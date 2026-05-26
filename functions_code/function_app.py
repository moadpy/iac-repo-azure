"""
Azure Functions — Dual-index Knowledge Base Ingestion Pipeline.

This module updates the ingestion flow to match the new Azure AI Search design:

  1. RunbookIngestor (Blob Trigger)
     - Parses markdown frontmatter when present
     - Splits runbooks into section-level chunks
     - Writes chunks to the runbook index

  2. GithubPRIngestor (HTTP Trigger)
     - Validates GitHub webhook signatures
     - Fetches merged PR file diffs from the GitHub API
     - Splits large diffs into chunk documents
     - Writes chunks to the evidence index

Authentication
--------------
- Azure OpenAI: Managed Identity via DefaultAzureCredential
- Azure AI Search: Managed Identity via DefaultAzureCredential
- GitHub API: Personal Access Token (GITHUB_TOKEN)
"""

import hashlib
import hmac
import json
import logging
import os
import re
import uuid
from typing import Any

import azure.functions as func
import requests
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from azure.search.documents import SearchClient
from openai import AzureOpenAI

app = func.FunctionApp()


# ---------------------------------------------------------------------------
# Environment variables
# ---------------------------------------------------------------------------

OPENAI_ENDPOINT = os.environ.get("AZURE_OPENAI_ENDPOINT")
OPENAI_API_VERSION = os.environ.get("AZURE_OPENAI_API_VERSION", "2024-07-01-preview")
EMBEDDING_DEPLOYMENT = os.environ.get(
    "AZURE_OPENAI_EMBEDDING_DEPLOYMENT",
    "text-embedding-3-small",
)

SEARCH_ENDPOINT = os.environ.get("AZURE_SEARCH_ENDPOINT")
EVIDENCE_INDEX_NAME = os.environ.get("AZURE_SEARCH_EVIDENCE_INDEX_NAME", "rca-evidence-index")
RUNBOOK_INDEX_NAME = os.environ.get("AZURE_SEARCH_RUNBOOK_INDEX_NAME", "rca-runbook-index")

GITHUB_WEBHOOK_SECRET = os.environ.get("GITHUB_WEBHOOK_SECRET")
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")

MAX_DIFF_LINES_PER_CHUNK = 80
GITHUB_API_PAGE_SIZE = 100


# ---------------------------------------------------------------------------
# Azure clients
# ---------------------------------------------------------------------------

credential = DefaultAzureCredential()

openai_client = None
if OPENAI_ENDPOINT:
    token_provider = get_bearer_token_provider(
        credential,
        "https://cognitiveservices.azure.com/.default",
    )
    openai_client = AzureOpenAI(
        azure_endpoint=OPENAI_ENDPOINT,
        azure_ad_token_provider=token_provider,
        api_version=OPENAI_API_VERSION,
    )

evidence_search_client = None
runbook_search_client = None
if SEARCH_ENDPOINT:
    evidence_search_client = SearchClient(
        endpoint=SEARCH_ENDPOINT,
        index_name=EVIDENCE_INDEX_NAME,
        credential=credential,
    )
    runbook_search_client = SearchClient(
        endpoint=SEARCH_ENDPOINT,
        index_name=RUNBOOK_INDEX_NAME,
        credential=credential,
    )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_RELEVANT_EXTENSIONS = {
    ".py", ".tf", ".yml", ".yaml", ".json", ".toml", ".cfg", ".ini",
    ".env", ".sh", ".dockerfile", ".js", ".ts", ".go", ".java",
}

_SERVICE_PATH_PATTERNS = {
    "src/payment-api/": "payment-api",
    "src/auth-service/": "auth-service",
    "src/order-service/": "order-service",
    "services/payment/": "payment-api",
    "services/auth/": "auth-service",
    "chaos-app/": "chaos-app",
    "config/": "*",
}


def _stable_id(value: str) -> str:
    return str(uuid.uuid5(uuid.NAMESPACE_URL, value))


def _normalize_timestamp(raw_ts: str | None) -> str | None:
    if not raw_ts:
        return None
    if raw_ts.endswith("Z") or "+" in raw_ts:
        return raw_ts
    if "T" in raw_ts:
        return raw_ts + "Z"
    return raw_ts + "T00:00:00Z"


def _parse_markdown_with_frontmatter(content: str) -> tuple[dict[str, str], str]:
    metadata: dict[str, str] = {}
    body = content
    match = re.match(r"^---\s*\n(.*?)\n---\s*\n", content, re.DOTALL)
    if match:
        frontmatter = match.group(1)
        body = content[match.end():]
        for line in frontmatter.splitlines():
            if ":" not in line:
                continue
            key, value = line.split(":", 1)
            metadata[key.strip()] = value.strip()
    return metadata, body


def _split_runbook_sections(body: str) -> list[tuple[str, str]]:
    sections: list[tuple[str, str]] = []
    current_title = "Overview"
    current_lines: list[str] = []

    for line in body.splitlines():
        if re.match(r"^##+\s+", line):
            section_content = "\n".join(current_lines).strip()
            if section_content:
                sections.append((current_title, section_content))
            current_title = re.sub(r"^##+\s+", "", line).strip()
            current_lines = []
            continue
        current_lines.append(line)

    trailing = "\n".join(current_lines).strip()
    if trailing:
        sections.append((current_title, trailing))

    return sections or [("Overview", body.strip())]


def _split_diff_into_chunks(code_diff: str) -> list[str]:
    lines = [line for line in code_diff.splitlines() if line.strip()]
    if not lines:
        return [""]
    return [
        "\n".join(lines[i : i + MAX_DIFF_LINES_PER_CHUNK])
        for i in range(0, len(lines), MAX_DIFF_LINES_PER_CHUNK)
    ]


def _infer_service_from_labels(labels: list[dict[str, Any]]) -> str | None:
    for label in labels:
        name = label.get("name", "")
        if name.lower().startswith("service:"):
            return name.split(":", 1)[1].strip()
    return None


def _infer_service_from_files(changed_files: list[dict[str, Any]]) -> str:
    for changed_file in changed_files:
        filename = changed_file.get("filename", "")
        for prefix, service in _SERVICE_PATH_PATTERNS.items():
            if filename.startswith(prefix):
                return service
    return "*"


def _filter_relevant_files(files: list[dict[str, Any]]) -> list[dict[str, Any]]:
    relevant: list[dict[str, Any]] = []
    for changed_file in files:
        filename = changed_file.get("filename", "")
        ext = "." + filename.rsplit(".", 1)[-1] if "." in filename else ""
        if ext.lower() in _RELEVANT_EXTENSIONS:
            relevant.append(changed_file)
    return relevant


def _fetch_all_pr_files(repo_full_name: str, pr_number: int) -> list[dict[str, Any]]:
    if not GITHUB_TOKEN:
        logging.warning("GITHUB_TOKEN not set — PR diffs will not be fetched.")
        return []

    headers = {
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json",
    }
    page = 1
    results: list[dict[str, Any]] = []

    while True:
        files_url = (
            f"https://api.github.com/repos/{repo_full_name}/pulls/{pr_number}/files"
            f"?per_page={GITHUB_API_PAGE_SIZE}&page={page}"
        )
        response = requests.get(files_url, headers=headers, timeout=30)
        response.raise_for_status()
        batch = response.json()
        if not batch:
            break
        results.extend(batch)
        if len(batch) < GITHUB_API_PAGE_SIZE:
            break
        page += 1

    return results


def _build_diff_text(files: list[dict[str, Any]]) -> str:
    diff_parts: list[str] = []
    for changed_file in files:
        patch = changed_file.get("patch", "")
        if not patch:
            continue
        diff_parts.append(f"--- {changed_file.get('filename')}\n{patch}")
    return "\n\n".join(diff_parts)


def _embedding_text(*parts: str) -> str:
    return "\n\n".join(part for part in parts if part).strip()


def get_embedding(text: str) -> list[float]:
    if not openai_client:
        logging.warning("OpenAI client not configured — skipping embedding generation.")
        return []
    try:
        response = openai_client.embeddings.create(
            input=[text],
            model=EMBEDDING_DEPLOYMENT,
        )
        return response.data[0].embedding
    except Exception as exc:  # pragma: no cover - runtime integration path
        logging.error("Error generating embedding: %s", exc)
        return []


def _delete_existing_documents(search_client: SearchClient, parent_id: str) -> None:
    escaped_parent_id = parent_id.replace("'", "''")
    existing_ids = [
        {"id": doc["id"]}
        for doc in search_client.search(
            search_text="*",
            filter=f"parent_id eq '{escaped_parent_id}'",
            select=["id"],
            top=1000,
        )
    ]
    if not existing_ids:
        return
    search_client.delete_documents(documents=existing_ids)
    logging.info("Deleted %d stale documents for parent_id=%s", len(existing_ids), parent_id)


def _upload_documents(search_client: SearchClient, documents: list[dict[str, Any]]) -> None:
    if not documents:
        return
    result = search_client.upload_documents(documents=documents)
    failed = [item.key for item in result if not item.succeeded]
    if failed:
        raise RuntimeError(f"Failed to index documents: {failed}")


# ---------------------------------------------------------------------------
# Runbook blob trigger
# ---------------------------------------------------------------------------

@app.blob_trigger(
    arg_name="myblob",
    path="runbooks/{name}",
    connection="RunbooksStorageConnection",
)
def RunbookIngestor(myblob: func.InputStream):
    logging.info(
        "Runbook blob trigger fired | Name: %s | Size: %s bytes",
        myblob.name,
        myblob.length,
    )

    if not runbook_search_client:
        logging.error("Runbook search client not initialized.")
        return

    if not myblob.name or not myblob.name.endswith(".md"):
        logging.info("Ignored non-markdown blob.")
        return

    raw_content = myblob.read().decode("utf-8")
    filename = myblob.name.split("/")[-1]
    metadata, body = _parse_markdown_with_frontmatter(raw_content)

    signature = metadata.get("signature", filename.replace(".md", ""))
    parent_id = metadata.get("runbook_id", _stable_id(filename))
    timestamp = _normalize_timestamp(metadata.get("last_updated"))
    service_affected = metadata.get("services", "*")
    author = metadata.get("author", "sre-team")

    documents: list[dict[str, Any]] = []
    for chunk_index, (section_title, section_content) in enumerate(_split_runbook_sections(body)):
        documents.append(
            {
                "id": f"{parent_id}--section-{chunk_index}",
                "parent_id": parent_id,
                "source_id": parent_id,
                "chunk_index": chunk_index,
                "step_order": chunk_index,
                "title": f"Runbook: {signature}",
                "section_title": section_title,
                "content": section_content,
                "doc_type": "runbook",
                "incident_signature": signature,
                "service_affected": service_affected,
                "author": author,
                "timestamp": timestamp,
                "url": myblob.name,
                "embedding": get_embedding(
                    _embedding_text(f"Runbook: {signature}", section_title, section_content)
                ),
            }
        )

    try:
        _delete_existing_documents(runbook_search_client, parent_id)
        _upload_documents(runbook_search_client, documents)
        logging.info(
            "Indexed runbook '%s' into '%s' with %d section docs.",
            filename,
            RUNBOOK_INDEX_NAME,
            len(documents),
        )
    except Exception as exc:  # pragma: no cover - runtime integration path
        logging.error("Error indexing runbook '%s': %s", filename, exc)


# ---------------------------------------------------------------------------
# GitHub PR HTTP trigger
# ---------------------------------------------------------------------------

@app.route(route="github-pr-ingestor", auth_level=func.AuthLevel.FUNCTION)
def GithubPRIngestor(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("GitHub PR Ingestor — webhook received.")

    if not evidence_search_client:
        logging.error("Evidence search client not initialized.")
        return func.HttpResponse("Search client error", status_code=500)

    signature_header = req.headers.get("x-hub-signature-256")
    if not signature_header or not GITHUB_WEBHOOK_SECRET:
        logging.warning("Missing webhook signature or secret.")
        return func.HttpResponse("Unauthorized", status_code=401)

    body = req.get_body()
    expected_signature = "sha256=" + hmac.new(
        GITHUB_WEBHOOK_SECRET.encode(),
        body,
        hashlib.sha256,
    ).hexdigest()
    if not hmac.compare_digest(signature_header, expected_signature):
        logging.warning("Webhook signature mismatch.")
        return func.HttpResponse("Invalid signature", status_code=401)

    try:
        event = req.get_json()
    except ValueError:
        return func.HttpResponse("Invalid JSON payload", status_code=400)

    action = event.get("action")
    pr = event.get("pull_request")
    if not (action == "closed" and pr and pr.get("merged")):
        return func.HttpResponse("Event ignored (not a merged PR).", status_code=200)

    base_branch = pr.get("base", {}).get("ref")
    if base_branch != "main":
        return func.HttpResponse(
            f"Ignored PR merged into '{base_branch}' — only 'main' is monitored.",
            status_code=200,
        )

    pr_number = pr.get("number")
    title = pr.get("title") or ""
    author = pr.get("user", {}).get("login") or ""
    merged_at = _normalize_timestamp(pr.get("merged_at"))
    repo_full_name = event.get("repository", {}).get("full_name") or ""
    labels = pr.get("labels", [])

    logging.info(
        "Processing merged PR #%s: '%s' by %s in %s",
        pr_number,
        title,
        author,
        repo_full_name,
    )

    try:
        changed_files = _fetch_all_pr_files(repo_full_name, int(pr_number))
    except requests.RequestException as exc:
        logging.error("Error calling GitHub API: %s", exc)
        return func.HttpResponse(f"GitHub API error: {exc}", status_code=502)

    relevant_files = _filter_relevant_files(changed_files)
    diff_text = _build_diff_text(relevant_files)

    service_affected = _infer_service_from_labels(labels)
    if not service_affected:
        service_affected = _infer_service_from_files(changed_files)

    logging.info(
        "Fetched %d files, %d relevant. Inferred service_affected='%s'",
        len(changed_files),
        len(relevant_files),
        service_affected,
    )

    parent_id = f"pr-{repo_full_name.replace('/', '-')}-{pr_number}"
    base_content = (
        f"PR #{pr_number}: {title}\n"
        f"Repository: {repo_full_name}\n"
        f"Author: {author}\n"
        f"Merged At: {merged_at or ''}"
    ).strip()
    diff_chunks = _split_diff_into_chunks(diff_text)

    documents: list[dict[str, Any]] = []
    for chunk_index, diff_chunk in enumerate(diff_chunks):
        documents.append(
            {
                "id": f"{parent_id}--chunk-{chunk_index}",
                "parent_id": parent_id,
                "source_id": parent_id,
                "chunk_index": chunk_index,
                "title": title,
                "content": base_content,
                "code_diff": diff_chunk[:30000],
                "doc_type": "github_pr",
                "incident_signature": "unknown",
                "service_affected": service_affected,
                "author": author,
                "timestamp": merged_at,
                "url": pr.get("html_url", ""),
                "embedding": get_embedding(
                    _embedding_text(title, base_content, diff_chunk[:30000])
                ),
            }
        )

    try:
        _delete_existing_documents(evidence_search_client, parent_id)
        _upload_documents(evidence_search_client, documents)
        logging.info(
            "Indexed PR #%s into '%s' with %d chunk docs.",
            pr_number,
            EVIDENCE_INDEX_NAME,
            len(documents),
        )
    except Exception as exc:  # pragma: no cover - runtime integration path
        logging.error("Error indexing PR #%s: %s", pr_number, exc)
        return func.HttpResponse(f"Error indexing: {exc}", status_code=500)

    return func.HttpResponse(
        json.dumps(
            {
                "status": "success",
                "pr_number": pr_number,
                "service_affected": service_affected,
                "evidence_index": EVIDENCE_INDEX_NAME,
                "documents_indexed": len(documents),
            }
        ),
        mimetype="application/json",
        status_code=200,
    )

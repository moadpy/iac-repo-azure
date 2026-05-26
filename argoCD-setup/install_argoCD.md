# Argo CD Re-installation & Private Repo Access

Because destroying the cluster wipes out its entire memory (etcd), you must re-install Argo CD and its configuration every time you recreate the cluster.

### The 5-Step Re-install Process

Once your `terraform apply` is finished and the cluster is ready, run these in order:

**1. Refresh your credentials:**
```bash
# Must overwrite the old stale config with the new cluster identity
az aks get-credentials --resource-group dev-env-rg --name <cluster_name> --overwrite-existing
```

**2. Create the namespace:**
```bash
kubectl create namespace argocd
```

**3. Install Argo CD (Server-Side Apply):**
```bash
# --server-side is required to bypass metadata size limits on CRDs
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --server-side
```

**4. Register Private Repository Credentials:**
Argo CD needs a GitHub Personal Access Token (PAT) to read your private GitOps repo. Apply this secret:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: github-repo-creds
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: https://github.com/moadpy/gitops-repo.git
  username: moadpy
  password: <GITHUB_PAT_PLACEHOLDER>
EOF
```

**5. Re-apply your Root Application:**
```bash
# This triggers the sync of your infrastructure
kubectl apply -f argoCD-setup/argocd-app.yaml
```

---

### Pro-Tip: Automating with Terraform
To avoid these manual steps, we can add a **Helm provider** to your Terraform configuration. This would allow Terraform to automatically install Argo CD and your repository credentials the moment the cluster is created. 
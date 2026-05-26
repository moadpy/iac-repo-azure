# Azure Application Gateway for Containers (AGC) Lifecycle Guide
## (Strategy B: ALB Controller Managed Deployment)

This guide documents how to create, verify, and delete the **Application Gateway for Containers (AGC)** (also known as the Azure Application Load Balancer) when adopting **Strategy B (ALB Controller Managed)**. 

Under this strategy, the lifecycle of the Azure load balancing resources is directly tied to the Kubernetes custom resources. You can provision or tear down the gateway resources at will to save the base cost (**$78.12 per environment for 3 weeks**) while leaving the AKS cluster compute, nodes, and internal pods fully intact.

---

## 1. Prerequisites (Managed by Terraform)

Before deploying the gateway in Kubernetes, ensure the following infrastructure is deployed via Terraform:
1. **Delegated Subnet (`snet-agc`)**: The subnet must exist and be delegated to `Microsoft.ServiceNetworking/trafficControllers`.
2. **ALB Controller Identity**: A User Assigned Managed Identity (`id-alb-controller-[suffix]`) must be configured with a federated credential linking it to the `alb-controller-sa` service account in the `azure-alb-system` namespace.
3. **RBAC Permissions**: The Managed Identity must have the following roles:
   * **AppGw for Containers Configuration Manager** on the resource group.
   * **Network Contributor** on the `snet-agc` subnet.

---

## 2. Step 1: Provisioning the AGC

To provision the load balancer in Azure, you must deploy two Kubernetes manifests: the **`ApplicationLoadBalancer`** resource (which triggers the Azure infrastructure) and the **`Gateway`** resource (which configures the routing rules).

### A. Define the `ApplicationLoadBalancer` Custom Resource
Create a file named `shared-alb.yaml` in your GitOps repository under `clusters/dev/apps/infrastructure/`.

```yaml
apiVersion: alb.networking.azure.io/v1
kind: ApplicationLoadBalancer
metadata:
  name: shared-alb
  namespace: rca-dev
spec:
  associations:
    # Point to the delegated subnet ID in Azure
    - /subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.Network/virtualNetworks/<vnet-name>/subnets/snet-agc
```

#### Parameter Explanation:
* `metadata.name`: The local name of the resource (e.g., `shared-alb`).
* `metadata.namespace`: The namespace where you are deploying your ingress rules (e.g., `rca-dev`).
* `spec.associations`: A list of the resource IDs of the delegated subnets. 
  * *How to construct it:* Combine your **Subscription ID**, the environment **Resource Group** (`preprod-env-rg` or `prod-env-rg`), the **VNet name** (`vnet-aks-[suffix]`), and the subnet name `snet-agc`.
  * *Example for Dev:* `/subscriptions/ce954bbd-0e01-4bb8-b01e-90d15bd16e75/resourceGroups/dev-env-rg/providers/Microsoft.Network/virtualNetworks/vnet-aks-8webdf/subnets/snet-agc`

---

### B. Define the `Gateway` Resource
Create or update `shared-gateway.yaml` in the same directory.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: shared-gateway
  namespace: rca-dev
spec:
  gatewayClassName: azure-alb-external # Managed by the external ALB controller
  listeners:
    - name: http
      port: 80
      protocol: HTTP
      allowedRoutes:
        namespaces:
          from: All
  infrastructure:
    parametersRef:
      name: shared-alb # Links directly to the ApplicationLoadBalancer resource above
      group: alb.networking.azure.io
      kind: ApplicationLoadBalancer
```

#### Parameter Explanation:
* `spec.gatewayClassName`: Must be `azure-alb-external` for public ingress (or `azure-alb-internal` for private ingress).
* `spec.infrastructure.parametersRef`: Tells the Gateway controller which `ApplicationLoadBalancer` resource defines the Azure backend.

---

### C. Deploy the Manifests
* **GitOps (Recommended)**: Commit and push `shared-alb.yaml` and `shared-gateway.yaml` to your GitOps repository. ArgoCD will automatically detect and apply the resources.
* **Manual CLI (For Quick Testing)**: Connect to your cluster from the Jumpbox VM and run:
  ```bash
  kubectl apply -f shared-alb.yaml
  kubectl apply -f shared-gateway.yaml
  ```

---

## 3. Step 2: Verifying Provisioning

Once applied, the ALB Controller in AKS will communicate with Azure to create the resource group resources.

1. **Verify in Kubernetes**:
   Run the following commands to check the deployment status:
   ```bash
   # Check the Load Balancer status (should show 'Ready' or 'Accepted')
   kubectl get applicationloadbalancer shared-alb -n rca-dev -o yaml
   
   # Check the Gateway status
   kubectl get gateway shared-gateway -n rca-dev
   ```
2. **Verify in Azure**:
   Navigate to the Azure Portal:
   * Go to your environment Resource Group (`dev-env-rg` or `preprod-env-rg`).
   * A new resource of type **Application Gateway for Containers** (Traffic Controller) will be provisioned dynamically.
   * Under its settings, you will see a **Frontend** and a **Subnet Association** created automatically.

---

## 4. Step 3: Deleting the AGC (Stopping Billing)

When you are done testing and want to avoid charges, you can delete the AGC resource to stop the hourly capacity and frontend billing.

### A. How to Delete
* **GitOps**: Move or remove `shared-alb.yaml` and `shared-gateway.yaml` from the tracked directory (`clusters/dev/apps/infrastructure/`) and push the change to your GitOps repository. ArgoCD will synchronize and automatically delete (prune) the resources from Kubernetes.
* **Manual CLI**:
  Run the following commands:
  ```bash
  kubectl delete gateway shared-gateway -n rca-dev
  kubectl delete applicationloadbalancer shared-alb -n rca-dev
  ```

### B. What Happens Under the Hood
1. The ALB Controller detects the deletion of the `ApplicationLoadBalancer` resource in Kubernetes.
2. It sends an API request to Azure to **delete the Traffic Controller parent resource, the association, and the frontend**.
3. **Billing stops immediately** for the AGC fixed hourly fees.
4. **Your AKS Cluster compute, nodes, pods, private endpoints, and data databases are fully preserved** and remain active.

---

## 5. Summary Checklist

| Action | Command / Location | Billing Status |
| :--- | :--- | :--- |
| **Start AGC Ingress** | Deploy `shared-alb.yaml` + `shared-gateway.yaml` | **Active** (~$0.155/hour) |
| **Stop AGC Ingress** | Delete `shared-alb.yaml` + `shared-gateway.yaml` | **Stopped** ($0.00/hour) |
| **Verify Status** | `kubectl get applicationloadbalancer -n rca-dev` | N/A |

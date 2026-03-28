## Munikube commands

### Lifecycle Commands

| Command | Description |
| :--- | :--- |
| `minikube start --driver=docker` | **Start the cluster** using the Docker driver. |
| `minikube stop` | **Shut down** the cluster (frees up RAM/CPU). |
| `minikube pause` | Freeze the cluster state without fully stopping. |
| `minikube unpause` | Resume a paused cluster. |
| `minikube delete --all --purge` | **Wipe everything** (Deletes all images and data). |


### Status & Monitoring

* **Check Cluster Health:**
    ```powershell
    minikube status
    ```
* **Open Web Dashboard:**
    ```powershell
    minikube dashboard
    ```
* **List Nodes:**
    ```powershell
    kubectl get nodes
    ```
* **List All Pods:**
    ```powershell
    kubectl get pods
    ```

---

## QuickPizza Management Guide

### Image & Deployment lifecycle

| Command | Description |
| :--- | :--- |
| `docker build -t quickpizza:latest .` | Download the image from Docker Hub to your local Docker. |
| `minikube image load quickpizza:latest` | Push the image from Windows Docker to Minikube internal storage. |
| `kubectl apply -f .\k8s\quickpizza.yaml` | Deploy the application (creates Pods and Service). |
| `minikube service quickpizza` | Open App in browser (creates a network tunnel). |
| `kubectl delete -f .\k8s\quickpizza.yaml` | Remove App from the cluster but keep Minikube running. |

### Lifecycle & Scaling

| Command | Description |
|--------|------------|
| `kubectl scale deployment quickpizza --replicas=0` | **Stop (Pause)** – Turns off pods to save RAM, but keeps configuration intact. |
| `kubectl scale deployment quickpizza --replicas=1` | **Resume (Start)** – Turns pods back on. |
| `kubectl rollout restart deployment quickpizza` | **Restart** – Forces a fresh start of all application pods. |
| `kubectl get svc quickpizza` | **Check Ports** – Shows which ports the service is exposed on. |
| `kubectl get endpoints quickpizza` | **Verify Connection** – Checks whether the service can see active pods. |
| `kubectl delete deployment quickpizza` | **Delete Deployment** – Removes the deployment and all associated pods. |
| `kubectl delete service quickpizza` | **Delete Service** – Removes the service exposing the application. |

### Status & Monitoring

* **Check if Pods are Running:**
    ```powershell
    kubectl get pods
    ```
* **Follow Logs (Debug):**
    ```powershell
    kubectl logs -f -l app=quickpizza
    ```
* **Check Service Details:**
    ```powershell
    kubectl get svc quickpizza
    ```
* **Interactive Shell (Go inside container):**
    ```powershell
    kubectl exec -it deployment/quickpizza -- sh
    ```
---

# Prometheus & Grafana Deployment

### Deployment
| Command | Description |
|--------|------------|
| `kubectl apply -f ./k8s/monitoring.yaml` | Deploy monitoring stack (Namespace, RBAC, Prometheus, Grafana) |
| `kubectl get pods -n monitoring` | To check monitoring podsf for Prometheus & Grafana |
| `minikube service prometheus -n monitoring` | Open Prometheus UI in browser |
| `minikube service grafana -n monitoring` | Open Grafana UI in browser |
| **Grafana Login:** `admin / admin` | Default credentials post-deployment |

### Post-Deployment Setup

Use `minikube service prometheus -n monitoring` and `minikube service grafana -n monitoring` in separate terminals.
1. **Link Prometheus to Grafana**
   - Go to **Connections → Data Sources → Add data source**
   - Select **Prometheus**
   - Set URL: `http://prometheus.monitoring:9090`
   - Click **Save & Test**

2. **Verify Data Flow**
   - Go to **Explore (compass icon)**
   - Query: `up` → Click **Run Query**
   - Result: `quickpizza` should show value `1`

### Maintenance & Debug

| Command | Description |
|--------|------------|
| `kubectl scale deployment -n monitoring --all --replicas=0` | Pause monitoring (saves RAM/CPU) |
| `kubectl rollout restart deployment prometheus -n monitoring` | Restart Prometheus to reload config/RBAC |
| `kubectl logs -l app=prometheus -n monitoring` | Check logs if targets are missing |
| `kubectl get targets -n monitoring` | Status check for all monitored pods |
---


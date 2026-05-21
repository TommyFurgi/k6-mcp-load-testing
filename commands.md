# Minikube & K8s Cheat Sheet

Below you will find a quick reference guide with the most necessary commands for debugging, verifying, and managing the infrastructure from the terminal.

## ⚙️ Minikube Operational Commands

| Command | Description |
| :--- | :--- |
| `minikube status` | Returns information about the cluster's health. |
| `minikube stop` | **Stops the cluster**, freeing up RAM and CPU (without data loss). |
| `minikube start` | Starts a previously stopped cluster. |
| `minikube delete --all --purge` | **Full format**. Destroys the cluster and removes all data. |
| `minikube dashboard` | Opens the official Kubernetes GUI panel in the browser. |

## 📦 Application Management (QuickPizza)

| Command | Description |
| :--- | :--- |
| `kubectl scale deployment quickpizza --replicas=0` | **Pause** – Temporarily kills application pods to save resources (configuration is preserved). |
| `kubectl scale deployment quickpizza --replicas=1` | **Resume** – Turns the application back on. |
| `kubectl rollout restart deployment quickpizza` | **Restart** – Forces old application containers to terminate and spins up fresh ones. |
| `kubectl get pods` | Checks the status of Pods (e.g., verifying if STATUS is Running). |
| `kubectl logs -f -l app=quickpizza` | **Follow Logs** – Starts a live view of errors and logs from the application level. |
| `kubectl exec -it deployment/quickpizza -- sh` | Opens an interactive console (shell) directly **inside** a running container. |

## 📊 Monitoring Management (Prometheus & Grafana)

By default, all monitoring tools run in the `monitoring` namespace. This requires appending the `-n monitoring` flag to your commands.

| Command | Description |
| :--- | :--- |
| `kubectl get pods -n monitoring` | Checks the operational status of Grafana and Prometheus Pods. |
| `kubectl scale deployment -n monitoring --all --replicas=0` | Stops ALL monitoring pods at once (useful if your computer is running hot). |
| `kubectl rollout restart deployment prometheus -n monitoring` | Forces Prometheus to fetch its configuration (ConfigMap) anew. |
| `kubectl logs -l app=prometheus -n monitoring` | Views Prometheus logs and errors. |

### UI Network Tunnels

Commands that you must leave running **in the background** in separate terminal tabs to access the charts via the browser in real time:

```bash
minikube service prometheus -n monitoring
minikube service grafana -n monitoring
```

*Default login credentials for Grafana are `admin` / `admin`.*

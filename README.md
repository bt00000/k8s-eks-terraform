# Kubernetes Microservices Deployment with Helm & AWS EKS 

This project sets up a **Kubernetes cluster on AWS EKS** with **Helm**, **Nginx Ingress**, **Redis**, **Prometheus**, and **Grafana** for monitoring. It also includes **Cluster Autoscaler** for automatic scaling.

<img width="596" alt="updated_kubernetes_cluster_architecture" src="https://github.com/user-attachments/assets/fafb5b8f-a30d-43f2-95e3-a866e06e652a" />


## Features
**Automated Deployment with Helm** – Easily deploy services like Nginx and Redis  
**Ingress Controller with Load Balancer** – Handle external traffic using Nginx  
**Cluster Autoscaler** – Automatically scales nodes based on workload  
**Monitoring & Logging** – Uses Prometheus and Grafana for real-time metrics  
**Terraform for Infrastructure as Code** – Deploy EKS cluster with Terraform  

---

## **Setup Instructions**

## 1. Install Dependencies
Ensure you have the following installed:
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

---

## 2. Deploy AWS EKS Cluster with Terraform
Run the following to provision an **EKS Cluster**:

```sh
terraform init
terraform apply -auto-approve
```

## 3. Install Helm & Add Repositories

```sh
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

This updates Helm repositories to pull the latest charts.

---

## 4. Deploy Nginx Ingress Controller

```sh
helm install my-nginx ingress-nginx/ingress-nginx --namespace kube-system
```

Verify installation:

```sh
kubectl get svc -n kube-system | grep my-nginx-ingress-nginx-controller
```

Find the `EXTERNAL-IP`, which will be used for routing.

---

## 5. Deploy Your Application with Helm

First, create a Helm chart:

```sh
helm create my-app-chart
```

Modify `values.yaml` to specify the image, ingress, and service.

Deploy your app:

```sh
helm install my-app my-app-chart
```

Verify:

```sh
kubectl get pods
kubectl get svc
kubectl get ingress
```

---

## 6. Deploy Redis for Caching

```sh
helm install my-redis bitnami/redis --namespace kube-system
```

Check Redis:

```sh
kubectl get pods -n kube-system | grep redis
```

---

## 7. Set Up Cluster Autoscaler

Install the autoscaler with:

```sh
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=my-eks-cluster \
  --set awsRegion=us-east-2 \
  --set extraArgs.balance-similar-node-groups=true \
  --set extraArgs.skip-nodes-with-local-storage=false \
  --set extraArgs.skip-nodes-with-system-pods=false
```

Check logs:

```sh
kubectl get pods -n kube-system | grep cluster-autoscaler
kubectl logs -f deployment/cluster-autoscaler-aws-cluster-autoscaler -n kube-system
```

---

## 8. Install Monitoring (Prometheus & Grafana)

```sh
helm install monitoring prometheus-community/kube-prometheus-stack --namespace kube-system
```

Verify:

```sh
kubectl get pods -n kube-system | grep prometheus
kubectl get pods -n kube-system | grep grafana
```

### Access Grafana

```sh
kubectl get secret -n kube-system monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
kubectl port-forward -n kube-system svc/monitoring-grafana 3000:80
```

Open `http://localhost:3000`

**Username:** `admin`  
**Password:** (from command above)

<img width="1433" alt="Grafana" src="https://github.com/user-attachments/assets/eebefd2a-76a2-4840-a982-5a3db98743c1" />

<img width="1423" alt="Grafana Prometheus" src="https://github.com/user-attachments/assets/8a7bb94f-69e4-4c46-bbd6-9d8d1e3eee06" />

---

## Useful Commands

### Check Resource Usage

```sh
kubectl top pods
kubectl top nodes
```

### Delete a Helm Deployment

```sh
helm uninstall my-app
```

### Scale a Deployment

```sh
kubectl scale deployment my-app --replicas=3
```

---

## Conclusion
This README provides step-by-step instructions to set up Kubernetes with Helm, deploy applications, configure autoscaling, and monitor cluster resources.

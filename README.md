# 🚀 Plausible Analytics on AWS EKS

This project demonstrates how to deploy **Plausible Analytics**, an open-source web analytics tool, on **Amazon Elastic Kubernetes Service (EKS)** using **Terraform** and **Kubernetes manifests**.  
It automates the entire setup — from infrastructure provisioning to HTTPS-secured access and observability — showing how to run a production-grade analytics application in the cloud.

---

## 💡 Why I Built This Project
Startups and agencies often rely on costly analytics platforms like Google Analytics 360 or Datadog for real-time insights.  
This project provides a **cost-efficient, privacy-friendly, and fully self-hosted alternative** — deployable in minutes using Terraform and AWS EKS.  
It demonstrates skills in **cloud automation, Kubernetes orchestration, and secure production architecture.**


---

## 📘 Project Overview

This setup automates:
- Creation of a secure AWS EKS cluster using Terraform  
- Deployment of Plausible Analytics and its dependencies (**PostgreSQL** and **ClickHouse**) on Kubernetes  
- Configuration of an **AWS Application Load Balancer (ALB)** Ingress for external access  
- Integration with **Route 53** for custom domain management  
- Secure **TLS/HTTPS** configuration via ACM  
- Health checks and observability setup for production readiness  

---

## 🏗️ Architecture

### Components
- **Terraform** → Provisions AWS infrastructure (VPC, EKS, IAM roles, networking).  
- **Kubernetes** → Manages deployment and service routing.  
- **AWS ALB Ingress Controller** → Handles external traffic routing.  
- **Route 53** → Maps domain (`analyzr.pro`) to ALB.  
- **Kubernetes Secrets** → Stores credentials and environment variables securely.  

### Logical Flow
1. User accesses `https://analyzr.pro`  
2. Route 53 resolves domain → ALB endpoint  
3. ALB routes traffic to the Plausible Service in Kubernetes  
4. Service forwards requests to the Plausible Pod (port 8000)  
5. Application connects internally to PostgreSQL and ClickHouse  
6. Responses are returned to the client via ALB  

---

## 📦 Prerequisites

Make sure you have:
- Terraform ≥ v1.9  
- kubectl ≥ v1.29  
- AWS CLI  
- eksctl  
- Helm  
- Active AWS account  
- Registered domain name in Route 53  
- IAM user with **AdministratorAccess** or equivalent  

---

## ⚙️ Terraform Setup

```bash
terraform init
terraform plan
terraform apply
```

This provisions:
- VPC, subnets, and security groups  
- EKS cluster and worker nodes  
- IAM roles and policies  
- Networking components  

Then configure kubectl:
```bash
aws eks --region <region> update-kubeconfig --name <cluster_name>
kubectl get nodes
```

---

## 🚀 Kubernetes Deployment

### 1. Create Namespace
```bash
kubectl create namespace plausible
```

### 2. Create Secrets
You can apply imperatively or via YAML (`plausible-secret.yaml`):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: plausible-secret
  namespace: plausible
type: Opaque
stringData:
  POSTGRES_USER: username
  POSTGRES_PASSWORD: pass
  POSTGRES_DB: dbname
  POSTGRES_HOST: postgres
  CLICKHOUSE_USER: username
  CLICKHOUSE_PASSWORD: pass
  CLICKHOUSE_DB: dbname
  CLICKHOUSE_HOST: clickhouse
  SECRET_KEY_BASE: "your_secret_key"
  BASE_URL: "https://analyzr.pro"
  DATABASE_URL: "postgresql://username:pass@postgres.plausible.svc.cluster.local:5432/dbname"
  CLICKHOUSE_DATABASE_URL: "http://username:pass@clickhouse.plausible.svc.cluster.local:8123/dbname"
```

### 3. Deploy Databases
```bash
kubectl apply -f postgres.yaml
kubectl apply -f clickhouse.yaml
```

### 4. Verify Deployments
Use Adminer to validate PostgreSQL connectivity.

### 5. Deploy Plausible
```bash
kubectl apply -f plausible.yaml
```

---

## 🌐 Networking (Route 53 + ALB + ACM)

1. Create ACM certificate for your domain  
2. Add Route 53 A-record pointing to your ALB  
3. Configure Ingress with ACM certificate annotations  

Example:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: plausible-ingress
  namespace: plausible
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:<account-id>:certificate/<cert-id>
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
    alb.ingress.kubernetes.io/ssl-redirect: "443"
spec:
  rules:
    - host: analyzr.pro
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: plausible
                port:
                  number: 80
```

---

## 🔐 Network Policy Setup

Restrict service-to-service communication.

Example:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-plausible-to-postgres
  namespace: plausible
spec:
  podSelector:
    matchLabels:
      app: postgres
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: plausible
      ports:
        - protocol: TCP
          port: 5432
```

---

## 🔑 Create Admin User

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: plausible-create-admin
  namespace: plausible
spec:
  template:
    spec:
      containers:
        - name: create-admin
          image: plausible/analytics:latest
          command: ["/bin/sh", "-c"]
          args:
            - |
              echo "Creating Plausible admin user..."
              /app/bin/plausible eval 'Plausible.Auth.create_user("your email", "your pass", "your name", true)'
          envFrom:
            - secretRef:
                name: plausible-secret
      restartPolicy: Never
```

Run:
```bash
kubectl apply -f create-admin.yaml
kubectl logs -n plausible job/plausible-create-admin -f
```

---

## 🧩 Verification

```bash
kubectl get pods -n plausible
kubectl logs deploy/plausible -n plausible
kubectl get ingress plausible-ingress -n plausible
```

Access your deployment:  
👉 [https://analyzr.pro](https://analyzr.pro)

---

## 🧠 Best Practices

- Enable autoscaling and monitoring with **Prometheus + Grafana**  
- Use **AWS Secrets Manager** for credentials  
- Match `servicePort` and `targetPort` correctly  
- Add readiness and liveness probes  
- Use **NetworkPolicies** for zero-trust networking  

---

## 🧾 License
MIT License — see [LICENSE](LICENSE) for details.

---

## 🧰 Tech Stack

| Tool | Purpose |
|------|----------|
| Terraform | Infrastructure as Code |
| AWS EKS | Managed Kubernetes Cluster |
| Helm & kubectl | Deployment Management |
| PostgreSQL & ClickHouse | Data Storage |
| Plausible Analytics | Application Layer |
| AWS ALB, Route 53, ACM | Networking, DNS, TLS |

---

## ✨ Results & Observations

- Successfully deployed **Plausible Analytics** on AWS EKS with full automation.  
- Verified **secure ingress**, **load balancing**, and **database connectivity**.  
- Demonstrated real-world **cloud-native design principles** — IaC, microservices, and observability.  

---

## 🌍 Future Improvements

- CI/CD with GitHub Actions or ArgoCD  
- Horizontal Pod Autoscaling  
- Centralized logging with Grafana Loki  
- Database backup automation  

---

## 👤 Author & Contact

**Chinelo Ufondu**  
Cloud / Infrastructure Engineer | DevOps Enthusiast  

🔗 [LinkedIn](https://linkedin.com/in/chineloufondu26)  
💻 [GitHub](https://github.com/SOft26)  
🌐 [Portfolio / Blog](https://bit.ly/chinelo_portfolio)

---

⭐ **If you found this project useful, consider giving it a star!**


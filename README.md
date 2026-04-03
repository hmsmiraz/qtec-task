# qtec-task — DevOps Practical Task 🚀

A production-style system demonstrating containerization, CI/CD
automation, traffic management, and observability.

---

## 📋 Table of Contents
1. [System Architecture](#system-architecture)
2. [Tech Stack](#tech-stack)
3. [Project Structure](#project-structure)
4. [API Endpoints](#api-endpoints)
5. [Containerization](#containerization)
6. [Reverse Proxy & Load Balancing](#reverse-proxy--load-balancing)
7. [CI/CD Pipeline](#cicd-pipeline)
8. [Monitoring & Logs](#monitoring--logs)
9. [Secrets Management](#secrets-management)
10. [Infrastructure as Code](#infrastructure-as-code)
11. [Kubernetes & EKS](#kubernetes--eks)
12. [Zero-Downtime Deployment](#zero-downtime-deployment)
13. [Handling ~100 req/sec](#handling-100-reqsec)
14. [Local Development](#local-development)
15. [Cloud Deployment](#cloud-deployment)

---

## 🏗️ System Architecture
```text
Internet
│
▼
AWS EKS (Kubernetes Cluster)
│
▼
Nginx (Reverse Proxy + Load Balancer)
│   ├── Rate limiting (100 req/sec)
│   ├── Security headers
│   └── Load balancing (round-robin)
│
▼
Node.js API Pods (3 replicas)
│   ├── Pod 1
│   ├── Pod 2
│   └── Pod 3
│        └── HPA (auto-scale 2 → 6)
│
├── Vault → Secrets
├── Prometheus → Metrics
└── Grafana → Dashboards

CI/CD: GitHub Actions
IaC: Terraform (VPC, EKS, IAM)

```

## 🛠️ Tech Stack

| Layer | Tool | Purpose |
|-------|------|---------|
| **API** | Node.js + Express | REST API |
| **Containerization** | Docker | Container packaging |
| **Registry** | Docker Hub | Image storage |
| **Orchestration** | Kubernetes (EKS) | Container orchestration |
| **Reverse Proxy + LB** | Nginx | Traffic management |
| **CI/CD** | GitHub Actions | Automated pipeline |
| **Monitoring** | Prometheus + Grafana | Metrics & dashboards |
| **Secrets** | HashiCorp Vault | Secrets management |
| **IaC** | Terraform | Infrastructure provisioning |
| **Cloud** | AWS (EKS, VPC) | Cloud platform |

---

## 📁 Project Structure
```text
qtec-task/
├── app/                        # Node.js Express API
│   ├── src/
│   │   ├── index.js            # App entry point
│   │   ├── config/
│   │   │   └── vault.js        # Vault client
│   │   ├── routes/
│   │   │   ├── status.js       # GET /status
│   │   │   └── data.js         # POST /data
│   │   └── middleware/
│   │       ├── logger.js       # Request logging
│   │       └── metrics.js      # Prometheus metrics
│   ├── tests/
│   │   ├── status.test.js
│   │   └── data.test.js
│   ├── Dockerfile
│   └── package.json
├── nginx/
│   ├── nginx.conf              # Main Nginx config
│   └── conf.d/
│       └── default.conf        # Server block
├── kubernetes/
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── deployment.yaml         # Rolling update strategy
│   ├── service.yaml
│   ├── nginx-configmap.yaml
│   ├── nginx-deployment.yaml
│   ├── nginx-service.yaml
│   ├── hpa.yaml                # Auto-scaling
│   └── monitoring/
│       ├── prometheus.yaml
│       └── grafana.yaml
├── terraform/
│   ├── main.tf                 # Provider config
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output values
│   ├── vpc.tf                  # VPC + networking
│   ├── eks.tf                  # EKS cluster
│   ├── iam.tf                  # IAM roles
│   └── security.tf             # Security groups
├── vault/
│   ├── config/
│   │   └── vault.hcl           # Vault server config
│   ├── policies/
│   │   └── qtec-policy.hcl     # Access policies
│   └── init/
│       └── init-vault.sh       # Auto-seed secrets
├── monitoring/
│   ├── prometheus.yml          # Scrape config
│   ├── alert.rules.yml         # Alert rules
│   └── grafana/
│       ├── provisioning/       # Auto-provision
│       └── dashboards/         # Pre-built dashboards
├── .github/
│   └── workflows/
│       ├── ci-cd.yaml          # Main pipeline
│       └── pr-check.yaml       # PR validation
├── docker-compose.yml          # Local development
└── README.md
```

## 🔌 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | API info & available endpoints |
| GET | `/status` | Service health + system info |
| GET | `/status/health` | Kubernetes liveness probe |
| GET | `/status/ready` | Kubernetes readiness probe |
| POST | `/data` | Store data |
| GET | `/data` | Retrieve all stored data |
| GET | `/metrics` | Prometheus metrics |
| GET | `/vault-status` | Vault connection status |
| GET | `/nginx-health` | Nginx health check |

### Example Requests
```bash
# GET /status
curl http://localhost/status

# POST /data
curl -X POST http://localhost/data \
  -H "Content-Type: application/json" \
  -d '{"name": "test", "value": 42, "tags": ["devops"]}'

# Response
{
  "status": "success",
  "data": {
    "id": "uuid-here",
    "name": "test",
    "value": 42,
    "processedBy": "qtec-task-api-pod-name"
  }
}
```

---

## 🐳 Containerization

### Multi-Stage Dockerfile
```text
Stage 1 (Builder):
├── Install ALL dependencies
├── Run tests (npm test)
└── If tests fail → build fails ✅
Stage 2 (Production):
├── Install ONLY production deps
├── Non-root user (appuser:1001)
├── HEALTHCHECK enabled
└── CMD ["node"] for SIGTERM handling
```
### Build & Push
```bash
# Build
docker build -t hmsmiraz/qtec-task:latest ./app

# Push
docker push hmsmiraz/qtec-task:latest
```

---

## 🔀 Reverse Proxy & Load Balancing

Nginx handles all incoming traffic:
```text
Client Request
│
▼
Nginx (port 80)
├── Rate limit: 100 req/sec (burst: 200)
├── Security headers
├── Gzip compression
└── Round-robin to API pods
├── Pod 1 (~33 req/sec)
├── Pod 2 (~33 req/sec)
└── Pod 3 (~33 req/sec)
```
### Key Nginx Config
```nginx
upstream qtec_api_backend {
    server api1:3000 weight=1 max_fails=3 fail_timeout=30s;
    server api2:3000 weight=1 max_fails=3 fail_timeout=30s;
    server api3:3000 weight=1 max_fails=3 fail_timeout=30s;
    keepalive 32;
}

limit_req_zone $binary_remote_addr zone=api_limit:10m rate=100r/s;
```

---

## ⚙️ CI/CD Pipeline

### Pipeline Flow
```text
Push to main branch
│
▼
🧪 Job 1: Run Tests
├── npm ci
├── npm test (Jest)
└── Upload coverage report
│
▼ (only if tests pass)
🐳 Job 2: Build & Push Docker
├── docker/login → Docker Hub
├── docker/build-push
│     ├── Tag: latest
│     └── Tag: sha-xxxxxxx
└── BuildKit layer caching
│
▼
🔒 Job 3: Security Scan
└── Trivy vulnerability scan
│
▼
🚀 Job 4: Deploy to EKS
├── aws eks update-kubeconfig
├── kubectl set image
└── kubectl rollout status
```
### How Zero-Downtime Works in CI/CD
```yaml
- name: Deploy to EKS
  run: |
    kubectl set image deployment/qtec-task-api \
      api=hmsmiraz/qtec-task:sha-${{ github.sha }} \
      -n qtec-task
    kubectl rollout status deployment/qtec-task-api \
      -n qtec-task --timeout=300s
```

---

## 📊 Monitoring & Logs

### Prometheus Metrics Collected

| Metric | Type | Description |
|--------|------|-------------|
| `http_requests_total` | Counter | Total HTTP requests |
| `http_request_duration_seconds` | Histogram | Request duration |
| `http_active_requests` | Gauge | Active requests |
| `http_errors_total` | Counter | Total errors |
| `process_resident_memory_bytes` | Gauge | Memory usage |

### Accessing Monitoring
```bash
# Local (docker-compose)
Prometheus: http://localhost:9090
Grafana:    http://localhost:3001  (admin/admin123)

# EKS (kubectl port-forward)
kubectl port-forward svc/prometheus-svc 9090:9090 -n qtec-task
kubectl port-forward svc/grafana-svc 3001:3000 -n qtec-task
```

### Application Logs
```bash
# Docker
docker compose logs -f api1 api2 api3

# Kubernetes
kubectl logs -f deployment/qtec-task-api -n qtec-task
kubectl logs -f deployment/qtec-nginx -n qtec-task
```

---

## 🔐 Secrets Management

HashiCorp Vault stores all sensitive config:
```text
Vault Secrets Engine: KV v2
└── secret/
└── qtec-task/
├── app/          ← APP_NAME, API_KEY, SECRET_KEY
└── database/     ← DB_HOST, DB_USER, DB_PASSWORD
```
### How Secrets Flow
```text
Vault Container
│
▼ (on startup)
vault.js client fetches secrets
│
▼
process.env injected
│
▼
App uses process.env.SECRET_KEY etc.
```
### Access Vault UI
```text
URL:    http://localhost:8200
Method: Token
Token:  qtec-root-token
```
---

## 🏗️ Infrastructure as Code

Terraform provisions all AWS resources:
```bash
cd terraform

terraform init      # Download providers
terraform plan      # Preview changes
terraform apply     # Create resources (~15 min)
terraform destroy   # Delete all resources
```

### Resources Created

| Resource | Details |
|----------|---------|
| VPC | 10.0.0.0/16 |
| Public Subnets | 2x (for Nginx LB) |
| Private Subnets | 2x (for EKS nodes) |
| Internet Gateway | Public internet access |
| NAT Gateway | Private node internet |
| EKS Cluster | v1.28, ap-southeast-1 |
| Node Group | t3.small, min:1, max:2 |
| IAM Roles | EKS + Node group |
| Security Groups | Cluster + Nodes |

---

## ☸️ Kubernetes & EKS

### Deploy to EKS
```bash
# Configure kubectl
aws eks update-kubeconfig \
  --region ap-southeast-1 \
  --name qtec-task-eks

# Deploy all resources
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/secret.yaml
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/nginx-configmap.yaml
kubectl apply -f kubernetes/nginx-deployment.yaml
kubectl apply -f kubernetes/nginx-service.yaml
kubectl apply -f kubernetes/hpa.yaml
kubectl apply -f kubernetes/monitoring/

# Verify
kubectl get all -n qtec-task
```

### Horizontal Pod Autoscaler
```text
Normal load:   2 pods  (minimum)
~50 req/sec:   3 pods
~100 req/sec:  4-5 pods
Peak load:     6 pods  (maximum)
```
---

## 🔄 Zero-Downtime Deployment

### Strategy: RollingUpdate
```text
Before:  [v1] [v1] [v1]   ← 3 pods serving traffic
Step 1:  [v1] [v1] [v1] [v2]   ← new pod starts (maxSurge: 1)
↓ health check passes
Step 2:  [v1] [v1] [v2]        ← old pod removed (maxUnavailable: 1)
↓ health check passes
Step 3:  [v1] [v1] [v2] [v2]   ← new pod starts
↓ health check passes
Step 4:  [v1] [v2] [v2]        ← old pod removed
↓ health check passes
Step 5:  [v2] [v2] [v2]        ← complete! ✅
Users NEVER experience downtime — Nginx always routes
to healthy pods only (readinessProbe ensures this)
```
### Key Settings That Guarantee Zero-Downtime
```yaml
# 1. Rolling strategy
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
    maxSurge: 1

# 2. Readiness probe — no traffic until ready
readinessProbe:
  httpGet:
    path: /status/ready
    port: 3000
  initialDelaySeconds: 10

# 3. PreStop hook — finish in-flight requests
lifecycle:
  preStop:
    exec:
      command: ["/bin/sh", "-c", "sleep 15"]

# 4. Graceful shutdown in Node.js
process.on('SIGTERM', () => {
  server.close(() => process.exit(0))
})
```

### Instant Rollback
```bash
# If deployment goes wrong:
kubectl rollout undo deployment/qtec-task-api -n qtec-task

# Check rollout history:
kubectl rollout history deployment/qtec-task-api -n qtec-task
```

---

## ⚡ Handling ~100 req/sec

### Strategy: Horizontal Scaling + Load Balancing
```text
100 req/sec incoming
│
▼
Nginx (rate limit: 100r/s, burst: 200)
└── keepalive 32 connections → reduces overhead
│
├── ~33 req/sec → Pod 1 (Node.js)
├── ~33 req/sec → Pod 2 (Node.js)
└── ~33 req/sec → Pod 3 (Node.js)
Each Node.js pod:
├── Single-threaded but non-blocking I/O
├── Handles 50-100 req/sec easily
└── HPA adds pods if CPU > 70%
```
### Capacity Math
```text
3 pods × ~50 req/sec each = 150 req/sec capacity
HPA max 6 pods × ~50 req/sec = 300 req/sec maximum
Target: 100 req/sec ← well within capacity ✅
```
---

## 💻 Local Development

### Prerequisites
```bash
node --version   # v18+
docker --version # v24+
```

### Run Locally
```bash
# Clone repo
git clone https://github.com/hmsmiraz/qtec-task.git
cd qtec-task

# Start all services
docker compose up -d

# Check status
docker compose ps

# Test API
curl http://localhost/status
curl -X POST http://localhost/data \
  -H "Content-Type: application/json" \
  -d '{"name":"test","value":1}'

# View logs
docker compose logs -f

# Stop
docker compose down
```

### Available Local Services

| Service | URL | Credentials |
|---------|-----|-------------|
| API (via Nginx) | http://localhost | — |
| Prometheus | http://localhost:9090 | — |
| Grafana | http://localhost:3001 | admin/admin123 |
| Vault UI | http://localhost:8200 | token: qtec-root-token |

---

## ☁️ Cloud Deployment

### AWS Resources

| Resource | Value |
|----------|-------|
| Region | ap-southeast-1 |
| EKS Cluster | qtec-task-eks |
| VPC | vpc-08b52827548c94966 |
| Public URL | ac2c68302baac4215bd50a94d71c0f70-a24b54bd3e5557c4.elb.ap-southeast-1.amazonaws.com |

### Deployment Steps
```bash
# 1. Provision infrastructure
cd terraform
terraform init && terraform apply

# 2. Configure kubectl
aws eks update-kubeconfig \
  --region ap-southeast-1 \
  --name qtec-task-eks

# 3. Deploy to K8s
kubectl apply -f kubernetes/

# 4. Verify
kubectl get all -n qtec-task
```

---

## 🧪 Testing
```bash
# Unit tests
cd app && npm test

# Test API endpoints
curl http://localhost/status
curl http://localhost/status/health
curl http://localhost/status/ready
curl http://localhost/nginx-health
curl http://localhost/vault-status

# Test load balancing (round-robin)
1..9 | ForEach-Object {
  $res = Invoke-RestMethod \`
    -Uri "http://localhost/data" \`
    -Method POST \`
    -ContentType "application/json" \`
    -Body '{"name":"lb-test","value":1}'
  Write-Host "Request $_ → handled by: $($res.data.processedBy)"
}
```
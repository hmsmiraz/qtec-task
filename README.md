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
Region: ap-southeast-1 (Singapore)
│
▼
Nginx Pod (Reverse Proxy + Load Balancer)
├── Rate limiting: 100 req/sec
├── Security headers
├── Gzip compression
└── Round-robin to API pods
│
▼
Node.js API Pods (3 replicas)
├── Pod 1: qtec-task-api-xxx
├── Pod 2: qtec-task-api-yyy
└── Pod 3: qtec-task-api-zzz
└── HPA: auto-scales 2→6 pods
│
├── HashiCorp Vault  → secrets injection
├── Prometheus       → metrics scraping (UP ✅)
└── Grafana          → metrics visualizationGitHub Actions CI/CD
├── 🧪 Run Tests
├── 🐳 Build & Push Docker Image → Docker Hub
├── 🔒 Security Scan (Trivy)
└── 🚀 Deploy to EKS (zero-downtime rolling update)Terraform
└── Provisions: VPC, EKS, IAM Roles, Security Groups

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
Stage 1 — Builder:
├── Base: node:18-alpine
├── Install ALL deps (including devDeps)
├── Copy source code
├── Run tests (npm test)
└── If tests fail → Docker build fails ✅
Stage 2 — Production:
├── Base: node:18-alpine (fresh)
├── Create non-root user (appuser:1001)
├── Install ONLY production deps
├── Copy source from builder
├── HEALTHCHECK enabled
└── CMD ["node"] for SIGTERM handling
```
### Security Features
- ✅ Non-root user (`appuser` UID 1001)
- ✅ Read-only source files
- ✅ No secrets in image
- ✅ Minimal attack surface (alpine)
- ✅ Tests run during build

### Build & Push
```bash
# Build
docker build -t hmsmiraz/qtec-task:latest ./app

# Push to Docker Hub
docker push hmsmiraz/qtec-task:latest

# Verify non-root
docker run hmsmiraz/qtec-task:latest whoami
# Output: appuser ✅
```

### Docker Hub
```text
Repository: https://hub.docker.com/r/hmsmiraz/qtec-task
Tags:

latest      ← always latest main branch
sha-xxxxxxx ← specific git commit
```
---

## 🔀 Reverse Proxy & Load Balancing

Nginx handles ALL incoming traffic as the single entry point:
```text
Client Request (100 req/sec)
│
▼
Nginx (port 80)
├── Rate limit: 100r/s per IP (burst: 200)
├── Security headers (X-Frame-Options, XSS, etc.)
├── Gzip compression
├── Keepalive: 32 connections
└── Round-robin load balancing
├── ~33 req/sec → API Pod 1
├── ~33 req/sec → API Pod 2
└── ~33 req/sec → API Pod 3
```
### Key Nginx Configuration
```nginx
# Rate limiting
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=100r/s;
limit_req zone=api_limit burst=200 nodelay;

# Upstream with keepalive
upstream qtec_api_backend {
    server qtec-task-api-svc:80;
    keepalive 32;
}

# Proxy settings
proxy_http_version 1.1;
proxy_set_header Connection "";
proxy_set_header X-Real-IP $remote_addr;
```

---

## ⚙️ CI/CD Pipeline

### Pipeline Flow
```text
Push to main branch
│
▼
🧪 Job 1: Run Tests (ubuntu-latest)
├── actions/setup-node@v4 (Node 18)
├── npm ci (cached)
├── npm test (Jest + coverage)
└── Upload coverage artifact
│
▼ (only if tests pass)
🐳 Job 2: Build & Push Docker
├── docker/setup-buildx-action@v3
├── docker/login → Docker Hub
├── docker/metadata → tags: latest, sha-xxxxxxx
├── docker/build-push (BuildKit cache)
└── Push to hmsmiraz/qtec-task
│
├──────────────────────┐
▼                      ▼
🔒 Job 3: Security Scan    🚀 Job 4: Deploy to EKS
└── Trivy scan               ├── Configure AWS credentials
CRITICAL + HIGH           ├── aws eks update-kubeconfig
├── kubectl set image
├── kubectl rollout status
└── kubectl get pods/svc
```
### GitHub Secrets Required

| Secret | Description |
|--------|-------------|
| `DOCKER_USERNAME` | Docker Hub username |
| `DOCKER_PASSWORD` | Docker Hub access token |
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `AWS_REGION` | `ap-southeast-1` |
| `EKS_CLUSTER_NAME` | `qtec-task-eks` |

---

## 📊 Monitoring & Logs

### Prometheus Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `http_requests_total` | Counter | Total HTTP requests by method/route/status |
| `http_request_duration_seconds` | Histogram | Request duration (p50/p95/p99) |
| `http_active_requests` | Gauge | Currently active requests |
| `http_errors_total` | Counter | Total errors (4xx/5xx) |
| `process_resident_memory_bytes` | Gauge | Memory per pod |

### Prometheus Targets (Verified ✅)
```text
prometheus  → localhost:9090/metrics        → UP ✅
qtec-api    → qtec-task-api-svc:80/metrics  → UP ✅
```
### Useful Prometheus Queries
```promql
# Total requests
http_requests_total

# Request rate per second
rate(http_requests_total[1m])

# P95 response time
histogram_quantile(0.95,
  rate(http_request_duration_seconds_bucket[5m]))

# Memory per pod
process_resident_memory_bytes

# Error rate
rate(http_errors_total[5m])

# All targets status
up
```

### Accessing Monitoring
```bash
# EKS (port-forward)
kubectl port-forward svc/prometheus-svc 9090:9090 -n qtec-task
kubectl port-forward svc/grafana-svc    3001:3000 -n qtec-task
kubectl port-forward svc/qtec-vault     8200:8200 -n qtec-task

# URLs
Prometheus: http://localhost:9090
Grafana:    http://localhost:3001  (admin/admin123)
Vault UI:   http://localhost:8200  (token: qtec-root-token)

# Local docker-compose
Prometheus: http://localhost:9090
Grafana:    http://localhost:3001
Vault UI:   http://localhost:8200
```

### Application Logs
```bash
# Kubernetes
kubectl logs -f deployment/qtec-task-api -n qtec-task
kubectl logs -f deployment/qtec-nginx    -n qtec-task
kubectl logs -f deployment/prometheus    -n qtec-task

# All pods
kubectl logs -f -l app=qtec-task -n qtec-task

# Docker Compose
docker compose logs -f api1 api2 api3
docker compose logs -f nginx
```

### Alert Rules
```yaml
# API instance down
APIInstanceDown: up{app="qtec-task"} == 0

# High error rate
HighErrorRate: rate(http_errors_total[5m]) > 0.1

# High response time (P95 > 1s)
HighResponseTime: histogram_quantile(0.95, ...) > 1

# High memory (> 200MB)
HighMemoryUsage: process_resident_memory_bytes > 200MB
```

---

## 🔐 Secrets Management

HashiCorp Vault v1.21.4 manages all sensitive configuration:

### Secrets Structure
```text
Vault KV v2 Engine
└── secret/
└── qtec-task/
├── app/
│   ├── APP_NAME
│   ├── APP_VERSION
│   ├── NODE_ENV
│   ├── SECRET_KEY
│   └── API_KEY
└── database/
├── DB_HOST
├── DB_PORT
├── DB_NAME
├── DB_USER
└── DB_PASSWORD
```
### How Secrets Flow
```text
vault-init Job seeds secrets into Vault
API pod starts with VAULT_ENABLED=true
vault.js client fetches secrets on startup
Secrets injected into process.env
App uses process.env.SECRET_KEY etc.

Secrets are NEVER:
❌ Hardcoded in source code
❌ Committed to git
❌ Stored in Docker image
❌ Exposed in logs (only key names logged)
```
### Security Practices

- ✅ No hardcoded credentials anywhere
- ✅ Vault policy: least privilege (`read` only on `qtec-task/*`)
- ✅ Non-root containers (UID 1001)
- ✅ Secrets injected at runtime
- ✅ `.env` and `terraform.tfvars` gitignored

### Vault Access
```bash
# UI
http://localhost:8200
Method: Token
Token:  qtec-root-token

# CLI
vault kv get secret/qtec-task/app
vault kv get secret/qtec-task/database
```

---

## 🏗️ Infrastructure as Code

Terraform provisions all AWS infrastructure:

### Resources Created

| Resource | Name | Details |
|----------|------|---------|
| VPC | `qtec-task-vpc` | 10.0.0.0/16 |
| Public Subnets | `qtec-task-public-subnet-1/2` | 10.0.1.0/24, 10.0.2.0/24 |
| Private Subnets | `qtec-task-private-subnet-1/2` | 10.0.10.0/24, 10.0.11.0/24 |
| Internet Gateway | `qtec-task-igw` | Public internet |
| NAT Gateway | `qtec-task-nat-gw` | Private node internet |
| EKS Cluster | `qtec-task-eks` | v1.28 |
| Node Group | `qtec-task-node-group` | t3.small, min:1, max:2 |
| IAM Roles | `qtec-task-eks-*` | Cluster + Node roles |
| Security Groups | `qtec-task-eks-*-sg` | Cluster + Nodes |

### Terraform Outputs
```text
aws_region          = "ap-southeast-1"
eks_cluster_name    = "qtec-task-eks"
eks_cluster_arn     = "arn:aws:eks:ap-southeast-1:..."
eks_cluster_endpoint= "https://590A3C39E615AF637C..."
vpc_id              = "vpc-08b52827548c9***"
public_subnet_ids   = ["subnet-08482d499b***", "subnet-08482d499b***"]
private_subnet_ids  = ["subnet-08482d499b***", "subnet-08482d499b***"]
configure_kubectl   = "aws eks update-kubeconfig --region ap-southeast-1 --name qtec-task-eks"
```
### Commands
```bash
cd terraform

# Initialize
terraform init

# Preview changes
terraform plan

# Apply (~15 minutes)
terraform apply

# Destroy (save costs!)
terraform destroy
```

---

## ☸️ Kubernetes & EKS

### Cluster Details
```text
Cluster:  qtec-task-eks
Region:   ap-southeast-1
Version:  1.28
Nodes:    t3.small (1-2 nodes)
```
### Deploy All Resources
```bash
# Configure kubectl
aws eks update-kubeconfig \
  --region ap-southeast-1 \
  --name qtec-task-eks

# Deploy in order
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/vault-deployment.yaml

# Wait for Vault
kubectl wait --for=condition=ready pod \
  -l component=vault -n qtec-task --timeout=60s

kubectl apply -f kubernetes/vault-init-job.yaml
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/secret.yaml
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/nginx-configmap.yaml
kubectl apply -f kubernetes/nginx-deployment.yaml
kubectl apply -f kubernetes/nginx-service.yaml
kubectl apply -f kubernetes/hpa.yaml
kubectl apply -f kubernetes/monitoring/prometheus.yaml
kubectl apply -f kubernetes/monitoring/grafana.yaml
```

### Verify Deployment
```bash
# All pods
kubectl get pods -n qtec-task

# All services + external IPs
kubectl get svc -n qtec-task

# HPA status
kubectl get hpa -n qtec-task

# Full status
kubectl get all -n qtec-task
```

### HPA Auto-Scaling
```text
Normal:      2 pods (minimum)
~50 req/sec: 3 pods
~100 req/sec: 4-5 pods
Peak:        6 pods (maximum)
Scale up:  CPU > 70% OR Memory > 80%
Scale down: After 5min of low usage
```
---

## 🔄 Zero-Downtime Deployment
```text
Rolling Update Strategy
Before:  [v1.0] [v1.0] [v1.0]   ← 3 pods serving traffic
Step 1:  [v1.0] [v1.0] [v1.0] [v2.0]  ← maxSurge: 1 new pod
↓ readinessProbe passes
Step 2:  [v1.0] [v1.0] [v2.0]         ← maxUnavailable: 1 removed
↓ readinessProbe passes
Step 3:  [v1.0] [v1.0] [v2.0] [v2.0]  ← new pod added
↓ readinessProbe passes
Step 4:  [v1.0] [v2.0] [v2.0]         ← old pod removed
↓ readinessProbe passes
Step 5:  [v2.0] [v2.0] [v2.0]         ← complete! ✅
Users NEVER hit a down pod — readinessProbe ensures
Nginx only routes to pods that passed health check
```

### Zero-Downtime Guarantees
```yaml
# 1. Rolling strategy
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1   # Always 2+ pods serving traffic
    maxSurge: 1         # One extra pod during update

# 2. Readiness probe — no traffic until app is ready
readinessProbe:
  httpGet:
    path: /status/ready
    port: 3000
  initialDelaySeconds: 10
  periodSeconds: 10

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

### Trigger Rolling Update
```bash
# Via kubectl
kubectl set image deployment/qtec-task-api \
  api=hmsmiraz/qtec-task:v2.0.0 \
  -n qtec-task

# Watch live
kubectl rollout status deployment/qtec-task-api \
  -n qtec-task

# Rollback if needed
kubectl rollout undo deployment/qtec-task-api \
  -n qtec-task
```

### Via CI/CD (Automatic)
```text
Push code to main branch
→ GitHub Actions runs
→ Tests pass
→ New Docker image built + pushed
→ kubectl set image (new SHA tag)
→ kubectl rollout status (waits for completion)
→ Zero-downtime guaranteed ✅
```
---

## ⚡ Handling ~100 req/sec

### Strategy: Horizontal Scaling + Load Balancing
```text
100 req/sec incoming
│
▼
Nginx (single entry point)
├── Rate limit: 100r/s (burst: 200)
├── keepalive: 32 connections (reuse TCP)
└── Round-robin distribution
├── ~33 req/sec → Pod 1 (Node.js)
├── ~33 req/sec → Pod 2 (Node.js)
└── ~33 req/sec → Pod 3 (Node.js)
Each Node.js pod:
├── Non-blocking async I/O (handles ~50-100 req/sec)
├── 100m-300m CPU allocated
└── HPA adds pods if CPU > 70%
```
### Capacity Math
```text
3 pods × ~50 req/sec = 150 req/sec capacity  ← normal
HPA max 6 pods × ~50 = 300 req/sec maximum   ← peak
Target: 100 req/sec ← well within capacity ✅
```
### Performance Features

| Feature | Impact |
|---------|--------|
| Nginx keepalive (32) | Reuses connections → less overhead |
| Node.js async I/O | Non-blocking → high concurrency |
| HPA auto-scaling | Adds pods under load automatically |
| Resource limits | Prevents memory leaks affecting other pods |
| Gzip compression | Reduces payload size → faster response |

---

## 💻 Local Development

### Prerequisites
```bash
node --version   # v18+
docker --version # v24+
git --version    # any
```

### Setup
```bash
# Clone
git clone https://github.com/hmsmiraz/qtec-task.git
cd qtec-task

# Create .env file
cp app/.env.example app/.env

# Start all services
docker compose up -d

# Check status
docker compose ps

# Run tests
cd app && npm test
```

### Local Services

| Service | URL | Credentials |
|---------|-----|-------------|
| API (via Nginx) | http://localhost | — |
| Prometheus | http://localhost:9090 | — |
| Grafana | http://localhost:3001 | admin/admin123 |
| Vault UI | http://localhost:8200 | token: qtec-root-token |

### Test Load Balancing
```powershell
# PowerShell — shows round-robin working
1..9 | ForEach-Object {
  $res = Invoke-RestMethod `
    -Uri "http://localhost/data" `
    -Method POST `
    -ContentType "application/json" `
    -Body '{"name":"lb-test","value":1}'
  Write-Host "Request $_ → handled by: $($res.data.processedBy)"
}

# Output:
# Request 1 → handled by: qtec-api-1
# Request 2 → handled by: qtec-api-2
# Request 3 → handled by: qtec-api-3
# Request 4 → handled by: qtec-api-1  ← round-robin ✅
```

---

## ☁️ Cloud Deployment

### AWS Resources

| Resource | Value |
|----------|-------|
| Region | ap-southeast-1 (Singapore) |
| EKS Cluster | qtec-task-eks |
| Kubernetes Version | 1.28 |
| Node Type | t3.small |
| VPC ID | vpc-08b52827548c94966 |
| Public URL | `ad37cbfbebcf64651bdad9df622e28b9-168f171f9f65e452.elb.ap-southeast-1.amazonaws.com` |

### Full Deployment Steps
```bash
# 1. Provision AWS infrastructure
cd terraform
terraform init
terraform apply   # ~15 minutes

# 2. Configure kubectl
aws eks update-kubeconfig \
  --region ap-southeast-1 \
  --name qtec-task-eks

# 3. Verify nodes
kubectl get nodes

# 4. Deploy all K8s resources
cd ..
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/vault-deployment.yaml
kubectl wait --for=condition=ready pod \
  -l component=vault -n qtec-task --timeout=60s
kubectl apply -f kubernetes/vault-init-job.yaml
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/secret.yaml
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/nginx-configmap.yaml
kubectl apply -f kubernetes/nginx-deployment.yaml
kubectl apply -f kubernetes/nginx-service.yaml
kubectl apply -f kubernetes/hpa.yaml
kubectl apply -f kubernetes/monitoring/

# 5. Get public URL
kubectl get svc qtec-nginx-svc -n qtec-task

# 6. Test
curl http://YOUR-ELB-URL/status
```

### Access Monitoring on EKS
```bash
# Run in separate terminals
kubectl port-forward svc/prometheus-svc 9090:9090 -n qtec-task
kubectl port-forward svc/grafana-svc    3001:3000 -n qtec-task
kubectl port-forward svc/qtec-vault     8200:8200 -n qtec-task
```

### Cost Management
```bash
# ⚠️ Destroy when not using to avoid charges!
kubectl delete namespace qtec-task
cd terraform && terraform destroy
```

---

## 🧪 Testing

### Unit Tests
```bash
cd app
npm test

# Output:
# PASS tests/status.test.js
# PASS tests/data.test.js
# Tests: 10 passed
# Coverage: ~85%
```

### API Tests
```bash
# Health checks
curl http://YOUR-URL/status
curl http://YOUR-URL/status/health
curl http://YOUR-URL/status/ready
curl http://YOUR-URL/nginx-health
curl http://YOUR-URL/vault-status

# POST data
curl -X POST http://YOUR-URL/data \
  -H "Content-Type: application/json" \
  -d '{"name":"test","value":42,"tags":["devops"]}'

# Prometheus metrics
curl http://YOUR-URL/metrics
```

### Load Test (~100 req/sec)
```powershell
$ELB = "YOUR-ELB-URL"

# Generate 100 requests
1..100 | ForEach-Object {
  Invoke-RestMethod -Uri "http://$ELB/status" -Method GET
  Invoke-RestMethod `
    -Uri "http://$ELB/data" `
    -Method POST `
    -ContentType "application/json" `
    -Body '{"name":"load-test","value":1}'
  Start-Sleep -Milliseconds 100
}
```

---

## 📦 Required Files (Not in Git)

Create these locally before running:

### `terraform/terraform.tfvars`
```hcl
project_name           = "qtec-task"
environment            = "production"
aws_region             = "ap-southeast-1"
vpc_cidr               = "10.0.0.0/16"
public_subnet_cidrs    = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs   = ["10.0.10.0/24", "10.0.11.0/24"]
eks_cluster_version    = "1.28"
eks_node_instance_type = "t3.small"
eks_node_min_size      = 1
eks_node_max_size      = 2
eks_node_desired_size  = 1
eks_node_disk_size     = 20
```

### `app/.env`
```bash
NODE_ENV=production
PORT=3000
APP_NAME=qtec-task
APP_VERSION=1.0.0
LOG_LEVEL=info
VAULT_ADDR=http://qtec-vault:8200
VAULT_TOKEN=qtec-root-token
VAULT_ENABLED=true
```

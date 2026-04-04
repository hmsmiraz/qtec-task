#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Deploy Script: qtec-task
# Usage: bash scripts/deploy.sh
# ─────────────────────────────────────────────────────────────

set -e  # Stop on any error

# ✅ Always work from project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_ROOT"

echo "📁 Working from: $PROJECT_ROOT"

echo "════════════════════════════════════════"
echo "🚀 qtec-task Full Deployment Starting..."
echo "════════════════════════════════════════"

# ── Step 1: Terraform ─────────────────────────────────────────
echo ""
echo "📦 Step 1: Provisioning AWS Infrastructure..."
cd terraform
terraform init -input=false
terraform apply -auto-approve
cd ..
echo "✅ AWS Infrastructure ready!"

# ── Step 2: Configure kubectl ─────────────────────────────────
echo ""
echo "⚙️  Step 2: Configuring kubectl..."
aws eks update-kubeconfig \
  --region ap-southeast-1 \
  --name qtec-task-eks
echo "✅ kubectl configured!"

# ── Step 3: Verify nodes ──────────────────────────────────────
echo ""
echo "🔍 Step 3: Checking EKS nodes..."
kubectl get nodes
echo "✅ Nodes ready!"

# ── Step 4: Deploy Namespace ──────────────────────────────────
echo ""
echo "📁 Step 4: Creating namespace..."
kubectl apply -f kubernetes/namespace.yaml
echo "✅ Namespace created!"

# ── Step 5: Deploy Vault ──────────────────────────────────────
echo ""
echo "🔐 Step 5: Deploying HashiCorp Vault..."
kubectl apply -f kubernetes/vault-deployment.yaml
echo "⏳ Waiting for Vault to be ready..."
kubectl wait --for=condition=ready pod \
  -l component=vault \
  -n qtec-task \
  --timeout=120s
echo "✅ Vault is ready!"

# ── Step 6: Seed Vault Secrets ────────────────────────────────
echo ""
echo "🌱 Step 6: Seeding Vault secrets..."
kubectl apply -f kubernetes/vault-init-job.yaml
sleep 15  # Wait for job to complete
echo "✅ Vault secrets seeded!"

# ── Step 7: Deploy App Config ─────────────────────────────────
echo ""
echo "⚙️  Step 7: Deploying app configuration..."
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/secret.yaml
echo "✅ Config deployed!"

# ── Step 8: Deploy API ────────────────────────────────────────
echo ""
echo "🖥️  Step 8: Deploying API pods..."
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
echo "✅ API deployed!"

# ── Step 9: Deploy Nginx ──────────────────────────────────────
echo ""
echo "🔀 Step 9: Deploying Nginx reverse proxy..."
kubectl apply -f kubernetes/nginx-configmap.yaml
kubectl apply -f kubernetes/nginx-deployment.yaml
kubectl apply -f kubernetes/nginx-service.yaml
echo "✅ Nginx deployed!"

# ── Step 10: Deploy HPA ───────────────────────────────────────
echo ""
echo "📈 Step 10: Deploying HPA auto-scaler..."
kubectl apply -f kubernetes/hpa.yaml
echo "✅ HPA deployed!"

# ── Step 11: Deploy Monitoring ────────────────────────────────
echo ""
echo "📊 Step 11: Deploying Prometheus + Grafana..."
kubectl apply -f kubernetes/monitoring/prometheus.yaml
kubectl apply -f kubernetes/monitoring/grafana.yaml
echo "✅ Monitoring deployed!"

# ── Step 12: Wait for all pods ────────────────────────────────
echo ""
echo "⏳ Step 12: Waiting for all pods to be ready..."
kubectl wait --for=condition=ready pod \
  -l app=qtec-task \
  -n qtec-task \
  --timeout=300s

# ── Final Status ──────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
echo "✅ DEPLOYMENT COMPLETE!"
echo "════════════════════════════════════════"
echo ""
echo "📋 All Resources:"
kubectl get all -n qtec-task
echo ""
echo "🌐 Public URL:"
kubectl get svc qtec-nginx-svc -n qtec-task \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
echo ""
echo ""
echo "📊 Monitoring (run in separate terminals):"
echo "  kubectl port-forward svc/prometheus-svc 9090:9090 -n qtec-task"
echo "  kubectl port-forward svc/grafana-svc 3001:3000 -n qtec-task"
echo "  kubectl port-forward svc/qtec-vault 8200:8200 -n qtec-task"
echo ""
echo "════════════════════════════════════════"
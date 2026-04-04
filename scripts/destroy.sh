#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Destroy Script: qtec-task
# Usage: bash scripts/destroy.sh (from ANY folder)
# ─────────────────────────────────────────────────────────────

set -e

# ✅ Always work from project root regardless of where script is run
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_ROOT"

echo "📁 Working from: $PROJECT_ROOT"
echo "════════════════════════════════════════"
echo "💣 qtec-task Destroy Starting..."
echo "⚠️  This will delete ALL resources!"
echo "════════════════════════════════════════"

# ── Confirm ───────────────────────────────────────────────────
read -p "Are you sure? Type 'yes' to confirm: " confirm
if [ "$confirm" != "yes" ]; then
  echo "❌ Cancelled."
  exit 1
fi

# ── Step 1: Delete K8s resources ─────────────────────────────
echo ""
echo "🗑️  Step 1: Deleting Kubernetes resources..."
kubectl delete namespace qtec-task --ignore-not-found=true
echo "✅ K8s resources deleted!"

# ── Step 2: Wait for namespace deletion ──────────────────────
echo ""
echo "⏳ Step 2: Waiting for namespace to be fully deleted..."
kubectl wait --for=delete namespace/qtec-task \
  --timeout=120s 2>/dev/null || true
echo "✅ Namespace deleted!"

# ── Step 3: Destroy Terraform ─────────────────────────────────
echo ""
echo "💣 Step 3: Destroying AWS infrastructure..."
cd "$PROJECT_ROOT/terraform"    # ✅ Always correct path
terraform destroy -auto-approve
cd "$PROJECT_ROOT"
echo "✅ AWS infrastructure destroyed!"

# ── Final ─────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
echo "✅ EVERYTHING DESTROYED!"
echo "💰 You are no longer being charged"
echo "════════════════════════════════════════"
echo ""
echo "To redeploy later run:"
echo "  bash scripts/deploy.sh"
echo ""
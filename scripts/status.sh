#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Status Script: qtec-task
# Usage: bash scripts/status.sh
# ─────────────────────────────────────────────────────────────

echo "════════════════════════════════════════"
echo "📋 qtec-task Status Check"
echo "════════════════════════════════════════"

echo ""
echo "🔍 Pods:"
kubectl get pods -n qtec-task

echo ""
echo "🌐 Services:"
kubectl get svc -n qtec-task

echo ""
echo "📈 HPA:"
kubectl get hpa -n qtec-task

echo ""
echo "🌐 Public URL:"
kubectl get svc qtec-nginx-svc -n qtec-task \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
echo ""

echo ""
echo "════════════════════════════════════════"
echo "📊 Access Monitoring:"
echo "  Terminal 1: kubectl port-forward svc/prometheus-svc 9090:9090 -n qtec-task"
echo "  Terminal 2: kubectl port-forward svc/grafana-svc 3001:3000 -n qtec-task"
echo "  Terminal 3: kubectl port-forward svc/qtec-vault 8200:8200 -n qtec-task"
echo "════════════════════════════════════════"
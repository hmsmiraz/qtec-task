#!/bin/sh
# ─────────────────────────────────────────────────────────────
# Vault Initialization Script
# Runs once when Vault container starts
# Creates secrets that our API will consume
# ─────────────────────────────────────────────────────────────

set -e

VAULT_ADDR="http://vault:8200"
VAULT_TOKEN="qtec-root-token"

echo "⏳ Waiting for Vault to be ready..."
until curl -fs "${VAULT_ADDR}/v1/sys/health" > /dev/null 2>&1; do
  sleep 2
  echo "   Still waiting..."
done

echo "✅ Vault is ready!"

# ── Enable KV Secrets Engine v2 ───────────────────────────────
echo "📦 Enabling KV secrets engine..."
curl -s \
  --header "X-Vault-Token: ${VAULT_TOKEN}" \
  --request POST \
  --data '{"type":"kv","options":{"version":"2"}}' \
  "${VAULT_ADDR}/v1/sys/mounts/secret" || true

# ── Store App Secrets ──────────────────────────────────────────
echo "🔐 Storing application secrets..."
curl -s \
  --header "X-Vault-Token: ${VAULT_TOKEN}" \
  --request POST \
  --data '{
    "data": {
      "APP_NAME": "qtec-task",
      "APP_VERSION": "1.0.0",
      "NODE_ENV": "production",
      "PORT": "3000",
      "LOG_LEVEL": "info",
      "SECRET_KEY": "qtec-super-secret-key-2024",
      "API_KEY": "qtec-api-key-abc123"
    }
  }' \
  "${VAULT_ADDR}/v1/secret/data/qtec-task/app"

# ── Store Database Secrets ─────────────────────────────────────
echo "🗄️ Storing database secrets..."
curl -s \
  --header "X-Vault-Token: ${VAULT_TOKEN}" \
  --request POST \
  --data '{
    "data": {
      "DB_HOST": "localhost",
      "DB_PORT": "5432",
      "DB_NAME": "qtec_db",
      "DB_USER": "qtec_user",
      "DB_PASSWORD": "qtec-db-password-2024"
    }
  }' \
  "${VAULT_ADDR}/v1/secret/data/qtec-task/database"

# ── Write Policy ───────────────────────────────────────────────
echo "📋 Writing Vault policy..."
curl -s \
  --header "X-Vault-Token: ${VAULT_TOKEN}" \
  --request PUT \
  --data '{
    "policy": "path \"secret/data/qtec-task/*\" { capabilities = [\"read\", \"list\"] }"
  }' \
  "${VAULT_ADDR}/v1/sys/policies/acl/qtec-policy"

# ── Create App Token ───────────────────────────────────────────
echo "🎟️ Creating app token..."
APP_TOKEN=$(curl -s \
  --header "X-Vault-Token: ${VAULT_TOKEN}" \
  --request POST \
  --data '{
    "policies": ["qtec-policy"],
    "ttl": "24h",
    "renewable": true,
    "display_name": "qtec-task-app"
  }' \
  "${VAULT_ADDR}/v1/auth/token/create" | \
  grep -o '"client_token":"[^"]*"' | \
  cut -d'"' -f4)

echo ""
echo "════════════════════════════════════════"
echo "✅ Vault initialized successfully!"
echo "════════════════════════════════════════"
echo "🌐 Vault UI:     http://localhost:8200"
echo "🔑 Root Token:   ${VAULT_TOKEN}"
echo "🎟️ App Token:    ${APP_TOKEN}"
echo "════════════════════════════════════════"

# Save app token to shared volume so API can use it
echo "${APP_TOKEN}" > /vault/init/app-token.txt
echo "💾 App token saved to /vault/init/app-token.txt"
# ─────────────────────────────────────────────────────────────
# Vault Policy: qtec-task
# Defines what secrets the qtec-task app can access
# Principle of least privilege — only what's needed
# ─────────────────────────────────────────────────────────────

# Allow reading app secrets
path "secret/data/qtec-task/*" {
  capabilities = ["read", "list"]
}

# Allow reading database credentials
path "secret/data/qtec-task/database" {
  capabilities = ["read"]
}

# Allow reading API keys
path "secret/data/qtec-task/api" {
  capabilities = ["read"]
}

# Allow token renewal
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Allow token lookup
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
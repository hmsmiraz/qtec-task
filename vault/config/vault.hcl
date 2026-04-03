# ─────────────────────────────────────────────────────────────
# HashiCorp Vault Server Configuration
# Mode: Development (for local/docker)
# In Production (K8s Step 8): use HA mode with etcd backend
# ─────────────────────────────────────────────────────────────

# Storage backend: file-based for docker
# In K8s: use integrated raft or consul storage
storage "file" {
  path = "/vault/data"
}

# HTTP listener
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true   # TLS handled by Nginx in production
}

# Vault UI enabled
ui = true

# API address
api_addr = "http://0.0.0.0:8200"

# Log level
log_level = "info"
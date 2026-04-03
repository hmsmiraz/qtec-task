// ─────────────────────────────────────────────────────────────
// HashiCorp Vault Client
// Fetches secrets from Vault and injects into process.env
// In K8s (Step 8): Vault Agent Injector handles this
// ─────────────────────────────────────────────────────────────

const VAULT_ADDR  = process.env.VAULT_ADDR  || 'http://vault:8200';
const VAULT_TOKEN = process.env.VAULT_TOKEN || 'qtec-root-token';

// ── Fetch secrets from Vault path ─────────────────────────────
const getSecrets = async (path) => {
  try {
    const response = await fetch(
      `${VAULT_ADDR}/v1/secret/data/${path}`,
      {
        headers: {
          'X-Vault-Token': VAULT_TOKEN,
          'Content-Type': 'application/json',
        },
      }
    );

    if (!response.ok) {
      throw new Error(`Vault responded with status: ${response.status}`);
    }

    const result = await response.json();
    return result.data?.data || {};

  } catch (error) {
    console.error(`[Vault] Failed to fetch secrets from ${path}:`, error.message);
    return {};
  }
};

// ── Load all secrets and inject into process.env ──────────────
const loadSecrets = async () => {
  console.log('[Vault] Loading secrets from HashiCorp Vault...');
  console.log(`[Vault] Address: ${VAULT_ADDR}`);

  try {
    // Fetch app secrets
    const appSecrets = await getSecrets('qtec-task/app');

    // Fetch database secrets
    const dbSecrets = await getSecrets('qtec-task/database');

    // Merge all secrets
    const allSecrets = { ...appSecrets, ...dbSecrets };

    // Inject into process.env
    // Only set if not already set (env vars take priority)
    let loadedCount = 0;
    for (const [key, value] of Object.entries(allSecrets)) {
      if (!process.env[key]) {
        process.env[key] = value;
        loadedCount++;
      }
    }

    console.log(`[Vault] ✅ Loaded ${loadedCount} secrets successfully`);

    // Log which secrets were loaded (NOT their values)
    const secretKeys = Object.keys(allSecrets);
    console.log(`[Vault] Secrets loaded: ${secretKeys.join(', ')}`);

    return true;

  } catch (error) {
    console.error('[Vault] ❌ Failed to load secrets:', error.message);
    console.warn('[Vault] Continuing with environment variables only...');
    return false;
  }
};

// ── Health check: verify Vault connection ─────────────────────
const checkVaultHealth = async () => {
  try {
    const response = await fetch(`${VAULT_ADDR}/v1/sys/health`);
    const data = await response.json();
    return {
      connected: true,
      initialized: data.initialized,
      sealed: data.sealed,
      version: data.version,
    };
  } catch (error) {
    return {
      connected: false,
      error: error.message,
    };
  }
};

module.exports = { loadSecrets, getSecrets, checkVaultHealth };
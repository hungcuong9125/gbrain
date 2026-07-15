#!/usr/bin/env bash
set -Eeuo pipefail

echo "[entrypoint] GBrain Dokploy startup"
echo "[entrypoint] Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# ── Wait for Postgres ──────────────────────────────────
if [ -n "${DATABASE_URL:-}" ]; then
  echo "[entrypoint] Waiting for Postgres at ${DATABASE_URL}..."
  until pg_isready -d "$DATABASE_URL" >/dev/null 2>&1; do
    sleep 2
  done
  echo "[entrypoint] Postgres ready"
fi

# ── Config model tiers ─────────────────────────────────
MODEL="${GBRAIN_MODEL:-openai:gpt-4o-mini}"
echo "[entrypoint] Configuring model tiers → $MODEL"

gbrain config set models.think "$MODEL"
gbrain config set models.default "$MODEL"
gbrain config set chat_model "$MODEL"
gbrain config set expansion_model "$MODEL"

for tier in deep reasoning subagent utility; do
  gbrain config set "models.tier.${tier}" "$MODEL"
done

# ── Enable gateway-native loop (provider-agnostic) ────
gbrain config set agent.use_gateway_loop true --force

# ── Apply migrations ──────────────────────────────────
echo "[entrypoint] Applying database migrations..."
gbrain apply-migrations --yes --non-interactive

# ── Embed stale pages (optional) ──────────────────────
if [[ "${GBRAIN_EMBED_ON_START:-false}" == "true" ]]; then
  echo "[entrypoint] Embedding stale pages..."
  gbrain embed --stale
else
  echo "[entrypoint] Skipping embed (set GBRAIN_EMBED_ON_START=true to enable)"
fi

echo "[entrypoint] Starting GBrain server..."

exec gbrain serve \
  --http \
  --port "${PORT:-3131}" \
  --bind 0.0.0.0 \
  --public-url "${PUBLIC_URL:-}" \
  "$@"

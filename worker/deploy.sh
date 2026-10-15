#!/usr/bin/env bash
# Deploy do Worker gree-family (sync da família).
# Auth: usa worker/.cloudflare-token (CLOUDFLARE_API_TOKEN) se existir,
# senão a sessão do `wrangler login`.
set -euo pipefail
cd "$(dirname "$0")"

if [ -f .cloudflare-token ]; then
  export CLOUDFLARE_API_TOKEN="$(tr -d '[:space:]' < .cloudflare-token)"
fi

# cria o namespace KV na primeira vez e grava o id no wrangler.toml
if grep -q "PREENCHER_PELO_DEPLOY" wrangler.toml; then
  ID="$(npx --yes wrangler kv namespace create GREE_FAMILY 2>&1 | grep -oE 'id = "[a-f0-9]+"' | head -1 | grep -oE '[a-f0-9]{32}')"
  [ -n "$ID" ] || { echo "ERRO: não consegui criar o namespace KV (wrangler login?)"; exit 1; }
  sed -i "s/PREENCHER_PELO_DEPLOY/$ID/" wrangler.toml
  echo ">>> KV namespace: $ID"
fi

npx --yes wrangler deploy

echo ">>> URL do Worker:"
npx --yes wrangler deployments list 2>/dev/null | head -5 || true

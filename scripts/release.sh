#!/usr/bin/env bash
# Release via GitHub Actions — só cria a tag; o Actions compila, assina e publica.
# O app instalado detecta e instala sozinho na próxima abertura.
#
# Uso:  ./scripts/release.sh 1.0.1
# (ou manualmente:  gh workflow run release.yml -f version=1.0.1)
set -euo pipefail

VER="${1:?use: ./scripts/release.sh 1.0.1}"
cd "$(dirname "$0")/.."

git -c gpg.program="C:/Program Files/Git/usr/bin/gpg.exe" tag "v$VER"
git push origin "v$VER"

echo ">>> tag v$VER enviada — acompanhe em github.com/matheusvcl/Gree-App/actions"

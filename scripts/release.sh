#!/usr/bin/env bash
# Release via GitHub Actions — bumpa a versão, cria a tag; o Actions compila,
# assina e publica. O app instalado detecta e instala sozinho na próxima abertura.
#
# Uso:  ./scripts/release.sh 1.0.3
# (ou manualmente:  gh workflow run release.yml -f version=1.0.3)
set -euo pipefail

VER="${1:?use: ./scripts/release.sh 1.0.3}"
cd "$(dirname "$0")/.."

# mantém o pubspec e a versão do app juntos (a tela de versão sempre correta)
sed -i "s/^version: .*/version: $VER/" pubspec.yaml
sed -i "s/const String kAppVersion = .*/const String kAppVersion = '$VER';/" lib/version.dart
git add pubspec.yaml lib/version.dart
git -c gpg.program="C:/Program Files/Git/usr/bin/gpg.exe" commit -m "release: Gree App v$VER" -m "Bump de versão para $VER." || true
git push origin main

git -c gpg.program="C:/Program Files/Git/usr/bin/gpg.exe" tag -a "v$VER" -m "release: Gree App v$VER"
git push origin "v$VER"

echo ">>> tag v$VER enviada — acompanhe em github.com/matheusvcl/Gree-App/actions"

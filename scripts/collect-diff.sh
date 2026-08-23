#!/usr/bin/env bash
# Recopila contexto para el agente de code review (pegar en Cursor o adjuntar al prompt).
# Uso: ./scripts/collect-diff.sh [repo-path] [base-branch]
set -euo pipefail

REPO="${1:-.}"
BASE="${2:-main}"

cd "$REPO"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Error: $REPO no es un repositorio git" >&2
  exit 1
fi

echo "# Code review — contexto git"
echo ""
echo "**Repo:** $(basename "$(pwd)")"
echo "**Base:** $BASE"
echo "**HEAD:** $(git rev-parse --short HEAD)  ($(git branch --show-current))"
echo ""
echo "## Archivos cambiados"
git diff --stat "$BASE...HEAD" 2>/dev/null || git diff --stat "$BASE" HEAD
echo ""
echo "## Diff (truncado a 400 líneas)"
git diff "$BASE...HEAD" 2>/dev/null | head -n 400 || git diff "$BASE" HEAD | head -n 400

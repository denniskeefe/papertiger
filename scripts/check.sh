#!/usr/bin/env bash
# Run every repo check. Used by CI; run locally before pushing.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== embedded scripts in sync"
python3 scripts/embedded.py check

echo "== shell syntax"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
python3 scripts/embedded.py extract wizard-sh > "$tmp/wizard.sh"
bash -n deploy.sh
bash -n "$tmp/wizard.sh"

if command -v shellcheck >/dev/null; then
  echo "== shellcheck"
  shellcheck -S warning deploy.sh "$tmp/wizard.sh"
else
  echo "== shellcheck not installed, skipping (CI runs it)"
fi

echo "== smoke test"
[ -d tests/node_modules ] || { echo "Run: (cd tests && npm ci && npx playwright install chromium)"; exit 1; }
node tests/smoke.mjs

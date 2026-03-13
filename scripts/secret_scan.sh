#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_DIR="$ROOT_DIR/reports/security"
REPORT_FILE="$REPORT_DIR/secret-scan.txt"

mkdir -p "$REPORT_DIR"

PATTERN='(-----BEGIN [A-Z ]+PRIVATE KEY-----|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36,}|AIza[0-9A-Za-z_-]{20,})'

git -C "$ROOT_DIR" grep -nI -E "$PATTERN" -- \
  . \
  ':(exclude)docs/**' \
  ':(exclude)**/*.example.*' \
  ':(exclude)mobile/nearpick/lib/firebase_options.example.dart' \
  ':(exclude)mobile/nearpick/android/app/google-services.example.json' \
  ':(exclude)mobile/nearpick/web/firebase-messaging-sw.example.js' \
  ':(exclude)scripts/secret_scan.sh' \
  > "$REPORT_FILE" || true

if [[ -s "$REPORT_FILE" ]]; then
  echo "Secret scan talalatok:"
  cat "$REPORT_FILE"
  exit 1
fi

echo "Nem talalhato magas kockazatu secret-minta." > "$REPORT_FILE"

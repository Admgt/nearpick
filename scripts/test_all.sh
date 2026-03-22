#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/mobile/nearpick"

echo "==> Flutter quality gate futtatasa: $APP_DIR"
cd "$APP_DIR"

echo "==> flutter pub get"
flutter pub get

echo "==> dart format gate"
dart format --set-exit-if-changed .

echo "==> flutter analyze"
flutter analyze

if [ -d "$HOME/.pub-cache/bin" ]; then
  export PATH="$PATH:$HOME/.pub-cache/bin"
fi

if [ -n "${LOCALAPPDATA:-}" ] && [ -d "${LOCALAPPDATA}/Pub/Cache/bin" ]; then
  export PATH="$PATH:${LOCALAPPDATA}/Pub/Cache/bin"
fi

if ! command -v tojunit >/dev/null 2>&1; then
  echo "==> junitreport telepites (tojunit)"
  dart pub global activate junitreport
else
  echo "==> tojunit mar telepitve"
fi

echo "==> unit/widget tesztek + junit"
mkdir -p reports
set -o pipefail
flutter test --machine | tojunit > reports/junit-flutter.xml

echo "==> integration_test ellenorzes"
if [ -d "integration_test" ] && find integration_test -type f -name "*.dart" | grep -q .; then
  flutter test integration_test
else
  echo "Nincs integration_test fajl, integration lepes kihagyva."
fi

echo "==> Kesz. JUnit: mobile/nearpick/reports/junit-flutter.xml"

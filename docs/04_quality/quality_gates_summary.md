# Quality gate összefoglaló

## Bevezetett kapuk
- Flutter formázási kapu: `dart format --set-exit-if-changed .`
- Flutter statikus analízis: `flutter analyze`
- Flutter automata tesztek: unit, widget és workflow integration suite a `test/**` alatt
- Opcionális valódi `integration_test` futás csak létező `*_test.dart` esetén
- Flutter dependency sebezhetőségi ellenőrzés: `dart run tool/audit_pub_dependencies.dart --report-dir=reports`
- Functions JavaScript quality gate: `npm run lint`
- Functions tesztek: `npm test`
- Functions dependency sebezhetőségi ellenőrzés: `npm run scan:deps`
- Repo szintű secret scan: `bash scripts/secret_scan.sh` vagy Windows alatt `powershell -ExecutionPolicy Bypass -File scripts/secret_scan.ps1`
- Build artifact mentés: Flutter web build
- Evidence artifact mentés: teszt- és security riportok

## Evidence források
- GitHub Actions artifactok:
  - `flutter-junit`
  - `quality-test-evidence`
  - `quality-security-evidence`
  - `nearpick-web-build`
- Forrásfájlok és konfiguráció:
  - [ci.yml](../../.github/workflows/ci.yml)
  - [firestore.rules](../../firestore.rules)
  - [functions/package.json](../../functions/package.json)
  - [audit_pub_dependencies.dart](../../mobile/nearpick/tool/audit_pub_dependencies.dart)
  - [scripts/secret_scan.sh](../../scripts/secret_scan.sh)
  - [scripts/secret_scan.ps1](../../scripts/secret_scan.ps1)

## Jelenlegi maradó kockázatok
- A mobil UI/E2E rétegben már van tényleges `integration_test/**/*_test.dart` suite, de még csak egy core flow-val.
- A Firestore rules ellenőrzése reprezentatív és hasznos, de nem teljes emulatoros allow/deny bizonyítás.
- A secret scan mintaalapú, ezért nem helyettesít teljes SAST vagy fejlett DLP eszközt.
- A Flutter dependency audit OSV advisory feedtől és hálózati elérhetőségtől függ; ez nem helyettesít teljes SBOM vagy SCA platformot.

## Következő ajánlott lépések
- Firebase Emulator alapú rules teszt bootstrap bevezetése a legkritikusabb kollekciókra.
- További `integration_test` UI-flow-k hozzáadása a reservation és completion utakra.
- SBOM vagy fejlettebb SCA ellenőrzés hozzáadása a meglévő OSV audit mellé.
- Acceptance feature-k automata összekötése smoke vagy BDD runnerrel.

# Quality gate összefoglaló

## Bevezetett kapuk
- Flutter formázási kapu: `dart format --set-exit-if-changed .`
- Flutter statikus analízis: `flutter analyze`
- Flutter automata tesztek: unit, widget és workflow integration suite a `test/**` alatt
- Opcionális valódi `integration_test` futás csak létező `*_test.dart` esetén
- Functions JavaScript quality gate: `npm run lint`
- Functions tesztek: `npm test`
- Dependency sebezhetőségi ellenőrzés: `npm run scan:deps`
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
  - [scripts/secret_scan.sh](../../scripts/secret_scan.sh)
  - [scripts/secret_scan.ps1](../../scripts/secret_scan.ps1)

## Jelenlegi maradó kockázatok
- A mobil UI/E2E rétegben már van tényleges `integration_test/**/*_test.dart` suite, de még csak egy core flow-val.
- A Firestore rules ellenőrzése reprezentatív és hasznos, de nem teljes emulatoros allow/deny bizonyítás.
- A secret scan mintaalapú, ezért nem helyettesít teljes SAST vagy fejlett DLP eszközt.
- A dependency audit jelenleg a `functions` csomagra koncentrál; a Flutter dependency-vulnerability ellenőrzés külön még nincs bevezetve.

## Következő ajánlott lépések
- Firebase Emulator alapú rules teszt bootstrap bevezetése a legkritikusabb kollekciókra.
- További `integration_test` UI-flow-k hozzáadása a reservation és completion utakra.
- Flutter dependency audit vagy SBOM alapú ellenőrzés hozzáadása.
- Acceptance feature-k automata összekötése smoke vagy BDD runnerrel.

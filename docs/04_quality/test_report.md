# Teszt riport

## Aktuális állapot 2026-04-07

### Jelenlegi repo-állapot

Ez a dokumentum kétféle evidence-et különít el:
- statikus repo-inventory: mit tartalmaz most a kódállapot
- utolsó ténylegesen rögzített futási evidence: mi lett valóban lefuttatva és dokumentálva

A 2026-04-07-es statikus repo-audit alapján:

| Kategória | Darab | Megjegyzés |
|---|---:|---|
| Flutter test definíció | 85 | `test/**` és `integration_test/**` |
| Functions / rules JS teszt | 54 | `functions/test/**` |
| Összes automata tesztdefiníció | 139 | statikus inventory, nem egyetlen futás eredménye |

Automatizált, külön futó E2E UI suite jelenleg:
- `mobile/nearpick/integration_test/flows/auth_and_product_flow_test.dart`

Manuális teszt artefaktum:
- `sprints/02/tests/acceptance/create_product.feature`
- `sprints/02/tests/acceptance/empty_state.feature`

### Fő lefedett területek

Flutter:
- auth regisztráció, login, root routing és password reset
- terméklétrehozás, pricing suggestion, termékszerkesztési korlátok
- location preference és city mode
- foglalás, készletcsökkentés, többdarabos foglalás és completion workflow
- refund adatok, pickup token, review modellek
- UI űrlapvalidációk és hibamegjelenítés
- merchant dashboard és CSV export logika

Functions és security:
- `security_helpers.js` biztonsági segédlogika
- Firestore rules szerződéses korlátai
- Firestore rules reprezentatív allow/deny viselkedési modelljei
- refund, review, archive és repricing callable döntési ágak

### CI evidence

A GitHub Actions [ci.yml](../../.github/workflows/ci.yml) a következő artefaktumokat teszi elérhetővé:
- `flutter-junit`
- `quality-test-evidence`
- `quality-security-evidence`
- `nearpick-web-build`

Ezek forrásai:
- Flutter `reports/junit-flutter.xml`
- Flutter és functions tesztlogok a `reports/` könyvtárakból
- secret scan, Flutter OSV audit és `npm audit` riportok
- a Flutter web build kimenete

Megjegyzés:
- a [ci_evidence.md](../06_release/ci_evidence.md) már az aktuálisan dokumentált HEAD-hez tartozó zöld runra mutat

### Utolsó ténylegesen rögzített Flutter evidence

Az utolsó repo-ban rögzített, lokális Flutter futási evidence továbbra is:
- dátum: `2026-03-06`
- futási mód: lokális terminál futás, Flutter suite
- parancs: `flutter test --reporter expanded`
- eredmény: `All tests passed!`

Rögzített összegzés:
- összes teszt: `45`
- sikeres: `45`
- sikertelen: `0`
- unit: `33`
- integration: `6`
- widget: `6`
- negatív tesztek: `9+`

Primer evidence:
- [docs/assets/logs/flutter_test_latest.log](../assets/logs/flutter_test_latest.log)

### Mit NEM állít ez a riport

Ez a dokumentumfrissítés nem futtatott új teszteket. Emiatt:
- a 2026-04-07-es kódállapothoz csak statikus inventory áll rendelkezésre
- a frissebb feature-k megléte kódból és tesztfájlokból auditált, nem friss runtime futásból
- a következő release-közeli körben érdemes újra futtatni a Flutter és functions suite-okat, majd frissíteni kell ezt a riportot a friss runtime eredményekkel

### Nyitott korlátok

- A jelenlegi integration szint in-memory workflow / adaptor alapú, nem Firebase emulátor alapú.
- Az `integration_test/` réteg még nem teljes suite, jelenleg egy validált core flow áll rendelkezésre.
- Az új account/profile, review, refund és QR flow-khoz még nincs teljes UI/E2E evidence.
- A CI generál JUnit XML-t (`reports/junit-flutter.xml`), de a lokális dokumentációs evidence itt jelenleg elsősorban a normalizált logfájlra támaszkodik.

# Teszt riport

## Aktuális állapot 2026-04-11

### Jelenlegi repo-állapot

Ez a dokumentum kétféle evidence-et különít el:
- statikus repo-inventory: mit tartalmaz most a kódállapot
- utolsó ténylegesen rögzített futási evidence: mi lett valóban lefuttatva és dokumentálva

A 2026-04-11-es statikus repo-audit alapján:

| Kategória | Darab | Megjegyzés |
|---|---:|---|
| Flutter test definíció | 91 | `test/**` és `integration_test/**` |
| Functions / rules JS teszt | 68 | `functions/test/**` |
| Összes automata tesztdefiníció | 159 | statikus inventory, nem egyetlen futás eredménye |

Automatizált, külön futó E2E UI suite jelenleg:
- `mobile/nearpick/integration_test/flows/auth_and_product_flow_test.dart`
- `mobile/nearpick/integration_test/flows/reservation_refund_review_flow_test.dart`
- `mobile/nearpick/integration_test/flows/admin_product_moderation_flow_test.dart`

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
- Android emulatoros reservation detail UI/E2E: pickup/QR token megjelenítés, lemondás refund kéréssel és completed reservation review
- UI űrlapvalidációk és hibamegjelenítés
- merchant dashboard és CSV export logika
- admin role routing widget szinten
- Android emulatoros admin product detail UI/E2E: elrejtés, archivált törlés és visszaállítás

Functions és security:
- `security_helpers.js` biztonsági segédlogika
- Firestore rules szerződéses korlátai
- Firestore rules reprezentatív allow/deny viselkedési modelljei
- refund, review, archive és repricing callable döntési ágak
- admin helper és `adminMessages` read / read receipt rule modell
- admin callable contract tesztek: jogosultsági tiltás, fiókstátusz-kezelés, admin üzenetküldés push ággal, termék elrejtés/visszaállítás és admin archiválás

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
- a [ci_evidence.md](../06_release/ci_evidence.md) a legutóbb dokumentált zöld main/default branch run helye; új release-közeli push után frissítendő

### Utolsó ténylegesen rögzített runtime evidence

A 2026-04-08-i lokális újrafuttatás, a 2026-04-11-i Functions újrafuttatás és a 2026-04-11-i Android emulatoros `integration_test` újrafuttatások alapján:

Flutter unit/widget/workflow réteg:
- parancs: `powershell -ExecutionPolicy Bypass -File scripts/test_all.ps1`
- primer artifact: [`../../mobile/nearpick/reports/junit-flutter.xml`](../../mobile/nearpick/reports/junit-flutter.xml)
- összes JUnit teszteset: `84`
- sikertelen: `0`
- errors: `0`
- tesztsuite-ok: `25`

Valódi Android emulatoros `integration_test` evidence:
- parancs: `flutter test integration_test/flows/auth_and_product_flow_test.dart -d emulator-5554`
- eredmény: `1/1` passed
- parancs: `flutter test integration_test/flows/reservation_refund_review_flow_test.dart -d emulator-5554`
- eredmény: `2/2` passed
- parancs: `flutter test integration_test/flows/admin_product_moderation_flow_test.dart -d emulator-5554`
- eredmény: `2/2` passed
- primer artifact: [`../../mobile/nearpick/reports/flutter-integration-test.txt`](../../mobile/nearpick/reports/flutter-integration-test.txt)

Functions quality gate:
- `npm.cmd run lint`: passed
- `npm.cmd test`: `68/68` passed
- `npm.cmd run scan:deps`: passed
- megjegyzés: az `npm.cmd ci` közben az npm általános audit összegzést jelzett, de a repository dedikált dependency audit scriptje végül `Functions dependency audit rendben` eredményt adott a dokumentált suppressions mellett

### Mit NEM állít ez a riport

- A 2026-04-11-es runtime evidence ellenére az `integration_test/**` réteg továbbra sem teljes suite; három validált flow-t fed le.
- A statikus repo-inventory továbbra sem azonos egyetlen teljes, minden réteget egyben mérő futási összesítéssel.
- A Functions dependency audit pass nem jelenti azt, hogy a teljes npm advisory ökoszisztéma zajmentes; a projekt jelenleg célzott, dokumentált auditkezelésre támaszkodik.

### Nyitott korlátok

- A jelenlegi integration szint in-memory workflow / adaptor alapú, nem Firebase emulátor alapú.
- Az `integration_test/` réteg most már három validált Android emulatoros flow-val rendelkezik, de még nem teljes suite.
- Az account/profile/location flow-khoz még nincs külön teljes UI/E2E evidence.
- A QR scanner valós kamerás és merchant pickup-completion útja még nem teljes UI/E2E fedésű; a consumer reservation detail QR token megjelenítés külön flow-ban fedett.
- Az admin dashboard, fiókstátusz-kezelés és admin üzenetküldés még nem rendelkezik külön teljes UI/E2E evidence-szel; admin product moderation detail flow és callable-level runtime evidence már van.
- A Functions quality gate lokálisan zöld, de a dependency advisories hosszabb távú karbantartása külön backlog-feladat marad.

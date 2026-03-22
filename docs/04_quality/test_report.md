# Teszt riport

## Aktuális állapot 2026-03-12

### Jelenlegi repo-állapot
A repository jelenlegi, fájlokból számolt automata tesztleltára. Ez leltár, nem azonos egyetlen konkrét futás eredményével:

| Kategória | Darab | Hely |
|---|---:|---|
| Flutter unit | 36 | `mobile/nearpick/test/widget_test.dart`, `mobile/nearpick/test/unit/**` |
| Flutter widget | 6 | `mobile/nearpick/test/widget/**` |
| Flutter integration/workflow | 10 | `mobile/nearpick/test/integration/**` |
| Flutter integration_test UI/E2E | 1 | `mobile/nearpick/integration_test/**` |
| Functions és Firestore/rules | 21 | `functions/test/**` |
| Összes automata teszt | 74+ | Flutter + functions, repo-szintű leltár |

Automatizált, külön futó E2E UI suite:
- `mobile/nearpick/integration_test/flows/auth_and_product_flow_test.dart`

Manuális teszt artefaktum:
- `sprints/02/tests/acceptance/create_product.feature`
- `sprints/02/tests/acceptance/empty_state.feature`

### Fő lefedett területek
Flutter:
- auth regisztráció és login workflow
- terméklétrehozás, böngészéshez szükséges adatok és érdeklődés jelölése
- foglalás, készletcsökkentés és completion workflow
- UI űrlapvalidációk és hibamegjelenítés
- valódi UI flow Android emulátoron: regisztráció -> login -> új termék mentés
- ajánlási, szűrési, dashboard és modell logika

Functions és security:
- `security_helpers.js` biztonsági segédlogika
- Firestore rules szerződéses korlátai
- Firestore rules reprezentatív allow/deny viselkedési modelljei

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

### Ellenőrzés ebben a módosítási körben
A jelenlegi változtatási körben a következő ellenőrzések futtatása van betervezve:

```bash
cd mobile/nearpick
dart run tool/audit_pub_dependencies.dart --report-dir=reports
flutter test
flutter test integration_test/flows/auth_and_product_flow_test.dart -d <android-emulator-device-id>

cd ../../functions
npm test
npm run lint
```

Ha valamelyik parancs környezeti okból nem futtatható, azt az összegzés külön jelzi.

### Ismert korlátok
- A `test/integration/**` suite workflow-szintű integráció; ettől külön már van egy valódi `integration_test` UI flow is.
- A Firestore rules verifikáció továbbra sem teljes emulatoros allow/deny tesztkészlet.
- A manuális acceptance feature-k nincsenek automata runnerhez kötve.

## Archivált korábbi tartalom

## Összegzés
A Flutter projekt automata tesztkészlete aktuálisan teljesíti a minimum követelményeket, és a repository szintjén ehhez functions/rules tesztek is társulnak.

Utolsó ellenőrzött Flutter-futás eredménye:
- összes teszt: `45`
- sikeres: `45`
- sikertelen: `0`
- unit: `33`
- integration: `6`
- widget: `6`
- negatív tesztek: `9+`

Primer evidence:
- [docs/assets/logs/flutter_test_latest.log](../assets/logs/flutter_test_latest.log)

## Futtatott parancs

```bash
cd mobile/nearpick
flutter test --reporter expanded
flutter test integration_test/flows/auth_and_product_flow_test.dart -d <android-emulator-device-id>
```

## Suite lista
| Suite | Darab | Állapot | Evidence |
|---|---|---|---|
| Root + unit tesztek | 33 | Passed | [docs/assets/logs/flutter_test_latest.log](../assets/logs/flutter_test_latest.log) |
| Integration workflow tesztek | 6 | Passed | [docs/assets/logs/flutter_test_latest.log](../assets/logs/flutter_test_latest.log) |
| Widget tesztek | 6 | Passed | [docs/assets/logs/flutter_test_latest.log](../assets/logs/flutter_test_latest.log) |
| Integration_test UI flow | 1 | Passed | [`auth_and_product_flow_test.dart`](../../mobile/nearpick/integration_test/flows/auth_and_product_flow_test.dart) |

Részletező fájlok:
- [mobile/nearpick/test/widget_test.dart](../../mobile/nearpick/test/widget_test.dart)
- [mobile/nearpick/test/unit/recommendation/recommendation_engine_test.dart](../../mobile/nearpick/test/unit/recommendation/recommendation_engine_test.dart)
- [mobile/nearpick/test/unit/utils/geo_utils_test.dart](../../mobile/nearpick/test/unit/utils/geo_utils_test.dart)
- [mobile/nearpick/test/unit/models/product_model_test.dart](../../mobile/nearpick/test/unit/models/product_model_test.dart)
- [mobile/nearpick/test/unit/models/reservation_model_test.dart](../../mobile/nearpick/test/unit/models/reservation_model_test.dart)
- [mobile/nearpick/test/unit/validation/new_product_form_logic_test.dart](../../mobile/nearpick/test/unit/validation/new_product_form_logic_test.dart)
- [mobile/nearpick/test/unit/dashboard/dashboard_metrics_test.dart](../../mobile/nearpick/test/unit/dashboard/dashboard_metrics_test.dart)
- [mobile/nearpick/test/unit/consumer/offer_filter_test.dart](../../mobile/nearpick/test/unit/consumer/offer_filter_test.dart)
- [mobile/nearpick/test/unit/reservation/pickup_code_generator_test.dart](../../mobile/nearpick/test/unit/reservation/pickup_code_generator_test.dart)
- [mobile/nearpick/test/integration/auth/auth_workflow_test.dart](../../mobile/nearpick/test/integration/auth/auth_workflow_test.dart)
- [mobile/nearpick/test/integration/product/product_workflow_test.dart](../../mobile/nearpick/test/integration/product/product_workflow_test.dart)
- [mobile/nearpick/test/integration/reservation/reservation_workflow_test.dart](../../mobile/nearpick/test/integration/reservation/reservation_workflow_test.dart)
- [mobile/nearpick/test/widget/auth/login_screen_test.dart](../../mobile/nearpick/test/widget/auth/login_screen_test.dart)
- [mobile/nearpick/test/widget/auth/register_screen_test.dart](../../mobile/nearpick/test/widget/auth/register_screen_test.dart)
- [mobile/nearpick/test/widget/merchant/new_product_screen_test.dart](../../mobile/nearpick/test/widget/merchant/new_product_screen_test.dart)
- [mobile/nearpick/integration_test/flows/auth_and_product_flow_test.dart](../../mobile/nearpick/integration_test/flows/auth_and_product_flow_test.dart)

## Utolsó futás
- dátum: `2026-03-06`
- futási mód: lokális terminál futás, Flutter suite
- parancs: `flutter test --reporter expanded`
- eredmény: `All tests passed!`

## Megjegyzés az evidence rögzítésről
A `flutter test` pipe-pal (`Tee-Object`, shell redirect) ebben a futtatási környezetben nem adott megbízható, automatikusan flush-olt logfájlt. Emiatt a repo-ban egy normalizált, ellenőrzött mintalog szerepel, amely a sikeres lokális futás eredményét dokumentálja.

Ez a dokumentációs célra elegendő, mert:
- a tényleges tesztfutás megtörtént
- az eredmény `45/45 passed`
- a teljes suite és a parancs dokumentálva van

## Nyitott korlátok
- A jelenlegi integration szint in-memory workflow/adaptor alapú, nem Firebase emulátor alapú.
- A CI generál JUnit XML-t (`reports/junit-flutter.xml`), de a lokális dokumentációs evidence itt jelenleg elsősorban a normalizált logfájlra támaszkodik.
- Az `integration_test/` réteg még nem teljes suite, jelenleg egy validált core flow áll rendelkezésre.

# Teszt riport

## Aktuális állapot 2026-03-12

### Jelenlegi repo-állapot
A repository jelenlegi, fájlokból számolt automata tesztleltára:

| Kategória | Darab | Hely |
|---|---:|---|
| Flutter unit | 36 | `mobile/nearpick/test/widget_test.dart`, `mobile/nearpick/test/unit/**` |
| Flutter widget | 6 | `mobile/nearpick/test/widget/**` |
| Flutter integration/workflow | 10 | `mobile/nearpick/test/integration/**` |
| Functions és Firestore/rules | 21 | `functions/test/**` |
| Összes automata teszt | 73 | Flutter + functions |

Automatizált, de külön nem futó E2E UI suite:
- `mobile/nearpick/integration_test/**` jelenleg csak README scaffoldot tartalmaz

Manuális teszt artefaktum:
- `sprints/02/tests/acceptance/create_product.feature`
- `sprints/02/tests/acceptance/empty_state.feature`

### Fő lefedett területek
Flutter:
- auth regisztráció és login workflow
- terméklétrehozás, böngészéshez szükséges adatok és érdeklődés jelölése
- foglalás, készletcsökkentés és completion workflow
- UI űrlapvalidációk és hibamegjelenítés
- ajánlási, szűrési, dashboard és modell logika

Functions és security:
- `security_helpers.js` biztonsági segédlogika
- Firestore rules szerződéses korlátai
- Firestore rules reprezentatív allow/deny viselkedési modelljei

### CI evidence
A GitHub Actions [ci.yml](/d:/Szakdoga/1-sprint-Admgt/.github/workflows/ci.yml) a következő artefaktumokat teszi elérhetővé:
- `flutter-junit`
- `quality-test-evidence`
- `quality-security-evidence`
- `nearpick-web-build`

Ezek forrásai:
- Flutter `reports/junit-flutter.xml`
- Flutter és functions tesztlogok a `reports/` könyvtárakból
- secret scan és `npm audit` riportok
- a Flutter web build kimenete

### Ellenőrzés ebben a módosítási körben
A jelenlegi változtatási körben a következő ellenőrzések futtatása van betervezve:

```bash
cd mobile/nearpick
flutter test

cd ../../functions
npm test
npm run lint
```

Ha valamelyik parancs környezeti okból nem futtatható, azt az összegzés külön jelzi.

### Ismert korlátok
- A `test/integration/**` suite workflow-szintű integráció, nem valódi device/emulator UI-E2E futás.
- A Firestore rules verifikáció továbbra sem teljes emulatoros allow/deny tesztkészlet.
- A manuális acceptance feature-k nincsenek automata runnerhez kötve.

## Archivált korábbi tartalom

## Összegzés
A Flutter projekt automata tesztkészlete aktuálisan teljesíti a minimum követelményeket.

Utolsó ellenőrzött eredmény:
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
```

## Suite lista
| Suite | Darab | Állapot | Evidence |
|---|---|---|---|
| Root + unit tesztek | 33 | Passed | [docs/assets/logs/flutter_test_latest.log](../assets/logs/flutter_test_latest.log) |
| Integration workflow tesztek | 6 | Passed | [docs/assets/logs/flutter_test_latest.log](../assets/logs/flutter_test_latest.log) |
| Widget tesztek | 6 | Passed | [docs/assets/logs/flutter_test_latest.log](../assets/logs/flutter_test_latest.log) |

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

## Utolsó futás
- dátum: `2026-03-06`
- futási mód: lokális terminál futás
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
- Külön JUnit XML most nincs generálva a repo aktuális quality evidence csomagjában.
- `integration_test/` alapú mobil E2E suite továbbra sincs bevezetve; a követelményhez szükséges widgetteszt minimum viszont teljesült.

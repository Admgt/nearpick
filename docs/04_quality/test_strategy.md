# Tesztstratégia

## Aktuális állapot 2026-03-12

### Cél és scope
A NearPick tesztstratégiájának célja, hogy a kritikus üzleti logikát, a fő felhasználói workflow-kat, a Firestore hozzáférési szabályok legfontosabb engedélyezési tiltásait, valamint a Cloud Functions biztonsági segédlogikáját automatizált kapukkal védje.

Az aktuális stratégia a meglévő repo-struktúrára épít:
- a Flutter tesztek továbbra is a `mobile/nearpick/test/**` alatt futnak
- a GitHub Actions a meglévő [ci.yml](/d:/Szakdoga/1-sprint-Admgt/.github/workflows/ci.yml) workflow-ban maradt
- a Firestore rules ellenőrzése jelenleg szerződés- és viselkedésmodell-szintű, nem teljes emulatoros allow/deny suite

### Aktuális tesztkategóriák
| Kategória | Darab | Hely | Automatizálás |
|---|---:|---|---|
| Flutter unit | 36 | `mobile/nearpick/test/widget_test.dart`, `mobile/nearpick/test/unit/**` | igen |
| Flutter widget | 6 | `mobile/nearpick/test/widget/**` | igen |
| Flutter integration/workflow | 10 | `mobile/nearpick/test/integration/**` | igen |
| Flutter integration_test UI/E2E | 1 | `mobile/nearpick/integration_test/**` | igen |
| Functions és rules | 21 | `functions/test/**` | igen |
| Manuális acceptance leírás | 2 feature | `sprints/02/tests/acceptance/**` | nem |

Összes automata teszt jelenleg: `74+`.

### Flutter stratégia
- Unit: ajánlási logika, geó számítás, modellek, validáció, dashboard, szűrés, pickup kód, auth hibaüzenet-mapping.
- Widget: login, register és új termék képernyő validációs viselkedés.
- Integration/workflow: regisztráció, login, terméklétrehozás, browse/detail adatok, érdeklődés, foglalás és completion flow.
- Integration_test UI/E2E: regisztráció -> login -> új termék mentés valódi Flutter képernyőkön, Android emulátoron futtatva.

Az integration szint ebben a repo-ban két részre vált:
- `test/integration/**`: workflow/adaptor szintű automatizálás, gyors és determinisztikus, in-memory fake gateway-ekkel
- `integration_test/**`: valódi UI/E2E jellegű Flutter futás, jelenleg egy stabil core flow-val

### Firestore és Functions stratégia
- Firestore rules szerződésvizsgálat: [firestore.rules](/d:/Szakdoga/1-sprint-Admgt/firestore.rules) kulcskorlátainak ellenőrzése.
- Firestore rules viselkedésmodell: reprezentatív allow/deny esetek a [functions/test/firestore_rules_policy.test.js](/d:/Szakdoga/1-sprint-Admgt/functions/test/firestore_rules_policy.test.js) alatt.
- Functions quality gate: `npm run lint`, `npm test`, `npm run scan:deps`.

Lefedett rules esetek:
- csak saját `ownerId`-val hozható létre termék
- a képes termék `imagePath` mezője csak saját storage útvonalra mutathat
- anonim terméklétrehozás tiltott
- `interestCount` csak izolált, engedélyezett módosítással változhat
- reservation olvasás csak buyer vagy merchant számára engedett
- merchant statisztika, user dokumentum és interest csak megfelelő saját azonosítóval érhető el

### Automatizált és manuális scope
Automatizált:
- Flutter unit, widget és workflow integration tesztek
- legalább egy valódi `integration_test` alapú mobil UI flow
- Functions és rules tesztek
- külön performance smoke benchmark a recommendation distance helperre
- Flutter format és analyze
- functions lint
- secret scan
- functions dependency audit
- web build és artifact publikálás

Manuális vagy részben manuális:
- acceptance feature-k automata futtatása
- teljes Firebase Emulator alapú rules allow/deny végponti ellenőrzés
- a performance benchmark optimalizálás utáni, gépazonos újramérése

### Lokális futtatás

```bash
cd mobile/nearpick
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter test test/integration
flutter test integration_test

cd ../../functions
npm ci
npm run lint
npm test
npm run scan:deps
```

### Ismert rések
- A `mobile/nearpick/integration_test/**/*_test.dart` réteg még csak egy core flow-t fed le, nem teljes E2E suite.
- A Firestore rules ellenőrzése még nem emulatoros allow/deny futás, hanem szerződés + viselkedésmodell.
- A manuális acceptance feature-k még nem kapcsolódnak automata runnerhez.

## Archivált korábbi tartalom

## Cél és scope
A NearPick tesztstratégiájának célja, hogy a kritikus üzleti logikát, a fő felhasználói flow-kat és a korábban nehezen tesztelhető UI-validációs részeket determinisztikus automata tesztekkel védje.

Védett területek:
- Auth flow és szerepkör-alapú regisztráció/bejelentkezés.
- Termék létrehozás validációval és opcionális koordinátákkal.
- Foglalási workflow és pickup kód logika.
- Ajánlási pontszámítás, indokok, geotávolság.
- Model mapping fallbackok.
- Consumer offer-szűrés és dashboard aggregáció.

## Aktuális tesztmix
A projekt jelenlegi automata tesztállománya:

| Szint | Darab | Hely |
|---|---|---|
| Unit | 33 | `mobile/nearpick/test/widget_test.dart`, `mobile/nearpick/test/unit/**` |
| Integration | 6 | `mobile/nearpick/test/integration/**` |
| Widget | 6 | `mobile/nearpick/test/widget/**` |
| Összesen | 45 | `mobile/nearpick/test/**` |

Követelmény teljesül:
- minimum `30` automata teszt: teljesült
- minimum `18` unit teszt: teljesült
- minimum `6` integration teszt: teljesült
- minimum `6` widget teszt: teljesült
- minimum `5` negatív teszt: teljesült

## Suite szerkezet
### Unit
Fókusz:
- recommendation score komponensek és reason rendezése
- `GeoUtils` távolságszámítás
- `Product` és `Reservation` mapping fallbackok
- új termék validációs helper logika
- merchant dashboard KPI aggregáció
- consumer offer filter predicate
- pickup kód generátor formátuma

Fájlok:
- [mobile/nearpick/test/unit/recommendation/recommendation_engine_test.dart](../../mobile/nearpick/test/unit/recommendation/recommendation_engine_test.dart)
- [mobile/nearpick/test/unit/utils/geo_utils_test.dart](../../mobile/nearpick/test/unit/utils/geo_utils_test.dart)
- [mobile/nearpick/test/unit/models/product_model_test.dart](../../mobile/nearpick/test/unit/models/product_model_test.dart)
- [mobile/nearpick/test/unit/models/reservation_model_test.dart](../../mobile/nearpick/test/unit/models/reservation_model_test.dart)
- [mobile/nearpick/test/unit/validation/new_product_form_logic_test.dart](../../mobile/nearpick/test/unit/validation/new_product_form_logic_test.dart)
- [mobile/nearpick/test/unit/dashboard/dashboard_metrics_test.dart](../../mobile/nearpick/test/unit/dashboard/dashboard_metrics_test.dart)
- [mobile/nearpick/test/unit/consumer/offer_filter_test.dart](../../mobile/nearpick/test/unit/consumer/offer_filter_test.dart)
- [mobile/nearpick/test/unit/reservation/pickup_code_generator_test.dart](../../mobile/nearpick/test/unit/reservation/pickup_code_generator_test.dart)

### Integration
Ebben a repo-ban az integration szint repository-adapter/workflow szintű, in-memory fake implementációkkal.
Ez tudatos döntés: a követelmény szerint emulator vagy repository adapter szint is elfogadható, és ez a megközelítés determinisztikus, gyors és külső szolgáltatás független.

Fájlok:
- [mobile/nearpick/test/integration/auth/auth_workflow_test.dart](../../mobile/nearpick/test/integration/auth/auth_workflow_test.dart)
- [mobile/nearpick/test/integration/product/product_workflow_test.dart](../../mobile/nearpick/test/integration/product/product_workflow_test.dart)
- [mobile/nearpick/test/integration/reservation/reservation_workflow_test.dart](../../mobile/nearpick/test/integration/reservation/reservation_workflow_test.dart)

Támogató fake/helper réteg:
- [mobile/nearpick/test/test_helpers/in_memory_workflow_fakes.dart](../../mobile/nearpick/test/test_helpers/in_memory_workflow_fakes.dart)

### Widget
Fókusz:
- login submit + error render
- register role választás + error render
- new product screen validáció + sikeres callback trigger

Fájlok:
- [mobile/nearpick/test/widget/auth/login_screen_test.dart](../../mobile/nearpick/test/widget/auth/login_screen_test.dart)
- [mobile/nearpick/test/widget/auth/register_screen_test.dart](../../mobile/nearpick/test/widget/auth/register_screen_test.dart)
- [mobile/nearpick/test/widget/merchant/new_product_screen_test.dart](../../mobile/nearpick/test/widget/merchant/new_product_screen_test.dart)

## Negatív tesztek
Kifejezetten negatív esetet ellenőriz:
- hibás login credential
- auth nélküli terméklétrehozás
- idegen merchant általi reservation complete
- hiányos koordináta
- nem numerikus koordináta
- nulla vagy negatív mennyiség/ár parser
- login error render
- register error render
- hiányzó lejárati dátum UI hiba

## Determinizmus
A tesztek nem függnek elő külső szolgáltatástól.

Determinista megoldások:
- fix dátumok a recommendation és workflow tesztekben
- fix fake UID-k
- in-memory fake repositoryk és gateway-ek
- injektálható pickup code generator
- injektálható UI callbackok a widget tesztekhez

Refaktorok a tesztelhetőséghez:
- [mobile/nearpick/lib/features/merchant/new_product_form_logic.dart](../../mobile/nearpick/lib/features/merchant/new_product_form_logic.dart)
- [mobile/nearpick/lib/features/merchant/dashboard_metrics.dart](../../mobile/nearpick/lib/features/merchant/dashboard_metrics.dart)
- [mobile/nearpick/lib/features/consumer/offer_filter.dart](../../mobile/nearpick/lib/features/consumer/offer_filter.dart)
- [mobile/nearpick/lib/services/pickup_code_generator.dart](../../mobile/nearpick/lib/services/pickup_code_generator.dart)
- [mobile/nearpick/lib/core/auth/auth_workflow.dart](../../mobile/nearpick/lib/core/auth/auth_workflow.dart)
- [mobile/nearpick/lib/core/product/product_workflow.dart](../../mobile/nearpick/lib/core/product/product_workflow.dart)
- [mobile/nearpick/lib/core/reservation/reservation_workflow.dart](../../mobile/nearpick/lib/core/reservation/reservation_workflow.dart)

## Lokális futtatási parancsok
Repo gyökérből:

```bash
cd mobile/nearpick
flutter test --reporter expanded
```

Célzott futtatás:

```bash
cd mobile/nearpick
flutter test test/unit
flutter test test/integration
flutter test test/widget
```

Quality gate futtatás:

```bash
cd mobile/nearpick
dart format --set-exit-if-changed .
flutter analyze
flutter test --reporter expanded
```

## Evidence
Az utolsó sikeres lokális tesztfutás mintalogja:
- [docs/assets/logs/flutter_test_latest.log](../assets/logs/flutter_test_latest.log)

Megjegyzés:
- A korábbi, nem létező vagy elavult JUnit evidence hivatkozásokat ez a dokumentum már nem használja.
- A jelenlegi primer bizonyíték a repo-ba mentett expanded test log.

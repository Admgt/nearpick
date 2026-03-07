# Tesztstratégia

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

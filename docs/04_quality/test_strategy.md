# Test Strategy

## Goals and scope
A tesztelés célja, hogy a NearPick regresszióit korán fogjuk, csökkentsük az AI-támogatott fejlesztésből jövő hallucinációs/regressziós kockázatot, és stabil release-t adjunk ki a kritikus user flow-kra.

Védett területek:
- Auth + role routing (`consumer` vs `merchant`) és belépési állapot ([mobile/nearpick/lib/main.dart](../../mobile/nearpick/lib/main.dart), [mobile/nearpick/lib/services/auth_service.dart](../../mobile/nearpick/lib/services/auth_service.dart)).
- Termék életút (létrehozás, archiválás, feed megjelenés) ([mobile/nearpick/lib/services/product_service.dart](../../mobile/nearpick/lib/services/product_service.dart), [mobile/nearpick/lib/features/merchant/new_product_screen.dart](../../mobile/nearpick/lib/features/merchant/new_product_screen.dart)).
- Foglalási tranzakció + státuszfrissítés ([mobile/nearpick/lib/services/reservation_service.dart](../../mobile/nearpick/lib/services/reservation_service.dart)).
- Ajánlási pontszámítás és indokok ([mobile/nearpick/lib/recommendation/recommendation_engine.dart](../../mobile/nearpick/lib/recommendation/recommendation_engine.dart)).
- Firebase security contract ([firestore.rules](../../firestore.rules), [storage.rules](../../storage.rules)).

Mi nem cél:
- 100% code coverage.
- Összes platform-specifikus (desktop runner) viselkedés teljes E2E automatizálása az első körben.

Evidence baseline (aktuális állapot):
- Monorepo: Flutter app + Firebase Functions + infra/sprint anyagok ([README.md](../../README.md)).
- Flutter tesztfájl jelenleg 1 db, benne 5 unit jellegű teszt ([mobile/nearpick/test/widget_test.dart](../../mobile/nearpick/test/widget_test.dart)).
- `integration_test/` es `e2e/` mappa nincs a Flutter projektben.
- CI gatek: format/analyze/build/test, JUnit artifact feltöltéssel ([.github/workflows/ci.yml](../../.github/workflows/ci.yml)).
- CI-ben coverage gate nincs; `lcov.info` nincs pipeline-ban.
- Sprint 2-ben vannak acceptance feature fájlok, de jelenleg nem futnak CI-ben ([sprints/02/tests/acceptance/create_product.feature](../../sprints/02/tests/acceptance/create_product.feature), [sprints/02/tests/acceptance/empty_state.feature](../../sprints/02/tests/acceptance/empty_state.feature)).

## Test pyramid and target mix
Célmix (v1.2 követelmény): minimum 30 automata teszt.
- Unit: 18 db (cél).
- Integration: 6 db (cél).
- E2E/Contract: 6 db (cél).
- Negatív tesztek: minimum 5 db.

Jelenlegi állapot: 5 / 0 / 0, ezért a mix teljesítése `Planned`.

Mi ez a mix ehhez a projekthez:
- A domain logika és rangsoroló algoritmus erős unit tesztelést igényel.
- A valódi kockázat Firebase integrációban van (Auth/Firestore/Storage/rules), ezért dedikált integration szint kell.
- A két legkritikusabb végfelhasználói folyamat (feltöltés->feed->foglalás, illetve hibaág) E2E védelmet igényel release előtt.

Negatív teszt minimum (konkrét kategóriák):
- Invalid input (pl. hibás ár/koordináta) - [new_product_screen.dart](../../mobile/nearpick/lib/features/merchant/new_product_screen.dart).
- Auth fail / nincs user - [auth_service.dart](../../mobile/nearpick/lib/services/auth_service.dart), [reservation_service.dart](../../mobile/nearpick/lib/services/reservation_service.dart).
- Network/Firestore hiba - több StreamBuilder hibaág a consumer/merchant képernyőkön.
- Empty state - [merchant_home_screen.dart](../../mobile/nearpick/lib/features/merchant/merchant_home_screen.dart), [my_reservations_screen.dart](../../mobile/nearpick/lib/features/consumer/my_reservations_screen.dart).
- Permission denied (location + rules) - [location_service.dart](../../mobile/nearpick/lib/services/location_service.dart), [firestore.rules](../../firestore.rules).

## What we test at each level
### Unit tests
Fókusz: tiszta vagy közel-tiszta logika.
- Recommendation score komponensek és indokok (`favoriteScore`, `recencyScore`, `expiryScore`, penalty-k, reason rendezés) ([recommendation_engine.dart](../../mobile/nearpick/lib/recommendation/recommendation_engine.dart)).
- Geo távolságszámítás ([geo_utils.dart](../../mobile/nearpick/lib/utils/geo_utils.dart)).
- Modell mapping és fallbackok ([models/product.dart](../../mobile/nearpick/lib/models/product.dart), [models/reservation.dart](../../mobile/nearpick/lib/models/reservation.dart)).
- Validációs szabályok (Planned: UI-ból kiemelt pure validátorok újrafelhasználható helperbe).
- Hibakód/hiba-üzenet mapping (Planned, különösen location/reservation hibákra).

Eszközök:
- Meglévő: `flutter_test`.
- Planned: `mocktail`/`mockito` csak ott, ahol külső függőség absztrakciója már adott.

### Integration tests
Ebben a projektben integrationnek számít:
- Service réteg + valódi Firestore/Auth/Storage viselkedés emulátorban (nem pure mock).
- Firestore rules enforce teszt (allowed/denied írás-olvasás).
- Reservation tranzakció következményeinek ellenőrzése (products/reservations/merchantStats állapot együtt).

Fókuszmodulok:
- [product_service.dart](../../mobile/nearpick/lib/services/product_service.dart)
- [reservation_service.dart](../../mobile/nearpick/lib/services/reservation_service.dart)
- [notification_service.dart](../../mobile/nearpick/lib/services/notification_service.dart)
- [functions/index.js](../../functions/index.js) trigger contract (Planned)

Flaky kockázat csökkentése:
- Determinisztikus fixture adatok es fix teszt UID-k.
- `await`-olt stream settle pontok, explicit timeoutok.
- Izolált test-runner projekt (emulátor namespace), minden futás utan cleanup.

### E2E / UI / Contract tests
Kritikus user flow-k (védelmi minimum):
- Flow A: `merchant login -> új termék mentése -> termék megjelenik merchant listában -> consumer feedben megjelenik -> consumer lefoglalja -> merchant átadja`.
- Flow B (error flow): `consumer lefoglalás sold_out vagy jogosultsági hiba esetben -> megfelelő hiba-üzenet + adatkonzisztencia marad`.

Hol futnak:
- Planned: Flutter `integration_test` alapon.
- Planned opcion: Patrol, ha natív permission (helyhozzáférés) megbízhatóbb kezelése kell.

Contract jelentése ebben a repo-ban:
- Firestore dokumentum schema + jogosultság szabályok ([firestore.rules](../../firestore.rules)).
- Storage elérési szabályok ([storage.rules](../../storage.rules)).
- Product/Reservation adatmapping szerződés ([models/product.dart](../../mobile/nearpick/lib/models/product.dart), [models/reservation.dart](../../mobile/nearpick/lib/models/reservation.dart)).
- Cloud Function trigger elvárt input mezői (`products/{productId}`) ([functions/index.js](../../functions/index.js)).

Adoption plan (mert nincs aktív E2E keret):
- `integration_test/` tesztcsomag létrehozása a Flutter appban.
- Firebase Emulator Suite konfiguráció kiegészítése (`auth`, `firestore`, `storage`, `functions`) root [firebase.json](../../firebase.json)-ban.
- CI `test` job bővítése emulatorral futtatható integration/e2e targettel ([.github/workflows/ci.yml](../../.github/workflows/ci.yml)).

## Test data & determinism
- Tesztadatok: Planned `test/fixtures/` + factory helper réteg (termék, user, reservation minták).
- Idődetermináció: Planned clock-absztrakció bevezetése a `DateTime.now()` erősen használt kódban ([recommendation_engine.dart](../../mobile/nearpick/lib/recommendation/recommendation_engine.dart), [reservation_service.dart](../../mobile/nearpick/lib/services/reservation_service.dart)).
- Random determináció: Planned pickup code generátor injektálható stratégia (`Random.secure` helyett tesztben fix provider).
- Környezetvédelem: integration/e2e csak emulátor ellen futhat; production Firebase project (`nearpick-c0fea`) tesztfutásban tiltott.

## Mock / stub strategy
Preferált irány:
- Unit: mock/stub a külső rendszerekhez (Firebase Auth/Firestore/Storage/Messaging), a domain logikát valósan futtatjuk.
- Integration: emulator/fake backend, itt minimális mock.
- E2E: minél valósabb stack, csak külső nem-determinisztikus részek (pl. push delivery) kontrollált stubbal.

Mit nem mockolunk:
- Recommendation score algoritmus.
- Model mapperek.
- Firestore/Storage rules contract.

## CI quality gates
Aktuális gate-ek ([.github/workflows/ci.yml](../../.github/workflows/ci.yml)):
- `lint` job: `dart format --set-exit-if-changed .`, `flutter analyze`, functions lint ha van.
- `build` job: `flutter build web --release` (lint utan).
- `test` job: `flutter test --machine | tojunit`, optional `flutter test integration_test`, functions test ha van script.

Gate viselkedés:
- Bármelyik job hiba blokkolja a pipeline-t (`needs` lanc: lint -> build -> test).
- Flutter JUnit artifact feltöltés megtörténik, ha file létezik: `mobile/nearpick/reports/junit-flutter.xml`.

Coverage gate:
- Jelenleg nincs CI coverage threshold.
- Planned: `flutter test --coverage` + `lcov` alap coverage gate (kezdő cél: 60%, majd sprintenként emelhető).

## How to run locally
Repo rootbol:

```bash
cd mobile/nearpick
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
dart pub global activate junitreport
flutter test --machine | tojunit > reports/junit-flutter.xml
```

Integration/E2E (Planned, ha `integration_test/` már létezik):

```bash
cd mobile/nearpick
flutter test integration_test
```

Functions (ha van lint/test script):

```bash
cd functions
npm ci
npm run lint --if-present
npm run test --if-present
```

Elvárt eredmény röviden:
- Minden parancs 0 exit code.
- JUnit kimenet generálódik a `mobile/nearpick/reports/junit-flutter.xml` fájlba.

## Risks and known gaps
- Jelenleg nincs integration/e2e automata teszt a Flutter appban.
- Functions csomagban nincs aktív lint/test script definiálva ([functions/package.json](../../functions/package.json)).
- A validáció egy része UI widgetekbe van ágyazva, ami nehezíti a gyors unit tesztelést.
- `DateTime.now()` és `Random.secure()` miatt több helyen nem determinisztikus a viselkedés.
- CI-ben nincs coverage gate.
- Sprint dokumentációs teszt artifactok és traceability fájlok részben nem a jelenlegi kódstruktúrát tükrözik ([sprints/02/docs/traceability.md](../../sprints/02/docs/traceability.md), [sprints/02/reports/coverage.xml](../../sprints/02/reports/coverage.xml)).

Flaky policy (Planned):
- Flaky teszt merge-gate-ben nem maradhat aktívan.
- Legfeljebb 1 ideiglenes quarantine cimke (max 7 nap), kötelező javítási issue-val.
- Re-run csak egyszer engedett CI-ben; tartós flaky tesztet javítani vagy kivenni kell a gate-ből.

## Next actions
1. Unit csomag: `recommendation_engine` score + reason determinisztikus tesztek (cél: 8 unit).
2. Unit csomag: model mapper + geo helper + validator helper tesztek (cél: 10 unit, benne negatív esetek).
3. Integration csomag: `AuthService` + `users` profil mentés emulátorral (cél: 2 integration).
4. Integration csomag: `ProductService` es `ReservationService` tranzakciós konzisztencia tesztek emulátorral (cél: 4 integration).
5. E2E csomag: kritikus Flow A végponttól végpontig (`merchant->upload->consumer->reserve->merchant complete`) (cél: 4 e2e).
6. E2E/Contract csomag: Flow B error + Firestore/Storage rules denied/allowed contract tesztek (cél: 2 e2e + legalább 5 negatív teszt összesen).

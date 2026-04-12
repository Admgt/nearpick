# Tesztstratégia

## Aktuális állapot 2026-04-11

### Cél és scope

A NearPick tesztstratégiájának célja, hogy a kritikus üzleti logikát, a fő felhasználói workflow-kat, a Firestore hozzáférési szabályok legfontosabb engedélyezési tiltásait, valamint a Cloud Functions reservation / refund / review segédlogikáját automatizált kapukkal védje.

Az aktuális stratégia a meglévő repo-struktúrára épít:
- a Flutter tesztek a `mobile/nearpick/test/**` alatt futnak
- a valódi UI / E2E jellegű Flutter tesztek a `mobile/nearpick/integration_test/**` alatt vannak
- a GitHub Actions a meglévő [ci.yml](../../.github/workflows/ci.yml) workflow-ban maradt
- a Firestore rules ellenőrzése jelenleg szerződés- és viselkedésmodell-szintű, nem teljes emulatoros allow/deny suite

### Jelenlegi tesztmix

A 2026-04-11-es statikus repo-audit alapján:

| Kategória | Darab | Megjegyzés |
|---|---:|---|
| Flutter test definíció | 93 | `test/**` és `integration_test/**` |
| Functions / rules JS teszt | 69 | `functions/test/**` |
| Összes automata tesztdefiníció | 162 | statikus inventory, nem egyetlen futás eredménye |

A mix továbbra is megfelel a minimum `30+` automata tesztelvárásnak, de a minőségi fókusz most már nem a darabszám, hanem az új mobilflow-k következetes védelme.

### Flutter stratégia

- Unit: ajánlási logika, geó számítás, modellek, pricing, dashboard aggregáció, location preference, pickup token és error mapping.
- Widget: login, register, root routing és új termék képernyő validáció / pricing javaslat.
- Integration/workflow: regisztráció, login, terméklétrehozás, browse/detail adatok, érdeklődés, többdarabos foglalás, refund állapotok.
- Integration_test UI/E2E: jelenleg három validált flow létezik: `auth_and_product_flow_test.dart`, `reservation_refund_review_flow_test.dart` és `admin_product_moderation_flow_test.dart`.

Az integration szint ebben a repo-ban két részre vált:
- `test/integration/**`: workflow / adaptor szintű automatizálás, gyors és determinisztikus, in-memory fake gateway-ekkel
- `integration_test/**`: valódi UI / E2E jellegű Flutter futás Android emulatoron, jelenleg három stabil flow-val

### Frissített lefedési fókusz

Már van explicit teszt- vagy kódszintű védelem az alábbi újabb területekre:
- password reset flow
- merchant company name regisztrációkor
- location preference parsing és city mode
- dynamic pricing recommendation és dashboard metrics
- quantity-aware reservation workflow
- pickup token parsing
- refund adatok modellezése
- review modellezés
- reservation detail QR token, refund kérés és completed reservation review UI/E2E flow Android emulatoron
- merchant CSV export
- product edit constraint az első foglalás előtt / után
- admin role routing
- egységes error mapper, `AppException` és callable `contextId` korreláció
- adminMessages Firestore read/read receipt rule modell
- admin callable permission-deny, validációs és happy path esetek a fiókstátusz, termékmoderáció és admin üzenetküldés útvonalakra
- admin product detail moderációs UI/E2E flow Android emulatoron: elrejtés, archivált törlés és visszaállítás

### Firestore és Functions stratégia

- Firestore rules szerződésvizsgálat: [firestore.rules](../../firestore.rules) kulcskorlátainak ellenőrzése.
- Firestore rules viselkedésmodell: reprezentatív allow/deny esetek a [functions/test/firestore_rules_policy.test.js](../../functions/test/firestore_rules_policy.test.js) alatt.
- Functions quality gate: `npm run lint`, `npm test`, `npm run scan:deps`.

Lefedett rules / helper esetek:
- csak saját `ownerId`-val hozható létre vagy módosítható termék
- a képes termék `imagePath` mezője csak saját storage útvonalra mutathat
- anonim terméklétrehozás tiltott
- reservation olvasás csak buyer vagy merchant számára engedett
- review, refund és archíválási helper döntések külön security helper tesztekkel támogatottak
- admin helper jelenléte és `adminMessages` olvasási / olvasottra jelölési szabályai
- admin callable contract tesztek: nem admin hívó tiltása, saját admin fiók tiltásának blokkolása, fiókstátusz-frissítés, admin üzenetküldés push ággal, termék elrejtés/visszaállítás és admin archiválás

Admin területen még célzottan bővítendő:
- admin dashboard stat aggregáció és admin message modell unit tesztek
- admin dashboard, fiókstátusz-kezelés és admin üzenetküldés UI smoke / integration_test flow

### Automatizált és manuális scope

Automatizált:
- Flutter unit, widget és workflow integration tesztek
- három valódi `integration_test` alapú mobil UI flow Android emulatoron
- Functions és rules tesztek
- külön performance smoke benchmark a recommendation distance helperre
- Flutter format és analyze
- Flutter dependency audit
- functions lint
- secret scan
- functions dependency audit
- web build és artifact publikálás

Manuális vagy részben manuális:
- acceptance feature-k automata futtatása
- teljes Firebase Emulator alapú rules allow/deny végponti ellenőrzés
- QR scanner valós kamerás ellenőrzése minden platformon
- a performance benchmark optimalizálás utáni, gépazonos újramérése

### Lokális futtatás

```bash
cd mobile/nearpick
dart run tool/audit_pub_dependencies.dart --report-dir=reports
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

- A `mobile/nearpick/integration_test/**/*_test.dart` réteg már három core flow-t fed le, de még nem teljes E2E suite.
- Az account/profile/location flow-khoz még nincs teljes UI/E2E fedés.
- A QR scanner valós kamerás és merchant pickup-completion útja még nem teljes UI/E2E fedésű; a consumer reservation detail QR token megjelenítés már külön emulatoros flow-ban fedett.
- Az admin felület UI/E2E fedése részleges: product moderation detail flow már van, de a dashboard, fiókstátusz-kezelés és admin üzenetküldés még nem teljes UI/E2E suite.
- A Firestore rules ellenőrzése még nem emulatoros allow/deny futás, hanem szerződés + viselkedésmodell.
- A manuális acceptance feature-k még nem kapcsolódnak automata runnerhez.
- A Flutter dependency audit advisory feed-alapú, ezért hálózati elérhetőséget igényel.

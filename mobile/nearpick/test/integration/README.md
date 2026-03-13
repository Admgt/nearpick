# Integration tesztek

Ez a mappa a NearPick workflow-szintű, determinisztikus Flutter integrációs tesztjeit tartalmazza. A tesztek nem eszköz- vagy emulátoralapú UI/E2E futások, hanem a fő üzleti folyamatokat ellenőrzik in-memory fake gateway-ekkel.

Jelenleg automatizált flow-k:
- regisztráció és bejelentkezés (`auth/auth_workflow_test.dart`)
- termék létrehozása képpel és kép nélkül (`product/product_workflow_test.dart`)
- piactéri főfolyamat: létrehozás, böngészéshez szükséges adatok, érdeklődés jelölése és foglalás (`marketplace/marketplace_workflow_test.dart`)
- foglalás, készletcsökkentés, merchant statisztika és foglalás lezárása (`reservation/reservation_workflow_test.dart`)

Környezeti függés:
- a `test/integration/**` suite nem igényel Firebase Emulatort vagy demo backendet
- a `mobile/nearpick/integration_test/**` mappa külön van fenntartva a későbbi, valódi UI/E2E tesztekhez; ott jelenleg csak README scaffold található

CI viselkedés:
- ez a suite a normál `flutter test` futás része, ezért a GitHub Actions `Flutter unit/widget tests + JUnit` lépésében fut
- a külön `Flutter integration tests (if present)` lépés csak akkor indul el, ha a `integration_test/**` alatt tényleges `*_test.dart` fájl jelenik meg

## Archivált korábbi leírás

Ez a mappa a Flutter `test/**` alatt futó integration jellegű tesztek helye.

Fókusz:
- service réteg + adatbázis viselkedés
- tranzakciós konzisztencia
- auth/jogosultsági ágak

Megjegyzés:
- Ezek a tesztek a CI-ben a `Flutter unit/widget tests + JUnit` lépéssel futnak, mert a `test/**` alatt vannak.
- Ha emulátoros setup kell, azt a teszt helperben vagy CI előkészítésben kell kezelni.

Futtatás:

```bash
cd mobile/nearpick
flutter test test/integration
```

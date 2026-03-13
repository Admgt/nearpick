# `integration_test` állapot

Ez a mappa a Flutter `integration_test` csomaggal futó, valódi UI/E2E tesztek helye. A repository jelenlegi állapotában itt még nincs futtatható `*_test.dart` fájl, csak ez a dokumentációs scaffold.

Miért maradt scaffold:
- a jelenlegi thesis-scope quality gate a `test/integration/**` alatti workflow-szintű lefedettségre épül
- a repo-ban nincs olyan stabil emulator/device bootstrap, amely mellett a teljes mobil UI-E2E futás most megbízhatóan hozzáadható lenne mellékhatás nélkül

CI viselkedés:
- a GitHub Actions csak akkor futtatja ezt a szintet, ha tényleges `mobile/nearpick/integration_test/**/*_test.dart` fájl létezik
- egy önmagában jelen lévő README vagy helper fájl nem aktiválja ezt a lépést

Ha később valódi E2E teszt kerül ide, a futtatás:

```bash
cd mobile/nearpick
flutter test integration_test
```

## Archivált korábbi leírás

Ez a mappa a Flutter `integration_test` csomaggal futó UI/E2E/contract tesztek helye.

CI viselkedés:
- A workflow csak akkor futtatja ezt a szintet, ha van fájl a `mobile/nearpick/integration_test/**` alatt.
- CI lépés: `Flutter integration tests (if present)`.

Futtatás:

```bash
cd mobile/nearpick
flutter test integration_test
```

Javasolt szerkezet:
- `integration_test/flows/**` - user flow tesztek
- `integration_test/contracts/**` - firestore/storage contract tesztek

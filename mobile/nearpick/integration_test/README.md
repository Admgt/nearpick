# `integration_test` állapot

Ez a mappa a Flutter `integration_test` csomaggal futó, valódi UI/E2E tesztek helye.

Jelenlegi állapot:
- már van futtatható `integration_test` suite
- az első validált flow: `flows/auth_and_product_flow_test.dart`
- a réteg még nem teljes; jelenleg egy core user flow van lefedve

CI viselkedés:
- a GitHub Actions csak akkor futtatja ezt a szintet, ha tényleges `mobile/nearpick/integration_test/**/*_test.dart` fájl létezik
- a workflow lépés neve: `Flutter integration tests (if present)`
- a jelenlegi CI runneren a lépés Android eszköz hiányában átugorható, ezért ez még nem kemény quality gate

Futtatás:

```bash
cd mobile/nearpick
flutter test integration_test
```

Jelenleg validált, célzott futtatás:

```bash
cd mobile/nearpick
flutter test integration_test/flows/auth_and_product_flow_test.dart -d <android-emulator-device-id>
```

Javasolt szerkezet:
- `integration_test/flows/**` - user flow tesztek
- `integration_test/contracts/**` - firestore/storage contract tesztek

## Megjegyzés

- A `test/integration/**` továbbra is külön, workflow-szintű, fake gateway-es integrációs réteg.
- Az `integration_test/**` ehhez képest valódi UI/E2E réteg, de még nem teljes suite.

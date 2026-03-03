# integration_test scaffold

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

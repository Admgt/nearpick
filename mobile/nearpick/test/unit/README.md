# Unit tesztek

Ez a mappa a tiszta logikára és kis komponensekre írt unit tesztek helye.

Ide valók például:
- recommendation score függvények
- model mapper fallbackok
- utility függvenyek
- refaktor után kinyert validációs helper-ek

Futtatás:

```bash
cd mobile/nearpick
flutter test test/unit
```

CI kapcsolat:
- A CI `Flutter unit/widget tests + JUnit` lépése automatikusan futtatja a `test/**` alatti teszteket.
- Eredmény JUnit fájlban: `mobile/nearpick/reports/junit-flutter.xml`.

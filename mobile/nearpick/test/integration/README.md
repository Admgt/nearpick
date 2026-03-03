# Integration tesztek (service szint)

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

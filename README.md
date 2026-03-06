# NearPick

[![CI](https://github.com/SZTE-SZF/1-sprint-Admgt/actions/workflows/ci.yml/badge.svg)](https://github.com/SZTE-SZF/1-sprint-Admgt/actions/workflows/ci.yml)

NearPick egy Flutter + Firebase alapú alkalmazás, amely a közeli, kedvezményes termékek gyors megtalálását és lefoglalását támogatja.

## Gyors hivatkozások

- Dokumentációs index: [`docs/00_index.md`](docs/00_index.md)
- Flutter app leírás: [`mobile/nearpick/README.md`](mobile/nearpick/README.md)
- Tesztstratégia: [`docs/04_quality/test_strategy.md`](docs/04_quality/test_strategy.md)

## Gyors indítás (lokál)

Projekt gyökérből:

```bash
cd mobile/nearpick
flutter pub get
flutter run -d edge --web-port 49904
```

Megjegyzés:
- A fix web port (`49904`) a jelenlegi CORS/Firebase lokális beállítások miatt van használatban.

## Minőségkapuk futtatása

Ha a teljes lokális quality gate-et szeretnéd futtatni:

```bash
bash scripts/test_all.sh
```

Ez a script formázás + elemzés + teszt lépéseket futtat, és JUnit kimenetet készít.

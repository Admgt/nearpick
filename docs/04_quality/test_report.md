# Teszt riport - product-quality előkészítés

## Evidence baseline (CI-hez kötve)
- CI workflow referencia: [.github/workflows/ci.yml](../../.github/workflows/ci.yml)
- Flutter JUnit artifact fájl: [mobile/nearpick/reports/junit-flutter.xml](../../mobile/nearpick/reports/junit-flutter.xml)
- Flutter projekt gyökér: [mobile/nearpick](../../mobile/nearpick)
- Lokális futtató script (opcionális): [scripts/test_all.sh](../../scripts/test_all.sh)

Ez a riport direkt a jelenlegi CI lépéseire épít:
- `Flutter unit/widget tests + JUnit`: `flutter test --machine | tojunit > reports/junit-flutter.xml`
- `Flutter integration tests (if present)`: csak akkor fut, ha van `mobile/nearpick/integration_test/**`

## Suite-ek es futtatási parancsok
| Suite | Lefedett terület | CI lépés | Parancs | Evidence |
|---|---|---|---|---|
| Format gate | Formázási szabályszerűség | `lint` job | `dart format --set-exit-if-changed .` | CI job log |
| Static analyze | Dart/Flutter statikus ellenőrzés | `lint` job | `flutter analyze` | CI job log |
| Unit + widget | `mobile/nearpick/test/**` | `test` job, `Flutter unit/widget tests + JUnit` | `flutter test --machine | tojunit > reports/junit-flutter.xml` | `mobile/nearpick/reports/junit-flutter.xml` + `flutter-junit` artifact |
| Integration (Flutter) | `mobile/nearpick/integration_test/**` | `test` job, `Flutter integration tests (if present)` | `flutter test integration_test` | CI step log (jelenleg nincs külön JUnit erre a lépésre) |

## Legutolsó futás (kitölthető mező)
- Futás dátuma (UTC): `2026-03-03 17:54 UTC`
- Workflow run URL: `https://github.com/SZTE-SZF/1-sprint-Admgt/actions/runs/22635961651`
- Branch: `main`
- Commit SHA: `98a04c1`
- Flutter verzió (CI env): `3.41.3`
- Unit/widget teszt db (junit alapján): `5`
- Sikertelen teszt db (junit alapján): `0`
- Integration tesztek futottak: `igen (step lefutott, testcase: 0)`
- Integration eredmény röviden: `A CI integration lépés sikeres, de futtatható integration_test/*.dart teszt nem volt.`

## Ismert hiányosságok
- A `mobile/nearpick/integration_test/` mappa most scaffoldolva van, de jelenleg nincs benne konkrét tesztfájl, ezért a CI integration lépés tipikusan kimarad.
- E2E/contract tesztekhez jelenleg nincs külön JUnit export; az evidence a CI step logban jelenik meg.
- CI-ben nincs coverage gate (`flutter test --coverage` és threshold nincs bekötve).
- Egyes logikák jelenleg UI-ba vannak ágyazva (példa: `new_product_screen.dart` validáció, `merchant_dashboard_screen.dart` aggregáció), ez lassítja a gyors unit tesztelést.
- A `DateTime.now()` és `Random.secure()` használat több helyen nem teljesen determinisztikus (példa: ajánlás pontszám, pickup kód generálás).

## Flaky policy
- Flaky teszt merge gate-ben nem maradhat aktív.
- Átmeneti quarantine legfeljebb 7 napig engedett, kötelező javitási issue-val.
- CI újrafuttatás legfeljebb 1 alkalommal elfogadott ugyanarra a teszthibára.
- Ha ugyanaz a teszt 2 egymást követő napon flaky, javítani kell vagy ideiglenesen ki kell venni a gate-ből dokumentált indokkal.

## Lokális futtatás (CI-vel azonos sorrendben)
Repo gyökérből:

```bash
bash scripts/test_all.sh
```

Kézi futtatás (ha script nélkül kell):

```bash
cd mobile/nearpick
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
dart pub global activate junitreport
flutter test --machine | tojunit > reports/junit-flutter.xml
flutter test integration_test   # csak ha van integration_test/** fájl
```


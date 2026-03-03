# Teszt riport - product-quality elokeszites

## Evidence baseline (CI-hez kotve)
- CI workflow referencia: [.github/workflows/ci.yml](../../.github/workflows/ci.yml)
- Flutter JUnit artifact fajl: [mobile/nearpick/reports/junit-flutter.xml](../../mobile/nearpick/reports/junit-flutter.xml)
- Flutter projekt gyoker: [mobile/nearpick](../../mobile/nearpick)
- Lokalis futtato script (opcionalis): [scripts/test_all.sh](../../scripts/test_all.sh)

Ez a riport direkt a jelenlegi CI lepeseire epit:
- `Flutter unit/widget tests + JUnit`: `flutter test --machine | tojunit > reports/junit-flutter.xml`
- `Flutter integration tests (if present)`: csak akkor fut, ha van `mobile/nearpick/integration_test/**`

## Suite-ek es futtatasi parancsok
| Suite | Lefedett terulet | CI lepes | Parancs | Evidence |
|---|---|---|---|---|
| Format gate | Formazasi szabalyszeruseg | `lint` job | `dart format --set-exit-if-changed .` | CI job log |
| Static analyze | Dart/Flutter statikus ellenorzes | `lint` job | `flutter analyze` | CI job log |
| Unit + widget | `mobile/nearpick/test/**` | `test` job, `Flutter unit/widget tests + JUnit` | `flutter test --machine | tojunit > reports/junit-flutter.xml` | `mobile/nearpick/reports/junit-flutter.xml` + `flutter-junit` artifact |
| Integration (Flutter) | `mobile/nearpick/integration_test/**` | `test` job, `Flutter integration tests (if present)` | `flutter test integration_test` | CI step log (jelenleg nincs kulon JUnit erre a lepesre) |

## Legutolso futas (kitoltheto mezo)
- Futas datuma (UTC): `<kitoltendo>`
- Workflow run URL: `<kitoltendo>`
- Branch: `<kitoltendo>`
- Commit SHA: `<kitoltendo>`
- Flutter verzio (CI env): `3.41.3`
- Unit/widget teszt db (junit alapjan): `<kitoltendo>`
- Sikertelen teszt db (junit alapjan): `<kitoltendo>`
- Integration tesztek futottak: `<igen/nem>`
- Integration eredmeny roviden: `<kitoltendo>`

## Ismert hianyossagok
- A `mobile/nearpick/integration_test/` mappa most scaffoldolva van, de jelenleg nincs benne konkret tesztfajl, ezert a CI integration lepes tipikusan kimarad.
- E2E/contract tesztekhez jelenleg nincs kulon JUnit export; az evidence a CI step logban jelenik meg.
- CI-ben nincs coverage gate (`flutter test --coverage` es threshold nincs bekotve).
- Egyes logikak jelenleg UI-ba vannak agyazva (pelda: `new_product_screen.dart` validacio, `merchant_dashboard_screen.dart` aggregacio), ez lassitja a gyors unit tesztelest.
- A `DateTime.now()` es `Random.secure()` hasznalat tobb helyen nem teljesen determinisztikus (pelda: ajanlas pontszam, pickup kod generalas).

## Flaky policy
- Flaky teszt merge gate-ben nem maradhat aktiv.
- Atmeneti quarantine legfeljebb 7 napig engedett, kotelezo javitasi issue-val.
- CI ujrafuttatas legfeljebb 1 alkalommal elfogadott ugyanarra a teszthibara.
- Ha ugyanaz a teszt 2 egymast koveto napon flaky, javitani kell vagy ideiglenesen ki kell venni a gate-bol dokumentalt indokkal.

## Lokalis futtatas (CI-vel azonos sorrendben)
Repo gyokerbol:

```bash
bash scripts/test_all.sh
```

Kezi futtatas (ha script nelkul kell):

```bash
cd mobile/nearpick
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
dart pub global activate junitreport
flutter test --machine | tojunit > reports/junit-flutter.xml
flutter test integration_test   # csak ha van integration_test/** fajl
```

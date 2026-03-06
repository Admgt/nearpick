# Képességtérkép

Az állapotértékek jelentése:
- `Done`: megvalósítva és bizonyítékokkal alátámasztva.
- `Partial`: részben megvalósítva, vagy a bizonyítékok/tesztek még nem teljesek.
- `Planned`: definiálva van, de még nincs megvalósítva.

| Képesség | Kategória | Bizonyíték | Teszt | Állapot |
|---|---|---|---|---|
| Szerepkör alapú hitelesítés és útválasztás (vásárló/kereskedő) | Termékesítés | [`mobile/nearpick/lib/main.dart`](../../mobile/nearpick/lib/main.dart), [`mobile/nearpick/lib/services/auth_service.dart`](../../mobile/nearpick/lib/services/auth_service.dart) | [`mobile/nearpick/test/widget_test.dart`](../../mobile/nearpick/test/widget_test.dart) | Partial |
| Kereskedői termék létrehozása opcionális képpel/helyszínnel | Érték | [`mobile/nearpick/lib/features/merchant/new_product_screen.dart`](../../mobile/nearpick/lib/features/merchant/new_product_screen.dart), [`mobile/nearpick/lib/services/product_service.dart`](../../mobile/nearpick/lib/services/product_service.dart) | [`sprints/02/tests/acceptance/create_product.feature`](../../sprints/02/tests/acceptance/create_product.feature) | Partial |
| Vásárlói rangsorolás és ajánlási indokok | Érték | [`mobile/nearpick/lib/recommendation/recommendation_engine.dart`](../../mobile/nearpick/lib/recommendation/recommendation_engine.dart), [`mobile/nearpick/lib/features/consumer/consumer_home_screen.dart`](../../mobile/nearpick/lib/features/consumer/consumer_home_screen.dart) | [`mobile/nearpick/test/widget_test.dart`](../../mobile/nearpick/test/widget_test.dart) | Partial |
| Foglalási életciklus (foglalás + teljesítés) | Érték | [`mobile/nearpick/lib/services/reservation_service.dart`](../../mobile/nearpick/lib/services/reservation_service.dart), [`mobile/nearpick/lib/features/consumer/product_detail_screen.dart`](../../mobile/nearpick/lib/features/consumer/product_detail_screen.dart) | [`docs/04_quality/test_backlog.md`](../04_quality/test_backlog.md) | Partial |
| CI minőségkapuk (formázás, elemzés, build, teszt) | Termékesítés | [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml), [`docs/04_quality/test_report.md`](../04_quality/test_report.md) | [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) | Done |
| Firestore/Storage hozzáférés-vezérlési alapok | Termékesítés | [`firestore.rules`](../../firestore.rules), [`storage.rules`](../../storage.rules) | [`docs/04_quality/test_backlog.md`](../04_quality/test_backlog.md) | Partial |
| Értesítési célzás új termék eseményekre | Érték | [`functions/index.js`](../../functions/index.js), [`mobile/nearpick/lib/services/notification_service.dart`](../../mobile/nearpick/lib/services/notification_service.dart) | [`docs/04_quality/test_backlog.md`](../04_quality/test_backlog.md) | Partial |
| Deploy/runbook/megfigyelhetőségi alapok | Termékesítés | [`sprints/02/deploy/target.yaml`](../../sprints/02/deploy/target.yaml), [`sprints/02/infra/terraform/README.md`](../../sprints/02/infra/terraform/README.md) | [`sprints/02/scripts/smoke.yaml`](../../sprints/02/scripts/smoke.yaml) | Partial |

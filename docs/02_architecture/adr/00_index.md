# ADR index

## Módszertan röviden

Az ADR (Architecture Decision Record) rövid, verziózott döntési rekord, amely egy konkrét architekturális döntést, annak indoklását és következményeit rögzíti. A NearPick projektben az ADR-ek célja, hogy a szakdolgozati értékeléshez és a későbbi karbantartáshoz egyértelműen visszakövethető legyen, miért lett a Flutter + Firebase, kliens-vezérelt, serverless piactér-architektúra választva.

Az itt szereplő ADR-ek a korábbi sprint-dokumentumokban található döntéseket egységes, release-ready formában konszolidálják. Előzményként különösen relevánsak:

- `sprints/01/architecture/adr/0001-first-tech-choice.md`
- `sprints/02/docs/adr/0001-deployment-target.md`
- `sprints/02/docs/adr/0002-platform-choice.md`
- `sprints/02/docs/adr/0003-iac-deploy-strategy.md`

## Döntési életciklus

- `Javasolt`: a döntés még vita vagy pontosítás alatt áll.
- `Elfogadva`: a döntés aktív, ez alapján épül a jelenlegi rendszer és dokumentáció.
- `Módosítva`: a döntés lényege megmaradt, de pontosítás vagy kiegészítés történt.
- `Felülírt`: egy újabb ADR leváltotta a korábbi döntést.
- `Elvetett`: a vizsgált opció végül nem került bevezetésre.

Jelen csomagban minden rekord `Elfogadva` státuszú, mert a repository jelenlegi állapotát írja le.

## ADR lista

- `0001_flutter_client_architecture.md`
  - A Flutter kliens UI + service + domain szerkezetének és a szerepkör alapú navigáció központi szerepének rögzítése.
- `0002_firebase_serverless_backend.md`
  - A Firebase Auth, Firestore, Storage, Functions és FCM alapú serverless backend választásának indoklása.
- `0003_firestore_security_rules_strategy.md`
  - A backend-oldali jogosultságkikényszerítés security rule központú stratégiájának rögzítése.
- `0004_interest_and_reservation_workflow.md`
  - Az érdeklődésjelölés, készletcsökkentés és foglalási életciklus fő workflow döntéseinek összefoglalása.
- `0005_ci_quality_gate_strategy.md`
  - A GitHub Actions alapú lint-build-test quality gate folyamat rögzítése.
- `0006_test_pyramid_definition.md`
  - A projekt tesztpiramisának, illetve a determinisztikus unit/widget/integration fókusznak a rögzítése.
- `0007_configuration_and_secret_management.md`
  - A minta konfigurációs fájlok, lokális secret-kezelés és demo Firebase projekt használatának dokumentálása.
- `0008_observability_and_logging_strategy.md`
  - A logolási baseline, minimum metrikák és incidensdiagnosztikai elvek rögzítése.

## Kapcsolódó architektúra-dokumentumok

- `../architecture_overview.md`
- `../c4_context_container.md`
- `../c4_component.md`
- `../quality_attributes.md`
- `../../03_design/api.md`
- `../../03_design/data_model.md`
- `../../03_design/error_handling.md`

# Önértékelés és készültségi scorecard

Dátum: `2026-04-08`

Ez a dokumentum a PDF 4.5 és 6. fejezetének megfelelő önértékelő melléklet. Az állapotok jelentése:

- `0.0`: nincs kész
- `0.5`: részben kész
- `1.0`: kész
- `N/A`: nem releváns

Megjegyzés:
- Ez egy köztes, dokumentációfrissítés utáni önértékelés.
- A pontozás a jelenlegi kód + dokumentáció auditjára támaszkodik; friss CI evidence és 2026-04-08-as lokális runtime tesztevidence is rögzítve van.

## 6.1 Gyors ellenőrzés 15 perc alatt

- [x] A repo klónozás után a `README` quickstart alapján elindítható demóútvonalat ír le.
- [x] A tesztek futtatása dokumentált.
- [x] A main/default branch aktuálisan rögzített zöld CI futásának konkrét linkje rögzítve van a [`ci_evidence.md`](ci_evidence.md) fájlban.
- [x] A secret hygiene dokumentált (`.env.example`, secret scan, gitignore).
- [x] A UX screenshot evidence a `docs/assets/ux/` alatt elérhető.

## 6.2 Kapu checklist

| Kapu feltétel | Státusz | Evidence / link | Megjegyzés |
|---|---|---|---|
| Futtathatóság: Quickstart alapján indul | Igen | [`README.md`](../../README.md), [`demo_environment.md`](demo_environment.md) | Demo Firebase projekt alapú reviewer útvonal dokumentálva |
| CI zöld a main/default branch-en | Igen | [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml), [`ci_evidence.md`](ci_evidence.md) | Az aktuálisan dokumentált HEAD-hez tartozó zöld run link rögzítve van |
| Nincs secret a repo-ban | Igen | [`.env.example`](../../.env.example), [`scripts/secret_scan.sh`](../../scripts/secret_scan.sh), [`scripts/secret_scan.ps1`](../../scripts/secret_scan.ps1), [`.gitignore`](../../.gitignore) | Secret scan és gitignore szabályok megvannak |
| Minimum tesztmix: 30+ automata teszt | Igen | [`test_strategy.md`](../04_quality/test_strategy.md), [`test_report.md`](../04_quality/test_report.md) | A statikus inventory 139 definíciót jelez, a friss runtime evidence pedig Flutter + Functions futást is alátámaszt |
| AI átláthatóság: manifest + prompt + verification | Igen | [`ai_manifest.md`](../07_ai/ai_manifest.md), [`prompt_log.md`](../07_ai/prompt_log.md), [`verification_log.md`](../07_ai/verification_log.md) | Megvannak, de mélységben még nem véglegesek |

## 6.3 100 pontos készültségi scorecard

### A) Product és scope - 10/12

| Pont | Követelmény | Állapot | Evidence / link |
|---|---:|---:|---|
| 2 | Vision kész és konkrét | 1.0 | [`vision.md`](../01_product/vision.md) |
| 2 | Scope Contract: MVP story-k + elfogadási kritériumok + scope fegyelem | 1.0 | [`scope_contract.md`](../01_product/scope_contract.md) |
| 2 | Capability Map kitöltve 6+ képességgel, státusszal és evidence linkekkel | 1.0 | [`capability_map.md`](../01_product/capability_map.md) |
| 2 | UX flow-k dokumentáltak: 2-3 fő flow + error/empty state | 1.0 | [`ux_flows.md`](../01_product/ux_flows.md), [`../assets/ux`](../assets/ux) |
| 2 | Mérőszámok/metrics: mit mérnél és miért | 1.0 | [`metrics.md`](../01_product/metrics.md) |
| 2 | Ismert korlátok + roadmap/tech debt | 1.0 | [`scope_contract.md`](../01_product/scope_contract.md), [`test_backlog.md`](../04_quality/test_backlog.md) |

### B) Képesség-szélesség - 9/10

| Pont | Követelmény | Állapot | Evidence / link |
|---|---:|---:|---|
| 2 | Legalább 6 capability, ebből minimum 3 termékesítő | 1.0 | [`capability_map.md`](../01_product/capability_map.md) |
| 2 | Minden Done capability-hez van konkrét evidence link | 1.0 | [`capability_map.md`](../01_product/capability_map.md) |
| 2 | Minden Done capability-hez van kapcsolt teszt vagy teszt bizonyíték | 1.0 | [`capability_map.md`](../01_product/capability_map.md), [`test_report.md`](../04_quality/test_report.md) |
| 2 | Edge case-ek és hibák capability szinten kezeltek | 1.0 | [`ux_flows.md`](../01_product/ux_flows.md), [`error_handling.md`](../03_design/error_handling.md) |
| 2 | A Planned/Partial elemek őszintén jelöltek | 1.0 | [`capability_map.md`](../01_product/capability_map.md) |

### C) Architektúra és döntések - 13/13

| Pont | Követelmény | Állapot | Evidence / link |
|---|---:|---:|---|
| 3 | C4 Context + Container diagram naprakészen | 1.0 | [`c4_context_container.md`](../02_architecture/c4_context_container.md) |
| 3 | Component/modul nézet dokumentált | 1.0 | [`c4_component.md`](../02_architecture/c4_component.md) |
| 3 | Minimum 8 ADR | 1.0 | [`00_index.md`](../02_architecture/adr/00_index.md) |
| 2 | Quality attributes + legalább 2 quality scenario | 1.0 | [`quality_attributes.md`](../02_architecture/quality_attributes.md) |
| 2 | Deployment view dokumentált | 1.0 | [`deployment_view.md`](../02_architecture/deployment_view.md), [`deploy_runbook.md`](../05_security_ops/deploy_runbook.md) |

### D) Engineering minőség - 11.5/15

| Pont | Követelmény | Állapot | Evidence / link |
|---|---:|---:|---|
| 3 | Kódszerkezet és moduláris felépítés | 1.0 | [`c4_component.md`](../02_architecture/c4_component.md), [`mobile/nearpick/lib`](../../mobile/nearpick/lib) |
| 3 | Egységes hibakezelés + input validáció + konzisztens hibamodel | 0.5 | [`error_handling.md`](../03_design/error_handling.md), [`api.md`](../03_design/api.md) |
| 2 | Konfiguráció és környezetek | 1.0 | [`configuration_matrix.md`](../03_design/configuration_matrix.md), [`README.md`](../../README.md), [`demo_environment.md`](demo_environment.md) |
| 3 | Teljesítmény baseline + 1 szűk keresztmetszet mérése és javítása | 0.5 | [`performance.md`](../04_quality/performance.md), [`quality_attributes.md`](../02_architecture/quality_attributes.md) |
| 2 | Statikus minőségi kapuk CI-ban | 1.0 | [`quality_gates_summary.md`](../04_quality/quality_gates_summary.md), [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) |
| 2 | Platform-specifikus minőség | 0.5 | [`ux_flows.md`](../01_product/ux_flows.md), [`mobile/nearpick/README.md`](../../mobile/nearpick/README.md) |

### E) Tesztelés és minőségi kapuk - 13/15

| Pont | Követelmény | Állapot | Evidence / link |
|---|---:|---:|---|
| 2 | Teszt stratégia és teszt riport kitöltve | 1.0 | [`test_strategy.md`](../04_quality/test_strategy.md), [`test_report.md`](../04_quality/test_report.md) |
| 4 | 30+ automata teszt értelmes mixben | 1.0 | [`test_report.md`](../04_quality/test_report.md), [`test_strategy.md`](../04_quality/test_strategy.md) |
| 3 | CI gating: tesztek kötelezően futnak | 1.0 | [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) |
| 2 | Integrációs tesztek valós függőségekkel | 1.0 | [`integration_test/README.md`](../../mobile/nearpick/integration_test/README.md), [`auth_and_product_flow_test.dart`](../../mobile/nearpick/integration_test/flows/auth_and_product_flow_test.dart), [`test_report.md`](../04_quality/test_report.md) |
| 2 | E2E/contract jellegű teszt a core flow-ra | 1.0 | [`auth_and_product_flow_test.dart`](../../mobile/nearpick/integration_test/flows/auth_and_product_flow_test.dart), [`test_report.md`](../04_quality/test_report.md) |
| 2 | Plusz minőségi teszt | 1.0 | [`functions/test/firestore_rules_policy.test.js`](../../functions/test/firestore_rules_policy.test.js), [`functions/test/observability.test.js`](../../functions/test/observability.test.js) |

### F) DevOps és üzemeltetés - 11/15

| Pont | Követelmény | Állapot | Evidence / link |
|---|---:|---:|---|
| 3 | CI pipeline komplett | 1.0 | [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) |
| 2 | Reprodukálható build/dependency kezelés | 1.0 | [`pubspec.lock`](../../mobile/nearpick/pubspec.lock), [`package-lock.json`](../../functions/package-lock.json) |
| 3 | Deploy leírás + környezetek | 1.0 | [`deploy_runbook.md`](../05_security_ops/deploy_runbook.md), [`demo_environment.md`](demo_environment.md) |
| 2 | Rollback terv | 1.0 | [`deploy_runbook.md`](../05_security_ops/deploy_runbook.md) |
| 3 | Observability baseline: log + healthcheck + 3 metrika | 1.0 | [`observability.md`](../05_security_ops/observability.md), [`functions/index.js`](../../functions/index.js) |
| 2 | Runbook: 2 incident scenario + teendők | 1.0 | [`deploy_runbook.md`](../05_security_ops/deploy_runbook.md) |

### G) Security, privacy, licenc - 9/10

| Pont | Követelmény | Állapot | Evidence / link |
|---|---:|---:|---|
| 3 | Threat model 6+ tétellel + konkrét mitigációk | 1.0 | [`threat_model.md`](../05_security_ops/threat_model.md) |
| 2 | Secret hygiene rendben | 1.0 | [`.env.example`](../../.env.example), [`scripts/secret_scan.sh`](../../scripts/secret_scan.sh), [`scripts/secret_scan.ps1`](../../scripts/secret_scan.ps1), [`.gitignore`](../../.gitignore) |
| 2 | AuthN/AuthZ modell dokumentált és tesztelt | 0.5 | [`api.md`](../03_design/api.md), [`firestore.rules`](../../firestore.rules), [`functions/test/firestore_rules_policy.test.js`](../../functions/test/firestore_rules_policy.test.js) |
| 2 | Dependency vulnerability ellenőrzés + kezelési terv | 1.0 | [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml), [`quality_gates_summary.md`](../04_quality/quality_gates_summary.md), [`audit_pub_dependencies.dart`](../../mobile/nearpick/tool/audit_pub_dependencies.dart) |
| 1 | Privacy + licensing | 1.0 | [`privacy_licensing.md`](../05_security_ops/privacy_licensing.md), [`publication_policy.md`](publication_policy.md), [`../../LICENSE`](../../LICENSE) |

### H) AI engineering érettség - 9/10

| Pont | Követelmény | Állapot | Evidence / link |
|---|---:|---:|---|
| 2 | AI manifest: eszközök és használati területek | 1.0 | [`ai_manifest.md`](../07_ai/ai_manifest.md) |
| 2 | Prompt log: 10-20 kulcsprompt | 1.0 | [`prompt_log.md`](../07_ai/prompt_log.md) |
| 3 | Verification log: legalább 10 verifikáció | 1.0 | [`verification_log.md`](../07_ai/verification_log.md) |
| 2 | AI output integráció: teszt + review checklist | 0.5 | [`ai_manifest.md`](../07_ai/ai_manifest.md), [`review_checklist.md`](../07_ai/review_checklist.md) |
| 1 | Tanulságok és guardrail-ek dokumentálva | 1.0 | [`ai_manifest.md`](../07_ai/ai_manifest.md), [`verification_log.md`](../07_ai/verification_log.md) |

## Összesítés

- A) Product és scope: `10/12`
- B) Képesség-szélesség: `9/10`
- C) Architektúra és döntések: `13/13`
- D) Engineering minőség: `11.5/15`
- E) Tesztelés és minőségi kapuk: `13/15`
- F) DevOps és üzemeltetés: `11/15`
- G) Security, privacy, licenc: `9/10`
- H) AI engineering érettség: `9/10`

Összpontszám: `85.5/100`

## Következő legnagyobb pontnyereségek

1. A performance benchmark optimalizálás utáni újrafuttatása és az eredmény rögzítése.
2. További `integration_test` flow-k hozzáadása account/location, reservation/refund/review és QR utakra.
3. Az auth/rules allow-deny coverage további bővítése, hogy az AuthN/AuthZ score is 1.0-ra emelhető legyen.
4. A performance benchmark újramérése és az eredmény dokumentálása a bővült mobil scope mellett.

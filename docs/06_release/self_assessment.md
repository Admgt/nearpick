# Önértékelés és készültségi scorecard

Dátum: `2026-03-16`

Ez a dokumentum a PDF 4.5 és 6. fejezetének megfelelő önértékelő melléklet. Az állapotok jelentése:

- `0.0`: nincs kész
- `0.5`: részben kész
- `1.0`: kész
- `N/A`: nem releváns

## 6.1 Gyors ellenőrzés 15 perc alatt

- [x] A repo klónozás után a `README` quickstart alapján elindítható demóútvonalat ír le.
- [x] A tesztek futtatása dokumentált.
- [ ] A main/default branch legutóbbi zöld CI futásának konkrét linkje nincs bemásolva ebbe a dokumentumba.
- [x] A secret hygiene dokumentált (`.env.example`, secret scan, gitignore).
- [x] A UX screenshot evidence a `docs/assets/ux/` alatt elérhető.

## 6.2 Kapu checklist

| Kapu feltétel | Státusz | Evidence / link | Megjegyzés |
|---|---|---|---|
| Futtathatóság: Quickstart alapján indul | Igen | [`README.md`](../../README.md), [`demo_environment.md`](demo_environment.md) | Demo Firebase projekt alapú reviewer útvonal dokumentálva |
| CI zöld a main/default branch-en | Részben | [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) | Workflow megvan, de az utolsó zöld run konkrét linkje nincs rögzítve |
| Nincs secret a repo-ban | Igen | [`.env.example`](../../.env.example), [`scripts/secret_scan.sh`](../../scripts/secret_scan.sh), [`scripts/secret_scan.ps1`](../../scripts/secret_scan.ps1), [`.gitignore`](../../.gitignore) | Secret scan és gitignore szabályok megvannak |
| Minimum tesztmix: 30+ automata teszt | Igen | [`test_strategy.md`](../04_quality/test_strategy.md), [`test_report.md`](../04_quality/test_report.md) | 73 automata teszt dokumentálva |
| AI átláthatóság: manifest + prompt + verification | Igen | [`ai_manifest.md`](../07_ai/ai_manifest.md), [`prompt_log.md`](../07_ai/prompt_log.md), [`verification_log.md`](../07_ai/verification_log.md) | Megvannak, de mélységben még nem véglegesek |

## 6.3 100 pontos készültségi scorecard

### A) Product és scope - 9/12

| Pont | Követelmény | Állapot | Evidence / link |
|---|---:|---:|---|
| 2 | Vision kész és konkrét | 1.0 | [`vision.md`](../01_product/vision.md) |
| 2 | Scope Contract: MVP story-k + elfogadási kritériumok + scope fegyelem | 1.0 | [`scope_contract.md`](../01_product/scope_contract.md) |
| 2 | Capability Map kitöltve 6+ képességgel, státusszal és evidence linkekkel | 0.5 | [`capability_map.md`](../01_product/capability_map.md) |
| 2 | UX flow-k dokumentáltak: 2-3 fő flow + error/empty state | 1.0 | [`ux_flows.md`](../01_product/ux_flows.md), [`../assets/ux`](../assets/ux) |
| 2 | Mérőszámok/metrics: mit mérnél és miért | 1.0 | [`metrics.md`](../01_product/metrics.md) |
| 2 | Ismert korlátok + roadmap/tech debt | 1.0 | [`scope_contract.md`](../01_product/scope_contract.md), [`test_backlog.md`](../04_quality/test_backlog.md) |

### B) Képesség-szélesség - 8/10

| Pont | Követelmény | Állapot | Evidence / link |
|---|---:|---:|---|
| 2 | Legalább 6 capability, ebből minimum 3 termékesítő | 1.0 | [`capability_map.md`](../01_product/capability_map.md) |
| 2 | Minden Done capability-hez van konkrét evidence link | 0.5 | [`capability_map.md`](../01_product/capability_map.md) |
| 2 | Minden Done capability-hez van kapcsolt teszt vagy teszt bizonyíték | 0.5 | [`capability_map.md`](../01_product/capability_map.md), [`test_report.md`](../04_quality/test_report.md) |
| 2 | Edge case-ek és hibák capability szinten kezeltek | 1.0 | [`ux_flows.md`](../01_product/ux_flows.md), [`error_handling.md`](../03_design/error_handling.md) |
| 2 | A Planned/Partial elemek őszintén jelöltek | 1.0 | [`capability_map.md`](../01_product/capability_map.md) |

### C) Architektúra és döntések - 12/13

| Pont | Követelmény | Állapot | Evidence / link |
|---|---:|---:|---|
| 3 | C4 Context + Container diagram naprakészen | 1.0 | [`c4_context_container.md`](../02_architecture/c4_context_container.md) |
| 3 | Component/modul nézet dokumentált | 1.0 | [`c4_component.md`](../02_architecture/c4_component.md) |
| 3 | Minimum 8 ADR | 1.0 | [`00_index.md`](../02_architecture/adr/00_index.md) |
| 2 | Quality attributes + legalább 2 quality scenario | 1.0 | [`quality_attributes.md`](../02_architecture/quality_attributes.md) |
| 2 | Deployment view dokumentált | 0.5 | [`c4_context_container.md`](../02_architecture/c4_context_container.md), [`deploy_runbook.md`](../05_security_ops/deploy_runbook.md) |

### D) Engineering minőség - 10.5/15

| Pont | Követelmény | Állapot | Evidence / link |
|---|---:|---:|---|
| 3 | Kódszerkezet és moduláris felépítés | 1.0 | [`c4_component.md`](../02_architecture/c4_component.md), [`mobile/nearpick/lib`](../../mobile/nearpick/lib) |
| 3 | Egységes hibakezelés + input validáció + konzisztens hibamodel | 0.5 | [`error_handling.md`](../03_design/error_handling.md), [`api.md`](../03_design/api.md) |
| 2 | Konfiguráció és környezetek | 0.5 | [`README.md`](../../README.md), [`demo_environment.md`](demo_environment.md) |
| 3 | Teljesítmény baseline + 1 szűk keresztmetszet mérése és javítása | 0.5 | [`performance.md`](../04_quality/performance.md), [`quality_attributes.md`](../02_architecture/quality_attributes.md) |
| 2 | Statikus minőségi kapuk CI-ban | 1.0 | [`quality_gates_summary.md`](../04_quality/quality_gates_summary.md), [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) |
| 2 | Platform-specifikus minőség | 0.5 | [`ux_flows.md`](../01_product/ux_flows.md), [`mobile/nearpick/README.md`](../../mobile/nearpick/README.md) |

### E) Tesztelés és minőségi kapuk - 12/15

| Pont | Követelmény | Állapot | Evidence / link |
|---|---:|---:|---|
| 2 | Teszt stratégia és teszt riport kitöltve | 1.0 | [`test_strategy.md`](../04_quality/test_strategy.md), [`test_report.md`](../04_quality/test_report.md) |
| 4 | 30+ automata teszt értelmes mixben | 1.0 | [`test_report.md`](../04_quality/test_report.md), [`test_strategy.md`](../04_quality/test_strategy.md) |
| 3 | CI gating: tesztek kötelezően futnak | 1.0 | [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) |
| 2 | Integrációs tesztek valós függőségekkel | 0.5 | [`integration_test/README.md`](../../mobile/nearpick/integration_test/README.md), [`auth_and_product_flow_test.dart`](../../mobile/nearpick/integration_test/flows/auth_and_product_flow_test.dart) |
| 2 | E2E/contract jellegű teszt a core flow-ra | 1.0 | [`auth_and_product_flow_test.dart`](../../mobile/nearpick/integration_test/flows/auth_and_product_flow_test.dart), [`test_report.md`](../04_quality/test_report.md) |
| 2 | Plusz minőségi teszt | 1.0 | [`functions/test/firestore_rules_policy.test.js`](../../functions/test/firestore_rules_policy.test.js), [`functions/test/observability.test.js`](../../functions/test/observability.test.js) |

### F) DevOps és üzemeltetés - 12/15

| Pont | Követelmény | Állapot | Evidence / link |
|---|---:|---:|---|
| 3 | CI pipeline komplett | 1.0 | [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) |
| 2 | Reprodukálható build/dependency kezelés | 1.0 | [`pubspec.lock`](../../mobile/nearpick/pubspec.lock), [`package-lock.json`](../../functions/package-lock.json) |
| 3 | Deploy leírás + környezetek | 0.5 | [`deploy_runbook.md`](../05_security_ops/deploy_runbook.md), [`demo_environment.md`](demo_environment.md) |
| 2 | Rollback terv | 1.0 | [`deploy_runbook.md`](../05_security_ops/deploy_runbook.md) |
| 3 | Observability baseline: log + healthcheck + 3 metrika | 1.0 | [`observability.md`](../05_security_ops/observability.md), [`functions/index.js`](../../functions/index.js) |
| 2 | Runbook: 2 incident scenario + teendők | 1.0 | [`deploy_runbook.md`](../05_security_ops/deploy_runbook.md) |

### G) Security, privacy, licenc - 8/10

| Pont | Követelmény | Állapot | Evidence / link |
|---|---:|---:|---|
| 3 | Threat model 6+ tétellel + konkrét mitigációk | 1.0 | [`threat_model.md`](../05_security_ops/threat_model.md) |
| 2 | Secret hygiene rendben | 1.0 | [`.env.example`](../../.env.example), [`scripts/secret_scan.sh`](../../scripts/secret_scan.sh), [`scripts/secret_scan.ps1`](../../scripts/secret_scan.ps1), [`.gitignore`](../../.gitignore) |
| 2 | AuthN/AuthZ modell dokumentált és tesztelt | 0.5 | [`api.md`](../03_design/api.md), [`firestore.rules`](../../firestore.rules), [`functions/test/firestore_rules_policy.test.js`](../../functions/test/firestore_rules_policy.test.js) |
| 2 | Dependency vulnerability ellenőrzés + kezelési terv | 0.5 | [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml), [`quality_gates_summary.md`](../04_quality/quality_gates_summary.md) |
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

- A) Product és scope: `9/12`
- B) Képesség-szélesség: `8/10`
- C) Architektúra és döntések: `12/13`
- D) Engineering minőség: `10.5/15`
- E) Tesztelés és minőségi kapuk: `12/15`
- F) DevOps és üzemeltetés: `12/15`
- G) Security, privacy, licenc: `8/10`
- H) AI engineering érettség: `9/10`

Összpontszám: `80.5/100`

## Következő legnagyobb pontnyereségek

1. A performance benchmark optimalizálás utáni újrafuttatása és az eredmény rögzítése.
2. CI main/default branch zöld futásának konkrét evidence linkelése.
3. További `integration_test` flow-k hozzáadása reservation és completion utakra.
4. Flutter oldali dependency-vulnerability audit hozzáadása.

# Verifikációs napló

Ez a fájl az AI által javasolt állítások és generált artefaktumok validálását követi.

| AI állítás/javaslat | Kockázat, ha hibás | Ellenőrzési módszer | Eredmény | Következtetés/változás |
|---|---|---|---|---|
| "A jelenlegi tesztbaseline elegendő a release gate-hez" | Hamis biztonságérzet, regressziók | Összevetés a dokumentált tesztdarabszám-követelményekkel és a meglévő tesztekkel | Fail | Explicit hiánydokumentáció került a quality doksikba és backlog hivatkozásokba |
| "A repo tesztmixe eléri a minimum 30+ automata küszöböt" | Téves release-readiness megítélés | Mérés: repo audit és tesztszámlálás (`54` Dart test-like + `28` functions test) | Pass | A mennyiségi minimum teljesül, a minőségi és integrációs mélység továbbra is külön kockázat |
| "A CI minőségkapuk be vannak kötve az alap engineering ellenőrzésekhez" | Törött merge quality gate | A CI workflow vizsgálata format/analyze/build/test sorrendre | Pass | Megerősítve itt: [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) |
| "Az ajánlási pontszámfüggvények helyesen clampelik az értékeket" | Hibás rangsorolás és instabil UX | Implementáció és meglévő unit tesztek vizsgálata a widget tesztfájlban | Pass (részleges bizonyosság) | Marad, és külön unit tesztekkel bővítendő a backlog alapján |
| "A Firestore rule-ok kikényszerítik a tulajdonosi/user határokat" | Jogosulatlan írások | Rule review a product/user/reservation útvonalakra | Pass (részleges) | A rules baseline marad, deny/allow automatizált tesztek hozzáadása szükséges |
| "A healthcheck endpoint és a strukturált szerverlogok ténylegesen jelen vannak" | Hamis operációs evidencia | PoC: `functions/index.js` és `functions/observability.js` kódútvonal bejárása, plusz observability baseline review | Pass | A baseline létezik; dashboard és alerting továbbra is hiányzik |
| "A `contextId` headerből vagy requestből konzisztensen előáll" | Nehéz incidenskorreláció | Meglévő tesztek átnézése: [`../../functions/test/observability.test.js`](../../functions/test/observability.test.js) | Pass | A szerveroldali korrelációs baseline megerősítve |
| "A valódi `integration_test` réteg már teljes CI quality gate" | Hamis E2E biztonságérzet | CI workflow és [`../../mobile/nearpick/integration_test/README.md`](../../mobile/nearpick/integration_test/README.md) auditja | Fail | A réteg létezik, de Android eszköz hiányában a CI-ben átugorható, ezért csak részleges gate |
| "A dependency audit már az egész alkalmazásra kiterjed" | Rejtett sérülékenységi rés | `.github/workflows/ci.yml`, `quality_gates_summary.md` és [`../../mobile/nearpick/tool/audit_pub_dependencies.dart`](../../mobile/nearpick/tool/audit_pub_dependencies.dart) auditja | Pass | A functions audit mellé bekerült a Flutter lockolt pub csomagjaira futó OSV alapú audit is |
| "A prompt- és AI használati evidence már teljes" | AI traceability gate bukik | AI artefaktok auditja a repositoryban (`manifest/prompt/verification`) | Fail | Eredetileg hiányos volt; a prompt- és verifikációs napló bővítése emiatt került be |
| "A promptnapló eléri a minimum 10 bejegyzést" | AI traceability továbbra is részleges marad | Mérés: a `prompt_log.md` táblázat sorainak újraszámlálása | Pass | A minimum bejegyzésszám teljesül |
| "A verifikációs napló eléri a minimum 10 tételt, köztük teszt- és mérésalapú ellenőrzésekkel" | AI verifikáció formális marad, de bizonyíték nélkül | Mérés: a `verification_log.md` bejegyzéseinek számlálása és a módszerek áttekintése | Pass | A minimum strukturális mélység teljesül; további runtime bizonyítékok később még növelhetik a hitelességet |
| "Van explicit AI review checklist a merge előtti ellenőrzéshez" | AI output review ad hoc marad | Artefakt audit: [`review_checklist.md`](review_checklist.md) + [`ai_manifest.md`](ai_manifest.md) | Pass | Az AI output integráció immár külön, linkelhető ellenőrzőlistát kapott |
| "A promptokból a secret és közvetlen PII kizárása dokumentált" | Véletlen adatszivárgás AI eszközök felé | Policy review: [`../../sprints/01/ai/usage_plan.yaml`](../../sprints/01/ai/usage_plan.yaml), [`../05_security_ops/privacy_licensing.md`](../05_security_ops/privacy_licensing.md) | Pass | A guardrail dokumentált, de továbbra is emberi fegyelemre támaszkodik |

## Állapot

- A verifikációs napló eléri a minimum elvárt 10+ tételt.
- Legalább 3 bejegyzés explicit teszt evidence-re támaszkodik.
- Legalább 2 bejegyzés mérés- vagy PoC-jellegű ellenőrzést dokumentál.

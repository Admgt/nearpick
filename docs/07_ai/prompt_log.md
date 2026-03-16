# Promptnapló

Ez a napló azokat a nagy hatású AI interakciókat gyűjti, amelyek a repository verziózott artefaktumaiból visszakövethetők.

Jelölések:
- `direct-log`: közvetlenül szerepel az AI naplóban
- `reconstructed`: verziózott artefaktumból és git-idővonalból rekonstruált promptcsalád

Megjegyzés:
- a táblázat nem nyers prompt dumpot tartalmaz, hanem auditálható promptösszefoglalókat
- a rekonstruált sorok szándékosan rövid, konzervatív leírások, hogy ne állítsanak többet annál, ami a repo-ból igazolható

| ID | Dátum / fázis | Forrás | Cél | Prompt összefoglaló | AI kimenet összefoglaló | Artefakt hivatkozás | Emberi módosítás |
|---|---|---|---|---|---|---|---|
| P-01 | 2025-10-20 | direct-log | Interjú-előkészítés | Nyitott, nem rávezető interjúkérdés-sor generálása korai user discovery-hoz | Interjúkérdés-struktúra és folyamat vázlata | [`../../sprints/01/interviews/001-zsofi.json`](../../sprints/01/interviews/001-zsofi.json) | Projekthez igazítva |
| P-02 | 2025-10-25 | direct-log | Versenytárselemzés | Összehasonlító versenytárstábla készítése termékpozicionáláshoz | Javasolt összehasonlítási dimenziók és bejegyzések | [`../../sprints/01/market/competitors.csv`](../../sprints/01/market/competitors.csv) | Tisztítva és CSV-re normalizálva |
| P-03 | 2025-10-27 | direct-log | ADR-vázlatolás | Kezdeti architektúradöntési rekord készítése az első stack-választáshoz | Javasolt ADR struktúra alternatívákkal és tradeoffokkal | [`../../sprints/01/architecture/adr/0001-first-tech-choice.md`](../../sprints/01/architecture/adr/0001-first-tech-choice.md) | Rövidítve és megfogalmazás igazítva |
| P-04 | 2026-03-06 (reconstructed) | reconstructed | Vision szerkesztés | Persona-, értékajánlat-, non-goal- és kockázatvázlat készítése tömör termékvízióhoz | Strukturált vision draft, metrika- és kockázatfejezetekkel | [`../01_product/vision.md`](../01_product/vision.md) | A NearPick scope-hoz és a meglévő metrikákhoz igazítva |
| P-05 | 2026-03-06 (reconstructed) | reconstructed | Scope contract pontosítás | MVP story-k, elfogadási kritériumok, stretch lista és release DoD rendezése | Scope contract vázlat sztori- és acceptance-centrikus bontással | [`../01_product/scope_contract.md`](../01_product/scope_contract.md) | A tényleges flow-khoz és a quality naplókhoz igazítva |
| P-06 | 2026-01-03..2026-03-07 (reconstructed) | reconstructed | Ajánlórendszer baseline | Szabályalapú ajánlási dimenziók, súlyozás és indoklási logika ötletelése | Recommendation baseline scoring és reason-list logika | [`../../mobile/nearpick/lib/recommendation/recommendation_engine.dart`](../../mobile/nearpick/lib/recommendation/recommendation_engine.dart) | Súlyok, clamp-ek és tesztelhetőség később kézzel finomítva |
| P-07 | 2025-11-11..2025-11-20 (reconstructed) | reconstructed | Acceptance flow draft | Merchant terméklétrehozási folyamat BDD/acceptance lépésekre bontása | `create_product.feature` első elfogadási forgatókönyv-vázlata | [`../../sprints/02/tests/acceptance/create_product.feature`](../../sprints/02/tests/acceptance/create_product.feature) | A tényleges űrlaplépésekhez és mezőkhöz igazítva |
| P-08 | 2025-12-03 (reconstructed) | reconstructed | Deploy/IaC tradeoff | Firebase Hosting, preview környezet és Terraform irány összevetése ADR-formában | Deployment/IaC ADR vázlat alternatívákkal és következményekkel | [`../../sprints/02/docs/adr/0003-iac-deploy-strategy.md`](../../sprints/02/docs/adr/0003-iac-deploy-strategy.md) | A projekt valós scope-jára szűkítve |
| P-09 | 2026-03-03..2026-03-16 (reconstructed) | reconstructed | Tesztbacklog bővítés | 30 elemes, unit/integration/e2e mixű tesztbacklog generálása negatív ágakkal | Strukturált tesztbacklog javasolt fájlutakkal és evidence mezőkkel | [`../04_quality/test_backlog.md`](../04_quality/test_backlog.md) | A meglévő suite-okhoz és CI lépésekhez kötve |
| P-10 | 2026-03-06 (reconstructed) | reconstructed | Security baseline doku | Threat model és privacy/licensing baseline szekciók vázlatolása | STRIDE-jellegű fenyegetési tábla és adatkezelési ellenőrzőpontok | [`../05_security_ops/threat_model.md`](../05_security_ops/threat_model.md), [`../05_security_ops/privacy_licensing.md`](../05_security_ops/privacy_licensing.md) | A tényleges Firestore/Functions útvonalakhoz és guardrail-ekhez igazítva |
| P-11 | 2026-03-14 (reconstructed) | reconstructed | Observability baseline | Strukturált logolás, healthcheck és minimál metrikák dokumentálása reviewer szemszögből | Observability baseline, logminták és diagnosztikai útmutató | [`../05_security_ops/observability.md`](../05_security_ops/observability.md) | A meglévő `functions/index.js` logmezőihez és healthcheck válaszhoz igazítva |

## Állapot

- A napló eléri a minimum elvárt 10+ bejegyzést.
- A közvetlenül naplózott AI-használat továbbra is csak részben áll rendelkezésre; ezt a táblázat rekonstruált promptcsaládokkal egészíti ki.

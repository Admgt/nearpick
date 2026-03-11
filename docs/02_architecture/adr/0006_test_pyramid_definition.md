# ADR 0006 - Tesztpiramis definíció

- Dátum: 2026-03-11
- Státusz: Elfogadva

## Kontextus

A NearPick rendszerben a teljes Firebase emulator alapú end-to-end környezet még nem teljes, ezért olyan tesztstratégiára volt szükség, amely determinisztikusan bizonyítja a kritikus viselkedéseket. A rendszer egyszerre tartalmaz UI-komponenseket, tiszta üzleti logikát és Firebase-közeli workflow-kat.

## Döntés

A projekt tesztpiramisát az alábbi elv szerint definiáljuk:

- az alapot a unit tesztek adják a modellekre, helper függvényekre, ajánlási logikára és validációra
- a középső szintet widget tesztek adják a kulcs képernyők és interakciók validálására
- a felső réteg jelenleg determinisztikus integration/workflow tesztekből áll, in-memory vagy adapteres megközelítéssel
- a teljes `integration_test` alapú e2e és rules contract suite tervben van, de nem ez a jelenlegi minimum evidence

## Következmények

Pozitív következmények:

- gyors és stabil tesztfuttatás CI-ban
- a fő üzleti logika és UI visszajelzés jól izolálható
- a szakdolgozati minőségi bizonyítás nem függ teljesen külső szolgáltatásoktól

Negatív vagy vállalt tradeoffok:

- a jelenlegi legfelső szint nem teljes valódi eszközös e2e
- egyes Firebase-specifikus integrációk csak részben bizonyítottak
- a rules contract coverage további erősítést igényel

## Alternatívák

- Teljes mértékben emulator- és e2e-központú stratégia
  - előny: erősebb környezethű bizonyítás
  - hátrány: lassabb, törékenyebb és jelenleg hiányos
- Csak unit tesztek
  - előny: gyors
  - hátrány: a UI és workflow viselkedés nem bizonyított
- Manuális tesztelés központú validáció
  - előny: gyors indulás
  - hátrány: nem skálázható és nem ismételhető

## Verification

- Tesztek:
  - `mobile/nearpick/test/unit/**`
  - `mobile/nearpick/test/widget/**`
  - `mobile/nearpick/test/integration/**`
- CI evidence:
  - `.github/workflows/ci.yml`
  - `docs/04_quality/test_report.md`
- Dokumentációs artefaktok:
  - `docs/04_quality/test_strategy.md`
  - `docs/04_quality/test_backlog.md`
  - `docs/06_release/release_checklist.md`
- Manuális demó validáció:
  - `docs/06_release/demo_script.md`
  - `docs/01_product/ux_flows.md`

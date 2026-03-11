# ADR 0005 - CI quality gate stratégia

- Dátum: 2026-03-11
- Státusz: Elfogadva

## Kontextus

A szakdolgozati projekt bírálhatóságához szükség van ismételhető, repository-szintű minőségi kapura. A cél nem csak a buildelhetőség, hanem annak bizonyítása is, hogy a formázás, statikus elemzés, tesztfuttatás és alap build ellenőrzés automatizáltan fut.

## Döntés

A repository minőségi kapuja GitHub Actions alapú CI workflow-ra épül, amely:

- külön `lint`, `build` és `test` jobokra bontja a folyamatot
- Flutter oldalon futtatja a `pub get`, format gate, analyze, test és web build lépéseket
- a functions mappa esetén futtatja a Node telepítést és az elérhető npm lépéseket
- JUnit artefaktot generál a Flutter tesztekhez
- a fő ágra és pull requestekre is lefut

## Következmények

Pozitív következmények:

- a minőségi minimum minden merge-nél újrafuttatható
- a hibák hamarabb észlelhetők, mint manuális ellenőrzéssel
- a szakdolgozati release csomaghoz objektív CI evidence áll rendelkezésre

Negatív vagy vállalt tradeoffok:

- a CI még nem tartalmaz teljes security audit vagy teljes e2e coverage lépést
- a Flutter és Node környezet verzióit karban kell tartani
- a helyi és CI környezet közti eltérések dokumentálást igényelnek

## Alternatívák

- Csak lokális minőségellenőrzés
  - előny: egyszerű
  - hátrány: nem auditálható, nem reprodukálható
- Egyetlen monolit CI job
  - előny: gyorsabban összerakható
  - hátrány: gyengébb áttekinthetőség és hibadiagnosztika
- Külső CI szolgáltató
  - előny: más integrációs lehetőségek
  - hátrány: a jelenlegi GitHub-centrikus workflow-hoz kevésbé illeszkedik

## Verification

- Tesztek:
  - a CI által futtatott `flutter test` suite-ok a `mobile/nearpick/test/**` alatt
  - `functions/test/**`
- CI evidence:
  - `.github/workflows/ci.yml`
  - `docs/assets/logs/flutter_test_latest.log`
  - `docs/04_quality/test_report.md`
- Dokumentációs artefaktok:
  - `docs/04_quality/test_strategy.md`
  - `docs/06_release/release_checklist.md`
  - `README.md`
- Manuális demó validáció:
  - `docs/06_release/demo_script.md` minőségi evidence blokkja

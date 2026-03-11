# ADR 0004 - Érdeklődési és foglalási workflow

- Dátum: 2026-03-11
- Státusz: Elfogadva

## Kontextus

A NearPick fő üzleti értékét az adja, hogy a fogyasztó gyorsan érdeklődést tud jelezni, releváns ajánlatokat kap, majd készletütközés nélkül tud foglalni. A workflow-nak egyszerre kell támogatnia az ajánlási inputokat, a készletkezelést és a felhasználó számára érthető státuszvisszajelzést.

## Döntés

Az érdeklődési és foglalási modell a következőkre épül:

- az `interests` kollekció rögzíti a user és product kapcsolatot
- a termékek `interestCount` mezője aggregált érdeklődési jelként is használható
- a foglalás `reservations` dokumentummal reprezentált életciklus
- a készletkezelés és foglalás tranzakciós szemantikával működik
- a fogyasztói és kereskedői nézet külön státusz-alapú képernyőkkel követi a foglalás állapotát

## Következmények

Pozitív következmények:

- az ajánlási és üzleti folyamat ugyanarra az adatmodellre épül
- a készletütközések kezelése dokumentált és tesztelhető
- a demo flow-ban jól bemutatható a termék létrehozása, megjelenése, foglalása és részletnézete

Negatív vagy vállalt tradeoffok:

- az aggregált számlálók és a tranzakciós lépések gondos konzisztenciakezelést igényelnek
- a workflow egy része közvetlen kliensből indított Firestore/Firebase műveletekre épül
- a versenyhelyzeti garanciák később erősíthetők lennének vastagabb backend kontrollal

## Alternatívák

- Csak kedvencjelölés, külön `interests` kollekció nélkül
  - előny: egyszerűbb adatmodell
  - hátrány: gyengébb ajánlási és analitikai jel
- Tiszta szerveroldali reservation orchestration
  - előny: erősebb invariáns-kikényszerítés
  - hátrány: nagyobb backend-komplexitás
- Teljesen eventual consistency alapú készletkezelés
  - előny: egyszerűbb implementáció
  - hátrány: túlfoglalási kockázat

## Verification

- Tesztek:
  - `mobile/nearpick/test/integration/product/product_workflow_test.dart`
  - `mobile/nearpick/test/integration/reservation/reservation_workflow_test.dart`
  - `mobile/nearpick/test/unit/reservation/pickup_code_generator_test.dart`
  - `mobile/nearpick/test/unit/consumer/offer_filter_test.dart`
- CI evidence:
  - `.github/workflows/ci.yml`
  - `docs/04_quality/test_report.md`
- Dokumentációs artefaktok:
  - `docs/03_design/data_model.md`
  - `docs/04_quality/test_strategy.md`
  - `docs/05_security_ops/threat_model.md`
- Manuális demó validáció:
  - `docs/01_product/ux_flows.md`
  - `docs/06_release/demo_script.md`

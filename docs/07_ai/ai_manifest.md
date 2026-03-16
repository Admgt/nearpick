# AI manifest

## Eszközök és verziók (ismert)

1. ChatGPT
- Tervezéshez, elemzéshez és dokumentációírási támogatáshoz használva.

2. GitHub Copilot
- Kódolási támogatásra és boilerplate gyorsításra használva.

Evidence forrás:
- [`../../sprints/01/ai/usage_plan.yaml`](../../sprints/01/ai/usage_plan.yaml)
- [`../../sprints/01/ai/ai_log.jsonl`](../../sprints/01/ai/ai_log.jsonl)
- [`prompt_log.md`](prompt_log.md)
- [`verification_log.md`](verification_log.md)
- [`review_checklist.md`](review_checklist.md)

## Felhasználási területek

- Terméktervezés és interjúösszegzés.
- Architektúradöntések vázlatolása.
- Teszttervezés és acceptance-flow scaffold készítése.
- Dokumentációgenerálás és átszervezés.

## Adatmegosztási korlátozások

- Nincs secret a promptokban.
- Nincs közvetlen személyes adat a promptokban.
- A generált tartalmak merge előtt manuális review-n mennek át.

## AI output integrációs szabály

Minden AI-val támogatott kód- vagy dokumentumváltozásnál a minimum folyamat:

1. Az AI eredetét vagy a promptcsaládot rögzíteni kell a [`prompt_log.md`](prompt_log.md) fájlban.
2. A kritikus állításokat vagy döntéseket rögzíteni kell a [`verification_log.md`](verification_log.md) fájlban.
3. Merge előtt végig kell menni a [`review_checklist.md`](review_checklist.md) ellenőrzőlistán.
4. Kód esetén legalább a releváns lokális vagy CI quality gate-nek zöldnek kell lennie.

Megjegyzés:
- a promptnapló nem nyers prompt export, hanem auditálható, rövid összefoglaló
- ahol csak verziózott artefaktumból rekonstruálható a prompt, azt explicit módon jelölni kell

## Emberi tulajdonú kritikus döntések

1. Platformválasztás (Flutter + Firebase).
2. Deployment target stratégia és IaC irány.
3. Foglalási és készletfolyamat szemantikája.
4. Security rule ownership modell.
5. Scope határok MVP és stretch között.

## AI kockázatkezelés

- Hallucinációs kockázat: az AI javaslatokat kóddal és futtatható tesztekkel kell validálni.
- Biztonsági tanácsadási kockázat: rule/kód review-val és security tesztekkel kell ellenőrizni.
- Licenckockázat: meg kell tartani a függőségek/licencek láthatóságát, és CI audit evidence-t kell hozzáadni.
- Reprodukálhatósági kockázat: fenn kell tartani a prompt- és verifikációs naplókat artefakt hivatkozásokkal.

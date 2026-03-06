# AI manifest

## Eszközök és verziók (ismert)

1. ChatGPT
- Tervezéshez, elemzéshez és dokumentációírási támogatáshoz használva.

2. GitHub Copilot
- Kódolási támogatásra és boilerplate gyorsításra használva.

Evidence forrás:
- [`../../sprints/01/ai/usage_plan.yaml`](../../sprints/01/ai/usage_plan.yaml)
- [`../../sprints/01/ai/ai_log.jsonl`](../../sprints/01/ai/ai_log.jsonl)

## Felhasználási területek

- Terméktervezés és interjúösszegzés.
- Architektúradöntések vázlatolása.
- Teszttervezés és acceptance-flow scaffold készítése.
- Dokumentációgenerálás és átszervezés.

## Adatmegosztási korlátozások

- Nincs secret a promptokban.
- Nincs közvetlen személyes adat a promptokban.
- A generált tartalmak merge előtt manuális review-n mennek át.

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

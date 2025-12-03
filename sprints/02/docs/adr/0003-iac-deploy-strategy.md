# ADR 0003 – IaC / Deploy stratégia 

**Dátum:** 2025-11-10  
**Státusz:** Elfogadva

## Kontextus
Kell egy egyszerű, olcsó és ismételhető mód a környezetek (dev/staging/prod) létrehozására, a mobil build-ek automatizálására, valamint a Firebase erőforrások (Firestore szabályok, indexek, Functions, Storage) verziózott kiépítésére.

## Döntés
Választás:
- IaC: GCP + Firebase komponensek kezelése Terraformmal (google/google-beta providerek) ott, ahol támogatott; Firebase  CLI a Firestore szabályok/indexek és Functions deployra.
- Deploy/CI: GitHub Actions
    - Mobile: Flutter build (lint, test, build), artefaktok; opcionálisan fastlane a store-feltöltéshez később.
    - Backend: firebase deploy --only functions,firestore:rules,firestore:indexes,storage
    - Környezetek: külön Firebase projektek: nearpick-dev, nearpick-stg, nearpick-prod; GitHub OIDC → GCP Workload Identity Federation (secret-less).

- State: Terraform state GCS bucketben lockkal.
- Konfiguráció: .env/secrets a GitHub Actions-ban + Remote Config a kliens feature flagekhez.

## Alternatívák
- Csak Firebase CLI, IaC nélkül: egyszerű, de nehezebb visszakövethetőség/ismételhetőség.
- Pulumi: fejlett DX, de csapatban kevesebb rutin; plusz függőség.
- Teljesen manuális konzolos beállítás: gyors indulás, de hosszú távon hibás és nem auditálható.

## Következmények
Pozitív: reprodukálható környezetek, verziózott infrastruktúra, egykattintásos (pipeline) deploy, alacsony költség.
Negatív: Terraform támogatás Firebase-re részlegesen elérhető; vegyes megoldás (Terraform + Firebase CLI) karbantartást igényel.

## Megjegyzések / Guardrail-ek
- Prod deploy csak „manual approval”-lal fusson.
- Firestore Security Rules és indexek kötelezően PR-ban, review-val.
- CI min: lint + unit + smoke ≥95% pass legyen a merge feltétele.

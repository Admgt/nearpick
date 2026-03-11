# ADR 0002 - Firebase serverless backend

- Dátum: 2026-03-11
- Státusz: Elfogadva

## Kontextus

A piactér alkalmazás backendjének hitelesítést, adatkezelést, fájltárolást, push értesítést és legalább minimális szerveroldali eseménykezelést kell biztosítania. Az MVP és a szakdolgozati célok miatt olyan megoldásra volt szükség, amely alacsony üzemeltetési terhet jelent, mégis támogatja a valós idejű frissítéseket és a gyors demózhatóságot.

## Döntés

A backend szerver nélküli, Firebase alapú szolgáltatáskészletre épül:

- Firebase Auth az email/jelszó alapú azonosításhoz
- Cloud Firestore a termék-, felhasználó-, érdeklődés- és foglalási adatokhoz
- Firebase Storage a képfeltöltésekhez
- Cloud Functions az eseményvezérelt értesítési és kiegészítő backend logikához
- Firebase Cloud Messaging a push értesítésekhez

A rendszer nem külön REST vagy GraphQL API-réteggel indul, hanem a kliens több esetben közvetlenül a Firebase SDK-kon keresztül kommunikál.

## Következmények

Pozitív következmények:

- gyors MVP-fejlesztés alacsony DevOps költséggel
- natív integráció a hitelesítés, dokumentumalapú adatmodell és push értesítések között
- a bemutatóhoz és helyi validációhoz egyszerűbb környezeti setup

Negatív vagy vállalt tradeoffok:

- vendor lock-in a Firebase ökoszisztéma felé
- a kliens és a backend közti szerződés részben implicit a Firestore sémában és rule-okban
- nem minden üzleti invariáns kényszerül ki külön szerveroldali API-n keresztül

## Alternatívák

- Saját backend Cloud Run vagy App Engine alapon
  - előny: erősebb domain-kontroll és tisztább API-határ
  - hátrány: nagyobb üzemeltetési és fejlesztési költség
- Supabase vagy más BaaS
  - előny: SQL-alapú adatmodell és más ökoszisztéma
  - hátrány: a jelenlegi repo döntései és integrációi Firebase-re épülnek
- Teljesen natív, egyedi GCP komponensekből épített backend
  - előny: maximális rugalmasság
  - hátrány: túl nagy komplexitás az alkalmazás jelenlegi érettségi szintjéhez

## Verification

- Tesztek:
  - `mobile/nearpick/test/integration/auth/auth_workflow_test.dart`
  - `mobile/nearpick/test/integration/product/product_workflow_test.dart`
  - `mobile/nearpick/test/integration/reservation/reservation_workflow_test.dart`
  - `functions/test/security_helpers.test.js`
- CI evidence:
  - `.github/workflows/ci.yml`
  - `docs/04_quality/test_report.md`
- Dokumentációs artefaktok:
  - `docs/03_design/api.md`
  - `docs/03_design/data_model.md`
  - `docs/02_architecture/c4_context_container.md`
- Manuális demó validáció:
  - `docs/06_release/demo_environment.md`
  - `docs/06_release/demo_script.md`

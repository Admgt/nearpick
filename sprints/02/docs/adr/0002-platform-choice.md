# ADR 0002 – Platform döntés 

**Dátum:** 2025-11-10  
**Státusz:** Elfogadva

## Kontextus
Gyorsan szállítható, cross-platform mobil kliens és minimális backend üzemeltetés a cél. Fontos a valós idejű adatszinkron (termékek gyorsan megjelenjenek), egyszerű push értesítés, alacsony költség, és kis csapat által is fenntartható stack.

## Döntés
Választás: Flutter + Firebase
- Kliens: Flutter (egy kód, iOS/Android), Material/Adaptive UI.
- Backend: Firebase (Auth, Firestore, Storage, Cloud Functions, FCM).
Indoklás: gyors fejlesztés, valós idejű adatok, beépített push, jó fejlesztői élmény és ingyenes/olcsó belépő szint.

## Alternatívák
- React Native + Supabase: jó DX, de push/valós idejű ökoszisztéma integrációja több illesztést igényel.
- Kotlin Multiplatform + saját backend (GCP/AWS): erős natív élmény, de nagyobb idő- és üzemeltetési költség.
- Natív iOS + Android külön: maximális kontroll/perf, de dupla kód, lassabb szállítás.

## Következmények
Pozitív: gyors prototípus és MVP, valós idejű feed, egyszerű értesítések, kevés ops.
Negatív: vendor lock-in (Firebase), komplexebb adatlekérdezések Firestore-ban, későbbi migráció költséges lehet.
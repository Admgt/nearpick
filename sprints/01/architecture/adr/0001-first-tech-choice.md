# 0001: Kezdeti technológiai stack kiválasztása (NearPick)

- Dátum: 2025-10-30
- Státusz: Elfogadva

## Kontextus

A NearPick egy mobilalkalmazás, amely a közeli boltok nap végi, gyorsan romló termékeit jeleníti meg személyre szabottan.
Az MVP célja egy gyorsan fejleszthető, alacsony karbantartási igényű, valós idejű megoldás, kis fejlesztői csapattal.
Fontos szempontok: mobil-first élmény, értesítések, helyadat-kezelés, és egyszerű felhő-infrastruktúra.

## Döntés

A projekt technológiai alapja **Flutter + Firebase** lesz.
- **Flutter:** egy kódbázis Android és iOS platformra, gyors prototípus-készítéshez.
- **Firebase:** autentikáció, adatbázis (Firestore), tárhely, értesítések (FCM) és analitika integráltan.
Ez a kombináció támogatja a gyors MVP-fejlesztést, alacsony belépési küszöbbel és valós idejű frissítésekkel.

## Megfontolt alternatívák

- **React Native + Supabase:** jó JS-ökoszisztéma, de bonyolultabb értesítési pipeline.
- **Kotlin + Swift:** natív teljesítmény, de két külön kódbázis és hosszabb fejlesztési idő.
- **Ionic + Firebase:** webes megközelítés, de gyengébb natív élmény.

## Következmények

- Gyors fejlesztési ciklus és kevesebb DevOps-feladat.
- Valós idejű értesítések egyszerűen megvalósíthatók.
- Firebase-hez kötött architektúra (vendor lock-in) és Security Rules-ban szükséges tapasztalat.
- Skálázásnál később érdemes lehet külön backend réteget bevezetni.
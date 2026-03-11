# ADR 0007 - Konfiguráció- és secret-kezelés

- Dátum: 2026-03-11
- Státusz: Elfogadva

## Kontextus

A NearPick futtatásához Firebase projektkonfiguráció szükséges, ugyanakkor a repository nem tartalmazhat valódi secretet vagy production API kulcsot. A szakdolgozati demó reprodukálhatósága azt kívánja meg, hogy a bíráló külön demo Firebase projektet használjon, minta konfigurációs fájlok alapján.

## Döntés

A konfiguráció- és secret-kezelés elve a következő:

- a repository csak mintafájlokat és metaadatokat verziókezel
- a valódi konfiguráció lokális, gitignore-olt fájlokban él
- a kliens nem `.env` alapú runtime konfigurációt használ, hanem generált vagy lokálisan létrehozott Firebase config fájlokat
- a demóhoz külön Firebase projekt ajánlott, nem production projekt
- a CI fallbackként képes az example `firebase_options` fájlt használni a buildhez

## Következmények

Pozitív következmények:

- csökken a véletlen secret-kommit kockázata
- a demó környezet és a fejlesztői környezet elkülöníthető
- a reviewer számára egyértelműbb, milyen minimális setup kell a futtatáshoz

Negatív vagy vállalt tradeoffok:

- a lokális setup első lépésként kézi konfigurációs másolást igényel
- a teljes offline reprodukció jelenleg nem érhető el
- iOS esetén hiányzik a verziókezelt example plist útvonal

## Alternatívák

- Valódi kulcsok commitolása a repositoryba
  - előny: minimális setup
  - hátrány: elfogadhatatlan biztonsági kockázat
- Egyetlen közös fejlesztői Firebase projekt minden célra
  - előny: egyszerűbb adminisztráció
  - hátrány: a demo és a fejlesztés összemosódik
- Teljes runtime `.env` konfiguráció
  - előny: rugalmas környezeti paraméterezés
  - hátrány: a jelenlegi Flutter/Firebase setup nem erre épül

## Verification

- Tesztek:
  - a CI `Prepare Firebase options (CI fallback)` lépése a `.github/workflows/ci.yml` fájlban
  - `mobile/nearpick/test/widget/auth/login_screen_test.dart` közvetett validáció a belépési flow-ra
- CI evidence:
  - `.github/workflows/ci.yml`
  - `docs/06_release/release_checklist.md`
- Dokumentációs artefaktok:
  - `.env.example`
  - `README.md`
  - `docs/06_release/demo_environment.md`
- Manuális demó validáció:
  - `docs/06_release/demo_script.md`
  - `docs/06_release/demo_environment.md`

# Product Spec v0.2 

## Cél
A cél, hogy a kiskereskedők egyszerűen, mobilról feltölthessék a nap végén megmaradt termékeiket (kép + ár + lejárat), amelyek azonnal megjelennek a környékbeli felhasználók személyre szabott feedjében.
Ezzel a felhasználók időben értesülnek a közeli kedvezményekről, a boltok pedig csökkenthetik a pazarlást és növelhetik a bevételt.

## Scope (In/Out)
- In: 
    - Termékfeltöltés képpel, névvel, lejárati idővel és árkedvezménnyel
    - Feltöltött termékek azonnali megjelenése a vásárlói feedben
    - Egyszerű szűrés kategória és távolság alapján
    - Alap ajánlás (preferencia + közelség)
- Out: 
    - Online fizetés és számlázás
    - Statisztikai dashboard
    - Külön webes adminfelület; a később elkészült beépített admin/moderációs felület nem része ennek a v0.2 scope-nak
    - Kurír integráció

## User Story térkép
- US-01: Üres állapot megértése (nincs még termék, CTA-val)
- US-02: Új termék létrehozása (kép, ár, lejárat megadása)
- US-03: Terméklista megjelenítése (feltöltött tételek Firestore-ból)
- US-04: Szűrés kategória és távolság alapján
- US-05: Vásárlói feed frissülése új termék feltöltése után

## NFR (mérhető)
- NFR-1: Termékfeltöltés → feed frissülés TTFB < 2.0s (Firebase/Firestore valós idejű update)
- NFR-2: Build idő < 90s (CI/CD)
- NFR-3: Smoke tesztek pass rate ≥ 95% 10 futás alatt
- NFR-4: Kép feltöltés ≤ 5s mobilhálózaton (Firebase Storage mérés)

## Fő AC-k (Given–When–Then)
- AC1: Üres állapot látható, CTA-val
- AC2: Hiba esetén visszajelzés + retry
- AC3: Sikeres mentés után lista frissül és toast jelenik meg
- AC4: Szűrés alkalmazásakor csak releváns termékek jelennek meg
- AC5: Új termék feltöltése után a vásárlói feed automatikusan frissül

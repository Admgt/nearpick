# Architektúra áttekintés

![Rendszer architektúra](../assets/architecture/system_overview.png)

## Rendszer célja

A NearPick célja, hogy a közeli, időérzékeny kedvezményes termékeket gyorsan összekapcsolja a fogyasztókkal, miközben a kereskedők egyszerűen tudnak új ajánlatokat közzétenni és a foglalásokat kezelni. A rendszer elsődleges fókusza a gyors reagálású piactér-élmény, nem pedig egy nehéz, sokrétegű vállalati backend.

## Fő komponensek

- Flutter kliensalkalmazás
  - auth, consumer és merchant képernyők
  - ajánlási logika és kliensoldali szűrés
  - Firebase SDK integrációk
- Firebase Auth
  - email/jelszó azonosítás és session alapú hozzáférés
- Cloud Firestore
  - felhasználók, termékek, érdeklődések, foglalások és preferenciaadatok
- Firebase Storage
  - termékképek tárolása
- Cloud Functions
  - eseményvezérelt értesítési és kiegészítő backend logika
- Firebase Cloud Messaging
  - push értesítések
- GitHub Actions CI
  - lint, build és teszt futtatás

## Kliens-vezérelt architektúra indoklása

A jelenlegi rendszer kliens-vezérelt, mert az MVP és a szakdolgozati célok szempontjából ez adta a legjobb egyensúlyt a fejlesztési sebesség, a bemutathatóság és az alacsony üzemeltetési teher között. A Flutter kliens közvetlenül dolgozik a Firebase SDK-kkal, ezért a UI, a navigáció és több domain workflow gyorsan implementálható és jól dokumentálható. A választás tudatos tradeoff: a kliens vastagabb, miközben a biztonsági határokat a backend-oldali rule-oknak kell kikényszeríteniük.

## Serverless backend rationale

A Firebase serverless backend választás indoka az volt, hogy a hitelesítés, adattárolás, fájlkezelés és értesítés egyetlen integrált platformon belül legyen elérhető. Ez különösen előnyös olyan piactér esetén, ahol:

- a termékadatok valós időben frissülnek
- a push értesítések fontos felhasználói értéket adnak
- kis csapat vagy egyéni fejlesztés mellett is fenntartható üzemeltetési modell szükséges
- a szakdolgozati leadásban egyszerre kell működő prototípust és reprodukálható dokumentációt adni

## Adatáramlási narratíva

1. A felhasználó bejelentkezik a Flutter kliensen keresztül Firebase Auth segítségével.
2. A kliens a `users/{uid}` dokumentumból kiolvassa a szerepkört és a preferenciákat.
3. A fogyasztói nézet a Firestore aktív termékadataiból feedet épít, majd kliensoldalon szűri és pontozza az ajánlatokat.
4. A kereskedő új terméket hoz létre, amely a Firestore-ban és opcionálisan a Storage-ban jelenik meg.
5. Új termék létrehozásakor Cloud Function indulhat, amely értesítéseket küld a releváns fogyasztóknak.
6. Foglaláskor a kliens tranzakciós logikával csökkenti a készletet és létrehozza a foglalási rekordot.
7. A fogyasztó és a kereskedő a foglalási életciklust külön képernyőkön követi.

## Authorization modell röviden

Az authorization modell három pillérre épül:

- Firebase Auth alapú hitelesítés
- Firestore és Storage security rules alapú backend jogosultságkikényszerítés
- ownership és role mezők használata (`ownerId`, `merchantId`, `buyerId`, `role`)

A kliensoldali tiltások és gombállapotok UX célúak, de nem helyettesítik a backend kontrollt. A biztonsági modell lényege, hogy a felhasználó csak a saját adataihoz és a szerepkörének megfelelő erőforrásokhoz férjen hozzá.

## Deployment high-level modell

- Lokális fejlesztés és demó
  - Flutter kliens + külön demo Firebase projekt
  - opcionálisan Functions emulátor helyi logolási célra
- CI
  - GitHub Actions futtatja a format, analyze, build és test lépéseket
- Backend kiadási modell
  - Firebase alapú deployment szemlélet
  - szabályok, functions és kapcsolódó konfigurációk verziókezelten élnek a repositoryban

## Kapcsolódó dokumentumok

- `adr/00_index.md`
- `c4_context_container.md`
- `c4_component.md`
- `quality_attributes.md`
- `../03_design/api.md`
- `../03_design/data_model.md`

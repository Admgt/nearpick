# NearPick

Közeli, kedvezményes termékek gyors felfedezésére és lefoglalására készült Flutter + Firebase demóalkalmazás.

[![CI](https://github.com/SZTE-SZF/1-sprint-Admgt/actions/workflows/ci.yml/badge.svg)](https://github.com/SZTE-SZF/1-sprint-Admgt/actions/workflows/ci.yml)

## Rövid leírás

A NearPick arra a problémára ad választ, hogy a nap végén megmaradó, időérzékeny termékek ne vesszenek kárba, hanem a közelben lévő vásárlók gyorsan megtalálhassák és lefoglalhassák őket. A megoldás egy kétoldalú piactér: a kereskedő feltölti az ajánlatot, a fogyasztó kategória, hely és érdeklődés alapján böngészi, majd lefoglalja a kiválasztott terméket.

Kapcsolódó dokumentációs belépési pont: [`docs/00_index.md`](docs/00_index.md)

## Fő funkciók

- Email/jelszó alapú regisztráció és bejelentkezés fogyasztói vagy kereskedői szereppel.
- Közeli ajánlatok listázása, kategóriaszűrés és ajánlási rangsorolás.
- Termék részleteinek megnyitása, érdeklődés jelölése és foglalás indítása.
- Kereskedői termékfeltöltés képpel, árral, készlettel, lejárattal és helyadattal.
- Foglalások, kedvencek, profil és helybeállítás kezelése.

## Architektúra áttekintés

A repository központi eleme a `mobile/nearpick` Flutter kliens, amely közvetlenül a Firebase Auth, Firestore, Storage, Functions és Messaging szolgáltatásokat használja. A backend logika főként Firebase szabályokban és Cloud Functions kódban jelenik meg, a minőségi és szakdolgozati artefaktumok pedig a `docs/` könyvtárban vannak összegyűjtve.

## Technológiai stack

- Flutter 3.41.x, Dart 3.9.x
- Firebase Auth
- Cloud Firestore
- Firebase Cloud Functions
- Firebase Storage
- Firebase Cloud Messaging
- GitHub Actions CI
- Node.js 22 a `functions/` mappához

## Quickstart (Lokális demo mód)

### Mit jelent a demo mód?

A jelenlegi repository nem tartalmaz beépített Flutter oldali Firebase Emulator átkötést, ezért a leggyorsabb és reprodukálható bírálói futtatás külön demo Firebase projekttel történik. Ez nem production környezet: a bíráló csak egy elkülönített demo projektből generált konfigurációt használ.

### Előfeltételek

- `git`
- `Flutter SDK` és `Dart` CLI
- egy böngésző-alapú Flutter device, például `edge` vagy `chrome`
- opcionálisan Android Emulator vagy fizikai Android eszköz
- `Node.js 22` és `npm`
- opcionálisan `firebase-tools`, ha a Functions emulátort is el akarod indítani

### Konfigurációs áttekintés

A repo nem tartalmaz futásidejű secretet. A szükséges konfigurációs változók és minták:

- környezeti változók mintája: [`.env.example`](.env.example)
- FlutterFire minta: [`mobile/nearpick/lib/firebase_options.example.dart`](mobile/nearpick/lib/firebase_options.example.dart)
- Android minta: [`mobile/nearpick/android/app/google-services.example.json`](mobile/nearpick/android/app/google-services.example.json)
- web push minta: [`mobile/nearpick/web/firebase-messaging-sw.example.js`](mobile/nearpick/web/firebase-messaging-sw.example.js)

Az [`.env.example`](.env.example) a bírálói és fejlesztői konfigurációhoz szükséges fő Firebase azonosítókat sorolja fel:

- `FIREBASE_PROJECT_ID`: a külön demo Firebase projekt azonosítója
- `FIREBASE_WEB_API_KEY`: webes Flutter futtatáshoz használt API kulcs
- `FIREBASE_ANDROID_API_KEY`: Android klienshez tartozó API kulcs
- `FIREBASE_IOS_API_KEY`: iOS klienshez tartozó API kulcs

Fontos: az app futás közben nem `.env` fájlból olvas, hanem a lokálisan előállított FlutterFire/Firebase config fájlokból. Az `.env.example` a reviewer számára azt dokumentálja, milyen értékeket kell előkészíteni a lokális mintafájlok kitöltéséhez.

### Klónozás

```bash
git clone <repo-url>
cd 1-sprint-Admgt
```

### Telepítés

1. Hozz létre vagy használj egy külön demo Firebase projektet, ne production projektet.
2. Másold le a `mobile/nearpick/lib/firebase_options.example.dart` fájlt `mobile/nearpick/lib/firebase_options.dart` néven, majd töltsd ki a demo Firebase projektből kapott API kulcsokat.
3. Webes demóhoz opcionálisan másold le a `mobile/nearpick/web/firebase-messaging-sw.example.js` fájlt `mobile/nearpick/web/firebase-messaging-sw.js` néven, ha push értesítést is szeretnél kipróbálni.
4. Android demóhoz másold le a `mobile/nearpick/android/app/google-services.example.json` fájlt `mobile/nearpick/android/app/google-services.json` néven, majd írd bele a demo projekt Android API kulcsát.
5. Telepítsd a Flutter függőségeket:

```bash
cd mobile/nearpick
flutter pub get
```

### Minimális seed / demo adat

A reviewer gyors kipróbálásához a demo Firebase projektben legyen előkészítve:

- a két demo felhasználó
- legalább 3 aktív termék több kategóriában
- legalább 1 korábbi foglalás a foglalási részlet képernyőhöz

Részletes seed és demóelvárások: [`docs/06_release/demo_environment.md`](docs/06_release/demo_environment.md)

### Emulátor indítása

```bash
cd functions
npm ci
npm run serve
```

Ez a lépés csak a Cloud Functions emulátort indítja el, és helyi logolási segítséget ad. A Flutter kliens ettől még a demo Firebase projektre csatlakozik, ezért ez opcionális kiegészítés, nem teljes offline futtatás.

### Mobilalkalmazás indítása

Ajánlott, leggyorsabb bírálói útvonal webes Flutter device-on:

```bash
cd mobile/nearpick
flutter run -d edge --web-port 49904
```

Android alternatíva:

```bash
cd mobile/nearpick
flutter devices
flutter run -d <android-device-id>
```

### Elvárt kezdőképernyő

Sikeres indulás után a `NearPick - Bejelentkezés` képernyő jelenik meg. Bejelentkezés után a szerepkörtől függően vagy a `NearPick - Ajánlatok a közelben`, vagy a `NearPick - Kereskedő` kezdőképernyő nyílik meg.

## Demo hitelesítő adatok

Az alábbi seed felhasználókat a dedikált demo Firebase projektben kell előre létrehozni:

- Fogyasztó: `demo.user@nearpick.local` / `NearPick123!`
- Kereskedő: `demo.merchant@nearpick.local` / `NearPick123!`

Részletes környezeti elvárások: [`docs/06_release/demo_environment.md`](docs/06_release/demo_environment.md)

## Demo walkthrough

1. Indítsd el az alkalmazást, és ellenőrizd, hogy a bejelentkezési képernyő jelenik meg.
2. Jelentkezz be a `demo.merchant@nearpick.local` felhasználóval.
3. Nyisd meg az új termék képernyőt, adj meg nevet, kategóriát, árakat, készletet, lejáratot és mentsd a terméket.
4. Ellenőrizd, hogy a termék megjelenik a kereskedői listában.
5. Jelentkezz ki, majd lépj be a `demo.user@nearpick.local` felhasználóval.
6. A fogyasztói feedben szűrj kategóriára, nyisd meg a termékrészletet, majd foglald le a terméket.
7. Nyisd meg a foglalás részleteit, és ellenőrizd, hogy a státusz és az átvételi információk láthatók.

1 perces első kipróbálási útvonal:

1. Indítsd el az appot weben.
2. Jelentkezz be a `demo.merchant@nearpick.local` felhasználóval.
3. Hozz létre egy egyszerű terméket.
4. Jelentkezz át a `demo.user@nearpick.local` felhasználóra.
5. Nyisd meg a listát, majd foglalj le egy tételt.

## Projektstruktúra áttekintés

- `mobile/nearpick/`: Flutter kliensalkalmazás és tesztek.
- `functions/`: Firebase Cloud Functions kód és helyi emulátor script.
- `docs/`: termék-, architektúra-, minőség-, release- és AI dokumentáció.
- `scripts/`: lokális quality gate és segédszkriptek.
- `firebase.json`, `firestore.rules`, `storage.rules`: Firebase konfiguráció és szabályok.

## Tesztelési áttekintés

Gyors Flutter tesztfuttatás:

```bash
cd mobile/nearpick
flutter test
```

Célzott suite-ok:

```bash
cd mobile/nearpick
flutter test test/unit
flutter test test/widget
flutter test test/integration
```

Repo szintű quality gate:

```bash
bash scripts/test_all.sh
```

További evidence:

- Tesztstratégia: [`docs/04_quality/test_strategy.md`](docs/04_quality/test_strategy.md)
- Tesztriport: [`docs/04_quality/test_report.md`](docs/04_quality/test_report.md)
- Release checklist: [`docs/06_release/release_checklist.md`](docs/06_release/release_checklist.md)

## Hibakeresési gyorslista

- Hiányzó `firebase_options.dart`
  - Hozd létre a `mobile/nearpick/lib/firebase_options.example.dart` alapján.
- Webes auth hiba vagy nem engedélyezett localhost/domain
  - Ellenőrizd, hogy a demo Firebase projektben a használt lokális domain és port engedélyezett.
- Android `google-services` hiba
  - Ellenőrizd, hogy a `mobile/nearpick/android/app/google-services.json` létezik.
- Push vagy token perzisztálási hiba
  - Ellenőrizd a `users/{uid}/fcmTokens` alkollekciót és a Cloud Functions logokat.
- Functions emulátor nem indul
  - Ellenőrizd, hogy a `functions/` mappában lefut-e az `npm ci`.

## CI badge

Az aktuális workflow badge fent látható. Ha a repository URL vagy workflow útvonal változik, ezt a badge hivatkozást kell frissíteni.

## Licenc

A végleges LICENSE fájl még nincs rögzítve a repositoryban, ezért a publikációs/licencelési döntést a leadás előtt külön véglegesíteni kell. A harmadik féltől származó fő komponensek és függőségek áttekintése itt található: [`docs/05_security_ops/privacy_licensing.md`](docs/05_security_ops/privacy_licensing.md).

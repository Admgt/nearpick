# Demo környezet

## Demo Firebase projekt koncepció

A NearPick bírálói demója külön, izolált Firebase projektre épüljön, ne a fejlesztői vagy production környezetre. A cél az, hogy a reviewer ugyanazt a minimális adat- és jogosultsági készletet kapja meg, amely a fő felhasználói folyamatok bemutatásához kell, de ne legyen szüksége éles kulcsokra vagy éles adatokra.

Javasolt elv:

- külön projekt, például `nearpick-demo-<felev>`
- külön Auth felhasználók a fogyasztói, kereskedői és admin szerepekhez
- előre feltöltött legalább 3 aktív termék
- előre bekapcsolt Firestore, Auth, Storage és Functions szolgáltatások
- a repo-ba csak a mintafájlok kerüljenek, a valódi kulcsok lokális fájlokban maradjanak

## Demo felhasználók mintája

Az alábbi fiókok ajánlottak a bírálói csomaghoz:

- Fogyasztó: `demo.user@nearpick.local`
- Kereskedő: `demo.merchant@nearpick.local`
- Admin: `demo.admin@nearpick.local`, admin custom claimmel
- Javasolt demó jelszó mindhárom seed fiókhoz: `NearPick123!`

Az admin fióknál a jelszó mellett a Firebase Auth custom claim is szükséges. A projekt előkészítésekor futtasd:

```bash
cd functions
npm run admin:set -- --email demo.admin@nearpick.local
```

Az admin fiók jelszava a többi seed fiókéval egyezően `NearPick123!`, de a custom claimet külön be kell állítani.

Ajánlott seed adatok:

- legalább 1 pékáru, 1 tejtermék és 1 készétel kategóriájú aktív termék
- legalább 1 olyan termék, amelyhez tartozik kép
- legalább 1 olyan merchant profil, ahol `companyName` és `companyLocation` is ki van töltve
- legalább 1 korábbi `completed` foglalás a review flow demonstrálásához
- legalább 1 `cancelled` foglalás `pending` refund státusszal
- legalább 1 olyan aktív termék, ahol `quantityAvailable > 1`, hogy a mennyiségválasztó flow kipróbálható legyen
- legalább 1 előre kijelölt teszttermék admin elrejtés/visszaállítás bemutatására
- legalább 1 teszt merchant, akinek admin üzenet küldhető anélkül, hogy valós felhasználói adat sérülne

## Emulátor ajánlás

A repository jelenlegi állapotában a leggyorsabb bírálói útvonal továbbra is a külön demo Firebase projekt használata, de a Flutter kliens már opcionálisan át tud kötni Firebase Emulator Suite-ra `--dart-define=USE_FIREBASE_EMULATORS=true` kapcsolóval. Teljes helyi útvonal:

```bash
firebase emulators:start --only auth,firestore,functions,storage,hosting
cd mobile/nearpick
flutter run -d edge --web-port 49914 --dart-define=USE_FIREBASE_EMULATORS=true
```

Ha csak háttérlogokra van szükség, marad a szűkebb Functions emulátor útvonal:

```bash
cd functions
npm ci
npm run serve
```

Ez a lépés hasznos akkor, ha a reviewer vagy az oktató helyi logokat akar látni, de nem váltja ki a demo Firebase projektet.

## Mit teszteljen a reviewer?

- Bejelentkezés és szerepkör alapú beléptetés.
- Kereskedői profiloldal megnyitása, céghely ellenőrzése és új termék létrehozása / szerkesztése.
- Fogyasztói ajánlatlista betöltése, kategóriaszűrés és helyalapú böngészés.
- Termékrészlet megnyitása és foglalás indítása akár több darabra.
- Foglalás részletképernyő megnyitása pickup code / QR token megjelenítéssel.
- Completed demo foglalás review részének megmutatása.
- Cancelled demo foglalás refund státuszának megmutatása.
- Alapvető hibaállapotok, például kötelező mező hiánya vagy sold-out / insufficient quantity üzenet.
- Admin dashboard megnyitása admin claimmel.
- Felhasználó státuszkezelés előre kijelölt tesztfiókon.
- Termék elrejtés/visszaállítás előre kijelölt tesztterméken.
- Admin üzenet küldése kereskedőnek, majd merchant dashboardon az üzenet olvasottra jelölése.

## Ismert korlátok

- A teljes lokális demóhoz a reviewernek külön el kell indítania az emulátorokat; a seed adatokat ez az útvonal sem tölti be automatikusan.
- A `functions/package.json` jelenleg csak Functions emulátort indít, nem teljes Auth/Firestore/Storage emulátorkészletet.
- A dokumentáció seed felhasználókat és seed adatokat ír elő, de ezek fenntartása a demo Firebase projekt adminisztrációjának része.
- Az admin demo fiók csak akkor fog admin felületre routolni, ha a custom claim beállítása után a kliens friss ID tokent kap; ha nem jelenik meg az admin felület, jelentkezz ki és be újra.

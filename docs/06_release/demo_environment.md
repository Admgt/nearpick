# Demo környezet

## Demo Firebase projekt koncepció

A NearPick bírálói demója külön, izolált Firebase projektre épüljön, ne a fejlesztői vagy production környezetre. A cél az, hogy a reviewer ugyanazt a minimális adat- és jogosultsági készletet kapja meg, amely a fő felhasználói folyamatok bemutatásához kell, de ne legyen szüksége éles kulcsokra vagy éles adatokra.

Javasolt elv:

- külön projekt, például `nearpick-demo-<felev>`
- külön Auth felhasználók a fogyasztói és kereskedői szerepekhez
- előre feltöltött legalább 3 aktív termék
- előre bekapcsolt Firestore, Auth, Storage és Functions szolgáltatások
- a repo-ba csak a mintafájlok kerüljenek, a valódi kulcsok lokális fájlokban maradjanak

## Demo felhasználók mintája

Az alábbi fiókok ajánlottak a bírálói csomaghoz:

- Fogyasztó: `demo.user@nearpick.local`
- Kereskedő: `demo.merchant@nearpick.local`
- Javasolt jelszó mindkét fiókhoz: `NearPick123!`

Ajánlott seed adatok:

- legalább 1 pékáru, 1 tejtermék és 1 készétel kategóriájú aktív termék
- legalább 1 olyan termék, amelyhez tartozik kép
- legalább 1 korábbi foglalás a foglalási részletképernyő demonstrálásához

## Emulátor ajánlás

A repository jelenlegi állapotában a leggyorsabb bírálói útvonal továbbra is a külön demo Firebase projekt használata, de a Flutter kliens már opcionálisan át tud kötni Firebase Emulator Suite-ra `--dart-define=USE_FIREBASE_EMULATORS=true` kapcsolóval. Teljes helyi útvonal:

```bash
firebase emulators:start --only auth,firestore,functions,storage,hosting
cd mobile/nearpick
flutter run -d edge --web-port 49904 --dart-define=USE_FIREBASE_EMULATORS=true
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
- Kereskedői új termék létrehozása és annak megjelenése a saját listában.
- Fogyasztói ajánlatlista betöltése és kategóriaszűrés.
- Termékrészlet megnyitása és foglalás indítása.
- Foglalás részletképernyő megnyitása.
- Alapvető hibaállapotok, például kötelező mező hiánya vagy sold-out üzenet.

## Ismert korlátok

- A teljes lokális demóhoz a reviewernek külön el kell indítania az emulátorokat; a seed adatokat ez az útvonal sem tölti be automatikusan.
- A `functions/package.json` jelenleg csak Functions emulátort indít, nem teljes Auth/Firestore/Storage emulátorkészletet.
- A dokumentáció seed felhasználókat és seed adatokat ír elő, de ezek fenntartása a demo Firebase projekt adminisztrációjának része.

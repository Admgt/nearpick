# NearPick

[![CI](https://github.com/SZTE-SZF/1-sprint-Admgt/actions/workflows/ci.yml/badge.svg)](https://github.com/SZTE-SZF/1-sprint-Admgt/actions/workflows/ci.yml)

NearPick egy Flutter + Firebase alkalmazás, amely közeli, kedvezményes termékek megtalálását és lefoglalását támogatja vásárlói és kereskedői nézetekkel.

## Gyors hivatkozások

- Dokumentációs index: [`docs/00_index.md`](docs/00_index.md)
- Mobil app README: [`mobile/nearpick/README.md`](mobile/nearpick/README.md)
- Tesztstratégia: [`docs/04_quality/test_strategy.md`](docs/04_quality/test_strategy.md)
- Quality gate script: [`scripts/test_all.sh`](scripts/test_all.sh)

## Repository felépítése

- `mobile/nearpick/`: Flutter kliensalkalmazás.
- `functions/`: Firebase Cloud Functions kód.
- `docs/`: szakdolgozati és termékminőségi dokumentáció.
- `scripts/`: lokális quality gate és segédscript.
- `firebase.json`, `firestore.rules`, `storage.rules`: Firebase backend konfiguráció és szabályok.

## Előfeltételek

Az alábbi eszközök kellenek a repo jelenlegi állapota alapján:

- `git`
- `Flutter SDK` és a hozzá tartozó `Dart` CLI
- `Node.js 22` és `npm` a `functions/` mappához
- `Java 11` és Android SDK, ha Androidra futtatnád a Flutter appot
- `bash`-kompatibilis shell, ha a `scripts/test_all.sh` quality gate-et akarod futtatni
- egy böngésző-web device (`edge` vagy más, amit a `flutter devices` listáz)
- Firebase projekt-hozzáférés, ha a valódi backenddel futtatod az appot
- `firebase-tools` csak akkor kell, ha Functions emulátort vagy deployt futtatsz

Megjegyzés:

- A CI jelenleg `Flutter 3.41.3` és `Node 22` környezetet használ.
- A Flutter app alapértelmezésben valódi Firebase projektre csatlakozik; a repo-ban nem látszik külön emulator-átkapcsolási logika.

## Firebase config és lokális secret fájlok

A repo-ban az alábbi fájlok sablonként vagy metaadatként verziókezeltek:

- `.env.example`
- `mobile/nearpick/firebase.json`
- `mobile/nearpick/lib/firebase_options.example.dart`
- `mobile/nearpick/android/app/google-services.example.json`
- `mobile/nearpick/web/firebase-messaging-sw.example.js`

A lokális, nem commitolandó fájlok:

- `mobile/nearpick/lib/firebase_options.dart`
- `mobile/nearpick/android/app/google-services.json`
- `mobile/nearpick/web/firebase-messaging-sw.js`

Fontos:

- Az app nem `.env` fájlból olvas futásidőben. Az `.env.example` itt referencia arra, milyen Firebase adatokra lesz szükséged.
- A kötelező lokális lépés az example fájlokból a valódi, gitignore-olt config fájlok előállítása.

Javasolt minimál setup:

1. Másold le `mobile/nearpick/lib/firebase_options.example.dart` tartalmát `mobile/nearpick/lib/firebase_options.dart` néven.
2. Cseréld ki a `<FIREBASE_API_KEY>` placeholdereket a saját Firebase projekted kulcsaira.
3. Android futtatáshoz másold le `mobile/nearpick/android/app/google-services.example.json` tartalmát `mobile/nearpick/android/app/google-services.json` néven, és töltsd ki a placeholder API key-t.
4. Ha web push értesítést is szeretnél kipróbálni, másold le `mobile/nearpick/web/firebase-messaging-sw.example.js` tartalmát `mobile/nearpick/web/firebase-messaging-sw.js` néven, és töltsd ki a webes API key-t.

Assumption / TODO:

- A repo tartalmaz FlutterFire metaadatot (`mobile/nearpick/firebase.json`), de nincs külön dokumentált, csapatszintű regenerálási parancs a config fájlokhoz. Ezt később érdemes szabványosítani.

## Quickstart web

Projekt gyökérből:

```bash
cd mobile/nearpick
flutter pub get
flutter run -d edge --web-port 49904
```

Miért fix a port:

- A webes lokális futtatásnál a `49904` port már szerepel a repo-ban, és a tesztek is erre a localhost refererre utalnak. Ha más portot használsz, a Firebase Auth webes domain-listáját is igazítanod kell.

Előtte ellenőrizd:

- létrejött a `lib/firebase_options.dart`
- ha web push kell, létrejött a `web/firebase-messaging-sw.js`

## Quickstart mobilra

### Android

Projekt gyökérből:

```bash
cd mobile/nearpick
flutter pub get
flutter devices
flutter run -d <android-device-id>
```

Androidhoz szükséges plusz lokális fájl:

- `mobile/nearpick/android/app/google-services.json`

### iOS

Assumption / TODO:

- A repo tartalmaz iOS kódot és iOS `FirebaseOptions` mintát, de nincs verziókezelt `GoogleService-Info.plist.example`. Emiatt az iOS lokális setuphoz projekt-specifikus plist fájlt kell beszerezni a Firebase projektből, mielőtt `flutter run -d ios` használható lenne.

## Functions helyi futtatása

Ez opcionális, a standard app quickstartnak nem része.

```bash
cd functions
npm ci
npm run serve
```

Megjegyzés:

- A `functions/` mappában csak Functions emulátor script látszik.
- A klienskódban nincs dokumentált Firebase emulator bekötés, ezért az app normál gyorsindítása nem erre a helyi emulátorra épít.

## Tesztek és quality gate

Gyors Flutter teszt:

```bash
cd mobile/nearpick
flutter test
```

Teljes repo-szintű quality gate:

```bash
bash scripts/test_all.sh
```

A script jelenleg ezeket futtatja:

- `flutter pub get`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test --machine | tojunit`
- opcionálisan `flutter test integration_test`, ha ott valódi tesztfájl is van

## Mi kerül gitbe és mi nem

Verziókezelve marad:

- dokumentációk
- `firebase.json`, `.firebaserc`, `firestore.rules`, `storage.rules`
- az `*.example` Firebase config fájlok
- `mobile/nearpick/firebase.json` FlutterFire metaadat

Ne commitold:

- valódi Firebase kulcsokkal kitöltött lokális config fájlokat
- lokális `.env` variánsokat
- build outputokat és lokális teszt riportokat
- `node_modules` és Firebase debug logokat

## Gyakori hibák / troubleshooting

- `Target of URI doesn't exist: 'firebase_options.dart'`
  - Hiányzik a `mobile/nearpick/lib/firebase_options.dart`. Hozd létre az example fájlból.
- Web login/auth hiba localhost referer miatt
  - Futtasd a web appot a dokumentált `49904` porton, vagy engedélyezd a saját localhost domainedet a Firebase Auth beállításokban.
- Android build hiba `google-services.json` miatt
  - Ellenőrizd, hogy létrehoztad-e a `mobile/nearpick/android/app/google-services.json` fájlt.
- `npm run serve` hiba a Functions mappában
  - Telepítsd a `firebase-tools` CLI-t, és jelentkezz be a Firebase projektbe.

## Kapcsolódó fájlok

- Gyökér config referencia: [`.env.example`](.env.example)
- FlutterFire metaadat: [`mobile/nearpick/firebase.json`](mobile/nearpick/firebase.json)
- Web service worker minta: [`mobile/nearpick/web/firebase-messaging-sw.example.js`](mobile/nearpick/web/firebase-messaging-sw.example.js)
- Android config minta: [`mobile/nearpick/android/app/google-services.example.json`](mobile/nearpick/android/app/google-services.example.json)

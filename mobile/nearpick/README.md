# NearPick Flutter app

Ez a mappa tartalmazza a NearPick Flutter kliensalkalmazását. A kliens Firebase Auth, Firestore, Storage és Firebase Messaging szolgáltatásokat használ vásárlói és kereskedői flow-khoz.

## Mire való ez az app

- vásárlói oldalon közeli ajánlatok böngészése, szűrése és foglalása
- kereskedői oldalon termékek feltöltése és foglalások kezelése
- push értesítések új ajánlatokra

## Előfeltételek

- Flutter SDK
- Dart CLI
- web futtatáshoz egy támogatott böngésző
- Android futtatáshoz Android SDK + emulator vagy fizikai eszköz
- Node nem kell az app indulásához, csak a repo `functions/` mappájához

A repo és a CI alapján fontos verziók:

- Flutter: a CI `3.41.3`-at használja
- Node: a `functions/` mappához `22`
- Java: Android buildhez `11`

## Függőségek telepítése

```bash
flutter pub get
```

## Firebase konfiguráció

Az app indulásához legalább ez a fájl kell:

- `lib/firebase_options.dart`

Platformfüggő további fájlok:

- Android: `android/app/google-services.json`
- Web push háttérértesítéshez: `web/firebase-messaging-sw.js`

A repo-ban ezekhez van sablon:

- `lib/firebase_options.example.dart`
- `android/app/google-services.example.json`
- `web/firebase-messaging-sw.example.js`

Javasolt repo-alapú lokális setup:

1. Másold le `lib/firebase_options.example.dart` tartalmát `lib/firebase_options.dart` néven.
2. Cseréld ki a `<FIREBASE_API_KEY>` placeholdereket a saját Firebase projekted adataira.
3. Ha Androidon futtatod az appot, másold le `android/app/google-services.example.json` tartalmát `android/app/google-services.json` néven, és töltsd ki a placeholder API key-t.
4. Ha web push értesítést is tesztelnél, másold le `web/firebase-messaging-sw.example.js` tartalmát `web/firebase-messaging-sw.js` néven, és töltsd ki a webes API key-t.
5. Web push tokenregisztrációhoz indításkor add át a VAPID public key-t `--dart-define=FIREBASE_WEB_VAPID_KEY=<your-web-push-vapid-public-key>` formában.

Fontos:

- Ezek a valódi config fájlok gitignore-olva vannak.
- Az app nem `.env` fájlból olvas futásidőben; a Firebase konfigurációt a fenti generált/lokális fájlokból veszi, a web push VAPID kulcsot pedig opcionálisan `--dart-define` paraméterből.
- A verziókezelt `firebase.json` ebben a mappában FlutterFire metaadat, nem helyettesíti a lokális `firebase_options.dart` fájlt.
- A mellékelt példa `firebase_options` jelenleg web, Android és iOS platformra tartalmaz beállítást; macOS, Windows és Linux nincs hozzá konfigurálva.

Megjegyzés:

- A repo nem dokumentál külön csapat-standard FlutterFire regenerálási parancsot. A biztos, auditálható út az example fájlokból való lokális előállítás.

## Futtatás weben

```bash
flutter run -d edge --web-port 49904
```

Web push teszthez:

```bash
flutter run -d edge --web-port 49904 --dart-define=FIREBASE_WEB_VAPID_KEY=<your-web-push-vapid-public-key>
```

Megjegyzés:

- A fix `49904` port nem véletlen; a repo több ponton erre a lokális webes futásra hivatkozik.
- Ha más portot használsz, a Firebase Auth webes domain beállítását is ellenőrizned kell.

## Futtatás Androidon

```bash
flutter devices
flutter run -d <android-device-id>
```

Futtatás előtt ellenőrizd:

- `lib/firebase_options.dart` létezik
- `android/app/google-services.json` létezik

## Futtatás iOS-en

Korlát:

- A projektben van iOS target, de nincs verziókezelt `GoogleService-Info.plist.example`.
- Emiatt az iOS futtatáshoz egy projekt-specifikus Firebase plist fájlt kell kézzel hozzáadni az `ios/Runner/` környezethez.

## Tesztek futtatása

Összes Flutter teszt:

```bash
flutter test
```

Célzott futtatás:

```bash
flutter test test/unit
flutter test test/integration
flutter test test/widget
```

Repo gyökérből teljes quality gate:

```bash
bash scripts/test_all.sh
```

## Fontos megjegyzések a generált config fájlokról

- `lib/firebase_options.dart`: szükséges a `Firebase.initializeApp(...)` híváshoz.
- `android/app/google-services.json`: Android buildhez szükséges.
- `web/firebase-messaging-sw.js`: webes háttérértesítésekhez szükséges.
- Ezeket ne commitold.

## Rövid hibakeresési lista

- Hiányzó `firebase_options.dart`
  - Hozd létre az example fájlból.
- Webes auth vagy messaging hiba
  - Ellenőrizd a `49904` portot és a webes Firebase configot.
- Android `google-services` hiba
  - Ellenőrizd, hogy a `google-services.json` a helyén van-e.

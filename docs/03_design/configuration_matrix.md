# Konfigurációs mátrix

Ez a dokumentum a NearPick jelenlegi konfigurációs modelljét foglalja össze környezet, fájl és futásidejű flag szerint.

## Alapelv

- A repository nem tartalmaz valódi futásidejű secretet.
- A reviewer és a fejlesztő külön demo Firebase projektet vagy opcionálisan emulátorokat használ.
- A Flutter kliens nem `.env` fájlból olvas futás közben, hanem lokálisan előállított Firebase konfigurációs fájlokból és opcionális `--dart-define` flag-ekből.

## Környezeti mátrix

| Környezet | Firebase backend | Kötelező lokális fájlok | Opcionális flag-ek |
|---|---|---|---|
| Demo Firebase projekt | valódi, elkülönített demo projekt | `lib/firebase_options.dart` | `FIREBASE_WEB_VAPID_KEY` |
| Lokális emulátor mód | Firebase Emulator Suite | `lib/firebase_options.dart` | `USE_FIREBASE_EMULATORS`, `FIREBASE_EMULATOR_HOST`, `FIREBASE_WEB_VAPID_KEY` |
| Android lokális futás | demo projekt vagy emulátor | `android/app/google-services.json`, `lib/firebase_options.dart` | `USE_FIREBASE_EMULATORS` |
| iOS lokális futás | demo projekt | `ios/Runner/GoogleService-Info.plist`, `lib/firebase_options.dart` | opcionális VAPID nem releváns |

## Verziózott minták és lokális párjaik

| Verziózott minta | Lokális futásidejű pár | Cél |
|---|---|---|
| `.env.example` | nincs közvetlen runtime pár | reviewer és fejlesztői előkészítő adatlista |
| `mobile/nearpick/lib/firebase_options.example.dart` | `mobile/nearpick/lib/firebase_options.dart` | FlutterFire projektkonfiguráció |
| `mobile/nearpick/android/app/google-services.example.json` | `mobile/nearpick/android/app/google-services.json` | Android Firebase klienskonfiguráció |
| `mobile/nearpick/ios/Runner/GoogleService-Info.plist.example` | `mobile/nearpick/ios/Runner/GoogleService-Info.plist` | iOS Firebase klienskonfiguráció |
| `mobile/nearpick/web/firebase-messaging-sw.example.js` | `mobile/nearpick/web/firebase-messaging-sw.js` | web push service worker |

## Fő futásidejű flag-ek

| Flag | Jelentés | Mikor használd |
|---|---|---|
| `FIREBASE_WEB_VAPID_KEY` | web push public key | ha web push értesítést is tesztelsz |
| `USE_FIREBASE_EMULATORS=true` | emulátoros átkötés | ha lokálisan az emulátorokra akarsz csatlakozni |
| `FIREBASE_EMULATOR_HOST=127.0.0.1` | egyedi emulator host | ha a default host nem megfelelő |

## Port- és útvonal-konvenciók

- Ajánlott helyi Flutter web port: `49904`
- Emulátor portok: a verziókezelt [`../../firebase.json`](../../firebase.json) fájl rögzíti
- Ajánlott emulátor indulási parancs:

```bash
firebase emulators:start --only auth,firestore,functions,storage,hosting
```

## Gyors validációs lista

1. A szükséges lokális config fájlok léteznek.
2. A helyi webes futás `49904` porton indul.
3. Emulátoros módban a `USE_FIREBASE_EMULATORS` flag át van adva.
4. A valódi lokális config fájlok nincsenek verziókezelve.

## Kapcsolódó artefaktumok

- [`api.md`](api.md)
- [`../../README.md`](../../README.md)
- [`../06_release/demo_environment.md`](../06_release/demo_environment.md)
- [`../05_security_ops/deploy_runbook.md`](../05_security_ops/deploy_runbook.md)
- [`../02_architecture/adr/0007_configuration_and_secret_management.md`](../02_architecture/adr/0007_configuration_and_secret_management.md)

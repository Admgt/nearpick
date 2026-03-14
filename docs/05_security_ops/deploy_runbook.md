# Telepítési runbook

## Környezeti modell

- Lokális: fejlesztői gép Flutter + Firebase konfigurációval.
- CI: GitHub Actions minőségkapuk és build/test futtatás.
- Staging/Prod: a célmodell definiálva van, de a teljes, lépcsőzetes rollout még részleges.

Hivatkozások:
- [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml)
- [`../../sprints/02/deploy/target.yaml`](../../sprints/02/deploy/target.yaml)
- [`../../sprints/02/docs/adr/0003-iac-deploy-strategy.md`](../../sprints/02/docs/adr/0003-iac-deploy-strategy.md)

## Telepítési lépések (jelenlegi gyakorlati útvonal)

1. Validáld a minőségkapukat lokálisan vagy CI-ban.
- Format, analyze, build, tesztek.

2. Ellenőrizd, hogy a Firebase config és rule fájlok naprakészek.
- `firebase.json`, `firestore.rules`, `storage.rules`.

3. Telepítsd a backend komponenseket.
- A functions és a rule-ok telepítése Firebase CLI útvonalon keresztül történik.

4. Telepítsd a webes artifactot vagy a cél hosting csatornát.
- A Flutter web build kimenetére és a hosting beállításra építve.

5. Validáld a healthcheck endpointot.
- A deploy után ellenőrizd, hogy a `healthcheck` HTTP function `200` vagy várt degradált státusszal válaszol, és a `checks.firestore` mező értelmes.

## Konfiguráció és secretek

- Futásidejű konfigurációs sablonok:
  - [`../../.env.example`](../../.env.example)
  - [`../../mobile/nearpick/lib/firebase_options.example.dart`](../../mobile/nearpick/lib/firebase_options.example.dart)
  - [`../../mobile/nearpick/android/app/google-services.example.json`](../../mobile/nearpick/android/app/google-services.example.json)
  - [`../../mobile/nearpick/web/firebase-messaging-sw.example.js`](../../mobile/nearpick/web/firebase-messaging-sw.example.js)

- A szükséges lokális secret fájlok ki vannak zárva a Flutter `.gitignore` segítségével.

## Rollback terv

1. Állítsd le a további rolloutot és azonosítsd az utolsó ismerten jó commitot/taget.
2. Telepítsd újra az utolsó ismerten jó rules/functions/build artifact verziót.
3. Validáld a `healthcheck` endpointot és a fő flow-kat (login, terméklista, foglalási útvonal).
4. Rögzítsd az incidenst és a követő javítási feladatot.

## Release verziózás

- Előnyben részesített: git tag vagy deploy eseményhez kötött commit SHA.
- Jelenlegi gyakorlati minimum: commit SHA + CI futás URL release megjegyzésekben/logban.

## Incidensforgatókönyvek

### A forgatókönyv: a foglalási útvonal ismétlődő hibákat ad

- Tünetek: a felhasználók nem tudnak foglalni; gyakori konfliktus/hiba snackbarok.
- Gyors diagnózis:
  - Firestore termékmennyiségek és állapotátmenetek ellenőrzése
  - foglalási írások és rule elutasítások ellenőrzése
  - a reservation service és rule-ok legutóbbi módosításainak átnézése
- Ideiglenes mitigáció:
  - a hibás release útvonal letiltása vagy az utolsó változás visszaforgatása
- Végleges javítási irány:
  - regressziós tesztek hozzáadása vagy frissítése konfliktus/auth edge case-ekre

### B forgatókönyv: az értesítések nem érkeznek meg

- Tünetek: új termékek létrejönnek, de a fogyasztók nem kapnak push értesítést.
- Gyors diagnózis:
  - function logok a trigger futásához
  - tokenek elérhetősége a `users/{uid}/fcmTokens` alatt
  - user preferencia/kategória egyezési útvonal ellenőrzése
- Ideiglenes mitigáció:
  - tokenek manuális ellenőrzése és újraregisztrálása az érintett usereknél
- Végleges javítási irány:
  - trigger contract tesztek és token-életciklus ellenőrzések hozzáadása

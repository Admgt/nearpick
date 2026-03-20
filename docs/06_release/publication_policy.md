# Publikációs policy

## Cél

Ez a dokumentum rögzíti, hogy a NearPick repositoryból mi publikálható nyilvánosan, mi marad kizárva, és milyen licenc alá tartozik a forráskód.

## Repository licenc

- A repositoryban verziókezelt saját forráskód és dokumentáció MIT licenc alatt érhető el: [`../../LICENSE`](../../LICENSE).
- A MIT licenc csak a repository saját tartalmára vonatkozik, nem írja felül a harmadik féltől származó csomagok, szolgáltatások és márkanevek saját feltételeit.

## Nyilvánosan publikálható tartalom

- A Flutter kliens és a Cloud Functions saját forráskódja.
- A `docs/` alatti szakdolgozati, architektúra-, minőségi és release dokumentáció.
- A tesztek, CI workflow-k és reprodukálhatóságot segítő script-ek.
- A mintakonfigurációk és példafájlok, például [`.env.example`](../../.env.example), [`firebase_options.example.dart`](../../mobile/nearpick/lib/firebase_options.example.dart), [`google-services.example.json`](../../mobile/nearpick/android/app/google-services.example.json) és [`firebase-messaging-sw.example.js`](../../mobile/nearpick/web/firebase-messaging-sw.example.js).

## Nem publikálható tartalom

- Secret, API kulcs, service account kulcs, `.env` és bármely környezetspecifikus hitelesítő adat.
- A valódi futtatási konfigurációk, például `firebase_options.dart`, `google-services.json` és `firebase-messaging-sw.js`.
- Valós vagy demo felhasználói adatok, exportok, adatbázis dumpok, logok és backupok.
- Olyan screenshot vagy bizonyíték, amely személyes adatot, tokent vagy érzékeny operatív információt fedne fel.

## Csomagpublikációs szabály

- A Flutter kliens nem publikus package-ként kerül terjesztésre; ezt a [`../../mobile/nearpick/pubspec.yaml`](../../mobile/nearpick/pubspec.yaml) `publish_to: 'none'` beállítása is rögzíti.
- A Cloud Functions csomag nem npm package-ként publikálandó; ezt a [`../../functions/package.json`](../../functions/package.json) `private: true` beállítása jelzi.
- A hivatalos publikációs forma a Git repository és a hozzá tartozó dokumentációs csomag, nem csomagregiszterbe feltöltött library.

## Publikálás előtti minimum ellenőrzés

- Secret scan fusson le a repositoryn.
- Csak a mintafájlok legyenek verziókezelve, a valódi környezeti konfiguráció ne.
- A `LICENSE` fájl és ez a policy maradjon a release csomag része.
- Harmadik féltől származó komponensekre továbbra is az eredeti licencek vonatkozzanak.

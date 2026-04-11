# Scope contract

## MVP sztorik

1. User registration and login with role routing
- A fogyasztó és a kereskedő be tud jelentkezni, jelszót tud visszaállítani, és a megfelelő kezdőképernyőre kerül.

2. Merchant creates and edits a product with key fields
- A kereskedő létre tud hozni és az első foglalásig szerkeszteni tud terméket névvel, kategóriával, árazással, mennyiséggel, lejárattal, átvételi idősávval, opcionális képpel és céghelyből örökölt helyadattal.

3. Consumer feed, map and filtering
- A fogyasztó látja az aktív termékeket, kategóriára szűrni tud, és a saját helye vagy előre definiált város alapján releváns ajánlatokat kap.

4. Consumer reservation flow
- A fogyasztó le tud foglalni egy vagy több elérhető darabot, el tud jutni a foglalás részleteihez, le tudja mondani a foglalást, és refund igényt tud jelezni.

5. Merchant reservation completion and aftercare
- A kereskedő QR vagy pickup kód alapján teljesíteni tud egy lefoglalt rendelést, refund státuszt tud kezelni, és a completed foglalás után review érkezhet.

6. Account and profile management
- A fogyasztó account oldalon szerkesztheti a display nevet, kedvenc kategóriákat és helybeállításokat, a kereskedő pedig a display nevet, cégnevet és céghelyet.

7. Merchant insights and reporting
- A kereskedő dashboardon látja a fő metrikákat, pricing recommendation lefedettséget, review összesítőt, és CSV exportot tud indítani.

8. Admin monitoring and moderation
- Az admin claimmel rendelkező felhasználó admin kezdőképernyőre kerül, látja a rendszer fő felhasználói, termék- és foglalási mutatóit, keresni tud a felhasználók/kereskedők/vásárlók/termékek/foglalások között, fiókstátuszt tud kezelni, terméket tud elrejteni/visszaállítani/archiválni, és admin üzenetet tud küldeni kereskedőnek.

Sztori hivatkozások:
- [`sprints/02/docs/stories/user_stories.md`](../../sprints/02/docs/stories/user_stories.md)
- [`sprints/02/docs/spec/product_spec_v0.2.md`](../../sprints/02/docs/spec/product_spec_v0.2.md)

## Elfogadási kritériumok (sztori szintű összefoglaló)

1. Auth és role routing
- Adott egy érvényes user role a `users/{uid}` dokumentumban, amikor az app elindul, akkor a szerephez tartozó képernyő nyílik meg.
- Adott egy érvényes email-cím, amikor a felhasználó password resetet kér, akkor visszaállító email küldése indul.

2. Terméklétrehozás és szerkesztés
- Adottak az érvényes bemenetek és a mentett céghely, amikor a kereskedő ment, akkor a termék megjelenik a kereskedő listájában és láthatóvá válik az aktív feedben.
- Adottak az érvénytelen kötelező bemenetek, amikor a mentés gombra kattint, akkor a termék nem jön létre, és a felhasználó validációs visszajelzést kap.
- Adott, hogy a terméken még nincs foglalás, amikor a kereskedő szerkeszt, akkor a termék módosítható.
- Adott, hogy a terméken már van foglalás, amikor a kereskedő szerkesztene, akkor üzleti hibát kap.

3. Fogyasztói feed/szűrés
- Adottak az aktív termékek, amikor kategóriaszűrés vagy helyalapú szűrés történik, akkor csak az illeszkedő aktív termékek listázódnak.
- Adott egy mentett home location vagy city mode, amikor a feed újratölt, akkor a távolságalapú rendezés ezt figyelembe veszi.

4. Foglalás
- Adott az elérhető mennyiség, amikor a fogyasztó foglal, akkor létrejön a foglalás rekordja, csökken a mennyiség, és a részletoldalon pickup code / QR token jelenik meg.
- Adott a nem elérhető mennyiség, amikor a fogyasztó foglal, akkor a felhasználó `sold_out` vagy `insufficient-quantity` jellegű hibát lát.
- Adott egy reserved foglalás, amikor a fogyasztó lemondja és refundot kér, akkor a státusz és a refund állapot rögzítődik.

5. Kereskedői teljesítés és utógondozás
- Adott, hogy a foglalás a kereskedőé, amikor QR tokennel vagy pickup kóddal végrehajtja a teljesítést, akkor a foglalás állapota `completed` lesz.
- Adott egy refundot igénylő cancelled foglalás, amikor a kereskedő frissíti a refund státuszt, akkor az új állapot látható a részletoldalakon.
- Adott egy completed foglalás, amikor a fogyasztó review-t küld, akkor a `reviews` kollekcióban megjelenik az értékelés és a merchant stat frissül.

6. Admin monitoring és moderáció
- Adott egy `admin: true` custom claimmel rendelkező aktív felhasználó, amikor belép, akkor az admin home nyílik meg.
- Adott egy admin felhasználó, amikor megnyitja a dashboardot, akkor látja az összes felhasználó, kereskedő, vásárló, aktív termék, foglalás és completed foglalás számát.
- Adott egy admin felhasználó és egy cél user, amikor az admin `active`, `suspended` vagy `blocked` státuszt állít, akkor a `users/{uid}.accountStatus` és a Firebase Auth disabled állapot a szabálynak megfelelően frissül.
- Adott egy admin felhasználó és egy termék, amikor az admin elrejtést, visszaállítást vagy törlést indít, akkor a termék státusza `hidden`/korábbi státusz/`archived` irányba módosul, és a kliens ezt visszajelzi.
- Adott egy admin felhasználó és egy merchant célprofil, amikor az admin üzenetet küld, akkor a `users/{merchantId}/adminMessages/{messageId}` rekord létrejön, és a kereskedő a dashboardon látja és olvasottra jelölheti.

## Stretch célok (opcionális, ha marad idő)

- További `integration_test` flow-k a reservation, refund, review és QR útvonalakra.
- Determinisztikus integrációs tesztcsomag Firebase Emulatoron.
- E2E contract tesztek a rule deny/allow útvonalakra.
- Coverage gate vagy flaky-lista a CI-ban.

## Korlátok

- Platform: Flutter app Firebase backend szolgáltatásokkal.
- A mobilapp gyorsabban fejlődött, mint a dokumentációs csomag; a docs-as-code utolérése külön release-feladat.
- Adatfüggőségek: Firebase Auth, Firestore, Storage, Functions, FCM.
- Biztonsági korlát: nincs commitolt futásidejű secret.

## Release Definition of Done (jelenlegi contract)

- A build, lint és tesztek futtathatók dokumentált parancsokkal.
- A szükséges dokumentáció létezik a `docs/` alatt, és nem mond ellent a mostani mobilflow-knak.
- A security rule-ok verziózottak és review-zottak.
- Elérhető a kritikus MVP folyamatot és az új reservation/refund/review/QR flow-kat is bemutató demóscript.
- Az ismert hiányok explicit módon jelölve vannak a quality, release és AI naplókban.

# Scope contract

## MVP sztorik

1. User registration and login with role routing
- A fogyasztó és a kereskedő be tud jelentkezni, és a megfelelő kezdőképernyőre kerül.

2. Merchant creates a product with key fields
- A kereskedő létre tud hozni terméket névvel, kategóriával, árazással, mennyiséggel, lejárattal, opcionális képpel és opcionális helyadattal.

3. Consumer feed and filtering
- A fogyasztó látja az aktív termékeket és kategória szerint szűrni tud.

4. Consumer reservation flow
- A fogyasztó le tudja foglalni az elérhető tételeket, és el tud jutni a foglalás részleteihez.

5. Merchant reservation completion
- A kereskedő teljesíteni tud egy lefoglalt rendelést, és a kereskedői statisztikák frissülnek.

Sztori hivatkozások:
- [`sprints/02/docs/stories/user_stories.md`](../../sprints/02/docs/stories/user_stories.md)
- [`sprints/02/docs/spec/product_spec_v0.2.md`](../../sprints/02/docs/spec/product_spec_v0.2.md)

## Elfogadási kritériumok (sztori szintű összefoglaló)

1. Auth és role routing
- Adott egy érvényes user role a `users/{uid}` dokumentumban, amikor az app elindul, akkor a szerephez tartozó képernyő nyílik meg.

2. Terméklétrehozás
- Adottak az érvényes bemenetek, amikor a kereskedő ment, akkor a termék megjelenik a kereskedő listájában és láthatóvá válik az aktív feedben.
- Adottak az érvénytelen kötelező bemenetek, amikor a mentés gombra kattint, akkor a termék nem jön létre, és a felhasználó validációs visszajelzést kap.

3. Fogyasztói feed/szűrés
- Adottak az aktív termékek, amikor kategóriaszűrés történik, akkor csak az illeszkedő aktív termékek listázódnak.

4. Foglalás
- Adott az elérhető mennyiség, amikor a fogyasztó foglal, akkor létrejön a foglalás rekordja és csökken a mennyiség.
- Adott a nem elérhető mennyiség, amikor a fogyasztó foglal, akkor a felhasználó sold_out jellegű hibát lát.

5. Kereskedői teljesítés
- Adott, hogy a foglalás a kereskedőé, amikor végrehajtja a teljesítést, akkor a foglalás állapota `completed` lesz.

## Stretch célok (opcionális, ha marad idő)

- Determinisztikus integrációs tesztcsomag Firebase Emulatoron.
- E2E contract tesztek a rule deny/allow útvonalakra.
- Coverage gate a CI-ban.
- Alap healthcheck endpoint az üzemeltetési láthatósághoz.

## Korlátok

- Platform: Flutter app Firebase backend szolgáltatásokkal.
- Idő: a dokumentáció és a megvalósítás még összehangolás alatt áll.
- Adatfüggőségek: Firebase Auth, Firestore, Storage, FCM.
- Biztonsági korlát: nincs commitolt futásidejű secret.

## Release Definition of Done (jelenlegi contract)

- A build, lint és tesztek futtathatók dokumentált parancsokkal.
- A szükséges dokumentáció létezik a `docs/` alatt.
- A security rule-ok verziózottak és review-zottak.
- Elérhető a kritikus MVP folyamatot bemutató demóscript.
- Az ismert hiányok explicit módon jelölve vannak a quality és AI naplókban.

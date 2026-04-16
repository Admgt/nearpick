# User journey-k

## 1. Vásárló lefoglal egy közeli ajánlatot

Persona: egy visszatérő vásárló gyorsan szeretne kedvezményes, közeli ételajánlatot találni és lefoglalni.

Belépési pont: app icon, majd bejelentkezés.

1. S01 - Login. A user megadja email címét és jelszavát, majd a `Belépés` gombra kattint. -> S03 nyílik meg consumer szerepkörrel. Hibaág: hibás auth adatnál szöveges hibaüzenet jelenik meg.
2. S03 - Fogyasztói ajánlatlista. A user kategóriát választ, majd megnyit egy ajánlatot. -> S04 nyílik meg. Hibaág: ha nincs találat, üres állapot jelenik meg.
3. S04 - Termék részletek. A user ellenőrzi a lejáratot, árat, kereskedőt és értékeléseket, majd a `Lefoglalom` gombra kattint. -> több darabnál D03 mennyiségválasztó jelenik meg. Hibaág: ha elfogyott a készlet, a foglalás nem indítható.
4. D03 - Foglalási mennyiség. A user kiválasztja a darabszámot és megerősít. -> S05 nyílik meg. Hibaág: insufficient quantity vagy sold-out esetén snackbar hibaüzenet jelenik meg.
5. S05 - Foglalás részletei. A user látja a pickup kódot, QR tokent, átvételi idősávot és státuszt.

Sikerkritérium: a user a S05 képernyőn látja az aktív foglalást, pickup kóddal és QR tokennel.

Mért időtartam kb.: 35-50 másodperc, 5-7 interakció.

## 2. Kereskedő új terméket tölt fel

Persona: egy kereskedő a nap végén megmaradt terméket szeretné gyorsan közzétenni kedvezményes áron.

Belépési pont: app icon, majd kereskedői bejelentkezés.

1. S01 - Login. A kereskedő belép email/jelszó párossal. -> S07 nyílik meg merchant szerepkörrel. Hibaág: nem aktív fiók esetén a rendszer hozzáférés-korlátozó képernyőre irányít.
2. S07 - Kereskedői terméklista. A kereskedő a `+ Új termék` gombra koppint. -> S08 nyílik meg. Hibaág: betöltési hiba esetén a terméklista helyén hibaüzenet jelenik meg.
3. S08 - Termékfeltöltő űrlap. A kereskedő kitölti a nevet, kategóriát, árakat, mennyiséget, lejáratot és pickup idősávot. Hibaág: hiányzó kötelező mezőknél validációs hiba látszik.
4. S08 - Termékfeltöltő űrlap. A kereskedő opcionálisan képet választ és árjavaslatot kér. -> az árjavaslat ugyanazon képernyő állapotaként jelenik meg. Hibaág: pricing/backend hiba snackbarban jelenik meg.
5. S08 - Termékfeltöltő űrlap. A kereskedő menti a terméket. -> S07 nyílik meg, a termék megjelenik a listában.

Sikerkritérium: a frissen létrehozott termék megjelenik a kereskedő saját terméklistájában, és aktív ajánlatként elérhető.

Mért időtartam kb.: 60-90 másodperc, 10-14 interakció.

## 3. Admin moderál és üzenetet küld kereskedőnek

Persona: egy admin alacsony rating vagy problémás termék miatt ellenőrzi a kereskedőt, majd célzott üzenetet küld.

Belépési pont: app icon, admin custom claimmel rendelkező fiók.

1. S01 - Login. Az admin belép. -> S12 nyílik meg, ha az account aktív és a tokenben `admin: true` claim van. Hibaág: nem admin user nem kap admin felületet.
2. S12 - Admin dashboard. Az admin áttekinti a metrikákat és moderációs fókuszpontokat, majd a kereskedő/felhasználó szekcióra lép. -> S13 nyílik meg.
3. S13 - Admin felhasználók. Az admin rákeres a kereskedőre és megnyitja a részleteket. -> S14 nyílik meg. Hibaág: nincs találat esetén üres találati szöveg látszik.
4. S14 - Admin kereskedő részlet. Az admin ellenőrzi a státuszt, termékeket, foglalásokat és review-kat, majd admin üzenetet ír. -> D07 admin üzenet állapot jelenik meg. Hibaág: tárgy vagy üzenettörzs nélkül validációs hiba jelenik meg.
5. S14 - Admin kereskedő részlet. Az admin elküldi az üzenetet. -> a kereskedő S10 dashboardján az admin üzenet megjelenik.

Sikerkritérium: az admin üzenet létrejön a kereskedő `adminMessages` alkollekciójában, és a kereskedői dashboardon olvasható.

Mért időtartam kb.: 45-70 másodperc, 7-10 interakció.

# UX flow-k

## 1. Felhasználói regisztráció és bejelentkezés

![Login screen](../assets/ux/login.png)
![Register screen](../assets/ux/register.png)

### Cél

A felhasználó tudjon új fiókot létrehozni, majd szerepkörének megfelelően belépni az alkalmazásba.

### Lépéssor

1. A felhasználó megnyitja a `NearPick - Bejelentkezés` képernyőt.
2. Ha még nincs fiókja, megnyitja a regisztrációs képernyőt.
3. Megadja az email címet, jelszót és a szükséges profiladatokat.
4. Sikeres regisztráció vagy bejelentkezés után a rendszer a szerepkör alapján a fogyasztói vagy kereskedői kezdőképernyőre navigál.

### Happy path

- A mezők helyesen vannak kitöltve.
- A Firebase Auth elfogadja a hitelesítést.
- A `users` gyűjteményből a szerepkör kiolvasható.
- A felhasználó a megfelelő kezdőképernyőre jut.

### Hibaállapotok

- Hibás email vagy jelszó.
- Hiányzó vagy érvénytelen regisztrációs adat.
- API kulcs vagy localhost auth domain probléma webes futtatásnál.
- Hálózati hiba vagy ideiglenesen nem elérhető Firebase szolgáltatás.

### Üres állapotok

- Új felhasználónak még nincs meglévő profiladata vagy preferenciája.
- A regisztrációs képernyő első megnyitásakor minden mező üres.

### Screenshot evidence

- A bejelentkezési képernyő alapállapota: `login.png`
- A regisztrációs képernyő szerepkör-választással: `register.png`

### Akadálymentességi megfontolások

- A beviteli mezők címkével rendelkeznek.
- A hibák szövegesen, nem csak színnel jelennek meg.
- A fő műveletek gombbal indíthatók, ezért érintőképernyőn és billentyűzettel is követhetők.

## 2. Termékböngészés és érdeklődés jelölése

![Consumer feed](../assets/ux/consumer_feed.png)
![Product detail](../assets/ux/product_detail.png)
![Consumer empty state](../assets/ux/consumer_empty_state.png)
![Reservation detail](../assets/ux/reservation_detail.png)

### Cél

A fogyasztó gyorsan találjon releváns ajánlatokat, tudja szűrni a listát, megnyitni a részleteket és jelezni az érdeklődését.

### Lépéssor

1. A felhasználó belép fogyasztói szerepkörrel.
2. Megnyílik az ajánlatlista.
3. A felhasználó kategóriát választ a szűrőből.
4. Megnyit egy terméket vagy a listából kezdeményez foglalást.
5. A rendszer a foglalási részletre vagy a termék részleteire navigál.

### Happy path

- A terméklista betöltődik.
- A kategóriaszűrő működik.
- A releváns termékek sorrendje az ajánlási logika alapján frissül.
- A foglalás gomb aktív, ha van elérhető készlet.

### Hibaállapotok

- A terméklista betöltése hibával megszakad.
- A foglalás sold-out vagy backend hiba miatt meghiúsul.
- A termékkép nem tölthető be, ezért csak placeholder jelenik meg.

### Üres állapotok

- Nincs elérhető ajánlat a kiválasztott kategóriában.
- A felhasználónak még nincs kedvenc kategóriája vagy implicit preferenciája.

### Screenshot evidence

- A lista normál betöltött állapota: `consumer_feed.png`
- Üres kategóriaállapot felhasználói szöveges visszajelzéssel: `consumer_empty_state.png`
- A termék részletoldal foglalási CTA-val: `product_detail.png`
- A sikeres foglalás utáni részletképernyő pickup kóddal és státusszal: `reservation_detail.png`

### Akadálymentességi megfontolások

- A listaelemek szöveges információt is tartalmaznak, nem csak képet.
- A fontos műveletek (`Lefoglalom`, `Miért ajánlott?`, `Nem érdekel`) jól elkülönülnek.
- Az üres és hibás állapotok rövid, olvasható szöveges visszajelzést adnak.

## 3. Termék feltöltése kereskedőként

![Merchant home](../assets/ux/merchant_home.png)
![New product form](../assets/ux/new_product_form.png)
![New product validation error](../assets/ux/new_product_validation_error.png)

### Cél

A kereskedő gyorsan tudjon új terméket közzétenni a kötelező üzleti adatokkal és opcionális képpel.

### Lépéssor

1. A felhasználó kereskedői fiókkal belép.
2. A kezdőképernyőn megnyomja a lebegő `+` gombot.
3. Kitölti a termék nevét, kategóriáját, árait, mennyiségét, helyadatait és lejáratát.
4. Opcionálisan képet választ vagy készít.
5. Mentés után a rendszer visszanavigál a kereskedői listára.

### Happy path

- Minden kötelező mező valid.
- A helymeghatározás vagy a kézi koordináta-megadás sikeres.
- A termék mentése lefut.
- Az új termék megjelenik a kereskedő saját listájában.

### Hibaállapotok

- Hiányzó kötelező mező vagy hibás számszerű adat.
- A lejárati dátum nincs kiválasztva.
- A helyhozzáférés tiltva van vagy a hely meghatározása sikertelen.
- A feltöltés backend vagy hálózati hiba miatt megszakad.

### Üres állapotok

- Az első belépő kereskedő listája üres, ezért a rendszer szövegesen jelzi, hogy még nincs feltöltött termék.
- A képfeltöltés opcionális, ezért üres képterületből is indulhat a folyamat.

### Screenshot evidence

- A kereskedői lista aktív termékekkel: `merchant_home.png`
- A kitöltött termékfeltöltő űrlap: `new_product_form.png`
- Validációs hiba kötelező mező hiányánál: `new_product_validation_error.png`

### Akadálymentességi megfontolások

- Az űrlapmezők mind címkézettek.
- A validációs hibák szövegként megjelennek.
- A helymeghatározás és a mentés külön, jól azonosítható gombbal indítható.
- A képfeltöltés nem kizárólagos bemeneti mód, a termék kép nélkül is menthető.

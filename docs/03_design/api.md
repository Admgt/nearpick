# API és interfészszerződés

A NearPick hibrid szerződést használ: az olvasási és egyszerűbb írási útvonalak egy része közvetlen Firebase SDK-alapú, a kritikus reservation és product lifecycle műveletek pedig Cloud Functions callable végpontokon mennek át.

## Alapkörnyezet

- Firebase project (default): lásd [`.firebaserc`](../../.firebaserc)
- Firestore rules: [`../../firestore.rules`](../../firestore.rules)
- Storage rules: [`../../storage.rules`](../../storage.rules)

## Auth modell

- Hitelesítés: Firebase Auth email/jelszó.
- Jogosultságkezelés: Firestore/Storage security rule-ok `request.auth.uid`, role mezők és ownership korlátok alapján.

## Szerződési felületek

### 1) Firestore kollekciószerződés (kliens <-> Firestore)

| Felület | Művelet | Fő bemenetek | Fő kimenetek |
|---|---|---|---|
| `products` | read + merchant-owned write | product mezők, ownerId, quantity, expiry, location | aktív feed dokumentumok és kereskedői lista |
| `reservations` | read | productId, buyerId, merchantId, status, qty, pickup metaadatok | foglalási életciklus rekordok |
| `interests` | create/delete | userId + productId kulcs | kedvencjel és rangsorolási jel |
| `merchantStats` | read | kereskedői számlálók és rating aggregátum | kereskedői dashboard aggregátumok |
| `reviews` | read | reservation / merchant review adatok | merchant review lista és reservation detail |
| `users` + `fcmTokens` | profile + token persistence | role, preferenciák, company metaadatok, tokenek | auth routing + értesítési célzás |

### 2) Cloud Functions callable szerződések

| Function | Cél | Fő bemenet | Fő kimenet |
|---|---|---|---|
| `reserveProduct` | készletcsökkentés + reservation létrehozás | `productId`, `quantity` | `reservationId` |
| `completeReservation` | pickup code / token alapú teljesítés | `reservationId`, `pickupInput` | state change |
| `cancelReservation` | reservation lemondása | `reservationId`, `reasonCode`, `reasonNote`, `refundRequested` | state change |
| `updateRefundStatus` | merchant refund workflow | `reservationId`, `refundStatus` | state change |
| `submitReview` | merchant review rögzítése | `reservationId`, `rating`, `comment` | review write |
| `archiveProduct` | product archiválás | `productId` | state change |
| `repriceProduct` | pricing recommendation alkalmazása | `productId` | `discountedPrice` |

### 3) Cloud Functions trigger / scheduler szerződések

- `notifyOnNewProduct`
  - Forrás: Firestore dokumentum létrehozási esemény `products/{productId}`
  - Mellékhatás: szegmentált fogyasztói push értesítések küldése
- `generateProductThumbnail`
  - Forrás: Storage objektum véglegesítése `products/{ownerId}/{productId}/main.jpg`
  - Mellékhatás: `thumbnail.jpg` generálása és `products.thumbnailPath` frissítése
- `expireReservations`
  - Forrás: ütemezett futás
  - Mellékhatás: lejárt reservationök állapotfrissítése és készletvisszaállítás

Hivatkozás: [`../../functions/index.js`](../../functions/index.js)

## Hibamodell

A jelenlegi modell vegyes:
- Firebase SDK kivételek (`FirebaseException`) a service rétegben.
- Domain kivételek szöveges üzenetekként a kliensfolyamatban.

A célmodell:
- Stabil alkalmazásszintű hibakategóriák:
  - validation
  - auth
  - permission
  - conflict / sold_out / insufficient_quantity
  - invalid_state / invalid_pickup
  - transient network
  - internal

## Retry és idempotencia

- A foglalás callable tranzakciós szemantikát használ a mennyiségcsökkentéshez és konfliktuskezeléshez.
- Az érdeklődés létrehozása idempotens az összetett doc id minta (`uid_productId`) és a létezésellenőrzés miatt.
- A review reservation-szinten egyszeri műveletnek tekintendő.
- A `repriceProduct` csak létező pricing recommendation esetén hajtható végre.
- A retry policy jelenleg implicit; az explicit retry mátrix a [`error_handling.md`](error_handling.md) fájlban követhető.

## Rate limiting / visszaélésvédelem

- Jelenleg nincs explicit API gateway rate limiting.
- Az alap kontroll jelenleg a Firebase szolgáltatási limiteire és a security rule-okra támaszkodik.
- A dedikált visszaélésvédelem tervezett megerősítési lépés.

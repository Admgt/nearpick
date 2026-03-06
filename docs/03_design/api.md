# API és interfészszerződés

A NearPick jelenleg Firebase SDK-alapú adatelérést használ a kliensből, valamint egy Cloud Function triggert.

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
| `products` | create/read/update/archive | item mezők, ownerId, quantity, expiry | aktív feed dokumentumok és kereskedői lista |
| `reservations` | create/read/update status | productId, buyerId, merchantId, status | foglalási életciklus rekordok |
| `interests` | create/delete | userId + productId kulcs | kedvencjel és rangsorolási jel |
| `merchantStats` | merge updates | kereskedői számlálók | kereskedői dashboard aggregátumok |
| `users` + `fcmTokens` | profile + token persistence | role, preferenciák, tokenek | auth routing + értesítési célzás |

### 2) Cloud Function trigger szerződés

- Function: `notifyOnNewProduct`
- Forrás: Firestore dokumentum létrehozási esemény `products/{productId}`
- Bemeneti feltételezések:
  - `category`, `ownerId`, termékmegjelenítési mezők.
- Mellékhatások:
  - fogyasztói userek lekérdezése kategóriapreferencia alapján
  - token alkollekciók beolvasása
  - FCM multicast batch-ek küldése

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
  - conflict/sold_out
  - transient network
  - internal

## Retry és idempotencia

- A foglalás tranzakciós szemantikát használ a mennyiségcsökkentéshez és konfliktuskezeléshez.
- Az érdeklődés létrehozása idempotens az összetett doc id minta (`uid_productId`) és a létezésellenőrzés miatt.
- A retry policy jelenleg implicit; az explicit retry mátrix a [`error_handling.md`](error_handling.md) fájlban követhető.

## Rate limiting / visszaélésvédelem

- Jelenleg nincs explicit API gateway rate limiting.
- Az alap kontroll jelenleg a Firebase szolgáltatási limiteire és a security rule-okra támaszkodik.
- A dedikált visszaélésvédelem tervezett megerősítési lépés.

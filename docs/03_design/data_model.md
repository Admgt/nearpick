# Adatmodell

## Fő entitások

### users/{uid}

- Cél: profil + szerepkör + preferenciák.
- Fő mezők: `email`, `displayName`, `role`, `favoriteCategories`, `homeLocation`, `createdAt`.

### users/{uid}/fcmTokens/{tokenId}

- Cél: push token nyilvántartás.
- Fő mezők: `token`, `createdAt`, `platform`.

### products/{productId}

- Cél: kereskedői terméklista.
- Fő mezők:
  - ownership: `ownerId`
  - content: `name`, `category`, `imageUrl`, `imagePath`
  - pricing: `originalPrice`, `discountedPrice`
  - inventory: `quantity`, `quantityAvailable`
  - lifecycle: `status`, `isDeleted`, `expiresAt`, `archivedAt`, `deletedAt`
  - signals: `interestCount`, `createdAt`

### reservations/{reservationId}

- Cél: foglalási tranzakciós rekord.
- Fő mezők:
  - refs: `productId`, `merchantId`, `buyerId`
  - state: `status`, `qty`
  - timing: `createdAt`, `expiresAt`, `completedAt`
  - fulfillment: `pickupCode`
  - denormalized snapshot: `productSnapshot`

### interests/{interestId}

- Cél: kedvenc/érdeklődési jel.
- Fő mezők: `userId`, `productId`, `createdAt`.

### merchantStats/{merchantId}

- Cél: aggregált kereskedői számlálók.
- Fő mezők: `reservedCount`, `soldOutCount`, `completedCount`, `updatedAt`.

### userInteractions/{interactionId}

- Cél: interakciós audit/naplózás az ajánlórendszer támogatásához.
- Fő mezők: `userId`, `ownerId`, `type`, `productId`, `category`, `createdAt`.

### userImplicitPrefs/{uid}

- Cél: származtatott preferenciaprofil.
- Fő mezők: `categoryViews`, `categoryLastViewedAt`, `lastCompactedAt`, `lastUpdatedAt`.

### userNegativePrefs/{uid}

- Cél: kategória-elutasítási büntetőadatok.
- Fő mezők: `categoryDismissals`, `categoryLastDismissedAt`, `updatedAt`.

## Kapcsolatok és integritás

- `users (1) -> (N) products` az `ownerId` alapján.
- `products (1) -> (N) reservations` a `productId` alapján.
- `users (consumer) (1) -> (N) reservations` a `buyerId` alapján.
- `users (merchant) (1) -> (N) reservations` a `merchantId` alapján.
- `users (1) -> (N) interests` a `userId` alapján.

Integritási mechanizmusok:
- A Firestore rule-ok kikényszerítik a tulajdonosi/user korlátokat.
- A foglalási tranzakció kikényszeríti a mennyiségcsökkentést és a sold_out átmenetet.
- Az érdeklődés-létrehozási útvonal elkerüli a duplikált számlálást.

## Sémaevolúciós stratégia

- Az additív mezőfejlődés az előnyben részesített.
- Visszafelé kompatibilis alapértékek a model mapper-ekben (`fromDoc` fallback viselkedés).
- A migrációs stílus jelenleg futásidejű, biztonságos fallback, nem batch migrációs script.

## Adatmegőrzés és törlés

- A termékrekordok archiválhatók soft-delete mezőkkel.
- A foglalási rekordok megmaradnak a tranzakciótörténethez.
- A token dokumentumokat a jelenlegi token-életciklus események felülírják/frissítik.
- A dedikált retention policy automatizálás egy még nyitott üzemeltetési megerősítési feladat.

## Indexelési és teljesítmény-megjegyzések

A jelenlegi lekérdezési minták az alábbi indexeket indokolják:
- `products.status + expiresAt`
- `products.ownerId + expiresAt`
- `interests.userId`

Az indexkészletet összhangban kell tartani az aktív lekérdezési mintákkal és a CI/deploy folyamattal.

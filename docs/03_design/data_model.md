# Adatmodell

## Fő entitások

### users/{uid}

- Cél: profil + szerepkör + preferenciák + account / merchant metaadatok.
- Fő mezők:
  - identity: `email`, `displayName`, `role`, `createdAt`
  - consumer prefs: `favoriteCategories`, `homeLocation`, `homeLocationMode`, `homeLocationCityId`, `preferredRadiusKm`
  - merchant profile: `companyName`, `companyLocation`

### users/{uid}/fcmTokens/{tokenId}

- Cél: push token nyilvántartás.
- Fő mezők: `token`, `createdAt`, `platform`.

### products/{productId}

- Cél: kereskedői terméklista.
- Fő mezők:
  - ownership: `ownerId`
  - content: `merchantName`, `name`, `category`, `imageUrl`, `imagePath`, `thumbnailPath`
  - pricing: `originalPrice`, `discountedPrice`, `pricingRecommendation`
  - inventory: `quantity`, `quantityAvailable`
  - lifecycle: `status`, `isDeleted`, `hasReservations`, `expiresAt`, `pickupStartAt`, `pickupEndAt`, `archivedAt`, `deletedAt`
  - signals: `interestCount`, `createdAt`
  - geo: `location`

### reservations/{reservationId}

- Cél: foglalási tranzakciós rekord.
- Fő mezők:
  - refs: `productId`, `merchantId`, `buyerId`
  - state: `status`, `qty`
  - timing: `createdAt`, `expiresAt`, `completedAt`, `cancelledAt`, `expiredAt`
  - fulfillment: `pickupCode`, `pickupToken`
  - cancellation/refund: `cancelReasonCode`, `cancelReasonNote`, `cancelledBy`, `refundStatus`, `refundRequestedAt`, `refundReviewedAt`, `refundCompletedAt`, `refundReviewedBy`
  - review marker: `reviewSubmittedAt`
  - denormalized snapshot: `productSnapshot`

### reviews/{reservationId}

- Cél: completed reservation után beküldött merchant review.
- Fő mezők: `reservationId`, `merchantId`, `buyerId`, `buyerDisplayName`, `productId`, `productName`, `rating`, `comment`, `createdAt`.

### interests/{interestId}

- Cél: kedvenc/érdeklődési jel.
- Fő mezők: `userId`, `productId`, `createdAt`.

### merchantStats/{merchantId}

- Cél: aggregált kereskedői számlálók.
- Fő mezők: `reservedCount`, `soldOutCount`, `completedCount`, `averageRating`, `reviewCount`, `updatedAt`.

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
- `reservations (1) -> (0..1) reviews` a reservation azonosító alapján.

Integritási mechanizmusok:
- A Firestore rule-ok kikényszerítik a tulajdonosi/user korlátokat.
- A foglalási tranzakció kikényszeríti a mennyiségcsökkentést, a sold_out átmenetet és a többdarabos foglalás konzisztenciáját.
- Az érdeklődés-létrehozási útvonal elkerüli a duplikált számlálást.
- A review flow reservation-szintű egyediségre és completed státuszra támaszkodik.

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
- `products.isDeleted + ownerId + status + expiresAt`
- `reservations.buyerId + createdAt`
- `reservations.merchantId + status + createdAt`
- `reservations.pickupCode + merchantId`
- `userInteractions.ownerId + createdAt`
- `interests.userId` (single-field, automatikus index elegendo)

Az indexkészlet verziókezelve van a repo-ban a [`../../firestore.indexes.json`](../../firestore.indexes.json) fájlban, és azt összhangban kell tartani az aktív lekérdezési mintákkal és a CI/deploy folyamattal.

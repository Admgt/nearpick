# Hibakezelés

## Hibakategóriák

1. Validációs hibák
- Hiányzó kötelező űrlapmezők, érvénytelen numerikus/tartományértékek, hiányzó cégnév vagy hiányzó céghely.

2. Hitelesítési hibák
- Nincs hitelesített user a védett műveletekhez.

3. Jogosultsági hibák
- A hozzáférést rule-ok vagy ownership ellenőrzések tiltják.

4. Konfliktus/üzleti állapot hibák
- A tétel már elfogyott, a kért mennyiség nem érhető el, érvénytelen állapotátmenet, már lefoglalt termék szerkesztése.

5. Not found hibák
- Hiányzó termék-/foglalási dokumentum.

6. Pickup / review / refund hibák
- Érvénytelen pickup input, nem review-zható foglalás, érvénytelen refund státusz.

7. Átmeneti platform/network hibák
- Kapcsolati problémák és átmeneti backend hibák.

8. Belső/nem várt hibák
- Nem besorolt futásidejű kivételek.

## Felhasználó felé megjelenő üzenetek alapelvei

- Az üzenetek legyenek rövidek és cselekvésre ösztönzők.
- Kerülni kell a stack trace-ek és belső részletek megjelenítését.
- Az ismert konfliktus/auth/pickup hibákat lehetőség szerint determinisztikus szövegre kell leképezni.
- A felhasználó felé ne jelenjen meg nyers `FirebaseFunctionsException` vagy `Exception:` előtag.

## Retry stratégia

- Retry engedett átmeneti hibákra (network timeout, ideiglenes backend probléma).
- Nincs vak retry validációs/auth/jogosultsági/pickup/refund státusz hibákra.
- A tranzakciós konfliktusoknak explicit felhasználói visszajelzésként kell megjelenniük, és lehetővé kell tenniük az újrapróbálást.

## Backend/contract hibastruktúra

A jelenlegi forma még nem teljesen egységes, de a fő UI flow-kon már közös kliensoldali error mapper normalizálja a Firebase auth/functions és az általános kivételek egy részét. A reservation és product lifecycle callable hibák a Functions oldali `HttpsError` -> kliensoldali üzenet leképezésre támaszkodnak.

Célforma:
- `code`
- `message`
- `contextId` (opcionális korrelációs mező)
- `retryable` (opcionális, kliensoldali döntést segítő flag)

## Naplózási szabályzat

- Elegendő kontextust kell naplózni ahhoz, hogy a hibák fejlesztés és CI közben diagnosztizálhatók legyenek.
- Kerülni kell az érzékeny személyes adatok naplózását.
- Az auth tokenek és secret anyagok ne kerüljenek logba.

## Ismert hiányok

- A service réteg kivételei még mindig vegyes üzenetstílust tartalmaznak.
- A központi kliensoldali error mapper még nem fedi le az összes képernyőt és service-t.
- Még nincs formális correlation id továbbítás a kliens minden felületén.

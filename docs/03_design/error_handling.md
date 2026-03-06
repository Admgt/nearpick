# Hibakezelés

## Hibakategóriák

1. Validációs hibák
- Hiányzó kötelező űrlapmezők, érvénytelen numerikus/tartományértékek.

2. Hitelesítési hibák
- Nincs hitelesített user a védett műveletekhez.

3. Jogosultsági hibák
- A hozzáférést rule-ok vagy ownership ellenőrzések tiltják.

4. Konfliktus/üzleti állapot hibák
- A tétel már elfogyott, érvénytelen állapotátmenet.

5. Not found hibák
- Hiányzó termék-/foglalási dokumentum.

6. Átmeneti platform/network hibák
- Kapcsolati problémák és átmeneti backend hibák.

7. Belső/nem várt hibák
- Nem besorolt futásidejű kivételek.

## Felhasználó felé megjelenő üzenetek alapelvei

- Az üzenetek legyenek rövidek és cselekvésre ösztönzők.
- Kerülni kell a stack trace-ek és belső részletek megjelenítését.
- Az ismert konfliktus/auth hibákat lehetőség szerint determinisztikus szövegre kell leképezni.

## Retry stratégia

- Retry engedett átmeneti hibákra (network timeout, ideiglenes backend probléma).
- Nincs vak retry validációs/auth/jogosultsági hibákra.
- A tranzakciós konfliktusoknak explicit felhasználói visszajelzésként kell megjelenniük, és lehetővé kell tenniük az újrapróbálást.

## Backend/contract hibastruktúra

A jelenlegi forma vegyes, és még nincs végponttól végpontig szabványosítva.

Célforma:
- `code`
- `message`
- `contextId` (opcionális korrelációs mező)

## Naplózási szabályzat

- Elegendő kontextust kell naplózni ahhoz, hogy a hibák fejlesztés és CI közben diagnosztizálhatók legyenek.
- Kerülni kell az érzékeny személyes adatok naplózását.
- Az auth tokenek és secret anyagok ne kerüljenek logba.

## Ismert hiányok

- A service réteg kivételei még mindig vegyes üzenetstílust tartalmaznak.
- Még nincs központosított error mapper az összes képernyőre/service-re.
- Még nincs formális correlation id továbbítás.

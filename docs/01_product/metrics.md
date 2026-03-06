# Termékmetrikák

## North Star

1. Heti teljesített foglalások száma aktív kereskedőnként
- Miért: egyszerre ragadja meg a keresletet és a kereskedői értéket.
- Hogyan mérném: a `reservations` rekordok aggregálása `status=completed` szűréssel kereskedőnként 7 napos ablakokban.

## Védőkorlátok

1. Ajánlatértesítések megnyitási aránya
- Definíció: megnyitott értesítések / kézbesített értesítések.
- Forrás: push kézbesítési logok + kliens oldali megnyitási események.

2. Foglalási hibaarány
- Definíció: sikertelen foglalási kísérletek / összes foglalási kísérlet.
- Forrás: foglalási folyamat hibakimenetei (`sold_out`, auth hibák, validációs hibák).

3. Idő az első érdeklődésig feltöltés után
- Definíció: medián percek száma a termék létrehozása és az első `interest` vagy `view` között.
- Forrás: `products.createdAt` és `userInteractions.createdAt`.

4. Kereskedői feltöltés sikeressége
- Definíció: sikeres terméklétrehozások / terméklétrehozási kísérletek.
- Forrás: kliens oldali eseményjelölések a beküldés és a siker/hiba körül.

## Mérési terv

- Rövid távon: manuális kinyerés Firestore kollekciókból és CI/demó logokból.
- Középtávon: explicit instrumentációs mezők hozzáadása a funnel és hibakategóriák méréséhez.
- Hosszú távon: dashboard-szintű riportok release ellenőrzési pontokhoz kötve.

## Jelenlegi hiányok

- Még nincs dedikált analitikai dashboard.
- Egyes események meglévő dokumentumokból vannak levezetve, nem explicit eseménysémából.

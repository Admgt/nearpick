# Fenyegetésmodell

## Támadási felület

- Mobil kliens UI és hitelesített folyamatok.
- Firestore és Storage adatműveletek Firebase SDK-n keresztül.
- Cloud Function trigger útvonal értesítésekhez.
- Push token regisztráció és értesítéskézbesítés.

## Fenyegetési tábla

| Fenyegetés | Leírás | Hatás | Valószínűség | Mitigáció | Verifikáció |
|---|---|---|---|---|---|
| Jogosulatlan termékmódosítás | A user megpróbál írni egy másik kereskedő termékére | Magas | Közepes | Firestore owner ellenőrzések és rule korlátok | Rule review itt: [`../../firestore.rules`](../../firestore.rules), contract tesztek a test backlogban |
| Foglalási verseny miatti túlfoglalás | Több vásárló foglalja le egyszerre az utolsó darabot | Magas | Közepes | Tranzakcióalapú csökkentés és sold_out ág | Service logika itt: [`../../mobile/nearpick/lib/services/reservation_service.dart`](../../mobile/nearpick/lib/services/reservation_service.dart), konfliktus backlog tesztek |
| Token misuse vagy spam | Rosszindulatú/hibás tokenhasználat push zajhoz | Közepes | Közepes | A token hitelesített user útvonal alatt tárolódik | Function logika + user token ownership rule-ok |
| Adatszivárgás logokon keresztül | Érzékeny mezők véletlenül logba kerülnek | Magas | Alacsony-közepes | Naplózási szabályzat és code review guardrail | Megfigyelhetőségi/logolási szabályzat ellenőrzőlista |
| Rule megkerülés csak kliensoldali ellenőrzéssel | A UI tilt, de a backend mégis enged | Magas | Közepes | Szerveroldali security rule-ok minden védett kollekcióra | Rule file review + tervezett rules tesztek |
| Túlzott írási visszaélés | Automatizált gyors írások módosítható kollekciókra | Közepes | Közepes | Firebase auth, rule-ok és usage monitoring baseline | CI/security checklist, jövőbeli rate limiting megerősítés |
| Hiányos törléskezelés | A soft-delete-elt assetek továbbra is elérhetők maradnak | Közepes | Közepes | Archiválási/törlési jelölők és tervezett cleanup folyamat | Termékéletciklus-ellenőrzések; cleanup feladat követése |

## Maradó kockázatok

- Egyes tranzakciós megerősítések még mindig kliensoldaliak, és meg vannak jelölve lehetséges function-oldali migrációra.
- A CI jelenleg a `functions` függőségeire futtat automatizált dependency auditot; külön Flutter dependency-vulnerability ellenőrzés még nincs.
- A health/ops telemetria még mindig csak alap szintű.

## Verifikációs terv

- Dedikált rules allow/deny tesztek hozzáadása a products/reservations/users útvonalakra.
- Biztonságfókuszú negatív tesztek hozzáadása a test backlogból.
- Flutter dependency audit vagy SBOM alapú ellenőrzés hozzáadása a meglévő functions audit mellé.

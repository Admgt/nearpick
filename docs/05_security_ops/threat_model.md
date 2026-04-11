# Fenyegetésmodell

## Támadási felület

- Mobil kliens UI és hitelesített folyamatok.
- Firestore és Storage adatműveletek Firebase SDK-n keresztül.
- Cloud Function callable, trigger és scheduler útvonalak.
- Push token regisztráció és értesítéskézbesítés.

## Fenyegetési tábla

| Fenyegetés | Leírás | Hatás | Valószínűség | Mitigáció | Verifikáció |
|---|---|---|---|---|---|
| Jogosulatlan termékmódosítás | A user megpróbál írni egy másik kereskedő termékére | Magas | Közepes | Firestore owner ellenőrzések és rule korlátok | Rule review itt: [`../../firestore.rules`](../../firestore.rules), contract tesztek a test backlogban |
| Foglalási verseny miatti túlfoglalás | Több vásárló foglalja le egyszerre az utolsó darabot | Magas | Közepes | Tranzakcióalapú csökkentés és sold_out ág | Service logika itt: [`../../mobile/nearpick/lib/services/reservation_service.dart`](../../mobile/nearpick/lib/services/reservation_service.dart), konfliktus backlog tesztek |
| Token misuse vagy spam | Rosszindulatú/hibás tokenhasználat push zajhoz | Közepes | Közepes | A token hitelesített user útvonal alatt tárolódik | Function logika + user token ownership rule-ok |
| QR vagy pickup token visszaélés | Másik reservation pickup inputjának bemutatása vagy brute-force próbálgatása | Magas | Közepes | Szerveroldali pickup ellenőrzés, reservation státusz- és merchant ownership check | `completeReservation` helper-ek és pickup token parser tesztek |
| Helyadat túlzott kitettsége | A consumer vagy merchant location indokolatlanul széles körben olvashatóvá válik | Magas | Alacsony-közepes | Ownership/rule korlátok és minimális adatkör a UI-ban | User/profile és product rule review, privacy dokumentáció |
| Adatszivárgás logokon keresztül | Érzékeny mezők véletlenül logba kerülnek | Magas | Alacsony-közepes | Naplózási szabályzat és code review guardrail | Megfigyelhetőségi/logolási szabályzat ellenőrzőlista |
| Rule megkerülés csak kliensoldali ellenőrzéssel | A UI tilt, de a backend mégis enged | Magas | Közepes | Szerveroldali security rule-ok minden védett kollekcióra | Rule file review + tervezett rules tesztek |
| Review és refund workflow visszaélés | Jogosulatlan refund státuszfrissítés vagy completed nélkül küldött review | Magas | Közepes | Function-oldali jogosultság- és állapotellenőrzés | `security_helpers.test.js`, reservation és review modellek tesztjei |
| Admin jogosultság megszerzése vagy túl széles használata | Nem admin user admin adatokat vagy moderációs műveleteket próbál elérni | Magas | Alacsony-közepes | Firebase Auth custom claim `admin: true`, aktív `accountStatus`, Firestore `isAdmin()` helper és Functions `assertAdminRequest` | `firestore_rules_contract.test.js`, `firestore_rules_policy.test.js`, `root_router_test.dart`; callable negatív tesztek még bővítendők |
| Hibás admin fiókstátusz-módosítás | Admin véletlenül vagy rossz céluserrel tilt/felfüggeszt fiókot | Magas | Alacsony-közepes | Callable validáció, önmaga tiltásának blokkolása, `statusUpdatedBy` és `statusUpdatedAt` auditmezők | `setUserAccountStatus` code review; célzott callable teszt még backlog |
| Admin üzenet visszaélés vagy PII túlmegosztás | Admin üzenetben túl részletes személyes adat vagy spam jellegű tartalom kerül a kereskedőhöz | Közepes | Közepes | Téma- és hosszkorlát, admin claim ellenőrzés, user-alatti alkollekció és read receipt limitált update | Rule policy tesztek az `adminMessages` olvasásra/frissítésre |
| Termékmoderációs téves állapotátmenet | Admin tévesen elrejt vagy archivál aktív terméket | Közepes | Alacsony-közepes | Admin callable-ök célzott állapotmezőket módosítanak, restore megőrzi a `statusBeforeHidden` értéket | Function logok és admin product detail manuális review; célzott teszt még backlog |
| Túlzott írási visszaélés | Automatizált gyors írások módosítható kollekciókra | Közepes | Közepes | Firebase auth, rule-ok és usage monitoring baseline | CI/security checklist, jövőbeli rate limiting megerősítés |
| Hiányos törléskezelés | A soft-delete-elt assetek továbbra is elérhetők maradnak | Közepes | Közepes | Archiválási/törlési jelölők és tervezett cleanup folyamat | Termékéletciklus-ellenőrzések; cleanup feladat követése |

## Maradó kockázatok

- A rendszer már több kritikus callable műveletet használ, de a kliens továbbra is közvetlen Firestore olvasásokra és részben kliensoldali guardokra támaszkodik.
- A Flutter dependency audit be van kötve, de OSV advisory feedtől és hálózati elérhetőségtől függ.
- A health/ops telemetria még mindig csak alap szintű.

## Verifikációs terv

- Dedikált rules allow/deny tesztek hozzáadása a products/reservations/users útvonalakra.
- Dedikált negatív tesztek hozzáadása a pickup, refund és review state machine útvonalakra.
- Biztonságfókuszú negatív tesztek hozzáadása a test backlogból.
- SBOM alapú vagy fejlettebb SCA ellenőrzés hozzáadása a meglévő Flutter + functions audit mellé.

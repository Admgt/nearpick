# NearPick jövőkép

## Problémafelvetés

A kis helyi kereskedőknél gyakran marad a nap végén olyan romlandó készlet, amely nem fogy el. A NearPick erre egy olyan kétoldalú piacteret ad, ahol a kereskedő gyorsan fel tud tölteni egyedi tételeket, a vásárló pedig a saját helyéhez, kategóriapreferenciáihoz és aktuális készletszinthez igazodva tud választani.

## Célfelhasználók (personák)

1. Költségtudatos vásárló
- Cél: gyorsan találjon releváns, közeli ajánlatokat mobilon, akár pontos hely vagy előre definiált város alapján.
- Frusztráció: túl sok irreleváns ajánlat, bizonytalan átvételi információ, nehézkes account beállítások.

2. Kis kereskedő tulajdonos
- Cél: gyorsan feltölteni vagy szerkeszteni a megmaradt tételeket, csökkenteni a pazarlást, és átlátható módon kezelni a foglalásokat.
- Frusztráció: lassú adminisztráció, rossz árazási döntések, nehezen áttekinthető foglalási életciklus.

## Értékajánlat

A NearPick egy Flutter + Firebase alapú mobilalkalmazás, amely segíti a kereskedőket az egyedi, kedvezményes tételek közzétételében, a fogyasztókat pedig a releváns, közeli ajánlatok megtalálásában. A jelenlegi termékverzió már account/profile szerkesztéssel, céghely-örökléssel, többdarabos foglalással, QR alapú átvételi támogatással, refund- és review-folyamattal, valamint baseline dinamikus árazási javaslatokkal is rendelkezik.

## Siker definíciója

- North star metrika: heti teljesített foglalások száma aktív kereskedőnként.
- 1. védőkorlát-metrika: releváns ajánlatértesítések push megnyitási aránya.
- 2. védőkorlát-metrika: foglalási hibaarány, külön figyelve a `sold_out` és `insufficient-quantity` konfliktusokra.
- 3. védőkorlát-metrika: átlagos idő a tétel feltöltésétől az első fogyasztói interakcióig.
- 4. védőkorlát-metrika: merchant-side feltöltési sikeresség és pricing recommendation lefedettség.

A metrikadefiníciók és a mérési megközelítés a [`metrics.md`](metrics.md) fájlban találhatók.

## Non-goalok (jelenlegi scope)

- Teljes online fizetés és számlázás.
- Futárszolgálati és kiszállítási integráció.
- Teljes értékű backoffice vagy webes admin termék.
- Teljesen automatizált, ML-alapú dinamikus árazás és készlet-előrejelzés. A jelenlegi scope-ban csak baseline pricing recommendation és manuális alkalmazás van.

## Kockázatok és bizonytalanságok

1. Adatvédelem és helyadat-kezelés
- Mitigáció: szigorú security rule-ok, legkisebb jogosultság elve és dokumentált privacy scope.

2. Ajánlási és árazási minőség a korai szakaszban
- Mitigáció: magyarázható, szabályalapú baseline megtartása, dashboard és tesztek melletti fokozatos finomhangolás.

3. Értesítési fáradtság
- Mitigáció: relevanciaszűrők és szegmentált push célzás.

4. Kereskedői onboarding nehézsége
- Mitigáció: céghely-alapú alapértelmezett termékhely, egyszerű product form és szerkesztés az első foglalásig.

5. Tesztlefedettségi hiány a release-minőségi célhoz képest
- Mitigáció: a meglévő teszt backlog bővítése az új location, QR, refund, review és edit flow-kra a [`../04_quality/test_backlog.md`](../04_quality/test_backlog.md) alapján.

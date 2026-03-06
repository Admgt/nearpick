# NearPick jövőkép

## Problémafelvetés

A kis helyi kereskedőknél gyakran marad a nap végén olyan romlandó készlet, amely nem fogy el. A jelenlegi kedvezményes megoldások általában csomagközpontúak, miközben a felhasználók inkább tételszintű, közeli és preferenciáikhoz illeszkedő ajánlatokat szeretnének.

## Célfelhasználók (personák)

1. Költségtudatos diák vásárló
- Cél: gyorsan találjon releváns, közeli ajánlatokat mobilon.
- Frusztráció: túl sok irreleváns ajánlat, alacsony átláthatóság.

2. Kis kereskedő tulajdonos
- Cél: gyorsan feltölteni a megmaradt tételeket és csökkenteni a pazarlást.
- Frusztráció: lassú eszközök és alacsony elérés a releváns vásárlók felé.

## Értékajánlat

A NearPick egy Flutter + Firebase alapú mobilalkalmazás, amely segíti a kereskedőket az egyedi, kedvezményes tételek közzétételében, a fogyasztókat pedig a releváns, közeli ajánlatok megtalálásában preferenciaalapú rangsorolással és foglalási folyamattal.

## Siker definíciója

- North star metrika: heti teljesített foglalások száma aktív kereskedőnként.
- 1. védőkorlát-metrika: releváns ajánlatértesítések push megnyitási aránya.
- 2. védőkorlát-metrika: foglalási hibaarány (például sold_out konfliktus).
- 3. védőkorlát-metrika: átlagos idő a tétel feltöltésétől az első fogyasztói interakcióig.

A metrikadefiníciók és a mérési megközelítés a [`metrics.md`](metrics.md) fájlban találhatók.

## Non-goalok (jelenlegi scope)

- Teljes online fizetés és számlázás.
- Futár- és kiszállítási logisztikai integráció.
- Teljes értékű webes admintermék.
- Fejlett dinamikus árazás és készlet-előrejelzés.

## Kockázatok és bizonytalanságok

1. Adatvédelem és helyadat-kezelés
- Mitigáció: szigorú security rule-ok és legkisebb jogosultság elve.

2. Ajánlási minőség a korai szakaszban
- Mitigáció: magyarázható, szabályalapú baseline megtartása és finomhangolása megfigyelt használat alapján.

3. Értesítési fáradtság
- Mitigáció: relevanciaszűrők és preferenciaalapú célzás.

4. Kereskedői onboarding nehézsége
- Mitigáció: minimális feltöltési folyamat és egyértelmű empty state útmutatás.

5. Tesztlefedettségi hiány a release-minőségi célhoz képest
- Mitigáció: a meglévő teszt backlog végrehajtása a [`../04_quality/test_backlog.md`](../04_quality/test_backlog.md) alapján.

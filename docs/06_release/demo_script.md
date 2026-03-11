# Demóscript (6-7 perc)

## 0. Előkészítés

- Javasolt környezet: webes futtatás `flutter run -d edge --web-port 49904`
- Demo fiókok:
  - fogyasztó: `demo.user@nearpick.local`
  - kereskedő: `demo.merchant@nearpick.local`
- Legyen előkészítve legalább egy demo termék vagy a kereskedői flow során hozd létre élőben.

## 1. Nyitás és problémafelvetés (0:00-0:30)

Mondható szöveg:

"A NearPick egy közeli, időérzékeny kedvezményes ajánlatokra épülő piactér. A kereskedő gyorsan feltölt egy megmaradó terméket, a fogyasztó pedig néhány lépésben megtalálja és lefoglalja azt."

Mutasd meg:

- a bejelentkezési képernyőt
- a README quickstartot vagy a release dokumentációt röviden

## 2. Kereskedői fő flow (0:30-2:30)

Mondható szöveg:

"Először kereskedőként lépek be, és létrehozok egy új ajánlatot."

Lépések:

1. Jelentkezz be a kereskedői demo fiókkal.
2. Mutasd meg a kereskedői kezdőképernyőt.
3. Nyomd meg a `+` gombot.
4. Töltsd ki a minimális mezőket: név, kategória, eredeti ár, akciós ár, mennyiség, lejárat.
5. Opcionálisan mutasd meg a helymeghatározás vagy képfeltöltés lehetőségét.
6. Mentsd a terméket.
7. Mutasd meg, hogy az új tétel megjelenik a kereskedői listában.

## 3. Fogyasztói fő flow (2:30-4:30)

Mondható szöveg:

"Most átváltok fogyasztói nézetre, ahol a felhasználó szűrni, böngészni és foglalni tud."

Lépések:

1. Jelentkezz ki.
2. Jelentkezz be a fogyasztói demo fiókkal.
3. Mutasd meg az ajánlatlistát.
4. Válts kategóriát a szűrőben.
5. Nyisd meg a létrehozott vagy előkészített termék részleteit.
6. Indíts foglalást a `Lefoglalom` gombbal.
7. Navigálj a foglalás részletképernyőre.

## 4. Hiba- és üres állapotok (4:30-5:30)

Mondható szöveg:

"A bemutatóban nem csak a happy path fontos, hanem az is, hogy a rendszer hogyan reagál hibára vagy hiányzó adatra."

Mutass be legalább egyet:

- termékfeltöltés kötelező mező nélkül, validációs hibával
- olyan kategória kiválasztása, ahol nincs elérhető ajánlat
- sold-out vagy általános foglalási hiba szöveges visszajelzése

## 5. Minőségi evidence és release artefaktumok (5:30-6:30)

Mondható szöveg:

"A projekt értékeléséhez a működő demó mellett dokumentált minőségi bizonyítékok is tartoznak."

Mutasd meg:

- `README.md`
- `docs/01_product/ux_flows.md`
- `docs/04_quality/test_report.md`
- `docs/06_release/release_checklist.md`
- `.github/workflows/ci.yml`

## 6. Fallback lépések hálózati hiba esetére (6:30-7:00)

Ha a Firebase vagy a hálózat éppen nem elérhető:

1. Mutasd meg a `docs/01_product/ux_flows.md` fájlt a képernyőkép-helyőrzőkkel.
2. Mutasd meg a `docs/04_quality/test_report.md` és a CI workflow evidence-et.
3. Mondd el, hogy a reprodukálható demo útvonal külön demo Firebase projektre épül, nem production környezetre.
4. Ha a Functions emulátor fut, mutasd meg a helyi logokat mint technikai fallback evidence-et.

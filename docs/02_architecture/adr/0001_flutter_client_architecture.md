# ADR 0001 - Flutter kliens architektúra

- Dátum: 2026-03-11
- Státusz: Elfogadva

## Kontextus

A NearPick elsődleges felhasználói felülete egy Flutter kliens, amely fogyasztói és kereskedői nézetet is kiszolgál. A repository jelenlegi állapotában a kliens oldalon történik a szerepkör alapú navigáció, a képernyőkompozíció, az ajánlási logika egy része, valamint több Firebase SDK hívás kezdeményezése. A döntést úgy kellett rögzíteni, hogy az támogassa az egykódbázisú fejlesztést, a gyors MVP-szállítást és a szakdolgozati bemutathatóságot.

## Döntés

A kliensarchitektúra Flutter alapú, és a következő fő szervezési elvekre épül:

- egy közös Flutter alkalmazás szolgálja ki a fogyasztói és kereskedői felhasználói utakat
- a `RootRouter` kezeli az auth állapotból és a user szerepkörből következő belépési döntéseket
- a képernyők feature-alapon szerveződnek (`features/auth`, `features/consumer`, `features/merchant`)
- a Firebase integrációk szolgáltatásosztályokban jelennek meg (`AuthService`, `ProductService`, `ReservationService`, `NotificationService`)
- a tisztább, tesztelhető üzleti részek külön workflow vagy helper rétegbe kerülnek, ahol ez már megtörtént

## Következmények

Pozitív következmények:

- gyors fejlesztés és alacsony koordinációs költség egy kisebb csapat számára
- a mobil és webes demó ugyanabból a klienskódból bemutatható
- a feature-alapú szervezés támogatja a szakdolgozati dokumentálhatóságot és a tesztelhetőséget

Negatív vagy vállalt tradeoffok:

- több üzleti döntés közvetlenül a kliensből indít Firebase műveleteket
- a kliens és a backend közti határ nem minden esetben vastag API-rétegen keresztül valósul meg
- bizonyos validációk és tranzakciós döntések később kiszervezhetők lennének erősebb backend kontroll alá

## Alternatívák

- Natív Android + iOS kliens
  - előny: platformspecifikus kontroll
  - hátrány: dupla kódbázis és nagyobb fejlesztési költség
- React Native kliens
  - előny: széles JS ökoszisztéma
  - hátrány: a jelenlegi csomagban kevésbé illeszkedik a meglévő Flutter kódhoz és tesztekhez
- Vastagabb backend API réteg és vékony kliens
  - előny: erősebb szerveroldali kontroll
  - hátrány: magasabb kezdeti fejlesztési és üzemeltetési teher

## Verification

- Tesztek:
  - `mobile/nearpick/test/widget/auth/login_screen_test.dart`
  - `mobile/nearpick/test/widget/auth/register_screen_test.dart`
  - `mobile/nearpick/test/widget/merchant/new_product_screen_test.dart`
- CI evidence:
  - `.github/workflows/ci.yml`
  - `docs/04_quality/test_report.md`
- Dokumentációs artefaktok:
  - `docs/02_architecture/c4_component.md`
  - `docs/02_architecture/c4_context_container.md`
  - `docs/02_architecture/architecture_overview.md`
- Manuális demó validáció:
  - `docs/06_release/demo_script.md`
  - `docs/01_product/ux_flows.md`

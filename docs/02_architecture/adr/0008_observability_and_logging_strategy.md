# ADR 0008 - Megfigyelhetőségi és logolási stratégia

- Dátum: 2026-03-11
- Státusz: Elfogadva

## Kontextus

A rendszer jelenlegi érettségi szintjén nincs teljes APM vagy külön operációs platform, de a fejlesztői hibakereséshez, a CI diagnosztikához és a szakdolgozati bizonyításhoz mégis szükség van minimum megfigyelhetőségi baseline-ra. Az alkalmazásban vannak kliensoldali debug logok, a Cloud Functions oldalon pedig esemény- és hibalogolás.

## Döntés

A projekt megfigyelhetőségi stratégiája minimum, de tudatos baseline-ra épül:

- a kliensoldali hibák felhasználói visszajelzéssel és fejlesztői diagnosztikai logokkal jelennek meg
- a backend oldalon a Cloud Functions naplózza a trigger futásait és hibáit
- a dokumentáció rögzíti, mit nem szabad logolni
- a minimum operatív metrikák dokumentáltak, még ha külön dashboard nem is épült ki
- a CI és a tesztriport a build/test observability részét képezik

## Következmények

Pozitív következmények:

- a hibák visszafejtése egyszerűbb lokális és CI környezetben
- a szakdolgozati csomagban explicit observability artefakt létezik
- világos határ jön létre a fejlesztői log és az érzékeny adatkezelés között

Negatív vagy vállalt tradeoffok:

- nincs külön dashboard és automatikus riasztási réteg
- a logolás egy része még fejlesztői célú debug szintű megoldás

## Alternatívák

- Teljes körű observability stack azonnali bevezetése
  - előny: erős operációs láthatóság
  - hátrány: túl nagy beruházás a jelenlegi projektfázishoz
- Minimális logolás dokumentáció nélkül
  - előny: gyors
  - hátrány: rossz auditálhatóság és gyenge incidenskezelés
- Külső third-party monitoring platform korai integrálása
  - előny: fejlett elemzések
  - hátrány: többletköltség és extra integrációs komplexitás

## Verification

- Tesztek:
  - `functions/test/security_helpers.test.js`
  - `mobile/nearpick/test/integration/reservation/reservation_workflow_test.dart`
  - `mobile/nearpick/test/widget/auth/login_screen_test.dart`
- CI evidence:
  - `.github/workflows/ci.yml`
  - `docs/assets/logs/flutter_test_latest.log`
- Dokumentációs artefaktok:
  - `docs/05_security_ops/observability.md`
  - `docs/03_design/error_handling.md`
  - `docs/06_release/release_checklist.md`
- Manuális demó validáció:
  - `docs/06_release/demo_script.md`
  - `docs/06_release/demo_environment.md`

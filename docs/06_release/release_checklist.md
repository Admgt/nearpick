# Release checklist és scorecard

## Build reprodukálhatóság

- [x] A gyökér `README.md` legfeljebb 15 perces reviewer quickstartot tartalmaz.
- [x] A lokális futtatás külön demo Firebase projektre épül, nem production konfigurációra.
- [x] A szükséges mintafájlok verziókezeltek: `firebase_options.example.dart`, `google-services.example.json`, `firebase-messaging-sw.example.js`.
- [x] A CI tartalmaz build lépést webes artifact előállítására.
- [ ] A Flutter kliens teljes Firebase Emulator Suite átkötése elkészült.

## Tesztlefedettségi evidence

- [x] Létezik tesztstratégia dokumentum.
- [x] Létezik tesztriport dokumentum összesített eredménnyel.
- [x] A repository tartalmaz unit, widget és workflow-szintű teszteket.
- [x] A CI JUnit artifactot generál Flutter tesztekhez.
- [ ] Teljes `integration_test/` alapú mobil E2E demóflow evidence rendelkezésre áll.

## Biztonsági evidence

- [x] Firestore és Storage szabályfájlok verziókezeltek.
- [x] Létezik fenyegetésmodell dokumentum.
- [x] Létezik adatvédelmi és licensing dokumentum.
- [ ] Automatizált dependency audit lépés be van kötve a CI-ba.

## UX dokumentáció

- [x] A fő felhasználói folyamatok leírása elkészült.
- [x] A demóscript a bemutatási sorrendet és fallback lépéseket is tartalmazza.
- [x] A UX evidence asset könyvtár struktúrája elő van készítve.
- [ ] A végleges képernyőképek vagy videós evidence assetek be vannak illesztve.

## AI dokumentáció teljessége

- [x] Létezik AI manifest.
- [x] Létezik promptnapló.
- [x] Létezik verifikációs napló.
- [x] Az AI használat korlátai és emberi döntési pontjai dokumentáltak.

## Observability readiness

- [x] Létezik megfigyelhetőségi baseline dokumentum.
- [x] A hibakeresési útmutató dokumentált.
- [x] Minimum metrikakészlet meg van nevezve.
- [ ] Dedikált healthcheck endpoint elérhető.

## Deployment readiness

- [x] Létezik deploy runbook.
- [x] A CI külön lint, build és test szakaszokra bontott.
- [x] A release csomag tartalmaz changelogot.
- [ ] Végleges licencfájl és publikációs policy rögzítve van.

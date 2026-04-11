# Release checklist és scorecard

Kapcsolódó kitöltött önértékelés: [`self_assessment.md`](self_assessment.md)
Kapcsolódó CI evidence hely: [`ci_evidence.md`](ci_evidence.md)

## Build reprodukálhatóság

- [x] A gyökér `README.md` legfeljebb 15 perces reviewer quickstartot tartalmaz.
- [x] A lokális futtatás külön demo Firebase projektre épül, nem production konfigurációra.
- [x] A szükséges mintafájlok verziókezeltek: `firebase_options.example.dart`, `google-services.example.json`, `firebase-messaging-sw.example.js`.
- [x] A CI tartalmaz build lépést webes artifact előállítására.
- [x] A Flutter kliens teljes Firebase Emulator Suite átkötése elkészült.

## Tesztlefedettségi evidence

- [x] Létezik tesztstratégia dokumentum.
- [x] Létezik tesztriport dokumentum összesített eredménnyel.
- [x] A repository tartalmaz unit, widget és workflow-szintű teszteket.
- [x] A CI JUnit artifactot generál Flutter tesztekhez.
- [x] Legalább egy `integration_test/` alapú mobil E2E demóflow evidence rendelkezésre áll.

## Biztonsági evidence

- [x] Firestore és Storage szabályfájlok verziókezeltek.
- [x] Létezik fenyegetésmodell dokumentum.
- [x] Létezik adatvédelmi és licensing dokumentum.
- [x] Automatizált dependency audit lépés be van kötve a CI-ba a `functions` csomagra.
- [x] Flutter oldali dependency-vulnerability audit külön is be van vezetve.
- [x] Az admin custom claim és adminMessages rules modell dokumentált.
- [ ] Az admin callable-ek célzott negatív/happy path tesztfedése még backlog.

## UX dokumentáció

- [x] A fő felhasználói folyamatok leírása elkészült.
- [x] A demóscript a bemutatási sorrendet és fallback lépéseket is tartalmazza.
- [x] A UX evidence asset könyvtár struktúrája elő van készítve.
- [x] Az új account/profile/pricing/refund/QR flow-khoz tartozó végleges képernyőképek evidence assetként is be vannak illesztve.
- [x] Az admin dashboard, user detail, product detail, reservation detail és merchant admin messages screenshot evidence elérhető.

## AI dokumentáció teljessége

- [x] Létezik AI manifest.
- [x] Létezik promptnapló.
- [x] Létezik AI review checklist.
- [x] Létezik verifikációs napló.
- [x] Az AI használat korlátai és emberi döntési pontjai dokumentáltak.

## Observability readiness

- [x] Létezik megfigyelhetőségi baseline dokumentum.
- [x] A hibakeresési útmutató dokumentált.
- [x] Minimum metrikakészlet meg van nevezve.
- [x] Dedikált healthcheck endpoint elérhető.

## Deployment readiness

- [x] Létezik deploy runbook.
- [x] A CI külön lint, build és test szakaszokra bontott.
- [x] A release csomag tartalmaz changelogot.
- [x] Végleges licencfájl és publikációs policy rögzítve van.

## CI evidence rögzítés

- [x] Van külön hely előkészítve a konkrét GitHub Actions run link rögzítésére.
- [x] A legutóbbi main/default branch zöld run URL-je ténylegesen be van írva a [`ci_evidence.md`](ci_evidence.md) fájlba az aktuális HEAD-hez.
- [x] A kapcsolódó commit SHA és futási dátum is az aktuális HEAD-hez rögzítve van.

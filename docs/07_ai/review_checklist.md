# AI review checklist

Ezt a listát minden olyan változásnál végig kell nézni, ahol az AI kódot, dokumentációt, tesztet vagy döntési javaslatot adott.

## Kötelező minimum

- Az AI eredete vagy a promptcsalád rögzítve van a [`prompt_log.md`](prompt_log.md) fájlban.
- A kritikus állítás vagy döntés rögzítve van a [`verification_log.md`](verification_log.md) fájlban.
- Az artefaktum nem tartalmaz secretet, tokent, közvetlen PII-t vagy nem publikálható adatot.
- Az AI kimenet össze van vetve a tényleges kóddal, konfigurációval és dokumentációval.
- A változás nem hagy maga után `TODO`, placeholder vagy ellentmondó állítást.

## Kód esetén

- A diff ténylegesen a kért scope-ra korlátozódik.
- A kritikus ágakra van releváns teszt vagy meglévő teszt evidence.
- Lefutott legalább a releváns minimum gate:
  - Flutter: `flutter analyze`, `flutter test`
  - Functions: `npm run lint`, `npm test`
- Biztonsági és jogosultsági hatásnál külön ellenőrizve lett az auth/rules/logging viselkedés.
- A hibakezelés és a user-facing üzenetek nem maradtak nyers, félkész AI-szöveg állapotban.

## Dokumentáció esetén

- A leírás hivatkozható evidence-re támaszkodik, nem csak állításokra.
- A dokumentáció nem mond ellent a repo más fájljainak.
- A relatív linkek és a hivatkozott fájlok léteznek.
- Ha rekonstruált AI prompt szerepel, az egyértelműen jelölve van.

## Kritikus döntések esetén

- Megvan az emberi döntés rövid indoklása.
- Megvan, hogyan lett ellenőrizve az AI állítása: teszt, mérés, code review vagy PoC.
- Ha a döntés security, auth, adatmodell vagy architektúra területet érint, van külön verification bejegyzés.

## Merge feltétel

Az AI-val támogatott változás csak akkor tekinthető késznek, ha:
- a checklist releváns pontjai teljesülnek
- a kapcsolódó quality gate zöld
- a dokumentáció és a kód egymással konzisztens

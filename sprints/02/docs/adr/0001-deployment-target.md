# ADR 0001 – Deployment cél választása 

**Dátum:** 2025-11-10  
**Státusz:** Elfogadva

## Kontextus
A NearPick egy Flutter + Firebase mobilalkalmazás, amelyhez szükség van:
- preview környezetre (PR-ekhez, QA-hoz)
- publikus API végpontok futtatására (Cloud Functions)
- Firestore szabályok és indexek folyamatos deployjára
- alacsony költségű és egyszerű hostingra a marketing landing page és a privacy policy/terms oldalak számára

Mivel az alkalmazás backendje Firebase-en fut, fontos a zökkenőmentes integráció, gyors CI/CD és globális elérés.

## Döntés
Választás: Firebase Hosting + Cloud Functions deploy GitHub Actionsből
Indoklás:
- natív integráció a Firestore/Firebase Auth/Storage/FCM ökoszisztémával
- egy parancsos deploy (firebase deploy) → egyszerű pipeline
- Functions + Hosting együtt működik (API + statikus oldalak)
- preview channel-ek (hosting preview) automatikusan generálhatók PR-eken
- ingyenes/olcsó szint → ideális MVP és pilot számára

## Alternatívák
- Vercel: kiváló webes preview, de nem kezeli Firebase Functions-öket natívan; API routingot külön kellene kialakítani.
- Netlify: jó statikus hosting + preview, de nem natív Firebase backend integráció.
- GCP App Engine / Cloud Run: robusztusabb és rugalmasabb, de több üzemeltetési és konfigurációs teher.
- VM alapú hosting: teljes kontroll, de nem reális MVP-nél; nagy ops-költség.

## Következmények
Pozitív:
- Egységes platform → minden komponens egy ökoszisztémán belül
- Gyors és olcsó deploy
- Könnyű CI/CD GitHub Actions-ből
- Hosting preview linkek PR-enként

Negatív:
- Firebase vendor lock-in → későbbi migráció költséges
- Hosting konfiguráció korlátozottabb, mint Vercel/Netlify esetén
- Functions hidegindítás időnként lassabb lehet
# Megfigyelhetőség

## Naplózási baseline

- Szintek: `INFO`, `WARNING`, `ERROR`.
- App oldali viselkedés: a felhasználó felé a hibák UI visszajelzésként jelennek meg; a kritikus szerveroldali diagnosztika a Cloud Functions logokban követhető.
- Function oldali viselkedés: a kritikus műveletek (`reserveProduct`, `completeReservation`, `archiveProduct`, `notifyOnNewProduct`, `healthcheck`) JSON logbejegyzéseket írnak.
- Minden szerveroldali log tartalmaz `event` és `contextId` mezőt; ahol releváns, szerepel benne `productId`, `reservationId`, `userId`, `failedCount` vagy más üzleti kontextus.

Hivatkozás:
- [`../../functions/index.js`](../../functions/index.js)
- [`../../functions/observability.js`](../../functions/observability.js)

## Mit nem szabad naplózni

- Secret-eket, hitelesítő adatokat, tokeneket nyílt szövegként.
- Teljes személyes adat payloadokat, amikor azok nem szükségesek a diagnózishoz.

## Healthcheck állapot

- Létezik dedikált HTTP healthcheck endpoint: `healthcheck`.
- A válasz JSON formátumú, és minimum a runtime valamint a Firestore elérhetőség állapotát adja vissza.
- Elvárt mezők:
  - `service`
  - `status`
  - `timestamp`
  - `contextId`
  - `latencyMs`
  - `checks.runtime`
  - `checks.firestore`

Példa válasz:

```json
{
  "service": "nearpick-functions",
  "status": "ok",
  "timestamp": "2026-03-14T12:00:00.000Z",
  "contextId": "trace-123",
  "latencyMs": 11,
  "checks": {
    "runtime": "ok",
    "firestore": "ok"
  }
}
```

Ha a Firestore elérés hibázik, a healthcheck `503` státuszt és `status: degraded` választ ad.

## Metrikák (minimum 3)

1. Foglalási sikerességi/hibaarány
- Hogyan: foglalási próbálkozások és kimenetek számlálása időben.

2. Értesítéskézbesítési hibák száma
- Hogyan: a function küldési batch hibáinak aggregálása.

3. Aktív termékelérhetőség minősége
- Hogyan: az `active` termékek monitorozása `quantityAvailable > 0` feltétellel a sold_out átmenetekhez képest.

4. Opcionális latency metrikajelölt
- Hogyan: medián idő a termék létrehozása és az első interakció/foglalás között.

5. Healthcheck latency
- Hogyan: a `healthcheck` endpoint válaszidejének trendelése, különösen degradált állapotok előtt.

## Log minta

Sikeres healthcheck példa:

```json
{"severity":"INFO","event":"healthcheck.completed","timestamp":"2026-03-14T12:00:00.000Z","service":"nearpick-functions","status":"ok","contextId":"trace-123","latencyMs":11,"checks":{"runtime":"ok","firestore":"ok"}}
```

Hibás foglalási művelet példa:

```json
{"severity":"ERROR","event":"reservation.reserve.failed","timestamp":"2026-03-14T12:02:00.000Z","contextId":"trace-456","productId":"product-1","userId":"buyer-1","error":{"code":"failed-precondition","message":"Elfogyott.","name":"Error"}}
```

## Hibakeresési útmutató

1. CI hiba
- A [`../../.github/workflows/ci.yml`](../../.github/workflows/ci.yml) hibás lépésével kell kezdeni.

2. App flow probléma
- Lokális futtatással reprodukálni kell, majd megvizsgálni az érintett screen/service útvonalakon a service szintű kivételeket.

3. Értesítési probléma
- Meg kell nézni a function logokat `contextId` szerint, majd a token perzisztálási útvonalat.

4. Adatelérési probléma
- Ellenőrizni kell a rule útvonalat a `firestore.rules` fájlban és az érintett user role/ownership adatokat.

5. Healthcheck hiba
- Először a `healthcheck` válasz `checks` mezőjét kell megnézni.
- Ha `checks.firestore = error`, akkor Firestore jogosultság, projektelérés vagy platformoldali kiesés gyanús.

## Következő megerősítési lépések

- Dashboard-szintű metrikaláthatóság és alap riasztási küszöbök hozzáadása.
- A `contextId` továbbvitele kliensoldali hibaüzenet-korrelációig.
- Egyszerű alert szabályok hozzáadása healthcheck és foglalási hibaarány köré.

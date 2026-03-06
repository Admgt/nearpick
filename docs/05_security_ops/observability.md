# Megfigyelhetőség

## Naplózási baseline

- Szintek: info, warning, error (ahol a platform/runtime ezt támogatja).
- App oldali viselkedés: a felhasználó felé a hibák UI visszajelzésként jelennek meg; kulcsfolyamatokban debug print-ek léteznek.
- Function oldali viselkedés: a trigger logok tartalmazzák a küldési darabszámokat és hibákat.

Hivatkozás:
- [`../../functions/index.js`](../../functions/index.js)

## Mit nem szabad naplózni

- Secret-eket, hitelesítő adatokat, tokeneket nyílt szövegként.
- Teljes személyes adat payloadokat, amikor azok nem szükségesek a diagnózishoz.

## Healthcheck állapot

- Még nem létezik dedikált `/health` endpoint a backend runtime-hoz.
- A jelenlegi ekvivalens ellenőrzések a smoke/build/test pipeline lépések és a deploy smoke script hivatkozások:
  - [`../../sprints/02/scripts/smoke.yaml`](../../sprints/02/scripts/smoke.yaml)
  - [`../../sprints/02/scripts/smoke.http`](../../sprints/02/scripts/smoke.http)

## Metrikák (minimum 3)

1. Foglalási sikerességi/hibaarány
- Hogyan: foglalási próbálkozások és kimenetek számlálása időben.

2. Értesítéskézbesítési hibák száma
- Hogyan: a function küldési batch hibáinak aggregálása.

3. Aktív termékelérhetőség minősége
- Hogyan: az `active` termékek monitorozása `quantityAvailable > 0` feltétellel a sold_out átmenetekhez képest.

4. Opcionális latency metrikajelölt
- Hogyan: medián idő a termék létrehozása és az első interakció/foglalás között.

## Hibakeresési útmutató

1. CI hiba
- A [`../../.github/workflows/ci.yml`](../../.github/workflows/ci.yml) hibás lépésével kell kezdeni.

2. App flow probléma
- Lokális futtatással reprodukálni kell, majd megvizsgálni az érintett screen/service útvonalakon a service szintű kivételeket.

3. Értesítési probléma
- Meg kell nézni a function logokat és a token perzisztálási útvonalat.

4. Adatelérési probléma
- Ellenőrizni kell a rule útvonalat a `firestore.rules` fájlban és az érintett user role/ownership adatokat.

## Következő megerősítési lépések

- Explicit health endpoint vagy diagnosztikai nézet hozzáadása.
- Strukturált logok hozzáadása correlation/request id-val, ahol ez életszerű.
- Dashboard-szintű metrikaláthatóság és alap riasztási küszöbök hozzáadása.

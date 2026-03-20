# Performance baseline

Datum: `2026-03-19`

## Cel

Ez az artefakt a PDF engineering quality kovetelmenyenek megfelelo, kicsi, reprodukalhato performance baseline-t rogziti.

Valasztott kritikus utvonal:
- a recommendation pipeline-ben hasznalt `GeoUtils.haversineKm`
- ez minden olyan listazasnal relevans, ahol a tavolsag pontozasi tenyezo

Miért ezt mertuk:
- tiszta, izolalhato helper
- reprodukalhato lokalis benchmarkkal merheto
- kis, alacsony kockazatu optimalizalassal javithato

## Meresi modszer

Benchmark script:
- [`../../mobile/nearpick/tool/geo_distance_benchmark.dart`](../../mobile/nearpick/tool/geo_distance_benchmark.dart)

Futtatasi parancs:

```bash
cd mobile/nearpick
dart run tool/geo_distance_benchmark.dart
```

Meresi megjegyzesek:
- lokalis smoke benchmark, nem teljes profilozasi rendszer
- a szamok gep- es runtime-fuggok
- a cel a regressziofigyeles es a merheto optimalizalas dokumentalasa, nem az abszolut SLA

## Baseline meres

Felvett baseline kimenet:

```text
Geo distance performance smoke benchmark
Scenario focus: recommendation distance scoring helper
identical_points: 51740 us total, 0.0259 us/call, checksum=0.00
nearby_points: 18293 us total, 0.0366 us/call, checksum=393902.02
```

Ertelmezes:
- az `identical_points` eset gyakori rovid utvonal lehet, amikor a tavolsag nulla vagy ugyanarra a koordinatara tortenik az osszevetes
- a `nearby_points` a recommendation szempontjabol realisztikusabb, nem nulla tavolsagu eset

## Azonositott szuk keresztmetszet

A baseline alapjan a `GeoUtils.haversineKm` minden hivaskor teljes trigonometrikus utvonalon ment vegig, akkor is, ha a ket koordinata teljesen azonos volt.

Ez nem nagy algoritmikus problema, de:
- felesleges szamitas ugyanazon pontokra
- recommendation listazasban sokszor hivott utility
- nagyon olcson optimalizalhato

## Vegrehajtott javitas

Modositas:
- gyors visszateres azonos koordinatakra (`0.0 km`)
- a fel-szog trigonometrikus ertekei ujrafelhasznalt temporalis valtozokba kerultek
- kulon konstans kerult a fok-radian szorzohoz

Erintett kod:
- [`../../mobile/nearpick/lib/utils/geo_utils.dart`](../../mobile/nearpick/lib/utils/geo_utils.dart)

Meglevo funkcionalis vedohalo:
- [`../../mobile/nearpick/test/unit/utils/geo_utils_test.dart`](../../mobile/nearpick/test/unit/utils/geo_utils_test.dart)
- [`../../mobile/nearpick/test/unit/recommendation/recommendation_engine_test.dart`](../../mobile/nearpick/test/unit/recommendation/recommendation_engine_test.dart)

## Optimalizalas utani ujrameres

Felvett utomeres:

```text
Geo distance performance smoke benchmark
Scenario focus: recommendation distance scoring helper
identical_points: 12964 us total, 0.0065 us/call, checksum=0.00
nearby_points: 47956 us total, 0.0959 us/call, checksum=393902.02
```

## Osszehasonlitas

| Szenario | Baseline us/call | Utomeres us/call | Valtozas |
|---|---:|---:|---:|
| `identical_points` | 0.0259 | 0.0065 | kb. `-74.9%` |
| `nearby_points` | 0.0366 | 0.0959 | kb. `+162.0%` |

Ertelmezes:
- a celzott gyors visszateres az azonos koordinatas esetre valoban nagy javulast adott
- a nem azonos, de kozeli pontok eseten a mert smoke benchmark romlast mutat
- ezert a valtoztatas jelenleg specializalt optimalizalasnak tekintheto, nem altalanos teljesitmenyjavitasnak

## Allapot

- Baseline meres: kesz
- Egy konkret szuk keresztmetszet azonositasa: kesz
- Kis optimalizalas implementalasa: kesz
- Optimalizalas utani ujrameres: kesz
- Altalanos teljesitmenyjavulas igazolasa: meg nincs meg

## Kovetkezo lepes

- Ugyanezt a benchmarkot erdemes tobbszor, azonos gepen megismetelni es median vagy atlag alapon rogziteni.
- Ha a `nearby_points` romlas reprodukalhato, a mostani optimalizalast tovabb kell finomitani vagy vissza kell venni.
- A scorecardban ez a tetel tovabbra is reszleges (`0.5`) teljesitesnek tekintheto, mert a meres es a javitasi probalkozas megvan, de a javulas nem altalanos.

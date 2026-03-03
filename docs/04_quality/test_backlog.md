# Teszt backlog (30+ terv)

## Célmix összesítés
- Összes tesztterv: 30
- Unit: 18
- Integration: 6
- E2E/Contract: 6
- Negatív teszt: 9 (`negative` tipus)

Evidence referencia:
- CI workflow: [.github/workflows/ci.yml](../../.github/workflows/ci.yml)
- JUnit helye (unit/widget + test/**): [mobile/nearpick/reports/junit-flutter.xml](../../mobile/nearpick/reports/junit-flutter.xml)
- Integration step (integration_test/**): `Flutter integration tests (if present)` a CI `test` jobban.

## Backlog tábla
| ID | Szint | Tipus | Cél (1 mondat) | Javasolt fájl útvonal | Evidence (CI lépés / riport) |
|---|---|---|---|---|---|
| T-01 | unit | happy | Ellenőrizze, hogy `favoriteScore` 1.0-t ad kedvenc kategóriára és 0.0-t másra. | `mobile/nearpick/test/unit/recommendation/favorite_score_test.dart` | `Flutter unit/widget tests + JUnit` / `mobile/nearpick/reports/junit-flutter.xml` |
| T-02 | unit | edge | Ellenőrizze a `recencyScore` határértékeit (0 óra, 72 óra, 72+ óra). | `mobile/nearpick/test/unit/recommendation/recency_score_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-03 | unit | edge | Ellenőrizze az `expiryScore` határértékeit (<=6 óra, 48 óra, 48+ óra). | `mobile/nearpick/test/unit/recommendation/expiry_score_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-04 | unit | edge | Ellenőrizze, hogy az `interestScore` clampeli az értéket 0..1 tartományra. | `mobile/nearpick/test/unit/recommendation/interest_score_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-05 | unit | edge | Ellenőrizze a negatív kategóriadismiss hatását (friss dismiss nagyobb büntetés, régi dismiss kisebb). | `mobile/nearpick/test/unit/recommendation/dismiss_penalty_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-06 | unit | happy | Ellenőrizze, hogy a `scoreProductDoc` reason listája hozzájárulás szerint csökkenő sorrendbe rendeződik. | `mobile/nearpick/test/unit/recommendation/reasons_sorting_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-07 | unit | edge | Ellenőrizze, hogy a végsű score mindig 0..1 között marad extrém bemeneteknél is. | `mobile/nearpick/test/unit/recommendation/score_clamp_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-08 | unit | happy | Ellenőrizze az `expiryDetail` emberi olvasható formátumait különböző időkülönbségekre. | `mobile/nearpick/test/unit/recommendation/expiry_detail_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-09 | unit | edge | Ellenőrizze, hogy `GeoUtils.haversineKm` 0-t ad azonos pontokra. | `mobile/nearpick/test/unit/utils/geo_utils_zero_distance_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-10 | unit | edge | Ellenőrizze a távolságszámítás szimmetriáját (`A->B == B->A`). | `mobile/nearpick/test/unit/utils/geo_utils_symmetry_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-11 | unit | edge | Ellenőrizze, hogy `Product.fromDoc` fallbackeket ad hiányos dokumentum esetén. | `mobile/nearpick/test/unit/models/product_from_doc_fallback_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-12 | unit | happy | Ellenőrizze, hogy `Product.toMap` megfelelően serializálja a dátum mezőket `Timestamp`-ra. | `mobile/nearpick/test/unit/models/product_to_map_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-13 | unit | edge | Ellenőrizze, hogy `Reservation.fromDoc` fallback értékeket ad hiányos adatra. | `mobile/nearpick/test/unit/models/reservation_from_doc_fallback_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-14 | unit | negative | Refaktor után ellenőrizze a `new_product` koordináta parsert: fél mezők és nem sáam értékek hibával állnak le. | `mobile/nearpick/test/unit/validation/product_location_validation_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-15 | unit | negative | Refaktor után ellenorizze a `new_product` ar/mennyiseg validaciot (negativ vagy 0 ertek tiltott). | `mobile/nearpick/test/unit/validation/product_price_quantity_validation_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-16 | unit | edge | Refaktor után ellenőrizze a dashboard KPI aggregáció tiszta függvényét (views/interests/CTR számítas). | `mobile/nearpick/test/unit/dashboard/dashboard_kpi_aggregation_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-17 | unit | edge | Refaktor után ellenőrizze a consumer lista szűrő predikátumot (`status`, `isDeleted`, `quantity`, kategória). | `mobile/nearpick/test/unit/consumer/offer_filter_predicate_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-18 | unit | edge | Refaktor után ellenőrizze a pickup kód generator formátumát (hossz, megengedett karakterkészlet). | `mobile/nearpick/test/unit/reservation/pickup_code_format_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-19 | integration | happy | Ellenőrizze, hogy `AuthService.register` létrehozza a `users/{uid}` dokumentumot role/email/displayName mezőkkel. | `mobile/nearpick/test/integration/auth/register_persists_user_profile_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-20 | integration | negative | Ellenőrizze, hogy érvénytelen loginra `AuthService.login` hibát ad és nem jön létre auth session. | `mobile/nearpick/test/integration/auth/login_invalid_credentials_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-21 | integration | negative | Ellenőrizze, hogy `ProductService.createProductWithOptionalImage` auth nélkül exceptiont dob. | `mobile/nearpick/test/integration/product/create_product_requires_auth_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-22 | integration | happy | Ellenőrizze, hogy `markInterest` idempotens: ugyanarra a user+product párra csak egy interest jön létre és a számláló egyszer növelődik. | `mobile/nearpick/test/integration/product/mark_interest_idempotent_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-23 | integration | happy | Ellenőrizze, hogy `reserveProduct` csökkenti a mennyiséget, létrehozza a reservationt és frissíti a `merchantStats`-ot. | `mobile/nearpick/test/integration/reservation/reserve_product_transaction_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-24 | integration | negative | Ellenőrizze, hogy `completeReservation` idegen merchant userrel jogosultsági hibát ad és nem módosít státuszt. | `mobile/nearpick/test/integration/reservation/complete_reservation_authorization_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-25 | e2e-contract | happy | Merchant flow: új termék mentése után a termék megjelenik merchant listában és consumer feedben. | `mobile/nearpick/integration_test/flows/merchant_create_product_visible_for_consumer_test.dart` | `Flutter integration tests (if present)` / CI step log (jelenleg nincs külön JUnit) |
| T-26 | e2e-contract | happy | Consumer flow: sikeres foglalás után navigáció a reservation detailre és pickup kód megjelenik. | `mobile/nearpick/integration_test/flows/consumer_reserve_and_open_detail_test.dart` | `Flutter integration tests (if present)` / CI step log |
| T-27 | e2e-contract | negative | Versenyhelyzetben az utolsó darabnál a második foglalás `Elfogyott` hibával álljon meg. | `mobile/nearpick/integration_test/flows/sold_out_conflict_test.dart` | `Flutter integration tests (if present)` / CI step log |
| T-28 | e2e-contract | happy | Merchant `Átadva` művelet után a reservation státus `completed` lesz és a merchant listában is frissül. | `mobile/nearpick/integration_test/flows/merchant_complete_reservation_test.dart` | `Flutter integration tests (if present)` / CI step log |
| T-29 | e2e-contract | negative | Firestore contract: consumer ne tudja más merchant terméket archiválni (`permission-denied`). | `mobile/nearpick/integration_test/contracts/firestore_product_archive_rule_test.dart` | `Flutter integration tests (if present)` / CI step log |
| T-30 | e2e-contract | negative | Firestore/Storage contract: user csak saját profil helyzetét és saját FCM token alkollekciót írhassa. | `mobile/nearpick/integration_test/contracts/user_data_ownership_rules_test.dart` | `Flutter integration tests (if present)` / CI step log |

## Refaktor pontok a backloghoz
- `new_product_screen.dart`: validációs logika UI-ból kiemelése tiszta helperbe (`test/unit/validation/**`), hogy gyors unit tesztek irhatók legyenek.
- `merchant_dashboard_screen.dart`: KPI aggregáció kiemelése tiszta függvénybe (`test/unit/dashboard/**`), hogy Firestore nélkül ellenőrizhető legyen.
- `consumer_home_screen.dart`: offer szűres/rendezés kiszervezése (`test/unit/consumer/**`) determinisztikus unit tesztekhez.
- `reservation_service.dart`: pickup kód generáló strategy injektálhatósága (`test/unit/reservation/**`) a nem determinisztikus rész kontrolljához.

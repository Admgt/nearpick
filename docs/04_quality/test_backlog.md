# Teszt backlog (30+ terv)

## Célmix összesítés
- Összes tesztterv: 45
- Unit: 24
- Integration: 10
- E2E/Contract: 11
- Negatív teszt: 17 (`negative` tipus)

Evidence referencia:
- CI workflow: [.github/workflows/ci.yml](../../.github/workflows/ci.yml)
- JUnit evidence helye (unit/widget + test/**): [sprints/02/reports/junit.xml](../../sprints/02/reports/junit.xml)
- Integration step (integration_test/**): `Flutter integration tests (if present)` a CI `test` jobban.

## Backlog tábla
| ID | Szint | Tipus | Cél (1 mondat) | Javasolt fájl útvonal | Evidence (CI lépés / riport) |
|---|---|---|---|---|---|
| T-01 | unit | happy | Ellenőrizze, hogy `favoriteScore` 1.0-t ad kedvenc kategóriára és 0.0-t másra. | `mobile/nearpick/test/unit/recommendation/favorite_score_test.dart` | `Flutter unit/widget tests + JUnit` / `sprints/02/reports/junit.xml` |
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
| T-25 | e2e-contract | happy | Regisztráció, login és új termék mentés valódi Flutter UI képernyőkön Android emulátoron végigfut. | `mobile/nearpick/integration_test/flows/auth_and_product_flow_test.dart` | `Flutter integration tests (if present)` / CI step log (jelenleg nincs külön JUnit) |
| T-26 | e2e-contract | happy | Consumer flow: sikeres foglalás után navigáció a reservation detailre és pickup kód megjelenik. | `mobile/nearpick/integration_test/flows/consumer_reserve_and_open_detail_test.dart` | `Flutter integration tests (if present)` / CI step log |
| T-27 | e2e-contract | negative | Versenyhelyzetben az utolsó darabnál a második foglalás `Elfogyott` hibával álljon meg. | `mobile/nearpick/integration_test/flows/sold_out_conflict_test.dart` | `Flutter integration tests (if present)` / CI step log |
| T-28 | e2e-contract | happy | Merchant `Átadva` művelet után a reservation státus `completed` lesz és a merchant listában is frissül. | `mobile/nearpick/integration_test/flows/merchant_complete_reservation_test.dart` | `Flutter integration tests (if present)` / CI step log |
| T-29 | e2e-contract | negative | Firestore contract: consumer ne tudja más merchant terméket archiválni (`permission-denied`). | `mobile/nearpick/integration_test/contracts/firestore_product_archive_rule_test.dart` | `Flutter integration tests (if present)` / CI step log |
| T-30 | e2e-contract | negative | Firestore/Storage contract: user csak saját profil helyzetét és saját FCM token alkollekciót írhassa. | `mobile/nearpick/integration_test/contracts/user_data_ownership_rules_test.dart` | `Flutter integration tests (if present)` / CI step log |
| T-31 | unit | happy | Ellenőrizze, hogy a `LocationPreferences` city mode-ban a városközpontot használja effektív home locationként. | `mobile/nearpick/test/unit/consumer/location_preferences_city_mode_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-32 | unit | negative | Ellenőrizze, hogy a password reset üres emaillel validációs hibát ad. | `mobile/nearpick/test/widget/auth/password_reset_validation_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-33 | unit | edge | Ellenőrizze, hogy a `Product.fromDoc` kezeli a `thumbnailPath`, `pricingRecommendation` és `hasReservations` mezőket. | `mobile/nearpick/test/unit/models/product_extended_fields_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-34 | unit | edge | Ellenőrizze, hogy a `Reservation.fromDoc` kezeli a `pickupToken`, `refund*` és `reviewSubmittedAt` mezőket. | `mobile/nearpick/test/unit/models/reservation_extended_fields_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-35 | integration | happy | Ellenőrizze, hogy a merchant profile-ban mentett `companyLocation` automatikusan bekerül az új termékbe. | `mobile/nearpick/test/integration/product/company_location_applied_to_product_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-36 | integration | negative | Ellenőrizze, hogy céghely nélkül az új termék mentése hibát ad. | `mobile/nearpick/test/integration/product/create_product_requires_company_location_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-37 | integration | happy | Ellenőrizze, hogy a refundot kérő lemondás `pending` refund státusszal jön létre és visszaállítja a készletet. | `mobile/nearpick/test/integration/reservation/cancel_with_refund_pending_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-38 | integration | happy | Ellenőrizze, hogy `submitReview` completed reservation után létrehozza a review rekordot és frissíti a merchant statot. | `mobile/nearpick/test/integration/reservation/submit_review_updates_stats_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-39 | e2e-contract | happy | Fogyasztói account flow: kategória, city mode és preferred radius mentése után a feed helyesen frissül. | `mobile/nearpick/integration_test/flows/consumer_account_and_location_flow_test.dart` | `Flutter integration tests (if present)` / CI step log |
| T-40 | e2e-contract | happy | Merchant flow: QR vagy pickup input alapján a reservation `completed` lesz, majd a completed foglalás review-t kaphat. | `mobile/nearpick/integration_test/flows/merchant_qr_complete_and_review_flow_test.dart` | `Flutter integration tests (if present)` / CI step log |
| T-41 | unit | happy | Ellenőrizze, hogy az `AdminDashboardStats.fromCollections` helyesen számolja a user, merchant, customer, active product és completed reservation metrikákat. | `mobile/nearpick/test/unit/admin/admin_dashboard_stats_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-42 | unit | edge | Ellenőrizze, hogy az `AdminMessage.fromDoc` fallbackeket ad hiányos admin message dokumentumra és az `isRead` a `readAt` mezőből számol. | `mobile/nearpick/test/unit/models/admin_message_model_test.dart` | `Flutter unit/widget tests + JUnit` / JUnit XML |
| T-43 | e2e-contract | happy | Admin flow: admin claimmel a RootRouter admin home-ra navigál, a dashboard betölt és legalább egy felhasználó detail megnyitható. | `mobile/nearpick/integration_test/flows/admin_dashboard_flow_test.dart` | `Flutter integration tests (if present)` / CI step log |
| T-44 | e2e-contract | negative | Firestore contract: nem admin user ne tudjon más user adminMessages alkollekcióját olvasni vagy idegen read receiptet írni. | `mobile/nearpick/integration_test/contracts/admin_messages_rules_test.dart` | `Flutter integration tests (if present)` / CI step log |

## Lezárt backlog tétel
- T-45: az admin callable functions-test alapú negatív és happy path fedése elkészült a `functions/test/admin_callables_policy.test.js` fájlban. A 2026-04-11-i `npm.cmd test` futásban a teljes Functions suite `68/68` passed eredménnyel zárt.

## Refaktor pontok a backloghoz
- `new_product_screen.dart`: validációs logika UI-ból kiemelése tiszta helperbe (`test/unit/validation/**`), hogy gyors unit tesztek irhatók legyenek.
- `merchant_dashboard_screen.dart`: KPI aggregáció kiemelése tiszta függvénybe (`test/unit/dashboard/**`), hogy Firestore nélkül ellenőrizhető legyen.
- `consumer_home_screen.dart`: offer szűres/rendezés kiszervezése (`test/unit/consumer/**`) determinisztikus unit tesztekhez.
- `reservation_service.dart`: pickup kód generáló strategy injektálhatósága (`test/unit/reservation/**`) a nem determinisztikus rész kontrolljához.
- Admin callable-ek: később csak a teljesebb Firebase emulatoros lefedés bővítendő.

# Önértékelés

| Szempont | Pontszám | Indoklás |
|---|---:|---|
| Vizuális konzisztencia (szín, tipográfia, spacing) | 4 | Az app egységes Material 3 témát, közös SurfaceCard/NearPickBackground komponenseket és konzisztens spacinget használ, de néhány régebbi képernyő szövegezése/ékezete még nem teljesen egységes. |
| Információs hierarchia és olvashatóság | 4 | A fő műveletek és státuszok jól elkülönülnek kártyákkal, chipekkel és címekkel; a hosszabb admin nézeteknél még lehetne több csoportosítás. |
| Visszajelzések (loading, validáció, hiba, siker) | 4 | A fő stream-alapú képernyők loading/error állapotot, az űrlapok validációt, a műveletek snackbar visszajelzést adnak. |
| Hibakezelés és üres állapotok | 4 | A consumer feed, merchant lista és admin listák kezelik az üres találati állapotokat, de néhány ritkább edge case még egyszerű szöveges fallbacket használ. |
| Mobil / asztal lefedettség | 4 | A compact breakpoint és az admin desktop NavigationRail jó alapot ad, a screenshot evidence több szélességű viewportból származik. |
| Akadálymentesség (a11y) | 3 | A legtöbb input címkézett és a hibák szövegesek, de nincs külön dokumentált képernyőolvasó teszt vagy kontrasztmérés. |
| Onboarding és új-user élmény | 3 | A regisztráció és az üres állapotok érthetőek, de nincs külön, lépésenkénti onboarding flow. |
| Teljesítményérzet (gyorsaság, animációk) | 4 | A stream loadingok és kompakt listák gyors visszajelzést adnak, a nehezebb képekhez thumbnail/StorageImage fallback van, de nincs külön skeleton loading. |

## Szabadszöveges értékelés

A fogyasztói, kereskedői és admin szerepkörök külön, mégis egységes vizuális rendszerben működnek. A reservation lifecycle a pickup kóddal, QR tokennel, refunddal és review-val egy végigkövethető folyamatot ad. Ha lenne még két hét, külön onboardingot, teljesebb a11y auditot és több célzott üres/hiba állapotot fejlesztenék. Nem sikerült külön sötét módot és minden ritkább részfolyamhoz önálló screenshotot készíteni.

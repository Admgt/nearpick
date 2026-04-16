# Design rendszer / vizuális nyelv

## UI könyvtár

A kliens Flutter + Material 3 alapú. Külső komponens-könyvtár helyett saját, kis újrahasználható UI wrapper-eket használ: `NearPickBackground`, `SurfaceCard`, `InfoBadge`, `EmptyStateCard`, role-alapú navigációs helper-ek és domain-specifikus listaelemek.

## Színpaletta

| Token | Hex |
|---|---|
| primary | `#1E6F5C` |
| secondary | `#CB6E17` |
| accent / tertiary | `#4B7BE5` |
| success | `#1E6F5C` |
| warning | `#CB6E17` |
| error | `#B42318` |
| surface | `#FFFCF7` |
| surface container | `#E8F1EC` |
| scaffold background | `#F4F1EA` |
| text | `#18211E` |
| outline | `#7B8B85` |

## Tipográfia

Alap: Flutter `Typography.material2021`, Android target platformmal. Egyedi skála:

| Stílus | Méret | Weight | Megjegyzés |
|---|---:|---:|---|
| displayLarge | 56 | 700 | jelentős cím |
| displayMedium | 40 | 700 | nagy szekciócím |
| headlineMedium | 28 | 700 | fő képernyőcím / kártyacím |
| titleLarge | 22 | 700 | app bar és blokkcím |
| titleMedium | 16 | 700 | kártya/lista alcím |
| bodyLarge | 16 | 400 | fő bekezdés |
| bodyMedium | 14 | 400 | lista- és segédszöveg |
| labelLarge | 14 | 700 | gombok, jelölők |

## Spacing / grid

Az alap spacing 8 px-es, gyakori értékek: 8, 12, 16, 20, 24. A fő tartalom max szélessége általában 1120 px, részletoldalakon 720 px, hozzáférés-korlátozó képernyőn 640 px. A compact layout 600 px alatt kisebb paddinget használ.

## Ikonkészlet

Material Icons a Flutter `Icons.*` készletéből. A QR megjelenítéshez `qr_flutter`, térképes nézethez `flutter_map`, QR scannerhez `mobile_scanner` kapcsolódik.

## Sötét mód

Nem támogatott. A jelenlegi implementáció csak `AppTheme.lightTheme` témát ad át a `MaterialApp` példánynak.

## Reszponzív breakpoint-ok

| Breakpoint | Határ |
|---|---:|
| compact / mobile | `< 600px` |
| normal / tablet-desktop | `>= 600px` |
| admin desktop navigation | `>= 1120px` |

## Forrás

- Theme tokenek: `mobile/nearpick/lib/ui/app_theme.dart`
- Layout wrapper-ek és breakpoint: `mobile/nearpick/lib/ui/app_chrome.dart`
- Screenshot evidence: `docs/ux/screenshots/`

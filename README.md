# Szakdolgozat (NearPick)

[![CI](https://github.com/SZTE-SZF/1-sprint-Admgt/actions/workflows/ci.yml/badge.svg)](https://github.com/SZTE-SZF/1-sprint-Admgt/actions/workflows/ci.yml)

Rövid áttekintés a projekt felépítéséről és futtatásáról.

## Mappastruktúra

- `sprints/` – a sprintanyagok
  - `sprints/1/` – 1. sprint
  - `sprints/2/` – 2. sprint
- `mobile/nearpick/` – maga a mobil/web alkalmazás (Flutter)
- `functions/` – backend függvények (Firebase Functions)
- `scripts/` – segédscriptek (validáló script)

## Futtatás

Az alkalmazás indítása a `mobile/nearpick/` könyvtárból:

```bash
flutter run -d edge --web-port 49904  
```

Magyarázat:
- `-d edge` – a célböngésző az Edge. Ezt azért használjuk, mert a helymeghatározása megbízhatóbb, mint a Chrome-é.
- `--web-port 49904` – fix portot ad meg. Erre a CORS-beállítások miatt van szükség, mert véletlenszerű porton gondot okozhatna.

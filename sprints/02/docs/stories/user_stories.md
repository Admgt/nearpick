# User Stories (Sprint 2) 

## INVEST ellenőrzőlista
- Independent, Negotiable, Valuable, Estimable, Small, Testable

---

### US‑01: Üres állapot megjelenítése
Új kereskedőként egy üres állapotot szeretnék látni, ha még nincs feltöltött termékem. Így tudom, hogy mi a következő lépés (pl. "Adj hozzá új terméket")

Acceptance Criteria (Given–When–Then):
- AC1: Üres állapot üzenet, és az "Új termék hozzáadása" CTA  gomb látható
- AC2: Hiba esetén megjelenik egy "Próbáld újra" üzenet

Automatizálás: `tests/acceptance/empty_state.feature`

---

### US‑02: Új termék létrehozása
Kereskedőként szeretnék új terméket feltölteni képpel, árral és lejárati dátummal,
hogy elérhetővé tegyem a maradék készletet a vásárlók számára.

AC példák:
- AC1: Érvényes adatok esetén → sikeres mentés + termék megjelenik a listában
- AC2: Kötelező mező hiánya esetén → mezőhiba + termék nem jön létre

Automatizálás: `tests/acceptance/create_product.feature`

---

### US‑03: Terméklista megjelenítése
Kereskedőként szeretném látni a korábban feltöltött termékeimet egy listában,
hogy könnyen áttekintsem és kezeljem őket.

AC példák:
- AC1: A legutóbb feltöltött termékek jelennek meg legfelül
- AC2: A hosszú terméknevek levágva, esztétikusan jelennek meg

Automatizálás: `tests/acceptance/product_list.feature`

---

### US‑04: Szűrés kategória és távolság alapján
Vásárlóként szeretnék kategória és távolság alapján szűrni,
hogy csak a számomra releváns, közelben lévő ajánlatokat lássam.

AC példák:
- AC1: Kategória szűrés alkalmazásakor csak a kiválasztott kategóriába tartozó termékek jelennek meg
- AC2: Távolságszűrés esetén csak a beállított sugáron belüli termékek láthatók

Automatizálás: `tests/acceptance/filter_products.feature`

---

### US‑05: Vásárlói feed frissülése új termék után
Vásárlóként szeretném, ha a feed automatikusan frissülne,
amikor egy új, hozzám közel eső terméket feltöltenek,
hogy azonnal lássam az új ajánlatokat.

AC példák:
- AC1: Az új termék manuális frissítés nélkül megjelenik a feedben
- AC2: Push értesítés érkezik, ha a termék releváns számomra

Automatizálás: `tests/acceptance/feed_refresh.feature`
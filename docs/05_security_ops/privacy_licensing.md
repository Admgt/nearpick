# Adatvédelem és licencek

## Repository licenc és publikációs határ

- A repository saját forráskódja és dokumentációja MIT licenc alatt érhető el: [`../../LICENSE`](../../LICENSE).
- A nyilvános publikáció hatókörét és a kizárt tartalmakat a [`../06_release/publication_policy.md`](../06_release/publication_policy.md) rögzíti.
- A harmadik féltől származó függőségek, szolgáltatások és márkanevek továbbra is a saját licenceik és feltételeik alatt maradnak.

## Adatkategóriák

1. Fiók-/profiladatok
- Email, displayName, role.

2. Termék- és kereskedői működési adatok
- Termékmetaadatok, árazás, mennyiség, állapot, időbélyegek.

3. Foglalási és tranzakciós adatok
- Vásárló/kereskedő hivatkozások, foglalási állapot, pickup code.

4. Preferencia- és interakciós adatok
- Kedvencek/érdeklődések, kategórianézetek, elutasítási jelek.

5. Helyadattal kapcsolatos adatok
- Opcionális termék- és user-helyadatpontok.

6. Értesítési token adatok
- Eszköztoken rekordok user-tulajdonú alkollekcióban.

## Adatfolyam összefoglaló

- A kliens a Firebase SDK-n keresztül írja és olvassa az adatokat.
- A Firestore és a Storage rule-okon keresztül kényszeríti ki a hozzáférést.
- A Cloud Function termék-/user-/tokenadatokat olvas és értesítéseket küld.

## Adatmegőrzés és törlés

- A termékek támogatják az archivált/törölt jelölőmezőket.
- A foglalási rekordok megmaradnak a folyamatintegritás és előzmények miatt.
- A tokenadatok tokenrotáció során frissülnek.
- Az explicit retention cleanup automatizálás tervezett megerősítési feladat.

## Hozzáférési modell

- A consumer és merchant szerepkörök a user profile-ban jelennek meg.
- A védett írások hitelesített usert és ownership/role korlátokat igényelnek.
- A userhez kötött kollekciók (`users/{uid}`, prefs, tokens) a tulajdonosra vannak korlátozva.

## AI használat és adatok

- Érzékeny secret-eket és közvetlen személyes azonosítókat nem szabad AI eszközöknek küldeni.
- Az AI-val támogatott artefaktokat merge előtt validálni kell.
- A jelenlegi AI használati megjegyzések forrása: [`../../sprints/01/ai/usage_plan.yaml`](../../sprints/01/ai/usage_plan.yaml)

## Harmadik féltől származó függőségek és licencek

- A Flutter oldali fő függőségek itt vannak felsorolva:
  - [`../../mobile/nearpick/pubspec.yaml`](../../mobile/nearpick/pubspec.yaml)
- A functions oldali npm függőségek itt vannak felsorolva:
  - [`../../functions/package.json`](../../functions/package.json)
  - [`../../functions/package-lock.json`](../../functions/package-lock.json)

Jelenlegi szabály:
- A függőségek maradjanak lockfile-okkal rögzítve.
- Audit/scan evidence hozzáadása a CI-ban a következő megerősítési lépésként.
- A repository MIT licence nem terjed ki automatikusan a függőségekre; azok saját licencfeltételeit külön kell figyelembe venni.

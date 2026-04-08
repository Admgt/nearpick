# Adatvédelem és licencek

## Repository licenc és publikációs határ

- A repository saját forráskódja és dokumentációja MIT licenc alatt érhető el: [`../../LICENSE`](../../LICENSE).
- A nyilvános publikáció hatókörét és a kizárt tartalmakat a [`../06_release/publication_policy.md`](../06_release/publication_policy.md) rögzíti.
- A harmadik féltől származó függőségek, szolgáltatások és márkanevek továbbra is a saját licenceik és feltételeik alatt maradnak.

## Adatkategóriák

1. Fiók-/profiladatok
- Email, displayName, role, merchant esetén `companyName`.

2. Termék- és kereskedői működési adatok
- Termékmetaadatok, árazás, pricing recommendation snapshot, mennyiség, állapot, időbélyegek, opcionális képútvonalak és thumbnail útvonal.

3. Foglalási és tranzakciós adatok
- Vásárló/kereskedő hivatkozások, foglalási állapot, pickup code, pickup token, refund státuszok és review marker mezők.

4. Review és reputációs adatok
- Csillagos értékelés, rövid szöveges komment, buyer display name snapshot és review időbélyeg.

5. Preferencia- és interakciós adatok
- Kedvencek/érdeklődések, kategórianézetek, elutasítási jelek.

6. Helyadattal kapcsolatos adatok
- Opcionális termék- és user-helyadatpontok, `homeLocationMode`, `homeLocationCityId`, `preferredRadiusKm`, merchant `companyLocation`.

7. Értesítési token adatok
- Eszköztoken rekordok user-tulajdonú alkollekcióban.

## Adatfolyam összefoglaló

- A kliens a Firebase SDK-n keresztül írja és olvassa az adatokat.
- A Firestore és a Storage rule-okon keresztül kényszeríti ki a hozzáférést.
- A Cloud Functions termék-, reservation-, user- és tokenadatokat olvasnak, és értesítéseket, review / refund / archive / repricing műveleteket kezelnek.

## Adatmegőrzés és törlés

- A termékek támogatják az archivált/törölt jelölőmezőket.
- A foglalási rekordok megmaradnak a folyamatintegritás és előzmények miatt.
- A review rekordok reservation-szintű auditnyomként megmaradnak.
- A tokenadatok tokenrotáció során frissülnek.
- Az explicit retention cleanup automatizálás tervezett megerősítési feladat.

## Hozzáférési modell

- A consumer és merchant szerepkörök a user profile-ban jelennek meg.
- A védett írások hitelesített usert és ownership/role korlátokat igényelnek.
- A userhez kötött kollekciók (`users/{uid}`, prefs, tokens) a tulajdonosra vannak korlátozva.
- A refund státuszfrissítés és review küldés kritikus útvonalon function-oldali state checkre támaszkodik.

## AI használat és adatok

- Érzékeny secret-eket és közvetlen személyes azonosítókat nem szabad AI eszközöknek küldeni.
- Helyadatot, review szöveget vagy futásidejű user snapshotot csak minimális, indokolt részletességgel szabad AI eszköznek adni.
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

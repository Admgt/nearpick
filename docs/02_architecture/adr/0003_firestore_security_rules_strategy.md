# ADR 0003 - Firestore security rule stratégia

- Dátum: 2026-03-11
- Státusz: Elfogadva

## Kontextus

A NearPick rendszerben a kliens közvetlenül végez Firestore és részben Storage műveleteket, ezért a jogosultságkezelés nem maradhat pusztán UI-szintű. Az alkalmazásnak garantálnia kell, hogy egy felhasználó csak a saját profiljához, a saját kereskedői termékeihez és a szerepkörének megfelelő műveletekhez férjen hozzá.

## Döntés

A hozzáférés-vezérlés elsődleges backend mechanizmusa a Firebase security rules stratégia:

- a `request.auth.uid` az alapazonosító
- a szerepkör és tulajdonosi modell (`ownerId`, `merchantId`, `buyerId`) a rule-okban is megjelenik
- az admin jogosultság Firebase Auth custom claimmel (`request.auth.token.admin == true`) és aktív `accountStatus` feltétellel érvényes
- a kliensoldali tiltások csak UX célúak, nem tekinthetők biztonsági kontrollnak
- a védett kollekciókra explicit allow/deny logika tartozik
- a kritikus módosításoknál a rules a megengedett mezőváltozásokat is korlátozzák
- az admin írási műveletek nem közvetlen kliensoldali Firestore write-ok, hanem admin claimet ellenőrző Cloud Functions callable-ökön keresztül futnak

## Következmények

Pozitív következmények:

- a backend jogosultsági döntések nem a kliens jóindulatától függenek
- a security modell auditálható és verziókezelhető
- a szakdolgozati értékeléshez konkrét, kézzelfogható védelmi artefakt keletkezik
- az admin felület kaphat szélesebb olvasási jogosultságot anélkül, hogy a nem admin kliensek hozzáférési modellje lazulna

Negatív vagy vállalt tradeoffok:

- a rule-logika összetettebbé válik, különösen ownership és mezőszintű korlátozásoknál
- a rules tesztelése és review-ja külön fegyelmet igényel
- a szabályok nem helyettesítenek minden szerveroldali invariánst
- az admin custom claim provisioning külön operációs lépés, ezért runbookban és demo környezetben is dokumentálni kell

## Alternatívák

- Csak kliensoldali jogosultságkezelés
  - előny: egyszerűbb implementáció
  - hátrány: nem elfogadható biztonsági modell
- Külön saját backend API minden írási műveletre
  - előny: központi szerveroldali kontroll
  - hátrány: magasabb komplexitás és üzemeltetési teher
- Hibrid modell minimális rule-okkal és sok functionnel
  - előny: erősebb szerveroldali kontroll bizonyos use case-ekben
  - hátrány: a jelenlegi projektmérethez képest túl nehéz indulás

## Verification

- Tesztek:
  - `functions/test/firestore_rules_contract.test.js`
  - `functions/test/security_helpers.test.js`
  - `mobile/nearpick/test/integration/reservation/reservation_workflow_test.dart`
- CI evidence:
  - `.github/workflows/ci.yml`
  - `docs/07_ai/verification_log.md`
- Dokumentációs artefaktok:
  - `firestore.rules`
  - `storage.rules`
  - `docs/05_security_ops/threat_model.md`
  - `docs/03_design/api.md`
- Manuális demó validáció:
  - `docs/06_release/demo_script.md`
  - `docs/06_release/release_checklist.md`

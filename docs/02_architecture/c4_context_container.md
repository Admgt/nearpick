# C4 kontextus és konténerek

## C4 kontextus

```mermaid
flowchart LR
    consumer[Fogyasztói felhasználó]
    merchant[Kereskedői felhasználó]
    app[NearPick mobilalkalmazás]
    firebase[(Firebase platform)]
    fcm[Firebase Cloud Messaging]

    consumer --> app
    merchant --> app
    app --> firebase
    firebase --> fcm
    fcm --> app
```

### Kontextus megjegyzések

- Az elsődleges szereplők a `consumer` és a `merchant`.
- Az alkalmazás kezeli a UI-t, a kliensoldali szűrést/rangsorolást és a közvetlen Firebase SDK hívásokat.
- A backend platform Firebase (Auth, Firestore, Storage, Functions, Messaging).

## C4 konténerek

```mermaid
flowchart TB
    subgraph Client
      ui[Flutter UI réteg]
      domain[Domain/szolgáltatás réteg]
      rec[Ajánlómotor]
    end

    subgraph Firebase
      auth[Firebase Auth]
      fs[Cloud Firestore]
      st[Cloud Storage]
      fn[Cloud Functions]
      msg[FCM]
    end

    ui --> domain
    ui --> rec
    domain --> auth
    domain --> fs
    domain --> st
    fn --> fs
    fn --> msg
    msg --> ui
```

### Konténer megjegyzések

- Auth határ: a Firebase Auth session token szabályokon keresztül védi az adatelérést.
- Tárolt adatok határa: Firestore/Storage security rule-okkal.
- Külső függőségek: csak Firebase menedzselt szolgáltatások.

## Telepítési nézet (magas szintű)

- Lokális/dev: Flutter app + Firebase projektelérés vagy emulátoros útvonal.
- CI: a GitHub Actions futtatja a lint/build/test pipeline-t.
- A cél hosting/telepítési megközelítés dokumentálva van itt:
  - [`../../sprints/02/docs/adr/0001-deployment-target.md`](../../sprints/02/docs/adr/0001-deployment-target.md)
  - [`../../sprints/02/docs/adr/0003-iac-deploy-strategy.md`](../../sprints/02/docs/adr/0003-iac-deploy-strategy.md)

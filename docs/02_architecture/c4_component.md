# C4 komponensnézet

## Mobilalkalmazás komponensei

```mermaid
flowchart LR
    root[RootRouter]
    auth[AuthService]
    prod[ProductService]
    resv[ReservationService]
    notif[NotificationService]
    inter[UserInteractionService]
    neg[NegativeFeedbackService]
    reco[Recommendation Engine]

    root --> auth
    root --> notif
    root --> prod
    root --> resv
    root --> inter
    root --> neg
    root --> reco
```

### Felelősségek

- `RootRouter`: auth state kezelés és szerepalapú navigáció.
- `AuthService`: regisztráció/bejelentkezés/kijelentkezés és user profile bootstrap.
- `ProductService`: termék létrehozási/archiválási/érdeklődési műveletek.
- `ReservationService`: foglalási és foglalásteljesítési tranzakciós folyamat.
- `NotificationService`: token regisztráció és tokenfrissítés perzisztálása.
- `UserInteractionService`: implicit preferencia- és interakciónaplózás.
- `NegativeFeedbackService`: elutasításalapú negatív preferenciakezelés.
- `Recommendation Engine`: pontszámítás és ajánlási indokok.

## Backend komponensnézet

```mermaid
flowchart TB
    trigger[notifyOnNewProduct trigger]
    query[Fogyasztók lekérdezése kedvenc kategória szerint]
    token[FCM tokenek beolvasása]
    send[Multicast küldés]

    trigger --> query --> token --> send
```

### Felelősségek

- A függvénytrigger reagál a `products/{productId}` létrehozási eseményeire.
- Lekérdezi a fogyasztói usereket kategóriapreferencia alapján.
- Beolvassa a token alkollekciót és kötegelt FCM multicast értesítéseket küld.

## Ismert határok és hiányok

- A tranzakcióintenzív foglalási és számlálási logika jelenleg kliensvezérelt, és meg van jelölve lehetséges function-oldali megerősítésre.
- Egyes validációs logikák UI-hoz kötöttek, és tervben van a kiszervezésük tesztelhető tiszta helper függvényekbe.

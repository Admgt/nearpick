Feature: Új termék létrehozása

  Scenario: Sikeres mentés érvényes adatokkal
    Given a kereskedő az "Új termék" űrlapon van
     And minden kötelező mezőt érvényesen kitöltött
    When a "Mentés" gombra kattint
    Then lát egy sikeres mentésről szóló toast üzenetet
     And az új termék megjelenik a terméklistában legfelül

  Scenario: Kötelező mező hiányzik
    Given a kereskedő az "Új termék" űrlapon van
     And kihagyta az ár mező kitöltését
    When a "Mentés" gombra kattint
    Then a rendszer pirossal jelöli a hiányzó mezőt
     And nem jön létre új termék
     And hibaüzenet jelenik meg: "Kérjük, töltsd ki a kötelező mezőket"
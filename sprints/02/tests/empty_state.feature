Feature: Üres állapot

  Scenario: Első megnyitás üres terméklistával
    Given nincs feltöltött termék
    When a kereskedő megnyitja a terméklista képernyőt
    Then lát "Még nincs feltöltött terméked" üzenetet
     And lát "Új termék hozzáadása" gombot
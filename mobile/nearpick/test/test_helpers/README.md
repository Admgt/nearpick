# Teszt helper-ek

Ez a mappa közös helper kódnak van fenntartva a `test/**` tesztekhez.

Tipikus tartalom:
- fixture factory-k (`product`, `reservation`, `user`)
- fake/mock adapterek
- idődeterminációhoz használt helper-ek
- firestore/emulator setup utilityk

Cél:
- kevesebb duplikáció
- könnyebben olvasható tesztek
- stabilabb, determinisztikus futás

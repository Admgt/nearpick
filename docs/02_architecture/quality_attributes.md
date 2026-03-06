# Minőségi attribútumok

## Célattribútumok (5-8)

1. Megbízhatóság
- A kritikus folyamatoknak érthető felhasználói visszajelzéssel kell degradálódniuk, nem néma hibával.

2. Biztonság
- A hozzáférés-vezérlést backend rule-oknak kell kikényszeríteniük, nem csak a kliens UI-nak.

3. Karbantarthatóság
- A szolgáltatáshatároknak és az elnevezéseknek támogatniuk kell a fokozatos funkcióbővítést.

4. Tesztelhetőség
- A fő pontszámítási, mapping- és tranzakciós viselkedést izolálni kell determinisztikus tesztekhez.

5. Teljesítmény
- A feed és a termékműveletek maradjanak reszponzívak tipikus városi használat mellett.

6. Üzemeltethetőség
- A build/test/deploy és incidensdiagnosztika legyen végrehajtható a repo dokumentációja alapján.

7. Adatvédelem
- Az adatgyűjtésnek és adatmegőrzésnek explicitnek, szerepkörhöz kötöttnek és minimálisnak kell lennie.

## 1. minőségi attribútum forgatókönyv (megbízhatóság)

- Forrás: fogyasztói user instabil mobilhálózaton.
- Stimulus: foglalási művelet kerül beküldésre úgy, hogy közben változik a készlet.
- Környezet: normál forgalom párhuzamos vásárlókkal.
- Artefakt: `ReservationService.reserveProduct` + Firestore tranzakció.
- Válasz: egy foglalás sikeres, az ütköző próbálkozások determinisztikus felhasználói üzenettel hibáznak.
- Mérőszám: nincs negatív mennyiség a termékdokumentumokban; a sikertelen felhasználók konzisztens hibát kapnak egy interakción belül.

## 2. minőségi attribútum forgatókönyv (biztonság)

- Forrás: hitelesített, de nem jogosult user.
- Stimulus: megpróbál módosítani egy másik kereskedő termékadatait.
- Környezet: normál működés.
- Artefakt: Firestore rule-ok a `/products`, `/reservations`, `/users` útvonalakra.
- Válasz: a kérés a rule-ok által elutasításra kerül, és nem marad fenn jogosulatlan írás.
- Mérőszám: a deny útvonal reprodukálható security/integration tesztekben, nulla mellékhatással a tárolt dokumentumokra.

## További forgatókönyv-jelölt (teljesítmény)

- Forrás: aktív fogyasztó, aki megnyitja a feedet.
- Stimulus: aktív termékek lekérése és rangsorolása.
- Környezet: normál csúcsidő.
- Artefakt: aktív terméklekérdezés + ajánlási pontozási pipeline.
- Válasz: a feed görgethető marad, a rangsorolás pedig nem blokkolja a UI-t.
- Mérőszám: a baseline mérés később formalizálható quality/performance artefaktban.

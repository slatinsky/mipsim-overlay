# Záplaty

## deaktivuj_windows_help.1337

Deaktivuje windows help, ktory vyvolá chybovú hlášku `Die Hilfe konnte nich aufgerufen werden.` a otvorí Edge v systémoch Windows 10 a vyšších.

Túto chybu je možné vyvolať v MIPSIMe stlačením F1 alebo pravým klikom na konkrétny komponent v obvode.

Tento patch je dobrý ak patchujete priamo binárku bez použitia overlayu. Pre verziu pre overlay, použite `uloz_help_na_adresu_44D6F4.1337`

## LW_fix_pre_adresy_vacsie_ako_0xff.1337

Fixne inštrukciu LOAD WORD, ktorá pri adresách väčších ako 0xff vracia nesprávne hodnoty

## LW_SW_invalid_parameter_fix.1337

Fixne inštrukcie LOAD WORD a STORE WORD, ktoré nejde uložiť v editore (vo vyskakovacom okne `assembler`), ak sú moc dlhé.

## povol_ulozenie_prazdneho_operacneho_kodu.1337

Povolí uloženie prázdneho operačného kódu (bez inštrukcií) do súboru v okne `assembler` po kliknutí na tlačidlo `save`.

Bez tejto záplaty je zobrazená chybová hláška `No program in memory.`.

## povol_ulozenie_prazdnej_pamate.1337

Povolí uloženie prázdnej operačnej pamäte (bez hodnôt) do súboru v okne `data` po kliknutí na tlačidlo `save`.

## prepis_subory_bez_dalsieho_opytania.1337

Prepíše súbory pri ukladaní bez potvrdzovacieho okna.

## uloz_help_na_adresu_44D6F4.1337

Uloží help ID na adresu 0x44D6F4 - overlay prečíta danú hodnotu a zobrazí help.

## vymaz_datovu_pamat_bez_dalsieho_opytania.1337

Vymazanie operačnej pamäte bez potvrdzovacieho okna v okne `data`.

## vymaz_operacny_kod_bez_dalsieho_opytania.1337

Vymazanie operačného kódu bez potvrdzovacieho okna v okne `assembler`.

## vymaz_registre_bez_dalsieho_opytania.1337

Vymazanie registrov bez potvrdzovacieho okna v okne `registers`.
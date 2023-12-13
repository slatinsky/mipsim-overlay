global list_navesti_array

class funkcie_citaj_mipsim_subory
{
	precitaj_registre(subor) {

		FileDelete, %A_WorkingDir%\vystup.txt
		runwait, hexdump.exe "%subor%",,hide
		FileRead, hex, %A_WorkingDir%\vystup.txt

		;msgbox % hex
		hex_novy .= "R00 00000000`nR01 "
		Loop, parse, hex, ,
		{	
			buffer .= A_LoopField
			;msgbox % A_LoopField
			if (mod(A_Index,8) == 0) {
			
				bit_0 := this.ziskaj_bit_na_pozicii_8_bit(buffer, 0)
				bit_1 := this.ziskaj_bit_na_pozicii_8_bit(buffer, 1)
				bit_2 := this.ziskaj_bit_na_pozicii_8_bit(buffer, 2)
				bit_3 := this.ziskaj_bit_na_pozicii_8_bit(buffer, 3)
				bit_4 := this.ziskaj_bit_na_pozicii_8_bit(buffer, 4)
				bit_5 := this.ziskaj_bit_na_pozicii_8_bit(buffer, 5)
				bit_6 := this.ziskaj_bit_na_pozicii_8_bit(buffer, 6)
				bit_7 := this.ziskaj_bit_na_pozicii_8_bit(buffer, 7)
				
				hex_novy .= bit_6 . bit_7 . bit_4 . bit_5 . bit_2 . bit_3 . bit_0 . bit_1 . " "
				buffer =
				hex_novy .= "`nR" . padding_nulami(round(A_Index / 8 + 1),2) " "
			}
		}
		
		
		StringTrimRight, hex_novy, hex_novy, 5	;daj prec označenie pre 32. register
		;msgbox % hex_novy
		return % hex_novy
	}



	precitaj_pamat(subor) {

		FileDelete, %A_WorkingDir%\vystup.txt
		runwait, hexdump.exe "%subor%",,hide
		FileRead, hex, %A_WorkingDir%\vystup.txt

		;msgbox % hex
		StringTrimLeft, hex, hex, 8
		;msgbox % hex

		Loop, parse, hex, ,
		{	
			;hex_novy .= A_LoopField
			buffer .= A_LoopField
			;msgbox % A_LoopField
			if (mod(A_Index,8) == 0) {
				;msgbox % buffer
				bit_0 := this.ziskaj_bit_na_pozicii_8_bit(buffer, 0)
				bit_1 := this.ziskaj_bit_na_pozicii_8_bit(buffer, 1)
				bit_2 := this.ziskaj_bit_na_pozicii_8_bit(buffer, 2)
				bit_3 := this.ziskaj_bit_na_pozicii_8_bit(buffer, 3)
				bit_4 := this.ziskaj_bit_na_pozicii_8_bit(buffer, 4)
				bit_5 := this.ziskaj_bit_na_pozicii_8_bit(buffer, 5)
				bit_6 := this.ziskaj_bit_na_pozicii_8_bit(buffer, 6)
				bit_7 := this.ziskaj_bit_na_pozicii_8_bit(buffer, 7)
		 
				hex_novy .= bit_6 . bit_7 . bit_4 . bit_5 . bit_2 . bit_3 . bit_0 . bit_1 . " "
				buffer =
				
			}
			
			if (mod(A_Index,32) == 0) {
				hex_novy .= "`n"
			}
		}
		return % hex_novy
	}



	precitaj_instrukcie(hex) {
		list = 
			
		if (false)
		{
			FileDelete, %A_WorkingDir%\dependencies\vystup.txt
			;runwait, hexdump.exe "instr.mp",,hide
			runwait, dependencies\hexdump.exe "%subor%",%A_WorkingDir%\dependencies,hide
			FileRead, hex, %A_WorkingDir%\dependencies\vystup.txt


			StringTrimLeft, hex, hex, 8
			StringTrimRight, hex, hex, 32
			;msgbox % hex
		}


		Loop, parse, hex, ,
		{	
			hex_novy .= A_LoopField
			;msgbox % A_LoopField
			if (mod(A_Index,8) == 0) {
				hex_novy .= "`n"
			}
		}
		;msgbox % hex_novy


		list_navesti_array := ziskaj_navestia_array()
		Loop, parse, hex_novy, `ns,
		{	
			if (list_navesti_array[A_Index - 1] != "")
			{
				list .= "`n" list_navesti_array[A_Index - 1] ":`n"
			}
			
			bin := funkcie_hex.hex_do_bin(A_LoopField)
			
			;Mená premenných bin:
			;bin_zaciatocnaPozicia_konecnaPozicia
			
			bin_0_7 := bin
			StringTrimRight, bin_0_7, bin_0_7, 24
			
			bin_24_29 := bin
			StringTrimLeft, bin_24_29, bin_24_29, 24
			StringTrimRight, bin_24_29, bin_24_29, 2
			
			bin_24_25 := bin
			StringTrimLeft, bin_24_25, bin_24_25, 24
			StringTrimRight, bin_24_25, bin_24_25, 6
			
			;msgbox % bin_24_25
			
			;msgbox % bin_24_29
			if (bin == "00001001000000000000000000000000")	;KONIEC PROGRAMU
			{
				;list .= "KONIEC" "`n"
				;msgbox % "KONIEC"
				break
			}
			else if (bin == "00000000000000000000000000000000")	;NOP
			{
				list .= "NOP" "`n"
			}
			else if (bin_24_29 == "000000")	;ADD SUB AND XOR, ... 
			{
				if (bin_0_7 == "00100000")	;ADD
				{
					list .= "ADD" this.spracuj_reg_reg_reg(bin) "`n"
				}
				else if (bin_0_7 == "00100100")	;AND
				{
					list .= "AND" this.spracuj_reg_reg_reg(bin) "`n"
				}
				else if (bin_0_7 == "00011010")	;DIV
				{
					list .= "DIV" this.spracuj_reg_reg_reg(bin) "`n"
				}
				else if (bin_0_7 == "00011011")	;DIVU
				{
					list .= "DIVU" this.spracuj_reg_reg_reg(bin) "`n"
				}
				else if (bin_0_7 == "00011000")	;MUL
				{
					list .= "MUL" this.spracuj_reg_reg_reg(bin) "`n"
				}
				else if (bin_0_7 == "00011001")	;MULU
				{
					list .= "MULU" this.spracuj_reg_reg_reg(bin) "`n"
				}
				else if (bin_0_7 == "00100111")	;NOR
				{
					list .= "NOR" this.spracuj_reg_reg_reg(bin) "`n"
				}
				else if (bin_0_7 == "00100101")	;OR
				{
					list .= "OR" this.spracuj_reg_reg_reg(bin) "`n"
				}
				else if (bin_0_7 == "00000001")	;SLLV
				{
					list .= "SLLV" this.spracuj_reg_reg_reg(bin) "`n"
				}
				else if (bin_0_7 == "00000010")	;SRLV
				{
					list .= "SRLV" this.spracuj_reg_reg_reg(bin) "`n"
				}
				else if (bin_0_7 == "00100010")	;SUB
				{
					list .= "SUB" this.spracuj_reg_reg_reg(bin) "`n"
				}
				else if (bin_0_7 == "00100110")	;XOR
				{
					list .= "XOR" this.spracuj_reg_reg_reg(bin) "`n"
				}
				else if (bin_0_7 != "")	;Nepodporovaná inštrukcia
				{
					;list .= "XXX2" "`n"
				}
				
			}
			else if (bin_24_29 == "001000")	;ADDI
			{
				list .= "ADDI" this.spracuj_reg_reg_imm(bin) "`n"
			}
			else if (bin_24_29 == "001001")	;SUBI
			{
				list .= "SUBI" this.spracuj_reg_reg_imm(bin) "`n"
			}
			else if (bin_24_29 == "001100")	;ANDI
			{
				list .= "ANDI" this.spracuj_reg_reg_imm(bin) "`n"
			}
			else if (bin_24_29 == "001101")	;ORI
			{
				list .= "ORI" this.spracuj_reg_reg_imm(bin) "`n"
			}
			else if (bin_24_29 == "001110")	;XORI
			{
				list .= "XORI" this.spracuj_reg_reg_imm(bin) "`n"
			}
			else if (bin_24_29 == "000100")	;BEQ
			{
				list .= "BEQ" this.spracuj_reg_reg_imm(bin,0,prekonvertuj_imm_offset := (A_Index)) "`n"
			}
			else if (bin_24_29 == "000101")	;BNEQ
			{
				list .= "BNEQ" this.spracuj_reg_reg_imm(bin,0,prekonvertuj_imm_offset := (A_Index)) "`n"
			}
			else if (bin_24_29 == "100100")	;LI
			{
				list .= "LI" this.spracuj_reg_imm(bin) "`n"
			}
			else if (bin_24_29 == "100101")	;LUI
			{
				list .= "LUI" this.spracuj_reg_imm(bin) "`n"
			}
			else if (bin_24_29 == "100011")	;LW
			{
				list .= "LW" this.spracuj_reg_reg_imm(bin, 1) "`n"
			}
			else if (bin_24_29 == "101011")	;SW
			{
				list .= "SW" this.spracuj_reg_reg_imm(bin, 1) "`n"
			}
			else if (bin != "")	;Nepodporovaná inštrukcia - zobraz binárne pre debug
			{
				list .= this.formatuj_bin(bin) "|" this.formatuj_hex(A_LoopField) "`n"
			}
			
		}
		return % list
	}


	formatuj_bin(bin) {
		Loop, parse, bin, ,
		{	
			vystup .= A_LoopField
			
			if (mod(A_Index,4) == 0) {
				vystup .= " "
			}
			if (mod(A_Index,8) == 0) {
				vystup .= "  "
			}
		}
		return % vystup
	}

	formatuj_hex(hex) {
		Loop, parse, hex, ,
		{	
			vystup .= A_LoopField
			
			if (mod(A_Index,2) == 0) {
				vystup .= " "
			}
		}
		return % vystup
	}


	spracuj_reg_reg_reg(bin) {
		reg_1 := 16 * this.ziskaj_bit_na_pozicii(bin,8) + 8 * this.ziskaj_bit_na_pozicii(bin,9) + 4 * this.ziskaj_bit_na_pozicii(bin,10) + 2 * this.ziskaj_bit_na_pozicii(bin,11) + 1 * this.ziskaj_bit_na_pozicii(bin,12)
		
		reg_2 := 16 * this.ziskaj_bit_na_pozicii(bin,30) + 8 * this.ziskaj_bit_na_pozicii(bin,31) + 4 * this.ziskaj_bit_na_pozicii(bin,16) + 2 * this.ziskaj_bit_na_pozicii(bin,17) + 1 * this.ziskaj_bit_na_pozicii(bin,18)
		
		reg_3 := 16 * this.ziskaj_bit_na_pozicii(bin,19) + 8 * this.ziskaj_bit_na_pozicii(bin,20) + 4 * this.ziskaj_bit_na_pozicii(bin,21) + 2 * this.ziskaj_bit_na_pozicii(bin,22) + 1 * this.ziskaj_bit_na_pozicii(bin,23)
		
		return % " $" reg_1 ", $" reg_2 ", $" reg_3
	}

	spracuj_reg_reg_imm(bin, LW_SW_formatovanie := 0, prekonvertuj_imm_offset := -1) {
		imm_3 := 8 * this.ziskaj_bit_na_pozicii(bin,0) + 4 * this.ziskaj_bit_na_pozicii(bin,1) + 2 * this.ziskaj_bit_na_pozicii(bin,2) + 1 * this.ziskaj_bit_na_pozicii(bin,3) 
		imm_4 := 8 * this.ziskaj_bit_na_pozicii(bin,4) + 4 * this.ziskaj_bit_na_pozicii(bin,5) + 2 * this.ziskaj_bit_na_pozicii(bin,6) + 1 * this.ziskaj_bit_na_pozicii(bin,7) 
		imm_1 := 8 * this.ziskaj_bit_na_pozicii(bin,8) + 4 * this.ziskaj_bit_na_pozicii(bin,9) + 2 * this.ziskaj_bit_na_pozicii(bin,10) + 1 * this.ziskaj_bit_na_pozicii(bin,11) 
		imm_2 := 8 * this.ziskaj_bit_na_pozicii(bin,12) + 4 * this.ziskaj_bit_na_pozicii(bin,13) + 2 * this.ziskaj_bit_na_pozicii(bin,14) + 1 * this.ziskaj_bit_na_pozicii(bin,15) 
		
		imm := funkcie_hex.dec_do_unsigned_hex(imm_1) . funkcie_hex.dec_do_unsigned_hex(imm_2) . funkcie_hex.dec_do_unsigned_hex(imm_3) . funkcie_hex.dec_do_unsigned_hex(imm_4)
		
		
		
		StringReplace, imm, imm, 0x,,All

		if (prekonvertuj_imm_offset != -1)
		{
			vypocitany_offset_navestia := prekonvertuj_imm_offset + round(hex_short_unsigned_na_signed(baseConvert(imm, "hex", "dec")) / 4)	
			
			imm := list_navesti_array[vypocitany_offset_navestia]
		}

		
		reg_2 := 16 * this.ziskaj_bit_na_pozicii(bin,30) + 8 * this.ziskaj_bit_na_pozicii(bin,31) + 4 * this.ziskaj_bit_na_pozicii(bin,16) + 2 * this.ziskaj_bit_na_pozicii(bin,17) + 1 * this.ziskaj_bit_na_pozicii(bin,18)
		
		reg_1 := 16 * this.ziskaj_bit_na_pozicii(bin,19) + 8 * this.ziskaj_bit_na_pozicii(bin,20) + 4 * this.ziskaj_bit_na_pozicii(bin,21) + 2 * this.ziskaj_bit_na_pozicii(bin,22) + 1 * this.ziskaj_bit_na_pozicii(bin,23)
		
		if(LW_SW_formatovanie == 1) {	;Load word, store word formátovanie
			return % " $" reg_1 ", " imm "($" reg_2 ")" 
		}
		else {
			return % " $" reg_1 ", $" reg_2 ", " imm
		}
		
		
	}

	spracuj_reg_imm(bin) {
		imm_3 := 8 * this.ziskaj_bit_na_pozicii(bin,0) + 4 * this.ziskaj_bit_na_pozicii(bin,1) + 2 * this.ziskaj_bit_na_pozicii(bin,2) + 1 * this.ziskaj_bit_na_pozicii(bin,3) 
		imm_4 := 8 * this.ziskaj_bit_na_pozicii(bin,4) + 4 * this.ziskaj_bit_na_pozicii(bin,5) + 2 * this.ziskaj_bit_na_pozicii(bin,6) + 1 * this.ziskaj_bit_na_pozicii(bin,7) 
		imm_1 := 8 * this.ziskaj_bit_na_pozicii(bin,8) + 4 * this.ziskaj_bit_na_pozicii(bin,9) + 2 * this.ziskaj_bit_na_pozicii(bin,10) + 1 * this.ziskaj_bit_na_pozicii(bin,11) 
		imm_2 := 8 * this.ziskaj_bit_na_pozicii(bin,12) + 4 * this.ziskaj_bit_na_pozicii(bin,13) + 2 * this.ziskaj_bit_na_pozicii(bin,14) + 1 * this.ziskaj_bit_na_pozicii(bin,15) 
		
		imm := funkcie_hex.dec_do_unsigned_hex(imm_1) . funkcie_hex.dec_do_unsigned_hex(imm_2) . funkcie_hex.dec_do_unsigned_hex(imm_3) . funkcie_hex.dec_do_unsigned_hex(imm_4)
		
		StringReplace, imm, imm, 0x,,All
		
		reg_1 := 16 * this.ziskaj_bit_na_pozicii(bin,19) + 8 * this.ziskaj_bit_na_pozicii(bin,20) + 4 * this.ziskaj_bit_na_pozicii(bin,21) + 2 * this.ziskaj_bit_na_pozicii(bin,22) + 1 * this.ziskaj_bit_na_pozicii(bin,23)
		
		return % " $" reg_1 ", " imm
	}


	ziskaj_bit_na_pozicii(bin, pozicia) {
		bit_vystup := bin
		StringTrimLeft, bit_vystup, bit_vystup, % 0 + pozicia
		StringTrimRight, bit_vystup, bit_vystup, % 31 - pozicia
		return % bit_vystup
	}

	ziskaj_bit_na_pozicii_8_bit(bin, pozicia) {
		bit_vystup := bin
		StringTrimLeft, bit_vystup, bit_vystup, % 0 + pozicia
		StringTrimRight, bit_vystup, bit_vystup, % 7 - pozicia
		return % bit_vystup
	}

}








ziskaj_navestia_array()
{
	pointer_pozicie_navesti := ziskaj_pointer_na_pozicie_navesti()
	pointer_nazvy_navesti := ziskaj_pointer_na_nazvy_navesti()
	pocet_navesti := ziskaj_pocet_navesti()
	
	loop % pocet_navesti
	{
		pozicia_navestia_v_liste := round(mipsim_obj.read(pointer_pozicie_navesti + ((A_Index - 1) * 4), "UChar") / 4)
		;msgbox % mipsim_obj.read(pointer_nazvy_navesti, "UChar")
		nazov_navestia := mipsim_obj.readString(pointer_nazvy_navesti + ((A_Index - 1) * 9),10,"")
		list_txt .= pozicia_navestia_v_liste "|" nazov_navestia "`n"
	}
	
	
	return list_navesti_array := spracuj_list_navesti_do_array(list_txt)
}

spracuj_list_navesti_do_array(list_txt)	
{
	list_navesti := []	;číslovanie od čísla 0
	
	loop % 256	;počet riadkov inštrukcií v mipsime
	{
		hladane_cislo_riadku := A_Index - 1
		list_navesti[hladane_cislo_riadku] := ""
		Loop, parse, list_txt, `n,
		{	
			Loop, parse, A_LoopField, |,
			{	
				if (A_Index == 1)
					prave_prechadzane_cislo_riadku := A_LoopField
				if (A_Index == 2 && prave_prechadzane_cislo_riadku == hladane_cislo_riadku)
					list_navesti[prave_prechadzane_cislo_riadku] := A_LoopField
			}
		}
	}
	return list_navesti
}

ziskaj_pointer_na_nazvy_navesti()
{
	base := 0x400000
	pointerBase := 0x00050800
	arrayPointerOffsets := [0xB84,0x0]
	return pointer := mipsim_obj.getAddressFromOffsets(base + pointerBase, arrayPointerOffsets*)
}

ziskaj_pointer_na_pozicie_navesti()
{
	base := 0x400000
	pointerBase := 0x00050800
	arrayPointerOffsets := [0xB9C,0x0]
	return pointer := mipsim_obj.getAddressFromOffsets(base + pointerBase, arrayPointerOffsets*)
}

ziskaj_pocet_navesti()
{
	base := 0x400000
	pointerBase := 0x00050800
	arrayPointerOffsets := [0xB8C]
	pointer := mipsim_obj.getAddressFromOffsets(base + pointerBase, arrayPointerOffsets*)
	pocet_navesti := mipsim_obj.read(base + pointerBase, "UChar", arrayPointerOffsets*)
	
	return pocet_navesti
}



hex_short_unsigned_na_signed(cislo)
{
   NumPut(cislo, Buffer := "--------", "UInt")
   return NumGet(Buffer, 0, "Short")
}














; Number System Converter by Holle
; http://www.autohotkey.com/forum/viewtopic.php?t=56135
; https://github.com/camerb/AHKs/blob/master/thirdParty/baseConvert.ahk

; Some "names" for the number systems will be accepted such as decimal/dec/d/base10/dekal or
; binary/bin/digital/dual/di/b/base2
; Use can use the names/shortcuts or the "base", like "base10" for decimal or "base2" for binary. 
baseConvert(value, from, to)                        ;the function baseConvert()
{
    if !(value and from and to)                 ;if mising data...
    {
        MsgBox, 4096 , , Missing Parameter! `n`nUse: baseConvert("Value", "From", "To") `n`nExample: `nbaseConvert("55", "dec", "hex")
        Exit
    }                                                      ;else ....
    ;some names for number systems
    base2 = Base2|Binary|Bin|Digital|Binär|Dual|Di|B
    base3 = Base3|Ternary|Triple|Trial|Ternär
    base4 = Base4|Quaternary|Quater|Tetral|Quaternär
    base5 = Base5|Quinary|Pental|Quinär
    base6 = Base6|Senary|Hexal|Senär
    base7 = Base7|Septenary|Peptal|Heptal
    base8 = Base8|Octal|Oktal|Oct|Okt|O
    base9 = Base9|Nonary|Nonal|Enneal
    base10 = Base10|Decimal|Dezimal|Denär|Dekal|Dec|Dez|D
    base11 = Base11|Undenary|Monodecimal|Monodezimal|Hendekal
    base12 = Base12|Duodecimal|Dedezimal|Dodekal
    base13 = Base13|Tridecimal|Tridezimal|Triskaidekal
    base14 = Base14|Tetradecimal|Tetradezimal|Tetrakaidekal
    base15 = Base15|Pentadecimal|Pentadezimal|Pentakaidekal
    base16 = Base16|Hexadecimal|Hexadezimal|Hektakaidekal|Hex|H
    base17 = Base17|Peptaldecimal|Peptaldezimal|Heptakaidekal
    base18 = Base18|Octaldecimal|Oktaldezimal|Octakaidekal|Oktakaidekal
    base19 = Base19|Nonarydecimal|Nonaldezimal|Enneakaidekal
    base20 = Base20|Vigesimal|Eikosal
    base30 = Base30|Triakontal
    base40 = Base40|Tettarakontal
    base50 = Base50|Pentekontal
    base60 = Base60|Sexagesimal|Hektakontal
    StringReplace, value_form, value,(,,all
    StringReplace, value_form, value_form ,),, all          ;if value is integer or letter when...
    if value_form is not Alnum                                       ;...parenthesis are removed
    {                                                                           ; if not...
        MsgBox, 4096 , , Error! `n`nOnly alphanumeric Symbols will be accepted!
        Exit
    }                                                           ;------------------------------------------------------------------------------------
    if (InStr(from, "base"))                                            ;if the word "base" is in "from"...
    {
        StringTrimLeft, base_check, from, 4                   ;...then cut "base" to have ONLY the number
        if base_check is not Integer                               ;if "from" not integer now
        {
            MsgBox, 4096 , , Unknown Number System! `n`nUse Base + Number (example: Base16), `nor the name/shortcut (example: "Hexadecimal" or "Hex")
            Exit
        }
        else                                                                  ;else replace the value from "from"
            from := base_check                                       ;with the number in base_check
    }                                                           ;------------------------------------------------------------------------------------
    if (InStr(to, "base"))                                               ;the same as above again for the destination number system
    {
        StringTrimLeft, base_check, to, 4
        if base_check is not Integer
        {
            MsgBox, 4096 , , Unknown Number System! `n`nUse Base + Number (example: Base16), `nor the name/shortcut (example: "Hexadecimal" or "Hex")
            Exit
        }
        else
            to := base_check
    }                                                           ;---------------------------------------------------------------------------------
    base_loop := 1
    loop, 60                                                ;check in a loop from 2 to 60 if the names from
    {                                                          ;the source / destination number system is in the Variable "base.."
        if from is Integer                               ;if "from" is integer...
            if to is Integer                               ;and "to" too...
                Break                                       ;...cancel the loop
        if (base_loop < 20)                            ;if base_loop < 20...
            base_loop ++                                ;...increase by 1
        else                                                  ;else...
            base_loop += 10                           ;...increase by 10
        if (base_loop > 60)                            ;and if more then 60 ...
            Break                                           ;...cancel the loop
        base := base%base_loop%
        loop parse, base, |                            ;split every base variable word by word
        {
            if (from = A_LoopField)                  ;if one of them identical with the name ...
                from := base_loop                     ;...from the source number system then save the number in "from"
            if (to = A_LoopField)                      ;        ...the same for the destination number system
                to := base_loop
        }
    }
    if (from < 11)                                        ;by source numer system to 10 (therefore Decimal)
        if value is not Integer                         ;letters are not allowed
        {                                                      ;else exit
            StringGetPos, seperator_1, base%from%, |, L1 ;position of the first seperator
            StringGetPos, seperator_2, base%from%, |, L2 ;position of the second seperator...
            StringMid, name_from, base%from%, (seperator_1 + 2), (seperator_2 - seperator_1 - 1)
            MsgBox, 4096 , , Error! `nNo letters allowed in %name_from% system!
            Exit
        }
    con_letter := "ABCDEFGHIJKLMNOPQRSTUVWXYZ" ;allowed letters
    result_dec=
    length := StrLen(value) ;count the characters
    counter := 0
    parenthesis := False    ;no parenthesis yet
    loop, %length%           ;loop by any character from "value"
    {
        StringMid, char, value, (length + 1 - A_Index), 1 ;process "backwards" the value, character by character
        if (char = ")")                                                   ;if there an right parenthesis ...
        {                                                                    ;      (notice, we work "backwards" at this time)
            if parenthesis                                              ;...although there was an right parenthesis before (without a left parenthesis) ...
            {                                                                ;...then exit
                MsgBox, 4096 , , Error!`nOnly "simple" parenthesis will be accepted!`n`nExample:`n57AH6(45)(48)G2 = accepted`n57AH6((45)(48))G2 = NOT accepted!
                Exit
            }
            parenthesis := True                                     ;else memorize that we are between parenthesis now
            Continue                                                     ;...cancel the rest from the loop and continue from begin
        }
        else if (char = "(")                                            ;if there an right parenthesis ...
        {                                                                    ;      (notice, we work "backwards" at this time)
            if !parenthesis                                             ;...although there wasn´t a right parenthesis before...
            {                                                                ;...then exit
                MsgBox, 4096 , , Error!`nOnly "simple" parenthesis will be accepted!`n`nExample:`n57AH6(45)(48)G2 = accepted`n57AH6((45)(48))G2 = NOT accepted!
                Exit
            }
            parenthesis := False                                   ;else memorize that we are NOT between parenthesis now
            if !par_char                                                ;if nothing between the parenthesis...
            {                                                               ;...then exit
                MsgBox, 4096 , , Error! `n No value between parenthesis!
                Exit
            }
            char := par_char                                        ;else, all numbers between parenthesis are ONE character now
        }
        else if parenthesis                                          ;we are between parenthesis at this time...
        {
            if char is not Integer                                   ;...and there is some other than Integer, then cancel
            {
                MsgBox, 4096 , , Error! ´nBetween parenthesis only numbers will be accepted!
                Exit
            }
            par_char := char . par_char                        ;else put every character between the parenthesis to ONE value
            Continue                                                    ;notice, because we work backwards in this loop, the next number will put BEFORE the previous number, ...
        }
        else if char is Alpha                                        ;if there a letter
        {
            StringGetPos, char_pos, con_letter, %char%          ;then check th position from this letter in "con_letter"
            StringReplace, char, char, %char%, %char_pos%   ;and replace the letter with the position-number
            char += 10                                                            ;and add 10
            if (char >= from)
            {                                                                           ;if the number greater than the number system...
                StringGetPos, seperator_1, base%from%, |, L1  ;...Example: 18 in hexadecimal system
                StringGetPos, seperator_2, base%from%, |, L2  ;then exit
                StringMid, name_from, base%from%, (seperator_1 + 2), (seperator_2 - seperator_1 - 1)
                char := from - 10
                StringMid, char, con_letter, %char%, 1
                MsgBox, 4096 , , Error! `nOnly letters until "%char%" will be accepted in %name_from% system!
                Exit
            }
        }
        if (char >= from)   ;is the character at this position isn´t a letter, but a number which is...
        {                          ;...greater than the number system, then exit
            max_value := from - 1
            MsgBox, 4096 , , Error! `nOnly values from 0-%max_value% will be accepted in base%from% system!
            Exit
        }
        result_dec += char * (from**counter)   ;convert source number system to decimale number system
        counter ++                                        ;increase counter by one
    }
    if (to = 10)                                            ;if decimale system the destination number system
        Return %result_dec%                        ;then return the result
    result=                                                  ;else convert it to destination number system
    while (result_dec)
    {       
        char := Mod(result_dec , to)                        ; first number from destination number system
        if (char > 35)                                               ;if it greater than 35...
            char := "(" . char . ")"                               ;...put it between parenthesis
        else if (char > 9)                                          ;if it less than 36 , but greater than 9,
            StringMid, char, con_letter, (char - 9), 1    ;...replace it with a letter
        result :=  char . result                                   ;combine the characters to the result
        result_dec := Floor(result_dec / to)               ;calculate the remain to continue the converting with this
    }
    Return %result%                                             ;return result
}

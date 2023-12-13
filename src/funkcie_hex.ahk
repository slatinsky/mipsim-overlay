
pocet_vykonanych_prevodov = 0

Hex2Dec:
if (pocet_vykonanych_prevodov == 1)
{
	pocet_vykonanych_prevodov = 0
	return
}
pocet_vykonanych_prevodov++	
GuiControlGet, GUI_hex_vstup

StringReplace, GUI_hex_vstup, GUI_hex_vstup, 0X,, All

;msgbox % "Hex2Dec"
GuiControl, , GUI_dec_vstup, % funkcie_hex.hex_do_signed_dec(GUI_hex_vstup)

return






Dec2Hex:
if (pocet_vykonanych_prevodov == 1)
{
	pocet_vykonanych_prevodov = 0
	return
}
pocet_vykonanych_prevodov++
GuiControlGet, GUI_dec_vstup
if (GUI_dec_vstup == "" || GUI_dec_vstup == "-")
	GuiControl, , GUI_hex_vstup, 0
else
	GuiControl, , GUI_hex_vstup, % funkcie_hex.dec_do_signed_hex(GUI_dec_vstup)
;msgbox % "Dec2Hex"

return






class funkcie_hex
{

	bin_do_hex(bin_vstup) {
		Loop, parse, bin_vstup,
		{	
			buffer .= A_LoopField
			if (mod(A_Index,4) == 0) {	;každé 4
				
				if (buffer == "0000")
					hex_vystup .= "0"
				else if (buffer == "0001")
					hex_vystup .= "1"
				else if (buffer == "0010")
					hex_vystup .= "2"
				else if (buffer == "0011")
					hex_vystup .= "3"
				else if (buffer == "0100")
					hex_vystup .= "4"
				else if (buffer == "0101")
					hex_vystup .= "5"
				else if (buffer == "0110")
					hex_vystup .= "6"
				else if (buffer == "0111")
					hex_vystup .= "7"
				else if (buffer == "1000")
					hex_vystup .= "8"
				else if (buffer == "1001")
					hex_vystup .= "9"
				else if (buffer == "1010")
					hex_vystup .= "A"
				else if (buffer == "1011")
					hex_vystup .= "B"
				else if (buffer == "1100")
					hex_vystup .= "C"
				else if (buffer == "1101")
					hex_vystup .= "D"
				else if (buffer == "1110")
					hex_vystup .= "E"
				else if (buffer == "1111")
					hex_vystup .= "F"
				
				buffer = 
			}
		} 
		return %hex_vystup%
	}


	hex_do_bin(hex_vstup) {
		Loop, parse, hex_vstup, ,
		{	
			hex := A_LoopField
		
			if (hex == "0")
				bin_vystup .= 0000
			else if (hex == "1")
				bin_vystup .= 0001
			else if (hex == "2")
				bin_vystup .= 0010
			else if (hex == "3")
				bin_vystup .= 0011
			else if (hex == "4")
				bin_vystup .= 0100
			else if (hex == "5")
				bin_vystup .= 0101
			else if (hex == "6")
				bin_vystup .= 0110
			else if (hex == "7")
				bin_vystup .= 0111
			else if (hex == "8")
				bin_vystup .= 1000
			else if (hex == "9")
				bin_vystup .= 1001
			else if (hex == "a" || hex == "A")
				bin_vystup .= 1010
			else if (hex == "b" || hex == "B")
				bin_vystup .= 1011
			else if (hex == "c" || hex == "C")
				bin_vystup .= 1100
			else if (hex == "d" || hex == "D")
				bin_vystup .= 1101
			else if (hex == "e" || hex == "E")
				bin_vystup .= 1110
			else if (hex == "f" || hex == "F")
				bin_vystup .= 1111
			
		}
		return %bin_vystup%
	}







	

	prevrat_znamienko_hex(hex_vstup,padding){
		;padding = 8	;8 bitový register

		if (velkost_retazca(hex_vstup) > padding) {

			;msgbox % "veľký počet číslic: " . pocet_cislic_vstup
			return "Pretečenie"
		}
		
		hex_vstup := padding_nulami(hex_vstup, 8)

		bin := this.hex_do_bin(hex_vstup)


		vystupna_zaporna_postupnost := this.prevrat_znamienko_bin(bin)
		
		vystup := this.bin_do_hex(vystupna_zaporna_postupnost)

		return vystup
	}

	prevrat_znamienko_bin(bin_vstup) {	;prvý bit zľava je znamienkový
		;otoč postupnosť a prevrat bity
		bin_reversed := this.prevrat_bity(this.otoc_postupnost(bin_vstup))


		;pripočítaj 1
		carry = 1
		Loop, parse, bin_reversed,
		{	
			if (carry == 1) {	;prvý bit
				if (A_LoopField == 1) {	;prvý bit je jedna
					vystup_reversed .= 0
					carry = 1
				}
				else {
					vystup_reversed .= 1
					carry = 0
				}
			}
			else {
				vystup_reversed .= A_LoopField
			}
			;msgbox % vystup_reversed
		}
		vystupna_zaporna_postupnost := this.otoc_postupnost(vystup_reversed)

		;msgbox % bin_vstup "`n" vystupna_zaporna_postupnost
		
		return % vystupna_zaporna_postupnost
	}

	otoc_postupnost(postupnost) {
		;otoč postupnosť
		Loop, parse, postupnost,
		{	
			postupnost_reversed := A_LoopField . postupnost_reversed
		}
		return % postupnost_reversed
	}

	prevrat_bity(slovo) {
		Loop, parse, slovo,
		{	
			if (A_LoopField == 0)
				vystup .= 1
			else
				vystup .= 0
		}
		return % vystup
	}




	hex_do_unsigned_dec(hex){
		dec := "0x" . hex
		dec -= 0 
		SetFormat, integer, d
		return % dec
	}

	dec_do_unsigned_hex( int, pad=0 ) { ; Function by [VxE]. Formats an integer (decimals are truncated) as hex.
	; "Pad" may be the minimum number of digits that should appear on the right of the "0x".
		Static hx := "0123456789ABCDEF"
		If !( 0 < int |= 0 )
			Return !int ? "0x0" : "-" this.dec_do_unsigned_hex( -int, pad )
		s := 1 + Floor( Ln( int ) / Ln( 16 ) )
		h := SubStr( "0x0000000000000000", 1, pad := pad < s ? s + 2 : pad < 16 ? pad + 2 : 18 )
		u := A_IsUnicode = 1
		Loop % s
			NumPut( *( &hx + ( ( int & 15 ) << u ) ), h, pad - A_Index << u, "UChar" ), int >>= 4
		Return h
	}
	
	
		
	hex_do_signed_dec(hex_vstup) {	;pre 8 bitový register
		Loop, parse, hex_vstup,	;over vstup
		{	
			if A_LoopField not contains 0,1,2,3,4,5,6,7,8,9,a,A,b,B,c,C,d,D,e,E,f,F
			{
				return "Zlý vstup"
			}
		}

		StringReplace, hex_vstup, hex_vstup, 0x,,



		hex_vstup := padding_nulami(hex_vstup, 8)

		Loop, parse, hex_vstup, ,
		{	
			prve_cislo := A_LoopField
			break
		}


		hex_vstup := this.hex_do_bin(hex_vstup)



		if prve_cislo not contains 0,1,2,3,4,5,6,7	;záporné čislo
		{
			hex_vstup := this.prevrat_znamienko_bin(hex_vstup)
		}

		hex_vstup := this.bin_do_hex(hex_vstup)

		;tooltip % hex_vstup



		dec_vystup := this.hex_do_unsigned_dec(hex_vstup)


		if prve_cislo not contains 0,1,2,3,4,5,6,7	;záporné čislo
		{
			return -%dec_vystup%
		}
		else {
			return %dec_vystup%
		}


	}
	
	
	dec_do_signed_hex(dec_vstup) {	;pre 8 bitový register

		Loop, parse, dec_vstup,	;over vstup
		{	
			if A_LoopField not contains 0,1,2,3,4,5,6,7,8,9,-
			{
				return "Zlý vstup"
			}
		}

		if (dec_vstup > 2147483647)	;2 na 31 minus jedna
		{
			return "Pretečenie"
		}

		if (dec_vstup <= -2147483649)
		{
			return "Pretečenie"
		}



		hex_vystup := this.dec_do_unsigned_hex(Abs(dec_vstup))
		StringReplace, hex_vystup, hex_vystup, 0x,,

		;tooltip % hex_vystup
		if (dec_vstup < 0) {	
			hex_vystup := this.prevrat_znamienko_hex(hex_vystup, 8)	;8 bitový register
		}
		
		return % hex_vystup

	}

}


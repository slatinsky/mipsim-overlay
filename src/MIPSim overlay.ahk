#SingleInstance force
SetWorkingDir %A_ScriptDir%
SetBatchLines -1
FileEncoding, UTF-8-RAW

SetTitleMatchMode, 3 ;Perfektny match

SetWinDelay, -1
SetControlDelay, -1

#Include classMemory.ahk

global program_verzia := "33"
global program_datum := "13.12.2023"



global SETTINGS_path := A_WorkingDir "\nastavenia.ini"
global SETTINGS_zobrazit_napovedu_tlacidla
global SETTINGS_zobrazit_napovedu_instrukcie
global SETTINGS_zobrazit_kalkulacku



global SETTINGS_DESIATKOVA_SUSTAVA := 0
global SETTINGS_VIAC := 0

global SETTINGS_vymaz_datovu_pamat_bez_dalsieho_opytania
global SETTINGS_vymaz_registre_bez_dalsieho_opytania





IniRead, SETTINGS_DESIATKOVA_SUSTAVA,%SETTINGS_path%, nastavenia, SETTINGS_DESIATKOVA_SUSTAVA, 0
IniRead, SETTINGS_VIAC,%SETTINGS_path%, nastavenia, SETTINGS_VIAC, 0

global REGISTER_A_DATOVA_PAMAT_ZNAK := "0"
IniRead, REGISTER_A_DATOVA_PAMAT_ZNAK,%SETTINGS_path%, nastavenia, REGISTER_A_DATOVA_PAMAT_ZNAK, 0

SysGet, X_BORDER, 32
SysGet, Y_BORDER, 33






Class Zaplaty {
	__New()
	{
		
	}
	
	get_mipsim_obj()
	{
		;----------------Čítanie registrov/pamäte - classMemory.ahk
		;if isObject(mipsim_obj)
		;;{
		;	return mipsim_obj
		;}
		
		mipsim_obj := new _ClassMemory("ahk_id " . mipsim_HWND, "", hProcessCopy) 
		if !isObject(mipsim_obj) 
		{
			msgbox failed to open a handle
			if (hProcessCopy = 0)
				msgbox The program isn't running (not found) or you passed an incorrect program identifier parameter. 
			else if (hProcessCopy = "")
				msgbox OpenProcess failed. If the target process has admin rights, then the script also needs to be ran as admin. Consult A_LastError for more information.
		}
		return mipsim_obj
	}
	
	najdi_smerniky()
	{
		statusbar("Hľadám smerník dátovej časti")
		pointer_pamat := this.ziskaj_pointer_pamat()
		statusbar("Hľadám smerník na registre")
		pointer_register := this.ziskaj_pointer_register()
		statusbar("Hľadám smerník na instrukcie")
		pointer_instrukcie := this.ziskaj_pointer_instrukcie()
	}
	
	ziskaj_pointer_pamat()
	{
		base := 0x400000
		pointerBase := 0x00050800
		arrayPointerOffsets := [0x40, 0x60, 0x328]
		pointer_pamat := mipsim_obj.getAddressFromOffsets(base + pointerBase, arrayPointerOffsets*)
		
		return pointer_pamat
	}

	ziskaj_pointer_register()
	{
		base := 0x400000
		pointerBase := 0x00050800
		arrayPointerOffsets := [0x40, 0x1C, 0x24]
		pointer_register := mipsim_obj.getAddressFromOffsets(base + pointerBase, arrayPointerOffsets*)
		
		return pointer_register
	}

	ziskaj_pointer_instrukcie()
	{
		base := 0x400000
		pointerBase := 0x00050994
		arrayPointerOffsets := [0x1AC, 0x0]
		pointer_instrukcie := mipsim_obj.getAddressFromOffsets(base + pointerBase, arrayPointerOffsets*)
		
		return pointer_instrukcie
	}
	
	aplikuj_zaplaty() {
		this.aplikuj_zaplatu("uloz_help_na_adresu_44D6F4")
		this.aplikuj_zaplatu("LW_SW_invalid_parameter_fix")
		this.aplikuj_zaplatu("LW_fix_pre_adresy_vacsie_ako_0xff")
		this.aplikuj_zaplatu("vymaz_datovu_pamat_bez_dalsieho_opytania")
		this.aplikuj_zaplatu("vymaz_operacny_kod_bez_dalsieho_opytania")
		this.aplikuj_zaplatu("vymaz_registre_bez_dalsieho_opytania")
		this.aplikuj_zaplatu("prepis_subory_bez_dalsieho_opytania")
		this.aplikuj_zaplatu("povol_ulozenie_prazdneho_operacneho_kodu")
		this.aplikuj_zaplatu("povol_ulozenie_prazdnej_pamate")
	}
	
	toggle_zaplata(meno_zaplaty) 
	{
		IniRead, SETTINGS_%meno_zaplaty%,%SETTINGS_path%, nastavenia, SETTINGS_%meno_zaplaty%, 1
		if (SETTINGS_%meno_zaplaty% == 1)
			toggled := 0	;deaktivuj záplatu, keďže bola aktivovaná
		else
			toggled := 1	;aktivuj záplatu, keďže bola deaktivovaná
		IniWrite, %toggled%,%SETTINGS_path%, nastavenia, SETTINGS_%meno_zaplaty%
		
		this.aplikuj_zaplatu(meno_zaplaty)
	}
	
	aplikuj_zaplatu(meno_zaplaty)
	{
		IniRead, SETTINGS_%meno_zaplaty%,%SETTINGS_path%, nastavenia, SETTINGS_%meno_zaplaty%, 1
		if (SETTINGS_%meno_zaplaty% == 1)
			aktivacia := 1	;aktivuj záplatu
		else
			aktivacia := 0	;deaktivuj záplatu
		GuiControl, 12:, SETTINGS_%meno_zaplaty%, %aktivacia%	;aktualizuj checkbox v gui
		
		
		
		static base := 0x400000
		
		if !isObject(mipsim_obj) 
		{
			return
		}
		
		;Parse .1337 súborov z x64dbg debuggera
		if(FileExist(A_WorkingDir . "\zaplaty\" . meno_zaplaty ".1337"))
		{
			fileread, zaplata_text, % A_WorkingDir . "\zaplaty\" . meno_zaplaty ".1337"
			
			Loop, parse, zaplata_text, `n,
			{	
				if (A_Index != 1 && A_LoopField != "")
				{
					
					zaplata := A_LoopField
					StringReplace, zaplata, zaplata,:,~,
					StringReplace, zaplata, zaplata,->,~,
					StringReplace, zaplata, zaplata,`n,,
					StringReplace, zaplata, zaplata,`r,,
					Loop, parse, zaplata, ~,
					{	
						if (A_Index == 1)
							offset := funkcie_hex.hex_do_unsigned_dec(A_LoopField)
						else if (A_Index == 2 && aktivacia == 0)
							hodnota_hex := funkcie_hex.hex_do_unsigned_dec(A_LoopField)
						else if (A_Index == 3 && aktivacia == 1)
							hodnota_hex := funkcie_hex.hex_do_unsigned_dec(A_LoopField)
					}
					
					mipsim_obj.write(base + offset,hodnota_hex, "UChar")	;zaplátaj pamäť MIPSimu
					;zapisana_hodnota := mipsim_obj.read(base + offset, "UChar")	;prečítaj hodnotu naspäť
				}
			}
			
		}
		else
		{
			msgbox % "Záplata " meno_zaplaty " neexistuje"
		}
	}
}


global mipsim_HWND
global mipsim_PID
global flag_obvod_patch_zmeneny
Class Startup {
	__New()
	{
		
	}
	
	nainstaluj_dependencies()
	{	
		;zložky
		FileCreateDir, grafika
		FileCreateDir, MIPSim
		FileCreateDir, programy
		FileCreateDir, zaplaty
		FileCreateDir, help

		;grafika
		FileInstall, grafika/breakpoint.png, %a_workingdir%/grafika/breakpoint.png, 0
		FileInstall, grafika/breakpoint_aktivny.png, %a_workingdir%/grafika/breakpoint_aktivny.png, 0
		FileInstall, grafika/po_bod.png, %a_workingdir%/grafika/po_bod.png, 0
		FileInstall, grafika/po_bod_p.png, %a_workingdir%/grafika/po_bod_p.png, 0
		FileInstall, grafika/run.png, %a_workingdir%/grafika/run.png, 0
		FileInstall, grafika/run_p.png, %a_workingdir%/grafika/run_p.png, 0
		FileInstall, grafika/stop.png, %a_workingdir%/grafika/stop.png, 0
		FileInstall, grafika/stop_p.png, %a_workingdir%/grafika/stop_p.png, 0
		FileInstall, grafika/top.png, %a_workingdir%/grafika/top.png, 0
		FileInstall, grafika/top_p.png, %a_workingdir%/grafika/top_p.png, 0
		FileInstall, grafika/nastavenia.png, %a_workingdir%/grafika/nastavenia.png, 0
		FileInstall, grafika/registre+datova_pamat.png, %a_workingdir%/grafika/registre+datova_pamat.png, 0


		FileInstall, grafika/x_data.png, %a_workingdir%/grafika/x_data.png, 0
		FileInstall, grafika/x_data_p.png, %a_workingdir%/grafika/x_data_p.png, 0
		FileInstall, grafika/x_register.png, %a_workingdir%/grafika/x_register.png, 0
		FileInstall, grafika/x_register_p.png, %a_workingdir%/grafika/x_register_p.png, 0
		FileInstall, grafika/mipsim.ico, %a_workingdir%/grafika/mipsim.ico, 0



		;MIPSim zaplátaný s mensi_obvod.1337
		FileInstall, MIPSim/MIPSIM32.EXE, %a_workingdir%/MIPSim/MIPSIM32.EXE, 0
		FileInstall, MIPSim/RA_CPU.SCH, %a_workingdir%/MIPSim/RA_CPU.SCH, 0
		FileInstall, MIPSim/MIPSIM32.GID, %a_workingdir%/MIPSim/MIPSIM32.GID, 0
		FileInstall, MIPSim/MIPSIM32.HLP, %a_workingdir%/MIPSim/MIPSIM32.HLP, 0

		;Záplaty
		FileInstall, zaplaty/uloz_help_na_adresu_44D6F4.1337, %a_workingdir%/zaplaty/uloz_help_na_adresu_44D6F4.1337, 0
		FileInstall, zaplaty/LW_fix_pre_adresy_vacsie_ako_0xff.1337, %a_workingdir%/zaplaty/LW_fix_pre_adresy_vacsie_ako_0xff.1337, 0
		FileInstall, zaplaty/LW_SW_invalid_parameter_fix.1337, %a_workingdir%/zaplaty/LW_SW_invalid_parameter_fix.1337, 0
		FileInstall, zaplaty/povol_ulozenie_prazdneho_operacneho_kodu.1337, %a_workingdir%/zaplaty/povol_ulozenie_prazdneho_operacneho_kodu.1337, 0
		FileInstall, zaplaty/povol_ulozenie_prazdnej_pamate.1337, %a_workingdir%/zaplaty/povol_ulozenie_prazdnej_pamate.1337, 0
		FileInstall, zaplaty/prepis_subory_bez_dalsieho_opytania.1337, %a_workingdir%/zaplaty/prepis_subory_bez_dalsieho_opytania.1337, 0
		FileInstall, zaplaty/vymaz_datovu_pamat_bez_dalsieho_opytania.1337, %a_workingdir%/zaplaty/vymaz_datovu_pamat_bez_dalsieho_opytania.1337, 0
		FileInstall, zaplaty/vymaz_operacny_kod_bez_dalsieho_opytania.1337, %a_workingdir%/zaplaty/vymaz_operacny_kod_bez_dalsieho_opytania.1337, 0
		FileInstall, zaplaty/vymaz_registre_bez_dalsieho_opytania.1337, %a_workingdir%/zaplaty/vymaz_registre_bez_dalsieho_opytania.1337, 0
		
		;help obrázky
		FileInstall, help/assembler_window.png, %a_workingdir%/help/assembler_window.png, 0
		FileInstall, help/data_window.png, %a_workingdir%/help/data_window.png, 0
		FileInstall, help/main_window.png, %a_workingdir%/help/main_window.png, 0
		FileInstall, help/register_window.png, %a_workingdir%/help/register_window.png, 0

		; Presuň naspäť zaplátaný MIPSim
		if(FileExist("MIPSim\MIPSIM32_upraveny.EXE"))
		{
			FileMove, MIPSim\MIPSIM32_upraveny.EXE, MIPSim\MIPSIM32.EXE, 1
			flag_obvod_patch_zmeneny = 1
		}
	}
	
	spusti_MIPSim()
	{
		if !(WinExist("ahk_exe MIPSIM32.EXE")) {	;Získaj HWND MIPSIMU, ak nie je spustený, spusti ho
			IfExist, %a_workingdir%\MIPSim\MIPSIM32.EXE
			{
			
				run, MIPSim\MIPSIM32.EXE
			
				WinWait, MIPSim
				sleep 100
				if !(WinExist("ahk_exe MIPSIM32.EXE")) {
					MsgBox 0x42010, , MIPSIM32.EXE nie je zapnutý
					exitapp
				}
			}
			else {
				MsgBox 0x42010, , MIPSIM32.EXE nenájdený v zložke MIPSim\%a_workingdir%
				exitapp
			}
		}
		else
		{
			;MIPSim je zapnutý, zavri tieto okná, aby sa program pripol len na to hlavné
			winclose, Register
			winclose, assembler
			winclose, data memory
		}
		
		WinGet, mipsim_HWND, ID, ahk_exe MIPSIM32.EXE
		WinGet, mipsim_PID, PID, ahk_id %mipsim_HWND%

	}
	
}


Class Graficke_rozhranie {
	__New(){

	}
	
	

	vypocitaj_toolbar_window_offset()
	{
		winactivate, ahk_id %mipsim_HWND%	;ak neaktivujem okno MIPSIMU pred prečítaním polohy Y_ToolbarWindow321 -> dostanem nulu, nie hodnotu, ktorú chcem
		ControlGetPos , X_ToolbarWindow321, Y_ToolbarWindow321, Width_ToolbarWindow321, Height_ToolbarWindow321, ToolbarWindow321, ahk_id %mipsim_HWND%
		BORDER_OFFSET := X_ToolbarWindow321
		Y_OFFSET := round(Y_ToolbarWindow321 / DPI_nasobitel)
	}
	
	vytvor_tray_menu()
	{
		;Tray menu
		Menu, Tray, Icon, shell32.dll, 25
		Menu, Tray, Icon, grafika\mipsim.ico

		menu, tray, NoStandard
		Menu, tray, Add, Informácie o MIPSim overlay, info
		Menu, tray, Add, Konfigurácia, config
		menu, tray, add
		Menu, tray, Add, Reštartovať, Reload
		Menu, tray, Add, Ukončiť, GuiClose

		Menu, tray, Icon, Ukončiť, imageres.dll , 162	;X
		Menu, tray, Icon, Konfigurácia, imageres.dll , 65	;Nastavenia
		Menu, tray, Icon, Informácie o MIPSim overlay, imageres.dll , 77	;Info
		Menu, tray, Icon, Reštartovať, shell32.dll , 239
	}
	
	vytvor_nastavenia_gui()
	{
		global
		IniRead, SETTINGS_zobrazit_napovedu_tlacidla,%SETTINGS_path%, nastavenia, SETTINGS_zobrazit_napovedu_tlacidla, 1
		IniRead, SETTINGS_zobrazit_napovedu_instrukcie,%SETTINGS_path%, nastavenia, SETTINGS_zobrazit_napovedu_instrukcie, 1
		IniRead, SETTINGS_zobrazit_kalkulacku,%SETTINGS_path%, nastavenia, SETTINGS_zobrazit_kalkulacku, 1

		IniRead, SETTINGS_zmena_velkosti_obvodu_patch,%SETTINGS_path%, nastavenia, SETTINGS_zmena_velkosti_obvodu_patch, 4


		Gui, 12: -MaximizeBox
		Gui, 12: -MinimizeBox
		Gui, 12:Add, GroupBox, x15 y10 w285 h90, Grafické rozhranie
		Gui, 12:Add, Checkbox, x25 y30 w265 h15 checked%SETTINGS_zobrazit_napovedu_tlacidla% vSETTINGS_zobrazit_napovedu_tlacidla gSETTINGS_zobrazit_napovedu_tlacidla, Zobraziť nápovedu k tlačidlám
		Gui, 12:Add, Checkbox, x25 y50 w265 h15 checked%SETTINGS_zobrazit_napovedu_instrukcie% vSETTINGS_zobrazit_napovedu_instrukcie gSETTINGS_zobrazit_napovedu_instrukcie, Zobraziť nápovedu k inštrukciám
		Gui, 12:Add, Checkbox, x25 y70 w265 h15 checked%SETTINGS_zobrazit_kalkulacku% vSETTINGS_zobrazit_kalkulacku gSETTINGS_zobrazit_kalkulacku, Zobraziť kalkulačku
		; 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3

		temp_moznosti = 0`%|6.25`%|12.5`%|18.75`%|25`%|31.25`%|37.5`%|43.75`%|50`%|56.25`%|62.5`%|68.75`%|75`%|81.25`%

		Loop, parse, temp_moznosti, |,
		{	
			moznosti .= A_LoopField . "|"
			if (SETTINGS_zmena_velkosti_obvodu_patch == A_Index)
				moznosti .= "|"
		}

		Gui, 12:Add, Text, x25 y120 w85 h15, Zmenši obvod o:
		Gui, 12:Add, DropDownList, x110 y117 w65 altsubmit vGUI_zmena_velkosti_obvodu_patch gzmena_velkosti_obvodu_patch, %moznosti%
		Gui, 12:Add, Text, x180 y120 w200 h13, (Reštartuje sa MIPSim!)

		Gui, 12:Add, GroupBox, x15 y100 w285 h110, Opravy chýb
		Gui, 12:Add, Checkbox, x25 y140 w265 h15 vSETTINGS_uloz_help_na_adresu_44D6F4 gSETTINGS_uloz_help_na_adresu_44D6F4, Nahraď nefunkčný Windows help
		Gui, 12:Add, Checkbox, x25 y160 w265 h15 vSETTINGS_LW_SW_invalid_parameter_fix gSETTINGS_LW_SW_invalid_parameter_fix, Inštrukcie LW a SW - invalid parameter fix
		Gui, 12:Add, Checkbox, x25 y180 w265 h15 vSETTINGS_LW_fix_pre_adresy_vacsie_ako_0xff gSETTINGS_LW_fix_pre_adresy_vacsie_ako_0xff, inštrukcia LW - fix pre adresy väčšie ako 0xff
		Gui, 12:Add, GroupBox, x15 y210 w285 h105, Odstránenie potvrdzovacích dialógov
		Gui, 12:Add, Checkbox, x25 y230 w265 h15 vSETTINGS_vymaz_operacny_kod_bez_dalsieho_opytania gSETTINGS_vymaz_operacny_kod_bez_dalsieho_opytania, Pri mazaní operačného kódu
		Gui, 12:Add, Checkbox, x25 y250 w265 h15 vSETTINGS_vymaz_datovu_pamat_bez_dalsieho_opytania gSETTINGS_vymaz_datovu_pamat_bez_dalsieho_opytania, Pri mazaní dátovej pamäte
		Gui, 12:Add, Checkbox, x25 y270 w265 h15 vSETTINGS_vymaz_registre_bez_dalsieho_opytania gSETTINGS_vymaz_registre_bez_dalsieho_opytania, Pri mazaní registrov
		Gui, 12:Add, Checkbox, x25 y290 w265 h15 vSETTINGS_prepis_subory_bez_dalsieho_opytania gSETTINGS_prepis_subory_bez_dalsieho_opytania, Pri prepisovaní existujúceho súboru
		Gui, 12:Add, GroupBox, x15 y315 w285 h65, Iné
		Gui, 12:Add, Checkbox, x25 y335 w265 h15 vSETTINGS_povol_ulozenie_prazdneho_operacneho_kodu gSETTINGS_povol_ulozenie_prazdneho_operacneho_kodu, Povoľ uloženie prázdneho operačného kódu
		Gui, 12:Add, Checkbox, x25 y355 w265 h15 vSETTINGS_povol_ulozenie_prazdnej_pamate gSETTINGS_povol_ulozenie_prazdnej_pamate, Povoľ uloženie prázdnej pamäte
		Gui, 12:Add, Text, x15 y385 w280 h20, (Nastavenia sa automaticky aplikujú)
	}
	
	vytvor_overlay_gui()
	{
		global
		Gui -Caption
		;gui, +E0x20	;Click throught
		Gui, Color, 000066
		Gui +LastFound
		WinSet, TransColor, 000066

		


		pozicia_x := this.overlay_gui_vypocitaj_poziciu_tlacidiel(12, 2)
		this.overlay_gui_oddelovac(this.overlay_gui_vypocitaj_poziciu_tlacidiel(12, 2))


		pozicia_y := Y_OFFSET + 3
		pozicia_y_hore := Y_OFFSET + 3 - 27

		pozicia_x := this.overlay_gui_vypocitaj_poziciu_tlacidiel(6, 2)
		Gui, Add, Picture, x%pozicia_x% y%pozicia_y% w25 h24 gSTOP vGUI_PAUSE, grafika/stop.png	;pause
		pozicia_x := this.overlay_gui_vypocitaj_poziciu_tlacidiel(7, 2)
		Gui, Add, Picture, x%pozicia_x% y%pozicia_y% w25 h24 gTop vGUI_Top, grafika/top.png	;stop


		pozicia_x := this.overlay_gui_vypocitaj_poziciu_tlacidiel(11, 2)
		Gui, Add, Picture, x%pozicia_x% y%pozicia_y% w25 h24 gVykonajPoPoziciu vGUI_VykonajPoPoziciu, grafika/run.png	;tripple

		pozicia_x := this.overlay_gui_vypocitaj_poziciu_tlacidiel(12, 3)
		Gui, Add, Picture, x%pozicia_x% y%pozicia_y% w25 h24 gvymaz_registre vGUI_vymaz_registre, grafika/x_register.png
		pozicia_x := this.overlay_gui_vypocitaj_poziciu_tlacidiel(13, 3)
		Gui, Add, Picture, x%pozicia_x% y%pozicia_y% w25 h24 gvymaz_data vGUI_vymaz_data, grafika/x_data.png

		pozicia_x := this.overlay_gui_vypocitaj_poziciu_tlacidiel(14, 4)
		Gui, Add, Picture, x%pozicia_x% y%pozicia_y% w50 h24 gotvor_live_pamat vGUI_registre_plus_datova_pamat, grafika/registre+datova_pamat.png
		pozicia_x := this.overlay_gui_vypocitaj_poziciu_tlacidiel(16, 5)
		Gui, Add, Picture, x%pozicia_x% y%pozicia_y% w25 h24 gotvor_nastavenia vGUI_nastavenia, grafika/nastavenia.png




		



		Gui, Add, Text, % "x517 y" pozicia_y + 3 "w360 h20 vGUI_opozdenie_text ", Po nájdení breakpointu zastaviť na:
		Gui, Add, DropDownList, x695 y%pozicia_y% w75 altsubmit vGUI_opozdenie, Začiatok|Fetch|Decode|Execute|Memory|Writeback||

		GuiControl, hide, GUI_opozdenie
		GuiControl, hide, GUI_opozdenie_text

		Gui, Font, s10


		Gui, Add, Text, x790 y%pozicia_y_hore% w220 h15 vGUI_popis_hex_do_dec, HEX              <-->              DEC

		Gui, Add, Edit, x790 y%pozicia_y% w80 h20 limit8 Uppercase vGUI_hex_vstup gHex2Dec, 0
		Gui, Add, Edit, x875 y%pozicia_y% w90 h20 limit11 vGUI_dec_vstup gDec2Hex, 0
		if (SETTINGS_zobrazit_kalkulacku == 0) {
			GuiControl, hide, GUI_popis_hex_do_dec
			GuiControl, hide, GUI_hex_vstup
			GuiControl, hide, GUI_dec_vstup
		}
		WinSetTitle, ahk_id %mipsim_HWND%,, Bez názvu - MIPSim


		Gui, Add, Button, x955 y57 w300 h20 gProgramDoSchranky vGUI_ProgramDoSchranky, Skopíruj operačnú pamäť do schránky 
		Gui, Add, Button, x955 y57 w175 h40 gRegistreDoSchranky vGUI_RegistreDoSchranky, Skopíruj registre do schránky 
		GuiControl, hide, GUI_ProgramDoSchranky
		GuiControl, hide, GUI_RegistreDoSchranky

		Gui, Font, s11
	}
	
	overlay_gui_vypocitaj_poziciu_tlacidiel(pozicia, medzier)
	{
		ZACIATOCNY_OFFSET := 16
		VELKOST_TLACIDLO := 25
		VELKOST_MEDZERA := 16
		
		return % round(ZACIATOCNY_OFFSET + (pozicia - 1) * VELKOST_TLACIDLO + medzier * VELKOST_MEDZERA)
	}
	
	overlay_gui_oddelovac(pozicia_x)
	{
		pozicia_y := Y_OFFSET + 3
		Gui, Add, Progress, x%pozicia_x% y%pozicia_y% w16 h25 cF0F0F0 Range0-100, 100
	}
	
	
	vytvor_live_registre_a_pamat_gui() 
	{
		global
		try
			Gui, 8: +owner%mipsim_HWND%
		catch {	;overlay má nižšie povolenia ako MIPSIM32.EXE proces
			msgbox % "Operačný systém nepovolil pripnutie MIPSIM overlay k MIPSimu.`n`nMožná príčina: `nJe spustený proces MIPSIM32.EXE overlay pod rovnakými oprávneniami ako MIPSIM overlay? (MIPSIM overlay potrebuje čítať a zapisovať priamo do pamäte originálneho MIPSimu - preto MIPSim overlay potrebuje vyššie alebo aspoň rovnaké oprávnenie)`n`nRiešenie:`nZabite proces MIPSIM32.EXE a spustite MIPSIM overlay odznova`n`nAk program emulujete na inom operačnom systéme ako Windows, použite len originálny MIPSim/MIPSIM32.EXE bez overlay"
			exitapp
		}
		Gui, 8: -MaximizeBox
		Gui, 8: -MinimizeBox
		Gui, 8:Font, s8 ,consolas  ; Set 10-point Verdana.
		Gui, 8:Add, Checkbox, x215 y2 w135 h20 vSETTINGS_DESIATKOVA_SUSTAVA gSETTINGS_DESIATKOVA_SUSTAVA checked%SETTINGS_DESIATKOVA_SUSTAVA%, Desiatková sústava
		Gui, 8:Add, Checkbox, x350 y2 w135 h20 vSETTINGS_VIAC gSETTINGS_DESIATKOVA_SUSTAVA checked%SETTINGS_VIAC%, Viac
		Gui, 8:Add, Text, x10 y5 w95 h20, Registre:
		Gui, 8:Add, Text, x120 y5 w80 h20, Dátová pamäť:
		Gui, 8:Add, Edit, x5 y25 w110 h430 ReadOnly -VScroll vGUI_registre Hwndgui_hwnd_registre, 

		Gui, 8:Add, Edit, x120 y25 w270 h430 ReadOnly -VScroll vGUI_data Hwndgui_hwnd_data_1, 
		Gui, 8:Add, Edit, x395 y25 w270 h430 ReadOnly -VScroll vGUI_data2 Hwndgui_hwnd_data_2, 
		
		Gui, 8:Add, Button, x5 y460 w35 h25 vGUI_uloz_stav_registrov guloz_stav_registrov, Ulož
		Gui, 8:Add, Button, x45 y460 w70 h25 vGUI_obnov_stav_registrov gobnov_stav_registrov, Obnov
		
		Gui, 8:Add, Button, x130 y460 w35 h25 vGUI_uloz_stav_datovej_pamate guloz_stav_datovej_pamate, Ulož
		Gui, 8:Add, Button, x170 y460 w70 h25 vGUI_obnov_stav_datovej_pamate gobnov_stav_datovej_pamate, Obnov
		
		Gui, 8:Add, Button, x320 y460 w70 h25 vGUI_editor_help, Help
	}
	
	resize_live_registre_a_pamat_gui()
	{
		if(SETTINGS_DESIATKOVA_SUSTAVA)
			width := 325
		else
			width := 270
		
		GuiControl 8:Move, GUI_data, x120 y25 w%width%
		x_pos := 120 + width + 5
		if(SETTINGS_VIAC)
		{
			
			GuiControl 8:Move, GUI_data2, x%x_pos% y25 w%width%
			x_pos += width + 5
			GuiControl 8:Show, GUI_data2
		}
		else
		{
			GuiControl 8:Hide, GUI_data2
		}

		Gui, 8:Show, w%x_pos% h490, Registre + dátová pamäť
	}
}


Class Tooltip {
	tooltip_instrukcia_pod_mysou := ""
	tooltip_pomoc_tlacidla := ""
	
	ukaz_tooltip(){
		static tooltip_instrukcia_pod_mysou_old := ""
		static tooltip_pomoc_tlacidla_old := ""
		
		if (this.tooltip_instrukcia_pod_mysou != tooltip_instrukcia_pod_mysou_old || this.tooltip_pomoc_tlacidla != tooltip_pomoc_tlacidla_old)	;tooltip sa zmenil
		{
			tooltip % this.tooltip_instrukcia_pod_mysou . this.tooltip_pomoc_tlacidla
			tooltip_instrukcia_pod_mysou_old := this.tooltip_instrukcia_pod_mysou
			tooltip_pomoc_tlacidla_old := this.tooltip_pomoc_tlacidla
		}
	}

	ukaz_tooltip_instrukcia_pod_mysou() 
	{
		CoordMode, mouse , window
		MouseGetPos , OutputVarX, OutputVarY, okno_pod_mysou, control_pod_mysou,
		if (control_pod_mysou == "ListBox2")
		{
			;356 47
			ControlGetPos,,,, hUkazovatel, Afx:400000:0:10003:0:01, ahk_id %mipsim_HWND%
			pozicia_scrollbaru := getPoziciaScrollbaru_instrukcie()
			ControlGetPos , X_ListBox2, Y_ListBox2, Width_ListBox2, Height_ListBox2, ListBox2, assembler
			aktualna_pozicia := floor(((OutputVarY - Y_ListBox2) / hUkazovatel) + pozicia_scrollbaru)
			;tooltip % aktualna_pozicia "|" OutputVarY - Y_ListBox2
			;return
			
			if (aktualna_pozicia >= 0 && aktualna_pozicia <= 23) {
				instrukcia_nazov := ""
				instrukcia_syntax := ""
				instrukcia_pseudokod := ""
				instrukcia_priklad_popis := ""
				instrukcia_priklad := ""
				
				
				if (aktualna_pozicia == 0) {
					instrukcia_nazov := "Add"
					instrukcia_popis := "Sčítanie registrov $R2 a $R3"
					instrukcia_syntax := "ADD $R1, $R2, $R3`n(v kóde to píšte bez R - piaty register je napr. $5)"
					instrukcia_pseudokod := "$R1 = $R2 + $R3;"
				}
				else if (aktualna_pozicia == 1) {
					instrukcia_nazov := "Add immediate"
					instrukcia_popis := "Pripočíta k registru $R2 konštantu"
					instrukcia_syntax := "ADDI $R1, $R2, const"
					instrukcia_pseudokod := "$R1 = $R2 + const;"
				}
				else if (aktualna_pozicia == 2) {
					instrukcia_nazov := "Bitwise and"
					instrukcia_popis := "Bitový súčin registrov $R2 a $R3"
					instrukcia_syntax := "AND $R1, $R2, $R3"
					instrukcia_pseudokod := "$R1 = AND($R2, $R3);"
				}
				else if (aktualna_pozicia == 3) {
					instrukcia_nazov := "Bitwise and immediate"
					instrukcia_popis := "Bitový súčin registra $R2 a konštanty"
					instrukcia_syntax := "ANDI $R1, $R2, const"
					instrukcia_pseudokod := "$R1 = AND($R2, const);"
				}
				else if (aktualna_pozicia == 4) {
					instrukcia_nazov := "Branch on equal"
					instrukcia_popis := "Skok ak sa registre $R1 a $R2 rovnajú"
					instrukcia_syntax := "BEQ $R1, $R2, OFFSET`nBEQ $R1, $R2, nazov_navestia"
					instrukcia_pseudokod := "if($R1 == $R2) `n{`n	goto nazov_navestia;`n}"
				}
				else if (aktualna_pozicia == 5) {
					instrukcia_nazov := "Branch on not equal"
					instrukcia_popis := "Skok ak sa registre $R1 a $R2 nerovnajú"
					instrukcia_syntax := "BNEQ $R1, $R2, OFFSET`nBNEQ $R1, $R2, nazov_navestia"
					instrukcia_pseudokod := "if($R1 != $R2) `n{`n	goto nazov_navestia;`n}"
				}
				else if (aktualna_pozicia == 6) {
					instrukcia_nazov := "Divide"
					instrukcia_popis := "Celočíselné delenie registrov $R2 a $R3"
					instrukcia_syntax := "DIV $R1, $R2, $R3"
					instrukcia_pseudokod := "$R1 = floor($R2 / $R3);"
				}
				else if (aktualna_pozicia == 7) {
					instrukcia_nazov := "Divide unsigned"
					instrukcia_popis := "Celočíselné delenie nezáporných registrov $R2 a $R3"
					instrukcia_syntax := "DIVU $R1, $R2, $R3"
					instrukcia_pseudokod := "$R1 = floor($R2 / $R3);"
				}
				else if (aktualna_pozicia == 8) {
					instrukcia_nazov := "Load immediate"
					instrukcia_popis := "Načíta do posledných 16 bitov registra $R1 konštantu, ostatné bity vynuluje"
					instrukcia_syntax := "LI $R1, const"
					instrukcia_pseudokod := "$R1 = const"
				}
				else if (aktualna_pozicia == 9) {
					instrukcia_nazov := "Load upper immediate"
					instrukcia_popis := "Načíta do prvých 16 bitov registra konštantu, ostatné bity vynuluje"
					instrukcia_syntax := "LUI $R1, const"
					instrukcia_pseudokod := "$R1 = const << 16" 
				}
				
				else if (aktualna_pozicia == 10) {
					instrukcia_nazov := "Load word"
					instrukcia_popis := "Načíta hodnotu z dátovej pamäte (z adresy OFFSET + $R2) do registra $R1.`nOFFSET je číselná konštanta, nie funkcia"
					instrukcia_syntax := "LW $R1, OFFSET($R2)"
					instrukcia_pseudokod := "$R1 = *(OFFSET + $R2);"
				}
				else if (aktualna_pozicia == 11) {
					instrukcia_nazov := "Multiply"
					instrukcia_popis := "Násobenie registrov $R2 a $R3"
					instrukcia_syntax := "MUL $R1, $R2, $R3"
					instrukcia_pseudokod := "$R1 = $R2 * $R3;"
				}
				else if (aktualna_pozicia == 12) {
					instrukcia_nazov := "Multiply unsigned"
					instrukcia_syntax := "MULU $R1, $R2, $R3"
					instrukcia_popis := "Násobenie nezáporných registrov $R2 a $R3"
					instrukcia_pseudokod := "$R1 = $R2 * $R3;"
				}
				else if (aktualna_pozicia == 13) {
					instrukcia_nazov := "No operation"
					instrukcia_popis := "Žiadna akcia ¯\_(ツ)_/¯ (okrem inkrementácie registra 'program counter' o 4)  "
					instrukcia_syntax := "NOP"
				}
				else if (aktualna_pozicia == 14) {
					instrukcia_nazov := "Bitwise nor"
					instrukcia_popis := "Negovaný bitový súčet registrov $R2 a $R3"
					instrukcia_syntax := "NOR $R1, $R2, $R3"
					instrukcia_pseudokod := "$R1 = NOT(OR($R2, $R3));`n$R1 = NOT($R2) AND NOT($R3); //De Morgan"
				}
				else if (aktualna_pozicia == 15) {
					instrukcia_nazov := "Bitwise or"
					instrukcia_popis := "Bitový súčet registrov $R2 a $R3"
					instrukcia_syntax := "OR $R1, $R2, $R3"
					instrukcia_pseudokod := "$R1 = OR($R2, $R3);"
				}
				
				else if (aktualna_pozicia == 16) {
					instrukcia_nazov := "Bitwise or immediate"
					instrukcia_popis := "Bitový súčet registra $R2 a konštanty"
					instrukcia_syntax := "ORI $R1, $R2, const"
					instrukcia_pseudokod := "$R1 = OR($R2, const);"
				}
				
				else if (aktualna_pozicia == 17) {
					instrukcia_nazov := "Shift left logical variable"
					instrukcia_popis := "Logický bitový posun doľava. Všetky bity registra $R2 sa posunú o $R3 bitov doľava a na vzniknuté voľné miesto vpravo sa vloží nula"
					instrukcia_syntax := "SLLV $R1, $R2, $R3"
					instrukcia_pseudokod := "$R1 = $R2 << $R3;`n(z toho vyplýva) $R1 = $R2 * 2^$R3;"
				}
				else if (aktualna_pozicia == 18) {
					instrukcia_nazov := "Shift right logical variable"
					instrukcia_popis := "Logický bitový posun doprava. Všetky bity registra $R2 sa posunú o $R3 bitov doprava a na vzniknuté voľné miesto vľavo sa vloží nula"
					instrukcia_syntax := "SRLV $R1, $R2, $R3"
					instrukcia_pseudokod := "$R1 = $R2 >> $R3;`n(z toho vyplýva) $R1 = $R2 / 2^$R3;"
				}
				if (aktualna_pozicia == 19) {
					instrukcia_nazov := "Subtract"
					instrukcia_popis := "Odčítanie registra $R3 od registra $R2"
					instrukcia_syntax := "SUB $R1, $R2, $R3"
					instrukcia_pseudokod := "$R1 = $R2 - $R3;"
				}
				else if (aktualna_pozicia == 20) {
					instrukcia_nazov := "Subtract immediate"
					instrukcia_popis := "Odčítanie konštanty od registra $R2"
					instrukcia_syntax := "SUBI $R1, $R2, const"
					instrukcia_pseudokod := "$R1 = $R2 - const;"
				}
				else if (aktualna_pozicia == 21) {
					instrukcia_nazov := "Store word"
					instrukcia_popis := "Uloží hodnotu z registra $R1 do dátovej pamäte (na adresu OFFSET + $R2)"
					instrukcia_syntax := "SW $R1, OFFSET($R2)"
					instrukcia_pseudokod := "*(OFFSET + $R2) = $R1;"
				}
				else if (aktualna_pozicia == 22) {
					instrukcia_nazov := "Bitwise exclusive or"
					instrukcia_popis := "Exkluzívny bitový súčet registrov $R2 a $R3"
					instrukcia_syntax := "XOR $R1, $R2, $R3"
					instrukcia_pseudokod := "$R1 = XOR($R2, $R3);"
				}
				
				else if (aktualna_pozicia == 23) {
					instrukcia_nazov := "Bitwise exclusive or immediate"
					instrukcia_popis := "Exkluzívny bitový súčet registra $R2 a konštanty"
					instrukcia_syntax := "XORI $R1, $R2, const"
					instrukcia_pseudokod := "$R1 = XOR($R2, const);"
				}
				
				
				static popis_instrukcii_old
				popis_instrukcii =
				if (instrukcia_nazov != "")
				{
					popis_instrukcii := instrukcia_nazov
					if (instrukcia_popis) {
						popis_instrukcii .= "`n" . instrukcia_popis
					}
					if (instrukcia_syntax) {
						popis_instrukcii .= "`n`nSyntax:`n" . instrukcia_syntax
					}
					if (instrukcia_pseudokod) {
						popis_instrukcii .= "`n`nPseudokód:`n" instrukcia_pseudokod
					}
					
				}
				
				if (popis_instrukcii != popis_instrukcii_old)
				{
					this.tooltip_instrukcia_pod_mysou := popis_instrukcii
					popis_instrukcii_old := popis_instrukcii
				}
			}
			else if (okno_pod_mysou != script_HWND)
			{
				this.tooltip_instrukcia_pod_mysou := ""
			}
			;ControlGetPos , X_assembler, Y_assembler,,, ListBox2, assembler
		}
		else if (okno_pod_mysou != script_HWND)
		{
			this.tooltip_instrukcia_pod_mysou := ""
		}
		
		;tooltip % "|" tooltip_instrukcia_pod_mysou . tooltip_pomoc_tlacidla
		this.ukaz_tooltip()
	}
	
	ukaz_tooltip_pomoc_tlacidla() {
		
		static OutputVarX_old
		static OutputVarY_old
		static OutputVarControl_old
		MouseGetPos , OutputVarX, OutputVarY, OutputVarWin, OutputVarControl,
		;tooltip % OutputVarWin "|" script_HWND
		
		;SetTimer, RemoveToolTip, -100
		
		if (OutputVarX_old == OutputVarX && OutputVarY_old == OutputVarY)
		{
			return
		}
		else {
			if (OutputVarControl_old != OutputVarControl)
				this.tooltip_pomoc_tlacidla := ""
		}

			
			
		OutputVarX_old := OutputVarX
		OutputVarY_old := OutputVarY
		OutputVarControl_old := OutputVarControl
		;msgbox % script_registre_a_pamat_HWND
		if (OutputVarWin == script_HWND)
			GuiControlGet, premenna_pod_mysou ,1:Name, %OutputVarControl%
		else if (OutputVarWin == script_registre_a_pamat_HWND)
			GuiControlGet, premenna_pod_mysou ,8:Name, %OutputVarControl%
		else if (OutputVarWin == script_nastavenia_HWND)
			GuiControlGet, premenna_pod_mysou ,12:Name, %OutputVarControl%
		
		
		
		
			
		if (premenna_pod_mysou == "GUI_PAUSE")
		{
			this.tooltip_pomoc_tlacidla := "Pause - Pozastaví aktuálne vykonávaný program`nKlávesová skratka: F7"
		}
		else if (premenna_pod_mysou == "GUI_Top")
		{
			this.tooltip_pomoc_tlacidla := "Reset - Zastaví aktuálne vykonávaný program a posunie program counter na začiatok`nKlávesová skratka: F6"
		}
		else if (premenna_pod_mysou == "GUI_VykonajPoPoziciu")
		{
			this.tooltip_pomoc_tlacidla := "Spustí program (zastaví na breakpointe ak je nastavený)`nBreakpoint nastavíte dvojklikom v ľavom menu s inštrukciami`nKlávesová skratka: F8`nTip: simulácia beží rýchlejšie, ak je okno MIPSimu zmenšené na menšie rozmery"
		}

		else if (premenna_pod_mysou == "GUI_vymaz_registre")
		{
			this.tooltip_pomoc_tlacidla := "Vyčisti registre`nKlávesová skratka: F9"
		}
		else if (premenna_pod_mysou == "GUI_vymaz_data")
		{
			this.tooltip_pomoc_tlacidla := "Vyčisti dátovú pamäť`nKlávesová skratka: F12"
		}
		else if (premenna_pod_mysou == "GUI_registre_plus_datova_pamat")
		{
			this.tooltip_pomoc_tlacidla := "Zobraz obsah registrov a dátovej pamäte"
		}
		
		
		else if (premenna_pod_mysou == "GUI_nastavenia")
		{
			this.tooltip_pomoc_tlacidla := "Nastavenia"
		}
		else if (InStr(premenna_pod_mysou,"GUI_breakpoint"))
		{
			this.tooltip_pomoc_tlacidla := "Zrušiť breakpoint"
		}
		else if (premenna_pod_mysou == "GUI_opozdenie")
		{
			this.tooltip_pomoc_tlacidla := "Určuje, v ktorej časti prúdového prostriedku sa má program pozastaviť po nájdení breakpointu. `nBreakpoint nastavíte dvojklikom v ľavom menu s inštrukciami"
		}
		else if (premenna_pod_mysou == "GUI_ProgramDoSchranky")
		{
			this.tooltip_pomoc_tlacidla := "Skopíruje operačnú pamäť do systémovej schránky"
		}
		else if (premenna_pod_mysou == "GUI_RegistreDoSchranky")
		{
			this.tooltip_pomoc_tlacidla := "Skopíruje registre do systémovej schránky.`nDržte shift pre skopírovanie registrov s hodnotami v desiatkovej sústave"
		}
		else if (premenna_pod_mysou == "SETTINGS_zobrazit_napovedu_tlacidla")
		{
			this.tooltip_pomoc_tlacidla := "Zobraziť takéto nápovedy"
		}
		else if (premenna_pod_mysou == "SETTINGS_zobrazit_napovedu_instrukcie")
		{
			this.tooltip_pomoc_tlacidla := "Zobraziť nápovedu, ktorá bližšie vysvetľuje, čo robia jednotlivé inštrukcie v okne assembler"
		}
		else if (premenna_pod_mysou == "SETTINGS_zobrazit_kalkulacku")
		{
			this.tooltip_pomoc_tlacidla := "Zobraziť prevodník medzi šestnástkovou a desiatkovou sústavou v 32-bitovom registri"
		}
		else if (premenna_pod_mysou == "GUI_zmena_velkosti_obvodu_patch")
		{
			this.tooltip_pomoc_tlacidla := "Pozor! Zmena tohto nastavenia automaticky reštartuje MIPSim (uložte si aktuálny projekt)`n`nZmenší grafické zobrazenie obvodu, ktoré je moc veľké na monitoroch iných ako v mierke 4:3"
		}
		else if (premenna_pod_mysou == "SETTINGS_uloz_help_na_adresu_44D6F4")
		{
			this.tooltip_pomoc_tlacidla := "Táto záplata deaktivuje Windows help a nahradí ho vlastnou implementáciou`n`nHelp sa normálne aktivuje:`n-stlačením F1`n-kliknutím na help v menu`n-po pravom kliknutí na jednotlivé súčiastky v časti s obvodom"
		}
		else if (premenna_pod_mysou == "SETTINGS_LW_SW_invalid_parameter_fix")
		{
			this.tooltip_pomoc_tlacidla := "Táto záplata opraví maximálnu dĺžku inštrukcie v okne assembler.`nPlatnú inštrukciu ako napr: LW $7, 0123($30) už bude možné zadať bez chybovej hlášky"
		}
		else if (premenna_pod_mysou == "SETTINGS_LW_fix_pre_adresy_vacsie_ako_0xff")
		{
			this.tooltip_pomoc_tlacidla := "Vďaka tejto záplate budete môcť načítavať hodnoty pomocou inštrukcie LW z offsetu väčšieho ako 0xFF"
		}
		else if (premenna_pod_mysou == "SETTINGS_vymaz_operacny_kod_bez_dalsieho_opytania")
		{
			this.tooltip_pomoc_tlacidla := "Vďaka tejto záplate sa hneď vymaže operačný kód bez ÁNO/NIE potvrdzovadzieho okna"
		}
		else if (premenna_pod_mysou == "SETTINGS_vymaz_datovu_pamat_bez_dalsieho_opytania")
		{
			this.tooltip_pomoc_tlacidla := "Vďaka tejto záplate sa hneď vymaže dátová pamäť bez ÁNO/NIE potvrdzovadzieho okna"
		}
		else if (premenna_pod_mysou == "SETTINGS_vymaz_registre_bez_dalsieho_opytania")
		{
			this.tooltip_pomoc_tlacidla := "Vďaka tejto záplate sa hneď vymažú registre bez ÁNO/NIE potvrdzovadzieho okna"
		}
		else if (premenna_pod_mysou == "SETTINGS_prepis_subory_bez_dalsieho_opytania")
		{
			this.tooltip_pomoc_tlacidla := "Vďaka tejto záplate nebudete musieť potvrdzovať prepisovanie existujúceho súboru"
		}
		else if (premenna_pod_mysou == "SETTINGS_povol_ulozenie_prazdneho_operacneho_kodu")
		{
			this.tooltip_pomoc_tlacidla := "Vďaka tejto záplate môžete vytvoriť súbor s prázdnym operačným kódom"
		}
		else if (premenna_pod_mysou == "SETTINGS_povol_ulozenie_prazdnej_pamate")
		{
			this.tooltip_pomoc_tlacidla := "Vďaka tejto záplate môžete vytvoriť súbor s prázdnou pamäťou"
		}
		else if (premenna_pod_mysou == "SETTINGS_VIAC")
		{
			this.tooltip_pomoc_tlacidla := "Zobraziť viac dátovej pamäte"
		}
		else if (premenna_pod_mysou == "SETTINGS_DESIATKOVA_SUSTAVA")
		{
			this.tooltip_pomoc_tlacidla := "Prepočítať registre a dátovú pamäť do desiatkovej sústavy"
		}
		else if (premenna_pod_mysou == "GUI_uloz_stav_registrov")
		{
			this.tooltip_pomoc_tlacidla := "Uloží aktuálny stav registrov, aby sa dali neskôr obnoviť stlačením tlačidla 'Obnoviť'"
		}
		else if (premenna_pod_mysou == "GUI_uloz_stav_datovej_pamate")
		{
			this.tooltip_pomoc_tlacidla := "Uloží aktuálny stav dátovej pamäte, aby sa dala neskôr obnoviť stlačením tlačidla 'Obnoviť'"
		}
		else if (premenna_pod_mysou == "GUI_obnov_stav_registrov")
		{
			this.tooltip_pomoc_tlacidla := "Obnoví stav registrov uložených stlačením tlačidla 'Ulož'"
		}
		else if (premenna_pod_mysou == "GUI_obnov_stav_datovej_pamate")
		{
			this.tooltip_pomoc_tlacidla := "Obnoví stav dátovej pamäte uloženej stlačením tlačidla 'Ulož'"
		}
		else if (premenna_pod_mysou == "GUI_editor_help")
		{
			help_info = 
(
Pre editáciu hodnoty:
1. Kliknite na hodnotu, ktorú chcete editovať
2. Pomocou klávesy backspace mažete poslednú číslicu
3. Zadajte hodnotu, ktorú si prajete zapísať v desiatkovej sústave
4. Potvrďte stlačením klávesy enter 

Skratky:
arrow up, mousewheel up - inkrementuje aktuálnu hodnotu o 1
arrow down, mousewheel down - dekrementuje aktuálnu hodnotu o 1
CTRL+C - skopíruje aktuálnu hodnotu. Ak nie je aktuálne editovaná žiadna hodnota - skopíruje celý obsah registrov+dátovej pamäte do schránky
CTRL+V - vloží skopírovanú hodnotu
Delete - vynuluje aktuálnu hodnotu
Enter, Esc - ukončí editáciu
-, Numpad- - Vynásobí číslo hodnotou -1 (teda zmení znamienko)

Prečo exitujú dve okná, kde sa danú meniť tie isté hodnoty?
-V originálnom okne data memory nevidíte zmeny hodnôt počas vykonávania programu
-V originálnych oknách data memory a register nevidíte hodnoty v desiatkovej sústave
)
			this.tooltip_pomoc_tlacidla := help_info
		}
		else
		{
			/*
			tooltip % premenna_pod_mysou
		
			if (premenna_pod_mysou == "")
				return
			clipboard := premenna_pod_mysou
			*/
		}
		;tooltip % "|||" this.tooltip_pomoc_tlacidla
		this.ukaz_tooltip()
	}
}

class Breakpointy {
	aktualne_vykonanany_riadok := 0
	pocet_vytvorenych_breakpointov := 0
	
	zoznam_breakpointov := []
	
	
	__New(){
		this.aktualne_vykonanany_riadok := this.ziskaj_aktualne_vykonavany_riadok()
	}
	
	ziskaj_aktualne_vykonavany_riadok() {
		return getPoziciaScrollbaru()  + getPoziciaUkazovatela()
	}
	
	vytvor_novy_breakpoint(riadok) {
		;over, či pre daný riadok už breakpoint neexistuje
		for key,value in this.zoznam_breakpointov {
			if(this.zoznam_breakpointov[key].get_riadok() == riadok)
				return	;nevytvor brekpoint, ak je na danom riadku už breakpoint nastavený
			
		}
		
		this.zoznam_breakpointov[this.pocet_vytvorenych_breakpointov] := new Breakpoint(this.pocet_vytvorenych_breakpointov++,riadok)
	}
	
	vymaz_breakpoint(id){
		this.zoznam_breakpointov[id].vymaz_breakpoint()
		this.zoznam_breakpointov[id] := ""
	}
	
	aktualizuj_poziciu_breakpointov_v_gui(){
		pozicia_scrollbaru := getPoziciaScrollbaru()
		for key,value in this.zoznam_breakpointov {
			this.zoznam_breakpointov[key].aktualizuj_poziciu_v_gui(pozicia_scrollbaru)
		}
	}
	
	oznam_vykonany_riadok() {
		;vráti 1 ak treba zastaviť
		;inak vráti 0
		
		vykonany_riadok := this.ziskaj_aktualne_vykonavany_riadok()
		
		zastavit := 0
		
		for key,value in this.zoznam_breakpointov {
			zastavit += this.zoznam_breakpointov[key].bol_vykonany_riadok(vykonany_riadok)
		}
		
		if (zastavit > 0)
			return 1
		else
			return 0
	
	}
}
/*
	GuiControl, hide, GUI_opozdenie
	GuiControl, hide, GUI_opozdenie_text
	GuiControl,, GUI_VykonajPoPoziciu, grafika\run.png
	statusbar("Breakpoint zrušený")
*/
class Breakpoint {
	id := 0
	riadok := 0	;cislovanie od 0 do 255
	casovac := -2
	
	__New(id,riadok){
		;msgbox % id
		this.id := id
		this.riadok := riadok
		this.vytvor_gui_obrazok(this.id)
	}
	
	bol_vykonany_riadok(vykonany_riadok) {
		;msgbox % this.riadok "|" vykonany_riadok
		this.casovac--
		if (this.riadok == vykonany_riadok) {
			GuiControlGet, GUI_opozdenie
			opozdenie := GUI_opozdenie - 1
			
			this.casovac := opozdenie
		}
		
		if (this.casovac == 0)
		{
			id := this.id
			GuiControl,, GUI_breakpoint%id%, grafika/breakpoint_aktivny.png
			return 1
		}
		
		else
		{
			if (this.casovac == -1)	;v ďalšom kroku obnov grafiku breakpointu
			{
				id := this.id
				GuiControl,, GUI_breakpoint%id%, grafika/breakpoint.png
			}
			return 0
		}
			
	}
	
	vytvor_gui_obrazok(id) {
		global
		breakpoint_velkost := 13 / DPI_nasobitel

		Gui, Add, Picture, x12 y-60 w%breakpoint_velkost% h%breakpoint_velkost% vGUI_breakpoint%id% gzrus_breakpoint, grafika/breakpoint.png
	}
	
	get_riadok() {
		return this.riadok
	}
	
	aktualizuj_poziciu_v_gui(pozicia_scrollbaru)
	{
		id := this.id
		yOffset := 94 + 13 * (this.riadok - pozicia_scrollbaru)
		
		if ((this.riadok - pozicia_scrollbaru) < 0)
			GuiControl, Move, GUI_breakpoint%id%, y-200
		else
			GuiControl, Move, GUI_breakpoint%id%, y%yOffset%
	}
	
	vymaz_breakpoint() {
		id := this.id
		GuiControl, Hide, GUI_breakpoint%id%
	}
	
}




Class Help {
	static umiestnenie_pomocneho_miesta := 0x44D6F4
	
	__New(){
		this.vytvor_gui()
		mipsim_obj.write(this.umiestnenie_pomocneho_miesta,0xFF, "UInt")	;zapíš číslo 0xFF, ktoré ignorujeme
		
		;this.zobraz_obrazok_v_gui("assembler_window", 1175, 581)
	}
	
	vytvor_gui() {
		global
		Gui, 20:Add, Picture, x0 y0 w495 h500 vGUI_help_obrazok, C:\WINDOWS\notepad.exe
	}
	
	zobraz_obrazok_v_gui(subor, w, h) {
		GuiControl, 20:, GUI_help_obrazok, *w%w% *h%h% %A_WorkingDir%\help\%subor%.png
		
		Gui, 20:Show, w%w% h%h%, Help
	}
	
	zisti_ci_nebol_vyvolany_help() {
		help_id := mipsim_obj.read(this.umiestnenie_pomocneho_miesta, "UInt")	;prečítaj hodnotu, ktorú nám pomocný patch zanechal na adrese this.umiestnenie_pomocneho_miesta
		if (help_id != 0xFF)
		{
			mipsim_obj.write(this.umiestnenie_pomocneho_miesta,0xFF, "UInt")	;zapíš naspäť číslo 0xFF, ktoré ignorujeme
			this.handle_help(help_id)
		}
	}
	
	handle_help(help_id) {
		help_nadpis := "Nepridaný help"
		help_text := "Pridajte help pre ID " help_id
		if (help_id == 14)
		{
			help_nadpis := "Instruction Memory (IM)"
			help_text := "The instruction memory in the IF stage is addressed by the PC and delivers the corresponding 32-bit value to the IF/ID-Latch"
		}
		else if (help_id == 17)
		{
			help_nadpis := "Control Unit (CU)"
			help_text := "From the opcode word as its input, the Control Unit generates several signals to control the operation of most of the elements in the schematic."
		}
		else if (help_id == 11)
		{
			help_nadpis := "Multiplexor (MUX)"
			help_text := "Used to select an arbitrary input to be fed through to the output. In this schematic, multiplexers are used to distribute the control signals according to the respective opcode."
		}
		else if (help_id == 2)
		{
			help_nadpis := "Latch"
			help_text := "The latches are used to store the signals computed within one stage until the next stage cycle begins, when they are fed through to the following stage."
		}
		else if (help_id == 3)
		{
			help_nadpis := "And-Gate"
			help_text := "Produces the logical ‘and’ of all of it’s inputs. In this case it combines the Zero output of the ALU and the branch bit from the Control Unit to select the appropriate PC value."
		}
		else if (help_id == 15)
		{
			help_nadpis := "Data Memory (DM)"
			help_text := "On the zero-to-one transition of the MemWrite input the 32-bit value on the data input is stored at the address on the address input."
		}
		else if (help_id == 8)
		{
			help_nadpis := "Arithmetic Logic Unit (ALU)"
			help_text := "The ALU in this simulator can perform various operations on 32-bit values. The Control Unit determines the operation to be performed via the 4-bit Alu operation bus.`nCarry and Overflow are not implemented."
		}
		else if (help_id == 12)
		{
			help_nadpis := "Sign Extension Unit"
			help_text := "Extends the 16-bit offset value contained in the opcode to 32 bit so that it can be added to the current address, which is 32 bit."
		}
		else if (help_id == 9)
		{
			help_nadpis := "Adder"
			help_text := "This simulator contains two 32-bit adders: One in the IF stage to increment the PC, and the other in the EX stage to add the sign-extended 16-bit offset to the PC."
		}
		else if (help_id == 13)
		{
			help_nadpis := "Register File"
			help_text := "The register file in this simulator contains 32 32-bit registers.`nRegister 0 is hardwired to zero."
		}
		else if (help_id == 131074 || help_id == 0)	;F1 - hlavné okno
		{
			this.zobraz_obrazok_v_gui("main_window", 1180, 709)
			return
		}
		else if (help_id == 131208)	;F1 - okno assembler
		{
			this.zobraz_obrazok_v_gui("assembler_window", 1175, 581)
			return
		}
		else if (help_id == 131207)	;F1 - okno Register
		{
			this.zobraz_obrazok_v_gui("register_window", 925, 401)
			return
		}
		else if (help_id == 131209)	;F1 - okno data memory
		{
			this.zobraz_obrazok_v_gui("data_window", 994, 343)
			return
		}
		if (help_id != 0)
			MsgBox 0x0, %help_nadpis%, %help_text%
	}
}




#include funkcie_citaj_mipsim_subory.ahk
;ListVars

global aktualny_program := "NULL"
global nadpis := "Overlay v" . program_verzia

global DPI_nasobitel := A_ScreenDPI / 100
global pozicia_oznacenia = -100

global list
global list_stary
global msgboxy := 0

global offset_instrukcie_gui




global STARTUP := new Startup()
STARTUP.nainstaluj_dependencies()
STARTUP.spusti_MIPSim()
STARTUP.kalibruj_otvorenie_a_ulozenie_suboru()

GRAFICKE_ROZHRANIE := new Graficke_rozhranie()
GRAFICKE_ROZHRANIE.vypocitaj_toolbar_window_offset()
GRAFICKE_ROZHRANIE.vytvor_tray_menu()
GRAFICKE_ROZHRANIE.vytvor_nastavenia_gui()
GRAFICKE_ROZHRANIE.vytvor_overlay_gui()
GRAFICKE_ROZHRANIE.vytvor_live_registre_a_pamat_gui()


global mipsim_obj
global pointer_register
global pointer_pamat
global pointer_instrukcie

;-----------------------Záplaty
global ZAPLATY := new Zaplaty()
mipsim_obj := ZAPLATY.get_mipsim_obj()
ZAPLATY.najdi_smerniky()
ZAPLATY.aplikuj_zaplaty()


;-----------------------Tooltip
global TOOLTIP := new ToolTip()

;-----------------------MIPSim help handler
global HELP := new Help()

global BREAKPOINTY := new Breakpointy()


;Vytvor hook pre win eventy 0x3 až 0xB
;EVENT_SYSTEM_FOREGROUND = 0x3
;EVENT_SYSTEM_CAPTUREEND = 0x9
;EVENT_SYSTEM_MOVESIZESTART = 0xA
;EVENT_SYSTEM_MOVESIZEEND = 0xB
HookProcAdr := RegisterCallback( "HookProc", "F" )
hWinEventHook := SetWinEventHook( 0x3, 0xB, 0, HookProcAdr, 0, 0, 0 )
OnExit, HandleExit



HookProc( hWinEventHook, Event, hWnd, idObject, idChild, dwEventThread, dwmsEventTime )
{
	if (Event == 10 || Event == 11 || Event == 3 || Event == 9)
	{
		if (hWnd == mipsim_HWND || WinActive("assembler") || WinActive("Register"))
		{
			;tooltip % hWinEventHook "|" Event "|" hWnd
			aktualizuj_rozmery_a_velkost_gui()
			if (Event == 9)	;Windows 7 fix, rozmery neaktualizovane hned pomaximalizovani/minimalizovani
			{
				sleep 10
				aktualizuj_rozmery_a_velkost_gui()
			}
			
			while (GetKeyState("LButton", "P"))
			{
				aktualizuj_rozmery_a_velkost_gui()
			}
			
		}
	}
}

;Autor Serenity
;https://autohotkey.com/board/topic/32662-tool-wineventhook-messages/
SetWinEventHook(eventMin, eventMax, hmodWinEventProc, lpfnWinEventProc, idProcess, idThread, dwFlags)
{
	DllCall("CoInitialize", Uint, 0)
	return DllCall("SetWinEventHook"
	, Uint,eventMin	
	, Uint,eventMax	
	, Uint,hmodWinEventProc
	, Uint,lpfnWinEventProc
	, Uint,idProcess
	, Uint,idThread
	, Uint,dwFlags)	
}

UnhookWinEvent()
{
	Global
	DllCall( "UnhookWinEvent", Uint,hWinEventHook )
	;DllCall( "GlobalFree", UInt,&HookProcAdr ) ; free up allocated memory for RegisterCallback, crash na Win 7
}
;KONIEC Vytvor hook









global BORDER_OFFSET
global Y_OFFSET

global X_mipsim
global Y_mipsim

WinGetPos , X_mipsim, Y_mipsim, Width_mipsim, Height_mipsim, ahk_id %mipsim_HWND%
Width_mipsim -= BORDER_OFFSET
Height_mipsim -= BORDER_OFFSET




	




setOwner() {
	Gui, +Owner%mipsim_HWND%
}


global script_registre_a_pamat_HWND
global script_nastavenia_HWND
Gui, 8:Show, w100 h100 Hide, Registre + dátová pamäť
DetectHiddenWindows, On
WinGet, script_registre_a_pamat_HWND, ID , Registre + dátová pamäť, 
DetectHiddenWindows, Off
Gui, 8:submit


Gui, 12:Show, w317 h403 Hide, MIPSim nastavenia
DetectHiddenWindows, On
WinGet, script_nastavenia_HWND, ID , MIPSim nastavenia, 
DetectHiddenWindows, Off
Gui, 12:+owner%mipsim_HWND%

if(flag_obvod_patch_zmeneny) {
	Gui, 12:Show, w317 h403, MIPSim nastavenia
}
else
{
	Gui, 12:submit
}






vypis_registre(pointer_register)
{
	list = 
	adresa := pointer_register
	
	static buffer
	VarSetCapacity(buffer, 124)
	mipsim_obj.readRaw(adresa, buffer, 124)
	offset = 0
	
	znak := REGISTER_A_DATOVA_PAMAT_ZNAK
	
	if(SETTINGS_DESIATKOVA_SUSTAVA == 0)
		list .= "R00	       0`n"
	else
		list .= "R00            " znak "`n"
	
	
	loop 31
	{
		list .= "R" . padding_nulami(a_index,2)
		;hodnota := funkcie_hex.dec_do_unsigned_hex(mipsim_obj.read(adresa, "UInt"))
		hodnota := funkcie_hex.dec_do_unsigned_hex(NumGet(buffer , offset, "UInt"))

		StringReplace, hodnota, hodnota, 0x,,
		;msgbox % hodnota
		
		
		if(SETTINGS_DESIATKOVA_SUSTAVA == 0)
			list .= a_tab . padding_nulami(hodnota,8, " ")
		else
			list .= "  " padding_nulami(funkcie_hex.hex_do_signed_dec(hodnota),11," ")
		
	
		
		if(mod(a_index - 1,1) == 0)
			list .= "`n"
		
		adresa+= 4
		offset+= 4

	}
	StringReplace, list, list, 0x,, All
	StringReplace, list, list, %znak%%znak%%znak%%znak%%znak%%znak%%znak%0,%znak%%znak%%znak%%znak%%znak%%znak%%znak%%znak%, All
	StringReplace, list, list, %a_space%%a_space%%a_space%%a_space%%a_space%%a_space%%a_space%0,%a_space%%a_space%%a_space%%a_space%%a_space%%a_space%%a_space%%znak%, All
	
	StringTrimRight, list, list, 1
	
	static last_list
	if(last_list != list)
	{
		GuiControl, 8:, GUI_registre, %list%
	}
	
	last_list := list
}

vypis_instrukcie(pointer_instrukcie)
{
	list = 
	adresa := pointer_instrukcie
	
	static buffer
	VarSetCapacity(buffer, 1024)
	mipsim_obj.readRaw(adresa, buffer, 1024)
	offset = 0
	
	
	loop 256
	{
		hodnota := funkcie_hex.dec_do_unsigned_hex(NumGet(buffer , offset, "UInt"))
		StringReplace, hodnota, hodnota, 0x,,
		
		list .= zmen_endian(padding_nulami(hodnota,8)) . "`n"
		
		adresa+= 4
		offset+= 4

	}
	list .= "koniec_magic"
	loop 256
	{
		StringReplace, list, list, 00000000`nkoniec_magic,koniec_magic, All
	}
	
	
	
	StringReplace, list, list, `nkoniec_magic,,
	StringReplace, list, list, koniec_magic,,
	
	StringReplace, hex, list, `n,, All
	program := funkcie_citaj_mipsim_subory.precitaj_instrukcie(hex)
	return program
}

;12 34 56 78
;34 12
zmen_endian(vstup) {
	Loop, parse, vstup,,
	{	
		if (mod(A_Index,2) == 1)
		{
			temp := A_LoopField
		}
		if (mod(A_Index,2) == 0)
		{
			vystup := temp . A_LoopField . vystup
		}
		
	}
	return vystup
}

vypis_celu_pamat(pointer_pamat, vynut_refresh:=0)
{
	znak := REGISTER_A_DATOVA_PAMAT_ZNAK
	
	list_temp = 
	adresa := pointer_pamat
	
	static buffer
	VarSetCapacity(buffer, 1024)
	if(SETTINGS_VIAC)
	{
		mipsim_obj.readRaw(adresa, buffer, 1024)
		loopcount := 256
	}
	else
	{
		mipsim_obj.readRaw(adresa, buffer, 512)
		loopcount := 128
	}
		
	offset = 0
	
	
	loop % loopcount
	{
		if(mod(a_index,4) == 1)
		{
			if(SETTINGS_DESIATKOVA_SUSTAVA == 0)
				list_temp .= padding_nulami(funkcie_hex.dec_do_unsigned_hex(adresa - pointer_pamat),5)
			else
				list_temp .= padding_nulami(padding_nulami(adresa - pointer_pamat,3),4," ")
			if(SETTINGS_DESIATKOVA_SUSTAVA == 0)
				list_temp .= a_tab
			else
				list_temp .= " "
			
		}
		
		;hodnota := funkcie_hex.dec_do_unsigned_hex(mipsim_obj.read(adresa, "UInt"))
		hodnota := funkcie_hex.dec_do_unsigned_hex(NumGet(buffer , offset, "UInt"))
		StringReplace, hodnota, hodnota, 0x,,
		
		if(SETTINGS_DESIATKOVA_SUSTAVA == 0)
			list_temp .= padding_nulami(hodnota,8," ")
		else
			list_temp .= padding_nulami(funkcie_hex.hex_do_signed_dec(hodnota),11," ")
		
		if(mod(a_index,4) != 0)
			list_temp .= " "
		
		if(mod(a_index,4) == 0 && a_index != 128 && a_index != 256)	;ak nie je koniec výpisu - daj nový riadok
			list_temp .= "`n"
		
		offset+= 4
		adresa+= 4
		
		if(a_index == 128)
		{
			list := list_temp
			list_temp := ""
		}
		if(a_index == 256)
			list2 := list_temp
	}
	StringReplace, list, list, 0x,, All
	StringReplace, list2, list2, 0x,, All
	StringReplace, list, list, %znak%%znak%%znak%%znak%%znak%%znak%%znak%0,%znak%%znak%%znak%%znak%%znak%%znak%%znak%%znak%, All
	StringReplace, list2, list2, %znak%%znak%%znak%%znak%%znak%%znak%%znak%0,%znak%%znak%%znak%%znak%%znak%%znak%%znak%%znak%, All
	StringReplace, list, list, %a_space%%a_space%%a_space%%a_space%%a_space%%a_space%%a_space%0,%a_space%%a_space%%a_space%%a_space%%a_space%%a_space%%a_space%%znak%, All
	StringReplace, list2, list2, %a_space%%a_space%%a_space%%a_space%%a_space%%a_space%%a_space%0,%a_space%%a_space%%a_space%%a_space%%a_space%%a_space%%a_space%%znak%, All
	
	static last_list
	static last_list2
	
	if(last_list != list || vynut_refresh == 1)
		GuiControl, 8:, GUI_data, %list%
	if(last_list2 != list2 || vynut_refresh == 1)
		GuiControl, 8:, GUI_data2, %list2%
	
	last_list := list
	last_list2 := list2
}





setOwner()

Gui, Show, x%X_mipsim% y%Y_mipsim% w%Width_mipsim% h%Height_mipsim%,%nadpis%
global script_HWND
WinGet, script_HWND, ID , %nadpis%, 
winactivate,ahk_id %mipsim_HWND%



statusbar("Vitajte v simulátore MIPSim")





;SetTimer, aktualizuj_rozmery_a_velkost_gui, 500
SetTimer, aktualizuj_poziciu_breakpointov, 100


statusbar(text) {
	ControlSetText ,msctls_statusbar321, %text%, ahk_id %mipsim_HWND%
}



aktualizuj_rozmery_a_velkost_gui() {
		WinGetPos , X_mipsim, Y_mipsim, Width_mipsim, Height_mipsim, ahk_id %mipsim_HWND%
		Width_mipsim -= BORDER_OFFSET
		Height_mipsim -= BORDER_OFFSET

		static old_X_mipsim
		static old_Y_mipsim
		static old_Width_mipsim
		static old_Height_mipsim

		if (old_X_mipsim != X_mipsim || old_Y_mipsim != Y_mipsim || old_Width_mipsim != Width_mipsim || old_Height_mipsim != Height_mipsim || )
		{
			;rozmery a velkost gui
			Width_mipsim -= X_BORDER
			WinMove, %nadpis%,, X_mipsim, Y_mipsim , Width_mipsim, Height_mipsim, 
			Width_mipsim += X_BORDER
			;ulož nové hodnoty
			old_X_mipsim := X_mipsim
			old_Y_mipsim := Y_mipsim
			old_Width_mipsim := Width_mipsim
			old_Height_mipsim := Height_mipsim
			

		}
		if(WinExist("assembler")) {
			GuiControl, show, GUI_ProgramDoSchranky
			
			WinGetPos , X_gui, Y_gui,,, %nadpis%
			WinGetPos , X_assembler, Y_assembler,,H_assembler, assembler
			
			DPI_nasobitel_relative := DPI_nasobitel / 96 * 100
			GuiControl, Move, GUI_ProgramDoSchranky, % "x" (X_assembler - X_gui) / DPI_nasobitel_relative "y" (Y_assembler - Y_gui + H_assembler ) / DPI_nasobitel_relative	
		}
		else
		{
			GuiControl, hide, GUI_ProgramDoSchranky
		}
		if(WinExist("Register")) {
			GuiControl, show, GUI_RegistreDoSchranky
			
			WinGetPos , X_gui, Y_gui,,, %nadpis%
			WinGetPos , X_register, Y_register,,H_register, Register
			
			DPI_nasobitel_relative := DPI_nasobitel / 96 * 100
			GuiControl, Move, GUI_RegistreDoSchranky, % "x" (X_register - X_gui) / DPI_nasobitel_relative "y" (Y_register - Y_gui + H_register ) / DPI_nasobitel_relative	
		}
		else
		{
			GuiControl, hide, GUI_RegistreDoSchranky
		}
}

aktualizuj_poziciu_breakpointov() {
	BREAKPOINTY.aktualizuj_poziciu_breakpointov_v_gui()
/*
	scroll_pozicia := getPoziciaScrollbaru()
	tooltip % scroll_pozicia
	;ControlGetPos , ,yListBox1,,, ListBox1, ahk_id %mipsim_HWND%
	;ControlGetPos , , yUkazovatel, w, hUkazovatel, Afx:400000:0:10003:0:01, ahk_id %mipsim_HWND%
	
	; 13 = hUkazovatel v 100% mierke
	; 94 = yListBox1 v 100% mierke
	yOffset := 94 + 13 * (pozicia_oznacenia - scroll_pozicia)
	;tooltip % (pozicia_oznacenia - scroll_pozicia) "|" yListBox1
	
	;Aktualizuj pozíciu obrázkov
	
	if ((pozicia_oznacenia - scroll_pozicia) < 0)
		GuiControl, Move, GUI_breakpoint0, y-200
	else
		GuiControl, Move, GUI_breakpoint0, y%yOffset%
		
		*/
}




/*
SendMessage, 0x18B, 0, 0, ListBox1, %WinTitle%
Total = %ErrorLevel%

SendMessage, 0x188, 0, 0, ListBox1, %WinTitle%
SelectedEntry = %ErrorLevel%
*/
;ControlGet, CurrTool, FindString   ,, ListBox1, %WinTitle%




getPoziciaUkazovatela() {
	ControlGetPos , ,yListBox1,,, ListBox1, ahk_id %mipsim_HWND%
	ControlGetPos , , yUkazovatel, w, hUkazovatel, Afx:400000:0:10003:0:01, ahk_id %mipsim_HWND%
	;ControlGetPos , x, y, w, h, ListBox1, MIPSim,
	
	yOffset := yListBox1 - 1
	pozicia_ukazovatela := round((yUkazovatel - yOffset) / hUkazovatel)
	;tooltip % yUkazovatel "|" hUkazovatel "|" yListBox1
	return % pozicia_ukazovatela
}

;;;;;;;;;;;;;;Scrollbar

getPoziciaOznacenia() {
	SendMessage, 0x188, 0, 0, ListBox1, ahk_id %mipsim_HWND%
	SelectedEntry = %ErrorLevel%
	return % SelectedEntry
}

getPoziciaScrollbaru() {
	ControlGet, ChildHWND, Hwnd ,,ListBox1, ahk_id %mipsim_HWND%
	ScrollPos:=DllCall("GetScrollPos", "UInt", ChildHWND, "Int", 1)  ;  Last parameter is 1 for SB_VERT, 0 for SB_HORZ.
	;tooltip % ScrollPos
	return % ScrollPos
	
}










najdi_offset() {	;pridávanie štítkov na zbernice nám zmení umiestnenie textových prvkov, z krorých chceme čítať aktuálne vykonávané inštrukcie. Funkcia nájde offset, ktorý musíme pripočítať aby sme sa dostali k prvkom, ktoré obsahujú aktuálne vykonávané inštrukcie
	
	offset = 1
	loop 100 {
		ControlGetText, nopka_temp%a_index% , AfxWnd42s%a_index%, ahk_id %mipsim_HWND%,,,
		;tooltip % nopka_temp%a_index%
		if (nopka_temp%a_index% == "")
			break
		;list .= nopka_temp%a_index% . "|"
		offset++
	}
	
	return %offset%
}

AktualizujObsahRegistrov(do_schranky = 0) {

	if (pocet_okien("Register") == 1)
	{
		list := "Registre:`nR00     0`n"
				
		;Prečítaj všetkých 31 registrov
		loop 31 {
				
			ControlGetText, vystup , Edit%A_Index%, Register,,,
			if(do_schranky != 1  || (do_schranky == 1 && GetKeyState("Shift", "P")))
			{
				vystup := funkcie_hex.hex_do_signed_dec(vystup)
			}
			

			list .= "R" . padding_nulami(A_Index, 2) . "     " . vystup . "`n"

		}
		
		if(do_schranky == 1)
		{
			if (!GetKeyState("Shift", "P"))
				StringReplace, list, list, R00     0 ,R00     00000000,
				
			StringReplace, list, list, Registre:`n,,
			clipboard := list
			list := "Registre skopírované do schránky:`n" . list
			tooltip % list
			sleep 1000
			tooltip
		}
		return % list
	}
}

otvorenie_suboru_uloz_meno_programu()
{
	if (WinActive("ahk_class #32770")) {	
		ControlGetText, typ_suboru , ComboBox2, ahk_class #32770
		
		if (typ_suboru == "MIPSim files (*.m?)" || typ_suboru == "MIPSim Program File (*.mp)" || typ_suboru == "MIPSim Register File (*.mr)" || typ_suboru == "MIPSim Data File (*.md)")
		{
			ControlGetText, subor , Edit1, ahk_class #32770,,,
			if (subor == "*.mp" || subor == "*.mr" || subor == "*.md" || subor == "test" || subor == "test.mp" || subor == "test.md" || subor == "test.mr")	;if placeholder
			{
				if(aktualny_program != "NULL")
					ControlSetText , Edit1, %aktualny_program%, ahk_class #32770, 
			}
			else if (subor != "")	;if not placeholder    ;if not empty
			{
				WinSetTitle, ahk_id %mipsim_HWND%,, %subor% - MIPSim
				StringReplace, subor, subor, .mp,,
				StringReplace, subor, subor, .md,,
				StringReplace, subor, subor, .mr,,
				StringReplace, subor, subor, .MP,,
				StringReplace, subor, subor, .MD,,
				StringReplace, subor, subor, .MR,,
				aktualny_program := subor
			}
		}
		
		
		
		
	}

}

EDITOR_HODNOT := new editor_hodnot()
obj_mipsnejk := new mipsnejk()

;Hlavný cyklus
loop {	
	otvorenie_suboru_uloz_meno_programu()	;Ak je otvorený dialóg na otorenie programu, získaj meno súboru
	
	if (SETTINGS_zobrazit_napovedu_tlacidla == 1)
		TOOLTIP.ukaz_tooltip_pomoc_tlacidla()
	
	
	if (!WinExist("ahk_id " mipsim_HWND)) {
		gosub, HandleExit	
	}
	
	if (SETTINGS_zobrazit_napovedu_instrukcie == 1)
	{
		if (WinExist("assembler") && WinActive("assembler")) {
			TOOLTIP.ukaz_tooltip_instrukcia_pod_mysou()
		}
	}

	
	
	;zatvor_potvrdenie_pre_vymazanie_registrov()
	
	MouseGetPos , OutputVarX, OutputVarY, OutputVarWin, OutputVarControl, Flag
	
	if WinExist("Registre + dátová pamäť")
	{
		vypis_registre(pointer_register)
		vypis_celu_pamat(pointer_pamat)
		
		EDITOR_HODNOT.aktualizuj_oznacenie()
		
	}
	vypis_instrukcie(pointer_instrukcie)
	
	HELP.zisti_ci_nebol_vyvolany_help()
	
	sleep 50	;rýchlosť cyklu
}


;msgbox % list
return








;GuiDropFiles:
	;msgbox % A_GuiEvent
	/*
	Loop, parse, A_GuiEvent, `n,
	{	
		vykonaj_ak_existuje(A_LoopField)
		SplitPath, A_LoopField ,,, Extension,,
		if(Extension == "mp" or Extension == "md" or Extension == "mr")
			break
	}
	*/
;return




getPoziciaScrollbaru_instrukcie() {
	ControlGet, ChildHWND, Hwnd ,,ListBox2, assembler
	ScrollPos:=DllCall("GetScrollPos", "UInt", ChildHWND, "Int", 1)  ;  Last parameter is 1 for SB_VERT, 0 for SB_HORZ.
	return % ScrollPos

}

getPoziciaOznacenia_instrukcie() {
	SendMessage, 0x188, 0, 0, ListBox2, assembler
	SelectedEntry = %ErrorLevel%
	return % SelectedEntry
}




Minimalizuj:
WinMinimize , %nadpis%, 
return

otvor_live_pamat:
if !WinExist("Registre + dátová pamäť")
{
	GRAFICKE_ROZHRANIE.resize_live_registre_a_pamat_gui()
	gui, 8: show
}
else
	gui, 8: submit
return

otvor_nastavenia:
if !WinExist("MIPSim nastavenia")
	gui, 12: show
else
	gui, 12: submit
return

8GuiClose:
gui, 8: submit
return

12GuiClose:
gui, 12: submit
return

GuiClose:
HandleExit:
tooltip % "Ukončujem"
gui, submit
UnhookWinEvent()
tooltip
exitapp
return

info:
MsgBox 0x40040, , MIPSim overlay pre FIIT STU vytvoril Adam Slatinský`nVerzia: v%program_verzia% - %program_datum%`n`nKontakt: slatinsky.adam@gmail.com
return

zmena_velkosti_obvodu_patch:
GuiControlGet, GUI_zmena_velkosti_obvodu_patch,12:
IniWrite, %GUI_zmena_velkosti_obvodu_patch%,%SETTINGS_path%, nastavenia, SETTINGS_zmena_velkosti_obvodu_patch

zmena_velkosti_obvodu_patch := padding_nulami(funkcie_hex.dec_do_unsigned_hex(17 - GUI_zmena_velkosti_obvodu_patch), 4)
StringReplace, zmena_velkosti_obvodu_patch, zmena_velkosti_obvodu_patch, 0x,,
;msgbox % zmena_velkosti_obvodu_patch

FileCopy, MIPSim\MIPSIM32.EXE, MIPSim\MIPSIM32_upraveny.EXE, 0
bytes_written := BinWrite("MIPSim\MIPSIM32_upraveny.EXE",zmena_velkosti_obvodu_patch,0,0x0003EE52)
if(bytes_written != 1)
	msgbox % "Nastala chyba pri plátaní"
;MsgBox ErrorLevel = %ErrorLevel%`nBytes Written = %bytes_written%

winclose, ahk_id %mipsim_HWND%
reload
return

config()
{
	;run, "%a_workingdir%\nastavenia.ini"
	gui, 12: show
}
Reload()
{
	Reload
}

;Autor Laszlo https://autohotkey.com/board/topic/4299-simple-binary-file-readwrite-functions/
/* ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; BinWrite ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
|  - Open binary file
|  - (Over)Write n bytes (n = 0: all)
|  - From offset (offset < 0: counted from end)
|  - Close file
|  data -> file[offset + 0..n-1], rest of file unchanged
|  Return #bytes actually written
*/ ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BinWrite(file, data, n=0, offset=0)
{
   ; Open file for WRITE (0x40..), OPEN_ALWAYS (4): creates only if it does not exists
   h := DllCall("CreateFile","str",file,"Uint",0x40000000,"Uint",0,"UInt",0,"UInt",4,"Uint",0,"UInt",0)
   IfEqual h,-1, SetEnv, ErrorLevel, -1
   IfNotEqual ErrorLevel,0,Return,0 ; couldn't create the file

   m = 0                            ; seek to offset
   IfLess offset,0, SetEnv,m,2
   r := DllCall("SetFilePointerEx","Uint",h,"Int64",offset,"UInt *",p,"Int",m)
   IfEqual r,0, SetEnv, ErrorLevel, -3
   IfNotEqual ErrorLevel,0, {
      t = %ErrorLevel%              ; save ErrorLevel to be returned
      DllCall("CloseHandle", "Uint", h)
      ErrorLevel = %t%              ; return seek error
      Return 0
   }

   TotalWritten = 0
   m := Ceil(StrLen(data)/2)
   If (n <= 0 or n > m)
       n := m
   Loop %n%
   {
      StringLeft c, data, 2         ; extract next byte
      StringTrimLeft data, data, 2  ; remove  used byte
      c = 0x%c%                     ; make it number
      result := DllCall("WriteFile","UInt",h,"UChar *",c,"UInt",1,"UInt *",Written,"UInt",0)
      TotalWritten += Written       ; count written
      if (!result or Written < 1 or ErrorLevel)
         break
   }

   IfNotEqual ErrorLevel,0, SetEnv,t,%ErrorLevel%

   h := DllCall("CloseHandle", "Uint", h)
   IfEqual h,-1, SetEnv, ErrorLevel, -2
   IfNotEqual t,,SetEnv, ErrorLevel, %t%

   Return TotalWritten
}

;--------------NASTAVENIA 
;záplaty
SETTINGS_uloz_help_na_adresu_44D6F4:
SETTINGS_LW_SW_invalid_parameter_fix:
SETTINGS_LW_fix_pre_adresy_vacsie_ako_0xff:
SETTINGS_vymaz_datovu_pamat_bez_dalsieho_opytania:
SETTINGS_vymaz_operacny_kod_bez_dalsieho_opytania:
SETTINGS_vymaz_registre_bez_dalsieho_opytania:
SETTINGS_prepis_subory_bez_dalsieho_opytania:
SETTINGS_povol_ulozenie_prazdneho_operacneho_kodu:
SETTINGS_povol_ulozenie_prazdnej_pamate:
GuiControlget,%A_ThisLabel%, 12:

meno_zaplaty := A_ThisLabel
StringReplace, meno_zaplaty, meno_zaplaty, SETTINGS_,,

ZAPLATY.toggle_zaplata(meno_zaplaty,%A_ThisLabel%)

;iné
SETTINGS_zobrazit_napovedu_tlacidla:
SETTINGS_zobrazit_napovedu_instrukcie:
SETTINGS_zobrazit_kalkulacku:
;SETTINGS_nezobrazeny_cely_obvod_fix_aktivovany:
;SETTINGS_nezobrazeny_cely_obvod_fix_rozlisenie:




GuiControlget,%A_ThisLabel%, 12:
IniWrite, % %A_ThisLabel%,%SETTINGS_path%, nastavenia, %A_ThisLabel%

;msgbox % SETTINGS_zobrazit_kalkulacku
if (A_ThisLabel == "SETTINGS_zobrazit_kalkulacku")
{
	if(SETTINGS_zobrazit_kalkulacku == 1)
	{
		GuiControl, 1:show, GUI_popis_hex_do_dec
		GuiControl, 1:show, GUI_hex_vstup
		GuiControl, 1:show, GUI_dec_vstup
	}
	else
	{
		GuiControl, 1:hide, GUI_popis_hex_do_dec
		GuiControl, 1:hide, GUI_hex_vstup
		GuiControl, 1:hide, GUI_dec_vstup
	}
	
}
if (A_ThisLabel == "SETTINGS_zobrazit_napovedu_tlacidla")
{
		tooltip
}

return




ProgramDoSchranky()
{
	
	program := vypis_instrukcie(pointer_instrukcie)
	;msgbox % program
	if (program != "") {
		tooltip % "Aktuálny program skopírovaný do schránky: `n" . program
		statusbar("Operačný kód skopírovaný do schránky")
		clipboard := program

		sleep, 1000
		tooltip
	}
	else
	{
		tooltip % "Operačný kód je prázdny"
		statusbar("Operačný kód je prázdny")

		sleep, 2000
		tooltip
	}
	

	
	FileDelete, %A_WorkingDir%\temp_asdfghjk.mp	; docasny subor
	return
}




zobraz_instrukcie() {
	if !(WinExist("assembler"))
		WinMenuSelectItem, ahk_id %mipsim_HWND%,, Instruction Memory , View
	else
		winclose, assembler
	
}


zobraz_registre() {
	WinMenuSelectItem, ahk_id %mipsim_HWND%,, Registers , View
}


vymaz_registre() {
	statusbar("Nulujem registre")
	GuiControl,, GUI_vymaz_registre, grafika\x_register_p.png
	if(WinExist("Register"))
	{
		WinMenuSelectItem, ahk_id %mipsim_HWND%,, Registers , Clear
	}
	else
	{
		WinMenuSelectItem, ahk_id %mipsim_HWND%,, Registers , Clear
		if(SETTINGS_vymaz_registre_bez_dalsieho_opytania == 0)
		{
			WinWait, Please confirm:
			sendMessage, 0x111 , 1, 0,, Please confirm:, 	;potvrď
			WinWaitclose Please confirm:
		}

		sleep 50
		winClose, Register
	}
	statusbar("Registre vynulované")
	while (GetKeyState("LButton", "P"))
		sleep 10
	GuiControl,, GUI_vymaz_registre, grafika\x_register.png
	
}

vymaz_data() {
	statusbar("Nulujem dáta")
	GuiControl,, GUI_vymaz_data, grafika\x_data_p.png
	;WinClose , data memory
	if(!WinExist("data memory"))
	{
		postMessage, 0x111 , 32773, 0,, ahk_id %mipsim_HWND%, 	;otvor data memory
	}
	else
	{
		okno_s_pamatou_otvorene := 1
	}
	
	WinWait, data memory
	postMessage, 0x111 , 1012, 0,, data memory, 	;vymaž data memory
	if(SETTINGS_vymaz_datovu_pamat_bez_dalsieho_opytania == 0)
	{
		WinWait, Please confirm:
		sendMessage, 0x111 , 1, 0,, Please confirm:, 	;potvrď
	}
	
	if (!okno_s_pamatou_otvorene)
		WinClose , data memory
	
	statusbar("Dáta vynulované")
	while (GetKeyState("LButton", "P"))
		sleep 10
	GuiControl,, GUI_vymaz_data, grafika\x_data.png
}
vymaz_instrukcie() {
	WinClose , assembler
	postMessage, 0x111 , 32771, 0,, ahk_id %mipsim_HWND%, 	;otvor assembler
	WinWait, assembler
	postMessage, 0x111 , 1007, 0,, assembler, 	;vymaž data memory
	WinWait, Please confirm:
	sendMessage, 0x111 , 1, 0,, Please confirm:, 	;potvrď
	WinClose , assembler
}

zobraz_data() {
	if !(WinExist("data memory"))
		WinMenuSelectItem, ahk_id %mipsim_HWND%,, Data Memory , View
	else
		winclose, data memory
}











; deteguj dvojklik v listview
~LButton::
sleep, 10	;Ak bolo kliknuté na vtedy neaktívne okno
IfWinActive, ahk_id %mipsim_HWND%
{
	
	CoordMode, mouse , screen
	WinGetPos , old_mipsimX, old_mipsimY,,, ahk_id %mipsim_HWND%
	MouseGetPos , old_mouseX, old_mouseY
	
	;tooltip, % OutputVarX "|" OutputVarY
	If (A_TimeSincePriorHotkey<400) and (A_TimeSincePriorHotkey<>-1) {

		MouseGetPos, UnderX, UnderY, WinUnderHwnd, ControlUnder, 
		;;tooltip % ControlUnder
		if instr(ControlUnder, "ListBox1")
		{
			riadok_old := riadok
			riadok := getPoziciaOznacenia()
			
			;nastav breakpoint
			BREAKPOINTY.vytvor_novy_breakpoint(riadok)


			GuiControl, show, GUI_opozdenie
			GuiControl, show, GUI_opozdenie_text
			GuiControl,, GUI_VykonajPoPoziciu, grafika\po_bod.png
			statusbar("Nastavený breakpoint na pozíciu " riadok)

			
		}
	}
}



return

zrus_breakpoint() 
{
	StringReplace, id, A_GuiControl, GUI_breakpoint,,
	BREAKPOINTY.vymaz_breakpoint(id)
}

~LButton up::
IfWinActive, ahk_id %mipsim_HWND%
{
	aktualizuj_rozmery_a_velkost_gui()
}
return











is_MIPSim_aktivny() 
{
	MIPsim_je_aktivny := 0
	if (WinActive("ahk_id " . mipsim_HWND))
		MIPsim_je_aktivny := 1
	else if (WinActive("Register"))
		MIPsim_je_aktivny := 1
	else if (WinActive(nadpis))
		MIPsim_je_aktivny := 1
	else if (WinActive("assembler"))
		MIPsim_je_aktivny := 1
	else if (WinActive("data memory"))
		MIPsim_je_aktivny := 1
	
	return MIPsim_je_aktivny
	; 1 - MIPSim je aktívny
	; 0 - MIPSim nie je aktívny
}





RegistreDoSchranky:
AktualizujObsahRegistrov(1)
return






;Simulation , Stop
~F6::
if !(is_MIPSim_aktivny())
	return

Top:
gosub, STOP
GuiControl,, GUI_Top, grafika\top_p.png
WinMenuSelectItem, ahk_id %mipsim_HWND%,, Simulation , Stop
while (GetKeyState("LButton", "P"))
	sleep 10
GuiControl,, GUI_Top, grafika\top.png

statusbar("Program counter posunutý na začiatok")
return



SETTINGS_DESIATKOVA_SUSTAVA:
GuiControlGet, SETTINGS_DESIATKOVA_SUSTAVA, 8:
GuiControlGet, SETTINGS_VIAC, 8:
IniWrite, %SETTINGS_DESIATKOVA_SUSTAVA%,%SETTINGS_path%, nastavenia, SETTINGS_DESIATKOVA_SUSTAVA
IniWrite, %SETTINGS_VIAC%,%SETTINGS_path%, nastavenia, SETTINGS_VIAC
GRAFICKE_ROZHRANIE.resize_live_registre_a_pamat_gui()
return






;Simulation , Pause
~F7::
if !(is_MIPSim_aktivny())
	return
STOP:
GuiControl,, GUI_PAUSE, grafika\stop_p.png
WinMenuSelectItem, ahk_id %mipsim_HWND%,, Simulation , Pause
while (GetKeyState("LButton", "P"))
	sleep 10

GuiControl,, GUI_PAUSE, grafika\stop.png

prerusit = 1	;preruš autoclicker
statusbar("Program pozastavený")
return


















;Vykonávaj program až po breakpoint
;Vykonávanie programu až do konca, ak breakpoint nie je nastavený
~F8::
if !(is_MIPSim_aktivny())
	return
VykonajPoPoziciu:
prerusit = 0
tooltip
statusbar("Program spustený")
if !(pozicia_oznacenia == -100)
	GuiControl,, GUI_VykonajPoPoziciu, grafika\po_bod_p.png
else
	GuiControl,, GUI_VykonajPoPoziciu, grafika\run_p.png

over_koniec_programu()
if (over_koniec_programu() == 1) {
	gosub, Top
	statusbar("Program spustený odznova")
}
else
{	
	GuiControlGet, GUI_opozdenie
	;if (GUI_opozdenie == 1)	;ak má breakpoint zastavovať priamo na inštrukcii v zozname ("začiatok") - posuň program, ak nie je koniec. Inak by sa po stlačení tlačidla ďalej nič nestalo
		SendMessage, 0x111 , 32783, 0,, ahk_id %mipsim_HWND%	;simulation - step
}

delay_aktualny = -1
IfWinNotExist , ahk_id %mipsim_HWND%
{
	MsgBox 0x42010, , MIPSim nie je spustený
	return	;Nič neurob, keďže mipsim nie je sputený
}

loop 50000
{
	if WinExist("Registre + dátová pamäť")
	{
		vypis_registre(pointer_register)
		vypis_celu_pamat(pointer_pamat)
	}
	


	if (BREAKPOINTY.oznam_vykonany_riadok() == 1)	;nájdený breakpoint
	{
		statusbar("Nájdený breakpoint - program pozastavený")
		GuiControl,, GUI_VykonajPoPoziciu, grafika\po_bod.png
		return
	}
	/*
	if (AktualneVykonavane == pozicia_oznacenia) {
		GuiControlGet, GUI_opozdenie
		delay_aktualny := GUI_opozdenie - 1
		if GUI_opozdenie not contains 0,1,2,3,4,5,6,7,8,9
		{	;zlý vstup
			delay_aktualny = 0
		}
		;msgbox % GUI_opozdenie
		
	}
	*/
	if (delay_aktualny == 0) {
		statusbar("Nájdený breakpoint - program pozastavený")
		GuiControl,, GUI_VykonajPoPoziciu, grafika\po_bod.png
		return
		delay_aktualny = -1
	}
	
	
	
	
	
	if (prerusit = 1) {
		if !(pozicia_oznacenia == -100)
			GuiControl,, GUI_VykonajPoPoziciu, grafika\po_bod.png
		else
			GuiControl,, GUI_VykonajPoPoziciu, grafika\run.png
		prerusit = 0
		break
	}
	
	
	if (over_koniec_programu() == 1) {
		statusbar("Program ukončený")
		if !(pozicia_oznacenia == -100)
			GuiControl,, GUI_VykonajPoPoziciu, grafika\po_bod.png
		else
			GuiControl,, GUI_VykonajPoPoziciu, grafika\run.png
		;MsgBox 0x40040, , Koniec programu
		break
	}
	

	
	
	;tooltip % "Oznacenie: " getPoziciaOznacenia() "`nScrollbar:     " getPoziciaScrollbaru() "`nUkazovatel: " getPoziciaUkazovatela() "`nAktualneVykonavane: " getAktualneVykonavane()
	
	;tooltip % AktualneVykonavane "|" pozicia_oznacenia
	
	if !(pozicia_oznacenia == -100)	;Ak je nastavený breakpoint
		pocet_cyklov = 1
	else
		pocet_cyklov = 1
	
	loop %pocet_cyklov% {
		if (prerusit = 1) {
			break
		}
		;suradnica_x := round(289 * DPI_nasobitel)
		;suradnica_y := round(69 * DPI_nasobitel)
		;ControlClick , x%suradnica_x% y%suradnica_y%, ahk_id %mipsim_HWND%,,,,,,
		;WinMenuSelectItem, ahk_id %mipsim_HWND%,, Simulation , Step
		SendMessage, 0x111 , 32783, 0,, ahk_id %mipsim_HWND%	;simulation - step
		;sleep 50
	}

	
	;sleep 500

	if (delay_aktualny > 0) {
		delay_aktualny--
	}
}

return

;debug
^p::
tooltip % AktualneVykonavane := BREAKPOINTY.ziskaj_aktualne_vykonavany_riadok()
return

~F9::
if !(is_MIPSim_aktivny())
	return
vymaz_registre()
return

~F12::
if !(is_MIPSim_aktivny())
	return
vymaz_data()
return





over_koniec_programu() {
	list := ""
	loop 5 {
		offset_temp := offset_instrukcie_gui - (6 - a_index)	;Vypočíta relatívny offset umiestnenia aktuálne vykonávaných inštrukcií
		
		if (offset_temp < 0 && offset_temp != "")	; pri vypnutí programu je offset_temp -4 (nemôže byť záporný)
			exitapp
			
		ControlGetText, nopka%offset_temp% , AfxWnd42s%offset_temp%, ahk_id %mipsim_HWND%,,,
		;tooltip % nopka%offset_temp%
		;tooltip % offset_instrukcie_gui
		if nopka not contains ADD,AND,BEQ,BNEQ,DIV,LI,LUI,LW,MUL,NOP,OR,SLLV,SRLV,SUB,SW,XOR
		{
			offset_instrukcie_gui := najdi_offset()
			;tooltip % offset
			;Bude v vrátená hodnota 0. To nevadí, lebo v ďalšom cykle sa to napraví po opravení offsetu
		}
		if (nopka%offset_temp% != "NOP "){	;nie je koniec programu, ak nejaká inštrukcia obsahuje niečo iné AKO NOP - teda hne%d odíď z cyklu
			return 0
		}
	}
	
	return 1 ;Koniec programu ak sa dostalo do konca
}








pocet_okien(nadpis) {
	WinGet, pocet_okien, List, %nadpis%
	return %pocet_okien%
}








velkost_retazca(retazec) {
	velkost_retazca = 0
	Loop, parse, retazec,
	{	
		velkost_retazca := A_Index
	}
	return % velkost_retazca
}


padding_nulami(retazec, kolko_miest, znak := "0") {

	velkost_retazca := velkost_retazca(retazec)
	if (velkost_retazca > kolko_miest) {	;ak pretečenie, vráť reťazec
		return % retazec
	}

	;padding zľava nulami
	loop % kolko_miest - velkost_retazca
		retazec := znak . retazec
	return % retazec
}








RemoveToolTip()
{
	ToolTip
	return
}




uloz_stav_registrov()
{
	static buffer
	VarSetCapacity(buffer, 124)
	mipsim_obj.readraw(pointer_register, buffer, 124)
	
	file := FileOpen(A_WorkingDir "\ulozeny_stav_registrov.mr", "w")
	file.RawWrite(buffer, 124)
	file.Close()
}
obnov_stav_registrov()
{
	if (!FileExist(A_WorkingDir "\ulozeny_stav_registrov.mr"))
	{
		msgbox % "Pred použitím obnovenia najskôr uložte stav registrov stlačením tlačidla 'Ulož'"
		return
	}
	file := FileOpen(A_WorkingDir "\ulozeny_stav_registrov.mr", "r")
	VarSetCapacity(buffer, 124)
	file.RawRead(buffer, 124)
	file.Close()
	
	mipsim_obj.writeRaw(pointer_register, &buffer, 124)
	
	;obnov grafické rozhranie, ktoré sa neaktualizuje po nakopírovaní pamäte
	DetectHiddenWindows, On
	loop 31 {
		hodnota_hex := funkcie_hex.dec_do_unsigned_hex(NumGet(buffer , (A_Index - 1) * 4, "UInt"))
		StringReplace, hodnota_hex, hodnota_hex, 0x,,
		
		hodnota_hex := padding_nulami(hodnota_hex, 8)
		ControlSetText ,Edit%A_Index%, %hodnota_hex%, Register
	}
	DetectHiddenWindows, Off
}
uloz_stav_datovej_pamate()
{
	static buffer
	VarSetCapacity(buffer, 1024)
	mipsim_obj.readraw(pointer_pamat, buffer, 1024)
	
	file := FileOpen(A_WorkingDir "\ulozeny_stav_datovej_pamate.md", "w")
	file.RawWrite(buffer, 1024)
	file.Close()
}
obnov_stav_datovej_pamate()
{
	if (!FileExist(A_WorkingDir "\ulozeny_stav_datovej_pamate.md"))
	{
		msgbox % "Pred použitím obnovenia najskôr uložte stav dátovej pamäte stlačením tlačidla 'Ulož'"
		return
	}
	file := FileOpen(A_WorkingDir "\ulozeny_stav_datovej_pamate.md", "r")
	VarSetCapacity(buffer, 1024)
	file.RawRead(buffer, 1024)
	file.Close()
	
	mipsim_obj.writeRaw(pointer_pamat, &buffer, 1024)
}





/*
pattern := mipsim_obj.hexStringToPattern("DE C0 13 42")	;4213C0DE



file := FileOpen(A_WorkingDir "\ulozeny_stav_registrov.mr", "r")
VarSetCapacity(buffer, 124)
file.RawRead(buffer, 124)
file.Close()

mipsim_obj.writeRaw(pointer_register, &buffer, 124)
*/


global gui_hwnd_registre
global gui_hwnd_data_1
global gui_hwnd_data_2
global EDITOR_HODNOT

;keyboard editor
#MaxHotkeysPerInterval 99999
#ifwinactive Registre + dátová pamäť
~0::
~Numpad0::
editor_hodnot.register_key(0)
return
~1::
~Numpad1::
editor_hodnot.register_key(1)
return
~2::
~Numpad2::
editor_hodnot.register_key(2)
return
~3::
~Numpad3::
editor_hodnot.register_key(3)
return
~4::
~Numpad4::
editor_hodnot.register_key(4)
return
~5::
~Numpad5::
editor_hodnot.register_key(5)
return
~6::
~Numpad6::
editor_hodnot.register_key(6)
return
~7::
~Numpad7::
editor_hodnot.register_key(7)
return
~8::
~Numpad8::
editor_hodnot.register_key(8)
return
~9::
~Numpad9::
editor_hodnot.register_key(9)
return
/*
~a::
~+a::
editor_hodnot.register_key("A")
return
~b::
~+b::
editor_hodnot.register_key("B")
return
~c::
~+c::
editor_hodnot.register_key("C")
return
~d::
~+d::
editor_hodnot.register_key("D")
return
~e::
~+e::
editor_hodnot.register_key("E")
return
~f::
~+f::
editor_hodnot.register_key("F")
return
*/

~-::
~NumpadSub::
editor_hodnot.register_key("-")
return

~NumpadAdd::
editor_hodnot.register_key("+")
return

Up::
~WheelUp::
obj_mipsnejk.zmen_smer("up")
editor_hodnot.pridaj(1)
return

Down::
~WheelDown::
obj_mipsnejk.zmen_smer("down")
editor_hodnot.pridaj(-1)
return


Left::
obj_mipsnejk.zmen_smer("left")
return

Right::
obj_mipsnejk.zmen_smer("right")
return

~Backspace::
editor_hodnot.vymaz_key()
return

~Delete::
editor_hodnot.nastav_na_nulu()
return

^c::
editor_hodnot.skopiruj_do_schranky()
return

~^v::
editor_hodnot.vloz_zo_schranky()
return

f11::
obj_mipsnejk.start_stop()
return

#ifwinactive

~Esc::
obj_mipsnejk.pause_game()
~Enter::
editor_hodnot.ukonci_editaciu()
return

keyboard_hook_init() {
	SetTimer, keyboard_hook_init, off
	EDITOR_HODNOT.keyboard_hook()
}

class editor_hodnot {
	aktualna_hodnota := ""
	pointer := 0
	textovy_opis_miesta_editacie := ""
	upravovany_register := 0	;ak je upravovana pamat, upravovany register je nastaveny na 0
	
	__New() {
		this.clickable_edit_registre := new clickable_edit_registre()
		this.clickable_edit_datova_pamat := new clickable_edit_datova_pamat()
	}
	
	ukonci_editaciu() {
		this.aktualna_hodnota := ""
		this.textovy_opis_miesta_editacie := ""
		this.pointer := 0
		tooltip
	}
	
	novy_pointer(pointer, textovy_opis_miesta_editacie, upravovany_register:=0) {
		this.textovy_opis_miesta_editacie := textovy_opis_miesta_editacie
		this.pointer := pointer
		this.upravovany_register := upravovany_register
		this.aktualna_hodnota := mipsim_obj.read(this.pointer, "Int")
		this.info_box()
	}
	
	register_key(key) {
		if (this.pointer == 0)	;nie je čo editovať
			return
		
		
		if (key == "-") {
			if (this.aktualna_hodnota == 0 || this.aktualna_hodnota == "") {
				this.aktualna_hodnota := "-"
			}
			else {
				this.aktualna_hodnota *= -1
			}
		}
		else if (key == "+") {
			this.aktualna_hodnota := abs(this.aktualna_hodnota)
		}
		else
		{
			;vymaž prvotnú nulu pred zápisom niečoho
			if (this.aktualna_hodnota == 0)
				this.aktualna_hodnota := ""
			
			;zapíš
			this.aktualna_hodnota .= key
			
		}
			
			
		
			
		this.zapis_hodnotu_do_pamate()
	}
	
	pridaj(kolko) {
		if (this.pointer != 0) {
			this.aktualna_hodnota += kolko
			this.zapis_hodnotu_do_pamate()		
		}
	}
	
	vymaz_key() {
		this.aktualna_hodnota := substr(this.aktualna_hodnota, 1, -1)
		this.zapis_hodnotu_do_pamate()
	}
	
	nastav_na_nulu() {
		this.aktualna_hodnota := 0
		this.zapis_hodnotu_do_pamate()
		this.ukonci_editaciu()
	}
	
	skopiruj_do_schranky() {
		if (this.pointer == 0) {
			GuiControlGet, GUI_registre, 8:
			GuiControlGet, GUI_data, 8:
			GuiControlGet, GUI_data2, 8:
			clipboard := "Registre:`n" GUI_registre "`n`nDátová pamäť:`n" GUI_data "`n`n" GUI_data2 
		}
		else
		{
			clipboard := this.aktualna_hodnota
			this.ukonci_editaciu()
		}
	}
	vloz_zo_schranky() {
		this.aktualna_hodnota := ""
		Loop, parse, clipboard,,
		{	
			znak := A_LoopField
			if znak contains 0,1,2,3,4,5,6,7,8,9,-
			{
				this.register_key(znak)
			}
		}
		this.ukonci_editaciu()
	}
	
	info_box() {
		if (this.pointer == 0)	;chyba - nie je kde zapisovať
			return -1
		
		cislo := this.aktualna_hodnota	;string to int
		if (cislo == "" || cislo == "-")
			cislo := 0
		hex := funkcie_hex.dec_do_signed_hex(cislo)
		StringReplace, hex, hex, 0x,
		
		error_info := ""
		if (hex == "Pretečenie")
			error_info := "`n`nčíslo nebolo možné zapísať z dôvodu pretečenia"
		else if (this.upravovany_register != 0)	;aktualizuj hodnotu aj v starom GUI
			ControlSetText ,% "Edit" this.upravovany_register, % padding_nulami(hex, 8), Register
			
		tooltip % this.textovy_opis_miesta_editacie "`nDEC: " this.aktualna_hodnota "`nHEX: " hex "`n(enter pre potvrdenie)" error_info
		
		if (error_info != "")	;vyskytla sa chyba - nezapisuj číslo do pamäte
			return -1
	}
	
	zapis_hodnotu_do_pamate() {
		if (this.info_box() != -1)
			mipsim_obj.write(this.pointer, this.aktualna_hodnota, "Int")
	}
	
	
	aktualizuj_oznacenie() {
		this.clickable_edit_registre.aktualizuj_oznacenie()
		this.clickable_edit_datova_pamat.aktualizuj_oznacenie()
	}
	
}


class clickable_edit_registre {
	offsety := []
	dlzka_jednej_hodnoty := 0
	
	__New() {
		this.aktualizuj_dlzku_jednej_hodnoty()
		this.vygeneruj_offsety_registrov()
		this.vypis_offsety()
		
		
		;SetTimer, keyboard_hook_init, 1000
	}
	
	vygeneruj_offsety_registrov() {
		;Velkosti premennych
		this.offsety := []
		loop 31 {
			this.offsety[a_index] := 4 + a_index * (this.dlzka_jednej_hodnoty + 6)
			;msgbox % this.offsety[a_index - 1]
		}
	}
	
	aktualizuj_dlzku_jednej_hodnoty() {
		if (SETTINGS_DESIATKOVA_SUSTAVA == 1) 
			this.dlzka_jednej_hodnoty := 12
		else
			this.dlzka_jednej_hodnoty := 8
	}
	
	vypis_offsety() {
		;msgbox % "|" this.offsety[0]
		;msgbox % "|" this.offsety[1]
		;msgbox % "|" this.offsety[2]
	}
	
	aktualizuj_oznacenie() {
	
		GuiControlGet, aktualny_focus, 8:Focus
		if (aktualny_focus != "Edit1")
			return
			
		this.aktualizuj_dlzku_jednej_hodnoty()
		this.vygeneruj_offsety_registrov()
		Edit_GetSelection(start, end, gui_hwnd_registre)
		
		;tooltip % start "|" end
		
		if (start - end > 9)	;už niečo je označené
			return
		
		if (start < this.offsety[0])
			return
			
		for cislo_registra, offset_v_zozname in this.offsety {
			;msgbox % "O" offset_v_zozname "o" this.offsety[0]
			if (start >= offset_v_zozname && start <= offset_v_zozname + this.dlzka_jednej_hodnoty) {
				Edit_Select(offset_v_zozname, offset_v_zozname + this.dlzka_jednej_hodnoty, gui_hwnd_registre)
			}
			if (start > offset_v_zozname && start <= offset_v_zozname + this.dlzka_jednej_hodnoty) {	;nájdený správny offset
				this.nastav_register_na_upravu(cislo_registra)
			}
		}
	}
	
	nastav_register_na_upravu(cislo_registra) {
		EDITOR_HODNOT.novy_pointer(pointer_register + 4 * (cislo_registra - 1), "Editácia registra č. " cislo_registra ":", cislo_registra)
	}
}



class clickable_edit_datova_pamat {
	offsety := []
	dlzka_jednej_hodnoty := 0
	zaciatocny_offset := 0
	
	__New() {
		this.aktualizuj_dlzku_jednej_hodnoty()
		this.vygeneruj_offsety_datovej_pamate()
		this.vypis_offsety()
	}
	
	vygeneruj_offsety_datovej_pamate() {
		;Velkosti premennych
		this.offsety := []
		
		index_cislo := 0
		aktualny_offset := this.zaciatocny_offset
		loop 32 {	;32 riadkov
			cislo_riadka := a_index - 1
			loop 4 {
				this.offsety[index_cislo] := aktualny_offset 
				aktualny_offset += + 1 + this.dlzka_jednej_hodnoty
				;msgbox % this.offsety[index_cislo]
				index_cislo++
			}
			aktualny_offset += this.zaciatocny_offset + 1
		}
	}
	
	aktualizuj_dlzku_jednej_hodnoty() {
		if (SETTINGS_DESIATKOVA_SUSTAVA == 1) {
			this.dlzka_jednej_hodnoty := 11
			this.zaciatocny_offset := 5
		}
		else {
			this.dlzka_jednej_hodnoty := 8
			this.zaciatocny_offset := 4
		}
	}
	
	vypis_offsety() {
		;msgbox % "|" this.offsety[0]
		;msgbox % "|" this.offsety[1]
		;msgbox % "|" this.offsety[2]
	}
	
	aktualizuj_oznacenie() {
		GuiControlGet, aktualny_focus, 8:Focus
		;tooltip % aktualny_focus
		if (aktualny_focus != "Edit2" && aktualny_focus != "Edit3")
			return
			
		if (aktualny_focus == "Edit2") {
			gui_hwnd := gui_hwnd_data_1
			offset_od_zaciatku := 0
		}
		if (aktualny_focus == "Edit3") {
			gui_hwnd := gui_hwnd_data_2
			offset_od_zaciatku := 32 * 4	;32 riadkov * 4 stĺpce
		}
			
		this.aktualizuj_dlzku_jednej_hodnoty()
		this.vygeneruj_offsety_datovej_pamate()
		Edit_GetSelection(start, end, gui_hwnd)
		
		;tooltip % start "|" end
		
		if (start - end > 9)	;už niečo je označené
			return
		
		if (start < this.offsety[0])
			return
			
		for cislo_pamate, offset_v_zozname in this.offsety {
			;msgbox % "O" offset_v_zozname "o" this.offsety[0]
			if (start >= offset_v_zozname && start <= offset_v_zozname + this.dlzka_jednej_hodnoty) {
				Edit_Select(offset_v_zozname, offset_v_zozname + this.dlzka_jednej_hodnoty, gui_hwnd)
			}
			if (start > offset_v_zozname && start <= offset_v_zozname + this.dlzka_jednej_hodnoty) {	;nájdený správny offset
				this.nastav_datovu_pamat_na_upravu(offset_od_zaciatku + cislo_pamate)
			}
		}
	}
	
	nastav_datovu_pamat_na_upravu(cislo_pamate) {
		hex := funkcie_hex.dec_do_signed_hex(cislo_pamate * 4)
		StringReplace, hex, hex, 0x,
		
		EDITOR_HODNOT.novy_pointer(pointer_pamat + 4 * cislo_pamate, "Editácia dátovej pamäte na adrese " (cislo_pamate * 4) " (HEX " hex "):")
	}
}











;************************
; Edit Control Functions
;************************
;
; Standard parameters:
;   Control, WinTitle   If WinTitle is not specified, 'Control' may be the
;                       unique ID (hwnd) of the control.  If "A" is specified
;                       in Control, the control with input focus is used.
;
; Standard/default return value:
;   true on success, otherwise false.
; https://autohotkey.com/board/topic/20981-edit-control-functions/

Edit_Standard_Params(ByRef Control, ByRef WinTitle) {  ; Helper function.
    if (Control="A" && WinTitle="") { ; Control is "A", use focused control.
        ControlGetFocus, Control, A
        WinTitle = A
    } else if (Control+0!="" && WinTitle="") {  ; Control is numeric, assume its a ahk_id.
        WinTitle := "ahk_id " . Control
        Control =
    }
}

; Returns true if text is selected, otherwise false.
;
Edit_TextIsSelected(Control="", WinTitle="")
{
    Edit_Standard_Params(Control, WinTitle)
    return Edit_GetSelection(start, end, Control, WinTitle) and (start!=end)
}

; Gets the start and end offset of the current selection.
;
Edit_GetSelection(ByRef start, ByRef end, Control="", WinTitle="")
{
    Edit_Standard_Params(Control, WinTitle)
    VarSetCapacity(start, 4), VarSetCapacity(end, 4)
    SendMessage, 0xB0, &start, &end, %Control%, %WinTitle%  ; EM_GETSEL
    if (ErrorLevel="FAIL")
        return false
    start := NumGet(start), end := NumGet(end)
    return true
}

; Selects text in a text box, given absolute character positions (starting at 0.)
;
; start:    Starting character offset, or -1 to deselect.
; end:      Ending character offset, or -1 for "end of text."
;
Edit_Select(start=0, end=-1, Control="", WinTitle="")
{
    Edit_Standard_Params(Control, WinTitle)
    SendMessage, 0xB1, start, end, %Control%, %WinTitle%  ; EM_SETSEL
    return (ErrorLevel != "FAIL")
}

; Selects a line of text.
;
; line:             One-based line number, or 0 to select the current line.
; include_newline:  Whether to also select the line terminator (`r`n).
;
Edit_SelectLine(line=0, include_newline=false, Control="", WinTitle="")
{
    Edit_Standard_Params(Control, WinTitle)
    
    ControlGet, hwnd, Hwnd,, %Control%, %WinTitle%
    if (!WinExist("ahk_id " hwnd))
        return false
    
    if (line<1)
        ControlGet, line, CurrentLine
    
    SendMessage, 0xBB, line-1, 0  ; EM_LINEINDEX
    offset := ErrorLevel

    SendMessage, 0xC1, offset, 0  ; EM_LINELENGTH
    lineLen := ErrorLevel

    if (include_newline) {
        WinGetClass, class
        lineLen += (class="Edit") ? 2 : 1 ; `r`n : `n
    }
    
    ; Select the line.
    SendMessage, 0xB1, offset, offset+lineLen  ; EM_SETSEL
    return (ErrorLevel != "FAIL")
}

; Deletes a line of text.
;
; line:     One-based line number, or 0 to delete current line.
;
Edit_DeleteLine(line=0, Control="", WinTitle="")
{
    Edit_Standard_Params(Control, WinTitle)
    ; Select the line.
    if (Edit_SelectLine(line, true, Control, WinTitle))
    {   ; Delete it.
        ControlSend, %Control%, {Delete}, %WinTitle%
        return true
    }
    return false
}














;Mipsnejk easter egg
snejk_update:
obj_mipsnejk.game_update()
return

class mipsnejk {
	started := "never"
	riadkov := 32
	stlpcov := 22
	padding := " "
	
	snejk := []
	snejk_smer := "down"
	snejk_smer_buffer := []
	
	obrazovka_overlay := []
	obrazovka_snejk := []
	obrazovka_pozadie := []
	
	highscore := 0

	__New() {
		IniRead, mipsnejk_highscore,%SETTINGS_path%, nastavenia, mipsnejk, 0
		this.highscore := mipsnejk_highscore
		
		
	}
	
	start_stop() {
		editor_hodnot.ukonci_editaciu()
		if (this.started == "never") {
			this.start()
		}
		else if (this.started == "yes") {
			this.pause_game()
		}
		else if (this.started == "no") {
			this.started := "yes"
			this.continue_game()
		}
	}
	
	start() {
		this.started := "yes"
		this.restart()
	}
	
	pause_game() {
		this.started := "no"
		settimer, snejk_update, off
		vypis_celu_pamat(pointer_pamat, 1)	;späť na originálnu funkcionalitu
	}
	
	restart() {
		this.vytvor_array()
		this.continue_game()
	}
	
	continue_game() {
		settimer, snejk_update, 120
	}
	
	game_update() {
		this.vybuduj_scenu()
		this.snejk_chod_dalej()
		this.aktualizuj_informacny_panel()
	}
	
	zmen_smer(novy_smer) {
		if (novy_smer == this.snejk_smer_buffer[this.snejk_smer_buffer.Length()])	;tento smer je už zaregistrovaný
			return
		this.snejk_smer_buffer.Push(novy_smer)	;pridaj smer do buffera
	}
	
	get_snejk_smer_z_buffera() {
		;tooltip % "ww" this.snejk_smer_buffer.Length()
		loop {
			novy_smer := this.snejk_smer_buffer.Pop()
			if (novy_smer == "")	;buffer prázdny, nemeň smer
				return
				
			;nemôže sa otočiť o 180°
			if (this.snejk_smer == "down" && novy_smer == "up")
				continue
			if (this.snejk_smer == "up" && novy_smer == "down")
				continue
			if (this.snejk_smer == "left" && novy_smer == "right")
				continue
			if (this.snejk_smer == "right" && novy_smer == "left")
				continue
				
			break	;nový smer je OK
		}
		
		this.snejk_smer := novy_smer
	}
	
	vygeneruj_jablko() {
		;vyčisti array
		loop % this.riadkov {
			riadok := A_Index - 1
			loop % this.stlpcov {
				stlpec := A_Index - 1
				this.obrazovka_overlay[riadok][stlpec] := " "
			}
		}
		loop {
			Random, nahodny_riadok , 1, this.riadkov - 1
			Random, nahodny_stlpec , 1, this.stlpcov - 1
			;tooltip % nahodny_riadok "|" nahodny_stlpec

			if (this.obrazovka_snejk[nahodny_riadok][nahodny_stlpec] != " ")	;na tomto mieste je snejk
				continue
			if (this.obrazovka_pozadie[nahodny_riadok][nahodny_stlpec] != " ")	;na tomto mieste je ohrada
				continue
				
			break	;všetko OK
		}
		this.obrazovka_overlay[nahodny_riadok][nahodny_stlpec] := "●"
	}
	
	vytvor_array() {
		GuiControl, 8:Focus, GUI_data
		;Vytvor obrazovky
		loop % this.riadkov {	; 15 riadkov
			riadok := A_Index - 1
			this.obrazovka_pozadie[riadok] := []
			this.obrazovka_snejk[riadok] := []
			this.obrazovka_overlay[riadok] := []
			loop % this.stlpcov {
				stlpec := A_Index - 1
				this.obrazovka_pozadie[riadok][stlpec] := " "
				this.obrazovka_snejk[riadok][stlpec] := " "
				this.obrazovka_overlay[riadok][stlpec] := " "
				
				
				if (stlpec == 0 || riadok == 0 || stlpec == this.stlpcov - 1 || riadok == this.riadkov - 1)
					this.obrazovka_pozadie[riadok][stlpec] := "@"
			}
		}
		
		this.vytvor_array_pridaj_kamene(8, 8, 11)
		this.vytvor_array_pridaj_kamene(4, 14, 2)
		this.vytvor_array_pridaj_kamene(5, 22, 5)
		
		;zresetuj snejka
		this.snejk := []
		
		
		;vytvor snejka
		this.snejk[0] := "5|5"
		this.snejk[1] := "5|6"
		this.snejk[2] := "5|7"
		this.snejk[3] := "5|8"
		this.snejk[4] := "6|8"
		this.snejk[5] := "7|8"
		
		this.snejk_smer_buffer := []
		this.snejk_smer := "right"
		this.vygeneruj_jablko()
	}
	
	vytvor_array_pridaj_kamene(velkost_kamena, riadok_offset, stlpec_offset) {
		loop %velkost_kamena% {
			riadok := a_index + riadok_offset
			loop %velkost_kamena% {
				stlpec := a_index + stlpec_offset
				this.obrazovka_pozadie[riadok][stlpec] := "@"
			}
		}
	}
	
	snejk_chod_dalej() {
		/*
		list_pozicii := 
		For key, value in this.snejk {
			list_pozicii .= value "`n"
		}
		tooltip % list_pozicii
		*/
		posledne_suradnice := this.snejk[this.snejk.Length()]
		Loop, parse, % posledne_suradnice, |,
		{	
			if (A_Index == 1)
				riadok := A_LoopField
			else if (A_Index == 2)
				stlpec := A_LoopField
		}
		
		this.get_snejk_smer_z_buffera()
		if (this.snejk_smer == "right")
			stlpec += 1
		else if (this.snejk_smer == "left")
			stlpec -= 1
		else if (this.snejk_smer == "up")
			riadok -= 1
		else if (this.snejk_smer == "down")
			riadok += 1
		
		
		;skontroluj, či sa nová adresa neprekrýva so starým snejkom
		nova_adresa := riadok "|" stlpec 
		For key, value in this.snejk {
			if (value == nova_adresa) {
				this.restart()
				return
			}
				
		}
		if (this.obrazovka_overlay[riadok][stlpec] != " ") {	;na tejto pozícií je jablko 
			this.obrazovka_overlay[riadok][stlpec] := " "
			this.snejk.Push(nova_adresa)
			this.vygeneruj_jablko()
		}
		else
		{
			this.snejk.RemoveAt(0)
			this.snejk.Push(nova_adresa)
		}
			
		
	}
	
	vycisti_array(nazov_array) {
		
	}
	
	vybuduj_poziciu_snejka_do_array() {
		;vyčisti array
		loop % this.riadkov {
			riadok := A_Index - 1
			loop % this.stlpcov {
				stlpec := A_Index - 1
				this.obrazovka_snejk[riadok][stlpec] := " "
			}
		}
		
		For key, value in this.snejk {
			Loop, parse, % this.snejk[key], |,
			{	
				if (A_Index == 1)
					riadok := A_LoopField
				else if (A_Index == 2)
					stlpec := A_LoopField
			}
			this.obrazovka_snejk[riadok][stlpec] := "█"
		}
	}
	
	vybuduj_scenu() {
		this.vybuduj_poziciu_snejka_do_array()
		scena := ""
		loop % this.riadkov {	; 15 riadkov
			riadok := A_Index - 1

			loop % this.stlpcov {
				stlpec := A_Index - 1
				obrazovka_pozadie := this.obrazovka_pozadie[riadok][stlpec]
				obrazovka_snejk := this.obrazovka_snejk[riadok][stlpec]
				obrazovka_overlay := this.obrazovka_overlay[riadok][stlpec]
				if (obrazovka_pozadie != " ")
					scena .= obrazovka_pozadie
				else if (obrazovka_snejk != " ")
					scena .= obrazovka_snejk
				else if (obrazovka_overlay != " ")
					scena .= obrazovka_overlay
				else
					scena .= " "
					
				if (obrazovka_pozadie != " " && obrazovka_snejk != " ") {	;kolízia
					this.restart()
					return
				}
				
				scena .= this.padding
			}
			scena .= "`n"
		}
		GuiControlGet, GUI_data, 8:
		if (GUI_data != scena)
			GuiControl, 8:, GUI_data, %scena%
			
		;tooltip % scena
	}
	
	aktualizuj_informacny_panel() {
		score := this.snejk.Length() - 5
		highscore := this.highscore
		
		if (score == 489 && highscore != 489) {
			msgbox % "Gratulujeme!!! Úspešne ste dokončili mipsnejk!!! `n`nPre mňa je záhada, ako sa vám to podarilo? Veď ovládanie tejto hry je úplne nepoužiteľné! (hlavne keď sa chcete otočit o 180°)"
		}
		if (highscore > 490) {	;489 je maximálne možné skóre
			score := 0
			highscore := 0
			this.highscore := 0
			IniWrite, 0,%SETTINGS_path%, nastavenia, mipsnejk
			
			msgbox % "Gratulujeme!!! Dosiahli ste ešte väčšie skóre, ako je maximálne možné!!!`n`nAký má zmysel tráviť hodiny nad nejakou hrou, keď môžem jednoducho prepísať hodnotu mipsnejk v súbore nastavenia.ini, však?`n`nMáme pre teba nový quest: Zisti, aké je maximálne možné skóre v hre mipsnejk :)"
		}
		if (highscore < 0) {
			msgbox % "Gratulujeme!!! Dosiahli ste až také veľké skóre, že PRETIEKOL INTEGER!!!"
		}
		
		;tooltip % score "|" highscore
		if (score > highscore) {
			
			highscore := score
			this.highscore := score
			IniWrite, %highscore%,%SETTINGS_path%, nastavenia, mipsnejk
		}
		info = 
(
 
        █   █  █  ███          ██
        ██ ██  █  █  █         █ ██
        █ █ █  █  ███   ████████   ██
        █   █  █  █            █     ██
        █   █  █  █             ██     ██
                                  ██     ██
  ███  █   █  ████  ████ █  █   ██     ██
 █     ██  █  █        █ █ █   █     ██
  ██   █ █ █  ████     █ ██  ███   ██
    █  █  ██  █     █  █ █ █   █ ██
 ███   █   █  ████   ██  █  █  ██

Score: %score%
Highscore: %highscore%
















Ukončite stlačením esc
)
		GuiControl, 8:, GUI_data2, %info%
		
		
	}
}



#include funkcie_hex.ahk


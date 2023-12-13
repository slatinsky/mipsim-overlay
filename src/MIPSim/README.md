## Modifikovaná MIPSIM binárka

Táto MIPSIM.exe je takmer ako originálna binárka zo zložky `original/`, ale má aplikovanú jedinú záplatu `mensi_obvod_patch.1337`. Tento patch zmenší zobrazenie obvodu, pretože pôvodná logika predpokladá, že váš monitor má pomer strán 4:3. Tento patch je možné používať aj bez overlayu, ale cez overlay je konfigurovateľná veľkosť zmenšenia.

Pre konfiguráciu bez overlayu zmente hodnotu v patchi `mensi_obvod_patch.1337` v časti `0003FA52:00->0D`, zvoľte hodnoty medzi `01` a `10` (hexa). Hodnota `0D` je predvolená hodnota a predstavuje zmenšenie `šírka okna / 16 * 13`

Tento patch je portebné mať aplikovaný pri spustení MIPSIMu - preto je ho potrebné aplikovať priamo do binárky a nestačí program dynamicky plátať počas behu tak, ako je to vykonávané pre zvyšok záplat.
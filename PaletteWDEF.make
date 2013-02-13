#Photoshop version 1.0.1, file: PaletteWDEF.make
#  Computer History Museum, www.computerhistory.org
#  This material is (C)Copyright 1990 Adobe Systems Inc.
#  It may not be distributed to third parties.
#  It is licensed for non-commercial use according to 
#  www.computerhistory.org/softwarelicense/photoshop/ 

PaletteWDEF : PaletteWDEF.p.o
	Link \
		-o PaletteWDEF \
		-rt WDEF=2 \
		-m PALETTEWDEF \
		-sn Main='Palette' \
		PaletteWDEF.p.o
	Delete PaletteWDEF.p.o

PaletteWDEF.p.o : PaletteWDEF.p
	Pascal PaletteWDEF.p -z -r

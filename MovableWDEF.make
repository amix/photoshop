#Photoshop version 1.0.1, file: MovableWDEF.make
#  Computer History Museum, www.computerhistory.org
#  This material is (C)Copyright 1990 Adobe Systems Inc.
#  It may not be distributed to third parties.
#  It is licensed for non-commercial use according to 
#  www.computerhistory.org/softwarelicense/photoshop/ 

MovableWDEF : MovableWDEF.p.o
	Link \
		-o MovableWDEF \
		-rt WDEF=3 \
		-m MOVABLEWDEF \
		-sn Main='Movable' \
		MovableWDEF.p.o
	Delete MovableWDEF.p.o

MovableWDEF.p.o : MovableWDEF.p
	Pascal MovableWDEF.p -z -r

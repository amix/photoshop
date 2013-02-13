{Photoshop version 1.0.1, file: UPressure.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UPressure;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop;

VAR
	gHavePressure: BOOLEAN;

PROCEDURE InitPressure;

FUNCTION UsingPressure: BOOLEAN;

FUNCTION ReadPressure: INTEGER;

IMPLEMENTATION

{$I UPressure.inc1.p}

END.

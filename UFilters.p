{Photoshop version 1.0.1, file: UFilters.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UFilters;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UProgress;

CONST
	cFacetPass1 		= -1;
	cFacetPass2 		= -2;
	cFacetPass3 		= -3;
	cFacetPass4 		= -4;
	cDiffuseDarken		= -5;
	cDiffuseLighten 	= -6;
	cSelectFringeNarrow = -7;
	cSelectFringeWide	= -8;

	kMaxParameters = 27;

VAR
	gFilterParameter: ARRAY [1..kMaxParameters] OF LONGINT;

PROCEDURE GaussianFilter (data: TVMArray;
						  VAR r: Rect;
						  width: INTEGER;
						  quick: BOOLEAN;
						  canAbort: BOOLEAN);

PROCEDURE MinOrMaxFilter (srcArray: TVMArray;
						  dstArray: TVMArray;
						  r: Rect;
						  radius: INTEGER;
						  maxFlag: BOOLEAN;
						  alternate: BOOLEAN);

PROCEDURE Do3by3Filter (srcArray: TVMArray;
						dstArray: TVMArray;
						r: Rect;
						which: INTEGER);

IMPLEMENTATION

{$I UFilters.inc1.p}

END.

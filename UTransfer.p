{Photoshop version 1.0.1, file: UTransfer.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UTransfer;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UBWDialog, UScreen;

TYPE
	TTransferArray = ARRAY [0..20] OF INTEGER;

PROCEDURE SolveTransfer (spec: TTransferSpec;
						 VAR transfer: TTransferArray);

PROCEDURE SetTransferFunction (VAR spec: TTransferSpec;
							   VAR gamma: INTEGER);

PROCEDURE SetTransferFunctions (VAR specs: TTransferSpecs;
								VAR gamma: INTEGER);

IMPLEMENTATION

{$I UTransfer.inc1.p}

END.

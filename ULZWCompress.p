{Photoshop version 1.0.1, file: ULZWCompress.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT ULZWCompress;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop;

VAR
	lzwWordSize: INTEGER;

PROCEDURE LZWCompress (codeSize: INTEGER;
					   FUNCTION GetData (VAR pixel: INTEGER): BOOLEAN;
					   PROCEDURE PutCodeWord (code: INTEGER);
					   tiff: BOOLEAN);

PROCEDURE LZWExpand (codeSize: INTEGER;
					 errorCode: INTEGER;
					 FUNCTION GetCodeWord: INTEGER;
					 PROCEDURE PutData (pixel: INTEGER);
					 tiff: BOOLEAN);

IMPLEMENTATION

{$I ULZWCompress.inc1.p}

END.

{Photoshop version 1.0.1, file: UPostScript.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UPostScript;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UBWDialog, UScreen, UTransfer, UProgress;

TYPE
	TRegMarkList = ARRAY [0..7] OF Point;

PROCEDURE BeginPostScript (toFile: BOOLEAN; refNum: INTEGER);

PROCEDURE FlushPostScript;

PROCEDURE EndPostScript;

PROCEDURE GenerateEPSFHeader (doc: TImageDocument;
							  channel: INTEGER;
							  inputArea: Rect;
							  outputArea: Rect;
							  useDCS: BOOLEAN;
							  color: BOOLEAN;
							  screen: BOOLEAN;
							  transfer: BOOLEAN;
							  binary: BOOLEAN);

PROCEDURE GeneratePostScript (doc: TImageDocument;
							  channel: INTEGER;
							  inputArea: Rect;
							  outputArea: Rect;
							  color: BOOLEAN;
							  screen: BOOLEAN;
							  transfer: BOOLEAN;
							  mask: BOOLEAN;
							  binary: BOOLEAN;
							  printing: BOOLEAN);

PROCEDURE GenerateRegMarks (marks: TRegMarkList);

PROCEDURE GenerateStarTargets (bounds: Rect);

PROCEDURE GenerateCropMarks (bounds: Rect);

PROCEDURE GenerateGrayBar (bounds: Rect);

PROCEDURE GenerateColorBars (bounds: Rect; channel: INTEGER);

PROCEDURE GenerateBorder (location: Point;
						  width: INTEGER;
						  height: INTEGER;
						  resolution: Fixed;
						  border: Fixed);

PROCEDURE GenerateSetFont;

PROCEDURE GenerateText (s: Str255;
						center: BOOLEAN;
						left: INTEGER;
						right: INTEGER;
						bottom: INTEGER);

PROCEDURE GenerateOther (s: Str255);

IMPLEMENTATION

{$I UPostScript.inc1.p}

END.

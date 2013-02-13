{Photoshop version 1.0.1, file: UProgress.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UProgress;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD}
	UDialog, UBWDialog;

PROCEDURE InitProgress;

PROCEDURE StartProgress (s: Str255);

PROCEDURE CommandProgress (cmd: INTEGER);

PROCEDURE FinishProgress;

PROCEDURE UpdateProgress (m, n: LONGINT);

PROCEDURE StartTask (f: EXTENDED);

PROCEDURE FinishTask;

IMPLEMENTATION

{$I UProgress.inc1.p}

END.

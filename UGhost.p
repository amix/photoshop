{Photoshop version 1.0.1, file: UGhost.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UGhost;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD}
	PaletteMgr, SysEqu, Traps, UPatch;

TYPE

	TGhostWindow = OBJECT (TWindow)

		fClosed: BOOLEAN;

		PROCEDURE TGhostWindow.ShowGhost (visible: BOOLEAN);

		PROCEDURE TGhostWindow.Close; OVERRIDE;

		PROCEDURE TGhostWindow.MoveByUser (startPt: Point); OVERRIDE;

		PROCEDURE TGhostWindow.UpdateEvent; OVERRIDE;

		END;

PROCEDURE InitGhosts;

PROCEDURE MoveGhostsForward;

FUNCTION FrontVisible: WindowPtr;

FUNCTION IsGhostWindow (wp: WindowPtr): BOOLEAN;

PROCEDURE MakeIntoGhost (wp: WindowPtr; ghost: BOOLEAN);

PROCEDURE HiliteGhosts (state: BOOLEAN);

PROCEDURE MySelectWindow (theWindow: WindowPtr);

PROCEDURE MyDragWindow (theWindow: WindowPtr; startPt: Point; bounds: Rect);

FUNCTION ToggleGhosts: BOOLEAN;

FUNCTION NewGhostWindow (itsRsrcID: INTEGER; itsView: TView): TWindow;

IMPLEMENTATION

{$I UGhost.inc1.p}

END.

{Photoshop version 1.0.1, file: UGhost.p.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE InitGhosts; EXTERNAL;

PROCEDURE MoveGhostsForward; EXTERNAL;

FUNCTION FrontVisible: WindowPtr; EXTERNAL;

FUNCTION IsGhostWindow (wp: WindowPtr): BOOLEAN; EXTERNAL;

PROCEDURE MakeIntoGhost (wp: WindowPtr; ghost: BOOLEAN); EXTERNAL;

PROCEDURE HiliteGhosts (state: BOOLEAN); EXTERNAL;

PROCEDURE MySelectWindow (theWindow: WindowPtr); EXTERNAL;

PROCEDURE MyDragWindow (theWindow: WindowPtr;
						startPt: Point;
						bounds: Rect); EXTERNAL;

FUNCTION ToggleGhosts: BOOLEAN; EXTERNAL;

FUNCTION NewGhostWindow (itsRsrcID: INTEGER;
						 itsView: TView): TWindow; EXTERNAL;

{Photoshop version 1.0.1, file: UGhost.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

CONST

	kMaxDevices = 6;

	kGhostKind = 5367;

VAR

	gFWPatch: TrapPatch;

	gGhostHilite: INTEGER;

	gGhostsHidden: BOOLEAN;

	gDepths: ARRAY [1..kMaxDevices] OF INTEGER;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ARes3}

FUNCTION MyFrontWindow: WindowPtr;

	VAR
		wp: WindowPeek;

	FUNCTION RealFrontWindow (address: LONGINT): WindowPtr;
		INLINE $205F, $4E90;

	BEGIN

	SetupA5;

	wp := WindowPeek (Handle (WindowList)^);

	WHILE wp <> NIL DO
		BEGIN

		IF wp^.visible & (wp^.windowKind = kGhostKind) THEN
			BEGIN

			wp^.windowKind := kGhostKind + 1;
			wp^.visible    := FALSE

			END;

		wp := wp^.nextWindow

		END;

	MyFrontWindow := RealFrontWindow (gFWPatch.oldTrapAddr);

	wp := WindowPeek (Handle (WindowList)^);

	WHILE wp <> NIL DO
		BEGIN

		IF wp^.windowKind = kGhostKind + 1 THEN
			BEGIN

			wp^.windowKind := kGhostKind;
			wp^.visible    := TRUE

			END;

		wp := wp^.nextWindow

		END;

	RestoreA5

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S AInit}

PROCEDURE InitGhosts;

	VAR
		gd: GDHandle;
		count: INTEGER;

	BEGIN

	FailOSErr (PatchTrap (gFWPatch, _FrontWindow, @MyFrontWindow));

	gGhostHilite := 0;

	gGhostsHidden := FALSE;

	IF gConfiguration.hasColorToolbox THEN
		BEGIN

		count := 0;
		gd := GetDeviceList;

		WHILE (gd <> NIL) AND (count < kMaxDevices) DO
			BEGIN
			count := count + 1;
			gDepths [count] := gd^^.gdPMap^^.pixelSize;
			gd := GetNextDevice (gd)
			END

		END

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE TestDepthChange;

	VAR
		gd: GDHandle;
		wp: WindowPeek;
		count: INTEGER;
		changed: BOOLEAN;
		front: WindowPeek;

	BEGIN

	IF gConfiguration.hasColorToolbox THEN
		BEGIN

		count := 0;
		changed := FALSE;
		gd := GetDeviceList;

		WHILE (gd <> NIL) AND (count < kMaxDevices) DO
			BEGIN

			count := count + 1;

			IF gDepths [count] <> gd^^.gdPMap^^.pixelSize THEN
				BEGIN
				changed := TRUE;
				gDepths [count] := gd^^.gdPMap^^.pixelSize
				END;

			gd := GetNextDevice (gd)

			END;

		IF changed THEN
			BEGIN

			front := WindowPeek (FrontWindow);

			wp := WindowPeek (Handle (WindowList)^);

			WHILE wp <> front DO
				BEGIN
				IF wp^.visible THEN PaintOne (wp, wp^.strucRgn);
				wp := wp^.nextWindow
				END

			END

		END

	END;

{*****************************************************************************}

{$S ARes3}

FUNCTION GetLastGhost: WindowPtr;

	VAR
		wp: WindowPeek;
		front: WindowPeek;
		lastGhost: WindowPeek;

	BEGIN

	lastGhost := NIL;

	wp := WindowPeek (Handle (WindowList)^);

	front := WindowPeek (FrontWindow);

	WHILE wp <> front DO
		BEGIN
		IF wp^.windowKind = kGhostKind THEN
			lastGhost := wp;
		wp := wp^.nextWindow
		END;

	GetLastGhost := WindowPtr (lastGhost)

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE MySendBehind (theWindow: WindowPtr; behind: WindowPtr);

	VAR
		wp: WindowPeek;
		clobberedRgn: RgnHandle;

	BEGIN

	IF behind = NIL THEN
		BringToFront (theWindow)

	ELSE
		BEGIN

		clobberedRgn := NewRgn;

		wp := WindowPeek (theWindow);

		CopyRgn (theWindow^.visRgn, clobberedRgn);

		IF BAND (CGrafPtr (theWindow)^ . portVersion, $0C000) = $0C000 THEN
			WITH CGrafPtr (theWindow)^ . portPixMap^^ . bounds DO
				OffSetRgn (clobberedRgn, -left, -top)
		ELSE
			WITH theWindow^ . portBits . bounds DO
				OffSetRgn (clobberedRgn, -left, -top);

		DiffRgn (wp^.strucRgn, clobberedRgn, clobberedRgn);

		SendBehind (theWindow, behind);

		PaintOne (wp, clobberedRgn);
		CalcVis (wp);
		PaintBehind (wp, clobberedRgn);
		CalcVisBehind (wp, clobberedRgn);

		DisposeRgn (clobberedRgn)

		END

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE MoveGhostsForward;

	VAR
		wp: WindowPeek;
		front: WindowPeek;
		lastGhost: WindowPtr;

	BEGIN

	TestDepthChange;

	front := WindowPeek (FrontWindow);

	IF front <> NIL THEN
		BEGIN

		lastGhost := GetLastGhost;

		WHILE TRUE DO
			BEGIN

			wp := front^.nextWindow;

			WHILE wp <> NIL DO
				BEGIN
				IF wp^.visible & (wp^.windowKind = kGhostKind) THEN LEAVE;
				wp := wp^.nextWindow
				END;

			IF wp = NIL THEN LEAVE;

			MySendBehind (WindowPtr (wp), lastGhost);

			lastGhost := WindowPtr (wp)

			END

		END

	END;

{*****************************************************************************}

{$S ARes3}

FUNCTION FrontVisible: WindowPtr;

	VAR
		wp: WindowPeek;

	BEGIN

	wp := WindowPeek (Handle (WindowList)^);

	WHILE wp <> NIL DO
		BEGIN
		IF wp^.visible THEN LEAVE;
		wp := wp^.nextWindow
		END;

	FrontVisible := WindowPtr (wp)

	END;

{*****************************************************************************}

{$S ARes3}

FUNCTION IsGhostWindow (wp: WindowPtr): BOOLEAN;

	BEGIN

	IsGhostWindow := (wp <> NIL) &
					 (WindowPeek (wp)^ . windowKind = kGhostKind)

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE MakeIntoGhost (wp: WindowPtr; ghost: BOOLEAN);

	BEGIN

	IF ghost THEN
		WindowPeek (wp)^ . windowKind := kGhostKind
	ELSE
		WindowPeek (wp)^ . windowKind := userKind

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE HiliteGhosts (state: BOOLEAN);

	VAR
		wp: WindowPeek;

	BEGIN

	IF state THEN
		gGhostHilite := gGhostHilite + 1
	ELSE
		gGhostHilite := gGhostHilite - 1;

	wp := WindowPeek (Handle (WindowList)^);

	WHILE wp <> NIL DO
		BEGIN

		IF wp^.windowKind = kGhostKind THEN
			HiliteWindow (WindowPtr (wp), gGhostHilite = 0);

		wp := wp^.nextWindow

		END

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE DoSelect (theWindow: WindowPtr);

	VAR
		front: WindowPtr;

	BEGIN

	front := FrontWindow;

	IF front <> NIL THEN
		BEGIN
		HiliteWindow (front, FALSE);
		Handle (CurDeactive)^ := Ptr (front)
		END;

	MySendBehind (theWindow, GetLastGhost);

	HiliteWindow (theWindow, TRUE);

	Handle (CurActivate)^ := Ptr (theWindow)

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE MySelectWindow (theWindow: WindowPtr);

	BEGIN

	IF theWindow <> FrontWindow THEN
		BEGIN
		DoSelect (theWindow);
		ActivatePalette (theWindow)
		END

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE DoDrag (theWindow: WindowPtr; startPt: Point; bounds: Rect);

	VAR
		move: Point;
		portBounds: Rect;
		savePort: GrafPtr;
		wmgrPort: GrafPtr;
		dragRgn: RgnHandle;
		saveClip: RgnHandle;

	BEGIN

	IF StillDown THEN
		BEGIN

		GetWMgrPort (wmgrPort);

		GetPort (savePort);
		SetPort (wmgrPort);

		saveClip := NewRgn;
		GetClip (saveClip);

		SetClip (GetGrayRgn);
		ClipAbove (WindowPeek (theWindow));

		dragRgn := NewRgn;
		CopyRgn (WindowPeek (theWindow)^ . strucRgn, dragRgn);

		move := Point (DragGrayRgn (dragRgn, startPt, bounds,
									bounds, noConstraint, NIL));

		SetClip (saveClip);
		SetPort (savePort);

		DisposeRgn (dragRgn);
		DisposeRgn (saveClip);

		IF move.v <> $8000 THEN
			BEGIN

			IF BAND (CGrafPtr (theWindow)^.portVersion, $0C000) = $0C000 THEN
				portBounds := CGrafPtr (theWindow)^.portPixMap^^.bounds
			ELSE
				portBounds := theWindow^.portBits.bounds;

			move.v := move.v + theWindow^.portRect.top	- portBounds.top;
			move.h := move.h + theWindow^.portRect.left - portBounds.left;

			MoveWindow (theWindow, move.h, move.v, FALSE)

			END;

		END

	END;

{*****************************************************************************}

{$S ARes3}

FUNCTION GetLastWindow: WindowPtr;

	VAR
		wp: WindowPeek;
		lastWindow: WindowPeek;

	BEGIN

	lastWindow := NIL;

	wp := WindowPeek (Handle (WindowList)^);

	WHILE wp <> NIL DO
		BEGIN
		IF wp^.visible & (wp^.windowKind <> kGhostKind) THEN
			lastWindow := wp;
		wp := wp^.nextWindow
		END;

	GetLastWindow := WindowPtr (lastWindow)

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE MyDragWindow (theWindow: WindowPtr; startPt: Point; bounds: Rect);

	VAR
		behind: WindowPtr;

	BEGIN

	IF gEventInfo.theOptionKey THEN
		BEGIN
		IF IsGhostWindow (theWindow) THEN
			behind := GetLastGhost
		ELSE
			behind := GetLastWindow;
		IF theWindow <> behind THEN
			SendBehind (theWindow, behind)
		END

	ELSE IF gEventInfo.theCmdKey OR (theWindow = FrontWindow) THEN
		DoDrag (theWindow, startPt, bounds)

	ELSE IF IsGhostWindow (theWindow) THEN
		BEGIN
		IF IsGhostWindow (FrontVisible) THEN
			BringToFront (theWindow);
		DoDrag (theWindow, startPt, bounds)
		END

	ELSE
		BEGIN
		DoSelect (theWindow);
		DoDrag (theWindow, startPt, bounds);
		ActivatePalette (theWindow)
		END

	END;

{*****************************************************************************}

{$S ARes3}

FUNCTION ToggleGhosts: BOOLEAN;

	VAR
		wp: WindowPeek;

	BEGIN

	gGhostsHidden := NOT gGhostsHidden;

	wp := WindowPeek (Handle (WindowList)^);

	WHILE wp <> NIL DO
		BEGIN
		IF IsGhostWindow (WindowPtr (wp)) THEN
			IF NOT TGhostWindow (wp^.refCon) . fClosed THEN
				BEGIN
				ShowHide (WindowPtr (wp), NOT gGhostsHidden);
				IF NOT gGhostsHidden THEN
					HiliteWindow (WindowPtr (wp), TRUE)
				END;
		wp := wp^.nextWindow
		END;

	ToggleGhosts := gGhostsHidden

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE TGhostWindow.ShowGhost (visible: BOOLEAN);

	BEGIN

	fClosed := NOT visible;

	ShowHide (fWmgrWindow, visible);

	IF visible THEN
		BEGIN
		BringToFront (fWmgrWindow);
		HiliteWindow (fWmgrWindow, TRUE)
		END

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE TGhostWindow.Close; OVERRIDE;

	BEGIN

	ShowGhost (FALSE)

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE TGhostWindow.MoveByUser (startPt: Point); OVERRIDE;

	VAR
		bounds: Rect;

	BEGIN

	GetMoveBounds (bounds);

	MyDragWindow (fWmgrWindow, startPt, bounds)

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE TGhostWindow.UpdateEvent; OVERRIDE;

	VAR
		fi: FailInfo;
		aWmgrWindow: WindowPtr;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		EndUpdate (aWmgrWindow);
		FailNewMessage (error, message, msgDrawFailed)
		END;

	BEGIN

	aWmgrWindow := fWmgrWindow;
	BeginUpdate (aWmgrWindow);

	CatchFailures (fi, CleanUp);

	DrawAll;

	Success (fi);

	EndUpdate (aWmgrWindow)

	END;

{*****************************************************************************}

{$S AOpen}

FUNCTION NewGhostWindow (itsRsrcID: INTEGER; itsView: TView): TWindow;

	VAR
		wSize: Point;
		canClose: BOOLEAN;
		canResize: BOOLEAN;
		aWindow: TGhostWindow;
		aWmgrWindow: WindowPtr;

	BEGIN

	aWmgrWindow := gApplication.GetRsrcWindow
				   (NIL, itsRsrcID, FALSE, canResize, canClose);

	SendBehind (aWmgrWindow, NIL);	{???}

	NEW (aWindow);
	FailNil (aWindow);

	aWindow.IWindow (NIL, aWmgrWindow, FALSE, canResize, canClose, TRUE);

	aWindow.HaveView (itsView);

	aWindow.fTarget := itsView;

	WITH aWindow.fWmgrWindow^.portRect DO
		BEGIN
		wSize := botRight;
		{$H-}
		SubPt (topLeft, botRight);
		{$H+}
		END;

	aWindow.Resize (wSize, FALSE);

	aWindow.fCanBeClosed  := FALSE;
	aWindow.fCanBeActive  := FALSE;
	aWindow.fDoFirstClick := TRUE;

	MakeIntoGhost (aWindow.fWmgrWindow, TRUE);

	aWindow.fClosed := FALSE;

	NewGhostWindow := aWindow

	END;

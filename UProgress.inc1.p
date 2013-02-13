{Photoshop version 1.0.1, file: UProgress.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

CONST
	kMaxTaskLevel = 10;

VAR
	gProgressLevel: INTEGER;

	gProgressDialog: DialogPtr;

	gProgressTitle: Str255;

	gProgressRect: Rect;
	gProgressCoord: INTEGER;

	gProgressLower: INTEGER;
	gProgressUpper: INTEGER;

	gProgressStarted: BOOLEAN;
	gProgressVisible: BOOLEAN;

	gProgressStartTime: LONGINT;

	gTaskLevel: INTEGER;
	gTaskStack: ARRAY [1..kMaxTaskLevel] OF INTEGER;

	{$IFC qDebug}
	gTaskStartTime: ARRAY [1..kMaxTaskLevel] OF LONGINT;
	{$ENDC}

{*****************************************************************************}

{$S AInit}

PROCEDURE InitProgress;

	BEGIN
	gProgressLevel := 0
	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE DrawTitle (theDialog: DialogPtr; itemNumber: INTEGER);

	VAR
		r: Rect;
		h: Handle;
		itemType: INTEGER;

	BEGIN

	GetDItem (theDialog, itemNumber, itemType, h, r);

	TextBox (@gProgressTitle[1], LENGTH (gProgressTitle), r, teJustLeft)

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE DrawGraph (theDialog: DialogPtr; itemNumber: INTEGER);

	VAR
		r: Rect;

	BEGIN

	r := gProgressRect;
	InsetRect (r, -1, -1);

	FrameRect (r);

	r := gProgressRect;
	r.right := r.left + gProgressCoord;

	PaintRect (r)

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE StartProgress (s: Str255);

	CONST
		kDialogID  = 950;
		kTitleItem = 1;
		kGraphItem = 2;

	VAR
		r: Rect;
		h: Handle;
		itemType: INTEGER;
		savePort: GrafPtr;

	BEGIN

	gProgressLevel := gProgressLevel + 1;

	IF gProgressLevel = 1 THEN
		BEGIN

		GetPort (savePort);

		gProgressTitle := s;

		IF s [LENGTH (s)] = CHR ($C9) THEN
			DELETE (gProgressTitle, LENGTH (s), 1);

		gProgressDialog := GetNewDialog (kDialogID, NIL, NIL);

		CenterWindow (gProgressDialog, FALSE);

		GetDItem (gProgressDialog, kTitleItem, itemType, h, r);
		SetDItem (gProgressDialog, kTitleItem, itemType, @DrawTitle, r);

		GetDItem (gProgressDialog, kGraphItem, itemType, h, r);
		SetDItem (gProgressDialog, kGraphItem, itemType, @DrawGraph, r);

		gProgressRect := r;
		gProgressCoord := 0;

		gProgressLower := 0;
		gProgressUpper := r.right - r.left;

		gProgressStarted := FALSE;

		gTaskLevel := 0;

		SetPort (savePort)

		END

	ELSE
		StartTask (1)

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE CommandProgress (cmd: INTEGER);

	VAR
		s: Str255;

	BEGIN

	CmdToName (cmd, s);

	StartProgress (s)

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE FinishProgress;

	BEGIN

	gProgressLevel := gProgressLevel - 1;

	IF gProgressLevel = 0 THEN
		BEGIN

		{$IFC qDebug}
		IF gProgressStarted THEN
			writeln ('0: ', TickCount - gProgressStartTime:1, ' ticks');
		{$ENDC}

		ShowHide (gProgressDialog, FALSE);
		DisposDialog (gProgressDialog)

		END

	ELSE
		FinishTask

	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ARes4}

PROCEDURE UpdateProgress (m, n: LONGINT);

	CONST
		kMinElapsed   =  2 * 60;
		kMinRemaining = 10 * 60;

	VAR
		r: Rect;
		coord: INTEGER;
		elapsed: LONGINT;
		savePort: GrafPtr;
		remaining: LONGINT;

	BEGIN

	IF gProgressLevel > 0 THEN
		BEGIN

		IF NOT gProgressStarted THEN
			BEGIN

			gProgressStarted := TRUE;
			gProgressVisible := FALSE;

			gProgressStartTime := TickCount;

			EXIT (UpdateProgress)

			END;

		IF m < 0 THEN m := 0;
		IF m > n THEN m := n;

		IF BAND ($FF800000, n) <> 0 THEN
			BEGIN
			m := BSR (m, 9);
			n := BSR (n, 9)
			END;

		coord := (m * (gProgressUpper - gProgressLower) + BSR (n, 1))
				 DIV n + gProgressLower;

		{$IFC qDebug}
		IF coord < gProgressCoord THEN
			BEGIN
			writeln ('Progress moving backward');
			gProgressCoord := coord
			END;
		{$ENDC}

		IF coord > gProgressCoord THEN
			BEGIN

			IF gProgressVisible THEN
				BEGIN

				GetPort (savePort);

				SetPort (gProgressDialog);

				r := gProgressRect;

				r.right := r.left + coord;
				r.left	:= r.left + gProgressCoord;

				PaintRect (r);

				SetPort (savePort)

				END;

			gProgressCoord := coord

			END;

		IF NOT gProgressVisible THEN
			BEGIN

			elapsed := TickCount - gProgressStartTime;

			IF elapsed >= kMinElapsed THEN
				BEGIN

				IF gProgressCoord = 0 THEN
					remaining := kMinRemaining
				ELSE
					remaining := (gProgressRect.right -
								  gProgressRect.left -
								  gProgressCoord) * elapsed
								  DIV gProgressCoord;

				IF remaining >= kMinRemaining THEN
					BEGIN

					BringToFront (gProgressDialog);
					ShowHide (gProgressDialog, TRUE);

					gProgressVisible := TRUE

					END

				END

			END;

		IF gProgressVisible THEN
			IF NOT EmptyRgn (WindowPeek (gProgressDialog)^.updateRgn) THEN
				BEGIN

				GetPort (savePort);

				BeginUpdate (gProgressDialog);
				DrawDialog	(gProgressDialog);
				EndUpdate	(gProgressDialog);

				SetPort (savePort)

				END

		END

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S ARes4}

PROCEDURE StartTask (f: EXTENDED);

	BEGIN

	IF gProgressLevel > 0 THEN
		BEGIN

		gTaskLevel := gTaskLevel + 1;

		{$IFC qDebug}
		IF gTaskLevel > kMaxTaskLevel THEN
			ProgramBreak ('Tasks nested too deep');
		{$ENDC}

		gTaskStack [gTaskLevel] := gProgressUpper;

		gProgressUpper := gProgressLower +
						  ROUND (f * (gProgressUpper - gProgressLower));

		{$IFC qDebug}
		writeln (gTaskLevel:1, ': ',
				 gProgressLower:3, '-', gProgressUpper:3);
		gTaskStartTime [gTaskLevel] := TickCount
		{$ENDC}

		END

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE FinishTask;

	BEGIN

	IF gProgressLevel > 0 THEN
		BEGIN

		IF gProgressVisible THEN
			UpdateProgress (1, 1);

		gProgressLower := gProgressUpper;
		gProgressUpper := gTaskStack [gTaskLevel];

		{$IFC qDebug}
		writeln (gTaskLevel:1, ': ',
				 TickCount - gTaskStartTime [gTaskLevel]:1, ' ticks');
		{$ENDC}

		gTaskLevel := gTaskLevel - 1

		END

	END;

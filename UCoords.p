{Photoshop version 1.0.1, file: UCoords.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UCoords;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UGhost;

TYPE

	TCoordsView = OBJECT (TView)

		fCoord: Point;

		fColor1: INTEGER;
		fColor2: INTEGER;
		fColor3: INTEGER;

		PROCEDURE TCoordsView.ICoordsView;

		PROCEDURE TCoordsView.DrawRight (top, left, right: INTEGER; s: Str255);

		PROCEDURE TCoordsView.DrawCoords;

		PROCEDURE TCoordsView.Draw (area: Rect); OVERRIDE;

		END;

PROCEDURE InitCoords;

FUNCTION CoordsVisible: BOOLEAN;

PROCEDURE ShowCoords (visible: BOOLEAN);

PROCEDURE UpdateCoords (view: TImageView; pt: Point);

IMPLEMENTATION

VAR
	gCoordsView: TCoordsView;
	gCoordsWindow: TGhostWindow;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitCoords;

	BEGIN

	NEW (gCoordsView);
	FailNil (gCoordsView);

	gCoordsView.ICoordsView

	END;

{*****************************************************************************}

{$S ARes4}

FUNCTION CoordsVisible: BOOLEAN;

	BEGIN

	CoordsVisible := ORD (WindowPeek (gCoordsWindow.
									  fWmgrWindow)^.visible) <> 0

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE ShowCoords (visible: BOOLEAN);

	BEGIN

	gCoordsWindow.ShowGhost (visible)

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE TCoordsView.ICoordsView;

	CONST
		kCoordsID = 1004;

	VAR
		r: Rect;
		location: Point;

	BEGIN

	fCoord.h := -1;
	fCoord.v := -1;

	fColor1 := -1;
	fColor2 := -1;
	fColor3 := -1;

	SetRect (r, 0, 0, 91, 40);

	IView (NIL, NIL, r, sizeFixed, sizeFixed, TRUE, HLOn);

	gCoordsWindow := TGhostWindow (NewGhostWindow (kCoordsID, SELF));

	SetPort (gCoordsWindow.fWmgrWindow);

	TextFont (gGeneva);
	TextSize (9);

	location.v := 0;
	location.h := screenBits.bounds.right;

	LocalToGlobal (location);

	MoveWindow (gCoordsWindow.fWmgrWindow, -30000, -30000, FALSE);

	gCoordsWindow.Open;

	gCoordsWindow.ShowGhost (FALSE);

	MoveWindow (gCoordsWindow.fWmgrWindow, location.h, location.v, FALSE)

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TCoordsView.DrawRight (top, left, right: INTEGER; s: Str255);

	VAR
		r: Rect;

	BEGIN

	r.top	 := top;
	r.bottom := top + 12;
	r.left	 := left;
	r.right  := right;

	MoveTo (right - StringWidth (s), top + 10);

	EraseRect (r);

	DrawString (s)

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TCoordsView.DrawCoords;

	VAR
		r: Rect;
		s: Str255;

	BEGIN

	IF fCoord.h <> -1 THEN
		BEGIN
		NumToString (fCoord.h, s);
		DrawRight (2, 16, 64, s);
		NumToString (fCoord.v, s);
		DrawRight (14, 16, 64, s)
		END
	ELSE
		BEGIN
		SetRect (r, 16, 2, 64, 26);
		EraseRect (r)
		END;

	IF fColor1 <> -1 THEN
		BEGIN
		NumToString (fColor1, s);
		DrawRight (26, 16, 40, s)
		END
	ELSE
		BEGIN
		SetRect (r, 16, 26, 40, 38);
		EraseRect (r)
		END;

	IF fColor2 <> -1 THEN
		BEGIN
		NumToString (fColor2, s);
		DrawRight (26, 40, 64, s)
		END
	ELSE
		BEGIN
		SetRect (r, 40, 26, 64, 38);
		EraseRect (r)
		END;

	IF fColor3 <> -1 THEN
		BEGIN
		NumToString (fColor3, s);
		DrawRight (26, 64, 88, s)
		END
	ELSE
		BEGIN
		SetRect (r, 64, 26, 88, 38);
		EraseRect (r)
		END

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TCoordsView.Draw (area: Rect); OVERRIDE;

	BEGIN

	DrawCoords;

	DrawRight ( 2, 0, 16, 'X:');
	DrawRight (14, 0, 16, 'Y:');
	DrawRight (26, 0, 16, 'Z:')

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE UpdateCoords (view: TImageView; pt: Point);

	VAR
		vr: Rect;
		c1: INTEGER;
		c2: INTEGER;
		c3: INTEGER;
		coord: Point;
		savePort: GrafPtr;
		doc: TImageDocument;

	BEGIN

	IF WindowPeek (gCoordsWindow.fWmgrWindow)^.visible THEN
		WITH gCoordsView DO
			BEGIN

			coord.h := -1;
			coord.v := -1;

			c1 := -1;
			c2 := -1;
			c3 := -1;

			IF view <> NIL THEN
				BEGIN

				doc := TImageDocument (view.fDocument);

				coord := pt;

				view.GetImageColor (coord, c1, c2, c3);

				IF (doc.fMode <> IndexedColorMode) AND
				   (view.fChannel <> kRGBChannels) THEN
					BEGIN
					c1 := -1;
					c3 := -1
					END

				END;

			IF (fCoord.h <> coord.h) OR
			   (fCoord.v <> coord.v) OR
			   (fColor1  <> c1	   ) OR
			   (fColor2  <> c2	   ) OR
			   (fColor3  <> c3	   ) THEN
				BEGIN

				fCoord	:= coord;
				fColor1 := c1;
				fColor2 := c2;
				fColor3 := c3;

				GetPort (savePort);

				fFrame.Focus;
				DrawCoords;

				SetPort (savePort)

				END

			END

	END;

{*****************************************************************************}

END.

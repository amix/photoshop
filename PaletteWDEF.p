{Photoshop version 1.0.1, file: PaletteWDEF.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UPaletteWDEF;

INTERFACE

USES
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf;

FUNCTION PaletteWDEF (varCode: INTEGER;
					  theWindow: WindowPtr;
					  message: INTEGER;
					  param: LONGINT): LONGINT;

IMPLEMENTATION

FUNCTION PaletteWDEF (varCode: INTEGER;
					  theWindow: WindowPtr;
					  message: INTEGER;
					  param: LONGINT): LONGINT;

	CONST
		kTitleHeight = 10;

	VAR
		r: Rect;
		frame: Rect;
		pat: Pattern;
		goAway: Rect;
		index: INTEGER;
		savePen: PenState;

	BEGIN

	PaletteWDEF := 0;

	frame := WindowPeek (theWindow)^.strucRgn^^.rgnBBox;

	goAway		  := frame;
	goAway.top	  := goAway.top  + 2;
	goAway.left   := goAway.left + 6;
	goAway.bottom := goAway.top  + 7;
	goAway.right  := goAway.left + 7;

		CASE message OF

		wDraw:
			IF WindowPeek (theWindow)^.visible THEN

				IF param <> 0 THEN
					BEGIN

					r := goAway;
					InsetRect (r, 1, 1);

					InvertRect (r)

					END

				ELSE
					BEGIN

					GetPenState (savePen);
					PenNormal;

					FrameRect (frame);

					r := frame;
					r.bottom := r.top + kTitleHeight + 1;

					FrameRect (r);

					FOR index := 0 TO 7 DO
						IF ODD (r.top + index) THEN
							pat [index] := 0
						ELSE
							IF ODD (r.left) THEN
								pat [index] := $55
							ELSE
								pat [index] := $AA;

					InsetRect (r, 1, 1);

					IF WindowPeek (theWindow)^.hilited THEN
						BEGIN

						FillRect (r, pat);

						IF WindowPeek (theWindow)^.goAwayFlag THEN
							BEGIN
							r := goAway;
							InsetRect (r, -1, -1);
							EraseRect (r);
							FrameRect (goAway)
							END

						END

					ELSE
						EraseRect (r);

					SetPenState (savePen)

					END;

		wHit:
			BEGIN

			r := WindowPeek (theWindow)^.contRgn^^.rgnBBox;

			IF PtInRect (Point (param), r) THEN
				PaletteWDEF := wInContent

			ELSE
				BEGIN

				r := frame;
				r.bottom := r.top + kTitleHeight + 1;

				IF WindowPeek (theWindow)^.goAwayFlag &
				   WindowPeek (theWindow)^.hilited &
				   PtInRect (Point (param), goAway) THEN
					PaletteWDEF := wInGoAway

				ELSE IF PtInRect (Point (param), r) THEN
					PaletteWDEF := wInDrag

				ELSE
					PaletteWDEF := wNoHit

				END

			END;

		wCalcRgns:
			BEGIN

			r := theWindow^.portRect;
			OffsetRect (r, -theWindow^.portBits.bounds.left,
						   -theWindow^.portBits.bounds.top);

			RectRgn (WindowPeek (theWindow)^.contRgn, r);

			InsetRect (r, -1, -1);
			r.top := r.top - kTitleHeight;

			RectRgn (WindowPeek (theWindow)^.strucRgn, r)

			END

		END

	END;

END.

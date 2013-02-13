{Photoshop version 1.0.1, file: MovableWDEF.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UMovableWDEF;

INTERFACE

USES
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf;

FUNCTION MovableWDEF (varCode: INTEGER;
					  theWindow: WindowPtr;
					  message: INTEGER;
					  param: LONGINT): LONGINT;

IMPLEMENTATION

FUNCTION MovableWDEF (varCode: INTEGER;
					  theWindow: WindowPtr;
					  message: INTEGER;
					  param: LONGINT): LONGINT;

	VAR
		r: Rect;
		s: Str255;
		w: INTEGER;
		white: Pattern;
		black: Pattern;
		index: INTEGER;
		savePen: PenState;

	BEGIN

	MovableWDEF := 0;

		CASE message OF

		wDraw:
			IF WindowPeek (theWindow)^.visible THEN
				BEGIN

				GetPenState (savePen);
				PenNormal;

				FOR index := 0 TO 7 DO
					BEGIN
					black [index] := 255;
					white [index] := 0
					END;

				r := WindowPeek (theWindow)^.strucRgn^^.rgnBBox;
				FrameRect (r);

				InsetRect (r, 1, 1);
				r.top := r.top + 15;

				PenSize (2, 2);
				PenPat (white);
				FrameRect (r);

				InsetRect (r, 2, 2);
				PenPat (black);
				FrameRect (r);

				InsetRect (r, 2, 2);
				PenPat (white);
				FrameRect (r);

				PenPat (black);
				PenSize (1, 1);

				r := WindowPeek (theWindow)^.strucRgn^^.rgnBBox;
				InsetRect (r, 1, 1);
				r.bottom := r.top + 15;
				EraseRect (r);

				IF WindowPeek (theWindow)^.hilited THEN
					FOR index := 0 TO 5 DO
						BEGIN
						MoveTo (r.left, r.top + 3 + 2 * index);
						Line (r.right - r.left - 1, 0)
						END;

				s := WindowPeek (theWindow)^.titleHandle^^;

				w := StringWidth (s);

				InsetRect (r, (r.right - r.left - w - 12) DIV 2, 0);

				EraseRect (r);

				MoveTo (r.left + 6, r.bottom - 2);

				DrawString (s);

				SetPenState (savePen)

				END;

		wHit:
			BEGIN

			r := WindowPeek (theWindow)^.contRgn^^.rgnBBox;

			IF PtInRect (Point (param), r) THEN
				MovableWDEF := wInContent

			ELSE
				BEGIN

				r := WindowPeek (theWindow)^.strucRgn^^.rgnBBox;
				r.bottom := r.top + 22;

				IF PtInRect (Point (param), r) THEN
					MovableWDEF := wInDrag
				ELSE
					MovableWDEF := wNoHit

				END

			END;

		wCalcRgns:
			BEGIN

			r := theWindow^.portRect;
			OffsetRect (r, -theWindow^.portBits.bounds.left,
						   -theWindow^.portBits.bounds.top);

			RectRgn (WindowPeek (theWindow)^.contRgn, r);

			InsetRect (r, -7, -7);
			r.top := r.top - 15;

			RectRgn (WindowPeek (theWindow)^.strucRgn, r)

			END

		END

	END;

END.

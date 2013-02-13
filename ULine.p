{Photoshop version 1.0.1, file: ULine.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT ULine;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UBWDialog, UCommands;

TYPE

	TArrowLocation = RECORD

		{ Bounding box in image space }

		bounds: Rect;

		{ Corner coordinates in 4x box space }

		corner1: Point;
		corner2: Point;
		corner3: Point;
		corner4: Point

		END;

	TLineTool = OBJECT (TBufferCommand)

		fPt1: Point;
		fPt2: Point;

		fLineRect: Rect;

		fArrow1: BOOLEAN;
		fArrow2: BOOLEAN;

		fChannel: INTEGER;

		fDrawLine: BOOLEAN;

		fArrowLoc1: TArrowLocation;
		fArrowLoc2: TArrowLocation;

		PROCEDURE TLineTool.ILineTool (view: TImageView);

		PROCEDURE TLineTool.TrackConstrain
				(anchorPoint: Point;
				 previousPoint: Point;
				 VAR nextPoint: Point); OVERRIDE;

		PROCEDURE TLineTool.TrackFeedBack
				(anchorPoint: Point;
				 nextPoint: Point;
				 turnItOn: BOOLEAN;
				 mouseDidMove: BOOLEAN); OVERRIDE;

		FUNCTION TLineTool.TrackMouse
				(aTrackPhase: TrackPhase;
				 VAR anchorPoint, previousPoint, nextPoint: Point;
				 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

		PROCEDURE TLineTool.LocateArrow (hLoc: Fixed;
										 vLoc: Fixed;
										 normH: EXTENDED;
										 normV: EXTENDED;
										 VAR arrow: TArrowLocation);

		PROCEDURE TLineTool.GetBounds (VAR r: Rect);

		PROCEDURE TLineTool.ImageLine (maskArray: TVMArray);

		PROCEDURE TLineTool.ImageArrow (maskArray: TVMArray;
										arrow: TArrowLocation);

		PROCEDURE TLineTool.MarkArray (srcArray: TVMArray;
									   dstArray: TVMArray;
									   level: INTEGER);

		PROCEDURE TLineTool.MultiplyMasks (dstArray: TVMArray);

		PROCEDURE TLineTool.DoIt; OVERRIDE;

		PROCEDURE TLineTool.SwapRect (iArray: TVMArray;
									  bArray: TVMArray);

		PROCEDURE TLineTool.UndoIt; OVERRIDE;

		PROCEDURE TLineTool.RedoIt; OVERRIDE;

		END;

PROCEDURE InitLineTool;

FUNCTION DoLineTool (view: TImageView): TCommand;

PROCEDURE DoLineToolOptions;

IMPLEMENTATION

{$I UAssembly.a.inc}
{$I UConvert.a.inc}
{$I ULine.a.inc}

VAR
	gLineWidth	   : INTEGER;
	gArrowWidth    : INTEGER;
	gArrowLength   : INTEGER;
	gArrowConcavity: INTEGER;
	gArrowAtEnd    : BOOLEAN;
	gArrowAtStart  : BOOLEAN;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitLineTool;

	BEGIN
	gLineWidth		:= 1;
	gArrowWidth 	:= 9;
	gArrowLength	:= 15;
	gArrowConcavity := 0;
	gArrowAtEnd 	:= FALSE;
	gArrowAtStart	:= FALSE
	END;

{*****************************************************************************}

{$S ALineTool}

PROCEDURE TLineTool.ILineTool (view: TImageView);

	BEGIN

	IBufferCommand (cLineTool, view);

	fConstrainsMouse := TRUE;
	fViewConstrain	 := FALSE

	END;

{*****************************************************************************}

{$S ALineTool}

PROCEDURE TLineTool.TrackConstrain (anchorPoint: Point;
									previousPoint: Point;
									VAR nextPoint: Point); OVERRIDE;

	VAR
		mag: INTEGER;
		delta: Point;
		theKeys: KeyMap;
		didMove: BOOLEAN;

	BEGIN

	fView.TrackRulers;

	didMove := LONGINT (anchorPoint) <> LONGINT (nextPoint);

	mag := fView.fMagnification;

	IF mag > 1 THEN
		BEGIN
		nextPoint.h := nextPoint.h DIV mag * mag;
		nextPoint.v := nextPoint.v DIV mag * mag
		END;

	GetKeys (theKeys);

	IF theKeys [kShiftCode] AND didMove THEN
		BEGIN

		delta.h := nextPoint.h - anchorPoint.h;
		delta.v := nextPoint.v - anchorPoint.v;

		IF ABS (delta.h) > BSL (ABS (delta.v), 1) THEN
			delta.v := 0

		ELSE IF ABS (delta.v) > BSL (ABS (delta.h), 1) THEN
			delta.h := 0

		ELSE IF ABS (delta.h) > ABS (delta.v) THEN
			IF delta.h > 0 THEN
				delta.h := ABS (delta.v)
			ELSE
				delta.h := -ABS (delta.v)

		ELSE
			IF delta.v > 0 THEN
				delta.v := ABS (delta.h)
			ELSE
				delta.v := -ABS (delta.h);

		nextPoint.h := anchorPoint.h + delta.h;
		nextPoint.v := anchorPoint.v + delta.v

		END

	END;

{*****************************************************************************}

{$S ALineTool}

PROCEDURE TLineTool.TrackFeedBack (anchorPoint: Point;
								   nextPoint: Point;
								   turnItOn: BOOLEAN;
								   mouseDidMove: BOOLEAN); OVERRIDE;

	VAR
		offset: INTEGER;

	BEGIN

	IF mouseDidMove THEN
		BEGIN

		IF fView.fMagnification > 1 THEN
			offset := BSR (fView.fMagnification, 1)
		ELSE
			offset := 0;

		MoveTo (anchorPoint.h + offset, anchorPoint.v + offset);

		Move (-4,  0);
		Line ( 8,  0);
		Move (-4, -4);
		Line ( 0,  8);
		Move ( 0, -4);

		LineTo (nextPoint.h + offset, nextPoint.v + offset)

		END

	END;

{*****************************************************************************}

{$S ALineTool}

FUNCTION TLineTool.TrackMouse
		(aTrackPhase: TrackPhase;
		 VAR anchorPoint, previousPoint, nextPoint: Point;
		 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

	VAR
		mag: INTEGER;

	BEGIN

	TrackMouse := SELF;

	IF aTrackPhase = trackRelease THEN
		BEGIN

		fPt1 := anchorPoint;
		fPt2 := nextPoint;

		mag := fView.fMagnification;

		IF mag > 0 THEN
			BEGIN
			fPt1.h := fPt1.h DIV mag;
			fPt1.v := fPt1.v DIV mag;
			fPt2.h := fPt2.h DIV mag;
			fPt2.v := fPt2.v DIV mag
			END
		ELSE
			BEGIN
			fPt1.h := fPt1.h * (-mag);
			fPt1.v := fPt1.v * (-mag);
			fPt2.h := fPt2.h * (-mag);
			fPt2.v := fPt2.v * (-mag)
			END

		END

	END;

{*****************************************************************************}

{$S ALineTool}

PROCEDURE TLineTool.LocateArrow (hLoc: Fixed;
								 vLoc: Fixed;
								 normH: EXTENDED;
								 normV: EXTENDED;
								 VAR arrow: TArrowLocation);

	VAR
		x: EXTENDED;
		hLoc2: Fixed;
		vLoc2: Fixed;
		hLoc3: Fixed;
		vLoc3: Fixed;
		hLoc4: Fixed;
		vLoc4: Fixed;
		baseH: Fixed;
		baseV: Fixed;

	BEGIN

	hLoc2 := hLoc + ROUND ($10000 * (normH * gArrowLength +
									 normV * gArrowWidth / 2));
	vLoc2 := vLoc + ROUND ($10000 * (normV * gArrowLength -
									 normH * gArrowWidth / 2));

	IF gArrowConcavity = 0 THEN
		BEGIN
		hLoc3 := hLoc2;
		vLoc3 := vLoc2
		END
	ELSE
		BEGIN
		x := (100 - gArrowConcavity) / 100 * gArrowLength;
		hLoc3 := hLoc + ROUND ($10000 * (normH * x));
		vLoc3 := vLoc + ROUND ($10000 * (normV * x))
		END;

	hLoc4 := hLoc + ROUND ($10000 * (normH * gArrowLength -
									 normV * gArrowWidth / 2));
	vLoc4 := vLoc + ROUND ($10000 * (normV * gArrowLength +
									 normH * gArrowWidth / 2));

	hLoc2 := BAND ($FFFFC000, hLoc2 + $2000);
	vLoc2 := BAND ($FFFFC000, vLoc2 + $2000);
	hLoc3 := BAND ($FFFFC000, hLoc3 + $2000);
	vLoc3 := BAND ($FFFFC000, vLoc3 + $2000);
	hLoc4 := BAND ($FFFFC000, hLoc4 + $2000);
	vLoc4 := BAND ($FFFFC000, vLoc4 + $2000);

	arrow.bounds.left	:= Min (Min (Min (HIWRD (hLoc),
										  HIWRD (hLoc2)),
										  HIWRD (hLoc3)),
										  HIWRD (hLoc4));

	arrow.bounds.top	:= Min (Min (Min (HIWRD (vLoc),
										  HIWRD (vLoc2)),
										  HIWRD (vLoc3)),
										  HIWRD (vLoc4));

	arrow.bounds.right	:= Max (Max (Max (HIWRD (hLoc  + $0FFFF),
										  HIWRD (hLoc2 + $0FFFF)),
										  HIWRD (hLoc3 + $0FFFF)),
										  HIWRD (hLoc4 + $0FFFF));

	arrow.bounds.bottom := Max (Max (Max (HIWRD (vLoc  + $0FFFF),
										  HIWRD (vLoc2 + $0FFFF)),
										  HIWRD (vLoc3 + $0FFFF)),
										  HIWRD (vLoc4 + $0FFFF));

	baseH := BSL (arrow.bounds.left, 16);
	baseV := BSL (arrow.bounds.top , 16);

	arrow.corner1.h := BSR (hLoc - baseH, 14);
	arrow.corner1.v := BSR (vLoc - baseV, 14);

	arrow.corner2.h := BSR (hLoc2 - baseH, 14);
	arrow.corner2.v := BSR (vLoc2 - baseV, 14);

	arrow.corner3.h := BSR (hLoc3 - baseH, 14);
	arrow.corner3.v := BSR (vLoc3 - baseV, 14);

	arrow.corner4.h := BSR (hLoc4 - baseH, 14);
	arrow.corner4.v := BSR (vLoc4 - baseV, 14)

	END;

{*****************************************************************************}

{$S ALineTool}

PROCEDURE TLineTool.GetBounds (VAR r: Rect);

	VAR
		temp: Point;
		hLoc: Fixed;
		vLoc: Fixed;
		dist: EXTENDED;
		normH: EXTENDED;
		normV: EXTENDED;
		deltaH: LONGINT;
		deltaV: LONGINT;
		remove: EXTENDED;

	BEGIN

	IF (fPt1.v < fPt2.v) OR (fPt1.v = fPt2.v) AND (fPt1.h <= fPt2.h) THEN
		BEGIN
		fArrow1 := gArrowAtStart;
		fArrow2 := gArrowAtEnd
		END
	ELSE
		BEGIN
		temp := fPt1;
		fPt1 := fPt2;
		fPt2 := temp;
		fArrow1 := gArrowAtEnd;
		fArrow2 := gArrowAtStart
		END;

	IF LONGINT (fPt1) = LONGINT (fPt2) THEN
		BEGIN
		fArrow1 := FALSE;
		fArrow2 := FALSE
		END;

	IF fArrow1 OR fArrow2 THEN
		BEGIN

		deltaH := ABS (fPt1.h - fPt2.h);
		deltaV := ABS (fPt1.v - fPt2.v);

		dist := SQRT (SQR (deltaH) + SQR (deltaV));

		normH := (fPt2.h - fPt1.h) / dist;
		normV := (fPt2.v - fPt1.v) / dist

		END;

	IF fArrow1 THEN
		BEGIN

		hLoc := fPt1.h * $10000;
		vLoc := fPt1.v * $10000;

		IF fPt2.h - fPt1.h >= 2 * deltaV THEN
			BEGIN
			IF ODD (gLineWidth) THEN
				vLoc := vLoc + $08000
			END

		ELSE IF fPt1.h - fPt2.h >= 2 * deltaV THEN
			BEGIN
			hLoc := hLoc + $10000;
			IF ODD (gLineWidth) THEN
				vLoc := vLoc + $08000
			END

		ELSE IF deltaV >= 2 * deltaH THEN
			BEGIN
			IF ODD (gLineWidth) THEN
				hLoc := hLoc + $08000
			END

		ELSE IF fPt2.h < fPt1.h THEN
			BEGIN
			IF ODD (gLineWidth) THEN
				hLoc := hLoc + $10000
			END;

		{$H-}
		LocateArrow (hLoc, vLoc, normH, normV, fArrowLoc1);
		{$H+}

		END;

	IF fArrow2 THEN
		BEGIN

		hLoc := fPt2.h * $10000;
		vLoc := fPt2.v * $10000;

		IF fPt2.h - fPt1.h >= 2 * deltaV THEN
			BEGIN
			hLoc := hLoc + $10000;
			IF ODD (gLineWidth) THEN
				vLoc := vLoc + $08000
			END

		ELSE IF fPt1.h - fPt2.h >= 2 * deltaV THEN
			BEGIN
			IF ODD (gLineWidth) THEN
				vLoc := vLoc + $08000
			END

		ELSE IF deltaV >= 2 * deltaH THEN
			BEGIN
			vLoc := vLoc + $10000;
			IF ODD (gLineWidth) THEN
				hLoc := hLoc + $08000
			END

		ELSE IF fPt2.h < fPt1.h THEN
			BEGIN
			IF ODD (gLineWidth) THEN
				vLoc := vLoc + $10000
			END

		ELSE
			BEGIN
			hLoc := hLoc + $10000;
			vLoc := vLoc + $10000
			END;

		{$H-}
		LocateArrow (hLoc, vLoc, -normH, -normV, fArrowLoc2);
		{$H+}

		END;

	Pt2Rect (fPt1, fPt2, r);

	r.top	 := r.top	 - gLineWidth DIV 2;
	r.left	 := r.left	 - gLineWidth DIV 2;
	r.bottom := r.bottom + (gLineWidth + 1) DIV 2;
	r.right  := r.right  + (gLineWidth + 1) DIV 2;

	IF fArrow1 OR fArrow2 THEN
		BEGIN

		remove := gArrowLength * (100 - gArrowConcavity) / 100 - gLineWidth;

		fDrawLine := dist > (remove + 1) * (ORD (fArrow1) + ORD (fArrow2));

		IF fDrawLine AND (remove > 0) THEN
			BEGIN

			IF fArrow1 THEN
				BEGIN
				fPt1.h := fPt1.h + ROUND (normH * remove);
				fPt1.v := fPt1.v + ROUND (normV * remove)
				END;

			IF fArrow2 THEN
				BEGIN
				fPt2.h := fPt2.h - ROUND (normH * remove);
				fPt2.v := fPt2.v - ROUND (normV * remove)
				END

			END;

		IF fArrow1 THEN
			UnionRect (fArrowLoc1.bounds, r, r);

		IF fArrow2 THEN
			UnionRect (fArrowLoc2.bounds, r, r)

		END

	ELSE
		fDrawLine := TRUE

	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ALineTool}

PROCEDURE TLineTool.ImageLine (maskArray: TVMArray);

	VAR
		r: Rect;
		rr: Rect;
		pt1: Point;
		pt2: Point;
		row: INTEGER;
		col: INTEGER;
		slope: Fixed;
		left1: Fixed;
		left2: Fixed;
		maskPtr: Ptr;
		thisPtr: Ptr;
		row1: INTEGER;
		row2: INTEGER;
		right1: Fixed;
		right2: Fixed;

	FUNCTION Edge (col: INTEGER;
				   lo: Fixed;
				   hi: Fixed): INTEGER;

		VAR
			f1: LONGINT;
			f2: LONGINT;

		BEGIN

		IF col < HIWRD (hi + $0FFFF) THEN
			IF col = HIWRD (lo) THEN
				IF col = HIWRD (hi) THEN
					Edge := BSR (BAND (BNOT (lo), $0FFFF) +
								 BAND (BNOT (hi), $0FFFF), 9)
				ELSE
					BEGIN
					f1 := BSR (BAND (BNOT (lo), $0FFFF), 8);
					f2 := BSL (BAND (BNOT (lo), $0FFFF), 8) DIV (hi - lo);
					Edge := BSR (f1 * f2, 9)
					END
			ELSE
				IF col = HIWRD (hi) THEN
					BEGIN
					f1 := BSR (BAND (hi, $0FFFF), 8);
					f2 := BSL (BAND (hi, $0FFFF), 8) DIV (hi - lo);
					Edge := 255 - BSR (f1 * f2, 9)
					END
				ELSE
					Edge := (BSL (col, 16) + $08000 - lo) DIV
							 BSR (hi - lo + $FF, 8)
		ELSE
			Edge := 255

		END;

	BEGIN

	r := fLineRect;

	pt1.h := fPt1.h - r.left - gLineWidth DIV 2;
	pt2.h := fPt2.h - r.left - gLineWidth DIV 2;

	pt1.v := fPt1.v - r.top - gLineWidth DIV 2;
	pt2.v := fPt2.v - r.top - gLineWidth DIV 2;

	OffsetRect (r, -r.left, -r.top);

	IF (pt1.v = pt2.v) OR (pt1.h = pt2.h) THEN
		BEGIN

		rr.topLeft := pt1;
		rr.right   := pt2.h + gLineWidth;
		rr.bottom  := pt2.v + gLineWidth;

		IF SectRect (r, rr, rr) THEN
			maskArray.SetRect (rr, 255);

		EXIT (ImageLine)

		END;

	slope := FixRatio (pt2.h - pt1.h, pt2.v - pt1.v);

	FOR row := Max (0, pt1.v) TO
			   Min (r.bottom, pt2.v + gLineWidth) - 1 DO
		BEGIN

		MoveHands (TRUE);

		IF slope > 0 THEN
			BEGIN

			left1 := pt1.h * $10000;
			left2 := left1;

			row1 := row - pt1.v - gLineWidth;
			row2 := row1 + 1;

			IF row1 > 0 THEN
				left1 := left1 + slope * row1;

			IF row2 > 0 THEN
				left2 := left2 + slope * row2;

			row1 := row - pt2.v;
			row2 := row1 + 1;

			right1 := (pt2.h + gLineWidth) * $10000;
			right2 := right1;

			IF row1 < 0 THEN
				right1 := right1 + slope * row1;

			IF row2 < 0 THEN
				right2 := right2 + slope * row2

			END

		ELSE
			BEGIN

			left1 := pt2.h * $10000;
			left2 := left1;

			row2 := row - pt2.v;
			row1 := row2 + 1;

			IF row1 < 0 THEN
				left1 := left1 + slope * row1;

			IF row2 < 0 THEN
				left2 := left2 + slope * row2;

			right1 := (pt1.h + gLineWidth) * $10000;
			right2 := right1;

			row2 := row - pt1.v - gLineWidth;
			row1 := row2 + 1;

			IF row1 > 0 THEN
				right1 := right1 + slope * row1;

			IF row2 > 0 THEN
				right2 := right2 + slope * row2

			END;

		maskPtr := maskArray.NeedPtr (row, row, TRUE);

		FOR col := Max (0, HIWRD (left1)) TO
				   Min (r.right, HIWRD (right2 + $0FFFF)) - 1 DO
			BEGIN

			thisPtr := Ptr (ORD4 (maskPtr) + col);

			{$PUSH}
			{$R-}
			thisPtr^ := Min (Edge (col, left1, left2),
							 Edge (r.right - col - 1,
								   BSL (r.right, 16) - right2,
								   BSL (r.right, 16) - right1));
			{$POP}

			END;

		maskArray.DoneWithPtr

		END;

	maskArray.Flush

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S ALineTool}

PROCEDURE TLineTool.ImageArrow (maskArray: TVMArray; arrow: TArrowLocation);

	VAR
		r: Rect;
		bm: BitMap;
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		gray: INTEGER;
		buffer: Handle;
		poly: PolyHandle;
		offPort: GrafPort;
		savePort: GrafPtr;
		thresTable: TThresTable;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (buffer)
		END;

	BEGIN

	IF SectRect (fLineRect, arrow.bounds, r) THEN
		BEGIN

		bm.bounds.top	 := (r.top	  - arrow.bounds.top ) * 4;
		bm.bounds.bottom := (r.bottom - arrow.bounds.top ) * 4;
		bm.bounds.left	 := (r.left   - arrow.bounds.left) * 4;
		bm.bounds.right  := (r.right  - arrow.bounds.left) * 4;

		bm.rowBytes := BSL (BSR (bm.bounds.right -
								 bm.bounds.left + 15, 4), 1);

		buffer := NewLargeHandle (bm.rowBytes *
							ORD4 (bm.bounds.bottom - bm.bounds.top));

		CatchFailures (fi, CleanUp);

		HLock (buffer);

		bm.baseAddr := buffer^;

		GetPort (savePort);

		OpenPort (@offPort);

		SetPortBits (bm);
		ClipRect (bm.bounds);
		RectRgn (offPort.visRgn, bm.bounds);

		EraseRect (bm.bounds);

		poly := OpenPoly;

		MoveTo (arrow.corner1.h, arrow.corner1.v);
		LineTo (arrow.corner2.h, arrow.corner2.v);

		IF LONGINT (arrow.corner3) <> LONGINT (arrow.corner2) THEN
			LineTo (arrow.corner3.h, arrow.corner3.v);

		LineTo (arrow.corner4.h, arrow.corner4.v);
		LineTo (arrow.corner1.h, arrow.corner1.v);

		ClosePoly;

		PaintPoly (poly);

		KillPoly (poly);

		SetPort (savePort);

		FOR gray := 0 TO 16 DO
			thresTable [gray] := CHR ((255 * ORD4 (gray) + 8) DIV 16);

		OffsetRect (r, -fLineRect.left, -fLineRect.top);

		FOR row := r.top TO r.bottom - 1 DO
			BEGIN

			MoveHands (TRUE);

			srcPtr := Ptr (ORD4 (bm.baseAddr) +
						   bm.rowBytes * ORD4 (row - r.top) * 4);

			DeHalftoneRow (srcPtr,
						   gBuffer,
						   bm.rowBytes,
						   r.right - r.left,
						   4,
						   thresTable);

			dstPtr := maskArray.NeedPtr (row, row, TRUE);
			dstPtr := Ptr (ORD4 (dstPtr) + r.left);

			DoMaxBytes (dstPtr, gBuffer, dstPtr, r.right - r.left);

			maskArray.DoneWithPtr

			END;

		maskArray.Flush;

		Success (fi);

		CleanUp (0, 0)

		END

	END;

{*****************************************************************************}

{$S ALineTool}

PROCEDURE TLineTool.MarkArray (srcArray: TVMArray;
							   dstArray: TVMArray;
							   level: INTEGER);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		row: INTEGER;

	BEGIN

	FOR row := 0 TO srcArray.fBlockCount - 1 DO
		BEGIN

		MoveHands (TRUE);

		srcPtr := srcArray.NeedPtr (row, row, FALSE);
		dstPtr := dstArray.NeedPtr (row, row, TRUE);

		DoMarkLine (srcPtr, dstPtr, level, srcArray.fLogicalSize);

		srcArray.DoneWithPtr;
		dstArray.DoneWithPtr

		END;

	srcArray.Flush;
	dstArray.Flush

	END;

{*****************************************************************************}

{$S ALineTool}

PROCEDURE TLineTool.MultiplyMasks (dstArray: TVMArray);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		srcRect: Rect;
		srcArray: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		srcArray.Flush;
		dstArray.Flush
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	srcRect  := fDoc.fSelectionRect;
	srcArray := fDoc.fSelectionMask;

	OffsetRect (srcRect, -fLineRect.left, -fLineRect.top);

	FOR row := 0 TO dstArray.fBlockCount - 1 DO
		BEGIN

		MoveHands (TRUE);

		dstPtr := dstArray.NeedPtr (row, row, TRUE);

		srcPtr := srcArray.NeedPtr (row - srcRect.top,
									row - srcRect.top, FALSE);
		srcPtr := Ptr (ORD4 (srcPtr) - srcRect.left);

		DoMultiplyMasks (srcPtr, dstPtr, dstArray.fLogicalSize);

		srcArray.DoneWithPtr;
		dstArray.DoneWithPtr

		END;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ALineTool}

PROCEDURE TLineTool.DoIt; OVERRIDE;

	VAR
		r: Rect;
		rr: Rect;
		fi: FailInfo;
		gray: INTEGER;
		ignore: BOOLEAN;
		channel: INTEGER;
		map: TLookUpTable;
		aVMArray: TVMArray;
		bVMArray: TVMArray;
		arrow: TArrowLocation;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (aVMArray);
		FailNewMessage (error, message, msgCannotLineTool)
		END;

	BEGIN

	aVMArray := NIL;

	CatchFailures (fi, CleanUp);

	MoveHands (TRUE);

	GetBounds (r);

	rr := fDoc.fSelectionRect;

	IF EmptyRect (rr) THEN
		fDoc.GetBoundsRect (rr);

	{$H-}
	IF NOT SectRect (rr, r, fLineRect) THEN Failure (0, 0);
	{$H+}

	aVMArray := NewVMArray (fLineRect.bottom - fLineRect.top,
							fLineRect.right - fLineRect.left, 1);

	aVMArray.SetBytes (0);

	IF fDrawLine THEN
		ImageLine (aVMArray);

	IF fArrow1 THEN
		BEGIN
		arrow := fArrowLoc1;
		ImageArrow (aVMArray, arrow)
		END;

	IF fArrow2 THEN
		BEGIN
		arrow := fArrowLoc2;
		ImageArrow (aVMArray, arrow)
		END;

	IF fDoc.fMode = IndexedColorMode THEN
		BEGIN

		FOR gray := 0 TO 255 DO
			IF gray >= 128 THEN
				map [gray] := CHR (255)
			ELSE
				map [gray] := CHR (0);

		aVMArray.MapBytes (map)

		END;

	IF fDoc.fSelectionMask <> NIL THEN
		MultiplyMasks (aVMArray);

	IF fDoc.fMode = IndexedColorMode THEN
		aVMArray.MapBytes (map);

	fChannel := fView.fChannel;

	r := fLineRect;

	IF fChannel = kRGBChannels THEN
		FOR channel := 0 TO 2 DO
			BEGIN

			bVMArray := fDoc.fData [channel] . CopyRect (r, 1);
			fBuffer [channel] := bVMArray;

			MarkArray (aVMArray, bVMArray, fView.ForegroundByte (channel))

			END

	ELSE
		BEGIN

		bVMArray := fDoc.fData [fChannel] . CopyRect (r, 1);
		fBuffer [0] := bVMArray;

		MarkArray (aVMArray, bVMArray, fView.ForegroundByte (fChannel))

		END;

	aVMArray.Free;
	aVMArray := NIL;

	MoveHands (TRUE);

	fDoc.FreeFloat;

	UndoIt;

	Success (fi)

	END;

{*****************************************************************************}

{$S ALineTool}

PROCEDURE TLineTool.SwapRect (iArray: TVMArray; bArray: TVMArray);

	VAR
		r: Rect;
		iPtr: Ptr;
		bPtr: Ptr;
		row: INTEGER;

	BEGIN

	r := fLineRect;

	FOR row := r.top TO r.bottom - 1 DO
		BEGIN

		MoveHands (FALSE);

		bPtr := bArray.NeedPtr (row - r.top, row - r.top, TRUE);
		iPtr := Ptr (ORD4 (iArray.NeedPtr (row, row, TRUE)) + r.left);

		DoSwapBytes (iPtr, bPtr, r.right - r.left);

		iArray.DoneWithPtr;
		bArray.DoneWithPtr

		END;

	iArray.Flush;
	bArray.Flush

	END;

{*****************************************************************************}

{$S ALineTool}

PROCEDURE TLineTool.UndoIt; OVERRIDE;

	VAR
		area: Rect;
		channel: INTEGER;

	BEGIN

	MoveHands (FALSE);

	area := fLineRect;

	IF fChannel = kRGBChannels THEN
		FOR channel := 0 TO 2 DO
			SwapRect (fDoc.fData [channel], fBuffer [channel])
	ELSE
		SwapRect (fDoc.fData [fChannel], fBuffer [0]);

	fDoc.UpdateImageArea (area, TRUE, TRUE, fChannel)

	END;

{*****************************************************************************}

{$S ALineTool}

PROCEDURE TLineTool.RedoIt; OVERRIDE;

	BEGIN
	UndoIt
	END;

{*****************************************************************************}

{$S ALineTool}

FUNCTION DoLineTool (view: TImageView): TCommand;

	VAR
		doc: TImageDocument;
		aLineTool: TLineTool;

	BEGIN

	doc := TImageDocument (view.fDocument);

	IF doc.fMode = HalftoneMode THEN
		Failure (errNoHalftone, msgCannotLineTool);

	NEW (aLineTool);
	FailNil (aLineTool);

	aLineTool.ILineTool (view);

	DoLineTool := aLineTool

	END;

{*****************************************************************************}

{$S ALineTool}

PROCEDURE DoLineToolOptions;

	CONST
		kDialogID	   = 1094;
		kHookItem	   = 3;
		kWidthItem	   = 4;
		kAtStartItem   = 5;
		kAtEndItem	   = 6;
		kAWidthItem    = 7;
		kALengthItem   = 8;
		kConcavityItem = 9;

	VAR
		fi: FailInfo;
		hitItem: INTEGER;
		atEndBox: TCheckBox;
		aBWDialog: TBWDialog;
		widthText: TFixedText;
		atStartBox: TCheckBox;
		aWidthText: TFixedText;
		aLengthText: TFixedText;
		concavityText: TFixedText;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	widthText := aBWDialog.DefineFixedText
				 (kWidthItem, 0, FALSE, TRUE, 1, 99);

	widthText.StuffValue (gLineWidth);

	aWidthText := aBWDialog.DefineFixedText
				  (kAWidthItem, 0, FALSE, TRUE, 5, 99);

	aWidthText.StuffValue (gArrowWidth);

	aLengthText := aBWDialog.DefineFixedText
				   (kALengthItem, 0, FALSE, TRUE, 7, 99);

	aLengthText.StuffValue (gArrowLength);

	concavityText := aBWDialog.DefineFixedText
					 (kConcavityItem, 0, FALSE, TRUE, 0, 50);

	concavityText.StuffValue (gArrowConcavity);

	atStartBox := aBWDialog.DefineCheckBox (kAtStartItem, gArrowAtStart);
	atEndBox   := aBWDialog.DefineCheckBox (kAtEndItem	, gArrowAtEnd  );

	aBWDialog.SetEditSelection (kWidthItem);

	aBWDialog.TalkToUser (hitItem, StdItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	gLineWidth		:= widthText	.fValue;
	gArrowWidth 	:= aWidthText	.fValue;
	gArrowLength	:= aLengthText	.fValue;
	gArrowConcavity := concavityText.fValue;

	gArrowAtStart := atStartBox.fChecked;
	gArrowAtEnd   := atEndBox  .fChecked;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

END.

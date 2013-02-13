{Photoshop version 1.0.1, file: USelect.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}
{$I USelect.a.inc}

VAR
	gLassoRadius: INTEGER;

	gWandTolerance: INTEGER;
	gWandFuzziness: INTEGER;

	gBucketTolerance: INTEGER;
	gBucketFuzziness: INTEGER;

	gFringeWidth: INTEGER;

	gDefringeWidth: INTEGER;

	gFeatherRadius: INTEGER;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitSelections;

	BEGIN

	gLassoRadius := 0;

	gWandTolerance := 32;
	gWandFuzziness := 64;

	gBucketTolerance := 32;
	gBucketFuzziness := 64;

	gFringeWidth := 4;

	gDefringeWidth := 1;

	gFeatherRadius := 50

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TSelectRect.ISelectRect (itsCommand: INTEGER;
								   view: TImageView;
								   r: Rect);

	BEGIN

	fSelectRect := r;

	IFloatCommand (itsCommand, view);

	fCausesChange := FALSE

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TSelectRect.DoIt; OVERRIDE;

	BEGIN

	IF fWasFloating THEN
		FloatSelection (TRUE)

	ELSE
		BEGIN

		fFloatRect := fDoc.fSelectionRect;

		IF fDoc.fSelectionMask <> NIL THEN
			fFloatMask := fDoc.fSelectionMask.CopyArray (1)

		END;

	RedoIt

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TSelectRect.UndoIt; OVERRIDE;

	VAR
		r: Rect;
		mask: TVMArray;

	BEGIN

	IF fWasFloating THEN
		SelectFloat

	ELSE
		BEGIN

		r := fFloatRect;

		IF fFloatMask = NIL THEN
			mask := NIL
		ELSE
			mask := fFloatMask.CopyArray (1);

		fDoc.Select (r, mask)

		END

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TSelectRect.RedoIt; OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	r := fSelectRect;

	fDoc.Select (r, NIL)

	END;

{*****************************************************************************}

{$S ASelect}

FUNCTION DoSelectAll (view: TImageView): TCommand;

	VAR
		r: Rect;
		doc: TImageDocument;
		aSelectRect: TSelectRect;

	BEGIN

	doc := TImageDocument (view.fDocument);

	doc.GetBoundsRect (r);

	NEW (aSelectRect);
	FailNil (aSelectRect);

	aSelectRect.ISelectRect (cSelectAll, view, r);

	DoSelectAll := aSelectRect

	END;

{*****************************************************************************}

{$S ASelect}

FUNCTION DoSelectNone (view: TImageView): TCommand;

	VAR
		doc: TImageDocument;
		aSelectRect: TSelectRect;

	BEGIN

	NEW (aSelectRect);
	FailNil (aSelectRect);

	aSelectRect.ISelectRect (cSelectNone, view, gZeroRect);

	DoSelectNone := aSelectRect

	END;

{*****************************************************************************}

{$S ASelect}

FUNCTION DropSelection (view: TImageView): TCommand;

	VAR
		doc: TImageDocument;
		aSelectRect: TSelectRect;

	BEGIN

	doc := TImageDocument (view.fDocument);

	IF EmptyRect (doc.fSelectionRect) THEN
		DropSelection := gNoChanges

	ELSE
		BEGIN

		NEW (aSelectRect);
		FailNil (aSelectRect);

		aSelectRect.ISelectRect (cDeselect, view, gZeroRect);

		DropSelection := aSelectRect

		END

	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ARes}

PROCEDURE InterpolatePoints (pt1, pt2: Point;
							 PROCEDURE EachPoint (pt: Point));

	VAR
		pt: Point;
		j: INTEGER;
		dh: INTEGER;
		dv: INTEGER;
		ah: INTEGER;
		av: INTEGER;
		half: LONGINT;

	BEGIN

	dh := pt2.h - pt1.h;
	dv := pt2.v - pt1.v;

	ah := ABS (dh);
	av := ABS (dv);

	IF (ah > 1) AND (ah >= av) THEN
		BEGIN

		IF dv >= 0 THEN
			half := BSR (ah, 1)
		ELSE
			half := -BSR (ah, 1);

		FOR j := 1 TO ah - 1 DO
			BEGIN

			IF dh > 0 THEN
				pt.h := pt1.h + j
			ELSE
				pt.h := pt1.h - j;

			pt.v := pt1.v + (j * ORD4 (dv) + half) DIV ah;

			EachPoint (pt)

			END

		END

	ELSE IF (av > 1) THEN
		BEGIN

		IF dh >= 0 THEN
			half := BSR (av, 1)
		ELSE
			half := -BSR (av, 1);

		FOR j := 1 TO av - 1 DO
			BEGIN

			IF dv > 0 THEN
				pt.v := pt1.v + j
			ELSE
				pt.v := pt1.v - j;

			pt.h := pt1.h + (j * ORD4 (dh) + half) DIV av;

			EachPoint (pt)

			END

		END;

	EachPoint (pt2)

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S ARes}

PROCEDURE Find4Connected (mask: TVMArray;
						  r: Rect;
						  edgeFill: BOOLEAN;
						  canAbort: BOOLEAN);

	VAR
		fi: FailInfo;
		row: INTEGER;
		maskPtr: Ptr;
		prevLine: Ptr;
		thisLine: Ptr;
		saveLine: Ptr;
		width: INTEGER;
		buffer1: Handle;
		buffer2: Handle;
		nextRgn: INTEGER;
		map: TLookUpTable;
		edgeValue: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		FreeLargeHandle (buffer1);
		FreeLargeHandle (buffer2);

		mask.Flush

		END;

	PROCEDURE MapUpToRow (limit: INTEGER);

		VAR
			row: INTEGER;

		BEGIN

		FOR row := r.top TO limit - 1 DO
			BEGIN

			maskPtr := mask.NeedPtr (row, row, TRUE);

			DoMapBytes (Ptr (ORD4 (maskPtr) + r.left),
						width,
						map);

			mask.DoneWithPtr

			END

		END;

	PROCEDURE PurgeOldRegions;

		VAR
			j: INTEGER;
			gray: INTEGER;
			map2: TLookUpTable;

		BEGIN

		DoSetBytes (@map2, 256, 0);

		map2 [1]   := CHR (1);
		map2 [255] := CHR (255);

		nextRgn := 254;

		FOR j := 1 TO width DO
			BEGIN

			gray := BAND ($FF, Ptr (ORD4 (thisLine) + j)^);

			IF (gray > 1) & (gray < 255) & (map2 [gray] = CHR (0)) THEN
				BEGIN
				map2 [gray] := CHR (nextRgn);
				nextRgn := nextRgn - 1
				END

			END;

		FOR gray := 0 TO 255 DO
			map [gray] := map2 [ORD (map [gray])];

		MapUpToRow (row);

		DoMapBytes (Ptr (ORD4 (thisLine) + 1), width, map);

		map := gNullLUT;

		{$IFC qDebug}
		writeln ('Purging old regions');
		writeln ('Row: ', row - r.top : 1, ' of ', r.bottom - r.top : 1);
		writeln ('Regions in use: ', 254 - nextRgn : 1);
		{$ENDC}

		END;

	PROCEDURE ComputeFinalMap;

		VAR
			gray: INTEGER;

		BEGIN

		FOR gray := 0 TO 255 DO
			IF (map [gray] = CHR (255)) <> edgeFill THEN
				map [gray] := CHR (255)
			ELSE
				map [gray] := CHR (0)

		END;

	BEGIN

	buffer1 := NIL;
	buffer2 := NIL;

	CatchFailures (fi, CleanUp);

	width := r.right - r.left;

	buffer1 := NewLargeHandle (width + 2);
	buffer2 := NewLargeHandle (width + 2);

	HLock (buffer1);
	HLock (buffer2);

	prevLine := buffer1^;
	thisLine := buffer2^;

	IF edgeFill THEN
		edgeValue := 255
	ELSE
		edgeValue := 0;

	DoSetBytes (prevLine, width + 2, edgeValue);
	DoSetBytes (thisLine, width + 2, edgeValue);

	map := gNullLUT;

	nextRgn := 254;

	FOR row := r.top TO r.bottom DO
		BEGIN

		MoveHands (canAbort);

		saveLine := prevLine;
		prevLine := thisLine;
		thisLine := saveLine;

		IF row = r.bottom THEN
			DoSetBytes (thisLine, width + 2, edgeValue)

		ELSE
			BEGIN
			maskPtr := mask.NeedPtr (row, row, FALSE);
			BlockMove (Ptr (ORD4 (maskPtr) + r.left),
					   Ptr (ORD4 (thisLine) + 1),
					   width);
			mask.DoneWithPtr
			END;

		MergeForward (Ptr (ORD4 (prevLine) + 1),
					  Ptr (ORD4 (thisLine) + 1),
					  width,
					  map);

		PropagateBackward (Ptr (ORD4 (thisLine) + 1),
						   width);

		MergeForward (thisLine,
					  Ptr (ORD4 (thisLine) + 1),
					  width + 1,
					  map);

		IF NOT MarkNewRegions (Ptr (ORD4 (thisLine) + 1),
							   width,
							   nextRgn) THEN
			BEGIN
			PurgeOldRegions;
			IF NOT MarkNewRegions (Ptr (ORD4 (thisLine) + 1),
								   width,
								   nextRgn) THEN
				Failure (errRgnTooComplex, 0)
			END;

		IF row <> r.bottom THEN
			BEGIN
			maskPtr := mask.NeedPtr (row, row, TRUE);
			BlockMove (Ptr (ORD4 (thisLine) + 1),
					   Ptr (ORD4 (maskPtr) + r.left),
					   width);
			mask.DoneWithPtr
			END

		END;

	ComputeFinalMap;

	MapUpToRow (r.bottom);

	Success (fi);

	CleanUp (0, 0);

	MoveHands (canAbort)

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TMaskCommand.IMaskCommand (itsCommand: INTEGER;
									 view: TImageView;
									 add, remove, refine, drop: BOOLEAN;
									 needMask: BOOLEAN;
									 obscure: BOOLEAN);

	VAR
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Free
		END;

	BEGIN

	fMask := NIL;

	fSaveMask := NIL;

	fAdd	:= add;
	fDrop	:= drop;
	fRemove := remove;
	fRefine := refine;

	IFloatCommand (itsCommand, view);

	IF EmptyRect (fDoc.fSelectionRect) THEN
		BEGIN
		fAdd	:= FALSE;
		fRemove := FALSE;
		fRefine := FALSE
		END;

	fTrim := fWasFloating AND (fRemove OR fRefine);

	fDrop := fDrop AND fTrim;

	fCausesChange := fTrim;

	fAutoScroll := FALSE;

	CatchFailures (fi, CleanUp);

	IF needMask OR fAdd OR fRemove OR fRefine THEN
		fMask := NewVMArray (fDoc.fRows, fDoc.fCols, 1);

	fObscure := obscure AND
				NOT (fAdd OR fRemove OR fRefine) AND
				NOT EmptyRect (fDoc.fSelectionRect) AND
				NOT fView.fObscured;

	IF fObscure THEN
		BEGIN
		IF fDoc.fSelectionMask <> NIL THEN
			MoveHands (FALSE);
		fView.ObscureSelection (-1);
		SetToolCursor (gUseTool, TRUE)
		END;

	Success (fi)

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TMaskCommand.Free; OVERRIDE;

	BEGIN

	FreeObject (fMask);

	FreeObject (fSaveMask);

	INHERITED Free

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TMaskCommand.FixObscured;

	VAR
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		EXIT (FixObscured)
		END;

	BEGIN

	IF fObscure THEN
		IF NOT EmptyRect (fDoc.fSelectionRect) AND fView.fObscured THEN
			BEGIN

			CatchFailures (fi, CleanUp);

			fView.fObscured := FALSE;
			fView.DoHighlightSelection (HLOff, HLOn);

			Success (fi)

			END

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TMaskCommand.TrackFeedBack
		(anchorPoint, nextPoint: Point;
		 turnItOn, mouseDidMove: BOOLEAN); OVERRIDE;

	BEGIN
	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TMaskCommand.CombineMask (sr: Rect; sm: TVMArray; VAR delta: Rect);

	VAR
		mr: Rect;
		oldPtr: Ptr;
		newPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		bounds: Rect;
		ignore: BOOLEAN;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		sm.DoneWithPtr;
		sm.Flush
		END;

	BEGIN

	mr := fMaskBounds;

	UnionRect (mr, sr, bounds);

	IF fAdd THEN
		InsetRect (mr, Min (-1, fView.fMagnification),
					   Min (-1, fView.fMagnification));

	delta := sr;

	IF fAdd OR fRemove THEN
		ignore := SectRect (mr, delta, delta);

	IF fRemove OR fRefine THEN
		fMask.SetOutsideRect (sr, 0);

	IF fRemove THEN
		fMask.MapRect (sr, gInvertLUT);

	IF (sm <> NIL) AND (fAdd OR fRemove OR fRefine) THEN
		BEGIN

		FOR row := sr.top TO sr.bottom - 1 DO
			BEGIN

			oldPtr := sm.NeedPtr (row - sr.top, row - sr.top, FALSE);

			CatchFailures (fi, CleanUp);

			MoveHands (TRUE);

			newPtr := fMask.NeedPtr (row, row, TRUE);

			newPtr := Ptr (ORD4 (newPtr) + sr.left);

			IF fAdd THEN
				DoMaxBytes (oldPtr,
							newPtr,
							newPtr,
							sr.right - sr.left)
			ELSE
				DoMinBytes (oldPtr,
							newPtr,
							newPtr,
							sr.right - sr.left);

			fMask.DoneWithPtr;

			Success (fi);

			sm.DoneWithPtr

			END;

		sm.Flush

		END

	ELSE IF fAdd THEN
		fMask.SetRect (sr, 255);

	IF fAdd OR fRemove OR fRefine THEN
		BEGIN

		fMask.FindInnerBounds (bounds);

		fMaskBounds := bounds

		END

	END;

{*****************************************************************************}

{$S ASelect}

FUNCTION TMaskCommand.SolidMask: BOOLEAN;

	VAR
		p: Ptr;
		r: Rect;
		row: INTEGER;
		solid: BOOLEAN;

	BEGIN

	r := fMaskBounds;

	FOR row := r.top TO r.bottom - 1 DO
		BEGIN

		p := Ptr (ORD4 (fMask.NeedPtr (row, row, FALSE)) + r.left);

		solid := SolidRow (p, r.right - r.left);

		fMask.DoneWithPtr;

		IF NOT solid THEN LEAVE

		END;

	fMask.Flush;

	SolidMask := solid

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TMaskCommand.DropDifference;

	VAR
		r: Rect;
		rr: Rect;
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		width: INTEGER;
		aVMArray: TVMArray;
		saveMask: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aVMArray.Free;
		fDoc.fFloatMask := saveMask
		END;

	BEGIN

	r := fDoc.fFloatRect;

	aVMArray := NewVMArray (r.bottom - r.top, r.right - r.left, 1);

	saveMask := fDoc.fFloatMask;

	CatchFailures (fi, CleanUp);

	IF fDoc.fFloatMask <> NIL THEN
		fDoc.fFloatMask.MoveArray (aVMArray)
	ELSE
		aVMArray.SetBytes (255);

	rr := fFloatRect;
	OffsetRect (rr, -r.left, -r.top);

	IF fFloatMask = NIL THEN
		aVMArray.SetRect (r, 0)

	ELSE
		BEGIN

		width := rr.right - rr.left;

		FOR row := rr.top TO rr.bottom - 1 DO
			BEGIN

			srcPtr := fFloatMask.NeedPtr (row - rr.top,
										  row - rr.top, FALSE);

			dstPtr := Ptr (ORD4 (aVMArray.NeedPtr (row,
												   row, TRUE)) + rr.left);

			DoDeltaMask (srcPtr, dstPtr, width);

			fFloatMask.DoneWithPtr;
			aVMArray.DoneWithPtr

			END;

		fFloatMask.Flush;
		aVMArray.Flush

		END;

	fDoc.DeSelect (FALSE);

	CopyBelow (FALSE);

	fDoc.fFloatMask := aVMArray;

	BlendFloat (FALSE);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TMaskCommand.TrimFloat (delta: Rect);

	VAR
		r: Rect;
		fi: FailInfo;
		channel: INTEGER;
		channels: INTEGER;
		aVMArray: TVMArray;

	BEGIN

	FloatSelection (FALSE);

	IF EmptyRect (fMaskBounds) THEN
		BEGIN

		IF NOT fDrop THEN
			CopyBelow (FALSE);

		r := fDoc.fSelectionRect;

		fDoc.DeSelect (FALSE);

		fDoc.UpdateImageArea (r, FALSE, TRUE, fDoc.fFloatChannel)

		END

	ELSE
		BEGIN

		fSwapMask	:= TRUE;
		fExactFloat := FALSE;
		fFloatRect	:= fMaskBounds;

		IF NOT SolidMask THEN
			BEGIN
			r := fMaskBounds;
			fFloatMask := fMask.CopyRect (r, 1)
			END;

		fMask.Free;
		fMask := NIL;

		IF NOT EqualRect (fFloatRect, fDoc.fFloatRect) OR fDrop THEN
			BEGIN

			IF fDoc.fFloatChannel = kRGBChannels THEN
				channels := 3
			ELSE
				channels := 1;

			r := fFloatRect;
			OffsetRect (r, -fDoc.fFloatRect.left, -fDoc.fFloatRect.top);

			FOR channel := 0 TO channels - 1 DO
				BEGIN
				aVMArray := fDoc.fFloatData [channel] . CopyRect (r, 1);
				fFloatData [channel] := aVMArray
				END;

			FOR channel := 0 TO channels - 1 DO
				BEGIN
				aVMArray := NewVMArray (r.bottom - r.top, r.right - r.left, 1);
				fFloatBelow [channel] := aVMArray
				END

			END;

		IF fDrop THEN
			DropDifference
		ELSE
			BEGIN
			fDoc.DeSelect (FALSE);
			CopyBelow (FALSE)
			END;

		SwapFloat;

		CopyBelow (TRUE);

		BlendFloat (FALSE);

		fDoc.UpdateImageArea (delta, FALSE, TRUE, fDoc.fFloatChannel);

		SelectFloat

		END

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TMaskCommand.UpdateSelection;

	VAR
		mr: Rect;
		sr: Rect;
		delta: Rect;
		update: Rect;
		gray: INTEGER;
		hist: THistogram;
		aVMArray: TVMArray;

	BEGIN

	delta := gZeroRect;

	mr := fMaskBounds;
	sr := fDoc.fSelectionRect;

	IF NOT EmptyRect (sr) THEN
		CombineMask (sr, fDoc.fSelectionMask, delta);

	mr := fMaskBounds;

	IF NOT EmptyRect (mr) THEN
		BEGIN

		MoveHands (TRUE);

		fMask.HistRect (mr, hist);

		gray := 255;

		WHILE hist [gray] = 0 DO
			gray := gray - 1;

		IF gray < 128 THEN
			mr := gZeroRect

		END;

	fMaskBounds := mr;

	IF NOT (fRemove OR fRefine) AND EmptyRect (mr) THEN
		Failure (errNoPixels, msgCannotSelect);

	IF fCanUndo THEN gApplication.CommitLastCommand;

	fTrim := fTrim OR (fWasFloating AND EmptyRect (mr));

	IF fTrim THEN
		TrimFloat (delta)

	ELSE
		BEGIN

		IF EmptyRect (mr) | SolidMask THEN
			aVMArray := NIL
		ELSE
			aVMArray := fMask.CopyRect (mr, 1);

		fMask.Free;
		fMask := aVMArray;

		IF fWasFloating THEN
			FloatSelection (FALSE)
		ELSE
			BEGIN
			fSaveRect := fDoc.fSelectionRect;
			IF fDoc.fSelectionMask <> NIL THEN
				fSaveMask := fDoc.fSelectionMask.CopyArray (1)
			END;

		update := gZeroRect;

		IF WindowPeek (fView.fWindow.fWmgrWindow)^ . updateRgn <> NIL THEN
			BEGIN

			update := WindowPeek (fView.fWindow.fWmgrWindow)^.
					  updateRgn^^.rgnBBox;

			GlobalToLocal (update.topLeft);
			GlobalToLocal (update.botRight)

			END;

		IF fAdd OR fRemove OR fRefine THEN
			BEGIN
			fDoc.DeSelect (FALSE);
			fView.UpdateImageArea (delta, FALSE)
			END

		ELSE IF (fDoc.fSelectionMask = NIL) OR
				NOT SectRect (sr, update, update) THEN
			BEGIN
			fView.UpdateImageArea (gZeroRect, FALSE);
			fDoc.DeSelect (TRUE)
			END

		ELSE
			BEGIN
			fDoc.DeSelect (FALSE);
			fView.UpdateImageArea (sr, FALSE)
			END;

		IF NOT EmptyRect (mr) THEN
			BEGIN
			IF fMask = NIL THEN
				aVMArray := NIL
			ELSE
				aVMArray := fMask.CopyArray (1);
			fDoc.Select (mr, aVMArray)
			END

		END

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TMaskCommand.UndoIt; OVERRIDE;

	VAR
		r1: Rect;
		r2: Rect;

	BEGIN

	MoveHands (FALSE);

	IF fTrim THEN

		IF EmptyRect (fMaskBounds) THEN
			BEGIN

			fDoc.DeSelect (TRUE);

			BlendFloat (FALSE);

			ComputeOverlap (r1);
			fDoc.UpdateImageArea (r1, FALSE, TRUE, fDoc.fFloatChannel);

			SelectFloat

			END

		ELSE
			BEGIN

			ComputeOverlap (r1);

			fDoc.DeSelect (NOT EqualRect (fDoc.fSelectionRect, r1));

			CopyBelow (FALSE);

			SwapFloat;

			IF NOT fDrop THEN
				CopyBelow (TRUE);

			BlendFloat (FALSE);

			ComputeOverlap (r2);

			UpdateRects (r1, r2, FALSE);

			SelectFloat

			END

	ELSE IF fWasFloating THEN
		SelectFloat

	ELSE
		BEGIN

		fDoc.DeSelect (TRUE);

		r1 := fSaveRect;

		IF NOT EmptyRect (r1) THEN
			IF fSaveMask = NIL THEN
				fDoc.Select (r1, NIL)
			ELSE
				fDoc.Select (r1, fSaveMask.CopyArray (1))

		END

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TMaskCommand.RedoIt; OVERRIDE;

	VAR
		r: Rect;
		r1: Rect;
		r2: Rect;

	BEGIN

	MoveHands (FALSE);

	IF fTrim THEN

		IF EmptyRect (fMaskBounds) THEN
			BEGIN

			ComputeOverlap (r);

			fDoc.DeSelect (NOT EqualRect (fDoc.fSelectionRect, r));

			IF NOT fDrop THEN
				CopyBelow (FALSE);

			fDoc.UpdateImageArea (r, FALSE, TRUE, fDoc.fFloatChannel)

			END

		ELSE IF fDrop THEN
			BEGIN

			ComputeOverlap (r1);

			fDoc.DeSelect (NOT EqualRect (fDoc.fSelectionRect, r1));

			DropDifference;

			SwapFloat;

			CopyBelow (TRUE);

			BlendFloat (FALSE);

			ComputeOverlap (r2);

			UpdateRects (r1, r2, FALSE);

			SelectFloat

			END

		ELSE
			UndoIt

	ELSE
		BEGIN

		fDoc.DeSelect (TRUE);

		r := fMaskBounds;

		IF NOT EmptyRect (r) THEN
			IF fMask = NIL THEN
				fDoc.Select (r, NIL)
			ELSE
				fDoc.Select (r, fMask.CopyArray (1))

		END

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TLassoSelector.ILassoSelector (view: TImageView;
										 downPoint: Point;
										 add, remove, refine, drop: BOOLEAN);

	VAR
		vr: Rect;
		r: INTEGER;
		g: INTEGER;
		b: INTEGER;

	BEGIN

	IMaskCommand (cLasso, view, add, remove, refine, drop, TRUE, TRUE);

	fConstrainsMouse := TRUE;

	view.fFrame.GetViewedRect (vr);

	vr.right  := vr.right  - 1;
	vr.bottom := vr.bottom - 1;

	fMouseRect := vr;

	view.GetViewColor (downPoint, r, g, b);

	fWhite := ORD (ConvertToGray (r, g, b)) < 128;

	fMovedOnce := FALSE

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TLassoSelector.TrackConstrain
		(anchorPoint, previousPoint: Point; VAR nextPoint: Point); OVERRIDE;

	BEGIN

	fView.TrackRulers;

	nextPoint := Point (PinOnRect (fMouseRect, nextPoint))

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TLassoSelector.ComputeMask;

	VAR
		mr: Rect;
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress
		END;

	BEGIN

	mr := fMaskBounds;

	Find4Connected (fMask, mr, TRUE, TRUE);

	fMask.SetOutsideRect (mr, 0);

	IF (gLassoRadius <> 0) AND
	   (fDoc.fMode <> HalftoneMode) AND
	   (fDoc.fMode <> IndexedColorMode) AND
	   (gTool <> TextTool) THEN
		BEGIN

		CommandProgress (fCmdNumber);

		CatchFailures (fi, CleanUp);

		GaussianFilter (fMask, mr, gLassoRadius, TRUE, TRUE);

		Success (fi);

		CleanUp (0, 0);

		fMask.FindInnerBounds (mr)

		END;

	fMaskBounds := mr

	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ASelect}

PROCEDURE TLassoSelector.MarkMask (fromPt, toPt: Point);

	VAR
		pt1: Point;
		pt2: Point;
		limit: Point;

	PROCEDURE MarkPoint (pt: Point);

		VAR
			p: Ptr;

		BEGIN

		p := fMask.NeedPtr (pt.v, pt.v, TRUE);

		IF pt.v < fMaskBounds.top THEN
			BEGIN
			fMaskBounds.top := pt.v;
			DoSetBytes (p, fDoc.fCols, 1)
			END;

		IF pt.v >= fMaskBounds.bottom THEN
			BEGIN
			fMaskBounds.bottom := pt.v + 1;
			DoSetBytes (p, fDoc.fCols, 1)
			END;

		p  := Ptr (ORD4 (p) + pt.h);
		p^ := 0;

		fMask.DoneWithPtr

		END;

	BEGIN

	pt1 := fromPt;
	pt2 := toPt;

	limit.h := fDoc.fCols;
	limit.v := fDoc.fRows;

	fView.CvtImage2View (limit, kRoundUp);

	IF pt1.h = limit.h - 1 THEN pt1.h := limit.h;
	IF pt2.h = limit.h - 1 THEN pt2.h := limit.h;

	IF pt1.v = limit.v - 1 THEN pt1.v := limit.v;
	IF pt2.v = limit.v - 1 THEN pt2.v := limit.v;

	fView.CvtView2Image (pt1);
	fView.CvtView2Image (pt2);

	IF pt1.h = fDoc.fCols THEN pt1.h := fDoc.fCols - 1;
	IF pt2.h = fDoc.fCols THEN pt2.h := fDoc.fCols - 1;

	IF pt1.v = fDoc.fRows THEN pt1.v := fDoc.fRows - 1;
	IF pt2.v = fDoc.fRows THEN pt2.v := fDoc.fRows - 1;

	IF NOT fMovedOnce THEN
		{$H-}
		SetRect (fMaskBounds, pt1.h, pt1.v, pt1.h, pt1.v);
		{$H+}

	MarkPoint (pt1);

	InterpolatePoints (pt1, pt2, MarkPoint);

	fMaskBounds.left  := Min (fMaskBounds.left , Min (pt1.h, pt2.h));
	fMaskBounds.right := Max (fMaskBounds.right, Max (pt1.h, pt2.h) + 1)

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S ASelect}

PROCEDURE TLassoSelector.Extend (fromPt, toPt: Point);

	VAR
		r: Rect;

	BEGIN

	MarkMask (fromPt, toPt);

	PenNormal;

	IF fWhite THEN PenPat (white);

	MoveTo (fromPt.h, fromPt.v);
	LineTo (  toPt.h,	toPt.v);

	Pt2Rect (fromPt, toPt, r);

	r.right  := r.right  + 1;
	r.bottom := r.bottom + 1;

	IF fMovedOnce THEN
		{$H-}
		UnionRect (r, fViewBounds, fViewBounds)
		{$H+}
	ELSE
		fViewBounds := r;

	fMovedOnce := TRUE

	END;

{*****************************************************************************}

{$S ASelect}

FUNCTION TLassoSelector.TrackMouseUp
		(VAR didMove: BOOLEAN;
		 VAR anchorPoint: Point;
		 VAR previousPoint: Point): BOOLEAN; OVERRIDE;

	VAR
		fi: FailInfo;
		lastPoint: Point;
		nextPoint: Point;
		theEvent: EventRecord;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		VAR
			r: Rect;

		BEGIN

		r := fViewBounds;
		fView.fFrame.InvalidRect (r);

		fView.UpdateImageArea (gZeroRect, TRUE);

		FixObscured;

		Free;
		FailNewMessage (error, message, msgCannotLasso)

		END;

	FUNCTION OptionDown: BOOLEAN;

		VAR
			theKeys: KeyMap;

		BEGIN
		GetKeys (theKeys);
		OptionDown := theKeys [kOptionCode]
		END;

	PROCEDURE ToggleFeedback (pt: Point);
		BEGIN
		PenNormal;
		PenMode (PatXOR);
		MoveTo (previousPoint.h, previousPoint.v);
		Line (0, 0);
		LineTo (pt.h, pt.v)
		END;

	BEGIN

	TrackMouseUp := FALSE;

	IF NOT OptionDown THEN EXIT (TrackMouseUp);

	CatchFailures (fi, CleanUp);

	didMove := TRUE;

	IF GetNextEvent (mUpMask, theEvent) THEN;

	ToggleFeedback (previousPoint);

	lastPoint := previousPoint;

	WHILE OptionDown DO
		BEGIN

		fView.TrackRulers;

		GetMouse (nextPoint);

		nextPoint := Point (PinOnRect (fMouseRect, nextPoint));

		IF LONGINT (nextPoint) <> LONGINT (lastPoint) THEN
			BEGIN
			ToggleFeedback (lastPoint);
			ToggleFeedback (nextPoint);
			lastPoint := nextPoint
			END;

		IF GetNextEvent (mDownMask, theEvent) THEN
			BEGIN

			ToggleFeedback (lastPoint);
			nextPoint := theEvent.where;
			GlobalToLocal (nextPoint);
			nextPoint := Point (PinOnRect (fMouseRect, nextPoint));
			Extend (previousPoint, nextPoint);
			previousPoint := nextPoint;

			IF StillDown THEN
				BEGIN
				Success (fi);
				TrackMouseUp := TRUE;
				EXIT (TrackMouseUp)
				END;

			IF GetNextEvent (mUpMask, theEvent) THEN
				BEGIN
				nextPoint := theEvent.where;
				GlobalToLocal (nextPoint);
				nextPoint := Point (PinOnRect (fMouseRect, nextPoint));
				Extend (previousPoint, nextPoint);
				previousPoint := nextPoint;
				ToggleFeedback (previousPoint);
				lastPoint := previousPoint
				END

			END

		END;

	ToggleFeedback (lastPoint);

	Success (fi)

	END;

{*****************************************************************************}

{$S ASelect}

FUNCTION TLassoSelector.TrackMouse
		(aTrackPhase: TrackPhase;
		 VAR anchorPoint, previousPoint, nextPoint: Point;
		 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

	VAR
		r: Rect;
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		r := fViewBounds;
		fView.fFrame.InvalidRect (r);

		fView.UpdateImageArea (gZeroRect, TRUE);

		FixObscured;

		Free;
		FailNewMessage (error, message, msgCannotLasso)

		END;

	BEGIN

	TrackMouse := SELF;

	CatchFailures (fi, CleanUp);

	IF mouseDidMove THEN

		CASE aTrackPhase OF

		trackMove:
			Extend (previousPoint, nextPoint);

		trackRelease:
			IF NOT fMovedOnce THEN
				BEGIN

				r := fViewBounds;
				fView.fFrame.InvalidRect (r);

				fView.UpdateImageArea (gZeroRect, TRUE);

				TrackMouse := DropSelection (fView)

				END

			ELSE
				BEGIN

				MoveHands (TRUE);

				Extend (previousPoint, anchorPoint);

				r := fViewBounds;
				fView.fFrame.InvalidRect (r);

				ComputeMask;

				UpdateSelection

				END

		END;

	Success (fi)

	END;

{*****************************************************************************}

{$S ASelect}

FUNCTION DoLassoTool (view: TImageView;
					  downPoint: Point;
					  add: BOOLEAN;
					  remove: BOOLEAN;
					  refine: BOOLEAN;
					  drop: BOOLEAN): TCommand;

	VAR
		fi: FailInfo;
		aLassoSelector: TLassoSelector;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FailNewMessage (error, message, msgCannotLasso)
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	NEW (aLassoSelector);
	FailNil (aLassoSelector);

	aLassoSelector.ILassoSelector (view, downPoint, add,
								   remove, refine, drop);

	DoLassoTool := aLassoSelector;

	Success (fi)

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE DoLassoOptions;

	CONST
		kDialogID	= 1081;
		kHookItem	= 3;
		kRadiusItem = 4;

	VAR
		fi: FailInfo;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		radiusText: TFixedText;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	radiusText := aBWDialog.DefineFixedText
				  (kRadiusItem, 0, TRUE, TRUE, 0, 64);

	radiusText.StuffValue (gLassoRadius DIV 10);

	aBWDialog.SetEditSelection (kRadiusItem);

	aBWDialog.TalkToUser (hitItem, StdItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	gLassoRadius := radiusText.fValue * 10;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TWandSelector.IWandSelector (itsCommand: INTEGER;
									   view: TImageView;
									   add, remove, refine: BOOLEAN);

	BEGIN

	fIgnore    := 0;
	fTolerance := gWandTolerance;
	fFuzziness := gWandFuzziness;
	fConnected := TRUE;

	IMaskCommand (itsCommand, view, add, remove, refine, FALSE, TRUE, FALSE)

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TWandSelector.HistRegion (src1Array: TVMArray;
									src2Array: TVMArray;
									src3Array: TVMArray;
									rgnRect: Rect;
									rgnMask: TVMArray;
									VAR hists: THistograms);

	VAR
		fi: FailInfo;
		row: INTEGER;
		src1Ptr: Ptr;
		src2Ptr: Ptr;
		src3Ptr: Ptr;
		maskPtr: Ptr;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		IF src1Ptr <> NIL THEN src1Array.DoneWithPtr;
		IF src2Ptr <> NIL THEN src2Array.DoneWithPtr;
		IF src3Ptr <> NIL THEN src3Array.DoneWithPtr;

		IF maskPtr <> NIL THEN rgnMask.DoneWithPtr;

		src1Array.Flush;

		IF src2Array <> NIL THEN
			BEGIN
			src2Array.Flush;
			src3Array.Flush
			END;

		IF rgnMask <> NIL THEN rgnMask.Flush

		END;

	BEGIN

	src1Ptr := NIL;
	src2Ptr := NIL;
	src3Ptr := NIL;
	maskPtr := NIL;

	CatchFailures (fi, CleanUp);

	DoSetBytes (@hists, SIZEOF (THistograms), 0);

	FOR row := rgnRect.top TO rgnRect.bottom - 1 DO
		BEGIN

		MoveHands (TRUE);

		IF rgnMask <> NIL THEN
			maskPtr := rgnMask.NeedPtr (row - rgnRect.top,
										row - rgnRect.top, FALSE);

		src1Ptr := Ptr (ORD4 (src1Array.NeedPtr (row, row, FALSE)) +
							  rgnRect.left);

		IF src2Array <> NIL THEN
			BEGIN

			src2Ptr := Ptr (ORD4 (src2Array.NeedPtr (row, row, FALSE)) +
								  rgnRect.left);

			src3Ptr := Ptr (ORD4 (src3Array.NeedPtr (row, row, FALSE)) +
								  rgnRect.left);

			Do6DHistogram (src1Ptr,
						   src2Ptr,
						   src3Ptr,
						   maskPtr,
						   rgnRect.right - rgnRect.left,
						   @hists);

			src2Array.DoneWithPtr;
			src3Array.DoneWithPtr;

			src2Ptr := NIL;
			src3Ptr := NIL

			END

		ELSE
			DoHistBytes (src1Ptr,
						 maskPtr,
						 rgnRect.right - rgnRect.left,
						 hists [0]);

		IF rgnMask <> NIL THEN
			rgnMask.DoneWithPtr;

		src1Array.DoneWithPtr;

		src1Ptr := NIL;
		maskPtr := NIL

		END;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TWandSelector.BuildMap (hist: THistogram;
								  VAR map: TLookUpTable;
								  tolerance: INTEGER;
								  fuzziness: INTEGER);

	VAR
		gap: INTEGER;
		gray: INTEGER;
		fuzz: INTEGER;
		lower: INTEGER;
		upper: INTEGER;
		count: LONGINT;
		ignore: LONGINT;

	BEGIN

	count := 0;
	FOR gray := 0 TO 255 DO
		count := count + hist [gray];

	ignore := count * fIgnore DIV 100;

	count := 0;
	FOR lower := 0 TO 255 DO
		BEGIN
		count := count + hist [lower];
		IF count > ignore THEN LEAVE
		END;

	count := 0;
	FOR upper := 255 DOWNTO lower DO
		BEGIN
		count := count + hist [upper];
		IF count > ignore THEN LEAVE
		END;

	lower := lower - tolerance;
	upper := upper + tolerance;

	fuzz := fuzziness + 1;

	FOR gray := 0 TO 255 DO

		IF (gray >= lower) AND (gray <= upper) THEN
			map [gray] := CHR (127)

		ELSE
			BEGIN

			IF gray < lower THEN
				gap := lower - gray
			ELSE
				gap := gray - upper;

			IF gap >= fuzz THEN
				map [gray] := CHR (0)
			ELSE
				map [gray] := CHR (127 * (fuzz - gap) DIV fuzz)

			END

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TWandSelector.BuildMaps (rgnRect: Rect; rgnMask: TVMArray);

	VAR
		band: INTEGER;
		gray: INTEGER;
		index: INTEGER;
		hist: THistogram;
		map: TLookUpTable;
		hists: THistograms;
		tolerance: INTEGER;
		fuzziness: INTEGER;
		maps: TRGBLookUpTable;

	BEGIN

	IF fView.fChannel = kRGBChannels THEN
		BEGIN

		HistRegion (fDoc.fData [0],
					fDoc.fData [1],
					fDoc.fData [2],
					rgnRect,
					rgnMask,
					hists);

		FOR band := 0 TO 5 DO
			BEGIN

			IF band <= 2 THEN
				BEGIN
				tolerance := fTolerance;
				fuzziness := fFuzziness
				END
			ELSE
				BEGIN
				tolerance := fTolerance DIV 2;
				fuzziness := fFuzziness DIV 2
				END;

			{$H-}
			BuildMap (hists [band], fMap [band], tolerance, fuzziness)
			{$H+}

			END

		END

	ELSE
		BEGIN

		HistRegion (fDoc.fData [fView.fChannel],
					NIL,
					NIL,
					rgnRect,
					rgnMask,
					hists);

		IF fDoc.fMode = IndexedColorMode THEN
			BEGIN

			maps := fDoc.fIndexedColorTable;

			FOR band := 0 TO 5 DO
				BEGIN

				DoSetBytes (@hist, SIZEOF (THistogram), 0);

				FOR gray := 0 TO 255 DO
					BEGIN

						CASE band OF
						0:	index := ORD (maps.R [gray]);
						1:	index := ORD (maps.G [gray]);
						2:	index := ORD (maps.B [gray]);
						3:	index := BSR (ORD (maps.R [gray]) -
										  ORD (maps.G [gray]) + 256, 1);
						4:	index := BSR (ORD (maps.G [gray]) -
										  ORD (maps.B [gray]) + 256, 1);
						5:	index := BSR (ORD (maps.B [gray]) -
										  ORD (maps.R [gray]) + 256, 1)
						END;

					hist [index] := hist [index] + hists [0, gray]

					END;

				IF band <= 2 THEN
					BEGIN
					tolerance := fTolerance;
					fuzziness := fFuzziness
					END
				ELSE
					BEGIN
					tolerance := fTolerance DIV 2;
					fuzziness := fFuzziness DIV 2
					END;

				{$H-}
				BuildMap (hist, fMap [band], tolerance, fuzziness)
				{$H+}

				END;

			Do6DMinimum (@maps.R,
						 @maps.G,
						 @maps.B,
						 @map,
						 @fMap,
						 256);

			fMap [0] := map

			END

		ELSE
			{$H-}
			BuildMap (hists [0], fMap [0], fTolerance, fFuzziness)
			{$H+}

		END

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TWandSelector.PrepareLine (row: INTEGER);

	VAR
		fi: FailInfo;
		src1Ptr: Ptr;
		src2Ptr: Ptr;
		src3Ptr: Ptr;
		maskPtr: Ptr;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF src1Ptr <> NIL THEN fDoc.fData [0] . DoneWithPtr;
		IF src2Ptr <> NIL THEN fDoc.fData [1] . DoneWithPtr;
		IF src3Ptr <> NIL THEN fDoc.fData [2] . DoneWithPtr
		END;

	BEGIN

	MoveHands (TRUE);

	maskPtr := fMask.NeedPtr (row, row, TRUE);

	IF fView.fChannel = kRGBChannels THEN
		BEGIN

		src1Ptr := NIL;
		src2Ptr := NIL;
		src3Ptr := NIL;

		CatchFailures (fi, CleanUp);

		src1Ptr := fDoc.fData [0] . NeedPtr (row, row, FALSE);
		src2Ptr := fDoc.fData [1] . NeedPtr (row, row, FALSE);
		src3Ptr := fDoc.fData [2] . NeedPtr (row, row, FALSE);

		Do6DMinimum (src1Ptr,
					 src2Ptr,
					 src3Ptr,
					 maskPtr,
					 @fMap,
					 fDoc.fCols);

		Success (fi);

		CleanUp (0, 0)

		END

	ELSE
		BEGIN

		src1Ptr := fDoc.fData [fView.fChannel] . NeedPtr (row, row, FALSE);

		BlockMove (src1Ptr, maskPtr, fDoc.fCols);

		DoMapBytes (maskPtr, fDoc.fCols, fMap [0]);

		fDoc.fData [fView.fChannel] . DoneWithPtr

		END;

	fMask.DoneWithPtr

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TWandSelector.Grow4Connected (VAR lower: INTEGER;
										VAR upper: INTEGER;
										VAR r: Rect);

	VAR
		p: Ptr;
		row: INTEGER;
		pass: INTEGER;

	BEGIN

	pass := 0;

		REPEAT

		pass := pass + 1;

		FOR row := r.top TO fDoc.fRows - 1 DO
			BEGIN

			MoveHands (TRUE);

			IF row > upper THEN
				BEGIN
				PrepareLine (row);
				upper := row
				END;

			p := fMask.NeedPtr (row, row, TRUE);

			IF row <> r.top THEN
				IF ConnectDown (gBuffer, p, r.left, r.right) THEN
					BEGIN
					IF r.bottom <= row THEN
						r.bottom := row + 1;
					pass := 1
					END;

			IF row < r.bottom THEN
				IF ConnectAcross (p, fDoc.fCols, r.left, r.right) THEN
					pass := 1;

			BlockMove (Ptr (ORD4 (p) + r.left),
					   gBuffer,
					   r.right - r.left);

			fMask.DoneWithPtr;

			IF row = r.bottom THEN LEAVE

			END;

		IF pass = 2 THEN LEAVE;

		pass := pass + 1;

		FOR row := r.bottom - 1 DOWNTO 0 DO
			BEGIN

			MoveHands (TRUE);

			IF row < lower THEN
				BEGIN
				PrepareLine (row);
				lower := row
				END;

			p := fMask.NeedPtr (row, row, TRUE);

			IF row <> r.bottom - 1 THEN
				IF ConnectDown (gBuffer, p, r.left, r.right) THEN
					BEGIN
					IF r.top > row THEN
						r.top := row;
					pass := 1
					END;

			IF row >= r.top THEN
				IF ConnectAcross (p, fDoc.fCols, r.left, r.right) THEN
					pass := 1;

			BlockMove (Ptr (ORD4 (p) + r.left),
					   gBuffer,
					   r.right - r.left);

			fMask.DoneWithPtr;

			IF row = r.top - 1 THEN LEAVE

			END

		UNTIL pass = 2;

	fMask.Flush

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TWandSelector.DilateArea (r: Rect);

	VAR
		p: Ptr;
		row: INTEGER;
		width: INTEGER;

	BEGIN

	width := r.right - r.left;

	IF width > 1 THEN
		FOR row := r.top TO r.bottom - 1 DO
			BEGIN

			MoveHands (TRUE);

			p := Ptr (ORD4 (fMask.NeedPtr (row, row, TRUE)) + r.left);
			DilateAcross (p, width);
			fMask.DoneWithPtr

			END;

	FOR row := r.top TO r.bottom - 2 DO
		BEGIN

		MoveHands (TRUE);

		p := Ptr (ORD4 (fMask.NeedPtr (row + 1, row + 1, FALSE)) + r.left);
		BlockMove (p, gBuffer, width);
		fMask.DoneWithPtr;

		p := Ptr (ORD4 (fMask.NeedPtr (row, row, TRUE)) + r.left);
		DilateDown (gBuffer, p, width);
		fMask.DoneWithPtr

		END;

	FOR row := r.bottom - 1 DOWNTO r.top + 1 DO
		BEGIN

		MoveHands (TRUE);

		p := Ptr (ORD4 (fMask.NeedPtr (row - 1, row - 1, FALSE)) + r.left);
		BlockMove (p, gBuffer, width);
		fMask.DoneWithPtr;

		p := Ptr (ORD4 (fMask.NeedPtr (row, row, TRUE)) + r.left);
		DilateDown (gBuffer, p, width);
		fMask.DoneWithPtr

		END;

	fMask.Flush

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TWandSelector.MarkRegion (rgnRect: Rect; rgnMask: TVMArray);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF srcPtr <> NIL THEN rgnMask.DoneWithPtr;
		IF dstPtr <> NIL THEN fMask.DoneWithPtr;
		rgnMask.Flush;
		fMask.Flush
		END;

	BEGIN

	IF rgnMask = NIL THEN
		fMask.SetRect (rgnRect, 255)

	ELSE
		BEGIN

		srcPtr := NIL;
		dstPtr := NIL;

		CatchFailures (fi, CleanUp);

		FOR row := rgnRect.top TO rgnRect.bottom - 1 DO
			BEGIN

			MoveHands (TRUE);

			srcPtr := rgnMask.NeedPtr (row - rgnRect.top,
									   row - rgnRect.top, FALSE);

			dstPtr := Ptr (ORD4 (fMask.NeedPtr (row, row, TRUE)) +
						   rgnRect.left);

			DoMarkMasked (srcPtr, dstPtr, rgnRect.right - rgnRect.left);

			rgnMask.DoneWithPtr;
			fMask.DoneWithPtr;

			srcPtr := NIL;
			dstPtr := NIL

			END;

		Success (fi);

		CleanUp (0, 0)

		END

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TWandSelector.GrowRegion (rgnRect: Rect; rgnMask: TVMArray);

	VAR
		r: Rect;
		rr: Rect;
		fi: FailInfo;
		row: INTEGER;
		gray: INTEGER;
		lower: INTEGER;
		upper: INTEGER;
		map: TLookUpTable;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF fView.fChannel = kRGBChannels THEN
			BEGIN
			fDoc.fData [0] . Flush;
			fDoc.fData [1] . Flush;
			fDoc.fData [2] . Flush
			END
		ELSE
			fDoc.fData [fView.fChannel] . Flush
		END;

	BEGIN

	BuildMaps (rgnRect, rgnMask);

	fMask.SetBytes (0);

	CatchFailures (fi, CleanUp);

	IF fConnected THEN
		BEGIN
		lower := rgnRect.top;
		upper := rgnRect.bottom - 1
		END
	ELSE
		BEGIN
		lower := 0;
		upper := fDoc.fRows - 1
		END;

	FOR row := lower TO upper DO
		PrepareLine (row);

	MarkRegion (rgnRect, rgnMask);

	IF fConnected THEN
		r := rgnRect
	ELSE
		BEGIN
		map := gNullLUT;
		map [127] := CHR (255);
		fMask.MapBytes (map);
		fDoc.GetBoundsRect (r)
		END;

	Grow4Connected (lower, upper, r);

	Success (fi);

	CleanUp (0, 0);

	IF fFuzziness <> 0 THEN
		BEGIN
		InsetRect (r, -1, -1);
		fDoc.SectBoundsRect (r);
		DilateArea (r)
		END;

	FOR gray := 0 TO 255 DO
		IF gray <= 128 THEN
			map [gray] := CHR (0)
		ELSE
			map [gray] := CHR (gray * 2 - 255);

	rr.top	  := lower;
	rr.bottom := upper + 1;
	rr.left   := 0;
	rr.right  := fDoc.fCols;

	fMask.MapRect (rr, map);

	IF (fFuzziness <> 0) OR NOT fConnected THEN
		fMask.FindInnerBounds (r);

	fMaskBounds := r

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TWandSelector.GrowFromSeed (downPoint: Point);

	VAR
		r: Rect;
		pt: Point;
		radius: INTEGER;

	BEGIN

	pt := downPoint;

	fView.CvtView2Image (pt);

	pt.h := Max (0, Min (pt.h, fDoc.fCols - 1));
	pt.v := Max (0, Min (pt.v, fDoc.fRows - 1));

	r.topLeft := pt;
	r.bottom  := r.top + 1;
	r.right   := r.left + 1;

	IF (fView.fMagnification > 4) OR (fCmdNumber = cPaintBucket) THEN
		radius := 0
	ELSE IF fView.fMagnification > 1 THEN
		radius := 1
	ELSE
		radius := 2;

	InsetRect (r, -radius, -radius);

	fDoc.SectBoundsRect (r);

	GrowRegion (r, NIL)

	END;

{*****************************************************************************}

{$S ASelect}

FUNCTION TWandSelector.TrackMouse
		(aTrackPhase: TrackPhase;
		 VAR anchorPoint, previousPoint, nextPoint: Point;
		 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

	VAR
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Free;
		FailNewMessage (error, message, msgCannotWand)
		END;

	BEGIN

	TrackMouse := SELF;

	IF aTrackPhase = trackPress THEN
		BEGIN

		CatchFailures (fi, CleanUp);

		GrowFromSeed (nextPoint);

		UpdateSelection;

		Success (fi)

		END

	END;

{*****************************************************************************}

{$S ASelect}

FUNCTION DoWandTool (view: TImageView;
					 add: BOOLEAN;
					 remove: BOOLEAN;
					 refine: BOOLEAN): TCommand;

	VAR
		fi: FailInfo;
		doc: TImageDocument;
		aWandSelector: TWandSelector;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FailNewMessage (error, message, msgCannotWand)
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	doc := TImageDocument (view.fDocument);

	IF doc.fMode = HalftoneMode THEN Failure (errNoHalftone, 0);

	NEW (aWandSelector);
	FailNil (aWandSelector);

	aWandSelector.IWandSelector (cMagicWand, view, add, remove, refine);

	DoWandTool := aWandSelector;

	Success (fi)

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE DoWandOptions;

	CONST
		kDialogID	   = 1089;
		kHookItem	   = 3;
		kToleranceItem = 4;
		kFuzzinessItem = 5;

	VAR
		fi: FailInfo;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		toleranceText: TFixedText;
		fuzzinessText: TFixedText;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	toleranceText := aBWDialog.DefineFixedText
					 (kToleranceItem, 0, TRUE, TRUE, 0, 255);

	toleranceText.StuffValue (gWandTolerance);

	fuzzinessText := aBWDialog.DefineFixedText
					 (kFuzzinessItem, 0, TRUE, TRUE, 0, 255);

	fuzzinessText.StuffValue (gWandFuzziness);

	aBWDialog.SetEditSelection (kToleranceItem);

	aBWDialog.TalkToUser (hitItem, StdItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	gWandTolerance := toleranceText.fValue;
	gWandFuzziness := fuzzinessText.fValue;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TBucketTool.IBucketTool (view: TImageView; refine: BOOLEAN);

	BEGIN

	IWandSelector (cPaintBucket, view, FALSE, FALSE, refine);

	fCausesChange := TRUE;

	fTolerance := gBucketTolerance;
	fFuzziness := gBucketFuzziness

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TBucketTool.FillMaskedArea;

	VAR
		r: Rect;
		width: INTEGER;
		height: INTEGER;
		channel: INTEGER;
		channels: INTEGER;
		aVMArray: TVMArray;

	BEGIN

	r := fMaskBounds;

	width  := r.right - r.left;
	height := r.bottom - r.top;

	fFloatMask := fMask.CopyRect (r, 1);

	fMask.Free;
	fMask := NIL;

	IF fView.fChannel = kRGBChannels THEN
		channels := 3
	ELSE
		channels := 1;

	FOR channel := 0 TO channels - 1 DO
		BEGIN
		aVMArray := NewVMArray (height, width, 1);
		fFloatBelow [channel] := aVMArray
		END;

	FOR channel := 0 TO channels - 1 DO
		BEGIN
		aVMArray := NewVMArray (height, width, channels - channel);
		fFloatData [channel] := aVMArray;
		aVMArray.SetBytes (fView.ForegroundByte (channel))
		END;

	fFloatRect	:= r;
	fExactFloat := FALSE;

	MoveHands (TRUE);

	gApplication.CommitLastCommand;

	fDoc.FreeFloat;

	fDoc.fSelectionFloating := FALSE;
	fDoc.fFloatCommand		:= SELF;
	fDoc.fFloatChannel		:= fView.fChannel;

	SwapFloat;

	CopyBelow (TRUE);

	BlendFloat (FALSE);

	fDoc.UpdateImageArea (r, TRUE, TRUE, fDoc.fFloatChannel)

	END;

{*****************************************************************************}

{$S ASelect}

FUNCTION TBucketTool.TrackMouse
		(aTrackPhase: TrackPhase;
		 VAR anchorPoint, previousPoint, nextPoint: Point;
		 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

	VAR
		r: Rect;
		fi: FailInfo;
		ignore: Rect;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Free;
		FailNewMessage (error, message, msgCannotBucket)
		END;

	BEGIN

	TrackMouse := SELF;

	IF aTrackPhase = trackPress THEN
		BEGIN

		CatchFailures (fi, CleanUp);

		GrowFromSeed (nextPoint);

		IF fRefine THEN
			BEGIN
			r := fDoc.fSelectionRect;
			CombineMask (r, fDoc.fSelectionMask, ignore)
			END;

		MoveHands (TRUE);

		IF EmptyRect (fMaskBounds) THEN Failure (0, 0);

		FillMaskedArea;

		Success (fi)

		END

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TBucketTool.UndoIt; OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	CopyBelow (FALSE);

	ComputeOverlap (r);
	fDoc.UpdateImageArea (r, TRUE, TRUE, fDoc.fFloatChannel)

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TBucketTool.RedoIt; OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	BlendFloat (FALSE);

	ComputeOverlap (r);
	fDoc.UpdateImageArea (r, TRUE, TRUE, fDoc.fFloatChannel)

	END;

{*****************************************************************************}

{$S ASelect}

FUNCTION DoBucketTool (view: TImageView): TCommand;

	VAR
		fi: FailInfo;
		doc: TImageDocument;
		aBucketTool: TBucketTool;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FailNewMessage (error, message, msgCannotBucket)
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	doc := TImageDocument (view.fDocument);

	IF doc.fMode = HalftoneMode THEN Failure (errNoHalftone, 0);

	NEW (aBucketTool);
	FailNil (aBucketTool);

	aBucketTool.IBucketTool (view, NOT EmptyRect (doc.fSelectionRect));

	DoBucketTool := aBucketTool;

	Success (fi)

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE DoBucketOptions;

	CONST
		kDialogID	   = 1090;
		kHookItem	   = 3;
		kToleranceItem = 4;
		kFuzzinessItem = 5;

	VAR
		fi: FailInfo;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		toleranceText: TFixedText;
		fuzzinessText: TFixedText;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	toleranceText := aBWDialog.DefineFixedText
					 (kToleranceItem, 0, TRUE, TRUE, 0, 255);

	toleranceText.StuffValue (gBucketTolerance);

	fuzzinessText := aBWDialog.DefineFixedText
					 (kFuzzinessItem, 0, TRUE, TRUE, 0, 255);

	fuzzinessText.StuffValue (gBucketFuzziness);

	aBWDialog.SetEditSelection (kToleranceItem);

	aBWDialog.TalkToUser (hitItem, StdItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	gBucketTolerance := toleranceText.fValue;
	gBucketFuzziness := fuzzinessText.fValue;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TGrowCommand.IGrowCommand (view: TImageView; connected: BOOLEAN);

	VAR
		itsCommand: INTEGER;

	BEGIN

	IF connected THEN
		itsCommand := cGrow
	ELSE
		itsCommand := cSelectSimilar;

	IWandSelector (itsCommand, view, FALSE, FALSE, FALSE);

	fIgnore    := 10;
	fConnected := connected

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TGrowCommand.DoIt; OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	r := fDoc.fSelectionRect;
	GrowRegion (r, fDoc.fSelectionMask);

	UpdateSelection

	END;

{*****************************************************************************}

{$S ASelect}

FUNCTION DoGrowCommand (view: TImageView; connected: BOOLEAN): TCommand;

	VAR
		aGrowCommand: TGrowCommand;

	BEGIN

	NEW (aGrowCommand);
	FailNil (aGrowCommand);

	aGrowCommand.IGrowCommand (view, connected);

	DoGrowCommand := aGrowCommand

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE THandTool.IHandTool (view: TImageView);

	BEGIN

	fView := view;

	ICommand (cMouseCommand);

	fAutoScroll := FALSE

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE THandTool.TrackFeedBack
		(anchorPoint, nextPoint: Point;
		 turnItOn, mouseDidMove: BOOLEAN); OVERRIDE;

	BEGIN
	END;

{*****************************************************************************}

{$S ASelect}

FUNCTION THandTool.TrackMouse
		(aTrackPhase: TrackPhase;
		 VAR anchorPoint, previousPoint, nextPoint: Point;
		 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

	VAR
		delta: Point;

	BEGIN

	IF aTrackPhase = trackRelease THEN
		TrackMouse := gNoChanges
	ELSE
		TrackMouse := SELF;

	delta.h := anchorPoint.h - nextPoint.h;
	delta.v := anchorPoint.v - nextPoint.v;

	fView.fFrame.ScrollBy (delta, FALSE)

	END;

{*****************************************************************************}

{$S ASelect}

FUNCTION DoHandTool (view: TImageView): TCommand;

	VAR
		aHandTool: THandTool;

	BEGIN

	NEW (aHandTool);
	FailNil (aHandTool);

	aHandTool.IHandTool (view);

	DoHandTool := aHandTool

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE CopyAlphaChannel (doc: TImageDocument; buffer: TVMArray);

	VAR
		r: Rect;
		r1: Rect;
		row: INTEGER;

	BEGIN

	buffer.SetBytes (0);

	r := doc.fSelectionRect;

	IF doc.fSelectionMask <> NIL THEN
		BEGIN

		r1 := r;
		OffsetRect (r1, -r1.left, -r1.top);

		doc.fSelectionMask.MoveRect (buffer, r1, r)

		END

	ELSE
		BEGIN

		FOR row := r.top TO r.bottom - 1 DO
			BEGIN

			DoSetBytes (Ptr (ORD4 (buffer.NeedPtr (row, row, TRUE)) + r.left),
						r.right - r.left,
						255);

			buffer.DoneWithPtr

			END;

		buffer.Flush

		END

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TSelectInverse.ISelectInverse (view: TImageView);

	BEGIN
	IMaskCommand (cSelectInverse, view, FALSE, FALSE, FALSE,
				  FALSE, TRUE, FALSE)
	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TSelectInverse.DoIt; OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	MoveHands (TRUE);

	CopyAlphaChannel (fDoc, fMask);

	fMask.MapBytes (gInvertLUT);

	fMask.FindBounds (r);
	fMaskBounds := r;

	MoveHands (TRUE);

	UpdateSelection

	END;

{*****************************************************************************}

{$S ASelect}

FUNCTION DoSelectInverse (view: TImageView): TCommand;

	VAR
		aSelectInverse: TSelectInverse;

	BEGIN

	NEW (aSelectInverse);
	FailNil (aSelectInverse);

	aSelectInverse.ISelectInverse (view);

	DoSelectInverse := aSelectInverse

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TSelectFringe.ISelectFringe (view: TImageView);

	BEGIN
	IMaskCommand (cSelectFringe2, view, FALSE, FALSE, FALSE,
				  FALSE, TRUE, FALSE)
	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE FindTaxiCab (buffer: TVMArray; r: Rect; block: INTEGER);

	VAR
		row: INTEGER;
		dataPtr: Ptr;
		gray: INTEGER;
		width: INTEGER;
		map: TLookUpTable;

	BEGIN

	FOR gray := 0 TO block - 1 DO
		map [gray] := CHR (0);

	FOR gray := block TO 255 DO
		map [gray] := CHR (gray - block);

	width := r.right - r.left;

	DoSetBytes (gBuffer, width, 0);

	StartTask (0.7);

	FOR row := r.top TO r.bottom - 1 DO
		BEGIN

		UpdateProgress (row, r.bottom - r.top);

		dataPtr := Ptr (ORD4 (buffer.NeedPtr (row, row, TRUE)) + r.left);

		DoTaxiCab (dataPtr, 1, width, block);
		DoTaxiCab (Ptr (ORD4 (dataPtr) + width - 1), -1, width, block);

		DoMaxBytes (gBuffer, dataPtr, dataPtr, width);
		BlockMove (dataPtr, gBuffer, width);
		DoMapBytes (gBuffer, width, map);

		buffer.DoneWithPtr;

		MoveHands (TRUE)

		END;

	FinishTask;

	FOR row := r.bottom - 2 DOWNTO r.top DO
		BEGIN

		UpdateProgress (r.bottom - 2 - row, r.bottom - r.top - 1);

		dataPtr := Ptr (ORD4 (buffer.NeedPtr (row, row, TRUE)) + r.left);

		DoMaxBytes (gBuffer, dataPtr, dataPtr, width);
		BlockMove (dataPtr, gBuffer, width);
		DoMapBytes (gBuffer, width, map);

		buffer.DoneWithPtr;

		MoveHands (TRUE)

		END;

	UpdateProgress (1, 1);

	buffer.Flush

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TSelectFringe.DoIt; OVERRIDE;

	VAR
		r: Rect;
		rr: Rect;
		fi: FailInfo;
		which: INTEGER;
		block: INTEGER;
		radius: INTEGER;
		buffer: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress;
		buffer.Free
		END;

	BEGIN

	MoveHands (TRUE);

	CopyAlphaChannel (fDoc, fMask);

	r := fDoc.fSelectionRect;
	InsetRect (r, -1, -1);
	fDoc.SectBoundsRect (r);

	buffer := NewVMArray (r.bottom - r.top, r.right - r.left, 1);

	CommandProgress (fCmdNumber);

	CatchFailures (fi, CleanUp);

	IF ODD (gFringeWidth) THEN
		which := cSelectFringeNarrow
	ELSE
		which := cSelectFringeWide;

	StartTask (0.5);
	Do3by3Filter (fMask, buffer, r, which);
	FinishTask;

	rr := r;
	OffsetRect (rr, -rr.left, -rr.top);

	buffer.MoveRect (fMask, rr, r);

	block := 127 DIV BSR (gFringeWidth + 1, 1) + 1;

	radius := (254 + block) DIV block;

	InsetRect (r, -radius, -radius);
	fDoc.SectBoundsRect (r);

	FindTaxiCab (fMask, r, block);

	fMask.FindBounds (r);
	fMaskBounds := r;

	Success (fi);

	CleanUp (0, 0);

	MoveHands (TRUE);

	UpdateSelection

	END;

{*****************************************************************************}

{$S ASelect}

FUNCTION DoSelectFringe (view: TImageView): TCommand;

	CONST
		kDialogID  = 1007;
		kHookItem  = 3;
		kWidthItem = 4;

	VAR
		fi: FailInfo;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		widthText: TFixedText;
		aSelectFringe: TSelectFringe;

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
				 (kWidthItem, 0, FALSE, TRUE, 1, 64);

	widthText.StuffValue (gFringeWidth);

	aBWDialog.SetEditSelection (kWidthItem);

	aBWDialog.TalkToUser (hitItem, StdItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	gFringeWidth := widthText.fValue;

	Success (fi);

	CleanUp (0, 0);

	NEW (aSelectFringe);
	FailNil (aSelectFringe);

	aSelectFringe.ISelectFringe (view);

	DoSelectFringe := aSelectFringe

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TFeatherCommand.IFeatherCommand (view: TImageView);

	BEGIN
	IMaskCommand (cFeather2, view, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE)
	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TFeatherCommand.DoIt; OVERRIDE;

	VAR
		r: Rect;
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress
		END;

	BEGIN

	MoveHands (TRUE);

	CommandProgress (fCmdNumber);

	CatchFailures (fi, CleanUp);

	CopyAlphaChannel (fDoc, fMask);

	r := fDoc.fSelectionRect;
	GaussianFilter (fMask, r, gFeatherRadius, TRUE, TRUE);

	fMask.FindInnerBounds (r);
	fMaskBounds := r;

	MoveHands (TRUE);

	Success (fi);

	CleanUp (0, 0);

	UpdateSelection

	END;

{*****************************************************************************}

{$S ASelect}

FUNCTION DoFeatherCommand (view: TImageView): TCommand;

	CONST
		kDialogID	= 1004;
		kHookItem	= 3;
		kRadiusItem = 4;

	VAR
		fi: FailInfo;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		radiusText: TFixedText;
		aFeatherCommand: TFeatherCommand;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	radiusText := aBWDialog.DefineFixedText
				  (kRadiusItem, 0, FALSE, TRUE, 1, 64);

	radiusText.StuffValue (gFeatherRadius DIV 10);

	aBWDialog.SetEditSelection (kRadiusItem);

	aBWDialog.TalkToUser (hitItem, StdItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	gFeatherRadius := radiusText.fValue * 10;

	Success (fi);

	CleanUp (0, 0);

	NEW (aFeatherCommand);
	FailNil (aFeatherCommand);

	aFeatherCommand.IFeatherCommand (view);

	DoFeatherCommand := aFeatherCommand

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TDefringeCommand.IDefringeCommand
		(view: TImageView; width: INTEGER);

	BEGIN

	fWidth := width;

	IFloatCommand (cDefringe2, view);

	fChannel := view.fChannel

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TDefringeCommand.DefringeData (maskArray: TVMArray;
										 dst1Array: TVMArray;
										 dst2Array: TVMArray;
										 dst3Array: TVMArray);

	VAR
		fi: FailInfo;
		row: INTEGER;
		bounds: Rect;
		maskPtr: Ptr;
		dst1Ptr: Ptr;
		dst2Ptr: Ptr;
		dst3Ptr: Ptr;
		width: INTEGER;
		buffer0: Handle;
		buffer1: Handle;
		buffer2: Handle;
		buffer3: Handle;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (buffer0);
		FreeLargeHandle (buffer1);
		FreeLargeHandle (buffer2);
		FreeLargeHandle (buffer3)
		END;

	BEGIN

	maskArray.FindBounds (bounds);

	IF EmptyRect (bounds) THEN
		Failure (errNoCorePixels, 0);

	width := maskArray.fLogicalSize;

	buffer0 := NIL;
	buffer1 := NIL;
	buffer2 := NIL;
	buffer3 := NIL;

	CatchFailures (fi, CleanUp);

	buffer0 := NewLargeHandle (width);
	buffer1 := NewLargeHandle (width);
	buffer2 := NewLargeHandle (width);
	buffer3 := NewLargeHandle (width);

	StartTask (1/3);

	FOR row := bounds.top TO bounds.bottom - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row - bounds.top, bounds.bottom - bounds.top);

		maskPtr := maskArray.NeedPtr (row, row, TRUE);
		dst1Ptr := dst1Array.NeedPtr (row, row, TRUE);

		IF dst2Array <> NIL THEN
			BEGIN

			dst2Ptr := dst2Array.NeedPtr (row, row, TRUE);
			dst3Ptr := dst3Array.NeedPtr (row, row, TRUE);

			DefringeAcross (Ptr (ORD4 (maskPtr) + bounds.left),
							Ptr (ORD4 (dst2Ptr) + bounds.left),
							width - bounds.left,
							1,
							FALSE);

			DefringeAcross (Ptr (ORD4 (maskPtr) + bounds.left),
							Ptr (ORD4 (dst3Ptr) + bounds.left),
							width - bounds.left,
							1,
							FALSE);

			END;

		DefringeAcross (Ptr (ORD4 (maskPtr) + bounds.left),
						Ptr (ORD4 (dst1Ptr) + bounds.left),
						width - bounds.left,
						1,
						TRUE);

		IF dst2Array <> NIL THEN
			BEGIN

			DefringeAcross (Ptr (ORD4 (maskPtr) + bounds.right - 1),
							Ptr (ORD4 (dst2Ptr) + bounds.right - 1),
							bounds.right,
							-1,
							FALSE);

			DefringeAcross (Ptr (ORD4 (maskPtr) + bounds.right - 1),
							Ptr (ORD4 (dst3Ptr) + bounds.right - 1),
							bounds.right,
							-1,
							FALSE);

			IF row = bounds.top THEN
				BEGIN
				BlockMove (dst2Ptr, buffer2^, width);
				BlockMove (dst3Ptr, buffer3^, width)
				END;

			dst2Array.DoneWithPtr;
			dst3Array.DoneWithPtr

			END;

		DefringeAcross (Ptr (ORD4 (maskPtr) + bounds.right - 1),
						Ptr (ORD4 (dst1Ptr) + bounds.right - 1),
						bounds.right,
						-1,
						TRUE);

		IF row = bounds.top THEN
			BEGIN
			BlockMove (maskPtr, buffer0^, width);
			BlockMove (dst1Ptr, buffer1^, width)
			END;

		dst1Array.DoneWithPtr;
		maskArray.DoneWithPtr

		END;

	FinishTask;

	StartTask (1/2);

	FOR row := bounds.top + 1 TO maskArray.fBlockCount - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row - bounds.top, maskArray.fBlockCount - bounds.top);

		maskPtr := maskArray.NeedPtr (row, row, TRUE);
		dst1Ptr := dst1Array.NeedPtr (row, row, TRUE);

		IF dst2Array <> NIL THEN
			BEGIN

			dst2Ptr := dst2Array.NeedPtr (row, row, TRUE);
			dst3Ptr := dst3Array.NeedPtr (row, row, TRUE);

			DefringeDown (buffer0^, buffer2^, maskPtr, dst2Ptr, width, FALSE);
			DefringeDown (buffer0^, buffer3^, maskPtr, dst3Ptr, width, FALSE);

			BlockMove (dst2Ptr, buffer2^, width);
			BlockMove (dst3Ptr, buffer3^, width);

			dst2Array.DoneWithPtr;
			dst3Array.DoneWithPtr

			END;

		DefringeDown (buffer0^, buffer1^, maskPtr, dst1Ptr, width, TRUE);

		BlockMove (dst1Ptr, buffer1^, width);
		BlockMove (maskPtr, buffer0^, width);

		dst1Array.DoneWithPtr;
		maskArray.DoneWithPtr

		END;

	FinishTask;

	FOR row := maskArray.fBlockCount - 2 DOWNTO 0 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (maskArray.fBlockCount - row, maskArray.fBlockCount);

		maskPtr := maskArray.NeedPtr (row, row, TRUE);
		dst1Ptr := dst1Array.NeedPtr (row, row, TRUE);

		IF dst2Array <> NIL THEN
			BEGIN

			dst2Ptr := dst2Array.NeedPtr (row, row, TRUE);
			dst3Ptr := dst3Array.NeedPtr (row, row, TRUE);

			DefringeDown (buffer0^, buffer2^, maskPtr, dst2Ptr, width, FALSE);
			DefringeDown (buffer0^, buffer3^, maskPtr, dst3Ptr, width, FALSE);

			BlockMove (dst2Ptr, buffer2^, width);
			BlockMove (dst3Ptr, buffer3^, width);

			dst2Array.DoneWithPtr;
			dst3Array.DoneWithPtr

			END;

		DefringeDown (buffer0^, buffer1^, maskPtr, dst1Ptr, width, TRUE);

		BlockMove (dst1Ptr, buffer1^, width);
		BlockMove (maskPtr, buffer0^, width);

		dst1Array.DoneWithPtr;
		maskArray.DoneWithPtr

		END;

	Success (fi);

	CleanUp (0, 0);

	maskArray.Flush;
	dst1Array.Flush;

	IF dst2Array <> NIL THEN
		BEGIN
		dst2Array.Flush;
		dst3Array.Flush
		END

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TDefringeCommand.DoIt; OVERRIDE;

	VAR
		r: Rect;
		rr: Rect;
		fi: FailInfo;
		gray: INTEGER;
		channel: INTEGER;
		map: TLookUpTable;
		aVMArray: TVMArray;
		bVMArray: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress;
		FreeObject (aVMArray)
		END;

	BEGIN

	MoveHands (TRUE);

	aVMArray := NIL;

	CommandProgress (fCmdNumber);

	CatchFailures (fi, CleanUp);

	IF fWasFloating THEN
		BEGIN

		r := fDoc.fFloatRect;
		OffsetRect (r, -r.left, -r.top);

		aVMArray := NewVMArray (r.bottom + 2, r.right + 2, 1);

		aVMArray.SetBytes (0);

		rr := r;
		OffsetRect (rr, 1, 1);

		IF fDoc.fFloatMask <> NIL THEN
			fDoc.fFloatMask.MoveRect (aVMArray, r, rr)
		ELSE
			aVMArray.SetRect (rr, 255);

		InsetRect (rr, -1, -1)

		END

	ELSE
		BEGIN

		aVMArray := NewVMArray (fDoc.fRows, fDoc.fCols, 1);

		aVMArray.SetBytes (0);

		rr := fDoc.fSelectionRect;

		r := rr;
		OffsetRect (r, -r.left, -r.top);

		IF fDoc.fSelectionMask <> NIL THEN
			fDoc.fSelectionMask.MoveRect (aVMArray, r, rr)
		ELSE
			aVMArray.SetRect (rr, 255);

		InsetRect (rr, -1, -1);

		fDoc.SectBoundsRect (rr)

		END;

	MoveHands (TRUE);

	FOR gray := 0 TO 255 DO
		IF gray >= 128 THEN
			map [gray] := CHR (0)
		ELSE
			map [gray] := CHR (255);

	aVMArray.MapRect (rr, map);

	StartTask (1/10);
	FindTaxiCab (aVMArray, rr, 1);
	FinishTask;

	FOR gray := 0 TO 255 DO
		IF gray >= 255 - fWidth THEN
			map [gray] := CHR (0)
		ELSE
			map [gray] := CHR (255);

	aVMArray.MapRect (rr, map);

	MoveHands (TRUE);

	IF fWasFloating THEN
		BEGIN

		InsetRect (rr, 1, 1);

		bVMArray := aVMArray.CopyRect (rr, 1);

		aVMArray.Free;

		aVMArray := bVMArray;

		IF fChannel = kRGBChannels THEN
			FOR channel := 0 TO 2 DO
				BEGIN
				bVMArray := fDoc.fFloatData [channel] . CopyArray (1);
				fFloatData [channel] := bVMArray
				END
		ELSE
			BEGIN
			bVMArray := fDoc.fFloatData [0] . CopyArray (1);
			fFloatData [0] := bVMArray
			END;

		DefringeData (aVMArray, fFloatData [0],
								fFloatData [1],
								fFloatData [2]);

		FloatSelection (FALSE);

		fExactFloat := FALSE;

		fFloatRect := fDoc.fFloatRect

		END

	ELSE
		BEGIN

		IF fChannel = kRGBChannels THEN
			FOR channel := 0 TO 2 DO
				BEGIN
				bVMArray := fDoc.fData [channel] . CopyArray (3 - channel);
				fBuffer [channel] := bVMArray
				END
		ELSE
			BEGIN
			bVMArray := fDoc.fData [fChannel] . CopyArray (1);
			fBuffer [0] := bVMArray
			END;

		DefringeData (aVMArray, fBuffer [0],
								fBuffer [1],
								fBuffer [2])

		END;

	Success (fi);

	CleanUp (0, 0);

	UndoIt

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TDefringeCommand.UndoIt; OVERRIDE;

	VAR
		area: Rect;
		channel: INTEGER;
		saveArray: TVMArray;

	BEGIN

	IF fWasFloating THEN
		BEGIN

		IF NOT fDoc.fSelectionFloating THEN
			fDoc.DeSelect (TRUE);

		SwapFloat;

		CopyBelow (FALSE);

		BlendFloat (FALSE);

		ComputeOverlap (area);

		fDoc.UpdateImageArea (area, TRUE, TRUE, fDoc.fFloatChannel);

		IF NOT fDoc.fSelectionFloating THEN
			SelectFloat

		END

	ELSE
		BEGIN

		IF fChannel = kRGBChannels THEN
			FOR channel := 0 TO 2 DO
				BEGIN
				saveArray			 := fBuffer [channel];
				fBuffer [channel]	 := fDoc.fData [channel];
				fDoc.fData [channel] := saveArray
				END
		ELSE
			BEGIN
			saveArray			  := fBuffer [0];
			fBuffer [0] 		  := fDoc.fData [fChannel];
			fDoc.fData [fChannel] := saveArray
			END;

		fDoc.GetBoundsRect (area);

		fDoc.UpdateImageArea (area, TRUE, TRUE, fChannel)

		END

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TDefringeCommand.RedoIt; OVERRIDE;

	BEGIN
	UndoIt
	END;

{*****************************************************************************}

{$S ASelect}

FUNCTION DoDefringeCommand (view: TImageView): TCommand;

	CONST
		kDialogID  = 1014;
		kHookItem  = 3;
		kWidthItem = 4;

	VAR
		fi: FailInfo;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		widthText: TFixedText;
		aDefringeCommand: TDefringeCommand;

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
				 (kWidthItem, 0, FALSE, TRUE, 0, 64);

	widthText.StuffValue (gDefringeWidth);

	aBWDialog.SetEditSelection (kWidthItem);

	aBWDialog.TalkToUser (hitItem, StdItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	gDefringeWidth := widthText.fValue;

	Success (fi);

	CleanUp (0, 0);

	NEW (aDefringeCommand);
	FailNil (aDefringeCommand);

	aDefringeCommand.IDefringeCommand (view, gDefringeWidth);

	DoDefringeCommand := aDefringeCommand

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TMakeAlphaCommand.IMakeAlphaCommand (view: TImageView);

	BEGIN

	IBufferCommand (cMakeAlpha, view);

	fSolid := (fDoc.fSelectionMask = NIL)

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TMakeAlphaCommand.DoIt; OVERRIDE;

	VAR
		aVMArray: TVMArray;

	BEGIN

	MoveHands (TRUE);

	aVMArray := NewVMArray (fDoc.fRows, fDoc.fCols, 1);
	fBuffer [0] := aVMArray;

	CopyAlphaChannel (fDoc, aVMArray);

	MoveHands (TRUE);

	RedoIt

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TMakeAlphaCommand.UndoIt; OVERRIDE;

	VAR
		r: Rect;

	PROCEDURE DoUpdateView (view: TImageView);

		BEGIN

		IF view.fChannel = fDoc.fChannels THEN
			BEGIN

			IF fDoc.fMode = RGBColorMode THEN
				view.fChannel := kRGBChannels
			ELSE
				view.fChannel := 0;

			view.ReDither (TRUE)

			END;

		view.UpdateWindowTitle

		END;

	BEGIN

	fDoc.fChannels := fDoc.fChannels - 1;

	fBuffer [0] := fDoc.fData [fDoc.fChannels];
	fDoc.fData [fDoc.fChannels] := NIL;

	IF (fDoc.fMode = MultichannelMode) AND (fDoc.fChannels < 2) THEN
		fDoc.fMode := MonochromeMode;

	fDoc.fViewList.Each (DoUpdateView);

	fDoc.UpdateStatus;

	fBuffer [0] . FindBounds (r);

	IF fSolid THEN
		fDoc.Select (r, NIL)
	ELSE
		fDoc.Select (r, fBuffer [0] . CopyRect (r, 1))

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TMakeAlphaCommand.RedoIt; OVERRIDE;

	VAR
		front: TImageView;

	PROCEDURE DoUpdateTitle (view: TImageView);
		BEGIN
		view.UpdateWindowTitle
		END;

	BEGIN

	fDoc.DeSelect (FALSE);

	front := TImageView (gTarget);

	front.fChannel := fDoc.fChannels;

	fDoc.fChannels := fDoc.fChannels + 1;

	fDoc.fData [front.fChannel] := fBuffer [0];
	fBuffer [0] := NIL;

	IF fDoc.fMode = MonochromeMode THEN
		BEGIN
		fDoc.fMode := MultichannelMode;
		fDoc.fViewList.Each (DoUpdateTitle)
		END
	ELSE
		front.UpdateWindowTitle;

	fDoc.UpdateStatus;

	front.ReDither (TRUE)

	END;

{*****************************************************************************}

{$S ASelect}

FUNCTION DoMakeAlphaCommand (view: TImageView): TCommand;

	VAR
		aMakeAlphaCommand: TMakeAlphaCommand;

	BEGIN

	NEW (aMakeAlphaCommand);
	FailNil (aMakeAlphaCommand);

	aMakeAlphaCommand.IMakeAlphaCommand (view);

	DoMakeAlphaCommand := aMakeAlphaCommand

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TSelectAlphaCommand.ISelectAlphaCommand (view: TImageView);

	BEGIN

	IBufferCommand (cSelectAlpha, view);

	fCausesChange := FALSE;

		CASE fDoc.fMode OF

		MultichannelMode:
			fChannel := 1;

		SeparationsCMYK:
			fChannel := 4;

		OTHERWISE
			fChannel := 3

		END;

	fChannel := Max (fChannel, view.fChannel)

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TSelectAlphaCommand.DoIt; OVERRIDE;

	BEGIN

	fOldRect := fDoc.fSelectionRect;

	IF fDoc.fSelectionMask <> NIL THEN
		fBuffer [0] := fDoc.fSelectionMask.CopyArray (1);

	RedoIt

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TSelectAlphaCommand.UndoIt; OVERRIDE;

	VAR
		r: Rect;
		mask: TVMArray;

	BEGIN

	r := fOldRect;

	IF EmptyRect (r) THEN
		fDoc.DeSelect (TRUE)

	ELSE IF fBuffer [0] <> NIL THEN
		BEGIN
		mask := fBuffer [0] . CopyArray (1);
		fDoc.Select (r, mask)
		END

	ELSE
		fDoc.Select (r, NIL)

	END;

{*****************************************************************************}

{$S ASelect}

PROCEDURE TSelectAlphaCommand.RedoIt; OVERRIDE;

	VAR
		r: Rect;
		gray: INTEGER;
		hist: THistogram;
		view: TImageView;

	BEGIN

	MoveHands (TRUE);

	fDoc.fData [fChannel] . FindBounds (r);

	IF NOT EmptyRect (r) THEN
		BEGIN

		fDoc.fData [fChannel] . HistRect (r, hist);

		gray := 255;

		WHILE hist [gray] = 0 DO
			gray := gray - 1;

		IF gray < 128 THEN
			r := gZeroRect

		END;

	IF EmptyRect (r) THEN
		Failure (errNoPixels, msgCannotSelect);

	MoveHands (TRUE);

	view := TImageView (gTarget);

	IF view.fChannel = fChannel THEN
		BEGIN

			CASE fDoc.fMode OF

			RGBColorMode:
				view.fChannel := kRGBChannels;

			SeparationsCMYK:
				view.fChannel := 3;

			SeparationsHSL,
			SeparationsHSB:
				view.fChannel := 2;

			OTHERWISE
				view.fChannel := 0

			END;

		fDoc.DeSelect (FALSE);

		view.ReDither (TRUE);
		view.UpdateWindowTitle;

		view.ObscureSelection (0)

		END;

	IF hist [255] = ORD4 (r.bottom - r.top) * (r.right - r.left) THEN
		fDoc.Select (r, NIL)
	ELSE
		fDoc.Select (r, fDoc.fData [fChannel] . CopyRect (r, 1))

	END;

{*****************************************************************************}

{$S ASelect}

FUNCTION DoSelectAlphaCommand (view: TImageView): TCommand;

	VAR
		aSelectAlphaCommand: TSelectAlphaCommand;

	BEGIN

	NEW (aSelectAlphaCommand);
	FailNil (aSelectAlphaCommand);

	aSelectAlphaCommand.ISelectAlphaCommand (view);

	DoSelectAlphaCommand := aSelectAlphaCommand

	END;

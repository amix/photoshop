{Photoshop version 1.0.1, file: UCrop.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UCrop;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UBWDialog, UCommands, UGhost, USelect, UProgress;

TYPE

	TRectOptions = RECORD
		mode  : INTEGER;
		size  : Point;
		ratioH: LONGINT;
		ratioV: LONGINT
		END;

	TMarqueeSelector = OBJECT (TMaskCommand)

		fLastRect: Rect;
		fNextRect: Rect;

		fMovedOnce: BOOLEAN;

		fFlickerTime: LONGINT;
		fFlickerState: INTEGER;

		fOptions: TRectOptions;

		PROCEDURE TMarqueeSelector.IMarqueeSelector
				(itsCommand: INTEGER; view: TImageView;
				 add, remove, refine: BOOLEAN);

		PROCEDURE TMarqueeSelector.CompNextRect (corner1, corner2: Point);

		PROCEDURE TMarqueeSelector.TrackConstrain
				(anchorPoint, previousPoint: Point;
				 VAR nextPoint: Point); OVERRIDE;

		PROCEDURE TMarqueeSelector.DrawShape (r: Rect);

		PROCEDURE TMarqueeSelector.TrackFeedBack
				(anchorPoint, nextPoint: Point;
				 turnItOn, mouseDidMove: BOOLEAN); OVERRIDE;

		PROCEDURE TMarqueeSelector.FillShape (r: Rect);

		PROCEDURE TMarqueeSelector.SelectShape;

		FUNCTION TMarqueeSelector.TrackMouse
				(aTrackPhase: TrackPhase;
				 VAR anchorPoint, previousPoint, nextPoint: Point;
				 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

		END;

	TEllipseSelector = OBJECT (TMarqueeSelector)

		PROCEDURE TEllipseSelector.IEllipseSelector
				(view: TImageView; add, remove, refine: BOOLEAN);

		PROCEDURE TEllipseSelector.DrawShape (r: Rect); OVERRIDE;

		PROCEDURE TEllipseSelector.FillShape (r: Rect); OVERRIDE;

		PROCEDURE TEllipseSelector.SelectShape; OVERRIDE;

		END;

	TCroppingTool = OBJECT (TMarqueeSelector)

		fRatio: EXTENDED;

		fStyleInfo: TStyleInfo;

		fOptionDown: BOOLEAN;
		fCommandDown: BOOLEAN;

		fNextCorners: TCornerList;
		fBaseCorners: TCornerList;
		fLastCorners: TCornerList;

		PROCEDURE TCroppingTool.ICroppingTool (view: TImageView);

		FUNCTION TCroppingTool.TrackMouse
				(aTrackPhase: TrackPhase;
				 VAR anchorPoint, previousPoint, nextPoint: Point;
				 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

		PROCEDURE TCroppingTool.DrawFeedback (state: INTEGER);

		PROCEDURE TCroppingTool.MoveCorner (corner: INTEGER; delta: Point);

		PROCEDURE TCroppingTool.TrackCorner (corner: INTEGER; downPt: Point);

		FUNCTION TCroppingTool.InsideCorners (pt: Point): BOOLEAN;

		PROCEDURE TCroppingTool.GetNewCorners;

		PROCEDURE TCroppingTool.ComputeNewSize (VAR newRows: INTEGER;
												VAR newCols: INTEGER);

		PROCEDURE TCroppingTool.SkewArray (srcArray: TVMArray;
										   dstArray: TVMArray;
										   offset1: EXTENDED;
										   offset2: EXTENDED;
										   oldWidth: EXTENDED;
										   r: Rect);

		PROCEDURE TCroppingTool.AngledCrop (srcArray: TVMArray;
											dstArray: TVMArray);

		PROCEDURE TCroppingTool.DoIt; OVERRIDE;

		PROCEDURE TCroppingTool.UndoIt; OVERRIDE;

		PROCEDURE TCroppingTool.RedoIt; OVERRIDE;

		END;

	TCropCommand = OBJECT (TBufferCommand)

		fRows: INTEGER;
		fCols: INTEGER;

		fSelectionRect: Rect;

		PROCEDURE TCropCommand.ICropCommand (view: TImageView);

		PROCEDURE TCropCommand.DoIt; OVERRIDE;

		PROCEDURE TCropCommand.UndoIt; OVERRIDE;

		PROCEDURE TCropCommand.RedoIt; OVERRIDE;

		END;

	TRulerCommand = OBJECT (TBufferCommand)

		fOldOrigin: Point;
		fNewOrigin: Point;

		PROCEDURE TRulerCommand.IRulerCommand (view: TImageView; pt: Point);

		PROCEDURE TRulerCommand.DoIt; OVERRIDE;

		PROCEDURE TRulerCommand.UndoIt; OVERRIDE;

		PROCEDURE TRulerCommand.RedoIt; OVERRIDE;

		END;

PROCEDURE InitCrops;

FUNCTION DoMarqueeTool (view: TImageView;
						add: BOOLEAN;
						remove: BOOLEAN;
						refine: BOOLEAN): TCommand;

PROCEDURE DoMarqueeOptions;

FUNCTION DoEllipseTool (view: TImageView;
						add: BOOLEAN;
						remove: BOOLEAN;
						refine: BOOLEAN): TCommand;

PROCEDURE DoEllipseOptions;

FUNCTION DoCroppingTool (view: TImageView): TCommand;

PROCEDURE DoCroppingOptions;

FUNCTION DoCropCommand (view: TImageView): TCommand;

FUNCTION AdjustZeroPoint (view: TImageView): TCommand;

IMPLEMENTATION

{$I UAssembly.a.inc}
{$I UResize.p.inc}
{$I URotate.a.inc}
{$I URotate.p.inc}

VAR
	gMarqueeOptions: TRectOptions;
	gEllipseOptions: TRectOptions;

	gCroppingWidth: FixedScaled;
	gCroppingHeight: FixedScaled;
	gCroppingResolution: FixedScaled;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitCrops;

	BEGIN

	WITH gMarqueeOptions DO
		BEGIN
		mode   := 0;
		size.h := 64;
		size.v := 64;
		ratioH := 1000;
		ratioV := 1000
		END;

	gEllipseOptions := gMarqueeOptions;

	gCroppingWidth.scale := 1 + ORD (gMetric);
	gCroppingWidth.value := 0;

	gCroppingHeight.scale := 1 + ORD (gMetric);
	gCroppingHeight.value := 0;

	gCroppingResolution.scale := 1;
	gCroppingResolution.value := 0

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TMarqueeSelector.IMarqueeSelector (itsCommand: INTEGER;
											 view: TImageView;
											 add, remove, refine: BOOLEAN);

	BEGIN

	IMaskCommand (itsCommand, view, add, remove, refine, FALSE, FALSE, TRUE);

	fAutoScroll := TRUE;

	fConstrainsMouse := TRUE;

	fMovedOnce := FALSE;

	fFlickerTime  := TickCount;
	fFlickerState := 0;

	fOptions := gMarqueeOptions

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TMarqueeSelector.CompNextRect (corner1, corner2: Point);

	VAR
		x: EXTENDED;
		delta: Point;
		bounds: Rect;
		width: INTEGER;
		ratio: EXTENDED;
		height: INTEGER;
		theKeys: KeyMap;
		fromCenter: BOOLEAN;
		hysteresis: BOOLEAN;

	BEGIN

	GetKeys (theKeys);
	fromCenter := theKeys [kOptionCode];

	fDoc.GetBoundsRect (bounds);

	hysteresis := (fOptions.mode <= 1);

	IF hysteresis AND NOT fMovedOnce THEN
		fNextRect := gZeroRect

	ELSE
		CASE fOptions.mode OF

		0,1:
			BEGIN	{ Normal and Fixed Ratio }

			IF fOptions.mode = 1 THEN
				BEGIN

				ratio := fOptions.ratioH / fOptions.ratioV;

				width  := ABS (corner2.h - corner1.h) + 1;
				height := ABS (corner2.v - corner1.v) + 1;

				IF width <= height * ratio THEN
					BEGIN

					x := width / ratio;

					IF x > kMaxCoord THEN x := kMaxCoord;

					height := Max (1, ROUND (x));

					IF corner2.v >= corner1.v THEN
						corner2.v := corner1.v + height - 1
					ELSE
						corner2.v := corner1.v - height + 1

					END

				ELSE
					BEGIN

					x := height * ratio;

					IF x > kMaxCoord THEN x := kMaxCoord;

					width := Max (1, ROUND (x));

					IF corner2.h >= corner1.h THEN
						corner2.h := corner1.h + width - 1
					ELSE
						corner2.h := corner1.h - width + 1

					END

				END;

			IF fromCenter THEN
				BEGIN

				delta.h := ABS (corner2.h - corner1.h) + 1;
				delta.v := ABS (corner2.v - corner1.v) + 1;

				fNextRect.right  := Min (kMaxCoord, corner1.h + delta.h);
				fNextRect.bottom := Min (kMaxCoord, corner1.v + delta.v);

				fNextRect.left := fNextRect.right  - BSL (delta.h, 1);
				fNextRect.top  := fNextRect.bottom - BSL (delta.v, 1);

				{$H-}
				SlideRectInto (fNextRect, bounds)
				{$H+}

				END

			ELSE
				BEGIN

				{$H-}
				Pt2Rect (corner1, corner2, fNextRect);
				{$H+}

				fNextRect.right  := fNextRect.right  + 1;
				fNextRect.bottom := fNextRect.bottom + 1

				END

			END;

		2:	BEGIN	{ Fixed Size }

			IF fromCenter THEN
				BEGIN
				fNextRect.right  := Min (kMaxCoord,
										 corner2.h + BSR (fOptions.size.h, 1));
				fNextRect.bottom := Min (kMaxCoord,
										 corner2.v + BSR (fOptions.size.v, 1))
				END
			ELSE
				BEGIN
				fNextRect.right  := corner2.h + 1;
				fNextRect.bottom := corner2.v + 1
				END;

			fNextRect.left := fNextRect.right  - fOptions.size.h;
			fNextRect.top  := fNextRect.bottom - fOptions.size.v;

			{$H-}
			SlideRectInto (fNextRect, bounds)
			{$H+}

			END;

		3:	BEGIN	{ Single Row }

			fNextRect := bounds;

			fNextRect.top	 := corner2.v;
			fNextRect.bottom := corner2.v + 1

			END;

		4:	BEGIN	{ Single Column }

			fNextRect := bounds;

			fNextRect.left	:= corner2.h;
			fNextRect.right := corner2.h + 1

			END

		END

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TMarqueeSelector.TrackConstrain
		(anchorPoint, previousPoint: Point; VAR nextPoint: Point); OVERRIDE;

	VAR
		corner1: Point;
		corner2: Point;
		firstPoint: Point;

	BEGIN

	fView.TrackRulers;

	firstPoint := anchorPoint;

	IF NOT fMovedOnce THEN
		BEGIN

		fMovedOnce := (Abs (nextPoint.h - firstPoint.h) > gStdHysteresis.h) OR
					  (Abs (nextPoint.v - firstPoint.v) > gStdHysteresis.v);

		fView.CvtView2Image (firstPoint);
		fView.CvtImage2View (firstPoint, kRoundDown)

		END;

	fView.CvtView2Image (nextPoint);
	fView.CvtImage2View (nextPoint, kRoundDown);

	corner1 := firstPoint;
	corner2 := nextPoint;

	fView.CvtView2Image (corner1);
	fView.CvtView2Image (corner2);

	corner1.h := Min (corner1.h, fDoc.fCols - 1);
	corner1.v := Min (corner1.v, fDoc.fRows - 1);
	corner2.h := Min (corner2.h, fDoc.fCols - 1);
	corner2.v := Min (corner2.v, fDoc.fRows - 1);

	CompNextRect (corner1, corner2)

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TMarqueeSelector.DrawShape (r: Rect);

	BEGIN
	FrameRect (r)
	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TMarqueeSelector.TrackFeedBack
		(anchorPoint, nextPoint: Point;
		 turnItOn, mouseDidMove: BOOLEAN); OVERRIDE;

	VAR
		r: Rect;
		flicker: BOOLEAN;

	BEGIN

	flicker := turnItOn AND (TickCount >= fFlickerTime);

	IF flicker THEN
		BEGIN
		fFlickerTime  := TickCount + kHLDelay;
		fFlickerState := (fFlickerState + 1) MOD kHLPatterns
		END;

	IF mouseDidMove OR NOT EqualRect (fLastRect, fNextRect) THEN
		BEGIN
		IF turnItOn THEN fLastRect := fNextRect;
		PenPat (gHLPattern [fFlickerState])
		END

	ELSE IF flicker THEN
		PenPat (gHLPatternDelta [fFlickerState])

	ELSE
		EXIT (TrackFeedBack);

	r := fLastRect;

	fView.CvtImage2View (r.topLeft, kRoundDown);
	fView.CvtImage2View (r.botRight, kRoundUp);

	PenSize (kMarqueeWidth, kMarqueeWidth);

	DrawShape (r)

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TMarqueeSelector.FillShape (r: Rect);

	BEGIN

	fMask.SetRect (r, 255)

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TMarqueeSelector.SelectShape;

	VAR
		r: Rect;

	BEGIN

	r := fMaskBounds;

	fDoc.Select (r, NIL)

	END;

{*****************************************************************************}

{$S ACropping}

FUNCTION TMarqueeSelector.TrackMouse
		(aTrackPhase: TrackPhase;
		 VAR anchorPoint, previousPoint, nextPoint: Point;
		 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

	VAR
		r: Rect;
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FixObscured;
		Free;
		FailNewMessage (error, message, msgCannotMarquee)
		END;

	BEGIN

	TrackMouse := SELF;

	IF aTrackPhase = trackRelease THEN
		BEGIN

		CatchFailures (fi, CleanUp);

		MoveHands (TRUE);

		r := fNextRect;

		IF EmptyRect (r) THEN
			TrackMouse := DropSelection (fView)

		ELSE
			BEGIN

			fMaskBounds := r;

			IF fAdd OR fRemove OR fRefine THEN
				BEGIN

				fMask.SetBytes (0);
				FillShape (r);

				MoveHands (TRUE);

				UpdateSelection

				END

			ELSE
				BEGIN

				IF fWasFloating THEN
					FloatSelection (FALSE)
				ELSE
					BEGIN
					fSaveRect := fDoc.fSelectionRect;
					IF fDoc.fSelectionMask <> NIL THEN
						fSaveMask := fDoc.fSelectionMask.CopyArray (1)
					END;

				SelectShape

				END

			END;

		Success (fi)

		END

	END;

{*****************************************************************************}

{$S ACropping}

FUNCTION DoMarqueeTool (view: TImageView;
						add: BOOLEAN;
						remove: BOOLEAN;
						refine: BOOLEAN): TCommand;

	VAR
		fi: FailInfo;
		aMarqueeSelector: TMarqueeSelector;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FailNewMessage (error, message, msgCannotMarquee)
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	NEW (aMarqueeSelector);
	FailNil (aMarqueeSelector);

	aMarqueeSelector.IMarqueeSelector (cMarquee, view, add, remove, refine);

	DoMarqueeTool := aMarqueeSelector;

	Success (fi)

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE DoRectOptions (dialogID: INTEGER; VAR options: TRectOptions);

	CONST
		kHookItem		= 3;
		kColsRatioItem	= 4;
		kRowsRatioItem	= 5;
		kColsSizeItem	= 6;
		kRowsSizeItem	= 7;
		kNormalItem 	= 8;
		kFixedRatioItem = 9;
		kFixedSizeItem	= 10;
		kSingleRowItem	= 11;
		kSingleColItem	= 12;

	VAR
		fi: FailInfo;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		colsSizeText: TFixedText;
		rowsSizeText: TFixedText;
		colsRatioText: TFixedText;
		rowsRatioText: TFixedText;
		modeCluster: TRadioCluster;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	PROCEDURE MyItemHandling (anItem: INTEGER; VAR done: BOOLEAN);

		BEGIN

		StdItemHandling (anItem, done);

			CASE anItem OF

			kColsRatioItem,
			kRowsRatioItem:
				StdItemHandling (kFixedRatioItem, done);

			kColsSizeItem,
			kRowsSizeItem:
				StdItemHandling (kFixedSizeItem, done)

			END

		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (dialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	colsRatioText := aBWDialog.DefineFixedText
					 (kColsRatioItem, 3, FALSE, TRUE, 1, 9999999);

	rowsRatioText := aBWDialog.DefineFixedText
					 (kRowsRatioItem, 3, FALSE, TRUE, 1, 9999999);

	colsRatioText.StuffValue (options.ratioH);
	rowsRatioText.StuffValue (options.ratioV);

	colsSizeText := aBWDialog.DefineFixedText
					(kColsSizeItem, 0, FALSE, TRUE, 1, kMaxCoord);

	rowsSizeText := aBWDialog.DefineFixedText
					(kRowsSizeItem, 0, FALSE, TRUE, 1, kMaxCoord);

	colsSizeText.StuffValue (options.size.h);
	rowsSizeText.StuffValue (options.size.v);

	modeCluster := aBWDialog.DefineRadioCluster
				   (kNormalItem,
					kSingleColItem,
					kNormalItem + options.mode);

	IF options.mode = 1 THEN
		aBWDialog.SetEditSelection (kColsRatioItem)
	ELSE
		aBWDialog.SetEditSelection (kColsSizeItem);

	aBWDialog.TalkToUser (hitItem, MyItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	options.ratioH := colsRatioText.fValue;
	options.ratioV := rowsRatioText.fValue;

	options.size.h := colsSizeText.fValue;
	options.size.v := rowsSizeText.fValue;

	options.mode := modeCluster.fChosenItem - kNormalItem;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE DoMarqueeOptions;

	CONST
		kDialogID = 1080;

	BEGIN
	DoRectOptions (kDialogID, gMarqueeOptions)
	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TEllipseSelector.IEllipseSelector (view: TImageView;
											 add, remove, refine: BOOLEAN);

	BEGIN

	IMarqueeSelector (cEllipse, view, add, remove, refine);

	fOptions := gEllipseOptions

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TEllipseSelector.DrawShape (r: Rect); OVERRIDE;

	BEGIN
	FrameOval (r)
	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TEllipseSelector.FillShape (r: Rect); OVERRIDE;

	VAR
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		width: INTEGER;
		height: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FailNewMessage (error, message, msgCannotEllipse)
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	width  := r.right - r.left;
	height := r.bottom - r.top;

	FOR row := 0 TO height - 1 DO
		BEGIN

		MoveHands (TRUE);

		dstPtr := fMask.NeedPtr (row + r.top, row + r.top, TRUE);
		dstPtr := Ptr (ORD4 (dstPtr) + r.left);

		DoEllipseRow (dstPtr, row, width, height);

		fMask.DoneWithPtr

		END;

	fMask.Flush;

	Success (fi)

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TEllipseSelector.SelectShape; OVERRIDE;

	VAR
		r: Rect;
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FailNewMessage (error, message, msgCannotEllipse)
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	MoveHands (TRUE);

	r := fMaskBounds;
	OffsetRect (r, -r.left, -r.top);

	fMask := NewVMArray (r.bottom, r.right, 1);

	FillShape (r);

	r := fMaskBounds;
	fDoc.Select (r, fMask.CopyArray (1));

	Success (fi)

	END;

{*****************************************************************************}

{$S ACropping}

FUNCTION DoEllipseTool (view: TImageView;
						add: BOOLEAN;
						remove: BOOLEAN;
						refine: BOOLEAN): TCommand;

	VAR
		anEllipseSelector: TEllipseSelector;

	BEGIN

	NEW (anEllipseSelector);
	FailNil (anEllipseSelector);

	anEllipseSelector.IEllipseSelector (view, add, remove, refine);

	DoEllipseTool := anEllipseSelector

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE DoEllipseOptions;

	CONST
		kDialogID = 1093;

	BEGIN
	DoRectOptions (kDialogID, gEllipseOptions)
	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TCroppingTool.ICroppingTool (view: TImageView);

	BEGIN

	IMarqueeSelector (cCrop, view, FALSE, FALSE, FALSE);

	fCausesChange := TRUE;

	fStyleInfo := fDoc.fStyleInfo;

	IF gCroppingHeight.value = 0 THEN
		BEGIN
		fRatio		  := 0;
		fOptions.mode := 0
		END
	ELSE
		BEGIN
		fRatio			:= gCroppingWidth.value / gCroppingHeight.value;
		fOptions.mode	:= 1;
		fOptions.ratioH := gCroppingWidth.value;
		fOptions.ratioV := gCroppingHeight.value
		END

	END;

{*****************************************************************************}

{$S ACropping}

FUNCTION TCroppingTool.TrackMouse
		(aTrackPhase: TrackPhase;
		 VAR anchorPoint, previousPoint, nextPoint: Point;
		 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

	BEGIN

	IF (aTrackPhase = trackRelease) & EmptyRect (fNextRect) THEN
		TrackMouse := gNoChanges
	ELSE
		TrackMouse := SELF

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TCroppingTool.DrawFeedback (state: INTEGER);

	VAR
		r: Rect;
		j: INTEGER;

	PROCEDURE DrawSides;

		VAR
			pt: Point;
			j: INTEGER;
			vp: TCornerList;

		BEGIN

		PenMode (patXor);

		FOR j := 0 TO 3 DO
			BEGIN
			vp [j] := fLastCorners [j];
			fView.CvtImage2View (vp [j], kRoundUp)
			END;

		vp[1].h := vp[1].h - 1;
		vp[2].h := vp[2].h - 1;
		vp[2].v := vp[2].v - 1;
		vp[3].v := vp[3].v - 1;

		FOR j := 0 TO 3 DO
			BEGIN

			pt := vp [j];
			MoveTo (pt.h, pt.v);

			pt := vp [(j + 1) MOD 4];
			LineTo (pt.h, pt.v)

			END

		END;

	BEGIN

	IF gApplication.fIdlePriority <> 0 THEN
		EXIT (DrawFeedback);

	PenNormal;

		CASE state OF

		0:	BEGIN

			fLastCorners := fNextCorners;

			FOR j := 0 TO 3 DO
				IF fView.CompCornerRect (fLastCorners [j], r) THEN
					BEGIN
					EraseRect (r);
					FrameRect (r)
					END;

			PenPat (gHLPattern [fFlickerState]);

			DrawSides

			END;

		1:	IF NOT EqualBytes (@fLastCorners,
							   @fNextCorners,
							   SIZEOF (TCornerList)) THEN
				BEGIN

				PenPat (gHLPattern [fFlickerState]);

				DrawSides;

				FOR j := 0 TO 3 DO
					BEGIN
					IF fView.CompCornerRect (fLastCorners [j], r) THEN
						BEGIN
						fView.DrawNow (r, TRUE);
						fView.DoDrawExtraFeedback (r)
						END;
					IF fView.CompCornerRect (fNextCorners [j], r) THEN
						BEGIN
						PenNormal;
						EraseRect (r);
						FrameRect (r)
						END
					END;

				fLastCorners := fNextCorners;

				PenNormal;
				PenPat (gHLPattern [fFlickerState]);

				DrawSides

				END

			ELSE IF TickCount >= fFlickerTime THEN
				BEGIN

				fFlickerTime  := TickCount + kHLDelay;
				fFlickerState := (fFlickerState + 1) MOD kHLPatterns;

				PenMode (patXor);
				PenPat (gHLPatternDelta [fFlickerState]);

				DrawSides

				END;

		2:	BEGIN

			PenPat (gHLPattern [fFlickerState]);

			DrawSides;

			FOR j := 0 TO 3 DO
				IF fView.CompCornerRect (fLastCorners [j], r) THEN
					BEGIN
					fView.DrawNow (r, TRUE);
					fView.DoDrawExtraFeedback (r)
					END;

			END

		END

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TCroppingTool.MoveCorner (corner: INTEGER; delta: Point);

	VAR
		j: INTEGER;
		bounds: Rect;
		center: Point;
		angle: EXTENDED;
		width: EXTENDED;
		height: EXTENDED;
		deltaW: EXTENDED;
		deltaH: EXTENDED;

	FUNCTION ArcTan2 (y, x: EXTENDED): EXTENDED;

		BEGIN

		IF y < 0 THEN
			ArcTan2 := -ArcTan2 (-y, x)
		ELSE IF x < 0 THEN
			ArcTan2 := pi - ArcTan2 (y, -x)
		ELSE IF y > x THEN
			ArcTan2 := pi / 2 - ArcTan2 (x, y)
		ELSE IF x = 0 THEN
			ArcTan2 := 0
		ELSE
			ArcTan2 := ARCTAN (y / x)

		END;

	PROCEDURE GetParameters;

		BEGIN

		width := SQRT (SQR (ORD4 (fBaseCorners [0] . h -
								  fBaseCorners [1] . h)) +
					   SQR (ORD4 (fBaseCorners [0] . v -
								  fBaseCorners [1] . v)));

		height := SQRT (SQR (ORD4 (fBaseCorners [0] . h -
								   fBaseCorners [3] . h)) +
						SQR (ORD4 (fBaseCorners [0] . v -
								   fBaseCorners [3] . v)));

		IF fRatio <> 0 THEN
			IF width >= height THEN
				height := width / fRatio
			ELSE
				width := height * fRatio;

		angle := ArcTan2 (fBaseCorners [1] . v - fBaseCorners [0] . v,
						  fBaseCorners [1] . h - fBaseCorners [0] . h);

		END;

	PROCEDURE SetParameters;

		VAR
			x: EXTENDED;
			cosW: INTEGER;
			sinW: INTEGER;
			cosH: INTEGER;
			sinH: INTEGER;
			maxAngle: EXTENDED;
			cosAngle: EXTENDED;
			sinAngle: EXTENDED;

		BEGIN

		WHILE angle >  pi DO angle := angle - 2 * pi;
		WHILE angle < -pi DO angle := angle + 2 * pi;

		maxAngle := pi / 4;

		IF angle >	maxAngle THEN angle :=	maxAngle;
		IF angle < -maxAngle THEN angle := -maxAngle;

		cosAngle := COS (ABS (angle));
		sinAngle := SIN (ABS (angle));

		x := (cosAngle * width + sinAngle * height) / bounds.right;

		IF x > 1 THEN
			BEGIN
			width  := width  / x;
			height := height / x
			END;

		x := (cosAngle * height + sinAngle * width) / bounds.bottom;

		IF x > 1 THEN
			BEGIN
			width  := width  / x;
			height := height / x
			END;

		cosW := ROUND (cosAngle * width);
		sinW := ROUND (sinAngle * width);
		cosH := ROUND (cosAngle * height);
		sinH := ROUND (sinAngle * height);

		IF cosW >= sinH THEN
			cosW := Min (cosW, bounds.right  - sinH)
		ELSE
			sinH := Min (sinH, bounds.right  - cosW);

		IF cosH >= sinW THEN
			cosH := Min (cosH, bounds.bottom - sinW)
		ELSE
			sinW := Min (sinW, bounds.bottom - cosH);

		IF angle >= 0 THEN
			BEGIN
			fNextCorners [0] . h := sinH;
			fNextCorners [0] . v := 0;
			fNextCorners [1] . h := sinH + cosW;
			fNextCorners [1] . v := sinW;
			fNextCorners [2] . h := cosW;
			fNextCorners [2] . v := sinW + cosH;
			fNextCorners [3] . h := 0;
			fNextCorners [3] . v := cosH
			END
		ELSE
			BEGIN
			fNextCorners [0] . h := 0;
			fNextCorners [0] . v := sinW;
			fNextCorners [1] . h := cosW;
			fNextCorners [1] . v := 0;
			fNextCorners [2] . h := cosW + sinH;
			fNextCorners [2] . v := cosH;
			fNextCorners [3] . h := sinH;
			fNextCorners [3] . v := sinW + cosH
			END

		END;

	PROCEDURE ForceOnImage;

		VAR
			j: INTEGER;
			limits: Rect;
			offset: Point;

		BEGIN

		limits.topLeft	:= fNextCorners [0];
		limits.botRight := fNextCorners [0];

		FOR j := 1 TO 3 DO
			BEGIN
			limits.top	  := Min (limits.top   , fNextCorners [j] . v);
			limits.left   := Min (limits.left  , fNextCorners [j] . h);
			limits.bottom := Max (limits.bottom, fNextCorners [j] . v);
			limits.right  := Max (limits.right , fNextCorners [j] . h)
			END;

		offset.v := Min (0, bounds.bottom - limits.bottom) +
					Max (0, bounds.top	  - limits.top	 );

		offset.h := Min (0, bounds.right  - limits.right ) +
					Max (0, bounds.left   - limits.left  );

		FOR j := 0 TO 3 DO
			BEGIN
			fNextCorners [j] . v := fNextCorners [j] . v + offset.v;
			fNextCorners [j] . h := fNextCorners [j] . h + offset.h
			END

		END;

	BEGIN

	fDoc.GetBoundsRect (bounds);

	delta.h := Max (bounds.left   - fBaseCorners [corner] . h,
			   Min (bounds.right  - fBaseCorners [corner] . h, delta.h));
	delta.v := Max (bounds.top	  - fBaseCorners [corner] . v,
			   Min (bounds.bottom - fBaseCorners [corner] . v, delta.v));

	IF fCommandDown THEN

		FOR j := 0 TO 3 DO
			BEGIN
			fNextCorners [j] . h := fBaseCorners [j] . h + delta.h;
			fNextCorners [j] . v := fBaseCorners [j] . v + delta.v
			END

	ELSE IF fOptionDown THEN
		BEGIN

		GetParameters;

		center.h := (fBaseCorners [0] . h + fBaseCorners [2] . h) DIV 2;
		center.v := (fBaseCorners [0] . v + fBaseCorners [2] . v) DIV 2;

		angle := angle +
				 ArcTan2 (fBaseCorners [corner] . v + delta.v - center.v,
						  fBaseCorners [corner] . h + delta.h - center.h) -
				 ArcTan2 (fBaseCorners [corner] . v - center.v,
						  fBaseCorners [corner] . h - center.h);

		SetParameters;

		center.h := center.h - (fNextCorners [0] . h +
								fNextCorners [2] . h) DIV 2;
		center.v := center.v - (fNextCorners [0] . v +
								fNextCorners [2] . v) DIV 2;

		FOR j := 0 TO 3 DO
			BEGIN
			fNextCorners [j] . h := fNextCorners [j] . h + center.h;
			fNextCorners [j] . v := fNextCorners [j] . v + center.v
			END

		END

	ELSE
		BEGIN

		GetParameters;

		deltaW := COS (angle) * delta.h + SIN (angle) * delta.v;
		deltaH := COS (angle) * delta.v - SIN (angle) * delta.h;

			CASE corner OF

			0:	BEGIN
				width  := width  - deltaW;
				height := height - deltaH
				END;

			1:	BEGIN
				width  := width  + deltaW;
				height := height - deltaH
				END;

			2:	BEGIN
				width  := width  + deltaW;
				height := height + deltaH
				END;

			3:	BEGIN
				width  := width  - deltaW;
				height := height + deltaH
				END

			END;

		IF width  < 0 THEN width  := 0;
		IF height < 0 THEN height := 0;

		IF fRatio <> 0 THEN
			IF width > height * fRatio THEN
				width := height * fRatio
			ELSE
				height := width / fRatio;

		SetParameters;

		j := (corner + 2) MOD 4;

		center.h := fBaseCorners [j] . h - fNextCorners [j] . h;
		center.v := fBaseCorners [j] . v - fNextCorners [j] . v;

		FOR j := 0 TO 3 DO
			BEGIN
			fNextCorners [j] . h := fNextCorners [j] . h + center.h;
			fNextCorners [j] . v := fNextCorners [j] . v + center.v
			END

		END;

	ForceOnImage

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TCroppingTool.TrackCorner (corner: INTEGER; downPt: Point);

	VAR
		vr: Rect;
		pt: Point;
		mag: INTEGER;
		delta: Point;
		done: BOOLEAN;
		lastDelta: Point;
		didScroll: BOOLEAN;
		theEvent: EventRecord;

	PROCEDURE ReFocus;
		BEGIN
		fView.fFrame.Focus;
		fView.fFrame.GetViewedRect (vr)
		END;

	BEGIN

	ReFocus;

	mag := fView.fMagnification;

	fBaseCorners := fNextCorners;

	lastDelta := Point (0);

		REPEAT

		fView.TrackRulers;

		GetMouse (pt);

		done := NOT StillDown;

		IF done THEN
			IF GetNextEvent (mUpMask, theEvent) THEN
				BEGIN
				pt := theEvent.where;
				GlobalToLocal (pt)
				END;

		delta := Point (0);

		IF NOT PtInRect (pt, vr) THEN
			BEGIN
			fView.fFrame.AutoScroll (pt, delta);
			AddPt (delta, pt)
			END;

		didScroll := LONGINT (delta) <> 0;

		IF didScroll THEN
			BEGIN
			DrawFeedback (2);
			fView.fFrame.ScrollBy (delta, FALSE);
			ReFocus
			END;

		delta.h := pt.h - downPt.h;
		delta.v := pt.v - downPt.v;

		IF mag > 0 THEN
			BEGIN
			delta.h := delta.h DIV mag;
			delta.v := delta.v DIV mag
			END
		ELSE
			BEGIN
			delta.h := delta.h * (-mag);
			delta.v := delta.v * (-mag)
			END;

		IF LONGINT (delta) <> LONGINT (lastDelta) THEN
			MoveCorner (corner, delta);

		lastDelta := delta;

		IF didScroll THEN
			DrawFeedback (0)
		ELSE
			DrawFeedback (1)

		UNTIL done

	END;

{*****************************************************************************}

{$S ACropping}

FUNCTION TCroppingTool.InsideCorners (pt: Point): BOOLEAN;

	FUNCTION RightSide (pt1, pt2: Point): BOOLEAN;

		BEGIN

		fView.CvtImage2View (pt1, kRoundDown);
		fView.CvtImage2View (pt2, kRoundDown);

		RightSide := ORD4 (pt.v - pt1.v) * (pt2.h - pt1.h) -
					 ORD4 (pt.h - pt1.h) * (pt2.v - pt1.v) >= 0

		END;

	BEGIN

	InsideCorners := RightSide (fLastCorners [0], fLastCorners [1]) &
					 RightSide (fLastCorners [1], fLastCorners [2]) &
					 RightSide (fLastCorners [2], fLastCorners [3]) &
					 RightSide (fLastCorners [3], fLastCorners [0])

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TCroppingTool.GetNewCorners;

	LABEL
		1;

	VAR
		c: CHAR;
		vr: Rect;
		pt: Point;
		id: INTEGER;
		tool: TTool;
		fi: FailInfo;
		wp: WindowPtr;
		part: INTEGER;
		corner: INTEGER;
		window: TWindow;
		theKeys: KeyMap;
		menu: MenuHandle;
		ignore: TCommand;
		spaceDown: BOOLEAN;
		theEvent: EventRecord;
		control: ControlHandle;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		HiliteGhosts (TRUE);
		gMenusAreSetUp := FALSE
		END;

	PROCEDURE SetTool (pt: Point; spaceDown, optionDown, commandDown: BOOLEAN);
		BEGIN

		IF spaceDown THEN
			IF optionDown THEN
				IF fView.fMagnification = fView.MinMagnification THEN
					gUseTool := ZoomLimitTool
				ELSE
					gUseTool := ZoomOutTool
			ELSE IF commandDown THEN
				IF fView.fMagnification = fView.MaxMagnification THEN
					gUseTool := ZoomLimitTool
				ELSE
					gUseTool := ZoomTool
			ELSE
				gUseTool := HandTool

		ELSE IF fView.FindCorner (fLastCorners, pt) <> -1 THEN
			gUseTool := CropAdjustTool

		ELSE IF InsideCorners (pt) THEN
			gUseTool := CropFinishTool

		ELSE
			gUseTool := CroppingTool;

		SetToolCursor (gUseTool, TRUE)

		END;

	BEGIN

	FOR id := 2 TO kLastMenuID DO
		BEGIN
		menu := GetResMenu (id);
		DisableItem (menu, 0)
		END;

	DrawMenuBar;

	HiliteGhosts (FALSE);

	CatchFailures (fi, CleanUp);

	fNextCorners [0]	 := fNextRect.topLeft;
	fNextCorners [1] . h := fNextRect.right;
	fNextCorners [1] . v := fNextRect.top;
	fNextCorners [2]	 := fNextRect.botRight;
	fNextCorners [3] . h := fNextRect.left;
	fNextCorners [3] . v := fNextRect.bottom;

	DrawFeedback (0);

	window := fView.fWindow;

		REPEAT

		fView.TrackRulers;

		GetMouse (pt);

		fView.fFrame.GetViewedRect (vr);

		IF PtInRect (pt, vr) THEN
			BEGIN
			GetKeys (theKeys);
			SetTool (pt,
					 theKeys [kSpaceCode],
					 theKeys [kOptionCode],
					 theKeys [kCommandCode])
			END
		ELSE
			SetCursor (arrow);

		gMenusAreSetUp := FALSE;

		IF gApplication.GetEvent (everyEvent, theEvent) THEN

			CASE theEvent.what OF

			mouseDown:
				IF FindWindow (theEvent.where, wp) <> inContent THEN
					SysBeep (1)

				ELSE IF wp = gToolsWindow THEN
					BEGIN

					gToolsView.fFrame.Focus;

					pt := theEvent.where;
					GlobalToLocal (pt);

					tool := gToolsView.FindTool (pt);

					IF tool <> NullTool THEN
						ignore := gToolsView.PickTool (tool, 1);

					fView.fFrame.Focus;

					IF tool = NullTool THEN
						SysBeep (1)
					ELSE
						BEGIN
						DrawFeedback (2);
						Failure (0, 0)
						END

					END

				ELSE IF wp <> window.fWmgrWindow THEN
					SysBeep (1)

				ELSE
					BEGIN

					window.Focus;

					pt := theEvent.where;
					GlobalToLocal (pt);

					part := FindControl (pt, wp, control);

					fView.fFrame.Focus;

					pt := theEvent.where;
					GlobalToLocal (pt);

					IF part <> 0 THEN
						BEGIN
						DrawFeedback (2);
						gApplication.DispatchEvent (@theEvent);
						fView.fFrame.Focus;
						DrawFeedback (0)
						END

					ELSE IF NOT PtInRect (pt, vr) THEN
						SysBeep (1)

					ELSE
						BEGIN

						fOptionDown  := BAND (theEvent.modifiers,
											  optionKey) <> 0;
						fCommandDown := BAND (theEvent.modifiers,
											  cmdKey) <> 0;

						spaceDown := SpaceWasDown;

						SetTool (pt, spaceDown, fOptionDown, fCommandDown);

							CASE gUseTool OF

							HandTool,
							ZoomTool,
							ZoomOutTool:
								BEGIN
								DrawFeedback (2);
								gApplication.DispatchEvent (@theEvent);
								fView.fFrame.Focus;
								DrawFeedback (0)
								END;

							CropAdjustTool:
								BEGIN
								corner := fView.FindCorner (fLastCorners, pt);
								TrackCorner (corner, pt)
								END;

							CropFinishTool:
								GOTO 1;

							CroppingTool:
								BEGIN
								DrawFeedback (2);
								Failure (0, 0)
								END

							END

						END

					END;

			keyDown,
			autoKey:
				BEGIN

				c := CHR (BAND (theEvent.message, charCodeMask));

				IF (c = '.') AND (BAND (theEvent.modifiers, cmdKey) <> 0) OR
				   (c = CHR ($8)) OR
				   (c = CHR ($1B)) THEN
					BEGIN
					DrawFeedback (2);
					Failure (0, 0)
					END

				END;

			updateEvt:
				BEGIN
				DrawFeedback (2);
				gApplication.DispatchEvent (@theEvent);
				fView.fFrame.Focus;
				DrawFeedback (0)
				END

			END

		ELSE IF gApplication.fIdlePriority <> 0 THEN
			BEGIN
			DrawFeedback (2);
			gApplication.DoIdle (idleContinue);
			fView.fFrame.Focus;
			DrawFeedback (0)
			END

		ELSE
			DrawFeedback (1)

		UNTIL FALSE;

	1:	{ Continue }

	DrawFeedback (2);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TCroppingTool.ComputeNewSize (VAR newRows: INTEGER;
										VAR newCols: INTEGER);

	VAR
		x: EXTENDED;
		y: EXTENDED;
		width: EXTENDED;
		height: EXTENDED;

	BEGIN

	IF (fNextCorners [0] . h = fNextCorners [1] . h) OR
	   (fNextCorners [0] . v = fNextCorners [3] . v) THEN
		Failure (errSelectTooSmall, 0);

	width  := SQRT (SQR (ORD4 (fNextCorners [0] . h - fNextCorners [1] . h)) +
					SQR (ORD4 (fNextCorners [0] . v - fNextCorners [1] . v)));

	height := SQRT (SQR (ORD4 (fNextCorners [0] . h - fNextCorners [3] . h)) +
					SQR (ORD4 (fNextCorners [0] . v - fNextCorners [3] . v)));

	IF gCroppingWidth.value <> 0 THEN
		fStyleInfo.fWidthUnit := gCroppingWidth.scale;

	IF gCroppingHeight.value <> 0 THEN
		fStyleInfo.fHeightUnit := gCroppingHeight.scale;

	IF gCroppingResolution.value <> 0 THEN
		BEGIN

		fStyleInfo.fResolution := gCroppingResolution;

		IF gCroppingWidth.value <> 0 THEN
			IF gCroppingHeight.value <> 0 THEN
				BEGIN
				x := gCroppingWidth.value	   / $10000 *
					 gCroppingResolution.value / $10000;
				y := gCroppingHeight.value	   / $10000 *
					 gCroppingResolution.value / $10000
				END
			ELSE
				BEGIN
				x := gCroppingWidth.value	   / $10000 *
					 gCroppingResolution.value / $10000;
				y := x / width * height
				END
		ELSE
			IF gCroppingHeight.value <> 0 THEN
				BEGIN
				y := gCroppingHeight.value	   / $10000 *
					 gCroppingResolution.value / $10000;
				x := y / height * width
				END
			ELSE
				BEGIN
				x := width;
				y := height
				END;

		IF x > kMaxCoord THEN
			newCols := kMaxCoord
		ELSE IF x < 1 THEN
			newCols := 1
		ELSE
			newCols := ROUND (x);

		IF y > kMaxCoord THEN
			newRows := kMaxCoord
		ELSE IF y < 1 THEN
			newRows := 1
		ELSE
			newRows := ROUND (y)

		END

	ELSE
		BEGIN

		newCols := Min (kMaxCoord, ROUND (width));
		newRows := Min (kMaxCoord, ROUND (height));

		IF gCroppingWidth.value <> 0 THEN
			IF gCroppingHeight.value <> 0 THEN
				IF newCols >= newRows THEN
					x := newCols / gCroppingWidth.value * $10000
				ELSE
					x := newRows / gCroppingHeight.value * $10000
			ELSE
				x := newCols / gCroppingWidth.value * $10000
		ELSE
			IF gCroppingHeight.value <> 0 THEN
				x := newRows / gCroppingHeight.value * $10000
			ELSE
				EXIT (ComputeNewSize);

		IF x > 3200 THEN x := 3200;

		fStyleInfo.fResolution.value := Max (1, ROUND (x * $10000))

		END

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TCroppingTool.SkewArray (srcArray: TVMArray;
								   dstArray: TVMArray;
								   offset1: EXTENDED;
								   offset2: EXTENDED;
								   oldWidth: EXTENDED;
								   r: Rect);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		row: INTEGER;
		step: LONGINT;
		count: INTEGER;
		factor: INTEGER;
		method: INTEGER;
		offset: EXTENDED;

	BEGIN

	IF fDoc.fMode = IndexedColorMode THEN
		method := 0
	ELSE
		method := gPreferences.fInterpolate;

	factor := Max (1, TRUNC (oldWidth / dstArray.fLogicalSize));

	offset1 := offset1 / factor;
	offset2 := offset2 / factor;

	IF dstArray.fLogicalSize = 1 THEN
		step := 0
	ELSE
		step := ROUND ((oldWidth / factor - 1) /
					   (dstArray.fLogicalSize - 1) * 16777216);

	FOR row := 0 TO r.bottom - r.top - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row, r.bottom - r.top);

		dstPtr := dstArray.NeedPtr (row, row, TRUE);

		srcPtr := Ptr (ORD4 (srcArray.NeedPtr (row + r.top,
											   row + r.top,
											   FALSE)) + r.left);

		IF factor = 1 THEN
			count := r.right - r.left
		ELSE
			BEGIN
			count := (r.right - r.left + factor - 1) DIV factor;
			IF method = 0 THEN
				DoStepCopyBytes (srcPtr, gBuffer, count, factor, 1)
			ELSE
				DoScaleFactor (srcPtr, gBuffer, r.right - r.left, factor);
			srcPtr := gBuffer
			END;

		offset := offset1 + (offset2 - offset1) *
							(row + 0.5) / (r.bottom - r.top);

		DoSkewRow (srcPtr,
				   dstPtr,
				   count,
				   dstArray.fLogicalSize,
				   ROUND (256 * offset),
				   step,
				   method,
				   -1);

		srcArray.DoneWithPtr;
		dstArray.DoneWithPtr

		END;

	UpdateProgress (1, 1);

	srcArray.Flush;
	dstArray.Flush

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TCroppingTool.AngledCrop (srcArray: TVMArray; dstArray: TVMArray);

	VAR
		r: Rect;
		fi: FailInfo;
		buffer1: TVMArray;
		buffer2: TVMArray;
		offset1: EXTENDED;
		offset2: EXTENDED;
		oldWidth: EXTENDED;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		FreeObject (buffer1);
		FreeObject (buffer2);

		srcArray.Flush

		END;

	BEGIN

	buffer1 := NIL;
	buffer2 := NIL;

	CatchFailures (fi, CleanUp);

	r.top	 := Min (fNextCorners [0] . v, fNextCorners [1] . v);
	r.left	 := Min (fNextCorners [0] . h, fNextCorners [3] . h);
	r.bottom := Max (fNextCorners [2] . v, fNextCorners [3] . v);
	r.right  := Max (fNextCorners [1] . h, fNextCorners [2] . h);

	IF fNextCorners [0] . h > r.left THEN
		BEGIN

		offset1 := fNextCorners [0] . h - r.left;
		offset2 := offset1 * (fNextCorners [3] . v - r.bottom) /
							 (fNextCorners [3] . v - r.top	 );

		oldWidth := fNextCorners [2] . h - r.left - offset2

		END

	ELSE
		BEGIN

		offset2 := fNextCorners [3] . h - r.left;
		offset1 := offset2 * (r.top    - fNextCorners [0] . v) /
							 (r.bottom - fNextCorners [0] . v);

		oldWidth := fNextCorners [1] . h - r.left - offset1

		END;

	buffer1 := NewVMArray (r.bottom - r.top, dstArray.fLogicalSize, 1);

	StartTask (9/20);
	SkewArray (srcArray, buffer1, offset1, offset2, oldWidth, r);
	FinishTask;

	buffer2 := NewVMArray (buffer1.fLogicalSize, buffer1.fBlockCount, 1);

	StartTask (1/11);
	DoTransposeArray (buffer1, buffer2, FALSE, FALSE);
	FinishTask;

	buffer1.Free;
	buffer1 := NIL;

	offset1 := fNextCorners [0] . v - r.top;
	offset2 := fNextCorners [1] . v - r.top;

	oldWidth := fNextCorners [3] . v - fNextCorners [0] . v;

	SetRect (r, 0, 0, buffer2.fLogicalSize, buffer2.fBlockCount);

	buffer1 := NewVMArray (dstArray.fLogicalSize, dstArray.fBlockCount, 1);

	StartTask (9/10);
	SkewArray (buffer2, buffer1, offset1, offset2, oldWidth, r);
	FinishTask;

	buffer2.Free;
	buffer2 := NIL;

	DoTransposeArray (buffer1, dstArray, FALSE, FALSE);

	buffer1.Free;
	buffer1 := NIL;

	Success (fi)

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TCroppingTool.DoIt; OVERRIDE;

	VAR
		r: Rect;
		rr: Rect;
		fi: FailInfo;
		newCols: INTEGER;
		newRows: INTEGER;
		channel: INTEGER;
		aVMArray: TVMArray;
		killProgress: BOOLEAN;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF killProgress THEN
			FinishProgress;
		FreeObject (aVMArray);
		FailNewMessage (error, message, msgCannotCrop)
		END;

	BEGIN

	aVMArray := NIL;

	killProgress := FALSE;

	CatchFailures (fi, CleanUp);

	GetNewCorners;

	ComputeNewSize (newRows, newCols);

	FOR channel := 0 TO fDoc.fChannels - 1 DO
		BEGIN

		MoveHands (TRUE);

		aVMArray := NewVMArray (newRows, newCols, fDoc.Interleave (channel));
		fBuffer [channel] := aVMArray;

		aVMArray := NIL

		END;

	CommandProgress (fCmdNumber);

	killProgress := TRUE;

	FOR channel := 0 TO fDoc.fChannels - 1 DO
		BEGIN

		MoveHands (TRUE);

		StartTask (1 / (fDoc.fChannels - channel));

		IF (fNextCorners [0] . v = fNextCorners [1] . v) AND
		   (fNextCorners [0] . h = fNextCorners [3] . h) THEN
			BEGIN

			r.topLeft  := fNextCorners [0];
			r.botRight := fNextCorners [2];

			SetRect (rr, 0, 0, newCols, newRows);

			IF (r.right - r.left = newCols) AND
			   (r.bottom - r.top = newRows) THEN
				fDoc.fData [channel] . MoveRect (fBuffer [channel], r, rr)

			ELSE
				BEGIN

				aVMArray := fDoc.fData [channel] . CopyRect (r, 1);

				ResizeArray (aVMArray, fBuffer [channel],
							 fDoc.fMode = IndexedColorMode, TRUE);

				aVMArray.Free;
				aVMArray := NIL

				END

			END

		ELSE
			AngledCrop (fDoc.fData [channel], fBuffer [channel]);

		FinishTask

		END;

	Success (fi);

	FinishProgress;

	UndoIt;

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TCroppingTool.UndoIt; OVERRIDE;

	VAR
		tempStyle: TStyleInfo;

	PROCEDURE UndoEach (view: TImageView);
		BEGIN
		view.AdjustExtent;
		SetTopLeft (view, 0, 0)
		END;

	BEGIN

	fDoc.DeSelect (FALSE);

	fDoc.fRows := fBuffer [0] . fBlockCount;
	fDoc.fCols := fBuffer [0] . fLogicalSize;

	SwapAllChannels;

	tempStyle := fStyleInfo;
	fStyleInfo := fDoc.fStyleInfo;
	fDoc.fStyleInfo := tempStyle;

	fDoc.fViewList.Each (UndoEach);

	fDoc.UpdateStatus;
	fDoc.InvalRulers

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TCroppingTool.RedoIt; OVERRIDE;

	BEGIN
	UndoIt
	END;

{*****************************************************************************}

{$S ACropping}

FUNCTION DoCroppingTool (view: TImageView): TCommand;

	VAR
		doc: TImageDocument;
		aCroppingTool: TCroppingTool;

	BEGIN

	doc := TImageDocument (view.fDocument);

	IF doc.fMode = HalftoneMode THEN Failure (errNoHalftone, msgCannotCrop);

	IF NOT EmptyRect (doc.fSelectionRect) THEN
		DoCroppingTool := DropSelection (view)

	ELSE
		BEGIN

		NEW (aCroppingTool);
		FailNil (aCroppingTool);

		aCroppingTool.ICroppingTool (view);

		DoCroppingTool := aCroppingTool

		END

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE DoCroppingOptions;

	CONST
		kDialogID	= 1092;
		kHookItem	= 3;
		kWidthItem	= 4;
		kHeightItem = 6;
		kResItem	= 8;

	VAR
		fi: FailInfo;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		resUnit: TUnitSelector;
		widthUnit: TUnitSelector;
		heightUnit: TUnitSelector;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	widthUnit := aBWDialog.DefineSizeUnit (kWidthItem, gCroppingWidth.scale,
										   TRUE, FALSE, TRUE, FALSE, TRUE);

	IF gCroppingWidth.value <> 0 THEN
		widthUnit.StuffFixed (0, gCroppingWidth.value);

	heightUnit := aBWDialog.DefineSizeUnit (kHeightItem, gCroppingHeight.scale,
											TRUE, FALSE, FALSE, FALSE, TRUE);

	IF gCroppingHeight.value <> 0 THEN
		heightUnit.StuffFixed (0, gCroppingHeight.value);

	resUnit := aBWDialog.DefineResUnit (kResItem, gCroppingResolution.scale, 0);

	resUnit . fEditItem [0] . fBlankOK := TRUE;

	IF gCroppingResolution.value <> 0 THEN
		resUnit.StuffFixed (0, gCroppingResolution.value);

	aBWDialog.SetEditSelection (kWidthItem);

	aBWDialog.TalkToUser (hitItem, StdItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	gCroppingWidth.scale := widthUnit.fPick;
	gCroppingHeight.scale := heightUnit.fPick;
	gCroppingResolution.scale := resUnit.fPick;

	IF widthUnit . fEditItem [0] . fBlank THEN
		gCroppingWidth.value := 0
	ELSE
		gCroppingWidth.value := widthUnit.GetFixed (0);

	IF heightUnit . fEditItem [0] . fBlank THEN
		gCroppingHeight.value := 0
	ELSE
		gCroppingHeight.value := heightUnit.GetFixed (0);

	IF resUnit . fEditItem [0] . fBlank THEN
		gCroppingResolution.value := 0
	ELSE
		gCroppingResolution.value := resUnit.GetFixed (0);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TCropCommand.ICropCommand (view: TImageView);

	BEGIN

	IBufferCommand (cCrop, view);

	fRows := fDoc.fRows;
	fCols := fDoc.fCols;

	fSelectionRect := fDoc.fSelectionRect

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TCropCommand.DoIt; OVERRIDE;

	VAR
		r: Rect;
		channel: INTEGER;
		aVMArray: TVMArray;

	BEGIN

	r := fSelectionRect;

	FOR channel := 0 TO fDoc.fChannels - 1 DO
		BEGIN

		MoveHands (TRUE);

		IF fDoc.fMode = HalftoneMode THEN
			aVMArray := CopyHalftoneRect (fDoc.fData [0], r, 1)
		ELSE
			aVMArray := fDoc.fData [channel] . CopyRect
											   (r, fDoc.Interleave (channel));

		fBuffer [channel] := aVMArray

		END;

	RedoIt

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TCropCommand.UndoIt; OVERRIDE;

	VAR
		center: Point;

	PROCEDURE UndoEach (view: TImageView);
		BEGIN
		view.AdjustExtent;
		SetCenterPoint (view, center)
		END;

	BEGIN

	fDoc.DeSelect (FALSE);

	fDoc.fCols := fCols;
	fDoc.fRows := fRows;

	SwapAllChannels;

	center.h := BSR (ORD4 (fSelectionRect.left) + fSelectionRect.right, 1);
	center.v := BSR (ORD4 (fSelectionRect.bottom) + fSelectionRect.top, 1);

	fDoc.fViewList.Each (UndoEach);

	fDoc.UpdateStatus;

	IF MEMBER (gTarget, TImageView) THEN
		TImageView (gTarget) . ObscureSelection (0);

	fDoc.Select (fSelectionRect, NIL)

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TCropCommand.RedoIt; OVERRIDE;

	PROCEDURE RedoEach (view: TImageView);
		BEGIN
		view.AdjustExtent;
		SetTopLeft (view, 0, 0)
		END;

	BEGIN

	fDoc.DeSelect (FALSE);

	fDoc.fRows := fSelectionRect.bottom - fSelectionRect.top;
	fDoc.fCols := fSelectionRect.right - fSelectionRect.left;

	SwapAllChannels;

	fDoc.fViewList.Each (RedoEach);

	fDoc.UpdateStatus

	END;

{*****************************************************************************}

{$S ACropping}

FUNCTION DoCropCommand (view: TImageView): TCommand;

	VAR
		aCropCommand: TCropCommand;

	BEGIN

	NEW (aCropCommand);
	FailNil (aCropCommand);

	aCropCommand.ICropCommand (view);

	DoCropCommand := aCropCommand

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TRulerCommand.IRulerCommand (view: TImageView; pt: Point);

	BEGIN

	IBufferCommand (cRulerOrigin, view);

	fOldOrigin := fDoc.fRulerOrigin;
	fNewOrigin := pt;

	fCausesChange := FALSE

	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TRulerCommand.DoIt; OVERRIDE;

	BEGIN
	fDoc.fRulerOrigin := fNewOrigin;
	fDoc.InvalRulers
	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TRulerCommand.UndoIt; OVERRIDE;

	BEGIN
	fDoc.fRulerOrigin := fOldOrigin;
	fDoc.InvalRulers
	END;

{*****************************************************************************}

{$S ACropping}

PROCEDURE TRulerCommand.RedoIt; OVERRIDE;

	BEGIN
	DoIt
	END;

{*****************************************************************************}

{$S ACropping}

FUNCTION AdjustZeroPoint (view: TImageView): TCommand;

	VAR
		mag: INTEGER;
		limits: Rect;
		done: BOOLEAN;
		lastPt: Point;
		nextPt: Point;
		origin: Point;
		doc: TImageDocument;
		theEvent: EventRecord;
		aRulerCommand: TRulerCommand;

	PROCEDURE DrawCross;

		BEGIN

		PenPat (gray);
		PenMode (patXOR);

		MoveTo (lastPt.h, limits.top);
		LineTo (lastPt.h, limits.bottom);

		MoveTo (limits.left , lastPt.v);
		LineTo (limits.right, lastPt.v)

		END;

	BEGIN

	doc := TImageDocument (view.fDocument);

	SetToolCursor (MarqueeTool, FALSE);

	limits := view.fFrame.fContentRect;

	OffsetRect (limits, view.fFrame.fRelOrigin.h,
						view.fFrame.fRelOrigin.v);

	lastPt.h := -kMaxCoord;
	lastPt.v := -kMaxCoord;

	PenNormal;

		REPEAT

		view.TrackRulers;

		GetMouse (nextPt);

		done := NOT StillDown;

		IF done THEN
			IF GetNextEvent (mUpMask, theEvent) THEN
				BEGIN
				nextPt := theEvent.where;
				GlobalToLocal (nextPt)
				END;

		IF LONGINT (nextPt) <> LONGINT (lastPt) THEN
			BEGIN
			DrawCross;
			lastPt := nextPt;
			DrawCross
			END

		UNTIL done;

	DrawCross;

	PenNormal;

	mag := view.fMagnification;

	origin := doc.fRulerOrigin;

	IF (lastPt.h >= limits.left - 1) AND (lastPt.h <= limits.right) THEN
		BEGIN
		origin.h := lastPt.h + 1;
		IF mag >= 1 THEN
			origin.h := origin.h DIV mag
		ELSE
			origin.h := origin.h * (-mag)
		END;

	IF (lastPt.v >= limits.top - 1) AND (lastPt.v <= limits.bottom) THEN
		BEGIN
		origin.v := lastPt.v + 1;
		IF mag >= 1 THEN
			origin.v := origin.v DIV mag
		ELSE
			origin.v := origin.v * (-mag)
		END;

	IF LONGINT (doc.fRulerOrigin) = LONGINT (origin) THEN
		Failure (0, 0);

	NEW (aRulerCommand);
	FailNil (aRulerCommand);

	aRulerCommand.IRulerCommand (view, origin);

	AdjustZeroPoint := aRulerCommand

	END;

{*****************************************************************************}

END.

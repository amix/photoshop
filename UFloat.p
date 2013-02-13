{Photoshop version 1.0.1, file: UFloat.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UFloat;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	PickerIntf, UDialog, UBWDialog, UCommands, UFilters,
	URootFormat, UPICTFile, UPICTResource;

TYPE

	TMoveCommand = OBJECT (TFloatCommand)

		fDuplicate: BOOLEAN;

		fOutline: BOOLEAN;

		fNudge: BOOLEAN;

		fHome : Point;
		fDest : Point;
		fDelta: Point;

		fExactHome: BOOLEAN;

		fMovedOnce: BOOLEAN;

		fHysteresis: Point;

		fOutlineMag: INTEGER;
		fOutlineData: Handle;
		fOutlineVRect: Rect;
		fOutlineBounds: Rect;

		fBaseChangeCount: LONGINT;

		fPreparedFeedback: BOOLEAN;

		fSelectRect: Rect;
		fSelectMask: TVMArray;

		PROCEDURE TMoveCommand.IMoveCommand (view: TImageView;
											 duplicate: BOOLEAN;
											 outline: BOOLEAN;
											 nudge: Point;
											 VAR hysteresis: Point);

		PROCEDURE TMoveCommand.Free; OVERRIDE;

		PROCEDURE TMoveCommand.TrackConstrain
				(anchorPoint, previousPoint: Point;
				 VAR nextPoint: Point); OVERRIDE;

		PROCEDURE TMoveCommand.PrepareFeedback (downPoint: Point);

		PROCEDURE TMoveCommand.TrackFeedback
				(anchorPoint, nextPoint: Point;
				 turnItOn, mouseDidMove: BOOLEAN); OVERRIDE;

		FUNCTION TMoveCommand.TrackMouse
				(aTrackPhase: TrackPhase;
				 VAR anchorPoint, previousPoint, nextPoint: Point;
				 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

		PROCEDURE TMoveCommand.MoveFloat
				(pt: Point; obscure: BOOLEAN; canAbort: BOOLEAN);

		PROCEDURE TMoveCommand.SwapBelow;

		PROCEDURE TMoveCommand.SelectOverlap (r: Rect);

		PROCEDURE TMoveCommand.DoIt; OVERRIDE;

		PROCEDURE TMoveCommand.UndoIt; OVERRIDE;

		PROCEDURE TMoveCommand.RedoIt; OVERRIDE;

		END;

	TClipImageView = OBJECT (TView)

		fSize: Point;

		fMask: TVMArray;

		fMode: TDisplayMode;

		fResolution: FixedScaled;

		fData: ARRAY [0..2] OF TVMArray;

		fIndexedColorTable: TRGBLookUpTable;

		PROCEDURE TClipImageView.IClipImageView;

		PROCEDURE TClipImageView.Free; OVERRIDE;

		FUNCTION TClipImageView.ContainsClipType
				(aType: ResType): BOOLEAN; OVERRIDE;

		PROCEDURE TClipImageView.CompTransMap
				(iTable: TRGBLookUpTable; VAR map: TLookUpTable);

		PROCEDURE TClipImageView.WriteToDeskScrap; OVERRIDE;

		END;

	TCutCopyCommand = OBJECT (TFloatCommand)

		fDuplicate: BOOLEAN;

		PROCEDURE TCutCopyCommand.ICutCopyCommand (view: TImageView;
												   duplicate: BOOLEAN);

		PROCEDURE TCutCopyCommand.DoIt; OVERRIDE;

		PROCEDURE TCutCopyCommand.UndoIt; OVERRIDE;

		PROCEDURE TCutCopyCommand.RedoIt; OVERRIDE;

		END;

	TPasteCommand = OBJECT (TFloatCommand)

		fPasteMode: INTEGER;

		PROCEDURE TPasteCommand.IPasteCommand (view: TImageView;
											   pasteMode: INTEGER);

		PROCEDURE TPasteCommand.DoIt; OVERRIDE;

		PROCEDURE TPasteCommand.UndoIt; OVERRIDE;

		PROCEDURE TPasteCommand.RedoIt; OVERRIDE;

		END;

	TClearCommand = OBJECT (TFloatCommand)

		PROCEDURE TClearCommand.IClearCommand (view: TImageView);

		PROCEDURE TClearCommand.DoIt; OVERRIDE;

		PROCEDURE TClearCommand.UndoIt; OVERRIDE;

		PROCEDURE TClearCommand.RedoIt; OVERRIDE;

		END;

	TFillCommand = OBJECT (TFloatCommand)

		fWithPattern: BOOLEAN;

		fBlend: INTEGER;
		fMode: TPasteMode;

		fChannel: INTEGER;

		fWholeImage: BOOLEAN;

		fNeedOriginal: BOOLEAN;

		fOldControls: TPasteControls;
		fNewControls: TPasteControls;

		PROCEDURE TFillCommand.IFillCommand (itsCommand: INTEGER;
											 view: TImageView;
											 withPattern: BOOLEAN;
											 blend: INTEGER;
											 mode: TPasteMode);

		PROCEDURE TFillCommand.PatternFill (band: INTEGER;
											dstArray: TVMArray);

		PROCEDURE TFillCommand.DoFill (r: Rect;
									   maskArray: TVMArray;
									   floatArray: TRGBArrayList);

		PROCEDURE TFillCommand.DoIt; OVERRIDE;

		PROCEDURE TFillCommand.UndoIt; OVERRIDE;

		PROCEDURE TFillCommand.RedoIt; OVERRIDE;

		END;

	TFillBorderCommand = OBJECT (TFillCommand)

		fWidth: INTEGER;

		PROCEDURE TFillBorderCommand.IFillBorderCommand
				(view: TImageView;
				 width: INTEGER;
				 blend: INTEGER;
				 mode: TPasteMode);

		PROCEDURE TFillBorderCommand.DoFill
				(r: Rect;
				 maskArray: TVMArray;
				 floatArray: TRGBArrayList); OVERRIDE;

		END;

	TGradientTool = OBJECT (TFillCommand)

		fPt1: Point;
		fPt2: Point;

		fSpace: INTEGER;
		fRadial: BOOLEAN;
		fOffset: INTEGER;
		fMidpoint: INTEGER;

		PROCEDURE TGradientTool.IGradientTool
				(view: TImageView;
				 radial: BOOLEAN;
				 midpoint: INTEGER;
				 offset: INTEGER;
				 space: INTEGER);

		PROCEDURE TGradientTool.TrackConstrain
				(anchorPoint: Point;
				 previousPoint: Point;
				 VAR nextPoint: Point); OVERRIDE;

		PROCEDURE TGradientTool.TrackFeedBack
				(anchorPoint: Point;
				 nextPoint: Point;
				 turnItOn: BOOLEAN;
				 mouseDidMove: BOOLEAN); OVERRIDE;

		FUNCTION TGradientTool.TrackMouse
				(aTrackPhase: TrackPhase;
				 VAR anchorPoint, previousPoint, nextPoint: Point;
				 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

		PROCEDURE TGradientTool.DoFill
				(r: Rect;
				 maskArray: TVMArray;
				 floatArray: TRGBArrayList); OVERRIDE;

		END;

PROCEDURE InitFloatCommands;

FUNCTION GetClipSize (VAR width: INTEGER;
					  VAR height: INTEGER;
					  VAR resolution: FixedScaled;
					  VAR color: BOOLEAN): BOOLEAN;

FUNCTION DoMoveSelection (view: TImageView;
						  duplicate: BOOLEAN;
						  outline: BOOLEAN;
						  VAR hysteresis: Point): TCommand;

FUNCTION DoNudgeSelection (view: TImageView;
						   nudge: Point;
						   duplicate: BOOLEAN;
						   outline: BOOLEAN): TCommand;

FUNCTION ConvertPICTDeskScrap (size: LONGINT): TView;

FUNCTION DoCutCopyCommand (view: TImageView;
						   duplicate: BOOLEAN): TCommand;

FUNCTION DoPasteCommand (view: TImageView; pasteMode: INTEGER): TCommand;

FUNCTION DoClearCommand (view: TImageView): TCommand;

FUNCTION DoFillCommand (view: TImageView; options: BOOLEAN): TCommand;

FUNCTION DoGradientTool (view: TImageView): TCommand;

PROCEDURE DoGradientOptions;

IMPLEMENTATION

{$I UAssembly.a.inc}
{$I UConvert.a.inc}
{$I UFloat.a.inc}
{$I URotate.a.inc}
{$I USelect.p.inc}

CONST
	kObscureDelay = 180;

VAR
	gFillBlend: INTEGER;
	gFillOption: INTEGER;
	gFillBorder: INTEGER;
	gFillMode: TPasteMode;

	gGradientSpace: INTEGER;
	gGradientRadial: BOOLEAN;
	gGradientOffset: INTEGER;
	gGradientMidpoint: INTEGER;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitFloatCommands;

	BEGIN

	gFillOption := 0;
	gFillBorder := 1;
	gFillBlend	:= 100;
	gFillMode	:= PasteNormal;

	gGradientSpace	  := 0;
	gGradientRadial   := FALSE;
	gGradientOffset   := 0;
	gGradientMidpoint := 50

	END;

{*****************************************************************************}

{$S AOpen}

FUNCTION GetClipSize (VAR width: INTEGER;
					  VAR height: INTEGER;
					  VAR resolution: FixedScaled;
					  VAR color: BOOLEAN): BOOLEAN;

	BEGIN

	IF MEMBER (gClipView, TClipImageView) THEN
		BEGIN

		width  := TClipImageView (gClipView) . fSize . h;
		height := TClipImageView (gClipView) . fSize . v;

		resolution := TClipImageView (gClipView) . fResolution;

		color := TClipImageView (gClipView) . fMode IN
				 [IndexedColorMode, RGBColorMode];

		GetClipSize := TRUE

		END

	ELSE
		GetClipSize := FALSE

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TMoveCommand.IMoveCommand (view: TImageView;
									 duplicate: BOOLEAN;
									 outline: BOOLEAN;
									 nudge: Point;
									 VAR hysteresis: Point);

	VAR
		old: TMoveCommand;
		itsCommand: INTEGER;

	BEGIN

	fOutline   := outline;
	fDuplicate := duplicate;

	fNudge := LONGINT (nudge) <> 0;

	fOutlineMag  := 0;
	fOutlineData := NIL;

	fSelectMask := NIL;

	IF fOutline THEN
		IF fNudge THEN
			itsCommand := cNudgeOutline
		ELSE
			itsCommand := cMoveOutline
	ELSE IF fDuplicate THEN
		IF fNudge THEN
			itsCommand	:= cNudge
		ELSE
			itsCommand := cDuplicate
	ELSE
		itsCommand := cMove;

	IFloatCommand (itsCommand, view);

	fDelta := nudge;

	fConstrainsMouse := TRUE;
	fViewConstrain	 := FALSE;

	fMovedOnce := FALSE;

	fPreparedFeedback := FALSE;

	fBaseChangeCount := fDoc.fChangeCount;

	IF fWasFloating AND NOT fOutline THEN

		IF MEMBER (gLastCommand, TMoveCommand) &
				(gLastCommand.fChangedDocument = fDoc) &
				NOT TMoveCommand (gLastCommand) . fOutline THEN
			BEGIN

			old := TMoveCommand (gLastCommand);

			fHome	   := old.fHome;
			fExactHome := old.fExactHome;

			fOutlineMag    := old.fOutlineMag;
			fOutlineData   := old.fOutlineData;
			fOutlineVRect  := old.fOutlineVRect;
			fOutlineBounds := old.fOutlineBounds;

			fBaseChangeCount := old.fBaseChangeCount;

			old.fOutlineMag  := 0;
			old.fOutlineData := NIL

			END

		ELSE
			BEGIN
			fHome	   := fDoc.fFloatRect.topLeft;
			fExactHome := fDoc.fExactFloat
			END

	ELSE
		BEGIN
		fHome	   := fDoc.fSelectionRect.topLeft;
		fExactHome := not fDuplicate
		END;

	IF MEMBER (gLastCommand, TMoveCommand) THEN
		BEGIN

		old := TMoveCommand (gLastCommand);

		IF old.fOutlineData <> NIL THEN
			BEGIN
			FreeLargeHandle (old.fOutlineData);
			old.fOutlineData := NIL
			END;

		old.fOutlineMag := 0

		END;

	IF fWasFloating OR fDuplicate OR fOutline THEN
		BEGIN
		hysteresis.h := 1;
		hysteresis.v := 1
		END;

	fHysteresis := hysteresis

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TMoveCommand.Free; OVERRIDE;

	BEGIN

	IF fOutlineData <> NIL THEN
		FreeLargeHandle (fOutlineData);

	FreeObject (fSelectMask);

	INHERITED Free

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TMoveCommand.TrackConstrain
		(anchorPoint, previousPoint: Point; VAR nextPoint: Point); OVERRIDE;

	VAR
		x: INTEGER;
		mag: INTEGER;
		delta: Point;
		theKeys: KeyMap;
		shiftDown: BOOLEAN;

	BEGIN

	fView.TrackRulers;

	GetKeys (theKeys);

	shiftDown := theKeys [kShiftCode];

	IF shiftDown THEN
		BEGIN

		delta.h := nextPoint.h - anchorPoint.h;
		delta.v := nextPoint.v - anchorPoint.v;

		IF ABS (delta.h) >= 2 * ABS (delta.v) THEN
			delta.v := 0
		ELSE IF ABS (delta.v) >= 2 * ABS (delta.h) THEN
			delta.h := 0
		ELSE
			BEGIN
			x := Min (ABS (delta.h), ABS (delta.v));
			IF delta.v > 0 THEN
				delta.v := x
			ELSE
				delta.v := -x;
			IF delta.h > 0 THEN
				delta.h := x
			ELSE
				delta.h := -x
			END;

		nextPoint.h := anchorPoint.h + delta.h;
		nextPoint.v := anchorPoint.v + delta.v

		END;

	mag := fView.fMagnification;

	IF mag > 1 THEN
		BEGIN
		nextPoint.h := nextPoint.h DIV mag * mag;
		nextPoint.v := nextPoint.v DIV mag * mag
		END

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TMoveCommand.PrepareFeedback (downPoint: Point);

	CONST
		kWatchSize = 32000;

	VAR
		r: Rect;
		r1: Rect;
		r2: Rect;
		pt: Point;
		map: BitMap;
		mag: INTEGER;
		bounds: Rect;
		size: LONGINT;
		mask: TVMArray;
		width: INTEGER;
		height: INTEGER;
		theScreen: GDHandle;

	BEGIN

	mag := fView.fMagnification;

	IF fWasFloating AND NOT fOutline THEN
		BEGIN
		r	 := fDoc.fFloatRect;
		mask := fDoc.fFloatMask
		END
	ELSE
		BEGIN
		r	 := fDoc.fSelectionRect;
		mask := fDoc.fSelectionMask
		END;

	pt := r.topLeft;
	fView.CvtImage2View (pt, kRoundDown);

	r1 := r;
	OffsetRect (r1, -r1.left, -r1.top);
	fView.CvtImage2View (r1.botRight, kRoundUp);

	OffSetRect (r1, pt.h, pt.v);

	IF mask = NIL THEN
		fOutlineBounds := r1

	ELSE
		BEGIN

		theScreen := fView.GetScreen;

		IF theScreen = NIL THEN
			bounds := screenBits.bounds
		ELSE
			bounds := theScreen^^.gdRect;

		width  := bounds.right - bounds.left;
		height := bounds.bottom - bounds.top;

		r2.top	  := downPoint.v - height - 16;
		r2.left   := downPoint.h - width  - 16;
		r2.bottom := downPoint.v + height + 16;
		r2.right  := downPoint.h + width  + 16;

		IF SectRect (r1, r2, r2) THEN
			OffsetRect (r2, -r1.left, -r1.top)
		ELSE
			r2 := gZeroRect;

		IF (fOutlineMag <> mag) |
		   (r2.top	  < fOutlineVRect.top	) |
		   (r2.left   < fOutlineVRect.left	) |
		   (r2.bottom > fOutlineVRect.bottom) |
		   (r2.right  > fOutlineVRect.right ) THEN
			BEGIN

			IF fOutlineData <> NIL THEN
				BEGIN
				FreeLargeHandle (fOutlineData);
				fOutlineData := NIL
				END;

			fOutlineVRect := r2;

			IF NOT EmptyRect (r2) THEN
				BEGIN

				map.bounds	 := r2;
				map.rowBytes := BSL (BSR (r2.right - r2.left + 15, 4), 1);

				size := ORD4 (r2.bottom - r2.top) * map.rowBytes;

				IF size > kWatchSize THEN
					MoveHands (FALSE);

				fOutlineData := NewLargeHandle (size);

				HLock (fOutlineData);

				map.baseAddr := fOutlineData^;

				OffsetRect (r, -r.left, -r.top);

				DrawMaskOutline (map, mask, r, mag);

				HUnlock (fOutlineData);

				SetToolCursor (MoveTool, TRUE)

				END

			END;

		fOutlineBounds := fOutlineVRect;

		{$H-}
		OffsetRect (fOutlineBounds, r1.left, r1.top);
		{$H+}

		END;

	fOutlineMag := mag

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TMoveCommand.TrackFeedback
		(anchorPoint, nextPoint: Point;
		 turnItOn, mouseDidMove: BOOLEAN); OVERRIDE;

	VAR
		r: Rect;
		vr: Rect;
		map: BitMap;
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		VAR
			newMsg: LONGINT;

		BEGIN

		IF fOutline THEN
			newMsg := msgCannotMoveOutline
		ELSE IF fDuplicate THEN
			newMsg := msgCannotDuplicate
		ELSE
			newMsg := msgCannotMove;

		Free;

		FailNewMessage (error, message, newMsg)

		END;

	BEGIN

	IF NOT fPreparedFeedback THEN
		BEGIN

		CatchFailures (fi, CleanUp);

		PrepareFeedback (anchorPoint);
		fPreparedFeedback := TRUE;

		Success (fi)

		END;

	IF mouseDidMove THEN
		IF NOT EqualPt (nextPoint, anchorPoint) THEN
			BEGIN

			r := fOutlineBounds;

			OffsetRect (r, nextPoint.h - anchorPoint.h,
						   nextPoint.v - anchorPoint.v);

			IF fOutlineData = NIL THEN
				FrameRect (r)

			ELSE
				BEGIN

				fView.fFrame.GetViewedRect (vr);

				IF SectRect (r, vr, vr) THEN
					BEGIN

					HLock (fOutlineData);

					map.bounds	 := r;
					map.rowBytes := BSL (BSR (r.right - r.left + 15, 4), 1);
					map.baseAddr := fOutlineData^;

					CopyBits (map, thePort^.portBits, vr, vr, srcXor, NIL);

					HUnlock (fOutlineData)

					END

				END

			END

	END;

{*****************************************************************************}

{$S ADoFloat}

FUNCTION TMoveCommand.TrackMouse
		(aTrackPhase: TrackPhase;
		 VAR anchorPoint, previousPoint, nextPoint: Point;
		 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

	VAR
		pt: Point;
		fi: FailInfo;
		mag: INTEGER;
		peekEvent: EventRecord;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		TrackMouse := gNoChanges;
		EXIT (TrackMouse)
		END;

	BEGIN

	TrackMouse := SELF;

	IF mouseDidMove THEN

		CASE aTrackPhase OF

		trackMove:
			fMovedOnce := TRUE;

		trackRelease:
			BEGIN

			IF EventAvail (mUpMask, peekEvent) THEN
				BEGIN

				pt := peekEvent.where;

				GlobalToLocal (pt);

				IF (ABS (pt.h - anchorPoint.h) >= fHysteresis.h) OR
				   (ABS (pt.v - anchorPoint.v) >= fHysteresis.v) THEN
					BEGIN
					nextPoint := pt;
					TrackConstrain (anchorPoint, previousPoint, nextPoint)
					END

				END;

			fDelta.h := nextPoint.h - anchorPoint.h;
			fDelta.v := nextPoint.v - anchorPoint.v;

			mag := fView.fMagnification;

			IF mag > 1 THEN
				BEGIN
				fDelta.h := fDelta.h DIV mag;
				fDelta.v := fDelta.v DIV mag
				END

			ELSE IF mag < 1 THEN
				BEGIN
				fDelta.h := fDelta.h * (-mag);
				fDelta.v := fDelta.v * (-mag)
				END;

			IF LONGINT (fDelta) = 0 THEN

				IF NOT fMovedOnce THEN
					BEGIN
					CatchFailures (fi, CleanUp);
					TrackMouse := DropSelection (fView);
					Success (fi)
					END

				ELSE IF NOT fWasFloating AND NOT fDuplicate THEN
					TrackMouse := gNoChanges

			END

		END

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TMoveCommand.MoveFloat (pt: Point;
								  obscure: BOOLEAN;
								  canAbort: BOOLEAN);

	VAR
		r: Rect;
		r1: Rect;
		r2: Rect;
		fi: FailInfo;
		fi2: FailInfo;
		oldRect: Rect;
		newRect: Rect;
		mask: TVMArray;
		width: INTEGER;
		height: INTEGER;
		canMove: BOOLEAN;
		saveExact: BOOLEAN;
		selectError: OSErr;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (mask)
		END;

	PROCEDURE CleanUp2 (error: INTEGER; message: LONGINT);
		BEGIN
		CopyBelow (FALSE);
		fDoc.fFloatRect  := oldRect;
		fDoc.fExactFloat := saveExact;
		CopyBelow (TRUE);
		BlendFloat (FALSE);
		IF NOT canMove THEN SelectFloat
		END;

	BEGIN

	MoveHands (canAbort);

	oldRect := fDoc.fFloatRect;

	width  := oldRect.right - oldRect.left;
	height := oldRect.bottom - oldRect.top;

	newRect.topLeft := pt;
	newRect.bottom	:= newRect.top + height;
	newRect.right	:= newRect.left + width;

	ComputeOverlap (r1);

	fDoc.fFloatRect := newRect;
	ComputeOverlap (r2);
	fDoc.fFloatRect := oldRect;

	canMove := fDoc.fSelectionFloating AND
			   (r1.bottom - r1.top = height) AND
			   (r2.bottom - r2.top = height) AND
			   (r1.right - r1.left = width) AND
			   (r2.right - r2.left = width);

	IF NOT canMove THEN
		BEGIN

		fDoc.DeSelect (NOT fDoc.fSelectionFloating);

		fDoc.fFloatRect := newRect;
		selectError := CanSelect (r, mask);
		fDoc.fFloatRect := oldRect;

		IF selectError <> noErr THEN
			Failure (selectError, msgCannotMove)

		END

	ELSE
		mask := NIL;

	CatchFailures (fi, CleanUp);

	CopyBelow (FALSE);

	saveExact := fDoc.fExactFloat;

	fDoc.fFloatRect := newRect;

	fDoc.fExactFloat := fExactHome AND
						(LONGINT (pt) = LONGINT (fHome));

	CopyBelow (TRUE);

	CatchFailures (fi2, CleanUp2);

	BlendFloat (canAbort AND saveExact);

	Success (fi2);

	UpdateRects (r1, r2, FALSE);

	Success (fi);

	obscure := obscure AND
			   ((r2.bottom - r2.top = 1) OR
				(r2.right - r2.left = 1));

	IF obscure THEN
		fView.ObscureSelection (kObscureDelay);

	IF canMove THEN
		fDoc.MoveSelection (r2)
	ELSE
		BEGIN
		fDoc.Select (r, mask);
		fDoc.fSelectionFloating := NOT EmptyRect (r)
		END;

	IF obscure THEN
		fView.ObscureSelection (kObscureDelay)

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TMoveCommand.SwapBelow;

	VAR
		save: TVMArray;
		channel: INTEGER;

	BEGIN

	FOR channel := 0 TO 2 DO
		IF fBuffer [channel] <> NIL THEN
			BEGIN
			save					   := fBuffer		   [channel];
			fBuffer 		 [channel] := fDoc.fFloatBelow [channel];
			fDoc.fFloatBelow [channel] := save
			END

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TMoveCommand.SelectOverlap (r: Rect);

	VAR
		rr: Rect;
		rrr: Rect;
		gray: INTEGER;
		solid: BOOLEAN;
		hist: THistogram;
		overlap: BOOLEAN;

	BEGIN

	rr := r;

	fDoc.SectBoundsRect (rr);

	IF EmptyRect (rr) THEN
		fDoc.DeSelect (TRUE)

	ELSE IF fSelectMask = NIL THEN
		fDoc.Select (rr, NIL)

	ELSE IF EqualRect (r, rr) THEN
		fDoc.Select (rr, fSelectMask.CopyArray (1))

	ELSE
		BEGIN

		rrr := rr;
		OffsetRect (rrr, -r.left, -r.top);

		fSelectMask.FindInnerBounds (rrr);

		fSelectMask.HistRect (rrr, hist);

		overlap := FALSE;
		FOR gray := 128 TO 255 DO
			overlap := overlap OR (hist [gray] <> 0);

		solid := TRUE;
		FOR gray := 0 TO 254 DO
			solid := solid AND (hist [gray] = 0);

		IF overlap THEN
			BEGIN

			rr := rrr;
			OffsetRect (rr, r.left, r.top);

			IF solid THEN
				fDoc.Select (rr, NIL)
			ELSE
				fDoc.Select (rr, fSelectMask.CopyRect (rrr, 1))

			END

		ELSE
			fDoc.DeSelect (TRUE)

		END;

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TMoveCommand.DoIt; OVERRIDE;

	VAR
		r: Rect;
		fi: FailInfo;
		channel: INTEGER;
		aVMArray: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		VAR
			newMsg: LONGINT;

		BEGIN

			CASE fCmdNumber OF
			cMove:			newMsg := msgCannotMove;
			cDuplicate: 	newMsg := msgCannotDuplicate;
			cNudge: 		newMsg := msgCannotNudge;
			cMoveOutline:	newMsg := msgCannotMoveOutline;
			cNudgeOutline:	newMsg := msgCannotNudgeOutline
			END;

		FailNewMessage (error, message, newMsg)

		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	MoveHands (TRUE);

	IF fOutline THEN
		BEGIN

		IF fWasFloating THEN
			FloatSelection (FALSE);

		fSelectRect := fDoc.fSelectionRect;

		IF fDoc.fSelectionMask <> NIL THEN
			fSelectMask := fDoc.fSelectionMask.CopyArray (1);

		r := fSelectRect;
		OffsetRect (r, fDelta.h, fDelta.v);

		SelectOverlap (r)

		END

	ELSE
		BEGIN

		FloatSelection (fDuplicate);

		IF fDuplicate THEN
			BEGIN

			IF fWasFloating THEN
				BEGIN

				FOR channel := 0 TO 2 DO
					IF fDoc.fFloatBelow [channel] <> NIL THEN
						BEGIN
						aVMArray := fDoc.fFloatBelow [channel] . CopyArray (1);
						fBuffer [channel] := aVMArray
						END;

				CopyBelow (TRUE);

				END;

			fHome := fDoc.fFloatRect.topLeft;
			fExactHome := FALSE;

			fDoc.fExactFloat := FALSE

			END;

		fDest.v := fDoc.fFloatRect.top	+ fDelta.v;
		fDest.h := fDoc.fFloatRect.left + fDelta.h;

		IF LONGINT (fDelta) <> 0 THEN
			MoveFloat (fDest, fNudge, NOT fDuplicate)

		END;

	Success (fi);

	fCausesChange := (LONGINT (fDest) <> LONGINT (fHome)) AND NOT fOutline;

	fCanUndo := fCausesChange OR fDuplicate OR fOutline;

	fDoc.fChangeCount := fBaseChangeCount

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TMoveCommand.UndoIt; OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	IF fOutline THEN

		IF fWasFloating THEN
			SelectFloat

		ELSE
			BEGIN
			r := fSelectRect;
			SelectOverlap (r)
			END

	ELSE
		BEGIN

		IF LONGINT (fDest) <> LONGINT (fHome) THEN
			MoveFloat (fHome, FALSE, FALSE);

		SwapBelow

		END

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TMoveCommand.RedoIt; OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	IF fOutline THEN
		BEGIN

		r := fSelectRect;
		OffsetRect (r, fDelta.h, fDelta.v);

		SelectOverlap (r)

		END

	ELSE
		BEGIN

		SwapBelow;

		IF LONGINT (fDest) <> LONGINT (fHome) THEN
			MoveFloat (fDest, fNudge, FALSE)

		END

	END;

{*****************************************************************************}

{$S ADoFloat}

FUNCTION DoMoveSelection (view: TImageView;
						  duplicate: BOOLEAN;
						  outline: BOOLEAN;
						  VAR hysteresis: Point): TCommand;

	VAR
		aMoveCommand: TMoveCommand;

	BEGIN

	NEW (aMoveCommand);
	FailNil (aMoveCommand);

	aMoveCommand.IMoveCommand (view,
							   duplicate,
							   outline,
							   Point (0),
							   hysteresis);

	DoMoveSelection := aMoveCommand

	END;

{*****************************************************************************}

{$S ADoFloat}

FUNCTION DoNudgeSelection (view: TImageView;
						   nudge: Point;
						   duplicate: BOOLEAN;
						   outline: BOOLEAN): TCommand;

	VAR
		hysteresis: Point;
		doc: TImageDocument;
		aMoveCommand: TMoveCommand;

	BEGIN

	MoveHands (TRUE);

	doc := TImageDocument (view.fDocument);

	IF EmptyRect (doc.fSelectionRect) THEN Failure (0, 0);

	NEW (aMoveCommand);
	FailNil (aMoveCommand);

	aMoveCommand.IMoveCommand (view, duplicate, outline, nudge, hysteresis);

	DoNudgeSelection := aMoveCommand

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TClipImageView.IClipImageView;

	BEGIN

	fMask := NIL;

	fData [0] := NIL;
	fData [1] := NIL;
	fData [2] := NIL;

	IView (NIL, NIL, gZeroRect, sizeFixed, sizeFixed, TRUE, hlOff);

	fWouldMakePICTScrap := FALSE;

	fIndexedColorTable.R := gNullLUT;
	fIndexedColorTable.G := gNullLUT;
	fIndexedColorTable.B := gNullLUT

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TClipImageView.Free; OVERRIDE;

	BEGIN

	FreeObject (fMask);

	FreeObject (fData [0]);
	FreeObject (fData [1]);
	FreeObject (fData [2]);

	INHERITED Free

	END;

{*****************************************************************************}

{$S ARes}

FUNCTION TClipImageView.ContainsClipType (aType: ResType): BOOLEAN; OVERRIDE;

	BEGIN

	ContainsClipType := (aType = kClipDataType)

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TClipImageView.CompTransMap (iTable: TRGBLookUpTable;
									   VAR map: TLookUpTable);

	VAR
		r,g,b: CHAR;
		j,k: INTEGER;
		found: BOOLEAN;
		hist: THistogram;

	BEGIN

	IF fMode = RGBColorMode THEN
		Failure (errRGBClipboard, 0);

	IF fMode = HalftoneMode THEN
		FOR j := 1 TO 254 DO
			hist [j] := ORD ((j = 0) OR (j = 255))
	ELSE
		fData [0] . HistBytes (hist);

	map := gNullLUT;

	FOR j := 0 TO 255 DO
		IF hist [j] <> 0 THEN
			BEGIN

			found := FALSE;

			r := fIndexedColorTable.R [j];
			g := fIndexedColorTable.G [j];
			b := fIndexedColorTable.B [j];

			FOR k := 0 TO 255 DO
				IF (r = iTable.R [k]) &
				   (g = iTable.G [k]) &
				   (b = iTable.B [k]) THEN
					BEGIN
					map [j] := CHR (k);
					found := TRUE;
					LEAVE
					END;

			IF NOT found THEN
				Failure (errDiffTables, 0)

			END

	END;

{*****************************************************************************}

{$S AClipboard}

PROCEDURE ReportExportFailed (why: OSErr);

	CONST
		kWaitTime = 180;
		kExportFailed = 905;

	VAR
		x: BOOLEAN;
		fi: FailInfo;
		temp: LONGINT;
		errStr: Str255;
		aBWDialog: TBWDialog;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		EXIT (ReportExportFailed)
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	x := LookupErrString (why, errReasonID, errStr);

	ParamText (errStr, '', '', '');

	NEW (aBWDialog);
	FailNIL (aBWDialog);

	aBWDialog.IBWDialog (kExportFailed, 0, 0);

	ShowWindow (aBWDialog.fDialogPtr);
	DrawDialog (aBWDialog.fDialogPtr);

	SetCursor (arrow);

	SysBeep (1);

	Delay (kWaitTime, temp);

	aBWDialog.Free;

	Success (fi)

	END;

{*****************************************************************************}

{$S AClipboard}

PROCEDURE TClipImageView.WriteToDeskScrap; OVERRIDE;

	LABEL
		1;

	CONST
		kConvertingToPICT = 904;
		kAskLargeClipID   = 916;
		kLargeClipboard   = 100 * 1024;

	VAR
		r: INTEGER;
		g: INTEGER;
		b: INTEGER;
		fi: FailInfo;
		row: INTEGER;
		maskPtr: Ptr;
		dataPtr: Ptr;
		wp: WindowPtr;
		gray: INTEGER;
		dist: INTEGER;
		best: INTEGER;
		index: INTEGER;
		thePICT: Handle;
		channel: INTEGER;
		map: TLookUpTable;
		clipSize: LONGINT;
		aVMArray: TVMArray;
		doc: TImageDocument;
		freeDialog: BOOLEAN;
		aBWDialog: TBWDialog;

	PROCEDURE FreeStuff;
		BEGIN

		IF freeDialog THEN
			aBWDialog.Free;

		IF doc <> NIL THEN
			BEGIN

			IF fMask = NIL THEN
				BEGIN
				doc.fData [0] := NIL;
				doc.fData [1] := NIL;
				doc.fData [2] := NIL
				END;

			doc.Free

			END;

		IF thePICT <> NIL THEN
			FreeLargeHandle (thePICT);

		IF maskPtr <> NIL THEN
			BEGIN
			fMask.DoneWithPtr;
			fMask.Flush
			END

		END;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeStuff;
		ReportExportFailed (error);
		GOTO 1
		END;

	BEGIN

	IF gPreferences.fClipOption = 0 THEN
		EXIT (WriteToDeskScrap);

	IF gAppDone THEN
		BEGIN

		clipSize := fSize.h * ORD4 (fSize.v);

			CASE fMode OF

			HalftoneMode:
				clipSize := clipSize DIV 8;

			RGBColorMode:
				clipSize := clipSize * 3

			END;

		IF clipSize > kLargeClipboard THEN
			IF BWAlert (kAskLargeClipID, 0, TRUE) = cancel THEN
				EXIT (WriteToDeskScrap)

		END;

	doc := NIL;
	thePICT := NIL;
	maskPtr := NIL;
	freeDialog := FALSE;

	CatchFailures (fi, CleanUp);

	NEW (aBWDialog);
	FailNIL (aBWDialog);

	aBWDialog.IBWDialog (kConvertingToPICT, 0, 0);

	freeDialog := TRUE;

	ShowWindow (aBWDialog.fDialogPtr);
	DrawDialog (aBWDialog.fDialogPtr);

	MoveHands (FALSE);

	doc := TImageDocument (gApplication.DoMakeDocument (cCopy));

	doc.fMode := fMode;

	doc.fRows := fSize.v;
	doc.fCols := fSize.h;

	doc.fStyleInfo.fResolution := fResolution;

	IF fMode = RGBColorMode THEN
		doc.fChannels := 3
	ELSE IF fMode = HalftoneMode THEN
		doc.fDepth := 1;

	doc.fIndexedColorTable := fIndexedColorTable;

	r := BSR (gBackgroundColor.red	, 8);
	g := BSR (gBackgroundColor.green, 8);
	b := BSR (gBackgroundColor.blue , 8);

	IF fMode = IndexedColorMode THEN
		BEGIN
		best := 768;
		FOR index := 0 TO 255 DO
			BEGIN
			dist := ABS (r - ORD (fIndexedColorTable.R [index])) +
					ABS (g - ORD (fIndexedColorTable.G [index])) +
					ABS (b - ORD (fIndexedColorTable.B [index]));
			IF dist < best THEN
				BEGIN
				gray := index;
				best := dist
				END
			END
		END
	ELSE
		gray := ORD (ConvertToGray (r, g, b));

	IF fMask = NIL THEN
		FOR channel := 0 TO doc.fChannels - 1 DO
			doc.fData [channel] := fData [channel]

	ELSE IF fMode = HalftoneMode THEN
		BEGIN

		aVMArray := fData [0] . CopyArray (1);

		doc.fData [0] := aVMArray;

		IF gray < 128 THEN
			aVMArray.MapBytes (gInvertLUT);

		FOR row := 0 TO doc.fRows - 1 DO
			BEGIN

			maskPtr := fMask.NeedPtr (row, row, FALSE);

			DoMaskBinary (maskPtr,
						  aVMArray.NeedPtr (row, row, TRUE),
						  doc.fCols);

			aVMArray.DoneWithPtr;
			fMask.DoneWithPtr;

			maskPtr := NIL

			END;

		aVMArray.Flush;
		fMask.Flush;

		IF gray < 128 THEN
			aVMArray.MapBytes (gInvertLUT)

		END

	ELSE
		FOR channel := 0 TO doc.fChannels - 1 DO
			BEGIN

			aVMArray := NewVMArray (fData [0] . fBlockCount,
									fData [0] . fLogicalSize,
									doc.fChannels - channel);

			doc.fData [channel] := aVMArray;

			IF fMode = IndexedColorMode THEN
				BEGIN
				DoSetBytes (@map [	0], 128,   0);
				DoSetBytes (@map [128], 128, 255)
				END;

			IF fMode <> RGBColorMode THEN
				aVMArray.SetBytes (gray)
			ELSE
				CASE channel OF
				0:	aVMArray.SetBytes (r);
				1:	aVMArray.SetBytes (g);
				2:	aVMArray.SetBytes (b)
				END;

			FOR row := 0 TO doc.fRows - 1 DO
				BEGIN

				dataPtr := aVMArray.NeedPtr (row, row, TRUE);
				maskPtr := fMask.NeedPtr (row, row, FALSE);

				BlockMove (maskPtr, gBuffer, doc.fCols);

				IF fMode = IndexedColorMode THEN
					DoMapBytes (gBuffer, doc.fCols, map);

				DoBlendBelow (gBuffer,
							  fData [channel] . NeedPtr (row, row, FALSE),
							  dataPtr,
							  doc.fCols,
							  0,
							  -1);

				fData [channel] . DoneWithPtr;
				aVMArray.DoneWithPtr;
				fMask.DoneWithPtr;

				maskPtr := NIL

				END;

			fData [channel] . Flush;
			aVMArray.Flush;
			fMask.Flush

			END;

	thePICT := gClipFormat.MakePICT (doc);

	FailOSErr (PutDeskScrapData ('PICT', thePICT));

	Success (fi);

	FreeStuff;

	1:	{ Error reentry point}

	wp := FrontWindow;

	IF wp <> NIL THEN
		IF WindowPeek (wp)^ . windowKind >= 0 THEN
			HiliteWindow (wp, FALSE)

	END;

{*****************************************************************************}

{$S AClipboard}

FUNCTION ConvertPICTDeskScrap (size: LONGINT): TView;

	CONST
		kConvertingFromPICT = 906;

	VAR
		fi: FailInfo;
		offset: LONGINT;
		thePICT: Handle;
		doc: TImageDocument;
		freeDialog: BOOLEAN;
		aBWDialog: TBWDialog;
		aClipImageView: TClipImageView;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		IF freeDialog THEN
			aBWDialog.Free;

		IF doc <> NIL THEN
			doc.Free;

		IF thePICT <> NIL THEN
			FreeLargeHandle (thePICT)

		END;

	BEGIN

	doc := NIL;
	thePICT := NIL;
	freeDialog := FALSE;

	CatchFailures (fi, CleanUp);

	thePICT := NewLargeHandle (size);

	NEW (aBWDialog);
	FailNIL (aBWDialog);

	aBWDialog.IBWDialog (kConvertingFromPICT, 0, 0);

	freeDialog := TRUE;

	ShowWindow (aBWDialog.fDialogPtr);
	DrawDialog (aBWDialog.fDialogPtr);

	MoveHands (FALSE);

	FailOSErr (Min (0, GetScrap (thePICT, 'PICT', offset)));

	doc := TImageDocument (gApplication.DoMakeDocument (cPaste));

	gClipFormat.ConvertPICT (thePICT, doc);

	FreeLargeHandle (thePICT);
	thePICT := NIL;

	NEW (aClipImageView);
	FailNil (aClipImageView);

	aClipImageView.IClipImageView;

	aClipImageView.fWrittenToDeskScrap := TRUE;

	aClipImageView.fSize.v := doc.fRows;
	aClipImageView.fSize.h := doc.fCols;

	aClipImageView.fMode := doc.fMode;

	aClipImageView.fResolution := doc.fStyleInfo.fResolution;

	IF doc.fMode = IndexedColorMode THEN
		aClipImageView.fIndexedColorTable := doc.fIndexedColorTable;

	aClipImageView.fMask := NIL;

	aClipImageView.fData [0] := doc.fData [0];
	aClipImageView.fData [1] := doc.fData [1];
	aClipImageView.fData [2] := doc.fData [2];

	doc.fData [0] := NIL;
	doc.fData [1] := NIL;
	doc.fData [2] := NIL;

	doc.Free;
	doc := NIL;

	Success (fi);

	CleanUp (0, 0);

	ConvertPICTDeskScrap := aClipImageView

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TCutCopyCommand.ICutCopyCommand (view: TImageView;
										   duplicate: BOOLEAN);

	BEGIN

	fDuplicate := duplicate;

	IF duplicate THEN
		IFloatCommand (cCopy, view)
	ELSE
		IFloatCommand (cCut, view);

	fChangesClipboard := TRUE;

	fCausesChange := NOT duplicate;

	fCanUndo := (fDoc.fDepth = 8)

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TCutCopyCommand.DoIt; OVERRIDE;

	VAR
		r: Rect;
		fi: FailInfo;
		channel: INTEGER;
		aVMArray: TVMArray;
		aClipImageView: TClipImageView;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aClipImageView.Free
		END;

	BEGIN

	MoveHands (FALSE);

	NEW (aClipImageView);
	FailNil (aClipImageView);

	aClipImageView.IClipImageView;

	CatchFailures (fi, CleanUp);

	aClipImageView.fResolution := fDoc.fStyleInfo.fResolution;

	IF fDoc.fMode = HalftoneMode THEN
		BEGIN

		aClipImageView.fMode := HalftoneMode;

		r := fDoc.fSelectionRect;

		aClipImageView.fSize.h := r.right - r.left;
		aClipImageView.fSize.v := r.bottom - r.top;

		IF fDoc.fSelectionMask <> NIL THEN
			BEGIN
			aVMArray := fDoc.fSelectionMask.CopyArray (1);
			aClipImageView.fMask := aVMArray
			END;

		aVMArray := CopyHalftoneRect (fDoc.fData [0], r, 1);
		aClipImageView.fData [0] := aVMArray

		END

	ELSE
		BEGIN

		FloatSelection (fDuplicate);

		IF NOT fWasFloating THEN
			fDoc.fExactFloat := TRUE;

		r := fDoc.fFloatRect;

		aClipImageView.fSize.h := r.right - r.left;
		aClipImageView.fSize.v := r.bottom - r.top;

		IF fDoc.fMode = IndexedColorMode THEN
			BEGIN
			aClipImageView.fMode := IndexedColorMode;
			aClipImageView.fIndexedColorTable := fDoc.fIndexedColorTable
			END

		ELSE IF fDoc.fFloatChannel = kRGBChannels THEN
			aClipImageView.fMode := RGBColorMode

		ELSE
			aClipImageView.fMode := MonochromeMode;

		IF fDoc.fFloatMask <> NIL THEN
			BEGIN
			aVMArray := fDoc.fFloatMask.CopyArray (1);
			aClipImageView.fMask := aVMArray
			END;

		IF fDoc.fFloatChannel = kRGBChannels THEN
			FOR channel := 0 TO 2 DO
				BEGIN
				aVMArray := fDoc.fFloatData [channel] . CopyArray (3 - channel);
				aClipImageView.fData [channel] := aVMArray
				END
		ELSE
			BEGIN
			aVMArray := fDoc.fFloatData [0] . CopyArray (1);
			aClipImageView.fData [0] := aVMArray
			END;

		RedoIt

		END;

	Success (fi);

	gApplication.ClaimClipboard (aClipImageView)

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TCutCopyCommand.UndoIt; OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	MoveHands (FALSE);

	IF NOT fDoc.fSelectionFloating THEN
		fDoc.DeSelect (TRUE);

	IF NOT fDuplicate THEN
		BEGIN
		BlendFloat (FALSE);
		ComputeOverlap (r);
		fDoc.UpdateImageArea (r, FALSE, TRUE, fDoc.fFloatChannel)
		END;

	IF NOT fDoc.fSelectionFloating THEN
		SelectFloat

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TCutCopyCommand.RedoIt; OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	MoveHands (FALSE);

	IF NOT fDoc.fSelectionFloating THEN
		fDoc.DeSelect (TRUE);

	IF NOT fDuplicate THEN
		BEGIN
		CopyBelow (FALSE);
		fDoc.DeSelect (FALSE);
		ComputeOverlap (r);
		fDoc.UpdateImageArea (r, FALSE, TRUE, fDoc.fFloatChannel)
		END

	ELSE IF NOT fDoc.fSelectionFloating THEN
		SelectFloat

	END;

{*****************************************************************************}

{$S ADoFloat}

FUNCTION DoCutCopyCommand (view: TImageView;
						   duplicate: BOOLEAN): TCommand;

	VAR
		aCutCopyCommand: TCutCopyCommand;

	BEGIN

	NEW (aCutCopyCommand);
	FailNil (aCutCopyCommand);

	aCutCopyCommand.ICutCopyCommand (view, duplicate);

	DoCutCopyCommand := aCutCopyCommand

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TPasteCommand.IPasteCommand (view: TImageView; pasteMode: INTEGER);

	BEGIN

	fPasteMode := pasteMode;

		CASE pasteMode OF
		0: IFloatCommand (cPaste, view);
		1: IFloatCommand (cPasteInto, view);
		2: IFloatCommand (cPasteBehind, view)
		END

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TPasteCommand.DoIt; OVERRIDE;

	VAR
		r: Rect;
		dr: Rect;
		pt: Point;
		fi: FailInfo;
		gray: INTEGER;
		selRect: Rect;
		channel: INTEGER;
		map: TLookUpTable;
		selMask: TVMArray;
		channels: INTEGER;
		aVMArray: TVMArray;
		aClipImageView: TClipImageView;

	PROCEDURE CleanUp1 (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (aVMArray)
		END;

	PROCEDURE CleanUp2 (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (selMask);
		fDoc.FreeFloat
		END;

	BEGIN

	MoveHands (TRUE);

	{$IFC qDebug}
	IF NOT MEMBER (gClipView, TClipImageView) THEN
		ProgramBreak ('Attempt to paste a non-native clipboard');
	{$ENDC}

	selMask := NIL;

	IF fPasteMode <> 0 THEN
		BEGIN
		aVMArray := NewVMArray (fDoc.fRows, fDoc.fCols, 1);
		CatchFailures (fi, CleanUp1);
		CopyAlphaChannel (fDoc, aVMArray);
		IF fPasteMode = 2 THEN
			aVMArray.MapBytes (gInvertLUT)
		END;

	r := fDoc.fSelectionRect;

	fDoc.DeSelect (TRUE);

	IF fPasteMode <> 0 THEN
		BEGIN
		fDoc.fFloatAlpha := aVMArray;
		Success (fi)
		END;

	CatchFailures (fi, CleanUp2);

	IF EmptyRect (r) THEN
		BEGIN

		fView.fFrame.GetViewedRect (r);

		pt.v := BSR (ORD4 (r.top ) + r.bottom, 1);
		pt.h := BSR (ORD4 (r.left) + r.right , 1);

		fView.CvtView2Image (pt)

		END

	ELSE
		BEGIN
		pt.v := BSR (ORD4 (r.top ) + r.bottom, 1);
		pt.h := BSR (ORD4 (r.left) + r.right , 1)
		END;

	aClipImageView := TClipImageView (gClipView);

	pt.v := pt.v - BSR (aClipImageView.fSize.v, 1);
	pt.h := pt.h - BSR (aClipImageView.fSize.h, 1);

	pt.v := Max (0, Min (pt.v, fDoc.fRows - aClipImageView.fSize.v));
	pt.h := Max (0, Min (pt.h, fDoc.fCols - aClipImageView.fSize.h));

	r.topLeft := pt;
	r.bottom  := pt.v + aClipImageView.fSize.v;
	r.right   := pt.h + aClipImageView.fSize.h;

	IF fDoc.fMode = IndexedColorMode THEN
		aClipImageView.CompTransMap (fDoc.fIndexedColorTable, map);

	IF fView.fChannel = kRGBChannels THEN
		channels := 3
	ELSE
		channels := 1;

	fDoc.fFloatRect    := r;
	fDoc.fFloatCommand := SELF;
	fDoc.fFloatChannel := fView.fChannel;
	fDoc.fExactFloat   := FALSE;

		CASE aClipImageView.fMode OF

		HalftoneMode:
			BEGIN

			SetRect (dr, 0, 0, aClipImageView.fSize.h,
							   aClipImageVIew.fSize.v);

			aVMArray := CopyHalftoneRect (aClipImageView.fData [0], dr, 8);
			fDoc.fFloatData [0] := aVMArray;

			IF fDoc.fMode = IndexedColorMode THEN
				aVMArray.MapBytes (map)

			ELSE IF fDoc.fFloatChannel = kRGBChannels THEN
				BEGIN

				aVMArray := aVMArray . CopyArray (1);
				fDoc.fFloatData [1] := aVMArray;

				aVMArray := aVMArray . CopyArray (1);
				fDoc.fFloatData [2] := aVMArray

				END

			END;

		MonochromeMode:
			BEGIN

			aVMArray := aClipImageView.fData [0] . CopyArray (channels);
			fDoc.fFloatData [0] := aVMArray;

			IF fDoc.fMode = IndexedColorMode THEN
				aVMArray.MapBytes (map)

			ELSE IF fDoc.fFloatChannel = kRGBChannels THEN
				BEGIN

				aVMArray := aVMArray . CopyArray (2);
				fDoc.fFloatData [1] := aVMArray;

				aVMArray := aVMArray . CopyArray (1);
				fDoc.fFloatData [2] := aVMArray

				END

			END;

		IndexedColorMode:
			BEGIN

			aVMArray := aClipImageView.fData [0] . CopyArray (channels);
			fDoc.fFloatData [0] := aVMArray;

			IF fDoc.fMode = IndexedColorMode THEN
				aVMArray.MapBytes (map)

			ELSE IF fDoc.fFloatChannel = kRGBChannels THEN
				BEGIN

				aVMArray := aVMArray . CopyArray (2);
				fDoc.fFloatData [1] := aVMArray;

				aVMArray := aVMArray . CopyArray (1);
				fDoc.fFloatData [2] := aVMArray;

				map := aClipImageView.fIndexedColorTable.R;
				fDoc.fFloatData [0] . MapBytes (map);

				map := aClipImageView.fIndexedColorTable.G;
				fDoc.fFloatData [1] . MapBytes (map);

				map := aClipImageView.fIndexedColorTable.B;
				fDoc.fFloatData [2] . MapBytes (map)

				END

			ELSE
				BEGIN

				FOR gray := 0 TO 255 DO
					map [gray] := ConvertToGray
								  (aClipImageView.fIndexedColorTable.R [gray],
								   aClipImageView.fIndexedColorTable.G [gray],
								   aClipImageView.fIndexedColorTable.B [gray]);

				aVMArray.MapBytes (map)

				END

			END;

		RGBColorMode:

			IF fDoc.fFloatChannel = kRGBChannels THEN
				BEGIN

				aVMArray := aClipImageView.fData [0] . CopyArray (3);
				fDoc.fFloatData [0] := aVMArray;

				aVMArray := aClipImageView.fData [1] . CopyArray (2);
				fDoc.fFloatData [1] := aVMArray;

				aVMArray := aClipImageView.fData [2] . CopyArray (1);
				fDoc.fFloatData [2] := aVMArray

				END

			ELSE
				BEGIN
				aVMArray := MakeMonochromeArray (aClipImageView.fData [0],
												 aClipImageView.fData [1],
												 aClipImageView.fData [2]);
				fDoc.fFloatData [0] := aVMArray
				END

		END;

	IF aClipImageView.fMask <> NIL THEN
		BEGIN
		aVMArray := aClipImageView.fMask.CopyArray (1);
		fDoc.fFloatMask := aVMArray
		END;

	FOR channel := 0 TO channels - 1 DO
		BEGIN
		aVMArray := NewVMArray (r.bottom - r.top, r.right - r.left, 1);
		fDoc.fFloatBelow [channel] := aVMArray
		END;

	CopyBelow (TRUE);

	FailOSErr (CanSelect (selRect, selMask));

	BlendFloat (FALSE);

	ComputeOverlap (r);
	fDoc.UpdateImageArea (r, FALSE, TRUE, fDoc.fFloatChannel);

	fDoc.Select (selRect, selMask);
	fDoc.fSelectionFloating := TRUE;

	Success (fi)

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TPasteCommand.UndoIt; OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	MoveHands (FALSE);

	fDoc.DeSelect (NOT fDoc.fSelectionFloating);

	CopyBelow (FALSE);

	ComputeOverlap (r);
	fDoc.UpdateImageArea (r, FALSE, TRUE, fDoc.fFloatChannel)

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TPasteCommand.RedoIt; OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	MoveHands (FALSE);

	fDoc.DeSelect (TRUE);

	BlendFloat (FALSE);

	ComputeOverlap (r);
	fDoc.UpdateImageArea (r, FALSE, TRUE, fDoc.fFloatChannel);

	SelectFloat

	END;

{*****************************************************************************}

{$S ADoFloat}

FUNCTION DoPasteCommand (view: TImageView; pasteMode: INTEGER): TCommand;

	VAR
		aPasteCommand: TPasteCommand;

	BEGIN

	NEW (aPasteCommand);
	FailNil (aPasteCommand);

	aPasteCommand.IPasteCommand (view, pasteMode);

	DoPasteCommand := aPasteCommand

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TClearCommand.IClearCommand (view: TImageView);

	BEGIN
	IFloatCommand (cClear, view)
	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TClearCommand.DoIt; OVERRIDE;

	VAR
		r: Rect;
		x: INTEGER;
		channel: INTEGER;

	BEGIN

	MoveHands (FALSE);

	FloatSelection (TRUE);

	fExactFloat := fDoc.fExactFloat;

	fFloatRect := fDoc.fFloatRect;

	r := fFloatRect;

	IF fWasFloating THEN
		BEGIN

		fDoc.DeSelect (FALSE);

		CopyBelow (FALSE);

		fDoc.UpdateImageArea (r, FALSE, TRUE, fDoc.fFloatChannel)

		END

	ELSE
		BEGIN

		fDoc.fSelectionFloating := FALSE;

		FOR channel := 0 TO 2 DO
			IF fDoc.fFloatData [channel] <> NIL THEN
				BEGIN

				x := fView.BackgroundByte (channel);

				fDoc.fFloatData [channel] . SetBytes (x)

				END;

		BlendFloat (FALSE);

		fDoc.UpdateImageArea (r, TRUE, TRUE, fDoc.fFloatChannel)

		END

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TClearCommand.UndoIt; OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	MoveHands (FALSE);

	fDoc.DeSelect (NOT EqualRect (fDoc.fFloatRect,
								  fDoc.fSelectionRect));

	IF fWasFloating THEN
		BlendFloat (FALSE)
	ELSE
		CopyBelow (FALSE);

	ComputeOverlap (r);
	fDoc.UpdateImageArea (r, FALSE, TRUE, fDoc.fFloatChannel);

	SelectFloat;
	fDoc.fSelectionFloating := fWasFloating

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TClearCommand.RedoIt; OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	MoveHands (FALSE);

	fDoc.DeSelect (NOT EqualRect (fDoc.fFloatRect,
								  fDoc.fSelectionRect));

	IF fWasFloating THEN
		BEGIN
		CopyBelow (FALSE);
		SwapFloat
		END
	ELSE
		BlendFloat (FALSE);

	ComputeOverlap (r);
	fDoc.UpdateImageArea (r, FALSE, TRUE, fDoc.fFloatChannel);

	IF NOT fWasFloating THEN
		BEGIN
		SelectFloat;
		fDoc.fSelectionFloating := FALSE
		END

	END;

{*****************************************************************************}

{$S ADoFloat}

FUNCTION DoClearCommand (view: TImageView): TCommand;

	VAR
		aClearCommand: TClearCommand;

	BEGIN

	NEW (aClearCommand);
	FailNil (aClearCommand);

	aClearCommand.IClearCommand (view);

	DoClearCommand := aClearCommand

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TFillCommand.IFillCommand (itsCommand: INTEGER;
									 view: TImageView;
									 withPattern: BOOLEAN;
									 blend: INTEGER;
									 mode: TPasteMode);

	BEGIN

	fWithPattern := withPattern;

	fBlend := blend;
	fMode  := mode;

	IFloatCommand (itsCommand, view);

	fChannel := view.fChannel;

	fWholeImage := EmptyRect (fDoc.fSelectionRect);

	fNeedOriginal := FALSE

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TFillCommand.PatternFill (band: INTEGER; dstArray: TVMArray);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		width: INTEGER;
		height: INTEGER;
		srcRow: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		gPattern [band] . Flush;
		dstArray.Flush
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	width  := gPatternRect.right - gPatternRect.left;
	height := gPatternRect.bottom - gPatternRect.top;

	FOR row := 0 TO dstArray.fBlockCount - 1 DO
		BEGIN

		MoveHands (TRUE);

		dstPtr := dstArray.NeedPtr (row, row, TRUE);

		srcRow := row MOD height + gPatternRect.top;

		srcPtr := gPattern [band] . NeedPtr (srcRow, srcRow, FALSE);
		srcPtr := Ptr (ORD4 (srcPtr) + gPatternRect.left);

		DoPatternFill (srcPtr, dstPtr, width, dstArray.fLogicalSize);

		gPattern [band] . DoneWithPtr;

		dstArray.DoneWithPtr

		END;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TFillCommand.DoFill (r: Rect;
							   maskArray: TVMArray;
							   floatArray: TRGBArrayList);

	VAR
		channel: INTEGER;

	BEGIN

	IF fWithPattern THEN
		BEGIN

		IF floatArray [1] = NIL THEN
			PatternFill (0, floatArray [0])
		ELSE
			IF gPattern [1] = NIL THEN
				FOR channel := 0 TO 2 DO
					PatternFill (0, floatArray [channel])
			ELSE
				FOR channel := 0 TO 2 DO
					PatternFill (channel + 1, floatArray [channel])

		END

	ELSE
		FOR channel := 0 TO 2 DO
			IF floatArray [channel] <> NIL THEN
				floatArray [channel] . SetBytes
									   (fView.ForegroundByte (channel))

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TFillCommand.DoIt; OVERRIDE;

	VAR
		r: Rect;
		h: Handle;
		channel: INTEGER;
		channels: INTEGER;
		aVMArray: TVMArray;
		floatArray: TRGBArrayList;

	BEGIN

	MoveHands (FALSE);

	IF fWholeImage THEN
		BEGIN

		IF fChannel = kRGBChannels THEN
			channels := 3
		ELSE
			channels := 1;

		FOR channel := 0 TO channels - 1 DO
			BEGIN

			IF fNeedOriginal THEN
				IF channels = 3 THEN
					aVMArray := fDoc.fData [channel] . CopyArray (3 - channel)
				ELSE
					aVMArray := fDoc.fData [fChannel] . CopyArray (1)
			ELSE
				aVMArray := NewVMArray (fDoc.fRows,
										fDoc.fCols, channels - channel);

			fBuffer [channel] := aVMArray

			END;

		FOR channel := 0 TO 2 DO
			floatArray [channel] := fBuffer [channel];

		fDoc.GetBoundsRect (r);

		DoFill (r, NIL, floatArray);

		RedoIt

		END

	ELSE
		BEGIN

		FloatSelection (TRUE);

		{$H-}
		GetPasteControls (fDoc, fOldControls);
		{$H+}

		fNewControls		:= fOldControls;
		fNewControls.fMode	:= fMode;
		fNewControls.fBlend := fBlend;

		IF fDoc.fPasteControls = NIL THEN
			BEGIN

			h := NewPermHandle (SIZEOF (TPasteControls));
			FailNil (h);

			fDoc.fPasteControls := h

			END;

		HPasteControls (fDoc.fPasteControls)^^ := fNewControls;

		fExactFloat := fDoc.fExactFloat;

		fFloatRect := fDoc.fFloatRect;

		r := fFloatRect;

		IF fWasFloating THEN
			BEGIN

			FOR channel := 0 TO 2 DO
				IF fDoc.fFloatData [channel] <> NIL THEN
					BEGIN

					IF fNeedOriginal THEN
						aVMArray := fDoc.fFloatData [channel] . CopyArray (1)
					ELSE
						aVMArray := NewVMArray (r.bottom - r.top,
												r.right - r.left, 1);

					fFloatData [channel] := aVMArray

					END;

			floatArray := fFloatData;

			DoFill (r, fDoc.fFloatMask, floatArray);

			RedoIt

			END

		ELSE
			BEGIN

			fDoc.fSelectionFloating := FALSE;

			floatArray := fDoc.fFloatData;

			DoFill (r, fDoc.fFloatMask, floatArray);

			BlendFloat (FALSE);

			fDoc.UpdateImageArea (r, TRUE, TRUE, fDoc.fFloatChannel)

			END

		END

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TFillCommand.UndoIt; OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	IF fWholeImage OR fWasFloating THEN
		RedoIt

	ELSE
		BEGIN

		MoveHands (FALSE);

		fDoc.DeSelect (NOT EqualRect (fDoc.fFloatRect,
									  fDoc.fSelectionRect));

		CopyBelow (FALSE);

		ComputeOverlap (r);
		fDoc.UpdateImageArea (r, FALSE, TRUE, fDoc.fFloatChannel);

		SelectFloat;
		fDoc.fSelectionFloating := FALSE

		END

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TFillCommand.RedoIt; OVERRIDE;

	VAR
		r: Rect;
		temp: TVMArray;
		channel: INTEGER;

	BEGIN

	MoveHands (FALSE);

	IF fWholeImage THEN
		BEGIN

		IF fChannel = kRGBChannels THEN
			FOR channel := 0 TO 2 DO
				BEGIN
				temp				 := fBuffer [channel];
				fBuffer [channel]	 := fDoc.fData [channel];
				fDoc.fData [channel] := temp
				END
		ELSE
			BEGIN
			temp				  := fBuffer [0];
			fBuffer [0] 		  := fDoc.fData [fChannel];
			fDoc.fData [fChannel] := temp
			END;

		fDoc.GetBoundsRect (r);

		fDoc.UpdateImageArea (r, TRUE, TRUE, fChannel)

		END

	ELSE
		BEGIN

		fDoc.DeSelect (NOT EqualRect (fDoc.fFloatRect,
									  fDoc.fSelectionRect));

		IF fWasFloating THEN
			BEGIN
			CopyBelow (FALSE);
			SwapFloat
			END;

		IF fCmdDone THEN
			HPasteControls (fDoc.fPasteControls)^^ := fOldControls
		ELSE
			HPasteControls (fDoc.fPasteControls)^^ := fNewControls;

		BlendFloat (FALSE);

		ComputeOverlap (r);
		fDoc.UpdateImageArea (r, FALSE, TRUE, fDoc.fFloatChannel);

		SelectFloat;
		fDoc.fSelectionFloating := fWasFloating

		END

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TFillBorderCommand.IFillBorderCommand (view: TImageView;
												 width: INTEGER;
												 blend: INTEGER;
												 mode: TPasteMode);

	BEGIN

	fWidth := width;

	IFillCommand (cFill, view, FALSE, blend, mode);

	fNeedOriginal := TRUE

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TFillBorderCommand.DoFill (r: Rect;
									 maskArray: TVMArray;
									 floatArray: TRGBArrayList); OVERRIDE;

	VAR
		rr: Rect;
		r1: Rect;
		r2: Rect;
		x: INTEGER;
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		channel: INTEGER;
		buffer1: TVMArray;
		buffer2: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (buffer1);
		FreeObject (buffer2)
		END;

	BEGIN

	IF (2 * fWidth >= r.right - r.left) OR
	   (2 * fWidth >= r.bottom - r.top) THEN
		INHERITED DoFill (r, maskArray, floatArray)

	ELSE IF maskArray = NIL THEN
		BEGIN

		FOR channel := 0 TO 2 DO
			IF floatArray [channel] <> NIL THEN
				BEGIN

				x := fView.ForegroundByte (channel);

				SetRect (rr, 0, 0, r.right - r.left, fWidth);
				floatArray [channel] . SetRect (rr, x);

				OffsetRect (rr, 0, r.bottom - r.top - fWidth);
				floatArray [channel] . SetRect (rr, x);

				SetRect (rr, 0, fWidth, fWidth, r.bottom - r.top - fWidth);
				floatArray [channel] . SetRect (rr, x);

				OffsetRect (rr, r.right - r.left - fWidth, 0);
				floatArray [channel] . SetRect (rr, x)

				END

		END

	ELSE
		BEGIN

		MoveHands (TRUE);

		buffer1 := NIL;
		buffer2 := NIL;

		CatchFailures (fi, CleanUp);

		rr.top	  := 0;
		rr.left   := 0;
		rr.bottom := r.bottom - r.top + 2;
		rr.right  := r.right - r.left + 2;

		buffer1 := NewVMArray (rr.bottom, rr.right, 1);
		buffer2 := NewVMArray (rr.bottom, rr.right, 1);

		buffer1.SetBytes (0);

		r1 := r;
		OffsetRect (r1, -r1.left, -r1.top);

		r2 := rr;
		InsetRect (r2, 1, 1);

		maskArray.MoveRect (buffer1, r1, r2);

		MinOrMaxFilter (buffer1, buffer2, rr, fWidth, FALSE, TRUE);

		buffer2.MapBytes (gInvertLUT);

		FOR channel := 0 TO 2 DO
			IF floatArray [channel] <> NIL THEN
				BEGIN

				DoSetBytes (gBuffer,
							r1.right,
							fView.ForegroundByte (channel));

				FOR row := 0 TO r1.bottom - 1 DO
					BEGIN

					MoveHands (TRUE);

					srcPtr := Ptr (ORD4 (buffer2.NeedPtr (row + 1,
														  row + 1,
														  FALSE)) + 1);

					dstPtr := floatArray [channel] . NeedPtr (row, row, TRUE);

					DoBlendBelow (srcPtr, gBuffer, dstPtr, r1.right, 0, -1);

					floatArray [channel] . DoneWithPtr;

					buffer2.DoneWithPtr

					END;

				floatArray [channel] . Flush

				END;

		Success (fi);

		CleanUp (0, 0)

		END

	END;

{*****************************************************************************}

{$S ADoFloat}

FUNCTION DoFillCommand (view: TImageView; options: BOOLEAN): TCommand;

	CONST
		kGrayDialogID  = 1100;
		kIndexDialogID = 1101;
		kRGBDialogID   = 1102;
		kHookItem	   = 3;
		kNormalItem    = 4;
		kPatternItem   = 5;
		kBorderItem    = 6;
		kWidthItem	   = 7;
		kBlendItem	   = 8;
		kFirstMode	   = 9;
		kLastMode	   = 12;

	VAR
		id: INTEGER;
		fi: FailInfo;
		itemBox: Rect;
		width: INTEGER;
		blend: INTEGER;
		option: INTEGER;
		mode: TPasteMode;
		hitItem: INTEGER;
		itemType: INTEGER;
		itemHandle: Handle;
		doc: TImageDocument;
		aBWDialog: TBWDialog;
		widthText: TFixedText;
		blendText: TFixedText;
		allowPattern: BOOLEAN;
		modeCluster: TRadioCluster;
		aFillCommand: TFillCommand;
		optionCluster: TRadioCluster;
		aFillBorderCommand: TFillBorderCommand;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	PROCEDURE MyItemHandling (anItem: INTEGER; VAR done: BOOLEAN);

		VAR
			temp1: BOOLEAN;
			temp2: BOOLEAN;
			ignore: TCommand;

		BEGIN

		StdItemHandling (anItem, done);

			CASE anItem OF

			kNormalItem,
			kPatternItem:
				BEGIN
				widthText.StuffString ('');
				aBWDialog.SetEditSelection (kWidthItem)
				END;

			kBorderItem:
				aBWDialog.SetEditSelection (kWidthItem);

			kWidthItem:
				ignore := optionCluster.ItemSelected (kBorderItem,
													  temp1, temp2)

			END;

		widthText.fBlankOK := (optionCluster.fChosenItem <> kBorderItem)

		END;

	BEGIN

	doc := TImageDocument (view.fDocument);

	IF options THEN
		BEGIN

		NEW (aBWDialog);
		FailNil (aBWDialog);

		{$IFC qBarneyscan}

		id := kIndexDialogID;

		{$ELSEC}

		IF view.fChannel = kRGBChannels THEN
			id := kRGBDialogID
		ELSE IF doc.fMode = IndexedColorMode THEN
			id := kIndexDialogID
		ELSE
			id := kGrayDialogID;

		{$ENDC}

		aBWDialog.IBWDialog (id, kHookItem, ok);

		CatchFailures (fi, CleanUp);

		allowPattern := NOT EmptyRect (gPatternRect) AND
						(id <> kIndexDialogID);

		IF (gFillOption = 1) AND NOT allowPattern THEN
			option := 0
		ELSE
			option := gFillOption;

		optionCluster := aBWDialog.DefineRadioCluster
						 (kNormalItem,
						  kBorderItem,
						  kNormalItem + option);

		IF NOT allowPattern THEN
			BEGIN
			GetDItem (aBWDialog.fDialogPtr, kPatternItem,
					  itemType, itemHandle, itemBox);
			HiliteControl (ControlHandle (itemHandle), 255)
			END;

		widthText := aBWDialog.DefineFixedText
					 (kWidthItem, 0, (option <> 2), TRUE, 1, 10);

		IF option = 2 THEN
			widthText.StuffValue (gFillBorder);

		IF (id <> kIndexDialogID) THEN
			BEGIN

			blendText := aBWDialog.DefineFixedText
						 (kBlendItem, 0, FALSE, TRUE, 1, 100);

			blendText.StuffValue (gFillBlend);

			IF (view.fChannel = kRGBChannels) OR
			   (gFillMode <> PasteColorOnly) THEN
				mode := gFillMode
			ELSE
				mode := PasteNormal;

			modeCluster := aBWDialog.DefineRadioCluster
						   (kFirstMode,
							kLastMode,
							kFirstMode + ORD (mode))

			END;

		aBWDialog.SetEditSelection (kWidthItem);

		aBWDialog.TalkToUser (hitItem, MyItemHandling);

		IF hitItem <> ok THEN Failure (0, 0);

		gFillOption := optionCluster.fChosenItem - kNormalItem;
		gFillBorder := Max (1, widthText.fValue);

		option := gFillOption;
		width  := gFillBorder;

		IF (id <> kIndexDialogID) THEN
			BEGIN
			gFillBlend := blendText.fValue;
			gFillMode  := TPasteMode (modeCluster.fChosenItem - kFirstMode);
			blend	   := gFillBlend;
			mode	   := gFillMode
			END
		ELSE
			BEGIN
			blend := 100;
			mode  := PasteNormal
			END;

		Success (fi);

		CleanUp (0, 0)

		END

	ELSE
		BEGIN
		option := 0;
		width  := 0;
		blend  := 100;
		mode   := PasteNormal
		END;

	IF option <> 2 THEN
		BEGIN

		NEW (aFillCommand);
		FailNil (aFillCommand);

		aFillCommand.IFillCommand (cFill, view, option = 1, blend, mode);

		DoFillCommand := aFillCommand

		END

	ELSE
		BEGIN

		NEW (aFillBorderCommand);
		FailNil (aFillBorderCommand);

		aFillBorderCommand.IFillBorderCommand (view, width, blend, mode);

		DoFillCommand := aFillBorderCommand

		END

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TGradientTool.IGradientTool (view: TImageView;
									   radial: BOOLEAN;
									   midpoint: INTEGER;
									   offset: INTEGER;
									   space: INTEGER);

	BEGIN

	fSpace := space;
	fRadial := radial;
	fOffset := offset;
	fMidpoint := midpoint;

	IFillCommand (cBlendTool, view, FALSE, 100, PasteNormal);

	fConstrainsMouse := TRUE;
	fViewConstrain	 := FALSE

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TGradientTool.TrackConstrain (anchorPoint: Point;
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

{$S ADoFloat}

PROCEDURE TGradientTool.TrackFeedBack (anchorPoint: Point;
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

{$S ADoFloat}

FUNCTION TGradientTool.TrackMouse
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
			END;

		IF LONGINT (fPt1) = LONGINT (fPt2) THEN
			TrackMouse := gNoChanges

		END

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE TGradientTool.DoFill (r: Rect;
								maskArray: TVMArray;
								floatArray: TRGBArrayList); OVERRIDE;

	VAR
		rr: Rect;
		n: LONGINT;
		d: LONGINT;
		pt1: Point;
		pt2: Point;
		dstPtr: Ptr;
		row: INTEGER;
		delta: Point;
		channel: INTEGER;
		map: ARRAY [0..2] OF TLookUpTable;
		table: PACKED ARRAY [0..4095] OF CHAR;

	PROCEDURE BuildTable;

		VAR
			j: INTEGER;
			k: INTEGER;
			m: EXTENDED;
			t: EXTENDED;
			x1: INTEGER;
			x2: INTEGER;
			y1: INTEGER;
			y2: INTEGER;
			dx: INTEGER;
			dy: LONGINT;
			w1: EXTENDED;
			w2: EXTENDED;
			half: INTEGER;
			start: INTEGER;

		BEGIN

		m := 4/3 * (fMidPoint / 100 - 1/8);

		start := ROUND (fOffset / 100 * 4095);

		FOR k := 0 TO start - 1 DO
			table [k] := CHR (0);

		x1 := start;
		y1 := 0;

		FOR j := 1 TO 20 DO
			BEGIN

			t := j / 20;

			w1 := 3 * t * (1 - t);
			w2 := t * t * t;

			x2 := ROUND ((w1 * m   + w2) * (4095 - start)) + start;
			y2 := ROUND ((w1 * 0.5 + w2) * 255);

			dx := x2 - x1;
			dy := y2 - y1;

			half := BSR (dx, 1);

			IF dx = 0 THEN
				table [x1] := CHR (y2)
			ELSE
				FOR k := x1 TO x2 DO
					table [k] := CHR (y1 + (dy * (k - x1) + half) DIV dx);

			x1 := x2;
			y1 := y2

			END

		END;

	PROCEDURE BuildMap;

		VAR
			j: INTEGER;
			k: INTEGER;
			temp: INTEGER;
			color: RGBColor;
			color2: HSVColor;
			x: ARRAY [0..2] OF INTEGER;
			y: ARRAY [0..2] OF INTEGER;

		BEGIN

		color := gForegroundColor;
		RGB2HSV (color, color2);

		IF fSpace <> 0 THEN
			BEGIN
			x [0] := BAND ($FF, BSR (color2.hue 	  , 8));
			x [1] := BAND ($FF, BSR (color2.saturation, 8));
			x [2] := BAND ($FF, BSR (color2.value	  , 8))
			END
		ELSE
			BEGIN
			x [0] := BAND ($FF, BSR (color.red	, 8));
			x [1] := BAND ($FF, BSR (color.green, 8));
			x [2] := BAND ($FF, BSR (color.blue , 8))
			END;

		color := gBackgroundColor;
		RGB2HSV (color, color2);

		IF fSpace <> 0 THEN
			BEGIN
			y [0] := BAND ($FF, BSR (color2.hue 	  , 8));
			y [1] := BAND ($FF, BSR (color2.saturation, 8));
			y [2] := BAND ($FF, BSR (color2.value	  , 8))
			END
		ELSE
			BEGIN
			y [0] := BAND ($FF, BSR (color.red	, 8));
			y [1] := BAND ($FF, BSR (color.green, 8));
			y [2] := BAND ($FF, BSR (color.blue , 8))
			END;

		y [0] := y [0] - x [0];
		y [1] := y [1] - x [1];
		y [2] := y [2] - x [2];

		IF (fSpace = 1) AND (y [0] > 0) THEN
			y [0] := y [0] - 256
		ELSE IF (fSpace = 2) AND (y [0] < 0) THEN
			y [0] := y [0] + 256;

		FOR j := 0 TO 2 DO
			FOR k := 0 TO 255 DO
				BEGIN
				temp := x [j] + (ORD4 (y [j]) * k) DIV 255;
				map [j, k] := CHR (BAND ($FF, temp))
				END;

		IF fSpace <> 0 THEN
			DoHSLorB2RGB (@map [0], @map [1], @map [2],
						  @map [0], @map [1], @map [2], 256, TRUE);

		IF floatArray [1] = NIL THEN
			DoMakeMonochrome (@map [0], gGrayLUT.R,
							  @map [1], gGrayLUT.G,
							  @map [2], gGrayLUT.B,
							  @map [0], 256)

		END;

	BEGIN

	BuildTable;

	pt1.h := fPt1.h - r.left;
	pt1.v := fPt1.v - r.top;

	pt2.h := fPt2.h - r.left;
	pt2.v := fPt2.v - r.top;

	SetRect (rr, 0, 0, r.right - r.left, r.bottom - r.top);

	delta.h := pt2.h - pt1.h;
	delta.v := pt2.v - pt1.v;

	n := ORD4 (-pt1.v) * delta.v + ORD4 (-pt1.h) * delta.h;
	d := SQR (ORD4 (delta.v)) + SQR (ORD4 (delta.h));

	FOR row := 0 TO rr.bottom - 1 DO
		BEGIN

		MoveHands (TRUE);

		dstPtr := floatArray [0] . NeedPtr (row, row, TRUE);

		IF fRadial THEN
			DoRadialGradient (dstPtr, rr.right, row - pt1.v, -pt1.h, d, @table)
		ELSE
			DoLinearGradient (dstPtr, rr.right, n, delta.h, d, @table);

		n := n + delta.v;

		floatArray [0] . DoneWithPtr

		END;

	FOR channel := 1 TO 2 DO
		IF floatArray [channel] <> NIL THEN
			floatArray [0] . MoveArray (floatArray [channel]);

	BuildMap;

	FOR channel := 0 TO 2 DO
		IF floatArray [channel] <> NIL THEN
			floatArray [channel] . MapBytes (map [channel])

	END;

{*****************************************************************************}

{$S ADoFloat}

FUNCTION DoGradientTool (view: TImageView): TCommand;

	VAR
		fi: FailInfo;
		doc: TImageDocument;
		aGradientTool: TGradientTool;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FailNewMessage (error, message, msgCannotGradient)
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	doc := TImageDocument (view.fDocument);

	IF doc.fMode = HalftoneMode THEN
		Failure (errNoHalftone, 0);

	IF doc.fMode = IndexedColorMode THEN
		Failure (errNoIndexedColor, 0);

	NEW (aGradientTool);
	FailNil (aGradientTool);

	aGradientTool.IGradientTool (view,
								 gGradientRadial,
								 gGradientMidpoint,
								 gGradientOffset,
								 gGradientSpace);

	Success (fi);

	DoGradientTool := aGradientTool

	END;

{*****************************************************************************}

{$S ADoFloat}

PROCEDURE DoGradientOptions;

	CONST
		kDialogID	  = 1091;
		kHookItem	  = 3;
		kLinearItem   = 4;
		kRadialItem   = 5;
		kMidpointItem = 6;
		kOffsetItem   = 7;
		kSpaceItems   = 8;

	VAR
		fi: FailInfo;
		hitItem: INTEGER;
		offset: TFixedText;
		midpoint: TFixedText;
		aBWDialog: TBWDialog;
		modeCluster: TRadioCluster;
		spaceCluster: TRadioCluster;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	PROCEDURE MyItemHandling (anItem: INTEGER; VAR done: BOOLEAN);

		BEGIN

		StdItemHandling (anItem, done);

			CASE anItem OF

			kLinearItem:
				BEGIN
				offset.StuffString ('');
				aBWDialog.SetEditSelection (kMidpointItem)
				END;

			kOffsetItem:
				IF modeCluster.fChosenItem <> kRadialItem THEN
					StdItemHandling (kRadialItem, done)

			END

		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	midpoint := aBWDialog.DefineFixedText
				(kMidpointItem, 0, FALSE, TRUE, 13, 87);

	midpoint.StuffValue (gGradientMidpoint);

	offset := aBWDialog.DefineFixedText
			  (kOffsetItem, 0, TRUE, TRUE, 0, 99);

	IF gGradientOffset <> 0 THEN
		offset.StuffValue (gGradientOffset);

	modeCluster := aBWDialog.DefineRadioCluster
				   (kLinearItem,
					kRadialItem,
					kLinearItem + ORD (gGradientRadial));

	spaceCluster := aBWDialog.DefineRadioCluster
					(kSpaceItems,
					 kSpaceItems + 2,
					 kSpaceItems + gGradientSpace);

	aBWDialog.SetEditSelection (kMidpointItem);

	aBWDialog.TalkToUser (hitItem, MyItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	gGradientMidpoint := midpoint.fValue;

	gGradientOffset := offset.fValue;

	gGradientRadial := (modeCluster.fChosenItem = kRadialItem);

	gGradientSpace := spaceCluster.fChosenItem - kSpaceItems;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

END.

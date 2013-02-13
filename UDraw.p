{Photoshop version 1.0.1, file: UDraw.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UDraw;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UBWDialog, UCommands, UGhost, UPressure;

TYPE

	TMarkingTool = OBJECT (TBufferCommand)

		fChannel: INTEGER;

		fMarkedArea: Rect;

		fCachedArea: Rect;

		fCacheSize: Point;

		fLastPoint: Point;

		fPixelAlign: BOOLEAN;
		fConstrainH: BOOLEAN;
		fConstrainV: BOOLEAN;

		fLowerPage: INTEGER;
		fUpperPage: INTEGER;

		fPhysicalSize: INTEGER;

		fFailMessage: LONGINT;

		fAlphaMap: TLookUpTable;
		fAlphaChannel: TVMArray;

		fAuxCursor: BOOLEAN;
		fAuxLocation: Point;
		fAuxView: TImageView;

		PROCEDURE TMarkingTool.IMarkingTool (view: TImageView;
											 itsCommand: INTEGER;
											 cacheSize: Point;
											 failMessage: LONGINT;
											 needAlpha: BOOLEAN);

		PROCEDURE TMarkingTool.Free; OVERRIDE;

		PROCEDURE TMarkingTool.TrackFeedBack (anchorPoint: Point;
											  nextPoint: Point;
											  turnItOn: BOOLEAN;
											  mouseDidMove: BOOLEAN); OVERRIDE;

		PROCEDURE TMarkingTool.TrackConstrain (anchorPoint: Point;
											   previousPoint: Point;
											   VAR nextPoint: Point); OVERRIDE;

		PROCEDURE TMarkingTool.BuildAlpha (lower, upper: INTEGER);

		PROCEDURE TMarkingTool.SaveLines (lower, upper: INTEGER);

		PROCEDURE TMarkingTool.AddToMarked (r: Rect);

		PROCEDURE TMarkingTool.DrawAuxCursor (pt: Point);

		PROCEDURE TMarkingTool.FlushCache;

		PROCEDURE TMarkingTool.AddToCache (r: Rect);

		PROCEDURE TMarkingTool.FixReleasePoint (anchorPoint: Point;
												VAR nextPoint: Point);

		PROCEDURE TMarkingTool.SwapRect (r: Rect; iArray, bArray: TVMArray);

		PROCEDURE TMarkingTool.SwapMarkedArea;

		PROCEDURE TMarkingTool.FlushImage;

		PROCEDURE TMarkingTool.RecoverFailure;

		PROCEDURE TMarkingTool.DoIt; OVERRIDE;

		PROCEDURE TMarkingTool.UndoIt; OVERRIDE;

		PROCEDURE TMarkingTool.RedoIt; OVERRIDE;

		END;

	TEraserTool = OBJECT (TMarkingTool)

		fMagic: BOOLEAN;

		fColor1: INTEGER;
		fColor2: INTEGER;
		fColor3: INTEGER;

		PROCEDURE TEraserTool.IEraserTool (view: TImageView; magic: BOOLEAN);

		FUNCTION TEraserTool.TrackMouse
						(aTrackPhase: TrackPhase;
						 VAR anchorPoint: Point;
						 VAR previousPoint: Point;
						 VAR nextPoint: Point;
						 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

		END;

	TTip = RECORD

		fSize: Point;
		fSpot: Point;

		fMask: Handle;
		fMask2: Handle;

		fData: ARRAY [0..3] OF Handle

		END;

	TDrawingMode = (NormalDrawing, ColorOnly, DarkenOnly, LightenOnly);

	TDrawingTool = OBJECT (TMarkingTool)

		fTip: TTip;

		fMode: TDrawingMode;

		fSpacing: INTEGER;

		fFadeout: INTEGER;

		fDelay: INTEGER;

		fPressureMode: INTEGER;

		fDip: BOOLEAN;

		fMixMap: TLookUpTable;

		fDrawings: LONGINT;

		fLastDrawTime: LONGINT;

		fSpacingCounter: INTEGER;

		fStampMethod: INTEGER;

		fImpressCounter: INTEGER;
		fImpressTimer  : LONGINT;

		fTextureNoise: Handle;

		fStampOffset: Point;

		fFore: ARRAY [1..3] OF INTEGER;
		fBack: ARRAY [1..3] OF INTEGER;

		PROCEDURE TDrawingTool.IDrawingTool (view: TImageView;
											 itsCommand: INTEGER;
											 VAR tip: TTip;
											 mode: TDrawingMode;
											 spacing: INTEGER;
											 fadeout: INTEGER;
											 rate: INTEGER;
											 failMessage: LONGINT;
											 needAlpha: BOOLEAN);

		PROCEDURE TDrawingTool.Free; OVERRIDE;

		PROCEDURE TDrawingTool.FindMask (offset: LONGINT; r: Rect);

		PROCEDURE TDrawingTool.BlurOrSharpen (dataPtr: Ptr;
											  offset: LONGINT;
											  r: Rect;
											  band: INTEGER;
											  sharpen: BOOLEAN);

		PROCEDURE TDrawingTool.SmudgeBand (dataPtr: Ptr;
										   offset: LONGINT;
										   r: Rect;
										   band: INTEGER);

		PROCEDURE TDrawingTool.MarkBand (dataPtr: Ptr;
										 offset: LONGINT;
										 r: Rect;
										 band: INTEGER);

		PROCEDURE TDrawingTool.MarkRGB (rDataPtr: Ptr;
										gDataPtr: Ptr;
										bDataPtr: Ptr;
										offset: LONGINT;
										r: Rect);

		PROCEDURE TDrawingTool.LoadOverlap (r: Rect;
											srcArray1: TVMArray;
											srcArray2: TVMArray;
											srcArray3: TVMArray);

		PROCEDURE TDrawingTool.LoadCloneTip (r: Rect);

		PROCEDURE TDrawingTool.LoadRevertTip (r: Rect);

		PROCEDURE TDrawingTool.LoadTextureTip;

		PROCEDURE TDrawingTool.LoadPatternTip (r: Rect);

		PROCEDURE TDrawingTool.LoadImpressTip (pt: Point);

		FUNCTION TDrawingTool.TrackMouse
						(aTrackPhase: TrackPhase;
						 VAR anchorPoint: Point;
						 VAR previousPoint: Point;
						 VAR nextPoint: Point;
						 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

		END;

	TPencilTool = OBJECT (TDrawingTool)

		fAutoErase: BOOLEAN;

		PROCEDURE TPencilTool.IPencilTool (view: TImageView; pt: Point);

		END;

	TBrushTool = OBJECT (TDrawingTool)

		PROCEDURE TBrushTool.IBrushTool (view: TImageView);

		END;

	TAirbrushTool = OBJECT (TDrawingTool)

		PROCEDURE TAirbrushTool.IAirbrushTool (view: TImageView);

		END;

	TBlurTool = OBJECT (TDrawingTool)

		PROCEDURE TBlurTool.IBlurTool (view: TImageView);

		END;

	TSharpenTool = OBJECT (TDrawingTool)

		PROCEDURE TSharpenTool.ISharpenTool (view: TImageView);

		END;

	TSmudgeTool = OBJECT (TDrawingTool)

		PROCEDURE TSmudgeTool.ISmudgeTool (view: TImageView; dip: BOOLEAN);

		END;

	TStampTool = OBJECT (TDrawingTool)

		PROCEDURE TStampTool.IStampTool (view: TImageView; theMsg: LONGINT);

		END;

	TEraseAll = OBJECT (TBufferCommand)

		fChannel: INTEGER;

		PROCEDURE TEraseAll.IEraseAll (view: TImageView);

		PROCEDURE TEraseAll.DoIt; OVERRIDE;

		PROCEDURE TEraseAll.UndoIt; OVERRIDE;

		PROCEDURE TEraseAll.RedoIt; OVERRIDE;

		END;

	TBrushesView = OBJECT (TView)

		fShapeID: INTEGER;

		fCustomRect: Rect;

		PROCEDURE TBrushesView.IBrushesView;

		PROCEDURE TBrushesView.HighlightShape (turnOn: BOOLEAN);

		FUNCTION TBrushesView.DoMouseCommand
				(VAR downLocalPoint: Point;
				 VAR info: EventInfo;
				 VAR hysteresis: Point): TCommand; OVERRIDE;

		PROCEDURE TBrushesView.Draw (area: Rect); OVERRIDE;

		END;

	TShapeDialog = OBJECT (TBWDialog)

		fShapeID: INTEGER;

		fShapesRect: Rect;
		fCustomRect: Rect;

		PROCEDURE TShapeDialog.IShapeDialog (dialogID, shapeID: INTEGER);

		PROCEDURE TShapeDialog.HighlightShape (turnOn: BOOLEAN);

		PROCEDURE TShapeDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

		PROCEDURE TShapeDialog.DoFilterEvent (VAR anEvent: EventRecord;
											  VAR itemHit: INTEGER;
											  VAR handledIt: BOOLEAN;
											  VAR doReturn: BOOLEAN); OVERRIDE;

		END;

PROCEDURE InitDrawing;

FUNCTION DoEraserTool (view: TImageView; magic: BOOLEAN): TCommand;

FUNCTION DoPencilTool (view: TImageView; pt: Point): TCommand;

FUNCTION DoBrushTool (view: TImageView): TCommand;

FUNCTION DoAirbrushTool (view: TImageView): TCommand;

FUNCTION DoBlurTool (view: TImageView): TCommand;

FUNCTION DoSharpenTool (view: TImageView): TCommand;

FUNCTION DoSmudgeTool (view: TImageView; dip: BOOLEAN): TCommand;

FUNCTION DoStampTool (view: TImageView): TCommand;

FUNCTION DoStampPadTool (view: TImageView; pt: Point): TCommand;

FUNCTION DoEraseAll (view: TImageView): TCommand;

FUNCTION BrushesVisible: BOOLEAN;

PROCEDURE ShowBrushes (visible: BOOLEAN);

PROCEDURE UpdateBrush;

PROCEDURE DoPencilOptions;

PROCEDURE DoBrushOptions;

PROCEDURE DoAirbrushOptions;

PROCEDURE DoBlurOptions;

PROCEDURE DoSharpenOptions;

PROCEDURE DoSmudgeOptions;

PROCEDURE DoStampOptions;

PROCEDURE DefineBrush (view: TImageView);

PROCEDURE DefinePattern (view: TImageView);

IMPLEMENTATION

{$I UAssembly.a.inc}
{$I UDraw.a.inc}
{$I UFloat.a.inc}
{$I USelect.p.inc}

CONST

	kTipSize = 25;

	kMaxTipSize = 64;
	kMaxTipArea = kMaxTipSize * kMaxTipSize;

	kShapesPictID = 2000;

	kClone1Method	= 0;
	kClone2Method	= 1;
	kRevertMethod	= 2;
	kTextureMethod	= 3;
	kPattern1Method = 4;
	kPattern2Method = 5;
	kImpressMethod	= 6;

	kUndefinedOption = -32768;

TYPE

	TTipBuffer = PACKED ARRAY [0..kMaxTipArea-1] OF CHAR;

	TTipTemplate = RECORD
		size: Point;
		spot: Point;
		data: ARRAY [0..0] OF INTEGER
		END;

	PTipTemplate = ^TTipTemplate;
	HTipTemplate = ^PTipTemplate;

	TToolOptions = RECORD
		shapeID  : INTEGER;
		mode	 : TDrawingMode;
		spacing  : INTEGER;
		fadeout  : INTEGER;
		rate	 : INTEGER;
		pressure : INTEGER;
		method	 : INTEGER;
		check1	 : INTEGER;
		wacom	 : INTEGER
		END;

VAR

	gHaveTexture: BOOLEAN;
	gTexture: ARRAY [0..3] OF TLookUpTable;

	gCustomSize: Point;
	gCustomTip: TTipBuffer;
	gCustomIcon: Handle;

	gBrushesView: TBrushesView;
	gBrushesWindow: TGhostWindow;

	gPencilOptions	: TToolOptions;
	gBrushOptions	: TToolOptions;
	gAirbrushOptions: TToolOptions;
	gBlurOptions	: TToolOptions;
	gSharpenOptions : TToolOptions;
	gSmudgeOptions	: TToolOptions;
	gStampOptions	: TToolOptions;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitDrawing;

	BEGIN

	InitPressure;

	gHaveTexture := FALSE;

	gCustomSize := Point (0);

	gCustomIcon := NewHandle (128);
	FailNil (gCustomIcon);

	gPatternRect := gZeroRect;

	gPattern [0] := NIL;
	gPattern [1] := NIL;
	gPattern [2] := NIL;
	gPattern [3] := NIL;

	WITH gPencilOptions DO
		BEGIN
		shapeID   := 1;
		mode	  := NormalDrawing;
		spacing   := 1;
		fadeout   := kUndefinedOption;
		rate	  := kUndefinedOption;
		pressure  := 100;
		method	  := kUndefinedOption;
		check1	  := 0;
		wacom	  := ORD (gHavePressure)
		END;

	WITH gBrushOptions DO
		BEGIN
		shapeID   := 4;
		mode	  := NormalDrawing;
		spacing   := 1;
		fadeout   := 0;
		rate	  := 0;
		pressure  := 100;
		method	  := kUndefinedOption;
		check1	  := kUndefinedOption;
		wacom	  := ORD (gHavePressure)
		END;

	WITH gAirbrushOptions DO
		BEGIN
		shapeID   := 8;
		mode	  := NormalDrawing;
		spacing   := 1;
		fadeout   := 0;
		rate	  := 10;
		pressure  := 50 + 50 * ORD (gHavePressure);
		method	  := kUndefinedOption;
		check1	  := kUndefinedOption;
		wacom	  := ORD (gHavePressure)
		END;

	WITH gBlurOptions DO
		BEGIN
		shapeID   := 4;
		mode	  := NormalDrawing;
		spacing   := 1;
		fadeout   := kUndefinedOption;
		rate	  := 10;
		pressure  := 50;
		method	  := kUndefinedOption;
		check1	  := kUndefinedOption;
		wacom	  := kUndefinedOption
		END;

	WITH gSharpenOptions DO
		BEGIN
		shapeID   := 8;
		mode	  := NormalDrawing;
		spacing   := 5;
		fadeout   := kUndefinedOption;
		rate	  := 0;
		pressure  := 50;
		method	  := kUndefinedOption;
		check1	  := kUndefinedOption;
		wacom	  := kUndefinedOption
		END;

	WITH gSmudgeOptions DO
		BEGIN
		shapeID   := 4;
		mode	  := NormalDrawing;
		spacing   := 1;
		fadeout   := kUndefinedOption;
		rate	  := 0;
		pressure  := 50;
		method	  := kUndefinedOption;
		check1	  := kUndefinedOption;
		wacom	  := kUndefinedOption
		END;

	WITH gStampOptions DO
		BEGIN
		shapeID   := 8;
		mode	  := NormalDrawing;
		spacing   := 1;
		fadeout   := kUndefinedOption;
		rate	  := kUndefinedOption;
		pressure  := 100;
		method	  := kClone1Method;
		check1	  := kUndefinedOption;
		wacom	  := kUndefinedOption
		END;

	NEW (gBrushesView);
	FailNil (gBrushesView);

	gBrushesView.IBrushesView

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE FreeTip (VAR tip: TTip);

	BEGIN

	IF tip.fMask  <> NIL THEN DisposHandle (tip.fMask);
	IF tip.fMask2 <> NIL THEN DisposHandle (tip.fMask2);

	IF tip.fData [0] <> NIL THEN DisposHandle (tip.fData [0]);
	IF tip.fData [1] <> NIL THEN DisposHandle (tip.fData [1]);
	IF tip.fData [2] <> NIL THEN DisposHandle (tip.fData [2]);
	IF tip.fData [3] <> NIL THEN DisposHandle (tip.fData [3])

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE LoadTip (VAR tip: TTip; id: INTEGER; view: TImageView);

	VAR
		band: INTEGER;
		pixels: INTEGER;
		template: HTipTemplate;

	BEGIN

	IF id = 0 THEN
		BEGIN

		IF gCustomSize.h = 0 THEN
			Failure (errNoCustomBrush, 0);

		tip.fSize := gCustomSize;

		tip.fSpot.h :=	gCustomSize.h	   DIV 2;
		tip.fSpot.v := (gCustomSize.v - 1) DIV 2

		END

	ELSE
		BEGIN

		template := HTipTemplate (Get1Resource ('TIP ', id));
		FailNil (template);

		HNoPurge (Handle (template));

		tip.fSize := template^^.size;
		tip.fSpot := template^^.spot

		END;

	pixels := tip.fSize.h * tip.fSize.v;

	tip.fMask := NewHandle (pixels);
	FailMemError;

	IF id = 0 THEN
		BlockMove (@gCustomTip, tip.fMask^, pixels)
	ELSE
		BEGIN
		BlockMove (@template^^.data, tip.fMask^, pixels);
		HPurge (Handle (template))
		END;

	tip.fMask2 := NewHandle (pixels);
	FailMemError;

	tip.fData [0] := NewHandle (pixels);
	FailMemError;

	tip.fData [1] := NewHandle (pixels);
	FailMemError;

	IF view.fChannel = kRGBChannels THEN
		BEGIN

		tip.fData [2] := NewHandle (pixels);
		FailMemError;

		tip.fData [3] := NewHandle (pixels);
		FailMemError;

		DoSetBytes (tip.fData [1]^, pixels, view.ForegroundByte (0));
		DoSetBytes (tip.fData [2]^, pixels, view.ForegroundByte (1));
		DoSetBytes (tip.fData [3]^, pixels, view.ForegroundByte (2))

		END

	ELSE
		BEGIN

		tip.fData [2] := NIL;
		tip.fData [3] := NIL;

		DoSetBytes (tip.fData [1]^, pixels, view.ForeGroundByte (0))

		END;

	MoveHHi (tip.fMask);
	HLock (tip.fMask);

	MoveHHi (tip.fMask2);
	HLock (tip.fMask2);

	FOR band := 0 TO 3 DO
		IF tip.fData [band] <> NIL THEN
			BEGIN
			MoveHHi (tip.fData [band]);
			HLock (tip.fData [band])
			END

	END;

{*****************************************************************************}

{$S ADoDraw}

FUNCTION TipCrossSection (tip: TTip): LONGINT;

	VAR
		r: INTEGER;
		c: INTEGER;
		sum: LONGINT;
		rows: INTEGER;
		cols: INTEGER;
		maxRow: LONGINT;
		maxCol: LONGINT;

	BEGIN

	rows := tip.fSize.v;
	cols := tip.fSize.h;

	maxRow := 0;

	FOR r := 0 TO rows - 1 DO
		BEGIN
		sum := 0;
		FOR c := 0 TO cols - 1 DO
			sum := sum + BAND (Ptr (ORD4 (tip.fMask^) + r * cols + c)^, $FF);
		IF maxRow < sum THEN maxRow := sum
		END;

	maxCol := 0;

	FOR c := 0 TO cols - 1 DO
		BEGIN
		sum := 0;
		FOR r := 0 TO rows - 1 DO
			sum := sum + BAND (Ptr (ORD4 (tip.fMask^) + r * cols + c)^, $FF);
		IF maxCol < sum THEN maxCol := sum
		END;

	TipCrossSection := Min (maxRow, maxCol)

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TMarkingTool.IMarkingTool (view: TImageView;
									 itsCommand: INTEGER;
									 cacheSize: Point;
									 failMessage: LONGINT;
									 needAlpha: BOOLEAN);

	VAR
		fi: FailInfo;
		channel: INTEGER;
		old: TMarkingTool;
		channels: INTEGER;
		aVMArray: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Free
		END;

	BEGIN

	fAlphaChannel := NIL;

	fChannel := view.fChannel;

	fMarkedArea := gZeroRect;

	fCachedArea := gZeroRect;

	fCacheSize := cacheSize;

	fUpperPage := -1;
	fLowerPage := -1;

	fLastPoint.h := -1;
	fLastPoint.v := -1;

	fAuxView   := NIL;
	fAuxCursor := FALSE;

	fFailMessage := failMessage;

	IBufferCommand (itsCommand, view);

	fViewConstrain := FALSE;
	fConstrainsMouse := TRUE;

	fPixelAlign := TRUE;
	fConstrainH := TRUE;
	fConstrainV := TRUE;

	CatchFailures (fi, CleanUp);

	IF MEMBER (gLastCommand, TMarkingTool) THEN
		IF gLastCommand.fChangedDocument = fDoc THEN
			BEGIN

			old := TMarkingTool (gLastCommand);

			fLastPoint := old.fLastPoint;

			fBuffer [0] := old.fBuffer [0];
			fBuffer [1] := old.fBuffer [1];
			fBuffer [2] := old.fBuffer [2];

			old.fBuffer [0] := NIL;
			old.fBuffer [1] := NIL;
			old.fBuffer [2] := NIL

			END;

	gApplication.CommitLastCommand;

	fDoc.KillEffect (TRUE);
	fDoc.FreeFloat;

	IF fChannel = kRGBChannels THEN
		channels := 3
	ELSE
		channels := 1;

	FOR channel := 0 TO 2 DO

		IF fBuffer [channel] <> NIL THEN

			IF channel >= channels THEN
				BEGIN
				fBuffer [channel] . Free;
				fBuffer [channel] := NIL
				END

			ELSE
				fBuffer [channel] . Undefine

		ELSE IF channel < channels THEN
			BEGIN
			aVMArray := NewVMArray (fDoc.fRows, fDoc.fCols, 1);
			fBuffer [channel] := aVMArray
			END;

	fPhysicalSize := fBuffer [0] . fPhysicalSize;

	IF NOT EmptyRect (fDoc.fSelectionRect) OR needAlpha THEN
		BEGIN

		aVMArray := NewVMArray (fDoc.fRows, fDoc.fCols, 1);
		fAlphaChannel := aVMArray;

		IF fDoc.fMode = IndexedColorMode THEN
			BEGIN
			DoSetBytes (@fAlphaMap [0  ], 128,	 0);
			DoSetBytes (@fAlphaMap [128], 128, 255)
			END
		ELSE
			fAlphaMap := gNullLUT

		END;

	Success (fi)

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TMarkingTool.Free; OVERRIDE;

	BEGIN

	FreeObject (fAlphaChannel);

	INHERITED Free

	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ADoDraw}

PROCEDURE TMarkingTool.TrackFeedBack (anchorPoint: Point;
									  nextPoint: Point;
									  turnItOn: BOOLEAN;
									  mouseDidMove: BOOLEAN); OVERRIDE;

	BEGIN
	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TMarkingTool.TrackConstrain (anchorPoint: Point;
									   previousPoint: Point;
									   VAR nextPoint: Point); OVERRIDE;

	VAR
		mag: INTEGER;
		delta: Point;
		offset: INTEGER;
		theKeys: KeyMap;

	BEGIN

	mag := fView.fMagnification;

	IF (mag > 1) AND fPixelAlign THEN
		BEGIN

		offset := BSL (mag, 6);

		nextPoint.h := (nextPoint.h + offset) DIV mag * mag - offset;
		nextPoint.v := (nextPoint.v + offset) DIV mag * mag - offset;

		IF fConstrainH AND fConstrainV THEN
			BEGIN
			anchorPoint.h := (anchorPoint.h + offset) DIV mag * mag - offset;
			anchorPoint.v := (anchorPoint.v + offset) DIV mag * mag - offset
			END

		END;

	IF fConstrainH AND fConstrainV THEN
		BEGIN

		delta.h := ABS (nextPoint.h - anchorPoint.h);
		delta.v := ABS (nextPoint.v - anchorPoint.v);

		IF delta.h > delta.v + gStdHysteresis.h THEN
			fConstrainH := FALSE

		ELSE IF delta.v > delta.h + gStdHysteresis.h THEN
			fConstrainV := FALSE

		END;

	GetKeys (theKeys);

	IF theKeys [kShiftCode] THEN
		BEGIN

		IF fConstrainH THEN
			nextPoint.h := anchorPoint.h;

		IF fConstrainV THEN
			nextPoint.v := anchorPoint.v

		END

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TMarkingTool.BuildAlpha (lower, upper: INTEGER);

	VAR
		r: Rect;
		srcPtr: Ptr;
		dstPtr: Ptr;
		line: INTEGER;

	BEGIN

	IF fAlphaChannel <> NIL THEN
		BEGIN

		FOR line := lower TO upper DO
			BEGIN

			dstPtr := fAlphaChannel.NeedPtr (line, line, TRUE);

			DoSetBytes (dstPtr, fDoc.fCols, 0);

			r := fDoc.fSelectionRect;

			IF r.bottom = r.top THEN
				BEGIN
				r.top	 := 0;
				r.left	 := 0;
				r.bottom := fDoc.fRows;
				r.right  := fDoc.fCols
				END;

			IF (line >= r.top) AND (line < r.bottom) THEN
				BEGIN

				dstPtr := Ptr (ORD4 (dstPtr) + r.left);

				IF fDoc.fSelectionMask = NIL THEN
					DoSetBytes (dstPtr,
								r.right - r.left,
								ORD (fAlphaMap [255]))

				ELSE
					BEGIN

					srcPtr := fDoc.fSelectionMask.NeedPtr (line - r.top,
														   line - r.top,
														   FALSE);

					BlockMove (srcPtr, dstPtr, r.right - r.left);

					fDoc.fSelectionMask.DoneWithPtr;

					DoMapBytes (dstPtr, r.right - r.left, fAlphaMap)

					END

				END;

			fAlphaChannel.DoneWithPtr

			END;

		IF fDoc.fSelectionMask <> NIL THEN
			fDoc.fSelectionMask.Flush

		END

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TMarkingTool.SaveLines (lower, upper: INTEGER);

	VAR
		r: Rect;
		srcPtr: Ptr;
		dstPtr: Ptr;
		page: INTEGER;
		line: INTEGER;
		channel: INTEGER;
		lowerPage: INTEGER;
		upperPage: INTEGER;
		blocksPerPage: INTEGER;

	BEGIN

	blocksPerPage := fBuffer [0] . fBlocksPerPage;

	lowerPage := lower DIV blocksPerPage;
	upperPage := upper DIV blocksPerPage;

	IF (lowerPage >= fLowerPage) & (upperPage <= fUpperPage) THEN
		EXIT (SaveLines);

	IF (fUpperPage = -1) OR (lowerPage < fLowerPage) AND
							(upperPage > fUpperPage) THEN
		BEGIN
		fLowerPage := lowerPage;
		fUpperPage := upperPage
		END

	ELSE IF lowerPage < fLowerPage THEN
		BEGIN
		upperPage  := fLowerPage - 1;
		fLowerPage := lowerPage
		END

	ELSE
		BEGIN
		lowerPage  := fUpperPage + 1;
		fUpperPage := upperPage
		END;

	IF fChannel = kRGBChannels THEN

		FOR channel := 0 TO 2 DO
			BEGIN

			FOR page := lowerPage TO upperPage DO
				BEGIN

				line := page * blocksPerPage;

				dstPtr := fBuffer [channel] . NeedPtr (line, line, TRUE);
				srcPtr := fDoc.fData [channel] . NeedPtr (line, line, FALSE);

				BlockMove (srcPtr, dstPtr, kVMPageSize);

				fDoc.fData [channel] . DoneWithPtr;
				fBuffer [channel] . DoneWithPtr

				END;

			fDoc.fData [channel] . Flush;
			fBuffer [channel] . Flush

			END

	ELSE
		BEGIN

		FOR page := lowerPage TO upperPage DO
			BEGIN

			line := page * blocksPerPage;

			dstPtr := fBuffer [0] . NeedPtr (line, line, TRUE);
			srcPtr := fDoc.fData [fChannel] . NeedPtr (line, line, FALSE);

			BlockMove (srcPtr, dstPtr, kVMPageSize);

			fDoc.fData [fChannel] . DoneWithPtr;
			fBuffer [0] . DoneWithPtr

			END;

		fDoc.fData [fChannel] . Flush;
		fBuffer [0] . Flush

		END

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TMarkingTool.AddToMarked (r: Rect);

	VAR
		area: Rect;

	BEGIN

	area := fMarkedArea;

	IF area.bottom = 0 THEN
		BEGIN
		BuildAlpha (r.top, r.bottom - 1);
		SaveLines  (r.top, r.bottom - 1);
		area := r
		END

	ELSE
		BEGIN

		IF r.left  < area.left	THEN area.left	:= r.left;
		IF r.right > area.right THEN area.right := r.right;

		IF r.top < area.top THEN
			BEGIN
			BuildAlpha (r.top, area.top - 1);
			SaveLines  (r.top, area.top - 1);
			area.top := r.top
			END;

		IF r.bottom > area.bottom THEN
			BEGIN
			BuildAlpha (area.bottom, r.bottom - 1);
			SaveLines  (area.bottom, r.bottom - 1);
			area.bottom := r.bottom
			END

		END;

	fMarkedArea := area

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TMarkingTool.DrawAuxCursor (pt: Point);

	VAR
		savePort: GrafPtr;

	BEGIN

	IF fAuxView <> fView THEN
		BEGIN
		GetPort (savePort);
		fAuxView.fFrame.Focus
		END;

	PenNormal;
	PenMode (patXor);

	MoveTo (pt.h - 7, pt.v);

	Line (14,  0);
	Move (-7, -7);
	Line ( 0, 14);

	fAuxCursor	 := NOT fAuxCursor;
	fAuxLocation := pt;

	IF fAuxView <> fView THEN
		SetPort (savePort)

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TMarkingTool.FlushCache;

	VAR
		r: Rect;
		rr: Rect;
		hideAux: BOOLEAN;

	BEGIN

	r := fCachedArea;

	IF r.bottom <> 0 THEN
		BEGIN

		hideAux := FALSE;

		IF (fAuxView = fView) & fAuxCursor THEN
			BEGIN

			rr.topLeft	:= fAuxLocation;
			rr.botRight := fAuxLocation;

			InsetRect (rr, -8, -8);

			IF SectRect (r, rr, rr) THEN
				BEGIN
				hideAux := TRUE;
				DrawAuxCursor (fAuxLocation)
				END

			END;

		fView.DrawNow (r, FALSE);

		IF hideAux THEN
			DrawAuxCursor (fAuxLocation);

		fCachedArea := gZeroRect

		END

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TMarkingTool.AddToCache (r: Rect);

	VAR
		vr: Rect;
		area: Rect;
		mag: INTEGER;

	BEGIN

	vr := r;

	mag := fView.fMagnification;

	IF mag > 1 THEN
		BEGIN
		vr.top	  := vr.top    * mag;
		vr.left   := vr.left   * mag;
		vr.bottom := vr.bottom * mag;
		vr.right  := vr.right  * mag
		END

	ELSE IF mag < 1 THEN
		BEGIN
		mag := -mag;
		vr.top	  := (vr.top	+ mag - 1) DIV mag;
		vr.left   := (vr.left	+ mag - 1) DIV mag;
		vr.bottom := (vr.bottom + mag - 1) DIV mag;
		vr.right  := (vr.right	+ mag - 1) DIV mag
		END;

	IF (vr.bottom > vr.top) AND (vr.right > vr.left) THEN
		BEGIN

		area := fCachedArea;

		IF area.bottom = 0 THEN
			fCachedArea := vr

		ELSE
			BEGIN

			IF vr.top	 < area.top    THEN area.top	:= vr.top;
			IF vr.left	 < area.left   THEN area.left	:= vr.left;
			IF vr.bottom > area.bottom THEN area.bottom := vr.bottom;
			IF vr.right  > area.right  THEN area.right	:= vr.right;

			IF (area.bottom - area.top <= fCacheSize.v) AND
			   (area.right - area.left <= fCacheSize.h) THEN
				fCachedArea := area

			ELSE
				BEGIN
				FlushCache;
				fCachedArea := vr
				END

			END

		END

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TMarkingTool.FixReleasePoint (anchorPoint: Point;
										VAR nextPoint: Point);

	VAR
		peekEvent: EventRecord;

	BEGIN

	IF EventAvail (mUpMask, peekEvent) THEN
		BEGIN

		nextPoint := peekEvent.where;

		GlobalToLocal (nextPoint);

		IF fConstrainsMouse THEN
			TrackConstrain (anchorPoint, nextPoint, nextPoint)

		END;

	IF PtInRect (nextPoint, fView.fExtentRect) THEN
		BEGIN

		fLastPoint := nextPoint;

		{$H-}
		fView.CvtView2Image (fLastPoint)
		{$H+}

		END

	ELSE
		BEGIN
		fLastPoint.h := -1;
		fLastPoint.v := -1
		END

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TMarkingTool.SwapRect (r: Rect; iArray, bArray: TVMArray);

	VAR
		iPtr: Ptr;
		bPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		IF iPtr <> NIL THEN iArray.DoneWithPtr;
		IF bPtr <> NIL THEN bArray.DoneWithPtr;

		iArray.Flush;
		bArray.Flush

		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	FOR row := r.top TO r.bottom - 1 DO
		BEGIN

		iPtr := NIL;
		bPtr := NIL;

		iPtr := Ptr (ORD4 (iArray.NeedPtr (row, row, TRUE)) + r.left);
		bPtr := Ptr (ORD4 (bArray.NeedPtr (row, row, TRUE)) + r.left);

		DoSwapBytes (iPtr, bPtr, r.right - r.left);

		iArray.DoneWithPtr;
		bArray.DoneWithPtr

		END;

	iArray.Flush;
	bArray.Flush;

	Success (fi)

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TMarkingTool.SwapMarkedArea;

	VAR
		r: Rect;

	BEGIN

	r := fMarkedArea;

	IF NOT EmptyRect (r) THEN
		IF fChannel = kRGBChannels THEN
			BEGIN
			SwapRect (r, fDoc.fData [0], fBuffer [0]);
			SwapRect (r, fDoc.fData [1], fBuffer [1]);
			SwapRect (r, fDoc.fData [2], fBuffer [2])
			END
		ELSE
			SwapRect (r, fDoc.fData [fChannel], fBuffer [0])

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TMarkingTool.FlushImage;

	VAR
		band: INTEGER;

	BEGIN

	FOR band := 0 TO kMaxChannels - 1 DO
		BEGIN

		IF fDoc.fData [band] <> NIL THEN
			fDoc.fData [band] . Flush;

		IF fDoc.fMagicData [band] <> NIL THEN
			fDoc.fMagicData [band] . Flush;

		IF gCloneDoc <> NIL THEN
			IF gCloneDoc.fData [band] <> NIL THEN
				gCloneDoc.fData [band] . Flush

		END;

	FOR band := 0 TO 3 DO
		IF gPattern [band] <> NIL THEN
			gPattern [band] . Flush

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TMarkingTool.RecoverFailure;

	VAR
		r: Rect;
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		EXIT (RecoverFailure)
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	IF fAuxCursor THEN
		DrawAuxCursor (fAuxLocation);

	IF NOT EmptyRect (fMarkedArea) THEN
		BEGIN

		MoveHands (FALSE);

		SwapMarkedArea;

		r := fMarkedArea;

		fView.UpdateImageArea (r, FALSE)

		END;

	Success (fi)

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TMarkingTool.DoIt; OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	IF fAlphaChannel <> NIL THEN
		BEGIN
		fAlphaChannel.Free;
		fAlphaChannel := NIL
		END;

	IF NOT EmptyRect (fDoc.fSelectionRect) THEN
		fView.DoHighlightSelection (HLOff, HLOn);

	fView.DoDrawExtraFeedback (fView.fExtentRect);

	IF fDoc.fViewList.fSize > 1 THEN
		BEGIN

		r := fMarkedArea;

		fDoc.UpdateImageArea (r, FALSE, FALSE, fChannel)

		END

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TMarkingTool.UndoIt; OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	MoveHands (FALSE);

	SwapMarkedArea;

	r := fMarkedArea;

	fDoc.UpdateImageArea (r, TRUE, TRUE, fChannel)

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TMarkingTool.RedoIt; OVERRIDE;

	BEGIN
	UndoIt
	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TEraserTool.IEraserTool (view: TImageView; magic: BOOLEAN);

	VAR
		cacheSize: Point;

	BEGIN

	fMagic := magic;

	cacheSize.h := 32;
	cacheSize.v := 32;

	IMarkingTool (view, cErasing, cacheSize, msgCannotErase, FALSE);

	fPixelAlign := FALSE;

	IF fChannel = kRGBChannels THEN
		BEGIN
		fColor1 := view.BackGroundByte (0);
		fColor2 := view.BackGroundByte (1);
		fColor3 := view.BackGroundByte (2)
		END
	ELSE
		fColor1 := view.BackGroundByte (fChannel)

	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ADoDraw}

FUNCTION TEraserTool.TrackMouse (aTrackPhase: TrackPhase;
								 VAR anchorPoint: Point;
								 VAR previousPoint: Point;
								 VAR nextPoint: Point;
								 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

	VAR
		fi: FailInfo;
		mag: INTEGER;
		startPt: Point;
		lastRect: Rect;
		blocksPerPage: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN
		RecoverFailure;
		FlushImage;
		message := fFailMessage;
		Free;
		Failure (error, message)
		END;

	PROCEDURE EraseRect (r: Rect;
						 band: INTEGER;
						 color: INTEGER;
						 update: BOOLEAN);

		VAR
			dstPtr: Ptr;
			srcPtr: Ptr;
			fi: FailInfo;
			alphaPtr: Ptr;
			rows: INTEGER;
			cols: INTEGER;

		PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
			BEGIN
			fDoc.fData [band] . DoneWithPtr;
			IF srcPtr <> NIL THEN
				fDoc.fMagicData [band] . DoneWithPtr
			END;

		BEGIN

		srcPtr := NIL;

		dstPtr := fDoc.fData [band] . NeedPtr (r.top,
											   r.bottom - 1,
											   TRUE);
		dstPtr := Ptr (ORD4 (dstPtr) + r.left);

		CatchFailures (fi, CleanUp);

		IF fMagic THEN
			BEGIN
			srcPtr := fDoc.fMagicData [band] . NeedPtr (r.top,
														r.bottom - 1,
														FALSE);
			srcPtr := Ptr (ORD4 (srcPtr) + r.left)
			END;

		rows := r.bottom - r.top;
		cols := r.right - r.left;

		IF fAlphaChannel = NIL THEN
			IF fMagic THEN
				DoMagicRect (srcPtr, dstPtr, fPhysicalSize, rows, cols)
			ELSE
				DoEraseRect (dstPtr, fPhysicalSize, rows, cols, color)

		ELSE
			BEGIN

			alphaPtr := fAlphaChannel.NeedPtr (r.top, r.bottom - 1, update);
			alphaPtr := Ptr (ORD4 (alphaPtr) + r.left);

			IF fMagic THEN
				DoAlphaMagicRect (srcPtr, dstPtr, alphaPtr,
								  fPhysicalSize, rows, cols)
			ELSE
				DoAlphaEraseRect (dstPtr, alphaPtr,
								  fPhysicalSize, rows, cols, color);

			IF update THEN
				DoEraseRect (alphaPtr, fPhysicalSize, rows, cols, 0);

			fAlphaChannel.DoneWithPtr

			END;

		Success (fi);

		CleanUp (0, 0)

		END;

	PROCEDURE UpdateRect (r: Rect);

		VAR
			rr: Rect;

		BEGIN

		IF (r.right > r.left) AND (r.bottom > r.top) THEN
			BEGIN

			AddToMarked (r);

			rr := r;

				REPEAT

				rr.bottom := Min ((rr.top DIV blocksPerPage + 1) *
								  blocksPerPage, r.bottom);

				IF fChannel = kRGBChannels THEN
					BEGIN
					EraseRect (rr, 0, fColor1, FALSE);
					EraseRect (rr, 1, fColor2, FALSE);
					EraseRect (rr, 2, fColor3, TRUE)
					END
				ELSE
					EraseRect (rr, fChannel, fColor1, TRUE);

				rr.top := rr.bottom

				UNTIL rr.top = r.bottom;

			AddToCache (r)

			END

		END;

	PROCEDURE ErasePoint (pt: Point);

		VAR
			r: Rect;
			rr: Rect;
			rrr: Rect;
			half: INTEGER;
			rows: INTEGER;
			cols: INTEGER;

		BEGIN

		r.top	 := pt.v - 8;
		r.left	 := pt.h - 8;
		r.bottom := pt.v + 8;
		r.right  := pt.h + 8;

		IF mag > 1 THEN
			BEGIN
			half := BSR (mag, 1);
			r.top	 := (r.top	  + half) DIV mag;
			r.left	 := (r.left   + half) DIV mag;
			r.bottom := (r.bottom + half) DIV mag;
			r.right  := (r.right  + half) DIV mag
			END

		ELSE IF mag < 1 THEN
			BEGIN
			r.top	 := r.top	 * (-mag);
			r.left	 := r.left	 * (-mag);
			r.bottom := r.bottom * (-mag);
			r.right  := r.right  * (-mag)
			END;

		rows := fDoc.fRows;
		cols := fDoc.fCols;

		IF r.top	< 0    THEN r.top	 := 0;
		IF r.left	< 0    THEN r.left	 := 0;
		IF r.bottom > rows THEN r.bottom := rows;
		IF r.right	> cols THEN r.right  := cols;

		IF (r.left	 >= lastRect.right ) |
		   (r.top	 >= lastRect.bottom) |
		   (r.right  <= lastRect.left  ) |
		   (r.bottom <= lastRect.top   ) THEN
			BEGIN

			UpdateRect (r);

			lastRect := r

			END

		ELSE
			BEGIN

			rrr := r;

			IF r.top < lastRect.top THEN
				BEGIN

				rr := r;
				rr.bottom := lastRect.top;

				UpdateRect (rr);

				r.top := lastRect.top

				END;

			IF r.bottom > lastRect.bottom THEN
				BEGIN

				rr := r;
				rr.top := lastRect.bottom;

				UpdateRect (rr);

				r.bottom := lastRect.bottom

				END;

			IF r.left < lastRect.left THEN
				BEGIN

				rr := r;
				rr.right := lastRect.left;

				UpdateRect (rr)

				END;

			IF r.right > lastRect.right THEN
				BEGIN

				rr := r;
				r.left := lastRect.right;

				UpdateRect (rr)

				END;

			lastRect := rrr

			END

		END;

	BEGIN

	TrackMouse := SELF;

	fView.TrackRulers;

	startPt := previousPoint;

	IF aTrackPhase = TrackPress THEN
		BEGIN

		IF gEventInfo.theShiftKey AND (fLastPoint.h >= 0) THEN
			BEGIN
			startPt := fLastPoint;
			fView.CvtImage2View (startPt, kRoundDown)
			END

		END

	ELSE IF aTrackPhase = TrackRelease THEN
		FixReleasePoint (anchorPoint, nextPoint);

	IF mouseDidMove THEN
		BEGIN

		CatchFailures (fi, CleanUp);

		mag := fView.fMagnification;

		blocksPerPage := fBuffer [0] . fBlocksPerPage;

		lastRect := gZeroRect;

		InterpolatePoints (startPt, nextPoint, ErasePoint);

		FlushCache;

		Success (fi)

		END;

	IF aTrackPhase = TrackRelease THEN FlushImage

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE FailBadMode (view: TImageView;
					   soft: BOOLEAN;
					   mode: TDrawingMode);

	VAR
		doc: TImageDocument;

	BEGIN

	doc := TImageDocument (view.fDocument);

	IF doc.fMode = HalftoneMode THEN
		Failure (errNoHalftone, 0);

	IF doc.fMode = IndexedColorMode THEN
		IF soft THEN
			Failure (errNoIndexedColor, 0)
		ELSE IF mode = DarkenOnly THEN
			Failure (errNoDarkenOnly, 0)
		ELSE IF mode = LightenOnly THEN
			Failure (errNoLightenOnly, 0);

	IF view.fChannel <> kRGBChannels THEN
		IF mode = ColorOnly THEN
			Failure (errNoColorOnly, 0)

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE GetMagicData (view: TImageView; tool: TTool; needChange: BOOLEAN);

	VAR
		err: OSErr;
		fi: FailInfo;
		channel: INTEGER;
		anAppFile: AppFile;
		doc: TImageDocument;
		temp: TImageDocument;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		temp.fRevertInfo := NIL;
		temp.Free
		END;

	BEGIN

	doc := TImageDocument (view.fDocument);

	IF NOT doc.CanRevert THEN
		IF doc.fSaveExists OR doc.fImported THEN
			BEGIN
			IF needChange THEN Failure (errNoChangeSince, 0)
			END
		ELSE
			Failure (errNeverSaved, 0);

	IF doc.fMode <> doc.fMagicMode THEN
		Failure (errModeChanged, 0);

	IF (doc.fRows <> doc.fMagicRows) OR
	   (doc.fCols <> doc.fMagicCols) THEN
		Failure (errSizeChanged, 0);

	IF view.fChannel >= doc.fMagicChannels THEN
		Failure (errNewChannel, 0);

	IF doc.fMagicData [0] <> NIL THEN
		EXIT (GetMagicData);

	MoveHands (TRUE);

	temp := TImageDocument (gApplication.DoMakeDocument (cMouseCommand));

	CatchFailures (fi, CleanUp);

	temp.fTitle 	 := doc.fTitle;
	temp.fFileType	 := doc.fFileType;
	temp.fCreator	 := doc.fCreator;
	temp.fVolRefNum  := doc.fVolRefNum;
	temp.fModDate	 := doc.fModDate;
	temp.fSaveExists := TRUE;

	temp.fFormatCode := doc.fFormatCode;
	temp.fRevertInfo := doc.fRevertInfo;

	err := temp.DiskFileChanged (TRUE);

	IF err <> noErr THEN Failure (errFileModified, 0);

	anAppFile.fName := '';

	gFormatCode := doc.fFormatCode;

	temp.ReadFromFile (anAppFile, kForDisplay);

	IF (doc.fMagicRows <> temp.fRows) OR
	   (doc.fMagicCols <> temp.fCols) OR
	   (doc.fMagicMode <> temp.fMode) OR
	   (doc.fMagicChannels <> temp.fChannels) THEN
		Failure (errFileModified, 0);

	FOR channel := 0 TO temp.fChannels - 1 DO
		BEGIN
		doc.fMagicData [channel] := temp.fData [channel];
		temp.fData [channel] := NIL
		END;

	Success (fi);

	CleanUp (0, 0);

	SetToolCursor (tool, TRUE);

	gMovingHands := FALSE

	END;

{*****************************************************************************}

{$S ADoDraw}

FUNCTION DoEraserTool (view: TImageView; magic: BOOLEAN): TCommand;

	VAR
		fi: FailInfo;
		anEraserTool: TEraserTool;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF magic THEN
			FailNewMessage (error, message, msgCannotMagic)
		ELSE
			FailNewMessage (error, message, msgCannotErase)
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	FailBadMode (view, FALSE, NormalDrawing);

	IF magic THEN GetMagicData (view, MagicTool, TRUE);

	NEW (anEraserTool);
	FailNil (anEraserTool);

	anEraserTool.IEraserTool (view, magic);

	Success (fi);

	DoEraserTool := anEraserTool

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TDrawingTool.IDrawingTool (view: TImageView;
									 itsCommand: INTEGER;
									 VAR tip: TTip;
									 mode: TDrawingMode;
									 spacing: INTEGER;
									 fadeout: INTEGER;
									 rate: INTEGER;
									 failMessage: LONGINT;
									 needAlpha: BOOLEAN);

	CONST
		kCallOverhead = 200;

	VAR
		s: LONGINT;
		p: LONGINT;
		mag: INTEGER;
		goal: INTEGER;
		cacheSize: Point;
		maxInvalid: INTEGER;

	BEGIN

	fTip	 := tip;
	fMode	 := mode;
	fSpacing := spacing;
	fFadeout := fadeout;

	IF rate = 0 THEN
		fDelay := 0
	ELSE
		fDelay := 60 DIV rate;

	fPressureMode := 0;

	fStampMethod := -1;

	fTextureNoise := NIL;

	s := Max (1, fSpacing);
	p := Max (fTip.fSize.h, fTip.fSize.v);

	mag := view.fMagnification;

	IF mag > 1 THEN
		BEGIN
		s := s * mag;
		p := p * mag
		END

	ELSE IF mag < 1 THEN
		BEGIN
		mag := -mag;
		s := (s + mag - 1) DIV mag;
		p := (p + mag - 1) DIV mag
		END;

	goal := (SQR (p - s) + kCallOverhead) DIV SQR (s);

	maxInvalid := 1;

	WHILE SQR (maxInvalid + 1) <= goal DO
		maxInvalid := maxInvalid + 1;

	cacheSize.h := fTip.fSize.h + maxInvalid - 1;
	cacheSize.v := fTip.fSize.v + maxInvalid - 1;

	view.CvtImage2View (cacheSize, kRoundUp);

	IMarkingTool (view, itsCommand, cacheSize, failMessage, needAlpha);

	fSpacingCounter := 1;

	fDrawings := 0

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TDrawingTool.Free; OVERRIDE;

	VAR
		tip: TTip;

	BEGIN

	tip := fTip;

	FreeTip (tip);

	IF fTextureNoise <> NIL THEN DisposHandle (fTextureNoise);

	INHERITED Free

	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ADoDraw}

PROCEDURE TDrawingTool.FindMask (offset: LONGINT; r: Rect);

	VAR
		alphaPtr: Ptr;

	BEGIN

	BlockMove (fTip.fMask^,
			   fTip.fMask2^,
			   fTip.fSize.h * fTip.fSize.v);

	IF fAlphaChannel <> NIL THEN
		BEGIN

		alphaPtr := fAlphaChannel.NeedPtr (r.top, r.bottom - 1, TRUE);

		DoAlphaMask (Ptr (ORD4 (fTip.fMask2^) + offset),
					 Ptr (ORD4 (alphaPtr) + r.left),
					 fTip.fSize.h,
					 fAlphaChannel.fPhysicalSize,
					 r.bottom - r.top,
					 r.right - r.left);

		fAlphaChannel.DoneWithPtr

		END

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TDrawingTool.BlurOrSharpen (dataPtr: Ptr;
									  offset: LONGINT;
									  r: Rect;
									  band: INTEGER;
									  sharpen: BOOLEAN);

	VAR
		rr: Rect;
		rrr: Rect;
		srcPtr: Ptr;
		srcWidth: INTEGER;
		tempWidth: INTEGER;
		tempHeight: INTEGER;

	BEGIN

	IF (r.top  = 0) OR (r.bottom = fDoc.fRows) OR
	   (r.left = 0) OR (r.right  = fDoc.fCols) THEN
		BEGIN

		rr := r;

		InsetRect (rr, -1, -1);

		tempWidth  := rr.right - rr.left;
		tempHeight := rr.bottom - rr.top;

		rrr := rr;

		IF rrr.top	  < 0		   THEN rrr.top    := 0;
		IF rrr.left   < 0		   THEN rrr.left   := 0;
		IF rrr.bottom > fDoc.fRows THEN rrr.bottom := fDoc.fRows;
		IF rrr.right  > fDoc.fCols THEN rrr.right  := fDoc.fCols;

		DoGetTip (Ptr (ORD4 (dataPtr) +
					   ORD4 (rrr.top - r.top) * fPhysicalSize +
					   (rrr.left - r.left)),
				  Ptr (ORD4 (gBuffer) +
					   (rrr.top - rr.top) * tempWidth +
					   (rrr.left - rr.left)),
				  fPhysicalSize,
				  tempWidth,
				  rrr.bottom - rrr.top,
				  rrr.right - rrr.left);

		IF r.top = 0 THEN
			DoGetTip (Ptr (ORD4 (gBuffer) + tempWidth),
					  gBuffer,
					  tempWidth,
					  tempWidth,
					  1,
					  tempWidth);

		IF r.bottom = fDoc.fRows THEN
			DoGetTip (Ptr (ORD4 (gBuffer) + (tempHeight - 2) * tempWidth),
					  Ptr (ORD4 (gBuffer) + (tempHeight - 1) * tempWidth),
					  tempWidth,
					  tempWidth,
					  1,
					  tempWidth);

		IF r.left = 0 THEN
			DoGetTip (Ptr (ORD4 (gBuffer) + 1),
					  gBuffer,
					  tempWidth,
					  tempWidth,
					  tempHeight,
					  1);

		IF r.right = fDoc.fCols THEN
			DoGetTip (Ptr (ORD4 (gBuffer) + tempWidth - 2),
					  Ptr (ORD4 (gBuffer) + tempWidth - 1),
					  tempWidth,
					  tempWidth,
					  tempHeight,
					  1);

		srcPtr	 := Ptr (ORD4 (gBuffer) + tempWidth + 1);
		srcWidth := tempWidth

		END

	ELSE
		BEGIN
		srcPtr	 := dataPtr;
		srcWidth := fPhysicalSize
		END;

	IF sharpen THEN
		DoGetSharpened (srcPtr,
						Ptr (ORD4 (fTip.fData [band]^) + offset),
						srcWidth,
						fTip.fSize.h,
						r.bottom - r.top,
						r.right - r.left)

	ELSE
		DoGetBlurred (srcPtr,
					  Ptr (ORD4 (fTip.fData [band]^) + offset),
					  srcWidth,
					  fTip.fSize.h,
					  r.bottom - r.top,
					  r.right - r.left)

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TDrawingTool.SmudgeBand (dataPtr: Ptr;
								   offset: LONGINT;
								   r: Rect;
								   band: INTEGER);

	BEGIN

	DoGetTip (dataPtr,
			  Ptr (ORD4 (fTip.fData [0]^) + offset),
			  fPhysicalSize,
			  fTip.fSize.h,
			  r.bottom - r.top,
			  r.right - r.left);

	IF fDrawings <> 0 THEN
		DoMixBytes (fTip.fData [band]^,
					fTip.fData [0]^,
					fMixMap,
					fTip.fSize.h * fTip.fSize.v)

	ELSE IF NOT fDip THEN
		BlockMove (fTip.fData [0]^,
				   fTip.fData [band]^,
				   fTip.fSize.h * fTip.fSize.v)

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TDrawingTool.MarkBand (dataPtr: Ptr;
								 offset: LONGINT;
								 r: Rect;
								 band: INTEGER);

	VAR
		noiseOffset: LONGINT;

	BEGIN

	IF (fCmdNumber = cBlurring) OR (fCmdNumber = cSharpening) THEN
		BlurOrSharpen (dataPtr, offset, r, band, fCmdNumber = cSharpening)

	ELSE IF fCmdNumber = cSmudging THEN
		SmudgeBand (dataPtr, offset, r, band);

	IF fMode = DarkenOnly THEN
		DoDrawTipDarken (dataPtr,
						 Ptr (ORD4 (fTip.fMask2^) + offset),
						 Ptr (ORD4 (fTip.fData [band]^) + offset),
						 fPhysicalSize,
						 fTip.fSize.h,
						 r.bottom - r.top,
						 r.right - r.left)

	ELSE IF fMode = LightenOnly THEN
		DoDrawTipLighten (dataPtr,
						  Ptr (ORD4 (fTip.fMask2^) + offset),
						  Ptr (ORD4 (fTip.fData [band]^) + offset),
						  fPhysicalSize,
						  fTip.fSize.h,
						  r.bottom - r.top,
						  r.right - r.left)

	ELSE
		DoDrawTip (dataPtr,
				   Ptr (ORD4 (fTip.fMask2^) + offset),
				   Ptr (ORD4 (fTip.fData [band]^) + offset),
				   fPhysicalSize,
				   fTip.fSize.h,
				   r.bottom - r.top,
				   r.right - r.left);

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TDrawingTool.MarkRGB (rDataPtr: Ptr;
								gDataPtr: Ptr;
								bDataPtr: Ptr;
								offset: LONGINT;
								r: Rect);

	VAR
		band: INTEGER;
		sharpen: BOOLEAN;
		noiseOffset: LONGINT;

	BEGIN

	IF fMode <> ColorOnly THEN
		BEGIN
		MarkBand (rDataPtr, offset, r, 1);
		MarkBand (gDataPtr, offset, r, 2);
		MarkBand (bDataPtr, offset, r, 3)
		END

	ELSE
		BEGIN

		IF (fCmdNumber = cBlurring) OR (fCmdNumber = cSharpening) THEN
			BEGIN
			sharpen := (fCmdNumber = cSharpening);
			BlurOrSharpen (rDataPtr, offset, r, 1, sharpen);
			BlurOrSharpen (gDataPtr, offset, r, 2, sharpen);
			BlurOrSharpen (bDataPtr, offset, r, 3, sharpen)
			END

		ELSE IF fCmdNumber = cSmudging THEN
			BEGIN
			SmudgeBand (rDataPtr, offset, r, 1);
			SmudgeBand (gDataPtr, offset, r, 2);
			SmudgeBand (bDataPtr, offset, r, 3)
			END;

		DoDrawTipColor (gGrayLUT,
						rDataPtr,
						gDataPtr,
						bDataPtr,
						Ptr (ORD4 (fTip.fMask2^) + offset),
						Ptr (ORD4 (fTip.fData [1]^) + offset),
						Ptr (ORD4 (fTip.fData [2]^) + offset),
						Ptr (ORD4 (fTip.fData [3]^) + offset),
						fPhysicalSize,
						fTip.fSize.h,
						r.bottom - r.top,
						r.right - r.left)

		END

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TDrawingTool.LoadOverlap (r: Rect;
									srcArray1: TVMArray;
									srcArray2: TVMArray;
									srcArray3: TVMArray);

	VAR
		rr: Rect;
		rows: INTEGER;
		cols: INTEGER;
		offset: LONGINT;

	PROCEDURE DoLoadOverlap (srcArray: TVMArray; band: INTEGER);

		VAR
			srcPtr: Ptr;

		BEGIN

		srcPtr := srcArray.NeedPtr (rr.top, rr.bottom - 1, FALSE);

		DoGetTip (Ptr (ORD4 (srcPtr) + rr.left),
				  Ptr (ORD4 (fTip.fData [band]^) + offset),
				  srcArray.fPhysicalSize,
				  fTip.fSize.h,
				  rr.bottom - rr.top,
				  rr.right - rr.left);

		srcArray.DoneWithPtr

		END;

	BEGIN

	rr := r;

	offset := 0;

	rows := srcArray1.fBlockCount;
	cols := srcArray1.fLogicalSize;

	IF (rr.top	< 0) OR (rr.bottom > rows) OR
	   (rr.left < 0) OR (rr.right  > cols) THEN
		BEGIN

		IF rr.left < 0 THEN
			BEGIN
			offset	:= -rr.left;
			rr.left := 0
			END;

		IF rr.top < 0 THEN
			BEGIN
			offset := offset - rr.top * fTip.fSize.h;
			rr.top := 0
			END;

		IF rr.right > cols THEN
			rr.right := cols;

		IF rr.bottom > rows THEN
			rr.bottom := rows

		END;

	DoLoadOverlap (srcArray1, 1);

	IF srcArray2 <> NIL THEN
		BEGIN
		DoLoadOverlap (srcArray2, 2);
		DoLoadOverlap (srcArray3, 3)
		END

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TDrawingTool.LoadCloneTip (r: Rect);

	VAR
		rr: Rect;
		j: INTEGER;
		width: INTEGER;
		height: INTEGER;
		offset: LONGINT;
		buffer: ARRAY [0..2] OF Ptr;

	PROCEDURE DoMoveClone (srcArray: TVMArray;
						   srcRect: Rect;
						   dstPtr: Ptr;
						   dstWidth: INTEGER);

		VAR
			srcPtr: Ptr;

		BEGIN

		srcPtr := srcArray.NeedPtr (srcRect.top,
									srcRect.bottom - 1, FALSE);

		DoGetTip (Ptr (ORD4 (srcPtr) + srcRect.left),
				  dstPtr,
				  srcArray.fPhysicalSize,
				  dstWidth,
				  srcRect.bottom - srcRect.top,
				  srcRect.right - srcRect.left);

		srcArray.DoneWithPtr

		END;

	PROCEDURE DoLoadClone (srcArray: TVMArray; band: INTEGER);

		BEGIN

		DoMoveClone (srcArray,
					 rr,
					 Ptr (ORD4 (fTip.fData [band]^) + offset),
					 fTip.fSize.h)

		END;

	BEGIN

	rr := r;

	OffsetRect (rr, fStampOffset.h, fStampOffset.v);

	offset := 0;

	IF (rr.top	< 0) OR (rr.bottom > gCloneDoc.fRows) OR
	   (rr.left < 0) OR (rr.right  > gCloneDoc.fCols) THEN
		BEGIN

		IF fChannel = kRGBChannels THEN
			LoadOverlap (r, fDoc.fData [0], fDoc.fData [1], fDoc.fData [2])
		ELSE
			LoadOverlap (r, fDoc.fData [fChannel], NIL, NIL);

		IF rr.left < 0 THEN
			BEGIN
			offset	:= -rr.left;
			rr.left := 0
			END;

		IF rr.top < 0 THEN
			BEGIN
			offset := offset - rr.top * fTip.fSize.h;
			rr.top := 0
			END;

		IF rr.right > gCloneDoc.fCols THEN
			rr.right := gCloneDoc.fCols;

		IF rr.bottom > gCloneDoc.fRows THEN
			rr.bottom := gCloneDoc.fRows;

		IF EmptyRect (rr) THEN EXIT (LoadCloneTip)

		END;

	IF fChannel = kRGBChannels THEN
		BEGIN

		IF gCloneChannel = kRGBChannels THEN

			IF fDoc = gCloneDoc THEN
				BEGIN
				SaveLines (rr.top, rr.bottom - 1);
				DoLoadClone (fBuffer [0], 1);
				DoLoadClone (fBuffer [1], 2);
				DoLoadClone (fBuffer [2], 3)
				END

			ELSE
				BEGIN
				DoLoadClone (gCloneDoc.fData [0], 1);
				DoLoadClone (gCloneDoc.fData [1], 2);
				DoLoadClone (gCloneDoc.fData [2], 3)
				END

		ELSE IF (gCloneChannel <= 2) AND (fDoc = gCloneDoc) THEN
			BEGIN
			SaveLines (rr.top, rr.bottom - 1);
			DoLoadClone (fBuffer [gCloneChannel], 1);
			DoLoadClone (fBuffer [gCloneChannel], 2);
			DoLoadClone (fBuffer [gCloneChannel], 3)
			END

		ELSE
			BEGIN
			DoLoadClone (gCloneDoc.fData [gCloneChannel], 1);
			DoLoadClone (gCloneDoc.fData [gCloneChannel], 2);
			DoLoadClone (gCloneDoc.fData [gCloneChannel], 3)
			END

		END

	ELSE IF gCloneChannel = kRGBChannels THEN
		BEGIN

		IF (fDoc = gCloneDoc) AND (fChannel <= 2) THEN
			SaveLines (rr.top, rr.bottom - 1);

		buffer [0] := gBuffer;
		buffer [1] := Ptr (ORD4 (buffer [0]) + kMaxTipArea);
		buffer [2] := Ptr (ORD4 (buffer [1]) + kMaxTipArea);

		width  := rr.right - rr.left;
		height := rr.bottom - rr.top;

		FOR j := 0 TO 2 DO
			IF (fDoc = gCloneDoc) AND (fChannel = j) THEN
				DoMoveClone (fBuffer [0], rr, buffer [j], width)
			ELSE
				DoMoveClone (gCloneDoc.fData [j], rr, buffer [j], width);

		DoMakeMonochrome (buffer [0], gGrayLUT.R,
						  buffer [1], gGrayLUT.G,
						  buffer [2], gGrayLUT.B,
						  buffer [0], width * height);

		DoGetTip (buffer [0],
				  Ptr (ORD4 (fTip.fData [1]^) + offset),
				  width,
				  fTip.fSize.h,
				  height,
				  width)

		END

	ELSE IF (fDoc = gCloneDoc) AND (fChannel = gCloneChannel) THEN
		BEGIN
		SaveLines (rr.top, rr.bottom - 1);
		DoLoadClone (fBuffer [0], 1)
		END

	ELSE
		DoLoadClone (gCloneDoc.fData [gCloneChannel], 1)

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TDrawingTool.LoadRevertTip (r: Rect);

	BEGIN

	IF fChannel = kRGBChannels THEN
		LoadOverlap (r,
					 fDoc.fMagicData [0],
					 fDoc.fMagicData [1],
					 fDoc.fMagicData [2])
	ELSE
		LoadOverlap (r,
					 fDoc.fMagicData [fChannel],
					 NIL,
					 NIL)

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TDrawingTool.LoadTextureTip;

	VAR
		noisePtr: Ptr;
		pixels: INTEGER;

	BEGIN

	noisePtr := Ptr (ORD4 (fTextureNoise^) + BAND (fDrawings, $F));

	IF fChannel = kRGBChannels THEN
		BEGIN
		ScrambleTexture (@gTexture [1], noisePtr);
		ScrambleTexture (@gTexture [2], noisePtr);
		ScrambleTexture (@gTexture [3], noisePtr)
		END
	ELSE
		ScrambleTexture (@gTexture [0], noisePtr);

	pixels := fTip.fSize.h * fTip.fSize.v;

	BlockMove (fTextureNoise^, fTip.fData [1]^, pixels);

	IF fChannel = kRGBChannels THEN
		BEGIN

		BlockMove (fTip.fData [1]^, fTip.fData [2]^, pixels);
		BlockMove (fTip.fData [1]^, fTip.fData [3]^, pixels);

		DoMapBytes (fTip.fData [1]^, pixels, gTexture [1]);
		DoMapBytes (fTip.fData [2]^, pixels, gTexture [2]);
		DoMapBytes (fTip.fData [3]^, pixels, gTexture [3])

		END

	ELSE
		DoMapBytes (fTip.fData [1]^, pixels, gTexture [0])

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TDrawingTool.LoadPatternTip (r: Rect);

	VAR
		pt: Point;
		width: INTEGER;
		height: INTEGER;

	PROCEDURE DoLoadPattern (srcArray: TVMArray; band: INTEGER);

		VAR
			srcPtr: Ptr;

		BEGIN

		srcPtr := srcArray.NeedPtr (pt.v,
									pt.v + r.bottom - r.top - 1,
									FALSE);

		DoGetTip (Ptr (ORD4 (srcPtr) + pt.h),
				  fTip.fData [band]^,
				  srcArray.fPhysicalSize,
				  fTip.fSize.h,
				  r.bottom - r.top,
				  r.right - r.left);

		srcArray.DoneWithPtr

		END;

	BEGIN

	width  := gPatternRect.right - gPatternRect.left;
	height := gPatternRect.bottom - gPatternRect.top;

	pt := r.topLeft;

	pt.v := pt.v + gPatternRect.top  - fStampOffset.v;
	pt.h := pt.h + gPatternRect.left - fStampOffset.h;

	IF pt.v < 0 THEN
		pt.v := height - 1 - (-pt.v - 1) MOD height
	ELSE
		pt.v := pt.v MOD height;

	IF pt.h < 0 THEN
		pt.h := width - 1 - (-pt.h - 1) MOD width
	ELSE
		pt.h := pt.h MOD width;

	IF fChannel = kRGBChannels THEN

		IF gPattern [1] <> NIL THEN
			BEGIN
			DoLoadPattern (gPattern [1], 1);
			DoLoadPattern (gPattern [2], 2);
			DoLoadPattern (gPattern [3], 3)
			END

		ELSE
			BEGIN
			DoLoadPattern (gPattern [0], 1);
			DoLoadPattern (gPattern [0], 2);
			DoLoadPattern (gPattern [0], 3)
			END

	ELSE
		DoLoadPattern (gPattern [0], 1)

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TDrawingTool.LoadImpressTip (pt: Point);

	PROCEDURE DoLoadImpress (srcArray: TVMArray; band: INTEGER);

		VAR
			p: Ptr;

		BEGIN

		p := Ptr (ORD4 (srcArray.NeedPtr (pt.v, pt.v, FALSE)) + pt.h);

		DoSetBytes (fTip.fData [band]^, fTip.fSize.h * fTip.fSize.v, p^);

		srcArray.DoneWithPtr

		END;

	BEGIN

	{$IFC qBarneyscan}
	Failure (errNotYetImp, 0);
	{$ENDC}

	fImpressCounter := fImpressCounter - 1;

	IF fImpressCounter >= 0 THEN EXIT (LoadImpressTip);

	IF fSpacing = 1 THEN
		fImpressCounter := Max (fTip.fSize.h, fTip.fSize.v)
	ELSE
		fImpressCounter := 0;

	fImpressTimer := TickCount;

	IF fChannel = kRGBChannels THEN
		BEGIN
		DoLoadImpress (fDoc.fMagicData [0], 1);
		DoLoadImpress (fDoc.fMagicData [1], 2);
		DoLoadImpress (fDoc.fMagicData [2], 3)
		END
	ELSE
		DoLoadImpress (fDoc.fMagicData [fChannel], 1)

	END;

{*****************************************************************************}

{$S ADoDraw}

FUNCTION TDrawingTool.TrackMouse (aTrackPhase: TrackPhase;
								  VAR anchorPoint: Point;
								  VAR previousPoint: Point;
								  VAR nextPoint: Point;
								  mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

	VAR
		pt1: Point;
		pt2: Point;
		fi: FailInfo;
		mag: INTEGER;
		auxPt: Point;
		bounds: Rect;
		dataPtr: Ptr;
		rows: INTEGER;
		cols: INTEGER;
		rDataPtr: Ptr;
		gDataPtr: Ptr;
		bDataPtr: Ptr;
		auxMag: INTEGER;

	PROCEDURE MarkPoint (pt: Point);

		VAR
			r: Rect;
			p: INTEGER;
			tipPtr: Ptr;
			upper: INTEGER;
			lower: INTEGER;
			delta: LONGINT;
			pixels: INTEGER;
			offset: LONGINT;
			channel: INTEGER;
			channels: INTEGER;

		BEGIN

		fSpacingCounter := fSpacingCounter - 1;

		IF fSpacingCounter <= 0 THEN
			BEGIN

			fSpacingCounter := fSpacing;

			pixels := fTip.fSize.h * fTip.fSize.v;

			IF (fDrawings = 0) AND ((fPressureMode <> 0) OR
									(fFadeout > 0)) THEN
				BlockMove (fTip.fMask^, fTip.fData [0]^, pixels);

			tipPtr := fTip.fData [0]^;

			IF fPressureMode <> 0 THEN
				BEGIN

				p := ReadPressure;

				IF p = 0 THEN
					DoSetBytes (fTip.fMask^, pixels, 0)

				ELSE IF fPressureMode = 1 THEN
					DoThresholdMask (tipPtr, fTip.fMask^, pixels, p)

				ELSE IF fPressureMode = 2 THEN
					DoNarrowMask (tipPtr, fTip.fMask^, pixels, p)

				ELSE
					DoFadeMask (tipPtr, fTip.fMask^, pixels, 255 - p, 255);

				tipPtr := fTip.fMask^

				END;

			IF fFadeout > 0 THEN
				BEGIN

				IF fDrawings < fFadeout THEN
					DoFadeMask (tipPtr, fTip.fMask^, pixels,
								fDrawings, fFadeout)

				END

			ELSE IF fFadeout < 0 THEN
				BEGIN

				IF fView.fChannel = kRGBChannels THEN
					channels := 3
				ELSE
					channels := 1;

				IF fDrawings = 0 THEN
					FOR channel := 1 TO channels DO
						BEGIN
						fFore [channel] := fView.ForegroundByte (channel - 1);
						fBack [channel] := fView.BackgroundByte (channel - 1)
						END

				ELSE IF fDrawings <= -fFadeout THEN
					FOR channel := 1 TO channels DO
						DoSetBytes (fTip.fData [channel]^, pixels,
									(fFore [channel] *
									 ORD4 (fDrawings + fFadeout) -
									 fBack [channel] *
									 ORD4 (fDrawings)) DIV fFadeout)

				END;

			IF (fFadeout <= 0) OR (fDrawings < fFadeout) THEN
				BEGIN

				r.top  := pt.v - fTip.fSpot.v;
				r.left := pt.h - fTip.fSpot.h;

				r.bottom := r.top  + fTip.fSize.v;
				r.right  := r.left + fTip.fSize.h;

				IF (r.bottom > 0) AND (r.top  < rows) AND
				   (r.right  > 0) AND (r.left < cols) THEN
					BEGIN

						CASE fStampMethod OF

						kClone1Method,
						kClone2Method:
							LoadCloneTip (r);

						kRevertMethod:
							LoadRevertTip (r);

						kTextureMethod:
							LoadTextureTip;

						kPattern1Method,
						kPattern2Method:
							LoadPatternTip (r);

						kImpressMethod:
							IF (pt.v >= 0) AND (pt.v < rows) AND
							   (pt.h >= 0) AND (pt.h < cols) THEN
								LoadImpressTip (pt)

						END;

					IF r.bottom > rows THEN r.bottom := rows;
					IF r.right	> cols THEN r.right  := cols;

					offset := 0;

					IF r.top < 0 THEN
						BEGIN
						offset := fTip.fSize.h * (-r.top);
						r.top  := 0
						END;

					IF r.left < 0 THEN
						BEGIN
						offset := offset - r.left;
						r.left := 0
						END;

					upper := r.top;
					lower := r.bottom;

					delta := r.left;

					IF (fCmdNumber = cBlurring) OR
					   (fCmdNumber = cSharpening) THEN
						BEGIN

						IF upper > 0 THEN
							BEGIN
							upper := upper - 1;
							delta := delta + fPhysicalSize
							END;

						IF lower < rows THEN
							lower := lower + 1

						END;

					AddToMarked (r);

					FindMask (offset, r);

					IF fChannel = kRGBChannels THEN
						BEGIN

						rDataPtr := Ptr (ORD4 (fDoc.fData [0] . NeedPtr
										 (upper, lower - 1, TRUE)) + delta);

						gDataPtr := Ptr (ORD4 (fDoc.fData [1] . NeedPtr
										 (upper, lower - 1, TRUE)) + delta);

						bDataPtr := Ptr (ORD4 (fDoc.fData [2] . NeedPtr
										 (upper, lower - 1, TRUE)) + delta);

						MarkRGB (rDataPtr, gDataPtr, bDataPtr, offset, r);

						fDoc.fData [0] . DoneWithPtr;
						fDoc.fData [1] . DoneWithPtr;
						fDoc.fData [2] . DoneWithPtr;

						rDataPtr := NIL;
						gDataPtr := NIL;
						bDataPtr := NIL

						END

					ELSE
						BEGIN

						dataPtr := Ptr (ORD4 (fDoc.fData [fChannel] . NeedPtr
										(upper, lower - 1, TRUE)) + delta);

						MarkBand (dataPtr, offset, r, 1);

						fDoc.fData [fChannel] . DoneWithPtr;

						dataPtr := NIL

						END;

					AddToCache (r)

					END

				END;

			fDrawings := fDrawings + 1

			END

		END;

	PROCEDURE FindAuxView (view: TImageView);

		BEGIN
		IF view.fChannel = gCloneChannel THEN
			fAuxView := view
		END;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		IF rDataPtr <> NIL THEN fDoc.fData [0] . DoneWithPtr;
		IF gDataPtr <> NIL THEN fDoc.fData [1] . DoneWithPtr;
		IF bDataPtr <> NIL THEN fDoc.fData [2] . DoneWithPtr;

		IF dataPtr <> NIL THEN fDoc.fData [fChannel] . DoneWithPtr;

		RecoverFailure;

		FlushImage;

		message := fFailMessage;

		Free;

		Failure (error, message)

		END;

	BEGIN

	TrackMouse := SELF;

	fView.TrackRulers;

	pt1 := previousPoint;

	IF aTrackPhase = TrackPress THEN
		BEGIN

		IF gEventInfo.theShiftKey AND (fLastPoint.h >= 0) THEN
			BEGIN
			pt1 := fLastPoint;
			fView.CvtImage2View (pt1, kRoundDown)
			END

		END

	ELSE IF aTrackPhase = TrackRelease THEN
		FixReleasePoint (anchorPoint, nextPoint);

	pt2 := nextPoint;

	mag := fView.fMagnification;

	IF mag > 1 THEN
		BEGIN
		pt1.h := pt1.h DIV mag;
		pt1.v := pt1.v DIV mag;
		pt2.h := pt2.h DIV mag;
		pt2.v := pt2.v DIV mag
		END

	ELSE IF mag < 1 THEN
		BEGIN
		mag := -mag;
		pt1.h := pt1.h * mag;
		pt1.v := pt1.v * mag;
		pt2.h := pt2.h * mag;
		pt2.v := pt2.v * mag
		END;

	IF aTrackPhase = TrackPress THEN
		CASE fStampMethod OF

		kClone1Method,
		kClone2Method:
			BEGIN

			IF (gCloneTarget = fDoc) AND (fStampMethod = kClone1Method) THEN
				fStampOffset := gCloneOffset

			ELSE
				BEGIN

				fStampOffset.h := gClonePoint.h - pt1.h;
				fStampOffset.v := gClonePoint.v - pt1.v;

				gCloneOffset := fStampOffset;
				gCloneTarget := fDoc

				END;

			IF (gCloneDoc = fDoc) AND (gCloneChannel = fView.fChannel) THEN
				fAuxView := fView
			ELSE
				gCloneDoc.fViewList.Each (FindAuxView)

			END;

		kPattern2Method:
			BEGIN
			fStampOffset.h := pt1.h - BSR (gPatternRect.right -
										   gPatternRect.left, 1);
			fStampOffset.v := pt1.v - BSR (gPatternRect.bottom -
										   gPatternRect.top, 1)
			END;

		kImpressMethod:
			BEGIN
			fImpressCounter := 0;
			fImpressTimer	:= TickCount
			END;

		OTHERWISE
			BEGIN
			fStampOffset.h := 0;
			fStampOffset.v := 0
			END

		END;

	IF fAuxView <> NIL THEN
		BEGIN

		auxPt.h := pt2.h + fStampOffset.h;
		auxPt.v := pt2.v + fStampOffset.v;

		gCloneDoc.GetBoundsRect (bounds);

		IF PtInRect (auxPt, bounds) THEN
			BEGIN

			fAuxView.CvtImage2View (auxPt, kRoundDown);

			auxMag := fAuxView.fMagnification;

			IF auxMag > 1 THEN
				BEGIN
				auxMag := auxMag DIV 2;
				auxPt.h := auxPt.h + auxMag;
				auxPt.v := auxPt.v + auxMag
				END;

				CASE aTrackPhase OF

				TrackPress:
					DrawAuxCursor (auxPt);

				trackMove:
					IF NOT fAuxCursor THEN
						DrawAuxCursor (auxPt)
					ELSE
						IF LONGINT (auxPt) <> LONGINT (fAuxLocation) THEN
							BEGIN
							DrawAuxCursor (fAuxLocation);
							DrawAuxCursor (auxPt)
							END;

				TrackRelease:
					IF fAuxCursor THEN
						DrawAuxCursor (fAuxLocation)

				END

			END

		ELSE IF fAuxCursor THEN
			DrawAuxCursor (fAuxLocation)

		END;

	rows := fDoc.fRows;
	cols := fDoc.fCols;

	dataPtr := NIL;

	rDataPtr := NIL;
	gDataPtr := NIL;
	bDataPtr := NIL;

	CatchFailures (fi, CleanUp);

	IF fStampMethod = kImpressMethod THEN
		IF TickCount - fImpressTimer >= 15 THEN
			BEGIN
			fImpressCounter := 0;
			fImpressTimer	:= TickCount
			END;

	IF (aTrackPhase = trackPress) OR (LONGINT (pt1) <> LONGINT (pt2)) THEN
		BEGIN

		IF (fSpacing = 0) AND (aTrackPhase <> trackPress) THEN
			MarkPoint (pt2)
		ELSE
			InterpolatePoints (pt1, pt2, MarkPoint);

		FlushCache;

		fLastDrawTime := TickCount

		END

	ELSE IF (fDelay > 0) AND (TickCount - fLastDrawTime >= fDelay) THEN
		BEGIN

		fSpacingCounter := 1;

		MarkPoint (pt2);

		FlushCache;

		fLastDrawTime := TickCount

		END;

	Success (fi);

	IF aTrackPhase = TrackRelease THEN FlushImage

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TPencilTool.IPencilTool (view: TImageView; pt: Point);

	VAR
		tip: TTip;
		r: INTEGER;
		g: INTEGER;
		b: INTEGER;
		ps: BOOLEAN;
		index: INTEGER;
		pixels: INTEGER;
		map: TLookUpTable;
		needAlpha: BOOLEAN;
		doc: TImageDocument;

	BEGIN

	fAutoErase := FALSE;

	doc := TImageDocument (view.fDocument);

	LoadTip (tip, gPencilOptions.shapeID, view);

	pixels := tip.fSize.h * tip.fSize.v;

	IF gPencilOptions.check1 = 1 THEN
		BEGIN

		IF gEventInfo.theShiftKey &
		   MEMBER (gLastCommand, TPencilTool) &
		   (gLastCommand.fChangedDocument = doc) THEN

			fAutoErase := TPencilTool (gLastCommand) . fAutoErase

		ELSE
			BEGIN

			view.GetViewColor (pt, r, g, b);

			IF view.fChannel = kRGBChannels THEN
				fAutoErase := (view.ForegroundByte (0) = r) &
							  (view.ForegroundByte (1) = g) &
							  (view.ForegroundByte (2) = b)

			ELSE IF doc.fMode = IndexedColorMode THEN
				BEGIN
				index := view.ForegroundByte (0);
				fAutoErase := (doc.fIndexedColorTable.R [index] = CHR (r)) &
							  (doc.fIndexedColorTable.G [index] = CHR (g)) &
							  (doc.fIndexedColorTable.B [index] = CHR (b))
				END

			ELSE
				fAutoErase := view.ForegroundByte (0) = r

			END;

		IF fAutoErase THEN
			BEGIN
			DoSetBytes (tip.fData [1]^, pixels, view.BackgroundByte (0));
			IF tip.fData [2] <> NIL THEN
				BEGIN
				DoSetBytes (tip.fData [2]^, pixels, view.BackgroundByte (1));
				DoSetBytes (tip.fData [3]^, pixels, view.BackgroundByte (2))
				END
			END

		END;

	ps := (gPencilOptions.wacom = 1) & UsingPressure;

	IF NOT ps THEN
		BEGIN
		map [0] := CHR (0);
		DoSetBytes (@map [1], 255, 255);
		DoMapBytes (tip.fMask^, pixels, map)
		END;

	needAlpha := (gPencilOptions.pressure <> 100) AND
				 (doc.fMode <> IndexedColorMode);

	IDrawingTool (view, cDrawing, tip, gPencilOptions.mode,
									   gPencilOptions.spacing,
									   0,
									   0,
									   msgCannotPencil,
									   needAlpha);

	IF needAlpha THEN
		{$H-}
		MakeRamp (fAlphaMap, gPencilOptions.pressure * 255 DIV 100);
		{$H+}

	IF ps THEN
		fPressureMode := 1

	END;

{*****************************************************************************}

{$S ADoDraw}

FUNCTION DoPencilTool (view: TImageView; pt: Point): TCommand;

	VAR
		fi: FailInfo;
		aPencilTool: TPencilTool;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FailNewMessage (error, message, msgCannotPencil)
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	FailBadMode (view, FALSE, gPencilOptions.mode);

	NEW (aPencilTool);
	FailNil (aPencilTool);

	aPencilTool.IPencilTool (view, pt);

	Success (fi);

	DoPencilTool := aPencilTool

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TBrushTool.IBrushTool (view: TImageView);

	VAR
		tip: TTip;

	BEGIN

	LoadTip (tip, gBrushOptions.shapeID, view);

	IDrawingTool (view, cPainting, tip, gBrushOptions.mode,
										gBrushOptions.spacing,
										gBrushOptions.fadeout,
										gBrushOptions.rate,
										msgCannotBrush,
										gBrushOptions.pressure <> 100);

	{$H-}
	MakeRamp (fAlphaMap, gBrushOptions.pressure * 255 DIV 100);
	{$H+}

	IF (gBrushOptions.wacom = 1) & UsingPressure THEN
		fPressureMode := 2

	END;

{*****************************************************************************}

{$S ADoDraw}

FUNCTION DoBrushTool (view: TImageView): TCommand;

	VAR
		fi: FailInfo;
		aBrushTool: TBrushTool;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FailNewMessage (error, message, msgCannotBrush)
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	FailBadMode (view, TRUE, gBrushOptions.mode);

	NEW (aBrushTool);
	FailNil (aBrushTool);

	aBrushTool.IBrushTool (view);

	Success (fi);

	DoBrushTool := aBrushTool

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TAirbrushTool.IAirbrushTool (view: TImageView);

	VAR
		tip: TTip;
		cross: LONGINT;
		weight: INTEGER;
		map: TLookUpTable;

	BEGIN

	LoadTip (tip, gAirbrushOptions.shapeID, view);

	cross := TipCrossSection (tip);

	IF gAirbrushOptions.spacing > 1 THEN
		cross := cross DIV Min (gAirbrushOptions.spacing, 5);

	cross := Min (Max (cross, 255), 2048);

	weight := ORD4 (255 * gAirbrushOptions.pressure DIV 100) * 255 DIV cross;

	IF weight < 1 THEN weight := 1;

	MakeRamp (map, weight);

	DoMapBytes (tip.fMask^, tip.fSize.h * tip.fSize.v, map);

	IDrawingTool (view, cAirbrushing, tip, gAirbrushOptions.mode,
										   gAirbrushOptions.spacing,
										   gAirbrushOptions.fadeout,
										   gAirbrushOptions.rate,
										   msgCannotAirbrush,
										   FALSE);

	IF (gAirbrushOptions.wacom = 1) & UsingPressure THEN
		fPressureMode := 3

	END;

{*****************************************************************************}

{$S ADoDraw}

FUNCTION DoAirbrushTool (view: TImageView): TCommand;

	VAR
		fi: FailInfo;
		aAirbrushTool: TAirbrushTool;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FailNewMessage (error, message, msgCannotAirbrush)
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	FailBadMode (view, TRUE, gAirbrushOptions.mode);

	NEW (aAirbrushTool);
	FailNil (aAirbrushTool);

	aAirbrushTool.IAirbrushTool (view);

	Success (fi);

	DoAirbrushTool := aAirbrushTool

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TBlurTool.IBlurTool (view: TImageView);

	VAR
		tip: TTip;
		map: TLookUpTable;

	BEGIN

	LoadTip (tip, gBlurOptions.shapeID, view);

	MakeRamp (map, 255 * gBlurOptions.pressure DIV 100);

	DoMapBytes (tip.fMask^, tip.fSize.h * tip.fSize.v, map);

	IDrawingTool (view, cBlurring, tip, gBlurOptions.mode,
										gBlurOptions.spacing,
										0,
										gBlurOptions.rate,
										msgCannotBlur,
										FALSE)

	END;

{*****************************************************************************}

{$S ADoDraw}

FUNCTION DoBlurTool (view: TImageView): TCommand;

	VAR
		fi: FailInfo;
		aBlurTool: TBlurTool;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FailNewMessage (error, message, msgCannotBlur)
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	FailBadMode (view, TRUE, gBlurOptions.mode);

	NEW (aBlurTool);
	FailNil (aBlurTool);

	aBlurTool.IBlurTool (view);

	Success (fi);

	DoBlurTool := aBlurTool

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TSharpenTool.ISharpenTool (view: TImageView);

	VAR
		tip: TTip;
		map: TLookUpTable;

	BEGIN

	LoadTip (tip, gSharpenOptions.shapeID, view);

	MakeRamp (map, 255 * gSharpenOptions.pressure DIV 100);

	DoMapBytes (tip.fMask^, tip.fSize.h * tip.fSize.v, map);

	IDrawingTool (view, cSharpening, tip, gSharpenOptions.mode,
										  gSharpenOptions.spacing,
										  0,
										  gSharpenOptions.rate,
										  msgCannotSharpen,
										  FALSE)

	END;

{*****************************************************************************}

{$S ADoDraw}

FUNCTION DoSharpenTool (view: TImageView): TCommand;

	VAR
		fi: FailInfo;
		aSharpenTool: TSharpenTool;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FailNewMessage (error, message, msgCannotSharpen)
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	FailBadMode (view, TRUE, gSharpenOptions.mode);

	NEW (aSharpenTool);
	FailNil (aSharpenTool);

	aSharpenTool.ISharpenTool (view);

	Success (fi);

	DoSharpenTool := aSharpenTool

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TSmudgeTool.ISmudgeTool (view: TImageView; dip: BOOLEAN);

	VAR
		tip: TTip;
		gray: INTEGER;
		weight: LONGINT;
		map: TLookUpTable;

	BEGIN

	LoadTip (tip, gSmudgeOptions.shapeID, view);

	IDrawingTool (view, cSmudging, tip, gSmudgeOptions.mode,
										gSmudgeOptions.spacing,
										0,
										gSmudgeOptions.rate,
										msgCannotSmudge,
										FALSE);

	weight := 255 * gSmudgeOptions.pressure DIV 100;

	MakeRamp (map, weight);

	FOR gray := 0 TO 255 DO
		fMixMap [gray] := CHR (gray - ORD (map [gray]));

	IF weight <> 255 THEN
		FOR gray := 1 TO 255 DO
			IF fMixMap [gray] = CHR (0) THEN
				fMixMap [gray] := CHR (1);

	fDip := dip

	END;

{*****************************************************************************}

{$S ADoDraw}

FUNCTION DoSmudgeTool (view: TImageView; dip: BOOLEAN): TCommand;

	VAR
		fi: FailInfo;
		aSmudgeTool: TSmudgeTool;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FailNewMessage (error, message, msgCannotSmudge)
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	FailBadMode (view, TRUE, gSmudgeOptions.mode);

	NEW (aSmudgeTool);
	FailNil (aSmudgeTool);

	aSmudgeTool.ISmudgeTool (view, dip);

	Success (fi);

	DoSmudgeTool := aSmudgeTool

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TStampTool.IStampTool (view: TImageView; theMsg: LONGINT);

	VAR
		tip: TTip;
		rate: INTEGER;
		pixels: INTEGER;
		map: TLookUpTable;
		itsCommand: INTEGER;

	BEGIN

	LoadTip (tip, gStampOptions.shapeID, view);

	pixels := tip.fSize.h * tip.fSize.v;

	IF gStampOptions.method = kTextureMethod THEN
		BEGIN
		map [0] := CHR (0);
		DoSetBytes (@map [1], 255, 255);
		DoMapBytes (tip.fMask^, pixels, map)
		END;

	IF (gStampOptions.method = kClone1Method) OR
	   (gStampOptions.method = kClone2Method) THEN
		itsCommand := cCloning
	ELSE IF gStampOptions.method = kRevertMethod THEN
		itsCommand := cReverting
	ELSE
		itsCommand := cStamping;

	IF gStampOptions.method = kImpressMethod THEN
		rate := 60
	ELSE
		rate := 0;

	IDrawingTool (view, itsCommand, tip, gStampOptions.mode,
										 gStampOptions.spacing,
										 0,
										 rate,
										 theMsg,
										 gStampOptions.pressure <> 100);

	{$H-}
	MakeRamp (fAlphaMap, gStampOptions.pressure * 255 DIV 100);
	{$H+}

	fStampMethod := gStampOptions.method;

	IF fStampMethod = kTextureMethod THEN
		BEGIN

		{$IFC qBarneyscan}
		Failure (errNotYetImp, 0);
		{$ENDC}

		fTextureNoise := NewHandle (Max (256 + 16, pixels));

		MakeTextureNoise (fTextureNoise^, GetHandleSize (fTextureNoise))

		END

	END;

{*****************************************************************************}

{$S ADoDraw}

FUNCTION DoStampTool (view: TImageView): TCommand;

	VAR
		fi: FailInfo;
		theMsg: LONGINT;
		aStampTool: TStampTool;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FailNewMessage (error, message, theMsg)
		END;

	BEGIN

		CASE gStampOptions.method OF

		kClone1Method,
		kClone2Method:
			theMsg := msgCannotCloneStamp;

		kRevertMethod:
			theMsg := msgCannotRevertStamp;

		kTextureMethod:
			theMsg := msgCannotTextureStamp;

		kImpressMethod:
			theMsg := msgCannotImpressStamp;

		OTHERWISE
			theMsg := msgCannotPatternStamp

		END;

	CatchFailures (fi, CleanUp);

	FailBadMode (view, TRUE, gStampOptions.mode);

		CASE gStampOptions.method OF

		kClone1Method,
		kClone2Method:
			BEGIN

			IF gCloneDoc = NIL THEN
				Failure (errNoCloneSource, 0);

			IF (gCloneChannel = kRGBChannels) AND
			   (gCloneDoc.fMode <> RGBColorMode) OR
			   (gCloneDoc.fMode = IndexedColorMode) OR
			   (gCloneDoc.fDepth <> 8) OR
			   (gCloneChannel >= gCloneDoc.fChannels) OR
			   (gClonePoint.h >= gCloneDoc.fCols) OR
			   (gClonePoint.v >= gCloneDoc.fRows) THEN
				Failure (errNoCloneSource, 0)

			END;

		kRevertMethod:
			GetMagicData (view, StampTool, TRUE);

		kTextureMethod:
			IF NOT gHaveTexture THEN
				Failure (errNoTexture, 0);

		kImpressMethod:
			GetMagicData (view, StampTool, FALSE);

		OTHERWISE
			IF EmptyRect (gPatternRect) THEN
				Failure (errNoPattern, 0)

		END;

	NEW (aStampTool);
	FailNil (aStampTool);

	aStampTool.IStampTool (view, theMsg);

	Success (fi);

	DoStampTool := aStampTool

	END;

{*****************************************************************************}

{$S ADoDraw}

FUNCTION DoStampPadTool (view: TImageView; pt: Point): TCommand;

	VAR
		fi: FailInfo;
		channel: INTEGER;
		doc: TImageDocument;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FailNewMessage (error, message, msgCannotStamp)
		END;

	PROCEDURE PickUpTexture (srcChannel: INTEGER; dstChannel: INTEGER);

		VAR
			r: Rect;
			srcPtr: Ptr;
			extra: INTEGER;
			pixels: INTEGER;

		BEGIN

		r.topLeft  := pt;
		r.botRight := pt;

		InsetRect (r, -8, -8);

		doc.SectBoundsRect (r);

		srcPtr := doc.fData [srcChannel] .
				  NeedPtr (r.top, r.bottom - 1, FALSE);

		DoGetTip (Ptr (ORD4 (srcPtr) + r.left),
				  @gTexture [dstChannel],
				  doc.fData [srcChannel] . fPhysicalSize,
				  r.right - r.left,
				  r.bottom - r.top,
				  r.right - r.left);

		doc.fData [srcChannel] . DoneWithPtr;
		doc.fData [srcChannel] . Flush;

		pixels := (r.right - r.left) * (r.bottom - r.top);

		WHILE pixels < 256 DO
			BEGIN

			extra := Min (256 - pixels, pixels);

			BlockMove (@gTexture [dstChannel],
					   @gTexture [dstChannel, pixels],
					   extra);

			pixels := pixels + extra

			END

		END;

	BEGIN

	doc := TImageDocument (view.fDocument);

	view.CvtView2Image (pt);

	gCloneDoc	  := doc;
	gCloneTarget  := NIL;
	gCloneChannel := view.fChannel;
	gClonePoint   := pt;

	CatchFailures (fi, CleanUp);

	FailBadMode (view, TRUE, NormalDrawing);

	gHaveTexture := FALSE;

	IF view.fChannel = kRGBChannels THEN
		BEGIN

		FOR channel := 0 TO 2 DO
			PickUpTexture (channel, channel + 1);

		DoMakeMonochrome (@gTexture [1], gGrayLUT.R,
						  @gTexture [2], gGrayLUT.G,
						  @gTexture [3], gGrayLUT.B,
						  @gTexture [0], 256)

		END

	ELSE
		BEGIN

		PickUpTexture (view.fChannel, 0);

		BlockMove (@gTexture [0], @gTexture [1], 256);
		BlockMove (@gTexture [0], @gTexture [2], 256);
		BlockMove (@gTexture [0], @gTexture [3], 256)

		END;

	Success (fi);

	gHaveTexture := TRUE;

	IF (gStampOptions.method <> kClone1Method) AND
	   (gStampOptions.method <> kClone2Method) AND
	   (gStampOptions.method <> kTextureMethod) THEN
		gStampOptions.method := kClone1Method;

	DoStampPadTool := gNoChanges

	END;

{*****************************************************************************}

{$S ASelCommand}

PROCEDURE TEraseAll.IEraseAll (view: TImageView);

	BEGIN

	IBufferCommand (cEraseAll, view);

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TEraseAll.DoIt; OVERRIDE;

	VAR
		channel: INTEGER;
		aVMArray: TVMArray;

	BEGIN

	IF NOT EmptyRect (fDoc.fSelectionRect) THEN
		BEGIN
		fDoc.DeSelect (FALSE);
		fView.fFrame.ForceRedraw
		END;

	fChannel := fView.fChannel;

	IF fChannel = kRGBChannels THEN
		FOR channel := 0 TO 2 DO
			BEGIN

			aVMArray := NewVMArray (fDoc.fRows, fDoc.fCols, 3 - channel);

			fBuffer [channel] := aVMArray;

			aVMArray.SetBytes (fView.BackgroundByte (channel))

			END

	ELSE
		BEGIN

		aVMArray := NewVMArray (fDoc.fRows, fDoc.fCols, 1);

		fBuffer [0] := aVMArray;

		aVMArray.SetBytes (fView.BackgroundByte (fChannel))

		END;

	UndoIt

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TEraseAll.UndoIt; OVERRIDE;

	VAR
		channel: INTEGER;
		saveArray: TVMArray;

	PROCEDURE RedrawView (view: TImageView);
		BEGIN

		IF (fChannel = view.fChannel) OR
		   (fChannel = kRGBChannels) AND (view.fChannel <= 2) OR
		   (fChannel <= 2) AND (view.fChannel = kRGBChannels) THEN

			view.fFrame.ForceRedraw

		END;

	BEGIN

	IF fChannel = kRGBChannels THEN
		FOR channel := 0 TO 2 DO
			BEGIN
			saveArray			 := fDoc.fData [channel];
			fDoc.fData [channel] := fBuffer    [channel];
			fBuffer    [channel] := saveArray
			END
	ELSE
		BEGIN
		saveArray			  := fDoc.fData [fChannel];
		fDoc.fData [fChannel] := fBuffer	[0		 ];
		fBuffer    [0		] := saveArray
		END;

	fDoc.fViewList.Each (RedrawView)

	END;

{*****************************************************************************}

{$S ADoDraw}

PROCEDURE TEraseAll.RedoIt; OVERRIDE;

	BEGIN
	UndoIt
	END;

{*****************************************************************************}

{$S ASelCommand}

FUNCTION DoEraseAll (view: TImageView): TCommand;

	VAR
		anEraseAll: TEraseAll;

	BEGIN

	IF TImageDocument (view.fDocument) . fDepth <> 8 THEN
		Failure (0, 0);

	NEW (anEraseAll);
	FailNil (anEraseAll);

	anEraseAll.IEraseAll (view);

	DoEraseAll := anEraseAll

	END;

{*****************************************************************************}

{$S ARes3}

FUNCTION BrushesVisible: BOOLEAN;

	BEGIN

	BrushesVisible := ORD (WindowPeek (gBrushesWindow.
									   fWmgrWindow)^.visible) <> 0

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE ShowBrushes (visible: BOOLEAN);

	BEGIN

	gBrushesWindow.ShowGhost (visible)

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE TBrushesView.IBrushesView;

	CONST
		kBrushesID = 1005;

	VAR
		r: Rect;
		location: Point;

	BEGIN

	fShapeID := -1;

	SetRect (r, 0, 0, 179, 105);

	IView (NIL, NIL, r, sizeFixed, sizeFixed, TRUE, HLOn);

	{$H-}
	SetRect (fCustomRect, 136, 65, 168, 97);
	{$H+}

	gBrushesWindow := TGhostWindow (NewGhostWindow (kBrushesID, SELF));

	SetPort (gBrushesWindow.fWmgrWindow);

	location.v := screenBits.bounds.bottom;
	location.h := screenBits.bounds.right;

	LocalToGlobal (location);

	MoveWindow (gBrushesWindow.fWmgrWindow, -30000, -30000, FALSE);

	gBrushesWindow.Open;

	gBrushesWindow.ShowGhost (FALSE);

	MoveWindow (gBrushesWindow.fWmgrWindow, location.h, location.v, FALSE)

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE TBrushesView.HighlightShape (turnOn: BOOLEAN);

	VAR
		r: Rect;
		row: INTEGER;
		col: INTEGER;

	BEGIN

	IF fShapeID < 0 THEN
		EXIT (HighlightShape);

	IF fShapeID = 0 THEN
		BEGIN

		row := 2;
		col := 5;

		SetRect (r, 0, 0, 2 * kTipSize, 2 * kTipSize)

		END

	ELSE
		BEGIN

		IF fShapeID <= 19 THEN
			BEGIN
			row := (fShapeID - 1) DIV 7;
			col := (fShapeID - 1) MOD 7
			END
		ELSE
			BEGIN
			row := 3;
			col := fShapeID - 20
			END;

		SetRect (r, 0, 0, kTipSize, kTipSize)

		END;

	OffsetRect (r, 2 + kTipSize * col,
				   2 + kTipSize * row);

	PenNormal;

	IF NOT turnOn THEN PenPat (white);

	PenSize (2, 2);

	FrameRect (r);

	PenNormal

	END;

{*****************************************************************************}

{$S AToolOptions}

FUNCTION TBrushesView.DoMouseCommand
		(VAR downLocalPoint: Point;
		 VAR info: EventInfo;
		 VAR hysteresis: Point): TCommand; OVERRIDE;

	VAR
		r: Rect;
		pt: Point;
		pick: INTEGER;

	BEGIN

	DoMouseCommand := gNoChanges;

	r := fExtentRect;

	InsetRect (r, 2, 2);

	IF PtInRect (downLocalPoint, r) THEN
		BEGIN

		pt.v := downLocalPoint.v - r.top;
		pt.h := downLocalPoint.h - r.left;

		pick := (pt.v DIV kTipSize) * 7 +
				(pt.h DIV kTipSize) + 1;

		IF (pick = 20) OR (pick = 21) OR (pick >= 27) THEN
			pick := 0
		ELSE IF pick >= 22 THEN
			pick := pick - 2;

		IF (pick <> fShapeID) AND (fShapeID <> -1) THEN
			BEGIN

			HighlightShape (FALSE);
			fShapeID := pick;
			HighlightShape (TRUE);

				CASE gTool OF

				PencilTool:
					gPencilOptions.shapeID := pick;

				BrushTool:
					gBrushOptions.shapeID := pick;

				AirbrushTool:
					gAirbrushOptions.shapeID := pick;

				StampTool:
					gStampOptions.shapeID := pick;

				SmudgeTool:
					gSmudgeOptions.shapeID := pick;

				BlurTool:
					gBlurOptions.shapeID := pick;

				SharpenTool:
					gSharpenOptions.shapeID := pick

				END

			END

		END

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE TBrushesView.Draw (area: Rect); OVERRIDE;

	VAR
		r: Rect;
		pict: PicHandle;

	BEGIN

	pict := GetPicture (kShapesPictID);

	IF pict <> NIL THEN
		BEGIN
		HLock (Handle (pict));
		r := fExtentRect;
		InsetRect (r, -1, -1);
		DrawPicture (pict, r);
		HUnlock (Handle (pict))
		END;

	IF gCustomSize.h <> 0 THEN
		BEGIN
		r := fCustomRect;
		PlotIcon (r, gCustomIcon)
		END;

	HighlightShape (TRUE)

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE UpdateBrush;

	VAR
		shape: INTEGER;

	BEGIN

		CASE gTool OF

		PencilTool:
			shape := gPencilOptions.shapeID;

		BrushTool:
			shape := gBrushOptions.shapeID;

		AirbrushTool:
			shape := gAirbrushOptions.shapeID;

		StampTool:
			shape := gStampOptions.shapeID;

		SmudgeTool:
			shape := gSmudgeOptions.shapeID;

		BlurTool:
			shape := gBlurOptions.shapeID;

		SharpenTool:
			shape := gSharpenOptions.shapeID;

		OTHERWISE
			shape := -1

		END;

	IF shape <> gBrushesView.fShapeID THEN
		BEGIN
		gBrushesView.fFrame.Focus;
		gBrushesView.HighlightShape (FALSE);
		gBrushesView.fShapeID := shape;
		gBrushesView.HighlightShape (TRUE)
		END

	END;

{*****************************************************************************}

{$S AToolOptions}

PROCEDURE TShapeDialog.IShapeDialog (dialogID, shapeID: INTEGER);

	CONST
		kHookItem	= 3;
		kShapesItem = 4;
		kCustomItem = 5;

	VAR
		r: Rect;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	fShapeID := shapeID;

	IBWDialog (dialogID, kHookItem, ok);

	GetDItem (fDialogPtr, kShapesItem, itemType, itemHandle, r);

	InsetRect (r, 3, 3);

	fShapesRect := r;

	GetDItem (fDialogPtr, kCustomItem, itemType, itemHandle, r);

	fCustomRect := r

	END;

{*****************************************************************************}

{$S AToolOptions}

PROCEDURE TShapeDialog.HighlightShape (turnOn: BOOLEAN);

	VAR
		r: Rect;
		row: INTEGER;
		col: INTEGER;

	BEGIN

	IF fShapeID = 0 THEN
		BEGIN

		row := 2;
		col := 5;

		SetRect (r, 0, 0, 2 * kTipSize, 2 * kTipSize)

		END

	ELSE
		BEGIN

		IF fShapeID <= 19 THEN
			BEGIN
			row := (fShapeID - 1) DIV 7;
			col := (fShapeID - 1) MOD 7
			END
		ELSE
			BEGIN
			row := 3;
			col := fShapeID - 20
			END;

		SetRect (r, 0, 0, kTipSize, kTipSize)

		END;

	OffsetRect (r, fShapesRect.left + kTipSize * col,
				   fShapesRect.top	+ kTipSize * row);

	PenNormal;

	IF NOT turnOn THEN PenPat (white);

	PenSize (2, 2);

	FrameRect (r);

	PenNormal

	END;

{*****************************************************************************}

{$S AToolOptions}

PROCEDURE TShapeDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

	VAR
		r: Rect;
		pict: PicHandle;

	BEGIN

	INHERITED DrawAmendments (theItem);

	r := fShapesRect;
	InsetRect (r, -3, -3);

	pict := GetPicture (kShapesPictID);

	IF pict <> NIL THEN
		BEGIN
		HLock (Handle (pict));
		DrawPicture (pict, r);
		HUnlock (Handle (pict))
		END;

	IF gCustomSize.h <> 0 THEN
		BEGIN
		r := fCustomRect;
		PlotIcon (r, gCustomIcon)
		END;

	HighlightShape (TRUE)

	END;

{*****************************************************************************}

{$S AToolOptions}

PROCEDURE TShapeDialog.DoFilterEvent (VAR anEvent: EventRecord;
									  VAR itemHit: INTEGER;
									  VAR handledIt: BOOLEAN;
									  VAR doReturn: BOOLEAN); OVERRIDE;

	VAR
		pt: Point;
		pick: INTEGER;
		whichWindow: WindowPtr;

	BEGIN

	IF anEvent.what = mouseDown THEN
		IF FindWindow (anEvent.where, whichWindow) = inContent THEN
			IF whichWindow = fDialogPtr THEN
				BEGIN

				SetPort (fDialogPtr);

				pt := anEvent.where;
				GlobalToLocal (pt);

				IF PtInRect (pt, fShapesRect) THEN
					BEGIN

					pt.v := pt.v - fShapesRect.top;
					pt.h := pt.h - fShapesRect.left;

					pick := (pt.v DIV kTipSize) * 7 +
							(pt.h DIV kTipSize) + 1;

					IF (pick = 20) OR (pick = 21) OR (pick >= 27) THEN
						pick := 0
					ELSE IF pick >= 22 THEN
						pick := pick - 2;

					{$IFC qBarneyscan}
					IF pick = 0 THEN
						pick := fShapeID;
					{$ENDC}

					IF pick <> fShapeID THEN
						BEGIN
						HighlightShape (FALSE);
						fShapeID := pick;
						HighlightShape (TRUE)
						END;

					anEvent.what := nullEvent

					END

				END;

	INHERITED DoFilterEvent (anEvent, itemHit, handledIt, doReturn)

	END;

{*****************************************************************************}

{$S AToolOptions}

PROCEDURE DoToolOptions (dialogID: INTEGER; VAR options: TToolOptions);

	CONST
		kFirstModeItem = 6;
		kLastModeItem  = 9;
		kFirstEditItem = 10;

	VAR
		fi: FailInfo;
		item: INTEGER;
		itemBox: Rect;
		itemType: INTEGER;
		itemHandle: Handle;
		doc: TImageDocument;
		rateText: TFixedText;
		checkbox1: TCheckBox;
		checkbox2: TCheckBox;
		spacingText: TFixedText;
		fadeoutText: TFixedText;
		pressureText: TFixedText;
		modeCluster: TRadioCluster;
		aShapeDialog: TShapeDialog;
		methodCluster: TRadioCluster;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aShapeDialog.Free
		END;

	BEGIN

	NEW (aShapeDialog);
	FailNil (aShapeDialog);

	aShapeDialog.IShapeDialog (dialogID, options.shapeID);

	CatchFailures (fi, CleanUp);

	modeCluster := aShapeDialog.DefineRadioCluster
			(kFirstModeItem, kLastModeItem,
			 kFirstModeItem + ORD (options.mode));

	item := kFirstEditItem;

	spacingText := aShapeDialog.DefineFixedText
				   (item, 0, FALSE, TRUE, 0, 999);

	spacingText.StuffValue (options.spacing);

	item := item + 1;

	IF options.fadeout <> kUndefinedOption THEN
		BEGIN

		fadeoutText := aShapeDialog.DefineFixedText
					   (item, 0, TRUE, TRUE, -999, 999);

		IF options.fadeout <> 0 THEN
			fadeoutText.StuffValue (options.fadeout);

		item := item + 1

		END;

	IF options.rate <> kUndefinedOption THEN
		BEGIN

		rateText := aShapeDialog.DefineFixedText
					(item, 0, TRUE, TRUE, 0, 60);

		IF options.rate <> 0 THEN
			rateText.StuffValue (options.rate);

		item := item + 1

		END;

	IF options.pressure <> kUndefinedOption THEN
		BEGIN

		pressureText := aShapeDialog.DefineFixedText
						(item, 0, FALSE, TRUE, 1, 100);

		pressureText.StuffValue (options.pressure);

		aShapeDialog.SetEditSelection (item);

		item := item + 1

		END

	ELSE
		aShapeDialog.SetEditSelection (kFirstEditItem);

	IF options.method <> kUndefinedOption THEN
		BEGIN

		methodCluster := aShapeDialog.DefineRadioCluster
						 (item, item + 6, item + options.method);

		item := item + 7

		END;

	IF options.check1 <> kUndefinedOption THEN
		BEGIN
		checkbox1 := aShapeDialog.DefineCheckBox (item, options.check1 = 1);
		item := item + 1
		END;

	IF options.wacom <> kUndefinedOption THEN
		BEGIN
		checkbox2 := aShapeDialog.DefineCheckBox (item, options.wacom = 1);
		IF NOT gHavePressure THEN
			HideControl (ControlHandle (checkbox2.fItemHandle))
		END;

	aShapeDialog.TalkToUser (item, StdItemHandling);

	IF item <> ok THEN Failure (0, 0);

	options.shapeID := aShapeDialog.fShapeID;

	options.mode := TDrawingMode (modeCluster.fChosenItem - kFirstModeItem);

	options.spacing := spacingText.fValue;

	IF options.fadeout <> kUndefinedOption THEN
		options.fadeout := fadeoutText.fValue;

	IF options.rate <> kUndefinedOption THEN
		options.rate := rateText.fValue;

	IF options.pressure <> kUndefinedOption THEN
		options.pressure := pressureText.fValue;

	IF options.method <> kUndefinedOption THEN
		options.method := methodCluster.fChosenItem -
						  methodCluster.fFirstItem;

	IF options.check1 <> kUndefinedOption THEN
		options.check1 := ORD (checkbox1.fChecked);

	IF options.wacom <> kUndefinedOption THEN
		options.wacom := ORD (checkbox2.fChecked);

	Success (fi);

	CleanUp (0, 0);

	UpdateBrush

	END;

{*****************************************************************************}

{$S AToolOptions}

PROCEDURE DoPencilOptions;

	CONST
		kDialogID = 1082;

	BEGIN
	DoToolOptions (kDialogID, gPencilOptions)
	END;

{*****************************************************************************}

{$S AToolOptions}

PROCEDURE DoBrushOptions;

	CONST
		kDialogID = 1083;

	BEGIN
	DoToolOptions (kDialogID, gBrushOptions)
	END;

{*****************************************************************************}

{$S AToolOptions}

PROCEDURE DoAirbrushOptions;

	CONST
		kDialogID = 1084;

	BEGIN
	DoToolOptions (kDialogID, gAirbrushOptions)
	END;

{*****************************************************************************}

{$S AToolOptions}

PROCEDURE DoBlurOptions;

	CONST
		kDialogID = 1085;

	BEGIN
	DoToolOptions (kDialogID, gBlurOptions)
	END;

{*****************************************************************************}

{$S AToolOptions}

PROCEDURE DoSharpenOptions;

	CONST
		kDialogID = 1086;

	BEGIN
	DoToolOptions (kDialogID, gSharpenOptions)
	END;

{*****************************************************************************}

{$S AToolOptions}

PROCEDURE DoSmudgeOptions;

	CONST
		kDialogID = 1087;

	BEGIN
	DoToolOptions (kDialogID, gSmudgeOptions)
	END;

{*****************************************************************************}

{$S AToolOptions}

PROCEDURE DoStampOptions;

	CONST
		kDialogID = 1088;

	BEGIN
	DoToolOptions (kDialogID, gStampOptions);
	END;

{*****************************************************************************}

{$S AToolOptions}

PROCEDURE DefineBrush (view: TImageView);

	VAR
		r: Rect;
		rr: Rect;
		j: INTEGER;
		k: INTEGER;
		jj: INTEGER;
		kk: INTEGER;
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		offset: Point;
		map: TLookUpTable;
		doc: TImageDocument;
		buffer: ARRAY [0..3] OF TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (buffer [0]);
		FreeObject (buffer [1]);
		FreeObject (buffer [2]);
		FreeObject (buffer [3]);
		END;

	BEGIN

	MoveHands (TRUE);

	buffer [0] := NIL;
	buffer [1] := NIL;
	buffer [2] := NIL;
	buffer [3] := NIL;

	CatchFailures (fi, CleanUp);

	doc := TImageDocument (view.fDocument);

	r := doc.fSelectionRect;

	IF view.fChannel = kRGBChannels THEN
		BEGIN

		FOR j := 1 TO 3 DO
			BEGIN
			MoveHands (TRUE);
			buffer [j] := doc.fData [j - 1] . CopyRect (r, 1)
			END;

		MoveHands (TRUE);

		buffer [0] := MakeMonochromeArray (buffer [1],
										   buffer [2],
										   buffer [3]);

		FOR j := 1 TO 3 DO
			BEGIN
			buffer [j] . Free;
			buffer [j] := NIL
			END

		END

	ELSE
		BEGIN

		buffer [0] := doc.fData [view.fChannel] . CopyRect (r, 1);

		MoveHands (TRUE);

		IF doc.fMode = IndexedColorMode THEN
			BEGIN

			FOR j := 0 TO 255 DO
				map [j] := ConvertToGray (doc.fIndexedColorTable.R [j],
										  doc.fIndexedColorTable.G [j],
										  doc.fIndexedColorTable.B [j]);

			buffer [0] . MapBytes (map)

			END

		END;

	MoveHands (TRUE);
	buffer [0] . MapBytes (gInvertLUT);

	MoveHands (TRUE);
	buffer [0] . FindBounds (r);

	IF (r.right - r.left > kMaxTipSize) OR
	   (r.bottom - r.top > kMaxTipSize) THEN Failure (errBrushTooLarge, 0);

	gCustomSize := Point (0);

	rr := gBrushesView.fCustomRect;
	gBrushesView.fFrame.InvalidRect (rr);

	FOR j := r.top TO r.bottom - 1 DO
		BEGIN
		BlockMove (Ptr (ORD4 (buffer [0] . NeedPtr (j, j, FALSE)) + r.left),
				   @gCustomTip [(r.right - r.left) * (j - r.top)],
				   r.right - r.left);
		buffer [0] . DoneWithPtr
		END;

	gCustomSize.h := r.right - r.left;
	gCustomSize.v := r.bottom - r.top;

	buffer [0] . Free;
	buffer [0] := NIL;

	DoSetBytes (gCustomIcon^, 128, 0);

	offset.v := Max (0, (32 - gCustomSize.v) DIV 2);
	offset.h := Max (0, (32 - gCustomSize.h) DIV 2);

	FOR j := 0 TO gCustomSize.v - 1 DO
		BEGIN

		jj := j + offset.v;

		IF jj <= 31 THEN
			BEGIN

			srcPtr := @gCustomTip [j * gCustomSize.h];
			dstPtr := Ptr (ORD4 (gCustomIcon^) + jj * 4);

			FOR k := 0 TO gCustomSize.h - 1 DO
				BEGIN

				kk := k + offset.h;

				IF (kk <= 31) & (srcPtr^ <> 0) THEN
					BitSet (dstPtr, kk);

				srcPtr := Ptr (ORD4 (srcPtr) + 1)

				END

			END

		END;

	doc.DeSelect (TRUE);

	Success (fi)

	END;

{*****************************************************************************}

{$S AToolOptions}

PROCEDURE CopyPatternBand (srcArray: TVMArray;
						   dstArray: TVMArray;
						   r: Rect);

	VAR
		p: Ptr;
		rr: Rect;
		row: INTEGER;

	BEGIN

	rr := gPatternRect;

	srcArray.MoveRect (dstArray, r, rr);

	FOR row := rr.top TO rr.bottom - 1 DO
		BEGIN

		p := dstArray.NeedPtr (row, row, TRUE);

		DoCopyForward (Ptr (ORD4 (p) + rr.left),
					   Ptr (ORD4 (p) + rr.right),
					   rr.left);

		DoCopyBackward (Ptr (ORD4 (p) + rr.right),
						Ptr (ORD4 (p) + rr.left),
						rr.left);

		dstArray.DoneWithPtr

		END;

	FOR row := rr.bottom TO dstArray.fBlockCount - 1 DO
		BEGIN

		BlockMove (dstArray.NeedPtr (row - rr.bottom + rr.top,
									 row - rr.bottom + rr.top,
									 FALSE),
				   gBuffer,
				   dstArray.fLogicalSize);

		dstArray.DoneWithPtr;

		BlockMove (gBuffer,
				   dstArray.NeedPtr (row, row, TRUE),
				   dstArray.fLogicalSize);

		dstArray.DoneWithPtr

		END;

	FOR row := rr.top - 1 DOWNTO 0 DO
		BEGIN

		BlockMove (dstArray.NeedPtr (row + rr.bottom - rr.top,
									 row + rr.bottom - rr.top,
									 FALSE),
				   gBuffer,
				   dstArray.fLogicalSize);

		dstArray.DoneWithPtr;

		BlockMove (gBuffer,
				   dstArray.NeedPtr (row, row, TRUE),
				   dstArray.fLogicalSize);

		dstArray.DoneWithPtr

		END;

	dstArray.Flush

	END;

{*****************************************************************************}

{$S AToolOptions}

PROCEDURE AutoRepeatDetect (srcArray: TVMArray; r: Rect; VAR pt: Point);

	VAR
		p: Ptr;
		ok: BOOLEAN;
		row: INTEGER;
		width: INTEGER;
		height: INTEGER;
		period: INTEGER;

	BEGIN

	width  := r.right - r.left;
	height := r.bottom - r.top;

	FOR period := pt.v TO height DO
		IF (period MOD pt.v = 0) OR (period = height) THEN
			BEGIN

			ok := TRUE;

			FOR row := r.top TO r.bottom - period - 1 DO
				BEGIN

				MoveHands (TRUE);

				p := Ptr (ORD4 (srcArray.NeedPtr (row, row, FALSE)) + r.left);

				BlockMove (p, gBuffer, width);

				srcArray.DoneWithPtr;

				p := Ptr (ORD4 (srcArray.NeedPtr (row + period,
												  row + period,
												  FALSE)) + r.left);

				ok := EqualBytes (p, gBuffer, width);

				srcArray.DoneWithPtr;

				IF NOT ok THEN LEAVE

				END;

			IF ok THEN
				BEGIN
				pt.v := period;
				LEAVE
				END

			END;

	FOR row := r.top TO r.bottom - 1 DO
		IF pt.h <> width THEN
			BEGIN

			MoveHands (TRUE);

			p := Ptr (ORD4 (srcArray.NeedPtr (row, row, FALSE)) + r.left);

			FOR period := pt.h TO width DO
				IF period = width THEN
					pt.h := width
				ELSE IF (period MOD pt.h = 0) &
						EqualBytes (p,
									Ptr (ORD4 (p) + period),
									width - period) THEN
					BEGIN
					pt.h := period;
					LEAVE
					END;

			srcArray.DoneWithPtr

			END;

	srcArray.Flush

	END;

{*****************************************************************************}

{$S AToolOptions}

PROCEDURE DefinePattern (view: TImageView);

	VAR
		r: Rect;
		pt: Point;
		fi: FailInfo;
		band: INTEGER;
		width: INTEGER;
		height: INTEGER;
		map: TLookUpTable;
		doc: TImageDocument;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		VAR
			j: INTEGER;

		BEGIN

		gPatternRect := gZeroRect;

		FOR j := 0 TO 3 DO
			BEGIN
			FreeObject (gPattern [j]);
			gPattern [j] := NIL
			END

		END;

	BEGIN

	CleanUp (0, 0);

	CatchFailures (fi, CleanUp);

	doc := TImageDocument (view.fDocument);

	r := doc.fSelectionRect;

	pt.h := 1;
	pt.v := 1;

	IF view.fChannel = kRGBChannels THEN
		FOR band := 0 TO 2 DO
			AutoRepeatDetect (doc.fData [band], r, pt)
	ELSE
		AutoRepeatDetect (doc.fData [view.fChannel], r, pt);

	r.right  := r.left + pt.h;
	r.bottom := r.top  + pt.v;

	gPatternRect := r;
	OffsetRect (gPatternRect, -r.left + kMaxTipSize - 1,
							  -r.top  + kMaxTipSize - 1);

	width  := gPatternRect.right + gPatternRect.left;
	height := gPatternRect.bottom + gPatternRect.top;

	IF view.fChannel = kRGBChannels THEN
		BEGIN

		FOR band := 1 TO 3 DO
			gPattern [band] := NewVMArray (height, width, 4 - band);

		FOR band := 1 TO 3 DO
			CopyPatternBand (doc.fData [band - 1],
							 gPattern [band],
							 r);

		gPattern [0] := MakeMonochromeArray (gPattern [1],
											 gPattern [2],
											 gPattern [3])

		END

	ELSE
		BEGIN

		gPattern [0] := NewVMArray (height, width, 1);

		CopyPatternBand (doc.fData [view.fChannel],
						 gPattern [0],
						 r);

		IF doc.fMode = IndexedColorMode THEN
			BEGIN

			map := doc.fIndexedColorTable.R;
			gPattern [1] := gPattern [0] . CopyArray (3);
			gPattern [1] . MapBytes (map);

			map := doc.fIndexedColorTable.G;
			gPattern [2] := gPattern [0] . CopyArray (2);
			gPattern [2] . MapBytes (map);

			map := doc.fIndexedColorTable.B;
			gPattern [3] := gPattern [0] . CopyArray (1);
			gPattern [3] . MapBytes (map);

			gPattern [0] . Free;
			gPattern [0] := NIL;

			gPattern [0] := MakeMonochromeArray (gPattern [1],
												 gPattern [2],
												 gPattern [3])

			END

		END;

	doc.DeSelect (TRUE);

	Success (fi)

	END;

{*****************************************************************************}

END.

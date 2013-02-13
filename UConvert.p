{Photoshop version 1.0.1, file: UConvert.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UConvert;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UBWDialog, UCommands, UScreen, USeparation, UProgress;

TYPE

	TCvtCommand = OBJECT (TBufferCommand)

		fState: ARRAY [BOOLEAN] OF RECORD

			fRows	  : INTEGER;
			fCols	  : INTEGER;
			fDepth	  : INTEGER;
			fChannels : INTEGER;
			fMode	  : TDisplayMode;
			fStyleInfo: TStyleInfo;

			fChannel: INTEGER

			END;

		PROCEDURE TCvtCommand.ICvtCommand (itsCommand: INTEGER;
										   view: TImageView);

		PROCEDURE TCvtCommand.Free; OVERRIDE;

		PROCEDURE TCvtCommand.GetOptions;

		PROCEDURE TCvtCommand.DoConversion;

		PROCEDURE TCvtCommand.SetState (state: BOOLEAN);

		PROCEDURE TCvtCommand.DoIt; OVERRIDE;

		PROCEDURE TCvtCommand.UndoIt; OVERRIDE;

		PROCEDURE TCvtCommand.RedoIt; OVERRIDE;

		END;

	TCvtHalftone = OBJECT (TCvtCommand)

		fDitherCode: INTEGER;

		fInputResolution: Fixed;
		fOutputResolution: FixedScaled;

		fHalftoneSpec: THalftoneSpec;

		PROCEDURE TCvtHalftone.GetOptions; OVERRIDE;

		PROCEDURE TCvtHalftone.DoConversion; OVERRIDE;

		END;

	TCvtMonochrome = OBJECT (TCvtCommand)

		fScale: INTEGER;

		PROCEDURE TCvtMonochrome.GetOptions1;

		PROCEDURE TCvtMonochrome.GetOptions; OVERRIDE;

		PROCEDURE TCvtMonochrome.DoConversion; OVERRIDE;

		END;

	TCvtIndexedColor = OBJECT (TCvtCommand)

		fDepth: INTEGER;

		fExact: BOOLEAN;

		fAdaptive: BOOLEAN;

		fDitherCode: INTEGER;

		fColorTable: ARRAY [0..255] OF LONGINT;

		FUNCTION TCvtIndexedColor.CountColors: INTEGER;

		PROCEDURE TCvtIndexedColor.GetOptions1 (colors: INTEGER);

		PROCEDURE TCvtIndexedColor.GetOptions; OVERRIDE;

		PROCEDURE TCvtIndexedColor.DoExactConversion;

		FUNCTION TCvtIndexedColor.BuildInverseTable
				(LUT: TRGBLookUpTable): Handle;

		PROCEDURE TCvtIndexedColor.DoDiffusion;

		FUNCTION TCvtIndexedColor.Find5BitHistogram: Handle;

		PROCEDURE TCvtIndexedColor.MedianCut (colors: INTEGER);

		FUNCTION TCvtIndexedColor.DoPattern (levels: INTEGER;
											 output: BOOLEAN): BOOLEAN;

		PROCEDURE TCvtIndexedColor.DoApproximateConversion;

		PROCEDURE TCvtIndexedColor.DoConversion; OVERRIDE;

		END;

	TCvtRGBColor = OBJECT (TCvtCommand)

		PROCEDURE TCvtRGBColor.DoConversion; OVERRIDE;

		END;

	TCvtSeparationsCMYK = OBJECT (TCvtCommand)

		PROCEDURE TCvtSeparationsCMYK.GetOptions; OVERRIDE;

		PROCEDURE TCvtSeparationsCMYK.DoConversion; OVERRIDE;

		END;

	TCvtSeparationsHSL = OBJECT (TCvtCommand)

		PROCEDURE TCvtSeparationsHSL.RealConversion (bright: BOOLEAN);

		PROCEDURE TCvtSeparationsHSL.DoConversion; OVERRIDE;

		END;

	TCvtSeparationsHSB = OBJECT (TCvtSeparationsHSL)

		PROCEDURE TCvtSeparationsHSB.DoConversion; OVERRIDE;

		END;

	TCvtMultichannel = OBJECT (TCvtCommand)

		PROCEDURE TCvtMultichannel.DoConversion; OVERRIDE;

		END;

	TDeleteChannelCommand = OBJECT (TCvtCommand)

		PROCEDURE TDeleteChannelCommand.DoConversion; OVERRIDE;

		END;

PROCEDURE InitCvtOptions;

FUNCTION DeHalftoneDoc (doc: TImageDocument;
						scale: INTEGER;
						canAbort: BOOLEAN): TVMArray;

FUNCTION DoConvertCommand (view: TImageView; mode: TDisplayMode): TCommand;

FUNCTION DoDeleteChannel (view: TImageView): TCommand;

IMPLEMENTATION

{$I UAssembly.a.inc}
{$I UConvert.a.inc}
{$I UScreen.a.inc}

CONST
	kMaxScale = 16;

VAR
	gDitherCode  : INTEGER;
	gScale		 : INTEGER;
	gCDitherCode : INTEGER;
	gAdaptive	 : BOOLEAN;
	gOutputRes	 : FixedScaled;

PROCEDURE qsort (base: Ptr;
				 nelem: LONGINT;
				 elSize: LONGINT;
				 compar: ProcPtr); C; EXTERNAL;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitCvtOptions;

	BEGIN

	gDitherCode  := 2;
	gScale		 := 1;
	gCDitherCode := 2;
	gAdaptive	 := TRUE;

	gOutputRes.value := 0

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtCommand.ICvtCommand (itsCommand: INTEGER; view: TImageView);

	VAR
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Free
		END;

	BEGIN

	IBufferCommand (itsCommand, view);

	CatchFailures (fi, CleanUp);

	GetOptions;

	Success (fi)

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TCvtCommand.Free; OVERRIDE;

	VAR
		j: INTEGER;
		k: INTEGER;

	BEGIN

	FOR j := kMaxChannels - 1 DOWNTO 0 DO
		IF fBuffer [j] <> NIL THEN
			FOR k := fDoc.fChannels - 1 DOWNTO 0 DO
				IF fBuffer [j] = fDoc.fData [k] THEN
					fBuffer [j] := NIL;

	INHERITED Free

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtCommand.GetOptions;

	BEGIN
	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtCommand.DoConversion;

	BEGIN
	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtCommand.SetState (state: BOOLEAN);

	VAR
		save: TVMArray;
		resize: BOOLEAN;
		channel: INTEGER;
		oldMode: TDisplayMode;

	PROCEDURE FixUpView (view: TImageView);
		BEGIN

		IF state THEN
			CASE fDoc.fMode OF

			HalftoneMode,
			MonochromeMode,
			IndexedColorMode:
				view.fChannel := 0;

			RGBColorMode:
				IF oldMode = SeparationsCMYK THEN
					IF view.fChannel > 3 THEN
						view.fChannel := view.fChannel - 1
					ELSE
						view.fChannel := kRGBChannels
				ELSE IF oldMode = RGBColorMode THEN
					BEGIN
					IF (fDoc.fChannels = 3) AND (view.fChannel = 3) THEN
						view.fChannel := kRGBChannels
					END
				ELSE
					IF view.fChannel <= 2 THEN
						view.fChannel := kRGBChannels;

			SeparationsCMYK:
				IF oldMode = IndexedColorMode THEN
					view.fChannel := 3
				ELSE IF oldMode = RGBColorMode THEN
					IF view.fChannel = kRGBChannels THEN
						view.fChannel := 3
					ELSE IF view.fChannel >= 3 THEN
						view.fChannel := view.fChannel + 1;

			SeparationsHSL,
			SeparationsHSB:
				IF oldMode = IndexedColorMode THEN
					view.fChannel := 2
				ELSE IF oldMode = RGBColorMode THEN
					IF view.fChannel = kRGBChannels THEN
						view.fChannel := 2

			END

		ELSE
			view.fChannel := fState [FALSE] . fChannel;

		view.ValidateView;

		IF resize THEN
			BEGIN
			view.AdjustExtent;
			SetTopLeft (view, 0, 0)
			END;

		view.ReDither (TRUE);
		view.UpdateWindowTitle

		END;

	BEGIN

	fDoc.DeSelect (FALSE);

	WITH fState [state] DO
		BEGIN

		oldMode := fDoc.fMode;

		resize := (fDoc.fRows <> fRows) OR (fDoc.fCols <> fCols);

		fDoc.fRows		:= fRows;
		fDoc.fCols		:= fCols;
		fDoc.fDepth 	:= fDepth;
		fDoc.fChannels	:= fChannels;
		fDoc.fMode		:= fMode;
		fDoc.fStyleInfo := fStyleInfo

		END;

	FOR channel := 0 TO kMaxChannels - 1 DO
		BEGIN
		save				 := fBuffer    [channel];
		fBuffer    [channel] := fDoc.fData [channel];
		fDoc.fData [channel] := save
		END;

	fDoc.fViewList.Each (FixUpView);

	fDoc.UpdateStatus;
	fDoc.InvalRulers

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtCommand.DoIt; OVERRIDE;

	VAR
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress
		END;

	BEGIN

	MoveHands (TRUE);

	WITH fState [FALSE] DO
		BEGIN

		fRows	   := fDoc.fRows;
		fCols	   := fDoc.fCols;
		fDepth	   := fDoc.fDepth;
		fChannels  := fDoc.fChannels;
		fMode	   := fDoc.fMode;
		fStyleInfo := fDoc.fStyleInfo;

		fChannel := fView.fChannel

		END;

	fState [TRUE] := fState [FALSE];

	CommandProgress (fCmdNumber);
	CatchFailures (fi, CleanUp);

	DoConversion;

	Success (fi);
	CleanUp (0, 0);

	SetState (TRUE)

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtCommand.UndoIt; OVERRIDE;

	BEGIN
	SetState (FALSE)
	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtCommand.RedoIt; OVERRIDE;

	BEGIN
	SetState (TRUE)
	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtHalftone.GetOptions; OVERRIDE;

	CONST
		kDialogID	 = 1051;
		kHookItem	 = 3;
		kInputItem	 = 4;
		kOutputItem  = 6;
		kFirstDither = 8;
		kLastDither  = 12;

	VAR
		fi: FailInfo;
		itemBox: Rect;
		hitItem: INTEGER;
		itemType: INTEGER;
		itemHandle: Handle;
		spec: THalftoneSpec;
		aBWDialog: TBWDialog;
		inputUnit: TUnitSelector;
		outputUnit: TUnitSelector;
		ditherCluster: TRadioCluster;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	IF gOutputRes.value = 0 THEN
		gOutputRes.scale := fDoc.fStyleInfo.fResolution.scale;

	inputUnit := aBWDialog.DefineResUnit
				 (kInputItem, fDoc.fStyleInfo.fResolution.scale, 0);

	outputUnit := aBWDialog.DefineResUnit
				  (kOutputItem, gOutputRes.scale, 0);

	inputUnit.StuffFixed (0, fDoc.fStyleInfo.fResolution.value);

	IF gOutputRes.value = 0 THEN
		outputUnit.StuffFixed (0, fDoc.fStyleInfo.fResolution.value)
	ELSE
		outputUnit.StuffFixed (0, gOutputRes.value);

	aBWDialog.SetEditSelection (kOutputItem);

	IF EmptyRect (gPatternRect) AND (gDitherCode = 4) THEN
		gDitherCode := 2;

	ditherCluster := aBWDialog.DefineRadioCluster
			(kFirstDither, kLastDither, kFirstDither + gDitherCode);

	IF EmptyRect (gPatternRect) THEN
		BEGIN
		GetDItem (aBWDialog.fDialogPtr, kLastDither,
				  itemType, itemHandle, itemBox);
		HiliteControl (ControlHandle (itemHandle), 255)
		END;

	aBWDialog.TalkToUser (hitItem, StdItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	fInputResolution := inputUnit.GetFixed (0);

	fOutputResolution.value := outputUnit.GetFixed (0);
	fOutputResolution.scale := outputUnit.fPick;

	IF fInputResolution = fOutputResolution.value THEN
		gOutputRes.value := 0
	ELSE
		gOutputRes := fOutputResolution;

	fDitherCode := ditherCluster.fChosenItem - kFirstDither;
	gDitherCode := fDitherCode;

	Success (fi);

	CleanUp (0, 0);

	IF fDitherCode = 3 THEN
		BEGIN
		spec := fDoc.fStyleInfo.fHalftoneSpec;
		SetHalftoneScreen (spec, FALSE);
		fHalftoneSpec := spec
		END

	END;

{*****************************************************************************}

{$S ADoConvert}

FUNCTION CustomScreen: TVMArray;

	VAR
		fi: FailInfo;
		gray: INTEGER;
		this: LONGINT;
		left: LONGINT;
		count: LONGINT;
		hist: THistogram;
		map: TLookUpTable;
		aVMArray: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (aVMArray)
		END;

	BEGIN

	IF EmptyRect (gPatternRect) THEN Failure (errNoPattern, 0);

	aVMArray := gPattern [0] . CopyRect (gPatternRect, 1);

	CatchFailures (fi, CleanUp);

	aVMArray.HistBytes (hist);

	count := aVMArray.fLogicalSize * ORD4 (aVMArray.fBlockCount);

	left := 0;

	FOR gray := 0 TO 255 DO
		BEGIN

		this := hist [gray];

		map [gray] := CHR (Min (254, TRUNC (255 * (left + this / 2) / count)));

		left := left + this

		END;

	aVMArray.MapBytes (map);

	Success (fi);

	CustomScreen := aVMArray

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtHalftone.DoConversion; OVERRIDE;

	VAR
		r: Rect;
		fi: FailInfo;
		limit: INTEGER;
		scale: EXTENDED;
		screen: TVMArray;
		newRows: INTEGER;
		newCols: INTEGER;
		cellData: Handle;
		cellSize: INTEGER;
		aVMArray: TVMArray;
		spec: THalftoneSpec;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (screen)
		END;

	BEGIN

	scale := fOutputResolution.value / fInputResolution;

	newRows := Max (1, Min (kMaxCoord, ROUND (fDoc.fRows * scale)));
	newCols := Max (1, Min (kMaxCoord, ROUND (fDoc.fCols * scale)));

	fState [TRUE] . fMode  := HalftoneMode;
	fState [TRUE] . fRows  := newRows;
	fState [TRUE] . fCols  := newCols;
	fState [TRUE] . fDepth := 1;

	fState [TRUE] . fStyleInfo . fResolution := fOutputResolution;

	aVMArray := NewVMArray (newRows, BSL (BSR (newCols + 15, 4), 1), 1);

	fBuffer [0] := aVMArray;

		CASE fDitherCode OF

		0, 1:
			BEGIN

			spec.frequency.value := $10000;
			spec.frequency.scale := 1;
			spec.angle			 := 0;
			spec.shape			 := 0;
			spec.spot			 := NIL;

			IF fDitherCode = 0 THEN
				limit := 1
			ELSE
				limit := 8;

			MakeScreen (limit, $10000, spec, cellData, cellSize);

			screen := ConvertScreen (cellData, cellSize)

			END;

		2:	screen := NIL;

		3:	BEGIN

			spec := fHalftoneSpec;

			MakeScreen (kMaxCellSize,
						fOutputResolution.value,
						spec,
						cellData,
						cellSize);

			screen := ConvertScreen (cellData, cellSize)

			END;

		4:	screen := CustomScreen

		END;

	CatchFailures (fi, CleanUp);

	SetRect (r, 0, 0, fDoc.fCols, fDoc.fRows);

	HalftoneArea (fDoc.fData [0],
				  aVMArray,
				  r,
				  newRows,
				  newCols,
				  NIL,
				  screen,
				  TRUE);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtMonochrome.GetOptions1;

	CONST
		kDialogID = 1052;
		kHookItem = 3;
		kEditItem = 4;

	VAR
		fi: FailInfo;
		hitItem: INTEGER;
		maxScale: INTEGER;
		aBWDialog: TBWDialog;
		scaleText: TFixedText;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	maxScale := Min (kMaxScale, Min (fDoc.fRows, fDoc.fCols));

	scaleText := aBWDialog.DefineFixedText
				 (kEditItem, 0, FALSE, TRUE, 1, maxScale);

	scaleText.StuffValue (Min (maxScale, gScale));

	aBWDialog.SetEditSelection (kEditItem);

	aBWDialog.TalkToUser (hitItem, StdItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	fScale := scaleText.fValue;
	gScale := fScale;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtMonochrome.GetOptions; OVERRIDE;

	CONST
		kDiscardColorQuestion  = 907;
		kDiscardOtherQuestion  = 908;
		kDiscardOthersQuestion = 909;

	PROCEDURE Confirm (question: INTEGER);
		BEGIN
		IF BWAlert (question, 0, FALSE) <> ok THEN
			Failure (0, 0)
		END;

	BEGIN

		CASE fDoc.fMode OF

		HalftoneMode:

			GetOptions1;

		IndexedColorMode:

			IF NOT EqualBytes (@gNullLUT, @fDoc.fIndexedColorTable.R, 256) OR
			   NOT EqualBytes (@gNullLUT, @fDoc.fIndexedColorTable.G, 256) OR
			   NOT EqualBytes (@gNullLUT, @fDoc.fIndexedColorTable.B, 256) THEN
				Confirm (kDiscardColorQuestion);

		OTHERWISE

			IF fView.fChannel = kRGBChannels THEN
				Confirm (kDiscardColorQuestion)

			ELSE IF fDoc.fChannels = 2 THEN
				Confirm (kDiscardOtherQuestion)

			ELSE
				Confirm (kDiscardOthersQuestion)

		END

	END;

{*****************************************************************************}

{$S ARes3}

FUNCTION DeHalftoneDoc (doc: TImageDocument;
						scale: INTEGER;
						canAbort: BOOLEAN): TVMArray;

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		gray: INTEGER;
		total: INTEGER;
		newRows: INTEGER;
		newCols: INTEGER;
		aVMArray: TVMArray;
		thresTable: TThresTable;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (aVMArray);
		doc.fData [0] . Flush
		END;

	BEGIN

	newRows := doc.fRows DIV scale;
	newCols := doc.fCols DIV scale;

	aVMArray := NewVMArray (newRows, newCols, 1);

	CatchFailures (fi, CleanUp);

	total := SQR (scale);

	FOR gray := 0 TO total DO
		thresTable [gray] := CHR (255 - (255 * ORD4 (gray) +
								  total DIV 2) DIV total);

	FOR row := 0 TO newRows - 1 DO
		BEGIN

		MoveHands (canAbort);

		UpdateProgress (row, newRows);

		dstPtr := aVMArray.NeedPtr (row, row, TRUE);

		srcPtr := doc.fData [0] . NeedPtr (row * scale,
										   row * scale + scale - 1,
										   FALSE);

		DeHalftoneRow (srcPtr,
					   dstPtr,
					   doc.fData [0] . fPhysicalSize,
					   newCols,
					   scale,
					   thresTable);

		doc.fData [0] . DoneWithPtr;

		aVMArray.DoneWithPtr

		END;

	UpdateProgress (1, 1);

	Success (fi);

	doc.fData [0] . Flush;

	aVMArray.Flush;

	DeHalftoneDoc := aVMArray

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtMonochrome.DoConversion; OVERRIDE;

	VAR
		gray: INTEGER;
		map: TLookUpTable;
		aVMArray: TVMArray;

	BEGIN

	fState [TRUE] . fMode	  := MonochromeMode;
	fState [TRUE] . fChannels := 1;

		CASE fDoc.fMode OF

		HalftoneMode:
			BEGIN

			aVMArray := DeHalftoneDoc (fDoc, fScale, TRUE);

			fBuffer [0] := aVMArray;

			fState [TRUE] . fRows  := aVMArray.fBlockCount;
			fState [TRUE] . fCols  := aVMArray.fLogicalSize;
			fState [TRUE] . fDepth := 8;

			fState [TRUE] . fStyleInfo.fResolution.value :=
					Max (1, fDoc.fStyleInfo.fResolution.value DIV fScale)

			END;

		IndexedColorMode:
			BEGIN

			aVMArray := fDoc.fData [0] . CopyArray (1);

			fBuffer [0] := aVMArray;

			FOR gray := 0 TO 255 DO
				map [gray] := ConvertToGray
						(fDoc.fIndexedColorTable.R [gray],
						 fDoc.fIndexedColorTable.G [gray],
						 fDoc.fIndexedColorTable.B [gray]);

			aVMArray . MapBytes (map)

			END;

		OTHERWISE

			IF fView.fChannel = kRGBChannels THEN
				BEGIN

				aVMArray := MakeMonochromeArray (fDoc.fData [0],
												 fDoc.fData [1],
												 fDoc.fData [2]);

				fBuffer [0] := aVMArray

				END

			ELSE
				fBuffer [0] := fDoc.fData [fView.fChannel]

		END

	END;

{*****************************************************************************}

{$S ADoConvert}

FUNCTION TCvtIndexedColor.CountColors: INTEGER;

	VAR
		rPtr: Ptr;
		gPtr: Ptr;
		bPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		index: INTEGER;
		colors: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		IF rPtr <> NIL THEN fDoc.fData [0] . DoneWithPtr;
		IF gPtr <> NIL THEN fDoc.fData [1] . DoneWithPtr;
		IF bPtr <> NIL THEN fDoc.fData [2] . DoneWithPtr;

		fDoc.fData [0] . Flush;
		fDoc.fData [1] . Flush;
		fDoc.fData [2] . Flush;

		HUnlock (Handle (SELF))

		END;

	BEGIN

	rPtr := NIL;
	gPtr := NIL;
	bPtr := NIL;

	HLock (Handle (SELF));

	CatchFailures (fi, CleanUp);

	DoSetBytes (@fColorTable, 1024, 0);

	fColorTable [0] := $FFFFFF;

	FOR row := 0 TO fDoc.fRows - 1 DO
		BEGIN

		MoveHands (TRUE);

		rPtr := fDoc.fData [0] . NeedPtr (row, row, FALSE);
		gPtr := fDoc.fData [1] . NeedPtr (row, row, FALSE);
		bPtr := fDoc.fData [2] . NeedPtr (row, row, FALSE);

		IF DoCountColors (rPtr, gPtr, bPtr, fDoc.fCols, @fColorTable) THEN
			BEGIN

			Success (fi);
			CleanUp (0, 0);

			CountColors := -1;
			EXIT (CountColors)

			END;

		fDoc.fData [0] . DoneWithPtr;
		fDoc.fData [1] . DoneWithPtr;
		fDoc.fData [2] . DoneWithPtr;

		rPtr := NIL;
		gPtr := NIL;
		bPtr := NIL

		END;

	Success (fi);

	CleanUp (0, 0);

	colors := 2;

	FOR index := 1 TO 254 DO
		IF fColorTable [index] <> 0 THEN
			colors := colors + 1;

	CountColors := colors

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtIndexedColor.GetOptions1 (colors: INTEGER);

	CONST
		kDialogID		 = 1054;
		kHookItem		 = 3;
		kFirstDepthItem  = 4;
		kLastDepthItem	 = 9;
		kExactItem		 = 10;
		kUniformItem	 = 11;
		kAdaptiveItem	 = 12;
		kFirstDitherItem = 13;
		kLastDitherItem  = 15;
		kWordingItem	 = 16;

	VAR
		fi: FailInfo;
		item: INTEGER;
		aBWDialog: TBWDialog;
		depthCluster: TRadioCluster;
		ditherCluster: TRadioCluster;
		paletteCluster: TRadioCluster;

	PROCEDURE EnableItem (anItem: INTEGER; state: BOOLEAN);

		VAR
			itemBox: Rect;
			itemType: INTEGER;
			itemHandle: Handle;

		BEGIN
		GetDItem (aBWDialog.fDialogPtr, anItem,
				  itemType, itemHandle, itemBox);
		IF state THEN
			HiliteControl (ControlHandle (itemHandle), 0)
		ELSE
			HiliteControl (ControlHandle (itemHandle), 255)
		END;

	PROCEDURE SetItem (anItem: INTEGER; state: BOOLEAN);

		VAR
			itemBox: Rect;
			itemType: INTEGER;
			itemHandle: Handle;

		BEGIN
		GetDItem (aBWDialog.fDialogPtr, anItem,
				  itemType, itemHandle, itemBox);
		SetCtlValue (ControlHandle (itemHandle), ORD (state))
		END;

	PROCEDURE SetUniformWording (system: BOOLEAN);

		VAR
			s: Str255;
			itemBox: Rect;
			itemType: INTEGER;
			itemHandle: Handle;

		BEGIN
		GetDItem (aBWDialog.fDialogPtr, kWordingItem + ORD (system),
				  itemType, itemHandle, itemBox);
		GetCTitle (ControlHandle (itemHandle), s);
		GetDItem (aBWDialog.fDialogPtr, kUniformItem,
				  itemType, itemHandle, itemBox);
		SetCTitle (ControlHandle (itemHandle), s)
		END;

	PROCEDURE EnableDither (state: BOOLEAN);

		VAR
			anItem: INTEGER;

		BEGIN
		FOR anItem := kFirstDitherItem TO kLastDitherItem DO
			EnableItem (anItem, state)
		END;

	PROCEDURE EnableExact (state: BOOLEAN);

		BEGIN
		EnableItem (kExactItem, state);
		IF fExact AND NOT state THEN
			BEGIN
			fExact := FALSE;
			SetItem (kExactItem, FALSE);
			IF fAdaptive THEN
				paletteCluster.fChosenItem := kAdaptiveItem
			ELSE
				paletteCluster.fChosenItem := kUniformItem;
			SetItem (paletteCluster.fChosenItem, TRUE);
			EnableDither (TRUE)
			END
		END;

	PROCEDURE MyItemHandling (anItem: INTEGER; VAR done: BOOLEAN);

		VAR
			oldDepth: INTEGER;

		BEGIN
		StdItemHandling (anItem, done);

			CASE anItem OF

			kFirstDepthItem..kLastDepthItem:
				BEGIN
				oldDepth := fDepth;
				fDepth := anItem - kFirstDepthItem + 3;
				IF colors > 0 THEN
					EnableExact (colors <= BSL (1, fDepth));
				IF (fDepth = 8) <> (oldDepth = 8) THEN
					SetUniformWording (fDepth = 8)
				END;

			kExactItem:
				BEGIN
				fExact := TRUE;
				EnableDither (FALSE)
				END;

			kUniformItem:
				BEGIN
				fExact := FALSE;
				fAdaptive := FALSE;
				EnableDither (TRUE)
				END;

			kAdaptiveItem:
				BEGIN
				fExact := FALSE;
				fAdaptive := TRUE;
				EnableDither (TRUE)
				END

			END

		END;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	fExact := (colors >= 0) AND (colors <= 256);

	fDepth := 8;
	IF fExact THEN
		WHILE (fDepth > 3) AND (colors <= BSL (1, fDepth - 1)) DO
			fDepth := fDepth - 1;

	fAdaptive := gAdaptive;
	fDitherCode := gCDitherCode;

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	depthCluster := aBWDialog.DefineRadioCluster
			(kFirstDepthItem, kLastDepthItem, kFirstDepthItem + fDepth - 3);

	IF fExact THEN
		item := kExactItem
	ELSE IF fAdaptive THEN
		item := kAdaptiveItem
	ELSE
		item := kUniformItem;

	paletteCluster := aBWDialog.DefineRadioCluster
			(kExactItem, kAdaptiveItem, item);

	ditherCluster := aBWDialog.DefineRadioCluster
			(kFirstDitherItem, kLastDitherItem,
			 kFirstDitherItem + fDitherCode);

	EnableExact (fExact);
	EnableDither (NOT fExact);
	SetUniformWording (fDepth = 8);

	aBWDialog.TalkToUser (item, MyItemHandling);

	IF item <> ok THEN Failure (0, 0);

	fDepth := depthCluster.fChosenItem - kFirstDepthItem + 3;

	fExact	  := (paletteCluster.fChosenItem = kExactItem);
	fAdaptive := (paletteCluster.fChosenItem = kAdaptiveItem);

	fDitherCode := ditherCluster.fChosenItem - kFirstDitherItem;

	IF NOT fExact THEN
		BEGIN
		gAdaptive := fAdaptive;
		gCDitherCode := fDitherCode
		END;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtIndexedColor.GetOptions; OVERRIDE;

	BEGIN

	IF fDoc.fMode = RGBColorMode THEN
		GetOptions1 (CountColors)

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtIndexedColor.DoExactConversion;

	VAR
		rPtr: Ptr;
		gPtr: Ptr;
		bPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		index: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		IF rPtr <> NIL THEN fDoc.fData [0] . DoneWithPtr;
		IF gPtr <> NIL THEN fDoc.fData [1] . DoneWithPtr;
		IF bPtr <> NIL THEN fDoc.fData [2] . DoneWithPtr;

		fDoc.fData [0] . Flush;
		fDoc.fData [1] . Flush;
		fDoc.fData [2] . Flush;

		fBuffer [0] . Flush;

		HUnlock (Handle (SELF))

		END;

	BEGIN

	rPtr := NIL;
	gPtr := NIL;
	bPtr := NIL;

	HLock (Handle (SELF));

	CatchFailures (fi, CleanUp);

	FOR row := 0 TO fDoc.fRows - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row, fDoc.fRows);

		rPtr := fDoc.fData [0] . NeedPtr (row, row, FALSE);
		gPtr := fDoc.fData [1] . NeedPtr (row, row, FALSE);
		bPtr := fDoc.fData [2] . NeedPtr (row, row, FALSE);

		DoMapColors (rPtr,
					 gPtr,
					 bPtr,
					 fDoc.fCols,
					 @fColorTable,
					 fBuffer [0] . NeedPtr (row, row, TRUE));

		fBuffer [0] . DoneWithPtr;

		fDoc.fData [0] . DoneWithPtr;
		fDoc.fData [1] . DoneWithPtr;
		fDoc.fData [2] . DoneWithPtr;

		rPtr := NIL;
		gPtr := NIL;
		bPtr := NIL

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0);

	FOR index := 0 TO 255 DO
		BEGIN

		fDoc.fIndexedColorTable.R [index] :=
				CHR (BAND ($FF, fColorTable [index]));

		fDoc.fIndexedColorTable.G [index] :=
				CHR (BAND ($FF, BSR (fColorTable [index], 8)));

		fDoc.fIndexedColorTable.B [index] :=
				CHR (BAND ($FF, BSR (fColorTable [index], 16)))

		END

	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ADoConvert}

FUNCTION TCvtIndexedColor.BuildInverseTable (LUT: TRGBLookUpTable): Handle;

	VAR
		p: Ptr;
		x: INTEGER;
		y: INTEGER;
		fi: FailInfo;
		table: Handle;
		index: INTEGER;
		buffer: Handle;
		offset: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (table);
		FreeLargeHandle (buffer)
		END;

	PROCEDURE DoLine (offset: INTEGER; step: INTEGER);
		BEGIN

		DoBuildInverse (Ptr (ORD4 (table^ ) + offset),
						Ptr (ORD4 (buffer^) + offset),
						step);

		offset := offset + 31 * step;

		DoBuildInverse (Ptr (ORD4 (table^ ) + offset),
						Ptr (ORD4 (buffer^) + offset),
						-step)

		END;

	BEGIN

	table := NewLargeHandle (32768);

	CatchFailures (fi, CleanUp);

	buffer := NIL;
	buffer := NewLargeHandle (32768);

	DoSetBytes (buffer^, 32768, 255);

	FOR index := 255 DOWNTO 0 DO
		BEGIN

		offset := BSL (BSR (ORD (LUT.B [index]), 3), 10) +
				  BSL (BSR (ORD (LUT.G [index]), 3),  5) +
					   BSR (ORD (LUT.R [index]), 3);

		{$PUSH}
		{$R-}

		p  := Ptr (ORD4 (table^) + offset);
		p^ := index;

		{$POP}

		p  := Ptr (ORD4 (buffer^) + offset);
		p^ := 0

		END;

	FOR x := 0 TO 31 DO
		FOR y := 0 TO 31 DO
			DoLine (x + BSL (y, 10), $20);

	MoveHands (TRUE);

	FOR x := 0 TO 31 DO
		FOR y := 0 TO 31 DO
			DoLine (BSL (x, 5) + BSL (y, 10), $1);

	MoveHands (TRUE);

	FOR x := 0 TO 31 DO
		FOR y := 0 TO 31 DO
			DoLine (x + BSL (y,  5), $400);

	Success (fi);

	FreeLargeHandle (buffer);

	BuildInverseTable := table

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtIndexedColor.DoDiffusion;

	VAR
		fi: FailInfo;
		row: INTEGER;
		table: Handle;
		rDataPtr: Ptr;
		gDataPtr: Ptr;
		bDataPtr: Ptr;
		thisError: Ptr;
		nextError: Ptr;
		tempError: Ptr;
		outDataPtr: Ptr;
		buffer1: Handle;
		buffer2: Handle;
		LUT: TRGBLookUpTable;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		FreeLargeHandle (table);

		FreeLargeHandle (buffer1);
		FreeLargeHandle (buffer2);

		IF rDataPtr <> NIL THEN fDoc.fData [0] . DoneWithPtr;
		IF gDataPtr <> NIL THEN fDoc.fData [1] . DoneWithPtr;
		IF bDataPtr <> NIL THEN fDoc.fData [2] . DoneWithPtr;

		fDoc.fData [0] . Flush;
		fDoc.fData [1] . Flush;
		fDoc.fData [2] . Flush

		END;

	BEGIN

	MoveHands (TRUE);

	buffer1 := NIL;
	buffer2 := NIL;

	rDataPtr := NIL;
	gDataPtr := NIL;
	bDataPtr := NIL;

	LUT := fDoc.fIndexedColorTable;

	table := BuildInverseTable (LUT);

	CatchFailures (fi, CleanUp);

	IF fDitherCode = 2 THEN
		BEGIN

		buffer1 := NewLargeHandle (6 * ORD4 (fDoc.fCols + 2));
		buffer2 := NewLargeHandle (6 * ORD4 (fDoc.fCols + 2));

		HLock (buffer1);
		HLock (buffer2);

		thisError := Ptr (ORD4 (buffer1^) + 6);
		nextError := Ptr (ORD4 (buffer2^) + 6);

		DoSetBytes (nextError, 6 * ORD4 (fDoc.fCols), 0)

		END;

	FOR row := 0 TO fDoc.fRows - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row, fDoc.fRows);

		rDataPtr := fDoc.fData [0] . NeedPtr (row, row, FALSE);
		gDataPtr := fDoc.fData [1] . NeedPtr (row, row, FALSE);
		bDataPtr := fDoc.fData [2] . NeedPtr (row, row, FALSE);

		outDataPtr := fBuffer [0] . NeedPtr (row, row, TRUE);

		IF fDitherCode = 2 THEN
			BEGIN

			tempError := thisError;
			thisError := nextError;
			nextError := tempError;

			DoSetBytes (nextError, 6 * ORD4 (fDoc.fCols), 0);

			DiffuseRGB (rDataPtr, gDataPtr, bDataPtr, outDataPtr,
						thisError, nextError, table^, LUT, fDoc.fCols)

			END

		ELSE
			NoDitherRow (rDataPtr, gDataPtr, bDataPtr,
						 outDataPtr, table^, fDoc.fCols);

		fBuffer [0] . DoneWithPtr;

		fDoc.fData [0] . DoneWithPtr;
		fDoc.fData [1] . DoneWithPtr;
		fDoc.fData [2] . DoneWithPtr;

		rDataPtr := NIL;
		gDataPtr := NIL;
		bDataPtr := NIL

		END;

	UpdateProgress (1, 1);

	fBuffer [0] . Flush;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoConvert}

FUNCTION TCvtIndexedColor.Find5BitHistogram: Handle;

	TYPE
		T5BitHistogram = ARRAY [0..31, 0..31, 0..31] OF LONGINT;
		P5BitHistogram = ^T5BitHistogram;
		H5BitHistogram = ^P5BitHistogram;

	VAR
		r: Rect;
		fi: FailInfo;
		row: INTEGER;
		rDataPtr: Ptr;
		gDataPtr: Ptr;
		bDataPtr: Ptr;
		sWeight: INTEGER;
		hist: H5BitHistogram;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		FreeLargeHandle (Handle (hist));

		IF rDataPtr <> NIL THEN fDoc.fData [0] . DoneWithPtr;
		IF gDataPtr <> NIL THEN fDoc.fData [1] . DoneWithPtr;
		IF bDataPtr <> NIL THEN fDoc.fData [2] . DoneWithPtr;

		fDoc.fData [0] . Flush;
		fDoc.fData [1] . Flush;
		fDoc.fData [2] . Flush

		END;

	BEGIN

	hist := H5BitHistogram (NewLargeHandle (SIZEOF (T5BitHistogram)));

	DoSetBytes (Ptr (hist^), SIZEOF (T5BitHistogram), 0);

	rDataPtr := NIL;
	gDataPtr := NIL;
	bDataPtr := NIL;

	CatchFailures (fi, CleanUp);

	r := fDoc.fSelectionRect;

	IF NOT EmptyRect (r) THEN
		sWeight := 1 + Min (32767, BSL (fDoc.fRows * ORD4 (fDoc.fCols), 1) DIV
							((r.bottom - r.top) * ORD4 (r.right - r.left)));

	FOR row := 0 TO fDoc.fRows - 1 DO
		BEGIN

		MoveHands (TRUE);

		rDataPtr := fDoc.fData [0] . NeedPtr (row, row, FALSE);
		gDataPtr := fDoc.fData [1] . NeedPtr (row, row, FALSE);
		bDataPtr := fDoc.fData [2] . NeedPtr (row, row, FALSE);

		IF (row >= r.top) AND (row < r.bottom) THEN
			BEGIN

			IF r.left <> 0 THEN
				Do5BitHistogram (rDataPtr,
								 gDataPtr,
								 bDataPtr,
								 Ptr (hist^),
								 1,
								 r.left);

			Do5BitHistogram (Ptr (ORD4 (rDataPtr) + r.left),
							 Ptr (ORD4 (gDataPtr) + r.left),
							 Ptr (ORD4 (bDataPtr) + r.left),
							 Ptr (hist^),
							 sWeight,
							 r.right - r.left);

			IF r.right <> fDoc.fCols THEN
				Do5BitHistogram (Ptr (ORD4 (rDataPtr) + r.right),
								 Ptr (ORD4 (gDataPtr) + r.right),
								 Ptr (ORD4 (bDataPtr) + r.right),
								 Ptr (hist^),
								 1,
								 fDoc.fCols - r.right)

			END

		ELSE
			Do5BitHistogram (rDataPtr,
							 gDataPtr,
							 bDataPtr,
							 Ptr (hist^),
							 1,
							 fDoc.fCols);

		fDoc.fData [0] . DoneWithPtr;
		fDoc.fData [1] . DoneWithPtr;
		fDoc.fData [2] . DoneWithPtr;

		rDataPtr := NIL;
		gDataPtr := NIL;
		bDataPtr := NIL

		END;

	Success (fi);

	fDoc.fData [0] . Flush;
	fDoc.fData [1] . Flush;
	fDoc.fData [2] . Flush;

	hist^^ [ 0,  0,  0] := 0;
	hist^^ [ 0,  0, 31] := 0;
	hist^^ [ 0, 31,  0] := 0;
	hist^^ [31,  0,  0] := 0;
	hist^^ [ 0, 31, 31] := 0;
	hist^^ [31,  0, 31] := 0;
	hist^^ [31, 31,  0] := 0;
	hist^^ [31, 31, 31] := 0;

	Find5BitHistogram := Handle (hist)

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE SortColorTable (VAR table: TRGBLookUpTable);

	VAR
		j: INTEGER;
		k: INTEGER;
		temp: TRGBLookUpTable;
		data: PACKED ARRAY [0..255, 0..3] OF CHAR;

	BEGIN

	DoRGB2HSLorB (@table.R,
				  @table.G,
				  @table.B,
				  @temp.R,
				  @temp.G,
				  @temp.B,
				  256,
				  TRUE);

	FOR j := 0 TO 255 DO
		BEGIN

		IF temp.G [j] = CHR (0) THEN
			data [j, 0] := CHR (255)
		ELSE
			data [j, 0] := temp.R [j];

		data [j, 1] := CHR (255 - ORD (temp.G [j]));
		data [j, 2] := CHR (255 - ORD (temp.B [j]));
		data [j, 3] := CHR (j);

		END;

	qsort (@data [8], 248, 4, @CompareUnsignedLongs);

	FOR j := 0 TO 255 DO
		BEGIN
		k := ORD (data [j, 3]);
		temp.R [j] := table.R [k];
		temp.G [j] := table.G [k];
		temp.B [j] := table.B [k]
		END;

	table := temp

	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ADoConvert}

PROCEDURE TCvtIndexedColor.MedianCut (colors: INTEGER);

	TYPE
		TBox = ARRAY [0..2] OF RECORD
							   lower : INTEGER;
							   upper : INTEGER;
							   median: INTEGER;
							   score : INTEGER
							   END;
		TProjection = ARRAY [0..31] OF LONGINT;

	VAR
		x: INTEGER;
		y: INTEGER;
		z: INTEGER;
		fi: FailInfo;
		hist: Handle;
		index: INTEGER;
		count: INTEGER;
		bestBox: INTEGER;
		bestBand: INTEGER;
		bestScore: INTEGER;
		LUT: TRGBLookUpTable;
		box: ARRAY [0..247] OF TBox;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (hist)
		END;

	FUNCTION ShrinkBox (VAR box: TBox): BOOLEAN;

		VAR
			j: INTEGER;
			k: INTEGER;
			half: LONGINT;
			total: LONGINT;
			project: ARRAY [0..2] OF TProjection;

		BEGIN

		MoveHands (TRUE);

		DoSetBytes (@project, 3 * SIZEOF (TProjection), 0);

		DoProjectHist (box [0] . lower, box [0] . upper,
					   box [1] . lower, box [1] . upper,
					   box [2] . lower, box [2] . upper,
					   @project [0],
					   @project [1],
					   @project [2],
					   hist^);

		FOR j := 0 TO 2 DO
			WITH box [j] DO
				BEGIN

				WHILE project [j, lower] = 0 DO
					BEGIN
					lower := lower + 1;
					IF lower > upper THEN
						BEGIN
						ShrinkBox := FALSE;
						EXIT (ShrinkBox)
						END
					END;

				WHILE project [j, upper] = 0 DO
					upper := upper - 1;

				total := 0;
				FOR k := lower TO upper DO
					total := total + project [j, k];

				half := BSR (total + 1, 1);

				total := 0;
				FOR k := lower TO upper DO
					BEGIN
					total := total + project [j, k];
					IF total >= half THEN
						BEGIN
						median := k;
						LEAVE
						END
					END;

				score := upper - lower

				END;

		ShrinkBox := TRUE

		END;

	PROCEDURE SplitBox (VAR box1, box2: TBox; band: INTEGER);

		VAR
			split: INTEGER;

		BEGIN

		WITH box1 [band] DO
			IF median > BSR (lower + upper, 1) THEN
				split := median
			ELSE
				split := median + 1;

		box2 := box1;

		box2 [band] . lower := split;
		box1 [band] . upper := split - 1;

		IF NOT ShrinkBox (box1) OR NOT ShrinkBox (box2) THEN
			Failure (1, 0)

		END;

	BEGIN

	DoSetBytes (@LUT, SIZEOF (TRGBLookUpTable), 0);

	index := 0;

	FOR x := 1 DOWNTO 0 DO
		FOR y := 1 DOWNTO 0 DO
			FOR z := 1 DOWNTO 0 DO
				BEGIN
				LUT.R [index] := CHR (255 * x);
				LUT.G [index] := CHR (255 * y);
				LUT.B [index] := CHR (255 * z);
				index := index + 1
				END;

	colors := colors - index;

	IF colors > 0 THEN
		BEGIN

		hist := Find5BitHistogram;

		CatchFailures (fi, CleanUp);

		FOR x := 0 TO 2 DO
			BEGIN
			box [0, x] . lower := 0;
			box [0, x] . upper := 31
			END;

		IF ShrinkBox (box [0]) THEN
			BEGIN

			count := 1;

			WHILE count < colors DO
				BEGIN

				bestScore := 0;

				FOR x := 0 TO count - 1 DO
					FOR y := 0 TO 2 DO
						IF box [x, y] . score > bestScore THEN
							BEGIN
							bestScore := box [x, y] . score;
							bestBox   := x;
							bestBand  := y
							END;

				IF bestScore = 0 THEN LEAVE;

				SplitBox (box [bestBox], box [count], bestBand);

				count := count + 1

				END;

			FOR x := 0 TO count - 1 DO
				BEGIN
				y := box [x, 0] . median;
				LUT.R [index] := CHR (BSL (y, 3) + BSR (y, 2));
				y := box [x, 1] . median;
				LUT.G [index] := CHR (BSL (y, 3) + BSR (y, 2));
				y := box [x, 2] . median;
				LUT.B [index] := CHR (BSL (y, 3) + BSR (y, 2));
				index := index + 1
				END

			END;

		Success (fi);

		CleanUp (0, 0)

		END;

	SortColorTable (LUT);

	fDoc.fIndexedColorTable := LUT

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S ADoConvert}

FUNCTION TCvtIndexedColor.DoPattern (levels: INTEGER;
									 output: BOOLEAN): BOOLEAN;

	VAR
		fi: FailInfo;
		row: INTEGER;
		tempPtr: Ptr;
		rDataPtr: Ptr;
		gDataPtr: Ptr;
		bDataPtr: Ptr;
		outDataPtr: Ptr;
		colors: INTEGER;
		grayGap: INTEGER;
		ditherSize: INTEGER;
		thresTable: TThresTable;
		noiseTable: TNoiseTable;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		IF rDataPtr <> NIL THEN fDoc.fData [0] . DoneWithPtr;
		IF gDataPtr <> NIL THEN fDoc.fData [1] . DoneWithPtr;
		IF bDataPtr <> NIL THEN fDoc.fData [2] . DoneWithPtr;

		fDoc.fData [0] . Flush;
		fDoc.fData [1] . Flush;
		fDoc.fData [2] . Flush

		END;

	BEGIN

	MoveHands (TRUE);

	IF NOT output THEN
		BEGIN

		DoSetBytes (gBuffer, 32768, 0);

		tempPtr := Ptr (ORD4 (gBuffer) + $421 * ORD4 (levels - 1));

		gBuffer^ := 1;
		tempPtr^ := 1

		END;

	colors := BSL (1, fDepth) - 2;

	rDataPtr := NIL;
	gDataPtr := NIL;
	bDataPtr := NIL;

	CatchFailures (fi, CleanUp);

	CompThresTable (levels, grayGap, thresTable);

	CompNoiseTable (1, grayGap, ditherSize, noiseTable);

	FOR row := 0 TO fDoc.fRows - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row, fDoc.fRows);

		rDataPtr := fDoc.fData [0] . NeedPtr (row, row, FALSE);
		gDataPtr := fDoc.fData [1] . NeedPtr (row, row, FALSE);
		bDataPtr := fDoc.fData [2] . NeedPtr (row, row, FALSE);

		IF output THEN
			outDataPtr := fBuffer [0] . NeedPtr (row, row, TRUE)
		ELSE
			outDataPtr := NIL;

		DitherRGB (rDataPtr, gDataPtr, bDataPtr,
				   row, fDoc.fCols, outDataPtr,
				   ditherSize, noiseTable, thresTable,
				   gBuffer, colors);

		IF output THEN fBuffer [0] . DoneWithPtr;

		fDoc.fData [0] . DoneWithPtr;
		fDoc.fData [1] . DoneWithPtr;
		fDoc.fData [2] . DoneWithPtr;

		rDataPtr := NIL;
		gDataPtr := NIL;
		bDataPtr := NIL;

		IF colors < 0 THEN LEAVE

		END;

	UpdateProgress (1, 1);

	IF output THEN fBuffer [0] . Flush;

	Success (fi);

	CleanUp (0, 0);

	DoPattern := (colors >= 0)

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtIndexedColor.DoApproximateConversion;

	VAR
		p: Ptr;
		r: INTEGER;
		g: INTEGER;
		b: INTEGER;
		lower: INTEGER;
		upper: INTEGER;
		color: INTEGER;
		white: LONGINT;
		black: LONGINT;
		levels: INTEGER;
		address: LONGINT;
		sysTable: HRGBLookUpTable;

	FUNCTION Index2Gray (index: INTEGER): CHAR;
		BEGIN
		Index2Gray := CHR (255 - (index * 255 + BSR (levels - 1, 1)) DIV
								 (levels - 1))
		END;

	BEGIN

	color := 0;

	DoSetBytes (@fDoc.fIndexedColorTable, SIZEOF (TRGBLookUpTable), 0);

		CASE fDepth OF
		3:	levels := 2;
		4:	levels := 2;
		5:	levels := 3;
		6:	levels := 4;
		7:	levels := 5;
		8:	levels := 6
		END;

	IF fDitherCode <> 1 THEN
		BEGIN

		IF fAdaptive THEN
			MedianCut (BSL (1, fDepth))

		ELSE IF levels = 6 THEN
			BEGIN
			sysTable := HRGBLookUpTable (GetResource ('PLUT', 1000));
			FailNil (sysTable);
			fDoc.fIndexedColorTable := sysTable^^
			END

		ELSE
			FOR r := 0 TO levels - 1 DO
				FOR g := 0 TO levels - 1 DO
					FOR b := 0 TO levels - 1 DO
						BEGIN
						fDoc.fIndexedColorTable.R [color] := Index2Gray (r);
						fDoc.fIndexedColorTable.G [color] := Index2Gray (g);
						fDoc.fIndexedColorTable.B [color] := Index2Gray (b);
						color := color + 1
						END;

		DoDiffusion

		END

	ELSE
		BEGIN

		IF fAdaptive THEN
			BEGIN

			StartTask (0);

			IF DoPattern (32, FALSE) THEN
				levels := 32

			ELSE
				BEGIN

				upper := 32;
				lower := levels;

				WHILE upper - lower >= 2 DO
					BEGIN
					levels := BSR (upper + lower + 1, 1);
					IF DoPattern (levels, FALSE) THEN
						lower := levels
					ELSE
						upper := levels
					END;

				IF levels <> lower THEN
					BEGIN
					levels := lower;
					IF NOT DoPattern (levels, FALSE) THEN
						Failure (1, 0)
					END

				END;

			FinishTask

			END

		ELSE
			BEGIN

			DoSetBytes (gBuffer, $421 * (levels - 1), 0);

			FOR r := 0 TO levels - 1 DO
				FOR g := 0 TO levels - 1 DO
					FOR b := 0 TO levels - 1 DO
						BEGIN
						p  := Ptr (ORD4 (gBuffer) + $400 * b + $20 * g + r);
						p^ := 1
						END

			END;

		white := ORD4 (gBuffer);
		black := white + $421 * ORD4 (levels - 1);

		FOR address := white TO black DO
			IF Ptr (address)^ <> 0 THEN
				BEGIN

				{$PUSH}
				{$R-}
				Ptr (address)^ := color;
				{$POP}

				fDoc.fIndexedColorTable.R [color] :=
						Index2Gray (BAND (address - white, $1F));

				fDoc.fIndexedColorTable.G [color] :=
						Index2Gray (BAND (BSR (address - white, 5), $1F));

				fDoc.fIndexedColorTable.B [color] :=
						Index2Gray (BSR (address - white, 10));

				color := color + 1

				END;

		IF NOT DoPattern (levels, TRUE) THEN
			Failure (1, 0)

		END

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtIndexedColor.DoConversion; OVERRIDE;

	VAR
		aVMArray: TVMArray;

	BEGIN

	fState [TRUE] . fMode	  := IndexedColorMode;
	fState [TRUE] . fChannels := 1;

	IF fDoc.fMode = MonochromeMode THEN
		BEGIN

		fBuffer [0] := fDoc.fData [0];

		fDoc.fIndexedColorTable.R := gNullLUT;
		fDoc.fIndexedColorTable.G := gNullLUT;
		fDoc.fIndexedColorTable.B := gNullLUT

		END

	ELSE
		BEGIN

		aVMArray := NewVMArray (fDoc.fRows, fDoc.fCols, 1);

		fBuffer [0] := aVMArray;

		IF fExact THEN
			DoExactConversion
		ELSE
			DoApproximateConversion

		END;

	fDoc.TestColorTable

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtRGBColor.DoConversion; OVERRIDE;

	VAR
		fi: FailInfo;
		row: INTEGER;
		srcPtr0: Ptr;
		srcPtr1: Ptr;
		srcPtr2: Ptr;
		channel: INTEGER;
		map: TLookUpTable;
		aVMArray: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		IF srcPtr0 <> NIL THEN fDoc.fData [0] . DoneWithPtr;
		IF srcPtr1 <> NIL THEN fDoc.fData [1] . DoneWithPtr;
		IF srcPtr2 <> NIL THEN fDoc.fData [2] . DoneWithPtr;

		fDoc.fData [0] . Flush;
		fDoc.fData [1] . Flush;
		fDoc.fData [2] . Flush

		END;

	BEGIN

	fState [TRUE] . fMode := RGBColorMode;

		CASE fDoc.fMode OF

		MonochromeMode,
		IndexedColorMode:
			BEGIN

			fState [TRUE] . fChannels := 3;

			FOR channel := 0 TO 2 DO
				BEGIN

				aVMArray := fDoc.fData [0] . CopyArray (3 - channel);
				fBuffer [channel] := aVMArray;

				IF fDoc.fMode = IndexedColorMode THEN
					BEGIN

						CASE channel OF
						0:	map := fDoc.fIndexedColorTable.R;
						1:	map := fDoc.fIndexedColorTable.G;
						2:	map := fDoc.fIndexedColorTable.B
						END;

					aVMArray.MapBytes (map)

					END

				END

			END;

		SeparationsCMYK:
			BEGIN

			fState [TRUE] . fChannels := fDoc.fChannels - 1;

			FOR channel := 0 TO 2 DO
				BEGIN
				aVMArray := NewVMArray (fDoc.fRows, fDoc.fCols, 3 - channel);
				fBuffer [channel] := aVMArray
				END;

			FOR channel := 4 TO fDoc.fChannels - 1 DO
				fBuffer [channel - 1] := fDoc.fData [channel];

			ConvertCMYK2RGB (fDoc.fData [0],
							 fDoc.fData [1],
							 fDoc.fData [2],
							 fDoc.fData [3],
							 fBuffer [0],
							 fBuffer [1],
							 fBuffer [2])

			END;

		SeparationsHSL,
		SeparationsHSB:
			BEGIN

			FOR channel := 0 TO 2 DO
				BEGIN
				aVMArray := NewVMArray (fDoc.fRows, fDoc.fCols, 3 - channel);
				fBuffer [channel] := aVMArray
				END;

			FOR channel := 3 TO fDoc.fChannels - 1 DO
				fBuffer [channel] := fDoc.fData [channel];

			srcPtr0 := NIL;
			srcPtr1 := NIL;
			srcPtr2 := NIL;

			CatchFailures (fi, CleanUp);

			FOR row := 0 TO fDoc.fRows - 1 DO
				BEGIN

				MoveHands (TRUE);

				UpdateProgress (row, fDoc.fRows);

				srcPtr0 := fDoc.fData [0] . NeedPtr (row, row, FALSE);
				srcPtr1 := fDoc.fData [1] . NeedPtr (row, row, FALSE);
				srcPtr2 := fDoc.fData [2] . NeedPtr (row, row, FALSE);

				DoHSLorB2RGB (srcPtr0,
							  srcPtr1,
							  srcPtr2,
							  fBuffer [0] . NeedPtr (row, row, TRUE),
							  fBuffer [1] . NeedPtr (row, row, TRUE),
							  fBuffer [2] . NeedPtr (row, row, TRUE),
							  fDoc.fCols,
							  fDoc.fMode = SeparationsHSB);

				fBuffer [0] . DoneWithPtr;
				fBuffer [1] . DoneWithPtr;
				fBuffer [2] . DoneWithPtr;

				fDoc.fData [0] . DoneWithPtr;
				fDoc.fData [1] . DoneWithPtr;
				fDoc.fData [2] . DoneWithPtr;

				srcPtr0 := NIL;
				srcPtr1 := NIL;
				srcPtr2 := NIL

				END;

			UpdateProgress (1, 1);

			fBuffer [0] . Flush;
			fBuffer [1] . Flush;
			fBuffer [2] . Flush;

			Success (fi);

			CleanUp (0, 0)

			END;

		MultichannelMode:
			FOR channel := 0 TO fDoc.fChannels - 1 DO
				fBuffer [channel] := fDoc.fData [channel]

		END

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtSeparationsCMYK.GetOptions; OVERRIDE;

	BEGIN
	
	IF fDoc.fMode = RGBColorMode THEN
		BuildSeparationTable

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtSeparationsCMYK.DoConversion; OVERRIDE;

	VAR
		channel: INTEGER;
		aVMArray: TVMArray;
		lut: TRGBLookUpTable;
		map: ARRAY [0..3] OF TLookUpTable;

	BEGIN

	fState [TRUE] . fMode := SeparationsCMYK;

		CASE fDoc.fMode OF

		IndexedColorMode:
			BEGIN

			fState [TRUE] . fChannels := 4;

			lut := fDoc.fIndexedColorTable;

			SeparateColorLUT (lut, map [0], map [1], map [2], map [3]);

			FOR channel := 0 TO 3 DO
				BEGIN

				MoveHands (TRUE);

				aVMArray := fDoc.fData [0] . CopyArray (4 - channel);
				fBuffer [channel] := aVMArray;

				MoveHands (TRUE);

				aVMArray.MapBytes (map [channel])

				END

			END;

		RGBColorMode:
			BEGIN

			fState [TRUE] . fChannels := fDoc.fChannels + 1;

			FOR channel := 0 TO 3 DO
				BEGIN
				aVMArray := NewVMArray (fDoc.fRows, fDoc.fCols, 4 - channel);
				fBuffer [channel] := aVMArray
				END;

			FOR channel := 3 TO fDoc.fChannels - 1 DO
				fBuffer [channel + 1] := fDoc.fData [channel];

			ConvertRGB2CMYK (fDoc.fData [0],
							 fDoc.fData [1],
							 fDoc.fData [2],
							 fBuffer [0],
							 fBuffer [1],
							 fBuffer [2],
							 fBuffer [3])

			END;

		MultichannelMode:
			FOR channel := 0 TO fDoc.fChannels - 1 DO
				fBuffer [channel] := fDoc.fData [channel]

		END

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtSeparationsHSL.RealConversion (bright: BOOLEAN);

	VAR
		rPtr: Ptr;
		gPtr: Ptr;
		bPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		channel: INTEGER;
		aVMArray: TVMArray;
		map: ARRAY [0..2] OF TLookUpTable;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		IF rPtr <> NIL THEN fDoc.fData [0] . DoneWithPtr;
		IF gPtr <> NIL THEN fDoc.fData [1] . DoneWithPtr;
		IF bPtr <> NIL THEN fDoc.fData [2] . DoneWithPtr;

		fDoc.fData [0] . Flush;
		fDoc.fData [1] . Flush;
		fDoc.fData [2] . Flush

		END;

	BEGIN

		CASE fDoc.fMode OF

		IndexedColorMode:
			BEGIN

			fState [TRUE] . fChannels := 3;

			DoRGB2HSLorB (@fDoc.fIndexedColorTable.R,
						  @fDoc.fIndexedColorTable.G,
						  @fDoc.fIndexedColorTable.B,
						  @map [0],
						  @map [1],
						  @map [2],
						  256,
						  bright);

			FOR channel := 0 TO 2 DO
				BEGIN

				MoveHands (TRUE);

				aVMArray := fDoc.fData [0] . CopyArray (3 - channel);
				fBuffer [channel] := aVMArray;

				MoveHands (TRUE);

				aVMArray.MapBytes (map [channel])

				END

			END;

		RGBColorMode:
			BEGIN

			FOR channel := 0 TO 2 DO
				BEGIN
				aVMArray := NewVMArray (fDoc.fRows, fDoc.fCols, 3 - channel);
				fBuffer [channel] := aVMArray
				END;

			FOR channel := 3 TO fDoc.fChannels - 1 DO
				fBuffer [channel] := fDoc.fData [channel];

			rPtr := NIL;
			gPtr := NIL;
			bPtr := NIL;

			CatchFailures (fi, CleanUp);

			FOR row := 0 TO fDoc.fRows - 1 DO
				BEGIN

				MoveHands (TRUE);

				UpdateProgress (row, fDoc.fRows - 1);

				rPtr := fDoc.fData [0] . NeedPtr (row, row, FALSE);
				gPtr := fDoc.fData [1] . NeedPtr (row, row, FALSE);
				bPtr := fDoc.fData [2] . NeedPtr (row, row, FALSE);

				DoRGB2HSLorB (rPtr,
							  gPtr,
							  bPtr,
							  fBuffer [0] . NeedPtr (row, row, TRUE),
							  fBuffer [1] . NeedPtr (row, row, TRUE),
							  fBuffer [2] . NeedPtr (row, row, TRUE),
							  fDoc.fCols,
							  bright);

				fBuffer [0] . DoneWithPtr;
				fBuffer [1] . DoneWithPtr;
				fBuffer [2] . DoneWithPtr;

				fDoc.fData [0] . DoneWithPtr;
				fDoc.fData [1] . DoneWithPtr;
				fDoc.fData [2] . DoneWithPtr;

				rPtr := NIL;
				gPtr := NIL;
				bPtr := NIL

				END;

			UpdateProgress (1, 1);

			fBuffer [0] . Flush;
			fBuffer [1] . Flush;
			fBuffer [2] . Flush;

			Success (fi);

			CleanUp (0, 0)

			END;

		MultichannelMode:
			FOR channel := 0 TO fDoc.fChannels - 1 DO
				fBuffer [channel] := fDoc.fData [channel]

		END

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtSeparationsHSL.DoConversion; OVERRIDE;

	BEGIN

	fState [TRUE] . fMode := SeparationsHSL;

	RealConversion (FALSE)

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtSeparationsHSB.DoConversion; OVERRIDE;

	BEGIN

	fState [TRUE] . fMode := SeparationsHSB;

	RealConversion (TRUE)

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TCvtMultichannel.DoConversion; OVERRIDE;

	VAR
		channel: INTEGER;

	BEGIN

	fState [TRUE] . fMode := MultichannelMode;

	FOR channel := 0 TO fDoc.fChannels - 1 DO
		fBuffer [channel] := fDoc.fData [channel]

	END;

{*****************************************************************************}

{$S ASelCommand}

FUNCTION DoConvertCommand (view: TImageView; mode: TDisplayMode): TCommand;

	VAR
		aCvtCommand 		: TCvtCommand;
		aCvtHalftone		: TCvtHalftone;
		aCvtMonochrome		: TCvtMonochrome;
		aCvtIndexedColor	: TCvtIndexedColor;
		aCvtRGBColor		: TCvtRGBColor;
		aCvtSeparationsCMYK : TCvtSeparationsCMYK;
		aCvtSeparationsHSL	: TCvtSeparationsHSL;
		aCvtSeparationsHSB	: TCvtSeparationsHSB;
		aCvtMultichannel	: TCvtMultichannel;

	BEGIN

	IF TImageDocument (view.fDocument) . fMode = mode THEN
		DoConvertCommand := gNoChanges

	ELSE
		BEGIN

			CASE mode OF

			HalftoneMode:
				BEGIN
				NEW (aCvtHalftone);
				aCvtCommand := aCvtHalftone
				END;

			MonochromeMode:
				BEGIN
				NEW (aCvtMonochrome);
				aCvtCommand := aCvtMonochrome
				END;

			IndexedColorMode:
				BEGIN
				NEW (aCvtIndexedColor);
				aCvtCommand := aCvtIndexedColor
				END;

			RGBColorMode:
				BEGIN
				NEW (aCvtRGBColor);
				aCvtCommand := aCvtRGBColor
				END;

			SeparationsCMYK:
				BEGIN
				NEW (aCvtSeparationsCMYK);
				aCvtCommand := aCvtSeparationsCMYK
				END;

			SeparationsHSL:
				BEGIN
				NEW (aCvtSeparationsHSL);
				aCvtCommand := aCvtSeparationsHSL
				END;

			SeparationsHSB:
				BEGIN
				NEW (aCvtSeparationsHSB);
				aCvtCommand := aCvtSeparationsHSB
				END;

			MultichannelMode:
				BEGIN
				NEW (aCvtMultichannel);
				aCvtCommand := aCvtMultichannel
				END

			END;

		FailNil (aCvtCommand);

		aCvtCommand.ICvtCommand (cConversion, view);

		DoConvertCommand := aCvtCommand

		END

	END;

{*****************************************************************************}

{$S ADoConvert}

PROCEDURE TDeleteChannelCommand.DoConversion; OVERRIDE;

	VAR
		channel: INTEGER;

	BEGIN

	fState [TRUE] . fChannels := fDoc.fChannels - 1;

	FOR channel := 0 TO fView.fChannel - 1 DO
		fBuffer [channel] := fDoc.fData [channel];

	FOR channel := fView.fChannel + 1 To fDoc.fChannels - 1 DO
		fBuffer [channel - 1] := fDoc.fData [channel];

	IF fDoc.fChannels = 2 THEN
		fState [TRUE] . fMode := MonochromeMode

	ELSE IF (fDoc.fChannels = 3) OR
			(fDoc.fMode IN [RGBColorMode, SeparationsHSL, SeparationsHSB]) AND
			(fView.fChannel < 3) OR
			(fDoc.fMode = SeparationsCMYK) AND
			(fView.fChannel < 4) THEN
		fState [TRUE] . fMode := MultichannelMode

	END;

{*****************************************************************************}

{$S ADoConvert}

FUNCTION DoDeleteChannel (view: TImageView): TCommand;

	VAR
		aDeleteChannelCommand: TDeleteChannelCommand;

	BEGIN

	NEW (aDeleteChannelCommand);
	FailNil (aDeleteChannelCommand);

	aDeleteChannelCommand.ICvtCommand (cDeleteChannel, view);

	DoDeleteChannel := aDeleteChannelCommand

	END;

{*****************************************************************************}

END.

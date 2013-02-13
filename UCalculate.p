{Photoshop version 1.0.1, file: UCalculate.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UCalculate;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UBWDialog, UCommands, UProgress;

TYPE

	TChannelSelector = OBJECT (TDialogItem)

		fProtoView	  : TImageView;
		fProtoDocument: TImageDocument;

		fCanCreate : BOOLEAN;
		fAllowMask : BOOLEAN;
		fPreferMask: BOOLEAN;
		fPreferRGB : BOOLEAN;

		fSource: ARRAY [1..3] OF TChannelSelector;

		fPickedDocument: TImageDocument;
		fPickedChannel : INTEGER;

		fMenu1: MenuHandle;
		fMenu2: MenuHandle;

		fPopUpMenu1: TPopUpMenu;
		fPopUpMenu2: TPopUpMenu;

		fNewChannelPick : INTEGER;
		fOldChannelsPick: INTEGER;
		fRGBChannelsPick: INTEGER;
		fMaskChannelPick: INTEGER;

		PROCEDURE TChannelSelector.IChannelSelector
				(itsDialog: TBWDialog;
				 itsItemNumber: INTEGER;
				 prototype: TImageView;
				 canCreate: BOOLEAN;
				 allowMask: BOOLEAN;
				 preferMask: BOOLEAN;
				 preferRGB: BOOLEAN;
				 source1: TChannelSelector;
				 source2: TChannelSelector;
				 source3: TChannelSelector);

		PROCEDURE TChannelSelector.Free; OVERRIDE;

		PROCEDURE TChannelSelector.ForAllSameSizeDocs
				(PROCEDURE DoIt (doc: TImageDocument));

		PROCEDURE TChannelSelector.BuildMenu2 (VAR pick: INTEGER);

		FUNCTION TChannelSelector.ItemSelected
				(anItem: INTEGER;
				 VAR handledIt: BOOLEAN;
				 VAR doneWithDialog: BOOLEAN): TCommand; OVERRIDE;

		PROCEDURE TChannelSelector.Validate
				(VAR succeeded: BOOLEAN); OVERRIDE;

		END;

	TCalculateCommand = OBJECT (TBufferCommand)

		fDstDocument: TImageDocument;
		fDstChannel : INTEGER;

		PROCEDURE TCalculateCommand.ICalculateCommand (view: TImageView);

		PROCEDURE TCalculateCommand.GetOptions;

		FUNCTION TCalculateCommand.ValidDestination (RGB: BOOLEAN): BOOLEAN;

		PROCEDURE TCalculateCommand.DoCalculation (band: INTEGER);

		FUNCTION TCalculateCommand.BandArray (doc: TImageDocument;
											  channel: INTEGER;
											  band: INTEGER): TVMArray;

		PROCEDURE TCalculateCommand.CopyToBuffer (doc: TImageDocument;
												  channel: INTEGER;
												  band: INTEGER);

		PROCEDURE TCalculateCommand.DoIt; OVERRIDE;

		PROCEDURE TCalculateCommand.UndoIt; OVERRIDE;

		PROCEDURE TCalculateCommand.RedoIt; OVERRIDE;

		END;

	TDuplicateChannel = OBJECT (TCalculateCommand)

		fInvert: BOOLEAN;

		fSrcDocument: TImageDocument;
		fSrcChannel : INTEGER;

		PROCEDURE TDuplicateChannel.GetOptions; OVERRIDE;

		PROCEDURE TDuplicateChannel.DoCalculation (band: INTEGER); OVERRIDE;

		END;

	TConstantChannel = OBJECT (TCalculateCommand)

		fConstant: INTEGER;

		PROCEDURE TConstantChannel.GetOptions; OVERRIDE;

		PROCEDURE TConstantChannel.DoCalculation (band: INTEGER); OVERRIDE;

		END;

	TCompositeChannels = OBJECT (TCalculateCommand)

		fForeDocument: TImageDocument;
		fForeChannel : INTEGER;

		fMaskDocument: TImageDocument;
		fMaskChannel : INTEGER;

		fBackDocument: TImageDocument;
		fBackChannel : INTEGER;

		PROCEDURE TCompositeChannels.GetOptions; OVERRIDE;

		PROCEDURE TCompositeChannels.DoCalculation (band: INTEGER); OVERRIDE;

		END;

	TBinaryCalculation = OBJECT (TCalculateCommand)

		fSrc1Document: TImageDocument;
		fSrc1Channel : INTEGER;

		fSrc2Document: TImageDocument;
		fSrc2Channel : INTEGER;

		PROCEDURE TBinaryCalculation.PrepareCalculation;

		PROCEDURE TBinaryCalculation.DoBinaryCalculation (srcPtr: Ptr;
														  dstPtr: Ptr;
														  count: INTEGER);

		PROCEDURE TBinaryCalculation.DoCalculation (band: INTEGER); OVERRIDE;

		END;

	TBlendChannels = OBJECT (TBinaryCalculation)

		fPercent: INTEGER;

		fMap1: TLookUpTable;
		fMap2: TLookUpTable;

		PROCEDURE TBlendChannels.GetOptions; OVERRIDE;

		PROCEDURE TBlendChannels.PrepareCalculation; OVERRIDE;

		PROCEDURE TBlendChannels.DoBinaryCalculation
				(srcPtr: Ptr; dstPtr: Ptr; count: INTEGER); OVERRIDE;

		END;

	TSOffsetBinary = OBJECT (TBinaryCalculation)

		fIndex: INTEGER;

		fScale: INTEGER;
		fOffset: INTEGER;

		PROCEDURE TSOffsetBinary.ISOffsetBinary (view: TImageView;
												 index: INTEGER);

		PROCEDURE TSOffsetBinary.GetOptions; OVERRIDE;

		END;

	TAddChannels = OBJECT (TSOffsetBinary)

		PROCEDURE TAddChannels.DoBinaryCalculation
				(srcPtr: Ptr; dstPtr: Ptr; count: INTEGER); OVERRIDE;

		END;

	TSubtractChannels = OBJECT (TSOffsetBinary)

		PROCEDURE TSubtractChannels.DoBinaryCalculation
				(srcPtr: Ptr; dstPtr: Ptr; count: INTEGER); OVERRIDE;

		END;

	TSimpleBinary = OBJECT (TBinaryCalculation)

		fIndex: INTEGER;

		PROCEDURE TSimpleBinary.ISimpleBinary (view: TImageView;
											   index: INTEGER);

		PROCEDURE TSimpleBinary.GetOptions; OVERRIDE;

		END;

	TMultiplyChannels = OBJECT (TSimpleBinary)

		PROCEDURE TMultiplyChannels.DoBinaryCalculation
				(srcPtr: Ptr; dstPtr: Ptr; count: INTEGER); OVERRIDE;

		END;

	TLighterChannel = OBJECT (TSimpleBinary)

		PROCEDURE TLighterChannel.DoBinaryCalculation
				(srcPtr: Ptr; dstPtr: Ptr; count: INTEGER); OVERRIDE;

		END;

	TDarkerChannel = OBJECT (TSimpleBinary)

		PROCEDURE TDarkerChannel.DoBinaryCalculation
				(srcPtr: Ptr; dstPtr: Ptr; count: INTEGER); OVERRIDE;

		END;

	TDiffOfChannels = OBJECT (TSimpleBinary)

		PROCEDURE TDiffOfChannels.DoBinaryCalculation
				(srcPtr: Ptr; dstPtr: Ptr; count: INTEGER); OVERRIDE;

		END;

	TScreenChannels = OBJECT (TSimpleBinary)

		PROCEDURE TScreenChannels.DoBinaryCalculation
				(srcPtr: Ptr; dstPtr: Ptr; count: INTEGER); OVERRIDE;

		END;

PROCEDURE InitCalculate;

FUNCTION DoDuplicateCommand (view: TImageView): TCommand;

FUNCTION DoConstantCommand (view: TImageView): TCommand;

FUNCTION DoCompositeCommand (view: TImageView): TCommand;

FUNCTION DoBlendCommand (view: TImageView): TCommand;

FUNCTION DoSubtractCommand (view: TImageView): TCommand;

FUNCTION DoAddCommand (view: TImageView): TCommand;

FUNCTION DoMultiplyCommand (view: TImageView): TCommand;

FUNCTION DoLighterCommand (view: TImageView): TCommand;

FUNCTION DoDarkerCommand (view: TImageView): TCommand;

FUNCTION DoDifferenceCommand (view: TImageView): TCommand;

FUNCTION DoScreenCommand (view: TImageView): TCommand;

IMPLEMENTATION

{$I UAssembly.a.inc}
{$I UCalculate.a.inc}
{$I USelect.p.inc}

VAR

	gLastBlend: INTEGER;

	gLastConstant: INTEGER;

	gLastScale: ARRAY [1..2] OF INTEGER;
	gLastOffset: ARRAY [1..2] OF INTEGER;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitCalculate;

	BEGIN

	gLastBlend := 50;

	gLastConstant := 0;

	gLastScale	[1] := 1000;
	gLastOffset [1] := 0;

	gLastScale	[2] := 1000;
	gLastOffset [2] := 0

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TChannelSelector.IChannelSelector (itsDialog: TBWDialog;
											 itsItemNumber: INTEGER;
											 prototype: TImageView;
											 canCreate: BOOLEAN;
											 allowMask: BOOLEAN;
											 preferMask: BOOLEAN;
											 preferRGB: BOOLEAN;
											 source1: TChannelSelector;
											 source2: TChannelSelector;
											 source3: TChannelSelector);


	CONST
		kBaseMenuID = 10000;

	VAR
		s: Str255;
		pick: INTEGER;

	PROCEDURE AddDocToMenu (doc: TImageDocument);

		VAR
			item: INTEGER;

		BEGIN

		AppendMenu (fMenu1, 'Dummy');
		item := CountMItems (fMenu1);

		s := doc.fTitle;
		IF s[1] = '-' THEN s[1] := CHR ($D0);
		SetItem (fMenu1, item, s);

		IF doc = fProtoDocument THEN pick := item

		END;

	BEGIN

	fProtoView	   := prototype;
	fProtoDocument := TImageDocument (prototype.fDocument);

	fCanCreate	:= canCreate;
	fAllowMask	:= allowMask;
	fPreferMask := preferMask;
	fPreferRGB	:= preferRGB;

	fSource [1] := source1;
	fSource [2] := source2;
	fSource [3] := source3;

	fMenu1 := NIL;
	fMenu2 := NIL;

	IDialogItem (itsItemNumber, itsDialog, FALSE);

	fMenu1 := NewMenu (kBaseMenuID + itsItemNumber, '');

	ForAllSameSizeDocs (AddDocToMenu);

	IF fCanCreate THEN
		BEGIN
		fProtoDocument.ChannelName (kDummyChannel, s);
		AppendMenu (fMenu1, s);
		pick := CountMItems (fMenu1);
		fPickedDocument := NIL
		END
	ELSE
		fPickedDocument := fProtoDocument;

	fPopUpMenu1 := itsDialog.DefinePopUpMenu
			(itsItemNumber, itsItemNumber + 1, fMenu1, pick);

	BuildMenu2 (pick);

	fPopUpMenu2 := itsDialog.DefinePopUpMenu
			(itsItemNumber + 2, itsItemNumber + 3, fMenu2, pick)

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TChannelSelector.Free; OVERRIDE;

	BEGIN

	IF fMenu1 <> NIL THEN DisposeMenu (fMenu1);
	IF fMenu2 <> NIL THEN DisposeMenu (fMenu2);

	INHERITED Free

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TChannelSelector.ForAllSameSizeDocs
		(PROCEDURE DoIt (doc: TImageDocument));

	PROCEDURE TestIt (doc: TImageDocument);
		BEGIN
		IF (doc.fDepth = 8) AND
		   (doc.fMode <> IndexedColorMode) AND
		   (doc.fRows = fProtoDocument.fRows) AND
		   (doc.fCols = fProtoDocument.fCols) THEN DoIt (doc)
		END;

	BEGIN
	gApplication.ForAllDocumentsDo (TestIt)
	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TChannelSelector.BuildMenu2 (VAR pick: INTEGER);

	CONST
		kBaseMenuID = 11000;

	VAR
		s: Str255;
		which: INTEGER;
		channel: INTEGER;
		preferRGB: BOOLEAN;
		succeeded: BOOLEAN;

	BEGIN

	pick := 0;

	fNewChannelPick  := 0;
	fOldChannelsPick := 0;
	fRGBChannelsPick := 0;
	fMaskChannelPick := 0;

	fMenu2 := NewMenu (kBaseMenuID + fItemNumber, '');

	IF ((fPickedDocument <> NIL) &
		(fPickedDocument.fMode = RGBColorMode)) THEN
		BEGIN

		fProtoDocument.ChannelName (kRGBChannels, s);
		AppendMenu (fMenu2, s);
		fRGBChannelsPick := 1;

		preferRGB := fPreferRGB;

		FOR which := 1 TO 3 DO
			IF NOT preferRGB AND (fSource [which] <> NIL) THEN
				BEGIN
				fSource [which] . Validate (succeeded);
				IF fSource [which] . fPickedChannel = kRGBChannels THEN
					preferRGB := TRUE
				END;

		IF preferRGB THEN pick := fRGBChannelsPick

		END;

	IF fPickedDocument <> NIL THEN
		BEGIN

		fOldChannelsPick := CountMItems (fMenu2) + 1;

		FOR channel := 0 TO fPickedDocument.fChannels - 1 DO
			BEGIN
			fPickedDocument.ChannelName (channel, s);
			AppendMenu (fMenu2, s)
			END

		END;

	IF fCanCreate AND ((fPickedDocument = NIL) |
					   (fPickedDocument.fChannels < kMaxChannels)) THEN
		BEGIN

		fProtoDocument.ChannelName (fProtoDocument.fChannels, s);
		AppendMenu (fMenu2, s);
		fNewChannelPick := CountMItems (fMenu2);

		IF pick = 0 THEN pick := fNewChannelPick

		END;

	IF fAllowMask AND (fPickedDocument <> NIL) THEN
		IF fCanCreate OR NOT EmptyRect (fPickedDocument.fSelectionRect) THEN
			BEGIN

			fPickedDocument.ChannelName (kMaskChannel, s);
			AppendMenu (fMenu2, s);
			fMaskChannelPick := CountMItems (fMenu2);

			IF fPreferMask THEN pick := fMaskChannelPick

			END;

	IF pick = 0 THEN
		IF fPreferMask THEN
			pick := fOldChannelsPick + fPickedDocument.fChannels - 1
		ELSE IF fPickedDocument = fProtoDocument THEN
			pick := fOldChannelsPick + Max (0, fProtoView.fChannel)
		ELSE
			pick := fOldChannelsPick

	END;

{*****************************************************************************}

{$S ADoCalculate}

FUNCTION TChannelSelector.ItemSelected
		(anItem: INTEGER;
		 VAR handledIt: BOOLEAN;
		 VAR doneWithDialog: BOOLEAN): TCommand; OVERRIDE;

	VAR
		pick: INTEGER;

	PROCEDURE DecodePick (doc: TImageDocument);
		BEGIN
		pick := pick + 1;
		IF pick = fPopUpMenu1.fPick THEN
			fPickedDocument := doc
		END;

	BEGIN

	ItemSelected := gNoChanges;

	IF anItem = fItemNumber + 1 THEN
		BEGIN

		pick := 0;
		fPickedDocument := NIL;

		ForAllSameSizeDocs (DecodePick);

		DisposeMenu (fMenu2);

		BuildMenu2 (pick);
		fPopUpMenu2.SetMenu (fMenu2, pick)

		END

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TChannelSelector.Validate (VAR succeeded: BOOLEAN); OVERRIDE;

	BEGIN

	succeeded := TRUE;

	fPickedChannel := fPopUpMenu2.fPick - fOldChannelsPick;

	IF fPopUpMenu2.fPick = fNewChannelPick THEN
		IF fPickedDocument <> NIL THEN
			fPickedChannel := fPickedDocument.fChannels
		ELSE
			fPickedChannel := 0;

	IF fPopUpMenu2.fPick = fRGBChannelsPick THEN
		fPickedChannel := kRGBChannels;

	IF fPopUpMenu2.fPick = fMaskChannelPick THEN
		fPickedChannel := kMaskChannel

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TCalculateCommand.ICalculateCommand (view: TImageView);

	VAR
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Free
		END;

	BEGIN

	IBufferCommand (cCalculation, view);

	CatchFailures (fi, CleanUp);

	GetOptions;

	Success (fi)

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TCalculateCommand.GetOptions;

	BEGIN

	{$IFC qDebug}
	ProgramBreak ('Need to override GetOptions')
	{$ENDC}

	END;

{*****************************************************************************}

{$S ADoCalculate}

FUNCTION TCalculateCommand.ValidDestination (RGB: BOOLEAN): BOOLEAN;

	CONST
		kNeedColorID  = 911;
		kNeedSingleID = 912;

	BEGIN

	IF (fDstDocument = NIL) AND RGB THEN fDstChannel := kRGBChannels;

	IF RGB <> (fDstChannel = kRGBChannels) THEN
		BEGIN

		ValidDestination := FALSE;

		IF RGB THEN
			BWNotice (kNeedColorID, TRUE)
		ELSE
			BWNotice (kNeedSingleID, TRUE)

		END

	ELSE
		ValidDestination := TRUE

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TCalculateCommand.DoCalculation (band: INTEGER);

	BEGIN

	{$IFC qDebug}
	ProgramBreak ('Need to override DoCalculation')
	{$ENDC}

	END;

{*****************************************************************************}

{$S ADoCalculate}

FUNCTION TCalculateCommand.BandArray (doc: TImageDocument;
									  channel: INTEGER;
									  band: INTEGER): TVMArray;

	BEGIN

	IF channel = kRGBChannels THEN
		BandArray := doc.fData [band]
	ELSE
		BandArray := doc.fData [channel]

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TCalculateCommand.CopyToBuffer (doc: TImageDocument;
										  channel: INTEGER;
										  band: INTEGER);

	VAR
		srcArray: TVMArray;

	BEGIN

	MoveHands (TRUE);

	IF channel = kMaskChannel THEN
		CopyAlphaChannel (doc, fBuffer [band])

	ELSE
		BEGIN
		srcArray := BandArray (doc, channel, band);
		srcArray.MoveArray (fBuffer [band]);
		END;

	MoveHands (TRUE)

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE SelectAlphaChannel (doc: TImageDocument; buffer: TVMArray);

	VAR
		r: Rect;
		old: Rect;
		fi: FailInfo;
		gray: INTEGER;
		mask: TVMArray;
		hist: THistogram;
		view: TImageView;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (mask)
		END;

	BEGIN

	MoveHands (TRUE);

	buffer.FindBounds (r);

	IF EmptyRect (r) THEN
		Failure (errNoPixels, msgCannotSelect);

	MoveHands (TRUE);

	mask := buffer.CopyRect (r, 1);

	CatchFailures (fi, CleanUp);

	MoveHands (TRUE);

	mask.HistBytes (hist);

	IF hist [255] = mask.fBlockCount * ORD4 (mask.fLogicalSize) THEN
		BEGIN
		mask.Free;
		mask := NIL
		END

	ELSE
		BEGIN

		gray := 255;
		WHILE hist [gray] = 0 DO
			gray := gray - 1;

		IF gray < 128 THEN
			Failure (errNoPixels, msgCannotSelect)

		END;

	MoveHands (TRUE);

	old := doc.fSelectionRect;

	view := NIL;

	IF MEMBER (gTarget, TImageView) THEN
		IF TImageView (gTarget) . fDocument = doc THEN
			view := TImageView (gTarget);

	IF doc.fSelectionMask = NIL THEN
		BEGIN
		IF view <> NIL THEN view.UpdateImageArea (gZeroRect, FALSE);
		doc.DeSelect (TRUE)
		END
	ELSE
		BEGIN
		doc.DeSelect (FALSE);
		IF view <> NIL THEN view.UpdateImageArea (old, FALSE)
		END;

	Success (fi);

	doc.Select (r, mask)

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TCalculateCommand.DoIt; OVERRIDE;

	VAR
		s: Str255;
		fi: FailInfo;
		band: INTEGER;
		bands: INTEGER;
		aVMArray: TVMArray;
		dstView: TImageView;

	PROCEDURE CleanUp1 (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress
		END;

	PROCEDURE CleanUp2 (error: INTEGER; message: LONGINT);
		BEGIN
		fDstDocument.Free
		END;

	PROCEDURE FindView (view: TImageView);
		BEGIN
		IF dstView = NIL THEN
			IF fDstChannel = view.fChannel THEN
				dstView := view
		END;

	PROCEDURE DoUpdateTitle (view: TImageView);
		BEGIN
		view.UpdateWindowTitle
		END;

	BEGIN

	MoveHands (TRUE);

	IF fDstChannel = kRGBChannels THEN
		bands := 3
	ELSE
		bands := 1;

	FOR band := 0 TO bands - 1 DO
		BEGIN
		aVMArray := NewVMArray (fDoc.fRows, fDoc.fCols, bands - band);
		fBuffer [band] := aVMArray
		END;

	CommandProgress (fCmdNumber);

	CatchFailures (fi, CleanUp1);

	FOR band := 0 TO bands - 1 DO
		BEGIN
		MoveHands (TRUE);
		StartTask (1 / (bands - band));
		DoCalculation (band);
		FinishTask
		END;

	Success (fi);

	CleanUp1 (0, 0);

	IF fDstDocument = NIL THEN
		BEGIN

		fCanUndo := FALSE;

		fDstDocument := TImageDocument
				(gApplication.DoMakeDocument (cCalculation));

		CatchFailures (fi, CleanUp2);

		fDstDocument.fRows := fDoc.fRows;
		fDstDocument.fCols := fDoc.fCols;

		fDstDocument.fChannels := bands;

		FOR band := 0 TO bands - 1 DO
			BEGIN
			fDstDocument.fData [band] := fBuffer [band];
			fBuffer 		   [band] := NIL
			END;

		fDstDocument.DefaultMode;

		fDstDocument.fStyleInfo := fDoc.fStyleInfo;

		fDstDocument.UntitledName (s);
		fDstDocument.SetTitle (s);

		fDstDocument.DoMakeViews (kForDisplay);
		fDstDocument.DoMakeWindows;

		gApplication.AddDocument (fDstDocument);

		fDstDocument.ShowWindows;

		Success (fi)

		END

	ELSE
		BEGIN

		dstView := NIL;

		fDstDocument.fViewList.Each (FindView);

		IF dstView = NIL THEN
			IF fDstDocument = fDoc THEN
				dstView := fView
			ELSE
				dstView := TImageView (fDstDocument.fViewList.First);

		IF fDstChannel = kMaskChannel THEN
			BEGIN

			fCanUndo := FALSE;

			fCausesChange := FALSE;

			SelectAlphaChannel (fDstDocument, fBuffer [0])

			END

		ELSE IF fDstChannel = fDstDocument.fChannels THEN
			BEGIN

			fCanUndo := FALSE;

			dstView.fChannel := fDstChannel;

			fDstDocument.fChannels := fDstChannel + 1;

			fDstDocument.fData [fDstChannel] := fBuffer [0];
			fBuffer [0] := NIL;

			IF fDstDocument.fMode = MonochromeMode THEN
				BEGIN
				fDstDocument.fMode := MultichannelMode;
				fDstDocument.fViewList.Each (DoUpdateTitle)
				END
			ELSE
				dstView.UpdateWindowTitle;

			fDstDocument.UpdateStatus;

			dstView.ReDither (TRUE)

			END

		ELSE
			BEGIN

			IF dstView.fChannel <> fDstChannel THEN
				BEGIN
				dstView.fChannel := fDstChannel;
				dstView.UpdateWindowTitle;
				dstView.ReDither (TRUE)
				END;

			UndoIt

			END;

		SelectWindow (dstView.fWindow.fWmgrWindow)

		END;

	fChangedDocument := fDstDocument

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TCalculateCommand.UndoIt; OVERRIDE;

	VAR
		channel: INTEGER;
		saveArray: TVMArray;

	PROCEDURE RedrawView (view: TImageView);
		BEGIN

		IF (view.fChannel = fDstChannel) OR
		   (view.fChannel = kRGBChannels) AND (fDstChannel <= 2) OR
		   (view.fChannel <= 2) AND (fDstChannel = kRGBChannels) THEN

			view.fFrame.ForceRedraw

		END;

	BEGIN

	fDstDocument.KillEffect (TRUE);
	fDstDocument.FreeFloat;

	IF fDstChannel = kRGBChannels THEN
		FOR channel := 0 TO 2 DO
			BEGIN
			saveArray					 := fDstDocument.fData [channel];
			fDstDocument.fData [channel] := fBuffer 		   [channel];
			fBuffer 		   [channel] := saveArray
			END
	ELSE
		BEGIN
		saveArray						 := fDstDocument.fData [fDstChannel];
		fDstDocument.fData [fDstChannel] := fBuffer 		   [0		   ];
		fBuffer 		   [0		   ] := saveArray
		END;

	fDstDocument.fViewList.Each (RedrawView)

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TCalculateCommand.RedoIt; OVERRIDE;

	BEGIN
	UndoIt
	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TDuplicateChannel.GetOptions; OVERRIDE;

	CONST
		kDialogID	= 1040;
		kHookItem	= 3;
		kSrcItem	= 4;
		kInvertItem = 8;
		kDstItem	= 9;

	VAR
		fi: FailInfo;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		invertBox: TCheckBox;
		srcSelector: TChannelSelector;
		dstSelector: TChannelSelector;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	NEW (srcSelector);
	FailNil (srcSelector);

	srcSelector.IChannelSelector (aBWDialog, kSrcItem, fView, FALSE,
								  TRUE, FALSE, fView.fChannel = kRGBChannels,
								  NIL, NIL, NIL);

	NEW (dstSelector);
	FailNil (dstSelector);

	dstSelector.IChannelSelector (aBWDialog, kDstItem, fView, TRUE,
								  TRUE, FALSE, FALSE,
								  srcSelector, NIL, NIL);

	invertBox := aBWDialog.DefineCheckBox (kInvertItem, FALSE);

		REPEAT

		aBWDialog.TalkToUser (hitItem, StdItemHandling);

		IF hitItem <> ok THEN Failure (0, 0);

		fInvert := invertBox.fChecked;

		fSrcDocument := srcSelector.fPickedDocument;
		fSrcChannel  := srcSelector.fPickedChannel;

		fDstDocument := dstSelector.fPickedDocument;
		fDstChannel  := dstSelector.fPickedChannel

		UNTIL ValidDestination (fSrcChannel = kRGBChannels);

	Success (fi);

	CleanUp (0, 0);

	IF NOT fInvert AND (fSrcDocument = fDstDocument) AND
					   (fSrcChannel  = fDstChannel ) THEN
		Failure (0, 0)

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TDuplicateChannel.DoCalculation (band: INTEGER); OVERRIDE;

	BEGIN

	CopyToBuffer (fSrcDocument, fSrcChannel, band);

	IF fInvert THEN
		fBuffer [band] . MapBytes (gInvertLUT)

	END;

{*****************************************************************************}

{$S ADoCalculate}

FUNCTION DoDuplicateCommand (view: TImageView): TCommand;

	VAR
		aDuplicateChannel: TDuplicateChannel;

	BEGIN

	NEW (aDuplicateChannel);
	FailNil (aDuplicateChannel);

	aDuplicateChannel.ICalculateCommand (view);

	DoDuplicateCommand := aDuplicateChannel

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TConstantChannel.GetOptions; OVERRIDE;

	CONST
		kDialogID  = 1041;
		kHookItem  = 3;
		kDstItem   = 4;
		kConstItem = 8;

	VAR
		fi: FailInfo;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		constantText: TFixedText;
		dstSelector: TChannelSelector;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	NEW (dstSelector);
	FailNil (dstSelector);

	dstSelector.IChannelSelector (aBWDialog, kDstItem, fView, TRUE,
								  FALSE, FALSE, FALSE,
								  NIL, NIL, NIL);

	constantText := aBWDialog.DefineFixedText
					(kConstItem, 0, FALSE, TRUE, 0, 255);

	constantText.StuffValue (gLastConstant);

	aBWDialog.SetEditSelection (kConstItem);

	aBWDialog.TalkToUser (hitItem, StdItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	fConstant := constantText.fValue;

	gLastConstant := fConstant;

	fDstDocument := dstSelector.fPickedDocument;
	fDstChannel  := dstSelector.fPickedChannel;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TConstantChannel.DoCalculation (band: INTEGER); OVERRIDE;

	BEGIN
	fBuffer [band] . SetBytes (fConstant)
	END;

{*****************************************************************************}

{$S ADoCalculate}

FUNCTION DoConstantCommand (view: TImageView): TCommand;

	VAR
		aConstantChannel: TConstantChannel;

	BEGIN

	NEW (aConstantChannel);
	FailNil (aConstantChannel);

	aConstantChannel.ICalculateCommand (view);

	DoConstantCommand := aConstantChannel

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TCompositeChannels.GetOptions; OVERRIDE;

	CONST
		kDialogID = 1042;
		kHookItem = 3;
		kForeItem = 4;
		kMaskItem = 8;
		kBackItem = 12;
		kDstItem  = 16;

	VAR
		fi: FailInfo;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		dstSelector: TChannelSelector;
		foreSelector: TChannelSelector;
		maskSelector: TChannelSelector;
		backSelector: TChannelSelector;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	NEW (foreSelector);
	FailNil (foreSelector);

	foreSelector.IChannelSelector (aBWDialog, kForeItem, fView, FALSE,
								   FALSE, FALSE, fDoc.fMode = RGBColorMode,
								   NIL, NIL, NIL);

	NEW (maskSelector);
	FailNil (maskSelector);

	maskSelector.IChannelSelector (aBWDialog, kMaskItem, fView, FALSE,
								   TRUE, TRUE, FALSE,
								   NIL, NIL, NIL);

	NEW (backSelector);
	FailNil (backSelector);

	backSelector.IChannelSelector (aBWDialog, kBackItem, fView, FALSE,
								   FALSE, FALSE, FALSE,
								   foreSelector, maskSelector, NIL);

	NEW (dstSelector);
	FailNil (dstSelector);

	dstSelector.IChannelSelector (aBWDialog, kDstItem, fView, TRUE,
								  FALSE, FALSE, FALSE,
								  foreSelector, maskSelector, backSelector);

		REPEAT

		aBWDialog.TalkToUser (hitItem, StdItemHandling);

		IF hitItem <> ok THEN Failure (0, 0);

		fForeDocument := foreSelector.fPickedDocument;
		fForeChannel  := foreSelector.fPickedChannel;

		fMaskDocument := maskSelector.fPickedDocument;
		fMaskChannel  := maskSelector.fPickedChannel;

		fBackDocument := backSelector.fPickedDocument;
		fBackChannel  := backSelector.fPickedChannel;

		fDstDocument := dstSelector.fPickedDocument;
		fDstChannel  := dstSelector.fPickedChannel

		UNTIL ValidDestination ((fForeChannel = kRGBChannels) OR
								(fMaskChannel = kRGBChannels) OR
								(fBackChannel = kRGBChannels));

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TCompositeChannels.DoCalculation (band: INTEGER); OVERRIDE;

	VAR
		fi: FailInfo;
		row: INTEGER;
		forePtr: Ptr;
		backPtr: Ptr;
		foreArray: TVMArray;
		backArray: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		IF forePtr <> NIL THEN foreArray.DoneWithPtr;
		IF backPtr <> NIL THEN backArray.DoneWithPtr;

		foreArray.Flush;
		backArray.Flush

		END;

	BEGIN

	CopyToBuffer (fMaskDocument, fMaskChannel, band);

	foreArray := BandArray (fForeDocument, fForeChannel, band);
	backArray := BandArray (fBackDocument, fBackChannel, band);

	foreArray.Preload (3);
	backArray.Preload (3);

	forePtr := NIL;
	backPtr := NIL;

	CatchFailures (fi, CleanUp);

	FOR row := 0 TO fDoc.fRows - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row, fDoc.fRows);

		forePtr := foreArray.NeedPtr (row, row, FALSE);
		backPtr := backArray.NeedPtr (row, row, FALSE);

		DoCompositeBytes (forePtr,
						  backPtr,
						  fBuffer [band] . NeedPtr (row, row, TRUE),
						  fDoc.fCols);

		fBuffer [band] . DoneWithPtr;

		foreArray.DoneWithPtr;
		backArray.DoneWithPtr;

		forePtr := NIL;
		backPtr := NIL

		END;

	fBuffer [band] . Flush;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoCalculate}

FUNCTION DoCompositeCommand (view: TImageView): TCommand;

	VAR
		aCompositeChannels: TCompositeChannels;

	BEGIN

	NEW (aCompositeChannels);
	FailNil (aCompositeChannels);

	aCompositeChannels.ICalculateCommand (view);

	DoCompositeCommand := aCompositeChannels

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TBinaryCalculation.PrepareCalculation;

	BEGIN
	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TBinaryCalculation.DoBinaryCalculation (srcPtr: Ptr;
												  dstPtr: Ptr;
												  count: INTEGER);

	BEGIN

	{$IFC qDebug}
	ProgramBreak ('Need to override DoBinaryCalculation')
	{$ENDC}

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TBinaryCalculation.DoCalculation (band: INTEGER); OVERRIDE;

	VAR
		srcPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		srcArray: TVMArray;
		dstArray: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF srcPtr <> NIL THEN srcArray.DoneWithPtr;
		srcArray.Flush
		END;

	BEGIN

	CopyToBuffer (fSrc1Document, fSrc1Channel, band);

	PrepareCalculation;

	srcArray := BandArray (fSrc2Document, fSrc2Channel, band);

	srcArray.Preload (2);

	srcPtr := NIL;

	CatchFailures (fi, CleanUp);

	dstArray := fBuffer [band];

	FOR row := 0 TO fDoc.fRows - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (0, fDoc.fRows);

		srcPtr := srcArray.NeedPtr (row, row, FALSE);

		DoBinaryCalculation (srcPtr,
							 dstArray.NeedPtr (row, row, TRUE),
							 fDoc.fCols);

		dstArray.DoneWithPtr;
		srcArray.DoneWithPtr;

		srcPtr := NIL

		END;

	dstArray.Flush;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TBlendChannels.GetOptions; OVERRIDE;

	CONST
		kDialogID	 = 1043;
		kHookItem	 = 3;
		kSrc1Item	 = 4;
		kSrc2Item	 = 8;
		kDstItem	 = 12;
		kPercentItem = 16;

	VAR
		fi: FailInfo;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		percentText: TFixedText;
		dstSelector: TChannelSelector;
		src1Selector: TChannelSelector;
		src2Selector: TChannelSelector;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	NEW (src1Selector);
	FailNil (src1Selector);

	src1Selector.IChannelSelector (aBWDialog, kSrc1Item, fView, FALSE,
								   FALSE, FALSE, fView.fChannel = kRGBChannels,
								   NIL, NIL, NIL);

	NEW (src2Selector);
	FailNil (src2Selector);

	src2Selector.IChannelSelector (aBWDialog, kSrc2Item, fView, FALSE,
								   FALSE, FALSE, FALSE,
								   src1Selector, NIL, NIL);

	NEW (dstSelector);
	FailNil (dstSelector);

	dstSelector.IChannelSelector (aBWDialog, kDstItem, fView, TRUE,
								  FALSE, FALSE, FALSE,
								  src1Selector, src2Selector, NIL);

	percentText := aBWDialog.DefineFixedText
				   (kPercentItem, 0, FALSE, TRUE, 1, 99);

	percentText.StuffValue (gLastBlend);

	aBWDialog.SetEditSelection (kPercentItem);

		REPEAT

		aBWDialog.TalkToUser (hitItem, StdItemHandling);

		IF hitItem <> ok THEN Failure (0, 0);

		fSrc1Document := src1Selector.fPickedDocument;
		fSrc1Channel  := src1Selector.fPickedChannel;

		fSrc2Document := src2Selector.fPickedDocument;
		fSrc2Channel  := src2Selector.fPickedChannel;

		fDstDocument := dstSelector.fPickedDocument;
		fDstChannel  := dstSelector.fPickedChannel;

		fPercent := percentText.fValue

		UNTIL ValidDestination ((fSrc1Channel = kRGBChannels) OR
								(fSrc2Channel = kRGBChannels));

	gLastBlend := fPercent;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TBlendChannels.PrepareCalculation; OVERRIDE;

	VAR
		gray: INTEGER;
		limit: INTEGER;

	BEGIN

	limit := (fPercent * 255 + 50) DIV 100;

	FOR gray := 0 TO 255 DO
		fMap1 [gray] := CHR ((gray * ORD4 (limit) + 127) DIV 255);

	limit := 255 - limit;

	FOR gray := 0 TO 255 DO
		fMap2 [gray] := CHR ((gray * ORD4 (limit) + 127) DIV 255)

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TBlendChannels.DoBinaryCalculation (srcPtr: Ptr;
											  dstPtr: Ptr;
											  count: INTEGER); OVERRIDE;

	BEGIN
	DoBlendBytes (srcPtr, dstPtr, count, fMap1, fMap2)
	END;

{*****************************************************************************}

{$S ADoCalculate}

FUNCTION DoBlendCommand (view: TImageView): TCommand;

	VAR
		aBlendChannels: TBlendChannels;

	BEGIN

	NEW (aBlendChannels);
	FailNil (aBlendChannels);

	aBlendChannels.ICalculateCommand (view);

	DoBlendCommand := aBlendChannels

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TSOffsetBinary.ISOffsetBinary (view: TImageView; index: INTEGER);

	BEGIN

	fIndex := index;

	ICalculateCommand (view)

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TSOffsetBinary.GetOptions; OVERRIDE;

	CONST
		kDialogID	= 1044;
		kHookItem	= 3;
		kSrc1Item	= 4;
		kSrc2Item	= 8;
		kDstItem	= 12;
		kScaleItem	= 16;
		kOffsetItem = 17;

	VAR
		s: Str255;
		fi: FailInfo;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		scaleText: TFixedText;
		offsetText: TFixedText;
		dstSelector: TChannelSelector;
		src1Selector: TChannelSelector;
		src2Selector: TChannelSelector;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	GetIndString (s, kDialogID, fIndex);

	ParamText (s, '', '', '');

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	NEW (src1Selector);
	FailNil (src1Selector);

	src1Selector.IChannelSelector (aBWDialog, kSrc1Item, fView, FALSE,
								   FALSE, FALSE, FALSE,
								   NIL, NIL, NIL);

	NEW (src2Selector);
	FailNil (src2Selector);

	src2Selector.IChannelSelector (aBWDialog, kSrc2Item, fView, FALSE,
								   FALSE, FALSE, FALSE,
								   src1Selector, NIL, NIL);

	NEW (dstSelector);
	FailNil (dstSelector);

	dstSelector.IChannelSelector (aBWDialog, kDstItem, fView, TRUE,
								  FALSE, FALSE, FALSE,
								  src1Selector, src2Selector, NIL);

	scaleText := aBWDialog.DefineFixedText
				 (kScaleItem, 3, FALSE, TRUE, 1000, 2000);

	scaleText.StuffValue (gLastScale [fIndex]);

	offsetText := aBWDialog.DefineFixedText
				  (kOffsetItem, 0, TRUE, TRUE, -255, 255);

	offsetText.StuffValue (gLastOffset [fIndex]);

	aBWDialog.SetEditSelection (kScaleItem);

		REPEAT

		aBWDialog.TalkToUser (hitItem, StdItemHandling);

		IF hitItem <> ok THEN Failure (0, 0);

		fSrc1Document := src1Selector.fPickedDocument;
		fSrc1Channel  := src1Selector.fPickedChannel;

		fSrc2Document := src2Selector.fPickedDocument;
		fSrc2Channel  := src2Selector.fPickedChannel;

		fDstDocument := dstSelector.fPickedDocument;
		fDstChannel  := dstSelector.fPickedChannel;

		fScale := scaleText.fValue;

		fOffset := offsetText.fValue

		UNTIL ValidDestination ((fSrc1Channel = kRGBChannels) OR
								(fSrc2Channel = kRGBChannels));

	gLastScale	[fIndex] := fScale;
	gLastOffset [fIndex] := fOffset;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TAddChannels.DoBinaryCalculation (srcPtr: Ptr;
											dstPtr: Ptr;
											count: INTEGER); OVERRIDE;

	BEGIN
	DoAddBytes (srcPtr, dstPtr, count, fScale, fOffset)
	END;

{*****************************************************************************}

{$S ADoCalculate}

FUNCTION DoAddCommand (view: TImageView): TCommand;

	CONST
		kAddIndex = 1;

	VAR
		aAddChannels: TAddChannels;

	BEGIN

	NEW (aAddChannels);
	FailNil (aAddChannels);

	aAddChannels.ISOffsetBinary (view, kAddIndex);

	DoAddCommand := aAddChannels

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TSubtractChannels.DoBinaryCalculation (srcPtr: Ptr;
												 dstPtr: Ptr;
												 count: INTEGER); OVERRIDE;

	BEGIN
	DoSubtractBytes (srcPtr, dstPtr, count, fScale, fOffset)
	END;

{*****************************************************************************}

{$S ADoCalculate}

FUNCTION DoSubtractCommand (view: TImageView): TCommand;

	CONST
		kSubtractIndex = 2;

	VAR
		aSubtractChannels: TSubtractChannels;

	BEGIN

	NEW (aSubtractChannels);
	FailNil (aSubtractChannels);

	aSubtractChannels.ISOffsetBinary (view, kSubtractIndex);

	DoSubtractCommand := aSubtractChannels

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TSimpleBinary.ISimpleBinary (view: TImageView; index: INTEGER);

	BEGIN

	fIndex := index;

	ICalculateCommand (view)

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TSimpleBinary.GetOptions; OVERRIDE;

	CONST
		kDialogID = 1045;
		kHookItem = 3;
		kSrc1Item = 4;
		kSrc2Item = 8;
		kDstItem  = 12;

	VAR
		s: Str255;
		fi: FailInfo;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		dstSelector: TChannelSelector;
		src1Selector: TChannelSelector;
		src2Selector: TChannelSelector;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	GetIndString (s, kDialogID, fIndex);

	ParamText (s, '', '', '');

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	NEW (src1Selector);
	FailNil (src1Selector);

	src1Selector.IChannelSelector (aBWDialog, kSrc1Item, fView, FALSE,
								   FALSE, FALSE, FALSE,
								   NIL, NIL, NIL);

	NEW (src2Selector);
	FailNil (src2Selector);

	src2Selector.IChannelSelector (aBWDialog, kSrc2Item, fView, FALSE,
								   FALSE, FALSE, FALSE,
								   src1Selector, NIL, NIL);

	NEW (dstSelector);
	FailNil (dstSelector);

	dstSelector.IChannelSelector (aBWDialog, kDstItem, fView, TRUE,
								  FALSE, FALSE, FALSE,
								  src1Selector, src2Selector, NIL);

		REPEAT

		aBWDialog.TalkToUser (hitItem, StdItemHandling);

		IF hitItem <> ok THEN Failure (0, 0);

		fSrc1Document := src1Selector.fPickedDocument;
		fSrc1Channel  := src1Selector.fPickedChannel;

		fSrc2Document := src2Selector.fPickedDocument;
		fSrc2Channel  := src2Selector.fPickedChannel;

		fDstDocument := dstSelector.fPickedDocument;
		fDstChannel  := dstSelector.fPickedChannel

		UNTIL ValidDestination ((fSrc1Channel = kRGBChannels) OR
								(fSrc2Channel = kRGBChannels));

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TMultiplyChannels.DoBinaryCalculation (srcPtr: Ptr;
												 dstPtr: Ptr;
												 count: INTEGER); OVERRIDE;

	BEGIN
	DoMultiplyBytes (srcPtr, dstPtr, count)
	END;

{*****************************************************************************}

{$S ADoCalculate}

FUNCTION DoMultiplyCommand (view: TImageView): TCommand;

	CONST
		kMultiplyIndex = 2;

	VAR
		aMultiplyChannels: TMultiplyChannels;

	BEGIN

	NEW (aMultiplyChannels);
	FailNil (aMultiplyChannels);

	aMultiplyChannels.ISimpleBinary (view, kMultiplyIndex);

	DoMultiplyCommand := aMultiplyChannels

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TLighterChannel.DoBinaryCalculation (srcPtr: Ptr;
											   dstPtr: Ptr;
											   count: INTEGER); OVERRIDE;

	BEGIN
	DoMaxBytes (srcPtr, dstPtr, dstPtr, count)
	END;

{*****************************************************************************}

{$S ADoCalculate}

FUNCTION DoLighterCommand (view: TImageView): TCommand;

	CONST
		kLighterIndex = 3;

	VAR
		aLighterChannel: TLighterChannel;

	BEGIN

	NEW (aLighterChannel);
	FailNil (aLighterChannel);

	aLighterChannel.ISimpleBinary (view, kLighterIndex);

	DoLighterCommand := aLighterChannel

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TDarkerChannel.DoBinaryCalculation (srcPtr: Ptr;
											  dstPtr: Ptr;
											  count: INTEGER); OVERRIDE;

	BEGIN
	DoMinBytes (srcPtr, dstPtr, dstPtr, count)
	END;

{*****************************************************************************}

{$S ADoCalculate}

FUNCTION DoDarkerCommand (view: TImageView): TCommand;

	CONST
		kDarkerIndex = 4;

	VAR
		aDarkerChannel: TDarkerChannel;

	BEGIN

	NEW (aDarkerChannel);
	FailNil (aDarkerChannel);

	aDarkerChannel.ISimpleBinary (view, kDarkerIndex);

	DoDarkerCommand := aDarkerChannel

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TDiffOfChannels.DoBinaryCalculation (srcPtr: Ptr;
											   dstPtr: Ptr;
											   count: INTEGER); OVERRIDE;

	BEGIN
	DoDiffBytes (srcPtr, dstPtr, count)
	END;

{*****************************************************************************}

{$S ADoCalculate}

FUNCTION DoDifferenceCommand (view: TImageView): TCommand;

	CONST
		kDiffOfIndex = 1;

	VAR
		aDiffOfChannels: TDiffOfChannels;

	BEGIN

	NEW (aDiffOfChannels);
	FailNil (aDiffOfChannels);

	aDiffOfChannels.ISimpleBinary (view, kDiffOfIndex);

	DoDifferenceCommand := aDiffOfChannels

	END;

{*****************************************************************************}

{$S ADoCalculate}

PROCEDURE TScreenChannels.DoBinaryCalculation
		(srcPtr: Ptr; dstPtr: Ptr; count: INTEGER); OVERRIDE;

	BEGIN
	DoScreenBytes (srcPtr, dstPtr, count)
	END;

{*****************************************************************************}

{$S ADoCalculate}

FUNCTION DoScreenCommand (view: TImageView): TCommand;

	CONST
		kScreenIndex = 5;

	VAR
		aScreenChannels: TScreenChannels;

	BEGIN

	NEW (aScreenChannels);
	FailNil (aScreenChannels);

	aScreenChannels.ISimpleBinary (view, kScreenIndex);

	DoScreenCommand := aScreenChannels

	END;

{*****************************************************************************}

END.

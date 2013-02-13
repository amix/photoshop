{Photoshop version 1.0.1, file: UPrint.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UPrint;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	QuickDraw32Bit, PrintTraps, UPrinting, UDialog,
	UBWDialog, UPostScript, UScreen, USeparation, UTransfer, UProgress;

TYPE

	TImageStyleCommand = OBJECT (TPrintStyleChangeCommand)

		fDoc: TImageDocument;

		fOldStyleInfo: TStyleInfo;
		fNewStyleInfo: TStyleInfo;

		PROCEDURE TImageStyleCommand.ImageStyleCommand
				(itsPrintHandler: TStdPrintHandler);

		PROCEDURE TImageStyleCommand.UndoIt; OVERRIDE;

		PROCEDURE TImageStyleCommand.RedoIt; OVERRIDE;

		END;

	TImagePrintHandler = OBJECT (TStdPrintHandler)

		fColor: BOOLEAN;
		fCorrect: BOOLEAN;
		fSelection: BOOLEAN;
		fAllChannels: BOOLEAN;
		fPrintUsingASCII: BOOLEAN;

		fAllowColor: BOOLEAN;
		fAllowCorrect: BOOLEAN;

		fInputArea: Rect;
		fOutputArea: Rect;
		fExpandedArea: Rect;

		fRegMarks: TRegMarkList;

		PROCEDURE TImagePrintHandler.IImagePrintHandler (view: TImageView);

		FUNCTION TImagePrintHandler.IsPostScript: BOOLEAN;

		PROCEDURE TImagePrintHandler.DoStyleItem
				(theDialog: DialogPtr; itemNo: INTEGER);

		PROCEDURE TImagePrintHandler.AddStyleItems
				(theDialog: DialogPtr);

		FUNCTION TImagePrintHandler.DoPageSetupDialog: BOOLEAN;

		FUNCTION TImagePrintHandler.PosePageSetupDialog
				(VAR cancelled: BOOLEAN): TCommand; OVERRIDE;

		PROCEDURE TImagePrintHandler.DoJobItem
				(theDialog: DialogPtr; itemNo: INTEGER);

		PROCEDURE TImagePrintHandler.AddJobItems
				(theDialog: DialogPtr);

		FUNCTION TImagePrintHandler.DoJobDialog: BOOLEAN;

		PROCEDURE TImagePrintHandler.PosePrintDialog; OVERRIDE;

		PROCEDURE TImagePrintHandler.ShowDocBeingPrinted
					(entering: BOOLEAN); OVERRIDE;

		PROCEDURE TImagePrintHandler.PoseJobDialog
				(VAR proceed: BOOLEAN); OVERRIDE;

		FUNCTION TImagePrintHandler.MaxPageNumber: INTEGER; OVERRIDE;

		PROCEDURE TImagePrintHandler.SetPage (aPageNumber: INTEGER); OVERRIDE;

		FUNCTION TImagePrintHandler.OneSubJob
				(subjobFirstPage, subjobLastPage: INTEGER;
				 justSpool: BOOLEAN;
				 partialJob: BOOLEAN;
				 VAR ranOutOfSpace: BOOLEAN;
				 VAR lastPageTried: INTEGER;
				 VAR proceed: BOOLEAN): TCommand; OVERRIDE;

		PROCEDURE TImagePrintHandler.FocusOnInterior
				(aPageNumber: INTEGER); OVERRIDE;

		FUNCTION TImagePrintHandler.WarnIfTooLarge: BOOLEAN;

		FUNCTION TImagePrintHandler.WarnIfTooFine: BOOLEAN;

		PROCEDURE TImagePrintHandler.PositionStuffOnPage;

		PROCEDURE TImagePrintHandler.PrintUsingPostScript
				(doc: TImageDocument; channel: INTEGER);

		FUNCTION TImagePrintHandler.GetPortDepth: INTEGER;

		PROCEDURE TImagePrintHandler.PrintUsingQuickDraw
				(doc: TImageDocument; channel: INTEGER);

		PROCEDURE TImagePrintHandler.PrintPostScriptMarks
				(doc: TImageDocument; channel: INTEGER);

		PROCEDURE TImagePrintHandler.PrintQuickDrawMarks
				(doc: TImageDocument; channel: INTEGER);

		FUNCTION TImagePrintHandler.CorrectPrintingColors
				(doc: TImageDocument; rgb: BOOLEAN): TImageDocument;

		PROCEDURE TImagePrintHandler.DrawPageInterior
				(aPageNumber: INTEGER); OVERRIDE;

		END;

PROCEDURE InitImagePrinting;

PROCEDURE GetPrintRects (doc: TImageDocument;
						 bounds: Rect;
						 VAR thePaper: Rect;
						 VAR theInk: Rect;
						 VAR theImage: Rect);

PROCEDURE AddImagePrintHander (view: TImageView);

IMPLEMENTATION

CONST
	kCaptionLines = 6;

TYPE
	TCaption = RECORD
			   center: BOOLEAN;
			   line: ARRAY [1..kCaptionLines] OF Str255
			   END;

VAR
	gColorCorrect: BOOLEAN;
	gPrintItemBase: INTEGER;
	gPrintItemProc: ProcPtr;
	gPrintStlDialog: TPPrDlg;
	gPrintJobDialog: TPPrDlg;
	gColorPostScript: BOOLEAN;
	gPrintUsingASCII: BOOLEAN;
	gImagePrintHandler: TImagePrintHandler;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitImagePrinting;

	BEGIN
	gColorCorrect	 := FALSE;
	gColorPostScript := FALSE;
	gPrintUsingASCII := FALSE
	END;

{*****************************************************************************}

{$S APageSetup}

PROCEDURE SetBorder (VAR border: FixedScaled);

	CONST
		kDialogID	= 1250;
		kHookItem	= 3;
		kBorderItem = 4;
		kUnitsItem	= 5;
		kUnitsMenu	= 1001;

	VAR
		fi: FailInfo;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		aUnitSelector: TUnitSelector;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	aUnitSelector := aBWDialog.DefineUnitSelector
					 (kUnitsItem, kBorderItem, 1, TRUE,
					  kUnitsMenu, border.scale);

	aUnitSelector.DefineUnit (1 	, 0, 3, 0,	150);
	aUnitSelector.DefineUnit (1/25.4, 0, 2, 0,	350);
	aUnitSelector.DefineUnit (1/72	, 0, 2, 0, 1000);

	IF border.value <> 0 THEN
		aUnitSelector.StuffFixed (0, border.value);

	aBWDialog.SetEditSelection (kBorderItem);

	aBWDialog.TalkToUser (hitItem, StdItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	border.value := aUnitSelector.GetFixed (0);
	border.scale := aUnitSelector.fPick;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S APageSetup}

PROCEDURE SetImageResolution (VAR resolution: FixedScaled;
							  VAR widthUnit: INTEGER;
							  VAR heightUnit: INTEGER;
							  rows: INTEGER;
							  cols: INTEGER);

	CONST
		kDialogID	= 1210;
		kHookItem	= 3;
		kWidthItem	= 4;
		kHeightItem = 6;
		kResItem	= 8;

	VAR
		fi: FailInfo;
		item: INTEGER;
		master: INTEGER;
		aBWDialog: TBWDialog;
		resUnit: TUnitSelector;
		size: ARRAY [0..1] OF INTEGER;
		sizeUnit: ARRAY [0..1] OF TUnitSelector;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	PROCEDURE Propogate (item: INTEGER);

		VAR
			x: EXTENDED;
			dpi: EXTENDED;
			side: INTEGER;

		BEGIN

		master := item;

			CASE item OF

			kResItem:
				IF resUnit . fEditItem [0] . ParseValue THEN
					BEGIN

					dpi := resUnit.GetFloat (0);

					sizeUnit [0] . StuffFloat (0, size [0] / dpi);
					sizeUnit [1] . StuffFloat (0, size [1] / dpi)

					END;

			kWidthItem,
			kHeightItem:
				BEGIN

				side := ORD (item = kHeightItem);

				IF sizeUnit [side] . fEditItem [0] . ParseValue THEN
					BEGIN

					x := sizeUnit [side] . GetFloat (0);

					IF x <= 0 THEN
						dpi := 32000
					ELSE
						dpi := size [side] / x;

					resUnit.StuffFloat (0, dpi);

					IF resUnit . fEditItem [0] . ParseValue THEN;

					dpi := resUnit.GetFloat (0);

					sizeUnit [1 - side] . StuffFloat (0, size [1 - side] / dpi)

					END

				END

			END

		END;

	PROCEDURE MyItemHandling (anItem: INTEGER; VAR done: BOOLEAN);

		BEGIN

		StdItemHandling (anItem, done);

			CASE anItem OF

			kResItem,
			kWidthItem,
			kHeightItem:
				Propogate (anItem);

			kResItem + 1,
			kWidthItem + 1,
			kHeightItem + 1:
				Propogate (master)

			END

		END;

	BEGIN

	size [0] := cols;
	size [1] := rows;

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	resUnit := aBWDialog.DefineResUnit (kResItem, resolution.scale,
										Max (rows, cols));

	resUnit.StuffFixed (0, resolution.value);

	sizeUnit [0] := aBWDialog.DefineSizeUnit (kWidthItem, widthUnit,
											  FALSE, FALSE, TRUE,
											  FALSE, TRUE);

	sizeUnit [1] := aBWDialog.DefineSizeUnit (kHeightItem, heightUnit,
											  FALSE, FALSE, FALSE,
											  FALSE, TRUE);

	Propogate (kResItem);

	aBWDialog.SetEditSelection (kResItem);

	aBWDialog.TalkToUser (item, MyItemHandling);

	IF item <> ok THEN Failure (0, 0);

	resolution.value := resUnit.GetFixed (0);
	resolution.scale := resUnit.fPick;

	widthUnit  := sizeUnit [0] . fPick;
	heightUnit := sizeUnit [1] . fPick;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S APageSetup}

PROCEDURE SetCaption (VAR caption: Str255);

	CONST
		kDialogID		= 1240;
		kHookItem		= 3;
		kCaptionItem	= 4;
		kTooManyCharsID = 919;

	VAR
		s: Str255;
		fi: FailInfo;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		captionHandler: TKeyHandler;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	aBWDialog.fAllowReturn := TRUE;

	CatchFailures (fi, CleanUp);

	NEW (captionHandler);
	FailNil (captionHandler);

	captionHandler.IKeyHandler (kCaptionItem, aBWDialog);

	captionHandler.StuffString (caption);

	aBWDialog.SetEditSelection (kCaptionItem);

		REPEAT

		aBWDialog.TalkToUser (hitItem, StdItemHandling);

		IF hitItem <> ok THEN Failure (0, 0);

		GetIText (captionHandler.fItemHandle, s);

		IF GetHandleSize (captionHandler.fItemHandle) <= 255 THEN LEAVE;

		captionHandler.StuffString (s);

		aBWDialog.SetEditSelection (kCaptionItem);

		BWNotice (kTooManyCharsID, TRUE)

		UNTIL FALSE;

	WHILE (LENGTH (s) > 0) & (s [LENGTH (s)] IN [' ', CHR (9), CHR (13)]) DO
		DELETE (s, LENGTH (s), 1);

	caption := s;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S APageSetup}

PROCEDURE TImageStyleCommand.ImageStyleCommand
		(itsPrintHandler: TStdPrintHandler);

	BEGIN

	fDoc := TImageDocument (itsPrintHandler.fView.fDocument);

	fOldStyleInfo := fDoc.fStyleInfo;

	IPrintStyleChangeCommand (itsPrintHandler);

	fDoc.InvalRulers

	END;

{*****************************************************************************}

{$S APageSetup}

PROCEDURE TImageStyleCommand.UndoIt; OVERRIDE;

	BEGIN

	fDoc.fStyleInfo := fOldStyleInfo;

	INHERITED UndoIt;

	fDoc.InvalRulers

	END;

{*****************************************************************************}

{$S APageSetup}

PROCEDURE TImageStyleCommand.RedoIt; OVERRIDE;

	BEGIN

	fDoc.fStyleInfo := fNewStyleInfo;

	INHERITED RedoIt;

	fDoc.InvalRulers

	END;

{*****************************************************************************}

{$S APrinting}

FUNCTION AppendDITL (theDialog: DialogPtr; theDITLID: INTEGER): INTEGER;

	{ Based on code from Technical Note #95 }

	TYPE
		DITLItem = RECORD
			itmHndl: Handle;
			itmRect: Rect;
			itmType: SignedByte;
			itmData: ARRAY [0..0] OF SignedByte
			END;

		pDITLItem = ^DITLItem;
		hDITLItem = ^pDITLItem;

		ItemList = RECORD
			dlgMaxIndex: INTEGER;
			DITLItems: ARRAY [0..0] OF DITLItem
			END;

		pItemList = ^ItemList;
		hItemList = ^pItemList;

		IntPtr = ^INTEGER;

	VAR
		i: INTEGER;
		err: OSErr;
		offset: Point;
		maxRect: Rect;
		hDITL: hItemList;
		pItem: pDITLItem;
		hItems: hItemList;
		newItems: INTEGER;
		dataSize: INTEGER;
		firstItem: INTEGER;
		USB: RECORD
			CASE Integer OF
			1:	(SBArray: ARRAY [0..1] OF SignedByte);
			2:	(Int: INTEGER);
			END;

	BEGIN

	maxRect := DialogPeek (theDialog)^.window.port.portRect;
	offset.v := maxRect.bottom;
	offset.h := 0;
	maxRect.bottom := maxRect.bottom - 5;
	maxRect.right := maxRect.right - 5;
	hItems := hItemList (DialogPeek (theDialog)^.items);
	firstItem := hItems^^.dlgMaxIndex + 2;
	hDITL := hItemList (GetResource ('DITL', theDITLID));
	IF hDITL = NIL THEN Failure (1, 0);
	HLock (Handle (hDITL));
	newItems := hDITL^^.dlgMaxIndex + 1;

	pItem := @hDITL^^.DITLItems;
	FOR i := 1 TO newItems DO
		BEGIN
		OffsetRect (pItem^.itmRect, offset.h, offset.v);
		UnionRect (pItem^.itmRect, maxRect, maxRect);

		USB.Int := 0;
		USB.SBArray[1] := pItem^.itmData[0];

		WITH pItem^ DO
			CASE BAND (itmType, $7F) OF

			userItem:
				itmHndl := NIL;

			ctrlItem + btnCtrl,
			ctrlItem + chkCtrl,
			ctrlItem + radCtrl:
				itmHndl := Handle (NewControl (theDialog,
											   itmRect,
											   StringPtr (@itmData [0])^,
											   TRUE,
											   0,0,1,
											   BAND (itmType, $03),
											   0));

			statText,
			editText:
				{$PUSH}
				{$R-}
				err := PtrToHand (@itmData[1], itmHndl, USB.Int);
				{$POP}

			{ Some other types left out because they are never used }

			OTHERWISE
				itmHndl := NIL

			END;

		dataSize := BAND (USB.Int + 1, $FFFE);
		pItem := pDITLItem (ORD4 (pItem) + dataSize + SIZEOF (DITLItem))
		END;

	err := PtrAndHand (@hDITL^^.DITLItems,
					   Handle (hItems),
					   GetHandleSize (Handle (hDITL)));

	hItems^^.dlgMaxIndex := hItems^^.dlgMaxIndex + newItems;
	HUnlock (Handle (hDITL));
	ReleaseResource (Handle (hDITL));
	maxRect.bottom := maxRect.bottom + 5;
	maxRect.right := maxRect.right + 5;
	SizeWindow (theDialog, maxRect.right, maxRect.bottom, TRUE);

	ComputeCentered (offset, maxRect.right, maxRect.bottom, FALSE);
	MoveWindow (theDialog, offset.h, offset.v, FALSE);

	AppendDITL := firstItem

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE DrawGrayLine (dp: DialogPtr; item: INTEGER);

	VAR
		r: Rect;
		h: Handle;
		itemType: INTEGER;

	BEGIN
	GetDItem (dp, item, itemType, h, r);
	FillRect (r, gray)
	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE GrayOutText (dp: DialogPtr; item: INTEGER);

	VAR
		r: Rect;
		h: Handle;
		itemType: INTEGER;

	BEGIN
	GetDItem (dp, item, itemType, h, r);
	PenMode (patBic);
	PenPat (gray);
	PaintRect (r);
	PenNormal
	END;

{*****************************************************************************}

{$S AOpen}

PROCEDURE TImagePrintHandler.IImagePrintHandler (view: TImageView);

	BEGIN

	IStdPrintHandler (view, TRUE);

	fFinderSetup	 := FALSE;
	fFinderJobDialog := TRUE

	END;

{*****************************************************************************}

{$S APrinting}

FUNCTION TImagePrintHandler.IsPostScript: BOOLEAN;

	BEGIN
	
	IF fHPrint <> NIL THEN
		IsPostScript := BSR (THPrint (fHPrint)^^.prStl.wdev, 8) = 3
	ELSE
		IsPostScript := FALSE

	END;

{*****************************************************************************}

{$S APageSetup}

PROCEDURE TImagePrintHandler.DoStyleItem
		(theDialog: DialogPtr; itemNo: INTEGER);

	CONST
		kStyleItemsID	= 1200;
		kResolutionItem = 1;
		kScreenItem 	= 2;
		kScreensItem	= 3;
		kTransferItem	= 4;
		kBorderItem 	= 5;
		kCaptionItem	= 6;
		kLabelItem		= 7;
		kCropMarkItem	= 8;
		kColorBarItem	= 9;
		kRegMarkItem	= 10;
		kNegativeItem	= 11;
		kFlipItem		= 12;
		kGrayLineItem	= 13;
		kWarnSingleID	= 917;
		kWarnPluralID	= 918;

	VAR
		fi: FailInfo;
		flag: BOOLEAN;
		itemH: Handle;
		itemBox: Rect;
		gamma: INTEGER;
		theKeys: KeyMap;
		caption: Str255;
		itemType: INTEGER;
		widthUnit: INTEGER;
		doc: TImageDocument;
		spec: THalftoneSpec;
		border: FixedScaled;
		heightUnit: INTEGER;
		allowCustom: BOOLEAN;
		specs: THalftoneSpecs;
		transfer: TTransferSpec;
		resolution: FixedScaled;
		transfers: TTransferSpecs;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		EXIT (DoStyleItem)
		END;

	PROCEDURE ToggleCheckBox (supported: BOOLEAN);
		BEGIN
		IF NOT supported AND NOT flag THEN
			IF BWAlert (kWarnSingleID, 0, TRUE) <> ok THEN
				EXIT (ToggleCheckBox);
		flag := NOT flag;
		SetCtlValue (ControlHandle (itemH), ORD (flag))
		END;

	BEGIN

	doc := TImageDocument (fView.fDocument);

	GetDItem (theDialog, gPrintItemBase + itemNo, itemType, itemH, itemBox);

		CASE itemNo OF

		kBorderItem:
			BEGIN

			CatchFailures (fi, CleanUp);

			border := doc.fStyleInfo.fBorder;

			SetBorder (border);

			doc.fStyleInfo.fBorder := border;

			Success (fi)

			END;

		kCaptionItem:
			BEGIN

			CatchFailures (fi, CleanUp);

			caption := doc.fStyleInfo.fCaption;

			SetCaption (caption);

			doc.fStyleInfo.fCaption := caption;

			Success (fi)

			END;

		kResolutionItem:
			BEGIN

			CatchFailures (fi, CleanUp);

			resolution := doc.fStyleInfo.fResolution;
			widthUnit  := doc.fStyleInfo.fWidthUnit;
			heightUnit := doc.fStyleInfo.fHeightUnit;

			SetImageResolution (resolution, widthUnit, heightUnit,
								doc.fRows, doc.fCols);

			doc.fStyleInfo.fResolution := resolution;
			doc.fStyleInfo.fWidthUnit  := widthUnit;
			doc.fStyleInfo.fHeightUnit := heightUnit;

			Success (fi)

			END;

		kScreenItem,
		kScreensItem:
			BEGIN

			CatchFailures (fi, CleanUp);

			IF NOT IsPostScript THEN
				IF BWAlert (kWarnPluralID, 0, TRUE) <> ok THEN
					Failure (0, 0);

			GetKeys (theKeys);
			allowCustom := theKeys [kOptionCode];

			IF doc.fMode IN [IndexedColorMode,
							 RGBColorMode,
							 SeparationsCMYK] THEN
				BEGIN
				specs := doc.fStyleInfo.fHalftoneSpecs;
				SetHalftoneScreens (specs, allowCustom);
				doc.fStyleInfo.fHalftoneSpecs := specs
				END
			ELSE
				BEGIN
				spec := doc.fStyleInfo.fHalftoneSpec;
				SetHalftoneScreen (spec, allowCustom);
				doc.fStyleInfo.fHalftoneSpec := spec
				END;

			Success (fi)

			END;

		kTransferItem:
			BEGIN

			CatchFailures (fi, CleanUp);

			IF NOT IsPostScript THEN
				IF BWAlert (kWarnPluralID, 0, TRUE) <> ok THEN
					Failure (0, 0);

			IF doc.fMode IN [IndexedColorMode,
							 RGBColorMode,
							 SeparationsCMYK] THEN
				BEGIN
				transfers := doc.fStyleInfo.fTransferSpecs;
				gamma	  := doc.fStyleInfo.fGamma;
				SetTransferFunctions (transfers, gamma);
				doc.fStyleInfo.fTransferSpecs := transfers;
				doc.fStyleInfo.fGamma		  := gamma
				END
			ELSE
				BEGIN
				transfer := doc.fStyleInfo.fTransferSpec;
				gamma	 := doc.fStyleInfo.fGamma;
				SetTransferFunction (transfer, gamma);
				doc.fStyleInfo.fTransferSpec := transfer;
				doc.fStyleInfo.fGamma		 := gamma
				END;

			Success (fi)

			END;

		kLabelItem:
			BEGIN
			flag := doc.fStyleInfo.fLabel;
			ToggleCheckBox (TRUE);
			doc.fStyleInfo.fLabel := flag
			END;

		kCropMarkItem:
			BEGIN
			flag := doc.fStyleInfo.fCropMarks;
			ToggleCheckBox (TRUE);
			doc.fStyleInfo.fCropMarks := flag
			END;

		kRegMarkItem:
			BEGIN
			flag := doc.fStyleInfo.fRegistrationMarks;
			ToggleCheckBox (TRUE);
			doc.fStyleInfo.fRegistrationMarks := flag
			END;

		kColorBarItem:
			BEGIN
			flag := doc.fStyleInfo.fColorBars;
			ToggleCheckBox (IsPostScript);
			doc.fStyleInfo.fColorBars := flag
			END;

		kNegativeItem:
			BEGIN
			flag := doc.fStyleInfo.fNegative;
			ToggleCheckBox (IsPostScript);
			doc.fStyleInfo.fNegative := flag
			END;

		kFlipItem:
			BEGIN
			flag := doc.fStyleInfo.fFlip;
			ToggleCheckBox (IsPostScript);
			doc.fStyleInfo.fFlip := flag
			END

		END

	END;

{*****************************************************************************}

{$S APageSetup}

PROCEDURE TImagePrintHandler.AddStyleItems (theDialog: DialogPtr);

	CONST
		kStyleItemsID	= 1200;
		kResolutionItem = 1;
		kScreenItem 	= 2;
		kScreensItem	= 3;
		kTransferItem	= 4;
		kBorderItem 	= 5;
		kCaptionItem	= 6;
		kLabelItem		= 7;
		kCropMarkItem	= 8;
		kColorBarItem	= 9;
		kRegMarkItem	= 10;
		kNegativeItem	= 11;
		kFlipItem		= 12;
		kGrayLineItem	= 13;

	VAR
		itemH: Handle;
		itemBox: Rect;
		color: BOOLEAN;
		itemType: INTEGER;
		doc: TImageDocument;

	PROCEDURE SetCheckBox (item: INTEGER; value: BOOLEAN);
		BEGIN
		GetDItem (theDialog, gPrintItemBase + item, itemType, itemH, itemBox);
		SetCtlValue (ControlHandle (itemH), ORD (value))
		END;

	BEGIN

	gPrintItemBase := AppendDITL (theDialog, kStyleItemsID) - 1;

	doc := TImageDocument (fView.fDocument);

	color := doc.fMode IN [IndexedColorMode, RGBColorMode, SeparationsCMYK];

	GetDItem (theDialog, gPrintItemBase + kScreenItem,
			  itemType, itemH, itemBox);

	IF doc.fDepth = 1 THEN
		HiliteControl (ControlHandle (itemH), 255)
	ELSE IF color THEN
		HideControl (ControlHandle (itemH));

	IF NOT color THEN
		BEGIN
		GetDItem (theDialog, gPrintItemBase + kScreensItem,
				  itemType, itemH, itemBox);
		HideControl (ControlHandle (itemH))
		END;

	IF doc.fDepth = 1 THEN
		BEGIN
		GetDItem (theDialog, gPrintItemBase + kTransferItem,
				  itemType, itemH, itemBox);
		HiliteControl (ControlHandle (itemH), 255)
		END;

	SetCheckBox (kLabelItem   , doc.fStyleInfo.fLabel			 );
	SetCheckBox (kCropMarkItem, doc.fStyleInfo.fCropMarks		 );
	SetCheckBox (kColorBarItem, doc.fStyleInfo.fColorBars		 );
	SetCheckBox (kRegMarkItem , doc.fStyleInfo.fRegistrationMarks);
	SetCheckBox (kNegativeItem, doc.fStyleInfo.fNegative		 );
	SetCheckBox (kFlipItem	  , doc.fStyleInfo.fFlip			 );

	GetDItem (theDialog, gPrintItemBase + kGrayLineItem,
			  itemType, itemH, itemBox);

	SetDItem (theDialog, gPrintItemBase + kGrayLineItem,
			  itemType, Handle (@DrawGrayLine), itemBox)

	END;

{*****************************************************************************}

{$S APageSetup}

PROCEDURE MyStyleItemProc (theDialog: DialogPtr; itemNo: INTEGER);

	VAR
		myItem: INTEGER;

	PROCEDURE CallItemHandler (theDialog: DialogPtr;
							   theItem: INTEGER;
							   theProc: ProcPtr); INLINE $205F, $4E90;

	BEGIN

	myItem := itemNo - gPrintItemBase;

	IF (myItem >= 1) AND (myItem <= 12) THEN
		gImagePrintHandler.DoStyleItem (theDialog, myItem)
	ELSE
		CallItemHandler (theDialog, itemNo, gPrintItemProc)

	END;

{*****************************************************************************}

{$S APageSetup}

FUNCTION MyStyleDlgInit (hPrint: THPrint): TPPrDlg;

	BEGIN

	gImagePrintHandler.AddStyleItems (DialogPtr (gPrintStlDialog));

	gPrintItemProc := gPrintStlDialog^.pItemProc;

	gPrintStlDialog^.pItemProc := @MyStyleItemProc;

	MyStyleDlgInit := gPrintStlDialog

	END;

{*****************************************************************************}

{$S APageSetup}

FUNCTION TImagePrintHandler.DoPageSetupDialog: BOOLEAN;

	BEGIN

	SetCursor (arrow);

	gImagePrintHandler := SELF;

	gPrintStlDialog := PrStlInit (THPrint (fHPrint));

	IF PrError <> noErr THEN
		BEGIN
		DoPageSetupDialog := FALSE;
		EXIT (DoPageSetupDialog)
		END;

	DoPageSetupDialog := PrDlgMain (THPrint (fHPrint), @MyStyleDlgInit)

	END;

{*****************************************************************************}

{$S APageSetup}

FUNCTION TImagePrintHandler.PosePageSetupDialog
		(VAR cancelled: BOOLEAN): TCommand; OVERRIDE;

	VAR
		react: BOOLEAN;
		doc: TImageDocument;
		anImageStyleCommand: TImageStyleCommand;

	PROCEDURE CallStyleDialog;
		BEGIN
		react := DoPageSetupDialog
		END;

	BEGIN

	doc := TImageDocument (fView.fDocument);

	New (anImageStyleCommand);
	FailNIL (anImageStyleCommand);

	anImageStyleCommand.ImageStyleCommand (SELF);

	react := FALSE;
	DoInMacPrint (CallStyleDialog);

	IF react THEN
		BEGIN
		BlockMove(fHPrint^,
				  anImageStyleCommand.fNewHPrint^,
				  SIZEOF(TPrint));
		anImageStyleCommand.fNewStyleInfo := doc.fStyleInfo;
		PosePageSetupDialog := anImageStyleCommand;
		END
	ELSE
		BEGIN
		doc.fStyleInfo := anImageStyleCommand.fOldStyleInfo;
		anImageStyleCommand.Free;
		PosePageSetupDialog := gNoChanges;
		END;

	cancelled := NOT react

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE TImagePrintHandler.DoJobItem
		(theDialog: DialogPtr; itemNo: INTEGER);

	CONST
		kJobItemsID 	 = 1201;
		kSelectionItem	 = 1;
		kAllChannelsItem = 2;
		kColorItem		 = 3;
		kCorrectItem	 = 4;
		kASCIIItem		 = 5;
		kBinaryItem 	 = 6;
		kGrayLineItem	 = 7;
		kEncodeBoxItem	 = 9;

	VAR
		itemH: Handle;
		itemBox: Rect;
		itemType: INTEGER;

	BEGIN

	GetDItem (theDialog, gPrintItemBase + itemNo, itemType, itemH, itemBox);

		CASE itemNo OF

		kSelectionItem:
			BEGIN
			fSelection := NOT fSelection;
			SetCtlValue (ControlHandle (itemH), ORD (fSelection))
			END;

		kAllChannelsItem:
			BEGIN
			fAllChannels := NOT fAllChannels;
			SetCtlValue (ControlHandle (itemH), ORD (NOT fAllChannels))
			END;

		kColorItem:
			BEGIN
			fColor := NOT fColor;
			SetCtlValue (ControlHandle (itemH), ORD (fColor))
			END;

		kCorrectItem:
			BEGIN
			fCorrect := NOT fCorrect;
			SetCtlValue (ControlHandle (itemH), ORD (fCorrect))
			END;

		kASCIIItem:
			BEGIN
			fPrintUsingASCII := TRUE;
			SetCtlValue (ControlHandle (itemH), 1);
			GetDItem (theDialog, gPrintItemBase + kBinaryItem,
					  itemType, itemH, itemBox);
			SetCtlValue (ControlHandle (itemH), 0)
			END;

		kBinaryItem:
			BEGIN
			fPrintUsingASCII := FALSE;
			SetCtlValue (ControlHandle (itemH), 1);
			GetDItem (theDialog, gPrintItemBase + kASCIIItem,
					  itemType, itemH, itemBox);
			SetCtlValue (ControlHandle (itemH), 0)
			END

		END

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE TImagePrintHandler.AddJobItems (theDialog: DialogPtr);

	CONST
		kJobItemsID 	 = 1201;
		kSelectionItem	 = 1;
		kAllChannelsItem = 2;
		kColorItem		 = 3;
		kCorrectItem	 = 4;
		kASCIIItem		 = 5;
		kBinaryItem 	 = 6;
		kGrayLineItem	 = 7;
		kEncodeBoxItem	 = 9;

	VAR
		itemH: Handle;
		itemBox: Rect;
		view: TImageView;
		itemType: INTEGER;
		doc: TImageDocument;

	BEGIN

	gPrintItemBase := AppendDITL (theDialog, kJobItemsID) - 1;

	view := TImageView (fView);
	doc  := TImageDocument (view.fDocument);

	GetDItem (theDialog, gPrintItemBase + kSelectionItem,
			  itemType, itemH, itemBox);

	fSelection := NOT EmptyRect (doc.fSelectionRect) AND
				  (doc.fSelectionMask = NIL);

	IF fSelection THEN
		SetCtlValue (ControlHandle (itemH), 1)
	ELSE
		HiliteControl (ControlHandle (itemH), 255);

	GetDItem (theDialog, gPrintItemBase + kAllChannelsItem,
			  itemType, itemH, itemBox);

	fAllChannels := (doc.fMode = SeparationsCMYK) AND (view.fChannel <= 3);

	IF (doc.fChannels = 1) OR (view.fChannel < 0) THEN
		HiliteControl (ControlHandle (itemH), 255)

	ELSE IF NOT fAllChannels THEN
		SetCtlValue (ControlHandle (itemH), 1);

	GetDItem (theDialog, gPrintItemBase + kColorItem,
			  itemType, itemH, itemBox);

	fAllowColor := IsPostScript AND
				   ((doc.fMode = IndexedColorMode) OR
					(doc.fMode = RGBColorMode) AND
					(view.fChannel = kRGBChannels) OR
					(doc.fMode = SeparationsCMYK) AND
					(view.fChannel <= 3));

	IF fAllowColor THEN
		BEGIN
		fColor := gColorPostScript;
		SetCtlValue (ControlHandle (itemH), ORD (fColor))
		END
	ELSE
		BEGIN
		fColor := FALSE;
		HiliteControl (ControlHandle (itemH), 255)
		END;

	GetDItem (theDialog, gPrintItemBase + kCorrectItem,
			  itemType, itemH, itemBox);

	fAllowCorrect := (doc.fMode = IndexedColorMode) OR
					 (view.fChannel = kRGBChannels);

	IF fAllowCorrect THEN
		BEGIN
		fCorrect := gColorCorrect;
		SetCtlValue (ControlHandle (itemH), ORD (fCorrect))
		END
	ELSE
		BEGIN
		fCorrect := FALSE;
		HiliteControl (ControlHandle (itemH), 255)
		END;

	fPrintUsingASCII := gPrintUsingASCII;

	GetDItem (theDialog, gPrintItemBase + kASCIIItem,
			  itemType, itemH, itemBox);

	IF NOT IsPostScript THEN
		HiliteControl (ControlHandle (itemH), 255)
	ELSE
		SetCtlValue (ControlHandle (itemH), ORD (fPrintUsingASCII));

	GetDItem (theDialog, gPrintItemBase + kBinaryItem,
			  itemType, itemH, itemBox);

	IF NOT IsPostScript THEN
		HiliteControl (ControlHandle (itemH), 255)
	ELSE
		SetCtlValue (ControlHandle (itemH), ORD (NOT fPrintUsingASCII));

	GetDItem (theDialog, gPrintItemBase + kGrayLineItem,
			  itemType, itemH, itemBox);
	SetDItem (theDialog, gPrintItemBase + kGrayLineItem,
			  itemType, Handle (@DrawGrayLine), itemBox);

	IF NOT IsPostScript THEN
		BEGIN
		GetDItem (theDialog, gPrintItemBase + kEncodeBoxItem,
				  itemType, itemH, itemBox);
		SetDItem (theDialog, gPrintItemBase + kEncodeBoxItem,
				  itemType, Handle (@GrayOutText), itemBox)
		END

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE MyJobItemProc (theDialog: DialogPtr; itemNo: INTEGER);

	VAR
		myItem: INTEGER;

	PROCEDURE CallItemHandler (theDialog: DialogPtr;
							   theItem: INTEGER;
							   theProc: ProcPtr); INLINE $205F, $4E90;

	BEGIN

	myItem := itemNo - gPrintItemBase;

	IF (myItem >= 1) AND (myItem <= 9) THEN
		gImagePrintHandler.DoJobItem (theDialog, myItem)
	ELSE
		CallItemHandler (theDialog, itemNo, gPrintItemProc)

	END;

{*****************************************************************************}

{$S APrinting}

FUNCTION MyJobDlgInit (hPrint: THPrint): TPPrDlg;

	BEGIN

	gImagePrintHandler.AddJobItems (DialogPtr (gPrintJobDialog));

	gPrintItemProc := gPrintJobDialog^.pItemProc;

	gPrintJobDialog^.pItemProc := @MyJobItemProc;

	MyJobDlgInit := gPrintJobDialog

	END;

{*****************************************************************************}

{$S APrinting}

FUNCTION TImagePrintHandler.DoJobDialog: BOOLEAN;

	VAR
		bounds: Rect;
		wp: WindowPtr;
		title: Str255;
		proceed: BOOLEAN;
		view: TImageView;
		doc: TImageDocument;
		
	BEGIN

	DoJobDialog := FALSE;
	
	VMCompress (TRUE);

	view := TImageView (fView);
	doc  := TImageDocument (view.fDocument);

	IF gFinderPrinting THEN
		BEGIN

		ValidatePrintRecord (proceed);

		fSelection := FALSE;

		fColor := IsPostScript AND (doc.fMode IN [IndexedColorMode,
												  RGBColorMode]);

		fCorrect := gColorCorrect AND (doc.fMode IN [IndexedColorMode,
													 RGBColorMode]);

		fAllChannels := (doc.fMode = SeparationsCMYK);

		fPrintUsingASCII := gPrintUsingASCII;

		proceed := TRUE
		
		END
		
	ELSE
		BEGIN

		fSelection := NOT EmptyRect (doc.fSelectionRect) AND
					  (doc.fSelectionMask = NIL);
	
		IF NOT WarnIfTooLarge THEN EXIT (DoJobDialog);
		IF NOT WarnIfTooFine  THEN EXIT (DoJobDialog);
	
		SetRect (bounds, -30000, -30000, -29900, -29900);
	
		title := doc.fTitle;
	
		wp := NewWindow (NIL, bounds, title, TRUE, documentProc,
						 WindowPtr (-1), TRUE, 0);
	
		SetCursor (arrow);
	
		gImagePrintHandler := SELF;
	
		gPrintJobDialog := PrJobInit (THPrint (fHPrint));
	
		IF PrError <> noErr THEN
			proceed := FALSE
	
		ELSE
			BEGIN
	
			proceed := PrDlgMain (THPrint (fHPrint), @MyJobDlgInit);
	
			IF proceed THEN
				BEGIN
	
				IF (doc.fMode = SeparationsCMYK) AND NOT fAllChannels THEN
					fColor := FALSE
	
				ELSE IF fAllowColor THEN
					gColorPostScript := fColor;
	
				IF fAllowCorrect THEN
					gColorCorrect := fCorrect;
					
				gPrintUsingASCII := fPrintUsingASCII
	
				END;
	
			END;
	
		DisposeWindow (wp)
		
		END;

	IF (view.fChannel = kRGBChannels) AND IsPostScript AND
										  fCorrect AND
										  fColor THEN
		BuildSeparationTable;

	DoJobDialog := proceed

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE TImagePrintHandler.PosePrintDialog; OVERRIDE;

	CONST
		kFinderID = 1270;
		kNormalID = 1271;

	VAR
		box: Rect;
		docName: Str255;
		itemType: INTEGER;
		dlgNumber: INTEGER;
		proceedButton: ControlHandle;

	BEGIN

	IF gFinderPrinting THEN
		dlgNumber := kFinderID
	ELSE
		dlgNumber := kNormalID;

	docName := fView.fDocument.fTitle;

	ParamText (docName, '', '', '');

	gPrintDialog := GetNewDialog (dlgNumber, NIL, POINTER (-1));

	CenterWindow (gPrintDialog, FALSE);

	THPrint(fHPrint)^^.prJob.pIdleProc := @CheckButton;

	GetDItem (gPrintDialog, 1, itemType, Handle (proceedButton), box);
	HiLiteControl (proceedButton, 255);

	ShowWindow (gPrintDialog);
	DrawDialog (gPrintDialog)

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE TImagePrintHandler.ShowDocBeingPrinted
			(entering: BOOLEAN); OVERRIDE;

	CONST
		kDialogID = 1290;

	VAR
		title: Str255;
		doc: TImageDocument;

	BEGIN

	IF entering THEN
		BEGIN

		doc := TImageDocument (fView.fDocument);

		gPrintDialog := GetNewDialog (kDialogID, NIL, POINTER (-1));

		IF gPrintDialog <> NIL THEN
			BEGIN
			title := doc.fTitle;
			SetWTitle (gPrintDialog, title);
			DrawDialog (gPrintDialog)
			END

		END

	ELSE
		INHERITED ShowDocBeingPrinted (entering)

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE TImagePrintHandler.PoseJobDialog (VAR proceed: BOOLEAN); OVERRIDE;

	PROCEDURE CallJobDialog;
		BEGIN
		proceed := DoJobDialog
		END;

	PROCEDURE UpdateIt (aWindow: TWindow);
		BEGIN
		aWindow.UpdateEvent;
		END;

	BEGIN

	proceed := FALSE; {??? Is this wrong in MacApp source code ???}

	DoInMacPrint (CallJobDialog);

	IF PrError <> noErr THEN proceed := FALSE;

	IF proceed THEN gApplication.ForAllWindowsDo (UpdateIt)

	END;

{*****************************************************************************}

{$S APrinting}

FUNCTION TImagePrintHandler.MaxPageNumber: INTEGER; OVERRIDE;

	VAR
		view: TImageView;
		doc: TImageDocument;

	BEGIN

	view := TImageView (fView);
	doc  := TImageDocument (view.fDocument);

	IF fAllChannels AND NOT fColor THEN
		IF (doc.fMode = SeparationsCMYK) AND (view.fChannel <= 3) THEN
			MaxPageNumber := 4
		ELSE
			MaxPageNumber := doc.fChannels
	ELSE
		MaxPageNumber := 1

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE TImagePrintHandler.SetPage (aPageNumber: INTEGER); OVERRIDE;

	BEGIN
	INHERITED SetPage (1)
	END;

{*****************************************************************************}

{$S APrinting}

FUNCTION TImagePrintHandler.OneSubJob
		(subjobFirstPage, subjobLastPage: INTEGER;
		 justSpool: BOOLEAN;
		 partialJob: BOOLEAN;
		 VAR ranOutOfSpace: BOOLEAN;
		 VAR lastPageTried: INTEGER;
		 VAR proceed: BOOLEAN): TCommand; OVERRIDE;

	VAR
		h: Handle;

	BEGIN

	{ Make sure there is a decent size block of memory }

	h := NewHandle ($18000);
	IF h <> NIL THEN
		DisposHandle (h);

	OneSubJob := INHERITED OneSubJob (subjobFirstPage, subjobLastPage,
									  justSpool, partialJob, ranOutOfSpace,
									  lastPageTried, proceed)

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE TImagePrintHandler.FocusOnInterior
		(aPageNumber: INTEGER); OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	r := fPageAreas [padSpace] . theInk;

	WITH gPageOffset DO OffsetRect (r, h, v);

	SetOrigin (r.left, r.top);
	ClipRect (r)

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE GetPrintRects (doc: TImageDocument;
						 bounds: Rect;
						 VAR thePaper: Rect;
						 VAR theInk: Rect;
						 VAR theImage: Rect);

	VAR
		dpi: EXTENDED;
		width: LONGINT;
		height: LONGINT;
		print: TImagePrintHandler;

	BEGIN

	print := TImagePrintHandler (TView (doc.fViewList.First).fPrintHandler);

	dpi := doc.fStyleInfo.fResolution.value / $10000;

	width  := bounds.right - bounds.left;
	height := bounds.bottom - bounds.top;

	IF print.IsPostScript THEN
		BEGIN
		width  := ROUND (width	/ dpi * 72);
		height := ROUND (height / dpi * 72)
		END
	ELSE
		BEGIN
		width  := TRUNC (width	/ dpi * 72 + 0.01);
		height := TRUNC (height / dpi * 72 + 0.01)
		END;

	width  := Max (1, Min (kMaxCoord, width));
	height := Max (1, Min (kMaxCoord, height));

	thePaper := print.fPageAreas [padSpace] . thePaper;
	theInk	 := print.fPageAreas [padSpace] . theInk;

	SetRect (theImage, 0, 0, width, height);

	OffsetRect (theImage, (theInk.right - theInk.left - width ) DIV 2,
						  (theInk.bottom - theInk.top - height) DIV 2)

	END;

{*****************************************************************************}

{$S APrinting}

FUNCTION TImagePrintHandler.WarnIfTooLarge: BOOLEAN;

	CONST
		kImageTooBig  = 920;
		kSelectTooBig = 921;

	VAR
		bounds: Rect;
		theInk: Rect;
		thePaper: Rect;
		theImage: Rect;
		doc: TImageDocument;

	BEGIN

	doc := TImageDocument (fView.fDocument);

	IF fSelection THEN
		bounds := doc.fSelectionRect
	ELSE
		doc.GetBoundsRect (bounds);

	GetPrintRects (doc, bounds, thePaper, theInk, theImage);

	IF (theInk.right - theInk.left < theImage.right - theImage.left) OR
	   (theInk.bottom - theInk.top < theImage.bottom - theImage.top) THEN

		IF fSelection THEN
			WarnIfTooLarge := (BWAlert (kSelectTooBig, 0, TRUE) = ok)
		ELSE
			WarnIfTooLarge := (BWAlert (kImageTooBig, 0, TRUE) = ok)

	ELSE
		WarnIfTooLarge := TRUE

	END;

{*****************************************************************************}

{$S APrinting}

FUNCTION TImagePrintHandler.WarnIfTooFine: BOOLEAN;

	CONST
		kImageTooFine = 927;

	VAR
		res: Fixed;
		freq: Fixed;
		view: TImageView;
		doc: TImageDocument;

	BEGIN

	WarnIfTooFine := TRUE;

	IF IsPostScript THEN
		BEGIN

		view := TImageView (fView);
		doc  := TImageDocument (view.fDocument);

		res := doc.fStyleInfo.fResolution.value;

		IF doc.fMode IN [IndexedColorMode, RGBColorMode, SeparationsCMYK] THEN
			freq := doc.fStyleInfo.fHalftoneSpecs[3].frequency.value
		ELSE
			freq := doc.fStyleInfo.fHalftoneSpec.frequency.value;

		freq := Max (50 * $10000, freq);

		IF (res > freq * 5 DIV 2) AND (doc.fMode <> HalftoneMode) THEN
			WarnIfTooFine := (BWAlert (kImageTooFine, 0, TRUE) = ok)

		END

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE TImagePrintHandler.PositionStuffOnPage;

	VAR
		r1: Rect;
		r2: Rect;
		doc: TImageDocument;

	BEGIN

	doc := TImageDocument (fView.fDocument);

	IF fSelection THEN
		fInputArea := doc.fSelectionRect
	ELSE
		{$H-}
		doc.GetBoundsRect (fInputArea);
		{$H+}

	{$H-}
	GetPrintRects (doc, fInputArea, r1, r2, fOutputArea);
	{$H+}

	fRegMarks [0] . v := fOutputArea.top	- 20;
	fRegMarks [0] . h := fOutputArea.left	+ 28;

	fRegMarks [1] . v := fOutputArea.top	- 20;
	fRegMarks [1] . h := fOutputArea.right	- 28;

	fRegMarks [2] . h := fOutputArea.right	+ 20;
	fRegMarks [2] . v := fOutputArea.top	+ 22;

	fRegMarks [3] . h := fOutputArea.right	+ 20;
	fRegMarks [3] . v := fOutputArea.bottom - 22;

	fRegMarks [4] . v := fOutputArea.bottom + 20;
	fRegMarks [4] . h := fOutputArea.right	- 34;

	fRegMarks [5] . v := fOutputArea.bottom + 20;
	fRegMarks [5] . h := fOutputArea.left	+ 16;

	fRegMarks [6] . h := fOutputArea.left	- 20;
	fRegMarks [6] . v := fOutputArea.bottom - 16;

	fRegMarks [7] . h := fOutputArea.left	- 20;
	fRegMarks [7] . v := fOutputArea.top	+ 34;

	IF fOutputArea.right - fOutputArea.left < 144 THEN
		BEGIN
		fRegMarks [0] . h := BSR (fOutputArea.left + fOutputArea.right, 1);
		fRegMarks [1] . h := fRegMarks [0] . h;
		fRegMarks [4] . h := fRegMarks [0] . h;
		fRegMarks [5] . h := fRegMarks [0] . h
		END;

	IF fOutputArea.bottom - fOutputArea.top < 144 THEN
		BEGIN
		fRegMarks [2] . v := BSR (fOutputArea.top + fOutputArea.bottom, 1);
		fRegMarks [3] . v := fRegMarks [2] . v;
		fRegMarks [6] . v := fRegMarks [2] . v;
		fRegMarks [7] . v := fRegMarks [2] . v
		END;

	fExpandedArea := fOutputArea;

	IF fOutputArea.right - fOutputArea.left < 276 THEN
		{$H-}
		InsetRect (fExpandedArea, 0, -30);
		{$H+}

	IF fOutputArea.bottom - fOutputArea.top < 228 THEN
		{$H-}
		InsetRect (fExpandedArea, -30, 0);
		{$H+}

	IF fExpandedArea.right - fExpandedArea.left < 176 THEN
		BEGIN
		fExpandedArea.left := (fExpandedArea.left +
							   fExpandedArea.right - 176) DIV 2;
		fExpandedArea.right := fExpandedArea.left + 176
		END

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE TImagePrintHandler.PrintUsingPostScript (doc: TImageDocument;
												   channel: INTEGER);

	CONST
		kPostScriptBegin = 190;
		kPostScriptEnd	 = 191;

	VAR
		r1: Rect;
		r2: Rect;
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		EndPostScript
		END;

	BEGIN

	MoveTo (-30000, -30000); Line (10, 0); { Fixes background printing }

	PicComment (kPostScriptBegin, 0, NIL);

	r1 := fInputArea;
	r2 := fOutputArea;

	BeginPostScript (FALSE, 0);

	CatchFailures (fi, CleanUp);
	
	{ Hack required for Color Calibration Software compatibility }
	GenerateOther ('/setcolortransfer where');
	GenerateOther ('{pop {} {} {} {} setcolortransfer}');
	GenerateOther ('{{} settransfer} ifelse');

	IF doc.fStyleInfo.fNegative THEN
		BEGIN
		GenerateOther ('{1 exch sub dummy exec} dup 3');
		GenerateOther ('systemdict /currenttransfer get exec put');
		GenerateOther ('systemdict /settransfer get exec erasepage')
		END;

	IF doc.fStyleInfo.fFlip THEN
		GenerateOther ('clippath pathbbox pop 0 translate pop pop -1 1 scale');

	GenerateOther ('gsave');

	GeneratePostScript (doc,
						channel,
						r1,
						r2,
						fColor,
						doc.fDepth <> 1,
						doc.fDepth <> 1,
						FALSE,
						NOT fPrintUsingASCII,
						TRUE);

	PrintPostScriptMarks (doc, channel);

	FlushPostScript;

	Success (fi);

	EndPostScript;

	PicComment (kPostScriptEnd, 0, NIL)

	END;

{*****************************************************************************}

{$S APrinting}

FUNCTION TImagePrintHandler.GetPortDepth: INTEGER;

	VAR
		port: CGrafPtr;
		depth: INTEGER;

	BEGIN

	depth := 1;

	GetPort (GrafPtr (port));

	IF BAND (BSR (port^.portVersion, 14), 3) = 3 THEN
		CASE port^.portPixMap^^.pixelSize OF

		2:	depth := 2;

		4:	depth := 4;

		8:	depth := 8;

		32: depth := 32

		END;

	GetPortDepth := depth

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE TImagePrintHandler.PrintUsingQuickDraw (doc: TImageDocument;
												  channel: INTEGER);

	TYPE
		BitPtr = ^BitMap;

	VAR
		r: Rect;
		res: Fixed;
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		bounds: Rect;
		res1: INTEGER;
		res2: INTEGER;
		mode: INTEGER;
		page: INTEGER;
		srcRect: Rect;
		dstRect: Rect;
		depth: INTEGER;
		block: INTEGER;
		srcSize: Point;
		dstSize: Point;
		fract: EXTENDED;
		buffer1: Handle;
		buffer2: Handle;
		aPixMap: PixMap;
		rowBytes1: LONGINT;
		rowBytes2: LONGINT;
		blockSize: INTEGER;
		saveClip: RgnHandle;
		blocksPerPage: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		DisposeRgn (saveClip);
		FreeLargeHandle (buffer1);
		FreeLargeHandle (buffer2)
		END;

	BEGIN

	buffer1 := NIL;
	buffer2 := NIL;

	saveClip := NewRgn;

	CatchFailures (fi, CleanUp);

	depth := GetPortDepth;

	IF (channel = kRGBChannels) AND (depth = 8) AND gHas32BitQuickDraw THEN
		depth := 32;

	gTables.CompTables (doc,
						channel,
						FALSE,
						FALSE,
						depth,
						depth,
						TRUE,
						TRUE,
						1);

	blocksPerPage := doc.fData [0] . fBlocksPerPage;

	r		 := fInputArea;
	r.top	 := 0;
	r.bottom := blocksPerPage;

	buffer1 := NewLargeHandle (gTables.BufferSize (r));

	rowBytes1 := gTables.CompRowBytes (r.right - r.left);

	res := doc.fStyleInfo.fResolution.value;

	IF (LoWrd (res) <> 0) OR (res <= 72 * $10000) THEN
		BEGIN
		res1 := 1;
		res2 := 1
		END
	ELSE
		BEGIN
		res1 := HiWrd (res);
		res2 := 72;
		Reduce (res1, res2)
		END;

	srcSize.h := (fInputArea.right - fInputArea.left + res1 - 1)
				 DIV res1 * res1;
	srcSize.v := (fInputArea.bottom - fInputArea.top + res1 - 1)
				 DIV res1 * res1;

	rowBytes2 := gTables.CompRowBytes (srcSize.h);

	blockSize := Max (res1, Min (srcSize.v, VMCanReserve DIV rowBytes2));
	blockSize := blockSize DIV res1 * res1;

	buffer2 := NewLargeHandle (blockSize * rowBytes2);

	IF res1 = 1 THEN
		BEGIN
		dstSize.h := fOutputArea.right - fOutputArea.left;
		dstSize.v := fOutputArea.bottom - fOutputArea.top
		END
	ELSE
		BEGIN
		dstSize.h := srcSize.h DIV res1 * res2;
		dstSize.v := srcSize.v DIV res1 * res2
		END;

	MoveHHi (buffer1);
	HLock (buffer1);

	HLock (buffer2);

	IF gTables.fDepth = 1 THEN
		aPixMap.rowBytes := rowBytes2
	ELSE
		aPixMap.rowBytes := BOR ($8000, rowBytes2);

	aPixMap.baseAddr := buffer2^;
	aPixMap.pmVersion := 0;
	aPixMap.packType := 0;
	aPixMap.packSize := 0;
	aPixMap.hRes := res;
	aPixMap.vRes := res;

	IF gTables.fDepth = 32 THEN
		BEGIN
		aPixMap.pixelType := RGBDirect;
		aPixMap.pixelSize := 32;
		aPixMap.cmpCount  := 3;
		aPixMap.cmpSize   := 8
		END
	ELSE
		BEGIN
		aPixMap.pixelType := 0;
		aPixMap.pixelSize := gTables.fDepth;
		aPixMap.cmpCount  := 1;
		aPixMap.cmpSize   := gTables.fDepth
		END;

	aPixMap.planeBytes := 0;
	aPixMap.pmReserved := 0;

	aPixMap.pmTable := gTables.fColorTable;

	GetClip (saveClip);

	r := fOutputArea;
	ClipRect (r);

	srcRect.left   := fInputArea.left;
	srcRect.right  := srcRect.left + srcSize.h;
	srcRect.bottom := fInputArea.top;

	dstRect.left   := fOutputArea.left;
	dstRect.right  := dstRect.left + dstSize.h;
	dstRect.bottom := fOutputArea.top;

	FOR block := 0 TO (srcSize.v - 1) DIV blockSize DO
		BEGIN

		srcRect.top    := srcRect.bottom;
		srcRect.bottom := Min (srcRect.top + blockSize,
							   fInputArea.top + srcSize.v);

		dstRect.top := dstRect.bottom;

		IF res1 = 1 THEN
			BEGIN
			fract := (srcRect.bottom - fInputArea.top) / srcSize.v;
			dstRect.bottom := fOutputArea.top + ROUND (dstSize.v * fract)
			END
		ELSE
			dstRect.bottom := Min (dstRect.top + blockSize DIV res1 * res2,
								   fOutputArea.top + dstSize.v);

		bounds := srcRect;
		doc.SectBoundsRect (bounds);

		r := bounds;

		dstPtr := buffer2^;

			REPEAT

			r.bottom := Min (ORD4 (r.top + blocksPerPage)
							 DIV blocksPerPage * blocksPerPage,
							 bounds.bottom);

			gTables.DitherRect (doc, channel, 1, r, buffer1^, TRUE);

			srcPtr := buffer1^;

			FOR row := r.top TO r.bottom - 1 DO
				BEGIN
				BlockMove (srcPtr, dstPtr, rowBytes1);
				srcPtr := Ptr (ORD4 (srcPtr) + rowBytes1);
				dstPtr := Ptr (ORD4 (dstPtr) + rowBytes2)
				END;

			r.top := r.bottom

			UNTIL r.top = bounds.bottom;

		aPixMap.bounds := srcRect;

		IF depth = 32 THEN
			mode := 64
		ELSE
			mode := srcCopy;

		IF NOT EmptyRect (dstRect) THEN
			CopyBits (BitPtr (@aPixMap)^, thePort^.portBits,
					  srcRect, dstRect, mode, NIL)

		END;

	Success (fi);

	SetClip (saveClip);

	CleanUp (0, 0);

	PrintQuickDrawMarks (doc, channel)

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE DecodeCaption (VAR s: Str255;
						 width: INTEGER;
						 VAR caption: TCaption);

	VAR
		j: INTEGER;
		k: INTEGER;
		w: INTEGER;
		line: INTEGER;
		hard: BOOLEAN;
		wrap: BOOLEAN;

	BEGIN

	hard := FALSE;
	wrap := FALSE;

	FOR line := 1 TO kCaptionLines DO
		BEGIN

		j := 0;
		w := 0;

		WHILE j < LENGTH (s) DO
			BEGIN

			j := j + 1;

			IF s [j] = CHR (13) THEN
				BEGIN
				hard := TRUE;
				DELETE (s, j, 1);
				j := j - 1;
				LEAVE
				END;

			w := w + CharWidth (s [j]);

			IF w > width THEN
				BEGIN

				wrap := TRUE;

				j := j - 1;
				k := j;

				WHILE s [j + 1] <> ' ' DO
					BEGIN
					j := j - 1;
					IF j <= 1 THEN
						BEGIN
						j := k;
						LEAVE
						END
					END;

				WHILE (j < LENGTH (s)) & (s [j + 1] = ' ') DO
					DELETE (s, j + 1, 1);

				LEAVE

				END

			END;

		caption.line [line] 	:= s;
		caption.line [line] [0] := CHR (j);

		IF j <> 0 THEN
			DELETE (s, 1, j)

		END;

	caption.center := NOT wrap OR hard

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE TImagePrintHandler.PrintPostScriptMarks (doc: TImageDocument;
												   channel: INTEGER);

	VAR
		s: Str255;
		bounds: Rect;
		line: INTEGER;
		offset: INTEGER;
		caption: TCaption;
		blackInk: BOOLEAN;
		marks: TRegMarkList;

	BEGIN

	blackInk := (doc.fMode <> SeparationsCMYK) OR (channel < 0) OR
												  (channel = 3);

	IF doc.fStyleInfo.fColorBars AND (doc.fDepth <> 1) THEN
		BEGIN

		bounds := fExpandedArea;

		IF blackInk THEN
			GenerateGrayBar (bounds);

		IF (doc.fMode = IndexedColorMode) OR (channel < 0) THEN
			BEGIN
			IF fColor THEN GenerateColorBars (bounds, -1)
			END

		ELSE IF (doc.fMode = SeparationsCMYK) AND (channel <= 3) THEN
			GenerateColorBars (bounds, channel)

		END;

	GenerateOther ('grestore'); 	{ Kill screen and transfer }

	IF doc.fStyleInfo.fRegistrationMarks THEN
		BEGIN
		marks := fRegMarks;
		GenerateRegMarks (marks)
		END;

	bounds := fOutputArea;

	IF doc.fStyleInfo.fRegistrationMarks THEN
		GenerateStarTargets (bounds);

	IF doc.fStyleInfo.fCropMarks THEN
		GenerateCropMarks (bounds);

	IF (doc.fStyleInfo.fBorder.value <> 0) AND blackInk THEN
		GenerateBorder (fOutputArea.topLeft,
						fInputArea.right - fInputArea.left,
						fInputArea.bottom - fInputArea.top,
						doc.fStyleInfo.fResolution.value,
						doc.fStyleInfo.fBorder.value);

	IF doc.fStyleInfo.fLabel THEN
		BEGIN

		GenerateSetFont;

		s := doc.fTitle;

		GenerateText (s,
					  TRUE,
					  fExpandedArea.left,
					  fExpandedArea.right,
					  fExpandedArea.top - 22);

		IF (doc.fChannels <> 1) AND (channel >= 0) THEN
			BEGIN

			doc.ChannelName (channel, s);

			IF (doc.fMode = SeparationsCMYK) AND (channel <= 3) THEN
				offset := offset + 44 * channel - 68
			ELSE
				offset := 0;

			GenerateText (s,
						  TRUE,
						  fExpandedArea.left + offset,
						  fExpandedArea.right + offset,
						  fExpandedArea.top - 12)

			END

		END;

	IF (LENGTH (doc.fStyleInfo.fCaption) <> 0) AND blackInk THEN
		BEGIN

		IF NOT doc.fStyleInfo.fLabel THEN
			GenerateSetFont;

		TextFont (gHelvetica);
		TextSize (9);

		s := doc.fStyleInfo.fCaption;

		DecodeCaption (s, fExpandedArea.right - fExpandedArea.left, caption);

		FOR line := 1 TO kCaptionLines DO
			BEGIN

			s := caption.line [line];

			GenerateText (s,
						  caption.center,
						  fExpandedArea.left,
						  fExpandedArea.right,
						  fExpandedArea.bottom + 36 + 12 * line)

			END

		END

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE TImagePrintHandler.PrintQuickDrawMarks (doc: TImageDocument;
												  channel: INTEGER);

	VAR
		r: Rect;
		s: Str255;
		ss: Str255;
		h: INTEGER;
		v: INTEGER;
		mark: INTEGER;
		just: INTEGER;
		info: FontInfo;
		width: INTEGER;
		blackInk: BOOLEAN;

	PROCEDURE CropMark (h, v, dh, dv: INTEGER);
		BEGIN
		MoveTo (h + dh * 30, v);
		LineTo (h + dh * 10, v);
		MoveTo (h, v + dv * 30);
		LineTo (h, v + dv * 10)
		END;

	PROCEDURE DrawCentered;
		BEGIN
		Move (-(StringWidth (s) DIV 2), 0);
		DrawString (s)
		END;

	BEGIN

	blackInk := (doc.fMode <> SeparationsCMYK) OR (channel < 0) OR
												  (channel = 3);

	PenNormal;

	IF doc.fStyleInfo.fRegistrationMarks THEN
		FOR mark := 0 TO 7 DO
			BEGIN

			h := fRegMarks [mark] . h;
			v := fRegMarks [mark] . v;

			SetRect (r, h - 10, v - 10, h + 11, v + 11);
			EraseOval (r);

			MoveTo (h - 10, v);
			LineTo (h + 10, v);
			MoveTo (h, v - 10);
			LineTo (h, v + 10);

			InsetRect (r, 2, 2);
			FrameOval (r)

			END;

	IF doc.fStyleInfo.fCropMarks THEN
		BEGIN
		CropMark (fOutputArea.left , fOutputArea.top   , -1, -1);
		CropMark (fOutputArea.right, fOutputArea.top   ,  1, -1);
		CropMark (fOutputArea.left , fOutputArea.bottom, -1,  1);
		CropMark (fOutputArea.right, fOutputArea.bottom,  1,  1)
		END;

	IF (doc.fStyleInfo.fBorder.value <> 0) AND blackInk THEN
		BEGIN

		width := Max (1, FixRound (doc.fStyleInfo.fBorder.value * 72));

		PenSize (width, width);

		width := (width + 1) DIV 2;

		r := fOutputArea;
		InsetRect (r, -width, -width);

		FrameRect (r);

		PenNormal

		END;

	TextFont (gGeneva);
	TextSize (9);

	IF doc.fStyleInfo.fLabel THEN
		BEGIN

		s := doc.fTitle;

		MoveTo ((fExpandedArea.left + fExpandedArea.right) DIV 2,
				fExpandedArea.top - 22);

		DrawCentered;

		IF (doc.fChannels <> 1) AND (channel >= 0) THEN
			BEGIN

			doc.ChannelName (channel, s);

			MoveTo ((fExpandedArea.left + fExpandedArea.right) DIV 2,
					fExpandedArea.top - 12);

			IF (doc.fMode = SeparationsCMYK) AND (channel <= 3) THEN
				Move (44 * channel - 68, 0);

			DrawCentered

			END

		END;

	IF (LENGTH (doc.fStyleInfo.fCaption) <> 0) AND blackInk THEN
		BEGIN

		s := doc.fStyleInfo.fCaption;

		GetFontInfo (info);

		r		 := fExpandedArea;
		r.top	 := r.bottom + 38;
		r.bottom := r.top + 6 * (info.ascent + info.descent + info.leading);

		ss := ' ';
		ss [1] := CHR (13);

		IF (POS (ss, s) <> 0) | (StringWidth (s) < r.right - r.left) THEN
			just := teJustCenter
		ELSE
			just := teJustLeft;

		TextBox (@s[1], LENGTH (s), r, just)

		END

	END;

{*****************************************************************************}

{$S APrinting}

FUNCTION TImagePrintHandler.CorrectPrintingColors
		(doc: TImageDocument; rgb: BOOLEAN): TImageDocument;

	VAR
		c: INTEGER;
		m: INTEGER;
		y: INTEGER;
		fi: FailInfo;
		fi2: FailInfo;
		index: INTEGER;
		channel: INTEGER;
		aVMArray: TVMArray;
		LUT: TRGBLookUpTable;
		pdoc: TImageDocument;
		map: ARRAY [0..3] OF TLookUpTable;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF pdoc.fMode = IndexedColorMode THEN
			pdoc.fData [0] := NIL;
		pdoc.Free
		END;

	PROCEDURE CleanUp2 (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress
		END;

	BEGIN

	pdoc := TImageDocument (gApplication.DoMakeDocument (cPrint));

	CatchFailures (fi, CleanUp);

	pdoc.fRows := doc.fRows;
	pdoc.fCols := doc.fCols;

	pdoc.fTitle := doc.fTitle;

	pdoc.fStyleInfo := doc.fStyleInfo;
	
	IF rgb THEN
		IF doc.fMode = IndexedColorMode THEN
			BEGIN
	
			pdoc.fMode := IndexedColorMode;
	
			pdoc.fChannels := 1;
	
			pdoc.fData [0] := doc.fData [0];
	
			FOR index := 0 TO 255 DO
				BEGIN
	
				SolveForCMY (ORD (doc.fIndexedColorTable.R [index]),
							 ORD (doc.fIndexedColorTable.G [index]),
							 ORD (doc.fIndexedColorTable.B [index]), c, m, y);
	
				pdoc.fIndexedColorTable.R [index] := CHR (c);
				pdoc.fIndexedColorTable.G [index] := CHR (m);
				pdoc.fIndexedColorTable.B [index] := CHR (y)
	
				END
	
			END
			
		ELSE
			BEGIN
			
			pdoc.fMode := RGBColorMode;

			pdoc.fChannels := 3;

			FOR channel := 0 TO 2 DO
				BEGIN
	
				aVMArray := NewVMArray (pdoc.fRows, pdoc.fCols, 3 - channel);
	
				pdoc.fData [channel] := aVMArray
	
				END;

			CommandProgress (cColorCorrection);

			CatchFailures (fi2, CleanUp2);

			ConvertRGB2CMY (doc.fData [0],
							doc.fData [1],
							doc.fData [2],
							pdoc.fData [0],
							pdoc.fData [1],
							pdoc.fData [2]);

			Success (fi2);

			CleanUp2 (0, 0)

			END

	ELSE
		BEGIN

		pdoc.fMode := SeparationsCMYK;

		pdoc.fChannels := 4;

		FOR channel := 0 TO 3 DO
			BEGIN

			IF doc.fMode = IndexedColorMode THEN
				aVMArray := doc.fData [0] . CopyArray (4 - channel)
			ELSE
				aVMArray := NewVMArray (pdoc.fRows, pdoc.fCols, 4 - channel);

			pdoc.fData [channel] := aVMArray

			END;

		IF doc.fMode = IndexedColorMode THEN
			BEGIN

			LUT := doc.fIndexedColorTable;

			SeparateColorLUT (LUT, map [0], map [1], map [2], map [3]);

			FOR channel := 0 TO 3 DO
				BEGIN
				MoveHands (TRUE);
				pdoc.fData [channel] . MapBytes (map [channel])
				END

			END

		ELSE
			BEGIN

			CommandProgress (cColorCorrection);

			CatchFailures (fi2, CleanUp2);

			ConvertRGB2CMYK (doc.fData [0],
							 doc.fData [1],
							 doc.fData [2],
							 pdoc.fData [0],
							 pdoc.fData [1],
							 pdoc.fData [2],
							 pdoc.fData [3]);

			Success (fi2);

			CleanUp2 (0, 0)

			END

		END;

	Success (fi);

	CorrectPrintingColors := pdoc

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE TImagePrintHandler.DrawPageInterior
		(aPageNumber: INTEGER); OVERRIDE;

	VAR
		s: Str255;
		fi: FailInfo;
		channel: INTEGER;
		doc: TImageDocument;
		pdoc: TImageDocument;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF pdoc <> doc THEN
			BEGIN
			IF pdoc.fMode = IndexedColorMode THEN
				pdoc.fData [0] := NIL;
			pdoc.Free
			END
		END;

	BEGIN

	doc := TImageDocument (fView.fDocument);

	IF fAllChannels THEN
		IF fColor THEN
			channel := kCMYKChannels
		ELSE
			channel := aPageNumber - 1
	ELSE
		channel := TImageView (fView) . fChannel;

	IF (channel >= 0) AND (doc.fChannels > 1) THEN
		BEGIN

		doc.ChannelName (channel, s);

		INSERT ('  (', s, 1);
		INSERT (')', s, LENGTH (s) + 1);
		INSERT (doc.fTitle, s, 1);

		ParamText (s, '', '', '');

		DrawDialog (gPrintDialog)

		END;

	PositionStuffOnPage;

	fCorrect := fCorrect AND ((doc.fMode = IndexedColorMode) OR
							  (channel = kRGBChannels));

	pdoc := doc;

	CatchFailures (fi, CleanUp);

	IF IsPostScript THEN
		BEGIN

		fCorrect := fCorrect AND fColor;

		IF fCorrect THEN
			BEGIN
			pdoc	:= CorrectPrintingColors (doc, FALSE);
			channel := kCMYKChannels
			END;

		PrintUsingPostScript (pdoc, channel)

		END

	ELSE
		BEGIN

		fCorrect := fCorrect AND (GetPortDepth >= 8);

		IF fCorrect THEN
			pdoc := CorrectPrintingColors (doc, TRUE);

		PrintUsingQuickDraw (pdoc, channel)

		END;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S AOpen}

PROCEDURE AddImagePrintHander (view: TImageView);

	VAR
		anImagePrintHandler: TImagePrintHandler;

	BEGIN

	NEW (anImagePrintHandler);
	FailNil (anImagePrintHandler);

	anImagePrintHandler.IImagePrintHandler (view)

	END;

{*****************************************************************************}

END.

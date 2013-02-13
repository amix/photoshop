{Photoshop version 1.0.1, file: UChannel.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UChannel;

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

	TNewChannelCommand = OBJECT (TBufferCommand)

		fOldChannel: INTEGER;

		PROCEDURE TNewChannelCommand.INewChannelCommand (view: TImageView);

		PROCEDURE TNewChannelCommand.DoIt; OVERRIDE;

		PROCEDURE TNewChannelCommand.UndoIt; OVERRIDE;

		PROCEDURE TNewChannelCommand.RedoIt; OVERRIDE;

		END;

	TSplitChannels = OBJECT (TBufferCommand)

		PROCEDURE TSplitChannels.DoIt; OVERRIDE;

		END;

	TMergeChannels = OBJECT (TBufferCommand)

		fMode: TDisplayMode;

		fChannels: INTEGER;

		fLegalCount: INTEGER;

		fMergeList: ARRAY [1..kMaxChannels] OF TImageDocument;

		PROCEDURE TMergeChannels.IMergeChannels (view: TImageView);

		PROCEDURE TMergeChannels.ForAllLegalDocuments
					(PROCEDURE DoToIt (doc: TImageDocument));

		FUNCTION TMergeChannels.GuessMode (mode: TDisplayMode): BOOLEAN;

		PROCEDURE TMergeChannels.GetMode;

		PROCEDURE TMergeChannels.GetList;

		PROCEDURE TMergeChannels.DoIt; OVERRIDE;

		END;

FUNCTION DoSetChannelCommand (view: TImageView; channel: INTEGER): TCommand;

FUNCTION DoNewChannel (view: TImageView): TCommand;

FUNCTION DoSplitChannels (view: TImageView): TCommand;

FUNCTION DoMergeChannels (view: TImageView): TCommand;

IMPLEMENTATION

{*****************************************************************************}

{$S ASelCommand}

FUNCTION DoSetChannelCommand (view: TImageView;
							  channel: INTEGER): TCommand;

	BEGIN

	IF channel = view.fChannel THEN Failure (0, 0);

	view.fChannel := channel;
	view.ReDither (TRUE);
	view.UpdateWindowTitle;

	DoSetChannelCommand := gNoChanges

	END;

{*****************************************************************************}

{$S AChannel}

PROCEDURE TNewChannelCommand.INewChannelCommand (view: TImageView);

	BEGIN

	IBufferCommand (cNewChannel, view)

	END;

{*****************************************************************************}

{$S AChannel}

PROCEDURE TNewChannelCommand.DoIt; OVERRIDE;

	VAR
		aVMArray: TVMArray;

	BEGIN

	MoveHands (TRUE);

	fOldChannel := fView.fChannel;

	aVMArray := NewVMArray (fDoc.fRows, fDoc.fCols, 1);
	fBuffer [0] := aVMArray;

	MoveHands (TRUE);

	aVMArray.SetBytes (fView.BackgroundByte (0));

	RedoIt

	END;

{*****************************************************************************}

{$S AChannel}

PROCEDURE TNewChannelCommand.UndoIt; OVERRIDE;

	PROCEDURE FixUpView (view: TImageView);
		BEGIN

		IF view.fChannel >= fDoc.fChannels THEN
			BEGIN
			view.fChannel := fOldChannel;
			view.ReDither (TRUE)
			END;

		view.UpdateWindowTitle

		END;

	BEGIN

	fDoc.fChannels := fDoc.fChannels - 1;

	fBuffer [0] := fDoc.fData [fDoc.fChannels];
	fDoc.fData [fDoc.fChannels] := NIL;

	IF fDoc.fChannels = 1 THEN
		fDoc.fMode := MonochromeMode;

	fDoc.fViewList.Each (FixUpView)

	END;

{*****************************************************************************}

{$S AChannel}

PROCEDURE TNewChannelCommand.RedoIt; OVERRIDE;

	PROCEDURE FixUpView (view: TImageView);
		BEGIN

		IF view = gTarget THEN
			BEGIN
			view.fChannel := fDoc.fChannels - 1;
			view.ReDither (TRUE)
			END;

		view.UpdateWindowTitle

		END;

	BEGIN

	fDoc.fData [fDoc.fChannels] := fBuffer [0];
	fBuffer [0] := NIL;

	fDoc.fChannels := fDoc.fChannels + 1;

	IF fDoc.fMode = MonochromeMode THEN
		fDoc.fMode := MultichannelMode;

	fDoc.fViewList.Each (FixUpView)

	END;

{*****************************************************************************}

{$S AChannel}

FUNCTION DoNewChannel (view: TImageView): TCommand;

	VAR
		aNewChannelCommand: TNewChannelCommand;

	BEGIN

	NEW (aNewChannelCommand);
	FailNil (aNewChannelCommand);

	aNewChannelCommand.INewChannelCommand (view);

	DoNewChannel := aNewChannelCommand

	END;

{*****************************************************************************}

{$S AChannel}

PROCEDURE GetColorLetters (mode: TDisplayMode; VAR s: Str255);

	CONST
		kLettersID = 1004;

	BEGIN

		CASE mode OF

		RGBColorMode:
			GetIndString (s, kLettersID, 1);

		SeparationsCMYK:
			GetIndString (s, kLettersID, 2);

		SeparationsHSL:
			GetIndString (s, kLettersID, 3);

		SeparationsHSB:
			GetIndString (s, kLettersID, 4);

		OTHERWISE
			s := ''

		END

	END;

{*****************************************************************************}

{$S AChannel}

PROCEDURE TSplitChannels.DoIt; OVERRIDE;

	CONST
		kWindowOverhead = 12 * 1024;

		kLettersID = 1004;

	VAR
		s: Str255;
		fi: FailInfo;
		rows: INTEGER;
		cols: INTEGER;
		title: Str255;
		buffer: Handle;
		channel: INTEGER;
		channels: INTEGER;
		mode: TDisplayMode;
		doc: TImageDocument;
		styleInfo: TStyleInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		doc.Free;
		Failure (1, 0)
		END;

	BEGIN

	fCanUndo := FALSE;

	fDoc.DeSelect (TRUE);

	rows	  := fDoc.fRows;
	cols	  := fDoc.fCols;
	channels  := fDoc.fChannels;
	mode	  := fDoc.fMode;
	title	  := fDoc.fTitle;
	styleInfo := fDoc.fStyleInfo;

	buffer := NewPermHandle (ORD4 (channels - 1) * kWindowOverhead);
	FailNil (buffer);

	IF MemSpaceIsLow THEN
		BEGIN
		DisposHandle (buffer);
		Failure (memFullErr, 0)
		END;

	DisposHandle (buffer);

	FOR channel := 0 TO channels - 1 DO
		BEGIN
		fBuffer [channel]	 := fDoc.fData [channel];
		fDoc.fData [channel] := NIL
		END;

	fDoc.Close;

	gStaggerCount := 0;

	IF LENGTH (title) > 56 THEN
		DELETE (title, 57, LENGTH (title) - 56);

	FOR channel := 0 TO channels - 1 DO
		BEGIN

		doc := TImageDocument (gApplication.DoMakeDocument (cSplitChannels));

		CatchFailures (fi, CleanUp);

		doc.fRows := rows;
		doc.fCols := cols;

		doc.fData [0] := fBuffer [channel];

		fBuffer [channel] := NIL;

		doc.DefaultMode;

		doc.fStyleInfo := styleInfo;

		IF mode = SeparationsCMYK THEN
			WITH doc.fStyleInfo DO
				IF channel <= 3 THEN
					BEGIN
					fHalftoneSpec := fHalftoneSpecs [channel];
					fTransferSpec := fTransferSpecs [channel]
					END
				ELSE
					BEGIN
					fHalftoneSpec := fHalftoneSpecs [3];
					fTransferSpec := fTransferSpecs [3]
					END;

		doc.fChangeCount := 1;

		GetColorLetters (mode, s);

		IF channel >= LENGTH (s) THEN
			NumToString (channel + 1, s)
		ELSE
			BEGIN
			s [1] := s [channel + 1];
			DELETE (s, 2, LENGTH (s) - 1)
			END;

		INSERT ('.', s, 1);
		INSERT (title, s, 1);

		doc.fTitle := s;

		doc.DoMakeViews (kForDisplay);
		doc.DoMakeWindows;

		gApplication.AddDocument (doc);

		doc.ShowWindows;

		Success (fi)

		END

	END;

{*****************************************************************************}

{$S AChannel}

FUNCTION DoSplitChannels (view: TImageView): TCommand;

	VAR
		aSplitChannels: TSplitChannels;

	BEGIN

	NEW (aSplitChannels);
	FailNil (aSplitChannels);

	aSplitChannels.IBufferCommand (cSplitChannels, view);

	DoSplitChannels := aSplitChannels

	END;

{*****************************************************************************}

{$S AChannel}

PROCEDURE TMergeChannels.IMergeChannels (view: TImageView);

	VAR
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Free
		END;

	BEGIN

	IBufferCommand (cMergeChannels, view);

	fCanUndo := FALSE;
	fChangedDocument := NIL;

	CatchFailures (fi, CleanUp);

	IF NOT GuessMode (RGBColorMode) THEN
		IF NOT GuessMode (SeparationsCMYK) THEN
			IF NOT GuessMode (SeparationsHSL) THEN
				IF NOT GuessMode (SeparationsHSB) THEN
					IF NOT GuessMode (MultichannelMode) THEN
						Failure (1, 0);

	GetMode;

	GetList;

	Success (fi)

	END;

{*****************************************************************************}

{$S AChannel}

PROCEDURE TMergeChannels.ForAllLegalDocuments
				(PROCEDURE DoToIt (doc: TImageDocument));

	PROCEDURE TestDoc (doc: TImageDocument);
		BEGIN

		IF (doc.fMode = MonochromeMode) AND
		   (doc.fRows = fDoc.fRows) AND
		   (doc.fCols = fDoc.fCols) THEN DoToIt (doc)

		END;

	BEGIN

	gApplication.ForAllDocumentsDo (TestDoc)

	END;

{*****************************************************************************}

{$S AChannel}

FUNCTION TMergeChannels.GuessMode (mode: TDisplayMode): BOOLEAN;

	VAR
		base: Str255;
		letters: Str255;

	PROCEDURE ScanDocument (doc: TImageDocument);

		VAR
			c: CHAR;
			s: Str255;
			channel: INTEGER;

		BEGIN

		fLegalCount := fLegalCount + 1;

		IF LENGTH (letters) = 0 THEN
			BEGIN

			fChannels := fChannels + 1;

			doc.fMergeDefault := fChannels

			END

		ELSE
			BEGIN

			doc.fMergeDefault := 0;

			s := doc.fTitle;

			IF LENGTH (s) <> 0 THEN
				BEGIN

				c := s [LENGTH (s)];

				IF (c >= 'a') AND (c <= 'z') THEN
					c := CHR (ORD (c) - ORD ('a') + ORD ('A'));

				DELETE (s, LENGTH (s), 1);

				IF (s = base) AND (c <> ' ') THEN
					FOR channel := 1 TO LENGTH (letters) DO
						IF c = letters [channel] THEN
							BEGIN

							fChannels := fChannels + 1;

							doc.fMergeDefault := channel;

							letters [channel] := ' '

							END

				END

			END

		END;

	BEGIN

	{$IFC qBarneyscan}
	IF mode = SeparationsCMYK THEN
		BEGIN
		GuessMode := FALSE;
		EXIT (GuessMode)
		END;
	{$ENDC}

	base := fDoc.fTitle;

	IF LENGTH (base) <> 0 THEN
		DELETE (base, LENGTH (base), 1);

	GetColorLetters (mode, letters);

	fMode := mode;

	fChannels := 0;

	fLegalCount := 0;

	ForAllLegalDocuments (ScanDocument);

	fChannels := Min (fChannels, kMaxChannels);

	fLegalCount := Min (fLegalCount, kMaxChannels);

	GuessMode := (fChannels >= 2) AND
				 (fChannels >= LENGTH (letters))

	END;

{*****************************************************************************}

{$S AChannel}

PROCEDURE TMergeChannels.GetMode;

	CONST
		kModeID 	   = 1020;
		kHookItem	   = 3;
		kChannelsItem  = 4;
		kRGBModeItem   = 5;
		kCMYKModeItem  = 6;
		kHSLModeItem   = 7;
		kHSBModeItem   = 8;
		kMultiModeItem = 9;

	VAR
		fi: FailInfo;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		channelsText: TFixedText;
		radioCluster: TRadioCluster;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
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

	PROCEDURE EnableButton (anItem: INTEGER; state: BOOLEAN);

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

	PROCEDURE MyItemHandling (anItem: INTEGER; VAR done: BOOLEAN);

		BEGIN

		StdItemHandling (anItem, done);

		fMode := TDisplayMode (ORD (RGBColorMode) +
							   radioCluster.fChosenItem -
							   kRGBModeItem);

		IF fMode = SeparationsCMYK THEN
			fChannels := 4
		ELSE
			fChannels := 3;

		IF fMode <> MultichannelMode THEN
			CASE anItem OF

			kChannelsItem:
				IF NOT channelsText.ParseValue OR
						(channelsText.fValue <> fChannels) THEN
					BEGIN
					SetItem (radioCluster.fChosenItem, FALSE);
					radioCluster.fChosenItem := kMultiModeItem;
					SetItem (radioCluster.fChosenItem, TRUE)
					END;

			kRGBModeItem..kMultiModeItem:
				BEGIN
				IF channelsText.ParseValue THEN
					IF channelsText.fValue = fChannels THEN
						EXIT (MyItemHandling);
				channelsText.StuffValue (fChannels);
				aBWDialog.SetEditSelection (kChannelsItem)
				END

			END

		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kModeID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	radioCluster := aBWDialog.DefineRadioCluster
						(kRGBModeItem, kMultiModeItem,
						 kRGBModeItem + ORD (fMode) - ORD (RGBColorMode));

	channelsText := aBWDialog.DefineFixedText
						(kChannelsItem, 0, FALSE, TRUE, 2, fLegalCount);

	channelsText.StuffValue (fChannels);

	aBWDialog.SetEditSelection (kChannelsItem);

	EnableButton (kRGBModeItem , fLegalCount >= 3);
	EnableButton (kCMYKModeItem, fLegalCount >= 4);
	EnableButton (kHSLModeItem , fLegalCount >= 3);
	EnableButton (kHSBModeItem , fLegalCount >= 3);

	aBWDialog.TalkToUser (hitItem, MyItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	fMode := TDisplayMode (ORD (RGBColorMode) +
						   radioCluster.fChosenItem - kRGBModeItem);

		CASE fMode OF

		MultichannelMode:
			fChannels := channelsText.fValue;

		SeparationsCMYK:
			fChannels := 4;

		OTHERWISE
			fChannels := 3

		END;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S AChannel}

PROCEDURE TMergeChannels.GetList;

	CONST
		kBaseDialogID = 1021;
		kHookItem	  = 3;
		kLabelItem	  = 4;
		kMenuItem	  = 5;
		kHiddenItem   = 6;
		kSameDocID	  = 910;
		kMenuID 	  = 9999;

	VAR
		s: Str255;
		fi: FailInfo;
		pick: INTEGER;
		itemBox: Rect;
		other: INTEGER;
		menu: MenuHandle;
		channel: INTEGER;
		default: INTEGER;
		hitItem: INTEGER;
		sameDoc: BOOLEAN;
		itemType: INTEGER;
		itemHandle: Handle;
		aBWDialog: TBWDialog;
		aPopUpMenu: TPopUpMenu;
		pickedDoc: TImageDocument;
		thePopUpMenus: ARRAY [1..4] OF TPopUpMenu;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		DisposeMenu (menu);
		aBWDialog.Free
		END;

	PROCEDURE AddDocToMenu (doc: TImageDocument);
		BEGIN
		s := doc.fTitle;
		IF s[1] = '-' THEN s[1] := CHR ($D0);
		AppendMenu (menu, 'Dummy');
		doc.fMergeItem := CountMItems (menu);
		SetItem (menu, doc.fMergeItem, s)
		END;

	PROCEDURE FindDefault (doc: TImageDocument);
		BEGIN
		IF doc.fMergeDefault = channel THEN
			default := doc.fMergeItem
		END;

	PROCEDURE DecodePick (doc: TImageDocument);
		BEGIN
		IF pick = doc.fMergeItem THEN
			pickedDoc := doc
		END;

	PROCEDURE AdjustItem (doc: TImageDocument);
		BEGIN
		IF doc.fMergeItem > pickedDoc.fMergeItem THEN
			doc.fMergeItem := doc.fMergeItem - 1
		END;

	BEGIN

	menu := NewMenu (kMenuID, '');

	ForAllLegalDocuments (AddDocToMenu);

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kBaseDialogID + ORD (fMode) - ORD (RGBColorMode),
						 kHookItem, ok);

	CatchFailures (fi, CleanUp);

	IF fMode = MultichannelMode THEN
		BEGIN

		aPopUpMenu := aBWDialog.DefinePopUpMenu
				(kLabelItem, kMenuItem, menu, 1);

		FOR channel := 1 TO fChannels DO
			BEGIN

			NumToString (channel, s);
			ParamText (s, '', '', '');

			IF channel = fChannels THEN
				BEGIN
				GetDItem (aBWDialog.fDialogPtr, kHiddenItem,
						  itemType, itemHandle, itemBox);
				GetCTitle (ControlHandle (itemHandle), s);
				GetDItem (aBWDialog.fDialogPtr, ok,
						  itemType, itemHandle, itemBox);
				SetCTitle (ControlHandle (itemHandle), s)
				END;

			IF channel <> 1 THEN
				BEGIN
				DrawDialog (aBWDialog.fDialogPtr);
				aPopUpMenu.SetMenu (menu, 1)
				END;

			aBWDialog.TalkToUser (hitItem, StdItemHandling);

			IF hitItem <> ok THEN Failure (0, 0);

			pick := aPopUpMenu.fPick;

			ForAllLegalDocuments (DecodePick);

			fMergeList [channel] := pickedDoc;

			DelMenuItem (menu, pickedDoc.fMergeItem);

			ForAllLegalDocuments (AdjustItem)

			END

		END

	ELSE
		BEGIN

		FOR channel := 1 TO fChannels DO
			BEGIN

			default := 1;

			ForAllLegalDocuments (FindDefault);

			thePopUpMenus [channel] :=
					aBWDialog.DefinePopUpMenu (kLabelItem + 2 * (channel - 1),
											   kMenuItem  + 2 * (channel - 1),
											   menu, default)

			END;

		WHILE TRUE DO
			BEGIN

			aBWDialog.TalkToUser (hitItem, StdItemHandling);

			IF hitItem <> ok THEN Failure (0, 0);

			FOR channel := 1 TO fChannels DO
				BEGIN

				pick := thePopUpMenus [channel] . fPick;

				ForAllLegalDocuments (DecodePick);

				fMergeList [channel] := pickedDoc

				END;

			sameDoc := FALSE;

			FOR channel := 1 TO fChannels - 1 DO
				FOR other := channel + 1 TO fChannels DO
					IF fMergeList [channel] = fMergeList [other] THEN
						sameDoc := TRUE;

			IF NOT sameDoc THEN LEAVE;

			BWNotice (kSameDocID, TRUE)

			END

		END;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S AChannel}

PROCEDURE TMergeChannels.DoIt; OVERRIDE;

	VAR
		s: Str255;
		fi: FailInfo;
		rows: INTEGER;
		cols: INTEGER;
		channel: INTEGER;
		style: TStyleInfo;
		doc: TImageDocument;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		doc.Free;
		Failure (1, 0)
		END;

	BEGIN

	rows := fDoc.fRows;
	cols := fDoc.fCols;

	FOR channel := 1 TO fChannels DO
		BEGIN

		doc := fMergeList [channel];

		IF channel = 1 THEN style := doc.fStyleInfo;

		fBuffer [channel - 1] := doc.fData [0];
		doc.fData [0] := NIL;

		doc.Close

		END;

	gStaggerCount := 0;

	doc := TImageDocument (gApplication.DoMakeDocument (cMergeChannels));

	CatchFailures (fi, CleanUp);

	doc.fRows := rows;
	doc.fCols := cols;

	doc.fMode := fMode;
	doc.fChannels := fChannels;

	doc.fStyleInfo := style;

	FOR channel := 0 TO fChannels - 1 DO
		BEGIN
		doc.fData [channel] := fBuffer [channel];
		fBuffer [channel] := NIL
		END;

	doc.fChangeCount := 1;

	doc.UntitledName (s);
	doc.SetTitle (s);

	doc.DoMakeViews (kForDisplay);
	doc.DoMakeWindows;

	gApplication.AddDocument (doc);

	doc.ShowWindows;

	Success (fi)

	END;

{*****************************************************************************}

{$S AChannel}

FUNCTION DoMergeChannels (view: TImageView): TCommand;

	VAR
		aMergeChannels: TMergeChannels;

	BEGIN

	NEW (aMergeChannels);
	FailNil (aMergeChannels);

	aMergeChannels.IMergeChannels (view);

	DoMergeChannels := aMergeChannels

	END;

{*****************************************************************************}

END.

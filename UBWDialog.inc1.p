{Photoshop version 1.0.1, file: UBWDialog.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

VAR
	gNoChar: CHAR;
	gYesChar: CHAR;

	gNoItem: INTEGER;
	gYesItem: INTEGER;
	gCancelItem: INTEGER;

	gErrorRect: Rect;
	gErrorCode: INTEGER;

{*****************************************************************************}

{$S ARes2}

PROCEDURE ComputeCentered (VAR where: Point;
						   width, height: INTEGER;
						   titled: BOOLEAN);

	VAR
		offset: INTEGER;

	BEGIN

	IF titled THEN
		offset := gMBarHeight + 18
	ELSE
		offset := gMBarHeight;

	where.h := BSR (screenBits.bounds.right - width, 1);

	where.v := (screenBits.bounds.bottom - offset - height) DIV 3 + offset

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE CenterWindow (wp: WindowPtr; titled: BOOLEAN);

	VAR
		r: Rect;
		where: Point;

	BEGIN

	SetPort (wp);

	r := wp^.portRect;

	LocalToGlobal (r.topLeft);
	LocalToGlobal (r.botRight);

	ComputeCentered (where, r.right, r.bottom, titled);

	MoveWindow (wp, where.h, where.v, FALSE)

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TBWDialog.IBWDialog (itsRsrcID: INTEGER;
							   itsHookItem: INTEGER;
							   itsDfltButton: INTEGER);

	VAR
		r: Rect;
		s: Str255;
		s1: Str255;
		item: INTEGER;
		dt: DialogTHndl;
		titled: BOOLEAN;
		itemList: Handle;
		itemType: INTEGER;
		itemCount: INTEGER;
		itemHandle: Handle;

	BEGIN

	HiliteGhosts (FALSE);

	titled := FALSE;

	dt := DialogTHndl (GetResource ('DLOG', itsRsrcID));

	IF dt <> NIL THEN
		titled := (dt^^.procID = 50);

	IDialogView (NIL, NIL, itsRsrcID,
				 itsHookItem, itsDfltButton, TRUE);

	CenterWindow (fDialogPtr, titled);

	fCancelItem := 0;

	CmdToName (cCancel, s1);

	itemList  := DialogPeek (fDialogPtr)^.items;
	itemCount := PInteger (itemList^)^ + 1;

	FOR item := 1 TO itemCount DO
		BEGIN
		GetDItem (fDialogPtr, item, itemType, itemHandle, r);
		IF itemType = ctrlItem + btnCtrl THEN
			BEGIN
			GetCTitle (ControlHandle (itemHandle), s);
			IF s = s1 THEN fCancelItem := item
			END
		END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TBWDialog.Free; OVERRIDE;

	BEGIN

	HiliteGhosts (TRUE);

	SetCursor (arrow);

	INHERITED Free

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION TBWDialog.DefineFixedText (itsItemNumber: INTEGER;
									places: INTEGER;
									blankOK: BOOLEAN;
									trim: BOOLEAN;
									minValue: LONGINT;
									maxValue: LONGINT): TFixedText;

	VAR
		aFixedText: TFixedText;

	BEGIN

	NEW (aFixedText);
	FailNil (aFixedText);

	aFixedText.IFixedText (itsItemNumber, SELF,
						   places, blankOK, trim, minValue, maxValue);

	DefineFixedText := aFixedText

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION TBWDialog.DefinePopUpMenu (itsLabelNumber: INTEGER;
									itsItemNumber: INTEGER;
									menu: MenuHandle;
									pick: INTEGER): TPopUpMenu;

	VAR
		aPopUpMenu: TPopUpMenu;

	BEGIN

	NEW (aPopUpMenu);
	FailNil (aPopUpMenu);

	aPopUpMenu.IPopUpMenu (itsLabelNumber, itsItemNumber, SELF, menu, pick);

	DefinePopUpMenu := aPopUpMenu

	END;

{*****************************************************************************}

{$S AUnits}

FUNCTION TBWDialog.DefineUnitSelector (itsItemNumber: INTEGER;
									   editItemNumber: INTEGER;
									   editItemCount: INTEGER;
									   blankOK: BOOLEAN;
									   menuID: INTEGER;
									   pick: INTEGER): TUnitSelector;

	VAR
		aUnitSelector: TUnitSelector;

	BEGIN

	NEW (aUnitSelector);
	FailNil (aUnitSelector);

	aUnitSelector.IUnitSelector (SELF, itsItemNumber, editItemNumber,
								 editItemCount, blankOK, menuID, pick);

	DefineUnitSelector := aUnitSelector

	END;

{*****************************************************************************}

{$S AUnits}

FUNCTION TBWDialog.DefineResUnit (item: INTEGER;
								  scale: INTEGER;
								  pixels: INTEGER): TUnitSelector;

	CONST
		kResMenu = 1002;

	VAR
		lower1: LONGINT;
		lower2: LONGINT;
		aUnit: TUnitSelector;

	BEGIN

	aUnit := DefineUnitSelector (item + 1, item, 1, FALSE, kResMenu, scale);

	IF pixels = 0 THEN
		BEGIN
		lower1 := 1;
		lower2 := 1
		END
	ELSE
		BEGIN
		lower1 := Max (1, TRUNC (pixels / (kMaxCoord / 72)		  * 1000));
		lower2 := Max (1, TRUNC (pixels / (kMaxCoord / 72 * 2.54) * 1000))
		END;

	aUnit.DefineUnit (1   , 0, 3, lower1, 3200000);
	aUnit.DefineUnit (2.54, 0, 3, lower2, 1260000);

	DefineResUnit := aUnit

	END;

{*****************************************************************************}

{$S AUnits}

FUNCTION TBWDialog.DefinePrintResUnit (item: INTEGER;
									   scale: INTEGER): TUnitSelector;

	CONST
		kResMenu = 1006;

	VAR
		aUnit: TUnitSelector;

	BEGIN

	aUnit := DefineUnitSelector (item + 1, item, 1, FALSE, kResMenu, scale);

	aUnit.DefineUnit (1   , 0, 1, 1, 32000);
	aUnit.DefineUnit (2.54, 0, 1, 1, 12600);

	DefinePrintResUnit := aUnit

	END;

{*****************************************************************************}

{$S AUnits}

FUNCTION TBWDialog.DefineFreqUnit (item: INTEGER;
								   count: INTEGER;
								   scale: INTEGER): TUnitSelector;

	CONST
		kFreqMenu = 1005;

	VAR
		aUnit: TUnitSelector;

	BEGIN

	aUnit := DefineUnitSelector (item + count, item, count,
								 FALSE, kFreqMenu, scale);

	aUnit.DefineUnit (1   , 0, 3, 1000, 999999);
	aUnit.DefineUnit (2.54, 0, 3,  400, 400000);

	DefineFreqUnit := aUnit

	END;

{*****************************************************************************}

{$S AUnits}

FUNCTION TBWDialog.DefineSizeUnit (item: INTEGER;
								   scale: INTEGER;
								   blankOK: BOOLEAN;
								   allowPixels: BOOLEAN;
								   allowColumns: BOOLEAN;
								   allowZero: BOOLEAN;
								   allowLarge: BOOLEAN): TUnitSelector;

	CONST
		kWidthMenu	 = 1003;
		kHeightMenu  = 1004;
		kPWidthMenu  = 1007;
		kPHeightMenu = 1008;

	VAR
		menu: INTEGER;
		lower: LONGINT;
		upper: LONGINT;
		colBase: EXTENDED;
		colScale: EXTENDED;
		aUnit: TUnitSelector;

	BEGIN

	IF allowPixels THEN
		IF allowColumns THEN
			menu := kPWidthMenu
		ELSE
			menu := kPHeightMenu
	ELSE
		IF allowColumns THEN
			menu := kWidthMenu
		ELSE
			menu := kHeightMenu;

	aUnit := DefineUnitSelector (item + 1, item, 1, blankOK, menu, scale);

	IF allowPixels THEN
		aUnit.DefineUnit (1, 0, 0, 1, kMaxCoord);

	IF allowZero THEN
		lower := 0
	ELSE
		lower := 1;

	IF allowLarge THEN
		BEGIN
		aUnit.DefineUnit (1 	, 0, 3, lower, 416667);
		aUnit.DefineUnit (1/2.54, 0, 2, lower, 105833);
		aUnit.DefineUnit (1/72	, 0, 1, lower, 300000);
		aUnit.DefineUnit (1/6	, 0, 2, lower, 250000)
		END
	ELSE
		BEGIN
		aUnit.DefineUnit (1 	, 0, 3, lower, 8000);
		aUnit.DefineUnit (1/2.54, 0, 2, lower, 2000);
		aUnit.DefineUnit (1/72	, 0, 1, lower, 6000);
		aUnit.DefineUnit (1/6	, 0, 2, lower, 5000)
		END;

	IF allowColumns THEN
		BEGIN

		colScale := (gPreferences.fColumnWidth.value +
					 gPreferences.fColumnGutter.value) / 65536;

		colBase := -gPreferences.fColumnGutter.value / 65536;

		upper := ROUND (400 / colScale) * 1000;

		aUnit.DefineUnit (colScale, colBase, 3, lower, upper)

		END;

	DefineSizeUnit := aUnit

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TBWDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

	PROCEDURE DrawPopUpMenus (aView: TView; VAR done: BOOLEAN);
		BEGIN
		IF Member (aView, TPopUpMenu) THEN
			TPopUpMenu (aView) . DrawPopUpMenu
		END;

	BEGIN

	INHERITED DrawAmendments (theItem);

	EachChild (DrawPopUpMenus)

	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ARes2}

PROCEDURE TBWDialog.DoFilterEvent (VAR anEvent: EventRecord;
								   VAR itemHit: INTEGER;
								   VAR handledIt: BOOLEAN;
								   VAR doReturn: BOOLEAN); OVERRIDE;

	VAR
		c: CHAR;
		pt: Point;
		ignore: TCommand;
		cmdDown: BOOLEAN;
		optDown: BOOLEAN;
		haveSelection: BOOLEAN;

	PROCEDURE DoPopUpMenus (aView: TView; VAR done: BOOLEAN);

		VAR
			aPopUpMenu: TPopUpMenu;

		BEGIN

		IF Member (aView, TPopUpMenu) THEN
			BEGIN

			aPopUpMenu := TPopUpMenu (aView);

			IF PtInRect (pt, aPopUpMenu.fMenuRect) THEN
				BEGIN

				IF aPopUpMenu.DoPopUpMenu (optDown) THEN
					BEGIN
					doReturn := TRUE;
					itemHit := aPopUpMenu.fItemNumber
					END
				ELSE
					anEvent.what := nullEvent

				END

			END

		END;

	BEGIN

	cmdDown := BAND (anEvent.modifiers, cmdKey	 ) <> 0;
	optDown := BAND (anEvent.modifiers, optionKey) <> 0;

	c := CHR (BAND (anEvent.message, charCodeMask));

	IF (anEvent.what = keyDown) & (fCancelItem <> 0) THEN
		BEGIN

		IF (c = kEscapeChar) | ((c = '.') & cmdDown) THEN
			BEGIN
			doReturn := TRUE;
			itemHit := fCancelItem;
			FlashButton (fDialogPtr, itemHit);
			EXIT (DoFilterEvent)
			END

		END;

	IF DialogPeek (fDialogPtr)^.textH <> NIL THEN
		IF (anEvent.what = keyDown) AND cmdDown THEN
			BEGIN

			WITH DialogPeek (fDialogPtr)^.textH^^ DO
				haveSelection := selEnd > selStart;

			anEvent.what := nullEvent;

				CASE c OF

				'X', 'x':
					IF haveSelection THEN
						BEGIN
						DlgCut (fDialogPtr);
						IF ZeroScrap = noErr THEN
							IF TEToScrap = noErr THEN
								IF gInitializedPS THEN
									CheckDeskScrap
						END;

				'C', 'c':
					IF haveSelection THEN
						BEGIN
						DlgCopy (fDialogPtr);
						IF ZeroScrap = noErr THEN
							IF TEToScrap = noErr THEN
								IF gInitializedPS THEN
									CheckDeskScrap
						END;

				'V', 'v':
					IF TEFromScrap = noErr THEN
						DlgPaste (fDialogPtr);

				OTHERWISE
					anEvent.what := keyDown

				END

			END;

	INHERITED DoFilterEvent (anEvent, itemHit, handledIt, doReturn);

	IF anEvent.what = mouseDown THEN
		BEGIN

		SetPort (fDialogPtr);

		pt := anEvent.where;

		GlobalToLocal (pt);

		EachChild (DoPopUpMenus)

		END

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S ARes2}

FUNCTION TBWDialog.DoItemSelected
		(anItem: INTEGER;
		 VAR handledIt: BOOLEAN;
		 VAR doneWithDialog: BOOLEAN): TCommand; OVERRIDE;

	VAR
		itsBox: Rect;
		itsType: INTEGER;
		itsHandle: Handle;
		found: TKeyHandler;

	PROCEDURE TryView (aView: TView; VAR done: BOOLEAN);

		VAR
			thisBox: Rect;
			this: TKeyHandler;

		BEGIN

		IF MEMBER (aView, TKeyHandler) THEN
			BEGIN

			this := TKeyHandler (aView);

			GetDItem (fDialogPtr, this.fItemNumber,
					  itsType, itsHandle, thisBox);

			IF (thisBox.top = itsBox.top) &
			   (thisBox.bottom = itsBox.bottom) &
			   (ABS (thisBox.left - itsBox.right) <= 10) THEN
				BEGIN
				done := TRUE;
				found := this
				END

			END

		END;

	BEGIN

	DoItemSelected := INHERITED DoItemSelected (anItem,
												handledIt,
												doneWithDialog);

	IF NOT handledIt THEN
		BEGIN

		GetDItem (fDialogPtr, anItem, itsType, itsHandle, itsBox);

		IF itsType = statText THEN
			BEGIN

			found := NIL;

			EachChild (TryView);

			IF found = NIL THEN found := fKeyHandler;

			IF found <> NIL THEN
				SetEditSelection (found.fItemNumber)

			END

		END;

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE DrawOutline (aDialog: DialogPtr; item: INTEGER);

	VAR
		r: Rect;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	GetDItem (aDialog, 1, itemType, itemHandle, r);

	InsetRect (r, -4, -4);

	PenSize (3, 3);

	FrameRoundRect (r, 16, 16)

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE DrawError (aDialog: DialogPtr; item: INTEGER);

	VAR
		s: Str255;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	TextFont (geneva);
	TextSize (9);

	NumToString (gErrorCode, s);

	MoveTo (gErrorRect.left, gErrorRect.bottom + 2);

	DrawString (s);

	TextFont (0);
	TextSize (0)

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION AlertFilter (theDialog: DialogPtr;
					  VAR theEvent: EventRecord;
					  VAR itemHit: INTEGER): BOOLEAN;

	VAR
		c: CHAR;
		cmdDown: BOOLEAN;

	BEGIN

	AlertFilter := FALSE;

	IF theEvent.what = keyDown THEN
		BEGIN

		c := CHR (BAND (theEvent.message, charCodeMask));

		IF (c >= 'a') AND (c <= 'z') THEN
			c := CHR (ORD (c) - ORD ('a') + ORD ('A'));

		cmdDown := BAND (theEvent.modifiers, cmdKey) <> 0;

		IF (c = kEnterChar) | (c = kReturnChar) THEN
			itemHit := ok

		ELSE IF (gYesItem <> 0) & (c = gYesChar) THEN
			itemHit := gYesItem

		ELSE IF (gNoItem <> 0) & (c = gNoChar) THEN
			itemHit := gNoItem

		ELSE IF (gCancelItem <> 0) &
				((c = kEscapeChar) | ((c = '.') & cmdDown)) THEN
			itemHit := gCancelItem

		ELSE
			EXIT (AlertFilter);

		FlashButton (theDialog, itemHit);

		AlertFilter := TRUE

		END

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION BWAlert (itsRsrcID: INTEGER; error: INTEGER; beep: BOOLEAN): INTEGER;

	VAR
		r: Rect;
		s: Str255;
		s1: Str255;
		s2: Str255;
		s3: Str255;
		dp: DialogPtr;
		item: INTEGER;
		itemList: Handle;
		itemType: INTEGER;
		itemCount: INTEGER;
		itemHandle: Handle;

	BEGIN

	dp := GetNewDialog (itsRsrcID, NIL, WindowPtr (-1));

	GetDItem (dp, 3, itemType, itemHandle, r);
	SetDItem (dp, 3, itemType, Handle (@DrawOutline), r);

	IF error <> 0 THEN
		BEGIN

		GetDItem (dp, 4, itemType, itemHandle, r);
		SetDItem (dp, 4, itemType, Handle (@DrawError), r);

		gErrorCode := error;
		gErrorRect := r

		END;

	gYesItem	:= 0;
	gNoItem 	:= 0;
	gCancelItem := 0;

	CmdToName (cYes   , s1);
	CmdToName (cNo	  , s2);
	CmdToName (cCancel, s3);

	gYesChar := s1 [1];
	gNoChar  := s2 [1];

	itemList  := DialogPeek (dp)^.items;
	itemCount := PInteger (itemList^)^ + 1;

	FOR item := 1 TO itemCount DO
		BEGIN
		GetDItem (dp, item, itemType, itemHandle, r);
		IF itemType = ctrlItem + btnCtrl THEN
			BEGIN
			GetCTitle (ControlHandle (itemHandle), s);
			IF s = s1 THEN gYesItem    := item;
			IF s = s2 THEN gNoItem	   := item;
			IF s = s3 THEN gCancelItem := item
			END
		END;

	IF gYesChar = gNoChar THEN
		BEGIN
		gYesItem := 0;
		gNoItem  := 0
		END;

	CenterWindow (dp, FALSE);

	IF beep THEN SysBeep (1);

	ShowWindow (dp);

	SetCursor (arrow);

	ModalDialog (@AlertFilter, item);

	DisposDialog (dp);

	BWAlert := item

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE BWNotice (itsRsrcID: INTEGER; beep: BOOLEAN);

	VAR
		item: INTEGER;

	BEGIN

	item := BWAlert (itsRsrcID, 0, beep)

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TFixedText.IFixedText (itsItemNumber: INTEGER;
								 itsParent: TDialogView;
								 places: INTEGER;
								 blankOK: BOOLEAN;
								 trim: BOOLEAN;
								 minValue: LONGINT;
								 maxValue: LONGINT);

	BEGIN

	IKeyHandler (itsItemNumber, itsParent);

	fPlaces   := places;
	fBlankOK  := blankOK;
	fTrim	  := trim;
	fMinValue := minValue;
	fMaxValue := maxValue

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE ConvertFixed (value: LONGINT; places: INTEGER;
						trim: BOOLEAN; VAR s: Str255);

	VAR
		j: INTEGER;
		f: LONGINT;
		n: LONGINT;
		c: STRING [1];
		negative: BOOLEAN;

	BEGIN

	negative := (value < 0);

	n := ABS (value);
	f := 0;

	FOR j := 1 TO places DO
		BEGIN
		f := f * 10 + n MOD 10;
		n := n DIV 10
		END;

	NumToString (n, s);

	IF places > 0 THEN
		BEGIN

		c := ' ';
		c [1] := gDecimalPt;

		INSERT (c, s, LENGTH (s) + 1);

		FOR j := 1 TO places DO
			BEGIN
			n := f MOD 10;
			f := f DIV 10;
			c [1] := CHR (ORD ('0') + n);
			INSERT (c, s, LENGTH (s) + 1)
			END;

		IF trim THEN
			BEGIN

			WHILE s [LENGTH (s)] = '0' DO
				DELETE (s, LENGTH (s), 1);

			IF s [LENGTH (s)] = gDecimalPt THEN
				DELETE (s, LENGTH (s), 1)

			END

		END;

	IF negative THEN INSERT ('-', s, 1)

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TFixedText.StuffValue (value: LONGINT);

	VAR
		s: Str255;

	BEGIN

	ConvertFixed (value, fPlaces, fTrim, s);

	StuffString (s)

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION TFixedText.ParseValue: BOOLEAN;

	VAR
		s: Str255;
		j: INTEGER;
		n: LONGINT;
		decimal: INTEGER;
		negative: BOOLEAN;

	BEGIN

	fValue := 0;
	fNumber := FALSE;

	ParseValue := FALSE;

	GetIText (fItemHandle, s);

	FOR j := LENGTH (s) DOWNTO 1 DO
		BEGIN
		IF s [j] <> ' ' THEN LEAVE;
		DELETE (s, LENGTH (s), 1)
		END;

	fBlank := (LENGTH (s) = 0);

	IF fBlank THEN
		BEGIN
		ParseValue := fBlankOK;
		EXIT (ParseValue)
		END;

	WHILE s [1] = ' ' DO
		DELETE (s, 1, 1);

	negative := (s [1] = '-');

	IF negative THEN
		BEGIN
		DELETE (s, 1, 1);
		IF LENGTH (s) = 0 THEN EXIT (ParseValue)
		END;

	decimal := LENGTH (s) + 1;

	FOR j := 1 TO LENGTH (s) DO
		IF s [j] = gDecimalPt THEN
			IF decimal < j THEN
				EXIT (ParseValue)
			ELSE
				decimal := j
		ELSE IF (s [j] < '0') OR (s [j] > '9') THEN
			EXIT (ParseValue);

	IF decimal <> LENGTH (s) + 1 THEN
		BEGIN
		DELETE (s, decimal, 1);
		IF (LENGTH (s) = 0) OR (fPlaces = 0) THEN EXIT (ParseValue)
		END;

	WHILE LENGTH (s) < decimal + fPlaces - 1 DO
		INSERT ('0', s, LENGTH (s) + 1);

	WHILE LENGTH (s) > decimal + fPlaces - 1 DO
		DELETE (s, LENGTH (s), 1);

	fNumber := TRUE;

	IF (LENGTH (s) > 10) OR (LENGTH (s) = 10) AND (s > '2147483647') THEN
		BEGIN
		IF negative THEN
			fValue := fMinValue
		ELSE
			fValue := fMaxValue;
		EXIT (ParseValue)
		END;

	StringToNum (s, n);

	IF negative THEN n := -n;

	IF n < fMinValue THEN
		fValue := fMinValue

	ELSE IF n > fMaxValue THEN
		fValue := fMaxValue

	ELSE
		BEGIN
		ParseValue := TRUE;
		fValue := n
		END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TFixedText.Validate (VAR succeeded: BOOLEAN); OVERRIDE;

	CONST
		DAStrings = $AA0;
		kNoNumberID = 914;
		kHaveNumberID = 915;

	TYPE
		TStrings = ARRAY [0..3] OF StringHandle;
		PStrings = ^TStrings;

	VAR
		s0: Str255;
		s1: Str255;
		s2: Str255;
		oldStrings: TStrings;
		theStrings: PStrings;

	BEGIN

	succeeded := ParseValue;

	IF NOT succeeded THEN
		BEGIN

		IF fNumber THEN StuffValue (fValue);

		TDialogView (fParent) . InstallKeyHandler (SELF);

		IF fPlaces = 0 THEN
			GetIndString (s0, kStringsID, strAnInteger)
		ELSE
			GetIndString (s0, kStringsID, strANumber);

		ConvertFixed (fMinValue, fPlaces, FALSE, s1);
		ConvertFixed (fMaxValue, fPlaces, FALSE, s2);

		theStrings := PStrings (DAStrings);

		oldStrings := theStrings^;

		theStrings^ [0] := NIL;
		theStrings^ [1] := NIL;
		theStrings^ [2] := NIL;
		theStrings^ [3] := NIL;

		ParamText (s0, s1, s2, '');

		IF fNumber THEN
			BWNotice (kHaveNumberID, TRUE)
		ELSE
			BWNotice (kNoNumberID, TRUE);

		DisposHandle (Handle (theStrings^ [0]));
		DisposHandle (Handle (theStrings^ [1]));
		DisposHandle (Handle (theStrings^ [2]));
		DisposHandle (Handle (theStrings^ [3]));

		theStrings^ := oldStrings

		END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TPopUpMenu.DrawPopUpText;

	VAR
		s: Str255;
		width: INTEGER;
		chStyle: Style;
		dots: STRING [1];
		maxWidth: INTEGER;
		dotsWidth: INTEGER;

	BEGIN

	EraseRect (fMenuRect);

	MoveTo (fMenuRect.left + 6, fMenuRect.top + 12);

	GetItem (fMenu, fPick, s);
	GetItemStyle (fMenu, fPick, chStyle);

	TextFace (chStyle);

	IF s [LENGTH (s)] = CHR ($C9) THEN
		DELETE (s, LENGTH (s), 1);

	width := StringWidth (s);

	maxWidth := fMenuRect.right - fMenuRect.left - 12;

	IF width > maxWidth THEN
		BEGIN

		dots := ' ';
		dots [1] := CHR ($C9);

		dotsWidth := StringWidth (dots);

		WHILE width > maxWidth - dotsWidth DO
			BEGIN
			width := width - CharWidth (s [LENGTH (s)]);
			DELETE (s, LENGTH (s), 1)
			END;

		INSERT (dots, s, LENGTH (s) + 1)

		END;

	DrawString (s);

	TextFace ([]);

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TPopUpMenu.DrawPopUpMenu;

	VAR
		r: Rect;

	BEGIN

	r := fMenuRect;

	PenNormal;

	InsetRect (r, -1, -1);
	FrameRect (r);

	MoveTo (r.right, r.top + 3);
	LineTo (r.right, r.bottom);
	LineTo (r.left + 3, r.bottom);

	DrawPopUpText

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TPopUpMenu.SetMenu (menu: MenuHandle; pick: INTEGER);

	VAR
		itemBox: Rect;
		redraw: BOOLEAN;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	SetPort (TDialogView (fParent) . fDialogPtr);

	redraw := fMenu <> NIL;

	fMenu := menu;
	fPick := Min (pick, CountMItems (menu));

	GetDItem (TDialogView (fParent) . fDialogPtr, fItemNumber,
			  itemType, itemHandle, itemBox);

	fMenuRect := itemBox;

	CalcMenuSize (fMenu);

	fMenuRect.right := Min (fMenuRect.right,
							fMenuRect.left + fMenu^^.menuWidth);

	IF redraw THEN
		BEGIN

		InsetRect (itemBox, -1, -1);
		itemBox.bottom := itemBox.bottom + 1;
		itemBox.right  := itemBox.right  + 1;

		EraseRect (itemBox);

		DrawPopUpMenu

		END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TPopUpMenu.IPopUpMenu (itsLabelNumber: INTEGER;
								 itsItemNumber: INTEGER;
								 itsParent: TDialogView;
								 menu: MenuHandle;
								 pick: INTEGER);

	VAR
		itemBox: Rect;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	fPickAgain := FALSE;

	IDialogItem (itsItemNumber, itsParent, FALSE);

	IF itsLabelNumber <> 0 THEN
		GetDItem (itsParent.fDialogPtr, itsLabelNumber,
				  itemType, itemHandle, itemBox)
	ELSE
		itemBox := gZeroRect;

	fLabelRect := itemBox;

	fMenu := NIL;

	SetMenu (menu, pick)

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION TPopUpMenu.DoPopUpMenu (optionDown: BOOLEAN): BOOLEAN;

	VAR
		spot: Point;
		item: INTEGER;
		result: LONGINT;

	BEGIN

	InvertRect (fLabelRect);
	InsertMenu (fMenu, -1);

	IF fPick <> 0 THEN
		FOR item := CountMItems (fMenu) DOWNTO 1 DO
			CheckItem (fMenu, item, fPick = item);

	spot := fMenuRect.topLeft;

	LocalToGlobal (spot);

	result := PopUpMenuSelect (fMenu, spot.v, spot.h, Max (1, fPick));

	DeleteMenu (fMenu^^.menuID);
	InvertRect (fLabelRect);

	IF HiWrd (result) <> 0 THEN
		IF LoWrd (result) <> fPick THEN
			BEGIN
			DoPopUpMenu := TRUE;
			fPick := LoWrd (result);
			DrawPopUpText
			END
		ELSE
			DoPopUpMenu := fPickAgain
	ELSE
		DoPopUpMenu := FALSE

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION TPopUpMenu.ItemSelected
		(anItem: INTEGER;
		 VAR handledIt: BOOLEAN;
		 VAR doneWithDialog: BOOLEAN): TCommand; OVERRIDE;

	BEGIN
	ItemSelected := gNoChanges
	END;

{*****************************************************************************}

{$S AUnits}

PROCEDURE TUnitSelector.IUnitSelector (itsParent: TBWDialog;
									   itsItemNumber: INTEGER;
									   editItemNumber: INTEGER;
									   editItemCount: INTEGER;
									   blankOK: BOOLEAN;
									   menuID: INTEGER;
									   pick: INTEGER);

	VAR
		item: INTEGER;
		ft: TFixedText;
		menu: MenuHandle;

	BEGIN

	fUnitCount := 0;

	fEditItemCount := editItemCount;

	menu := GetMenu (menuID);
	FailNil (menu);

	IPopUpMenu (0, itsItemNumber, itsParent, menu, pick);

	FOR item := 0 TO fEditItemCount - 1 DO
		BEGIN
		ft := itsParent.DefineFixedText (editItemNumber + item,
										 0, blankOK, TRUE, 0, 1);
		fEditItem [item] := ft
		END

	END;

{*****************************************************************************}

{$S AUnits}

PROCEDURE TUnitSelector.UnitHasChanged;

	VAR
		item: INTEGER;
		ft: TFixedText;

	BEGIN

	FOR item := 0 TO fEditItemCount - 1 DO
		BEGIN

		ft := fEditItem [item];

		WITH fUnitInfo [fPick] DO
			BEGIN
			ft.fPlaces	 := fPlaces;
			ft.fMinValue := fLower;
			ft.fMaxValue := fUpper
			END

		END

	END;

{*****************************************************************************}

{$S AUnits}

PROCEDURE TUnitSelector.DefineUnit (scale: EXTENDED;
									base: EXTENDED;
									places: INTEGER;
									lower: LONGINT;
									upper: LONGINT);

	BEGIN

	fUnitCount := fUnitCount + 1;

	WITH fUnitInfo [fUnitCount] DO
		BEGIN
		fScale	:= scale;
		fBase	:= base;
		fPlaces := places;
		fLower	:= lower;
		fUpper	:= upper
		END;

	IF fUnitCount = fPick THEN UnitHasChanged

	END;

{*****************************************************************************}

{$S AUnits}

FUNCTION TUnitSelector.ItemSelected
		(anItem: INTEGER;
		 VAR handledIt: BOOLEAN;
		 VAR doneWithDialog: BOOLEAN): TCommand; OVERRIDE;

	BEGIN

	ItemSelected := gNoChanges;

	IF anItem = fItemNumber THEN UnitHasChanged

	END;

{*****************************************************************************}

{$S AUnits}

PROCEDURE TUnitSelector.StuffFixed (item: INTEGER; value: Fixed);

	VAR
		j: INTEGER;
		x: EXTENDED;

	BEGIN

	WITH fUnitInfo [fPick] DO
		BEGIN

		x := (value / 65536 - fBase) / fScale;

		FOR j := 1 TO fPlaces DO
			x := x * 10;

		IF x < fLower THEN
			x := fLower;

		IF x > fUpper THEN
			x := fUpper

		END;

	fEditItem [item] . StuffValue (ROUND (x))

	END;

{*****************************************************************************}

{$S AUnits}

PROCEDURE TUnitSelector.StuffFloat (item: INTEGER; value: EXTENDED);

	BEGIN

	IF value > 32000 THEN
		StuffFixed (item, 32000 * $10000)
	ELSE
		StuffFixed (item, ROUND (value * $10000))

	END;

{*****************************************************************************}

{$S AUnits}

FUNCTION TUnitSelector.GetFixed (item: INTEGER): Fixed;

	VAR
		j: INTEGER;
		x: EXTENDED;

	BEGIN

	WITH fUnitInfo [fPick] DO
		BEGIN

		x := fEditItem [item] . fValue;

		FOR j := 1 TO fPlaces DO
			x := x * 0.1;

		x := x * fScale + fBase

		END;

	GetFixed := ROUND (x * 65536)

	END;

{*****************************************************************************}

{$S AUnits}

FUNCTION TUnitSelector.GetFloat (item: INTEGER): EXTENDED;

	BEGIN

	GetFloat := GetFixed (item) / $10000

	END;

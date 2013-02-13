{Photoshop version 1.0.1, file: UAbout.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UAbout;

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

	TSerialText = OBJECT (TKeyHandler)

		fCode: Str255;
		fValue: LONGINT;

		PROCEDURE TSerialText.Validate (VAR succeeded: BOOLEAN); OVERRIDE;

		END;

	TRegisterDialog = OBJECT (TBWDialog)

		PROCEDURE TRegisterDialog.DoFilterEvent
				(VAR anEvent: EventRecord;
				 VAR itemHit: INTEGER;
				 VAR handledIt: BOOLEAN;
				 VAR doReturn: BOOLEAN); OVERRIDE;

		END;

PROCEDURE RegisterCopy;

PROCEDURE ShowSplashScreen;

PROCEDURE KillSplashScreen;

PROCEDURE DoAboutPhotoshop;

PROCEDURE MakeSizeString (doc: TImageDocument;
						  across: BOOLEAN;
						  VAR s: Str255);

PROCEDURE MakeResString (doc: TImageDocument;
						 align: BOOLEAN;
						 VAR s: Str255);

PROCEDURE DoSizeBoxPopUp (doc: TImageDocument; r: Rect; info: EventInfo);

PROCEDURE VerifyEvE;

IMPLEMENTATION

{$I UAssembly.a.inc}
{$I UAbout.a.inc}
{$I UPrint.p.inc}

CONST
	kMaxRegLine = 63;
	kMaxSerialCode = 7;
	kCodeKey = 59253658;

TYPE
	TRegistration = RECORD
		fLine1: STRING [kMaxRegLine];
		fLine2: STRING [kMaxRegLine];
		fCode:	STRING [kMaxSerialCode];
		fSerial: LONGINT;
		fChecksum: LONGINT
		END;

	PRegistration = ^TRegistration;
	HRegistration = ^PRegistration;

VAR
	gSplashTime: LONGINT;
	gSplashDialog: DialogPtr;
	gSplashPalette: PaletteHandle;

	gRegistration: HRegistration;

{*****************************************************************************}

{$S ARes4}

FUNCTION ComputeChecksum (s: Str255): INTEGER;

	VAR
		d: INTEGER;
		w: INTEGER;
		sum: LONGINT;

	BEGIN

	sum := 0;

	FOR d := 1 TO LENGTH (s) DO
		BEGIN

			CASE d OF
			1:	w := 594;
			2:	w := 629;
			3:	w := 431;
			4:	w := 954;
			5:	w := 228;
			6:	w := 741;
			7:	w := 413;
			8:	w := 846;
			9:	w := 548;
			10: w := 945;
			11: w := 187;
			12: w := 375;
			13: w := 599
			END;

		sum := sum + ORD4 (s[d]) * w

		END;

	sum := sum MOD 1000;

	IF sum < 100 THEN sum := sum + 284;

	ComputeChecksum := sum

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE TSerialText.Validate (VAR succeeded: BOOLEAN); OVERRIDE;

	CONST
		kNeedSerialID = 753;
		kBadSerialID  = 754;

	VAR
		s: Str255;
		j: INTEGER;
		n: LONGINT;
		ss: Str255;
		cs: LONGINT;
		nonBlank: BOOLEAN;

	BEGIN

	GetIText (fItemHandle, s);

	FOR j := LENGTH (s) DOWNTO 0 DO
		IF s [j] IN [' ', '-'] THEN
			DELETE (s, j, 1)
		ELSE IF s [j] IN ['a'..'z'] THEN
			s [j] := CHR (ORD (s [j]) - ORD ('a') + ORD ('A'));

	nonBlank := (LENGTH (s) > 0);

	succeeded := (LENGTH (s) >= 4);

	IF succeeded THEN
		BEGIN

		ss := s;
		DELETE (ss, 1, LENGTH (s) - 3);
		StringToNum (ss, cs);

		s [0] := CHR (LENGTH (s) - 3);

		succeeded := (ComputeChecksum (s) = cs);

		IF succeeded THEN
			BEGIN

			IF LENGTH (s) > 6 THEN
				BEGIN

				ss := s;
				ss [0] := CHR (LENGTH (s) - 6);

				FOR j := 1 TO LENGTH (ss) DO
					succeeded := succeeded & (ss [j] IN ['0'..'9', 'A'..'Z']);

				IF LENGTH (ss) <= kMaxSerialCode THEN
					fCode := ss
				ELSE
					succeeded := FALSE;

				DELETE (s, 1, LENGTH (s) - 6)

				END

			ELSE
				fCode := '';

			FOR j := 1 TO LENGTH (s) DO
				succeeded := succeeded & (s [j] IN ['0'..'9']);

			StringToNum (s, n);

			fValue := n

			END

		END;

	IF NOT succeeded THEN
		BEGIN

		IF nonBlank THEN
			BWNotice (kBadSerialID, TRUE)
		ELSE
			BWNotice (kNeedSerialID, TRUE);

		TDialogView (fParent) . InstallKeyHandler (SELF)

		END

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE TRegisterDialog.DoFilterEvent
		(VAR anEvent: EventRecord;
		 VAR itemHit: INTEGER;
		 VAR handledIt: BOOLEAN;
		 VAR doReturn: BOOLEAN); OVERRIDE;

	BEGIN

	IF anEvent.what IN [keyDown, autoKey] THEN
		IF CHR (BAND (anEvent.message, charCodeMask)) = kReturnChar THEN
			BEGIN
			Tab (TRUE);
			anEvent.what := nullEvent
			END;

	INHERITED DoFilterEvent (anEvent, itemHit, handledIt, doReturn)

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE AskUserToRegister;

	CONST
		kDialogID	= 750;
		kHookItem	= 3;
		kLine1Item	= 4;
		kLine2Item	= 5;
		kSerialItem = 6;
		kTooFewID	= 751;
		kTooManyID	= 752;

	VAR
		s1: Str255;
		s2: Str255;
		fi: FailInfo;
		hitItem: INTEGER;
		serialText: TSerialText;
		line1Handler: TKeyHandler;
		line2Handler: TKeyHandler;
		aRegisterDialog: TRegisterDialog;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aRegisterDialog.Free
		END;

	PROCEDURE TrimBlanks (VAR s: Str255);
		BEGIN
		WHILE (LENGTH (s) > 0) & (s[1] = ' ') DO
			DELETE (s, 1, 1);
		WHILE (s [LENGTH (s)] = ' ') DO
			DELETE (s, LENGTH (s), 1)
		END;

	BEGIN

	NEW (aRegisterDialog);
	FailNil (aRegisterDialog);

	aRegisterDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	NEW (line1Handler);
	FailNil (line1Handler);

	line1Handler.IKeyHandler (kLine1Item, aRegisterDialog);

	NEW (line2Handler);
	FailNil (line2Handler);

	line2Handler.IKeyHandler (kLine2Item, aRegisterDialog);

	NEW (serialText);
	FailNil (serialText);

	serialText.IKeyHandler (kSerialItem, aRegisterDialog);

	aRegisterDialog.SetEditSelection (kLine1Item);

		REPEAT

		aRegisterDialog.TalkToUser (hitItem, StdItemHandling);

		IF hitItem <> ok THEN Failure (0, 0);

		GetIText (line1Handler.fItemHandle, s1);
		GetIText (line2Handler.fItemHandle, s2);

		TrimBlanks (s1);
		TrimBlanks (s2);

		IF LENGTH (s1) > kMaxRegLine THEN
			BEGIN
			DELETE (s1, kMaxRegLine + 1, LENGTH (s1) - kMaxRegLine);
			line1Handler.StuffString (s1);
			aRegisterDialog.SetEditSelection (kLine1Item);
			BWNotice (kTooManyID, TRUE)
			END

		ELSE IF LENGTH (s2) > kMaxRegLine THEN
			BEGIN
			DELETE (s2, kMaxRegLine + 1, LENGTH (s2) - kMaxRegLine);
			line2Handler.StuffString (s2);
			aRegisterDialog.SetEditSelection (kLine2Item);
			BWNotice (kTooManyID, TRUE)
			END

		ELSE IF LENGTH (s1) = 0 THEN
			BEGIN
			aRegisterDialog.SetEditSelection (kLine1Item);
			BWNotice (kTooFewID, TRUE)
			END

		ELSE
			LEAVE

		UNTIL FALSE;

	gRegistration^^.fCode	:= serialText.fCode;
	gRegistration^^.fSerial := serialText.fValue;

	Success (fi);

	CleanUp (0, 0);

	gRegistration^^.fLine1 := s1;
	gRegistration^^.fLine2 := s2;

	DoSetBytes (Ptr (ORD4 (@gRegistration^^.fLine1) + LENGTH (s1) + 1),
				kMaxRegLine - LENGTH (s1), 0);

	DoSetBytes (Ptr (ORD4 (@gRegistration^^.fLine2) + LENGTH (s2) + 1),
				kMaxRegLine - LENGTH (s2), 0)

	END;

{*****************************************************************************}

{$S AInit}

FUNCTION FindChecksum: LONGINT;

	BEGIN

	randSeed := kCodeKey;

	FindChecksum := CodedChecksum (Ptr (gRegistration^),
								   SIZEOF (TRegistration) - 4)

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE RegisterCopy;

	VAR
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FailNewMessage (error, message, msgCannotPersonalize)
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	{$IFC NOT qBarneyscan AND NOT qDemo}

	gRegistration := HRegistration (Get1Resource ('Reg ', 0));

	IF gRegistration = NIL THEN
		BEGIN

		{$IFC qDebug}

		gRegistration := HRegistration (NewHandle (SIZEOF (TRegistration)));
		FailNil (gRegistration);

		DoSetBytes (Ptr (gRegistration^), SIZEOF (TRegistration), 0);

		AddResource (Handle (gRegistration), 'Reg ', 0, '');
		FailResError

		{$ELSEC}

		Failure (errBadRegistration, 0)

		{$ENDC}

		END;

	IF gRegistration^^.fChecksum <> FindChecksum THEN
		BEGIN

		{$IFC qDebug}

		gRegistration^^.fChecksum := FindChecksum;

		writeln ('Checksum: ', gRegistration^^.fChecksum:1);

		ChangedResource (Handle (gRegistration))

		{$ELSEC}

		Failure (errBadRegistration, 0)

		{$ENDC}

		END;

	IF LENGTH (gRegistration^^.fLine1) = 0 THEN
		BEGIN

		AskUserToRegister;

		gRegistration^^.fChecksum := FindChecksum;

		ChangedResource (Handle (gRegistration));
		FailResError;

		WriteResource (Handle (gRegistration));
		FailResError

		END;

	gSerialNumber := gRegistration^^.fSerial;

	{$ELSEC}

	gSerialNumber := 0;

	{$ENDC}

	Success (fi)

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE DrawUserName (dp: DialogPtr; item: INTEGER);

	VAR
		r: Rect;
		h: Handle;
		s: Str255;
		ss: Str255;
		itemType: INTEGER;

	BEGIN

	TextFont (gGeneva);
	TextSize (9);
	TextFace ([bold]);

	GetDItem (dp, item, itemType, h, r);

	s := gRegistration^^.fLine1;

	r.bottom := r.top + 12;
	TextBox (@s[1], LENGTH (s), r, teJustLeft);

	s := gRegistration^^.fLine2;

	IF LENGTH (s) <> 0 THEN
		BEGIN
		OffsetRect (r, 0, 12);
		TextBox (@s[1], LENGTH (s), r, teJustLeft)
		END;

	NumToString (gSerialNumber, s);

	WHILE LENGTH (s) < 6 DO
		INSERT ('0', s, 1);

	INSERT (gRegistration^^.fCode, s, 1);

	NumToString (ComputeChecksum (s), ss);

	INSERT ('-', s, LENGTH (s) + 1);
	INSERT (ss, s, LENGTH (s) + 1);

	OffsetRect (r, 0, 12);
	TextBox (@s[1], LENGTH (s), r, teJustLeft)

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE ShowSplashScreen;

	CONST
		kDialogID = 710;

	VAR
		r: Rect;
		rr: Rect;
		h: Handle;
		j: INTEGER;
		item: INTEGER;
		depth: INTEGER;
		itemList: Handle;
		itemType: INTEGER;
		theEvent: EventRecord;

	BEGIN

	IF gConfiguration.hasColorToolbox THEN
		depth := GetMainDevice^^.gdPMap^^.pixelSize
	ELSE
		depth := 1;

	gSplashDialog := GetNewDialog (kDialogID + ORD (depth < 4),
								   NIL, WindowPtr (-1));

	IF depth < 4 THEN
		gSplashPalette := NIL
	ELSE
		BEGIN
		gSplashPalette := GetNewPalette (kDialogID);
		SetPalette (gSplashDialog, gSplashPalette, FALSE)
		END;

	CenterWindow (gSplashDialog, FALSE);

	{$IFC NOT qBarneyscan AND NOT qDemo}

	itemList := DialogPeek (gSplashDialog)^.items;

	item := PInteger (itemList^)^ + 1;

	GetDItem (gSplashDialog, item, itemType, h, r);
	SetDItem (gSplashDialog, item, itemType, Handle (@DrawUserName), r);

	rr := gSplashDialog^.portRect;

	IF (itemType <> userItem + itemDisable) OR
	   (r.left < rr.left) OR
	   (r.right > rr.right) OR
	   (r.top < rr.top) OR
	   (r.bottom > rr.bottom) OR
	   (r.bottom - r.top < 36) OR
	   (r.right - r.left < 100) THEN Failure (errBadRegistration, 0);

	{$ENDC}

	FOR j := 1 TO 5 DO
		IF GetNextEvent (everyEvent, theEvent) THEN;

	ShowWindow (gSplashDialog);
	DrawDialog (gSplashDialog);

	gSplashTime := TickCount

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE KillSplashScreen;

	CONST
		kMinSplash = 120;

	BEGIN

	WHILE TickCount < gSplashTime + kMinSplash DO;

	IF gSplashPalette <> NIL THEN
		DisposePalette (gSplashPalette);

	DisposDialog (gSplashDialog);

	FlushEvents (everyEvent, 0)

	END;

{*****************************************************************************}

{$S ADoAbout}

PROCEDURE AboutPlugIn (info: HPlugInInfo);

	VAR
		h: Handle;
		fi: FailInfo;
		data: LONGINT;
		port: GrafPtr;
		refNum: INTEGER;
		result: INTEGER;
		fileName: Str255;

	PROCEDURE DoCallPlugIn (selector: INTEGER;
							stuff: Ptr;
							VAR data: LONGINT;
							VAR result: INTEGER;
							codeAddress: Ptr); INLINE $205F, $4E90;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF refNum <> -1 THEN CloseResFile (refNum);
		END;

	BEGIN

	refNum := -1;
	CatchFailures (fi, CleanUp);

	fileName := info^^.fFileName;

	IF LENGTH (fileName) <> 0 THEN
		BEGIN
		FailOSErr (SetVol (NIL, gPouchRefNum));
		refNum := OpenResFile (fileName);
		FailResError
		END;

	h := GetResource (info^^.fKind, info^^.fResourceID);
	FailResError;
	FailNil (h);

	MoveHHi (h);
	HLock (h);

	GetPort (port);

	SetCursor (arrow);

	data := info^^.fData;

	DoCallPlugIn (0, NIL, data, result, StripAddress (h^));

	info^^.fData := data;

	SetPort (port);

	HUnlock (h);
	HPurge (h);

	Success (fi);
	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoAbout}

PROCEDURE AboutPlugIns;

	PROCEDURE AboutPlugInList (first: HPlugInInfo);

		VAR
			info: HPlugInInfo;

		BEGIN

		info := first;

		WHILE info <> NIL DO
			BEGIN
			AboutPlugIn (info);
			info := info^^.fNext
			END

		END;

	BEGIN

	AboutPlugInList (gFirstPSAcquire);
	AboutPlugInList (gFirstDDAcquire);
	AboutPlugInList (gFirstBWAcquire);

	AboutPlugInList (gFirstPSExport);

	AboutPlugInList (gFirstPSFilter);
	AboutPlugInList (gFirstDDFilter)

	END;

{*****************************************************************************}

{$S ADoAbout}

FUNCTION HavePlugIns: BOOLEAN;

	BEGIN

	HavePlugIns := (gFirstPSAcquire <> NIL) OR
				   (gFirstDDAcquire <> NIL) OR
				   (gFirstBWAcquire <> NIL) OR
				   (gFirstPSFilter	<> NIL) OR
				   (gFirstDDFilter	<> NIL)

	END;

{*****************************************************************************}

{$S ADoAbout}

FUNCTION AuxAboutBox: BOOLEAN;

	VAR
		r: Rect;
		c: CHAR;
		wp: WindowPtr;
		ph: PicHandle;
		which: WindowPtr;
		theEvent: EventRecord;

	BEGIN

	ph := PicHandle (GetResource ('KSAB', 1000));

	IF ph = NIL THEN
		AuxAboutBox := FALSE

	ELSE
		BEGIN

		AuxAboutBox := TRUE;

		HLock (Handle (ph));

		r := ph^^.picFrame;

		IF gConfiguration.hasColorToolbox THEN
			wp := WindowPtr (NewCWindow (NIL, r, '', FALSE, dBoxProc,
										 WindowPtr (-1), FALSE, 0))
		ELSE
			wp := NewWindow (NIL, r, '', FALSE, dBoxProc,
							 WindowPtr (-1), FALSE, 0);

		CenterWindow (wp, FALSE);
		ShowWindow (wp);

		SetPort (wp);
		DrawPicture (ph, r);

		HUnlock (Handle (ph));

			REPEAT

			IF GetNextEvent (everyEvent, theEvent) THEN
				CASE theEvent.what OF

				keyDown,
				autoKey:
					BEGIN
					c := CHR (BAND (theEvent.message, charCodeMask));
					IF (c = kReturnChar) OR (c = kEnterChar) THEN
						LEAVE
					END;

				mouseDown:
					BEGIN
					IF FindWindow (theEvent.where, which) = inContent THEN
						IF which = wp THEN
							LEAVE;
					SysBeep (1)
					END

				END

			UNTIL FALSE;

		DisposeWindow (wp)

		END

	END;

{*****************************************************************************}

{$S ADoAbout}

PROCEDURE DoAboutPhotoshop;

	CONST
		kAboutID	= 700;
		kOKItem 	= 2;
		kPlugInItem = 3;
		kHookItem	= 4;
		kUserItem	= 5;

	VAR
		fi: FailInfo;
		itemBox: Rect;
		theKeys: KeyMap;
		hitItem: INTEGER;
		ph: PaletteHandle;
		itemType: INTEGER;
		grayscale: BOOLEAN;
		itemHandle: Handle;
		aBWDialog: TBWDialog;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF grayscale THEN
			DisposePalette (ph);
		aBWDialog.Free
		END;

	BEGIN

	GetKeys (theKeys);

	IF theKeys [kOptionCode] THEN
		IF AuxAboutBox THEN
			EXIT (DoAboutPhotoshop);

	IF gConfiguration.hasColorToolbox THEN
		grayscale := (GetMainDevice^^.gdPMap^^.pixelSize >= 4)
	ELSE
		grayscale := FALSE;

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kAboutID + ORD (NOT grayscale), kHookItem, kOKItem);

	IF grayscale THEN
		BEGIN
		ph := GetNewPalette (kAboutID);
		SetPalette (aBWDialog.fDialogPtr, ph, FALSE)
		END;

	{$IFC NOT qBarneyscan AND NOT qDemo}

	GetDItem (aBWDialog.fDialogPtr, kUserItem,
			  itemType, itemHandle, itemBox);
	SetDItem (aBWDialog.fDialogPtr, kUserItem,
			  itemType, Handle (@DrawUserName), itemBox);

	{$ENDC}

	IF NOT HavePlugIns THEN
		BEGIN

		GetDItem (aBWDialog.fDialogPtr, kPlugInItem,
				  itemType, itemHandle, itemBox);

		HiliteControl (ControlHandle (itemHandle), 255)

		END;

	CatchFailures (fi, CleanUp);

		REPEAT

		aBWDialog.TalkToUser (hitItem, StdItemHandling);

		IF hitItem = kPlugInItem THEN
			AboutPlugIns

		UNTIL hitItem = kOKItem;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoAbout}

PROCEDURE MakeSizeString (doc: TImageDocument;
						  across: BOOLEAN;
						  VAR s: Str255);

	CONST
		kUnitStrings = 1007;

	VAR
		u: INTEGER;
		j: INTEGER;
		ss: Str255;
		x: EXTENDED;
		base: EXTENDED;
		upper: LONGINT;
		scale: EXTENDED;
		places: INTEGER;

	BEGIN

	IF across THEN
		BEGIN
		x := doc.fCols;
		u := doc.fStyleInfo.fWidthUnit
		END
	ELSE
		BEGIN
		x := doc.fRows;
		u := doc.fStyleInfo.fHeightUnit
		END;

	x := x / (doc.fStyleInfo.fResolution.value / $10000);

	base := 0;

		CASE u OF

		1:	BEGIN
			scale  := 1.0;
			places := 3;
			upper  := 400000
			END;

		2:	BEGIN
			scale  := 1/2.54;
			places := 2;
			upper  := 100000
			END;

		3:	BEGIN
			scale  := 1/72;
			places := 1;
			upper  := 300000
			END;

		4:	BEGIN
			scale  := 1/6;
			places := 2;
			upper  := 250000
			END;

		5:	BEGIN
			scale  := (gPreferences.fColumnWidth.value +
					   gPreferences.fColumnGutter.value) / $10000;
			base   := -gPreferences.fColumnGutter.value / $10000;
			places := 3;
			upper  := ROUND (400 / scale) * 1000;
			END

		END;

	x := (x - base) / scale;

	FOR j := 1 TO places DO x := x * 10;

	IF x < 1	 THEN x := 1;
	IF x > upper THEN x := upper;

	ConvertFixed (ROUND (x), places, TRUE, s);

	GetIndString (ss, kUnitStrings, 2 * u - ORD (s = '1'));

	INSERT (ss, s, LENGTH (s) + 1)

	END;

{*****************************************************************************}

{$S ADoAbout}

PROCEDURE MakeResString (doc: TImageDocument;
						 align: BOOLEAN;
						 VAR s: Str255);

	CONST
		kResStrings = 1008;

	VAR
		u: INTEGER;
		y: LONGINT;
		ss: Str255;
		x: EXTENDED;
		pad: INTEGER;

	BEGIN

	x := doc.fStyleInfo.fResolution.value / $10000;
	u := doc.fStyleInfo.fResolution.scale;

	IF u = 1 THEN
		BEGIN
		x := x * 1000;
		IF x > 3200000 THEN x := 3200000
		END
	ELSE
		BEGIN
		x := x / 2.54 * 1000;
		IF x > 1300000 THEN x := 1300000
		END;

	y := ROUND (x);

	ConvertFixed (y, 3, FALSE, s);

	IF align THEN
		pad := 9 - LENGTH (s)
	ELSE
		pad := 0;

	ConvertFixed (y, 3, TRUE, s);

	WHILE pad > 0 DO
		BEGIN
		INSERT (' ', s, 1);
		pad := pad - 1
		END;

	GetIndString (ss, kResStrings, 2 * u - ORD (y = 1000));

	INSERT (ss, s, LENGTH (s) + 1)

	END;

{*****************************************************************************}

{$S ADoAbout}

PROCEDURE ForceOnScreen (VAR r: Rect);

	VAR
		sr: Rect;
		rr: Rect;
		gdh: GDHandle;

	BEGIN

	sr := screenBits.bounds;

	IF gConfiguration.hasColorToolbox THEN
		BEGIN

		SetRect (rr, 0, 0, 1, 1);
		OffsetRect (rr, gLastEvent.where.h, gLastEvent.where.v);

		gdh := GetMaxDevice (rr);
		IF gdh <> NIL THEN sr := gdh^^.gdRect

		END;

	IF LONGINT (sr.topLeft) = 0 THEN
		sr.top := sr.top + gMBarHeight;

	InsetRect (sr, 3, 3);

	IF r.bottom > sr.bottom THEN OffsetRect (r, 0, sr.bottom - r.bottom);
	IF r.right	> sr.right	THEN OffsetRect (r, sr.right - r.right, 0);
	IF r.top	< sr.top	THEN OffsetRect (r, 0, sr.top - r.top);
	IF r.left	< sr.left	THEN OffsetRect (r, sr.left - r.left, 0)

	END;

{*****************************************************************************}

{$S ADoAbout}

PROCEDURE DoTextSizePopUp (doc: TImageDocument; r: Rect);

	CONST
		kSizeStrings = 1006;
		kDepthID	 = 1;
		kWidthID	 = 2;
		kHeightID	 = 3;
		kResID		 = 4;
		kPixelID	 = 5;
		kModeID 	 = 7;

	VAR
		rr: Rect;
		s1: Str255;
		s2: Str255;
		s3: Str255;
		s4: Str255;
		wp: WindowPtr;
		width: INTEGER;

	PROCEDURE SetInteger (VAR s: Str255; x: INTEGER);

		BEGIN
		NumToString (x, s);
		WHILE LENGTH (s) < 5 DO INSERT (' ', s, 1)
		END;

	PROCEDURE InsertString (VAR s: Str255; id: INTEGER; index: INTEGER);

		VAR
			ss: Str255;

		BEGIN
		GetIndString (ss, kSizeStrings, id);
		INSERT (ss, s, index)
		END;

	PROCEDURE AppendString (VAR s: Str255; id: INTEGER);

		BEGIN
		InsertString (s, id, LENGTH (s) + 1)
		END;

	PROCEDURE AppendSize (VAR s: Str255; across: BOOLEAN);

		VAR
			ss: Str255;

		BEGIN
		MakeSizeString (doc, across, ss);
		INSERT (' (', s, LENGTH (s) + 1);
		INSERT (ss	, s, LENGTH (s) + 1);
		INSERT (')' , s, LENGTH (s) + 1)
		END;

	BEGIN

	SetInteger (s1, doc.fCols);
	AppendString (s1, kPixelID + ORD (doc.fCols <> 1));
	AppendSize (s1, TRUE);

	SetInteger (s2, doc.fRows);
	AppendString (s2, kPixelID + ORD (doc.fRows <> 1));
	AppendSize (s2, FALSE);

	SetInteger (s3, doc.fChannels);
	AppendString (s3, kModeID + ORD (doc.fMode));

	MakeResString (doc, TRUE, s4);

	WHILE (s1 [1] = ' ') AND (s2 [1] = ' ') AND
		  (s3 [1] = ' ') AND (s4 [1] = ' ') DO
		BEGIN
		DELETE (s1, 1, 1);
		DELETE (s2, 1, 1);
		DELETE (s3, 1, 1);
		DELETE (s4, 1, 1)
		END;

	InsertString (s1, kWidthID, 1);
	InsertString (s2, kHeightID, 1);
	InsertString (s3, kDepthID, 1);
	InsertString (s4, kResID, 1);

	TextFont (gMonaco);
	TextSize (9);

	width := Max (StringWidth (s1),
			 Max (StringWidth (s2),
			 Max (StringWidth (s3),
				  StringWidth (s4))));

	rr := r;

	LocalToGlobal (rr.topLeft);
	LocalToGlobal (rr.botRight);

	rr.top	  := rr.bottom - 50;
	rr.right  := rr.left   + 20 + width;

	ForceOnScreen (rr);

	wp := NewWindow (NIL, rr, '', FALSE, plainDBox, NIL, FALSE, 0);
	BringToFront (wp);
	ShowHide (wp, TRUE);

	SetPort (wp);

	TextFont (gMonaco);
	TextSize (9);

	MoveTo (10, 13);
	DrawString (s1);

	MoveTo (10, 23);
	DrawString (s2);

	MoveTo (10, 33);
	DrawString (s3);

	MoveTo (10, 43);
	DrawString (s4);

		REPEAT
		UNTIL NOT StillDown;

	ShowHide (wp, FALSE);

	DisposeWindow (wp)

	END;

{*****************************************************************************}

{$S ADoAbout}

PROCEDURE DoVisualSizePopUp (doc: TImageDocument; r: Rect);

	CONST
		kSizeLimit = 306;

	VAR
		rr: Rect;
		rrr: Rect;
		bounds: Rect;
		theInk: Rect;
		wp: WindowPtr;
		thePaper: Rect;
		theImage: Rect;
		width: INTEGER;
		height: INTEGER;

	PROCEDURE RegMark (h, v: INTEGER);

		VAR
			r: Rect;

		BEGIN

		SetRect    (r, -3, -3, 4, 4);
		OffsetRect (r, h, v);
		FrameOval  (r);

		MoveTo (h - 3, v);
		Line   (6, 0);
		MoveTo (h, v - 3);
		Line   (0, 6)

		END;

	PROCEDURE StarMark (h, v: INTEGER);

		VAR
			r: Rect;

		BEGIN
		SetRect    (r, -3, -3, 4, 4);
		OffsetRect (r, h, v);
		PaintOval  (r)
		END;

	BEGIN

	doc.GetBoundsRect (bounds);

	GetPrintRects (doc, bounds, thePaper, theInk, theImage);

	width  := thePaper.right - thePaper.left;
	height := thePaper.bottom - thePaper.top;

	IF Max (width, height) > kSizeLimit * 4 THEN
		IF width >= height THEN
			BEGIN
			height := ROUND (height / width * kSizeLimit);
			width  := kSizeLimit
			END
		ELSE
			BEGIN
			width  := ROUND (width / height * kSizeLimit);
			height := kSizeLimit
			END
	ELSE
		BEGIN
		width  := width  DIV 4;
		height := height DIV 4
		END;

	width  := Max (width,  18);
	height := Max (height, 18);

	rr := r;

	LocalToGlobal (rr.topLeft);
	LocalToGlobal (rr.botRight);

	rr.top	  := rr.bottom - height;
	rr.right  := rr.left   + width;

	ForceOnScreen (rr);

	wp := NewWindow (NIL, rr, '', FALSE, plainDBox, NIL, FALSE, 0);
	BringToFront (wp);
	ShowHide (wp, TRUE);

	SetPort (wp);

	SetRect (rr, 0, 0, width, height);

	MapRect (theInk  , thePaper, rr);
	MapRect (theImage, thePaper, rr);

	FillRect (rr, gray);
	EraseRect (theInk);

	FrameRect (theImage);

	MoveTo (theImage.left  + 1, theImage.top	+ 1);
	LineTo (theImage.right - 2, theImage.bottom - 2);
	MoveTo (theImage.right - 2, theImage.top	+ 1);
	LineTo (theImage.left  + 1, theImage.bottom - 2);

	IF doc.fStyleInfo.fCropMarks THEN
		BEGIN

		MoveTo (theImage.left, theImage.top);
		Move (-3,  0);
		Line (-6,  0);
		Move ( 9, -3);
		Line ( 0, -6);

		MoveTo (theImage.right - 1, theImage.top);
		Move ( 3,  0);
		Line ( 6,  0);
		Move (-9, -3);
		Line ( 0, -6);

		MoveTo (theImage.right - 1, theImage.bottom - 1);
		Move ( 3,  0);
		Line ( 6,  0);
		Move (-9,  3);
		Line ( 0,  6);

		MoveTo (theImage.left, theImage.bottom - 1);
		Move (-3,  0);
		Line (-6,  0);
		Move ( 9,  3);
		Line ( 0,  6)

		END;

	IF doc.fStyleInfo.fRegistrationMarks THEN
		BEGIN

		RegMark (theImage.left	- 6, theImage.top	 + 5);
		RegMark (theImage.left	- 6, theImage.bottom - 6);
		RegMark (theImage.left	+ 5, theImage.top	 - 6);
		RegMark (theImage.right - 6, theImage.top	 - 6);
		RegMark (theImage.right + 5, theImage.top	 + 5);
		RegMark (theImage.right + 5, theImage.bottom - 6);
		RegMark (theImage.right - 6, theImage.bottom + 5);
		RegMark (theImage.left	+ 5, theImage.bottom + 5);

		IF doc.fStyleInfo.fFlip THEN
			BEGIN
			StarMark (theImage.right + 5, theImage.top	  - 6);
			StarMark (theImage.left  - 6, theImage.bottom + 5)
			END
		ELSE
			BEGIN
			StarMark (theImage.left  - 6, theImage.top	  - 6);
			StarMark (theImage.right + 5, theImage.bottom + 5)
			END

		END;

	IF doc.fStyleInfo.fLabel THEN
		BEGIN

		SetRect (rrr, -12, 0, 13, 3);

		OffsetRect (rrr, (theImage.left + theImage.right) DIV 2,
						 theImage.top - 9);

		IF theImage.right - theImage.left < 69 THEN
			OffsetRect (rrr, 0, -8);

		FillRect (rrr, gray)

		END;

	IF LENGTH (doc.fStyleInfo.fCaption) > 0 THEN
		BEGIN

		SetRect (rrr, -12, 0, 13, 3);

		OffsetRect (rrr, (theImage.left + theImage.right) DIV 2,
						 theImage.bottom + 10);

		IF theImage.right - theImage.left < 69 THEN
			OffsetRect (rrr, 0, 8);

		FillRect (rrr, gray)

		END;

	IF doc.fStyleInfo.fColorBars THEN
		BEGIN

		SetRect (rrr, -20, 0, 21, 5);

		OffsetRect (rrr, (theImage.left + theImage.right) DIV 2,
						 theImage.bottom + 3);

		IF theImage.right - theImage.left < 69 THEN
			OffsetRect (rrr, 0, 8);

		FillRect (rrr, gray);

		IF doc.fMode IN [IndexedColorMode,
						 RGBColorMode,
						 SeparationsCMYK] THEN
			BEGIN

			SetRect (rrr, -5, -15, 0, 16);

			OffsetRect (rrr, theImage.left - 3,
							 (theImage.top + theImage.bottom) DIV 2);

			IF theImage.bottom - theImage.top < 57 THEN
				OffsetRect (rrr, -8, 0);

			FillRect (rrr, gray);

			OffsetRect (rrr, theImage.right + 3 - rrr.left, 0);

			IF theImage.bottom - theImage.top < 57 THEN
				OffsetRect (rrr, 8, 0);

			FillRect (rrr, gray)

			END

		END;

	IF doc.fStyleInfo.fNegative THEN InvertRect (rr);

		REPEAT
		UNTIL NOT StillDown;

	ShowHide (wp, FALSE);

	DisposeWindow (wp)

	END;

{*****************************************************************************}

{$S ADoAbout}

PROCEDURE DoSizeBoxPopUp (doc: TImageDocument; r: Rect; info: EventInfo);

	BEGIN

	IF info.theOptionKey THEN
		DoTextSizePopUp (doc, r)
	ELSE
		DoVisualSizePopUp (doc, r)

	END;

{*****************************************************************************}

{$S AInit}

FUNCTION EVEReset: INTEGER; EXTERNAL;
FUNCTION EVEStatus: INTEGER; EXTERNAL;
FUNCTION EVEReadGPR (GPR: INTEGER): INTEGER; EXTERNAL;
FUNCTION EVEEnable (VAR PASSWORD: STRING): INTEGER; EXTERNAL;
FUNCTION EVEChallenge (LOCK, VALUE: INTEGER): INTEGER; EXTERNAL;

PROCEDURE VerifyEvE;

	CONST
		errOtherEve    = -25900;
		errNoEveDriver = -25901;
		errNoEveKey    = -25902;
		errBadKeyCodes = -25903;

	VAR
		h: Handle;
		s: STRING;
		key: INTEGER;

	FUNCTION Retry (error: INTEGER): BOOLEAN;

		BEGIN

			CASE error OF

			noErr:
				Retry := FALSE;

			-991:
				Retry := TRUE;

			-994:
				Failure (errNoEveKey, 0);

			-999:
				Failure (errNoEveDriver, 0);

			OTHERWISE
				Failure (errOtherEve, 0)

			END

		END;

	PROCEDURE EncodeSegment (code: Handle; key: INTEGER);

		VAR
			p: Ptr;
			count: INTEGER;
			ignore: INTEGER;

		BEGIN

		randSeed := key;

		FOR count := 1 TO 10 DO
			ignore := Random;

		count := GetHandleSize (code);

		p := code^;

		WHILE count > 0 DO
			BEGIN

			count := count - 1;

			{$PUSH}
			{$R-}

			p^ := BXOR (p^, Random);

			{$POP}

			p := Ptr (ORD4 (p) + 1)

			END

		END;

	BEGIN

	h := Get1Resource ('EvE ', 256);

	IF h = NIL THEN EXIT (VerifyEvE);

	WHILE Retry (EVEStatus) DO;

	WHILE Retry (EVEReset) DO;

	s := 'zsBanSwzaMGpSmDP';
	WHILE Retry (EVEEnable (s)) DO;

	key := EVEReadGPR (1);

	IF EVEChallenge (1, 20029) <> 56 THEN
		Failure (errBadKeyCodes, 0);

	IF EVEChallenge (2, key) <> 56 THEN
		Failure (errBadKeyCodes, 0);

	WHILE Retry (EVEReset) DO;

	ReleaseResource (h);
	FailResError;

	h := GetNamedResource ('CODE', 'AEncoded');
	FailNIL (h);

	EncodeSegment (h, key)

	END;

{*****************************************************************************}

END.

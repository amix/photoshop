{Photoshop version 1.0.1, file: UScreen.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}
{$I UConvert.a.inc}
{$I UScreen.a.inc}

CONST
	kHalftoneVersion  = 2;
	kHalftoneFileType = '8BHS';

TYPE
	TBufferEntry = RECORD
		fPriority: LONGINT;
		fRandom  : INTEGER;
		fRow	 : INTEGER;
		fCol	 : INTEGER;
		END;
	PBufferEntry = ^TBufferEntry;

VAR
	gSpotList: Handle;
	gSpotDirty: BOOLEAN;

	gAutoFrequency: FixedScaled;

PROCEDURE qsort (base: Ptr;
				 nelem: LONGINT;
				 elSize: LONGINT;
				 compar: ProcPtr); C; EXTERNAL;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitScreens;

	BEGIN

	gSpotList := NewHandle (0);
	FailNil (gSpotList);

	gSpotDirty := FALSE;

	gAutoFrequency.value := 133 * $10000;
	gAutoFrequency.scale := 1

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE RegisterSpot (h: Handle);

	VAR
		offset: LONGINT;

	BEGIN

	{$IFC qDebug}
	write ('Allocate Spot: ');
	writePtr (h);
	writeln;
	{$ENDC}

	offset := Munger (gSpotList, 0, NIL, 0, @h, 4)

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE MarkSpotDirty;

	BEGIN
	gSpotDirty := TRUE
	END;

{*****************************************************************************}

{$S ARes4}

FUNCTION SpotInUse (h: Handle): BOOLEAN;

	VAR
		inUse: BOOLEAN;

	PROCEDURE TestDoc (doc: TImageDocument);
		BEGIN
		inUse := inUse |
				 (h = doc.fStyleInfo.fHalftoneSpec.spot) |
				 (h = doc.fStyleInfo.fHalftoneSpecs[0].spot) |
				 (h = doc.fStyleInfo.fHalftoneSpecs[1].spot) |
				 (h = doc.fStyleInfo.fHalftoneSpecs[2].spot) |
				 (h = doc.fStyleInfo.fHalftoneSpecs[3].spot)
		END;

	BEGIN

	inUse := (h = gPreferences.fHalftone.spot) |
			 (h = gPreferences.fHalftones[0].spot) |
			 (h = gPreferences.fHalftones[1].spot) |
			 (h = gPreferences.fHalftones[2].spot) |
			 (h = gPreferences.fHalftones[3].spot);

	IF NOT inUse THEN
		gDocList.Each (TestDoc);

	SpotInUse := inUse

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE CollectSpotGarbage;

	TYPE
		PHandle = ^Handle;

	VAR
		h: Handle;
		item: LONGINT;
		count: LONGINT;
		offset: LONGINT;

	BEGIN

	IF gSpotDirty THEN
		BEGIN

		count := BSR (GetHandleSize (gSpotList), 2);

		FOR item := count - 1 DOWNTO 0 DO
			BEGIN

			offset := BSL (item, 2);

			h := PHandle (ORD4 (gSpotList^) + offset)^;

			IF NOT SpotInUse (h) THEN
				BEGIN

				{$IFC qDebug}
				write ('Free Spot: ');
				writePtr (h);
				writeln;
				{$ENDC}

				DisposHandle (h);

				offset := Munger (gSpotList, offset, NIL, 4, @h, 0)

				END

			END;

		gSpotDirty := FALSE

		END

	END;

{*****************************************************************************}

{$S APageSetup}

PROCEDURE TLSDialog.ILSDialog (dialogID: INTEGER;
							   loadItem: INTEGER;
							   saveItem: INTEGER);

	CONST
		kHookItem = 3;

	VAR
		r: Rect;
		h: Handle;
		itemType: INTEGER;

	BEGIN

	IBWDialog (dialogID, kHookItem, ok);

	GetDItem (fDialogPtr, loadItem, itemType, h, r);
	fLoadButton := ControlHandle (h);

	GetDItem (fDialogPtr, saveItem, itemType, h, r);
	fSaveButton := ControlHandle (h);

	{$H-}

	GetCTitle (fLoadButton, fLoadTitle1);
	GetCTitle (fSaveButton, fSaveTitle1);

	GetDItem (fDialogPtr, loadItem + 1, itemType, h, r);
	GetCTitle (ControlHandle (h), fLoadTitle2);

	GetDItem (fDialogPtr, saveItem + 1, itemType, h, r);
	GetCTitle (ControlHandle (h), fSaveTitle2);

	{$H+}

	fOptionDown := FALSE

	END;

{*****************************************************************************}

{$S APageSetup}

PROCEDURE TLSDialog.UpdateButtons;

	VAR
		s1: Str255;
		s2: Str255;
		theKeys: KeyMap;

	BEGIN

	GetKeys (theKeys);

	IF theKeys [kOptionCode] <> fOptionDown THEN
		BEGIN

		fOptionDown := NOT fOptionDown;

		IF fOptionDown THEN
			BEGIN
			s1 := fLoadTitle2;
			s2 := fSaveTitle2
			END
		ELSE
			BEGIN
			s1 := fLoadTitle1;
			s2 := fSaveTitle1
			END;

		SetCTitle (fLoadButton, s1);
		SetCTitle (fSaveButton, s2)

		END

	END;

{*****************************************************************************}

{$S APageSetup}

FUNCTION TLSDialog.DoSetCursor (localPoint: Point): BOOLEAN; OVERRIDE;

	BEGIN

	DoSetCursor := INHERITED DoSetCursor (localPoint);

	UpdateButtons

	END;

{*****************************************************************************}

{$S APageSetup}

FUNCTION LoadHalftoneSpecs (VAR specs: THalftoneSpecs;
							plural: BOOLEAN): BOOLEAN;

	VAR
		fi: FailInfo;
		where: Point;
		reply: SFReply;
		count: LONGINT;
		refNum: INTEGER;
		version: INTEGER;
		typeList: SFTypeList;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		VAR
			ignore: OSErr;

		BEGIN
		IF refNum <> -1 THEN
			ignore := FSClose (refNum);
		IF error <> noErr THEN
			BEGIN
			IF plural THEN
				message := msgCannotLoadHalftones
			ELSE
				message := msgCannotLoadHalftone;
			gApplication.ShowError (error, message)
			END;
		EXIT (LoadHalftoneSpecs)
		END;

	PROCEDURE ReadSpot (VAR spec: THalftoneSpec);

		BEGIN

		count := -spec.shape;

		IF count > 0 THEN
			BEGIN

			spec.spot := NewPermHandle (count);
			FailNil (spec.spot);

			RegisterSpot (spec.spot);

			HLock (spec.spot);
			FailOSErr (FSRead (refNum, count, spec.spot^));
			HUnlock (spec.spot)

			END

		END;

	BEGIN

	LoadHalftoneSpecs := FALSE;

	refNum := -1;

	CatchFailures (fi, CleanUp);

	WhereToPlaceDialog (getDlgID, where);

	typeList [0] := kHalftoneFileType;

	SFGetFile (where, '', NIL, 1, typeList, NIL, reply);
	IF NOT reply.good THEN Failure (0, 0);

	FailOSErr (FSOpen (reply.fName, reply.vRefNum, refNum));

	count := SIZEOF (INTEGER);

	FailOSErr (FSRead (refNum, count, @version));

	IF version <> kHalftoneVersion THEN
		Failure (errBadFileVersion, 0);

	count := SIZEOF (THalftoneSpecs);

	FailOSErr (FSRead (refNum, count, @specs));

	ReadSpot (specs [0]);
	ReadSpot (specs [1]);
	ReadSpot (specs [2]);
	ReadSpot (specs [3]);

	FailOSErr (FSClose (refNum));

	Success (fi);

	LoadHalftoneSpecs := TRUE

	END;

{*****************************************************************************}

{$S APageSetup}

PROCEDURE SaveHalftoneSpecs (specs: THalftoneSpecs; plural: BOOLEAN);

	VAR
		fi: FailInfo;
		reply: SFReply;
		count: LONGINT;
		prompt: Str255;
		refNum: INTEGER;
		version: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		VAR
			ignore: OSErr;

		BEGIN
		IF refNum <> -1 THEN
			ignore := FSClose (refNum);
		IF error <> noErr THEN
			BEGIN
			IF plural THEN
				message := msgCannotSaveHalftones
			ELSE
				message := msgCannotSaveHalftone;
			gApplication.ShowError (error, message)
			END;
		EXIT (SaveHalftoneSpecs)
		END;

	PROCEDURE WriteSpot (spec: THalftoneSpec);

		BEGIN

		count := -spec.shape;

		IF count > 0 THEN
			BEGIN
			HLock (spec.spot);
			FailOSErr (FSWrite (refNum, count, spec.spot^));
			HUnlock (spec.spot)
			END

		END;

	BEGIN

	refNum := -1;

	CatchFailures (fi, CleanUp);

	IF plural THEN
		GetIndString (prompt, kStringsID, strSaveHalftonesIn)
	ELSE
		GetIndString (prompt, kStringsID, strSaveHalftoneIn);

	refNum := CreateOutputFile (prompt, kHalftoneFileType, reply);

	version := kHalftoneVersion;
	count	:= SIZEOF (INTEGER);

	FailOSErr (FSWrite (refNum, count, @version));

	count := SIZEOF (THalftoneSpecs);

	FailOSErr (FSWrite (refNum, count, @specs));

	WriteSpot (specs [0]);
	WriteSpot (specs [1]);
	WriteSpot (specs [2]);
	WriteSpot (specs [3]);

	FailOSErr (FSClose (refNum));
	refNum := -1;

	FailOSErr (FlushVol (NIL, reply.vRefNum));

	Success (fi)

	END;

{*****************************************************************************}

{$S APageSetup}

FUNCTION EditSpotFunction (VAR h: Handle; color: INTEGER): BOOLEAN;

	CONST
		kDialogID	   = 1220;
		kHookItem	   = 3;
		kSpotItem	   = 4;

		kColorNameList = 1003;
		kCyanID 	   = 9;
		kMagentaID	   = 10;
		kYellowID	   = 11;
		kBlackID	   = 12;

	VAR
		s: Str255;
		id: INTEGER;
		fi: FailInfo;
		count: LONGINT;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		spotHandler: TKeyHandler;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free;
		EXIT (EditSpotFunction)
		END;

	BEGIN

	EditSpotFunction := FALSE;

	IF color < 0 THEN
		s := ''

	ELSE
		BEGIN

			CASE color OF
			0:	id := kCyanID;
			1:	id := kMagentaID;
			2:	id := kYellowID;
			3:	id := kBlackID
			END;

		GetIndString (s, kColorNameList, id);

		INSERT ('(', s, 1);
		INSERT (')', s, LENGTH (s) + 1)

		END;

	ParamText (s, '', '', '');

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	aBWDialog.fAllowReturn := TRUE;

	CatchFailures (fi, CleanUp);

	NEW (spotHandler);
	FailNil (spotHandler);

	spotHandler.IKeyHandler (kSpotItem, aBWDialog);

	aBWDialog.SetEditSelection (kSpotItem);

	IF h <> NIL THEN
		BEGIN

		HLock (h);
		TESetText (h^, GetHandleSize (h),
				   DialogPeek (aBWDialog.fDialogPtr)^.textH);
		HUnlock (h);

		SelIText (aBWDialog.fDialogPtr, kSpotItem, 0, 32767)

		END;

	aBWDialog.TalkToUser (hitItem, StdItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	EditSpotFunction := TRUE;

	count := GetHandleSize (spotHandler.fItemHandle);

	IF (h = NIL) | (GetHandleSize (h) <> count) |
			NOT EqualBytes (h^, spotHandler.fItemHandle^, count) THEN
		BEGIN

		h := NIL;

		IF count > 0 THEN
			BEGIN

			h := NewPermHandle (count);
			FailNil (h);

			BlockMove (spotHandler.fItemHandle^, h^, count);

			RegisterSpot (h)

			END

		END;

	Success (fi);

	aBWDialog.Free;

	END;

{*****************************************************************************}

{$S APageSetup}

PROCEDURE SetHalftoneScreen (VAR spec: THalftoneSpec;
							 allowCustom: BOOLEAN);

	CONST
		kDialogID	= 1221;
		kLoadItem	= 4;
		kSaveItem	= 6;
		kCustomItem = 8;
		kFreqItem	= 9;
		kAngleItem	= 11;
		kFirstShape = 13;
		kLastShape	= 17;

	VAR
		r: Rect;
		h: Handle;
		fi: FailInfo;
		ignore: TCommand;
		ignore1: BOOLEAN;
		ignore2: BOOLEAN;
		hitItem: INTEGER;
		itemType: INTEGER;
		succeeded: BOOLEAN;
		specs: THalftoneSpecs;
		angleText: TFixedText;
		anLSDialog: TLSDialog;
		freqUnit: TUnitSelector;
		shapeCluster: TRadioCluster;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		anLSDialog.Free
		END;

	PROCEDURE StuffValues;
		BEGIN
		freqUnit.StuffFixed (0, spec.frequency.value);
		angleText.StuffValue (ROUND (spec.angle / $10000 * 1000));
		anLSDialog.SetEditSelection (kFreqItem)
		END;

	PROCEDURE GetValues;
		BEGIN

		WITH spec DO
			BEGIN

			frequency.value := freqUnit.GetFixed (0);
			frequency.scale := freqUnit.fPick;
			angle			:= ROUND (angleText.fValue / 1000 * $10000);
			shape			:= shapeCluster.fChosenItem - kFirstShape;

			IF shape >= 0 THEN
				spot := NIL
			ELSE IF spot = NIL THEN
				shape := 0
			ELSE
				shape := -GetHandleSize (spot)

			END

		END;

	BEGIN

	MarkSpotDirty;

	NEW (anLSDialog);
	FailNil (anLSDialog);

	anLSDialog.ILSDialog (kDialogID, kLoadItem, kSaveItem);

	IF NOT allowCustom THEN
		BEGIN
		GetDItem (anLSDialog.fDialogPtr, kCustomItem, itemType, h, r);
		HideControl (ControlHandle (h))
		END;

	CatchFailures (fi, CleanUp);

	freqUnit := anLSDialog.DefineFreqUnit (kFreqItem, 1, spec.frequency.scale);

	angleText := anLSDialog.DefineFixedText
				 (kAngleItem, 3, FALSE, TRUE, -180000, 180000);

	shapeCluster := anLSDialog.DefineRadioCluster
				(kFirstShape - 1,
				 kLastShape,
				 kFirstShape + Max (-1, spec.shape));

	StuffValues;

		REPEAT

		anLSDialog.TalkToUser (hitItem, StdItemHandling);

			CASE hitItem OF

			cancel:
				Failure (0, 0);

			kLoadItem:
				BEGIN

				anLSDialog.UpdateButtons;

				IF anLSDialog.fOptionDown THEN
					spec := gPreferences.fHalftone

				ELSE IF LoadHalftoneSpecs (specs, FALSE) THEN
					spec := specs [3]

				ELSE
					CYCLE;

				freqUnit.SetMenu (freqUnit.fMenu, spec.frequency.scale);

				ignore := shapeCluster.ItemSelected
									   (kFirstShape + Max (-1, spec.shape),
										ignore1,
										ignore2);

				StuffValues

				END;

			kSaveItem:
				BEGIN

				anLSDialog.UpdateButtons;

				anLSDialog.Validate (succeeded);

				IF succeeded THEN
					BEGIN

					GetValues;

					specs [0] := spec;
					specs [1] := spec;
					specs [2] := spec;
					specs [3] := spec;

					IF anLSDialog.fOptionDown THEN
						gPreferences.fHalftone := spec
					ELSE
						SaveHalftoneSpecs (specs, FALSE)

					END

				END;

			kCustomItem:
				IF EditSpotFunction (spec.spot, -1) THEN
					BEGIN

					IF spec.spot = NIL THEN
						spec.shape := Max (shapeCluster.fChosenItem -
										   kFirstShape, 0)
					ELSE
						spec.shape := -GetHandleSize (spec.spot);

					ignore := shapeCluster.ItemSelected
							  (kFirstShape + Max (-1, spec.shape),
							   ignore1,
							   ignore2)

					END

			END

		UNTIL hitItem = ok;

	GetValues;

	Success (fi);

	anLSDialog.Free

	END;

{*****************************************************************************}

{$S APageSetup}

FUNCTION AutoHalftoneScreens (VAR specs: THalftoneSpecs): BOOLEAN;

	CONST
		kDialogID	= 1232;
		kHookItem	= 3;
		kResItem	= 4;
		kFreqItem	= 6;

	TYPE
		TTable = ARRAY [1..999] OF RECORD
								   f, k, c, m, y: INTEGER
								   END;
		PTable = ^TTable;
		HTable = ^PTable;

	VAR
		f: LONGINT;
		fi: FailInfo;
		table: HTable;
		screen: INTEGER;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		resUnit: TUnitSelector;
		freqUnit: TUnitSelector;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free;
		EXIT (AutoHalftoneScreens)
		END;

	FUNCTION ComputeFreq (x, y: EXTENDED): Fixed;

		VAR
			z: EXTENDED;

		BEGIN

		z := gPrinterResolution.value / $10000 / SQRT (SQR (x) + SQR (y));

		IF z > 30000 THEN z := 30000;

		IF gAutoFrequency.scale = 1 THEN
			z := ROUND (z * 10) / 10
		ELSE
			z := ROUND (z / 2.54 * 100) / 100 * 2.54;

		ComputeFreq := ROUND (z * $10000)

		END;

	FUNCTION ComputeAngle (x, y: EXTENDED): Fixed;

		VAR
			theta: EXTENDED;

		BEGIN

		theta := ROUND (ARCTAN (y / x) * 180 / pi * 10) / 10;

		ComputeAngle := ROUND (theta * $10000)

		END;

	BEGIN

	AutoHalftoneScreens := FALSE;

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	resUnit := aBWDialog.DefinePrintResUnit
			   (kResItem, gPrinterResolution.scale);

	resUnit.StuffFixed (0, gPrinterResolution.value);

	freqUnit := aBWDialog.DefineFreqUnit
				(kFreqItem, 1, gAutoFrequency.scale);

	freqUnit.StuffFixed (0, gAutoFrequency.value);

	aBWDialog.SetEditSelection (kResItem);

	aBWDialog.TalkToUser (hitItem, StdItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	gPrinterResolution.value := resUnit.GetFixed (0);
	gPrinterResolution.scale := resUnit.fPick;

	gAutoFrequency.value := freqUnit.GetFixed (0);
	gAutoFrequency.scale := freqUnit.fPick;

	Success (fi);

	aBWDialog.Free;

	table := HTable (GetResource ('CHST', 1000));

	IF table = NIL THEN Failure (1, 0);

	f := ROUND (gAutoFrequency.value / gPrinterResolution.value * 1000);

	screen := 1;

	WHILE f < table^^ [screen] . f DO
		screen := screen + 1;

	WITH table^^ [screen] DO
		BEGIN

		specs [0] . frequency . scale := gAutoFrequency.scale;
		specs [1] . frequency . scale := gAutoFrequency.scale;
		specs [2] . frequency . scale := gAutoFrequency.scale;
		specs [3] . frequency . scale := gAutoFrequency.scale;

		specs [0] . frequency . value := ComputeFreq (c, m);
		specs [1] . frequency . value := ComputeFreq (c, m);
		specs [2] . frequency . value := ComputeFreq (y, 0);
		specs [3] . frequency . value := ComputeFreq (k, k);

		specs [0] . angle := ComputeAngle (c, m) + 90 * $10000;
		specs [1] . angle := ComputeAngle (m, c) + 90 * $10000;
		specs [2] . angle := 90 * $10000;
		specs [3] . angle := 45 * $10000

		END;

	AutoHalftoneScreens := TRUE

	END;

{*****************************************************************************}

{$S APageSetup}

PROCEDURE SetHalftoneScreens (VAR specs: THalftoneSpecs;
							  allowCustom: BOOLEAN);

	CONST
		kDialogID	= 1231;
		kAutoItem	= 4;
		kLoadItem	= 5;
		kSaveItem	= 7;
		kCustomItem = 9;
		kFreqItems	= 10;
		kAngleItems = 15;
		kFirstShape = 20;
		kLastShape	= 24;

	VAR
		r: Rect;
		h: Handle;
		fi: FailInfo;
		color: INTEGER;
		ignore: TCommand;
		ignore1: BOOLEAN;
		ignore2: BOOLEAN;
		hitItem: INTEGER;
		itemType: INTEGER;
		succeeded: BOOLEAN;
		spec: THalftoneSpec;
		anLSDialog: TLSDialog;
		freqUnit: TUnitSelector;
		shapeCluster: TRadioCluster;
		angleText: ARRAY [0..3] OF TFixedText;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		anLSDialog.Free
		END;

	PROCEDURE StuffValues;

		VAR
			j: INTEGER;

		BEGIN

		FOR j := 0 TO 3 DO
			BEGIN
			freqUnit	  . StuffFixed (j, specs [j] . frequency . value);
			angleText [j] . StuffValue (ROUND (specs [j] .angle
										/ $10000 * 1000))
			END;

		anLSDialog.SetEditSelection (kFreqItems)

		END;

	PROCEDURE GetValues;

		VAR
			j: INTEGER;

		BEGIN

		FOR j := 0 TO 3 DO
			WITH specs [j] DO
				BEGIN

				frequency.value := freqUnit.GetFixed (j);
				frequency.scale := freqUnit.fPick;

				angle := ROUND (angleText [j] . fValue / 1000 * $10000);
				shape := shapeCluster.fChosenItem - kFirstShape;

				IF shape >= 0 THEN
					spot := NIL
				ELSE IF spot = NIL THEN
					shape := 0
				ELSE
					shape := -GetHandleSize (spot)

				END

		END;

	BEGIN

	MarkSpotDirty;

	NEW (anLSDialog);
	FailNil (anLSDialog);

	anLSDialog.ILSDialog (kDialogID, kLoadItem, kSaveItem);

	IF NOT allowCustom THEN
		BEGIN
		GetDItem (anLSDialog.fDialogPtr, kCustomItem, itemType, h, r);
		HideControl (ControlHandle (h))
		END;

	CatchFailures (fi, CleanUp);

	freqUnit := anLSDialog.DefineFreqUnit (kFreqItems, 4,
										   specs [0] . frequency . scale);

	FOR color := 0 TO 3 DO
		angleText [color] := anLSDialog.DefineFixedText
							 (kAngleItems + color, 3,
							  FALSE, TRUE, -180000, 180000);

	shapeCluster := anLSDialog.DefineRadioCluster
					(kFirstShape - 1,
					 kLastShape,
					 kFirstShape + Max (-1, specs [0] . shape));

	StuffValues;

		REPEAT

		anLSDialog.TalkToUser (hitItem, StdItemHandling);

			CASE hitItem OF

			cancel:
				Failure (0, 0);

			kAutoItem:
				IF AutoHalftoneScreens (specs) THEN
					BEGIN

					freqUnit.SetMenu (freqUnit.fMenu,
									  specs [0] . frequency . scale);

					StuffValues

					END;

			kLoadItem:
				BEGIN

				anLSDialog.UpdateButtons;

				IF anLSDialog.fOptionDown THEN
					specs := gPreferences.fHalftones

				ELSE IF NOT LoadHalftoneSpecs (specs, TRUE) THEN
					CYCLE;

				freqUnit.SetMenu (freqUnit.fMenu,
								  specs [0] . frequency . scale);

				ignore := shapeCluster.ItemSelected
						  (kFirstShape + Max (-1, specs [0] . shape),
						   ignore1,
						   ignore2);

				StuffValues

				END;

			kSaveItem:
				BEGIN

				anLSDialog.UpdateButtons;

				anLSDialog.Validate (succeeded);

				IF succeeded THEN
					BEGIN

					GetValues;

					IF anLSDialog.fOptionDown THEN
						gPreferences.fHalftones := specs
					ELSE
						SaveHalftoneSpecs (specs, TRUE)

					END

				END;

			kCustomItem:
				FOR color := 0 TO 3 DO
					BEGIN

					spec := specs [color];

					IF EditSpotFunction (spec.spot, color) THEN
						BEGIN

						IF spec.spot = NIL THEN
							spec.shape := Max (shapeCluster.fChosenItem -
											   kFirstShape, 0)
						ELSE
							spec.shape := -GetHandleSize (spec.spot);

						ignore := shapeCluster.ItemSelected
								  (kFirstShape + Max (-1, spec.shape),
								   ignore1,
								   ignore2)

						END

					ELSE
						LEAVE;

					specs [color] := spec;

					IF spec.shape >= 0 THEN
						LEAVE

					END

			END;

		UNTIL hitItem = ok;

	GetValues;

	Success (fi);

	anLSDialog.Free

	END;

{*****************************************************************************}

{$S AScreen}

PROCEDURE FindScreen (limit: INTEGER;
					  period: EXTENDED;
					  theta: EXTENDED;
					  VAR cellSize: INTEGER;
					  VAR cluster: INTEGER;
					  VAR m: INTEGER;
					  VAR n: INTEGER);

	CONST
		kMinPeriod = 1;
		kMaxPeriod = 64;

	VAR
		j: INTEGER;
		k: INTEGER;
		dir: INTEGER;
		step: INTEGER;
		count: INTEGER;
		eCluster: LONGINT;
		tCluster: LONGINT;

	BEGIN

	IF period < kMinPeriod THEN period := kMinPeriod;
	IF period > kMaxPeriod THEN period := kMaxPeriod;
	IF period > limit	   THEN period := limit;

	cluster := 0;

	IF limit <> 1 THEN
		WHILE (cluster < 6) & (SQR (period) * BSL (1, cluster) < 200) DO
			cluster := cluster + 1;

	eCluster := BNOT (BSL (-1, BSR (cluster, 1)));
	tCluster := BNOT (BSL (-1, BSR (cluster + 1, 1)));

	j := ROUND (period * COS (theta));
	k := ROUND (period * SIN (theta));

	dir   := 0;
	step  := 1;
	count := 1;

		REPEAT

		IF (j + k <= limit) & (j > 0) & (k >= 0) & (k <= j) THEN
			BEGIN

			m := j;
			n := k;
			Reduce (n, m);

			WHILE (BAND (m	  , eCluster) <> 0) |
				  (BAND (n	  , eCluster) <> 0) |
				  (BAND (m + n, tCluster) <> 0) DO
				BEGIN
				m := m + m;
				n := n + n
				END;

			cellSize := m * j + n * k;

			IF cellSize <= limit THEN EXIT (FindScreen)

			END;

		count := count - 1;

			CASE dir OF
			0:	j := j + 1;
			1:	k := k + 1;
			2:	j := j - 1;
			3:	k := k - 1
			END;

		IF count = 0 THEN
			BEGIN
			MoveHands (TRUE);
			IF ODD (dir) THEN step := step + 1;
			dir := BAND (dir + 1, 3);
			count := step
			END

		UNTIL FALSE

	END;

{*****************************************************************************}

{$S AScreen}

PROCEDURE ComputeScreen (cellData: Handle;
						 cellSize: INTEGER;
						 cluster: INTEGER;
						 m: INTEGER;
						 n: INTEGER;
						 shape: INTEGER);

	VAR
		j: INTEGER;
		k: INTEGER;
		x: INTEGER;
		y: INTEGER;
		h: EXTENDED;
		hs: LONGINT;
		xf: INTEGER;
		yf: INTEGER;
		fi: FailInfo;
		row: INTEGER;
		col: INTEGER;
		xCell: INTEGER;
		yCell: INTEGER;
		buffer: Handle;
		oldSeed: LONGINT;
		stdCell: INTEGER;
		halfUnit: INTEGER;
		cosTheta: INTEGER;
		sinTheta: INTEGER;
		rowOffset: INTEGER;
		colOffset: INTEGER;
		frequency: LONGINT;
		bufferEntry: PBufferEntry;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (buffer);
		randSeed := oldSeed
		END;

	FUNCTION Spiral (x, y: INTEGER): INTEGER;
		BEGIN
		IF y < 0 THEN
			Spiral := -Spiral (x, -y)
		ELSE IF x < 0 THEN
			Spiral := $2000 - Spiral (-x, y)
		ELSE IF y > x THEN
			Spiral := $1000 - Spiral (y, x)
		ELSE
			Spiral := BSR (y, 4)
		END;

	BEGIN

	IF (shape < 0) OR (shape > 4) THEN
		shape := 0;

	hs := SQR (ORD4 (m)) + SQR (ORD4 (n));
	h  := SQRT (hs);

	cosTheta  := ROUND (BSL (m, 14) / h);
	sinTheta  := ROUND (BSL (n, 14) / h);
	frequency := ROUND ((BSL (1, 30) * h) / cellSize);

	halfUnit := ORD4 (m) * cellSize DIV (hs * 2) +
				ORD4 (n) * cellSize DIV (hs * 2) + 4;

	j := ORD4 (cellSize) * m DIV hs;
	k := ORD4 (cellSize) * n DIV hs;

	stdCell := SQR (ORD4 (cellSize)) DIV hs;

	buffer := NewLargeHandle (ORD4 (stdCell) * SIZEOF (TBufferEntry));

	oldSeed  := randSeed;
	randSeed := 1;

	CatchFailures (fi, CleanUp);

	HLock (buffer);

	IF (shape = 0) AND (j = k) AND NOT ODD (j) THEN
		BEGIN
		rowOffset := 16;
		colOffset := 16
		END
	ELSE
		BEGIN
		rowOffset := 0;
		colOffset := 0
		END;

	bufferEntry := PBufferEntry (buffer^);

	FOR row := -halfUnit TO halfUnit DO
		BEGIN

		MoveHands (TRUE);

		FOR col := -halfUnit TO halfUnit DO
			IF InsideUnitCell (row, col, j, k) THEN
				BEGIN

				CvtToGridCoords (LoWrd (BSL (row, 5)) + rowOffset,
								 LoWrd (BSL (col, 5)) + colOffset,
								 cosTheta, sinTheta, frequency,
								 x, y, xf, yf);

				WITH bufferEntry^ DO
					BEGIN

						CASE shape OF
						0:	fPriority := DotScreenProc	   (xf, yf);
						1:	fPriority := EllipseScreenProc (xf, yf);
						2:	fPriority := LineScreenProc    (xf, yf);
						3:	fPriority := SquareScreenProc  (xf, yf);
						4:	fPriority := CrossScreenProc   (xf, yf)
						END;

					IF shape <= 1 THEN
						fRandom := Spiral (xf, yf)
					ELSE
						fRandom := Random;

					fRow := row;
					fCol := col

					END;

				bufferEntry := PBufferEntry (ORD4 (bufferEntry) +
											 SIZEOF (TBufferEntry))

				END

		END;

	qsort (buffer^,
		   stdCell,
		   SIZEOF (TBufferEntry),
		   @CompareCells);

	FOR xCell := 0 TO m + n - 1 DO
		FOR yCell := -n TO m - 1 DO
			BEGIN

			MoveHands (TRUE);

			x := xCell;
			y := yCell;

			NormGridCoords (m, n, hs, x, y);

			IF (x = xCell) AND (y = yCell) THEN
				CompScreenValues (buffer^,
								  stdCell,
								  xCell * j - yCell * k,
								  xCell * k + yCell * j,
								  cluster,
								  ClusterOffset (xCell, yCell, cluster),
								  cellData^,
								  cellSize)

			END;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S AScreen}

PROCEDURE MakeScreen (limit: INTEGER;
					  resolution: Fixed;
					  spec: THalftoneSpec;
					  VAR cellData: Handle;
					  VAR cellSize: INTEGER);

	VAR
		m: INTEGER;
		n: INTEGER;
		fi: FailInfo;
		row: INTEGER;
		col: INTEGER;
		flipH: BOOLEAN;
		flipV: BOOLEAN;
		flipD: BOOLEAN;
		theta: EXTENDED;
		period: EXTENDED;
		cluster: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (cellData)
		END;

	BEGIN

	MoveHands (TRUE);

	period := resolution / spec.frequency.value;

	theta := 90.0 - spec.angle / $10000;

	WHILE theta >	180.0 DO theta := theta - 360.0;
	WHILE theta <= -180.0 DO theta := theta + 360.0;

	flipH := theta < 0.0;
	IF flipH THEN theta := -theta;

	flipV := theta > 90.0;
	IF flipV THEN theta := 180.0 - theta;

	flipD := theta > 45.0;
	IF flipD THEN theta := 90.0 - theta;

	theta := theta * pi / 180.0;

	FindScreen (limit, period, theta, cellSize, cluster, m, n);

	MoveHands (TRUE);

	cellData := NewLargeHandle (SQR (ORD4 (cellSize)));

	CatchFailures (fi, CleanUp);

	MoveHHi (cellData);
	HLock (cellData);

	ComputeScreen (cellData, cellSize, cluster, m, n, spec.shape);

	MoveHands (TRUE);

	IF flipD THEN
		FOR row := 0 TO cellSize - 2 DO
			DoStepSwapBytes (Ptr (ORD4 (cellData^) +
								  ORD4 (cellSize) * row + (row + 1)),
							 Ptr (ORD4 (cellData^) +
								  ORD4 (cellSize) * (row + 1) + row),
							 cellSize - 1 - row,
							 1,
							 cellSize);

	MoveHands (TRUE);

	IF flipV THEN
		FOR col := 0 TO cellSize - 1 DO
			DoStepSwapBytes (Ptr (ORD4 (cellData^) + col),
							 Ptr (ORD4 (cellData^) + col +
								  ORD4 (cellSize - 1) * cellSize),
							 BSR (cellSize, 1),
							 cellSize,
							 -cellSize);

	MoveHands (TRUE);

	IF flipH THEN
		FOR row := 0 TO cellSize - 1 DO
			DoStepSwapBytes (Ptr (ORD4 (cellData^) +
								  ORD4 (cellSize) * row),
							 Ptr (ORD4 (cellData^) +
								  ORD4 (cellSize) * row + cellSize - 1),
							 BSR (cellSize, 1),
							 1,
							 -1);

	HUnlock (cellData);

	Success (fi)

	END;

{*****************************************************************************}

{$S AScreen}

FUNCTION ConvertScreen (cellData: Handle; cellSize: INTEGER): TVMArray;

	VAR
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		aVMArray: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (aVMArray);
		FreeLargeHandle (cellData)
		END;

	BEGIN

	aVMArray := NIL;

	CatchFailures (fi, CleanUp);

	aVMArray := NewVMArray (cellSize, cellSize, 1);

	FOR row := 0 TO cellSize - 1 DO
		BEGIN

		dstPtr := aVMArray.NeedPtr (row, row, TRUE);

		BlockMove (Ptr (ORD4 (cellData^) + row * ORD4 (cellSize)),
				   dstPtr, cellSize);

		aVMArray.DoneWithPtr

		END;

	aVMArray.Flush;

	Success (fi);

	FreeLargeHandle (cellData);

	ConvertScreen := aVMArray

	END;

{*****************************************************************************}

{$S AScreen}

PROCEDURE HalftoneArea (srcArray: TVMArray;
						dstArray: TVMArray;
						r: Rect;
						newRows: INTEGER;
						newCols: INTEGER;
						map: PLookUpTable;
						screen: TVMArray;
						canAbort: BOOLEAN);

	CONST
		kPeakNoise	= 15;
		kExtraNoise = 1024;

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		tempPtr: Ptr;
		noisePtr: Ptr;
		bSize: LONGINT;
		thisError: Ptr;
		nextError: Ptr;
		newRow: INTEGER;
		oldRow: INTEGER;
		buffer1: Handle;
		buffer2: Handle;
		buffer3: Handle;
		buffer4: Handle;
		oldSeed: LONGINT;
		lastRow: INTEGER;
		screenRow: INTEGER;
		freeHTable: BOOLEAN;
		freeVTable: BOOLEAN;
		hTable: TResizeTable;
		vTable: TResizeTable;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		IF freeHTable THEN hTable.Free;
		IF freeVTable THEN vTable.Free;

		FreeLargeHandle (buffer1);
		FreeLargeHandle (buffer2);
		FreeLargeHandle (buffer3);
		FreeLargeHandle (buffer4);

		IF dstPtr <> NIL THEN
			dstArray.DoneWithPtr;

		srcArray.Flush;
		dstArray.Flush;

		IF screen <> NIL THEN
			screen.Flush;

		randSeed := oldSeed

		END;

	BEGIN

	freeHTable := FALSE;
	freeVTable := FALSE;

	buffer1 := NIL;
	buffer2 := NIL;
	buffer3 := NIL;
	buffer4 := NIL;

	oldSeed := randSeed;

	dstPtr := NIL;

	CatchFailures (fi, CleanUp);

	NEW (hTable);
	FailNil (hTable);

	hTable.IResizeTable (r.right - r.left, newCols, TRUE);

	freeHTable := TRUE;

	NEW (vTable);
	FailNil (vTable);

	vTable.IResizeTable (r.bottom - r.top, newRows, TRUE);

	freeVTable := TRUE;

	buffer1 := NewLargeHandle (newCols);

	IF screen = NIL THEN
		BEGIN

		bSize := BSL (newCols + 2, 1);

		buffer2 := NewLargeHandle (bSize);
		buffer3 := NewLargeHandle (bSize);

		buffer4 := NewLargeHandle (newCols + kExtraNoise);

		HLock (buffer2);
		HLock (buffer3);
		HLock (buffer4);

		thisError := Ptr (ORD4 (buffer2^) + 2);
		nextError := Ptr (ORD4 (buffer3^) + 2);

		DoSetBytes (nextError, BSL (newCols, 1), 0);

		randSeed := 1;

		MakeWhiteNoise (buffer4^,
						newCols + kExtraNoise,
						-kPeakNoise, kPeakNoise)

		END;

	lastRow := -1;

	FOR newRow := 0 TO newRows - 1 DO
		BEGIN

		MoveHands (canAbort);

		UpdateProgress (newRow, newRows);

		oldRow := vTable.fTable1^^ [newRow] + r.top;

		IF oldRow <> lastRow THEN
			BEGIN

			srcPtr := srcArray.NeedPtr (oldRow, oldRow, FALSE);

			hTable.ResizeLine (Ptr (ORD4 (srcPtr) + r.left), buffer1^);

			srcArray.DoneWithPtr;

			IF map <> NIL THEN
				DoMapBytes (buffer1^, newCols, map^);

			lastRow := oldRow

			END;

		dstPtr := dstArray.NeedPtr (newRow, newRow, TRUE);

		IF screen = NIL THEN
			BEGIN

			tempPtr   := nextError;
			nextError := thisError;
			thisError := tempPtr;

			noisePtr := Ptr (ORD4 (buffer4^) +
							 BAND (Random, kExtraNoise - 1));

			DoSetBytes (nextError, BSL (newCols, 1), 0);

			DoSetBytes (dstPtr, dstArray.fLogicalSize, 0);

			DoDiffuseRow (buffer1^,
						  dstPtr,
						  thisError,
						  nextError,
						  noisePtr,
						  newCols)

			END

		ELSE
			BEGIN

			screenRow := newRow MOD screen.fBlockCount;

			srcPtr := screen.NeedPtr (screenRow, screenRow, FALSE);

			DoScreenRow (buffer1^,
						 dstPtr,
						 newCols,
						 srcPtr,
						 screen.fLogicalSize);

			screen.DoneWithPtr

			END;

		dstArray.DoneWithPtr;

		dstPtr := NIL

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

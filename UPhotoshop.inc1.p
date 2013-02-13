{Photoshop version 1.0.1, file: UPhotoshop.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAbout.p.inc}
{$I UAdjust.p.inc}
{$I UAssembly.a.inc}
{$I UCalculate.p.inc}
{$I UChannel.p.inc}
{$I UConvert.p.inc}
{$I UCoords.p.inc}
{$I UCrop.p.inc}
{$I UDither.a.inc}
{$I UDraw.p.inc}
{$I UFilter.p.inc}
{$I UFloat.p.inc}
{$I UGhost.p.inc}
{$I UHistogram.p.inc}
{$I UInitFormats.p.inc}
{$I UInternal.p.inc}
{$I ULine.p.inc}
{$I UMagnification.p.inc}
{$I UPasteControls.p.inc}
{$I UPick.p.inc}
{$I UPreferences.p.inc}
{$I UPrint.p.inc}
{$I UResize.p.inc}
{$I URotate.p.inc}
{$I UScan.p.inc}
{$I UScreen.a.inc}
{$I UScreen.p.inc}
{$I USelect.p.inc}
{$I USeparation.p.inc}
{$I UTable.p.inc}
{$I UText.p.inc}
{$I UTrap.p.inc}

CONST

	kWindowMenu  = 7;
	kTableMenu	 = 33;
	kAcquireMenu = 37;
	kFilterMenu  = 39;
	kChannelMenu = 42;
	kExportMenu  = 43;

	MBarHeight = $BAA;

VAR

	gDoingUpdate: BOOLEAN;
	gDoingScroll: BOOLEAN;

	gInBackground: BOOLEAN;

	gLastReply: SFReply;

	gFileSize: LONGINT;

	gPopUpMenu: MenuHandle;

	gOpenAsFormat: INTEGER;

	gTempRgn1: RgnHandle;
	gTempRgn2: RgnHandle;
	gTempRgn3: RgnHandle;

	gSaveGrayRgn: RgnHandle;

	gSaveEventMask: INTEGER;

	gWNEIsImplemented: BOOLEAN;

	gSplashScreen: BOOLEAN;

	gInitedPreferences: BOOLEAN;
	gInitedVirtualMemory: BOOLEAN;

	gOutlineCache: RECORD
		doc: TImageDocument;
		mag: INTEGER;
		area: Rect;
		data: Handle;
		END;

	gLastFilter: INTEGER;

	gRgnFillPixMap: PixMap;
	gRgnFillData  : PACKED ARRAY [0..1023] OF CHAR;
	gRgnFillNoise : TNoiseTable;

	gNoDocuments: BOOLEAN;
	gToolsPalette1: PaletteHandle;
	gToolsPalette2: PaletteHandle;

	gNewColor: BOOLEAN;
	gNewWidth: FixedScaled;
	gNewHeight: FixedScaled;
	gNewResolution: FixedScaled;

	gScratchSelection: BOOLEAN;

	gHideCursor: BOOLEAN;
	gCursorHidden: BOOLEAN;
	gHiddenLocation: Point;

	gTableFixed: INTEGER;
	gWindowFixed: INTEGER;

PROCEDURE qsort (base: Ptr;
				 nelem: LONGINT;
				 elSize: LONGINT;
				 compar: ProcPtr); C; EXTERNAL;

{*****************************************************************************}

{$S ARes}

FUNCTION CreateOutputFile (prompt: Str255;
						   fileType: OSType;
						   VAR reply: SFReply): INTEGER;

	VAR
		err: OSErr;
		where: Point;
		refNum: INTEGER;

	BEGIN

	WhereToPlaceDialog (putDlgID, where);

	SFPutFile (where, prompt, '', NIL, reply);
	IF NOT reply.good THEN Failure (0, 0);
	
	err := Create (reply.fName, reply.vRefNum, kSignature, fileType);
	
	IF err = dupFNErr THEN
		BEGIN
		FailOSErr (DeleteFile (@reply.fName, reply.vRefNum));
		err := Create (reply.fName, reply.vRefNum, kSignature, fileType)
		END;
		
	FailOSErr (err);
		
	FailOSErr (FSOpen (reply.fName, reply.vRefNum, refNum));

	CreateOutputFile := refNum

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitRgnFillRGB;

	VAR
		r: INTEGER;
		c: INTEGER;
		size: INTEGER;

	BEGIN

	CompNoiseTable (1, 255, size, gRgnFillNoise);

	WITH gRgnFillPixMap DO
		BEGIN

		baseAddr	  := @gRgnFillData;
		rowBytes	  := $8000 + 16;
		bounds.top	  := 0;
		bounds.left   := 0;
		bounds.bottom := 64;
		bounds.right  := 64;
		pmVersion	  := 0;
		packType	  := 0;
		packSize	  := 0;
		hRes		  := $480000;
		vRes		  := $480000;
		pixelType	  := 0;
		pixelSize	  := 2;
		cmpCount	  := 1;
		cmpSize 	  := 2;
		planeBytes	  := 0;
		pmReserved	  := 0;

		pmTable := CTabHandle (NewHandle (SIZEOF (ColorTable) +
										  SIZEOF (ColorSpec) * 3));
		FailNil (pmTable);

		WITH pmTable^^ DO
			BEGIN

			transIndex := 0;
			ctSize	   := 3;

			{$PUSH}
			{$R-}
			FOR r := 0 TO 3 DO
				ctTable [r] . value := r;
			{$POP}

			END;

		FOR r := 0 TO 63 DO
			FOR c := 0 TO 15 DO
				IF ODD (r) THEN
					gRgnFillData [r * 16 + c] := CHR ($EE)
				ELSE
					gRgnFillData [r * 16 + c] := CHR ($11)

		END

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE TPhotoshopApplication.IPhotoshopApplication;

	CONST
		kFormatsMenu = 1000;

	VAR
		r1: Rect;
		r2: Rect;
		j: INTEGER;
		r: INTEGER;
		g: INTEGER;
		b: INTEGER;
		fi: FailInfo;
		gdh: GDHandle;
		gray: INTEGER;
		temp: INTEGER;
		state: INTEGER;
		int0: Intl0Hndl;
		theWorld: SysEnvRec;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF error <> noErr THEN
			BEGIN
			IF message = 0 THEN message := msgInitFailed;
			ShowError (error, message);
			ExitToShell
			END
		END;

	BEGIN

	gInitializedPS := FALSE;

	gSplashScreen := FALSE;

	gInitedPreferences := FALSE;
	gInitedVirtualMemory := FALSE;

	gSaveEventMask := PInteger (SysEvtMask)^;

	SetEventMask (EveryEvent);

	IApplication (kFileType);

	FailOSErr (SysEnvirons (1, theWorld));

	IF NOT gConfiguration.hasHierarchicalMenus OR
		(theWorld.systemVersion < $0602) THEN Failure (errOldSys, 0);

	gWNEIsImplemented := NGetTrapAddress (_WaitNextEvent, ToolTrap) <>
						 NGetTrapAddress (_Unimplemented, ToolTrap);

	gHideCursor   := FALSE;
	gCursorHidden := FALSE;

	IF gConfiguration.hasColorToolbox THEN
		gHas32BitQuickDraw := NGetTrapAddress ($AB03, ToolTrap) <>
							  NGetTrapAddress (_Unimplemented, ToolTrap)
	ELSE
		gHas32BitQuickDraw := FALSE;

	{$IFC qDebug}
	IF gHas32BitQuickDraw THEN
		writeln ('Has 32-bit QuickDraw');
	{$ENDC}
	
	gMetric := IUMetric;

	GetFNum ('Geneva', gGeneva);
	IF gGeneva = 0 THEN gGeneva := geneva;

	GetFNum ('Monaco', gMonaco);
	IF gMonaco = 0 THEN gMonaco := monaco;

	GetFNum ('Helvetica', gHelvetica);
	IF gHelvetica = 0 THEN gHelvetica := helvetica;

	SetFractEnable (TRUE);

	FOR gray := 0 TO 255 DO
		BEGIN
		gNullLUT [gray]   := CHR (gray);
		gInvertLUT [gray] := CHR (255 - gray)
		END;

	CatchFailures (fi, CleanUp);

	RegisterCopy;

	VerifyEvE;

	InitScreens;

	InitPreferences;
	gInitedPreferences := TRUE;

	IF NOT gFinderPrinting THEN
		BEGIN

		ShowSplashScreen;
		gSplashScreen := TRUE;

		gTableFixed := CountMItems (GetResMenu (kTableMenu));
		gWindowFixed := CountMItems (GetResMenu (kWindowMenu));

		InsertResMenu (GetResMenu (kTableMenu), 'PLUT', gTableFixed);
		InsertResMenu (GetResMenu (kFilterMenu), 'FILT', 0)

		END;

	gGrayLUT.R [0] := CHR (0);
	gGrayLUT.G [0] := CHR (0);
	gGrayLUT.B [0] := CHR (0);

	r := 0;
	g := 0;
	b := 0;

	FOR gray := 1 TO 255 DO
		BEGIN

		r := r + 30;
		g := g + 59;
		b := b + 11;

		gGrayLUT.R [gray] := gGrayLUT.R [gray - 1];
		gGrayLUT.G [gray] := gGrayLUT.G [gray - 1];
		gGrayLUT.B [gray] := gGrayLUT.B [gray - 1];

		IF (r >= g) AND (r >= b) THEN
			BEGIN
			r := r - 100;
			gGrayLUT.R [gray] := SUCC (gGrayLUT.R [gray])
			END
		ELSE IF g >= b THEN
			BEGIN
			g := g - 100;
			gGrayLUT.G [gray] := SUCC (gGrayLUT.G [gray])
			END
		ELSE
			BEGIN
			b := b - 100;
			gGrayLUT.B [gray] := SUCC (gGrayLUT.B [gray])
			END

		END;

	InitGhosts;
	InitFormats;
	InitWatches;
	InitSelections;
	InitCvtOptions;
	InitDrawing;
	InitAdjustments;
	InitFilters;
	InitRotations;
	InitScanners;
	InitPasteControls;
	InitFloatCommands;
	InitImagePrinting;
	InitResize;
	InitTraps;
	InitCrops;
	InitCalculate;
	InitTextTool;
	InitLineTool;
	InitProgress;
	InitSeparation;

	{$IFC qBarneyscan}
	InitCoords;
	{$ENDC}

	int0 := Intl0Hndl (IUGetIntl (0));
	FailNil (int0);

	gDecimalPt := int0^^.decimalPt;

	gPrinterResolution.value := 1270 * $10000;
	gPrinterResolution.scale := 1;

	gNewColor := TRUE;
	gNewWidth.scale := 1;
	gNewWidth.value := 512 * $10000;
	gNewHeight.scale := 1;
	gNewHeight.value := 512 * $10000;
	gNewResolution.scale := 1;
	gNewResolution.value := 72 * $10000;

	gTempRgn1 := NewRgn;
	gTempRgn2 := NewRgn;
	gTempRgn3 := NewRgn;

	gDoingUpdate := FALSE;
	gDoingScroll := FALSE;

	gInBackground := FALSE;

	gPopUpMenu := GetMenu (kFormatsMenu);
	FailNil (gPopUpMenu);

	gOpenAsFormat := kFmtCodeRaw;

	gStaggerCount := 0;

	gForegroundColor.red   := 0;
	gForegroundColor.green := 0;
	gForegroundColor.blue  := 0;

	gBackgroundColor.red   := $FFFF;
	gBackgroundColor.green := $FFFF;
	gBackgroundColor.blue  := $FFFF;

	gCloneDoc	 := NIL;
	gCloneTarget := NIL;

	InitRgnFillRGB;

	gTool := MarqueeTool;

	NEW (gToolsView);
	FailNil (gToolsView);

	gToolsView.IToolsView;

	StuffHex (@gHLPattern[0], 'F0E1C3870F1E3C78');
	StuffHex (@gHLPattern[1], '78F0E1C3870F1E3C');
	StuffHex (@gHLPattern[2], '3C78F0E1C3870F1E');
	StuffHex (@gHLPattern[3], '1E3C78F0E1C3870F');
	StuffHex (@gHLPattern[4], '0F1E3C78F0E1C387');
	StuffHex (@gHLPattern[5], '870F1E3C78F0E1C3');
	StuffHex (@gHLPattern[6], 'C3870F1E3C78F0E1');
	StuffHex (@gHLPattern[7], 'E1C3870F1E3C78F0');

	FOR state := 0 TO kHLPatterns - 1 DO
		FOR j := 0 TO 7 DO
			BEGIN

			temp := (state + kHLPatterns - 1) MOD kHLPatterns;

			temp := BXOR (gHLPattern [state] [j],
						  gHLPattern [temp ] [j]);

			gHLPatternDelta [state] [j] := temp

			END;

	r1 := screenBits.bounds;

	IF gConfiguration.hasColorToolbox THEN
		BEGIN

		gdh := GetDeviceList;

		WHILE gdh <> NIL DO
			BEGIN

			r2 := gdh^^.gdRect;

			IF ORD4 (r2.right - r2.left) *
					(r2.bottom - r2.top) >
			   ORD4 (r1.right - r1.left) *
					(r1.bottom - r1.top) THEN r1 := r2;

			gdh := GetNextDevice (gdh)

			END

		END;

	gOutlineCache.doc  := NIL;
	gOutlineCache.data := NewPermHandle
						  (BSL (BSR (r1.right - r1.left + 15, 4), 1) *
									(r1.bottom - r1.top));
	FailMemError;

	NEW (gTables);
	FailNil (gTables);

	gTables.ITables;

	gLastFilter := 0;

	InitVM;
	gInitedVirtualMemory := TRUE;

	InitPicker;

	VerifyHardware;

	Success (fi);

	gInitializedPS := TRUE

	END;

{*****************************************************************************}

{$S ATerminate}

PROCEDURE TPhotoshopApplication.Terminate; OVERRIDE;

	BEGIN

	SetEventMask (gSaveEventMask);

	IF gInitedVirtualMemory THEN
		TermVM;

	IF gInitedPreferences THEN
		SavePreferences

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TPhotoshopApplication.ShowError
		(error: OSErr; message: LONGINT); OVERRIDE;

	CONST

		kGenErrorID   = 802;
		kCmdErrorID   = 803;
		kUnknownErrID = 804;

		kMsgCmdErr	 = msgCmdErr	  DIV $10000;
		kMsgAlert	 = msgAlert 	  DIV $10000;
		kMsgLookup	 = msgLookup	  DIV $10000;
		kMsgAltRecov = msgAltRecovery DIV $10000;

	VAR
		x: BOOLEAN;
		item: INTEGER;
		errStr: Str255;
		recovErr: OSErr;
		opString: Str255;
		recovery: Str255;
		alertID: INTEGER;

	BEGIN

	IF gInBackground THEN
		BEGIN
		gInBackground := FALSE;
		HiliteGhosts (TRUE)
		END;

	alertID := kGenErrorID;
	opString := '';

		CASE HiWrd (message) OF

		kMsgCmdErr:
			BEGIN
			alertID := kCmdErrorID;
			CmdToName (LoWrd (message), opString);
			END;

		kMsgAlert:
			BEGIN
			INHERITED ShowError (error, message);
			EXIT (ShowError)
			END;

		kMsgLookup,
		kMsgAltRecov:
			x := LookupErrString (LoWrd (message), errOperationsID, opString);

		OTHERWISE
			GetIndString (opString, HiWrd (message), LoWrd (message))

		END;

	x := LookupErrString (error, errReasonID, errStr);

	IF HiWrd (message) = kMsgAltRecov THEN
		recovErr := LoWrd (message)
	ELSE
		recovErr := error;

	x := LookupErrString (recovErr, errRecoveryID, recovery);

	ParamText (errStr, recovery, opString, gErrorParm3);

	IF opString = '' THEN alertID := kUnknownErrID;

	IF (alertID = kGenErrorID) OR
	   (alertID = kCmdErrorID) OR
	   (alertID = kUnknownErrID) THEN
		item := BWAlert (alertID, error, TRUE)
	ELSE
		BWNotice (alertID, TRUE)

	END;

{*****************************************************************************}

{$S Main}

PROCEDURE TPhotoshopApplication.MainEventLoop; OVERRIDE;

	BEGIN

	IF gSplashScreen THEN
		BEGIN
		KillSplashScreen;
		gSplashScreen := FALSE
		END;

	INHERITED MainEventLoop

	END;

{*****************************************************************************}

{$S ARes}

FUNCTION TPhotoshopApplication.GetEvent
		(eventMask: INTEGER; VAR anEvent: EventRecord): BOOLEAN; OVERRIDE;

	VAR
		pt: Point;
		sleep: LONGINT;
		result: BOOLEAN;
		doc: TImageDocument;
		mouseRgn: RgnHandle;

	BEGIN

	IF (eventMask = gMainEventMask) AND NOT gInBackground THEN
		BEGIN

		IF (gFrontWindow <> NIL) &
		   (IsGhostWindow (gFrontWindow.fWmgrWindow)) THEN
			BEGIN
			gFrontWindow := NIL;
			gTarget := SELF
			END;

		MoveGhostsForward;

		IF NOT gNoDocuments AND (gDocList.fSize = 0) THEN
			IF gToolsPalette2 <> NIL THEN
				BEGIN
				MakeIntoGhost	(gToolsWindow, FALSE);
				SetPalette		(gToolsWindow, gToolsPalette2, TRUE);
				ActivatePalette (gToolsWindow);
				SetPalette		(gToolsWindow, gToolsPalette1, TRUE);
				MakeIntoGhost	(gToolsWindow, TRUE)
				END;

		gNoDocuments := (gDocList.fSize = 0)

		END

	ELSE IF gInBackground THEN
		gNoDocuments := FALSE;

	IF (eventMask <> gMainEventMask) OR (fIdlePriority <> 0) THEN
		sleep := 0

	ELSE IF gInBackground THEN
		sleep := 50

	ELSE IF NOT gMenusAreSetup OR gRedrawMenuBar THEN
		sleep := 0

	ELSE IF gDocument <> NIL THEN
		BEGIN

		doc := TImageDocument (gDocument);

		IF doc.fIdlePriority <> 0 THEN
			sleep := Max (0, doc.fFlickerTime - TickCount)
		ELSE
			sleep := 10

		END

	ELSE IF PickerVisible THEN
		sleep := 10

	ELSE
		sleep := 50;

	IF (gScratchDoc.fIdlePriority <> 0) & PickerVisible THEN
		sleep := 0;

	IF (sleep > 0) AND ((sleep < 50) OR gCursorHidden) THEN
		BEGIN
		GetMouse (pt);
		LocalToGlobal (pt);
		SetRectRgn (gTempRgn1, pt.h, pt.v, pt.h + 1, pt.v + 1);
		mouseRgn := gTempRgn1
		END
	ELSE
		mouseRgn := NIL;

	IF gWNEIsImplemented THEN
		BEGIN
		ResetBusyCursor;
		result := WaitNextEvent (eventMask, anEvent, sleep, mouseRgn)
		END
	ELSE
		BEGIN
		SystemTask;
		result := GetNextEvent (eventMask, anEvent)
		END;

	IF gCursorHidden THEN
		BEGIN
		GetMouse (pt);
		LocalToGlobal (pt);
		IF (LONGINT (pt) <> LONGINT (gHiddenLocation)) |
		   (anEvent.what IN [mouseDown, keyDown, autoKey]) THEN
			BEGIN
			ShowCursor;
			gCursorHidden := FALSE
			END
		END;

	IF gHideCursor THEN
		IF gInBackground | gCursorHidden THEN
			gHideCursor := FALSE
		ELSE
			IF (anEvent.what = nullEvent) &
					(fIdlePriority = 0) &
					gMenusAreSetup &
					NOT gRedrawMenuBar THEN
				BEGIN
				GetMouse (gHiddenLocation);
				LocalToGlobal (gHiddenLocation);
				HideCursor;
				gCursorHidden := TRUE;
				gHideCursor := FALSE
				END;

	IF result AND (anEvent.what = activateEvt) THEN
		IF IsGhostWindow (WindowPtr (anEvent.message)) THEN
			IF FrontWindow <> NIL THEN
				BEGIN
				anEvent.message := LONGINT (FrontWindow);
				HiliteWindow (FrontWindow, TRUE)
				END;

	GetEvent := result;

	gMovingHands := FALSE

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE SetToolCursor (tool: TTool; allowCross: BOOLEAN);

	CONST
		kLassoCursor	   = 501;
		kHandCursor 	   = 502;
		kZoomCursor 	   = 503;
		kZoomOutCursor	   = 504;
		kZoomLimitCursor   = 505;
		kEyedropperCursor  = 506;
		kMarqueeCursor	   = 507;
		kEraserCursor	   = 508;
		kPencilCursor	   = 509;
		kBrushCursor	   = 510;
		kAirbrushCursor    = 511;
		kBlurCursor 	   = 512;
		kSmudgeCursor	   = 513;
		kBucketCursor	   = 514;
		kSharpenCursor	   = 515;
		kLineCursor 	   = 516;
		kMoveCursor 	   = 517;
		kWandCursor 	   = 518;
		kStampCursor	   = 519;
		kStampPadCursor    = 520;
		kMagicCursor	   = 521;
		kGradientCursor    = 522;
		kCrosshairCursor   = 523;
		kPickupCursor	   = 524;
		kCroppingCursor    = 525;
		kEllipseCursor	   = 526;
		kTextCursor 	   = 527;
		kCropFinishCursor  = 528;

	VAR
		theKeys: KeyMap;
		crosshair: BOOLEAN;

	BEGIN

	gMovingHands := FALSE;

	IF allowCross THEN
		BEGIN
		GetKeys (theKeys);
		crosshair := theKeys [kCapsLockCode]
		END
	ELSE
		crosshair := FALSE;

	IF crosshair & (tool IN [PencilTool, BrushTool, AirbrushTool,
							 BlurTool, SmudgeTool, LassoTool, WandTool,
							 BucketTool, SharpenTool, StampTool]) THEN

		SetCursor (GetCursor (kCrosshairCursor)^^)

	ELSE IF crosshair & (tool IN [EyedropperTool, EyedropperBackTool,
								  StampPadTool]) THEN

		SetCursor (GetCursor (kPickupCursor)^^)

	ELSE
		CASE tool OF

		MarqueeTool:
			SetCursor (GetCursor (kMarqueeCursor)^^);

		LassoTool:
			SetCursor (GetCursor (kLassoCursor)^^);

		HandTool:
			SetCursor (GetCursor (kHandCursor)^^);

		ZoomTool:
			SetCursor (GetCursor (kZoomCursor)^^);

		ZoomOutTool:
			SetCursor (GetCursor (kZoomOutCursor)^^);

		ZoomLimitTool:
			SetCursor (GetCursor (kZoomLimitCursor)^^);

		EyedropperTool,
		EyedropperBackTool:
			SetCursor (GetCursor (kEyedropperCursor)^^);

		EraserTool:
			SetCursor (GetCursor (kEraserCursor)^^);

		PencilTool:
			SetCursor (GetCursor (kPencilCursor)^^);

		BrushTool:
			SetCursor (GetCursor (kBrushCursor)^^);

		AirbrushTool:
			SetCursor (GetCursor (kAirbrushCursor)^^);

		BlurTool:
			SetCursor (GetCursor (kBlurCursor)^^);

		SmudgeTool:
			SetCursor (GetCursor (kSmudgeCursor)^^);

		BucketTool:
			SetCursor (GetCursor (kBucketCursor)^^);

		SharpenTool:
			SetCursor (GetCursor (kSharpenCursor)^^);

		LineTool:
			SetCursor (GetCursor (kLineCursor)^^);

		MoveTool:
			SetCursor (GetCursor (kMoveCursor)^^);

		WandTool:
			SetCursor (GetCursor (kWandCursor)^^);

		StampTool:
			SetCursor (GetCursor (kStampCursor)^^);

		StampPadTool:
			SetCursor (GetCursor (kStampPadCursor)^^);

		MagicTool:
			SetCursor (GetCursor (kMagicCursor)^^);

		GradientTool:
			SetCursor (GetCursor (kGradientCursor)^^);

		CroppingTool:
			SetCursor (GetCursor (kCroppingCursor)^^);

		EllipseTool:
			SetCursor (GetCursor (kEllipseCursor)^^);

		TextTool:
			SetCursor (GetCursor (kTextCursor)^^);

		CropFinishTool:
			SetCursor (GetCursor (kCropFinishCursor)^^);

		OTHERWISE
			SetCursor (arrow)

		END

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE TPhotoshopApplication.DoTrackCursor (mousePt: Point;
											   spaceDown: BOOLEAN;
											   shiftDown: BOOLEAN;
											   optionDown: BOOLEAN;
											   commandDown: BOOLEAN);

	VAR
		r: Rect;
		pt: Point;
		maskPtr: Ptr;
		part: INTEGER;
		inside: BOOLEAN;
		view: TImageView;
		canMove: BOOLEAN;
		doc: TImageDocument;
		theWindow: WindowPtr;

	PROCEDURE TestInsideView (theView: TImageView);

		BEGIN

		IF NOT inside & (theView.fWindow.fWmgrWindow = theWindow) THEN
			BEGIN

			theView.fFrame.Focus;
			theView.fFrame.GetViewedRect (r);

			pt := mousePt;
			GlobalToLocal (pt);

			IF PtInRect (pt, r) THEN
				BEGIN
				view := theView;
				inside := TRUE
				END

			END

		END;

	BEGIN

	gUseTool := NullTool;

	IF gInBackground THEN EXIT (DoTrackCursor);

	part := FindWindow (mousePt, theWindow);

	IF part <> inContent THEN
		theWindow := NIL;

	inside := FALSE;

	gUseTool := gTool;

	IF MEMBER (gTarget, TImageView) THEN
		BEGIN

		view := TImageView (gTarget);
		doc  := TImageDocument (view.fDocument);

		view.TrackRulers;

		IF spaceDown THEN
			IF optionDown THEN
				IF view.fMagnification = view.MinMagnification THEN
					gUseTool := ZoomLimitTool
				ELSE
					gUseTool := ZoomOutTool
			ELSE IF commandDown THEN
				IF view.fMagnification = view.MaxMagnification THEN
					gUseTool := ZoomLimitTool
				ELSE
					gUseTool := ZoomTool
			ELSE
				gUseTool := HandTool

		ELSE
			CASE gTool OF

			ZoomTool:
				IF optionDown THEN
					IF view.fMagnification = view.MinMagnification THEN
						gUseTool := ZoomLimitTool
					ELSE
						gUseTool := ZoomOutTool
				ELSE
					IF view.fMagnification = view.MaxMagnification THEN
						gUseTool := ZoomLimitTool;

			EraserTool:
				IF optionDown THEN
					gUseTool := MagicTool;

			PencilTool,
			BrushTool,
			AirbrushTool,
			BucketTool,
			GradientTool,
			LineTool:
				IF optionDown THEN
					gUseTool := EyedropperTool;

			EyedropperTool:
				IF optionDown THEN
					gUseTool := EyedropperBackTool;

			TextTool:
				IF commandDown AND NOT EmptyRect (doc.fSelectionRect) THEN
					gUseTool := LassoTool
				ELSE IF optionDown THEN
					gUseTool := EyedropperTool;

			StampTool:
				IF optionDown THEN
					gUseTool := StampPadTool

			END;

		IF gUseTool IN [EyedropperTool, EyedropperBackTool, StampPadTool] THEN
			ForAllImageViewsDo (TestInsideView)
		ELSE
			TestInsideView (view)

		END

	ELSE
		BEGIN

		{$IFC qBarneyscan}
		UpdateCoords (NIL, Point (0))
		{$ENDC}

		END;

	IF inside THEN
		BEGIN

		doc := TImageDocument (view.fDocument);

		IF (doc.fEffectMode <> 0) &
		   (doc.fEffectChannel = view.fChannel) &
		   (view = gTarget) &
		   (view.FindCorner (doc.fEffectCorners, pt) <> -1) THEN

			gUseTool := EffectsTool;

		IF gUseTool = EffectsTool THEN
			canMove := FALSE
		ELSE IF gTool IN [MarqueeTool, LassoTool, WandTool,
						  EllipseTool, TextTool] THEN
			canMove := (NOT shiftDown AND NOT commandDown OR optionDown) AND
						NOT spaceDown
		ELSE
			canMove := commandDown AND NOT spaceDown;

		IF canMove AND (doc.fDepth = 8) THEN
			IF NOT EmptyRect (doc.fSelectionRect) THEN
				BEGIN

				view.CvtView2Image (pt);

				r := doc.fSelectionRect;

				IF PtInRect (pt, r) THEN

					IF doc.fSelectionMask = NIL THEN
						gUseTool := MoveTool

					ELSE
						BEGIN

						maskPtr := doc.fSelectionMask.NeedPtr
								   (pt.v - r.top, pt.v - r.top, FALSE);

						maskPtr := Ptr (ORD4 (maskPtr) + pt.h - r.left);

						IF BAND (maskPtr^, $80) <> 0 THEN
							gUseTool := MoveTool;

						doc.fSelectionMask.DoneWithPtr;
						doc.fSelectionMask.Flush

						END

				END

		END

	ELSE
		BEGIN

		gUseTool := NullTool;

		IF theWindow = gPickerWmgrWindow THEN
			BEGIN
			TrackPickerCursor (mousePt,
							   spaceDown,
							   shiftDown,
							   optionDown,
							   commandDown);
			EXIT (DoTrackCursor)
			END

		END;

	SetToolCursor (gUseTool, TRUE)

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TPhotoshopApplication.TrackCursor; OVERRIDE;

	VAR
		pt: Point;
		theKeys: KeyMap;

	BEGIN

	GetMouse (pt);
	LocalToGlobal (pt);

	GetKeys (theKeys);

	DoTrackCursor (pt, theKeys [kSpaceCode],
					   theKeys [kShiftCode],
					   theKeys [kOptionCode],
					   theKeys [kCommandCode])

	END;

{*****************************************************************************}

{$S ARes}

FUNCTION SpaceWasDown: BOOLEAN;

	TYPE
		EvQElPtr = ^EvQEl;

	VAR
		c: CHAR;
		eq: EvQElPtr;
		theKeys: KeyMap;

	BEGIN

	eq := EvQElPtr (GetEvQHdr^.QHead);

	WHILE eq <> NIL DO
		BEGIN

		c := CHR (BAND (eq^.evtQMessage, charCodeMask));

		IF (c = ' ') OR (c = CHR ($CA)) THEN
			IF eq^.evtQWhat = keyUp THEN
				BEGIN
				SpaceWasDown := TRUE;
				EXIT (SpaceWasDown)
				END
			ELSE IF eq^.evtQWhat = keyDown THEN
				BEGIN
				SpaceWasDown := FALSE;
				EXIT (SpaceWasDown)
				END;

		IF eq = EvQElPtr (GetEvQHdr^.QTail) THEN LEAVE;

		eq := EvQElPtr (eq^.qLink)

		END;

	GetKeys (theKeys);

	SpaceWasDown := theKeys [kSpaceCode]

	END;

{*****************************************************************************}

{$S ARes}

FUNCTION TPhotoshopApplication.ObeyMouseDown
		(whereMouseDown: INTEGER;
		 aWmgrWindow: WindowPtr;
		 nextEvent: PEventRecord): TCommand; OVERRIDE;

	VAR
		fi: FailInfo;
		aWindow: TWindow;
		palette: BOOLEAN;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aWindow.fCanBeActive  := TRUE;
		aWindow.fDoFirstClick := FALSE
		END;

	BEGIN

	DoTrackCursor (nextEvent^.where,
				   SpaceWasDown,
				   BAND (nextEvent^.modifiers, shiftKey) <> 0,
				   BAND (nextEvent^.modifiers, optionKey) <> 0,
				   BAND (nextEvent^.modifiers, cmdKey) <> 0);

	palette := FALSE;

	IF (whereMouseDown = inContent) AND (aWmgrWindow <> FrontWindow) THEN
		BEGIN

		aWindow := TWindow (GetWRefcon (aWmgrWindow));

		IF (gUseTool <> NullTool) & aWindow.fCanBeActive THEN
			BEGIN

			palette := TRUE;

			CatchFailures (fi, CleanUp);

			aWindow.fCanBeActive  := FALSE;
			aWindow.fDoFirstClick := TRUE

			END

		ELSE IF aWindow.fCanBeActive AND NOT aWindow.fDoFirstClick THEN
			BEGIN

			MySelectWindow (aWmgrWindow);

			ObeyMouseDown := gNoChanges;
			EXIT (ObeyMouseDown)

			END

		END;

	ObeyMouseDown := INHERITED ObeyMouseDown (whereMouseDown,
											  aWmgrWindow,
											  nextEvent);

	IF palette THEN
		BEGIN
		Success (fi);
		CleanUp (0, 0)
		END

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TPhotoshopApplication.SpaceIsLow; OVERRIDE;

	BEGIN
	END;

{*****************************************************************************}

{$S AOpen}

PROCEDURE TPhotoshopApplication.OpenNew (itsCmdNumber: CmdNumber); OVERRIDE;

	BEGIN

	IF itsCmdNumber = cNew THEN
		INHERITED OpenNew (itsCmdNumber)

	END;

{*****************************************************************************}

{$S GFinder}

FUNCTION TPhotoshopApplication.CanOpenDocument
		(itsCmdNumber: CmdNumber;
		 VAR anAppFile: AppFile): BOOLEAN; OVERRIDE;

	VAR
		canOpen: BOOLEAN;

	BEGIN

	canOpen := INHERITED CanOpenDocument (itsCmdNumber, anAppFile);

	IF NOT canOpen THEN Failure (0, 0);

	CanOpenDocument := TRUE

	END;

{*****************************************************************************}

{$S ARes}

FUNCTION TPhotoshopApplication.AlreadyOpen
		(fileName: Str255; volRefnum: INTEGER): TDocument; OVERRIDE;

	PROCEDURE PrepareDocument (doc: TDocument);
		BEGIN
		IF TImageDocument (doc) . fSaveExists THEN
			TImageDocument (doc) . fImported := FALSE
		ELSE IF TImageDocument (doc) . fImported THEN
			TImageDocument (doc) . fSaveExists := TRUE
		END;

	PROCEDURE FixDocument (doc: TDocument);
		BEGIN
		IF TImageDocument (doc) . fImported THEN
			TImageDocument (doc) . fSaveExists := FALSE
		END;

	BEGIN

	ForAllDocumentsDo (PrepareDocument);

	AlreadyOpen := INHERITED AlreadyOpen (fileName, volRefnum);

	ForAllDocumentsDo (FixDocument)

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE SetItemControl (theDialog: DialogPtr;
						  itemNumber: INTEGER;
						  value: INTEGER);

	VAR
		itemBox: Rect;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	GetDItem (theDialog, itemNumber, itemType, itemHandle, itemBox);

	SetCtlValue (ControlHandle (itemHandle), value)

	END;

{*****************************************************************************}

{$S AOpen}

PROCEDURE DrawFileSize (theDialog: DialogPtr; itemNo: INTEGER);

	VAR
		s: Str255;
		itemBox: Rect;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	GetDItem (theDialog, itemNo, itemType, itemHandle, itemBox);

	EraseRect (itemBox);

	IF gFileSize <> -1 THEN
		BEGIN
		NumToString (gFileSize, s);
		INSERT ('K', s, LENGTH (s) + 1);
		MoveTo ((itemBox.left + itemBox.right - StringWidth (s)) DIV 2,
				itemBox.top + 12);
		DrawString (s)
		END

	END;

{*****************************************************************************}

{$S AOpen}

PROCEDURE UpdateFileSize (theDialog: DialogPtr; item: INTEGER);

	VAR
		size: LONGINT;
		pb: ParamBlockRec;
		hpb: HParamBlockRec;

	BEGIN

	size := -1;

	IF LENGTH (gReply.fName) <> 0 THEN
		BEGIN

		pb.ioNamePtr   := @gReply.fName;
		pb.ioVRefNum   := -PInteger (SFSaveDisk)^;
		pb.ioFVersNum  := 0;
		pb.ioFDirIndex := 0;

		hpb.ioNamePtr	:= @gReply.fName;
		hpb.ioVRefNum	:= -PInteger (SFSaveDisk)^;
		hpb.ioFDirIndex := 0;
		hpb.ioDirID 	:= PLongInt (CurDirStore)^;

		IF PBHGetFInfo (@hpb, FALSE) = noErr THEN
			size := (hpb.ioFlPyLen + hpb.ioFlRPyLen + 1023) DIV 1024

		ELSE IF PBGetFInfo (@pb, FALSE) = noErr THEN
			size := (pb.ioFlPyLen + pb.ioFlRPyLen + 1023) DIV 1024

		END;

	IF size <> gFileSize THEN
		BEGIN
		gFileSize := size;
		DrawFileSize (theDialog, item)
		END

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE FormatDrawProc (theDialog: DialogPtr; itemNo: INTEGER);

	VAR
		s: Str255;
		itemBox: Rect;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	GetDItem (theDialog, itemNo, itemType, itemHandle, itemBox);

	itemBox.right := itemBox.right - 1;
	itemBox.bottom := itemBox.bottom - 1;

	MoveTo (itemBox.right, itemBox.top + 1);
	LineTo (itemBox.right, itemBox.bottom);
	LineTo (itemBox.left + 1, itemBox.bottom);

	FrameRect (itemBox);

	InsetRect (itemBox, 1, 1);
	EraseRect (itemBox);

	GetItem (gPopUpMenu, gFormatCode + 1, s);

	MoveTo (itemBox.left + 6, itemBox.top + 12);

	DrawString (s)

	END;

{*****************************************************************************}

{$S ARes}

FUNCTION FormatFilterProc (theDialog: DialogPtr;
						   VAR theEvent: EventRecord;
						   VAR itemHit: INTEGER;
						   titleItem: INTEGER;
						   menuItem: INTEGER): BOOLEAN;

	VAR
		pt: Point;
		itemBox: Rect;
		result: LONGINT;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN
	FormatFilterProc := FALSE;

	IF theEvent.what = mouseDown THEN
		BEGIN

		GetDItem (theDialog, menuItem, itemType, itemHandle, itemBox);

		itemBox.top := itemBox.top + 1;
		itemBox.left := itemBox.left + 1;
		itemBox.bottom := itemBox.bottom - 2;
		itemBox.right := itemBox.right - 2;

		pt := theEvent.where;
		GlobalToLocal (pt);

		IF PtInRect (pt, itemBox) THEN
			BEGIN

			pt := itemBox.topleft;
			LocalToGlobal (pt);

			GetDItem (theDialog, titleItem, itemType, itemHandle, itemBox);

			InvertRect (itemBox);
			InsertMenu (gPopUpMenu, -1);
			result := PopUpMenuSelect (gPopUpMenu, pt.v, pt.h,
									   gFormatCode + 1);
			DeleteMenu (gPopUpMenu^^.menuID);
			InvertRect (itemBox);

			IF HiWrd (result) <> 0 THEN
				IF LoWrd (result) <> gFormatCode + 1 THEN
					BEGIN
					CheckItem (gPopUpMenu, gFormatCode + 1, FALSE);
					gFormatCode := LoWrd (result) - 1;
					CheckItem (gPopUpMenu, gFormatCode + 1, TRUE);
					FormatDrawProc (theDialog, menuItem)
					END

			END

		END

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE FormatHookInit (theDialog: DialogPtr;
						  menuItem: INTEGER; reading: BOOLEAN);

	VAR
		code: INTEGER;
		itemBox: Rect;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	FOR code := 0 TO kLastFmtCode DO
		IF reading THEN
			IF gFormats [code] . fCanRead THEN
				EnableItem (gPopUpMenu, code + 1)
			ELSE
				DisableItem (gPopUpMenu, code + 1)
		ELSE
			IF gFormats [code] . CanWrite (TImageDocument (gDocument)) THEN
				EnableItem (gPopUpMenu, code + 1)
			ELSE
				DisableItem (gPopUpMenu, code + 1);

	FOR code := 0 TO kLastFmtCode DO
		CheckItem (gPopUpMenu, code + 1, code = gFormatCode);

	GetDItem (theDialog, menuItem, itemType, itemHandle, itemBox);

	CalcMenuSize (gPopUpMenu);

	itemBox.right := itemBox.left + gPopUpMenu^^.menuWidth + 3;
	itemHandle := Handle (@FormatDrawProc);

	SetDItem (theDialog, menuItem, itemType, itemHandle, itemBox)

	END;

{*****************************************************************************}

{$S AOpen}

FUNCTION GetAsFilterProc (theDialog: DialogPtr;
						  VAR theEvent: EventRecord;
						  VAR itemHit: INTEGER): BOOLEAN;


	BEGIN
	GetAsFilterProc := FormatFilterProc (theDialog, theEvent, itemHit, 11, 12)
	END;

{*****************************************************************************}

{$S AOpen}

FUNCTION GetAsHookProc (itemHit: INTEGER; theDialog: DialogPtr): INTEGER;

	CONST
		kSizeItem = 13;

	VAR
		itemBox: Rect;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	IF itemHit = -1 THEN
		BEGIN

		FormatHookInit (theDialog, 12, TRUE);

		DoSetBytes (@gLastReply, SIZEOF (SFReply), 0);

		gFileSize := -1;

		GetDItem (theDialog, kSizeItem, itemType, itemHandle, itemBox);
		SetDItem (theDialog, kSizeItem, itemType,
				  Handle (@DrawFileSize), itemBox)

		END

	ELSE IF NOT EqualBytes (@gReply, @gLastReply, SIZEOF (SFReply)) THEN
		BEGIN

		gLastReply := gReply;

		UpdateFileSize (theDialog, kSizeItem)

		END;

	GetAsHookProc := itemHit

	END;

{*****************************************************************************}

{$S AOpen}

FUNCTION FindFormatCode (fileType: OSType): INTEGER;

	VAR
		code: INTEGER;

	BEGIN

	FindFormatCode := -1;

	IF fileType <> '    ' THEN
		FOR code := 0 TO kLastFmtCode DO
			IF gFormats [code] . fCanRead THEN
				IF (fileType = gFormats [code] . fReadType1) OR
				   (fileType = gFormats [code] . fReadType2) OR
				   (fileType = gFormats [code] . fReadType3) THEN
					BEGIN
					FindFormatCode := code;
					EXIT (FindFormatCode)
					END

	END;

{*****************************************************************************}

{$S AOpen}

PROCEDURE DrawFormatName (theDialog: DialogPtr; itemNo: INTEGER);

	VAR
		s: Str255;
		ss: Str255;
		itemBox: Rect;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	GetDItem (theDialog, itemNo - 1, itemType, itemHandle, itemBox);
	GetIText (itemHandle, s);

	GetDItem (theDialog, itemNo, itemType, itemHandle, itemBox);

	EraseRect (itemBox);

	IF gFormatCode <> -1 THEN
		BEGIN
		GetItem (gPopUpMenu, gFormatCode + 1, ss);
		INSERT (ss, s, LENGTH (s) + 1)
		END;

	MoveTo (itemBox.left, itemBox.top + 12);
	DrawString (s);

	IF gFormatCode = -1 THEN
		BEGIN
		PenPat (gray);
		PenMode (notPatBic);
		PaintRect (itemBox);
		PenNormal
		END

	END;

{*****************************************************************************}

{$S AOpen}

FUNCTION GetHookProc (itemHit: INTEGER; theDialog: DialogPtr): INTEGER;

	CONST
		kNameItem = 12;
		kSizeItem = 13;

	VAR
		code: INTEGER;
		itemBox: Rect;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	IF itemHit = -1 THEN
		BEGIN

		DoSetBytes (@gLastReply, SIZEOF (SFReply), 0);

		gFileSize := -1;

		GetDItem (theDialog, kNameItem, itemType, itemHandle, itemBox);
		SetDItem (theDialog, kNameItem, itemType,
				  Handle (@DrawFormatName), itemBox);

		GetDItem (theDialog, kSizeItem, itemType, itemHandle, itemBox);
		SetDItem (theDialog, kSizeItem, itemType,
				  Handle (@DrawFileSize), itemBox)

		END

	ELSE IF NOT EqualBytes (@gReply, @gLastReply, SIZEOF (SFReply)) THEN
		BEGIN

		gLastReply := gReply;

		IF LENGTH (gReply.fName) = 0 THEN
			code := -1
		ELSE
			code := FindFormatCode (gReply.fType);

		IF code <> gFormatCode THEN
			BEGIN
			gFormatCode := code;
			DrawFormatName (theDialog, kNameItem)
			END;

		UpdateFileSize (theDialog, kSizeItem)

		END;

	GetHookProc := itemHit

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE WhereToPlaceDialog (id: INTEGER; VAR where: Point);

	VAR
		template: DialogTHndl;

	BEGIN

	template := DialogTHndl (GetResource ('DLOG', id));

	IF template <> NIL THEN
		ComputeCentered (where, template^^.boundsRect.right,
								template^^.boundsRect.bottom, FALSE)

	END;

{*****************************************************************************}

{$S AOpen}

PROCEDURE TPhotoshopApplication.SFGetParms
		(itsCmdNumber: CmdNumber; VAR dlgID: INTEGER; VAR where: Point;
		 VAR fileFilter, dlgHook, filterProc: ProcPtr;
		 typeList: HTypeList); OVERRIDE;

	CONST
		kOpenDialogID	= 1400;
		kOpenAsDialogID = 1401;

	VAR
		code: INTEGER;
		count: INTEGER;

	BEGIN

	gFormatCode := -1;

	INHERITED SFGetParms (itsCmdNumber, dlgID, where, fileFilter,
						  dlgHook, filterProc, typeList);

	IF itsCmdNumber <> cOpenAs THEN
		BEGIN

		SetHandleSize (Handle (typeList), SIZEOF (OSType) * kLastFmtCode * 3);
		FailMemError;

		count := 0;

		FOR code := 0 TO kLastFmtCode DO
			IF gFormats [code] . fCanRead THEN
				BEGIN
				IF gFormats [code] . fReadType1 <> '    ' THEN
					BEGIN
					count := count + 1;
					typeList^^ [count] := gFormats [code] . fReadType1
					END;
				IF gFormats [code] . fReadType2 <> '    ' THEN
					BEGIN
					count := count + 1;
					typeList^^ [count] := gFormats [code] . fReadType2
					END;
				IF gFormats [code] . fReadType3 <> '    ' THEN
					BEGIN
					count := count + 1;
					typeList^^ [count] := gFormats [code] . fReadType3
					END
				END;

		SetHandleSize (Handle (typeList), SIZEOF (OSType) * count)

		END

	ELSE
		SetHandleSize (Handle (typeList), 0);

	IF itsCmdNumber = cOpenAs THEN
		BEGIN

		dlgID := kOpenAsDialogID;
		dlgHook := @GetAsHookProc;
		filterProc := @GetAsFilterProc;

		gFormatCode := gOpenAsFormat

		END

	ELSE
		BEGIN
		dlgID := kOpenDialogID;
		dlgHook := @GetHookProc
		END;

	WhereToPlaceDialog (dlgID, where)

	END;

{*****************************************************************************}

{$S AOpen}

FUNCTION TPhotoshopApplication.ChooseDocument
		(itsCmdNumber: CmdNumber;
		 VAR anAppFile: AppFile): BOOLEAN; OVERRIDE;

	TYPE
		HSFTypeList = ^PSFTypeList;
		PSFTypeList = ^SFTypeList;

	VAR
		where: Point;
		dlgID: INTEGER;
		dlgHook: ProcPtr;
		numTypes: INTEGER;
		typeList: HTypeList;
		fileFilter: ProcPtr;
		filterProc: ProcPtr;
		pTypeList: PSFTypeList;

	BEGIN

	typeList := HTypeList (NewHandle (0));
	FailNIL (typeList);

	SFGetParms (itsCmdNumber, dlgID, where, fileFilter,
				dlgHook, filterProc, typeList);
	numTypes := GetHandleSize (Handle (typeList)) DIV 4;

	IF numTypes = 0 THEN
		BEGIN
		numTypes := -1;
		pTypeList := @pTypeList
		END
	ELSE
		BEGIN
		MoveHHi (Handle (typeList));
		HLock (Handle (typeList));
		pTypeList := HSFTypeList (typeList)^
		END;

	UpdateAllWindows;

	SFPGetFile (where, '', fileFilter, numTypes, pTypeList^,
				dlgHook, gReply, dlgID, filterProc);

	DisposHandle (Handle (typeList));

	ChooseDocument := gReply.good;

	IF gReply.good THEN
		BEGIN

		anAppFile.vRefnum := gReply.vRefnum;
		anAppFile.fType   := gReply.fType;
		anAppFile.versNum := gReply.version;
		anAppFile.fName   := gReply.fName;

		IF itsCmdNumber = cOpenAs THEN
			gOpenAsFormat := gFormatCode

		END;

	MoveGhostsForward		{ Standard file trashes ghost windows }

	END;

{*****************************************************************************}

{$S AOpen}

FUNCTION TPhotoshopApplication.DoMakeDocument
		(itsCmdNumber: CmdNumber): TDocument; OVERRIDE;

	VAR
		anImageDocument: TImageDocument;

	BEGIN

	New (anImageDocument);
	FailNil (anImageDocument);

	anImageDocument.IImageDocument;

	DoMakeDocument := anImageDocument

	END;

{*****************************************************************************}

{$S AClose}

PROCEDURE TPhotoshopApplication.CloseDocument
		(docToClose: TDocument); OVERRIDE;

	CONST
		kBeforeQuittingID = 800;
		kBeforeClosingID  = 801;

	VAR
		id: INTEGER;
		name: Str255;
		reply: INTEGER;

	BEGIN
	
	{$IFC NOT qDemo}

	IF docToClose.fChangeCount <> 0 THEN
		BEGIN

		IF gAppDone THEN
			id := kBeforeQuittingID
		ELSE
			id := kBeforeClosingID;

		name := docToClose.fTitle;
		ParamText (name, '', '', '');

		reply := BWAlert (id, 0, FALSE);

		IF reply = cancel THEN
			Failure (0, 0)

		ELSE IF reply = ok THEN
			docToClose.Save (cClose, NOT docToClose.fSaveExists, FALSE)

		END;
		
	{$ENDC}

	IF gLastCommand <> NIL THEN
		IF gLastCommand.fChangedDocument = docToClose THEN
			CommitLastCommand;

	docToClose.Close

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TPhotoshopApplication.AboutToLoseControl
		(convertClipboard: BOOLEAN); OVERRIDE;

	BEGIN

	IF NOT gInBackground THEN
		BEGIN
		gInBackground := TRUE;
		HiliteGhosts (FALSE)
		END;

	INHERITED AboutToLoseControl (convertClipboard)

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TPhotoshopApplication.RegainControl
		(checkClipboard: BOOLEAN); OVERRIDE;

	BEGIN

	IF gInBackground THEN
		BEGIN
		gInBackground := FALSE;
		HiliteGhosts (TRUE)
		END;

	INHERITED RegainControl (checkClipboard)

	END;

{*****************************************************************************}

{$S AClipboard}

FUNCTION TPhotoshopApplication.MakeViewForAlienClipboard: TView; OVERRIDE;

	VAR
		size: LONGINT;
		offset: LONGINT;

	BEGIN

	size := GetScrap (NIL, 'PICT', offset);

	IF size > 0 THEN
		MakeViewForAlienClipboard := ConvertPICTDeskScrap (size)
	ELSE
		MakeViewForAlienClipboard := INHERITED MakeViewForAlienClipboard

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TPhotoshopApplication.DoIdle (phase: IdlePhase); OVERRIDE;

	CONST
		kBackgroundPixels = 3000;
		kForegroundPixels = 12000;		{ Must be < than 30000 }

	VAR
		area: Rect;
		mag: INTEGER;
		refCon: LONGINT;
		maxRows: INTEGER;
		theFrame: TFrame;
		pageRows: LONGINT;
		delayed: RgnHandle;
		maxPixels: INTEGER;
		isAtFront: BOOLEAN;
		doc: TImageDocument;
		theView: TImageView;
		theWindow: WindowPeek;
		imageView: TImageView;

	BEGIN

	IF phase <> IdleEnd THEN
		BEGIN

		imageView := NIL;

		theWindow := WindowPeek (FrontWindow);

		WHILE theWindow <> NIL DO
			BEGIN

			IF theWindow^.windowKind = userKind THEN
				BEGIN
				refCon := GetWRefCon (WindowPtr (theWindow));
				IF MEMBER (TWindow (refCon), TImageWindow) THEN
					BEGIN
					theFrame := TFrame (TWindow (refCon) . fFrameList.First);
					theView := TImageView (theFrame.fView);
					IF NOT EmptyRgn (theView.fDelayedUpdateRgn) THEN
						BEGIN
						imageView := theView;
						LEAVE
						END
					END
				END;

			theWindow := theWindow^.nextWindow

			END;

		IF imageView = NIL THEN
			fIdlePriority := 0

		ELSE
			BEGIN

			isAtFront := NOT gInBackground AND
						 (imageView.fWindow.fWmgrWindow = FrontWindow);

			IF isAtFront THEN
				maxPixels := kForegroundPixels
			ELSE
				maxPixels := kBackgroundPixels;

			doc := TImageDocument (imageView.fDocument);

			mag := imageView.fMagnification;

			pageRows := doc.fData [0] . fBlocksPerPage;

			IF mag >= 1 THEN
				pageRows := pageRows * mag
			ELSE
				pageRows := (pageRows - mag - 1) DIV (-mag);

			imageView.fFrame.Focus;

			delayed := imageView.fDelayedUpdateRgn;

			SectRgn (imageView.fWindow.fWmgrWindow^.visRgn, delayed, delayed);

			IF EmptyRgn (delayed) THEN
				BEGIN

				IF imageView.fHLDesired = HLOn THEN
					imageView.DoHighlightSelection (HLOff, HLOn)

				END

			ELSE
				BEGIN

				area := delayed^^.rgnBBox;

				maxRows := Max (1, Min (pageRows,
								maxPixels DIV (area.right - area.left)));

				IF area.bottom - area.top <= maxRows THEN
					SetEmptyRgn (delayed)

				ELSE
					BEGIN

					area.bottom := area.top + maxRows;

					RectRgn (gTempRgn1, area);

					IF delayed^^.rgnSize <> 10 THEN
						BEGIN

						SectRgn (gTempRgn1, delayed, gTempRgn2);

						IF (gTempRgn2^^.rgnBBox.left  <> area.left ) OR
						   (gTempRgn2^^.rgnBBox.right <> area.right) THEN
							BEGIN

							area := gTempRgn2^^.rgnBBox;

							maxRows := Max (1, Min (pageRows,
											maxPixels DIV
											(area.right - area.left)));

							area.bottom := area.top + maxRows;

							RectRgn (gTempRgn1, area);

							DiffRgn (delayed, gTempRgn1, gTempRgn2);

							area.bottom := gTempRgn2^^.rgnBBox.top;

							RectRgn (gTempRgn1, area)

							END

						END;

					DiffRgn (delayed, gTempRgn1, delayed)

					END;

				imageView.DisplayOnScreen (area)

				END

			END

		END

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TPhotoshopApplication.SetUndoText
		(cmdDone: BOOLEAN; aCmdNumber: CmdNumber); OVERRIDE;

	BEGIN

	{ Bug fix--Kludge! }

	IF aCmdNumber = cRepeatFilter THEN
		INHERITED SetUndoText (NOT cmdDone, aCmdNumber);

	INHERITED SetUndoText (cmdDone, aCmdNumber)

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE SetWording (cmd, cmd1, cmd2: INTEGER; which: BOOLEAN);

	VAR
		s: Str255;
		menu: INTEGER;
		item: INTEGER;

	BEGIN

	IF which THEN
		CmdToMenuItem (cmd1, menu, item)
	ELSE
		CmdToMenuItem (cmd2, menu, item);

	GetItem (GetResMenu (menu), item, s);

	SetCmdName (cmd, s)

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TPhotoshopApplication.DoSetupMenus; OVERRIDE;

	VAR
		item: INTEGER;
		count: INTEGER;
		menu: MenuHandle;

	PROCEDURE AddViewToMenu (view: TImageView);

		VAR
			s: Str255;

		BEGIN

		IF item = gWindowFixed THEN
			BEGIN
			item := item + 1;
			AppendMenu (menu, '(-');
			count := count + 1
			END;

		item := item + 1;

		IF item > count THEN
			BEGIN
			AppendMenu (menu, 'Dummy');
			count := count + 1
			END;

		GetWTitle (view.fWindow.fWmgrWindow, s);

		IF s[1] = '-' THEN s[1] := CHR ($D0);

		SetItem (menu, item, s);

		view.fCmdNumber := -(256 * kWindowMenu + item);

		EnableCheck (view.fCmdNumber, TRUE, view = gTarget)

		END;

	BEGIN

	INHERITED DoSetupMenus;

	IF (gLastCommand = NIL) |
	   (gLastCommand.fCmdNumber <> cChangePrinterStyle) THEN
		CollectSpotGarbage;

	menu  := GetResMenu (kWindowMenu);
	count := CountMItems (menu);
	item  := gWindowFixed;

	ForAllImageViewsDo (AddViewToMenu);

	WHILE count > item DO
		BEGIN
		DelMenuItem (menu, count);
		count := count - 1
		END;

	IF count = gWindowFixed THEN
		BEGIN
		gStaggerCount := 0;
		menu^^.enableFlags := 0 	{ MacApp bug fix }
		END;

	SetWording (cBrushesWindow, cHideBrushes, cShowBrushes, BrushesVisible);

	Enable (cBrushesWindow, TRUE);

	SetWording (cPickerWindow, cHidePicker, cShowPicker, PickerVisible);

	Enable (cPickerWindow, TRUE);

	{$IFC qBarneyscan}

	SetWording (cCoordsWindow, cHideCoords, cShowCoords, CoordsVisible);

	Enable (cCoordsWindow, TRUE);

	{$ENDC}

	menu := GetResMenu (kAcquireMenu);

	count := CountMItems (menu);

	Enable (cAcquire, count >= 1);

	FOR item := 1 TO count DO
		EnableItem (menu, item);

	Enable (cOpenAs, TRUE);

	Enable (cPreferences, TRUE);

	gScratchSelection := PickerVisible &
						 NOT EmptyRect (gScratchDoc.fSelectionRect);

	IF gScratchSelection THEN
		BEGIN
		Enable (cDefineBrush, TRUE);
		Enable (cDefinePattern, TRUE)
		END

	END;

{*****************************************************************************}

{$S ASelCommand}

FUNCTION TPhotoshopApplication.DoMenuCommand
		(aCmdNumber: CmdNumber): TCommand; OVERRIDE;

	VAR
		name: Str255;
		menu: INTEGER;
		item: INTEGER;
		found: BOOLEAN;

	PROCEDURE PickView (view: TImageView);
		BEGIN
		IF view.fCmdNumber = aCmdNumber THEN
			BEGIN
			found := TRUE;
			MySelectWindow (view.fWindow.fWmgrWindow)
			END
		END;

	BEGIN

	DoMenuCommand := gNoChanges;

	found := FALSE;

	IF aCmdNumber < 0 THEN
		BEGIN

		CmdToMenuItem (aCmdNumber, menu, item);

		IF menu = kAcquireMenu THEN
			BEGIN
			GetItem (GetResMenu (kAcquireMenu), item, name);
			DoAcquireCommand (name);
			EXIT (DoMenuCommand)
			END;

		ForAllImageViewsDo (PickView)

		END;

	IF NOT found THEN
		CASE aCmdNumber OF

		cAboutApp:
			DoAboutPhotoshop;

		cBrushesWindow:
			ShowBrushes (NOT BrushesVisible);

		cPickerWindow:
			ShowPicker (NOT PickerVisible);

		{$IFC qBarneyscan}

		cCoordsWindow:
			ShowCoords (NOT CoordsVisible);

		{$ENDC}

		cAcquire:
			BEGIN
			GetItem (GetResMenu (kAcquireMenu), 1, name);
			DoAcquireCommand (name)
			END;

		cPreferences:
			DoPreferencesCommand;

		cDefineBrush:
			DefineBrush (TImageView (gScratchDoc.fViewList.First));

		cDefinePattern:
			DefinePattern (TImageView (gScratchDoc.fViewList.First));

		OTHERWISE
			DoMenuCommand := INHERITED DoMenuCommand (aCmdNumber)

		END

	END;

{*****************************************************************************}

{$S ARes}

FUNCTION TPhotoshopApplication.DoKeyCommand
		(ch: CHAR;
		 aKeyCode: INTEGER;
		 VAR info: EventInfo): TCommand; OVERRIDE;

	BEGIN

	TrackCursor;	{ For faster response time }

	IF ch = kTabChar THEN
		gHideCursor := ToggleGhosts;

	DoKeyCommand := INHERITED DoKeyCommand (ch, aKeyCode, info)

	END;

{*****************************************************************************}

{$S ARes}

FUNCTION TPhotoshopApplication.CommandKey
		(ch: CHAR;
		 aKeyCode: INTEGER;
		 VAR info: EventInfo): TCommand; OVERRIDE;

	BEGIN

	TrackCursor;	{ For faster response time }

	IF ch = '=' THEN ch := '+';

	IF (ch = CHR ($C3)) OR
	   (ch = CHR ($D7)) THEN ch := 'V';

	IF (ch = CHR ($C4)) OR
	   (ch = CHR ($EC)) THEN ch := 'F';

	IF ch IN [kLeftArrowChar,
			  kRightArrowChar,
			  kUpArrowChar,
			  kDownArrowChar] THEN

		CommandKey := gTarget.DoKeyCommand (ch, aKeyCode, info)

	ELSE
		CommandKey := INHERITED CommandKey (ch, aKeyCode, info)

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TImageDocument.DefaultState;

	VAR
		channel: INTEGER;

	BEGIN

	fDepth := 8;
	fChannels := 1;

	FOR channel := 0 TO kMaxChannels - 1 DO
		fData [channel] := NIL;

	fSelectionRect := gZeroRect;
	fSelectionMask := NIL;

	fSelectionFloating := FALSE;

	fExactFloat := FALSE;

	fFloatCommand := NIL;

	fFloatRect := gZeroRect;
	fFloatMask := NIL;

	FOR channel := 0 TO 2 DO
		BEGIN
		fFloatData	[channel] := NIL;
		fFloatBelow [channel] := NIL
		END;

	fFloatAlpha := NIL;

	fPasteControls := NIL;

	fEffectMode    := 0;
	fEffectCommand := NIL;

	WITH fStyleInfo DO
		BEGIN

		fResolution.value := 72 * $10000;
		fResolution.scale := 1;
		fWidthUnit		  := 1 + ORD (gMetric);
		fHeightUnit 	  := 1 + ORD (gMetric);

		fGamma := gPreferences.fSeparation.fGamma;

		fHalftoneSpec  := gPreferences.fHalftone;
		fHalftoneSpecs := gPreferences.fHalftones;

		fTransferSpec  := gPreferences.fTransfer;
		fTransferSpecs := gPreferences.fTransfers;

		fCropMarks		   := FALSE;
		fRegistrationMarks := FALSE;
		fLabel			   := FALSE;
		fColorBars		   := FALSE;
		fNegative		   := FALSE;
		fFlip			   := FALSE;

		fBorder.value := 0;
		fBorder.scale := 3;

		{$H-}
		DoSetBytes (@fCaption, SIZEOF (Str255), 0);
		{$H+}

		END;

	FOR channel := 0 TO kMaxChannels - 1 DO
		fMagicData [channel] := NIL;

	fMiscResources := NIL

	END;

{*****************************************************************************}

{$S AOpen}

PROCEDURE TImageDocument.IImageDocument;

	BEGIN

	fReverting := FALSE;
	fRevertInfo := NIL;

	fRulerOrigin := Point (0);

	DefaultState;

	IDocument (kFileType, kSignature,
			   kUsesDataFork, kUsesRsrcFork,
			   NOT kDataOpen, NOT kRsrcOpen);

	fSaveInPlace := sipAlways;

	fImported := FALSE;

	fMasterChanges := FALSE;

	fFormatCode := kFmtCodeInternal;

	fFlickerTime  := 0;
	fFlickerState := 0

	END;

{*****************************************************************************}

{$S AReadFile}

FUNCTION TImageDocument.ValidSize: BOOLEAN;

	BEGIN

	ValidSize := (fRows > 0) AND (fRows <= kMaxCoord) AND
				 (fCols > 0) AND (fCols <= kMaxCoord) AND
				 (fChannels > 0) AND (fChannels <= kMaxChannels) AND
				 ((fDepth = 8) OR (fDepth = 1) AND (fChannels = 1))

	END;

{*****************************************************************************}

{$S ARes}

FUNCTION TImageDocument.Interleave (channel: INTEGER): INTEGER;

	BEGIN

		CASE fMode OF

		RGBColorMode,
		SeparationsHSL,
		SeparationsHSB:
			Interleave := Max (1, 3 - channel);

		SeparationsCMYK:
			Interleave := Max (1, 4 - channel);

		OTHERWISE
			Interleave := 1

		END

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TImageDocument.DefaultMode;

	BEGIN

	IF fDepth = 1 THEN
		fMode := HalftoneMode
	ELSE IF fChannels = 1 THEN
		fMode := MonochromeMode
	ELSE IF fChannels = 2 THEN
		fMode := MultichannelMode
	ELSE
		fMode := RGBColorMode

	END;

{*****************************************************************************}

{$S AOpen}

PROCEDURE TImageDocument.DoInitialState; OVERRIDE;

	CONST
		kDialogID	= 1001;
		kHookItem	= 3;
		kWidthItem	= 4;
		kHeightItem = 6;
		kResItem	= 8;
		kMonoItem	= 10;
		kColorItem	= 11;

	VAR
		r: INTEGER;
		g: INTEGER;
		b: INTEGER;
		fi: FailInfo;
		color: BOOLEAN;
		width: INTEGER;
		height: INTEGER;
		channel: INTEGER;
		hitItem: INTEGER;
		aVMArray: TVMArray;
		aBWDialog: TBWDialog;
		resUnit: TUnitSelector;
		resolution: FixedScaled;
		widthUnit: TUnitSelector;
		heightUnit: TUnitSelector;
		modeCluster: TRadioCluster;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	IF GetClipSize (width, height, resolution, color) THEN
		BEGIN

		gNewWidth.scale := 1;
		gNewWidth.value := width * $10000;

		gNewHeight.scale := 1;
		gNewHeight.value := height * $10000;

		gNewResolution := resolution;

		gNewColor := color

		END;

	widthUnit := aBWDialog.DefineSizeUnit (kWidthItem, gNewWidth.scale,
										   FALSE, TRUE, TRUE, FALSE, TRUE);

	heightUnit := aBWDialog.DefineSizeUnit (kHeightItem, gNewHeight.scale,
											FALSE, TRUE, FALSE, FALSE, TRUE);

	resUnit := aBWDialog.DefineResUnit (kResItem, gNewResolution.scale, 0);

	widthUnit  . StuffFixed (0, gNewWidth.value);
	heightUnit . StuffFixed (0, gNewHeight.value);
	resUnit    . StuffFixed (0, gNewResolution.value);

	modeCluster := aBWDialog.DefineRadioCluster (kMonoItem, kColorItem,
												 kMonoItem + ORD (gNewColor));

	aBWDialog.SetEditSelection (kWidthItem);

	aBWDialog.TalkToUser (hitItem, StdItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	gNewWidth.scale := widthUnit.fPick;
	gNewWidth.value := widthUnit.GetFixed (0);

	gNewHeight.scale := heightUnit.fPick;
	gNewHeight.value := heightUnit.GetFixed (0);

	gNewResolution.scale := resUnit.fPick;
	gNewResolution.value := resUnit.GetFixed (0);

	gNewColor := (modeCluster.fChosenItem = kColorItem);

	fStyleInfo.fResolution := gNewResolution;

	IF gNewWidth.scale = 1 THEN
		BEGIN
		fCols := HIWRD (gNewWidth.value);
		fStyleInfo.fWidthUnit := gNewResolution.scale
		END
	ELSE
		BEGIN
		fCols := Max (1, Min (kMaxCoord,
				 ROUND (widthUnit.GetFloat (0) * resUnit.GetFloat (0))));
		fStyleInfo.fWidthUnit := gNewWidth.scale - 1
		END;

	IF gNewHeight.scale = 1 THEN
		BEGIN
		fRows := HIWRD (gNewHeight.value);
		fStyleInfo.fHeightUnit := gNewResolution.scale
		END
	ELSE
		BEGIN
		fRows := Max (1, Min (kMaxCoord,
				 ROUND (heightUnit.GetFloat (0) * resUnit.GetFloat (0))));
		fStyleInfo.fHeightUnit := gNewHeight.scale - 1
		END;

	IF gNewColor THEN
		fChannels := 3;

	Success (fi);

	CleanUp (0, 0);

	gApplication.CommitLastCommand; 	{ Maximize VM }

	FOR channel := 0 TO fChannels - 1 DO
		BEGIN
		MoveHands (TRUE);
		aVMArray := NewVMArray (fRows, fCols, fChannels - channel);
		fData [channel] := aVMArray
		END;

	r := BSR (gBackgroundColor.red	, 8);
	g := BSR (gBackgroundColor.green, 8);
	b := BSR (gBackgroundColor.blue , 8);

	MoveHands (TRUE);

	IF fChannels = 3 THEN
		BEGIN
		fData [0] . SetBytes (r);
		MoveHands (TRUE);
		fData [1] . SetBytes (g);
		MoveHands (TRUE);
		fData [2] . SetBytes (b)
		END
	ELSE
		fData [0] . SetBytes (ORD (ConvertToGray (r, g, b)));

	DefaultMode

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TImageDocument.FreeFloat;

	VAR
		channel: INTEGER;

	BEGIN

	fSelectionFloating := FALSE;

	fFloatCommand := NIL;

	fFloatRect := gZeroRect;

	FreeObject (fFloatMask);
	fFloatMask := NIL;

	FOR channel := 0 TO 2 DO
		BEGIN

		FreeObject (fFloatData	[channel]);
		FreeObject (fFloatBelow [channel]);

		fFloatData	[channel] := NIL;
		fFloatBelow [channel] := NIL

		END;

	FreeObject (fFloatAlpha);
	fFloatAlpha := NIL;

	IF fPasteControls <> NIL THEN
		BEGIN
		DisposHandle (fPasteControls);
		fPasteControls := NIL
		END

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TImageDocument.FreeMagic;

	VAR
		channel: INTEGER;

	BEGIN

	FOR channel := 0 TO kMaxChannels - 1 DO
		IF fMagicData [channel] <> NIL THEN
			BEGIN
			fMagicData	[channel] . Free;
			fMagicData	[channel] := NIL
			END

	END;

{*****************************************************************************}

{$S AClose}

PROCEDURE TImageDocument.FreeData; OVERRIDE;

	VAR
		channel: INTEGER;

	BEGIN

	fReverting := TRUE;

	FOR channel := 0 TO kMaxChannels - 1 DO
		FreeObject (fData [channel]);

	FreeObject (fSelectionMask);

	FreeFloat;

	FreeMagic;

	IF fMiscResources <> NIL THEN
		BEGIN
		fMiscResources.Each (FreeObject);
		fMiscResources.Free
		END;

	DefaultState;

	MarkSpotDirty

	END;

{*****************************************************************************}

{$S AClose}

PROCEDURE TImageDocument.Free; OVERRIDE;

	BEGIN

	FreeData;

	IF fRevertInfo <> NIL THEN
		DisposHandle (fRevertInfo);

	IF gCloneDoc = SELF THEN
		gCloneDoc := NIL;

	IF gCloneTarget = SELF THEN
		gCloneTarget := NIL;

	INHERITED Free

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TImageDocument.TestColorTable;

	VAR
		name: Str255;
		item: INTEGER;
		count: INTEGER;
		menu: MenuHandle;
		tableH: HRGBLookUpTable;

	BEGIN

	fTableItem := -1;

	menu := GetResMenu (kTableMenu);

	count := CountMItems (menu);

	FOR item := gTableFixed + 1 TO count DO
		BEGIN

		GetItem (menu, item, name);

		tableH := HRGBLookUpTable (GetNamedResource ('PLUT', name));

		IF tableH <> NIL THEN
			IF EqualBytes (Ptr (tableH^),
						   @fIndexedColorTable,
						   SIZEOF (TRGBLookUpTable)) THEN
				fTableItem := item

		END

	END;

{*****************************************************************************}

{$S AWriteFile}

FUNCTION PutFilterProc (theDialog: DialogPtr;
						VAR theEvent: EventRecord;
						VAR itemHit: INTEGER): BOOLEAN;

	BEGIN

	PutFilterProc := FormatFilterProc (theDialog, theEvent, itemHit, 9, 10)

	END;

{*****************************************************************************}

{$S AWriteFile}

FUNCTION PutHookProc (itemHit: INTEGER; theDialog: DialogPtr): INTEGER;

	BEGIN

	IF itemHit = -1 THEN
		FormatHookInit (theDialog, 10, FALSE);

	PutHookProc := itemHit

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE SetSFDirectory (vRefNum: INTEGER);

	VAR
		dirID: LONGINT;
		temp1: PInteger;
		temp2: PLongInt;

	BEGIN

	IF (vRefNum <> 0) & (GetDirID (vRefnum, dirID) = noErr) THEN
		BEGIN

		temp1  := PInteger (SFSaveDisk);
		temp1^ := -vRefnum;

		temp2  := PLongInt (CurDirStore);
		temp2^ := dirID

		END

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TImageDocument.SFPutParms
		(itsCmdNumber: CmdNumber;
		 VAR dlgID: INTEGER; VAR where: Point;
		 VAR defaultName, prompt: Str255;
		 VAR dlgHook, filterProc: ProcPtr); OVERRIDE;

	CONST
		kSaveAsDialogID = 1300;

	BEGIN

	INHERITED SFPutParms (itsCmdNumber, dlgID, where, defaultName,
						  prompt, dlgHook, filterProc);

	dlgID := kSaveAsDialogID;

	WhereToPlaceDialog (dlgID, where);

	dlgHook := @PutHookProc;
	filterProc := @PutFilterProc;

	SetSFDirectory (fVolRefNum)

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TImageDocument.SaveAgain (itsCmdNumber: CmdNumber;
									makingCopy: BOOLEAN;
									savingDoc: TDocument); OVERRIDE;

	BEGIN

	IF SELF <> savingDoc THEN
		INHERITED SaveAgain (itsCmdNumber, makingCopy, savingDoc)
	ELSE
		BEGIN
		fSaveExists := FALSE;
		fImported := FALSE
		END

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TImageDocument.Save
		(itsCmdNumber: CmdNumber;
		 askForFilename, makingCopy: BOOLEAN); OVERRIDE;

	BEGIN

	IF askForFileName THEN
		itsCmdNumber := cSaveAs;

	IF gFormats [fFormatCode] . CanWrite (SELF) THEN
		gFormatCode := fFormatCode
	ELSE
		gFormatCode := kFmtCodeInternal;

	INHERITED Save (itsCmdNumber, askForFilename, makingCopy);

	gFormats [gFormatCode] . WriteOther (SELF, gReply.fName);

	fMasterChanges := fMasterChanges OR (fChangeCount > 0);
	fChangeCount   := 0

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TImageDocument.AboutToSave
		(itsCmd: CmdNumber; VAR newName: Str255;
		 VAR newVolRefnum: INTEGER;
		 VAR makingCopy: BOOLEAN); OVERRIDE;

	BEGIN

	MoveGhostsForward;	{ Standard file trashes ghost windows }

	gApplication.CommitLastCommand;

	FreeMagic;

	gReply.fName   := newName;
	gReply.vRefNum := newVolRefnum;

	IF gFormatCode <> kFmtCodeInternal THEN
		BEGIN
		gFormats [gFormatCode] . SetFormatOptions (SELF);
		makingCopy := TRUE
		END;

	VMCompress (TRUE);

	gFormats [gFormatCode] . AboutToSave (SELF, itsCmd, newName,
										  newVolRefNum, makingCopy);

	fUsesRsrcFork := gFormats [gFormatCode] . fUsesRsrcFork OR
					 (fMiscResources <> NIL);

	fUsesDataFork := gFormats [gFormatCode] . fUsesDataFork

	END;

{*****************************************************************************}

{$S AWriteFile}

FUNCTION TImageDocument.GetSaveInfo
		(itsCmdNumber: CmdNumber; copyFInfo: BOOLEAN;
		 VAR cInfo: CInfoPBRec): BOOLEAN; OVERRIDE;

	BEGIN

	GetSaveInfo := INHERITED GetSaveInfo (itsCmdNumber, copyFInfo, cInfo);

	cInfo.ioFlFndrInfo.fdType	 := gFormats [gFormatCode] . fFileType;
	cInfo.ioFlFndrInfo.fdCreator := gFormats [gFormatCode] . fFileCreator

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TImageDocument.SavedOn
		(VAR fileName: Str255; volRefNum: INTEGER); OVERRIDE;

	BEGIN

	fImported := FALSE;

	fFileType	:= kFileType;
	fFormatCode := kFmtCodeInternal;

	fMasterChanges := FALSE;

	fMagicRows	   := fRows;
	fMagicCols	   := fCols;
	fMagicChannels := fChannels;
	fMagicMode	   := fMode;

	INHERITED SavedOn (fileName, volRefNum)

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TImageDocument.DoNeedDiskSpace
		(VAR dataForkBytes, rsrcForkBytes: LONGINT); OVERRIDE;

	VAR
		format: TImageFormat;

	BEGIN

	INHERITED DoNeedDiskSpace (dataForkBytes, rsrcForkBytes);

	format := gFormats [gFormatCode];

	IF format.fUsesDataFork THEN
		dataForkBytes := dataForkBytes + format.DataForkBytes (SELF);

	IF format.fUsesRsrcFork THEN
		rsrcForkBytes := rsrcForkBytes + format.RsrcForkBytes (SELF);

	IF fMiscResources <> NIL THEN
		MiscResourcesBytes (SELF, rsrcForkBytes)

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TImageDocument.DoWrite
		(aRefNum: INTEGER; makingCopy: BOOLEAN); OVERRIDE;

	VAR
		s: Str255;
		ss: Str255;
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress
		END;

	BEGIN

	IF fMiscResources <> NIL THEN
		WriteMiscResources (SELF);

	GetItem (gPopUpMenu, gFormatCode + 1, s);
	GetIndString (ss, kStringsID, strWriting);
	INSERT (ss, s, 1);
	GetIndString (ss, kStringsID, strFormat);
	INSERT (ss, s, LENGTH (s) + 1);

	StartProgress (s);
	CatchFailures (fi, CleanUp);

	gFormats [gFormatCode] . DoWrite (SELF, aRefNum);

	Success (fi);
	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TImageDocument.DoRead
		(aRefNum: INTEGER; rsrcExists, forPrinting: BOOLEAN); OVERRIDE;

	VAR
		s: Str255;
		ss: Str255;
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress
		END;

	BEGIN

	gApplication.CommitLastCommand; 	{ Maximize VM }

	IF gFormatCode = -1 THEN
		BEGIN
		gFormatCode := FindFormatCode (fFileType);
		IF gFormatCode = -1 THEN gFormatCode := kFmtCodeRaw
		END;

	GetItem (gPopUpMenu, gFormatCode + 1, s);
	GetIndString (ss, kStringsID, strReading);
	INSERT (ss, s, 1);
	GetIndString (ss, kStringsID, strFormat);
	INSERT (ss, s, LENGTH (s) + 1);

	StartProgress (s);
	CatchFailures (fi, CleanUp);

	gFormats [gFormatCode] . DoRead (SELF, aRefNum, rsrcExists);

	Success (fi);
	CleanUp (0, 0);

	{$IFC qBarneyscan}
	IF fMode = SeparationsCMYK THEN
		Failure (errNoCMYK, 0);
	{$ENDC}

	IF rsrcExists THEN
		ReadMiscResources (SELF);

	fFormatCode := gFormatCode

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TImageDocument.ReadFromFile
		(VAR anAppFile: AppFile; forPrinting: BOOLEAN); OVERRIDE;

	BEGIN

	IF anAppFile.fName <> '' THEN
		fFileType := anAppFile.fType;

	INHERITED ReadFromFile (anAppFile, forPrinting);

	fImported := (fFormatCode <> kFmtCodeInternal);

	fSaveExists := NOT fImported;

	gFormats [gFormatCode] . ReadOther (SELF, anAppFile.fName);

	fMagicRows	   := fRows;
	fMagicCols	   := fCols;
	fMagicChannels := fChannels;
	fMagicMode	   := fMode

	END;

{*****************************************************************************}

{$S AOpen}

FUNCTION NewImageWindow (itsView: TImageView): TWindow;

	CONST
		kImageWindowID = 1001;

	VAR
		r: Rect;
		fi: FailInfo;
		wSize: Point;
		canClose: BOOLEAN;
		canResize: BOOLEAN;
		aFrame: TImageFrame;
		aWindow: TImageWindow;
		aRulerView: TRulerView;
		aWmgrWindow: WindowPtr;
		aRulerFrame: TRulerFrame;

	PROCEDURE HdlNewWObj (error: INTEGER; message: LONGINT);
		BEGIN
		FreeWmgrWindow (aWmgrWindow, FALSE, TRUE)
		END;

	PROCEDURE HdlNSWindow (error: INTEGER; message: LONGINT);
		BEGIN
		aWindow.Free
		END;

	BEGIN

	aWmgrWindow := gApplication.GetRsrcWindow (NIL,
											   kImageWindowID,
											   NOT kDialogWindow,
											   canResize,
											   canClose);

	CatchFailures (fi, HdlNewWObj);

	NEW (aWindow);
	FailNil (aWindow);

	Success (fi);

	aWindow.IWindow (itsView.fDocument,
					 aWmgrWindow,
					 NOT kDialogWindow,
					 canResize,
					 canClose,
					 TRUE);

	CatchFailures (fi, HdlNSWindow);

	NEW (aFrame);
	FailNIL (aFrame);

	r := aWindow.fContentRect;
	SubPt (Point ($00100010), r.botRight);

	aFrame.IFrame (aWindow, aWindow, r,
				   kWantHScrollBar, kWantVScrollBar,
				   kHFrResize, kVFrResize);

	aFrame.HaveView (itsView);

	aWindow.fTarget := itsView;

	NEW (aRulerFrame);
	FailNIL (aRulerFrame);

	aRulerFrame.IRulerFrame (aWindow, FALSE);

	aFrame.fRuler [h] := aRulerFrame;

	NEW (aRulerView);
	FailNIL (aRulerView);

	aRulerView.IRulerView (itsView);

	aRulerFrame.HaveView (aRulerView);

	NEW (aRulerFrame);
	FailNIL (aRulerFrame);

	aRulerFrame.IRulerFrame (aWindow, TRUE);

	aFrame.fRuler [v] := aRulerFrame;

	NEW (aRulerView);
	FailNIL (aRulerView);

	aRulerView.IRulerView (itsView);

	aRulerFrame.HaveView (aRulerView);

	aFrame.PositionRulers;

	WITH aWindow.fWmgrWindow^.portRect DO
		BEGIN
		wSize := botRight;
		{$H-}
		SubPt (topLeft, wSize);
		{$H+}
		END;

	aWindow.Resize (wSize, FALSE);

	NewImageWindow := aWindow;

	Success (fi)

	END;

{*****************************************************************************}

{$S AOpen}

PROCEDURE TImageDocument.DoMakeViews (forPrinting: BOOLEAN); OVERRIDE;

	VAR
		anImageView: TImageView;

	BEGIN

	New (anImageView);
	FailNil (anImageView);

	anImageView.IImageView (SELF)

	END;

{*****************************************************************************}

{$S AOpen}

PROCEDURE TImageDocument.DoMakeWindows; OVERRIDE;

	VAR
		view: TImageView;

	BEGIN

	view := TImageView (fViewList.At (fViewList.fSize));

	view.fWindow := NewImageWindow (view);

	view.fWindow.fFreeOnClosing := TRUE;
	view.fWindow.fWouldCloseDoc := FALSE;

	SimpleStagger (view.fWindow, 8, 8, gStaggerCount);

	view.AdjustZoomSize;

	view.SetToZoomSize;

	view.UpdateWindowTitle;

	IF view.fPalette <> NIL THEN
		SetPalette (view.fWindow.fWmgrWindow, view.fPalette, TRUE)

	END;

{*****************************************************************************}

{$S AOpen}

PROCEDURE TImageDocument.OpenAgain
		(itsCmdNumber: INTEGER; openingDoc: TDocument); OVERRIDE;

	CONST
		kOpenAgainID = 924;

	VAR
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		TImageView (fViewList.At (fViewList.fSize)) . Free
		END;

	BEGIN

	IF itsCmdNumber <> cAnotherView THEN
		IF BWAlert (kOpenAgainID, 0, TRUE) <> ok THEN
			Failure (0, 0);

	DoMakeViews (FALSE);

	CatchFailures (fi, CleanUp);
	DoMakeWindows;
	Success (fi);

	ShowWindows;

	Failure (0, 0)

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION TImageDocument.CanRevert: BOOLEAN;

	BEGIN

	CanRevert := (fSaveExists OR fImported) AND
				 (fMasterChanges OR (fChangeCount > 0))

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TImageDocument.MyRevert;

	CONST
		kWarningID = 902;

	VAR
		name: Str255;

	BEGIN

	fReverting := FALSE;

	name := fTitle;
	ParamText (name, '', '', '');

	IF BWAlert (kWarningID, 0, FALSE) <> ok THEN
		Failure (0, 0);

	fSaveExists := TRUE;

	fUsesRsrcFork := TRUE;
	fUsesDataFork := TRUE;

	gFormatCode := fFormatCode;

	Revert;

	fReverting := FALSE;

	ShowReverted

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TImageDocument.DoIdle (phase: IdlePhase); OVERRIDE;

	VAR
		view: TImageView;

	BEGIN

	IF (phase <> IdleEnd) THEN
		BEGIN

		IF SELF = gScratchDoc THEN
			view := TImageView (fViewList.First)

		ELSE IF MEMBER (gTarget, TImageView) &
				(TImageView (gTarget) . fDocument = SELF) THEN
			view := TImageView (gTarget)

		ELSE
			EXIT (DoIdle);

		view.UpdateSelection

		END

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TImageDocument.GetBoundsRect (VAR r: Rect);

	BEGIN
	SetRect (r, 0, 0, fCols, fRows)
	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TImageDocument.SectBoundsRect (VAR r: Rect);

	VAR
		bounds: Rect;
		ignore: BOOLEAN;

	BEGIN

	GetBoundsRect (bounds);

	ignore := SectRect (bounds, r, r)

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TImageDocument.KillEffect (fixup: BOOLEAN);

	VAR
		view: TImageView;

	BEGIN

	IF fEffectMode <> 0 THEN
		BEGIN

		fEffectMode    := 0;
		fEffectCommand := NIL;

		IF MEMBER (gTarget, TImageView) THEN
			BEGIN

			view := TImageView (gTarget);

			IF (view.fDocument = SELF) AND
			   (view.fChannel = fEffectChannel) THEN
				BEGIN

				view.fFrame.Focus;
				view.DoHighlightCorners (FALSE);

				IF fixup THEN
					view.DoHighlightSelection (HLOff, HLOn)

				END

			END

		END

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TImageDocument.DeSelect (redraw: BOOLEAN);

	VAR
		view: TImageView;
		showWatch: BOOLEAN;

	BEGIN

	KillEffect (FALSE);

	fSelectionFloating := FALSE;

	IF fFloatCommand = NIL THEN FreeFloat;

	IF NOT EmptyRect (fSelectionRect) THEN
		BEGIN

		IF redraw THEN
			BEGIN

			IF SELF = gScratchDoc THEN
				view := TImageView (fViewList.First)

			ELSE IF MEMBER (gTarget, TImageView) &
					(TImageView (gTarget) . fDocument = SELF) THEN
				view := TImageView (gTarget)

			ELSE
				view := NIL;

			IF view <> NIL THEN
				BEGIN

				showWatch := NOT gMovingHands & (fSelectionMask <> NIL);

				IF showWatch THEN MoveHands (FALSE);

				view.DoHighlightSelection (HLOn, HLOff);

				IF showWatch THEN
					SetToolCursor (gUseTool, TRUE)

				END

			END;

		fSelectionRect := gZeroRect;

		IF fSelectionMask <> NIL THEN
			BEGIN
			fSelectionMask.Free;
			fSelectionMask := NIL
			END;

		gOutlineCache.doc := NIL;

		fIdlePriority := 0

		END

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TImageDocument.Select (r: Rect; mask: TVMArray);

	VAR
		fi: FailInfo;
		view: TImageView;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF mask <> fSelectionMask THEN FreeObject (mask);
		EXIT (Select)
		END;

	PROCEDURE ResetObscureTime (view: TImageView);
		BEGIN
		view.fObscureTime := TickCount
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	DeSelect (TRUE);

	IF NOT EmptyRect (r) THEN
		BEGIN

		fSelectionRect := r;
		fSelectionMask := mask;

		IF SELF = gScratchDoc THEN
			view := TImageView (fViewList.First)

		ELSE IF MEMBER (gTarget, TImageView) &
				(TImageView (gTarget) . fDocument = SELF) THEN
			view := TImageView (gTarget)

		ELSE
			view := NIL;

		IF view <> NIL THEN
			view.DoHighlightSelection (HLOff, HLOn);

		fViewList.Each (ResetObscureTime);

		fIdlePriority := 1

		END;

	Success (fi)

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TImageDocument.MoveSelection (r: Rect);

	VAR
		mag: INTEGER;
		delta: Point;

	PROCEDURE ResetObscureTime (view: TImageView);
		BEGIN
		view.fObscureTime := TickCount
		END;

	BEGIN

	KillEffect (FALSE);

	delta.v := r.top  - fSelectionRect.top;
	delta.h := r.left - fSelectionRect.left;

	fSelectionRect := r;

	IF gOutlineCache.doc = SELF THEN
		BEGIN

		mag := gOutlineCache.mag;

		IF mag >= 1 THEN
			OffsetRect (gOutlineCache.area,
						delta.h * mag,
						delta.v * mag)

		ELSE IF (delta.v MOD (-mag) = 0) AND
				(delta.h MOD (-mag) = 0) THEN
			OffsetRect (gOutlineCache.area,
						delta.h DIV (-mag),
						delta.v DIV (-mag))

		ELSE
			gOutlineCache.doc := NIL

		END;

	IF MEMBER (gTarget, TImageView) THEN
		IF TImageView (gTarget) . fDocument = SELF THEN
			TImageView (gTarget) . DoHighlightSelection (HLOff, HLOn);

	fViewList.Each (ResetObscureTime)

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageDocument.UpdateImageArea (area: Rect;
										  highlight: BOOLEAN;
										  doFront: BOOLEAN;
										  channel: INTEGER);

	PROCEDURE CheckView (view: TImageView);
		BEGIN

		IF view <> gTarget THEN

			IF (channel = view.fChannel) OR
			   (channel = kRGBChannels) AND (view.fChannel <= 2) OR
			   (view.fChannel = kRGBChannels) AND (channel <= 2) THEN

				view.UpdateImageArea (area, highlight)

		END;

	BEGIN

	IF doFront THEN
		IF MEMBER (gTarget, TImageView) THEN
			IF TImageView (gTarget) . fDocument = SELF THEN
				TImageView (gTarget) . UpdateImageArea (area, highlight);

	fViewList.Each (CheckView)

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageDocument.UpdateStatus;

	PROCEDURE UpdateView (view: TImageView);

		VAR
			r: Rect;

		BEGIN
		r := TImageFrame (view.fFrame) . fStatusRect;
		view.fFrame.FocusOnContainer;
		InvalRect (r)
		END;

	BEGIN
	fViewList.Each (UpdateView)
	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageDocument.InvalRulers;

	PROCEDURE UpdateView (view: TImageView);
		BEGIN
		view.InvalRulers
		END;

	BEGIN
	fViewList.Each (UpdateView)
	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageDocument.ChannelName (channel: INTEGER; VAR name: Str255);

	CONST
		kColorNameList = 1003;
		kDummyID	   = 1;
		kNumberID	   = 2;
		kRGBID		   = 3;
		kSelectionID   = 4;
		kNewID		   = 5;
		kRedID		   = 6;
		kGreenID	   = 7;
		kBlueID 	   = 8;
		kCyanID 	   = 9;
		kMagentaID	   = 10;
		kYellowID	   = 11;
		kBlackID	   = 12;
		kHueID		   = 13;
		kSaturationID  = 14;
		kLightnessID   = 15;
		kBrightnessID  = 16;

	VAR
		s: Str255;
		id: INTEGER;

	BEGIN

		CASE channel OF

		kRGBChannels:
			id := kRGBID;

		kMaskChannel:
			id := kSelectionID;

		kDummyChannel:
			id := kDummyID;

		OTHERWISE

			IF channel = fChannels THEN
				id := kNewID

			ELSE
				BEGIN
				id := kNumberID;

					CASE fMode OF

					RGBColorMode:
						CASE channel OF
						0:	id := kRedID;
						1:	id := kGreenID;
						2:	id := kBlueID
						END;

					SeparationsCMYK:
						CASE channel OF
						0:	id := kCyanID;
						1:	id := kMagentaID;
						2:	id := kYellowID;
						3:	id := kBlackID
						END;

					SeparationsHSL:
						CASE channel OF
						0:	id := kHueID;
						1:	id := kSaturationID;
						2:	id := kLightnessID
						END;

					SeparationsHSB:
						CASE channel OF
						0:	id := kHueID;
						1:	id := kSaturationID;
						2:	id := kBrightnessID
						END

					END

				END

		END;

	GetIndString (name, kColorNameList, id);

	IF id = kNumberID THEN
		BEGIN
		NumToString (channel + 1, s);
		INSERT (s, name, LENGTH (name) + 1)
		END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageDocument.DoSetupMenus; OVERRIDE;

	VAR
		item: INTEGER;
		count: INTEGER;
		menu: MenuHandle;

	BEGIN

	INHERITED DoSetupMenus;
	
	{$IFC qDemo}
	Enable (cSave, FALSE);
	Enable (cSaveAs, FALSE);
	{$ELSEC}
	Enable (cSave, TRUE);
	{$ENDC}

	Enable (cAnotherView, TRUE);

	Enable (cRevert, CanRevert);

	menu := GetResMenu (kExportMenu);

	count := CountMItems (menu);

	Enable (cExport, count >= 1);

	FOR item := 1 TO count DO
		EnableItem (menu, item)

	END;

{*****************************************************************************}

{$S ASelCommand}

FUNCTION TImageDocument.DoMenuCommand
		(aCmdNumber: CmdNumber): TCommand; OVERRIDE;

	VAR
		fi: FailInfo;
		name: Str255;
		menu: INTEGER;
		item: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF fReverting THEN Close
		END;

	BEGIN

	DoMenuCommand := gNoChanges;

	IF aCmdNumber < 0 THEN
		BEGIN

		CmdToMenuItem (aCmdNumber, menu, item);

		IF menu = kExportMenu THEN
			BEGIN
			GetItem (GetResMenu (kExportMenu), item, name);
			DoExportCommand (SELF, name);
			EXIT (DoMenuCommand)
			END

		END;

		CASE aCmdNumber OF

		cAnotherView:
			OpenAgain (cAnotherView, NIL);

		cRevert:
			BEGIN
			CatchFailures (fi, CleanUp);
			MyRevert;
			Success (fi)
			END;

		OTHERWISE
			DoMenuCommand := INHERITED DoMenuCommand (aCmdNumber)

		END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE ForAllImageViewsDo (PROCEDURE DoIt (view: TImageView));

	PROCEDURE DoToDocument (doc: TImageDocument);
		BEGIN
		doc.fViewList.Each (DoIt)
		END;

	BEGIN
	gApplication.ForAllDocumentsDo (DoToDocument)
	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION MakePseudocolorTable (theColors: TRGBLookUpTable;
							   VAR LUT: TLookUpTable): CTabHandle;

	TYPE
		TColor =
			RECORD
			gray: INTEGER;
			color: LONGINT;
			END;
		PColor = ^TColor;

	VAR
		gray: INTEGER;
		size: INTEGER;
		match: INTEGER;
		color: LONGINT;
		clobber: INTEGER;
		LUT1: TLookUpTable;
		LUT2: TLookUpTable;
		cTable: CTabHandle;
		sameOrder: BOOLEAN;
		firstBlack: INTEGER;
		table: ARRAY [0..255] OF TColor;

	{$IFC qTrace} {$D+} {$ENDC}

	FUNCTION ColorDist (color1, color2: LONGINT): INTEGER;

		VAR
			dr, dg, db: INTEGER;

		BEGIN

		dr := BAND (color1, $FF) -
			  BAND (color2, $FF);
		dg := BAND (BSR (color1, 8), $FF) -
			  BAND (BSR (color2, 8), $FF);
		db := BSR (color1, 16) -
			  BSR (color2, 16);

		IF dr < 0 THEN dr := -dr;
		IF dg < 0 THEN dg := -dg;
		IF db < 0 THEN db := -db;

		ColorDist := dr + dg + db

		END;

	{$IFC qTrace} {$D++} {$ENDC}

	FUNCTION ColorAverage (color1, color2: LONGINT): LONGINT;

		VAR
			r, g, b: INTEGER;

		BEGIN

		r := BAND (color1, $FF) +
			 BAND (color2, $FF);
		g := BAND (BSR (color1, 8), $FF) +
			 BAND (BSR (color2, 8), $FF);
		b := BSR (color1, 16) +
			 BSR (color2, 16);

		r := BSR (r, 1);
		g := BSR (g, 1);
		b := BSR (b, 1);

		ColorAverage := r + BSL (g, 8) + BSL (b, 16)

		END;

	FUNCTION BestClobber (color: LONGINT): INTEGER;

		VAR
			gray: INTEGER;
			dist: INTEGER;
			bestDist: INTEGER;

		BEGIN

		bestDist := 1024;

		FOR gray := 0 TO size - 1 DO
			BEGIN

			IF gray = size - 1 THEN
				dist := ColorDist (table [gray] . color, color)
			ELSE
				dist := ColorDist (table [gray] . color,
								   table [gray + 1] . color);

			IF gray = 0 THEN
				dist := Min (dist, ColorDist (color, table [0] . color));

			IF (dist < bestDist) OR
			   (dist = bestDist) AND (color = 0) THEN
				IF (table [gray] . color <> 0) AND
				   (table [gray] . color <> $FFFFFF) THEN
					BEGIN
					bestDist := dist;
					BestClobber := gray
					END

			END

		END;

	FUNCTION BestMatch (color: LONGINT): INTEGER;

		VAR
			gray: INTEGER;
			dist: INTEGER;
			bestDist: INTEGER;

		BEGIN

		bestDist := 1024;

		FOR gray := 0 TO size - 1 DO
			BEGIN

			dist := ColorDist (color, table [gray] . color);

			IF dist < bestDist THEN
				BEGIN
				bestDist := dist;
				BestMatch := gray
				END

			END

		END;

	BEGIN

	FOR gray := 0 TO 255 DO
		BEGIN
		table [gray] . gray := gray;
		table [gray] . color := ORD (theColors.R [gray]) +
						   BSL (ORD (theColors.G [gray]), 8) +
						   BSL (ORD (theColors.B [gray]), 16)
		END;

	qsort (@table, 256, SIZEOF (TColor), @CompareColors);

	LUT1 := gNullLUT;

	gray := 0;
	size := 256;
		REPEAT
		IF table [gray] . color = table [gray + 1] . color THEN
			BEGIN
			LUT1 [table [gray + 1] . gray] := CHR (table [gray] . gray);
			IF size > gray + 2 THEN
				BlockMove (Ptr (@table [gray + 2]),
						   Ptr (@table [gray + 1]),
						   SIZEOF (TColor) * (size - gray - 2));
			size := size - 1
			END
		ELSE
			gray := gray + 1
		UNTIL gray >= size - 1;

	sameOrder := TRUE;

	IF table [0] . color <> $FFFFFF THEN
		BEGIN

		sameOrder := FALSE;

		IF size < 256 THEN
			BEGIN
			BlockMove (Ptr (@table [0]),
					   Ptr (@table [1]),
					   SIZEOF (TColor) * size);
			table [0] . gray  := -1;
			table [0] . color := $FFFFFF;
			size := size + 1
			END

		ELSE
			BEGIN
			clobber := BestClobber ($FFFFFF);
			color := table [clobber] . color;
			table [clobber] . color := $FFFFFF;
			match := BestMatch (color);
			IF match <> clobber THEN
				BEGIN
				FOR gray := 0 TO 255 DO
					IF ORD (LUT1 [gray]) = table [clobber] . gray THEN
						LUT1 [gray] := CHR (table [match] . gray);
				table [clobber] . gray	:= -1;
				table [match  ] . color :=
						ColorAverage (table [match] . color, color)
				END
			END

		END;

	IF table [size - 1] . color <> 0 THEN
		BEGIN

		sameOrder := FALSE;

		IF size < 256 THEN
			BEGIN
			table [size] . gray  := -1;
			table [size] . color := 0;
			size := size + 1
			END

		ELSE
			BEGIN
			clobber := BestClobber (0);
			color := table [clobber] . color;
			table [clobber] . color := 0;
			match := BestMatch (color);
			IF match <> clobber THEN
				BEGIN
				FOR gray := 0 TO 255 DO
					IF ORD (LUT1 [gray]) = table [clobber] . gray THEN
						LUT1 [gray] := CHR (table [match] . gray);
				table [clobber] . gray	:= -1;
				table [match  ] . color :=
						ColorAverage (table [match] . color, color)
				END
			END

		END;

	IF sameOrder THEN
		FOR gray := 255 DOWNTO 0 DO
			IF (theColors.R [gray] = CHR (0)) &
			   (theColors.G [gray] = CHR (0)) &
			   (theColors.B [gray] = CHR (0)) THEN
				firstBlack := gray
			ELSE IF gray >= size - 1 THEN
				sameOrder := FALSE;

	IF sameOrder THEN
		BEGIN

		FOR gray := 0 TO 255 DO
			table [gray] . color := ORD (theColors.R [gray]) +
							   BSL (ORD (theColors.G [gray]), 8) +
							   BSL (ORD (theColors.B [gray]), 16);

		LUT := gNullLUT;

		FOR gray := size TO 255 DO
			LUT [gray] := CHR (firstBlack)

		END

	ELSE
		BEGIN

		qsort (@table, size, SIZEOF (TColor), @CompareColors);

		FOR gray := 0 TO size - 1 DO
			IF table [gray] . gray >= 0 THEN
				LUT2 [table [gray] . gray] := CHR (gray);

		FOR gray := 0 to 255 DO
			LUT [gray] := LUT2 [ORD (LUT1 [gray])]

		END;

	cTable := CTabHandle (NewPermHandle (8 + SIZEOF (ColorSpec) * size));
	FailMemError;

	IF gConfiguration.hasColorToolbox THEN
		cTable^^.ctSeed := GetCTSeed
	ELSE
		cTable^^.ctSeed := 1024;

	cTable^^.transIndex := 0;
	cTable^^.ctSize := size - 1;

	{$PUSH}
	{$R-}

	FOR gray := 0 TO size - 1 DO
		WITH cTable^^.ctTable [gray] DO
			BEGIN

			value := gray;

			color := BAND (table [gray] . color, $FF);
			rgb.red := BSL (color, 8) + color;

			color := BAND (BSR (table [gray] . color, 8), $FF);
			rgb.green := BSL (color, 8) + color;

			color := BSR (table [gray] . color, 16);
			rgb.blue := BSL (color, 8) + color

			END;

	{$POP}

	MakePseudocolorTable := cTable

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION MakeMonochromeTable (levels: INTEGER): CTabHandle;

	VAR
		gray: INTEGER;
		cTable: CTabHandle;

	BEGIN

	cTable := CTabHandle (NewPermHandle (8 + SIZEOF (ColorSpec) * levels));
	FailMemError;

	cTable^^.ctSeed := 500 + levels;
	cTable^^.transIndex := 0;
	cTable^^.ctSize := levels - 1;

	{$PUSH}
	{$R-}

	FOR gray := 0 TO levels - 1 DO
		WITH cTable^^.ctTable [gray] DO
			BEGIN

			value := gray;

			rgb.red   := 65535 - gray * 65535 DIV (levels - 1);
			rgb.green := rgb.red;
			rgb.blue  := rgb.red

			END;

	{$POP}

	MakeMonochromeTable := cTable

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION MakeColorTable (levels: INTEGER): CTabHandle;

	VAR
		r: INTEGER;
		g: INTEGER;
		b: INTEGER;
		size: INTEGER;
		index: INTEGER;
		cTable: CTabHandle;

	BEGIN

	size := levels * levels * levels;

	cTable := CTabHandle (NewPermHandle (8 + SIZEOF (ColorSpec) * size));
	FailMemError;

	cTable^^.ctSeed := 800 + levels;
	cTable^^.transIndex := 0;
	cTable^^.ctSize := size - 1;

	{$PUSH}
	{$R-}

	FOR r := 0 TO levels - 1 DO
		FOR g := 0 TO levels - 1 DO
			FOR b := 0 TO levels - 1 DO
				BEGIN

				index := ((b * levels) + g) * levels + r;

				WITH cTable^^.ctTable [index] DO
					BEGIN

					value := index;

					rgb.red   := 65535 - r * 65535 DIV (levels - 1);
					rgb.green := 65535 - g * 65535 DIV (levels - 1);
					rgb.blue  := 65535 - b * 65535 DIV (levels - 1)

					END

				END;

	{$POP}

	MakeColorTable := cTable

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION IsSystemPalette (LUT: TRGBLookUpTable): BOOLEAN;

	VAR
		r: INTEGER;
		g: INTEGER;
		b: INTEGER;
		index: INTEGER;

	BEGIN

	FOR index := 0 TO 255 DO
		BEGIN

		r := ORD (LUT.R [index]);
		g := ORD (LUT.G [index]);
		b := ORD (LUT.B [index]);

		IF ((r MOD 51 <> 0) OR (g MOD 51 <> 0) OR (b MOD 51 <> 0)) AND
		   ((r MOD 17 <> 0) OR (g		 <> 0) OR (b		<> 0)) AND
		   ((r		  <> 0) OR (g MOD 17 <> 0) OR (b		<> 0)) AND
		   ((r		  <> 0) OR (g		 <> 0) OR (b MOD 17 <> 0)) AND
		   ((r MOD 17 <> 0) OR (g		 <> r) OR (b		<> r)) THEN

			BEGIN
			IsSystemPalette := FALSE;
			EXIT (IsSystemPalette)
			END

		END;

	IsSystemPalette := TRUE

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE CompThresTable (grayLevels: INTEGER;
						  VAR grayGap: INTEGER;
						  VAR thresTable: TThresTable);

	VAR
		gray: INTEGER;

	BEGIN

	grayGap := 255 DIV (grayLevels - 1);

	FOR gray := 0 TO grayGap + 254 DO
		thresTable [gray] := CHR (grayLevels - 1 -
								  ORD4 (gray) * (grayLevels - 1) DIV 255);

	FOR gray := 255 + grayGap TO 510 DO
		thresTable [gray] := CHR (0)

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE CompNoiseTable (ditherCode: INTEGER;
						  grayGap: INTEGER;
						  VAR ditherSize: INTEGER;
						  VAR noiseTable: TNoiseTable);

	VAR
		r: INTEGER;
		c: INTEGER;

	BEGIN

	IF ditherCode = 0 THEN
		BEGIN
		ditherSize := 1;
		noiseTable [0, 0] := CHR (grayGap DIV 2)
		END

	ELSE
		BEGIN
		ditherSize := 8;
		FOR r := 0 TO 7 DO
			FOR c := 0 TO 7 DO
				noiseTable [r, c] :=
						CHR ((ClusterOffset (r, c, 6) + 1) * grayGap DIV 65)
		END

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE TDitherTables.ITables;

	BEGIN

	fColorTable := NIL

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE TDitherTables.Free; OVERRIDE;

	BEGIN

	IF fColorTable <> NIL THEN
		DisposHandle (Handle (fColorTable));

	INHERITED Free

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE TDitherTables.CompTables (doc: TImageDocument;
									channel: INTEGER;
									forceMonochrome: BOOLEAN;
									forceSystem: BOOLEAN;
									depth: INTEGER;
									resolution: INTEGER;
									autoDepth: BOOLEAN;
									autoResolution: BOOLEAN;
									ditherCode: INTEGER);

{ Initializes dither tables. }

	VAR
		lo: INTEGER;
		hi: INTEGER;
		fi: FailInfo;
		gray: INTEGER;
		grayGap: INTEGER;
		grayLevels: INTEGER;
		LUT: TRGBLookUpTable;

	PROCEDURE UnlockSelf (error: INTEGER; message: LONGINT);
		BEGIN
		HUnlock (Handle (SELF))
		END;

	BEGIN

	HLock (Handle (SELF));

	CatchFailures (fi, UnlockSelf);

	IF fColorTable <> NIL THEN
		BEGIN
		DisposHandle (Handle (fColorTable));
		fColorTable := NIL
		END;

	fMonochrome := forceMonochrome;

	fDepth		:= depth;
	fResolution := resolution;

	IF doc.fMode = HalftoneMode THEN
		BEGIN

		fMethod := DitherMethodHalftone;

		IF autoDepth	  THEN fDepth := 1;
		IF autoResolution THEN fResolution := 1;

		IF fResolution <> 1 THEN
			CASE fDepth OF

			2:	BEGIN
				fLUT1 [$00] := CHR ($00);
				fLUT1 [$01] := CHR ($03);
				fLUT1 [$04] := CHR ($0C);
				fLUT1 [$05] := CHR ($0F);
				fLUT1 [$10] := CHR ($30);
				fLUT1 [$11] := CHR ($33);
				fLUT1 [$14] := CHR ($3C);
				fLUT1 [$15] := CHR ($3F);
				fLUT1 [$40] := CHR ($C0);
				fLUT1 [$41] := CHR ($C3);
				fLUT1 [$44] := CHR ($CC);
				fLUT1 [$45] := CHR ($CF);
				fLUT1 [$50] := CHR ($F0);
				fLUT1 [$51] := CHR ($F3);
				fLUT1 [$54] := CHR ($FC);
				fLUT1 [$55] := CHR ($FF)
				END;

			4:	BEGIN
				lo := BSR ($F, 4 - fResolution);
				hi := BSL (lo, 4);
				fLUT1 [$00] := CHR (0);
				fLUT1 [$01] := CHR (lo);
				fLUT1 [$10] := CHR (hi);
				fLUT1 [$11] := CHR (hi + lo)
				END;

			8:	BEGIN
				fLUT1 [0] := CHR (0);
				fLUT1 [1] := CHR (BSR ($FF, 8 - fResolution))
				END;

			OTHERWISE
				Failure (1, 0)

			END;

		IF fDepth > 8 THEN
			Failure (1, 0)

		ELSE IF fDepth > 1 THEN
			fColorTable := MakeMonochromeTable (BSL (1, fResolution));

		fSystemPalette := (fResolution = 4)

		END

	ELSE IF fDepth = 32 THEN
		BEGIN

		IF fResolution <> 32 THEN Failure (1, 0);

		fLUT1 := gNullLUT;
		fLUT2 := gNullLUT;
		fLUT3 := gNullLUT;

		fMethod := DitherMethod24BitTable;

		IF (doc.fMode = RGBColorMode) AND (channel = kRGBChannels) THEN
			fMethod := DitherMethod24BitRGB

		ELSE IF doc.fMode = IndexedColorMode THEN
			BEGIN
			fLUT1 := doc.fIndexedColorTable.R;
			fLUT2 := doc.fIndexedColorTable.G;
			fLUT3 := doc.fIndexedColorTable.B
			END

		END

	ELSE IF fDepth = 16 THEN
		BEGIN

		IF fResolution <> 16 THEN Failure (1, 0);

		fLUT1 := gNullLUT;
		fLUT2 := gNullLUT;
		fLUT3 := gNullLUT;

		fMethod := DitherMethod16BitTable;

		IF (doc.fMode = RGBColorMode) AND (channel = kRGBChannels) THEN
			fMethod := DitherMethod16BitRGB

		ELSE IF doc.fMode = IndexedColorMode THEN
			BEGIN
			fLUT1 := doc.fIndexedColorTable.R;
			fLUT2 := doc.fIndexedColorTable.G;
			fLUT3 := doc.fIndexedColorTable.B
			END;

		{$H-}
		CompThresTable (32, grayGap, fThresTable1);
		CompNoiseTable (ditherCode, grayGap, fDitherSize, fNoiseTable);
		{$H+}

		FOR gray := 0 TO 510 DO
			fThresTable1 [gray] := CHR (31 - ORD (fThresTable1 [gray]))

		END

	ELSE IF doc.fMode = IndexedColorMode THEN
		BEGIN

		LUT := doc.fIndexedColorTable;

		fSystemPalette := IsSystemPalette (LUT);

		IF NOT forceMonochrome AND
				(fResolution >= 2) AND (fResolution <= 8) AND
				(NOT forceSystem OR fSystemPalette) THEN
			BEGIN

			{$H-}
			fColorTable := MakePseudocolorTable (LUT, fLUT1);
			{$H+}

			IF fColorTable^^.ctSize > BSL (1, fResolution) - 1 THEN
				BEGIN
				DisposHandle (Handle (fColorTable));
				fColorTable := NIL
				END

			END;

		IF fColorTable <> NIL THEN
			BEGIN

			fMethod := DitherMethodSimple;

			IF autoResolution THEN
				WHILE fColorTable^^.ctSize < BSL (1, fResolution - 1) DO
					fResolution := fResolution - 1;

			fDitherSize := 1;
			fNoiseTable [0, 0] := CHR (0);

			FOR gray := 0 TO 255 DO
				fThresTable1 [gray] := CHR (gray)

			END

		ELSE IF NOT forceMonochrome AND
				(fResolution >= 3) AND (fResolution <= 8) THEN
			BEGIN

			fMethod := DitherMethodIndexed;

			fLUT1 := LUT.R;
			fLUT2 := LUT.G;
			fLUT3 := LUT.B;

				CASE fResolution OF
				3:	grayLevels := 2;
				4:	grayLevels := 2;
				5:	grayLevels := 3;
				6:	grayLevels := 4;
				7:	grayLevels := 5;
				8:	grayLevels := 6
				END;

			{$H-}
			CompThresTable (grayLevels, grayGap, fThresTable1);
			{$H+}

			FOR gray := 0 TO 510 DO
				BEGIN
				fThresTable2 [gray] := CHR (ORD (fThresTable1 [gray]) *
											grayLevels);
				fThresTable3 [gray] := CHR (ORD (fThresTable2 [gray]) *
											grayLevels)
				END;

			{$H-}
			CompNoiseTable (ditherCode, grayGap, fDitherSize, fNoiseTable);
			{$H+}

			fColorTable := MakeColorTable (grayLevels);

			fSystemPalette := (fResolution = 8)

			END

		ELSE
			BEGIN

			fMethod := DitherMethodSimple;

			FOR gray := 0 TO 255 DO
				fLUT1 [gray] := ConvertToGray (LUT.R [gray],
											   LUT.G [gray],
											   LUT.B [gray]);

			grayLevels := BSL (1, fResolution);

			{$H-}
			CompThresTable (grayLevels, grayGap, fThresTable1);
			{$H+}

			{$H-}
			CompNoiseTable (ditherCode, grayGap, fDitherSize, fNoiseTable);
			{$H+}

			IF fDepth <> 1 THEN
				fColorTable := MakeMonochromeTable (grayLevels);

			fSystemPalette := (fResolution = 4)

			END

		END

	ELSE IF (doc.fMode = RGBColorMode) AND (channel = kRGBChannels) THEN

		IF NOT forceMonochrome AND
				(fResolution >= 3) AND (fResolution <= 8) THEN
			BEGIN

			fMethod := DitherMethodRGB;

			fLUT1 := gNullLUT;
			fLUT2 := gNullLUT;
			fLUT3 := gNullLUT;

				CASE fResolution OF
				3:	grayLevels := 2;
				4:	grayLevels := 2;
				5:	grayLevels := 3;
				6:	grayLevels := 4;
				7:	grayLevels := 5;
				8:	grayLevels := 6
				END;

			{$H-}
			CompThresTable (grayLevels, grayGap, fThresTable1);
			{$H+}

			FOR gray := 0 TO 510 DO
				BEGIN
				fThresTable2 [gray] := CHR (ORD (fThresTable1 [gray]) *
											grayLevels);
				fThresTable3 [gray] := CHR (ORD (fThresTable2 [gray]) *
											grayLevels)
				END;

			{$H-}
			CompNoiseTable (ditherCode, grayGap, fDitherSize, fNoiseTable);
			{$H+}

			fColorTable := MakeColorTable (grayLevels);

			fSystemPalette := (fResolution = 6)

			END

		ELSE
			BEGIN

			fMethod := DitherMethodRGBMonochrome;

			fLUT1 := gGrayLUT.R;
			fLUT2 := gGrayLUT.G;
			fLUT3 := gGrayLUT.B;

			IF forceSystem THEN
				BEGIN
				IF autoDepth	  THEN fDepth := 4;
				IF autoResolution THEN fResolution := 4
				END;

			grayLevels := BSL (1, fResolution);

			{$H-}
			CompThresTable (grayLevels, grayGap, fThresTable1);
			{$H+}

			{$H-}
			CompNoiseTable (ditherCode, grayGap, fDitherSize, fNoiseTable);
			{$H+}

			IF fDepth <> 1 THEN
				fColorTable := MakeMonochromeTable (grayLevels);

			fSystemPalette := (fResolution = 4)

			END

	ELSE
		BEGIN

		fMethod := DitherMethodSimple;

		IF forceSystem THEN
			BEGIN
			IF autoDepth	  THEN fDepth := 4;
			IF autoResolution THEN fResolution := 4
			END;

		fLUT1 := gNullLUT;

		grayLevels := BSL (1, fResolution);

		{$H-}
		CompThresTable (grayLevels, grayGap, fThresTable1);
		{$H+}

		{$H-}
		CompNoiseTable (ditherCode, grayGap, fDitherSize, fNoiseTable);
		{$H+}

		IF fDepth <> 1 THEN
			fColorTable := MakeMonochromeTable (grayLevels);

		fSystemPalette := (fResolution = 4)

		END;

	Success (fi);

	UnlockSelf (0, 0)

	END;

{*****************************************************************************}

{$S ARes3}

FUNCTION TDitherTables.CompRowBytes (width: INTEGER): LONGINT;

	BEGIN

		CASE fDepth OF

		1:	CompRowBytes := BSL (BSR (width + 15, 4), 1);
		2:	CompRowBytes := BSL (BSR (width +  7, 3), 1);
		4:	CompRowBytes := BSL (BSR (width +  3, 2), 1);
		8:	CompRowBytes := BSL (BSR (width +  1, 1), 1);
		16: CompRowBytes := BSL (width, 1);
		32: CompRowBytes := BSL (width, 2);

		OTHERWISE
			Failure (1, 0)

		END

	END;

{*****************************************************************************}

{$S ARes3}

FUNCTION TDitherTables.BufferSize (r: Rect): LONGINT;

	VAR
		width: INTEGER;
		height: LONGINT;

	BEGIN

	width  := r.right - r.left;
	height := r.bottom - r.top;

		CASE fMethod OF

		DitherMethodRGBMonochrome:
			BufferSize := height * (width + CompRowBytes (width));

		DitherMethod16BitRGB,
		DitherMethod16BitTable:
			BufferSize := height * (BAND (width + 1, $7FFE) +
									CompRowBytes (width));

		OTHERWISE
			BufferSize := height * CompRowBytes (width)

		END

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE TDitherTables.DitherRect (doc: TImageDocument;
									channel: INTEGER;
									magnification: INTEGER;
									r: Rect;
									buffer: Ptr;
									doFlush: BOOLEAN);

	VAR
		fi: FailInfo;
		dataPtr: Ptr;
		size: LONGINT;
		rDataPtr: Ptr;
		gDataPtr: Ptr;
		bDataPtr: Ptr;
		topRow: INTEGER;
		botRow: INTEGER;
		tempBuffer: Ptr;
		rowBytes: INTEGER;
		tempRowBytes: INTEGER;
		dataRowBytes: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		IF rDataPtr <> NIL THEN doc.fData [0] . DoneWithPtr;
		IF gDataPtr <> NIL THEN doc.fData [1] . DoneWithPtr;
		IF bDataPtr <> NIL THEN doc.fData [2] . DoneWithPtr;

		IF doFlush THEN
			BEGIN
			doc.fData [0] . Flush;
			doc.fData [1] . Flush;
			doc.fData [2] . Flush
			END

		END;

	BEGIN

	IF magnification > 0 THEN
		BEGIN
		topRow := r.top 		 DIV magnification;
		botRow := (r.bottom - 1) DIV magnification
		END
	ELSE
		BEGIN
		topRow := r.top 		 * (-magnification);
		botRow := (r.bottom - 1) * (-magnification)
		END;

	{$IFC qDebug}

	IF topRow DIV doc.fData [0] . fBlocksPerPage <>
	   botRow DIV doc.fData [0] . fBlocksPerPage THEN
		ProgramBreak ('DitherRect request crosses page boundary');

	{$ENDC}

	rowBytes := CompRowBytes (r.right - r.left);

	dataRowBytes := doc.fData [0] . fPhysicalSize;

		CASE fMethod OF

		DitherMethodHalftone:
			BEGIN

			size := rowBytes * ORD4 (r.bottom - r.top);

			DoSetBytes (buffer, size, 0);

			dataPtr := doc.fData [0] . NeedPtr (topRow, botRow, FALSE);

			dataPtr := Ptr (ORD4 (dataPtr) - ORD4 (dataRowBytes) * topRow);

			DoHalftone (dataPtr, dataRowBytes, buffer, rowBytes,
						fDepth, r, magnification);

			doc.fData [0] . DoneWithPtr;

			IF doFlush THEN
				doc.fData [0] . Flush;

			IF fResolution <> 1 THEN
				DoMapBytes (buffer, size, fLUT1)

			END;

		DitherMethodSimple:
			BEGIN

			dataPtr := doc.fData [channel] . NeedPtr
											 (topRow, botRow, FALSE);

			dataPtr := Ptr (ORD4 (dataPtr) - ORD4 (dataRowBytes) * topRow);

			DoDither (dataPtr, dataRowBytes, buffer, rowBytes,
					  fDepth, r, magnification, fDitherSize,
					  fLUT1, fNoiseTable, fThresTable1, TRUE);

			doc.fData [channel] . DoneWithPtr;

			IF doFlush THEN
				doc.fData [channel] . Flush

			END;

		DitherMethodIndexed:
			BEGIN

			dataPtr := doc.fData [0] . NeedPtr (topRow, botRow, FALSE);

			dataPtr := Ptr (ORD4 (dataPtr) - ORD4 (dataRowBytes) * topRow);

			DoDither (dataPtr, dataRowBytes, buffer, rowBytes,
					  fDepth, r, magnification, fDitherSize,
					  fLUT1, fNoiseTable, fThresTable1, TRUE);

			DoDither (dataPtr, dataRowBytes, buffer, rowBytes,
					  fDepth, r, magnification, fDitherSize,
					  fLUT2, fNoiseTable, fThresTable2, FALSE);

			DoDither (dataPtr, dataRowBytes, buffer, rowBytes,
					  fDepth, r, magnification, fDitherSize,
					  fLUT3, fNoiseTable, fThresTable3, FALSE);

			doc.fData [0] . DoneWithPtr;

			IF doFlush THEN
				doc.fData [0] . Flush

			END;

		DitherMethodRGB:
			BEGIN

			dataPtr := doc.fData [0] . NeedPtr (topRow, botRow, FALSE);

			dataPtr := Ptr (ORD4 (dataPtr) - ORD4 (dataRowBytes) * topRow);

			DoDither (dataPtr, dataRowBytes, buffer, rowBytes,
					  fDepth, r, magnification, fDitherSize,
					  fLUT1, fNoiseTable, fThresTable1, TRUE);

			doc.fData [0] . DoneWithPtr;

			IF doFlush THEN
				doc.fData [0] . Flush;

			dataPtr := doc.fData [1] . NeedPtr (topRow, botRow, FALSE);

			dataPtr := Ptr (ORD4 (dataPtr) - ORD4 (dataRowBytes) * topRow);

			DoDither (dataPtr, dataRowBytes, buffer, rowBytes,
					  fDepth, r, magnification, fDitherSize,
					  fLUT2, fNoiseTable, fThresTable2, FALSE);

			doc.fData [1] . DoneWithPtr;

			IF doFlush THEN
				doc.fData [1] . Flush;

			dataPtr := doc.fData [2] . NeedPtr (topRow, botRow, FALSE);

			dataPtr := Ptr (ORD4 (dataPtr) - ORD4 (dataRowBytes) * topRow);

			DoDither (dataPtr, dataRowBytes, buffer, rowBytes,
					  fDepth, r, magnification, fDitherSize,
					  fLUT3, fNoiseTable, fThresTable3, FALSE);

			doc.fData [2] . DoneWithPtr;

			IF doFlush THEN
				doc.fData [2] . Flush

			END;

		DitherMethodRGBMonochrome:
			BEGIN

			rDataPtr := NIL;
			gDataPtr := NIL;
			bDataPtr := NIL;

			CatchFailures (fi, CleanUp);

			rDataPtr := doc.fData [0] . NeedPtr (topRow, botRow, FALSE);
			gDataPtr := doc.fData [1] . NeedPtr (topRow, botRow, FALSE);
			bDataPtr := doc.fData [2] . NeedPtr (topRow, botRow, FALSE);

			Success (fi);

			rDataPtr := Ptr (ORD4 (rDataPtr) - ORD4 (dataRowBytes) * topRow);
			gDataPtr := Ptr (ORD4 (gDataPtr) - ORD4 (dataRowBytes) * topRow);
			bDataPtr := Ptr (ORD4 (bDataPtr) - ORD4 (dataRowBytes) * topRow);

			tempBuffer := Ptr (ORD4 (buffer) +
							   ORD4 (r.bottom - r.top) * rowBytes);

			DoMonochrome (rDataPtr, gDataPtr, bDataPtr, dataRowBytes,
						  tempBuffer, r, magnification,
						  fLUT1, fLUT2, fLUT3);

			tempBuffer := Ptr (ORD4 (tempBuffer) -
							   r.top * ORD4 (r.right - r.left) -
							   r.left);

			DoDither (tempBuffer, r.right - r.left, buffer, rowBytes,
					  fDepth, r, 1, fDitherSize, gNullLUT,
					  fNoiseTable, fThresTable1, TRUE);

			doc.fData [0] . DoneWithPtr;
			doc.fData [1] . DoneWithPtr;
			doc.fData [2] . DoneWithPtr;

			IF doFlush THEN
				BEGIN
				doc.fData [0] . Flush;
				doc.fData [1] . Flush;
				doc.fData [2] . Flush
				END

			END;

		DitherMethod24BitRGB:
			BEGIN

			DoSetBytes (buffer, rowBytes * ORD4 (r.bottom - r.top), 0);

			dataPtr := doc.fData [0] . NeedPtr (topRow, botRow, FALSE);

			dataPtr := Ptr (ORD4 (dataPtr) - ORD4 (dataRowBytes) * topRow);

			DoDither24 (dataPtr, dataRowBytes,
						Ptr (ORD4 (buffer) + 1), rowBytes,
						4, r, magnification, fLUT1);

			doc.fData [0] . DoneWithPtr;

			IF doFlush THEN
				doc.fData [0] . Flush;

			dataPtr := doc.fData [1] . NeedPtr (topRow, botRow, FALSE);

			dataPtr := Ptr (ORD4 (dataPtr) - ORD4 (dataRowBytes) * topRow);

			DoDither24 (dataPtr, dataRowBytes,
						Ptr (ORD4 (buffer) + 2), rowBytes,
						4, r, magnification, fLUT2);

			doc.fData [1] . DoneWithPtr;

			IF doFlush THEN
				doc.fData [1] . Flush;

			dataPtr := doc.fData [2] . NeedPtr (topRow, botRow, FALSE);

			dataPtr := Ptr (ORD4 (dataPtr) - ORD4 (dataRowBytes) * topRow);

			DoDither24 (dataPtr, dataRowBytes,
						Ptr (ORD4 (buffer) + 3), rowBytes,
						4, r, magnification, fLUT3);

			doc.fData [2] . DoneWithPtr;

			IF doFlush THEN
				doc.fData [2] . Flush

			END;

		DitherMethod24BitTable:
			BEGIN

			DoSetBytes (buffer, rowBytes * ORD4 (r.bottom - r.top), 0);

			dataPtr := doc.fData [channel] . NeedPtr (topRow, botRow, FALSE);

			dataPtr := Ptr (ORD4 (dataPtr) - ORD4 (dataRowBytes) * topRow);

			DoDither24 (dataPtr, dataRowBytes,
						Ptr (ORD4 (buffer) + 1), rowBytes,
						4, r, magnification, fLUT1);

			DoDither24 (dataPtr, dataRowBytes,
						Ptr (ORD4 (buffer) + 2), rowBytes,
						4, r, magnification, fLUT2);

			DoDither24 (dataPtr, dataRowBytes,
						Ptr (ORD4 (buffer) + 3), rowBytes,
						4, r, magnification, fLUT3);

			doc.fData [channel] . DoneWithPtr;

			IF doFlush THEN
				doc.fData [channel] . Flush

			END;

		DitherMethod16BitRGB:
			BEGIN

			tempBuffer := Ptr (ORD4 (buffer) +
							   ORD4 (r.bottom - r.top) * rowBytes);

			tempRowBytes := BAND (r.right - r.left + 1, $7FFE);

			dataPtr := doc.fData [0] . NeedPtr (topRow, botRow, FALSE);

			dataPtr := Ptr (ORD4 (dataPtr) - ORD4 (dataRowBytes) * topRow);

			DoDither (dataPtr, dataRowBytes, tempBuffer, tempRowBytes,
					  8, r, magnification, fDitherSize,
					  fLUT1, fNoiseTable, fThresTable1, TRUE);

			doc.fData [0] . DoneWithPtr;

			IF doFlush THEN
				doc.fData [0] . Flush;

			DoDither16Red (tempBuffer, tempRowBytes, buffer, rowBytes,
						   r.bottom - r.top, r.right - r.left);

			dataPtr := doc.fData [1] . NeedPtr (topRow, botRow, FALSE);

			dataPtr := Ptr (ORD4 (dataPtr) - ORD4 (dataRowBytes) * topRow);

			DoDither (dataPtr, dataRowBytes, tempBuffer, tempRowBytes,
					  8, r, magnification, fDitherSize,
					  fLUT2, fNoiseTable, fThresTable1, TRUE);

			doc.fData [1] . DoneWithPtr;

			IF doFlush THEN
				doc.fData [1] . Flush;

			DoDither16Green (tempBuffer, tempRowBytes, buffer, rowBytes,
							 r.bottom - r.top, r.right - r.left);

			dataPtr := doc.fData [2] . NeedPtr (topRow, botRow, FALSE);

			dataPtr := Ptr (ORD4 (dataPtr) - ORD4 (dataRowBytes) * topRow);

			DoDither (dataPtr, dataRowBytes, tempBuffer, tempRowBytes,
					  8, r, magnification, fDitherSize,
					  fLUT3, fNoiseTable, fThresTable1, TRUE);

			doc.fData [2] . DoneWithPtr;

			IF doFlush THEN
				doc.fData [2] . Flush;

			DoDither16Blue (tempBuffer, tempRowBytes, buffer, rowBytes,
							r.bottom - r.top, r.right - r.left)

			END;

		DitherMethod16BitTable:
			BEGIN

			tempBuffer := Ptr (ORD4 (buffer) +
							   ORD4 (r.bottom - r.top) * rowBytes);

			tempRowBytes := BAND (r.right - r.left + 1, $7FFE);

			dataPtr := doc.fData [channel] . NeedPtr (topRow, botRow, FALSE);

			dataPtr := Ptr (ORD4 (dataPtr) - ORD4 (dataRowBytes) * topRow);

			DoDither (dataPtr, dataRowBytes, tempBuffer, tempRowBytes,
					  8, r, magnification, fDitherSize,
					  fLUT1, fNoiseTable, fThresTable1, TRUE);

			DoDither16Red (tempBuffer, tempRowBytes, buffer, rowBytes,
						   r.bottom - r.top, r.right - r.left);

			DoDither (dataPtr, dataRowBytes, tempBuffer, tempRowBytes,
					  8, r, magnification, fDitherSize,
					  fLUT2, fNoiseTable, fThresTable1, TRUE);

			DoDither16Green (tempBuffer, tempRowBytes, buffer, rowBytes,
							 r.bottom - r.top, r.right - r.left);

			DoDither (dataPtr, dataRowBytes, tempBuffer, tempRowBytes,
					  8, r, magnification, fDitherSize,
					  fLUT3, fNoiseTable, fThresTable1, TRUE);

			DoDither16Blue (tempBuffer, tempRowBytes, buffer, rowBytes,
							r.bottom - r.top, r.right - r.left);

			doc.fData [channel] . DoneWithPtr;

			IF doFlush THEN
				doc.fData [channel] . Flush

			END

		END

	END;

{*****************************************************************************}

{$S AOpen}

PROCEDURE TImageView.IImageView (doc: TImageDocument);

	VAR
		fi: FailInfo;
		wSize: Point;
		iWidth: INTEGER;
		wWidth: INTEGER;
		itsExtent: Rect;
		tables: TDitherTables;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Free
		END;

	BEGIN

	fTables := NIL;
	fPalette := NIL;

	fDocument := doc;

		CASE doc.fMode OF

		RGBColorMode:
			fChannel := kRGBChannels;

		SeparationsCMYK:
			fChannel := 3;

		SeparationsHSL,
		SeparationsHSB:
			fChannel := 2;

		OTHERWISE
			fChannel := 0

		END;

	fWindow := NIL;

	fScreenMode := 0;
	fRulers := FALSE;

	GetZoomSize (wSize);

	IF ORD4 (doc.fRows) * wSize.h >= ORD4 (doc.fCols) * wSize.v THEN
		BEGIN
		wWidth := wSize.v;
		iWidth := doc.fRows
		END
	ELSE
		BEGIN
		wWidth := wSize.h;
		iWidth := doc.fCols
		END;

	IF wWidth < iWidth THEN
		fMagnification := Max (-((iWidth + wWidth - 1) DIV wWidth),
							   MinMagnification)
	ELSE
		fMagnification := 1;

	fDelayedUpdateRgn := NewRgn;

	fObscured := FALSE;
	fObscureTime := TickCount;

	CompBounds (itsExtent);

	IView (NIL, doc, itsExtent, sizeFixed, sizeFixed, TRUE, hlOff);

	CatchFailures (fi, CleanUp);

	NEW (tables);
	FailNil (tables);

	tables.ITables;

	fTables := tables;

	IDither;

	AddImagePrintHander (SELF);

	Success (fi)

	END;

{*****************************************************************************}

{$S AClose}

PROCEDURE TImageView.Free; OVERRIDE;

	BEGIN

	DisposeRgn (fDelayedUpdateRgn);

	FreeObject (fTables);

	IF fPalette <> NIL THEN
		DisposePalette (fPalette);

	INHERITED Free

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION TImageView.GetScreen: GDHandle;

	VAR
		r: Rect;
		port: GrafPtr;

	BEGIN

	GetScreen := NIL;

	IF gConfiguration.hasColorToolbox THEN

		IF fScreenMode <> 0 THEN
			GetScreen := GetMainDevice

		ELSE IF fWindow <> NIL THEN
			BEGIN

			GetPort (port);
			SetPort (fWindow.fWmgrWindow);

			r := fWindow.fWmgrWindow^.portRect;

			LocalToGlobal (r.topLeft);
			LocalToGlobal (r.botRight);

			GetScreen := GetMaxDevice (r);

			SetPort (port)

			END

		ELSE IF fFrame <> NIL THEN
			BEGIN

			GetPort (port);

			fFrame.Focus;

			fFrame.GetViewedRect (r);

			LocalToGlobal (r.topLeft);
			LocalToGlobal (r.botRight);

			GetScreen := GetMaxDevice (r);

			SetPort (port)

			END

		ELSE
			GetScreen := GetMainDevice

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE GetScreenInfo (device: GDHandle;
						 VAR depth: INTEGER;
						 VAR monochrome: BOOLEAN);

	BEGIN

	depth := 1;

	IF device <> NIL THEN
		CASE device^^.gdPMap^^.pixelSize OF
		2:	depth := 2;
		4:	depth := 4;
		8:	depth := 8;
		16: depth := 16;
		32: depth := 32
		END;

	IF depth = 1 THEN
		monochrome := TRUE

	ELSE IF depth > 8 THEN
		monochrome := FALSE

	ELSE
		monochrome := NOT TestDeviceAttribute (device, gdDevType)

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.GetViewScreenInfo (VAR depth: INTEGER;
										VAR monochrome: BOOLEAN);

	BEGIN
	GetScreenInfo (GetScreen, depth, monochrome)
	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.CvtImage2View (VAR pt: Point; way: BOOLEAN);

	BEGIN

	IF fMagnification > 0 THEN
		BEGIN
		pt.h := pt.h * fMagnification;
		pt.v := pt.v * fMagnification
		END

	ELSE IF way = kRoundUp THEN
		BEGIN
		pt.h := (pt.h - fMagnification - 1) DIV (-fMagnification);
		pt.v := (pt.v - fMagnification - 1) DIV (-fMagnification)
		END

	ELSE
		BEGIN
		pt.h := pt.h DIV (-fMagnification);
		pt.v := pt.v DIV (-fMagnification)
		END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.CvtView2Image (VAR pt: Point);

	VAR
		doc: TImageDocument;

	BEGIN

	IF fMagnification > 0 THEN
		BEGIN
		pt.h := pt.h DIV fMagnification;
		pt.v := pt.v DIV fMagnification
		END

	ELSE
		BEGIN
		pt.h := pt.h * (-fMagnification);
		pt.v := pt.v * (-fMagnification)
		END;

	doc := TImageDocument (fDocument);

	IF pt.h > doc.fCols THEN pt.h := doc.fCols;
	IF pt.v > doc.fRows THEN pt.v := doc.fRows

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TImageView.GetImageColor (pt: Point; VAR r, g, b: INTEGER);

	VAR
		dataPtr: Ptr;
		gray: INTEGER;
		doc: TImageDocument;

	PROCEDURE FinishedWith (aVMArray: TVMArray);
		BEGIN
		aVMArray.DoneWithPtr;
		IF aVMArray.fLoPage = aVMArray.fHiPage THEN
			aVMArray.Flush
		END;

	BEGIN

	doc := TImageDocument (fDocument);

	IF fChannel = kRGBChannels THEN
		BEGIN

		dataPtr := doc.fData [0] . NeedPtr (pt.v, pt.v, FALSE);

		r := BAND (Ptr (ORD4 (dataPtr) + pt.h)^, 255);

		FinishedWith (doc.fData [0]);

		dataPtr := doc.fData [1] . NeedPtr (pt.v, pt.v, FALSE);

		g := BAND (Ptr (ORD4 (dataPtr) + pt.h)^, 255);

		FinishedWith (doc.fData [1]);

		dataPtr := doc.fData [2] . NeedPtr (pt.v, pt.v, FALSE);

		b := BAND (Ptr (ORD4 (dataPtr) + pt.h)^, 255);

		FinishedWith (doc.fData [2])

		END

	ELSE
		BEGIN

		dataPtr := doc.fData [fChannel] . NeedPtr (pt.v, pt.v, FALSE);

		IF doc.fDepth = 8 THEN
			gray := BAND (Ptr (ORD4 (dataPtr) + pt.h)^, 255)

		ELSE IF BTST (Ptr (ORD4 (dataPtr) + BSR (pt.h, 3))^,
					  7 - BAND (pt.h, 7)) THEN
			gray := 0

		ELSE
			gray := 255;

		FinishedWith (doc.fData [fChannel]);

		IF doc.fMode = IndexedColorMode THEN
			BEGIN
			r := ORD (doc.fIndexedColorTable.R [gray]);
			g := ORD (doc.fIndexedColorTable.G [gray]);
			b := ORD (doc.fIndexedColorTable.B [gray])
			END

		ELSE
			BEGIN
			r := gray;
			g := gray;
			b := gray
			END

		END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.GetViewColor (pt: Point; VAR r, g, b: INTEGER);

	VAR
		ip: Point;

	BEGIN

	ip := pt;

	CvtView2Image (ip);

	ip.h := Max (0, Min (ip.h, TImageDocument (fDocument) . fCols - 1));
	ip.v := Max (0, Min (ip.v, TImageDocument (fDocument) . fRows - 1));

	GetImageColor (ip, r, g, b)

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION TImageView.GroundByte (color: RGBColor; channel: INTEGER): INTEGER;

	VAR
		r: INTEGER;
		g: INTEGER;
		b: INTEGER;
		gray: INTEGER;
		best: INTEGER;
		dist: INTEGER;
		index: INTEGER;
		doc: TImageDocument;

	BEGIN

	r := BAND (BSR (color.red  , 8), $FF);
	g := BAND (BSR (color.green, 8), $FF);
	b := BAND (BSR (color.blue , 8), $FF);

	gray := ORD (ConvertToGray (r, g, b));

	doc := TImageDocument (fDocument);

		CASE doc.fMode OF

		HalftoneMode:
			IF gray >= 128 THEN
				GroundByte := 0
			ELSE
				GroundByte := $FF;

		IndexedColorMode:
			BEGIN
			best := 768;
			FOR index := 0 TO 255 DO
				BEGIN
				dist := ABS (r - ORD (doc.fIndexedColorTable.R [index])) +
						ABS (g - ORD (doc.fIndexedColorTable.G [index])) +
						ABS (b - ORD (doc.fIndexedColorTable.B [index]));
				IF dist < best THEN
					BEGIN
					GroundByte := index;
					best := dist
					END
				END
			END;

		OTHERWISE
			BEGIN
			GroundByte := gray;
			IF fChannel = kRGBChannels THEN
				CASE channel OF
				0:	GroundByte := r;
				1:	GroundByte := g;
				2:	GroundByte := b
				END
			END

		END

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION TImageView.ForegroundByte (channel: INTEGER): INTEGER;

	BEGIN
	ForeGroundByte := GroundByte (gForegroundColor, channel)
	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION TImageView.BackgroundByte (channel: INTEGER): INTEGER;

	BEGIN
	BackgroundByte := GroundByte (gBackgroundColor, channel)
	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.CompBounds (VAR bounds: Rect);

	VAR
		doc: TImageDocument;

	BEGIN

	doc := TImageDocument (fDocument);

	bounds.top	  := 0;
	bounds.left   := 0;
	bounds.bottom := doc.fRows;
	bounds.right  := doc.fCols;

	CvtImage2View (bounds.botRight, kRoundUp)

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION TImageView.MinMagnification: INTEGER;

	BEGIN
	MinMagnification := -16
	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION TImageView.MaxMagnification: INTEGER;

	BEGIN
	MaxMagnification := Min (16, kMaxCoord DIV
								 Max (TImageDocument (fDocument) . fRows,
									  TImageDocument (fDocument) . fCols))
	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.ValidateView;

	VAR
		doc: TImageDocument;

	BEGIN

	doc := TImageDocument (fDocument);

	IF (fChannel = kRGBChannels) AND (doc.fMode <> RGBColorMode) THEN
		fChannel := 0;

	IF fChannel >= doc.fChannels THEN
		fChannel := doc.fChannels - 1;

	fMagnification := Max (MinMagnification,
					  Min (fMagnification,
						   MaxMagnification));

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.ChangeExtent;

	VAR
		r: Rect;

	BEGIN

	SetEmptyRgn (fDelayedUpdateRgn);

	ValidateView;

	CompBounds (r);
	SetExtent (r);

	IF fWindow <> NIL THEN
		BEGIN
		AdjustZoomSize;
		fFrame.ForceRedraw
		END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.AdjustExtent; OVERRIDE;

	VAR
		old: Rect;
		area: Rect;

	BEGIN

	old := fExtentRect;

	ChangeExtent;

	IF fWindow <> NIL THEN
		BEGIN

		GetGlobalArea (area);

		IF fScreenMode = 0 THEN
			IF (fExtentRect.right  > old.right ) OR
			   (fExtentRect.bottom > old.bottom) OR
			   (fExtentRect.right  < area.right  - area.left) OR
			   (fExtentRect.bottom < area.bottom - area.top ) THEN
				SetToZoomSize

		END

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TImageView.ShowReverted; OVERRIDE;

	BEGIN

	INHERITED ShowReverted;

	IF TImageDocument (fDocument) . fMode = RGBColorMode THEN
		fChannel := kRGBChannels;

	UpdateWindowTitle;

	DrawStatus;

	InvalRulers;

	ReDither (TRUE)

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION TImageView.ColorizeBand (VAR band: INTEGER;
								  VAR subtractive: BOOLEAN): BOOLEAN;

	VAR
		depth: INTEGER;
		doc: TImageDocument;
		monochrome: BOOLEAN;

	BEGIN

	band := 0;
	subtractive := FALSE;

	doc := TImageDocument (fDocument);

	GetViewScreenInfo (depth, monochrome);

	IF gPreferences.fColorize AND (depth >= 8) AND NOT monochrome THEN

		CASE doc.fMode OF

		RGBColorMode:
			IF fChannel <= 2 THEN
				band := fChannel + 1;

		SeparationsCMYK:
			IF (fChannel <= 2) AND
			   ((depth <> 8) OR NOT gPreferences.fUseSystem) THEN
				BEGIN
				band := fChannel + 1;
				subtractive := TRUE
				END

		END;

	ColorizeBand := band <> 0

	END;

{*****************************************************************************}

{$S ARes2}

{$IFC qTrace} {$D+} {$ENDC}

PROCEDURE DoColorize (VAR color: RGBColor;
					  band: INTEGER;
					  subtractive: BOOLEAN);

	BEGIN

	WITH color DO
		BEGIN

		IF band <> 1 THEN
			IF subtractive THEN
				red := $FFFF
			ELSE
				red := 0;

		IF band <> 2 THEN
			IF subtractive THEN
				green := $FFFF
			ELSE
				green := 0;

		IF band <> 3 THEN
			IF subtractive THEN
				blue := $FFFF
			ELSE
				blue := 0

		END

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.IDither;

{ Initializes the dither tables and color palette. }

	VAR
		j: INTEGER;
		size: INTEGER;
		band: INTEGER;
		swap: BOOLEAN;
		ct: CTabHandle;
		depth: INTEGER;
		doc: TImageDocument;
		lastColor: RGBColor;
		monochrome: BOOLEAN;
		firstColor: RGBColor;
		forceSystem: BOOLEAN;
		subtractive: BOOLEAN;

	BEGIN

	doc := TImageDocument (fDocument);

	GetViewScreenInfo (depth, monochrome);

	forceSystem := gPreferences.fUseSystem AND
				   (depth = 8) AND
				   (doc.fDepth <> 1);

	fTables.CompTables (doc,
						fChannel,
						monochrome,
						forceSystem,
						depth,
						depth,
						NOT forceSystem,
						TRUE,
						1);

	IF ColorizeBand (band, subtractive) THEN

		IF fTables.fColorTable = NIL THEN
			BEGIN

			IF band <> 1 THEN
				DoSetBytes (@fTables.fLUT1, 256, 255 * ORD (subtractive));

			IF band <> 2 THEN
				DoSetBytes (@fTables.fLUT2, 256, 255 * ORD (subtractive));

			IF band <> 3 THEN
				DoSetBytes (@fTables.fLUT3, 256, 255 * ORD (subtractive))

			END

		ELSE
			WITH fTables.fColorTable^^ DO
				FOR j := 0 TO ctSize DO
					{$PUSH}
					{$R-}
					{$H-}
					DoColorize (ctTable [j] . rgb, band, subtractive);
					{$H+}
					{$POP}

	fTransSeed := -1;

	IF fPalette <> NIL THEN
		BEGIN
		DisposePalette (fPalette);
		fPalette := NIL
		END;

	IF forceSystem THEN
		BEGIN

		ct := GetCTable (8);
		FailNil (ct);

		fPalette := NewPalette (256, ct, pmTolerant, 0);

		DisposCTable (ct);

		FailNil (fPalette)

		END

	ELSE IF fTables.fColorTable <> NIL THEN
		BEGIN

		size := fTables.fColorTable^^.ctSize;

		{$PUSH}
		{$R-}

		firstColor := fTables.fColorTable^^.ctTable [0	 ] . rgb;
		lastColor  := fTables.fColorTable^^.ctTable [size] . rgb;

		swap := (firstColor.red <> firstColor.green) OR
				(firstColor.red <> firstColor.blue );

		IF swap THEN
			BEGIN
			fTables.fColorTable^^.ctTable [0   ] . rgb := lastColor;
			fTables.fColorTable^^.ctTable [size] . rgb := firstColor
			END;

		fPalette := NewPalette (size + 1, fTables.fColorTable, pmTolerant, 0);

		IF swap THEN
			BEGIN
			fTables.fColorTable^^.ctTable [0   ] . rgb := firstColor;
			fTables.fColorTable^^.ctTable [size] . rgb := lastColor
			END;

		{$POP}

		FailNil (fPalette)

		END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.ReDither (redraw: BOOLEAN);

	BEGIN

	IDither;

	IF redraw THEN
		BEGIN

		fFrame.Focus;
		EraseRect (fExtentRect);

		fFrame.ForceRedraw;

		IF gTarget = SELF THEN
			IF gConfiguration.hasColorToolBox THEN
				InvalidateGhostColors

		END;

	IF (fPalette <> NIL) AND (fWindow <> NIL) THEN
		SetPalette (fWindow.fWmgrWindow, fPalette, TRUE)

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION TImageView.CompTransLUT (device: GDHandle): BOOLEAN;

	VAR
		gray: INTEGER;
		size: INTEGER;
		depth: INTEGER;
		color: RGBColor;
		table: CTabHandle;
		monochrome: BOOLEAN;
		saveDevice: GDHandle;
		index: ARRAY [0..15] OF INTEGER;

	BEGIN

	GetScreenInfo (device, depth, monochrome);

	table := fTables.fColorTable;

	IF (table = NIL) OR
		   (depth <> gTables.fDepth) OR
		   (depth < 2) OR
		   (depth > 8) THEN
		BEGIN
		CompTransLUT := FALSE;
		EXIT (CompTransLUT)
		END;

	IF fTransSeed = device^^.gdPMap^^.pmTable^^.ctSeed THEN
		BEGIN
		CompTransLUT := TRUE;
		EXIT (CompTransLUT)
		END;

	saveDevice := GetGDevice;

	SetGDevice (device);

	fTransSeed := device^^.gdPMap^^.pmTable^^.ctSeed;

	size := table^^.ctSize;

	IF depth = 8 THEN
		FOR gray := 0 TO size DO
			BEGIN

			{$PUSH}
			{$R-}
			color := table^^.ctTable [gray] . rgb;
			{$POP}

			fTransLUT [gray] := CHR (BAND ($FF, Color2Index (color)))

			END

	ELSE
		BEGIN

		FOR gray := 0 TO size DO
			BEGIN

			{$PUSH}
			{$R-}
			color := table^^.ctTable [gray] . rgb;
			{$POP}

			index [gray] := Color2Index (color)

			END;

		FOR gray := size + 1 TO 15 DO
			index [gray] := 0;

		IF depth = 4 THEN
			FOR gray := 0 TO 255 DO
				fTransLUT [gray] :=
						CHR (BSL (index [BSR (gray, 4)], 4) +
								  index [BAND (gray, $F)])

		ELSE
			FOR gray := 0 TO 255 DO
				fTransLUT [gray] :=
						CHR (BSL (index [BSR (gray, 6)], 6) +
							 BSL (index [BAND (BSR (gray, 4), $3)], 4) +
							 BSL (index [BAND (BSR (gray, 2), $3)], 2) +
								  index [BAND (gray, $3)])

		END;

	SetGDevice (saveDevice)

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.CheckDither;

	VAR
		r: Rect;
		depth: INTEGER;
		monochrome: BOOLEAN;

	BEGIN

	GetViewScreenInfo (depth, monochrome);

	IF (fTables.fDepth		<> depth	 ) OR
	   (fTables.fMonochrome <> monochrome) THEN
		BEGIN

		ReDither (FALSE);

		IF fWindow <> NIL THEN
			BEGIN

			fFrame.GetViewedRect (r);
			RectRgn (fDelayedUpdateRgn, r);

			gApplication.fIdlePriority := 1

			END

		END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.DrawNow (area: Rect; doFlush: BOOLEAN);

	TYPE
		BitPtr = ^BitMap;

	VAR
		r: Rect;
		rr: Rect;
		aPixMap: PixMap;
		topRow: INTEGER;
		botRow: INTEGER;
		device: GDHandle;
		topPage: INTEGER;
		botPage: INTEGER;
		maxRows: INTEGER;
		rowBytes: INTEGER;
		mapColors: BOOLEAN;
		doc: TImageDocument;
		blocksPerPage: INTEGER;

	BEGIN

	doc := TImageDocument (fDocument);

	IF doc.fMode <> HalftoneMode THEN
		CheckDither;

	rowBytes := fTables.CompRowBytes (area.right - area.left);

	IF fTables.fDepth = 1 THEN
		aPixMap.rowBytes := rowBytes
	ELSE
		aPixMap.rowBytes := BOR ($8000, rowBytes);
	aPixMap.baseAddr := gBuffer;
	aPixMap.pmVersion := 0;
	aPixMap.packType := 0;
	aPixMap.packSize := 0;
	aPixMap.hRes := $480000;
	aPixMap.vRes := $480000;

	IF fTables.fDepth = 32 THEN
		BEGIN
		aPixMap.pixelType := RGBDirect;
		aPixMap.pixelSize := 32;
		aPixMap.cmpCount  := 3;
		aPixMap.cmpSize   := 8
		END
	ELSE IF fTables.fDepth = 16 THEN
		BEGIN
		aPixMap.pixelType := RGBDirect;
		aPixMap.pixelSize := 16;
		aPixMap.cmpCount  := 3;
		aPixMap.cmpSize   := 5
		END
	ELSE
		BEGIN
		aPixMap.pixelType := 0;
		aPixMap.pixelSize := fTables.fDepth;
		aPixMap.cmpCount  := 1;
		aPixMap.cmpSize   := fTables.fDepth
		END;

	aPixMap.planeBytes := 0;
	aPixMap.pmReserved := 0;

	device := GetScreen;

	mapColors := CompTransLUT (device);

	IF mapColors THEN
		aPixMap.pmTable := device^^.gdPMap^^.pmTable
	ELSE
		aPixMap.pmTable := fTables.fColorTable;

	maxRows := 3072 DIV (area.right - area.left + 1);

	IF maxRows < 1 THEN maxRows := 1;

	r		 := area;
	r.bottom := area.top;

	blocksPerPage := doc.fData [0] . fBlocksPerPage;

	WHILE r.bottom < area.bottom DO
		BEGIN

		r.top	 := r.bottom;
		r.bottom := Min (r.top + maxRows, area.bottom);

		IF fMagnification > 0 THEN
			BEGIN
			topRow := r.top 		 DIV fMagnification;
			botRow := (r.bottom - 1) DIV fMagnification
			END
		ELSE
			BEGIN
			topRow := r.top 		 * (-fMagnification);
			botRow := (r.bottom - 1) * (-fMagnification)
			END;

		topPage := topRow DIV blocksPerPage;
		botPage := botRow DIV blocksPerPage;

		IF topPage <> botPage THEN
			IF fMagnification > 0 THEN
				r.bottom := (topPage + 1) * blocksPerPage * fMagnification
			ELSE
				r.bottom := ((topPage + 1) * blocksPerPage - 1) DIV
							(-fMagnification) + 1;

		fTables.DitherRect (doc,
							fChannel,
							fMagnification,
							r,
							gBuffer,
							doFlush);

		IF mapColors THEN
			DoMapBytes (gBuffer,
						rowBytes * ORD4 (r.bottom - r.top),
						fTransLUT);

		aPixMap.bounds := r;

		CopyBits (BitPtr (@aPixMap)^, thePort^.portBits, r, r, srcCopy, NIL)

		END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.Draw (area: Rect); OVERRIDE;

	BEGIN

	IF gDoingUpdate AND NOT gDoingScroll THEN
		BEGIN

		RectRgn (gTempRgn3, area);
		UnionRgn (gTempRgn3, fDelayedUpdateRgn, fDelayedUpdateRgn);

		gApplication.fIdlePriority := 1;
		EXIT (Draw)

		END;

	DrawNow (area, TRUE)

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.UpdateImageArea (area: Rect; highlight: BOOLEAN);

	VAR
		r: Rect;
		r2: Rect;
		rh: RgnHandle;

	BEGIN

	r := area;

	CvtImage2View (r.topLeft, kRoundDown);
	CvtImage2View (r.botRight, kRoundUp);

	fFrame.Focus;

	IF fWindow = NIL THEN
		rh := NIL
	ELSE
		rh := WindowPeek (fWindow.fWmgrWindow)^ . updateRgn;

	IF rh <> NIL THEN
		BEGIN

		r2 := rh^^.rgnBBox;

		GlobalToLocal (r2.topLeft);
		GlobalToLocal (r2.botRight);

		IF NOT EmptyRect (r2) THEN
			IF EmptyRect (r) THEN
				r := r2
			ELSE
				UnionRect (r, r2, r)

		END;

	fFrame.GetViewedRect (r2);

	IF SectRect (r, r2, r) THEN
		BEGIN

		IF highlight THEN
			DisplayOnScreen (r)
		ELSE
			BEGIN
			DrawNow (r, TRUE);
			DoDrawExtraFeedback (r)
			END;

		ValidRect (r)

		END

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION TImageView.CompHighlightAreas (VAR r, area: Rect): BOOLEAN;

	VAR
		viewedRect: Rect;

	BEGIN

	CompHighlightAreas := FALSE;

	r := TImageDocument (fDocument) . fSelectionRect;

	IF NOT EmptyRect (r) THEN
		BEGIN

		CvtImage2View (r.topLeft, kRoundDown);
		CvtImage2View (r.botRight, kRoundUp);

		area := r;

		fFrame.GetViewedRect (viewedRect);

		IF SectRect (viewedRect, area, area) THEN
			BEGIN

			RectRgn (gTempRgn3, area);

			IF fWindow <> NIL THEN
				SectRgn (gTempRgn3, fWindow.fWmgrWindow^.visRgn, gTempRgn3);

			DiffRgn (gTempRgn3, fDelayedUpdateRgn, gTempRgn3);

			area := gTempRgn3^^.rgnBBox;

			CompHighlightAreas := NOT EmptyRect (area)

			END

		END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.DoHighlightRect (fromHL, toHL: HLState);

	VAR
		r: Rect;
		area: Rect;
		band: Rect;
		clear: Rect;
		delayed: Rect;
		doc: TImageDocument;

	BEGIN

	IF CompHighlightAreas (r, area) THEN

		IF toHL = HLOn THEN
			BEGIN

			doc := TImageDocument (fDocument);

			PenMode (patCopy);
			PenSize (kMarqueeWidth, kMarqueeWidth);
			PenPat (gHLPattern [doc.fFlickerState]);

			FrameRect (r)

			END

		ELSE
			BEGIN

			delayed := fDelayedUpdateRgn^^.rgnBBox;

			band		:= r;
			band.bottom := Min (r.top + kMarqueeWidth, r.bottom);
			r.top		:= band.bottom;

			IF SectRect (band, delayed, clear) THEN EraseRect (clear);
			IF SectRect (band, area   , band ) THEN DrawNow   (band, TRUE);

			band	   := r;
			band.right := Min (r.left + kMarqueeWidth, r.right);
			r.left	   := band.right;

			IF SectRect (band, delayed, clear) THEN EraseRect (clear);
			IF SectRect (band, area   , band ) THEN DrawNow   (band, TRUE);

			band	  := r;
			band.left := Max (r.right - kMarqueeWidth, r.left);
			r.right   := band.left;

			IF SectRect (band, delayed, clear) THEN EraseRect (clear);
			IF SectRect (band, area   , band ) THEN DrawNow   (band, TRUE);

			band	 := r;
			band.top := Max (band.bottom - kMarqueeWidth, r.top);

			IF SectRect (band, delayed, clear) THEN EraseRect (clear);
			IF SectRect (band, area   , band ) THEN DrawNow   (band, TRUE);

			DoDrawExtraFeedback (fExtentRect)

			END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE DrawMaskOutline (map: BitMap;
						   maskData: TVMArray;
						   maskRect: Rect;
						   mag: INTEGER);

	VAR
		r: Rect;
		r2: Rect;
		fi: FailInfo;
		row: INTEGER;
		prevPtr: Ptr;
		thisPtr: Ptr;
		nextPtr: Ptr;
		savePtr: Ptr;
		width: INTEGER;
		buffer1: Handle;
		buffer2: Handle;
		buffer3: Handle;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (buffer1);
		FreeLargeHandle (buffer2);
		FreeLargeHandle (buffer3);
		maskData.Flush
		END;

	PROCEDURE MoveRow (dstPtr: Ptr; row: INTEGER);

		VAR
			srcPtr: Ptr;
			iRow: INTEGER;
			iCol: INTEGER;

		BEGIN

		dstPtr := Ptr (ORD4 (dstPtr) + r.left - r2.left);

		IF (row < r.top) OR (row >= r.bottom) THEN
			DoSetBytes (dstPtr, r.right - r.left, 0)

		ELSE
			BEGIN

			IF mag >= 1 THEN
				BEGIN
				iRow := row DIV mag;
				iCol := r.left DIV mag
				END
			ELSE
				BEGIN
				iRow := row * (-mag);
				iCol := r.left * (-mag)
				END;

			iRow := iRow - maskRect.top;
			iCol := iCol - maskRect.left;

			srcPtr := maskData.NeedPtr (iRow, iRow, FALSE);
			srcPtr := Ptr (ORD4 (srcPtr) + iCol);

			IF mag > 1 THEN
				MoveMagnifData (srcPtr, dstPtr, r.right - r.left,
								mag, r.left MOD mag)

			ELSE IF mag < 1 THEN
				MoveReductData (srcPtr, dstPtr, r.right - r.left, -mag)

			ELSE
				BlockMove (srcPtr, dstPtr, r.right - r.left);

			maskData.DoneWithPtr

			END

		END;

	BEGIN

	DoSetBytes (map.baseAddr, map.rowBytes * ORD4 (map.bounds.bottom -
												   map.bounds.top), 0);

	r := maskRect;

	IF mag > 1 THEN
		BEGIN
		r.top	 := r.top	 * mag;
		r.left	 := r.left	 * mag;
		r.bottom := r.bottom * mag;
		r.right  := r.right  * mag
		END

	ELSE IF mag < 1 THEN
		BEGIN
		r.top	 := (r.top	  - mag - 1) DIV (-mag);
		r.left	 := (r.left   - mag - 1) DIV (-mag);
		r.bottom := (r.bottom - mag - 1) DIV (-mag);
		r.right  := (r.right  - mag - 1) DIV (-mag)
		END;

	r2 := map.bounds;

	InsetRect (r2, -1, -1);

	IF SectRect (r2, r, r) THEN
		BEGIN

		buffer1 := NIL;
		buffer2 := NIL;
		buffer3 := NIL;

		width := r2.right - r2.left;

		CatchFailures (fi, CleanUp);

		buffer1 := NewLargeHandle (width);
		buffer2 := NewLargeHandle (width);
		buffer3 := NewLargeHandle (width);

		HLock (buffer1);
		HLock (buffer2);
		HLock (buffer3);

		DoSetBytes (buffer1^, width, 0);
		DoSetBytes (buffer2^, width, 0);
		DoSetBytes (buffer3^, width, 0);

		prevPtr := buffer1^;
		thisPtr := buffer2^;
		nextPtr := buffer3^;

		MoveRow (thisPtr, r2.top);
		MoveRow (nextPtr, r2.top + 1);

		FOR row := r2.top + 1 TO r2.bottom - 2 DO
			BEGIN

			savePtr := prevPtr;
			prevPtr := thisPtr;
			thisPtr := nextPtr;
			nextPtr := savePtr;

			IF (mag > 1) & ((row + 1) MOD mag <> 0) THEN
				BlockMove (thisPtr, nextPtr, width)
			ELSE
				MoveRow (nextPtr, row + 1);

			DrawOutlineRow (prevPtr,
							thisPtr,
							nextPtr,
							Ptr (ORD4 (map.baseAddr) +
								 ORD4 (row - map.bounds.top) *
								 map.rowBytes),
							width - 2)

			END;

		Success (fi);

		CleanUp (0, 0)

		END

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION IsAreaBlank (map: BitMap; r: Rect): BOOLEAN;

	VAR
		dataPtr: Ptr;
		left: INTEGER;
		right: INTEGER;

	BEGIN

	left  := BSR (r.left  - map.bounds.left    , 3);
	right := BSR (r.right - map.bounds.left + 7, 3);

	dataPtr := Ptr (ORD4 (map.baseAddr) +
					ORD4 (r.top - map.bounds.top) * map.rowBytes +
					left);

	IsAreaBlank := IsRectZero (dataPtr,
							   map.rowBytes,
							   r.bottom - r.top,
							   right - left)

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE DrawPatternedMap (map: BitMap;
							area: Rect;
							pat: Pattern;
							clear: BOOLEAN);

	VAR
		r: Rect;
		j: INTEGER;
		map2: BitMap;
		band: INTEGER;
		mousePt: Point;
		mouseRect: Rect;
		bandSize: INTEGER;

	BEGIN

	map2.bounds   := area;
	map2.rowBytes := BSL (BSR (area.right - area.left + 15, 4), 1);
	map2.baseAddr := gBuffer;

	bandSize := Min (16,
				Min (32768 DIV map2.rowBytes,
					 area.bottom - area.top));

	FOR band := 0 TO (area.bottom - area.top - 1) DIV bandSize DO
		BEGIN

		map2.bounds.top    := area.top + band * bandSize;
		map2.bounds.bottom := Min (map2.bounds.top + bandSize,
								   area.bottom);

		CopyBits (map, map2, map2.bounds, map2.bounds, srcCopy, NIL);

		IF clear THEN
			CopyBits (map2, thePort^.portBits,
					  map2.bounds, map2.bounds, srcBic, NIL);

		DoPatternMap (map2, pat);

		GetMouse   (mousePt);
		SetRect    (mouseRect, -16, -16, 64 {???}, 16);
		OffsetRect (mouseRect, mousePt.h, mousePt.v);

		FOR j := 1 TO 5 DO
			BEGIN

			r := map2.bounds;

				CASE j OF

				1:	r.bottom := mouseRect.top;

				2:	BEGIN
					r.right  := mouseRect.left;
					r.top	 := mouseRect.top;
					r.bottom := mouseRect.bottom
					END;

				3:	r := mouseRect;

				4:	BEGIN
					r.left	 := mouseRect.right;
					r.top	 := mouseRect.top;
					r.bottom := mouseRect.bottom
					END;

				5:	r.top	 := mouseRect.bottom

				END;

			IF SectRect (map2.bounds, r, r) THEN
				IF (j <> 3) | NOT IsAreaBlank (map2, r) THEN
					CopyBits (map2, thePort^.portBits, r, r, srcXor, NIL)

			END

		END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.DoHighlightMask (fromHL, toHL: HLState);

	VAR
		r: Rect;
		err: OSErr;
		area: Rect;
		map: BitMap;
		pat: Pattern;
		size: LONGINT;
		width: INTEGER;
		height: INTEGER;
		doc: TImageDocument;

	BEGIN

	IF CompHighlightAreas (r, area) THEN

		IF toHL = HLOn THEN
			BEGIN

			map.bounds := area;

			width  := area.right - area.left;
			height := area.bottom - area.top;

			map.rowBytes := BSL (BSR (width + 15, 4), 1);

			size := map.rowBytes * ORD4 (height);

			IF GetHandleSize (gOutlineCache.data) < size THEN
				EXIT (DoHighlightMask);

			HLock (gOutlineCache.data);

			map.baseAddr := gOutlineCache.data^;

			doc := TImageDocument (fDocument);

			IF (gOutlineCache.doc <> doc) OR
			   (gOutlineCache.mag <> fMagnification) OR
				NOT EqualRect (gOutlineCache.area, area) THEN
				BEGIN

				gOutlineCache.doc  := doc;
				gOutlineCache.mag  := fMagnification;
				gOutlineCache.area := map.bounds;

				DrawMaskOutline (map,
								 doc.fSelectionMask,
								 doc.fSelectionRect,
								 fMagnification)

				END;

			IF fromHL = HLOff THEN
				pat := gHLPattern [doc.fFlickerState]
			ELSE
				pat := gHLPatternDelta [doc.fFlickerState];

			DrawPatternedMap (map, map.bounds, pat, fromHL = HLOff);

			HUnlock (gOutlineCache.data);

			END

		ELSE
			BEGIN
			DrawNow (area, TRUE);
			DoDrawExtraFeedback (area)
			END

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION TImageView.CompCornerRect (pt: Point; VAR r: Rect): BOOLEAN;

	CONST
		kCornerRadius = 3;

	VAR
		bounds: Rect;

	BEGIN

	SetRect (bounds, 0, 0, TImageDocument (fDocument) . fCols,
						   TImageDocument (fDocument) . fRows);

	IF (pt.v >= 0) AND (pt.v <= bounds.bottom) AND
	   (pt.h >= 0) AND (pt.h <= bounds.right ) THEN
		BEGIN

		CvtImage2View (bounds.botRight, kRoundUp);

		r.topLeft := pt;

		CvtImage2View (r.topLeft, kRoundUp);

		r.botRight := r.topLeft;

		InsetRect (r, -kCornerRadius, -kCornerRadius);

		SlideRectInto (r, bounds)

		END

	ELSE
		r := gZeroRect;

	CompCornerRect := NOT EmptyRect (r)

	END;

{*****************************************************************************}

{$S ARes2}

FUNCTION TImageView.FindCorner (corners: TCornerList; pt: Point): INTEGER;

	CONST
		kMaxSlop = 2;

	VAR
		r: Rect;
		j: INTEGER;
		dist: INTEGER;
		best: INTEGER;

	BEGIN

	best := kMaxSlop + 1;

	FindCorner := -1;

	FOR j := 0 TO 3 DO
		IF CompCornerRect (corners [j], r) THEN
			BEGIN

			dist := Max (Max (r.top - pt.v, pt.v - r.bottom),
						 Max (r.left - pt.h, pt.h - r.right));

			IF dist < best THEN
				BEGIN
				best := dist;
				FindCorner := j
				END

			END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.DoHighlightCorner (pt: Point; turnOn: BOOLEAN);

	VAR
		r: Rect;
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		EXIT (DoHighlightCorner)
		END;

	BEGIN

	IF CompCornerRect (pt, r) THEN

		IF turnOn THEN
			BEGIN
			PenNormal;
			FrameRect (r);
			InsetRect (r, 1, 1);
			IF NOT EmptyRect (r) THEN EraseRect (r)
			END

		ELSE
			BEGIN
			CatchFailures (fi, CleanUp);
			DrawNow (r, TRUE);
			DoDrawExtraFeedback (r);
			Success (fi)
			END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.DoHighlightCorners (turnOn: BOOLEAN);

	VAR
		j: INTEGER;
		doc: TImageDocument;

	BEGIN

	doc := TImageDocument (fDocument);

	FOR j := 0 TO 3 DO
		DoHighlightCorner (doc.fEffectCorners [j], turnOn)

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.DoHighlightSelection (fromHL, toHL: HLState); OVERRIDE;

	VAR
		doc: TImageDocument;

	BEGIN

	doc := TImageDocument (fDocument);

	IF NOT fObscured THEN
		IF NOT EmptyRect (doc.fSelectionRect) THEN
			IF (toHL = HLOff) OR EmptyRgn (fDelayedUpdateRgn) THEN
				BEGIN

				fFrame.Focus;

				IF (doc.fEffectMode <> 0) AND
				   (doc.fEffectChannel = fChannel) AND
				   (fromHL <> toHL) THEN
					DoHighlightCorners (toHL = HLOn);

				IF doc.fSelectionMask = NIL THEN
					DoHighlightRect (fromHL, toHL)
				ELSE
					DoHighlightMask (fromHL, toHL)

				END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.UpdateSelection;

	VAR
		doc: TImageDocument;

	BEGIN

	doc := TImageDocument (fDocument);

	IF TickCount >= doc.fFlickerTime THEN
		IF gApplication.fIdlePriority = 0 THEN
			BEGIN

			doc.fFlickerState := (doc.fFlickerState + 1) MOD kHLPatterns;
			doc.fFlickerTime  := TickCount + kHLDelay;

			IF NOT fObscured THEN
				DoHighlightSelection (HLOn, HLOn)

			ELSE IF TickCount >= fObscureTime THEN
				BEGIN
				fObscured := FALSE;
				DoHighlightSelection (HLOff, HLOn)
				END

			END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.ObscureSelection (delay: INTEGER);

	BEGIN

	IF NOT fObscured THEN
		BEGIN
		DoHighlightSelection (HLOn, HLOff);
		fObscured := TRUE
		END;

	IF delay = -1 THEN
		fObscureTime := $7FFFFFFF
	ELSE
		fObscureTime := TickCount + delay

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.DoDrawStatus (r: Rect);

	VAR
		s: Str255;
		size: LONGINT;
		doc: TImageDocument;

	BEGIN

	doc := TImageDocument (fDocument);

	size := BSR (doc.fChannels * ORD4 (doc.fRows) *
				 doc.fData [0] . fLogicalSize + 1023, 10);

	NumToString (size, s);

	INSERT ('K', s, LENGTH (s) + 1);

	TextFont (gGeneva);
	TextSize (9);

	TextBox (@s[1], LENGTH (s), r, teJustCenter);

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.DrawStatus;

	VAR
		r: Rect;

	BEGIN

	fFrame.FocusOnContainer;

	r := TImageFrame (fFrame) . fStatusRect;

	IF RectIsVisible (r) THEN
		DoDrawStatus (r)

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.InvalRulers;

	BEGIN

	IF fRulers THEN
		BEGIN
		TImageFrame (fFrame) . fRuler [h] . ForceRedraw;
		TImageFrame (fFrame) . fRuler [v] . ForceRedraw
		END

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TImageView.TrackRulers;

	VAR
		vr: Rect;
		pt: Point;
		local: Point;
		limits: Rect;
		offset: INTEGER;
		view: TRulerView;
		frame: TRulerFrame;

	BEGIN

	IF gTarget <> SELF THEN EXIT (TrackRulers);

	{$IFC qBarneyscan}

	IF CoordsVisible THEN
		BEGIN

		fFrame.Focus;

		GetMouse (pt);

		fFrame.GetViewedRect (vr);

		IF PtInRect (pt, vr) THEN
			BEGIN
			CvtView2Image (pt);
			pt.h := Min (pt.h, TImageDocument (fDocument) . fCols - 1);
			pt.v := Min (pt.v, TImageDocument (fDocument) . fRows - 1);
			UpdateCoords (SELF, pt)
			END
		ELSE
			UpdateCoords (NIL, Point (0))

		END;

	{$ENDC}

	IF fRulers THEN
		BEGIN

		fFrame.Focus;

		limits := fFrame.fContentRect;

		OffsetRect (limits, fFrame.fRelOrigin.h,
							fFrame.fRelOrigin.v);

		GetMouse (pt);

		IF PtInRect (pt, limits) THEN
			BEGIN

			LocalToGlobal (pt);

			frame := TImageFrame (fFrame) . fRuler [h];
			view  := TRulerView (frame.fView);

			frame.Focus;

			local := pt;
			GlobalToLocal (local);

			view.FindOrigin;

			offset := local.h - view.fOrigin;

			IF offset <> view.fMarkOffset THEN
				BEGIN
				view.DoHighlightSelection (hlOn, hlOff);
				view.fMarkOffset := offset;
				view.DoHighlightSelection (hlOff, hlOn)
				END;

			frame := TImageFrame (fFrame) . fRuler [v];
			view  := TRulerView (frame.fView);

			frame.Focus;

			local := pt;
			GlobalToLocal (local);

			view.FindOrigin;

			offset := local.v - view.fOrigin;

			IF offset <> view.fMarkOffset THEN
				BEGIN
				view.DoHighlightSelection (hlOn, hlOff);
				view.fMarkOffset := offset;
				view.DoHighlightSelection (hlOff, hlOn)
				END

			END

		ELSE
			BEGIN

			frame := TImageFrame (fFrame) . fRuler [h];
			view  := TRulerView (frame.fView);

			IF view.fMarkOffset <> -kMaxCoord THEN
				BEGIN
				frame.Focus;
				view.DoHighlightSelection (hlOn, hlOff);
				view.fMarkOffset := -kMaxCoord
				END;

			frame := TImageFrame (fFrame) . fRuler [v];
			view  := TRulerView (frame.fView);

			IF view.fMarkOffset <> -kMaxCoord THEN
				BEGIN
				frame.Focus;
				view.DoHighlightSelection (hlOn, hlOff);
				view.fMarkOffset := -kMaxCoord
				END

			END;

		fFrame.Focus

		END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.GetGlobalArea (VAR area: Rect);

	BEGIN

	fWindow.Focus;

	area := fFrame.fContentRect;

	LocalToGlobal (area.topLeft);
	LocalToGlobal (area.botRight)

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.ResetGlobalArea (area: Rect);

	TYPE
		WStatePtr = ^WStateData;
		WStateHandle = ^WStatePtr;

	VAR
		oldArea: Rect;
		theRect: Rect;
		theSize: Point;
		visible: BOOLEAN;
		stateData: WStateHandle;

	BEGIN

	GetGlobalArea (oldArea);

	IF NOT EqualRect (area, oldArea) THEN
		BEGIN

		visible := WindowPeek (fWindow.fWmgrWindow)^ . visible;

		IF visible THEN ShowHide (fWindow.fWmgrWindow, FALSE);

		fWindow.Focus;

		theRect := fWindow.fWmgrWindow^.portRect;

		LocalToGlobal (theRect.topLeft);
		LocalToGlobal (theRect.botRight);

		theRect.top    := theRect.top	 - oldArea.top	  + area.top;
		theRect.left   := theRect.left	 - oldArea.left   + area.left;
		theRect.bottom := theRect.bottom - oldArea.bottom + area.bottom;
		theRect.right  := theRect.right  - oldArea.right  + area.right;

		theSize.h := theRect.right - theRect.left;
		theSize.v := theRect.bottom - theRect.top;

		MoveWindow (fWindow.fWmgrWindow,
					theRect.left, theRect.top, FALSE);

		fWindow.Resize (theSize, TRUE);

		stateData := WStateHandle
				(WindowPeek (fWindow.fWmgrWindow)^.dataHandle);

		stateData^^.userState := theRect;

		IF visible THEN ShowHide (fWindow.fWmgrWindow, TRUE)

		END;

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.GetZoomLimits (VAR limits: Rect);

	VAR
		r: Rect;
		rr: Rect;
		gdh: GDHandle;
		best: LONGINT;

	FUNCTION Overlap (r1, r2: Rect): LONGINT;

		VAR
			r3: Rect;

		BEGIN
		IF SectRect (r1, r2, r3) THEN
			Overlap := ORD4 (r3.bottom - r3.top) * (r3.right - r3.left)
		ELSE
			Overlap := 0
		END;

	BEGIN

	limits := screenBits.bounds;

	IF (gConfiguration.hasColorToolbox) AND (fWindow <> NIL) THEN
		BEGIN

		SetPort (fWindow.fWmgrWindow);

		r := fWindow.fWmgrWindow^.portRect;

		LocalToGlobal (r.topLeft);
		LocalToGlobal (r.botRight);

		best := Overlap (r, limits);

		gdh := GetDeviceList;

		WHILE gdh <> NIL DO
			BEGIN
			rr := gdh^^.gdRect;
			IF Overlap (r, rr) > best THEN
				BEGIN
				limits := rr;
				best := Overlap (r, rr)
				END;
			gdh := GetNextDevice (gdh)
			END

		END;

	IF LONGINT (limits.topLeft) = 0 THEN
		BEGIN
		limits.top	:= gMBarHeight;
		limits.left := 59
		END;

	limits.top	  := limits.top    + 21;
	limits.left   := limits.left   +  3;
	limits.bottom := limits.bottom -  4;
	limits.right  := limits.right  -  4

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.GetZoomSize (VAR pt: Point);

	VAR
		limits: Rect;

	BEGIN

		CASE fScreenMode OF

		0:	BEGIN

			GetZoomLimits (limits);

			pt.h := limits.right - limits.left - (kStdSzSBar - 1);
			pt.v := limits.bottom - limits.top - (kStdSzSBar - 1);

			IF fRulers THEN
				BEGIN
				pt.h := pt.h - kRulerWidth - 1;
				pt.v := pt.v - kRulerWidth - 1
				END

			END;

		1:	BEGIN
			pt := screenBits.bounds.botRight;
			pt.v := pt.v - gMBarheight
			END;

		2:	pt := screenBits.bounds.botRight

		END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE TImageView.AdjustZoomSize;

{ Adjusts the zoom limits for the view's window. }

	CONST
		kMinWindWidth  = kStdSzMinus1SBar + 128;
		kMinWindHeight = kStdSzMinus1SBar +  64;
		kMinZoomWidth  = kMinWindWidth;
		kMinZoomHeight = kMinWindHeight;

	TYPE
		WStatePtr = ^WStateData;
		WStateHandle = ^WStatePtr;

	VAR
		area: Rect;
		limits: Rect;
		theRect: Rect;
		theSize: Point;
		stateData: WStateHandle;

	BEGIN

	fWindow.fResizeLimits.left	 := kMinWindWidth;
	fWindow.fResizeLimits.top	 := kMinWindHeight;
	fWindow.fResizeLimits.right  := kMaxCoord;
	fWindow.fResizeLimits.bottom := kMaxCoord;

	theRect := fWindow.fWmgrWindow^.portRect;

	GetGlobalArea (area);

	theSize.h := fExtentRect.right +
				 (theRect.right - theRect.left) -
				 (area.right - area.left);

	theSize.v := fExtentRect.bottom +
				 (theRect.bottom - theRect.top) -
				 (area.bottom - area.top);

	GetZoomLimits (limits);

	theSize.h := Min (Max (theSize.h, kMinZoomWidth),
						   limits.right - limits.left);

	theSize.v := Min (Max (theSize.v, kMinZoomHeight),
						   limits.bottom - limits.top);

	theRect := limits;

	theRect.right  := theRect.left + theSize.h;
	theRect.bottom := theRect.top  + theSize.v;

	stateData := WStateHandle (WindowPeek (fWindow.fWmgrWindow)^.dataHandle);

	stateData^^.stdState := theRect;

	fWindow.Focus;

	stateData^^.userState := fWindow.fWmgrWindow^.portRect;

	LocalToGlobal (stateData^^.userState.topLeft);
	LocalToGlobal (stateData^^.userState.botRight)

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE SlideRectInto (VAR inner: Rect; outer: Rect);

	BEGIN

	IF inner.left < outer.left THEN
		OffsetRect (inner, outer.left - inner.left, 0);

	IF inner.top < outer.top THEN
		OffsetRect (inner, 0, outer.top - inner.top);

	IF inner.right > outer.right THEN
		OffsetRect (inner, outer.right - inner.right, 0);

	IF inner.bottom > outer.bottom THEN
		OffsetRect (inner, 0, outer.bottom - inner.bottom);

	IF inner.left < outer.left THEN
		inner.left := outer.left;

	IF inner.top < outer.top THEN
		inner.top := outer.top

	END;

{*****************************************************************************}

{$S AOpen}

PROCEDURE TImageView.SetToZoomSize;

{ Adjusts the size of the view's window to its zoom value. }

	TYPE
		WStatePtr = ^WStateData;
		WStateHandle = ^WStatePtr;

	VAR
		area: Rect;
		limits: Rect;
		oldRect: Rect;
		newRect: Rect;
		zoomRect: Rect;
		stateData: WStateHandle;

	BEGIN

	GetGlobalArea (area);

	fWindow.Focus;

	oldRect := fWindow.fWmgrWindow^.portRect;

	LocalToGlobal (oldRect.topLeft);
	LocalToGlobal (oldRect.botRight);

	newRect := oldRect;

	stateData := WStateHandle (WindowPeek (fWindow.fWmgrWindow)^.dataHandle);

	zoomRect := stateData^^.stdState;

	newRect.right  := newRect.left + (zoomRect.right - zoomRect.left);
	newRect.bottom := newRect.top  + (zoomRect.bottom - zoomRect.top);

	GetZoomLimits (limits);

	SlideRectInto (newRect, limits);

	newRect.top    := newRect.top	 + area.top    - oldRect.top;
	newRect.left   := newRect.left	 + area.left   - oldRect.left;
	newRect.bottom := newRect.bottom + area.bottom - oldRect.bottom;
	newRect.right  := newRect.right  + area.right  - oldRect.right;

	ResetGlobalArea (newRect)

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE HideMenuBar;

	TYPE
		PRgnHandle = ^RgnHandle;

	VAR
		r: Rect;
		wPort: GrafPtr;
		rgn1: RgnHandle;
		rgn2: RgnHandle;
		rgn3: RgnHandle;
		temp: PRgnHandle;

	BEGIN

	PInteger (MBarHeight)^ := 0;

	gSaveGrayRgn := PRgnHandle (GrayRgn)^;

	rgn1 := NewRgn;
	RectRgn (rgn1, screenBits.bounds);

	rgn2 := NewRgn;
	UnionRgn (rgn1, gSaveGrayRgn, rgn2);

	temp  := PRgnHandle (GrayRgn);
	temp^ := rgn2;

	rgn2 := NewRgn;
	RectRgn (rgn2, screenBits.bounds);

	PaintOne (NIL, rgn2);

	GetWMgrPort (wPort);
	SetPort (wPort);

	ClipRect (screenBits.bounds);

	r		 := screenBits.bounds;
	r.bottom := r.top + gMBarHeight;

	RectRgn (rgn2, r);

	rgn3 := NewRgn;
	DiffRgn (rgn1, gSaveGrayRgn, rgn3);
	UnionRgn (rgn3, rgn2, rgn3);

	PaintOne	(WindowPeek (FrontVisible), rgn3);
	PaintBehind (WindowPeek (FrontVisible), rgn3);

	CalcVis 	  (WindowPeek (FrontVisible));
	CalcVisBehind (WindowPeek (FrontVisible), rgn3);

	DisposeRgn (rgn1);
	DisposeRgn (rgn2);
	DisposeRgn (rgn3)

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE ShowMenuBar;

	TYPE
		PRgnHandle = ^RgnHandle;

	VAR
		r: Rect;
		wPort: GrafPtr;
		rgn1: RgnHandle;
		rgn2: RgnHandle;

	BEGIN

	PInteger (MBarHeight)^ := gMBarHeight;

	DisposeRgn (PRgnHandle (GrayRgn)^);

	PRgnHandle (GrayRgn)^ := gSaveGrayRgn;

	r		 := screenBits.bounds;
	r.bottom := r.top + gMBarHeight;

	rgn1 := NewRgn;
	RectRgn (rgn1, r);

	CalcVis 	  (WindowPeek (FrontVisible));
	CalcVisBehind (WindowPeek (FrontVisible), rgn1);

	RectRgn (rgn1, screenBits.bounds);

	rgn2 := NewRgn;
	DiffRgn (rgn1, gSaveGrayRgn, rgn2);

	CalcVisBehind (WindowPeek (FrontVisible), rgn2);

	GetWMgrPort (wPort);
	SetPort (wPort);

	ClipRect (screenBits.bounds);

	FillRgn (rgn2, black);

	DisposeRgn (rgn1);
	DisposeRgn (rgn2);

	HiliteMenu (0);

	DrawMenuBar

	END;

{*****************************************************************************}

{$S ASelCommand}

PROCEDURE TImageView.SetScreenMode (mode: INTEGER);

	VAR
		area: Rect;

	BEGIN

	ShowHide (fWindow.fWmgrWindow, FALSE);

	IF mode = 2 THEN
		HideMenuBar;

	IF mode = 0 THEN
		SetToZoomSize
	ELSE
		BEGIN
		area := screenBits.bounds;
		IF mode = 1 THEN
			area.top := area.top + gMBarHeight;
		ResetGlobalArea (area)
		END;

	IF fScreenMode = 2 THEN
		ShowMenuBar;

	ShowHide (fWindow.fWmgrWindow, TRUE);

	fScreenMode := mode

	END;

{*****************************************************************************}

{$S ASelCommand}

PROCEDURE TImageView.ShowRulers (rulers: BOOLEAN);

	VAR
		r: Rect;

	BEGIN

	IF (fRulers <> rulers) OR (fScreenMode <> 0) THEN
		BEGIN

		fRulers := rulers;

		IF fScreenMode <> 0 THEN
			BEGIN
			SetScreenMode (0);
			gToolsView.MarkMode (0)
			END;

		TImageFrame (fFrame) . PositionRulers;

		fFrame.FocusOnContainer;

		r := fWindow.fContentRect;
		EraseRect (r);
		InvalRect (r);

		AdjustZoomSize;
		SetToZoomSize

		END;

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE TImageView.Activate (wasActive, beActive: BOOLEAN); OVERRIDE;

	BEGIN

	IF wasActive <> beActive THEN
		BEGIN

		IF fScreenMode = 2 THEN
			IF beActive THEN
				HideMenuBar
			ELSE
				ShowMenuBar;

		IF beActive THEN
			gToolsView.MarkMode (fScreenMode)
		ELSE
			gToolsView.MarkMode (-1);

		IF gConfiguration.hasColorToolBox THEN
			InvalidateGhostColors

		END;

	INHERITED Activate (wasActive, beActive)

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE TImageView.UpdateWindowTitle;

	VAR
		s: Str255;
		title: Str255;
		doc: TImageDocument;

	BEGIN

	doc := TImageDocument (fDocument);

	title := doc.fTitle;

	INSERT ('  (', title, LENGTH (title) + 1);

	IF (doc.fChannels > 1) AND (fChannel <> kRGBChannels) THEN
		BEGIN
		TImageDocument (fDocument) . ChannelName (fChannel, s);
		INSERT (s	, title, LENGTH (title) + 1);
		INSERT (', ', title, LENGTH (title) + 1)
		END;

	NumToString (ABS (fMagnification), s);

	IF fMagnification >= 1 THEN
		BEGIN
		INSERT (s	 , title, LENGTH (title) + 1);
		INSERT (':1)', title, LENGTH (title) + 1)
		END
	ELSE
		BEGIN
		INSERT ('1:', title, LENGTH (title) + 1);
		INSERT (s	, title, LENGTH (title) + 1);
		INSERT (')' , title, LENGTH (title) + 1)
		END;

	fWindow.fPreDocName := 1;
	fWindow.fConstTitle := LENGTH (title) - LENGTH (doc.fTitle);

	GetWTitle (fWindow.fWmgrWindow, s);

	IF title <> s THEN
		SetWTitle (fWindow.fWmgrWindow, title)

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE TImageView.DoSetupMenus; OVERRIDE;

	VAR
		r: Rect;
		s: Str255;
		item: INTEGER;
		count: INTEGER;
		menu: MenuHandle;
		channel: INTEGER;
		haveAlpha: BOOLEAN;
		doc: TImageDocument;
		wholeImage: BOOLEAN;
		isFloating: BOOLEAN;
		enableMerge: BOOLEAN;
		haveSelection: BOOLEAN;

	PROCEDURE TestMerge (otherDoc: TImageDocument);
		BEGIN
		IF (otherDoc <> doc) &
		   (otherDoc.fMode = MonochromeMode) &
		   (otherDoc.fCols = doc.fCols) &
		   (otherDoc.fRows = doc.fRows) THEN enableMerge := TRUE
		END;

	BEGIN

	INHERITED DoSetupMenus;
	
	{$IFC qDemo}
	Enable (cPrint, FALSE);
	{$ENDC}

	doc := TImageDocument (fDocument);

	r := doc.fSelectionRect;

	haveSelection := NOT EmptyRect (r);

	wholeImage := NOT haveSelection OR
				  (r.top	= 0    ) AND
				  (r.left	= 0    ) AND
				  (r.bottom = doc.fRows) AND
				  (r.right	= doc.fCols) AND
				  (doc.fSelectionMask = NIL);

	isFloating := doc.fSelectionFloating AND
				  NOT doc.fExactFloat AND
				  (doc.fFloatChannel = fChannel);

	IF doc.fChannels > 1 THEN
		BEGIN

		Enable (cChannel, TRUE);

		menu := GetResMenu (kChannelMenu);
		item := CountMItems (menu);

		WHILE item > 0 DO
			BEGIN
			DelMenuItem (menu, item);
			item := item - 1
			END;

		FOR channel := kRGBChannels TO doc.fChannels - 1 DO
			IF (doc.fMode = RGBColorMode) OR (channel >= 0) THEN
				BEGIN

				item := item + 1;

				doc.ChannelName (channel, s);

				IF channel < 9 THEN
					BEGIN
					INSERT ('/0', s, LENGTH (s) + 1);
					s [LENGTH (s)] := CHR (ORD ('1') + channel)
					END;

				AppendMenu (menu, s);

				EnableCheck (-(256 * kChannelMenu + item),
							 TRUE,
							 channel = fChannel)

				END

		END;

	IF doc.fMode = IndexedColorMode THEN
		BEGIN

		Enable (cColorTable, TRUE);

		Enable (cEditTable, TRUE);

		menu := GetResMenu (kTableMenu);

		count := CountMItems (menu);

		FOR item := gTableFixed + 1 TO count DO
			BEGIN
			EnableItem (menu, item);
			CheckItem (menu, item, item = doc.fTableItem)
			END

		END;

	Enable (cZoomIn, fMagnification < MaxMagnification);
	Enable (cZoomOut, fMagnification > MinMagnification);
	Enable (cScaleFactor, TRUE);

	SetWording (cToggleRulers, cShowRulers, cHideRulers,
				NOT fRulers OR (fScreenMode <> 0));

	Enable (cToggleRulers, TRUE);

	Enable (cSelectAll, TRUE);
	Enable (cSelectNone, haveSelection);
	Enable (cSelectInverse, NOT wholeImage);
	Enable (cSelectFringe, NOT wholeImage);

	SetWording (cHideEdges, cShowEdgesWording, cHideEdgesWording,
				haveSelection AND fObscured AND (fObscureTime = $7FFFFFFF));

	Enable (cHideEdges, haveSelection);

	Enable (cMakeAlpha, haveSelection AND (doc.fMode <> HalftoneMode)
									  AND (doc.fMode <> IndexedColorMode)
									  AND (doc.fChannels < kMaxChannels));

		CASE doc.fMode OF

		MultichannelMode:
			haveAlpha := TRUE;

		RGBColorMode,
		SeparationsHSL,
		SeparationsHSB:
			haveAlpha := doc.fChannels > 3;

		SeparationsCMYK:
			haveAlpha := doc.fChannels > 4;

		OTHERWISE
			haveAlpha := FALSE

		END;

	Enable (cSelectAlpha, haveAlpha);

	IF NOT wholeImage AND (doc.fDepth = 8) THEN
		BEGIN
		Enable (cSelectSimilar, TRUE);
		Enable (cGrow, TRUE)
		END;

	Enable (cFeather, NOT wholeImage AND (doc.fMode <> HalftoneMode)
									 AND (doc.fMode <> IndexedColorMode));

	IF (doc.fDepth = 8) AND haveSelection THEN
		BEGIN
		Enable (cCut, TRUE);
		Enable (cClear, TRUE);
		Enable (cOptionFill, TRUE)
		END;

	Enable (cCopy, haveSelection);

	IF doc.fDepth = 8 THEN
		BEGIN

		CanPaste (kClipDataType);

		IF gClipView <> NIL THEN
			IF gClipView.ContainsClipType (kClipDataType) THEN
				BEGIN
				Enable (cPasteInto, NOT wholeImage);
				Enable (cPasteBehind, NOT wholeImage)
				END

		END;

	Enable (cCrop, haveSelection AND
				   NOT wholeImage AND
				   (doc.fSelectionMask = NIL));

	IF haveSelection AND (doc.fSelectionMask = NIL) AND (doc.fDepth = 8) THEN
		BEGIN
		Enable (cDefineBrush, TRUE);
		Enable (cDefinePattern, TRUE)
		END;

	Enable (cPasteControls, isFloating);

	SetWording (cHalftone, cHalftoneOptWording, cHalftoneWording,
				doc.fMode = MonochromeMode);

	EnableCheck (cHalftone,
				 doc.fMode IN [HalftoneMode, MonochromeMode],
				 doc.fMode = HalftoneMode);

	SetWording (cMonochrome, cMonochromeOptWording, cMonochromeWording,
				(doc.fMode = HalftoneMode));

	EnableCheck (cMonochrome, TRUE, doc.fMode = MonochromeMode);

	SetWording (cIndexedColor, cIndexedColorOptWording, cIndexedColorWording,
				doc.fMode = RGBColorMode);

	EnableCheck (cIndexedColor,
				 doc.fMode IN [MonochromeMode, IndexedColorMode, RGBColorMode],
				 doc.fMode = IndexedColorMode);

	EnableCheck (cRGBColor,
				 (doc.fDepth = 8) AND (doc.fChannels <> 2),
				 doc.fMode = RGBColorMode);

	EnableCheck (cSeparationsCMYK,
				 (doc.fMode IN [IndexedColorMode, SeparationsCMYK]) OR
				 (doc.fMode = RGBColorMode) AND
					(doc.fChannels < kMaxChannels) OR
				 (doc.fMode = MultichannelMode) AND
					(doc.fChannels >= 4),
				 doc.fMode = SeparationsCMYK);

	EnableCheck (cSeparationsHSL,
				 (doc.fMode IN [IndexedColorMode,
								RGBColorMode,
								SeparationsHSL]) OR
				 (doc.fMode = MultichannelMode) AND (doc.fChannels >= 3),
				 doc.fMode = SeparationsHSL);

	EnableCheck (cSeparationsHSB,
				 (doc.fMode IN [IndexedColorMode,
								RGBColorMode,
								SeparationsHSB]) OR
				 (doc.fMode = MultichannelMode) AND (doc.fChannels >= 3),
				 doc.fMode = SeparationsHSB);

	EnableCheck (cMultichannel,
				 doc.fChannels <> 1,
				 doc.fMode = MultichannelMode);

	Enable (cNewChannel, (doc.fChannels < kMaxChannels) AND
						 (doc.fDepth = 8) AND
						 (doc.fMode <> IndexedColorMode));

	Enable (cDeleteChannel, (doc.fChannels <> 1) AND (fChannel >= 0));

	Enable (cSplitChannels, doc.fChannels <> 1);

	enableMerge := FALSE;

	IF doc.fMode = MonochromeMode THEN
		gApplication.ForAllDocumentsDo (TestMerge);

	Enable (cMergeChannels, enableMerge);

	Enable (cTrap, wholeImage AND (doc.fMode = SeparationsCMYK) AND
								  (fChannel <= 3));

	IF doc.fDepth = 8 THEN
		BEGIN

		Enable (cDefringe, isFloating);

		Enable (cHistogram, TRUE);

		Enable (cResizeImage, TRUE);
		Enable (cResample, TRUE);

		Enable (cFlip, TRUE);

		Enable (cFlipHorizontal, TRUE);
		Enable (cFlipVertical, TRUE);

		Enable (cRotate, TRUE);

		Enable (cRotate180, TRUE);
		Enable (cRotateLeft, TRUE);
		Enable (cRotateRight, TRUE);
		Enable (cRotateArbitrary, TRUE);

		IF haveSelection THEN
			BEGIN

			Enable (cEffects, TRUE);

			EnableCheck (cEffectResize, TRUE,
						 (doc.fEffectMode = cEffectResize) AND
						 (doc.fEffectChannel = fChannel));

			EnableCheck (cEffectRotate, TRUE,
						 (doc.fEffectMode = cEffectRotate) AND
						 (doc.fEffectChannel = fChannel));

			EnableCheck (cEffectSkew, TRUE,
						 (doc.fEffectMode = cEffectSkew) AND
						 (doc.fEffectChannel = fChannel));

			EnableCheck (cEffectPerspective, TRUE,
						 (doc.fEffectMode = cEffectPerspective) AND
						 (doc.fEffectChannel = fChannel));

			EnableCheck (cEffectDistort, TRUE,
						 (doc.fEffectMode = cEffectDistort) AND
						 (doc.fEffectChannel = fChannel))

			END

		END;

	IF wholeImage AND NOT isFloating OR
		NOT (doc.fMode IN [HalftoneMode, IndexedColorMode]) THEN
		BEGIN

		Enable (cMap, TRUE);

		Enable (cInvert, TRUE);

		SetWording (cEqualize, cEqualizeOptWording, cEqualizeWording,
					NOT wholeImage OR isFloating);

		IF doc.fDepth = 8 THEN
			BEGIN

			Enable (cEqualize, TRUE);
			Enable (cThreshold, TRUE);
			Enable (cPosterize, TRUE);
			Enable (cMapArbitrary, TRUE);

			Enable (cAdjust, TRUE);

			Enable (cLevels, TRUE);
			Enable (cBrightContrast, TRUE);

			IF (doc.fMode = IndexedColorMode) OR
					(fChannel = kRGBChannels) THEN
				BEGIN
				Enable (cBalance, TRUE);
				Enable (cHueSaturation, TRUE)
				END

			END

		END;

	IF (doc.fDepth = 8) AND (doc.fMode <> IndexedColorMode) THEN
		BEGIN

		Enable (cFilter, TRUE);

		menu := GetResMenu (kFilterMenu);

		count := CountMItems (menu);

		FOR item := 1 TO count DO
			EnableItem (menu, item);

		Enable (cRepeatFilter, gLastFilter <> 0);

		Enable (cCalculate, TRUE);

		Enable (cAddChannels	   , TRUE);
		Enable (cBlendChannels	   , TRUE);
		Enable (cCompositeChannels , TRUE);
		Enable (cConstantChannel   , TRUE);
		Enable (cDarkerOfChannels  , TRUE);
		Enable (cDifferenceChannels, TRUE);
		Enable (cDuplicateChannel  , TRUE);
		Enable (cLighterOfChannels , TRUE);
		Enable (cMultiplyChannels  , TRUE);
		Enable (cScreenChannels    , TRUE);
		Enable (cSubtractChannels  , TRUE)

		END;

	END;

{*****************************************************************************}

{$S ASelCommand}

FUNCTION TImageView.DoMenuCommand
		(aCmdNumber: CmdNumber): TCommand; OVERRIDE;

	VAR
		r: Rect;
		name: Str255;
		menu: INTEGER;
		item: INTEGER;
		temp: TCommand;
		which: INTEGER;
		channel: INTEGER;
		doc: TImageDocument;

	BEGIN

	doc := TImageDocument (fDocument);

	IF aCmdNumber < 0 THEN
		BEGIN

		CmdToMenuItem (aCmdNumber, menu, item);

		IF menu = kChannelMenu THEN
			BEGIN
			channel := item - 1 - ORD (doc.fMode = RGBColorMode);
			DoMenuCommand := DoSetChannelCommand (SELF, channel);
			EXIT (DoMenuCommand)
			END;

		IF menu = kTableMenu THEN
			IF item > gTableFixed THEN
				BEGIN
				GetItem (GetResMenu (menu), item, name);
				DoMenuCommand := DoTableCommand (SELF, name);
				EXIT (DoMenuCommand)
				END;

		IF menu = kFilterMenu THEN
			BEGIN

			GetItem (GetResMenu (menu), item, name);

			DoMenuCommand := DoFilterCommand (SELF, name, FALSE);

			gLastFilter := item;

			IF name [length (name)] = CHR ($C9) THEN
				DELETE (name, LENGTH (name), 1);

			SetCmdName (cRepeatFilter, name);

			EXIT (DoMenuCommand)

			END

		END;

	DoMenuCommand := gNoChanges;

		CASE aCmdNumber OF

		cZoomIn:
			DoMenuCommand := DoZoomInCommand (SELF);

		cZoomOut:
			DoMenuCommand := DoZoomOutCommand (SELF);

		cScaleFactor:
			DoMenuCommand := DoScaleFactorCommand (SELF);

		cToggleRulers:
			ShowRulers (NOT fRulers OR (fScreenMode <> 0));

		cSelectAll:
			DoMenuCommand := DoSelectAll (SELF);

		cSelectNone:
			DoMenuCommand := DoSelectNone (SELF);

		cSelectInverse:
			DoMenuCommand := DoSelectInverse (SELF);

		cSelectFringe:
			DoMenuCommand := DoSelectFringe (SELF);

		cSelectSimilar:
			DoMenuCommand := DoGrowCommand (SELF, FALSE);

		cGrow:
			DoMenuCommand := DoGrowCommand (SELF, TRUE);

		cFeather:
			DoMenuCommand := DoFeatherCommand (SELF);

		cHideEdges:
			IF fObscured AND (fObscureTime = $7FFFFFFF) THEN
				BEGIN
				fObscured := FALSE;
				DoHighlightSelection (HLOff, HLOn)
				END
			ELSE
				ObscureSelection (-1);

		cDefringe:
			DoMenuCommand := DoDefringeCommand (SELF);

		cMakeAlpha:
			DoMenuCommand := DoMakeAlphaCommand (SELF);

		cSelectAlpha:
			DoMenuCommand := DoSelectAlphaCommand (SELF);

		cCut:
			DoMenuCommand := DoCutCopyCommand (SELF, FALSE);

		cCopy:
			DoMenuCommand := DoCutCopyCommand (SELF, TRUE);

		cPaste,
		cPasteInto,
		cPasteBehind:
			BEGIN

			IF aCmdNumber = cPaste THEN
				which := 0
			ELSE IF aCmdNumber = cPasteInto THEN
				which := 1
			ELSE
				which := 2;

			IF gEventInfo.theOptionKey THEN
				BEGIN

				temp := DoPasteCommand (SELF, which);

				gApplication.CommitLastCommand;

				IF temp <> gNoChanges THEN
					BEGIN
					temp.DoIt;
					temp.Commit;
					temp.Free
					END;

				DoMenuCommand := DoPasteControls (SELF)

				END

			ELSE
				DoMenuCommand := DoPasteCommand (SELF, which)

			END;

		cPasteControls:
			DoMenuCommand := DoPasteControls (SELF);

		cClear:
			IF (doc.fDepth = 8) AND NOT EmptyRect (doc.fSelectionRect) THEN
				DoMenuCommand := DoClearCommand (SELF);

		cFill:
			IF (doc.fDepth = 8) AND NOT EmptyRect (doc.fSelectionRect) THEN
				DoMenuCommand := DoFillCommand (SELF, FALSE);

		cOptionFill:
			DoMenuCommand := DoFillCommand (SELF, TRUE);

		cCrop:
			DoMenuCommand := DoCropCommand (SELF);

		cDefineBrush:
			IF gScratchSelection THEN
				DoMenuCommand := INHERITED DoMenuCommand (cDefineBrush)
			ELSE
				DefineBrush (SELF);

		cDefinePattern:
			IF gScratchSelection THEN
				DoMenuCommand := INHERITED DoMenuCommand (cDefinePattern)
			ELSE
				DefinePattern (SELF);

		cHalftone:
			DoMenuCommand := DoConvertCommand (SELF, HalftoneMode);

		cMonochrome:
			DoMenuCommand := DoConvertCommand (SELF, MonochromeMode);

		cIndexedColor:
			DoMenuCommand := DoConvertCommand (SELF, IndexedColorMode);

		cRGBColor:
			DoMenuCommand := DoConvertCommand (SELF, RGBColorMode);

		cSeparationsCMYK:
			DoMenuCommand := DoConvertCommand (SELF, SeparationsCMYK);

		cSeparationsHSL:
			DoMenuCommand := DoConvertCommand (SELF, SeparationsHSL);

		cSeparationsHSB:
			DoMenuCommand := DoConvertCommand (SELF, SeparationsHSB);

		cMultichannel:
			DoMenuCommand := DoConvertCommand (SELF, MultichannelMode);

		cEditTable:
			DoMenuCommand := DoEditTableCommand (SELF);

		cNewChannel:
			DoMenuCommand := DoNewChannel (SELF);

		cDeleteChannel:
			DoMenuCommand := DoDeleteChannel (SELF);

		cSplitChannels:
			DoMenuCommand := DoSplitChannels (SELF);

		cMergeChannels:
			DoMenuCommand := DoMergeChannels (SELF);

		cTrap:
			DoMenuCommand := DoTrapCommand (SELF);

		cHistogram:
			DoHistogramCommand (SELF);

		cResizeImage:
			DoMenuCommand := DoResizeImage (SELF);

		cResample:
			DoMenuCommand := DoResampleImage (SELF);

		cFlipHorizontal:
			DoMenuCommand := DoFlipCommand (SELF, TRUE, FALSE);

		cFlipVertical:
			DoMenuCommand := DoFlipCommand (SELF, FALSE, TRUE);

		cRotate180:
			DoMenuCommand := DoRotateCommand (SELF, 1800);

		cRotateLeft:
			DoMenuCommand := DoRotateCommand (SELF, -900);

		cRotateRight:
			DoMenuCommand := DoRotateCommand (SELF, 900);

		cRotateArbitrary:
			DoMenuCommand := DoRotateArbitraryCommand (SELF);

		cEffectResize,
		cEffectRotate,
		cEffectSkew,
		cEffectPerspective,
		cEffectDistort:
			DoMenuCommand := SetEffectMode (SELF, aCmdNumber);

		cInvert:
			DoMenuCommand := DoInvertCommand (SELF);

		cEqualize:
			DoMenuCommand := DoEqualizeCommand (SELF);

		cThreshold:
			DoMenuCommand := DoThresholdCommand (SELF);

		cPosterize:
			DoMenuCommand := DoPosterizeCommand (SELF);

		cMapArbitrary:
			DoMenuCommand := DoMapArbitraryCommand (SELF);

		cLevels:
			DoMenuCommand := DoLevelsCommand (SELF);

		cBrightContrast:
			DoMenuCommand := DoBrightnessCommand (SELF);

		cBalance:
			DoMenuCommand := DoBalanceCommand (SELF);

		cHueSaturation:
			DoMenuCommand := DoSaturationCommand (SELF);

		cAddChannels:
			DoMenuCommand := DoAddCommand (SELF);

		cBlendChannels:
			DoMenuCommand := DoBlendCommand (SELF);

		cCompositeChannels:
			DoMenuCommand := DoCompositeCommand (SELF);

		cConstantChannel:
			DoMenuCommand := DoConstantCommand (SELF);

		cDarkerOfChannels:
			DoMenuCommand := DoDarkerCommand (SELF);

		cDifferenceChannels:
			DoMenuCommand := DoDifferenceCommand (SELF);

		cDuplicateChannel:
			DoMenuCommand := DoDuplicateCommand (SELF);

		cLighterOfChannels:
			DoMenuCommand := DoLighterCommand (SELF);

		cMultiplyChannels:
			DoMenuCommand := DoMultiplyCommand (SELF);

		cScreenChannels:
			DoMenuCommand := DoScreenCommand (SELF);

		cSubtractChannels:
			DoMenuCommand := DoSubtractCommand (SELF);

		cRepeatFilter:
			BEGIN
			GetItem (GetResMenu (kFilterMenu), gLastFilter, name);
			DoMenuCommand := DoFilterCommand
							 (SELF, name, NOT gEventInfo.theOptionKey)
			END;

		OTHERWISE
			DoMenuCommand := INHERITED DoMenuCommand (aCmdNumber)

		END

	END;

{*****************************************************************************}

{$S ASelCommand}

FUNCTION TImageView.DoKeyCommand (ch: CHAR;
								  aKeyCode: INTEGER;
								  VAR info: EventInfo): TCommand; OVERRIDE;

	VAR
		nudge: Point;
		outline: BOOLEAN;
		duplicate: BOOLEAN;

	BEGIN

	outline   := info.theOptionKey AND info.theCmdKey;
	duplicate := info.theOptionKey AND NOT info.theCmdKey;

		CASE ch OF

		kBackspaceChar,
		kClearChar:
			IF info.theOptionKey OR info.theShiftKey THEN
				DoKeyCommand := DoMenuCommand (cFill)
			ELSE
				DoKeyCommand := DoMenuCommand (cClear);

		kLeftArrowChar:
			BEGIN
			nudge.h := -1;
			nudge.v := 0;
			DoKeyCommand := DoNudgeSelection (SELF, nudge, duplicate, outline)
			END;

		kRightArrowChar:
			BEGIN
			nudge.h := 1;
			nudge.v := 0;
			DoKeyCommand := DoNudgeSelection (SELF, nudge, duplicate, outline)
			END;

		kUpArrowChar:
			BEGIN
			nudge.h := 0;
			nudge.v := -1;
			DoKeyCommand := DoNudgeSelection (SELF, nudge, duplicate, outline)
			END;

		kDownArrowChar:
			BEGIN
			nudge.h := 0;
			nudge.v := 1;
			DoKeyCommand := DoNudgeSelection (SELF, nudge, duplicate, outline)
			END;

		OTHERWISE
			DoKeyCommand := INHERITED DoKeyCommand (ch, aKeyCode, info)

		END

	END;

{*****************************************************************************}

{$S ASelCommand}

FUNCTION TImageView.DoMouseCommand
		(VAR downLocalPoint: Point;
		 VAR info: EventInfo;
		 VAR hysteresis: Point): TCommand; OVERRIDE;

	VAR
		outline: BOOLEAN;
		duplicate: BOOLEAN;

	BEGIN

	DoMouseCommand := gNoChanges;

	IF NOT (gUseTool IN [LassoTool, MoveTool, EffectsTool]) THEN
		BEGIN
		hysteresis.h := 0;
		hysteresis.v := 0
		END;

	IF PtInRect (downLocalPoint, fExtentRect) THEN

		CASE gUseTool OF

		MarqueeTool:
			DoMouseCommand := DoMarqueeTool
							  (SELF,
							   info.theShiftKey AND NOT info.theCmdKey,
							   info.theCmdKey AND NOT info.theShiftKey,
							   info.theCmdKey AND info.theShiftKey);

		EllipseTool:
			DoMouseCommand := DoEllipseTool
							  (SELF,
							   info.theShiftKey AND NOT info.theCmdKey,
							   info.theCmdKey AND NOT info.theShiftKey,
							   info.theCmdKey AND info.theShiftKey);

		LassoTool:
			DoMouseCommand := DoLassoTool
							  (SELF,
							   downLocalPoint,
							   info.theShiftKey AND NOT info.theCmdKey,
							   info.theCmdKey AND NOT info.theShiftKey,
							   info.theCmdKey AND info.theShiftKey,
							   gTool = TextTool);

		WandTool:
			DoMouseCommand := DoWandTool
							  (SELF,
							   info.theShiftKey AND NOT info.theCmdKey,
							   info.theCmdKey AND NOT info.theShiftKey,
							   info.theCmdKey AND info.theShiftKey);

		CroppingTool:
			DoMouseCommand := DoCroppingTool (SELF);

		BucketTool:
			DoMouseCommand := DoBucketTool (SELF);

		MoveTool:
			BEGIN

			outline := info.theCmdKey AND info.theOptionKey AND
					   (gTool IN [MarqueeTool, EllipseTool,
								  LassoTool, WandTool, TextTool]);

			duplicate := info.theOptionKey AND NOT outline;

			DoMouseCommand := DoMoveSelection (SELF,
											   duplicate,
											   outline,
											   hysteresis)

			END;

		EffectsTool:
			DoMouseCommand := DoEffectsCommand (SELF, downLocalPoint);

		HandTool:
			DoMouseCommand := DoHandTool (SELF);

		ZoomTool:
			DoMouseCommand := DoZoomTool (SELF, downLocalPoint, FALSE);

		ZoomOutTool:
			DoMouseCommand := DoZoomTool (SELF, downLocalPoint, TRUE);

		ZoomLimitTool:
			DoMouseCommand := gNoChanges;

		EyedropperTool:
			DoMouseCommand := DoEyedropperTool (SELF, FALSE);

		EyedropperBackTool:
			DoMouseCommand := DoEyedropperTool (SELF, TRUE);

		LineTool:
			DoMouseCommand := DoLineTool (SELF);

		EraserTool:
			DoMouseCommand := DoEraserTool (SELF, FALSE);

		MagicTool:
			DoMouseCommand := DoEraserTool (SELF, TRUE);

		PencilTool:
			DoMouseCommand := DoPencilTool (SELF, downLocalPoint);

		BrushTool:
			DoMouseCommand := DoBrushTool (SELF);

		AirbrushTool:
			DoMouseCommand := DoAirbrushTool (SELF);

		BlurTool:
			DoMouseCommand := DoBlurTool (SELF);

		SharpenTool:
			DoMouseCommand := DoSharpenTool (SELF);

		SmudgeTool:
			DoMouseCommand := DoSmudgeTool (SELF, info.theOptionKey);

		StampTool:
			DoMouseCommand := DoStampTool (SELF);

		StampPadTool:
			DoMouseCommand := DoStampPadTool (SELF, downLocalPoint);

		GradientTool:
			DoMouseCommand := DoGradientTool (SELF);

		TextTool:
			DoMouseCommand := DoTextTool (SELF, downLocalPoint);

		OTHERWISE
			Failure (errNotYetImp, 0)

		END

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE TImageWindow.UpdateEvent; OVERRIDE;

	VAR
		fi: FailInfo;
		aWmgrWindow: WindowPtr;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		gDoingUpdate := FALSE;
		EndUpdate (aWmgrWindow);
		FailNewMessage (error, message, msgDrawFailed)
		END;

	BEGIN

	gDoingUpdate := TRUE;

	aWmgrWindow := fWmgrWindow;
	BeginUpdate (aWmgrWindow);

	CatchFailures (fi, CleanUp);

	DrawAll;

	Success (fi);

	EndUpdate (aWmgrWindow);

	gDoingUpdate := FALSE

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE TImageWindow.MoveByUser (startPt: Point); OVERRIDE;

	VAR
		bounds: Rect;

	BEGIN

	GetMoveBounds (bounds);

	MyDragWindow (fWmgrWindow, startPt, bounds);

	TImageView (TFrame (fFrameList.First) . fView) . AdjustZoomSize

	END;

{*****************************************************************************}

{$S ARes3}

FUNCTION TImageWindow.TrackInContent
		(localPoint: Point; VAR info: EventInfo): TCommand; OVERRIDE;

	VAR
		r1: Rect;
		r2: Rect;
		frame: TImageFrame;

	BEGIN

	frame := TImageFrame (fFrameList.First);

	r1 := frame.fStatusRect;

	IF TImageView (frame.fView) . fRulers THEN
		SetRect (r2, 0, 0, kRulerWidth, kRulerWidth)
	ELSE
		r2 := gZeroRect;

	IF PtInRect (localPoint, r1) THEN
		BEGIN
		DoSizeBoxPopUp (TImageDocument (frame.fView.fDocument), r1, info);
		TrackInContent := gNoChanges
		END

	ELSE IF PtInRect (localPoint, r2) THEN
		TrackInContent := AdjustZeroPoint (TImageView (frame.fView))

	ELSE
		TrackInContent := INHERITED TrackInContent (localPoint, info)

	END;

{*****************************************************************************}

{$S AOpen}

PROCEDURE TRulerFrame.IRulerFrame (window: TImageWindow; vertical: BOOLEAN);

	VAR
		r: Rect;

	BEGIN

	fVertical := vertical;

	r := window.fContentRect;

	IF fVertical THEN
		BEGIN
		r.right  := kRulerWidth;
		r.top	 := kRulerWidth + 1;
		r.bottom := r.bottom - kStdSzMinus1SBar
		END
	ELSE
		BEGIN
		r.bottom := kRulerWidth;
		r.left	 := kRulerWidth + 1;
		r.right  := r.right - kStdSzMinus1SBar
		END;

	IFrame (window, window, r, FALSE, FALSE, FALSE, FALSE)

	END;

{*****************************************************************************}

{$S AOpen}

PROCEDURE TRulerFrame.ResizedContainer
		(oldBotRight, newBotRight: Point); OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	IF (oldBotRight.v <> newBotRight.v) AND fVertical OR
	   (oldBotRight.h <> newBotRight.h) AND NOT fVertical THEN
		BEGIN

		IF fVertical THEN
			fContentRect.bottom := newBotRight.v - kRulerWidth
		ELSE
			fContentRect.right	:= newBotRight.h - kRulerWidth;

		FocusOnContainer;

		r := fContentRect;
		InvalRect (r);

		ChangedSize (oldBotRight, newBotRight)

		END

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TRulerFrame.ScrollRuler (invalWholeFrame: BOOLEAN);

	VAR
		r: Rect;
		delta: INTEGER;
		view: TRulerView;
		oldOrigin: INTEGER;

	BEGIN

	IF invalWholeFrame THEN
		ForceRedraw

	ELSE IF NOT EmptyRgn (WindowPeek (fWindow.fWmgrWindow) ^.updateRgn) THEN
		BEGIN
		ForceRedraw;
		UpdateEvent
		END

	ELSE
		BEGIN

		view := TRulerView (fView);

		oldOrigin := view.fOrigin;

		view.FindOrigin;

		delta := view.fOrigin - oldOrigin;

		IF delta <> 0 THEN
			BEGIN

			FocusOnContainer;

			r := fContentRect;

			IF fVertical THEN
				ScrollRect (r, 0, delta, gTempRgn1)
			ELSE
				ScrollRect (r, delta, 0, gTempRgn1);

			InvalRgn (gTempRgn1);

			UpdateEvent

			END

		END

	END;

{*****************************************************************************}

{$S AOpen}

PROCEDURE TRulerView.IRulerView (view: TImageView);

	BEGIN

	fImageView := view;

	fLastMag := 0;

	fMarkOffset := -kMaxCoord;

	IView (NIL, NIL, gZeroRect, sizeFrame, sizeFrame, FALSE, hlOff)

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TRulerView.FindOrigin;

	VAR
		mag: INTEGER;
		scroll: INTEGER;
		origin: INTEGER;
		doc: TImageDocument;

	BEGIN

	doc := TImageDocument (fImageView.fDocument);

	IF TRulerFrame (fFrame) . fVertical THEN
		BEGIN
		origin := doc.fRulerOrigin.v;
		scroll := GetCtlValue (fImageView.fFrame.fScrollBars [v])
		END
	ELSE
		BEGIN
		origin := doc.fRulerOrigin.h;
		scroll := GetCtlValue (fImageView.fFrame.fScrollBars [h])
		END;

	mag := fImageView.fMagnification;

	IF mag > 1 THEN
		origin := origin * mag
	ELSE IF mag < 1 THEN
		origin := origin DIV (-mag);

	fOrigin := origin - scroll

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TRulerView.FindScale;

	CONST
		kTableSize = 20;

	VAR
		res: Fixed;
		j: INTEGER;
		k: INTEGER;
		m: INTEGER;
		mag: INTEGER;
		units: INTEGER;
		level: INTEGER;
		steps: LONGINT;
		scale: EXTENDED;
		fraction: LONGINT;
		doc: TImageDocument;
		table: ARRAY [1..kTableSize] OF INTEGER;

	BEGIN

	mag := fImageView.fMagnification;

	doc := TImageDocument (fImageView.fDocument);

	res := doc.fStyleInfo.fResolution.value;

	IF TRulerFrame (fFrame) . fVertical THEN
		units := doc.fStyleInfo.fHeightUnit
	ELSE
		units := doc.fStyleInfo.fWidthUnit;

	IF units = 5 THEN
		units := gPreferences.fColumnWidth.scale;

	IF (mag   = fLastMag) AND
	   (res   = fLastRes) AND
	   (units = fLastUnit) THEN EXIT (FindScale);

	fLastMag  := mag;
	fLastRes  := res;
	fLastUnit := units;

	scale := res / $10000;

	IF mag > 1 THEN
		scale := scale * mag
	ELSE IF mag < 1 THEN
		scale := scale / (-mag);

	FOR j := 1 TO kTableSize DO table [j] := 2;

		CASE units OF

		1:	BEGIN	{ inches }

			scale := scale / 32;

			fraction := 32;

			FOR j := 6 TO kTableSize DO
				IF NOT ODD (j) THEN
					table [j] := 5

			END;

		2:	BEGIN	{ cm }

			scale := scale / 2.54 / 10;

			fraction := 10;

			FOR j := 1 TO kTableSize DO
				IF ODD (j) THEN
					table [j] := 5

			END;

		OTHERWISE	{ points/picas }
			BEGIN

			scale := scale / 72;

			IF units = 3 THEN
				fraction := 1
			ELSE
				fraction := 12;

			table [1] := 3;
			table [4] := 3;

			FOR j := 6 TO kTableSize DO
				IF NOT ODD (j) THEN
					table [j] := 5

			END

		END;

	j := 1;

	fLabel := 1;

	WHILE scale < 5 DO
		BEGIN

		IF (scale * 2 >= 5) AND (table [j  ] = 5) AND
								(table [j+1] = 2) THEN
			BEGIN
			table [j  ] := 2;
			table [j+1] := 5
			END;

		scale := scale * table [j];

		IF fraction = 1 THEN
			fLabel := fLabel * table [j]
		ELSE
			fraction := fraction DIV table [j];

		j := j + 1

		END;

	fScale := ROUND (scale * $10000);

	k := j;

	WHILE (scale < 32) OR (fraction > 1) DO
		BEGIN

		IF fraction = 1 THEN
			IF (scale * 2 >= 32) AND (table [k	] = 5) AND
									 (table [k+1] = 2) THEN
				BEGIN
				table [k  ] := 2;
				table [k+1] := 5
				END;

		scale := scale * table [k];

		IF fraction = 1 THEN
			fLabel := fLabel * table [k]
		ELSE
			fraction := fraction DIV table [k];

		k := k + 1

		END;

	FOR level := 0 TO 5 DO
		fSteps [level] := 0;

	level := 5;

	steps := 1;

	FOR m := j TO k DO
		BEGIN

		IF m = k THEN
			level := 0;

		fSteps [level] := Min (32000, steps);

		steps := steps * table [m];

		level := level - 1

		END;

	IF fSteps [3] = 0 THEN
		BEGIN
		fSteps [3] := fSteps [4];
		fSteps [4] := 0
		END

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TRulerView.Draw (area: Rect); OVERRIDE;

	VAR
		s: Str255;
		x: INTEGER;
		y: INTEGER;
		mark: INTEGER;
		dist: INTEGER;
		lower: INTEGER;
		upper: INTEGER;
		vertical: BOOLEAN;

	BEGIN

	FindOrigin;
	FindScale;

	vertical := TRulerFrame (fFrame) . fVertical;

	IF vertical THEN
		BEGIN
		lower := area.top;
		upper := area.bottom
		END
	ELSE
		BEGIN
		lower := area.left;
		upper := area.right
		END;

	lower := lower - fOrigin - 32;
	upper := upper - fOrigin;

	lower := ROUND (lower * ($10000 / fScale)) - 1;
	upper := ROUND (upper * ($10000 / fScale)) + 1;

	PenNormal;

	TextFont (gGeneva);
	TextSize (9);

	EraseRect (area);

	FOR mark := lower TO upper DO
		BEGIN

		x := FixRound (mark * fScale) + fOrigin;

		dist := ABS (mark);

		IF dist MOD fSteps [0] = 0 THEN
			BEGIN

			NumToString (dist DIV fSteps [0] * fLabel, s);

			IF LENGTH (s) > 4 THEN
				DELETE (s, 1, LENGTH (s) - 4);

			IF vertical THEN
				FOR y := 1 TO LENGTH (s) DO
					BEGIN
					MoveTo (1, x + 8 * y);
					DrawChar (s [y])
					END
			ELSE
				BEGIN
				MoveTo (x + 1, 8);
				DrawString (s)
				END;

			y := kRulerWidth - 1

			END

		ELSE IF (fSteps [1] <> 0) & (dist MOD fSteps [1] = 0) THEN
			y := 9
		ELSE IF (fSteps [2] <> 0) & (dist MOD fSteps [2] = 0) THEN
			y := 7
		ELSE IF (fSteps [3] <> 0) & (dist MOD fSteps [3] = 0) THEN
			y := 5
		ELSE IF (fSteps [4] <> 0) & (dist MOD fSteps [4] = 0) THEN
			y := 3
		ELSE
			y := 2;

		IF vertical THEN
			BEGIN
			MoveTo (kRulerWidth - 1, x - 1);
			Line (-y, 0)
			END
		ELSE
			BEGIN
			MoveTo (x - 1, kRulerWidth - 1);
			Line (0, -y)
			END

		END

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TRulerView.DoHighlightSelection (fromHL, toHL: HLState); OVERRIDE;

	VAR
		j: INTEGER;

	BEGIN

	IF fromHL <> toHL THEN
		BEGIN

		FindOrigin;

		PenNormal;
		PenMode (patXOR);

		IF TRulerFrame (fFrame) . fVertical THEN
			BEGIN
			MoveTo (1, fOrigin + fMarkOffset);
			FOR j := 1 TO kRulerWidth DIV 2 DO
				BEGIN
				Line (0, 0);
				Move (2, 0)
				END
			END
		ELSE
			BEGIN
			MoveTo (fOrigin + fMarkOffset, 1);
			FOR j := 1 TO kRulerWidth DIV 2 DO
				BEGIN
				Line (0, 0);
				Move (0, 2)
				END
			END;

		PenNormal

		END

	END;

{*****************************************************************************}

{$S AOpen}

PROCEDURE TImageFrame.PositionRulers;

	VAR
		r: Rect;
		pt1: Point;
		pt2: Point;

	BEGIN

	r := fContentRect;

	pt1 := fRuler [h] . fContentRect . topLeft;
	pt2 := fRuler [v] . fContentRect . topLeft;

	IF TImageView (fView) . fRulers THEN
		BEGIN

		r.top  := kRulerWidth + 1;
		r.left := kRulerWidth + 1;

		pt1.v := 0;
		pt2.h := 0

		END

	ELSE
		BEGIN

		r.topLeft := Point (0);

		pt1.v := -kRulerWidth - 1;
		pt2.h := -kRulerWidth - 1

		END;

	Move (r.topLeft, FALSE);
	Resize (r.botRight, FALSE);

	fRuler [h] . Move (pt1, FALSE);
	fRuler [v] . Move (pt2, FALSE)

	END;

{*****************************************************************************}

{$S ARes3}

FUNCTION TImageFrame.AdjustSBars: BOOLEAN; OVERRIDE;

	CONST
		kStatusWidth = 64;

	BEGIN

	fStatusRect.top    := fContentRect.bottom + 1;
	fStatusRect.bottom := fStatusRect.top + kStdSzSBar - 2;
	fStatusRect.left   := 0;
	fStatusRect.right  := kStatusWidth;

	fSBarOffset.top  := 0;
	fSBarOffset.left := fStatusRect.right + 1;

	IF fView <> NIL THEN
		IF TImageView (fView) . fRulers THEN
			BEGIN
			fSBarOffset.left := fSBarOffset.left - kRulerWidth - 1;
			fSBarOffset.top  := -kRulerWidth - 1
			END;

	AdjustSBars := INHERITED AdjustSBars

	END;

{*****************************************************************************}

{$S ARes3}

FUNCTION TImageFrame.CalcSBarMin (direction: VHSelect): INTEGER; OVERRIDE;

	VAR
		slop: INTEGER;

	BEGIN

	slop := fContentRect.botRight.vh [direction] -
			fContentRect.topLeft.vh [direction] -
			fScrollLimit.vh [direction];

	IF slop <= 0 THEN
		CalcSBarMin := 0
	ELSE
		CalcSBarMin := -(slop DIV 2)

	END;

{*****************************************************************************}

{$S ARes3}

FUNCTION TImageFrame.CalcSBarMax (direction: VHSelect): INTEGER; OVERRIDE;

	VAR
		sBarMin: INTEGER;

	BEGIN

	sBarMin := CalcSBarMin (direction);

	IF sBarMin < 0 THEN
		CalcSBarMax := sBarMin
	ELSE
		CalcSBarMax := INHERITED CalcSBarMax (direction)

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE TImageFrame.DrawAll; OVERRIDE;

	VAR
		r: Rect;
		vr: Rect;
		cr: Rect;
		pat: Pattern;

	BEGIN

	IF fShowBorder THEN
		DrawBorder;

	FocusOnContainer;

	r := fStatusRect;

	PenNormal;

	MoveTo (r.right, r.top);
	LineTo (r.right, r.bottom - 1);

	IF RectIsVisible (r) THEN
		TImageView (fView) . DoDrawStatus (r);

	IF TImageView (fView) . fRulers THEN
		BEGIN

		PenPat (gray);

		MoveTo (0, kRulerWidth - 5);
		Line (kRulerWidth - 1, 0);

		MoveTo (kRulerWidth - 5, 0);
		Line (0, kRulerWidth - 1);

		PenNormal

		END;

	Focus;

	GetViewedRect (vr);

	EraseRect (vr);

	cr := fContentRect;
	OffsetRect (cr, fRelOrigin.h, fRelOrigin.v);

	IF NOT EqualRect (vr, cr) THEN
		BEGIN

		IF TImageView (fView) . fScreenMode <> 2 THEN
			pat := gray
		ELSE
			pat := black;

		IF cr.top < vr.top THEN
			BEGIN
			r := cr;
			r.bottom := vr.top;
			cr.top := vr.top;
			FillRect (r, pat)
			END;

		IF cr.bottom > vr.bottom THEN
			BEGIN
			r := cr;
			r.top := vr.bottom;
			cr.bottom := vr.bottom;
			FillRect (r, pat)
			END;

		IF cr.left < vr.left THEN
			BEGIN
			r := cr;
			r.right := vr.left;
			FillRect (r, pat)
			END;

		IF cr.right > vr.right THEN
			BEGIN
			r := cr;
			r.left := vr.right;
			FillRect (r, pat)
			END;

		r := vr;
		InsetRect (r, -1, -1);
		FrameRect (r)

		END;

	DrawInterior

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE TImageFrame.ChangedSize (oldBotRight: Point;
								   newBotRight: Point); OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	INHERITED ChangedSize (oldBotRight, newBotRight);

	IF LONGINT (oldBotRight) <> LONGINT (newBotRight) THEN
		BEGIN

		FocusOnContainer;

		r		:= fStatusRect;
		r.top	:= r.top - 1;

		InvalRect (r);

		OffsetRect (r, 0, oldBotRight.v - newBotRight.v);

		InvalRect (r)

		END

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE TImageFrame.ScrlToSBars (invalWholeFrame: BOOLEAN); OVERRIDE;

	VAR
		r: Rect;
		delta: Point;
		vhs: VHSelect;
		pass: INTEGER;
		radius: INTEGER;
		newRelOrigin: Point;

	BEGIN

	IF TImageView (fView) . fRulers THEN
		BEGIN
		fRuler [h] . ScrollRuler (invalWholeFrame);
		fRuler [v] . ScrollRuler (invalWholeFrame)
		END;

	IF invalWholeFrame THEN
		BEGIN
		INHERITED ScrlToSBars (TRUE);
		EXIT (ScrlToSBars)
		END;

	FOR vhs := v TO h DO
		BEGIN
		newRelOrigin.vh [vhs] := GetCtlValue (fScrollBars [vhs]) -
								 fContentRect.topLeft.vh[vhs];
		delta.vh [vhs] := newRelOrigin.vh[vhs] -
						  fRelOrigin.vh[vhs];
		END;

	gDoingScroll := TRUE;

	IF LONGINT (delta) <> 0 THEN
		IF NOT EmptyRgn (WindowPeek (fWindow.fWmgrWindow) ^.updateRgn) THEN
			UpdateEvent;

	fRelOrigin := newRelOrigin;

	FocusOnContainer;

	IF LONGINT (delta) <> 0 THEN
		BEGIN

		r := fContentRect;

		ScrollRect (r, -delta.h, -delta.v, gTempRgn1);

		OffsetRgn (gTempRgn1, fRelOrigin.h, fRelOrigin.v);

		radius := 5;

		pass := 0;

		WHILE NOT EmptyRgn (gTempRgn1) DO
			BEGIN

			pass := pass + 1;

			IF pass = 5 THEN
				BEGIN
				Focus;
				InvalRgn (gTempRgn1);
				UpdateEvent;
				LEAVE
				END;

			IF delta.v < 0 THEN
				BEGIN

				r := gTempRgn1^^.rgnBBox;

				r.bottom := r.top - delta.v;

				RectRgn (gTempRgn2, r);
				SectRgn (gTempRgn2, gTempRgn1, gTempRgn2);

				r := gTempRgn2^^.rgnBBox;

				IF NOT EmptyRect (r) THEN
					BEGIN
					Focus;
					InvalRect (r);
					UpdateEvent
					END;

				DiffRgn (gTempRgn1, gTempRgn2, gTempRgn1)

				END;

			IF delta.h <> 0 THEN
				BEGIN

				r := gTempRgn1^^.rgnBBox;

				IF delta.h > 0 THEN
					r.left := r.right - delta.h - radius
				ELSE
					r.right := r.left - delta.h + radius;

				radius := 0;

				RectRgn (gTempRgn2, r);
				SectRgn (gTempRgn2, gTempRgn1, gTempRgn2);

				r := gTempRgn2^^.rgnBBox;

				IF NOT EmptyRect (r) THEN
					BEGIN
					Focus;
					InvalRect (r);
					UpdateEvent
					END;

				DiffRgn (gTempRgn1, gTempRgn2, gTempRgn1)

				END;

			IF delta.v > 0 THEN
				BEGIN

				r := gTempRgn1^^.rgnBBox;

				r.top := r.bottom - delta.v - radius;

				radius := 0;

				RectRgn (gTempRgn2, r);
				SectRgn (gTempRgn2, gTempRgn1, gTempRgn2);

				r := gTempRgn2^^.rgnBBox;

				IF NOT EmptyRect (r) THEN
					BEGIN
					Focus;
					InvalRect (r);
					UpdateEvent
					END;

				DiffRgn (gTempRgn1, gTempRgn2, gTempRgn1)

				END;

			delta.h := -delta.h;
			delta.v := -delta.v

			END

		END;

	gDoingScroll := FALSE

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE TToolsView.IToolsView;

	CONST
		kToolsID = 1002;
		kPict1ID = 1001;
		kPict2ID = 1002;

	VAR
		r: Rect;
		j: INTEGER;
		tool: TTool;
		ct: CTabHandle;
		depth: INTEGER;
		aWindow: TWindow;
		monochrome: BOOLEAN;

	BEGIN

	SetRect (r, 0, 0, 55, 303);

	{$IFC qBarneyscan}
	r.bottom := r.bottom - 22;
	{$ENDC}

	IView (NIL, NIL, r, sizeFixed, sizeFixed, TRUE, HLOn);

	aWindow := NewGhostWindow (kToolsID, SELF);

	gToolsWindow := aWindow.fWmgrWindow;
	gNoDocuments := FALSE;

	gToolsPalette1 := NIL;
	gToolsPalette2 := NIL;

	IF gConfiguration.hasColorToolbox THEN
		BEGIN

		gToolsPalette1 := GetNewPalette (0);

		SetPalette (gToolsWindow, gToolsPalette1, TRUE);

		GetScreenInfo (GetMainDevice, depth, monochrome);

		IF (depth >= 4) AND (depth <= 8) THEN
			BEGIN
			ct := GetCTable (depth);
			gToolsPalette2 := NewPalette (ct^^.ctSize + 1, ct, pmTolerant, 0);
			DisposCTable (ct)
			END

		END;

	fPict1 := GetPicture (kPict1ID);
	FailNil (fPict1);

	fPict2 := GetPicture (kPict2ID);
	FailNil (fPict2);

	{$H-}

	fPictRect1 := fPict1^^.picFrame;
	OffsetRect (fPictRect1, 2, 2);

	fPictRect2 := fPict2^^.picFrame;
	OffsetRect (fPictRect2, 2, 280);

	{$IFC qBarneyscan}
	OffsetRect (fPictRect2, 0, -22);
	{$ENDC}

	SetRect (fToolRect [MarqueeTool   ],  3,   3, 27,  24);
	SetRect (fToolRect [EllipseTool   ], 28,   3, 52,  24);
	SetRect (fToolRect [LassoTool	  ],  3,  25, 27,  46);
	SetRect (fToolRect [WandTool	  ], 28,  25, 52,  46);
	SetRect (fToolRect [HandTool	  ],  3,  47, 27,  68);
	SetRect (fToolRect [ZoomTool	  ], 28,  47, 52,  68);
	SetRect (fToolRect [CroppingTool  ],  3,  69, 27,  90);
	SetRect (fToolRect [TextTool	  ], 28,  69, 52,  90);
	SetRect (fToolRect [BucketTool	  ],  3,  91, 27, 112);
	SetRect (fToolRect [GradientTool  ], 28,  91, 52, 112);
	SetRect (fToolRect [LineTool	  ],  3, 113, 27, 134);
	SetRect (fToolRect [EyedropperTool], 28, 113, 52, 134);
	SetRect (fToolRect [EraserTool	  ],  3, 135, 27, 156);
	SetRect (fToolRect [PencilTool	  ], 28, 135, 52, 156);
	SetRect (fToolRect [AirbrushTool  ],  3, 157, 27, 178);
	SetRect (fToolRect [BrushTool	  ], 28, 157, 52, 178);
	SetRect (fToolRect [StampTool	  ],  3, 179, 27, 200);
	SetRect (fToolRect [SmudgeTool	  ], 28, 179, 52, 200);
	SetRect (fToolRect [BlurTool	  ],  3, 201, 27, 222);
	SetRect (fToolRect [SharpenTool   ], 28, 201, 52, 222);

	{$IFC qBarneyscan}

	FOR tool := LassoTool TO LineTool DO
		IF fToolRect [tool] . top > fToolRect [CroppingTool] . top THEN
			OffsetRect (fToolRect [tool], 0, -22);

	fToolRect [CroppingTool] := gZeroRect;
	fToolRect [TextTool    ] := gZeroRect;

	{$ENDC}

	fForeRgn := NewRgn;
	fBackRgn := NewRgn;

	FailNil (fForeRgn);
	FailNil (fBackRgn);

	SetRect (r, 3, 226, 52, 277);

	{$IFC qBarneyscan}
	OffsetRect (r, 0, -22);
	{$ENDC}

	RectRgn (fBackRgn, r);

	InsetRect (r, 11, 11);
	r.bottom := r.bottom - 1;

	RectRgn (fForeRgn, r);

	DiffRgn (fBackRgn, fForeRgn, fBackRgn);

	InsetRgn (fForeRgn, 1, 1);

	SetRect (fModeRect [0],  6, 283, 19, 298);
	SetRect (fModeRect [1], 21, 283, 34, 298);
	SetRect (fModeRect [2], 36, 283, 49, 298);

	FOR j := 0 TO 2 DO
		BEGIN

		{$IFC qBarneyscan}
		OffsetRect (fModeRect [j], 0, -22);
		{$ENDC}

		r := fModeRect [j];
		r.top	:= r.bottom - 2;
		r.left	:= r.left + 2;
		r.right := r.right - 2;
		fMarkRect [j] := r

		END;

	{$H+}

	aWindow.Open;

	HiliteWindow (gToolsWindow, TRUE)

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE RgnFillRGB (rgn: RgnHandle; color: RGBColor; depth: INTEGER);

	TYPE
		BitPtr = ^BitMap;

	VAR
		r: INTEGER;
		c: INTEGER;
		pat: Pattern;
		temp: LONGINT;
		srcRect: Rect;
		dstRect: Rect;
		level: INTEGER;
		deltaR: LONGINT;
		deltaG: LONGINT;
		deltaB: LONGINT;
		goalColor: RGBColor;
		scrnColor: RGBColor;

	BEGIN

	IF depth < 4 THEN
		BEGIN

		level := ORD (ConvertToGray (BSR (color.red  , 8),
									 BSR (color.green, 8),
									 BSR (color.blue , 8)));

		FOR r := 0 TO 7 DO
			BEGIN
			temp := 0;
			FOR c := 0 TO 7 DO
				IF level + ORD (gRgnFillNoise [r] [c]) < 255 THEN
					BSET (temp, 7 - c);
			pat [r] := temp
			END;

		FillRgn (rgn, pat)

		END

	ELSE
		BEGIN

		deltaR := 0;
		deltaG := 0;
		deltaB := 0;

		FOR r := 0 TO 3 DO
			BEGIN

			goalColor.red	:= Max (0,
							   Min ($0000FFFF,
									BAND ($0000FFFF, color.red	) + deltaR));
			goalColor.green := Max (0,
							   Min ($0000FFFF,
									BAND ($0000FFFF, color.green) + deltaG));
			goalColor.blue	:= Max (0,
							   Min ($0000FFFF,
									BAND ($0000FFFF, color.blue ) + deltaB));

			IF depth > 8 THEN
				scrnColor := goalColor
			ELSE
				Index2Color (Color2Index (goalColor), scrnColor);

			{$PUSH}
			{$R-}

			gRgnFillPixMap.pmTable^^.ctTable [r] . rgb := scrnColor;

			{$POP}

			deltaR := deltaR + BAND ($0000FFFF, 	color.red  ) -
							   BAND ($0000FFFF, scrnColor.red  );
			deltaG := deltaG + BAND ($0000FFFF, 	color.green) -
							   BAND ($0000FFFF, scrnColor.green);
			deltaB := deltaB + BAND ($0000FFFF, 	color.blue ) -
							   BAND ($0000FFFF, scrnColor.blue )

			END;

		gRgnFillPixMap.pmTable^^.ctSeed := GetCTSeed;

		dstRect := rgn^^.rgnBBox;

		srcRect := dstRect;
		OffsetRect (srcRect, -srcRect.left, -srcRect.top);

		CopyBits (BitPtr (@gRgnFillPixMap)^,
				  thePort^.portBits,
				  srcRect,
				  dstRect,
				  srcCopy,
				  rgn)

		END

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE DoColorizedFill (rgn: RgnHandle; color: RGBColor; depth: INTEGER);

	VAR
		band: INTEGER;
		level: INTEGER;
		view: TImageView;
		theColor: RGBColor;
		doc: TImageDocument;
		subtractive: BOOLEAN;

	BEGIN

	theColor := color;

	IF MEMBER (gTarget, TImageView) THEN
		BEGIN

		view := TImageView (gTarget);
		doc  := TImageDocument (view.fDocument);

		IF (doc.fMode <> IndexedColorMode) AND
		   (view.fChannel <> kRGBChannels) THEN
			BEGIN

			level := ORD (ConvertToGray (BSR (color.red  , 8),
										 BSR (color.green, 8),
										 BSR (color.blue , 8)));

			theColor.red   := BSL (level, 8) + level;
			theColor.green := BSL (level, 8) + level;
			theColor.blue  := BSL (level, 8) + level

			END;

		IF view.ColorizeBand (band, subtractive) THEN
			DoColorize (theColor, band, subtractive)

		END;

	RgnFillRGB (rgn, theColor, depth)

	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE ColorizedFill (rgn: RgnHandle; color: RGBColor);

	VAR
		r: Rect;
		depth: INTEGER;
		maxDevice: GDHandle;
		monochrome: BOOLEAN;
		saveDevice: GDHandle;

	BEGIN

	IF gConfiguration.hasColorToolBox THEN
		BEGIN

		r := rgn^^.rgnBBox;
		LocalToGlobal (r.topLeft);
		LocalToGlobal (r.botRight);

		maxDevice := GetMaxDevice (r);

		GetScreenInfo (maxDevice, depth, monochrome);

		saveDevice := GetGDevice;

		IF (maxDevice <> saveDevice) & (maxDevice <> NIL) THEN
			SetGDevice (maxDevice)

		END

	ELSE
		depth := 1;

	DoColorizedFill (rgn, color, depth);

	IF gConfiguration.hasColorToolBox & (maxDevice <> saveDevice) THEN
		SetGDevice (saveDevice)

	END;

{*****************************************************************************}

{$S AEncoded}

PROCEDURE TToolsView.DrawForeground;

	BEGIN

	fFrame.Focus;

	ColorizedFill (fForeRgn, gForegroundColor)

	END;

{*****************************************************************************}

{$S AEncoded}

PROCEDURE TToolsView.DrawBackground;

	BEGIN

	fFrame.Focus;

	ColorizedFill (fBackRgn, gBackgroundColor)

	END;

{*****************************************************************************}

{$S AEncoded}

PROCEDURE TToolsView.InvalidateColors;

	VAR
		r: Rect;

	BEGIN

	r := fBackRgn^^.rgnBBox;

	InvalidRect (r)

	END;

{*****************************************************************************}

{$S AEncoded}

PROCEDURE TToolsView.MarkMode (mode: INTEGER);

	VAR
		j: INTEGER;

	BEGIN

	fFrame.Focus;

	PenNormal;

	FOR j := 0 TO 2 DO
		IF j = mode THEN
			PaintRect (fMarkRect [j])
		ELSE
			EraseRect (fMarkRect [j])

	END;

{*****************************************************************************}

{$S AEncoded}

PROCEDURE TToolsView.Draw (area: Rect); OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	r := fPictRect1;
	DrawPicture (fPict1, r);

	PenNormal;

	r := fBackRgn^^.rgnBBox;
	InsetRect (r, -1, -1);
	FrameRect (r);

	r := fForeRgn^^.rgnBBox;
	InsetRect (r, -1, -1);
	FrameRect (r);

	DrawForeground;
	DrawBackground;

	r := fPictRect2;
	DrawPicture (fPict2, r);

	IF MEMBER (gTarget, TImageView) THEN
		MarkMode (TImageView (gTarget) . fScreenMode)

	END;

{*****************************************************************************}

{$S AEncoded}

PROCEDURE TToolsView.DoHighlightSelection (fromHL, toHL: HLState); OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	IF fromHL <> toHL THEN
		BEGIN

		fFrame.Focus;

		r := fToolRect [gTool];
		InvertRect (r)

		END

	END;

{*****************************************************************************}

{$S AEncoded}

FUNCTION TToolsView.PickTool (tool: TTool; click: INTEGER): TCommand;

	BEGIN

	PickTool := gNoChanges;

	IF tool <> gTool THEN
		BEGIN

		DoHighlightSelection (HLOn, HLOff);
		gTool := tool;
		DoHighlightSelection (HLOff, HLOn);

		UpdateBrush

		END;

	IF click = 2 THEN
		CASE tool OF

		LassoTool:
			DoLassoOptions;

		MarqueeTool:
			DoMarqueeOptions;

		EllipseTool:
			DoEllipseOptions;

		WandTool:
			DoWandOptions;

		CroppingTool:
			DoCroppingOptions;

		BucketTool:
			DoBucketOptions;

		HandTool:
			IF MEMBER (gTarget, TImageView) THEN
				PickTool := DoOverviewSize (TImageView (gTarget));

		ZoomTool:
			IF MEMBER (gTarget, TImageView) THEN
				PickTool := DoNormalSize (TImageView (gTarget));

		EyedropperTool:
			ResetGroundColors;

		EraserTool:
			IF MEMBER (gTarget, TImageView) THEN
				PickTool := DoEraseAll (TImageView (gTarget));

		LineTool:
			DoLineToolOptions;

		PencilTool:
			DoPencilOptions;

		BrushTool:
			DoBrushOptions;

		AirbrushTool:
			DoAirbrushOptions;

		BlurTool:
			DoBlurOptions;

		SharpenTool:
			DoSharpenOptions;

		SmudgeTool:
			DoSmudgeOptions;

		StampTool:
			DoStampOptions;

		GradientTool:
			DoGradientOptions

		END

	END;

{*****************************************************************************}

{$S AEncoded}

FUNCTION TToolsView.FindTool (pt: Point): TTool;

	VAR
		tool: TTool;

	BEGIN

	FOR tool := LassoTool TO LineTool DO
		IF PtInRect (pt, fToolRect [tool]) THEN
			BEGIN
			FindTool := tool;
			EXIT (FindTool)
			END;

	FindTool := NullTool

	END;

{*****************************************************************************}

{$S AEncoded}

FUNCTION TToolsView.DoMouseCommand
		(VAR downLocalPoint: Point;
		 VAR info: EventInfo;
		 VAR hysteresis: Point): TCommand; OVERRIDE;

	VAR
		tool: TTool;
		mode: INTEGER;
		click: INTEGER;
		view: TImageView;

	BEGIN

	DoMouseCommand := gNoChanges;

	tool := FindTool (downLocalPoint);

	IF tool <> NullTool THEN
		BEGIN
		IF info.theOptionKey THEN
			click := 2
		ELSE
			click := info.theClickCount;
		DoMouseCommand := PickTool (tool, click);
		EXIT (DoMouseCommand)
		END;

	IF PtInRgn (downLocalPoint, fForeRgn) THEN
		DoSetForeground

	ELSE IF PtInRgn (downLocalPoint, fBackRgn) THEN
		DoSetBackground

	ELSE
		FOR mode := 0 TO 2 DO
			IF PtInRect (downLocalPoint, fModeRect [mode]) THEN
				IF MEMBER (gTarget, TImageView) THEN
					BEGIN
					view := TImageView (gTarget);
					IF view.fScreenMode <> mode THEN
						BEGIN
						MarkMode (mode);
						view.SetScreenMode (mode)
						END
					END

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE TImageFormat.IImageFormat;

	BEGIN

	fCanRead	  := FALSE;
	fReadType1	  := '    ';
	fReadType2	  := '    ';
	fReadType3	  := '    ';
	fUsesDataFork := FALSE;
	fUsesRsrcFork := FALSE;
	fFileType	  := '????';
	fFileCreator  := kSignature

	END;

{*****************************************************************************}

{$S AWriteFile}

FUNCTION TImageFormat.CanWrite (doc: TImageDocument): BOOLEAN;

	BEGIN
	CanWrite := FALSE
	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TImageFormat.SetFormatOptions (doc: TImageDocument);

	BEGIN
	END;

{*****************************************************************************}

{$S ANonRes}

PROCEDURE TImageFormat.DoRead
		(doc: TImageDocument; refNum: INTEGER; rsrcExists: BOOLEAN);

	BEGIN

	{$IFC qDebug}
	ProgramBreak ('Need to override DoRead')
	{$ENDC}

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TImageFormat.ReadOther (doc: TImageDocument; name: Str255);

	BEGIN
	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TImageFormat.AboutToSave (doc: TImageDocument;
									itsCmd: INTEGER;
									VAR name: Str255;
									VAR vRefNum: INTEGER;
									VAR makingCopy: BOOLEAN);

	BEGIN
	END;

{*****************************************************************************}

{$S AWriteFile}

FUNCTION TImageFormat.DataForkBytes (doc: TImageDocument): LONGINT;

	BEGIN
	DataForkBytes := 0
	END;

{*****************************************************************************}

{$S AWriteFile}

FUNCTION TImageFormat.RsrcForkBytes (doc: TImageDocument): LONGINT;

	BEGIN
	RsrcForkBytes := 0
	END;

{*****************************************************************************}

{$S ANonRes}

PROCEDURE TImageFormat.DoWrite (doc: TImageDocument; refNum: INTEGER);

	BEGIN

	{$IFC qDebug}
	ProgramBreak ('Need to override DoWrite')
	{$ENDC}

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TImageFormat.WriteOther (doc: TImageDocument; name: Str255);

	BEGIN
	END;

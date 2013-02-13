{Photoshop version 1.0.1, file: UPreferences.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UPreferences;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	SysEqu, UDialog, UBWDialog, USeparation;

PROCEDURE InitPreferences;

PROCEDURE SavePreferences;

PROCEDURE DoPreferencesCommand;

IMPLEMENTATION

{$I UPick.p.inc}
{$I UScreen.p.inc}

CONST

	kPrefsVersion = 37;

	kPrefsLocID = 1000;

	kPrefsType = '8BPF';

TYPE

	PPreferences = ^TPreferences;
	HPreferences = ^PPreferences;

	Str31 = STRING [31];
	Str63 = STRING [63];

	TFileLocation = RECORD
		fFileName : Str63;
		fVolName  : Str31;
		fDirName  : Str31;
		fDirID	  : LONGINT
		END;

	PFileLocation = ^TFileLocation;
	HFileLocation = ^PFileLocation;

VAR
	gNewFile: BOOLEAN;

{*****************************************************************************}

{$S AInit}

FUNCTION GetPrefsHook (item: INTEGER; theDialog: DialogPtr): INTEGER;

	CONST
		kNewItem = 11;

	BEGIN

	IF item = kNewItem THEN
		BEGIN
		gNewFile := TRUE;
		GetPrefsHook := getCancel
		END

	ELSE
		GetPrefsHook := item;

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE AskUserForFile (VAR name: Str63);

	CONST
		kGetPrefsID = 1402;

	VAR
		err: OSErr;
		where: Point;
		reply: SFReply;
		prompt: Str255;
		typeList: SFTypeList;

	BEGIN

	gNewFile := FALSE;

	typeList [0] := kPrefsType;

	WhereToPlaceDialog (kGetPrefsID, where);

	SFPGetFile (where, '', NIL, 1, typeList,
				@GetPrefsHook, reply, kGetPrefsID, NIL);

	IF gNewFile THEN
		BEGIN

		GetIndString (prompt, kStringsID, strSavePreferencesIn);
		
		WhereToPlaceDialog (putDlgID, where);
		
		SFPutFile (where, prompt, name, NIL, reply);
		IF NOT reply.good THEN Failure (0, 0);
		
		err := Create (reply.fName, reply.vRefNum, kSignature, kPrefsType);
		
		IF err = dupFNErr THEN
			BEGIN
			FailOSErr (DeleteFile (@reply.fName, reply.vRefNum));
			err := Create (reply.fName, reply.vRefNum, kSignature, kPrefsType)
			END;
			
		FailOSErr (err)

		END

	ELSE IF NOT reply.good THEN Failure (0, 0);

	gPouchRefNum := reply.vRefNum;

	name := reply.fName

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE CloseMyWD (refNum: INTEGER);

	VAR
		error: OSErr;
		wdBlk: WDPBRec;

	BEGIN

	WITH wdBlk DO
		BEGIN
		ioNamePtr := NIL;
		ioVRefNum := refNum;
		ioWDDirID := 0;
		ioWDIndex := 0
		END;

	IF PBGetWDInfo (@wdBlk, FALSE) = noErr THEN
		IF wdBlk.ioWDProcID = LONGINT (kSignature) THEN
			error := PBCloseWD (@wdBlk, FALSE)

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE OpenPreferencesFile (VAR fRefNum: INTEGER);

	VAR
		wdBlk: WDPBRec;
		update: BOOLEAN;
		opened: BOOLEAN;
		catBlk: CInfoPBRec;
		saveVolume: INTEGER;
		volBlk: HParamBlockRec;
		fileLocation: HFileLocation;

	BEGIN

	fileLocation := HFileLocation (Get1Resource ('FLoc', kPrefsLocID));

	FailNil (fileLocation);

	MoveHHi (Handle (fileLocation));
	HLock	(Handle (fileLocation));

	update := TRUE;
	opened := FALSE;

	IF LENGTH (fileLocation^^.fVolName) <> 0 THEN
		BEGIN

		FailOSErr (GetVol (NIL, saveVolume));

		IF SetVol (@fileLocation^^.fVolName, 0) = noErr THEN
			BEGIN

			FailOSErr (GetVol (NIL, gPouchRefNum));

			WITH wdBlk DO
				BEGIN
				ioNamePtr  := NIL;
				ioVRefNum  := gPouchRefNum;
				ioWDDirID  := fileLocation^^.fDirID;
				ioWDProcID := LONGINT (kSignature)
				END;

			IF PBOpenWD (@wdBlk, FALSE) = noErr THEN
				BEGIN

				gPouchRefNum := wdBlk.ioVRefNum;

				IF FSOpen (fileLocation^^.fFileName,
						   gPouchRefNum,
						   fRefNum) = noErr THEN
					BEGIN
					update := FALSE;
					opened := TRUE
					END
				ELSE
					CloseMyWD (gPouchRefNum)

				END

			END;

		FailOSErr (SetVol (NIL, saveVolume))

		END;

	IF NOT opened THEN
		BEGIN

		gPouchRefNum := 0;

		opened := FSOpen (fileLocation^^.fFileName,
						  gPouchRefNum,
						  fRefNum) = noErr

		END;

	IF NOT opened THEN
		BEGIN

		WITH catBlk DO
			BEGIN
			ioNamePtr	 := @fileLocation^^.fDirName;
			ioVRefNum	 := 0;
			ioFDirIndex  := 0;
			ioDrDirID	 := 0
			END;

		IF PBGetCatInfo (@catBlk, FALSE) = noErr THEN
			IF BTST (catBlk.ioFlAttrib, 4) THEN
				BEGIN

				WITH wdBlk DO
					BEGIN
					ioNamePtr  := NIL;
					ioVRefNum  := 0;
					ioWDDirID  := catBlk.ioDrDirID;
					ioWDProcID := LONGINT (kSignature)
					END;

				IF PBOpenWD (@wdBlk, FALSE) = noErr THEN
					BEGIN

					gPouchRefNum := wdBlk.ioVRefNum;

					IF FSOpen (fileLocation^^.fFileName,
							   gPouchRefNum,
							   fRefNum) = noErr THEN
						opened := TRUE
					ELSE
						CloseMyWD (gPouchRefNum)

					END

				END

		END;

	IF opened THEN
		BEGIN

		WITH catBlk DO
			BEGIN
			ioNamePtr	 := @fileLocation^^.fFileName;
			ioVRefNum	 := gPouchRefNum;
			ioFDirIndex  := 0;
			ioDrDirID	 := 0
			END;

		FailOSErr (PBGetCatInfo (@catBlk, FALSE));

		IF BTST (catBlk.ioFlAttrib, 4) OR
		   (catBlk.ioFlFndrInfo.fdType <> kPrefsType) THEN
			BEGIN

			FailOSErr (FSClose (fRefNum));

			opened := FALSE;
			update := TRUE

			END

		ELSE IF catBlk.ioFlParID <> fileLocation^^.fDirID THEN
			BEGIN

			WITH wdBlk DO
				BEGIN
				ioNamePtr  := NIL;
				ioVRefNum  := gPouchRefNum;
				ioWDDirID  := catBlk.ioFlParID;
				ioWDProcID := LONGINT (kSignature)
				END;

			FailOSErr (PBOpenWD (@wdBlk, FALSE));

			gPouchRefNum := wdBlk.ioVRefNum;

			update := TRUE

			END

		END;

	IF NOT opened THEN
		BEGIN

		AskUserForFile (fileLocation^^.fFileName);

		FailOSErr (FSOpen (fileLocation^^.fFileName,
						   gPouchRefNum,
						   fRefNum))

		END;

	IF update THEN
		BEGIN

		WITH volBlk DO
			BEGIN
			ioNamePtr	 := @fileLocation^^.fVolName;
			ioVRefNum	 := gPouchRefNum;
			ioVolIndex	 := 0
			END;

		FailOSErr (PBHGetVInfo (@volBlk, FALSE));

		INSERT (':', fileLocation^^.fVolName,
				LENGTH (fileLocation^^.fVolName) + 1);

		WITH catBlk DO
			BEGIN
			ioNamePtr	 := @fileLocation^^.fDirName;
			ioVRefNum	 := gPouchRefNum;
			ioFDirIndex  := -1;
			ioDrDirID	 := 0
			END;

		FailOSErr (PBGetCatInfo (@catBlk, FALSE));

		fileLocation^^.fDirID := catBlk.ioDrDirID;

		ChangedResource (Handle (fileLocation));
		WriteResource	(Handle (fileLocation))

		END;

	HUnlock (Handle (fileLocation));

	FailOSErr (SetVol (NIL, gPouchRefNum))

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitPreferences;

	VAR
		error: OSErr;
		count: LONGINT;
		version: INTEGER;
		fRefNum: INTEGER;
		preferences: HPreferences;

	PROCEDURE ReadSpot (VAR spec: THalftoneSpec);

		BEGIN

		count := -spec.shape;

		IF count > 0 THEN
			BEGIN

			spec.spot := NewPermHandle (count);
			FailNil (spec.spot);

			RegisterSpot (spec.spot);

			HLock (spec.spot);
			FailOSErr (FSRead (fRefNum, count, spec.spot^));
			HUnlock (spec.spot)

			END

		END;

	BEGIN

	preferences := HPreferences (Get1Resource ('OPTs', 1000));

	IF preferences = NIL THEN Failure (1, 0);

	gPreferences := preferences^^;

	ReleaseResource (Handle (preferences));

	GetBlackTables (gPreferences.fSeparation.fGCRTable,
					gPreferences.fSeparation.fUCRTable,
					gPreferences.fSeparation.fBlackID);

	{$IFC NOT qPlugIns}
	
	gPouchRefNum := PInteger (BootDrive)^;
	
	{$ELSEC}
	
	OpenPreferencesFile (fRefNum);

	count := SIZEOF (INTEGER);

	error := FSRead (fRefNum, count, @version);

	IF (error = noErr) AND (version = kPrefsVersion) THEN
		BEGIN

		count := SIZEOF (TPreferences);

		FailOSErr (FSRead (fRefNum, count, @gPreferences));

		ReadSpot (gPreferences.fHalftone);

		ReadSpot (gPreferences.fHalftones [0]);
		ReadSpot (gPreferences.fHalftones [1]);
		ReadSpot (gPreferences.fHalftones [2]);
		ReadSpot (gPreferences.fHalftones [3])

		END;

	FailOSErr (FSClose (fRefNum));

	{$ENDC}
	
	{$IFC qDemo}
	gPreferences.fClipOption := 0;
	{$ENDC}
	
	InitCMYK

	END;

{*****************************************************************************}

{$S ATerminate}

PROCEDURE SavePreferences;

	{$IFC qPlugIns}

	LABEL
		1;

	VAR
		name: Str63;
		fi: FailInfo;
		ignore: OSErr;
		count: LONGINT;
		version: INTEGER;
		fRefNum: INTEGER;
		fileLocation: HFileLocation;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		ignore := SetEOF (fRefNum, 0);
		GOTO 1
		END;

	PROCEDURE WriteSpot (spec: THalftoneSpec);

		BEGIN

		count := -spec.shape;

		IF count > 0 THEN
			BEGIN
			HLock (spec.spot);
			FailOSErr (FSWrite (fRefNum, count, spec.spot^));
			HUnlock (spec.spot)
			END

		END;
		
	{$ENDC}

	BEGIN
	
	{$IFC qPlugIns}

	fileLocation := HFileLocation (Get1Resource ('FLoc', kPrefsLocID));

	IF fileLocation <> NIL THEN
		BEGIN

		name := fileLocation^^.fFileName;

		IF FSOpen (name, gPouchRefNum, fRefNum) = noErr THEN
			BEGIN

			CatchFailures (fi, CleanUp);

			version := kPrefsVersion;
			count	:= SIZEOF (INTEGER);
			FailOSErr (FSWrite (fRefNum, count, @version));

			count  := SIZEOF (TPreferences);
			FailOSErr (FSWrite (fRefNum, count, @gPreferences));

			WriteSpot (gPreferences.fHalftone);

			WriteSpot (gPreferences.fHalftones [0]);
			WriteSpot (gPreferences.fHalftones [1]);
			WriteSpot (gPreferences.fHalftones [2]);
			WriteSpot (gPreferences.fHalftones [3]);

			Success (fi);

			1:	{ Continue after failure }

			ignore := FSClose (fRefNum);
			ignore := FlushVol (NIL, gPouchRefNum)

			END

		END;

	CloseMyWD (gPouchRefNum)
	
	{$ENDC}

	END;

{*****************************************************************************}

{$S APreferences}

PROCEDURE DoPreferencesCommand;

	CONST
		kDialogID		 = 1002;
		kHookItem		 = 3;
		kColorItem		 = 4;
		kSystemItem 	 = 5;
		kDirectItem 	 = 6;
		kFirstClipItem	 = 7;
		kLastClipItem	 = 14;
		kFirstMethodItem = 15;
		kLastMethodItem  = 17;
		kWidthItem		 = 18;
		kGutterItem 	 = 20;
		kInkColorsItem	 = 22;

	VAR
		fi: FailInfo;
		item: INTEGER;
		newSystem: BOOLEAN;
		oldColumn: INTEGER;
		scaled: FixedScaled;
		aBWDialog: TBWDialog;
		newColorize: BOOLEAN;
		setup: TSeparationSetup;
		widthUnit: TUnitSelector;
		colorCheckBox: TCheckBox;
		gutterUnit: TUnitSelector;
		systemCheckBox: TCheckBox;
		directCheckBox: TCheckBox;
		clipCluster: TRadioCluster;
		methodCluster: TRadioCluster;
		
		{$IFC qDemo}
		r: Rect;
		h: Handle;
		itemType: INTEGER;
		{$ENDC}

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free;
		InitCMYK;
		InvalidateCMYKPicker
		END;

	PROCEDURE FixRulers (view: TImageView);
		BEGIN
		view.InvalRulers
		END;

	PROCEDURE FixColorize (view: TImageView);

		VAR
			band: INTEGER;
			subtractive: BOOLEAN;

		BEGIN
		gPreferences.fColorize := TRUE;
		IF view.ColorizeBand (band, subtractive) THEN
			BEGIN
			gPreferences.fColorize := newColorize;
			view.ReDither (TRUE)
			END
		END;

	PROCEDURE FixSystem (view: TImageView);
		BEGIN
		view.ReDither (TRUE)
		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	WITH gPreferences DO
		BEGIN

		setup := fSeparation;

		colorCheckBox  := aBWDialog.DefineCheckBox (kColorItem , fColorize);
		systemCheckBox := aBWDialog.DefineCheckBox (kSystemItem, fUseSystem);
		directCheckBox := aBWDialog.DefineCheckBox (kDirectItem, fUseDirectLUT);

		clipCluster := aBWDialog.DefineRadioCluster
				(kFirstClipItem, kLastClipItem, kFirstClipItem + fClipOption);
				
		{$IFC qDemo}
		FOR item := kFirstClipItem + 1 TO kLastClipItem DO
			BEGIN
			GetDItem (aBWDialog.fDialogPtr, item, itemType, h, r);
			HiliteControl (ControlHandle (h), 255);
			END;
		{$ENDC}

		methodCluster := aBWDialog.DefineRadioCluster
				(kFirstMethodItem, kLastMethodItem,
				 kFirstMethodItem + fInterpolate);

		oldColumn := fColumnWidth.scale;

		widthUnit := aBWDialog.DefineSizeUnit (kWidthItem,
											   fColumnWidth.scale,
											   FALSE, FALSE, FALSE,
											   FALSE, FALSE);

		widthUnit . StuffFixed (0, fColumnWidth.value);

		gutterUnit := aBWDialog.DefineSizeUnit (kGutterItem,
												fColumnGutter.scale,
												FALSE, FALSE, FALSE,
												TRUE, FALSE);

		gutterUnit . StuffFixed (0, fColumnGutter.value);

		aBWDialog.SetEditSelection (kWidthItem);

			REPEAT

			aBWDialog.TalkToUser (item, StdItemHandling);

			IF item = cancel THEN Failure (0, 0);

			IF item = kInkColorsItem THEN
				DoSeparationSetup (setup)

			UNTIL item = ok;

		newColorize := colorCheckBox .fChecked;
		newSystem	:= systemCheckBox.fChecked;

		fUseDirectLUT := directCheckBox.fChecked;

		fClipOption := clipCluster.fChosenItem - kFirstClipItem;

		fInterpolate := methodCluster.fChosenItem - kFirstMethodItem;

		fColumnWidth.value := widthUnit . GetFixed (0);
		fColumnWidth.scale := widthUnit . fPick;

		fColumnGutter.value := gutterUnit . GetFixed (0);
		fColumnGutter.scale := gutterUnit . fPick;

		fSeparation := setup;

		Success (fi);

		CleanUp (0, 0);

		IF oldColumn <> fColumnWidth.scale THEN
			ForAllImageViewsDo (FixRulers);

		IF newColorize <> fColorize THEN
			BEGIN
			ForAllImageViewsDo (FixColorize);
			fColorize := newColorize
			END;

		IF newSystem <> fUseSystem THEN
			BEGIN
			fUseSystem := newSystem;
			ForAllImageViewsDo (FixSystem)
			END

		END

	END;

{*****************************************************************************}

END.

{Photoshop version 1.0.1, file: UScan.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UScan;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UCommands, UProgress, AcquireInterface, ExportInterface;

PROCEDURE VerifyHardware;

PROCEDURE InitScanners;

PROCEDURE DoAcquireCommand (name: Str255);

PROCEDURE DoExportCommand (doc: TImageDocument; name: Str255);

IMPLEMENTATION

{$I UAssembly.a.inc}

CONST
	kPSAcquireType = '8BAM';
	kDDAcquireType = 'G8im';
	kBWAcquireType = 'BWim';

	kPSExportType = '8BEM';

VAR
	gPlugInName: Str255;

{*****************************************************************************}

{$IFC qBarneyscan}

{$S AInit}

FUNCTION IsBarneyscanInstalled (info: HPlugInInfo): BOOLEAN;

	VAR
		h: Handle;
		fi: FailInfo;
		data: LONGINT;
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

	data := info^^.fData;

	DoCallPlugIn (-100, NIL, data, result, StripAddress (h^));

	info^^.fData := data;

	IsBarneyscanInstalled := (result = 31462);

	HUnlock (h);
	HPurge (h);

	Success (fi);
	CleanUp (0, 0)

	END;

{$ENDC}

{*****************************************************************************}

{$S AInit}

PROCEDURE VerifyHardware;

	VAR
		info: HPlugInInfo;

	BEGIN

	{$IFC qBarneyscan}

	info := gFirstPSAcquire;

	WHILE info <> NIL DO
		BEGIN
		IF IsBarneyscanInstalled (info) THEN
			EXIT (VerifyHardware);
		info := info^^.fNext
		END;

	Failure (errNoBarneyscan, 0)

	{$ENDC}

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitScanners;

	BEGIN

	gFirstPSAcquire := NIL;
	gFirstDDAcquire := NIL;
	gFirstBWAcquire := NIL;
	gFirstPSExport  := NIL;
	
	{$IFC qPlugIns}
	
	InitPlugInList (kPSAcquireType, 1, 3, gFirstPSAcquire, cAcquire);

	{$IFC NOT qBarneyscan}

	InitPlugInList (kDDAcquireType, 1, 1, gFirstDDAcquire, cAcquire);
	InitPlugInList (kBWAcquireType, 1, 1, gFirstBWAcquire, cAcquire);

	{$ENDC}

	CheckForNoPlugIns (cAcquire);

	{$IFC NOT qBarneyscan}

	InitPlugInList (kPSExportType, 1, 3, gFirstPSExport, cExport);

	CheckForNoPlugIns (cExport)

	{$ENDC}
	
	{$ENDC}

	END;

{*****************************************************************************}

{$S AScan}

PROCEDURE AcquireResolution (doc: TImageDocument; resolution: Fixed);

	BEGIN

	IF (resolution >= $10000) AND (resolution <= 3200 * $10000) THEN
	   doc.fStyleInfo.fResolution.value := resolution

	END;

{*****************************************************************************}

{$S AScan}

PROCEDURE PSPlugInAcquire (doc: TImageDocument;
						   info: HPlugInInfo;
						   codeAddress: Ptr);

	VAR
		r: Rect;
		s: Str255;
		srcPtr: Ptr;
		dstPtr: Ptr;
		buffer: Ptr;
		fi: FailInfo;
		row: INTEGER;
		width: INTEGER;
		space: LONGINT;
		result: INTEGER;
		channel: INTEGER;
		aVMArray: TVMArray;
		callFinish: BOOLEAN;
		stuff: AcquireRecord;
		killProgress: BOOLEAN;

	PROCEDURE DoCallAcquire (selector: INTEGER;
							 stuff: AcquireRecordPtr;
							 VAR data: LONGINT;
							 VAR result: INTEGER;
							 codeAddress: Ptr); INLINE $205F, $4E90;

	PROCEDURE CallAcquire (selector: INTEGER);

		VAR
			data: LONGINT;

		BEGIN

		data := info^^.fData;

		DoCallAcquire (selector, @stuff, data, result, codeAddress);

		info^^.fData := data

		END;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		IF killProgress THEN
			FinishProgress;

		IF buffer <> NIL THEN
			DisposPtr (buffer);

		IF callFinish THEN
			CallAcquire (acquireSelectorFinish);

		VMAdjustReserve (-space)

		END;

	BEGIN

	space := VMCanReserve;
	space := space - BSR (space, 4);

	stuff.serialNumber := gSerialNumber;
	stuff.abortProc    := @TestAbort;
	stuff.progressProc := @UpdateProgress;
	stuff.maxData	   := space;
	stuff.filename	   := doc.fTitle;
	stuff.vRefNum	   := 0;
	stuff.dirty 	   := TRUE;

	IF info^^.fVersion >= 3 THEN
		BEGIN
		CallAcquire (acquireSelectorPrepare);
		IF result <> 0 THEN Failure (Min (result, 0), 0);
		END;

	{$IFC qDebug}
	writeln ('Memory: ', space:1, ' -> ', stuff.maxData:1);
	{$ENDC}

	space := stuff.maxData;

	VMAdjustReserve (space);

	buffer := NIL;
	callFinish := FALSE;
	killProgress := FALSE;

	CatchFailures (fi, CleanUp);

	SetCursor (arrow);

	CallAcquire (acquireSelectorStart);
	IF result <> 0 THEN Failure (Min (result, 0), 0);

	callFinish := TRUE;

	MoveHands (TRUE);

	CmdToName (cAcquire, s);

	INSERT (':  ', s, LENGTH (s) + 1);
	INSERT (gPlugInName, s, LENGTH (s) + 1);

	StartProgress (s);
	killProgress := TRUE;

	IF (stuff.imageMode < acquireModeBitmap) OR
	   (stuff.imageMode > acquireModeMultichannel) THEN
		Failure (acquireBadParameters, 0);

	doc.fMode	  := TDisplayMode (stuff.imageMode);
	doc.fRows	  := stuff.imageSize.v;
	doc.fCols	  := stuff.imageSize.h;
	doc.fDepth	  := stuff.depth;
	doc.fChannels := stuff.planes;

	AcquireResolution (doc, stuff.imageVRes);

	IF NOT doc.ValidSize THEN Failure (acquireBadParameters, 0);

	IF (doc.fMode = HalftoneMode) <> (doc.fDepth = 1) THEN
		Failure (acquireBadParameters, 0);

		CASE doc.fMode OF

		HalftoneMode,
		MonochromeMode,
		IndexedColorMode:
			IF doc.fChannels <> 1 THEN
				Failure (acquireBadParameters, 0);

		{$IFC qBarneyscan}
		SeparationsCMYK:
			Failure (errNoCMYK, 0);
		{$ENDC}

		OTHERWISE
			IF doc.fChannels < doc.Interleave (0) THEN
				Failure (acquireBadParameters, 0)

		END;

	doc.fIndexedColorTable.R := TLookUpTable (stuff.redLUT);
	doc.fIndexedColorTable.G := TLookUpTable (stuff.greenLUT);
	doc.fIndexedColorTable.B := TLookUpTable (stuff.blueLUT);

	FOR channel := 0 TO doc.fChannels - 1 DO
		BEGIN

		IF doc.fDepth = 1 THEN
			aVMArray := NewVMArray (doc.fRows,
									BSL (BSR (doc.fCols + 15, 4), 1),
									1)
		ELSE
			aVMArray := NewVMArray (doc.fRows,
									doc.fCols,
									doc.Interleave (channel));

		doc.fData [channel] := aVMArray

		END;

	WHILE TRUE DO
		BEGIN

		MoveHands (TRUE);

		CallAcquire (acquireSelectorContinue);

		IF result <> 0 THEN Failure (Min (result, 0), 0);

		IF stuff.data = NIL THEN LEAVE;

		IF info^^.fVersion <= 2 THEN
			buffer := stuff.data;

		r := stuff.theRect;

		IF (r.top	 < 0		) OR
		   (r.left	 < 0		) OR
		   (r.bottom > doc.fRows) OR
		   (r.right  > doc.fCols) THEN Failure (acquireBadParameters, 0);

		IF (stuff.loPlane < 0) OR (stuff.hiPlane >= doc.fChannels) THEN
			Failure (acquireBadParameters, 0);

		{$IFC qDebug}
		write (stuff.loPlane:1, '-', stuff.hiPlane:1, ': ');
		writeRect (r);
		writeln;
		{$ENDC}

		FOR channel := stuff.loPlane TO stuff.hiPlane DO
			BEGIN

			srcPtr := Ptr (ORD4 (stuff.data) +
						   stuff.planeBytes * (channel - stuff.loPlane));

			FOR row := r.top TO r.bottom - 1 DO
				BEGIN

				MoveHands (TRUE);

				dstPtr := doc.fData [channel] . NeedPtr (row, row, TRUE);

				IF doc.fDepth = 1 THEN
					BEGIN
					dstPtr := Ptr (ORD4 (dstPtr) + BSR (r.left, 3));
					width  := BSR (r.right - r.left + 7, 3)
					END
				ELSE
					BEGIN
					dstPtr := Ptr (ORD4 (dstPtr) + r.left);
					width  := r.right - r.left
					END;

				DoStepCopyBytes (srcPtr, dstPtr, width, stuff.colBytes, 1);

				doc.fData [channel] . DoneWithPtr;

				srcPtr := Ptr (ORD4 (srcPtr) + stuff.rowBytes)

				END;

			doc.fData [channel] . Flush

			END;

		IF buffer <> NIL THEN
			DisposPtr (buffer);

		buffer := NIL

		END;

	UpdateProgress (1, 1);

	Success (fi);

	FinishProgress;

	CallAcquire (acquireSelectorFinish);

	VMAdjustReserve (-space);

	IF result <> 0 THEN Failure (Min (result, 0), 0);

	IF LENGTH (stuff.filename) <> 0 THEN
		doc.SetTitle (stuff.filename);

	doc.fVolRefNum := stuff.vRefNum;

	IF NOT stuff.dirty THEN
		doc.fChangeCount := 0

	END;

{*****************************************************************************}

{$S AScan}

PROCEDURE DDPlugInAcquire (doc: TImageDocument;
						   info: HPlugInInfo;
						   codeAddress: Ptr);

	TYPE
		AqStruct = RECORD
			thePix: PixMapPtr;
			END;
		PAqStruct = ^AqStruct;

	VAR
		buffer: Ptr;
		fi: FailInfo;
		row: INTEGER;
		size: LONGINT;
		space: LONGINT;
		aPixMap: PixMap;
		stuff: AqStruct;
		result: INTEGER;
		rowBytes: LONGINT;
		aVMArray: TVMArray;
		fixReserve: BOOLEAN;

	PROCEDURE DoCallAcquire (selector: INTEGER;
							 stuff: PAqStruct;
							 VAR data: LONGINT;
							 VAR result: INTEGER;
							 codeAddress: Ptr); INLINE $205F, $4E90;

	PROCEDURE CallAcquire (selector: INTEGER);

		VAR
			data: LONGINT;

		BEGIN

		data := info^^.fData;

		DoCallAcquire (selector, @stuff, data, result, codeAddress);

		info^^.fData := data

		END;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		IF buffer <> NIL THEN
			DisposPtr (buffer);

		IF fixReserve THEN
			VMAdjustReserve (-space)

		END;

	BEGIN

	buffer := NIL;
	fixReserve := FALSE;

	CatchFailures (fi, CleanUp);

	space := VMCanReserve;
	space := space - BSR (space, 4);

	VMAdjustReserve (space);
	fixReserve := TRUE;

	aPixMap.baseAddr := NIL;

	stuff.thePix := @aPixMap;

	SetCursor (arrow);

	CallAcquire (1);

	IF result <> 0 THEN Failure (0, 0);

	buffer := aPixMap.baseAddr;

	IF buffer = NIL THEN Failure (0, 0);

	size := GetPtrSize (buffer);

	IF size = 0 THEN Failure (0, 0);

	IF size > space THEN Failure (memFullErr, 0);

	IF (aPixMap.bounds.top	<> 0) OR
	   (aPixMap.bounds.left <> 0) OR
	   (aPixMap.pixelSize	<> 8) THEN Failure (acquireBadParameters, 0);

	doc.fRows := aPixMap.bounds.bottom;
	doc.fCols := aPixMap.bounds.right;

	AcquireResolution (doc, aPixMap.vRes);

	doc.DefaultMode;

	IF NOT doc.ValidSize THEN Failure (acquireBadParameters, 0);

	aVMArray := NewVMArray (doc.fRows, doc.fCols, 1);

	doc.fData [0] := aVMArray;

	rowBytes := BAND ($7FFF, aPixMap.rowBytes);

	FOR row := 0 TO doc.fRows - 1 DO
		BEGIN

		MoveHands (TRUE);

		BlockMove (Ptr (ORD4 (buffer) + row * rowBytes),
				   aVMArray.NeedPtr (row, row, TRUE),
				   doc.fCols);

		aVMArray.DoneWithPtr

		END;

	aVMArray.MapBytes (gInvertLUT);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S AScan}

PROCEDURE BWPlugInAcquire (doc: TImageDocument;
						   info: HPlugInInfo;
						   codeAddress: Ptr);

	TYPE
		AqStruct = RECORD
			theBits: ^BitMap;
			hRes   : Fixed;
			vRes   : Fixed
			END;
		PAqStruct = ^AqStruct;

	VAR
		buffer: Ptr;
		fi: FailInfo;
		row: INTEGER;
		size: LONGINT;
		width: INTEGER;
		space: LONGINT;
		aBitMap: BitMap;
		stuff: AqStruct;
		result: INTEGER;
		rowBytes: LONGINT;
		aVMArray: TVMArray;
		fixReserve: BOOLEAN;

	PROCEDURE DoCallAcquire (selector: INTEGER;
							 stuff: PAqStruct;
							 VAR data: LONGINT;
							 VAR result: INTEGER;
							 codeAddress: Ptr); INLINE $205F, $4E90;

	PROCEDURE CallAcquire (selector: INTEGER);

		VAR
			data: LONGINT;

		BEGIN

		data := info^^.fData;

		DoCallAcquire (selector, @stuff, data, result, codeAddress);

		info^^.fData := data

		END;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		IF buffer <> NIL THEN
			DisposPtr (buffer);

		IF fixReserve THEN
			VMAdjustReserve (-space)

		END;

	BEGIN

	buffer := NIL;
	fixReserve := FALSE;

	CatchFailures (fi, CleanUp);

	space := VMCanReserve;
	space := space - BSR (space, 4);

	VMAdjustReserve (space);
	fixReserve := TRUE;

	aBitMap.baseAddr := NIL;

	stuff.theBits := @aBitMap;
	stuff.hRes	  := 0;
	stuff.vRes	  := 0;

	SetCursor (arrow);

	CallAcquire (1);

	IF result <> 0 THEN Failure (0, 0);

	buffer := aBitMap.baseAddr;

	IF buffer = NIL THEN Failure (0, 0);

	size := GetPtrSize (buffer);

	IF size = 0 THEN Failure (0, 0);

	IF size > space THEN Failure (memFullErr, 0);

	IF (aBitMap.bounds.top	<> 0) OR
	   (aBitMap.bounds.left <> 0) THEN Failure (acquireBadParameters, 0);

	doc.fRows  := aBitMap.bounds.bottom;
	doc.fCols  := aBitMap.bounds.right;
	doc.fDepth := 1;

	AcquireResolution (doc, stuff.vRes);

	doc.DefaultMode;

	IF NOT doc.ValidSize THEN Failure (acquireBadParameters, 0);

	width := BSL (BSR (doc.fCols + 15, 4), 1);

	aVMArray := NewVMArray (doc.fRows, width, 1);

	doc.fData [0] := aVMArray;

	rowBytes := aBitMap.rowBytes;

	FOR row := 0 TO doc.fRows - 1 DO
		BEGIN

		MoveHands (TRUE);

		BlockMove (Ptr (ORD4 (buffer) + row * rowBytes),
				   aVMArray.NeedPtr (row, row, TRUE),
				   width);

		aVMArray.DoneWithPtr

		END;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S AScan}

PROCEDURE PlugInAcquire (info: HPlugInInfo);

	VAR
		h: Handle;
		s: Str255;
		fi: FailInfo;
		refNum: INTEGER;
		fileName: Str255;
		saveLimit: INTEGER;
		doc: TImageDocument;

	PROCEDURE FreeStuff;

		BEGIN

		IF h <> NIL THEN
			BEGIN
			HUnlock (h);
			HPurge (h);
			h := NIL
			END;

		IF refNum <> -1 THEN
			BEGIN
			CloseResFile (refNum);
			refNum := -1
			END;

		gVMMinPageLimit := saveLimit

		END;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		FreeObject (doc);

		FreeStuff

		END;

	BEGIN
	
	gApplication.CommitLastCommand;
	
	VMCompress (TRUE);

	h		   := NIL;
	doc 	   := NIL;
	refNum	   := -1;
	saveLimit  := gVMMinPageLimit;

	CatchFailures (fi, CleanUp);

	doc := TImageDocument (gApplication.DoMakeDocument (cAcquire));

	doc.fChangeCount := 1;

	doc.UntitledName (s);
	doc.SetTitle (s);

	gVMMinPageLimit := 1;

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

	IF info^^.fKind = kPSAcquireType THEN
		PSPlugInAcquire (doc, info, StripAddress (h^))

	ELSE IF info^^.fKind = kDDAcquireType THEN
		DDPlugInAcquire (doc, info, StripAddress (h^))

	ELSE
		BWPlugInAcquire (doc, info, StripAddress (h^));

	FreeStuff;

	doc.DoMakeViews (kForDisplay);
	doc.DoMakeWindows;

	gApplication.AddDocument (doc);

	FailSpaceIsLow;

	Success (fi);

	doc.ShowWindows

	END;

{*****************************************************************************}

{$S AScan}

PROCEDURE DoAcquireCommand (name: Str255);

	VAR
		info: HPlugInInfo;

	BEGIN

	gPlugInName := name;

	IF IsPlugIn (name, gFirstPSAcquire, info) THEN
		PlugInAcquire (info)

	ELSE IF IsPlugIn (name, gFirstDDAcquire, info) THEN
		PlugInAcquire (info)

	ELSE IF IsPlugIn (name, gFirstBWAcquire, info) THEN
		PlugInAcquire (info)

	ELSE
		Failure (1, 0)

	END;

{*****************************************************************************}

{$S AScan}

PROCEDURE PSPlugInExport (doc: TImageDocument;
						  info: HPlugInInfo;
						  codeAddress: Ptr);

	VAR
		r: Rect;
		s: Str255;
		srcPtr: Ptr;
		dstPtr: Ptr;
		buffer: Ptr;
		fi: FailInfo;
		row: INTEGER;
		fi2: FailInfo;
		width: INTEGER;
		space: LONGINT;
		result: INTEGER;
		needed: LONGINT;
		channel: INTEGER;
		stuff: ExportRecord;

	PROCEDURE DoCallExport (selector: INTEGER;
							stuff: ExportRecordPtr;
							VAR data: LONGINT;
							VAR result: INTEGER;
							codeAddress: Ptr); INLINE $205F, $4E90;

	PROCEDURE CallExport (selector: INTEGER);

		VAR
			data: LONGINT;

		BEGIN

		data := info^^.fData;

		DoCallExport (selector, @stuff, data, result, codeAddress);

		info^^.fData := data

		END;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		FinishProgress;

		IF buffer <> NIL THEN
			DisposPtr (buffer);

		CallExport (exportSelectorFinish)

		END;

	PROCEDURE CheckResult;

		BEGIN

		IF result <> 0 THEN
			IF result = exportBadMode THEN
				Failure (exportBadMode - ORD (doc.fMode), 0)
			ELSE
				Failure (Min (result, 0), 0)

		END;

	PROCEDURE FixReserve (error: INTEGER; message: LONGINT);
		BEGIN
		VMAdjustReserve (-space)
		END;

	BEGIN

	space := VMCanReserve;
	space := space - BSR (space, 4);

	stuff.serialNumber := gSerialNumber;
	stuff.abortProc    := @TestAbort;
	stuff.progressProc := @UpdateProgress;
	stuff.maxData	   := space;
	stuff.imageMode    := ORD (doc.fMode);
	stuff.imageSize.v  := doc.fRows;
	stuff.imageSize.h  := doc.fCols;
	stuff.depth 	   := doc.fDepth;
	stuff.planes	   := doc.fChannels;
	stuff.imageHRes    := doc.fStyleInfo.fResolution.value;
	stuff.imageVRes    := doc.fStyleInfo.fResolution.value;
	stuff.redLUT	   := doc.fIndexedColorTable.R;
	stuff.greenLUT	   := doc.fIndexedColorTable.G;
	stuff.blueLUT	   := doc.fIndexedColorTable.B;
	stuff.filename	   := doc.fTitle;
	stuff.vRefNum	   := doc.fVolRefNum;
	stuff.dirty 	   := TRUE;
	stuff.selectBBox   := doc.fSelectionRect;

	IF info^^.fVersion >= 3 THEN
		BEGIN
		CallExport (exportSelectorPrepare);
		IF result <> 0 THEN Failure (Min (result, 0), 0);
		END;

	{$IFC qDebug}
	writeln ('Memory: ', space:1, ' -> ', stuff.maxData:1);
	{$ENDC}

	space := stuff.maxData;

	VMAdjustReserve (space);

	CatchFailures (fi2, FixReserve);

	SetSFDirectory (doc.fVolRefNum);

	SetCursor (arrow);

	CallExport (exportSelectorStart);

	CheckResult;

	buffer := NIL;

	CmdToName (cExport, s);

	INSERT (':  ', s, LENGTH (s) + 1);
	INSERT (gPlugInName, s, LENGTH (s) + 1);

	StartProgress (s);

	CatchFailures (fi, CleanUp);

	WHILE NOT EmptyRect (stuff.theRect) DO
		BEGIN

		MoveHands (TRUE);

		r := stuff.theRect;

		{$IFC qDebug}
		write (stuff.loPlane:1, '-', stuff.hiPlane:1, ': ');
		writeRect (r);
		writeln;
		{$ENDC}

		IF (r.left < 0) OR (r.right  > doc.fCols) OR
		   (r.top  < 0) OR (r.bottom > doc.fRows) OR
				(stuff.loPlane < 0) OR
				(stuff.hiPlane >= doc.fChannels) OR
				(stuff.loPlane > stuff.hiPlane) THEN
			Failure (exportBadParameters, 0);

		IF doc.fMode = HalftoneMode THEN
			BEGIN

			IF r.left MOD 8 <> 0 THEN
				Failure (exportBadParameters, 0);

			stuff.rowBytes := BSR (r.right - r.left + 7, 3)

			END

		ELSE
			stuff.rowBytes := ORD4 (r.right - r.left) *
							  (stuff.hiPlane - stuff.loPlane + 1);

		needed := stuff.rowBytes * (r.bottom - r.top);

		IF needed > space THEN Failure (memFullErr, 0);

		IF (buffer = NIL) | (GetPtrSize (buffer) < needed) THEN
			BEGIN

			IF buffer <> NIL THEN
				BEGIN
				DisposPtr (buffer);
				buffer := NIL
				END;

			buffer := NewPtr (needed);

			IF buffer = NIL THEN
				Failure (memFullErr, 0)

			END;

		stuff.data := buffer;

		FOR channel := stuff.loPlane TO stuff.hiPlane DO
			BEGIN

			dstPtr := Ptr (ORD4 (buffer) + channel - stuff.loPlane);

			FOR row := r.top TO r.bottom - 1 DO
				BEGIN

				MoveHands (TRUE);

				srcPtr := doc.fData [channel] . NeedPtr (row, row, TRUE);

				IF doc.fDepth = 1 THEN
					BEGIN
					srcPtr := Ptr (ORD4 (srcPtr) + BSR (r.left, 3));
					width  := BSR (r.right - r.left + 7, 3)
					END
				ELSE
					BEGIN
					srcPtr := Ptr (ORD4 (srcPtr) + r.left);
					width  := r.right - r.left
					END;

				DoStepCopyBytes (srcPtr, dstPtr, width, 1,
								 stuff.hiPlane - stuff.loPlane + 1);

				doc.fData [channel] . DoneWithPtr;

				dstPtr := Ptr (ORD4 (dstPtr) + stuff.rowBytes)

				END;

			doc.fData [channel] . Flush

			END;

		CallExport (exportSelectorContinue);

		CheckResult

		END;

	IF buffer <> NIL THEN
		BEGIN
		DisposPtr (buffer);
		buffer := NIL
		END;

	Success (fi);

	FinishProgress;

	CallExport (exportSelectorFinish);

	CheckResult;

	IF NOT stuff.dirty THEN
		BEGIN
		doc.fMasterChanges := doc.fMasterChanges OR (doc.fChangeCount > 0);
		doc.fChangeCount   := 0
		END;

	Success (fi2);

	FixReserve (0, 0)

	END;

{*****************************************************************************}

{$S AScan}

PROCEDURE DoExportCommand (doc: TImageDocument; name: Str255);

	VAR
		h: Handle;
		fi: FailInfo;
		refNum: INTEGER;
		fileName: Str255;
		info: HPlugInInfo;
		saveLimit: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		IF h <> NIL THEN
			BEGIN
			HUnlock (h);
			HPurge (h)
			END;

		IF refNum <> -1 THEN
			CloseResFile (refNum);

		gVMMinPageLimit := saveLimit

		END;

	BEGIN

	gPlugInName := name;

	IF NOT IsPlugIn (name, gFirstPSExport, info) THEN
		Failure (1, 0);

	gApplication.CommitLastCommand;

	VMCompress (TRUE);

	h		   := NIL;
	refNum	   := -1;
	saveLimit  := gVMMinPageLimit;

	CatchFailures (fi, CleanUp);

	gVMMinPageLimit := 1;

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

	PSPlugInExport (doc, info, StripAddress (h^));

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

END.

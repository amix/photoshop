{Photoshop version 1.0.1, file: UInternal.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}
{$I UGhost.p.inc}
{$I UScreen.p.inc}

CONST
	kFileVersion1 = 119;
	kFileVersion = 120;
	
	kModeVersion1 = 106;
	kModeVersion2 = 115;

	kRsrcKind = kFileType;

	kImageSizeInfoID	 = 1000;
	kPrintInfoID		 = 1001;
	kImageStyleInfoID	 = 1002;
	kIndexedColorTableID = 1003;
	kMultidiskStampID	 = 1004;

	kMultidiskInitial	= '8BMD';
	kMultidiskContinued = '8BMC';

TYPE

	{ Basic image information, stored as resource in image file }

	TImageSizeInfo = RECORD
		fChannels: INTEGER;
		fRows	 : INTEGER;
		fCols	 : INTEGER;
		fDepth	 : INTEGER;
		fMode	 : INTEGER
		END;

	PImageSizeInfo = ^TImageSizeInfo;
	HImageSizeInfo = ^PImageSizeInfo;

	{ Image style information, stored as resource in image file }

	TImageStyleInfo = RECORD
		fVersion: INTEGER;
			CASE INTEGER OF
			0: (fMode: INTEGER);
			1: (fStyleInfo: TStyleInfo);
		END;

	PImageStyleInfo = ^TImageStyleInfo;
	HImageStyleInfo = ^PImageStyleInfo;

VAR
	gName: STRING [63];
	gStamp: TMultidiskStamp;

{*****************************************************************************}

{$S AInit}

PROCEDURE TInternalFormat.IImageFormat; OVERRIDE;

	BEGIN

	INHERITED IImageFormat;

	fCanRead	  := TRUE;
	fReadType1	  := kFileType;
	fReadType2	  := kMultidiskInitial;
	fUsesDataFork := TRUE;
	fUsesRsrcFork := TRUE

	END;

{*****************************************************************************}

{$S AWriteFile}

FUNCTION TInternalFormat.CanWrite (doc: TImageDocument): BOOLEAN; OVERRIDE;

	BEGIN
	CanWrite := TRUE
	END;

{*****************************************************************************}

{$S AInternal}

PROCEDURE TInternalFormat.ReadPart (doc: TImageDocument);

	VAR
		size: LONGINT;
		count: INTEGER;
		vRefNum: INTEGER;

	BEGIN

	MoveHands (TRUE);

	FailOSErr (GetVRefNum (fRefNum, vRefNum));

	fLastVRefNum := vRefNum;

	FailOSErr (GetEOF (fRefNum, size));

	IF size MOD doc.fData [0] . fLogicalSize <> 0 THEN
		Failure (errBadInternal, 0);

	size := size DIV doc.fData [0] . fLogicalSize;

	WHILE size > 0 DO
		BEGIN

		IF fChannel = doc.fChannels THEN
			Failure (errBadInternal, 0);

		count := Min (size, doc.fRows - fRow);

		StartTask (count / size);

		GetRawRows (doc.fData [fChannel],
					doc.fData [fChannel] . fLogicalSize,
					fRow, count, TRUE);

		FinishTask;

		size := size - count;

		fRow := fRow + count;

		IF fRow = doc.fRows THEN
			BEGIN
			fRow	 := 0;
			fChannel := fChannel + 1
			END

		END

	END;

{*****************************************************************************}

{$S AInternal}

PROCEDURE TInternalFormat.DoRead (doc: TImageDocument;
								  refNum: INTEGER;
								  rsrcExists: BOOLEAN); OVERRIDE;

	VAR
		srcPtr: Ptr;
		channel: INTEGER;
		aVMArray: TVMArray;
		logicalSize: INTEGER;
		stamp: HMultidiskStamp;
		imageSizeInfo: HImageSizeInfo;
		imageStyleInfo: HImageStyleInfo;
		indexedColorTable: HRGBLookUpTable;

	PROCEDURE GetSpot (VAR spec: THalftoneSpec);

		VAR
			count: LONGINT;

		BEGIN

		count := -spec.shape;

		IF count > 0 THEN
			BEGIN

			spec.spot := NewPermHandle (count);
			FailNil (spec.spot);

			RegisterSpot (spec.spot);

			BlockMove (srcPtr, spec.spot^, count);

			srcPtr := Ptr (ORD4 (srcPtr) + count)

			END

		END;

	BEGIN

	MoveHands (NOT doc.fReverting);

	fRefNum := refNum;

	IF NOT rsrcExists THEN Failure (errBadInternal, 0);

	imageSizeInfo := HImageSizeInfo
					 (Get1Resource (kRsrcKind, kImageSizeInfoID));

	IF imageSizeInfo = NIL THEN Failure (errBadInternal, 0);

	IF GetHandleSize (Handle (imageSizeInfo)) >= 8 THEN
		BEGIN
		doc.fChannels := imageSizeInfo^^.fChannels;
		doc.fRows	  := imageSizeInfo^^.fRows;
		doc.fCols	  := imageSizeInfo^^.fCols;
		doc.fDepth	  := imageSizeInfo^^.fDepth
		END
	ELSE
		Failure (errBadInternal, 0);

	IF NOT doc.ValidSize THEN Failure (errBadInternal, 0);

	IF GetHandleSize (Handle (imageSizeInfo)) >= 10 THEN
		doc.fMode := TDisplayMode (imageSizeInfo^^.fMode)
	ELSE
		doc.DefaultMode;

	ReleaseResource (Handle (imageSizeInfo));

	doc.fPrintInfo := Get1Resource (kRsrcKind, kPrintInfoID);

	IF doc.fPrintInfo <> NIL THEN DetachResource (doc.fPrintInfo);

	indexedColorTable := HRGBLookUpTable
						 (Get1Resource (kRsrcKind, kIndexedColorTableID));

	if indexedColorTable <> NIL THEN
		BEGIN

		IF GetHandleSize (Handle (indexedColorTable)) =
						  SIZEOF (TRGBLookUpTable) THEN
			BEGIN
			doc.fMode := IndexedColorMode;
			doc.fIndexedColorTable := indexedColorTable^^;
			doc.TestColorTable
			END;

		ReleaseResource (Handle (indexedColorTable))

		END;

	imageStyleInfo := HImageStyleInfo
					  (Get1Resource (kRsrcKind, kImageStyleInfoID));

	IF imageStyleInfo <> NIL THEN
		BEGIN

		HLock (Handle (imageStyleInfo));

		IF GetHandleSize (Handle (imageStyleInfo)) >= SIZEOF (INTEGER) THEN
			WITH imageStyleInfo^^ DO
				BEGIN

				IF (fVersion >= kModeVersion1) AND
				   (fVersion <= kModeVersion2) THEN
					doc.fMode := TDisplayMode (fMode);

				IF (fVersion = kFileVersion1) OR
				   (fVersion = kFileVersion) THEN
					BEGIN

					srcPtr := Ptr (ORD4 (imageStyleInfo^) +
								   SIZEOF (TImageStyleInfo));

					GetSpot (fStyleInfo.fHalftoneSpec);

					GetSpot (fStyleInfo.fHalftoneSpecs[0]);
					GetSpot (fStyleInfo.fHalftoneSpecs[1]);
					GetSpot (fStyleInfo.fHalftoneSpecs[2]);
					GetSpot (fStyleInfo.fHalftoneSpecs[3]);

					doc.fStyleInfo := fStyleInfo;
					
					IF fVersion = kFileVersion1 THEN
						IF doc.fMode = SeparationsCMYK THEN
							doc.fStyleInfo.fGamma := 100

					END

				END;

		ReleaseResource (Handle (imageStyleInfo))

		END;

	IF (doc.fDepth = 1) <> (doc.fMode = HalftoneMode) THEN
		Failure (errBadInternal, 0);

	IF (doc.fChannels > 1) AND ((doc.fMode = MonochromeMode) OR
								(doc.fMode = IndexedColorMode)) THEN
		Failure (errBadInternal, 0);

	IF doc.fChannels < doc.Interleave (0) THEN
		Failure (errBadInternal, 0);

	IF (doc.fChannels = 1) AND (doc.fMode = MultichannelMode) THEN
		Failure (errBadInternal, 0);

	stamp := HMultidiskStamp (Get1Resource (kRsrcKind, kMultidiskStampID));

	IF stamp = NIL THEN
		fMultidisk := FALSE

	ELSE
		BEGIN

		fMultidisk := TRUE;

		IF GetHandleSize (Handle (stamp)) <> SIZEOF (TMultidiskStamp) THEN
			Failure (errBadInternal, 0);

		fStamp := stamp^^;

		ReleaseResource (Handle (stamp))

		END;

	IF doc.fDepth = 1 THEN
		logicalSize := BSL (BSR (doc.fCols + 15, 4), 1)
	ELSE
		logicalSize := doc.fCols;

	FOR channel := 0 TO doc.fChannels - 1 DO
		BEGIN
		aVMArray := NewVMArray (doc.fRows,
								logicalSize,
								doc.Interleave (channel));
		doc.fData [channel] := aVMArray
		END;

	IF fMultidisk THEN
		BEGIN

		fRow	 := 0;
		fChannel := 0;

		ReadPart (doc)

		END

	ELSE
		BEGIN

		IF GetFileLength = 0 THEN
			Failure (errEmptyFile, 0);

		FOR channel := 0 TO doc.fChannels - 1 DO
			BEGIN

			StartTask (1 / (doc.fChannels - channel));

			GetRawRows (doc.fData [channel],
						doc.fData [channel] . fLogicalSize,
						0, doc.fRows,
						NOT doc.fReverting);

			FinishTask

			END

		END

	END;

{*****************************************************************************}

{$S AInternal}

FUNCTION ReadNextHook (item: INTEGER; theDialog: DialogPtr): INTEGER;

	CONST
		kPromptItem = 11;

	VAR
		s: Str255;
		ss: Str255;
		itemBox: Rect;
		index: INTEGER;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	ReadNextHook := item;

	IF item = -1 THEN
		BEGIN

		NumToString (gStamp.fPart, ss);

		GetDItem (theDialog, kPromptItem, itemType, itemHandle, itemBox);

		GetIText (itemHandle, s);

		FOR index := 1 TO LENGTH (s) DO
			IF s [index] = '%' THEN
				BEGIN
				DELETE (s, index, 1);
				INSERT (ss, s, index);
				LEAVE
				END;

		FOR index := 1 TO LENGTH (s) DO
			IF s [index] = '%' THEN
				BEGIN
				DELETE (s, index, 1);
				INSERT (gName, s, index);
				LEAVE
				END;

		SetIText (itemHandle, s)

		END

	END;

{*****************************************************************************}

{$S AInternal}

FUNCTION ReadNextFilter (paramBlock: CInfoPBPtr): BOOLEAN;

	VAR
		err: OSErr;
		wd: WDPBRec;
		mfs: BOOLEAN;
		name: Str255;
		stamp: Handle;
		refNum: INTEGER;
		vRefNum: INTEGER;
		saveVol: INTEGER;
		pb: HParamBlockRec;

	BEGIN

	ReadNextFilter := TRUE;

	name	:= paramBlock^.ioNamePtr^;
	vRefNum := paramBlock^.ioVRefNum;

	pb.ioNamePtr  := NIL;
	pb.ioVRefNum  := vRefNum;
	pb.ioVolIndex := 0;

	IF PBHGetVInfo (@pb, FALSE) <> noErr THEN
		EXIT (ReadNextFilter);

	mfs := (pb.ioVSigWord = $D2D7);

	IF GetVol (NIL, saveVol) = noErr THEN
		BEGIN

		IF mfs THEN
			err := SetVol (NIL, vRefNum)
		ELSE
			BEGIN

			wd.ioNamePtr := NIL;
			wd.ioVRefNum := vRefNum;
			wd.ioWDDirID := paramBlock^.ioFlParID;

			err := PBHSetVol (@wd, FALSE)

			END;

		IF err = noErr THEN
			BEGIN

			refNum := OpenResFile (name);

			IF refNum <> -1 THEN
				BEGIN

				stamp := Get1Resource (kRsrcKind, kMultidiskStampID);

				IF stamp <> NIL THEN
					IF EqualBytes (stamp^, @gStamp,
								   SIZEOF (TMultidiskStamp)) THEN
						ReadNextFilter := FALSE;

				CloseResFile (refNum)

				END;

			err := SetVol (NIL, saveVol)

			END

		END

	END;

{*****************************************************************************}

{$S AInternal}

PROCEDURE TInternalFormat.ReadNext (doc: TImageDocument; name: Str255);

	CONST
		kGetPartID = 1403;

	VAR
		s: Str255;
		ss: Str255;
		fi: FailInfo;
		where: Point;
		reply: SFReply;
		refNum: INTEGER;
		typeList: SFTypeList;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		VAR
			ignore: OSErr;

		BEGIN
		FinishProgress;
		ignore := FSClose (refNum)
		END;

	BEGIN

	fStamp.fPart := fStamp.fPart + 1;

	gName  := name;
	gStamp := fStamp;

	EjectLastVolume;

	WhereToPlaceDialog (kGetPartID, where);

	typeList [0] := kMultidiskContinued;

	SFPGetFile (where, '', @ReadNextFilter, 1, typeList,
				@ReadNextHook, reply, kGetPartID, NIL);

	IF NOT reply.good THEN Failure (0, 0);

	MoveGhostsForward;

	FailOSErr (FSOpen (reply.fName, reply.vRefNum, refNum));

	GetIndString (s, kStringsID, strReadingPart);
	NumToString (fStamp.fPart, ss);
	INSERT (ss, s, LENGTH (s) + 1);

	StartProgress (s);

	CatchFailures (fi, CleanUp);

	fRefNum := refNum;

	ReadPart (doc);

	Success (fi);

	FinishProgress;

	FailOSErr (FSClose (refNum))

	END;

{*****************************************************************************}

{$S AInternal}

PROCEDURE TInternalFormat.ReadOther
		(doc: TImageDocument; name: Str255); OVERRIDE;

	BEGIN

	IF fMultidisk THEN
		BEGIN

		doc.fSaveExists := FALSE;

		WHILE fChannel < doc.fChannels DO
			ReadNext (doc, name);

		EjectLastVolume

		END

	END;

{*****************************************************************************}

{$S AInternal}

PROCEDURE TInternalFormat.AboutToSave (doc: TImageDocument;
									   itsCmd: INTEGER;
									   VAR name: Str255;
									   VAR vRefNum: INTEGER;
									   VAR makingCopy: BOOLEAN); OVERRIDE;

	CONST
		kSaveMultidiskID = 926;

	VAR
		blkSize: LONGINT;
		freeBlks: LONGINT;
		pb: HParamBlockRec;
		neededBlks: LONGINT;
		rsrcForkSize: LONGINT;

	BEGIN

	fMultidisk := FALSE;

	IF itsCmd = cSaveAs THEN
		BEGIN

		pb.ioNamePtr  := NIL;
		pb.ioVRefNum  := vRefNum;
		pb.ioVolIndex := 0;

		FailOSErr (PBHGetVInfo (@pb, FALSE));

		blkSize := pb.ioVAlBlkSiz;

		freeBlks := BAND (pb.ioVFrBlk, $0FFFF) - 1;
		
		IF GetFileInfo (name, vRefNum, pb) = noErr THEN
			freeBlks := freeBlks + NumBlocks (pb.ioFlRPyLen, blkSize) +
								   NumBlocks (pb.ioFlPyLen , blkSize);

		rsrcForkSize := RsrcForkBytes (doc);

		IF doc.fMiscResources <> NIL THEN
			MiscResourcesBytes (doc, rsrcForkSize);

		neededBlks := NumBlocks (DataForkBytes (doc), blkSize) +
					  NumBlocks (rsrcForkSize		, blkSize);

		IF (neededBlks > freeBlks) AND (freeBlks * blkSize >= $10000) THEN
			BEGIN

			IF BWAlert (kSaveMultidiskID, 0, TRUE) <> ok THEN
				Failure (0, 0);

			fMultidisk := TRUE;

			makingCopy := TRUE

			END

		END;

	IF fMultidisk THEN
		fFileType := kMultidiskInitial
	ELSE
		fFileType := kFileType

	END;

{*****************************************************************************}

{$S AInternal}

FUNCTION TInternalFormat.DataForkBytes
		(doc: TImageDocument): LONGINT; OVERRIDE;

	BEGIN

	IF fMultidisk THEN
		DataForkBytes := 0
	ELSE
		DataForkBytes := doc.fRows *
						 ORD4 (doc.fData [0] . fLogicalSize) *
						 doc.fChannels

	END;

{*****************************************************************************}

{$S AInternal}

FUNCTION TInternalFormat.SpotBytes (doc: TImageDocument): LONGINT;

	VAR
		j: INTEGER;
		bytes: LONGINT;

	BEGIN

	bytes := Max (0, -doc.fStyleInfo.fHalftoneSpec.shape);

	FOR j := 0 TO 3 DO
		bytes := bytes + Max (0, -doc.fStyleInfo.fHalftoneSpecs[j].shape);

	SpotBytes := bytes

	END;

{*****************************************************************************}

{$S AInternal}

FUNCTION TInternalFormat.RsrcForkBytes
		(doc: TImageDocument): LONGINT; OVERRIDE;

	VAR
		bytes: LONGINT;

	BEGIN

	bytes := kRsrcTypeOverhead + 2 * kRsrcOverhead +
			 SIZEOF (TImageSizeInfo) +
			 SIZEOF (TImageStyleInfo) + SpotBytes (doc);

	IF doc.fMode = IndexedColorMode THEN
		bytes := bytes + kRsrcOverhead + SIZEOF (TRGBLookUpTable);

	IF doc.fPrintInfo <> NIL THEN
		bytes := bytes + kRsrcOverhead + GetHandleSize (doc.fPrintInfo);

	IF fMultidisk THEN
		bytes := bytes + kRsrcOverhead + SIZEOF (TMultidiskStamp);

	RsrcForkBytes := bytes

	END;

{*****************************************************************************}

{$S AInternal}

PROCEDURE TInternalFormat.AddResources (doc: TImageDocument);

	VAR
		dstPtr: Ptr;
		printInfo: Handle;
		imageSizeInfo: HImageSizeInfo;
		imageStyleInfo: HImageStyleInfo;
		indexedColorTable: HRGBLookUpTable;

	PROCEDURE AddSpot (spec: THalftoneSpec);

		VAR
			count: LONGINT;

		BEGIN

		count := -spec.shape;

		IF count > 0 THEN
			BEGIN
			BlockMove (spec.spot^, dstPtr, count);
			dstPtr := Ptr (ORD4 (dstPtr) + count)
			END

		END;

	BEGIN

	imageSizeInfo := HImageSizeInfo (NewHandle (SIZEOF (TImageSizeInfo)));
	FailMemError;

	imageSizeInfo^^.fChannels := doc.fChannels;
	imageSizeInfo^^.fRows	  := doc.fRows;
	imageSizeInfo^^.fCols	  := doc.fCols;
	imageSizeInfo^^.fDepth	  := doc.fDepth;
	imageSizeInfo^^.fMode	  := ORD (doc.fMode);

	AddResource (Handle (imageSizeInfo), kRsrcKind, kImageSizeInfoID, '');
	FailResError;

	IF doc.fPrintInfo <> NIL THEN
		BEGIN
		printInfo := doc.fPrintInfo;
		FailOSErr (HandToHand (printInfo));
		AddResource (printInfo, kRsrcKind, kPrintInfoID, '');
		FailResError
		END;

	imageStyleInfo := HImageStyleInfo
					  (NewHandle (SIZEOF (TImageStyleInfo) +
								  SpotBytes (doc)));
	FailMemError;

	WITH imageStyleInfo^^ DO
		BEGIN
		fVersion   := kFileVersion;
		fStyleInfo := doc.fStyleInfo
		END;

	dstPtr := Ptr (ORD4 (imageStyleInfo^) + SIZEOF (TImageStyleInfo));

	AddSpot (doc.fStyleInfo.fHalftoneSpec);

	AddSpot (doc.fStyleInfo.fHalftoneSpecs[0]);
	AddSpot (doc.fStyleInfo.fHalftoneSpecs[1]);
	AddSpot (doc.fStyleInfo.fHalftoneSpecs[2]);
	AddSpot (doc.fStyleInfo.fHalftoneSpecs[3]);

	AddResource (Handle (imageStyleInfo), kRsrcKind, kImageStyleInfoID, '');
	FailResError;

	IF doc.fMode = IndexedColorMode THEN
		BEGIN

		indexedColorTable := HRGBLookUpTable
							(NewHandle (SIZEOF (TRGBLookUpTable)));
		FailMemError;

		indexedColorTable^^ := doc.fIndexedColorTable;

		AddResource (Handle (indexedColorTable), kRsrcKind,
					 kIndexedColorTableID, '');
		FailResError

		END

	END;

{*****************************************************************************}

{$S AInternal}

PROCEDURE TInternalFormat.AddStamp;

	VAR
		stamp: HMultidiskStamp;

	BEGIN

	stamp := HMultidiskStamp (NewHandle (SIZEOF (TMultidiskStamp)));
	FailMemError;

	stamp^^ := fStamp;

	AddResource (Handle (stamp), kRsrcKind, kMultidiskStampID, '');
	FailResError

	END;

{*****************************************************************************}

{$S AInternal}

PROCEDURE TInternalFormat.FillUpDisk (doc: TImageDocument);

	VAR
		count: INTEGER;
		vRefNum: INTEGER;
		freeRows: LONGINT;
		needRows: LONGINT;
		pb: HParamBlockRec;
		freeBytes: LONGINT;

	BEGIN

	MoveHands (FALSE);

	FailOSErr (GetVRefNum (fRefNum, vRefNum));

	fLastVRefNum := vRefNum;

	pb.ioNamePtr  := NIL;
	pb.ioVRefNum  := vRefNum;
	pb.ioVolIndex := 0;

	FailOSErr (PBHGetVInfo (@pb, FALSE));

	freeBytes := (BAND ($0FFFF, pb.ioVFrBlk) - 1) * pb.ioVAlBlkSiz - $2000;

	freeRows := freeBytes DIV doc.fData [0] . fLogicalSize;

	IF freeRows <= 0 THEN Failure (dskFulErr, 0);

	needRows := doc.fRows - fRow;

	IF fChannel < doc.fChannels - 1 THEN
		needRows := needRows +
					ORD4 (doc.fChannels - 1 - fChannel) * doc.fRows;

	freeRows := Min (freeRows, needRows);

	WHILE fChannel < doc.fChannels DO
		BEGIN

		count := Min (doc.fRows - fRow, freeRows);

		IF count = 0 THEN EXIT (FillUpDisk);

		StartTask (count / freeRows);

		PutRawRows (doc.fData [fChannel],
					doc.fData [fChannel] . fLogicalSize,
					fRow, count);

		FinishTask;

		freeRows := freeRows - count;

		fRow := fRow + count;

		IF fRow = doc.fRows THEN
			BEGIN
			fRow	 := 0;
			fChannel := fChannel + 1
			END

		END

	END;

{*****************************************************************************}

{$S AInternal}

PROCEDURE TInternalFormat.DoWrite
		(doc: TImageDocument; refNum: INTEGER); OVERRIDE;

	VAR
		secs: LONGINT;
		channel: INTEGER;

	BEGIN

	fRefNum := refNum;

	MoveHands (FALSE);

	AddResources (doc);

	IF fMultidisk THEN
		BEGIN

		GetDateTime (secs);

		fStamp.fName := doc.fTitle;
		fStamp.fDate := secs;
		fStamp.fTime := TickCount;
		fStamp.fPart := 1;

		AddStamp;

		fRow	 := 0;
		fChannel := 0;

		FillUpDisk (doc)

		END

	ELSE
		FOR channel := 0 TO doc.fChannels - 1 DO
			BEGIN
			StartTask (1 / (doc.fChannels - channel));
			PutRawRows (doc.fData [channel],
						doc.fData [channel] . fLogicalSize,
						0, doc.fRows);
			FinishTask
			END

	END;

{*****************************************************************************}

{$S AInternal}

PROCEDURE TInternalFormat.EjectLastVolume;

	CONST
		kEjectSizeLimit = $500000;

	VAR
		err: OSErr;
		dq: DrvQElPtr;
		size: LONGINT;
		flags: INTEGER;
		vRefNum: INTEGER;
		pb: HParamBlockRec;

	BEGIN

	IF fLastVRefNum = 0 THEN EXIT (EjectLastVolume);

	pb.ioNamePtr  := NIL;
	pb.ioVRefNum  := fLastVRefNum;
	pb.ioVolIndex := 0;

	IF PBHGetVInfo (@pb, FALSE) = noErr THEN
		BEGIN

		size := BAND (pb.ioVNmAlBlks, $0FFFF) * pb.ioVAlBlkSiz;

		IF (size > 0) AND (size <= kEjectSizeLimit) THEN
			BEGIN

			dq := DrvQElPtr (GetDrvQHdr^.QHead);

			WHILE (dq <> NIL) & (dq^.dQDrive <> pb.ioVDrvInfo) DO
				dq := DrvQElPtr (dq^.qLink);

			IF dq <> NIL THEN
				BEGIN

				flags := BAND ($FF, Ptr (ORD4 (dq) - 3)^);

				IF (flags = 1) OR (flags = 2) THEN
					BEGIN

					vRefNum := pb.ioVRefNum;

					IF Eject (NIL, vRefNum) = noErr THEN
						err := UnmountVol (NIL, vRefNum)

					END

				END

			END

		END

	END;

{*****************************************************************************}

{$S AInternal}

PROCEDURE TInternalFormat.WriteNext (doc: TImageDocument; name: Str255);

	VAR
		s: Str255;
		ss: Str255;
		err: OSErr;
		fi: FailInfo;
		part: Str255;
		where: Point;
		reply: SFReply;
		limit: INTEGER;
		index: INTEGER;
		prompt: Str255;
		refNum: INTEGER;
		close1: BOOLEAN;
		close2: BOOLEAN;
		close3: BOOLEAN;
		killIt: BOOLEAN;
		default: Str255;
		saveVol: INTEGER;
		saveRow: INTEGER;
		pb: HParamBlockRec;
		saveChannel: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		CONST
			kPartFailedID = 925;

		VAR
			x: BOOLEAN;
			ignore: OSErr;
			errStr: Str255;

		BEGIN

		fLastVRefNum := 0;

		fRow	 := saveRow;
		fChannel := saveChannel;

		IF close1 THEN
			CloseResFile (refNum);

		IF close2 THEN
			ignore := FSClose (refNum);

		IF close3 THEN
			FinishProgress;

		IF killIt THEN
			ignore := DeleteFile (@reply.fName, reply.vRefNum);

		ignore := SetVol (NIL, saveVol);

		IF error <> noErr THEN
			BEGIN

			x := LookupErrString (error, errReasonID, errStr);

			ParamText (errStr, part, '', '');

			IF BWAlert (kPartFailedID, 0, TRUE) <> ok THEN Failure (0, 0)

			END;

		EXIT (WriteNext)

		END;

	BEGIN

	NumToString (fStamp.fPart, part);

	default := name;

	limit := 30 - LENGTH (part);

	IF LENGTH (default) > limit THEN
		default [0] := CHR (limit);

	INSERT ('.' , default, LENGTH (default) + 1);
	INSERT (part, default, LENGTH (default) + 1);

	GetIndString (prompt, kStringsID, strSavePartIn);

	FOR index := 1 TO LENGTH (prompt) DO
		IF prompt [index] = '^' THEN
			BEGIN
			DELETE (prompt, index, 2);
			INSERT (part, prompt, index)
			END;

	WhereToPlaceDialog (putDlgID, where);

	UpdateAllWindows;

	EjectLastVolume;

	SFPutFile (where, prompt, default, NIL, reply);
	IF NOT reply.good THEN Failure (0, 0);

	MoveGhostsForward;

	FailOSErr (GetVol (NIL, saveVol));

	close1 := FALSE;
	close2 := FALSE;
	killIt := FALSE;

	saveRow 	:= fRow;
	saveChannel := fChannel;

	CatchFailures (fi, CleanUp);
	
	err := Create (reply.fName, reply.vRefNum,
				   kSignature, kMultidiskContinued);
				   
	IF err = dupFNErr THEN
		BEGIN
		FailOSErr (DeleteFile (@reply.fName, reply.vRefNum));
		err := Create (reply.fName, reply.vRefNum,
					   kSignature, kMultidiskContinued)
		END;
		
	FailOSErr (err);
	
	killIt := TRUE;

	pb.ioNamePtr  := NIL;
	pb.ioVRefNum  := reply.vRefNum;
	pb.ioVolIndex := 0;

	FailOSErr (PBHGetVInfo (@pb, FALSE));

	IF pb.ioVAlBlkSiz <> 0 THEN
		IF BAND (pb.ioVFrBlk, $0FFFF) < $10000 DIV pb.ioVAlBlkSiz THEN
			Failure (dskFulErr, 0);

	FailOSErr (SetVol (NIL, reply.vRefNum));

	CreateResFile (reply.fName);
	FailResError;

	refNum := OpenResFile (reply.fName);
	FailResError;

	close1 := TRUE;

	FailOSErr (SetVol (NIL, saveVol));

	AddStamp;

	close1 := FALSE;

	CloseResFile (refNum);
	FailResError;

	FailOSErr (FSOpen (reply.fName, reply.vRefNum, refNum));

	close2 := TRUE;

	fRefNum := refNum;

	GetIndString (s, kStringsID, strWritingPart);
	NumToString (fStamp.fPart, ss);
	INSERT (ss, s, LENGTH (s) + 1);

	StartProgress (s);

	close3 := TRUE;

	FillUpDisk (doc);

	FinishProgress;

	close3 := FALSE;

	close2 := FALSE;

	FailOSErr (FSClose (refNum));
	FailOSErr (FlushVol (NIL, reply.vRefNum));

	Success (fi);

	fStamp.fPart := fStamp.fPart + 1

	END;

{*****************************************************************************}

{$S AInternal}

PROCEDURE TInternalFormat.WriteOther
		(doc: TImageDocument; name: Str255); OVERRIDE;

	BEGIN

	IF fMultidisk THEN
		BEGIN

		fStamp.fPart := 2;

		WHILE fChannel < doc.fChannels DO
			WriteNext (doc, name);

		IF fStamp.fPart > 2 THEN
			EjectLastVolume

		END

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TMiscResource.Free; OVERRIDE;

	BEGIN

	IF fData <> NIL THEN
		DisposHandle (fData);

	INHERITED Free

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE ReadMiscResources (doc: TImageDocument);

	VAR
		h: Handle;
		err: OSErr;
		name: Str255;
		index: INTEGER;
		state: BOOLEAN;
		theID: INTEGER;
		theType: ResType;
		entry: TMiscResource;

	BEGIN

	theType := 'STR ';

	FOR index := 1 TO Count1Resources (theType) DO
		BEGIN

		IF doc.fMiscResources = NIL THEN
			doc.fMiscResources := NewList;

		NEW (entry);
		FailNil (entry);

		entry.fData := NIL;

		doc.fMiscResources.InsertLast (entry);

		state := PermAllocation (TRUE);
		h := Get1IndResource (theType, index);
		err := ResError;
		state := PermAllocation (state);

		FailOSErr (err);

		GetResInfo (h, theID, theType, name);
		FailResError;

		DetachResource (h);
		FailResError;

		HNoPurge (h);
		HUnlock  (h);

		entry.fID	:= theID;
		entry.fType := theType;
		entry.fData := h

		END

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE MiscResourcesBytes (doc: TImageDocument;
							  VAR rsrcForkBytes: LONGINT);

	PROCEDURE AddEntry (entry: TMiscResource);
		BEGIN
		rsrcForkBytes := rsrcForkBytes + kRsrcOverhead +
						 GetHandleSize (entry.fData)
		END;

	BEGIN

	rsrcForkBytes := rsrcForkBytes + kRsrcTypeOverhead;

	doc.fMiscResources.Each (AddEntry)

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE WriteMiscResources (doc: TImageDocument);

	PROCEDURE WriteEntry (entry: TMiscResource);

		VAR
			h: Handle;
			err: OSErr;

		BEGIN

		h := entry.fData;

		FailOSErr (HandToHand (h));

		AddResource (h, entry.fType, entry.fID, '');
		err := ResError;

		IF err <> noErr THEN
			BEGIN
			DisposHandle (h);
			Failure (err, 0)
			END

		END;

	BEGIN
	doc.fMiscResources.Each (WriteEntry)
	END;

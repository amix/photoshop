{Photoshop version 1.0.1, file: UEPSFormat.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}
{$I UConvert.p.inc}
{$I UPostScript.a.inc}
{$I UResize.p.inc}

{*****************************************************************************}

{$S AInit}

PROCEDURE TEPSFormat.IImageFormat; OVERRIDE;

	BEGIN

	INHERITED IImageFormat;

	fCanRead	  := TRUE;
	fReadType1	  := 'EPSF';
	fReadType2	  := '    ';
	fReadType3	  := '    ';
	fFileType	  := 'EPSF';
	fUsesDataFork := TRUE;
	fUsesRsrcFork := TRUE;

	fSystemPalette := TRUE;

	fHalftonePreview := 1;
	fOtherPreview	 := 1;

	fBinary := FALSE;

	fFiveFiles := FALSE;

	fTransparent := FALSE;

	fIncludeScreen	 := FALSE;
	fIncludeTransfer := FALSE;

	fFTypeItem	   := 0;
	fFCreatorItem  := 0;
	fCheck1Item    := 9;
	fCheck2Item    := 10;
	fCheck3Item    := 11;
	fRadioClusters := 2;
	fRadio1Item    := 4;
	fRadio1Count   := 3;
	fRadio2Item    := 7;
	fRadio2Count   := 2;
	fInts		   := 0;
	fStrs		   := 0

	END;

{*****************************************************************************}

{$S AWriteFile}

FUNCTION TEPSFormat.CanWrite (doc: TImageDocument): BOOLEAN; OVERRIDE;

	BEGIN

	CanWrite := doc.fMode IN [HalftoneMode,
							  MonochromeMode,
							  IndexedColorMode,
							  RGBColorMode,
							  SeparationsCMYK,
							  MultichannelMode]

	END;

{*****************************************************************************}

{$S AEPSFormat}

PROCEDURE TEPSFormat.SetFormatOptions (doc: TImageDocument); OVERRIDE;

	BEGIN

		CASE doc.fMode OF

		HalftoneMode:
			fDialogID := 3100;

		MonochromeMode,
		MultichannelMode:
			fDialogID := 3101;

		IndexedColorMode,
		RGBColorMode:
			fDialogID := 3102;

		SeparationsCMYK:
			fDialogID := 3103

		END;

	IF doc.fMode = HalftoneMode THEN
		BEGIN

		fCheckBoxes := 1;
		fCheck1 := fTransparent;

		fRadio1 := fHalftonePreview

		END

	ELSE
		BEGIN

		IF doc.fMode = SeparationsCMYK THEN
			fCheckboxes := 3
		ELSE
			fCheckboxes := 2;

		fCheck1 := fIncludeScreen;
		fCheck2 := fIncludeTransfer;
		fCheck3 := fFiveFiles;

		fRadio1 := fOtherPreview

		END;

	fRadio2 := ORD (fBinary);

	DoOptionsDialog;

	IF doc.fMode = HalftoneMode THEN
		BEGIN
		fTransparent	 := fCheck1;
		fHalftonePreview := fRadio1
		END
	ELSE
		BEGIN
		fIncludeScreen	 := fCheck1;
		fIncludeTransfer := fCheck2;
		fFiveFiles		 := fCheck3;
		fOtherPreview	 := fRadio1
		END;

	IF fRadio1 = 2 THEN
		fDepth := 8
	ELSE
		fDepth := fRadio1;

	fBinary := (fRadio2 <> 0);

	fUsesRsrcFork := (fDepth <> 0)

	END;

{*****************************************************************************}

{$S AEPSFormat}

PROCEDURE TEPSFormat.GetLine (VAR s: Str255);

	VAR
		pb: ParamBlockRec;

	BEGIN

	pb.ioRefNum    := fRefNum;
	pb.ioBuffer    := @s[1];
	pb.ioReqCount  := 255;
	pb.ioPosMode   := $0D80 + fsAtMark;
	pb.ioPosOffset := 0;

	FailOSErr (PBRead (@pb, FALSE));

	BlockMove (Ptr (ORD4 (@pb.ioActCount) + 3), @s, 1);

	IF s [LENGTH (s)] <> CHR ($D) THEN Failure (errBadEPSF, 0);

	DELETE (s, LENGTH (s), 1)

	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S AEPSFormat}

PROCEDURE TEPSFormat.ReadImageData (doc: TImageDocument;
									binary: BOOLEAN;
									first: INTEGER;
									count: INTEGER;
									alpha: INTEGER;
									invert: BOOLEAN);

	CONST
		kBufferSize = 32768;

	VAR
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		buffer: Handle;
		channel: INTEGER;
		rowBytes: INTEGER;
		fileBytes: LONGINT;
		table: TLookUpTable;
		bufferUsed: LONGINT;
		bufferBytes: LONGINT;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (buffer)
		END;

	PROCEDURE LoadBytes (n: LONGINT; p: Ptr);

		VAR
			count: LONGINT;

		BEGIN

		IF NOT binary THEN
			n := BSL (n, 1);

		WHILE n > 0 DO
			BEGIN

			IF bufferUsed = bufferBytes THEN
				BEGIN

				bufferUsed	:= 0;
				bufferBytes := Min (kBufferSize, fileBytes);

				IF bufferBytes <= 0 THEN Failure (errBadEPSF, 0);

				fileBytes := fileBytes - bufferBytes;

				GetBytes (bufferBytes, buffer^)

				END;

			IF binary THEN
				BEGIN

				count := Min (bufferBytes - bufferUsed, n);

				BlockMove (Ptr (ORD4 (buffer^) + bufferUsed), p, count);

				n := n - count;
				p := Ptr (ORD4 (p) + count);

				bufferUsed := bufferUsed + count

				END

			ELSE
				BEGIN

				count := bufferBytes - bufferUsed;

				DeHexBytes (Ptr (ORD4 (buffer^) + bufferUsed),
							count, p, n, table);

				bufferUsed := bufferBytes - count

				END

			END

		END;

	BEGIN

	IF doc.fDepth = 1 THEN
		rowBytes := (doc.fCols + 7) DIV 8
	ELSE
		rowBytes := doc.fCols;

	buffer := NewLargeHandle (kBufferSize);

	MoveHHi (buffer);
	HLock (buffer);

	CatchFailures (fi, CleanUp);

	fileBytes := GetFileLength - GetFilePosition;

	bufferUsed	:= 0;
	bufferBytes := 0;

	IF NOT binary THEN
		FOR row := 0 TO 255 DO
			IF CHR (row) IN ['0'..'9'] THEN
				table [row] := CHR (row - ORD ('0'))
			ELSE IF CHR (row) IN ['A'..'F'] THEN
				table [row] := CHR (row + 10 - ORD ('A'))
			ELSE IF CHR (row) IN ['a'..'f'] THEN
				table [row] := CHR (row + 10 - ORD ('a'))
			ELSE
				table [row] := CHR (255);

	FOR row := 0 TO doc.fRows - 1 DO
		BEGIN

		MoveHands (NOT doc.fReverting);

		UpdateProgress (row, doc.fRows);

		FOR channel := first TO first + count - 1 DO
			BEGIN

			dstPtr := doc.fData [channel] . NeedPtr (row, row, TRUE);

			LoadBytes (rowBytes, dstPtr);

			IF invert THEN
				DoMapBytes (dstPtr, rowBytes, gInvertLUT);

			doc.fData [channel] . DoneWithPtr

			END;

		FOR channel := 1 TO alpha DO
			LoadBytes (rowBytes, gBuffer)

		END;

	UpdateProgress (1, 1);

	FOR channel := first TO first + count - 1 DO
		doc.fData [channel] . Flush;

	Success (fi);

	CleanUp (0, 0)

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S AEPSFormat}

PROCEDURE TEPSFormat.ParseHeader (doc: TImageDocument;
								  VAR binary: BOOLEAN;
								  VAR cPlate: Str255;
								  VAR mPlate: Str255;
								  VAR yPlate: Str255;
								  VAR kPlate: Str255;
								  dcsPlate: BOOLEAN);

	VAR
		s: Str255;
		x1: INTEGER;
		x2: INTEGER;
		y1: INTEGER;
		y2: INTEGER;
		key: Str255;
		res: EXTENDED;
		index: INTEGER;
		which: INTEGER;
		width: LONGINT;
		height: LONGINT;
		blockSize: INTEGER;
		hSpec: THalftoneSpec;
		tSpec: TTransferSpec;
		haveResolution: BOOLEAN;

	FUNCTION NextChar: CHAR;
		BEGIN
		IF index <= LENGTH (s) THEN
			NextChar := s [index]
		ELSE
			NextChar := CHR ($D)
		END;

	PROCEDURE SkipWhite;
		BEGIN
		WHILE (NextChar = ' ') OR (NextChar = CHR (9)) DO
			index := index + 1
		END;

	FUNCTION ParseInteger: LONGINT;

		VAR
			x: LONGINT;
			negative: BOOLEAN;

		BEGIN
		x := 0;
		SkipWhite;
		negative := NextChar = '-';
		IF negative THEN index := index + 1;
		WHILE (NextChar IN ['0'..'9']) DO
			BEGIN
			x := x * 10 + ORD (NextChar) - ORD ('0');
			index := index + 1
			END;
		IF negative THEN x := -x;
		ParseInteger := x
		END;

	FUNCTION ParseRange (lower, upper: LONGINT): LONGINT;
		BEGIN
		ParseRange := Max (lower, Min (upper, ParseInteger))
		END;

	BEGIN

	cPlate := '';
	mPlate := '';
	yPlate := '';
	kPlate := '';

	width  := 0;
	height := 0;

	doc.fRows := 0;
	doc.fCols := 0;

	haveResolution := FALSE;

		REPEAT

		MoveHands (NOT doc.fReverting);

		GetLine (s);

		IF POS ('%%BoundingBox:', s) = 1 THEN
			BEGIN

			index := 15;

			x1 := ParseInteger;
			y1 := ParseInteger;
			x2 := ParseInteger;
			y2 := ParseInteger;

			width  := Max (0, x2 - x1);
			height := Max (0, y2 - y1)

			END;

		IF POS ('%%CyanPlate: ', s) = 1 THEN
			BEGIN
			cPlate := s;
			DELETE (cPlate, 1, 13)
			END;

		IF POS ('%%MagentaPlate: ', s) = 1 THEN
			BEGIN
			mPlate := s;
			DELETE (mPlate, 1, 16)
			END;

		IF POS ('%%YellowPlate: ', s) = 1 THEN
			BEGIN
			yPlate := s;
			DELETE (yPlate, 1, 15)
			END;

		IF POS ('%%BlackPlate: ', s) = 1 THEN
			BEGIN
			kPlate := s;
			DELETE (kPlate, 1, 14)
			END;

		IF POS ('%ImageData:', s) = 1 THEN
			BEGIN

			index := 12;

			doc.fCols  := ParseInteger;
			doc.fRows  := ParseInteger;
			doc.fDepth := ParseInteger;

			IF (doc.fDepth <> 1) AND
			   (doc.fDepth <> 8) THEN Failure (errBadEPSF, 0);

			doc.fChannels := ParseInteger;

				CASE doc.fChannels OF

				1:	BEGIN
					IF doc.fDepth = 1 THEN
						doc.fMode := HalftoneMode
					ELSE
						doc.fMode := MonochromeMode;
					IF ParseInteger <> 0 THEN Failure (errBadEPSF, 0)
					END;

				3:	BEGIN
					doc.fMode := RGBColorMode;
					IF ParseInteger <> 1 THEN Failure (errBadEPSF, 0)
					END;

				4:	BEGIN
					doc.fMode := SeparationsCMYK;
					IF ParseInteger <> 1 THEN Failure (errBadEPSF, 0)
					END;

				OTHERWISE
					Failure (errBadEPSF, 0)

				END;

			IF doc.fDepth = 1 THEN
				blockSize := (doc.fCols + 7) DIV 8
			ELSE
				blockSize := doc.fCols;

			IF ParseInteger <> blockSize THEN Failure (errBadEPSF, 0);

				CASE ParseInteger OF

				1:	binary := TRUE;

				2:	binary := FALSE;

				OTHERWISE
					Failure (errBadEPSF, 0)

				END;

			SkipWhite;

			IF NextChar <> '"' THEN Failure (errBadEPSF, 0);

			index := index + 1;

			key := '';

			WHILE NextChar <> '"' DO
				BEGIN
				IF NextChar = CHR ($D) THEN Failure (errBadEPSF, 0);
				INSERT (' ', key, LENGTH (key) + 1);
				key [LENGTH (key)] := NextChar;
				index := index + 1
				END;

			IF LENGTH (key) = 0 THEN Failure (errBadEPSF, 0)

			END;

		IF POS ('%ImageStyle:', s) = 1 THEN
			BEGIN

			index := 13;

			which := ParseInteger;

				CASE which OF

				1:	BEGIN

					doc.fStyleInfo.fResolution.value := Max (1, ParseInteger);
					doc.fStyleInfo.fResolution.scale := ParseRange (1, 2);
					doc.fStyleInfo.fWidthUnit		 := ParseRange (1, 5);
					doc.fStyleInfo.fHeightUnit		 := ParseRange (1, 4);

					haveResolution := TRUE

					END;

				100, 101, 102, 103, 104:
					BEGIN

					hSpec.frequency.value := ParseRange ($10000, 1000 * $10000);
					hSpec.frequency.scale := ParseRange (1, 2);
					hSpec.angle 		  := ParseRange (-180 * $10000,
														  180 * $10000);
					hSpec.shape 		  := ParseRange (0, 4);
					hSpec.spot			  := NIL;

					IF which > 100 THEN
						doc.fStyleInfo.fHalftoneSpecs [which - 101] := hSpec

					ELSE IF NOT dcsPlate THEN
						doc.fStyleInfo.fHalftoneSpec := hSpec

					END;

				200, 201, 202, 203, 204:
					BEGIN

					tSpec [0] := ParseRange ( 0, 100);
					tSpec [1] := ParseRange (-1, 100);
					tSpec [2] := ParseRange (-1, 100);
					tSpec [3] := ParseRange (-1, 100);
					tSpec [4] := ParseRange ( 0, 100);

					IF which > 200 THEN
						doc.fStyleInfo.fTransferSpecs [which - 201] := tSpec

					ELSE IF NOT dcsPlate THEN
						doc.fStyleInfo.fTransferSpec := tSpec

					END;

				210:
					IF NOT dcsPlate THEN
						doc.fStyleInfo.fGamma := ParseRange (100, 220)

				END

			END

		UNTIL (LENGTH (s) = 0) | (s[1] <> '%');

	IF NOT doc.ValidSize THEN Failure (errBadEPSF, 0);

	IF (width > 0) AND (height > 0) AND NOT haveResolution THEN
		BEGIN

		IF height > width THEN
			res := doc.fRows / height
		ELSE
			res := doc.fCols / width;

		res := res * 72 * $10000;

		IF res > 32000 * $10000 THEN res := 32000 * $10000;

		doc.fStyleInfo.fResolution.value := Max (1, ROUND (res))

		END;

	WHILE (LENGTH (s) <> LENGTH (key)) | (POS (key, s) <> 1) DO
		BEGIN
		MoveHands (NOT doc.fReverting);
		GetLine (s)
		END

	END;

{*****************************************************************************}

{$S AEPSFormat}

PROCEDURE TEPSFormat.ReadPostScript (doc: TImageDocument);

	VAR
		s: Str255;
		j: INTEGER;
		s1: Str255;
		s2: Str255;
		s3: Str255;
		s4: Str255;
		err: OSErr;
		fi: FailInfo;
		cPlate: Str255;
		mPlate: Str255;
		yPlate: Str255;
		kPlate: Str255;
		binary: BOOLEAN;
		refNum: INTEGER;
		channel: INTEGER;
		newRows: INTEGER;
		newCols: INTEGER;
		rowBytes: INTEGER;
		aVMArray: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		err := FSClose (refNum)
		END;

	BEGIN

	ParseHeader (doc, binary, cPlate, mPlate, yPlate, kPlate, FALSE);

	IF LENGTH (cPlate) <> 0 THEN
		BEGIN

		FOR channel := 0 TO 3 DO
			BEGIN

			StartTask (1 / (4 - channel));

				CASE channel OF
				0:	s := cPlate;
				1:	s := mPlate;
				2:	s := yPlate;
				3:	s := kPlate
				END;

			err := FSOpen (s, doc.fVolRefnum, refNum);

			IF err <> noErr THEN
				Failure (errNoAuxEPSF - channel, 0);

			CatchFailures (fi, CleanUp);

			fRefNum := refNum;

			ParseHeader (doc, binary, s1, s2, s3, s4, TRUE);

			IF channel = 0 THEN
				BEGIN
				newRows := doc.fRows;
				newCols := doc.fCols
				END;

			IF (doc.fRows <> newRows) OR
			   (doc.fCols <> newCols) OR
			   (doc.fChannels <> 1) OR
			   (doc.fDepth <> 8) THEN Failure (errBadEPSF, 0);

			IF channel = 0 THEN
				FOR j := 0 TO 3 DO
					BEGIN
					aVMArray := NewVMArray (newRows, newCols, 4 - j);
					doc.fData [j] := aVMArray
					END;

			ReadImageData (doc, binary, channel, 1, 0, FALSE);

			Success (fi);

			FailOSErr (FSClose (refNum));

			FinishTask

			END;

		doc.fMode := SeparationsCMYK;
		doc.fChannels := 4

		END

	ELSE
		BEGIN

		IF doc.fDepth = 1 THEN
			rowBytes := (doc.fCols + 15) DIV 16 * 2
		ELSE
			rowBytes := doc.fCols;

		FOR channel := 0 TO doc.fChannels - 1 DO
			BEGIN
			aVMArray := NewVMArray (doc.fRows,
									rowBytes,
									doc.fChannels - channel);
			doc.fData [channel] := aVMArray
			END;

		ReadImageData (doc,
					   binary,
					   0,
					   doc.fChannels,
					   ORD (doc.fChannels <> 1),
					   doc.fMode IN [HalftoneMode, SeparationsCMYK])

		END

	END;

{*****************************************************************************}

{$S AEPSFormat}

PROCEDURE TEPSFormat.DoRead (doc: TImageDocument;
							 refNum: INTEGER;
							 rsrcExists: BOOLEAN); OVERRIDE;

	LABEL
		1;

	CONST
		kUsePreviewPICT = 922;

	VAR
		h: Handle;
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF (error = errBadEPSF) AND rsrcExists THEN
			IF Count1Resources ('PICT') = 1 THEN
				GOTO 1
		END;

	BEGIN

	fSpool := FALSE;

	fRefNum := refNum;

	CatchFailures (fi, CleanUp);

	ReadPostScript (doc);

	Success (fi);

	EXIT (DoRead);

	1:	{ PostScript parse failed, try preview PICT }

	IF doc.fRevertInfo = NIL THEN
		BEGIN

		IF BWAlert (kUsePreviewPICT, 0, TRUE) <> ok THEN
			Failure (0, 0);

		h := NewPermHandle (0);
		FailNil (h);

		doc.fRevertInfo := h

		END;

	INHERITED DoRead (doc, refNum, rsrcExists)

	END;

{*****************************************************************************}

{$S AEPSFormat}

FUNCTION TEPSFormat.DataForkBytes (doc: TImageDocument): LONGINT; OVERRIDE;

	VAR
		count: LONGINT;

	BEGIN

	count := ORD4 (doc.fRows) * doc.fCols;

	IF doc.fMode = HalftoneMode THEN
		count := count DIV 8
	ELSE IF doc.fMode = SeparationsCMYK THEN
		IF fFiveFiles THEN
			count := 0
		ELSE
			count := count * 5
	ELSE IF NOT (doc.fMode IN [MonochromeMode, MultichannelMode]) THEN
		count := count * 4;

	IF fBinary THEN
		DataForkBytes := count
	ELSE
		DataForkBytes := count * 2

	END;

{*****************************************************************************}

{$S AEPSFormat}

FUNCTION TEPSFormat.MakePreviewPICT1 (doc: TImageDocument;
									  newRows: INTEGER;
									  newCols: INTEGER): Handle;

	VAR
		fi: FailInfo;
		gray: INTEGER;
		srcRect: Rect;
		scale: INTEGER;
		map: TLookUpTable;
		buffer1: TVMArray;
		buffer2: TVMArray;
		dummyDoc: TImageDocument;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (buffer1);
		FreeObject (buffer2);
		FreeObject (dummyDoc)
		END;

	BEGIN

	buffer1 := NIL;
	buffer2 := NIL;
	dummyDoc := NIL;

	CatchFailures (fi, CleanUp);

	SetRect (srcRect, 0, 0, doc.fCols, doc.fRows);

	buffer1 := NewVMArray (newRows, BSL (BSR (newCols + 15, 4), 1), 1);

	StartTask (0.7);

		CASE doc.fMode OF

		HalftoneMode:
			IF (newRows = doc.fRows) AND (newCols = doc.fCols) THEN
				doc.fData [0] . MoveArray (buffer1)
			ELSE
				BEGIN

				scale := 1;
				WHILE (scale < 16) AND
					  (scale < doc.fRows) AND
					  (scale < doc.fCols) AND
					  (doc.fRows DIV scale > newRows) AND
					  (doc.fCols DIV scale > newCols) DO scale := scale + 1;

				{$IFC qDebug}
				writeln ('scale = ', scale:1);
				{$ENDC}

				buffer2 := DeHalftoneDoc (doc, scale, FALSE);

				SetRect (srcRect, 0, 0, buffer2.fLogicalSize, buffer2.fBlockCount);

				{$IFC qDebug}
				write ('srcRect = '); writeRect (srcRect); writeln;
				{$ENDC}

				HalftoneArea (buffer2,
							  buffer1,
							  srcRect,
							  newRows,
							  newCols,
							  NIL,
							  NIL,
							  FALSE)

				END;

		MonochromeMode,
		MultichannelMode:
			HalftoneArea (doc.fData [0],
						  buffer1,
						  srcRect,
						  newRows,
						  newCols,
						  NIL,
						  NIL,
						  FALSE);

		IndexedColorMode:
			BEGIN
			FOR gray := 0 TO 255 DO
				map [gray] := ConvertToGray
						(doc.fIndexedColorTable.R [gray],
						 doc.fIndexedColorTable.G [gray],
						 doc.fIndexedColorTable.B [gray]);
			HalftoneArea (doc.fData [0],
						  buffer1,
						  srcRect,
						  newRows,
						  newCols,
						  @map,
						  NIL,
						  FALSE)
			END;

		RGBColorMode:
			BEGIN
			StartTask (0.5);
			buffer2 := MakeMonochromeArray (doc.fData [0],
											doc.fData [1],
											doc.fData [2]);
			FinishTask;
			HalftoneArea (buffer2,
						  buffer1,
						  srcRect,
						  newRows,
						  newCols,
						  NIL,
						  NIL,
						  FALSE)
			END;

		SeparationsCMYK:
			BEGIN
			buffer2 := NewVMArray (doc.fRows, doc.fCols, 1);
			StartTask (0.5);
			ConvertCMYK2Gray (doc.fData [0],
							  doc.fData [1],
							  doc.fData [2],
							  doc.fData [3],
							  buffer2);
			FinishTask;
			HalftoneArea (buffer2,
						  buffer1,
						  srcRect,
						  newRows,
						  newCols,
						  NIL,
						  NIL,
						  FALSE)
			END

		END;

	FinishTask;

	FreeObject (buffer2);
	buffer2 := NIL;

	dummyDoc := TImageDocument (gApplication.DoMakeDocument (cSave));

	dummyDoc.fMode	:= HalftoneMode;
	dummyDoc.fDepth := 1;
	dummyDoc.fRows	:= newRows;
	dummyDoc.fCols	:= newCols;

	dummyDoc.fData [0] := buffer1;
	buffer1 := NIL;

	MakePreviewPICT1 := MakePICT (dummyDoc);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S AEPSFormat}

FUNCTION TEPSFormat.MakePreviewPICT2 (doc: TImageDocument;
									  newRows: INTEGER;
									  newCols: INTEGER): Handle;

	VAR
		fi: FailInfo;
		channel: INTEGER;
		aVMArray: TVMArray;
		dummyDoc: TImageDocument;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (dummyDoc)
		END;

	BEGIN

	IF (doc.fRows <= newRows) AND
	   (doc.fCols <= newCols) AND
	   (doc.fMode <> SeparationsCMYK) THEN
		MakePreviewPICT2 := MakePICT (doc)

	ELSE
		BEGIN
		
		dummyDoc := TImageDocument (gApplication.DoMakeDocument (cSave));

		dummyDoc.fMode := doc.fMode;

		newRows := Min (doc.fRows, newRows);
		newCols := Min (doc.fCols, newCols);

		dummyDoc.fRows := newRows;
		dummyDoc.fCols := newCols;

		dummyDoc.fStyleInfo.fResolution.value :=
				Min (doc.fStyleInfo.fResolution.value, 72 * $10000);

		CatchFailures (fi, CleanUp);

		StartTask (0.7);

			CASE doc.fMode OF

			HalftoneMode:
				Failure (1, 0);

			MonochromeMode,
			IndexedColorMode,
			MultichannelMode:
				BEGIN

				aVMArray := NewVMArray (newRows, newCols, 1);
				dummyDoc.fData [0] := aVMArray;

				ResizeArray (doc.fData [0], aVMArray, TRUE, FALSE);

				dummyDoc.fIndexedColorTable := doc.fIndexedColorTable

				END;

			RGBColorMode:
				BEGIN

				dummyDoc.fChannels := 3;

				FOR channel := 0 TO 2 DO
					BEGIN

					StartTask (1 / (3 - channel));

					aVMArray := NewVMArray (newRows, newCols, 3 - channel);
					dummyDoc.fData [channel] := aVMArray;

					ResizeArray (doc.fData [channel], aVMArray, TRUE, FALSE);

					FinishTask

					END

				END;

			SeparationsCMYK:
				BEGIN

				dummyDoc.fMode := RGBColorMode;
				dummyDoc.fChannels := 4;

				StartTask (0.5);

				FOR channel := 0 TO 3 DO
					BEGIN

					StartTask (1 / (4 - channel));

					aVMArray := NewVMArray (newRows, newCols, 4 - channel);
					dummyDoc.fData [channel] := aVMArray;

					ResizeArray (doc.fData [channel], aVMArray, TRUE, FALSE);

					FinishTask

					END;

				FinishTask;

				ConvertCMYK2RGB (dummyDoc.fData [0],
								 dummyDoc.fData [1],
								 dummyDoc.fData [2],
								 dummyDoc.fData [3],
								 dummyDoc.fData [0],
								 dummyDoc.fData [1],
								 dummyDoc.fData [2])

				END;

			END;

		FinishTask;

		MakePreviewPICT2 := MakePICT (dummyDoc);

		Success (fi);

		CleanUp (0, 0)

		END

	END;

{*****************************************************************************}

{$S AEPSFormat}

PROCEDURE TEPSFormat.AddPreviewPICT (doc: TImageDocument;
									 newRows: INTEGER;
									 newCols: INTEGER);

	VAR
		err: OSErr;
		thePICT: Handle;

	BEGIN

	IF fDepth = 1 THEN
		thePICT := MakePreviewPICT1 (doc, newRows, newCols)
	ELSE
		thePICT := MakePreviewPICT2 (doc, newRows, newCols);

	AddResource (thePICT, 'PICT', 256, '');

	err := ResError;

	IF err <> noErr THEN
		BEGIN
		FreeLargeHandle (thePICT);
		FailOSErr (err)
		END
	ELSE
		VMAdjustReserve (-GetHandleSize (thePICT))

	END;

{*****************************************************************************}

{$S AEPSFormat}

PROCEDURE TEPSFormat.WritePostScript (doc: TImageDocument;
									  refNum: INTEGER;
									  channel: INTEGER;
									  dstSize: Point;
									  useDCS: BOOLEAN;
									  depth: INTEGER);

	VAR
		fi: FailInfo;
		mask: BOOLEAN;
		srcRect: Rect;
		dstRect: Rect;
		color: BOOLEAN;
		screen: BOOLEAN;
		transfer: BOOLEAN;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		EndPostScript
		END;

	BEGIN

	IF depth <> 0 THEN
		StartTask (0.5);

	fSpool := FALSE;

	fRefNum := refNum;

	srcRect.topLeft  := Point (0);
	srcRect.bottom	 := doc.fRows;
	srcRect.right	 := doc.fCols;

	dstRect.topLeft  := Point (0);
	dstRect.botRight := dstSize;

	color := (doc.fMode = IndexedColorMode) OR
			 (channel = kRGBChannels) OR
			 (channel = kCMYKChannels);

	screen	 := fIncludeScreen AND
				(doc.fMode <> HalftoneMode) AND NOT useDCS;

	transfer := fIncludeTransfer AND
				(doc.fMode <> HalftoneMode);

	mask := fTransparent AND (doc.fMode = HalftoneMode);

	IF mask THEN
		fTransferMode := srcOr
	ELSE
		fTransferMode := srcCopy;

	BeginPostScript (TRUE, fRefNum);

	CatchFailures (fi, CleanUp);

	GenerateEPSFHeader (doc,
						channel,
						srcRect,
						dstRect,
						useDCS,
						color,
						screen,
						transfer,
						fBinary);

	GeneratePostScript (doc,
						channel,
						srcRect,
						dstRect,
						color,
						screen,
						transfer,
						mask,
						fBinary,
						FALSE);

	FlushPostScript;

	Success (fi);

	EndPostScript;

	IF depth <> 0 THEN
		BEGIN
		FinishTask;
		AddPreviewPICT (doc, dstSize.v, dstSize.h)
		END

	END;

{*****************************************************************************}

{$S AEPSFormat}

PROCEDURE TEPSFormat.DoWrite (doc: TImageDocument; refNum: INTEGER); OVERRIDE;

	VAR
		s: Str255;
		err: OSErr;
		fi: FailInfo;
		dpi: EXTENDED;
		dstSize: Point;
		channel: INTEGER;
		auxOpen: BOOLEAN;
		aVMArray: TVMArray;
		auxRefNum: INTEGER;
		dummyDoc: TImageDocument;

	PROCEDURE GetFileName (VAR s: Str255; channel: INTEGER);

		VAR
			ss: Str255;

		BEGIN

		s := gReply.fName;

			CASE channel OF
			0:	ss := '.C';
			1:	ss := '.M';
			2:	ss := '.Y';
			3:	ss := '.K'
			END;

		IF LENGTH (s) > 29 THEN
			s [0] := CHR (29);

		INSERT (ss, s, LENGTH (s) + 1)

		END;

	PROCEDURE DeleteAuxFiles;

		VAR
			s: Str255;
			ignore: OSErr;
			channel: INTEGER;

		BEGIN

		FOR channel := 0 TO 3 DO
			BEGIN
			GetFileName (s, channel);
			ignore := DeleteFile (@s, gReply.vRefNum)
			END

		END;

	PROCEDURE CleanUp1 (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (dummyDoc)
		END;

	PROCEDURE CleanUp2 (error: INTEGER; message: LONGINT);

		VAR
			ignore: OSErr;

		BEGIN

		IF auxOpen THEN
			ignore := FSClose (auxRefNum);

		DeleteAuxFiles

		END;

	BEGIN

	IF doc.fMode = RGBColorMode THEN
		channel := kRGBChannels
	ELSE IF doc.fMode = SeparationsCMYK THEN
		channel := kCMYKChannels
	ELSE
		channel := 0;

	dpi := doc.fStyleInfo.fResolution.value / $10000;

	dstSize.v := Max (1, Min (kMaxCoord, ROUND (doc.fRows / dpi * 72)));
	dstSize.h := Max (1, Min (kMaxCoord, ROUND (doc.fCols / dpi * 72)));

	IF fFiveFiles AND (doc.fMode = SeparationsCMYK) THEN
		BEGIN

		StartTask (0.5);

		IF (doc.fRows > dstSize.v) OR (doc.fCols > dstSize.h) THEN
			BEGIN

			dummyDoc := TImageDocument (gApplication.DoMakeDocument (cSave));

			CatchFailures (fi, CleanUp1);

			dummyDoc.fMode		:= SeparationsCMYK;
			dummyDoc.fChannels	:= 4;
			dummyDoc.fRows		:= dstSize.v;
			dummyDoc.fCols		:= dstSize.h;
			dummyDoc.fStyleInfo := doc.fStyleInfo;

			dummyDoc.fStyleInfo.fResolution.value := 72 * $10000;

			StartTask (0.25);

			FOR channel := 0 TO 3 DO
				BEGIN

				StartTask (1 / (4 - channel));

				aVMArray := NewVMArray (dstSize.v, dstSize.h, 4 - channel);
				dummyDoc.fData [channel] := aVMArray;

				ResizeArray (doc.fData [channel], aVMArray, TRUE, FALSE);

				FinishTask

				END;

			FinishTask;

			WritePostScript (dummyDoc, refNum, kCMYKChannels,
							 dstSize, TRUE, fDepth);

			Success (fi);

			CleanUp1 (0, 0)

			END

		ELSE
			WritePostScript (doc, refNum, channel, dstSize, TRUE, fDepth);

		FinishTask;

		auxOpen := FALSE;

		CatchFailures (fi, CleanUp2);

		FOR channel := 0 TO 3 DO
			BEGIN

			StartTask (1 / (4 - channel));

			GetFileName (s, channel);
			
			err := Create (s, gReply.vRefNum, kSignature, fFileType);
			
			IF err = dupFNErr THEN
				BEGIN
				FailOSErr (DeleteFile (@s, gReply.vRefNum));
				err := Create (s, gReply.vRefNum, kSignature, fFileType)
				END;
				
			FailOSErr (err);

			FailOSErr (FSOpen (s, gReply.vRefNum, auxRefNum));

			auxOpen := TRUE;

			WritePostScript (doc, auxRefNum, channel, dstSize, FALSE, 0);

			auxOpen := FALSE;

			FailOSErr (FSClose (auxRefNum));

			FinishTask

			END;

		Success (fi)

		END

	ELSE
		WritePostScript (doc, refNum, channel, dstSize, FALSE, fDepth)

	END;

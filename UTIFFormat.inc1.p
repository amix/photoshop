{Photoshop version 1.0.1, file: UTIFFormat.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}
{$I UTIFFormat.a.inc}

{*****************************************************************************}

{$S AInit}

PROCEDURE TTIFFormat.IImageFormat; OVERRIDE;

	BEGIN

	INHERITED IImageFormat;

	fCanRead	  := TRUE;
	fReadType1	  := 'TIFF';
	fFileType	  := 'TIFF';
	fUsesDataFork := TRUE;

	fDialogID	   := 2400;
	fRadioClusters := 1;
	fRadio1Item    := 4;
	fRadio1Count   := 2;
	fCheckBoxes    := 1;
	fCheck1Item    := 6;

	fMotorola	:= TRUE;
	fCompressed := FALSE

	END;

{*****************************************************************************}

{$S AWriteFile}

FUNCTION TTIFFormat.CanWrite (doc: TImageDocument): BOOLEAN; OVERRIDE;

	BEGIN

	CanWrite := doc.fMode IN [HalftoneMode,
							  MonochromeMode,
							  IndexedColorMode,
							  RGBColorMode,
							  MultichannelMode]

	END;

{*****************************************************************************}

{$S ATIFFormat}

PROCEDURE TTIFFormat.SetFormatOptions (doc: TImageDocument); OVERRIDE;

	BEGIN

	fRadio1 := ORD (fMotorola);
	fCheck1 := fCompressed;

	DoOptionsDialog;

	fMotorola	:= (fRadio1 = 1);
	fCompressed := fCheck1

	END;

{*****************************************************************************}

{$S ATIFFormat}

PROCEDURE TTIFFormat.ParseTag (tagCode: INTEGER;
							   tagType: INTEGER;
							   tagCount: LONGINT);

	VAR
		x: CHAR;
		n: LONGINT;
		d: LONGINT;
		mark: LONGINT;
		which: INTEGER;
		index: INTEGER;

	BEGIN

		CASE tagCode OF

		256:
			IF tagType = 4 THEN
				fDoc.fCols := LoWrd (GetLong)
			ELSE
				fDoc.fCols := GetWord;

		257:
			BEGIN
			IF tagType = 4 THEN
				fDoc.fRows := LoWrd (GetLong)
			ELSE
				fDoc.fRows := GetWord;
			fRowsPerStrip := fDoc.fRows
			END;

		258:
			BEGIN
			fBitsPerSample := GetWord;
			FOR n := 2 TO tagCount DO
				IF fBitsPerSample <> GetWord THEN
					Failure (errBadTIFF, 0);
			IF (fBitsPerSample < 1) OR (fBitsPerSample > 8) THEN
				Failure (errTooDeepTIFF, 0)
			END;

		259:
			BEGIN
			fCompressionCode := GetWord;
			IF fCompressionCode = 0 THEN
				fCompressionCode := 1
			END;

		262:
			fPhotometricInterpretation := GetWord;

		266:
			IF GetWord <> 1 THEN Failure (errBadTIFF - 1, 0);

		273:
			BEGIN
			fStripOffsets := GetFilePosition;
			fLongStripOffsets := (tagType = 4)
			END;

		277:
			fDoc.fChannels := GetWord;

		278:
			BEGIN
			IF tagType = 4 THEN
				n := GetLong
			ELSE
				n := GetWord;
			IF n > 0 THEN
				fRowsPerStrip := Min (fDoc.fRows, n)
			ELSE
				fRowsPerStrip := fDoc.fRows
			END;

		279:
			BEGIN
			fStripByteCounts := GetFilePosition;
			fLongStripByteCounts := (tagType = 4)
			END;

		282:
			BEGIN
			n := GetLong;
			d := GetLong;
			IF d <> 0 THEN
				fResolution := n / d
			END;

		284:
			fPlanarConfiguration := GetWord;

		296:
			fMetric := (GetWord = 3);

		317:
			BEGIN
			fPredictor := GetWord;
			IF fPredictor <> 1 THEN
				IF (fPredictor <> 2) OR
				   (fCompressionCode <> 5) OR
				   (fBitsPerSample <> 8) THEN
					Failure (errCompressedTIFF, 0)
			END;

		320:
			BEGIN

			DoSetBytes (@fDoc.fIndexedColorTable,
						SIZEOF (TRGBLookUpTable),
						0);

			mark := GetFilePosition;

			FOR which := 0 TO 2 DO
				FOR index := 0 TO Min (256, tagCount DIV 3) - 1 DO
					BEGIN

					x := CHR (BAND (BSR (GetWord, 8), $FF));

						CASE which OF
						0:	fDoc.fIndexedColorTable.R [index] := x;
						1:	fDoc.fIndexedColorTable.G [index] := x;
						2:	fDoc.fIndexedColorTable.B [index] := x
						END

					END;

			FOR index := 0 TO 255 DO
				IF (fDoc.fIndexedColorTable.R [index] <> CHR (0)) OR
				   (fDoc.fIndexedColorTable.G [index] <> CHR (0)) OR
				   (fDoc.fIndexedColorTable.B [index] <> CHR (0)) THEN
					EXIT (ParseTag);

			{ Fix common TIFF bug }

			SeekTo (mark);

			FOR which := 0 TO 2 DO
				FOR index := 0 TO Min (256, tagCount DIV 3) - 1 DO
					BEGIN

					x := CHR (BAND (GetWord, $FF));

						CASE which OF
						0:	fDoc.fIndexedColorTable.R [index] := x;
						1:	fDoc.fIndexedColorTable.G [index] := x;
						2:	fDoc.fIndexedColorTable.B [index] := x
						END

					END

			END

		END

	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ATIFFormat}

PROCEDURE TTIFFormat.DecompressCCITT (VAR srcPtr: Ptr; dstPtr: Ptr);

	TYPE
		THuffmanTable = ARRAY [0..0] OF RECORD
			code  : INTEGER;
			branch: ARRAY [0..1] OF INTEGER
			END;
		PHuffmanTable = ^THuffmanTable;
		HHuffmanTable = ^PHuffmanTable;

	VAR
		p: Ptr;
		fi: FailInfo;
		bit: INTEGER;
		count: INTEGER;
		column: LONGINT;
		whiteTable: HHuffmanTable;
		blackTable: HHuffmanTable;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		HUnlock (Handle (whiteTable));
		HUnlock (Handle (blackTable))
		END;

	FUNCTION GetBit: BOOLEAN;
		BEGIN
		GetBit := BTST (srcPtr^, bit);
		bit := bit - 1;
		IF bit < 0 THEN
			BEGIN
			bit := 7;
			srcPtr := Ptr (ORD4 (srcPtr) + 1)
			END
		END;

	FUNCTION GetCode (table: PHuffmanTable): INTEGER;

		VAR
			entry: INTEGER;

		BEGIN

		entry := 0;

		{$PUSH}
		{$R-}

		WHILE entry <> -1 DO
			IF table^ [entry] . code <> -1 THEN
				BEGIN
				GetCode := table^ [entry] . code;
				EXIT (GetCode)
				END
			ELSE
				entry := table^ [entry] . branch [ORD (GetBit)];

		{$POP}

		Failure (errBadTIFF - 2, 0)

		END;

	FUNCTION GetWhite: INTEGER;

		VAR
			code: INTEGER;
			count: INTEGER;

		BEGIN
		count := 0;
			REPEAT
			code := GetCode (whiteTable^);
			count := count + code
			UNTIL code < 64;
		GetWhite := count
		END;

	FUNCTION GetBlack: INTEGER;

		VAR
			code: INTEGER;
			count: INTEGER;

		BEGIN
		count := 0;
			REPEAT
			code := GetCode (blackTable^);
			count := count + code
			UNTIL code < 64;
		GetBlack := count
		END;

	BEGIN

	whiteTable := HHuffmanTable (GetResource ('HUFF', 1));
	FailNil (whiteTable);

	HLock (Handle (whiteTable));

	blackTable := HHuffmanTable (GetResource ('HUFF', 2));
	FailNil (blackTable);

	HLock (Handle (blackTable));

	CatchFailures (fi, CleanUp);

	bit := 7;

	column := 0;

	DoSetBytes (dstPtr, BSR (fDoc.fCols + 7, 3), 0);

	WHILE column < fDoc.fCols DO
		BEGIN

		column := column + GetWhite;

		IF column >= fDoc.fCols THEN LEAVE;

		count := GetBlack;

		IF column + count > fDoc.fCols THEN LEAVE;

		WHILE count > 0 DO
			BEGIN

			count := count - 1;

			p  := Ptr (ORD4 (dstPtr) + BSR (column, 3));
			p^ := p^ + BSR ($80, BAND (column, 7));

			column := column + 1

			END

		END;

	IF column <> fDoc.fCols THEN Failure (errBadTIFF - 3, 0);

	IF bit <> 7 THEN srcPtr := Ptr (ORD4 (srcPtr) + 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ATIFFormat}

PROCEDURE TTIFFormat.DecompressLZW (srcPtr, dstPtr: Ptr; count: LONGINT);

	VAR
		fi: FailInfo;
		bitsUsed: LONGINT;

	FUNCTION GetCodeWord: INTEGER;
		BEGIN
		GetCodeWord := ExtractTIFF (srcPtr, bitsUsed, lzwWordSize);
		bitsUsed := bitsUsed + lzwWordSize
		END;

	PROCEDURE PutData (pixel: INTEGER);
		BEGIN

		IF BAND (count, $FF) = 0 THEN
			MoveHands (NOT fDoc.fReverting);

		count := count - 1;

		IF count >= 0 THEN
			BEGIN

			{$PUSH}
			{$R-}
			dstPtr^ := pixel;
			{$POP}

			dstPtr := Ptr (ORD4 (dstPtr) + 1)

			END

		END;
		
	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF (error <> 0) AND (count <= 0) THEN
			EXIT (DecompressLZW);
		END;

	BEGIN
	
	CatchFailures (fi, CleanUp);
	
	bitsUsed := 0;

	LZWExpand (8, errBadTIFF - 4, GetCodeWord, PutData, TRUE);
	
	Success (fi);

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S ATIFFormat}

PROCEDURE DeltaDecode (srcPtr: Ptr; count: INTEGER; step: INTEGER);

	VAR
		index: INTEGER;
		pixel: INTEGER;

	BEGIN

	WHILE count > 1 DO
		BEGIN

		pixel := srcPtr^;

		srcPtr := Ptr (ORD4 (srcPtr) + step);

		{$PUSH}
		{$R-}
		srcPtr^ := pixel + srcPtr^;
		{$POP}

		count := count - 1

		END

	END;

{*****************************************************************************}

{$S ATIFFormat}

PROCEDURE DeltaEncode (srcPtr: Ptr; count: INTEGER; step: INTEGER);

	VAR
		dstPtr: Ptr;
		index: INTEGER;
		pixel: INTEGER;

	BEGIN

	srcPtr := Ptr (ORD4 (srcPtr) + ORD4 (count - 1) * step);

	WHILE count > 1 DO
		BEGIN

		dstPtr := Ptr (ORD4 (srcPtr) - step);

		{$PUSH}
		{$R-}
		srcPtr^ := srcPtr^ - dstPtr^;
		{$POP}

		srcPtr := dstPtr;

		count := count - 1

		END

	END;

{*****************************************************************************}

{$S ATIFFormat}

PROCEDURE TTIFFormat.ReadPlaneStrip (plane: INTEGER;
									 strip: INTEGER;
									 count: LONGINT);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		row1: INTEGER;
		row2: INTEGER;
		buffer1: Handle;
		buffer2: Handle;
		rowBytes: INTEGER;
		stripBytes: LONGINT;

	PROCEDURE ExtractRow (srcPtr: Ptr);

		VAR
			dstPtr: Ptr;
			column: INTEGER;
			offset: LONGINT;

		BEGIN

		dstPtr := fDoc.fData [plane] . NeedPtr (row, row, TRUE);

		IF fPredictor = 2 THEN
			DeltaDecode (srcPtr, fDoc.fCols, 1);

		IF fBitsPerSample = fDoc.fDepth THEN
			BlockMove (srcPtr, dstPtr, rowBytes)

		ELSE IF fBitsPerSample = 4 THEN
			FOR column := 0 TO fDoc.fCols - 1 DO
				BEGIN
				IF ODD (column) THEN
					BEGIN
					dstPtr^ := BAND (srcPtr^, $F);
					srcPtr	:= Ptr (ORD4 (srcPtr) + 1)
					END
				ELSE
					dstPtr^ := BAND (BSR (srcPtr^, 4), $F);
				dstPtr := Ptr (ORD4 (dstPtr) + 1)
				END

		ELSE IF fBitsPerSample = 2 THEN
			FOR column := 0 TO fDoc.fCols - 1 DO
				BEGIN
					CASE BAND (column, $3) OF
					0:	dstPtr^ := BAND (BSR (srcPtr^, 6), $3);
					1:	dstPtr^ := BAND (BSR (srcPtr^, 4), $3);
					2:	dstPtr^ := BAND (BSR (srcPtr^, 2), $3);
					3:	BEGIN
						dstPtr^ := BAND (srcPtr^, $3);
						srcPtr	:= Ptr (ORD4 (srcPtr) + 1)
						END
					END;
				dstPtr := Ptr (ORD4 (dstPtr) + 1)
				END

		ELSE
			BEGIN
			offset := 0;
			FOR column := 1 TO fDoc.fCols DO
				BEGIN
				dstPtr^ := ExtractTIFF (srcPtr, offset, fBitsPerSample);
				dstPtr	:= Ptr (ORD4 (dstPtr) + 1);
				offset	:= offset + fBitsPerSample
				END
			END;

		fDoc.fData [plane] . DoneWithPtr

		END;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (buffer1);
		FreeLargeHandle (buffer2)
		END;

	BEGIN

	row1 := strip * fRowsPerStrip;
	row2 := Min (fDoc.fRows, row1 + fRowsPerStrip) - 1;

	rowBytes := BSR (fBitsPerSample * ORD4 (fDoc.fCols) + 7, 3);

	IF fCompressionCode = 1 THEN
		BEGIN

		IF (fBitsPerSample = 1) AND (fDoc.fDepth = 1) AND (row2 > row1) THEN
			BEGIN
			StartTask ((row2 - row1 + 1) / (fDoc.fRows - row1));
			GetRawRows (fDoc.fData [plane],
						BSR (fDoc.fCols + 7, 3),
						row1,
						row2 - row1 + 1,
						NOT fDoc.fReverting);
			FinishTask
			END

		ELSE IF (fBitsPerSample = 8) AND (row2 > row1) THEN
			BEGIN
			StartTask ((row2 - row1 + 1) / (fDoc.fRows - row1));
			GetRawRows (fDoc.fData [plane],
						fDoc.fCols,
						row1,
						row2 - row1 + 1,
						NOT fDoc.fReverting);
			FinishTask
			END

		ELSE
			BEGIN

			FOR row := row1 TO row2 DO
				BEGIN
				MoveHands (NOT fDoc.fReverting);
				UpdateProgress (row, fDoc.fRows);
				GetBytes (rowBytes, gBuffer);
				ExtractRow (gBuffer)
				END;

			UpdateProgress (row2 + 1, fDoc.fRows);

			fDoc.fData [plane] . Flush

			END

		END

	ELSE
		BEGIN

		buffer1 := NIL;
		buffer2 := NIL;

		CatchFailures (fi, CleanUp);

		stripBytes := rowBytes * ORD4 (row2 - row1 + 1);

		IF count = 0 THEN
			BEGIN

			IF fCompressionCode = 5 THEN
				count := stripBytes * 2 + 32

			ELSE IF fCompressionCode = $8005 THEN
				count := stripBytes + BSR (stripBytes, 6) + 2

			ELSE
				count := stripBytes * 5 + 32

			END;

		count := Min (count, GetFileLength - GetFilePosition);

		buffer1 := NewLargeHandle (count);

		IF fCompressionCode = 5 THEN
			buffer2 := NewLargeHandle (stripBytes)
		ELSE
			buffer2 := NewLargeHandle (rowBytes);

		HLock (buffer1);
		HLock (buffer2);

		GetBytes (count, buffer1^);

		srcPtr := buffer1^;
		dstPtr := buffer2^;

		IF fCompressionCode = 5 THEN
			DecompressLZW (srcPtr, dstPtr, stripBytes);

		FOR row := row1 TO row2 DO
			BEGIN

			MoveHands (NOT fDoc.fReverting);

			UpdateProgress (row, fDoc.fRows);

			IF fCompressionCode = 2 THEN
				DecompressCCITT (srcPtr, dstPtr)

			ELSE IF fCompressionCode = $8005 THEN
				BEGIN
				UnPackBits (srcPtr, dstPtr, rowBytes);
				dstPtr := buffer2^
				END

			ELSE IF fCompressionCode <> 5 THEN
				Failure (errCompressedTIFF, 0);

			ExtractRow (dstPtr);

			IF fCompressionCode = 5 THEN
				dstPtr := Ptr (ORD4 (dstPtr) + rowBytes)

			END;

		UpdateProgress (row2 + 1, fDoc.fRows);

		fDoc.fData [plane] . Flush;

		Success (fi);

		CleanUp (0, 0)

		END

	END;

{*****************************************************************************}

{$S ATIFFormat}

PROCEDURE TTIFFormat.ReadRGBStrip (strip: INTEGER; count: LONGINT);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		row1: INTEGER;
		row2: INTEGER;
		buffer1: Handle;
		buffer2: Handle;
		channel: INTEGER;
		rowBytes: LONGINT;
		stripBytes: LONGINT;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (buffer1);
		FreeLargeHandle (buffer2)
		END;

	BEGIN

	IF (fDoc.fChannels <> 3) OR (fBitsPerSample <> 8) THEN
		Failure (errBadTIFF - 5, 0);

	row1 := strip * fRowsPerStrip;
	row2 := Min (fDoc.fRows, row1 + fRowsPerStrip) - 1;

	IF fCompressionCode = 1 THEN
		BEGIN
		StartTask ((row2 - row1 + 1) / (fDoc.fRows - row1));
		GetInterleavedRows (fDoc.fData,
							3,
							row1,
							row2 - row1 + 1,
							NOT fDoc.fReverting);
		FinishTask
		END

	ELSE IF fCompressionCode = 5 THEN
		BEGIN

		buffer1 := NIL;
		buffer2 := NIL;

		CatchFailures (fi, CleanUp);

		rowBytes := 3 * ORD4 (fDoc.fCols);
		stripBytes := rowBytes * (row2 - row1 + 1);

		IF count = 0 THEN
			count := Min (stripBytes * 2 + 32,
						  GetFileLength - GetFilePosition);

		buffer1 := NewLargeHandle (count);
		buffer2 := NewLargeHandle (stripBytes);

		HLock (buffer1);
		HLock (buffer2);

		GetBytes (count, buffer1^);
		
		DecompressLZW (buffer1^, buffer2^, stripBytes);

		srcPtr := buffer2^;

		FOR row := row1 TO row2 DO
			BEGIN

			MoveHands (NOT fDoc.fReverting);

			UpdateProgress (row, fDoc.fRows);

			FOR channel := 0 TO 2 DO
				BEGIN

				dstPtr := fDoc.fData [channel] . NeedPtr (row, row, TRUE);

				IF fPredictor = 2 THEN
					DeltaDecode (Ptr (ORD4 (srcPtr) + channel),
								 fDoc.fCols, 3);

				DoStepCopyBytes (Ptr (ORD4 (srcPtr) + channel),
								 dstPtr, fDoc.fCols, 3, 1);

				fDoc.fData [channel] . DoneWithPtr

				END;

			srcPtr := Ptr (ORD4 (srcPtr) + rowBytes)

			END;

		UpdateProgress (row2 + 1, fDoc.fRows);

		FOR channel := 0 TO 2 DO
			fDoc.fData [channel] . Flush;

		Success (fi);

		CleanUp (0, 0)

		END

	ELSE
		Failure (errCompressedTIFF, 0);

	END;

{*****************************************************************************}

{$S ATIFFormat}

PROCEDURE TTIFFormat.AdjustPlane (plane: INTEGER);

	VAR
		gray: INTEGER;
		diff: INTEGER;
		half: INTEGER;
		map: TLookUpTable;

	BEGIN

	IF (fPhotometricInterpretation < 0) OR
	   (fPhotometricInterpretation > 3) THEN Failure (errBadTIFF - 6, 0);

	IF fDoc.fDepth = 1 THEN
		BEGIN

		IF fCompressionCode = 2 THEN
			fPhotometricInterpretation := 0;

		IF fPhotometricInterpretation = 1 THEN
			fDoc.fData [0] . MapBytes (gInvertLUT);

		EXIT (AdjustPlane)

		END;

	IF fPhotometricInterpretation = 3 THEN
		fDoc.fMode := IndexedColorMode

	ELSE IF fPhotometricInterpretation <> 2 THEN
		BEGIN

		diff := BSL (1, fBitsPerSample) - 1;
		half := BSR (diff, 1);

		FOR gray := 0 TO 255 DO
			IF gray >= diff THEN
				map [gray] := CHR (255)
			ELSE
				map [gray] := CHR ((ORD4 (gray) * 255 + half) DIV diff);

		IF fPhotometricInterpretation = 0 THEN
			FOR gray := 0 TO 255 DO
				map [gray] := CHR (255 - ORD (map [gray]));

		IF NOT EqualBytes (@map, @gNullLUT, 256) THEN
			fDoc.fData [plane] . MapBytes (map)

		END

	END;

{*****************************************************************************}

{$S ATIFFormat}

PROCEDURE TTIFFormat.AddBitPlane (srcArray: TVMArray;
								  dstArray: TVMArray);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		row: INTEGER;

	BEGIN

	FOR row := 0 TO srcArray.fBlockCount - 1 DO
		BEGIN

		srcPtr := srcArray.NeedPtr (row, row, FALSE);
		dstPtr := dstArray.NeedPtr (row, row, TRUE);

		AddTIFFPlane (srcPtr, dstPtr, srcArray.fLogicalSize);

		srcArray.DoneWithPtr;
		dstArray.DoneWithPtr

		END;

	srcArray.Flush;
	dstArray.Flush

	END;

{*****************************************************************************}

{$S ATIFFormat}

PROCEDURE TTIFFormat.DoRead (doc: TImageDocument;
							 refNum: INTEGER;
							 rsrcExists: BOOLEAN); OVERRIDE;

	TYPE
		LongArray  = ARRAY [0..99999] OF LONGINT;
		PLongArray = ^LongArray;
		HLongArray = ^PLongArray;

	VAR
		fi: FailInfo;
		entry: INTEGER;
		plane: INTEGER;
		strip: INTEGER;
		count: LONGINT;
		index: LONGINT;
		offset: LONGINT;
		entries: INTEGER;
		tagCode: INTEGER;
		tagType: INTEGER;
		tagSize: LONGINT;
		tagCount: LONGINT;
		aVMArray: TVMArray;
		directory: LONGINT;
		stripCounts: HLongArray;
		stripsPerPlane: INTEGER;
		stripsPerImage: LONGINT;
		stripOffsets: HLongArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (Handle (stripCounts));
		FreeLargeHandle (Handle (stripOffsets))
		END;

	BEGIN

	fRefNum := refNum;

	MoveHands (NOT doc.fReverting);

	fDoc := doc;

	doc.fRows := 0;
	doc.fCols := 0;

	fResolution := 0;
	fMetric := FALSE;

	fPredictor := 1;
	fBitsPerSample := 1;
	fCompressionCode := 1;
	fPlanarConfiguration := 1;
	fPhotometricInterpretation := 0;

	fStripOffsets := 0;
	fStripByteCounts := 0;

		CASE GetWord OF

		$4949:	fLSBFirst := TRUE;
		$4D4D:	fLSBFirst := FALSE;

		OTHERWISE
			Failure (errBadTIFF - 7, 0);

		END;

	IF GetWord <> 42 THEN Failure (errBadTIFF - 8, 0);

	directory := GetLong;

	SeekTo (directory);

	entries := GetWord;

	FOR entry := 0 TO entries - 1 DO
		BEGIN

		SeekTo (directory + 12 * entry + 2);

		tagCode  := GetWord;
		tagType  := GetWord;
		tagCount := GetLong;

			CASE tagType OF

			1,2:	tagSize := tagCount;
			3:		tagSize := BSL (tagCount, 1);
			4:		tagSize := BSL (tagCount, 2);
			5:		tagSize := BSL (tagCount, 3);

			OTHERWISE
				Failure (errBadTIFF - 9, 0)

			END;

		IF tagSize > 4 THEN SeekTo (GetLong);

		ParseTag (tagCode, tagType, tagCount)

		END;

	IF fMetric THEN
		fResolution := fResolution * 2.54;

	IF (fResolution >= 1) AND (fResolution <= 3200) THEN
		BEGIN

		doc.fStyleInfo.fResolution.value := ROUND (fResolution * $10000);

		IF fMetric THEN
			BEGIN
			doc.fStyleInfo.fResolution.scale := 2;
			doc.fStyleInfo.fWidthUnit		 := 2;
			doc.fStyleInfo.fHeightUnit		 := 2
			END

		END;

	IF (doc.fChannels = 1) AND (fBitsPerSample = 1) THEN
		doc.fDepth := 1;

	IF doc.fChannels = 1 THEN
		fPlanarConfiguration := 2;

	IF NOT doc.ValidSize OR
		(fPlanarConfiguration < 1) OR
		(fPlanarConfiguration > 2) OR
		(fStripOffsets = 0) THEN Failure (errBadTIFF, 0);

	doc.DefaultMode;

	IF doc.fDepth = 1 THEN
		BEGIN
		aVMArray := NewVMArray (doc.fRows,
								BSL (BSR (doc.fCols + 15, 4), 1),
								1);
		doc.fData [0] := aVMArray
		END
	ELSE
		FOR plane := 0 TO doc.fChannels - 1 DO
			BEGIN
			aVMArray := NewVMArray (doc.fRows,
									doc.fCols,
									doc.Interleave (plane));
			doc.fData [plane] := aVMArray
			END;

	stripsPerPlane := (doc.fRows - 1) DIV fRowsPerStrip + 1;

	IF fPlanarConfiguration = 1 THEN
		stripsPerImage := stripsPerPlane
	ELSE
		stripsPerImage := stripsPerPlane * ORD4 (doc.fChannels);

	stripCounts := NIL;
	stripOffsets := NIL;

	CatchFailures (fi, CleanUp);

	IF (fStripByteCounts <> 0) AND (fCompressionCode <> 1) THEN
		BEGIN

		stripCounts := HLongArray (NewLargeHandle (stripsPerImage * 4));

		SeekTo (fStripByteCounts);

		FOR index := 0 TO stripsPerImage - 1 DO
			BEGIN

			IF fLongStripByteCounts THEN
				count := GetLong
			ELSE
				count := BAND ($0FFFF, GetWord);

			IF count <= 0 THEN Failure (errBadTIFF - 1, 0);

			stripCounts^^ [index] := count

			END

		END;

	stripOffsets := HLongArray (NewLargeHandle (stripsPerImage * 4));

	SeekTo (fStripOffsets);

	FOR index := 0 TO stripsPerImage - 1 DO
		BEGIN

		IF fLongStripOffsets THEN
			offset := GetLong
		ELSE
			offset := BAND ($0FFFF, GetWord);

		stripOffsets^^ [index] := offset

		END;

	IF fPlanarConfiguration = 1 THEN
		FOR strip := 0 TO stripsPerPlane - 1 DO
			BEGIN

			IF stripCounts = NIL THEN
				count := 0
			ELSE
				count := stripCounts^^ [strip];

			SeekTo (stripOffsets^^ [strip]);

			ReadRGBStrip (strip, count)

			END

	ELSE
		FOR plane := 0 TO doc.fChannels - 1 DO
			BEGIN

			StartTask (1 / (doc.fChannels - plane));

			FOR strip := 0 TO stripsPerPlane - 1 DO
				BEGIN

				index := plane * ORD4 (stripsPerPlane) + strip;

				IF stripCounts = NIL THEN
					count := 0
				ELSE
					count := stripCounts^^ [index];

				SeekTo (stripOffsets^^ [index]);

				ReadPlaneStrip (plane, strip, count)

				END;

			FinishTask

			END;

	Success (fi);

	CleanUp (0, 0);

	FOR plane := 0 TO doc.fChannels - 1 DO
		AdjustPlane (plane);

	IF (doc.fMode = IndexedColorMode) AND (doc.fChannels > 1) THEN
		BEGIN

		IF fBitsPerSample <> 1 THEN
			Failure (errBadTIFF - 2, 0);

		FOR plane := doc.fChannels - 2 DOWNTO 0 DO
			BEGIN
			AddBitPlane (doc.fData [plane],
						 doc.fData [doc.fChannels - 1]);
			doc.fData [plane] . Free;
			doc.fData [plane] := NIL
			END;

		doc.fData [0] := doc.fData [doc.fChannels - 1];

		doc.fData [doc.fChannels - 1] := NIL;

		doc.fChannels := 1

		END

	END;

{*****************************************************************************}

{$S ATIFFormat}

FUNCTION TTIFFormat.DataForkBytes (doc: TImageDocument): LONGINT; OVERRIDE;

	BEGIN

	IF fCompressed THEN
		DataForkBytes := 0

	ELSE
		CASE doc.fMode OF

		HalftoneMode:
			DataForkBytes := doc.fRows * BSR (doc.fCols + 7, 3);

		RGBColorMode:
			DataForkBytes := 3 * ORD4 (doc.fRows) * doc.fCols;

		OTHERWISE
			DataForkBytes := doc.fRows * ORD4 (doc.fCols)

		END

	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ATIFFormat}

FUNCTION TTIFFormat.CompressStrip (srcPtr: Ptr;
								   dstPtr: Ptr;
								   srcBytes: LONGINT;
								   dstBytes: LONGINT): LONGINT;

	VAR
		bitsUsed: LONGINT;

	FUNCTION GetData (VAR pixel: INTEGER): BOOLEAN;

		BEGIN

		IF srcBytes > 0 THEN
			BEGIN

			IF BAND (srcBytes, $FF) = 0 THEN
				MoveHands (FALSE);

			pixel := BAND ($FF, srcPtr^);

			srcPtr := Ptr (ORD4 (srcPtr) + 1);
			srcBytes := srcBytes - 1;

			GetData := TRUE

			END

		ELSE
			GetData := FALSE

		END;

	PROCEDURE PutCodeWord (code: INTEGER);

		BEGIN
		
		bitsUsed := bitsUsed + lzwWordSize;

		IF BSR (bitsUsed + 7, 3) > dstBytes THEN
			Failure (1, 0);

		StuffTIFF (dstPtr, bitsUsed, code)

		END;

	BEGIN
	
	bitsUsed := 0;

	DoSetBytes (dstPtr, dstBytes, 0);

	LZWCompress (8, GetData, PutCodeWord, TRUE);

	CompressStrip := BSR (bitsUsed + 7, 3)

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S ATIFFormat}

PROCEDURE TTIFFormat.WriteLZW (doc: TImageDocument;
							   stripsPerImage: INTEGER;
							   rowBytes: LONGINT);

	TYPE
		LongArray  = ARRAY [0..kMaxCoord] OF LONGINT;
		PLongArray = ^LongArray;
		HLongArray = ^PLongArray;

	VAR
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		row1: INTEGER;
		row2: INTEGER;
		size: LONGINT;
		strip: INTEGER;
		count: LONGINT;
		buffer1: Handle;
		buffer2: Handle;
		stripCounts: HLongArray;
		stripOffsets: HLongArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (buffer1);
		FreeLargeHandle (buffer2);
		FreeLargeHandle (Handle (stripCounts));
		FreeLargeHandle (Handle (stripOffsets))
		END;

	BEGIN

	buffer1 	 := NIL;
	buffer2 	 := NIL;
	stripCounts  := NIL;
	stripOffsets := NIL;

	CatchFailures (fi, CleanUp);

	size := BSL (stripsPerImage, 2);

	stripCounts  := HLongArray (NewLargeHandle (size));
	stripOffsets := HLongArray (NewLargeHandle (size));

	buffer1 := NewLargeHandle (rowBytes * fRowsPerStrip);
	buffer2 := NewLargeHandle (2 * rowBytes * fRowsPerStrip + 32);

	HLock (buffer1);
	HLock (buffer2);

	FOR strip := 0 TO stripsPerImage - 1 DO
		BEGIN

		stripOffsets^^[strip] := GetFilePosition;

		row1 := strip * fRowsPerStrip;
		row2 := Min (row1 + fRowsPerStrip, doc.fRows) - 1;

		dstPtr := buffer1^;

		FOR row := row1 TO row2 DO
			BEGIN

			UpdateProgress (row, doc.fRows);

			IF doc.fMode = RGBColorMode THEN
				BEGIN

				DoStepCopyBytes (doc.fData [0] . NeedPtr (row, row, FALSE),
								 dstPtr,
								 doc.fCols, 1, 3);
				DoStepCopyBytes (doc.fData [1] . NeedPtr (row, row, FALSE),
								 Ptr (ORD4 (dstPtr) + 1),
								 doc.fCols, 1, 3);
				DoStepCopyBytes (doc.fData [2] . NeedPtr (row, row, FALSE),
								 Ptr (ORD4 (dstPtr) + 2),
								 doc.fCols, 1, 3);

				IF fPredictor = 2 THEN
					BEGIN
					DeltaEncode (dstPtr 				, doc.fCols, 3);
					DeltaEncode (Ptr (ORD4 (dstPtr) + 1), doc.fCols, 3);
					DeltaEncode (Ptr (ORD4 (dstPtr) + 2), doc.fCols, 3)
					END;

				doc.fData [0] . DoneWithPtr;
				doc.fData [1] . DoneWithPtr;
				doc.fData [2] . DoneWithPtr

				END

			ELSE
				BEGIN

				BlockMove (doc.fData [0] . NeedPtr (row, row, FALSE),
						   dstPtr,
						   rowBytes);

				IF fPredictor = 2 THEN
					DeltaEncode (dstPtr, doc.fCols, 1);

				doc.fData [0] . DoneWithPtr

				END;

			dstPtr := Ptr (ORD4 (dstPtr) + rowBytes)

			END;

		doc.fData [0] . Flush;

		IF doc.fMode = RGBColorMode THEN
			BEGIN
			doc.fData [1] . Flush;
			doc.fData [2] . Flush
			END;

		count := CompressStrip (buffer1^,
								buffer2^,
								rowBytes * (row2 - row1 + 1),
								GetHandleSize (buffer2));

		PutBytes (count, buffer2^);

		IF ODD (count) THEN
			PutByte (0);

		stripCounts^^[strip] := count

		END;

	UpdateProgress (1, 1);

	SeekTo (fStripOffsets);
	
	FOR strip := 0 TO stripsPerImage - 1 DO
		PutLong (stripOffsets^^[strip]);

	SeekTo (fStripByteCounts);

	FOR strip := 0 TO stripsPerImage - 1 DO
		PutLong (stripCounts^^[strip]);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ATIFFormat}

PROCEDURE TTIFFormat.DoWrite (doc: TImageDocument; refNum: INTEGER); OVERRIDE;

	VAR
		x: EXTENDED;
		tags: INTEGER;
		offset: LONGINT;
		rowBytes: LONGINT;
		stripsPerImage: INTEGER;

	BEGIN

	fRefNum := refNum;

	MoveHands (FALSE);

	fLSBFirst := NOT fMotorola;

	IF fMotorola THEN
		PutWord ($4D4D)
	ELSE
		PutWord ($4949);

	PutWord (42);
	PutLong (8);

		CASE doc.fMode OF

		HalftoneMode:
			rowBytes := BSR (doc.fCols + 7, 3);

		RGBColorMode:
			rowBytes := 3 * ORD4 (doc.fCols);

		OTHERWISE
			rowBytes := doc.fCols

		END;

	IF fCompressed THEN
		BEGIN
		fRowsPerStrip  := Min (doc.fRows, Max (1, $2000 DIV rowBytes));
		stripsPerImage := (doc.fRows - 1) DIV fRowsPerStrip + 1
		END
	ELSE
		BEGIN
		fRowsPerStrip  := doc.fRows;
		stripsPerImage := 1
		END;

	IF doc.fMode IN [IndexedColorMode, RGBColorMode] THEN
		tags := 14
	ELSE
		tags := 13;

	IF fCompressed THEN
		tags := tags + 1;

	PutWord (tags);

	offset := 14 + 12 * tags;

	PutWord (254);	{ NewSubfileType }
	PutWord (4);
	PutLong (1);
	PutLong (0);

	PutWord (256);	{ ImageWidth }
	PutWord (3);
	PutLong (1);
	PutWord (doc.fCols);
	PutWord (0);

	PutWord (257);	{ ImageLength }
	PutWord (3);
	PutLong (1);
	PutWord (doc.fRows);
	PutWord (0);

	PutWord (258);	{ BitsPerSample }
	PutWord (3);
	IF doc.fMode = RGBColorMode THEN
		BEGIN
		PutLong (3);
		PutLong (offset);
		offset := offset + 6
		END
	ELSE
		BEGIN
		PutLong (1);
		PutWord (doc.fDepth);
		PutWord (0)
		END;

	PutWord (259);	{ Compression }
	PutWord (3);
	PutLong (1);
	IF fCompressed THEN
		PutWord (5)
	ELSE
		PutWord (1);
	PutWord (0);

	PutWord (262);	{ PhotometricInterpretation }
	PutWord (3);
	PutLong (1);
		CASE doc.fMode OF
		HalftoneMode:
			PutWord (0);
		RGBColorMode:
			PutWord (2);
		IndexedColorMode:
			PutWord (3);
		OTHERWISE
			PutWord (1)
		END;
	PutWord (0);

	PutWord (273);	{ StripOffsets }
	PutWord (4);
	PutLong (stripsPerImage);
	IF stripsPerImage = 1 THEN
		BEGIN
		fStripOffsets := GetFilePosition;
		PutLong (0)
		END
	ELSE
		BEGIN
		fStripOffsets := offset;
		PutLong (offset);
		offset := offset + 4 * ORD4 (stripsPerImage)
		END;

	PutWord (277);	{ SamplesPerPixel }
	PutWord (3);
	PutLong (1);
	IF doc.fMode = RGBColorMode THEN
		PutWord (3)
	ELSE
		PutWord (1);
	PutWord (0);

	PutWord (278);	{ RowsPerStrip }
	PutWord (3);
	PutLong (1);
	PutWord (fRowsPerStrip);
	PutWord (0);

	PutWord (279);	{ StripByteCounts }
	PutWord (4);
	PutLong (stripsPerImage);
	IF stripsPerImage = 1 THEN
		BEGIN
		fStripByteCounts := GetFilePosition;
		PutLong (rowBytes * doc.fRows)
		END
	ELSE
		BEGIN
		fStripByteCounts := offset;
		PutLong (offset);
		offset := offset + 4 * ORD4 (stripsPerImage)
		END;

	PutWord (282);	{ X Resolution }
	PutWord (5);
	PutLong (1);
	PutLong (offset);

	PutWord (283);	{ Y Resolution }
	PutWord (5);
	PutLong (1);
	PutLong (offset);
	offset := offset + 8;

	IF doc.fMode = RGBColorMode THEN
		BEGIN
		PutWord (284);	{ PlanarConfiguration }
		PutWord (3);
		PutLong (1);
		PutWord (1);
		PutWord (0)
		END;

	PutWord (296);	{ ResolutionUnit }
	PutWord (3);
	PutLong (1);
	IF doc.fStyleInfo.fResolution.scale = 1 THEN
		PutWord (2)
	ELSE
		PutWord (3);
	PutWord (0);

	IF fCompressed THEN
		BEGIN
		PutWord (317);	{ Predictor }
		PutWord (3);
		PutLong (1);
		IF doc.fMode IN [HalftoneMode, IndexedColorMode] THEN
			fPredictor := 1
		ELSE
			fPredictor := 2;
		PutWord (fPredictor);
		PutWord (0)
		END;

	IF doc.fMode = IndexedColorMode THEN
		BEGIN
		PutWord (320);	{ ColorMap }
		PutWord (3);
		PutLong (768);
		PutLong (offset);
		offset := offset + 2 * 768
		END;

	PutLong (0);	{ End-of-directory }

	IF doc.fMode = RGBColorMode THEN
		BEGIN
		PutWord (8);
		PutWord (8);
		PutWord (8)
		END;

	IF stripsPerImage <> 1 THEN
		PutZeros (8 * ORD4 (stripsPerImage));

	x := doc.fStyleInfo.fResolution.value / $10000;

	IF doc.fStyleInfo.fResolution.scale <> 1 THEN
		x := x / 2.54;

	PutLong (ROUND (x * 10000));
	PutLong (10000);

	IF doc.fMode = IndexedColorMode THEN
		BEGIN

		DoStepCopyBytes (@doc.fIndexedColorTable,
						 gBuffer,
						 768,
						 1,
						 2);

		DoStepCopyBytes (gBuffer,
						 Ptr (ORD4 (gBuffer) + 1),
						 768,
						 2,
						 2);

		PutBytes (2 * 768, gBuffer)

		END;

	IF fCompressed THEN
		WriteLZW (doc, stripsPerImage, rowBytes)

	ELSE
		BEGIN

		SeekTo	(fStripOffsets);
		PutLong (offset);
		SeekTo	(offset);

		IF doc.fMode = RGBColorMode THEN
			PutInterleavedRows (doc.fData, 3, 0, doc.fRows)
		ELSE
			PutRawRows (doc.fData [0], rowBytes, 0, doc.fRows);

		IF ODD (GetFilePosition) THEN PutByte (0)

		END

	END;

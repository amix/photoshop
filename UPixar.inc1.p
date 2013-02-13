{Photoshop version 1.0.1, file: UPixar.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}

TYPE
	TwelveBitLUT = ARRAY [0..4095] OF CHAR;

{*****************************************************************************}

{$S AInit}

PROCEDURE TPixarFormat.IImageFormat; OVERRIDE;

	BEGIN

	INHERITED IImageFormat;

	fFTypeItem	  := 4;
	fFCreatorItem := 5;

	fCanRead	  := TRUE;
	fReadType1	  := 'PXR ';
	fFileType	  := 'PXR ';
	fUsesDataFork := TRUE;

	fDialogID := 3000;

	fLSBFirst := TRUE

	END;

{*****************************************************************************}

{$S AWriteFile}

FUNCTION TPixarFormat.CanWrite (doc: TImageDocument): BOOLEAN; OVERRIDE;

	BEGIN
	CanWrite := doc.fMode IN [MonochromeMode,
							  RGBColorMode,
							  MultichannelMode]
	END;

{*****************************************************************************}

{$S APixarFormat}

PROCEDURE TPixarFormat.SetFormatOptions (doc: TImageDocument); OVERRIDE;

	BEGIN
	DoOptionsDialog
	END;

{*****************************************************************************}

{$S APixarFormat}

PROCEDURE TPixarFormat.DecodeRow (dBytes: INTEGER;
								  pBytes: INTEGER;
								  rBytes: LONGINT;
								  blockSize: INTEGER;
								  buffer: Ptr);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		limPtr: Ptr;
		rep: INTEGER;
		reps: INTEGER;
		size: LONGINT;
		code: INTEGER;
		count: INTEGER;
		block: INTEGER;
		alpha: INTEGER;

	BEGIN

	srcPtr := buffer;
	limPtr := Ptr (ORD4 (srcPtr) + rBytes);

		REPEAT

		IF GetFilePosition MOD blockSize = blockSize - 1 THEN
			SkipBytes (1);

		code := GetWord;
		count := BAND (code, $FFF) + 1;

			CASE BSR (code, 12) OF

			0:	SeekTo ((1 + (GetFilePosition - 1) DIV blockSize) * blockSize);

			1:	BEGIN
				size := count * ORD4 (pBytes);
				IF ORD4 (srcPtr) + size > ORD4 (limPtr) THEN
					Failure (errBadPixar - 1, 0);
				GetBytes (size, srcPtr);
				srcPtr := Ptr (ORD4 (srcPtr) + size)
				END;

			2:	FOR block := 1 TO count DO
					BEGIN
					IF dBytes = 2 THEN
						reps := GetWord
					ELSE
						reps := GetByte;
					IF ORD4 (srcPtr) + reps * pBytes > ORD4 (limPtr) THEN
						Failure (errBadPixar - 2, 0);
					GetBytes (pBytes, srcPtr);
					FOR rep := 1 TO reps DO
						BEGIN
						dstPtr := Ptr (ORD4 (srcPtr) + pBytes);
						BlockMove (srcPtr, dstPtr, pBytes);
						srcPtr := dstPtr
						END;
					srcPtr := Ptr (ORD4 (srcPtr) + pBytes)
					END;

			3:	BEGIN
				GetBytes (dBytes, @alpha);
				IF ORD4 (srcPtr) + count * ORD4 (pBytes) > ORD4 (limPtr) THEN
					Failure (errBadPixar - 3, 0);
				FOR block := 1 TO count DO
					BEGIN
					GetBytes (pBytes - dBytes, srcPtr);
					srcPtr := Ptr (ORD4 (srcPtr) + pBytes);
					BlockMove (@alpha, Ptr (ORD4 (srcPtr) - dBytes), dBytes)
					END
				END;

			4:	BEGIN
				GetBytes (dBytes, @alpha);
				FOR block := 1 TO count DO
					BEGIN
					IF dBytes = 2 THEN
						reps := GetWord
					ELSE
						reps := GetByte;
					IF ORD4 (srcPtr) + reps * pBytes > ORD4 (limPtr) THEN
						Failure (errBadPixar - 4, 0);
					GetBytes (pBytes - dBytes, srcPtr);
					srcPtr := Ptr (ORD4 (srcPtr) + pBytes);
					BlockMove (@alpha, Ptr (ORD4 (srcPtr) - dBytes), dBytes);
					FOR rep := 1 TO reps DO
						BEGIN
						BlockMove (Ptr (ORD4 (srcPtr) - pBytes),
								   srcPtr, pBytes);
						srcPtr := Ptr (ORD4 (srcPtr) + pBytes)
						END
					END
				END;

			OTHERWISE
				Failure (errBadPixar - 5, 0)

			END

		UNTIL ORD4 (srcPtr) = ORD4 (limPtr)

	END;

{*****************************************************************************}

{$S APixarFormat}

PROCEDURE Init12BitLUT (var LUT: TwelveBitLUT);

	VAR
		j: INTEGER;

	BEGIN

	FOR j := 0 TO 2047 DO
		LUT [j] := CHR (BSR (j, 3));

	FOR j := 2048 TO 3071 DO
		LUT [j] := CHR (255);

	FOR j := 3072 TO 4095 DO
		LUT [j] := CHR (0)

	END;

{*****************************************************************************}

{$S APixarFormat}

PROCEDURE Map12BitData (rBytes: LONGINT;
						var LUT: TwelveBitLUT;
						buffer: Ptr);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		lo8: INTEGER;
		hi4: INTEGER;
		count: LONGINT;
		counter: LONGINT;

	BEGIN

	srcPtr := buffer;
	dstPtr := buffer;

	count := BSR (rBytes, 1);

	FOR counter := 1 TO count DO
		BEGIN

		lo8 := BAND (srcPtr^, $FF);
		hi4 := BAND (Ptr (ORD4 (srcPtr) + 1)^, $F);

		{$PUSH}
		{$R-}
		dstPtr^ := ORD (LUT [BSL (hi4, 8) + lo8]);
		{$POP}

		srcPtr := Ptr (ORD4 (srcPtr) + 2);
		dstPtr := Ptr (ORD4 (dstPtr) + 1)

		END

	END;

{*****************************************************************************}

{$S APixarFormat}

PROCEDURE TPixarFormat.ReadTile (doc: TImageDocument;
								 rowOffset: INTEGER;
								 colOffset: INTEGER;
								 tileRows: INTEGER;
								 tileCols: INTEGER;
								 storage: INTEGER;
								 blockSize: INTEGER);

	VAR
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		buffer: Handle;
		dBytes: INTEGER;
		pBytes: INTEGER;
		rBytes: LONGINT;
		channel: INTEGER;
		encoded: BOOLEAN;
		LUT: TwelveBitLUT;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (buffer)
		END;

	BEGIN

		CASE storage OF

		0:	BEGIN
			dBytes := 1;
			encoded := TRUE
			END;

		1:	BEGIN
			dBytes := 2;
			encoded := TRUE
			END;

		2:	BEGIN
			dBytes := 1;
			encoded := FALSE
			END;

		3:	BEGIN
			dBytes := 2;
			encoded := FALSE
			END;

		OTHERWISE
			Failure (errBadPixar - 6, 0)

		END;

	IF dBytes = 2 THEN Init12BitLUT (LUT);

	pBytes := dBytes * doc.fChannels;
	rBytes := pBytes * ORD4 (tileCols);

	buffer := NewLargeHandle (rBytes);

	CatchFailures (fi, CleanUp);

	MoveHHi (buffer);
	HLock (buffer);

	FOR row := 0 TO tileRows - 1 DO
		BEGIN

		MoveHands (NOT doc.fReverting);

		UpdateProgress (row, tileRows);

		IF encoded THEN
			DecodeRow (dBytes, pBytes, rBytes, blockSize, buffer^)
		ELSE
			GetBytes (rBytes, buffer^);

		IF dBytes = 2 THEN Map12BitData (rBytes, LUT, buffer^);

		IF row + rowOffset < doc.fRows THEN
			FOR channel := 0 TO doc.fChannels - 1 DO
				BEGIN

				dstPtr := doc.fData [channel] . NeedPtr (row + rowOffset,
														 row + rowOffset,
														 TRUE);

				DoStepCopyBytes (Ptr (ORD4 (buffer^) + channel),
								 Ptr (ORD4 (dstPtr) + colOffset),
								 Min (tileCols, doc.fCols - colOffset),
								 doc.fChannels,
								 1);

				doc.fData [channel] . DoneWithPtr;
				doc.fData [channel] . Flush

				END

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S APixarFormat}

PROCEDURE TPixarFormat.DoRead (doc: TImageDocument;
							   refNum: INTEGER;
							   rsrcExists: BOOLEAN); OVERRIDE;

	VAR
		r: INTEGER;
		c: INTEGER;
		format: INTEGER;
		storage: INTEGER;
		channel: INTEGER;
		tileRows: INTEGER;
		tileCols: INTEGER;
		aVMArray: TVMArray;
		blockSize: INTEGER;
		rowsOfTiles: INTEGER;
		colsOfTiles: INTEGER;

	BEGIN

	fRefNum := refNum;

	MoveHands (NOT doc.fReverting);

	IF GetLong <> $0000E880 THEN Failure (errBadPixar - 7, 0);

	SeekTo (416);

	doc.fRows := GetWord;
	doc.fCols := GetWord;

	IF NOT doc.ValidSize THEN Failure (errBadPixar - 8, 0);

	tileRows := GetWord;
	tileCols := GetWord;

	IF (tileRows < 1) OR (tileCols < 1) THEN Failure (errBadPixar - 9, 0);

	format := GetWord;

	doc.fChannels := ORD (BTST (format, 3)) +
					 ORD (BTST (format, 2)) +
					 ORD (BTST (format, 1)) +
					 ORD (BTST (format, 0));

	IF doc.fChannels = 0 THEN Failure (errBadPixar, 0);

	doc.DefaultMode;

	storage := GetWord;
	blockSize := GetWord;

	FOR channel := 0 TO doc.fChannels - 1 DO
		BEGIN

		aVMArray := NewVMArray (doc.fRows,
								doc.fCols, doc.Interleave (channel));

		doc.fData [channel] := aVMArray

		END;

	rowsOfTiles := (doc.fRows + tileRows - 1) DIV tileRows;
	colsOfTiles := (doc.fCols + tileCols - 1) DIV tileCols;

	FOR r := 0 TO rowsOfTiles - 1 DO
		BEGIN

		StartTask (1 / (rowsOfTiles - r));

		FOR c := 0 TO colsOfTiles - 1 DO
			BEGIN

			StartTask (1 / (colsOfTiles - c));

			SeekTo (512 + 8 * (r * colsOfTiles) + c);
			SeekTo (GetLong);

			ReadTile (doc,
					  r * tileRows,
					  c * tileCols,
					  tileRows,
					  tileCols,
					  storage,
					  blockSize);

			FinishTask

			END;

		FinishTask

		END

	END;

{*****************************************************************************}

{$S APixarFormat}

FUNCTION TPixarFormat.SaveChannels (doc: TImageDocument): INTEGER;

	BEGIN

	IF doc.fMode = RGBColorMode THEN
		SaveChannels := Min (doc.fChannels, 4)
	ELSE
		SaveChannels := 1

	END;

{*****************************************************************************}

{$S APixarFormat}

FUNCTION TPixarFormat.DataForkBytes (doc: TImageDocument): LONGINT; OVERRIDE;

	BEGIN

	DataForkBytes := 1024 + SaveChannels (doc) * ORD4 (doc.fRows) * doc.fCols

	END;

{*****************************************************************************}

{$S APixarFormat}

PROCEDURE TPixarFormat.DoWrite (doc: TImageDocument;
								refNum: INTEGER); OVERRIDE;

	VAR
		extra: INTEGER;
		channels: INTEGER;

	BEGIN

	fRefNum := refNum;

	MoveHands (FALSE);

	PutLong ($0000E880);

	PutWord (1);

	PutZeros (410);

	PutWord (doc.fRows);
	PutWord (doc.fCols);
	PutWord (doc.fRows);
	PutWord (doc.fCols);

	channels := SaveChannels (doc);

		CASE channels OF
		1:	PutWord (8);
		3:	PutWord (14);
		4:	PutWord (15)
		END;

	PutWord (2);
	PutWord (1024);

	PutZeros (82);

	PutLong (1024);
	PutLong (channels * ORD4 (doc.fRows) * doc.fCols);

	PutZeros (504);

	PutInterleavedRows (doc.fData, channels, 0, doc.fRows);

	extra := BAND (GetFilePosition, 1023);

	IF extra <> 0 THEN
		PutZeros (1024 - extra)

	END;

{Photoshop version 1.0.1, file: UTarga.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}
{$I UTarga.a.inc}

{*****************************************************************************}

{$S AInit}

PROCEDURE TTargaFormat.IImageFormat; OVERRIDE;

	BEGIN

	INHERITED IImageFormat;

	fDialogID	   := 2900;
	fRadioClusters := 1;
	fRadio1Item    := 4;
	fRadio1Count   := 3;

	fCanRead	  := TRUE;
	fReadType1	  := 'TPIC';
	fFileType	  := 'TPIC';
	fUsesDataFork := TRUE;

	fLSBFirst := TRUE;

	fDepth := 32

	END;

{*****************************************************************************}

{$S AWriteFile}

FUNCTION TTargaFormat.CanWrite (doc: TImageDocument): BOOLEAN; OVERRIDE;

	BEGIN

	CanWrite := doc.fMode IN [MonochromeMode,
							  IndexedColorMode,
							  RGBColorMode,
							  MultichannelMode]

	END;

{*****************************************************************************}

{$S ATargaFormat}

PROCEDURE TTargaFormat.SetFormatOptions (doc: TImageDocument); OVERRIDE;

	BEGIN

	IF doc.fMode = RGBColorMode THEN
		BEGIN

			CASE fDepth OF
			16: fRadio1 := 0;
			24: fRadio1 := 1;
			32: fRadio1 := 2
			END;

		DoOptionsDialog;

			CASE fRadio1 OF
			0:	fDepth := 16;
			1:	fDepth := 24;
			2:	fDepth := 32
			END

		END

	END;

{*****************************************************************************}

{$S ATargaFormat}

PROCEDURE TTargaFormat.DoRead (doc: TImageDocument;
							   refNum: INTEGER;
							   rsrcExists: BOOLEAN); OVERRIDE;

	VAR
		r: INTEGER;
		g: INTEGER;
		b: INTEGER;
		x: INTEGER;
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		size: LONGINT;
		depth: INTEGER;
		index: INTEGER;
		theRow: INTEGER;
		itCode: INTEGER;
		cmCode: INTEGER;
		buffer1: Handle;
		buffer2: Handle;
		idBytes: INTEGER;
		cmStart: INTEGER;
		cmCount: INTEGER;
		cmEntry: INTEGER;
		channel: INTEGER;
		encoded: BOOLEAN;
		reversed: BOOLEAN;
		rowBytes: LONGINT;
		aVMArray: TVMArray;
		wrapBytes: LONGINT;
		fileCount: LONGINT;
		fileOffset: LONGINT;
		pixelBytes: INTEGER;
		wrapPixels: LONGINT;
		maxRowBytes: LONGINT;
		dstPtrs: ARRAY [0..2] OF Ptr;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (buffer1);
		FreeLargeHandle (buffer2)
		END;

	BEGIN

	fRefNum := refNum;

	MoveHands (NOT doc.fReverting);

	idBytes := GetByte;
	cmCode	:= GetByte;
	itCode	:= GetByte;

	encoded := (itCode >= 9);

	IF encoded THEN
		itCode := itCode - 8;

	IF (itCode < 1) OR (itCode > 3) THEN
		Failure (errUnspTarga, 0);

	IF (cmCode < 0) OR (cmCode > 1) THEN
		Failure (errBadTarga - 1, 0);

	IF cmCode = 1 THEN
		BEGIN
		cmStart := GetWord;
		cmCount := GetWord;
		cmEntry := GetByte
		END
	ELSE
		SkipBytes (5);

	SkipBytes (4);

	doc.fCols := GetWord;
	doc.fRows := GetWord;

	IF NOT doc.ValidSize THEN
		Failure (errBadTarga - 2, 0);

	depth := GetByte;

	reversed := NOT BTST (GetByte, 5);

	reversed := TRUE;	{??? Safer guess ???}

		CASE itCode OF

		1:	BEGIN
			doc.fMode := IndexedColorMode;
			IF (depth <> 8) OR (cmCode <> 1) THEN
				Failure (errBadTarga - 3, 0)
			END;

		2:	BEGIN
			doc.fMode := RGBColorMode;
			doc.fChannels := 3;
			IF (depth <> 16) AND (depth <> 24) AND (depth <> 32) THEN
				Failure (errBadTarga - 4, 0)
			END;

		3:	BEGIN
			doc.fMode := MonochromeMode;
			IF depth <> 8 THEN
				Failure (errBadTarga - 5, 0)
			END

		END;

	SkipBytes (idBytes);

	IF cmCode = 1 THEN
		BEGIN

		IF doc.fMode = IndexedColorMode THEN
			BEGIN

			doc.fIndexedColorTable.R := gNullLUT;
			doc.fIndexedColorTable.G := gNullLUT;
			doc.fIndexedColorTable.B := gNullLUT;

			IF (cmStart < 0) OR (cmCount < 0) THEN
				Failure (errBadTarga - 6, 0);

			FOR index := cmStart TO cmStart + cmCount - 1 DO
				BEGIN

					CASE cmEntry OF

					15, 16:
						BEGIN

						x := GetWord;

						r := BAND ($1F, BSR (x, 10));
						g := BAND ($1F, BSR (x, 5));
						b := BAND ($1F, x);

						r := BSL (r, 3) + BSR (r, 2);
						g := BSL (g, 3) + BSR (g, 2);
						b := BSL (b, 3) + BSR (b, 2)

						END;

					24: BEGIN
						b := GetByte;
						g := GetByte;
						r := GetByte
						END;

					32: BEGIN
						b := GetByte;
						g := GetByte;
						r := GetByte;
						SkipBytes (1)
						END;

					OTHERWISE
						Failure (errBadTarga - 7, 0)

					END;

				IF index < 256 THEN
					BEGIN
					doc.fIndexedColorTable.R [index] := CHR (r);
					doc.fIndexedColorTable.G [index] := CHR (g);
					doc.fIndexedColorTable.B [index] := CHR (b)
					END

				END

			END

		ELSE
			SkipBytes (BSR (cmEntry + 7, 3) * cmCount)

		END;

	buffer1 := NIL;
	buffer2 := NIL;

	CatchFailures (fi, CleanUp);

	FOR channel := 0 TO doc.fChannels - 1 DO
		BEGIN

		aVMArray := NewVMArray (doc.fRows,
								doc.fCols, doc.Interleave (channel));

		doc.fData [channel] := aVMArray

		END;

	pixelBytes := BSR (depth, 3);

	size := ORD4 (pixelBytes) * doc.fCols;

	buffer1 := NewLargeHandle (size + 127 * pixelBytes);

	IF encoded THEN
		BEGIN

		maxRowBytes := size + doc.fCols;

		buffer2 := NewLargeHandle (maxRowBytes);

		fileOffset := GetFilePosition;
		fileCount  := GetFileLength - fileOffset;

		HLock (buffer2)

		END;

	HLock (buffer1);

	wrapBytes  := 0;
	wrapPixels := 0;

	FOR row := 0 TO doc.fRows - 1 DO
		BEGIN

		MoveHands (NOT doc.fReverting);

		UpdateProgress (row, doc.fRows);

		IF encoded THEN
			BEGIN

			SeekTo (fileOffset);

			srcPtr := buffer2^;
			dstPtr := buffer1^;

			maxRowBytes := Min (maxRowBytes, fileCount);

			GetBytes (maxRowBytes, srcPtr);

			IF wrapBytes > 0 THEN
				BEGIN
				BlockMove (Ptr (ORD4 (dstPtr) + size),
						   dstPtr,
						   wrapBytes);
				dstPtr := Ptr (ORD4 (dstPtr) + wrapBytes)
				END;

			IF doc.fCols > wrapPixels THEN
				DecodeTargaRLE (srcPtr,
								dstPtr,
								doc.fCols - wrapPixels,
								pixelBytes);

			rowBytes := ORD4 (srcPtr) - ORD4 (buffer2^);

			IF rowBytes > maxRowBytes THEN
				Failure (errBadTarga - 8, 0);

			wrapBytes  := ORD4 (dstPtr) - ORD4 (buffer1^) - size;
			wrapPixels := wrapBytes DIV pixelBytes;

			fileOffset := fileOffset + rowBytes;
			fileCount  := fileCount  - rowBytes

			END

		ELSE
			GetBytes (size, buffer1^);

		IF reversed THEN
			theRow := doc.fRows - 1 - row
		ELSE
			theRow := row;

		FOR channel := 0 TO doc.fChannels - 1 DO
			dstPtrs [channel] := doc.fData [channel] .
								 NeedPtr (theRow, theRow, TRUE);

			CASE depth OF

			8:	BlockMove (buffer1^, dstPtrs [0], doc.fCols);

			16: BEGIN
				Targa16Red	 (buffer1^, dstPtrs [0], doc.fCols);
				Targa16Green (buffer1^, dstPtrs [1], doc.fCols);
				Targa16Blue  (buffer1^, dstPtrs [2], doc.fCols)
				END;

			OTHERWISE
				FOR channel := 0 TO 2 DO
					DoStepCopyBytes (Ptr (ORD4 (buffer1^) + channel),
									 dstPtrs [2 - channel],
									 doc.fCols,
									 pixelBytes,
									 1)

			END;

		FOR channel := 0 TO doc.fChannels - 1 DO
			doc.fData [channel] . DoneWithPtr

		END;

	IF wrapPixels <> 0 THEN
		Failure (errBadTarga - 9, 0);

	UpdateProgress (1, 1);

	FOR channel := 0 TO doc.fChannels - 1 DO
		doc.fData [channel] . Flush;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ATargaFormat}

FUNCTION TTargaFormat.DataForkBytes (doc: TImageDocument): LONGINT; OVERRIDE;

	VAR
		pixelBytes: INTEGER;

	BEGIN

	IF doc.fMode = RGBColorMode THEN
		pixelBytes := fDepth DIV 8
	ELSE
		pixelBytes := 1;

	DataForkBytes := doc.fRows * ORD4 (doc.fCols) * pixelBytes

	END;

{*****************************************************************************}

{$S ATargaFormat}

PROCEDURE TTargaFormat.DoWrite (doc: TImageDocument;
								refNum: INTEGER); OVERRIDE;

	VAR
		r: Rect;
		srcPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		index: INTEGER;
		ddepth: INTEGER;
		buffer1: Handle;
		buffer2: Handle;
		rowBytes: LONGINT;
		pixelBytes: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (buffer1);
		FreeLargeHandle (buffer2)
		END;

	BEGIN

	fRefNum := refNum;

	MoveHands (FALSE);

	PutByte (0);

	IF doc.fMode = IndexedColorMode THEN
		PutByte (1)
	ELSE
		PutByte (0);

		CASE doc.fMode OF

		IndexedColorMode:
			PutByte (1);

		RGBColorMode:
			PutByte (2);

		OTHERWISE
			PutByte (3)

		END;

	IF doc.fMode = IndexedColorMode THEN
		BEGIN
		PutWord (0);
		PutWord (256);
		PutByte (24)
		END
	ELSE
		PutZeros (5);

	PutWord (0);
	PutWord (0);
	PutWord (doc.fCols);
	PutWord (doc.fRows);

	IF doc.fMode = RGBColorMode THEN
		BEGIN
		PutByte (fDepth);
			CASE fDepth OF
			16: PutByte (1);
			24: PutByte (0);
			32: PutByte (8)
			END
		END
	ELSE
		BEGIN
		PutByte (8);
		PutByte (0)
		END;

	IF doc.fMode = IndexedColorMode THEN
		FOR index := 0 TO 255 DO
			BEGIN
			PutByte (ORD (doc.fIndexedColorTable.B [index]));
			PutByte (ORD (doc.fIndexedColorTable.G [index]));
			PutByte (ORD (doc.fIndexedColorTable.R [index]))
			END;

	IF doc.fMode = RGBColorMode THEN
		BEGIN

		IF fDepth = 16 THEN
			ddepth := 16
		ELSE
			ddepth := 32;

		gTables.CompTables (doc, kRGBChannels, FALSE, FALSE,
							ddepth, ddepth, FALSE, FALSE, 1);

		buffer1 := NIL;
		buffer2 := NIL;

		CatchFailures (fi, CleanUp);

		doc.GetBoundsRect (r);
		r.top := r.bottom - 1;

		pixelBytes := BSR (fDepth, 3);

		rowBytes := doc.fCols * ORD4 (pixelBytes);

		buffer1 := NewLargeHandle (gTables.BufferSize (r));
		buffer2 := NewLargeHandle (rowBytes);

		HLock (buffer1);
		HLock (buffer2);

		DoSetBytes (buffer2^, rowBytes, 0);

		FOR row := doc.fRows - 1 DOWNTO 0 DO
			BEGIN

			UpdateProgress (row, doc.fRows);

			gTables.DitherRect (doc, kRGBChannels, 1, r, buffer1^, TRUE);

			IF fDepth = 16 THEN
				BEGIN
				DoStepCopyBytes (Ptr (ORD4 (buffer1^) + 1),
								 buffer2^,
								 doc.fCols, 2, 2);
				DoStepCopyBytes (buffer1^,
								 Ptr (ORD4 (buffer2^) + 1),
								 doc.fCols, 2, 2)
				END
			ELSE
				BEGIN
				DoStepCopyBytes (Ptr (ORD4 (buffer1^) + 3),
								 buffer2^,
								 doc.fCols, 4, pixelBytes);
				DoStepCopyBytes (Ptr (ORD4 (buffer1^) + 2),
								 Ptr (ORD4 (buffer2^) + 1),
								 doc.fCols, 4, pixelBytes);
				DoStepCopyBytes (Ptr (ORD4 (buffer1^) + 1),
								 Ptr (ORD4 (buffer2^) + 2),
								 doc.fCols, 4, pixelBytes)
				END;

			PutBytes (rowBytes, buffer2^);

			OffsetRect (r, 0, -1)

			END;

		Success (fi);

		CleanUp (0, 0)

		END

	ELSE
		BEGIN

		FOR row := doc.fRows - 1 DOWNTO 0 DO
			BEGIN

			UpdateProgress (doc.fRows - 1 - row, doc.fRows);

			srcPtr := doc.fData [0] . NeedPtr (row, row, FALSE);

			PutBytes (doc.fCols, srcPtr);

			doc.fData [0] . DoneWithPtr

			END;

		doc.fData [0] . Flush

		END;

	UpdateProgress (1, 1);

	PutLong (0);
	PutLong (0);
	PutByte (ORD ('T'));
	PutByte (ORD ('R'));
	PutByte (ORD ('U'));
	PutByte (ORD ('E'));
	PutByte (ORD ('V'));
	PutByte (ORD ('I'));
	PutByte (ORD ('S'));
	PutByte (ORD ('I'));
	PutByte (ORD ('O'));
	PutByte (ORD ('N'));
	PutByte (ORD ('-'));
	PutByte (ORD ('X'));
	PutByte (ORD ('F'));
	PutByte (ORD ('I'));
	PutByte (ORD ('L'));
	PutByte (ORD ('E'));
	PutByte (ORD ('.'));
	PutByte (0)

	END;

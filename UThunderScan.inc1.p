{Photoshop version 1.0.1, file: UThunderScan.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}
{$I UResize.p.inc}

{*****************************************************************************}

{$S AInit}

PROCEDURE TThunderScanFormat.IImageFormat; OVERRIDE;

	BEGIN

	INHERITED IImageFormat;

	fCanRead	  := TRUE;
	fReadType1	  := 'SCAN';
	fFileType	  := 'SCAN';
	fFileCreator  := 'SCAN';
	fUsesDataFork := TRUE;

	fDialogID	   := 2300;
	fRadioClusters := 1;
	fRadio1Item    := 4;
	fRadio1Count   := 3

	END;

{*****************************************************************************}

{$S AWriteFile}

FUNCTION TThunderScanFormat.CanWrite
		(doc: TImageDocument): BOOLEAN; OVERRIDE;

	BEGIN

	CanWrite := doc.fMode IN [HalftoneMode,
							  MonochromeMode,
							  MultichannelMode]

	END;

{*****************************************************************************}

{$S AThunderScan}

PROCEDURE TThunderScanFormat.SetFormatOptions (doc: TImageDocument); OVERRIDE;

	BEGIN

	IF doc.fMode = HalftoneMode THEN
		fDepth := 1
	ELSE
		fDepth := 5;

		CASE fDepth OF
		1:	fRadio1 := 0;
		4:	fRadio1 := 1;
		5:	fRadio1 := 2
		END;

	DoOptionsDialog;

		CASE fRadio1 OF
		0:	fDepth := 1;
		1:	fDepth := 4;
		2:	fDepth := 5
		END

	END;

{*****************************************************************************}

{$S AThunderScan}

PROCEDURE TThunderScanFormat.ReadSCANLine (doc: TImageDocument;
										   row: INTEGER);

	VAR
		col: INTEGER;
		bit: INTEGER;
		gray: INTEGER;
		inPtr: LONGINT;
		bitPtr: LONGINT;
		outPtr: LONGINT;
		rowBytes: INTEGER;

	BEGIN

	rowBytes := BSR (doc.fCols + 1, 1) + BSR (doc.fCols + 7, 3);

	GetBytes (rowBytes, gBuffer);

	inPtr  := ORD4 (gBuffer);
	bitPtr := ORD4 (gBuffer) + BSR (doc.fCols + 1, 1);

	outPtr := ORD4 (doc.fData [0] . NeedPtr (row, row, TRUE));

	FOR col := 0 TO doc.fCols - 1 DO
		BEGIN
		IF ODD (col) THEN
			BEGIN
			gray := BSL (BAND (Ptr (inPtr)^, $F), 1);
			inPtr := inPtr + 1
			END
		ELSE
			gray := BSR (BAND (Ptr (inPtr)^, $F0), 3);
		bit := 7 - BAND (col, 7);
		gray := gray + ORD (BTST (Ptr (bitPtr)^, bit));
		IF bit = 0 THEN bitPtr := bitPtr + 1;
		Ptr (outPtr)^ := 255 - (BSL (gray, 3) + BSR (gray, 2));
		outPtr := outPtr + 1
		END;

	doc.fData [0] . DoneWithPtr

	END;

{*****************************************************************************}

{$S AThunderScan}

PROCEDURE TThunderScanFormat.DoRead (doc: TImageDocument;
									 refNum: INTEGER;
									 rsrcExists: BOOLEAN); OVERRIDE;

	TYPE
		PBoolean = ^BOOLEAN;
		HBoolean = ^PBoolean;

	VAR
		row: INTEGER;
		fi: FailInfo;
		info: HBoolean;
		depth: INTEGER;
		offset: LONGINT;
		adjust: BOOLEAN;
		rowBytes: INTEGER;
		realRows: INTEGER;
		aVMArray: TVMArray;
		resolution: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aVMArray.Free
		END;

	BEGIN

	fRefNum := refNum;

	MoveHands (NOT doc.fReverting);

	IF GetWord <> 0 THEN Failure (errBadThunderScan, 0);
	IF GetLong <> 0 THEN Failure (errBadThunderScan, 0);

	realRows  := GetWord;
	doc.fCols := GetWord;

	IF (realRows  <= 0) OR (realRows  > kMaxCoord) OR
	   (doc.fCols <= 0) OR (doc.fCols > kMaxCoord) THEN
		Failure (errBadThunderScan, 0);

	depth	   := GetWord;
	resolution := GetWord;

	IF (resolution <= 200) OR (depth = 1) THEN
		doc.fRows := realRows
	ELSE
		doc.fRows := (ORD4 (realRows) * 200 + 199) DIV resolution;

	SkipBytes (6);
	offset := GetLong;
	SkipBytes (488);

	StartTask (1);

	IF depth = 5 THEN
		BEGIN

		aVMArray := NewVMArray (doc.fRows, doc.fCols, 1);
		doc.fData [0] := aVMArray;

		rowBytes := BSR (doc.fCols + 1, 1) + BSR (doc.fCols + 7, 3);

		IF (offset - 512) MOD rowBytes <> 0 THEN
			Failure (errBadThunderScan, 0);

		IF (offset - 512) DIV rowBytes < doc.fRows THEN
			Failure (errBadThunderScan, 0);

		FOR row := 0 TO doc.fRows - 1 DO
			BEGIN
			UpdateProgress (row, doc.fRows);
			ReadSCANLine (doc, row)
			END;

		UpdateProgress (1, 1)

		END

	ELSE IF depth = 1 THEN

		BEGIN

		IF offset <> 512 THEN Failure (errBadThunderScan, 0);

		doc.fDepth := 1;

		aVMArray := NewVMArray (doc.fRows,
								BSL (BSR (doc.fCols + 15, 4), 1),
								1);

		doc.fData [0] := aVMArray;

		GetRawRows (aVMArray, aVMArray.fLogicalSize,
					0, doc.fRows, NOT doc.fReverting)

		END

	ELSE
		Failure (errBadThunderScan, 0);

	FinishTask;

	doc.DefaultMode;

	IF doc.fRows <> realRows THEN
		BEGIN

		IF doc.fRevertInfo = NIL THEN
			BEGIN

			adjust := AskAdjustAspect;

			info := HBoolean (NewPermHandle (SIZEOF (BOOLEAN)));
			FailMemError;

			info^^ := adjust;

			doc.fRevertInfo := Handle (info)

			END

		ELSE
			adjust := HBoolean (doc.fRevertInfo)^^;

		IF adjust THEN
			BEGIN

			aVMArray := NewVMArray (realRows, doc.fCols, 1);

			CatchFailures (fi, CleanUp);

			ResizeArray (doc.fData [0], aVMArray, FALSE, NOT doc.fReverting);

			Success (fi);

			doc.fData [0] . Free;

			doc.fData [0] := aVMArray;

			doc.fRows := realRows

			END

		END

	END;

{*****************************************************************************}

{$S AThunderScan}

FUNCTION TThunderScanFormat.DataForkBytes
		(doc: TImageDocument): LONGINT; OVERRIDE;

	VAR
		bytes: LONGINT;

	BEGIN

	bytes := 512 + doc.fRows * BSL (BSR (doc.fCols + 15, 4), 1);

	IF (fDepth <> 1) AND (doc.fMode <> HalftoneMode) THEN
		bytes := bytes + ORD4 (doc.fRows + 2) *
				 (BSR (doc.fCols + 1, 1) + BSR (doc.fCols + 7, 3));

	DataForkBytes := bytes

	END;

{*****************************************************************************}

{$S AThunderScan}

PROCEDURE TThunderScanFormat.DoWrite
		(doc: TImageDocument; refNum: INTEGER); OVERRIDE;

	VAR
		r: Rect;
		srcPtr: Ptr;
		fi: FailInfo;
		dst1Ptr: Ptr;
		dst4Ptr: Ptr;
		bit: INTEGER;
		row: INTEGER;
		col: INTEGER;
		bounds: Rect;
		hiBit: BOOLEAN;
		buffer: Handle;
		outDepth: INTEGER;
		rowBytes: INTEGER;
		rowBytes1: INTEGER;
		rowBytes4: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (buffer);
		doc.fData [0] . Flush
		END;

	BEGIN

	fRefNum := refNum;

	MoveHands (FALSE);

	IF fDepth = 5 THEN
		outDepth := 8
	ELSE
		outDepth := fDepth;

	gTables.CompTables (doc, 0, TRUE, FALSE,
						outDepth, fDepth, FALSE, FALSE, 1);

	SetRect (bounds, 0, 0, doc.fCols, doc.fRows);

	PutWord (0);
	PutBytes (8, @bounds);

	IF gTables.fDepth = 1 THEN
		PutWord (1)
	ELSE
		PutWord (5);

	PutWord (100);
	PutWord (0);

	PutLong (bounds.bottom * BSL (BSR (bounds.right + 15, 4), 1));

	IF gTables.fDepth = 1 THEN
		PutLong (512)

	ELSE
		BEGIN

		rowBytes4 := BSR (bounds.right + 1, 1);
		rowBytes1 := BSR (bounds.right + 7, 3);

		rowBytes := rowBytes4 + rowBytes1;

		PutLong (512 + ORD4 (bounds.bottom + 2) * rowBytes)

		END;

	PutWord (0);
	PutWord (50);
	PutZeros (226);
	PutWord (-1);

	PutBytes (256, @gNullLUT);

	IF gTables.fDepth <> 1 THEN
		BEGIN

		rowBytes := gTables.CompRowBytes (bounds.right);

		r := bounds;
		r.top	 := 0;
		r.bottom := 1;

		buffer := NewLargeHandle (Max (gTables.BufferSize (r),
									   rowBytes + rowBytes4 + rowBytes1));

		CatchFailures (fi, CleanUp);

		MoveHHi (buffer);
		HLock (buffer);

		StartTask (0.75);

		FOR row := 0 TO bounds.bottom - 1 DO
			BEGIN

			UpdateProgress (row, bounds.bottom);

			r.top	 := row;
			r.bottom := row + 1;

			gTables.DitherRect (doc, 0, 1, r, buffer^, FALSE);

			srcPtr	:= buffer^;
			dst4Ptr := Ptr (ORD4 (buffer^) + rowBytes);
			dst1Ptr := Ptr (ORD4 (buffer^) + rowBytes + rowBytes4);

			DoSetBytes (dst1Ptr, rowBytes1, 0);

			IF fDepth = 4 THEN
				BEGIN

				BlockMove (srcPtr, dst4Ptr, rowBytes4);

				FOR col := 0 TO bounds.right - 1 DO
					BEGIN

					IF ODD (col) THEN
						BEGIN
						hiBit := BAND (srcPtr^, $8) <> 0;
						srcPtr := Ptr (ORD4 (srcPtr) + 1)
						END
					ELSE
						hiBit := BAND (srcPtr^, $80) <> 0;

					bit := 7 - BAND (col, 7);

					IF hiBit THEN
						dst1Ptr^ := dst1Ptr^ + BSL (1, bit);

					IF bit = 0 THEN
						dst1Ptr := Ptr (ORD4 (dst1Ptr) + 1)

					END;

				END

			ELSE
				FOR col := 0 TO bounds.right - 1 DO
					BEGIN

					IF ODD (col) THEN
						BEGIN
						dst4Ptr^ := dst4Ptr^ + BSR (srcPtr^, 1);
						dst4Ptr := Ptr (ORD4 (dst4Ptr) + 1)
						END
					ELSE
						dst4Ptr^ := BAND (BSL (srcPtr^, 3), $F0);

					bit := 7 - BAND (col, 7);

					dst1Ptr^ := dst1Ptr^ + BSL (BAND (srcPtr^, 1), bit);

					IF bit = 0 THEN
						dst1Ptr := Ptr (ORD4 (dst1Ptr) + 1);

					srcPtr := Ptr (ORD4 (srcPtr) + 1)

					END;

			PutBytes (rowBytes4 + rowBytes1, Ptr (ORD4 (buffer^) + rowBytes));

			END;

		FinishTask;

		Success (fi);

		CleanUp (0, 0);

		PutZeros (BSL (rowBytes4 + rowBytes1, 1))

		END;

	IF gTables.fDepth <> 1 THEN
		gTables.CompTables (doc, 0, TRUE, FALSE, 1, 1, TRUE, TRUE, 1);

	rowBytes := gTables.CompRowBytes (bounds.right);

	r := bounds;

	FOR row := 0 TO bounds.bottom - 1 DO
		BEGIN

		UpdateProgress (row, bounds.bottom);

		r.top	 := row;
		r.bottom := row + 1;

		gTables.DitherRect (doc, 0, 1, r, gBuffer, TRUE);

		PutBytes (rowBytes, gBuffer)

		END;

	UpdateProgress (1, 1)

	END;

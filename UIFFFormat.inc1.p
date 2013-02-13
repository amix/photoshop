{Photoshop version 1.0.1, file: UIFFFormat.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}
{$I UIFFFormat.a.inc}
{$I UResize.p.inc}

{*****************************************************************************}

{$S AInit}

PROCEDURE TIFFFormat.IImageFormat; OVERRIDE;

	BEGIN

	INHERITED IImageFormat;

	fCanRead	  := TRUE;
	fReadType1	  := 'ILBM';
	fReadType2	  := 'IFF ';
	fFileType	  := 'ILBM';
	fUsesDataFork := TRUE;

	fDialogID	   := 2800;
	fRadioClusters := 1;
	fRadio1Item    := 4;
	fRadio1Count   := 8

	END;

{*****************************************************************************}

{$S AWriteFile}

FUNCTION TIFFFormat.CanWrite (doc: TImageDocument): BOOLEAN; OVERRIDE;

	BEGIN
	CanWrite := (doc.fMode = HalftoneMode) OR
				(doc.fMode = MonochromeMode) OR
				(doc.fMode = IndexedColorMode) OR
				(doc.fMode = MultichannelMode)
	END;

{*****************************************************************************}

{$S AIFFFormat}

PROCEDURE TIFFFormat.SetFormatOptions (doc: TImageDocument); OVERRIDE;

	BEGIN

	gTables.CompTables (doc, 0, FALSE, FALSE, 8, 8, FALSE, TRUE, 1);

	fDepth := gTables.fResolution;

	fRadio1 := fDepth - 1;

	DoOptionsDialog;

	fDepth := fRadio1 + 1

	END;

{*****************************************************************************}

{$S AIFFFormat}

FUNCTION TIFFFormat.ReadCMap (VAR cMap: TRGBLookUpTable): INTEGER;

	VAR
		size: LONGINT;
		gray: INTEGER;
		colors: INTEGER;
		zero4Bits: BOOLEAN;

	BEGIN

	size := GetLong;

	IF (size < 3) OR (size > 768) OR (size MOD 3 <> 0) THEN
		Failure (errBadIFF, 0);

	DoSetBytes (@cMap, SIZEOF (TRGBLookUpTable), 0);

	colors := size DIV 3;

	FOR gray := 0 TO colors - 1 DO
		BEGIN
		cMap.R [gray] := CHR (GetByte);
		cMap.G [gray] := CHR (GetByte);
		cMap.B [gray] := CHR (GetByte)
		END;

	IF ODD (size) THEN SkipBytes (1);

	zero4Bits := TRUE;
	FOR gray := 0 TO colors - 1 DO
		zero4Bits := zero4Bits AND (BAND (ORD (cMap.R [gray]), $F) = 0)
							   AND (BAND (ORD (cMap.G [gray]), $F) = 0)
							   AND (BAND (ORD (cMap.B [gray]), $F) = 0);

	IF zero4Bits THEN
		FOR gray := 0 TO colors - 1 DO
			BEGIN
			cMap.R [gray] := CHR (BSR (ORD (cMap.R [gray]), 4) +
									   ORD (cMap.R [gray]));
			cMap.G [gray] := CHR (BSR (ORD (cMap.G [gray]), 4) +
									   ORD (cMap.G [gray]));
			cMap.B [gray] := CHR (BSR (ORD (cMap.B [gray]), 4) +
									   ORD (cMap.B [gray]))
			END;

	ReadCMap := colors

	END;

{*****************************************************************************}

{$S AIFFFormat}

PROCEDURE TIFFFormat.TransCMap (doc: TImageDocument;
								VAR cMap: TRGBLookUpTable;
								nPlanes: INTEGER;
								depth: INTEGER;
								planePick: INTEGER;
								planeOnOff: INTEGER;
								planeMask: INTEGER);

	VAR
		gray: INTEGER;
		color: INTEGER;
		inBit: INTEGER;
		outBit: INTEGER;

	BEGIN

	DoSetBytes (@doc.fIndexedColorTable, SIZEOF (TRGBLookUpTable), 0);

	FOR gray := 0 TO BSL (1, nPlanes) - 1 DO
		BEGIN

		inBit := 0;
		color := 0;

		FOR outBit := 0 TO depth - 1 DO

			IF BTST (planePick, outBit) THEN
				BEGIN
				color := color + BSL (ORD (BTST (gray, inBit)), outBit);
				inBit := inBit + 1
				END

			ELSE
				color := color + BSL (ORD (BTST (planeOnOff, outBit)), outBit);

		color := BAND (color, planeMask);

		doc.fIndexedColorTable.R [gray] := cMap.R [color];
		doc.fIndexedColorTable.G [gray] := cMap.G [color];
		doc.fIndexedColorTable.B [gray] := cMap.B [color]

		END

	END;

{*****************************************************************************}

{$S AIFFFormat}

PROCEDURE TIFFFormat.ReadBody (doc: TImageDocument;
							   nPlanes: INTEGER;
							   masked: BOOLEAN;
							   compressed: BOOLEAN);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		row: INTEGER;
		plane: INTEGER;
		sPlanes: INTEGER;
		rowBytes: INTEGER;
		dataUsed: LONGINT;
		dataSize: LONGINT;
		dataStart: LONGINT;
		packedBytes: INTEGER;

	BEGIN

	dataUsed := 0;
	dataSize := GetLong;
	dataStart := GetFilePosition;

	sPlanes := nPlanes + ORD (masked);

	rowBytes := BSL (BSR (doc.fCols + 15, 4), 1);

	packedBytes := rowBytes + 1 + BSR (rowBytes, 7);

	IF GetPtrSize (gBuffer) < sPlanes * ORD4 (rowBytes + packedBytes) THEN
		Failure (errBadIFF, 0);

	doc.fData [0] . SetBytes (0);

	FOR row := 0 TO doc.fRows - 1 DO
		BEGIN

		UpdateProgress (row, doc.fRows);

		IF compressed THEN
			BEGIN

			SeekTo (dataStart + dataUsed);

			srcPtr := Ptr (ORD4 (gBuffer) + rowBytes * sPlanes);
			dstPtr := gBuffer;

			GetBytes (Min (packedBytes * sPlanes,
						   dataSize - dataUsed), srcPtr);

			UnpackBits (srcPtr, dstPtr, rowBytes * sPlanes);

			dataUsed := dataUsed + ORD4 (srcPtr) - ORD4 (dstPtr)

			END

		ELSE
			BEGIN

			GetBytes (rowBytes * sPlanes, gBuffer);

			dataUsed := dataUsed + rowBytes * sPlanes

			END;

		IF dataUsed > dataSize THEN Failure (errBadIFF, 0);

		dstPtr := doc.fData [0] . NeedPtr (row, row, TRUE);

		FOR plane := 0 TO nPlanes - 1 DO
			StuffPlane (Ptr (ORD4 (gBuffer) + plane * rowBytes),
						dstPtr,
						doc.fCols,
						plane);

		doc.fData [0] . DoneWithPtr

		END;

	UpdateProgress (1, 1)

	END;

{*****************************************************************************}

{$S AIFFFormat}

PROCEDURE DeHAM (doc: TImageDocument);

	VAR
		r: CHAR;
		g: CHAR;
		b: CHAR;
		rPtr: Ptr;
		gPtr: Ptr;
		bPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		col: INTEGER;
		gray: INTEGER;
		rArray: TVMArray;
		gArray: TVMArray;
		bArray: TVMArray;
		table: TRGBLookUpTable;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (rArray);
		FreeObject (gArray);
		FreeObject (bArray)
		END;

	BEGIN

	rArray := NIL;
	gArray := NIL;
	bArray := NIL;

	CatchFailures (fi, CleanUp);

	rArray := doc.fData [0] . CopyArray (3);

	gArray := NewVMArray (doc.fRows, doc.fCols, 2);
	bArray := NewVMArray (doc.fRows, doc.fCols, 1);

	table := doc.fIndexedColorTable;

	FOR row := 0 TO doc.fRows - 1 DO
		BEGIN

		MoveHands (NOT doc.fReverting);

		UpdateProgress (row, doc.fRows);

		r := table.R [0];
		g := table.G [0];
		b := table.B [0];

		rPtr := rArray.NeedPtr (row, row, TRUE);
		gPtr := gArray.NeedPtr (row, row, TRUE);
		bPtr := bArray.NeedPtr (row, row, TRUE);

		FOR col := 1 TO doc.fCols DO
			BEGIN

			gray := BAND (rPtr^, $F);

				CASE BSR (rPtr^, 4) OF

				0:	BEGIN
					r := table.R [gray];
					g := table.G [gray];
					b := table.B [gray]
					END;

				1:	b := CHR (gray + BSL (gray, 4));

				2:	r := CHR (gray + BSL (gray, 4));

				3:	g := CHR (gray + BSL (gray, 4))

				END;

			{$PUSH}
			{$R-}

			rPtr^ := ORD (r);
			rPtr := Ptr (ORD4 (rPtr) + 1);

			gPtr^ := ORD (g);
			gPtr := Ptr (ORD4 (gPtr) + 1);

			bPtr^ := ORD (b);
			bPtr := Ptr (ORD4 (bPtr) + 1)

			{$POP}

			END;

		rArray.DoneWithPtr;
		gArray.DoneWithPtr;
		bArray.DoneWithPtr;

		END;

	UpdateProgress (1, 1);

	rArray.Flush;
	gArray.Flush;
	bArray.Flush;

	Success (fi);

	doc.fData [0] . Free;

	doc.fData [0] := rArray;
	doc.fData [1] := gArray;
	doc.fData [2] := bArray;

	doc.fChannels := 3;

	doc.fMode := RGBColorMode

	END;

{*****************************************************************************}

{$S AIFFFormat}

PROCEDURE TIFFFormat.DoRead (doc: TImageDocument;
							 refNum: INTEGER;
							 rsrcExists: BOOLEAN); OVERRIDE;

	TYPE
		PBoolean = ^BOOLEAN;
		HBoolean = ^PBoolean;

	VAR
		fi: FailInfo;
		code: OSType;
		info: HBoolean;
		depth: INTEGER;
		colors: INTEGER;
		adjust: BOOLEAN;
		hamMode: BOOLEAN;
		nPlanes: INTEGER;
		xAspect: INTEGER;
		yAspect: INTEGER;
		newRows: LONGINT;
		newCols: LONGINT;
		channel: INTEGER;
		compCode: INTEGER;
		maskCode: INTEGER;
		haveBMHD: BOOLEAN;
		aVMArray: TVMArray;
		planePick: INTEGER;
		planeMask: INTEGER;
		planeOnOff: INTEGER;
		cMap: TRGBLookUpTable;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aVMArray.Free
		END;

	BEGIN

	fRefNum := refNum;

	MoveHands (NOT doc.fReverting);

		REPEAT

		IF GetFilePosition + 4 > GetFileLength THEN
			Failure (errBadIFF, 0);

		GetBytes (4, @code);

		IF code = 'CAT ' THEN
			SkipBytes (8)

		ELSE IF code = 'FORM' THEN
			BEGIN
			SkipBytes (4);
			GetBytes (4, @code);
			IF code = 'ILBM' THEN LEAVE
			END

		ELSE IF GetFilePosition = 4 THEN
			Failure (errBadIFF, 0)

		ELSE
			SkipBytes (BSL (BSR (GetLong + 1, 1), 1))

		UNTIL FALSE;

	colors := 0;
	haveBMHD := FALSE;

		REPEAT

		GetBytes (4, @code);

		IF code = 'BMHD' THEN
			BEGIN

			IF GetLong <> 20 THEN Failure (errBadIFF, 0);

			doc.fCols := GetWord;
			doc.fRows := GetWord;

			IF NOT doc.ValidSize THEN Failure (errBadIFF, 0);

			SkipBytes (4);

			nPlanes := GetByte;
			maskCode := GetByte;
			compCode := GetByte;

			IF (nPlanes <= 0) OR (nPlanes > 8) OR
			   (maskCode < 0) OR (maskCode > 3) OR
			   (compCode < 0) OR (compCode > 1) THEN
				Failure (errBadIFF, 0);

			SkipBytes (3);

			xAspect := GetByte;
			yAspect := GetByte;

			IF (xAspect = 0) OR (yAspect = 0) THEN
				BEGIN
				xAspect := 1;
				yAspect := 1
				END;

			{ Special cases: Fix aspect ratios for common errors }

			IF (doc.fRows = 400) AND (doc.fCols = 320) AND
				  (xAspect = 10) AND (yAspect = 11) THEN
				xAspect := 20;

			IF ((doc.fRows = 400) AND (doc.fCols = 640) OR
				(doc.fRows = 200) AND (doc.fCols = 320)) AND
				   (xAspect = 20) AND (yAspect = 11) THEN
				xAspect := 10;

			SkipBytes (4);

			depth := nPlanes;
			planePick := -1;
			planeOnOff := 0;
			planeMask := -1;

			haveBMHD := TRUE

			END

		ELSE IF code = 'CMAP' THEN
			colors := ReadCMap (cMap)

		ELSE IF code = 'DEST' THEN
			BEGIN

			IF GetLong <> 8 THEN Failure (errBadIFF, 0);

			depth := GetByte;

			IF (depth < 1) OR (depth > 8) THEN Failure (errBadIFF, 0);

			SkipBytes (1);

			planePick := GetWord;
			planeOnOff := GetWord;
			planeMask := GetWord

			END

		ELSE IF code <> 'BODY' THEN
			SkipBytes (BSL (BSR (GetLong + 1, 1), 1))

		UNTIL code = 'BODY';

	IF NOT haveBMHD OR (colors = 0) THEN
		Failure (errBadIFF, 0);

	hamMode := (colors = 16) AND (depth = 6);

	aVMArray := NewVMArray (doc.fRows, doc.fCols, 1);

	doc.fData [0] := aVMArray;

	TransCMap (doc, cMap, nPlanes, depth, planePick, planeOnOff, planeMask);

	StartTask (1);

	IF hamMode THEN
		StartTask (0.6);

	ReadBody (doc, nPlanes, maskCode = 1, compCode = 1);

	doc.fMode := IndexedColorMode;

	IF hamMode THEN
		BEGIN
		FinishTask;
		DeHAM (doc)
		END;

	FinishTask;

	IF xAspect <> yAspect THEN
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

			newRows := doc.fRows;
			newCols := doc.fCols;

			IF xAspect > yAspect THEN
				newCols := (newCols * xAspect + BSR (yAspect, 1)) DIV yAspect
			ELSE
				newRows := (newRows * yAspect + BSR (xAspect, 1)) DIV xAspect;

			IF (newRows > kMaxCoord) OR (newCols > kMaxCoord) THEN
				Failure (errBadIFF, 0);

			FOR channel := 0 TO doc.fChannels - 1 DO
				BEGIN

				aVMArray := NewVMArray (newRows,
										newCols, doc.Interleave (channel));

				CatchFailures (fi, CleanUp);

				ResizeArray (doc.fData [channel],
							 aVMArray,
							 doc.fMode = IndexedColorMode,
							 NOT doc.fReverting);

				Success (fi);

				doc.fData [channel] . Free;
				doc.fData [channel] := aVMArray

				END;

			doc.fRows := newRows;
			doc.fCols := newCols

			END

		END;

	TestForMonochrome (doc);

	IF nPlanes = 1 THEN
		TestForHalftone (doc)

	END;

{*****************************************************************************}

{$S AIFFFormat}

PROCEDURE TIFFFormat.WriteBody (doc: TImageDocument; bounds: Rect);

	VAR
		r: Rect;
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		size: LONGINT;
		plane: INTEGER;
		buffer: Handle;
		outBytes: INTEGER;
		rowBytes: INTEGER;
		startPosition: LONGINT;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (buffer)
		END;

	BEGIN

	startPosition := GetFilePosition;

	PutLong (0);

	outBytes := BSL (BSR (bounds.right + 15, 4), 1);
	rowBytes := BSL (BSR (bounds.right +  1, 1), 1);

	buffer := NewLargeHandle (rowBytes +
							  ORD4 (outBytes) * 2 + 1 + BSR (outBytes, 7));

	CatchFailures (fi, CleanUp);

	MoveHHi (buffer);
	HLock (buffer);

	r := bounds;

	FOR row := 0 TO bounds.bottom - 1 DO
		BEGIN

		UpdateProgress (row, bounds.bottom);

		r.top	 := row;
		r.bottom := row + 1;

		gTables.DitherRect (doc, 0, 1, r, buffer^, TRUE);

		FOR plane := 0 TO fDepth - 1 DO
			BEGIN

			srcPtr := buffer^;
			dstPtr := Ptr (ORD4 (buffer^) + rowBytes);

			DoSetBytes (dstPtr, outBytes, 0);

			ExtractPlane (srcPtr, dstPtr, bounds.right, plane);

			srcPtr := Ptr (ORD4 (buffer^) + rowBytes);
			dstPtr := Ptr (ORD4 (srcPtr) + outBytes);

			MyPackBits (srcPtr, dstPtr, outBytes);

			PutBytes (ORD4 (dstPtr) - ORD4 (srcPtr), srcPtr)

			END

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0);

	size := GetFilePosition - startPosition - 4;

	IF ODD (size) THEN PutByte (0);

	SeekTo (startPosition);

	PutLong (size)

	END;

{*****************************************************************************}

{$S AIFFFormat}

PROCEDURE TIFFFormat.DoWrite (doc: TImageDocument; refNum: INTEGER); OVERRIDE;

	VAR
		bounds: Rect;
		code: OSType;
		gray: INTEGER;
		color: RGBColor;

	BEGIN

	fRefNum := refNum;

	MoveHands (FALSE);

	gTables.CompTables (doc, 0, FALSE, FALSE, 8, fDepth, FALSE, FALSE, 1);

	SetRect (bounds, 0, 0, doc.fCols, doc.fRows);

	code := 'FORM';
	PutBytes (4, @code);
	PutLong (0);

	code := 'ILBM';
	PutBytes (4, @code);

	code := 'BMHD';
	PutBytes (4, @code);
	PutLong (20);
	PutWord (bounds.right);
	PutWord (bounds.bottom);
	PutWord (0);
	PutWord (0);
	PutByte (fDepth);
	PutByte (0);
	PutByte (1);
	PutByte (0);
	PutWord (0);
	PutByte (1);
	PutByte (1);
	PutWord (bounds.right);
	PutWord (bounds.bottom);

	code := 'CMAP';
	PutBytes (4, @code);
	PutLong (3 * BSL (1, fDepth));
	FOR gray := 0 TO gTables.fColorTable^^.ctSize DO
		BEGIN
		{$PUSH}
		{$R-}
		color := gTables.fColorTable^^.ctTable[gray].rgb;
		{$POP}
		PutByte (BSR (color.red  , 8));
		PutByte (BSR (color.green, 8));
		PutByte (BSR (color.blue , 8))
		END;
	FOR gray := gTables.fColorTable^^.ctSize + 1 TO BSL (1, fDepth) - 1 DO
		BEGIN
		PutByte (0);
		PutByte (0);
		PutByte (0)
		END;

	code := 'BODY';
	PutBytes (4, @code);

	WriteBody (doc, bounds);

	SeekTo (4);
	PutLong (GetFileLength - 8)

	END;

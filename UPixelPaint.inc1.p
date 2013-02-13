{Photoshop version 1.0.1, file: UPixelPaint.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}

{*****************************************************************************}

{$S AInit}

PROCEDURE TPixelPaintFormat.IImageFormat; OVERRIDE;

	BEGIN

	INHERITED IImageFormat;

	fCanRead	  := TRUE;
	fReadType1	  := 'PX01';
	fFileType	  := 'PX01';
	fFileCreator  := 'PIXR';
	fUsesDataFork := TRUE;
	fUsesRsrcFork := TRUE;

	fDialogID	   := 2700;
	fRadioClusters := 2;
	fRadio1Item    := 4;
	fRadio1Count   := 4;
	fRadio2Item    := 8;
	fRadio2Count   := 2;

	fCenter := TRUE;
	fCanvasSize := 1

	END;

{*****************************************************************************}

{$S APaintFormat}

FUNCTION GetCanvasCols (size: INTEGER): INTEGER;

	BEGIN

		CASE size OF
		1:	GetCanvasCols := 576;
		2:	GetCanvasCols := 512;
		3:	GetCanvasCols := 1024;
		4:	GetCanvasCols := 1024
		END

	END;

{*****************************************************************************}

{$S APaintFormat}

FUNCTION GetCanvasRows (size: INTEGER): INTEGER;

	BEGIN

		CASE size OF
		1:	GetCanvasRows := 720;
		2:	GetCanvasRows := 512;
		3:	GetCanvasRows := 1024;
		4:	GetCanvasRows := 768
		END

	END;

{*****************************************************************************}

{$S AWriteFile}

FUNCTION TPixelPaintFormat.CanWrite (doc: TImageDocument): BOOLEAN; OVERRIDE;

	BEGIN
	CanWrite := (doc.fMode IN [HalftoneMode,
							   MonochromeMode,
							   IndexedColorMode,
							   MultichannelMode]) AND
				(doc.fCols <= 1024) AND
				(doc.fRows <= 1024)
	END;

{*****************************************************************************}

{$S APaintFormat}

PROCEDURE TPixelPaintFormat.SetFormatOptions (doc: TImageDocument); OVERRIDE;

	BEGIN

	IF (fCanvasSize = 2) AND ((doc.fCols > 512) OR (doc.fRows > 512)) THEN
		fCanvasSize := 1;

	IF (fCanvasSize = 1) AND ((doc.fCols > 576) OR (doc.fRows > 720)) THEN
		fCanvasSize := 4;

	IF (fCanvasSize = 4) AND (doc.fRows > 768) THEN
		fCanvasSize := 3;

	fRadio1 := fCanvasSize - 1;
	fRadio2 := ORD (NOT fCenter);

	DoOptionsDialog;

	fCanvasSize := fRadio1 + 1;
	fCenter := (fRadio2 = 0);

	IF (doc.fCols > GetCanvasCols (fCanvasSize)) OR
	   (doc.fRows > GetCanvasRows (fCanvasSize)) THEN
		Failure (errCanvasTooSmall, 0)

	END;

{*****************************************************************************}

{$S APaintFormat}

PROCEDURE TPixelPaintFormat.ReadRow (cols: INTEGER);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		block: INTEGER;
		usedBlocks: INTEGER;
		buffer: RECORD
				length: LONGINT;
				data:	PACKED ARRAY [0..64] OF CHAR
				END;

	BEGIN

	usedBlocks := BSR (cols + 63, 6);

	FOR block := 0 TO 15 DO
		BEGIN

		GetBytes (6, @buffer);

		IF (buffer.length < 2) OR (buffer.length > 65) THEN
			Failure (errBadPixelPaint, 0);

		IF (buffer.length > 2) THEN
			GetBytes (buffer.length - 2, @buffer.data[2]);

		IF block < usedBlocks THEN
			BEGIN
			srcPtr := Ptr (@buffer.data);
			dstPtr := Ptr (ORD4 (gBuffer) + BSL (block, 6));
			UnpackBits (srcPtr, dstPtr, 64)
			END

		END

	END;

{*****************************************************************************}

{$S APaintFormat}

PROCEDURE TPixelPaintFormat.DoRead (doc: TImageDocument;
									refNum: INTEGER;
									rsrcExists: BOOLEAN); OVERRIDE;

	VAR
		row: INTEGER;
		size: INTEGER;
		color: ColorSpec;
		version: LONGINT;
		aVMArray: TVMArray;

	BEGIN

	fRefNum := refNum;

	MoveHands (NOT doc.fReverting);
	
	version := GetLong;
	
	IF version = $08000 THEN
		BEGIN
		SkipBytes (3254);
		DoReadPICT (doc, NOT doc.fReverting);
		EXIT (DoRead)
		END;

	IF version <> $7FFF THEN
		Failure (errPPVersion, 0);

	SkipBytes (288);

	size := GetWord;

	IF (size < 1) OR (size > 4) THEN Failure (errBadPixelPaint, 0);

	doc.fCols := GetCanvasCols (size);
	doc.fRows := GetCanvasRows (size);

	doc.fMode := IndexedColorMode;

	SkipBytes (768);

	FOR row := 0 TO 255 DO
		BEGIN

		GetBytes (SIZEOF (ColorSpec), @color);

		doc.fIndexedColorTable.R [row] :=
				CHR (BAND (BSR (color.rgb.red  , 8), $FF));
		doc.fIndexedColorTable.G [row] :=
				CHR (BAND (BSR (color.rgb.green, 8), $FF));
		doc.fIndexedColorTable.B [row] :=
				CHR (BAND (BSR (color.rgb.blue , 8), $FF))

		END;

	SkipBytes (1152);

	aVMArray := NewVMArray (doc.fRows, doc.fCols, 1);

	doc.fData [0] := aVMArray;

	FOR row := 0 TO doc.fRows - 1 DO
		BEGIN

		MoveHands (NOT doc.fReverting);

		UpdateProgress (row, doc.fRows);

		ReadRow (doc.fCols);

		BlockMove (gBuffer,
				   aVMArray.NeedPtr (row, row, TRUE),
				   doc.fCols);

		aVMArray.DoneWithPtr

		END;

	UpdateProgress (1, 1);

	TestForMonochrome (doc);
	TestForHalftone (doc)

	END;

{*****************************************************************************}

{$S APaintFormat}

FUNCTION TPixelPaintFormat.DataForkBytes
		(doc: TImageDocument): LONGINT; OVERRIDE;

	BEGIN
	DataForkBytes := 102556 		{ Lower bound }
	END;

{*****************************************************************************}

{$S APaintFormat}

FUNCTION TPixelPaintFormat.RsrcForkBytes
		(doc: TImageDocument): LONGINT; OVERRIDE;

	BEGIN
	RsrcForkBytes := kRsrcTypeOverhead + kRsrcOverhead + 4422
	END;

{*****************************************************************************}

{$S APaintFormat}

PROCEDURE TPixelPaintFormat.DoWriteImage (doc: TImageDocument);

	VAR
		r: Rect;
		srcPtr: Ptr;
		dstPtr: Ptr;
		bounds: Rect;
		row: INTEGER;
		block: INTEGER;
		rowOffset: INTEGER;
		colOffset: INTEGER;
		canvasRows: INTEGER;
		canvasCols: INTEGER;
		zeroData: PACKED ARRAY [0..95] OF CHAR;
		srcBuffer: PACKED ARRAY [0..63] OF CHAR;
		dstBuffer: RECORD
				   count: LONGINT;
				   data: PACKED ARRAY [0..64] OF CHAR;
				   END;

	BEGIN

	SetRect (bounds, 0, 0, doc.fCols, doc.fRows);

	canvasCols := GetCanvasCols (fCanvasSize);
	canvasRows := GetCanvasRows (fCanvasSize);

	IF fCenter THEN
		BEGIN
		rowOffset := BSR (canvasRows - bounds.bottom, 1);
		colOffset := BSR (canvasCols - bounds.right, 1)
		END
	ELSE
		BEGIN
		rowOffset := 0;
		colOffset := 0
		END;

	DoSetBytes (@zeroData, 96, 0);
	FOR row := 0 TO 15 DO
		BEGIN
		zeroData [row * 6 + 3] := CHR (2);
		zeroData [row * 6 + 4] := CHR ($C1)
		END;

	FOR row := 0 TO 1023 DO
		BEGIN

		UpdateProgress (row, 1024);

		r := bounds;

		r.top	 := row - rowOffset;
		r.bottom := r.top + 1;

		IF (r.top >= 0) AND (r.bottom <= bounds.bottom) THEN
			BEGIN

			gTables.DitherRect (doc, 0, 1, r, gBuffer, TRUE);

			FOR block := 0 TO 15 DO
				BEGIN

				r.left	:= BSL (block, 6) - colOffset;
				r.right := r.left + 64;

				IF (r.right > 0) AND (r.left < bounds.right) THEN
					BEGIN
					DoSetBytes (@srcBuffer, 64, 0);
					IF r.left <= 0 THEN
						BlockMove (gBuffer,
								   @srcBuffer [-r.left],
								   Min (r.right, bounds.right))
					ELSE
						BlockMove (Ptr (ORD4 (gBuffer) + r.left),
								   @srcBuffer,
								   Min (64, bounds.right - r.left));
					srcPtr := @srcBuffer;
					dstPtr := @dstBuffer.data;
					PackBits (srcPtr, dstPtr, 64);
					dstBuffer.count := ORD4 (dstPtr) - ORD4 (@dstBuffer.data);
					PutBytes (dstBuffer.count + 4, @dstBuffer)
					END

				ELSE
					PutBytes (6, @zeroData)

				END

			END

		ELSE
			PutBytes (96, @zeroData)

		END;

	UpdateProgress (1, 1)

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TPixelPaintFormat.DoWrite
		(doc: TImageDocument; refNum: INTEGER); OVERRIDE;

	VAR
		j: INTEGER;
		fi: FailInfo;
		data: Handle;
		spec: ColorSpec;

	PROCEDURE CleanUp (error: OSErr; message: LONGINT);
		BEGIN
		IF data <> NIL THEN DisposHandle (data)
		END;

	BEGIN

	fRefNum := refNum;

	MoveHands (FALSE);

	gTables.CompTables (doc, 0, FALSE, FALSE, 8, 8, FALSE, TRUE, 1);

	PutLong ($7FFF);
	PutZeros (288);
	PutWord (fCanvasSize);
	PutWord (8);
	PutWord (5);
	PutWord (1);

	PutByte (1);
	PutByte (0);
	PutWord (5);

	PutWord (51);
	IF fCanvasSize = 2 THEN
		PutWord (28)
	ELSE
		PutWord (8);
	PutWord (467);
	IF fCanvasSize = 2 THEN
		PutWord (611)
	ELSE
		PutWord (632);

	PutLong (0);

	PutWord (56);
	PutWord (401);
	IF fCanvasSize = 2 THEN
		PutWord (568)
	ELSE
		PutWord (609);

	PutZeros (20);

	PutWord (401);
	IF fCanvasSize = 2 THEN
		PutWord (512)
	ELSE
		PutWord (553);

	PutWord (1);
	PutZeros (10);
	PutWord (3);
	PutZeros (32);

	FOR j := 1 TO 7 DO
		BEGIN
		PutWord (0);
		PutWord (5);
		PutZeros (42);
		PutWord (1);
		PutZeros (10);
		PutWord (1);
		PutZeros (32)
		END;

	PutWord (0);
	PutWord (1);
	PutWord (40);
	PutWord (170);
	PutWord (3);
	PutWord (255);
	PutWord (9);
	PutByte (1);
	PutByte (0);
	PutByte (1);
	PutByte (1);
	PutByte (1);
	PutByte (1);
	PutWord (2);
	PutWord (256);
	PutWord (128);

	FOR j := 0 TO gTables.fColorTable^^.ctSize DO
		BEGIN

		{$PUSH}
		{$R-}
		spec := gTables.fColorTable^^.ctTable[j];
		{$POP}

		spec.value := 0;
		PutBytes (8, @spec)

		END;

	PutZeros (8 * (255 - gTables.fColorTable^^.ctSize));

	CatchFailures (fi, CleanUp);

	data := GetResource ('PPTM', 5000);
	FailResError;
	IF data = NIL THEN Failure (1, 0);

	HLock (data);
	PutBytes (GetHandleSize (data), data^);
	HUnlock (data);

	data := GetResource ('PICT', 5000);
	FailResError;
	IF data = NIL THEN Failure (1, 0);

	DetachResource (data);
	FailResError;
	AddResource (data, 'PICT', 5000, '');
	FailResError;

	Success (fi);

	DoWriteImage (doc)

	END;

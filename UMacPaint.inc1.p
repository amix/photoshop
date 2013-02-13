{Photoshop version 1.0.1, file: UMacPaint.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}

CONST

	kMacPaintRows = 720;
	kMacPaintCols = 576;

	kMacPaintRowBytes = 72;

	kMacPaintBuffer = 51840;

{*****************************************************************************}

{$S AInit}

PROCEDURE TMacPaintFormat.IImageFormat; OVERRIDE;

	BEGIN

	INHERITED IImageFormat;

	fCanRead	  := TRUE;
	fReadType1	  := 'PNTG';
	fFileType	  := 'PNTG';
	fFileCreator  := 'MPNT';
	fUsesDataFork := TRUE;

	fDialogID	   := 2600;
	fRadioClusters := 1;
	fRadio1Item    := 4;
	fRadio1Count   := 2;

	fCenter := TRUE

	END;

{*****************************************************************************}

{$S AWriteFile}

FUNCTION TMacPaintFormat.CanWrite (doc: TImageDocument): BOOLEAN; OVERRIDE;

	BEGIN
	CanWrite := (doc.fMode = HalftoneMode) AND
				(doc.fCols <= kMacPaintCols) AND
				(doc.fRows <= kMacPaintRows)
	END;

{*****************************************************************************}

{$S APaintFormat}

PROCEDURE TMacPaintFormat.SetFormatOptions (doc: TImageDocument); OVERRIDE;

	BEGIN

	fRadio1 := ORD (NOT fCenter);

	DoOptionsDialog;

	fCenter := (fRadio1 = 0)

	END;

{*****************************************************************************}

{$S APaintFormat}

PROCEDURE TMacPaintFormat.DoRead (doc: TImageDocument;
								  refNum: INTEGER;
								  rsrcExists: BOOLEAN); OVERRIDE;

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		tempPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		size: LONGINT;
		buffer: Handle;
		aVMArray: TVMArray;
		lineBuffer: PACKED ARRAY [0..255] OF CHAR;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (buffer)
		END;

	BEGIN

	fRefNum := refNum;

	MoveHands (NOT doc.fReverting);

	doc.fDepth := 1;

	doc.fRows := kMacPaintRows;
	doc.fCols := kMacPaintCols;

	doc.DefaultMode;

	size := GetFileLength - 512;

	IF size <= 0 THEN Failure (errBadMacPaint, 0);

	buffer := NewLargeHandle (size);

	CatchFailures (fi, CleanUp);

	HLock (buffer);

	SkipBytes (512);
	GetBytes (size, buffer^);

	aVMArray := NewVMArray (kMacPaintRows, kMacPaintRowBytes, 1);

	doc.fData [0] := aVMArray;

	srcPtr := buffer^;

	FOR row := 0 TO kMacPaintRows - 1 DO
		BEGIN

		UpdateProgress (row, kMacPaintRows);

		dstPtr := @lineBuffer;

		UnpackBits (srcPtr, dstPtr, kMacPaintRowBytes);

		IF ORD4 (srcPtr) - ORD4 (buffer^) > size THEN
			Failure (errBadMacPaint, 0);

		BlockMove (@lineBuffer,
				   aVMArray.NeedPtr (row, row, TRUE),
				   kMacPaintRowBytes);

		aVMArray.DoneWithPtr

		END;

	UpdateProgress (1, 1);

	aVMArray.Flush;

	IF ORD4 (srcPtr) - ORD4 (buffer^) > size THEN
		Failure (errBadMacPaint, 0);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S APaintFormat}

PROCEDURE TMacPaintFormat.DoWrite
		(doc: TImageDocument; refNum: INTEGER); OVERRIDE;

	VAR
		r: Rect;
		srcPtr: Ptr;
		dstPtr: Ptr;
		row: INTEGER;
		col: INTEGER;
		bounds: Rect;
		srcBit: INTEGER;
		dstBit: INTEGER;
		rowBytes: INTEGER;
		rowOffset: INTEGER;
		colOffset: INTEGER;

	BEGIN

	fRefNum := refNum;

	MoveHands (FALSE);

	SetRect (bounds, 0, 0, doc.fCols, doc.fRows);

	PutZeros (512);

	gTables.CompTables (doc, 0, TRUE, FALSE, 1, 1, TRUE, TRUE, 1);

	IF fCenter THEN
		BEGIN
		rowOffset := BSR (kMacPaintRows - bounds.bottom, 1);
		colOffset := BSR (kMacPaintCols - bounds.right, 1)
		END
	ELSE
		BEGIN
		rowOffset := 0;
		colOffset := 0
		END;

	rowBytes := gTables.CompRowBytes (bounds.right);

	FOR row := 0 TO kMacPaintRows - 1 DO
		BEGIN

		UpdateProgress (row, kMacPaintRows);

		r		 := bounds;
		r.top	 := row - rowOffset;
		r.bottom := r.top + 1;

		dstPtr := Ptr (ORD4 (gBuffer) + rowBytes);

		DoSetBytes (dstPtr, kMacPaintRowBytes, 0);

		IF (r.top >= 0) AND (r.bottom <= bounds.bottom) THEN
			BEGIN

			gTables.DitherRect (doc, 0, 1, r, gBuffer, TRUE);

			DoSetBytes (dstPtr, kMacPaintRowBytes, 0);

			srcPtr := gBuffer;
			srcBit := 7;
			dstPtr := Ptr (ORD4 (gBuffer) + rowBytes + BSR (colOffset, 3));
			dstBit := 7 - BAND (colOffset, 7);

			IF dstBit = 7 THEN
				BlockMove (srcPtr, dstPtr, rowBytes)

			ELSE
				FOR col := 0 TO bounds.right - 1 DO
					BEGIN

					IF BTST (srcPtr^, srcBit) THEN
						dstPtr^ := dstPtr^ + BSL (1, dstBit);

					IF srcBit = 0 THEN
						BEGIN
						srcBit := 7;
						srcPtr := Ptr (ORD4 (srcPtr) + 1)
						END
					ELSE
						srcBit := srcBit - 1;

					IF dstBit = 0 THEN
						BEGIN
						dstBit := 7;
						dstPtr := Ptr (ORD4 (dstPtr) + 1)
						END
					ELSE
						dstBit := dstBit - 1

					END

			END;

		srcPtr := Ptr (ORD4 (gBuffer) + rowBytes);
		dstPtr := Ptr (ORD4 (gBuffer) + rowBytes + kMacPaintRowBytes);

		PackBits (srcPtr, dstPtr, kMacPaintRowBytes);

		PutBytes (ORD4 (dstPtr) - ORD4 (srcPtr), srcPtr)

		END;

	UpdateProgress (1, 1)

	END;

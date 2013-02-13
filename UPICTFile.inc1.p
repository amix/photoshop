{Photoshop version 1.0.1, file: UPICTFile.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}
{$I UDither.a.inc}

CONST
	kHave8BitPICT	 = 2;
	kHave24BitPICT	 = 3;
	kHaveNewSizePICT = 4;

VAR
	gHScale: EXTENDED;
	gVScale: EXTENDED;
	gHaveScale: BOOLEAN;

	gGetPICTError : OSErr;
	gGetPICTObject: TPICTFileFormat;

{*****************************************************************************}

{$S AInit}

PROCEDURE TPICTFileFormat.IImageFormat; OVERRIDE;

	BEGIN

	INHERITED IImageFormat;

	fCanRead	  := TRUE;
	fReadType1	  := 'PICT';
	fFileType	  := 'PICT';
	fUsesDataFork := TRUE;
	fUsesRsrcFork := TRUE;

	fTransferMode := srcCopy;

	fDialogID	   := 2000;
	fRadioClusters := 1;
	fRadio1Item    := 4;
	fRadio1Count   := 7

	END;

{*****************************************************************************}

{$S AWriteFile}

FUNCTION TPICTFileFormat.CanWrite (doc: TImageDocument): BOOLEAN; OVERRIDE;

	BEGIN

	CanWrite := doc.fMode IN [HalftoneMode,
							  MonochromeMode,
							  IndexedColorMode,
							  RGBColorMode,
							  MultichannelMode]

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TPICTFileFormat.SetFormatOptions (doc: TImageDocument); OVERRIDE;

	BEGIN

	IF doc.fMode = RGBColorMode THEN
		fRadio1 := 6

	ELSE
		BEGIN

		gTables.CompTables (doc, 0, FALSE, FALSE, 8, 8, TRUE, TRUE, 1);

		fDepth := 1;
		WHILE gTables.fResolution > fDepth DO
			fDepth := BSL (fDepth, 1);

		IF gTables.fSystemPalette THEN
			fRadio1 := 4
		ELSE
			CASE fDepth OF
			1:	fRadio1 := 0;
			2:	fRadio1 := 1;
			4:	fRadio1 := 2;
			8:	fRadio1 := 3
			END

		END;

	DoOptionsDialog;

		CASE fRadio1 OF
		0:	fDepth := 1;
		1:	fDepth := 2;
		2:	fDepth := 4;
		3:	fDepth := 8;
		4:	fDepth := 8;
		5:	fDepth := 16;
		6:	fDepth := 32
		END;

	fSystemPalette := (fRadio1 = 4);

	fUsesRsrcFork := (fDepth > 1) AND (fDepth <= 8)

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TPICTFileFormat.AdjustRects (doc: TImageDocument;
									   hRes: Fixed;
									   vRes: Fixed;
									   pictBounds: Rect;
									   bounds: Rect;
									   VAR srcRect: Rect;
									   VAR dstRect: Rect);

	LABEL
		1;

	VAR
		upper: EXTENDED;
		lower: EXTENDED;
		guess: EXTENDED;
		almost: BOOLEAN;
		srcWidth: INTEGER;
		dstWidth: INTEGER;
		srcHeight: INTEGER;
		dstHeight: INTEGER;

	BEGIN
	
	IF EmptyRect (srcRect) OR EmptyRect (dstRect) THEN
		Failure (errBadPICT, 0);

	OffsetRect (dstRect, -pictBounds.left, -pictBounds.top);

	IF (dstRect.top < 0) OR (dstRect.left < 0) THEN
		Failure (errBadPICT - 1, 0);

	{*** Begin PixelPaint hacks ***}

	IF srcRect.right - srcRect.left > bounds.right - bounds.left THEN
		BEGIN
		srcRect.right := srcRect.left + (bounds.right - bounds.left);
		dstRect.right := dstRect.left + (bounds.right - bounds.left)
		END;

	IF srcRect.bottom - srcRect.top > bounds.bottom - bounds.top THEN
		BEGIN
		srcRect.bottom := srcRect.top + (bounds.bottom - bounds.top);
		dstRect.bottom := dstRect.top + (bounds.bottom - bounds.top)
		END;

	SlideRectInto (srcRect, bounds);

	{*** End PixelPaint hacks ***}

	1:	{ AppleScan hack reentry }

	IF gHaveScale THEN
		BEGIN

		IF hRes = 0 THEN
			BEGIN

			hRes := ROUND (gHScale * 72) * $10000;

			IF (hRes >= $10000) AND (hRes <= 3200 * $10000) THEN
				doc.fStyleInfo.fResolution.value := hRes

			END;

		dstRect.left  := ROUND (dstRect.left  * gHScale);
		dstRect.right := ROUND (dstRect.right * gHScale);

		almost := (dstRect.bottom - 1) * gVScale <= doc.fRows;

		IF (srcRect.top    >= (dstRect.top	  - 1) * gVScale) &
		   (srcRect.top    <= (dstRect.top	  + 1) * gVScale) &
		   (srcRect.bottom >= (dstRect.bottom - 1) * gVScale) &
		   (srcRect.bottom <= (dstRect.bottom + 1) * gVScale) THEN
			BEGIN
			dstRect.top    := srcRect.top;
			dstRect.bottom := srcRect.bottom
			END
		ELSE
			BEGIN
			dstRect.top    := ROUND (dstRect.top	* gVScale);
			dstRect.bottom := ROUND (dstRect.bottom * gVScale)
			END;

		IF almost AND (dstRect.bottom > doc.fRows) THEN
			BEGIN

			srcRect.bottom := srcRect.bottom - (dstRect.bottom - doc.fRows);
			dstRect.bottom := doc.fRows;

			IF EmptyRect (srcRect) THEN
				Failure (errBadPICT - 2, 0)

			END

		END;

	srcWidth  := srcRect.right - srcRect.left;
	srcHeight := srcRect.bottom - srcRect.top;

	dstWidth  := dstRect.right - dstRect.left;
	dstHeight := dstRect.bottom - dstRect.top;

	IF (srcHeight <> dstHeight) OR (srcWidth <> dstWidth) THEN

		IF gHaveScale THEN
			Failure (errBadPICT - 3, 0)

		ELSE
			BEGIN

			gHaveScale := TRUE;

			gHScale := srcWidth  / dstWidth;
			gVScale := srcHeight / dstHeight;

			{*** Begin AppleScan hack ***}

			IF (doc.fCols = srcWidth) AND (doc.fRows = srcHeight) THEN
				GOTO 1;

			{*** End AppleScan hack ***}

			IF (dstHeight > 1) AND (dstHeight <> doc.fRows) THEN
				BEGIN

				lower := srcHeight / (dstHeight + 1);
				upper := srcHeight / (dstHeight - 1);

				IF (vRes = 0) AND (srcWidth > srcHeight) THEN
					guess := gHScale
				ELSE
					guess := vRes / $10000;

				IF (guess >= lower) AND (guess <= upper) THEN
					gVScale := guess

				END;

			IF (doc.fCols * gHScale > kMaxCoord) OR
			   (doc.fRows * gVScale > kMaxCoord) THEN
				Failure (errBadPICT - 4, 0);

			doc.fCols := ROUND (doc.fCols * gHScale);
			doc.fRows := ROUND (doc.fRows * gVScale);

			Failure (kHaveNewSizePICT, 0)

			END;

	IF (dstRect.bottom > doc.fRows) OR (dstRect.right > doc.fCols) THEN
		Failure (errBadPICT - 5, 0)

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TPICTFileFormat.ParseCopyBits (doc: TImageDocument;
										 opcode: INTEGER;
										 pictBounds: Rect;
										 canAbort: BOOLEAN);

	VAR
		r: Rect;
		hRes: Fixed;
		vRes: Fixed;
		srcPtr: Ptr;
		dstPtr: Ptr;
		row: INTEGER;
		col: INTEGER;
		bit: INTEGER;
		bounds: Rect;
		dstPtr1: Ptr;
		dstPtr2: Ptr;
		mode: INTEGER;
		srcRect: Rect;
		dstRect: Rect;
		limit: INTEGER;
		count: LONGINT;
		width: INTEGER;
		spec: ColorSpec;
		imageRow: INTEGER;
		imageCol: INTEGER;
		rowBytes: INTEGER;
		pixelSize: INTEGER;

	BEGIN

	rowBytes := GetWord;

	GetBytes (8, @bounds);

	hRes := 0;
	vRes := 0;

	IF BAND (rowBytes, $8000) = 0 THEN
		pixelSize := 1

	ELSE
		BEGIN

		rowBytes := BAND (rowBytes, $7FFF);

		IF GetLong <> 0 THEN Failure (errBadPICT - 4, 0);

		SkipBytes (4);

		hRes := Fixed (GetLong);
		vRes := Fixed (GetLong);

		IF (hRes >= $10000) AND (hRes <= 3200 * $10000) THEN
			doc.fStyleInfo.fResolution.value := hRes;

		IF GetWord <> 0 THEN Failure (errBadPICT - 5, 0);

		pixelSize := GetWord;

		IF (pixelSize <> 1) AND
		   (pixelSize <> 2) AND
		   (pixelSize <> 4) AND
		   (pixelSize <> 8) THEN Failure (errBadPICT - 6, 0);

		IF (pixelSize <> 1) AND
		   (doc.fDepth = 1) THEN Failure (kHave8BitPICT, 0);

		IF GetWord <> 1 THEN Failure (errBadPICT - 7, 0);

		IF GetWord <> pixelSize THEN Failure (errBadPICT - 8, 0);

		SkipBytes (18);

		limit := GetWord;

		FOR row := 0 TO limit DO
			BEGIN

			GetBytes (8, @spec);

			IF row <= 255 THEN
				BEGIN
				doc.fIndexedColorTable.R [row] :=
						CHR (BAND (BSR (spec.rgb.red  , 8), $FF));
				doc.fIndexedColorTable.G [row] :=
						CHR (BAND (BSR (spec.rgb.green, 8), $FF));
				doc.fIndexedColorTable.B [row] :=
						CHR (BAND (BSR (spec.rgb.blue , 8), $FF))
				END

			END;

		IF limit = 0 THEN
			BEGIN
			doc.fIndexedColorTable.R := gInvertLUT;
			doc.fIndexedColorTable.G := gInvertLUT;
			doc.fIndexedColorTable.B := gInvertLUT
			END

		ELSE IF (limit <> 7) OR (pixelSize <> 8) THEN	{ Old GrayView bug }
			FOR row := limit + 1 TO 255 DO
				BEGIN
				doc.fIndexedColorTable.R [row] := CHR (0);
				doc.fIndexedColorTable.G [row] := CHR (0);
				doc.fIndexedColorTable.B [row] := CHR (0)
				END

		END;

	GetBytes (8, @srcRect);
	GetBytes (8, @dstRect);

	AdjustRects (doc, hRes, vRes, pictBounds, bounds, srcRect, dstRect);

	mode := GetWord;

	IF (mode <> srcCopy) AND ((mode <> srcOr) OR (doc.fDepth <> 1)) THEN
		IF mode <> 34 THEN { addOver }
			Failure (errBadPICT - 9, 0)
		ELSE IF doc.fChannels <> 3 THEN
			Failure (kHave24BitPICT, 0)
		ELSE IF pixelSize <> 8 THEN
			Failure (errBadPICT, 0);

	IF ODD (opcode) THEN SkipBytes (GetWord - 2);

	OffsetRect (srcRect, -bounds.left, 0);

	imageRow := dstRect.top;
	imageCol := dstRect.left;

	IF doc.fDepth = 1 THEN
		BEGIN

		IF BAND (imageCol, 7) <> 0 THEN
			Failure (errBadPICT - 1, 0);

		imageCol := BSR (imageCol, 3)

		END;

	FOR row := bounds.top TO bounds.bottom - 1 DO
		BEGIN

		MoveHands (canAbort);

		IF opcode >= $98 THEN
			BEGIN

			IF rowBytes > 250 THEN
				count := GetWord
			else
				count := GetByte;

			IF (count < 0) OR (rowBytes + count > 32768) THEN
				Failure (errBadPICT - 2, 0);

			srcPtr := Ptr (ORD4 (gBuffer) + rowBytes);
			dstPtr := gBuffer;

			GetBytes (count, srcPtr);
			UnpackBits (srcPtr, dstPtr, rowBytes)

			END

		ELSE
			GetBytes (rowBytes, gBuffer);

		IF (row >= srcRect.top) AND (row < srcRect.bottom) THEN
			BEGIN

			UpdateProgress (imageRow, doc.fRows);

			dstPtr := doc.fData [0] . NeedPtr (imageRow, imageRow, TRUE);
			dstPtr := Ptr (ORD4 (dstPtr) + imageCol);

			IF doc.fChannels = 3 THEN
				BEGIN

				dstPtr1 := doc.fData [1] . NeedPtr (imageRow, imageRow, TRUE);
				dstPtr1 := Ptr (ORD4 (dstPtr1) + imageCol);

				dstPtr2 := doc.fData [2] . NeedPtr (imageRow, imageRow, TRUE);
				dstPtr2 := Ptr (ORD4 (dstPtr2) + imageCol);

				width := srcRect.right - srcRect.left;

				IF mode = srcCopy THEN
					BEGIN

					BlockMove (Ptr (ORD4 (gBuffer) + srcRect.left),
							   dstPtr, width);

					BlockMove (dstPtr, dstPtr1, width);
					BlockMove (dstPtr, dstPtr2, width);

					DoMapBytes (dstPtr , width, doc.fIndexedColorTable.R);
					DoMapBytes (dstPtr1, width, doc.fIndexedColorTable.G);
					DoMapBytes (dstPtr2, width, doc.fIndexedColorTable.B)

					END

				ELSE
					BEGIN

					DoAddOver (Ptr (ORD4 (gBuffer) + srcRect.left),
							   dstPtr, doc.fIndexedColorTable.R, width);

					DoAddOver (Ptr (ORD4 (gBuffer) + srcRect.left),
							   dstPtr1, doc.fIndexedColorTable.G, width);

					DoAddOver (Ptr (ORD4 (gBuffer) + srcRect.left),
							   dstPtr2, doc.fIndexedColorTable.B, width)

					END;

				doc.fData [1] . DoneWithPtr;
				doc.fData [2] . DoneWithPtr

				END

			ELSE IF doc.fDepth = 1 THEN
				BEGIN

				r.top	 := 0;
				r.bottom := 1;
				r.left	 := srcRect.left;
				r.right  := srcRect.right;

				DoHalftone (gBuffer, 0, dstPtr, 0, 1, r, 1)

				END

			ELSE
				CASE pixelSize OF

				1:	BEGIN

					srcPtr := Ptr (ORD4 (gBuffer) + BSR (srcRect.left, 3));

					FOR col := srcRect.left TO srcRect.right - 1 DO
						BEGIN

						bit := 7 - BAND (col, 7);

						IF BTST (srcPtr^, bit) THEN
							dstPtr^ := -1
						ELSE
							dstPtr^ := 0;

						dstPtr := Ptr (ORD4 (dstPtr) + 1);

						IF bit = 0 THEN
							srcPtr := Ptr (ORD4 (srcPtr) + 1)

						END

					END;

				2:	BEGIN

					srcPtr := Ptr (ORD4 (gBuffer) + BSR (srcRect.left, 2));

					FOR col := srcRect.left TO srcRect.right - 1 DO
						BEGIN

							CASE BAND (col, 3) OF

							0:	dstPtr^ := BAND (BSR (srcPtr^, 6), 3);
							1:	dstPtr^ := BAND (BSR (srcPtr^, 4), 3);
							2:	dstPtr^ := BAND (BSR (srcPtr^, 2), 3);

							3:	BEGIN
								dstPtr^ := BAND (srcPtr^, 3);
								srcPtr := Ptr (ORD4 (srcPtr) + 1)
								END

							END;

						dstPtr := Ptr (ORD4 (dstPtr) + 1)

						END

					END;

				4:	BEGIN

					srcPtr := Ptr (ORD4 (gBuffer) + BSR (srcRect.left, 1));

					FOR col := srcRect.left TO srcRect.right - 1 DO
						BEGIN

						IF ODD (col) THEN
							BEGIN
							dstPtr^ := BAND (srcPtr^, 15);
							srcPtr := Ptr (ORD4 (srcPtr) + 1);
							END
						ELSE
							dstPtr^ := BAND (BSR (srcPtr^, 4), 15);

						dstPtr := Ptr (ORD4 (dstPtr) + 1)

						END

					END;

				8:	BlockMove (Ptr (ORD4 (gBuffer) + srcRect.left),
							   dstPtr,
							   srcRect.right - srcRect.left)

				END;

			imageRow := imageRow + 1;

			doc.fData [0] . DoneWithPtr

			END

		END;

	UpdateProgress (imageRow, doc.fRows)

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TPICTFileFormat.ParseDirectBits (doc: TImageDocument;
										   opcode: INTEGER;
										   pictBounds: Rect;
										   canAbort: BOOLEAN);

	VAR
		hRes: Fixed;
		vRes: Fixed;
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		bounds: Rect;
		srcRect: Rect;
		dstRect: Rect;
		count: LONGINT;
		width: INTEGER;
		channel: INTEGER;
		cmpSize: INTEGER;
		cmpCount: INTEGER;
		imageRow: INTEGER;
		imageCol: INTEGER;
		packType: INTEGER;
		rowBytes: INTEGER;
		aVMArray: TVMArray;
		component: INTEGER;
		pixelSize: INTEGER;
		tempBuffer: Handle;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (tempBuffer)
		END;

	BEGIN

	SkipBytes (4);

	rowBytes := BAND (GetWord, $7FFF);

	GetBytes (8, @bounds);

	IF GetWord <> 0 THEN Failure (errBadPICT - 3, 0);

	packType := GetWord;

	IF GetLong <> 0 THEN Failure (errBadPICT - 4, 0);

	hRes := Fixed (GetLong);
	vRes := Fixed (GetLong);

	IF (hRes >= $10000) AND (hRes <= 3200 * $10000) THEN
		doc.fStyleInfo.fResolution.value := hRes;

	IF GetWord <> RGBDirect THEN Failure (errBadPICT - 5, 0);

	pixelSize := GetWord;
	cmpCount  := GetWord;
	cmpSize   := GetWord;

		CASE pixelSize OF

		16: IF cmpCount <> 3 THEN
				Failure (errBadPICT - 6, 0);

		32: IF (cmpCount < 3) OR (cmpCount > 4) THEN
				Failure (errBadPICT - 7, 0)

		END;

	SkipBytes (12);

	GetBytes (8, @srcRect);
	GetBytes (8, @dstRect);

	AdjustRects (doc, hRes, vRes, pictBounds, bounds, srcRect, dstRect);

	SkipBytes (2);

	IF opcode = $9B THEN
		SkipBytes (GetWord - 2);

	OffsetRect (srcRect, -bounds.left, 0);

	imageRow := dstRect.top;
	imageCol := dstRect.left;

	width := srcRect.right - srcRect.left;

	IF rowBytes < 8 THEN packType := 1; {???}

		CASE packType OF

		1:	;

		2:	IF (pixelSize <> 32) OR (cmpCount <> 3) THEN
				Failure (errBadPICT - 8, 0);

		3:	IF pixelSize <> 16 THEN
				Failure (errBadPICT - 9, 0);

		4:	IF pixelSize <> 32 THEN
				Failure (errBadPICT, 0);

		OTHERWISE
			Failure (errBadPICT - 1, 0)

		END;

	tempBuffer := NewLargeHandle (rowBytes);

	CatchFailures (fi, CleanUp);

	MoveHHi (tempBuffer);
	HLock (tempBuffer);

	IF (cmpCount = 4) AND (doc.fChannels = 3) THEN
		BEGIN

		doc.fChannels := 4;

		aVMArray := NewVMArray (doc.fRows, doc.fCols, 1);

		doc.fData [3] := aVMArray;

		aVMArray.SetBytes (255)

		END;

	FOR row := bounds.top TO bounds.bottom - 1 DO
		BEGIN

		MoveHands (canAbort);

			CASE packType OF

			1:	GetBytes (rowBytes, tempBuffer^);

			2:	GetBytes (rowBytes - BSR (rowBytes, 2), tempBuffer^);

			OTHERWISE
				BEGIN

				IF rowBytes > 250 THEN
					count := GetWord
				ELSE
					count := GetByte;

				IF count <= 0 THEN Failure (errBadPICT - 2, 0);

				GetBytes (count, gBuffer);

				srcPtr := gBuffer;
				dstPtr := tempBuffer^;

				IF packType = 3 THEN
					UnpackWords (srcPtr, dstPtr, width)

				ELSE
					BEGIN
					IF cmpCount = 3 THEN
						count := rowBytes - BSR (rowBytes, 2)
					ELSE
						count := rowBytes;
					UnpackBits (srcPtr, dstPtr, count)
					END

				END

			END;

		IF (row >= srcRect.top) AND (row < srcRect.bottom) THEN
			BEGIN

			UpdateProgress (imageRow, doc.fRows);

			FOR channel := 0 TO cmpCount - 1 DO
				BEGIN

				dstPtr := Ptr (ORD4 (doc.fData [channel] .
									 NeedPtr (imageRow,
											  imageRow,
											  TRUE)) + imageCol);

				srcPtr := tempBuffer^;

				IF pixelSize = 16 THEN
					CASE channel OF

					0:	Extract16Red (srcPtr, dstPtr, width);

					1:	Extract16Green (srcPtr, dstPtr, width);

					2:	Extract16Blue (srcPtr, dstPtr, width)

					END

				ELSE
					CASE packType OF

					1:	DoStepCopyBytes (Ptr (ORD4 (srcPtr) +
											  BSL (srcRect.left, 2) +
											  (channel + 1) MOD 4),
										 dstPtr,
										 width,
										 4,
										 1);

					2:	DoStepCopyBytes (Ptr (ORD4 (srcPtr) +
											  srcRect.left * 3 +
											  channel),
										 dstPtr,
										 width,
										 3,
										 1);

					4:	BEGIN

						IF cmpCount = 4 THEN
							component := (channel + 1) MOD 4
						ELSE
							component := channel;

						BlockMove (Ptr (ORD4 (srcPtr) +
										BSR (rowBytes, 2) * component +
										srcRect.left),
								   dstPtr,
								   width)

						END

					END;

				doc.fData [channel] . DoneWithPtr

				END;

			imageRow := imageRow + 1

			END

		END;

	UpdateProgress (imageRow, doc.fRows);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TPICTFileFormat.ParsePICT (doc: TImageDocument;
									 canAbort: BOOLEAN);

	VAR
		opcode: INTEGER;
		channel: INTEGER;
		pictBounds: Rect;
		bigOpcodes: BOOLEAN;

	BEGIN

	IF doc.fChannels = 3 THEN
		FOR channel := 0 TO 2 DO
			doc.fData [channel] . SetBytes (255)
	ELSE
		doc.fData [0] . SetBytes (0);

	SkipBytes (2);
	GetBytes (8, @pictBounds);

	bigOpcodes := FALSE;

		REPEAT

		IF bigOpcodes THEN
			BEGIN
			IF ODD (GetFilePosition) THEN SkipBytes (1);
			opcode := GetWord
			END
		ELSE
			opcode := GetByte;

		IF BAND (opcode, $FF00) = 0 THEN
			CASE opcode OF

			$0, 							{ NOP }
			$1E,							{ Default hilite color }
			$FF:							{ End of image }
				;

			$1: 							{ Clip }
				SkipBytes (GetWord - 2);

			$11:							{ Version }
				bigOpcodes := GetByte > 1;

			$1A,							{ RGB foreground color }
			$1B,							{ RGB background color }
			$1D,							{ RGB hilite color }
			$1F:							{ RGB OpColor }
				SkipBytes (6);

			$9: 							{ PnPat }
				SkipBytes (8);

			$A0:							{ Short comment }
				SkipBytes (2);

			$A1:							{ Long comment }
				BEGIN
				SkipBytes (2);
				SkipBytes (GetWord)
				END;

			$90, $91, $98, $99: 			{ Copybits }
				ParseCopyBits (doc, opcode, pictBounds, canAbort);

			$9A, $9B:						{ DirectBits }
				IF doc.fChannels >= 3 THEN
					ParseDirectBits (doc, opcode, pictBounds, canAbort)
				ELSE
					Failure (kHave24BitPICT, 0);

			OTHERWISE
				BEGIN

				{$IFC qDebug}
				writeln ('Unknown opcode = ', opcode:1);
				{$ENDC}

				Failure (errBadPICT - 3, 0)

				END

			END

		ELSE IF opcode = $0C00 THEN
			SkipBytes (24)

		ELSE
			Failure (errBadPICT - 4, 0)

		UNTIL opcode = $FF;

	UpdateProgress (1, 1);

	FOR channel := 0 TO doc.fChannels - 1 DO
		doc.fData [channel] . Flush

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE GetPICTBytes (dataPtr: Ptr; byteCount: INTEGER);

	VAR
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		gGetPICTError := error;

		DoSetBytes (dataPtr, byteCount, $FF);

		EXIT (GetPICTBytes)

		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	MoveHands (FALSE);

	IF gGetPICTError <> noErr THEN Failure (gGetPICTError, 0);

	gGetPICTObject . GetBytes (byteCount, dataPtr);

	Success (fi)

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TPICTFileFormat.ParseOldPICT (doc: TImageDocument);

	VAR
		bm: BitMap;
		fi: FailInfo;
		row: INTEGER;
		size: LONGINT;
		buffer: Handle;
		qProcs: QDProcs;
		offPort: GrafPort;
		savePort: GrafPtr;
		thePICT: PicHandle;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		IF thePICT <> NIL THEN
			DisposHandle (Handle (thePICT));

		FreeLargeHandle (buffer)

		END;

	BEGIN

	thePICT := NIL;

	SetRect (bm.bounds, 0, 0, doc.fCols, doc.fRows);

	bm.rowBytes := doc.fData [0] . fLogicalSize;

	size := bm.rowBytes * ORD4 (doc.fRows);

	buffer := NewLargeHandle (size);

	CatchFailures (fi, CleanUp);

	MoveHHi (buffer);
	HLock	(buffer);

	bm.baseAddr := buffer^;

	DoSetBytes (bm.baseAddr, size, 0);

	thePICT := PicHandle (NewHandle (SIZEOF (Picture)));
	FailNil (thePICT);

	HLock (Handle (thePICT));
	GetBytes (SIZEOF (Picture), Ptr (thePICT^));

	HUnlock (Handle (thePICT));

	GetPort (savePort);

	OpenPort (@offPort);
	SetPortBits (bm);
	ClipRect (bm.bounds);
	RectRgn (offPort.visRgn, bm.bounds);

	SetStdProcs (qProcs);
	offPort.grafProcs := @qProcs;
	qProcs.getPicProc := @GetPICTBytes;

	gGetPICTError  := noErr;
	gGetPICTObject := SELF;

	DrawPicture (PicHandle (thePICT), bm.bounds);

	SetPort (savePort);

	FailOSErr (gGetPICTError);

	FOR row := 0 TO doc.fRows - 1 DO
		BEGIN

		BlockMove (Ptr (ORD4 (buffer^) + row * ORD4 (bm.rowBytes)),
				   doc.fData [0] . NeedPtr (row, row, TRUE),
				   bm.rowBytes);

		doc.fData [0] . DoneWithPtr

		END;

	doc.fData [0] . Flush;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TPICTFileFormat.ParseNewPICT (doc: TImageDocument);

	VAR
		r: Rect;
		fi: FailInfo;
		row: INTEGER;
		index: INTEGER;
		width: INTEGER;
		buffer: Handle;
		color: RGBColor;
		pm: PixMapHandle;
		cProcs: CQDProcs;
		freePort: BOOLEAN;
		savePort: GrafPtr;
		thePICT: PicHandle;
		offPort: CGrafPort;
		offDevice: GDHandle;
		saveDevice: GDHandle;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		SetPort (savePort);
		SetGDevice (saveDevice);

		IF freePort THEN
			CloseCPort (@offPort);

		IF offDevice <> NIL THEN
			BEGIN
			offDevice^^.gdPMap := NIL;
			DisposGDevice (offDevice)
			END;

		IF pm <> NIL THEN
			BEGIN
			IF pm^^.pmTable <> NIL THEN DisposCTable (pm^^.pmTable);
			DisposHandle (Handle (pm))
			END;

		IF thePICT <> NIL THEN
			DisposHandle (Handle (thePICT));

		IF buffer <> NIL THEN
			FreeLargeHandle (buffer)

		END;

	BEGIN

	pm := NIL;
	buffer := NIL;
	thePICT := NIL;
	offDevice := NIL;
	freePort := FALSE;

	GetPort (savePort);
	saveDevice := GetGDevice;

	CatchFailures (fi, CleanUp);

	width := BAND (doc.fCols + 1, $7FFE);

	buffer := NewLargeHandle (doc.fRows * ORD4 (width));

	MoveHHi (buffer);
	HLock	(buffer);

	DoSetBytes (buffer^, GetHandleSize (buffer), 0);

	thePICT := PicHandle (NewHandle (SIZEOF (Picture)));
	FailNil (thePICT);

	HLock (Handle (thePICT));
	GetBytes (SIZEOF (Picture), Ptr (thePICT^));

	HUnlock (Handle (thePICT));

	SetRect (r, 0, 0, doc.fCols, doc.fRows);

	pm := PixMapHandle (NewHandle (SIZEOF (PixMap)));
	FailMemError;

	WITH pm^^ DO
		BEGIN
		baseAddr   := buffer^;
		rowBytes   := width + $8000;
		bounds	   := r;
		pmVersion  := 0;
		packType   := 0;
		packSize   := 0;
		hRes	   := Fixed ($480000);
		vRes	   := Fixed ($480000);
		pixelType  := 0;
		pixelSize  := 8;
		cmpCount   := 1;
		cmpSize    := 8;
		planeBytes := 0;
		pmReserved := 0
		END;

	pm^^.pmTable := GetCTable (8);
	FailNil (pm^^.pmTable);

	FOR index := 0 TO 255 DO
		BEGIN

		color.red	:= ORD (doc.fIndexedColorTable.R [index]);
		color.green := ORD (doc.fIndexedColorTable.G [index]);
		color.blue	:= ORD (doc.fIndexedColorTable.B [index]);

		color.red	:= BOR (BSL (color.red	, 8), color.red  );
		color.green := BOR (BSL (color.green, 8), color.green);
		color.blue	:= BOR (BSL (color.blue , 8), color.blue );

		{$PUSH}
		{$R-}
		pm^^.pmTable^^.ctTable [index] . rgb := color;
		{$POP}

		END;

	pm^^.pmTable^^.ctSeed	  := GetCTSeed;
	pm^^.pmTable^^.transIndex := $8000;

	offDevice := NewGDevice (-1, -1);
	FailNil (offDevice);

	WITH offDevice^^ DO
		BEGIN
		gdType	  := clutType;
		gdResPref := 4;
		gdFlags   := $4001;
		gdPMap	  := pm;
		gdRect	  := r
		END;

	SetGDevice (offDevice);

	MakeITable (NIL, NIL, 0);

	IF QDError <> noErr THEN
		Failure (memFullErr, 0);

	OpenCPort (@offPort);

	IF QDError <> noErr THEN
		Failure (memFullErr, 0);

	freePort := TRUE;

	ClipRect (r);
	RectRgn (offPort.visRgn, r);

	SetStdCProcs (cProcs);
	offPort.grafProcs := @cProcs;
	cProcs.getPicProc := @GetPICTBytes;

	gGetPICTError  := noErr;
	gGetPICTObject := SELF;

	DrawPicture (PicHandle (thePICT), r);

	IF QDError <> noErr THEN
		Failure (memFullErr, 0);

	FailOSErr (gGetPICTError);

	FOR row := 0 TO doc.fRows - 1 DO
		BEGIN

		BlockMove (Ptr (ORD4 (buffer^) + row * ORD4 (width)),
				   doc.fData [0] . NeedPtr (row, row, TRUE),
				   doc.fCols);

		doc.fData [0] . DoneWithPtr

		END;

	doc.fData [0] . Flush;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TPICTFileFormat.DoReadPICT (doc: TImageDocument;
									  canAbort: BOOLEAN);

	LABEL
		1, 2, 3;

	VAR
		fi: FailInfo;
		bounds: Rect;
		depth: INTEGER;
		version: INTEGER;
		channel: INTEGER;
		rowBytes: INTEGER;
		aVMArray: TVMArray;
		pictStart: LONGINT;
		reverting: BOOLEAN;
		sysTable: HRGBLookUpTable;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
			CASE error OF

			kHave8BitPICT:
				IF depth = 8 THEN
					GOTO 2
				ELSE
					BEGIN
					depth := 8;
					GOTO 1
					END;

			kHave24BitPICT:
				IF depth = 24 THEN
					GOTO 2
				ELSE
					BEGIN
					depth := 24;
					GOTO 1
					END;

			kHaveNewSizePICT:
				GOTO 1;

			OTHERWISE
				IF error <> 0 THEN
					GOTO 2

			END
		END;

	BEGIN

	MoveHands (canAbort);

	reverting := doc.fReverting;

	pictStart := GetFilePosition;

	IF GetFileLength - pictStart < SIZEOF (Picture) + 3 THEN
		Failure (errBadPICT - 5, 0);

	SkipBytes (2);

	GetBytes (8, @bounds);

	IF EmptyRect (bounds) THEN
		Failure (errBadPICT - 6, 0);

	doc.fRows := bounds.bottom - bounds.top;
	doc.fCols := bounds.right  - bounds.left;

	gHaveScale := FALSE;

	IF GetWord = $1101 THEN
		version := 1
	ELSE
		version := 2;

	depth := 1;

	1:	{ Parse PICT of current depth }

	doc.FreeData;
	doc.fReverting := reverting;

		CASE depth OF

		1:	BEGIN

			doc.fMode  := HalftoneMode;
			doc.fDepth := 1;

			rowBytes := BSL (BSR (doc.fCols + 15, 4), 1);

			aVMArray := NewVMArray (doc.fRows, rowBytes, 1);

			doc.fData [0] := aVMArray

			END;

		8:	BEGIN

			doc.fMode := IndexedColorMode;

			sysTable := HRGBLookUpTable (GetResource ('PLUT', 1000));
			FailNil (sysTable);

			doc.fIndexedColorTable := sysTable^^;

			aVMArray := NewVMArray (doc.fRows, doc.fCols, 1);

			doc.fData [0] := aVMArray

			END;

		24: BEGIN

			doc.fMode	  := RGBColorMode;
			doc.fChannels := 3;

			FOR channel := 0 TO 2 DO
				BEGIN
				aVMArray := NewVMArray (doc.fRows, doc.fCols, 3 - channel);
				doc.fData [channel] := aVMArray
				END

			END

		END;

	CatchFailures (fi, CleanUp);

	SeekTo (pictStart);

	ParsePICT (doc, canAbort);

	Success (fi);

	GOTO 3;

	2:	{ Use QuickDraw to parse PICT }

	SeekTo (pictStart);

	doc.fRows := bounds.bottom - bounds.top;
	doc.fCols := bounds.right  - bounds.left;

	doc.FreeData;
	doc.fReverting := reverting;

	IF version = 1 THEN
		BEGIN

		IF depth <> 1 THEN Failure (errBadPICT - 7, 0);

		doc.fMode  := HalftoneMode;
		doc.fDepth := 1;

		rowBytes := BSL (BSR (doc.fCols + 15, 4), 1);

		aVMArray := NewVMArray (doc.fRows, rowBytes, 1);

		doc.fData [0] := aVMArray;

		ParseOldPICT (doc)

		END

	ELSE IF gConfiguration.hasColorToolbox THEN
		BEGIN

		doc.fMode := IndexedColorMode;

		aVMArray := NewVMArray (doc.fRows, doc.fCols, 1);

		doc.fData [0] := aVMArray;

		sysTable := HRGBLookUpTable (GetResource ('PLUT', 1000));
		FailNil (sysTable);

		doc.fIndexedColorTable := sysTable^^;

		ParseNewPICT (doc);

		TestForMonochrome (doc);
		TestForHalftone (doc);

		IF doc.fMode <> MonochromeMode THEN EXIT (DoReadPICT);

		doc.fMode := IndexedColorMode;

		doc.fIndexedColorTable.R := gInvertLUT;
		doc.fIndexedColorTable.G := gInvertLUT;
		doc.fIndexedColorTable.B := gInvertLUT;

		SeekTo (pictStart);

		ParseNewPICT (doc)

		END

	ELSE
		Failure (errPICTTooComplex, 0);

	3:	{ Success }

	TestForMonochrome (doc)

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TPICTFileFormat.DoRead (doc: TImageDocument;
								  refNum: INTEGER;
								  rsrcExists: BOOLEAN); OVERRIDE;

	BEGIN

	fRefNum := refNum;

	SkipBytes (512);

	DoReadPICT (doc, NOT doc.fReverting)

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TPICTFileFormat.PutOpcode (opcode: INTEGER);

	BEGIN

	IF fVersion1 THEN
		PutByte (opcode)

	ELSE
		BEGIN
		IF ODD (GetFilePosition) THEN PutByte (0);
		PutWord (opcode)
		END

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TPICTFileFormat.DoWritePICT (doc: TImageDocument);

	VAR
		r: Rect;
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		bounds: Rect;
		res: EXTENDED;
		size: INTEGER;
		srcRect: Rect;
		dstRect: Rect;
		buffer: Handle;
		channel: INTEGER;
		maxRows: INTEGER;
		rowBytes: LONGINT;
		rowBlock: INTEGER;
		pictSize: LONGINT;
		saveAlpha: BOOLEAN;
		maxPackSize: INTEGER;
		startPosition: LONGINT;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		FreeLargeHandle (buffer);

		IF gTables.fColorTable <> NIL THEN
			HUnlock (Handle (gTables.fColorTable))

		END;

	BEGIN

	startPosition := GetFilePosition;

	IF doc.fMode = RGBColorMode THEN
		channel := kRGBChannels
	ELSE
		channel := 0;

	saveAlpha := (gTables.fDepth = 32) AND
				 (channel = kRGBChannels) AND
				 (doc.fChannels > 3);

	res := doc.fStyleInfo.fResolution.value / (72 * $10000);

	bounds.topLeft := Point (0);
	bounds.right   := Max (1, Min (kMaxCoord, ROUND (doc.fCols / res)));
	bounds.bottom  := Max (1, Min (kMaxCoord, ROUND (doc.fRows / res)));

	fVersion1 := (gTables.fDepth = 1) AND
				 (doc.fCols = bounds.right) AND
				 (doc.fRows = bounds.bottom);

	PutWord (0);				{ LoWrd (pictSize) }
	PutBytes (8, @bounds);

	IF fVersion1 THEN
		BEGIN
		PutOpcode ($11);
		PutByte ($01)
		END

	ELSE
		BEGIN

		PutOpcode ($11);
		PutWord ($02FF);

		PutOpcode ($0C00);
		PutLong (0);			{ pictSize }
		PutLong (0);
		PutLong (0);
		PutWord (bounds.bottom);
		PutWord (0);
		PutWord (bounds.right);
		PutWord (0);
		PutLong (0)

		END;

	PutOpcode ($1);
	PutWord (10);
	PutBytes (8, @bounds);

	IF fVersion1 THEN
		BEGIN
		PutOpcode ($A0);
		PutWord (130);
		PutOpcode ($A0);
		PutWord (142)
		END;

	rowBytes := gTables.CompRowBytes (doc.fCols);

	IF rowBytes > $7FFF THEN Failure (errPICTTooWide, 0);

	SetRect (r, 0, 0, doc.fCols, 1);

	maxPackSize := rowBytes + (rowBytes + 126) DIV 127;

	buffer := NewLargeHandle (Max (gTables.BufferSize (r),
								   rowBytes + maxPackSize));

	CatchFailures (fi, CleanUp);

	HLock (buffer);

	IF gTables.fColorTable <> NIL THEN
		HLock (Handle (gTables.fColorTable));

	IF fVersion1 THEN
		maxRows := (3 * 1024) DIV rowBytes
	ELSE
		maxRows := doc.fRows;

	maxRows := Max (1, Min (maxRows, doc.fRows));

	FOR rowBlock := 0 TO (doc.fRows - 1) DIV maxRows DO
		BEGIN

		srcRect.left   := 0;
		srcRect.right  := doc.fCols;
		srcRect.top    := rowBlock * maxRows;
		srcRect.bottom := Min (srcRect.top + maxRows, doc.fRows);

		IF fVersion1 THEN
			dstRect := srcRect
		ELSE
			dstRect := bounds;

		IF gTables.fDepth > 8 THEN
			BEGIN
			PutOpcode ($9A);
			PutLong ($FF)
			END
		ELSE IF rowBytes < 8 THEN
			PutOpcode ($90)
		ELSE
			PutOpcode ($98);

		IF fVersion1 THEN
			PutWord (rowBytes)
		ELSE
			PutWord (BOR ($8000, rowBytes));

		PutBytes (8, @srcRect);

		IF NOT fVersion1 THEN
			BEGIN

			PutWord (0);

			IF gTables.fDepth = 32 THEN
				IF rowBytes < 8 THEN
					PutWord (1)
				ELSE
					PutWord (4)
			ELSE IF gTables.fDepth = 16 THEN
				IF rowBytes < 8 THEN
					PutWord (1)
				ELSE
					PutWord (3)
			ELSE
				PutWord (0);

			PutLong (0);
			PutLong (doc.fStyleInfo.fResolution.value);
			PutLong (doc.fStyleInfo.fResolution.value);

			IF gTables.fDepth = 32 THEN
				BEGIN
				PutWord (RGBDirect);
				PutWord (32);
				IF saveAlpha THEN
					PutWord (4)
				ELSE
					PutWord (3);
				PutWord (8)
				END
			ELSE IF gTables.fDepth = 16 THEN
				BEGIN
				PutWord (RGBDirect);
				PutWord (16);
				PutWord (3);
				PutWord (5)
				END
			ELSE
				BEGIN
				PutWord (0);
				PutWord (gTables.fDepth);
				PutWord (1);
				PutWord (gTables.fDepth)
				END;

			PutLong (0);
			PutLong (0);
			PutLong (0);

			IF gTables.fDepth <= 8 THEN
				BEGIN

				PutLong (0);
				PutWord (0);

				IF gTables.fDepth = 1 THEN
					BEGIN
					PutWord (1);
					PutWord (0);
					PutWord ($FFFF);
					PutWord ($FFFF);
					PutWord ($FFFF);
					PutWord (1);
					PutWord (0);
					PutWord (0);
					PutWord (0)
					END

				ELSE
					BEGIN
					PutWord (gTables.fColorTable^^.ctSize);
					PutBytes (8 * (gTables.fColorTable^^.ctSize + 1),
							  @gTables.fColorTable^^.ctTable)
					END

				END

			END;

		PutBytes (8, @srcRect);
		PutBytes (8, @dstRect);

		IF (gTables.fDepth > 8) AND (fTransferMode = srcCopy) THEN
			PutWord (ditherCopy)
		ELSE
			PutWord (fTransferMode);

		FOR row := srcRect.top TO srcRect.bottom - 1 DO
			BEGIN

			UpdateProgress (row, doc.fRows);

			r		 := srcRect;
			r.top	 := row;
			r.bottom := row + 1;

			gTables.DitherRect (doc, channel, 1, r, buffer^, TRUE);

			IF saveAlpha THEN
				BEGIN

				srcPtr := doc.fData [3] . NeedPtr (row, row, FALSE);

				DoStepCopyBytes (srcPtr, buffer^, doc.fCols, 1, 4);

				doc.fData [3] . DoneWithPtr;
				doc.fData [3] . Flush

				END;

			IF rowBytes < 8 THEN
				PutBytes (rowBytes, buffer^)

			ELSE IF gTables.fDepth = 32 THEN
				BEGIN

				dstPtr := Ptr (ORD4 (buffer^) + maxPackSize);
				srcPtr := dstPtr;

				IF saveAlpha THEN
					BEGIN
					DoStepCopyBytes (buffer^,
									 dstPtr,
									 doc.fCols, 4, 1);
					dstPtr := Ptr (ORD4 (dstPtr) + doc.fCols)
					END;

				DoStepCopyBytes (Ptr (ORD4 (buffer^) + 1),
								 dstPtr,
								 doc.fCols, 4, 1);

				DoStepCopyBytes (Ptr (ORD4 (buffer^) + 2),
								 Ptr (ORD4 (dstPtr) + doc.fCols),
								 doc.fCols, 4, 1);

				DoStepCopyBytes (Ptr (ORD4 (buffer^) + 3),
								 Ptr (ORD4 (dstPtr) + 2 * doc.fCols),
								 doc.fCols, 4, 1);

				dstPtr := buffer^;

				IF saveAlpha THEN
					MyPackBits (srcPtr, dstPtr, 4 * doc.fCols)
				ELSE
					MyPackBits (srcPtr, dstPtr, 3 * doc.fCols);

				size := LoWrd (ORD4 (dstPtr) - ORD4 (buffer^));

				IF rowBytes > 250 THEN
					PutWord (size)
				ELSE
					PutByte (size);

				PutBytes (size, buffer^)

				END

			ELSE IF gTables.fDepth = 16 THEN
				BEGIN

				srcPtr := buffer^;
				dstPtr := Ptr (ORD4 (buffer^) + rowBytes);

				PackWords (srcPtr, dstPtr, doc.fCols);

				size := LoWrd (ORD4 (dstPtr) - ORD4 (srcPtr));

				IF rowBytes > 250 THEN
					PutWord (size)
				ELSE
					PutByte (size);

				PutBytes (size, srcPtr)

				END

			ELSE
				BEGIN

				srcPtr := buffer^;
				dstPtr := Ptr (ORD4 (srcPtr) + rowBytes);

				MyPackBits (srcPtr, dstPtr, rowBytes);

				size := LoWrd (ORD4 (dstPtr) - ORD4 (srcPtr));

				IF rowBytes > 250 THEN
					PutWord (size)
				ELSE
					PutByte (size);

				PutBytes (size, srcPtr)

				END

			END

		END;

	UpdateProgress (1, 1);

	IF fVersion1 THEN
		BEGIN
		PutOpcode ($A0);
		PutWord (143);
		PutOpcode ($A0);
		PutWord (131)
		END;

	PutOpcode ($FF);

	pictSize := GetFilePosition - startPosition;

	SeekTo (startPosition);
	PutWord (LoWord (pictSize));

	IF NOT fVersion1 THEN
		BEGIN
		SeekTo (startPosition + 16);
		PutLong (pictSize)
		END;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TPICTFileFormat.AddPixelPaintStuff;

	TYPE

		TPixelPaint = RECORD
			size: INTEGER;
			rgb: ARRAY [0..255] OF RGBColor
			END;

		PPixelPaint = ^TPixelPaint;
		HPixelPaint = ^PPixelPaint;

	VAR
		j: INTEGER;
		err: OSErr;
		black: RGBColor;
		clut: CTabHandle;
		pixelPaint: HPixelPaint;

	BEGIN

	clut := gTables.fColorTable;

	IF gTables.fDepth = 8 THEN
		BEGIN

		pixelPaint := HPixelPaint (NewHandle (SIZEOF (TPixelPaint)));
		FailMemError;

		pixelPaint^^.size := 255;

		black.red	:= 0;
		black.green := 0;
		black.blue	:= 0;

		{$PUSH}
		{$R-}

		FOR j := 0 TO clut^^.ctSize DO
			pixelPaint^^.rgb [j] := clut^^.ctTable [j] . rgb;

		FOR j := clut^^.ctSize + 1 TO 255 DO
			pixelPaint^^.rgb [j] := black;

		{$POP}

		AddResource (Handle (pixelPaint), 'COLR', 999, '');
		err := ResError;

		IF err <> 0 THEN
			BEGIN
			DisposHandle (Handle (pixelPaint));
			FailOSErr (err)
			END

		END;

	FailOSErr (HandToHand (Handle (clut)));

	AddResource (Handle (clut), 'clut', 999, '');
	err := ResError;

	IF err <> 0 THEN
		BEGIN
		DisposHandle (Handle (clut));
		FailOSErr (err)
		END

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TPICTFileFormat.DoWrite
		(doc: TImageDocument; refNum: INTEGER); OVERRIDE;

	VAR
		channel: INTEGER;

	BEGIN

	MoveHands (FALSE);

	fRefNum := refNum;

	IF doc.fMode = RGBColorMode THEN
		channel := kRGBChannels
	ELSE
		channel := 0;

	gTables.CompTables (doc, channel, FALSE, fSystemPalette,
						fDepth, fDepth, TRUE, TRUE, 1);

	PutZeros (512);

	DoWritePICT (doc);

	IF gTables.fColorTable <> NIL THEN
		AddPixelPaintStuff

	END;

{Photoshop version 1.0.1, file: UGIFFormat.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}
{$I UGIFFormat.a.inc}

VAR
	gifOutPtr: Ptr;
	gifRow: INTEGER;
	gifCol: INTEGER;
	gifRows: INTEGER;
	gifCols: INTEGER;
	gifScan: INTEGER;
	gifArray: TVMArray;
	gifBaseRow: INTEGER;
	gifBaseCol: INTEGER;

{*****************************************************************************}

{$S AInit}

PROCEDURE TGIFFormat.IImageFormat; OVERRIDE;

	BEGIN

	INHERITED IImageFormat;

	fCanRead	  := TRUE;
	fReadType1	  := 'GIFf';
	fReadType2	  := 'GIF ';
	fFileType	  := 'GIFf';
	fUsesDataFork := TRUE;

	fDialogID	   := 2500;
	fRadioClusters := 1;
	fRadio1Item    := 4;
	fRadio1Count   := 8;

	fLSBFirst := TRUE

	END;

{*****************************************************************************}

{$S AWriteFile}

FUNCTION TGIFFormat.CanWrite (doc: TImageDocument): BOOLEAN; OVERRIDE;

	BEGIN

	CanWrite := (doc.fMode IN [HalftoneMode,
							   MonochromeMode,
							   IndexedColorMode,
							   MultichannelMode]) AND
				(doc.fRows <= 16383) AND
				(doc.fCols <= 16383)

	END;

{*****************************************************************************}

{$S AGIFFormat}

PROCEDURE TGIFFormat.SetFormatOptions (doc: TImageDocument); OVERRIDE;

	BEGIN

	gTables.CompTables (doc, 0, FALSE, FALSE, 8, 8, FALSE, TRUE, 1);

	fDepth := gTables.fResolution;

	fRadio1 := fDepth - 1;

	DoOptionsDialog;

	fDepth := fRadio1 + 1

	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S AGIFFormat}

PROCEDURE TGIFFormat.ReadRaster (canAbort: BOOLEAN);

	VAR
		fi: FailInfo;
		rows: INTEGER;
		bitsUsed: LONGINT;
		bufferCount: INTEGER;
		buffer: PACKED ARRAY [0..257] OF SignedByte;

	FUNCTION GetCodeWord: INTEGER;

		BEGIN

		IF bitsUsed + lzwWordSize > BSL (bufferCount, 3) THEN
			BEGIN

			buffer [0] := buffer [bufferCount];
			buffer [1] := buffer [bufferCount + 1];

			bitsUsed := bitsUsed - BSL (bufferCount, 3);

			bufferCount := GetByte;

			IF bufferCount <= 0 THEN Failure (errBadGIF - 1, 0);

			GetBytes (bufferCount, @buffer [2])

			END;

		GetCodeWord := ExtractGIF (@buffer, bitsUsed + 16, lzwWordSize);

		bitsUsed := bitsUsed + lzwWordSize

		END;

	PROCEDURE PutData (pixel: INTEGER);

		BEGIN

		IF gifOutPtr = NIL THEN
			BEGIN

			MoveHands (canAbort);

			UpdateProgress (rows, gifRows);
			rows := rows + 1;

			IF gifRow >= gifRows THEN Failure (errBadGIF - 2, 0);

			gifOutPtr := gifArray.NeedPtr (gifBaseRow + gifRow,
										   gifBaseRow + gifRow, TRUE);

			gifOutPtr := Ptr (ORD4 (gifOutPtr) + gifBaseCol)

			END;

		{$PUSH}
		{$R-}

		gifOutPtr^ := pixel;

		{$POP}

		gifOutPtr := Ptr (ORD4 (gifOutPtr) + 1);

		gifCol := gifCol + 1;

		IF gifCol = gifCols THEN
			BEGIN

			gifArray.DoneWithPtr;

			gifOutPtr := NIL;

			gifCol := 0;

				CASE gifScan OF
				0:		gifRow := gifRow + 1;
				1, 2:	gifRow := gifRow + 8;
				3:		gifRow := gifRow + 4;
				4:		gifRow := gifRow + 2
				END;

			WHILE gifRow >= gifRows DO
				BEGIN

					CASE gifScan OF

					1:	gifRow := 4;
					2:	gifRow := 2;
					3:	gifRow := 1;

					OTHERWISE
						EXIT (PutData)

					END;

				gifScan := gifScan + 1

				END

			END

		END;
		
	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF (error <> 0) AND (gifRow >= gifRows) THEN
			EXIT (ReadRaster)
		END;

	BEGIN

	rows := 0;

	bitsUsed := 0;
	bufferCount := 0;
	
	CatchFailures (fi, CleanUp);

	LZWExpand (GetByte, errBadGIF, GetCodeWord, PutData, FALSE);
	
	Success (fi);

	UpdateProgress (1, 1)

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S AGIFFormat}

PROCEDURE TGIFFormat.DoRead (doc: TImageDocument;
							 refNum: INTEGER;
							 rsrcExists: BOOLEAN); OVERRIDE;

	VAR
		info: INTEGER;
		depth: INTEGER;
		count: INTEGER;
		opcode: INTEGER;
		signature: PACKED ARRAY [0..5] OF CHAR;

	PROCEDURE ReadCLUT (res: INTEGER);

		VAR
			gray: INTEGER;

		BEGIN

		FOR gray := 0 TO BSL (1, res) - 1 DO
			BEGIN
			doc.fIndexedColorTable.R [gray] := CHR (GetByte);
			doc.fIndexedColorTable.G [gray] := CHR (GetByte);
			doc.fIndexedColorTable.B [gray] := CHR (GetByte)
			END

		END;

	BEGIN

	fRefNum := refNum;

	MoveHands (NOT doc.fReverting);

	GetBytes (6, @signature);

	IF signature <> 'GIF87a' THEN Failure (errBadGIF - 3, 0);

	doc.fCols := GetWord;
	doc.fRows := GetWord;

	doc.fMode := IndexedColorMode;

	IF NOT doc.ValidSize THEN Failure (errBadGIF - 4, 0);

	gifArray := NewVMArray (doc.fRows, doc.fCols, 1);

	doc.fData [0] := gifArray;

	info := GetByte;

	depth := BAND (info, 7) + 1;

	gifArray.SetBytes (GetByte);

	IF GetByte <> 0 THEN Failure (errBadGIF - 5, 0);

	DoSetBytes (@doc.fIndexedColorTable, SIZEOF (TRGBLookUpTable), 0);

	IF BTST (info, 7) THEN ReadCLUT (BAND (info, 7) + 1);

		REPEAT

		opcode := GetByte;

			CASE CHR (opcode) OF

			'!':
				BEGIN

				SkipBytes (1);

					REPEAT
					count := GetByte;
					SkipBytes (count)
					UNTIL count = 0

				END;

			',':
				BEGIN

				gifBaseCol := GetWord;
				gifBaseRow := GetWord;
				gifCols    := GetWord;
				gifRows    := GetWord;

				IF (gifBaseCol			 <	0		 ) OR
				   (gifCols 			 <= 0		 ) OR
				   (gifBaseCol + gifCols >	doc.fCols) OR
				   (gifBaseRow			 <	0		 ) OR
				   (gifRows 			 <= 0		 ) OR
				   (gifBaseRow + gifRows >	doc.fRows) THEN
					Failure (errBadGIF - 6, 0);

				gifCol := 0;
				gifRow := 0;

				info := GetByte;

				gifScan := ORD (BTST (info, 6));

				IF BTST (info, 7) THEN
					ReadCLUT (BAND (info, 7) + 1);

				gifOutPtr := NIL;

				ReadRaster (NOT doc.fReverting);

				IF gifRow < gifRows THEN Failure (errBadGIF - 7, 0)

				END

			END

		UNTIL CHR (opcode) = ';';

	TestForMonochrome (doc);

	IF depth = 1 THEN
		TestForHalftone (doc)

	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S AGIFFormat}

PROCEDURE TGIFFormat.WriteRaster (doc: TImageDocument);

	VAR
		r: Rect;
		count: INTEGER;
		column: INTEGER;
		codeSize: INTEGER;
		bitsUsed: LONGINT;
		buffer: PACKED ARRAY [0..257] OF SignedByte;

	FUNCTION GetData (VAR pixel: INTEGER): BOOLEAN;

		BEGIN

		IF column = 0 THEN
			BEGIN

			UpdateProgress (r.top, doc.fRows);

			IF r.top = doc.fRows THEN
				BEGIN
				GetData := FALSE;
				EXIT (GetData)
				END;

			gTables.DitherRect (doc, 0, 1, r, gBuffer, TRUE);

			OffsetRect (r, 0, 1)

			END;

		pixel := BAND ($FF, Ptr (ORD4 (gBuffer) + column)^);

		IF column = doc.fCols - 1 THEN
			column := 0
		ELSE
			column := column + 1;

		GetData := TRUE

		END;

	PROCEDURE PutCodeWord (code: INTEGER);

		BEGIN

		StuffGIF (@buffer, bitsUsed, code);

		bitsUsed := bitsUsed + lzwWordSize;

		IF bitsUsed >= 2040 THEN
			BEGIN

			PutByte (255);
			PutBytes (255, @buffer);

			buffer [0] := buffer [255];
			buffer [1] := buffer [256];

			DoSetBytes (@buffer [2], 255, 0);

			bitsUsed := bitsUsed - 2040

			END

		END;

	BEGIN

	SetRect (r, 0, 0, doc.fCols, 1);
	column := 0;

	bitsUsed := 0;
	DoSetBytes (@buffer, 257, 0);

	codeSize := Max (2, fDepth);

	PutByte (codeSize);

	LZWCompress (codeSize, GetData, PutCodeWord, FALSE);

	count := BSR (bitsUsed + 7, 3);

	IF count > 0 THEN
		BEGIN
		PutByte (count);
		PutBytes (count, @buffer)
		END

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S AGIFFormat}

PROCEDURE TGIFFormat.DoWrite (doc: TImageDocument; refNum: INTEGER); OVERRIDE;

	VAR
		index: INTEGER;
		color: RGBColor;
		signature: PACKED ARRAY [0..5] OF CHAR;

	BEGIN

	fRefNum := refNum;

	MoveHands (FALSE);

	gTables.CompTables (doc, 0, FALSE, FALSE, 8, fDepth, FALSE, FALSE, 1);

	signature := 'GIF87a';
	PutBytes (6, @signature);

	PutWord (doc.fCols);
	PutWord (doc.fRows);

	PutByte ($80 + BSL (fDepth - 1, 4) + fDepth - 1);

	PutWord (0);

	FOR index := 0 TO gTables.fColorTable^^.ctSize DO
		BEGIN

		{$PUSH}
		{$R-}
		color := gTables.fColorTable^^.ctTable [index] . rgb;
		{$POP}

		PutByte (BSR (color.red  , 8));
		PutByte (BSR (color.green, 8));
		PutByte (BSR (color.blue , 8))

		END;

	FOR index := gTables.fColorTable^^.ctSize + 1 TO BSL (1, fDepth) - 1 DO
		BEGIN
		PutByte (0);
		PutByte (0);
		PutByte (0)
		END;

	PutByte (ORD (','));

	PutWord (0);
	PutWord (0);
	PutWord (doc.fCols);
	PutWord (doc.fRows);

	PutByte (fDepth - 1);

	WriteRaster (doc);

	PutByte (0);

	PutByte (ORD (';'))

	END;

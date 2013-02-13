{Photoshop version 1.0.1, file: UScitexFormat.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$S AInit}

PROCEDURE TScitexFormat.IImageFormat; OVERRIDE;

	BEGIN

	INHERITED IImageFormat;

	fCanRead	  := TRUE;
	fReadType1	  := '..CT';
	fFileType	  := '..CT';
	fUsesDataFork := TRUE

	END;

{*****************************************************************************}

{$S AWriteFile}

FUNCTION TScitexFormat.CanWrite (doc: TImageDocument): BOOLEAN; OVERRIDE;

	BEGIN
	CanWrite := doc.fMode IN [MonochromeMode,
							  SeparationsCMYK,
							  MultichannelMode]
	END;

{*****************************************************************************}

{$S AScitexFormat}

PROCEDURE TScitexFormat.DoRead (doc: TImageDocument;
								refNum: INTEGER;
								rsrcExists: BOOLEAN); OVERRIDE;

	VAR
		dstPtr: Ptr;
		row: INTEGER;
		res: EXTENDED;
		units: INTEGER;
		width: EXTENDED;
		height: EXTENDED;
		channel: INTEGER;
		aVMArray: TVMArray;

	FUNCTION ParseInteger (digits: INTEGER; period: BOOLEAN): LONGINT;

		VAR
			d: INTEGER;
			x: LONGINT;
			sign: INTEGER;
			digit: INTEGER;

		BEGIN

			CASE CHR (GetByte) OF

			'+':
				sign := 1;

			'-':
				sign := -1;

			OTHERWISE
				Failure (errBadScitex, 0)

			END;

		IF period THEN
			IF GetByte <> ORD ('.') THEN
				Failure (errBadScitex, 0);

		x := 0;

		FOR digit := 1 TO digits DO
			BEGIN

			d := GetByte - ORD ('0');

			IF (d < 0) OR (d > 9) THEN Failure (errBadScitex, 0);

			x := x * 10 + d

			END;

		ParseInteger := sign * x

		END;

	FUNCTION ParseReal: EXTENDED;

		VAR
			y: INTEGER;
			x: EXTENDED;

		BEGIN

		x := ParseInteger (8, TRUE) / 100000000;

		IF GetByte <> ORD ('E') THEN Failure (errBadScitex, 0);

		y := ParseInteger (2, FALSE);

		WHILE y > 0 DO
			BEGIN
			x := x * 10;
			y := y - 1
			END;

		WHILE y < 0 DO
			BEGIN
			x := x / 10;
			y := y + 1
			END;

		ParseReal := x

		END;

	BEGIN

	fRefNum := refNum;

	SkipBytes (1024);

	units := GetByte;

	IF (units < 0) OR (units > 1) THEN
		Failure (errBadScitex, 0);

	doc.fChannels := GetByte;

		CASE doc.fChannels OF

		1:	doc.fMode := MonochromeMode;

		3:	doc.fMode := RGBColorMode;

		OTHERWISE
			doc.fMode := SeparationsCMYK

		END;

	SkipBytes (2);

	height := ParseReal;
	width  := ParseReal;

	IF (height <= 0) OR (width <= 0) THEN Failure (errBadScitex, 0);

	doc.fRows := ParseInteger (11, FALSE);
	doc.fCols := ParseInteger (11, FALSE);

	IF NOT doc.ValidSize THEN Failure (errBadScitex, 0);

	IF units = 0 THEN
		BEGIN
		height := height / 25.4;
		width  := width  / 25.4
		END;

	IF doc.fCols >= doc.fRows THEN
		res := doc.fCols / width
	ELSE
		res := doc.fRows / height;

	IF (res >= 1) AND (res <= 3200) THEN
		WITH doc.fStyleInfo DO
			BEGIN

			fResolution.value := ROUND (res * $10000);

			IF units = 0 THEN
				BEGIN
				fResolution.scale := 2;
				fWidthUnit		  := 2;
				fHeightUnit 	  := 2
				END

			END;

	SeekTo (2048);

	FOR channel := 0 TO doc.fChannels - 1 DO
		BEGIN
		aVMArray := NewVMArray (doc.fRows,
								doc.fCols,
								doc.Interleave (channel));
		doc.fData [channel] := aVMArray
		END;

	FOR row := 0 TO doc.fRows - 1 DO
		BEGIN

		UpdateProgress (row, doc.fRows);

		FOR channel := 0 TO doc.fChannels - 1 DO
			BEGIN

			MoveHands (NOT doc.fReverting);

			dstPtr := doc.fData [channel] . NeedPtr (row, row, TRUE);

			GetBytes (doc.fCols, dstPtr);

			doc.fData [channel] . DoneWithPtr;

			IF ODD (doc.fCols) THEN
				SkipBytes (1)

			END

		END;

	UpdateProgress (1, 1);

	FOR channel := 0 TO doc.fChannels - 1 DO
		doc.fData [channel] . Flush

	END;

{*****************************************************************************}

{$S AScitexFormat}

FUNCTION TScitexFormat.DataForkBytes (doc: TImageDocument): LONGINT; OVERRIDE;

	BEGIN

	IF doc.fMode = SeparationsCMYK THEN
		DataForkBytes := 2048 + ORD4 (doc.fRows) * doc.fCols * 4
	ELSE
		DataForkBytes := 2048 + ORD4 (doc.fRows) * doc.fCols

	END;

{*****************************************************************************}

{$S AScitexFormat}

PROCEDURE TScitexFormat.DoWrite (doc: TImageDocument;
								 refNum: INTEGER); OVERRIDE;

	VAR
		j: INTEGER;
		srcPtr: Ptr;
		name: Str255;
		row: INTEGER;
		units: INTEGER;
		channel: INTEGER;
		channels: INTEGER;

	PROCEDURE PutSideSize (pixels: INTEGER);

		VAR
			j: INTEGER;
			y: INTEGER;
			x: EXTENDED;

		BEGIN

		x := pixels / (doc.fStyleInfo.fResolution.value / $10000);

		IF units = 0 THEN x := x * 25.4;

		y := 0;

		WHILE x >= 1 DO
			BEGIN
			x := x / 10;
			y := y + 1
			END;

		WHILE x < 0.1 DO
			BEGIN
			x := x * 10;
			y := y - 1
			END;

		PutByte (ORD ('+'));
		PutByte (ORD ('.'));

		FOR j := 1 TO 8 DO
			BEGIN
			x := x * 10;
			PutByte (ORD ('0') + TRUNC (x));
			x := x - TRUNC (x)
			END;

		PutByte (ORD ('E'));

		IF y >= 0 THEN
			PutByte (ORD ('+'))
		ELSE
			PutByte (ORD ('-'));

		y := ABS (y);

		PutByte (ORD ('0') + y DIV 10);
		PutByte (ORD ('0') + y MOD 10)

		END;

	PROCEDURE PutSideCount (pixels: INTEGER);

		VAR
			j: INTEGER;

		BEGIN

		PutByte (ORD ('+'));

		FOR j := 1 TO 6 DO
			PutByte (ORD ('0'));

		PutByte (ORD ('0') + pixels DIV 10000);
		PutByte (ORD ('0') + pixels DIV 1000 MOD 10);
		PutByte (ORD ('0') + pixels DIV 100 MOD 10);
		PutByte (ORD ('0') + pixels DIV 10 MOD 10);
		PutByte (ORD ('0') + pixels MOD 10)

		END;

	BEGIN

	fRefNum := refNum;

	MoveHands (FALSE);

	name := gReply.fName;

	PutBytes (LENGTH (name), @name[1]);

	FOR j := LENGTH (name) + 1 TO 80 DO
		PutByte (ORD (' '));

	PutByte (ORD ('C'));
	PutByte (ORD ('T'));

	PutZeros (1024 - 82);

	IF doc.fStyleInfo.fResolution.scale = 2 THEN
		units := 0
	ELSE
		units := 1;

	PutByte (units);

	IF doc.fMode = SeparationsCMYK THEN
		channels := 4
	ELSE
		channels := 1;

	PutByte (channels);

	IF channels = 4 THEN
		PutWord ($0F)
	ELSE
		PutWord ($08);

	PutSideSize (doc.fRows);
	PutSideSize (doc.fCols);

	PutSideCount (doc.fRows);
	PutSideCount (doc.fCols);

	PutZeros (1024 - 56);

	FOR row := 0 TO doc.fRows - 1 DO
		BEGIN

		UpdateProgress (row, doc.fRows);

		FOR channel := 0 TO channels - 1 DO
			BEGIN

			MoveHands (FALSE);

			srcPtr := doc.fData [channel] . NeedPtr (row, row, FALSE);

			PutBytes (doc.fCols, srcPtr);

			doc.fData [channel] . DoneWithPtr;

			IF ODD (doc.fCols) THEN
				PutByte (0);

			END

		END;

	UpdateProgress (1, 1);

	FOR channel := 0 TO channels - 1 DO
		doc.fData [channel] . Flush

	END;

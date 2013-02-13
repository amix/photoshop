{Photoshop version 1.0.1, file: ULZWCompress.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}

TYPE
	TLZWTable = ARRAY [0..4095] OF
		RECORD
		prefix	: INTEGER;
		final	: INTEGER;
		son 	: INTEGER;
		brother : INTEGER
		END;

	PLZWTable = ^TLZWTable;

VAR
	lzwTable: PLZWTable;
	lzwNextCode: INTEGER;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ALZWCompress}

PROCEDURE InitLZWTable (codeSize: INTEGER);

	VAR
		code: INTEGER;

	BEGIN

	lzwWordSize := codeSize + 1;

	lzwNextCode := BSL (1, codeSize) + 2;

	FOR code := 0 TO lzwNextCode - 3 DO
		WITH lzwTable^ [code] DO
			BEGIN
			prefix	:= -1;
			final	:= code;
			son 	:= -1;
			brother := -1
			END

	END;

{*****************************************************************************}

{$S ALZWCompress}

FUNCTION SearchLZWTable (w, k: INTEGER): INTEGER;

	VAR
		code: INTEGER;

	BEGIN

	code := lzwTable^ [w] . son;

	WHILE code <> -1 DO
		WITH lzwTable^ [code] DO
			BEGIN

			IF final = k THEN
				BEGIN
				SearchLZWTable := code;
				EXIT (SearchLZWTable)
				END;

			code := brother

			END;

	SearchLZWTable := -1

	END;

{*****************************************************************************}

{$S ALZWCompress}

PROCEDURE AddLZWTable (w, k: INTEGER; reading, tiff: BOOLEAN);

	VAR
		oldSon: INTEGER;

	BEGIN

	WITH lzwTable^ [w] DO
		BEGIN
		oldSon := son;
		son    := lzwNextCode
		END;

	WITH lzwTable^ [lzwNextCode] DO
		BEGIN
		prefix	:= w;
		final	:= k;
		son 	:= -1;
		brother := oldSon
		END;

	IF reading THEN lzwNextCode := lzwNextCode + 1;

	IF lzwNextCode = BSL (1, lzwWordSize) - ORD (tiff) THEN
		lzwWordSize := Min (lzwWordSize + 1, 12);

	IF NOT reading THEN lzwNextCode := lzwNextCode + 1

	END;

{*****************************************************************************}

{$S ALZWCompress}

PROCEDURE LZWCompress (codeSize: INTEGER;
					   FUNCTION GetData (VAR pixel: INTEGER): BOOLEAN;
					   PROCEDURE PutCodeWord (code: INTEGER);
					   tiff: BOOLEAN);

	VAR
		fi: FailInfo;
		code: INTEGER;
		pixel: INTEGER;
		buffer: Handle;
		newCode: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (buffer)
		END;

	BEGIN

	buffer := NewLargeHandle (32768);
	HLock (buffer);

	CatchFailures (fi, CleanUp);

	lzwTable := PLZWTable (buffer^);

	InitLZWTable (codeSize);

	PutCodeWord (BSL (1, codeSize));

	code := -1;

	WHILE GetData (pixel) DO
		BEGIN

		IF code = -1 THEN
			code := pixel

		ELSE
			BEGIN

			newCode := SearchLZWTable (code, pixel);

			IF newCode = -1 THEN
				BEGIN

				PutCodeWord (code);

				IF lzwNextCode < 4093 THEN
					AddLZWTable (code, pixel, FALSE, tiff)

				ELSE
					BEGIN
					PutCodeWord (BSL (1, codeSize));
					InitLZWTable (codeSize)
					END;

				code := pixel

				END

			ELSE
				code := newCode

			END

		END;

	IF code <> -1 THEN
		BEGIN
		PutCodeWord (code);
		AddLZWTable (code, 0, FALSE, tiff)
		END;

	PutCodeWord (BSL (1, codeSize) + 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ALZWCompress}

PROCEDURE LZWExpand (codeSize: INTEGER;
					 errorCode: INTEGER;
					 FUNCTION GetCodeWord: INTEGER;
					 PROCEDURE PutData (pixel: INTEGER);
					 tiff: BOOLEAN);

	LABEL
		1, 2;

	VAR
		fi: FailInfo;
		code: INTEGER;
		count: INTEGER;
		buffer: Handle;
		inCode: INTEGER;
		endCode: INTEGER;
		oldCode: INTEGER;
		finChar: INTEGER;
		bitsUsed: LONGINT;
		resetCode: INTEGER;
		stack: PACKED ARRAY [0..4095] OF CHAR;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (buffer)
		END;

	BEGIN

	buffer := NewLargeHandle (32768);
	HLock (buffer);

	CatchFailures (fi, CleanUp);

	lzwTable := PLZWTable (buffer^);

	resetCode := BSL (1, codeSize);
	endCode   := resetCode + 1;

	1: InitLZWTable (codeSize);

	code := GetCodeWord;

	IF code = resetCode THEN GOTO 1;
	IF code = endCode	THEN GOTO 2;

	IF code > endCode THEN
		Failure (errorCode, 0);

	oldCode := code;
	finChar := code;

	PutData (code);

		REPEAT

		code := GetCodeWord;

		IF code = resetCode THEN GOTO 1;
		IF code = endCode	THEN GOTO 2;

		inCode := code;

		count := 0;

		IF code >= lzwNextCode THEN
			BEGIN

			IF code <> lzwNextCode THEN
				Failure (errorCode, 0);

			stack [0] := CHR (finChar);
			count := 1;

			code := oldCode

			END;

		WHILE code >= resetCode DO
			WITH lzwTable^ [code] DO
				BEGIN
				stack [count] := CHR (final);
				count := count + 1;
				code := prefix
				END;

		PutData (code);

		finChar := code;

		WHILE count > 0 DO
			BEGIN
			count := count - 1;
			PutData (ORD (stack [count]))
			END;

		IF lzwNextCode < 4096 THEN
			AddLZWTable (oldCode, code, TRUE, tiff);

		oldCode := inCode

		UNTIL FALSE;

	2:	{ Found an end-of-data code }

	Success (fi);

	CleanUp (0, 0)

	END;

{$IFC qTrace} {$D++} {$ENDC}

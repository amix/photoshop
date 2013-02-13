{Photoshop version 1.0.1, file: URawFormat.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}
{$I UDither.a.inc}

{*****************************************************************************}

{$S ARawFormat}

PROCEDURE GuessSize (fileLength: LONGINT;
					 VAR rows: LONGINT;
					 VAR cols: LONGINT;
					 VAR channels: LONGINT;
					 VAR header: LONGINT);

	VAR
		goal: LONGINT;
		size: LONGINT;
		width: LONGINT;
		factor: LONGINT;
		portrait: BOOLEAN;

	BEGIN

	goal := fileLength - header;

	IF (rows = 0) AND (cols = 0) THEN
		BEGIN

		IF channels = 0 THEN
			BEGIN

			width := 1;
			factor := 2;
			size := goal;

			WHILE size >= SQR (factor) DO
				IF size MOD SQR (factor) = 0 THEN
					BEGIN
					size := size DIV SQR (factor);
					width := width * factor
					END
				ELSE
					factor := factor + 1;

			IF size <= 3 THEN
				BEGIN
				rows := width;
				cols := width;
				channels := size;
				EXIT (GuessSize)
				END;

			channels := 1

			END;

		IF goal MOD channels = 0 THEN
			BEGIN

			size := goal DIV channels;

			factor := 1;
			WHILE SQR (factor + 1) <= size DO
				factor := factor + 1;

			WHILE size DIV factor < factor * 4 DO
				BEGIN

				IF size MOD factor = 0 THEN
					BEGIN
					rows := factor;
					cols := (size DIV factor);
					EXIT (GuessSize)
					END;

				factor := factor - 1
				END

			END

		END

	ELSE IF (rows = 0) OR (cols = 0) THEN
		BEGIN

		IF channels = 0 THEN channels := 1;

		IF goal MOD channels = 0 THEN
			BEGIN

			size := goal DIV channels;

			IF rows = 0 THEN
				IF size MOD cols = 0 THEN
					rows := size DIV cols;

			IF cols = 0 THEN
				IF size MOD rows = 0 THEN
					cols := size DIV rows

			END

		END

	ELSE IF channels = 0 THEN
		BEGIN

		IF goal MOD (rows * cols) = 0 THEN
			channels := goal DIV (rows * cols)

		END

	ELSE IF rows * cols * channels = goal THEN
		BEGIN

		size := rows * cols;

		portrait := rows > cols;

		factor := Min (rows, cols) - 1;

		WHILE size DIV factor < factor * 4 DO
			BEGIN

			IF size MOD factor = 0 THEN
				BEGIN

				IF portrait THEN
					BEGIN
					cols := factor;
					rows := (size DIV factor)
					END
				ELSE
					BEGIN
					rows := factor;
					cols := (size DIV factor)
					END;

				EXIT (GuessSize)
				END;

			factor := factor - 1
			END

		END

	ELSE
		BEGIN

		size := rows * cols * channels;

		IF fileLength >= size THEN
			header := fileLength - size

		END

	END;

{*****************************************************************************}

{$S ARawFormat}

PROCEDURE AskImageParameters (name: Str255;
							  fileLength: LONGINT;
							  VAR channels: INTEGER;
							  VAR rows: INTEGER;
							  VAR cols: INTEGER;
							  VAR header: LONGINT;
							  VAR interleaved: BOOLEAN);

	CONST
		kAskParamsID	 = 2202;
		kTooLargeID 	 = 2203;
		kTooSmallID 	 = 2204;
		kHookItem		 = 3;
		kColsItem		 = 4;
		kRowsItem		 = 5;
		kChannelsItem	 = 6;
		kInterleavedItem = 7;
		kHeaderItem 	 = 8;
		kSwapItem		 = 9;
		kGuessItem		 = 10;

	VAR
		s: Str255;
		fi: FailInfo;
		temp: BOOLEAN;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		colsField: TFixedText;
		rowsField: TFixedText;
		headerField: TFixedText;
		channelsField: TFixedText;
		interleavedBox: TCheckBox;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	PROCEDURE AdjustCheckBox;
		BEGIN
		IF channelsField.ParseValue THEN
			IF channelsField.fValue < 2 THEN
				HideControl (ControlHandle (interleavedBox.fItemHandle))
			ELSE
				ShowControl (ControlHandle (interleavedBox.fItemHandle))
		END;

	PROCEDURE MyItemHandling (anItem: INTEGER; VAR done: BOOLEAN);

		VAR
			r: LONGINT;
			c: LONGINT;
			ch: LONGINT;
			temp: BOOLEAN;
			item: INTEGER;

		BEGIN

			CASE anItem OF

			kChannelsItem:
				AdjustCheckBox;

			kSwapItem:
				IF rowsField.ParseValue AND colsField.ParseValue THEN
					BEGIN

					rows := rowsField.fValue;
					cols := colsField.fValue;

					IF rows <> cols THEN
						BEGIN
						rowsField.StuffValue (cols);
						colsField.StuffValue (rows);
						aBWDialog.SetEditSelection (kColsItem)
						END

					END;

			kGuessItem:
				BEGIN

				temp := rowsField.ParseValue;
				temp := colsField.ParseValue;
				temp := channelsField.ParseValue;
				temp := headerField.ParseValue;

				r := rowsField.fValue;
				c := colsField.fValue;
				ch := channelsField.fValue;
				header := headerField.fValue;

				GuessSize (fileLength, r, c, ch, header);

				IF (ch <= 32767) AND (r <= kMaxCoord) AND
									 (c <= kMaxCoord) THEN
					BEGIN

					item := 0;

					IF NOT temp OR (header <> headerField.fValue) THEN
						BEGIN
						headerField.StuffValue (header);
						item := kHeaderItem
						END;

					IF ch <> channelsField.fValue THEN
						BEGIN
						channelsField.StuffValue (ch);
						item := kChannelsItem;
						AdjustCheckBox
						END;

					IF r <> rowsField.fValue THEN
						BEGIN
						rowsField.StuffValue (r);
						item := kRowsItem
						END;

					IF c <> colsField.fValue THEN
						BEGIN
						colsField.StuffValue (c);
						item := kColsItem
						END;

					IF item <> 0 THEN
						aBWDialog.SetEditSelection (item)

					END

				END;

			OTHERWISE
				StdItemHandling (anItem, done)

			END

		END;

	FUNCTION ValidSize: BOOLEAN;

		VAR
			n: LONGINT;
			result: Int64Bit;

		BEGIN

		rows	 := rowsField	 .fValue;
		cols	 := colsField	 .fValue;
		channels := channelsField.fValue;
		header	 := headerField  .fValue;

		LongMul (channels, ORD4 (rows) * cols, result);

		n := result.loLong;

		IF (result.hiLong <> 0) OR (n < 0) OR (n > fileLength) THEN
			n := fileLength + 1;

		n := n + header;

		IF n > fileLength THEN
			BEGIN
			BWNotice (kTooLargeID, TRUE);
			ValidSize := FALSE
			END

		ELSE IF n < fileLength THEN
			ValidSize := (BWAlert (kTooSmallID, 0, TRUE) = 1)

		ELSE
			ValidSize := TRUE

		END;

	BEGIN

	NumToString (fileLength, s);
	ParamText (name, s, '', '');

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kAskParamsID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	colsField := aBWDialog.DefineFixedText
			(kColsItem, 0, FALSE, TRUE, 1, Max (1, Min (kMaxCoord, fileLength)));

	rowsField := aBWDialog.DefineFixedText
			(kRowsItem, 0, FALSE, TRUE, 1, Max (1, Min (kMaxCoord, fileLength)));

	channelsField := aBWDialog.DefineFixedText
			(kChannelsItem, 0, FALSE, TRUE, 1, Max (1, Min (32767, fileLength)));

	headerField := aBWDialog.DefineFixedText
			(kHeaderItem, 0, FALSE, TRUE, 0, fileLength - 1);

	interleavedBox := aBWDialog.DefineCheckBox (kInterleavedItem, TRUE);

	MyItemHandling (kGuessItem, temp);

	aBWDialog.SetEditSelection (kColsItem);

		REPEAT

		aBWDialog.TalkToUser (hitItem, MyItemHandling);

		IF hitItem = cancel THEN Failure (0, 0)

		UNTIL ValidSize;

	interleaved := interleavedBox.fChecked AND (channels > 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE TRawFormat.IImageFormat; OVERRIDE;

	BEGIN

	INHERITED IImageFormat;

	fCanRead	  := TRUE;
	fUsesDataFork := TRUE;

	fFileCreator := '????';

	fFTypeItem	  := 4;
	fFCreatorItem := 5;

	fInts	   := 1;
	fInt1Item  := 6;
	fInt1Lower := 0;
	fInt1Upper := 32768;

	fRadio1Item  := 7;
	fRadio1Count := 2;

	fHeader := 0;

	fInterleaved := TRUE

	END;

{*****************************************************************************}

{$S AWriteFile}

FUNCTION TRawFormat.CanWrite (doc: TImageDocument): BOOLEAN; OVERRIDE;

	BEGIN
	CanWrite := (doc.fDepth = 8)
	END;

{*****************************************************************************}

{$S ARawFormat}

PROCEDURE TRawFormat.SetFormatOptions (doc: TImageDocument); OVERRIDE;

	BEGIN

	IF doc.fChannels < 2 THEN
		BEGIN
		fDialogID := 2200;
		fRadioClusters := 0
		END
	ELSE
		BEGIN
		fDialogID := 2201;
		fRadioClusters := 1
		END;

	fRadio1 := ORD (NOT fInterleaved);

	fInt1 := fHeader;

	DoOptionsDialog;

	fHeader := fInt1;

	fInterleaved := (fRadio1 = 0)

	END;

{*****************************************************************************}

{$S ARawFormat}

PROCEDURE TRawFormat.DoRead (doc: TImageDocument;
							 refNum: INTEGER;
							 rsrcExists: BOOLEAN); OVERRIDE;

	TYPE
		TRevertInfo = RECORD
			fRows		: INTEGER;
			fCols		: INTEGER;
			fChannels	: INTEGER;
			fHeader 	: LONGINT;
			fInterleaved: BOOLEAN
			END;
		PRevertInfo = ^TRevertInfo;
		HRevertInfo = ^PRevertInfo;

	VAR
		rows: INTEGER;
		cols: INTEGER;
		header: LONGINT;
		channel: INTEGER;
		channels: INTEGER;
		info: HRevertInfo;
		aVMArray: TVMArray;
		fileLength: LONGINT;
		interleaved: BOOLEAN;

	BEGIN

	fRefNum := refNum;

	fileLength := GetFileLength;

	IF fileLength = 0 THEN Failure (errEmptyFile, 0);

	IF doc.fRevertInfo = NIL THEN
		BEGIN

		AskImageParameters (doc.fTitle, fileLength,
							channels, rows, cols, header, interleaved);

		info := HRevertInfo (NewPermHandle (SIZEOF (TRevertInfo)));
		FailMemError;

		info^^.fRows		:= rows;
		info^^.fCols		:= cols;
		info^^.fChannels	:= channels;
		info^^.fHeader		:= header;
		info^^.fInterleaved := interleaved;

		doc.fRevertInfo := Handle (info)

		END

	ELSE
		BEGIN

		info := HRevertInfo (doc.fRevertInfo);

		rows		:= info^^.fRows;
		cols		:= info^^.fCols;
		channels	:= info^^.fChannels;
		header		:= info^^.fHeader;
		interleaved := info^^.fInterleaved

		END;

	doc.fRows := rows;
	doc.fCols := cols;

	doc.fChannels := channels;

	doc.DefaultMode;

	FOR channel := 0 TO channels - 1 DO
		BEGIN
		aVMArray := NewVMArray (rows, cols, doc.Interleave (channel));
		doc.fData [channel] := aVMArray
		END;

	SkipBytes (header);

	IF interleaved THEN
		GetInterleavedRows (doc.fData,
							channels,
							0,
							rows,
							NOT doc.fReverting)
	ELSE
		FOR channel := 0 TO channels - 1 DO
			BEGIN
			StartTask (1 / (channels - channel));
			GetRawRows (doc.fData [channel],
						doc.fData [channel] . fLogicalSize,
						0,
						rows,
						NOT doc.fReverting);
			FinishTask
			END

	END;

{*****************************************************************************}

{$S ARawFormat}

FUNCTION TRawFormat.DataForkBytes (doc: TImageDocument): LONGINT; OVERRIDE;

	BEGIN
	DataForkBytes := doc.fChannels * ORD4 (doc.fRows) * doc.fCols + fHeader
	END;

{*****************************************************************************}

{$S ARawFormat}

PROCEDURE TRawFormat.DoWrite (doc: TImageDocument; refNum: INTEGER); OVERRIDE;

	VAR
		channel: INTEGER;

	BEGIN

	fRefNum := refNum;

	MoveHands (FALSE);

	PutZeros (fHeader);

	IF fInterleaved THEN
		PutInterleavedRows (doc.fData,
							doc.fChannels,
							0,
							doc.fRows)

	ELSE
		FOR channel := 0 TO doc.fChannels - 1 DO
			BEGIN
			StartTask (1 / (doc.fChannels - channel));
			PutRawRows (doc.fData [channel],
						doc.fData [channel] . fLogicalSize,
						0,
						doc.fRows);
			FinishTask
			END

	END;

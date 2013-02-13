{Photoshop version 1.0.1, file: URootFormat.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TOSTypeText.IOSTypeText (itsItemNumber: INTEGER;
								   itsParent: TDialogView;
								   initValue: OSType);

	VAR
		s: String [4];

	BEGIN

	IKeyHandler (itsItemNumber, itsParent);

	s := '    ';

	s [1] := initValue [1];
	s [2] := initValue [2];
	s [3] := initValue [3];
	s [4] := initValue [4];

	StuffString (s)

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TOSTypeText.Validate (VAR succeeded: BOOLEAN); OVERRIDE;

	CONST
		kTooManyCharsID = 903;

	VAR
		s: Str255;

	BEGIN

	GetIText (fItemHandle, s);

	s := CONCAT (s, '    ');

	WHILE (LENGTH (s) > 4) AND (s [LENGTH (s)] = ' ') DO
		DELETE (s, LENGTH (s), 1);

	fValue [1] := s [1];
	fValue [2] := s [2];
	fValue [3] := s [3];
	fValue [4] := s [4];

	succeeded := (LENGTH (s) <= 4);

	IF NOT succeeded THEN
		BEGIN

		BWNotice (kTooManyCharsID, TRUE);

		TDialogView (fParent) . InstallKeyHandler (SELF)

		END

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE TRootFormat.IImageFormat; OVERRIDE;

	BEGIN

	INHERITED IImageFormat;

	fFTypeItem	  := 0;
	fFCreatorItem := 0;

	fCheckBoxes    := 0;
	fRadioClusters := 0;
	fInts		   := 0;
	fStrs		   := 0;

	fLSBFirst := FALSE;

	fSpool := FALSE

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TRootFormat.DoOptionsDialog;

	CONST
		kHookItem = 3;

	VAR
		fi: FailInfo;
		theEdit: INTEGER;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		checkBox1: TCheckBox;
		checkBox2: TCheckBox;
		checkBox3: TCheckBox;
		int1Field: TFixedText;
		str1Handler: TKeyHandler;
		theFileType: TOSTypeText;
		theFileCreator: TOSTypeText;
		radioCluster1: TRadioCluster;
		radioCluster2: TRadioCluster;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (fDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	theEdit := 0;

	IF fFTypeItem <> 0 THEN
		BEGIN

		NEW (theFileType);
		FailNil (theFileType);

		theFileType.IOSTypeText (fFTypeItem, aBWDialog, fFileType);

		theEdit := fFTypeItem

		END;

	IF fFCreatorItem <> 0 THEN
		BEGIN

		NEW (theFileCreator);
		FailNil (theFileCreator);

		theFileCreator.IOSTypeText (fFCreatorItem, aBWDialog, fFileCreator);

		IF theEdit = 0 THEN theEdit := fFCreatorItem

		END;

	IF fCheckBoxes >= 1 THEN
		checkBox1 := aBWDialog.DefineCheckBox (fCheck1Item, fCheck1);

	IF fCheckBoxes >= 2 THEN
		checkBox2 := aBWDialog.DefineCheckBox (fCheck2Item, fCheck2);

	IF fCheckBoxes >= 3 THEN
		checkBox3 := aBWDialog.DefineCheckBox (fCheck3Item, fCheck3);

	IF fRadioClusters >= 1 THEN
		radioCluster1 := aBWDialog.DefineRadioCluster
				(fRadio1Item,
				 fRadio1Item + fRadio1Count - 1,
				 fRadio1Item + fRadio1);

	IF fRadioClusters >= 2 THEN
		radioCluster2 := aBWDialog.DefineRadioCluster
				(fRadio2Item,
				 fRadio2Item + fRadio2Count - 1,
				 fRadio2Item + fRadio2);

	IF fInts >= 1 THEN
		BEGIN

		int1Field := aBWDialog.DefineFixedText
				(fInt1Item, 0, FALSE, TRUE, fInt1Lower, fInt1Upper);

		int1Field.StuffValue (fInt1);

		IF theEdit = 0 THEN theEdit := fInt1Item

		END;

	IF fStrs >= 1 THEN
		BEGIN

		NEW (str1Handler);
		FailNil (str1Handler);

		str1Handler.IKeyHandler (fStr1Item, aBWDialog);

		str1Handler.StuffString (fStr1^);

		IF theEdit = 0 THEN theEdit := fStr1Item

		END;

	aBWDialog.SetEditSelection (theEdit);

	aBWDialog.TalkToUser (hitItem, StdItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	IF fFTypeItem <> 0 THEN
		fFileType := theFileType.fValue;

	IF fFCreatorItem <> 0 THEN
		fFileCreator := theFileCreator.fValue;

	IF fCheckBoxes >= 1 THEN
		fCheck1 := checkBox1.fChecked;

	IF fCheckBoxes >= 2 THEN
		fCheck2 := checkBox2.fChecked;

	IF fCheckBoxes >= 3 THEN
		fCheck3 := checkBox3.fChecked;

	IF fRadioClusters >= 1 THEN
		fRadio1 := radioCluster1.fChosenItem - fRadio1Item;

	IF fRadioClusters >= 2 THEN
		fRadio2 := radioCluster2.fChosenItem - fRadio2Item;

	IF fInts >= 1 THEN
		fInt1 := int1Field.fValue;

	IF fStrs >= 1 THEN
		{$H-}
		GetIText (str1Handler.fItemHandle, fStr1^);
		{$H+}

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S AFile}

FUNCTION TRootFormat.GetFileLength: LONGINT;

	VAR
		err: OSErr;
		fileLength: LONGINT;

	BEGIN

	IF fSpool THEN
		GetFileLength := fSpoolEOFPosition

	ELSE
		BEGIN
		err := GetEOF (fRefNum, fileLength);
		IF err <> 0 THEN FailOSErr (err);
		GetFileLength := fileLength
		END

	END;

{*****************************************************************************}

{$S AFile}

FUNCTION TRootFormat.GetFilePosition: LONGINT;

	VAR
		n: LONGINT;
		err: OSErr;

	BEGIN

	IF fSpool THEN
		GetFilePosition := fSpoolPosition

	ELSE
		BEGIN
		err := GetFPos (fRefNum, n);
		IF err <> 0 THEN FailOSErr (err);
		GetFilePosition := n
		END

	END;

{*****************************************************************************}

{$S AFile}

PROCEDURE TRootFormat.SeekTo (n: LONGINT);

	VAR
		err: OSErr;

	BEGIN

	IF fSpool THEN
		fSpoolPosition := n

	ELSE
		BEGIN
		err := SetFPos (fRefNum, fsFromStart, n);
		IF err <> 0 THEN FailOSErr (err)
		END

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TRootFormat.SkipBytes (n: LONGINT);

	VAR
		err: OSErr;

	BEGIN

	IF fSpool THEN
		fSpoolPosition := fSpoolPosition + n

	ELSE
		BEGIN
		err := SetFPos (fRefNum, fsFromMark, n);
		IF err <> 0 THEN FailOSErr (err)
		END

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TRootFormat.GetBytes (n: LONGINT; p: Ptr);

	VAR
		err: OSErr;

	BEGIN

	IF n > 0 THEN
		IF fSpool THEN
			BEGIN

			IF fSpoolPosition + n > fSpoolEOFPosition THEN
				Failure (eofErr, 0);

			BlockMove (Ptr (ORD4 (fSpoolData^) + fSpoolPosition), p, n);

			fSpoolPosition := fSpoolPosition + n

			END

		ELSE
			BEGIN

			err := FSRead (fRefNum, n, p);

			IF err <> 0 THEN FailOSErr (err)

			END

	END;

{*****************************************************************************}

{$S AReadFile}

FUNCTION TRootFormat.GetByte: INTEGER;

	VAR
		w: INTEGER;

	BEGIN

	GetBytes (1, @w);

	GetByte := BAND (BSR (w, 8), $FF)

	END;

{*****************************************************************************}

{$S AReadFile}

FUNCTION TRootFormat.GetWord: INTEGER;

	VAR
		w: INTEGER;

	BEGIN

	IF fLSBFirst THEN
		BEGIN
		w := GetByte;
		GetWord := w + BSL (GetByte, 8)
		END

	ELSE
		BEGIN
		GetBytes (2, @w);
		GetWord := w
		END

	END;

{*****************************************************************************}

{$S AReadFile}

FUNCTION TRootFormat.GetLong: LONGINT;

	VAR
		l: LONGINT;

	BEGIN

	IF fLSBFirst THEN
		BEGIN
		l := GetByte;
		l := l + BSL (GetByte, 8);
		l := l + BSL (GetByte, 16);
		GetLong := l + BSL (GetByte, 24);
		END

	ELSE
		BEGIN
		GetBytes (4, @l);
		GetLong := l
		END

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TRootFormat.GetRawRows (buffer: TVMArray;
								  rowBytes: INTEGER;
								  first: INTEGER;
								  count: INTEGER;
								  canAbort: BOOLEAN);

	VAR
		j: INTEGER;
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		rows: INTEGER;
		page: INTEGER;
		direct: BOOLEAN;
		pageCount: INTEGER;
		rowsPerPage: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF dstPtr <> NIL THEN buffer.DoneWithPtr;
		buffer.Flush
		END;

	BEGIN

	dstPtr := NIL;

	CatchFailures (fi, CleanUp);

	rowsPerPage := buffer.fBlocksPerPage;

	pageCount := (count + rowsPerPage - 1) DIV rowsPerPage;

	direct := (rowBytes = buffer.fPhysicalSize) AND
			  (first MOD rowsPerPage = 0);

	row := first;

	FOR page := 0 TO pageCount - 1 DO
		BEGIN

		MoveHands (canAbort);

		UpdateProgress (page, pageCount);

		rows := Min (rowsPerPage, first + count - row);

		IF direct THEN
			BEGIN

			dstPtr := buffer.NeedPtr (row, row, TRUE);

			GetBytes (rows * rowBytes, dstPtr);

			buffer.DoneWithPtr;

			dstPtr := NIL

			END

		ELSE
			BEGIN

			GetBytes (rows * rowBytes, gBuffer);

			srcPtr := gBuffer;

			FOR j := 0 TO rows - 1 DO
				BEGIN

				dstPtr := buffer.NeedPtr (row + j, row + j, TRUE);

				BlockMove (srcPtr, dstPtr, rowBytes);

				srcPtr := Ptr (ORD4 (srcPtr) + rowBytes);

				buffer.DoneWithPtr;

				dstPtr := NIL

				END

			END;

		row := row + rows

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TRootFormat.GetInterleavedRows (buffer: TChannelArrayList;
										  channels: INTEGER;
										  first: INTEGER;
										  count: INTEGER;
										  canAbort: BOOLEAN);

	VAR
		j: INTEGER;
		fi: FailInfo;
		row: INTEGER;
		rows: INTEGER;
		page: INTEGER;
		tempBuffer: Ptr;
		channel: INTEGER;
		rowSize: LONGINT;
		pageCount: INTEGER;
		logicalSize: INTEGER;
		rowsPerPage: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		VAR
			channel: INTEGER;

		BEGIN

		IF (tempBuffer <> NIL) AND (tempBuffer <> gBuffer) THEN
			DisposPtr (tempBuffer);

		FOR channel := 0 TO channels - 1 DO
			buffer [channel] . Flush

		END;

	BEGIN

	IF channels = 1 THEN
		GetRawRows (buffer [0],
					buffer [0] . fLogicalSize,
					first,
					count,
					canAbort)

	ELSE
		BEGIN

		tempBuffer := NIL;

		CatchFailures (fi, CleanUp);

		logicalSize := buffer [0] . fLogicalSize;

		rowSize := channels * ORD4 (logicalSize);

		IF GetPtrSize (gBuffer) < rowSize THEN
			BEGIN
			tempBuffer := NewPtr (rowSize);
			FailMemError
			END
		ELSE
			tempBuffer := gBuffer;

		rowsPerPage := GetPtrSize (tempBuffer) DIV rowSize;

		pageCount := (count + rowsPerPage - 1) DIV rowsPerPage;

		row := first;

		FOR page := 0 TO pageCount - 1 DO
			BEGIN

			MoveHands (canAbort);

			UpdateProgress (page, pageCount);

			rows := Min (rowsPerPage, first + count - row);

			GetBytes (rows * rowSize, tempBuffer);

			FOR channel := 0 TO channels - 1 DO
				BEGIN

				FOR j := 0 TO rows - 1 DO
					BEGIN

					DoStepCopyBytes
						(Ptr (ORD4 (tempBuffer) + j * rowSize + channel),
						 buffer [channel] . NeedPtr (row + j, row + j, TRUE),
						 logicalSize,
						 channels,
						 1);

					buffer [channel] . DoneWithPtr

					END;

				buffer [channel] . Flush

				END;

			row := row + rows

			END;

		UpdateProgress (1, 1);

		Success (fi);

		CleanUp (0, 0)

		END

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TRootFormat.PutBytes (n: LONGINT; p: Ptr);

	CONST
		kBlock = 30 * 1024;

	VAR
		err: OSErr;

	BEGIN

	IF n > 0 THEN
		IF fSpool THEN
			BEGIN

			IF fSpoolPosition + n > fSpoolEOFPosition THEN
				fSpoolEOFPosition := fSpoolPosition + n;

			IF fSpoolEOFPosition > GetHandleSize (fSpoolData) THEN
				ResizeLargeHandle (fSpoolData, fSpoolEOFPosition + kBlock);

			BlockMove (p, Ptr (ORD4 (fSpoolData^) + fSpoolPosition), n);

			fSpoolPosition := fSpoolPosition + n

			END

		ELSE
			BEGIN

			err := FSWrite (fRefNum, n, p);

			IF err <> 0 THEN FailOSErr (err)

			END

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TRootFormat.PutByte (w: INTEGER);

	BEGIN

	PutBytes (1, Ptr (ORD4 (@w) + 1))

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TRootFormat.PutWord (w: INTEGER);

	BEGIN

	IF fLSBFirst THEN
		BEGIN
		PutByte (BAND (w, $FF));
		PutByte (BSR (w, 8))
		END

	ELSE
		PutBytes (2, @w)

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TRootFormat.PutLong (l: LONGINT);

	BEGIN

	IF fLSBFirst THEN
		BEGIN
		PutByte (BAND (l, $FF));
		PutByte (BAND (BSR (l, 8), $FF));
		PutByte (BAND (BSR (l, 16), $FF));
		PutByte (BSR (l, 24))
		END

	ELSE
		PutBytes (4, @l)

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TRootFormat.PutZeros (n: LONGINT);

	VAR
		buffer: PACKED ARRAY [1..32] OF CHAR;

	BEGIN

	WHILE n >= 32 DO
		BEGIN
		DoSetBytes (@buffer, 32, 0);
		PutBytes (32, @buffer);
		n := n - 32
		END;

	WHILE n > 0 DO
		BEGIN
		PutByte (0);
		n := n - 1
		END

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TRootFormat.PutRawRows (buffer: TVMArray;
								  rowBytes: INTEGER;
								  first: INTEGER;
								  count: INTEGER);

	VAR
		j: INTEGER;
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		rows: INTEGER;
		page: INTEGER;
		direct: BOOLEAN;
		pageCount: INTEGER;
		rowsPerPage: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF srcPtr <> NIL THEN buffer.DoneWithPtr;
		buffer.Flush
		END;

	BEGIN

	srcPtr := NIL;

	CatchFailures (fi, CleanUp);

	rowsPerPage := buffer.fBlocksPerPage;

	pageCount := (count + rowsPerPage - 1) DIV rowsPerPage;

	direct := (rowBytes = buffer.fPhysicalSize) AND
			  (first MOD rowsPerPage = 0);

	row := first;

	FOR page := 0 TO pageCount - 1 DO
		BEGIN

		UpdateProgress (page, pageCount);

		IF page MOD gVMPageLimit = 0 THEN
			FOR j := page TO Min (pageCount - 1, page + gVMPageLimit - 1) DO
				BEGIN
				srcPtr := buffer.NeedPtr (j * rowsPerPage,
										  j * rowsPerPage,
										  FALSE);
				buffer.DoneWithPtr
				END;

		rows := Min (rowsPerPage, first + count - row);

		IF direct THEN
			BEGIN

			srcPtr := buffer.NeedPtr (row, row, FALSE);

			PutBytes (rows * rowBytes, srcPtr);

			buffer.DoneWithPtr;

			srcPtr := NIL

			END

		ELSE
			BEGIN

			dstPtr := gBuffer;

			FOR j := 0 TO rows - 1 DO
				BEGIN

				srcPtr := buffer.NeedPtr (row + j, row + j, FALSE);

				BlockMove (srcPtr, dstPtr, rowBytes);

				dstPtr := Ptr (ORD4 (dstPtr) + rowBytes);

				buffer.DoneWithPtr;

				srcPtr := NIL

				END;

			PutBytes (rows * rowBytes, gBuffer);

			END;

		row := row + rows

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TRootFormat.PutInterleavedRows (buffer: TChannelArrayList;
										  channels: INTEGER;
										  first: INTEGER;
										  count: INTEGER);

	VAR
		j: INTEGER;
		fi: FailInfo;
		row: INTEGER;
		rows: INTEGER;
		page: INTEGER;
		tempBuffer: Ptr;
		channel: INTEGER;
		rowSize: LONGINT;
		pageCount: INTEGER;
		logicalSize: INTEGER;
		rowsPerPage: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		VAR
			channel: INTEGER;

		BEGIN

		IF (tempBuffer <> NIL) AND (tempBuffer <> gBuffer) THEN
			DisposPtr (tempBuffer);

		FOR channel := 0 TO channels - 1 DO
			buffer [channel] . Flush

		END;

	BEGIN

	IF channels = 1 THEN
		PutRawRows (buffer [0], buffer [0] . fLogicalSize, first, count)

	ELSE
		BEGIN

		tempBuffer := NIL;

		CatchFailures (fi, CleanUp);

		logicalSize := buffer [0] . fLogicalSize;

		rowSize := channels * ORD4 (logicalSize);

		IF GetPtrSize (gBuffer) < rowSize THEN
			BEGIN
			tempBuffer := NewPtr (rowSize);
			FailMemError
			END
		ELSE
			tempBuffer := gBuffer;

		rowsPerPage := GetPtrSize (tempBuffer) DIV rowSize;

		pageCount := (count + rowsPerPage - 1) DIV rowsPerPage;

		row := first;

		FOR page := 0 TO pageCount - 1 DO
			BEGIN

			UpdateProgress (page, pageCount);

			rows := Min (rowsPerPage, first + count - row);

			FOR channel := 0 TO channels - 1 DO
				BEGIN

				FOR j := 0 TO rows - 1 DO
					BEGIN

					DoStepCopyBytes
						(buffer [channel] . NeedPtr (row + j, row + j, FALSE),
						 Ptr (ORD4 (tempBuffer) + j * rowSize + channel),
						 logicalSize,
						 1,
						 channels);

					buffer [channel] . DoneWithPtr

					END;

				buffer [channel] . Flush

				END;

			PutBytes (rows * rowSize, tempBuffer);

			row := row + rows

			END;

		UpdateProgress (1, 1);

		Success (fi);

		CleanUp (0, 0)

		END

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE MyPackBits (VAR srcPtr, dstPtr: Ptr; srcBytes: INTEGER);

	BEGIN

	WHILE srcBytes > 127 DO
		BEGIN
		PackBits (srcPtr, dstPtr, 127);
		srcBytes := srcBytes - 127
		END;

	PackBits (srcPtr, dstPtr, srcBytes)

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TestForMonochrome (doc: TImageDocument);

	VAR
		gray: INTEGER;
		hist: THistogram;
		convert: BOOLEAN;
		map: TLookUpTable;

	BEGIN

	IF doc.fMode = IndexedColorMode THEN
		BEGIN

		doc.TestColorTable;

		doc.fData [0] . HistBytes (hist);

		convert := TRUE;

		FOR gray := 0 TO 255 DO
			IF hist [gray] <> 0 THEN
				IF (doc.fIndexedColorTable.R [gray] <>
					doc.fIndexedColorTable.G [gray]) OR
				   (doc.fIndexedColorTable.R [gray] <>
					doc.fIndexedColorTable.B [gray]) THEN
					convert := FALSE;

		IF convert THEN
			BEGIN
			map := doc.fIndexedColorTable.R;
			doc.fData [0] . MapBytes (map);
			doc.fMode := MonochromeMode
			END

		END

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TestForHalftone (doc: TImageDocument);

	VAR
		r: Rect;
		fi: FailInfo;
		row: INTEGER;
		gray: INTEGER;
		hist: THistogram;
		convert: BOOLEAN;
		rowBytes: INTEGER;
		aVMArray: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aVMArray.Free
		END;

	BEGIN

	IF doc.fMode = MonochromeMode THEN
		BEGIN

		doc.fData [0] . HistBytes (hist);

		convert := TRUE;

		FOR gray := 1 TO 254 DO
			IF hist [gray] <> 0 THEN
				convert := FALSE;

		IF convert THEN
			BEGIN

			rowBytes := BSL (BSR (doc.fCols + 15, 4), 1);

			aVMArray := NewVMArray (doc.fRows, rowBytes, 1);

			CatchFailures (fi, CleanUp);

			gTables.CompTables (doc, 0, TRUE, FALSE, 1, 1, FALSE, FALSE, 1);

			r.left	:= 0;
			r.right := doc.fCols;

			FOR row := 0 TO doc.fRows - 1 DO
				BEGIN

				r.top	 := row;
				r.bottom := row + 1;

				gTables.DitherRect (doc, 0, 1, r, gBuffer, TRUE);

				BlockMove (gBuffer,
						   aVMArray.NeedPtr (row, row, TRUE),
						   rowBytes);

				aVMArray.DoneWithPtr

				END;

			aVMArray.Flush;

			Success (fi);

			doc.fData [0] . Free;
			doc.fData [0] := aVMArray;

			doc.fDepth := 1;
			doc.fMode := HalftoneMode

			END

		END

	END;

{*****************************************************************************}

{$S AReadFile}

FUNCTION AskAdjustAspect: BOOLEAN;

	CONST
		kAdjustAspectID = 901;

	VAR
		item: INTEGER;

	BEGIN

	item := BWAlert (kAdjustAspectID, 0, TRUE);

	IF item = cancel THEN Failure (0, 0);

	AskAdjustAspect := (item = ok)

	END;

{Photoshop version 1.0.1, file: UResize.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAbout.p.inc}
{$I UAssembly.a.inc}
{$I UResize.a.inc}

VAR
	gPrintQuality: INTEGER;

	gResampledSize: LONGINT;
	gResampledSizeRect: Rect;

{*****************************************************************************}

{$S ARes}

PROCEDURE InitResize;

	BEGIN
	gPrintQuality := 1
	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TResizeTable.IResizeTable (oldSize: INTEGER;
									 newSize: INTEGER;
									 sample: BOOLEAN);

	VAR
		h: Handle;
		j: INTEGER;
		k: INTEGER;
		w: INTEGER;
		x: LONGINT;
		fi: FailInfo;
		method: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Free
		END;

	BEGIN

	IF sample THEN
		method := 0
	ELSE
		method := gPreferences.fInterpolate;

	fTable1 := NIL;
	fTable2 := NIL;

	fOldSize := oldSize;
	fNewSize := newSize;

	IF (method = 0) OR (oldSize = 1) OR (newSize = oldSize) THEN
		fMode := ResizeModeSample

	ELSE IF (method = 1) AND (newSize > oldSize) THEN
		fMode := ResizeModeInterpolate

	ELSE IF (method = 2) AND (newSize >= oldSize DIV 2) THEN
		fMode := ResizeModeBiCubic

	ELSE IF (ORD4 (newSize) * 5 < oldSize) OR (oldSize MOD newSize = 0) THEN
		fMode := ResizeModeBigAverage

	ELSE
		fMode := ResizeModeAverage;

	CatchFailures (fi, CleanUp);

	h := NewLargeHandle (BSL (newSize, 1));

	MoveHHi (h);
	HLock (h);

	fTable1 := HWordArray (h);

	IF fMode IN [ResizeModeInterpolate,
				 ResizeModeBiCubic,
				 ResizeModeAverage] THEN
		BEGIN

		h := NewLargeHandle (newSize);

		MoveHHi (h);
		HLock (h);

		fTable2 := HByteArray (h)

		END;

	Success (fi);

		CASE fMode OF

		ResizeModeSample:
			FOR j := 0 TO newSize - 1 DO
				BEGIN

				IF newSize > oldSize THEN
					k := (j * ORD4 (oldSize)) DIV newSize
				ELSE
					k := (j * ORD4 (oldSize) + BSR (oldSize, 1)) DIV newSize;

				fTable1^^ [j] := k

				END;

		ResizeModeInterpolate,
		ResizeModeBiCubic:
			FOR j := 0 TO newSize - 1 DO
				BEGIN

				x := j * ORD4 (oldSize - 1);

				k := x DIV (newSize - 1);
				w := BSL (x MOD (newSize - 1), 8) DIV (newSize - 1);

				fTable1^^ [j] := k;
				fTable2^^ [j] := CHR (w)

				END;

		ResizeModeBigAverage:
			FOR j := 0 TO newSize - 1 DO
				BEGIN

				k := (ORD4 (j + 1) * oldSize DIV newSize) -
					 (ORD4 (j	 ) * oldSize DIV newSize);

				fTable1^^ [j] := k

				END;

		ResizeModeAverage:
			BEGIN

			fTotalWeight := BSL (oldSize, 8) DIV newSize;

			FOR j := 0 TO newSize - 1 DO
				BEGIN

				x := j * ORD4 (oldSize);

				k := x DIV newSize;
				w := BSL (x MOD newSize, 8) DIV newSize;

				fTable1^^ [j] := k;
				fTable2^^ [j] := CHR (w)

				END

			END

		END

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TResizeTable.Free; OVERRIDE;

	BEGIN

	FreeLargeHandle (Handle (fTable1));
	FreeLargeHandle (Handle (fTable2));

	INHERITED Free

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TResizeTable.ResizeLine (srcPtr, dstPtr: Ptr);

	BEGIN

		CASE fMode OF

		ResizeModeSample:
			DoSampleLine (srcPtr, dstPtr, fNewSize, fTable1^);

		ResizeModeInterpolate:
			DoInterpolateLine (srcPtr, dstPtr, fNewSize, fTable1^, fTable2^);

		ResizeModeBiCubic:
			DoBiCubicLine (srcPtr, dstPtr, fOldSize, fNewSize,
						   fTable1^, fTable2^);

		ResizeModeBigAverage:
			DoBigAverageLine (srcPtr, dstPtr, fNewSize, fTable1^);

		ResizeModeAverage:
			DoAverageLine (srcPtr, dstPtr, fNewSize,
						   fTable1^, fTable2^, fTotalWeight)

		END

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE DoResizeArray (srcArray: TVMArray;
						 dstArray: TVMArray;
						 hTable: TResizeTable;
						 vTable: TResizeTable;
						 canAbort: BOOLEAN);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		total: INTEGER;
		buffer: Handle;
		newRow: INTEGER;
		oldRow: INTEGER;
		weight: INTEGER;
		offset: INTEGER;
		oldWidth: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		FreeLargeHandle (buffer);

		IF dstPtr <> NIL THEN dstArray.DoneWithPtr;

		srcArray.Flush;
		dstArray.Flush

		END;

	BEGIN

	buffer := NIL;

	dstPtr := NIL;

	CatchFailures (fi, CleanUp);

	oldWidth := srcArray.fLogicalSize;

	IF vTable.fMode IN [ResizeModeBiCubic,
						ResizeModeBigAverage,
						ResizeModeAverage] THEN
		BEGIN

		buffer := NewLargeHandle (BSL (oldWidth, 2));

		MoveHHi (buffer);
		HLock (buffer)

		END;

	oldRow := 0;

	FOR newRow := 0 TO dstArray.fBlockCount - 1 DO
		BEGIN

		MoveHands (canAbort);

		UpdateProgress (newRow, dstArray.fBlockCount);

		dstPtr := dstArray.NeedPtr (newRow, newRow, TRUE);

			CASE vTable.fMode OF

			ResizeModeSample:
				BEGIN

				oldRow := vTable.fTable1^^ [newRow];

				srcPtr := srcArray.NeedPtr (oldRow, oldRow, FALSE);

				hTable.ResizeLine (srcPtr, dstPtr);

				srcArray.DoneWithPtr

				END;

			ResizeModeInterpolate:
				BEGIN

				oldRow := vTable.fTable1^^ [newRow];
				weight := ORD (vTable.fTable2^^ [newRow]);

				IF weight = 0 THEN
					BEGIN

					srcPtr := srcArray.NeedPtr (oldRow, oldRow, FALSE);

					hTable.ResizeLine (srcPtr, dstPtr);

					srcArray.DoneWithPtr

					END

				ELSE
					BEGIN

					srcPtr := srcArray.NeedPtr (oldRow, oldRow, FALSE);

					BlockMove (srcPtr, gBuffer, oldWidth);

					srcArray.DoneWithPtr;

					srcPtr := srcArray.NeedPtr (oldRow + 1, oldRow + 1, FALSE);

					DoInterpolateRow (srcPtr, gBuffer, oldWidth, weight);

					srcArray.DoneWithPtr;

					hTable.ResizeLine (gBuffer, dstPtr)

					END

				END;

			ResizeModeBiCubic:
				BEGIN

				oldRow := vTable.fTable1^^ [newRow];
				weight := ORD (vTable.fTable2^^ [newRow]);

				IF weight = 0 THEN
					BEGIN

					srcPtr := srcArray.NeedPtr (oldRow, oldRow, FALSE);

					hTable.ResizeLine (srcPtr, dstPtr);

					srcArray.DoneWithPtr

					END

				ELSE
					BEGIN

					FOR offset := -1 TO 2 DO
						BEGIN

						row := Max (0,
							   Min (oldRow + offset,
									srcArray.fBlockCount - 1));

						srcPtr := srcArray.NeedPtr (row, row, FALSE);

						DoStepCopyBytes (srcPtr,
										 Ptr (ORD4 (buffer^) + offset + 1),
										 oldWidth,
										 1,
										 4);

						srcArray.DoneWithPtr

						END;

					DoBiCubicRow (buffer^, oldWidth, weight);

					hTable.ResizeLine (buffer^, dstPtr)

					END

				END;

			ResizeModeBigAverage:
				BEGIN

				DoSetBytes (buffer^, BSL (oldWidth, 2), 0);

				total := vTable.fTable1^^ [newRow];

				FOR row := 1 TO total DO
					BEGIN

					srcPtr := srcArray.NeedPtr (oldRow, oldRow, FALSE);

					DoAddWeightedRow (srcPtr, buffer^, oldWidth, 1);

					srcArray.DoneWithPtr;

					oldRow := oldRow + 1

					END;

				DoDivideRow (buffer^, oldWidth, total);

				hTable.ResizeLine (buffer^, dstPtr)

				END;

			ResizeModeAverage:
				BEGIN

				DoSetBytes (buffer^, BSL (oldWidth, 2), 0);

				oldRow := vTable.fTable1^^ [newRow];
				weight := 256 - ORD (vTable.fTable2^^ [newRow]);

				total := vTable.fTotalWeight;

					REPEAT

					srcPtr := srcArray.NeedPtr (oldRow, oldRow, FALSE);

					DoAddWeightedRow (srcPtr, buffer^, oldWidth, weight);

					srcArray.DoneWithPtr;

					oldRow := oldRow + 1;

					total := total - weight;

					IF total >= 256 THEN
						weight := 256
					ELSE
						weight := total

					UNTIL total = 0;

				DoDivideRow (buffer^, oldWidth, vTable.fTotalWeight);

				hTable.ResizeLine (buffer^, dstPtr)

				END

			END;

		dstArray.DoneWithPtr;
		dstPtr := NIL

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE ResizeArray (srcArray: TVMArray;
					   dstArray: TVMArray;
					   sample: BOOLEAN;
					   canAbort: BOOLEAN);

	VAR
		fi: FailInfo;
		aTable: TResizeTable;
		hTable: TResizeTable;
		vTable: TResizeTable;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (hTable);
		FreeObject (vTable);
		END;

	BEGIN

	hTable := NIL;
	vTable := NIL;

	CatchFailures (fi, CleanUp);

	NEW (aTable);
	FailNil (aTable);

	aTable.IResizeTable (srcArray.fLogicalSize,
						 dstArray.fLogicalSize, sample);

	hTable := aTable;

	NEW (aTable);
	FailNil (aTable);

	aTable.IResizeTable (srcArray.fBlockCount,
						 dstArray.fBlockCount, sample);

	vTable := aTable;

	DoResizeArray (srcArray, dstArray, hTable, vTable, canAbort);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S AResize}

PROCEDURE TResizeCommand.IResizeCommand (itsCommand: INTEGER;
										 view: TImageView;
										 newRows: INTEGER;
										 newCols: INTEGER;
										 vPlacement: INTEGER;
										 hPlacement: INTEGER);

	BEGIN

	IBufferCommand (itsCommand, view);

	fNewRows := newRows;
	fNewCols := newCols;

	fVPlacement := vPlacement;
	fHPlacement := hPlacement;

	fOldStyle := fDoc.fStyleInfo;
	fNewStyle := fOldStyle;

	fSameSize := (fDoc.fRows = newRows) AND (fDoc.fCols = newCols);

	IF fDoc.fRows = newRows THEN fVPlacement := 0;
	IF fDoc.fCols = newCols THEN fHPlacement := 0

	END;

{*****************************************************************************}

{$S AResize}

PROCEDURE TResizeCommand.CopyPart (image: TVMArray;
								   buffer: TVMArray;
								   background: INTEGER);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		row: INTEGER;
		rows: INTEGER;
		cols: INTEGER;
		iOffset: Point;
		bOffset: Point;
		oldRows: INTEGER;
		oldCols: INTEGER;

	BEGIN

	oldRows := image.fBlockCount;
	oldCols := image.fLogicalSize;

	IF (fNewRows > oldRows) OR
	   (fNewCols > oldCols) THEN buffer.SetBytes (background);

	rows := Min (fNewRows, oldRows);
	cols := Min (fNewCols, oldCols);

	IF fVPlacement = 2 THEN
		BEGIN
		iOffset.v := BSR (oldRows  - rows, 1);
		bOffset.v := BSR (fNewRows - rows, 1)
		END
	ELSE IF fVPlacement = 3 THEN
		BEGIN
		iOffset.v := oldRows  - rows;
		bOffset.v := fNewRows - rows
		END
	ELSE
		BEGIN
		iOffset.v := 0;
		bOffset.v := 0
		END;

	IF fHPlacement = 2 THEN
		BEGIN
		iOffset.h := BSR (oldCols  - cols, 1);
		bOffset.h := BSR (fNewCols - cols, 1)
		END
	ELSE IF fHPlacement = 3 THEN
		BEGIN
		iOffset.h := oldCols  - cols;
		bOffset.h := fNewCols - cols
		END
	ELSE
		BEGIN
		iOffset.h := 0;
		bOffset.h := 0
		END;

	FOR row := 0 TO rows - 1 DO
		BEGIN

		dstPtr := buffer.NeedPtr (row + bOffset.v,
								  row + bOffset.v,
								  TRUE);

		srcPtr := image.NeedPtr (row + iOffset.v,
								 row + iOffset.v,
								 FALSE);

		BlockMove (Ptr (ORD4 (srcPtr) + iOffset.h),
				   Ptr (ORD4 (dstPtr) + bOffset.h),
				   cols);

		buffer.DoneWithPtr;
		image.DoneWithPtr

		END;

	buffer.Flush;
	image.Flush

	END;

{*****************************************************************************}

{$S AResize}

PROCEDURE TResizeCommand.DoIt; OVERRIDE;

	VAR
		fi: FailInfo;
		channel: INTEGER;
		aVMArray: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (aVMArray);
		FinishProgress
		END;

	BEGIN

	IF NOT EmptyRect (fDoc.fSelectionRect) THEN
		BEGIN
		fDoc.DeSelect (FALSE);
		fView.fFrame.ForceRedraw
		END;

	IF NOT fSameSize THEN
		BEGIN

		FOR channel := 0 TO fDoc.fChannels - 1 DO
			BEGIN

			MoveHands (TRUE);

			aVMArray := NewVMArray (fNewRows,
									fNewCols,
									fDoc.Interleave (channel));

			fBuffer [channel] := aVMArray

			END;

		aVMArray := NIL;

		IF (fVPlacement <> 0) OR (fHPlacement <> 0) THEN

			IF (fVPlacement = 0) AND (fNewRows <> fDoc.fRows) THEN
				aVMArray := NewVMArray (fNewRows, fDoc.fCols, 1)

			ELSE IF (fHPlacement = 0) AND (fNewCols <> fDoc.fCols) THEN
				aVMArray := NewVMArray (fDoc.fRows, fNewCols, 1);

		CommandProgress (fCmdNumber);

		CatchFailures (fi, CleanUp);

		FOR channel := 0 TO fDoc.fChannels - 1 DO
			BEGIN

			StartTask (1 / (fDoc.fChannels - channel));

			IF (fVPlacement = 0) AND (fHPlacement = 0) THEN

				ResizeArray (fDoc.fData [channel],
							 fBuffer [channel],
							 fDoc.fMode = IndexedColorMode,
							 TRUE)

			ELSE IF aVMArray = NIL THEN

				CopyPart (fDoc.fData [channel],
						  fBuffer [channel],
						  fView.BackgroundByte (channel))

			ELSE
				BEGIN

				aVMArray.Undefine;

				ResizeArray (fDoc.fData [channel],
							 aVMArray,
							 fDoc.fMode = IndexedColorMode,
							 TRUE);

				CopyPart (aVMArray,
						  fBuffer [channel],
						  fView.BackgroundByte (channel))

				END;

			FinishTask

			END;

		Success (fi);

		CleanUp (0, 0)

		END;

	RedoIt

	END;

{*****************************************************************************}

{$S AResize}

PROCEDURE TResizeCommand.UndoIt; OVERRIDE;

	PROCEDURE FixView (view: TImageView);
		BEGIN
		view.AdjustExtent;
		SetTopLeft (view, 0, 0)
		END;

	BEGIN

	IF NOT fSameSize THEN
		BEGIN

		fDoc.DeSelect (FALSE);

		SwapAllChannels;

		fDoc.fRows := fDoc.fData [0] . fBlockCount;
		fDoc.fCols := fDoc.fData [0] . fLogicalSize;

		fDoc.fViewList.Each (FixView);

		fDoc.UpdateStatus

		END;

	fDoc.fStyleInfo := fOldStyle;

	fDoc.InvalRulers

	END;

{*****************************************************************************}

{$S AResize}

PROCEDURE TResizeCommand.RedoIt; OVERRIDE;

	BEGIN

	UndoIt;

	fDoc.fStyleInfo := fNewStyle

	END;

{*****************************************************************************}

{$S AResize}

FUNCTION DoResizeImage (view: TImageView): TCommand;

	CONST
		kResizeID	   = 1060;
		kHookItem	   = 3;
		kResizeByItem  = 4;
		kResizeToItem  = 5;
		kPercentItem   = 6;
		kColsItem	   = 7;
		kRowsItem	   = 8;
		kScreenItem    = 9;
		kWindowItem    = 10;
		kConstrainItem = 11;
		kFirstPlace    = 12;
		kLastPlace	   = 17;
		kPixelsID	   = 1009;
		kWillCropID    = 928;

	VAR
		r: Rect;
		s1: Str255;
		s2: Str255;
		ss: Str255;
		fi: FailInfo;
		hitItem: INTEGER;
		newRows: INTEGER;
		newCols: INTEGER;
		percent: INTEGER;
		doc: TImageDocument;
		vPlacement: INTEGER;
		hPlacement: INTEGER;
		aBWDialog: TBWDialog;
		rowsField: TFixedText;
		colsField: TFixedText;
		constrainBox: TCheckBox;
		percentField: TFixedText;
		placeCluster: TRadioCluster;
		resizeCluster: TRadioCluster;
		aResizeCommand: TResizeCommand;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	FUNCTION Constrain (newRows, oldRows, oldCols: INTEGER): INTEGER;
		BEGIN
		Constrain := Min (Max ((oldCols * ORD4 (newRows) + BSR (oldRows, 1))
								DIV oldRows, 1), kMaxCoord)
		END;

	PROCEDURE SetItem (anItem: INTEGER; state: BOOLEAN);

		VAR
			itemBox: Rect;
			itemType: INTEGER;
			itemHandle: Handle;

		BEGIN
		GetDItem (aBWDialog.fDialogPtr, anItem,
				  itemType, itemHandle, itemBox);
		SetCtlValue (ControlHandle (itemHandle), ORD (state))
		END;

	PROCEDURE SetResizeBy (setEdit: BOOLEAN);

		BEGIN

		SetItem (kResizeByItem, TRUE);
		SetItem (kResizeToItem, FALSE);

		resizeCluster.fChosenItem := kResizeByItem;

		IF percentField.ParseValue THEN
			BEGIN
			percent := percentField.fValue;
			newRows := (doc.fRows * ORD4 (percent) + 99) DIV 100;
			newCols := (doc.fCols * ORD4 (percent) + 99) DIV 100;
			END
		ELSE
			BEGIN
			newRows := 0;
			newCols := 0
			END;

		IF newRows <> 0 THEN
			BEGIN
			colsField.StuffValue (newCols);
			rowsField.StuffValue (newRows)
			END
		ELSE
			BEGIN
			colsField.StuffString ('');
			rowsField.StuffString ('')
			END;

		IF setEdit THEN
			aBWDialog.SetEditSelection (kPercentItem)

		END;

	PROCEDURE SetResizeTo (setEdit: BOOLEAN);

		BEGIN

		SetItem (kResizeByItem, FALSE);
		SetItem (kResizeToItem, TRUE);

		resizeCluster.fChosenItem := kResizeToItem;

		percentField.StuffString ('');

		IF setEdit THEN
			aBWDialog.SetEditSelection (kColsItem)

		END;

	PROCEDURE MyItemHandling (anItem: INTEGER; VAR done: BOOLEAN);

		VAR
			cEst: INTEGER;
			rEst: INTEGER;

		BEGIN

		StdItemHandling (anItem, done);

			CASE anItem OF

			kResizeByItem:
				SetResizeBy (TRUE);

			kResizeToItem:
				SetResizeTo (TRUE);

			kPercentItem:
				SetResizeBy (FALSE);

			kRowsItem:
				BEGIN
				SetResizeTo (FALSE);
				IF constrainBox.fChecked THEN
					IF rowsField.ParseValue & (rowsField.fValue <> 0) THEN
						BEGIN
						newCols := Constrain (rowsField.fValue,
											  doc.fRows, doc.fCols);
						colsField.StuffValue (newCols)
						END
					ELSE
						colsField.StuffString ('')
				END;

			kColsItem:
				BEGIN
				SetResizeTo (FALSE);
				IF constrainBox.fChecked THEN
					IF colsField.ParseValue & (colsField.fValue <> 0) THEN
						BEGIN
						newRows := Constrain (colsField.fValue,
											  doc.fCols, doc.fRows);
						rowsField.StuffValue (newRows)
						END
					ELSE
						rowsField.StuffString ('')
				END;

			kConstrainItem:
				IF constrainBox.fChecked THEN
					BEGIN

					SetResizeTo (resizeCluster.fChosenItem <> kResizeToItem);

					IF colsField.ParseValue & rowsField.ParseValue THEN
						BEGIN

						newRows := rowsField.fValue;
						newCols := colsField.fValue;

						IF (newRows <> 0) OR (newCols <> 0) THEN
							BEGIN

							IF newRows = 0 THEN newRows := kMaxCoord;
							IF newCols = 0 THEN newCols := kMaxCoord;

							rEst := Constrain (newCols, doc.fCols, doc.fRows);
							cEst := Constrain (newRows, doc.fRows, doc.fCols);

							IF newCols > cEst THEN
								BEGIN
								colsField.StuffValue (cEst);
								aBWDialog.SetEditSelection (kColsItem)
								END

							ELSE IF newRows > rEst THEN
								BEGIN
								rowsField.StuffValue (rEst);
								aBWDialog.SetEditSelection (kRowsItem)
								END

							END

						END

					END

			END

		END;

	PROCEDURE ForceSize (rows, cols: INTEGER);

		VAR
			cEst: INTEGER;
			rEst: INTEGER;

		BEGIN

		IF constrainBox.fChecked THEN
			BEGIN

			rEst := Constrain (cols, doc.fCols, doc.fRows);
			cEst := Constrain (rows, doc.fRows, doc.fCols);

			IF cols > cEst THEN
				cols := cEst

			ELSE IF rows > rEst THEN
				rows := rEst

			END;

		rowsField.StuffValue (rows);
		colsField.StuffValue (cols);

		SetResizeTo (TRUE)

		END;

	BEGIN

	doc := TImageDocument (view.fDocument);

	NumToString (doc.fCols, s1);
	GetIndString (ss, kPixelsID, 1 + ORD (doc.fCols <> 1));
	INSERT (ss, s1, LENGTH (s1) + 1);

	NumToString (doc.fRows, s2);
	GetIndString (ss, kPixelsID, 1 + ORD (doc.fRows <> 1));
	INSERT (ss, s2, LENGTH (s2) + 1);

	ParamText (s1, s2, '', '');

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kResizeID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	resizeCluster := aBWDialog.DefineRadioCluster
			(kResizeByItem, kResizeToItem, kResizeByItem);

	percentField := aBWDialog.DefineFixedText
					(kPercentItem, 0, TRUE, TRUE, 1, Min (10000,
					 kMaxCoord * ORD4 (100) DIV Max (doc.fRows, doc.fCols)));

	colsField := aBWDialog.DefineFixedText
				 (kColsItem, 0, TRUE, TRUE, 1, kMaxCoord);

	rowsField := aBWDialog.DefineFixedText
				 (kRowsItem, 0, TRUE, TRUE, 1, kMaxCoord);

	constrainBox := aBWDialog.DefineCheckBox (kConstrainItem, FALSE);

	placeCluster := aBWDialog.DefineRadioCluster
					(kFirstPlace, kLastPlace, kFirstPlace);

	aBWDialog.SetEditSelection (kPercentItem);

		REPEAT

			REPEAT

			aBWDialog.TalkToUser (hitItem, MyItemHandling);

				CASE hitItem OF

				cancel:
					Failure (0, 0);

				kWindowItem:
					BEGIN
					r := view.fFrame.fContentRect;
					ForceSize (r.bottom - r.top,
							   r.right - r.left)
					END;

				kScreenItem:
					ForceSize (screenBits.bounds.bottom,
							   screenBits.bounds.right)

				END

			UNTIL hitItem = ok;

		IF resizeCluster.fChosenItem = kResizeByItem THEN
			BEGIN

			percent := percentField.fValue;

			IF (percent = 0) OR (percent = 100) THEN Failure (0, 0);

			newRows := (doc.fRows * ORD4 (percent) + 99) DIV 100;
			newCols := (doc.fCols * ORD4 (percent) + 99) DIV 100;

			END

		ELSE
			BEGIN

			newRows := rowsField.fValue;
			newCols := colsField.fValue;

			IF (newCols = 0) AND (newRows = 0) THEN Failure (0, 0);

			IF newRows = 0 THEN
				newRows := Constrain (newCols, doc.fCols, doc.fRows);

			IF newCols = 0 THEN
				newCols := Constrain (newRows, doc.fRows, doc.fCols)

			END;

			CASE placeCluster.fChosenItem - kFirstPlace OF

			0:	BEGIN
				vPlacement := 0;
				hPlacement := 0
				END;

			1:	BEGIN
				vPlacement := 2;
				hPlacement := 2
				END;

			2:	BEGIN
				vPlacement := 1;
				hPlacement := 1
				END;

			3:	BEGIN
				vPlacement := 1;
				hPlacement := 3
				END;

			4:	BEGIN
				vPlacement := 3;
				hPlacement := 1
				END;

			5:	BEGIN
				vPlacement := 3;
				hPlacement := 3
				END

			END;

		IF ((vPlacement = 0) OR (newRows >= doc.fRows)) AND
		   ((hPlacement = 0) OR (newCols >= doc.fCols)) THEN LEAVE;

		UNTIL (BWAlert (kWillCropID, 0, TRUE) = ok);

	Success (fi);

	CleanUp (0, 0);

	IF (newRows = doc.fRows) AND
	   (newCols = doc.fCols) THEN Failure (0, 0);

	NEW (aResizeCommand);
	FailNil (aResizeCommand);

	aResizeCommand.IResizeCommand (cSizeChange, view,
								   newRows, newCols,
								   vPlacement, hPlacement);

	DoResizeImage := aResizeCommand

	END;

{*****************************************************************************}

{$S AResize}

FUNCTION AutoResample (VAR frequency: FixedScaled;
					   VAR resolution: Fixed): BOOLEAN;

	CONST
		kDialogID	 = 1062;
		kHookItem	 = 3;
		kResItem	 = 4;
		kFreqItem	 = 6;
		kQualityItem = 8;

	VAR
		fi: FailInfo;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		resUnit: TUnitSelector;
		freqUnit: TUnitSelector;
		qualityCluster: TRadioCluster;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free;
		EXIT (AutoResample)
		END;

	BEGIN

	AutoResample := FALSE;

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	resUnit := aBWDialog.DefinePrintResUnit (kResItem,
											 gPrinterResolution.scale);

	resUnit.StuffFixed (0, gPrinterResolution.value);

	freqUnit := aBWDialog.DefineFreqUnit (kFreqItem, 1, frequency.scale);

	freqUnit.StuffFixed (0, frequency.value);

	qualityCluster := aBWDialog.DefineRadioCluster
					  (kQualityItem, kQualityItem + 2,
					   kQualityItem + gPrintQuality);

	aBWDialog.SetEditSelection (kResItem);

	aBWDialog.TalkToUser (hitItem, StdItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	gPrinterResolution.value := resUnit.GetFixed (0);
	gPrinterResolution.scale := resUnit.fPick;

	frequency.value := freqUnit.GetFixed (0);
	frequency.scale := freqUnit.fPick;

	gPrintQuality := qualityCluster.fChosenItem - kQualityItem;

	Success (fi);

	aBWDialog.Free;

		CASE gPrintQuality OF

		0:	resolution := Min (frequency.value, 72 * $10000);

		1:	resolution := Min (frequency.value * 3 DIV 2,
							   gPrinterResolution.value DIV 4);

		2:	resolution := Min (frequency.value * 2,
							   gPrinterResolution.value DIV 3)

		END;

	AutoResample := TRUE

	END;

{*****************************************************************************}

{$S AResize}

PROCEDURE DrawResampledSize (theDialog: DialogPtr; itemNo: INTEGER);

	VAR
		s: Str255;

	BEGIN

	IF gResampledSize = 0 THEN
		EraseRect (gResampledSizeRect)
	ELSE
		BEGIN
		NumToString (gResampledSize, s);
		INSERT ('K', s, LENGTH (s) + 1);
		TextBox (@s[1], LENGTH (s), gResampledSizeRect, teJustLeft)
		END

	END;

{*****************************************************************************}

{$S AResize}

FUNCTION DoResampleImage (view: TImageView): TCommand;

	CONST
		kDialogID	= 1061;
		kHookItem	= 3;
		kAutoItem	= 4;
		kWidthItem	= 5;
		kHeightItem = 7;
		kResItem	= 9;
		kSizeItem	= 11;

	VAR
		s1: Str255;
		s2: Str255;
		s3: Str255;
		s4: Str255;
		fi: FailInfo;
		master: INTEGER;
		hitItem: INTEGER;
		newRows: INTEGER;
		newCols: INTEGER;
		itemType: INTEGER;
		itemHandle: Handle;
		inputRes: EXTENDED;
		doc: TImageDocument;
		widthScale: INTEGER;
		heightScale: INTEGER;
		aBWDialog: TBWDialog;
		resUnit: TUnitSelector;
		frequency: FixedScaled;
		resolution: FixedScaled;
		widthUnit: TUnitSelector;
		heightUnit: TUnitSelector;
		aResizeCommand: TResizeCommand;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	PROCEDURE Propogate (item: INTEGER);

		BEGIN

		IF item = kWidthItem THEN
			BEGIN
			IF widthUnit . fEditItem [0] . ParseValue THEN
				heightUnit.StuffFloat (0, widthUnit.GetFloat (0) /
										  doc.fCols * doc.fRows)
			END
		ELSE
			IF heightUnit . fEditItem [0] . ParseValue THEN
				widthUnit.StuffFloat (0, heightUnit.GetFloat (0) /
										 doc.fRows * doc.fCols)

		END;

	PROCEDURE UpdateSize;

		VAR
			scale: EXTENDED;
			newSize: LONGINT;
			longSize: Int64Bit;

		BEGIN

		newSize := 0;

		IF widthUnit  . fEditItem [0] . ParseValue AND
		   heightUnit . fEditItem [0] . ParseValue AND
		   resUnit	  . fEditItem [0] . ParseValue THEN
			BEGIN

			resolution.value := resUnit.GetFixed (0);
			resolution.scale := resUnit.fPick;

			scale := resolution.value / $10000;

			newRows := Max (1,
					   Min (kMaxCoord,
							ROUND (heightUnit.GetFloat (0) * scale)));

			newCols := Max (1,
					   Min (kMaxCoord,
							ROUND (widthUnit .GetFloat (0) * scale)));

			LongMul (ORD4 (newRows) * newCols, doc.fChannels, longSize);

			IF longSize.hiLong = 0 THEN
				newSize := (longSize.loLong + 1023) DIV 1024;

			IF newSize > 999999 THEN newSize := 0

			END;

		IF newSize <> gResampledSize THEN
			BEGIN
			gResampledSize := newSize;
			SetPort (aBWDialog.fDialogPtr);
			InvalRect (gResampledSizeRect)
			END

		END;

	PROCEDURE MyItemHandling (anItem: INTEGER; VAR done: BOOLEAN);

		BEGIN

		StdItemHandling (anItem, done);

			CASE anItem OF

			kWidthItem,
			kHeightItem:
				BEGIN
				master := anItem;
				Propogate (master);
				END;

			kWidthItem + 1:
				IF master = 0 THEN
					Propogate (kHeightItem)
				ELSE
					Propogate (master);

			kHeightItem + 1:
				IF master = 0 THEN
					Propogate (kWidthItem)
				ELSE
					Propogate (master);

			kResItem:
				master := 0

			END;

		UpdateSize

		END;

	BEGIN

	doc := TImageDocument (view.fDocument);

	WITH doc.fStyleInfo DO
		IF doc.fMode <> SeparationsCMYK THEN
			frequency := fHalftoneSpec.frequency
		ELSE
			BEGIN
			frequency.scale := fHalftoneSpecs [0] . frequency . scale;
			{$H-}
			frequency.value := Max (fHalftoneSpecs [0] . frequency . value,
							   Max (fHalftoneSpecs [1] . frequency . value,
							   Max (fHalftoneSpecs [2] . frequency . value,
									fHalftoneSpecs [3] . frequency . value)));
			{$H+}
			END;

	inputRes := doc.fStyleInfo.fResolution.value / $10000;

	MakeSizeString (doc, TRUE , s1);
	MakeSizeString (doc, FALSE, s2);
	MakeResString  (doc, FALSE, s3);

	gResampledSize := (ORD4 (doc.fChannels) * doc.fRows *
					   doc.fCols + 1023) DIV 1024;

	NumToString (gResampledSize, s4);
	INSERT ('K', s4, LENGTH (s4) + 1);

	ParamText (s1, s2, s3, s4);

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	GetDItem (aBWDialog.fDialogPtr, kSizeItem,
			  itemType, itemHandle, gResampledSizeRect);

	SetDItem (aBWDialog.fDialogPtr, kSizeItem,
			  itemType, Handle (@DrawResampledSize), gResampledSizeRect);

	widthUnit := aBWDialog.DefineSizeUnit (kWidthItem,
										   doc.fStyleInfo.fWidthUnit,
										   FALSE, FALSE, TRUE,
										   FALSE, TRUE);

	widthUnit.StuffFloat (0, doc.fCols / inputRes);

	heightUnit := aBWDialog.DefineSizeUnit (kHeightItem,
											doc.fStyleInfo.fHeightUnit,
											FALSE, FALSE, FALSE,
											FALSE, TRUE);

	heightUnit.StuffFloat (0, doc.fRows / inputRes);

	resUnit := aBWDialog.DefineResUnit (kResItem,
										doc.fStyleInfo.fResolution.scale, 0);

	resUnit.StuffFloat (0, inputRes);

	aBWDialog.SetEditSelection (kResItem);

	master := 0;

		REPEAT

		aBWDialog.TalkToUser (hitItem, MyItemHandling);

			CASE hitItem OF

			cancel:
				Failure (0, 0);

			kAutoItem:
				IF AutoResample (frequency, resolution.value) THEN
					BEGIN
					resUnit.StuffFixed (0, resolution.value);
					aBWDialog.SetEditSelection (kResItem)
					END

			END;

		UpdateSize

		UNTIL hitItem = ok;

	widthScale	:= widthUnit.fPick;
	heightScale := heightUnit.fPick;

	Success (fi);

	CleanUp (0, 0);

	IF (newRows = doc.fRows) AND
	   (newCols = doc.fCols) AND
	   (resolution.value = doc.fStyleInfo.fResolution.value) THEN
		Failure (0, 0);

	NEW (aResizeCommand);
	FailNil (aResizeCommand);

	aResizeCommand.IResizeCommand (cResampling, view, newRows, newCols, 0, 0);

	aResizeCommand.fNewStyle.fResolution := resolution;
	aResizeCommand.fNewStyle.fWidthUnit  := widthScale;
	aResizeCommand.fNewStyle.fHeightUnit := heightScale;

	DoResampleImage := aResizeCommand

	END;

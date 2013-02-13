{Photoshop version 1.0.1, file: URotate.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT URotate;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UBWDialog, UCommands, UResize, UProgress;

TYPE

	TFlipImageCommand = OBJECT (TBufferCommand)

		fVertical: BOOLEAN;
		fHorizontal: BOOLEAN;

		PROCEDURE TFlipImageCommand.IFlipImageCommand
				(view: TImageView; horizontal, vertical: BOOLEAN);

		PROCEDURE TFlipImageCommand.DoIt; OVERRIDE;

		PROCEDURE TFlipImageCommand.UndoIt; OVERRIDE;

		PROCEDURE TFlipImageCommand.RedoIt; OVERRIDE;

		END;

	TRotateImageCommand = OBJECT (TBufferCommand)

		fAngle: INTEGER;

		PROCEDURE TRotateImageCommand.IRotateImageCommand
				(view: TImageView; angle: INTEGER);

		PROCEDURE TRotateImageCommand.DoIt; OVERRIDE;

		PROCEDURE TRotateImageCommand.UndoIt; OVERRIDE;

		PROCEDURE TRotateImageCommand.RedoIt; OVERRIDE;

		END;

	TFlipFloatCommand = OBJECT (TFloatCommand)

		fVertical: BOOLEAN;
		fHorizontal: BOOLEAN;

		PROCEDURE TFlipFloatCommand.IFlipFloatCommand
				(view: TImageView; horizontal, vertical: BOOLEAN);

		PROCEDURE TFlipFloatCommand.DoIt; OVERRIDE;

		PROCEDURE TFlipFloatCommand.UndoIt; OVERRIDE;

		PROCEDURE TFlipFloatCommand.RedoIt; OVERRIDE;

		END;

	TRotateFloatCommand = OBJECT (TFloatCommand)

		fAngle: INTEGER;

		PROCEDURE TRotateFloatCommand.IRotateFloatCommand
				(view: TImageView; angle: INTEGER);

		PROCEDURE TRotateFloatCommand.DoIt; OVERRIDE;

		PROCEDURE TRotateFloatCommand.UndoIt; OVERRIDE;

		PROCEDURE TRotateFloatCommand.RedoIt; OVERRIDE;

		END;

	TEffectsCommand = OBJECT (TFloatCommand)

		fMode: INTEGER;

		fSrcRect: Rect;
		fDstRect: Rect;
		fMidRect: Rect;

		fComplex: BOOLEAN;

		fRecycled: BOOLEAN;

		fAnother: BOOLEAN;

		fCorner: INTEGER;

		fChangeCount: LONGINT;

		fOldCorners: TCornerList;
		fNewCorners: TCornerList;
		fLastCorners: TCornerList;
		fBaseCorners: TCornerList;

		PROCEDURE TEffectsCommand.IEffectsCommand (itsCommand: INTEGER;
												   view: TImageView;
												   downPoint: Point);

		PROCEDURE TEffectsCommand.Recycle (view: TImageView;
										   downPoint: Point);

		PROCEDURE TEffectsCommand.Free; OVERRIDE;

		PROCEDURE TEffectsCommand.TrackConstrain
				(anchorPoint, previousPoint: Point;
				 VAR nextPoint: Point); OVERRIDE;

		PROCEDURE TEffectsCommand.TrackFeedback
				(anchorPoint, nextPoint: Point;
				 turnItOn, mouseDidMove: BOOLEAN); OVERRIDE;

		FUNCTION TEffectsCommand.TrackMouse
				(aTrackPhase: TrackPhase;
				 VAR anchorPoint, previousPoint, nextPoint: Point;
				 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

		PROCEDURE TEffectsCommand.ComputeNewCorners (delta: Point);

		PROCEDURE TEffectsCommand.CompDstRect;

		PROCEDURE TEffectsCommand.DoEffect (srcArray: TVMArray;
											dstArray: TVMArray;
											sample: BOOLEAN;
											background: INTEGER);

		FUNCTION TEffectsCommand.TestAnother: BOOLEAN;

		PROCEDURE TEffectsCommand.DoIt; OVERRIDE;

		PROCEDURE TEffectsCommand.SwapIt (undo: BOOLEAN);

		PROCEDURE TEffectsCommand.UndoIt; OVERRIDE;

		PROCEDURE TEffectsCommand.RedoIt; OVERRIDE;

		PROCEDURE TEffectsCommand.Commit; OVERRIDE;

		END;

	TResizeEffect = OBJECT (TEffectsCommand)

		PROCEDURE TResizeEffect.IResizeEffect (view: TImageView;
											   downPoint: Point);

		PROCEDURE TResizeEffect.ComputeNewCorners (delta: Point); OVERRIDE;

		PROCEDURE TResizeEffect.DoEffect (srcArray: TVMArray;
										  dstArray: TVMArray;
										  sample: BOOLEAN;
										  background: INTEGER); OVERRIDE;

		END;

	TRotateEffect = OBJECT (TEffectsCommand)

		fAngle: INTEGER;

		fRowRadius: EXTENDED;
		fColRadius: EXTENDED;

		fCenterRow: EXTENDED;
		fCenterCol: EXTENDED;

		fBaseAngle: EXTENDED;

		PROCEDURE TRotateEffect.IRotateEffect (view: TImageView;
											   downPoint: Point);

		PROCEDURE TRotateEffect.Recycle (view: TImageView;
										 downPoint: Point); OVERRIDE;

		PROCEDURE TRotateEffect.ComputeBaseAngle;

		PROCEDURE TRotateEffect.ComputeNewCorners (delta: Point); OVERRIDE;

		PROCEDURE TRotateEffect.CompDstRect; OVERRIDE;

		PROCEDURE TRotateEffect.DoEffect (srcArray: TVMArray;
										  dstArray: TVMArray;
										  sample: BOOLEAN;
										  background: INTEGER); OVERRIDE;

		END;

	TSkewEffect = OBJECT (TEffectsCommand)

		fCoupled: BOOLEAN;

		fHaveAxis: BOOLEAN;

		fVertical: BOOLEAN;

		PROCEDURE TSkewEffect.ISkewEffect (view: TImageView;
										   downPoint: Point);

		PROCEDURE TSkewEffect.Recycle (view: TImageView;
									   downPoint: Point); OVERRIDE;

		PROCEDURE TSkewEffect.ComputeNewCorners (delta: Point); OVERRIDE;

		PROCEDURE TSkewEffect.DoEffect (srcArray: TVMArray;
										dstArray: TVMArray;
										sample: BOOLEAN;
										background: INTEGER); OVERRIDE;

		END;

	TPerspectiveTable = OBJECT (TResizeTable)

		PROCEDURE TPerspectiveTable.IPerspectiveTable (oldSize: INTEGER;
													   newSize: INTEGER;
													   sample: BOOLEAN;
													   a: EXTENDED);

		END;

	TPerspectiveEffect = OBJECT (TEffectsCommand)

		PROCEDURE TPerspectiveEffect.IPerspectiveEffect (view: TImageView;
														 downPoint: Point);

		PROCEDURE TPerspectiveEffect.ComputeNewCorners (delta: Point); OVERRIDE;

		PROCEDURE TPerspectiveEffect.DoEffect (srcArray: TVMArray;
											   dstArray: TVMArray;
											   sample: BOOLEAN;
											   background: INTEGER); OVERRIDE;

		END;

	TDistortEffect = OBJECT (TEffectsCommand)

		PROCEDURE TDistortEffect.IDistortEffect (view: TImageView;
												 downPoint: Point);

		PROCEDURE TDistortEffect.ComputeNewCorners (delta: Point); OVERRIDE;

		PROCEDURE TDistortEffect.DoEffect (srcArray: TVMArray;
										   dstArray: TVMArray;
										   sample: BOOLEAN;
										   background: INTEGER); OVERRIDE;

		END;

PROCEDURE InitRotations;

PROCEDURE DoTransposeArray (srcArray: TVMArray;
							dstArray: TVMArray;
							horizontal: BOOLEAN;
							vertical: BOOLEAN);

FUNCTION DoFlipCommand (view: TImageView;
						horizontal, vertical: BOOLEAN): TCommand;

FUNCTION DoRotateCommand (view: TImageView; angle: INTEGER): TCommand;

FUNCTION DoRotateArbitraryCommand (view: TImageView): TCommand;

FUNCTION SetEffectMode (view: TImageView; mode: INTEGER): TCommand;

FUNCTION DoEffectsCommand (view: TImageView; downPoint: Point): TCommand;

IMPLEMENTATION

{$I UAssembly.a.inc}
{$I URotate.a.inc}

VAR
	gLastCCW  : BOOLEAN;
	gLastAngle: INTEGER;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitRotations;

	BEGIN

	gLastCCW   := FALSE;
	gLastAngle := 0

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE DoFlipArray (srcArray: TVMArray;
					   dstArray: TVMArray;
					   horizontal: BOOLEAN;
					   vertical: BOOLEAN);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		rows: INTEGER;
		cols: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		IF dstPtr <> NIL THEN dstArray.DoneWithPtr;

		srcArray.Flush;
		dstArray.Flush

		END;

	BEGIN

	dstPtr := NIL;

	CatchFailures (fi, CleanUp);

	rows := srcArray.fBlockCount;
	cols := srcArray.fLogicalSize;

	FOR row := 0 TO rows - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row, rows);

		dstPtr := dstArray.NeedPtr (row, row, TRUE);

		IF vertical THEN
			srcPtr := srcArray.NeedPtr (rows - 1 - row,
										rows - 1 - row, FALSE)
		ELSE
			srcPtr := srcArray.NeedPtr (row, row, FALSE);

		BlockMove (srcPtr, dstPtr, cols);

		IF horizontal THEN
			DoReverseBytes (dstPtr, cols);

		srcArray.DoneWithPtr;

		dstArray.DoneWithPtr;
		dstPtr := NIL

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE DoTransposeArray (srcArray: TVMArray;
							dstArray: TVMArray;
							horizontal: BOOLEAN;
							vertical: BOOLEAN);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		col: INTEGER;
		rows: INTEGER;
		cols: INTEGER;
		buffer: Handle;
		saveLimit: INTEGER;
		bufferRow: INTEGER;
		bufferRows: INTEGER;
		rowsPerBuffer: INTEGER;
		bufferCounter: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		srcArray.Flush;
		dstArray.Flush;

		IF buffer <> NIL THEN
			FreeLargeHandle (buffer);

		gVMMinPageLimit := saveLimit

		END;

	BEGIN

	MoveHands (TRUE);

	buffer:= NIL;
	saveLimit := gVMMinPageLimit;

	CatchFailures (fi, CleanUp);

	gVMMinPageLimit := 1;

	rows := dstArray.fBlockCount;
	cols := dstArray.fLogicalSize;

	rowsPerBuffer := Min (rows, VMCanReserve DIV cols);

	IF rowsPerBuffer < 1 THEN Failure (1, 0);

	buffer := NewLargeHandle (rowsPerBuffer * ORD4 (cols));

	FOR bufferCounter := 0 TO (rows - 1) DIV rowsPerBuffer DO
		BEGIN

		bufferRow  := bufferCounter * rowsPerBuffer;
		bufferRows := Min (rows - bufferRow, rowsPerBuffer);

		FOR col := 0 TO cols - 1 DO
			BEGIN

			MoveHands (TRUE);

			srcPtr := srcArray.NeedPtr (col, col, FALSE);

			IF vertical THEN
				DoStepCopyBytes (Ptr (ORD4 (srcPtr) + rows - 1 - bufferRow),
								 Ptr (ORD4 (buffer^) + col),
								 bufferRows,
								 -1,
								 cols)
			ELSE
				DoStepCopyBytes (Ptr (ORD4 (srcPtr) + bufferRow),
								 Ptr (ORD4 (buffer^) + col),
								 bufferRows,
								 1,
								 cols);

			srcArray.DoneWithPtr

			END;

		srcArray.Flush;

		FOR row := bufferRow TO bufferRow + bufferRows - 1 DO
			BEGIN

			MoveHands (TRUE);

			UpdateProgress (row, rows);

			dstPtr := dstArray.NeedPtr (row, row, TRUE);

			srcPtr := Ptr (ORD4 (buffer^) + cols * ORD4 (row - bufferRow));

			BlockMove (srcPtr, dstPtr, cols);

			IF horizontal THEN
				DoReverseBytes (dstPtr, cols);

			dstArray.DoneWithPtr

			END;

		dstArray.Flush

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE DoCustomSkewArray (srcArray: TVMArray;
							 dstArray: TVMArray;
							 PROCEDURE GetScaleOffset (row: INTEGER;
													   VAR scale: EXTENDED;
													   VAR offset: EXTENDED);
							 sample: BOOLEAN;
							 background: INTEGER);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		base: LONGINT;
		step: LONGINT;
		scale: EXTENDED;
		method: INTEGER;
		offset: EXTENDED;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		IF srcPtr <> NIL THEN srcArray.DoneWithPtr;

		srcArray.Flush;
		dstArray.Flush

		END;

	BEGIN

	IF sample THEN
		method := 0
	ELSE
		method := gPreferences.fInterpolate;

	srcPtr := NIL;

	CatchFailures (fi, CleanUp);

	FOR row := 0 TO srcArray.fBlockCount - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row, srcArray.fBlockCount);

		GetScaleOffset (row, scale, offset);

		srcPtr := srcArray.NeedPtr (row, row, FALSE);
		dstPtr := dstArray.NeedPtr (row, row, TRUE);

		IF ABS (scale) >= 0.01 THEN
			BEGIN

			base := ROUND (-256 * offset / scale);

			step := ROUND (16777216 / scale);

			DoSkewRow (srcPtr,
					   dstPtr,
					   srcArray.fLogicalSize,
					   dstArray.fLogicalSize,
					   base,
					   step,
					   method,
					   background)

			END

		ELSE IF background = -1 THEN
			DoSetBytes (dstPtr, dstArray.fLogicalSize, srcPtr^)

		ELSE
			DoSetBytes (dstPtr, dstArray.fLogicalSize, background);

		dstArray.DoneWithPtr;
		srcArray.DoneWithPtr;

		srcPtr := NIL

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE DoSkewArray (srcArray: TVMArray;
					   dstArray: TVMArray;
					   offset1: EXTENDED;
					   offset2: EXTENDED;
					   scale1: EXTENDED;
					   scale2: EXTENDED;
					   sample: BOOLEAN;
					   background: INTEGER);

	VAR
		deltaScale: EXTENDED;
		deltaOffset: EXTENDED;

	PROCEDURE GetScaleOffset (row: INTEGER;
							  VAR scale: EXTENDED;
							  VAR offset: EXTENDED);

		BEGIN
		IF row = 0 THEN
			BEGIN
			scale  := scale1;
			offset := offset1
			END
		ELSE
			BEGIN
			scale  := scale  + deltaScale;
			offset := offset + deltaOffset
			END
		END;

	BEGIN

	IF srcArray.fBlockCount = 1 THEN
		BEGIN
		deltaScale	:= 0;
		deltaOffset := 0
		END
	ELSE
		BEGIN
		deltaScale	:= (scale2	- scale1 ) / (srcArray.fBlockCount - 1);
		deltaOffset := (offset2 - offset1) / (srcArray.fBlockCount - 1)
		END;

	DoCustomSkewArray (srcArray,
					   dstArray,
					   GetScaleOffset,
					   sample,
					   background)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE NormalizeAngle (VAR angle: INTEGER;
						  VAR transpose: BOOLEAN;
						  VAR horizontal: BOOLEAN;
						  VAR vertical: BOOLEAN);

	BEGIN

	IF ABS (angle) > 1350 THEN
		BEGIN

		transpose  := TRUE;
		horizontal := TRUE;
		vertical   := TRUE;

		IF angle > 0 THEN
			angle := angle - 1800
		ELSE
			angle := angle + 1800

		END

	ELSE IF angle > 450 THEN
		BEGIN

		transpose  := FALSE;
		horizontal := FALSE;
		vertical   := TRUE;

		angle := angle - 900

		END

	ELSE IF angle < -450 THEN
		BEGIN

		transpose  := FALSE;
		horizontal := TRUE;
		vertical   := FALSE;

		angle := angle + 900

		END

	ELSE
		BEGIN

		transpose  := TRUE;
		horizontal := FALSE;
		vertical   := FALSE

		END

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE ComputeRotatedSize (rows: INTEGER;
							  cols: INTEGER;
							  angle: INTEGER;
							  VAR height: INTEGER;
							  VAR width: INTEGER);

	VAR
		A: EXTENDED;
		B: EXTENDED;
		theta: EXTENDED;
		vertical: BOOLEAN;
		cosTheta: EXTENDED;
		sinTheta: EXTENDED;
		transpose: BOOLEAN;
		horizontal: BOOLEAN;

	BEGIN

	NormalizeAngle (angle, transpose, horizontal, vertical);

	IF transpose THEN
		BEGIN
		A := rows - 1;
		B := cols - 1
		END
	ELSE
		BEGIN
		A := cols - 1;
		B := rows - 1
		END;

	theta := ABS (angle) * (pi / 1800);

	cosTheta := COS (theta);
	sinTheta := SIN (theta);

	height := TRUNC (A * cosTheta + B * sinTheta) + 2;
	width  := TRUNC (A * sinTheta + B * cosTheta) + 2;

	IF (height > kMaxCoord) OR (width > kMaxCoord) THEN
		Failure (errResultTooBig, 0)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE DoRotateArray (srcArray: TVMArray;
						 dstArray: TVMArray;
						 angle: INTEGER;
						 sample: BOOLEAN;
						 background: INTEGER);

	VAR
		A: EXTENDED;
		B: EXTENDED;
		fi: FailInfo;
		theta: EXTENDED;
		delta: EXTENDED;
		delta2: EXTENDED;
		buffer1: TVMArray;
		buffer2: TVMArray;
		vertical: BOOLEAN;
		cosTheta: EXTENDED;
		sinTheta: EXTENDED;
		transpose: BOOLEAN;
		horizontal: BOOLEAN;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (buffer1);
		FreeObject (buffer2)
		END;

	BEGIN

	MoveHands (TRUE);

	buffer1 := NIL;
	buffer2 := NIL;

	CatchFailures (fi, CleanUp);

	NormalizeAngle (angle, transpose, horizontal, vertical);

	StartTask (1/20);

	IF transpose THEN
		BEGIN

		buffer1 := NewVMArray (srcArray.fLogicalSize,
							   srcArray.fBlockCount, 1);

		DoTransposeArray (srcArray, buffer1, horizontal, vertical)

		END

	ELSE
		BEGIN

		buffer1 := NewVMArray (srcArray.fBlockCount,
							   srcArray.fLogicalSize, 1);

		DoFlipArray (srcArray, buffer1, horizontal, vertical)

		END;

	FinishTask;

	A := buffer1.fLogicalSize - 1;
	B := buffer1.fBlockCount  - 1;

	theta := ABS (angle) * (pi / 1800);

	cosTheta := COS (theta);
	sinTheta := SIN (theta);

	delta := B * sinTheta;

	buffer2 := NewVMArray (buffer1.fBlockCount, dstArray.fBlockCount, 1);

	StartTask (9/19);

	IF angle > 0 THEN
		DoSkewArray (buffer1,
					 buffer2,
					 0.0,
					 delta,
					 cosTheta,
					 cosTheta,
					 sample,
					 background)
	ELSE
		DoSkewArray (buffer1,
					 buffer2,
					 delta,
					 0.0,
					 cosTheta,
					 cosTheta,
					 sample,
					 background);

	FinishTask;

	buffer1.Free;
	buffer1 := NIL;

	buffer1 := NewVMArray (buffer2.fLogicalSize, buffer2.fBlockCount, 1);

	StartTask (1/10);

	DoTransposeArray (buffer2, buffer1, FALSE, FALSE);

	FinishTask;

	buffer2.Free;
	buffer2 := NIL;

	delta := A * sinTheta;

	delta2 := delta - (dstArray.fBlockCount - 1) * sinTheta / cosTheta;

	IF angle > 0 THEN
		DoSkewArray (buffer1,
					 dstArray,
					 delta,
					 delta2,
					 1.0 / cosTheta,
					 1.0 / cosTheta,
					 sample,
					 background)
	ELSE
		DoSkewArray (buffer1,
					 dstArray,
					 delta2,
					 delta,
					 1.0 / cosTheta,
					 1.0 / cosTheta,
					 sample,
					 background);

	buffer1.Free;
	buffer1 := NIL;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TFlipImageCommand.IFlipImageCommand (view: TImageView;
											   horizontal, vertical: BOOLEAN);

	BEGIN

	fVertical  := vertical;
	fHorizontal := horizontal;

	IF horizontal AND vertical THEN
		IBufferCommand (cRotation, view)
	ELSE
		IBufferCommand (cFlip, view)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TFlipImageCommand.DoIt; OVERRIDE;

	VAR
		fi: FailInfo;
		channel: INTEGER;
		aVMArray: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress
		END;

	BEGIN

	FOR channel := 0 TO fDoc.fChannels - 1 DO
		BEGIN
		aVMArray := NewVMArray (fDoc.fRows,
								fDoc.fCols,
								fDoc.Interleave (channel));
		fBuffer [channel] := aVMArray
		END;

	CommandProgress (fCmdNumber);

	CatchFailures (fi, CleanUp);

	FOR channel := 0 TO fDoc.fChannels - 1 DO
		BEGIN
		StartTask (1 / (fDoc.fChannels - channel));
		DoFlipArray (fDoc.fData [channel],
					 fBuffer [channel],
					 fHorizontal,
					 fVertical);
		FinishTask
		END;

	Success (fi);

	CleanUp (0, 0);

	UndoIt

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TFlipImageCommand.UndoIt; OVERRIDE;

	PROCEDURE FixView (view: TImageView);
		BEGIN
		view.fFrame.ForceRedraw
		END;

	BEGIN

	fDoc.DeSelect (FALSE);

	SwapAllChannels;

	fDoc.fViewList.Each (FixView)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TFlipImageCommand.RedoIt; OVERRIDE;

	BEGIN
	UndoIt
	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TRotateImageCommand.IRotateImageCommand (view: TImageView;
												   angle: INTEGER);

	BEGIN

	fAngle := angle;

	IBufferCommand (cRotation, view)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TRotateImageCommand.DoIt; OVERRIDE;

	VAR
		fi: FailInfo;
		width: INTEGER;
		height: INTEGER;
		channel: INTEGER;
		aVMArray: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress
		END;

	BEGIN

	MoveHands (TRUE);

	IF ABS (fAngle) = 900 THEN
		BEGIN
		height := fDoc.fCols;
		width  := fDoc.fRows
		END
	ELSE
		ComputeRotatedSize (fDoc.fRows, fDoc.fCols, fAngle, height, width);

	FOR channel := 0 TO fDoc.fChannels - 1 DO
		BEGIN
		aVMArray := NewVMArray (height, width, fDoc.Interleave (channel));
		fBuffer [channel] := aVMArray
		END;

	CommandProgress (fCmdNumber);

	CatchFailures (fi, CleanUp);

	FOR channel := 0 TO fDoc.fChannels - 1 DO
		BEGIN

		StartTask (1 / (fDoc.fChannels - channel));

		IF ABS (fAngle) = 900 THEN
			DoTransposeArray (fDoc.fData [channel],
							  fBuffer [channel],
							  fAngle = 900,
							  fAngle = -900)
		ELSE
			DoRotateArray (fDoc.fData [channel],
						   fBuffer [channel],
						   fAngle,
						   fDoc.fMode = IndexedColorMode,
						   fView.BackgroundByte (channel));

		FinishTask

		END;

	Success (fi);

	CleanUp (0, 0);

	UndoIt

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TRotateImageCommand.UndoIt; OVERRIDE;

	VAR
		sameSize: BOOLEAN;

	PROCEDURE FixView (view: TImageView);
		BEGIN
		IF sameSize THEN
			view.fFrame.ForceRedraw
		ELSE
			BEGIN
			view.AdjustExtent;
			SetTopLeft (view, 0, 0)
			END
		END;

	BEGIN

	fDoc.DeSelect (FALSE);

	SwapAllChannels;

	sameSize := (fDoc.fRows = fDoc.fData [0] . fBlockCount) AND
				(fDoc.fCols = fDoc.fData [0] . fLogicalSize);

	fDoc.fRows := fDoc.fData [0] . fBlockCount;
	fDoc.fCols := fDoc.fData [0] . fLogicalSize;

	fDoc.fViewList.Each (FixView)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TRotateImageCommand.RedoIt; OVERRIDE;

	BEGIN
	UndoIt
	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TFlipFloatCommand.IFlipFloatCommand (view: TImageView;
											   horizontal, vertical: BOOLEAN);

	BEGIN

	fVertical  := vertical;
	fHorizontal := horizontal;

	IF horizontal AND vertical THEN
		IFloatCommand (cRotation, view)
	ELSE
		IFloatCommand (cFlip, view)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TFlipFloatCommand.DoIt; OVERRIDE;

	VAR
		fi: FailInfo;
		width: INTEGER;
		height: INTEGER;
		channel: INTEGER;
		channels: INTEGER;
		aVMArray: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress
		END;

	BEGIN

	MoveHands (TRUE);

	FloatSelection (FALSE);

	fExactFloat := FALSE;

	fFloatRect := fDoc.fFloatRect;

	width  := fFloatRect.right - fFloatRect.left;
	height := fFloatRect.bottom - fFloatRect.top;

	IF fDoc.fFloatMask <> NIL THEN
		BEGIN
		aVMArray := NewVMArray (height, width, 1);
		fFloatMask := aVMArray
		END;

	IF fDoc.fFloatChannel = kRGBChannels THEN
		channels := 3
	ELSE
		channels := 1;

	FOR channel := 0 TO channels - 1 DO
		BEGIN
		aVMArray := NewVMArray (height, width, channels - channel);
		fFloatData [channel] := aVMArray
		END;

	CommandProgress (fCmdNumber);

	CatchFailures (fi, CleanUp);

	IF fFloatMask <> NIL THEN
		BEGIN
		StartTask (1 / (channels + 1));
		DoFlipArray (fDoc.fFloatMask,
					 fFloatMask,
					 fHorizontal,
					 fVertical);
		FinishTask
		END;

	FOR channel := 0 TO channels - 1 DO
		BEGIN
		StartTask (1 / (channels - channel));
		DoFlipArray (fDoc.fFloatData [channel],
					 fFloatData [channel],
					 fHorizontal,
					 fVertical);
		FinishTask
		END;

	Success (fi);

	CleanUp (0, 0);

	UndoIt

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TFlipFloatCommand.UndoIt; OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	MoveHands (FALSE);

	fDoc.DeSelect (NOT fDoc.fSelectionFloating);

	CopyBelow (FALSE);

	SwapFloat;

	BlendFloat (FALSE);

	ComputeOverlap (r);
	fDoc.UpdateImageArea (r, FALSE, TRUE, fDoc.fFloatChannel);

	SelectFloat

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TFlipFloatCommand.RedoIt; OVERRIDE;

	BEGIN
	UndoIt
	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TRotateFloatCommand.IRotateFloatCommand (view: TImageView;
												   angle: INTEGER);

	BEGIN

	fAngle := angle;

	IFloatCommand (cRotation, view)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TRotateFloatCommand.DoIt; OVERRIDE;

	VAR
		r: Rect;
		rr: Rect;
		pt: Point;
		fi: FailInfo;
		width: INTEGER;
		height: INTEGER;
		channel: INTEGER;
		channels: INTEGER;
		aVMArray: TVMArray;
		tempArray: TVMArray;
		rotatedWidth: INTEGER;
		rotatedHeight: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress;
		FreeObject (tempArray)
		END;

	BEGIN

	MoveHands (TRUE);

	tempArray := NIL;

	CommandProgress (fCmdNumber);

	CatchFailures (fi, CleanUp);

	FloatSelection (FALSE);

	fExactFloat := FALSE;

	IF fDoc.fFloatChannel = kRGBChannels THEN
		channels := 3
	ELSE
		channels := 1;

	r := fDoc.fFloatRect;

	IF ABS (fAngle) <> 900 THEN
		BEGIN

		StartTask (1 / (channels + 1));

		IF fDoc.fFloatMask = NIL THEN
			BEGIN

			tempArray := NewVMArray (r.bottom - r.top,
									 r.right - r.left, 1);

			tempArray.SetBytes (255);

			ComputeRotatedSize (r.bottom - r.top,
								r.right - r.left,
								fAngle,
								rotatedHeight,
								rotatedWidth);

			aVMArray := NewVMArray (rotatedHeight, rotatedWidth, 1);

			fFloatMask := aVMArray;

			DoRotateArray (tempArray, fFloatMask, fAngle, FALSE, 0);

			fSwapMask := TRUE;

			SetRect (rr, 0, 0, rotatedWidth, rotatedHeight);

			tempArray.Free

			END

		ELSE
			BEGIN

			ComputeRotatedSize (fDoc.fFloatMask.fBlockCount,
								fDoc.fFloatMask.fLogicalSize,
								fAngle,
								rotatedHeight,
								rotatedWidth);

			tempArray := NewVMArray (rotatedHeight, rotatedWidth, 1);

			DoRotateArray (fDoc.fFloatMask, tempArray, fAngle, FALSE, 0);

			tempArray.FindBounds (rr);

			IF (rr.bottom - rr.top = rotatedHeight) AND
			   (rr.right - rr.left = rotatedWidth ) THEN

				fFloatMask := tempArray

			ELSE
				BEGIN

				aVMArray := tempArray.CopyRect (rr, 1);

				fFloatMask := aVMArray;

				tempArray.Free

				END

			END;

		tempArray := NIL;

		width  := rr.right - rr.left;
		height := rr.bottom - rr.top;

		FinishTask

		END

	ELSE
		BEGIN

		width  := r.bottom - r.top;
		height := r.right - r.left;

		IF fDoc.fFloatMask <> NIL THEN
			BEGIN

			aVMArray := NewVMArray (height, width, 1);

			fFloatMask := aVMArray;

			StartTask (1 / (channels + 1));

			DoTransposeArray (fDoc.fFloatMask,
							  fFloatMask,
							  fAngle = 900,
							  fAngle = -900);

			FinishTask

			END

		END;

	pt.h := BSR (r.left + ORD4 (r.right), 1);
	pt.v := BSR (r.top + ORD4 (r.bottom), 1);

	pt.h := pt.h - BSR (width, 1);
	pt.v := pt.v - BSR (height, 1);

	pt.h := Max (0, Min (pt.h, fDoc.fCols - width));
	pt.v := Max (0, Min (pt.v, fDoc.fRows - height));

	IF width > fDoc.fCols THEN
		pt.h := pt.h - BSR (width - fDoc.fCols - 1, 1);

	IF height > fDoc.fRows THEN
		pt.v := pt.v - BSR (height - fDoc.fRows - 1, 1);

	fFloatRect.topLeft := pt;
	fFloatRect.right   := pt.h + width;
	fFloatRect.bottom  := pt.v + height;

	IF (height <> r.bottom - r.top) OR (width <> r.right - r.left) THEN
		FOR channel := 0 TO channels - 1 DO
			BEGIN
			aVMArray := NewVMArray (height, width, 1);
			fFloatBelow [channel] := aVMArray
			END;

	FOR channel := 0 TO channels - 1 DO
		BEGIN
		aVMArray := NewVMArray (height, width, channels - channel);
		fFloatData [channel] := aVMArray
		END;

	FOR channel := 0 TO channels - 1 DO
		BEGIN

		StartTask (1 / (channels - channel));

		IF ABS (fAngle) <> 900 THEN

			IF (rr.bottom - rr.top = rotatedHeight) AND
			   (rr.right - rr.left = rotatedWidth ) THEN

				DoRotateArray (fDoc.fFloatData [channel],
							   fFloatData [channel],
							   fAngle,
							   fDoc.fMode = IndexedColorMode,
							   -1)

			ELSE
				BEGIN

				tempArray := NewVMArray (rotatedHeight, rotatedWidth, 1);

				DoRotateArray (fDoc.fFloatData [channel],
							   tempArray,
							   fAngle,
							   fDoc.fMode = IndexedColorMode,
							   -1);

				SetRect (r, 0, 0, rr.right - rr.left, rr.bottom - rr.top);

				tempArray.MoveRect (fFloatData [channel], rr, r);

				tempArray.Free;
				tempArray := NIL

				END

		ELSE
			DoTransposeArray (fDoc.fFloatData [channel],
							  fFloatData [channel],
							  fAngle = 900,
							  fAngle = -900);

		FinishTask

		END;

	Success (fi);

	FinishProgress;

	UndoIt

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TRotateFloatCommand.UndoIt; OVERRIDE;

	VAR
		r1: Rect;
		r2: Rect;

	BEGIN

	MoveHands (FALSE);

	fDoc.DeSelect (NOT fDoc.fSelectionFloating);

	ComputeOverlap (r1);

	CopyBelow (FALSE);

	SwapFloat;

	IF NOT EqualRect (fDoc.fFloatRect, fFloatRect) THEN
		CopyBelow (TRUE);

	BlendFloat (FALSE);

	ComputeOverlap (r2);

	UpdateRects (r1, r2, FALSE);

	SelectFloat

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TRotateFloatCommand.RedoIt; OVERRIDE;

	BEGIN
	UndoIt
	END;

{*****************************************************************************}

{$S ADoRotate}

FUNCTION DoFlipCommand (view: TImageView;
						horizontal, vertical: BOOLEAN): TCommand;

	VAR
		doc: TImageDocument;
		aFlipImageCommand: TFlipImageCommand;
		aFlipFloatCommand: TFlipFloatCommand;

	BEGIN

	doc := TImageDocument (view.fDocument);

	IF EmptyRect (doc.fSelectionRect) THEN
		BEGIN

		NEW (aFlipImageCommand);
		FailNil (aFlipImageCommand);

		aFlipImageCommand.IFlipImageCommand (view, horizontal, vertical);

		DoFlipCommand := aFlipImageCommand

		END

	ELSE
		BEGIN

		NEW (aFlipFloatCommand);
		FailNil (aFlipFloatCommand);

		aFlipFloatCommand.IFlipFloatCommand (view, horizontal, vertical);

		DoFlipCommand := aFlipFloatCommand

		END

	END;

{*****************************************************************************}

{$S ADoRotate}

FUNCTION DoRotateCommand (view: TImageView; angle: INTEGER): TCommand;

	VAR
		doc: TImageDocument;
		aRotateImageCommand: TRotateImageCommand;
		aRotateFloatCommand: TRotateFloatCommand;

	BEGIN

	IF angle = 1800 THEN
		DoRotateCommand := DoFlipCommand (view, TRUE, TRUE)

	ELSE
		BEGIN

		doc := TImageDocument (view.fDocument);

		IF EmptyRect (doc.fSelectionRect) THEN
			BEGIN

			NEW (aRotateImageCommand);
			FailNil (aRotateImageCommand);

			aRotateImageCommand.IRotateImageCommand (view, angle);

			DoRotateCommand := aRotateImageCommand

			END

		ELSE
			BEGIN

			NEW (aRotateFloatCommand);
			FailNil (aRotateFloatCommand);

			aRotateFloatCommand.IRotateFloatCommand (view, angle);

			DoRotateCommand := aRotateFloatCommand

			END

		END

	END;

{*****************************************************************************}

{$S ADoRotate}

FUNCTION DoRotateArbitraryCommand (view: TImageView): TCommand;

	CONST
		kDialogID  = 1005;
		kHookItem  = 3;
		kAngleItem = 4;
		kCWItem    = 5;
		kCCWItem   = 6;

	VAR
		fi: FailInfo;
		angle: INTEGER;
		hitItem: INTEGER;
		doc: TImageDocument;
		aBWDialog: TBWDialog;
		angleText: TFixedText;
		aRadioCluster: TRadioCluster;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	angleText := aBWDialog.DefineFixedText
				 (kAngleItem, 1, FALSE, FALSE, -3599, 3599);

	IF gLastAngle <> 0 THEN angleText.StuffValue (gLastAngle);

	aBWDialog.SetEditSelection (kAngleItem);

	aRadioCluster := aBWDialog.DefineRadioCluster (kCWItem, kCCWItem,
												   kCWItem + ORD (gLastCCW));

	aBWDialog.TalkToUser (hitItem, StdItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	gLastAngle := angleText.fValue;

	angle := gLastAngle;

	gLastCCW := (aRadioCluster.fChosenItem = kCCWItem);

	IF gLastCCW THEN angle := -angle;

	Success (fi);

	CleanUp (0, 0);

	IF angle >	 1800 THEN angle := angle - 3600;
	IF angle <= -1800 THEN angle := angle + 3600;

	IF angle = 0 THEN Failure (0, 0);

	DoRotateArbitraryCommand := DoRotateCommand (view, angle)

	END;

{*****************************************************************************}

{$S ADoRotate}

FUNCTION SetEffectMode (view: TImageView; mode: INTEGER): TCommand;

	VAR
		r: Rect;
		doc: TImageDocument;

	BEGIN

	doc := TImageDocument (view.fDocument);

	doc.KillEffect (TRUE);

	doc.fEffectMode    := mode;
	doc.fEffectChannel := view.fChannel;

	r := doc.fSelectionRect;

	doc.fEffectCorners [0]	   := r.topLeft;
	doc.fEffectCorners [1] . v := r.top;
	doc.fEffectCorners [1] . h := r.right;
	doc.fEffectCorners [2]	   := r.botRight;
	doc.fEffectCorners [3] . v := r.bottom;
	doc.fEffectCorners [3] . h := r.left;

	view.fFrame.Focus;
	view.DoHighlightCorners (TRUE);

	SetEffectMode := gNoChanges

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TEffectsCommand.IEffectsCommand (itsCommand: INTEGER;
										   view: TImageView;
										   downPoint: Point);

	VAR
		r: Rect;

	BEGIN

	IFloatCommand (itsCommand, view);

	fMode := fDoc.fEffectMode;

	fConstrainsMouse := TRUE;
	fViewConstrain := FALSE;

	fOldCorners := fDoc.fEffectCorners;

	fBaseCorners := fOldCorners;

	fCorner := view.FindCorner (fOldCorners, downPoint);

	Pt2Rect (fOldCorners [0], fOldCorners [2], r);

	fSrcRect := r;

	fRecycled := FALSE;

	fAnother := FALSE;

	fChangeCount := fDoc.fChangeCount

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TEffectsCommand.Recycle (view: TImageView; downPoint: Point);

	BEGIN

	fView := view;

	fOldCorners := fDoc.fEffectCorners;

	fCorner := view.FindCorner (fOldCorners, downPoint);

	fRecycled := TRUE

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TEffectsCommand.Free; OVERRIDE;

	BEGIN

	IF fDoc.fEffectCommand = SELF THEN
		fDoc.fEffectCommand := NIL;

	INHERITED Free

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TEffectsCommand.TrackConstrain
		(anchorPoint, previousPoint: Point;
		 VAR nextPoint: Point); OVERRIDE;

	VAR
		mag: INTEGER;
		delta: Point;
		half: INTEGER;

	BEGIN

	fView.TrackRulers;

	mag := fView.fMagnification;

	IF mag > 1 THEN
		BEGIN

		half := BSR (mag, 1);

		anchorPoint.h := (anchorPoint.h + half) DIV mag * mag;
		anchorPoint.v := (anchorPoint.v + half) DIV mag * mag;

		nextPoint.h := (nextPoint.h + half) DIV mag * mag;
		nextPoint.v := (nextPoint.v + half) DIV mag * mag

		END;

	delta.h := nextPoint.h - anchorPoint.h;
	delta.v := nextPoint.v - anchorPoint.v;

	IF mag > 1 THEN
		BEGIN
		delta.h := delta.h DIV mag;
		delta.v := delta.v DIV mag
		END

	ELSE IF mag < 1 THEN
		BEGIN
		delta.h := delta.h * (-mag);
		delta.v := delta.v * (-mag)
		END;

	ComputeNewCorners (delta)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TEffectsCommand.TrackFeedback
		(anchorPoint, nextPoint: Point;
		 turnItOn, mouseDidMove: BOOLEAN); OVERRIDE;

	VAR
		r: Rect;
		pt: Point;
		j: INTEGER;
		vp: ARRAY [0..3] OF Point;

	BEGIN

	IF mouseDidMove OR NOT EqualBytes (@fNewCorners,
									   @fLastCorners,
									   SIZEOF (TCornerList)) THEN
		BEGIN

		IF turnItOn THEN
			fLastCorners := fNewCorners;

		FOR j := 0 TO 3 DO
			BEGIN
			vp [j] := fLastCorners [j];
			fView.CvtImage2View (vp [j], kRoundUp)
			END;

		vp[1].h := vp[1].h - 1;
		vp[2].h := vp[2].h - 1;
		vp[2].v := vp[2].v - 1;
		vp[3].v := vp[3].v - 1;

		FOR j := 0 TO 3 DO
			BEGIN

			pt := vp [j];
			MoveTo (pt.h, pt.v);

			pt := vp [(j + 1) MOD 4];
			LineTo (pt.h, pt.v)

			END;

		FOR j := 0 TO 3 DO
			IF NOT EqualPt (fOldCorners [j], fLastCorners [j]) THEN
				IF fView.CompCornerRect (fLastCorners [j], r) THEN
					InvertRect (r)

		END

	END;

{*****************************************************************************}

{$S ADoRotate}

FUNCTION TEffectsCommand.TrackMouse
		(aTrackPhase: TrackPhase;
		 VAR anchorPoint, previousPoint, nextPoint: Point;
		 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

	BEGIN

	TrackMouse := SELF;

	IF aTrackPhase = TrackRelease THEN
		IF EqualBytes (@fOldCorners, @fNewCorners, SIZEOF (TCornerList)) THEN
			IF NOT fRecycled THEN
				TrackMouse := gNoChanges

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TEffectsCommand.ComputeNewCorners (delta: Point);

	BEGIN

	{$IFC qDebug}
	ProgramBreak ('Need to OVERRIDE ComputeNewCorners')
	{$ENDC}

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TEffectsCommand.CompDstRect;

	BEGIN

	fDstRect.top	:= Min (Min (Min (fNewCorners [0] . v,
									  fNewCorners [1] . v),
									  fNewCorners [2] . v),
									  fNewCorners [3] . v);

	fDstRect.left	:= Min (Min (Min (fNewCorners [0] . h,
									  fNewCorners [1] . h),
									  fNewCorners [2] . h),
									  fNewCorners [3] . h);

	fDstRect.bottom := Max (Max (Max (Max (fNewCorners [0] . v,
										   fNewCorners [1] . v),
										   fNewCorners [2] . v),
										   fNewCorners [3] . v),
										   fDstRect.top + 1);

	fDstRect.right	:= Max (Max (Max (Max (fNewCorners [0] . h,
										   fNewCorners [1] . h),
										   fNewCorners [2] . h),
										   fNewCorners [3] . h),
										   fDstRect.left + 1)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TEffectsCommand.DoEffect (srcArray: TVMArray;
									dstArray: TVMArray;
									sample: BOOLEAN;
									background: INTEGER);

	BEGIN

	{$IFC qDebug}
	ProgramBreak ('Need to OVERRIDE DoEffect')
	{$ENDC}

	END;

{*****************************************************************************}

{$S ADoRotate}

FUNCTION TEffectsCommand.TestAnother: BOOLEAN;

	VAR
		r: Rect;
		pt: Point;
		peekEvent: EventRecord;

	FUNCTION DelayIt: BOOLEAN;

		VAR
			theKeys: KeyMap;

		BEGIN
		GetKeys (theKeys);
		DelayIt := theKeys [kCommandCode] OR theKeys [kOptionCode]
		END;

	BEGIN

	TestAnother := FALSE;

	IF DelayIt THEN
		BEGIN

		fDoc.fEffectMode	:= fMode;
		fDoc.fEffectChannel := fView.fChannel;
		fDoc.fEffectCommand := SELF;

		fDoc.fEffectCorners := fNewCorners;

		fView.fFrame.Focus;
		fView.DoHighlightCorners (TRUE);

		fView.fFrame.GetViewedRect (r);

		SetCursor (arrow);

			REPEAT

			IF EventAvail (mDownMask + keyDownMask, peekEvent) THEN
				BEGIN

				IF peekEvent.what = mouseDown THEN
					BEGIN

					pt := peekEvent.where;

					GlobalToLocal (pt);

					IF PtInRect (pt, r) THEN
						IF fView.FindCorner (fNewCorners, pt) <> -1 THEN
							BEGIN
							TestAnother := TRUE;
							EXIT (TestAnother)
							END

					END;

				LEAVE

				END

			UNTIL NOT DelayIt;

		fDoc.KillEffect (TRUE)

		END;

	MoveHands (TRUE)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TEffectsCommand.DoIt; OVERRIDE;

	VAR
		r: Rect;
		rr: Rect;
		fi: FailInfo;
		fixup: BOOLEAN;
		channel: INTEGER;
		channels: INTEGER;
		aVMArray: TVMArray;
		bVMArray: TVMArray;
		tempArray: TVMArray;
		tempArray2: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		FinishProgress;

		FreeObject (tempArray);
		FreeObject (tempArray2);

		IF fixup THEN
			BEGIN

			BlendFloat (FALSE);

			fDoc.DeSelect (FALSE);

			r := fMidRect;
			ComputeOverlap (rr);
			UpdateRects (r, rr, FALSE);

			SelectFloat

			END

		END;

	BEGIN

	MoveHands (FALSE);

	fDoc.fChangeCount := fChangeCount;

	CompDstRect;

	fDoc.KillEffect (TRUE);

	IF fView.fChannel = kRGBChannels THEN
		channels := 3
	ELSE
		channels := 1;

	IF NOT fRecycled THEN
		BEGIN

		fMidRect := gZeroRect;

		FloatSelection (FALSE)

		END;

	fAnother := TestAnother;

	IF fAnother THEN EXIT (DoIt);

	fixup := fFloatData [0] <> NIL;

	IF fixup THEN
		BEGIN

		ComputeOverlap (r);

		fMidRect := r;

		CopyBelow (FALSE);

		SwapFloat;

		CopyBelow (TRUE);

		fSwapMask := FALSE;

		FreeObject (fFloatMask);
		fFloatMask := NIL;

		FOR channel := 0 TO channels - 1 DO
			BEGIN

			FreeObject (fFloatBelow [channel]);
			fFloatBelow [channel] := NIL;

			FreeObject (fFloatData [channel]);
			fFloatData [channel] := NIL

			END

		END;

	tempArray := NIL;
	tempArray2 := NIL;

	CommandProgress (fCmdNumber);

	CatchFailures (fi, CleanUp);

	fExactFloat := FALSE;

	fFloatRect := fDstRect;

	IF fComplex THEN
		BEGIN

		StartTask (1 / (channels + 1));

		IF fDoc.fFloatMask = NIL THEN
			BEGIN

			tempArray := NewVMArray (fSrcRect.bottom - fSrcRect.top,
									 fSrcRect.right - fSrcRect.left, 1);

			tempArray.SetBytes (255);

			aVMArray := NewVMArray (fDstRect.bottom - fDstRect.top,
									fDstRect.right - fDstRect.left, 1);

			fFloatMask := aVMArray;

			DoEffect (tempArray, aVMArray, FALSE, 0);

			tempArray.Free;
			tempArray := NIL;

			fSwapMask := TRUE

			END

		ELSE
			BEGIN

			tempArray := NewVMArray (fDstRect.bottom - fDstRect.top,
									 fDstRect.right - fDstRect.left, 1);

			IF NOT EqualRect (fSrcRect, fDoc.fFloatRect) THEN
				BEGIN

				r := fSrcRect;

				OffsetRect (r, -fDoc.fFloatRect.left, -fDoc.fFloatRect.top);

				tempArray2 := fDoc.fFloatMask.CopyRect (r, 1);

				DoEffect (tempArray2, tempArray, FALSE, 0);

				tempArray2.Free;
				tempArray2 := NIL

				END

			ELSE
				DoEffect (fDoc.fFloatMask, tempArray, FALSE, 0);

			tempArray.FindBounds (r);

			IF (r.bottom - r.top = tempArray.fBlockCount ) AND
			   (r.right - r.left = tempArray.fLogicalSize) THEN

				fFloatMask := tempArray

			ELSE
				BEGIN

				aVMArray := tempArray.CopyRect (r, 1);

				fFloatMask := aVMArray;

				tempArray.Free;

				END;

			tempArray := NIL;

			OffsetRect (r, fDstRect.left, fDstRect.top);

			fFloatRect := r

			END;

		FinishTask

		END

	ELSE IF fDoc.fFloatMask <> NIL THEN
		BEGIN

		StartTask (1 / (channels + 1));

		aVMArray := NewVMArray (fDstRect.bottom - fDstRect.top,
								fDstRect.right - fDstRect.left, 1);

		fFloatMask := aVMArray;

		IF NOT EqualRect (fSrcRect, fDoc.fFloatRect) THEN
			BEGIN

			r := fSrcRect;

			OffsetRect (r, -fDoc.fFloatRect.left, -fDoc.fFloatRect.top);

			tempArray2 := fDoc.fFloatMask.CopyRect (r, 1);

			DoEffect (tempArray2, aVMArray, FALSE, 0);

			tempArray2.Free;
			tempArray2 := NIL

			END

		ELSE
			DoEffect (fDoc.fFloatMask, aVMArray, FALSE, 0);

		FinishTask

		END;

	FOR channel := 0 TO channels - 1 DO
		BEGIN

		aVMArray := NewVMArray (fFloatRect.bottom - fFloatRect.top,
								fFloatRect.right - fFloatRect.left, 1);

		fFloatBelow [channel] := aVMArray

		END;

	FOR channel := 0 TO channels - 1 DO
		BEGIN

		aVMArray := NewVMArray (fFloatRect.bottom - fFloatRect.top,
								fFloatRect.right - fFloatRect.left,
								channels - channel);

		fFloatData [channel] := aVMArray

		END;

	FOR channel := 0 TO channels - 1 DO
		BEGIN

		StartTask (1 / (channels - channel));

		IF EqualRect (fSrcRect, fDoc.fFloatRect) THEN

			aVMArray := fDoc.fFloatData [channel]

		ELSE
			BEGIN

			r := fSrcRect;

			OffsetRect (r, -fDoc.fFloatRect.left, -fDoc.fFloatRect.top);

			tempArray := fDoc.fFloatData [channel] . CopyRect (r, 1);

			aVMArray := tempArray

			END;

		IF EqualRect (fDstRect, fFloatRect) THEN

			bVMArray := fFloatData [channel]

		ELSE
			BEGIN

			tempArray2 := NewVMArray (fDstRect.bottom - fDstRect.top,
									  fDstRect.right - fDstRect.left, 1);

			bVMArray := tempArray2

			END;

		DoEffect (aVMArray, bVMArray, fDoc.fMode = IndexedColorMode, -1);

		FreeObject (tempArray);

		tempArray := NIL;

		IF tempArray2 <> NIL THEN
			BEGIN

			r := fFloatRect;
			rr := r;

			OffsetRect (r, -fDstRect.left, -fDstRect.top);
			OffsetRect (rr, -rr.left, -rr.top);

			tempArray2.MoveRect (fFloatData [channel], r, rr);

			tempArray2.Free;
			tempArray2 := NIL

			END;

		FinishTask

		END;

	Success (fi);

	FinishProgress;

	RedoIt

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TEffectsCommand.SwapIt (undo: BOOLEAN);

	VAR
		r1: Rect;
		r2: Rect;
		view: TImageView;

	BEGIN

	MoveHands (FALSE);

	IF EmptyRect (fMidRect) THEN
		BEGIN
		fDoc.DeSelect (NOT fDoc.fSelectionFloating);
		ComputeOverlap (r1);
		END
	ELSE
		BEGIN
		fDoc.DeSelect (FALSE);
		r1 := fMidRect;
		fMidRect := gZeroRect
		END;

	CopyBelow (FALSE);

	SwapFloat;

	CopyBelow (TRUE);

	BlendFloat (FALSE);

	ComputeOverlap (r2);

	UpdateRects (r1, r2, FALSE);

	SelectFloat;

	fDoc.fEffectMode	:= fMode;
	fDoc.fEffectChannel := fDoc.fFloatChannel;
	fDoc.fEffectCommand := SELF;

	IF undo THEN
		fDoc.fEffectCorners := fBaseCorners
	ELSE
		fDoc.fEffectCorners := fNewCorners;

	IF MEMBER (gTarget, TImageView) THEN
		BEGIN

		view := TImageView (gTarget);

		IF (view.fDocument = fDoc) AND
		   (view.fChannel  = fDoc.fEffectChannel) THEN
			BEGIN
			view.fFrame.Focus;
			view.DoHighlightCorners (TRUE)
			END

		END

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TEffectsCommand.UndoIt; OVERRIDE;

	BEGIN
	SwapIt (TRUE)
	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TEffectsCommand.RedoIt; OVERRIDE;

	BEGIN
	SwapIt (FALSE)
	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TEffectsCommand.Commit; OVERRIDE;

	BEGIN

	IF fDoc.fEffectCommand = SELF THEN
		fDoc.KillEffect (TRUE)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TResizeEffect.IResizeEffect (view: TImageView; downPoint: Point);

	BEGIN

	IEffectsCommand (cEffectResize, view, downPoint);

	fComplex := FALSE

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TResizeEffect.ComputeNewCorners (delta: Point); OVERRIDE;

	VAR
		r: Rect;
		pt1: Point;
		pt2: Point;
		oldH: INTEGER;
		oldV: INTEGER;
		newH: INTEGER;
		newV: INTEGER;
		theKeys: KeyMap;
		shiftDown: BOOLEAN;

	BEGIN

	GetKeys (theKeys);

	shiftDown := theKeys [kShiftCode];

	pt1 := fOldCorners [BAND (fCorner + 2, 3)];
	pt2 := fOldCorners [fCorner];

	oldH := pt2.h - pt1.h;
	oldV := pt2.v - pt1.v;

	newH := pt2.h + delta.h - pt1.h;
	newV := pt2.v + delta.v - pt1.v;

	IF ORD4 (oldH) * newH <= 0 THEN
		IF oldH < 0 THEN
			newH := -1
		ELSE
			newH := 1;

	IF ORD4 (oldV) * newV <= 0 THEN
		IF oldV < 0 THEN
			newV := -1
		ELSE
			newV := 1;

	IF shiftDown THEN
		BEGIN

		newH := ABS (newH);
		newV := ABS (newV);

		oldH := fSrcRect.right - fSrcRect.left;
		oldV := fSrcRect.bottom - fSrcRect.top;

		IF ORD4 (newH) * oldV <= ORD4 (newV) * oldH THEN
			newV := Max (1, (ORD4 (newH) * oldV + BSR (oldH, 1)) DIV oldH)
		ELSE
			newH := Max (1, (ORD4 (newV) * oldH + BSR (oldV, 1)) DIV oldV);

		IF pt2.h < pt1.h THEN newH := -newH;
		IF pt2.v < pt1.v THEN newV := -newV

		END;

	pt2.h := pt1.h + newH;
	pt2.v := pt1.v + newV;

	Pt2Rect (pt1, pt2, r);

	fNewCorners [0] 	:= r.topLeft;
	fNewCorners [1] . h := r.right;
	fNewCorners [1] . v := r.top;
	fNewCorners [2] 	:= r.botRight;
	fNewCorners [3] . h := r.left;
	fNewCorners [3] . v := r.bottom;

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TResizeEffect.DoEffect (srcArray: TVMArray;
								  dstArray: TVMArray;
								  sample: BOOLEAN;
								  background: INTEGER); OVERRIDE;

	BEGIN
	ResizeArray (srcArray, dstArray, sample, TRUE)
	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TRotateEffect.IRotateEffect (view: TImageView; downPoint: Point);

	BEGIN

	IEffectsCommand (cRotation, view, downPoint);

	fRowRadius := (fSrcRect.bottom - fSrcRect.top) / 2;
	fColRadius := (fSrcRect.right - fSrcRect.left) / 2;

	fCenterRow := fSrcRect.top	+ fRowRadius;
	fCenterCol := fSrcRect.left + fColRadius;

	ComputeBaseAngle

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TRotateEffect.Recycle (view: TImageView;
								 downPoint: Point); OVERRIDE;

	BEGIN

	INHERITED Recycle (view, downPoint);

	ComputeBaseAngle

	END;

{*****************************************************************************}

{$S ADoRotate}

FUNCTION DeltaToAngle (deltaRow, deltaCol: EXTENDED): EXTENDED;

	BEGIN

	IF deltaRow = 0 THEN
		IF deltaCol > 0 THEN
			DeltaToAngle := pi / 2
		ELSE IF deltaCol = 0 THEN
			DeltaToAngle := 0
		ELSE
			DeltaToAngle := -pi / 2

	ELSE IF deltaRow > 0 THEN
		DeltaToAngle := ARCTAN (deltaCol / deltaRow)

	ELSE
		DeltaToAngle := pi + ARCTAN (deltaCol / deltaRow)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TRotateEffect.ComputeBaseAngle;

	BEGIN

	fBaseAngle := DeltaToAngle (fBaseCorners [fCorner] . v - fCenterRow,
								fBaseCorners [fCorner] . h - fCenterCol)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TRotateEffect.ComputeNewCorners (delta: Point); OVERRIDE;

	VAR
		theta: EXTENDED;
		sinTheta: EXTENDED;
		cosTheta: EXTENDED;
		deltaRow1: EXTENDED;
		deltaCol1: EXTENDED;
		deltaRow2: EXTENDED;
		deltaCol2: EXTENDED;

	BEGIN

	theta := DeltaToAngle (fOldCorners [fCorner] . v + delta.v - fCenterRow,
						   fOldCorners [fCorner] . h + delta.h - fCenterCol) -
			 fBaseAngle;

	sinTheta := SIN (theta);
	cosTheta := COS (theta);

	deltaRow1 :=   cosTheta * fRowRadius - sinTheta * fColRadius;
	deltaCol1 :=   cosTheta * fColRadius + sinTheta * fRowRadius;

	deltaRow2 :=   cosTheta * fRowRadius + sinTheta * fColRadius;
	deltaCol2 := - cosTheta * fColRadius + sinTheta * fRowRadius;

	fNewCorners [0] . v := ROUND (fCenterRow - deltaRow1);
	fNewCorners [0] . h := ROUND (fCenterCol - deltaCol1);

	fNewCorners [1] . v := ROUND (fCenterRow - deltaRow2);
	fNewCorners [1] . h := ROUND (fCenterCol - deltaCol2);

	fNewCorners [2] . v := ROUND (fCenterRow + deltaRow1);
	fNewCorners [2] . h := ROUND (fCenterCol + deltaCol1);

	fNewCorners [3] . v := ROUND (fCenterRow + deltaRow2);
	fNewCorners [3] . h := ROUND (fCenterCol + deltaCol2);

	theta := DeltaToAngle (fNewCorners [fCorner] . v - fCenterRow,
						   fNewCorners [fCorner] . h - fCenterCol) -
			 fBaseAngle;

	fAngle := ROUND (-theta * (1800 / pi));

	WHILE fAngle > 1800 DO
		fAngle := fAngle - 3600;

	WHILE fAngle <= -1800 DO
		fAngle := fAngle + 3600;

	fComplex := ABS (fAngle) MOD 900 <> 0

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TRotateEffect.CompDstRect; OVERRIDE;

	VAR
		rows: INTEGER;
		cols: INTEGER;
		width: INTEGER;
		height: INTEGER;

	BEGIN

	rows := fSrcRect.bottom - fSrcRect.top;
	cols := fSrcRect.right - fSrcRect.left;

	IF (fAngle = 0) OR (fAngle = 1800) THEN
		BEGIN
		width  := cols;
		height := rows
		END

	ELSE IF ABS (fAngle) = 900 THEN
		BEGIN
		width  := rows;
		height := cols
		END

	ELSE
		ComputeRotatedSize (rows, cols, fAngle, height, width);

	fDstRect.top  := BSR (fSrcRect.top + ORD4 (fSrcRect.bottom) - height, 1);
	fDstRect.left := BSR (fSrcRect.left + ORD4 (fSrcRect.right) - width , 1);

	fDstRect.bottom := fDstRect.top  + height;
	fDstRect.right	:= fDstRect.left + width

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TRotateEffect.DoEffect (srcArray: TVMArray;
								  dstArray: TVMArray;
								  sample: BOOLEAN;
								  background: INTEGER); OVERRIDE;

	BEGIN

	IF fAngle = 0 THEN
		srcArray.MoveArray (dstArray)

	ELSE IF fAngle = 1800 THEN
		DoFlipArray (srcArray, dstArray, TRUE, TRUE)

	ELSE IF ABS (fAngle) = 900 THEN
		DoTransposeArray (srcArray, dstArray, fAngle = 900, fAngle = -900)

	ELSE
		DoRotateArray (srcArray, dstArray, fAngle, sample, background)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TSkewEffect.ISkewEffect (view: TImageView; downPoint: Point);

	BEGIN

	fCoupled := TRUE;

	fHaveAxis := FALSE;

	IEffectsCommand (cSkewing, view, downPoint);

	fComplex := FALSE

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TSkewEffect.Recycle (view: TImageView;
							   downPoint: Point); OVERRIDE;

	BEGIN

	fCoupled := FALSE;

	INHERITED Recycle (view, downPoint)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TSkewEffect.ComputeNewCorners (delta: Point); OVERRIDE;

	VAR
		theKeys: KeyMap;
		shiftDown: BOOLEAN;

	BEGIN

	GetKeys (theKeys);

	shiftDown := theKeys [kShiftCode];

	fNewCorners := fOldCorners;

	IF NOT fHaveAxis THEN

		IF (delta.h = 0) AND (delta.v = 0) THEN
			EXIT (ComputeNewCorners)

		ELSE IF ABS (delta.h) >= ABS (delta.v) THEN
			BEGIN
			fHaveAxis := TRUE;
			fVertical := FALSE
			END

		ELSE
			BEGIN
			fHaveAxis := TRUE;
			fVertical := TRUE
			END;

	IF fVertical THEN
		IF fCoupled OR shiftDown THEN
			IF (fCorner = 0) OR (fCorner = 3) THEN
				BEGIN
				fNewCorners [0] . v := fOldCorners [0] . v + delta.v;
				fNewCorners [3] . v := fOldCorners [3] . v + delta.v
				END
			ELSE
				BEGIN
				fNewCorners [1] . v := fOldCorners [1] . v + delta.v;
				fNewCorners [2] . v := fOldCorners [2] . v + delta.v
				END
		ELSE
			fNewCorners [fCorner] . v := fOldCorners [fCorner] . v + delta.v
	ELSE
		IF fCoupled OR shiftDown THEN
			IF (fCorner = 0) OR (fCorner = 1) THEN
				BEGIN
				fNewCorners [0] . h := fOldCorners [0] . h + delta.h;
				fNewCorners [1] . h := fOldCorners [1] . h + delta.h
				END
			ELSE
				BEGIN
				fNewCorners [2] . h := fOldCorners [2] . h + delta.h;
				fNewCorners [3] . h := fOldCorners [3] . h + delta.h
				END
		ELSE
			fNewCorners [fCorner] . h := fOldCorners [fCorner] . h + delta.h;

	fComplex := NOT EqualBytes (@fBaseCorners,
								@fNewCorners,
								SIZEOF (TCornerList))

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TSkewEffect.DoEffect (srcArray: TVMArray;
								dstArray: TVMArray;
								sample: BOOLEAN;
								background: INTEGER); OVERRIDE;

	VAR
		fi: FailInfo;
		width: INTEGER;
		height: INTEGER;
		delta1: INTEGER;
		delta2: INTEGER;
		scale1: EXTENDED;
		scale2: EXTENDED;
		buffer1: TVMArray;
		buffer2: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (buffer1);
		FreeObject (buffer2)
		END;

	BEGIN

	IF fVertical THEN
		BEGIN

		height := fSrcRect.bottom - fSrcRect.top;

		scale1 := (fNewCorners [3] . v - fNewCorners [0] . v) / height;
		scale2 := (fNewCorners [2] . v - fNewCorners [1] . v) / height;

		delta1 := fNewCorners [0] . v - fDstRect.top;
		delta2 := fNewCorners [1] . v - fDstRect.top;

		IF (scale1 = 1) AND (scale2 = 1) AND
		   (delta1 = 0) AND (delta2 = 0) THEN
			srcArray.MoveArray (dstArray)

		ELSE
			BEGIN

			buffer1 := NIL;
			buffer2 := NIL;

			CatchFailures (fi, CleanUp);

			buffer1 := NewVMArray (srcArray.fLogicalSize,
								   srcArray.fBlockCount, 1);

			StartTask (1/11);
			DoTransposeArray (srcArray, buffer1, FALSE, FALSE);
			FinishTask;

			buffer2 := NewVMArray (dstArray.fLogicalSize,
								   dstArray.fBlockCount, 1);

			StartTask (9/10);
			DoSkewArray (buffer1, buffer2,
						 delta1, delta2,
						 scale1, scale2,
						 sample, background);
			FinishTask;

			DoTransposeArray (buffer2, dstArray, FALSE, FALSE);

			Success (fi);

			CleanUp (0, 0)

			END

		END

	ELSE
		BEGIN

		width := fSrcRect.right - fSrcRect.left;

		scale1 := (fNewCorners [1] . h - fNewCorners [0] . h) / width;
		scale2 := (fNewCorners [2] . h - fNewCorners [3] . h) / width;

		delta1 := fNewCorners [0] . h - fDstRect.left;
		delta2 := fNewCorners [3] . h - fDstRect.left;

		IF (scale1 = 1) AND (scale2 = 1) AND
		   (delta1 = 0) AND (delta2 = 0) THEN
			srcArray.MoveArray (dstArray)

		ELSE
			DoSkewArray (srcArray, dstArray,
						 delta1, delta2,
						 scale1, scale2,
						 sample, background)

		END

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TPerspectiveTable.IPerspectiveTable (oldSize: INTEGER;
											   newSize: INTEGER;
											   sample: BOOLEAN;
											   a: EXTENDED);

	VAR
		h: Handle;
		j: INTEGER;
		k: INTEGER;
		w: INTEGER;
		x: EXTENDED;
		y: EXTENDED;
		b: EXTENDED;
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Free
		END;

	BEGIN

	IF (oldSize <= 2) OR (newSize <= 2) OR (a = 1.0) THEN
		IResizeTable (oldSize, newSize, sample)

	ELSE
		BEGIN

		fTable1 := NIL;
		fTable2 := NIL;

		fOldSize := oldSize;
		fNewSize := newSize;

		sample := sample OR (gPreferences.fInterpolate = 0);

		IF sample THEN
			fMode := ResizeModeSample

		ELSE IF gPreferences.fInterpolate = 1 THEN
			fMode := ResizeModeInterpolate

		ELSE
			fMode := ResizeModeBiCubic;

		CatchFailures (fi, CleanUp);

		h := NewLargeHandle (BSL (newSize, 1));

		MoveHHi (h);
		HLock (h);

		fTable1 := HWordArray (h);

		IF NOT sample THEN
			BEGIN

			h := NewLargeHandle (newSize);

			MoveHHi (h);
			HLock (h);

			fTable2 := HByteArray (h)

			END;

		IF sample THEN
			b := oldSize / LN (1 - a)
		ELSE
			b := (oldSize - 1) / LN (1 - a);

		FOR j := 0 TO newSize - 1 DO
			BEGIN

			MoveHands (TRUE);

			IF sample THEN
				x := (j + 0.5) / newSize
			ELSE
				x := j / (newSize - 1);

			y := LN (1 - a * x) * b;

			k := TRUNC (y);
			w := ROUND (256 * (y - k));

			IF w > 255 THEN
				BEGIN
				k := k + 1;
				w := 0
				END;

			fTable1^^ [j] := k;

			IF NOT sample THEN
				fTable2^^ [j] := CHR (w)

			END;

		Success (fi)

		END

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE PerspectiveSample (srcArray: TVMArray;
							 dstArray: TVMArray;
							 scale1: EXTENDED;
							 scale2: EXTENDED;
							 sample: BOOLEAN);

	VAR
		fi: FailInfo;
		hTable: TResizeTable;
		vTable: TPerspectiveTable;
		aTable: TPerspectiveTable;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (hTable);
		FreeObject (vTable);
		END;

	BEGIN

	NEW (hTable);
	FailNil (hTable);

	hTable.IResizeTable (srcArray.fLogicalSize,
						 dstArray.fLogicalSize, sample);

	vTable := NIL;

	CatchFailures (fi, CleanUp);

	NEW (aTable);
	FailNil (aTable);

	aTable.IPerspectiveTable (srcArray.fBlockCount,
							  dstArray.fBlockCount,
							  sample,
							  (scale1 - scale2) / scale1);

	vTable := aTable;

	DoResizeArray (srcArray, dstArray, hTable, vTable, TRUE);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TPerspectiveEffect.IPerspectiveEffect (view: TImageView;
												 downPoint: Point);

	BEGIN

	IEffectsCommand (cEffectPerspective, view, downPoint);

	fComplex := FALSE

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TPerspectiveEffect.ComputeNewCorners (delta: Point); OVERRIDE;

	VAR
		width: INTEGER;
		height: INTEGER;

	BEGIN

	fNewCorners := fOldCorners;

	IF (fCorner = 1) OR (fCorner = 2) THEN
		delta.h := -delta.h;

	height := fOldCorners [3] . v - fOldCorners [0] . v - 1;

	IF (fCorner = 0) OR (fCorner = 1) THEN
		BEGIN

		width := fOldCorners [1] . h - fOldCorners [0] . h;

		delta.h := Min (delta.h, (width - 1) DIV 2);

		fNewCorners [0] . h := fOldCorners [0] . h + delta.h;
		fNewCorners [1] . h := fOldCorners [1] . h - delta.h;

		delta.v := Min (delta.v, height);

		fNewCorners [0] . v := fOldCorners [0] . v + delta.v;
		fNewCorners [1] . v := fOldCorners [1] . v + delta.v

		END

	ELSE
		BEGIN

		width := fOldCorners [2] . h - fOldCorners [3] . h;

		delta.h := Min (delta.h, (width - 1) DIV 2);

		fNewCorners [3] . h := fOldCorners [3] . h + delta.h;
		fNewCorners [2] . h := fOldCorners [2] . h - delta.h;

		delta.v := Max (delta.v, -height);

		fNewCorners [3] . v := fOldCorners [3] . v + delta.v;
		fNewCorners [2] . v := fOldCorners [2] . v + delta.v

		END;

	fComplex := NOT EqualBytes (@fBaseCorners,
								@fNewCorners,
								SIZEOF (TCornerList))

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TPerspectiveEffect.DoEffect (srcArray: TVMArray;
									   dstArray: TVMArray;
									   sample: BOOLEAN;
									   background: INTEGER); OVERRIDE;

	VAR
		fi: FailInfo;
		width: INTEGER;
		scale1: EXTENDED;
		scale2: EXTENDED;
		buffer: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (buffer)
		END;

	BEGIN

	width := fSrcRect.right - fSrcRect.left;

	scale1 := (fNewCorners [1] . h - fNewCorners [0] . h) / width;
	scale2 := (fNewCorners [2] . h - fNewCorners [3] . h) / width;

	IF (scale1 = 1) AND (scale2 = 1) AND (srcArray.fBlockCount =
										  dstArray.fBlockCount) THEN
		srcArray.MoveArray (dstArray)

	ELSE
		BEGIN

		buffer := NewVMArray (dstArray.fBlockCount, width, 1);

		CatchFailures (fi, CleanUp);

		StartTask (1/2);
		PerspectiveSample (srcArray,
						   buffer,
						   scale1,
						   scale2,
						   sample);
		FinishTask;

		DoSkewArray (buffer,
					 dstArray,
					 fNewCorners [0] . h - fDstRect.left,
					 fNewCorners [3] . h - fDstRect.left,
					 scale1,
					 scale2,
					 sample,
					 background);

		Success (fi);

		CleanUp (0, 0)

		END

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TDistortEffect.IDistortEffect (view: TImageView; downPoint: Point);

	BEGIN
	IEffectsCommand (cDistortion, view, downPoint)
	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TDistortEffect.ComputeNewCorners (delta: Point); OVERRIDE;

	CONST
		kMaxSlope = 1;

	VAR
		limit: Point;

	PROCEDURE MovePointInside (VAR pt: Point; pt1, pt2: Point);

		VAR
			p: POINT;
			d: INTEGER;
			t: INTEGER;
			dv: LONGINT;
			dh: LONGINT;

		BEGIN

		dv := pt2.v - pt1.v;
		dh := pt2.h - pt1.h;

		IF (pt.v - pt1.v) * dh >= (pt.h - pt1.h) * dv THEN
			BEGIN

			d := Max (ABS (dv), ABS (dh));
			t := 0;

				REPEAT

				t := t + 1;

				p.v := pt.v - dh * t DIV d;
				p.h := pt.h + dv * t DIV d

				UNTIL (p.v - pt1.v) * dh < (p.h - pt1.h) * dv;

			pt := p

			END

		END;

	BEGIN

	fNewCorners := fOldCorners;

	fNewCorners [fCorner] . h := fNewCorners [fCorner] . h + delta.h;
	fNewCorners [fCorner] . v := fNewCorners [fCorner] . v + delta.v;

	{$H-}

		CASE fCorner OF

		0:	BEGIN

			limit.h := fOldCorners [3] . h + kMaxSlope;
			limit.v := fOldCorners [3] . v + 1;

			MovePointInside (fNewCorners [0], fOldCorners [3], limit);

			limit.v := fOldCorners [3] . v - 1;

			MovePointInside (fNewCorners [0], fOldCorners [3], limit)

			END;

		1:	BEGIN

			limit.h := fOldCorners [2] . h + kMaxSlope;
			limit.v := fOldCorners [2] . v + 1;

			MovePointInside (fNewCorners [1], fOldCorners [2], limit);

			limit.v := fOldCorners [2] . v - 1;

			MovePointInside (fNewCorners [1], fOldCorners [2], limit)

			END;

		2:	BEGIN

			limit.h := fOldCorners [1] . h - kMaxSlope;
			limit.v := fOldCorners [1] . v + 1;

			MovePointInside (fNewCorners [2], fOldCorners [1], limit);

			limit.v := fOldCorners [1] . v - 1;

			MovePointInside (fNewCorners [2], fOldCorners [1], limit)

			END;

		3:	BEGIN

			limit.h := fOldCorners [0] . h - kMaxSlope;
			limit.v := fOldCorners [0] . v + 1;

			MovePointInside (fNewCorners [3], fOldCorners [0], limit);

			limit.v := fOldCorners [0] . v - 1;

			MovePointInside (fNewCorners [3], fOldCorners [0], limit)

			END

		END;

	MovePointInside (fNewCorners [fCorner],
					 fOldCorners [(fCorner + 3) MOD 4],
					 fOldCorners [(fCorner + 1) MOD 4]);

	MovePointInside (fNewCorners [fCorner],
					 fOldCorners [(fCorner + 3) MOD 4],
					 fOldCorners [(fCorner + 2) MOD 4]);

	MovePointInside (fNewCorners [fCorner],
					 fOldCorners [(fCorner + 2) MOD 4],
					 fOldCorners [(fCorner + 1) MOD 4]);

	{$H+}

	fComplex := NOT EqualBytes (@fBaseCorners,
								@fNewCorners,
								SIZEOF (TCornerList))

	END;

{*****************************************************************************}

{$S ADoRotate}

PROCEDURE TDistortEffect.DoEffect (srcArray: TVMArray;
								   dstArray: TVMArray;
								   sample: BOOLEAN;
								   background: INTEGER); OVERRIDE;

	VAR
		fi: FailInfo;
		x0: EXTENDED;
		x1: EXTENDED;
		x2: EXTENDED;
		x3: EXTENDED;
		width: INTEGER;
		height: INTEGER;
		slope1: EXTENDED;
		slope2: EXTENDED;
		scale1: EXTENDED;
		scale2: EXTENDED;
		buffer1: TVMArray;
		buffer2: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (buffer1);
		FreeObject (buffer2)
		END;

	BEGIN

	IF NOT fComplex THEN
		BEGIN
		srcArray.MoveArray (dstArray);
		EXIT (DoEffect)
		END;

	buffer1 := NIL;
	buffer2 := NIL;

	CatchFailures (fi, CleanUp);

	buffer1 := NewVMArray (srcArray.fLogicalSize,
						   srcArray.fBlockCount, 1);

	StartTask (1/20);
	DoTransposeArray (srcArray, buffer1, FALSE, FALSE);
	FinishTask;

	buffer2 := NewVMArray (srcArray.fLogicalSize,
						   dstArray.fBlockCount, 1);

	height := fSrcRect.bottom - fSrcRect.top;

	scale1 := (fNewCorners [3] . v - fNewCorners [0] . v) / height;
	scale2 := (fNewCorners [2] . v - fNewCorners [1] . v) / height;

	StartTask (9/19);
	DoSkewArray (buffer1,
				 buffer2,
				 fNewCorners [0] . v - fDstRect.top,
				 fNewCorners [1] . v - fDstRect.top,
				 scale1,
				 scale2,
				 sample,
				 background);
	FinishTask;

	buffer1.Free;
	buffer1 := NIL;

	buffer1 := NewVMArray (dstArray.fBlockCount,
						   srcArray.fLogicalSize, 1);

	StartTask (1/10);
	DoTransposeArray (buffer2, buffer1, FALSE, FALSE);
	FinishTask;

	height := fDstRect.bottom - fDstRect.top;

	IF fNewCorners [0] . v = fNewCorners [3] . v THEN
		Failure (errDistortTooMuch, 0)
	ELSE
		BEGIN
		slope1 := (fNewCorners [3] . h - fNewCorners [0] . h) /
				  (fNewCorners [0] . v - fNewCorners [3] . v);
		x0 := (fNewCorners [0] . h - fDstRect.left) +
			  (fNewCorners [0] . v - fDstRect.top) * slope1;
		x3 := x0 - height * slope1
		END;

	IF fNewCorners [1] . v = fNewCorners [2] . v THEN
		Failure (errDistortTooMuch, 0)
	ELSE
		BEGIN
		slope2 := (fNewCorners [1] . h - fNewCorners [2] . h) /
				  (fNewCorners [2] . v - fNewCorners [1] . v);
		x1 := (fNewCorners [1] . h - fDstRect.left) +
			  (fNewCorners [1] . v - fDstRect.top) * slope2;
		x2 := x1 - height * slope2
		END;

	width := fSrcRect.right - fSrcRect.left;

	scale1 := (x1 - x0) / width;
	scale2 := (x2 - x3) / width;

	DoSkewArray (buffer1,
				 dstArray,
				 x0,
				 x3,
				 scale1,
				 scale2,
				 sample,
				 background);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoRotate}

FUNCTION DoEffectsCommand (view: TImageView; downPoint: Point): TCommand;

	VAR
		doc: TImageDocument;
		cmd: TEffectsCommand;
		aSkewEffect: TSkewEffect;
		aResizeEffect: TResizeEffect;
		aRotateEffect: TRotateEffect;
		aDistortEffect: TDistortEffect;
		aPerspectiveEffect: TPerspectiveEffect;

	BEGIN

	doc := TImageDocument (view.fDocument);

	IF MEMBER (gLastCommand, TEffectsCommand) THEN
		BEGIN

		cmd := TEffectsCommand (gLastCommand);

		IF (doc.fEffectCommand = cmd) AND cmd.fCmdDone THEN
			BEGIN

			gLastCommand := NIL;

			cmd.Recycle (view, downPoint);

			DoEffectsCommand := cmd;

			EXIT (DoEffectsCommand)

			END

		END;

		CASE doc.fEffectMode OF

		cEffectResize:
			BEGIN

			NEW (aResizeEffect);
			FailNil (aResizeEffect);

			aResizeEffect.IResizeEffect (view, downPoint);

			DoEffectsCommand := aResizeEffect

			END;

		cEffectRotate:
			BEGIN

			NEW (aRotateEffect);
			FailNil (aRotateEffect);

			aRotateEffect.IRotateEffect (view, downPoint);

			DoEffectsCommand := aRotateEffect

			END;

		cEffectSkew:
			BEGIN

			NEW (aSkewEffect);
			FailNil (aSkewEffect);

			aSkewEffect.ISkewEffect (view, downPoint);

			DoEffectsCommand := aSkewEffect

			END;

		cEffectPerspective:
			BEGIN

			NEW (aPerspectiveEffect);
			FailNil (aPerspectiveEffect);

			aPerspectiveEffect.IPerspectiveEffect (view, downPoint);

			DoEffectsCommand := aPerspectiveEffect

			END;

		cEffectDistort:
			BEGIN

			NEW (aDistortEffect);
			FailNil (aDistortEffect);

			aDistortEffect.IDistortEffect (view, downPoint);

			DoEffectsCommand := aDistortEffect

			END

		END

	END;

{*****************************************************************************}

END.

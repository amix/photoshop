{Photoshop version 1.0.1, file: UTrap.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UTrap;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UBWDialog, UCommands, UProgress;

TYPE

	TTrapCommand = OBJECT (TBufferCommand)

		fWidth: INTEGER;

		PROCEDURE TTrapCommand.ITrapCommand (view: TImageView; width: INTEGER);

		PROCEDURE TTrapCommand.TrapAcross (srcArray1: TVMArray;
										   srcArray2: TVMArray;
										   srcArray3: TVMArray;
										   srcArray4: TVMArray;
										   dstArray1: TVMArray;
										   dstArray2: TVMArray;
										   dstArray3: TVMArray;
										   clear: BOOLEAN);

		PROCEDURE TTrapCommand.CombineTrap (srcArray: TVMArray;
											dstArray: TVMArray);

		PROCEDURE TTrapCommand.DoIt; OVERRIDE;

		PROCEDURE TTrapCommand.UndoIt; OVERRIDE;

		PROCEDURE TTrapCommand.RedoIt; OVERRIDE;

		END;

PROCEDURE InitTraps;

FUNCTION DoTrapCommand (view: TImageView): TCommand;

IMPLEMENTATION

{$I UAssembly.a.inc}
{$I URotate.p.inc}
{$I UTrap.a.inc}

VAR
	gTrapUnit: INTEGER;
	gTrapWidth: INTEGER;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitTraps;

	BEGIN
	gTrapUnit := 1;
	gTrapWidth := 1
	END;

{*****************************************************************************}

{$S ATrap}

PROCEDURE TTrapCommand.ITrapCommand (view: TImageView; width: INTEGER);

	BEGIN

	fWidth := width;

	IBufferCommand (cTrapping, view)

	END;

{*****************************************************************************}

{$S ATrap}

PROCEDURE TTrapCommand.TrapAcross (srcArray1: TVMArray;
								   srcArray2: TVMArray;
								   srcArray3: TVMArray;
								   srcArray4: TVMArray;
								   dstArray1: TVMArray;
								   dstArray2: TVMArray;
								   dstArray3: TVMArray;
								   clear: BOOLEAN);

	VAR
		fi: FailInfo;
		row: INTEGER;
		srcPtr1: Ptr;
		srcPtr2: Ptr;
		srcPtr3: Ptr;
		srcPtr4: Ptr;
		dstPtr1: Ptr;
		dstPtr2: Ptr;
		dstPtr3: Ptr;
		rows: INTEGER;
		cols: INTEGER;
		buffer1: Handle;
		buffer2: Handle;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		FreeLargeHandle (buffer1);
		FreeLargeHandle (buffer2);

		IF srcPtr1 <> NIL THEN srcArray1.DoneWithPtr;
		IF srcPtr2 <> NIL THEN srcArray2.DoneWithPtr;
		IF srcPtr3 <> NIL THEN srcArray3.DoneWithPtr;
		IF srcPtr4 <> NIL THEN srcArray4.DoneWithPtr;

		srcArray1.Flush;
		srcArray2.Flush;
		srcArray3.Flush;
		srcArray4.Flush;

		dstArray1.Flush;
		dstArray2.Flush;
		dstArray3.Flush

		END;

	BEGIN

	srcPtr1 := NIL;
	srcPtr2 := NIL;
	srcPtr3 := NIL;
	srcPtr4 := NIL;

	buffer1 := NIL;
	buffer2 := NIL;

	CatchFailures (fi, CleanUp);

	rows := srcArray1.fBlockCount;
	cols := srcArray1.fLogicalSize;

	buffer1 := NewLargeHandle (cols + fWidth);
	buffer2 := NewLargeHandle (cols + fWidth);

	MoveHHi (buffer1);
	HLock (buffer1);

	MoveHHi (buffer2);
	HLock (buffer2);

	FOR row := 0 TO rows - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row, rows);

		srcPtr1 := srcArray1.NeedPtr (row, row, FALSE);
		srcPtr2 := srcArray2.NeedPtr (row, row, FALSE);
		srcPtr3 := srcArray3.NeedPtr (row, row, FALSE);
		srcPtr4 := srcArray4.NeedPtr (row, row, FALSE);

		dstPtr1 := dstArray1.NeedPtr (row, row, TRUE);
		dstPtr2 := dstArray2.NeedPtr (row, row, TRUE);
		dstPtr3 := dstArray3.NeedPtr (row, row, TRUE);

		IF clear THEN
			BEGIN
			DoSetBytes (dstPtr1, cols, 0);
			DoSetBytes (dstPtr2, cols, 0);
			DoSetBytes (dstPtr3, cols, 0)
			END;

		DoTrapRow (srcPtr4, srcPtr1, dstPtr1, buffer1^, buffer2^,
				   fWidth, cols);

		DoTrapRow (srcPtr4, srcPtr2, dstPtr2, buffer1^, buffer2^,
				   fWidth, cols);

		DoTrapRow (srcPtr4, srcPtr3, dstPtr3, buffer1^, buffer2^,
				   fWidth, cols);

		DoTrapRow (srcPtr1, srcPtr2, dstPtr2, buffer1^, buffer2^,
				   (fWidth + 1) DIV 2, cols);

		DoTrapRow (srcPtr1, srcPtr3, dstPtr3, buffer1^, buffer2^,
				   fWidth, cols);

		DoTrapRow (srcPtr2, srcPtr1, dstPtr1, buffer1^, buffer2^,
				   fWidth DIV 2, cols);

		DoTrapRow (srcPtr2, srcPtr3, dstPtr3, buffer1^, buffer2^,
				   fWidth, cols);

		dstArray1.DoneWithPtr;
		dstArray2.DoneWithPtr;
		dstArray3.DoneWithPtr;

		srcArray1.DoneWithPtr;
		srcArray2.DoneWithPtr;
		srcArray3.DoneWithPtr;
		srcArray4.DoneWithPtr;

		srcPtr1 := NIL;
		srcPtr2 := NIL;
		srcPtr3 := NIL;
		srcPtr4 := NIL

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ATrap}

PROCEDURE TTrapCommand.CombineTrap (srcArray: TVMArray;
									dstArray: TVMArray);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		half: LONGINT;
		total: LONGINT;
		median: INTEGER;
		hist: THistogram;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		IF srcPtr <> NIL THEN srcArray.DoneWithPtr;

		srcArray.Flush;
		dstArray.Flush

		END;

	BEGIN

	dstArray.HistBytes (hist);

	half := fDoc.fRows * ORD4 (fDoc.fCols) DIV 2;

	total := 0;

	FOR median := 0 TO 255 DO
		BEGIN
		total := total + hist [median];
		IF total >= half THEN LEAVE
		END;

	srcPtr := NIL;

	CatchFailures (fi, CleanUp);

	FOR row := 0 TO fDoc.fRows - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row, fDoc.fRows);

		srcPtr := srcArray.NeedPtr (row, row, FALSE);
		dstPtr := dstArray.NeedPtr (row, row, TRUE);

		DoCombineTrap (srcPtr, dstPtr, median, fDoc.fCols);

		dstArray.DoneWithPtr;
		srcArray.DoneWithPtr;

		srcPtr := NIL

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ATrap}

PROCEDURE TTrapCommand.DoIt; OVERRIDE;

	VAR
		fi: FailInfo;
		channel: INTEGER;
		aVMArray: TVMArray;
		interleave: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress
		END;

	BEGIN

	FOR channel := 0 TO 6 DO
		BEGIN

		MoveHands (TRUE);

		IF channel <= 3 THEN
			interleave := 4 - channel
		ELSE
			interleave := 1;

		aVMArray := NewVMArray (fDoc.fCols, fDoc.fRows, interleave);
		fBuffer [channel] := aVMArray

		END;

	CommandProgress (fCmdNumber);

	CatchFailures (fi, CleanUp);

	StartTask (1/20);

	FOR channel := 0 TO 3 DO
		BEGIN

		MoveHands (TRUE);

		StartTask (1 / (4 - channel));
		DoTransposeArray (fDoc.fData [channel],
						  fBuffer [channel],
						  FALSE, FALSE);
		FinishTask

		END;

	FinishTask;

	StartTask (8/19);
	TrapAcross (fBuffer [0],
				fBuffer [1],
				fBuffer [2],
				fBuffer [3],
				fBuffer [4],
				fBuffer [5],
				fBuffer [6],
				TRUE);
	FinishTask;

	FOR channel := 0 TO 3 DO
		BEGIN
		fBuffer [channel] . Free;
		fBuffer [channel] := NIL
		END;

	FOR channel := 0 TO 2 DO
		BEGIN

		MoveHands (TRUE);

		aVMArray := NewVMArray (fDoc.fRows, fDoc.fCols, 3 - channel);
		fBuffer [channel] := aVMArray

		END;

	StartTask (1/11);

	FOR channel := 0 TO 2 DO
		BEGIN

		MoveHands (TRUE);

		StartTask (1 / (3 - channel));
		DoTransposeArray (fBuffer [4 + channel],
						  fBuffer [channel],
						  FALSE, FALSE);
		FinishTask;

		fBuffer [4 + channel] . Free;
		fBuffer [4 + channel] := NIL

		END;

	FinishTask;

	StartTask (8/10);
	TrapAcross (fDoc.fData [0],
				fDoc.fData [1],
				fDoc.fData [2],
				fDoc.fData [3],
				fBuffer [0],
				fBuffer [1],
				fBuffer [2],
				FALSE);
	FinishTask;

	FOR channel := 0 TO 2 DO
		BEGIN
		StartTask (1 / (3 - channel));
		CombineTrap (fDoc.fData [channel], fBuffer [channel]);
		FinishTask
		END;

	Success (fi);

	CleanUp (0, 0);

	UndoIt

	END;

{*****************************************************************************}

{$S ATrap}

PROCEDURE TTrapCommand.UndoIt; OVERRIDE;

	VAR
		save: TVMArray;
		channel: INTEGER;

	PROCEDURE UpdateView (view: TImageView);
		BEGIN
		IF view.fChannel <= 2 THEN
			view.fFrame.ForceRedraw
		END;

	BEGIN

	fDoc.FreeFloat;

	FOR channel := 0 TO 2 DO
		BEGIN
		save				 := fBuffer    [channel];
		fBuffer    [channel] := fDoc.fData [channel];
		fDoc.fData [channel] := save
		END;

	fDoc.fViewList.Each (UpdateView)

	END;

{*****************************************************************************}

{$S ATrap}

PROCEDURE TTrapCommand.RedoIt; OVERRIDE;

	BEGIN
	UndoIt
	END;

{*****************************************************************************}

{$S ATrap}

FUNCTION DoTrapCommand (view: TImageView): TCommand;

	CONST
		kDialogID	= 1011;
		kHookItem	= 3;
		kWidthItem	= 4;
		kUnitsItem	= 5;
		kUnitsMenu	= 1012;

	VAR
		fi: FailInfo;
		res: EXTENDED;
		bound: LONGINT;
		scale: EXTENDED;
		hitItem: INTEGER;
		doc: TImageDocument;
		aBWDialog: TBWDialog;
		aTrapCommand: TTrapCommand;
		aUnitSelector: TUnitSelector;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	doc := TImageDocument (view.fDocument);

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	aUnitSelector := aBWDialog.DefineUnitSelector
					 (kUnitsItem, kWidthItem, 1, FALSE,
					  kUnitsMenu, gTrapUnit);

	res := doc.fStyleInfo.fResolution.value / $10000;

	aUnitSelector.DefineUnit (1, 0, 0, 1, 10);

	scale := res / 72;
	bound := Max (1, Min (999, ROUND (1000 / scale)));

	aUnitSelector.DefineUnit (scale, 0, 2, 1, bound);

	scale := res / 25.4;
	bound := Max (1, Min (999, ROUND (1000 / scale)));

	aUnitSelector.DefineUnit (scale, 0, 2, 1, bound);

	aUnitSelector.StuffFixed (0, gTrapWidth * $10000);

	aBWDialog.SetEditSelection (kWidthItem);

	aBWDialog.TalkToUser (hitItem, StdItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	gTrapWidth := Max (1, Min (10, FixRound (aUnitSelector.GetFixed (0))));
	gTrapUnit  := aUnitSelector.fPick;

	Success (fi);

	CleanUp (0, 0);

	NEW (aTrapCommand);
	FailNil (aTrapCommand);

	aTrapCommand.ITrapCommand (view, gTrapWidth);

	DoTrapCommand := aTrapCommand

	END;

{*****************************************************************************}

END.

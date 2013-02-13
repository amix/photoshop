{Photoshop version 1.0.1, file: UFilter.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UFilter;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UBWDialog, UCommands, UFilters, UProgress, FilterInterface;

TYPE

	TFilterArrays = ARRAY [0..2] OF TVMArray;

	TFilterCommand = OBJECT (TFloatCommand)

		fChannel: INTEGER;

		fAutoMask: BOOLEAN;

		fWholeImage: BOOLEAN;

		PROCEDURE TFilterCommand.IFilterCommand (view: TImageView);

		PROCEDURE TFilterCommand.DoFilter (srcArray: TVMArray;
										   dstArray: TVMArray;
										   r: Rect;
										   band: INTEGER);

		PROCEDURE TFilterCommand.DoFilters (srcArrays: TFilterArrays;
											dstArrays: TFilterArrays;
											maskArray: TVMArray;
											r: Rect;
											bands: INTEGER);

		PROCEDURE TFilterCommand.DoIt; OVERRIDE;

		PROCEDURE TFilterCommand.UndoIt; OVERRIDE;

		PROCEDURE TFilterCommand.RedoIt; OVERRIDE;

		END;

	TKernelElement = RECORD

		dr	  : INTEGER;	{ Row displacement }
		dc	  : INTEGER;	{ Column displacement }
		weight: INTEGER;	{ Pixel weight }

		shift : INTEGER;	{ If weight is power of 2, its power }
		offset: LONGINT 	{ Offset in memory to pixel }

		END;

	TKernel = RECORD

		count: INTEGER; 		{ Element count - 1 }
		scale: INTEGER; 		{ Overall scale }
		base : INTEGER; 		{ Overall additive constant }

		shift: INTEGER; 		{ If scale is power of 2, its power }

		valid: Rect;			{ Valid rectangle }

		data : ARRAY [0..0] OF TKernelElement

		END;

	PKernel = ^TKernel;
	HKernel = ^PKernel;

	TConvolveCommand = OBJECT (TFilterCommand)

		fKernel: HKernel;

		fMinDR: INTEGER;
		fMaxDR: INTEGER;

		fMinDC: INTEGER;
		fMaxDC: INTEGER;

		PROCEDURE TConvolveCommand.IConvolveCommand (view: TImageView;
													 kernel: HKernel);

		PROCEDURE TConvolveCommand.Free; OVERRIDE;

		PROCEDURE TConvolveCommand.PrepareKernel (rows: INTEGER;
												  cols: INTEGER;
												  rowBytes: INTEGER);

		PROCEDURE TConvolveCommand.DoFilter (srcArray: TVMArray;
											 dstArray: TVMArray;
											 r: Rect;
											 band: INTEGER); OVERRIDE;

		END;

	TOffsetFilter = OBJECT (TFilterCommand)

		fRowOffset: INTEGER;
		fColOffset: INTEGER;

		fEdgeMethod: INTEGER;

		PROCEDURE TOffsetFilter.IOffsetFilter (view: TImageView);

		PROCEDURE TOffsetFilter.DoFilter (srcArray: TVMArray;
										  dstArray: TVMArray;
										  r: Rect;
										  band: INTEGER); OVERRIDE;

		END;

	TGaussianFilter = OBJECT (TFilterCommand)

		fRadius: INTEGER;

		PROCEDURE TGaussianFilter.IGaussianFilter (view: TImageView);

		PROCEDURE TGaussianFilter.DoFilter (srcArray: TVMArray;
											dstArray: TVMArray;
											r: Rect;
											band: INTEGER); OVERRIDE;

		END;

	THighPassFilter = OBJECT (TGaussianFilter)

		PROCEDURE THighPassFilter.DoFilter (srcArray: TVMArray;
											dstArray: TVMArray;
											r: Rect;
											band: INTEGER); OVERRIDE;

		END;

	TUnsharpMaskFilter = OBJECT (TGaussianFilter)

		fAmount: INTEGER;

		PROCEDURE TUnsharpMaskFilter.IUnsharpMaskFilter (view: TImageView);

		PROCEDURE TUnsharpMaskFilter.DoFilter (srcArray: TVMArray;
											   dstArray: TVMArray;
											   r: Rect;
											   band: INTEGER); OVERRIDE;

		END;

	TMedianFilter = OBJECT (TFilterCommand)

		fRadius: INTEGER;

		PROCEDURE TMedianFilter.IMedianFilter (view: TImageView);

		PROCEDURE TMedianFilter.DoFilter (srcArray: TVMArray;
										  dstArray: TVMArray;
										  r: Rect;
										  band: INTEGER); OVERRIDE;

		END;

	TMaximumFilter = OBJECT (TFilterCommand)

		fRadius: INTEGER;

		PROCEDURE TMaximumFilter.IMaximumFilter (view: TImageView);

		PROCEDURE TMaximumFilter.DoFilter (srcArray: TVMArray;
										   dstArray: TVMArray;
										   r: Rect;
										   band: INTEGER); OVERRIDE;

		END;

	TMinimumFilter = OBJECT (TFilterCommand)

		fRadius: INTEGER;

		PROCEDURE TMinimumFilter.IMinimumFilter (view: TImageView);

		PROCEDURE TMinimumFilter.DoFilter (srcArray: TVMArray;
										   dstArray: TVMArray;
										   r: Rect;
										   band: INTEGER); OVERRIDE;

		END;

	T3by3Filter = OBJECT (TFilterCommand)

		fWhich: INTEGER;

		PROCEDURE T3by3Filter.I3by3Filter (view: TImageView; which: INTEGER);

		PROCEDURE T3by3Filter.DoFilter (srcArray: TVMArray;
										dstArray: TVMArray;
										r: Rect;
										band: INTEGER); OVERRIDE;

		END;

	TFacetFilter = OBJECT (TFilterCommand)

		PROCEDURE TFacetFilter.DoFilter (srcArray: TVMArray;
										 dstArray: TVMArray;
										 r: Rect;
										 band: INTEGER); OVERRIDE;

		END;

	TDiffuseFilter = OBJECT (TFilterCommand)

		fSeed: LONGINT;

		PROCEDURE TDiffuseFilter.DoFilter (srcArray: TVMArray;
										   dstArray: TVMArray;
										   r: Rect;
										   band: INTEGER); OVERRIDE;

		END;

	TAddNoiseFilter = OBJECT (TFilterCommand)

		fAmount: INTEGER;

		fGaussian: BOOLEAN;

		PROCEDURE TAddNoiseFilter.IAddNoiseFilter (view: TImageView;
												   amount: INTEGER;
												   gaussian: BOOLEAN);

		PROCEDURE TAddNoiseFilter.DoFilter (srcArray: TVMArray;
											dstArray: TVMArray;
											r: Rect;
											band: INTEGER); OVERRIDE;

		END;

	TMosaicFilter = OBJECT (TFilterCommand)

		fCellSize: INTEGER;

		PROCEDURE TMosaicFilter.IMosaicFilter (view: TImageView);

		PROCEDURE TMosaicFilter.DoFilter (srcArray: TVMArray;
										  dstArray: TVMArray;
										  r: Rect;
										  band: INTEGER); OVERRIDE;

		END;

	TAreaBuffer = OBJECT (TObject)

		fValid: BOOLEAN;
		fDirty: BOOLEAN;

		fData: Handle;

		fArea: Rect;
		fLoPlane: INTEGER;
		fHiPlane: INTEGER;

		fArrays: TFilterArrays;

		PROCEDURE TAreaBuffer.IAreaBuffer (dirty: BOOLEAN;
										   arrays: TFilterArrays);

		PROCEDURE TAreaBuffer.Free; OVERRIDE;

		PROCEDURE TAreaBuffer.MoveArea (save: BOOLEAN);

		PROCEDURE TAreaBuffer.NextArea (VAR area: Rect;
										loPlane: INTEGER;
										hiPlane: INTEGER;
										bands: INTEGER);

		PROCEDURE TAreaBuffer.LoadPtr (VAR dataPtr: Ptr;
									   VAR rowBytes: LONGINT);

		END;

	TPSFilter = OBJECT (TFilterCommand)

		fRepeating: BOOLEAN;
		fFilterInfo: HPlugInInfo;

		fCodeAddress: Ptr;

		PROCEDURE TPSFilter.IPSFilter (view: TImageView;
									   repeating: BOOLEAN;
									   filterInfo: HPlugInInfo);

		PROCEDURE TPSFilter.CallFilter (selector: INTEGER;
										VAR stuff: FilterRecord;
										testResult: BOOLEAN);

		PROCEDURE TPSFilter.InnerFilterLoop (srcArrays: TFilterArrays;
											 dstArrays: TFilterArrays;
											 maskArray: TVMArray;
											 r: Rect;
											 bands: INTEGER;
											 VAR stuff: FilterRecord);

		PROCEDURE TPSFilter.DoPlugInFilters (srcArrays: TFilterArrays;
											 dstArrays: TFilterArrays;
											 maskArray: TVMArray;
											 r: Rect;
											 bands: INTEGER);

		PROCEDURE TPSFilter.DoFilters (srcArrays: TFilterArrays;
									   dstArrays: TFilterArrays;
									   maskArray: TVMArray;
									   r: Rect;
									   bands: INTEGER); OVERRIDE;

		END;

	TDDFilter = OBJECT (TFilterCommand)

		fFilterInfo: HPlugInInfo;

		PROCEDURE TDDFilter.IDDFilter (view: TImageView;
									   filterInfo: HPlugInInfo);

		PROCEDURE TDDFilter.DoFilter (srcArray: TVMArray;
									  dstArray: TVMArray;
									  r: Rect;
									  band: INTEGER); OVERRIDE;

		END;

PROCEDURE InitFilters;

FUNCTION DoFilterCommand (view: TImageView;
						  name: Str255;
						  repeating: BOOLEAN): TCommand;

IMPLEMENTATION

{$I UAssembly.a.inc}
{$I UFilters.a.inc}
{$I UResize.a.inc}

CONST

	kPSFilterType = '8BFM';
	kDDFilterType = 'G8tc';

	kKernelFileType = '8BCK';

TYPE

	T5by5Kernel = ARRAY [1..27] OF INTEGER;

	TFilterTemplate = RECORD

		CASE kind: INTEGER OF

		0: (scale: INTEGER;
			base : INTEGER;
			count: INTEGER;
			data : ARRAY [0..0] OF
						RECORD
						dr	  : INTEGER;
						dc	  : INTEGER;
						weight: INTEGER
						END);

		1: (params: INTEGER;
			info  : ARRAY [1..kMaxParameters] OF
						RECORD
						digits: -2..8;
						blank : BOOLEAN;
						min   : LONGINT;
						max   : LONGINT;
						value : LONGINT
						END)

		END;

	PFilterTemplate = ^TFilterTemplate;
	HFilterTemplate = ^PFilterTemplate;

VAR
	gFilterName: Str255;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitFilters;

	BEGIN

	gFirstPSFilter := NIL;
	gFirstDDFilter := NIL;
	
	{$IFC qPlugIns}

	{$IFC NOT qBarneyscan}
	InitPlugInList (kPSFilterType, 1, 3, gFirstPSFilter, cFilter);
	{$ENDC}

	{$IFC FALSE}
	InitPlugInList (kDDFilterType, 1, 1, gFirstDDFilter, cFilter);
	{$ENDC}
	
	{$ENDC}

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TFilterCommand.IFilterCommand (view: TImageView);

	BEGIN

	IFloatCommand (cRepeatFilter, view);

	fChannel := view.fChannel;

	fWholeImage := EmptyRect (fDoc.fSelectionRect) OR
				   (fDoc.fSelectionMask 	   = NIL	   ) AND
				   (fDoc.fSelectionRect.top    = 0		   ) AND
				   (fDoc.fSelectionRect.left   = 0		   ) AND
				   (fDoc.fSelectionRect.bottom = fDoc.fRows) AND
				   (fDoc.fSelectionRect.right  = fDoc.fCols);

	IF fWasFloating THEN fWholeImage := FALSE

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TFilterCommand.DoFilter (srcArray: TVMArray;
								   dstArray: TVMArray;
								   r: Rect;
								   band: INTEGER);

	BEGIN

	{$IFC qDebug}
	ProgramBreak ('Need to OVERRIDE DoFilter')
	{$ENDC}

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TFilterCommand.DoFilters (srcArrays: TFilterArrays;
									dstArrays: TFilterArrays;
									maskArray: TVMArray;
									r: Rect;
									bands: INTEGER);

	VAR
		band: INTEGER;

	BEGIN

	FOR band := 0 TO bands - 1 DO
		BEGIN

		StartTask (1 / (bands - band));

		DoFilter (srcArrays [band],
				  dstArrays [band],
				  r,
				  band);

		FinishTask

		END

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TFilterCommand.DoIt; OVERRIDE;

	VAR
		r: Rect;
		channel: INTEGER;
		channels: INTEGER;
		aVMArray: TVMArray;
		saveMask: TVMArray;
		srcArrays: TFilterArrays;
		dstArrays: TFilterArrays;

	PROCEDURE RunFilter (maskArray: TVMArray);

		VAR
			s: Str255;
			fi: FailInfo;

		PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
			BEGIN
			FinishProgress
			END;

		BEGIN

		CmdToName (cFilter, s);

		INSERT (':  ', s, LENGTH (s) + 1);
		INSERT (gFilterName, s, LENGTH (s) + 1);

		StartProgress (s);

		CatchFailures (fi, CleanUp);
		DoFilters (srcArrays, dstArrays, maskArray, r, channels);
		Success (fi);

		CleanUp (0, 0);

		END;

	BEGIN

	MoveHands (TRUE);

	IF fChannel = kRGBChannels THEN
		channels := 3
	ELSE
		channels := 1;

	IF fWholeImage THEN
		BEGIN

		fDoc.KillEffect (TRUE);
		fDoc.FreeFloat;

		fDoc.GetBoundsRect (r);

		FOR channel := 0 TO channels - 1 DO
			BEGIN
			aVMArray := NewVMArray (fDoc.fRows,
									fDoc.fCols,
									channels - channel);
			fBuffer [channel] := aVMArray
			END;

		IF fChannel = kRGBChannels THEN
			FOR channel := 0 TO 2 DO
				BEGIN
				srcArrays [channel] := fDoc.fData [channel];
				dstArrays [channel] := fBuffer	  [channel]
				END
		ELSE
			BEGIN
			srcArrays [0] := fDoc.fData [fChannel];
			dstArrays [0] := fBuffer	[0]
			END;

		RunFilter (NIL);

		UndoIt

		END

	ELSE IF fWasFloating THEN
		BEGIN

		FloatSelection (TRUE);

		fExactFloat := FALSE;

		fFloatRect := fDoc.fFloatRect;

		SetRect (r, 0, 0, fFloatRect.right - fFloatRect.left,
						  fFloatRect.bottom - fFloatRect.top);

		FOR channel := 0 TO channels - 1 DO
			BEGIN

			aVMArray := NewVMArray (r.bottom, r.right, channels - channel);
			fFloatData [channel] := aVMArray;

			srcArrays [channel] := fDoc.fFloatData [channel];
			dstArrays [channel] := aVMArray

			END;

		RunFilter (fDoc.fFloatMask);

		UndoIt

		END

	ELSE
		BEGIN

		FloatSelection (TRUE);

		fDoc.fSelectionFloating := FALSE;

		fDoc.fExactFloat := FALSE;

		fFloatRect := fDoc.fFloatRect;

		r := fFloatRect;

		FOR channel := 0 TO channels - 1 DO
			fDoc.fFloatData [channel] . Undefine;

		IF fChannel = kRGBChannels THEN
			FOR channel := 0 TO 2 DO
				BEGIN
				srcArrays [channel] := fDoc.fData	   [channel];
				dstArrays [channel] := fDoc.fFloatData [channel]
				END
		ELSE
			BEGIN
			srcArrays [0] := fDoc.fData 	 [fChannel];
			dstArrays [0] := fDoc.fFloatData [0]
			END;

		fAutoMask := TRUE;

		RunFilter (fDoc.fSelectionMask);

		saveMask := fDoc.fFloatMask;

		IF NOT fAutoMask THEN
			fDoc.fFloatMask := NIL;

		BlendFloat (FALSE);

		fDoc.fFloatMask := saveMask;

		fDoc.UpdateImageArea (r, TRUE, TRUE, fChannel)

		END

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TFilterCommand.UndoIt; OVERRIDE;

	VAR
		r: Rect;
		channel: INTEGER;
		saveArray: TVMArray;

	BEGIN

	MoveHands (FALSE);

	IF fWholeImage THEN
		BEGIN

		IF fChannel = kRGBChannels THEN
			FOR channel := 0 TO 2 DO
				BEGIN
				saveArray			 := fDoc.fData [channel];
				fDoc.fData [channel] := fBuffer    [channel];
				fBuffer    [channel] := saveArray
				END
		ELSE
			BEGIN
			saveArray			  := fDoc.fData [fChannel];
			fDoc.fData [fChannel] := fBuffer	[0		 ];
			fBuffer    [0		] := saveArray
			END;

		fDoc.GetBoundsRect (r);

		fDoc.UpdateImageArea (r, TRUE, TRUE, fChannel)

		END

	ELSE IF fWasFloating THEN
		BEGIN

		IF NOT fDoc.fSelectionFloating THEN
			fDoc.DeSelect (TRUE);

		CopyBelow (FALSE);

		SwapFloat;

		BlendFloat (FALSE);

		ComputeOverlap (r);
		fDoc.UpdateImageArea (r, TRUE, TRUE, fChannel);

		IF NOT fDoc.fSelectionFloating THEN
			SelectFloat

		END

	ELSE
		BEGIN

		fDoc.DeSelect (NOT EqualRect (fFloatRect, fDoc.fSelectionRect));

		CopyBelow (FALSE);

		ComputeOverlap (r);
		fDoc.UpdateImageArea (r, FALSE, TRUE, fChannel);

		SelectFloat;
		fDoc.fSelectionFloating := FALSE

		END

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TFilterCommand.RedoIt; OVERRIDE;

	VAR
		r: Rect;
		saveMask: TVMArray;

	BEGIN

	IF fWholeImage OR fWasFloating THEN
		UndoIt

	ELSE
		BEGIN

		MoveHands (FALSE);

		fDoc.DeSelect (NOT EqualRect (fFloatRect, fDoc.fSelectionRect));

		saveMask := fDoc.fFloatMask;

		IF NOT fAutoMask THEN
			fDoc.fFloatMask := NIL;

		BlendFloat (FALSE);

		fDoc.fFloatMask := saveMask;

		ComputeOverlap (r);
		fDoc.UpdateImageArea (r, FALSE, TRUE, fChannel);

		SelectFloat;
		fDoc.fSelectionFloating := FALSE

		END

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TConvolveCommand.IConvolveCommand (view: TImageView;
											 kernel: HKernel);

	BEGIN

	fKernel := kernel;

	IFilterCommand (view)

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TConvolveCommand.Free; OVERRIDE;

	BEGIN

	DisposHandle (Handle (fKernel));

	INHERITED Free

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TConvolveCommand.PrepareKernel (rows: INTEGER;
										  cols: INTEGER;
										  rowBytes: INTEGER);

	VAR
		j: INTEGER;
		k: INTEGER;

	BEGIN

	WITH fKernel^^ DO
		BEGIN

		shift := -1;

		FOR j := 0 TO 14 DO
			IF BSL (1, j) = ABS (scale) THEN
				shift := j;

		fMinDR := data [0] . dr;
		fMaxDR := data [0] . dr;

		fMinDC := data [0] . dc;
		fMaxDC := data [0] . dc;

		{$PUSH}
		{$R-}

		FOR k := 0 TO count DO
			BEGIN

			fMinDR := Min (fMinDR, data [k] . dr);
			fMaxDR := Max (fMaxDR, data [k] . dr);

			fMinDC := Min (fMinDC, data [k] . dc);
			fMaxDC := Max (fMaxDC, data [k] . dc);

			data [k] . shift := -1;

			FOR j := 0 TO 14 DO
				IF BSL (1, j) = ABS (data [k] . weight) THEN
					data [k] . shift := j;

			data [k] . offset := data [k] . dr * ORD4 (rowBytes) +
								 data [k] . dc

			END;

		{$POP}

		valid.top  := Max (0, -fMinDR);
		valid.left := Max (0, -fMinDC);

		valid.bottom := rows - Max (0, fMaxDR);
		valid.right  := cols - Max (0, fMaxDC)

		END

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TConvolveCommand.DoFilter (srcArray: TVMArray;
									 dstArray: TVMArray;
									 r: Rect;
									 band: INTEGER); OVERRIDE;

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		row1: INTEGER;
		row2: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		srcArray.Flush
		END;

	BEGIN

	PrepareKernel (srcArray.fBlockCount,
				   srcArray.fLogicalSize,
				   srcArray.fPhysicalSize);

	CatchFailures (fi, CleanUp);

	FOR row := r.top TO r.bottom - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row - r.top, r.bottom - r.top);

		dstPtr := dstArray.NeedPtr (row - r.top, row - r.top, TRUE);

		row1 := Max (0, Min (row + fMinDR, srcArray.fBlockCount - 1));
		row2 := Max (0, Min (row + fMaxDR, srcArray.fBlockCount - 1));

		srcPtr := srcArray.NeedPtr (row1, row2, FALSE);

		srcPtr := Ptr (ORD4 (srcPtr) +
					   ORD4 (row - row1) * srcArray.fPhysicalSize +
					   r.left);

		ConvolveRow (srcPtr,
					 dstPtr,
					 srcArray.fBlockCount,
					 srcArray.fLogicalSize,
					 srcArray.fPhysicalSize,
					 row,
					 r.left,
					 r.right,
					 fKernel^);

		srcArray.DoneWithPtr;
		dstArray.DoneWithPtr

		END;

	UpdateProgress (1, 1);

	srcArray.Flush;
	dstArray.Flush;

	Success (fi)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TOffsetFilter.IOffsetFilter (view: TImageView);

	BEGIN

	fColOffset := gFilterParameter [1];
	fRowOffset := gFilterParameter [2];

	fEdgeMethod := gFilterParameter [3];

	IFilterCommand (view)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TOffsetFilter.DoFilter (srcArray: TVMArray;
								  dstArray: TVMArray;
								  r: Rect;
								  band: INTEGER); OVERRIDE;

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		back: INTEGER;
		rows: LONGINT;
		cols: LONGINT;
		last: INTEGER;
		first: INTEGER;
		width: INTEGER;
		count: INTEGER;
		srcRow: LONGINT;
		srcCol: LONGINT;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		srcArray.Flush
		END;

	BEGIN

	rows := srcArray.fBlockCount;
	cols := srcArray.fLogicalSize;

	back := fView.BackgroundByte (band);

	CatchFailures (fi, CleanUp);

	FOR row := r.top TO r.bottom - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row - r.top, r.bottom - r.top);

		dstPtr := dstArray.NeedPtr (row - r.top, row - r.top, TRUE);

		srcRow := row - ORD4 (fRowOffset);

			CASE fEdgeMethod OF

			1:	srcRow := Max (0, Min (srcRow, rows - 1));

			2:	IF srcRow >= 0 THEN
					srcRow := srcRow MOD rows
				ELSE
					srcRow := rows - 1 - ((-srcRow) - 1) MOD rows

			END;

		width := r.right - r.left;

		IF (srcRow < 0) OR (srcRow >= rows) THEN
			DoSetBytes (dstPtr, width, back)

		ELSE
			BEGIN

			srcPtr := srcArray.NeedPtr (srcRow, srcRow, FALSE);

			srcCol := r.left - ORD4 (fColOffset);

				CASE fEdgeMethod OF

				0, 1:
					BEGIN

					IF fEdgeMethod = 0 THEN
						BEGIN
						first := back;
						last  := back
						END
					ELSE
						BEGIN
						first := srcPtr^;
						last  := Ptr (ORD4 (srcPtr) + cols - 1)^
						END;

					IF srcCol < 0 THEN
						BEGIN
						count := Min (width, -srcCol);
						DoSetBytes (dstPtr, count, first);
						dstPtr := Ptr (ORD4 (dstPtr) + count);
						width := width - count;
						srcCol := 0
						END;

					IF width > 0 THEN
						BEGIN

						count := Min (width, cols - srcCol);

						IF count > 0 THEN
							BEGIN
							BlockMove (Ptr (ORD4 (srcPtr) + srcCol),
									   dstPtr, count);
							dstPtr := Ptr (ORD4 (dstPtr) + count);
							width := width - count
							END;

						IF width > 0 THEN
							DoSetBytes (dstPtr, width, last)

						END

					END;

				2:	BEGIN

					IF srcCol >= 0 THEN
						srcCol := srcCol MOD cols
					ELSE
						srcCol := cols - 1 - ((-srcCol) - 1) MOD cols;

					count := Min (width, cols - srcCol);

					BlockMove (Ptr (ORD4 (srcPtr) + srcCol), dstPtr, count);

					dstPtr := Ptr (ORD4 (dstPtr) + count);

					IF width > count THEN
						BlockMove (srcPtr, dstPtr, width - count)

					END

				END;

			srcArray.DoneWithPtr

			END;

		dstArray.DoneWithPtr

		END;

	UpdateProgress (1, 1);

	srcArray.Flush;
	dstArray.Flush;

	Success (fi)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TGaussianFilter.IGaussianFilter (view: TImageView);

	BEGIN

	fRadius := gFilterParameter [1];

	IFilterCommand (view)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TGaussianFilter.DoFilter (srcArray: TVMArray;
									dstArray: TVMArray;
									r: Rect;
									band: INTEGER); OVERRIDE;

	VAR
		rr: Rect;
		fi: FailInfo;
		buffer: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		buffer.Free
		END;

	BEGIN

	rr := r;

	IF (r.top  = 0) AND (r.bottom = srcArray.fBlockCount) AND
	   (r.left = 0) AND (r.right  = srcArray.fLogicalSize) THEN
		BEGIN

		srcArray.MoveArray (dstArray);

		GaussianFilter (dstArray,
						rr,
						fRadius,
						FALSE,
						TRUE)

		END

	ELSE
		BEGIN

		buffer := srcArray.CopyArray (1);

		CatchFailures (fi, CleanUp);

		GaussianFilter (buffer,
						rr,
						fRadius,
						FALSE,
						TRUE);

		SetRect (rr, 0, 0, r.right - r.left, r.bottom - r.top);

		buffer.MoveRect (dstArray, r, rr);

		Success (fi);

		CleanUp (0, 0)

		END

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE THighPassFilter.DoFilter (srcArray: TVMArray;
									dstArray: TVMArray;
									r: Rect;
									band: INTEGER); OVERRIDE;

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		IF srcPtr <> NIL THEN srcArray.DoneWithPtr;

		srcArray.Flush;
		dstArray.Flush

		END;

	BEGIN

	StartTask (0.9);

	INHERITED DoFilter (srcArray, dstArray, r, band);

	FinishTask;

	srcPtr := NIL;

	CatchFailures (fi, CleanUp);

	srcArray.Preload (2);

	FOR row := r.top TO r.bottom - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row - r.top, r.bottom - r.top);

		srcPtr := Ptr (ORD4 (srcArray.NeedPtr (row, row, FALSE)) + r.left);
		dstPtr := dstArray.NeedPtr (row - r.top, row - r.top, TRUE);

		DoHighPassLine (srcPtr, dstPtr, r.right - r.left);

		srcArray.DoneWithPtr;
		dstArray.DoneWithPtr;

		srcPtr := NIL

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TUnsharpMaskFilter.IUnsharpMaskFilter (view: TImageView);

	BEGIN

	fAmount := gFilterParameter [1];
	fRadius := gFilterParameter [2];

	IFilterCommand (view)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TUnsharpMaskFilter.DoFilter (srcArray: TVMArray;
									   dstArray: TVMArray;
									   r: Rect;
									   band: INTEGER); OVERRIDE;

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		IF srcPtr <> NIL THEN srcArray.DoneWithPtr;

		srcArray.Flush;
		dstArray.Flush

		END;

	BEGIN

	StartTask (0.9);

	INHERITED DoFilter (srcArray, dstArray, r, band);

	FinishTask;

	srcPtr := NIL;

	CatchFailures (fi, CleanUp);

	srcArray.Preload (2);

	FOR row := r.top TO r.bottom - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row - r.top, r.bottom - r.top);

		srcPtr := Ptr (ORD4 (srcArray.NeedPtr (row, row, FALSE)) + r.left);
		dstPtr := dstArray.NeedPtr (row - r.top, row - r.top, TRUE);

		DoUnsharpMaskLine (srcPtr, dstPtr, fAmount, r.right - r.left);

		srcArray.DoneWithPtr;
		dstArray.DoneWithPtr;

		srcPtr := NIL

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TMedianFilter.IMedianFilter (view: TImageView);

	BEGIN

	fRadius := gFilterParameter [1];

	IFilterCommand (view)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TMedianFilter.DoFilter (srcArray: TVMArray;
								  dstArray: TVMArray;
								  r: Rect;
								  band: INTEGER); OVERRIDE;

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		row1: INTEGER;
		row2: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		IF srcPtr <> NIL THEN srcArray.DoneWithPtr;

		srcArray.Flush;
		dstArray.Flush

		END;

	BEGIN

	srcPtr := NIL;

	CatchFailures (fi, CleanUp);

	FOR row := r.top TO r.bottom - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row - r.top, r.bottom - r.top);

		row1 := Max (row - fRadius, 0);
		row2 := Min (row + fRadius, srcArray.fBlockCount - 1);

		srcPtr := Ptr (ORD4 (srcArray.NeedPtr (row1, row2, FALSE)) + r.left);

		dstPtr := dstArray.NeedPtr (row - r.top, row - r.top, TRUE);

		DoMedianFilter (srcPtr,
						dstPtr,
						srcArray.fPhysicalSize,
						fRadius,
						r.right - r.left,
						row2 - row1 + 1,
						-r.left,
						srcArray.fLogicalSize - 1 - r.left);

		srcArray.DoneWithPtr;
		dstArray.DoneWithPtr;

		srcPtr := NIL

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TMaximumFilter.IMaximumFilter (view: TImageView);

	BEGIN

	fRadius := gFilterParameter [1];

	IFilterCommand (view)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TMaximumFilter.DoFilter (srcArray: TVMArray;
								   dstArray: TVMArray;
								   r: Rect;
								   band: INTEGER); OVERRIDE;

	BEGIN

	MinOrMaxFilter (srcArray, dstArray, r, fRadius, TRUE, FALSE)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TMinimumFilter.IMinimumFilter (view: TImageView);

	BEGIN

	fRadius := gFilterParameter [1];

	IFilterCommand (view)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TMinimumFilter.DoFilter (srcArray: TVMArray;
								   dstArray: TVMArray;
								   r: Rect;
								   band: INTEGER); OVERRIDE;

	BEGIN

	MinOrMaxFilter (srcArray, dstArray, r, fRadius, FALSE, FALSE)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE T3by3Filter.I3by3Filter (view: TImageView; which: INTEGER);

	BEGIN

	fWhich := which;

	IFilterCommand (view)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE T3by3Filter.DoFilter (srcArray: TVMArray;
								dstArray: TVMArray;
								r: Rect;
								band: INTEGER); OVERRIDE;


	BEGIN
	Do3by3Filter (srcArray, dstArray, r, fWhich)
	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TFacetFilter.DoFilter (srcArray: TVMArray;
								 dstArray: TVMArray;
								 r: Rect;
								 band: INTEGER); OVERRIDE;

	VAR
		r1: Rect;
		r2: Rect;
		fi: FailInfo;
		tempArray1: TVMArray;
		tempArray2: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (tempArray1);
		FreeObject (tempArray2)
		END;

	BEGIN

	MoveHands (TRUE);

	tempArray1 := NIL;
	tempArray2 := NIL;

	CatchFailures (fi, CleanUp);

	r1.top	  := Max (r.top    - 1, 0					 );
	r1.left   := Max (r.left   - 1, 0					 );
	r1.bottom := Min (r.bottom + 1, srcArray.fBlockCount );
	r1.right  := Min (r.right  + 1, srcArray.fLogicalSize);

	tempArray1 := NewVMArray (r1.bottom - r1.top, r1.right - r1.left, 1);
	tempArray2 := NewVMArray (r1.bottom - r1.top, r1.right - r1.left, 1);

	StartTask (0.6);
	Do3by3Filter (srcArray, tempArray1, r1, cFacetPass1);
	FinishTask;

	StartTask (0.5);
	Do3by3Filter (srcArray, tempArray2, r1, cFacetPass2);
	FinishTask;

	r2 := r;
	OffsetRect (r2, -r1.left, -r1.top);

	StartTask (0.5);
	Do3by3Filter (tempArray1, dstArray, r2, cFacetPass3);
	FinishTask;

	Do3by3Filter (tempArray2, dstArray, r2, cFacetPass4);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TDiffuseFilter.DoFilter (srcArray: TVMArray;
								   dstArray: TVMArray;
								   r: Rect;
								   band: INTEGER); OVERRIDE;

	CONST
		kExtraNoise = 2048;
		kMinDelta	= 32;

	VAR
		row: INTEGER;
		mode: INTEGER;
		offset: INTEGER;
		lastOffset: INTEGER;

	BEGIN

	IF band = 0 THEN
		BEGIN
		MakeDiffuseNoise (gBuffer, r.right - r.left + kExtraNoise);
		fSeed := randSeed
		END
	ELSE
		randSeed := fSeed;

	lastOffset := 0;

	StartTask (0.1);

	FOR row := 0 TO r.bottom - r.top - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row, r.bottom - r.top);

			REPEAT
			offset := ABS (ORD4 (Random)) MOD kExtraNoise
			UNTIL ABS (offset - lastOffset) >= kMinDelta;

		lastOffset := offset;

		BlockMove (Ptr (ORD4 (gBuffer) + offset),
				   dstArray.NeedPtr (row, row, TRUE),
				   r.right - r.left);

		dstArray.DoneWithPtr

		END;

	FinishTask;

	IF gFilterParameter [1] = 0 THEN
		mode := cFacetPass4
	ELSE IF gFilterParameter [1] = 1 THEN
		mode := cDiffuseDarken
	ELSE
		mode := cDiffuseLighten;

	Do3by3Filter (srcArray, dstArray, r, mode)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TAddNoiseFilter.IAddNoiseFilter (view: TImageView;
										   amount: INTEGER;
										   gaussian: BOOLEAN);

	BEGIN

	fAmount := amount;
	fGaussian := gaussian;

	IFilterCommand (view)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TAddNoiseFilter.DoFilter (srcArray: TVMArray;
									dstArray: TVMArray;
									r: Rect;
									band: INTEGER); OVERRIDE;

	CONST
		kExtraNoise = 4096;
		kMinDelta	= 32;

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		noisePtr: Ptr;
		width: INTEGER;
		buffer: Handle;
		count: LONGINT;
		offset: INTEGER;
		lastOffset: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		IF srcPtr <> NIL THEN srcArray.DoneWithPtr;

		srcArray.Flush;
		dstArray.Flush;

		FreeLargeHandle (buffer)

		END;

	BEGIN

	count := ORD4 (r.right - r.left) + kExtraNoise;

	buffer := NewLargeHandle (BSL (count, 1));

	MoveHHi (buffer);
	HLock (buffer);

	srcPtr := NIL;
	dstPtr := NIL;

	CatchFailures (fi, CleanUp);

	noisePtr := buffer^;

	WHILE count > 0 DO
		BEGIN

		MoveHands (TRUE);

		IF fGaussian THEN
			MakeGaussianNoise (noisePtr, fAmount, Min (count, 256))
		ELSE
			MakeUniformNoise (noisePtr, fAmount, Min (count, 256));

		noisePtr := Ptr (ORD4 (noisePtr) + 512);

		count := count - 256

		END;

	lastOffset := 0;

	FOR row := r.top TO r.bottom - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row - r.top, r.bottom - r.top);

			REPEAT
			offset := ABS (ORD4 (Random)) MOD kExtraNoise
			UNTIL ABS (offset - lastOffset) >= kMinDelta;

		lastOffset := offset;

		srcPtr := Ptr (ORD4 (srcArray.NeedPtr (row, row, FALSE)) + r.left);
		dstPtr := dstArray.NeedPtr (row - r.top, row - r.top, TRUE);

		DoAddNoise (srcPtr,
					dstPtr,
					Ptr (ORD4 (buffer^) + BSL (offset, 1)),
					r.right - r.left);

		srcArray.DoneWithPtr;
		dstArray.DoneWithPtr;

		srcPtr := NIL;
		dstPtr := NIL

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TMosaicFilter.IMosaicFilter (view: TImageView);

	BEGIN

	fCellSize := gFilterParameter [1];

	IFilterCommand (view)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TMosaicFilter.DoFilter (srcArray: TVMArray;
								  dstArray: TVMArray;
								  r: Rect;
								  band: INTEGER); OVERRIDE;

	VAR
		fi: FailInfo;
		row: INTEGER;
		size: LONGINT;
		width: INTEGER;
		block: INTEGER;
		count: INTEGER;
		buffer: Handle;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (buffer)
		END;

	BEGIN

	width := r.right - r.left;
	size  := SIZEOF (LONGINT) * ORD4 (width);

	buffer := NewLargeHandle (size);

	MoveHHi (buffer);
	HLock	(buffer);

	CatchFailures (fi, CleanUp);

	FOR block := 0 TO (r.bottom - r.top - 1) DIV fCellSize DO
		BEGIN

		count := 0;
		DoSetBytes (buffer^, size, 0);

		FOR row := r.top + block * fCellSize TO
				   Min (r.top + (block + 1) * fCellSize, r.bottom - 1) DO
			BEGIN
			MoveHands (TRUE);
			DoAddWeightedRow (Ptr (ORD4 (srcArray.NeedPtr (row, row, FALSE)) +
								   r.left),
							  buffer^,
							  width,
							  1);
			srcArray.DoneWithPtr;
			count := count + 1
			END;

		DoDivideRow (buffer^, width, count);

		DoMosaicRow (buffer^, fCellSize, width);

		FOR row := block * fCellSize TO block * fCellSize + count - 1 DO
			BEGIN
			MoveHands (TRUE);
			UpdateProgress (row - r.top, r.bottom - r.top);
			BlockMove (buffer^, dstArray.NeedPtr (row, row, TRUE), width);
			dstArray.DoneWithPtr
			END

		END;

	UpdateProgress (1, 1);

	srcArray.Flush;
	dstArray.Flush;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TAreaBuffer.IAreaBuffer (dirty: BOOLEAN;
								   arrays: TFilterArrays);

	BEGIN

	fValid := FALSE;
	fDirty := dirty;

	fArrays := arrays;

	fArea := gZeroRect;

	fData := NIL

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TAreaBuffer.Free; OVERRIDE;

	BEGIN

	IF fData <> NIL THEN
		FreeLargeHandle (fData);

	INHERITED Free

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TAreaBuffer.MoveArea (save: BOOLEAN);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		row: INTEGER;
		plane: INTEGER;
		width: INTEGER;
		planes: INTEGER;
		rowBytes: LONGINT;

	BEGIN

	width := fArea.right - fArea.left;

	planes := fHiPlane - fLoPlane + 1;

	rowBytes := ORD4 (width) * planes;

	FOR plane := fLoPlane TO fHiPlane DO
		BEGIN

		FOR row := fArea.top TO fArea.bottom - 1 DO
			BEGIN

			dstPtr := Ptr (ORD4 (fArrays [plane] .
								 NeedPtr (row, row, save)) +
						   fArea.left);

			srcPtr := Ptr (ORD4 (fData^) +
						   (plane - fLoPlane) +
						   (row - fArea.top) * rowBytes);

			IF planes = 1 THEN
				IF save THEN
					BlockMove (srcPtr, dstPtr, width)
				ELSE
					BlockMove (dstPtr, srcPtr, width)
			ELSE
				IF save THEN
					DoStepCopyBytes (srcPtr, dstPtr, width, planes, 1)
				ELSE
					DoStepCopyBytes (dstPtr, srcPtr, width, 1, planes);

			fArrays [plane] . DoneWithPtr

			END;

		fArrays [plane] . Flush

		END

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TAreaBuffer.NextArea (VAR area: Rect;
								loPlane: INTEGER;
								hiPlane: INTEGER;
								bands: INTEGER);

	VAR
		same: BOOLEAN;
		size: LONGINT;

	BEGIN

	IF fData <> NIL THEN HUnlock (fData);

	{$H-}

	IF (area.bottom <= area.top) OR (area.right <= area.left) THEN
		BEGIN
		area := gZeroRect;
		same := EmptyRect (fArea)
		END

	ELSE
		BEGIN

		IF (area.top	< 0 						) OR
		   (area.left	< 0 						) OR
		   (area.bottom > fArrays [0] . fBlockCount ) OR
		   (area.right	> fArrays [0] . fLogicalSize) OR
		   (loPlane <  0	  ) OR
		   (hiPlane >= bands  ) OR
		   (loPlane >  hiPlane) THEN Failure (filterBadParameters, 0);

		same := EqualRect (fArea, area) AND (fLoPlane = loPlane) AND
											(fHiPlane = hiPlane)

		END;

	{$H+}

	IF NOT same THEN
		BEGIN

		IF fValid AND fDirty THEN MoveArea (TRUE);

		fValid := FALSE;

		fArea	 := area;
		fLoPlane := loPlane;
		fHiPlane := hiPlane;

		size := ORD4 (area.right - area.left) *
					 (area.bottom - area.top) *
					 (hiPlane - loPlane + 1);

		IF fData <> NIL THEN
			IF GetHandleSize (fData) <> size THEN
				BEGIN
				FreeLargeHandle (fData);
				fData := NIL
				END

		END

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TAreaBuffer.LoadPtr (VAR dataPtr: Ptr;
							   VAR rowBytes: LONGINT);

	VAR
		h: Handle;

	BEGIN

	dataPtr := NIL;

	rowBytes := ORD4 (fArea.right - fArea.left) *
					 (fHiPlane - fLoPlane + 1);

	IF rowBytes > 0 THEN
		BEGIN

		IF NOT fValid THEN
			BEGIN

			IF fData = NIL THEN
				BEGIN
				h := NewLargeHandle (rowBytes * (fArea.bottom - fArea.top));
				fData := h
				END;

			MoveArea (FALSE);
			fValid := TRUE

			END;

		HLock (fData);
		dataPtr := fData^

		END

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TPSFilter.IPSFilter (view: TImageView;
							   repeating: BOOLEAN;
							   filterInfo: HPlugInInfo);

	BEGIN

	fRepeating	:= repeating;
	fFilterInfo := filterInfo;

	IFilterCommand (view)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TPSFilter.CallFilter (selector: INTEGER;
								VAR stuff: FilterRecord;
								testResult: BOOLEAN);

	VAR
		data: LONGINT;
		result: INTEGER;

	PROCEDURE DoCallFilter (selector: INTEGER;
							stuff: FilterRecordPtr;
							VAR data: LONGINT;
							VAR result: INTEGER;
							codeAddress: Ptr); INLINE $205F, $4E90;

	BEGIN

	data			 := fFilterInfo^^.fData;
	stuff.parameters := fFilterInfo^^.fParameters;

	DoCallFilter (selector, @stuff, data, result, fCodeAddress);

	fFilterInfo^^.fParameters := stuff.parameters;
	fFilterInfo^^.fData 	  := data;

	IF testResult AND (result <> 0) THEN
		Failure (Min (0, result), 0)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TPSFilter.InnerFilterLoop (srcArrays: TFilterArrays;
									 dstArrays: TFilterArrays;
									 maskArray: TVMArray;
									 r: Rect;
									 bands: INTEGER;
									 VAR stuff: FilterRecord);

	VAR
		area1: Rect;
		area2: Rect;
		area3: Rect;
		fi: FailInfo;
		inBuffer: TAreaBuffer;
		outBuffer: TAreaBuffer;
		maskBuffer: TAreaBuffer;
		maskArrays: TFilterArrays;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeObject (inBuffer);
		FreeObject (outBuffer);
		FreeObject (maskBuffer);
		CallFilter (filterSelectorFinish, stuff, FALSE)
		END;

	BEGIN

	inBuffer := NIL;
	outBuffer := NIL;
	maskBuffer := NIL;

	stuff.inRect := gZeroRect;
	stuff.outRect := gZeroRect;
	stuff.maskRect := gZeroRect;

	CallFilter (filterSelectorStart, stuff, TRUE);

	CatchFailures (fi, CleanUp);

	NEW (inBuffer);
	FailNil (inBuffer);

	inBuffer.IAreaBuffer (FALSE, srcArrays);

	NEW (outBuffer);
	FailNil (outBuffer);

	outBuffer.IAreaBuffer (TRUE, dstArrays);

	IF maskArray <> NIL THEN
		BEGIN

		maskArrays [0] := maskArray;
		maskArrays [1] := NIL;
		maskArrays [2] := NIL;

		NEW (maskBuffer);
		FailNil (maskBuffer);

		maskBuffer.IAreaBuffer (FALSE, maskArrays)

		END;

	WHILE TRUE DO
		BEGIN

		MoveHands (TRUE);

		area1 := stuff.inRect;
		inBuffer.NextArea (area1, stuff.inLoPlane, stuff.inHiPlane, bands);

		area2 := stuff.outRect;
		OffsetRect (area2, -r.left, -r.top);
		outBuffer.NextArea (area2, stuff.outLoPlane, stuff.outHiPlane, bands);

		IF maskArray <> NIL THEN
			BEGIN
			area3 := stuff.maskRect;
			OffsetRect (area3, -r.left, -r.top);
			maskBuffer.NextArea (area3, 0, 0, 1)
			END
		ELSE
			area3 := gZeroRect;

		IF EmptyRect (area1) &
		   EmptyRect (area2) &
		   EmptyRect (area3) THEN LEAVE;

		inBuffer.LoadPtr (stuff.inData, stuff.inRowBytes);
		outBuffer.LoadPtr (stuff.outData, stuff.outRowBytes);

		IF maskArray <> NIL THEN
			maskBuffer.LoadPtr (stuff.maskData, stuff.maskRowBytes)
		ELSE
			BEGIN
			stuff.maskData := NIL;
			stuff.maskRowBytes := 0
			END;

		CallFilter (filterSelectorContinue, stuff, TRUE)

		END;

	UpdateProgress (1, 1);

	Success (fi);

	inBuffer.Free;
	outBuffer.Free;

	IF maskArray <> NIL THEN
		maskBuffer.Free;

	CallFilter (filterSelectorFinish, stuff, TRUE)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TPSFilter.DoPlugInFilters (srcArrays: TFilterArrays;
									 dstArrays: TFilterArrays;
									 maskArray: TVMArray;
									 r: Rect;
									 bands: INTEGER);

	VAR
		fi: FailInfo;
		space: LONGINT;
		stuff: FilterRecord;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		VMAdjustReserve (-space)
		END;

	PROCEDURE MakeMonochrome (VAR color: RGBColor);

		VAR
			gray: INTEGER;

		BEGIN
		gray := ORD (ConvertToGray (BSR (color.red	, 8),
									BSR (color.green, 8),
									BSR (color.blue , 8)));
		color.red	:= BSL (gray, 8) + gray;
		color.green := color.red;
		color.blue	:= color.red
		END;

	BEGIN

	WITH stuff DO
		BEGIN
		serialNumber := gSerialNumber;
		abortProc	 := @TestAbort;
		progressProc := @UpdateProgress
		END;

	IF NOT fRepeating THEN
		BEGIN
		SetCursor (arrow);
		CallFilter (filterSelectorParameters, stuff, TRUE)
		END;

	MoveHands (TRUE);

	WITH stuff DO
		BEGIN

		imageSize.h := srcArrays [0] . fLogicalSize;
		imageSize.v := srcArrays [0] . fBlockCount;
		planes		:= bands;
		filterRect	:= r;
		background	:= gBackgroundColor;
		foreground	:= gForegroundColor;
		maxSpace	:= VMCanReserve;
		bufferSpace := 0;
		isFloating	:= fWasFloating;
		haveMask	:= maskArray <> NIL;
		autoMask	:= TRUE;

		IF bands = 1 THEN
			BEGIN
			MakeMonochrome (background);
			MakeMonochrome (foreground)
			END

		END;

	CallFilter (filterSelectorPrepare, stuff, TRUE);

	space := stuff.bufferSpace;

	IF space < 0 THEN Failure (filterBadParameters, 0);

	MoveHands (TRUE);

	VMAdjustReserve (space);

	CatchFailures (fi, CleanUp);

	InnerFilterLoop (srcArrays, dstArrays, maskArray, r, bands, stuff);

	fAutoMask := stuff.autoMask;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TPSFilter.DoFilters (srcArrays: TFilterArrays;
							   dstArrays: TFilterArrays;
							   maskArray: TVMArray;
							   r: Rect;
							   bands: INTEGER); OVERRIDE;

	VAR
		h: Handle;
		fi: FailInfo;
		refNum: INTEGER;
		fileName: Str255;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		IF h <> NIL THEN
			BEGIN
			HUnlock (h);
			HPurge (h)
			END;

		IF refNum <> -1 THEN
			CloseResFile (refNum)

		END;

	BEGIN

	h := NIL;
	refNum := -1;

	CatchFailures (fi, CleanUp);

	fileName := fFilterInfo^^.fFileName;

	IF LENGTH (fileName) <> 0 THEN
		BEGIN
		FailOSErr (SetVol (NIL, gPouchRefNum));
		refNum := OpenResFile (fileName);
		FailResError
		END;

	h := GetResource (fFilterInfo^^.fKind, fFilterInfo^^.fResourceID);
	FailResError;
	FailNil (h);

	MoveHHi (h);
	HLock (h);

	fCodeAddress := StripAddress (h^);

	DoPlugInFilters (srcArrays, dstArrays, maskArray, r, bands);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TDDFilter.IDDFilter (view: TImageView;
							   filterInfo: HPlugInInfo);

	BEGIN

	fFilterInfo := filterInfo;

	IFilterCommand (view)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE TDDFilter.DoFilter (srcArray: TVMArray;
							  dstArray: TVMArray;
							  r: Rect;
							  band: INTEGER); OVERRIDE;

	TYPE
		FilterStruct = RECORD
			thePix	 : PixMapPtr;
			theRegion: RgnHandle;
			srcGrays : Ptr;
			dstGrays : Ptr;
			pad: ARRAY [0..255] OF LONGINT; 	{???}
			END;
		PFilterStruct = ^FilterStruct;

	VAR
		h: Handle;
		fi: FailInfo;
		row: INTEGER;
		data: LONGINT;
		ct: CTabHandle;
		space: LONGINT;
		buffer: Handle;
		refNum: INTEGER;
		result: INTEGER;
		aPixMap: PixMap;
		fileName: Str255;
		map: TLookUpTable;
		rowBytes: LONGINT;
		aRegion: RgnHandle;
		saveLimit: INTEGER;
		fixReserve: BOOLEAN;
		stuff: FilterStruct;

	PROCEDURE DoCallFilter (selector: INTEGER;
							stuff: PFilterStruct;
							VAR data: LONGINT;
							VAR result: INTEGER;
							codeAddress: Ptr); INLINE $205F, $4E90;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		IF buffer <> NIL THEN
			FreeLargeHandle (buffer);

		IF aRegion <> NIL THEN
			DisposeRgn (aRegion);

		IF ct <> NIL THEN
			DisposHandle (Handle (ct));

		IF refNum <> -1 THEN
			CloseResFile (refNum);

		IF fixReserve THEN
			VMAdjustReserve (-space);

		gVMMinPageLimit := saveLimit

		END;

	BEGIN

	buffer	   := NIL;
	aRegion    := NIL;
	ct		   := NIL;
	refNum	   := -1;
	fixReserve := FALSE;
	saveLimit  := gVMMinPageLimit;

	CatchFailures (fi, CleanUp);

	gVMMinPageLimit := 1;

	rowBytes := srcArray.fLogicalSize;

	IF ODD (rowBytes) THEN
		rowBytes := rowBytes + 1;

	buffer := NewLargeHandle (rowBytes * srcArray.fBlockCount);

	MoveHHi (buffer);
	HLock (buffer);

	FOR row := 0 TO srcArray.fBlockCount - 1 DO
		BEGIN

		BlockMove (srcArray.NeedPtr (row, row, FALSE),
				   Ptr (ORD4 (buffer^) + row * rowBytes),
				   srcArray.fLogicalSize);

		srcArray.DoneWithPtr

		END;

	srcArray.Flush;

	DoMapBytes (buffer^, rowBytes * srcArray.fBlockCount, gInvertLUT);

	ct := MakeMonochromeTable (256);

	aPixMap.baseAddr	  := buffer^;
	aPixMap.rowBytes	  := BOR ($8000, rowBytes);
	aPixMap.bounds.top	  := 0;
	aPixMap.bounds.left   := 0;
	aPixMap.bounds.bottom := srcArray.fBlockCount;
	aPixMap.bounds.right  := srcArray.fLogicalSize;
	aPixMap.pmVersion	  := 0;
	aPixMap.packType	  := 0;
	aPixMap.packSize	  := 0;
	aPixMap.hRes		  := Fixed ($480000);
	aPixMap.vRes		  := Fixed ($480000);
	aPixMap.pixelType	  := 0;
	aPixMap.pixelSize	  := 8;
	aPixMap.cmpCount	  := 1;
	aPixMap.cmpSize 	  := 8;
	aPixMap.planeBytes	  := 0;
	aPixMap.pmTable 	  := ct;
	aPixMap.pmReserved	  := 0;

	aRegion := NewRgn;
	RectRgn (aRegion, r);

	DoSetBytes (@map, 256, 1);

	DoSetBytes (@stuff, SIZEOF (FilterStruct), 0); {???}

	stuff.thePix	:= @aPixMap;
	stuff.theRegion := aRegion;
	stuff.srcGrays	:= @map;
	stuff.dstGrays	:= @map;

	data := fFilterInfo^^.fData;

	space := VMCanReserve;

	VMAdjustReserve (space);

	fixReserve := TRUE;

	fileName := fFilterInfo^^.fFileName;

	IF LENGTH (fileName) <> 0 THEN
		BEGIN
		FailOSErr (SetVol (NIL, gPouchRefNum));
		refNum := OpenResFile (fileName);
		FailResError
		END;

	h := GetResource (fFilterInfo^^.fKind, fFilterInfo^^.fResourceID);
	FailResError;
	FailNil (h);

	MoveHHi (h);
	HLock (h);

	SetCursor (arrow);

	DoCallFilter (1, @stuff, data, result, StripAddress (h^));

	HUnlock (h);
	HPurge (h);

	fFilterInfo^^.fData := data;

	IF result <> 0 THEN Failure (0, 0);

	MoveHands (TRUE);

	IF refNum <> -1 THEN
		BEGIN
		CloseResFile (refNum);
		refNum := -1
		END;

	VMAdjustReserve (-space);

	fixReserve := FALSE;

	FOR row := r.top TO r.bottom - 1 DO
		BEGIN

		BlockMove (Ptr (ORD4 (buffer^) + row * rowBytes + r.left),
				   dstArray.NeedPtr (row - r.top, row - r.top, TRUE),
				   r.right - r.left);

		dstArray.DoneWithPtr

		END;

	dstArray.Flush;

	dstArray.MapBytes (gInvertLUT);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoFilter}

FUNCTION CopyKernel (template: HFilterTemplate): HKernel;

	VAR
		item: INTEGER;
		kernel: HKernel;

	BEGIN

	HNoPurge (Handle (template));

	kernel := HKernel (NewHandle (SIZEOF (TKernel) +
								  SIZEOF (TKernelElement) *
								  (template^^.count - 1)));

	HPurge (Handle (template));

	FailNil (kernel);

	kernel^^.count := template^^.count - 1;
	kernel^^.scale := template^^.scale;
	kernel^^.base  := template^^.base;

	FOR item := 0 TO kernel^^.count DO
		BEGIN

		{$PUSH}
		{$R-}

		kernel^^.data [item] . dr	  := template^^.data [item] . dr;
		kernel^^.data [item] . dc	  := template^^.data [item] . dc;
		kernel^^.data [item] . weight := template^^.data [item] . weight;

		{$POP}

		END;

	CopyKernel := kernel

	END;

{*****************************************************************************}

{$S ADoFilter}

FUNCTION MakeConvolveKernel: HKernel;

	VAR
		j: INTEGER;
		k: INTEGER;
		kernel: HKernel;

	BEGIN

	k := 0;
	FOR j := 1 TO 25 DO
		k := k + ORD (gFilterParameter [j] <> 0);

	kernel := HKernel (NewHandle (SIZEOF (TKernel) +
								  SIZEOF (TKernelElement) * Max (0, k - 1)));
	FailMemError;

	WITH kernel^^ DO
		BEGIN

		count := -1;
		scale := gFilterParameter [26];
		base  := gFilterParameter [27];

		{$PUSH}
		{$R-}

		FOR j := 1 TO 25 DO
			IF gFilterParameter [j] <> 0 THEN
				BEGIN
				count := count + 1;
				WITH data [count] DO
					BEGIN
					dr := (j - 1) DIV 5 - 2;
					dc := (j - 1) MOD 5 - 2;
					weight := gFilterParameter [j]
					END
				END;

		{$POP}

		IF count = -1 THEN
			BEGIN
			count := 0;
			WITH data [0] DO
				BEGIN
				dr := 0;
				dc := 0;
				weight := 0
				END
			END

		END;

	MakeConvolveKernel := kernel

	END;

{*****************************************************************************}

{$S ADoFilter}

FUNCTION MakeMotionBlurKernel: HKernel;

	VAR
		j: INTEGER;
		angle: EXTENDED;
		kernel: HKernel;
		distance: INTEGER;
		sinAngle: EXTENDED;
		cosAngle: EXTENDED;

	PROCEDURE AddElement (row, col, thisWeight: INTEGER);

		VAR
			j: INTEGER;

		BEGIN

		IF thisWeight = 0 THEN EXIT (AddElement);

		kernel^^.scale := kernel^^.scale + thisWeight;

		{$PUSH}
		{$R-}

		FOR j := kernel^^.count DOWNTO 0 DO
			WITH kernel^^.data [j] DO
				IF (dr = row) AND (dc = col) THEN
					BEGIN
					weight := weight + thisWeight;
					EXIT (AddElement)
					END;

		kernel^^.count := kernel^^.count + 1;

		SetHandleSize (Handle (kernel), SIZEOF (TKernel) +
										SIZEOF (TKernelElement) * kernel^^.count);
		FailMemError;

		WITH kernel^^.data [kernel^^.count] DO
			BEGIN
			dr	   := row;
			dc	   := col;
			weight := thisWeight
			END

		{$POP}

		END;

	PROCEDURE AddCoordinate (row, col: EXTENDED);

		VAR
			r: INTEGER;
			c: INTEGER;
			rr: INTEGER;
			cc: INTEGER;

		BEGIN

		r := ROUND (row * 8);
		c := ROUND (col * 8);

		rr := BAND (r, 7);
		cc := BAND (c, 7);

		r := (r - rr) DIV 8;
		c := (c - cc) DIV 8;

		AddElement (r	 , c	, (8 - rr) * (8 - cc));
		AddElement (r	 , c + 1, (8 - rr) *	  cc );
		AddElement (r + 1, c	,	   rr  * (8 - cc));
		AddElement (r + 1, c + 1,	   rr  *	  cc )

		END;

	BEGIN

	kernel := HKernel (NewHandle (SIZEOF (TKernel)));
	FailMemError;

	kernel^^.count := -1;
	kernel^^.scale := 0;
	kernel^^.base  := 0;

	angle := gFilterParameter [1] / 57.295779513;

	cosAngle := COS (angle);
	sinAngle := SIN (angle);

	distance := gFilterParameter [2];

	FOR j := 0 TO distance DO
		AddCoordinate (sinAngle * (j - distance * 0.5),
					   cosAngle * (j - distance * 0.5));

	MakeMotionBlurKernel := kernel

	END;

{*****************************************************************************}

{$S ADoFilter}

FUNCTION LoadKernel (VAR kernel: T5by5Kernel): BOOLEAN;

	VAR
		err: OSErr;
		fi: FailInfo;
		where: Point;
		reply: SFReply;
		count: LONGINT;
		refNum: INTEGER;
		typeList: SFTypeList;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF refNum <> -1 THEN
			err := FSClose (refNum);
		IF error <> noErr THEN
			gApplication.ShowError (error, msgCannotLoadKernel);
		EXIT (LoadKernel)
		END;

	BEGIN

	LoadKernel := FALSE;

	refNum := -1;

	CatchFailures (fi, CleanUp);

	WhereToPlaceDialog (getDlgID, where);

	typeList [0] := kKernelFileType;

	SFGetFile (where, '', NIL, 1, typeList, NIL, reply);
	IF NOT reply.good THEN Failure (0, 0);

	FailOSErr (FSOpen (reply.fName, reply.vRefNum, refNum));

	FailOSErr (GetEOF (refNum, count));

	IF count <> SIZEOF (T5by5Kernel) THEN Failure (eofErr, 0);

	FailOSErr (FSRead (refNum, count, @kernel));

	FailOSErr (FSClose (refNum));

	Success (fi);

	LoadKernel := TRUE

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE SaveKernel (kernel: T5by5Kernel);

	VAR
		fi: FailInfo;
		reply: SFReply;
		count: LONGINT;
		prompt: Str255;
		refNum: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		VAR
			ignore: OSErr;

		BEGIN
		IF refNum <> -1 THEN
			ignore := FSClose (refNum);
		IF error <> noErr THEN
			gApplication.ShowError (error, msgCannotSaveKernel);
		EXIT (SaveKernel)
		END;

	BEGIN

	refNum := -1;

	CatchFailures (fi, CleanUp);

	GetIndString (prompt, kStringsID, strSaveKernelIn);

	refNum := CreateOutputFile (prompt, kKernelFileType, reply);

	count := SIZEOF (T5by5Kernel);
	FailOSErr (FSWrite (refNum, count, @kernel));

	FailOSErr (FSClose (refNum));
	refNum := -1;

	FailOSErr (FlushVol (NIL, reply.vRefNum));

	Success (fi)

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE GetParameters (template: HFilterTemplate;
						 filterID: INTEGER;
						 repeating: BOOLEAN);

	CONST
		kHookItem	=  3;
		kFirstItem	=  4;
		kLoadKernel = 31;
		kSaveKernel = 32;

	VAR
		fi: FailInfo;
		item: INTEGER;
		param: INTEGER;
		params: INTEGER;
		haveText: BOOLEAN;
		aBWDialog: TBWDialog;
		paramItem: ARRAY [1..kMaxParameters] OF TObject;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	PROCEDURE DoLoadKernel;

		VAR
			r: Rect;
			j: INTEGER;
			kernel: T5by5Kernel;
			theText: TFixedText;

		BEGIN

		IF LoadKernel (kernel) THEN
			BEGIN

			SetPort (aBWDialog.fDialogPtr);

			SetRect (r, 0, 0, 1000, 1000);
			ValidRect (r);

			DrawDialog (aBWDialog.fDialogPtr);

			FOR j := 1 TO 27 DO
				BEGIN
				theText := TFixedText (paramItem [j]);
				IF kernel [j] = 0 THEN
					theText.StuffString ('')
				ELSE
					theText.StuffValue (kernel [j])
				END

			END;

		aBWDialog.SetEditSelection (kFirstItem);

		END;

	PROCEDURE DoSaveKernel;

		VAR
			j: INTEGER;
			succeeded: BOOLEAN;
			kernel: T5by5Kernel;
			theText: TFixedText;

		BEGIN

		FOR j := 1 TO 27 DO
			BEGIN
			theText := TFixedText (paramItem [j]);
			theText.Validate (succeeded);
			IF NOT succeeded THEN EXIT (DoSaveKernel);
			kernel [j] := theText.fValue
			END;

		SaveKernel (kernel)

		END;

	BEGIN

	HNoPurge (Handle (template));

	params := template^^.params;

	IF params = 0 THEN
		BEGIN
		HPurge (Handle (template));
		EXIT (GetParameters)
		END;

	FOR param := 1 TO params DO
		gFilterParameter [param] := template^^.info [param] . value;

	IF repeating THEN EXIT (GetParameters);

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (filterID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	item := kFirstItem;
	haveText := FALSE;

	FOR param := 1 TO params DO
		CASE template^^.info [param] . digits OF

		-2: BEGIN
			paramItem [param] := aBWDialog.DefineRadioCluster
								 (item, item + template^^.info [param] . max,
								  item + gFilterParameter [param]);
			item := item + 1 + template^^.info [param] . max
			END;

		-1: BEGIN
			paramItem [param] := aBWDialog.DefineCheckBox
								 (item, gFilterParameter [param] <> 0);
			item := item + 1
			END;

		OTHERWISE
			BEGIN
			paramItem [param] := aBWDialog.DefineFixedText
								 (item,
								  template^^.info [param] . digits,
								  template^^.info [param] . blank,
								  FALSE,
								  template^^.info [param] . min,
								  template^^.info [param] . max);
			IF NOT template^^.info [param] . blank OR
				   (gFilterParameter [param] <> 0) THEN
				TFixedText (paramItem [param]) . StuffValue
								  (gFilterParameter [param]);
			IF NOT haveText THEN
				aBWDialog.SetEditSelection (item);
			haveText := TRUE;
			item := item + 1
			END

		END;

		REPEAT

		aBWDialog.TalkToUser (item, StdItemHandling);

		IF item = cancel THEN Failure (0, 0);

		IF item = kLoadKernel THEN DoLoadKernel;

		IF item = kSaveKernel THEN DoSaveKernel

		UNTIL item = ok;

	FOR param := 1 TO params DO
		CASE template^^.info [param] . digits OF

		-2: gFilterParameter [param] :=
					TRadioCluster (paramItem [param]) . fChosenItem -
					TRadioCluster (paramItem [param]) . fFirstItem;

		-1: gFilterParameter [param] :=
					ORD (TCheckBox (paramItem [param]) . fChecked);

		OTHERWISE
			gFilterParameter [param] :=
					TFixedText (paramItem [param]) . fValue

		END;

	Success (fi);

	CleanUp (0, 0);

	FOR param := 1 TO params DO
		template^^.info [param] . value := gFilterParameter [param]

	END;

{*****************************************************************************}

{$S ADoFilter}

FUNCTION DoFilterCommand (view: TImageView;
						  name: Str255;
						  repeating: BOOLEAN): TCommand;

	VAR
		kernel: HKernel;
		filterID: INTEGER;
		ignoreName: Str255;
		ignoreType: ResType;
		aPSFilter: TPSFilter;
		aDDFilter: TDDFilter;
		filterInfo: HPlugInInfo;
		a3by3Filter: T3by3Filter;
		template: HFilterTemplate;
		aFacetFilter: TFacetFilter;
		aMedianFilter: TMedianFilter;
		aMosaicFilter: TMosaicFilter;
		anOffsetFilter: TOffsetFilter;
		aMaximumFilter: TMaximumFilter;
		aMinimumFilter: TMinimumFilter;
		aDiffuseFilter: TDiffuseFilter;
		aGaussianFilter: TGaussianFilter;
		aHighPassFilter: THighPassFilter;
		anAddNoiseFilter: TAddNoiseFilter;
		aConvolveCommand: TConvolveCommand;
		anUnsharpMaskFilter: TUnsharpMaskFilter;

	BEGIN

	gFilterName := name;

	IF IsPlugIn (name, gFirstPSFilter, filterInfo) THEN
		BEGIN

		NEW (aPSFilter);
		FailNil (aPSFilter);

		aPSFilter.IPSFilter (view, repeating, filterInfo);

		DoFilterCommand := aPSFilter;

		EXIT (DoFilterCommand)

		END;

	IF IsPlugIn (name, gFirstDDFilter, filterInfo) THEN
		BEGIN

		NEW (aDDFilter);
		FailNil (aDDFilter);

		aDDFilter.IDDFilter (view, filterInfo);

		DoFilterCommand := aDDFilter;

		EXIT (DoFilterCommand)

		END;

	template := HFilterTemplate (GetNamedResource ('FILT', name));
	FailNil (template);

	GetResInfo (Handle (template), filterID, ignoreType, ignoreName);
	FailOSErr (ResError);

	IF template^^.kind = 0 THEN
		BEGIN

		kernel := CopyKernel (template);

		NEW (aConvolveCommand);

		IF aConvolveCommand = NIL THEN
			DisposHandle (Handle (kernel));

		FailNil (aConvolveCommand);

		aConvolveCommand.IConvolveCommand (view, kernel);

		DoFilterCommand := aConvolveCommand

		END

	ELSE
		BEGIN

		GetParameters (template, filterID, repeating);

			CASE filterID OF

			cConvolve,
			cMotionBlur:
				BEGIN

				IF filterID = cConvolve THEN
					kernel := MakeConvolveKernel
				ELSE
					kernel := MakeMotionBlurKernel;

				NEW (aConvolveCommand);

				IF aConvolveCommand = NIL THEN
					DisposHandle (Handle (kernel));

				FailNil (aConvolveCommand);

				aConvolveCommand.IConvolveCommand (view, kernel);

				DoFilterCommand := aConvolveCommand

				END;

			cOffset:
				BEGIN

				IF (gFilterParameter [1] = 0) AND
				   (gFilterParameter [2] = 0) THEN Failure (0, 0);

				NEW (anOffsetFilter);
				FailNil (anOffsetFilter);

				anOffsetFilter.IOffsetFilter (view);

				DoFilterCommand := anOffsetFilter

				END;

			cGaussian:
				BEGIN

				NEW (aGaussianFilter);
				FailNil (aGaussianFilter);

				aGaussianFilter.IGaussianFilter (view);

				DoFilterCommand := aGaussianFilter

				END;

			cHighPass:
				BEGIN

				NEW (aHighPassFilter);
				FailNil (aHighPassFilter);

				aHighPassFilter.IGaussianFilter (view);

				DoFilterCommand := aHighPassFilter

				END;

			cUnsharpMask:
				BEGIN

				NEW (anUnsharpMaskFilter);
				FailNil (anUnsharpMaskFilter);

				anUnsharpMaskFilter.IUnsharpMaskFilter (view);

				DoFilterCommand := anUnsharpMaskFilter

				END;

			cMedian:
				BEGIN

				NEW (aMedianFilter);
				FailNil (aMedianFilter);

				aMedianFilter.IMedianFilter (view);

				DoFilterCommand := aMedianFilter

				END;

			cMaximum:
				BEGIN

				NEW (aMaximumFilter);
				FailNil (aMaximumFilter);

				aMaximumFilter.IMaximumFilter (view);

				DoFilterCommand := aMaximumFilter

				END;

			cMinimum:
				BEGIN

				NEW (aMinimumFilter);
				FailNil (aMinimumFilter);

				aMinimumFilter.IMinimumFilter (view);

				DoFilterCommand := aMinimumFilter

				END;

			cBlur,
			cBlurMore,
			cSharpen,
			cSharpenMore,
			cTraceContour,
			cSobel,
			cDespeckle,
			cSharpenEdges:
				BEGIN

				NEW (a3by3Filter);
				FailNil (a3by3Filter);

				a3by3Filter.I3by3Filter (view, filterID);

				DoFilterCommand := a3by3Filter

				END;

			cFacet:
				BEGIN

				NEW (aFacetFilter);
				FailNil (aFacetFilter);

				aFacetFilter.IFilterCommand (view);

				DoFilterCommand := aFacetFilter

				END;

			cDiffuse:
				BEGIN

				NEW (aDiffuseFilter);
				FailNil (aDiffuseFilter);

				aDiffuseFilter.IFilterCommand (view);

				DoFilterCommand := aDiffuseFilter

				END;

			cAddNoise:
				BEGIN

				NEW (anAddNoiseFilter);
				FailNil (anAddNoiseFilter);

				anAddNoiseFilter.IAddNoiseFilter (view,
												  gFilterParameter [1],
												  gFilterParameter [2] <> 0);

				DoFilterCommand := anAddNoiseFilter

				END;

			cMosaic:
				BEGIN

				NEW (aMosaicFilter);
				FailNil (aMosaicFilter);

				aMosaicFilter.IMosaicFilter (view);

				DoFilterCommand := aMosaicFilter

				END;

			OTHERWISE
				Failure (errNotYetImp, 0)

			END

		END

	END;

{*****************************************************************************}

END.

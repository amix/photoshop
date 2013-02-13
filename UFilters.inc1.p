{Photoshop version 1.0.1, file: UFilters.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}
{$I UFilters.a.inc}
{$I UFloat.a.inc}

CONST
	kMaxWRadius = 10;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ADoCommand}

PROCEDURE BoxFilter (srcData: TVMArray;
					 dstData: TVMArray;
					 r: Rect;
					 radius: INTEGER;
					 canAbort: BOOLEAN);

	VAR
		fi: FailInfo;
		row: INTEGER;
		size: LONGINT;
		buffer: Handle;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		FreeLargeHandle (buffer);

		srcData.Flush;
		dstData.Flush

		END;

	PROCEDURE UpdateBuffer (row: INTEGER; add: BOOLEAN);

		BEGIN

		row := Max (r.top, Min (row, r.bottom - 1));

		UpdateTotals (buffer^,
					  Ptr (ORD4 (srcData.NeedPtr (row, row, FALSE)) + r.left),
					  r.right - r.left,
					  radius,
					  add);

		srcData.DoneWithPtr;

		MoveHands (canAbort)

		END;

	BEGIN

	IF radius > 127 THEN Failure (1, 0);

	size := SIZEOF (INTEGER) * ORD4 (r.right - r.left + 2 * radius);

	buffer := NewLargeHandle (size);

	CatchFailures (fi, CleanUp);

	HLock (buffer);

	DoSetBytes (buffer^, size, 0);

	FOR row := r.top - radius TO r.top + radius DO
		UpdateBuffer (row, TRUE);

	FOR row := r.top TO r.bottom - 1 DO
		BEGIN

		UpdateProgress (row - r.top, r.bottom - r.top);

		DoBoxFilter (buffer^,
					 Ptr (ORD4 (dstData.NeedPtr (row, row, TRUE)) + r.left),
					 radius,
					 r.right - r.left);

		dstData.DoneWithPtr;

		UpdateBuffer (row - radius	  , FALSE);
		UpdateBuffer (row + radius + 1, TRUE )

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ADoCommand}

PROCEDURE WeightedFilter (data: TVMArray;
						  r: Rect;
						  radius: INTEGER;
						  width: INTEGER;
						  canAbort: BOOLEAN);

	CONST
		kShiftEvery  = 10;
		kMaxDiameter = 2 * kMaxWRadius;

	VAR
		j: INTEGER;
		fi: FailInfo;
		row: INTEGER;
		buffer: Handle;
		total: EXTENDED;
		offset: INTEGER;
		rowBytes: INTEGER;
		curve: ARRAY [0..kMaxDiameter] OF EXTENDED;
		weights: ARRAY [0..kMaxDiameter] OF INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		FreeLargeHandle (buffer);

		data.Flush

		END;

	PROCEDURE LoadRow (row: INTEGER; buffPtr: Ptr);

		VAR
			p: Ptr;

		BEGIN

		row := Max (r.top, Min (row, r.bottom - 1));

		p := Ptr (ORD4 (data.NeedPtr (row, row, FALSE)) + r.left);

		DoSetBytes (gBuffer,
					radius,
					p^);

		BlockMove (p,
				   Ptr (ORD4 (gBuffer) + radius),
				   r.right - r.left);

		DoSetBytes (Ptr (ORD4 (gBuffer) + (radius + r.right - r.left)),
					radius,
					Ptr (ORD4 (p) + (r.right - r.left - 1))^);

		data.DoneWithPtr;

		DoWeightedFilter (gBuffer,
						  buffPtr,
						  1,
						  r.right - r.left,
						  radius,
						  @weights);

		MoveHands (canAbort)

		END;

	BEGIN

	total := 0.0;

	FOR j := 0 TO radius * 2 DO
		BEGIN
		curve [j] := EXP (-SQR ((j - radius) * 10.0 / width) * 0.5);
		total := total + curve [j]
		END;

	FOR j := 0 TO radius * 2 DO
		weights [j] := Min (65535, ROUND (curve [j] / total * 65536.0));

	WHILE weights [0] = 0 DO
		BEGIN
		radius := radius - 1;
		FOR j := 0 TO radius * 2 DO
			weights [j] := weights [j + 1]
		END;

	IF radius = 0 THEN EXIT (WeightedFilter);

	rowBytes := BAND (r.right - r.left + 3, $FFFC);

	buffer := NewLargeHandle (ORD4 (2 * radius + kShiftEvery) * rowBytes);

	CatchFailures (fi, CleanUp);

	HLock (buffer);

	FOR row := 0 TO 2 * radius DO
		LoadRow (row + r.top - radius,
				 Ptr (ORD4 (buffer^) + ORD4 (row) * rowBytes));

	offset := 0;

	FOR row := r.top TO r.bottom - 1 DO
		BEGIN

		UpdateProgress (row - r.top, r.bottom - r.top);

		DoWeightedFilter (Ptr (ORD4 (buffer^) + ORD4 (offset) * rowBytes),
						  Ptr (ORD4 (data.NeedPtr (row, row, TRUE)) + r.left),
						  rowBytes,
						  r.right - r.left,
						  radius,
						  @weights);

		data.DoneWithPtr;

		IF row <> r.bottom - 1 THEN
			BEGIN

			offset := offset + 1;

			IF offset = kShiftEvery THEN
				BEGIN
				BlockMove (Ptr (ORD4 (buffer^) + ORD4 (offset) * rowBytes),
						   buffer^,
						   rowBytes * ORD4 (2 * radius));
				offset := 0
				END;

			LoadRow (row + radius + 1,
					 Ptr (ORD4 (buffer^) +
						  ORD4 (2 * radius + offset) * rowBytes));

			END

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE GaussianFilter (data: TVMArray;
						  VAR r: Rect;
						  width: INTEGER;
						  quick: BOOLEAN;
						  canAbort: BOOLEAN);

	VAR
		fi: FailInfo;
		goal: LONGINT;
		pass: INTEGER;
		temp: TVMArray;
		count: INTEGER;
		passes: INTEGER;
		radius: INTEGER;
		subGoal: LONGINT;
		radiusList: ARRAY [0..5] OF INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		temp.Free;
		data.Flush
		END;

	BEGIN

	radius := (width + 1) DIV 2;

	r.top  := Max (r.top  - radius, 0);
	r.left := Max (r.left - radius, 0);

	r.bottom := Min (r.bottom + radius, data.fBlockCount);
	r.right  := Min (r.right  + radius, data.fLogicalSize);

	IF NOT quick AND (radius <= kMaxWRadius) THEN
		WeightedFilter (data, r, radius, width, canAbort)

	ELSE
		BEGIN

		temp := NewVMArray (data.fBlockCount, data.fLogicalSize, 1);

		CatchFailures (fi, CleanUp);

		goal := SQR (ORD4 (width)) * 3 DIV 100;

		IF quick THEN
			passes := 3
		ELSE
			passes := 5;

		count := 0;

		FOR pass := passes DOWNTO ORD (quick) DO
			BEGIN

			IF pass > 1 THEN
				subGoal := goal DIV pass
			ELSE
				subGoal := goal;

			radius := 0;

			WHILE (radius + 1) * (radius + 2) <= subGoal DO
				radius := radius + 1;

			IF radius > 0 THEN
				BEGIN

				radiusList [count] := radius;

				count := count + 1

				END;

			goal := goal - radius * (radius + 1)

			END;

		FOR pass := 0 TO count - 1 DO
			BEGIN

			StartTask (1 / (count - pass));

			radius := radiusList [pass];

			IF ODD (pass) THEN
				BoxFilter (temp, data, r, radius, canAbort)
			ELSE
				BoxFilter (data, temp, r, radius, canAbort);

			FinishTask

			END;

		IF ODD (count) THEN
			temp.MoveRect (data, r, r);

		Success (fi);

		CleanUp (0, 0)

		END

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE MinOrMaxOnce (srcArray: TVMArray;
						dstArray: TVMArray;
						r1: Rect;
						r2: Rect;
						maxFlag: BOOLEAN;
						connect8: BOOLEAN);

	VAR
		r: Rect;
		fi: FailInfo;
		row: INTEGER;
		prevPtr: Ptr;
		thisPtr: Ptr;
		nextPtr: Ptr;
		savePtr: Ptr;
		buffer1: Handle;
		buffer2: Handle;
		buffer3: Handle;
		buffer4: Handle;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		FreeLargeHandle (buffer1);
		FreeLargeHandle (buffer2);
		FreeLargeHandle (buffer3);
		FreeLargeHandle (buffer4);

		srcArray.Flush;
		dstArray.Flush

		END;

	PROCEDURE LoadRow (dstPtr: Ptr; row: INTEGER);

		VAR
			srcPtr: Ptr;

		BEGIN

		MoveHands (TRUE);

		row := Max (r.top, Min (row, r.bottom - 1));

		srcPtr := Ptr (ORD4 (srcArray.NeedPtr (row, row, FALSE)) + r.left);

		IF connect8 THEN
			MinOrMaxRow (srcPtr, dstPtr, r.right - r.left, maxFlag)
		ELSE
			BlockMove (srcPtr, dstPtr, r.right - r.left);

		srcArray.DoneWithPtr

		END;

	BEGIN

	buffer1 := NIL;
	buffer2 := NIL;
	buffer3 := NIL;
	buffer4 := NIL;

	CatchFailures (fi, CleanUp);

	r.top	 := Max (0					  , r1.top	  - 1);
	r.left	 := Max (0					  , r1.left   - 1);
	r.bottom := Min (srcArray.fBlockCount , r1.bottom + 1);
	r.right  := Min (srcArray.fLogicalSize, r1.right  + 1);

	buffer1 := NewLargeHandle (r.right - r.left);
	buffer2 := NewLargeHandle (r.right - r.left);
	buffer3 := NewLargeHandle (r.right - r.left);
	buffer4 := NewLargeHandle (r.right - r.left);

	HLock (buffer1);
	HLock (buffer2);
	HLock (buffer3);
	HLock (buffer4);

	prevPtr := buffer1^;
	thisPtr := buffer2^;
	nextPtr := buffer3^;

	LoadRow (thisPtr, r1.top - 1);
	LoadRow (nextPtr, r1.top);

	FOR row := r2.top TO r2.bottom - 1 DO
		BEGIN

		UpdateProgress (row, r2.bottom - r2.top);

		savePtr := prevPtr;
		prevPtr := thisPtr;
		thisPtr := nextPtr;
		nextPtr := savePtr;

		LoadRow (nextPtr, row - r2.top + r1.top + 1);

		IF connect8 THEN
			savePtr := thisPtr
		ELSE
			BEGIN
			savePtr := buffer4^;
			MinOrMaxRow (thisPtr, savePtr, r.right - r.left, maxFlag)
			END;

		MinOrMaxRows (Ptr (ORD4 (prevPtr) + r1.left - r.left),
					  Ptr (ORD4 (savePtr) + r1.left - r.left),
					  Ptr (ORD4 (nextPtr) + r1.left - r.left),
					  Ptr (ORD4 (dstArray.NeedPtr (row, row, TRUE)) + r2.left),
					  r2.right - r2.left,
					  maxFlag);

		dstArray.DoneWithPtr

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE MinOrMaxFilter (srcArray: TVMArray;
						  dstArray: TVMArray;
						  r: Rect;
						  radius: INTEGER;
						  maxFlag: BOOLEAN;
						  alternate: BOOLEAN);

	VAR
		rr: Rect;
		pass: INTEGER;

	BEGIN

	SetRect (rr, 0, 0, r.right - r.left, r.bottom - r.top);

	IF radius = 0 THEN
		srcArray.MoveRect (dstArray, r, rr)

	ELSE
		BEGIN

		StartTask (1/radius);
		MinOrMaxOnce (srcArray, dstArray, r, rr, maxFlag, TRUE);
		FinishTask;

		FOR pass := 2 TO radius DO
			BEGIN
			StartTask (1/(radius - pass + 1));
			MinOrMaxOnce (dstArray, dstArray, rr, rr, maxFlag,
						  ODD (pass) OR NOT alternate);
			FinishTask
			END

		END

	END;

{*****************************************************************************}

{$S ADoFilter}

PROCEDURE Do3by3Filter (srcArray: TVMArray;
						dstArray: TVMArray;
						r: Rect;
						which: INTEGER);

	VAR
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		prevPtr: Ptr;
		thisPtr: Ptr;
		nextPtr: Ptr;
		savePtr: Ptr;
		width: INTEGER;
		buffer1: Handle;
		buffer2: Handle;
		buffer3: Handle;
		map: TLookUpTable;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		FreeLargeHandle (buffer1);
		FreeLargeHandle (buffer2);
		FreeLargeHandle (buffer3);

		srcArray.Flush;
		dstArray.Flush

		END;

	PROCEDURE CopyRow (dstPtr: Ptr; row: INTEGER);

		VAR
			srcPtr: Ptr;

		BEGIN

		row := Max (0, Min (row, srcArray.fBlockCount - 1));

		srcPtr := srcArray.NeedPtr (row, row, FALSE);

		dstPtr := Ptr (ORD4 (dstPtr) - 1);

		BlockMove (Ptr (ORD4 (srcPtr) + r.left - 1), dstPtr, width + 2);

		IF r.left = 0 THEN
			dstPtr^ := srcPtr^;

		IF r.right = srcArray.fLogicalSize THEN
			BEGIN
			dstPtr	:= Ptr (ORD4 (dstPtr) + width + 1);
			dstPtr^ := Ptr (ORD4 (srcPtr) + r.right - 1)^
			END;

		srcArray.DoneWithPtr

		END;

	BEGIN

	buffer1 := NIL;
	buffer2 := NIL;
	buffer3 := NIL;

	CatchFailures (fi, CleanUp);

	width := r.right - r.left;

	buffer1 := NewLargeHandle (width + 2);
	buffer2 := NewLargeHandle (width + 2);
	buffer3 := NewLargeHandle (width + 2);

	HLock (buffer1);
	HLock (buffer2);
	HLock (buffer3);

	prevPtr := Ptr (ORD4 (buffer1^) + 1);
	thisPtr := Ptr (ORD4 (buffer2^) + 1);
	nextPtr := Ptr (ORD4 (buffer3^) + 1);

	CopyRow (thisPtr, r.top - 1);
	CopyRow (nextPtr, r.top);

	IF (which = cDespeckle) OR (which = cSharpenEdges) THEN
		FOR row := 0 TO 255 DO
			IF row <= 64 THEN
				map [row] := CHR (0)
			ELSE
				map [row] := CHR (ORD4 (row - 64) * 255 DIV 191);

	IF which = cSharpenEdges THEN
		DoMapBytes (@map, 256, gInvertLUT);

	FOR row := r.top TO r.bottom - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row - r.top, r.bottom - r.top);

		savePtr := prevPtr;
		prevPtr := thisPtr;
		thisPtr := nextPtr;
		nextPtr := savePtr;

		CopyRow (nextPtr, row + 1);

		dstPtr := dstArray.NeedPtr (row - r.top, row - r.top, TRUE);

			CASE which OF

			cBlur:
				BlurLine (prevPtr, thisPtr, nextPtr, dstPtr, width);

			cBlurMore:
				BlurMoreLine (prevPtr, thisPtr, nextPtr, dstPtr, width);

			cSharpen:
				SharpenLine (prevPtr, thisPtr, nextPtr, dstPtr, width);

			cSharpenMore:
				SharpenMoreLine (prevPtr, thisPtr, nextPtr, dstPtr, width);

			cFacetPass1:
				DoFacet1 (prevPtr, thisPtr, nextPtr, dstPtr, width);

			cFacetPass2:
				DoFacet2 (prevPtr, thisPtr, nextPtr, dstPtr, width);

			cFacetPass3:
				DoFacet3 (prevPtr, thisPtr, nextPtr, dstPtr, width);

			cFacetPass4:
				DoFacet4 (prevPtr, thisPtr, nextPtr, dstPtr, width);

			cDiffuseDarken:
				DoDiffuseDarken (prevPtr, thisPtr, nextPtr, dstPtr, width);

			cDiffuseLighten:
				DoDiffuseLighten (prevPtr, thisPtr, nextPtr, dstPtr, width);

			cTraceContour:
				DoTraceContour (prevPtr, thisPtr, nextPtr, dstPtr, width,
								gFilterParameter [1],
								gFilterParameter [2] <> 0);

			cSobel:
				SobelLine (prevPtr, thisPtr, nextPtr,
						   dstPtr, width, FALSE, FALSE);

			cDespeckle:
				BEGIN
				SobelLine (prevPtr, thisPtr, nextPtr,
						   gBuffer, width, FALSE, FALSE);
				DoMapBytes (gBuffer, width, map);
				BlurMoreLine (prevPtr, thisPtr, nextPtr, dstPtr, width);
				DoBlendBelow (gBuffer, thisPtr, dstPtr, width, 0, -1)
				END;

			cSharpenEdges:
				BEGIN
				SobelLine (prevPtr, thisPtr, nextPtr,
						   gBuffer, width, FALSE, FALSE);
				DoMapBytes (gBuffer, width, map);
				SharpenLine (prevPtr, thisPtr, nextPtr, dstPtr, width);
				DoBlendBelow (gBuffer, thisPtr, dstPtr, width, 0, -1)
				END;

			cSelectFringeNarrow:
				BEGIN
				DoSetBytes (dstPtr, width, 0);
				SetJustInside (prevPtr, thisPtr, nextPtr, dstPtr, width)
				END;

			cSelectFringeWide:
				BEGIN
				DoSetBytes (dstPtr, width, 0);
				SetJustInside (prevPtr, thisPtr, nextPtr, dstPtr, width);
				SetJustOutside (prevPtr, thisPtr, nextPtr, dstPtr, width)
				END

			END;

		dstArray.DoneWithPtr

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

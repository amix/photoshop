{Photoshop version 1.0.1, file: UAdjust.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}
{$I UAdjust.a.inc}
{$I UConvert.a.inc}
{$I UHistogram.p.inc}
{$I UPick.p.inc}

CONST
	kMapFileType = '8BLT';

VAR
	gOffMap: BitMap;
	gOffPort: GrafPort;

	gLastPosterize: INTEGER;
	gLastThreshold: INTEGER;

	gLevelsLocation: Point;
	gBalanceLocation: Point;
	gThresholdLocation: Point;
	gPosterizeLocation: Point;
	gArbitraryLocation: Point;
	gSaturationLocation: Point;
	gBrightnessLocation: Point;

	gEqualizeWholeImage: BOOLEAN;

	gBPointerData: PACKED ARRAY [0..11] OF CHAR;
	gGPointerData: PACKED ARRAY [0..11] OF CHAR;
	gWPointerData: PACKED ARRAY [0..11] OF CHAR;

	gOffMapData: PACKED ARRAY [0..95] OF CHAR;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitAdjustments;

	VAR
		savePort: GrafPtr;

	BEGIN

	gAdjustCommand := NIL;

	gPtrWidth := 5;

	SetRect (gBPointer.bounds, 0, 0, 11, 6);

	gBPointer.rowBytes := 2;
	gBPointer.baseAddr := @gBPointerData;

	StuffHex (@gBPointerData, '04000E001F003F807FC0FFE0');

	gGPointer := gBPointer;
	gGPointer.baseAddr := @gGPointerData;

	StuffHex (@gGPointerData, '04000A0015002A805540FFE0');

	gWPointer := gBPointer;
	gWPointer.baseAddr := @gWPointerData;

	StuffHex (@gWPointerData, '04000A00110020804040FFE0');

	gOffMap.rowBytes := 6;
	gOffMap.baseAddr := @gOffMapData;
	SetRect (gOffMap.bounds, 0, 0, 48, 16);

	GetPort (savePort);

	OpenPort (@gOffPort);

	SetPortBits (gOffMap);
	ClipRect (gOffMap.bounds);

	SetPort (savePort);

	gEqualizeWholeImage := TRUE;

	gLastPosterize := 4;
	gLastThreshold := 128;

	gLevelsLocation.h := 0;
	gLevelsLocation.v := 0;

	gBalanceLocation.h := 0;
	gBalanceLocation.v := 0;

	gThresholdLocation.h := 0;
	gThresholdLocation.v := 0;

	gPosterizeLocation.h := 0;
	gPosterizeLocation.v := 0;

	gArbitraryLocation.h := 0;
	gArbitraryLocation.v := 0;

	gSaturationLocation.h := 0;
	gSaturationLocation.v := 0;

	gBrightnessLocation.h := 0;
	gBrightnessLocation.v := 0

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE DrawNoFlicker (s: Str255; r: Rect);

	VAR
		rr: Rect;
		savePort: GrafPtr;

	BEGIN

	rr.top	  := 0;
	rr.left   := 0;
	rr.bottom := r.bottom - r.top;
	rr.right  := r.right - r.left;

	GetPort (savePort);

	SetPort (@gOffPort);

	TextBox (@s[1], LENGTH (s), rr, teJustRight);

	SetPort (savePort);

	CopyBits (gOffMap, thePort^.portBits, rr, r, srcCopy, NIL)

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE DrawNumber (n: LONGINT; r: Rect);

	VAR
		s: Str255;

	BEGIN

	NumToString (n, s);

	DrawNoFlicker (s, r)

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE SetLUTConst (VAR LUT: TLookUpTable; x1, x2, y: INTEGER);

	VAR
		gray: INTEGER;

	BEGIN

	FOR gray := x1 TO x2 DO
		LUT [gray] := CHR (y)

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE SetLUTLine (VAR LUT: TLookUpTable; x1, x2, y1, y2: INTEGER);

	VAR
		x: INTEGER;
		dx: INTEGER;
		dy: LONGINT;
		half: INTEGER;

	BEGIN

	dx := x2 - x1;
	dy := y2 - y1;

	half := BSR (dx, 1);

	FOR x := x1 TO x2 DO
		LUT [x] := CHR (y1 + (dy * (x - x1) + half) DIV dx)

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE SetGammaTable (VAR LUT: TLookUpTable; g: INTEGER);

	VAR
		B: Fixed;
		C: Fixed;
		D: Fixed;
		s0: Fixed;
		s1: Fixed;
		x: INTEGER;
		x1: INTEGER;
		y1: INTEGER;
		gamma: EXTENDED;

	BEGIN

	IF g = 100 THEN
		LUT := gNullLUT

	ELSE
		BEGIN

		FOR x := 0 TO 255 DO
			LUT [x] := CHR (FindGamma (x, g));

		IF g > 100 THEN
			BEGIN

			gamma := 100 / g;

			x1 := ROUND (255 * EXP (LN (2) * (1 + 1/gamma/(gamma-1))));
			y1 := ORD (LUT [x1]);

			IF x1 >= 2 THEN
				BEGIN

				s0 := ROUND ($10000 * EXP (LN (2) * (1/gamma)));
				s1 := ROUND ($10000 * gamma * y1 / x1);

				FOR x := 1 TO x1 - 1 DO
					BEGIN

					B := FixRatio (x	 , x1);
					C := FixRatio (x1 - x, x1);

					D := FixMul (FixMul (s0 * x1, B), FixMul (C, C)) +
						 FixMul (y1 * ($20000 - B + C) -
								 FixMul (s1 * x1, C), FixMul (B, B));

					LUT [x] := CHR (FixRound (D))

					END

				END

			END

		END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE SetLUTGamma (VAR LUT: TLookUpTable;
					   x1, x2, y1, y2: INTEGER; gamma: EXTENDED);

	VAR
		j: INTEGER;
		x: INTEGER;
		g: INTEGER;
		dx: INTEGER;
		dy: INTEGER;
		half: INTEGER;
		tempLUT: TLookUpTable;

	BEGIN

	dx := x2 - x1;
	dy := y2 - y1;

	g := ROUND (gamma * 100);

	IF (g = 100) OR (dx <= 1) OR (dy = 0) THEN
		SetLUTLine (LUT, x1, x2, y1, y2)

	ELSE IF (dx = 255) AND (dy = 255) THEN
		SetGammaTable (LUT, g)

	ELSE
		BEGIN

		SetGammaTable (tempLUT, g);

		half := dx DIV 2;

		FOR j := x1 TO x2 DO
			BEGIN

			x := (ORD4 (j - x1) * 255 + half) DIV dx;

			LUT [j] := CHR (y1 + (ORD4 (tempLUT [x]) * dy + 127) DIV 255)

			END

		END

	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE SmoothLUT (VAR LUT: TLookUpTable;
					 radius, passes: INTEGER;
					 wrap: BOOLEAN);

	VAR
		j: INTEGER;
		k: INTEGER;
		pass: INTEGER;
		width: INTEGER;
		total: INTEGER;
		newLUT: TLookUpTable;

	BEGIN

	width := 2 * radius + 1;

	FOR pass := 1 TO passes DO
		BEGIN

		IF wrap THEN
			BEGIN

			total := 0;

			FOR k := -radius TO radius DO
				total := total + ORD (LUT [BAND ($FF, k)])

			END

		ELSE
			total := ORD (LUT [0]) * (2 * radius + 1) + radius;

		FOR j := 0 TO 255 DO
			BEGIN

			newLUT [j] := CHR (total DIV width);

			k := j - radius;

			IF (k < 0) AND NOT wrap THEN
				total := total - 2 * ORD (LUT [0]) + ORD (LUT [-k])
			ELSE
				total := total - ORD (LUT [BAND ($FF, k)]);

			k := j + radius + 1;

			IF (k > 255) AND NOT wrap THEN
				total := total + 2 * ORD (LUT [255]) - ORD (LUT [510 - k])
			ELSE
				total := total + ORD (LUT [BAND ($FF, k)])

			END;

		LUT := newLUT

		END

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE AdjustForFeedback (VAR LUT: TLookUpTable);

	CONST
		kMinGap  = 64;
		kHalfGap = kMinGap DIV 2;

	VAR
		mean: INTEGER;
		black: INTEGER;
		white: INTEGER;

	BEGIN

	black := ORD (LUT [  0]);
	white := ORD (LUT [255]);

	IF ABS (white - black) < kMinGap THEN
		BEGIN

		mean := Max (Min (BSR (white + black, 1),
						  255 - kHalfGap),
						  kHalfGap);

		IF white >= black THEN
			BEGIN
			LUT [  0] := CHR (mean - kHalfGap);
			LUT [255] := CHR (mean + kHalfGap)
			END
		ELSE
			BEGIN
			LUT [  0] := CHR (mean + kHalfGap);
			LUT [255] := CHR (mean - kHalfGap)
			END

		END

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TAdjustmentCommand.IAdjustmentCommand (itsCommand: INTEGER;
												 view: TImageView);

	VAR
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Free
		END;

	BEGIN

	fAllocated := FALSE;
	fPreviewed := FALSE;

	fUsingBuffers := FALSE;

	IFloatCommand (itsCommand, view);

	fChannel := view.fChannel;

	fWholeImage := EmptyRect (fDoc.fSelectionRect) OR
				   (fDoc.fSelectionMask 	   = NIL	   ) AND
				   (fDoc.fSelectionRect.top    = 0		   ) AND
				   (fDoc.fSelectionRect.left   = 0		   ) AND
				   (fDoc.fSelectionRect.bottom = fDoc.fRows) AND
				   (fDoc.fSelectionRect.right  = fDoc.fCols);

	IF fWasFloating THEN fWholeImage := FALSE;

	CatchFailures (fi, CleanUp);

	GetParameters;

	Success (fi)

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TAdjustmentCommand.GetParameters;

	BEGIN
	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TAdjustmentCommand.MapMonochrome (dataPtr: Ptr; count: INTEGER);

	BEGIN

	DoMapBytes (dataPtr, count, fMonochromeLUT)

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TAdjustmentCommand.MapRGB (rPtr, gPtr, bPtr: Ptr; count: INTEGER);

	BEGIN

	MapMonochrome (rPtr, count);
	MapMonochrome (gPtr, count);
	MapMonochrome (bPtr, count)

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TAdjustmentCommand.MakeMonochromeLUT;

	VAR
		index: INTEGER;
		LUT: TRGBLookUpTable;

	BEGIN

	LUT.R := gNullLUT;
	LUT.G := gNullLUT;
	LUT.B := gNullLUT;

	MapRGB (@LUT.R, @LUT.G, @LUT.B, 256);

	FOR index := 0 TO 255 DO
		fMonochromeLUT [index] := ConvertToGray (ORD (LUT.R [index]),
												 ORD (LUT.G [index]),
												 ORD (LUT.B [index]))

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TAdjustmentCommand.AllocateBuffers;

	VAR
		width: INTEGER;
		height: INTEGER;
		channel: INTEGER;
		channels: INTEGER;
		aVMArray: TVMArray;

	BEGIN

	gApplication.CommitLastCommand;

	IF fDoc.fMode = IndexedColorMode THEN
		channels := 0
	ELSE IF fChannel = kRGBChannels THEN
		channels := 3
	ELSE
		channels := 1;

	IF fWholeImage THEN
		BEGIN

		fDoc.KillEffect (TRUE);
		fDoc.FreeFloat;

		width  := fDoc.fData [0] . fLogicalSize;
		height := fDoc.fData [0] . fBlockCount;

		FOR channel := 0 TO channels - 1 DO
			BEGIN
			aVMArray := NewVMArray (height, width, channels - channel);
			fBuffer [channel] := aVMArray
			END

		END

	ELSE IF fWasFloating THEN
		BEGIN

		FloatSelection (TRUE);

		fExactFloat := FALSE;

		fFloatRect := fDoc.fFloatRect;

		width  := fFloatRect.right - fFloatRect.left;
		height := fFloatRect.bottom - fFloatRect.top;

		FOR channel := 0 TO channels - 1 DO
			BEGIN
			aVMArray := NewVMArray (height, width, channels - channel);
			fFloatData [channel] := aVMArray
			END

		END

	ELSE
		BEGIN

		FloatSelection (TRUE);

		fDoc.fSelectionFloating := FALSE;

		fDoc.fExactFloat := FALSE;

		fFloatRect := fDoc.fFloatRect

		END

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TAdjustmentCommand.MapBuffers;

	VAR
		rPtr: Ptr;
		gPtr: Ptr;
		bPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		fi0: FailInfo;
		width: INTEGER;
		height: INTEGER;
		LUT: TRGBLookUpTable;

	PROCEDURE CleanUp0 (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress
		END;

	PROCEDURE CleanUp1 (error: INTEGER; message: LONGINT);
		BEGIN

		IF rPtr <> NIL THEN fBuffer [0] . DoneWithPtr;
		IF gPtr <> NIL THEN fBuffer [1] . DoneWithPtr;
		IF bPtr <> NIL THEN fBuffer [2] . DoneWithPtr;

		fBuffer [0] . Flush;
		fBuffer [1] . Flush;
		fBuffer [2] . Flush;

		fDoc.fData [0] . Flush;
		fDoc.fData [1] . Flush;
		fDoc.fData [2] . Flush

		END;

	PROCEDURE CleanUp2 (error: INTEGER; message: LONGINT);
		BEGIN

		IF rPtr <> NIL THEN fBuffer [0] . DoneWithPtr;

		fBuffer [0] . Flush;

		fDoc.fData [fChannel] . Flush

		END;

	PROCEDURE CleanUp3 (error: INTEGER; message: LONGINT);
		BEGIN

		IF rPtr <> NIL THEN fFloatData [0] . DoneWithPtr;
		IF gPtr <> NIL THEN fFloatData [1] . DoneWithPtr;
		IF bPtr <> NIL THEN fFloatData [2] . DoneWithPtr;

		fFloatData [0] . Flush;
		fFloatData [1] . Flush;
		fFloatData [2] . Flush;

		fDoc.fFloatData [0] . Flush;
		fDoc.fFloatData [1] . Flush;
		fDoc.fFloatData [2] . Flush

		END;

	PROCEDURE CleanUp4 (error: INTEGER; message: LONGINT);
		BEGIN

		IF rPtr <> NIL THEN fFloatData [0] . DoneWithPtr;

		fFloatData [0] . Flush;

		fDoc.fFloatData [0] . Flush

		END;

	PROCEDURE CleanUp5 (error: INTEGER; message: LONGINT);
		BEGIN

		IF rPtr <> NIL THEN fDoc.fFloatData [0] . DoneWithPtr;
		IF gPtr <> NIL THEN fDoc.fFloatData [1] . DoneWithPtr;
		IF bPtr <> NIL THEN fDoc.fFloatData [2] . DoneWithPtr;

		fDoc.fFloatData [0] . Flush;
		fDoc.fFloatData [1] . Flush;
		fDoc.fFloatData [2] . Flush

		END;

	PROCEDURE CleanUp6 (error: INTEGER; message: LONGINT);
		BEGIN
		fDoc.fFloatData [0] . Flush
		END;

	BEGIN

	CommandProgress (fCmdNumber);

	CatchFailures (fi0, CleanUp0);

	IF fDoc.fMode = IndexedColorMode THEN
		BEGIN

		LUT := fDoc.fIndexedColorTable;

		MapRGB (@LUT.R, @LUT.G, @LUT.B, 256);

		fIndexedColorTable := LUT

		END

	ELSE IF fWholeImage THEN
		BEGIN

		width  := fDoc.fData [0] . fLogicalSize;
		height := fDoc.fData [0] . fBlockCount;

		IF fChannel = kRGBChannels THEN
			BEGIN

			rPtr := NIL;
			gPtr := NIL;
			bPtr := NIL;

			CatchFailures (fi, CleanUp1);

			FOR row := 0 TO height - 1 DO
				BEGIN

				MoveHands (TRUE);

				UpdateProgress (row, height);

				rPtr := fBuffer [0] . NeedPtr (row, row, TRUE);
				gPtr := fBuffer [1] . NeedPtr (row, row, TRUE);
				bPtr := fBuffer [2] . NeedPtr (row, row, TRUE);

				BlockMove (fDoc.fData [0] . NeedPtr (row, row, FALSE),
						   rPtr, width);

				fDoc.fData [0] . DoneWithPtr;

				BlockMove (fDoc.fData [1] . NeedPtr (row, row, FALSE),
						   gPtr, width);

				fDoc.fData [1] . DoneWithPtr;

				BlockMove (fDoc.fData [2] . NeedPtr (row, row, FALSE),
						   bPtr, width);

				fDoc.fData [2] . DoneWithPtr;

				MapRGB (rPtr, gPtr, bPtr, width);

				fBuffer [0] . DoneWithPtr;
				fBuffer [1] . DoneWithPtr;
				fBuffer [2] . DoneWithPtr;

				rPtr := NIL;
				gPtr := NIL;
				bPtr := NIL

				END;

			Success (fi);

			CleanUp1 (0, 0)

			END

		ELSE
			BEGIN

			MakeMonochromeLUT;

			rPtr := NIL;

			CatchFailures (fi, CleanUp2);

			FOR row := 0 TO height - 1 DO
				BEGIN

				MoveHands (TRUE);

				UpdateProgress (row, height);

				rPtr := fBuffer [0] . NeedPtr (row, row, TRUE);

				BlockMove (fDoc.fData [fChannel] . NeedPtr (row, row, FALSE),
						   rPtr, width);

				fDoc.fData [fChannel] . DoneWithPtr;

				MapMonochrome (rPtr, width);

				fBuffer [0] . DoneWithPtr;

				rPtr := NIL

				END;

			Success (fi);

			CleanUp2 (0, 0)

			END

		END

	ELSE IF fWasFloating THEN
		BEGIN

		width  := fFloatRect.right - fFloatRect.left;
		height := fFloatRect.bottom - fFloatRect.top;

		IF fChannel = kRGBChannels THEN
			BEGIN

			rPtr := NIL;
			gPtr := NIL;
			bPtr := NIL;

			CatchFailures (fi, CleanUp3);

			FOR row := 0 TO height - 1 DO
				BEGIN

				MoveHands (TRUE);

				UpdateProgress (row, height);

				rPtr := fFloatData [0] . NeedPtr (row, row, TRUE);
				gPtr := fFloatData [1] . NeedPtr (row, row, TRUE);
				bPtr := fFloatData [2] . NeedPtr (row, row, TRUE);

				BlockMove (fDoc.fFloatData [0] . NeedPtr (row, row, FALSE),
						   rPtr, width);

				fDoc.fFloatData [0] . DoneWithPtr;

				BlockMove (fDoc.fFloatData [1] . NeedPtr (row, row, FALSE),
						   gPtr, width);

				fDoc.fFloatData [1] . DoneWithPtr;

				BlockMove (fDoc.fFloatData [2] . NeedPtr (row, row, FALSE),
						   bPtr, width);

				fDoc.fFloatData [2] . DoneWithPtr;

				MapRGB (rPtr, gPtr, bPtr, width);

				fFloatData [0] . DoneWithPtr;
				fFloatData [1] . DoneWithPtr;
				fFloatData [2] . DoneWithPtr;

				rPtr := NIL;
				gPtr := NIL;
				bPtr := NIL

				END;

			Success (fi);

			CleanUp3 (0, 0)

			END

		ELSE
			BEGIN

			MakeMonochromeLUT;

			rPtr := NIL;

			CatchFailures (fi, CleanUp4);

			FOR row := 0 TO height - 1 DO
				BEGIN

				MoveHands (TRUE);

				UpdateProgress (row, height);

				rPtr := fFloatData [0] . NeedPtr (row, row, TRUE);

				BlockMove (fDoc.fFloatData [0] . NeedPtr (row, row, FALSE),
						   rPtr, width);

				fDoc.fFloatData [0] . DoneWithPtr;

				MapMonochrome (rPtr, width);

				fFloatData [0] . DoneWithPtr;

				rPtr := NIL

				END;

			Success (fi);

			CleanUp4 (0, 0)

			END

		END

	ELSE
		BEGIN

		width  := fFloatRect.right - fFloatRect.left;
		height := fFloatRect.bottom - fFloatRect.top;

		IF fChannel = kRGBChannels THEN
			BEGIN

			rPtr := NIL;
			gPtr := NIL;
			bPtr := NIL;

			CatchFailures (fi, CleanUp5);

			FOR row := 0 TO height - 1 DO
				BEGIN

				MoveHands (TRUE);

				UpdateProgress (row, height);

				rPtr := fDoc.fFloatData [0] . NeedPtr (row, row, TRUE);
				gPtr := fDoc.fFloatData [1] . NeedPtr (row, row, TRUE);
				bPtr := fDoc.fFloatData [2] . NeedPtr (row, row, TRUE);

				MapRGB (rPtr, gPtr, bPtr, width);

				fDoc.fFloatData [0] . DoneWithPtr;
				fDoc.fFloatData [1] . DoneWithPtr;
				fDoc.fFloatData [2] . DoneWithPtr;

				rPtr := NIL;
				gPtr := NIL;
				bPtr := NIL

				END;

			Success (fi);

			CleanUp5 (0, 0)

			END

		ELSE
			BEGIN

			MakeMonochromeLUT;

			CatchFailures (fi, CleanUp6);

			FOR row := 0 TO height - 1 DO
				BEGIN

				MoveHands (TRUE);

				UpdateProgress (row, height);

				MapMonochrome (fDoc.fFloatData [0] . NeedPtr (row, row, TRUE),
							   width);

				fDoc.fFloatData [0] . DoneWithPtr

				END;

			Success (fi);

			CleanUp6 (0, 0)

			END

		END;

	UpdateProgress (1, 1);

	Success (fi0);

	CleanUp0 (0, 0)

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TAdjustmentCommand.ExchangeBuffers;

	VAR
		channel: INTEGER;
		saveArray: TVMArray;

	BEGIN

	fUsingBuffers := NOT fUsingBuffers;

	IF fDoc.fMode = IndexedColorMode THEN
		BEGIN

		DoSwapBytes (@fIndexedColorTable,
					 @fDoc.fIndexedColorTable,
					 SIZEOF (TRGBLookUpTable));

		fDoc.TestColorTable

		END

	ELSE IF fWholeImage THEN

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
			END

	ELSE IF fWasFloating THEN
		SwapFloat

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TAdjustmentCommand.ShowBuffers (checkSelection: BOOLEAN);

	VAR
		r: Rect;
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		EXIT (ShowBuffers)		{ This command cannot fail }
		END;

	PROCEDURE ReDitherView (view: TImageView);
		BEGIN
		view.ReDither (TRUE)
		END;

	BEGIN

	MoveHands (FALSE);

	CatchFailures (fi, CleanUp);

	ExchangeBuffers;

	IF fDoc.fMode = IndexedColorMode THEN

		fDoc.fViewList.Each (ReDitherView)

	ELSE IF fWholeImage THEN
		BEGIN

		fDoc.GetBoundsRect (r);
		fDoc.UpdateImageArea (r, TRUE, TRUE, fChannel)

		END

	ELSE IF fWasFloating THEN
		BEGIN

		IF NOT fDoc.fSelectionFloating THEN
			fDoc.DeSelect (TRUE);

		CopyBelow (FALSE);

		BlendFloat (FALSE);

		ComputeOverlap (r);

		fDoc.UpdateImageArea (r, TRUE, TRUE, fDoc.fFloatChannel);

		IF NOT fDoc.fSelectionFloating THEN
			SelectFloat

		END

	ELSE
		BEGIN

		IF checkSelection THEN
			fDoc.DeSelect (NOT EqualRect (fFloatRect, fDoc.fSelectionRect));

		IF fUsingBuffers THEN
			BEGIN
			IF fPreviewed THEN
				CopyBelow (FALSE);
			BlendFloat (FALSE)
			END
		ELSE
			CopyBelow (FALSE);

		ComputeOverlap (r);
		fDoc.UpdateImageArea (r, TRUE, TRUE, fDoc.fFloatChannel);

		IF checkSelection THEN
			BEGIN
			SelectFloat;
			fDoc.fSelectionFloating := FALSE
			END

		END;

	Success (fi)

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TAdjustmentCommand.SaveState;

	BEGIN
	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION TAdjustmentCommand.SameState: BOOLEAN;

	BEGIN
	SameState := FALSE
	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TAdjustmentCommand.DoPreview;

	VAR
		fi: FailInfo;
		channel: INTEGER;
		wasAllocated: BOOLEAN;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		ExchangeBuffers
		END;

	BEGIN

	IF fPreviewed THEN
		IF SameState THEN
			EXIT (DoPreview);

	MoveHands (TRUE);

	wasAllocated := fAllocated;

	IF NOT fAllocated THEN
		BEGIN
		AllocateBuffers;
		fAllocated := TRUE
		END;

	IF fPreviewed THEN
		BEGIN
		ExchangeBuffers;
		CatchFailures (fi, CleanUp)
		END;

	IF wasAllocated THEN
		BEGIN

		IF fWholeImage THEN
			BEGIN

			FOR channel := 0 TO 2 DO
				IF fBuffer [channel] <> NIL THEN
					fBuffer [channel] . Undefine

			END

		ELSE IF fWasFloating THEN
			BEGIN

			FOR channel := 0 TO 2 DO
				IF fFloatData [channel] <> NIL THEN
					fFloatData [channel] . Undefine

			END

		ELSE
			BEGIN

			FOR channel := 0 TO 2 DO
				IF fDoc.fFloatBelow [channel] <> NIL THEN
					fDoc.fFloatBelow [channel] . MoveArray
												 (fDoc.fFloatData [channel])

			END

		END;

	MapBuffers;

	IF fPreviewed THEN
		Success (fi);

	ShowBuffers (FALSE);

	fPreviewed := TRUE;

	SaveState

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TAdjustmentCommand.Free; OVERRIDE;

	BEGIN

	IF fPreviewed THEN ShowBuffers (FALSE);

	INHERITED Free

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TAdjustmentCommand.DoIt; OVERRIDE;

	BEGIN

	DoPreview;

	fPreviewed := FALSE

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TAdjustmentCommand.UndoIt; OVERRIDE;

	BEGIN
	ShowBuffers (TRUE)
	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TAdjustmentCommand.RedoIt; OVERRIDE;

	BEGIN
	UndoIt
	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TInvertCommand.MapMonochrome (dataPtr: Ptr;
										count: INTEGER); OVERRIDE;

	BEGIN
	DoMapBytes (dataPtr, count, gInvertLUT)
	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION DoInvertCommand (view: TImageView): TCommand;

	VAR
		anInvertCommand: TInvertCommand;

	BEGIN

	NEW (anInvertCommand);
	FailNil (anInvertCommand);

	anInvertCommand.IAdjustmentCommand (cInversion, view);

	DoInvertCommand := anInvertCommand

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TEqualizeCommand.GetParameters; OVERRIDE;

	CONST
		kDialogID  = 1030;
		kHookItem  = 3;
		kRadioItem = 4;

	VAR
		j: INTEGER;
		fi: FailInfo;
		left: LONGINT;
		last: INTEGER;
		first: INTEGER;
		count: LONGINT;
		hist: THistogram;
		hitItem: INTEGER;
		hist1: THistogram;
		hist2: THistogram;
		hist3: THistogram;
		aBWDialog: TBWDialog;
		radioCluster: TRadioCluster;

	PROCEDURE CleanUp1 (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress
		END;

	PROCEDURE CleanUp2 (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	GetHistogram (fView, FALSE, hist, hist1, hist2, hist3);

	FOR first := 0 TO 255 DO
		IF hist [first] <> 0 THEN
			LEAVE;

	FOR last := 255 DOWNTO 0 DO
		IF hist [last] <> 0 THEN
			LEAVE;

	IF first = last THEN
		IF fWholeImage THEN
			Failure (errOneValueImage, 0)
		ELSE
			Failure (errOneValueSelect, 0);

	FOR j := 0 TO first - 1 DO
		fLUT [j] := CHR (0);

	FOR j := last + 1 TO 255 DO
		fLUT [j] := CHR (255);

	count := - BSR (hist [first], 1) - BSR (hist [last] + 1, 1);

	FOR j := first TO last DO
		count := count + hist [j];

	FOR j := first TO last DO
		BEGIN

		IF j = first THEN
			left := 0
		ELSE
			left := left + BSR (hist [j], 1);

		fLUT [j] := CHR (ROUND (255.0 * left / count));

		left := left + BSR (hist [j] + 1, 1)

		END;

	IF NOT fWholeImage THEN
		BEGIN

		NEW (aBWDialog);
		FailNil (aBWDialog);

		aBWDialog.IBWDialog (kDialogID, kHookItem, ok);

		CatchFailures (fi, CleanUp2);

		radioCluster := aBWDialog.DefineRadioCluster
						(kRadioItem, kRadioItem + 1,
						 kRadioItem + ORD (gEqualizeWholeImage));

		aBWDialog.TalkToUser (hitItem, StdItemHandling);

		IF hitItem <> ok THEN Failure (0, 0);

		fWholeImage := (radioCluster.fChosenItem <> kRadioItem);

		gEqualizeWholeImage := fWholeImage;

		Success (fi);

		CleanUp2 (0, 0)

		END

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TEqualizeCommand.MapMonochrome (dataPtr: Ptr;
										  count: INTEGER); OVERRIDE;

	BEGIN
	DoMapBytes (dataPtr, count, fLUT)
	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION DoEqualizeCommand (view: TImageView): TCommand;

	VAR
		anEqualizeCommand: TEqualizeCommand;

	BEGIN

	NEW (anEqualizeCommand);
	FailNil (anEqualizeCommand);

	anEqualizeCommand.IAdjustmentCommand (cEqualization, view);

	DoEqualizeCommand := anEqualizeCommand

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TFeedbackDialog.IFeedbackDialog (view: TImageView;
										   command: TAdjustmentCommand;
										   location: PPoint;
										   itsRsrcID: INTEGER;
										   itsHookItem: INTEGER;
										   itsDfltButton: INTEGER;
										   itsPreviewButton: INTEGER);

	BEGIN

	fView	  := view;
	fCommand  := command;
	fLocation := location;

	fPreviewButton := itsPreviewButton;

	IBWDialog (itsRsrcID, itsHookItem, itsDfltButton)

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TFeedbackDialog.NextMousePoint (VAR pt: Point);

	VAR
		peekEvent: EventRecord;

	BEGIN

	GetMouse (pt);

	fLastPoint := NOT StillDown;

	IF fLastPoint THEN
		IF EventAvail (mUpMask, peekEvent) THEN
			BEGIN
			pt := peekEvent.where;
			GlobalToLocal (pt)
			END

	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION TFeedbackDialog.DownInDialog (mousePt: Point): BOOLEAN;

	BEGIN
	DownInDialog := FALSE
	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TFeedbackDialog.PrepareMap (forFeedback: BOOLEAN);

	BEGIN
	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TFeedbackDialog.GetOldColors;

	VAR
		gray: INTEGER;
		index: INTEGER;
		colors: INTEGER;
		sysTable: CTabHandle;

	BEGIN

	IF fFeedbackDepth <= 8 THEN
		BEGIN

		sysTable := fFeedbackDevice^^.gdPMap^^.pmTable;

		IF fFeedbackDepth = 4 THEN
			colors := 16
		ELSE
			colors := 256;

		DoSetBytes (@fOldColors, 256 * SIZEOF (ColorSpec), 0);
		DoSetBytes (@fNewColors, 256 * SIZEOF (ColorSpec), 0);

		BlockMove (@sysTable^^.ctTable,
				   @fOldColors,
				   colors * SIZEOF (ColorSpec));

		BlockMove (@sysTable^^.ctTable,
				   @fNewColors,
				   colors * SIZEOF (ColorSpec))

		END

	ELSE
		FOR index := 0 TO 255 DO
			BEGIN

			{$PUSH}
			{$R-}

			IF fFeedbackDepth = 16 THEN
				IF index <= 31 THEN
					gray := index * $842 + index DIV $10
				ELSE
					gray := 0
			ELSE
				gray := index * $101;

			fOldColors [index] . value := index;

			fOldColors [index] . rgb . red	 := gray;
			fOldColors [index] . rgb . green := gray;
			fOldColors [index] . rgb . blue  := gray;

			fNewColors [index] := fOldColors [index];

			{$POP}

			END

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TFeedbackDialog.GetNewColors;

	VAR
		band: INTEGER;
		index: INTEGER;
		color: RGBColor;
		ignore: BOOLEAN;
		subtractive: BOOLEAN;
		colors: TRGBLookUpTable;
		newLUT: TRGBLookUpTable;

	BEGIN

	FOR index := 0 TO 255 DO
		BEGIN

		{$PUSH}
		{$R-}
		color := fOldColors [index] . rgb;
		{$POP}

		newLUT.R [index] := CHR (BSR (color.red  , 8));
		newLUT.G [index] := CHR (BSR (color.green, 8));
		newLUT.B [index] := CHR (BSR (color.blue , 8))

		END;

	ignore := fCommand.fView.ColorizeBand (band, subtractive);

		CASE band OF

		0:	colors := newLUT;

		1:	BEGIN
			colors.R := newLUT.R;
			colors.G := newLUT.R;
			colors.B := newLUT.R
			END;

		2:	BEGIN
			colors.R := newLUT.G;
			colors.G := newLUT.G;
			colors.B := newLUT.G
			END;

		3:	BEGIN
			colors.R := newLUT.B;
			colors.G := newLUT.B;
			colors.B := newLUT.B
			END

		END;

	PrepareMap (TRUE);

	fCommand.MapRGB (@colors.R, @colors.G, @colors.B, 256);

		CASE band OF
		0:	newLUT	 := colors;
		1:	newLUT.R := colors.R;
		2:	newLUT.G := colors.G;
		3:	newLUT.B := colors.B
		END;

	FOR index := 0 TO 255 DO
		BEGIN

		color.red	:= ORD (newLUT.R [index]);
		color.red	:= color.red   + BSL (color.red  , 8);

		color.green := ORD (newLUT.G [index]);
		color.green := color.green + BSL (color.green, 8);

		color.blue	:= ORD (newLUT.B [index]);
		color.blue	:= color.blue  + BSL (color.blue , 8);

		{$PUSH}
		{$R-}
		fNewColors [index] . rgb := color
		{$POP}

		END

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TFeedbackDialog.SetScreenColors (VAR colors: cSpecArray);

	CONST
		kDirectSetEntries = 8;

	VAR
		err: OSErr;
		code: INTEGER;
		vd: VDSetEntryRecord;
		vdp: ^VDSetEntryRecord;

	BEGIN

	vd.csTable := @colors;
	vd.csStart := 0;

	IF fFeedbackDepth = 4 THEN
		vd.csCount := 15
	ELSE IF fFeedbackDepth = 16 THEN
		vd.csCount := 31
	ELSE
		vd.csCount := 255;

	IF fFeedbackDepth > 8 THEN
		code := kDirectSetEntries
	ELSE
		code := cscSetEntries;

	vdp := @vd;

	err := Control (fFeedbackDevice^^.gdRefNum, code, @vdp)

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TFeedbackDialog.SetNewColors;

	BEGIN

	{$H-}
	SetScreenColors (fNewColors);
	{$H+}

	fUsingNewColors := TRUE

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TFeedbackDialog.SetOldColors;

	BEGIN

	{$H-}
	SetScreenColors (fOldColors);
	{$H+}

	fUsingNewColors := FALSE

	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION TFeedbackDialog.DoSetCursor (localPoint: Point): BOOLEAN; OVERRIDE;

	VAR
		vr: Rect;
		pt: Point;
		theKeys: KeyMap;
		which: WindowPtr;
		spaceDown: BOOLEAN;
		optionDown: BOOLEAN;
		commandDown: BOOLEAN;

	BEGIN

	gUseTool := NullTool;

	IF fView <> NIL THEN
		BEGIN

		fView.TrackRulers;
		SetPort (fDialogPtr);

		pt := localPoint;
		LocalToGlobal (pt);

		IF FindWindow (pt, which) = inContent THEN
			IF which = fView.fWindow.fWmgrWindow THEN
				BEGIN

				fView.fFrame.Focus;
				GlobalToLocal (pt);
				SetPort (fDialogPtr);

				fView.fFrame.GetViewedRect (vr);

				IF PtInRect (pt, vr) THEN
					BEGIN

					GetKeys (theKeys);

					spaceDown	:= theKeys [kSpaceCode];
					optionDown	:= theKeys [kOptionCode];
					commandDown := theKeys [kCommandCode];

					IF spaceDown THEN
						IF optionDown THEN
							IF fView.fMagnification =
							   fView.MinMagnification THEN
								gUseTool := ZoomLimitTool
							ELSE
								gUseTool := ZoomOutTool
						ELSE IF commandDown THEN
							IF fView.fMagnification =
							   fView.MaxMagnification THEN
								gUseTool := ZoomLimitTool
							ELSE
								gUseTool := ZoomTool
						ELSE
							gUseTool := HandTool

					ELSE IF PickerVisible THEN
						IF PickerBackground THEN
							gUseTool := EyedropperBackTool
						ELSE
							gUseTool := EyedropperTool

					END

				END

		END;

	IF gUseTool = NullTool THEN
		DoSetCursor := INHERITED DoSetCursor (localPoint)
	ELSE
		BEGIN
		DoSetCursor := TRUE;
		SetToolCursor (gUseTool, TRUE)
		END

	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION TFeedbackDialog.IsSafeButton (item: INTEGER): BOOLEAN;

	BEGIN
	IsSafeButton := FALSE
	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TFeedbackDialog.DoFilterEvent (VAR anEvent: EventRecord;
										 VAR itemHit: INTEGER;
										 VAR handledIt: BOOLEAN;
										 VAR doReturn: BOOLEAN); OVERRIDE;

	LABEL
		1;

	VAR
		pt: Point;
		fi: FailInfo;
		part: INTEGER;
		item: INTEGER;
		itemBox: Rect;
		count: INTEGER;
		ignore: TCommand;
		itemType: INTEGER;
		itemHandle: Handle;
		whichWindow: WindowPtr;
		theControl: ControlHandle;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		GOTO 1
		END;

	BEGIN

	gMovingHands := FALSE;

	IF anEvent.what = nullEvent THEN
		BEGIN

		IF NOT fUsingNewColors AND (fFeedbackDevice <> NIL) THEN
			SetNewColors;

		IF gApplication.fIdlePriority <> 0 THEN
			gApplication.DoIdle (IdleContinue)

		END;

	IF anEvent.what = updateEvt THEN
		IF WindowPeek (anEvent.message)^.windowKind >= userKind THEN
			BEGIN
			gApplication.ObeyEvent (@anEvent, ignore);
			anEvent.what := nullEvent
			END;

	SetPort (fDialogPtr);

	IF anEvent.what = mouseDown THEN
		BEGIN

		part := FindWindow (anEvent.where, whichWindow);

		IF whichWindow = fDialogPtr THEN
			BEGIN

			IF part = inDrag THEN
				BEGIN

				IF fUsingNewColors THEN SetOldColors;

				DragWindow (whichWindow, anEvent.where, screenBits.bounds);
				anEvent.what := nullEvent

				END

			ELSE IF part = inContent THEN
				BEGIN

				pt := anEvent.where;
				GlobalToLocal (pt);

				fShiftDown	:= BAND (anEvent.modifiers, shiftKey ) <> 0;
				fOptionDown := BAND (anEvent.modifiers, optionKey) <> 0;

				IF DownInDialog (pt) THEN
					anEvent.what := nullEvent

				ELSE
					IF FindControl (pt, whichWindow, theControl) <> 0 THEN
						IF fUsingNewColors THEN
							BEGIN

							count := PInteger
									 (DialogPeek (fDialogPtr)^.items)^;

							FOR item := 1 TO count + 1 DO
								BEGIN
								GetDItem (fDialogPtr, item, itemType,
										  itemHandle, itemBox);
								IF itemHandle = Handle (theControl) THEN
									LEAVE
								END;

							IF itemType = ctrlItem + btnCtrl THEN
								IF NOT IsSafeButton (item) THEN
									SetOldColors

							END

				END

			END

		ELSE IF (fView <> NIL) &
				(whichWindow = fView.fWindow.fWmgrWindow) THEN

			BEGIN

			pt := anEvent.where;
			GlobalToLocal (pt);

			IF DoSetCursor (pt) THEN;

			fView.fWindow.Focus;

			pt := anEvent.where;
			GlobalToLocal (pt);

			part := FindControl (pt, whichWindow, theControl);

			IF (gUseTool <> NullTool) OR (part <> 0) THEN
				BEGIN

				IF NOT fUsingNewColors AND (fFeedbackDevice <> NIL) THEN
					SetNewColors;

				CatchFailures (fi, CleanUp);

				IF (gUseTool IN [EyedropperTool,
								 EyedropperBackTool]) AND
						(fFeedbackDevice <> NIL) THEN
					BEGIN
					PrepareMap (FALSE);
					gAdjustCommand := fCommand
					END;

				WITH anEvent, gEventInfo DO
					BEGIN
					thePEvent	  := @anEvent;
					theBtnState   := BAND(modifiers, btnState)	<> 0;
					theCmdKey	  := BAND(modifiers, cmdKey)	<> 0;
					theShiftKey   := BAND(modifiers, shiftKey)	<> 0;
					theAlphaLock  := BAND(modifiers, alphaLock) <> 0;
					theOptionKey  := BAND(modifiers, optionKey) <> 0;
					theAutoKey	  := (what = autoKey);
					theClickCount := 0
					END;

				ignore := fView.fWindow.DownInContent (anEvent.where,
													   gEventInfo);

				Success (fi);

				1:	{ Ignore errors }

				gAdjustCommand := NIL;

				anEvent.what := NullEvent

				END;

			SetPort (fDialogPtr)

			END

		END;

	INHERITED DoFilterEvent (anEvent, itemHit, handledIt, doReturn)

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TFeedbackDialog.DoFeedback;

	BEGIN

	IF fFeedbackDevice <> NIL THEN
		BEGIN
		GetNewColors;
		SetNewColors
		END

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TFeedbackDialog.DoTalkToUser
		(PROCEDURE HandleSelectedItem (anItem: INTEGER; VAR done: BOOLEAN));

	VAR
		item: INTEGER;
		succeeded: BOOLEAN;

	BEGIN

	IF LONGINT (fLocation^) <> 0 THEN
		MoveWindow (fDialogPtr, fLocation^.h, fLocation^.v, FALSE);

	ShowWindow (fDialogPtr);
	SelectWindow (fDialogPtr);

	IF fCommand = NIL THEN
		fFeedbackDevice := NIL
	ELSE
		fFeedbackDevice := fCommand.fView.GetScreen;

	IF fFeedbackDevice <> NIL THEN
		BEGIN

		fFeedbackDepth := fFeedbackDevice^^.gdPMap^^.pixelSize;

		IF (fFeedbackDepth < 4) OR
		   (fFeedbackDepth > 8) AND NOT gPreferences.fUseDirectLUT THEN
			fFeedbackDevice := NIL;

		IF (fFeedbackDepth = 4) AND
			((fCommand.fView.fChannel = kRGBChannels) OR
			 (fCommand.fDoc.fMode = IndexedColorMode)) THEN
			fFeedbackDevice := NIL

		END;

	fSaveDevice := fFeedbackDevice;

	IF fFeedbackDevice <> NIL THEN
		BEGIN
		GetOldColors;
		GetNewColors
		END;

	fUsingNewColors := FALSE;

		REPEAT

		TalkToUser (item, HandleSelectedItem);

		IF item = fPreviewButton THEN
			BEGIN

			IF fUsingNewColors THEN SetOldColors;

			Validate (succeeded);

			IF succeeded THEN
				BEGIN

				IF fOptionDown THEN
					BEGIN

					IF fCommand.fPreviewed THEN
						BEGIN

						fCommand.fPreviewed := FALSE;

						fCommand.ShowBuffers (FALSE);

						fFeedbackDevice := fSaveDevice;

						DoFeedback

						END

					END

				ELSE
					BEGIN

					fFeedbackDevice := NIL;

					PrepareMap (FALSE);

					fCommand.DoPreview;

					END;

				IF fCommand.fDoc.fMode = IndexedColorMode THEN
					IF fCommand.fView.fPalette <> NIL THEN
						SetPalette (fDialogPtr,
									fCommand.fView.fPalette,
									FALSE)

				END

			END

		UNTIL (item = ok) OR (item = cancel);

	IF fUsingNewColors THEN SetOldColors;

	fLocation^.h := 0;
	fLocation^.v := 0;

	SetPort (fDialogPtr);

	{$H-}
	LocalToGlobal (fLocation^);
	{$H+}

	IF item = cancel THEN Failure (0, 0)

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE THistDialog.IHistDialog (command: TAdjustmentCommand;
								   location: PPoint;
								   hist: THistogram;
								   itsRsrcID: INTEGER;
								   itsHookItem: INTEGER;
								   itsHistItem: INTEGER;
								   itsDfltButton: INTEGER;
								   itsPreviewButton: INTEGER);

	VAR
		r: Rect;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	fHist := hist;

	IFeedbackDialog (command.fView, command, location, itsRsrcID,
					 itsHookItem, itsDfltButton, itsPreviewButton);

	GetDItem (fDialogPtr, itsHistItem, itemType, itemHandle, r);

	fHistRect := r

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE THistDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

	VAR
		bounds: Rect;
		hist: THistogram;

	BEGIN

	INHERITED DrawAmendments (theItem);

	hist := fHist;
	bounds := fHistRect;

	DrawHistogram (hist, bounds)

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TThresholdDialog.IThresholdDialog (command: TThresholdCommand;
											 hist: THistogram);

	CONST
		kDialogID	 = 1031;
		kPreviewItem = 3;
		kHookItem	 = 4;
		kHistItem	 = 5;
		kLevelItem	 = 6;

	VAR
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	IHistDialog (command, @gThresholdLocation, hist,
				 kDialogID, kHookItem, kHistItem, ok, kPreviewItem);

	{$H-}
	GetDItem (fDialogPtr, kLevelItem, itemType, itemHandle, fLevelRect);
	{$H+}

	fPointerRect.top	:= fHistRect.bottom;
	fPointerRect.left	:= fHistRect.left	- gPtrWidth;
	fPointerRect.right	:= fHistRect.right	+ gPtrWidth;
	fPointerRect.bottom := fHistRect.bottom + gBPointer.bounds.bottom;

	fLevel := gLastThreshold

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TThresholdDialog.DrawLevel;

	VAR
		r: Rect;

	BEGIN

	r := fPointerRect;

	EraseRect (r);

	r.left	:= r.left + fLevel;
	r.right := r.left + gBPointer.bounds.right;

	CopyBits (gWPointer, thePort^.portBits,
			  gWPointer.bounds, r, srcOr, NIL);

	DrawNumber (fLevel, fLevelRect)

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TThresholdDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

	BEGIN

	INHERITED DrawAmendments (theItem);

	DrawLevel

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TThresholdDialog.PrepareMap (forFeedback: BOOLEAN); OVERRIDE;

	BEGIN
	TThresholdCommand (fCommand) . fThreshold := fLevel
	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION TThresholdDialog.DownInDialog (mousePt: Point): BOOLEAN; OVERRIDE;

	VAR
		r: Rect;
		pt: Point;
		level: INTEGER;

	BEGIN

	DownInDialog := FALSE;
	
	r := fPointerRect;
	r.bottom := r.bottom + 6;

	IF PtInRect (mousePt, r) THEN
		BEGIN

			REPEAT

			NextMousePoint (pt);

			level := Max (1, Min (pt.h - r.left - gPtrWidth, 255));

			IF level <> fLevel THEN
				BEGIN
				fLevel := level;
				DrawLevel;
				DoFeedback
				END

			UNTIL fLastPoint;

		DownInDialog := TRUE

		END

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TThresholdCommand.SaveState; OVERRIDE;

	BEGIN
	fPreviewThreshold := fThreshold
	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION TThresholdCommand.SameState: BOOLEAN; OVERRIDE;

	BEGIN
	SameState := (fThreshold = fPreviewThreshold)
	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TThresholdCommand.GetParameters; OVERRIDE;

	VAR
		fi: FailInfo;
		hist: THistogram;
		hist1: THistogram;
		hist2: THistogram;
		hist3: THistogram;
		aThresholdDialog: TThresholdDialog;

	PROCEDURE CleanUp1 (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress
		END;

	PROCEDURE CleanUp2 (error: INTEGER; message: LONGINT);
		BEGIN
		aThresholdDialog.Free
		END;

	BEGIN

	CommandProgress (cHistogram);
	CatchFailures (fi, CleanUp1);

	GetHistogram (fView, TRUE, hist, hist1, hist2, hist3);

	Success (fi);
	CleanUp1 (0, 0);

	NEW (aThresholdDialog);
	FailNil (aThresholdDialog);

	aThresholdDialog.IThresholdDialog (SELF, hist);

	CatchFailures (fi, CleanUp2);

	aThresholdDialog.DoTalkToUser (StdItemHandling);

	aThresholdDialog.PrepareMap (FALSE);

	gLastThreshold := aThresholdDialog.fLevel;

	Success (fi);

	CleanUp2 (0, 0)

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TThresholdCommand.MapRGB (rPtr, gPtr, bPtr: Ptr;
									count: INTEGER); OVERRIDE;

	BEGIN
	ThresholdLuminosity (rPtr, gPtr, bPtr, gGrayLUT, count, fThreshold)
	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION DoThresholdCommand (view: TImageView): TCommand;

	VAR
		aThresholdCommand: TThresholdCommand;

	BEGIN

	NEW (aThresholdCommand);
	FailNil (aThresholdCommand);

	aThresholdCommand.IAdjustmentCommand (cThresholding, view);

	DoThresholdCommand := aThresholdCommand

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TPosterizeDialog.IPosterizeDialog (command: TPosterizeCommand);

	CONST
		kDialogID	 = 1032;
		kPreviewItem = 3;
		kHookItem	 = 4;
		kLevelsItem  = 5;

	BEGIN

	IFeedbackDialog (command.fView, command, @gPosterizeLocation,
					 kDialogID, kHookItem, ok, kPreviewItem);

	fLevelsText := DefineFixedText (kLevelsItem, 0, FALSE, TRUE, 2, 255);

	fLevelsText.StuffValue (gLastPosterize);

	SetEditSelection (kLevelsItem)

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TPosterizeDialog.PrepareMap (forFeedback: BOOLEAN); OVERRIDE;

	VAR
		gray: INTEGER;
		levels: INTEGER;
		LUT: TLookUpTable;

	BEGIN

	IF fLevelsText.ParseValue THEN
		levels := fLevelsText.fValue
	ELSE
		levels := 256;

	FOR gray := 0 TO 255 DO
		LUT [gray] := CHR (BSR (gray * ORD4 (levels), 8) * 255
						   DIV (levels - 1));

	TPosterizeCommand (fCommand) . fLUT := LUT

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TPosterizeCommand.SaveState; OVERRIDE;

	BEGIN
	fPreviewLUT := fLUT
	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION TPosterizeCommand.SameState: BOOLEAN; OVERRIDE;

	BEGIN
	SameState := EqualBytes (@fLUT, @fPreviewLUT, 256)
	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TPosterizeCommand.GetParameters; OVERRIDE;

	VAR
		fi: FailInfo;
		aPosterizeDialog: TPosterizeDialog;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aPosterizeDialog.Free
		END;

	PROCEDURE MyItemHandling (anItem: INTEGER; VAR done: BOOLEAN);
		BEGIN
		StdItemHandling (anItem, done);
		IF anItem = aPosterizeDialog.fLevelsText.fItemNumber THEN
			IF aPosterizeDialog.fLevelsText.ParseValue THEN
				aPosterizeDialog.DoFeedback
		END;

	BEGIN

	NEW (aPosterizeDialog);
	FailNil (aPosterizeDialog);

	aPosterizeDialog.IPosterizeDialog (SELF);

	CatchFailures (fi, CleanUp);

	aPosterizeDialog.DoTalkToUser (MyItemHandling);

	aPosterizeDialog.PrepareMap (FALSE);

	gLastPosterize := aPosterizeDialog.fLevelsText.fValue;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TPosterizeCommand.MapMonochrome (dataPtr: Ptr;
										   count: INTEGER); OVERRIDE;

	BEGIN
	DoMapBytes (dataPtr, count, fLUT)
	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION DoPosterizeCommand (view: TImageView): TCommand;

	VAR
		aPosterizeCommand: TPosterizeCommand;

	BEGIN

	NEW (aPosterizeCommand);
	FailNil (aPosterizeCommand);

	aPosterizeCommand.IAdjustmentCommand (cPosterization, view);

	DoPosterizeCommand := aPosterizeCommand

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TSlidersDialog.ISlidersDialog (command: TAdjustmentCommand;
										 location: PPoint;
										 dialogID: INTEGER;
										 sliders: INTEGER;
										 blackOnes: INTEGER);

	CONST
		kPreviewItem = 3;
		kHookItem	 = 4;
		kScaleItems  = 5;

	VAR
		r: Rect;
		which: INTEGER;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	fSliders := sliders;
	fBlackOnes := blackOnes;

	IFeedbackDialog (command.fView, command, location, dialogID,
					 kHookItem, ok, kPreviewItem);

	FOR which := 1 TO fSliders DO
		BEGIN

		fLevel [which] := 0;

		{$H-}

		GetDItem (fDialogPtr, kScaleItems + which - 1,
				  itemType, itemHandle, fScaleRect [which]);

		GetDItem (fDialogPtr, kScaleItems + fSliders + which - 1,
				  itemType, itemHandle, fLevelRect [which]);

		{$H+}

		r := fScaleRect [which];

		fRange := BSR (r.right - r.left - 1, 1);

		r.top	 := r.bottom;
		r.bottom := r.bottom + gBPointer.bounds.bottom;
		r.left	 := r.left	 - gPtrWidth;
		r.right  := r.right  + gPtrWidth;

		fPointerRect [which] := r;

		fMinValue	 [which] := -fRange;
		fMaxValue	 [which] :=  fRange;
		fSignedValue [which] :=  TRUE

		END

	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION TSlidersDialog.GetValue (which: INTEGER): INTEGER;

	VAR
		level: INTEGER;
		delta: LONGINT;

	BEGIN

	level := fLevel [which] + fRange;

	delta := fMaxValue [which] - fMinValue [which];

	GetValue := fMinValue [which] +
				(level * delta + fRange - 1) DIV BSL (fRange, 1)

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TSlidersDialog.DrawLevel (which: INTEGER);

	VAR
		r: Rect;
		s: Str255;
		value: INTEGER;

	BEGIN

	r := fPointerRect [which];

	EraseRect (r);

	r.left	:= r.left + fRange + fLevel [which];
	r.right := r.left + gBPointer.bounds.right;

	IF which <= fBlackOnes THEN
		CopyBits (gBPointer, thePort^.portBits,
				  gBPointer.bounds, r, srcOr, NIL)
	ELSE
		CopyBits (gWPointer, thePort^.portBits,
				  gWPointer.bounds, r, srcOr, NIL);

	value := GetValue (which);

	NumToString (value, s);

	IF (fSignedValue [which]) AND (value > 0) THEN INSERT ('+', s, 1);

	DrawNoFlicker (s, fLevelRect [which])

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TSlidersDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

	VAR
		r: Rect;
		which: INTEGER;

	BEGIN

	INHERITED DrawAmendments (theItem);

	FOR which := 1 TO fSliders DO
		BEGIN

		r := fScaleRect [which];

		PaintRect (r);

		r.left	:= r.left + fRange;
		r.right := r.left + 1;
		r.top	:= r.top  - 3;

		PaintRect (r);

		DrawLevel (which)

		END

	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION TSlidersDialog.DownInDialog
		(mousePt: Point): BOOLEAN; OVERRIDE;

	VAR
		r: Rect;
		pt: Point;
		which: INTEGER;
		level: INTEGER;
	
	BEGIN

	FOR which := 1 TO fSliders DO
		BEGIN
		
		r := fPointerRect [which];
		r.bottom := r.bottom + 6;
		
		IF PtInRect (mousePt, r) THEN
			BEGIN

				REPEAT

				NextMousePoint (pt);

				level := Max (-fRange,
						 Min (pt.h - (r.left + gPtrWidth + fRange),
						      fRange));

				IF level <> fLevel [which] THEN
					BEGIN
					fLevel [which] := level;
					DrawLevel (which);
					DoFeedback
					END

				UNTIL fLastPoint;

			DownInDialog := TRUE;
			EXIT (DownInDialog)

			END
			
		END;

	DownInDialog := FALSE

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TBrightnessDialog.IBrightnessDialog (command: TBrightnessCommand;
											   mean: INTEGER);

	CONST
		kDialogID = 1037;

	BEGIN

	fMean := mean;

	ISlidersDialog (command, @gBrightnessLocation, kDialogID, 2, 0)

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TBrightnessDialog.PrepareMap (forFeedback: BOOLEAN); OVERRIDE;

	VAR
		pt: Point;
		gap: LONGINT;
		gray: INTEGER;
		half: LONGINT;
		level: LONGINT;
		LUT: TLookUpTable;

	BEGIN

	pt.h := fMean;
	pt.v := fMean;

	IF fLevel [2] >= 0 THEN
		BEGIN

		pt.h := pt.h - fLevel [1];

		gap := 255 - fLevel [2] * ORD4 (255) DIV fRange;

		half := BSR (gap, 1);

		FOR gray := 0 TO 255 DO
			BEGIN

			IF gap = 0 THEN
				IF gray >= pt.h THEN
					level := 255
				ELSE
					level := 0
			ELSE
				IF gray >= pt.h THEN
					level := pt.v + (255 * ORD4 (gray - pt.h) + half) DIV gap
				ELSE
					level := pt.v - (255 * ORD4 (pt.h - gray) + half) DIV gap;

			LUT [gray] := CHR (Max (0, Min (level, 255)))

			END

		END

	ELSE
		BEGIN

		pt.v := pt.v + fLevel [1];

		gap := 255 + fLevel [2] * ORD4 (255) DIV fRange;

		FOR gray := 0 TO 255 DO
			BEGIN

			IF gray >= pt.h THEN
				level := pt.v + (gap * (gray - pt.h) + 127) DIV 255
			ELSE
				level := pt.v - (gap * (pt.h - gray) + 127) DIV 255;

			LUT [gray] := CHR (Max (0, Min (level, 255)))

			END

		END;

	IF forFeedback THEN AdjustForFeedback (LUT);

	TBrightnessCommand (fCommand) . fLUT := LUT

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TBrightnessCommand.SaveState; OVERRIDE;

	BEGIN
	fPreviewLUT := fLUT
	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION TBrightnessCommand.SameState: BOOLEAN; OVERRIDE;

	BEGIN
	SameState := EqualBytes (@fLUT, @fPreviewLUT, 256);
	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TBrightnessCommand.GetParameters; OVERRIDE;

	VAR
		fi: FailInfo;
		mean: INTEGER;
		count: LONGINT;
		total: EXTENDED;
		hist: THistogram;
		hist1: THistogram;
		hist2: THistogram;
		hist3: THistogram;
		aBrightnessDialog: TBrightnessDialog;

	PROCEDURE CleanUp1 (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress
		END;

	PROCEDURE CleanUp2 (error: INTEGER; message: LONGINT);
		BEGIN
		aBrightnessDialog.Free
		END;

	BEGIN

	CommandProgress (cHistogram);
	CatchFailures (fi, CleanUp1);

	GetHistogram (fView, TRUE, hist, hist1, hist2, hist3);

	Success (fi);
	CleanUp1 (0, 0);

	count := 0;
	total := 0.0;
	FOR mean := 0 TO 255 DO
		BEGIN
		count := count + hist [mean];
		total := total + mean * 1.0 * hist [mean]
		END;
	mean := ROUND (total / count);

	NEW (aBrightnessDialog);
	FailNil (aBrightnessDialog);

	aBrightnessDialog.IBrightnessDialog (SELF, mean);

	CatchFailures (fi, CleanUp2);

	aBrightnessDialog.DoTalkToUser (StdItemHandling);

	aBrightnessDialog.PrepareMap (FALSE);

	IF EqualBytes (@fLUT, @gNullLUT, 256) THEN Failure (0, 0);

	Success (fi);

	CleanUp2 (0, 0)

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TBrightnessCommand.MapMonochrome (dataPtr: Ptr;
											count: INTEGER); OVERRIDE;

	BEGIN
	DoMapBytes (dataPtr, count, fLUT)
	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION DoBrightnessCommand (view: TImageView): TCommand;

	VAR
		aBrightnessCommand: TBrightnessCommand;

	BEGIN

	NEW (aBrightnessCommand);
	FailNil (aBrightnessCommand);

	aBrightnessCommand.IAdjustmentCommand (cAdjustment, view);

	DoBrightnessCommand := aBrightnessCommand

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TBalanceDialog.IBalanceDialog (command: TBalanceCommand);

	CONST
		kDialogID	 = 1035;
		kPreviewItem = 3;
		kHookItem	 = 4;
		kScaleItems  = 5;
		kLevelItems  = 8;

	VAR
		r: Rect;
		which: INTEGER;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	IFeedbackDialog (command.fView, command, @gBalanceLocation, kDialogID,
					 kHookItem, ok, kPreviewItem);

	fBand := 2;

	FOR which := 1 TO 3 DO
		BEGIN

		{$H-}

		GetDItem (fDialogPtr, kScaleItems + which - 1,
				  itemType, itemHandle, fScaleRect [which]);

		GetDItem (fDialogPtr, kLevelItems + which - 1,
				  itemType, itemHandle, fLevelRect [which]);

		{$H+}

		r := fScaleRect [which];

		fRange := BSR (r.right - r.left - 1, 1);

		r.top	 := r.bottom;
		r.bottom := r.bottom + gBPointer.bounds.bottom;
		r.left	 := r.left	 - gPtrWidth;
		r.right  := r.right  + gPtrWidth;

		fPointerRect [which] := r;

		fLevel [1, which] := 0;
		fLevel [2, which] := 0;
		fLevel [3, which] := 0

		END

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TBalanceDialog.DrawLevel (which: INTEGER);

	VAR
		r: Rect;
		s: Str255;
		value: INTEGER;

	BEGIN

	r := fPointerRect [which];

	EraseRect (r);

	r.left	:= r.left + fRange + fLevel [fBand, which];
	r.right := r.left + gBPointer.bounds.right;

		CASE fBand OF

		1:	CopyBits (gBPointer, thePort^.portBits,
					  gBPointer.bounds, r, srcOr, NIL);

		2:	CopyBits (gGPointer, thePort^.portBits,
					  gGPointer.bounds, r, srcOr, NIL);

		3:	CopyBits (gWPointer, thePort^.portBits,
					  gWPointer.bounds, r, srcOr, NIL)

		END;

	value := fLevel [fBand, which];

	NumToString (value, s);

	IF value > 0 THEN INSERT ('+', s, 1);

	DrawNoFlicker (s, fLevelRect [which])

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TBalanceDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

	VAR
		r: Rect;
		which: INTEGER;

	BEGIN

	INHERITED DrawAmendments (theItem);

	FOR which := 1 TO 3 DO
		BEGIN

		r := fScaleRect [which];

		PaintRect (r);

		r.left	:= r.left + fRange;
		r.right := r.left + 1;
		r.top	:= r.top  - 3;

		PaintRect (r);

		DrawLevel (which)

		END

	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION TBalanceDialog.DownInDialog (mousePt: Point): BOOLEAN; OVERRIDE;

	VAR
		r: Rect;
		pt: Point;
		which: INTEGER;
		level: INTEGER;

	BEGIN

	FOR which := 1 TO 3 DO
		BEGIN
		
		r := fPointerRect [which];
		r.bottom := r.bottom + 6;
		
		IF PtInRect (mousePt, r) THEN
			BEGIN

				REPEAT

				NextMousePoint (pt);

				level := Max (-fRange,
						 Min (pt.h - (r.left + gPtrWidth + fRange),
						      fRange));

				IF level <> fLevel [fBand, which] THEN
					BEGIN
					fLevel [fBand, which] := level;
					DrawLevel (which);
					DoFeedback
					END

				UNTIL fLastPoint;

			DownInDialog := TRUE;
			EXIT (DownInDialog)

			END
			
		END;

	DownInDialog := FALSE

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TBalanceDialog.PrepareMap (forFeedback: BOOLEAN); OVERRIDE;

	VAR
		band: INTEGER;
		which: INTEGER;
		gamma: EXTENDED;
		middle: INTEGER;
		SLevel: INTEGER;
		MLevel: INTEGER;
		HLevel: INTEGER;
		LUT: TLookUpTable;
		upper: ARRAY [1..3] OF INTEGER;
		lower: ARRAY [1..3] OF INTEGER;

	BEGIN

	FOR band := 1 TO 3 DO
		BEGIN
		lower [band] := Min (fLevel [band, 1],
						Min (fLevel [band, 2],
							 fLevel [band, 3]));
		upper [band] := Max (fLevel [band, 1],
						Max (fLevel [band, 2],
							 fLevel [band, 3]))
		END;

	middle := (lower [2] + upper [2]) DIV 2;

	FOR which := 1 TO 3 DO
		BEGIN

		SLevel := upper [1] - fLevel [1, which];
		MLevel := fLevel [2, which] - middle;
		HLevel := 255 - fLevel [3, which] + lower [3];

		SetLUTConst (LUT, 0, SLevel, 0);

		IF HLevel > SLevel + 1 THEN
			BEGIN

			IF MLevel = 0 THEN
				gamma := 1.0
			ELSE
				gamma := EXP (MLevel / 100 * LN (2));

			SetLUTGamma (LUT, SLevel, HLevel, 0, 255, gamma)

			END;

		SetLUTConst (LUT, HLevel, 255, 255);

			CASE which OF
			1:	TBalanceCommand (fCommand) . fLUT.R := LUT;
			2:	TBalanceCommand (fCommand) . fLUT.G := LUT;
			3:	TBalanceCommand (fCommand) . fLUT.B := LUT
			END

		END

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TBalanceCommand.SaveState; OVERRIDE;

	BEGIN
	fPreviewLUT := fLUT
	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION TBalanceCommand.SameState: BOOLEAN; OVERRIDE;

	BEGIN
	SameState := EqualBytes (@fLUT, @fPreviewLUT, SIZEOF (TRGBLookUpTable))
	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TBalanceCommand.GetParameters; OVERRIDE;

	CONST
		kShadowsItem	= 11;
		kMidtonesItem	= 12;
		kHighlightsItem = 13;

	VAR
		fi: FailInfo;
		bandCluster: TRadioCluster;
		aBalanceDialog: TBalanceDialog;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBalanceDialog.Free
		END;

	PROCEDURE MyItemHandling (anItem: INTEGER; VAR done: BOOLEAN);

		VAR
			band: INTEGER;

		BEGIN

		StdItemHandling (anItem, done);

		band := bandCluster.fChosenItem - kShadowsItem + 1;

		IF band <> aBalanceDialog.fBand THEN
			BEGIN

			aBalanceDialog.fBand := band;

			aBalanceDialog.DrawLevel (1);
			aBalanceDialog.DrawLevel (2);
			aBalanceDialog.DrawLevel (3);

			END

		END;

	BEGIN

	NEW (aBalanceDialog);
	FailNil (aBalanceDialog);

	aBalanceDialog.IBalanceDialog (SELF);

	CatchFailures (fi, CleanUp);

	bandCluster := aBalanceDialog.DefineRadioCluster (kShadowsItem,
													  kHighlightsItem,
													  kMidtonesItem);

	aBalanceDialog.DoTalkToUser (MyItemHandling);

	aBalanceDialog.PrepareMap (FALSE);

	IF EqualBytes (@fLUT.R, @gNullLUT, 256) &
	   EqualBytes (@fLUT.G, @gNullLUT, 256) &
	   EqualBytes (@fLUT.B, @gNullLUT, 256) THEN Failure (0, 0);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TBalanceCommand.MapRGB (rPtr, gPtr, bPtr: Ptr;
								  count: INTEGER); OVERRIDE;

	BEGIN
	DoMapBytes (rPtr, count, fLUT.R);
	DoMapBytes (gPtr, count, fLUT.G);
	DoMapBytes (bPtr, count, fLUT.B)
	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION DoBalanceCommand (view: TImageView): TCommand;

	VAR
		aBalanceCommand: TBalanceCommand;

	BEGIN

	NEW (aBalanceCommand);
	FailNil (aBalanceCommand);

	aBalanceCommand.IAdjustmentCommand (cAdjustment, view);

	DoBalanceCommand := aBalanceCommand

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TMapArbitraryDialog.IMapArbitraryDialog
		(command: TMapArbitraryCommand);

	CONST
		kDialogID	 = 1033;
		kPreviewItem = 3;
		kHookItem	 = 4;
		kMapItem	 = 5;
		kXLevelItem  = 8;
		kYLevelItem  = 9;

	VAR
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	IFeedbackDialog (command.fView, command, @gArbitraryLocation,
					 kDialogID, kHookItem, ok, kPreviewItem);

	{$H-}

	GetDItem (fDialogPtr, kMapItem, itemType, itemHandle, fMapRect);

	fActiveArea := fMapRect;
	InsetRect (fActiveArea, -4, -4);

	GetDItem (fDialogPtr, kXLevelItem, itemType, itemHandle, fXLevelRect);
	GetDItem (fDialogPtr, kYLevelItem, itemType, itemHandle, fYLevelRect);

	{$H+}

	fPrevPoint.h := fMapRect.left;
	fPrevPoint.v := fMapRect.bottom - 1;

	fBand := 0;

	fSmoothCount := 0;

	fLUT [0] := gNullLUT;
	fLUT [1] := gNullLUT;
	fLUT [2] := gNullLUT;
	fLUT [3] := gNullLUT;

	fXLevel := -1;
	fYLevel := -1

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TMapArbitraryDialog.MarkRulers;

	BEGIN

	PenNormal;
	PenPat (gray);
	PenMode (patXOR);

	IF fXLevel >= 0 THEN
		BEGIN
		MoveTo (fMapRect.left + fXLevel, fMapRect.top - 7);
		Line (0, 5);
		Move (0, 259);
		Line (0, 5)
		END;

	IF fYLevel >= 0 THEN
		BEGIN
		MoveTo (fMapRect.left - 7, fMapRect.bottom - 1 - fYLevel);
		Line (5, 0);
		Move (259, 0);
		Line (5, 0)
		END;

	PenNormal

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TMapArbitraryDialog.DrawLevels;

	VAR
		r: Rect;

	BEGIN

	r := fXLevelRect;

	IF fXLevel < 0 THEN
		EraseRect (r)
	ELSE
		DrawNumber (fXLevel, r);

	r := fYLevelRect;

	IF fYLevel < 0 THEN
		EraseRect (r)
	ELSE
		DrawNumber (fYLevel, r);

	MarkRulers

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TMapArbitraryDialog.UpdateLevels (pt: Point);

	VAR
		x: INTEGER;
		y: INTEGER;

	BEGIN

	x := pt.h - fMapRect.left;
	y := fMapRect.bottom - pt.v - 1;

	IF (x < 0) OR (x > 255) OR (y < 0) OR (y > 255) THEN
		BEGIN
		x := -1;
		y := -1
		END;

	IF (x <> fXLevel) OR (y <> fYLevel) THEN
		BEGIN
		MarkRulers;
		fXLevel := x;
		fYLevel := y;
		DrawLevels
		END

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TMapArbitraryDialog.DrawMap;

	VAR
		r: Rect;
		index: INTEGER;
		LUT: TLookUpTable;

	BEGIN

	PenNormal;

	r := fMapRect;

	EraseRect (r);

	LUT := fLUT [fBand];

	FOR index := 0 TO 255 DO
		BEGIN
		MoveTo (r.left + index, r.bottom - 1 - ORD (LUT [index]));
		Line (0, 0)
		END

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TMapArbitraryDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

	VAR
		r: Rect;
		j: INTEGER;
		x: INTEGER;
		y: INTEGER;

	BEGIN

	INHERITED DrawAmendments (theItem);

	PenNormal;

	r := fMapRect;
	InsetRect (r, -7, -7);
	EraseRect (r);

	r := fMapRect;
	InsetRect (r, -1, -1);
	FrameRect (r);

	FOR j := 0 TO 20 DO
		BEGIN

		x := (j * 255 + 10) DIV 20;

		IF j MOD 10 = 0 THEN
			y := 5
		ELSE IF j MOD 2 = 0 THEN
			y := 3
		ELSE
			y := 1;

		MoveTo (fMapRect.left - y - 2, fMapRect.bottom - 1 - x);
		Line (y, 0);
		Move (259, 0);
		Line (y, 0);

		MoveTo (fMapRect.left + x, fMapRect.top - y - 2);
		Line (0, y);
		Move (0, 259);
		Line (0, y)

		END;

	DrawLevels;

	DrawMap

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TMapArbitraryDialog.PrepareMap (forFeedback: BOOLEAN); OVERRIDE;

	VAR
		gray: INTEGER;
		index: INTEGER;
		LUT: TRGBLookUpTable;

	BEGIN

	FOR index := 0 TO 255 DO
		BEGIN

		gray := ORD (fLUT [0, index]);

		LUT.R [index] := fLUT [1, gray];
		LUT.G [index] := fLUT [2, gray];
		LUT.B [index] := fLUT [3, gray]

		END;

	IF forFeedback THEN
		BEGIN
		AdjustForFeedback (LUT.R);
		AdjustForFeedback (LUT.G);
		AdjustForFeedback (LUT.B)
		END;

	TMapArbitraryCommand (fCommand) . fLUT := LUT

	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION TMapArbitraryDialog.DoSetCursor
		(localPoint: Point): BOOLEAN; OVERRIDE;

	BEGIN

	UpdateLevels (localPoint);

	IF PtInRect (localPoint, fActiveArea) THEN
		BEGIN
		SetToolCursor (PencilTool, TRUE);
		DoSetCursor := TRUE
		END

	ELSE
		DoSetCursor := INHERITED DoSetCursor (localPoint)

	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION LoadMapFile (VAR maps: TLookUpTables; isColor: BOOLEAN): BOOLEAN;

	VAR
		err: OSErr;
		fi: FailInfo;
		where: Point;
		gray: INTEGER;
		index: INTEGER;
		lower: INTEGER;
		count: LONGINT;
		reply: SFReply;
		refNum: INTEGER;
		typeList: SFTypeList;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF refNum <> -1 THEN
			err := FSClose (refNum);
		IF error <> noErr THEN
			gApplication.ShowError (error, msgCannotLoadMap);
		EXIT (LoadMapFile)
		END;

	BEGIN

	LoadMapFile := FALSE;

	refNum := -1;

	CatchFailures (fi, CleanUp);

	WhereToPlaceDialog (getDlgID, where);

	typeList [0] := kMapFileType;

	SFGetFile (where, '', NIL, 1, typeList, NIL, reply);
	IF NOT reply.good THEN Failure (0, 0);

	FailOSErr (FSOpen (reply.fName, reply.vRefNum, refNum));

	FailOSErr (GetEOF (refNum, count));

	IF (count MOD SIZEOF (TLookUpTable) <> 0) THEN
		Failure (eofErr, 0);

		CASE count DIV SIZEOF (TLookUpTable) OF

		1:	lower := 0;
		3:	lower := 1;
		4:	lower := 0;

		OTHERWISE
			Failure (eofErr, 0)

		END;

	maps [0] := gNullLUT;
	maps [1] := gNullLUT;
	maps [2] := gNullLUT;
	maps [3] := gNullLUT;

	FailOSErr (FSRead (refNum, count, @maps [lower]));

	FailOSErr (FSClose (refNum));

	Success (fi);

	IF NOT isColor THEN
		BEGIN
		FOR index := 0 TO 255 DO
			BEGIN
			gray := ORD (maps [0, index]);
			maps [0, index] := ConvertToGray (maps [1, gray],
											  maps [2, gray],
											  maps [3, gray])
			END;
		maps [1] := gNullLUT;
		maps [2] := gNullLUT;
		maps [3] := gNullLUT
		END;

	LoadMapFile := TRUE

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TMapArbitraryDialog.DoLoadMap;

	VAR
		index: INTEGER;
		maps: TLookUpTables;

	BEGIN

	IF LoadMapFile (maps, fIsColor) THEN
		BEGIN

		FOR index := 0 TO 3 DO
			fLUT [index] := maps [index];

		SetPort (fDialogPtr);

		InvalRect (fMapRect);

		IF fFeedbackDevice <> NIL THEN
			GetNewColors

		END

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE SaveMapFile (VAR maps: TLookUpTables; promptID: INTEGER);

	VAR
		fi: FailInfo;
		band: INTEGER;
		lower: INTEGER;
		upper: INTEGER;
		count: LONGINT;
		reply: SFReply;
		prompt: Str255;
		refNum: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		VAR
			ignore: OSErr;

		BEGIN
		IF refNum <> -1 THEN
			ignore := FSClose (refNum);
		IF error <> noErr THEN
			gApplication.ShowError (error, msgCannotSaveMap);
		EXIT (SaveMapFile)
		END;

	BEGIN

	refNum := -1;

	CatchFailures (fi, CleanUp);

	GetIndString (prompt, kStringsID, promptID);

	refNum := CreateOutputFile (prompt, kMapFileType, reply);

	IF EqualBytes (@maps [1], @gNullLUT, 256) &
	   EqualBytes (@maps [2], @gNullLUT, 256) &
	   EqualBytes (@maps [3], @gNullLUT, 256) THEN
		BEGIN
		lower := 0;
		upper := 0
		END

	ELSE IF EqualBytes (@maps [0], @gNullLUT, 256) THEN
		BEGIN
		lower := 1;
		upper := 3
		END

	ELSE
		BEGIN
		lower := 0;
		upper := 3
		END;

	FOR band := lower TO upper DO
		BEGIN
		count := SIZEOF (TLookUpTable);
		FailOSErr (FSWrite (refNum, count, @maps [band]))
		END;

	FailOSErr (FSClose (refNum));
	refNum := -1;

	FailOSErr (FlushVol (NIL, reply.vRefNum));

	Success (fi)

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TMapArbitraryDialog.DoSaveMap;

	VAR
		maps: TLookUpTables;

	BEGIN

	maps := fLUT;

	SaveMapFile (maps, strSaveMapIn)

	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION TMapArbitraryDialog.IsSafeButton (item: INTEGER): BOOLEAN; OVERRIDE;

	CONST
		kResetItem	= 10;
		kSmoothItem = 11;

	BEGIN
	IsSafeButton := (item = kResetItem) OR (item = kSmoothItem)
	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TMapArbitraryDialog.DoButtonPushed
		(anItem: INTEGER; VAR succeeded: BOOLEAN); OVERRIDE;

	CONST
		kLoadItem	= 6;
		kSaveItem	= 7;
		kResetItem	= 10;
		kSmoothItem = 11;

	BEGIN

		CASE anItem OF

		kLoadItem:
			BEGIN
			fSmoothCount := 0;
			succeeded := FALSE;
			DoLoadMap
			END;

		kSaveItem:
			BEGIN
			succeeded := FALSE;
			DoSaveMap
			END;

		kResetItem,
		kSmoothItem:
			BEGIN

			succeeded := FALSE;

			IF anItem = kResetItem THEN
				BEGIN
				fSmoothCount := 0;
				fLUT [fBand] := gNullLUT
				END
			ELSE
				BEGIN
				fSmoothCount := Min (fSmoothCount + 1, 10);
				{$H-}
				SmoothLUT (fLUT [fBand], 5 * fSmoothCount, 3, FALSE);
				{$H+}
				END;

			SetPort (fDialogPtr);
			DrawMap;

			DoFeedback

			END;

		OTHERWISE
			INHERITED DoButtonPushed (anItem, succeeded)

		END

	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ADoAdjust}

FUNCTION TMapArbitraryDialog.DownInDialog (mousePt: Point): BOOLEAN; OVERRIDE;

	VAR
		pt1: Point;
		pt2: Point;
		peekEvent: EventRecord;

	PROCEDURE MarkPoint (pt: Point);

		VAR
			gray: INTEGER;
			index: INTEGER;

		BEGIN

		index := pt.h - fMapRect.left;

		IF (index >= 0) AND (index <= 255) THEN
			BEGIN

			gray  := fMapRect.bottom - 1 - pt.v;

			IF gray < 0   THEN gray := 0;
			IF gray > 255 THEN gray := 255;

			IF fLUT [fBand, index] <> CHR (gray) THEN
				BEGIN

				PenPat (white);

				MoveTo (fMapRect.left + index,
						fMapRect.bottom - ORD (fLUT [fBand, index]) - 1);

				Line (0, 0);

				fLUT [fBand, index] := CHR (gray);

				PenPat (black);

				MoveTo (fMapRect.left + index,
						fMapRect.bottom - gray - 1);

				Line (0, 0)

				END

			END

		END;

	PROCEDURE DrawLine (fromPt, toPt: Point);

		VAR
			pt: Point;
			j: INTEGER;
			dh: INTEGER;
			dv: LONGINT;
			half: LONGINT;

		BEGIN

		dh := toPt.h - fromPt.h;
		dv := toPt.v - fromPt.v;

		IF dv >= 0 THEN
			half := BSR (ABS (dh), 1)
		ELSE
			half := -BSR (ABS (dh), 1);

		IF dh > 0 THEN
			FOR j := 1 TO dh - 1 DO
				BEGIN
				pt.h := fromPt.h + j;
				pt.v := fromPt.v + (j * dv + half) DIV dh;
				MarkPoint (pt)
				END
		ELSE
			FOR j := 1 TO -dh - 1 DO
				BEGIN
				pt.h := fromPt.h - j;
				pt.v := fromPt.v + (j * dv + half) DIV (-dh);
				MarkPoint (pt)
				END;

		MarkPoint (toPt);

		DoFeedback

		END;

	BEGIN

	DownInDialog := FALSE;

	IF PtInRect (mousePt, fActiveArea) THEN
		BEGIN

		fSmoothCount := 0;

		PenNormal;

		pt1 := mousePt;

		IF fShiftDown THEN
			DrawLine (fPrevPoint, pt1)
		ELSE
			DrawLine (pt1, pt1);

		WHILE StillDown DO
			BEGIN
			GetMouse (pt2);
			UpdateLevels (pt2);
			IF NOT EqualPt (pt1, pt2) THEN
				BEGIN
				DrawLine (pt1, pt2);
				pt1 := pt2
				END
			END;

		IF EventAvail (mUpMask, peekEvent) THEN
			BEGIN
			pt2 := peekEvent.where;
			GlobalToLocal (pt2);
			IF NOT EqualPt (pt1, pt2) THEN
				DrawLine (pt1, pt2)
			END;

		fPrevPoint := pt2;

		DownInDialog := TRUE

		END

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TMapArbitraryCommand.GetParameters; OVERRIDE;

	CONST
		kMainItem = 12;
		kBlueItem = 15;

	VAR
		fi: FailInfo;
		item: INTEGER;
		itemBox: Rect;
		itemType: INTEGER;
		itemHandle: Handle;
		bandCluster: TRadioCluster;
		aMapArbitraryDialog: TMapArbitraryDialog;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aMapArbitraryDialog.Free
		END;

	PROCEDURE MyItemHandling (anItem: INTEGER; VAR done: BOOLEAN);

		VAR
			band: INTEGER;

		BEGIN

		StdItemHandling (anItem, done);

		band := bandCluster.fChosenItem - kMainItem;

		IF band <> aMapArbitraryDialog.fBand THEN
			BEGIN
			aMapArbitraryDialog.fSmoothCount := 0;
			aMapArbitraryDialog.fBand := band;
			aMapArbitraryDialog.DrawMap
			END

		END;

	BEGIN

	NEW (aMapArbitraryDialog);
	FailNil (aMapArbitraryDialog);

	aMapArbitraryDialog.IMapArbitraryDialog (SELF);

	CatchFailures (fi, CleanUp);

	bandCluster := aMapArbitraryDialog.DefineRadioCluster
				   (kMainItem, kBlueItem, kMainItem);

	aMapArbitraryDialog.fIsColor := (fDoc.fMode = IndexedColorMode) OR
									(fView.fChannel = kRGBChannels);

	IF NOT aMapArbitraryDialog.fIsColor THEN
		FOR item := kMainItem TO kBlueItem DO
			BEGIN
			GetDItem (aMapArbitraryDialog.fDialogPtr,
					  item, itemType, itemHandle, itemBox);
			HideControl (ControlHandle (itemHandle))
			END;

	aMapArbitraryDialog.DoTalkToUser (MyItemHandling);

	aMapArbitraryDialog.PrepareMap (FALSE);

	IF EqualBytes (@fLUT.R, @gNullLUT, 256) &
	   EqualBytes (@fLUT.G, @gNullLUT, 256) &
	   EqualBytes (@fLUT.B, @gNullLUT, 256) THEN Failure (0, 0);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION DoMapArbitraryCommand (view: TImageView): TCommand;

	VAR
		aMapArbitraryCommand: TMapArbitraryCommand;

	BEGIN

	NEW (aMapArbitraryCommand);
	FailNil (aMapArbitraryCommand);

	aMapArbitraryCommand.IAdjustmentCommand (cMapping, view);

	DoMapArbitraryCommand := aMapArbitraryCommand

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TLevelsDialog.ILevelsDialog (command: TLevelsCommand;
									   hist: THistogram);

	CONST
		kDialogID	 = 1034;
		kPreviewItem = 3;
		kHookItem	 = 4;
		kHistItem	 = 5;
		kOutputItem  = 6;
		kBLevelItem  = 7;
		kGLevelItem  = 8;
		kWLevelItem  = 9;
		kLLevelItem  = 10;
		kHLevelItem  = 11;

	VAR
		band: INTEGER;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	IHistDialog (command, @gLevelsLocation, hist,
				 kDialogID, kHookItem, kHistItem, ok, kPreviewItem);

	{$H-}

	GetDItem (fDialogPtr, kOutputItem, itemType, itemHandle, fOutputRect);

	GetDItem (fDialogPtr, kBLevelItem, itemType, itemHandle, fBRect);
	GetDItem (fDialogPtr, kGLevelItem, itemType, itemHandle, fGRect);
	GetDItem (fDialogPtr, kWLevelItem, itemType, itemHandle, fWRect);
	GetDItem (fDialogPtr, kLLevelItem, itemType, itemHandle, fLRect);
	GetDItem (fDialogPtr, kHLevelItem, itemType, itemHandle, fHRect);

	{$H+}

	fInLevelsRect.top	 := fHistRect.bottom;
	fInLevelsRect.left	 := fHistRect.left	 - gPtrWidth;
	fInLevelsRect.right  := fHistRect.right  + gPtrWidth;
	fInLevelsRect.bottom := fHistRect.bottom + gBPointer.bounds.bottom;

	fOutLevelsRect.top	  := fOutputRect.bottom;
	fOutLevelsRect.left   := fOutputRect.left	- gPtrWidth;
	fOutLevelsRect.right  := fOutputRect.right	+ gPtrWidth;
	fOutLevelsRect.bottom := fOutputRect.bottom + gBPointer.bounds.bottom;

	fBand := 0;

	FOR band := 0 TO 3 DO
		BEGIN

		WITH fLevels [band] DO
			BEGIN

			fBLevel := 0;
			fGLevel := 128;
			fWLevel := 255;
			fLLevel := 0;
			fHLevel := 255;

			fFraction := FixRatio (1, 2);
			fGamma	  := 100

			END;

		fLUT [band] := gNullLUT

		END

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TLevelsDialog.DrawInputLevels;

	VAR
		r: Rect;
		s: Str255;
		levels: TFiveLevels;

	BEGIN

	levels := fLevels [fBand];

	WITH levels DO
		BEGIN

		r := fInLevelsRect;

		EraseRect (r);

		r.left	:= r.left + fBLevel;
		r.right := r.left + gBPointer.bounds.right;

		CopyBits (gBPointer, thePort^.portBits,
				  gBPointer.bounds, r, srcOr, NIL);

		OffsetRect (r, fGLevel - fBLevel, 0);

		CopyBits (gGPointer, thePort^.portBits,
				  gGPointer.bounds, r, srcOr, NIL);

		OffsetRect (r, fWLevel - fGLevel, 0);

		CopyBits (gWPointer, thePort^.portBits,
				  gWPointer.bounds, r, srcOr, NIL);

		DrawNumber (fBLevel, fBRect);

		s := '  .  ';
		IF fGamma >= 1000 THEN s[1] := CHR (ORD ('0') + fGamma DIV 1000);
		s[2] := CHR (ORD ('0') + fGamma DIV 100 MOD 10);
		s[4] := CHR (ORD ('0') + fGamma DIV 10 MOD 10);
		s[5] := CHR (ORD ('0') + fGamma MOD 10);

		DrawNoFlicker (s, fGRect);

		DrawNumber (fWLevel, fWRect)

		END

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TLevelsDialog.DrawOutputLevels;

	VAR
		r: Rect;
		levels: TFiveLevels;

	BEGIN

	levels := fLevels [fBand];

	WITH levels DO
		BEGIN

		r := fOutLevelsRect;

		EraseRect (r);

		r.left	:= r.left + fLLevel;
		r.right := r.left + gBPointer.bounds.right;

		CopyBits (gBPointer, thePort^.portBits,
				  gBPointer.bounds, r, srcOr, NIL);

		OffsetRect (r, fHLevel - fLLevel, 0);

		CopyBits (gWPointer, thePort^.portBits,
				  gWPointer.bounds, r, srcOr, NIL);

		DrawNumber (fLLevel, fLRect);
		DrawNumber (fHLevel, fHRect)

		END

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TLevelsDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

	BEGIN

	INHERITED DrawAmendments (theItem);

	PaintRect (fOutputRect);

	DrawInputLevels;

	DrawOutputLevels

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TLevelsDialog.PrepareMap (forFeedback: BOOLEAN); OVERRIDE;

	VAR
		gray: INTEGER;
		index: INTEGER;
		LUT: TLookUpTable;
		CLUT: TRGBLookUpTable;

	BEGIN

	WITH fLevels [fBand] DO
		BEGIN

		SetLUTConst (LUT, 0, fBLevel - 1, fLLevel);

		IF fGamma = 100 THEN
			SetLUTLine (LUT, fBLevel, fWLevel, fLLevel, fHLevel)
		ELSE
			SetLUTGamma (LUT, fBLevel, fWLevel,
							  fLLevel, fHLevel, fGamma * 0.01);

		SetLUTConst (LUT, fWLevel + 1, 255, fHLevel);

		END;

	fLUT [fBand] := LUT;

	FOR index := 0 TO 255 DO
		BEGIN

		gray := ORD (fLUT [0, index]);

		CLUT.R [index] := fLUT [1, gray];
		CLUT.G [index] := fLUT [2, gray];
		CLUT.B [index] := fLUT [3, gray]

		END;

	IF forFeedback THEN
		BEGIN
		AdjustForFeedback (CLUT.R);
		AdjustForFeedback (CLUT.G);
		AdjustForFeedback (CLUT.B)
		END;

	TLevelsCommand (fCommand) . fLUT := CLUT

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TLevelsDialog.DoSetLevel (which, what: INTEGER);

	BEGIN

	IF which <= 3 THEN
		BEGIN

		WITH fLevels [fBand] DO

			IF which = 2 THEN
				BEGIN

				fGLevel := what;

				fFraction := FixRatio (fGLevel - fBLevel, fWLevel - fBLevel);

				IF (fGLevel = BSR (fBLevel + fWLevel	, 1)) OR
				   (fGLevel = BSR (fBLevel + fWLevel + 1, 1)) THEN
					fGamma := 100

				ELSE
					BEGIN
					fGamma := ROUND (LN ((fWLevel - fBLevel) /
										 (fGLevel - fBLevel)) *
										 (100 / LN (2)));
					fGamma := Max (10, Min (fGamma, 9999))
					END

				END

			ELSE
				BEGIN

				IF which = 1 THEN
					fBLevel := what
				ELSE
					fWLevel := what;

				fGLevel := fBLevel + FixRound (fFraction * (fWLevel -
															fBLevel));

				IF fGLevel = fBLevel THEN fGLevel := fBLevel + 1;
				IF fGLevel = fWLevel THEN fGLevel := fWLevel - 1

				END;

		DrawInputLevels

		END

	ELSE
		BEGIN

		WITH fLevels [fBand] DO
			IF which = 4 THEN
				fLLevel := what
			ELSE
				fHLevel := what;

		DrawOutputLevels

		END;

	DoFeedback

	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION TLevelsDialog.DownInDialog (mousePt: Point): BOOLEAN; OVERRIDE;

	VAR
		r: Rect;
		pt: Point;
		which: INTEGER;
		delta: INTEGER;
		lower: INTEGER;
		upper: INTEGER;
		newLevel: INTEGER;
		oldLevel: INTEGER;

	BEGIN

	DownInDialog := FALSE;

	WITH fLevels [fBand] DO
		BEGIN
		
		which := 0;
		
		newLevel := mousePt.h - fHistRect.left;

		r := fInLevelsRect;
		r.bottom := r.bottom + 6;

		IF PtInRect (mousePt, r) THEN
			BEGIN

			which := 2;
			delta := newLevel - fGLevel;

			IF ABS (newLevel - fBLevel) < ABS (delta) THEN
				BEGIN
				which := 1;
				delta := newLevel - fBLevel
				END;

			IF ABS (newLevel - fWLevel) < ABS (delta) THEN
				BEGIN
				which := 3;
				delta := newLevel - fWLevel
				END

			END;
			
		r := fOutLevelsRect;
		r.bottom := r.bottom + 6;

		IF PtInRect (mousePt, r) THEN
			BEGIN

			which := 4;
			delta := newLevel - fLLevel;

			IF (fLLevel = fHLevel) AND
			   ((fLLevel = 0) OR (delta > 0)) AND
			   (fLLevel <> 255) THEN
				which := 5;

			IF ABS (newLevel - fHLevel) < ABS (delta) THEN
				BEGIN
				which := 5;
				delta := newLevel - fHLevel
				END

			END;
			
		IF which = 0 THEN
			EXIT (DownInDialog);

		DownInDialog := TRUE;

			CASE which OF

			1:	BEGIN
				lower := 0;
				upper := fWLevel - 2
				END;

			2:	BEGIN
				lower := fBLevel + 1;
				upper := fWLevel - 1
				END;

			3:	BEGIN
				lower := fBLevel + 2;
				upper := 255
				END;

			4:	BEGIN
				lower := 0;
				upper := fHLevel
				END;

			5:	BEGIN
				lower := fLLevel;
				upper := 255
				END

			END

		END;

	oldLevel := newLevel - delta;

		REPEAT

		NextMousePoint (pt);

		newLevel := Max (lower, Min (pt.h - fHistRect.left, upper));

		IF newLevel <> oldLevel THEN
			BEGIN
			DoSetLevel (which, newLevel);
			oldLevel := newLevel
			END

		UNTIL fLastPoint

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TLevelsCommand.GetParameters; OVERRIDE;

	CONST
		kMainItem  = 12;
		kRedItem   = 13;
		kGreenItem = 14;
		kBlueItem  = 15;

	VAR
		fi: FailInfo;
		item: INTEGER;
		itemBox: Rect;
		itemType: INTEGER;
		itemHandle: Handle;
		bandCluster: TRadioCluster;
		aLevelsDialog: TLevelsDialog;
		hist: ARRAY [0..3] OF THistogram;

	PROCEDURE CleanUp1 (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress
		END;

	PROCEDURE CleanUp2 (error: INTEGER; message: LONGINT);
		BEGIN
		aLevelsDialog.Free
		END;

	PROCEDURE MyItemHandling (anItem: INTEGER; VAR done: BOOLEAN);

		VAR
			band: INTEGER;
			gray: INTEGER;
			index: INTEGER;
			LUT: TLookUpTable;
			thisHist: THistogram;

		BEGIN

		StdItemHandling (anItem, done);

		band := bandCluster.fChosenItem - kMainItem;

		IF band <> aLevelsDialog.fBand THEN
			BEGIN

			aLevelsDialog.PrepareMap (FALSE);

			aLevelsDialog.fBand := band;

			IF band = 0 THEN
				thisHist := hist [0]

			ELSE
				BEGIN

				LUT := aLevelsDialog.fLUT [0];

				DoSetBytes (@thisHist, SIZEOF (THistogram), 0);

				FOR index := 0 TO 255 DO
					BEGIN
					gray := ORD (LUT [index]);
					thisHist [gray] := thisHist [gray] + hist [band, index]
					END

				END;

			aLevelsDialog.fHist := thisHist;

			aLevelsDialog.DrawAmendments (1)

			END

		END;

	BEGIN

	CommandProgress (cHistogram);
	CatchFailures (fi, CleanUp1);

	GetHistogram (fView, FALSE, hist [0], hist [1], hist [2], hist [3]);

	Success (fi);
	CleanUp1 (0, 0);

	NEW (aLevelsDialog);
	FailNil (aLevelsDialog);

	aLevelsDialog.ILevelsDialog (SELF, hist [0]);

	CatchFailures (fi, CleanUp2);

	bandCluster := aLevelsDialog.DefineRadioCluster (kMainItem,
													 kBlueItem,
													 kMainItem);

	IF (fDoc.fMode <> IndexedColorMode) AND
	   (fView.fChannel <> kRGBChannels) THEN
		FOR item := kMainItem TO kBlueItem DO
			BEGIN
			GetDItem (aLevelsDialog.fDialogPtr,
					  item, itemType, itemHandle, itemBox);
			HideControl (ControlHandle (itemHandle))
			END;

	aLevelsDialog.DoTalkToUser (MyItemHandling);

	aLevelsDialog.PrepareMap (FALSE);

	IF EqualBytes (@fLUT.R, @gNullLUT, 256) &
	   EqualBytes (@fLUT.G, @gNullLUT, 256) &
	   EqualBytes (@fLUT.B, @gNullLUT, 256) THEN Failure (0, 0);

	Success (fi);

	CleanUp2 (0, 0)

	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION DoLevelsCommand (view: TImageView): TCommand;

	VAR
		aLevelsCommand: TLevelsCommand;

	BEGIN

	NEW (aLevelsCommand);
	FailNil (aLevelsCommand);

	aLevelsCommand.IAdjustmentCommand (cAdjustment, view);

	DoLevelsCommand := aLevelsCommand

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TSaturationDialog.ISaturationDialog (command: TSaturationCommand);

	CONST
		kDialogID = 1036;

	BEGIN

	ISlidersDialog (command, @gSaturationLocation, kDialogID, 2, 0);

	fColorize := FALSE;

	fMinValue [1] := -180;
	fMaxValue [1] :=  180

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TSaturationDialog.PrepareMap (forFeedback: BOOLEAN); OVERRIDE;

	VAR
		gray: INTEGER;
		offset: INTEGER;
		LUT: TLookUpTable;

	BEGIN

	offset := GetValue (1) * 128 DIV 180;

	IF fColorize THEN
		SetLUTConst (LUT, 0, 255, BAND (offset, $FF))
	ELSE
		FOR gray := 0 TO 255 DO
			LUT [gray] := CHR (BAND (gray + offset, $FF));

	TSaturationCommand (fCommand) . fHueLUT := LUT;

	IF fColorize THEN
		BEGIN
		gray := GetValue (2) * 255 DIV 100;
		SetLUTConst (LUT, 0, 255, gray)
		END
	ELSE IF fLevel [2] > 0 THEN
		BEGIN
		gray := 255 - fLevel [2] * ORD4 (254) DIV fRange;
		SetLUTLine (LUT, 0, gray, 0, 255);
		SetLUTConst (LUT, gray + 1, 255, 255)
		END
	ELSE
		BEGIN
		gray := 255 + fLevel [2] * ORD4 (255) DIV fRange;
		SetLUTLine (LUT, 0, 255, 0, gray)
		END;

	TSaturationCommand (fCommand) . fSatLUT := LUT

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TSaturationCommand.SaveState; OVERRIDE;

	BEGIN
	fPreviewHue := fHueLUT;
	fPreviewSat := fSatLUT
	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION TSaturationCommand.SameState: BOOLEAN; OVERRIDE;

	BEGIN
	SameState := EqualBytes (@fHueLUT, @fPreviewHue, 256) AND
				 EqualBytes (@fSatLUT, @fPreviewSat, 256)
	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TSaturationCommand.GetParameters; OVERRIDE;

	CONST
		kColorizeItem = 9;

	VAR
		fi: FailInfo;
		colorizeBox: TCheckBox;
		aSaturationDialog: TSaturationDialog;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aSaturationDialog.Free
		END;

	PROCEDURE MyItemHandling (anItem: INTEGER; VAR done: BOOLEAN);
		BEGIN

		StdItemHandling (anItem, done);

		IF anItem = kColorizeItem THEN
			BEGIN

			aSaturationDialog.fColorize := colorizeBox.fChecked;

			IF aSaturationDialog.fColorize THEN
				BEGIN
				aSaturationDialog.fLevel [2] := aSaturationDialog.fRange;
				aSaturationDialog.fMinValue [2] := 0;
				aSaturationDialog.fMaxValue [2] := 100;
				aSaturationDialog.fSignedValue [1] := FALSE;
				aSaturationDialog.fSignedValue [2] := FALSE
				END

			ELSE
				BEGIN
				aSaturationDialog.fLevel [2] := 0;
				aSaturationDialog.fMinValue [2] := -aSaturationDialog.fRange;
				aSaturationDialog.fMaxValue [2] :=	aSaturationDialog.fRange;
				aSaturationDialog.fSignedValue [1] := TRUE;
				aSaturationDialog.fSignedValue [2] := TRUE
				END;

			aSaturationDialog.DrawLevel (1);
			aSaturationDialog.DrawLevel (2);

			aSaturationDialog.DoFeedback

			END

		END;

	BEGIN

	NEW (aSaturationDialog);
	FailNil (aSaturationDialog);

	aSaturationDialog.ISaturationDialog (SELF);

	CatchFailures (fi, CleanUp);

	colorizeBox := aSaturationDialog.DefineCheckBox (kColorizeItem, FALSE);

	aSaturationDialog.DoTalkToUser (MyItemHandling);

	aSaturationDialog.PrepareMap (FALSE);

	IF EqualBytes (@fHueLUT, @gNullLUT, 256) &
	   EqualBytes (@fSatLUT, @gNullLUT, 256) THEN Failure (0, 0);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ADoAdjust}

PROCEDURE TSaturationCommand.MapRGB (rPtr, gPtr, bPtr: Ptr;
									 count: INTEGER); OVERRIDE;

	BEGIN

	DoRGB2HSLorB (rPtr, gPtr, bPtr, rPtr, gPtr, bPtr, count, FALSE);

	DoMapBytes (rPtr, count, fHueLUT);
	DoMapBytes (gPtr, count, fSatLUT);

	DoHSLorB2RGB (rPtr, gPtr, bPtr, rPtr, gPtr, bPtr, count, FALSE)

	END;

{*****************************************************************************}

{$S ADoAdjust}

FUNCTION DoSaturationCommand (view: TImageView): TCommand;

	VAR
		aSaturationCommand: TSaturationCommand;

	BEGIN

	NEW (aSaturationCommand);
	FailNil (aSaturationCommand);

	aSaturationCommand.IAdjustmentCommand (cAdjustment, view);

	DoSaturationCommand := aSaturationCommand

	END;

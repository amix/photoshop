{Photoshop version 1.0.1, file: UHistogram.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UHistogram;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UBWDialog, UProgress;

TYPE

	THistogramDialog = OBJECT (TBWDialog)

		fLevel: INTEGER;

		fHist: THistogram;

		fHistRect: Rect;

		PROCEDURE THistogramDialog.IHistogramDialog (hist: THistogram);

		PROCEDURE THistogramDialog.DrawStatistics;

		PROCEDURE THistogramDialog.DrawLevelInfo;

		PROCEDURE THistogramDialog.DrawAmendments
				(theItem: INTEGER); OVERRIDE;

		FUNCTION THistogramDialog.DoSetCursor
				(localPoint: Point): BOOLEAN; OVERRIDE;

		END;

PROCEDURE GetHistogram (view: TImageView;
						luminosity: BOOLEAN;
						VAR hist0: THistogram;
						VAR hist1: THistogram;
						VAR hist2: THistogram;
						VAR hist3: THistogram);

PROCEDURE DrawHistogram (hist: THistogram; bounds: Rect);

PROCEDURE DoHistogramCommand (view: TImageView);

IMPLEMENTATION

{$I UAssembly.a.inc}
{$I UAdjust.a.inc}

{*****************************************************************************}

{$S AHistogram}

PROCEDURE GetHistogram (view: TImageView;
						luminosity: BOOLEAN;
						VAR hist0: THistogram;
						VAR hist1: THistogram;
						VAR hist2: THistogram;
						VAR hist3: THistogram);

	VAR
		r: Rect;
		fi: FailInfo;
		row: INTEGER;
		srcPtr1: Ptr;
		srcPtr2: Ptr;
		srcPtr3: Ptr;
		maskPtr: Ptr;
		mask: TVMArray;
		index: INTEGER;
		width: INTEGER;
		height: INTEGER;
		channels: INTEGER;
		doc: TImageDocument;
		saveHist: THistogram;

	PROCEDURE CleanUp1 (error: INTEGER; message: LONGINT);

		BEGIN

		IF mask <> NIL THEN
			BEGIN
			IF maskPtr <> NIL THEN mask.DoneWithPtr;
			mask.Flush
			END;

		IF srcPtr1 <> NIL THEN
			doc.fFloatData [0] . DoneWithPtr;

		IF srcPtr2 <> NIL THEN
			doc.fFloatData [1] . DoneWithPtr;

		IF srcPtr3 <> NIL THEN
			doc.fFloatData [2] . DoneWithPtr;

		doc.fFloatData [0] . Flush;

		IF channels = 3 THEN
			BEGIN
			doc.fFloatData [1] . Flush;
			doc.fFloatData [2] . Flush
			END

		END;

	PROCEDURE CleanUp2 (error: INTEGER; message: LONGINT);

		BEGIN

		IF mask <> NIL THEN
			BEGIN
			IF maskPtr <> NIL THEN mask.DoneWithPtr;
			mask.Flush
			END;

		IF channels = 3 THEN
			BEGIN

			IF srcPtr1 <> NIL THEN doc.fData [0] . DoneWithPtr;
			IF srcPtr2 <> NIL THEN doc.fData [1] . DoneWithPtr;
			IF srcPtr3 <> NIL THEN doc.fData [2] . DoneWithPtr;

			doc.fData [0] . Flush;
			doc.fData [1] . Flush;
			doc.fData [2] . Flush

			END

		ELSE
			BEGIN

			IF srcPtr1 <> NIL THEN
				doc.fData [view.fChannel] . DoneWithPtr;

			doc.fData [view.fChannel] . Flush

			END

		END;

	BEGIN

	MoveHands (TRUE);

	DoSetBytes (@hist0, SIZEOF (THistogram), 0);
	DoSetBytes (@hist1, SIZEOF (THistogram), 0);
	DoSetBytes (@hist2, SIZEOF (THistogram), 0);
	DoSetBytes (@hist3, SIZEOF (THistogram), 0);

	doc := TImageDocument (view.fDocument);

	IF view.fChannel = kRGBChannels THEN
		channels := 3
	ELSE
		channels := 1;

	IF doc.fSelectionFloating AND
	   NOT doc.fExactFloat AND
	   (doc.fFloatChannel = view.fChannel) THEN
		BEGIN

		width  := doc.fFloatData [0] . fLogicalSize;
		height := doc.fFloatData [0] . fBlockCount;

		mask := doc.fFloatMask;
		maskPtr := NIL;

		IF mask <> NIL THEN
			mask.Preload (channels + 1);

		srcPtr1 := NIL;
		srcPtr2 := NIL;
		srcPtr3 := NIL;

		CatchFailures (fi, CleanUp1);

		FOR row := 0 TO height - 1 DO
			BEGIN

			MoveHands (TRUE);

			UpdateProgress (row, height);

			IF mask <> NIL THEN
				maskPtr := mask.NeedPtr (row, row, FALSE);

			srcPtr1 := doc.fFloatData [0] . NeedPtr (row, row, FALSE);

			IF channels = 3 THEN
				BEGIN

				srcPtr2 := doc.fFloatData [1] . NeedPtr (row, row, FALSE);
				srcPtr3 := doc.fFloatData [2] . NeedPtr (row, row, FALSE);

				IF luminosity THEN
					DoHistLuminosity (srcPtr1, srcPtr2, srcPtr3, maskPtr,
									  gGrayLUT, width, hist0);

				DoHistBytes (srcPtr1, maskPtr, width, hist1);
				DoHistBytes (srcPtr2, maskPtr, width, hist2);
				DoHistBytes (srcPtr3, maskPtr, width, hist3);

				doc.fFloatData [1] . DoneWithPtr;
				doc.fFloatData [2] . DoneWithPtr;

				srcPtr2 := NIL;
				srcPtr3 := NIL

				END

			ELSE
				DoHistBytes (srcPtr1, maskPtr, width, hist0);

			doc.fFloatData [0] . DoneWithPtr;

			srcPtr1 := NIL;

			IF maskPtr <> NIL THEN
				BEGIN
				mask.DoneWithPtr;
				maskPtr := NIL
				END

			END;

		Success (fi);

		CleanUp1 (0, 0)

		END

	ELSE
		BEGIN

		r := doc.fSelectionRect;

		IF EmptyRect (r) THEN doc.GetBoundsRect (r);

		width  := r.right - r.left;
		height := r.bottom - r.top;

		mask := doc.fSelectionMask;
		maskPtr := NIL;

		IF mask <> NIL THEN
			mask.Preload (channels + 1);

		srcPtr1 := NIL;
		srcPtr2 := NIL;
		srcPtr3 := NIL;

		CatchFailures (fi, CleanUp2);

		FOR row := 0 TO height - 1 DO
			BEGIN

			MoveHands (TRUE);

			UpdateProgress (row, height);

			IF mask <> NIL THEN
				maskPtr := mask.NeedPtr (row, row, FALSE);

			IF channels = 3 THEN
				BEGIN

				srcPtr1 := Ptr (ORD4 (doc.fData [0] .
									  NeedPtr (row + r.top,
											   row + r.top,
											   FALSE)) + r.left);
				srcPtr2 := Ptr (ORD4 (doc.fData [1] .
									  NeedPtr (row + r.top,
											   row + r.top,
											   FALSE)) + r.left);
				srcPtr3 := Ptr (ORD4 (doc.fData [2] .
									  NeedPtr (row + r.top,
											   row + r.top,
											   FALSE)) + r.left);


				IF luminosity THEN
					DoHistLuminosity (srcPtr1, srcPtr2, srcPtr3, maskPtr,
									  gGrayLUT, width, hist0);

				DoHistBytes (srcPtr1, maskPtr, width, hist1);
				DoHistBytes (srcPtr2, maskPtr, width, hist2);
				DoHistBytes (srcPtr3, maskPtr, width, hist3);

				doc.fData [0] . DoneWithPtr;
				doc.fData [1] . DoneWithPtr;
				doc.fData [2] . DoneWithPtr;

				srcPtr1 := NIL;
				srcPtr2 := NIL;
				srcPtr3 := NIL

				END

			ELSE
				BEGIN

				srcPtr1 := Ptr (ORD4 (doc.fData [view.fChannel] .
									  NeedPtr (row + r.top,
											   row + r.top,
											   FALSE)) + r.left);

				DoHistBytes (srcPtr1, maskPtr, width, hist0);

				doc.fData [view.fChannel] . DoneWithPtr;

				srcPtr1 := NIL

				END;

			IF maskPtr <> NIL THEN
				BEGIN
				mask.DoneWithPtr;
				maskPtr := NIL
				END

			END;

		Success (fi);

		CleanUp2 (0, 0)

		END;

	UpdateProgress (1, 1);

	IF doc.fMode = IndexedColorMode THEN
		BEGIN

		FOR row := 0 TO 255 DO
			BEGIN

			index := ORD (doc.fIndexedColorTable.R [row]);
			hist1 [index] := hist1 [index] + hist0 [row];

			index := ORD (doc.fIndexedColorTable.G [row]);
			hist2 [index] := hist2 [index] + hist0 [row];

			index := ORD (doc.fIndexedColorTable.B [row]);
			hist3 [index] := hist3 [index] + hist0 [row]

			END;

		IF luminosity THEN
			BEGIN

			saveHist := hist0;

			DoSetBytes (@hist0, SIZEOF (THistogram), 0);

			FOR row := 0 TO 255 DO
				BEGIN

				index := ORD (gGrayLUT.R
							  [ORD (doc.fIndexedColorTable.R [row])]) +
						 ORD (gGrayLUT.G
							  [ORD (doc.fIndexedColorTable.G [row])]) +
						 ORD (gGrayLUT.B
							  [ORD (doc.fIndexedColorTable.B [row])]);

				hist0 [index] := hist0 [index] + saveHist [row]

				END

			END;

		channels := 3

		END;

	IF (channels = 3) AND NOT luminosity THEN
		FOR row := 0 TO 255 DO
			hist0 [row] := hist1 [row] + hist2 [row] + hist3 [row]

	END;

{*****************************************************************************}

{$S AHistogram}

PROCEDURE DrawHistogram (hist: THistogram; bounds: Rect);

	VAR
		r: Rect;
		big: LONGINT;
		gray: INTEGER;
		total: LONGINT;
		count: INTEGER;
		height: INTEGER;
		level: ARRAY [0..255] OF INTEGER;

	BEGIN

	big := 0;
	count := 0;
	total := 0;

	FOR gray := 0 TO 255 DO
		BEGIN

		total := total + hist [gray];

		IF hist [gray] > 0 THEN
			count := count + 1;

		IF hist [gray] > big THEN
			big := hist [gray]

		END;

	EraseRect (bounds);

	r	  := bounds;
	r.top := r.bottom - 1;

	PaintRect (r);

	IF count <> 0 THEN
		BEGIN

		big := Min (big, 4 * total DIV count);

		height := bounds.bottom - bounds.top - 2;

		FOR gray := 0 TO 255 DO
			IF hist [gray] = 0 THEN
				level [gray] := 0
			ELSE IF hist [gray] > big THEN
				level [gray] := height
			ELSE
				level [gray] := Max (1, ROUND (hist [gray] / big * height));

		FOR gray := 0 TO 255 DO
			IF level [gray] <> 0 THEN
				BEGIN
				r.left	 := bounds.left + gray;
				r.right  := r.left + 1;
				r.bottom := bounds.bottom - 2;
				r.top	 := r.bottom - level [gray];
				PaintRect (r)
				END

		END

	END;

{*****************************************************************************}

{$S AHistogram}

PROCEDURE THistogramDialog.IHistogramDialog (hist: THistogram);

	CONST
		kDialogID = 1012;
		kHookItem = 2;
		kHistItem = 3;

	VAR
		r: Rect;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	fLevel := -1;

	fHist := hist;

	IBWDialog (kDialogID, kHookItem, ok);

	GetDItem (fDialogPtr, kHistItem, itemType, itemHandle, r);

	fHistRect := r

	END;

{*****************************************************************************}

{$S AHistogram}

PROCEDURE THistogramDialog.DrawStatistics;

	CONST
		kMeanItem	= 8;
		kStdDevItem = 9;
		kMedianItem = 10;
		kPixelsItem = 11;

	VAR
		r: Rect;
		s: Str255;
		x: EXTENDED;
		gray: INTEGER;
		sum0: LONGINT;
		total: LONGINT;
		sum1: EXTENDED;
		sum2: EXTENDED;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	sum0 := 0;
	sum1 := 0;
	sum2 := 0;

	FOR gray := 0 TO 255 DO
		BEGIN
		x := fHist [gray];
		sum0 := sum0 + fHist [gray];
		sum1 := sum1 + x * gray;
		sum2 := sum2 + x * SQR (ORD4 (gray))
		END;

	GetDItem (fDialogPtr, kMeanItem, itemType, itemHandle, r);

	IF sum0 < 1 THEN
		EraseRect (r)
	ELSE
		BEGIN
		ConvertFixed (ROUND (sum1 / sum0 * 100), 2, FALSE, s);
		TextBox (@s[1], LENGTH (s), r, teJustLeft)
		END;

	GetDItem (fDialogPtr, kStdDevItem, itemType, itemHandle, r);

	IF sum0 < 2 THEN
		EraseRect (r)
	ELSE
		BEGIN
		ConvertFixed (ROUND (SQRT ((sum2 - SQR (sum1) / sum0) /
								   (sum0 - 1)) * 100), 2, FALSE, s);
		TextBox (@s[1], LENGTH (s), r, teJustLeft)
		END;

	GetDItem (fDialogPtr, kPixelsItem, itemType, itemHandle, r);

	NumToString (sum0, s);
	TextBox (@s[1], LENGTH (s), r, teJustLeft);

	GetDItem (fDialogPtr, kMedianItem, itemType, itemHandle, r);

	IF sum0 < 1 THEN
		EraseRect (r)
	ELSE
		BEGIN

		gray  := 0;
		total := fHist [0];

		sum0 := (sum0 + 1) DIV 2;

		WHILE total < sum0 DO
			BEGIN
			gray  := gray + 1;
			total := total + fHist [gray]
			END;

		NumToString (gray, s);
		TextBox (@s[1], LENGTH (s), r, teJustLeft)

		END

	END;

{*****************************************************************************}

{$S AHistogram}

PROCEDURE THistogramDialog.DrawLevelInfo;

	CONST
		kLevelItem	 = 12;
		kCountItem	 = 13;
		kPercentItem = 14;

	VAR
		r1: Rect;
		r2: Rect;
		r3: Rect;
		s: Str255;
		gray: INTEGER;
		total1: LONGINT;
		total2: LONGINT;
		itemType: INTEGER;
		itemHandle: Handle;

	BEGIN

	GetDItem (fDialogPtr, kLevelItem  , itemType, itemHandle, r1);
	GetDItem (fDialogPtr, kCountItem  , itemType, itemHandle, r2);
	GetDItem (fDialogPtr, kPercentItem, itemType, itemHandle, r3);

	IF fLevel < 0 THEN
		BEGIN
		EraseRect (r1);
		EraseRect (r2);
		EraseRect (r3)
		END

	ELSE
		BEGIN

		NumToString (fLevel, s);
		TextBox (@s[1], LENGTH (s), r1, teJustLeft);

		NumToString (fHist [fLevel], s);
		TextBox (@s[1], LENGTH (s), r2, teJustLeft);

		total1 := 0;

		FOR gray := 0 TO fLevel DO
			total1 := total1 + fHist [gray];

		total2 := total1;

		FOR gray := fLevel + 1 TO 255 DO
			total2 := total2 + fHist [gray];

		IF total2 = 0 THEN
			EraseRect (r3)
		ELSE
			BEGIN
			ConvertFixed (ROUND (total1 / total2 * 10000), 2, FALSE, s);
			TextBox (@s[1], LENGTH (s), r3, teJustLeft)
			END

		END

	END;

{*****************************************************************************}

{$S AHistogram}

PROCEDURE THistogramDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

	BEGIN

	INHERITED DrawAmendments (theItem);

	{$H-}
	DrawHistogram (fHist, fHistRect);
	{$H+}

	DrawStatistics;

	DrawLevelInfo

	END;

{*****************************************************************************}

{$S AHistogram}

FUNCTION THistogramDialog.DoSetCursor (localPoint: Point): BOOLEAN; OVERRIDE;

	CONST
		kHistCursor = 550;

	VAR
		level: INTEGER;

	BEGIN

	IF PtInRect (localPoint, fHistRect) THEN
		BEGIN
		level := localPoint.h - fHistRect.left;
		SetCursor (GetCursor (kHistCursor)^^);
		DoSetCursor := TRUE
		END

	ELSE
		BEGIN
		level := -1;
		DoSetCursor := INHERITED DoSetCursor (localPoint)
		END;

	IF level <> fLevel THEN
		BEGIN
		fLevel := level;
		DrawLevelInfo
		END

	END;

{*****************************************************************************}

{$S AHistogram}

PROCEDURE DoHistogramCommand (view: TImageView);

	CONST
		kFirstBand = 4;
		kLastBand  = 7;

	VAR
		fi: FailInfo;
		item: INTEGER;
		itemBox: Rect;
		itemType: INTEGER;
		itemHandle: Handle;
		doc: TImageDocument;
		bandCluster: TRadioCluster;
		hist: ARRAY [0..3] OF THistogram;
		aHistogramDialog: THistogramDialog;

	PROCEDURE CleanUp1 (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress
		END;

	PROCEDURE CleanUp2 (error: INTEGER; message: LONGINT);
		BEGIN
		aHistogramDialog.Free
		END;

	PROCEDURE MyItemHandling (anItem: INTEGER; VAR done: BOOLEAN);

		VAR
			band: INTEGER;
			oldPick: INTEGER;

		BEGIN

		oldPick := bandCluster.fChosenItem;

		StdItemHandling (anItem, done);

		IF oldPick <> bandCluster.fChosenItem THEN
			BEGIN

			band := bandCluster.fChosenItem - kFirstBand;

			aHistogramDialog.fHist := hist [band];

			aHistogramDialog.DrawAmendments (2)

			END

		END;

	BEGIN

	doc := TImageDocument (view.fDocument);

	CommandProgress (cHistogram);
	CatchFailures (fi, CleanUp1);

	GetHistogram (view, TRUE, hist [0], hist [1], hist [2], hist [3]);

	Success (fi);
	CleanUp1 (0, 0);

	NEW (aHistogramDialog);
	FailNil (aHistogramDialog);

	aHistogramDialog.IHistogramDialog (hist [0]);

	CatchFailures (fi, CleanUp2);

	bandCluster := aHistogramDialog.DefineRadioCluster (kFirstBand,
														kLastBand,
														kFirstBand);

	IF (doc.fMode <> IndexedColorMode) AND
	   (view.fChannel <> kRGBChannels) THEN
		FOR item := kFirstBand TO kLastBand DO
			BEGIN
			GetDItem (aHistogramDialog.fDialogPtr, item,
					  itemType, itemHandle, itemBox);
			HideControl (ControlHandle (itemHandle))
			END;

	aHistogramDialog.TalkToUser (item, MyItemHandling);

	Success (fi);

	CleanUp2 (0, 0)

	END;

{*****************************************************************************}

END.

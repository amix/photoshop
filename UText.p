{Photoshop version 1.0.1, file: UText.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UText;

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

	TOffsetTable = ARRAY [0..255] OF INTEGER;

	TTextTool = OBJECT (TFloatCommand)

		fBasePt: Point;

		fText: Str255;

		fFont	: INTEGER;
		fSize	: INTEGER;
		fLeading: INTEGER;
		fSpacing: INTEGER;
		fStyle	: Style;

		fAlignment: INTEGER;

		fFeather: BOOLEAN;

		PROCEDURE TTextTool.ITextTool (view: TImageView;
									   basePt: Point;
									   theText: Str255;
									   theFont: INTEGER;
									   theSize: INTEGER;
									   theLeading: INTEGER;
									   theSpacing: INTEGER;
									   theStyle: Style;
									   alignment: INTEGER;
									   feather: BOOLEAN);

		PROCEDURE TTextTool.BuildOffsetTable (s: Str255;
											  scale: INTEGER;
											  VAR offsets: TOffsetTable);

		FUNCTION TTextTool.ImageText (VAR r: Rect): TVMArray;

		PROCEDURE TTextTool.DoIt; OVERRIDE;

		PROCEDURE TTextTool.UndoIt; OVERRIDE;

		PROCEDURE TTextTool.RedoIt; OVERRIDE;

		END;

	TTextDialog = OBJECT (TBWDialog)

		fTextHandler: TKeyHandler;

		PROCEDURE TTextDialog.DoFilterEvent (VAR anEvent: EventRecord;
											 VAR itemHit: INTEGER;
											 VAR handledIt: BOOLEAN;
											 VAR doReturn: BOOLEAN); OVERRIDE;

		END;

PROCEDURE InitTextTool;

FUNCTION DoTextTool (view: TImageView; pt: Point): TCommand;

IMPLEMENTATION

{$I UConvert.a.inc}
{$I USelect.p.inc}

VAR
	gTTText: Str255;
	gTTStyle: Style;
	gTTSize: INTEGER;
	gTTPoints: BOOLEAN;
	gTTLocation: Point;
	gTTFeather: BOOLEAN;
	gTTLeading: INTEGER;
	gTTSpacing: INTEGER;
	gTTFontPick: INTEGER;
	gTTAlignment: INTEGER;
	gTTFontMenu: MenuHandle;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitTextTool;

	CONST
		kMenuID = 2000;

	VAR
		id: INTEGER;
		name: Str255;
		item: INTEGER;
		this: INTEGER;
		count: INTEGER;

	BEGIN

	gTTText 	 := '';
	gTTStyle	 := [];
	gTTSize 	 := 12;
	gTTPoints	 := TRUE;
	gTTFeather	 := FALSE;
	gTTLeading	 := 0;
	gTTSpacing	 := 0;
	gTTLocation  := Point (0);
	gTTAlignment := teJustLeft;

	gTTFontMenu := NewMenu (kMenuID, '');
	FailNIL (gTTFontMenu);

	AddResMenu (gTTFontMenu, 'FONT');

	GetFontName (applFont, name);
	GetFNum (name, id);

	gTTFontPick := 1;

	FOR item := CountMItems (gTTFontMenu) DOWNTO 1 DO
		BEGIN

		GetItem (gTTFontMenu, item, name);
		GetFNum (name, this);

		IF this = id THEN
			gTTFontPick := item

		END

	END;

{*****************************************************************************}

{$S ATextTool}

PROCEDURE TTextTool.ITextTool (view: TImageView;
							   basePt: Point;
							   theText: Str255;
							   theFont: INTEGER;
							   theSize: INTEGER;
							   theLeading: INTEGER;
							   theSpacing: INTEGER;
							   theStyle: Style;
							   alignment: INTEGER;
							   feather: BOOLEAN);

	BEGIN

	fBasePt := basePt;

	fText := theText;

	fFont	 := theFont;
	fSize	 := theSize;
	fLeading := theLeading;
	fSpacing := theSpacing;
	fStyle	 := theStyle;

	fAlignment := alignment;

	fFeather := feather;

	IFloatCommand (cTextTool, view)

	END;

{*****************************************************************************}

{$S ATextTool}

PROCEDURE TTextTool.BuildOffsetTable (s: Str255;
									  scale: INTEGER;
									  VAR offsets: TOffsetTable);

	TYPE
		PFamRec 	= ^FamRec;
		HFamRec 	= ^PFamRec;
		PKernTable	= ^KernTable;
		KernEntry	= RECORD
					  kernStyle: INTEGER;
					  kernCount: INTEGER
					  END;
		PKernEntry	= ^KernEntry;
		KernPair	= PACKED RECORD
					  kernFirst : CHAR;
					  kernSecond: CHAR;
					  kernWidth : INTEGER
					  END;
		PKernPair	= ^KernPair;
		PWidthTable = ^WidthTable;
		HWidthTable = ^PWidthTable;

	VAR
		c1: CHAR;
		c2: CHAR;
		w: Fixed;
		dw: Fixed;
		j: INTEGER;
		k: INTEGER;
		fond: HFamRec;
		hScale: Fixed;
		pairs: INTEGER;
		delta: LONGINT;
		pair: PKernPair;
		points: LONGINT;
		styles: INTEGER;
		entry: PKernEntry;
		table: PKernTable;
		nextOffset: LONGINT;
		theMetrics: FMetricRec;

	BEGIN

	points := fSize * scale;

	FontMetrics (theMetrics);

	hScale := FixRatio (HWidthTable (theMetrics.wTabHandle)^^.hOutput,
						HWidthTable (theMetrics.wTabHandle)^^.hFactor);

	dw := FixRatio (fSpacing, 10) * scale;

	FOR j := 1 TO LENGTH (s) DO
		BEGIN

		w := HWidthTable (theMetrics.wTabHandle)^^.tabData [ORD (s [j]) + 1];

		w := FixMul (w, hScale);

		IF j <> LENGTH (s) THEN
			w := Max (0, w + dw);

		offsets [j] := FixRound (w)

		END;

	fond := HFamRec (GetResource ('FOND', fFont));

	IF fond <> NIL THEN
		IF fond^^.ffKernOff <> 0 THEN
			BEGIN

			table := PKernTable (ORD4 (fond^) + fond^^.ffKernOff);

			entry := PKernEntry (ORD4 (table) + SIZEOF (INTEGER));

			styles := table^.numKerns;

			WHILE styles >= 0 DO
				BEGIN

				pairs := entry^.kernCount;

				IF entry^.kernStyle = BAND ($FF, Ptr (@fStyle)^) THEN
					BEGIN

					FOR j := 1 TO LENGTH (s) - 1 DO
						BEGIN

						c1 := s [j];
						c2 := s [j + 1];

						pair := PKernPair (ORD4 (entry) + SIZEOF (KernEntry));

						FOR k := 1 TO pairs DO
							BEGIN

							IF (pair^.kernFirst  = c1) AND
							   (pair^.kernSecond = c2) THEN
								BEGIN

								delta := pair^.kernWidth * points;

								IF delta >= 0 THEN
									delta := (delta + 2048) DIV 4096
								ELSE
									delta := (delta - 2048) DIV 4096;

								offsets [j] := offsets [j] + delta;

								LEAVE

								END;

							pair := PKernPair (ORD4 (pair) + SIZEOF (KernPair))

							END

						END;

					LEAVE

					END;

				entry := PKernEntry (ORD4 (entry) +
									 ORD4 (pairs) * SIZEOF (KernPair) +
									 SIZEOF (KernEntry));

				styles := styles - 1

				END

			END;

	offsets [0] := 0;

	FOR j := 2 TO LENGTH (s) DO
		BEGIN

		nextOffset := offsets [j] + ORD4 (offsets [j-1]);

		IF nextOffset > kMaxCoord THEN
			Failure (errTextTooBig, 0);

		offsets [j] := nextOffset

		END

	END;

{*****************************************************************************}

{$S ATextTool}

FUNCTION TTextTool.ImageText (VAR r: Rect): TVMArray;

	VAR
		rr: Rect;
		s: Str255;
		j: INTEGER;
		k: INTEGER;
		bm: BitMap;
		base: Point;
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		pad: INTEGER;
		line: INTEGER;
		gray: INTEGER;
		offset: Point;
		info: FontInfo;
		chars: INTEGER;
		total: INTEGER;
		scale: INTEGER;
		count: INTEGER;
		extra: INTEGER;
		width: LONGINT;
		buffer: Handle;
		height: LONGINT;
		hist: THistogram;
		baseRow: INTEGER;
		offPort: GrafPort;
		savePort: GrafPtr;
		aVMArray: TVMArray;
		bVMArray: TVMArray;
		lineHeight: INTEGER;
		offsets: TOffsetTable;
		thresTable: TThresTable;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		FinishProgress;

		SetPort (savePort);

		FreeLargeHandle (buffer);

		FreeObject (aVMArray)

		END;

	PROCEDURE CountLines;

		VAR
			index: INTEGER;

		BEGIN

		count := 1;

		FOR index := 1 TO LENGTH (fText) DO
			IF fText [index] = CHR ($0D) THEN
				count := count + 1

		END;

	PROCEDURE GetLine;

		VAR
			j: INTEGER;
			k: INTEGER;
			stop: INTEGER;
			start: INTEGER;

		BEGIN

		start := 1;

		FOR j := 1 TO line - 1 DO
			BEGIN
			WHILE fText [start] <> CHR ($0D) DO
				start := start + 1;
			start := start + 1
			END;

		stop := start;

		WHILE (stop <= LENGTH (fText)) & (fText [stop] <> CHR ($0D)) DO
			stop := stop + 1;

		s [0] := CHR (stop - start);

		BlockMove (@fText [start], @s[1], LENGTH (s))

		END;

	BEGIN

	buffer	 := NIL;
	aVMArray := NIL;

	GetPort (savePort);

	CommandProgress (fCmdNumber);

	CatchFailures (fi, CleanUp);

	OpenPort (@offPort);

	IF fFeather THEN
		BEGIN
		scale := 4;
		WHILE NOT RealFont (fFont, fSize * scale) DO
			BEGIN
			scale := scale - 1;
			IF scale = 1 THEN
				BEGIN
				scale := 4;
				LEAVE
				END
			END
		END
	ELSE
		scale := 1;

	TextFont (fFont);
	TextFace (fStyle);
	TextSize (fSize * scale);

	GetFontInfo (info);

	info.ascent  := (info.ascent  + scale - 1) DIV scale * scale;
	info.descent := (info.descent + scale - 1) DIV scale * scale;
	info.leading := (info.leading + scale - 1) DIV scale * scale;
	info.widMax  := (info.widMax  + scale - 1) DIV scale * scale;

	lineHeight := info.ascent + info.descent + info.leading;

	pad := lineHeight DIV 2 DIV scale * scale + 1;

	IF fLeading = 0 THEN
		extra := 0
	ELSE
		extra := fLeading * scale - lineHeight;

	CountLines;

	width := 0;
	chars := 0;

	FOR line := 1 TO count DO
		BEGIN

		GetLine;

		BuildOffsetTable (s, scale, offsets);

		width := Max (width, offsets [LENGTH (s)]);

		chars := chars + LENGTH (s)

		END;

	width := (width + scale - 1) DIV scale * scale + 2 * info.widMax;

	height := ORD4 (lineHeight + extra) * count - extra + 2 * pad;

	IF height > kMaxCoord THEN
		Failure (errTextTooBig, 0);

	aVMArray := NewVMArray (height DIV scale, width DIV scale, 1);

		CASE fAlignment OF

		teJustLeft:
			offset.h := (width - info.widMax) DIV scale;

		teJustRight:
			offset.h := info.widMax DIV scale;

		teJustCenter:
			offset.h := BSR (width DIV scale, 1)

		END;

	offset.v := (height - info.ascent - pad) DIV scale + 1;

	r.right  := Min (fBasePt.h + ORD4 (offset.h), kMaxCoord);
	r.bottom := Min (fBasePt.v + ORD4 (offset.v), kMaxCoord);

	r.left	 := r.right  - width  DIV scale;
	r.top	 := r.bottom - height DIV scale;

	SetRect (bm.bounds, 0, 0, width, height);

	bm.rowBytes := BSL (BSR (width + 15, 4), 1);

	buffer := NewLargeHandle (bm.rowBytes * ORD4 (bm.bounds.bottom));

	HLock (buffer);

	bm.baseAddr := buffer^;

	SetPortBits (bm);
	ClipRect (bm.bounds);
	RectRgn (offPort.visRgn, bm.bounds);

	EraseRect (bm.bounds);

	StartTask (0.5);

	k := 0;

	FOR line := 1 TO count DO
		BEGIN

		MoveHands (TRUE);

		GetLine;

		BuildOffsetTable (s, scale, offsets);

		base.v := pad + info.ascent + (line - 1) * (lineHeight + extra);

			CASE fAlignment OF

			teJustLeft:
				base.h := info.widMax;

			teJustRight:
				base.h := width - info.widMax - offsets [LENGTH (s)];

			teJustCenter:
				base.h := (width - offsets [LENGTH (s)]) DIV 2

			END;

		FOR j := 1 TO LENGTH (s) DO
			BEGIN

			MoveHands (TRUE);

			UpdateProgress (k, chars);
			k := k + 1;

			MoveTo (base.h + offsets [j-1], base.v);
			DrawChar (s [j])

			END

		END;

	FinishTask;

	SetPort (savePort);

	total := SQR (scale);

	FOR gray := 0 TO total DO
		thresTable [gray] := CHR ((255 * ORD4 (gray) +
								   total DIV 2) DIV total);

	FOR row := 0 TO height DIV scale - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row, height DIV scale);

		srcPtr := Ptr (ORD4 (bm.baseAddr) +
					   ORD4 (bm.rowBytes) * row * scale);

		dstPtr := aVMArray.NeedPtr (row, row, TRUE);

		DeHalftoneRow (srcPtr,
					   dstPtr,
					   bm.rowBytes,
					   width DIV scale,
					   scale,
					   thresTable);

		aVMArray.DoneWithPtr

		END;

	UpdateProgress (1, 1);

	aVMArray.Flush;

	FreeLargeHandle (buffer);
	buffer := NIL;

	offset := r.topLeft;

	aVMArray.FindBounds (r);

	IF EmptyRect (r) THEN Failure (errNoPixels, 0);

	bVMArray := aVMArray.CopyRect (r, 1);

	aVMArray.Free;
	aVMArray := bVMArray;

	OffsetRect (r, offset.h, offset.v);

	rr := r;
	fDoc.SectBoundsRect (rr);
	OffsetRect (rr, -r.left, -r.top);

	aVMArray.HistRect (rr, hist);

	FOR gray := 255 DOWNTO 127 DO
		IF gray = 127 THEN
			Failure (errNoPixels, 0)
		ELSE IF hist [gray] > 0 THEN
			LEAVE;

	Success (fi);

	FinishProgress;

	ImageText := aVMArray

	END;

{*****************************************************************************}

{$S ATextTool}

PROCEDURE TTextTool.DoIt; OVERRIDE;

	VAR
		r: Rect;
		fi: FailInfo;
		selRect: Rect;
		channel: INTEGER;
		selMask: TVMArray;
		channels: INTEGER;
		aVMArray: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		fDoc.FreeFloat;
		FreeObject (selMask);
		FailNewMessage (error, message, msgCannotUseText)
		END;

	BEGIN

	selMask := NIL;

	CatchFailures (fi, CleanUp);

	MoveHands (TRUE);

	IF fView.fChannel = kRGBChannels THEN
		channels := 3
	ELSE
		channels := 1;

	aVMArray := ImageText (r);

	fDoc.fFloatRect    := r;
	fDoc.fFloatMask    := aVMArray;
	fDoc.fFloatCommand := SELF;
	fDoc.fFloatChannel := fView.fChannel;
	fDoc.fExactFloat   := FALSE;

	FOR channel := 0 TO channels - 1 DO
		BEGIN

		aVMArray := NewVMArray (r.bottom - r.top,
								r.right - r.left,
								channels - channel);

		fDoc.fFloatData [channel] := aVMArray;

		aVMArray.SetBytes (fView.ForegroundByte (channel))

		END;

	FOR channel := 0 TO channels - 1 DO
		BEGIN

		aVMArray := NewVMArray (r.bottom - r.top,
								r.right - r.left, 1);

		fDoc.fFloatBelow [channel] := aVMArray

		END;

	CopyBelow (TRUE);

	FailOSErr (CanSelect (selRect, selMask));

	BlendFloat (FALSE);

	ComputeOverlap (r);
	fDoc.UpdateImageArea (r, FALSE, TRUE, fDoc.fFloatChannel);

	fDoc.Select (selRect, selMask);
	fDoc.fSelectionFloating := TRUE;

	Success (fi)

	END;

{*****************************************************************************}

{$S ATextTool}

PROCEDURE TTextTool.UndoIt; OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	MoveHands (FALSE);

	fDoc.DeSelect (NOT fDoc.fSelectionFloating);

	CopyBelow (FALSE);

	ComputeOverlap (r);
	fDoc.UpdateImageArea (r, FALSE, TRUE, fDoc.fFloatChannel)

	END;

{*****************************************************************************}

{$S ATextTool}

PROCEDURE TTextTool.RedoIt; OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	MoveHands (FALSE);

	fDoc.DeSelect (TRUE);

	BlendFloat (FALSE);

	ComputeOverlap (r);
	fDoc.UpdateImageArea (r, FALSE, TRUE, fDoc.fFloatChannel);

	SelectFloat

	END;

{*****************************************************************************}

{$S ATextTool}

PROCEDURE TTextDialog.DoFilterEvent (VAR anEvent: EventRecord;
									 VAR itemHit: INTEGER;
									 VAR handledIt: BOOLEAN;
									 VAR doReturn: BOOLEAN); OVERRIDE;

	VAR
		part: INTEGER;
		ignore: TCommand;
		whichWindow: WindowPtr;

	BEGIN

	fAllowReturn := (fKeyHandler = fTextHandler);

	IF anEvent.what = nullEvent THEN
		IF gApplication.fIdlePriority <> 0 THEN
			gApplication.DoIdle (IdleContinue);

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

		IF (whichWindow = fDialogPtr) AND (part = inDrag) THEN
			BEGIN
			DragWindow (whichWindow, anEvent.where, screenBits.bounds);
			anEvent.what := nullEvent
			END

		END;

	INHERITED DoFilterEvent (anEvent, itemHit, handledIt, doReturn)

	END;

{*****************************************************************************}

{$S ATextTool}

FUNCTION DoTextTool (view: TImageView; pt: Point): TCommand;

	CONST
		kDialogID		= 1013;
		kHookItem		= 3;
		kTextItem		= 4;
		kFontLabel		= 5;
		kFontItem		= 6;
		kSizeItem		= 7;
		kLeadingItem	= 9;
		kSpacingItem	= 10;
		kStyleItems 	= 11;
		kAlignItems 	= 17;
		kTooManyCharsID = 919;
		kSizeMenuID 	= 1009;

	VAR
		s: Str255;
		fi: FailInfo;
		name: Str255;
		item: INTEGER;
		size: INTEGER;
		lower: INTEGER;
		upper: INTEGER;
		ratio: EXTENDED;
		fontID: INTEGER;
		leading: INTEGER;
		spacing: INTEGER;
		style1: TCheckBox;
		style2: TCheckBox;
		style3: TCheckBox;
		style4: TCheckBox;
		style5: TCheckBox;
		style6: TCheckBox;
		doc: TImageDocument;
		aTextTool: TTextTool;
		fontPopUp: TPopUpMenu;
		sizeUnit: TUnitSelector;
		leadingText: TFixedText;
		spacingText: TFixedText;
		textHandler: TKeyHandler;
		aTextDialog: TTextDialog;
		alignCluster: TRadioCluster;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aTextDialog.Free
		END;

	BEGIN

	doc := TImageDocument (view.fDocument);

	IF doc.fMode = HalftoneMode THEN
		Failure (errNoHalftone, msgCannotUseText);

	IF NOT EmptyRect (doc.fSelectionRect) THEN
		BEGIN
		DoTextTool := DropSelection (view);
		EXIT (DoTextTool)
		END;

	view.CvtView2Image (pt);

	NEW (aTextDialog);
	FailNil (aTextDialog);

	aTextDialog.IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	IF LONGINT (gTTLocation) <> 0 THEN
		MoveWindow (aTextDialog.fDialogPtr, gTTLocation.h,
											gTTLocation.v, FALSE);

	NEW (textHandler);
	FailNil (textHandler);

	aTextDialog.fTextHandler := textHandler;

	textHandler.IKeyHandler (kTextItem, aTextDialog);

	textHandler.StuffString (gTTText);

	gTTFontPick := Min (gTTFontPick, CountMItems (gTTFontMenu));

	fontPopUp := aTextDialog.DefinePopUpMenu (kFontLabel,
											  kFontItem,
											  gTTFontMenu,
											  gTTFontPick);

	sizeUnit := aTextDialog.DefineUnitSelector (kSizeItem + 1,
												kSizeItem, 1,
												FALSE,
												kSizeMenuID,
												ORD (gTTPoints) + 1);

	ratio := doc.fStyleInfo.fResolution.value / (72 * $10000);

	IF ratio >= 1 THEN
		lower := 4
	ELSE
		lower := ROUND (4 / ratio);

	IF ratio <= 0.1 THEN
		upper := 9999
	ELSE
		upper := Min (9999, ROUND (1000 / ratio));

	sizeUnit.DefineUnit (1, 0, 0, 4, 1000);
	sizeUnit.DefineUnit (1, 0, 0, lower, upper);

	sizeUnit.StuffFixed (0, BSL (gTTSize, 16));

	leadingText := aTextDialog.DefineFixedText
				   (kLeadingItem, 0, TRUE, TRUE, 0, Max (1000, upper));

	IF gTTLeading <> 0 THEN
		leadingText.StuffValue (gTTLeading);

	spacingText := aTextDialog.DefineFixedText
				   (kSpacingItem, 1, TRUE, TRUE, -999, 9999);

	IF gTTSpacing <> 0 THEN
		spacingText.StuffValue (gTTSpacing);

	style1 := aTextDialog.DefineCheckBox (kStyleItems,
										  bold IN gTTStyle);

	style2 := aTextDialog.DefineCheckBox (kStyleItems + 1,
										  italic IN gTTStyle);

	style3 := aTextDialog.DefineCheckBox (kStyleItems + 2,
										  underline IN gTTStyle);

	style4 := aTextDialog.DefineCheckBox (kStyleItems + 3,
										  outline IN gTTStyle);

	style5 := aTextDialog.DefineCheckBox (kStyleItems + 4,
										  shadow IN gTTStyle);

	style6 := aTextDialog.DefineCheckBox (kStyleItems + 5,
										  gTTFeather);

	alignCluster := aTextDialog.DefineRadioCluster
					(kAlignItems,
					 kAlignItems + 2,
					 kAlignItems + ORD (gTTAlignment = teJustCenter) +
							   2 * ORD (gTTAlignment = teJustRight));

	aTextDialog.SetEditSelection (kTextItem);

		REPEAT

		aTextDialog.TalkToUser (item, StdItemHandling);

		SetPort (aTextDialog.fDialogPtr);

		gTTLocation := Point (0);
		LocalToGlobal (gTTLocation);

		IF item <> ok THEN Failure (0, 0);

		GetIText (textHandler.fItemHandle, s);

		IF GetHandleSize (textHandler.fItemHandle) <= 255 THEN LEAVE;

		textHandler.StuffString (s);

		aTextDialog.SetEditSelection (kTextItem);

		BWNotice (kTooManyCharsID, TRUE)

		UNTIL FALSE;

	WHILE (LENGTH (s) > 0) & (s [LENGTH (s)] = CHR (13)) DO
		DELETE (s, LENGTH (s), 1);

	gTTText := s;

	gTTFontPick := fontPopUp.fPick;

	gTTSize := HiWrd (sizeUnit.GetFixed (0));

	gTTLeading := leadingText.fValue;
	gTTSpacing := spacingText.fValue;

	gTTPoints := (sizeUnit.fPick = 2);

	gTTStyle := [];

	IF style1.fChecked THEN gTTStyle := gTTStyle + [bold];
	IF style2.fChecked THEN gTTStyle := gTTStyle + [italic];
	IF style3.fChecked THEN gTTStyle := gTTStyle + [underline];
	IF style4.fChecked THEN gTTStyle := gTTStyle + [outline];
	IF style5.fChecked THEN gTTStyle := gTTStyle + [shadow];

	gTTFeather := style6.fChecked;

		CASE alignCluster.fChosenItem - kAlignItems OF
		0:	gTTAlignment := teJustLeft;
		1:	gTTAlignment := teJustCenter;
		2:	gTTAlignment := teJustRight
		END;

	Success (fi);

	aTextDialog.Free;

	IF LENGTH (s) = 0 THEN Failure (0, 0);

	GetItem (gTTFontMenu, gTTFontPick, name);
	GetFNum (name, fontID);

	IF gTTPoints THEN
		BEGIN
		size	:= ROUND (gTTSize * ratio);
		leading := Min (4000, ROUND (gTTLeading * ratio));
		spacing := Max (-32000, Min (32000, ROUND (gTTSpacing * ratio)))
		END
	ELSE
		BEGIN
		size	:= gTTSize;
		leading := gTTLeading;
		spacing := gTTSpacing
		END;

	NEW (aTextTool);
	FailNil (aTextTool);

	aTextTool.ITextTool (view, pt, gTTText, fontID, size, leading, spacing,
						 gTTStyle, gTTAlignment, gTTFeather);

	DoTextTool := aTextTool

	END;

{*****************************************************************************}

END.

{Photoshop version 1.0.1, file: UPick.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UPick;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	QuickDraw32Bit, PickerIntf, UDialog, UBWDialog, UCommands,
	UAdjust, UGhost, USeparation;

CONST
	kStorageCells = 30;

TYPE

	TPickerView = OBJECT (TView)

		fColorRect: Rect;

		fLevelsRect: Rect;

		fMenuRect1: Rect;
		fMenuRect2: Rect;

		fMenu1: MenuHandle;
		fMenu2: MenuHandle;

		fColorSpace: INTEGER;
		fBackground: BOOLEAN;

		fLevelsLocked: BOOLEAN;

		fLevel: ARRAY [0..3] OF INTEGER;
		fOffset: ARRAY [0..3] OF INTEGER;

		fStorageRect: Rect;

		fStorage: ARRAY [0..kStorageCells-1] OF RGBColor;

		fScratchRect: Rect;

		fScratchView: TScratchView;

		PROCEDURE TPickerView.IPickerView;

		PROCEDURE TPickerView.ComputeLevels;

		PROCEDURE TPickerView.ComputeColor (VAR color: RGBColor);

		PROCEDURE TPickerView.DrawColor;

		PROCEDURE TPickerView.DrawStorage (cell1: INTEGER; cell2: INTEGER);

		PROCEDURE TPickerView.GetSliderRect (band: INTEGER; VAR r: Rect);

		PROCEDURE TPickerView.DrawSliders;

		PROCEDURE TPickerView.DrawLevel (band: INTEGER);

		PROCEDURE TPickerView.DrawLevels;

		PROCEDURE TPickerView.UpdateColor;

		PROCEDURE TPickerView.Draw (area: Rect); OVERRIDE;

		FUNCTION TPickerView.DoMouseCommand
				(VAR downLocalPoint: Point;
				 VAR info: EventInfo;
				 VAR hysteresis: Point): TCommand; OVERRIDE;

		END;

	TScratchFrame = OBJECT (TFrame)

		FUNCTION TScratchFrame.AdjustSBars: BOOLEAN; OVERRIDE;

		END;

	TScratchView = OBJECT (TImageView)

		fLastBand: INTEGER;
		fLastSubtractive: BOOLEAN;

		PROCEDURE TScratchView.IScratchView (doc: TImageDocument);

		FUNCTION TScratchView.DoMouseCommand
				(VAR downLocalPoint: Point;
				 VAR info: EventInfo;
				 VAR hysteresis: Point): TCommand; OVERRIDE;

		PROCEDURE TScratchView.GetViewScreenInfo
				(VAR depth: INTEGER;
				 VAR monochrome: BOOLEAN); OVERRIDE;

		FUNCTION TScratchView.ColorizeBand
				(VAR band: INTEGER;
				 VAR subtractive: BOOLEAN): BOOLEAN; OVERRIDE;

		PROCEDURE TScratchView.CheckDither; OVERRIDE;

		FUNCTION TScratchView.MinMagnification: INTEGER; OVERRIDE;

		END;

	DualColor = RECORD
				rgb: RGBColor;
				hsv: HSVColor
				END;

	TCubeDialog = OBJECT (TBWDialog)

		fOldColor: DualColor;
		fCurColor: DualColor;
		fNewColor: DualColor;

		fWarnRect: Rect;
		fCoreRect: Rect;
		fCrossRect: Rect;
		fPatchRect: Rect;

		fColorTable: CTabHandle;

		fPalette: PaletteHandle;

		fBuffer1: Handle;
		fBuffer2: Handle;

		fCoreCluster: TRadioCluster;

		fCoords: ARRAY [0..9] OF TFixedText;

		fCMYKMode: BOOLEAN;

		fWarning: BOOLEAN;

		fDirty: BOOLEAN;
		fDirtyTime: LONGINT;

		PROCEDURE TCubeDialog.ICubeDialog (color: RGBColor);

		PROCEDURE TCubeDialog.Free; OVERRIDE;

		FUNCTION TCubeDialog.GetDepth: INTEGER;

		PROCEDURE TCubeDialog.DrawRGB (rPtr: Ptr;
									   gPtr: Ptr;
									   bPtr: Ptr;
									   area: Rect;
									   magnification: INTEGER);

		PROCEDURE TCubeDialog.DrawPatch (which: BOOLEAN);

		PROCEDURE TCubeDialog.DecodeCoords (color: DualColor;
											VAR hsb: BOOLEAN;
											VAR a1, a2, a3: INTEGER;
											VAR c1, c2, c3: INTEGER);

		PROCEDURE TCubeDialog.DrawCircle (c1, c2: INTEGER;
										  turnOn: BOOLEAN);

		PROCEDURE TCubeDialog.DrawCross (area: Rect);

		PROCEDURE TCubeDialog.DrawLevel (c3: INTEGER);

		PROCEDURE TCubeDialog.DrawCore (level: BOOLEAN);

		PROCEDURE TCubeDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

		PROCEDURE TCubeDialog.CoreChanged;

		PROCEDURE TCubeDialog.StuffCoordsHSB;

		PROCEDURE TCubeDialog.StuffCoordsRGB;

		PROCEDURE TCubeDialog.StuffCoordsCMYK;

		PROCEDURE TCubeDialog.StuffCoords;

		PROCEDURE TCubeDialog.UpdateNewColor (c1, c2, c3: INTEGER);

		PROCEDURE TCubeDialog.TrackLevel;

		PROCEDURE TCubeDialog.TrackCircle;

		PROCEDURE TCubeDialog.DoFilterEvent
				(VAR anEvent: EventRecord;
				 VAR itemHit: INTEGER;
				 VAR handledIt: BOOLEAN;
				 VAR doReturn: BOOLEAN); OVERRIDE;

		PROCEDURE TCubeDialog.ClearDirty;

		PROCEDURE TCubeDialog.TypedHSB;

		PROCEDURE TCubeDialog.TypedRGB;

		PROCEDURE TCubeDialog.TypedCMYK;

		END;

	TEyedropperTool = OBJECT (TCommand)

		fView: TImageView;

		fBackground: BOOLEAN;

		PROCEDURE TEyedropperTool.IEyedropperTool
				(view: TImageView; background: BOOLEAN);

		PROCEDURE TEyedropperTool.TrackFeedBack
				(anchorPoint, nextPoint: Point;
				 turnItOn, mouseDidMove: BOOLEAN); OVERRIDE;

		FUNCTION TEyedropperTool.TrackMouse
				(aTrackPhase: TrackPhase;
				 VAR anchorPoint, previousPoint, nextPoint: Point;
				 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

		END;

PROCEDURE InitPicker;

FUNCTION PickerVisible: BOOLEAN;

FUNCTION PickerBackground: BOOLEAN;

PROCEDURE ShowPicker (visible: BOOLEAN);

PROCEDURE TrackPickerCursor (mousePt: Point;
							 spaceDown: BOOLEAN;
							 shiftDown: BOOLEAN;
							 optionDown: BOOLEAN;
							 commandDown: BOOLEAN);

PROCEDURE InvalidateGhostColors;

PROCEDURE InvalidateCMYKPicker;

PROCEDURE ResetGroundColors;

FUNCTION DoSetColor (cube: BOOLEAN;
					 index: INTEGER;
					 VAR color: RGBColor): BOOLEAN;

PROCEDURE DoSetForeground;

PROCEDURE DoSetBackground;

FUNCTION DoEyedropperTool (view: TImageView;
						   background: BOOLEAN): TCommand;

IMPLEMENTATION

{$I UAssembly.a.inc}
{$I UConvert.a.inc}
{$I UCrop.p.inc}
{$I UDither.a.inc}
{$I UDraw.p.inc}
{$I UFloat.a.inc}
{$I UFloat.p.inc}
{$I UMagnification.p.inc}
{$I USelect.p.inc}

VAR
	gPickerRgn: RgnHandle;

	gPickerView: TPickerView;
	gPickerWindow: TGhostWindow;

	gAllowCube: BOOLEAN;

	gCubeLocation: Point;

	gCoreColor: INTEGER;

	gWarnIcon: BitMap;
	gWarnIconData: PACKED ARRAY [0..29] OF CHAR;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitPicker;

	BEGIN

	gPickerRgn := NewRgn;
	FailNil (gPickerRgn);

	NEW (gPickerView);
	FailNil (gPickerView);

	gPickerView.IPickerView;

	gAllowCube := TRUE;

	gCubeLocation := Point (0);

	gCoreColor := 0;

	SetRect (gWarnIcon.bounds, 0, 0, 16, 15);

	gWarnIcon.rowBytes := 2;
	gWarnIcon.baseAddr := @gWarnIconData;

	StuffHex (@gWarnIconData,
			  '018002400240042005A0099009901188118821842004418241828001FFFF');

	END;

{*****************************************************************************}

{$S ARes4}

FUNCTION PickerVisible: BOOLEAN;

	BEGIN

	PickerVisible := ORD (WindowPeek (gPickerWmgrWindow)^.visible) <> 0

	END;

{*****************************************************************************}

{$S ARes4}

FUNCTION PickerBackground: BOOLEAN;

	BEGIN

	PickerBackground := gPickerView.fBackground

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE ShowPicker (visible: BOOLEAN);

	BEGIN

	gPickerWindow.ShowGhost (visible)

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE TPickerView.IPickerView;

	CONST
		kPickerID = 1003;
		kMenu1ID  = 1010;
		kMenu2ID  = 1011;

	VAR
		r: Rect;
		cell: INTEGER;
		gray: INTEGER;
		location: Point;
		channel: INTEGER;
		ph: PaletteHandle;
		aVMArray: TVMArray;
		sView: TScratchView;
		sDoc: TImageDocument;
		sFrame: TScratchFrame;

	PROCEDURE SetStorage (cell, r, g, b: INTEGER);
		BEGIN
		fStorage [cell] . red	:= r * $101;
		fStorage [cell] . green := g * $101;
		fStorage [cell] . blue	:= b * $101
		END;

	BEGIN

	SetRect (r, 0, 0, 333, 124);

	IView (NIL, NIL, r, sizeFixed, sizeFixed, TRUE, HLOn);

	{$H-}
	SetRect (fColorRect  , 182, 64, 234, 116);
	SetRect (fLevelsRect ,	 4,  3, 173,  62);
	SetRect (fStorageRect,	10, 69, 169, 116);
	SetRect (fScratchRect, 248,  8, 324, 115);
	{$H+}

	fColorSpace := 1;
	fBackground := FALSE;

	fLevelsLocked := FALSE;

	fMenu1 := GetMenu (kMenu1ID);
	FailNil (fMenu1);

	fMenu2 := GetMenu (kMenu2ID);
	FailNil (fMenu2);

	CalcMenuSize (fMenu1);
	CalcMenuSize (fMenu2);

	fMenuRect1.top	  := 36;
	fMenuRect1.left   := 182;
	fMenuRect1.bottom := fMenuRect1.top + 16;
	fMenuRect1.right  := Min (fMenuRect1.left + fMenu1^^.menuWidth,
							  fColorRect.right - 1);

	fMenuRect2.top	  := 10;
	fMenuRect2.left   := 182;
	fMenuRect2.bottom := fMenuRect2.top + 16;
	fMenuRect2.right  := Min (fMenuRect2.left + fMenu2^^.menuWidth,
							  fColorRect.right - 1);

	SetStorage (0, 255,   0,   0);
	SetStorage (1, 255, 255,   0);
	SetStorage (2,	 0, 255,   0);
	SetStorage (3,	 0, 255, 255);
	SetStorage (4,	 0,   0, 255);
	SetStorage (5, 255,   0, 255);

	FOR cell := 6 TO 9 DO
		SetStorage (cell, 255, 255, 255);

	FOR cell := 10 TO 29 DO
		BEGIN
		gray := ((cell - 10) * 255 + 10) DIV 20;
		SetStorage (cell, gray, gray, gray)
		END;

	gPickerWindow := TGhostWindow (NewGhostWindow (kPickerID, SELF));

	NEW (sDoc);
	FailNil (sDoc);

	gScratchDoc := sDoc;

	sDoc.IImageDocument;

	sDoc.fChannels := 3;

	sDoc.fMode := RGBColorMode;

	sDoc.fRows := fScratchRect.bottom - fScratchRect.top;
	sDoc.fCols := fScratchRect.right - fScratchRect.left;

	FOR channel := 0 TO 2 DO
		BEGIN

		aVMArray := NewVMArray (sDoc.fRows, sDoc.fCols, 3 - channel);

		aVMArray.SetBytes (255);

		sDoc.fData [channel] := aVMArray

		END;

	NEW (sView);
	FailNil (sView);

	sView.IScratchView (sDoc);

	fScratchView := sView;

	r := fScratchRect;

	NEW (sFrame);
	FailNil (sFrame);

	sFrame.IFrame (fFrame, fFrame, r, TRUE, TRUE, FALSE, FALSE);

	sFrame.HaveView (sView);

	gApplication.InstallCohandler (sDoc, TRUE);

	gPickerWmgrWindow := gPickerWindow.fWmgrWindow;

	IF gConfiguration.hasColorToolbox THEN
		BEGIN
		ph := GetNewPalette (0);
		SetPalette (gPickerWmgrWindow, ph, TRUE)
		END;

	SetPort (gPickerWmgrWindow);

	TextFont (0);

	location.v := screenBits.bounds.bottom;
	location.h := screenBits.bounds.left;

	LocalToGlobal (location);

	{ Radius large menus bug! }

	IF location.v >= screenBits.bounds.bottom THEN
		location.v := screenBits.bounds.bottom - fExtentRect.bottom - 3;

	MoveWindow (gPickerWmgrWindow, -30000, -30000, FALSE);

	gPickerWindow.Open;

	gPickerWindow.ShowGhost (FALSE);

	MoveWindow (gPickerWmgrWindow, location.h, location.v, FALSE)

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TPickerView.ComputeLevels;

	VAR
		c: INTEGER;
		m: INTEGER;
		y: INTEGER;
		k: INTEGER;
		which: INTEGER;
		color: RGBColor;
		inside: BOOLEAN;
		color2: HSVColor;
		view: TImageView;
		doc: TImageDocument;
		monochrome: BOOLEAN;

	FUNCTION MapPercent (x: INTEGER): INTEGER;

		VAR
			y: INTEGER;

		BEGIN

		x := BAND ($FF, BSR (x, 8));

		y := (x * 100 + 127) DIV 255;

		IF (y = 0) AND (x <> 0) THEN
			MapPercent := 1

		ELSE IF (y = 100) AND (x <> 255) THEN
			MapPercent := 99

		ELSE
			MapPercent := y

		END;

	BEGIN

	IF fBackground THEN
		color := gBackgroundColor
	ELSE
		color := gForegroundColor;

		CASE fColorSpace OF

		1:	BEGIN

			fLevel [0] := BAND ($FF, BSR (color.red  , 8));
			fLevel [1] := BAND ($FF, BSR (color.green, 8));
			fLevel [2] := BAND ($FF, BSR (color.blue , 8));

			FOR which := 0 TO 2 DO
				fOffset [which] := (fLevel [which] * 100 + 127) DIV 255

			END;

		2:	BEGIN

			RGB2HSV (color, color2);

			fLevel [0] := HiWrd (BAND ($0FFFF, color2.hue) * 360 + $08000);

			IF fLevel [0] = 360 THEN
				fLevel [0] := 0;

			fOffset [0] := (ORD4 (fLevel [0]) * 100 + 180) DIV 360;

			fLevel [1] := MapPercent (color2.saturation);
			fLevel [2] := MapPercent (color2.value	   );

			fOffset [1] := fLevel [1];
			fOffset [2] := fLevel [2]

			END;

		3:	BEGIN

			monochrome := FALSE;

			IF MEMBER (gTarget, TImageView) THEN
				BEGIN

				view := TImageView (gTarget);
				doc  := TImageDocument (view.fDocument);

				monochrome := (doc.fMode <> IndexedColorMode) AND
							  (view.fChannel <> kRGBChannels)

				END;

			IF monochrome THEN
				BEGIN

				c := 255;
				m := 255;
				y := 255;

				k := ORD (ConvertToGray (BSR (color.red  , 8),
										 BSR (color.green, 8),
										 BSR (color.blue , 8)))

				END

			ELSE
				SolveForCMYK (BAND ($FF, BSR (color.red  , 8)),
							  BAND ($FF, BSR (color.green, 8)),
							  BAND ($FF, BSR (color.blue , 8)),
							  c, m, y, k, inside);

			fLevel [0] := CvtToPercent (c);
			fLevel [1] := CvtToPercent (m);
			fLevel [2] := CvtToPercent (y);
			fLevel [3] := CvtToPercent (k);

			fOffset [0] := fLevel [0];
			fOffset [1] := fLevel [1];
			fOffset [2] := fLevel [2];
			fOffset [3] := fLevel [3]

			END

		END

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TPickerView.ComputeColor (VAR color: RGBColor);

	VAR
		color2: HSVColor;
		view: TImageView;
		doc: TImageDocument;
		monochrome: BOOLEAN;

	FUNCTION Map255 (x: INTEGER): INTEGER;
		BEGIN
		Map255 := (x * 255 + 50) DIV 100
		END;

	BEGIN

		CASE fColorSpace OF

		1:	BEGIN
			color.red	:= fLevel [0] * $101;
			color.green := fLevel [1] * $101;
			color.blue	:= fLevel [2] * $101
			END;

		2:	BEGIN

			color2.hue := LoWrd ((ORD4 (fLevel [0]) * $10000 + 180) DIV 360);

			color2.saturation := Map255 (fLevel [1]) * $101;
			color2.value	  := Map255 (fLevel [2]) * $101;

			HSV2RGB (color2, color)

			END;

		3:	BEGIN

			monochrome := FALSE;

			IF MEMBER (gTarget, TImageView) THEN
				BEGIN

				view := TImageView (gTarget);
				doc  := TImageDocument (view.fDocument);

				monochrome := (doc.fMode <> IndexedColorMode) AND
							  (view.fChannel <> kRGBChannels)

				END;

			IF monochrome THEN
				BEGIN

				color.red := CvtFromPercent (fLevel [3]);

				color.green := color.red;
				color.blue	:= color.red

				END

			ELSE
				SolveForRGB (CvtFromPercent (fLevel [0]),
							 CvtFromPercent (fLevel [1]),
							 CvtFromPercent (fLevel [2]),
							 CvtFromPercent (fLevel [3]),
							 color.red,
							 color.green,
							 color.blue);

			color.red	:= color.red   * $101;
			color.green := color.green * $101;
			color.blue	:= color.blue  * $101

			END

		END

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TPickerView.DrawColor;

	VAR
		r: Rect;
		color: RGBColor;

	BEGIN

	IF fBackground THEN
		color := gBackgroundColor
	ELSE
		color := gForegroundColor;

	IF (fColorSpace = 3) AND NOT fLevelsLocked THEN
		BEGIN
		ComputeLevels;
		ComputeColor (color)
		END;

	r := fColorRect;

	RectRgn (gPickerRgn, r);

	ColorizedFill (gPickerRgn, color)

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TPickerView.DrawStorage (cell1: INTEGER; cell2: INTEGER);

	VAR
		r: Rect;
		cell: INTEGER;
		depth: INTEGER;
		color: RGBColor;
		maxDevice: GDHandle;
		monochrome: BOOLEAN;
		saveDevice: GDHandle;

	BEGIN

	IF gConfiguration.hasColorToolBox THEN
		BEGIN

		r := fStorageRect;
		LocalToGlobal (r.topLeft);
		LocalToGlobal (r.botRight);

		maxDevice := GetMaxDevice (r);

		GetScreenInfo (maxDevice, depth, monochrome);

		saveDevice := GetGDevice;

		IF (maxDevice <> saveDevice) & (maxDevice <> NIL) THEN
			SetGDevice (maxDevice)

		END

	ELSE
		depth := 1;

	FOR cell := cell1 TO cell2 DO
		BEGIN

		color := fStorage [cell];

		r.left := fStorageRect.left + (cell MOD 10) * 16;
		r.top  := fStorageRect.top	+ (cell DIV 10) * 16;

		r.right  := r.left + 15;
		r.bottom := r.top  + 15;

		RectRgn (gPickerRgn, r);

		DoColorizedFill (gPickerRgn, color, depth)

		END;

	IF gConfiguration.hasColorToolBox & (maxDevice <> saveDevice) THEN
		SetGDevice (saveDevice)

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TPickerView.GetSliderRect (band: INTEGER; VAR r: Rect);

	BEGIN

	SetRect (r, 24, 8, 125, 9);

	IF fColorSpace = 3 THEN
		OffsetRect (r, fLevelsRect.left, fLevelsRect.top + 14 * band)
	ELSE
		OffsetRect (r, fLevelsRect.left, fLevelsRect.top + 18 * band + 3);

	IF fColorSpace = 1 THEN
		OffsetRect (r, 2, 0)

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TPickerView.DrawSliders;

	VAR
		r: Rect;
		c: CHAR;
		s: Str255;
		band: INTEGER;
		bands: INTEGER;

	BEGIN

	PenNormal;

	r := fLevelsRect;

	EraseRect (r);

	IF fColorSpace = 3 THEN
		bands := 4
	ELSE
		bands := 3;

	GetItem (fMenu2, fColorSpace, s);

	FOR band := 0 TO bands - 1 DO
		BEGIN

		GetSliderRect (band, r);

		PaintRect (r);

		c := s [band + 1];

		MoveTo (r.left - CharWidth (c) - 11, r.top + 5);
		DrawChar (c);

		IF (band = 0) AND (fColorSpace = 2) THEN
			c := CHR ($A1)
		ELSE IF fColorSpace = 1 THEN
			c := ' '
		ELSE
			c := '%';

		MoveTo (r.right + 34, r.top + 5);
		DrawChar (c)

		END

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TPickerView.DrawLevel (band: INTEGER);

	VAR
		r: Rect;
		rr: Rect;
		s: Str255;

	BEGIN

	NumToString (fLevel [band], s);

	GetSliderRect (band, r);

	rr.top	  := r.bottom;
	rr.bottom := rr.top  + gWPointer.bounds.bottom;
	rr.left   := r.left  - gPtrWidth;
	rr.right  := r.right + gPtrWidth;

	EraseRect (rr);

	rr.left  := rr.left + fOffset [band];
	rr.right := rr.left + gBPointer.bounds.right;

	CopyBits (gWPointer, thePort^.portBits,
			  gWPointer.bounds, rr, srcOr, NIL);

	rr.right  := r.right   + 32;
	rr.bottom := r.top	   +  5;
	rr.top	  := rr.bottom - 12;
	rr.left   := rr.right  - 24;

	IF fColorSpace = 1 THEN
		OffsetRect (rr, 5, 0);

	MoveTo (rr.right - StringWidth (s), rr.bottom);

	EraseRect (rr);

	DrawString (s)

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TPickerView.DrawLevels;

	VAR
		band: INTEGER;

	BEGIN

	IF NOT fLevelsLocked THEN
		ComputeLevels;

	FOR band := 0 TO 2 + ORD (fColorSpace = 3) DO
		DrawLevel (band)

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TPickerView.UpdateColor;

	BEGIN

	fFrame.Focus;

	fLevelsLocked := FALSE;

	DrawColor;
	DrawLevels

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TPickerView.Draw (area: Rect); OVERRIDE;

	VAR
		r: Rect;
		s: Str255;
		j: INTEGER;

	PROCEDURE FramePopUp (menuRect: Rect);

		BEGIN

		r := menuRect;

		InsetRect (r, -1, -1);
		FrameRect (r);

		MoveTo (r.right, r.top + 3);
		LineTo (r.right, r.bottom);
		LineTo (r.left + 3, r.bottom)

		END;

	BEGIN

	PenNormal;

	r := fStorageRect;

	InsetRect (r, -1, -1);
	FrameRect (r);

	FOR j := 1 TO 2 DO
		BEGIN
		MoveTo (r.left, r.top + 16 * j);
		Line (r.right - r.left - 1, 0)
		END;

	FOR j := 1 TO 9 DO
		BEGIN
		MoveTo (r.left + 16 * j, r.top);
		Line (0, r.bottom - r.top - 1)
		END;

	r := fScratchRect;

	PenSize (2, 2);

	InsetRect (r, -2, -2);
	FrameRect (r);

	PenNormal;

	r := fColorRect;

	InsetRect (r, -1, -1);
	FrameRect (r);

	DrawColor;

	FramePopUp (fMenuRect1);
	FramePopUp (fMenuRect2);

	GetItem (fMenu1, 1 + ORD (fBackground), s);

	EraseRect (fMenuRect1);
	MoveTo (fMenuRect1.left + 6, fMenuRect1.top + 12);
	DrawString (s);

	GetItem (fMenu2, fColorSpace, s);

	EraseRect (fMenuRect2);
	MoveTo (fMenuRect2.left + 6, fMenuRect2.top + 12);
	DrawString (s);

	DrawSliders;
	DrawLevels;

	DrawStorage (0, kStorageCells - 1)

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE UpdateForeground (invalid: BOOLEAN);

	VAR
		r: Rect;

	BEGIN

	IF invalid THEN
		BEGIN

		InvalidateGhostColors;

		IF NOT gPickerView.fBackground THEN
			BEGIN

			gPickerView.fLevelsLocked := FALSE;

			IF PickerVisible THEN
				BEGIN
				r := gPickerView.fLevelsRect;
				gPickerView.fFrame.InvalidRect (r)
				END

			END

		END

	ELSE
		BEGIN

		gToolsView.DrawForeground;

		IF PickerVisible & NOT gPickerView.fBackground THEN
			gPickerView.UpdateColor

		END

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE UpdateBackground (invalid: BOOLEAN);

	VAR
		r: Rect;

	BEGIN

	IF invalid THEN
		BEGIN

		InvalidateGhostColors;

		IF gPickerView.fBackground THEN
			BEGIN

			gPickerView.fLevelsLocked := FALSE;

			IF PickerVisible THEN
				BEGIN
				r := gPickerView.fLevelsRect;
				gPickerView.fFrame.InvalidRect (r)
				END

			END

		END

	ELSE
		BEGIN

		gToolsView.DrawBackground;

		IF PickerVisible & gPickerView.fBackground THEN
			gPickerView.UpdateColor

		END

	END;

{*****************************************************************************}

{$S APicker}

FUNCTION TPickerView.DoMouseCommand
		(VAR downLocalPoint: Point;
		 VAR info: EventInfo;
		 VAR hysteresis: Point): TCommand; OVERRIDE;

	VAR
		r: Rect;
		rr: Rect;
		s: Str255;
		pt: Point;
		spot: Point;
		done: BOOLEAN;
		cell: INTEGER;
		pick: INTEGER;
		band: INTEGER;
		bands: INTEGER;
		result: LONGINT;
		oldOffset: INTEGER;
		newOffset: INTEGER;
		peekEvent: EventRecord;

	BEGIN

	DoMouseCommand := gNoChanges;

	IF PtInRect (downLocalPoint, fColorRect) THEN
		IF fBackground THEN
			DoSetBackground
		ELSE
			DoSetForeground

	ELSE IF PtInRect (downLocalPoint, fMenuRect1) THEN
		BEGIN

		InsertMenu (fMenu1, -1);

		pick := 1 + ORD (fBackground);

		CheckItem (fMenu1, 1, pick = 1);
		CheckItem (fMenu1, 2, pick = 2);

		spot := fMenuRect1.topLeft;

		LocalToGlobal (spot);

		result := PopUpMenuSelect (fMenu1, spot.v, spot.h, pick);

		DeleteMenu (fMenu1^^.menuID);

		IF HiWrd (result) <> 0 THEN
			IF LoWrd (result) <> pick THEN
				BEGIN

				fBackground := NOT fBackground;

				GetItem (fMenu1, 1 + ORD (fBackground), s);

				EraseRect (fMenuRect1);
				MoveTo (fMenuRect1.left + 6, fMenuRect1.top + 12);
				DrawString (s)

				END;

		UpdateColor

		END

	ELSE IF PtInRect (downLocalPoint, fMenuRect2) THEN
		BEGIN

		InsertMenu (fMenu2, -1);

		CheckItem (fMenu2, 1, fColorSpace = 1);
		CheckItem (fMenu2, 2, fColorSpace = 2);
		CheckItem (fMenu2, 3, fColorSpace = 3);

		spot := fMenuRect2.topLeft;

		LocalToGlobal (spot);

		result := PopUpMenuSelect (fMenu2, spot.v, spot.h, fColorSpace);

		DeleteMenu (fMenu2^^.menuID);

		IF HiWrd (result) <> 0 THEN
			IF LoWrd (result) <> fColorSpace THEN
				BEGIN

				fColorSpace := LoWrd (result);

				GetItem (fMenu2, fColorSpace, s);

				EraseRect (fMenuRect2);
				MoveTo (fMenuRect2.left + 6, fMenuRect2.top + 12);
				DrawString (s);

				DrawSliders

				END;

		UpdateColor

		END

	ELSE IF PtInRect (downLocalPoint, fLevelsRect) THEN
		BEGIN

		IF fColorSpace = 3 THEN
			bands := 4
		ELSE
			bands := 3;

		FOR band := 0 TO bands - 1 DO
			BEGIN

			GetSliderRect (band, r);

			rr.top	  := r.bottom;
			rr.bottom := r.bottom + 12;
			rr.left   := r.left   - gPtrWidth;
			rr.right  := r.right  + gPtrWidth;

			oldOffset := fOffset [band];

			IF PtInRect (downLocalPoint, rr) THEN
				REPEAT

				GetMouse (pt);

				done := NOT StillDown;

				IF done THEN
					IF EventAvail (mUpMask, peekEvent) THEN
						BEGIN
						pt := peekEvent.where;
						GlobalToLocal (pt)
						END;

				newOffset := Max (0, Min (pt.h - r.left, 100));

				IF (newOffset <> fOffset [band]) OR NOT fLevelsLocked THEN
					BEGIN

					fLevelsLocked := TRUE;

					fOffset [band] := newOffset;

					IF (fColorSpace = 2) AND (band = 0) THEN
						fLevel [band] := (newOffset * 36 + 5) DIV 10
					ELSE IF fColorSpace = 1 THEN
						fLevel [band] := (newOffset * 255 + 50) DIV 100
					ELSE
						fLevel [band] := newOffset;

					DrawLevel (band);

					IF fBackground THEN
						ComputeColor (gBackgroundColor)
					ELSE
						ComputeColor (gForegroundColor);

					DrawColor;

					IF fBackground THEN
						gToolsView.DrawBackground
					ELSE
						gToolsView.DrawForeground;

					fFrame.Focus

					END

				UNTIL done

			END

		END

	ELSE IF PtInRect (downLocalPoint, fStorageRect) THEN

		IF gUseTool = BucketTool THEN
			BEGIN

			cell := (downLocalPoint.h - fStorageRect.left) DIV 16 +
					(downLocalPoint.v - fStorageRect.top ) DIV 16 * 10;

			IF fBackground THEN
				fStorage [cell] := gBackgroundColor
			ELSE
				fStorage [cell] := gForegroundColor;

			DrawStorage (cell, cell)

			END

		ELSE
			REPEAT

			fFrame.Focus;
			GetMouse (pt);

			done := NOT StillDown;

			IF done THEN
				IF EventAvail (mUpMask, peekEvent) THEN
					BEGIN
					pt := peekEvent.where;
					GlobalToLocal (pt)
					END;

			IF PtInRect (pt, fStorageRect) THEN
				BEGIN

				cell := (pt.h - fStorageRect.left) DIV 16 +
						(pt.v - fStorageRect.top ) DIV 16 * 10;

				IF fBackground THEN
					BEGIN
					gBackgroundColor := fStorage [cell];
					UpdateBackground (FALSE)
					END
				ELSE
					BEGIN
					gForegroundColor := fStorage [cell];
					UpdateForeground (FALSE)
					END

				END

			UNTIL done

	ELSE
		DoMouseCommand := INHERITED DoMouseCommand (downLocalPoint,
													info, hysteresis)

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TrackPickerCursor (mousePt: Point;
							 spaceDown: BOOLEAN;
							 shiftDown: BOOLEAN;
							 optionDown: BOOLEAN;
							 commandDown: BOOLEAN);

	VAR
		pt: Point;
		view: TScratchView;

	BEGIN

	gPickerView.fFrame.Focus;

	pt := mousePt;
	GlobalToLocal (pt);

	IF PtInRect (pt, gPickerView.fStorageRect) THEN
		BEGIN

		IF (gTool = BucketTool) <> optionDown THEN
			gUseTool := BucketTool
		ELSE
			gUseTool := EyedropperTool;

		SetToolCursor (gUseTool, FALSE);

		EXIT (TrackPickerCursor)

		END

	ELSE IF PtInRect (pt, gPickerView.fScratchRect) THEN
		BEGIN

		view := gPickerView.fScratchView;

		IF spaceDown THEN
			IF optionDown THEN
				IF view.fMagnification = view.MinMagnification THEN
					gUseTool := ZoomLimitTool
				ELSE
					gUseTool := ZoomOutTool
			ELSE IF commandDown THEN
				IF view.fMagnification = view.MaxMagnification THEN
					gUseTool := ZoomLimitTool
				ELSE
					gUseTool := ZoomTool
			ELSE
				gUseTool := HandTool

		ELSE
			CASE gTool OF

			MarqueeTool:
				gUseTool := gTool;

			EraserTool,
			PencilTool,
			BrushTool,
			AirbrushTool,
			SmudgeTool,
			BlurTool,
			SharpenTool,
			GradientTool,
			BucketTool,
			HandTool:
				IF optionDown THEN
					gUseTool := EyeDropperTool
				ELSE
					gUseTool := gTool;

			ZoomTool:
				IF optionDown THEN
					IF view.fMagnification = view.MinMagnification THEN
						gUseTool := ZoomLimitTool
					ELSE
						gUseTool := ZoomOutTool
				ELSE
					IF view.fMagnification = view.MaxMagnification THEN
						gUseTool := ZoomLimitTool
					ELSE
						gUseTool := ZoomTool;

			StampTool:
				IF optionDown THEN
					gUseTool := StampPadTool
				ELSE
					gUseTool := StampTool;

			OTHERWISE
				gUseTool := EyedropperTool

			END

		END;

	SetToolCursor (gUseTool, TRUE)

	END;

{*****************************************************************************}

{$S ARes4}

FUNCTION TScratchFrame.AdjustSBars: BOOLEAN; OVERRIDE;

	VAR
		vhs: VHSelect;
		anSBar: ControlHandle;

	BEGIN

	FOR vhs := v TO h DO
		BEGIN

		anSBar := fScrollBars [vhs];

		MoveControl (fScrollBars [vhs], -1000, -1000);

		SetCtlMax (anSBar, CalcSBarMax (vhs))

		END;

	AdjustSBars := TRUE

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE TScratchView.IScratchView (doc: TImageDocument);

	BEGIN

	fLastBand		 := 0;
	fLastSubtractive := FALSE;

	IImageView (doc);

	END;

{*****************************************************************************}

{$S APicker}

FUNCTION TScratchView.DoMouseCommand
		(VAR downLocalPoint: Point;
		 VAR info: EventInfo;
		 VAR hysteresis: Point): TCommand; OVERRIDE;

	VAR
		fi: FailInfo;
		cmd: TCommand;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF error = errNeverSaved THEN
			Failure (errNoScratchPad, message)
		END;

	BEGIN

	cmd := gNoChanges;

	hysteresis.h := 0;
	hysteresis.v := 0;

	CatchFailures (fi, CleanUp);

		CASE gUseTool OF

		MarqueeTool:
			cmd := DoMarqueeTool (SELF, FALSE, FALSE, FALSE);

		HandTool:
			cmd := DoHandTool (SELF);

		ZoomTool:
			cmd := DoZoomTool (SELF, downLocalPoint, FALSE);

		ZoomOutTool:
			cmd := DoZoomTool (SELF, downLocalPoint, TRUE);

		EyedropperTool:
			cmd := DoEyedropperTool (SELF, gPickerView.fBackground);

		BucketTool:
			cmd := DoBucketTool (SELF);

		EraserTool:
			cmd := DoEraserTool (SELF, FALSE);

		PencilTool:
			cmd := DoPencilTool (SELF, downLocalPoint);

		BrushTool:
			cmd := DoBrushTool (SELF);

		AirbrushTool:
			cmd := DoAirbrushTool (SELF);

		BlurTool:
			cmd := DoBlurTool (SELF);

		SharpenTool:
			cmd := DoSharpenTool (SELF);

		SmudgeTool:
			cmd := DoSmudgeTool (SELF, FALSE);

		StampTool:
			cmd := DoStampTool (SELF);

		StampPadTool:
			cmd := DoStampPadTool (SELF, downLocalPoint);

		GradientTool:
			cmd := DoGradientTool (SELF)

		END;

	Success (fi);

	IF cmd <> gNoChanges THEN
		cmd.fChangedDocument := NIL;

	DoMouseCommand := cmd

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TScratchView.GetViewScreenInfo (VAR depth: INTEGER;
										  VAR monochrome: BOOLEAN); OVERRIDE;

	VAR
		view: TImageView;
		doc: TImageDocument;

	BEGIN

	GetScreenInfo (GetScreen, depth, monochrome);

	IF depth >= 8 THEN
		IF MEMBER (gTarget, TImageView) THEN
			BEGIN

			view := TImageView (gTarget);
			doc  := TImageDocument (view.fDocument);

			IF (doc.fMode <> IndexedColorMode) AND
			   (view.fChannel <> kRGBChannels) THEN
				BEGIN
				monochrome := TRUE;
				depth := 8
				END

			END

	END;

{*****************************************************************************}

{$S ARes4}

FUNCTION TScratchView.ColorizeBand
		(VAR band: INTEGER; VAR subtractive: BOOLEAN): BOOLEAN; OVERRIDE;

	VAR
		depth: INTEGER;
		view: TImageView;
		monochrome: BOOLEAN;

	BEGIN

	GetViewScreenInfo (depth, monochrome);

	IF MEMBER (gTarget, TImageView) AND (depth >= 8) THEN
		BEGIN
		view := TImageView (gTarget);
		ColorizeBand := view.ColorizeBand (band, subtractive)
		END

	ELSE
		ColorizeBand := FALSE

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE TScratchView.CheckDither; OVERRIDE;

	VAR
		band: INTEGER;
		depth: INTEGER;
		monochrome: BOOLEAN;
		subtractive: BOOLEAN;

	BEGIN

	GetViewScreenInfo (depth, monochrome);

	IF NOT ColorizeBand (band, subtractive) THEN
		BEGIN
		band		:= 0;
		subtractive := FALSE
		END;

	IF (fTables.fDepth		<> depth	  ) OR
	   (fTables.fMonochrome <> monochrome ) OR
	   (fLastBand			<> band 	  ) OR
	   (fLastSubtractive	<> subtractive) THEN
		ReDither (FALSE);

	fLastBand		 := band;
	fLastSubtractive := subtractive

	END;

{*****************************************************************************}

{$S ARes4}

FUNCTION TScratchView.MinMagnification: INTEGER; OVERRIDE;

	BEGIN
	MinMagnification := 1
	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE InvalidateGhostColors;

	VAR
		r: Rect;

	BEGIN

	gToolsView.InvalidateColors;

	IF PickerVisible THEN
		BEGIN

		InvalidateCMYKPicker;

		r := gPickerView.fColorRect;
		gPickerView.fFrame.InvalidRect (r);

		r := gPickerView.fStorageRect;
		gPickerView.fFrame.InvalidRect (r);

		r := gPickerView.fScratchRect;
		gPickerView.fFrame.InvalidRect (r)

		END

	END;

{*****************************************************************************}

{$S APreferences}

PROCEDURE InvalidateCMYKPicker;

	VAR
		r: Rect;

	BEGIN

	IF gPickerView.fColorSpace = 3 THEN
		BEGIN

		gPickerView.fLevelsLocked := FALSE;

		IF PickerVisible THEN
			BEGIN
			r := gPickerView.fLevelsRect;
			gPickerView.fFrame.InvalidRect (r)
			END

		END

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE ResetGroundColors;

	BEGIN

	gForegroundColor.red   := 0;
	gForegroundColor.green := 0;
	gForegroundColor.blue  := 0;

	UpdateForeground (FALSE);

	gBackgroundColor.red   := $FFFF;
	gBackgroundColor.green := $FFFF;
	gBackgroundColor.blue  := $FFFF;

	UpdateBackground (FALSE)

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.ICubeDialog (color: RGBColor);

	CONST
		kDialogID	= 1015;
		kHookItem	= 35;
		kCrossItem	= 3;
		kCoreItem	= 4;
		kPatchItem	= 5;
		kWarnItem	= 6;
		kRadioItems = 7;
		kCoordItems = 13;

	VAR
		j: INTEGER;
		fi: FailInfo;
		ct: TFixedText;
		limit: INTEGER;
		color2: HSVColor;
		itemType: INTEGER;
		itemHandle: Handle;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Free
		END;

	BEGIN

	RGB2HSV (color, color2);

	fOldColor.rgb := color;
	fOldColor.hsv := color2;

	fCurColor := fOldColor;
	fNewColor := fOldColor;

	fCMYKMode := FALSE;

	fWarning := FALSE;

	fColorTable := NIL;

	fPalette := NIL;

	fBuffer1 := NIL;
	fBuffer2 := NIL;

	IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	{$H-}
	GetDItem (fDialogPtr, kCrossItem, itemType, itemHandle, fCrossRect);
	GetDItem (fDialogPtr, kCoreItem , itemType, itemHandle, fCoreRect );
	GetDItem (fDialogPtr, kPatchItem, itemType, itemHandle, fPatchRect);
	GetDItem (fDialogPtr, kWarnItem , itemType, itemHandle, fWarnRect );
	{$H+}

	IF gConfiguration.hasColorToolbox THEN
		BEGIN

		fColorTable := MakeColorTable (6);

		SetPort (fDialogPtr);

		IF GetDepth >= 8 THEN
			BEGIN

			fPalette := NewPalette (216, fColorTable, pmTolerant, 0);
			FailNil (fPalette);

			SetPalette (fDialogPtr, fPalette, TRUE)

			END

		END;

	fBuffer1 := NewLargeHandle ($0C000);
	fBuffer2 := NewLargeHandle ($40000);

	fCoreCluster := DefineRadioCluster (kRadioItems,
										kRadioItems + 5,
										kRadioItems + gCoreColor);

	FOR j := 0 TO 9 DO
		BEGIN
		IF j = 0 THEN
			limit := 360
		ELSE IF (j >= 3) AND (j <= 5) THEN
			limit := 255
		ELSE
			limit := 100;
		ct := DefineFixedText (kCoordItems + j, 0, FALSE, FALSE, 0, limit);
		fCoords [j] := ct
		END;

	StuffCoords;

	fDirty := FALSE;

	Success (fi)

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.Free; OVERRIDE;

	BEGIN

	IF fColorTable <> NIL THEN
		DisposHandle (Handle (fColorTable));

	IF fPalette <> NIL THEN
		DisposePalette (fPalette);

	FreeLargeHandle (fBuffer1);
	FreeLargeHandle (fBuffer2);

	INHERITED Free

	END;

{*****************************************************************************}

{$S APicker}

FUNCTION TCubeDialog.GetDepth: INTEGER;

	VAR
		r: Rect;
		depth: INTEGER;
		device: GDHandle;
		monochrome: BOOLEAN;

	BEGIN

	IF gConfiguration.hasColorToolbox THEN
		BEGIN

		UnionRect (fCrossRect, fCoreRect, r);
		UnionRect (fPatchRect, r, r);

		LocalToGlobal (r.topLeft);
		LocalToGlobal (r.botRight);

		device := GetMaxDevice (r)

		END

	ELSE
		device := NIL;

	GetScreenInfo (device, depth, monochrome);

	GetDepth := depth

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.DrawRGB (rPtr: Ptr;
							   gPtr: Ptr;
							   bPtr: Ptr;
							   area: Rect;
							   magnification: INTEGER);

	TYPE
		BitPtr = ^BitMap;

	VAR
		r: Rect;
		rows: INTEGER;
		cols: INTEGER;
		gray: INTEGER;
		mode: INTEGER;
		depth: INTEGER;
		count: LONGINT;
		aPixMap: PixMap;
		grayGap: INTEGER;
		rowBytes: INTEGER;
		ditherSize: INTEGER;
		table1: TThresTable;
		table2: TThresTable;
		table3: TThresTable;
		noiseTable: TNoiseTable;

	BEGIN

	depth := GetDepth;

	IF depth < 8 THEN
		depth := 1
	ELSE IF depth > 8 THEN
		depth := 32;

	r := area;
	OffsetRect (r, -r.left, -r.top);

	IF magnification = 0 THEN
		magnification := Max (r.right, r.bottom);

	cols := Max (1, r.right  DIV magnification);
	rows := Max (1, r.bottom DIV magnification);

	HLock (fBuffer2);

		CASE depth OF

		1:	BEGIN

			rowBytes := BSL (BSR (r.right + 15, 4), 1);

			DoMakeMonochrome (rPtr, gGrayLUT.R,
							  gPtr, gGrayLUT.G,
							  bPtr, gGrayLUT.B,
							  rPtr, ORD4 (cols) * rows);

			CompThresTable (2, grayGap, table1);

			CompNoiseTable (1, grayGap, ditherSize, noiseTable);

			DoDither (rPtr, cols, fBuffer2^, rowBytes,
					  1, r, magnification, ditherSize, gNullLUT,
					  noiseTable, table1, TRUE)

			END;

		8:	BEGIN

			rowBytes := BAND ($7FFE, r.right + 1);

			CompThresTable (6, grayGap, table1);

			FOR gray := 0 TO 510 DO
				BEGIN
				table2 [gray] := CHR (ORD (table1 [gray]) * 6);
				table3 [gray] := CHR (ORD (table2 [gray]) * 6)
				END;

			CompNoiseTable (1, grayGap, ditherSize, noiseTable);

			DoDither (rPtr, cols, fBuffer2^, rowBytes, 8, r, magnification,
					  ditherSize, gNullLUT, noiseTable, table1, TRUE);

			DoDither (gPtr, cols, fBuffer2^, rowBytes, 8, r, magnification,
					  ditherSize, gNullLUT, noiseTable, table2, FALSE);

			DoDither (bPtr, cols, fBuffer2^, rowBytes, 8, r, magnification,
					  ditherSize, gNullLUT, noiseTable, table3, FALSE)

			END;

		32: BEGIN

			rowBytes := BSL (r.right, 2);

			DoSetBytes (fBuffer2^, rowBytes * ORD4 (r.bottom - r.top), 0);

			DoDither24 (rPtr, cols,
						Ptr (ORD4 (fBuffer2^) + 1), rowBytes,
						4, r, magnification, gNullLUT);

			DoDither24 (gPtr, cols,
						Ptr (ORD4 (fBuffer2^) + 2), rowBytes,
						4, r, magnification, gNullLUT);

			DoDither24 (bPtr, cols,
						Ptr (ORD4 (fBuffer2^) + 3), rowBytes,
						4, r, magnification, gNullLUT)

			END

		END;

	IF depth = 1 THEN
		aPixMap.rowBytes := rowBytes
	ELSE
		aPixMap.rowBytes := BOR ($8000, rowBytes);

	aPixMap.bounds	   := area;
	aPixMap.baseAddr   := fBuffer2^;
	aPixMap.pmVersion  := 0;
	aPixMap.packType   := 0;
	aPixMap.packSize   := 0;
	aPixMap.hRes	   := $480000;
	aPixMap.vRes	   := $480000;
	aPixMap.planeBytes := 0;
	aPixMap.pmReserved := 0;

	IF depth = 32 THEN
		BEGIN
		aPixMap.pixelType := RGBDirect;
		aPixMap.pixelSize := 32;
		aPixMap.cmpCount  := 3;
		aPixMap.cmpSize   := 8
		END
	ELSE
		BEGIN
		aPixMap.pixelType := 0;
		aPixMap.pixelSize := depth;
		aPixMap.cmpCount  := 1;
		aPixMap.cmpSize   := depth
		END;

	IF depth = 8 THEN
		aPixMap.pmTable := fColorTable
	ELSE
		aPixMap.pmTable := NIL;

	IF depth = 32 THEN
		mode := ditherCopy
	ELSE
		mode := srcCopy;

	CopyBits (BitPtr (@aPixMap)^, thePort^.portBits,
			  area, area, mode, NIL);

	HUnlock (fBuffer2)

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.DrawPatch (which: BOOLEAN);

	VAR
		r: Rect;
		c: INTEGER;
		m: INTEGER;
		y: INTEGER;
		k: INTEGER;
		color: RGBColor;
		inside: BOOLEAN;
		middle: INTEGER;

	BEGIN

	r := fPatchRect;

	middle := (r.top + r.bottom) DIV 2;

	IF which THEN
		BEGIN
		color := fNewColor.rgb;
		r.bottom := middle
		END
	ELSE
		BEGIN
		color := fOldColor.rgb;
		r.top := middle
		END;

	DrawRGB (@color.red, @color.green, @color.blue, r, 0);

	IF which THEN
		BEGIN

		color := fNewColor.rgb;

		SolveForCMYK (BAND ($FF, BSR (color.red, 8)),
					  BAND ($FF, BSR (color.green, 8)),
					  BAND ($FF, BSR (color.blue, 8)),
					  c, m, y, k, inside);

		r := fWarnRect;

		fWarning := NOT inside AND NOT fCMYKMode;

		IF fWarning THEN
			CopyBits (gWarnIcon,
					  thePort^.portBits,
					  gWarnIcon.bounds,
					  r,
					  srcOr,
					  NIL)
		ELSE
			EraseRect (r)

		END

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.DecodeCoords (color: DualColor;
									VAR hsb: BOOLEAN;
									VAR a1, a2, a3: INTEGER;
									VAR c1, c2, c3: INTEGER);

	VAR
		which: INTEGER;

	BEGIN

	which := fCoreCluster.fChosenItem - fCoreCluster.fFirstItem;

	hsb := which < 3;

		CASE which OF

		0:	BEGIN
			a1 := 2;
			a2 := 3;
			a3 := 1;
			c1 := color.hsv.saturation;
			c2 := color.hsv.value;
			c3 := color.hsv.hue
			END;

		1:	BEGIN
			a1 := 1;
			a2 := 3;
			a3 := 2;
			c1 := color.hsv.hue;
			c2 := color.hsv.value;
			c3 := color.hsv.saturation
			END;

		2:	BEGIN
			a1 := 1;
			a2 := 2;
			a3 := 3;
			c1 := color.hsv.hue;
			c2 := color.hsv.saturation;
			c3 := color.hsv.value
			END;

		3:	BEGIN
			a1 := 3;
			a2 := 2;
			a3 := 1;
			c1 := color.rgb.blue;
			c2 := color.rgb.green;
			c3 := color.rgb.red
			END;

		4:	BEGIN
			a1 := 3;
			a2 := 1;
			a3 := 2;
			c1 := color.rgb.blue;
			c2 := color.rgb.red;
			c3 := color.rgb.green
			END;

		5:	BEGIN
			a1 := 1;
			a2 := 2;
			a3 := 3;
			c1 := color.rgb.red;
			c2 := color.rgb.green;
			c3 := color.rgb.blue
			END

		END;

	c1 := BAND ($FF, BSR (c1, 8));
	c2 := BAND ($FF, BSR (c2, 8));
	c3 := BAND ($FF, BSR (c3, 8))

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.DrawCircle (c1, c2: INTEGER; turnOn: BOOLEAN);

	VAR
		r: Rect;
		rr: Rect;
		saveClip: RgnHandle;

	BEGIN

	SetRect (r, -5, -5, 6, 6);

	rr := fCrossRect;

	OffsetRect (r, rr.left + c1, rr.bottom - 1 - c2);

	IF turnOn THEN
		BEGIN

		PenNormal;

		IF ORD (ConvertToGray (BSR (fCurColor.rgb.red, 8),
							   BSR (fCurColor.rgb.green, 8),
							   BSR (fCurColor.rgb.blue, 8))) < 128 THEN
			PenPat (white);

		saveClip := NewRgn;

		GetClip (saveClip);

		ClipRect (rr);

		FrameOval (r);

		SetClip (saveClip);

		DisposeRgn (saveClip);

		PenNormal

		END

	ELSE
		IF SectRect (rr, r, r) THEN
			DrawCross (r)

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.DrawCross (area: Rect);

	VAR
		p: Ptr;
		pp: Ptr;
		r: Rect;
		rr: Rect;
		rPtr: Ptr;
		gPtr: Ptr;
		bPtr: Ptr;
		a1: INTEGER;
		a2: INTEGER;
		a3: INTEGER;
		c1: INTEGER;
		c2: INTEGER;
		c3: INTEGER;
		row: INTEGER;
		hsb: BOOLEAN;
		width: INTEGER;
		whole: BOOLEAN;
		temp: PACKED ARRAY [0..127] OF CHAR;

	BEGIN

	whole := EqualRect (area, fCrossRect);

	IF whole THEN MoveHands (FALSE);

	r := area;

	OffsetRect (r, -fCrossRect.left, -fCrossRect.top);

	r.top	 := BAND ($7FF8, r.top		 );
	r.left	 := BAND ($7FF8, r.left 	 );
	r.bottom := BAND ($7FF8, r.bottom + 7);
	r.right  := BAND ($7FF8, r.right  + 7);

	rr := r;

	OffsetRect (rr, fCrossRect.left, fCrossRect.top);

	r.top	 := r.top	 DIV 2;
	r.left	 := r.left	 DIV 2;
	r.bottom := r.bottom DIV 2;
	r.right  := r.right  DIV 2;

	width := r.right - r.left;

	DecodeCoords (fCurColor, hsb, a1, a2, a3, c1, c2, c3);

	HLock (fBuffer1);

	p := Ptr (ORD4 (fBuffer1^) + $4000 * ORD4 (a1 - 1));

	DoStepCopyBytes (@gNullLUT, @temp, 128, 2, 1);

	pp := Ptr (ORD4 (@temp) + r.left);

	FOR row := r.top TO r.bottom - 1 DO
		BEGIN
		BlockMove (pp, p, width);
		p := Ptr (ORD4 (p) + width)
		END;

	p := Ptr (ORD4 (fBuffer1^) + $4000 * ORD4 (a2 - 1));

	FOR row := r.top TO r.bottom - 1 DO
		BEGIN
		DoSetBytes (p, width, 254 - row * 2);
		p := Ptr (ORD4 (p) + width)
		END;

	p := Ptr (ORD4 (fBuffer1^) + $4000 * ORD4 (a3 - 1));

	DoSetBytes (p, width * ORD4 (r.bottom - r.top), c3);

	rPtr := fBuffer1^;
	gPtr := Ptr (ORD4 (rPtr) + $4000);
	bPtr := Ptr (ORD4 (gPtr) + $4000);

	IF hsb THEN
		DoHSLorB2RGB (rPtr, gPtr, bPtr,
					  rPtr, gPtr, bPtr,
					  width * ORD4 (r.bottom - r.top), TRUE);

	DrawRGB (rPtr, gPtr, bPtr, rr, 2);

	HUnlock (fBuffer1);

	IF whole THEN
		DrawCircle (c1, c2, TRUE);

	gMovingHands := FALSE

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.DrawLevel (c3: INTEGER);

	VAR
		r: Rect;

	BEGIN

	PenNormal;

	r := fCoreRect;

	r.top	 := r.top	 - 5;
	r.bottom := r.bottom + 5;

	r.right := r.left  - 1;
	r.left	:= r.right - 6;

	EraseRect (r);

	MoveTo (r.left, r.bottom - c3 - 1);

	Line ( 0, -10);
	Line ( 5,	5);
	Line (-5,	5);

	r.left	:= fCoreRect.right + 1;
	r.right := r.left + 6;

	EraseRect (r);

	MoveTo (r.right - 1, r.bottom - c3 - 1);

	Line ( 0, -10);
	Line (-5,	5);
	Line ( 5,	5)

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.DrawCore (level: BOOLEAN);

	VAR
		p: Ptr;
		r: Rect;
		rPtr: Ptr;
		gPtr: Ptr;
		bPtr: Ptr;
		a1: INTEGER;
		a2: INTEGER;
		a3: INTEGER;
		c1: INTEGER;
		c2: INTEGER;
		c3: INTEGER;
		row: INTEGER;
		hsb: BOOLEAN;
		width: INTEGER;
		LUT: TRGBLookUpTable;

	BEGIN

	DecodeCoords (fCurColor, hsb, a1, a2, a3, c1, c2, c3);

	IF level THEN
		DrawLevel (c3);

	p := Ptr (ORD4 (@LUT) + 256 * (a1 - 1));

	DoSetBytes (p, 256, c1);

	p := Ptr (ORD4 (@LUT) + 256 * (a2 - 1));

	DoSetBytes (p, 256, c2);

	p := Ptr (ORD4 (@LUT) + 256 * (a3 - 1));

	BlockMove (@gInvertLUT, p, 256);

	IF hsb THEN
		DoHSLorB2RGB (@LUT.R, @LUT.G, @LUT.B,
					  @LUT.R, @LUT.G, @LUT.B,
					  256, TRUE);

	r := fCoreRect;

	width := r.right - r.left;

	HLock (fBuffer1);

	rPtr := fBuffer1^;
	gPtr := Ptr (ORD4 (rPtr) + width * 256);
	bPtr := Ptr (ORD4 (gPtr) + width * 256);

	FOR row := 0 TO 255 DO
		BEGIN

		DoSetBytes (Ptr (ORD4 (rPtr) + width * row),
					width,
					ORD (LUT.R [row]));

		DoSetBytes (Ptr (ORD4 (gPtr) + width * row),
					width,
					ORD (LUT.G [row]));

		DoSetBytes (Ptr (ORD4 (bPtr) + width * row),
					width,
					ORD (LUT.B [row]))

		END;

	DrawRGB (rPtr, gPtr, bPtr, r, 1);

	HUnlock (fBuffer1)

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

	VAR
		r: Rect;

	BEGIN

	INHERITED DrawAmendments (theItem);

	PenNormal;

	r := fCrossRect;

	InsetRect (r, -1, -1);
	FrameRect (r);

	r := fCoreRect;

	InsetRect (r, -1, -1);
	FrameRect (r);

	r := fPatchRect;

	InsetRect (r, -1, -1);
	FrameRect (r);

	DrawPatch (FALSE);
	DrawPatch (TRUE);

	DrawCore (TRUE);

	r := fCrossRect;

	DrawCross (r)

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.CoreChanged;

	VAR
		r: Rect;

	BEGIN

	IF fDirty THEN
		BEGIN
		fCurColor := fNewColor;
		fDirty	  := FALSE
		END;

	r := fCrossRect;
	DrawCross (r);

	DrawCore (TRUE)

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.StuffCoordsHSB;

	VAR
		x: INTEGER;
		index: INTEGER;
		percent: INTEGER;

	BEGIN

	x := HiWrd (BAND ($0FFFF, fNewColor.hsv.hue) * 360 + $08000);

	IF x = 360 THEN x := 0;

	fCoords [0] . StuffValue (x);

	FOR index := 1 TO 2 DO
		BEGIN

			CASE index OF
			1:	x := fNewColor.hsv.saturation;
			2:	x := fNewColor.hsv.value
			END;

		x := BAND ($FF, BSR (x, 8));

		percent := (x * 100 + 127) DIV 255;

		IF (x > 0) AND (percent = 0) THEN
			percent := 1;

		IF (x < 255) AND (percent = 100) THEN
			percent := 99;

		fCoords [index] . StuffValue (percent)

		END

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.StuffCoordsRGB;

	VAR
		x: INTEGER;
		index: INTEGER;

	BEGIN

	FOR index := 0 TO 2 DO
		BEGIN

			CASE index OF
			0:	x := fNewColor.rgb.red;
			1:	x := fNewColor.rgb.green;
			2:	x := fNewColor.rgb.blue
			END;

		fCoords [3 + index] . StuffValue (BAND ($FF, BSR (x, 8)))

		END

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.StuffCoordsCMYK;

	VAR
		c: INTEGER;
		m: INTEGER;
		y: INTEGER;
		k: INTEGER;
		index: INTEGER;
		inside: BOOLEAN;
		percent: INTEGER;

	BEGIN

	SolveForCMYK (BAND ($FF, BSR (fNewColor.rgb.red  , 8)),
				  BAND ($FF, BSR (fNewColor.rgb.green, 8)),
				  BAND ($FF, BSR (fNewColor.rgb.blue , 8)),
				  c, m, y, k, inside);

	fCoords [6] . StuffValue (CvtToPercent (c));
	fCoords [7] . StuffValue (CvtToPercent (m));
	fCoords [8] . StuffValue (CvtToPercent (y));
	fCoords [9] . StuffValue (CvtToPercent (k))

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.StuffCoords;

	VAR
		te: TEHandle;
		select: BOOLEAN;

	BEGIN

	StuffCoordsHSB;

	StuffCoordsRGB;

	StuffCoordsCMYK;

	select := TRUE;

	IF fKeyHandler = fCoords [6] THEN
		WITH DialogPeek (fDialogPtr) ^.textH^^ DO
			select := (selStart <> 0) OR (selEnd <> teLength);

	IF select THEN
		SetEditSelection (fCoords [6] . fItemNumber);

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.UpdateNewColor (c1, c2, c3: INTEGER);

	VAR
		which: INTEGER;
		color: DualColor;

	PROCEDURE SetBand (x: INTEGER; VAR y: INTEGER);
		BEGIN
		IF x <> -1 THEN y := x * $101;
		END;

	BEGIN

	color := fNewColor;

	which := fCoreCluster.fChosenItem - fCoreCluster.fFirstItem;

		CASE which OF

		0:	BEGIN
			SetBand (c1, color.hsv.saturation);
			SetBand (c2, color.hsv.value);
			SetBand (c3, color.hsv.hue)
			END;

		1:	BEGIN
			SetBand (c1, color.hsv.hue);
			SetBand (c2, color.hsv.value);
			SetBand (c3, color.hsv.saturation)
			END;

		2:	BEGIN
			SetBand (c1, color.hsv.hue);
			SetBand (c2, color.hsv.saturation);
			SetBand (c3, color.hsv.value)
			END;

		3:	BEGIN
			SetBand (c1, color.rgb.blue);
			SetBand (c2, color.rgb.green);
			SetBand (c3, color.rgb.red)
			END;

		4:	BEGIN
			SetBand (c1, color.rgb.blue);
			SetBand (c2, color.rgb.red);
			SetBand (c3, color.rgb.green)
			END;

		5:	BEGIN
			SetBand (c1, color.rgb.red);
			SetBand (c2, color.rgb.green);
			SetBand (c3, color.rgb.blue)
			END

		END;

	IF which < 3 THEN
		HSV2RGB (color.hsv, color.rgb)
	ELSE
		RGB2HSV (color.rgb, color.hsv);

	fNewColor := color;
	fCMYKMode := FALSE;

	DrawPatch (TRUE);

	StuffCoords

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.TrackLevel;

	VAR
		r: Rect;
		pt: Point;
		a1: INTEGER;
		a2: INTEGER;
		a3: INTEGER;
		c1: INTEGER;
		c2: INTEGER;
		c3: INTEGER;
		hsb: BOOLEAN;
		done: BOOLEAN;
		oldLevel: INTEGER;
		newLevel: INTEGER;
		peekEvent: EventRecord;

	BEGIN

	IF fDirty THEN ClearDirty;

	DecodeCoords (fCurColor, hsb, a1, a2, a3, c1, c2, c3);

	oldLevel := c3;

		REPEAT

		GetMouse (pt);

		done := NOT StillDown;

		IF done THEN
			IF EventAvail (mUpMask, peekEvent) THEN
				BEGIN
				pt := peekEvent.where;
				GlobalToLocal (pt)
				END;

		newLevel := Min (255, Max (0, fCoreRect.bottom - 1 - pt.v));

		IF newLevel <> oldLevel THEN
			BEGIN
			oldLevel := newLevel;
			DrawLevel (newLevel);
			UpdateNewColor (-1, -1, newLevel)
			END

		UNTIL done;

	fCurColor := fNewColor;

	IF newLevel <> c3 THEN
		BEGIN
		r := fCrossRect;
		DrawCross (r)
		END

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.TrackCircle;

	VAR
		r: Rect;
		pt: Point;
		a1: INTEGER;
		a2: INTEGER;
		a3: INTEGER;
		c1: INTEGER;
		c2: INTEGER;
		c3: INTEGER;
		hsb: BOOLEAN;
		done: BOOLEAN;
		new1: INTEGER;
		new2: INTEGER;
		peekEvent: EventRecord;

	BEGIN

	IF fDirty THEN ClearDirty;

	DecodeCoords (fCurColor, hsb, a1, a2, a3, c1, c2, c3);

		REPEAT

		GetMouse (pt);

		done := NOT StillDown;

		IF done THEN
			IF EventAvail (mUpMask, peekEvent) THEN
				BEGIN
				pt := peekEvent.where;
				GlobalToLocal (pt)
				END;

		new1 := Min (255, Max (0, pt.h - fCrossRect.left));
		new2 := Min (255, Max (0, fCrossRect.bottom - 1 - pt.v));

		IF (new1 <> c1) OR (new2 <> c2) THEN
			BEGIN

			DrawCircle (c1, c2, FALSE);
			DrawCircle (new1, new2, TRUE);

			c1 := new1;
			c2 := new2;

			UpdateNewColor (c1, c2, -1);

			fCurColor := fNewColor;

			DrawCore (FALSE)

			END

		UNTIL done

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.DoFilterEvent
		(VAR anEvent: EventRecord;
		 VAR itemHit: INTEGER;
		 VAR handledIt: BOOLEAN;
		 VAR doReturn: BOOLEAN); OVERRIDE;

	VAR
		r: Rect;
		pt: Point;
		part: INTEGER;
		ignore: TCommand;
		whichWindow: WindowPtr;

	BEGIN

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

	IF (anEvent.what = nullEvent) AND fDirty THEN
		IF TickCount > fDirtyTime + 60 THEN
			ClearDirty;

	IF anEvent.what = mouseDown THEN
		BEGIN

		part := FindWindow (anEvent.where, whichWindow);

		IF (whichWindow = fDialogPtr) AND (part = inDrag) THEN
			BEGIN
			DragWindow (whichWindow, anEvent.where, screenBits.bounds);
			anEvent.what := nullEvent
			END;

		IF (whichWindow = fDialogPtr) AND (part = inContent) THEN
			BEGIN

			pt := anEvent.where;
			GlobalToLocal (pt);

			r := fCoreRect;
			InsetRect (r, -7, -7);

			IF PtInRect (pt, r) THEN
				BEGIN
				TrackLevel;
				anEvent.what := nullEvent
				END;

			r := fCrossRect;
			InsetRect (r, -2, -2);

			IF PtInRect (pt, r) THEN
				BEGIN
				TrackCircle;
				anEvent.what := nullEvent
				END

			END

		END;

	INHERITED DoFilterEvent (anEvent, itemHit, handledIt, doReturn)

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.ClearDirty;

	VAR
		r: Rect;
		a1: INTEGER;
		a2: INTEGER;
		a3: INTEGER;
		c1: INTEGER;
		c2: INTEGER;
		c3: INTEGER;
		n1: INTEGER;
		n2: INTEGER;
		n3: INTEGER;
		hsb: BOOLEAN;

	BEGIN

	fDirty := FALSE;

	DecodeCoords (fCurColor, hsb, a1, a2, a3, c1, c2, c3);
	DecodeCoords (fNewColor, hsb, a1, a2, a3, n1, n2, n3);

	IF ((n1 <> c1) OR (n2 <> c2)) AND (n3 = c3) THEN
		DrawCircle (c1, c2, FALSE);

	fCurColor := fNewColor;

	IF n3 <> c3 THEN
		BEGIN
		r := fCrossRect;
		DrawCross (r)
		END

	ELSE IF (n1 <> c1) OR (n2 <> c2) THEN
		DrawCircle (n1, n2, TRUE);

	IF (n1 <> c1) OR (n2 <> c2) THEN
		DrawCore (TRUE)

	ELSE IF n3 <> c3 THEN
		DrawLevel (n3);

	SetCursor (arrow)

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.TypedHSB;

	VAR
		x: INTEGER;
		y: INTEGER;
		z: INTEGER;
		color: DualColor;

	BEGIN

	IF fCoords [0] . ParseValue AND
	   fCoords [1] . ParseValue AND
	   fCoords [2] . ParseValue THEN
		BEGIN

		x := fCoords [0] . fValue;
		y := fCoords [1] . fValue;
		z := fCoords [2] . fValue;

		color.hsv.hue		 := (x * $10000 + 180) DIV 360;
		color.hsv.saturation := (y * $0FFFF +  50) DIV 100;
		color.hsv.value 	 := (z * $0FFFF +  50) DIV 100;

		HSV2RGB (color.hsv, color.rgb);

		fNewColor := color;
		fCMYKMode := FALSE;

		DrawPatch (TRUE);

		StuffCoordsRGB;
		StuffCoordsCMYK;

		fDirty	   := TRUE;
		fDirtyTime := TickCount

		END

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.TypedRGB;

	VAR
		color: DualColor;

	BEGIN

	IF fCoords [3] . ParseValue AND
	   fCoords [4] . ParseValue AND
	   fCoords [5] . ParseValue THEN
		BEGIN

		color.rgb.red	:= fCoords [3] . fValue * $101;
		color.rgb.green := fCoords [4] . fValue * $101;
		color.rgb.blue	:= fCoords [5] . fValue * $101;

		RGB2HSV (color.rgb, color.hsv);

		fNewColor := color;
		fCMYKMode := FALSE;

		DrawPatch (TRUE);

		StuffCoordsHSB;
		StuffCoordsCMYK;

		fDirty	   := TRUE;
		fDirtyTime := TickCount

		END

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TCubeDialog.TypedCMYK;

	VAR
		c: INTEGER;
		m: INTEGER;
		y: INTEGER;
		k: INTEGER;
		r: INTEGER;
		g: INTEGER;
		b: INTEGER;
		color: DualColor;

	BEGIN

	IF fCoords [6] . ParseValue AND
	   fCoords [7] . ParseValue AND
	   fCoords [8] . ParseValue AND
	   fCoords [9] . ParseValue THEN
		BEGIN

		c := CvtFromPercent (fCoords [6] . fValue);
		m := CvtFromPercent (fCoords [7] . fValue);
		y := CvtFromPercent (fCoords [8] . fValue);
		k := CvtFromPercent (fCoords [9] . fValue);

		SolveForRGB (c, m, y, k, r, g, b);

		color.rgb.red	:= r * $101;
		color.rgb.green := g * $101;
		color.rgb.blue	:= b * $101;

		RGB2HSV (color.rgb, color.hsv);

		fNewColor := color;
		fCMYKMode := TRUE;

		DrawPatch (TRUE);

		StuffCoordsHSB;
		StuffCoordsRGB;

		fDirty	   := TRUE;
		fDirtyTime := TickCount

		END

	END;

{*****************************************************************************}

{$S APicker}

FUNCTION DoCubePicker (prompt: Str255; VAR color: RGBColor): BOOLEAN;

	CONST
		kWarnItem = 6;

	VAR
		fi: FailInfo;
		item: INTEGER;
		freeDialog: BOOLEAN;
		saveView: TDialogView;
		aCubeDialog: TCubeDialog;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF freeDialog THEN
			aCubeDialog.Free;
		IF error <> 0 THEN
			BEGIN
			gAllowCube := FALSE;
			gApplication.ShowError (error, msgCannotUsePicker)
			END;
		gDialogView := saveView;
		EXIT (DoCubePicker)
		END;

	PROCEDURE MyItemHandling (anItem: INTEGER; VAR done: BOOLEAN);

		VAR
			oldCore: INTEGER;

		BEGIN

		oldCore := aCubeDialog.fCoreCluster.fChosenItem;

		StdItemHandling (anItem, done);

		IF oldCore <> aCubeDialog.fCoreCluster.fChosenItem THEN
			aCubeDialog.CoreChanged;

		IF (anItem >= aCubeDialog.fCoords [0] . fItemNumber) AND
		   (anItem <= aCubeDialog.fCoords [2] . fItemNumber) THEN
			aCubeDialog.TypedHSB;

		IF (anItem >= aCubeDialog.fCoords [3] . fItemNumber) AND
		   (anItem <= aCubeDialog.fCoords [5] . fItemNumber) THEN
			aCubeDialog.TypedRGB;

		IF (anItem >= aCubeDialog.fCoords [6] . fItemNumber) AND
		   (anItem <= aCubeDialog.fCoords [9] . fItemNumber) THEN
			aCubeDialog.TypedCMYK;

		IF (anItem = kWarnItem) AND (aCubeDialog.fWarning) THEN
			BEGIN
			aCubeDialog.TypedCMYK;
			IF aCubeDialog.fDirty THEN
				aCubeDialog.ClearDirty
			END

		END;

	BEGIN

	DoCubePicker := FALSE;

	freeDialog := FALSE;

	saveView := gDialogView;

	CatchFailures (fi, CleanUp);

	ParamText (prompt, '', '', '');

	NEW (aCubeDialog);
	FailNil (aCubeDialog);

	aCubeDialog.ICubeDialog (color);

	freeDialog := TRUE;

	IF LONGINT (gCubeLocation) <> 0 THEN
		MoveWindow (aCubeDialog.fDialogPtr, gCubeLocation.h,
											gCubeLocation.v, FALSE);

	aCubeDialog.TalkToUser (item, MyItemHandling);

	SetPort (aCubeDialog.fDialogPtr);

	gCubeLocation := Point (0);
	LocalToGlobal (gCubeLocation);

	IF item <> ok THEN Failure (0, 0);

	gCoreColor := aCubeDialog.fCoreCluster.fChosenItem -
				  aCubeDialog.fCoreCluster.fFirstItem;

	color := aCubeDialog.fNewColor.rgb;

	aCubeDialog.Free;

	gDialogView := saveView;

	Success (fi);

	DoCubePicker := TRUE

	END;

{*****************************************************************************}

{$S APicker}

FUNCTION DoSetColor (cube: BOOLEAN;
					 index: INTEGER;
					 VAR color: RGBColor): BOOLEAN;

	VAR
		where: Point;
		prompt: Str255;
		inColor: RGBColor;

	BEGIN

	GetIndString (prompt, kStringsID, index);

	{$IFC qBarneyscan}
	gAllowCube := FALSE;
	{$ENDC}

	IF cube AND gAllowCube THEN
		DoSetColor := DoCubePicker (prompt, color)

	ELSE
		BEGIN

		where.h := 0;
		where.v := 0;

		inColor := color;

		DoSetColor := GetColor (where, prompt, inColor, color)

		END

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE DoSetForeground;

	VAR
		color: RGBColor;

	BEGIN

	color := gForegroundColor;

	IF DoSetColor (NOT gEventInfo.theOptionKey,
				   strSelectForegroundColor,
				   color) THEN
		BEGIN
		gForegroundColor := color;
		UpdateForeground (TRUE)
		END

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE DoSetBackground;

	VAR
		color: RGBColor;

	BEGIN

	color := gBackgroundColor;

	IF DoSetColor (NOT gEventInfo.theOptionKey,
				   strSelectBackgroundColor,
				   color) THEN
		BEGIN
		gBackgroundColor := color;
		UpdateBackground (TRUE)
		END

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TEyedropperTool.IEyedropperTool (view: TImageView;
										   background: BOOLEAN);

	BEGIN

	fView := view;

	fBackground := background;

	ICommand (cMouseCommand);

	fViewConstrain := FALSE

	END;

{*****************************************************************************}

{$S APicker}

PROCEDURE TEyedropperTool.TrackFeedBack
		(anchorPoint, nextPoint: Point;
		 turnItOn, mouseDidMove: BOOLEAN); OVERRIDE;

	BEGIN
	END;

{*****************************************************************************}

{$S APicker}

FUNCTION TEyedropperTool.TrackMouse
		(aTrackPhase: TrackPhase;
		 VAR anchorPoint, previousPoint, nextPoint: Point;
		 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

	VAR
		vr: Rect;
		r: INTEGER;
		g: INTEGER;
		b: INTEGER;
		color: RGBColor;
		oldColor: RGBColor;

	BEGIN

	fView.TrackRulers;

	IF aTrackPhase = trackRelease THEN
		TrackMouse := gNoChanges
	ELSE
		TrackMouse := SELF;

	fView.fFrame.GetViewedRect (vr);

	IF PtInRect (nextPoint, vr) THEN
		BEGIN

		fView.GetViewColor (nextPoint, r, g, b);

		IF gAdjustCommand <> NIL THEN
			gAdjustCommand.MapRGB (Ptr (ORD4 (@r) + 1),
								   Ptr (ORD4 (@g) + 1),
								   Ptr (ORD4 (@b) + 1),
								   1);

		color.red	:= BSL (r, 8) + r;
		color.green := BSL (g, 8) + g;
		color.blue	:= BSL (b, 8) + b;

		IF fBackground THEN
			oldColor := gBackgroundColor
		ELSE
			oldColor := gForegroundColor;

		IF (color.red	<> oldColor.red  ) OR
		   (color.green <> oldColor.green) OR
		   (color.blue	<> oldColor.blue ) THEN
			BEGIN

			IF fBackground THEN
				BEGIN
				gBackgroundColor := color;
				UpdateBackground (FALSE)
				END
			ELSE
				BEGIN
				gForegroundColor := color;
				UpdateForeground (FALSE)
				END;

			fView.fFrame.Focus

			END

		END

	END;

{*****************************************************************************}

{$S APicker}

FUNCTION DoEyedropperTool (view: TImageView;
						   background: BOOLEAN): TCommand;

	VAR
		anEyedropperTool: TEyedropperTool;

	BEGIN

	NEW (anEyedropperTool);
	FailNil (anEyedropperTool);

	anEyedropperTool.IEyedropperTool (view, background);

	DoEyedropperTool := anEyedropperTool

	END;

{*****************************************************************************}

END.

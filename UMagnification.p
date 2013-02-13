{Photoshop version 1.0.1, file: UMagnification.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UMagnification;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UBWDialog, UCommands;

FUNCTION DoZoomInCommand (view: TImageView): TCommand;

FUNCTION DoZoomOutCommand (view: TImageView): TCommand;

FUNCTION DoScaleFactorCommand (view: TImageView): TCommand;

FUNCTION DoNormalSize (view: TImageView): TCommand;

FUNCTION DoOverviewSize (view: TImageView): TCommand;

FUNCTION DoZoomTool (view: TImageView;
					 downPoint: Point;
					 zoomOut: BOOLEAN): TCommand;

IMPLEMENTATION

{*****************************************************************************}

{$S ASelCommand}

FUNCTION DoZoomInCommand (view: TImageView): TCommand;

	VAR
		center: Point;
		newMag: INTEGER;

	BEGIN

	newMag := Min (view.fMagnification + 1,
				   view.MaxMagnification);

	IF newMag = -1 THEN newMag := 1;

	GetCenterPoint (view, center);

	view.fMagnification := newMag;
	view.AdjustExtent;
	view.UpdateWindowTitle;
	view.InvalRulers;

	SetCenterPoint (view, center);

	DoZoomInCommand := gNoChanges

	END;

{*****************************************************************************}

{$S ASelCommand}

FUNCTION DoZoomOutCommand (view: TImageView): TCommand;

	VAR
		center: Point;
		newMag: INTEGER;

	BEGIN

	IF view.fMagnification = 1 THEN
		newMag := -2
	ELSE
		newMag := view.fMagnification - 1;

	newMag := Max (newMag, view.MinMagnification);

	GetCenterPoint (view, center);

	view.fMagnification := newMag;
	view.AdjustExtent;
	view.UpdateWindowTitle;
	view.InvalRulers;

	SetCenterPoint (view, center);

	DoZoomOutCommand := gNoChanges

	END;

{*****************************************************************************}

{$S ASelCommand}

FUNCTION DoScaleFactorCommand (view: TImageView): TCommand;

	CONST
		kScaleDialogID = 1003;
		kHookItem	   = 3;
		kEditItem	   = 4;
		kMagItem	   = 5;

	VAR
		fi: FailInfo;
		center: Point;
		newMag: INTEGER;
		hitItem: INTEGER;
		aBWDialog: TBWDialog;
		aNumberText: TFixedText;
		aRadioCluster: TRadioCluster;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aBWDialog.Free
		END;

	BEGIN

	NEW (aBWDialog);
	FailNil (aBWDialog);

	aBWDialog.IBWDialog (kScaleDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	aNumberText := aBWDialog.DefineFixedText
			(kEditItem, 0, FALSE, TRUE, 1, Max (ABS (view.MinMagnification),
												ABS (view.MaxMagnification)));

	IF view.fMagnification > 0 THEN
		aNumberText.StuffValue (view.fMagnification)
	ELSE
		aNumberText.StuffValue (-view.fMagnification);

	aBWDialog.SetEditSelection (kEditItem);

	aRadioCluster := aBWDialog.DefineRadioCluster
			(kMagItem,
			 kMagItem + 1,
			 kMagItem + ORD (view.fMagnification < 0));

	aBWDialog.TalkToUser (hitItem, StdItemHandling);

	IF hitItem <> ok THEN Failure (0, 0);

	newMag := aNumberText.fValue;

	IF aRadioCluster.fChosenItem <> kMagItem THEN
		newMag := -newMag;

	Success (fi);

	CleanUp (0, 0);

	newMag := Min (newMag, view.MaxMagnification);
	newMag := Max (newMag, view.MinMagnification);

	IF newMag = -1 THEN newMag := 1;

	IF newMag = view.fMagnification THEN Failure (0, 0);

	GetCenterPoint (view, center);

	view.fMagnification := newMag;
	view.AdjustExtent;
	view.UpdateWindowTitle;
	view.InvalRulers;

	SetCenterPoint (view, center);

	DoScaleFactorCommand := gNoChanges

	END;

{*****************************************************************************}

{$S ASelCommand}

FUNCTION DoNormalSize (view: TImageView): TCommand;

	VAR
		center: Point;

	BEGIN

	IF view.fMagnification = 1 THEN Failure (0, 0);

	GetCenterPoint (view, center);

	view.fMagnification := 1;
	view.AdjustExtent;
	view.UpdateWindowTitle;
	view.InvalRulers;

	SetCenterPoint (view, center);

	DoNormalSize := gNoChanges

	END;

{*****************************************************************************}

{$S ASelCommand}

FUNCTION DoOverviewSize (view: TImageView): TCommand;

	VAR
		wSize: Point;
		newMag: INTEGER;
		iWidth: INTEGER;
		wWidth: INTEGER;
		doc: TImageDocument;

	BEGIN

	doc := TImageDocument (view.fDocument);

	view.GetZoomSize (wSize);

	IF ORD4 (doc.fRows) * wSize.h >= ORD4 (doc.fCols) * wSize.v THEN
		BEGIN
		wWidth := wSize.v;
		iWidth := doc.fRows
		END
	ELSE
		BEGIN
		wWidth := wSize.h;
		iWidth := doc.fCols
		END;

	IF wWidth >= iWidth THEN
		newMag := wWidth DIV iWidth
	ELSE
		newMag := -((iWidth + wWidth - 1) DIV wWidth);

	newMag := Min (newMag, view.MaxMagnification);
	newMag := Max (newMag, view.MinMagnification);

	IF view.fMagnification <> newMag THEN
		BEGIN
		view.fMagnification := newMag;
		view.ChangeExtent;
		view.UpdateWindowTitle;
		view.InvalRulers
		END;

	IF view.fScreenMode = 0 THEN
		view.SetToZoomSize;

	DoOverviewSize := gNoChanges

	END;

{*****************************************************************************}

{$S ASelCommand}

FUNCTION DoZoomTool (view: TImageView;
					 downPoint: Point;
					 zoomOut: BOOLEAN): TCommand;

	VAR
		r: Rect;
		r1: Rect;
		r2: Rect;
		vr1: Rect;
		vr2: Rect;
		j: INTEGER;
		time: LONGINT;
		center: Point;
		origin1: Point;
		origin2: Point;
		newMag: INTEGER;
		oldMag: INTEGER;

	BEGIN

	oldMag := view.fMagnification;

	IF zoomOut THEN
		BEGIN
		IF oldMag < 1 THEN
			newMag := -BSL (-oldMag, 1)
		ELSE IF oldMag = 1 THEN
			newMag := -2
		ELSE
			newMag := BSR (oldMag + 1, 1)
		END
	ELSE
		BEGIN
		IF oldMag >= 1 THEN
			newMag := BSL (oldMag, 1)
		ELSE IF oldMag = -2 THEN
			newMag := 1
		ELSE
			newMag := -BSR (-oldMag + 1, 1)
		END;

	newMag := Min (view.MaxMagnification,
			  Max (view.MinMagnification,
				   newMag));

	IF newMag = oldMag THEN Failure (0, 0);

	view.fFrame.GetViewedRect (vr1);
	origin1 := view.fFrame.fRelOrigin;

	center := downPoint;
	view.CvtView2Image (center);

	view.fMagnification := newMag;
	view.ChangeExtent;
	view.InvalRulers;

	IF view.fWindow <> NIL THEN
		view.UpdateWindowTitle;

	SetCenterPoint (view, center);

	view.fFrame.GetViewedRect (vr2);
	origin2 := view.fFrame.fRelOrigin;

	IF zoomOut THEN
		BEGIN

		r1 := vr1;
		r2 := vr1;

		view.fMagnification := oldMag;
		view.CvtView2Image (r2.topLeft);
		view.CvtView2Image (r2.botRight);
		view.fMagnification := newMag;

		view.CvtImage2View (r2.topLeft, kRoundDown);
		view.CvtImage2View (r2.botRight, kRoundUp)

		END

	ELSE
		BEGIN

		r1 := vr2;
		r2 := vr2;

		view.CvtView2Image (r1.topLeft);
		view.CvtView2Image (r1.botRight);

		view.fMagnification := oldMag;
		view.CvtImage2View (r1.topLeft, kRoundDown);
		view.CvtImage2View (r1.botRight, kRoundUp);
		view.fMagnification := newMag

		END;

	OffsetRect (r1, origin2.h - origin1.h,
					origin2.v - origin1.v);

	view.fFrame.Focus;

	PenNormal;
	PenMode (patXor);

	time := TickCount;

	FOR j := 0 TO 8 DO
		BEGIN

		r.top	 := BSR ((r2.top	* ORD4 (j) +
						  r1.top	* ORD4 (8 - j)), 3);
		r.left	 := BSR ((r2.left	* ORD4 (j) +
						  r1.left	* ORD4 (8 - j)), 3);
		r.bottom := BSR ((r2.bottom * ORD4 (j) +
						  r1.bottom * ORD4 (8 - j)), 3);
		r.right  := BSR ((r2.right	* ORD4 (j) +
						  r1.right	* ORD4 (8 - j)), 3);

		FrameRect (r);

		time := time + 2;
			REPEAT
			UNTIL TickCount >= time;

		FrameRect (r)

		END;

	IF StillDown THEN Failure (0, 0);

	DoZoomTool := gNoChanges

	END;

{*****************************************************************************}

END.

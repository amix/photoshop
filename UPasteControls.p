{Photoshop version 1.0.1, file: UPasteControls.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UPasteControls;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UBWDialog, UCommands, UAdjust;

TYPE

	TPasteControlsDialog = OBJECT (TFeedbackDialog)

		fControls: TPasteControls;

		fSrcBarRect: Rect;
		fDstBarRect: Rect;

		fSrcMinRect: Rect;
		fSrcMaxRect: Rect;
		fDstMinRect: Rect;
		fDstMaxRect: Rect;

		fSrcLevelsRect: Rect;
		fDstLevelsRect: Rect;

		fBlendText: TFixedText;
		fFuzzText : TFixedText;

		fBandCluster: TRadioCluster;
		fModeCluster: TRadioCluster;

		PROCEDURE TPasteControlsDialog.IPasteControlsDialog
				(view: TImageView;
				 controls: TPasteControls;
				 mode: TDisplayMode);

		PROCEDURE TPasteControlsDialog.GetSettings
				(VAR controls: TPasteControls);

		PROCEDURE TPasteControlsDialog.DrawSrcLevels;

		PROCEDURE TPasteControlsDialog.DrawDstLevels;

		PROCEDURE TPasteControlsDialog.DrawAmendments
				(theItem: INTEGER); OVERRIDE;

		PROCEDURE TPasteControlsDialog.DoSetLevel (which, what: INTEGER);

		FUNCTION TPasteControlsDialog.DownInDialog
				(mousePt: Point): BOOLEAN; OVERRIDE;

		END;

	TPasteControlsCommand = OBJECT (TFloatCommand)

		fNewControls: TPasteControls;
		fOldControls: TPasteControls;

		PROCEDURE TPasteControlsCommand.IPasteControls (view: TImageView);

		PROCEDURE TPasteControlsCommand.PreviewControls (useNew: BOOLEAN);

		PROCEDURE TPasteControlsCommand.GetParameters;

		PROCEDURE TPasteControlsCommand.DoIt; OVERRIDE;

		PROCEDURE TPasteControlsCommand.UndoIt; OVERRIDE;

		PROCEDURE TPasteControlsCommand.RedoIt; OVERRIDE;

		END;

PROCEDURE InitPasteControls;

FUNCTION DoPasteControls (view: TImageView): TCommand;

IMPLEMENTATION

{$I UAssembly.a.inc}

VAR
	gPasteLocation1: Point;
	gPasteLocation2: Point;
	gPasteLocation3: Point;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitPasteControls;

	BEGIN

	gPasteLocation1.h := 0;
	gPasteLocation1.v := 0;

	gPasteLocation2.h := 0;
	gPasteLocation2.v := 0;

	gPasteLocation3.h := 0;
	gPasteLocation3.v := 0

	END;

{*****************************************************************************}

{$S APasteControls}

PROCEDURE TPasteControlsDialog.IPasteControlsDialog (view: TImageView;
													 controls: TPasteControls;
													 mode: TDisplayMode);

	CONST
		kMonoDialogID  = 1070;
		kIndexDialogID = 1071;
		kRGBDialogID   = 1072;
		kHookItem	   = 4;
		kSrcBarItem    = 5;
		kDstBarItem    = 6;
		kSrcMinItem    = 7;
		kSrcMaxItem    = 8;
		kDstMinItem    = 9;
		kDstMaxItem    = 10;
		kFirstBandItem = 11;
		kLastBandItem  = 14;
		kFirstModeItem = 15;
		kLastModeItem  = 18;
		kBlendItem	   = 19;
		kFuzzItem	   = 20;

	VAR
		pp: PPoint;
		id: INTEGER;
		fi: FailInfo;
		itemType: INTEGER;
		itemHandle: Handle;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Free
		END;

	BEGIN

	fControls := controls;

	IF mode = MonochromeMode THEN
		BEGIN
		id := kMonoDialogID;
		pp := @gPasteLocation1
		END
	ELSE IF mode = IndexedColorMode THEN
		BEGIN
		id := kIndexDialogID;
		pp := @gPasteLocation2
		END
	ELSE
		BEGIN
		id := kRGBDialogID;
		pp := @gPasteLocation3
		END;

	IFeedbackDialog (view, NIL, pp, id, kHookItem, ok, 0);

	CatchFailures (fi, CleanUp);

	{$H-}

	GetDItem (fDialogPtr, kSrcBarItem, itemType, itemHandle, fSrcBarRect);
	GetDItem (fDialogPtr, kDstBarItem, itemType, itemHandle, fDstBarRect);

	GetDItem (fDialogPtr, kSrcMinItem, itemType, itemHandle, fSrcMinRect);
	GetDItem (fDialogPtr, kSrcMaxItem, itemType, itemHandle, fSrcMaxRect);
	GetDItem (fDialogPtr, kDstMinItem, itemType, itemHandle, fDstMinRect);
	GetDItem (fDialogPtr, kDstMaxItem, itemType, itemHandle, fDstMaxRect);

	{$H+}

	fSrcLevelsRect.top	  := fSrcBarRect.bottom;
	fSrcLevelsRect.left   := fSrcBarRect.left	- gPtrWidth;
	fSrcLevelsRect.right  := fSrcBarRect.right	+ gPtrWidth;
	fSrcLevelsRect.bottom := fSrcBarRect.bottom + gBPointer.bounds.bottom;

	fDstLevelsRect.top	  := fDstBarRect.bottom;
	fDstLevelsRect.left   := fDstBarRect.left	- gPtrWidth;
	fDstLevelsRect.right  := fDstBarRect.right	+ gPtrWidth;
	fDstLevelsRect.bottom := fDstBarRect.bottom + gBPointer.bounds.bottom;

	fBandCluster := DefineRadioCluster (kFirstBandItem,
										kLastBandItem,
										kFirstBandItem);

	fModeCluster := DefineRadioCluster (kFirstModeItem,
										kLastModeItem,
										kFirstModeItem +
										ORD (fControls.fMode));

	IF mode = IndexedColorMode THEN
		BEGIN
		fBlendText := NIL;
		fFuzzText  := NIL;
		END

	ELSE
		BEGIN

		fBlendText := DefineFixedText (kBlendItem, 0, FALSE, TRUE, 1, 100);
		fFuzzText  := DefineFixedText (kFuzzItem , 0, FALSE, TRUE, 0, 100);

		fBlendText.StuffValue (fControls.fBlend);
		fFuzzText .StuffValue (fControls.fFuzz);

		SetEditSelection (kBlendItem)

		END;

	Success (fi)

	END;

{*****************************************************************************}

{$S APasteControls}

PROCEDURE TPasteControlsDialog.GetSettings (VAR controls: TPasteControls);

	BEGIN

	fControls.fMode := TPasteMode (fModeCluster.fChosenItem -
								   fModeCluster.fFirstItem);

	IF fBlendText <> NIL THEN
		fControls.fBlend := fBlendText.fValue;

	IF fFuzzText <> NIL THEN
		fControls.fFuzz := fFuzzText.fValue;

	controls := fControls

	END;

{*****************************************************************************}

{$S APasteControls}

PROCEDURE TPasteControlsDialog.DrawSrcLevels;

	VAR
		r: Rect;
		band: INTEGER;
		bLevel: INTEGER;
		wLevel: INTEGER;

	BEGIN

	r := fSrcLevelsRect;

	band := fBandCluster.fChosenItem - fBandCluster.fFirstItem;

	bLevel := fControls.fSrcMin [band];
	wLevel := fControls.fSrcMax [band];

	EraseRect (r);

	r.left	:= r.left + bLevel;
	r.right := r.left + gBPointer.bounds.right;

	CopyBits (gBPointer, thePort^.portBits, gBPointer.bounds, r, srcOr, NIL);

	OffsetRect (r, wLevel - bLevel, 0);

	CopyBits (gWPointer, thePort^.portBits, gWPointer.bounds, r, srcOr, NIL);

	DrawNumber (bLevel, fSrcMinRect);

	DrawNumber (wLevel, fSrcMaxRect)

	END;

{*****************************************************************************}

{$S APasteControls}

PROCEDURE TPasteControlsDialog.DrawDstLevels;

	VAR
		r: Rect;
		band: INTEGER;
		bLevel: INTEGER;
		wLevel: INTEGER;

	BEGIN

	r := fDstLevelsRect;

	band := fBandCluster.fChosenItem - fBandCluster.fFirstItem;

	bLevel := fControls.fDstMin [band];
	wLevel := fControls.fDstMax [band];

	EraseRect (r);

	r.left	:= r.left + bLevel;
	r.right := r.left + gBPointer.bounds.right;

	CopyBits (gBPointer, thePort^.portBits, gBPointer.bounds, r, SrcOr, NIL);

	OffsetRect (r, wLevel - bLevel, 0);

	CopyBits (gWPointer, thePort^.portBits, gWPointer.bounds, r, SrcOr, NIL);

	DrawNumber (bLevel, fDstMinRect);

	DrawNumber (wLevel, fDstMaxRect)

	END;

{*****************************************************************************}

{$S APasteControls}

PROCEDURE TPasteControlsDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

	BEGIN

	INHERITED DrawAmendments (theItem);

	PaintRect (fSrcBarRect);
	PaintRect (fDstBarRect);

	DrawSrcLevels;
	DrawDstLevels

	END;

{*****************************************************************************}

{$S APasteControls}

PROCEDURE TPasteControlsDialog.DoSetLevel (which, what: INTEGER);

	VAR
		band: INTEGER;

	BEGIN

	band := fBandCluster.fChosenItem - fBandCluster.fFirstItem;

		CASE which OF
		1:	fControls.fSrcMin [band] := what;
		2:	fControls.fSrcMax [band] := what;
		3:	fControls.fDstMin [band] := what;
		4:	fControls.fDstMax [band] := what
		END;

	IF which <= 2 THEN
		DrawSrcLevels
	ELSE
		DrawDstLevels

	END;

{*****************************************************************************}

{$S APasteControls}

FUNCTION TPasteControlsDialog.DownInDialog (mousePt: Point): BOOLEAN; OVERRIDE;

	VAR
		r: Rect;
		pt: Point;
		band: INTEGER;
		which: INTEGER;
		delta: INTEGER;
		bLevel: INTEGER;
		wLevel: INTEGER;
		newLevel: INTEGER;
		oldLevel: INTEGER;

	BEGIN

	DownInDialog := FALSE;

	band := fBandCluster.fChosenItem - fBandCluster.fFirstItem;
	
	which := 0;
	
	newLevel := mousePt.h - fSrcBarRect.left;

	r := fSrcLevelsRect;
	r.bottom := r.bottom + 6;

	IF PtInRect (mousePt, r) THEN
		BEGIN

		bLevel := fControls.fSrcMin [band];
		wLevel := fControls.fSrcMax [band];

		which := 1;
		delta := newLevel - bLevel;

		IF Abs (newLevel - wLevel) < Abs (delta) THEN
			BEGIN
			which := 2;
			delta := newLevel - wLevel
			END

		END;
		
	r := fDstLevelsRect;
	r.bottom := r.bottom + 6;

	IF PtInRect (mousePt, r) THEN
		BEGIN

		bLevel := fControls.fDstMin [band];
		wLevel := fControls.fDstMax [band];

		which := 3;
		delta := newLevel - bLevel;

		IF Abs (newLevel - wLevel) < Abs (delta) THEN
			BEGIN
			which := 4;
			delta := newLevel - wLevel
			END

		END;
		
	IF which = 0 THEN
		EXIT (DownInDialog);

	DownInDialog := TRUE;

	oldLevel := newLevel - delta;

		REPEAT

		NextMousePoint (pt);

		newLevel := Max (0, Min (pt.h - fSrcBarRect.left, 255));

		IF newLevel <> oldLevel THEN
			BEGIN
			DoSetLevel (which, newLevel);
			oldLevel := newLevel
			END

		UNTIL fLastPoint

	END;

{*****************************************************************************}

{$S APasteControls}

PROCEDURE TPasteControlsCommand.IPasteControls (view: TImageView);

	VAR
		h: Handle;
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Free
		END;

	BEGIN

	IFloatCommand (cPasteControls2, view);

	CatchFailures (fi, CleanUp);

	{$H-}
	GetPasteControls (fDoc, fOldControls);
	{$H+}

	IF fDoc.fPasteControls = NIL THEN
		BEGIN

		h := NewPermHandle (SIZEOF (TPasteControls));
		FailNil (h);

		HPasteControls (h)^^ := fOldControls;

		fDoc.fPasteControls := h

		END;

	fNewControls := fOldControls;

	GetParameters;

	Success (fi)

	END;

{*****************************************************************************}

{$S APasteControls}

PROCEDURE TPasteControlsCommand.PreviewControls (useNew: BOOLEAN);

	VAR
		r: Rect;
		controls: TPasteControls;

	BEGIN

	MoveHands (FALSE);

	IF fDoc.fFloatCommand <> SELF THEN
		FloatSelection (FALSE);

	controls := HPasteControls (fDoc.fPasteControls)^^;

	IF useNew THEN
		HPasteControls (fDoc.fPasteControls)^^ := fNewControls
	ELSE
		HPasteControls (fDoc.fPasteControls)^^ := fOldControls;

	IF NOT EqualBytes (@controls,
					   fDoc.fPasteControls^,
					   SIZEOF (TPasteControls)) THEN
		BEGIN

		CopyBelow (FALSE);

		BlendFloat (FALSE);

		ComputeOverlap (r);
		fDoc.UpdateImageArea (r, TRUE, TRUE, fDoc.fFloatChannel)

		END;

	IF NOT fDoc.fSelectionFloating THEN
		SelectFloat

	END;

{*****************************************************************************}

{$S APasteControls}

PROCEDURE TPasteControlsCommand.GetParameters;

	CONST
		kPreviewItem = 3;

	VAR
		fi: FailInfo;
		mode: TDisplayMode;
		previewed: BOOLEAN;
		aPasteDialog: TPasteControlsDialog;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aPasteDialog.Free;
		IF previewed THEN PreviewControls (FALSE)
		END;

	PROCEDURE MyItemHandling (item: INTEGER; VAR done: BOOLEAN);

		VAR
			succeeded: BOOLEAN;

		BEGIN

		done := FALSE;

		IF item = kPreviewItem THEN
			BEGIN
			aPasteDialog.Validate (succeeded);
			IF succeeded THEN
				BEGIN
				{$H-}
				aPasteDialog.GetSettings (fNewControls);
				{$H+}
				gApplication.CommitLastCommand;
				PreviewControls (TRUE);
				previewed := TRUE
				END
			END

		ELSE IF (item >= aPasteDialog.fBandCluster.fFirstItem) AND
				(item <= aPasteDialog.fBandCluster.fLastItem) THEN
			BEGIN
			StdItemHandling (item, done);
			SetPort (aPasteDialog.fDialogPtr);
			aPasteDialog.DrawSrcLevels;
			aPasteDialog.DrawDstLevels
			END

		ELSE
			StdItemHandling (item, done)

		END;

	BEGIN

	previewed := FALSE;

	NEW (aPasteDialog);
	FailNil (aPasteDialog);

	IF fView.fChannel = kRGBChannels THEN
		mode := RGBColorMode
	ELSE IF fDoc.fMode = IndexedColorMode THEN
		mode := IndexedColorMode
	ELSE
		mode := MonochromeMode;

	aPasteDialog.IPasteControlsDialog (fView, fNewControls, mode);

	CatchFailures (fi, CleanUp);

	aPasteDialog.DoTalkToUser (MyItemHandling);

	{$H-}
	aPasteDialog.GetSettings (fNewControls);
	{$H+}

	IF EqualBytes (@fNewControls,
				   @fOldControls,
				   SIZEOF (TPasteControls)) THEN Failure (0, 0);

	Success (fi);

	aPasteDialog.Free

	END;

{*****************************************************************************}

{$S APasteControls}

PROCEDURE TPasteControlsCommand.DoIt; OVERRIDE;

	BEGIN
	PreviewControls (TRUE)
	END;

{*****************************************************************************}

{$S APasteControls}

PROCEDURE TPasteControlsCommand.UndoIt; OVERRIDE;

	BEGIN
	PreviewControls (FALSE)
	END;

{*****************************************************************************}

{$S APasteControls}

PROCEDURE TPasteControlsCommand.RedoIt; OVERRIDE;

	BEGIN
	DoIt
	END;

{*****************************************************************************}

{$S APasteControls}

FUNCTION DoPasteControls (view: TImageView): TCommand;

	VAR
		aPasteControlsCommand: TPasteControlsCommand;

	BEGIN

	NEW (aPasteControlsCommand);
	FailNil (aPasteControlsCommand);

	aPasteControlsCommand.IPasteControls (view);

	DoPasteControls := aPasteControlsCommand

	END;

{*****************************************************************************}

END.

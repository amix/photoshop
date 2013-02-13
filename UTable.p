{Photoshop version 1.0.1, file: UTable.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UTable;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	PickerIntf, UDialog, UBWDialog, UCommands;

TYPE

	TTableCommand = OBJECT (TBufferCommand)

		fTable: TRGBLookUpTable;

		PROCEDURE TTableCommand.DoIt; OVERRIDE;

		PROCEDURE TTableCommand.UndoIt; OVERRIDE;

		PROCEDURE TTableCommand.RedoIt; OVERRIDE;

		END;

	TTableDialog = OBJECT (TBWDialog)

		fTableRect: Rect;

		fTable: TRGBLookUpTable;

		fSystemPalette: PaletteHandle;

		PROCEDURE TTableDialog.ITableDialog (table: TRGBLookUpTable);

		PROCEDURE TTableDialog.Free; OVERRIDE;

		PROCEDURE TTableDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

		PROCEDURE TTableDialog.PickRange (index1, index2: INTEGER; cube: BOOLEAN);

		PROCEDURE TTableDialog.DownInTable (pt: Point; optionDown: BOOLEAN);

		PROCEDURE TTableDialog.DoFilterEvent (VAR anEvent: EventRecord;
											  VAR itemHit: INTEGER;
											  VAR handledIt: BOOLEAN;
											  VAR doReturn: BOOLEAN); OVERRIDE;

		PROCEDURE TTableDialog.DoLoadTable;

		PROCEDURE TTableDialog.DoSaveTable;

		PROCEDURE TTableDialog.DoButtonPushed
				(anItem: INTEGER; VAR succeeded: BOOLEAN); OVERRIDE;

		END;

FUNCTION DoTableCommand (view: TImageView; name: Str255): TCommand;

FUNCTION DoEditTableCommand (view: TImageView): TCommand;

IMPLEMENTATION

{$I UAssembly.a.inc}
{$I UPick.p.inc}

CONST
	kTableFileType = '8BCT';

{*****************************************************************************}

{$S AColorTable}

PROCEDURE TTableCommand.DoIt; OVERRIDE;

	VAR
		table: TRGBLookUpTable;

	PROCEDURE FixView (view: TImageView);
		BEGIN
		view.ReDither (TRUE)
		END;

	BEGIN

	table					:= fDoc.fIndexedColorTable;
	fDoc.fIndexedColorTable := fTable;
	fTable					:= table;

	fDoc.TestColorTable;

	fDoc.fViewList.Each (FixView)

	END;

{*****************************************************************************}

{$S AColorTable}

PROCEDURE TTableCommand.UndoIt; OVERRIDE;

	BEGIN
	Doit
	END;

{*****************************************************************************}

{$S AColorTable}

PROCEDURE TTableCommand.RedoIt; OVERRIDE;

	BEGIN
	Doit
	END;

{*****************************************************************************}

{$S AColorTable}

FUNCTION DoTableCommand (view: TImageView; name: Str255): TCommand;

	VAR
		doc: TImageDocument;
		table: TRGBLookUpTable;
		tableH: HRGBLookUpTable;
		aTableCommand: TTableCommand;

	BEGIN

	doc := TImageDocument (view.fDocument);

	tableH := HRGBLookUpTable (GetNamedResource ('PLUT', name));

	IF tableH = NIL THEN Failure (1, 0);

	table := tableH^^;

	IF EqualBytes (@table,
				   @doc.fIndexedColorTable,
				   SIZEOF (TRGBLookUpTable)) THEN Failure (0, 0);

	NEW (aTableCommand);
	FailNil (aTableCommand);

	aTableCommand.IBufferCommand (cTableChange, view);

	aTableCommand.fTable := table;

	DoTableCommand := aTableCommand

	END;

{*****************************************************************************}

{$S AColorTable}

PROCEDURE TTableDialog.ITableDialog (table: TRGBLookUpTable);

	CONST
		kDialogID  = 1006;
		kHookItem  = 3;
		kTableItem = 4;

	VAR
		r: Rect;
		ct: CTabHandle;
		depth: INTEGER;
		itemType: INTEGER;
		itemHandle: Handle;
		monochrome: BOOLEAN;

	BEGIN

	fTable := table;

	fSystemPalette := NIL;

	IBWDialog (kDialogID, kHookItem, ok);

	IF gConfiguration.hasColorToolBox THEN
		BEGIN

		GetScreenInfo (GetMainDevice, depth, monochrome);

		IF (depth >= 4) AND (depth <= 8) THEN
			BEGIN
			ct := GetCTable (depth);
			fSystemPalette := NewPalette (ct^^.ctSize + 1, ct, pmTolerant, 0);
			SetPalette (fDialogPtr, fSystemPalette, TRUE);
			DisposCTable (ct)
			END

		END;

	GetDItem (fDialogPtr, kTableItem, itemType, itemHandle, r);
	InsetRect (r, 1, 1);
	fTableRect := r

	END;

{*****************************************************************************}

{$S AColorTable}

PROCEDURE TTableDialog.Free; OVERRIDE;

	BEGIN

	IF fSystemPalette <> NIL THEN DisposePalette (fSystemPalette);

	INHERITED Free

	END;

{*****************************************************************************}

{$S AColorTable}

PROCEDURE TTableDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

	VAR
		r: Rect;
		rgn: RgnHandle;
		index: INTEGER;
		depth: INTEGER;
		color: RGBColor;
		monochrome: BOOLEAN;

	BEGIN

	INHERITED DrawAmendments (theItem);

	PenNormal;

	r := fTableRect;
	InsetRect (r, -1, -1);
	FrameRect (r);

	IF gConfiguration.hasColorToolBox THEN
		GetScreenInfo (GetMainDevice, depth, monochrome)
	ELSE
		depth := 1;

	rgn := NewRgn;

	FOR index := 0 TO 255 DO
		BEGIN

		r.top	 := fTableRect.top	+ 16 * BSR	(index, 4 ) + 1;
		r.left	 := fTableRect.left + 16 * BAND (index, $F) + 1;
		r.bottom := r.top  + 14;
		r.right  := r.left + 14;

		RectRgn (rgn, r);

		color.red	:= ORD (fTable.R [index]);
		color.green := ORD (fTable.G [index]);
		color.blue	:= ORD (fTable.B [index]);

		color.red	:= BSL (color.red  , 8) + color.red;
		color.green := BSL (color.green, 8) + color.green;
		color.blue	:= BSL (color.blue , 8) + color.blue;

		RgnFillRGB (rgn, color, depth)

		END;

	DisposeRgn (rgn)

	END;

{*****************************************************************************}

{$S AColorTable}

PROCEDURE TTableDialog.PickRange (index1, index2: INTEGER; cube: BOOLEAN);

	VAR
		index: INTEGER;
		prompt: INTEGER;
		color: RGBColor;
		color1: RGBColor;
		color2: RGBColor;

	BEGIN

	color1.red	 := ORD (fTable.R [index1]);
	color1.green := ORD (fTable.G [index1]);
	color1.blue  := ORD (fTable.B [index1]);

	color1.red	 := BSL (color1.red  , 8) + color1.red;
	color1.green := BSL (color1.green, 8) + color1.green;
	color1.blue  := BSL (color1.blue , 8) + color1.blue;

	IF index1 = index2 THEN
		prompt := strSelectColor
	ELSE
		prompt := strSelectFirstColor;

	IF NOT DoSetColor (cube, prompt, color1) THEN EXIT (PickRange);

	color2 := color1;

	IF index1 <> index2 THEN
		IF NOT DoSetColor (cube, strSelectLastColor, color2) THEN
			EXIT (PickRange);

	FOR index := index1 TO index2 DO
		BEGIN

		IF index1 = index2 THEN
			color := color1
		ELSE
			BEGIN
			color.red	:= (BAND (color1.red  , $0000FFFF) *
							(index2 - index) +
							BAND (color2.red  , $0000FFFF) *
							(index - index1)) DIV
						   (index2 - index1);
			color.green := (BAND (color1.green, $0000FFFF) *
							(index2 - index) +
							BAND (color2.green, $0000FFFF) *
							(index - index1)) DIV
						   (index2 - index1);
			color.blue	:= (BAND (color1.blue , $0000FFFF) *
							(index2 - index) +
							BAND (color2.blue , $0000FFFF) *
							(index - index1)) DIV
						   (index2 - index1)
			END;

		fTable.R [index] := CHR (BAND ($FF, BSR (color.red	, 8)));
		fTable.G [index] := CHR (BAND ($FF, BSR (color.green, 8)));
		fTable.B [index] := CHR (BAND ($FF, BSR (color.blue , 8)))

		END

	END;

{*****************************************************************************}

{$S AColorTable}

PROCEDURE TTableDialog.DownInTable (pt: Point; optionDown: BOOLEAN);

	VAR
		nextPt: Point;
		index1: INTEGER;
		index2: INTEGER;
		loHilite: INTEGER;
		hiHilite: INTEGER;

	PROCEDURE ToggleCell (index: INTEGER);

		VAR
			r: Rect;

		BEGIN

		r.top	 := fTableRect.top	+ 16 * BSR	(index, 4 );
		r.left	 := fTableRect.left + 16 * BAND (index, $F);
		r.bottom := r.top  + 16;
		r.right  := r.left + 16;

		FrameRect (r)

		END;

	PROCEDURE HiliteRange (loCell, hiCell: INTEGER);

		VAR
			index: INTEGER;

		BEGIN

		FOR index := 0 TO 255 DO
			IF ((index >= loCell  ) AND (index <= hiCell  )) <>
			   ((index >= loHilite) AND (index <= hiHilite)) THEN
				ToggleCell (index);

		loHilite := loCell;
		hiHilite := hiCell

		END;

	FUNCTION GetIndex (pt: Point): INTEGER;

		BEGIN
		GetIndex := Max (0, Min (15, (pt.v - fTableRect.top ) DIV 16)) * 16 +
					Max (0, Min (15, (pt.h - fTableRect.left) DIV 16));
		END;

	BEGIN

	PenNormal;
	PenMode (patXor);

	loHilite := 255;
	hiHilite := 0;

	index1 := GetIndex (pt);
	index2 := index1;

	WHILE StillDown DO
		BEGIN
		GetMouse (nextPt);
		index2 := GetIndex (nextPt);
		HiliteRange (Min (index1, index2), Max (index1, index2))
		END;

	PenNormal;

	InvalRect (fTableRect);

	PickRange (Min (index1, index2), Max (index1, index2), NOT optionDown)

	END;

{*****************************************************************************}

{$S AColorTable}

PROCEDURE TTableDialog.DoFilterEvent (VAR anEvent: EventRecord;
									  VAR itemHit: INTEGER;
									  VAR handledIt: BOOLEAN;
									  VAR doReturn: BOOLEAN); OVERRIDE;

	VAR
		pt: Point;
		cmd: TCommand;
		whichWindow: WindowPtr;

	BEGIN

	IF anEvent.what = nullEvent THEN
		IF gApplication.fIdlePriority <> 0 THEN
			gApplication.DoIdle (IdleContinue);

	IF anEvent.what = updateEvt THEN
		IF WindowPeek (anEvent.message)^.windowKind >= userKind THEN
			BEGIN
			gApplication.ObeyEvent (@anEvent, cmd);
			anEvent.what := nullEvent
			END;

	IF anEvent.what = mouseDown THEN
		IF FindWindow (anEvent.where, whichWindow) = inContent THEN
			IF whichWindow = fDialogPtr THEN
				BEGIN

				SetPort (fDialogPtr);

				pt := anEvent.where;
				GlobalToLocal (pt);

				IF PtInRect (pt, fTableRect) THEN
					BEGIN
					DownInTable (pt, BAND (anEvent.modifiers,
										   optionKey) <> 0);
					anEvent.what := nullEvent
					END

				END;

	INHERITED DoFilterEvent (anEvent, itemHit, handledIt, doReturn)

	END;

{*****************************************************************************}

{$S AColorTable}

PROCEDURE TTableDialog.DoLoadTable;

	VAR
		err: OSErr;
		fi: FailInfo;
		where: Point;
		reply: SFReply;
		count: LONGINT;
		refNum: INTEGER;
		typeList: SFTypeList;
		buffer: PACKED ARRAY [0..767] OF CHAR;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF refNum <> -1 THEN
			err := FSClose (refNum);
		IF error <> noErr THEN
			gApplication.ShowError (error, msgCannotLoadCLUT);
		EXIT (DoLoadTable)
		END;

	BEGIN

	refNum := -1;

	CatchFailures (fi, CleanUp);

	WhereToPlaceDialog (getDlgID, where);

	typeList [0] := kTableFileType;

	SFGetFile (where, '', NIL, 1, typeList, NIL, reply);
	IF NOT reply.good THEN Failure (0, 0);

	FailOSErr (FSOpen (reply.fName, reply.vRefNum, refNum));

	FailOSErr (GetEOF (refNum, count));

	IF count <> SIZEOF (TRGBLookUpTable) THEN Failure (eofErr, 0);

	FailOSErr (FSRead (refNum, count, @buffer));

	FailOSErr (FSClose (refNum));

	Success (fi);

	DoStepCopyBytes (@buffer [0], @fTable.R, 256, 3, 1);
	DoStepCopyBytes (@buffer [1], @fTable.G, 256, 3, 1);
	DoStepCopyBytes (@buffer [2], @fTable.B, 256, 3, 1);

	SetPort (fDialogPtr);
	InvalRect (fTableRect)

	END;

{*****************************************************************************}

{$S AColorTable}

PROCEDURE TTableDialog.DoSaveTable;

	VAR
		fi: FailInfo;
		reply: SFReply;
		count: LONGINT;
		prompt: Str255;
		refNum: INTEGER;
		buffer: PACKED ARRAY [0..767] OF CHAR;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		VAR
			ignore: OSErr;

		BEGIN
		IF refNum <> -1 THEN
			ignore := FSClose (refNum);
		IF error <> noErr THEN
			gApplication.ShowError (error, msgCannotSaveCLUT);
		EXIT (DoSaveTable)
		END;

	BEGIN

	refNum := -1;

	CatchFailures (fi, CleanUp);

	GetIndString (prompt, kStringsID, strSaveColorTableIn);

	refNum := CreateOutputFile (prompt, kTableFileType, reply);

	DoStepCopyBytes (@fTable.R, @buffer [0], 256, 1, 3);
	DoStepCopyBytes (@fTable.G, @buffer [1], 256, 1, 3);
	DoStepCopyBytes (@fTable.B, @buffer [2], 256, 1, 3);

	count := 768;
	FailOSErr (FSWrite (refNum, count, @buffer));

	FailOSErr (FSClose (refNum));
	refNum := -1;

	FailOSErr (FlushVol (NIL, reply.vRefNum));

	Success (fi)

	END;

{*****************************************************************************}

{$S AColorTable}

PROCEDURE TTableDialog.DoButtonPushed
		(anItem: INTEGER; VAR succeeded: BOOLEAN); OVERRIDE;

	CONST
		kLoadItem = 5;
		kSaveItem = 6;

	BEGIN

		CASE anItem OF

		kLoadItem:
			BEGIN
			succeeded := FALSE;
			DoLoadTable
			END;

		kSaveItem:
			BEGIN
			succeeded := FALSE;
			DoSaveTable
			END;

		OTHERWISE
			INHERITED DoButtonPushed (anItem, succeeded)

		END

	END;

{*****************************************************************************}

{$S AColorTable}

FUNCTION DoEditTableCommand (view: TImageView): TCommand;

	VAR
		fi: FailInfo;
		itemHit: INTEGER;
		doc: TImageDocument;
		table: TRGBLookUpTable;
		aTableDialog: TTableDialog;
		aTableCommand: TTableCommand;

	BEGIN

	doc := TImageDocument (view.fDocument);

	NEW (aTableDialog);
	FailNil (aTableDialog);

	aTableDialog.ITableDialog (doc.fIndexedColorTable);

	aTableDialog.TalkToUser (itemHit, StdItemHandling);

	table := aTableDialog.fTable;

	aTableDialog.Free;

	IF itemHit <> ok THEN Failure (0, 0);

	IF EqualBytes (@table,
				   @doc.fIndexedColorTable,
				   SIZEOF (TRGBLookUpTable)) THEN Failure (0, 0);

	NEW (aTableCommand);
	FailNil (aTableCommand);

	aTableCommand.IBufferCommand (cTableChange, view);

	aTableCommand.fTable := table;

	DoEditTableCommand := aTableCommand

	END;

{*****************************************************************************}

END.

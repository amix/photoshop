{Photoshop version 1.0.1, file: UCommands.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}
{$I UFloat.a.inc}
{$I UDither.a.inc}

{*****************************************************************************}

{$S AInit}

PROCEDURE ScanPouchFiles (theType: OSType;
						  PROCEDURE TestIt (fileName: TFileName));

	LABEL
		1;

	CONST
		kGeneralType = '8BPI';

	VAR
		fi: FailInfo;
		name: Str255;
		index: INTEGER;
		refNum: INTEGER;
		pb: ParamBlockRec;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		GOTO 1
		END;

	BEGIN

	FOR index := 1 TO 32767 DO
		BEGIN

		WITH pb DO
			BEGIN
			ioNamePtr	:= @name;
			ioVRefNum	:= gPouchRefNum;
			ioFVersNum	:= 0;
			ioFDirIndex := index
			END;

		IF PBGetFInfo (@pb, FALSE) <> noErr THEN LEAVE;

		IF (pb.ioFlFndrInfo.fdType = theType) OR
		   (pb.ioFlFndrInfo.fdType = kGeneralType) THEN
			IF LENGTH (name) <= kFileNameLength THEN
				BEGIN

				refNum := OpenResFile (name);

				IF refNum <> -1 THEN
					BEGIN

					CatchFailures (fi, CleanUp);

					TestIt (name);

					Success (fi);

					1: CloseResFile (refNum)

					END

				END

		END

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE AddNameToMenu (command: INTEGER; name: Str255);

	VAR
		mark: CHAR;
		item: INTEGER;
		count: INTEGER;
		oldName: Str255;
		menu: MenuHandle;
		compare: INTEGER;
		cmdMenu: INTEGER;
		cmdItem: INTEGER;

	BEGIN

	CmdToMenuItem (command, cmdMenu, cmdItem);

	GetItemMark (GetResMenu (cmdMenu), cmdItem, mark);

	menu := GetResMenu (ORD (mark));

	count := CountMItems (menu);

	item := 1;

	WHILE item <= count DO
		BEGIN

		GetItem (menu, item, oldName);

		compare := RelString (name, oldName, TRUE, TRUE);

		IF compare <= 0 THEN LEAVE;

		item := item + 1

		END;

	IF item > count THEN
		BEGIN
		AppendMenu (menu, 'Dummy');
		SetItem    (menu, item, name)
		END

	ELSE IF compare <> 0 THEN
		BEGIN
		InsMenuItem (menu, 'Dummy', item - 1);
		SetItem 	(menu, item, name)
		END

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitPlugInList (kind: ResType;
						  loVersion, hiVersion: INTEGER;
						  VAR first: HPlugInInfo;
						  command: INTEGER);

	PROCEDURE AddPlugIn (name: Str255;
						 fileName: TFileName;
						 resourceID: INTEGER;
						 version: INTEGER);

		VAR
			aPlugInInfo: HPlugInInfo;

		BEGIN

		aPlugInInfo := HPlugInInfo (NewHandle (SIZEOF (TPlugInInfo)));
		FailMemError;

		WITH aPlugInInfo^^ DO
			BEGIN

			fName		:= name;
			fFileName	:= fileName;
			fKind		:= kind;
			fResourceID := resourceID;
			fVersion	:= version;

			fData		:= 0;
			fParameters := NIL;

			fNext := first

			END;

		first := aPlugInInfo;

		AddNameToMenu (command, name)

		END;

	PROCEDURE TestIt (fileName: TFileName);

		TYPE
			IntegerPtr = ^INTEGER;

		VAR
			h: Handle;
			name: Str255;
			index: INTEGER;
			count: INTEGER;
			version: INTEGER;
			resourceID: INTEGER;
			ignoreType: ResType;

		BEGIN

		count := Count1Resources (kind);

		FOR index := 1 TO count DO
			BEGIN

			SetResLoad (FALSE);
			h := Get1IndResource (kind, index);
			SetResLoad (TRUE);

			IF h <> NIL THEN
				BEGIN

				GetResInfo (h, resourceID, ignoreType, name);
				FailResError;

				IF LENGTH (name) <> 0 THEN
					BEGIN

					h := Get1Resource ('PiMI', resourceID);

					IF h <> NIL THEN
						BEGIN

						version := IntegerPtr (h^)^;

						IF (version >= loVersion) AND
						   (version <= hiVersion) THEN

							AddPlugIn (name, fileName, resourceID, version)

						END

					END

				END

			END

		END;

	BEGIN

	first := NIL;

	IF NOT gFinderPrinting THEN
		BEGIN

		TestIt ('');

		ScanPouchFiles (kind, TestIt)

		END

	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE CheckForNoPlugIns (command: INTEGER);

	VAR
		mark: CHAR;
		name: Str255;
		count: INTEGER;
		cmdMenu: INTEGER;
		cmdItem: INTEGER;
		subMenu: MenuHandle;
		mainMenu: MenuHandle;

	BEGIN

	CmdToMenuItem (command, cmdMenu, cmdItem);

	mainMenu := GetResMenu (cmdMenu);

	GetItemMark (mainMenu, cmdItem, mark);

	subMenu := GetResMenu (ORD (mark));

	count := CountMItems (subMenu);

	IF count = 0 THEN
		BEGIN
		SetItemCmd	(mainMenu, cmdItem, CHR (noMark));
		SetItemMark (mainMenu, cmdItem, CHR (noMark))
		END

	END;

{*****************************************************************************}

{$S ASelCommand}

FUNCTION IsPlugIn (name: Str255;
				   first: HPlugInInfo;
				   VAR info: HPlugInInfo): BOOLEAN;

	BEGIN

	info := first;

	WHILE info <> NIL DO
		BEGIN

		IF EqualString (name, info^^.fName, TRUE, TRUE) THEN
			BEGIN
			IsPlugIn := TRUE;
			EXIT (IsPlugIn)
			END;

		info := info^^.fNext

		END;

	IsPlugIn := FALSE

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE GetCenterPoint (view: TImageView; VAR center: Point);

	VAR
		r: Rect;

	BEGIN

	view.fFrame.GetViewedRect (r);

	center.h := BSR (ORD4 (r.right) + r.left, 1);
	center.v := BSR (ORD4 (r.bottom) + r.top, 1);

	view.CvtView2Image (center)

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE SetTopLeft (view: TImageView; top, left: INTEGER);

	BEGIN

	SetCtlValue (view.fFrame.fScrollBars [h], left);
	SetCtlValue (view.fFrame.fScrollBars [v], top);

	view.fFrame.ScrlToSBars (TRUE)

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE SetCenterPoint (view: TImageView; center: Point);

	VAR
		r: Rect;
		tl: Point;

	BEGIN

	tl := center;

	view.CvtImage2View (tl, kRoundDown);

	r := view.fFrame.fContentRect;

	tl.h := tl.h - BSR (r.right - r.left, 1);
	tl.v := tl.v - BSR (r.bottom - r.top, 1);

	SetTopLeft (view, tl.v, tl.h)

	END;

{*****************************************************************************}

{$S ADoCommand}

FUNCTION MakeMonochromeArray (rArray, gArray, bArray: TVMArray): TVMArray;

	VAR
		rPtr: Ptr;
		gPtr: Ptr;
		bPtr: Ptr;
		mPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		mArray: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		IF rPtr <> NIL THEN rArray.DoneWithPtr;
		IF gPtr <> NIL THEN gArray.DoneWithPtr;
		IF bPtr <> NIL THEN bArray.DoneWithPtr;

		rArray.Flush;
		gArray.Flush;
		bArray.Flush;

		mArray.Free

		END;

	BEGIN

	mArray := NewVMArray (rArray.fBlockCount, rArray.fLogicalSize, 1);

	CatchFailures (fi, CleanUp);

	FOR row := 0 TO mArray.fBlockCount - 1 DO
		BEGIN

		UpdateProgress (row, mArray.fBlockCount);

		rPtr := NIL;
		gPtr := NIL;
		bPtr := NIL;

		rPtr := rArray.NeedPtr (row, row, FALSE);
		gPtr := gArray.NeedPtr (row, row, FALSE);
		bPtr := bArray.NeedPtr (row, row, FALSE);
		mPtr := mArray.NeedPtr (row, row, TRUE);

		DoMakeMonochrome (rPtr, gGrayLUT.R,
						  gPtr, gGrayLUT.G,
						  bPtr, gGrayLUT.B,
						  mPtr, mArray.fLogicalSize);

		rArray.DoneWithPtr;
		gArray.DoneWithPtr;
		bArray.DoneWithPtr;
		mArray.DoneWithPtr

		END;

	UpdateProgress (1, 1);

	Success (fi);

	rArray.Flush;
	gArray.Flush;
	bArray.Flush;
	mArray.Flush;

	MakeMonochromeArray := mArray;

	END;

{*****************************************************************************}

{$S ADoCommand}

FUNCTION CopyHalftoneRect (srcBuffer: TVMArray;
						   r: Rect;
						   depth: INTEGER): TVMArray;

	VAR
		dr: Rect;
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		map: TLookUpTable;
		rowBytes: INTEGER;
		dstBuffer: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF srcPtr <> NIL THEN srcBuffer.DoneWithPtr;
		srcBuffer.Flush;
		dstBuffer.Free
		END;

	BEGIN

	{$IFC qDebug}
	IF (depth <> 1) AND (depth <> 8) THEN
		ProgramBreak ('Bad depth passed to CopyHalftoneRect');
	{$ENDC}

	IF depth = 8 THEN
		rowBytes := r.right - r.left
	ELSE
		rowBytes := BSL (BSR (r.right - r.left + 15, 4), 1);

	dstBuffer := NewVMArray (r.bottom - r.top, rowBytes, 1);

	CatchFailures (fi, CleanUp);

	dr		  := r;
	dr.top	  := 0;
	dr.bottom := 1;

	FOR row := r.top TO r.bottom - 1 DO
		BEGIN

		srcPtr := NIL;
		srcPtr := srcBuffer.NeedPtr (row, row, FALSE);

		dstPtr := dstBuffer.NeedPtr (row - r.top, row - r.top, TRUE);

		DoHalftone (srcPtr, 0, dstPtr, rowBytes, depth, dr, 1);

		srcBuffer.DoneWithPtr;
		dstBuffer.DoneWithPtr

		END;

	srcPtr := NIL;

	srcBuffer.Flush;
	dstBuffer.Flush;

	IF depth = 8 THEN
		BEGIN
		map [0] := CHR (255);
		map [1] := CHR (  0);
		dstBuffer.MapBytes (map)
		END;

	Success (fi);

	CopyHalftoneRect := dstBuffer

	END;

{*****************************************************************************}

{$S ASelCommand}

PROCEDURE TBufferCommand.IBufferCommand (itsCommand: INTEGER;
										 view: TImageView);

	VAR
		channel: INTEGER;

	BEGIN

	fView := view;
	fDoc  := TImageDocument (view.fDocument);

	FOR channel := 0 TO kMaxChannels - 1 DO
		fBuffer [channel] := NIL;

	ICommand (itsCommand)

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TBufferCommand.Free; OVERRIDE;

	VAR
		channel: INTEGER;

	BEGIN

	FOR channel := 0 TO kMaxChannels - 1 DO
		FreeObject (fBuffer [channel]);

	INHERITED Free

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TBufferCommand.SwapAllChannels;

	VAR
		save: TVMArray;
		channel: INTEGER;

	BEGIN

	FOR channel := 0 TO fDoc.fChannels - 1 DO
		BEGIN
		save				 := fBuffer    [channel];
		fBuffer    [channel] := fDoc.fData [channel];
		fDoc.fData [channel] := save
		END

	END;

{*****************************************************************************}

{$S ASelCommand}

PROCEDURE TFloatCommand.IFloatCommand (itsCommand: INTEGER;
									   view: TImageView);

	VAR
		channel: INTEGER;

	BEGIN

	fSwapMask := FALSE;

	fFloatMask := NIL;

	FOR channel := 0 TO 2 DO
		BEGIN
		fFloatData	[channel] := NIL;
		fFloatBelow [channel] := NIL
		END;

	IBufferCommand (itsCommand, view);

	fWasFloating := fDoc.fSelectionFloating AND
					NOT fDoc.fExactFloat AND
					(fDoc.fFloatChannel = view.fChannel);

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TFloatCommand.Free; OVERRIDE;

	VAR
		channel: INTEGER;

	BEGIN

	FreeObject (fFloatMask);

	FOR channel := 0 TO 2 DO
		BEGIN
		FreeObject (fFloatData	[channel]);
		FreeObject (fFloatBelow [channel])
		END;

	IF fDoc.fFloatCommand = SELF THEN
		BEGIN

		fDoc.fFloatCommand := NIL;

		IF NOT fDoc.fSelectionFloating OR fDoc.fExactFloat THEN
			fDoc.FreeFloat

		END;

	INHERITED Free

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TFloatCommand.SwapFloat;

	VAR
		saveRect: Rect;
		channel: INTEGER;
		saveExact: BOOLEAN;
		saveArray: TVMArray;

	BEGIN

	saveExact		 := fDoc.fExactFloat;
	fDoc.fExactFloat := fExactFloat;
	fExactFloat 	 := saveExact;

	saveRect		:= fDoc.fFloatRect;
	fDoc.fFloatRect := fFloatRect;
	fFloatRect		:= saveRect;

	IF (fFloatMask <> NIL) OR fSwapMask THEN
		BEGIN
		saveArray		:= fDoc.fFloatMask;
		fDoc.fFloatMask := fFloatMask;
		fFloatMask		:= saveArray
		END;

	FOR channel := 0 TO 2 DO
		BEGIN

		IF fFloatData [channel] <> NIL THEN
			BEGIN
			saveArray				  := fDoc.fFloatData [channel];
			fDoc.fFloatData [channel] := fFloatData 	 [channel];
			fFloatData		[channel] := saveArray
			END;

		IF fFloatBelow [channel] <> NIL THEN
			BEGIN
			saveArray				   := fDoc.fFloatBelow [channel];
			fDoc.fFloatBelow [channel] := fFloatBelow	   [channel];
			fFloatBelow 	 [channel] := saveArray
			END

		END

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TFloatCommand.MakeMapLegal (VAR map: TLookUpTable);

	VAR
		gray: INTEGER;

	BEGIN

	IF fDoc.fMode = IndexedColorMode THEN
		FOR gray := 0 TO 255 DO
			IF ORD (map [gray]) >= 128 THEN
				map [gray] := CHR (255)
			ELSE
				map [gray] := CHR (0)

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TFloatCommand.FloatSelection (duplicate: BOOLEAN);

	VAR
		r: Rect;
		fi: FailInfo;
		row: INTEGER;
		page: INTEGER;
		width: INTEGER;
		height: INTEGER;
		channel: INTEGER;
		map: TLookUpTable;
		channels: INTEGER;
		aVMArray: TVMArray;
		bVMArray: TVMArray;
		cVMArray: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		fDoc.FreeFloat
		END;

	BEGIN

	IF fWasFloating THEN
		BEGIN
		fDoc.fFloatCommand := SELF;
		EXIT (FloatSelection)
		END;

	fDoc.FreeFloat;

	CatchFailures (fi, CleanUp);

	r := fDoc.fSelectionRect;

	width  := r.right - r.left;
	height := r.bottom - r.top;

	fDoc.fSelectionFloating := TRUE;
	fDoc.fExactFloat		:= NOT duplicate;
	fDoc.fFloatCommand		:= SELF;
	fDoc.fFloatChannel		:= fView.fChannel;
	fDoc.fFloatRect 		:= r;

	IF fDoc.fSelectionMask <> NIL THEN
		BEGIN
		aVMArray := fDoc.fSelectionMask.CopyArray (1);
		fDoc.fFloatMask := aVMArray
		END;

	IF fDoc.fFloatChannel = kRGBChannels THEN
		channels := 3
	ELSE
		channels := 1;

	FOR channel := 0 TO channels - 1 DO
		BEGIN
		aVMArray := NewVMArray (height, width, 1);
		fDoc.fFloatBelow [channel] := aVMArray
		END;

	FOR channel := 0 TO channels - 1 DO
		BEGIN

		IF channels = 3 THEN
			aVMArray := fDoc.fData [channel] .
						CopyRect (r, channels - channel)
		ELSE
			aVMArray := fDoc.fData [fDoc.fFloatChannel] .
						CopyRect (r, channels - channel);

		fDoc.fFloatData [channel] := aVMArray;

		bVMArray := fDoc.fFloatBelow [channel];

		IF duplicate THEN
			aVMArray.MoveArray (bVMArray)

		ELSE
			BEGIN

			bVMArray.SetBytes (fView.BackgroundByte (channel));

			cVMArray := fDoc.fFloatMask;

			IF cVMArray <> NIL THEN
				BEGIN

				map := gInvertLUT;

				MakeMapLegal (map);

				FOR row := 0 TO height - 1 DO
					BEGIN

					BlockMove (cVMArray.NeedPtr (row, row, FALSE),
							   gBuffer,
							   width);

					DoMapBytes (gBuffer, width, map);

					DoBlendBelow (gBuffer,
								  aVMArray.NeedPtr (row, row, FALSE),
								  bVMArray.NeedPtr (row, row, TRUE),
								  width,
								  0,
								  -1);

					aVMArray.DoneWithPtr;
					bVMArray.DoneWithPtr;
					cVMArray.DoneWithPtr

					END;

				aVMArray.Flush;
				bVMArray.Flush;
				cVMArray.Flush

				END

			END

		END;

	Success (fi)

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TFloatCommand.ComputeOverlap (VAR r: Rect);

	BEGIN

	r := fDoc.fFloatRect;

	fDoc.SectBoundsRect (r)

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TFloatCommand.CopyOverlapArea (into: BOOLEAN;
										 buffer: TVMArray;
										 image: TVMArray);

	VAR
		r1: Rect;
		r2: Rect;

	BEGIN

	IF into THEN
		buffer.Undefine
	ELSE
		buffer.Preload (2);

	ComputeOverlap (r1);

	r2 := r1;
	OffsetRect (r2, -fDoc.fFloatRect.left, -fDoc.fFloatRect.top);

	IF into THEN
		image.MoveRect (buffer, r1, r2)
	ELSE
		buffer.MoveRect (image, r2, r1)

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TFloatCommand.CopyOverlapAreas (into: BOOLEAN;
										  buffer0: TVMArray;
										  buffer1: TVMArray;
										  buffer2: TVMArray);

	BEGIN

	IF fDoc.fFloatChannel = kRGBChannels THEN
		BEGIN
		CopyOverlapArea (into, buffer0, fDoc.fData [0]);
		CopyOverlapArea (into, buffer1, fDoc.fData [1]);
		CopyOverlapArea (into, buffer2, fDoc.fData [2])
		END

	ELSE
		CopyOverlapArea (into, buffer0, fDoc.fData [fDoc.fFloatChannel])

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TFloatCommand.CopyBelow (into: BOOLEAN);

	BEGIN

	CopyOverlapAreas (into, fDoc.fFloatBelow [0],
							fDoc.fFloatBelow [1],
							fDoc.fFloatBelow [2])

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE GetPasteControls (doc: TImageDocument;
							VAR controls: TPasteControls);

	VAR
		band: INTEGER;

	BEGIN

	IF doc.fPasteControls <> NIL THEN
		controls := HPasteControls (doc.fPasteControls)^^

	ELSE
		WITH controls DO
			BEGIN
			FOR band := 0 TO 3 DO
				BEGIN
				fSrcMin [band] := 0;
				fSrcMax [band] := 255;
				fDstMin [band] := 0;
				fDstMax [band] := 255
				END;
			fMode  := PasteNormal;
			fBlend := 100;
			fFuzz  := 0;
			fMat   := -1
			END

	END;

{*****************************************************************************}

{$S ADoCommand}

FUNCTION BuildMaskLUT (VAR map: TLookUpTable;
					  lower: INTEGER;
					  upper: INTEGER;
					  fuzz: INTEGER): BOOLEAN;

	VAR
		g1: INTEGER;
		g2: INTEGER;
		g3: INTEGER;
		gap: INTEGER;
		gray: INTEGER;
		ignore: BOOLEAN;

	BEGIN

	IF upper >= lower THEN
		BEGIN

		DoSetBytes (@map, 256, 255);

		gap := fuzz + 1;

		IF lower <> 0 THEN
			BEGIN

			g1 := lower - BSR (gap + 1, 1);
			g2 := lower + BSR (gap	  , 1);

			FOR gray := 0 TO g2 - 1 DO
				IF gray <= g1 THEN
					map [gray] := CHR (0)
				ELSE
					map [gray] := CHR (255 * (gray - g1) DIV gap)

			END;

		IF upper <> 255 THEN
			BEGIN

			g1 := upper - BSR (gap	  , 1);
			g2 := upper + BSR (gap + 1, 1);

			FOR gray := g1 + 1 TO 255 DO
				IF gray >= g2 THEN
					map [gray] := CHR (0)
				ELSE
					BEGIN
					g3 := 255 * (g2 - gray) DIV gap;
					IF ORD (map [gray]) > g3 THEN
						map [gray] := CHR (g3)
					END

			END

		END

	ELSE
		BEGIN

		ignore := BuildMaskLUT (map, upper, lower, fuzz);

		DoMapBytes (@map, 256, gInvertLUT)

		END;

	BuildMaskLUT := (lower <> 0) OR (upper <> 255)

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TFloatCommand.BlendFloatSingle (srcArray: TVMArray;
										  dstArray: TVMArray;
										  maskArray: TVMArray;
										  alphaArray: TVMArray;
										  r1: Rect;
										  r2: Rect;
										  canAbort: BOOLEAN);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row1: INTEGER;
		row2: INTEGER;
		band: INTEGER;
		width: INTEGER;
		map: TLookUpTable;
		temp: TLookUpTable;
		useSrcMask: BOOLEAN;
		useDstMask: BOOLEAN;
		srcMask: TLookUpTable;
		dstMask: TLookUpTable;
		controls: TPasteControls;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		IF srcPtr <> NIL THEN srcArray.DoneWithPtr;
		IF dstPtr <> NIL THEN dstArray.DoneWithPtr;

		srcArray.Flush;
		dstArray.Flush;

		IF maskArray <> NIL THEN maskArray.Flush;

		IF alphaArray <> NIL THEN alphaArray.Flush

		END;

	BEGIN

	GetPasteControls (fDoc, controls);

	MakeRamp (map, (255 * controls.fBlend + 50) DIV 100);

	MakeMapLegal (map);

	IF fDoc.fMode = IndexedColorMode THEN
		BEGIN

		useSrcMask := FALSE;
		useDstMask := FALSE;

		DoSetBytes (@srcMask, SIZEOF (TLookUpTable), 255);
		DoSetBytes (@dstMask, SIZEOF (TLookUpTable), 255);

		FOR band := 0 TO 3 DO
			BEGIN

			IF BuildMaskLUT (temp,
							 controls.fSrcMin [band],
							 controls.fSrcMax [band], 0) THEN
				BEGIN

				IF band = 0 THEN
					ZapMaskRGB (@fDoc.fIndexedColorTable.R,
								@fDoc.fIndexedColorTable.G,
								@fDoc.fIndexedColorTable.B,
								gGrayLUT,
								@srcMask,
								SIZEOF (TLookUpTable),
								temp)

				ELSE
					ZapMaskLUT (Ptr (ORD4 (@fDoc.fIndexedColorTable) +
									 SIZEOF (TLookUpTable) * (band - 1)),
								@srcMask,
								SIZEOF (TLookUpTable),
								temp);

				useSrcMask := TRUE

				END;

			IF BuildMaskLUT (temp,
							 controls.fDstMin [band],
							 controls.fDstMax [band], 0) THEN
				BEGIN

				IF band = 0 THEN
					ZapMaskRGB (@fDoc.fIndexedColorTable.R,
								@fDoc.fIndexedColorTable.G,
								@fDoc.fIndexedColorTable.B,
								gGrayLUT,
								@dstMask,
								SIZEOF (TLookUpTable),
								temp)

				ELSE
					ZapMaskLUT (Ptr (ORD4 (@fDoc.fIndexedColorTable) +
									 SIZEOF (TLookUpTable) * (band - 1)),
								@dstMask,
								SIZEOF (TLookUpTable),
								temp);

				useDstMask := TRUE

				END

			END

		END

	ELSE
		BEGIN

		useSrcMask := BuildMaskLUT (srcMask,
									controls.fSrcMin [0],
									controls.fSrcMax [0],
									controls.fFuzz);

		useDstMask := BuildMaskLUT (dstMask,
									controls.fDstMin [0],
									controls.fDstMax [0],
									controls.fFuzz)

		END;

	IF maskArray = NIL THEN
		srcArray.PreLoad (2)
	ELSE
		BEGIN
		srcArray.PreLoad (3);
		maskArray.PreLoad (3)
		END;

	CatchFailures (fi, CleanUp);

	width := r1.right - r1.left;

	FOR row1 := r1.top TO r1.bottom - 1 DO
		BEGIN

		row2 := row1 - r1.top + r2.top;

		srcPtr := NIL;
		dstPtr := NIL;

		MoveHands (canAbort);

		srcPtr := Ptr (ORD4 (srcArray.NeedPtr (row1, row1, FALSE)) +
					   r1.left);

		dstPtr := Ptr (ORD4 (dstArray.NeedPtr (row2, row2, TRUE)) +
					   r2.left);

		IF maskArray <> NIL THEN
			BEGIN
			BlockMove (Ptr (ORD4 (maskArray.NeedPtr (row1, row1, FALSE)) +
							r1.left),
					   gBuffer,
					   width);
			maskArray.DoneWithPtr
			END
		ELSE
			DoSetBytes (gBuffer, width, 255);

		IF alphaArray <> NIL THEN
			BEGIN
			DoMinBytes (Ptr (ORD4 (alphaArray.NeedPtr (row2, row2, FALSE)) +
							 r2.left),
						gBuffer,
						gBuffer,
						width);
			alphaArray.DoneWithPtr
			END;

		IF useSrcMask THEN
			ZapMaskLUT (srcPtr, gBuffer, width, srcMask);

		IF useDstMask THEN
			ZapMaskLUT (dstPtr, gBuffer, width, dstMask);

		DoMapBytes (gBuffer, width, map);

		DoBlendBelow (gBuffer,
					  srcPtr,
					  dstPtr,
					  width,
					  ORD (controls.fMode),
					  controls.fMat);

		srcArray.DoneWithPtr;
		dstArray.DoneWithPtr

		END;

	Success (fi);

	srcArray.Flush;
	dstArray.Flush;

	IF maskArray <> NIL THEN
		maskArray.Flush;

	IF alphaArray <> NIL THEN
		alphaArray.Flush

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TFloatCommand.BlendFloatRGB (src1Array: TVMArray;
									   src2Array: TVMArray;
									   src3Array: TVMArray;
									   dst1Array: TVMArray;
									   dst2Array: TVMArray;
									   dst3Array: TVMArray;
									   maskArray: TVMArray;
									   alphaArray: TVMArray;
									   r1: Rect;
									   r2: Rect;
									   canAbort: BOOLEAN);

	VAR
		fi: FailInfo;
		src1Ptr: Ptr;
		src2Ptr: Ptr;
		src3Ptr: Ptr;
		dst1Ptr: Ptr;
		dst2Ptr: Ptr;
		dst3Ptr: Ptr;
		row1: INTEGER;
		row2: INTEGER;
		band: INTEGER;
		width: INTEGER;
		buffer: Handle;
		map: TLookUpTable;
		controls: TPasteControls;
		useSrcMask: ARRAY [0..3] OF BOOLEAN;
		useDstMask: ARRAY [0..3] OF BOOLEAN;
		srcMask: ARRAY [0..3] OF TLookUpTable;
		dstMask: ARRAY [0..3] OF TLookUpTable;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN

		IF src1Ptr <> NIL THEN src1Array.DoneWithPtr;
		IF src2Ptr <> NIL THEN src2Array.DoneWithPtr;
		IF src3Ptr <> NIL THEN src3Array.DoneWithPtr;

		IF dst1Ptr <> NIL THEN dst1Array.DoneWithPtr;
		IF dst2Ptr <> NIL THEN dst2Array.DoneWithPtr;
		IF dst3Ptr <> NIL THEN dst3Array.DoneWithPtr;

		src1Array.Flush;
		src2Array.Flush;
		src3Array.Flush;

		dst1Array.Flush;
		dst2Array.Flush;
		dst3Array.Flush;

		IF maskArray <> NIL THEN maskArray.Flush;

		IF alphaArray <> NIL THEN alphaArray.Flush;

		FreeLargeHandle (buffer)

		END;

	BEGIN

	GetPasteControls (fDoc, controls);

	MakeRamp (map, (255 * controls.fBlend + 50) DIV 100);

	IF maskArray = NIL THEN
		BEGIN
		src1Array.PreLoad (6);
		src2Array.PreLoad (6);
		src3Array.PreLoad (6)
		END
	ELSE
		BEGIN
		src1Array.PreLoad (7);
		src2Array.PreLoad (7);
		src3Array.PreLoad (7);
		maskArray.PreLoad (7)
		END;

	FOR band := 0 TO 3 DO
		BEGIN

		useSrcMask [band] := BuildMaskLUT (srcMask [band],
										   controls.fSrcMin [band],
										   controls.fSrcMax [band],
										   controls.fFuzz);

		useDstMask [band] := BuildMaskLUT (dstMask [band],
										   controls.fDstMin [band],
										   controls.fDstMax [band],
										   controls.fFuzz)

		END;

	width := r1.right - r1.left;

	IF controls.fMode = PasteColorOnly THEN
		buffer := NewLargeHandle (width)
	ELSE
		buffer := NIL;

	CatchFailures (fi, CleanUp);

	FOR row1 := r1.top TO r1.bottom - 1 DO
		BEGIN

		row2 := row1 - r1.top + r2.top;

		src1Ptr := NIL;
		src2Ptr := NIL;
		src3Ptr := NIL;

		dst1Ptr := NIL;
		dst2Ptr := NIL;
		dst3Ptr := NIL;

		MoveHands (canAbort);

		src1Ptr := Ptr (ORD4 (src1Array.NeedPtr (row1, row1, FALSE)) +
						r1.left);
		src2Ptr := Ptr (ORD4 (src2Array.NeedPtr (row1, row1, FALSE)) +
						r1.left);
		src3Ptr := Ptr (ORD4 (src3Array.NeedPtr (row1, row1, FALSE)) +
						r1.left);

		dst1Ptr := Ptr (ORD4 (dst1Array.NeedPtr (row2, row2, TRUE)) +
						r2.left);
		dst2Ptr := Ptr (ORD4 (dst2Array.NeedPtr (row2, row2, TRUE)) +
						r2.left);
		dst3Ptr := Ptr (ORD4 (dst3Array.NeedPtr (row2, row2, TRUE)) +
						r2.left);

		IF maskArray <> NIL THEN
			BEGIN
			BlockMove (Ptr (ORD4 (maskArray.NeedPtr (row1, row1, FALSE)) +
							r1.left),
					   gBuffer,
					   width);
			maskArray.DoneWithPtr
			END
		ELSE
			DoSetBytes (gBuffer, width, 255);

		IF alphaArray <> NIL THEN
			BEGIN
			DoMinBytes (Ptr (ORD4 (alphaArray.NeedPtr (row2, row2, FALSE)) +
							 r2.left),
						gBuffer,
						gBuffer,
						width);
			alphaArray.DoneWithPtr
			END;

		IF useSrcMask [0] THEN
			ZapMaskRGB (src1Ptr, src2Ptr, src3Ptr, gGrayLUT,
						gBuffer, width, srcMask [0]);

		IF useSrcMask [1] THEN
			ZapMaskLUT (src1Ptr, gBuffer, width, srcMask [1]);

		IF useSrcMask [2] THEN
			ZapMaskLUT (src2Ptr, gBuffer, width, srcMask [2]);

		IF useSrcMask [3] THEN
			ZapMaskLUT (src3Ptr, gBuffer, width, srcMask [3]);

		IF useDstMask [0] THEN
			ZapMaskRGB (dst1Ptr, dst2Ptr, dst3Ptr, gGrayLUT,
						gBuffer, width, dstMask [0]);

		IF useDstMask [1] THEN
			ZapMaskLUT (dst1Ptr, gBuffer, width, dstMask [1]);

		IF useDstMask [2] THEN
			ZapMaskLUT (dst2Ptr, gBuffer, width, dstMask [2]);

		IF useDstMask [3] THEN
			ZapMaskLUT (dst3Ptr, gBuffer, width, dstMask [3]);

		DoMapBytes (gBuffer, width, map);

		IF controls.fMode = PasteColorOnly THEN
			DoMakeMonochrome (dst1Ptr, gGrayLUT.R,
							  dst2Ptr, gGrayLUT.G,
							  dst3Ptr, gGrayLUT.B,
							  buffer^, width);

		DoBlendBelow (gBuffer,
					  src1Ptr,
					  dst1Ptr,
					  width,
					  ORD (controls.fMode),
					  controls.fMat);

		DoBlendBelow (gBuffer,
					  src2Ptr,
					  dst2Ptr,
					  width,
					  ORD (controls.fMode),
					  controls.fMat);

		DoBlendBelow (gBuffer,
					  src3Ptr,
					  dst3Ptr,
					  width,
					  ORD (controls.fMode),
					  controls.fMat);

		IF controls.fMode = PasteColorOnly THEN
			DoBlendColorOnly (buffer^,
							  dst1Ptr,
							  dst2Ptr,
							  dst3Ptr,
							  gGrayLUT,
							  width);

		src1Array.DoneWithPtr;
		src2Array.DoneWithPtr;
		src3Array.DoneWithPtr;

		dst1Array.DoneWithPtr;
		dst2Array.DoneWithPtr;
		dst3Array.DoneWithPtr

		END;

	Success (fi);

	src1Array.Flush;
	src2Array.Flush;
	src3Array.Flush;

	dst1Array.Flush;
	dst2Array.Flush;
	dst3Array.Flush;

	IF maskArray <> NIL THEN
		maskArray.Flush;

	IF alphaArray <> NIL THEN
		alphaArray.Flush;

	FreeLargeHandle (buffer)

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TFloatCommand.BlendFloat (canAbort: BOOLEAN);

	VAR
		r1: Rect;
		r2: Rect;

	BEGIN

	MoveHands (canAbort);

	IF fDoc.fExactFloat OR (fDoc.fFloatMask = NIL) AND
						   (fDoc.fFloatAlpha = NIL) AND
						   (fDoc.fPasteControls = NIL) THEN

		CopyOverlapAreas (FALSE, fDoc.fFloatData [0],
								 fDoc.fFloatData [1],
								 fDoc.fFloatData [2])

	ELSE
		BEGIN

		ComputeOverlap (r2);

		IF NOT EmptyRect (r2) THEN
			BEGIN

			r1 := r2;

			OffsetRect (r1, -fDoc.fFloatRect.left, -fDoc.fFloatRect.top);

			IF fDoc.fFloatChannel = kRGBChannels THEN
				BlendFloatRGB (fDoc.fFloatData [0],
							   fDoc.fFloatData [1],
							   fDoc.fFloatData [2],
							   fDoc.fData [0],
							   fDoc.fData [1],
							   fDoc.fData [2],
							   fDoc.fFloatMask,
							   fDoc.fFloatAlpha,
							   r1, r2, canAbort)
			ELSE
				BlendFloatSingle (fDoc.fFloatData [0],
								  fDoc.fData [fDoc.fFloatChannel],
								  fDoc.fFloatMask,
								  fDoc.fFloatAlpha,
								  r1, r2, canAbort)

			END

		END

	END;

{*****************************************************************************}

{$S ADoCommand}

FUNCTION TFloatCommand.CanSelect (VAR r: Rect; VAR mask: TVMArray): OSErr;

	VAR
		mr: Rect;
		fi: FailInfo;
		gray: INTEGER;
		hist: THistogram;
		overlap: BOOLEAN;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		CanSelect := error;
		EXIT (CanSelect)
		END;

	BEGIN

	mask := NIL;
	ComputeOverlap (r);

	CatchFailures (fi, CleanUp);

	IF NOT EmptyRect (r) AND (fDoc.fFloatMask <> NIL) THEN

		IF EqualRect (r, fDoc.fFloatRect) THEN
			mask := fDoc.fFloatMask.CopyArray (1)

		ELSE
			BEGIN

			mr := r;
			OffsetRect (mr, -fDoc.fFloatRect.left,
							-fDoc.fFloatRect.top);

			fDoc.fFloatMask.HistRect (mr, hist);

			overlap := FALSE;
			FOR gray := 128 TO 255 DO
				overlap := overlap OR (hist [gray] <> 0);

			IF overlap THEN
				BEGIN

				fDoc.fFloatMask.FindInnerBounds (mr);
				mask := fDoc.fFloatMask.CopyRect (mr, 1);

				r := mr;
				OffsetRect (r, fDoc.fFloatRect.left,
							   fDoc.fFloatRect.top)

				END

			ELSE
				r := gZeroRect

			END;

	Success (fi);

	CanSelect := noErr

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TFloatCommand.SelectFloat;

	VAR
		r: Rect;
		mask: TVMArray;

	BEGIN

	IF CanSelect (r, mask) = noErr THEN
		BEGIN
		fDoc.Select (r, mask);
		fDoc.fSelectionFloating := NOT EmptyRect (r)
		END

	END;

{*****************************************************************************}

{$S ADoCommand}

PROCEDURE TFloatCommand.UpdateRects (r1, r2: Rect; highlight: BOOLEAN);

	VAR
		r3: Rect;

	BEGIN

	IF NOT EmptyRect (r1) AND
	   NOT EmptyRect (r2) AND SectRect (r1, r2, r3) THEN
		BEGIN
		UnionRect (r1, r2, r3);
		fDoc.UpdateImageArea (r3, highlight, TRUE, fDoc.fFloatChannel)
		END

	ELSE
		BEGIN
		fDoc.UpdateImageArea (r1, highlight, TRUE, fDoc.fFloatChannel);
		fDoc.UpdateImageArea (r2, highlight, TRUE, fDoc.fFloatChannel)
		END

	END;

{Photoshop version 1.0.1, file: UPICTResource.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$S AInit}

PROCEDURE TPICTResourceFormat.IImageFormat; OVERRIDE;

	BEGIN

	INHERITED IImageFormat;

	fReadType1	  := 'SCRN';
	fReadType2	  := 'PCT0';
	fReadType3	  := 'gray';
	fFileType	  := 'SCRN';
	fUsesDataFork := FALSE;
	fUsesRsrcFork := TRUE;

	fDialogID	  := 2100;
	fFTypeItem	  := 4;
	fFCreatorItem := 5;
	fRadio1Item   := 6;
	fInts		  := 1;
	fInt1Item	  := 13;
	fStrs		  := 1;
	fStr1Item	  := 14;

	fInt1Lower := -32768;
	fInt1Upper :=  32767;

	fResID := 0

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TPICTResourceFormat.SetFormatOptions (doc: TImageDocument); OVERRIDE;

	VAR
		s: Str255;

	BEGIN

	s := gReply.fName;

	fInt1 := fResID;
	fStr1 := @s;

	INHERITED SetFormatOptions (doc);

	fResID	 := fInt1;
	fResName := s;

	fUsesRsrcFork := TRUE

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TPICTResourceFormat.ConvertPICT (thePICT: Handle;
										   doc: TImageDocument);

	BEGIN

	fSpool			  := TRUE;
	fSpoolData		  := thePICT;
	fSpoolPosition	  := 0;
	fSpoolEOFPosition := GetHandleSize (thePICT);

	DoReadPICT (doc, FALSE)

	END;

{*****************************************************************************}

{$S AReadFile}

PROCEDURE TPICTResourceFormat.DoRead (doc: TImageDocument;
									  refNum: INTEGER;
									  rsrcExists: BOOLEAN); OVERRIDE;

	VAR
		err: OSErr;
		fi: FailInfo;
		size: LONGINT;
		thePICT: Handle;

	PROCEDURE CleanUp (error: OSErr; message: LONGINT);
		BEGIN
		VMAdjustReserve (-size);
		DisposHandle (thePICT)
		END;

	BEGIN

	IF NOT rsrcExists THEN
		Failure (errNoPICTResource, 0);

	IF Count1Resources ('PICT') < 1 THEN
		Failure (errNoPICTResource, 0);

	SetResLoad (FALSE);

	thePICT := Get1IndResource ('PICT', 1);
	err := ResError;

	SetResLoad (TRUE);

	FailOSErr (err);

	IF thePICT = NIL THEN
		Failure (errNoPICTResource, 0);

	size := SizeResource (thePICT);

	FailOSErr (ResError);

	DisposHandle (NewLargeHandle (size));

	CatchFailures (fi, CleanUp);

	LoadResource (thePICT);

	FailOSErr (ResError);

	DetachResource (thePICT);

	ConvertPICT (thePICT, doc);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S AWriteFile}

FUNCTION TPICTResourceFormat.MakePICT (doc: TImageDocument): Handle;

	VAR
		fi: FailInfo;
		thePICT: Handle;
		channel: INTEGER;

	PROCEDURE CleanUp (error: OSErr; message: LONGINT);
		BEGIN
		FreeLargeHandle (thePICT)
		END;

	BEGIN

	thePICT := NewLargeHandle (0);

	CatchFailures (fi, CleanUp);

	fSpool			  := TRUE;
	fSpoolData		  := thePICT;
	fSpoolPosition	  := 0;
	fSpoolEOFPosition := 0;

	IF doc.fMode = RGBColorMode THEN
		channel := kRGBChannels
	ELSE
		channel := 0;

	gTables.CompTables (doc, channel, FALSE, fSystemPalette,
						fDepth, fDepth, TRUE, TRUE, 1);

	DoWritePICT (doc);

	ResizeLargeHandle (thePICT, fSpoolEOFPosition);

	Success (fi);

	MakePICT := thePICT

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE TPICTResourceFormat.DoWrite (doc: TImageDocument;
									   refNum: INTEGER); OVERRIDE;

	VAR
		err: OSErr;
		name: Str255;
		thePICT: Handle;

	BEGIN

	thePICT := MakePICT (doc);

	name := fResName;

	AddResource (thePICT, 'PICT', fResID, name);

	err := ResError;

	IF err <> noErr THEN
		BEGIN
		FreeLargeHandle (thePICT);
		FailOSErr (err)
		END
	ELSE
		VMAdjustReserve (-GetHandleSize (thePICT));

	IF gTables.fColorTable <> NIL THEN
		AddPixelPaintStuff

	END;

{*****************************************************************************}

{$S AClipboard}

FUNCTION TClipFormat.MakePICT (doc: TImageDocument): Handle; OVERRIDE;

	BEGIN

	fSystemPalette := FALSE;

		CASE gPreferences.fClipOption OF

		1:	fDepth := 1;

		2:	fDepth := 2;

		3:	fDepth := 4;

		4:	fDepth := 8;

		5:	BEGIN
			fDepth := 8;
			fSystemPalette := TRUE
			END;

		6:	IF doc.fMode = RGBColorMode THEN
				fDepth := 16
			ELSE
				fDepth := 8;

		7:	IF doc.fMode = RGBColorMode THEN
				fDepth := 32
			ELSE
				fDepth := 8

		END;

	MakePICT := INHERITED MakePICT (doc)

	END;

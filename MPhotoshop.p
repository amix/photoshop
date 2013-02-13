{Photoshop version 1.0.1, file: MPhotoshop.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROGRAM Photoshop;

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UPrinting, UDialog;

VAR
	gPhotoshopApplication: TPhotoshopApplication;

{*****************************************************************************}

{$S ARes}

PROCEDURE AResDummy;
	BEGIN
	END;

{*****************************************************************************}

{$S ARes2}

PROCEDURE ARes2Dummy;
	BEGIN
	END;

{*****************************************************************************}

{$S ARes3}

PROCEDURE ARes3Dummy;
	BEGIN
	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE ARes4Dummy;
	BEGIN
	END;

{*****************************************************************************}

{$S AEncoded}

PROCEDURE AEncodedDummy;
	BEGIN
	END;

{*****************************************************************************}

{$S AInit}

PROCEDURE ClaimColorTable;

{ Kludge code, claims colors on the main screen of a Mac II }

	VAR
		size: INTEGER;
		index: INTEGER;
		device: GDHandle;
		saveDevice: GDHandle;

	BEGIN

	IF gConfiguration.hasColorToolbox THEN
		BEGIN

		device := GetMainDevice;

			CASE device^^.gdPMap^^.pixelSize OF

			2:	size := 3;
			4:	size := 15;
			8:	size := 255;

			OTHERWISE
				EXIT (ClaimColorTable)

			END;

		saveDevice := GetGDevice;

		SetGDevice (device);

		FOR index := 0 TO SIZE DO
			BEGIN
			ProtectEntry (index, FALSE);
			ReserveEntry (index, FALSE)
			END;

		SetGDevice (saveDevice)

		END

	END;

{*****************************************************************************}

{$S ATerminate}

PROCEDURE UpdateScreen;

{ Kludge code, force a redraw of the main screen on a Mac II }

	VAR
		wp: WindowPtr;
		ct: CTabHandle;
		depth: INTEGER;
		device: GDHandle;
		saveDevice: GDHandle;

	BEGIN

	IF gConfiguration.hasColorToolbox THEN
		BEGIN

		device := GetMainDevice;

			CASE device^^.gdPMap^^.pixelSize OF

			2:	depth := 2;
			4:	depth := 4;
			8:	depth := 8;

			OTHERWISE
				EXIT (UpdateScreen)

			END;

		ct := GetCTable (depth);

		saveDevice := GetGDevice;

		SetGDevice (device);

		SetEntries (0, ct^^.ctSize, ct^^.ctTable);

		SetGDevice (saveDevice);

		wp := WindowPtr (NewCWindow (NIL, GetGrayRgn^^.rgnBBox, '',
									 FALSE, plainDBox, WindowPtr (-1),
									 FALSE, 0));

		PaintBehind (WindowPeek (wp), GetGrayRgn)

		END

	END;

{*****************************************************************************}

{$S Main}

BEGIN

InitToolbox (8);
InitPrinting;
InitUDialog;

gBuffer := NewPtr (32768);
FailNil (gBuffer);

SetResidentSegment (GetSegNumber (@AResDummy), TRUE);
SetResidentSegment (GetSegNumber (@ARes2Dummy), TRUE);
SetResidentSegment (GetSegNumber (@ARes3Dummy), TRUE);
SetResidentSegment (GetSegNumber (@ARes4Dummy), TRUE);
SetResidentSegment (GetSegNumber (@AEncodedDummy), TRUE);

ClaimColorTable;

NEW (gPhotoshopApplication);
FailNil (gPhotoshopApplication);

gPhotoshopApplication.IPhotoshopApplication;

gPhotoshopApplication.Run;

UpdateScreen

END.

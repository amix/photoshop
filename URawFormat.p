{Photoshop version 1.0.1, file: URawFormat.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT URawFormat;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UBWDialog, URootFormat, UProgress;

TYPE

	TRawFormat = OBJECT (TRootFormat)

		fHeader: LONGINT;

		fInterleaved: BOOLEAN;

		PROCEDURE TRawFormat.IImageFormat; OVERRIDE;

		FUNCTION TRawFormat.CanWrite
				(doc: TImageDocument): BOOLEAN; OVERRIDE;

		PROCEDURE TRawFormat.SetFormatOptions (doc: TImageDocument); OVERRIDE;

		PROCEDURE TRawFormat.DoRead (doc: TImageDocument;
									 refNum: INTEGER;
									 rsrcExists: BOOLEAN); OVERRIDE;

		FUNCTION TRawFormat.DataForkBytes
				(doc: TImageDocument): LONGINT; OVERRIDE;

		PROCEDURE TRawFormat.DoWrite
				(doc: TImageDocument; refNum: INTEGER); OVERRIDE;

		END;

IMPLEMENTATION

{$I URawFormat.inc1.p}

END.

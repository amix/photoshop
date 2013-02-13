{Photoshop version 1.0.1, file: UPixar.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UPixar;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, URootFormat, UProgress;

TYPE

	TPixarFormat = OBJECT (TRootFormat)

		PROCEDURE TPixarFormat.IImageFormat; OVERRIDE;

		FUNCTION TPixarFormat.CanWrite
				(doc: TImageDocument): BOOLEAN; OVERRIDE;

		PROCEDURE TPixarFormat.SetFormatOptions
				(doc: TImageDocument); OVERRIDE;

		PROCEDURE TPixarFormat.DecodeRow (dBytes: INTEGER;
										  pBytes: INTEGER;
										  rBytes: LONGINT;
										  blockSize: INTEGER;
										  buffer: Ptr);

		PROCEDURE TPixarFormat.ReadTile (doc: TImageDocument;
										 rowOffset: INTEGER;
										 colOffset: INTEGER;
										 tileRows: INTEGER;
										 tileCols: INTEGER;
										 storage: INTEGER;
										 blockSize: INTEGER);

		PROCEDURE TPixarFormat.DoRead (doc: TImageDocument;
									   refNum: INTEGER;
									   rsrcExists: BOOLEAN); OVERRIDE;

		FUNCTION TPixarFormat.SaveChannels (doc: TImageDocument): INTEGER;

		FUNCTION TPixarFormat.DataForkBytes
				(doc: TImageDocument): LONGINT; OVERRIDE;

		PROCEDURE TPixarFormat.DoWrite (doc: TImageDocument;
										refNum: INTEGER); OVERRIDE;

		END;

IMPLEMENTATION

{$I UPixar.inc1.p}

END.

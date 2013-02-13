{Photoshop version 1.0.1, file: UGIFFormat.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UGIFFormat;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, URootFormat, ULZWCompress, UProgress;

TYPE

	TGIFFormat = OBJECT (TRootFormat)

		fDepth: INTEGER;

		PROCEDURE TGIFFormat.IImageFormat; OVERRIDE;

		FUNCTION TGIFFormat.CanWrite
				(doc: TImageDocument): BOOLEAN; OVERRIDE;

		PROCEDURE TGIFFormat.SetFormatOptions
				(doc: TImageDocument); OVERRIDE;

		PROCEDURE TGIFFormat.ReadRaster (canAbort: BOOLEAN);

		PROCEDURE TGIFFormat.DoRead
				(doc: TImageDocument;
				 refNum: INTEGER;
				 rsrcExists: BOOLEAN); OVERRIDE;

		PROCEDURE TGIFFormat.WriteRaster (doc: TImageDocument);

		PROCEDURE TGIFFormat.DoWrite
				(doc: TImageDocument; refNum: INTEGER); OVERRIDE;

		END;

IMPLEMENTATION

{$I UGIFFormat.inc1.p}

END.

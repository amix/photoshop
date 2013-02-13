{Photoshop version 1.0.1, file: UPixelPaint.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UPixelPaint;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, URootFormat, UPICTFile, UProgress;

TYPE

	TPixelPaintFormat = OBJECT (TPICTFileFormat)

		fCenter: BOOLEAN;
		fCanvasSize: INTEGER;

		PROCEDURE TPixelPaintFormat.IImageFormat; OVERRIDE;

		FUNCTION TPixelPaintFormat.CanWrite
				(doc: TImageDocument): BOOLEAN; OVERRIDE;

		PROCEDURE TPixelPaintFormat.SetFormatOptions
				(doc: TImageDocument); OVERRIDE;

		PROCEDURE TPixelPaintFormat.ReadRow (cols: INTEGER);

		PROCEDURE TPixelPaintFormat.DoRead
				(doc: TImageDocument;
				 refNum: INTEGER;
				 rsrcExists: BOOLEAN); OVERRIDE;

		FUNCTION TPixelPaintFormat.DataForkBytes
				(doc: TImageDocument): LONGINT; OVERRIDE;

		FUNCTION TPixelPaintFormat.RsrcForkBytes
				(doc: TImageDocument): LONGINT; OVERRIDE;

		PROCEDURE TPixelPaintFormat.DoWriteImage (doc: TImageDocument);

		PROCEDURE TPixelPaintFormat.DoWrite
				(doc: TImageDocument; refNum: INTEGER); OVERRIDE;

		END;

IMPLEMENTATION

{$I UPixelPaint.inc1.p}

END.

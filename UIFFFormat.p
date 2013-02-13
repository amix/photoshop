{Photoshop version 1.0.1, file: UIFFFormat.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UIFFFormat;

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

	TIFFFormat = OBJECT (TRootFormat)

		fDepth: INTEGER;

		PROCEDURE TIFFFormat.IImageFormat; OVERRIDE;

		FUNCTION TIFFFormat.CanWrite
				(doc: TImageDocument): BOOLEAN; OVERRIDE;

		PROCEDURE TIFFFormat.SetFormatOptions
				(doc: TImageDocument); OVERRIDE;

		FUNCTION TIFFFormat.ReadCMap (VAR cMap: TRGBLookUpTable): INTEGER;

		PROCEDURE TIFFFormat.TransCMap (doc: TImageDocument;
										VAR cMap: TRGBLookUpTable;
										nPlanes: INTEGER;
										depth: INTEGER;
										planePick: INTEGER;
										planeOnOff: INTEGER;
										planeMask: INTEGER);

		PROCEDURE TIFFFormat.ReadBody (doc: TImageDocument;
									   nPlanes: INTEGER;
									   masked: BOOLEAN;
									   compressed: BOOLEAN);

		PROCEDURE TIFFFormat.DoRead (doc: TImageDocument;
									 refNum: INTEGER;
									 rsrcExists: BOOLEAN); OVERRIDE;

		PROCEDURE TIFFFormat.WriteBody (doc: TImageDocument;
										bounds: Rect);

		PROCEDURE TIFFFormat.DoWrite (doc: TImageDocument;
									  refNum: INTEGER); OVERRIDE;

		END;

IMPLEMENTATION

{$I UIFFFormat.inc1.p}

END.

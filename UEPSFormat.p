{Photoshop version 1.0.1, file: UEPSFormat.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UEPSFormat;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UBWDialog, UPrinting, UCommands, URootFormat, UPICTFile,
	UPICTResource, UPostScript, UScreen, USeparation, UProgress;

TYPE

	TEPSFormat = OBJECT (TPICTResourceFormat)

		fBinary: BOOLEAN;

		fFiveFiles: BOOLEAN;

		fTransparent: BOOLEAN;

		fIncludeScreen	: BOOLEAN;
		fIncludeTransfer: BOOLEAN;

		fHalftonePreview: INTEGER;
		fOtherPreview	: INTEGER;

		PROCEDURE TEPSFormat.IImageFormat; OVERRIDE;

		FUNCTION TEPSFormat.CanWrite
				(doc: TImageDocument): BOOLEAN; OVERRIDE;

		PROCEDURE TEPSFormat.SetFormatOptions
				(doc: TImageDocument); OVERRIDE;

		PROCEDURE TEPSFormat.GetLine (VAR s: Str255);

		PROCEDURE TEPSFormat.ReadImageData
				(doc: TImageDocument;
				 binary: BOOLEAN;
				 first: INTEGER;
				 count: INTEGER;
				 alpha: INTEGER;
				 invert: BOOLEAN);

		PROCEDURE TEPSFormat.ParseHeader
				(doc: TImageDocument;
				 VAR binary: BOOLEAN;
				 VAR cPlate: Str255;
				 VAR mPlate: Str255;
				 VAR yPlate: Str255;
				 VAR kPlate: Str255;
				 dcsPlate: BOOLEAN);

		PROCEDURE TEPSFormat.ReadPostScript (doc: TImageDocument);

		PROCEDURE TEPSFormat.DoRead
				(doc: TImageDocument;
				 refNum: INTEGER;
				 rsrcExists: BOOLEAN); OVERRIDE;

		FUNCTION TEPSFormat.DataForkBytes
				(doc: TImageDocument): LONGINT; OVERRIDE;

		FUNCTION TEPSFormat.MakePreviewPICT1
				(doc: TImageDocument;
				 newRows: INTEGER;
				 newCols: INTEGER): Handle;

		FUNCTION TEPSFormat.MakePreviewPICT2
				(doc: TImageDocument;
				 newRows: INTEGER;
				 newCols: INTEGER): Handle;

		PROCEDURE TEPSFormat.AddPreviewPICT
				(doc: TImageDocument;
				 newRows: INTEGER;
				 newCols: INTEGER);

		PROCEDURE TEPSFormat.WritePostScript
				(doc: TImageDocument;
				 refNum: INTEGER;
				 channel: INTEGER;
				 dstSize: Point;
				 useDCS: BOOLEAN;
				 depth: INTEGER);

		PROCEDURE TEPSFormat.DoWrite
				(doc: TImageDocument; refNum: INTEGER); OVERRIDE;

		END;

IMPLEMENTATION

{$I UEPSFormat.inc1.p}

END.

{Photoshop version 1.0.1, file: UPICTFile.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UPICTFile;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	QuickDraw32Bit, UDialog, URootFormat, UProgress;

TYPE

	TPICTFileFormat = OBJECT (TRootFormat)

		fDepth: INTEGER;

		fTransferMode: INTEGER;

		fSystemPalette: BOOLEAN;

		fVersion1: BOOLEAN;

		PROCEDURE TPICTFileFormat.IImageFormat; OVERRIDE;

		FUNCTION TPICTFileFormat.CanWrite
				(doc: TImageDocument): BOOLEAN; OVERRIDE;

		PROCEDURE TPICTFileFormat.SetFormatOptions
				(doc: TImageDocument); OVERRIDE;

		PROCEDURE TPICTFileFormat.AdjustRects (doc: TImageDocument;
											   hRes: Fixed;
											   vRes: Fixed;
											   pictBounds: Rect;
											   bounds: Rect;
											   VAR srcRect: Rect;
											   VAR dstRect: Rect);

		PROCEDURE TPICTFileFormat.ParseCopyBits (doc: TImageDocument;
												 opcode: INTEGER;
												 pictBounds: Rect;
												 canAbort: BOOLEAN);

		PROCEDURE TPICTFileFormat.ParseDirectBits (doc: TImageDocument;
												   opcode: INTEGER;
												   pictBounds: Rect;
												   canAbort: BOOLEAN);

		PROCEDURE TPICTFileFormat.ParsePICT (doc: TImageDocument;
											 canAbort: BOOLEAN);

		PROCEDURE TPICTFileFormat.ParseOldPICT (doc: TImageDocument);

		PROCEDURE TPICTFileFormat.ParseNewPICT (doc: TImageDocument);

		PROCEDURE TPICTFileFormat.DoReadPICT (doc: TImageDocument;
											  canAbort: BOOLEAN);

		PROCEDURE TPICTFileFormat.DoRead (doc: TImageDocument;
										  refNum: INTEGER;
										  rsrcExists: BOOLEAN); OVERRIDE;

		PROCEDURE TPICTFileFormat.PutOpcode (opcode: INTEGER);

		PROCEDURE TPICTFileFormat.DoWritePICT (doc: TImageDocument);

		PROCEDURE TPICTFileFormat.AddPixelPaintStuff;

		PROCEDURE TPICTFileFormat.DoWrite (doc: TImageDocument;
										   refNum: INTEGER); OVERRIDE;

		END;

IMPLEMENTATION

{$I UPICTFile.inc1.p}

END.

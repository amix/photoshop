{Photoshop version 1.0.1, file: UPICTResource.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UPICTResource;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, URootFormat, UPICTFile;

TYPE

	TPICTResourceFormat = OBJECT (TPICTFileFormat)

		fResID: INTEGER;
		fResName: Str255;

		PROCEDURE TPICTResourceFormat.IImageFormat; OVERRIDE;

		PROCEDURE TPICTResourceFormat.SetFormatOptions
				(doc: TImageDocument); OVERRIDE;

		PROCEDURE TPICTResourceFormat.ConvertPICT
				(thePICT: Handle; doc: TImageDocument);

		PROCEDURE TPICTResourceFormat.DoRead
				(doc: TImageDocument;
				 refNum: INTEGER;
				 rsrcExists: BOOLEAN); OVERRIDE;

		FUNCTION TPICTResourceFormat.MakePICT
				(doc: TImageDocument): Handle;

		PROCEDURE TPICTResourceFormat.DoWrite
				(doc: TImageDocument; refNum: INTEGER); OVERRIDE;

		END;

	TClipFormat = OBJECT (TPICTResourceFormat)

		FUNCTION TClipFormat.MakePICT
				(doc: TImageDocument): Handle; OVERRIDE;

		END;

VAR
	gClipFormat: TClipFormat;

IMPLEMENTATION

{$I UPICTResource.inc1.p}

END.

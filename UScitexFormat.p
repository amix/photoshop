{Photoshop version 1.0.1, file: UScitexFormat.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UScitexFormat;

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

	TScitexFormat = OBJECT (TRootFormat)

		PROCEDURE TScitexFormat.IImageFormat; OVERRIDE;

		FUNCTION TScitexFormat.CanWrite
				(doc: TImageDocument): BOOLEAN; OVERRIDE;

		PROCEDURE TScitexFormat.DoRead (doc: TImageDocument;
									 refNum: INTEGER;
									 rsrcExists: BOOLEAN); OVERRIDE;

		FUNCTION TScitexFormat.DataForkBytes
				(doc: TImageDocument): LONGINT; OVERRIDE;

		PROCEDURE TScitexFormat.DoWrite
				(doc: TImageDocument; refNum: INTEGER); OVERRIDE;

		END;

IMPLEMENTATION

{$I UScitexFormat.inc1.p}

END.

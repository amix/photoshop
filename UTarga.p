{Photoshop version 1.0.1, file: UTarga.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UTarga;

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

	TTargaFormat = OBJECT (TRootFormat)

		fDepth: INTEGER;

		PROCEDURE TTargaFormat.IImageFormat; OVERRIDE;

		FUNCTION TTargaFormat.CanWrite
				(doc: TImageDocument): BOOLEAN; OVERRIDE;

		PROCEDURE TTargaFormat.SetFormatOptions
				(doc: TImageDocument); OVERRIDE;

		PROCEDURE TTargaFormat.DoRead (doc: TImageDocument;
									   refNum: INTEGER;
									   rsrcExists: BOOLEAN); OVERRIDE;

		FUNCTION TTargaFormat.DataForkBytes
				(doc: TImageDocument): LONGINT; OVERRIDE;

		PROCEDURE TTargaFormat.DoWrite (doc: TImageDocument;
										refNum: INTEGER); OVERRIDE;

		END;

IMPLEMENTATION

{$I UTarga.inc1.p}

END.

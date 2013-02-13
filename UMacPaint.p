{Photoshop version 1.0.1, file: UMacPaint.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UMacPaint;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, URootFormat, UCommands, UProgress;

TYPE

	TMacPaintFormat = OBJECT (TRootFormat)

		fCenter: BOOLEAN;

		PROCEDURE TMacPaintFormat.IImageFormat; OVERRIDE;

		FUNCTION TMacPaintFormat.CanWrite
				(doc: TImageDocument): BOOLEAN; OVERRIDE;

		PROCEDURE TMacPaintFormat.SetFormatOptions
				(doc: TImageDocument); OVERRIDE;

		PROCEDURE TMacPaintFormat.DoRead
				(doc: TImageDocument;
				 refNum: INTEGER;
				 rsrcExists: BOOLEAN); OVERRIDE;

		PROCEDURE TMacPaintFormat.DoWrite
				(doc: TImageDocument; refNum: INTEGER); OVERRIDE;

		END;

IMPLEMENTATION

{$I UMacPaint.inc1.p}

END.

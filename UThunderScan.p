{Photoshop version 1.0.1, file: UThunderScan.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UThunderScan;

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

	TThunderScanFormat = OBJECT (TRootFormat)

		fDepth: INTEGER;

		PROCEDURE TThunderScanFormat.IImageFormat; OVERRIDE;

		FUNCTION TThunderScanFormat.CanWrite
				(doc: TImageDocument): BOOLEAN; OVERRIDE;

		PROCEDURE TThunderScanFormat.SetFormatOptions
				(doc: TImageDocument); OVERRIDE;

		PROCEDURE TThunderScanFormat.ReadSCANLine
				(doc: TImageDocument;
				 row: INTEGER);

		PROCEDURE TThunderScanFormat.DoRead
				(doc: TImageDocument;
				 refNum: INTEGER;
				 rsrcExists: BOOLEAN); OVERRIDE;

		FUNCTION TThunderScanFormat.DataForkBytes
				(doc: TImageDocument): LONGINT; OVERRIDE;

		PROCEDURE TThunderScanFormat.DoWrite
				(doc: TImageDocument; refNum: INTEGER); OVERRIDE;

		END;

IMPLEMENTATION

{$I UThunderScan.inc1.p}

END.

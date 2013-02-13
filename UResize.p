{Photoshop version 1.0.1, file: UResize.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UResize;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UBWDialog, UCommands, UProgress;

TYPE

	TWordArray = ARRAY [0..kMaxCoord-1] OF INTEGER;
	PWordArray = ^TWordArray;
	HWordArray = ^PWordArray;

	TByteArray = PACKED ARRAY [0..kMaxCoord-1] OF CHAR;
	PByteArray = ^TByteArray;
	HByteArray = ^PByteArray;

	TResizeMode = (ResizeModeSample,
				   ResizeModeInterpolate,
				   ResizeModeBiCubic,
				   ResizeModeBigAverage,
				   ResizeModeAverage);

	TResizeTable = OBJECT (TObject)

		fOldSize: INTEGER;
		fNewSize: INTEGER;

		fMode: TResizeMode;

		fTable1: HWordArray;
		fTable2: HByteArray;

		fTotalWeight: INTEGER;

		PROCEDURE TResizeTable.IResizeTable (oldSize: INTEGER;
											 newSize: INTEGER;
											 sample: BOOLEAN);

		PROCEDURE TResizeTable.Free; OVERRIDE;

		PROCEDURE TResizeTable.ResizeLine (srcPtr, dstPtr: Ptr);

		END;

	TResizeCommand = OBJECT (TBufferCommand)

		fNewRows: INTEGER;
		fNewCols: INTEGER;

		fSameSize: BOOLEAN;

		fVPlacement: INTEGER;
		fHPlacement: INTEGER;

		fOldStyle: TStyleInfo;
		fNewStyle: TStyleInfo;

		PROCEDURE TResizeCommand.IResizeCommand (itsCommand: INTEGER;
												 view: TImageView;
												 newRows: INTEGER;
												 newCols: INTEGER;
												 vPlacement: INTEGER;
												 hPlacement: INTEGER);

		PROCEDURE TResizeCommand.CopyPart (image: TVMArray;
										   buffer: TVMArray;
										   background: INTEGER);

		PROCEDURE TResizeCommand.DoIt; OVERRIDE;

		PROCEDURE TResizeCommand.UndoIt; OVERRIDE;

		PROCEDURE TResizeCommand.RedoIt; OVERRIDE;

		END;

PROCEDURE InitResize;

PROCEDURE DoResizeArray (srcArray: TVMArray;
						 dstArray: TVMArray;
						 hTable: TResizeTable;
						 vTable: TResizeTable;
						 canAbort: BOOLEAN);

PROCEDURE ResizeArray (srcArray: TVMArray;
					   dstArray: TVMArray;
					   sample: BOOLEAN;
					   canAbort: BOOLEAN);

FUNCTION DoResizeImage (view: TImageView): TCommand;

FUNCTION DoResampleImage (view: TImageView): TCommand;

IMPLEMENTATION

{$I UResize.inc1.p}

END.

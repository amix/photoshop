{Photoshop version 1.0.1, file: UScreen.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UScreen;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UBWDialog, UCommands, UResize, UProgress;

CONST
	kMaxCellSize = 256;

TYPE

	TLSDialog = OBJECT (TBWDialog)

		fLoadTitle1: Str255;
		fSaveTitle1: Str255;

		fLoadTitle2: Str255;
		fSaveTitle2: Str255;

		fOptionDown: BOOLEAN;

		fLoadButton: ControlHandle;
		fSaveButton: ControlHandle;

		PROCEDURE TLSDialog.ILSDialog (dialogID: INTEGER;
									   loadItem: INTEGER;
									   saveItem: INTEGER);

		PROCEDURE TLSDialog.UpdateButtons;

		FUNCTION TLSDialog.DoSetCursor
				(localPoint: Point): BOOLEAN; OVERRIDE;

		END;

PROCEDURE InitScreens;

PROCEDURE RegisterSpot (h: Handle);

PROCEDURE MarkSpotDirty;

PROCEDURE CollectSpotGarbage;

PROCEDURE SetHalftoneScreen (VAR spec: THalftoneSpec;
							 allowCustom: BOOLEAN);

PROCEDURE SetHalftoneScreens (VAR specs: THalftoneSpecs;
							  allowCustom: BOOLEAN);

PROCEDURE MakeScreen (limit: INTEGER;
					  resolution: Fixed;
					  spec: THalftoneSpec;
					  VAR cellData: Handle;
					  VAR cellSize: INTEGER);

FUNCTION ConvertScreen (cellData: Handle; cellSize: INTEGER): TVMArray;

PROCEDURE HalftoneArea (srcArray: TVMArray;
						dstArray: TVMArray;
						r: Rect;
						newRows: INTEGER;
						newCols: INTEGER;
						map: PLookUpTable;
						screen: TVMArray;
						canAbort: BOOLEAN);

IMPLEMENTATION

{$I UScreen.inc1.p}

END.

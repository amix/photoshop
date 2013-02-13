{Photoshop version 1.0.1, file: USeparation.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT USeparation;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	PickerIntf, UDialog, UBWDialog, UCommands, UAdjust, UProgress;

TYPE

	TBlackPopUp = OBJECT (TPopUpMenu)

		fUseGCR: BOOLEAN;

		fCmdPick: INTEGER;

		PROCEDURE TBlackPopUp.IBlackPopUp (itsLabelNumber: INTEGER;
										   itsItemNumber: INTEGER;
										   itsParent: TDialogView);

		FUNCTION TBlackPopUp.DoPopUpMenu
				(optionDown: BOOLEAN): BOOLEAN; OVERRIDE;

		END;

	TSeparationDialog = OBJECT (TBWDialog)

		fSetup: TSeparationSetup;

		fPalette: PaletteHandle;

		fColorItems: INTEGER;

		fColorRect: ARRAY [1..kProgressive] OF Rect;

		fScreenColor: ARRAY [1..kProgressive] OF RGBColor;

		fColorPercent: ARRAY [1..kProgressive] OF TFixedText;

		fGamma: TFixedText;

		fInkMaximum: TFixedText;
		
		fUCAPercent: TFixedText;

		fBlackPopUp: TBlackPopUp;

		fLastGamma: INTEGER;

		PROCEDURE TSeparationDialog.ISeparationDialog
				(VAR setup: TSeparationSetup);

		PROCEDURE TSeparationDialog.Free; OVERRIDE;

		PROCEDURE TSeparationDialog.StuffValues;

		PROCEDURE TSeparationDialog.UpdatePalette;

		PROCEDURE TSeparationDialog.DrawAmendments
				(theItem: INTEGER); OVERRIDE;

		FUNCTION TSeparationDialog.DoItemSelected
				(anItem: INTEGER;
				 VAR handledIt: BOOLEAN;
				 VAR doneWithDialog: BOOLEAN): TCommand; OVERRIDE;

		PROCEDURE TSeparationDialog.Validate
				(VAR succeeded: BOOLEAN); OVERRIDE;

		END;

PROCEDURE InitSeparation;

PROCEDURE GetBlackTables (VAR gcrTable: TLookUpTable;
						  VAR ucrTable: TLookUpTable;
						  id: INTEGER);

PROCEDURE InitCMYK;

PROCEDURE SolveForCMYK (r: INTEGER;
						g: INTEGER;
						b: INTEGER;
						VAR c: INTEGER;
						VAR m: INTEGER;
						VAR y: INTEGER;
						VAR k: INTEGER;
						VAR inside: BOOLEAN);

PROCEDURE SolveForCMY (r: INTEGER;
					   g: INTEGER;
					   b: INTEGER;
					   VAR c: INTEGER;
					   VAR m: INTEGER;
					   VAR y: INTEGER);

PROCEDURE SolveForRGB (c: INTEGER;
					   m: INTEGER;
					   y: INTEGER;
					   k: INTEGER;
					   VAR r: INTEGER;
					   VAR g: INTEGER;
					   VAR b: INTEGER);

FUNCTION CvtToPercent (gray: INTEGER): INTEGER;

FUNCTION CvtFromPercent (percent: INTEGER): INTEGER;

PROCEDURE DoSeparationSetup (VAR setup: TSeparationSetup);

PROCEDURE SeparateColorLUT (LUT: TRGBLookUpTable;
							VAR map1: TLookUpTable;
							VAR map2: TLookUpTable;
							VAR map3: TLookUpTable;
							VAR map4: TLookUpTable);

PROCEDURE BuildSeparationTable;

PROCEDURE ConvertRGB2CMYK (srcArray1: TVMArray;
						   srcArray2: TVMArray;
						   srcArray3: TVMArray;
						   dstArray1: TVMArray;
						   dstArray2: TVMArray;
						   dstArray3: TVMArray;
						   dstArray4: TVMArray);

PROCEDURE ConvertRGB2CMY (srcArray1: TVMArray;
						  srcArray2: TVMArray;
						  srcArray3: TVMArray;
						  dstArray1: TVMArray;
						  dstArray2: TVMArray;
						  dstArray3: TVMArray);

PROCEDURE ConvertCMYK2RGB (srcArray1: TVMArray;
						   srcArray2: TVMArray;
						   srcArray3: TVMArray;
						   srcArray4: TVMArray;
						   dstArray1: TVMArray;
						   dstArray2: TVMArray;
						   dstArray3: TVMArray);

PROCEDURE ConvertCMYK2Gray (srcArray1: TVMArray;
							srcArray2: TVMArray;
							srcArray3: TVMArray;
							srcArray4: TVMArray;
							dstArray: TVMArray);

IMPLEMENTATION

{$I USeparation.inc1.p}

END.

{Photoshop version 1.0.1, file: UAdjust.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UAdjust;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	VideoIntf, UDialog, UBWDialog, UCommands, UProgress;

CONST
	kMaxSliders = 6;

TYPE

	TAdjustmentCommand = OBJECT (TFloatCommand)

		fChannel: INTEGER;

		fWholeImage: BOOLEAN;

		fAllocated: BOOLEAN;
		fPreviewed: BOOLEAN;

		fUsingBuffers: BOOLEAN;

		fMonochromeLUT: TLookUpTable;

		fIndexedColorTable: TRGBLookUpTable;

		PROCEDURE TAdjustmentCommand.IAdjustmentCommand (itsCommand: INTEGER;
														 view: TImageView);

		PROCEDURE TAdjustmentCommand.GetParameters;

		PROCEDURE TAdjustmentCommand.MapMonochrome (dataPtr: Ptr;
													count: INTEGER);

		PROCEDURE TAdjustmentCommand.MapRGB (rPtr, gPtr, bPtr: Ptr;
											 count: INTEGER);

		PROCEDURE TAdjustmentCommand.MakeMonochromeLUT;

		PROCEDURE TAdjustmentCommand.AllocateBuffers;

		PROCEDURE TAdjustmentCommand.MapBuffers;

		PROCEDURE TAdjustmentCommand.ExchangeBuffers;

		PROCEDURE TAdjustmentCommand.ShowBuffers (checkSelection: BOOLEAN);

		PROCEDURE TAdjustmentCommand.SaveState;

		FUNCTION TAdjustmentCommand.SameState: BOOLEAN;

		PROCEDURE TAdjustmentCommand.DoPreview;

		PROCEDURE TAdjustmentCommand.Free; OVERRIDE;

		PROCEDURE TAdjustmentCommand.DoIt; OVERRIDE;

		PROCEDURE TAdjustmentCommand.UndoIt; OVERRIDE;

		PROCEDURE TAdjustmentCommand.RedoIt; OVERRIDE;

		END;

	TInvertCommand = OBJECT (TAdjustmentCommand)

		PROCEDURE TInvertCommand.MapMonochrome (dataPtr: Ptr;
												count: INTEGER); OVERRIDE;

		END;

	TEqualizeCommand = OBJECT (TAdjustmentCommand)

		fLUT: TLookUpTable;

		PROCEDURE TEqualizeCommand.GetParameters; OVERRIDE;

		PROCEDURE TEqualizeCommand.MapMonochrome (dataPtr: Ptr;
												  count: INTEGER); OVERRIDE;

		END;

	PPoint = ^Point;

	TFeedbackDialog = OBJECT (TBWDialog)

		fView: TImageView;
		fCommand: TAdjustmentCommand;
		fLocation: PPoint;

		fPreviewButton: INTEGER;

		fFeedbackDevice: GDHandle;
		fSaveDevice: GDHandle;

		fFeedbackDepth: INTEGER;

		fLastPoint: BOOLEAN;
		fShiftDown: BOOLEAN;
		fOptionDown: BOOLEAN;

		fUsingNewColors: BOOLEAN;

		fOldColors: cSpecArray;
		fPad1	  : ARRAY [1..255] OF ColorSpec;

		fNewColors: cSpecArray;
		fPad2	  : ARRAY [1..255] OF ColorSpec;

		PROCEDURE TFeedbackDialog.IFeedbackDialog
				(view: TImageView;
				 command: TAdjustmentCommand;
				 location: PPoint;
				 itsRsrcID: INTEGER;
				 itsHookItem: INTEGER;
				 itsDfltButton: INTEGER;
				 itsPreviewButton: INTEGER);

		PROCEDURE TFeedbackDialog.NextMousePoint (VAR pt: Point);

		FUNCTION TFeedbackDialog.DownInDialog (mousePt: Point): BOOLEAN;

		PROCEDURE TFeedbackDialog.PrepareMap (forFeedback: BOOLEAN);

		PROCEDURE TFeedbackDialog.GetOldColors;

		PROCEDURE TFeedbackDialog.GetNewColors;

		PROCEDURE TFeedbackDialog.SetScreenColors (VAR colors: cSpecArray);

		PROCEDURE TFeedbackDialog.SetNewColors;

		PROCEDURE TFeedbackDialog.SetOldColors;

		FUNCTION TFeedbackDialog.DoSetCursor
				(localPoint: Point): BOOLEAN; OVERRIDE;

		FUNCTION TFeedbackDialog.IsSafeButton (item: INTEGER): BOOLEAN;

		PROCEDURE TFeedbackDialog.DoFilterEvent
				(VAR anEvent: EventRecord;
				 VAR itemHit: INTEGER;
				 VAR handledIt: BOOLEAN;
				 VAR doReturn: BOOLEAN); OVERRIDE;

		PROCEDURE TFeedbackDialog.DoFeedback;

		PROCEDURE TFeedbackDialog.DoTalkToUser
				(PROCEDURE HandleSelectedItem
				 (anItem: INTEGER; VAR done: BOOLEAN));

		END;

	THistDialog = OBJECT (TFeedbackDialog)

		fHistRect: Rect;

		fHist: THistogram;

		PROCEDURE THistDialog.IHistDialog (command: TAdjustmentCommand;
										   location: PPoint;
										   hist: THistogram;
										   itsRsrcID: INTEGER;
										   itsHookItem: INTEGER;
										   itsHistItem: INTEGER;
										   itsDfltButton: INTEGER;
										   itsPreviewButton: INTEGER);

		PROCEDURE THistDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

		END;

	TThresholdDialog = OBJECT (THistDialog)

		fLevel: INTEGER;

		fLevelRect: Rect;
		fPointerRect: Rect;

		PROCEDURE TThresholdDialog.IThresholdDialog
				(command: TThresholdCommand; hist: THistogram);

		PROCEDURE TThresholdDialog.DrawLevel;

		PROCEDURE TThresholdDialog.DrawAmendments
				(theItem: INTEGER); OVERRIDE;

		PROCEDURE TThresholdDialog.PrepareMap (forFeedback: BOOLEAN); OVERRIDE;

		FUNCTION TThresholdDialog.DownInDialog
				(mousePt: Point): BOOLEAN; OVERRIDE;

		END;

	TThresholdCommand = OBJECT (TAdjustmentCommand)

		fThreshold: INTEGER;

		fPreviewThreshold: INTEGER;

		PROCEDURE TThresholdCommand.SaveState; OVERRIDE;

		FUNCTION TThresholdCommand.SameState: BOOLEAN; OVERRIDE;

		PROCEDURE TThresholdCommand.GetParameters; OVERRIDE;

		PROCEDURE TThresholdCommand.MapRGB (rPtr, gPtr, bPtr: Ptr;
											count: INTEGER); OVERRIDE;

		END;

	TPosterizeDialog = OBJECT (TFeedbackDialog)

		fLevelsText: TFixedText;

		PROCEDURE TPosterizeDialog.IPosterizeDialog
				(command: TPosterizeCommand);

		PROCEDURE TPosterizeDialog.PrepareMap (forFeedback: BOOLEAN); OVERRIDE;

		END;

	TPosterizeCommand = OBJECT (TAdjustmentCommand)

		fLUT: TLookUpTable;

		fPreviewLUT: TLookUpTable;

		PROCEDURE TPosterizeCommand.SaveState; OVERRIDE;

		FUNCTION TPosterizeCommand.SameState: BOOLEAN; OVERRIDE;

		PROCEDURE TPosterizeCommand.GetParameters; OVERRIDE;

		PROCEDURE TPosterizeCommand.MapMonochrome (dataPtr: Ptr;
												   count: INTEGER); OVERRIDE;

		END;

	TSlidersDialog = OBJECT (TFeedbackDialog)

		fSliders: INTEGER;
		fBlackOnes: INTEGER;

		fRange: INTEGER;

		fLevel: ARRAY [1..kMaxSliders] OF INTEGER;

		fScaleRect: ARRAY [1..kMaxSliders] OF Rect;
		fLevelRect: ARRAY [1..kMaxSliders] OF Rect;
		fPointerRect: ARRAY [1..kMaxSliders] OF Rect;

		fMinValue: ARRAY [1..kMaxSliders] OF INTEGER;
		fMaxValue: ARRAY [1..kMaxSliders] OF INTEGER;

		fSignedValue: ARRAY [1..kMaxSliders] OF BOOLEAN;

		PROCEDURE TSlidersDialog.ISlidersDialog (command: TAdjustmentCommand;
												 location: PPoint;
												 dialogID: INTEGER;
												 sliders: INTEGER;
												 blackOnes: INTEGER);

		FUNCTION TSlidersDialog.GetValue (which: INTEGER): INTEGER;

		PROCEDURE TSlidersDialog.DrawLevel (which: INTEGER);

		PROCEDURE TSlidersDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

		FUNCTION TSlidersDialog.DownInDialog
				(mousePt: Point): BOOLEAN; OVERRIDE;

		END;

	TBrightnessDialog = OBJECT (TSlidersDialog)

		fMean: INTEGER;

		PROCEDURE TBrightnessDialog.IBrightnessDialog
				(command: TBrightnessCommand; mean: INTEGER);

		PROCEDURE TBrightnessDialog.PrepareMap
				(forFeedback: BOOLEAN); OVERRIDE;

		END;

	TBrightnessCommand = OBJECT (TAdjustmentCommand)

		fLUT: TLookUpTable;

		fPreviewLUT: TLookUpTable;

		PROCEDURE TBrightnessCommand.SaveState; OVERRIDE;

		FUNCTION TBrightnessCommand.SameState: BOOLEAN; OVERRIDE;

		PROCEDURE TBrightnessCommand.GetParameters; OVERRIDE;

		PROCEDURE TBrightnessCommand.MapMonochrome
				(dataPtr: Ptr; count: INTEGER); OVERRIDE;

		END;

	TBalanceDialog = OBJECT (TFeedbackDialog)

		fBand: INTEGER;

		fRange: INTEGER;

		fScaleRect: ARRAY [1..3] OF Rect;
		fLevelRect: ARRAY [1..3] OF Rect;
		fPointerRect: ARRAY [1..3] OF Rect;

		fLevel: ARRAY [1..3, 1..3] OF INTEGER;

		PROCEDURE TBalanceDialog.IBalanceDialog (command: TBalanceCommand);

		PROCEDURE TBalanceDialog.DrawLevel (which: INTEGER);

		PROCEDURE TBalanceDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

		FUNCTION TBalanceDialog.DownInDialog
				(mousePt: Point): BOOLEAN; OVERRIDE;

		PROCEDURE TBalanceDialog.PrepareMap (forFeedback: BOOLEAN); OVERRIDE;

		END;

	TBalanceCommand = OBJECT (TAdjustmentCommand)

		fLUT: TRGBLookUpTable;

		fPreviewLUT: TRGBLookUpTable;

		PROCEDURE TBalanceCommand.SaveState; OVERRIDE;

		FUNCTION TBalanceCommand.SameState: BOOLEAN; OVERRIDE;

		PROCEDURE TBalanceCommand.GetParameters; OVERRIDE;

		PROCEDURE TBalanceCommand.MapRGB (rPtr, gPtr, bPtr: Ptr;
										  count: INTEGER); OVERRIDE;

		END;

	TLookUpTables = ARRAY [0..3] OF TLookUpTable;

	TMapArbitraryDialog = OBJECT (TFeedbackDialog)

		fMapRect: Rect;

		fActiveArea: Rect;

		fXLevel: INTEGER;
		fYLevel: INTEGER;

		fXLevelRect: Rect;
		fYLevelRect: Rect;

		fPrevPoint: Point;

		fIsColor: BOOLEAN;

		fBand: INTEGER;

		fSmoothCount: INTEGER;

		fLUT: TLookUpTables;

		PROCEDURE TMapArbitraryDialog.IMapArbitraryDialog
				(command: TMapArbitraryCommand);

		PROCEDURE TMapArbitraryDialog.MarkRulers;

		PROCEDURE TMapArbitraryDialog.DrawLevels;

		PROCEDURE TMapArbitraryDialog.UpdateLevels (pt: Point);

		PROCEDURE TMapArbitraryDialog.DrawMap;

		PROCEDURE TMapArbitraryDialog.DrawAmendments
				(theItem: INTEGER); OVERRIDE;

		PROCEDURE TMapArbitraryDialog.PrepareMap
				(forFeedback: BOOLEAN); OVERRIDE;

		FUNCTION TMapArbitraryDialog.DoSetCursor
				(localPoint: Point): BOOLEAN; OVERRIDE;

		FUNCTION TMapArbitraryDialog.DownInDialog
				(mousePt: Point): BOOLEAN; OVERRIDE;

		PROCEDURE TMapArbitraryDialog.DoLoadMap;

		PROCEDURE TMapArbitraryDialog.DoSaveMap;

		FUNCTION TMapArbitraryDialog.IsSafeButton
				(item: INTEGER): BOOLEAN; OVERRIDE;

		PROCEDURE TMapArbitraryDialog.DoButtonPushed
				(anItem: INTEGER; VAR succeeded: BOOLEAN); OVERRIDE;

		END;

	TMapArbitraryCommand = OBJECT (TBalanceCommand)

		PROCEDURE TMapArbitraryCommand.GetParameters; OVERRIDE;

		END;

	TFiveLevels = RECORD

		fBLevel: INTEGER;
		fGLevel: INTEGER;
		fWLevel: INTEGER;
		fLLevel: INTEGER;
		fHLevel: INTEGER;

		fGamma: INTEGER;
		fFraction: Fixed

		END;

	TLevelsDialog = OBJECT (THistDialog)

		fBRect: Rect;
		fGRect: Rect;
		fWRect: Rect;
		fLRect: Rect;
		fHRect: Rect;

		fOutputRect: Rect;

		fInLevelsRect: Rect;
		fOutLevelsRect: Rect;

		fBand: INTEGER;

		fLevels: ARRAY [0..3] OF TFiveLevels;

		fLUT: ARRAY [0..3] OF TLookUpTable;

		PROCEDURE TLevelsDialog.ILevelsDialog (command: TLevelsCommand;
											   hist: THistogram);

		PROCEDURE TLevelsDialog.DrawInputLevels;

		PROCEDURE TLevelsDialog.DrawOutputLevels;

		PROCEDURE TLevelsDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

		PROCEDURE TLevelsDialog.PrepareMap (forFeedback: BOOLEAN); OVERRIDE;

		PROCEDURE TLevelsDialog.DoSetLevel (which, what: INTEGER);

		FUNCTION TLevelsDialog.DownInDialog
				(mousePt: Point): BOOLEAN; OVERRIDE;

		END;

	TLevelsCommand = OBJECT (TBalanceCommand)

		PROCEDURE TLevelsCommand.GetParameters; OVERRIDE;

		END;

	TSaturationDialog = OBJECT (TSlidersDialog)

		fColorize: BOOLEAN;

		PROCEDURE TSaturationDialog.ISaturationDialog
				(command: TSaturationCommand);

		PROCEDURE TSaturationDialog.PrepareMap
				(forFeedback: BOOLEAN); OVERRIDE;

		END;

	TSaturationCommand = OBJECT (TAdjustmentCommand)

		fHueLUT: TLookUpTable;
		fSatLUT: TLookUpTable;

		fPreviewHue: TLookUpTable;
		fPreviewSat: TLookUpTable;

		PROCEDURE TSaturationCommand.SaveState; OVERRIDE;

		FUNCTION TSaturationCommand.SameState: BOOLEAN; OVERRIDE;

		PROCEDURE TSaturationCommand.GetParameters; OVERRIDE;

		PROCEDURE TSaturationCommand.MapRGB (rPtr, gPtr, bPtr: Ptr;
											 count: INTEGER); OVERRIDE;

		END;

VAR
	gBPointer: BitMap;
	gGPointer: BitMap;
	gWPointer: BitMap;

	gPtrWidth: INTEGER;

	gAdjustCommand: TAdjustmentCommand;

PROCEDURE InitAdjustments;

PROCEDURE DrawNumber (n: LONGINT; r: Rect);

PROCEDURE SetGammaTable (VAR LUT: TLookUpTable; g: INTEGER);

PROCEDURE SmoothLUT (VAR LUT: TLookUpTable;
					 radius, passes: INTEGER;
					 wrap: BOOLEAN);

FUNCTION LoadMapFile (VAR maps: TLookUpTables; isColor: BOOLEAN): BOOLEAN;

PROCEDURE SaveMapFile (VAR maps: TLookUpTables; promptID: INTEGER);

FUNCTION DoInvertCommand (view: TImageView): TCommand;

FUNCTION DoEqualizeCommand (view: TImageView): TCommand;

FUNCTION DoThresholdCommand (view: TImageView): TCommand;

FUNCTION DoPosterizeCommand (view: TImageView): TCommand;

FUNCTION DoMapArbitraryCommand (view: TImageView): TCommand;

FUNCTION DoBrightnessCommand (view: TImageView): TCommand;

FUNCTION DoBalanceCommand (view: TImageView): TCommand;

FUNCTION DoLevelsCommand (view: TImageView): TCommand;

FUNCTION DoSaturationCommand (view: TImageView): TCommand;

IMPLEMENTATION

{$I UAdjust.inc1.p}

END.

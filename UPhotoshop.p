{Photoshop version 1.0.1, file: UPhotoshop.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UPhotoshop;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD}
	PaletteMgr, QuickDraw32Bit, SysEqu, Traps, UPrinting,
	UPatch, UDialog, UConstants, UVMemory, UBWDialog, UProgress;

CONST

	kMaxChannels  = 16; 		{ Maximum number of channels per image }

	kRGBChannels  = -1; 		{ Means all three RGB channels }
	kMaskChannel  = -2; 		{ Means the selection mask channel }
	kDummyChannel = -3; 		{ Means a new image }
	kCMYKChannels = -4; 		{ Means all four CMYK channels }

	kRoundUp	  = TRUE;		{ Round coordinates up }
	kRoundDown	  = FALSE;		{ Round coordinates down }

	kMarqueeWidth = 1;			{ Width of marquee tool highlighting }

	kHLPatterns   = 8;			{ Number of patterns in highlight set }
	kHLDelay	  = 3;			{ Tick count between highlight changes }

	kProgressive  = 7;			{ Number of progressive colors }

	kRulerWidth   = 15; 		{ Width of rulers in pixels }

TYPE

	TPhotoshopApplication = OBJECT (TApplication)

		PROCEDURE TPhotoshopApplication.IPhotoshopApplication;

		PROCEDURE TPhotoshopApplication.Terminate; OVERRIDE;

		PROCEDURE TPhotoshopApplication.ShowError
				(error: OSErr; message: LONGINT); OVERRIDE;

		PROCEDURE TPhotoshopApplication.MainEventLoop; OVERRIDE;

		FUNCTION TPhotoshopApplication.GetEvent
				(eventMask: INTEGER;
				 VAR anEvent: EventRecord): BOOLEAN; OVERRIDE;

		PROCEDURE TPhotoshopApplication.DoTrackCursor
				(mousePt: Point;
				 spaceDown: BOOLEAN;
				 shiftDown: BOOLEAN;
				 optionDown: BOOLEAN;
				 commandDown: BOOLEAN);

		PROCEDURE TPhotoshopApplication.TrackCursor; OVERRIDE;

		FUNCTION TPhotoshopApplication.ObeyMouseDown
				(whereMouseDown: INTEGER;
				 aWmgrWindow: WindowPtr;
				 nextEvent: PEventRecord): TCommand; OVERRIDE;

		PROCEDURE TPhotoshopApplication.SpaceIsLow; OVERRIDE;

		PROCEDURE TPhotoshopApplication.OpenNew
				(itsCmdNumber: CmdNumber); OVERRIDE;

		FUNCTION TPhotoshopApplication.CanOpenDocument
				(itsCmdNumber: CmdNumber;
				 VAR anAppFile: AppFile): BOOLEAN; OVERRIDE;

		FUNCTION TPhotoshopApplication.AlreadyOpen
				(fileName: Str255; volRefnum: INTEGER): TDocument; OVERRIDE;

		PROCEDURE TPhotoshopApplication.SFGetParms
				(itsCmdNumber: CmdNumber;
				 VAR dlgID: INTEGER;
				 VAR where: Point;
				 VAR fileFilter, dlgHook, filterProc: ProcPtr;
				 typeList: HTypeList); OVERRIDE;

		FUNCTION TPhotoshopApplication.ChooseDocument
				(itsCmdNumber: CmdNumber;
				 VAR anAppFile: AppFile): BOOLEAN; OVERRIDE;

		FUNCTION TPhotoshopApplication.DoMakeDocument
				(itsCmdNumber: CmdNumber): TDocument; OVERRIDE;

		PROCEDURE TPhotoshopApplication.CloseDocument
				(docToClose: TDocument); OVERRIDE;

		PROCEDURE TPhotoshopApplication.AboutToLoseControl
				(convertClipboard: BOOLEAN); OVERRIDE;

		PROCEDURE TPhotoshopApplication.RegainControl
				(checkClipboard: BOOLEAN); OVERRIDE;

		FUNCTION TPhotoshopApplication.MakeViewForAlienClipboard: TView;
				OVERRIDE;

		PROCEDURE TPhotoshopApplication.DoIdle (phase: IdlePhase); OVERRIDE;

		PROCEDURE TPhotoshopApplication.SetUndoText
				(cmdDone: BOOLEAN; aCmdNumber: CmdNumber); OVERRIDE;

		PROCEDURE TPhotoshopApplication.DoSetupMenus; OVERRIDE;

		FUNCTION TPhotoshopApplication.DoMenuCommand
				(aCmdNumber: CmdNumber): TCommand; OVERRIDE;

		FUNCTION TPhotoshopApplication.DoKeyCommand
				(ch: CHAR;
				 aKeyCode: INTEGER;
				 VAR info: EventInfo): TCommand; OVERRIDE;

		FUNCTION TPhotoshopApplication.CommandKey
				(ch: CHAR;
				 aKeyCode: INTEGER;
				 VAR info: EventInfo): TCommand; OVERRIDE;

		END;

	TChannelArrayList = ARRAY [0..kMaxChannels-1] OF TVMArray;

	TRGBArrayList = ARRAY [0..2] OF TVMArray;

	TCornerList = ARRAY [0..3] OF Point;

	FixedScaled = RECORD
		value: Fixed;
		scale: INTEGER
		END;

	THalftoneSpec = RECORD
		frequency : FixedScaled;
		angle	  : Fixed;
		shape	  : INTEGER;
		spot	  : Handle
		END;

	THalftoneSpecs = ARRAY [0..3] OF THalftoneSpec;

	TTransferSpec = ARRAY [0..4] OF INTEGER;

	TTransferSpecs = ARRAY [0..3] OF TTransferSpec;

	TStyleInfo = RECORD

		{ Printing resolution }
		fResolution: FixedScaled;
		fWidthUnit : INTEGER;
		fHeightUnit: INTEGER;

		{ Image gamma value }
		fGamma: INTEGER;

		{ Monochrome halftone screen }
		fHalftoneSpec: THalftoneSpec;

		{ Monochrome transfer function }
		fTransferSpec: TTransferSpec;

		{ Color halftone screens }
		fHalftoneSpecs: THalftoneSpecs;

		{ Color transfer functions }
		fTransferSpecs: TTransferSpecs;

		{ Printing options }
		fCropMarks		  : BOOLEAN;
		fRegistrationMarks: BOOLEAN;
		fLabel			  : BOOLEAN;
		fColorBars		  : BOOLEAN;
		fNegative		  : BOOLEAN;
		fFlip			  : BOOLEAN;
		fBorder 		  : FixedScaled;
		fCaption		  : Str255

		END;

	TImageDocument = OBJECT (TDocument)

		{ Size of image }
		fRows: INTEGER;
		fCols: INTEGER;

		{ Bits per pixel }
		fDepth: INTEGER;

		{ Number of channels }
		fChannels: INTEGER;

		{ Display mode }
		fMode: TDisplayMode;

		{ Indexed color table }
		fIndexedColorTable: TRGBLookUpTable;

		{ Information on the color table }
		fTableItem: INTEGER;

		{ Virtual memory arrays holding each channel }
		fData: TChannelArrayList;

		{ Rulers zero point }
		fRulerOrigin: Point;

		{ The bounding box of the selected rectangle }
		fSelectionRect: Rect;

		{ Virtual memory array holding selection mask }
		fSelectionMask: TVMArray;

		{ Is the selection floating? }
		fSelectionFloating: BOOLEAN;

		{ Does the floating data equal that below? }
		fExactFloat: BOOLEAN;

		{ Command using float, if any }
		fFloatCommand: TCommand;

		{ Channel number that is floating }
		fFloatChannel: INTEGER;

		{ Floating area bounds }
		fFloatRect: Rect;

		{ Floating mask, if any }
		fFloatMask: TVMArray;

		{ Floating image }
		fFloatData: TRGBArrayList;

		{ Area below float in image }
		fFloatBelow: TRGBArrayList;

		{ Alpha channel for floating selection, if any }
		fFloatAlpha: TVMArray;

		{ Paste controls setting }
		fPasteControls: Handle;

		{ What effect is current, if any }
		fEffectMode: INTEGER;

		{ On what channel is the effect }
		fEffectChannel: INTEGER;

		{ Command doing the effect, if any }
		fEffectCommand: TCommand;

		{ List of corners to highlight if fEffectMode <> 0 }
		fEffectCorners: TCornerList;

		{ Was the image imported }
		fImported: BOOLEAN;

		{ Have there been any changes since disk version? }
		fMasterChanges: BOOLEAN;

		{ The format the image was read from }
		fFormatCode: INTEGER;

		{ Are we performing a revert? }
		fReverting: BOOLEAN;

		{ Handle to any information needed for Revert }
		fRevertInfo: Handle;

		{ Item number and default number for use in merge command }
		fMergeItem	 : INTEGER;
		fMergeDefault: INTEGER;

		{ Page Setup information }
		fStyleInfo: TStyleInfo;

		{ Magic eraser information }
		fMagicRows: INTEGER;
		fMagicCols: INTEGER;
		fMagicChannels: INTEGER;
		fMagicMode: TDisplayMode;
		fMagicData: TChannelArrayList;

		{ Selection highlighting information }
		fFlickerTime: LONGINT;
		fFlickerState: INTEGER;

		{ Miscellaneous resource list }
		fMiscResources: TList;

		PROCEDURE TImageDocument.DefaultState;

		PROCEDURE TImageDocument.IImageDocument;

		FUNCTION TImageDocument.ValidSize: BOOLEAN;

		FUNCTION TImageDocument.Interleave (channel: INTEGER): INTEGER;

		PROCEDURE TImageDocument.DefaultMode;

		PROCEDURE TImageDocument.DoInitialState; OVERRIDE;

		PROCEDURE TImageDocument.FreeFloat;

		PROCEDURE TImageDocument.FreeMagic;

		PROCEDURE TImageDocument.FreeData; OVERRIDE;

		PROCEDURE TImageDocument.Free; OVERRIDE;

		PROCEDURE TImageDocument.TestColorTable;

		PROCEDURE TImageDocument.SFPutParms
				(itsCmdNumber: CmdNumber;
				 VAR dlgID: INTEGER; VAR where: Point;
				 VAR defaultName, prompt: Str255;
				 VAR dlgHook, filterProc: ProcPtr); OVERRIDE;

		PROCEDURE TImageDocument.SaveAgain
				(itsCmdNumber: CmdNumber;
				 makingCopy: BOOLEAN;
				 savingDoc: TDocument); OVERRIDE;

		PROCEDURE TImageDocument.Save
				(itsCmdNumber: CmdNumber;
				 askForFilename, makingCopy: BOOLEAN); OVERRIDE;

		PROCEDURE TImageDocument.AboutToSave
				(itsCmd: CmdNumber; VAR newName: Str255;
				 VAR newVolRefnum: INTEGER;
				 VAR makingCopy: BOOLEAN); OVERRIDE;

		FUNCTION TImageDocument.GetSaveInfo
				(itsCmdNumber: CmdNumber; copyFInfo: BOOLEAN;
				 VAR cInfo: CInfoPBRec): BOOLEAN; OVERRIDE;

		PROCEDURE TImageDocument.SavedOn
				(VAR fileName: Str255; volRefNum: INTEGER); OVERRIDE;

		PROCEDURE TImageDocument.DoNeedDiskSpace
				(VAR dataForkBytes, rsrcForkBytes: LONGINT); OVERRIDE;

		PROCEDURE TImageDocument.DoWrite
				(aRefNum: INTEGER; makingCopy: BOOLEAN); OVERRIDE;

		PROCEDURE TImageDocument.DoRead
				(aRefNum: INTEGER; rsrcExists, forPrinting: BOOLEAN); OVERRIDE;

		PROCEDURE TImageDocument.ReadFromFile
				(VAR anAppFile: AppFile; forPrinting: BOOLEAN); OVERRIDE;

		PROCEDURE TImageDocument.DoMakeViews (forPrinting: BOOLEAN); OVERRIDE;

		PROCEDURE TImageDocument.DoMakeWindows; OVERRIDE;

		PROCEDURE TImageDocument.OpenAgain
				(itsCmdNumber: INTEGER; openingDoc: TDocument); OVERRIDE;

		FUNCTION TImageDocument.CanRevert: BOOLEAN;

		PROCEDURE TImageDocument.MyRevert;

		PROCEDURE TImageDocument.DoIdle (phase: IdlePhase); OVERRIDE;

		PROCEDURE TImageDocument.GetBoundsRect (VAR r: Rect);

		PROCEDURE TImageDocument.SectBoundsRect (VAR r: Rect);

		PROCEDURE TImageDocument.KillEffect (fixup: BOOLEAN);

		PROCEDURE TImageDocument.DeSelect (redraw: BOOLEAN);

		PROCEDURE TImageDocument.Select (r: Rect; mask: TVMArray);

		PROCEDURE TImageDocument.MoveSelection (r: Rect);

		PROCEDURE TImageDocument.UpdateImageArea (area: Rect;
												  highlight: BOOLEAN;
												  doFront: BOOLEAN;
												  channel: INTEGER);

		PROCEDURE TImageDocument.UpdateStatus;

		PROCEDURE TImageDocument.InvalRulers;

		PROCEDURE TImageDocument.ChannelName (channel: INTEGER;
											  VAR name: Str255);

		PROCEDURE TImageDocument.DoSetupMenus; OVERRIDE;

		FUNCTION TImageDocument.DoMenuCommand
				(aCmdNumber: CmdNumber): TCommand; OVERRIDE;

		END;

	TDitherTables = OBJECT (TObject)

		{ Dither method }
		fMethod: (DitherMethodHalftone,
				  DitherMethodSimple,
				  DitherMethodIndexed,
				  DitherMethodRGB,
				  DitherMethodRGBMonochrome,
				  DitherMethod24BitRGB,
				  DitherMethod24BitTable,
				  DitherMethod16BitRGB,
				  DitherMethod16BitTable);

		{ Is the color table compatible with the 8-bit system table }
		fSystemPalette: BOOLEAN;

		{ Is the data dithered for a monochrome screen }
		fMonochrome: BOOLEAN;

		{ Packing depth of dithered data }
		fDepth: INTEGER;

		{ Resolution of dithered data }
		fResolution: INTEGER;

		{ Handle to color table, if any }
		fColorTable: CTabHandle;

		{ LUTs for dithering }
		fLUT1: TLookUpTable;
		fLUT2: TLookUpTable;
		fLUT3: TLookUpTable;

		{ Dither pattern size }
		fDitherSize: INTEGER;

		{ Dither noise table }
		fNoiseTable: TNoiseTable;

		{ Dither threshold tables }
		fThresTable1: TThresTable;
		fThresTable2: TThresTable;
		fThresTable3: TThresTable;

		PROCEDURE TDitherTables.ITables;

		PROCEDURE TDitherTables.Free; OVERRIDE;

		PROCEDURE TDitherTables.CompTables (doc: TImageDocument;
											channel: INTEGER;
											forceMonochrome: BOOLEAN;
											forceSystem: BOOLEAN;
											depth: INTEGER;
											resolution: INTEGER;
											autoDepth: BOOLEAN;
											autoResolution: BOOLEAN;
											ditherCode: INTEGER);

		FUNCTION TDitherTables.CompRowBytes (width: INTEGER): LONGINT;

		FUNCTION TDitherTables.BufferSize (r: Rect): LONGINT;

		PROCEDURE TDitherTables.DitherRect (doc: TImageDocument;
											channel: INTEGER;
											magnification: INTEGER;
											r: Rect;
											buffer: Ptr;
											doFlush: BOOLEAN);

		END;

	TImageView = OBJECT (TView)

		{ View's channel }
		fChannel: INTEGER;

		{ View's magnification }
		fMagnification: INTEGER;

		{ Screen mode }
		fScreenMode: INTEGER;

		{ Rulers? }
		fRulers: BOOLEAN;

		{ Holds the window the view is in }
		fWindow: TWindow;

		{ Dither tables }
		fTables: TDitherTables;

		{ Handle to palette }
		fPalette: PaletteHandle;

		{ The main screen's seed value when fTransLUT was computed }
		fTransSeed: LONGINT;

		{ A LUT from the dither table's LUT to the screen's LUT }
		fTransLUT: TLookUpTable;

		{ Area to update during idle time }
		fDelayedUpdateRgn: RgnHandle;

		{ Command number in windows menu }
		fCmdNumber: INTEGER;

		{ Is the selection obscured? }
		fObscured: BOOLEAN;

		{ Tickcount when selection an be shown again }
		fObscureTime: LONGINT;

		PROCEDURE TImageView.IImageView (doc: TImageDocument);

		PROCEDURE TImageView.Free; OVERRIDE;

		FUNCTION TImageView.GetScreen: GDHandle;

		PROCEDURE TImageView.GetViewScreenInfo (VAR depth: INTEGER;
												VAR monochrome: BOOLEAN);

		PROCEDURE TImageView.CvtImage2View (VAR pt: Point; way: BOOLEAN);

		PROCEDURE TImageView.CvtView2Image (VAR pt: Point);

		PROCEDURE TImageView.GetImageColor (pt: Point; VAR r, g, b: INTEGER);

		PROCEDURE TImageView.GetViewColor (pt: Point; VAR r, g, b: INTEGER);

		FUNCTION TImageView.GroundByte (color: RGBColor;
										channel: INTEGER): INTEGER;

		FUNCTION TImageView.ForegroundByte (channel: INTEGER): INTEGER;

		FUNCTION TImageView.BackgroundByte (channel: INTEGER): INTEGER;

		PROCEDURE TImageView.CompBounds (VAR bounds: Rect);

		FUNCTION TImageView.MinMagnification: INTEGER;

		FUNCTION TImageView.MaxMagnification: INTEGER;

		PROCEDURE TImageView.ValidateView;

		PROCEDURE TImageView.ChangeExtent;

		PROCEDURE TImageView.AdjustExtent; OVERRIDE;

		PROCEDURE TImageView.ShowReverted; OVERRIDE;

		FUNCTION TImageView.ColorizeBand
				(VAR band: INTEGER; VAR subtractive: BOOLEAN): BOOLEAN;

		PROCEDURE TImageView.IDither;

		PROCEDURE TImageView.ReDither (redraw: BOOLEAN);

		FUNCTION TImageView.CompTransLUT (device: GDHandle): BOOLEAN;

		PROCEDURE TImageView.CheckDither;

		PROCEDURE TImageView.DrawNow (area: Rect; doFlush: BOOLEAN);

		PROCEDURE TImageView.Draw (area: Rect); OVERRIDE;

		PROCEDURE TImageView.UpdateImageArea (area: Rect; highlight: BOOLEAN);

		FUNCTION TImageView.CompHighlightAreas (VAR r, area: Rect): BOOLEAN;

		PROCEDURE TImageView.DoHighlightRect (fromHL, toHL: HLState);

		PROCEDURE TImageView.DoHighlightMask (fromHL, toHL: HLState);

		FUNCTION TImageView.CompCornerRect (pt: Point; VAR r: Rect): BOOLEAN;

		FUNCTION TImageView.FindCorner
				(corners: TCornerList; pt: Point): INTEGER;

		PROCEDURE TImageView.DoHighlightCorner (pt: Point; turnOn: BOOLEAN);

		PROCEDURE TImageView.DoHighlightCorners (turnOn: BOOLEAN);

		PROCEDURE TImageView.DoHighlightSelection
				(fromHL, toHL: HLState); OVERRIDE;

		PROCEDURE TImageView.UpdateSelection;

		PROCEDURE TImageView.ObscureSelection (delay: INTEGER);

		PROCEDURE TImageView.DoDrawStatus (r: Rect);

		PROCEDURE TImageView.DrawStatus;

		PROCEDURE TImageView.InvalRulers;

		PROCEDURE TImageView.TrackRulers;

		PROCEDURE TImageView.GetGlobalArea (VAR area: Rect);

		PROCEDURE TImageView.ResetGlobalArea (area: Rect);

		PROCEDURE TImageView.GetZoomLimits (VAR limits: Rect);

		PROCEDURE TImageView.GetZoomSize (VAR pt: Point);

		PROCEDURE TImageView.AdjustZoomSize;

		PROCEDURE TImageView.SetToZoomSize;

		PROCEDURE TImageView.SetScreenMode (mode: INTEGER);

		PROCEDURE TImageView.ShowRulers (rulers: BOOLEAN);

		PROCEDURE TImageView.Activate (wasActive, beActive: BOOLEAN); OVERRIDE;

		PROCEDURE TImageView.UpdateWindowTitle;

		PROCEDURE TImageView.DoSetupMenus; OVERRIDE;

		FUNCTION TImageView.DoMenuCommand
				(aCmdNumber: CmdNumber): TCommand; OVERRIDE;

		FUNCTION TImageView.DoKeyCommand
				(ch: CHAR;
				 aKeyCode: INTEGER;
				 VAR info: EventInfo): TCommand; OVERRIDE;

		FUNCTION TImageView.DoMouseCommand
				(VAR downLocalPoint: Point;
				 VAR info: EventInfo;
				 VAR hysteresis: Point): TCommand; OVERRIDE;

		END;

	TImageWindow = OBJECT (TWindow)

		PROCEDURE TImageWindow.UpdateEvent; OVERRIDE;

		PROCEDURE TImageWindow.MoveByUser (startPt: Point); OVERRIDE;

		FUNCTION TImageWindow.TrackInContent
				(localPoint: Point; VAR info: EventInfo): TCommand; OVERRIDE;

		END;

	TRulerFrame = OBJECT (TFrame)

		fVertical: BOOLEAN;

		PROCEDURE TRulerFrame.IRulerFrame
				(window: TImageWindow; vertical: BOOLEAN);

		PROCEDURE TRulerFrame.ResizedContainer
				(oldBotRight, newBotRight: Point); OVERRIDE;

		PROCEDURE TRulerFrame.ScrollRuler (invalWholeFrame: BOOLEAN);

		END;

	TRulerView = OBJECT (TView)

		fImageView: TImageView;

		fOrigin: INTEGER;

		fScale: Fixed;
		fLabel: LONGINT;
		fSteps: ARRAY [0..5] OF INTEGER;

		fLastRes: Fixed;
		fLastMag: INTEGER;
		fLastUnit: INTEGER;

		fHaveMark: BOOLEAN;
		fMarkOffset: INTEGER;

		PROCEDURE TRulerView.IRulerView (view: TImageView);

		PROCEDURE TRulerView.FindOrigin;

		PROCEDURE TRulerView.FindScale;

		PROCEDURE TRulerView.Draw (area: Rect); OVERRIDE;

		PROCEDURE TRulerView.DoHighlightSelection
				(fromHL, toHL: HLState); OVERRIDE;

		END;

	TImageFrame = OBJECT (TFrame)

		fStatusRect: Rect;

		fRuler: ARRAY [VHSelect] OF TRulerFrame;

		PROCEDURE TImageFrame.PositionRulers;

		FUNCTION TImageFrame.AdjustSBars: BOOLEAN; OVERRIDE;

		FUNCTION TImageFrame.CalcSBarMin (direction: VHSelect): INTEGER; OVERRIDE;

		FUNCTION TImageFrame.CalcSBarMax (direction: VHSelect): INTEGER; OVERRIDE;

		PROCEDURE TImageFrame.DrawAll; OVERRIDE;

		PROCEDURE TImageFrame.ChangedSize (oldBotRight: Point;
										   newBotRight: Point); OVERRIDE;

		PROCEDURE TImageFrame.ScrlToSBars (invalWholeFrame: BOOLEAN); OVERRIDE;

		END;

	TTool = (LassoTool, MarqueeTool, HandTool, CroppingTool, ZoomTool,
			 EyedropperTool, EraserTool, PencilTool, BrushTool, AirbrushTool,
			 BlurTool, SmudgeTool, BucketTool, SharpenTool, WandTool,
			 StampTool, GradientTool, TextTool, EllipseTool, LineTool,
			 MoveTool, EffectsTool, StampPadTool, EyedropperBackTool,
			 MagicTool, ZoomOutTool, ZoomLimitTool, CropFinishTool,
			 CropAdjustTool, NullTool);

	TToolsView = OBJECT (TView)

		fPictRect1: Rect;
		fPictRect2: Rect;

		fPict1: PicHandle;
		fPict2: PicHandle;

		fToolRect: ARRAY [LassoTool..LineTool] OF Rect;

		fForeRgn: RgnHandle;
		fBackRgn: RgnHandle;

		fModeRect: ARRAY [0..2] OF Rect;
		fMarkRect: ARRAY [0..2] OF Rect;

		PROCEDURE TToolsView.IToolsView;

		PROCEDURE TToolsView.DrawForeground;

		PROCEDURE TToolsView.DrawBackground;

		PROCEDURE TToolsView.InvalidateColors;

		PROCEDURE TToolsView.MarkMode (mode: INTEGER);

		PROCEDURE TToolsView.Draw (area: Rect); OVERRIDE;

		PROCEDURE TToolsView.DoHighlightSelection
				(fromHL, toHL: HLState); OVERRIDE;

		FUNCTION TToolsView.PickTool (tool: TTool; click: INTEGER): TCommand;

		FUNCTION TToolsView.FindTool (pt: Point): TTool;

		FUNCTION TToolsView.DoMouseCommand
				(VAR downLocalPoint: Point;
				 VAR info: EventInfo;
				 VAR hysteresis: Point): TCommand; OVERRIDE;

		END;

	TImageFormat = OBJECT (TObject)

		{ Can I read this format? }
		fCanRead: BOOLEAN;

		{ File types for reading }
		fReadType1: OSType;
		fReadType2: OSType;
		fReadType3: OSType;

		{ Finder file type and creator for writing }
		fFileType: OSType;
		fFileCreator: OSType;

		{ Does the file format use the data fork? }
		fUsesDataFork: BOOLEAN;

		{ Does the file format use the resource fork? }
		fUsesRsrcFork: BOOLEAN;

		PROCEDURE TImageFormat.IImageFormat;

		FUNCTION TImageFormat.CanWrite (doc: TImageDocument): BOOLEAN;

		PROCEDURE TImageFormat.SetFormatOptions (doc: TImageDocument);

		PROCEDURE TImageFormat.DoRead
				(doc: TImageDocument; refNum: INTEGER; rsrcExists: BOOLEAN);

		PROCEDURE TImageFormat.ReadOther (doc: TImageDocument; name: Str255);

		PROCEDURE TImageFormat.AboutToSave (doc: TImageDocument;
											itsCmd: INTEGER;
											VAR name: Str255;
											VAR vRefNum: INTEGER;
											VAR makingCopy: BOOLEAN);

		FUNCTION TImageFormat.DataForkBytes (doc: TImageDocument): LONGINT;

		FUNCTION TImageFormat.RsrcForkBytes (doc: TImageDocument): LONGINT;

		PROCEDURE TImageFormat.DoWrite (doc: TImageDocument; refNum: INTEGER);

		PROCEDURE TImageFormat.WriteOther (doc: TImageDocument; name: Str255);

		END;

	TColorCoord = RECORD
		rgb 	: RGBColor;
		percent : INTEGER
		END;

	TProgressive = ARRAY [1..kProgressive] OF TColorCoord;

	TSeparationSetup = RECORD
		fProgressive : TProgressive;
		fGamma		 : INTEGER;
		fInkMaximum  : INTEGER;
		fBlackID	 : INTEGER;
		fGCRTable	 : TLookUpTable;
		fUCRTable	 : TLookUpTable;
		fUCAPercent  : INTEGER
		END;

	TPreferences = RECORD
		fColorize		: BOOLEAN;
		fUseSystem		: BOOLEAN;
		fUseDirectLUT	: BOOLEAN;
		fClipOption 	: INTEGER;
		fInterpolate	: INTEGER;
		fColumnWidth	: FixedScaled;
		fColumnGutter	: FixedScaled;
		fHalftone		: THalftoneSpec;
		fTransfer		: TTransferSpec;
		fHalftones		: THalftoneSpecs;
		fTransfers		: TTransferSpecs;
		fSeparation 	: TSeparationSetup
		END;

VAR

	{ The current preferences settings }

	gPreferences: TPreferences;

	{ Program's serial number }

	gSerialNumber: LONGINT;
	
	{ Are we running on a metric system? }
	
	gMetric: BOOLEAN;

	{ Has the application been fully initialized yet? }

	gInitializedPS: BOOLEAN;

	{ A general use 32K buffer }

	gBuffer: Ptr;

	{ Currently selected tool }

	gTool: TTool;
	gUseTool: TTool;

	{ Current colors }

	gForegroundColor: RGBColor;
	gBackgroundColor: RGBColor;

	{ Current information for cloning tool }

	gCloneDoc	 : TImageDocument;
	gCloneTarget : TImageDocument;
	gCloneChannel: INTEGER;
	gClonePoint  : Point;
	gCloneOffset : Point;

	{ Current pattern }

	gPatternRect: Rect;
	gPattern: ARRAY [0..3] OF TVMArray;

	{ Tools palette view }

	gToolsView: TToolsView;
	gToolsWindow: WindowPtr;

	{ Color picker window }

	gPickerWmgrWindow: WindowPtr;

	{ Scrach pad document }

	gScratchDoc: TImageDocument;

	{ A set of dither tables for general use }

	gTables: TDitherTables;

	{ Array for image format objects }

	gFormats: ARRAY [0..kLastFmtCode] OF TImageFormat;

	{ Currently active format }

	gFormatCode: INTEGER;

	{ Current SF reply record }

	gReply: SFReply;

	{ A null (one to one) look up table }

	gNullLUT: TLookUpTable;

	{ A inverting look up table }

	gInvertLUT: TLookUpTable;

	{ A color to gray level look up table }

	gGrayLUT: TRGBLookUpTable;

	{ IDs of fonts used for display and printing }

	gGeneva: INTEGER;
	gMonaco: INTEGER;
	gHelvetica: INTEGER;

	{ Decimal point character for numbers }

	gDecimalPt: CHAR;

	{ Is 32-bit QuickDraw installed? }

	gHas32BitQuickDraw: BOOLEAN;

	{ Window stagger count }

	gStaggerCount: INTEGER;

	{ Current printer resolution for use in dialogs }

	gPrinterResolution: FixedScaled;

	{ Set of patterns for highlighting, and their differences }

	gHLPattern	   : ARRAY [0..kHLPatterns-1] OF Pattern;
	gHLPatternDelta: ARRAY [0..kHLPatterns-1] OF Pattern;

FUNCTION CreateOutputFile (prompt: Str255;
						   fileType: OSType;
						   VAR reply: SFReply): INTEGER;

PROCEDURE SetToolCursor (tool: TTool; allowCross: BOOLEAN);

FUNCTION SpaceWasDown: BOOLEAN;

PROCEDURE WhereToPlaceDialog (id: INTEGER; VAR where: Point);

PROCEDURE SetSFDirectory (vRefNum: INTEGER);

PROCEDURE ForAllImageViewsDo (PROCEDURE DoIt (view: TImageView));

FUNCTION MakeColorTable (levels: INTEGER): CTabHandle;

FUNCTION MakeMonochromeTable (levels: INTEGER): CTabHandle;

PROCEDURE CompThresTable (grayLevels: INTEGER;
						  VAR grayGap: INTEGER;
						  VAR thresTable: TThresTable);

PROCEDURE CompNoiseTable (ditherCode: INTEGER;
						  grayGap: INTEGER;
						  VAR ditherSize: INTEGER;
						  VAR noiseTable: TNoiseTable);

PROCEDURE DrawMaskOutline (map: BitMap;
						   maskData: TVMArray;
						   maskRect: Rect;
						   mag: INTEGER);

PROCEDURE SlideRectInto (VAR inner: Rect; outer: Rect);

PROCEDURE GetScreenInfo (device: GDHandle;
						 VAR depth: INTEGER;
						 VAR monochrome: BOOLEAN);

PROCEDURE RgnFillRGB (rgn: RgnHandle; color: RGBColor; depth: INTEGER);

PROCEDURE DoColorizedFill (rgn: RgnHandle; color: RGBColor; depth: INTEGER);

PROCEDURE ColorizedFill (rgn: RgnHandle; color: RGBColor);

IMPLEMENTATION

{$I UPhotoshop.inc1.p}

END.

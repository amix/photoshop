{Photoshop version 1.0.1, file: UCommands.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UCommands;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UProgress;

CONST

	kFileNameLength = 31;

TYPE

	TFileName = STRING [kFileNameLength];
	PFileName = ^TFileName;

	PPlugInInfo = ^TPlugInInfo;
	HPlugInInfo = ^PPlugInInfo;

	TPlugInInfo = RECORD
		fName	   : Str255;
		fFileName  : TFileName;
		fKind	   : ResType;
		fResourceID: INTEGER;
		fVersion   : INTEGER;
		fData	   : LONGINT;
		fParameters: Handle;
		fNext	   : HPlugInInfo
		END;

	TPasteMode = (PasteNormal, PasteColorOnly,
				  PasteDarkenOnly, PasteLightenOnly);

	TPasteControls = RECORD
		fSrcMin: ARRAY [0..3] OF INTEGER;
		fSrcMax: ARRAY [0..3] OF INTEGER;
		fDstMin: ARRAY [0..3] OF INTEGER;
		fDstMax: ARRAY [0..3] OF INTEGER;
		fMode  : TPasteMode;
		fBlend : INTEGER;
		fFuzz  : INTEGER;
		fMat   : INTEGER
		END;

	PPasteControls = ^TPasteControls;
	HPasteControls = ^PPasteControls;

	TBufferCommand = OBJECT (TCommand)

		fView: TImageView;
		fDoc : TImageDocument;

		fBuffer: TChannelArrayList;

		PROCEDURE TBufferCommand.IBufferCommand (itsCommand: INTEGER;
												 view: TImageView);

		PROCEDURE TBufferCommand.Free; OVERRIDE;

		PROCEDURE TBufferCommand.SwapAllChannels;

		END;

	TFloatCommand = OBJECT (TBufferCommand)

		fWasFloating: BOOLEAN;

		fSwapMask: BOOLEAN;

		fExactFloat: BOOLEAN;

		fFloatRect: Rect;

		fFloatMask: TVMArray;

		fFloatData: TRGBArrayList;

		fFloatBelow: TRGBArrayList;

		PROCEDURE TFloatCommand.IFloatCommand (itsCommand: INTEGER;
											   view: TImageView);

		PROCEDURE TFloatCommand.Free; OVERRIDE;

		PROCEDURE TFloatCommand.SwapFloat;

		PROCEDURE TFloatCommand.MakeMapLegal (VAR map: TLookUpTable);

		PROCEDURE TFloatCommand.FloatSelection (duplicate: BOOLEAN);

		PROCEDURE TFloatCommand.ComputeOverlap (VAR r: Rect);

		PROCEDURE TFloatCommand.CopyOverlapArea (into: BOOLEAN;
												 buffer: TVMArray;
												 image: TVMArray);

		PROCEDURE TFloatCommand.CopyOverlapAreas (into: BOOLEAN;
												  buffer0: TVMArray;
												  buffer1: TVMArray;
												  buffer2: TVMArray);

		PROCEDURE TFloatCommand.CopyBelow (into: BOOLEAN);

		PROCEDURE TFloatCommand.BlendFloatSingle (srcArray: TVMArray;
												  dstArray: TVMArray;
												  maskArray: TVMArray;
												  alphaArray: TVMArray;
												  r1: Rect;
												  r2: Rect;
												  canAbort: BOOLEAN);

		PROCEDURE TFloatCommand.BlendFloatRGB (src1Array: TVMArray;
											   src2Array: TVMArray;
											   src3Array: TVMArray;
											   dst1Array: TVMArray;
											   dst2Array: TVMArray;
											   dst3Array: TVMArray;
											   maskArray: TVMArray;
											   alphaArray: TVMArray;
											   r1: Rect;
											   r2: Rect;
											   canAbort: BOOLEAN);

		PROCEDURE TFloatCommand.BlendFloat (canAbort: BOOLEAN);

		FUNCTION TFloatCommand.CanSelect (VAR r: Rect;
										  VAR mask: TVMArray): OSErr;

		PROCEDURE TFloatCommand.SelectFloat;

		PROCEDURE TFloatCommand.UpdateRects (r1, r2: Rect; highlight: BOOLEAN);

		END;

VAR

	gFirstPSAcquire: HPlugInInfo;
	gFirstDDAcquire: HPlugInInfo;
	gFirstBWAcquire: HPlugInInfo;
	gFirstPSExport : HPlugInInfo;
	gFirstPSFilter : HPlugInInfo;
	gFirstDDFilter : HPlugInInfo;

PROCEDURE InitPlugInList (kind: ResType;
						  loVersion, hiVersion: INTEGER;
						  VAR first: HPlugInInfo;
						  command: INTEGER);

PROCEDURE CheckForNoPlugIns (command: INTEGER);

FUNCTION IsPlugIn (name: Str255;
				   first: HPlugInInfo;
				   VAR info: HPlugInInfo): BOOLEAN;

PROCEDURE GetCenterPoint (view: TImageView; VAR center: Point);

PROCEDURE SetTopLeft (view: TImageView; top, left: INTEGER);

PROCEDURE SetCenterPoint (view: TImageView; center: Point);

FUNCTION MakeMonochromeArray (rArray, gArray, bArray: TVMArray): TVMArray;

FUNCTION CopyHalftoneRect (srcBuffer: TVMArray;
						   r: Rect;
						   depth: INTEGER): TVMArray;

PROCEDURE GetPasteControls (doc: TImageDocument;
							VAR controls: TPasteControls);

IMPLEMENTATION

{$I UCommands.inc1.p}

END.

{Photoshop version 1.0.1, file: USelect.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT USelect;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UBWDialog, UCommands, UFilters, UProgress;

TYPE

	TSelectRect = OBJECT (TFloatCommand)

		fSelectRect: Rect;

		PROCEDURE TSelectRect.ISelectRect (itsCommand: INTEGER;
										   view: TImageView;
										   r: Rect);

		PROCEDURE TSelectRect.DoIt; OVERRIDE;

		PROCEDURE TSelectRect.UndoIt; OVERRIDE;

		PROCEDURE TSelectRect.RedoIt; OVERRIDE;

		END;

	TMaskCommand = OBJECT (TFloatCommand)

		fAdd: BOOLEAN;
		fDrop: BOOLEAN;
		fRemove: BOOLEAN;
		fRefine: BOOLEAN;

		fObscure: BOOLEAN;

		fTrim: BOOLEAN;

		fMask: TVMArray;
		fMaskBounds: Rect;

		fSaveRect: Rect;
		fSaveMask: TVMArray;

		PROCEDURE TMaskCommand.IMaskCommand
				(itsCommand: INTEGER;
				 view: TImageView;
				 add, remove, refine, drop: BOOLEAN;
				 needMask: BOOLEAN;
				 obscure: BOOLEAN);

		PROCEDURE TMaskCommand.Free; OVERRIDE;

		PROCEDURE TMaskCommand.FixObscured;

		PROCEDURE TMaskCommand.TrackFeedBack
				(anchorPoint, nextPoint: Point;
				 turnItOn, mouseDidMove: BOOLEAN); OVERRIDE;

		PROCEDURE TMaskCommand.CombineMask
				(sr: Rect; sm: TVMArray; VAR delta: Rect);

		FUNCTION TMaskCommand.SolidMask: BOOLEAN;

		PROCEDURE TMaskCommand.DropDifference;

		PROCEDURE TMaskCommand.TrimFloat (delta: Rect);

		PROCEDURE TMaskCommand.UpdateSelection;

		PROCEDURE TMaskCommand.UndoIt; OVERRIDE;

		PROCEDURE TMaskCommand.RedoIt; OVERRIDE;

		END;

	TLassoSelector = OBJECT (TMaskCommand)

		fWhite: BOOLEAN;

		fMovedOnce: BOOLEAN;

		fViewBounds: Rect;

		fMouseRect: Rect;

		PROCEDURE TLassoSelector.ILassoSelector
				(view: TImageView;
				 downPoint: Point;
				 add, remove, refine, drop: BOOLEAN);

		PROCEDURE TLassoSelector.TrackConstrain
				(anchorPoint, previousPoint: Point;
				 VAR nextPoint: Point); OVERRIDE;

		FUNCTION TLassoSelector.TrackMouseUp
				(VAR didMove: BOOLEAN;
				 VAR anchorPoint: Point;
				 VAR previousPoint: Point): BOOLEAN; OVERRIDE;

		PROCEDURE TLassoSelector.ComputeMask;

		PROCEDURE TLassoSelector.MarkMask (fromPt, toPt: Point);

		PROCEDURE TLassoSelector.Extend (fromPt, toPt: Point);

		FUNCTION TLassoSelector.TrackMouse
				(aTrackPhase: TrackPhase;
				 VAR anchorPoint, previousPoint, nextPoint: Point;
				 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

		END;

	THistograms = ARRAY [0..5] OF THistogram;

	TWandSelector = OBJECT (TMaskCommand)

		fIgnore   : INTEGER;
		fTolerance: INTEGER;
		fFuzziness: INTEGER;
		fConnected: BOOLEAN;

		fMap: ARRAY [0..5] OF TLookUpTable;

		PROCEDURE TWandSelector.IWandSelector (itsCommand: INTEGER;
											   view: TImageView;
											   add, remove, refine: BOOLEAN);

		PROCEDURE TWandSelector.HistRegion (src1Array: TVMArray;
											src2Array: TVMArray;
											src3Array: TVMArray;
											rgnRect: Rect;
											rgnMask: TVMArray;
											VAR hists: THistograms);

		PROCEDURE TWandSelector.BuildMap (hist: THistogram;
										  VAR map: TLookUpTable;
										  tolerance: INTEGER;
										  fuzziness: INTEGER);

		PROCEDURE TWandSelector.BuildMaps (rgnRect: Rect;
										   rgnMask: TVMArray);

		PROCEDURE TWandSelector.PrepareLine (row: INTEGER);

		PROCEDURE TWandSelector.Grow4Connected (VAR lower: INTEGER;
												VAR upper: INTEGER;
												VAR r: Rect);

		PROCEDURE TWandSelector.DilateArea (r: Rect);

		PROCEDURE TWandSelector.MarkRegion (rgnRect: Rect;
											rgnMask: TVMArray);

		PROCEDURE TWandSelector.GrowRegion (rgnRect: Rect;
											rgnMask: TVMArray);

		PROCEDURE TWandSelector.GrowFromSeed (downPoint: Point);

		FUNCTION TWandSelector.TrackMouse
				(aTrackPhase: TrackPhase;
				 VAR anchorPoint, previousPoint, nextPoint: Point;
				 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

		END;

	TBucketTool = OBJECT (TWandSelector)

		PROCEDURE TBucketTool.IBucketTool (view: TImageView; refine: BOOLEAN);

		PROCEDURE TBucketTool.FillMaskedArea;

		FUNCTION TBucketTool.TrackMouse
				(aTrackPhase: TrackPhase;
				 VAR anchorPoint, previousPoint, nextPoint: Point;
				 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

		PROCEDURE TBucketTool.UndoIt; OVERRIDE;

		PROCEDURE TBucketTool.RedoIt; OVERRIDE;

		END;

	TGrowCommand = OBJECT (TWandSelector)

		PROCEDURE TGrowCommand.IGrowCommand (view: TImageView;
											 connected: BOOLEAN);

		PROCEDURE TGrowCommand.DoIt; OVERRIDE;

		END;

	THandTool = OBJECT (TCommand)

		fView: TImageView;

		PROCEDURE THandTool.IHandTool (view: TImageView);

		PROCEDURE THandTool.TrackFeedBack
				(anchorPoint, nextPoint: Point;
				 turnItOn, mouseDidMove: BOOLEAN); OVERRIDE;

		FUNCTION THandTool.TrackMouse
				(aTrackPhase: TrackPhase;
				 VAR anchorPoint, previousPoint, nextPoint: Point;
				 mouseDidMove: BOOLEAN): TCommand; OVERRIDE;

		END;

	TSelectInverse = OBJECT (TMaskCommand)

		PROCEDURE TSelectInverse.ISelectInverse (view: TImageView);

		PROCEDURE TSelectInverse.DoIt; OVERRIDE;

		END;

	TSelectFringe = OBJECT (TMaskCommand)

		PROCEDURE TSelectFringe.ISelectFringe (view: TImageView);

		PROCEDURE TSelectFringe.DoIt; OVERRIDE;

		END;

	TFeatherCommand = OBJECT (TMaskCommand)

		PROCEDURE TFeatherCommand.IFeatherCommand (view: TImageView);

		PROCEDURE TFeatherCommand.DoIt; OVERRIDE;

		END;

	TDefringeCommand = OBJECT (TFloatCommand)

		fWidth: INTEGER;

		fChannel: INTEGER;

		PROCEDURE TDefringeCommand.IDefringeCommand
				(view: TImageView; width: INTEGER);

		PROCEDURE TDefringeCommand.DefringeData
				(maskArray: TVMArray;
				 dst1Array: TVMArray;
				 dst2Array: TVMArray;
				 dst3Array: TVMArray);

		PROCEDURE TDefringeCommand.DoIt; OVERRIDE;

		PROCEDURE TDefringeCommand.UndoIt; OVERRIDE;

		PROCEDURE TDefringeCommand.RedoIt; OVERRIDE;

		END;

	TMakeAlphaCommand = OBJECT (TBufferCommand)

		fSolid: BOOLEAN;

		PROCEDURE TMakeAlphaCommand.IMakeAlphaCommand (view: TImageView);

		PROCEDURE TMakeAlphaCommand.DoIt; OVERRIDE;

		PROCEDURE TMakeAlphaCommand.UndoIt; OVERRIDE;

		PROCEDURE TMakeAlphaCommand.RedoIt; OVERRIDE;

		END;

	TSelectAlphaCommand = OBJECT (TBufferCommand)

		fOldRect: Rect;

		fChannel: INTEGER;

		PROCEDURE TSelectAlphaCommand.ISelectAlphaCommand (view: TImageView);

		PROCEDURE TSelectAlphaCommand.DoIt; OVERRIDE;

		PROCEDURE TSelectAlphaCommand.UndoIt; OVERRIDE;

		PROCEDURE TSelectAlphaCommand.RedoIt; OVERRIDE;

		END;

PROCEDURE InitSelections;

FUNCTION DoSelectAll (view: TImageView): TCommand;

FUNCTION DoSelectNone (view: TImageView): TCommand;

FUNCTION DropSelection (view: TImageView): TCommand;

PROCEDURE InterpolatePoints (pt1, pt2: Point;
							 PROCEDURE EachPoint (pt: Point));

FUNCTION DoLassoTool (view: TImageView;
					  downPoint: Point;
					  add: BOOLEAN;
					  remove: BOOLEAN;
					  refine: BOOLEAN;
					  drop: BOOLEAN): TCommand;

PROCEDURE DoLassoOptions;

FUNCTION DoWandTool (view: TImageView;
					 add: BOOLEAN;
					 remove: BOOLEAN;
					 refine: BOOLEAN): TCommand;

PROCEDURE DoWandOptions;

FUNCTION DoBucketTool (view: TImageView): TCommand;

PROCEDURE DoBucketOptions;

FUNCTION DoGrowCommand (view: TImageView; connected: BOOLEAN): TCommand;

FUNCTION DoHandTool (view: TImageView): TCommand;

PROCEDURE CopyAlphaChannel (doc: TImageDocument; buffer: TVMArray);

FUNCTION DoSelectInverse (view: TImageView): TCommand;

PROCEDURE FindTaxiCab (buffer: TVMArray; r: Rect; block: INTEGER);

FUNCTION DoSelectFringe (view: TImageView): TCommand;

FUNCTION DoFeatherCommand (view: TImageView): TCommand;

FUNCTION DoDefringeCommand (view: TImageView): TCommand;

FUNCTION DoMakeAlphaCommand (view: TImageView): TCommand;

FUNCTION DoSelectAlphaCommand (view: TImageView): TCommand;

IMPLEMENTATION

{$I USelect.inc1.p}

END.

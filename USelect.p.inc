{Photoshop version 1.0.1, file: USelect.p.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE InitSelections; EXTERNAL;

FUNCTION DoSelectAll (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoSelectNone (view: TImageView): TCommand; EXTERNAL;

FUNCTION DropSelection (view: TImageView): TCommand; EXTERNAL;

PROCEDURE InterpolatePoints (pt1, pt2: Point;
							 PROCEDURE EachPoint (pt: Point)); EXTERNAL;

FUNCTION DoLassoTool (view: TImageView;
					  downPoint: Point;
					  add: BOOLEAN;
					  remove: BOOLEAN;
					  refine: BOOLEAN;
					  drop: BOOLEAN): TCommand; EXTERNAL;

PROCEDURE DoLassoOptions; EXTERNAL;

FUNCTION DoWandTool (view: TImageView;
					 add: BOOLEAN;
					 remove: BOOLEAN;
					 refine: BOOLEAN): TCommand; EXTERNAL;

PROCEDURE DoWandOptions; EXTERNAL;

FUNCTION DoBucketTool (view: TImageView): TCommand; EXTERNAL;

PROCEDURE DoBucketOptions; EXTERNAL;

FUNCTION DoGrowCommand (view: TImageView;
						connected: BOOLEAN): TCommand; EXTERNAL;

FUNCTION DoHandTool (view: TImageView): TCommand; EXTERNAL;

PROCEDURE CopyAlphaChannel (doc: TImageDocument; buffer: TVMArray); EXTERNAL;

FUNCTION DoSelectInverse (view: TImageView): TCommand; EXTERNAL;

PROCEDURE FindTaxiCab (buffer: TVMArray; r: Rect; block: INTEGER); EXTERNAL;

FUNCTION DoSelectFringe (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoFeatherCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoDefringeCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoMakeAlphaCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoSelectAlphaCommand (view: TImageView): TCommand; EXTERNAL;

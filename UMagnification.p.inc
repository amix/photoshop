{Photoshop version 1.0.1, file: UMagnification.p.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

FUNCTION DoZoomInCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoZoomOutCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoScaleFactorCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoNormalSize (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoOverviewSize (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoZoomTool (view: TImageView;
					 downPoint: Point;
					 zoomOut: BOOLEAN): TCommand; EXTERNAL;

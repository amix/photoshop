{Photoshop version 1.0.1, file: UCrop.p.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE InitCrops; EXTERNAL;

FUNCTION DoMarqueeTool (view: TImageView;
						add: BOOLEAN;
						remove: BOOLEAN;
						refine: BOOLEAN): TCommand; EXTERNAL;

PROCEDURE DoMarqueeOptions; EXTERNAL;

FUNCTION DoEllipseTool (view: TImageView;
						add: BOOLEAN;
						remove: BOOLEAN;
						refine: BOOLEAN): TCommand; EXTERNAL;

PROCEDURE DoEllipseOptions; EXTERNAL;

FUNCTION DoCroppingTool (view: TImageView): TCommand; EXTERNAL;

PROCEDURE DoCroppingOptions; EXTERNAL;

FUNCTION DoCropCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION AdjustZeroPoint (view: TImageView): TCommand; EXTERNAL;

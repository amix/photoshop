{Photoshop version 1.0.1, file: URotate.p.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE InitRotations; EXTERNAL;

PROCEDURE DoTransposeArray (srcArray: TVMArray;
							dstArray: TVMArray;
							horizontal: BOOLEAN;
							vertical: BOOLEAN); EXTERNAL;

FUNCTION DoFlipCommand (view: TImageView;
						horizontal, vertical: BOOLEAN): TCommand; EXTERNAL;

FUNCTION DoRotateCommand (view: TImageView; angle: INTEGER): TCommand; EXTERNAL;

FUNCTION DoRotateArbitraryCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION SetEffectMode (view: TImageView; mode: INTEGER): TCommand; EXTERNAL;

FUNCTION DoEffectsCommand (view: TImageView;
						   downPoint: Point): TCommand; EXTERNAL;

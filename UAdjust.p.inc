{Photoshop version 1.0.1, file: UAdjust.p.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE InitAdjustments; EXTERNAL;

FUNCTION DoInvertCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoEqualizeCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoThresholdCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoPosterizeCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoMapArbitraryCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoLevelsCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoBrightnessCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoBalanceCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoSaturationCommand (view: TImageView): TCommand; EXTERNAL;

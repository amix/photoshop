{Photoshop version 1.0.1, file: UCalculate.p.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE InitCalculate; EXTERNAL;

FUNCTION DoDuplicateCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoConstantCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoCompositeCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoBlendCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoSubtractCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoAddCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoMultiplyCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoLighterCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoDarkerCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoDifferenceCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoScreenCommand (view: TImageView): TCommand; EXTERNAL;

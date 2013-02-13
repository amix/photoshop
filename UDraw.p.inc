{Photoshop version 1.0.1, file: UDraw.p.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE InitDrawing; EXTERNAL;

FUNCTION DoEraserTool (view: TImageView; magic: BOOLEAN): TCommand; EXTERNAL;

FUNCTION DoPencilTool (view: TImageView; pt: Point): TCommand; EXTERNAL;

FUNCTION DoBrushTool (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoAirbrushTool (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoBlurTool (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoSharpenTool (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoSmudgeTool (view: TImageView; dip: BOOLEAN): TCommand; EXTERNAL;

FUNCTION DoStampTool (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoStampPadTool (view: TImageView; pt: Point): TCommand; EXTERNAL;

FUNCTION DoEraseAll (view: TImageView): TCommand; EXTERNAL;

FUNCTION BrushesVisible: BOOLEAN; EXTERNAL;

PROCEDURE ShowBrushes (visible: BOOLEAN); EXTERNAL;

PROCEDURE UpdateBrush; EXTERNAL;

PROCEDURE DoPencilOptions; EXTERNAL;

PROCEDURE DoBrushOptions; EXTERNAL;

PROCEDURE DoAirbrushOptions; EXTERNAL;

PROCEDURE DoBlurOptions; EXTERNAL;

PROCEDURE DoSharpenOptions; EXTERNAL;

PROCEDURE DoSmudgeOptions; EXTERNAL;

PROCEDURE DoStampOptions; EXTERNAL;

PROCEDURE DefineBrush (view: TImageView); EXTERNAL;

PROCEDURE DefinePattern (view: TImageView); EXTERNAL;

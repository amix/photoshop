{Photoshop version 1.0.1, file: UFloat.p.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE InitFloatCommands; EXTERNAL;

FUNCTION GetClipSize (VAR width: INTEGER;
					  VAR height: INTEGER;
					  VAR resolution: FixedScaled;
					  VAR color: BOOLEAN): BOOLEAN; EXTERNAL;

FUNCTION DoMoveSelection (view: TImageView;
						  duplicate: BOOLEAN;
						  outline: BOOLEAN;
						  VAR hysteresis: Point): TCommand; EXTERNAL;

FUNCTION DoNudgeSelection (view: TImageView;
						   nudge: Point;
						   duplicate: BOOLEAN;
						   outline: BOOLEAN): TCommand; EXTERNAL;

FUNCTION ConvertPICTDeskScrap (size: LONGINT): TView; EXTERNAL;

FUNCTION DoCutCopyCommand (view: TImageView;
						   duplicate: BOOLEAN): TCommand; EXTERNAL;

FUNCTION DoPasteCommand (view: TImageView;
						 pasteMode: INTEGER): TCommand; EXTERNAL;

FUNCTION DoClearCommand (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoFillCommand (view: TImageView;
						options: BOOLEAN): TCommand; EXTERNAL;

FUNCTION DoGradientTool (view: TImageView): TCommand; EXTERNAL;

PROCEDURE DoGradientOptions; EXTERNAL;

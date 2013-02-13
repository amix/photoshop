{Photoshop version 1.0.1, file: UText.p.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE InitTextTool; EXTERNAL;

FUNCTION DoTextTool (view: TImageView; pt: Point): TCommand; EXTERNAL;

FUNCTION DoTextDrop (view: TImageView): TCommand; EXTERNAL;

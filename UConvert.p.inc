{Photoshop version 1.0.1, file: UConvert.p.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE InitCvtOptions; EXTERNAL;

FUNCTION DeHalftoneDoc (doc: TImageDocument;
						scale: INTEGER;
						canAbort: BOOLEAN): TVMArray; EXTERNAL;

FUNCTION DoConvertCommand (view: TImageView;
						   mode: TDisplayMode): TCommand; EXTERNAL;

FUNCTION DoDeleteChannel (view: TImageView): TCommand; EXTERNAL;

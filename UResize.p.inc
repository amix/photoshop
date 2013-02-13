{Photoshop version 1.0.1, file: UResize.p.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE InitResize; EXTERNAL;

PROCEDURE ResizeArray (srcArray: TVMArray;
					   dstArray: TVMArray;
					   sample: BOOLEAN;
					   canAbort: BOOLEAN); EXTERNAL;

FUNCTION DoResizeImage (view: TImageView): TCommand; EXTERNAL;

FUNCTION DoResampleImage (view: TImageView): TCommand; EXTERNAL;

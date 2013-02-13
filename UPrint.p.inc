{Photoshop version 1.0.1, file: UPrint.p.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE InitImagePrinting; EXTERNAL;

PROCEDURE GetPrintRects (doc: TImageDocument;
						 bounds: Rect;
						 VAR thePaper: Rect;
						 VAR theInk: Rect;
						 VAR theImage: Rect); EXTERNAL;

PROCEDURE AddImagePrintHander (view: TImageView); EXTERNAL;

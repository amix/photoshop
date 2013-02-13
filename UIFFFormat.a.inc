{Photoshop version 1.0.1, file: UIFFFormat.a.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE ExtractPlane (iData: Ptr;
						pData: Ptr;
						cols: INTEGER;
						plane: INTEGER); EXTERNAL;

PROCEDURE StuffPlane (pData: Ptr;
					  iData: Ptr;
					  cols: INTEGER;
					  plane: INTEGER); EXTERNAL;

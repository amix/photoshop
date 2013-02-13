{Photoshop version 1.0.1, file: UFilter.p.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE InitFilters; EXTERNAL;

PROCEDURE Do3by3Filter (srcArray: TVMArray;
						dstArray: TVMArray;
						r: Rect;
						which: INTEGER); EXTERNAL;

FUNCTION DoFilterCommand (view: TImageView;
						  name: Str255;
						  repeating: BOOLEAN): TCommand; EXTERNAL;

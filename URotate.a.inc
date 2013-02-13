{Photoshop version 1.0.1, file: URotate.a.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

FUNCTION DoBiCubic (base: Ptr;
					part: INTEGER): INTEGER; EXTERNAL;

PROCEDURE DoReverseBytes (data: Ptr;
						  count: INTEGER); EXTERNAL;

PROCEDURE DoSkewRow (srcPtr: Ptr;
					 dstPtr: Ptr;
					 srcCount: INTEGER;
					 dstCount: INTEGER;
					 base: LONGINT;
					 step: LONGINT;
					 method: INTEGER;
					 background: INTEGER); EXTERNAL;

PROCEDURE DoScaleFactor (srcPtr: Ptr;
						 dstPtr: Ptr;
						 count: INTEGER;
						 factor: INTEGER); EXTERNAL;

PROCEDURE DoEllipseRow (dstPtr: Ptr;
						row: INTEGER;
						width: INTEGER;
						height: INTEGER); EXTERNAL;

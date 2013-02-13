{Photoshop version 1.0.1, file: UTarga.a.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE Targa16Red (srcPtr: Ptr;
					  dstPtr: Ptr;
					  count: INTEGER); EXTERNAL;

PROCEDURE Targa16Green (srcPtr: Ptr;
						dstPtr: Ptr;
						count: INTEGER); EXTERNAL;

PROCEDURE Targa16Blue (srcPtr: Ptr;
					   dstPtr: Ptr;
					   count: INTEGER); EXTERNAL;

PROCEDURE DecodeTargaRLE (VAR srcPtr: Ptr;
						  VAR dstPtr: Ptr;
						  count: LONGINT;
						  size: INTEGER); EXTERNAL;

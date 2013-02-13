{Photoshop version 1.0.1, file: UTIFFormat.a.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

FUNCTION ExtractTIFF (buffer: Ptr;
					  offset: LONGINT;
					  count: INTEGER): INTEGER; EXTERNAL;

PROCEDURE StuffTIFF (buffer: Ptr;
					 offset: LONGINT;
					 code: INTEGER); EXTERNAL;

PROCEDURE AddTIFFPlane (srcPtr: Ptr;
						dstPtr: Ptr;
						count: INTEGER); EXTERNAL;

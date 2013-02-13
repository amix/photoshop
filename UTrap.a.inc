{Photoshop version 1.0.1, file: UTrap.a.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE DoTrapRow (srcPtr1: Ptr;
					 srcPtr2: Ptr;
					 dstPtr: Ptr;
					 bufPtr1: Ptr;
					 bufPtr2: Ptr;
					 radius: INTEGER;
					 count: INTEGER); EXTERNAL;

PROCEDURE DoCombineTrap (srcPtr: Ptr;
						 dstPtr: Ptr;
						 median: INTEGER;
						 count: INTEGER); EXTERNAL;

{Photoshop version 1.0.1, file: UPostScript.a.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE ConvertToHex (srcPtr: Ptr;
						dstPtr: Ptr;
						count: INTEGER); EXTERNAL;

PROCEDURE DeHexBytes (srcPtr: Ptr;
					  VAR srcCount: LONGINT;
					  VAR dstPtr: Ptr;
					  VAR dstCount: LONGINT;
					  table: TLookUpTable); EXTERNAL;

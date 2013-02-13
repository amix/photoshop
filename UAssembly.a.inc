{Photoshop version 1.0.1, file: UAssembly.a.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE DoSetBytes (dataPtr: Ptr;
					  count: LONGINT;
					  value: INTEGER); EXTERNAL;

PROCEDURE DoMapBytes (dataPtr: Ptr;
					  count: LONGINT;
					  map: TLookUpTable); EXTERNAL;

PROCEDURE DoHistBytes (dataPtr: Ptr;
					   maskPtr: Ptr;
					   count: LONGINT;
					   VAR hist: THistogram); EXTERNAL;

PROCEDURE DoSwapBytes (data1: Ptr;
					   data2: Ptr;
					   count: LONGINT); EXTERNAL;

PROCEDURE DoMaxBytes (data1: Ptr;
					  data2: Ptr;
					  data3: Ptr;
					  count: LONGINT); EXTERNAL;

PROCEDURE DoMinBytes (data1: Ptr;
					  data2: Ptr;
					  data3: Ptr;
					  count: LONGINT); EXTERNAL;

FUNCTION EqualBytes (data1: Ptr;
					 data2: Ptr;
					 count: INTEGER): BOOLEAN; EXTERNAL;

FUNCTION ConvertToGray (r, g, b: UNIV INTEGER): CHAR; EXTERNAL;

FUNCTION DoFindBounds (dataPtr: Ptr;
					   count: INTEGER;
					   VAR first: INTEGER;
					   VAR last: INTEGER): BOOLEAN; EXTERNAL;

PROCEDURE DoStepCopyBytes (srcPtr: Ptr;
						   dstPtr: Ptr;
						   count: INTEGER;
						   step1: INTEGER;
						   step2: INTEGER); EXTERNAL;

PROCEDURE CompareWords; EXTERNAL;

PROCEDURE CompareUnsignedLongs; EXTERNAL;

PROCEDURE MakeRamp (VAR map: TLookUpTable; limit: INTEGER); EXTERNAL;

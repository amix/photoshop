{Photoshop version 1.0.1, file: UCalculate.a.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE DoCompositeBytes (forePtr: Ptr;
							backPtr: Ptr;
							maskPtr: Ptr;
							count: INTEGER); EXTERNAL;

PROCEDURE DoBlendBytes (srcPtr: Ptr;
						dstPtr: Ptr;
						count: INTEGER;
						map1: TLookUpTable;
						map2: TLookUpTable); EXTERNAL;

PROCEDURE DoSubtractBytes (srcPtr: Ptr;
						   dstPtr: Ptr;
						   count: INTEGER;
						   scale: INTEGER;
						   offset: INTEGER); EXTERNAL;

PROCEDURE DoAddBytes (srcPtr: Ptr;
					  dstPtr: Ptr;
					  count: INTEGER;
					  scale: INTEGER;
					  offset: INTEGER); EXTERNAL;

PROCEDURE DoMultiplyBytes (srcPtr: Ptr;
						   dstPtr: Ptr;
						   count: INTEGER); EXTERNAL;

PROCEDURE DoScreenBytes (srcPtr: Ptr;
						 dstPtr: Ptr;
						 count: INTEGER); EXTERNAL;

PROCEDURE DoDiffBytes (srcPtr: Ptr;
					   dstPtr: Ptr;
					   count: INTEGER); EXTERNAL;

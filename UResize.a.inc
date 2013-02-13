{Photoshop version 1.0.1, file: UResize.a.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE DoSampleLine (srcPtr: Ptr;
						dstPtr: Ptr;
						count: INTEGER;
						offsets: UNIV Ptr); EXTERNAL;

PROCEDURE DoInterpolateLine (srcPtr: Ptr;
							 dstPtr: Ptr;
							 count: INTEGER;
							 offsets: UNIV Ptr;
							 weights: UNIV Ptr); EXTERNAL;

PROCEDURE DoBiCubicLine (srcPtr: Ptr;
						 dstPtr: Ptr;
						 srcCount: INTEGER;
						 dstCount: INTEGER;
						 offsets: UNIV Ptr;
						 weights: UNIV Ptr); EXTERNAL;

PROCEDURE DoInterpolateRow (srcPtr: Ptr;
							dstPtr: Ptr;
							count: INTEGER;
							weight: INTEGER); EXTERNAL;

PROCEDURE DoBiCubicRow (bufPtr: Ptr;
						count: INTEGER;
						weight: INTEGER); EXTERNAL;

PROCEDURE DoBigAverageLine (srcPtr: Ptr;
							dstPtr: Ptr;
							count: INTEGER;
							counts: UNIV Ptr); EXTERNAL;

PROCEDURE DoAddWeightedRow (srcPtr: Ptr;
							dstPtr: Ptr;
							count: INTEGER;
							weight: INTEGER); EXTERNAL;

PROCEDURE DoDivideRow (bufPtr: Ptr;
					   count: INTEGER;
					   total: INTEGER); EXTERNAL;

PROCEDURE DoAverageLine (srcPtr: Ptr;
						 dstPtr: Ptr;
						 count: INTEGER;
						 offsets: UNIV Ptr;
						 weights: UNIV Ptr;
						 total: INTEGER); EXTERNAL;

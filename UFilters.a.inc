{Photoshop version 1.0.1, file: UFilters.a.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE UpdateTotals (buffPtr: Ptr;
						dataPtr: Ptr;
						count: INTEGER;
						radius: INTEGER;
						add: BOOLEAN); EXTERNAL;

PROCEDURE DoBoxFilter (buffPtr: Ptr;
					   dataPtr: Ptr;
					   radius: INTEGER;
					   count: INTEGER); EXTERNAL;

PROCEDURE DoWeightedFilter (srcPtr: Ptr;
							dstPtr: Ptr;
							step: INTEGER;
							count: INTEGER;
							radius: INTEGER;
							weights: Ptr); EXTERNAL;

PROCEDURE SobelLine (prevPtr: Ptr;
					 thisPtr: Ptr;
					 nextPtr: Ptr;
					 destPtr: Ptr;
					 count: INTEGER;
					 atStart: BOOLEAN;
					 atEnd: BOOLEAN); EXTERNAL;

PROCEDURE MinOrMaxRow (srcPtr: Ptr;
					   dstPtr: Ptr;
					   count: INTEGER;
					   maxFlag: BOOLEAN); EXTERNAL;

PROCEDURE MinOrMaxRows (prevPtr: Ptr;
						thisPtr: Ptr;
						nextPtr: Ptr;
						destPtr: Ptr;
						count: INTEGER;
						maxFlag: BOOLEAN); EXTERNAL;

PROCEDURE ConvolveRow (inPtr: Ptr;
					   outPtr: Ptr;
					   numRows: INTEGER;
					   numCols: INTEGER;
					   rowBytes: INTEGER;
					   row: INTEGER;
					   col1: INTEGER;
					   col2: INTEGER;
					   kernel: UNIV Ptr); EXTERNAL;

PROCEDURE BlurLine (prevPtr: Ptr;
					thisPtr: Ptr;
					nextPtr: Ptr;
					destPtr: Ptr;
					count: INTEGER); EXTERNAL;

PROCEDURE BlurMoreLine (prevPtr: Ptr;
						thisPtr: Ptr;
						nextPtr: Ptr;
						destPtr: Ptr;
						count: INTEGER); EXTERNAL;

PROCEDURE SharpenLine (prevPtr: Ptr;
					   thisPtr: Ptr;
					   nextPtr: Ptr;
					   destPtr: Ptr;
					   count: INTEGER); EXTERNAL;

PROCEDURE SharpenMoreLine (prevPtr: Ptr;
						   thisPtr: Ptr;
						   nextPtr: Ptr;
						   destPtr: Ptr;
						   count: INTEGER); EXTERNAL;

PROCEDURE DoHighPassLine (srcPtr: Ptr;
						  dstPtr: Ptr;
						  count: INTEGER); EXTERNAL;

PROCEDURE DoUnsharpMaskLine (srcPtr: Ptr;
							 dstPtr: Ptr;
							 amount: INTEGER;
							 count: INTEGER); EXTERNAL;

PROCEDURE DoMedianFilter (srcPtr: Ptr;
						  dstPtr: Ptr;
						  rowBytes: INTEGER;
						  radius: INTEGER;
						  count: INTEGER;
						  rows: INTEGER;
						  col1: INTEGER;
						  col2: INTEGER); EXTERNAL;

PROCEDURE DoFacet1 (prevPtr: Ptr;
					thisPtr: Ptr;
					nextPtr: Ptr;
					destPtr: Ptr;
					count: INTEGER); EXTERNAL;

PROCEDURE DoFacet2 (prevPtr: Ptr;
					thisPtr: Ptr;
					nextPtr: Ptr;
					destPtr: Ptr;
					count: INTEGER); EXTERNAL;

PROCEDURE DoFacet3 (prevPtr: Ptr;
					thisPtr: Ptr;
					nextPtr: Ptr;
					destPtr: Ptr;
					count: INTEGER); EXTERNAL;

PROCEDURE DoFacet4 (prevPtr: Ptr;
					thisPtr: Ptr;
					nextPtr: Ptr;
					destPtr: Ptr;
					count: INTEGER); EXTERNAL;

PROCEDURE DoDiffuseDarken (prevPtr: Ptr;
						   thisPtr: Ptr;
						   nextPtr: Ptr;
						   destPtr: Ptr;
						   count: INTEGER); EXTERNAL;

PROCEDURE DoDiffuseLighten (prevPtr: Ptr;
							thisPtr: Ptr;
							nextPtr: Ptr;
							destPtr: Ptr;
							count: INTEGER); EXTERNAL;

PROCEDURE DoTraceContour (prevPtr: Ptr;
						  thisPtr: Ptr;
						  nextPtr: Ptr;
						  destPtr: Ptr;
						  count: INTEGER;
						  level: INTEGER;
						  upper: BOOLEAN); EXTERNAL;

PROCEDURE MakeDiffuseNoise (dstPtr: Ptr;
							count: INTEGER); EXTERNAL;

PROCEDURE MakeUniformNoise (dstPtr: Ptr;
							amount: INTEGER;
							count: INTEGER); EXTERNAL;

PROCEDURE MakeGaussianNoise (dstPtr: Ptr;
							 amount: INTEGER;
							 count: INTEGER); EXTERNAL;

PROCEDURE DoAddNoise (srcPtr: Ptr;
					  dstPtr: Ptr;
					  noisePtr: Ptr;
					  count: INTEGER); EXTERNAL;

PROCEDURE DoMosaicRow (dataPtr: Ptr;
					   cellSize: INTEGER;
					   count: INTEGER); EXTERNAL;

PROCEDURE SetJustInside (prevPtr: Ptr;
						 thisPtr: Ptr;
						 nextPtr: Ptr;
						 destPtr: Ptr;
						 count: INTEGER); EXTERNAL;

PROCEDURE SetJustOutside (prevPtr: Ptr;
						  thisPtr: Ptr;
						  nextPtr: Ptr;
						  destPtr: Ptr;
						  count: INTEGER); EXTERNAL;

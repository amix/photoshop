{Photoshop version 1.0.1, file: UConvert.a.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE DeHalftoneRow (srcPtr: Ptr;
						 dstPtr: Ptr;
						 rowBytes: INTEGER;
						 cols: INTEGER;
						 scale: INTEGER;
						 thresTable: TThresTable); EXTERNAL;

FUNCTION DoCountColors (rDataPtr: Ptr;
						gDataPtr: Ptr;
						bDataPtr: Ptr;
						size: INTEGER;
						colorTable: Ptr): BOOLEAN; EXTERNAL;

PROCEDURE DoMapColors (rDataPtr: Ptr;
					   gDataPtr: Ptr;
					   bDataPtr: Ptr;
					   size: INTEGER;
					   colorTable: Ptr;
					   outDataPtr: Ptr); EXTERNAL;

PROCEDURE DoBuildInverse (table: Ptr;
						  buffer: Ptr;
						  step: INTEGER); EXTERNAL;

PROCEDURE NoDitherRow (rDataPtr: Ptr;
					   gDataPtr: Ptr;
					   bDataPtr: Ptr;
					   outDataPtr: Ptr;
					   table: Ptr;
					   count: INTEGER); EXTERNAL;

PROCEDURE DiffuseRGB (rDataPtr: Ptr;
					  gDataPtr: Ptr;
					  bDataPtr: Ptr;
					  outDataPtr: Ptr;
					  thisError: Ptr;
					  nextError: Ptr;
					  table: Ptr;
					  LUT: TRGBLookUpTable;
					  count: INTEGER); EXTERNAL;

PROCEDURE Do5BitHistogram (rDataPtr: Ptr;
						   gDataPtr: Ptr;
						   bDataPtr: Ptr;
						   hist: Ptr;
						   weight: INTEGER;
						   count: INTEGER); EXTERNAL;

PROCEDURE DoProjectHist (minR: INTEGER;
						 maxR: INTEGER;
						 minG: INTEGER;
						 maxG: INTEGER;
						 minB: INTEGER;
						 maxB: INTEGER;
						 projectR: Ptr;
						 projectG: Ptr;
						 projectB: Ptr;
						 hist: Ptr); EXTERNAL;

PROCEDURE DitherRGB (rDataPtr: Ptr;
					 gDataPtr: Ptr;
					 bDataPtr: Ptr;
					 row: INTEGER;
					 numCols: INTEGER;
					 outDataPtr: Ptr;
					 ditherSize: INTEGER;
					 noiseTable: TNoiseTable;
					 thresTable: TThresTable;
					 colorTable: Ptr;
					 VAR colors: INTEGER); EXTERNAL;

PROCEDURE DoRGB2HSLorB (rPtr: Ptr;
						gPtr: Ptr;
						bPtr: Ptr;
						hPtr: Ptr;
						sPtr: Ptr;
						lPtr: Ptr;
						count: INTEGER;
						bright: BOOLEAN); EXTERNAL;

PROCEDURE DoHSLorB2RGB (hPtr: Ptr;
						sPtr: Ptr;
						lPtr: Ptr;
						rPtr: Ptr;
						gPtr: Ptr;
						bPtr: Ptr;
						count: LONGINT;
						bright: BOOLEAN); EXTERNAL;

{Photoshop version 1.0.1, file: UDither.a.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE DoDither (inDataPtr: Ptr;
					inRowBytes: INTEGER;
					outDataPtr: Ptr;
					outRowBytes: INTEGER;
					outPixelBits: INTEGER;
					viewRect: Rect;
					magnification: INTEGER;
					ditherSize: INTEGER;
					lookUpTable: TlookUpTable;
					noiseTable: TNoiseTable;
					thresTable: TThresTable;
					zeroFirst: BOOLEAN); EXTERNAL;

PROCEDURE DoHalftone (inDataPtr: Ptr;
					  inRowBytes: INTEGER;
					  outDataPtr: Ptr;
					  outRowBytes: INTEGER;
					  outPixelBits: INTEGER;
					  viewRect: Rect;
					  magnification: INTEGER); EXTERNAL;

PROCEDURE DoMonochrome (rDataPtr: Ptr;
						gDataPtr: Ptr;
						bDataPtr: Ptr;
						inRowBytes: INTEGER;
						outDataPtr: Ptr;
						viewRect: Rect;
						magnification: INTEGER;
						rLUT: TLookUpTable;
						gLUT: TLookUpTable;
						bLUT: TLookUpTable); EXTERNAL;

PROCEDURE DoDither24 (inDataPtr: Ptr;
					  inRowBytes: INTEGER;
					  outDataPtr: Ptr;
					  outRowBytes: LONGINT;
					  outStep: INTEGER;
					  viewRect: Rect;
					  magnification: INTEGER;
					  lookUpTable: TlookUpTable); EXTERNAL;

PROCEDURE DoDither16Red (srcPtr: Ptr;
						 srcRowBytes: INTEGER;
						 dstPtr: Ptr;
						 dstRowBytes: LONGINT;
						 numRows: INTEGER;
						 numCols: INTEGER); EXTERNAL;

PROCEDURE DoDither16Green (srcPtr: Ptr;
						   srcRowBytes: INTEGER;
						   dstPtr: Ptr;
						   dstRowBytes: LONGINT;
						   numRows: INTEGER;
						   numCols: INTEGER); EXTERNAL;

PROCEDURE DoDither16Blue (srcPtr: Ptr;
						  srcRowBytes: INTEGER;
						  dstPtr: Ptr;
						  dstRowBytes: LONGINT;
						  numRows: INTEGER;
						  numCols: INTEGER); EXTERNAL;

PROCEDURE DoPatternMap (map: BitMap;
						pat: Pattern); EXTERNAL;

PROCEDURE MoveMagnifData (srcPtr: Ptr;
						  dstPtr: Ptr;
						  count: INTEGER;
						  mag: INTEGER;
						  phase: INTEGER); EXTERNAL;

PROCEDURE MoveReductData (srcPtr: Ptr;
						  dstPtr: Ptr;
						  count: INTEGER;
						  red: INTEGER); EXTERNAL;

PROCEDURE DrawOutlineRow (prevPtr: Ptr;
						  thisPtr: Ptr;
						  nextPtr: Ptr;
						  outPtr: Ptr;
						  count: INTEGER); EXTERNAL;

FUNCTION IsRectZero (dataPtr: Ptr;
					 rowBytes: INTEGER;
					 rows: INTEGER;
					 cols: INTEGER): BOOLEAN; EXTERNAL;

PROCEDURE CompareColors; EXTERNAL;

PROCEDURE DoAddOver (srcPtr: Ptr;
					 dstPtr: Ptr;
					 map: TLookUpTable;
					 count: INTEGER); EXTERNAL;

PROCEDURE Extract16Red (srcPtr: Ptr;
						dstPtr: Ptr;
						count: INTEGER); EXTERNAL;

PROCEDURE Extract16Green (srcPtr: Ptr;
						  dstPtr: Ptr;
						  count: INTEGER); EXTERNAL;

PROCEDURE Extract16Blue (srcPtr: Ptr;
						 dstPtr: Ptr;
						 count: INTEGER); EXTERNAL;

PROCEDURE PackWords (VAR srcPtr: Ptr;
					 VAR dstPtr: Ptr;
					 count: INTEGER); EXTERNAL;

PROCEDURE UnpackWords (VAR srcPtr: Ptr;
					   VAR dstPtr: Ptr;
					   count: INTEGER); EXTERNAL;

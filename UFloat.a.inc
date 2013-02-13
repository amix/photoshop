{Photoshop version 1.0.1, file: UFloat.a.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE DoMakeMonochrome (rPtr: Ptr;
							rTable: TLookUpTable;
							gPtr: Ptr;
							gTable: TLookUpTable;
							bPtr: Ptr;
							bTable: TLookUpTable;
							mPtr: Ptr;
							count: INTEGER); EXTERNAL;

PROCEDURE ZapMaskRGB (rDataPtr: Ptr;
					  gDataPtr: Ptr;
					  bDataPtr: Ptr;
					  grayLUT: TRGBLookUpTable;
					  maskPtr: Ptr;
					  count: INTEGER;
					  map: TLookUpTable); EXTERNAL;

PROCEDURE ZapMaskLUT (dataPtr: Ptr;
					  maskPtr: Ptr;
					  count: INTEGER;
					  map: TLookUpTable); EXTERNAL;

PROCEDURE DoBlendBelow (maskPtr: Ptr;
						floatPtr: Ptr;
						belowPtr: Ptr;
						count: INTEGER;
						mode: INTEGER;
						mat: INTEGER); EXTERNAL;

PROCEDURE DoBlendColorOnly (grayPtr: Ptr;
							rPtr: Ptr;
							gPtr: Ptr;
							bPtr: Ptr;
							grayLUT: TRGBLookUpTable;
							count: INTEGER); EXTERNAL;

PROCEDURE DoMaskBinary (maskPtr: Ptr;
						dataPtr: Ptr;
						count: INTEGER); EXTERNAL;

PROCEDURE DoPatternFill (srcPtr: Ptr;
						 dstPtr: Ptr;
						 width: INTEGER;
						 count: INTEGER); EXTERNAL;

PROCEDURE DoLinearGradient (dstPtr: Ptr;
							count: INTEGER;
							base: LONGINT;
							step: LONGINT;
							dist: LONGINT;
							table: Ptr); EXTERNAL;

PROCEDURE DoRadialGradient (dstPtr: Ptr;
							count: INTEGER;
							deltaRow: INTEGER;
							deltaCol: INTEGER;
							dist: LONGINT;
							table: Ptr); EXTERNAL;

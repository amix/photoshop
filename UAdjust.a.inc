{Photoshop version 1.0.1, file: UAdjust.a.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

FUNCTION FindGamma (x: INTEGER; gamma: INTEGER): INTEGER; EXTERNAL;

PROCEDURE DoHistLuminosity (data1Ptr: Ptr;
							data2Ptr: Ptr;
							data3Ptr: Ptr;
							maskPtr: Ptr;
							maps: TRGBLookUpTable;
							count: INTEGER;
							VAR hist: THistogram); EXTERNAL;

PROCEDURE ThresholdLuminosity (data1Ptr: Ptr;
							   data2Ptr: Ptr;
							   data3Ptr: Ptr;
							   maps: TRGBLookUpTable;
							   count: INTEGER;
							   threshold: INTEGER); EXTERNAL;

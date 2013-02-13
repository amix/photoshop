{Photoshop version 1.0.1, file: USelect.a.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE DoDeltaMask (srcPtr: Ptr;
					   dstPtr: Ptr;
					   count: INTEGER); EXTERNAL;

PROCEDURE MergeForward (prevPtr: Ptr;
						thisPtr: Ptr;
						count: INTEGER;
						VAR map: TLookUpTable); EXTERNAL;

PROCEDURE PropagateBackward (thisPtr: Ptr;
							 count: INTEGER); EXTERNAL;

FUNCTION MarkNewRegions (thisPtr: Ptr;
						 count: INTEGER;
						 VAR nextRgn: INTEGER): BOOLEAN; EXTERNAL;

FUNCTION SolidRow (dataPtr: Ptr;
				   count: INTEGER): BOOLEAN; EXTERNAL;

PROCEDURE Do6DHistogram (rData: Ptr;
						 gData: Ptr;
						 bData: Ptr;
						 mData: Ptr;
						 count: INTEGER;
						 hData: Ptr); EXTERNAL;

PROCEDURE Do6DMinimum (rData: Ptr;
					   gData: Ptr;
					   bData: Ptr;
					   mData: Ptr;
					   maps: Ptr;
					   count: INTEGER); EXTERNAL;

FUNCTION ConnectAcross (p: Ptr;
						count: INTEGER;
						VAR left: INTEGER;
						VAR right: INTEGER): BOOLEAN; EXTERNAL;

FUNCTION ConnectDown (p1: Ptr;
					  p2: Ptr;
					  left: INTEGER;
					  right: INTEGER): BOOLEAN; EXTERNAL;

PROCEDURE DilateAcross (p: Ptr;
						count: INTEGER); EXTERNAL;

PROCEDURE DilateDown (p1: Ptr;
					  p2: Ptr;
					  count: INTEGER); EXTERNAL;

PROCEDURE DoMarkMasked (srcPtr: Ptr;
						dstPtr: Ptr;
						count: INTEGER); EXTERNAL;

PROCEDURE DoTaxiCab (dataPtr: Ptr;
					 step: INTEGER;
					 count: INTEGER;
					 block: INTEGER); EXTERNAL;

PROCEDURE DefringeAcross (maskPtr: Ptr;
						  dataPtr: Ptr;
						  count: INTEGER;
						  step: INTEGER;
						  update: BOOLEAN); EXTERNAL;

PROCEDURE DefringeDown (maskPtr1: Ptr;
						dataPtr1: Ptr;
						maskPtr2: Ptr;
						dataPtr2: Ptr;
						count: INTEGER;
						update: BOOLEAN); EXTERNAL;

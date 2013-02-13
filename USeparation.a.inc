{Photoshop version 1.0.1, file: USeparation.a.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

TYPE
	TInkTransform = ARRAY [1..3, 1..7] OF INTEGER;

FUNCTION Map8to12Bit (index: INTEGER;
					  gamma: INTEGER): INTEGER; EXTERNAL;

FUNCTION Map12to8Bit (index: INTEGER;
					  gamma: INTEGER): INTEGER; EXTERNAL;

PROCEDURE DoInkTransform (c: INTEGER;
						  m: INTEGER;
						  y: INTEGER;
						  VAR r: INTEGER;
						  VAR g: INTEGER;
						  VAR b: INTEGER;
						  transform: TInkTransform); EXTERNAL;

PROCEDURE FindSeedCMY (r: INTEGER;
					   g: INTEGER;
					   b: INTEGER;
					   VAR c: INTEGER;
					   VAR m: INTEGER;
					   VAR y: INTEGER;
					   coords: Ptr); EXTERNAL;

PROCEDURE FindDeltaCMY (dr: INTEGER;
						dg: INTEGER;
						db: INTEGER;
						VAR dc: INTEGER;
						VAR dm: INTEGER;
						VAR dy: INTEGER;
						slope: Ptr); EXTERNAL;

FUNCTION ProjectFace (VAR r: INTEGER;
					  VAR g: INTEGER;
					  VAR b: INTEGER;
					  face: Ptr): BOOLEAN; EXTERNAL;

FUNCTION ProjectEdge (VAR r: INTEGER;
					  VAR g: INTEGER;
					  VAR b: INTEGER;
					  edge: Ptr): LONGINT; EXTERNAL;

FUNCTION ProjectLine (VAR r: INTEGER;
					  VAR g: INTEGER;
					  VAR b: INTEGER;
					  rr: INTEGER;
					  gg: INTEGER;
					  bb: INTEGER;
					  face: Ptr): LONGINT; EXTERNAL;

FUNCTION ProjectGray (r: INTEGER;
					  g: INTEGER;
					  b: INTEGER;
					  face: Ptr): INTEGER; EXTERNAL;

PROCEDURE ClipRGBValue (VAR r: INTEGER;
						VAR g: INTEGER;
						VAR b: INTEGER); EXTERNAL;

PROCEDURE BuildFMTable1 (table: Handle); EXTERNAL;

PROCEDURE DoColorCorrect (rPtr: Ptr;
						  gPtr: Ptr;
						  bPtr: Ptr;
						  table1: Handle;
						  table2: Handle;
						  count: INTEGER); EXTERNAL;

PROCEDURE CvtHVStoRGB (h: INTEGER;
					   v: INTEGER;
					   s: INTEGER;
					   VAR r: INTEGER;
					   VAR g: INTEGER;
					   VAR b: INTEGER); EXTERNAL;

PROCEDURE BuildFMTable2 (table: Handle); EXTERNAL;

PROCEDURE DoSeparateColors (cPtr: Ptr;
							mPtr: Ptr;
							yPtr: Ptr;
							kPtr: Ptr;
							table1: Handle;
							table2: Handle;
							count: INTEGER); EXTERNAL;

PROCEDURE DoReplaceBlack (cPtr: Ptr;
						  mPtr: Ptr;
						  yPtr: Ptr;
						  kPtr: Ptr;
						  table1: Ptr;
						  table2: Ptr;
						  count: INTEGER); EXTERNAL;

PROCEDURE DoCMYK2Gray (cPtr: Ptr;
					   mPtr: Ptr;
					   yPtr: Ptr;
					   kPtr: Ptr;
					   gPtr: Ptr;
					   grayLUT: TRGBLookUpTable;
					   count: INTEGER); EXTERNAL;

{Photoshop version 1.0.1, file: UScreen.a.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

FUNCTION InsideUnitCell (row: INTEGER;
						 col: INTEGER;
						 j: INTEGER;
						 k: INTEGER): BOOLEAN; EXTERNAL;

PROCEDURE CvtToGridCoords (row: INTEGER;
						   col: INTEGER;
						   cosTheta: INTEGER;
						   sinTheta: INTEGER;
						   frequency: LONGINT;
						   VAR x: INTEGER;
						   VAR y: INTEGER;
						   VAR xf: INTEGER;
						   VAR yf: INTEGER); EXTERNAL;

PROCEDURE NormGridCoords (m: INTEGER;
						  n: INTEGER;
						  hs: LONGINT;
						  VAR x: INTEGER;
						  VAR y: INTEGER); EXTERNAL;

FUNCTION DotScreenProc (x: INTEGER;
						y: INTEGER): LONGINT; EXTERNAL;

FUNCTION EllipseScreenProc (x: INTEGER;
							y: INTEGER): LONGINT; EXTERNAL;

FUNCTION LineScreenProc (x: INTEGER;
						 y: INTEGER): LONGINT; EXTERNAL;

FUNCTION SquareScreenProc (x: INTEGER;
						   y: INTEGER): LONGINT; EXTERNAL;

FUNCTION CrossScreenProc (x: INTEGER;
						  y: INTEGER): LONGINT; EXTERNAL;

PROCEDURE CompareCells; EXTERNAL;

FUNCTION ClusterOffset (xCell: INTEGER;
						yCell: INTEGER;
						cluster: INTEGER): INTEGER; EXTERNAL;

PROCEDURE CompScreenValues (buffer: Ptr;
							count: INTEGER;
							rowBase: INTEGER;
							colBase: INTEGER;
							cluster: INTEGER;
							offset: INTEGER;
							cellData: Ptr;
							cellSize: INTEGER); EXTERNAL;

PROCEDURE DoStepSwapBytes (dataPtr1: Ptr;
						   dataPtr2: Ptr;
						   count: INTEGER;
						   step1: INTEGER;
						   step2: INTEGER); EXTERNAL;

PROCEDURE MakeWhiteNoise (data: Ptr;
						  count: LONGINT;
						  min: INTEGER;
						  max: INTEGER); EXTERNAL;

PROCEDURE DoScreenRow (srcPtr: Ptr;
					   dstPtr: Ptr;
					   count: INTEGER;
					   cellData: Ptr;
					   cellSize: INTEGER); EXTERNAL;

PROCEDURE DoDiffuseRow (srcPtr: Ptr;
						dstPtr: Ptr;
						thisError: Ptr;
						nextError: Ptr;
						noisePtr: Ptr;
						count: INTEGER); EXTERNAL;

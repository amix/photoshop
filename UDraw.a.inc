{Photoshop version 1.0.1, file: UDraw.a.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE DoEraseRect (dataPtr: Ptr;
					   dataWidth: INTEGER;
					   rows: INTEGER;
					   cols: INTEGER;
					   color: INTEGER); EXTERNAL;

PROCEDURE DoMagicRect (srcPtr: Ptr;
					   dstPtr: Ptr;
					   dataWidth: INTEGER;
					   rows: INTEGER;
					   cols: INTEGER); EXTERNAL;

PROCEDURE DoAlphaEraseRect (dataPtr: Ptr;
							alphaPtr: Ptr;
							dataWidth: INTEGER;
							rows: INTEGER;
							cols: INTEGER;
							color: INTEGER); EXTERNAL;

PROCEDURE DoAlphaMagicRect (srcPtr: Ptr;
							dstPtr: Ptr;
							alphaPtr: Ptr;
							dataWidth: INTEGER;
							rows: INTEGER;
							cols: INTEGER); EXTERNAL;

PROCEDURE DoAlphaMask (maskPtr: Ptr;
					   alphaPtr: Ptr;
					   maskWidth: INTEGER;
					   alphaWidth: INTEGER;
					   rows: INTEGER;
					   cols: INTEGER); EXTERNAL;

PROCEDURE DoFadeMask (srcPtr: Ptr;
					  dstPtr: Ptr;
					  count: INTEGER;
					  drawings: INTEGER;
					  fadeout: INTEGER); EXTERNAL;

PROCEDURE DoThresholdMask (srcPtr: Ptr;
						   dstPtr: Ptr;
						   count: INTEGER;
						   pressure: INTEGER); EXTERNAL;

PROCEDURE DoNarrowMask (srcPtr: Ptr;
						dstPtr: Ptr;
						count: INTEGER;
						pressure: INTEGER); EXTERNAL;

PROCEDURE DoGetTip (dataPtr: Ptr;
					buffPtr: Ptr;
					dataWidth: INTEGER;
					buffWidth: INTEGER;
					rows: INTEGER;
					cols: INTEGER); EXTERNAL;

PROCEDURE DoGetBlurred (dataPtr: Ptr;
						buffPtr: Ptr;
						dataWidth: INTEGER;
						buffWidth: INTEGER;
						rows: INTEGER;
						cols: INTEGER); EXTERNAL;

PROCEDURE DoGetSharpened (dataPtr: Ptr;
						  buffPtr: Ptr;
						  dataWidth: INTEGER;
						  buffWidth: INTEGER;
						  rows: INTEGER;
						  cols: INTEGER); EXTERNAL;

PROCEDURE DoMixBytes (oldPtr: Ptr;
					  newPtr: Ptr;
					  mixMap: TLookUpTable;
					  count: INTEGER); EXTERNAL;

PROCEDURE DoDrawTip (dataPtr: Ptr;
					 maskPtr: Ptr;
					 buffPtr: Ptr;
					 dataWidth: INTEGER;
					 maskWidth: INTEGER;
					 rows: INTEGER;
					 cols: INTEGER); EXTERNAL;

PROCEDURE DoDrawTipDarken (dataPtr: Ptr;
						   maskPtr: Ptr;
						   buffPtr: Ptr;
						   dataWidth: INTEGER;
						   maskWidth: INTEGER;
						   rows: INTEGER;
						   cols: INTEGER); EXTERNAL;

PROCEDURE DoDrawTipLighten (dataPtr: Ptr;
							maskPtr: Ptr;
							buffPtr: Ptr;
							dataWidth: INTEGER;
							maskWidth: INTEGER;
							rows: INTEGER;
							cols: INTEGER); EXTERNAL;

PROCEDURE DoDrawTipColor (grayLUT: TRGBLookUpTable;
						  rDataPtr: Ptr;
						  gDataPtr: Ptr;
						  bDataPtr: Ptr;
						  maskPtr: Ptr;
						  rBuffPtr: Ptr;
						  gBuffPtr: Ptr;
						  bBuffPtr: Ptr;
						  dataWidth: INTEGER;
						  maskWidth: INTEGER;
						  rows: INTEGER;
						  cols: INTEGER); EXTERNAL;

PROCEDURE MakeTextureNoise (noisePtr: Ptr;
							count: INTEGER); EXTERNAL;

PROCEDURE ScrambleTexture (dataPtr: Ptr;
						   noisePtr: Ptr); EXTERNAL;

PROCEDURE DoCopyForward (srcPtr: Ptr;
						 dstPtr: Ptr;
						 count: INTEGER); EXTERNAL;

PROCEDURE DoCopyBackward (srcPtr: Ptr;
						  dstPtr: Ptr;
						  count: INTEGER); EXTERNAL;

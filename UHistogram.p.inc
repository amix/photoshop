{Photoshop version 1.0.1, file: UHistogram.p.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE GetHistogram (view: TImageView;
						luminosity: BOOLEAN;
						VAR hist0: THistogram;
						VAR hist1: THistogram;
						VAR hist2: THistogram;
						VAR hist3: THistogram); EXTERNAL;

PROCEDURE DrawHistogram (hist: THistogram; bounds: Rect); EXTERNAL;

PROCEDURE DoHistogramCommand (view: TImageView); EXTERNAL;

{Photoshop version 1.0.1, file: UAbout.p.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE RegisterCopy; EXTERNAL;

PROCEDURE ShowSplashScreen; EXTERNAL;

PROCEDURE KillSplashScreen; EXTERNAL;

PROCEDURE DoAboutPhotoshop; EXTERNAL;

PROCEDURE MakeSizeString (doc: TImageDocument;
						  across: BOOLEAN;
						  VAR s: Str255); EXTERNAL;

PROCEDURE MakeResString (doc: TImageDocument;
						 align: BOOLEAN;
						 VAR s: Str255); EXTERNAL;

PROCEDURE DoSizeBoxPopUp (doc: TImageDocument;
						  r: Rect;
						  info: EventInfo); EXTERNAL;

PROCEDURE VerifyEvE; EXTERNAL;

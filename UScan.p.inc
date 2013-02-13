{Photoshop version 1.0.1, file: UScan.p.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE VerifyHardware; EXTERNAL;

PROCEDURE InitScanners; EXTERNAL;

PROCEDURE DoAcquireCommand (name: Str255); EXTERNAL;

PROCEDURE DoExportCommand (doc: TImageDocument; name: Str255); EXTERNAL;

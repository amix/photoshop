{Photoshop version 1.0.1, file: UInternal.p.inc
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROCEDURE ReadMiscResources (doc: TImageDocument); EXTERNAL;

PROCEDURE MiscResourcesBytes (doc: TImageDocument;
							  VAR rsrcForkBytes: LONGINT); EXTERNAL;

PROCEDURE WriteMiscResources (doc: TImageDocument); EXTERNAL;

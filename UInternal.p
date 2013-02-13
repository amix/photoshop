{Photoshop version 1.0.1, file: UInternal.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UInternal;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UBWDialog, URootFormat, UProgress;

TYPE

	TMultidiskStamp = RECORD
		fName: STRING[63];
		fDate: LONGINT;
		fTime: LONGINT;
		fPart: INTEGER
		END;

	PMultidiskStamp = ^TMultidiskStamp;
	HMultidiskStamp = ^PMultidiskStamp;

	TInternalFormat = OBJECT (TRootFormat)

		fMultidisk: BOOLEAN;

		fRow: INTEGER;
		fChannel: INTEGER;

		fLastVRefNum: INTEGER;

		fStamp: TMultidiskStamp;

		PROCEDURE TInternalFormat.IImageFormat; OVERRIDE;

		FUNCTION TInternalFormat.CanWrite
				(doc: TImageDocument): BOOLEAN; OVERRIDE;

		PROCEDURE TInternalFormat.ReadPart (doc: TImageDocument);

		PROCEDURE TInternalFormat.DoRead
				(doc: TImageDocument;
				 refNum: INTEGER;
				 rsrcExists: BOOLEAN); OVERRIDE;

		PROCEDURE TInternalFormat.ReadNext
				(doc: TImageDocument; name: Str255);

		PROCEDURE TInternalFormat.ReadOther
				(doc: TImageDocument; name: Str255); OVERRIDE;

		PROCEDURE TInternalFormat.AboutToSave
				(doc: TImageDocument;
				 itsCmd: INTEGER;
				 VAR name: Str255;
				 VAR vRefNum: INTEGER;
				 VAR makingCopy: BOOLEAN); OVERRIDE;

		FUNCTION TInternalFormat.DataForkBytes
				(doc: TImageDocument): LONGINT; OVERRIDE;

		FUNCTION TInternalFormat.SpotBytes (doc: TImageDocument): LONGINT;

		FUNCTION TInternalFormat.RsrcForkBytes
				(doc: TImageDocument): LONGINT; OVERRIDE;

		PROCEDURE TInternalFormat.AddResources (doc: TImageDocument);

		PROCEDURE TInternalFormat.AddStamp;

		PROCEDURE TInternalFormat.FillUpDisk (doc: TImageDocument);

		PROCEDURE TInternalFormat.DoWrite
				(doc: TImageDocument; refNum: INTEGER); OVERRIDE;

		PROCEDURE TInternalFormat.EjectLastVolume;

		PROCEDURE TInternalFormat.WriteNext
				(doc: TImageDocument; name: Str255);

		PROCEDURE TInternalFormat.WriteOther
				(doc: TImageDocument; name: Str255); OVERRIDE;

		END;

	TMiscResource = OBJECT (TObject)

		fID: INTEGER;
		fType: ResType;

		fData: Handle;

		PROCEDURE TMiscResource.Free; OVERRIDE;

		END;

PROCEDURE ReadMiscResources (doc: TImageDocument);

PROCEDURE MiscResourcesBytes (doc: TImageDocument;
							  VAR rsrcForkBytes: LONGINT);

PROCEDURE WriteMiscResources (doc: TImageDocument);

IMPLEMENTATION

{$I UInternal.inc1.p}

END.

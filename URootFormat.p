{Photoshop version 1.0.1, file: URootFormat.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT URootFormat;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UBWDialog, UProgress;

TYPE

	TOSTypeText = OBJECT (TKeyHandler)

		fValue: OSType;

		PROCEDURE TOSTypeText.IOSTypeText (itsItemNumber: INTEGER;
										   itsParent: TDialogView;
										   initValue: OSType);

		PROCEDURE TOSTypeText.Validate (VAR succeeded: BOOLEAN); OVERRIDE;

		END;

	TRootFormat = OBJECT (TImageFormat)

		fDialogID: INTEGER;

		fFTypeItem: INTEGER;
		fFCreatorItem: INTEGER;

		fCheckBoxes: INTEGER;
		fCheck1Item: INTEGER;
		fCheck2Item: INTEGER;
		fCheck3Item: INTEGER;

		fRadioClusters: INTEGER;
		fRadio1Item: INTEGER;
		fRadio1Count: INTEGER;
		fRadio2Item: INTEGER;
		fRadio2Count: INTEGER;

		fInts: INTEGER;
		fInt1Item: INTEGER;
		fInt1Lower: LONGINT;
		fInt1Upper: LONGINT;

		fStrs: INTEGER;
		fStr1Item: INTEGER;

		fCheck1: BOOLEAN;
		fCheck2: BOOLEAN;
		fCheck3: BOOLEAN;

		fRadio1: INTEGER;
		fRadio2: INTEGER;

		fInt1: LONGINT;

		fStr1: StringPtr;

		fLSBFirst: BOOLEAN;

		fRefNum: INTEGER;

		fSpool: BOOLEAN;
		fSpoolData: Handle;
		fSpoolPosition: LONGINT;
		fSpoolEOFPosition: LONGINT;

		PROCEDURE TRootFormat.IImageFormat; OVERRIDE;

		PROCEDURE TRootFormat.DoOptionsDialog;

		FUNCTION TRootFormat.GetFileLength: LONGINT;

		FUNCTION TRootFormat.GetFilePosition: LONGINT;

		PROCEDURE TRootFormat.SeekTo (n: LONGINT);

		PROCEDURE TRootFormat.SkipBytes (n: LONGINT);

		PROCEDURE TRootFormat.GetBytes (n: LONGINT; p: Ptr);

		FUNCTION TRootFormat.GetByte: INTEGER;

		FUNCTION TRootFormat.GetWord: INTEGER;

		FUNCTION TRootFormat.GetLong: LONGINT;

		PROCEDURE TRootFormat.GetRawRows (buffer: TVMArray;
										  rowBytes: INTEGER;
										  first: INTEGER;
										  count: INTEGER;
										  canAbort: BOOLEAN);

		PROCEDURE TRootFormat.GetInterleavedRows (buffer: TChannelArrayList;
												  channels: INTEGER;
												  first: INTEGER;
												  count: INTEGER;
												  canAbort: BOOLEAN);

		PROCEDURE TRootFormat.PutBytes (n: LONGINT; p: Ptr);

		PROCEDURE TRootFormat.PutByte (w: INTEGER);

		PROCEDURE TRootFormat.PutWord (w: INTEGER);

		PROCEDURE TRootFormat.PutLong (l: LONGINT);

		PROCEDURE TRootFormat.PutZeros (n: LONGINT);

		PROCEDURE TRootFormat.PutRawRows (buffer: TVMArray;
										  rowBytes: INTEGER;
										  first: INTEGER;
										  count: INTEGER);

		PROCEDURE TRootFormat.PutInterleavedRows (buffer: TChannelArrayList;
												  channels: INTEGER;
												  first: INTEGER;
												  count: INTEGER);

		END;

PROCEDURE MyPackBits (VAR srcPtr, dstPtr: Ptr; srcBytes: INTEGER);

PROCEDURE TestForMonochrome (doc: TImageDocument);

PROCEDURE TestForHalftone (doc: TImageDocument);

FUNCTION AskAdjustAspect: BOOLEAN;

IMPLEMENTATION

{$I URootFormat.inc1.p}

END.

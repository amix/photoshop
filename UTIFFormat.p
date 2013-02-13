{Photoshop version 1.0.1, file: UTIFFormat.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UTIFFormat;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, URootFormat, ULZWCompress, UProgress;

TYPE

	TTIFFormat = OBJECT (TRootFormat)

		fDoc: TImageDocument;

		fMotorola: BOOLEAN;
		fCompressed: BOOLEAN;

		fMetric: BOOLEAN;
		fResolution: EXTENDED;

		fPredictor: INTEGER;
		fBitsPerSample: INTEGER;
		fCompressionCode: INTEGER;
		fPlanarConfiguration: INTEGER;
		fPhotometricInterpretation: INTEGER;

		fStripOffsets: LONGINT;
		fStripByteCounts: LONGINT;

		fLongStripOffsets: BOOLEAN;
		fLongStripByteCounts: BOOLEAN;

		fRowsPerStrip: INTEGER;

		PROCEDURE TTIFFormat.IImageFormat; OVERRIDE;

		FUNCTION TTIFFormat.CanWrite (doc: TImageDocument): BOOLEAN; OVERRIDE;

		PROCEDURE TTIFFormat.SetFormatOptions (doc: TImageDocument); OVERRIDE;

		PROCEDURE TTIFFormat.ParseTag (tagCode: INTEGER;
									   tagType: INTEGER;
									   tagCount: LONGINT);

		PROCEDURE TTIFFormat.DecompressCCITT (VAR srcPtr: Ptr; dstPtr: Ptr);

		PROCEDURE TTIFFormat.DecompressLZW (srcPtr, dstPtr: Ptr;
											count: LONGINT);

		PROCEDURE TTIFFormat.ReadPlaneStrip (plane: INTEGER;
											 strip: INTEGER;
											 count: LONGINT);

		PROCEDURE TTIFFormat.ReadRGBStrip (strip: INTEGER; count: LONGINT);

		PROCEDURE TTIFFormat.AdjustPlane (plane: INTEGER);

		PROCEDURE TTIFFormat.AddBitPlane (srcArray: TVMArray;
										  dstArray: TVMArray);

		PROCEDURE TTIFFormat.DoRead (doc: TImageDocument;
									 refNum: INTEGER;
									 rsrcExists: BOOLEAN); OVERRIDE;

		FUNCTION TTIFFormat.DataForkBytes
				(doc: TImageDocument): LONGINT; OVERRIDE;

		FUNCTION TTIFFormat.CompressStrip (srcPtr: Ptr;
										   dstPtr: Ptr;
										   srcBytes: LONGINT;
										   dstBytes: LONGINT): LONGINT;

		PROCEDURE TTIFFormat.WriteLZW (doc: TImageDocument;
									   stripsPerImage: INTEGER;
									   rowBytes: LONGINT);

		PROCEDURE TTIFFormat.DoWrite
				(doc: TImageDocument; refNum: INTEGER); OVERRIDE;

		END;

IMPLEMENTATION

{$I UTIFFormat.inc1.p}

END.

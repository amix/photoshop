{Photoshop version 1.0.1, file: UInitFormats.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UInitFormats;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, URootFormat, UInternal, UPICTFile, UPICTResource,
	URawFormat, UThunderScan, UTIFFormat, UGIFFormat, UMacPaint,
	UPixelPaint, UIFFFormat, UPixar, UEPSFormat, UScitexFormat, UTarga;

PROCEDURE InitFormats;

IMPLEMENTATION

{$S AInit}

PROCEDURE InitFormats;

	VAR
		code: INTEGER;
		anInternalFormat   : TInternalFormat;
		aPICTFileFormat    : TPICTFileFormat;
		aPICTResourceFormat: TPICTResourceFormat;
		aRawFormat		   : TRawFormat;
		aThunderScanFormat : TThunderScanFormat;
		aTIFFormat		   : TTIFFormat;
		aGIFFormat		   : TGIFFormat;
		aMacPaintFormat    : TMacPaintFormat;
		aPixelPaintFormat  : TPixelPaintFormat;
		anIFFFormat 	   : TIFFFormat;
		aPixarFormat	   : TPixarFormat;
		anEPSFormat 	   : TEPSFormat;
		aScitexFormat	   : TScitexFormat;
		aTargaFormat	   : TTargaFormat;

	BEGIN

	NEW (anInternalFormat);
	FailNil (anInternalFormat);

	NEW (aPICTFileFormat);
	FailNil (aPICTFileFormat);

	NEW (aPICTResourceFormat);
	FailNil (aPICTResourceFormat);

	NEW (aRawFormat);
	FailNil (aRawFormat);

	NEW (aThunderScanFormat);
	FailNil (aThunderScanFormat);

	NEW (aTIFFormat);
	FailNil (aTIFFormat);

	NEW (aGIFFormat);
	FailNil (aGIFFormat);

	NEW (aMacPaintFormat);
	FailNil (aMacPaintFormat);

	NEW (aPixelPaintFormat);
	FailNil (aPixelPaintFormat);

	NEW (anIFFFormat);
	FailNil (anIFFFormat);

	NEW (aPixarFormat);
	FailNil (aPixarFormat);

	NEW (anEPSFormat);
	FailNil (anEPSFormat);

	NEW (aTargaFormat);
	FailNil (aTargaFormat);

	gFormats [kFmtCodeInternal] 	:= anInternalFormat;
	gFormats [kFmtCodeIFF]			:= anIFFFormat;
	gFormats [kFmtCodeGIF]			:= aGIFFormat;
	gFormats [kFmtCodeEPS]			:= anEPSFormat;
	gFormats [kFmtCodeMacPaint] 	:= aMacPaintFormat;
	gFormats [kFmtCodePICTFile] 	:= aPICTFileFormat;
	gFormats [kFmtCodePICTResource] := aPICTResourceFormat;
	gFormats [kFmtCodePixar]		:= aPixarFormat;
	gFormats [kFmtCodePixelPaint]	:= aPixelPaintFormat;
	gFormats [kFmtCodeRaw]			:= aRawFormat;
	gFormats [kFmtCodeTarga]		:= aTargaFormat;
	gFormats [kFmtCodeThunderScan]	:= aThunderScanFormat;
	gFormats [kFmtCodeTIFF] 		:= aTIFFormat;

	{$IFC NOT qBarneyscan}

	NEW (aScitexFormat);
	FailNil (aScitexFormat);

	gFormats [kFmtCodeScitex] := aScitexFormat;

	{$ENDC}

	FOR code := 0 TO kLastFmtCode DO
		gFormats [code] . IImageFormat;

	NEW (gClipFormat);
	FailNil (gClipFormat);

	gClipFormat.IImageFormat

	END;

END.

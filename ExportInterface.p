{Photoshop version 1.0.1, file: ExportInterface.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{
	File: ExportInterface.p

	Copyright 1990 by Thomas Knoll.

	This file describes version 3 of Photoshop's Export module interface.
}

UNIT ExportInterface;

INTERFACE

USES
	MemTypes, QuickDraw, OSIntf;

CONST

	{ Operation selectors }

	exportSelectorAbout    = 0;
	exportSelectorStart    = 1;
	exportSelectorContinue = 2;
	exportSelectorFinish   = 3;
	exportSelectorPrepare  = 4;

	{ Image modes }

	exportModeBitmap	   = 0;
	exportModeGrayScale    = 1;
	exportModeIndexedColor = 2;
	exportModeRGBColor	   = 3;
	exportModeCMYKColor    = 4;
	exportModeHSLColor	   = 5;
	exportModeHSBColor	   = 6;
	exportModeMultichannel = 7;

	{ Error return values. The plug-in module may also return standard Macintosh
	  operating system error codes, or report its own errors, in which case it
	  can return any positive integer. }

	exportBadParameters  = -30200;	{ "a problem with the export module interface" }
	exportBadMode		 = -30201;	{ "the export module does not support <mode> images" }

TYPE

	ExportLUT = PACKED ARRAY [0..255] OF CHAR;

	ExportRecord = RECORD

		serialNumber:	LONGINT;	{ Photoshop's serial number, to allow
									  copy protected plug-in modules. }
		abortProc:		ProcPtr;	{ The plug-in module may call this no-argument
									  BOOLEAN function (using Pascal calling
									  conventions) several times a second during long
									  operations to allow the user to abort the operation.
									  If it returns TRUE, the operation should be aborted
									  (and a positive error code returned). }
		progressProc:	ProcPtr;	{ The plug-in module may call this two-argument
									  procedure (using Pascal calling conventions)
									  periodically to update a progress indicator.
									  The first parameter (type LONGINT) is the number
									  of operations completed; the second (type LONGINT)
									  is the total number of operations. }

		maxData:		LONGINT;	{ Maximum number of bytes that should be
									  requested at once (the plug-in should reduce
									  its requests by the size any large buffers
									  it allocates). The plug-in may reduce this
									  value in the exportSelectorPrepare routine. }

		imageMode:		INTEGER;	{ Image mode }
		imageSize:		Point;		{ Size of image }
		depth:			INTEGER;	{ Bits per sample, currently will be 1 or 8 }
		planes: 		INTEGER;	{ Samples per pixel }
		imageHRes:		Fixed;		{ Pixels per inch }
		imageVRes:		Fixed;		{ Pixels per inch }
		redLUT: 		ExportLUT;	{ Red LUT, only used for Indexed Color images }
		greenLUT:		ExportLUT;	{ Green LUT, only used for Indexed Color images }
		blueLUT:		ExportLUT;	{ Blue LUT, only used for Indexed Color images }

		theRect:		Rect;		{ Rectangle requested, set to empty rect when done }
		loPlane:		INTEGER;	{ First plane requested }
		hiPlane:		INTEGER;	{ Last plane requested }

		data:			Ptr;		{ A pointer to the requested image data }
		rowBytes:		LONGINT;	{ Spacing between rows }

		filename:		Str255; 	{ Document file name }
		vRefNum:		INTEGER;	{ Volume reference number, or zero if none }
		dirty:			BOOLEAN;	{ Changes since last saved flag. The plug-in may clear
									  this field to prevent prompting the user when
									  closing the document. }

		selectBBox: 	Rect;		{ Bounding box of current selection, or an empty
									  rect if there is no current selection. }

		END;

	ExportRecordPtr = ^ExportRecord;

END.

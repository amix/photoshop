{Photoshop version 1.0.1, file: AcquireInterface.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{
	File: AcquireInterface.p

	Copyright 1990 by Thomas Knoll.

	This file describes version 3 of Photoshop's Acquisition module interface.
}

UNIT AcquireInterface;

INTERFACE

USES
	MemTypes, QuickDraw, OSIntf;

CONST

	{ Operation selectors }

	acquireSelectorAbout	= 0;
	acquireSelectorStart	= 1;
	acquireSelectorContinue = 2;
	acquireSelectorFinish	= 3;
	acquireSelectorPrepare	= 4;

	{ Image modes }

	acquireModeBitmap		= 0;
	acquireModeGrayScale	= 1;
	acquireModeIndexedColor = 2;
	acquireModeRGBColor 	= 3;
	acquireModeCMYKColor	= 4;
	acquireModeHSLColor 	= 5;
	acquireModeHSBColor 	= 6;
	acquireModeMultichannel = 7;

	{ Error return values. The plug-in module may also return standard Macintosh
	  operating system error codes, or report its own errors, in which case it
	  can return any positive integer. }

	acquireBadParameters  = -30000; 	{ "a problem with the acquisition module interface" }
	acquireNoScanner	  = -30001; 	{ "there is no scanner installed" }
	acquireScannerProblem = -30002; 	{ "a problem with the scanner" }

TYPE

	AcquireLUT = PACKED ARRAY [0..255] OF CHAR;

	AcquireRecord = RECORD

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
									  passed back at once, plus the size of any
									  interal buffers.	The plug-in may reduce this
									  value in the acquireSelectorPrepare routine. }

		imageMode:		INTEGER;	{ Image mode }
		imageSize:		Point;		{ Size of image }
		depth:			INTEGER;	{ Bits per sample, currently must be 1 or 8 }
		planes: 		INTEGER;	{ Samples per pixel }
		imageHRes:		Fixed;		{ Pixels per inch }
		imageVRes:		Fixed;		{ Pixels per inch }
		redLUT: 		AcquireLUT; { Red LUT, only used for Indexed Color images }
		greenLUT:		AcquireLUT; { Green LUT, only used for Indexed Color images }
		blueLUT:		AcquireLUT; { Blue LUT, only used for Indexed Color images }

		data:			Ptr;		{ A pointer to the returned image data. The
									  plug-in module is now responsible for freeing
									  this buffer (this is a change from previous
									  versions). Should be set to NIL when
									  all the image data has been returned. }
		theRect:		Rect;		{ Rectangle being returned }
		loPlane:		INTEGER;	{ First plane being returned }
		hiPlane:		INTEGER;	{ Last plane being returned }
		colBytes:		INTEGER;	{ Spacing between columns }
		rowBytes:		LONGINT;	{ Spacing between rows }
		planeBytes: 	LONGINT;	{ Spacing between planes (ignored if only one
									  plane is returned at a time) }

		filename:		Str255; 	{ Document file name }
		vRefNum:		INTEGER;	{ Volume reference number, or zero if none }
		dirty:			BOOLEAN;	{ Changes since last saved flag. The plug-in may clear
									  this field to prevent prompting the user when
									  closing the document. }

		END;

	AcquireRecordPtr = ^AcquireRecord;

END.

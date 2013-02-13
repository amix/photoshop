{Photoshop version 1.0.1, file: FilterInterface.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{
	File: FilterInterface.p

	Copyright 1990 by Thomas Knoll.

	This file describes version 3 of Photoshop's Filter module interface.
}

UNIT FilterInterface;

INTERFACE

USES
	MemTypes, QuickDraw, OSIntf;

CONST

	{ Operation selectors }

	filterSelectorAbout 	 = 0;
	filterSelectorParameters = 1;
	filterSelectorPrepare	 = 2;
	filterSelectorStart 	 = 3;
	filterSelectorContinue	 = 4;
	filterSelectorFinish	 = 5;

	{ Error return values. The plug-in module may also return standard Macintosh
	  operating system error codes, or report its own errors, in which case it
	  can return any positive integer. }

	filterBadParameters  = -30100;		{ "a problem with the filter module interface" }

TYPE

	FilterRecord = RECORD

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

		parameters: 	Handle; 	{ A handle, initialized to NIL by Photoshop.
									  This should be used to hold the filter's
									  current parameters. }

		imageSize:		Point;		{ Size of image }
		planes: 		INTEGER;	{ Samples per pixel (1 = Monochrome, 3 = RGB) }
		filterRect: 	Rect;		{ Rectangle to filter }

		background: 	RGBColor;	{ Current background color }
		foreground: 	RGBColor;	{ Current foreground color }

		maxSpace:		LONGINT;	{ Maximum possible total of data and buffer space }

		bufferSpace:	LONGINT;	{ If the plug-in filter needs to allocate
									  large internal buffers, the filterSelectorPrepare
									  routine should set this field to the number
									  of bytes the filterSelectorStart routine is
									  planning to allocate.  Relocatable blocks should
									  be used if possible. }

		inRect: 		Rect;		{ Requested input rectangle. Must be a subset of
									  the image's bounding rectangle. }
		inLoPlane:		INTEGER;	{ First requested input plane }
		inHiPlane:		INTEGER;	{ Last requested input plane }
		outRect:		Rect;		{ Requested output rectangle. Must be a subset of
									  filterRect. }
		outLoPlane: 	INTEGER;	{ First requested output plane }
		outHiPlane: 	INTEGER;	{ Last requested output plane }

		inData: 		Ptr;		{ Pointer to input rectangle. If more than one
									  plane was requested, the data is interleaved. }
		inRowBytes: 	LONGINT;	{ Offset between input rows }
		outData:		Ptr;		{ Pointer to output rectangle. If more than one
									  plane was requested, the data is interleaved. }
		outRowBytes:	LONGINT;	{ Offset between output rows }

		isFloating: 	BOOLEAN;	{ Set to true if the selection is floating }
		haveMask:		BOOLEAN;	{ Set to true if there is a selection mask }
		autoMask:		BOOLEAN;	{ If there is a mask, and the selection is not
									  floating, the plug-in can change this field to
									  false to turn off auto-masking. }

		maskRect:		Rect;		{ Requested mask rectangle.  Must be a subset of
									  filterRect. Should only be used if haveMask is
									  true. }

		maskData:		Ptr;		{ Pointer to (read only) mask data. }
		maskRowBytes:	LONGINT;	{ Offset between mask rows }

		END;

	FilterRecordPtr = ^FilterRecord;

END.

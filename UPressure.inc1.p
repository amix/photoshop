{Photoshop version 1.0.1, file: UPressure.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

CONST
	kProximity = $80;

TYPE
	TWacomRecord = PACKED RECORD
		version:		Byte;
		semaphore:		Byte;
		cursors:		Byte;
		updateFlags:	Byte;
		angleRes:		INTEGER;
		spaceRes:		INTEGER;
		xDimension: 	LONGINT;
		yDimension: 	LONGINT;
		zDimension: 	LONGINT;
		xDisplace:		LONGINT;
		yDisplace:		LONGINT;
		zDisplace:		LONGINT;
		resvPtr:		Ptr;
		tabletID:		ResType;
		DOFFlag:		Byte;
		orientFlag: 	Byte;
		pressLevels:	INTEGER;
		xScale: 		INTEGER;
		xTrans: 		INTEGER;
		yScale: 		INTEGER;
		yTrans: 		INTEGER;
		flags:			Byte;
		pressThresh:	Byte;
		buttonMask: 	INTEGER;
		errorFlag:		INTEGER;
		buttons:		INTEGER;
		tangPress:		INTEGER;
		pressure:		INTEGER;
		timeStamp:		LONGINT;
		xCoord: 		LONGINT;
		yCoord: 		LONGINT;
		zCoord: 		LONGINT;
		xTilt:			INTEGER;
		yTilt:			INTEGER;
		tabXMin:		INTEGER;
		tabYMin:		INTEGER;
		tabXMax:		INTEGER;
		tabYMax:		INTEGER;
		screenXMin: 	INTEGER;
		screenYMin: 	INTEGER;
		screenXMax: 	INTEGER;
		screenYMax: 	INTEGER;
		buttonMapping:	Ptr;
		modelInUse: 	INTEGER
		END;

	PWacomRecord = ^TWacomRecord;

VAR
	gWacomRecord: PWacomRecord;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitPressure;

	CONST
		kGetRecord = 20;

	VAR
		refNum: INTEGER;
		stuff: RECORD
			wr: PWacomRecord;
			pad: ARRAY [0..9] OF INTEGER;
			END;

	BEGIN

	gHavePressure := FALSE;

	{$IFC NOT qBarneyscan}

	IF OpenDriver ('.Wacom', refNum) <> noErr THEN
		EXIT (InitPressure);

	IF Status (refNum, kGetRecord, @stuff) <> noErr THEN
		EXIT (InitPressure);

	gWacomRecord := stuff.wr;

	IF gWacomRecord^.tabletID <> 'TBLT' THEN
		EXIT (InitPressure);

	IF gWacomRecord^.semaphore = 0 THEN
		EXIT (InitPressure);

	gHavePressure := gWacomRecord^.pressLevels > 1;

	{$IFC qDebug}
	IF gHavePressure THEN
		writeln ('Has Pressure')
	{$ENDC}

	{$ENDC}

	END;

{*****************************************************************************}

{$S ARes4}

FUNCTION UsingPressure: BOOLEAN;

	BEGIN

	UsingPressure := gHavePressure &
					 (BAND (gWacomRecord^.flags, kProximity) <> 0) &
					 (gWacomRecord^.pressLevels > 1) &
					 (gWacomRecord^.pressThresh < gWacomRecord^.pressLevels) &
					 (gWacomRecord^.pressThresh >= 0)

	END;

{*****************************************************************************}

{$S ARes4}

{$IFC qTrace} {$D+} {$ENDC}

FUNCTION ReadPressure: INTEGER;

	VAR
		levels: INTEGER;
		pressure: LONGINT;
		threshold: INTEGER;

	BEGIN

	levels	  := gWacomRecord^.pressLevels;
	threshold := gWacomRecord^.pressThresh;
	pressure  := gWacomRecord^.pressure;

	IF BAND (gWacomRecord^.flags, kProximity) = 0 THEN
		pressure := 0

	ELSE IF pressure < threshold THEN
		pressure := 0

	ELSE IF pressure >= levels THEN
		pressure := 255

	ELSE
		pressure := (pressure + 1 - threshold) * 255 DIV (levels - threshold);

	IF pressure > 0 THEN
		ReadPressure := Max (1, SQR (pressure) DIV 255)
	ELSE
		ReadPressure := 0

	END;

{$IFC qTrace} {$D++} {$ENDC}

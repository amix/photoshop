{Photoshop version 1.0.1, file: UTransfer.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

CONST
	kTransferVersion  = 3;
	kTransferFileType = '8BTF';

TYPE
	TSplineArray = ARRAY [0..4] OF EXTENDED;

{*****************************************************************************}

{$S APostScript}

PROCEDURE FindSpline (count: INTEGER;
					  X: TSplineArray;
					  Y: TSplineArray;
					  VAR S: TSplineArray);

	VAR
		j: INTEGER;
		A: EXTENDED;
		B: EXTENDED;
		C: EXTENDED;
		D: EXTENDED;
		E: TSplineArray;
		F: TSplineArray;
		G: TSplineArray;

	BEGIN

	A := X [1] - X [0];
	B := (Y [1] - Y [0]) / A;

	S [0] := B;

	FOR j := 2 TO count DO
		BEGIN
		C := X [j] - X [j-1];
		D := (Y [j] - Y [j-1]) / C;
		S [j-1] := (B * C + D * A) / (A + C);
		A := C;
		B := D
		end;

	S [count] := 2.0 * B - S [count-1];
	S [0]	  := 2.0 * S [0] - S [1];

	IF count > 1 THEN
		BEGIN

		F [0]	  := 0.5;
		E [count] := 0.5;
		G [0]	  := 0.75 * (S [0] + S [1]);
		G [count] := 0.75 * (S [count-1] + S [count]);

		FOR j := 1 TO count-1 DO
			BEGIN
			A := (X [j+1] - X [j-1]) * 2.0;
			E [j] := (X [j+1] - X [j]) / A;
			F [j] := (X [j] - X [j-1]) / A;
			G [j] := 1.5 * S [j]
			END;

		FOR j := 1 TO count DO
			BEGIN
			A := 1.0 - F [j-1] * E [j];
			IF j <> count THEN F [j] := F [j] / A;
			G [j] := (G [j] - G [j-1] * E [j]) / A
			END;

		FOR j := count-1 DOWNTO 0 DO
			G [j] := G [j] - F [j] * G [j+1];

		FOR j := 0 TO count DO
			S [j] := G [j]

		END

	END;

{*****************************************************************************}

{$S APostScript}

FUNCTION Evaluate (value: EXTENDED;
				   count: INTEGER;
				   X: TSplineArray;
				   Y: TSplineArray;
				   S: TSplineArray): EXTENDED;

	VAR
		j: INTEGER;
		A: EXTENDED;
		B: EXTENDED;
		C: EXTENDED;
		D: EXTENDED;
		lower: EXTENDED;
		upper: EXTENDED;

	BEGIN

	j := 1;

	WHILE (j < count) & (value > X [j]) DO
		j := j + 1;

	A :=  X [j] - X [j-1];
	B := (value - X [j-1]) / A;
	C := (X [j] - value  ) / A;

	D := (Y [j-1] * (2.0 - C + B) + S [j-1] * A * B) * C * C +
		 (Y [j	] * (2.0 - B + C) - S [j  ] * A * C) * B * B;

	IF Y [j] >= Y [j-1] THEN
		BEGIN
		lower := Y [j-1];
		upper := Y [j]
		END
	ELSE
		BEGIN
		lower := Y [j];
		upper := Y [j-1]
		END;

	IF D < lower THEN D := lower;
	IF D > upper THEN D := upper;

	Evaluate := D

	END;

{*****************************************************************************}

{$S APostScript}

PROCEDURE SolveTransfer (spec: TTransferSpec;
						 VAR transfer: TTransferArray);

	VAR
		j: INTEGER;
		count: INTEGER;
		X: TSplineArray;
		Y: TSplineArray;
		S: TSplineArray;

	BEGIN

	count := -1;

	FOR j := 0 TO 4 DO
		IF spec [j] <> -1 THEN
			BEGIN
			count := count + 1;
			X [count] := j / 4;
			Y [count] := spec [j] / 100
			END;

	FindSpline (count, X, Y, S);

	FOR j := 0 TO 20 DO
		transfer [j] := ROUND (Evaluate (j/20, count, X, Y, S) * 1000);

	END;

{*****************************************************************************}

{$S APageSetup}

FUNCTION LoadTransferSpecs (VAR specs: TTransferSpecs;
							plural: BOOLEAN): BOOLEAN;

	CONST
		kOldVersion = 2;

	VAR
		fi: FailInfo;
		where: Point;
		reply: SFReply;
		count: LONGINT;
		refNum: INTEGER;
		version: INTEGER;
		typeList: SFTypeList;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		VAR
			ignore: OSErr;

		BEGIN
		IF refNum <> -1 THEN
			ignore := FSClose (refNum);
		IF error <> noErr THEN
			BEGIN
			IF plural THEN
				message := msgCannotLoadTransfers
			ELSE
				message := msgCannotLoadTransfer;
			gApplication.ShowError (error, message)
			END;
		EXIT (LoadTransferSpecs)
		END;

	BEGIN

	LoadTransferSpecs := FALSE;

	refNum := -1;

	CatchFailures (fi, CleanUp);

	WhereToPlaceDialog (getDlgID, where);

	typeList [0] := kTransferFileType;

	SFGetFile (where, '', NIL, 1, typeList, NIL, reply);
	IF NOT reply.good THEN Failure (0, 0);

	FailOSErr (FSOpen (reply.fName, reply.vRefNum, refNum));

	count := SIZEOF (INTEGER);
	FailOSErr (FSRead (refNum, count, @version));

	IF (version < kOldVersion) OR (version > kTransferVersion) THEN
		Failure (errBadFileVersion, 0);

	count := SIZEOF (TTransferSpecs);
	FailOSErr (FSRead (refNum, count, @specs));

	FailOSErr (FSClose (refNum));

	Success (fi);

	LoadTransferSpecs := TRUE

	END;

{*****************************************************************************}

{$S APageSetup}

PROCEDURE SaveTransferSpecs (specs: TTransferSpecs; plural: BOOLEAN);

	VAR
		fi: FailInfo;
		reply: SFReply;
		count: LONGINT;
		prompt: Str255;
		refNum: INTEGER;
		version: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		VAR
			ignore: OSErr;

		BEGIN
		IF refNum <> -1 THEN
			ignore := FSClose (refNum);
		IF error <> noErr THEN
			BEGIN
			IF plural THEN
				message := msgCannotSaveTransfers
			ELSE
				message := msgCannotSaveTransfer;
			gApplication.ShowError (error, message)
			END;
		EXIT (SaveTransferSpecs)
		END;

	BEGIN

	refNum := -1;

	CatchFailures (fi, CleanUp);

	IF plural THEN
		GetIndString (prompt, kStringsID, strSaveTransfersIn)
	ELSE
		GetIndString (prompt, kStringsID, strSaveTransferIn);

	refNum := CreateOutputFile (prompt, kTransferFileType, reply);

	version := kTransferVersion;
	count	:= SIZEOF (INTEGER);

	FailOSErr (FSWrite (refNum, count, @version));

	count := SIZEOF (TTransferSpecs);
	FailOSErr (FSWrite (refNum, count, @specs));

	FailOSErr (FSClose (refNum));
	refNum := -1;

	FailOSErr (FlushVol (NIL, reply.vRefNum));

	Success (fi)

	END;

{*****************************************************************************}

{$S APageSetup}

PROCEDURE SetTransferFunction (VAR spec: TTransferSpec;
							   VAR gamma: INTEGER);

	CONST
		kDialogID	  = 1260;
		kLoadItem	  = 4;
		kSaveItem	  = 6;
		kPercentItems = 8;
		kGammaItem	  = 13;

	VAR
		j: INTEGER;
		fi: FailInfo;
		hitItem: INTEGER;
		succeeded: BOOLEAN;
		specs: TTransferSpecs;
		gammaText: TFixedText;
		anLSDialog: TLSDialog;
		percentText: ARRAY [0..4] OF TFixedText;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		anLSDialog.Free
		END;

	PROCEDURE StuffValues;

		VAR
			j: INTEGER;

		BEGIN

		FOR j := 0 TO 4 DO
			IF spec [j] = -1 THEN
				percentText [j] . StuffString ('')
			ELSE
				percentText [j] . StuffValue (spec [j]);

		IF gamma <> 0 THEN
			gammaText.StuffValue (gamma);

		anLSDialog.SetEditSelection (kPercentItems)

		END;

	PROCEDURE GetValues;

		VAR
			j: INTEGER;

		BEGIN

		FOR j := 0 TO 4 DO
			IF percentText [j] . fBlank THEN
				spec [j] := -1
			ELSE
				spec [j] := percentText [j] . fValue;

		gamma := gammaText.fValue

		END;

	BEGIN

	NEW (anLSDialog);
	FailNil (anLSDialog);

	anLSDialog.ILSDialog (kDialogID, kLoadItem, kSaveItem);

	CatchFailures (fi, CleanUp);

	FOR j := 0 TO 4 DO
		percentText [j] := anLSDialog.DefineFixedText
						   (kPercentItems + j, 0,
							(j <> 0) AND (j <> 4), TRUE, 0, 100);

	gammaText := anLSDialog.DefineFixedText
				 (kGammaItem, 2, FALSE, FALSE, 100, 220);

	StuffValues;

		REPEAT

		anLSDialog.TalkToUser (hitItem, StdItemHandling);

			CASE hitItem OF

			cancel:
				Failure (0, 0);
				
			kLoadItem:
				BEGIN

				anLSDialog.UpdateButtons;

				IF anLSDialog.fOptionDown THEN
					BEGIN
					spec  := gPreferences.fTransfer;
					gamma := gPreferences.fSeparation.fGamma
					END

				ELSE IF LoadTransferSpecs (specs, FALSE) THEN
					BEGIN
					spec  := specs [3];
					gamma := 0
					END

				ELSE
					CYCLE;

				StuffValues

				END;

			kSaveItem:
				BEGIN

				anLSDialog.UpdateButtons;

				anLSDialog.Validate (succeeded);

				IF succeeded THEN
					BEGIN

					GetValues;

					specs [0] := spec;
					specs [1] := spec;
					specs [2] := spec;
					specs [3] := spec;

					IF anLSDialog.fOptionDown THEN
						gPreferences.fTransfer := spec
					ELSE
						SaveTransferSpecs (specs, FALSE)

					END

				END

			END

		UNTIL hitItem = ok;

	GetValues;

	Success (fi);

	anLSDialog.Free

	END;

{*****************************************************************************}

{$S APageSetup}

PROCEDURE SetTransferFunctions (VAR specs: TTransferSpecs;
								VAR gamma: INTEGER);

	CONST
		kDialogID	  = 1261;
		kLoadItem	  = 4;
		kSaveItem	  = 6;
		kPercentItems = 8;
		kGammaItem	  = 28;

	VAR
		j: INTEGER;
		k: INTEGER;
		fi: FailInfo;
		hitItem: INTEGER;
		succeeded: BOOLEAN;
		gammaText: TFixedText;
		anLSDialog: TLSDialog;
		percentText: ARRAY [0..4, 0..3] OF TFixedText;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		anLSDialog.Free
		END;

	PROCEDURE StuffValues;

		VAR
			j: INTEGER;
			k: INTEGER;

		BEGIN

		FOR j := 0 TO 4 DO
			FOR k := 0 TO 3 DO
				IF specs [k, j] = -1 THEN
					percentText [j, k] . StuffString ('')
				ELSE
					percentText [j, k] . StuffValue (specs [k, j]);

		IF gamma <> 0 THEN
			gammaText.StuffValue (gamma);

		anLSDialog.SetEditSelection (kPercentItems);

		END;

	PROCEDURE GetValues;

		VAR
			j: INTEGER;
			k: INTEGER;

		BEGIN

		FOR j := 0 TO 4 DO
			FOR k := 0 TO 3 DO
				IF percentText [j, k] . fBlank THEN
					specs [k, j] := -1
				ELSE
					specs [k, j] := percentText [j, k] . fValue;
					
		gamma := gammaText.fValue

		END;

	BEGIN

	NEW (anLSDialog);
	FailNil (anLSDialog);

	anLSDialog.ILSDialog (kDialogID, kLoadItem, kSaveItem);

	CatchFailures (fi, CleanUp);

	FOR j := 0 TO 4 DO
		FOR k := 0 TO 3 DO
			percentText [j, k] := anLSDialog.DefineFixedText
								  (kPercentItems + 4 * j + k,
								   0, (j <> 0) AND (j <> 4), TRUE, 0, 100);

	gammaText := anLSDialog.DefineFixedText
				 (kGammaItem, 2, FALSE, FALSE, 100, 220);

	StuffValues;

		REPEAT

		anLSDialog.TalkToUser (hitItem, StdItemHandling);

			CASE hitItem OF

			cancel:
				Failure (0, 0);

			kLoadItem:
				BEGIN

				anLSDialog.UpdateButtons;

				IF anLSDialog.fOptionDown THEN
					BEGIN
					specs := gPreferences.fTransfers;
					gamma := gPreferences.fSeparation.fGamma
					END
					
				ELSE IF LoadTransferSpecs (specs, TRUE) THEN
					gamma := 0
					
				ELSE
					CYCLE;
					
				StuffValues

				END;

			kSaveItem:
				BEGIN

				anLSDialog.UpdateButtons;

				anLSDialog.Validate (succeeded);

				IF succeeded THEN
					BEGIN

					GetValues;

					IF anLSDialog.fOptionDown THEN
						gPreferences.fTransfers := specs
					ELSE
						SaveTransferSpecs (specs, TRUE)

					END

				END

			END

		UNTIL hitItem = ok;

	GetValues;

	Success (fi);

	anLSDialog.Free

	END;

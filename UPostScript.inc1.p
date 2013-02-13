{Photoshop version 1.0.1, file: UPostScript.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}
{$I UFloat.a.inc}
{$I UPostScript.a.inc}
{$I USeparation.a.inc}

CONST
	kPSBuffer = 16384;

VAR
	gPSFile: BOOLEAN;
	gPSRefNum: INTEGER;

	gPSCount: LONGINT;
	gPSBuffer: Handle;

{*****************************************************************************}

{$S APostScript}

PROCEDURE BeginPostScript (toFile: BOOLEAN; refNum: INTEGER);

	BEGIN

	gPSFile   := toFile;
	gPSRefNum := refNum;

	gPSCount  := 0;
	gPSBuffer := NewLargeHandle (kPSBuffer)

	END;

{*****************************************************************************}

{$S APostScript}

PROCEDURE FlushPostScript;

	CONST
		kPostScriptHandle = 192;

	BEGIN

	IF gPSCount > 0 THEN
		BEGIN

		IF gPSFile THEN
			FailOSErr (FSWrite (gPSRefNum, gPSCount, gPSBuffer^))
		ELSE
			PicComment (kPostScriptHandle, gPSCount, gPSBuffer);

		gPSCount := 0

		END

	END;

{*****************************************************************************}

{$S APostScript}

PROCEDURE EndPostScript;

	BEGIN
	FreeLargeHandle (gPSBuffer)
	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S APostScript}

PROCEDURE PutData (p: Ptr; n: LONGINT);

	VAR
		count: LONGINT;

	BEGIN

		REPEAT

		IF gPSCount + n <= kPSBuffer THEN
			count := n
		ELSE
			count := kPSBuffer - gPSCount;

		BlockMove (p, Ptr (ORD4 (gPSBuffer^) + gPSCount), count);

		p := Ptr (ORD4 (p) + count);
		n := n - count;

		gPSCount := gPSCount + count;

		IF gPSCount = kPSBuffer THEN FlushPostScript

		UNTIL n = 0

	END;

{*****************************************************************************}

{$S APostScript}

PROCEDURE PutString (s: Str255);

	BEGIN
	PutData (@s[1], LENGTH (s))
	END;

{*****************************************************************************}

{$S APostScript}

PROCEDURE PutNumber (n: LONGINT);

	VAR
		s: Str255;

	BEGIN
	NumToString (n, s);
	PutString (s)
	END;

{*****************************************************************************}

{$S APostScript}

PROCEDURE PutSpace;

	BEGIN
	PutString (' ')
	END;

{*****************************************************************************}

{$S APostScript}

PROCEDURE PutNewLine;

	VAR
		buffer: PACKED ARRAY [1..1] OF CHAR;

	BEGIN

	buffer [1] := CHR (13);

	PutData (@buffer, 1)

	END;

{*****************************************************************************}

{$S APostScript}

PROCEDURE PutLine (s: Str255);

	BEGIN
	PutString (s);
	PutNewLine
	END;

{*****************************************************************************}

{$S APostScript}

PROCEDURE PutHexData (p: Ptr; n: LONGINT);

	VAR
		count: INTEGER;
		buffer: PACKED ARRAY [1..65] OF CHAR;

	BEGIN

		REPEAT

		IF n > 32 THEN
			count := 32
		ELSE
			count := n;

		ConvertToHex (p, @buffer, count);

		PutData (@buffer, BSL (count, 1) + 1);

		p := Ptr (ORD4 (p) + count);
		n := n - count

		UNTIL n = 0

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S AEPSFormat}

PROCEDURE GenerateEPSFHeader (doc: TImageDocument;
							  channel: INTEGER;
							  inputArea: Rect;
							  outputArea: Rect;
							  useDCS: BOOLEAN;
							  color: BOOLEAN;
							  screen: BOOLEAN;
							  transfer: BOOLEAN;
							  binary: BOOLEAN);

	VAR
		h: Handle;
		s: Str255;
		band: INTEGER;
		dateTime: LONGINT;
		hSpec: THalftoneSpec;
		tSpec: TTransferSpec;

	PROCEDURE PutHSpec;
		BEGIN
		WITH hSpec DO
			BEGIN
			PutNumber (frequency.value);
			PutSpace;
			PutNumber (frequency.scale);
			PutSpace;
			PutNumber (angle);
			PutSpace;
			PutNumber (shape);
			PutNewLine
			END
		END;

	PROCEDURE PutTSpec;
		BEGIN
		PutNumber (tSpec [0]);
		PutSpace;
		PutNumber (tSpec [1]);
		PutSpace;
		PutNumber (tSpec [2]);
		PutSpace;
		PutNumber (tSpec [3]);
		PutSpace;
		PutNumber (tSpec [4]);
		PutNewLine
		END;

	BEGIN

	PutLine ('%!PS-Adobe-2.0 EPSF-1.2');

	h := GetResource (kSignature, 0);
	IF h <> NIL THEN
		BEGIN
		s := StringHandle (h)^^;
		PutString ('%%Creator: ');
		PutLine (s);
		ReleaseResource (h)
		END;

	PutString ('%%Title: ');
	PutLine (gReply.fName);

	PutString ('%%CreationDate: ');
	GetDateTime (dateTime);
	IUDateString (dateTime, shortDate, s);
	PutString (s);
	PutSpace;
	IUTimeString (dateTime, FALSE, s);
	PutLine (s);

	PutString ('%%BoundingBox: ');
	PutNumber (outputArea.left);
	PutSpace;
	PutNumber (outputArea.top);
	PutSpace;
	PutNumber (outputArea.right);
	PutSpace;
	PutNumber (outputArea.bottom);
	PutNewLine;
	
	IF transfer THEN
		PutLine ('%%SuppressDotGainCompensation');

	IF channel = kCMYKChannels THEN
		PutLine ('%%DocumentProcessColors: Cyan Magenta Yellow Black');

	IF doc.fMode IN [HalftoneMode, MonochromeMode, MultichannelMode] THEN
		PutLine ('%%DocumentProcessColors: Black');

	IF useDCS THEN
		BEGIN

		s := gReply.fName;
		IF LENGTH (s) > 29 THEN
			s [0] := CHR (29);

		PutString ('%%CyanPlate: ');
		PutString (s);
		PutLine ('.C');

		PutString ('%%MagentaPlate: ');
		PutString (s);
		PutLine ('.M');

		PutString ('%%YellowPlate: ');
		PutString (s);
		PutLine ('.Y');

		PutString ('%%BlackPlate: ');
		PutString (s);
		PutLine ('.K')

		END;

	PutLine ('%%EndComments');

	PutString ('%ImageData: ');
	PutNumber (inputArea.right - inputArea.left);
	PutSpace;
	PutNumber (inputArea.bottom - inputArea.top);
	PutSpace;
	PutNumber (doc.fDepth);
	IF color THEN
		IF channel = kCMYKChannels THEN
			PutString (' 4 1 ')
		ELSE
			PutString (' 3 1 ')
	ELSE
		PutString (' 1 0 ');
	IF doc.fDepth = 1 THEN
		PutNumber ((inputArea.right - inputArea.left + 7) DIV 8)
	ELSE
		PutNumber (inputArea.right - inputArea.left);
	IF binary THEN
		PutString (' 1')
	ELSE
		PutString (' 2');
	PutLine (' "beginimage"');

	PutString ('%ImageStyle: 1 ');
	PutNumber (doc.fStyleInfo.fResolution.value);
	PutSpace;
	PutNumber (doc.fStyleInfo.fResolution.scale);
	PutSpace;
	PutNumber (doc.fStyleInfo.fWidthUnit);
	PutSpace;
	PutNumber (doc.fStyleInfo.fHeightUnit);
	PutNewLine;

	IF screen THEN

		IF doc.fMode IN [IndexedColorMode, RGBColorMode, SeparationsCMYK] THEN
			BEGIN

			FOR band := 0 TO 3 DO
				BEGIN
				hSpec := doc.fStyleInfo.fHalftoneSpecs [band];
				IF hSpec.shape >= 0 THEN
					BEGIN
					PutString ('%ImageStyle: ');
					PutNumber (101 + band);
					PutSpace;
					PutHSpec
					END
				END;

			IF (doc.fMode = SeparationsCMYK) AND (channel >= 0) AND
												 (channel <= 3) THEN
				BEGIN
				hSpec := doc.fStyleInfo.fHalftoneSpecs [channel];
				IF hSpec.shape >= 0 THEN
					BEGIN
					PutString ('%ImageStyle: 100 ');
					PutHSpec
					END
				END

			END

		ELSE
			BEGIN
			hSpec := doc.fStyleInfo.fHalftoneSpec;
			IF hSpec.shape >= 0 THEN
				BEGIN
				PutString ('%ImageStyle: 100 ');
				PutHSpec
				END
			END;

	IF transfer THEN
		BEGIN

		IF doc.fMode IN [IndexedColorMode, RGBColorMode, SeparationsCMYK] THEN
			BEGIN

			FOR band := 0 TO 3 DO
				BEGIN
				PutString ('%ImageStyle: ');
				PutNumber (201 + band);
				PutSpace;
				tSpec := doc.fStyleInfo.fTransferSpecs [band];
				PutTSpec
				END;

			IF (doc.fMode = SeparationsCMYK) AND (channel >= 0) AND
												 (channel <= 3) THEN
				BEGIN
				PutString ('%ImageStyle: 200 ');
				tSpec := doc.fStyleInfo.fTransferSpecs [channel];
				PutTSpec
				END

			END

		ELSE
			BEGIN
			PutString ('%ImageStyle: 200 ');
			tSpec := doc.fStyleInfo.fTransferSpec;
			PutTSpec
			END;

		PutString ('%ImageStyle: 210 ');
		PutNumber (doc.fStyleInfo.fGamma);
		PutNewLine

		END

	END;

{*****************************************************************************}

{$S APostScript}

PROCEDURE PutHalftoneSpec (spec: THalftoneSpec);

	BEGIN

	PutNumber (spec.frequency.value);
	PutString (' 65536 div ');
	PutNumber (spec.angle);
	PutLine (' 65536 div');

	IF spec.spot <> NIL THEN
		BEGIN
		HLock (spec.spot);
		PutData (spec.spot^, GetHandleSize (spec.spot));
		HUnlock (spec.spot);
		PutNewLine
		END

	ELSE
		BEGIN

		PutString ('{');

			CASE spec.shape OF

			1:	BEGIN
				PutLine ('abs exch abs 2 copy 3 mul exch 4 mul add 3 sub');
				PutLine ('dup 0 lt {pop dup mul exch .75 div dup mul add 4');
				PutLine ('div 1 exch sub} {dup 1 gt {pop 1 exch sub dup mul');
				PutLine ('exch 1 exch sub .75 div dup mul add 4 div 1 sub}');
				PutLine ('{.5 exch sub exch pop exch pop} ifelse} ifelse')
				END;

			2:	PutLine ('exch pop abs neg');

			3:	PutLine ('abs exch abs 2 copy lt {exch} if pop neg');

			4:	PutLine ('abs exch abs 2 copy gt {exch} if pop neg');

			OTHERWISE
				BEGIN
				PutLine ('abs exch abs 2 copy add 1 le');
				PutLine ('{dup mul exch dup mul add 1 exch sub}');
				PutLine ('{1 sub dup mul exch 1 sub dup mul add 1 sub}');
				PutLine ('ifelse')
				END

			END;

		PutLine ('negative {neg} if}')

		END

	END;

{*****************************************************************************}

{$S APostScript}

PROCEDURE PutScreen (doc: TImageDocument; channel: INTEGER; color: BOOLEAN);

	VAR
		scale: Fixed;
		band: INTEGER;
		code: INTEGER;
		code1: INTEGER;
		code2: INTEGER;
		cellData: Handle;
		cellSize: INTEGER;
		spec: THalftoneSpec;
		buffer: PACKED ARRAY [0..783] OF CHAR;

	BEGIN

	IF color THEN
		BEGIN

		FOR band := 0 TO 3 DO
			BEGIN
			spec := doc.fStyleInfo.fHalftoneSpecs [band];
			PutHalftoneSpec (spec)
			END;

		PutLine ('band 0 eq {setcolorscreen} if');

		IF channel = kCMYKChannels THEN
			BEGIN
			PutLine ('band 1 eq {9 {pop} repeat setscreen} if');
			PutLine ('band 2 eq {6 {pop} repeat setscreen pop pop pop} if');
			PutLine ('band 3 eq {pop pop pop setscreen 6 {pop} repeat} if');
			PutLine ('band 4 ge {setscreen 9 {pop} repeat} if')
			END
		ELSE
			PutLine ('band 0 ne {setscreen 9 {pop} repeat} if')

		END

	ELSE
		BEGIN

		IF doc.fMode = SeparationsCMYK THEN
			spec := doc.fStyleInfo.fHalftoneSpecs [Min (channel, 3)]

		ELSE IF doc.fMode IN [IndexedColorMode, RGBColorMode] THEN
			spec := doc.fStyleInfo.fHalftoneSpecs [3]

		ELSE
			spec := doc.fStyleInfo.fHalftoneSpec;

		PutHalftoneSpec (spec);

		PutLine ('setscreen');

		IF (spec.angle MOD (45 * $10000) = 0) AND
				(doc.fMode <> SeparationsCMYK) AND
				(spec.shape >= 0) THEN
			BEGIN

			PutLine ('5 dict begin');

			PutLine ('/devicedpi 72 0 matrix defaultmatrix dtransform');
			PutLine ('dup mul exch dup mul add sqrt def');

			PutLine ('/setcustomscreen {devicedpi customsize div 0 {');
			PutLine ('1 add 2 div customsize mul cvi exch');
			PutLine ('1 add 2 div customsize mul cvi exch');
			PutLine ('customsize mul add');
			PutLine ('customdata exch get 256 div');
			PutLine ('negative not {neg} if} setscreen} def');

			PutLine ('/screenid devicedpi currentscreen pop pop div');

			IF spec.angle MOD (90 * $10000) = 0 THEN
				BEGIN
				code1 := 3;
				code2 := 15;
				scale := $10000
				END
			ELSE
				BEGIN
				code1 := 2;
				code2 := 8;
				scale := FixRatio (141, 100);
				PutLine ('2 sqrt div')
				END;

			PutLine ('0.5 add cvi def');

			PutLine ('/customdata 28 28 mul string def');

			spec.frequency.value := $10000;

			FOR code := code1 TO code2 DO
				BEGIN

				MakeScreen (28,
							code * scale,
							spec,
							cellData,
							cellSize);

				DoSetBytes (@buffer, SQR (28), 0);
				BlockMove (cellData^, @buffer, SQR (cellSize));
				FreeLargeHandle (cellData);

				PutString ('/customsize ');
				PutNumber (cellSize);
				PutLine (' def');

				PutLine ('currentfile customdata readhexstring');
				PutHexData (@buffer, SQR (28));
				PutLine ('pop pop');

				PutNumber (code);
				PutLine (' screenid eq {setcustomscreen} if')

				END;

			PutLine ('end')

			END

		END

	END;

{*****************************************************************************}

{$S APostScript}

PROCEDURE PutTransferSpec (spec: TTransferSpec);

	VAR
		j: INTEGER;
		transfer: TTransferArray;

	BEGIN

	SolveTransfer (spec, transfer);
	
	PutLine ('{mark 1000');

	FOR j := 0 TO 20 DO
		BEGIN
		PutNumber (1000 - transfer [j]);
		IF (j = 9) OR (j = 20) THEN
			PutNewLine
		ELSE
			PutSpace
		END;

	PutLine ('24 -1 roll 20 mul dup floor cvi');
	PutLine ('dup 3 1 roll sub exch dup');
	PutLine ('3 add index exch 2 add index dup 4 1 roll');
	PutLine ('sub mul add 1000 div 24 1 roll cleartomark} bind')

	END;

{*****************************************************************************}

{$S APostScript}

PROCEDURE PutTransfer (doc: TImageDocument; channel: INTEGER; color: BOOLEAN);

	VAR
		band: INTEGER;
		spec: TTransferSpec;

	BEGIN

	PutLine ('/__settransfer {{dummy1 exec dummy2 exec}');
	PutLine ('dup 0 4 -1 roll put dup 2 _currenttransfer put');
	PutLine ('_settransfer} def');

	IF color THEN
		BEGIN

		FOR band := 0 TO 3 DO
			BEGIN
			spec := doc.fStyleInfo.fTransferSpecs [band];
			PutTransferSpec (spec)
			END;

		PutLine ('band 0 eq {');
		PutLine ('systemdict /currentcolortransfer get exec');
		PutLine ('{dummy1 exec dummy2 exec}');
		PutLine ('dup 0 11 -1 roll put dup 2 7 -1 roll put');
		PutLine ('{dummy1 exec dummy2 exec}');
		PutLine ('dup 0 10 -1 roll put dup 2 7 -1 roll put');
		PutLine ('{dummy1 exec dummy2 exec}');
		PutLine ('dup 0 9 -1 roll put dup 2 7 -1 roll put');
		PutLine ('{dummy1 exec dummy2 exec}');
		PutLine ('dup 0 8 -1 roll put dup 2 7 -1 roll put');
		PutLine ('systemdict /setcolortransfer get exec} if');

		IF channel = kCMYKChannels THEN
			BEGIN
			PutLine ('band 1 eq {pop pop pop __settransfer} if');
			PutLine ('band 2 eq {pop pop __settransfer pop} if');
			PutLine ('band 3 eq {pop __settransfer pop pop} if');
			PutLine ('band 4 ge {__settransfer pop pop pop} if')
			END
		ELSE
			PutLine ('band 0 ne {__settransfer pop pop pop} if')

		END

	ELSE
		BEGIN

		IF doc.fMode = SeparationsCMYK THEN
			spec := doc.fStyleInfo.fTransferSpecs [Min (channel, 3)]

		ELSE IF doc.fMode IN [IndexedColorMode, RGBColorMode] THEN
			spec := doc.fStyleInfo.fTransferSpecs [3]

		ELSE
			spec := doc.fStyleInfo.fTransferSpec;

		PutTransferSpec (spec);

		PutLine ('__settransfer')

		END

	END;

{*****************************************************************************}

{$S APostScript}

PROCEDURE GeneratePostScript (doc: TImageDocument;
							  channel: INTEGER;
							  inputArea: Rect;
							  outputArea: Rect;
							  color: BOOLEAN;
							  screen: BOOLEAN;
							  transfer: BOOLEAN;
							  mask: BOOLEAN;
							  binary: BOOLEAN;
							  printing: BOOLEAN);

	VAR
		r: Rect;
		p0: Ptr;
		p1: Ptr;
		p2: Ptr;
		p3: Ptr;
		p4: Ptr;
		srcPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		band: INTEGER;
		bands: INTEGER;
		width: LONGINT;
		buffer: Handle;
		map: TLookUpTable;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (buffer);
		END;

	BEGIN

	buffer := NIL;

	CatchFailures (fi, CleanUp);

	width := inputArea.right - inputArea.left;

	IF doc.fDepth = 1 THEN
		BEGIN

		width := BSR (width + 7, 3);

		gTables.CompTables (doc,
							channel,
							TRUE,
							FALSE,
							1,
							1,
							FALSE,
							FALSE,
							1);

		r		 := inputArea;
		r.bottom := r.top + 1;

		buffer := NewLargeHandle (gTables.BufferSize (r))

		END

	ELSE
		buffer := NewLargeHandle (5 * width);

	IF doc.fMode = IndexedColorMode THEN
		FOR row := 0 TO 255 DO
			map [row] := ConvertToGray
						 (ORD (doc.fIndexedColorTable.R [row]),
						  ORD (doc.fIndexedColorTable.G [row]),
						  ORD (doc.fIndexedColorTable.B [row]));

	MoveHHi (buffer);
	HLock (buffer);

	p0 := buffer^;
	p1 := Ptr (ORD4 (p0) + width);
	p2 := Ptr (ORD4 (p1) + width);
	p3 := Ptr (ORD4 (p2) + width);
	p4 := Ptr (ORD4 (p3) + width);

	PutLine ('35 dict begin');

	PutLine ('/_image systemdict /image get def');
	PutLine ('/_setgray systemdict /setgray get def');
	PutLine ('/_currentgray systemdict /currentgray get def');
	PutLine ('/_settransfer systemdict /settransfer get def');
	PutLine ('/_currenttransfer systemdict /currenttransfer get def');

	PutLine ('/negative 0 _currenttransfer exec');
	PutLine ('1 _currenttransfer exec gt def');

	PutLine ('/inverted? negative def');	{ FreeHand 2.0.2 Bug }
	
	IF color THEN
		BEGIN

		PutLine ('/hascolor systemdict /colorimage known def');
		
		PutLine ('/foureq {4 index eq 8 1 roll');
		PutLine ('4 index eq 8 1 roll');
		PutLine ('4 index eq 8 1 roll');
		PutLine ('4 index eq 8 1 roll');
		PutLine ('pop pop pop pop and and and} def');

		PutLine ('hascolor {/band 0 def} {/band 5 def} ifelse');

		PutLine ('/setcmykcolor where {pop');
		PutLine ('1 0 0 0 setcmykcolor _currentgray 1 exch sub');
		PutLine ('0 1 0 0 setcmykcolor _currentgray 1 exch sub');
		PutLine ('0 0 1 0 setcmykcolor _currentgray 1 exch sub');
		PutLine ('0 0 0 1 setcmykcolor _currentgray 1 exch sub');
		PutLine ('4 {4 copy} repeat');
		PutLine ('1 0 0 0 foureq {/band 1 store} if');
		PutLine ('0 1 0 0 foureq {/band 2 store} if');
		PutLine ('0 0 1 0 foureq {/band 3 store} if');
		PutLine ('0 0 0 1 foureq {/band 4 store} if');
		PutLine ('0 0 0 0 foureq {/band 6 store} if} if');

		PutLine ('/negativeimage {{1 exch sub dummy exec} dup 3');
		PutLine ('_currenttransfer put _settransfer _image} def');
		
		PutLine ('/whiteimage {negative {{pop 0}} {{pop 1}} ifelse');
		PutLine ('_settransfer _image} def')

		END;

	IF screen THEN PutScreen (doc, channel, color);

	IF transfer THEN PutTransfer (doc, channel, color);

	PutLine ('gsave');

	IF transfer AND (doc.fStyleInfo.fGamma <> 100) THEN
		BEGIN

		PutString ('{');
		PutNumber (doc.fStyleInfo.fGamma);
		PutLine (' 100 div exp}');
		
		IF color THEN
			BEGIN
			PutLine ('hascolor {dup dup dup');
			PutLine ('systemdict /currentcolortransfer get exec');
			PutLine ('{dummy1 exec dummy2 exec}');
			PutLine ('dup 0 11 -1 roll put dup 2 7 -1 roll put');
			PutLine ('{dummy1 exec dummy2 exec}');
			PutLine ('dup 0 10 -1 roll put dup 2 7 -1 roll put');
			PutLine ('{dummy1 exec dummy2 exec}');
			PutLine ('dup 0 9 -1 roll put dup 2 7 -1 roll put');
			PutLine ('{dummy1 exec dummy2 exec}');
			PutLine ('dup 0 8 -1 roll put dup 2 7 -1 roll put');
			PutLine ('systemdict /setcolortransfer get exec} {')
			END;
			
		PutLine ('{dummy1 exec dummy2 exec} dup 0 4 -1 roll put ');
		PutLine ('dup 2 _currenttransfer put _settransfer');
		
		IF color THEN
			PutLine ('} ifelse')
			
		END;

	IF NOT color AND (doc.fMode <> SeparationsCMYK) THEN
		PutLine ('0 setgray');

	PutString ('/rows ');
	PutNumber (inputArea.bottom - inputArea.top);
	PutLine (' def');

	PutString ('/cols ');
	PutNumber (inputArea.right - inputArea.left);
	PutLine (' def');

	IF color THEN
		IF channel = kCMYKChannels THEN
			bands := 5
		ELSE
			bands := 4
	ELSE
		bands := 1;

	FOR band := 1 TO bands DO
		BEGIN
		PutString ('/picstr');
		PutNumber (band);
		PutSpace;
		PutNumber (width);
		PutLine (' string def')
		END;

	IF binary THEN
		PutLine ('/readdata {currentfile exch readstring pop} def')
	ELSE
		PutLine ('/readdata {currentfile exch readhexstring pop} def');

	PutLine ('/beginimage');

	IF color THEN
		IF channel = kCMYKChannels THEN
			BEGIN

			PutLine ('band 0 eq');
			PutLine ('{{{picstr1 readdata}');
			PutLine ('{picstr2 readdata}');
			PutLine ('{picstr3 readdata}');
			PutLine ('{picstr4 readdata picstr5 readdata pop}');
			PutLine ('true 4 colorimage}} if');

			PutLine ('band 1 eq');
			PutLine ('{{{picstr1 readdata');
			PutLine ('picstr2 readdata pop');
			PutLine ('picstr3 readdata pop');
			PutLine ('picstr4 readdata pop');
			PutLine ('picstr5 readdata pop} negativeimage}} if');

			PutLine ('band 2 eq');
			PutLine ('{{{picstr1 readdata pop');
			PutLine ('picstr2 readdata');
			PutLine ('picstr3 readdata pop');
			PutLine ('picstr4 readdata pop');
			PutLine ('picstr5 readdata pop} negativeimage}} if');

			PutLine ('band 3 eq');
			PutLine ('{{{picstr1 readdata pop');
			PutLine ('picstr2 readdata pop');
			PutLine ('picstr3 readdata');
			PutLine ('picstr4 readdata pop');
			PutLine ('picstr5 readdata pop} negativeimage}} if');

			PutLine ('band 4 eq');
			PutLine ('{{{picstr1 readdata pop');
			PutLine ('picstr2 readdata pop');
			PutLine ('picstr3 readdata pop');
			PutLine ('picstr4 readdata');
			PutLine ('picstr5 readdata pop} negativeimage}} if');

			PutLine ('band 5 eq');
			PutLine ('{{{picstr1 readdata pop');
			PutLine ('picstr2 readdata pop');
			PutLine ('picstr3 readdata pop');
			PutLine ('picstr4 readdata pop');
			PutLine ('picstr5 readdata} image}} if');

			PutLine ('band 6 eq');
			PutLine ('{{{picstr1 readdata pop');
			PutLine ('picstr2 readdata pop');
			PutLine ('picstr3 readdata pop');
			PutLine ('picstr4 readdata pop');
			PutLine ('picstr5 readdata} whiteimage}} if')

			END

		ELSE
			BEGIN

			PutLine ('band 0 eq');
			PutLine ('{{{picstr1 readdata}');
			PutLine ('{picstr2 readdata}');
			PutLine ('{picstr3 readdata picstr4 readdata pop}');
			PutLine ('true 3 colorimage}} if');

			PutLine ('band 4 eq band 5 eq or');
			PutLine ('{{{picstr1 readdata pop');
			PutLine ('picstr2 readdata pop');
			PutLine ('picstr3 readdata pop');
			PutLine ('picstr4 readdata} image}} if');

			PutLine ('band 0 eq band 4 eq band 5 eq or or not');
			PutLine ('{{{picstr1 readdata pop');
			PutLine ('picstr2 readdata pop');
			PutLine ('picstr3 readdata pop');
			PutLine ('picstr4 readdata} whiteimage}} if')

			END

	ELSE IF mask THEN
		PutLine ('{{picstr1 readdata} imagemask}')

	ELSE
		PutLine ('{{picstr1 readdata} image}');

	PutLine ('def');

	IF (outputArea.left <> 0) OR (outputArea.top <> 0) THEN
		BEGIN
		PutNumber (outputArea.left);
		PutSpace;
		PutNumber (outputArea.top);
		PutLine (' translate')
		END;

	PutString ('72 65536 mul ');
	PutNumber (doc.fStyleInfo.fResolution.value);
	PutLine (' div dup cols mul exch rows mul scale');

	IF mask THEN
		PutString ('cols rows false')
	ELSE IF doc.fDepth = 1 THEN
		PutString ('cols rows 1')
	ELSE
		PutString ('cols rows 8');

	IF printing THEN
		PutLine (' [cols 0 0 rows 0 0]')
	ELSE
		PutLine (' [cols 0 0 rows neg 0 rows]');

	IF binary THEN
		BEGIN
		PutString ('%%BeginBinary: ');
		PutNumber (ORD4 (inputArea.bottom - inputArea.top) *
				   width * bands + 11);
		PutNewLine
		END;

	PutLine ('beginimage');

	FOR row := inputArea.top TO inputArea.bottom - 1 DO
		BEGIN

		MoveHands (printing);

		UpdateProgress (row - inputArea.top,
						inputArea.bottom - inputArea.top);

		IF doc.fDepth = 1 THEN
			BEGIN

			r		 := inputArea;
			r.top	 := row;
			r.bottom := row + 1;

			gTables.DitherRect (doc, channel, 1, r, p0, TRUE);

			DoMapBytes (p0, width, gInvertLUT)

			END

		ELSE IF doc.fMode = IndexedColorMode THEN
			BEGIN

			srcPtr := doc.fData [0] . NeedPtr (row, row, FALSE);

			BlockMove (Ptr (ORD4 (srcPtr) + inputArea.left), p0, width);

			doc.fData [0] . DoneWithPtr;
			doc.fData [0] . Flush;

			BlockMove (p0, p1, width);
			BlockMove (p0, p2, width);
			BlockMove (p0, p3, width);

			DoMapBytes (p0, width, doc.fIndexedColorTable.R);
			DoMapBytes (p1, width, doc.fIndexedColorTable.G);
			DoMapBytes (p2, width, doc.fIndexedColorTable.B);
			DoMapBytes (p3, width, map);

			IF NOT color THEN BlockMove (p3, p0, width)

			END

		ELSE IF channel = kRGBChannels THEN
			BEGIN

			srcPtr := doc.fData [0] . NeedPtr (row, row, FALSE);

			BlockMove (Ptr (ORD4 (srcPtr) + inputArea.left), p0, width);

			doc.fData [0] . DoneWithPtr;
			doc.fData [0] . Flush;

			srcPtr := doc.fData [1] . NeedPtr (row, row, FALSE);

			BlockMove (Ptr (ORD4 (srcPtr) + inputArea.left), p1, width);

			doc.fData [1] . DoneWithPtr;
			doc.fData [1] . Flush;

			srcPtr := doc.fData [2] . NeedPtr (row, row, FALSE);

			BlockMove (Ptr (ORD4 (srcPtr) + inputArea.left), p2, width);

			doc.fData [2] . DoneWithPtr;
			doc.fData [2] . Flush;

			DoMakeMonochrome (p0, gGrayLUT.R,
							  p1, gGrayLUT.G,
							  p2, gGrayLUT.B,
							  p3, width);

			IF NOT color THEN BlockMove (p3, p0, width)

			END

		ELSE IF channel = kCMYKChannels THEN
			BEGIN

			srcPtr := doc.fData [0] . NeedPtr (row, row, FALSE);

			BlockMove (Ptr (ORD4 (srcPtr) + inputArea.left), p0, width);

			doc.fData [0] . DoneWithPtr;
			doc.fData [0] . Flush;

			srcPtr := doc.fData [1] . NeedPtr (row, row, FALSE);

			BlockMove (Ptr (ORD4 (srcPtr) + inputArea.left), p1, width);

			doc.fData [1] . DoneWithPtr;
			doc.fData [1] . Flush;

			srcPtr := doc.fData [2] . NeedPtr (row, row, FALSE);

			BlockMove (Ptr (ORD4 (srcPtr) + inputArea.left), p2, width);

			doc.fData [2] . DoneWithPtr;
			doc.fData [2] . Flush;

			srcPtr := doc.fData [3] . NeedPtr (row, row, FALSE);

			BlockMove (Ptr (ORD4 (srcPtr) + inputArea.left), p3, width);

			doc.fData [3] . DoneWithPtr;
			doc.fData [3] . Flush;

			DoCMYK2Gray (p0, p1, p2, p3, p4, gGrayLUT, width);

			IF color THEN
				DoMapBytes (p0, 4 * width, gInvertLUT)
			ELSE
				BlockMove (p4, p0, width)

			END

		ELSE
			BEGIN

			srcPtr := doc.fData [channel] . NeedPtr (row, row, FALSE);

			BlockMove (Ptr (ORD4 (srcPtr) + inputArea.left), p0, width);

			doc.fData [channel] . DoneWithPtr;
			doc.fData [channel] . Flush

			END;

		IF binary THEN
			PutData (p0, bands * width)
		ELSE
			PutHexData (p0, bands * width)

		END;

	UpdateProgress (1, 1);

	IF binary THEN
		BEGIN
		PutNewLine;
		PutLine ('%%EndBinary')
		END;

	PutLine ('grestore end');

	Success (fi)

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE NormalizeCoords;

	BEGIN

	PutLine ('matrix currentmatrix');
	PutLine ('dup dup 4 get round 4 exch .25 add put');
	PutLine ('dup dup 5 get round 5 exch .25 add put setmatrix')

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE GenerateRegMarks (marks: TRegMarkList);

	VAR
		j: INTEGER;

	BEGIN

	PutLine ('1 dict begin /registrationmark {gsave translate');

	NormalizeCoords;

	PutLine ('.3 setlinewidth 0 setlinecap 0 setlinejoin');
	PutLine ('newpath 1 setgray 10 0 moveto 0 0 10 0 360 arc fill');
	PutLine ('0 setgray 8 0 moveto 0 0 8 0 360 arc');
	PutLine ('-10 0 moveto 10 0 lineto 0 -10 moveto 0 10 lineto stroke');
	PutLine ('4 0 moveto 0 0 4 0 360 arc fill');
	PutLine ('1 setgray -4 0 moveto 4 0 lineto 0 -4 moveto 0 4 lineto');
	PutLine ('stroke grestore} def');

	FOR j := 0 TO 7 DO
		BEGIN
		PutNumber (marks [j] . h);
		PutSpace;
		PutNumber (marks [j] . v);
		PutLine (' registrationmark')
		END;

	PutLine ('end')

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE GenerateStarTargets (bounds: Rect);

	BEGIN

	PutLine ('1 dict begin /startarget {gsave translate');

	NormalizeCoords;

	PutLine ('.3 setlinewidth 0 setlinecap 0 setlinejoin');
	PutLine ('newpath 1 setgray 0 0 10 0 360 arc fill');
	PutLine ('0 setgray 0 0 10 0 360 arc stroke');
	PutLine ('36 {1 0 moveto 0 0 10 -2.5 2.5 arc fill 10 rotate} repeat');
	PutLine ('grestore} def');

	PutNumber (bounds.left - 20);
	PutSpace;
	PutNumber (bounds.top - 20);
	PutLine (' startarget');

	PutNumber (bounds.right + 20);
	PutSpace;
	PutNumber (bounds.bottom + 20);
	PutLine (' startarget end');

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE GenerateCropMarks (bounds: Rect);

	BEGIN

	PutLine ('5 dict begin');

	PutString ('/top ');
	PutNumber (bounds.top);
	PutString (' def /bottom ');
	PutNumber (bounds.bottom);
	PutString (' def /left ');
	PutNumber (bounds.left);
	PutString (' def /right ');
	PutNumber (bounds.right);
	PutLine (' def');

	PutLine ('/cropmark {gsave translate rotate');

	NormalizeCoords;

	PutLine ('.3 setlinewidth 0 setlinecap 0 setlinejoin');
	PutLine ('0 setgray newpath');
	PutLine ('-30 0 moveto -10 0 lineto');
	PutLine ('0 -30 moveto 0 -10 lineto stroke grestore} def');

	PutLine ('0 left top cropmark');
	PutLine ('90 right top cropmark');
	PutLine ('180 right bottom cropmark');
	PutLine ('270 left bottom cropmark end')

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE GenerateGrayBar (bounds: Rect);

	VAR
		cell: INTEGER;

	BEGIN

	PutLine ('gsave');

	FOR cell := 0 TO 10 DO
		BEGIN

		PutNumber (cell);
		PutLine (' 10 div setgray newpath');

		PutNumber ((bounds.left + bounds.right - 176) DIV 2 + 16 * cell);
		PutSpace;
		PutNumber (bounds.bottom + 12);
		PutLine (' moveto');

		PutLine ('16 0 rlineto');
		PutLine ('0 16 rlineto');
		PutLine ('-16 0 rlineto closepath fill')

		END;

	PutLine ('grestore')

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE GenerateColorBars (bounds: Rect; channel: INTEGER);

	VAR
		bar: INTEGER;
		cell: INTEGER;

	PROCEDURE PutBand (mark: BOOLEAN);
		BEGIN
		IF mark THEN
			IF bar = 1 THEN
				PutString (' 1')
			ELSE IF cell >= 6 THEN
				PutString (' .5')
			ELSE
				PutString (' .8')
		ELSE
			PutString (' 0')
		END;

	BEGIN

	PutLine ('1 dict begin');

	PutLine ('/colorpatch {gsave');

		CASE channel OF

		0:	PutLine ('pop pop pop 1 exch sub setgray');
		1:	PutLine ('pop pop 1 exch sub setgray pop');
		2:	PutLine ('pop 1 exch sub setgray pop pop');
		3:	PutLine ('1 exch sub setgray pop pop pop');

		OTHERWISE
			BEGIN
			PutLine ('systemdict /setcmykcolor known {setcmykcolor}');
			PutLine ('{1 exch sub 4 1 roll');
			PutLine ('.11 mul exch .59 mul add exch .30 mul add');
			PutLine ('1 exch sub mul setgray} ifelse')
			END

		END;

	PutLine ('newpath moveto');
	PutLine ('16 0 rlineto');
	PutLine ('0 16 rlineto');
	PutLine ('-16 0 rlineto closepath fill grestore} def');

	FOR bar := 0 TO 1 DO
		FOR cell := 0 TO 7 DO
			BEGIN

			IF bar = 0 THEN
				PutNumber (bounds.left - 28)
			ELSE
				PutNumber (bounds.right + 12);

			PutSpace;

			PutNumber ((bounds.top + bounds.bottom - 128) DIV 2 + 16 * cell);

			PutBand ((cell >= 3) AND (cell <= 6));
			PutBand ((cell >= 1) AND (cell <= 3) OR (cell = 6));
			PutBand ((cell = 0) OR (cell = 1) OR (cell = 5) OR (cell = 6));
			PutBand (cell = 7);

			PutLine (' colorpatch')

			END;

	PutLine ('end')

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE GenerateBorder (location: Point;
						  width: INTEGER;
						  height: INTEGER;
						  resolution: Fixed;
						  border: Fixed);

	BEGIN

	PutLine ('2 dict begin gsave');

	PutString ('/width 72 65536 mul ');
	PutNumber (resolution);
	PutString (' div ');
	PutNumber (width);
	PutLine   (' mul def');

	PutString ('/height 72 65536 mul ');
	PutNumber (resolution);
	PutString (' div ');
	PutNumber (height);
	PutLine   (' mul def');

	PutLine ('0 setgray 0 setlinejoin newpath');

	PutNumber (location.h);
	PutSpace;
	PutNumber (location.v);
	PutLine (' moveto');

	PutLine ('width 0 rlineto 0 height rlineto');
	PutLine ('width neg 0 rlineto closepath');

	PutNumber (border);
	PutLine (' 72 mul 65536 div setlinewidth stroke');

	PutLine ('grestore end')

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE GenerateSetFont;

	BEGIN

	PutLine ('/RE {findfont begin currentdict dup length dict begin');
	PutLine ('{1 index /FID ne {def} {pop pop} ifelse} forall');
	PutLine ('/FontName exch def dup length 0 ne');
	PutLine ('{/Encoding Encoding 256 array copy def');
	PutLine ('0 exch {dup type /nametype eq');
	PutLine ('{Encoding 2 index 2 index put pop 1 add}');
	PutLine ('{exch pop} ifelse} forall} if pop');
	PutLine ('currentdict dup end end');
	PutLine ('/FontName get exch definefont pop} bind def');

	PutLine ('[39/quotesingle 96/grave 128/Adieresis/Aring/Ccedilla/Eacute');
	PutLine ('/Ntilde/Odieresis/Udieresis/aacute/agrave/acircumflex');
	PutLine ('/adieresis/atilde/aring/ccedilla/eacute/egrave/ecircumflex');
	PutLine ('/edieresis/iacute/igrave/icircumflex/idieresis/ntilde');
	PutLine ('/oacute/ograve/ocircumflex/odieresis/otilde/uacute/ugrave');
	PutLine ('/ucircumflex/udieresis/dagger/degree/cent/sterling/section');
	PutLine ('/bullet/paragraph/germandbls/registered/copyright/trademark');
	PutLine ('/acute/dieresis/.notdef/AE/Oslash/.notdef/plusminus/.notdef');
	PutLine ('/.notdef/yen/mu/.notdef/.notdef/.notdef/.notdef/.notdef');
	PutLine ('/ordfeminine/ordmasculine/.notdef/ae/oslash/questiondown');
	PutLine ('/exclamdown/logicalnot/.notdef/florin/.notdef/.notdef');
	PutLine ('/guillemotleft/guillemotright/ellipsis/.notdef/Agrave');
	PutLine ('/Atilde/Otilde/OE/oe/endash/emdash/quotedblleft/quotedblright');
	PutLine ('/quoteleft/quoteright/divide/.notdef/ydieresis/Ydieresis');
	PutLine ('/fraction/currency/guilsinglleft/guilsinglright/fi/fl');
	PutLine ('/daggerdbl/periodcentered/quotesinglbase/quotedblbase');
	PutLine ('/perthousand/Acircumflex/Ecircumflex/Aacute/Edieresis/Egrave');
	PutLine ('/Iacute/Icircumflex/Idieresis/Igrave/Oacute/Ocircumflex');
	PutLine ('/.notdef/Ograve/Uacute/Ucircumflex/Ugrave/dotlessi/circumflex');
	PutLine ('/tilde/macron/breve/dotaccent/ring/cedilla/hungarumlaut');
	PutLine ('/ogonek/caron]');

	PutLine ('/_Helvetica /Helvetica RE');

	PutLine ('/_Helvetica findfont 9 scalefont setfont')

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE GenerateText (s: Str255;
						center: BOOLEAN;
						left: INTEGER;
						right: INTEGER;
						bottom: INTEGER);

	BEGIN

	IF LENGTH (s) <> 0 THEN
		BEGIN

		PutLine ('<');
		PutHexData (@s[1], LENGTH (s));
		PutLine ('>');

		IF center THEN
			PutNumber ((left + right) DIV 2)
		ELSE
			PutNumber (left);

		PutSpace;
		PutNumber (bottom);
		PutLine (' moveto');

		IF center THEN
			PutLine ('dup stringwidth pop 2 div neg 0 rmoveto');

		PutLine ('gsave 1 -1 scale show grestore')

		END

	END;

{*****************************************************************************}

{$S APrinting}

PROCEDURE GenerateOther (s: Str255);

	BEGIN
	PutLine (s)
	END;

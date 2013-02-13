{Photoshop version 1.0.1, file: USeparation.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}
{$I USeparation.a.inc}

CONST
	kSSetupVersion1 = 13;
	kSSetupVersion  = 14;
	kSSetupFileType = '8BSS';

	cLoadBG  = 1;
	cSaveBG  = 2;
	cLoadUCR = 3;
	cSaveUCR = 4;
	
TYPE
	T8to12LookUpTable = ARRAY [0..255] OF INTEGER;
	T12to8LookUpTable = PACKED ARRAY [0..4096] OF CHAR;

	T3DCoord = ARRAY [0..2] OF INTEGER;

	T3DMatrix = ARRAY [0..2, 0..2] OF INTEGER;

	THullFace = RECORD
				base: T3DCoord;
				norm: T3DCoord
				END;

	THullEdge = RECORD
				head: T3DCoord;
				tail: T3DCoord;
				len2: LONGINT
				END;

VAR
	gInkLimit: INTEGER;

	gBlackMenu: MenuHandle;
	gOptBlackMenu: MenuHandle;

	gInkTransform: TInkTransform;

	gGCRTable: T8to12LookUpTable;
	gUCRTable: T8to12LookUpTable;

	gGammaTable1: T8to12LookUpTable;
	gGammaTable2: T12to8LookUpTable;

	gUCRSaturation: T8to12LookUpTable;

	gDesaturationTable: T8to12LookUpTable;

	gHullFace: ARRAY [0..11] OF THullFace;
	gHullEdge: ARRAY [0..17] OF THullEdge;
	
	gSeedCoord: ARRAY [0..5, 0..5, 0..5] OF T3DCoord;
	gSeedMatrix: ARRAY [0..5, 0..5, 0..5] OF T3DMatrix;

{*****************************************************************************}

{$S APreferences}

PROCEDURE MakeHiResTable (srcTable: TLookUpTable;
					      VAR dstTable: T8to12LookUpTable);
						  
	VAR
		j: INTEGER;
		pass: INTEGER;
		table: T8to12LookUpTable;
		
	BEGIN
	
	FOR j := 0 TO 255 DO
		dstTable [j] := (BSL (ORD (srcTable [j]), 12) + 127) DIV 255;
		
	FOR pass := 1 TO 3 DO
		BEGIN
		table := dstTable;
		FOR j := 1 TO 254 DO
			dstTable [j] := BSR (table [j - 1] +
							     table [j] * 2 +
							     table [j + 1] + 2, 2)
		END
		
	END;
					
{*****************************************************************************}

{$S AInit}

PROCEDURE InitSeparation;

	CONST
		kBlackMenuID	= 1013;
		kOptBlackMenuID = 1014;

	VAR
		h: Handle;
		index: INTEGER;
		count: INTEGER;
		theID: INTEGER;
		theName: Str255;
		theType: ResType;
		LUT: TLookUpTable;

	BEGIN

	gBlackMenu := GetMenu (kBlackMenuID);
	FailNIL (gBlackMenu);

	DisableItem (gBlackMenu, 2);

	count := Count1Resources ('GCR ');

	SetResLoad (FALSE);

	FOR index := 1 TO count DO
		BEGIN
		h := Get1IndResource ('GCR ', index);
		GetResInfo (h, theID, theType, theName);
		AppendMenu (gBlackMenu, theName)
		END;

	SetResLoad (TRUE);

	gOptBlackMenu := GetMenu (kOptBlackMenuID);
	FailNil (gOptBlackMenu);

	DisableItem (gOptBlackMenu, 3);

	FOR index := 0 TO 255 DO
		LUT [index] := CHR (Max (25, index));
	SmoothLUT (LUT, 10, 3, FALSE);
	MakeHiResTable (LUT, gUCRSaturation)
	
	END;

{*****************************************************************************}

{$S APreferences}

PROCEDURE SolveUCR (VAR gcrTable: TLookUpTable;
					VAR ucrTable: TLookUpTable);

	VAR
		j: INTEGER;
		k: INTEGER;
		s: EXTENDED;
		w: EXTENDED;

	BEGIN

	s := 1.0;

	FOR j := 255 DOWNTO 0 DO
		BEGIN

		k := ORD (gcrTable [j]);

		IF k > 0 THEN
			BEGIN
			w := SQR (k / 255);
			s := (j / k) * w + s * (1 - w);
			IF s > 1 THEN s := 1
			END;

		ucrTable [j] := CHR (Max (0,
							 Min (255,
								  j + ROUND ((255 - k) * s))))

		END

	END;

{*****************************************************************************}

{$S APreferences}

PROCEDURE GetBlackTables (VAR gcrTable: TLookUpTable;
						  VAR ucrTable: TLookUpTable;
						  id: INTEGER);

	VAR
		h: HLookUpTable;

	BEGIN

	h := HLookUpTable (Get1Resource ('GCR ', id));

	IF h = NIL THEN
		gcrTable := gNullLUT
	ELSE
		gcrTable := h^^;

	h := HLookUpTable (Get1Resource ('UCR ', id));

	IF h = NIL THEN
		SolveUCR (gcrTable, ucrTable)
	ELSE
		ucrTable := h^^

	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ARes4}

FUNCTION FindHue (r, g, b: INTEGER): INTEGER;

	FUNCTION Angle (x, y: INTEGER): INTEGER;
		BEGIN
		IF y < 0 THEN
			Angle := -Angle (x, -y)
		ELSE IF x < 0 THEN
			Angle := 2048 - Angle (-x, y)
		ELSE IF y > x THEN
			Angle := 1024 - Angle (y, x)
		ELSE IF x = 0 THEN
			Angle := 0
		ELSE
			Angle := BSL (y, 9) DIV x
		END;

	BEGIN
	FindHue := BAND ($FFF, Angle (2 * r - g - b, 2 * (g - b)))
	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S APreferences}

PROCEDURE BuildDesaturationTable;

	VAR
		r: INTEGER;
		g: INTEGER;
		b: INTEGER;
		s: INTEGER;
		h: INTEGER;
		s1: INTEGER;
		s2: INTEGER;
		h1: INTEGER;
		h2: INTEGER;
		ok: BOOLEAN;
		which: INTEGER;
		upper: INTEGER;
		lower: INTEGER;
		weight: LONGINT;
		LUT1: T8to12LookUpTable;
		LUT2: T8to12LookUpTable;
		hue: ARRAY [0..11] OF INTEGER;
		sat: ARRAY [0..11] OF INTEGER;

	PROCEDURE Solve (c, m, y: INTEGER);
		BEGIN
		DoInkTransform (c, m, y, r, g, b, gInkTransform)
		END;

	PROCEDURE Smooth8to12LUT (VAR LUT: T8to12LookUpTable);
							  
		CONST
			passes = 3;
			radius = 10;
	
		VAR
			j: INTEGER;
			pass: INTEGER;
			total: LONGINT;
			newLUT: T8to12LookUpTable;
	
		BEGIN

		FOR pass := 1 TO passes DO
			BEGIN
	
			total := radius;
	
			FOR j := -radius TO radius DO
				total := total + LUT [BAND ($FF, j)];
		
			FOR j := 0 TO 255 DO
				BEGIN
	
				newLUT [j] := total DIV (2 * radius + 1);
	
				total := total - LUT [BAND ($FF, j - radius    )]
							   + LUT [BAND ($FF, j + radius + 1)]
	
				END;
	
			LUT := newLUT
	
			END

		END;
		
	BEGIN

	FOR which := 0 TO 11 DO
		BEGIN

			CASE which OF
			0:	Solve (4096,    0,    0);
			1:	Solve (4096, 2048,    0);
			2:	Solve (4096, 4096,    0);
			3:	Solve (2048, 4096,    0);
			4:	Solve (   0, 4096,    0);
			5:	Solve (   0, 4096, 2048);
			6:	Solve (   0, 4096, 4096);
			7:	Solve (   0, 2048, 4096);
			8:	Solve (   0,    0, 4096);
			9:	Solve (2048,    0, 4096);
			10: Solve (4096,    0, 4096);
			11: Solve (4096,    0, 2048)
			END;

		hue [which] := BSR (FindHue (r, g, b), 4);

		lower := Min (Min (r, g), b);
		upper := Max (Max (r, g), b);

		IF upper >= upper - lower THEN
			sat [which] := 4096
		ELSE
			sat [which] := ORD4 (upper) * 4096 DIV (upper - lower)

		END;

	FOR which := 0 TO 11 DO
		BEGIN

		h1 := hue [which];
		h2 := hue [(which + 1) MOD 12];

		WHILE h2 < h1 DO h2 := h2 + 256;

		s1 := sat [which];
		s2 := sat [(which + 1) MOD 12];

		FOR h := h1 + 1 TO h2 DO
			BEGIN

			IF h = h2 THEN
				s := s2
			ELSE
				s := (s1 * ORD4 (h2 - h) +
					  s2 * ORD4 (h - h1)) DIV (h2 - h1);

			gDesaturationTable [BAND (h, $FF)] := s

			END

		END;

	LUT1 := gDesaturationTable;

	FOR weight := 2 TO 20 DO
		BEGIN
		
		LUT2 := LUT1;

		Smooth8to12LUT (LUT2);

		ok := TRUE;

		FOR h := 0 TO 255 DO
			BEGIN

			s := LUT2 [h] - gDesaturationTable [h];

			IF s > 0 THEN
				BEGIN
				ok := FALSE;
				LUT1 [h] := Max (0, LUT1 [h] - weight * s)
				END

			END;

		IF ok THEN LEAVE
		
		END;

	gDesaturationTable := LUT2
	
	END;

{*****************************************************************************}

{$S APreferences}

PROCEDURE BuildSeedTable;

	VAR
		c: INTEGER;
		m: INTEGER;
		y: INTEGER;
		j: INTEGER;
		k: INTEGER;
		x: LONGINT;
		det: LONGINT;
		A: ARRAY [0..2, 0..2] OF LONGINT;
		B: ARRAY [0..2, 0..2] OF LONGINT;

	BEGIN
	
	FOR c := 0 TO 5 DO
		FOR m := 0 TO 5 DO
			FOR y := 0 TO 5 DO
				DoInkTransform ((c * 4096 + 2) DIV 5,
								(m * 4096 + 2) DIV 5,
								(y * 4096 + 2) DIV 5,
								gSeedCoord [c, m, y, 0],
								gSeedCoord [c, m, y, 1],
								gSeedCoord [c, m, y, 2],
								gInkTransform);
								
	FOR c := 0 TO 5 DO
		FOR m := 0 TO 5 DO
			FOR y := 0 TO 5 DO
				BEGIN
				
				FOR j := 0 TO 2 DO
					BEGIN

					IF c = 0 THEN
						A [j,0] := 2 * (gSeedCoord [1, m, y, j] -
										gSeedCoord [0, m, y, j])
					ELSE IF c = 5 THEN
						A [j,0] := 2 * (gSeedCoord [5, m, y, j] -
										gSeedCoord [4, m, y, j])
					ELSE
						A [j,0] := gSeedCoord [c + 1, m, y, j] -
								   gSeedCoord [c - 1, m, y, j];

					IF m = 0 THEN
						A [j,1] := 2 * (gSeedCoord [c, 1, y, j] -
										gSeedCoord [c, 0, y, j])
					ELSE IF m = 5 THEN
						A [j,1] := 2 * (gSeedCoord [c, 5, y, j] -
										gSeedCoord [c, 4, y, j])
					ELSE
						A [j,1] := gSeedCoord [c, m + 1, y, j] -
								   gSeedCoord [c, m - 1, y, j];

					IF y = 0 THEN
						A [j,2] := 2 * (gSeedCoord [c, m, 1, j] -
										gSeedCoord [c, m, 0, j])
					ELSE IF y = 5 THEN
						A [j,2] := 2 * (gSeedCoord [c, m, 5, j] -
										gSeedCoord [c, m, 4, j])
					ELSE
						A [j,2] := gSeedCoord [c, m, y + 1, j] -
								   gSeedCoord [c, m, y - 1, j]

					END;
					
				FOR j := 0 TO 2 DO
					FOR k := 0 TO 2 DO
						A [j, k] := A [j, k] DIV 16;

				B [0,0] := A [1,1] * A [2,2] - A [2,1] * A [1,2];
				B [0,1] := A [2,1] * A [0,2] - A [0,1] * A [2,2];
				B [0,2] := A [0,1] * A [1,2] - A [1,1] * A [0,2];
				B [1,0] := A [2,0] * A [1,2] - A [1,0] * A [2,2];
				B [1,1] := A [0,0] * A [2,2] - A [2,0] * A [0,2];
				B [1,2] := A [1,0] * A [0,2] - A [0,0] * A [1,2];
				B [2,0] := A [1,0] * A [2,1] - A [2,0] * A [1,1];
				B [2,1] := A [2,0] * A [0,1] - A [0,0] * A [2,1];
				B [2,2] := A [0,0] * A [1,1] - A [1,0] * A [0,1];

				det := (A [0,0] * B [0,0] +
						A [0,1] * B [1,0] +
						A [0,2] * B [2,0]) DIV 102;

				FOR j := 0 TO 2 DO
					FOR k := 0 TO 2 DO
						BEGIN

						IF det = 0 THEN
							x := 256 * ORD (j = k)
						ELSE
							x := BSL (B [j,k], 8) DIV det;

						IF x >	4096 THEN x :=	4096;
						IF x < -4096 THEN x := -4096;

						gSeedMatrix [c, m, y, j, k] := x

						END

				END
		
	END;

{*****************************************************************************}

{$S APreferences}

PROCEDURE BuildConvexHull;

	TYPE
		TLong3DCoord = ARRAY [0..2] OF LONGINT;

	VAR
		kCoord: T3DCoord;
		rCoord: T3DCoord;
		gCoord: T3DCoord;
		bCoord: T3DCoord;
		cCoord: T3DCoord;
		mCoord: T3DCoord;
		yCoord: T3DCoord;
		wCoord: T3DCoord;
		faceCount: INTEGER;
		edgeCount: INTEGER;

	PROCEDURE SubCoord (A, B: T3DCoord; VAR C: T3DCoord);
		BEGIN
		C [0] := A [0] - B [0];
		C [1] := A [1] - B [1];
		C [2] := A [2] - B [2]
		END;

	PROCEDURE CrossProduct (A, B: T3DCoord; VAR C: TLong3DCoord);
		BEGIN
		C [0] := A [1] * ORD4 (B [2]) - B [1] * ORD4 (A [2]);
		C [1] := A [2] * ORD4 (B [0]) - B [2] * ORD4 (A [0]);
		C [2] := A [0] * ORD4 (B [1]) - B [0] * ORD4 (A [1])
		END;

	FUNCTION DotProduct (A: T3DCoord; B: TLong3DCoord): LONGINT;
		BEGIN
		DotProduct := A [0] * B [0] + A [1] * B [1] + A [2] * B [2]
		END;

	PROCEDURE AddEdge (pt0, pt1: T3DCoord);

		VAR
			j: INTEGER;
			k: INTEGER;
			A: T3DCoord;
			match: BOOLEAN;

		BEGIN

		FOR j := 0 TO edgeCount - 1 DO
			BEGIN

			match := TRUE;

			FOR k := 0 TO 2 DO
				match := match & (gHullEdge [j] . head [k] = pt1 [k]) &
								 (gHullEdge [j] . tail [k] = pt0 [k]);

			IF match THEN
				EXIT (AddEdge)

			END;

		gHullEdge [edgeCount] . head := pt0;
		gHullEdge [edgeCount] . tail := pt1;

		SubCoord (pt1, pt0, A);

		gHullEdge [edgeCount] . len2 := SQR (ORD4 (A [0])) +
										SQR (ORD4 (A [1])) +
										SQR (ORD4 (A [2]));

		edgeCount := edgeCount + 1

		END;

	PROCEDURE AddFace (pt0, pt1, pt2: T3DCoord);

		VAR
			A: T3DCoord;
			B: T3DCoord;
			C: T3DCoord;
			len: EXTENDED;
			N: TLong3DCoord;
			scale: EXTENDED;

		BEGIN

		AddEdge (pt0, pt1);
		AddEdge (pt1, pt2);
		AddEdge (pt2, pt0);

		SubCoord (pt1, pt0, A);
		SubCoord (pt2, pt0, B);

		CrossProduct (A, B, N);

		len := SQRT (SQR (N [0] * 1.0) +
					 SQR (N [1] * 1.0) +
					 SQR (N [2] * 1.0));

		IF len < 1.0 THEN len := 1.0;

		scale := 16384 / len;

		C [0] := ROUND (N [0] * scale);
		C [1] := ROUND (N [1] * scale);
		C [2] := ROUND (N [2] * scale);

		gHullFace [faceCount] . base := pt0;
		gHullFace [faceCount] . norm := C;

		faceCount := faceCount + 1

		END;

	PROCEDURE AddQuad (pt0, pt1, pt2, pt3: T3DCoord);

		VAR
			A: T3DCoord;
			B: T3DCoord;
			C: T3DCoord;
			D: TLong3DCoord;

		BEGIN

		SubCoord (pt1, pt0, A);
		SubCoord (pt2, pt0, B);
		SubCoord (pt3, pt0, C);

		CrossProduct (A, C, D);

		WHILE (ABS (D [0]) > $10000) |
			  (ABS (D [1]) > $10000) |
			  (ABS (D [2]) > $10000) DO
			 BEGIN
			 D [0] := D [0] DIV 2;
			 D [1] := D [1] DIV 2;
			 D [2] := D [2] DIV 2
			 END;

		IF DotProduct (B, D) <= 0 THEN
			BEGIN
			AddFace (pt0, pt1, pt3);
			AddFace (pt2, pt3, pt1)
			END
		ELSE
			BEGIN
			AddFace (pt0, pt1, pt2);
			AddFace (pt0, pt2, pt3)
			END

		END;

	BEGIN

	kCoord := gSeedCoord [0, 0, 0];
	rCoord := gSeedCoord [5, 0, 0];
	gCoord := gSeedCoord [0, 5, 0];
	bCoord := gSeedCoord [0, 0, 5];
	cCoord := gSeedCoord [0, 5, 5];
	mCoord := gSeedCoord [5, 0, 5];
	yCoord := gSeedCoord [5, 5, 0];
	wCoord := gSeedCoord [5, 5, 5];

	faceCount := 0;
	edgeCount := 0;

	AddQuad (kCoord, bCoord, cCoord, gCoord);
	AddQuad (kCoord, rCoord, mCoord, bCoord);
	AddQuad (kCoord, gCoord, yCoord, rCoord);
	AddQuad (wCoord, mCoord, rCoord, yCoord);
	AddQuad (wCoord, yCoord, gCoord, cCoord);
	AddQuad (wCoord, cCoord, bCoord, mCoord)

	END;

{*****************************************************************************}

{$S APreferences}

PROCEDURE ApplyUCA (uca: INTEGER);

	VAR
		j: INTEGER;
		gray: INTEGER;
		scale: LONGINT;

	BEGIN
	
	FOR j := 0 TO 127 DO
		BEGIN
		
		gray := (BSL (j, 12) + 127) DIV 255;
		
		scale := 16384 - (ORD4 (SQR (128 - j)) * uca + 50) DIV 100;
		
		gUCRTable [j] := (gUCRTable [j] - gray) * scale DIV 16384 + gray
		
		END
	
	END;

{*****************************************************************************}

{$S APreferences}

PROCEDURE BuildInkTransform (VAR setup: TSeparationSetup);

	VAR
		r: INTEGER;
		g: INTEGER;
		b: INTEGER;
		gray: INTEGER;
		
	FUNCTION MapToRange (x: INTEGER): INTEGER;
		BEGIN
		MapToRange := (4096 * BAND (BSR (x, 8), $FF) + 127) DIV 255
		END;

	PROCEDURE ColorColumn (col: INTEGER; color: RGBColor);
		BEGIN
		gInkTransform [1, col] := MapToRange (color.red);
		gInkTransform [2, col] := MapToRange (color.green);
		gInkTransform [3, col] := MapToRange (color.blue)
		END;

	PROCEDURE AdjustSubtractive (col, percent: INTEGER);

		VAR
			x: LONGINT;
			row: INTEGER;

		BEGIN
		FOR row := 1 TO 3 DO
			BEGIN
			x := 4096 - gInkTransform [row, col];
			x := (x * 100 + percent DIV 2) DIV percent;
			gInkTransform [row, col] := 4096 - x
			END
		END;

	PROCEDURE AdjustAdditive (col, s1, s2, percent: INTEGER);

		VAR
			x: LONGINT;
			y: LONGINT;
			z: LONGINT;
			row: INTEGER;

		BEGIN
		FOR row := 1 TO 3 DO
			BEGIN
			x := 4096 - gInkTransform [row, col];
			y := 4096 - gInkTransform [row, s1];
			z := 4096 - gInkTransform [row, s2];
			x := (x * 10000 + SQR (percent) DIV 2) DIV SQR (percent);
			x := x - ((y + z) * (100 - percent) + percent DIV 2) DIV percent;
			gInkTransform [row, col] := 4096 - x
			END
		END;

	BEGIN

	WITH setup DO
		BEGIN

		FOR gray := 0 TO 255 DO
			gGammaTable1 [gray] := Map8to12Bit (gray, fGamma);
			
		FOR gray := 0 TO 4096 DO
			gGammaTable2 [gray] := CHR (Map12to8Bit (gray, fGamma));
		
		MakeHiResTable (fGCRTable, gGCRTable);
		MakeHiResTable (fUCRTable, gUCRTable);
		
		ApplyUCA (fUCAPercent);

		IF fInkMaximum = 0 THEN
			gInkLimit := 0
		ELSE
			gInkLimit := 16384 - (4096 * ORD4 (fInkMaximum) + 50) DIV 100;
			
		ColorColumn (1, fProgressive [1] . rgb);
		ColorColumn (2, fProgressive [2] . rgb);
		ColorColumn (3, fProgressive [3] . rgb);
		ColorColumn (4, fProgressive [4] . rgb);
		ColorColumn (5, fProgressive [5] . rgb);
		ColorColumn (6, fProgressive [6] . rgb);
		
		gInkTransform [1, 7] := 0;
		gInkTransform [2, 7] := 0;
		gInkTransform [3, 7] := 0;
		
		AdjustSubtractive (1, fProgressive [1] . percent);
		AdjustSubtractive (2, fProgressive [2] . percent);
		AdjustSubtractive (3, fProgressive [3] . percent);

		AdjustAdditive (4, 2, 3, fProgressive [4] . percent);
		AdjustAdditive (5, 1, 3, fProgressive [5] . percent);
		AdjustAdditive (6, 1, 2, fProgressive [6] . percent);

		IF fProgressive [7] . percent = 0 THEN
			BEGIN

			DoInkTransform (2048, 2048, 2048, r, g, b, gInkTransform);
						
			r := (Min (4096, Max (0, r)) * 255 + 2048) DIV 4096;
			g := (Min (4096, Max (0, g)) * 255 + 2048) DIV 4096;
			b := (Min (4096, Max (0, b)) * 255 + 2048) DIV 4096;

			WITH fProgressive [7] . rgb DO
				BEGIN
				red   := $101 * r;
				green := $101 * g;
				blue  := $101 * b
				END;

			fProgressive [7] . percent := 50

			END

		ELSE
			BEGIN

			gray := (ORD4 (100 - fProgressive [7] . percent) *
					 4096 + 50) DIV 100;
					 
			DoInkTransform (gray, gray, gray, r, g, b, gInkTransform);

			WITH fProgressive [7] . rgb DO
				BEGIN
				r := MapToRange (red)   - r;
				g := MapToRange (green) - g;
				b := MapToRange (blue)  - b
				END;
				
			gInkTransform [1, 7] := r;
			gInkTransform [2, 7] := g;
			gInkTransform [3, 7] := b

			END;

		BuildDesaturationTable;

		BuildSeedTable;

		BuildConvexHull
		
		END

	END;

{*****************************************************************************}

{$S APreferences}

PROCEDURE InitCMYK;

	BEGIN
	BuildInkTransform (gPreferences.fSeparation);
	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ARes4}

PROCEDURE ProjectHull (VAR r: INTEGER;
					   VAR g: INTEGER;
					   VAR b: INTEGER);

	LABEL
		1, 2;

	VAR
		j: INTEGER;
		k: INTEGER;
		rr: INTEGER;
		gg: INTEGER;
		bb: INTEGER;
		rrr: INTEGER;
		ggg: INTEGER;
		bbb: INTEGER;
		dist: LONGINT;
		gray: INTEGER;
		bestR: INTEGER;
		bestG: INTEGER;
		bestB: INTEGER;
		inside: BOOLEAN;
		delta1: LONGINT;
		delta2: LONGINT;
		bestDist: LONGINT;

	FUNCTION Luminosity (r, g, b: INTEGER): INTEGER;
		BEGIN
		Luminosity := (Min (Max (0, r), 4096) * 30 +
					   Min (Max (0, g), 4096) * 59 +
					   Min (Max (0, b), 4096) * 11 + 50) DIV 100
		END;

	BEGIN

	inside := TRUE;

	FOR j := 0 TO 11 DO
		BEGIN

		rr := r;
		gg := g;
		bb := b;

		IF ProjectFace (rr, gg, bb, @gHullFace [j]) THEN
			BEGIN

			inside := FALSE;

			FOR k := 0 TO 11 DO
				IF j <> k THEN
					IF ProjectFace (rr, gg, bb, @gHullFace [k]) THEN
						GOTO 1;

			GOTO 2;

			1:	{ Projected point outside hull }

			END

		END;

	IF inside THEN
		EXIT (ProjectHull);

	FOR j := 0 TO 17 DO
		BEGIN

		rr := r;
		gg := g;
		bb := b;

		dist := ProjectEdge (rr, gg, bb, @gHullEdge [j]);

		IF (j = 0) | (dist < bestDist) THEN
			BEGIN
			bestDist := dist;
			bestR := rr;
			bestG := gg;
			bestB := bb
			END

		END;

	rr := bestR;
	gg := bestG;
	bb := bestB;

	2:	{ Outside of hull }

	delta1 := Luminosity (rr, gg, bb) - Luminosity (r, g, b);

	IF delta1 <= 0 THEN
		BEGIN
		r := rr;
		g := gg;
		b := bb
		END

	ELSE
		BEGIN

		bestDist := 0;

		gray := Luminosity (r, g, b) DIV 2 + 128;

		FOR j := 0 TO 11 DO
			BEGIN

			rrr := r;
			ggg := g;
			bbb := b;

			dist := ProjectLine (rrr, ggg, bbb,
								 gray, gray, gray,
								 @gHullFace [j]);

			IF dist >= bestDist THEN
				BEGIN
				bestDist := dist;
				bestR := rrr;
				bestG := ggg;
				bestB := bbb
				END

			END;

		delta2 := Max (Luminosity (r, g, b) -
					   Luminosity (bestR, bestG, bestB), 128);

		r := (rr * delta2 + bestR * delta1) DIV (delta1 + delta2);
		g := (gg * delta2 + bestG * delta1) DIV (delta1 + delta2);
		b := (bb * delta2 + bestB * delta1) DIV (delta1 + delta2)

		END

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE SolveCMY (r: INTEGER;
					g: INTEGER;
					b: INTEGER;
					VAR c: INTEGER;
					VAR m: INTEGER;
					VAR y: INTEGER);

	VAR
		rr: INTEGER;
		gg: INTEGER;
		bb: INTEGER;
		dr: INTEGER;
		dg: INTEGER;
		db: INTEGER;
		dc: INTEGER;
		dm: INTEGER;
		dy: INTEGER;
		guess: INTEGER;

	BEGIN

	FindSeedCMY (r, g, b, c, m, y, @gSeedCoord);

	rr := gSeedCoord [c, m, y, 0];
	gg := gSeedCoord [c, m, y, 1];
	bb := gSeedCoord [c, m, y, 2];

	c := (c * 4096 + 2) DIV 5;
	m := (m * 4096 + 2) DIV 5;
	y := (y * 4096 + 2) DIV 5;

	FOR guess := 1 TO 10 DO
		BEGIN

		IF guess <> 1 THEN
			DoInkTransform (c, m, y, rr, gg, bb, gInkTransform);

		dr := r - rr;
		dg := g - gg;
		db := b - bb;
		
		FindDeltaCMY (dr, dg, db, dc, dm, dy,
					  @gSeedMatrix [(c + 409) DIV 819,
									(m + 409) DIV 819,
									(y + 409) DIV 819]);

		IF (guess >= 5) & ((ABS (dc) >= 2) |
						   (ABS (dm) >= 2) |
						   (ABS (dy) >= 2)) THEN
			BEGIN
			dc := dc DIV 2;
			dm := dm DIV 2;
			dy := dy DIV 2
			END;

		IF c + dc < 0 THEN
			dc := -c
		ELSE IF c + dc > 4096 THEN
			dc := 4096 - c;

		IF m + dm < 0 THEN
			dm := -m
		ELSE IF m + dm > 4096 THEN
			dm := 4096 - m;

		IF y + dy < 0 THEN
			dy := -y
		ELSE IF y + dy > 4096 THEN
			dy := 4096 - y;

		IF (dc = 0) & (dm = 0) & (dy = 0) THEN LEAVE;

		c := c + dc;
		m := m + dm;
		y := y + dy

		END

	END;

{*****************************************************************************}

{$S ARes4}

FUNCTION FindDesaturation (r, g, b: INTEGER): INTEGER;

	VAR
		w: LONGINT;
		h1: INTEGER;
		h2: INTEGER;
		hue: INTEGER;

	BEGIN
	
	hue := FindHue (r, g, b);
	
	w := BAND (hue, $F);
	
	h1 := BSR (hue, 4);
	h2 := BAND (h1 + 1, $FF);
	
	FindDesaturation := BSR (gDesaturationTable [h1] * (16 - w) +
							 gDesaturationTable [h2] * w + 8, 4)
	
	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE DesaturateRGB (VAR r: INTEGER;
						 VAR g: INTEGER;
						 VAR b: INTEGER);

	VAR
		scale: INTEGER;
		upper: INTEGER;

	BEGIN

	scale := FindDesaturation (r, g, b);

	upper := r;
	IF upper < g THEN upper := g;
	IF upper < b THEN upper := b;

	r := upper - BSR (ORD4 (upper - r) * scale + 2048, 12);
	g := upper - BSR (ORD4 (upper - g) * scale + 2048, 12);
	b := upper - BSR (ORD4 (upper - b) * scale + 2048, 12)

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE SupersaturateRGB (VAR r: INTEGER;
							VAR g: INTEGER;
							VAR b: INTEGER);

	VAR
		half: INTEGER;
		scale: INTEGER;
		upper: INTEGER;

	BEGIN

	scale := FindDesaturation (r, g, b);

	half := scale DIV 2;

	upper := r;
	IF upper < g THEN upper := g;
	IF upper < b THEN upper := b;

	r := upper - (BSL (upper - r, 12) + half) DIV scale;
	g := upper - (BSL (upper - g, 12) + half) DIV scale;
	b := upper - (BSL (upper - b, 12) + half) DIV scale

	END;

{*****************************************************************************}

{$S ARes4}

FUNCTION HighResLookUp (LUT: T8to12LookUpTable; index: INTEGER): INTEGER;

	VAR
		j: INTEGER;
		k: LONGINT;
		x: LONGINT;

	BEGIN
	
	x := ORD4 (index) * 255;
	
	j := BSR (x, 12);
	k := BAND (x, 4095);
	
	IF k = 0 THEN
		HighResLookUp := LUT [j]
	ELSE
		HighResLookUp := BSR (LUT [j] * (4096 - k) +
							  LUT [j + 1] * k + 2048, 12)
	
	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE SolveForCMYK (r: INTEGER;
						g: INTEGER;
						b: INTEGER;
						VAR c: INTEGER;
						VAR m: INTEGER;
						VAR y: INTEGER;
						VAR k: INTEGER;
						VAR inside: BOOLEAN);

	VAR
		rr: INTEGER;
		gg: INTEGER;
		bb: INTEGER;
		ucr: INTEGER;
		lum1: INTEGER;
		lum2: INTEGER;
		face: INTEGER;
		gray: INTEGER;
		this: INTEGER;
		pass: INTEGER;
		delta: INTEGER;
		saveR: INTEGER;
		saveG: INTEGER;
		saveB: INTEGER;
		scale1: LONGINT;
		scale2: INTEGER;

	BEGIN
	
	r := gGammaTable1 [r];
	g := gGammaTable1 [g];
	b := gGammaTable1 [b];
	
	SupersaturateRGB (r, g, b);

	saveR := r;
	saveG := g;
	saveB := b;

	ProjectHull (r, g, b);

	SolveCMY (r, g, b, c, m, y);

	DoInkTransform (c, m, y, rr, gg, bb, gInkTransform);

	inside := (ABS (rr - saveR) <= 16) &
			  (ABS (gg - saveG) <= 16) &
			  (ABS (bb - saveB) <= 16);

	FOR face := 6 TO 11 DO
		BEGIN
		this := ProjectGray (r, g, b, @gHullFace [face]);
		IF (face = 6) | (this > gray) THEN
			gray := this
		END;
		
	k := HighResLookUp (gGCRTable, gray);
	
	ucr := HighResLookUp (gUCRTable, gray) - gray;

	IF ucr <> 0 THEN
		BEGIN
		
		lum1 := Max ((30 * ORD4 (r) +
					  59 * ORD4 (g) +
					  11 * ORD4 (b)) DIV 100, 0);
					
		scale2 := HighResLookUp (gUCRSaturation, gray);
		scale1 := Max (scale2, Min (ucr + scale2, 5 * scale2));

		r := r - gray;
		g := g - gray;
		b := b - gray;

		gray := gray + ucr;

		r := r * scale1 DIV scale2;
		g := g * scale1 DIV scale2;
		b := b * scale1 DIV scale2;

		r := r + gray;
		g := g + gray;
		b := b + gray;

		ProjectHull (r, g, b);

		SolveCMY (r, g, b, c, m, y);
		
		lum2 := BSR ((30 * ORD4 (r) +
					  59 * ORD4 (g) +
					  11 * ORD4 (b)) DIV 100 * k, 12);
				
		IF lum2 > lum1 THEN
			k := Max (ORD4 (k) * lum1 DIV lum2, gGCRTable [0])
				 
		END;
		
	FOR pass := 1 TO 3 DO
		BEGIN
		
		delta := (gInkLimit - c - m - y - k + 2) DIV 3;
		
		IF delta > 0 THEN
			BEGIN
			
			IF pass = 1 THEN
				DoInkTransform (c, m, y, r, g, b, gInkTransform);

			lum1 := Max ((30 * ORD4 (r) +
						  59 * ORD4 (g) +
						  11 * ORD4 (b)) DIV 100, 0);
			
			c := Min (c + delta, 4096);
			m := Min (m + delta, 4096);
			y := Min (y + delta, 4096);
			
			DoInkTransform (c, m, y, r, g, b, gInkTransform);

			lum2 := Max ((30 * ORD4 (r) +
						  59 * ORD4 (g) +
						  11 * ORD4 (b)) DIV 100, Max (lum1, 1));
			
			k := k * ORD4 (lum1) DIV lum2
			
			END
			
		ELSE
			LEAVE
			
		END;
		
	c := ORD (gGammaTable2 [c]);
	m := ORD (gGammaTable2 [m]);
	y := ORD (gGammaTable2 [y]);
	k := ORD (gGammaTable2 [k])

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE SolveForCMY (r: INTEGER;
					   g: INTEGER;
					   b: INTEGER;
					   VAR c: INTEGER;
					   VAR m: INTEGER;
					   VAR y: INTEGER);

	BEGIN
	
	r := gGammaTable1 [r];
	g := gGammaTable1 [g];
	b := gGammaTable1 [b];
	
	SupersaturateRGB (r, g, b);

	ProjectHull (r, g, b);

	SolveCMY (r, g, b, c, m, y);
		
	c := ORD (gGammaTable2 [c]);
	m := ORD (gGammaTable2 [m]);
	y := ORD (gGammaTable2 [y])

	END;

{*****************************************************************************}

{$S ARes4}

PROCEDURE SolveForRGB (c: INTEGER;
					   m: INTEGER;
					   y: INTEGER;
					   k: INTEGER;
					   VAR r: INTEGER;
					   VAR g: INTEGER;
					   VAR b: INTEGER);

	BEGIN
	
	c := gGammaTable1 [c];
	m := gGammaTable1 [m];
	y := gGammaTable1 [y];
	k := gGammaTable1 [k];
	
	DoInkTransform (c, m, y, r, g, b, gInkTransform);

	DesaturateRGB (r, g, b);

	ClipRGBValue (r, g, b);

	IF k <> 4096 THEN
		BEGIN
		r := BSR (ORD4 (r) * k + 2048, 12);
		g := BSR (ORD4 (g) * k + 2048, 12);
		b := BSR (ORD4 (b) * k + 2048, 12)
		END;
	
	r := ORD (gGammaTable2 [r]);
	g := ORD (gGammaTable2 [g]);
	b := ORD (gGammaTable2 [b])
	
	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S ARes4}

FUNCTION CvtToPercent (gray: INTEGER): INTEGER;

	VAR
		percent: INTEGER;

	BEGIN
	
	gray := gGammaTable1 [gray];
	
	percent := 100 - (ORD4 (gray) * 100 + 2048) DIV 4096;
	
	IF (percent = 100) AND (gray <> 0) THEN
		percent := 99;
		
	IF (percent = 0) AND (gray <> 4096) THEN
		percent := 1;
		
	CvtToPercent := percent
	
	END;

{*****************************************************************************}

{$S ARes4}

FUNCTION CvtFromPercent (percent: INTEGER): INTEGER;

	VAR
		gray: INTEGER;

	BEGIN
	
	gray := (ORD4 (100 - percent) * 4096 + 50) DIV 100;
	
	CvtFromPercent := ORD (gGammaTable2 [gray])
	
	END;
	
{*****************************************************************************}

{$S APreferences}

FUNCTION SolveMaxInk: INTEGER;

	VAR
		r: INTEGER;
		g: INTEGER;
		b: INTEGER;
		c: INTEGER;
		m: INTEGER;
		y: INTEGER;
		k: INTEGER;
		fi: FailInfo;
		limit: INTEGER;
		inside: BOOLEAN;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress
		END;

	BEGIN
	
	CommandProgress (cSolveMaxInk);

	CatchFailures (fi, CleanUp);

	limit := 16384;

	FOR r := 0 TO 15 DO
		FOR g := 0 TO 15 DO
			BEGIN

			MoveHands (FALSE);

			UpdateProgress (r * 16 + g, 256);

			FOR b := 0 TO 15 DO
				BEGIN

				SolveForCMYK (r * 17, g * 17, b * 17, c, m, y, k, inside);
				
				limit := Min (limit, gGammaTable1 [c] +
									 gGammaTable1 [m] +
									 gGammaTable1 [y] +
									 gGammaTable1 [k])

				END

			END;

	UpdateProgress (1, 1);

	SolveMaxInk := Max (200, (ORD4 (16384 - limit) * 100 + 2048) DIV 4096);

	Success (fi);
	CleanUp (0, 0);

	SetCursor (arrow);
	gMovingHands := FALSE

	END;

{*****************************************************************************}

{$S APreferences}

PROCEDURE TBlackPopUp.IBlackPopUp (itsLabelNumber: INTEGER;
								   itsItemNumber: INTEGER;
								   itsParent: TDialogView);

	BEGIN

	IPopUpMenu (itsLabelNumber, itsItemNumber, itsParent, gBlackMenu, 1);

	fPickAgain := TRUE

	END;

{*****************************************************************************}

{$S APreferences}

FUNCTION TBlackPopUp.DoPopUpMenu (optionDown: BOOLEAN): BOOLEAN; OVERRIDE;

	VAR
		ok: BOOLEAN;
		savePick: INTEGER;
		saveMenu: MenuHandle;

	BEGIN

	fCmdPick := 0;

	savePick := fPick;
	saveMenu := fMenu;

	IF optionDown THEN
		BEGIN

		fPick := 0;
		fMenu := gOptBlackMenu;

		ok := INHERITED DoPopUpMenu (TRUE);

			CASE fPick OF
			1:	fCmdPick := cLoadBG;
			2:	fCmdPick := cSaveBG;
			4:	fCmdPick := cLoadUCR;
			5:	fCmdPick := cSaveUCR
			END;

		SetMenu (saveMenu, savePick)

		END

	ELSE
		BEGIN

		ok := INHERITED DoPopUpMenu (FALSE);

		IF ok AND (fPick = 1) THEN
			BEGIN
			fCmdPick := cLoadBG;
			SetMenu (saveMenu, savePick)
			END
		ELSE
			ok := ok AND (fPick <> savePick)

		END;

	DoPopUpMenu := ok

	END;

{*****************************************************************************}

{$S APreferences}

PROCEDURE TSeparationDialog.ISeparationDialog (VAR setup: TSeparationSetup);

	CONST
		kDialogID		= 1009;
		kHookItem		= 3;
		kColorItems 	= 6;
		kPercentItems	= 13;
		kInkItem		= 20;
		kGammaItem		= 21;
		kBlackLabel 	= 22;
		kBlackItem		= 23;
		kUCAItem        = 24;

	VAR
		r: Rect;
		fi: FailInfo;
		ft: TFixedText;
		which: INTEGER;
		itemType: INTEGER;
		itemHandle: Handle;
		aBlackPopUp: TBlackPopUp;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Free
		END;

	BEGIN

	fSetup := setup;

	fPalette := NIL;

	IBWDialog (kDialogID, kHookItem, ok);

	CatchFailures (fi, CleanUp);

	fColorItems := kColorItems;

	FOR which := 1 TO kProgressive DO
		BEGIN
		GetDItem (fDialogPtr, kColorItems + which - 1,
				  itemType, itemHandle, r);
		fColorRect [which] := r
		END;

	FOR which := 1 TO kProgressive DO
		BEGIN
		IF which = kProgressive THEN
			ft := DefineFixedText
				  (kPercentItems + which - 1,
				   0, TRUE, TRUE, 30, 70)
		ELSE
			ft := DefineFixedText
				  (kPercentItems + which - 1,
				   0, FALSE, TRUE, 70, 100);
		fColorPercent [which] := ft;
		END;

	fGamma := DefineFixedText (kGammaItem, 2, FALSE, FALSE, 100, 220);

	fInkMaximum := DefineFixedText (kInkItem, 0, TRUE, TRUE, 200, 400);
	
	fUCAPercent := DefineFixedText (kUCAItem, 0, FALSE, TRUE, 0, 100);

	NEW (aBlackPopUp);
	FailNil (aBlackPopUp);

	aBlackPopUp.IBlackPopUp (kBlackLabel, kBlackItem, SELF);

	fBlackPopUp := aBlackPopUp;

	StuffValues;

	IF gConfiguration.hasColorToolbox THEN
		BEGIN
		fPalette := GetNewPalette (kDialogID);
		SetPalette (fDialogPtr, fPalette, TRUE)
		END;

	UpdatePalette;

	Success (fi)

	END;

{*****************************************************************************}

{$S APreferences}

PROCEDURE TSeparationDialog.Free; OVERRIDE;

	BEGIN

	IF fPalette <> NIL THEN
		DisposePalette (fPalette);

	INHERITED Free

	END;

{*****************************************************************************}

{$S APreferences}

PROCEDURE TSeparationDialog.StuffValues;

	VAR
		h: Handle;
		name: Str255;
		pick: INTEGER;
		item: INTEGER;
		theID: INTEGER;
		which: INTEGER;
		color: RGBColor;
		theType: ResType;

	BEGIN

	FOR which := 1 TO kProgressive DO
		fColorPercent [which] . StuffValue
			(fSetup.fProgressive [which] . percent);

	fGamma.StuffValue (fSetup.fGamma);

	fLastGamma := fSetup.fGamma;

	pick := 1;

	IF fSetup.fBlackID <> 0 THEN
		BEGIN

		SetResLoad (FALSE);

		FOR item := 3 TO CountMItems (gBlackMenu) DO
			BEGIN
			GetItem (gBlackMenu, item, name);
			h := Get1NamedResource ('GCR ', name);
			IF h <> NIL THEN
				GetResInfo (h, theID, theType, name);
			IF theID = fSetup.fBlackID THEN
				BEGIN
				pick := item;
				LEAVE
				END
			END;

		SetResLoad (TRUE)

		END;

	fBlackPopUp.SetMenu (gBlackMenu, pick);

	IF fSetup.fInkMaximum <> 0 THEN
		fInkMaximum.StuffValue (fSetup.fInkMaximum)
	ELSE
		fInkMaximum.StuffString ('');
		
	fUCAPercent.StuffValue (fSetup.fUCAPercent);

	SetEditSelection (fGamma.fItemNumber)

	END;

{*****************************************************************************}

{$S APreferences}

PROCEDURE TSeparationDialog.UpdatePalette;

	VAR
		r: Rect;
		which: INTEGER;
		color: RGBColor;

	BEGIN

	FOR which := 1 TO kProgressive DO
		BEGIN

		color := fSetup.fProgressive [which] . rgb;

		color.red	:= BAND (BSR (color.red  , 8), $FF);
		color.green := BAND (BSR (color.green, 8), $FF);
		color.blue	:= BAND (BSR (color.blue , 8), $FF);
		
		color.red   := (ORD4 (color.red  ) * 4096 + 127) DIV 255;
		color.green := (ORD4 (color.green) * 4096 + 127) DIV 255;
		color.blue  := (ORD4 (color.blue ) * 4096 + 127) DIV 255;

		color.red	:= $101 * Map12to8Bit (color.red  , fLastGamma);
		color.green := $101 * Map12to8Bit (color.green, fLastGamma);
		color.blue  := $101 * Map12to8Bit (color.blue , fLastGamma);

		fScreenColor [which] := color

		END;

	IF fPalette <> NIL THEN
		BEGIN

		FOR which := 1 TO kProgressive DO
			BEGIN
			color := fScreenColor [which];
			SetEntryColor (fPalette, 1 + which, color)
			END;

		ActivatePalette (fDialogPtr)

		END;

	SetPort (fDialogPtr);

	FOR which := 1 TO kProgressive DO
		BEGIN
		r := fColorRect [which];
		InvalRect (r)
		END

	END;

{*****************************************************************************}

{$S APreferences}

PROCEDURE TSeparationDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

	VAR
		r: Rect;
		rgn: RgnHandle;
		which: INTEGER;
		depth: INTEGER;
		color: RGBColor;
		monochrome: BOOLEAN;

	BEGIN

	INHERITED DrawAmendments (theItem);

	PenNormal;

	IF gConfiguration.hasColorToolBox THEN
		GetScreenInfo (GetMainDevice, depth, monochrome)
	ELSE
		depth := 1;

	rgn := NewRgn;

	FOR which := 1 TO kProgressive DO
		BEGIN

		r := fColorRect [which];

		FrameRect (r);

		InsetRect (r, 1, 1);
		RectRgn (rgn, r);

		color := fScreenColor [which];

		RgnFillRGB (rgn, color, depth)

		END;

	DisposeRgn (rgn)

	END;

{*****************************************************************************}

{$S APreferences}

FUNCTION TSeparationDialog.DoItemSelected
		(anItem: INTEGER;
		 VAR handledIt: BOOLEAN;
		 VAR doneWithDialog: BOOLEAN): TCommand; OVERRIDE;

	VAR
		r: Rect;
		h: Handle;
		where: Point;
		name: Str255;
		theID: INTEGER;
		which: INTEGER;
		prompt: Str255;
		color: RGBColor;
		theType: ResType;
		newGamma: INTEGER;
		maps: TLookUpTables;
		gcrTable: TLookUpTable;
		ucrTable: TLookUpTable;

	BEGIN

	DoItemSelected := INHERITED DoItemSelected (anItem,
												handledIt,
												doneWithDialog);

	IF anItem = fBlackPopUp.fItemNumber THEN
		CASE fBlackPopUp.fCmdPick OF

		cLoadBG:
			IF LoadMapFile (maps, FALSE) THEN
				BEGIN

				gcrTable := maps [0];

				SolveUCR (gcrTable, ucrTable);

				fSetup.fBlackID  := 0;
				fSetup.fGCRTable := gcrTable;
				fSetup.fUCRTable := ucrTable;

				fBlackPopUp.SetMenu (gBlackMenu, 1)

				END;

		cLoadUCR:
			IF LoadMapFile (maps, FALSE) THEN
				BEGIN

				fSetup.fBlackID  := 0;
				fSetup.fUCRTable := maps [0];

				fBlackPopUp.SetMenu (gBlackMenu, 1)

				END;

		cSaveBG:
			BEGIN

			maps [0] := fSetup.fGCRTable;

			maps [1] := gNullLUT;
			maps [2] := gNullLUT;
			maps [3] := gNullLUT;

			SaveMapFile (maps, strSaveBG)

			END;

		cSaveUCR:
			BEGIN

			maps [0] := fSetup.fUCRTable;

			maps [1] := gNullLUT;
			maps [2] := gNullLUT;
			maps [3] := gNullLUT;

			SaveMapFile (maps, strSaveUCR)

			END;

		OTHERWISE
			BEGIN

			GetItem (gBlackMenu, fBlackPopUp.fPick, name);

			h := Get1NamedResource ('GCR ', name);
			FailNil (h);

			GetResInfo (h, theID, theType, name);
			FailResError;

			GetBlackTables (gcrTable, ucrTable, theID);

			fSetup.fBlackID  := theID;
			fSetup.fGCRTable := gcrTable;
			fSetup.fUCRTable := ucrTable

			END

		END;

	IF anItem = fGamma.fItemNumber THEN
		IF fGamma.ParseValue THEN
			BEGIN
			newGamma := fGamma.fValue;
			IF newGamma <> fLastGamma THEN
				BEGIN
				fLastGamma := newGamma;
				UpdatePalette
				END
			END;

	which := anItem - fColorItems + 1;

	IF (which >= 1) AND (which <= kProgressive) THEN
		BEGIN

		where.h := 0;
		where.v := 0;

		color := fScreenColor [which];

		GetIndString (prompt, kStringsID, strSelectProgessive);

		IF GetColor (where, prompt, color, color) THEN
			BEGIN

			color.red	:= BAND (BSR (color.red  , 8), $FF);
			color.green := BAND (BSR (color.green, 8), $FF);
			color.blue	:= BAND (BSR (color.blue , 8), $FF);
			
			color.red   := Map8to12Bit (color.red  , fLastGamma);
			color.green := Map8to12Bit (color.green, fLastGamma);
			color.blue  := Map8to12Bit (color.blue , fLastGamma);

			color.red	:= (ORD4 (color.red  ) * 255 + 2048) DIV 4096;
			color.green := (ORD4 (color.green) * 255 + 2048) DIV 4096;
			color.blue 	:= (ORD4 (color.blue ) * 255 + 2048) DIV 4096;
			
			color.red   := $101 * color.red;
			color.green := $101 * color.green;
			color.blue  := $101 * color.blue;
			
			fSetup.fProgressive [which] . rgb := color;

			UpdatePalette

			END

		END

	END;

{*****************************************************************************}

{$S APreferences}

PROCEDURE TSeparationDialog.Validate (VAR succeeded: BOOLEAN); OVERRIDE;

	VAR
		which: INTEGER;

	BEGIN

	INHERITED Validate (succeeded);

	IF succeeded THEN
		BEGIN

		FOR which := 1 TO kProgressive DO
			fSetup.fProgressive [which] . percent :=
				  fColorPercent [which] . fValue;

		fSetup.fGamma	   := fGamma.fValue;
		fSetup.fInkMaximum := fInkMaximum.fValue;
		fSetup.fUCAPercent := fUCAPercent.fValue

		END

	END;

{*****************************************************************************}

{$S APreferences}

FUNCTION LoadSeparationSetup (VAR setup: TSeparationSetup): BOOLEAN;

	VAR
		j: INTEGER;
		err: OSErr;
		fi: FailInfo;
		where: Point;
		reply: SFReply;
		count: LONGINT;
		refNum: INTEGER;
		version: INTEGER;
		typeList: SFTypeList;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF refNum <> -1 THEN
			err := FSClose (refNum);
		IF error <> noErr THEN
			gApplication.ShowError (error, msgCannotLoadSSetup);
		EXIT (LoadSeparationSetup)
		END;

	BEGIN

	LoadSeparationSetup := FALSE;

	refNum := -1;

	CatchFailures (fi, CleanUp);

	WhereToPlaceDialog (getDlgID, where);

	typeList [0] := kSSetupFileType;

	SFGetFile (where, '', NIL, 1, typeList, NIL, reply);
	IF NOT reply.good THEN Failure (0, 0);

	FailOSErr (FSOpen (reply.fName, reply.vRefNum, refNum));

	count := SIZEOF (INTEGER);

	FailOSErr (FSRead (refNum, count, @version));

	IF version = kSSetupVersion1 THEN
		BEGIN
		setup.fUCAPercent := 0;
		count := SIZEOF (TSeparationSetup) - SIZEOF (INTEGER)
		END
		
	ELSE IF version = kSSetupVersion THEN
		count := SIZEOF (TSeparationSetup)
		
	ELSE
		Failure (errBadFileVersion, 0);

	FailOSErr (FSRead (refNum, count, @setup));

	FailOSErr (FSClose (refNum));

	Success (fi);

	LoadSeparationSetup := TRUE

	END;

{*****************************************************************************}

{$S APreferences}

PROCEDURE SaveSeparationSetup (setup: TSeparationSetup);

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
			gApplication.ShowError (error, msgCannotSaveSSetup);
		EXIT (SaveSeparationSetup)
		END;

	BEGIN

	refNum := -1;

	CatchFailures (fi, CleanUp);

	GetIndString (prompt, kStringsID, strSaveSSetupIn);

	refNum := CreateOutputFile (prompt, kSSetupFileType, reply);

	version := kSSetupVersion;
	count	:= SIZEOF (INTEGER);

	FailOSErr (FSWrite (refNum, count, @version));

	count := SIZEOF (TSeparationSetup);

	FailOSErr (FSWrite (refNum, count, @setup));

	FailOSErr (FSClose (refNum));
	refNum := -1;

	FailOSErr (FlushVol (NIL, reply.vRefNum));

	Success (fi)

	END;

{*****************************************************************************}

{$S APreferences}

PROCEDURE DoSeparationSetup (VAR setup: TSeparationSetup);

	CONST
		kLoadItem = 4;
		kSaveItem = 5;

	VAR
		fi: FailInfo;
		itemHit: INTEGER;
		succeeded: BOOLEAN;
		freeDialog: BOOLEAN;
		tempSetup: TSeparationSetup;
		aSeparationDialog: TSeparationDialog;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF freeDialog THEN aSeparationDialog.Free;
		EXIT (DoSeparationSetup)
		END;

	BEGIN

	freeDialog := FALSE;

	CatchFailures (fi, CleanUp);

	NEW (aSeparationDialog);
	FailNil (aSeparationDialog);

	aSeparationDialog.ISeparationDialog (setup);

	freeDialog := TRUE;

		REPEAT

		aSeparationDialog.TalkToUser (itemHit, StdItemHandling);

			CASE itemHit OF

			cancel:
				Failure (0, 0);

			kLoadItem:
				BEGIN

				tempSetup := aSeparationDialog.fSetup;

				IF LoadSeparationSetup (tempSetup) THEN
					BEGIN

					aSeparationDialog.fSetup := tempSetup;

					aSeparationDialog.StuffValues;
					aSeparationDialog.UpdatePalette

					END

				END;

			kSaveItem:
				BEGIN

				aSeparationDialog.Validate (succeeded);

				IF succeeded THEN
					BEGIN
					tempSetup := aSeparationDialog.fSetup;
					SaveSeparationSetup (tempSetup)
					END

				END

			END

		UNTIL itemHit = ok;

	setup := aSeparationDialog.fSetup;

	Success (fi);

	aSeparationDialog.Free;

	BuildInkTransform (setup);

	IF setup.fInkMaximum = 0 THEN
		setup.fInkMaximum := SolveMaxInk

	END;

{*****************************************************************************}

{$S ASeparation}

PROCEDURE SeparateColorLUT (LUT: TRGBLookUpTable;
							VAR map1: TLookUpTable;
							VAR map2: TLookUpTable;
							VAR map3: TLookUpTable;
							VAR map4: TLookUpTable);

	VAR
		c: INTEGER;
		m: INTEGER;
		y: INTEGER;
		k: INTEGER;
		index: INTEGER;
		inside: BOOLEAN;

	BEGIN

	FOR index := 0 TO 255 DO
		BEGIN

		MoveHands (FALSE);

		SolveForCMYK (ORD (LUT.R [index]),
					  ORD (LUT.G [index]),
					  ORD (LUT.B [index]),
					  c, m, y, k, inside);

		map1 [index] := CHR (c);
		map2 [index] := CHR (m);
		map3 [index] := CHR (y);
		map4 [index] := CHR (k)

		END

	END;

{*****************************************************************************}

{$S ASeparation}

FUNCTION BuildCMYKTable: Handle;

	VAR
		cPtr: Ptr;
		mPtr: Ptr;
		yPtr: Ptr;
		kPtr: Ptr;
		h: INTEGER;
		v: INTEGER;
		s: INTEGER;
		r: INTEGER;
		g: INTEGER;
		b: INTEGER;
		c: INTEGER;
		m: INTEGER;
		y: INTEGER;
		k: INTEGER;
		fi: FailInfo;
		table: Handle;
		inside: BOOLEAN;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (table)
		END;

	BEGIN
	
	table := NewLargeHandle ($18800);

	CatchFailures (fi, CleanUp);

	HLock (table);

	cPtr := table^;
	mPtr := Ptr (ORD4 (cPtr) + $6200);
	yPtr := Ptr (ORD4 (mPtr) + $6200);
	kPtr := Ptr (ORD4 (yPtr) + $6200);
	
	FOR h := 0 TO 48 DO
		FOR v := 0 TO 31 DO
			BEGIN

			MoveHands (TRUE);

			UpdateProgress (h * 32 + v, 1568);

			FOR s := 0 TO 15 DO
				BEGIN
				
				CvtHVStoRGB (h, v, s, r, g, b);
				
				SolveForCMYK (r, g, b, c, m, y, k, inside);

				{$PUSH}
				{$R-}

				cPtr^ := c;
				cPtr  := Ptr (ORD4 (cPtr) + 1);

				mPtr^ := m;
				mPtr  := Ptr (ORD4 (mPtr) + 1);

				yPtr^ := y;
				yPtr  := Ptr (ORD4 (yPtr) + 1);

				kPtr^ := k;
				kPtr  := Ptr (ORD4 (kPtr) + 1)

				{$POP}

				END

			END;

	UpdateProgress (1, 1);

	HUnlock (table);

	Success (fi);

	BuildCMYKTable := table

	END;

{*****************************************************************************}

{$S ASeparation}

PROCEDURE BuildSeparationTable;

	CONST
		kVersion = 1;
		kFileType = '8BST';
		
	VAR
		err: OSErr;
		fi: FailInfo;
		name: Str255;
		title: Str255;
		table: Handle;
		ignore: OSErr;
		count: LONGINT;
		refNum: INTEGER;
		version: INTEGER;
		setup: TSeparationSetup;
		
	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FinishProgress;
		FreeLargeHandle (table);
		FailNewMessage (error, message, msgBuildSepTable)
		END;

	BEGIN
	
	GetIndString (name, kStringsID, strSepTableName);
	
	err := FSOpen (name, gPouchRefNum, refNum);
	
	IF err = noErr THEN
		BEGIN
		
		count := SIZEOF (INTEGER);
		err := FSRead (refNum, count, @version);
		
		IF (err = noErr) & (version = kVersion) THEN
			BEGIN
			
			count := SIZEOF (TSeparationSetup);
			err := FSRead (refNum, count, @setup);
			
			IF (err = noErr) & EqualBytes (@setup,
										   @gPreferences.fSeparation,
										   count) THEN
				BEGIN
				err := FSClose (refNum);
				EXIT (BuildSeparationTable)
				END
				
			END;
			
		err := FSClose (refNum)
		
		END;
		
	table := NIL;
	
	GetIndString (title, kStringsID, strBuildingTable);

	StartProgress (title);
	
	CatchFailures (fi, CleanUp);
	
	table := BuildCMYKTable;
	
	VMCompress (TRUE);
		
	err := Create (name, gPouchRefNum, kSignature, kFileType);
	
	IF err = dupFNErr THEN
		BEGIN
		FailOSErr (DeleteFile (@name, gPouchRefNum));
		err := Create (name, gPouchRefNum, kSignature, kFileType)
		END;
		
	FailOSErr (err);
	
	FailOSErr (FSOpen (name, gPouchRefNum, refNum));
	
	count := SIZEOF (INTEGER);
	version := kVersion;
	err := FSWrite (refNum, count, @version);
	
	IF err = noErr THEN
		BEGIN
		count := SIZEOF (TSeparationSetup);
		err := FSWrite (refNum, count, @gPreferences.fSeparation)
		END;
		
	IF err = noErr THEN
		BEGIN
		count := GetHandleSize (table);
		err := FSWrite (refNum, count, table^)
		END;
		
	IF err <> noErr THEN
		BEGIN
		ignore := FSClose (refNum);
		ignore := DeleteFile (@name, gPouchRefNum);
		Failure (err, 0)
		END;
		
	err := FSClose (refNum);

	IF err = noErr THEN
		err := FlushVol (NIL, gPouchRefNum);
		
	IF err <> noErr THEN
		BEGIN
		ignore := DeleteFile (@name, gPouchRefNum);
		Failure (err, 0)
		END;
		
	Success (fi);
	
	FreeLargeHandle (table);
	
	FinishProgress
	
	END;
	
{*****************************************************************************}

{$S ASeparation}

FUNCTION LoadSeparationTable: Handle;

	VAR
		err: OSErr;
		fi: FailInfo;
		name: Str255;
		table: Handle;
		ignore: OSErr;
		count: LONGINT;
		refNum: INTEGER;
		
	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (table)
		END;

	BEGIN
	
	GetIndString (name, kStringsID, strSepTableName);
	
	table := NewLargeHandle ($18800);
	
	CatchFailures (fi, CleanUp);
	
	FailOSErr (FSOpen (name, gPouchRefNum, refNum));
	
	err := SetFPos (refNum, fsFromStart, SIZEOF (INTEGER) +
										 SIZEOF (TSeparationSetup));
										 
	IF err = noErr THEN
		BEGIN
		count := GetHandleSize (table);
		err := FSRead (refNum, count, table^)
		END;
		
	ignore := FSClose (refNum);
	
	FailOSErr (err);
	
	Success (fi);
	
	LoadSeparationTable := table
			
	END;

{*****************************************************************************}

{$S ASeparation}

PROCEDURE ConvertRGB2CMYK (srcArray1: TVMArray;
						   srcArray2: TVMArray;
						   srcArray3: TVMArray;
						   dstArray1: TVMArray;
						   dstArray2: TVMArray;
						   dstArray3: TVMArray;
						   dstArray4: TVMArray);

	VAR
		fi: FailInfo;
		row: INTEGER;
		srcPtr1: Ptr;
		srcPtr2: Ptr;
		srcPtr3: Ptr;
		dstPtr1: Ptr;
		dstPtr2: Ptr;
		dstPtr3: Ptr;
		dstPtr4: Ptr;
		count: INTEGER;
		table1: Handle;
		table2: Handle;
		
	PROCEDURE MakeNilPtrs;

		BEGIN

		srcPtr1 := NIL;
		srcPtr2 := NIL;
		srcPtr3 := NIL;

		dstPtr1 := NIL;
		dstPtr2 := NIL;
		dstPtr3 := NIL;
		dstPtr4 := NIL

		END;

	PROCEDURE DoneWithPtrs;

		BEGIN

		IF srcPtr1 <> NIL THEN srcArray1.DoneWithPtr;
		IF srcPtr2 <> NIL THEN srcArray2.DoneWithPtr;
		IF srcPtr3 <> NIL THEN srcArray3.DoneWithPtr;

		IF dstPtr1 <> NIL THEN dstArray1.DoneWithPtr;
		IF dstPtr2 <> NIL THEN dstArray2.DoneWithPtr;
		IF dstPtr3 <> NIL THEN dstArray3.DoneWithPtr;
		IF dstPtr4 <> NIL THEN dstArray4.DoneWithPtr

		END;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		FreeLargeHandle (table1);
		FreeLargeHandle (table2);

		DoneWithPtrs;

		srcArray1.Flush;
		srcArray2.Flush;
		srcArray3.Flush;

		dstArray1.Flush;
		dstArray2.Flush;
		dstArray3.Flush;
		dstArray4.Flush

		END;

	BEGIN
	
	MakeNilPtrs;
	
	table1 := NIL;
	table2 := NIL;
	
	CatchFailures (fi, CleanUp);
	
	table1 := LoadSeparationTable;
	
	table2 := NewLargeHandle (32 * 512);
	
	BuildFMTable2 (table2);
	
	count := srcArray1.fLogicalSize;

	FOR row := 0 TO srcArray1.fBlockCount - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row, srcArray1.fBlockCount);

		dstPtr1 := dstArray1 . NeedPtr (row, row, TRUE);
		dstPtr2 := dstArray2 . NeedPtr (row, row, TRUE);
		dstPtr3 := dstArray3 . NeedPtr (row, row, TRUE);
		dstPtr4 := dstArray4 . NeedPtr (row, row, TRUE);

		srcPtr1 := srcArray1 . NeedPtr (row, row, FALSE);
		srcPtr2 := srcArray2 . NeedPtr (row, row, FALSE);
		srcPtr3 := srcArray3 . NeedPtr (row, row, FALSE);

		IF srcPtr1 <> dstPtr1 THEN BlockMove (srcPtr1, dstPtr1, count);
		IF srcPtr2 <> dstPtr2 THEN BlockMove (srcPtr2, dstPtr2, count);
		IF srcPtr3 <> dstPtr3 THEN BlockMove (srcPtr3, dstPtr3, count);
				
		DoSeparateColors (dstPtr1,
						  dstPtr2,
						  dstPtr3,
						  dstPtr4,
						  table1,
						  table2,
						  count);
						  
		DoneWithPtrs;

		MakeNilPtrs

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ASeparation}

FUNCTION BuildCMYTable: Handle;

	VAR
		cPtr: Ptr;
		mPtr: Ptr;
		yPtr: Ptr;
		r: INTEGER;
		g: INTEGER;
		b: INTEGER;
		c: INTEGER;
		m: INTEGER;
		y: INTEGER;
		fi: FailInfo;
		table: Handle;
		inside: BOOLEAN;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (table)
		END;

	BEGIN
	
	table := NewLargeHandle ($3000);

	CatchFailures (fi, CleanUp);

	HLock (table);

	cPtr := table^;
	mPtr := Ptr (ORD4 (cPtr) + $1000);
	yPtr := Ptr (ORD4 (mPtr) + $1000);
	
	FOR r := 0 TO 15 DO
		FOR g := 0 TO 15 DO
			BEGIN

			MoveHands (TRUE);

			UpdateProgress (r * 16 + g, 256);

			FOR b := 0 TO 15 DO
				BEGIN
				
				SolveForCMY (r, g, b, c, m, y);

				{$PUSH}
				{$R-}

				cPtr^ := c;
				cPtr  := Ptr (ORD4 (cPtr) + 1);

				mPtr^ := m;
				mPtr  := Ptr (ORD4 (mPtr) + 1);

				yPtr^ := y;
				yPtr  := Ptr (ORD4 (yPtr) + 1)

				{$POP}

				END

			END;

	UpdateProgress (1, 1);

	HUnlock (table);

	Success (fi);

	BuildCMYTable := table

	END;

{*****************************************************************************}

{$S ASeparation}

PROCEDURE ConvertRGB2CMY (srcArray1: TVMArray;
						  srcArray2: TVMArray;
						  srcArray3: TVMArray;
						  dstArray1: TVMArray;
						  dstArray2: TVMArray;
						  dstArray3: TVMArray);

	CONST
		kTablePixels = 150000;

	VAR
		fi: FailInfo;
		row: INTEGER;
		srcPtr1: Ptr;
		srcPtr2: Ptr;
		srcPtr3: Ptr;
		dstPtr1: Ptr;
		dstPtr2: Ptr;
		dstPtr3: Ptr;
		count: INTEGER;
		table1: Handle;
		table2: Handle;
		pixels: LONGINT;

	PROCEDURE MakeNilPtrs;

		BEGIN

		srcPtr1 := NIL;
		srcPtr2 := NIL;
		srcPtr3 := NIL;

		dstPtr1 := NIL;
		dstPtr2 := NIL;
		dstPtr3 := NIL

		END;

	PROCEDURE DoneWithPtrs;

		BEGIN

		IF srcPtr1 <> NIL THEN srcArray1.DoneWithPtr;
		IF srcPtr2 <> NIL THEN srcArray2.DoneWithPtr;
		IF srcPtr3 <> NIL THEN srcArray3.DoneWithPtr;

		IF dstPtr1 <> NIL THEN dstArray1.DoneWithPtr;
		IF dstPtr2 <> NIL THEN dstArray2.DoneWithPtr;
		IF dstPtr3 <> NIL THEN dstArray3.DoneWithPtr

		END;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		FreeLargeHandle (table1);
		FreeLargeHandle (table2);

		DoneWithPtrs;

		srcArray1.Flush;
		srcArray2.Flush;
		srcArray3.Flush;

		dstArray1.Flush;
		dstArray2.Flush;
		dstArray3.Flush

		END;

	BEGIN
	
	MakeNilPtrs;

	table1 := NIL;
	table2 := NIL;

	CatchFailures (fi, CleanUp);

	count := srcArray1.fLogicalSize;

	pixels := srcArray1.fBlockCount * ORD4 (count);

	StartTask (kTablePixels / (kTablePixels + pixels));

	table1 := BuildCMYTable;

	FinishTask;
	
	table2 := NewLargeHandle (18 * 512);
	
	BuildFMTable1 (table2);

	FOR row := 0 TO srcArray1.fBlockCount - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row, srcArray1.fBlockCount);

		dstPtr1 := dstArray1 . NeedPtr (row, row, TRUE);
		dstPtr2 := dstArray2 . NeedPtr (row, row, TRUE);
		dstPtr3 := dstArray3 . NeedPtr (row, row, TRUE);

		srcPtr1 := srcArray1 . NeedPtr (row, row, FALSE);
		srcPtr2 := srcArray2 . NeedPtr (row, row, FALSE);
		srcPtr3 := srcArray3 . NeedPtr (row, row, FALSE);

		IF srcPtr1 <> dstPtr1 THEN BlockMove (srcPtr1, dstPtr1, count);
		IF srcPtr2 <> dstPtr2 THEN BlockMove (srcPtr2, dstPtr2, count);
		IF srcPtr3 <> dstPtr3 THEN BlockMove (srcPtr3, dstPtr3, count);

		DoColorCorrect (dstPtr1,
						dstPtr2,
						dstPtr3,
						table1,
						table2,
						count);

		DoneWithPtrs;

		MakeNilPtrs

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ASeparation}

FUNCTION BuildRGBTable: Handle;

	VAR
		rPtr: Ptr;
		gPtr: Ptr;
		bPtr: Ptr;
		c: INTEGER;
		m: INTEGER;
		y: INTEGER;
		r: INTEGER;
		g: INTEGER;
		b: INTEGER;
		table: Handle;

	BEGIN

	table := NewLargeHandle ($3000);

	HLock (table);

	rPtr := table^;
	gPtr := Ptr (ORD4 (table^) + $1000);
	bPtr := Ptr (ORD4 (table^) + $2000);

	FOR c := 0 TO 15 DO
		FOR m := 0 TO 15 DO
			BEGIN

			MoveHands (FALSE);

			UpdateProgress (c * 16 + m, 256);

			FOR y := 0 TO 15 DO
				BEGIN
				
				SolveForRGB (c * 17, m * 17, y * 17, 255, r, g, b);

				{$PUSH}
				{$R-}

				rPtr^ := r;
				rPtr  := Ptr (ORD4 (rPtr) + 1);

				gPtr^ := g;
				gPtr  := Ptr (ORD4 (gPtr) + 1);

				bPtr^ := b;
				bPtr  := Ptr (ORD4 (bPtr) + 1)

				{$POP}

				END

			END;

	UpdateProgress (1, 1);

	HUnlock (table);

	BuildRGBTable := table

	END;

{*****************************************************************************}

{$S ASeparation}

PROCEDURE ConvertCMYK2RGB (srcArray1: TVMArray;
						   srcArray2: TVMArray;
						   srcArray3: TVMArray;
						   srcArray4: TVMArray;
						   dstArray1: TVMArray;
						   dstArray2: TVMArray;
						   dstArray3: TVMArray);

	CONST
		kTablePixels = 15000;

	VAR
		fi: FailInfo;
		row: INTEGER;
		srcPtr1: Ptr;
		srcPtr2: Ptr;
		srcPtr3: Ptr;
		srcPtr4: Ptr;
		dstPtr1: Ptr;
		dstPtr2: Ptr;
		dstPtr3: Ptr;
		count: INTEGER;
		table1: Handle;
		table2: Handle;
		pixels: LONGINT;

	PROCEDURE MakeNilPtrs;

		BEGIN

		srcPtr1 := NIL;
		srcPtr2 := NIL;
		srcPtr3 := NIL;
		srcPtr4 := NIL;

		dstPtr1 := NIL;
		dstPtr2 := NIL;
		dstPtr3 := NIL

		END;

	PROCEDURE DoneWithPtrs;

		BEGIN

		IF srcPtr1 <> NIL THEN srcArray1.DoneWithPtr;
		IF srcPtr2 <> NIL THEN srcArray2.DoneWithPtr;
		IF srcPtr3 <> NIL THEN srcArray3.DoneWithPtr;
		IF srcPtr4 <> NIL THEN srcArray4.DoneWithPtr;

		IF dstPtr1 <> NIL THEN dstArray1.DoneWithPtr;
		IF dstPtr2 <> NIL THEN dstArray2.DoneWithPtr;
		IF dstPtr3 <> NIL THEN dstArray3.DoneWithPtr

		END;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		FreeLargeHandle (table1);
		FreeLargeHandle (table2);

		DoneWithPtrs;

		srcArray1.Flush;
		srcArray2.Flush;
		srcArray3.Flush;
		srcArray4.Flush;

		dstArray1.Flush;
		dstArray2.Flush;
		dstArray3.Flush

		END;

	BEGIN
	
	MakeNilPtrs;

	table1 := NIL;
	table2 := NIL;

	CatchFailures (fi, CleanUp);

	count := srcArray1.fLogicalSize;

	pixels := srcArray1.fBlockCount * ORD4 (count);

	StartTask (kTablePixels / (kTablePixels + pixels));

	table1 := BuildRGBTable;

	FinishTask;
	
	table2 := NewLargeHandle (18 * 512);
	
	BuildFMTable1 (table2);

	FOR row := 0 TO srcArray1.fBlockCount - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row, srcArray1.fBlockCount);

		dstPtr1 := dstArray1 . NeedPtr (row, row, TRUE);
		dstPtr2 := dstArray2 . NeedPtr (row, row, TRUE);
		dstPtr3 := dstArray3 . NeedPtr (row, row, TRUE);

		srcPtr1 := srcArray1 . NeedPtr (row, row, FALSE);
		srcPtr2 := srcArray2 . NeedPtr (row, row, FALSE);
		srcPtr3 := srcArray3 . NeedPtr (row, row, FALSE);
		srcPtr4 := srcArray4 . NeedPtr (row, row, FALSE);

		IF srcPtr1 <> dstPtr1 THEN BlockMove (srcPtr1, dstPtr1, count);
		IF srcPtr2 <> dstPtr2 THEN BlockMove (srcPtr2, dstPtr2, count);
		IF srcPtr3 <> dstPtr3 THEN BlockMove (srcPtr3, dstPtr3, count);

		DoColorCorrect (dstPtr1,
						dstPtr2,
						dstPtr3,
						table1,
						table2,
						count);

		DoReplaceBlack (dstPtr1,
						dstPtr2,
						dstPtr3,
						srcPtr4,
						@gGammaTable1,
						@gGammaTable2,
						count);

		DoneWithPtrs;

		MakeNilPtrs

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ASeparation}

PROCEDURE ConvertCMYK2Gray (srcArray1: TVMArray;
							srcArray2: TVMArray;
							srcArray3: TVMArray;
							srcArray4: TVMArray;
							dstArray: TVMArray);

	VAR
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		srcPtr1: Ptr;
		srcPtr2: Ptr;
		srcPtr3: Ptr;
		srcPtr4: Ptr;

	PROCEDURE MakeNilPtrs;

		BEGIN

		srcPtr1 := NIL;
		srcPtr2 := NIL;
		srcPtr3 := NIL;
		srcPtr4 := NIL;

		dstPtr := NIL

		END;

	PROCEDURE DoneWithPtrs;

		BEGIN

		IF srcPtr1 <> NIL THEN srcArray1.DoneWithPtr;
		IF srcPtr2 <> NIL THEN srcArray2.DoneWithPtr;
		IF srcPtr3 <> NIL THEN srcArray3.DoneWithPtr;
		IF srcPtr4 <> NIL THEN srcArray4.DoneWithPtr;

		IF dstPtr <> NIL THEN dstArray.DoneWithPtr

		END;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		BEGIN

		DoneWithPtrs;

		srcArray1.Flush;
		srcArray2.Flush;
		srcArray3.Flush;
		srcArray4.Flush;

		dstArray.Flush

		END;

	BEGIN

	MakeNilPtrs;

	CatchFailures (fi, CleanUp);

	FOR row := 0 TO srcArray1.fBlockCount - 1 DO
		BEGIN

		MoveHands (TRUE);

		UpdateProgress (row, srcArray1.fBlockCount);

		dstPtr := dstArray . NeedPtr (row, row, TRUE);

		srcPtr1 := srcArray1 . NeedPtr (row, row, FALSE);
		srcPtr2 := srcArray2 . NeedPtr (row, row, FALSE);
		srcPtr3 := srcArray3 . NeedPtr (row, row, FALSE);
		srcPtr4 := srcArray4 . NeedPtr (row, row, FALSE);

		DoCMYK2Gray (srcPtr1,
					 srcPtr2,
					 srcPtr3,
					 srcPtr4,
					 dstPtr,
					 gGrayLUT,
					 srcArray1.fLogicalSize);

		DoneWithPtrs;

		MakeNilPtrs

		END;

	UpdateProgress (1, 1);

	Success (fi);

	CleanUp (0, 0)

	END;

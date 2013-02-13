{Photoshop version 1.0.1, file: Tables.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROGRAM Tables;

USES
	MemTypes, QuickDraw, PickerIntf;

TYPE

	TLookUpTable = PACKED ARRAY [0..255] OF CHAR;

	TRGBLookUpTable = RECORD R, G, B: TLookUpTable END;

{*****************************************************************************}

PROCEDURE WritePLUT (table: TRGBLookUpTable; id: INTEGER; name: Str255);

	VAR
		row: INTEGER;
		col: INTEGER;
		gray: INTEGER;
		color: INTEGER;

	BEGIN

	WRITELN;
	WRITELN ('resource ''PLUT'' (', id:1, ', "', name, '", purgeable)');
	WRITELN ('    {');
	WRITELN ('        {');

	FOR color := 0 TO 2 DO
		FOR row := 0 TO 15 DO
			BEGIN
			WRITE ('        ');

			FOR col := 0 TO 15 DO
				BEGIN

					CASE color OF
					0:	gray := ORD (table.R [row * 16 + col]);
					1:	gray := ORD (table.G [row * 16 + col]);
					2:	gray := ORD (table.B [row * 16 + col])
					END;

				WRITE (gray:3);

				IF (row <> 15) OR (col <> 15) OR (color <> 2) THEN
					WRITE (';')

				END;

			WRITELN
			END;

	WRITELN ('        }');
	WRITELN ('    };')

	END;

{*****************************************************************************}

PROCEDURE MakeBlackBody (VAR table: TRGBLookUpTable);

	VAR
		gray: INTEGER;

	BEGIN

	FOR gray := 0 TO 255 DO
		CASE gray OF

		0..85:
			BEGIN
			table.R [gray] := CHR (3 * gray);
			table.G [gray] := CHR (0);
			table.B [gray] := CHR (0)
			END;

		86..170:
			BEGIN
			table.R [gray] := CHR (255);
			table.G [gray] := CHR (3 * (gray - 85));
			table.B [gray] := CHR (0)
			END;

		171..255:
			BEGIN
			table.R [gray] := CHR (255);
			table.G [gray] := CHR (255);
			table.B [gray] := CHR (3 * (gray - 170))
			END

		END

	END;

{*****************************************************************************}

PROCEDURE MakeMonochrome (VAR table: TRGBLookUpTable);

	VAR
		gray: INTEGER;

	BEGIN

	FOR gray := 0 TO 255 DO
		BEGIN
		table.R [gray] := CHR (gray);
		table.G [gray] := CHR (gray);
		table.B [gray] := CHR (gray)
		END

	END;

{*****************************************************************************}

PROCEDURE MakeSpectrum (VAR table: TRGBLookUpTable);

	VAR
		gray: INTEGER;
		rColor: RGBColor;
		hColor: HSVColor;

	BEGIN

	FOR gray := 0 TO 255 DO
		BEGIN

		hColor.hue := ORD4 (255 - gray) * 54613 DIV 255;
		hColor.saturation := $FFFF;
		hColor.value := $FFFF;

		HSV2RGB (hColor, rColor);

		table.R [gray] := CHR (BAND (BSR (rColor.red  , 8), $FF));
		table.G [gray] := CHR (BAND (BSR (rColor.green, 8), $FF));
		table.B [gray] := CHR (BAND (BSR (rColor.blue , 8), $FF))

		END

	END;

{*****************************************************************************}

PROCEDURE MakeSystem (VAR table: TRGBLookUpTable);

	VAR
		x: INTEGER;
		gray: INTEGER;
		band: INTEGER;
		slot: INTEGER;
		r, g, b: INTEGER;

	BEGIN

	gray := 0;

	FOR r := 5 DOWNTO 0 DO
		FOR g := 5 DOWNTO 0 DO
			FOR b := 5 DOWNTO 0 DO
				IF gray <> 215 THEN
					BEGIN
					table.R [gray] := CHR (r * $33);
					table.G [gray] := CHR (g * $33);
					table.B [gray] := CHR (b * $33);
					gray := gray + 1
					END;

	FOR band := 1 TO 4 DO
		FOR slot := 1 TO 10 DO
			BEGIN
			r := ORD ((band = 1) OR (band = 4));
			g := ORD ((band = 2) OR (band = 4));
			b := ORD ((band = 3) OR (band = 4));
				CASE slot OF
				1:	x := $EE;
				2:	x := $DD;
				3:	x := $BB;
				4:	x := $AA;
				5:	x := $88;
				6:	x := $77;
				7:	x := $55;
				8:	x := $44;
				9:	x := $22;
				10: x := $11
				END;
			table.R [gray] := CHR (r * x);
			table.G [gray] := CHR (g * x);
			table.B [gray] := CHR (b * x);
			gray := gray + 1
			END;

	table.R [255] := CHR (0);
	table.G [255] := CHR (0);
	table.B [255] := CHR (0)

	END;

{*****************************************************************************}

VAR
	table: TRGBLookUpTable;

BEGIN

WRITELN ('type ''PLUT'''		  );
WRITELN ('    {'				  );
WRITELN ('    wide array [768]'   );
WRITELN ('        {'			  );
WRITELN ('        unsigned byte;' );
WRITELN ('        };'			  );
WRITELN ('    };'				  );

MakeSystem (table);
WritePLUT (table, 1000, '.System');

MakeBlackBody (table);
WritePLUT (table, 1001, 'Blackbody');

MakeMonochrome (table);
WritePLUT (table, 1002, 'Gray Scale');

MakeSpectrum (table);
WritePLUT (table, 1003, 'Spectrum')

END.

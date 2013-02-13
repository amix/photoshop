{Photoshop version 1.0.1, file: Tips.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROGRAM Tips;

VAR
	rows: INTEGER;
	cols: INTEGER;
	data: ARRAY [0..18, 0..18] OF INTEGER;

{*****************************************************************************}

PROCEDURE WriteTip (id: INTEGER);

	VAR
		r, c: INTEGER;

	BEGIN

	WRITELN;
	WRITELN ('resource ''TIP '' (', id:1, ', purgeable)');
	WRITELN ('    {');
	WRITELN ('    {', rows		:2, ', ', cols		:2, '},');
	WRITELN ('    {', rows DIV 2:2, ', ', cols DIV 2:2, '},');
	WRITELN ('        {');

	FOR r := 0 TO rows - 1 DO
		BEGIN
		WRITE ('        ');

		FOR c := 0 TO cols - 1 DO
			BEGIN
			WRITE (data [r, c]:3);
			IF (r <> rows - 1) OR (c <> cols - 1) THEN
				WRITE (';');
			END;

		WRITELN
		END;

	WRITELN ('        }');
	WRITELN ('    };')

	END;

{*****************************************************************************}

FUNCTION GaussianWeight (r, c: INTEGER): INTEGER;

	VAR
		sigma: EXTENDED;
		radius: EXTENDED;

	BEGIN

	IF rows > cols THEN
		sigma := rows * 0.5
	ELSE
		sigma := cols * 0.5;

	radius := SQRT (SQR (r - rows DIV 2) + SQR (c - cols DIV 2));

	IF radius > sigma THEN
		GaussianWeight := 0
	ELSE
		GaussianWeight := ROUND (255.0 * EXP (-SQR (radius / sigma * 2.0)))

	END;

{*****************************************************************************}

PROCEDURE GaussianTip (id, rr, cc: INTEGER);

	VAR
		r, c: INTEGER;

	BEGIN

	rows := rr;
	cols := cc;

	FOR r := 0 TO rows - 1 DO
		FOR c := 0 TO cols - 1 DO
			data [r, c] := GaussianWeight (r, c);

	WriteTip (id)

	END;

{*****************************************************************************}

FUNCTION SquareWeight (r, c: INTEGER): INTEGER;

	VAR
		dr: INTEGER;
		dc: INTEGER;
		radius: LONGINT;

	BEGIN

	dr := ABS (r - rows DIV 2);
	dc := ABS (c - cols DIV 2);

	IF dr < dc THEN
		radius := dc
	ELSE
		radius := dr;

	SquareWeight := ROUND (255 * (1.0 - radius / ((cols + 1) DIV 2)))

	END;

{*****************************************************************************}

PROCEDURE SquareTip (id, rr, cc: INTEGER);

	VAR
		r, c: INTEGER;

	BEGIN

	rows := rr;
	cols := cc;

	FOR r := 0 TO rows - 1 DO
		FOR c := 0 TO cols - 1 DO
			data [r, c] := SquareWeight (r, c);

	WriteTip (id)

	END;

{*****************************************************************************}

BEGIN

WRITELN ('type ''TIP '''		  );
WRITELN ('    {'				  );
WRITELN ('    point;'			  );
WRITELN ('    point;'			  );
WRITELN ('    wide array'		  );
WRITELN ('        {'			  );
WRITELN ('        unsigned byte;' );
WRITELN ('        };'			  );
WRITELN ('    };'				  );

GaussianTip ( 1,  1,  1);
GaussianTip ( 2,  3,  3);
GaussianTip ( 3,  5,  5);
GaussianTip ( 4,  7,  7);
GaussianTip ( 5,  9,  9);
GaussianTip ( 6, 11, 11);
GaussianTip ( 7, 13, 13);
GaussianTip ( 8, 15, 15);
GaussianTip ( 9, 17, 17);
GaussianTip (10, 19, 19);

SquareTip (11,	7,	7);
SquareTip (12,	9,	9);
SquareTip (13, 11, 11);
SquareTip (14, 13, 13);

GaussianTip (15,  3, 1);
GaussianTip (16,  5, 1);
GaussianTip (17,  7, 1);
GaussianTip (18,  9, 1);
GaussianTip (19, 11, 1);

GaussianTip (20, 1,  3);
GaussianTip (21, 1,  5);
GaussianTip (22, 1,  7);
GaussianTip (23, 1,  9);
GaussianTip (24, 1, 11)

END.

{Photoshop version 1.0.1, file: Huffman.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

PROGRAM Huffman;

TYPE
	PNode = ^TNode;
	TNode = RECORD
		leaf: BOOLEAN;
		code: INTEGER;
		entry: INTEGER;
		branch: ARRAY [0..1] OF PNode
		END;

	Str255 = STRING [255];

VAR
	id: INTEGER;
	root: PNode;
	word: Str255;
	code: INTEGER;
	entry: INTEGER;

PROCEDURE AddCode (node: PNode; code: INTEGER; VAR word: Str255);

	VAR
		branch: INTEGER;

	BEGIN

	IF LENGTH (word) = 0 THEN
		BEGIN

		IF node^.leaf OR (node^.branch [0] <> NIL) OR
						 (node^.branch [1] <> NIL) THEN
			BEGIN
			WRITELN ('? Conflict for code ', code:1);
			EXIT (PROGRAM)
			END;

		node^.leaf := TRUE;
		node^.code := code

		END

	ELSE
		BEGIN

		IF word [1] = '0' THEN
			branch := 0
		ELSE IF word [1] = '1' THEN
			branch := 1
		ELSE
			BEGIN
			WRITELN ('? Invalid word for code ', code:1);
			EXIT (PROGRAM)
			END;

		DELETE (word, 1, 1);

		IF node^.branch [branch] = NIL THEN
			BEGIN

			NEW (node^.branch [branch]);

			node^.branch [branch]^.leaf := FALSE;
			node^.branch [branch]^.branch [0] := NIL;
			node^.branch [branch]^.branch [1] := NIL

			END;

		AddCode (node^.branch [branch], code, word)

		END

	END;

PROCEDURE NumberNode (node: PNode);
	BEGIN

	node^.entry := entry;

	entry := entry + 1;

	IF node^.branch [0] <> NIL THEN NumberNode (node^.branch [0]);
	IF node^.branch [1] <> NIL THEN NumberNode (node^.branch [1])

	END;

PROCEDURE WriteHexDigit (x: INTEGER);
	BEGIN
	IF x <= 9 THEN
		WRITE (x:1)
	ELSE
		WRITE (CHR (ORD ('A') + x - 10))
	END;

PROCEDURE WriteHex (x: INTEGER);
	BEGIN
	WriteHexDigit (BAND (BSR (x, 12), $F));
	WriteHexDigit (BAND (BSR (x, 8), $F));
	WriteHexDigit (BAND (BSR (x, 4), $F));
	WriteHexDigit (BAND (x, $F))
	END;

PROCEDURE WriteNode (node: PNode);
	BEGIN

	WRITE ('    $"');

	IF node^.leaf THEN
		WriteHex (node^.code)
	ELSE
		WriteHex (-1);

	WRITE (' ');

	IF node^.branch [0] <> NIL THEN
		WriteHex (node^.branch [0]^.entry)
	ELSE
		WriteHex (-1);

	WRITE (' ');

	IF node^.branch [1] <> NIL THEN
		WriteHex (node^.branch [1]^.entry)
	ELSE
		WriteHex (-1);

	WRITELN ('"');

	IF node^.branch [0] <> NIL THEN WriteNode (node^.branch [0]);
	IF node^.branch [1] <> NIL THEN WriteNode (node^.branch [1])

	END;

BEGIN

NEW (root);

root^.leaf := FALSE;
root^.branch [0] := NIL;
root^.branch [1] := NIL;

READLN (id);

WHILE NOT EOF DO
	BEGIN

	READ (code);
	READLN (word);

	WHILE (word [1] = ' ') OR
		  (word [1] = CHR (9)) DO
		DELETE (word, 1, 1);

	WHILE (word [LENGTH (word)] = ' ') OR
		  (word [LENGTH (word)] = CHR (9)) DO
		DELETE (word, LENGTH (word), 1);

	AddCode (root, code, word)

	END;

entry := 0;

NumberNode (root);

WRITELN ('data ''HUFF'' (', id:1, ', purgeable)');
WRITELN ('    {');

WriteNode (root);

WRITELN ('    };')

END.

{Photoshop version 1.0.1, file: Photoshop.r
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

#ifdef Debugging
include MacAppRFiles"Debug.rsrc";
#endif
include MacAppRFiles"MacApp.rsrc";
include MacAppRFiles"Printing.rsrc";
include MacAppRFiles"Dialog.rsrc";

#if Barneyscan
#define TheName    "BarneyscanXP"
#define FullName   "BarneyscanXP™"
#define ShortName  "XP"
#define FormatName "Barneyscan"
#else
#define TheName    "Photoshop"
#define FullName   "Adobe Photoshop™"
#define ShortName  "PS"
#define FormatName "Photoshop"
#endif

include "Photoshop" 'CODE';

type '8BIM' as 'STR ';

resource '8BIM' (0)
	{
#if Barneyscan
	TheName " Version 1.0.2"
#elif Demo
	TheName " Version 1.0 Demo 2"
#else
	TheName " Version 1.1d1"
#endif
	};

resource 'vers' (1)
	{
#if Barneyscan
	1, 0, release, 2, verUS,
	"1.0.2",
	"1.0.2 © 1989-90 Adobe Systems Inc."
#elif PlugIns && Demo
	1, 0, release, 0, verUS,
	"1.0",
	"1.0/Developer © 1989-90 Adobe Systems Inc."
#elif Demo
	1, 0, release, 0, verUS,
	"1.0",
	"1.0 Demo 2 © 1989-90 Adobe Systems Inc."
#else
	1, 1, development, 1, verUS,
	"1.1d1",
	"1.1d1 © 1989-90 Adobe Systems Inc."
#endif
	};

resource 'SIZE' (-1)
	{
	saveScreen,
	acceptSuspendResumeEvents,
	enableOptionSwitch,
	canBackground,
	MultiFinderAware,
	backgroundAndForeground,
	dontGetFrontClicks,
	ignoreChildDiedEvents,
	is32BitCompatible,
	reserved,
	reserved,
	reserved,
	reserved,
	reserved,
	reserved,
	reserved,
#ifdef Debugging
	2048 * 1024,
	1024 * 1024
#else
	2048 * 1024,
	1024 * 1024
#endif
	};

resource 'mem!' (256, purgeable)
	{
	30 * 1024,			/* Add to temporary reserve */
	 0 * 1024,			/* Add to permanent reserve */
	12 * 1024			/* Add to stack space */
	};

resource 'seg!' (256, purgeable)
	{
		{
		"ARes";
		"ARes2";
		"ARes3";
		"ARes4";
		"AEncoded";
		"ADoDraw";
		"ATIFFormat";
		"ALZWCompress";
		"GOpen";
		"GClose";
		"GDoCommand";
		"GSelCommand";
		"GFile";
		"GReadFile";
		"GWriteFile";
		"GClipboard"
		}
	};

type 'Reg '
	{
	pstring [63];
	pstring [63];
	pstring [7];
	longint;
	longint;
	};

#if !Barneyscan && !Demo
#ifdef Debugging

resource 'Reg ' (0)
	{
	"Thomas Knoll",
	"Knoll Software",
	"PCA100",
	123456,
	119634998
	};

#else

resource 'Reg ' (0)
	{
	"",
	"",
	"",
	0,
	5016209
	};

#endif
#endif

type 'FLoc'
	{
	pstring [63];
	pstring [31];
	pstring [31];
	longint;
	};

#ifdef Debugging

resource 'FLoc' (1000)
	{
	"PS Prefs",
	"HD:",
	"PS Pouch",
	$137
	};

#else

resource 'FLoc' (1000)
	{
	ShortName " Prefs",
	"",
	"",
	0
	};

#endif

type 'OPTs'
	{
	byte noColorize, Colorize;
	byte noUseSystem, UseSystem;
	byte noUseDirectLUT, UseDirectLUT;
	fill byte;
	integer off, oneBit, twoBit, fourBit, eightBit,
			eightBitSystem, sixteenBit, thirtytwoBit;
	integer sample, bilinear, bicubic;
	longint; integer;
	longint; integer;
	longint; integer; longint; integer; longint;
	integer; integer; integer; integer; integer;
	longint; integer; longint; integer; longint;
	longint; integer; longint; integer; longint;
	longint; integer; longint; integer; longint;
	longint; integer; longint; integer; longint;
	integer; integer; integer; integer; integer;
	integer; integer; integer; integer; integer;
	integer; integer; integer; integer; integer;
	integer; integer; integer; integer; integer;
	unsigned integer; unsigned integer; unsigned integer; integer;
	unsigned integer; unsigned integer; unsigned integer; integer;
	unsigned integer; unsigned integer; unsigned integer; integer;
	unsigned integer; unsigned integer; unsigned integer; integer;
	unsigned integer; unsigned integer; unsigned integer; integer;
	unsigned integer; unsigned integer; unsigned integer; integer;
	unsigned integer; unsigned integer; unsigned integer; integer;
	integer;
	integer;
	integer;
	wide array [256]
		{
		unsigned byte;
		};
	wide array [256]
		{
		unsigned byte;
		};
	integer;
	};

resource 'OPTs' (1000)
	{
	Colorize,
	noUseSystem,
	UseDirectLUT,
	eightBitSystem,
	bicubic,
	$28000, 4,
	$02AAB, 4,
	3473408, 1,  2949120, 0, 0,
	0, 15, 32, 55, 100,
	3106406, 1,  7104102, 0, 0,
	3106406, 1, 10590617, 0, 0,
	3276800, 1,  5898240, 0, 0,
	3473408, 1,  2949120, 0, 0,
	0, 15, 32, 55, 100,
	0, 15, 32, 55, 100,
	0, 15, 32, 55, 100,
	0, 15, 32, 55, 100,
	$0000, $8585, $BFBF,  80,
	$F3F3, $1A1A, $5454,  80,
	$FFFF, $DEDE, $0000, 100,
	$C9C9, $0000, $0000, 100,
	$0B0B, $7979, $1C1C,  80,
	$1C1C, $0000, $4A4A, 100,
	$6E6E, $5D5D, $5757,  50,
	140,
	300,
	300,
		{
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		},
		{
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		},
	0
	};

type 'CHST'
	{
	wide array
		{
		integer;
		integer;
		integer;
		integer;
		integer;
		};
	};

resource 'CHST' (1000, purgeable)
	{
		{
		146,  4,  6,  2,  6,
		103,  6,  9,  3,  9,
		 87,  7, 11,  4, 11,
		 76,  8, 12,  4, 12,
		 62, 10, 15,  5, 15,
		 52, 12, 18,  6, 18,
		 45, 14, 21,  7, 21,
		 39, 16, 24,  8, 24,
		 35, 18, 27,  9, 27,
		 31, 20, 30, 10, 30,
		 29, 22, 33, 11, 33,
		  0, 24, 36, 12, 36
		}
	};

resource 'BNDL' (128)
	{
	'8BIM', 0,
		{
		'ICN#', { 0, 128;
				  1, 129;
				  2, 130;
				  3, 131;
				  4, 132;
				  5, 133;
				  6, 134;
				  7, 135;
				  8, 136;
				  9, 137;
				 10, 138;
				 11, 139;
				 12, 140;
				 13, 141;
				 14, 142;
				 15, 143;
				 16, 144;
				 17, 145;
				 18, 146;
				 19, 147;
				 20, 148;
				 21, 149 };
		'FREF', { 0, 128;
				  1, 129;
				  2, 130;
				  3, 131;
				  4, 132;
				  5, 133;
				  6, 134;
				  7, 135;
				  8, 136;
				  9, 137;
				 10, 138;
				 11, 139;
				 12, 140;
				 13, 141;
				 14, 142;
				 15, 143;
				 16, 144;
				 17, 145;
				 18, 146;
				 19, 147;
				 20, 148;
				 21, 149;
				 22, 150;
				 23, 151;
				 24, 152;
				 25, 153;
				 26, 154;
				 27, 155;
				 28, 156 }
		}
	};

resource 'FREF' (128)
	{
	'APPL', 0, ""
	};

resource 'FREF' (129)
	{
	'8BPF', 1, ""
	};

resource 'FREF' (130)
	{
	'8BIM', 2, ""
	};

resource 'FREF' (131)
	{
	'PICT', 3, ""
	};

resource 'FREF' (132)
	{
	'SCRN', 4, ""
	};

resource 'FREF' (133)
	{
	'TIFF', 5, ""
	};

resource 'FREF' (134)
	{
	'GIFf', 6, ""
	};

resource 'FREF' (135)
	{
	'ILBM', 7, ""
	};

resource 'FREF' (136)
	{
	'PXR ', 8, ""
	};

resource 'FREF' (137)
	{
	'8BSS', 9, ""
	};

resource 'FREF' (138)
	{
	'8BAM', 10, ""
	};

resource 'FREF' (139)
	{
	'G8im', 10, ""
	};

resource 'FREF' (140)
	{
	'BWim', 10, ""
	};

resource 'FREF' (141)
	{
	'8BFM', 10, ""
	};

resource 'FREF' (142)
	{
	'G8tc', 10, ""
	};

resource 'FREF' (143)
	{
	'8BEM', 10, ""
	};

resource 'FREF' (144)
	{
	'8BPI', 10, ""
	};

resource 'FREF' (145)
	{
	'EPSF', 11, ""
	};

resource 'FREF' (146)
	{
	'8BCT', 12, ""
	};

resource 'FREF' (147)
	{
	'8BLT', 13, ""
	};

resource 'FREF' (148)
	{
	'8BCK', 14, ""
	};

resource 'FREF' (149)
	{
	'8BMD', 15, ""
	};

resource 'FREF' (150)
	{
	'8BMC', 15, ""
	};

resource 'FREF' (151)
	{
	'..CT', 16, ""
	};

resource 'FREF' (152)
	{
	'8BHS', 17, ""
	};

resource 'FREF' (153)
	{
	'8BTF', 18, ""
	};

resource 'FREF' (154)
	{
	'TPIC', 19, ""
	};

resource 'FREF' (155)
	{
	'8BST', 20, ""
	};

resource 'FREF' (156)
	{
	'8BVM', 21, ""
	};

resource 'ICN#' (128, "Program")
	{
		{
		$"FC00 003F 8000 0001 BFFF FFFD A00F FFFD"
		$"A01B FFFD A03F FFFD 207F F5FC 21FE 01FC"
		$"22F0 00FC 27C0 F03C 2B87 FE3C 2E1F FFCC"
		$"3E37 FFDC 30E7 FFEC 2180 FFF4 2F80 3FFC"
		$"2D08 7FAC 218D FFBC 26C7 FFBC 29C7 FF4C"
		$"20A3 FEFC 2231 FEFC 2008 78FC 205C 07FC"
		$"200F FFFC 2802 FFBC A501 EDFD A000 037D"
		$"A000 001D BFFF FFFD 8000 0001 FC00 003F",
		$"FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF"
		$"FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF"
		$"FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF"
		$"FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF"
		$"FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF"
		$"FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF"
		$"FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF"
		$"FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF"
		}
	};

resource 'ICN#' (129, "Preferences")
	{
		{
		$"0000 0000 7FFF FFFE 4040 2002 4040 4002"
		$"4040 8002 4041 0002 4042 0002 4047 FFFE"
		$"604F F002 505F F802 487F FC02 447F FE02"
		$"427F FF02 417F FE82 40FF FE42 407F FE22"
		$"403F FE12 401F FA0A 400F F206 7FFF E202"
		$"4000 4202 4000 8202 4001 0202 4002 0202"
		$"7FFF FFFE 78C6 231E 7B5A EEFE 78C6 673E"
		$"7BDA EFDE 7BDA 2E3E 7FFF FFFE",
		$"0000 0000 0000 0000 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC"
		}
	};

resource 'ICN#' (130, "Internal")
	{
		{
		$"01FF FFE0 0100 0050 FFFF FE48 FFFF FE44"
		$"8D6C 6E42 B556 D641 8C56 D67F BD56 D601"
		$"BD6E EE01 FFFF FE01 FFFF FE01 0104 0801"
		$"0104 1001 0104 2001 0104 7FFF 0104 FF01"
		$"0105 FF81 0187 FFC1 0147 FFE1 0127 FFF1"
		$"0117 FFE9 010F FFE5 0107 FFE3 0103 FFE1"
		$"0101 FFA1 0100 FF21 01FF FE21 0100 0421"
		$"0100 0821 0100 1021 0100 2021 01FF FFFF",
		$"0000 0040 00FF FFE0 0000 01F0 7FFF FFF8"
		$"7FFF FFFC 7FFF FFFE 7FFF FFFF 7FFF FFFE"
		$"7FFF FFFE 7FFF FFFE 0000 01FE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE"
		}
	};

resource 'ICN#' (131, "PICT File")
	{
		{
		$"01FF FFE0 0100 0050 FFFF FE48 FFFF FE44"
		$"F1B2 3E42 F6AF 7E41 F1AF 7E7F F7AF 7E01"
		$"F7B3 7E01 FFFF FE01 FFFF FE01 0104 0801"
		$"0104 1001 0104 2001 0104 7FFF 0104 FF01"
		$"0105 FF81 0187 FFC1 0147 FFE1 0127 FFF1"
		$"0117 FFE9 010F FFE5 0107 FFE3 0103 FFE1"
		$"0101 FFA1 0100 FF21 01FF FE21 0100 0421"
		$"0100 0821 0100 1021 0100 2021 01FF FFFF",
		$"0000 0040 00FF FFE0 0000 01F0 7FFF FFF8"
		$"7FFF FFFC 7FFF FFFE 7FFF FFFF 7FFF FFFE"
		$"7FFF FFFE 7FFF FFFE 0000 01FE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE"
		}
	};

resource 'ICN#' (132, "PICT Resource")
	{
		{
		$"01FF FFE0 0100 0050 FFFF FE48 FFFF FE44"
		$"8D91 C642 B57B DA41 8D7B 467F BD7B D601"
		$"BD9B DA01 FFFF FE01 FFFF FE01 0104 0801"
		$"0104 1001 0104 2001 0104 7FFF 0104 FF01"
		$"0105 FF81 0187 FFC1 0147 FFE1 0127 FFF1"
		$"0117 FFE9 010F FFE5 0107 FFE3 0103 FFE1"
		$"0101 FFA1 0100 FF21 01FF FE21 0100 0421"
		$"0100 0821 0100 1021 0100 2021 01FF FFFF",
		$"0000 0040 00FF FFE0 0000 01F0 7FFF FFF8"
		$"7FFF FFFC 7FFF FFFE 7FFF FFFF 7FFF FFFE"
		$"7FFF FFFE 7FFF FFFE 0000 01FE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE"
		}
	};

resource 'ICN#' (133, "TIFF")
	{
		{
		$"01FF FFE0 0100 0050 FFFF FE48 FFFF FE44"
		$"F8A2 3E42 FDAE FE41 FDA6 7E7F FDAE FE01"
		$"FDAE FE01 FFFF FE01 FFFF FE01 0104 0801"
		$"0104 1001 0104 2001 0104 7FFF 0104 FF01"
		$"0105 FF81 0187 FFC1 0147 FFE1 0127 FFF1"
		$"0117 FFE9 010F FFE5 0107 FFE3 0103 FFE1"
		$"0101 FFA1 0100 FF21 01FF FE21 0100 0421"
		$"0100 0821 0100 1021 0100 2021 01FF FFFF",
		$"0000 0040 00FF FFE0 0000 01F0 7FFF FFF8"
		$"7FFF FFFC 7FFF FFFE 7FFF FFFF 7FFF FFFE"
		$"7FFF FFFE 7FFF FFFE 0000 01FE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE"
		}
	};

resource 'ICN#' (134, "GIF")
	{
		{
		$"01FF FFE0 0100 0050 FFFF FE48 FFFF FE44"
		$"FF34 7E42 FEF5 FE41 FE94 FE7F FED5 FE01"
		$"FF35 FE01 FFFF FE01 FFFF FE01 0104 0801"
		$"0104 1001 0104 2001 0104 7FFF 0104 FF01"
		$"0105 FF81 0187 FFC1 0147 FFE1 0127 FFF1"
		$"0117 FFE9 010F FFE5 0107 FFE3 0103 FFE1"
		$"0101 FFA1 0100 FF21 01FF FE21 0100 0421"
		$"0100 0821 0100 1021 0100 2021 01FF FFFF",
		$"0000 0040 00FF FFE0 0000 01F0 7FFF FFF8"
		$"7FFF FFFC 7FFF FFFE 7FFF FFFF 7FFF FFFE"
		$"7FFF FFFE 7FFF FFFE 0000 01FE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE"
		}
	};

resource 'ICN#' (135, "IFF")
	{
		{
		$"01FF FFE0 0100 0050 FFFF FE48 FFFF FE44"
		$"FE88 FE42 FEBB FE41 FE99 FE7F FEBB FE01"
		$"FEBB FE01 FFFF FE01 FFFF FE01 0104 0801"
		$"0104 1001 0104 2001 0104 7FFF 0104 FF01"
		$"0105 FF81 0187 FFC1 0147 FFE1 0127 FFF1"
		$"0117 FFE9 010F FFE5 0107 FFE3 0103 FFE1"
		$"0101 FFA1 0100 FF21 01FF FE21 0100 0421"
		$"0100 0821 0100 1021 0100 2021 01FF FFFF",
		$"0000 0040 00FF FFE0 0000 01F0 7FFF FFF8"
		$"7FFF FFFC 7FFF FFFE 7FFF FFFF 7FFF FFFE"
		$"7FFF FFFE 7FFF FFFE 0000 01FE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE"
		}
	};

resource 'ICN#' (136, "PIXAR")
	{
		{
		$"01FF FFE0 0100 0050 FFFF FE48 FFFF FE44"
		$"8D59 8E42 B556 B641 8DB6 8E7F BD50 B601"
		$"BD56 B601 FFFF FE01 FFFF FE01 0104 0801"
		$"0104 1001 0104 2001 0104 7FFF 0104 FF01"
		$"0105 FF81 0187 FFC1 0147 FFE1 0127 FFF1"
		$"0117 FFE9 010F FFE5 0107 FFE3 0103 FFE1"
		$"0101 FFA1 0100 FF21 01FF FE21 0100 0421"
		$"0100 0821 0100 1021 0100 2021 01FF FFFF",
		$"0000 0040 00FF FFE0 0000 01F0 7FFF FFF8"
		$"7FFF FFFC 7FFF FFFE 7FFF FFFF 7FFF FFFE"
		$"7FFF FFFE 7FFF FFFE 0000 01FE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE"
		}
	};

resource 'ICN#' (137, "Setup")
	{
		{
		$"0000 0000 3FFF FFFC 2040 2004 2040 4004"
		$"2040 8004 2041 0004 2042 0004 2047 FFFC"
		$"204F F004 305F F804 287F FC04 247F FE04"
		$"227F FF04 217F FE84 20FF FE44 207F FE24"
		$"203F FE14 201F FA0C 200F F204 3FFF E204"
		$"2000 4204 2000 8204 2001 0204 2002 0204"
		$"3FFF FFFC 3C44 5A3C 3BDE DADC 3CCE DA3C"
		$"3F5E DAFC 38C6 E6FC 3FFF FFFC",
		$"0000 0000 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC"
		}
	};

resource 'ICN#' (138, "Plug-in")
	{
		{
		$"0000 0000 0000 0000 0000 0000 0000 0000"
		$"07FF FFFE 0800 00A9 1000 00A9 2000 00A9"
		$"4000 00A9 FFFF FFFE 8000 0000 8000 0000"
		$"8000 0000 81FF FFFE 8110 00A9 8110 00A9"
		$"8110 00A9 8110 00A9 811F FFFE 8120 0000"
		$"8140 0000 8180 0000 81FF FFFE 8000 00A9"
		$"8000 00A9 8000 00A9 8000 00A9 FFFF FFFE",
		$"0000 0000 0000 0000 0000 0000 0000 0000"
		$"07FF FFFE 0FFF FFFF 1FFF FFFF 3FFF FFFF"
		$"7FFF FFFF FFFF FFFE FFFF FFFE FFFF FFFE"
		$"FFFF FFFE FFFF FFFE FFFF FFFF FFFF FFFF"
		$"FFFF FFFF FFFF FFFF FFFF FFFE FFFF FFFE"
		$"FFFF FFFE FFFF FFFE FFFF FFFE FFFF FFFF"
		$"FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFE"
		}
	};

resource 'ICN#' (139, "EPS")
	{
		{
		$"01FF FFE0 0100 0050 FFFF FE48 FFFF FE44"
		$"F88E 3E42 FBB5 FE41 F98E 7E7F FBBF BE01"
		$"F8BC 7E01 FFFF FE01 FFFF FE01 0104 0801"
		$"0104 1001 0104 2001 0104 7FFF 0104 FF01"
		$"0105 FF81 0187 FFC1 0147 FFE1 0127 FFF1"
		$"0117 FFE9 010F FFE5 0107 FFE3 0103 FFE1"
		$"0101 FFA1 0100 FF21 01FF FE21 0100 0421"
		$"0100 0821 0100 1021 0100 2021 01FF FFFF",
		$"0000 0040 00FF FFE0 0000 01F0 7FFF FFF8"
		$"7FFF FFFC 7FFF FFFE 7FFF FFFF 7FFF FFFE"
		$"7FFF FFFE 7FFF FFFE 0000 01FE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE"
		}
	};

resource 'ICN#' (140, "CLUT")
	{
		{
		$"0000 0000 7FFF FFFE 4040 2002 4040 4002"
		$"4040 8002 4041 0002 4042 0002 4047 FFFE"
		$"604F F002 505F F802 487F FC02 447F FE02"
		$"427F FF02 417F FE82 40FF FE42 407F FE22"
		$"403F FE12 401F FA0A 400F F206 7FFF E202"
		$"4000 4202 4000 8202 4001 0202 4002 0202"
		$"7FFF FFFE 7F97 68FE 7F77 6DFE 7F77 6DFE"
		$"7F77 6DFE 7F91 9DFE 7FFF FFFE",
		$"0000 0000 0000 0000 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC"
		}
	};

resource 'ICN#' (141, "Map")
	{
		{
		$"0000 0000 7FFF FFFE 4040 2002 4040 4002"
		$"4040 8002 4041 0002 4042 0002 4047 FFFE"
		$"604F F002 505F F802 487F FC02 447F FE02"
		$"427F FF02 417F FE82 40FF FE42 407F FE22"
		$"403F FE12 401F FA0A 400F F206 7FFF E202"
		$"4000 4202 4000 8202 4001 0202 4002 0202"
		$"7FFF FFFE 7F76 63FE 7F25 ADFE 7F55 A3FE"
		$"7F74 2FFE 7F75 AFFE 7FFF FFFE",
		$"0000 0000 0000 0000 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC"
		}
	};

resource 'ICN#' (142, "Kernel")
	{
		{
		$"0000 0000 7FFF FFFE 4040 2002 4040 4002"
		$"4040 8002 4041 0002 4042 0002 4047 FFFE"
		$"604F F002 505F F802 487F FC02 447F FE02"
		$"427F FF02 417F FE82 40FF FE42 407F FE22"
		$"403F FE12 401F FA0A 400F F206 7FFF E202"
		$"4000 4202 4000 8202 4001 0202 4002 0202"
		$"7FFF FFFE 6D11 B45E 6B76 95DE 6731 A4DE"
		$"6B76 B5DE 6D16 B446 7FFF FFFE",
		$"0000 0000 0000 0000 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC"
		}
	};

resource 'ICN#' (143, "MD")
	{
		{
		$"01FF FFE0 0100 0050 FFFF FE48 FFFF FE44"
		$"FDD1 FE42 FC96 FE41 FD56 FE7F FDD6 FE01"
		$"FDD1 FE01 FFFF FE01 FFFF FE01 0104 0801"
		$"0104 1001 0104 2001 0104 7FFF 0104 FF01"
		$"0105 FF81 0187 FFC1 0147 FFE1 0127 FFF1"
		$"0117 FFE9 010F FFE5 0107 FFE3 0103 FFE1"
		$"0101 FFA1 0100 FF21 01FF FE21 0100 0421"
		$"0100 0821 0100 1021 0100 2021 01FF FFFF",
		$"0000 0040 00FF FFE0 0000 01F0 7FFF FFF8"
		$"7FFF FFFC 7FFF FFFE 7FFF FFFF 7FFF FFFE"
		$"7FFF FFFE 7FFF FFFE 0000 01FE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE"
		}
	};

resource 'ICN#' (144, "Scitex")
	{
		{
		$"01FF FFE0 0100 0050 FFFF FE48 FFFF FE44"
		$"CCA2 2A42 BBB6 EA41 DBB6 767F EBB6 EA01"
		$"9CB6 2A01 FFFF FE01 FFFF FE01 0104 0801"
		$"0104 1001 0104 2001 0104 7FFF 0104 FF01"
		$"0105 FF81 0187 FFC1 0147 FFE1 0127 FFD1"
		$"0117 FFC9 010F FFC5 0107 FFC3 0103 FFC1"
		$"0101 FFC1 0100 FF41 01FF FE41 0100 0441"
		$"0100 0841 0100 1041 0100 2041 01FF FFFF",
		$"0000 0040 00FF FFE0 0000 01F0 7FFF FFF8"
		$"7FFF FFFC 7FFF FFFE 7FFF FFFF 7FFF FFFE"
		$"7FFF FFFE 7FFF FFFE 0000 01FE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE"
		}
	};

resource 'ICN#' (145, "Screen")
	{
		{
		$"0000 0000 7FFF FFFE 4040 2002 4040 4002"
		$"4040 8002 4041 0002 4042 0002 4047 FFFE"
		$"604F F002 505F F802 487F FC02 447F FE02"
		$"427F FF02 417F FE82 40FF FE42 407F FE22"
		$"403F FE12 401F FA0A 400F F206 7FFF E202"
		$"4000 4202 4000 8202 4001 0202 4002 0202"
		$"7FFF FFFE 7191 88B6 6F76 BB96 7371 99A6"
		$"7D76 BBB6 6396 88B6 7FFF FFFE",
		$"0000 0000 0000 0000 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC"
		}
	};

resource 'ICN#' (146, "Transfer")
	{
		{
		$"0000 0000 7FFF FFFE 4040 2002 4040 4002"
		$"4040 8002 4041 0002 4042 0002 4047 FFFE"
		$"604F F002 505F F802 487F FC02 447F FE02"
		$"427F FF02 417F FE82 40FF FE42 407F FE22"
		$"403F FE12 401F FA0A 400F F206 7FFF E202"
		$"4000 4202 4000 8202 4001 0202 4002 0202"
		$"7FFF FFFE 711C DB1E 7B6B 4AFE 7B1B 533E"
		$"7B68 5BDE 7B6B 5A3E 7FFF FFFE",
		$"0000 0000 0000 0000 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC"
		}
	};

resource 'ICN#' (147, "TGA")
	{
		{
		$"01FF FFE0 0100 0050 FFFF FE48 FFFF FE44"
		$"F8C6 7E42 FDBD BE41 FDA5 BE7F FDB4 3E01"
		$"FDC5 BE01 FFFF FE01 FFFF FE01 0104 0801"
		$"0104 1001 0104 2001 0104 7FFF 0104 FF01"
		$"0105 FF81 0187 FFC1 0147 FFE1 0127 FFF1"
		$"0117 FFE9 010F FFE5 0107 FFE3 0103 FFE1"
		$"0101 FFA1 0100 FF21 01FF FE21 0100 0421"
		$"0100 0821 0100 1021 0100 2021 01FF FFFF",
		$"0000 0040 00FF FFE0 0000 01F0 7FFF FFF8"
		$"7FFF FFFC 7FFF FFFE 7FFF FFFF 7FFF FFFE"
		$"7FFF FFFE 7FFF FFFE 0000 01FE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE 00FF FFFE"
		$"00FF FFFE 00FF FFFE 00FF FFFE"
		}
	};

resource 'ICN#' (148, "Table")
	{
		{
		$"0000 0000 7FFF FFFE 4040 2002 4040 4002"
		$"4040 8002 4041 0002 4042 0002 4047 FFFE"
		$"604F F002 505F F802 487F FC02 447F FE02"
		$"427F FF02 417F FE82 40FF FE42 407F FE22"
		$"403F FE12 401F FA0A 400F F206 7FFF E202"
		$"4000 4202 4000 8202 4001 0202 4002 0202"
		$"7FFF FFFE 78CC 6E3E 7DB5 AEFE 7DB4 6E7E"
		$"7D85 AEFE 7DB4 623E 7FFF FFFE",
		$"0000 0000 0000 0000 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC"
		}
	};

resource 'ICN#' (149, "Temp")
	{
		{
		$"0000 0000 7FFF FFFE 4040 2002 4040 4002"
		$"4040 8002 4041 0002 4042 0002 4047 FFFE"
		$"604F F002 505F F802 487F FC02 447F FE02"
		$"427F FF02 417F FE82 40FF FE42 407F FE22"
		$"403F FE12 401F FA0A 400F F206 7FFF E202"
		$"4000 4202 4000 8202 4001 0202 4002 0202"
		$"7FFF FFFE 7E22 E8FE 7F6E 4B7E 7F66 A8FE"
		$"7F6E EBFE 7F62 EBFE 7FFF FFFE",
		$"0000 0000 0000 0000 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC 3FFF FFFC 3FFF FFFC"
		$"3FFF FFFC 3FFF FFFC"
		}
	};

resource 'WIND' (1001, purgeable)
	{
	{41, 62, 184, 205},
	zoomDocProc,
	invisible,
	goAway,
	0x0,
	"<<<>>>"
	};

resource 'WIND' (1002, purgeable)
	{
#if Barneyscan
	{33, 3, 314, 58},
#else
	{33, 3, 336, 58},
#endif
	32,
	invisible,
	noGoAway,
	0x0,
	""
	};

resource 'WIND' (1003, purgeable)
	{
	{-127, 3, -3, 336},
	32,
	invisible,
	goAway,
	0x0,
	""
	};

resource 'WIND' (1004, purgeable)
	{
	{33, -94, 75, -3},
	32,
	invisible,
	goAway,
	0x0,
	""
	};

resource 'WIND' (1005, purgeable)
	{
	{-107, -182, -3, -3},
	32,
	invisible,
	goAway,
	0x0,
	""
	};

data 'WDEF' (2)
	{
	$"4E56 FFCC 48E7 0308 286E 000E 2C2E 0008"
	$"7000 2D40 0014 206C 0072 2050 43EE FFF0"
	$"5488 22D8 22D8 41EE FFE0 43EE FFF0 20D9"
	$"20D9 302E FFE0 5440 3D40 FFE0 302E FFE2"
	$"5C40 3D40 FFE2 302E FFE0 5E40 3D40 FFE4"
	$"302E FFE2 5E40 3D40 FFE6 302E 000C 6710"
	$"5340 6700 00F6 5340 6700 0178 6000 01C2"
	$"102C 006E 6700 00E0 4A86 6722 41EE FFF8"
	$"43EE FFE0 20D9 20D9 486E FFF8 2F3C 0001"
	$"0001 A8A9 486E FFF8 A8A4 6000 0194 486E"
	$"FFCC A898 A89E 486E FFF0 A8A1 41EE FFF8"
	$"43EE FFF0 20D9 20D9 302E FFF8 D07C 000A"
	$"5240 3D40 FFFC 486E FFF8 A8A1 4247 602C"
	$"3007 D06E FFF8 0240 0001 6706 4236 70E8"
	$"6018 102E FFFB 0240 0001 6708 1DBC 0055"
	$"70E8 6006 1DBC FFAA 70E8 5247 7007 B047"
	$"6CCE 486E FFF8 2F3C 0001 0001 A8A9 102C"
	$"006F 6736 486E FFF8 486E FFE8 A8A5 102C"
	$"0070 6724 41EE FFF8 43EE FFE0 20D9 20D9"
	$"486E FFF8 2F3C FFFF FFFF A8A9 486E FFF8"
	$"A8A3 486E FFE0 A8A1 6006 486E FFF8 A8A3"
	$"486E FFCC A899 6000 00D8 206C 0076 2050"
	$"43EE FFF8 5488 22D8 22D8 4267 2F06 486E"
	$"FFF8 A8AD 101F 6708 7001 2D40 0014 6060"
	$"41EE FFF8 43EE FFF0 20D9 20D9 302E FFF8"
	$"D07C 000A 5240 3D40 FFFC 102C 0070 6724"
	$"C02C 006F 4A00 671C 2F00 4267 2F06 486E"
	$"FFE0 A8AD 121F 201F C001 6708 7004 2D40"
	$"0014 606C 4267 2F06 486E FFF8 A8AD 101F"
	$"6708 7002 2D40 0014 6056 7000 2D40 0014"
	$"604E 41EE FFF8 43EC 0010 20D9 20D9 486E"
	$"FFF8 302C 000A 4440 3F00 302C 0008 4440"
	$"3F00 A8A8 2F2C 0076 486E FFF8 A8DF 486E"
	$"FFF8 2F3C FFFF FFFF A8A9 302E FFF8 907C"
	$"000A 3D40 FFF8 2F2C 0072 486E FFF8 A8DF"
	$"4CDF 10C0 4E5E 205F DEFC 000C 4ED0"
	};

data 'WDEF' (3)
	{
	$"4E56 FED2 48E7 0308 286E 000E 7000 2D40"
	$"0014 302E 000C 6710 5340 6700 0180 5340"
	$"6700 01DE 6000 0228 102C 006E 6700 016A"
	$"486E FED2 A898 A89E 4247 6014 41EE FEE6"
	$"11BC FFFF 7000 43EE FEEE 4231 7000 5247"
	$"7007 B047 6CE6 206C 0072 2050 43EE FFF8"
	$"5488 22D8 22D8 486E FFF8 A8A1 486E FFF8"
	$"2F3C 0001 0001 A8A9 302E FFF8 D07C 000F"
	$"3D40 FFF8 2F3C 0002 0002 A89B 486E FEEE"
	$"A89D 486E FFF8 A8A1 486E FFF8 2F3C 0002"
	$"0002 A8A9 486E FEE6 A89D 486E FFF8 A8A1"
	$"486E FFF8 2F3C 0002 0002 A8A9 486E FEEE"
	$"A89D 486E FFF8 A8A1 486E FEE6 A89D 2F3C"
	$"0001 0001 A89B 206C 0072 2050 43EE FFF8"
	$"5488 22D8 22D8 486E FFF8 2F3C 0001 0001"
	$"A8A9 302E FFF8 D07C 000F 3D40 FFFC 486E"
	$"FFF8 A8A3 102C 006F 6730 4247 6026 3F2E"
	$"FFFA 302E FFF8 5640 3207 E341 D240 3F01"
	$"A893 302E FFFE 906E FFFA 5340 3F00 4267"
	$"A892 5247 7005 B047 6CD4 206C 0086 2050"
	$"43EE FEF8 703F 22D8 51C8 FFFC 4267 486E"
	$"FEF8 A88C 3C1F 486E FFF8 302E FFFE 906E"
	$"FFFA 9046 907C 000C 48C0 81FC 0002 3F00"
	$"4267 A8A9 486E FFF8 A8A3 302E FFFA 5C40"
	$"3F00 302E FFFC 5540 3F00 A893 486E FEF8"
	$"A884 486E FED2 A899 6000 00B4 206C 0076"
	$"2050 43EE FFF8 5488 22D8 22D8 4267 2F2E"
	$"0008 486E FFF8 A8AD 101F 6708 7001 2D40"
	$"0014 603A 206C 0072 2050 43EE FFF8 5488"
	$"22D8 22D8 302E FFF8 D07C 0016 3D40 FFFC"
	$"4267 2F2E 0008 486E FFF8 A8AD 101F 6708"
	$"7002 2D40 0014 6056 7000 2D40 0014 604E"
	$"41EE FFF8 43EC 0010 20D9 20D9 486E FFF8"
	$"302C 000A 4440 3F00 302C 0008 4440 3F00"
	$"A8A8 2F2C 0076 486E FFF8 A8DF 486E FFF8"
	$"2F3C FFF9 FFF9 A8A9 302E FFF8 907C 000F"
	$"3D40 FFF8 2F2C 0072 486E FFF8 A8DF 4CDF"
	$"10C0 4E5E 205F DEFC 000C 4ED0"
	};

resource 'errs' (1128, purgeable)
	{
		{
		whichList, 0, 1000;

		-25019, -25010, 1;
		-25029, -25020, 2;
		-25039, -25030, 3;
		-25049, -25040, 4;
		-25059, -25050, 5;
		-25069, -25060, 6;
		-25079, -25070, 7;
		-25089, -25080, 8;
		-25099, -25090, 9;
		-25109, -25100, 10;
		-25119, -25110, 11;
		-25129, -25120, 12;
		-25139, -25130, 13;
		-25149, -25140, 14;
		-25159, -25150, 15;
		-25169, -25160, 16;
		-25179, -25170, 17;
		-25189, -25180, 18;
		-25199, -25190, 19;
		-25209, -25200, 20;
		-25219, -25210, 21;
		-25229, -25220, 22;
		-25239, -25230, 23;
		-25249, -25240, 24;
		-25259, -25250, 25;
		-25269, -25260, 26;
		-25279, -25270, 27;
		-25289, -25280, 28;
		-25299, -25290, 29;
		-25309, -25300, 30;
		-25319, -25310, 31;
		-25329, -25320, 32;
		-25339, -25330, 33;
		-25349, -25340, 34;
		-25359, -25350, 35;
		-25369, -25360, 36;
		-25379, -25370, 37;
		-25389, -25380, 38;
		-25399, -25390, 39;
		-25409, -25400, 40;
		-25419, -25410, 41;
		-25429, -25420, 42;
		-25439, -25430, 43;
		-25449, -25440, 44;
		-25459, -25450, 45;
		-25469, -25460, 46;
		-25479, -25470, 47;
		-25489, -25480, 48;
		-25499, -25490, 49;
		-25509, -25500, 50;
		-25519, -25510, 51;
		-25529, -25520, 52;
		-25539, -25530, 53;
		-25549, -25540, 54;
		-25559, -25550, 55;

		-25900, -25900, 56;
		-25901, -25901, 57;
		-25902, -25902, 58;
		-25903, -25903, 59;

		-25999, -25990, 60;

		-30000, -30000, 61;
		-30001, -30001, 62;
		-30002, -30002, 63;

		-30100, -30100, 64;

		-30200, -30200, 65;
		-30201, -30201, 66;
		-30202, -30202, 67;
		-30203, -30203, 68;
		-30204, -30204, 69;
		-30205, -30205, 70;
		-30206, -30206, 71;
		-30207, -30207, 72;
		-30208, -30208, 73;

		  -61,	 -61, 74;
		  -39,	 -39, 75;
		-8133, -8133, 76
		}
	};

resource 'STR#' (1000, purgeable)
	{
		{
		"the System file is too old (version 6.0.2 or higher is required)",
		"it is not a valid " FormatName " document",
		"there were no pixels in the selected area",
		"the region was too complex",
		"it does not work in the scratch pad",
		"the clipboard’s contents are in RGB Color mode,"
			" and cannot be pasted into an Indexed Color image",
		"the clipboard’s and the image’s color tables are incompatible",
		"of a problem parsing the PICT",
		"the PICT is too complex to read without Color QuickDraw",
		"the image is too wide to save as a PICT",
		"it does not contain any PICT resources",
		"it does not work with Bitmap images"
			" (convert image to Gray Scale to edit)",
		"it does not work with Indexed Color images"
			" (convert image to RGB Color to edit)",
		"it is in Color Only mode,"
			" which works only with RGB Color images",
		"it is in Darken Only mode,"
			" which does not work with Indexed Color images",
		"it is in Lighten Only mode,"
			" which does not work with Indexed Color images",
		"the image has only one brightness value",
		"the selected area has only one brightness value",
		"the file is empty",
		"of a problem parsing the ThunderScan document",
		"of a problem parsing the TIFF document",
		"the TIFF document uses more than 8 bits per pixel",
		"the TIFF document uses an unsupported compression scheme",
		"of a problem parsing the MacPaint document",
		"of a problem parsing the PixelPaint document",
		"the selected canvas size was too small",
		"of a problem parsing the GIF document",
		"of a problem parsing the IFF document",
		"the file is not compatible with this version of " TheName,
		"of a problem parsing the PIXAR document",
		"the result would be too large",
		"the distortion is too complex",
		"there is no Barneyscan scanner attached to this Macintosh",
		"the image has not been saved in single-disk " FormatName " format",
		"the image has not been modified since it was last saved",
		"the image’s mode has been changed since it was last saved",
		"the image’s size has been changed since it was last saved",
		"this channel has been created since the image was last saved",
		"the disk copy of the document has been changed",
		"the EPS document is not compatible with " TheName,
		"of missing or invalid personalization information",
		"the area to clone has not been defined"
			" (option-click to define a source point)",
		"no texture has been defined"
			" (option-click to define a texture)",
		"no pattern has been defined",
		"the selected area is too large to use as a brush",
		"no custom brush has been defined",
		"the selected area was too small",
		"of a problem parsing the Scitex CT document",
		"the type block is too large",
		"there were no non-fringe pixels in the selection",
		"of a problem parsing the TGA document",
		"the TGA document uses an unsupported format",
		"CMYK images are not supported by " TheName,
		"a DCS color plate file was not found",
		"it was created by an version of PixelPaint after 2.0",

		"a problem with the hardware key",
		"the EvE INIT file was not in the system folder at boot time",
		"no hardware key is present",
		"the hardware key was not initialized correctly",

		"it is not yet implemented",

		"a problem with the acquisition module interface",
		"there is no scanner installed",
		"a problem with the scanner",

		"a problem with the filter module interface",

		"a problem with the export module interface",
		"the export module does not work with Bitmap images",
		"the export module does not work with Gray Scale images",
		"the export module does not work with Indexed Color images",
		"the export module does not work with RGB Color images",
		"the export module does not work with CMYK Color images",
		"the export module does not work with HSL Color images",
		"the export module does not work with HSB Color images",
		"the export module does not work with Multichannel images",

		"write access was not granted",
		"an unexpected end-of-file was encountered",
		"a PostScript error"
		}
	};

resource 'STR#' (1001, purgeable)
	{
		{
		"use the lasso tool",
		"complete the selection",
		"move the selection",
		"duplicate the selection",
		"use the eraser tool",
		"use the pencil tool",
		"use the paint brush tool",
		"use the airbrush tool",
		"use the blurring tool",
		"use the smudging tool",
		"use the sharpening tool",
		"load the color table",
		"save the color table",
		"load the map",
		"save the map",
		"load the convolution kernel",
		"save the convolution kernel",
		"use the magic wand tool",
		"use the paint bucket tool",
		"use the magic eraser tool",
		"nudge the selection",
		"use the blend tool",
		"load the separation setup",
		"save the separation setup",
		"use the rubber stamp", 				/* Clone */
		"use the reverting rubber stamp",
		"use the rubber stamp", 				/* Texture */
		"use the rubber stamp", 				/* Pattern */
		"use the rubber stamp", 				/* Pickup */
		"use the impressionist rubber stamp",
		"use the cropping tool",
		"use the elliptical marquee tool",
		"use the type tool",
		"use the " TheName " color picker",
		"load the halftone screen",
		"load the halftone screens",
		"save the halftone screen",
		"save the halftone screens",
		"load the transfer function",
		"load the transfer functions",
		"save the transfer function",
		"save the transfer functions",
		"use the line tool",
		"use the rectangular marquee tool",
		"move the selection outline",
		"nudge the selection outline",
		"personalize your copy of " FullName,
		"build the color separation table",
		"open the temporary file"
		}
	};

resource 'STR#' (1002, purgeable)
	{
		{
		"Select foreground color:",
		"Select background color:",
		"Save preferences in:",
		"Select color:",
		"Select first color:",
		"Select last color:",
		"Save color table in:",
		"Save map in:",
		"Save convolution kernel in:",
		"Select calibration color:",
		"An integer",
		"A number",
		"Save separation setup in:",
		"Save part ^0 in:",
		"Save halftone screen in:",
		"Save halftone screens in:",
		"Save transfer function in:",
		"Save transfer functions in:",
		"Reading ",
		"Writing ",
		" Format",
		"Reading Part ",
		"Writing Part ",
		"Save BG curve in:",
		"Save UCR curve in:",
		ShortName " Table",
		"Building Color Separation Table"
		}
	};

resource 'STR#' (1003, purgeable)
	{
		{
		"New <I",
		"#",
		"RGB",
		"Selection <I",
		"New <I",
		"Red",
		"Green",
		"Blue",
		"Cyan",
		"Magenta",
		"Yellow",
		"Black",
		"Hue",
		"Saturation",
		"Lightness",
		"Brightness"
		}
	};

resource 'STR#' (1004, purgeable)
	{
		{
		"RGB",
		"CMYK",
		"HSL",
		"HSB"
		}
	};

resource 'STR ' (1005)
	{
	ShortName " Temp"
	};

resource 'STR#' (1006, purgeable)
	{
		{
		"  Channels: ",
		"     Width: ",
		"    Height: ",
		"Resolution: ",
		" pixel ",
		" pixels",
		" (Bitmap)",
		" (Gray Scale)",
		" (Indexed Color)",
		" (RGB Color)",
		" (CMYK Color)",
		" (HSL Color)",
		" (HSB Color)",
		" (Multichannel)"
		}
	};

resource 'STR#' (1007, purgeable)
	{
		{
		" inch",
		" inches",
		" cm",
		" cm",
		" point",
		" points",
		" pica",
		" picas",
		" column",
		" columns"
		}
	};

resource 'STR#' (1008, purgeable)
	{
		{
		" pixel/inch",
		" pixels/inch",
		" pixel/cm",
		" pixels/cm"
		}
	};

resource 'STR#' (1009, purgeable)
	{
		{
		" pixel",
		" pixels",
		}
	};

resource 'CURS' (501, "Lasso")
	{
	$"0000 0000 03F8 1C06 2001 4001 8001 8006"
	$"8038 71C0 CE00 A800 7000 1000 1000 2000",
	$"0000 0000 0000 0000 0000 0000 0000 0000"
	$"0000 0000 0000 0000 0000 0000 0000 0000",
	{15, 2}
	};

resource 'CURS' (502, "Hand")
	{
	$"0180 1A70 2648 264A 124D 1249 6809 9801"
	$"8802 4002 2002 2004 1004 0808 0408 0408",
	$"0180 1BF0 3FF8 3FFA 1FFF 1FFF 6FFF FFFF"
	$"FFFE 7FFE 3FFE 3FFC 1FFC 0FF8 07F8 07F8",
	{7, 7}
	};

resource 'CURS' (503, "Zoom In")
	{
	$"0F00 30C0 4020 4620 8610 9F90 9F90 8610"
	$"4620 4020 30F0 0F38 001C 000E 0007 0002",
	$"0F00 3FC0 7FE0 7FE0 FFF0 FFF0 FFF0 FFF0"
	$"7FE0 7FE0 3FF0 0F38 001C 000E 0007 0002",
	{6, 6}
	};

resource 'CURS' (504, "Zoom Out")
	{
	$"0F00 30C0 4020 4020 8010 9F90 9F90 8010"
	$"4020 4020 30F0 0F38 001C 000E 0007 0002",
	$"0F00 3FC0 7FE0 7FE0 FFF0 FFF0 FFF0 FFF0"
	$"7FE0 7FE0 3FF0 0F38 001C 000E 0007 0002",
	{6, 6}
	};

resource 'CURS' (505, "Zoom Limit")
	{
	$"0F00 30C0 4020 4020 8010 8010 8010 8010"
	$"4020 4020 30F0 0F38 001C 000E 0007 0002",
	$"0F00 3FC0 7FE0 7FE0 FFF0 FFF0 FFF0 FFF0"
	$"7FE0 7FE0 3FF0 0F38 001C 000E 0007 0002",
	{6, 6}
	};

resource 'CURS' (506, "Eyedropper")
	{
	$"000E 001F 001F 00FF 007E 00B8 0118 0228"
	$"0440 0880 1100 2200 4400 4800 B000 4000",
	$"000E 001F 001F 00FF 007E 00F8 01F8 03E8"
	$"07C0 0F80 1F00 3E00 7C00 7800 F000 4000",
	{15, 1}
	};

resource 'CURS' (507, "Marquee")
	{
	$"0100 0100 0100 0100 0100 0100 0100 FFFE"
	$"0100 0100 0100 0100 0100 0100 0100 0000",
	$"0000 0000 0000 0000 0000 0000 0000 0000"
	$"0000 0000 0000 0000 0000 0000 0000 0000",
	{7, 7}
	};

resource 'CURS' (508, "Eraser")
	{
	$"FFFF 8001 8001 8001 8001 8001 8001 8001"
	$"8001 8001 8001 8001 8001 8001 8001 FFFF",
	$"FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF"
	$"FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF",
	{8, 8}
	};

resource 'CURS' (509, "Pencil")
	{
	$"0F00 0880 1080 1900 2700 2200 4200 4400"
	$"8400 8800 C800 F000 E000 C000 8000 0000",
	$"0F00 0F80 1F80 1F00 3F00 3E00 7E00 7C00"
	$"FC00 F800 F800 F000 E000 C000 0000 0000",
	{14, 0}
	};

resource 'CURS' (510, "Brush")
	{
	$"0048 0048 0090 0090 0120 0120 0240 0240"
	$"0780 0980 1180 1380 2700 2E00 5C00 F000",
	$"0078 0078 00F0 00F0 01E0 01E0 03C0 03C0"
	$"0780 0F80 1F80 1F80 3F00 3E00 7C00 F000",
	{15, 0}
	};

resource 'CURS' (511, "Airbrush")
	{
	$"0007 000F 001F 003E 007C 0CF8 19F0 17E0"
	$"05C0 0880 1100 2303 4484 4884 B048 C030",
	$"0007 000F 001F 003E 007C 0CF8 19F0 17E0"
	$"07C0 0F80 1F00 3F03 7C84 7884 F048 C030",
	{15, 0}
	};

resource 'CURS' (512, "Blur")
	{
	$"0400 0400 0A00 0A00 1100 1100 2080 4040"
	$"4040 8020 8020 8020 8020 4040 2080 1F00",
	$"0400 0400 0E00 0E00 1F00 1F00 3F80 7FC0"
	$"7FC0 FFE0 FFE0 FFE0 FFE0 7FC0 3F80 1F00",
	{0, 5}
	};

resource 'CURS' (513, "Smudge")
	{
	$"0408 0808 1008 2804 5404 6A04 5444 68C4"
	$"2944 3388 1210 27E0 2400 4800 9000 E000",
	$"07F8 0FF8 1FF8 3FFC 7FFC 7FFC 7FFC 7FFC"
	$"3F7C 3FF8 1FF0 3FE0 3C00 7800 F000 E000",
	{15, 0}
	};

resource 'CURS' (514, "Bucket")
	{
	$"0700 0880 0980 0AC0 0CB0 089C 108E 2147"
	$"4087 800F 8017 4027 2047 1086 0904 0600",
	$"0700 0F80 0F80 0FC0 0FF0 0FFC 1FFE 3FFF"
	$"7FFF FFFF FFF7 7FE7 3FC7 1F86 0F00 0600",
	{14, 13}
	};

resource 'CURS' (515, "Sharpen")
	{
	$"0800 0800 0800 1400 1400 1400 2200 2200"
	$"2200 4100 4100 4100 8080 8080 8080 FF80",
	$"0800 0800 0800 1C00 1C00 1C00 3E00 3E00"
	$"3E00 7F00 7F00 7F00 FF80 FF80 FF80 FF80",
	{0, 4}
	};

resource 'CURS' (516, "Line")
	{
	$"0800 0800 0000 0800 DD80 0800 0000 0800"
	$"0800 0000 0000 0000 0000 0000 0000 0000",
	$"0000 0000 0000 0000 0000 0000 0000 0000"
	$"0000 0000 0000 0000 0000 0000 0000 0000",
	{4, 4}
	};

resource 'CURS' (517, "Move")
	{
	$"0000 0040 00C0 01C0 03C0 07C0 0FC0 1FC0"
	$"3FC0 07C0 06C0 0C40 0C00 1800 1800 0000",
	$"0060 00E0 01E0 03E0 07E0 0FE0 1FE0 3FE0"
	$"7FE0 FFE0 0FE0 1EE0 1E60 3C20 3C00 3800",
	{1, 9}
	};

resource 'CURS' (518, "Wand")
	{
	$"1000 4400 2800 9200 2800 4400 1100 0280"
	$"0140 00E0 0070 0038 001C 000E 0007 0002",
	$"1000 5400 3800 FE00 3800 5400 1100 0380"
	$"01C0 00E0 0070 0038 001C 000E 0007 0002",
	{3, 3}
	};

resource 'CURS' (519, "Stamp")
	{
	$"01C0 0220 05D0 0410 0410 0220 01C0 0140"
	$"1F7C 21C2 4001 7FFF 43E1 41C1 4081 3FFE",
	$"01C0 03E0 07F0 07F0 07F0 03E0 01C0 01C0"
	$"1FFC 3FFE 7FFF 7FFF 7FFF 7FFF 7FFF 3FFE",
	{15, 8}
	};

resource 'CURS' (520, "Stamp Pickup")
	{
	$"01C0 0220 05D0 0410 0410 0220 01C0 0140"
	$"1F7C 21C2 4001 7FFF 4221 4141 4081 3FFE",
	$"01C0 03E0 07F0 07F0 07F0 03E0 01C0 01C0"
	$"1FFC 3FFE 7FFF 7FFF 7FFF 7FFF 7FFF 3FFE",
	{15, 8}
	};

resource 'CURS' (521, "Magic Eraser")
	{
	$"FFFF 8001 BFFD A005 AFF5 A815 ABD5 AA55"
	$"AA55 ABD5 A815 AFF5 A005 BFFD 8001 FFFF",
	$"FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF"
	$"FFFF FFFF FFFF FFFF FFFF FFFF FFFF FFFF",
	{8, 8}
	};

resource 'CURS' (522, "Blend")
	{
	$"0800 0800 0000 0800 DD80 0800 0000 0800"
	$"0800 0000 0000 0000 0000 0000 0000 0000",
	$"0000 0000 0000 0000 0000 0000 0000 0000"
	$"0000 0000 0000 0000 0000 0000 0000 0000",
	{4, 4}
	};

resource 'CURS' (523, "Crosshair")
	{
	$"0100 0100 0100 0000 0000 0000 0000 E10E"
	$"0000 0000 0000 0000 0100 0100 0100 0000",
	$"0000 0000 0000 0000 0000 0000 0000 0000"
	$"0000 0000 0000 0000 0000 0000 0000 0000",
	{7, 7}
	};

resource 'CURS' (524, "Crosshair Pickup")
	{
	$"0100 0100 0100 07C0 0820 1010 1010 F11E"
	$"1010 1010 0820 07C0 0100 0100 0100 0000",
	$"0000 0000 0000 0000 0000 0000 0000 0000"
	$"0000 0000 0000 0000 0000 0000 0000 0000",
	{7, 7}
	};

resource 'CURS' (525, "Crop")
	{
	$"1801 1802 1804 FFF8 FFF8 1838 1858 1898"
	$"1918 1A18 1C18 1FFF 1FFF 0018 0018 0018",
	$"2402 3C07 FFFE 7FFC 7FFC FFDC 3C7C 3CBC"
	$"3D3C 3E3C 3FFF 3FFE 3FFE 3FFF 003C 0024",
	{8, 8}
	};

resource 'CURS' (526, "Ellipse")
	{
	$"0100 0100 0100 0100 0100 0100 0100 FFFE"
	$"0100 0100 0100 0100 0100 0100 0100 0000",
	$"0000 0000 0000 0000 0000 0000 0000 0000"
	$"0000 0000 0000 0000 0000 0000 0000 0000",
	{7, 7}
	};

resource 'CURS' (527, "Type")
	{
	$"0C60 0280 0100 0100 0100 0100 0100 0100"
	$"0100 0100 0100 07C0 0100 0100 0280 0C60",
	$"0000 0000 0000 0000 0000 0000 0000 0000"
	$"0000 0000 0000 0000 0000 0000 0000 0000",
	{11, 7}
	};

resource 'CURS' (528, "Finish Crop")
	{
	$"0000 0000 000C 0012 7012 1C3C 0760 01C0"
	$"0760 1C3C 7012 0012 000C 0000 0000 0000",
	$"0000 001E 003F F03F FC3F FFFF 3FFE 0FF0"
	$"3FFE FFFF FC3F F03F 003F 001E 0000 0000",
	{7, 6}
	};

resource 'CURS' (550, "Histogram")
	{
	$"0400 0400 0000 0000 0400 CE60 0400 0000"
	$"0000 0400 0400 0000 0000 0000 0000 0000",
	$"0400 0400 0400 0400 0400 FFE0 0400 0400"
	$"0400 0400 0400 0000 0000 0000 0000 0000",
	{5, 5}
	};

/* Watch cursors */

resource 'CURS' (600, purgeable)
	{
	$"3F00 3F00 3F00 3F00 4080 8440 8440 8460"
	$"9C60 8040 8040 4080 3F00 3F00 3F00 3F00",
	$"3F00 3F00 3F00 3F00 7F80 FFC0 FFC0 FFC0"
	$"FFC0 FFC0 FFC0 7F80 3F00 3F00 3F00 3F00",
	{8, 8}
	};

resource 'CURS' (601, purgeable)
	{
	$"3F00 3F00 3F00 3F00 4080 8040 8140 8260"
	$"9C60 8040 8040 4080 3F00 3F00 3F00 3F00",
	$"3F00 3F00 3F00 3F00 7F80 FFC0 FFC0 FFC0"
	$"FFC0 FFC0 FFC0 7F80 3F00 3F00 3F00 3F00",
	{8, 8}
	};

resource 'CURS' (602, purgeable)
	{
	$"3F00 3F00 3F00 3F00 4080 8040 8040 8060"
	$"9F60 8040 8040 4080 3F00 3F00 3F00 3F00",
	$"3F00 3F00 3F00 3F00 7F80 FFC0 FFC0 FFC0"
	$"FFC0 FFC0 FFC0 7F80 3F00 3F00 3F00 3F00",
	{8, 8}
	};

resource 'CURS' (603, purgeable)
	{
	$"3F00 3F00 3F00 3F00 4080 8040 8040 8060"
	$"9C60 8240 8040 4080 3F00 3F00 3F00 3F00",
	$"3F00 3F00 3F00 3F00 7F80 FFC0 FFC0 FFC0"
	$"FFC0 FFC0 FFC0 7F80 3F00 3F00 3F00 3F00",
	{8, 8}
	};

resource 'CURS' (604, purgeable)
	{
	$"3F00 3F00 3F00 3F00 4080 8040 8040 8060"
	$"9C60 8440 8440 4080 3F00 3F00 3F00 3F00",
	$"3F00 3F00 3F00 3F00 7F80 FFC0 FFC0 FFC0"
	$"FFC0 FFC0 FFC0 7F80 3F00 3F00 3F00 3F00",
	{8, 8}
	};

resource 'CURS' (605, purgeable)
	{
	$"3F00 3F00 3F00 3F00 4080 8040 8040 8060"
	$"9C60 8840 9040 4080 3F00 3F00 3F00 3F00",
	$"3F00 3F00 3F00 3F00 7F80 FFC0 FFC0 FFC0"
	$"FFC0 FFC0 FFC0 7F80 3F00 3F00 3F00 3F00",
	{8, 8}
	};

resource 'CURS' (606, purgeable)
	{
	$"3F00 3F00 3F00 3F00 4080 8040 8040 8060"
	$"BC60 8040 8040 4080 3F00 3F00 3F00 3F00",
	$"3F00 3F00 3F00 3F00 7F80 FFC0 FFC0 FFC0"
	$"FFC0 FFC0 FFC0 7F80 3F00 3F00 3F00 3F00",
	{8, 8}
	};

resource 'CURS' (607, purgeable)
	{
	$"3F00 3F00 3F00 3F00 4080 8040 9040 8860"
	$"9C60 8040 8040 4080 3F00 3F00 3F00 3F00",
	$"3F00 3F00 3F00 3F00 7F80 FFC0 FFC0 FFC0"
	$"FFC0 FFC0 FFC0 7F80 3F00 3F00 3F00 3F00",
	{8, 8}
	};

resource 'cmnu' (1)
	{
	1,
	textMenuProc,
	allEnabled,
	enabled,
	apple,
		{
		"About " TheName "…"	, noIcon, noKey, noMark, plain, cAboutApp;
		"-" 					, noIcon, noKey, noMark, plain, noCommand
		}
	};

resource 'cmnu' (2)
	{
	2,
	textMenuProc,
	allEnabled,
	enabled,
	"File",
		{
		"New…"				, noIcon, "N"	 , noMark , plain, cNew;
		"Open…" 			, noIcon, "O"	 , noMark , plain, cOpen;
		"Open As…"			, noIcon, noKey  , noMark , plain, 21;
		"-" 				, noIcon, noKey  , noMark , plain, noCommand;
		"Close" 			, noIcon, "W"	 , noMark , plain, cClose;
		"Save"				, noIcon, "S"	 , noMark , plain, cSave;
		"Save As…"			, noIcon, noKey  , noMark , plain, cSaveAs;
		"Revert"			, noIcon, noKey  , noMark , plain, cRevert;
		"-" 				, noIcon, noKey  , noMark , plain, noCommand;
		"Acquire"			, noIcon, "\0x1B", "\0x25", plain, 1600;
#if !Barneyscan
		"Export"			, noIcon, "\0x1B", "\0x2B", plain, 1700;
#endif
		"-" 				, noIcon, noKey  , noMark , plain, noCommand;
		"Page Setup…"		, noIcon, noKey  , noMark , plain, cPageSetup;
		"Print…"			, noIcon, "P"	 , noMark , plain, cPrint;
		"-" 				, noIcon, noKey  , noMark , plain, noCommand;
		"Quit"				, noIcon, "Q"	 , noMark , plain, cQuit
		}
	};

resource 'cmnu' (3)
	{
	3,
	textMenuProc,
	allEnabled,
	enabled,
	"Edit",
		{
		"Undo"				, noIcon,	  "Z",	noMark, plain, cUndo;
		"-" 				, noIcon,	noKey,	noMark, plain, noCommand;
		"Cut"				, noIcon,	  "X",	noMark, plain, cCut;
		"Copy"				, noIcon,	  "C",	noMark, plain, cCopy;
		"Paste" 			, noIcon,	  "V",	noMark, plain, cPaste;
		"Paste Into"		, noIcon,	noKey,	noMark, plain, 1028;
		"Paste Behind"		, noIcon,	noKey,	noMark, plain, 1011;
		"Clear" 			, noIcon,	noKey,	noMark, plain, cClear;
		"Fill…" 			, noIcon,	noKey,	noMark, plain, 1001;
		"Crop"				, noIcon,	noKey,	noMark, plain, 1012;
#if !Barneyscan
		"-" 				, noIcon,	noKey,	noMark, plain, noCommand;
		"Define Brush"		, noIcon,	noKey,	noMark, plain, 1036;
		"Define Pattern"	, noIcon,	noKey,	noMark, plain, 1033;
#endif
		"-" 				, noIcon,	noKey,	noMark, plain, noCommand;
		"Paste Controls…"	, noIcon,	noKey,	noMark, plain, 1026;
		"-" 				, noIcon,	noKey,	noMark, plain, noCommand;
		"Preferences…"		, noIcon,	  "K",	noMark, plain, 1002
		}
	};

resource 'cmnu' (4)
	{
	4,
	textMenuProc,
	allEnabled,
	enabled,
	"Mode",
		{
		"Bitmap"			, noIcon,	noKey,	noMark, plain, 1013;
		"Gray Scale"		, noIcon,	noKey,	noMark, plain, 1014;
		"Indexed Color" 	, noIcon,	noKey,	noMark, plain, 1015;
		"RGB Color" 		, noIcon,	noKey,	noMark, plain, 1016;
#if !Barneyscan
		"CMYK Color"		, noIcon,	noKey,	noMark, plain, 1017;
#endif
		"HSL Color" 		, noIcon,	noKey,	noMark, plain, 1018;
		"HSB Color" 		, noIcon,	noKey,	noMark, plain, 1019;
		"Multichannel"		, noIcon,	noKey,	noMark, plain, 1020;
		"-" 				, noIcon,	noKey,	noMark, plain, noCommand;
		"Color Table"		, noIcon, "\0x1B", "\0x21", plain, 1150;
		"-" 				, noIcon,	noKey,	noMark, plain, noCommand;
		"Channel"			, noIcon, "\0x1B", "\0x2A", plain, 1100;
		"-" 				, noIcon,	noKey,	noMark, plain, noCommand;
		"New Channel"		, noIcon,	noKey,	noMark, plain, 1038;
		"Delete Channel"	, noIcon,	noKey,	noMark, plain, 1021;
		"-" 				, noIcon,	noKey,	noMark, plain, noCommand;
		"Split Channels"	, noIcon,	noKey,	noMark, plain, 1022;
		"Merge Channels…"	, noIcon,	noKey,	noMark, plain, 1023
		}
	};

resource 'cmnu' (5)
	{
	5,
	textMenuProc,
	allEnabled,
	enabled,
	"Image",
		{
		"Map"				, noIcon, "\0x1B", "\0x26", plain, 1400;
		"Adjust"			, noIcon, "\0x1B", "\0x22", plain, 1450;
		"-" 				, noIcon,	noKey,	noMark, plain, noCommand;
		"Filter"			, noIcon, "\0x1B", "\0x27", plain, 1550;
		"Last Filter"		, noIcon,	  "F",	noMark, plain, 1025;
		"-" 				, noIcon,	noKey,	noMark, plain, noCommand;
		"Calculate" 		, noIcon, "\0x1B", "\0x28", plain, 1500;
		"-" 				, noIcon,	noKey,	noMark, plain, noCommand;
		"Flip"				, noIcon, "\0x1B", "\0x23", plain, 1200;
		"Rotate"			, noIcon, "\0x1B", "\0x24", plain, 1250;
		"Effects"			, noIcon, "\0x1B", "\0x29", plain, 1300;
		"-" 				, noIcon,	noKey,	noMark, plain, noCommand;
#if !Barneyscan
		"Resize…"			, noIcon,	noKey,	noMark, plain, 1024;
		"Resample…" 		, noIcon,	noKey,	noMark, plain, 1030;
		"-" 				, noIcon,	noKey,	noMark, plain, noCommand;
		"Trap…" 			, noIcon,	noKey,	noMark, plain, 1035
#else
		"Resize…"			, noIcon,	  "R",	noMark, plain, 1024
#endif
		}
	};

resource 'cmnu' (6)
	{
	6,
	textMenuProc,
	allEnabled,
	enabled,
	"Select",
		{
		"All"				, noIcon,	"A", noMark, plain, cSelectAll;
		"None"				, noIcon,	"D", noMark, plain, 1029;
		"Inverse"			, noIcon, noKey, noMark, plain, 1008;
		"-" 				, noIcon, noKey, noMark, plain, noCommand;
		"Grow"				, noIcon,	"G", noMark, plain, 1027;
		"Similar"			, noIcon, noKey, noMark, plain, 1010;
		"-" 				, noIcon, noKey, noMark, plain, noCommand;
		"Fringe…"			, noIcon, noKey, noMark, plain, 1009;
		"Feather…"			, noIcon, noKey, noMark, plain, 1007;
		"-" 				, noIcon, noKey, noMark, plain, noCommand;
#if Barneyscan
		"Hide Edges"		, noIcon,	"H", noMark, plain, 1034
#else
		"Defringe…" 		, noIcon, noKey, noMark, plain, 1041;
		"-" 				, noIcon, noKey, noMark, plain, noCommand;
		"Hide Edges"		, noIcon,	"H", noMark, plain, 1034;
		"-" 				, noIcon, noKey, noMark, plain, noCommand;
		"Selection->Alpha"	, noIcon, noKey, noMark, plain, 1031;
		"Alpha->Selection"	, noIcon, noKey, noMark, plain, 1032
#endif
		}
	};

resource 'cmnu' (7)
	{
	7,
	textMenuProc,
	allEnabled,
	enabled,
	"Window",
		{
		"New Window"		, noIcon, noKey, noMark, plain, 1003;
		"-" 				, noIcon, noKey, noMark, plain, noCommand;
		"Zoom In"			, noIcon,	"+", noMark, plain, 1004;
		"Zoom Out"			, noIcon,	"-", noMark, plain, 1005;
		"Zoom Factor…"		, noIcon, noKey, noMark, plain, 1006;
		"-" 				, noIcon, noKey, noMark, plain, noCommand;
#if Barneyscan
		"Show Coords"		, noIcon, noKey, noMark, plain, 1043;
#else
		"Show Rulers"		, noIcon,	"R", noMark, plain, 1039;
		"Show Palette"		, noIcon, noKey, noMark, plain, 1042;
		"Show Brushes"		, noIcon, noKey, noMark, plain, 1040;
#endif
		"-" 				, noIcon, noKey, noMark, plain, noCommand;
		"Histogram…"		, noIcon, noKey, noMark, plain, 1037
		}
	};

resource 'cmnu' (33)
	{
	33,
	textMenuProc,
	allEnabled,
	enabled,
	"Color Table",
		{
		"Edit Table…"		, noIcon, noKey, noMark, plain, 1151;
		"-" 				, noIcon, noKey, noMark, plain, noCommand
		}
	};

resource 'cmnu' (34)
	{
	34,
	textMenuProc,
	allEnabled,
	enabled,
	"Adjust",
		{
		"Levels…"				, noIcon,	"L", noMark, plain, 1451;
		"Brightness/Contrast…"	, noIcon,	"B", noMark, plain, 1452;
		"Color Balance…"		, noIcon,	"Y", noMark, plain, 1453;
		"Hue/Saturation…"		, noIcon,	"U", noMark, plain, 1454
		}
	};

resource 'cmnu' (35)
	{
	35,
	textMenuProc,
	allEnabled,
	enabled,
	"Flip",
		{
		"Horizontal"		, noIcon, noKey, noMark, plain, 1201;
		"Vertical"			, noIcon, noKey, noMark, plain, 1202
		}
	};

resource 'cmnu' (36)
	{
	36,
	textMenuProc,
	allEnabled,
	enabled,
	"Rotate",
		{
		"180°"					, noIcon, noKey, noMark, plain, 1251;
		"90° CW"				, noIcon, noKey, noMark, plain, 1253;
		"90° CCW"				, noIcon, noKey, noMark, plain, 1252;
		"Arbitrary…"			, noIcon, noKey, noMark, plain, 1254;
		"Free"					, noIcon, noKey, noMark, plain, 1302
		}
	};

resource 'cmnu' (37)
	{
	37,
	textMenuProc,
	allEnabled,
	enabled,
	"Acquire",
		{
		}
	};

resource 'cmnu' (38)
	{
	38,
	textMenuProc,
	allEnabled,
	enabled,
	"Map",
		{
		"Invert"			, noIcon,	"I", noMark, plain, 1401;
		"Equalize"			, noIcon,	"E", noMark, plain, 1402;
		"Threshold…"		, noIcon,	"T", noMark, plain, 1403;
		"Posterize…"		, noIcon,	"J", noMark, plain, 1404;
		"Arbitrary…"		, noIcon,	"M", noMark, plain, 1405
		}
	};

resource 'cmnu' (39)
	{
	39,
	textMenuProc,
	allEnabled,
	enabled,
	"Filter",
		{
		}
	};

resource 'cmnu' (40)
	{
	40,
	textMenuProc,
	allEnabled,
	enabled,
	"Calculate",
		{
		"Add…"				, noIcon, noKey, noMark, plain, 1501;
		"Blend…"			, noIcon, noKey, noMark, plain, 1502;
		"Composite…"		, noIcon, noKey, noMark, plain, 1503;
		"Constant…" 		, noIcon, noKey, noMark, plain, 1504;
		"Darker…"			, noIcon, noKey, noMark, plain, 1505;
		"Difference…"		, noIcon, noKey, noMark, plain, 1506;
		"Duplicate…"		, noIcon, noKey, noMark, plain, 1507;
		"Lighter…"			, noIcon, noKey, noMark, plain, 1508;
		"Multiply…" 		, noIcon, noKey, noMark, plain, 1509;
		"Screen…"			, noIcon, noKey, noMark, plain, 1510;
		"Subtract…" 		, noIcon, noKey, noMark, plain, 1511
		}
	};

resource 'cmnu' (41)
	{
	41,
	textMenuProc,
	allEnabled,
	enabled,
	"Effects",
		{
		"Stretch/Shrink"	, noIcon, noKey, noMark, plain, 1301;
		"Skew"				, noIcon, noKey, noMark, plain, 1303;
		"Perspective"		, noIcon, noKey, noMark, plain, 1304;
		"Distort"			, noIcon, noKey, noMark, plain, 1305
		}
	};

resource 'cmnu' (42)
	{
	42,
	textMenuProc,
	allEnabled,
	enabled,
	"Channel",
		{
		}
	};

resource 'cmnu' (43)
	{
	43,
	textMenuProc,
	allEnabled,
	enabled,
	"Export",
		{
		}
	};

resource 'cmnu' (128)
	{
	128,
	textMenuProc,
	allEnabled,
	enabled,
	"Buzzwords",
		{

		"Page Setup"		, noIcon, noKey, noMark, plain, cChangePrinterStyle,
		"Move"				, noIcon, noKey, noMark, plain, 2000,
		"Duplicate" 		, noIcon, noKey, noMark, plain, 2001,
		"Nudge" 			, noIcon, noKey, noMark, plain, 2002,
		"Mode Change"		, noIcon, noKey, noMark, plain, 2003,
		"Color Table"		, noIcon, noKey, noMark, plain, 2004,
		"Eraser"			, noIcon, noKey, noMark, plain, 2005,
		"Pencil"			, noIcon, noKey, noMark, plain, 2006,
		"Paint Brush"		, noIcon, noKey, noMark, plain, 2007,
		"Blur Tool" 		, noIcon, noKey, noMark, plain, 2008,
		"Sharpen Tool"		, noIcon, noKey, noMark, plain, 2009,
		"Smudge Tool"		, noIcon, noKey, noMark, plain, 2010,
		"Erase All" 		, noIcon, noKey, noMark, plain, 2011,
		"Resize"			, noIcon, noKey, noMark, plain, 2012,
		"Rotate"			, noIcon, noKey, noMark, plain, 2013,
		"Invert"			, noIcon, noKey, noMark, plain, 2014,
		"Equalize"			, noIcon, noKey, noMark, plain, 2015,
		"Threshold" 		, noIcon, noKey, noMark, plain, 2016,
		"Posterize" 		, noIcon, noKey, noMark, plain, 2017,
		"Map"				, noIcon, noKey, noMark, plain, 2018,
		"Adjust"			, noIcon, noKey, noMark, plain, 2019,
		"Calculate" 		, noIcon, noKey, noMark, plain, 2020,
		"Skew"				, noIcon, noKey, noMark, plain, 2021,
		"Distort"			, noIcon, noKey, noMark, plain, 2022,
		"Rubber Stamp"		, noIcon, noKey, noMark, plain, 2023,
		"Paste Controls"	, noIcon, noKey, noMark, plain, 2024,
		"Magic Wand"		, noIcon, noKey, noMark, plain, 2025,
		"Lasso" 			, noIcon, noKey, noMark, plain, 2026,
		"Fringe"			, noIcon, noKey, noMark, plain, 2027,
		"Feather"			, noIcon, noKey, noMark, plain, 2028,
		"Paint Bucket"		, noIcon, noKey, noMark, plain, 2029,
		"Rubber Stamp"		, noIcon, noKey, noMark, plain, 2030,
		"Rulers"			, noIcon, noKey, noMark, plain, 2031,
		"Fill"				, noIcon, noKey, noMark, plain, 2032,
		"Resample"			, noIcon, noKey, noMark, plain, 2033,
		"Rubber Stamp"		, noIcon, noKey, noMark, plain, 2034,
		"Trap"				, noIcon, noKey, noMark, plain, 2035,
		"Type Tool" 		, noIcon, noKey, noMark, plain, 2036,
		"Defringe"			, noIcon, noKey, noMark, plain, 2037,
		"Line Tool" 		, noIcon, noKey, noMark, plain, 2038,
		"Airbrush"			, noIcon, noKey, noMark, plain, 2039,
		"Blend Tool"		, noIcon, noKey, noMark, plain, 2040,
		"Marquee"			, noIcon, noKey, noMark, plain, 2041,	/* Rectangular */
		"Marquee"			, noIcon, noKey, noMark, plain, 2042,	/* Elliptical */
		"Move Outline"		, noIcon, noKey, noMark, plain, 2043,
		"Nudge Outline" 	, noIcon, noKey, noMark, plain, 2044,
		"Color Correction"	, noIcon, noKey, noMark, plain, 2045,
		"Total Ink Limit"	, noIcon, noKey, noMark, plain, 2046,
		"Yes"				, noIcon, noKey, noMark, plain, 2047,
		"No"				, noIcon, noKey, noMark, plain, 2048,
		"Cancel"			, noIcon, noKey, noMark, plain, 2049,
		"Deselect"			, noIcon, noKey, noMark, plain, 2050,

		"Bitmap"			, noIcon, noKey, noMark, plain, 3000,
		"Bitmap…"			, noIcon, noKey, noMark, plain, 3001,
		"Gray Scale"		, noIcon, noKey, noMark, plain, 3002,
		"Gray Scale…"		, noIcon, noKey, noMark, plain, 3003,
		"Indexed Color" 	, noIcon, noKey, noMark, plain, 3004,
		"Indexed Color…"	, noIcon, noKey, noMark, plain, 3005,
		"Equalize"			, noIcon, noKey, noMark, plain, 3006,
		"Equalize…" 		, noIcon, noKey, noMark, plain, 3007,
		"Hide Edges"		, noIcon, noKey, noMark, plain, 3008,
		"Show Edges"		, noIcon, noKey, noMark, plain, 3009,
		"Hide Rulers"		, noIcon, noKey, noMark, plain, 3010,
		"Show Rulers"		, noIcon, noKey, noMark, plain, 3011,
		"Hide Brushes"		, noIcon, noKey, noMark, plain, 3012,
		"Show Brushes"		, noIcon, noKey, noMark, plain, 3013,
		"Hide Palette"		, noIcon, noKey, noMark, plain, 3014,
		"Show Palette"		, noIcon, noKey, noMark, plain, 3015,
		"Hide Coords"		, noIcon, noKey, noMark, plain, 3016,
		"Show Coords"		, noIcon, noKey, noMark, plain, 3017

		}
	};

resource 'MBAR' (128)
	{
	{1; 2; 3; 4; 5; 6; 7}
	};

resource 'MBAR' (130)
	{
	{33; 34; 35; 36; 37; 38; 39; 40; 41; 42; 43}
	};

resource 'MENU' (1000)
	{
	1000,
	textMenuProc,
	allEnabled,
	enabled,
	"Format",
		{
		FormatName			, noIcon, noKey, noMark, plain,
		"Amiga IFF/ILBM"	, noIcon, noKey, noMark, plain,
		"CompuServe GIF"	, noIcon, noKey, noMark, plain,
		"EPS"				, noIcon, noKey, noMark, plain,
		"MacPaint"			, noIcon, noKey, noMark, plain,
		"PICT File" 		, noIcon, noKey, noMark, plain,
		"PICT Resource" 	, noIcon, noKey, noMark, plain,
		"PIXAR" 			, noIcon, noKey, noMark, plain,
		"PixelPaint"		, noIcon, noKey, noMark, plain,
		"Raw"				, noIcon, noKey, noMark, plain,
#if !Barneyscan
		"Scitex CT" 		, noIcon, noKey, noMark, plain,
#endif
		"TGA"				, noIcon, noKey, noMark, plain,
		"ThunderScan"		, noIcon, noKey, noMark, plain,
		"TIFF"				, noIcon, noKey, noMark, plain
		}
	};

resource 'MENU' (1001)
	{
	1001,
	textMenuProc,
	allEnabled,
	enabled,
	"Units 1",
		{
		"(inches)"			, noIcon, noKey, noMark, plain,
		"(mm)"				, noIcon, noKey, noMark, plain,
		"(points)"			, noIcon, noKey, noMark, plain
		}
	};

resource 'MENU' (1002)
	{
	1002,
	textMenuProc,
	allEnabled,
	enabled,
	"Units 2",
		{
		"(pixels/inch)" 	, noIcon, noKey, noMark, plain,
		"(pixels/cm)"		, noIcon, noKey, noMark, plain
		}
	};

resource 'MENU' (1003)
	{
	1003,
	textMenuProc,
	allEnabled,
	enabled,
	"Units 3",
		{
		"(inches)"			, noIcon, noKey, noMark, plain,
		"(cm)"				, noIcon, noKey, noMark, plain,
		"(points)"			, noIcon, noKey, noMark, plain,
		"(picas)"			, noIcon, noKey, noMark, plain,
		"(columns)" 		, noIcon, noKey, noMark, plain
		}
	};

resource 'MENU' (1004)
	{
	1004,
	textMenuProc,
	allEnabled,
	enabled,
	"Units 4",
		{
		"(inches)"			, noIcon, noKey, noMark, plain,
		"(cm)"				, noIcon, noKey, noMark, plain,
		"(points)"			, noIcon, noKey, noMark, plain,
		"(picas)"			, noIcon, noKey, noMark, plain
		}
	};

resource 'MENU' (1005)
	{
	1005,
	textMenuProc,
	allEnabled,
	enabled,
	"Units 6",
		{
		"(lines/inch)"		, noIcon, noKey, noMark, plain,
		"(lines/cm)"		, noIcon, noKey, noMark, plain
		}
	};

resource 'MENU' (1006)
	{
	1006,
	textMenuProc,
	allEnabled,
	enabled,
	"Units 7",
		{
		"(dots/inch)"		, noIcon, noKey, noMark, plain,
		"(dots/cm)" 		, noIcon, noKey, noMark, plain
		}
	};

resource 'MENU' (1007)
	{
	1007,
	textMenuProc,
	allEnabled,
	enabled,
	"Units 8",
		{
		"(pixels)"			, noIcon, noKey, noMark, plain,
		"(inches)"			, noIcon, noKey, noMark, plain,
		"(cm)"				, noIcon, noKey, noMark, plain,
		"(points)"			, noIcon, noKey, noMark, plain,
		"(picas)"			, noIcon, noKey, noMark, plain,
		"(columns)" 		, noIcon, noKey, noMark, plain
		}
	};

resource 'MENU' (1008)
	{
	1008,
	textMenuProc,
	allEnabled,
	enabled,
	"Units 9",
		{
		"(pixels)"			, noIcon, noKey, noMark, plain,
		"(inches)"			, noIcon, noKey, noMark, plain,
		"(cm)"				, noIcon, noKey, noMark, plain,
		"(points)"			, noIcon, noKey, noMark, plain,
		"(picas)"			, noIcon, noKey, noMark, plain
		}
	};

resource 'MENU' (1009)
	{
	1009,
	textMenuProc,
	allEnabled,
	enabled,
	"Units 10",
		{
		"pixel" 			, noIcon, noKey, noMark, plain,
		"point" 			, noIcon, noKey, noMark, plain
		}
	};

resource 'MENU' (1010)
	{
	1010,
	textMenuProc,
	allEnabled,
	enabled,
	"Ground",
		{
		"Fore"			, noIcon, noKey, noMark, plain,
		"Back"			, noIcon, noKey, noMark, plain
		}
	};

resource 'MENU' (1011)
	{
	1011,
	textMenuProc,
	allEnabled,
	enabled,
	"Space",
		{
		"RGB"			, noIcon, noKey, noMark, plain,
		"HSB"			, noIcon, noKey, noMark, plain,
		"CMYK"			, noIcon, noKey, noMark, plain
		}
	};

resource 'MENU' (1012)
	{
	1012,
	textMenuProc,
	allEnabled,
	enabled,
	"Units 11",
		{
		"(pixels)"			, noIcon, noKey, noMark, plain,
		"(points)"			, noIcon, noKey, noMark, plain,
		"(mm)"				, noIcon, noKey, noMark, plain
		}
	};

resource 'MENU' (1013)
	{
	1013,
	textMenuProc,
	allEnabled,
	enabled,
	"Black",
		{
		"Custom…"			, noIcon, noKey, noMark, plain,
		"-" 				, noIcon, noKey, noMark, plain
		}
	};

resource 'MENU' (1014)
	{
	1014,
	textMenuProc,
	allEnabled,
	enabled,
	"OptBlack",
		{
		"Load BG…"			, noIcon, noKey, noMark, plain,
		"Save BG…"			, noIcon, noKey, noMark, plain,
		"-" 				, noIcon, noKey, noMark, plain,
		"Load UCR…" 		, noIcon, noKey, noMark, plain,
		"Save UCR…" 		, noIcon, noKey, noMark, plain
		}
	};

type 'FILT'
	{
	switch
		{

		case Kernal:
			key integer = 0;
			integer;								/* Scale */
			integer;								/* Offset */
			integer = $$Countof (Elements);
			array Elements
				{
				integer;							/* Delta row */
				integer;							/* Delta column */
				integer;							/* Weight */
				};

		case Procedure:
			key integer = 1;
			integer = $$Countof (Parameters);
			array Parameters
				{
				byte Check = -1, Radio = -2;		/* Decimal places */
				byte noBlank, Blank;				/* Does blank mean 0? */
				longint;							/* Minimum value */
				longint;							/* Maximum value */
				longint;							/* Default value */
				};

		};
	};

resource 'FILT' (1001, "Fragment", purgeable)
	{
	Kernal
		{
		4,
		0,
			{
			-4, -4,  1;
			-4,  4,  1;
			 4, -4,  1;
			 4,  4,  1
			}
		}
	};

resource 'FILT' (4001, "Custom…")
	{
	Procedure
		{
			{
			0,	 Blank,  -999,	999,  0;
			0,	 Blank,  -999,	999,  0;
			0,	 Blank,  -999,	999,  0;
			0,	 Blank,  -999,	999,  0;
			0,	 Blank,  -999,	999,  0;
			0,	 Blank,  -999,	999,  0;
			0,	 Blank,  -999,	999,  0;
			0,	 Blank,  -999,	999, -1;
			0,	 Blank,  -999,	999,  0;
			0,	 Blank,  -999,	999,  0;
			0,	 Blank,  -999,	999,  0;
			0,	 Blank,  -999,	999, -1;
			0,	 Blank,  -999,	999,  5;
			0,	 Blank,  -999,	999, -1;
			0,	 Blank,  -999,	999,  0;
			0,	 Blank,  -999,	999,  0;
			0,	 Blank,  -999,	999,  0;
			0,	 Blank,  -999,	999, -1;
			0,	 Blank,  -999,	999,  0;
			0,	 Blank,  -999,	999,  0;
			0,	 Blank,  -999,	999,  0;
			0,	 Blank,  -999,	999,  0;
			0,	 Blank,  -999,	999,  0;
			0,	 Blank,  -999,	999,  0;
			0,	 Blank,  -999,	999,  0;
			0, noBlank, 	1, 9999,  1;
			0,	 Blank, -9999, 9999,  0
			}
		}
	};

resource 'FILT' (4002, "Offset…")
	{
	Procedure
		{
			{
			0,	   Blank, -30000, 30000, 0;
			0,	   Blank, -30000, 30000, 0;
			Radio, Blank,	   0,	  2, 0
			}
		}
	};

resource 'FILT' (4003, "Gaussian Blur…")
	{
	Procedure
		{
			{
			1, noBlank, 1, 1000, 10
			}
		}
	};

resource 'FILT' (4004, "Find Edges", purgeable)
	{
	Procedure
		{
			{
			}
		}
	};

resource 'FILT' (4005, "Maximum…", purgeable)
	{
	Procedure
		{
			{
			0, noBlank, 1, 10, 1
			}
		}
	};

resource 'FILT' (4006, "Minimum…", purgeable)
	{
	Procedure
		{
			{
			0, noBlank, 1, 10, 1
			}
		}
	};

resource 'FILT' (4007, "Blur", purgeable)
	{
	Procedure
		{
			{
			}
		}
	};

resource 'FILT' (4008, "Blur More", purgeable)
	{
	Procedure
		{
			{
			}
		}
	};

resource 'FILT' (4009, "Sharpen", purgeable)
	{
	Procedure
		{
			{
			}
		}
	};

resource 'FILT' (4010, "Sharpen More", purgeable)
	{
	Procedure
		{
			{
			}
		}
	};

resource 'FILT' (4011, "High Pass…", purgeable)
	{
	Procedure
		{
			{
			1, noBlank, 1, 1000, 100
			}
		}
	};

resource 'FILT' (4012, "Median…", purgeable)
	{
	Procedure
		{
			{
			0, noBlank, 1, 16, 1
			}
		}
	};

resource 'FILT' (4013, "Facet", purgeable)
	{
	Procedure
		{
			{
			}
		}
	};

resource 'FILT' (4014, "Motion Blur…", purgeable)
	{
	Procedure
		{
			{
			0, noBlank, -90, 90,  0;
			0, noBlank,   1, 32, 10
			}
		}
	};

resource 'FILT' (4015, "Diffuse…", purgeable)
	{
	Procedure
		{
			{
			Radio, noBlank, 0, 2, 0
			}
		}
	};

resource 'FILT' (4016, "Add Noise…", purgeable)
	{
	Procedure
		{
			{
			0,	   noBlank, 1, 999, 32;
			Radio, noBlank, 0,	 1,  0
			}
		}
	};

resource 'FILT' (4017, "Trace Contour…", purgeable)
	{
	Procedure
		{
			{
			0,	   noBlank, 0, 255, 128;
			Radio, noBlank, 0,	 1,   0
			}
		}
	};

resource 'FILT' (4018, "Mosaic…", purgeable)
	{
	Procedure
		{
			{
			0, noBlank, 2, 64, 4
			}
		}
	};

resource 'FILT' (4019, "Sharpen Edges", purgeable)
	{
	Procedure
		{
			{
			}
		}
	};

resource 'FILT' (4020, "Despeckle", purgeable)
	{
	Procedure
		{
			{
			}
		}
	};

#if !Barneyscan

resource 'FILT' (4021, "Unsharp Mask…", purgeable)
	{
	Procedure
		{
			{
			0, noBlank, 1, 500, 50;
			1, noBlank, 1, 999, 10
			}
		}
	};

#endif

resource 'pltt' (0)
	{
		{
		$FFFF, $FFFF, $FFFF, pmTolerant, 0;
		$0000, $0000, $0000, pmTolerant, 0
		}
	};

resource 'DLOG' (700, purgeable)
	{
	{0, 0, 275, 500},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	700,
	""
	};

resource 'dctb' (700, purgeable)
	{
	0,
	0,
	{}
	};

resource 'DITL' (700, purgeable)
	{
		{
		{0, 0, 220, 500},	  Picture { disabled, 700 },
		{235, 400, 255, 460}, Button { enabled, "OK" },
		{235, 240, 255, 365}, Button { enabled, "About Plug-ins…" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{220, 14, 256, 214},  UserItem { disabled }
		}
	};

resource 'pltt' (700, purgeable)
	{
		{
		$FFFF, $FFFF, $FFFF, pmTolerant, 0;
		$0000, $0000, $0000, pmTolerant, 0;
		$1111, $1111, $1111, pmTolerant, 0;
		$2222, $2222, $2222, pmTolerant, 0;
		$3333, $3333, $3333, pmTolerant, 0;
		$4444, $4444, $4444, pmTolerant, 0;
		$5555, $5555, $5555, pmTolerant, 0;
		$6666, $6666, $6666, pmTolerant, 0;
		$7777, $7777, $7777, pmTolerant, 0;
		$8888, $8888, $8888, pmTolerant, 0;
		$9999, $9999, $9999, pmTolerant, 0;
		$AAAA, $AAAA, $AAAA, pmTolerant, 0;
		$BBBB, $BBBB, $BBBB, pmTolerant, 0;
		$CCCC, $CCCC, $CCCC, pmTolerant, 0;
		$DDDD, $DDDD, $DDDD, pmTolerant, 0;
		$EEEE, $EEEE, $EEEE, pmTolerant, 0
		}
	};

resource 'DLOG' (701, purgeable)
	{
	{0, 0, 275, 500},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	701,
	""
	};

resource 'DITL' (701, purgeable)
	{
		{
		{0, 0, 220, 500},	  Picture { disabled, 701 },
		{235, 400, 255, 460}, Button { enabled, "OK" },
		{235, 240, 255, 365}, Button { enabled, "About Plug-ins…" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{220, 14, 256, 214},  UserItem { disabled }
		}
	};

resource 'DLOG' (710, purgeable)
	{
	{0, 0, 270, 500},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	710,
	""
	};

resource 'dctb' (710, purgeable)
	{
	0,
	0,
	{}
	};

resource 'DITL' (710, purgeable)
	{
		{
		{0, 0, 220, 500},	  Picture { disabled, 700 },
		{220, 14, 256, 214},  UserItem { disabled }
		}
	};

resource 'pltt' (710, purgeable)
	{
		{
		$FFFF, $FFFF, $FFFF, pmTolerant, 0;
		$0000, $0000, $0000, pmTolerant, 0;
		$1111, $1111, $1111, pmTolerant, 0;
		$2222, $2222, $2222, pmTolerant, 0;
		$3333, $3333, $3333, pmTolerant, 0;
		$4444, $4444, $4444, pmTolerant, 0;
		$5555, $5555, $5555, pmTolerant, 0;
		$6666, $6666, $6666, pmTolerant, 0;
		$7777, $7777, $7777, pmTolerant, 0;
		$8888, $8888, $8888, pmTolerant, 0;
		$9999, $9999, $9999, pmTolerant, 0;
		$AAAA, $AAAA, $AAAA, pmTolerant, 0;
		$BBBB, $BBBB, $BBBB, pmTolerant, 0;
		$CCCC, $CCCC, $CCCC, pmTolerant, 0;
		$DDDD, $DDDD, $DDDD, pmTolerant, 0;
		$EEEE, $EEEE, $EEEE, pmTolerant, 0
		}
	};

resource 'DLOG' (711, purgeable)
	{
	{0, 0, 270, 500},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	711,
	""
	};

resource 'DITL' (711, purgeable)
	{
		{
		{0, 0, 220, 500},	  Picture { disabled, 701 },
		{220, 14, 256, 214},  UserItem { disabled }
		}
	};

resource 'DLOG' (750, purgeable)
	{
	{0, 0, 155, 370},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	750,
	""
	};

resource 'DITL' (750, purgeable)
	{
		{
		{120, 60, 140, 130},  Button { enabled, "OK" },
		{120, 240, 140, 310}, Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{36, 120, 52, 340},   EditText { enabled, "" },
		{62, 120, 78, 340},   EditText { enabled, "" },
		{88, 120, 104, 270},  EditText { enabled, "" },
		{10, 10, 26, 360},	  StaticText { disabled,
							  "Please personalize your copy of "
							  FullName ":" },
		{36, 67, 52, 115},	  StaticText { enabled, "Name:" },
		{62, 20, 78, 115},	  StaticText { enabled, "Organization:" },
		{88, 53, 104, 115},   StaticText { enabled, "Serial #:" }
		}
	};

resource 'DLOG' (751, purgeable)
	{
	{0, 0, 100, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	751,
	""
	};

resource 'DITL' (751, purgeable)
	{
		{
		{60, 210, 80, 280},   Button { enabled, "OK" },
		{10, 20, 42, 52},	  Icon { disabled, 0 },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 62, 42, 300},	  StaticText { disabled,
							  "You are required to enter your name." }
		}
	};

resource 'DLOG' (752, purgeable)
	{
	{0, 0, 120, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	752,
	""
	};

resource 'DITL' (752, purgeable)
	{
		{
		{80, 210, 100, 280},  Button { enabled, "OK" },
		{10, 20, 42, 52},	  Icon { disabled, 0 },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 62, 58, 300},	  StaticText { disabled,
							  "At most 63 characters are allowed here.  "
							  "The extra characters have been deleted." }
		}
	};

resource 'DLOG' (753, purgeable)
	{
	{0, 0, 100, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	753,
	""
	};

resource 'DITL' (753, purgeable)
	{
		{
		{60, 210, 80, 280},   Button { enabled, "OK" },
		{10, 20, 42, 52},	  Icon { disabled, 0 },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 62, 42, 300},	  StaticText { disabled,
							  "You are required to enter the serial number." }
		}
	};

resource 'DLOG' (754, purgeable)
	{
	{0, 0, 100, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	754,
	""
	};

resource 'DITL' (754, purgeable)
	{
		{
		{60, 210, 80, 280},   Button { enabled, "OK" },
		{10, 20, 42, 52},	  Icon { disabled, 0 },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 62, 42, 300},	  StaticText { disabled,
							  "An invalid serial number has been entered." }
		}
	};

resource 'DLOG' (800, purgeable)
	{
	{0, 0, 130, 292},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	800,
	""
	};

resource 'DITL' (800, purgeable)
	{
		{
		{68, 25, 86, 99},	  Button { enabled, "Yes" },
		{96, 195, 114, 269},  Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{96, 25, 114, 99},	  Button { enabled, "No" },
		{10, 20, 58, 277},	  StaticText { disabled,
							  "Save changes to “^0” before quitting?" }
		}
	};

resource 'DLOG' (801, purgeable)
	{
	{0, 0, 130, 292},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	801,
	""
	};

resource 'DITL' (801, purgeable)
	{
		{
		{68, 25, 86, 99},	  Button { enabled, "Yes" },
		{96, 195, 114, 269},  Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{96, 25, 114, 99},	  Button { enabled, "No" },
		{10, 20, 58, 277},	  StaticText { disabled,
							  "Save changes to “^0” before closing?" }
		}
	};

resource 'DLOG' (802, purgeable)
	{
	{0, 0, 155, 290},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	802,
	""
	};

resource 'DITL' (802, purgeable)
	{
		{
		{120, 215, 140, 275}, Button { enabled, "Cancel" },
		{10, 20, 42, 52},	  Icon { disabled, 0 },
		{0, 0, 0, 0},		  UserItem { disabled },
		{128, 10, 140, 200},  UserItem { disabled },
		{10, 70, 106, 275},   StaticText { disabled,
							  "Could not ^2 because ^0.  ^1" }
		}
	};

resource 'DLOG' (803, purgeable)
	{
	{0, 0, 155, 290},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	803,
	""
	};

resource 'DITL' (803, purgeable)
	{
		{
		{120, 215, 140, 275}, Button { enabled, "Cancel" },
		{10, 20, 42, 52},	  Icon { disabled, 0 },
		{0, 0, 0, 0},		  UserItem { disabled },
		{128, 10, 140, 200},  UserItem { disabled },
		{10, 70, 106, 275},   StaticText { disabled,
							  "Could not complete the “^2” command"
							  " because ^0.  ^1" }
		}
	};

resource 'DLOG' (804, purgeable)
	{
	{0, 0, 155, 290},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	804,
	""
	};

resource 'DITL' (804, purgeable)
	{
		{
		{120, 215, 140, 275}, Button { enabled, "Cancel" },
		{10, 20, 42, 52},	  Icon { disabled, 0 },
		{0, 0, 0, 0},		  UserItem { disabled },
		{128, 10, 140, 200},  UserItem { disabled },
		{10, 70, 106, 275},   StaticText { disabled,
							  "Could not complete your request because "
							  "^0.  ^1" }
		}
	};

resource 'DLOG' (901, purgeable)
	{
	{0, 0, 120, 292},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	901,
	""
	};

resource 'DITL' (901, purgeable)
	{
		{
		{58, 25, 76, 99},	  Button { enabled, "Yes" },
		{86, 195, 104, 269},  Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{86, 25, 104, 99},	  Button { enabled, "No" },
		{12, 20, 45, 277},	  StaticText { disabled,
							  "This image has non-square pixels;"
							  " adjust aspect ratio?" }
		}
	};

resource 'DLOG' (902, purgeable)
	{
	{0, 0, 100, 360},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	902,
	""
	};

resource 'DITL' (902, purgeable)
	{
		{
		{60, 80, 80, 150},	  Button { enabled, "OK" },
		{60, 250, 80, 320},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 20, 42, 52},	  Icon { disabled, 2 },
		{10, 62, 42, 340},	  StaticText { disabled,
							  "Revert to the previously saved version"
							  " of “^0”?" }
		}
	};

resource 'DLOG' (903, purgeable)
	{
	{0, 0, 100, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	903,
	""
	};

resource 'DITL' (903, purgeable)
	{
		{
		{60, 210, 80, 280},   Button { enabled, "Cancel" },
		{10, 20, 42, 52},	  Icon { disabled, 0 },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 62, 42, 300},	  StaticText { disabled,
							  "A maximum of four characters are allowed." }
		}
	};

resource 'DLOG' (904, purgeable)
	{
	{0, 0, 60, 200},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	904,
	""
	};

resource 'DITL' (904, purgeable)
	{
		{
		{10, 20, 42, 180},	  StaticText { disabled,
							  "Converting clipboard to PICT format…" }
		}
	};

resource 'DLOG' (905, purgeable)
	{
	{0, 0, 60, 330},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	905,
	""
	};

resource 'DITL' (905, purgeable)
	{
		{
		{10, 20, 42, 52},	  Icon { disabled, 0 },
		{10, 62, 42, 310},	  StaticText { disabled,
							  "Clipboard conversion failed because ^0." }
		}
	};

resource 'DLOG' (906, purgeable)
	{
	{0, 0, 60, 220},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	906,
	""
	};

resource 'DITL' (906, purgeable)
	{
		{
		{10, 20, 42, 200},	  StaticText { disabled,
							  "Converting clipboard from PICT format…" }
		}
	};

resource 'DLOG' (907, purgeable)
	{
	{0, 0, 100, 300},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	907,
	""
	};

resource 'DITL' (907, purgeable)
	{
		{
		{60, 50, 80, 120},	  Button { enabled, "OK" },
		{60, 180, 80, 250},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 20, 42, 52},	  Icon { disabled, 2 },
		{10, 62, 42, 280},	  StaticText { disabled,
							  "Discard color information?" }
		}
	};

resource 'DLOG' (908, purgeable)
	{
	{0, 0, 100, 360},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	908,
	""
	};

resource 'DITL' (908, purgeable)
	{
		{
		{60, 50, 80, 120},	  Button { enabled, "OK" },
		{60, 180, 80, 250},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 20, 42, 52},	  Icon { disabled, 2 },
		{10, 62, 42, 280},	  StaticText { disabled,
							  "Discard other channel?" }
		}
	};

resource 'DLOG' (909, purgeable)
	{
	{0, 0, 100, 300},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	909,
	""
	};

resource 'DITL' (909, purgeable)
	{
		{
		{60, 50, 80, 120},	  Button { enabled, "OK" },
		{60, 180, 80, 250},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 20, 42, 52},	  Icon { disabled, 2 },
		{10, 62, 42, 280},	  StaticText { disabled,
							  "Discard other channels?" }
		}
	};

resource 'DLOG' (910, purgeable)
	{
	{0, 0, 100, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	910,
	""
	};

resource 'DITL' (910, purgeable)
	{
		{
		{60, 210, 80, 280},   Button { enabled, "Cancel" },
		{10, 20, 42, 52},	  Icon { disabled, 0 },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 62, 42, 300},	  StaticText { disabled,
							  "A document is selected for more"
									" than one channel." }
		}
	};

resource 'DLOG' (911, purgeable)
	{
	{0, 0, 100, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	911,
	""
	};

resource 'DITL' (911, purgeable)
	{
		{
		{60, 210, 80, 280},   Button { enabled, "Cancel" },
		{10, 20, 42, 52},	  Icon { disabled, 0 },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 62, 42, 300},	  StaticText { disabled,
							  "An RGB result cannot be stored in a single"
							  " channel destination." }
		}
	};

resource 'DLOG' (912, purgeable)
	{
	{0, 0, 100, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	912,
	""
	};

resource 'DITL' (912, purgeable)
	{
		{
		{60, 210, 80, 280},   Button { enabled, "Cancel" },
		{10, 20, 42, 52},	  Icon { disabled, 0 },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 62, 42, 300},	  StaticText { disabled,
							  "A single channel result cannot be stored in"
							  " an RGB destination." }
		}
	};

resource 'DLOG' (913, purgeable)
	{
	{0, 0, 100, 340},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	913,
	""
	};

resource 'DITL' (913, purgeable)
	{
		{
		{60, 210, 80, 280},   Button { enabled, "OK" },
		{10, 20, 42, 52},	  Icon { disabled, 2 },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 62, 42, 320},	  StaticText { disabled,
							  "Due to limited memory, some editing"
							  " operations may not be possible." }
		}
	};

resource 'DLOG' (914, purgeable)
	{
	{0, 0, 100, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	914,
	""
	};

resource 'DITL' (914, purgeable)
	{
		{
		{60, 210, 80, 280},   Button { enabled, "Cancel" },
		{10, 20, 42, 52},	  Icon { disabled, 0 },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 62, 42, 300},	  StaticText { disabled,
							  "^0 between ^1 and ^2 is required." }
		}
	};

resource 'DLOG' (915, purgeable)
	{
	{0, 0, 120, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	915,
	""
	};

resource 'DITL' (915, purgeable)
	{
		{
		{80, 210, 100, 280},  Button { enabled, "OK" },
		{10, 20, 42, 52},	  Icon { disabled, 0 },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 62, 58, 300},	  StaticText { disabled,
							  "^0 between ^1 and ^2 is required.  "
							  "Closest value inserted." }
		}
	};

resource 'DLOG' (916, purgeable)
	{
	{0, 0, 90, 300},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	916,
	""
	};

resource 'DITL' (916, purgeable)
	{
		{
		{50, 50, 70, 120},	  Button { enabled, "Yes" },
		{50, 180, 70, 250},   Button { enabled, "No" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 15, 26, 280},	  StaticText { disabled,
							  "Convert large clipboard to PICT format?" }
		}
	};

resource 'DLOG' (917, purgeable)
	{
	{0, 0, 100, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	917,
	""
	};

resource 'DITL' (917, purgeable)
	{
		{
		{60, 50, 80, 120},	  Button { enabled, "Proceed" },
		{60, 200, 80, 270},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 20, 42, 52},	  Icon { disabled, 2 },
		{10, 62, 42, 300},	  StaticText { disabled,
							  "Note:  This setting is ignored by the"
							  " currently selected printer." }
		}
	};

resource 'DLOG' (918, purgeable)
	{
	{0, 0, 100, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	918,
	""
	};

resource 'DITL' (918, purgeable)
	{
		{
		{60, 50, 80, 120},	  Button { enabled, "Proceed" },
		{60, 200, 80, 270},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 20, 42, 52},	  Icon { disabled, 2 },
		{10, 62, 42, 300},	  StaticText { disabled,
							  "Note:  These settings are ignored by the"
							  " currently selected printer." }
		}
	};

resource 'DLOG' (919, purgeable)
	{
	{0, 0, 120, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	919,
	""
	};

resource 'DITL' (919, purgeable)
	{
		{
		{80, 210, 100, 280},  Button { enabled, "OK" },
		{10, 20, 42, 52},	  Icon { disabled, 0 },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 62, 58, 300},	  StaticText { disabled,
							  "At most 255 characters are allowed here.  "
							  "The extra characters have been deleted." }
		}
	};

resource 'DLOG' (920, purgeable)
	{
	{0, 0, 100, 380},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	920,
	""
	};

resource 'DITL' (920, purgeable)
	{
		{
		{60, 80, 80, 150},	  Button { enabled, "Proceed" },
		{60, 230, 80, 300},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 20, 42, 52},	  Icon { disabled, 2 },
		{10, 62, 42, 360},	  StaticText { disabled,
							  "The image is larger than the paper’s "
							  "printable area; some clipping will occur." }
		}
	};

resource 'DLOG' (921, purgeable)
	{
	{0, 0, 100, 380},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	921,
	""
	};

resource 'DITL' (921, purgeable)
	{
		{
		{60, 80, 80, 150},	  Button { enabled, "Proceed" },
		{60, 230, 80, 300},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 20, 42, 52},	  Icon { disabled, 2 },
		{10, 62, 42, 360},	  StaticText { disabled,
							  "The selected area is larger than the paper’s "
							  "printable area; some clipping will occur." }
		}
	};

resource 'DLOG' (922, purgeable)
	{
	{0, 0, 100, 300},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	922,
	""
	};

resource 'DITL' (922, purgeable)
	{
		{
		{60, 50, 80, 120},	  Button { enabled, "OK" },
		{60, 180, 80, 250},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 20, 42, 52},	  Icon { disabled, 2 },
		{10, 62, 42, 280},	  StaticText { disabled,
							  "Unable to parse PostScript code;"
							  " open PICT preview instead?" }
		}
	};

resource 'DLOG' (924, purgeable)
	{
	{0, 0, 100, 360},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	924,
	""
	};

resource 'DITL' (924, purgeable)
	{
		{
		{60, 80, 80, 150},	  Button { enabled, "OK" },
		{60, 250, 80, 320},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 20, 42, 52},	  Icon { disabled, 2 },
		{10, 62, 42, 340},	  StaticText { disabled,
							  "This document is already open; "
							  "create another window for the document?" }
		}
	};

resource 'DLOG' (925, purgeable)
	{
	{0, 0, 120, 360},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	925,
	""
	};

resource 'DITL' (925, purgeable)
	{
		{
		{80, 80, 100, 150},   Button { enabled, "OK" },
		{80, 250, 100, 320},  Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 20, 42, 52},	  Icon { disabled, 0 },
		{10, 62, 58, 340},	  StaticText { disabled,
							  "Could not save part ^1 because ^0."
							  "  Try again?" }
		}
	};

resource 'DLOG' (926, purgeable)
	{
	{0, 0, 100, 360},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	926,
	""
	};

resource 'DITL' (926, purgeable)
	{
		{
		{60, 80, 80, 150},	  Button { enabled, "OK" },
		{60, 250, 80, 320},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 20, 42, 52},	  Icon { disabled, 2 },
		{10, 62, 42, 340},	  StaticText { disabled,
							  "The document is too large to fit on the"
							  " selected disk; save on multiple disks?" }
		}
	};

resource 'DLOG' (927, purgeable)
	{
	{0, 0, 100, 390},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	927,
	""
	};

resource 'DITL' (927, purgeable)
	{
		{
		{60, 80, 80, 150},	  Button { enabled, "Proceed" },
		{60, 240, 80, 310},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 20, 42, 52},	  Icon { disabled, 2 },
		{10, 62, 42, 375},	  StaticText { disabled,
							  "The image’s resolution is higher than 2.5 times "
							  "the halftone screen frequency.  Print anyway?" }
		}
	};

resource 'DLOG' (928, purgeable)
	{
	{0, 0, 100, 380},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	928,
	""
	};

resource 'DITL' (928, purgeable)
	{
		{
		{60, 80, 80, 150},	  Button { enabled, "Proceed" },
		{60, 230, 80, 300},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 20, 42, 52},	  Icon { disabled, 2 },
		{10, 62, 42, 365},	  StaticText { disabled,
							  "The new image size is smaller than the existing "
							  "image size; some clipping will occur." }
		}
	};

resource 'DLOG' (950, purgeable)
	{
	{0, 0, 48, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	950,
	""
	};

resource 'DITL' (950, purgeable)
	{
		{
		{4, 7, 20, 313},	  UserItem { disabled },
		{28, 10, 38, 310},	  UserItem { disabled }
		}
	};

resource 'DLOG' (1001, purgeable)
	{
	{0, 0, 190, 370},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1001,
	""
	};

resource 'DITL' (1001, purgeable)
	{
		{
		{15, 295, 35, 355},   Button { enabled, "OK" },
		{45, 295, 65, 355},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{38, 95, 54, 160},	  EditText { enabled, "" },
		{38, 170, 54, 285},   UserItem { enabled },
		{64, 95, 80, 160},	  EditText { enabled, "" },
		{64, 170, 80, 285},   UserItem { enabled },
		{90, 95, 106, 160},   EditText { enabled, "" },
		{90, 170, 106, 285},  UserItem { enabled },
		{140, 30, 156, 150},  RadioButton { enabled, "Gray Scale" },
		{156, 30, 172, 150},  RadioButton { enabled, "RGB Color" },
		{10, 10, 26, 280},	  StaticText { disabled, "New…" },
		{38, 41, 54, 90},	  StaticText { enabled, "Width:" },
		{64, 37, 80, 90},	  StaticText { enabled, "Height:" },
		{90, 10, 106, 90},	  StaticText { enabled, "Resolution:" },
		{120, 10, 136, 90},   StaticText { disabled, "Mode:" }
		}
	};

resource 'DLOG' (1002, purgeable)
	{
	{0, 0, 278, 500},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1002,
	""
	};

resource 'DITL' (1002, purgeable)
	{
		{
		{15, 425, 35, 485},   Button { enabled, "OK" },
		{45, 425, 65, 485},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{52, 30, 68, 190},	  CheckBox { enabled, "Colored separations" },
		{72, 30, 88, 190},	  CheckBox { enabled, "Use system palette" },
		{92, 30, 108, 190},   CheckBox { enabled, "Use DirectSetEntries" },
		{136, 30, 152, 240},  RadioButton { enabled, "Disabled" },
		{152, 30, 168, 240},  RadioButton { enabled, "1 bit/pixel" },
		{168, 30, 184, 240},  RadioButton { enabled, "2 bits/pixel" },
		{184, 30, 200, 240},  RadioButton { enabled, "4 bits/pixel" },
		{200, 30, 216, 240},  RadioButton { enabled, "8 bits/pixel" },
		{216, 30, 232, 240},  RadioButton { enabled,
							  "8 bits/pixel, System Palette" },
		{232, 30, 248, 240},  RadioButton { enabled, "16 bits/pixel" },
		{248, 30, 264, 240},  RadioButton { enabled, "32 bits/pixel" },
		{180, 280, 196, 430}, RadioButton { enabled, "Nearest Neighbor" },
		{196, 280, 212, 430}, RadioButton { enabled, "Bilinear" },
		{212, 280, 228, 430}, RadioButton { enabled, "Bicubic" },
		{98, 325, 114, 365},  EditText { enabled, "" },
		{98, 375, 114, 460},  UserItem { enabled },
		{126, 325, 142, 365}, EditText { enabled, "" },
		{126, 375, 142, 460}, UserItem { enabled },
#if Barneyscan
		{-80, 240, -60, 390}, Button { enabled, "Separation Setup…" },
#else
		{25, 240, 45, 390},   Button { enabled, "Separation Setup…" },
#endif
		{10, 10, 26, 190},	  StaticText { disabled, "Preferences…" },
		{32, 10, 48, 190},	  StaticText { disabled, "Display:" },
		{116, 10, 132, 190},  StaticText { disabled, "Clipboard Export:" },
		{74, 260, 90, 400},   StaticText { disabled, "Column Size:" },
		{160, 260, 176, 430}, StaticText { disabled, "Interpolation Method:" },
		{98, 274, 114, 320},  StaticText { enabled, "Width:" },
		{126, 270, 142, 320}, StaticText { enabled, "Gutter:" }
		}
	};

resource 'DLOG' (1003, purgeable)
	{
	{0, 0, 110, 250},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1003,
	""
	};

resource 'DITL' (1003, purgeable)
	{
		{
		{15, 175, 35, 235},   Button { enabled, "OK" },
		{45, 175, 65, 235},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{36, 70, 52, 100},	  EditText { enabled, "" },
		{60, 20, 76, 150},	  RadioButton { enabled, "Magnification" },
		{76, 20, 92, 150},	  RadioButton { enabled, "Reduction" },
		{10, 10, 26, 150},	  StaticText { disabled, "Zoom Factor…" },
		{36, 10, 52, 60},	  StaticText { enabled, "Factor:" }
		}
	};

resource 'DLOG' (1004, purgeable)
	{
	{0, 0, 90, 260},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1004,
	""
	};

resource 'DITL' (1004, purgeable)
	{
		{
		{15, 185, 35, 245},   Button { enabled, "OK" },
		{45, 185, 65, 245},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{44, 70, 60, 100},	  EditText { enabled, "" },
		{44, 10, 60, 60},	  StaticText { enabled, "Radius:" },
		{44, 110, 60, 170},   StaticText { disabled, "(pixels)" },
		{10, 10, 26, 165},	  StaticText { disabled, "Feather…" }
		}
	};

resource 'DLOG' (1005, purgeable)
	{
	{0, 0, 90, 290},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1005,
	""
	};

resource 'DITL' (1005, purgeable)
	{
		{
		{15, 215, 35, 275},   Button { enabled, "OK" },
		{45, 215, 65, 275},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{44, 60, 60, 105},	  EditText { enabled, "" },
		{36, 115, 52, 175},   RadioButton { enabled, "°CW" },
		{52, 115, 68, 175},   RadioButton { enabled, "°CCW" },
		{44, 10, 60, 55},	  StaticText { enabled, "Angle:" },
		{10, 10, 26, 150},	  StaticText { disabled, "Arbitrary Rotate…" }
		}
	};

resource 'DLOG' (1006, purgeable)
	{
	{0, 0, 300, 370},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1006,
	""
	};

resource 'dctb' (1006, purgeable)
	{
	0,
	0,
	{}
	};

resource 'DITL' (1006, purgeable)
	{
		{
		{15, 295, 35, 355},   Button { enabled, "OK" },
		{45, 295, 65, 355},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{30, 10, 288, 268},   UserItem { disabled },
		{90, 295, 110, 355},  Button { enabled, "Load…" },
		{116, 295, 136, 355}, Button { enabled, "Save…" },
		{6, 10, 22, 150},	  StaticText { disabled, "Edit Table…" }
		}
	};

resource 'DLOG' (1007, purgeable)
	{
	{0, 0, 90, 260},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1007,
	""
	};

resource 'DITL' (1007, purgeable)
	{
		{
		{15, 185, 35, 245},   Button { enabled, "OK" },
		{45, 185, 65, 245},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{44, 65, 60, 95},	  EditText { enabled, "" },
		{44, 10, 60, 55},	  StaticText { enabled, "Width:" },
		{44, 105, 60, 165},   StaticText { disabled, "(pixels)" },
		{10, 10, 26, 165},	  StaticText { disabled, "Fringe…" }
		}
	};

resource 'DLOG' (1009, purgeable)
	{
	{0, 0, 275, 500},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1009,
	""
	};

resource 'dctb' (1009, purgeable)
	{
	0,
	0,
	{}
	};

resource 'DITL' (1009, purgeable)
	{
		{
		{15, 425, 35, 485},   Button { enabled, "OK" },
		{45, 425, 65, 485},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{15, 300, 35, 380},   Button { enabled, "Load…" },
		{45, 300, 65, 380},   Button { enabled, "Save…" },
		{40, 35, 90, 85},	  UserItem { enabled },
		{40, 115, 90, 165},   UserItem { enabled },
		{40, 195, 90, 245},   UserItem { enabled },
		{125, 35, 175, 85},   UserItem { enabled },
		{125, 115, 175, 165}, UserItem { enabled },
		{125, 195, 175, 245}, UserItem { enabled },
		{210, 115, 260, 165}, UserItem { enabled },
		{98, 40, 114, 68},	  EditText { enabled, "" },
		{98, 120, 114, 148},  EditText { enabled, "" },
		{98, 200, 114, 228},  EditText { enabled, "" },
		{183, 40, 199, 68},   EditText { enabled, "" },
		{183, 120, 199, 148}, EditText { enabled, "" },
		{183, 200, 199, 228}, EditText { enabled, "" },
		{225, 173, 241, 201}, EditText { enabled, "" },
		{190, 405, 206, 435}, EditText { enabled, "" },
		{100, 420, 116, 455}, EditText { enabled, "" },
		{160, 280, 176, 402}, StaticText { disabled, "Black Generation:" },
		{160, 403, 176, 495}, UserItem { enabled },
		{220, 405, 236, 435}, EditText { enabled, "" },
		{10, 10, 26, 140},	  StaticText { disabled, "Separation Setup…" },
		{55, 10, 71, 35},	  StaticText { disabled, "  C:" },
		{55, 91, 71, 115},	  StaticText { disabled, " M:" },
		{55, 175, 71, 195},   StaticText { disabled, " Y:" },
		{140, 8, 156, 35},	  StaticText { disabled, "MY:" },
		{140, 92, 156, 115},  StaticText { disabled, "CY:" },
		{140, 168, 156, 195}, StaticText { disabled, "CM:" },
		{225, 78, 241, 115},  StaticText { disabled, "CMY:" },
		{98, 73, 114, 93},	  StaticText { disabled, "%" },
		{98, 153, 114, 173},  StaticText { disabled, "%" },
		{98, 233, 114, 253},  StaticText { disabled, "%" },
		{183, 73, 199, 93},   StaticText { disabled, "%" },
		{183, 153, 199, 173}, StaticText { disabled, "%" },
		{183, 233, 199, 253}, StaticText { disabled, "%" },
		{225, 206, 241, 226}, StaticText { disabled, "%" },
		{190, 296, 206, 400}, StaticText { enabled, "Total Ink Limit:" },
		{190, 440, 206, 460}, StaticText { disabled, "%" },
		{100, 302, 116, 415}, StaticText { enabled, "Monitor Gamma:" },
		{220, 262, 236, 400}, StaticText { enabled, "Undercolor Addition:" },
		{220, 440, 236, 460}, StaticText { disabled, "%" }
		}
	};

resource 'pltt' (1009, purgeable)
	{
		{
		$FFFF, $FFFF, $FFFF, pmTolerant, 0;
		$0000, $0000, $0000, pmTolerant, 0;
		$0000, $FFFF, $FFFF, pmTolerant, 0;
		$FFFF, $0000, $FFFF, pmTolerant, 0;
		$FFFF, $FFFF, $0000, pmTolerant, 0;
		$FFFF, $0000, $0000, pmTolerant, 0;
		$0000, $FFFF, $0000, pmTolerant, 0;
		$0000, $0000, $FFFF, pmTolerant, 0;
		$8000, $8000, $8000, pmTolerant, 0;
		$0000, $0000, $0000, pmTolerant, 0
		}
	};

resource 'DLOG' (1011, purgeable)
	{
	{0, 0, 85, 290},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1011,
	""
	};

resource 'DITL' (1011, purgeable)
	{
		{
		{15, 215, 35, 275},   Button { enabled, "OK" },
		{45, 215, 65, 275},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{38, 62, 54, 100},	  EditText { enabled, "" },
		{38, 110, 54, 195},   UserItem { enabled },
		{10, 10, 26, 120},	  StaticText { disabled, "Trap…" },
		{38, 10, 54, 55},	  StaticText { enabled, "Width:" }
		}
	};

resource 'DLOG' (1012, purgeable)
	{
	{0, 0, 235, 370},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1012,
	""
	};

resource 'DITL' (1012, purgeable)
	{
		{
		{15, 295, 35, 355},   Button { enabled, "OK" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{30, 15, 132, 271},   UserItem { disabled },
		{54, 295, 70, 360},   RadioButton { enabled, "Gray" },
		{70, 295, 86, 360},   RadioButton { enabled, "Red" },
		{86, 295, 102, 360},  RadioButton { enabled, "Green" },
		{102, 295, 118, 360}, RadioButton { enabled, "Blue" },
		{144, 100, 160, 150}, UserItem { disabled },
		{164, 100, 180, 150}, UserItem { disabled },
		{184, 100, 200, 130}, UserItem { disabled },
		{204, 100, 220, 180}, UserItem { disabled },
		{150, 280, 166, 310}, UserItem { disabled },
		{170, 280, 186, 360}, UserItem { disabled },
		{190, 280, 206, 330}, UserItem { disabled },
		{10, 15, 26, 115},	  StaticText { disabled, "Histogram…" },
		{144, 49, 160, 100},  StaticText { disabled, "Mean:" },
		{164, 36, 180, 100},  StaticText { disabled, "Std Dev:" },
		{184, 37, 200, 100},  StaticText { disabled, "Median:" },
		{204, 46, 220, 100},  StaticText { disabled, "Pixels:" },
		{150, 230, 166, 280}, StaticText { disabled, "Level:" },
		{170, 227, 186, 280}, StaticText { disabled, "Count:" },
		{190, 198, 206, 280}, StaticText { disabled, "Percentile:" }
		}
	};

resource 'DLOG' (1013, purgeable)
	{
	{0, 0, 294, 420},
	50,
	invisible,
	noGoAway,
	0x0,
	1013,
	"Type"
	};

resource 'DITL' (1013, purgeable)
	{
		{
		{15, 345, 35, 405},   Button { enabled, "OK" },
		{45, 345, 65, 405},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{188, 15, 284, 405},  EditText { enabled, "" },
		{10, 32, 26, 74},	  StaticText { disabled, "Font:" },
		{10, 75, 26, 325},	  UserItem { enabled },
		{36, 77, 52, 117},	  EditText { enabled, "" },
		{36, 127, 52, 200},   UserItem { enabled },
		{62, 77, 78, 117},	  EditText { enabled, "" },
		{88, 77, 104, 117},   EditText { enabled, "" },
		{130, 30, 146, 120},  CheckBox { enabled, "Bold" },
		{146, 30, 162, 120},  CheckBox { enabled, "Italic" },
		{162, 30, 178, 120},  CheckBox { enabled, "Underline" },
		{130, 130, 146, 230}, CheckBox { enabled, "Outline" },
		{146, 130, 162, 230}, CheckBox { enabled, "Shadow" },
		{162, 130, 178, 230}, CheckBox { enabled, "Anti-aliased" },
		{130, 280, 146, 350}, RadioButton { enabled, "Left" },
		{146, 280, 162, 350}, RadioButton { enabled, "Center" },
		{162, 280, 178, 350}, RadioButton { enabled, "Right" },
		{36, 34, 52, 70},	  StaticText { enabled, "Size:" },
		{62, 10, 78, 70},	  StaticText { enabled, "Leading:" },
		{88, 11, 104, 70},	  StaticText { enabled, "Spacing:" },
		{112, 10, 128, 60},   StaticText { disabled, "Style:" },
		{112, 260, 128, 340}, StaticText { disabled, "Alignment:" }
		}
	};

resource 'DLOG' (1014, purgeable)
	{
	{0, 0, 90, 260},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1014,
	""
	};

resource 'DITL' (1014, purgeable)
	{
		{
		{15, 185, 35, 245},   Button { enabled, "OK" },
		{45, 185, 65, 245},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{44, 65, 60, 95},	  EditText { enabled, "" },
		{44, 10, 60, 55},	  StaticText { enabled, "Width:" },
		{44, 105, 60, 165},   StaticText { disabled, "(pixels)" },
		{10, 10, 26, 165},	  StaticText { disabled, "Defringe…" }
		}
	};

resource 'DLOG' (1015, purgeable)
	{
	{0, 0, 294, 500},
	50,
	invisible,
	noGoAway,
	0x0,
	1015,
	"Color Picker"
	};

resource 'dctb' (1015, purgeable)
	{
	0,
	0,
	{}
	};

resource 'DITL' (1015, purgeable)
	{
		{
		{15, 425, 35, 485},   Button { enabled, "OK" },
		{45, 425, 65, 485},   Button { enabled, "Cancel" },
		{24, 13, 280, 269},   UserItem { disabled },
		{24, 284, 280, 304},  UserItem { disabled },
		{24, 325, 104, 385},  UserItem { disabled },
		{41, 392, 56, 408},   UserItem { enabled },
		{124, 321, 140, 353}, RadioButton { enabled, "H:" },
		{149, 321, 165, 353}, RadioButton { enabled, "S:" },
		{174, 321, 190, 353}, RadioButton { enabled, "B:" },
		{212, 321, 228, 353}, RadioButton { enabled, "R:" },
		{237, 321, 253, 353}, RadioButton { enabled, "G:" },
		{262, 321, 278, 353}, RadioButton { enabled, "B:" },
		{124, 358, 140, 388}, EditText { enabled, "" },
		{149, 358, 165, 388}, EditText { enabled, "" },
		{174, 358, 190, 388}, EditText { enabled, "" },
		{212, 358, 228, 388}, EditText { enabled, "" },
		{237, 358, 253, 388}, EditText { enabled, "" },
		{262, 358, 278, 388}, EditText { enabled, "" },
		{124, 441, 140, 471}, EditText { enabled, "" },
		{149, 441, 165, 471}, EditText { enabled, "" },
		{174, 441, 190, 471}, EditText { enabled, "" },
		{199, 441, 215, 471}, EditText { enabled, "" },
		{124, 417, 140, 438}, StaticText { enabled, " C:" },
		{149, 417, 165, 438}, StaticText { enabled, "M:" },
		{174, 417, 190, 438}, StaticText { enabled, " Y:" },
		{199, 416, 215, 438}, StaticText { enabled, " K:" },
		{3, 12, 19, 270},	  StaticText { disabled, "^0" },
		{124, 393, 140, 413}, StaticText { disabled, "°" },
		{149, 393, 165, 413}, StaticText { disabled, "%" },
		{174, 393, 190, 413}, StaticText { disabled, "%" },
		{124, 476, 140, 496}, StaticText { disabled, "%" },
		{149, 476, 165, 496}, StaticText { disabled, "%" },
		{174, 476, 190, 496}, StaticText { disabled, "%" },
		{199, 476, 215, 496}, StaticText { disabled, "%" },
		{0, 0, 0, 0},		  UserItem { disabled }
		}
	};

resource 'DLOG' (1020, purgeable)
	{
#if Barneyscan
	{0, 0, 160, 300},
#else
	{0, 0, 176, 300},
#endif
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1020,
	""
	};

resource 'DITL' (1020, purgeable)
	{
		{
		{15, 225, 35, 285},   Button { enabled, "OK" },
		{45, 225, 65, 285},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
#if Barneyscan
		{126, 85, 142, 110},  EditText { enabled, "" },
		{52, 30, 68, 180},	  RadioButton { enabled, "RGB Color" },
		{-80, 30, -64, 180},  RadioButton { enabled, "CMYK Color" },
		{68, 30, 84, 180},	  RadioButton { enabled, "HSL Color" },
		{84, 30, 100, 180},   RadioButton { enabled, "HSB Color" },
		{100, 30, 116, 180},  RadioButton { enabled, "Multichannel" },
		{126, 10, 142, 75},   StaticText { enabled, "Channels:" },
#else
		{142, 85, 158, 110},  EditText { enabled, "" },
		{52, 30, 68, 180},	  RadioButton { enabled, "RGB Color" },
		{68, 30, 84, 180},	  RadioButton { enabled, "CMYK Color" },
		{84, 30, 100, 180},   RadioButton { enabled, "HSL Color" },
		{100, 30, 116, 180},  RadioButton { enabled, "HSB Color" },
		{116, 30, 132, 180},  RadioButton { enabled, "Multichannel" },
		{142, 10, 158, 75},   StaticText { enabled, "Channels:" },
#endif
		{10, 10, 26, 180},	  StaticText { disabled, "Merge Channels…" },
		{32, 10, 48, 180},	  StaticText { disabled, "Mode:" }
		}
	};

resource 'DLOG' (1021, purgeable)
	{
	{0, 0, 128, 330},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1021,
	""
	};

resource 'DITL' (1021, purgeable)
	{
		{
		{15, 255, 35, 315},   Button { enabled, "OK" },
		{45, 255, 65, 315},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{40, 24, 56, 58},	  StaticText { disabled, "Red:" },
		{40, 59, 56, 225},	  UserItem { disabled },
		{66, 10, 82, 58},	  StaticText { disabled, "Green:" },
		{66, 59, 82, 225},	  UserItem { disabled },
		{92, 20, 108, 58},	  StaticText { disabled, "Blue:" },
		{92, 59, 108, 225},   UserItem { disabled },
		{10, 10, 26, 200},	  StaticText { disabled, "Specify Channels:" }
		}
	};

resource 'DLOG' (1022, purgeable)
	{
	{0, 0, 154, 330},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1022,
	""
	};

resource 'DITL' (1022, purgeable)
	{
		{
		{15, 255, 35, 315},   Button { enabled, "OK" },
		{45, 255, 65, 315},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{40, 36, 56, 78},	  StaticText { disabled, "Cyan:" },
		{40, 79, 56, 225},	  UserItem { disabled },
		{66, 10, 82, 78},	  StaticText { disabled, "Magenta:" },
		{66, 79, 82, 225},	  UserItem { disabled },
		{92, 24, 108, 78},	  StaticText { disabled, "Yellow:" },
		{92, 79, 108, 225},   UserItem { disabled },
		{118, 33, 134, 78},   StaticText { disabled, "Black:" },
		{118, 79, 134, 225},  UserItem { disabled },
		{10, 10, 26, 200},	  StaticText { disabled, "Specify Channels:" }
		}
	};

resource 'DLOG' (1023, purgeable)
	{
	{0, 0, 128, 330},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1023,
	""
	};

resource 'DITL' (1023, purgeable)
	{
		{
		{15, 255, 35, 315},   Button { enabled, "OK" },
		{45, 255, 65, 315},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{40, 55, 56, 89},	  StaticText { disabled, "Hue:" },
		{40, 90, 56, 225},	  UserItem { disabled },
		{66, 10, 82, 89},	  StaticText { disabled, "Saturation:" },
		{66, 90, 82, 225},	  UserItem { disabled },
		{92, 16, 108, 89},	  StaticText { disabled, "Lightness:" },
		{92, 90, 108, 225},   UserItem { disabled },
		{10, 10, 26, 200},	  StaticText { disabled, "Specify Channels:" }
		}
	};

resource 'DLOG' (1024, purgeable)
	{
	{0, 0, 128, 330},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1024,
	""
	};

resource 'DITL' (1024, purgeable)
	{
		{
		{15, 255, 35, 315},   Button { enabled, "OK" },
		{45, 255, 65, 315},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{40, 56, 56, 90},	  StaticText { disabled, "Hue:" },
		{40, 91, 56, 225},	  UserItem { disabled },
		{66, 11, 82, 90},	  StaticText { disabled, "Saturation:" },
		{66, 91, 82, 225},	  UserItem { disabled },
		{92, 10, 108, 90},	  StaticText { disabled, "Brightness:" },
		{92, 91, 108, 225},   UserItem { disabled },
		{10, 10, 26, 200},	  StaticText { disabled, "Specify Channels:" }
		}
	};

resource 'DLOG' (1025, purgeable)
	{
	{0, 0, 85, 330},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1025,
	""
	};

resource 'DITL' (1025, purgeable)
	{
		{
		{15, 255, 35, 315},   Button { enabled, "Next" },
		{45, 255, 65, 315},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{40, 10, 56, 62},	  StaticText { disabled, "Image:" },
		{40, 63, 56, 225},	  UserItem { disabled },
		{-80, 255, -60, 315}, Button { enabled, "OK" },
		{10, 10, 26, 200},	  StaticText { disabled, "Specify Channel ^0:" }
		}
	};

resource 'DLOG' (1030, purgeable)
	{
	{0, 0, 85, 350},
	dBoxProc,
	visible,
	noGoAway,
	0x0,
	1030,
	""
	};

resource 'DITL' (1030, purgeable)
	{
		{
		{15, 275, 35, 335},   Button { enabled, "OK" },
		{45, 275, 65, 335},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{30, 30, 46, 250},	  RadioButton { enabled, "Selected area only" },
		{46, 30, 62, 250},	  RadioButton { enabled,
											"Entire image based on area" },
		{10, 10, 26, 100},	  StaticText { disabled, "Equalize…" }
		}
	};

resource 'DLOG' (1031, purgeable)
	{
	{0, 0, 140, 370},
	50,
	invisible,
	noGoAway,
	0x0,
	1031,
	"Threshold"
	};

resource 'dctb' (1031, purgeable)
	{
	0,
	0,
	{}
	};

resource 'DITL' (1031, purgeable)
	{
		{
		{15, 290, 35, 355},   Button { enabled, "OK" },
		{45, 290, 65, 355},   Button { enabled, "Cancel" },
		{71, 290, 91, 355},   Button { enabled, "Preview" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{28, 15, 122, 271},   UserItem { disabled },
		{8, 180, 24, 216},	  UserItem { disabled },
		{8, 70, 24, 180},	  StaticText { disabled, "Threshold Level:" }
		}
	};

resource 'DLOG' (1032, purgeable)
	{
	{0, 0, 100, 220},
	50,
	invisible,
	noGoAway,
	0x0,
	1032,
	"Posterize"
	};

resource 'dctb' (1032, purgeable)
	{
	0,
	0,
	{}
	};

resource 'DITL' (1032, purgeable)
	{
		{
		{10, 140, 30, 205},   Button { enabled, "OK" },
		{40, 140, 60, 205},   Button { enabled, "Cancel" },
		{66, 140, 86, 205},   Button { enabled, "Preview" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{30, 75, 46, 110},	  EditText { enabled, "" },
		{30, 15, 46, 65},	  StaticText { enabled, "Levels:" },
		}
	};

resource 'DLOG' (1033, purgeable)
	{
	{0, 0, 294, 375},
	50,
	invisible,
	noGoAway,
	0x0,
	1033,
	"Arbitrary Map"
	};

resource 'dctb' (1033, purgeable)
	{
	0,
	0,
	{}
	};

resource 'DITL' (1033, purgeable)
	{
		{
		{15, 295, 35, 360},   Button { enabled, "OK" },
		{45, 295, 65, 360},   Button { enabled, "Cancel" },
		{71, 295, 91, 360},   Button { enabled, "Preview" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{24, 16, 280, 272},   UserItem { disabled },
		{105, 294, 125, 360}, Button { enabled, "Load…" },
		{131, 294, 151, 360}, Button { enabled, "Save…" },
		{2, 90, 18, 117},	  UserItem { disabled },
		{2, 170, 18, 197},	  UserItem { disabled },
		{165, 295, 185, 360}, Button { enabled, "Reset" },
		{191, 295, 211, 360}, Button { enabled, "Smooth" },
		{220, 292, 236, 364}, RadioButton { enabled, "Master" },
		{236, 292, 252, 364}, RadioButton { enabled, "Red" },
		{252, 292, 268, 364}, RadioButton { enabled, "Green" },
		{268, 292, 284, 364}, RadioButton { enabled, "Blue" },
		{2, 70, 18, 90},	  StaticText { disabled, "X:" },
		{2, 150, 18, 170},	  StaticText { disabled, "Y:" }
		}
	};

resource 'DLOG' (1034, purgeable)
	{
	{0, 0, 172, 370},
	50,
	invisible,
	noGoAway,
	0x0,
	1034,
	"Levels"
	};

resource 'dctb' (1034, purgeable)
	{
	0,
	0,
	{}
	};

resource 'DITL' (1034, purgeable)
	{
		{
		{15, 290, 35, 355},   Button { enabled, "OK" },
		{45, 290, 65, 355},   Button { enabled, "Cancel" },
		{71, 290, 91, 355},   Button { enabled, "Preview" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{24, 15, 118, 271},   UserItem { disabled },
		{158, 15, 159, 271},  UserItem { disabled },
		{6, 130, 22, 164},	  UserItem { disabled },
		{6, 164, 22, 210},	  UserItem { disabled },
		{6, 210, 22, 246},	  UserItem { disabled },
		{130, 155, 146, 191}, UserItem { disabled },
		{130, 191, 146, 227}, UserItem { disabled },
		{99,  290, 115, 360}, RadioButton { enabled, "Master" },
		{115, 290, 131, 360}, RadioButton { enabled, "Red" },
		{131, 290, 147, 360}, RadioButton { enabled, "Green" },
		{147, 290, 163, 360}, RadioButton { enabled, "Blue" },
		{148, 14, 159, 272},  Picture { disabled, 1003 },
		{6, 40, 22, 128},	  StaticText { disabled, "Input Levels:" },
		{130, 59, 146, 155},  StaticText { disabled, "Output Levels:" }
		}
	};

resource 'DLOG' (1035, purgeable)
	{
	{0, 0, 120, 450},
	50,
	invisible,
	noGoAway,
	0x0,
	1035,
	"Color Balance"
	};

resource 'dctb' (1035, purgeable)
	{
	0,
	0,
	{}
	};

resource 'DITL' (1035, purgeable)
	{
		{
		{15, 370, 35, 435},   Button { enabled, "OK" },
		{45, 370, 65, 435},   Button { enabled, "Cancel" },
		{71, 370, 91, 435},   Button { enabled, "Preview" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{41, 90, 42, 291},	  UserItem { disabled },
		{57, 90, 58, 291},	  UserItem { disabled },
		{73, 90, 74, 291},	  UserItem { disabled },
		{10, 185, 26, 221},   UserItem { disabled },
		{10, 221, 26, 257},   UserItem { disabled },
		{10, 257, 26, 293},   UserItem { disabled },
		{94, 60, 110, 140},   RadioButton { enabled, "Shadows" },
		{94, 145, 110, 230},  RadioButton { enabled, "Midtones" },
		{94, 233, 110, 320},  RadioButton { enabled, "Highlights" },
		{10, 88, 26, 185},	  StaticText { disabled, "Color Levels:" },
		{36, 41, 52, 75},	  StaticText { disabled, "Cyan" },
		{52, 15, 68, 75},	  StaticText { disabled, "Magenta" },
		{68, 29, 84, 75},	  StaticText { disabled, "Yellow" },
		{36, 306, 52, 350},   StaticText { disabled, "Red" },
		{52, 306, 68, 350},   StaticText { disabled, "Green" },
		{68, 306, 84, 350},   StaticText { disabled, "Blue" }
		}
	};

resource 'DLOG' (1036, purgeable)
	{
	{0, 0, 130, 320},
	50,
	invisible,
	noGoAway,
	0x0,
	1036,
	"Hue/Saturation"
	};

resource 'dctb' (1036, purgeable)
	{
	0,
	0,
	{}
	};

resource 'DITL' (1036, purgeable)
	{
		{
		{15, 240, 35, 305},   Button { enabled, "OK" },
		{45, 240, 65, 305},   Button { enabled, "Cancel" },
		{71, 240, 91, 305},   Button { enabled, "Preview" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{40, 15, 41, 216},	  UserItem { disabled },
		{90, 15, 91, 216},	  UserItem { disabled },
		{14, 112, 30, 148},   UserItem { disabled },
		{64, 133, 80, 169},   UserItem { disabled },
		{101, 235, 117, 320}, CheckBox { enabled, "Colorize" },
		{14, 83, 30, 112},	  StaticText { disabled, "Hue:" },
		{64, 58, 80, 133},	  StaticText { disabled, "Saturation:" }
		}
	};

resource 'DLOG' (1037, purgeable)
	{
	{0, 0, 110, 320},
	50,
	invisible,
	noGoAway,
	0x0,
	1037,
	"Brightness/Contrast"
	};

resource 'dctb' (1037, purgeable)
	{
	0,
	0,
	{}
	};

resource 'DITL' (1037, purgeable)
	{
		{
		{15, 240, 35, 305},   Button { enabled, "OK" },
		{45, 240, 65, 305},   Button { enabled, "Cancel" },
		{71, 240, 91, 305},   Button { enabled, "Preview" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{38, 15, 39, 216},	  UserItem { disabled },
		{84, 15, 85, 216},	  UserItem { disabled },
		{12, 135, 28, 171},   UserItem { disabled },
		{58, 127, 74, 163},   UserItem { disabled },
		{12, 60, 28, 135},	  StaticText { disabled, "Brightness:" },
		{58, 64, 74, 127},	  StaticText { disabled, "Contrast:" }
		}
	};

resource 'DLOG' (1040, purgeable)
	{
	{0, 0, 180, 330},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1040,
	""
	};

resource 'DITL' (1040, purgeable)
	{
		{
		{15, 255, 35, 315},   Button { enabled, "OK" },
		{45, 255, 65, 315},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{40, 41, 56, 95},	  StaticText { disabled, "Source:" },
		{40, 96, 56, 225},	  UserItem { disabled },
		{66, 33, 82, 95},	  StaticText { disabled, "Channel:" },
		{66, 96, 82, 225},	  UserItem { disabled },
		{92, 56, 108, 136},   CheckBox { enabled, "Invert" },
		{118, 10, 134, 95},   StaticText { disabled, "Destination:" },
		{118, 96, 134, 225},  UserItem { disabled },
		{144, 33, 160, 95},   StaticText { disabled, "Channel:" },
		{144, 96, 160, 225},  UserItem { disabled },
		{10, 10, 26, 200},	  StaticText { disabled, "Duplicate…" }
		}
	};

resource 'DLOG' (1041, purgeable)
	{
	{0, 0, 133, 330},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1041,
	""
	};

resource 'DITL' (1041, purgeable)
	{
		{
		{15, 255, 35, 315},   Button { enabled, "OK" },
		{45, 255, 65, 315},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{71, 10, 87, 95},	  StaticText { disabled, "Destination:" },
		{71, 96, 87, 225},	  UserItem { disabled },
		{97, 33, 113, 95},	  StaticText { disabled, "Channel:" },
		{97, 96, 113, 225},   UserItem { disabled },
		{40, 98, 56, 128},	  EditText { enabled, "" },
		{10, 10, 26, 200},	  StaticText { disabled, "Constant…" },
		{40, 50, 56, 95},	  StaticText { enabled, "Level:" },
		}
	};

resource 'DLOG' (1042, purgeable)
	{
	{0, 0, 263, 330},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1042,
	""
	};

resource 'DITL' (1042, purgeable)
	{
		{
		{15, 255, 35, 315},   Button { enabled, "OK" },
		{45, 255, 65, 315},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{40, 12, 56, 97},	  StaticText { disabled, "Foreground:" },
		{40, 98, 56, 225},	  UserItem { disabled },
		{66, 35, 82, 97},	  StaticText { disabled, "Channel:" },
		{66, 98, 82, 225},	  UserItem { disabled },
		{92, 52, 108, 97},	  StaticText { disabled, "Mask:" },
		{92, 98, 108, 225},   UserItem { disabled },
		{118, 35, 134, 97},   StaticText { disabled, "Channel:" },
		{118, 98, 134, 225},  UserItem { disabled },
		{144, 10, 160, 97},   StaticText { disabled, "Background:" },
		{144, 98, 160, 225},  UserItem { disabled },
		{170, 35, 186, 97},   StaticText { disabled, "Channel:" },
		{170, 98, 186, 225},  UserItem { disabled },
		{201, 10, 217, 97},   StaticText { disabled, "Destination:" },
		{201, 98, 217, 225},  UserItem { disabled },
		{227, 35, 243, 97},   StaticText { disabled, "Channel:" },
		{227, 98, 243, 225},  UserItem { disabled },
		{10, 10, 26, 225},	  StaticText { disabled, "Composite…" }
		}
	};

resource 'DLOG' (1043, purgeable)
	{
	{0, 0, 242, 330},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1043,
	""
	};

resource 'DITL' (1043, purgeable)
	{
		{
		{15, 255, 35, 315},   Button { enabled, "OK" },
		{45, 255, 65, 315},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{40, 29, 56, 95},	  StaticText { disabled, "Source 1:" },
		{40, 96, 56, 225},	  UserItem { disabled },
		{66, 33, 82, 95},	  StaticText { disabled, "Channel:" },
		{66, 96, 82, 225},	  UserItem { disabled },
		{92, 29, 108, 95},	  StaticText { disabled, "Source 2:" },
		{92, 96, 108, 225},   UserItem { disabled },
		{118, 33, 134, 95},   StaticText { disabled, "Channel:" },
		{118, 96, 134, 225},  UserItem { disabled },
		{180, 10, 196, 95},   StaticText { disabled, "Destination:" },
		{180, 96, 196, 225},  UserItem { disabled },
		{206, 33, 222, 95},   StaticText { disabled, "Channel:" },
		{206, 96, 222, 225},  UserItem { disabled },
		{149, 98, 165, 128},  EditText { enabled, "" },
		{10, 10, 26, 200},	  StaticText { disabled, "Blend…" },
		{149, 14, 165, 95},   StaticText { enabled, "Source 1 %:" }
		}
	};

resource 'STR#' (1044, purgeable)
	{
		{
		"Add…",
		"Subtract…"
		}
	};

resource 'DLOG' (1044, purgeable)
	{
	{0, 0, 268, 330},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1044,
	""
	};

resource 'DITL' (1044, purgeable)
	{
		{
		{15, 255, 35, 315},   Button { enabled, "OK" },
		{45, 255, 65, 315},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{40, 29, 56, 95},	  StaticText { disabled, "Source 1:" },
		{40, 96, 56, 225},	  UserItem { disabled },
		{66, 33, 82, 95},	  StaticText { disabled, "Channel:" },
		{66, 96, 82, 225},	  UserItem { disabled },
		{92, 29, 108, 95},	  StaticText { disabled, "Source 2:" },
		{92, 96, 108, 225},   UserItem { disabled },
		{118, 33, 134, 95},   StaticText { disabled, "Channel:" },
		{118, 96, 134, 225},  UserItem { disabled },
		{206, 10, 222, 95},   StaticText { disabled, "Destination:" },
		{206, 96, 222, 225},  UserItem { disabled },
		{232, 33, 248, 95},   StaticText { disabled, "Channel:" },
		{232, 96, 248, 225},  UserItem { disabled },
		{149, 98, 165, 148},  EditText { enabled, "" },
		{175, 98, 191, 148},  EditText { enabled, "" },
		{10, 10, 26, 200},	  StaticText { disabled, "^0" },
		{149, 51, 165, 95},   StaticText { enabled, "Scale:" },
		{175, 44, 191, 95},   StaticText { enabled, "Offset:" }
		}
	};

resource 'STR#' (1045, purgeable)
	{
		{
		"Difference…",
		"Multiply…",
		"Lighter…",
		"Darker…",
		"Screen…"
		}
	};

resource 'DLOG' (1045, purgeable)
	{
	{0, 0, 211, 330},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1045,
	""
	};

resource 'DITL' (1045, purgeable)
	{
		{
		{15, 255, 35, 315},   Button { enabled, "OK" },
		{45, 255, 65, 315},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{40, 29, 56, 95},	  StaticText { disabled, "Source 1:" },
		{40, 96, 56, 225},	  UserItem { disabled },
		{66, 33, 82, 95},	  StaticText { disabled, "Channel:" },
		{66, 96, 82, 225},	  UserItem { disabled },
		{92, 29, 108, 95},	  StaticText { disabled, "Source 2:" },
		{92, 96, 108, 225},   UserItem { disabled },
		{118, 33, 134, 95},   StaticText { disabled, "Channel:" },
		{118, 96, 134, 225},  UserItem { disabled },
		{149, 10, 165, 95},   StaticText { disabled, "Destination:" },
		{149, 96, 165, 225},  UserItem { disabled },
		{175, 33, 191, 95},   StaticText { disabled, "Channel:" },
		{175, 96, 191, 225},  UserItem { disabled },
		{10, 10, 26, 225},	  StaticText { disabled, "^0" }
		}
	};

resource 'DLOG' (1051, purgeable)
	{
#if Barneyscan
	{0, 0, 204, 360},
#else
	{0, 0, 220, 360},
#endif
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1051,
	""
	};

resource 'DITL' (1051, purgeable)
	{
		{
		{15, 285, 35, 345},   Button { enabled, "OK" },
		{45, 285, 65, 345},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{44, 70, 60, 135},	  EditText { enabled, "" },
		{44, 145, 60, 260},   UserItem { enabled },
		{70, 70, 86, 135},	  EditText { enabled, "" },
		{70, 145, 86, 260},   UserItem { enabled },
		{126, 30, 142, 230},  RadioButton { enabled, "50% Threshold" },
		{142, 30, 158, 230},  RadioButton { enabled, "Pattern Dither" },
		{158, 30, 174, 230},  RadioButton { enabled, "Diffusion Dither" },
		{174, 30, 190, 230},  RadioButton { enabled, "Halftone Screen…" },
#if Barneyscan
		{-80, 30, -64, 230},  RadioButton { enabled, "Custom Pattern" },
#else
		{190, 30, 206, 230},  RadioButton { enabled, "Custom Pattern" },
#endif
		{44, 18, 60, 60},	  StaticText { enabled, "Input:" },
		{70, 10, 86, 60},	  StaticText { enabled, "Output:" },
		{104, 10, 120, 200},  StaticText { disabled, "Conversion Method:" },
		{10, 10, 26, 250},	  StaticText { disabled,
							  "Gray Scale to Bitmap…" }
		}
	};

resource 'DLOG' (1052, purgeable)
	{
	{0, 0, 90, 340},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1052,
	""
	};

resource 'DITL' (1052, purgeable)
	{
		{
		{15, 265, 35, 325},   Button { enabled, "OK" },
		{45, 265, 65, 325},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{44, 95, 60, 125},	  EditText { enabled, "" },
		{44, 10, 60, 85},	  StaticText { enabled, "Size Ratio:" },
		{10, 10, 26, 250},	  StaticText { disabled,
							  "Bitmap to Gray Scale…" }
		}
	};

resource 'DLOG' (1054, purgeable)
	{
	{0, 0, 240, 350},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1054,
	""
	};

resource 'DITL' (1054, purgeable)
	{
		{
		{15, 275, 35, 335},   Button { enabled, "OK" },
		{45, 275, 65, 335},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{54, 30, 70, 130},	  RadioButton { enabled, "3 bits/pixel" },
		{70, 30, 86, 130},	  RadioButton { enabled, "4 bits/pixel" },
		{86, 30, 102, 130},   RadioButton { enabled, "5 bits/pixel" },
		{102, 30, 118, 130},  RadioButton { enabled, "6 bits/pixel" },
		{118, 30, 134, 130},  RadioButton { enabled, "7 bits/pixel" },
		{134, 30, 150, 130},  RadioButton { enabled, "8 bits/pixel" },
		{176, 30, 192, 120},  RadioButton { enabled, "Exact" },
		{192, 30, 208, 120},  RadioButton { enabled, "Uniform" },
		{208, 30, 224, 120},  RadioButton { enabled, "Adaptive" },
		{176, 160, 192, 280}, RadioButton { enabled, "None" },
		{192, 160, 208, 280}, RadioButton { enabled, "Pattern" },
		{208, 160, 224, 280}, RadioButton { enabled, "Diffusion" },
		{-32, 30, -16, 120},  RadioButton { disabled, "Uniform" },
		{-32, 30, -16, 120},  RadioButton { disabled, "System" },
		{10, 10, 26, 260},	  StaticText { disabled,
							  "RGB Color to Indexed Color…" },
		{34, 10, 50, 100},	  StaticText { disabled, "Resolution:" },
		{156, 10, 172, 100},  StaticText { disabled, "Palette:" },
		{156, 140, 172, 240}, StaticText { disabled, "Dither:" }
		}
	};

resource 'DLOG' (1060, purgeable)
	{
	{0, 0, 260, 360},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1060,
	""
	};

resource 'DITL' (1060, purgeable)
	{
		{
		{15, 270, 35, 345},   Button { enabled, "OK" },
		{45, 270, 65, 345},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{30, 10, 46, 160},	  RadioButton { enabled, "Resize image by:" },
		{80, 10, 96, 160},	  RadioButton { enabled, "Resize image to:" },
		{54, 80, 70, 125},	  EditText { enabled, "" },
		{104, 80, 120, 125},  EditText { enabled, "" },
		{130, 80, 146, 125},  EditText { enabled, "" },
		{102, 270, 122, 345}, Button { enabled, "Screen" },
		{128, 270, 148, 345}, Button { enabled, "Window" },
		{154, 30, 170, 210},  CheckBox { enabled, "Constrain aspect ratio" },
		{200, 20, 216, 170},  RadioButton { enabled, "Stretch/shrink" },
		{200, 180, 216, 340}, RadioButton { enabled, "Place at center" },
		{216, 20, 232, 170},  RadioButton { enabled, "Place at upper-left" },
		{216, 180, 232, 340}, RadioButton { enabled, "Place at upper-right" },
		{232, 20, 248, 170},  RadioButton { enabled, "Place at lower-left" },
		{232, 180, 248, 340}, RadioButton { enabled, "Place at lower-right" },
		{8, 10, 24, 80},	  StaticText { disabled, "Resize…" },
		{54, 14, 70, 75},	  StaticText { enabled, "Percent:" },
		{104, 27, 120, 75},   StaticText { enabled, "Width:" },
		{130, 23, 146, 75},   StaticText { enabled, "Height:" },
		{104, 140, 120, 250}, StaticText { disabled, "(^0)" },
		{130, 140, 146, 250}, StaticText { disabled, "(^1)" },
		{180, 10, 196, 120},  StaticText { disabled, "Existing Image:" }
		}
	};

resource 'DLOG' (1061, purgeable)
	{
	{0, 0, 246, 370},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1061,
	""
	};

resource 'DITL' (1061, purgeable)
	{
		{
		{15, 295, 35, 355},   Button { enabled, "OK" },
		{45, 295, 65, 355},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{90, 295, 110, 355},  Button { enabled, "Auto…" },
		{158, 105, 174, 170}, EditText { enabled, "" },
		{158, 180, 174, 300}, UserItem { enabled },
		{184, 105, 200, 170}, EditText { enabled, "" },
		{184, 180, 200, 300}, UserItem { enabled },
		{210, 105, 226, 170}, EditText { enabled, "" },
		{210, 180, 226, 300}, UserItem { enabled },
		{130, 140, 146, 240}, UserItem { disabled },
		{10, 10, 26, 165},	  StaticText { disabled, "Resample…" },
		{36, 10, 52, 130},	  StaticText { disabled, "Current Size:" },
		{36, 140, 52, 240},   StaticText { disabled, "^3" },
		{60, 51, 76, 275},	  StaticText { disabled, "Width:   ^0" },
		{80, 47, 96, 275},	  StaticText { disabled, "Height:   ^1" },
		{100, 20, 116, 275},  StaticText { disabled, "Resolution:   ^2" },
		{130, 10, 146, 130},  StaticText { disabled, "Resampled Size:" },
		{158, 51, 174, 100},  StaticText { enabled, "Width:" },
		{184, 47, 200, 100},  StaticText { enabled, "Height:" },
		{210, 20, 226, 100},  StaticText { enabled, "Resolution:" }
		}
	};

resource 'DLOG' (1062, purgeable)
	{
	{0, 0, 190, 340},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1062,
	""
	};

resource 'DITL' (1062, purgeable)
	{
		{
		{15, 265, 35, 325},   Button { enabled, "OK" },
		{45, 265, 65, 325},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{40, 72, 56, 127},	  EditText { enabled, "" },
		{40, 137, 56, 247},   UserItem { enabled },
		{70, 72, 86, 127},	  EditText { enabled, "" },
		{70, 137, 86, 247},   UserItem { enabled },
		{122, 30, 138, 130},  RadioButton { enabled, "Draft" },
		{138, 30, 154, 130},  RadioButton { enabled, "Medium" },
		{154, 30, 170, 130},  RadioButton { enabled, "High" },
		{10, 10, 26, 220},	  StaticText { disabled, "Auto Resolution…" },
		{40, 10, 56, 65},	  StaticText { enabled, "Printer:" },
		{70, 12, 86, 65},	  StaticText { enabled, "Screen:" },
		{102, 10, 118, 220},  StaticText { disabled, "Quality Required:" }
		}
	};

resource 'DLOG' (1070, purgeable)
	{
	{0, 0, 170, 380},
	50,
	invisible,
	noGoAway,
	0x0,
	1070,
	"Paste Controls"
	};

resource 'DITL' (1070, purgeable)
	{
		{
		{15, 300, 35, 365},   Button { enabled, "OK" },
		{45, 300, 65, 365},   Button { enabled, "Cancel" },
		{71, 300, 91, 365},   Button { enabled, "Preview" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{40, 20, 41, 276},	  UserItem { disabled },
		{88, 20, 89, 276},	  UserItem { disabled },
		{8, 175, 24, 211},	  UserItem { disabled },
		{8, 211, 24, 247},	  UserItem { disabled },
		{56, 175, 72, 211},   UserItem { disabled },
		{56, 211, 72, 247},   UserItem { disabled },
		{-32, 305, -16, 365}, RadioButton { enabled, "Gray" },
		{-32, 305, -16, 365}, RadioButton { enabled, "Red" },
		{-32, 305, -16, 365}, RadioButton { enabled, "Green" },
		{-32, 305, -16, 365}, RadioButton { enabled, "Blue" },
		{106, 175, 122, 280}, RadioButton { enabled, "Normal" },
		{-32, 175, -16, 280}, RadioButton { enabled, "Color Only" },
		{122, 175, 138, 280}, RadioButton { enabled, "Darken Only" },
		{138, 175, 154, 280}, RadioButton { enabled, "Lighten Only" },
		{110, 100, 126, 130}, EditText { enabled, "" },
		{138, 100, 154, 130}, EditText { enabled, "" },
		{30, 19, 41, 277},	  Picture { disabled, 1003 },
		{78, 19, 89, 277},	  Picture { disabled, 1003 },
		{8, 50, 24, 175},	  StaticText { disabled, "Floating Selection:" },
		{56, 50, 72, 175},	  StaticText { disabled, "Underlying Image:" },
		{110, 37, 126, 95},   StaticText { enabled, "Opacity:" },
		{110, 135, 126, 155}, StaticText { disabled, "%" },
		{138, 21, 154, 95},   StaticText { enabled, "Fuzziness:" }
		}
	};

resource 'DLOG' (1071, purgeable)
	{
	{0, 0, 130, 380},
	50,
	invisible,
	noGoAway,
	0x0,
	1071,
	"Paste Controls"
	};

resource 'DITL' (1071, purgeable)
	{
		{
		{15, 300, 35, 365},   Button { enabled, "OK" },
		{45, 300, 65, 365},   Button { enabled, "Cancel" },
		{71, 300, 91, 365},   Button { enabled, "Preview" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{40, 20, 41, 276},	  UserItem { disabled },
		{88, 20, 89, 276},	  UserItem { disabled },
		{8, 175, 24, 211},	  UserItem { disabled },
		{8, 211, 24, 247},	  UserItem { disabled },
		{56, 175, 72, 211},   UserItem { disabled },
		{56, 211, 72, 247},   UserItem { disabled },
		{104, 30, 120, 90},   RadioButton { enabled, "Gray" },
		{104, 95, 120, 155},  RadioButton { enabled, "Red" },
		{104, 155, 120, 215}, RadioButton { enabled, "Green" },
		{104, 228, 120, 288}, RadioButton { enabled, "Blue" },
		{-32, 175, -16, 280}, RadioButton { enabled, "Normal" },
		{-32, 175, -16, 280}, RadioButton { enabled, "Color Only" },
		{-32, 175, -16, 280}, RadioButton { enabled, "Darken Only" },
		{-32, 175, -16, 280}, RadioButton { enabled, "Lighten Only" },
		{30, 19, 41, 277},	  Picture { disabled, 1003 },
		{78, 19, 89, 277},	  Picture { disabled, 1003 },
		{8, 50, 24, 175},	  StaticText { disabled, "Floating Selection:" },
		{56, 50, 72, 175},	  StaticText { disabled, "Underlying Image:" }
		}
	};

resource 'DLOG' (1072, purgeable)
	{
	{0, 0, 180, 380},
	50,
	invisible,
	noGoAway,
	0x0,
	1072,
	"Paste Controls"
	};

resource 'DITL' (1072, purgeable)
	{
		{
		{15, 300, 35, 365},   Button { enabled, "OK" },
		{45, 300, 65, 365},   Button { enabled, "Cancel" },
		{71, 300, 91, 365},   Button { enabled, "Preview" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{40, 20, 41, 276},	  UserItem { disabled },
		{88, 20, 89, 276},	  UserItem { disabled },
		{8, 175, 24, 211},	  UserItem { disabled },
		{8, 211, 24, 247},	  UserItem { disabled },
		{56, 175, 72, 211},   UserItem { disabled },
		{56, 211, 72, 247},   UserItem { disabled },
		{106, 305, 122, 365}, RadioButton { enabled, "Gray" },
		{122, 305, 138, 365}, RadioButton { enabled, "Red" },
		{138, 305, 154, 365}, RadioButton { enabled, "Green" },
		{154, 305, 170, 365}, RadioButton { enabled, "Blue" },
		{106, 175, 122, 280}, RadioButton { enabled, "Normal" },
		{122, 175, 138, 280}, RadioButton { enabled, "Color Only" },
		{138, 175, 154, 280}, RadioButton { enabled, "Darken Only" },
		{154, 175, 170, 280}, RadioButton { enabled, "Lighten Only" },
		{112, 100, 128, 130}, EditText { enabled, "" },
		{140, 100, 156, 130}, EditText { enabled, "" },
		{30, 19, 41, 277},	  Picture { disabled, 1003 },
		{78, 19, 89, 277},	  Picture { disabled, 1003 },
		{8, 50, 24, 175},	  StaticText { disabled, "Floating Selection:" },
		{56, 50, 72, 175},	  StaticText { disabled, "Underlying Image:" },
		{112, 37, 128, 95},   StaticText { enabled, "Opacity:" },
		{112, 135, 128, 155}, StaticText { disabled, "%" },
		{140, 21, 156, 95},   StaticText { enabled, "Fuzziness:" }
		}
	};

resource 'DLOG' (1080, purgeable)
	{
	{0, 0, 260, 340},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1080,
	""
	};

resource 'DITL' (1080, purgeable)
	{
		{
		{15, 265, 35, 325},   Button { enabled, "OK" },
		{45, 265, 65, 325},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{76, 90, 92, 155},	  EditText { enabled, "" },
		{104, 90, 120, 155},  EditText { enabled, "" },
		{156, 90, 172, 135},  EditText { enabled, "" },
		{184, 90, 200, 135},  EditText { enabled, "" },
		{32, 10, 48, 150},	  RadioButton { enabled, "Normal" },
		{52, 10, 68, 200},	  RadioButton { enabled, "Constrained Aspect Ratio:" },
		{132, 10, 148, 110},  RadioButton { enabled, "Fixed Size:" },
		{212, 10, 228, 150},  RadioButton { enabled, "Single Row" },
		{232, 10, 248, 150},  RadioButton { enabled, "Single Column" },
		{10, 10, 26, 250},	  StaticText { disabled,
							  "Rectangular Marquee Options…" },
		{156, 34, 172, 80},   StaticText { enabled, "Width:" },
		{184, 30, 200, 80},   StaticText { enabled, "Height:" },
		{76, 34, 92, 80},	  StaticText { enabled, "Width:" },
		{104, 30, 120, 80},   StaticText { enabled, "Height:" },
		{156, 145, 172, 200}, StaticText { disabled, "(pixels)" },
		{184, 145, 200, 200}, StaticText { disabled, "(pixels)" }
		}
	};

resource 'DLOG' (1081, purgeable)
	{
	{0, 0, 90, 280},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1081,
	""
	};

resource 'DITL' (1081, purgeable)
	{
		{
		{15, 205, 35, 265},   Button { enabled, "OK" },
		{45, 205, 65, 265},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{44, 80, 60, 105},	  EditText { enabled, "" },
		{10, 10, 26, 165},	  StaticText { disabled, "Lasso Options…" },
		{44, 10, 60, 70},	  StaticText { enabled, "Feather:" },
		{44, 115, 60, 175},   StaticText { disabled, "(pixels)" }
		}
	};

resource 'DLOG' (1082, purgeable)
	{
	{0, 0, 260, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1082,
	""
	};

resource 'DITL' (1082, purgeable)
	{
		{
		{15, 245, 35, 305},   Button { enabled, "OK" },
		{45, 245, 65, 305},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{37, 30, 143, 211},   UserItem { disabled },
		{103, 167, 135, 199}, UserItem { disabled },
		{176, 190, 192, 300}, RadioButton { enabled, "Normal" },
		{192, 190, 208, 300}, RadioButton { enabled, "Color Only" },
		{208, 190, 224, 300}, RadioButton { enabled, "Darken Only" },
		{224, 190, 240, 300}, RadioButton { enabled, "Lighten Only" },
		{164, 95, 180, 125},  EditText { enabled, "" },
		{194, 95, 210, 125},  EditText { enabled, "" },
		{224, 36, 240, 136},  CheckBox { enabled, "Auto Erase" },
		{100, 220, 116, 310}, CheckBox { enabled, "Wacom PS" },
		{10, 10, 26, 200},	  StaticText { disabled, "Pencil Options…" },
		{156, 170, 172, 260}, StaticText { disabled, "Mode:" },
		{164, 30, 180, 90},   StaticText { enabled, "Spacing:" },
		{194, 31, 210, 90},   StaticText { enabled, "Opacity:" },
		{194, 130, 210, 150}, StaticText { disabled, "%" }
		}
	};

resource 'DLOG' (1083, purgeable)
	{
	{0, 0, 280, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1083,
	""
	};

resource 'DITL' (1083, purgeable)
	{
		{
		{15, 245, 35, 305},   Button { enabled, "OK" },
		{45, 245, 65, 305},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{37, 30, 143, 211},   UserItem { disabled },
		{103, 167, 135, 199}, UserItem { disabled },
		{176, 190, 192, 300}, RadioButton { enabled, "Normal" },
		{192, 190, 208, 300}, RadioButton { enabled, "Color Only" },
		{208, 190, 224, 300}, RadioButton { enabled, "Darken Only" },
		{224, 190, 240, 300}, RadioButton { enabled, "Lighten Only" },
		{156, 105, 172, 140}, EditText { enabled, "" },
		{186, 105, 202, 140}, EditText { enabled, "" },
		{216, 105, 232, 140}, EditText { enabled, "" },
		{246, 105, 262, 140}, EditText { enabled, "" },
		{100, 220, 116, 310}, CheckBox { enabled, "Wacom PS" },
		{10, 10, 26, 200},	  StaticText { disabled, "Paint Brush Options…" },
		{156, 170, 172, 260}, StaticText { disabled, "Mode:" },
		{156, 40, 172, 100},  StaticText { enabled, "Spacing:" },
		{186, 30, 202, 100},  StaticText { enabled, "Fade-out:" },
		{216, 10, 232, 100},  StaticText { enabled, "Repeat Rate:" },
		{246, 41, 262, 100},  StaticText { enabled, "Opacity:" },
		{246, 145, 262, 165}, StaticText { disabled, "%" }
		}
	};

resource 'DLOG' (1084, purgeable)
	{
	{0, 0, 280, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1084,
	""
	};

resource 'DITL' (1084, purgeable)
	{
		{
		{15, 245, 35, 305},   Button { enabled, "OK" },
		{45, 245, 65, 305},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{37, 30, 143, 211},   UserItem { disabled },
		{103, 167, 135, 199}, UserItem { disabled },
		{176, 190, 192, 300}, RadioButton { enabled, "Normal" },
		{192, 190, 208, 300}, RadioButton { enabled, "Color Only" },
		{208, 190, 224, 300}, RadioButton { enabled, "Darken Only" },
		{224, 190, 240, 300}, RadioButton { enabled, "Lighten Only" },
		{156, 105, 172, 140}, EditText { enabled, "" },
		{186, 105, 202, 140}, EditText { enabled, "" },
		{216, 105, 232, 140}, EditText { enabled, "" },
		{246, 105, 262, 140}, EditText { enabled, "" },
		{100, 220, 116, 310}, CheckBox { enabled, "Wacom PS" },
		{10, 10, 26, 200},	  StaticText { disabled, "Airbrush Options…" },
		{156, 170, 172, 260}, StaticText { disabled, "Mode:" },
		{156, 40, 172, 100},  StaticText { enabled, "Spacing:" },
		{186, 30, 202, 100},  StaticText { enabled, "Fade-out:" },
		{216, 10, 232, 100},  StaticText { enabled, "Repeat Rate:" },
		{246, 32, 262, 100},  StaticText { enabled, "Pressure:" },
		{246, 145, 262, 165}, StaticText { disabled, "%" }
		}
	};

resource 'DLOG' (1085, purgeable)
	{
	{0, 0, 260, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1085,
	""
	};

resource 'DITL' (1085, purgeable)
	{
		{
		{15, 245, 35, 305},   Button { enabled, "OK" },
		{45, 245, 65, 305},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{37, 30, 143, 211},   UserItem { disabled },
		{103, 167, 135, 199}, UserItem { disabled },
		{176, 190, 192, 300}, RadioButton { enabled, "Normal" },
		{192, 190, 208, 300}, RadioButton { enabled, "Color Only" },
		{208, 190, 224, 300}, RadioButton { enabled, "Darken Only" },
		{224, 190, 240, 300}, RadioButton { enabled, "Lighten Only" },
		{160, 105, 176, 135}, EditText { enabled, "" },
		{190, 105, 206, 135}, EditText { enabled, "" },
		{220, 105, 236, 135}, EditText { enabled, "" },
		{10, 10, 26, 200},	  StaticText { disabled, "Blur Tool Options…" },
		{156, 170, 172, 260}, StaticText { disabled, "Mode:" },
		{160, 40, 176, 100},  StaticText { enabled, "Spacing:" },
		{190, 10, 206, 100},  StaticText { enabled, "Repeat Rate:" },
		{220, 32, 236, 100},  StaticText { enabled, "Pressure:" },
		{220, 140, 236, 160}, StaticText { disabled, "%" }
		}
	};

resource 'DLOG' (1086, purgeable)
	{
	{0, 0, 260, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1086,
	""
	};

resource 'DITL' (1086, purgeable)
	{
		{
		{15, 245, 35, 305},   Button { enabled, "OK" },
		{45, 245, 65, 305},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{37, 30, 143, 211},   UserItem { disabled },
		{103, 167, 135, 199}, UserItem { disabled },
		{176, 190, 192, 300}, RadioButton { enabled, "Normal" },
		{192, 190, 208, 300}, RadioButton { enabled, "Color Only" },
		{208, 190, 224, 300}, RadioButton { enabled, "Darken Only" },
		{224, 190, 240, 300}, RadioButton { enabled, "Lighten Only" },
		{160, 105, 176, 135}, EditText { enabled, "" },
		{190, 105, 206, 135}, EditText { enabled, "" },
		{220, 105, 236, 135}, EditText { enabled, "" },
		{10, 10, 26, 200},	  StaticText { disabled, "Sharpen Tool Options…" },
		{156, 170, 172, 260}, StaticText { disabled, "Mode:" },
		{160, 40, 176, 100},  StaticText { enabled, "Spacing:" },
		{190, 10, 206, 100},  StaticText { enabled, "Repeat Rate:" },
		{220, 32, 236, 100},  StaticText { enabled, "Pressure:" },
		{220, 140, 236, 160}, StaticText { disabled, "%" }
		}
	};

resource 'DLOG' (1087, purgeable)
	{
	{0, 0, 260, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1087,
	""
	};

resource 'DITL' (1087, purgeable)
	{
		{
		{15, 245, 35, 305},   Button { enabled, "OK" },
		{45, 245, 65, 305},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{37, 30, 143, 211},   UserItem { disabled },
		{103, 167, 135, 199}, UserItem { disabled },
		{176, 190, 192, 300}, RadioButton { enabled, "Normal" },
		{192, 190, 208, 300}, RadioButton { enabled, "Color Only" },
		{208, 190, 224, 300}, RadioButton { enabled, "Darken Only" },
		{224, 190, 240, 300}, RadioButton { enabled, "Lighten Only" },
		{160, 105, 176, 135}, EditText { enabled, "" },
		{190, 105, 206, 135}, EditText { enabled, "" },
		{220, 105, 236, 135}, EditText { enabled, "" },
		{10, 10, 26, 220},	  StaticText { disabled, "Smudge Tool Options…" },
		{156, 170, 172, 260}, StaticText { disabled, "Mode:" },
		{160, 40, 176, 100},  StaticText { enabled, "Spacing:" },
		{190, 10, 206, 100},  StaticText { enabled, "Repeat Rate:" },
		{220, 32, 236, 100},  StaticText { enabled, "Pressure:" },
		{220, 140, 236, 160}, StaticText { disabled, "%" }
		}
	};

resource 'DLOG' (1088, purgeable)
	{
	{0, 0, 300, 370},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1088,
	""
	};

resource 'DITL' (1088, purgeable)
	{
		{
		{15, 295, 35, 355},   Button { enabled, "OK" },
		{45, 295, 65, 355},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{37, 30, 143, 211},   UserItem { disabled },
		{103, 167, 135, 199}, UserItem { disabled },
#if Barneyscan
		{176, 240, 192, 350}, RadioButton { enabled, "Normal" },
		{192, 240, 208, 350}, RadioButton { enabled, "Color Only" },
		{208, 240, 224, 350}, RadioButton { enabled, "Darken Only" },
		{224, 240, 240, 350}, RadioButton { enabled, "Lighten Only" },
		{240, 95, 256, 125},  EditText { enabled, "" },
		{270, 95, 286, 125},  EditText { enabled, "" },
		{176, 50, 192, 220},  RadioButton { enabled, "Clone (aligned)" },
		{192, 50, 208, 220},  RadioButton { enabled, "Clone (non-aligned)" },
		{208, 50, 224, 220},  RadioButton { enabled, "Revert" },
		{-80, 50, -64, 220},  RadioButton { enabled, "Texture" },
		{-80, 50, -64, 220},  RadioButton { enabled, "Pattern (aligned)" },
		{-80, 50, -64, 220},  RadioButton { enabled, "Pattern (non-aligned)" },
		{-80, 50, -64, 220},  RadioButton { enabled, "Impressionist" },
		{156, 30, 172, 120},  StaticText { disabled, "Option:" },
		{156, 220, 172, 310}, StaticText { disabled, "Mode:" },
		{240, 30, 256, 90},   StaticText { enabled, "Spacing:" },
		{270, 31, 286, 90},   StaticText { enabled, "Opacity:" },
		{270, 130, 286, 150}, StaticText { disabled, "%" },
#else
		{224, 240, 240, 350}, RadioButton { enabled, "Normal" },
		{240, 240, 256, 350}, RadioButton { enabled, "Color Only" },
		{256, 240, 272, 350}, RadioButton { enabled, "Darken Only" },
		{272, 240, 288, 350}, RadioButton { enabled, "Lighten Only" },
		{145, 295, 161, 325}, EditText { enabled, "" },
		{175, 295, 191, 325}, EditText { enabled, "" },
		{176, 30, 192, 200},  RadioButton { enabled, "Clone (aligned)" },
		{192, 30, 208, 200},  RadioButton { enabled, "Clone (non-aligned)" },
		{208, 30, 224, 200},  RadioButton { enabled, "Revert" },
		{224, 30, 240, 200},  RadioButton { enabled, "Texture" },
		{240, 30, 256, 200},  RadioButton { enabled, "Pattern (aligned)" },
		{256, 30, 272, 200},  RadioButton { enabled, "Pattern (non-aligned)" },
		{272, 30, 288, 200},  RadioButton { enabled, "Impressionist" },
		{156, 10, 172, 100},  StaticText { disabled, "Option:" },
		{204, 220, 220, 310}, StaticText { disabled, "Mode:" },
		{145, 230, 161, 290}, StaticText { enabled, "Spacing:" },
		{175, 231, 191, 290}, StaticText { enabled, "Opacity:" },
		{175, 330, 191, 350}, StaticText { disabled, "%" },
#endif
		{10, 10, 26, 200},	  StaticText { disabled, "Rubber Stamp Options…" }
		}
	};

resource 'DLOG' (1089, purgeable)
	{
	{0, 0, 106, 260},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1089,
	""
	};

resource 'DITL' (1089, purgeable)
	{
		{
		{15, 185, 35, 245},   Button { enabled, "OK" },
		{45, 185, 65, 245},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{40, 100, 56, 135},   EditText { enabled, "" },
		{70, 100, 86, 135},   EditText { enabled, "" },
		{10, 10, 26, 170},	  StaticText { disabled, "Magic Wand Options…" },
		{40, 22, 56, 95},	  StaticText { enabled, "Tolerance:" },
		{70, 20, 86, 95},	  StaticText { enabled, "Fuzziness:" },
		}
	};

resource 'DLOG' (1090, purgeable)
	{
	{0, 0, 106, 260},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1090,
	""
	};

resource 'DITL' (1090, purgeable)
	{
		{
		{15, 185, 35, 245},   Button { enabled, "OK" },
		{45, 185, 65, 245},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{40, 100, 56, 135},   EditText { enabled, "" },
		{70, 100, 86, 135},   EditText { enabled, "" },
		{10, 10, 26, 170},	  StaticText { disabled, "Paint Bucket Options…" },
		{40, 22, 56, 95},	  StaticText { enabled, "Tolerance:" },
		{70, 20, 86, 95},	  StaticText { enabled, "Fuzziness:" },
		}
	};

resource 'DLOG' (1091, purgeable)
	{
	{0, 0, 160, 310},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1091,
	""
	};

resource 'DITL' (1091, purgeable)
	{
		{
		{15, 235, 35, 295},   Button { enabled, "OK" },
		{45, 235, 65, 295},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{54, 30, 70, 100},	  RadioButton { enabled, "Linear" },
		{70, 30, 86, 100},	  RadioButton { enabled, "Radial" },
		{98, 120, 114, 145},  EditText { enabled, "" },
		{126, 120, 142, 145}, EditText { enabled, "" },
		{100, 210, 116, 290}, RadioButton { enabled, "RGB" },
		{116, 210, 132, 290}, RadioButton { enabled, "HSB-CW" },
		{132, 210, 148, 290}, RadioButton { enabled, "HSB-CCW" },
		{10, 10, 26, 170},	  StaticText { disabled, "Blend Tool Options…" },
		{34, 10, 50, 100},	  StaticText { disabled, "Type:" },
		{98, 10, 114, 115},   StaticText { enabled, "Midpoint Skew:" },
		{98, 150, 114, 170},  StaticText { disabled, "%" },
		{126, 22, 142, 115},  StaticText { enabled, "Radial Offset:" },
		{126, 150, 142, 170}, StaticText { disabled, "%" },
		{80, 190, 96, 300},   StaticText { disabled, "Color Space:" }
		}
	};

resource 'DLOG' (1092, purgeable)
	{
	{0, 0, 130, 370},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1092,
	""
	};

resource 'DITL' (1092, purgeable)
	{
		{
		{15, 295, 35, 355},   Button { enabled, "OK" },
		{45, 295, 65, 355},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{38, 95, 54, 160},	  EditText { enabled, "" },
		{38, 170, 54, 285},   UserItem { enabled },
		{64, 95, 80, 160},	  EditText { enabled, "" },
		{64, 170, 80, 285},   UserItem { enabled },
		{90, 95, 106, 160},   EditText { enabled, "" },
		{90, 170, 106, 285},  UserItem { enabled },
		{10, 10, 26, 280},	  StaticText { disabled, "Cropping Tool Options…" },
		{38, 41, 54, 90},	  StaticText { enabled, "Width:" },
		{64, 37, 80, 90},	  StaticText { enabled, "Height:" },
		{90, 10, 106, 90},	  StaticText { enabled, "Resolution:" },
		}
	};

resource 'DLOG' (1093, purgeable)
	{
	{0, 0, 220, 340},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1093,
	""
	};

resource 'DITL' (1093, purgeable)
	{
		{
		{15, 265, 35, 325},   Button { enabled, "OK" },
		{45, 265, 65, 325},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{76, 90, 92, 155},	  EditText { enabled, "" },
		{104, 90, 120, 155},  EditText { enabled, "" },
		{156, 90, 172, 135},  EditText { enabled, "" },
		{184, 90, 200, 135},  EditText { enabled, "" },
		{32, 10, 48, 150},	  RadioButton { enabled, "Normal" },
		{52, 10, 68, 200},	  RadioButton { enabled, "Constrained Aspect Ratio:" },
		{132, 10, 148, 110},  RadioButton { enabled, "Fixed Size:" },
		{-32, 10, -16, 150},  RadioButton { enabled, "Single Row" },
		{-32, 10, -16, 150},  RadioButton { enabled, "Single Column" },
		{10, 10, 26, 250},	  StaticText { disabled,
							  "Elliptical Marquee Options…" },
		{156, 34, 172, 80},   StaticText { enabled, "Width:" },
		{184, 30, 200, 80},   StaticText { enabled, "Height:" },
		{76, 34, 92, 80},	  StaticText { enabled, "Width:" },
		{104, 30, 120, 80},   StaticText { enabled, "Height:" },
		{156, 145, 172, 200}, StaticText { disabled, "(pixels)" },
		{184, 145, 200, 200}, StaticText { disabled, "(pixels)" },
		}
	};

resource 'DLOG' (1094, purgeable)
	{
	{0, 0, 210, 300},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1094,
	""
	};

resource 'DITL' (1094, purgeable)
	{
		{
		{15, 225, 35, 285},   Button { enabled, "OK" },
		{45, 225, 65, 285},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{40, 83, 56, 108},	  EditText { enabled, "" },
		{94, 30, 110, 105},   CheckBox { enabled, "At Start" },
		{94, 110, 110, 180},  CheckBox { enabled, "At End" },
		{120, 103, 136, 128}, EditText { enabled, "" },
		{148, 103, 164, 128}, EditText { enabled, "" },
		{176, 103, 192, 128}, EditText { enabled, "" },
		{10, 10, 26, 170},	  StaticText { disabled, "Line Tool Options…" },
		{40, 27, 56, 75},	  StaticText { enabled, "Width:" },
		{40, 118, 56, 180},   StaticText { disabled, "(pixels)" },
		{70, 10, 86, 170},	  StaticText { disabled, "Arrow Heads:" },
		{120, 47, 136, 95},   StaticText { enabled, "Width:" },
		{120, 138, 136, 200}, StaticText { disabled, "(pixels)" },
		{148, 40, 164, 95},   StaticText { enabled, "Length:" },
		{148, 138, 164, 200}, StaticText { disabled, "(pixels)" },
		{176, 20, 192, 95},   StaticText { enabled, "Concavity:" },
		{176, 138, 192, 158}, StaticText { disabled, "%" }
		}
	};

resource 'DLOG' (1100, purgeable)
	{
	{0, 0, 234, 280},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1100,
	""
	};

resource 'DITL' (1100, purgeable)
	{
		{
		{15, 205, 35, 265},   Button { enabled, "OK" },
		{45, 205, 65, 265},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{56, 30, 72, 130},	  RadioButton { enabled, "Normal" },
		{72, 30, 88, 130},	  RadioButton { enabled, "Pattern" },
		{88, 30, 104, 130},   RadioButton { enabled, "Border Only:" },
		{88, 138, 104, 163},  EditText { enabled, "" },
		{120, 75, 136, 105},  EditText { enabled, "" },
		{170, 30, 186, 130},  RadioButton { enabled, "Normal" },
		{-80, 30, -60, 130},  RadioButton { enabled, "Color Only" },
		{186, 30, 202, 130},  RadioButton { enabled, "Darken Only" },
		{202, 30, 218, 130},  RadioButton { enabled, "Lighten Only" },
		{10, 10, 26, 80},	  StaticText { disabled, "Fill…" },
		{36, 10, 52, 80},	  StaticText { disabled, "Option:" },
		{88, 173, 104, 228},  StaticText { disabled, "(pixels)" },
		{120, 10, 136, 70},   StaticText { enabled, "Opacity:" },
		{120, 110, 136, 130}, StaticText { disabled, "%" },
		{150, 10, 166, 80},   StaticText { disabled, "Mode:" }
		}
	};

resource 'DLOG' (1101, purgeable)
	{
	{0, 0, 105, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1101,
	""
	};

resource 'DITL' (1101, purgeable)
	{
		{
		{15, 245, 35, 305},   Button { enabled, "OK" },
		{45, 245, 65, 305},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{56, 30, 72, 130},	  RadioButton { enabled, "Normal" },
		{-80, 30, -60, 130},  RadioButton { enabled, "Pattern" },
		{72, 30, 88, 130},	  RadioButton { enabled, "Border Only:" },
		{72, 138, 88, 163},   EditText { enabled, "" },
		{10, 10, 26, 80},	  StaticText { disabled, "Fill…" },
		{36, 10, 52, 80},	  StaticText { disabled, "Option:" },
		{72, 173, 88, 228},   StaticText { disabled, "(pixels)" }
		}
	};

resource 'DLOG' (1102, purgeable)
	{
	{0, 0, 250, 280},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1102,
	""
	};

resource 'DITL' (1102, purgeable)
	{
		{
		{15, 205, 35, 265},   Button { enabled, "OK" },
		{45, 205, 65, 265},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{56, 30, 72, 130},	  RadioButton { enabled, "Normal" },
		{72, 30, 88, 130},	  RadioButton { enabled, "Pattern" },
		{88, 30, 104, 130},   RadioButton { enabled, "Border Only:" },
		{88, 138, 104, 163},  EditText { enabled, "" },
		{120, 75, 136, 105},  EditText { enabled, "" },
		{170, 30, 186, 130},  RadioButton { enabled, "Normal" },
		{186, 30, 202, 130},  RadioButton { enabled, "Color Only" },
		{202, 30, 218, 130},  RadioButton { enabled, "Darken Only" },
		{218, 30, 234, 130},  RadioButton { enabled, "Lighten Only" },
		{10, 10, 26, 80},	  StaticText { disabled, "Fill…" },
		{36, 10, 52, 80},	  StaticText { disabled, "Option:" },
		{88, 173, 104, 228},  StaticText { disabled, "(pixels)" },
		{120, 10, 136, 70},   StaticText { enabled, "Opacity:" },
		{120, 110, 136, 130}, StaticText { disabled, "%" },
		{150, 10, 166, 80},   StaticText { disabled, "Mode:" }
		}
	};

resource 'DITL' (1200, purgeable)
	{
		{
		{67, 15, 87, 115},	  Button { enabled,
#if Barneyscan
							  "Image Size…"
#else
							  "Size/Rulers…"
#endif
							  },
		{15, 15, 35, 115},	  Button { enabled, "Screen…" },
		{15, 15, 35, 115},	  Button { enabled, "Screens…" },
		{41, 15, 61, 115},	  Button { enabled, "Transfer…" },
		{15, 127, 35, 207},   Button { enabled, "Border…" },
		{41, 127, 61, 207},   Button { enabled, "Caption…" },
		{15, 218, 31, 325},   CheckBox { enabled, "Labels" },
		{33, 218, 49, 325},   CheckBox { enabled, "Crop Marks" },
		{51, 218, 67, 365},   CheckBox { enabled, "Calibration Bars" },
		{69, 218, 85, 365},   CheckBox { enabled, "Registration Marks" },
		{15, 345, 31, 462},   CheckBox { enabled, "Negative" },
		{33, 345, 49, 462},   CheckBox { enabled, "Emulsion Down" },
		{5, 10, 6, 462},	  UserItem { disabled }
		}
	};

resource 'DITL' (1201, purgeable)
	{
		{
		{15, 10, 31, 220},	 CheckBox { enabled, "Print Selected Area Only" },
		{31, 10, 47, 220},	 CheckBox { enabled, "Print Selected Channel Only" },
		{47, 10, 63, 220},	 CheckBox { enabled, "Print Using Color PostScript" },
#if Barneyscan
		{47, -90, 63, -10},  CheckBox { enabled, "Correct for Printing Colors" },
#else
		{63, 10, 79, 220},	 CheckBox { enabled, "Correct for Printing Colors" },
#endif
		{31, 270, 47, 350},  RadioButton { enabled, "ASCII" },
		{47, 270, 63, 350},  RadioButton { enabled, "Binary" },
		{5, 10, 6, 462},	 UserItem { disabled },
		{13, 250, 29, 330},  StaticText { disabled, "Encoding:" },
		{13, 250, 29, 330},  UserItem { disabled }
		}
	};

resource 'DLOG' (1210, purgeable)
	{
	{0, 0, 126, 370},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1210,
	""
	};

resource 'DITL' (1210, purgeable)
	{
		{
		{15, 295, 35, 355},   Button { enabled, "OK" },
		{45, 295, 65, 355},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{38, 95, 54, 160},	  EditText { enabled, "" },
		{38, 170, 54, 285},   UserItem { enabled },
		{64, 95, 80, 160},	  EditText { enabled, "" },
		{64, 170, 80, 285},   UserItem { enabled },
		{90, 95, 106, 160},   EditText { enabled, "" },
		{90, 170, 106, 285},  UserItem { enabled },
		{38, 41, 54, 90},	  StaticText { enabled, "Width:" },
		{64, 37, 80, 90},	  StaticText { enabled, "Height:" },
		{90, 10, 106, 90},	  StaticText { enabled, "Resolution:" },
		{10, 10, 26, 250},	  StaticText { disabled,
#if Barneyscan
							  "Image Size…"
#else
							  "Image Size/Ruler Units…"
#endif
							  }
		}
	};

resource 'DLOG' (1220, purgeable)
	{
	{0, 0, 240, 480},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1220,
	""
	};

resource 'DITL' (1220, purgeable)
	{
		{
		{15, 405, 35, 465},   Button { enabled, "OK" },
		{45, 405, 65, 465},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{32, 15, 224, 380},   EditText { enabled, "" },
		{10, 10, 26, 400},	  StaticText { enabled,
							  "PostScript Spot Function:  ^0" }
		}
	};

resource 'DLOG' (1221, purgeable)
	{
	{0, 0, 210, 350},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1221,
	""
	};

resource 'DITL' (1221, purgeable)
	{
		{
		{15, 265, 35, 335},   Button { enabled, "OK" },
		{45, 265, 65, 335},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{85, 265, 105, 335},  Button { enabled, "Load…" },
		{85, -80, 105, -20},  Button { enabled, "<-Default" },
		{111, 265, 131, 335}, Button { enabled, "Save…" },
		{111, -80, 131, -20}, Button { enabled, "->Default" },
		{140, 120, 160, 250}, Button { enabled, "Custom Shape…" },
		{38, 93, 54, 139},	  EditText { enabled, "" },
		{38, 149, 54, 249},   UserItem { enabled },
		{66, 93, 82, 139},	  EditText { enabled, "" },
		{-80, 30, -60, 110},  RadioButton { enabled, "Custom" },
		{116, 30, 132, 110},  RadioButton { enabled, "Round" },
		{132, 30, 148, 110},  RadioButton { enabled, "Elliptical" },
		{148, 30, 164, 110},  RadioButton { enabled, "Line" },
		{164, 30, 180, 110},  RadioButton { enabled, "Square" },
		{180, 30, 196, 110},  RadioButton { enabled, "Cross" },
		{10, 10, 26, 160},	  StaticText { disabled, "Halftone Screen…" },
		{38, 10, 54, 85},	  StaticText { enabled, "Frequency:" },
		{66, 42, 82, 85},	  StaticText { enabled, "Angle:" },
		{66, 149, 82, 230},   StaticText { disabled, "(degrees)" },
		{96, 10, 112, 160},   StaticText { disabled, "Shape:" }
		}
	};

resource 'DLOG' (1231, purgeable)
	{
	{0, 0, 230, 504},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1231,
	""
	};

resource 'DITL' (1231, purgeable)
	{
		{
		{15, 419, 35, 489},   Button { enabled, "OK" },
		{45, 419, 65, 489},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{85, 419, 105, 489},  Button { enabled, "Auto…" },
		{125, 419, 145, 489}, Button { enabled, "Load…" },
		{125, -80, 145, -20}, Button { enabled, "<-Default" },
		{151, 419, 171, 489}, Button { enabled, "Save…" },
		{151, -80, 171, -20}, Button { enabled, "->Default" },
		{162, 120, 182, 250}, Button { enabled, "Custom Shapes…" },
		{60, 92, 76, 138},	  EditText { enabled, "" },
		{60, 147, 76, 193},   EditText { enabled, "" },
		{60, 202, 76, 248},   EditText { enabled, "" },
		{60, 257, 76, 303},   EditText { enabled, "" },
		{60, 313, 76, 413},   UserItem { enabled },
		{88, 92, 104, 138},   EditText { enabled, "" },
		{88, 147, 104, 193},  EditText { enabled, "" },
		{88, 202, 104, 248},  EditText { enabled, "" },
		{88, 257, 104, 303},  EditText { enabled, "" },
		{-80, 30, -60, 110},  RadioButton { enabled, "Custom" },
		{138, 30, 154, 110},  RadioButton { enabled, "Round" },
		{154, 30, 170, 110},  RadioButton { enabled, "Elliptical" },
		{170, 30, 186, 110},  RadioButton { enabled, "Line" },
		{186, 30, 202, 110},  RadioButton { enabled, "Square" },
		{202, 30, 218, 110},  RadioButton { enabled, "Cross" },
		{10, 10, 26, 160},	  StaticText { disabled, "Halftone Screens…" },
		{36, 102, 52, 138},   StaticText { disabled, "C:" },
		{36, 157, 52, 193},   StaticText { disabled, "M:" },
		{36, 212, 52, 248},   StaticText { disabled, "Y:" },
		{36, 267, 52, 303},   StaticText { disabled, "K:" },
		{60, 10, 76, 85},	  StaticText { enabled, "Frequency:" },
		{88, 42, 104, 85},	  StaticText { enabled, "Angle:" },
		{88, 313, 104, 400},  StaticText { disabled, "(degrees)" },
		{118, 10, 134, 160},  StaticText { disabled, "Shape:" }
		}
	};

resource 'DLOG' (1232, purgeable)
	{
	{0, 0, 106, 340},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1232,
	""
	};

resource 'DITL' (1232, purgeable)
	{
		{
		{15, 265, 35, 325},   Button { enabled, "OK" },
		{45, 265, 65, 325},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{40, 72, 56, 127},	  EditText { enabled, "" },
		{40, 137, 56, 247},   UserItem { enabled },
		{70, 72, 86, 127},	  EditText { enabled, "" },
		{70, 137, 86, 247},   UserItem { enabled },
		{10, 10, 26, 220},	  StaticText { disabled, "Auto Screens…" },
		{40, 10, 56, 65},	  StaticText { enabled, "Printer:" },
		{70, 12, 86, 65},	  StaticText { enabled, "Screen:" }
		}
	};

resource 'DLOG' (1240, purgeable)
	{
	{0, 0, 150, 480},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1240,
	""
	};

resource 'DITL' (1240, purgeable)
	{
		{
		{15, 405, 35, 465},   Button { enabled, "OK" },
		{45, 405, 65, 465},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{32, 15, 128, 380},   EditText { enabled, "" },
		{10, 10, 26, 100},	  StaticText { enabled, "Caption…" }
		}
	};

resource 'DLOG' (1250, purgeable)
	{
	{0, 0, 90, 300},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1250,
	""
	};

resource 'DITL' (1250, purgeable)
	{
		{
		{15, 225, 35, 285},   Button { enabled, "OK" },
		{45, 225, 65, 285},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{44, 75, 60, 120},	  EditText { enabled, "" },
		{44, 130, 60, 200},   UserItem { enabled },
		{44, 20, 60, 65},	  StaticText { enabled, "Width:" },
		{10, 10, 26, 165},	  StaticText { disabled, "Border…" }
		}
	};

resource 'DLOG' (1260, purgeable)
	{
	{0, 0, 220, 300},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1260,
	""
	};

resource 'DITL' (1260, purgeable)
	{
		{
		{15, 215, 35, 285},   Button { enabled, "OK" },
		{45, 215, 65, 285},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{85, 215, 105, 285},  Button { enabled, "Load…" },
		{85, -80, 105, -20},  Button { enabled, "<-Default" },
		{111, 215, 131, 285}, Button { enabled, "Save…" },
		{111, -80, 131, -20}, Button { enabled, "->Default" },
		{38, 100, 54, 130},   EditText { enabled, "" },
		{66, 100, 82, 130},   EditText { enabled, "" },
		{94, 100, 110, 130},  EditText { enabled, "" },
		{122, 100, 138, 130}, EditText { enabled, "" },
		{150, 100, 166, 130}, EditText { enabled, "" },
		{184, 120, 200, 155}, EditText { enabled, "" },
		{10, 10, 26, 160},	  StaticText { disabled, "Transfer Function…" },
		{38, 20, 54, 95},	  StaticText { enabled, "Highlights:" },
		{66, 21, 82, 95},	  StaticText { enabled, "1/4 Tones:" },
		{94, 24, 110, 95},	  StaticText { enabled, "Midtones:" },
		{122, 21, 138, 95},   StaticText { enabled, "3/4 Tones:" },
		{150, 27, 166, 95},   StaticText { enabled, "Shadows:" },
		{38, 135, 54, 155},   StaticText { disabled, "%" },
		{66, 135, 82, 155},   StaticText { disabled, "%" },
		{94, 135, 110, 155},  StaticText { disabled, "%" },
		{122, 135, 138, 155}, StaticText { disabled, "%" },
		{150, 135, 166, 155}, StaticText { disabled, "%" },
		{184, 10, 200, 110},  StaticText { enabled, "Image Gamma:" }
		}
	};

resource 'DLOG' (1261, purgeable)
	{
	{0, 0, 242, 390},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1261,
	""
	};

resource 'DITL' (1261, purgeable)
	{
		{
		{15, 305, 35, 375},   Button { enabled, "OK" },
		{45, 305, 65, 375},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{85, 305, 105, 375},  Button { enabled, "Load…" },
		{85, -80, 105, -20},  Button { enabled, "<-Default" },
		{111, 305, 131, 375}, Button { enabled, "Save…" },
		{111, -80, 131, -20}, Button { enabled, "->Default" },
		{60, 100, 76, 130},   EditText { enabled, "" },
		{60, 140, 76, 170},   EditText { enabled, "" },
		{60, 180, 76, 210},   EditText { enabled, "" },
		{60, 220, 76, 250},   EditText { enabled, "" },
		{88, 100, 104, 130},  EditText { enabled, "" },
		{88, 140, 104, 170},  EditText { enabled, "" },
		{88, 180, 104, 210},  EditText { enabled, "" },
		{88, 220, 104, 250},  EditText { enabled, "" },
		{116, 100, 132, 130}, EditText { enabled, "" },
		{116, 140, 132, 170}, EditText { enabled, "" },
		{116, 180, 132, 210}, EditText { enabled, "" },
		{116, 220, 132, 250}, EditText { enabled, "" },
		{144, 100, 160, 130}, EditText { enabled, "" },
		{144, 140, 160, 170}, EditText { enabled, "" },
		{144, 180, 160, 210}, EditText { enabled, "" },
		{144, 220, 160, 250}, EditText { enabled, "" },
		{172, 100, 188, 130}, EditText { enabled, "" },
		{172, 140, 188, 170}, EditText { enabled, "" },
		{172, 180, 188, 210}, EditText { enabled, "" },
		{172, 220, 188, 250}, EditText { enabled, "" },
		{206, 170, 222, 205}, EditText { enabled, "" },
		{10, 10, 26, 160},	  StaticText { disabled, "Transfer Functions…" },
		{36, 105, 52, 130},   StaticText { disabled, "C:" },
		{36, 145, 52, 170},   StaticText { disabled, "M:" },
		{36, 185, 52, 210},   StaticText { disabled, "Y:" },
		{36, 225, 52, 250},   StaticText { disabled, "K:" },
		{60, 20, 76, 95},	  StaticText { enabled, "Highlights:" },
		{88, 21, 104, 95},	  StaticText { enabled, "1/4 Tones:" },
		{116, 24, 132, 95},   StaticText { enabled, "Midtones:" },
		{144, 21, 160, 95},   StaticText { enabled, "3/4 Tones:" },
		{172, 27, 188, 95},   StaticText { enabled, "Shadows:" },
		{60, 255, 76, 275},   StaticText { disabled, "%" },
		{88, 255, 104, 275},  StaticText { disabled, "%" },
		{116, 255, 132, 275}, StaticText { disabled, "%" },
		{144, 255, 160, 275}, StaticText { disabled, "%" },
		{172, 255, 188, 275}, StaticText { disabled, "%" },
		{206, 60, 222, 160},  StaticText { enabled, "Image Gamma:" }
		}
	};

resource 'DLOG' (1270, purgeable)
	{
	{0, 0, 106, 446},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1270,
	""
	};

resource 'DITL' (1270, purgeable)
	{
		{
		{72, 16, 92, 96},	  Button { enabled, "Proceed" },
		{72, 120, 92, 180},   Button { enabled, "Pause" },
		{72, 200, 92, 260},   Button { enabled, "Cancel" },
		{72, 280, 92, 430},   Button { enabled, "Cancel All Printing" };
		{16, 24, 60, 410},	  StaticText { disabled,
							  "Now printing:  ^0" }
		}
	};

resource 'DLOG' (1271, purgeable)
	{
	{0, 0, 106, 384},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1271,
	""
	};

resource 'DITL' (1271, purgeable)
	{
		{
		{72, 24, 92, 104},	  Button { enabled, "Proceed" },
		{72, 128, 92, 208},   Button { enabled, "Pause" },
		{72, 232, 92, 362},   Button { enabled, "Cancel Printing" },
		{16, 24, 60, 360},	  StaticText { disabled,
							  "Now printing:  ^0" }
		}
	};

resource 'DLOG' (1290, purgeable)
	{
	{-30000, -30000, -29900, -29900},
	dBoxProc,
	visible,
	noGoAway,
	0x0,
	1290,
	""
	};

resource 'DITL' (1290, purgeable)
	{
		{
		}
	};

resource 'DLOG' (1300, purgeable)
	{
	{0, 0, 230, 304},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1300,
	""
	};

resource 'DITL' (1300, purgeable)
	{
		{
		{132, 218, 150, 288}, Button { enabled, "Save" },
		{158, 218, 176, 288}, Button { enabled, "Cancel" },
		{136, 14, 152, 197},  StaticText { disabled, "Save as:" },
		{29, 198, 49, 302},   UserItem { disabled },
		{56, 218, 74, 288},   Button { enabled, "Eject" },
		{82, 218, 100, 288},  Button { enabled, "Drive" },
		{157, 17, 173, 194},  EditText { enabled, "" },
		{29, 14, 127, 197},   UserItem { disabled },
		{190, 14, 206, 100},  StaticText { disabled, "File Format:" },
		{189, 100, 208, 220}, UserItem { disabled }
		}
	};

resource 'DLOG' (1400, purgeable)
	{
	{0, 0, 220, 348},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1400,
	""
	};

resource 'DITL' (1400, purgeable)
	{
		{
		{138, 256, 156, 336}, Button { enabled, "Open" },
		{0, 571, 80, 589},	  Button { enabled, "Hidden" },
		{163, 256, 181, 336}, Button { enabled, "Cancel" },
		{39, 232, 59, 347},   UserItem { disabled },
		{68, 256, 86, 336},   Button { enabled, "Eject" },
		{93, 256, 111, 336},  Button { enabled, "Drive" },
		{39, 12, 185, 230},   UserItem { enabled },
		{39, 229, 185, 246},  UserItem { enabled },
		{124, 252, 125, 340}, UserItem { disabled },
		{0, 532, 101, 628},   StaticText { disabled, "" },
		{-116, 0, -100, 0},   StaticText { disabled, "File Format:  " },
		{190, 20, 206, 240},  UserItem { disabled },
		{190, 256, 206, 336}, UserItem { disabled }
		}
	};

resource 'DLOG' (1401, purgeable)
	{
	{0, 0, 239, 348},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1401,
	""
	};

resource 'DITL' (1401, purgeable)
	{
		{
		{138, 256, 156, 336}, Button { enabled, "Open" },
		{0, 571, 80, 589},	  Button { enabled, "Hidden" },
		{163, 256, 181, 336}, Button { enabled, "Cancel" },
		{39, 232, 59, 347},   UserItem { disabled },
		{68, 256, 86, 336},   Button { enabled, "Eject" },
		{93, 256, 111, 336},  Button { enabled, "Drive" },
		{39, 12, 185, 230},   UserItem { enabled },
		{39, 229, 185, 246},  UserItem { enabled },
		{124, 252, 125, 340}, UserItem { disabled },
		{0, 532, 101, 628},   StaticText { disabled, "" },
		{199, 14, 215, 100},  StaticText { disabled, "File Format:" },
		{198, 100, 217, 220}, UserItem { disabled },
		{199, 256, 215, 336}, UserItem { disabled }
		}
	};

resource 'DLOG' (1402, purgeable)
	{
	{0, 0, 220, 348},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1402,
	""
	};

resource 'DITL' (1402, purgeable)
	{
		{
		{138, 256, 156, 336}, Button { enabled, "Open" },
		{0, 571, 80, 589},	  Button { enabled, "Hidden" },
		{188, 256, 206, 336}, Button { enabled, "Cancel" },
		{39, 232, 59, 347},   UserItem { disabled },
		{68, 256, 86, 336},   Button { enabled, "Eject" },
		{93, 256, 111, 336},  Button { enabled, "Drive" },
		{60, 12, 206, 230},   UserItem { enabled },
		{60, 229, 206, 246},  UserItem { enabled },
		{124, 252, 125, 340}, UserItem { disabled },
		{0, 532, 101, 628},   StaticText { disabled, "" },
		{163, 256, 181, 336}, Button { enabled, "New" },
		{10, 10, 26, 250},	  StaticText { disabled,
							  "Where is the preferences file?" }
		}
	};

resource 'DLOG' (1403, purgeable)
	{
	{0, 0, 220, 348},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	1403,
	""
	};

resource 'DITL' (1403, purgeable)
	{
		{
		{138, 256, 156, 336}, Button { enabled, "Open" },
		{0, 571, 80, 589},	  Button { enabled, "Hidden" },
		{163, 256, 181, 336}, Button { enabled, "Cancel" },
		{39, 232, 59, 347},   UserItem { disabled },
		{68, 256, 86, 336},   Button { enabled, "Eject" },
		{93, 256, 111, 336},  Button { enabled, "Drive" },
		{60, 12, 206, 230},   UserItem { enabled },
		{60, 229, 206, 246},  UserItem { enabled },
		{124, 252, 125, 340}, UserItem { disabled },
		{0, 532, 101, 628},   StaticText { disabled, "" },
		{10, 10, 26, 250},	  StaticText { disabled,
							  "Where is part % of “%”?" }
		}
	};

resource 'DLOG' (2000, purgeable)
	{
	{0, 0, 185, 310},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	2000,
	""
	};

resource 'DITL' (2000, purgeable)
	{
		{
		{15, 235, 35, 295},   Button { enabled, "OK" },
		{45, 235, 65, 295},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{58, 30, 74, 200},	  RadioButton { enabled, "1 bit/pixel" },
		{74, 30, 90, 220},	  RadioButton { enabled, "2 bits/pixel" },
		{90, 30, 106, 220},   RadioButton { enabled, "4 bits/pixel" },
		{106, 30, 122, 220},  RadioButton { enabled, "8 bits/pixel" },
		{122, 30, 138, 280},  RadioButton { enabled, "8 bits/pixel,"
													 " System Palette" },
		{138, 30, 154, 220},  RadioButton { enabled, "16 bits/pixel" },
		{154, 30, 170, 220},  RadioButton { enabled, "32 bits/pixel" },
		{10, 10, 26, 225},	  StaticText { disabled, "PICT File Options…" },
		{36, 10, 52, 200},	  StaticText { disabled, "Resolution:" }
		}
	};

resource 'DLOG' (2100, purgeable)
	{
	{0, 0, 285, 360},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	2100,
	""
	};

resource 'DITL' (2100, purgeable)
	{
		{
		{15, 285, 35, 345},   Button { enabled, "OK" },
		{45, 285, 65, 345},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{36, 125, 52, 175},   EditText { enabled, "" },
		{61, 125, 77, 175},   EditText { enabled, "" },
		{159, 30, 175, 200},  RadioButton { enabled, "1 bit/pixel" },
		{175, 30, 191, 220},  RadioButton { enabled, "2 bits/pixel" },
		{191, 30, 207, 220},  RadioButton { enabled, "4 bits/pixel" },
		{207, 30, 223, 220},  RadioButton { enabled, "8 bits/pixel" },
		{223, 30, 239, 280},  RadioButton { enabled, "8 bits/pixel,"
													 " System Palette" },
		{239, 30, 255, 220},  RadioButton { enabled, "16 bits/pixel" },
		{255, 30, 271, 220},  RadioButton { enabled, "32 bits/pixel" },
		{86, 125, 102, 175},  EditText { enabled, "" },
		{111, 125, 127, 342}, EditText { enabled, "" },
		{10, 10, 26, 225},	  StaticText { disabled, "PICT Resource Options…" },
		{36, 53, 52, 120},	  StaticText { enabled, "File Type:" },
		{61, 33, 77, 120},	  StaticText { enabled, "File Creator:" },
		{137, 10, 153, 200},  StaticText { disabled, "Resolution:" },
		{86, 32, 102, 120},   StaticText { enabled, "Resource ID:" },
		{111, 10, 127, 120},  StaticText { enabled, "Resource Name:" }
		}
	};

resource 'DLOG' (2200, purgeable)
	{
	{0, 0, 120, 300},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	2200,
	""
	};

resource 'DITL' (2200, purgeable)
	{
		{
		{15, 225, 35, 285},   Button { enabled, "OK" },
		{45, 225, 65, 285},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{36, 105, 52, 155},   EditText { enabled, "" },
		{61, 105, 77, 155},   EditText { enabled, "" },
		{86, 105, 102, 155},  EditText { enabled, "" },
		{10, 10, 26, 200},	  StaticText { disabled, "Raw Options…" },
		{36, 30, 52, 95},	  StaticText { enabled, "File Type:" },
		{61, 10, 77, 95},	  StaticText { enabled, "File Creator:" },
		{86, 41, 102, 95},	  StaticText { enabled, "Header:" }
		}
	};

resource 'DLOG' (2201, purgeable)
	{
	{0, 0, 180, 300},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	2201,
	""
	};

resource 'DITL' (2201, purgeable)
	{
		{
		{15, 225, 35, 285},   Button { enabled, "OK" },
		{45, 225, 65, 285},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{36, 105, 52, 155},   EditText { enabled, "" },
		{61, 105, 77, 155},   EditText { enabled, "" },
		{86, 105, 102, 155},  EditText { enabled, "" },
		{134, 30, 150, 200},  RadioButton { enabled,
							  "Interleaved Order" },
		{150, 30, 166, 200},  RadioButton { enabled,
							  "Non-interleaved Order" },
		{10, 10, 26, 200},	  StaticText { disabled, "Raw Options…" },
		{36, 30, 52, 95},	  StaticText { enabled, "File Type:" },
		{61, 10, 77, 95},	  StaticText { enabled, "File Creator:" },
		{86, 41, 102, 95},	  StaticText { enabled, "Header:" },
		{112, 10, 128, 220},  StaticText { disabled, "Save image in:" }
		}
	};

resource 'DLOG' (2202, purgeable)
	{
	{0, 0, 165, 400},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	2202,
	""
	};

resource 'DITL' (2202, purgeable)
	{
		{
		{15, 325, 35, 385},   Button { enabled, "OK" },
		{45, 325, 65, 385},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{54, 115, 70, 160},   EditText { enabled, "" },
		{79, 115, 95, 160},   EditText { enabled, "" },
		{104, 115, 120, 160}, EditText { enabled, "" },
		{104, 173, 120, 275}, CheckBox { enabled, "Interleaved" },
		{129, 115, 145, 190}, EditText { enabled, "" },
		{85, 325, 105, 385},  Button { enabled, "Swap" },
		{111, 325, 131, 385}, Button { enabled, "Guess" },
		{10, 10, 26, 305},	  StaticText { disabled,
							  "Specify parameters of “^0”:" },
		{26, 10, 42, 305},	  StaticText { disabled, "(^1 bytes)" },
		{54, 59, 70, 105},	  StaticText { enabled, "Width:" },
		{54, 170, 70, 225},   StaticText { disabled, "(pixels)" },
		{79, 55, 95, 105},	  StaticText { enabled, "Height:" },
		{79, 170, 95, 225},   StaticText { disabled, "(pixels)" },
		{104, 38, 120, 105},  StaticText { enabled, "Channels:" },
		{129, 51, 145, 105},  StaticText { enabled, "Header:" },
		{129, 200, 145, 255}, StaticText { disabled, "(bytes)" }
		}
	};

resource 'DLOG' (2203, purgeable)
	{
	{0, 0, 100, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	2203,
	""
	};

resource 'DITL' (2203, purgeable)
	{
		{
		{60, 210, 80, 280},   Button { enabled, "Cancel" };
		{10, 20, 42, 52},	  Icon { disabled, 0 },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 62, 42, 300},	  StaticText { disabled,
							  "Specified image is larger than file." }
		}
	};

resource 'DLOG' (2204, purgeable)
	{
	{0, 0, 100, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	2204,
	""
	};

resource 'DITL' (2204, purgeable)
	{
		{
		{60, 80, 80, 150},	  Button { enabled, "OK" },
		{60, 210, 80, 280},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{10, 20, 42, 52},	  Icon { disabled, 2 },
		{10, 62, 42, 300},	  StaticText { disabled,
							  "Specified image is smaller than file;"
							  " open anyway?" }
		}
	};

resource 'DLOG' (2300, purgeable)
	{
	{0, 0, 125, 300},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	2300,
	""
	};

resource 'DITL' (2300, purgeable)
	{
		{
		{15, 225, 35, 285},   Button { enabled, "OK" },
		{45, 225, 65, 285},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{58, 30, 74, 160},	  RadioButton { enabled, "1 bit/pixel" },
		{74, 30, 90, 160},	  RadioButton { enabled, "4 bits/pixel" },
		{90, 30, 106, 160},   RadioButton { enabled, "5 bits/pixel" },
		{10, 10, 26, 220},	  StaticText { disabled, "ThunderScan Options…" },
		{36, 10, 52, 200},	  StaticText { disabled, "Resolution:" }
		}
	};

resource 'DLOG' (2400, purgeable)
	{
	{0, 0, 136, 300},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	2400,
	""
	};

resource 'DITL' (2400, purgeable)
	{
		{
		{15, 225, 35, 285},   Button { enabled, "OK" },
		{45, 225, 65, 285},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{56, 30, 72, 120},	  RadioButton { enabled, "IBM PC" },
		{72, 30, 88, 120},	  RadioButton { enabled, "Macintosh" },
		{100, 10, 116, 150},  Checkbox { enabled, "LZW Compression" },
		{10, 10, 26, 200},	  StaticText { disabled, "TIFF Options…" },
		{36, 10, 52, 100},	  StaticText { disabled, "Format:" }
		}
	};

resource 'DLOG' (2500, purgeable)
	{
	{0, 0, 205, 300},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	2500,
	""
	};

resource 'DITL' (2500, purgeable)
	{
		{
		{15, 225, 35, 285},   Button { enabled, "OK" },
		{45, 225, 65, 285},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{58, 30, 74, 160},	  RadioButton { enabled, "1 bit/pixel" },
		{74, 30, 90, 160},	  RadioButton { enabled, "2 bits/pixel" },
		{90, 30, 106, 160},   RadioButton { enabled, "3 bits/pixel" },
		{106, 30, 122, 160},  RadioButton { enabled, "4 bits/pixel" },
		{122, 30, 138, 160},  RadioButton { enabled, "5 bits/pixel" },
		{138, 30, 154, 160},  RadioButton { enabled, "6 bits/pixel" },
		{154, 30, 170, 160},  RadioButton { enabled, "7 bits/pixel" },
		{170, 30, 186, 160},  RadioButton { enabled, "8 bits/pixel" },
		{10, 10, 26, 220},	  StaticText { disabled,
							  "CompuServe GIF Options…" },
		{36, 10, 52, 200},	  StaticText { disabled, "Resolution:" }
		}
	};

resource 'DLOG' (2600, purgeable)
	{
	{0, 0, 110, 300},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	2600,
	""
	};

resource 'DITL' (2600, purgeable)
	{
		{
		{15, 225, 35, 285},   Button { enabled, "OK" },
		{45, 225, 65, 285},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{58, 30, 74, 200},	  RadioButton { enabled, "Center" },
		{74, 30, 90, 200},	  RadioButton { enabled, "Top-Left Corner" },
		{10, 10, 26, 200},	  StaticText { disabled, "MacPaint Options…" },
		{36, 10, 52, 200},	  StaticText { disabled, "Position on Page:" }
		}
	};

resource 'DLOG' (2700, purgeable)
	{
	{0, 0, 205, 300},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	2700,
	""
	};

resource 'DITL' (2700, purgeable)
	{
		{
		{15, 225, 35, 285},   Button { enabled, "OK" },
		{45, 225, 65, 285},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{74, 30, 90, 240},	  RadioButton { enabled,
											"576 by 720 pixels" },
		{58, 30, 74, 240},	  RadioButton { enabled,
											"512 by 512 pixels" },
		{106, 30, 122, 240},  RadioButton { enabled,
											"1024 by 1024 pixels" },
		{90, 30, 106, 240},   RadioButton { enabled,
											"1024 by 768 pixels" },
		{152, 30, 168, 200},  RadioButton { enabled, "Center" },
		{168, 30, 184, 200},  RadioButton { enabled, "Top-Left Corner" },
		{10, 10, 26, 200},	  StaticText { disabled, "PixelPaint Options…" },
		{36, 10, 52, 200},	  StaticText { disabled, "Canvas Size:" },
		{130, 10, 146, 200},  StaticText { disabled, "Position on Canvas:" }
		}
	};

resource 'DLOG' (2800, purgeable)
	{
	{0, 0, 205, 300},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	2800,
	""
	};

resource 'DITL' (2800, purgeable)
	{
		{
		{15, 225, 35, 285},   Button { enabled, "OK" },
		{45, 225, 65, 285},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{58, 30, 74, 160},	  RadioButton { enabled, "1 bit/pixel" },
		{74, 30, 90, 160},	  RadioButton { enabled, "2 bits/pixel" },
		{90, 30, 106, 160},   RadioButton { enabled, "3 bits/pixel" },
		{106, 30, 122, 160},  RadioButton { enabled, "4 bits/pixel" },
		{122, 30, 138, 160},  RadioButton { enabled, "5 bits/pixel" },
		{138, 30, 154, 160},  RadioButton { enabled, "6 bits/pixel" },
		{154, 30, 170, 160},  RadioButton { enabled, "7 bits/pixel" },
		{170, 30, 186, 160},  RadioButton { enabled, "8 bits/pixel" },
		{10, 10, 26, 220},	  StaticText { disabled,
							  "Amiga IFF/ILBM Options…" },
		{36, 10, 52, 200},	  StaticText { disabled, "Resolution:" }
		}
	};

resource 'DLOG' (2900, purgeable)
	{
	{0, 0, 126, 300},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	2900,
	""
	};

resource 'DITL' (2900, purgeable)
	{
		{
		{15, 225, 35, 285},   Button { enabled, "OK" },
		{45, 225, 65, 285},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{58, 30, 74, 160},	  RadioButton { enabled, "16 bits/pixel" },
		{74, 30, 90, 160},	  RadioButton { enabled, "24 bits/pixel" },
		{90, 30, 106, 160},   RadioButton { enabled, "32 bits/pixel" },
		{10, 10, 26, 200},	  StaticText { disabled, "TGA Options…" },
		{36, 10, 52, 200},	  StaticText { disabled, "Resolution:" }
		}
	};

resource 'DLOG' (3000, purgeable)
	{
	{0, 0, 95, 300},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	3000,
	""
	};

resource 'DITL' (3000, purgeable)
	{
		{
		{15, 225, 35, 285},   Button { enabled, "OK" },
		{45, 225, 65, 285},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{36, 105, 52, 155},   EditText { enabled, "" },
		{61, 105, 77, 155},   EditText { enabled, "" },
		{10, 10, 26, 200},	  StaticText { disabled, "PIXAR Options…" },
		{36, 30, 52, 95},	  StaticText { enabled, "File Type:" },
		{61, 10, 77, 95},	  StaticText { enabled, "File Creator:" }
		}
	};

resource 'DLOG' (3100, purgeable)
	{
	{0, 0, 130, 330},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	3100,
	""
	};

resource 'DITL' (3100, purgeable)
	{
		{
		{15, 255, 35, 315},   Button { enabled, "OK" },
		{45, 255, 65, 315},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{58, 30, 74, 150},	  RadioButton { enabled, "None" },
		{74, 30, 90, 150},	  RadioButton { enabled, "1 bit/pixel" },
		{-80, 30, -60, 150},  RadioButton { enabled, "8 bits/pixel" },
		{58, 170, 74, 240},   RadioButton { enabled, "ASCII" },
		{74, 170, 90, 240},   RadioButton { enabled, "Binary" },
		{98, 10, 114, 250},   CheckBox { enabled, "Transparent Whites" },
		{10, 10, 26, 200},	  StaticText { disabled, "EPS Options…" },
		{36, 10, 52, 130},	  StaticText { disabled, "Preview PICT:" },
		{36, 150, 52, 240},   StaticText { disabled, "Encoding:" }
		}
	};

resource 'DLOG' (3101, purgeable)
	{
	{0, 0, 165, 330},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	3101,
	""
	};

resource 'DITL' (3101, purgeable)
	{
		{
		{15, 255, 35, 315},   Button { enabled, "OK" },
		{45, 255, 65, 315},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{58, 30, 74, 150},	  RadioButton { enabled, "None" },
		{74, 30, 90, 150},	  RadioButton { enabled, "1 bit/pixel" },
		{90, 30, 106, 150},   RadioButton { enabled, "4 bits/pixel" },
		{58, 170, 74, 240},   RadioButton { enabled, "ASCII" },
		{74, 170, 90, 240},   RadioButton { enabled, "Binary" },
		{115, 10, 131, 250},  CheckBox { enabled, "Include Halftone Screen" },
		{131, 10, 147, 250},  CheckBox { enabled, "Include Transfer Function" },
		{10, 10, 26, 200},	  StaticText { disabled, "EPS Options…" },
		{36, 10, 52, 130},	  StaticText { disabled, "Preview PICT:" },
		{36, 150, 52, 240},   StaticText { disabled, "Encoding:" }
		}
	};

resource 'DLOG' (3102, purgeable)
	{
	{0, 0, 165, 330},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	3102,
	""
	};

resource 'DITL' (3102, purgeable)
	{
		{
		{15, 255, 35, 315},   Button { enabled, "OK" },
		{45, 255, 65, 315},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{58, 30, 74, 150},	  RadioButton { enabled, "None" },
		{74, 30, 90, 150},	  RadioButton { enabled, "1 bit/pixel" },
		{90, 30, 106, 150},   RadioButton { enabled, "8 bits/pixel" },
		{58, 170, 74, 240},   RadioButton { enabled, "ASCII" },
		{74, 170, 90, 240},   RadioButton { enabled, "Binary" },
		{115, 10, 131, 250},  CheckBox { enabled, "Include Halftone Screens" },
		{131, 10, 147, 250},  CheckBox { enabled, "Include Transfer Functions" },
		{10, 10, 26, 200},	  StaticText { disabled, "EPS Options…" },
		{36, 10, 52, 130},	  StaticText { disabled, "Preview PICT:" },
		{36, 150, 52, 240},   StaticText { disabled, "Encoding:" }
		}
	};

resource 'DLOG' (3103, purgeable)
	{
	{0, 0, 182, 330},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	3103,
	""
	};

resource 'DITL' (3103, purgeable)
	{
		{
		{15, 255, 35, 315},   Button { enabled, "OK" },
		{45, 255, 65, 315},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{58, 30, 74, 150},	  RadioButton { enabled, "None" },
		{74, 30, 90, 150},	  RadioButton { enabled, "1 bit/pixel" },
		{90, 30, 106, 150},   RadioButton { enabled, "8 bits/pixel" },
		{58, 170, 74, 240},   RadioButton { enabled, "ASCII" },
		{74, 170, 90, 240},   RadioButton { enabled, "Binary" },
		{115, 10, 131, 250},  CheckBox { enabled, "Include Halftone Screens" },
		{131, 10, 147, 250},  CheckBox { enabled, "Include Transfer Functions" },
		{154, 10, 170, 300},  CheckBox { enabled,
							  "“Desktop Color Separation” (5 files)" },
		{10, 10, 26, 200},	  StaticText { disabled, "EPS Options…" },
		{36, 10, 52, 130},	  StaticText { disabled, "Preview PICT:" },
		{36, 150, 52, 240},   StaticText { disabled, "Encoding:" }
		}
	};

resource 'DLOG' (4001, purgeable)
	{
	{0, 0, 274, 370},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	4001,
	""
	};

resource 'DITL' (4001, purgeable)
	{
		{
		{15, 295, 35, 355},   Button { enabled, "OK" },
		{45, 295, 65, 355},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{40, 20, 56, 55},	  EditText { enabled, "" },
		{40, 70, 56, 105},	  EditText { enabled, "" },
		{40, 120, 56, 155},   EditText { enabled, "" },
		{40, 170, 56, 205},   EditText { enabled, "" },
		{40, 220, 56, 255},   EditText { enabled, "" },
		{72, 20, 88, 55},	  EditText { enabled, "" },
		{72, 70, 88, 105},	  EditText { enabled, "" },
		{72, 120, 88, 155},   EditText { enabled, "" },
		{72, 170, 88, 205},   EditText { enabled, "" },
		{72, 220, 88, 255},   EditText { enabled, "" },
		{104, 20, 120, 55},   EditText { enabled, "" },
		{104, 70, 120, 105},  EditText { enabled, "" },
		{104, 120, 120, 155}, EditText { enabled, "" },
		{104, 170, 120, 205}, EditText { enabled, "" },
		{104, 220, 120, 255}, EditText { enabled, "" },
		{136, 20, 152, 55},   EditText { enabled, "" },
		{136, 70, 152, 105},  EditText { enabled, "" },
		{136, 120, 152, 155}, EditText { enabled, "" },
		{136, 170, 152, 205}, EditText { enabled, "" },
		{136, 220, 152, 255}, EditText { enabled, "" },
		{168, 20, 184, 55},   EditText { enabled, "" },
		{168, 70, 184, 105},  EditText { enabled, "" },
		{168, 120, 184, 155}, EditText { enabled, "" },
		{168, 170, 184, 205}, EditText { enabled, "" },
		{168, 220, 184, 255}, EditText { enabled, "" },
		{204, 115, 220, 160}, EditText { enabled, "" },
		{234, 115, 250, 160}, EditText { enabled, "" },
		{90, 295, 110, 355},  Button { enabled, "Load…" },
		{116, 295, 136, 355}, Button { enabled, "Save…" },
		{10, 15, 26, 160},	  StaticText { disabled, "Custom…" },
		{204, 63, 220, 110},  StaticText { enabled, "Scale:" },
		{234, 56, 250, 110},  StaticText { enabled, "Offset:" }
		}
	};

resource 'DLOG' (4002, purgeable)
	{
	{0, 0, 183, 350},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	4002,
	""
	};

resource 'DITL' (4002, purgeable)
	{
		{
		{15, 275, 35, 335},   Button { enabled, "OK" },
		{45, 275, 65, 335},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{38, 100, 54, 150},   EditText { enabled, "" },
		{64, 100, 80, 150},   EditText { enabled, "" },
		{115, 30, 131, 180},  RadioButton { enabled, "Set to background" },
		{131, 30, 147, 180},  RadioButton { enabled, "Repeat edge pixels" },
		{147, 30, 163, 180},  RadioButton { enabled, "Wrap around" },
		{10, 10, 26, 160},	  StaticText { disabled, "Offset…" },
		{38, 15, 54, 95},	  StaticText { enabled, "Horizontal:" },
		{38, 160, 54, 260},   StaticText { disabled, "(pixels right)" },
		{64, 32, 80, 95},	  StaticText { enabled, "Vertical:" },
		{64, 160, 80, 260},   StaticText { disabled, "(pixels down)" },
		{95, 10, 111, 160},   StaticText { disabled, "Undefined Areas:" }
		}
	};

resource 'DLOG' (4003, purgeable)
	{
	{0, 0, 85, 280},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	4003,
	""
	};

resource 'DITL' (4003, purgeable)
	{
		{
		{15, 205, 35, 265},   Button { enabled, "OK" },
		{45, 205, 65, 265},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{38, 68, 54, 113},	  EditText { enabled, "" },
		{10, 10, 26, 160},	  StaticText { disabled, "Gaussian Blur…" },
		{38, 10, 54, 63},	  StaticText { enabled, "Radius:" },
		{38, 123, 54, 183},   StaticText { disabled, "(pixels)" }
		}
	};

resource 'DLOG' (4005, purgeable)
	{
	{0, 0, 85, 270},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	4005,
	""
	};

resource 'DITL' (4005, purgeable)
	{
		{
		{15, 195, 35, 255},   Button { enabled, "OK" },
		{45, 195, 65, 255},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{38, 68, 54, 90},	  EditText { enabled, "" },
		{10, 10, 26, 160},	  StaticText { disabled, "Maximum…" },
		{38, 10, 54, 63},	  StaticText { enabled, "Radius:" },
		{38, 100, 54, 160},   StaticText { disabled, "(pixels)" }
		}
	};

resource 'DLOG' (4006, purgeable)
	{
	{0, 0, 85, 270},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	4006,
	""
	};

resource 'DITL' (4006, purgeable)
	{
		{
		{15, 195, 35, 255},   Button { enabled, "OK" },
		{45, 195, 65, 255},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{38, 68, 54, 90},	  EditText { enabled, "" },
		{10, 10, 26, 160},	  StaticText { disabled, "Minimum…" },
		{38, 10, 54, 63},	  StaticText { enabled, "Radius:" },
		{38, 100, 54, 160},   StaticText { disabled, "(pixels)" }
		}
	};

resource 'DLOG' (4011, purgeable)
	{
	{0, 0, 85, 280},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	4011,
	""
	};

resource 'DITL' (4011, purgeable)
	{
		{
		{15, 205, 35, 265},   Button { enabled, "OK" },
		{45, 205, 65, 265},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{38, 68, 54, 113},	  EditText { enabled, "" },
		{10, 10, 26, 170},	  StaticText { disabled, "High Pass…" },
		{38, 10, 54, 63},	  StaticText { enabled, "Radius:" },
		{38, 123, 54, 183},   StaticText { disabled, "(pixels)" }
		}
	};

resource 'DLOG' (4012, purgeable)
	{
	{0, 0, 85, 270},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	4012,
	""
	};

resource 'DITL' (4012, purgeable)
	{
		{
		{15, 195, 35, 255},   Button { enabled, "OK" },
		{45, 195, 65, 255},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{38, 68, 54, 90},	  EditText { enabled, "" },
		{10, 10, 26, 160},	  StaticText { disabled, "Median…" },
		{38, 10, 54, 63},	  StaticText { enabled, "Radius:" },
		{38, 100, 54, 160},   StaticText { disabled, "(pixels)" }
		}
	};

resource 'DLOG' (4014, purgeable)
	{
	{0, 0, 110, 280},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	4014,
	""
	};

resource 'DITL' (4014, purgeable)
	{
		{
		{15, 205, 35, 265},   Button { enabled, "OK" },
		{45, 205, 65, 265},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{38, 80, 54, 110},	  EditText { enabled, "" },
		{68, 80, 84, 110},	  EditText { enabled, "" },
		{10, 10, 26, 170},	  StaticText { disabled, "Motion Blur…" },
		{38, 30, 54, 75},	  StaticText { enabled, "Angle:" },
		{38, 120, 54, 190},   StaticText { disabled, "(degrees)" },
		{68, 10, 84, 75},	  StaticText { enabled, "Distance:" },
		{68, 120, 84, 180},   StaticText { disabled, "(pixels)" }
		}
	};

resource 'DLOG' (4015, purgeable)
	{
	{0, 0, 120, 270},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	4015,
	""
	};

resource 'DITL' (4015, purgeable)
	{
		{
		{15, 195, 35, 255},   Button { enabled, "OK" },
		{45, 195, 65, 255},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{52, 30, 68, 180},	  RadioButton { enabled, "Normal" },
		{68, 30, 84, 180},	  RadioButton { enabled, "Darken Only" },
		{84, 30, 100, 180},   RadioButton { enabled, "Lighten Only" },
		{10, 10, 26, 160},	  StaticText { disabled, "Diffuse…" },
		{32, 10, 48, 160},	  StaticText { disabled, "Mode:" }
		}
	};

resource 'DLOG' (4016, purgeable)
	{
	{0, 0, 140, 270},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	4016,
	""
	};

resource 'DITL' (4016, purgeable)
	{
		{
		{15, 195, 35, 255},   Button { enabled, "OK" },
		{45, 195, 65, 255},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{38, 75, 54, 105},	  EditText { enabled, "" },
		{90, 30, 106, 180},   RadioButton { enabled, "Uniform" },
		{106, 30, 122, 180},  RadioButton { enabled, "Gaussian" },
		{10, 10, 26, 160},	  StaticText { disabled, "Add Noise…" },
		{38, 10, 54, 70},	  StaticText { enabled, "Amount:" },
		{70, 10, 86, 160},	  StaticText { disabled, "Distribution:" }
		}
	};

resource 'DLOG' (4017, purgeable)
	{
	{0, 0, 135, 270},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	4017,
	""
	};

resource 'DITL' (4017, purgeable)
	{
		{
		{15, 195, 35, 255},   Button { enabled, "OK" },
		{45, 195, 65, 255},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{38, 65, 54, 95},	  EditText { enabled, "" },
		{87, 30, 103, 100},   RadioButton { enabled, "Lower" },
		{103, 30, 119, 100},  RadioButton { enabled, "Upper" },
		{10, 10, 26, 160},	  StaticText { disabled, "Trace Contour…" },
		{38, 10, 54, 60},	  StaticText { enabled, "Level:" },
		{67, 10, 83, 160},	  StaticText { disabled, "Edge:" }
		}
	};

resource 'DLOG' (4018, purgeable)
	{
	{0, 0, 85, 320},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	4018,
	""
	};

resource 'DITL' (4018, purgeable)
	{
		{
		{15, 245, 35, 305},   Button { enabled, "OK" },
		{45, 245, 65, 305},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{38, 83, 54, 110},	  EditText { enabled, "" },
		{10, 10, 26, 160},	  StaticText { disabled, "Mosaic…" },
		{38, 10, 54, 73},	  StaticText { enabled, "Cell Size:" },
		{38, 120, 54, 240},   StaticText { disabled, "(pixels square)" }
		}
	};

resource 'DLOG' (4021, purgeable)
	{
	{0, 0, 110, 280},
	dBoxProc,
	invisible,
	noGoAway,
	0x0,
	4021,
	""
	};

resource 'DITL' (4021, purgeable)
	{
		{
		{15, 205, 35, 265},   Button { enabled, "OK" },
		{45, 205, 65, 265},   Button { enabled, "Cancel" },
		{0, 0, 0, 0},		  UserItem { disabled },
		{38, 82, 54, 115},	  EditText { enabled, "" },
		{68, 82, 84, 115},	  EditText { enabled, "" },
		{10, 10, 26, 170},	  StaticText { disabled, "Unsharp Mask…" },
		{38, 15, 54, 75},	  StaticText { enabled, "Amount:" },
		{38, 125, 54, 145},   StaticText { disabled, "%" },
		{68, 22, 84, 75},	  StaticText { enabled, "Radius:" },
		{68, 125, 84, 190},   StaticText { disabled, "(pixels)" }
		}
	};

#if Barneyscan

resource 'PICT' (1001)
	{
	2013,
	{0, 0, 199, 51},
	$"1101 0100 0A00 0000 0000 C700 33A0 0082"
	$"A000 8E98 0008 0000 0000 00C7 0033 0000"
	$"0000 00C7 0033 0000 0000 00C7 0033 0000"
	$"05FB FF01 E000 0907 8000 0040 0000 2000"
	$"0907 8000 0040 0000 2000 0907 8000 0040"
	$"0000 2000 0907 8000 0040 0000 2000 0907"
	$"879F 3840 0F00 2000 0907 8400 0840 6060"
	$"2000 0907 8400 0840 8010 2000 0907 8000"
	$"0841 0008 2000 0907 8000 0040 0000 2000"
	$"0907 8400 0042 0004 2000 0907 8400 0842"
	$"0004 2000 0907 8400 0842 0004 2000 0907"
	$"8000 0842 0004 2000 0907 8000 0040 0000"
	$"2000 0907 8400 0041 0008 2000 0907 8400"
	$"0840 8010 2000 0907 8400 0840 6060 2000"
	$"0907 873E 7840 0F00 2000 0907 8000 0040"
	$"0000 2000 0907 8000 0040 0000 2000 0907"
	$"8000 0040 0000 2000 05FB FF01 E000 0907"
	$"8000 0040 0000 2000 0907 8000 0040 0000"
	$"2000 0907 8000 0040 0000 2000 0907 8000"
	$"0040 4000 2000 0907 801F C041 1000 2000"
	$"0907 80E0 3040 A000 2000 0907 8100 0842"
	$"4800 2000 0907 8200 0840 A000 2000 0907"
	$"8400 0841 1000 2000 0907 8400 3040 4400"
	$"2000 0907 8401 C040 0A00 2000 0907 838E"
	$"0040 0500 2000 0907 8670 0040 0380 2000"
	$"0907 8540 0040 01C0 2000 0907 8380 0040"
	$"00E0 2000 0907 8080 0040 0070 2000 0907"
	$"8080 0040 0038 2000 0907 8100 0040 001C"
	$"2000 0907 8000 0040 0008 2000 0907 8000"
	$"0040 0000 2000 0907 8000 0040 0000 2000"
	$"05FB FF01 E000 0907 8000 0040 0000 2000"
	$"0907 8000 0040 0000 2000 0907 8000 0040"
	$"0000 2000 0907 800C 0040 0000 2000 0907"
	$"80D3 8040 3C00 2000 0907 8132 4040 C300"
	$"2000 0907 8132 5040 8100 2000 0907 8092"
	$"6841 0080 2000 0907 8092 4841 0080 2000"
	$"0907 8340 4841 0080 2000 0907 84C0 0841"
	$"0080 2000 0907 8440 1040 8100 2000 0907"
	$"8200 1040 C380 2000 0907 8100 1040 3DC0"
	$"2000 0907 8100 2040 00E0 2000 0907 8080"
	$"2040 0070 2000 0900 80FE 4003 0038 2000"
	$"0907 8020 4040 001C 2000 0907 8020 4040"
	$"0008 2000 0907 8000 0040 0000 2000 0907"
	$"8000 0040 0000 2000 05FB FF01 E000 0907"
	$"8000 0040 0000 2000 0907 8000 0040 0000"
	$"2000 0907 8000 0040 0000 2000 0907 8038"
	$"0040 0000 2000 0907 8044 0040 0000 2000"
	$"0907 804C 0043 DD44 2000 0907 8056 0043"
	$"F690 2000 0907 8065 8043 DD44 2000 0907"
	$"8044 E043 F690 2000 0907 8084 7043 DD44"
	$"2000 0907 810A 3843 F690 2000 0907 8204"
	$"3843 DD44 2000 0907 8400 7843 F690 2000"
	$"0907 8400 B843 DD44 2000 0907 8201 3843"
	$"F690 2000 0907 8102 3843 DD44 2000 0907"
	$"8084 3040 0000 2000 0907 8048 2040 0000"
	$"2000 0907 8030 0040 0000 2000 0907 8000"
	$"0040 0000 2000 0907 8000 0040 0000 2000"
	$"05FB FF01 E000 0907 8000 0040 0000 2000"
	$"0907 8000 0040 0000 2000 0907 8000 0040"
	$"0000 2000 0907 8000 0040 0038 2000 0907"
	$"8300 0040 007C 2000 0907 8180 0040 007C"
	$"2000 0907 80C0 0040 03FC 2000 0907 8060"
	$"0040 01F8 2000 0907 8030 0040 02E0 2000"
	$"0907 8018 0040 0460 2000 0907 800C 0040"
	$"08A0 2000 0907 8006 0040 1100 2000 0907"
	$"8003 0040 2200 2000 0907 8001 8040 4400"
	$"2000 0907 8000 C040 8800 2000 0907 8000"
	$"6041 1000 2000 0907 8000 3041 2000 2000"
	$"0907 8000 0042 C000 2000 0907 8000 0041"
	$"0000 2000 0907 8000 0040 0000 2000 0907"
	$"8000 0040 0000 2000 05FB FF01 E000 0907"
	$"8000 0040 0000 2000 0907 8000 0040 0000"
	$"2000 0907 8000 0040 0000 2000 0907 8000"
	$"0040 0000 2000 0907 8000 0040 03C0 2000"
	$"0907 8000 0040 0220 2000 0907 8007 F840"
	$"0420 2000 0907 8008 1840 0640 2000 0907"
	$"8010 2840 09C0 2000 0907 8020 4840 0880"
	$"2000 0907 8040 9040 1080 2000 0907 8081"
	$"2040 1100 2000 0907 8102 4040 2100 2000"
	$"0907 83FC 8040 2200 2000 0907 8205 0040"
	$"3200 2000 0907 8206 0040 3C00 2000 0907"
	$"83FC 0040 3800 2000 0907 8000 0040 3000"
	$"2000 0907 8000 0040 2000 2000 0907 8000"
	$"0040 0000 2000 0907 8000 0040 0000 2000"
	$"05FB FF01 E000 0907 8000 0040 0000 2000"
	$"0907 8000 0040 0000 2000 0907 8000 0040"
	$"0000 2000 0907 8000 3840 0090 2000 0907"
	$"8000 7840 0090 2000 0907 8000 F840 0120"
	$"2000 0907 8001 F040 0120 2000 0907 8003"
	$"E040 0240 2000 0907 8067 C040 0240 2000"
	$"0907 80CF 8040 0480 2000 0907 80BF 0040"
	$"0480 2000 0907 802E 0040 0F00 2000 0907"
	$"8044 0040 1300 2000 0907 8088 0040 2300"
	$"2000 0907 8118 1840 2700 2000 0907 8224"
	$"2040 4E00 2000 0907 8244 2040 5C00 2000"
	$"0907 8582 4040 B800 2000 0907 8601 8041"
	$"E000 2000 0907 8000 0040 0000 2000 0907"
	$"8000 0040 0000 2000 05FB FF01 E000 0907"
	$"8000 0040 0000 2000 0907 8000 0040 0000"
	$"2000 0907 8000 0040 0000 2000 0907 800E"
	$"0040 0810 2000 0907 8011 0040 1010 2000"
	$"0907 802E 8040 2010 2000 0907 8020 8040"
	$"5008 2000 0907 8020 8040 A808 2000 0907"
	$"8011 0040 D408 2000 0907 800E 0040 A888"
	$"2000 0907 800A 0040 D188 2000 0907 80FB"
	$"E040 5288 2000 0907 810E 1040 6710 2000"
	$"0907 8200 0840 2420 2000 0907 83FF F840"
	$"4FC0 2000 0907 821F 0840 4800 2000 0907"
	$"820E 0840 9000 2000 0907 8204 0841 2000"
	$"2000 0907 81FF F041 C000 2000 0907 8000"
	$"0040 0000 2000 0907 8000 0040 0000 2000"
	$"05FB FF01 E000 0907 8000 0040 0000 2000"
	$"0907 8000 0040 0000 2000 0907 8000 0040"
	$"0000 2000 0907 8004 0040 0400 2000 0907"
	$"8004 0040 0400 2000 0907 800A 0040 0400"
	$"2000 0907 800A 0040 0A00 2000 0907 8011"
	$"0040 0A00 2000 0907 8011 0040 0A00 2000"
	$"0907 8020 8040 1100 2000 0900 80FE 4003"
	$"1100 2000 0900 80FE 4003 1100 2000 0907"
	$"8080 2040 2080 2000 0907 8080 2040 2080"
	$"2000 0907 8080 2040 2080 2000 0902 8080"
	$"20FE 4001 2000 0700 80FC 4001 2000 0902"
	$"8020 80FE 4001 2000 0907 801F 0040 7FC0"
	$"2000 0907 8000 0040 0000 2000 0907 8000"
	$"0040 0000 2000 05FB FF01 E000 A000 8FA0"
	$"0083 FF"
	};

#else

resource 'PICT' (1001)
	{
	2229,
	{0, 0, 221, 51},
	$"1101 0100 0A00 0000 0000 DD00 33A0 0082"
	$"A000 8E98 0008 0000 0000 00DD 0033 0000"
	$"0000 00DD 0033 0000 0000 00DD 0033 0000"
	$"05FB FF01 E000 0907 8000 0040 0000 2000"
	$"0907 8000 0040 0000 2000 0907 8000 0040"
	$"0000 2000 0907 8000 0040 0000 2000 0907"
	$"879F 3840 0F00 2000 0907 8400 0840 6060"
	$"2000 0907 8400 0840 8010 2000 0907 8000"
	$"0841 0008 2000 0907 8000 0040 0000 2000"
	$"0907 8400 0042 0004 2000 0907 8400 0842"
	$"0004 2000 0907 8400 0842 0004 2000 0907"
	$"8000 0842 0004 2000 0907 8000 0040 0000"
	$"2000 0907 8400 0041 0008 2000 0907 8400"
	$"0840 8010 2000 0907 8400 0840 6060 2000"
	$"0907 873E 7840 0F00 2000 0907 8000 0040"
	$"0000 2000 0907 8000 0040 0000 2000 0907"
	$"8000 0040 0000 2000 05FB FF01 E000 0907"
	$"8000 0040 0000 2000 0907 8000 0040 0000"
	$"2000 0907 8000 0040 0000 2000 0907 8000"
	$"0040 4000 2000 0907 801F C041 1000 2000"
	$"0907 80E0 3040 A000 2000 0907 8100 0842"
	$"4800 2000 0907 8200 0840 A000 2000 0907"
	$"8400 0841 1000 2000 0907 8400 3040 4400"
	$"2000 0907 8401 C040 0A00 2000 0907 838E"
	$"0040 0500 2000 0907 8670 0040 0380 2000"
	$"0907 8540 0040 01C0 2000 0907 8380 0040"
	$"00E0 2000 0907 8080 0040 0070 2000 0907"
	$"8080 0040 0038 2000 0907 8100 0040 001C"
	$"2000 0907 8000 0040 0008 2000 0907 8000"
	$"0040 0000 2000 0907 8000 0040 0000 2000"
	$"05FB FF01 E000 0907 8000 0040 0000 2000"
	$"0907 8000 0040 0000 2000 0907 8000 0040"
	$"0000 2000 0907 800C 0040 0000 2000 0907"
	$"80D3 8040 3C00 2000 0907 8132 4040 C300"
	$"2000 0907 8132 5040 8100 2000 0907 8092"
	$"6841 0080 2000 0907 8092 4841 0080 2000"
	$"0907 8340 4841 0080 2000 0907 84C0 0841"
	$"0080 2000 0907 8440 1040 8100 2000 0907"
	$"8200 1040 C380 2000 0907 8100 1040 3DC0"
	$"2000 0907 8100 2040 00E0 2000 0907 8080"
	$"2040 0070 2000 0900 80FE 4003 0038 2000"
	$"0907 8020 4040 001C 2000 0907 8020 4040"
	$"0008 2000 0907 8000 0040 0000 2000 0907"
	$"8000 0040 0000 2000 05FB FF01 E000 0907"
	$"8000 0040 0000 2000 0907 8000 0040 0000"
	$"2000 0907 8000 0040 0000 2000 0907 80C0"
	$"0840 0000 2000 0907 80C0 1040 FFF0 2000"
	$"0907 80C0 2040 C630 2000 0907 87FF C040"
	$"8610 2000 0907 87FF C040 8610 2000 0907"
	$"80C1 C040 0600 2000 0907 80C2 C040 0600"
	$"2000 0907 80C4 C040 0600 2000 0907 80C8"
	$"C040 0600 2000 0907 80D0 C040 0600 2000"
	$"0907 80E0 C040 0600 2000 0907 80FF F840"
	$"0600 2000 0907 80FF F840 0600 2000 0907"
	$"8000 C040 1F80 2000 0907 8000 C040 0000"
	$"2000 0907 8000 C040 0000 2000 0907 8000"
	$"0040 0000 2000 0907 8000 0040 0000 2000"
	$"05FB FF01 E000 0907 8000 0040 0000 2000"
	$"0907 8000 0040 0000 2000 0907 8000 0040"
	$"0000 2000 0907 8038 0040 0000 2000 0907"
	$"8044 0040 0000 2000 0907 804C 0043 DD44"
	$"2000 0907 8056 0043 F690 2000 0907 8065"
	$"8043 DD44 2000 0907 8044 E043 F690 2000"
	$"0907 8084 7043 DD44 2000 0907 810A 3843"
	$"F690 2000 0907 8204 3843 DD44 2000 0907"
	$"8400 7843 F690 2000 0907 8400 B843 DD44"
	$"2000 0907 8201 3843 F690 2000 0907 8102"
	$"3843 DD44 2000 0907 8084 3040 0000 2000"
	$"0907 8048 2040 0000 2000 0907 8030 0040"
	$"0000 2000 0907 8000 0040 0000 2000 0907"
	$"8000 0040 0000 2000 05FB FF01 E000 0907"
	$"8000 0040 0000 2000 0907 8000 0040 0000"
	$"2000 0907 8000 0040 0000 2000 0907 8000"
	$"0040 0038 2000 0907 8300 0040 007C 2000"
	$"0907 8180 0040 007C 2000 0907 80C0 0040"
	$"03FC 2000 0907 8060 0040 01F8 2000 0907"
	$"8030 0040 02E0 2000 0907 8018 0040 0460"
	$"2000 0907 800C 0040 08A0 2000 0907 8006"
	$"0040 1100 2000 0907 8003 0040 2200 2000"
	$"0907 8001 8040 4400 2000 0907 8000 C040"
	$"8800 2000 0907 8000 6041 1000 2000 0907"
	$"8000 3041 2000 2000 0907 8000 0042 C000"
	$"2000 0907 8000 0041 0000 2000 0907 8000"
	$"0040 0000 2000 0907 8000 0040 0000 2000"
	$"05FB FF01 E000 0907 8000 0040 0000 2000"
	$"0907 8000 0040 0000 2000 0907 8000 0040"
	$"0000 2000 0907 8000 0040 0000 2000 0907"
	$"8000 0040 03C0 2000 0907 8000 0040 0220"
	$"2000 0907 8007 F840 0420 2000 0907 8008"
	$"1840 0640 2000 0907 8010 2840 09C0 2000"
	$"0907 8020 4840 0880 2000 0907 8040 9040"
	$"1080 2000 0907 8081 2040 1100 2000 0907"
	$"8102 4040 2100 2000 0907 83FC 8040 2200"
	$"2000 0907 8205 0040 3200 2000 0907 8206"
	$"0040 3C00 2000 0907 83FC 0040 3800 2000"
	$"0907 8000 0040 3000 2000 0907 8000 0040"
	$"2000 2000 0907 8000 0040 0000 2000 0907"
	$"8000 0040 0000 2000 05FB FF01 E000 0907"
	$"8000 0040 0000 2000 0907 8000 0040 0000"
	$"2000 0907 8000 0040 0000 2000 0907 8000"
	$"3840 0090 2000 0907 8000 7840 0090 2000"
	$"0907 8000 F840 0120 2000 0907 8001 F040"
	$"0120 2000 0907 8003 E040 0240 2000 0907"
	$"8067 C040 0240 2000 0907 80CF 8040 0480"
	$"2000 0907 80BF 0040 0480 2000 0907 802E"
	$"0040 0F00 2000 0907 8044 0040 1300 2000"
	$"0907 8088 0040 2300 2000 0907 8118 1840"
	$"2700 2000 0907 8224 2040 4E00 2000 0907"
	$"8244 2040 5C00 2000 0907 8582 4040 B800"
	$"2000 0907 8601 8041 E000 2000 0907 8000"
	$"0040 0000 2000 0907 8000 0040 0000 2000"
	$"05FB FF01 E000 0907 8000 0040 0000 2000"
	$"0907 8000 0040 0000 2000 0907 8000 0040"
	$"0000 2000 0907 800E 0040 0810 2000 0907"
	$"8011 0040 1010 2000 0907 802E 8040 2010"
	$"2000 0907 8020 8040 5008 2000 0907 8020"
	$"8040 A808 2000 0907 8011 0040 D408 2000"
	$"0907 800E 0040 A888 2000 0907 800A 0040"
	$"D188 2000 0907 80FB E040 5288 2000 0907"
	$"810E 1040 6710 2000 0907 8200 0840 2420"
	$"2000 0907 83FF F840 4FC0 2000 0907 821F"
	$"0840 4800 2000 0907 820E 0840 9000 2000"
	$"0907 8204 0841 2000 2000 0907 81FF F041"
	$"C000 2000 0907 8000 0040 0000 2000 0907"
	$"8000 0040 0000 2000 05FB FF01 E000 0907"
	$"8000 0040 0000 2000 0907 8000 0040 0000"
	$"2000 0907 8000 0040 0000 2000 0907 8004"
	$"0040 0400 2000 0907 8004 0040 0400 2000"
	$"0907 800A 0040 0400 2000 0907 800A 0040"
	$"0A00 2000 0907 8011 0040 0A00 2000 0907"
	$"8011 0040 0A00 2000 0907 8020 8040 1100"
	$"2000 0900 80FE 4003 1100 2000 0900 80FE"
	$"4003 1100 2000 0907 8080 2040 2080 2000"
	$"0907 8080 2040 2080 2000 0907 8080 2040"
	$"2080 2000 0902 8080 20FE 4001 2000 0700"
	$"80FC 4001 2000 0902 8020 80FE 4001 2000"
	$"0907 801F 0040 7FC0 2000 0907 8000 0040"
	$"0000 2000 0907 8000 0040 0000 2000 05FB"
	$"FF01 E000 A000 8FA0 0083 FF"
	};

#endif

resource 'PICT' (1002)
	{
	253,
	{0, 0, 21, 51},
	$"1101 0100 0A00 0000 0000 1500 33A0 0082"
	$"A000 8E98 0008 0000 0000 0015 0033 0000"
	$"0000 0015 0033 0000 0000 0015 0033 0000"
	$"05FB FF01 E000 0700 80FC 0001 2000 0700"
	$"80FC 0001 2000 0907 87FF 0FFE 1FFC 2000"
	$"0907 8800 9001 2002 2000 0907 8FFF 9FFF"
	$"2002 2000 0907 8800 9001 2002 2000 0907"
	$"8BF8 9001 2002 2000 0907 8A08 9001 2002"
	$"2000 0907 8A0E 9001 2002 2000 0907 8BFA"
	$"9001 2002 2000 0907 8882 9001 2002 2000"
	$"0907 88FE 9001 2002 2000 0907 8800 9001"
	$"2002 2000 0907 87FF 0FFE 1FFC 2000 0700"
	$"80FC 0001 2000 0700 80FC 0001 2000 0700"
	$"80FC 0001 2000 0700 80FC 0001 2000 0700"
	$"80FC 0001 2000 05FB FF01 E000 A000 8FA0"
	$"0083 FF"
	};

resource 'PICT' (1003, purgeable)
	{
	243,
	{0, 0, 11, 258},
	$"1101 0100 0A00 0000 0000 0B01 02A0 0082"
	$"A000 8E98 0022 0000 0000 000B 0102 0000"
	$"0000 000B 0102 0000 0000 000B 0102 0000"
	$"05E1 FF01 C000 1301 FF7F FD77 0175 75F1"
	$"5501 5454 FD44 FE40 0000 16F9 FF01 FEFE"
	$"FDEE 03EA EAAA 2AFD 2201 2020 F900 0140"
	$"0012 05FF FFFD FDDD 5DED 5507 5151 1010"
	$"0000 4000 13F7 FF03 FBFB BABA FDAA 03A8"
	$"A888 08F7 0001 4000 0D01 FFF7 FC77 EF55"
	$"FB44 0200 4000 0FF8 FFFB EE02 AAAA A2FC"
	$"22F8 0001 4000 10FE FF02 DDDD D5EC 5501"
	$"1111 FE00 0140 0010 F6FF 01BB BBFB AA02"
	$"8888 80F7 0001 4000 1301 FF7F FD77 0175"
	$"75F1 5501 5454 FD44 FE40 0000 05E1 FF01"
	$"C000 A000 8FA0 0083 FF"
	};

#if Barneyscan

resource 'PICT' (2000, purgeable)
	{
	1426,
	{0, 0, 106, 181},
	$"1101 0100 0A00 0000 0000 6A00 B5A0 0082"
	$"A000 8E98 0018 0000 0000 006A 00B5 0000"
	$"0000 006A 00B5 0000 0000 006A 00B5 0000"
	$"05EB FF01 F800 0700 80EC 0001 0800 0700"
	$"80EC 0001 0800 0700 80EC 0001 0800 0700"
	$"80EC 0001 0800 0700 80EC 0001 0800 0700"
	$"80EC 0001 0800 0700 80EC 0001 0800 0700"
	$"80EC 0001 0800 0900 80EE 0003 1F00 0800"
	$"0C00 80F1 0006 3E00 007F C008 000F 0080"
	$"F400 097C 0000 7F00 00FF E008 0012 0080"
	$"F700 0C70 0000 FE00 00FF 8000 FFE0 0800"
	$"1500 80FA 000F E000 00F8 0001 FF00 01FF"
	$"C001 FFF0 0800 1900 80FE 0013 01C0 0001"
	$"F000 01FC 0001 FF00 01FF C001 FFF0 0800"
	$"1917 8001 0000 01C0 0001 F000 01FC 0001"
	$"FF00 01FF C001 FFF0 0800 1900 80FE 0013"
	$"01C0 0001 F000 01FC 0001 FF00 01FF C001"
	$"FFF0 0800 1500 80FA 000F E000 00F8 0001"
	$"FF00 01FF C001 FFF0 0800 1200 80F7 000C"
	$"7000 00FE 0000 FF80 00FF E008 000F 0080"
	$"F400 097C 0000 7F00 00FF E008 000C 0080"
	$"F100 063E 0000 7FC0 0800 0900 80EE 0003"
	$"1F00 0800 0700 80EC 0001 0800 0700 80EC"
	$"0001 0800 0700 80EC 0001 0800 0700 80EC"
	$"0001 0800 0700 80EC 0001 0800 0700 80EC"
	$"0001 0800 0700 80EC 0001 0800 0700 80EC"
	$"0001 0800 0700 80EC 0001 0800 0C00 80FB"
	$"0001 03F8 F400 0108 000F 0080 FE00 0403"
	$"E000 0FFE F400 0108 000F 0880 07C0 000F"
	$"F800 1FFF F400 0108 0013 0980 1FF0 003F"
	$"FE00 3FFF 80F8 0004 01FF F008 0016 0980"
	$"3FF8 003F FE00 7FFF C0FB 0007 01FF C001"
	$"FFF0 0800 1909 807F FC00 7FFF 007F FFC0"
	$"FE00 0A01 FF00 01FF C001 FFF0 0800 1917"
	$"807F FC00 7FFF 00FF FFE0 01FC 0001 FF00"
	$"01FF C001 FFF0 0800 1917 80FF FE00 FFFF"
	$"80FF FFE0 01FC 0001 FF00 01FF C001 FFF0"
	$"0800 1917 80FF FE00 FFFF 80FF FFE0 01FC"
	$"0001 FF00 01FF C001 FFF0 0800 1917 80FF"
	$"FE00 FFFF 80FF FFE0 01FC 0001 FF00 01FF"
	$"C001 FFF0 0800 1917 80FF FE00 FFFF 80FF"
	$"FFE0 01FC 0001 FF00 01FF C001 FFF0 0800"
	$"1917 80FF FE00 FFFF 80FF FFE0 01FC 0001"
	$"FF00 01FF C001 FFF0 0800 1917 807F FC00"
	$"7FFF 00FF FFE0 01FC 0001 FF00 01FF C001"
	$"FFF0 0800 1909 807F FC00 7FFF 007F FFC0"
	$"FE00 0A01 FF00 01FF C001 FFF0 0800 1609"
	$"803F F800 3FFE 007F FFC0 FB00 0701 FFC0"
	$"01FF F008 0013 0980 1FF0 003F FE00 3FFF"
	$"80F8 0004 01FF F008 000F 0880 07C0 000F"
	$"F800 1FFF F400 0108 000F 0080 FE00 0403"
	$"E000 0FFE F400 0108 000C 0080 FB00 0103"
	$"F8F4 0001 0800 0700 80EC 0001 0800 0700"
	$"80EC 0001 0800 0700 80EC 0001 0800 0700"
	$"80EC 0001 0800 0700 80EC 0001 0800 0700"
	$"80EC 0001 0800 0700 80EC 0001 0800 0700"
	$"80EC 0001 0800 0700 80EC 0001 0800 0700"
	$"80EC 0001 0800 0B00 80F4 0000 10FA 0001"
	$"0800 0E00 80F7 0003 2000 0010 FA00 0108"
	$"0011 0080 FA00 0640 0000 2000 0010 FA00"
	$"0108 0014 0080 FD00 0980 0000 4000 0020"
	$"0000 10FA 0001 0800 1501 8001 FE00 0980"
	$"0000 4000 0020 0000 10FA 0001 0800 1501"
	$"8001 FE00 0980 0000 4000 0020 0000 10FA"
	$"0001 0800 1501 8001 FE00 0980 0000 4000"
	$"0020 0000 10FA 0001 0800 1400 80FD 0009"
	$"8000 0040 0000 2000 0010 FA00 0108 0011"
	$"0080 FA00 0640 0000 2000 0010 FA00 0108"
	$"000E 0080 F700 0320 0000 10FA 0001 0800"
	$"0B00 80F4 0000 10FA 0001 0800 0700 80EC"
	$"0001 0800 0700 80EC 0001 0800 0700 80EC"
	$"0001 0800 0700 80EC 0001 0800 0700 80EC"
	$"0001 0800 0700 80EC 0001 0800 0700 80EC"
	$"0001 0800 0700 80EC 0001 0800 0700 80EC"
	$"0001 0800 0700 80EC 0001 0800 0700 80EC"
	$"0001 0800 0700 80EC 0001 0800 0700 80EC"
	$"0001 0800 0700 80EC 0001 0800 0700 80EC"
	$"0001 0800 0700 80EC 0001 0800 0700 80EC"
	$"0001 0800 0700 80EC 0001 0800 0700 80EC"
	$"0001 0800 160F 8003 8000 03E0 0003 F800"
	$"03FE 0003 FF80 FB00 0108 0007 0080 EC00"
	$"0108 0007 0080 EC00 0108 0007 0080 EC00"
	$"0108 0007 0080 EC00 0108 0007 0080 EC00"
	$"0108 0007 0080 EC00 0108 0007 0080 EC00"
	$"0108 0007 0080 EC00 0108 0007 0080 EC00"
	$"0108 0007 0080 EC00 0108 0007 0080 EC00"
	$"0108 0007 0080 EC00 0108 0007 0080 EC00"
	$"0108 0007 0080 EC00 0108 0005 EBFF 01F8"
	$"00A0 008F A000 83FF"
	};

#else

resource 'PICT' (2000, purgeable)
	{
	1457,
	{0, 0, 106, 181},
	$"1101 0100 0A00 0000 0000 6A00 B5A0 0082"
	$"A000 8E98 0018 0000 0000 006A 00B5 0000"
	$"0000 006A 00B5 0000 0000 006A 00B5 0000"
	$"05EB FF01 F800 0700 80EC 0001 0800 0700"
	$"80EC 0001 0800 0700 80EC 0001 0800 0700"
	$"80EC 0001 0800 0700 80EC 0001 0800 0700"
	$"80EC 0001 0800 0700 80EC 0001 0800 0700"
	$"80EC 0001 0800 0900 80EE 0003 1F00 0800"
	$"0C00 80F1 0006 3E00 007F C008 000F 0080"
	$"F400 097C 0000 7F00 00FF E008 0012 0080"
	$"F700 0C70 0000 FE00 00FF 8000 FFE0 0800"
	$"1500 80FA 000F E000 00F8 0001 FF00 01FF"
	$"C001 FFF0 0800 1900 80FE 0013 01C0 0001"
	$"F000 01FC 0001 FF00 01FF C001 FFF0 0800"
	$"1917 8001 0000 01C0 0001 F000 01FC 0001"
	$"FF00 01FF C001 FFF0 0800 1900 80FE 0013"
	$"01C0 0001 F000 01FC 0001 FF00 01FF C001"
	$"FFF0 0800 1500 80FA 000F E000 00F8 0001"
	$"FF00 01FF C001 FFF0 0800 1200 80F7 000C"
	$"7000 00FE 0000 FF80 00FF E008 000F 0080"
	$"F400 097C 0000 7F00 00FF E008 000C 0080"
	$"F100 063E 0000 7FC0 0800 0900 80EE 0003"
	$"1F00 0800 0700 80EC 0001 0800 0700 80EC"
	$"0001 0800 0700 80EC 0001 0800 0700 80EC"
	$"0001 0800 0700 80EC 0001 0800 0700 80EC"
	$"0001 0800 0700 80EC 0001 0800 0700 80EC"
	$"0001 0800 0700 80EC 0001 0800 0C00 80FB"
	$"0001 03F8 F400 0108 000F 0080 FE00 0403"
	$"E000 0FFE F400 0108 000F 0880 07C0 000F"
	$"F800 1FFF F400 0108 0013 0980 1FF0 003F"
	$"FE00 3FFF 80F8 0004 01FF F008 0016 0980"
	$"3FF8 003F FE00 7FFF C0FB 0007 01FF C001"
	$"FFF0 0800 1909 807F FC00 7FFF 007F FFC0"
	$"FE00 0A01 FF00 01FF C001 FFF0 0800 1917"
	$"807F FC00 7FFF 00FF FFE0 01FC 0001 FF00"
	$"01FF C001 FFF0 0800 1917 80FF FE00 FFFF"
	$"80FF FFE0 01FC 0001 FF00 01FF C001 FFF0"
	$"0800 1917 80FF FE00 FFFF 80FF FFE0 01FC"
	$"0001 FF00 01FF C001 FFF0 0800 1917 80FF"
	$"FE00 FFFF 80FF FFE0 01FC 0001 FF00 01FF"
	$"C001 FFF0 0800 1917 80FF FE00 FFFF 80FF"
	$"FFE0 01FC 0001 FF00 01FF C001 FFF0 0800"
	$"1917 80FF FE00 FFFF 80FF FFE0 01FC 0001"
	$"FF00 01FF C001 FFF0 0800 1917 807F FC00"
	$"7FFF 00FF FFE0 01FC 0001 FF00 01FF C001"
	$"FFF0 0800 1909 807F FC00 7FFF 007F FFC0"
	$"FE00 0A01 FF00 01FF C001 FFF0 0800 1609"
	$"803F F800 3FFE 007F FFC0 FB00 0701 FFC0"
	$"01FF F008 0013 0980 1FF0 003F FE00 3FFF"
	$"80F8 0004 01FF F008 000F 0880 07C0 000F"
	$"F800 1FFF F400 0108 000F 0080 FE00 0403"
	$"E000 0FFE F400 0108 000C 0080 FB00 0103"
	$"F8F4 0001 0800 0700 80EC 0001 0800 0700"
	$"80EC 0001 0800 0700 80EC 0001 0800 0700"
	$"80EC 0001 0800 0700 80EC 0001 0800 0700"
	$"80EC 0001 0800 0700 80EC 0001 0800 0C00"
	$"80F1 0006 3800 2000 0008 000C 0080 F100"
	$"0644 0020 0000 0800 0C00 80F1 0006 4127"
	$"733B 0008 000F 0080 F400 0910 0000 4128"
	$"24A4 8008 0012 0080 F700 0C20 0000 1000"
	$"0041 2624 A480 0800 1500 80FA 000F 4000"
	$"0020 0000 1000 0045 2124 A480 0800 1800"
	$"80FD 0012 8000 0040 0000 2000 0010 0000"
	$"38EE 1324 8008 0015 0180 01FE 0009 8000"
	$"0040 0000 2000 0010 FA00 0108 0015 0180"
	$"01FE 0009 8000 0040 0000 2000 0010 FA00"
	$"0108 0015 0180 01FE 0009 8000 0040 0000"
	$"2000 0010 FA00 0108 0014 0080 FD00 0980"
	$"0000 4000 0020 0000 10FA 0001 0800 1100"
	$"80FA 0006 4000 0020 0000 10FA 0001 0800"
	$"0E00 80F7 0003 2000 0010 FA00 0108 000B"
	$"0080 F400 0010 FA00 0108 0007 0080 EC00"
	$"0108 0007 0080 EC00 0108 0007 0080 EC00"
	$"0108 0007 0080 EC00 0108 0007 0080 EC00"
	$"0108 0007 0080 EC00 0108 0007 0080 EC00"
	$"0108 0007 0080 EC00 0108 0007 0080 EC00"
	$"0108 0007 0080 EC00 0108 0007 0080 EC00"
	$"0108 0007 0080 EC00 0108 0007 0080 EC00"
	$"0108 0007 0080 EC00 0108 0007 0080 EC00"
	$"0108 0007 0080 EC00 0108 0007 0080 EC00"
	$"0108 0007 0080 EC00 0108 0007 0080 EC00"
	$"0108 0016 0F80 0380 0003 E000 03F8 0003"
	$"FE00 03FF 80FB 0001 0800 0700 80EC 0001"
	$"0800 0700 80EC 0001 0800 0700 80EC 0001"
	$"0800 0700 80EC 0001 0800 0700 80EC 0001"
	$"0800 0700 80EC 0001 0800 0700 80EC 0001"
	$"0800 0700 80EC 0001 0800 0700 80EC 0001"
	$"0800 0700 80EC 0001 0800 0700 80EC 0001"
	$"0800 0700 80EC 0001 0800 0700 80EC 0001"
	$"0800 0700 80EC 0001 0800 05EB FF01 F800"
	$"A000 8FA0 0083 FF"
	};

#endif

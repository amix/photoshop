{Photoshop version 1.0.1, file: UConstants.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UConstants;

INTERFACE

CONST

	pi = 3.14159265359;

	kEnterChar		= CHR ($03);
	kBackspaceChar	= CHR ($08);
	kTabChar		= CHR ($09);
	kReturnChar 	= CHR ($0D);
	kClearChar		= CHR ($1B);
	kEscapeChar 	= CHR ($1B);
	kLeftArrowChar	= CHR ($1C);
	kRightArrowChar = CHR ($1D);
	kUpArrowChar	= CHR ($1E);
	kDownArrowChar	= CHR ($1F);

	kSpaceCode	  = $31;
	kCommandCode  = $37;
	kShiftCode	  = $38;
	kCapsLockCode = $39;
	kOptionCode   = $3A;
	
	{ Types and creators }

	kSignature	  = '8BIM'; 	{ Application signature }
	kFileType	  = '8BIM'; 	{ Internal file type }
	kClipDataType = '8BIM'; 	{ Clipboard data type }

	{ Resource ID of last main menu }

	kLastMenuID = 7;

	{ Image file format codes }

	kFmtCodeInternal	 = 0;
	kFmtCodeIFF 		 = 1;
	kFmtCodeGIF 		 = 2;
	kFmtCodeEPS 		 = 3;
	kFmtCodeMacPaint	 = 4;
	kFmtCodePICTFile	 = 5;
	kFmtCodePICTResource = 6;
	kFmtCodePixar		 = 7;
	kFmtCodePixelPaint	 = 8;
	kFmtCodeRaw 		 = 9;

	{$IFC qBarneyscan}

	kFmtCodeTarga		 = 10;
	kFmtCodeThunderScan  = 11;
	kFmtCodeTIFF		 = 12;

	kLastFmtCode		 = 12;

	{$ELSEC}

	kFmtCodeScitex		 = 10;
	kFmtCodeTarga		 = 11;
	kFmtCodeThunderScan  = 12;
	kFmtCodeTIFF		 = 13;

	kLastFmtCode		 = 13;

	{$ENDC}

	{ Command numbers }

	cOpenAs = 21;

	cOptionFill 	 = 1001;
	cPreferences	 = 1002;
	cAnotherView	 = 1003;
	cZoomIn 		 = 1004;
	cZoomOut		 = 1005;
	cScaleFactor	 = 1006;
	cFeather		 = 1007;
	cSelectInverse	 = 1008;
	cSelectFringe	 = 1009;
	cSelectSimilar	 = 1010;
	cPasteBehind	 = 1011;
	cCrop			 = 1012;
	cHalftone		 = 1013;
	cMonochrome 	 = 1014;
	cIndexedColor	 = 1015;
	cRGBColor		 = 1016;
	cSeparationsCMYK = 1017;
	cSeparationsHSL  = 1018;
	cSeparationsHSB  = 1019;
	cMultichannel	 = 1020;
	cDeleteChannel	 = 1021;
	cSplitChannels	 = 1022;
	cMergeChannels	 = 1023;
	cResizeImage	 = 1024;
	cRepeatFilter	 = 1025;
	cPasteControls	 = 1026;
	cGrow			 = 1027;
	cPasteInto		 = 1028;
	cSelectNone 	 = 1029;
	cResample		 = 1030;
	cMakeAlpha		 = 1031;
	cSelectAlpha	 = 1032;
	cDefinePattern	 = 1033;
	cHideEdges		 = 1034;
	cTrap			 = 1035;
	cDefineBrush	 = 1036;
	cHistogram		 = 1037;
	cNewChannel 	 = 1038;
	cToggleRulers	 = 1039;
	cBrushesWindow	 = 1040;
	cDefringe		 = 1041;
	cPickerWindow	 = 1042;
	cCoordsWindow	 = 1043;

	cChannel = 1100;

	cColorTable = 1150;
	cEditTable	= 1151;

	cFlip			= 1200;
	cFlipHorizontal = 1201;
	cFlipVertical	= 1202;

	cRotate 		 = 1250;
	cRotate180		 = 1251;
	cRotateLeft 	 = 1252;
	cRotateRight	 = 1253;
	cRotateArbitrary = 1254;

	cEffects		   = 1300;
	cEffectResize	   = 1301;
	cEffectRotate	   = 1302;
	cEffectSkew 	   = 1303;
	cEffectPerspective = 1304;
	cEffectDistort	   = 1305;

	cMap		  = 1400;
	cInvert 	  = 1401;
	cEqualize	  = 1402;
	cThreshold	  = 1403;
	cPosterize	  = 1404;
	cMapArbitrary = 1405;

	cAdjust 		= 1450;
	cLevels 		= 1451;
	cBrightContrast = 1452;
	cBalance		= 1453;
	cHueSaturation	= 1454;

	cCalculate			= 1500;
	cAddChannels		= 1501;
	cBlendChannels		= 1502;
	cCompositeChannels	= 1503;
	cConstantChannel	= 1504;
	cDarkerOfChannels	= 1505;
	cDifferenceChannels = 1506;
	cDuplicateChannel	= 1507;
	cLighterOfChannels	= 1508;
	cMultiplyChannels	= 1509;
	cScreenChannels 	= 1510;
	cSubtractChannels	= 1511;

	cFilter = 1550;

	cAcquire = 1600;

	cExport = 1700;

	cMove			 = 2000;
	cDuplicate		 = 2001;
	cNudge			 = 2002;
	cConversion 	 = 2003;
	cTableChange	 = 2004;
	cErasing		 = 2005;
	cDrawing		 = 2006;
	cPainting		 = 2007;
	cBlurring		 = 2008;
	cSharpening 	 = 2009;
	cSmudging		 = 2010;
	cEraseAll		 = 2011;
	cSizeChange 	 = 2012;
	cRotation		 = 2013;
	cInversion		 = 2014;
	cEqualization	 = 2015;
	cThresholding	 = 2016;
	cPosterization	 = 2017;
	cMapping		 = 2018;
	cAdjustment 	 = 2019;
	cCalculation	 = 2020;
	cSkewing		 = 2021;
	cDistortion 	 = 2022;
	cStamping		 = 2023;
	cPasteControls2  = 2024;
	cMagicWand		 = 2025;
	cLasso			 = 2026;
	cSelectFringe2	 = 2027;
	cFeather2		 = 2028;
	cPaintBucket	 = 2029;
	cReverting		 = 2030;
	cRulerOrigin	 = 2031;
	cFill			 = 2032;
	cResampling 	 = 2033;
	cCloning		 = 2034;
	cTrapping		 = 2035;
	cTextTool		 = 2036;
	cDefringe2		 = 2037;
	cLineTool		 = 2038;
	cAirbrushing	 = 2039;
	cBlendTool		 = 2040;
	cMarquee		 = 2041;
	cEllipse		 = 2042;
	cMoveOutline	 = 2043;
	cNudgeOutline	 = 2044;
	cColorCorrection = 2045;
	cSolveMaxInk	 = 2046;
	cYes			 = 2047;
	cNo 			 = 2048;
	cCancel 		 = 2049;
	cDeselect		 = 2050;

	cHalftoneWording		= 3000;
	cHalftoneOptWording 	= 3001;
	cMonochromeWording		= 3002;
	cMonochromeOptWording	= 3003;
	cIndexedColorWording	= 3004;
	cIndexedColorOptWording = 3005;
	cEqualizeWording		= 3006;
	cEqualizeOptWording 	= 3007;
	cHideEdgesWording		= 3008;
	cShowEdgesWording		= 3009;
	cHideRulers 			= 3010;
	cShowRulers 			= 3011;
	cHideBrushes			= 3012;
	cShowBrushes			= 3013;
	cHidePicker 			= 3014;
	cShowPicker 			= 3015;
	cHideCoords 			= 3016;
	cShowCoords 			= 3017;

	cConvolve	  = 4001;
	cOffset 	  = 4002;
	cGaussian	  = 4003;
	cSobel		  = 4004;
	cMaximum	  = 4005;
	cMinimum	  = 4006;
	cBlur		  = 4007;
	cBlurMore	  = 4008;
	cSharpen	  = 4009;
	cSharpenMore  = 4010;
	cHighPass	  = 4011;
	cMedian 	  = 4012;
	cFacet		  = 4013;
	cMotionBlur   = 4014;
	cDiffuse	  = 4015;
	cAddNoise	  = 4016;
	cTraceContour = 4017;
	cMosaic 	  = 4018;
	cSharpenEdges = 4019;
	cDespeckle	  = 4020;
	cUnsharpMask  = 4021;

	{ Error codes }

	errOldSys		   = -25010;
	errBadInternal	   = -25020;
	errNoPixels 	   = -25030;
	errRgnTooComplex   = -25040;
	errNoScratchPad    = -25050;
	errRGBClipboard    = -25060;
	errDiffTables	   = -25070;
	errBadPICT		   = -25080;
	errPICTTooComplex  = -25090;
	errPICTTooWide	   = -25100;
	errNoPICTResource  = -25110;
	errNoHalftone	   = -25120;
	errNoIndexedColor  = -25130;
	errNoColorOnly	   = -25140;
	errNoDarkenOnly    = -25150;
	errNoLightenOnly   = -25160;
	errOneValueImage   = -25170;
	errOneValueSelect  = -25180;
	errEmptyFile	   = -25190;
	errBadThunderScan  = -25200;
	errBadTIFF		   = -25210;
	errTooDeepTIFF	   = -25220;
	errCompressedTIFF  = -25230;
	errBadMacPaint	   = -25240;
	errBadPixelPaint   = -25250;
	errCanvasTooSmall  = -25260;
	errBadGIF		   = -25270;
	errBadIFF		   = -25280;
	errBadFileVersion  = -25290;
	errBadPixar 	   = -25300;
	errResultTooBig    = -25310;
	errDistortTooMuch  = -25320;
	errNoBarneyscan    = -25330;
	errNeverSaved	   = -25340;
	errNoChangeSince   = -25350;
	errModeChanged	   = -25360;
	errSizeChanged	   = -25370;
	errNewChannel	   = -25380;
	errFileModified    = -25390;
	errBadEPSF		   = -25400;
	errBadRegistration = -25410;
	errNoCloneSource   = -25420;
	errNoTexture	   = -25430;
	errNoPattern	   = -25440;
	errBrushTooLarge   = -25450;
	errNoCustomBrush   = -25460;
	errSelectTooSmall  = -25470;
	errBadScitex	   = -25480;
	errTextTooBig	   = -25490;
	errNoCorePixels    = -25500;
	errBadTarga 	   = -25510;
	errUnspTarga	   = -25520;
	errNoCMYK		   = -25530;
	errNoAuxEPSF	   = -25540;
	errPPVersion	   = -25550;

	errNotYetImp	   = -25990;

	{ Error messages }

	msgCannotLasso		   = 1001 * $10000 +  1;
	msgCannotSelect 	   = 1001 * $10000 +  2;
	msgCannotMove		   = 1001 * $10000 +  3;
	msgCannotDuplicate	   = 1001 * $10000 +  4;
	msgCannotErase		   = 1001 * $10000 +  5;
	msgCannotPencil 	   = 1001 * $10000 +  6;
	msgCannotBrush		   = 1001 * $10000 +  7;
	msgCannotAirbrush	   = 1001 * $10000 +  8;
	msgCannotBlur		   = 1001 * $10000 +  9;
	msgCannotSmudge 	   = 1001 * $10000 + 10;
	msgCannotSharpen	   = 1001 * $10000 + 11;
	msgCannotLoadCLUT	   = 1001 * $10000 + 12;
	msgCannotSaveCLUT	   = 1001 * $10000 + 13;
	msgCannotLoadMap	   = 1001 * $10000 + 14;
	msgCannotSaveMap	   = 1001 * $10000 + 15;
	msgCannotLoadKernel    = 1001 * $10000 + 16;
	msgCannotSaveKernel    = 1001 * $10000 + 17;
	msgCannotWand		   = 1001 * $10000 + 18;
	msgCannotBucket 	   = 1001 * $10000 + 19;
	msgCannotMagic		   = 1001 * $10000 + 20;
	msgCannotNudge		   = 1001 * $10000 + 21;
	msgCannotGradient	   = 1001 * $10000 + 22;
	msgCannotLoadSSetup    = 1001 * $10000 + 23;
	msgCannotSaveSSetup    = 1001 * $10000 + 24;
	msgCannotCloneStamp    = 1001 * $10000 + 25;
	msgCannotRevertStamp   = 1001 * $10000 + 26;
	msgCannotTextureStamp  = 1001 * $10000 + 27;
	msgCannotPatternStamp  = 1001 * $10000 + 28;
	msgCannotStamp		   = 1001 * $10000 + 29;
	msgCannotImpressStamp  = 1001 * $10000 + 30;
	msgCannotCrop		   = 1001 * $10000 + 31;
	msgCannotEllipse	   = 1001 * $10000 + 32;
	msgCannotUseText	   = 1001 * $10000 + 33;
	msgCannotUsePicker	   = 1001 * $10000 + 34;
	msgCannotLoadHalftone  = 1001 * $10000 + 35;
	msgCannotLoadHalftones = 1001 * $10000 + 36;
	msgCannotSaveHalftone  = 1001 * $10000 + 37;
	msgCannotSaveHalftones = 1001 * $10000 + 38;
	msgCannotLoadTransfer  = 1001 * $10000 + 39;
	msgCannotLoadTransfers = 1001 * $10000 + 40;
	msgCannotSaveTransfer  = 1001 * $10000 + 41;
	msgCannotSaveTransfers = 1001 * $10000 + 42;
	msgCannotLineTool	   = 1001 * $10000 + 43;
	msgCannotMarquee	   = 1001 * $10000 + 44;
	msgCannotMoveOutline   = 1001 * $10000 + 45;
	msgCannotNudgeOutline  = 1001 * $10000 + 46;
	msgCannotPersonalize   = 1001 * $10000 + 47;
	msgBuildSepTable   	   = 1001 * $10000 + 48;
	msgOpenTempFile   	   = 1001 * $10000 + 49;

	{ Miscellaneous strings }

	kStringsID = 1002;

	strSelectForegroundColor =	1;
	strSelectBackgroundColor =	2;
	strSavePreferencesIn	 =	3;
	strSelectColor			 =	4;
	strSelectFirstColor 	 =	5;
	strSelectLastColor		 =	6;
	strSaveColorTableIn 	 =	7;
	strSaveMapIn			 =	8;
	strSaveKernelIn 		 =	9;
	strSelectProgessive 	 = 10;
	strAnInteger			 = 11;
	strANumber				 = 12;
	strSaveSSetupIn 		 = 13;
	strSavePartIn			 = 14;
	strSaveHalftoneIn		 = 15;
	strSaveHalftonesIn		 = 16;
	strSaveTransferIn		 = 17;
	strSaveTransfersIn		 = 18;
	strReading				 = 19;
	strWriting				 = 20;
	strFormat				 = 21;
	strReadingPart			 = 22;
	strWritingPart			 = 23;
	strSaveBG				 = 24;
	strSaveUCR				 = 25;
	strSepTableName			 = 26;
	strBuildingTable		 = 27;

TYPE

	PInteger = ^INTEGER;
	PLongInt = ^LONGINT;

	TDisplayMode = (HalftoneMode, MonochromeMode, IndexedColorMode,
					RGBColorMode, SeparationsCMYK, SeparationsHSL,
					SeparationsHSB, MultichannelMode);

	TLookUpTable = PACKED ARRAY [0..255] OF CHAR;

	PLookUpTable = ^TLookUpTable;
	HLookUpTable = ^PLookUpTable;

	TRGBLookUpTable = RECORD
		R: TLookUpTable;
		G: TLookUpTable;
		B: TLookUpTable
		END;

	PRGBLookUpTable = ^TRGBLookUpTable;
	HRGBLookUpTable = ^PRGBLookUpTable;

	THistogram = ARRAY [0..255] OF LONGINT;

	TThresTable = PACKED ARRAY [0..510] OF CHAR;

	TNoiseTable = PACKED ARRAY [0..15, 0..15] OF CHAR;

END.

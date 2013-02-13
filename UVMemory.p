{Photoshop version 1.0.1, file: UVMemory.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UVMemory;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD}
	PaletteMgr, UDialog, UConstants, UBWDialog;

CONST

	kVMPageSize = 30720;			{ Size of each page of VM }

TYPE

	TVMPageList = ARRAY [0..32767] OF INTEGER;
	PVMPageList = ^TVMPageList;
	HVMPageList = ^PVMPageList;

	TVMArray = OBJECT (TObject)

		fBlockCount: LONGINT;		{ Number of blocks in array }

		fLogicalSize: INTEGER;		{ Logical size of each block }
		fPhysicalSize: INTEGER; 	{ Physical size of each block }

		fBlocksPerPage: INTEGER;	{ Number of blocks per page }
		fPageCount: INTEGER;		{ Number of pages in array }

		fPageList: HVMPageList; 	{ List of pages holding array }

		fData: Handle;				{ Buffer to hold part of array }

		fDirty: BOOLEAN;			{ Has the data in the buffer changed? }

		fLoPage: INTEGER;			{ First page in data buffer }
		fHiPage: INTEGER;			{ Last page in data buffer }

		fNeedDepth: INTEGER;		{ Depth of nested NeedPtr calls }

		PROCEDURE TVMArray.IVMArray (count: LONGINT;
									 size: INTEGER;
									 interleave: INTEGER);

		PROCEDURE TVMArray.Free; OVERRIDE;

		FUNCTION TVMArray.NeedPtr
				(loBlock, hiBlock: LONGINT; dirty: BOOLEAN): Ptr;

		PROCEDURE TVMArray.DoneWithPtr;

		PROCEDURE TVMArray.Flush;

		PROCEDURE TVMArray.Undefine;

		PROCEDURE TVMArray.Preload (total: INTEGER);

		PROCEDURE TVMArray.SetBytes (x: INTEGER);

		PROCEDURE TVMArray.SetRect (r: Rect; x: INTEGER);

		PROCEDURE TVMArray.SetOutsideRect (r: Rect; x: INTEGER);

		PROCEDURE TVMArray.MapBytes (map: TLookUpTable);

		PROCEDURE TVMArray.MapRect (r: Rect; map: TLookUpTable);

		PROCEDURE TVMArray.HistBytes (VAR hist: THistogram);

		PROCEDURE TVMArray.HistRect (r: Rect; VAR hist: THistogram);

		PROCEDURE TVMArray.MoveArray (aVMArray: TVMArray);

		FUNCTION TVMArray.CopyArray (interleave: INTEGER): TVMArray;

		PROCEDURE TVMArray.MoveRect (aVMArray: TVMArray; r1, r2: Rect);

		FUNCTION TVMArray.CopyRect (r: Rect; interleave: INTEGER): TVMArray;

		PROCEDURE TVMArray.FindInnerBounds (VAR r: Rect);

		PROCEDURE TVMArray.FindBounds (VAR r: Rect);

		END;

VAR
	gMovingHands: BOOLEAN;

	gPouchRefNum: INTEGER;

	gVMPageLimit: INTEGER;
	gVMMinPageLimit: INTEGER;

PROCEDURE InitWatches;

PROCEDURE MoveHands (canAbort: BOOLEAN);

FUNCTION TestAbort: BOOLEAN;

PROCEDURE InitVM;

PROCEDURE TermVM;

FUNCTION VMCanReserve: LONGINT;

PROCEDURE VMAdjustReserve (change: LONGINT);

FUNCTION NewLargeHandle (size: LONGINT): Handle;

PROCEDURE ResizeLargeHandle (h: Handle; size: LONGINT);

PROCEDURE FreeLargeHandle (h: Handle);

FUNCTION NewVMArray (count: LONGINT;
					 size: INTEGER;
					 interleave: INTEGER): TVMArray;

PROCEDURE VMCompress (complete: BOOLEAN);

IMPLEMENTATION

{$I UVMemory.inc1.p}

END.

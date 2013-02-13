{Photoshop version 1.0.1, file: UVMemory.inc1.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

{$I UAssembly.a.inc}

CONST
	kVMFileType = '8BVM';			{ Virtual memory file type }

	kVMInitPages = 1000;			{ Initial number of pages of VM }

	kVMMinPages 	   = 7; 		{ Minimum pages of real memory }
	kVMMinOtherPages   = 2; 		{ Minimum pages for other stuff }
	kVMMaxOtherPages   = 4; 		{ Maximum pages for other stuff }
	kVMMinReservePages = 1; 		{ Minimum pages for large handles }
	kVMMaxReservePages = 7; 		{ Maximum pages for large handles }

TYPE
	TVMPageInfo = RECORD

		fData: Handle;				{ Handle to data, if in memory }

		fUsed: BOOLEAN; 			{ Is the page used or free? }
		fDirty: BOOLEAN;			{ Are memory and disk version different? }
		fDefined: BOOLEAN;			{ Are the page's contains defined? }
		fPurgeable: BOOLEAN;		{ Can the page be purged from memory? }

		fNextOlder: INTEGER;		{ Next older purgeable page }
		fNextNewer: INTEGER;		{ Next newer purgeable page }

		END;

	TVMPageArray = ARRAY [0..32767] OF TVMPageInfo;
	PVMPageArray = ^TVMPageArray;
	HVMPageArray = ^PVMPageArray;

VAR
	gHandsState: INTEGER;			{ Which cursor is active }
	gHandsLastMoved: LONGINT;		{ Time the hands last moved }
	gLastAbortCheck: LONGINT;		{ Time last checked for abort }

	gWatchCursor: ARRAY [0..7] OF Cursor;

	gVMPageCount: INTEGER;			{ Number of pages in memory }

	gVMNextPage: INTEGER;			{ Next virtual memory page to allocate }

	gVMNewestPage: INTEGER; 		{ Purgeable page most recently used }
	gVMOldestPage: INTEGER; 		{ Purgeable page least recently used }

	gVMMaxPages: INTEGER;			{ Number of allocated page info records }

	gVMPageInfo: HVMPageArray;		{ Information on each page }

	gVMFileName: String [63];		{ Temporary file name }

	gVMFileOpen: BOOLEAN;			{ Is the temporary file open? }

	gVMFile: INTEGER;				{ Reference number of temporary file }

	gVMMaxPageLimit: INTEGER;		{ Maximum number of pages in memory ever }

	gVMReserve: LONGINT;			{ Permanent space allocated to other data }

	gVMArrayList: TList;			{ List of current virtual memory arrays }

PROCEDURE qsort (base: Ptr;
				 nelem: LONGINT;
				 elSize: LONGINT;
				 compar: ProcPtr); C; EXTERNAL;

{*****************************************************************************}

{$S AInit}

PROCEDURE InitWatches;

	CONST
		kFirstWatchCursor = 600;

	VAR
		state: INTEGER;

	BEGIN

	gMovingHands := FALSE;

	gLastAbortCheck := TickCount;

	FOR state := 0 TO 7 DO
		gWatchCursor [state] := GetCursor (kFirstWatchCursor + state)^^;

	BusyDelay (32000, TRUE)

	END;

{*****************************************************************************}

{$S ARes}

{$IFC qTrace} {$D+} {$ENDC}

PROCEDURE MoveHands (canAbort: BOOLEAN);

	CONST
		kHandsRate	= 10;
		kAbortRate	= 30;

	TYPE
		EvQElPtr = ^EvQEl;

	VAR
		eq: EvQElPtr;
		now: LONGINT;

	BEGIN

	now := TickCount;

	IF NOT gMovingHands THEN
		BEGIN

		gMovingHands := TRUE;

		gHandsState := 7;

		gHandsLastMoved := now - kHandsRate

		END;

	IF now - gHandsLastMoved >= kHandsRate THEN
		BEGIN

		gHandsState := BAND (gHandsState + 1, 7);

		SetCursor (gWatchCursor [gHandsState]);

		gHandsLastMoved := now

		END;

	IF canAbort & (now - gLastAbortCheck >= kAbortRate) THEN
		BEGIN

		eq := EvQElPtr (GetEvQHdr^.QHead);

		WHILE eq <> NIL DO
			BEGIN

			IF ((eq^.evtQWhat = keyDown) OR (eq^.evtQWhat = autoKey)) &
			   (BAND (eq^.evtQModifiers, cmdKey) <> 0) &
			   (BAND (eq^.evtQMessage, charCodeMask) = ORD ('.')) THEN

				BEGIN
				FlushEvents (everyEvent, 0);
				Failure (0, 0)
				END;

			IF eq = EvQElPtr (GetEvQHdr^.QTail) THEN LEAVE;

			eq := EvQElPtr (eq^.qLink)

			END;

		gLastAbortCheck := now

		END

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S ARes}

{$IFC qTrace} {$D+} {$ENDC}

FUNCTION TestAbort: BOOLEAN;

	VAR
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		TestAbort := TRUE;
		EXIT (TestAbort)
		END;

	BEGIN

	TestAbort := FALSE;

	CatchFailures (fi, CleanUp);

	MoveHands (TRUE);

	Success (fi)

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S AInit}

PROCEDURE InitVM;

{ Initializes the virtual memory system. This procedure is called once
  when the application starts up. }

	CONST
		kLowMemoryID = 913;
		kTempNameID = 1005;

	VAR
		h: Handle;
		err: OSErr;
		page: INTEGER;
		other: INTEGER;
		reserve: INTEGER;
		name: StringHandle;

	BEGIN

	gVMPageCount := 0;

	gVMNewestPage := -1;
	gVMOldestPage := -1;

	gVMMaxPages := kVMInitPages;

	gVMPageInfo := HVMPageArray (NewPermHandle (ORD4 (gVMMaxPages) *
												SIZEOF (TVMPageInfo)));
	FailMemError;

	FOR page := 0 TO gVMMaxPages - 1 DO
		gVMPageInfo^^ [page] . fUsed := FALSE;

	gVMFileOpen := FALSE;

	name := GetString (kTempNameID);
	FailNil (name);
	
	gVMFileName := name^^;
	
	ReleaseResource (Handle (name));

	err := DeleteFile (@gVMFileName, gPouchRefNum);

	NEW (gVMArrayList);
	FailNil (gVMArrayList);

	gVMArrayList.IList;

	gVMPageLimit := 0;

	FOR page := 0 TO gVMMaxPages - 1 DO
		BEGIN

		h := NewPermHandle (kVMPageSize);
		gVMPageInfo^^ [page] . fData := h;

		IF h = NIL THEN LEAVE;

		gVMPageLimit := gVMPageLimit + 1

		END;

	FOR page := 0 TO gVMPageLimit - 1 DO
		DisposHandle (gVMPageInfo^^ [page] . fData);

	other := gVMPageLimit - kVMMinPages - kVMMaxReservePages;

	other := Max (kVMMinOtherPages, Min (other, kVMMaxOtherPages));

	gVMPageLimit := gVMPageLimit - other;

	reserve := gVMPageLimit - kVMMinPages;

	reserve := Max (kVMMinReservePages, Min (reserve, kVMMaxReservePages));

	gVMPageLimit := gVMPageLimit - reserve;

	IF gVMPageLimit < kVMMinPages THEN Failure (memFullErr, 0);

	gVMMaxPageLimit := gVMPageLimit;
	gVMMinPageLimit := kVMMinPages;

	gVMReserve := ORD4 (-reserve) * kVMPageSize;

	{$IFC qDebug}
	writeln ('VM Pages:   ', gVMPageLimit:3);
	writeln ('VM Reserve: ', reserve:3);
	writeln ('VM Other:   ', other:3);
	{$ENDC}

	IF reserve < kVMMaxReservePages THEN
		BWNotice (kLowMemoryID, TRUE)

	END;

{*****************************************************************************}

{$S ATerminate}

PROCEDURE TermVM;

{ Cleans up the temporary file used by the virtual memory system. This
  procedure should be called once when the application exits. }

	VAR
		err: OSErr;

	BEGIN

	IF gVMFileOpen THEN
		BEGIN

		err := FSClose (gVMFile);

		IF err = noErr THEN
			BEGIN
			err := DeleteFile (@gVMFileName, gPouchRefNum);
			err := FlushVol (NIL, gPouchRefNum)
			END

		END

	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ARes}

PROCEDURE VMLinkPage (page: INTEGER);

{ Adds a page to the purgeable pages list. }

	BEGIN

	WITH gVMPageInfo^^ [page] DO
		BEGIN
		fNextNewer := -1;
		fNextOlder := gVMNewestPage
		END;

	IF gVMNewestPage <> -1 THEN
		gVMPageInfo^^ [gVMNewestPage] . fNextNewer := page;

	gVMNewestPage := page;

	IF gVMOldestPage = -1 THEN
		gVMOldestPage := page

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE VMUnlinkPage (page: INTEGER);

{ Unlinks a page from the purgeabe pages list. }

	BEGIN

	WITH gVMPageInfo^^ [page] DO
		BEGIN

		IF fNextNewer = -1 THEN
			gVMNewestPage := fNextOlder
		ELSE
			gVMPageInfo^^ [fNextNewer] . fNextOlder := fNextOlder;

		IF fNextOlder = -1 THEN
			gVMOldestPage := fNextNewer
		ELSE
			gVMPageInfo^^ [fNextOlder] . fNextNewer := fNextNewer

		END

	END;

{*****************************************************************************}

{$S ARes}

FUNCTION VMNeedDiskSpace (page: INTEGER): BOOLEAN;

{ Makes sure there is enough disk space to save the specified page.
  Fails if there is not. }

	VAR
		err: OSErr;
		fi: FailInfo;
		size: LONGINT;
		needed: LONGINT;
		
	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FailNewMessage (error, message, msgOpenTempFile)
		END;

	BEGIN

	VMNeedDiskSpace := FALSE;

	IF NOT gVMFileOpen THEN
		BEGIN
		
		VMNeedDiskSpace := TRUE;
		
		CatchFailures (fi, CleanUp);
		
		err := Create (gVMFileName, gPouchRefNum, kSignature, kVMFileType);
		
		IF err = dupFNErr THEN
			BEGIN
			FailOSErr (DeleteFile (@gVMFileName, gPouchRefNum));
			err := Create (gVMFileName, gPouchRefNum,
						   kSignature, kVMFileType)
			END;
			
		FailOSErr (err);
		
		FailOSErr (FSOpen (gVMFileName, gPouchRefNum, gVMFile));
		
		Success (fi);
		
		gVMFileOpen := TRUE
		
		END;

	FailOSErr (GetEOF (gVMFile, size));

	needed := ORD4 (page + 1) * kVMPageSize;

	IF size < needed THEN
		BEGIN
		VMNeedDiskSpace := TRUE;
		FailOSErr (SetEOF (gVMFile, needed))
		END

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE VMSaveDirty;

{ Saves the oldest dirty purgeable pages to disk, and marks them as clean.
  Will fail if there are problems with the disk. }

	CONST
		kBatchSize = 20;

	VAR
		j: INTEGER;
		fi: FailInfo;
		page: INTEGER;
		size: LONGINT;
		count: INTEGER;
		flush: BOOLEAN;
		batch: ARRAY [1..kBatchSize] OF INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		VAR
			err: OSErr;

		BEGIN
		err := FlushVol (NIL, gPouchRefNum)
		END;

	BEGIN

	count := 0;
	page  := gVMOldestPage;

	WHILE page <> -1 DO
		WITH gVMPageInfo^^ [page] DO
			BEGIN

			IF fDirty THEN
				BEGIN
				count := count + 1;
				batch [count] := page;
				IF count = kBatchSize THEN LEAVE
				END;

			page := fNextNewer

			END;

	IF count > 0 THEN
		BEGIN

		IF count > 1 THEN
			qsort (@batch, count, SIZEOF (INTEGER), @CompareWords);

		CatchFailures (fi, CleanUp);

		flush := FALSE;

		FOR j := 1 TO count DO
			BEGIN

			page := batch [j];

			IF VMNeedDiskSpace (page) THEN
				flush := TRUE;

			size := kVMPageSize;

			FailOSErr (SetFPos (gVMFile,
								fsFromStart,
								page * size));

			FailOSErr (FSWrite (gVMFile,
								size,
								gVMPageInfo^^ [page] . fData^));

			gVMPageInfo^^ [page] . fDirty := FALSE;

			IF gMovingHands THEN MoveHands (FALSE)

			END;

		Success (fi);

		IF flush THEN
			CleanUp (0, 0)

		END

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE PurgeVM;

{ Purges the oldest page in virtual memory.  Fails if unable to
  purge a page. }

	BEGIN

	IF gVMOldestPage = -1 THEN
		Failure (memFullErr, 0);

	IF gVMPageInfo^^ [gVMOldestPage] . fDirty THEN
		VMSaveDirty;

	DisposHandle (gVMPageInfo^^ [gVMOldestPage] . fData);
	gVMPageInfo^^ [gVMOldestPage] . fData := NIL;

	gVMPageCount := gVMPageCount - 1;

	VMUnlinkPage (gVMOldestPage)

	END;

{*****************************************************************************}

{$S ARes}

FUNCTION VMCanReserve: LONGINT;

{ Computes the amount of space that can be reserved for non-VM uses. }

	BEGIN

	VMCanReserve := ORD4 (gVMMaxPageLimit - gVMMinPageLimit) * kVMPageSize -
					gVMReserve

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE VMAdjustReserve (change: LONGINT);

{ Adjusts the amount of space reserved for uses other than VM. }

	VAR
		fi: FailInfo;
		oldReserve: LONGINT;
		oldPageLimit: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		gVMReserve	 := oldReserve;
		gVMPageLimit := oldPageLimit
		END;

	BEGIN

	oldReserve	 := gVMReserve;
	oldPageLimit := gVMPageLimit;

	gVMReserve	 := gVMReserve + change;
	gVMPageLimit := gVMMaxPageLimit - Max (0, gVMReserve) DIV kVMPageSize;

	CatchFailures (fi, CleanUp);

	IF gVMPageLimit < gVMMinPageLimit THEN
		Failure (MemFullErr, 0);

	WHILE gVMPageCount > gVMPageLimit DO
		PurgeVM;

	Success (fi)

	END;

{*****************************************************************************}

{$S ARes}

FUNCTION NewLargeHandle (size: LONGINT): Handle;

{ Allocates a handle from permanent memory, purging pages as needed from
  virtual memory.  Fails if unable to allocate the block. }

	VAR
		h: Handle;
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF h <> NIL THEN DisposHandle (h);
		VMAdjustReserve (-size)
		END;

	BEGIN

	h := NIL;

	VMAdjustReserve (size);

	CatchFailures (fi, CleanUp);

		REPEAT
		h := NewPermHandle (size);
		IF h <> NIL THEN LEAVE;
		PurgeVM
		UNTIL FALSE;

	WHILE MemSpaceIsLow DO
		PurgeVM;

	Success (fi);

	NewLargeHandle := h

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE ResizeLargeHandle (h: Handle; size: LONGINT);

{ Resizes a handle in permanent memory, purging pages as needed from
  virtual memory.  Fails if unable to resize the block. }

	VAR
		fi: FailInfo;
		oldSize: LONGINT;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		SetHandleSize (h, oldSize);
		VMAdjustReserve (oldSize - size)
		END;

	BEGIN

	oldSize := GetHandleSize (h);

	VMAdjustReserve (size - oldSize);

	IF oldSize > size THEN
		SetHandleSize (h, size)

	ELSE IF oldSize < size THEN
		BEGIN

		CatchFailures (fi, CleanUp);

			REPEAT
			SetHandleSize (h, size);
			IF MemError = noErr THEN LEAVE;
			PurgeVM
			UNTIL FALSE;

		WHILE MemSpaceIsLow DO
			PurgeVM;

		Success (fi)

		END

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE FreeLargeHandle (h: Handle);

	BEGIN

	IF h <> NIL THEN
		BEGIN

		VMAdjustReserve (-GetHandleSize (h));

		DisposHandle (h)

		END

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE VMFindFirstFree;

	VAR
		page: INTEGER;

	BEGIN

	FOR page := 0 TO gVMMaxPages - 1 DO
		IF NOT gVMPageInfo^^ [page] . fUsed THEN
			BEGIN
			gVMNextPage := page;
			EXIT (VMFindFirstFree)
			END;

	gVMNextPage := gVMMaxPages

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE VMExpandTable;

{ Doubles the size of the page infomation table, if possible }

	VAR
		size: LONGINT;
		page: INTEGER;

	BEGIN

	IF BSL (gVMMaxPages, 1) > 32000 THEN Failure (memFullErr, 0);

	size := GetHandleSize (Handle (gVMPageInfo));

	VMAdjustReserve (size);

	SetHandleSize (Handle (gVMPageInfo), 2 * size);

	IF MemError <> noErr THEN
		BEGIN
		VMAdjustReserve (-size);
		Failure (memFullErr, 0)
		END;

	gVMMaxPages := BSL (gVMMaxPages, 1);

	FOR page := BSR (gVMMaxPages, 1) TO gVMMaxPages - 1 DO
		gVMPageInfo^^ [page] . fUsed := FALSE;

	{$IFC qDebug}
	writeln ('VM expanded to ', gVMMaxPages:1, ' pages')
	{$ENDC}

	END;

{*****************************************************************************}

{$S ARes}

FUNCTION VMAllocPage (interleave: INTEGER): INTEGER;

{ Allocates a page of virtual memory.  Fails if unable. }

	VAR
		h: Handle;
		skip: INTEGER;
		ignore: BOOLEAN;

	BEGIN

	IF gVMNextPage = gVMMaxPages THEN
		VMExpandTable;

	gVMPageInfo^^ [gVMNextPage] . fData := NIL;

	IF gVMFileOpen OR (gVMPageCount = gVMPageLimit) THEN
		h := NIL
	ELSE
		BEGIN

		h := NewPermHandle (kVMPageSize);

		IF h = NIL THEN
			BEGIN

			{$IFC qDebug}
			writeln ('Warning: VM reserved space is too low, ',
					 gVMMaxPageLimit:1, ' max ',
					 gVMMinPageLimit:1, ' min ',
					 gVMPageLimit	:1, ' limit');
			{$ENDC}

			IF gVMMaxPageLimit > gVMMinPageLimit THEN
				BEGIN
				gVMPageLimit := gVMPageLimit - 1;
				gVMMaxPageLimit := gVMMaxPageLimit - 1
				END

			END

		END;

	IF h = NIL THEN
		ignore := VMNeedDiskSpace (gVMNextPage)
	ELSE
		BEGIN
		gVMPageInfo^^ [gVMNextPage] . fData := h;
		gVMPageCount := gVMPageCount + 1;
		VMLinkPage (gVMNextPage)
		END;

	WITH gVMPageInfo^^ [gVMNextPage] DO
		BEGIN
		fUsed := TRUE;
		fDirty := FALSE;
		fDefined := FALSE;
		fPurgeable := TRUE
		END;

	VMAllocPage := gVMNextPage;

	FOR skip := 1 TO interleave DO
		REPEAT
		gVMNextPage := gVMNextPage + 1;
		IF gVMNextPage = gVMMaxPages THEN EXIT (VMAllocPage)
		UNTIL NOT gVMPageInfo^^ [gVMNextPage] . fUsed

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE VMFreePage (page: INTEGER);

{ Frees a page of virtual memory. }

	BEGIN

	{$IFC qDebug}

	IF (page < 0) OR (page >= gVMMaxPages) THEN
		ProgramBreak ('Bad page number passed to VMFreePage');

	IF NOT gVMPageInfo^^ [page] . fUsed THEN
		ProgramBreak ('Unused page number passed to VMFreePage');

	{$ENDC}

	WITH gVMPageInfo^^ [page] DO
		BEGIN

		fUsed := FALSE;

		IF fData <> NIL THEN
			BEGIN
			IF fPurgeable THEN VMUnlinkPage (page);
			gVMPageCount := gVMPageCount - 1;
			DisposHandle (fData)
			END

		END

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE VMLockPage (page: INTEGER);

{ Locks a virtual memory page into memory.	Fails if unable. }

	VAR
		h: Handle;
		err: OSErr;
		size: LONGINT;

	BEGIN

	{$IFC qDebug}

	IF (page < 0) OR (page >= gVMMaxPages) THEN
		ProgramBreak ('Bad page number passed to VMLockPage');

	IF NOT gVMPageInfo^^ [page]. fUsed THEN
		ProgramBreak ('Unused page number passed to VMLockPage');

	IF NOT gVMPageInfo^^ [page]. fPurgeable THEN
		ProgramBreak ('Locked page number passed to VMLockPage');

	IF (gVMPageCount < 0) OR (gVMPageCount > gVMPageLimit) THEN
		ProgramBreak ('Bad VM page count');

	{$ENDC}

	IF gVMPageInfo^^ [page] . fData = NIL THEN
		BEGIN

		IF gVMPageCount = gVMPageLimit THEN
			h := NIL
		ELSE
			BEGIN

			h := NewPermHandle (kVMPageSize);

			IF h = NIL THEN
				BEGIN

				{$IFC qDebug}
				writeln ('Warning: VM reserved space is too low, ',
						 gVMMaxPageLimit:1, ' max ',
						 gVMMinPageLimit:1, ' min ',
						 gVMPageLimit	:1, ' limit');
				{$ENDC}

				IF gVMMaxPageLimit > gVMMinPageLimit THEN
					BEGIN
					gVMPageLimit := gVMPageLimit - 1;
					gVMMaxPageLimit := gVMMaxPageLimit - 1
					END

				END

			END;

		IF h = NIL THEN
			BEGIN

			IF gVMOldestPage = -1 THEN
				Failure (memFullErr, 0);

			IF gVMPageInfo^^ [gVMOldestPage] . fDirty THEN
				VMSaveDirty;

			WITH gVMPageInfo^^ [gVMOldestPage] DO
				BEGIN
				h := fData;
				fData := NIL
				END;

			gVMPageCount := gVMPageCount - 1;

			VMUnlinkPage (gVMOldestPage)

			END;

		IF gVMPageInfo^^ [page] . fDefined THEN
			BEGIN

			size := kVMPageSize;

			err := SetFPos (gVMFile, fsFromStart, page * size);

			IF err = noErr THEN
				err := FSRead (gVMFile, size, h^);

			IF err <> noErr THEN
				BEGIN
				DisposHandle (h);
				FailOSErr (err)
				END

			END;

		WITH gVMPageInfo^^ [page] DO
			BEGIN
			fData := h;
			fDirty := FALSE
			END;

		gVMPageCount := gVMPageCount + 1

		END

	ELSE
		VMUnlinkPage (page);

	gVMPageInfo^^ [page] . fPurgeable := FALSE

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE VMUnlockPage (page: INTEGER);

{ Unlocks a virtual memory page. }

	BEGIN

	{$IFC qDebug}

	IF (page < 0) OR (page >= gVMMaxPages) THEN
		ProgramBreak ('Bad page number passed to VMUnlockPage');

	IF NOT gVMPageInfo^^ [page] . fUsed THEN
		ProgramBreak ('Unused page number passed to VMLockPage');

	IF gVMPageInfo^^ [page] . fPurgeable THEN
		ProgramBreak ('Unlocked page number passed to VMUnlockPage');

	{$ENDC}

	gVMPageInfo^^ [page] . fPurgeable := TRUE;

	VMLinkPage (page)

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S ARes}

PROCEDURE TVMArray.IVMArray (count: LONGINT;
							 size: INTEGER;
							 interleave: INTEGER);

{ Initializes an array of virtual memory. Fails if unable, freeing itself. }

	VAR
		j: INTEGER;
		err: OSErr;
		fi: FailInfo;
		page: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Free;
		VMCompress (FALSE)
		END;

	BEGIN

	{$IFC qDebug}

	IF (count < 1) OR (size < 1) OR (size > kVMPageSize) THEN
		ProgramBreak ('Invalid size passed to IVMArray');

	IF interleave < 1 THEN
		ProgramBreak ('Invalid interleave passed to IVMArray');

	{$ENDC}

	fBlockCount := count;
	fLogicalSize := size;

	IF ODD (size) THEN
		BEGIN
		j := kVMPageSize DIV size;
		WHILE kVMPageSize MOD j <> 0 DO
			j := j - 1
		END

	ELSE IF BAND (size, 2) <> 0 THEN
		BEGIN
		j := (kVMPageSize DIV 2) DIV BSR (size + 1, 1);
		WHILE (kVMPageSize DIV 2) MOD j <> 0 DO
			j := j - 1
		END

	ELSE
		BEGIN
		j := (kVMPageSize DIV 4) DIV BSR (size + 3, 2);
		WHILE (kVMPageSize DIV 4) MOD j <> 0 DO
			j := j - 1
		END;

	fBlocksPerPage := j;

	fPhysicalSize := kVMPageSize DIV j;

	fPageCount := (count + j - 1) DIV j;

	fPageList := NIL;

	fData := NIL;

	fNeedDepth := 0;

	CatchFailures (fi, CleanUp);

	fPageList := HVMPageList (NewLargeHandle (fPageCount * SIZEOF (INTEGER)));

	FOR j := 0 TO fPageCount - 1 DO
		fPageList^^ [j] := -1;

	VMFindFirstFree;

	FOR j := 0 TO fPageCount - 1 DO
		BEGIN
		page := VMAllocPage (interleave);
		fPageList^^ [j] := page
		END;

	IF gVMFileOpen THEN
		err := FlushVol (NIL, gPouchRefNum);

	gVMArrayList.InsertLast (SELF);

	Success (fi)

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TVMArray.Free; OVERRIDE;

{ Frees an array of virtual memory. }

	VAR
		j: INTEGER;
		page: INTEGER;

	BEGIN

	gVMArrayList.Delete (SELF);

	IF fPageList <> NIL THEN
		BEGIN

		FOR j := fPageCount - 1 DOWNTO 0 DO
			BEGIN
			page := fPageList^^ [j];
			IF page <> -1 THEN VMFreePage (page)
			END;

		DisposHandle (Handle (fPageList))

		END;

	IF fData <> NIL THEN
		IF fLoPage <> fHiPage THEN
			FreeLargeHandle (fData);

	INHERITED Free

	END;

{*****************************************************************************}

{$IFC qTrace} {$D+} {$ENDC}

{$S ARes}

FUNCTION TVMArray.NeedPtr (loBlock, hiBlock: LONGINT; dirty: BOOLEAN): Ptr;

	LABEL
		1;

	VAR
		j: INTEGER;
		dstPtr: Ptr;
		fi: FailInfo;
		page: INTEGER;
		loPage: INTEGER;
		hiPage: INTEGER;
		lockedPages: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);

		VAR
			j: INTEGER;

		BEGIN

		FOR j := loPage TO loPage + lockedPages - 1 DO
			VMUnlockPage (fPageList^^[j]);

		IF fData <> NIL THEN
			BEGIN
			FreeLargeHandle (fData);
			fData := NIL
			END

		END;

	BEGIN

	{$IFC qDebug}
	IF (loBlock < 0) OR (loBlock > hiBlock) OR (hiBlock >= fBlockCount) THEN
		BEGIN
		writeln ('loBlock    = ', loBlock:1);
		writeln ('hiBlock    = ', hiBlock:1);
		writeln ('blockCount = ', fBlockCount:1);
		ProgramBreak ('Invalid parameters passed to NeedPtr')
		END;
	{$ENDC}

	IF gMovingHands THEN MoveHands (FALSE);

	loPage := loBlock DIV fBlocksPerPage;
	hiPage := hiBlock DIV fBlocksPerPage;

	IF fNeedDepth = 0 THEN
		BEGIN

		IF fData <> NIL THEN
			IF (loPage < fLoPage) OR (hiPage > fHiPage) THEN
				Flush
			ELSE
				GOTO 1;

		fDirty := FALSE;

		fLoPage := loPage;
		fHiPage := hiPage;

		IF loPage = hiPage THEN
			BEGIN

			page := fPageList^^ [loPage];
			VMLockPage (page);

			fData := gVMPageInfo^^ [page] . fData

			END

		ELSE
			BEGIN

			lockedPages := 0;

			CatchFailures (fi, CleanUp);

			FOR j := loPage TO hiPage DO
				BEGIN
				VMLockPage (fPageList^^[j]);
				lockedPages := lockedPages + 1
				END;

			fData := NewLargeHandle (ORD4 (hiPage - loPage + 1) * kVMPageSize);

			Success (fi);

			dstPtr := fData^;

			FOR j := loPage TO hiPage DO
				BEGIN
				BlockMove (gVMPageInfo^^ [fPageList^^[j]] .fData^,
						   dstPtr,
						   kVMPageSize);
				dstPtr := Ptr (ORD4 (dstPtr) + kVMPageSize)
				END

			END;

		HLock (fData)

		END

	ELSE
		BEGIN

		{$IFC qDebug}
		IF (loPage < fLoPage) OR (hiPage > fHiPage) THEN
			ProgramBreak ('Incompatible nested calls to NeedPtr')
		{$ENDC}

		END;

	1: fNeedDepth := fNeedDepth + 1;

	IF dirty THEN fDirty := TRUE;

	NeedPtr := Ptr (ORD4 (fData^) +
					ORD4 (loBlock - fLoPage * ORD4 (fBlocksPerPage)) *
					fPhysicalSize)

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TVMArray.DoneWithPtr;

	BEGIN

	fNeedDepth := fNeedDepth - 1;

	{$IFC qDebug}
	IF fNeedDepth < 0 THEN
		ProgramBreak ('Too many calls to DoneWithPtr')
	{$ENDC}

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TVMArray.Flush;

	VAR
		j: INTEGER;
		srcPtr: Ptr;
		page: INTEGER;

	BEGIN

	IF (fNeedDepth = 0) AND (fData <> NIL) THEN
		BEGIN

		IF fLoPage = fHiPage THEN
			BEGIN

			HUnlock (fData);

			page := fPageList^^ [fLoPage];

			IF fDirty THEN
				BEGIN
				gVMPageInfo^^ [page] . fDirty := TRUE;
				gVMPageInfo^^ [page] . fDefined := TRUE
				END;

			VMUnlockPage (page)

			END

		ELSE
			BEGIN

			IF fDirty THEN
				BEGIN

				srcPtr := fData^;

				FOR j := fLoPage TO fHiPage DO
					BEGIN

					page := fPageList^^ [j];

					BlockMove (srcPtr,
							   gVMPageInfo^^ [page] . fData^,
							   kVMPageSize);

					srcPtr := Ptr (ORD4 (srcPtr) + kVMPageSize);

					gVMPageInfo^^ [page] . fDirty := TRUE;
					gVMPageInfo^^ [page] . fDefined := TRUE

					END

				END;

			FOR j := fLoPage To fHiPage DO
				VMUnlockPage (fPageList^^ [j]);

			FreeLargeHandle (fData)

			END;

		fData := NIL

		END

	END;

{$IFC qTrace} {$D++} {$ENDC}

{*****************************************************************************}

{$S ARes}

PROCEDURE TVMArray.Undefine;

	VAR
		j: INTEGER;
		page: INTEGER;

	BEGIN

	FOR j := 0 TO fPageCount - 1 DO
		BEGIN

		page := fPageList^^ [j];

		gVMPageInfo^^ [page] . fDirty := FALSE;
		gVMPageInfo^^ [page] . fDefined := FALSE

		END

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TVMArray.Preload (total: INTEGER);

	LABEL
		1;

	VAR
		p: Ptr;
		fi: FailInfo;
		row: INTEGER;
		page: INTEGER;
		count: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		GOTO 1
		END;

	BEGIN

	count := Min (fPageCount, gVMPageLimit DIV total);

	CatchFailures (fi, CleanUp);

	FOR page := 0 TO count - 1 DO
		BEGIN
		row := page * fBlocksPerPage;
		p := NeedPtr (row, row, FALSE);
		DoneWithPtr
		END;

	Success (fi);

	1: Flush

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TVMArray.SetBytes (x: INTEGER);

	VAR
		p: Ptr;
		j: INTEGER;
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Flush
		END;

	BEGIN

	Undefine;

	CatchFailures (fi, CleanUp);

	FOR j := 0 TO fPageCount - 1 DO
		BEGIN
		p := NeedPtr (j * fBlocksPerPage, j * fBlocksPerPage, TRUE);
		DoSetBytes (p, kVMPageSize, x);
		DoneWithPtr
		END;

	Success (fi);

	Flush

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TVMArray.SetRect (r: Rect; x: INTEGER);

	VAR
		p: Ptr;
		fi: FailInfo;
		row: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Flush
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	FOR row := r.top TO r.bottom - 1 DO
		BEGIN
		p := NeedPtr (row, row, TRUE);
		DoSetBytes (Ptr (ORD4 (p) + r.left), r.right - r.left, x);
		DoneWithPtr
		END;

	Success (fi);

	Flush

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TVMArray.SetOutsideRect (r: Rect; x: INTEGER);

	VAR
		p: Ptr;
		fi: FailInfo;
		row: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Flush
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	FOR row := 0 TO r.top - 1 DO
		BEGIN
		DoSetBytes (NeedPtr (row, row, TRUE), fLogicalSize, x);
		DoneWithPtr
		END;

	IF (r.left > 0) OR (r.right < fLogicalSize) THEN
		FOR row := r.top TO r.bottom - 1 DO
			BEGIN

			p := NeedPtr (row, row, TRUE);

			IF r.left > 0 THEN
				DoSetBytes (p, r.left, x);

			IF r.right < fLogicalSize THEN
				DoSetBytes (Ptr (ORD4 (p) + r.right),
							fLogicalSize - r.right, x);

			DoneWithPtr

			END;

	FOR row := r.bottom TO fBlockCount - 1 DO
		BEGIN
		DoSetBytes (NeedPtr (row, row, TRUE), fLogicalSize, x);
		DoneWithPtr
		END;

	Success (fi);

	Flush

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TVMArray.MapBytes (map: TLookUpTable);

	VAR
		p: Ptr;
		j: INTEGER;
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Flush
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	FOR j := 0 TO fPageCount - 1 DO
		BEGIN
		p := NeedPtr (j * fBlocksPerPage, j * fBlocksPerPage, TRUE);
		DoMapBytes (p, kVMPageSize, map);
		DoneWithPtr
		END;

	Success (fi);

	Flush

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TVMArray.MapRect (r: Rect; map: TLookUpTable);

	VAR
		p: Ptr;
		fi: FailInfo;
		row: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Flush
		END;

	BEGIN

	CatchFailures (fi, CleanUp);

	FOR row := r.top TO r.bottom - 1 DO
		BEGIN
		p := NeedPtr (row, row, TRUE);
		DoMapBytes (Ptr (ORD4 (p) + r.left), r.right - r.left, map);
		DoneWithPtr
		END;

	Success (fi);

	Flush

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TVMArray.HistBytes (VAR hist: THistogram);

	VAR
		r: Rect;

	BEGIN

	r.top	 := 0;
	r.left	 := 0;
	r.bottom := fBlockCount;
	r.right  := fLogicalSize;

	HistRect (r, hist)

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TVMArray.HistRect (r: Rect; VAR hist: THistogram);

	VAR
		p: Ptr;
		fi: FailInfo;
		row: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Flush
		END;

	BEGIN

	DoSetBytes (@hist, SIZEOF (THistogram), 0);

	CatchFailures (fi, CleanUp);

	FOR row := r.top TO r.bottom - 1 DO
		BEGIN
		p := NeedPtr (row, row, FALSE);
		DoHistBytes (Ptr (ORD4 (p) + r.left), NIL, r.right - r.left, hist);
		DoneWithPtr
		END;

	Success (fi);

	Flush

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TVMArray.MoveArray (aVMArray: TVMArray);

	VAR
		j: INTEGER;
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF srcPtr <> NIL THEN DoneWithPtr;
		aVMArray.Flush;
		Flush
		END;

	BEGIN

	{$IFC qDebug}
	IF (aVMArray.fBlockCount  <> fBlockCount ) OR
	   (aVMArray.fLogicalSize <> fLogicalSize) THEN
		ProgramBreak ('Different size arrays passed to MoveArray');
	{$ENDC}

	aVMArray.Undefine;

	srcPtr := NIL;

	CatchFailures (fi, CleanUp);

	FOR j := 0 TO fPageCount - 1 DO
		BEGIN

		srcPtr := NeedPtr (j * fBlocksPerPage,
						   j * fBlocksPerPage, FALSE);

		dstPtr := aVMArray.NeedPtr (j * fBlocksPerPage,
									j * fBlocksPerPage, TRUE);

		BlockMove (srcPtr, dstPtr, kVMPageSize);

		DoneWithPtr;
		aVMArray.DoneWithPtr;

		srcPtr := NIL

		END;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ARes}

FUNCTION TVMArray.CopyArray (interleave: INTEGER): TVMArray;

	VAR
		aVMArray: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aVMArray.Free
		END;

	BEGIN

	aVMArray := NewVMArray (fBlockCount, fLogicalSize, interleave);

	MoveArray (aVMArray);

	CopyArray := aVMArray

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TVMArray.MoveRect (aVMArray: TVMArray; r1, r2: Rect);

	VAR
		srcPtr: Ptr;
		dstPtr: Ptr;
		fi: FailInfo;
		row: INTEGER;
		width: INTEGER;
		height: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		IF srcPtr <> NIL THEN DoneWithPtr;
		aVMArray.Flush;
		Flush
		END;

	BEGIN

	srcPtr := NIL;

	width  := r1.right - r1.left;
	height := r1.bottom - r1.top;

	{$IFC qDebug}
	IF (width  <> r2.right - r2.left) OR
	   (height <> r2.bottom - r2.top) THEN
		ProgramBreak ('Different size rects passed to MoveRect');
	{$ENDC}

	CatchFailures (fi, CleanUp);

	FOR row := 0 TO height - 1 DO
		BEGIN

		srcPtr := Ptr (ORD4 (NeedPtr (row + r1.top,
									  row + r1.top, FALSE)) + r1.left);

		dstPtr := Ptr (ORD4 (aVMArray.NeedPtr (row + r2.top,
											   row + r2.top, TRUE)) + r2.left);

		BlockMove (srcPtr, dstPtr, width);

		DoneWithPtr;
		aVMArray.DoneWithPtr;

		srcPtr := NIL

		END;

	Success (fi);

	CleanUp (0, 0)

	END;

{*****************************************************************************}

{$S ARes}

FUNCTION TVMArray.CopyRect (r: Rect; interleave: INTEGER): TVMArray;

	VAR
		r2: Rect;
		fi: FailInfo;
		aVMArray: TVMArray;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		aVMArray.Free;
		END;

	BEGIN

	r2.top	  := 0;
	r2.left   := 0;
	r2.bottom := r.bottom - r.top;
	r2.right  := r.right - r.left;

	aVMArray := NewVMArray (r2.bottom, r2.right, interleave);

	CatchFailures (fi, CleanUp);

	MoveRect (aVMArray, r, r2);

	Success (fi);

	CopyRect := aVMArray

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TVMArray.FindInnerBounds (VAR r: Rect);

	VAR
		p: Ptr;
		outer: Rect;
		fi: FailInfo;
		row: INTEGER;
		last: INTEGER;
		first: INTEGER;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		Flush
		END;

	BEGIN

	outer := r;

	r := gZeroRect;

	CatchFailures (fi, CleanUp);

	FOR row := outer.top TO outer.bottom - 1 DO
		BEGIN

		p := Ptr (ORD4 (NeedPtr (row, row, FALSE)) + outer.left);

		IF DoFindBounds (p, outer.right - outer.left, first, last) THEN
			BEGIN

			first := first + outer.left;
			last  := last  + outer.left;

			IF EmptyRect (r) THEN
				BEGIN
				r.top	 := row;
				r.left	 := first;
				r.right  := last + 1
				END

			ELSE
				BEGIN
				IF r.left  > first	  THEN r.left  := first;
				IF r.right < last + 1 THEN r.right := last + 1
				END;

			r.bottom := row + 1

			END;

		DoneWithPtr

		END;

	Success (fi);

	Flush

	END;

{*****************************************************************************}

{$S ARes}

PROCEDURE TVMArray.FindBounds (VAR r: Rect);

	BEGIN

	r.top	 := 0;
	r.left	 := 0;
	r.bottom := fBlockCount;
	r.right  := fLogicalSize;

	FindInnerBounds (r)

	END;

{*****************************************************************************}

{$S ARes}

FUNCTION NewVMArray (count: LONGINT;
					 size: INTEGER;
					 interleave: INTEGER): TVMArray;

{ Allocates an array of virtual memory. Fails if unable. }

	VAR
		aVMArray: TVMArray;

	BEGIN

	NEW (aVMArray);
	FailNil (aVMArray);

	aVMArray.IVMArray (count, size, interleave);

	NewVMArray := aVMArray

	END;

{*****************************************************************************}

{$S AWriteFile}

PROCEDURE VMCompress (complete: BOOLEAN);

{ Compresses the virtual memory file, if possible }

	TYPE
		TRenumber = ARRAY [0..32767] OF INTEGER;
		PRenumber = ^TRenumber;
		HRenumber = ^PRenumber;

	VAR
		err: OSErr;
		fi: FailInfo;
		page: INTEGER;
		used: INTEGER;
		last: INTEGER;
		size: LONGINT;
		count: INTEGER;
		locked: BOOLEAN;
		srcPage: INTEGER;
		dstPage: INTEGER;
		renumber: HRenumber;

	PROCEDURE CleanUp (error: INTEGER; message: LONGINT);
		BEGIN
		FreeLargeHandle (Handle (renumber));
		EXIT (VMCompress)
		END;

	PROCEDURE FlushArray (aVMArray: TVMArray);
		BEGIN
		aVMArray.Flush;
		locked := locked OR (aVMArray.fNeedDepth <> 0)
		END;

	PROCEDURE RenumberArray (aVMArray: TVMArray);

		VAR
			page: INTEGER;

		BEGIN

		FOR page := 0 TO aVMArray.fPageCount - 1 DO
			aVMArray.fPageList^^ [page] := renumber^^
										   [aVMArray.fPageList^^ [page]]

		END;

	BEGIN

	IF NOT gVMFileOpen THEN EXIT (VMCompress);

	MoveHands (FALSE);

	renumber := NIL;

	CatchFailures (fi, CleanUp);

	used := 0;
	last := -1;

	FOR page := 0 TO gVMMaxPages - 1 DO
		IF gVMPageInfo^^ [page] . fUsed THEN
			BEGIN
			used := used + 1;
			last := page
			END;

	FailOSErr (SetEOF (gVMFile, ORD4 (last + 1) * kVMPageSize));

	err := FlushVol (NIL, gPouchRefNum);

	IF (used <> last + 1) AND complete THEN
		BEGIN

		locked := FALSE;
		gVMArrayList.Each (FlushArray);
		IF locked THEN Failure (1, 0);

		{$IFC qDebug}
		writeln ('Compression begins...');
		{$ENDC}

		renumber := HRenumber (NewLargeHandle (ORD4 (last + 1) *
											   SIZEOF (INTEGER)));
		FailNil (renumber);

		FOR page := 0 TO last DO
			renumber^^ [page] := page;

		srcPage := used;
		WHILE NOT gVMPageInfo^^ [srcPage] . fUsed DO
			srcPage := srcPage + 1;

		dstPage := 0;
		WHILE gVMPageInfo^^ [dstPage] . fUsed DO
			dstPage := dstPage + 1;

			REPEAT

			count := 0;

			FOR page := srcPage TO last DO
				IF gVMPageInfo^^ [page] . fUsed THEN
					BEGIN

					MoveHands (FALSE);

					VMLockPage (page);
					VMUnlockPage (page);

					count := count + 1;

					IF count = gVMPageLimit THEN LEAVE

					END;

			WHILE count > 0 DO
				BEGIN

				MoveHands (FALSE);

				renumber^^ [srcPage] := dstPage;

				IF gVMPageInfo^^ [srcPage] . fData = NIL THEN
					Failure (2, 0);

				size := kVMPageSize;

				FailOSErr (SetFPos (gVMFile,
									fsFromStart,
									dstPage * size));

				FailOSErr (FSWrite (gVMFile,
									size,
									gVMPageInfo^^ [srcPage] . fData^));

					REPEAT
					srcPage := srcPage + 1
					UNTIL (srcPage > last) |
						  gVMPageInfo^^ [srcPage] . fUsed;

					REPEAT
					dstPage := dstPage + 1
					UNTIL (dstPage >= used) |
						  NOT gVMPageInfo^^ [dstPage] . fUsed;

				count := count - 1

				END;

			UNTIL dstPage >= used;

		IF gVMNewestPage <> -1 THEN
			gVMNewestPage := renumber^^ [gVMNewestPage];

		IF gVMOldestPage <> -1 THEN
			gVMOldestPage := renumber^^ [gVMOldestPage];

		FOR page := 0 TO last DO
			WITH gVMPageInfo^^ [page] DO
				IF fUsed THEN
					BEGIN

					IF (fData <> NIL) AND fPurgeable THEN
						BEGIN

						IF fNextOlder <> -1 THEN
							fNextOlder := renumber^^ [fNextOlder];

						IF fNextNewer <> -1 THEN
							fNextNewer := renumber^^ [fNextNewer]

						END;

					dstPage := renumber^^ [page];

					IF dstPage <> page THEN
						BEGIN
						gVMPageInfo^^ [dstPage] := gVMPageInfo^^ [page];
						fUsed := FALSE
						END

					END;

		gVMArrayList.Each (RenumberArray);

		FailOSErr (SetEOF (gVMFile, ORD4 (used) * kVMPageSize));

		err := FlushVol (NIL, gPouchRefNum);

		{$IFC qDebug}
		writeln ('Compression complete')
		{$ENDC}

		END;

	Success (fi);

	CleanUp (0, 0)

	END;

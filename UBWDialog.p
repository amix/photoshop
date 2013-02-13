{Photoshop version 1.0.1, file: UBWDialog.p
  Computer History Museum, www.computerhistory.org
  This material is (C)Copyright 1990 Adobe Systems Inc.
  It may not be distributed to third parties.
  It is licensed for non-commercial use according to 
  www.computerhistory.org/softwarelicense/photoshop/ }

UNIT UBWDialog;

INTERFACE

USES
	{$LOAD MacIntf.LOAD}
	MemTypes, QuickDraw, OSIntf, ToolIntf, PackIntf,
	{$LOAD UMacApp.LOAD}
	UObject, UList, UMacApp,
	{$LOAD UPhotoshop.LOAD}
	PaletteMgr, UConstants, UVMemory, UPhotoshop,
	{$LOAD}
	UDialog, UGhost;

TYPE

	TBWDialog = OBJECT (TDialogView)

		fCancelItem: INTEGER;

		PROCEDURE TBWDialog.IBWDialog (itsRsrcID: INTEGER;
									   itsHookItem: INTEGER;
									   itsDfltButton: INTEGER);

		PROCEDURE TBWDialog.Free; OVERRIDE;

		FUNCTION TBWDialog.DefineFixedText (itsItemNumber: INTEGER;
											places: INTEGER;
											blankOK: BOOLEAN;
											trim: BOOLEAN;
											minValue: LONGINT;
											maxValue: LONGINT): TFixedText;

		FUNCTION TBWDialog.DefinePopUpMenu (itsLabelNumber: INTEGER;
											itsItemNumber: INTEGER;
											menu: MenuHandle;
											pick: INTEGER): TPopUpMenu;

		FUNCTION TBWDialog.DefineUnitSelector (itsItemNumber: INTEGER;
											   editItemNumber: INTEGER;
											   editItemCount: INTEGER;
											   blankOK: BOOLEAN;
											   menuID: INTEGER;
											   pick: INTEGER): TUnitSelector;

		FUNCTION TBWDialog.DefineResUnit (item: INTEGER;
										  scale: INTEGER;
										  pixels: INTEGER): TUnitSelector;

		FUNCTION TBWDialog.DefinePrintResUnit (item: INTEGER;
											   scale: INTEGER): TUnitSelector;

		FUNCTION TBWDialog.DefineFreqUnit (item: INTEGER;
										   count: INTEGER;
										   scale: INTEGER): TUnitSelector;

		FUNCTION TBWDialog.DefineSizeUnit (item: INTEGER;
										   scale: INTEGER;
										   blankOK: BOOLEAN;
										   allowPixels: BOOLEAN;
										   allowColumns: BOOLEAN;
										   allowZero: BOOLEAN;
										   allowLarge: BOOLEAN): TUnitSelector;

		PROCEDURE TBWDialog.DrawAmendments (theItem: INTEGER); OVERRIDE;

		PROCEDURE TBWDialog.DoFilterEvent (VAR anEvent: EventRecord;
										   VAR itemHit: INTEGER;
										   VAR handledIt: BOOLEAN;
										   VAR doReturn: BOOLEAN); OVERRIDE;

		FUNCTION TBWDialog.DoItemSelected
				(anItem: INTEGER;
				 VAR handledIt: BOOLEAN;
				 VAR doneWithDialog: BOOLEAN): TCommand; OVERRIDE;

		END;

	TFixedText = OBJECT (TKeyHandler)

		fPlaces: INTEGER;
		fBlankOK: BOOLEAN;
		fTrim: BOOLEAN;
		fMinValue: LONGINT;
		fMaxValue: LONGINT;

		fBlank: BOOLEAN;
		fNumber: BOOLEAN;

		fValue: LONGINT;

		PROCEDURE TFixedText.IFixedText (itsItemNumber: INTEGER;
										 itsParent: TDialogView;
										 places: INTEGER;
										 blankOK: BOOLEAN;
										 trim: BOOLEAN;
										 minValue: LONGINT;
										 maxValue: LONGINT);

		PROCEDURE TFixedText.StuffValue (value: LONGINT);

		FUNCTION TFixedText.ParseValue: BOOLEAN;

		PROCEDURE TFixedText.Validate (VAR succeeded: BOOLEAN); OVERRIDE;

		END;

	TPopUpMenu = OBJECT (TDialogItem)

		fMenu: MenuHandle;
		fPick: INTEGER;

		fLabelRect: Rect;
		fMenuRect: Rect;

		fPickAgain: BOOLEAN;

		PROCEDURE TPopUpMenu.DrawPopUpText;

		PROCEDURE TPopUpMenu.DrawPopUpMenu;

		PROCEDURE TPopUpMenu.SetMenu (menu: MenuHandle; pick: INTEGER);

		PROCEDURE TPopUpMenu.IPopUpMenu (itsLabelNumber: INTEGER;
										 itsItemNumber: INTEGER;
										 itsParent: TDialogView;
										 menu: MenuHandle;
										 pick: INTEGER);

		FUNCTION TPopUpMenu.DoPopUpMenu (optionDown: BOOLEAN): BOOLEAN;

		FUNCTION TPopUpMenu.ItemSelected
				(anItem: INTEGER;
				 VAR handledIt: BOOLEAN;
				 VAR doneWithDialog: BOOLEAN): TCommand; OVERRIDE;

		END;

	TUnitSelector = OBJECT (TPopUpMenu)

		fEditItemCount: INTEGER;
		fEditItem: ARRAY [0..3] OF TFixedText;

		fUnitCount: INTEGER;
		fUnitInfo: ARRAY [1..6] OF
						RECORD
						fScale: EXTENDED;
						fBase: EXTENDED;
						fPlaces: INTEGER;
						fLower: LONGINT;
						fUpper: LONGINT
						END;

		PROCEDURE TUnitSelector.IUnitSelector (itsParent: TBWDialog;
											   itsItemNumber: INTEGER;
											   editItemNumber: INTEGER;
											   editItemCount: INTEGER;
											   blankOK: BOOLEAN;
											   menuID: INTEGER;
											   pick: INTEGER);

		PROCEDURE TUnitSelector.UnitHasChanged;

		PROCEDURE TUnitSelector.DefineUnit (scale: EXTENDED;
											base: EXTENDED;
											places: INTEGER;
											lower: LONGINT;
											upper: LONGINT);

		FUNCTION TUnitSelector.ItemSelected
				(anItem: INTEGER;
				 VAR handledIt: BOOLEAN;
				 VAR doneWithDialog: BOOLEAN): TCommand; OVERRIDE;

		PROCEDURE TUnitSelector.StuffFixed (item: INTEGER; value: Fixed);

		PROCEDURE TUnitSelector.StuffFloat (item: INTEGER; value: EXTENDED);

		FUNCTION TUnitSelector.GetFixed (item: INTEGER): Fixed;

		FUNCTION TUnitSelector.GetFloat (item: INTEGER): EXTENDED;

		END;

PROCEDURE ComputeCentered (VAR where: Point; width, height: INTEGER;
						   titled: BOOLEAN);

PROCEDURE CenterWindow (wp: WindowPtr; titled: BOOLEAN);

FUNCTION BWAlert (itsRsrcID: INTEGER; error: INTEGER; beep: BOOLEAN): INTEGER;

PROCEDURE BWNotice (itsRsrcID: INTEGER; beep: BOOLEAN);

PROCEDURE ConvertFixed (value: LONGINT; places: INTEGER;
						trim: BOOLEAN; VAR s: Str255);

IMPLEMENTATION

{$I UBWDialog.inc1.p}

END.

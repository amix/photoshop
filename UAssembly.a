;Photoshop version 1.0.1, file: UAssembly.a
;  Computer History Museum, www.computerhistory.org
;  This material is (C)Copyright 1990 Adobe Systems Inc.
;  It may not be distributed to third parties.
;  It is licensed for non-commercial use according to 
;  www.computerhistory.org/softwarelicense/photoshop/ 

			INCLUDE 	'Traps.a'

; **********************************************************************

			SEG 		'ARes'

DoSetBytes	PROC		EXPORT

;			Calling sequence (Pascal conventions):
;
;			PROCEDURE DoSetBytes (dataPtr: Ptr;
;								  count: LONGINT;
;								  value: INTEGER);

;			Parameter Offsets

@dataPtr	EQU 	14
@count		EQU 	10
@value		EQU 	8

;			Size of parameters

@params 	EQU 	10

;			Unload parameters

			LINK		A6,#0
			MOVE.L		@dataPtr(A6),A0
			CLR.L		D0
			MOVE.W		@value(A6),D0
			AND.W		#$FF,D0
			MOVE.W		D0,D1
			LSL.W		#8,D1
			OR.W		D1,D0
			MOVE.L		D0,D1
			SWAP		D1
			OR.L		D1,D0
			MOVE.L		@count(A6),D1
			SUB.L		#1,D1

;			If count < 32 just do final loop

			CMP.L		#31,D1
			BLT.S		@2

;			Set bytes until at long word boundary

@0			MOVE.L		A0,D2
			AND.L		#3,D2
			BEQ.S		@1
			MOVE.B		D0,(A0)+
			SUB.L		#1,D1
			BRA.S		@0

;			Set until fewer than 32 bytes left

@1			CMP.L		#31,D1
			BLT.S		@2
			SUB.L		#32,D1
			MOVE.L		D0,(A0)+
			MOVE.L		D0,(A0)+
			MOVE.L		D0,(A0)+
			MOVE.L		D0,(A0)+
			MOVE.L		D0,(A0)+
			MOVE.L		D0,(A0)+
			MOVE.L		D0,(A0)+
			MOVE.L		D0,(A0)+
			BRA.S		@1

;			Set remaining bytes

@2			TST.W		D1
			BMI.S		@4
@3			MOVE.B		D0,(A0)+
			DBF 		D1,@3

;			Clean up and exit

@4			UNLK		A6
			MOVE.L		(SP)+,A0
			ADD.W		#@params,SP
			JMP 		(A0)

; **********************************************************************

			SEG 		'ARes'

DoMapBytes	PROC		EXPORT

;			Calling sequence (Pascal conventions):
;
;			PROCEDURE DoMapBytes (dataPtr: Ptr;
;								  count: LONGINT;
;								  map: TLookUpTable);

;			Parameter Offsets

@dataPtr	EQU 	16
@count		EQU 	12
@map		EQU 	8

;			Size of parameters

@params 	EQU 	12

;			Unload parameters

			LINK		A6,#0
			MOVE.L		@dataPtr(A6),A0
			MOVE.L		@map(A6),A1
			MOVE.L		@count(A6),D0

;			Map bytes until fewer than 8 bytes left

			CLR.W		D1
@1			CMP.L		#8,D0
			BLT.S		@2
			SUB.L		#8,D0
			MOVE.B		(A0),D1
			MOVE.B		(A1,D1.W),(A0)+
			MOVE.B		(A0),D1
			MOVE.B		(A1,D1.W),(A0)+
			MOVE.B		(A0),D1
			MOVE.B		(A1,D1.W),(A0)+
			MOVE.B		(A0),D1
			MOVE.B		(A1,D1.W),(A0)+
			MOVE.B		(A0),D1
			MOVE.B		(A1,D1.W),(A0)+
			MOVE.B		(A0),D1
			MOVE.B		(A1,D1.W),(A0)+
			MOVE.B		(A0),D1
			MOVE.B		(A1,D1.W),(A0)+
			MOVE.B		(A0),D1
			MOVE.B		(A1,D1.W),(A0)+
			BRA.S		@1

;			Map remaining bytes

@2			TST.L		D0
			BEQ.S		@3
			SUB.L		#1,D0
			MOVE.B		(A0),D1
			MOVE.B		(A1,D1.W),(A0)+
			BRA.S		@2

;			Clean up and exit

@3			UNLK		A6
			MOVE.L		(SP)+,A0
			ADD.W		#@params,SP
			JMP 		(A0)

; **********************************************************************

			SEG 		'ARes'

DoHistBytes PROC		EXPORT

;			Calling sequence (Pascal conventions):
;
;			PROCEDURE DoHistBytes (dataPtr: Ptr;
;								   maskPtr: Ptr;
;								   count: LONGINT;
;								   VAR hist: THistogram);

;			Parameter Offsets

@dataPtr	EQU 	20
@maskPtr	EQU 	16
@count		EQU 	12
@hist		EQU 	8

;			Size of parameters

@params 	EQU 	16

;			Save registers

			LINK		A6,#0
			MOVEM.L 	A2,-(SP)

;			Unload parameters

			MOVE.L		@count(A6),D0
			BEQ.S		@exit
			MOVE.L		@dataPtr(A6),A0
			MOVE.L		@hist(A6),A1
			MOVE.L		@maskPtr(A6),A2
			MOVE.L		A2,D1
			BNE.S		@2

;			Compute histogram, without mask

@1			CLR.W		D1
			MOVE.B		(A0)+,D1
			LSL.W		#2,D1
			ADD.L		#1,(A1,D1.W)
			SUB.L		#1,D0
			BNE.S		@1
			BRA.S		@exit

;			Compute histogram, with mask

@2			CLR.W		D1
			MOVE.B		(A0)+,D1
			MOVE.B		(A2)+,D2
			BPL.S		@3
			LSL.W		#2,D1
			ADD.L		#1,(A1,D1.W)
@3			SUB.L		#1,D0
			BNE.S		@2

;			Clean up and exit

@exit		MOVEM.L 	(SP)+,A2
			UNLK		A6
			MOVE.L		(SP)+,A0
			ADD.W		#@params,SP
			JMP 		(A0)

; **********************************************************************

			SEG 		'ARes'

DoSwapBytes PROC		EXPORT

;			Calling sequence (Pascal conventions):
;
;			PROCEDURE DoSwapBytes (data1: Ptr;
;								   data2: Ptr;
;								   count: LONGINT);

;			Parameter Offsets

@data1		EQU 	16
@data2		EQU 	12
@count		EQU 	8

;			Size of parameters

@params 	EQU 	12

;			Unload parameters

			LINK		A6,#0
			MOVE.L		@data1(A6),A0
			MOVE.L		@data2(A6),A1
			MOVE.L		@count(A6),D0

;			Swap the bytes

@1			MOVE.B		(A0),D1
			MOVE.B		(A1),(A0)+
			MOVE.B		D1,(A1)+
			SUB.L		#1,D0
			BNE.S		@1

;			Clean up and exit

@4			UNLK		A6
			MOVE.L		(SP)+,A0
			ADD.W		#@params,SP
			JMP 		(A0)

; **********************************************************************

			SEG 		'ARes'

DoMaxBytes	PROC		EXPORT

;			Calling sequence (Pascal conventions):
;
;			PROCEDURE DoMaxBytes (data1: Ptr;
;								  data2: Ptr;
;								  data3: Ptr;
;								  count: LONGINT);

;			Parameter Offsets

@data1		EQU 	20
@data2		EQU 	16
@data3		EQU 	12
@count		EQU 	8

;			Size of parameters

@params 	EQU 	16

;			Unload parameters

			LINK		A6,#0
			MOVE.L		A2,-(SP)
			MOVE.L		@data1(A6),A0
			MOVE.L		@data2(A6),A1
			MOVE.L		@data3(A6),A2
			MOVE.L		@count(A6),D0
			BLE.S		@3

;			Compute the maximums

@1			MOVE.B		(A0)+,D1
			MOVE.B		(A1)+,D2
			CMP.B		D1,D2
			BHI.S		@2
			MOVE.B		D1,(A2)+
			SUB.L		#1,D0
			BNE.S		@1
			BRA.S		@3
@2			MOVE.B		D2,(A2)+
			SUB.L		#1,D0
			BNE.S		@1

;			Clean up and exit

@3			MOVE.L		(SP)+,A2
			UNLK		A6
			MOVE.L		(SP)+,A0
			ADD.W		#@params,SP
			JMP 		(A0)

; **********************************************************************

			SEG 		'ARes'

DoMinBytes	PROC		EXPORT

;			Calling sequence (Pascal conventions):
;
;			PROCEDURE DoMinBytes (data1: Ptr;
;								  data2: Ptr;
;								  data3: Ptr;
;								  count: LONGINT);

;			Parameter Offsets

@data1		EQU 	20
@data2		EQU 	16
@data3		EQU 	12
@count		EQU 	8

;			Size of parameters

@params 	EQU 	16

;			Unload parameters

			LINK		A6,#0
			MOVE.L		A2,-(SP)
			MOVE.L		@data1(A6),A0
			MOVE.L		@data2(A6),A1
			MOVE.L		@data3(A6),A2
			MOVE.L		@count(A6),D0
			BLE.S		@3

;			Compute the minimums

@1			MOVE.B		(A0)+,D1
			MOVE.B		(A1)+,D2
			CMP.B		D1,D2
			BLO.S		@2
			MOVE.B		D1,(A2)+
			SUB.L		#1,D0
			BNE.S		@1
			BRA.S		@3
@2			MOVE.B		D2,(A2)+
			SUB.L		#1,D0
			BNE.S		@1

;			Clean up and exit

@3			MOVE.L		(SP)+,A2
			UNLK		A6
			MOVE.L		(SP)+,A0
			ADD.W		#@params,SP
			JMP 		(A0)

; **********************************************************************

			SEG 		'ARes'

EqualBytes	PROC		EXPORT

;			Calling sequence (Pascal conventions):
;
;			FUNCTION EqualBytes (data1: Ptr;
;								 data2: Ptr;
;								 count: INTEGER): BOOLEAN;
;
;			Parameter Offsets

@result 	EQU 	18
@data1		EQU 	14
@data2		EQU 	10
@count		EQU 	8

;			Size of parameters

@params 	EQU 	10

;			Build frame

			LINK		A6,#0

;			Compare bytes

			CLR.B		@result(A6)

			MOVE.L		@data1(A6),A0
			MOVE.L		@data2(A6),A1

			MOVE.W		@count(A6),D0
			SUB.W		#1,D0

@1			MOVE.B		(A0)+,D1
			CMP.B		(A1)+,D1
			BNE.S		@2
			DBF 		D0,@1

			MOVE.B		#1,@result(A6)

;			Clean up and exit

@2			UNLK		A6
			MOVE.L		(SP)+,A0
			ADD.W		#@params,SP
			JMP 		(A0)

; **********************************************************************

				SEG 		'ARes'

ConvertToGray	PROC		EXPORT

;			Calling sequence (Pascal conventions):
;
;			FUNCTION ConvertToGray (r, g, b: INTEGER): CHAR;

;			Parameter Offsets

@result 	EQU 	14
@r			EQU 	12
@g			EQU 	10
@b			EQU 	8

;			Gray level weights

@rw 		EQU 	30
@gw 		EQU 	59
@bw 		EQU 	11

;			Size of parameters

@params 	EQU 	6

;			Compute gray level

			LINK		A6,#0

			MOVE.W		@r(A6),D0
			AND.W		#$FF,D0
			MULU.W		#@rw,D0

			MOVE.W		@g(A6),D1
			AND.W		#$FF,D1
			MULU.W		#@gw,D1
			ADD.W		D1,D0

			MOVE.W		@b(A6),D1
			AND.W		#$FF,D1
			MULU.W		#@bw,D1
			ADD.W		D1,D0

			ADD.W		#50,D0
			EXT.L		D0
			DIVU.W		#100,D0
			MOVE.W		D0,@result(A6)

;			Clean up and exit

@3			UNLK		A6
			MOVE.L		(SP)+,A0
			ADD.W		#@params,SP
			JMP 		(A0)

; **********************************************************************

				SEG 		'ARes'

DoFindBounds	PROC		EXPORT

;			Calling sequence (Pascal conventions):
;
;			FUNCTION DoFindBounds (dataPtr: Ptr;
;								   count: INTEGER;
;								   VAR first: INTEGER;
;								   VAR last: INTEGER): BOOLEAN;
;
;			Parameter Offsets

@result 	EQU 	22
@dataPtr	EQU 	18
@count		EQU 	16
@first		EQU 	12
@last		EQU 	8

;			Size of parameters

@params 	EQU 	14

;			Save registers

			LINK		A6,#0
			MOVEM.L 	D3-D4,-(SP)

;			Find bounds

			MOVE.L		@dataPtr(A6),A0
			MOVE.W		@count(A6),D0
			CLR.W		D1
			CLR.B		D2

@1			TST.B		(A0)+
			BEQ.S		@3
			TST.B		D2
			BNE.S		@2
			MOVE.B		#1,D2
			MOVE.W		D1,D3
@2			MOVE.W		D1,D4
@3			ADD.W		#1,D1
			CMP.W		D1,D0
			BNE.S		@1

			MOVE.B		D2,@result(A6)

			MOVE.L		@first(A6),A0
			MOVE.W		D3,(A0)

			MOVE.L		@last(A6),A0
			MOVE.W		D4,(A0)

;			Clean up and exit

			MOVEM.L 	(SP)+,D3-D4
			UNLK		A6
			MOVE.L		(SP)+,A0
			ADD.W		#@params,SP
			JMP 		(A0)

; **********************************************************************

					SEG 		'ARes'

DoStepCopyBytes 	PROC		EXPORT

;			Calling sequence (Pascal conventions):
;
;			PROCEDURE DoStepCopyBytes (srcPtr: Ptr;
;									   dstPtr: Ptr;
;									   count: INTEGER;
;									   step1: INTEGER;
;									   step2: INTEGER);
;
;			Parameter Offsets

@srcPtr 	EQU 	18
@dstPtr 	EQU 	14
@count		EQU 	12
@step1		EQU 	10
@step2		EQU 	8

;			Size of parameters

@params 	EQU 	14

;			Save registers

			LINK		A6,#0

;			Unload parameters

			MOVE.L		@srcPtr(A6),A0
			MOVE.L		@dstPtr(A6),A1
			MOVE.W		@count(A6),D0
			MOVE.W		@step1(A6),D1
			MOVE.W		@step2(A6),D2

;			Copy the bytes

			SUB.W		#1,D0
@1			MOVE.B		(A0),(A1)
			ADDA.W		D1,A0
			ADDA.W		D2,A1
			DBF 		D0,@1

;			Clean up and exit

			UNLK		A6
			MOVE.L		(SP)+,A0
			ADD.W		#@params,SP
			JMP 		(A0)

; **********************************************************************

				SEG 		'ARes'

CompareWords	PROC		EXPORT

;			Calling sequence (C conventions):
;
;			int CompareWords (elem1, elem2)
;				char *elem1;
;				char *elem2;
;
;			Unload parameters

			MOVE.L		4(SP),A0
			MOVE.L		8(SP),A1

;			Compare short words

			MOVE.W		(A0),D0
			CMP.W		(A1),D0
			BGT.S		@1
			BLT.S		@2

;			Entries are equal

			CLR.L		D0
			RTS

;			First entry is greater

@1			MOVE.L		#1,D0
			RTS

;			First entry is lesser

@2			MOVE.L		#-1,D0
			RTS

; **********************************************************************

						SEG 		'ARes'

CompareUnsignedLongs	PROC		EXPORT

;			Calling sequence (C conventions):
;
;			int CompareUnsignedLongs (elem1, elem2)
;				char *elem1;
;				char *elem2;
;
;			Unload parameters

			MOVE.L		4(SP),A0
			MOVE.L		8(SP),A1

;			Compare short words

			MOVE.L		(A0),D0
			CMP.L		(A1),D0
			BHI.S		@1
			BLO.S		@2

;			Entries are equal

			CLR.L		D0
			RTS

;			First entry is greater

@1			MOVE.L		#1,D0
			RTS

;			First entry is lesser

@2			MOVE.L		#-1,D0
			RTS

; **********************************************************************

			SEG 		'ARes'

MakeRamp	PROC		EXPORT

;			Calling sequence (Pascal conventions):
;
;			PROCEDURE MakeRamp (VAR map: TLookUpTable;
;								limit: INTEGER);
;
;			Parameter Offsets

@map		EQU 	10
@limit		EQU 	8

;			Size of parameters

@params 	EQU 	6

;			Save registers

			LINK		A6,#0

;			Unload parameters

			MOVE.L		@map(A6),A0
			ADDA.W		#256,A0
			MOVE.W		@limit(A6),D1

;			Compute ramp backwards

			MOVE.W		#255,D0
@1			MOVE.W		D1,D2
			MULU.W		D0,D2
			ADD.L		#127,D2
			DIVU.W		#255,D2
			MOVE.B		D2,-(A0)
			DBF 		D0,@1

;			Clean up and exit

			UNLK		A6
			MOVE.L		(SP)+,A0
			ADD.W		#@params,SP
			JMP 		(A0)

; **********************************************************************

			END

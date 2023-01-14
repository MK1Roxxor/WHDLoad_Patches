;*---------------------------------------------------------------------------
;  :Program.	atomixslave.asm
;  :Contents.	Slave for "Atomix"
;  :Author.	Harry
;  :Version.	$Id: atomixslave.asm 1.1 2000/02/13 12:18:30 jah Exp jah $
;  :History.	21.02.98
;		13.01.00 Wepl	24-bit access on highscore loading fixed
;				smc removed (quitkey)
;		21.02.2011 Harry Absurdly high preset hiscore reduced
;		13.08.2019 StingRay:
;		- RawDIC imager
;		- write to BEAMCON0 (in slave) removed
;		- Bplcon0 color bit fixes
;		- default quitkey changed to F10
;		- Thalion intro patched (and hidden features detected:
;		  typing "aaarrgh" will change tunes, typing "schnism" will
;		  make the logo move)
;		- byte writes to volume register fixed
;		- interrupts fixed
;		12.01.2023 StingRay:
;		- unlimited time trainer added
;		- WHDLoad v17+ features used
;		14.01.2023 StingRay:
;		- level skip added
;		- typo in "congratulation" text fixed
;		- level selector added
;		- in-game keys added
;		- highscore saving disabled if trainer options are used
;
;  :Requires.	whdload-package :)
;  :Copyright.	Freeware
;  :Language.	68000 Assembler
;  :Translator.	ASM-One 1.25, Barfly 2.9, ASM-Pro 1.16d
;  :To Do.	highscore file should be shortened, currently a whole track
;		is saved (6300 bytes), actual highscore data is much shorter
;		
;---------------------------------------------------------------------------*

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM

; Trainer options
TRB_UNLIMITED_TIME	= 0
TRB_IN_GAME_KEYS	= 1

	IFD	BARFLY
	INCDIR	Includes:
	INCLUDE	whdload.i
;	INCLUDE	whdmacros.i
	OUTPUT	"wart:a/atomix/Atomix.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ELSE
	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i
;	INCLUDE	own/CCRMAKRO
	ENDC

;======================================================================

slbase
.base		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_Disk!WHDLF_NoError!WHDLF_EmulTrap	;ws_flags
		dc.l	$80000		;ws_BaseMemSize			;$bc000
		dc.l	$00		;ws_ExecInstall
		dc.w	SLStart-.base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
 		dc.b	$00		;debugkey
qkey		dc.b	$59		;quitkey
_expmem		dc.l	0		;ws_ExpMem
		dc.w	_name-slbase	;ws_name
		dc.w	_copy-slbase	;ws_copy
		dc.w	_info-slbase	;ws_info

; v16
	dc.w	0			; ws_kickname
	dc.l	0			; ws_kicksize
	dc.w	0			; ws_kickcrc

; v17
	dc.w	.config-slbase		; ws_config


.config	dc.b 	"C1:X:Unlimited Time:",TRB_UNLIMITED_TIME+"0",";"
	dc.b	"C1:X:In-Game Keys:",TRB_IN_GAME_KEYS+"0",";"
	dc.b	"C2:L:Start at Level:Off,1,2,3,4,5,6,7,8,9,10,"
	dc.b	"11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30"
	dc.b	0



_name		dc.b	"Atomix",0
_copy		dc.b	"1990 Tale/Thalion",0
_info		dc.b	"installed & fixed by Harry and Wepl and StingRay",10
		dc.b	"V1.4 (14-Jan-2023)",10
		dc.b	10
		dc.b	"In-Game Keys:",10
		dc.b	"T: Refresh Time C: Toggle Unlimited Time",10
		dc.b	"N: Skip Level",0
		even

;======================================================================

;	DOSCMD	"WDate >T:date"
		dc.b	"$VER: Atomix_Slave_1.4"
;	INCBIN	"T:date"
		dc.b	0
		even

;======================================================================
SLStart	;	A0 = resident loader
;======================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later using

	MOVEQ	#0,D0
	MOVE.L	#$1600,D1
	LEA	$70000,A0
	MOVEQ	#1,D2
	MOVE.L	_resload(PC),A2
	jsr	(resload_DiskLoad,a2)


;	MOVE.W	#$2820,$DFF1DC

	MOVE.W	#$4EF9,$702B6
	PEA	LOADROUT(PC)
	MOVE.L	(A7)+,$702B8

	MOVE.L	#$72FF4E75,$70830		;DISKRESTE

	PEA	PATCHGAME(PC)
	MOVE.L	(A7)+,$7019E

	PEA	PATCHHI(PC)
	MOVE.L	(A7)+,$701C2

	PEA	PATCHMENU(PC)
	MOVE.L	(A7)+,$70158


	lea	PLBOOT(pc),a0
	lea	$70000,a1
	jsr	resload_Patch(a2)

	JMP	$70000


PLBOOT	PL_START
	PL_ORW	$290+2,1<<9		; set Bplcon0 color bit
	PL_P	$132,.patchintro
	PL_END


.patchintro
	lea	PLINTRO(pc),a0
	lea	$15000,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	move.l	#-2,$267d0
	jmp	$15000

PLINTRO	PL_START
	PL_PSS	$6d6,.fixkbd,2

; following 2 patches are required to make snoop
; work on 68060
	PL_W	$cc5a,$3040		; move.w d0,-(a7) -> move.w d0,a0
	PL_W	$cc96,$33c8		; move.w (a7)+,$dff096 -> move.w a0,...
	PL_END

.fixkbd	cmp.b	slbase+ws_keyexit(pc),d0
	beq.w	QUIT
	moveq	#3-1,d0
	bra.w	FixDBF
	



TAGLIST	dc.l	WHDLTAG_CUSTOM1_GET
TRAINER	dc.l	0
	dc.l	WHDLTAG_CUSTOM2_GET
LEVEL	dc.l	0
	dc.l	TAG_DONE

MAX_LEVEL	= 30
RAWKEY_N	= $36
RAWKEY_T	= $14
RAWKEY_C	= $33


PATCHGAME
	MOVE.L	#$4E714EB9,$4E7A.W
	PEA	KEYHP(PC)
	MOVE.L	(A7)+,$4E7E.W

	lea	TAGLIST(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Control(a2)


	lea	PLGAME(pc),a0
	lea	$3000.w,a1

	move.l	LEVEL(pc),d0
	beq.b	.no_level_set
	cmp.l	#MAX_LEVEL,d0
	bhi.b	.invalid_level
	move.l	d0,$38+2(a1)
.invalid_level
.no_level_set

	jsr	resload_Patch(a2)

	JSR	$3000.W
	MOVE.L	$5306.W,$106.W
	RTS

PLGAME	PL_START
	PL_ORW	$20a8+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$21c4+2,1<<9		; set Bplcon0 color bit
	PL_P	$a0a,AckVBI

	PL_IFC1X	TRB_UNLIMITED_TIME
	PL_B	$9f6,$4a
	PL_ENDIF


	PL_IFC1X	TRB_IN_GAME_KEYS
	PL_PSS	$18a,.Check_Keys,2
	PL_ENDIF

	; Fix typo in "Congratulation" text
	PL_DATA	$249e,.Congratulations_Text_Length
.Congratulations_Text
	dc.b	"congratulation",0
	CNOP	0,2
.Congratulations_Text_Length = *-.Congratulations_Text


	PL_END


.Check_Keys
	moveq	#0,d0
	jsr	$3000+$1e4e.w		; returns raw key code in d0

	movem.l	d0,-(a7)
	lea	In_Game_Keys_Table(pc),a0
	bsr	Handle_Keys
	movem.l	(a7)+,d0

	cmp.b	#$ff,d0
	rts


In_Game_Keys_Table
	dc.w	RAWKEY_N,.Skip_Level-In_Game_Keys_Table
	dc.w	RAWKEY_T,.Refresh_Time-In_Game_Keys_Table
	dc.w	RAWKEY_C,.Toggle_Unlimited_Time-In_Game_Keys_Table
	dc.w	0

.Skip_Level
	move.l	$3000+$231e.w,a0
	addq.w	#1,a0
	move.l	a0,a2
	moveq	#0,d4
	jsr	$3000+$86a.w		; get offset value
	addq.w	#1,d4	
	move.b	#-1,(a0,d4.w)		; set "level complete" flag

	st	$3000+$2356.w
	rts	

.Refresh_Time
	move.l	$3000+$2302.w,d0	; level number
	subq.w	#1,d0
	lsl.w	#2,d0
	lea	$3000+$1a12a,a0		; level times
	move.l	(a0,d0.w),$3000+$22fe.w
	rts	


.Toggle_Unlimited_Time
	eor.b	#$19,$3000+$9f6.w	; subq.l #1,Time <-> tst.l Time
	rts


PATCHHI
	MOVE.L	#$4E714EB9,$33E6.W
	PEA	KEYHP(PC)
	MOVE.L	(A7)+,$33EA.W

	lea	PLHIGH(pc),a0
	lea	$3000.w,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	JMP	$3000.W

PLHIGH	PL_START
	PL_ORW	$c0a+2,1<<9		; set Bplcon0 color bit
	PL_P	$938,FixAudXVol		; fix byte write to volumee register
	PL_P	$3a8,AckVBI
	PL_END


PATCHMENU
	move.w	#$6002,$3118			;24-bit access
	MOVE.L	#$4E714EB9,$323A.W
	PEA	KEYHP(PC)
	MOVE.L	(A7)+,$323E.W
	LEA.L	$3000.W,A0
	LEA.L	$4000.W,A1

.2	CMP.W	#$33FC,(A0)		;COMPARE WITH MOVE.W #,$DFF058
	BNE.S	.1
	CMP.L	#$DFF058,4(A0)
	BNE.S	.1
	MOVE.W	2(A0),6(A0)
	MOVE.W	#$4EB9,(A0)
	PEA	BLITWAIT1(PC)
	MOVE.L	(A7)+,2(A0)

.1	ADDQ.L	#2,A0
	CMP.L	A1,A0
	BLS.S	.2

	MOVE.W	#$A0,$375A.W		; set value for DMA wait


	lea	PLMENU(pc),a0
	lea	$3000.w,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	JMP	$3000.W


PLMENU	PL_START
	PL_P	$382,AckVBI
	PL_ORW	$bce+2,1<<9		; set Bplcon0 color bit
	PL_P	$916,FixAudXVol		; fix byte write to volume register
	PL_END

AckVBI	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte

FixAudXVol
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts


BLITWAIT1
	MOVE.L	A0,-(A7)
	MOVE.L	4(A7),A0
	MOVE.W	(A0),$DFF058
	BTST	#6,$DFF002
.1	BTST	#6,$DFF002
	BNE.S	.1
	MOVE.L	(A7)+,A0
	ADDQ.L	#2,(A7)
	RTS


DBFD0
	AND.L	#$FFFF,D0
	DIVU	#$28,D0

FixDBF
.4	MOVE.L	D0,-(A7)
	MOVE.B	$DFF006,D0
.3	CMP.B	$DFF006,D0
	BEQ.S	.3
	MOVE.L	(A7)+,D0
	DBF	D0,.4
	RTS

;d0.highwort - starttrack
;d0.lowwort - # of tracks (here ignored)
;d1 - len
;d2 - 0:read, 1:write
;a0 - dest

LOADROUT
	MOVEM.L	D0-A6,-(A7)
	MOVE.L	D1,D6
	move.l	a0,a4
	CLR.W	D0
	SWAP	D0
	CMP.W	#$68,D0
	BEQ.W	.HI
.LOAD	SUBQ.L	#1,D0
	MULU	#$189C,D0
	
	MOVE.L	D6,D1	;LENGTH
	MOVEQ.L	#1,D2	;DISK#
	move.l	(_resload,pc),a3
	jsr	(resload_DiskLoad,a3)
	movem.l	(a7),d0-a6
	swap	d0
	cmp.w	#$68,d0
	bne.s	.ret
	;check inserted here if highest score is 900k and must be reduced to
	;a sensible value
.chkscore
	move.l	(a0),d0
	cmp.l	#900000,d0
	bne.s	.ret		;score already reduced

	moveq.l	#8-1,d7		;8 entries
	move.l	a0,a4
	move.l	a4,a0
.reduscore
	move.l	(a0),d0
	divu	#50000,d0
	btst	#0,d0
	bne.s	.no50k
	swap	d0
	tst.w	d0
	bne.s	.no50k
	move.l	(a0),d0
	divu	#10000,d0	;convert 900k to 360k
	mulu	#4000,d0
	move.l	d0,(a0)

.no50k	lea	$16(a0),a0
	dbf	d7,.reduscore

	;simple bubblesort to reorder the (now unordered) entries
.stexch	moveq	#0,d6		;changed-flag
	moveq	#8-1-1,d7	;8 entries, 7 searched (last automatically)
	move.l	a4,a0
	
.exch2	move.l	(a0),d0
	cmp.l	$16(a0),d0
	bhs.s	.noexch

	st	d6
	moveq	#$16/2-1,d5	;entry is $16 bytes
	move.l	a0,a1
.exch3	move.w	$16(a1),d0
	move.w	(a1),$16(a1)
	move.w	d0,(a1)+
	dbf	d5,.exch3

.noexch
	lea	$16(a0),a0
	dbf	d7,.exch2

	tst.b	d6
	bne.s	.stexch

.ret	MOVEM.L	(A7)+,D0-A6
	RTS

;HISCORE IS ON TRACK $68

.HI	TST.L	D2
	BNE.S	.WRITE
	MOVE.L	D0,D7
	MOVE.L	A0,A4

	lea	(HIGHNAME,PC),a0	;filename
	move.l	(_resload,PC),a3
	jsr	(resload_GetFileSize,a3)
	MOVE.L	A4,A0
	EXG	D0,D7
	tst.l	d7
	BEQ.W	.LOAD

	MOVE.L	A4,A1			;ADDY
	MOVE.L	#$189C,D0		;LEN
	lea	(HIGHNAME,PC),a0	;filename
	jsr	(resload_LoadFile,a3)

	movem.l	(a7),d0-a6
	bra.w	.chkscore

;	MOVEM.L	(A7)+,D0-A6
;	RTS


.WRITE

	move.l	TRAINER(pc),d0
	add.l	LEVEL(pc),d0
	bne.b	.no_highscore_save

	MOVE.L	#$189c,d0

	MOVE.L	A0,A1
	move.l	(_resload,PC),a3
	lea	(HIGHNAME,PC),a0	;filename
	jsr	(resload_SaveFile,a3)

.no_highscore_save
	MOVEM.L	(A7)+,D0-A6
	RTS




_resload	dc.l	0	;address of resident loader
HIGHNAME	DC.B	'atomixhigh',0
	EVEN

; RAW-Key-Codes:
;	ESC	$45
;	DEL	$46
;	F1..F10	$50..$59
;	HELP	$5f
;	NUM *	$5D

KEYHP	
	MOVE.L	D0,-(A7)
	MOVEQ.L	#$50,D0
	BSR.W	DBFD0
	MOVE.L	(A7)+,D0
	BCLR	#6,$BFEE01

	CMP.B	qkey(PC),D0
	BEQ.S	QUIT
	RTS

QUIT	pea	(TDREASON_OK).w
	move.l	(_resload,pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

; a0.l: table with keys and corresponding routines to call
; d0.w: raw key code

Handle_Keys
	move.l	a0,a1
.check_all_key_entries
	movem.w	(a0)+,d1/d2
	cmp.w	d0,d1
	beq.b	.key_entry_found
	tst.w	(a0)
	bne.b	.check_all_key_entries
	rts	
	
.key_entry_found
	pea	Flush_Cache(pc)
	jmp	(a1,d2.w)

Flush_Cache
	move.l	_resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts

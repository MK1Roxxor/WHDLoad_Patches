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
;
;  :Requires.	whdload-package :)
;  :Copyright.	Freeware
;  :Language.	68000 Assembler
;  :Translator.	ASM-One 1.25, Barfly 2.9, ASM-Pro 1.16d
;  :To Do.
;---------------------------------------------------------------------------*

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
		dc.w	13		;ws_Version
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

_name		dc.b	"Atomix",0
_copy		dc.b	"1990 Tale/Thalion",0
_info		dc.b	"installed & fixed by Harry and Wepl and StingRay",10
		dc.b	"V1.3 (13-Aug-2018)",0
		even

;======================================================================

;	DOSCMD	"WDate >T:date"
		dc.b	"$VER: Atomix_Slave_1.3"
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
	



PATCHGAME
	MOVE.L	#$4E714EB9,$4E7A.W
	PEA	KEYHP(PC)
	MOVE.L	(A7)+,$4E7E.W

	lea	PLGAME(pc),a0
	lea	$3000.w,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	JSR	$3000.W
	MOVE.L	$5306.W,$106.W
	RTS

PLGAME	PL_START
	PL_ORW	$20a8+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$21c4+2,1<<9		; set Bplcon0 color bit
	PL_P	$a0a,AckVBI
	PL_END

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
	MOVE.L	#$189c,d0

	MOVE.L	A0,A1
	move.l	(_resload,PC),a3
	lea	(HIGHNAME,PC),a0	;filename
	jsr	(resload_SaveFile,a3)
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


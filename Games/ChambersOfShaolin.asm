;*---------------------------------------------------------------------------
;  :Program.	ChambersOfShaolin.asm
;  :Contents.	Slave for "Chambers Of Shaolin" from 
;  :Author.	Mr.Larmer of Wanted Team, StingRay/Scarab^Scoopex
;  :History.	04.03.2000
;		10.01.2016 (StingRay):
;		- DMA wait in sample player fixed
;		- Save game bug fixed, only 1 player was saved		
;		- Bplcon0 color bit fixes
;		- Uninitialised copperlists in Thalion intro fixed
;		- some patches converted to use patchlists
;		- WHDLF_ClearMem flag added, WHDLF_Disk removed
;		11.01.2016:
;		- another DMA wait fixed
;		- keyboard routines rewritten
;		- 68000 quitkey support
;		- all patches converted to use patchlists
;		- interrupts fixed
;		- fixes applied to 2nd version (SPS 3049) too
;		- code optimised and cleaned up a bit
;		- save game size reduced to 16100 bytes
;		- 2 blitter waits added
;		- title in about window changed (Of -> of) :)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, ASM-Pro 1.16d
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i

	IFD	BARFLY
	OUTPUT	dh2:chambersofshaolin/ChambersOfShaolin.slave
	OPT	O+ OG+			;enable optimizing
	ENDC

FLAGS	= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem	;ws_flags	
DEBUG

;======================================================================

HEADER
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	FLAGS		;ws_flags
		dc.l	$80000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-HEADER	;ws_GameLoader
		IFD	DEBUG
		dc.w	.dir-HEADER	;ws_CurrentDir
		ELSE
		dc.w	0		;ws_CurrentDir
		ENDC
		dc.w	0		;ws_DontCache
		dc.b	0		;ws_keydebug = none
		dc.b	$59		;ws_keyexit = F10
		dc.l	0		;ws_ExpMem
		dc.w	.name-HEADER	;ws_name
		dc.w	.copy-HEADER	;ws_copy
		dc.w	.info-HEADER	;ws_info

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/ChambersOfShaolin",0
	ENDC
	
.name	dc.b	'Chambers of Shaolin',0
.copy	dc.b	'1989 Thalion',0
.info	dc.b	'Installed and fixed by Mr.Larmer & StingRay',10
	dc.b	'Version 1.2 (11.01.2016)',-1
	dc.b	'Greetings to Mario Cattaneo',10
	dc.b	'Jeff',0
	CNOP 0,2

;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	resload(pc),a1
		move.l	a0,(a1)			;save for later use
	move.l	a0,a2

		lea	Tags(pc),a0
		jsr	resload_Control(a2)

		lea	$800.w,A0
		move.l	#$6E000,D0
		move.l	#$1600,D1
		moveq	#1,D2
		bsr.w	LoadDisk

		move.l	#$1600,D0
		jsr	resload_CRC16(a2)

	move.w	#$4ef9,d1			; jmp

		move.w	d1,$100.w
		pea	Patch1(pc)		; Chambers 1
		move.l	(A7)+,$102.w

		move.w	d1,$106.w
		pea	Patch2(pc)		; Chambers 2
		move.l	(A7)+,$108.w

		move.w	d1,$10C.w
		pea	Patch3(pc)		; Fight
		move.l	(A7)+,$10E.w

		move.w	#$4E71,$82C.w		; skip check return value from read proc

		lea	PLBOOT3050(pc),a0
		cmp.w	#$9674,d0		; SPS 3050
		beq.b	.patch

		cmp.w	#$9593,D0		; SPS 3049
		bne.b	.not_support

		move.w	d1,$112.w
		pea	Patch4(pc)
		move.l	(A7)+,$114.w

	lea	PLBOOT3049(pc),a0
.patch	lea	$800.w,a1
	jsr	resload_Patch(a2)
	jmp	$800.w



.not_support
		subq.l	#8,a7
		pea	(TDREASON_WRONGVER).w
		move.l	resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

Tags	dc.l	TAG_DONE

AckVBI	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rte

;--------------------------------

; Boot, SPS 3049 version with Grandslam intro
PLBOOT3049
	PL_START
	PL_W	$3c+2,$112	; jsr $2000.w->jsr $112.w->jsr Patch4
	PL_W	$254+2,$100	; jsr $2000.w->jsr $100.w->jsr Patch1
	PL_W	$288+2,$106	; jsr $2000.w->jsr $106.w->jsr Patch2
	PL_W	$2b8+2,$10c	; jsr $2000.w->jsr $10c.w->jsr Patch3
	PL_P	$e16,Load

	PL_ORW	$bac+2,1<<9	; set Bplcon0 color bit
	PL_PS	$64,Patch5	; patch Thalion intro
	PL_PSS	$bde,.setkbd,2	; install keyboard interrupt
	PL_R	$d7a		; end level 2 interrupt code
	PL_P	$d1c,AckVBI
	PL_END

.setkbd	bsr	SetLev2IRQ
	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts
	
.kbdcust
	move.b	RawKey(pc),d0
	jmp	$800+$d64.w


; Boot, SPS 3050 version without Grandslam intro
PLBOOT3050
	PL_START
	PL_W	$250+2,$100	; jsr $2000.w->jsr $100.w->jsr Patch1
	PL_W	$284+2,$106	; jsr $2000.w->jsr $106.w->jsr Patch2
	PL_W	$2b4+2,$10c	; jsr $2000.w->jsr $10c.w->jsr Patch3
	PL_P	$e12,Load

	PL_ORW	$ba8+2,1<<9	; set Bplcon0 color bit
	PL_PS	$60,Patch5	; patch Thalion intro
	PL_PSS	$bda,.setkbd,2	; install keyboard interrupt
	PL_R	$d76		; end level 2 interrupt code
	PL_P	$d18,AckVBI
	PL_END

.setkbd	bsr	SetLev2IRQ
	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts
	
.kbdcust
	move.b	RawKey(pc),d0
	jmp	$800+$d60.w



;--------------------------------

; Thalion intro
Patch5	lea	PLTHALION(pc),a0
	pea	$15000
	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)

PLTHALION
	PL_START
	PL_L	$11000,-2		; fix uninitialised copperlist
	PL_L	$117d0,-2		; fix uninitialised copperlist
	PL_PSS	$2e,.setkbd,2
	PL_END

.setkbd	bsr	SetLev2IRQ
	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts

.kbdcust
	move.b	RawKey(pc),d0	; optimised original code
	bpl.b	.ok
	moveq	#0,d0
.ok	move.b	d0,$15000+$666
	rts

;--------------------------------

; Grandslam intro
Patch4	lea	PLINTRO(pc),a0
	bra.b	Patch2k

PLINTRO	PL_START
	PL_W	$4,$6004		; don't set stack
	PL_W	$270e,$6004		; skip Atari ST code
	PL_ORW	$40+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$5e,.setkbd,2
	PL_END

.setkbd	bsr	SetLev2IRQ
	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts

.kbdcust
	move.b	RawKey(pc),$2000+$1ea.w
	rts

;--------------------------------

; chambers 1 (first 3 tests)
Patch1	lea	PLCHAMBERS1(pc),a0
	bra.b	Patch2k
	

PLCHAMBERS1
	PL_START
	PL_P	$54e4,Load
	PL_P	$61be,FixDMAWait
	PL_END
	

;--------------------------------

; chambers 2 (called after "test of balance")
Patch2	lea	PLCHAMBERS2(pc),a0

Patch2k	lea	$2000.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$2000.w

PLCHAMBERS2
	PL_START
	PL_R	$2f8			; disable "Format Disk"
	PL_P	$689e,Load

	;PL_R	$69d6			; skip load disk 2

	PL_P	$6ac0,SaveGame
	PL_R	$6c50			; skip check if disk 2
	

	PL_P	$69d6,.loadgame	; required for correct character saving!
	PL_P	$77ee,FixDMAWait
	PL_PS	$2a74,.wblit
	PL_PS	$b44,.wblit
	PL_END

.wblit	lea	$dff000,a6
	tst.b	$02(a6)
.wb	btst	#6,$02(a6)
	bne.b	.wb
	rts

.loadgame
	lea	savename(pc),a0
	lea	$47bac,a1
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nosave

	lea	savename(pc),a0
	lea	$47bac,a1
	jsr	resload_LoadFile(a2)
	
.nosave	rts


FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d1	
.loop	move.b	$dff006,d0
.wait	cmp.b	$dff006,d0
	beq.b	.wait
	dbf	d1,.loop
	movem.l	(a7)+,d0/d1
	rts


;--------------------------------

; fight
Patch3	lea	PLFIGHT(pc),a0
	bra.w	Patch2k


PLFIGHT	PL_START
	PL_P	$3f3e,Load
	PL_P	$4050,LoadSaveGame
	PL_L	$413a,$70004e75		; fake disk 2 (character disk) check
	PL_L	$4170,$70004e75		; fake disk 1 (game disk) check
	PL_S	$46c0,4			; skip file size check 
	PL_END
	

;--------------------------------

Load		movem.l	d0-a6,-(a7)

		move.w	(a6)+,d0		; track
		mulu.w	#512*11,d0

		move.w	(a6)+,d1		; sector
		subq.w	#1,D1
		mulu	#512*2,d1
		add.l	d1,d0

		tst.w	(a6)+			; which side?
		beq.b	.side1

		add.l	#80*512*11,d0		; side 2
.side1
		move.w	(a6)+,d1		; length
		mulu.w	#512,d1

		move.l	(a6),a0			; destination

		moveq	#1,d2			; disk 1

		bsr.b	LoadDisk

		movem.l	(a7)+,d0-a6
		moveq	#0,D0
		rts

;--------------------------------

LoadSaveGame
		movem.l	d0-a6,-(a7)

		lea	savename(pc),a0
		move.l	resload(pc),a2
		jsr	resload_GetFileSize(a2)
		tst.l	d0
		beq.b	.not_saved

		lea	$3CAB6,a1		;address
		lea	savename(pc),a0		;filename
		jsr	resload_LoadFile(a2)

		movem.l	(A7)+,d0-a6
		moveq	#0,D0
		rts
.not_saved
		movem.l	(A7)+,d0-a6
		moveq	#-1,D0
		rts
SaveGame
		movem.l	d0-a6,-(a7)


		;move.l	#$4000,d0		;len
	move.l	#16000+100,d0	; game decodes 8000 words, 100 bytes for header
		lea	$47BAC,a1		;address
		move.l	#'VOL3',(a1)
		lea	savename(pc),a0		;filename
		move.l	resload(pc),a2
		jsr	resload_SaveFile(a2)
.skip
		movem.l	(a7)+,d0-a6
		moveq	#0,D0
		rts

savename	dc.b	"savegame",0
		CNOP 0,2

;--------------------------------

resload	dc.l	0			;address of resident loader

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

;======================================================================


***********************************
*** Level 2 IRQ			***
***********************************

SetLev2IRQ
	pea	.int(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode

	move.w	#1<<3,$dff09c			; clear ports interrupt
	move.w	#1<<15|1<<14|1<<3,$dff09a	; and enable it
	rts

.int	movem.l	d0-d1/a0-a2,-(a7)
	lea	$dff000,a0
	lea	$bfe001,a1


	btst	#3,$1e+1(a0)			; PORTS irq?
	beq.w	.end

	btst	#3,$d00(a1)			; KBD irq?
	beq.b	.end

	moveq	#0,d0
	move.b	$c00(a1),d0
	lea	Key(pc),a2
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)

	move.l	KbdCust(pc),d1
	beq.b	.nocustom
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.nocustom	
	


	or.b	#1<<6,$e00(a1)			; set output mode



	cmp.b	HEADER+ws_keydebug(pc),d0	
	bne.b	.nodebug
	movem.l	(a7)+,d0-d1/a0-a2
	move.w	(a7),6(a7)			; sr
	move.l	2(a7),(a7)			; pc
	clr.w	4(a7)				; ext.l sr
	bra.b	.debug


.nodebug
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	.exit
	

.nokeys	moveq	#3-1,d1
.loop	move.b	$6(a0),d0
.wait	cmp.b	$6(a0),d0
	beq.b	.wait
	dbf	d1,.loop


	and.b	#~(1<<6),$e00(a1)	; set input mode
.end	move.w	#1<<3,$9c(a0)
	move.w	#1<<3,$9c(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte

.debug	pea	(TDREASON_DEBUG).w
	bra.b	EXIT

.exit	bra.w	QUIT


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	jmp	resload_Abort(a2)

Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine


	END

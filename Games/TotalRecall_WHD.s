***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       TOTAL RECALL WHDLOAD SLAVE           )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             January 2016                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 03-Jan-2016	- blitter waits added (68010+ only)
;		- ATOM decrunche relocated
;		- interrupts fixed
;		- access faults fixed (files loaded too high into memory
;		  so decruncher accesses memory outside $80000)
;		- byte writes to volume register fixed
;		- all levels tested
;		- this is enough for this crap game!

; 02-Jan-2016	- work started

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
DEBUGKEY	= $58		; F9
QUITKEY		= $59		; F10
;DEBUG

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM

HEADER	SLAVE_HEADER		; ws_security + ws_ID
	dc.w	10		; ws_version
	dc.w	FLAGS		; flags
	dc.l	524288		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	dc.w	.dir-HEADER	; ws_CurrentDir
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_KeyDebug
	dc.b	QUITKEY		; ws_KeyExit
	dc.l	0		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
;	dc.w	0		; ws_kickname
;	dc.l	0		; ws_kicksize
;	dc.w	0		; ws_kickcrc
;
;; v17
;	dc.w	.config-HEADER	; ws_config


.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/TotalRecall/"
	ENDC
	dc.b	"data",0
.name	dc.b	"Total Recall",0
.copy	dc.b	"1990 Ocean",0
.info	dc.b	"Installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.1 (02.01.2016)",0
Name	dc.b	"Recall.prg",0
	CNOP	0,2


TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	TAG_END
resload	dc.l	0


Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


; install keyboard irq
	bsr	SetLev2IRQ

; load game
	lea	Name(pc),a0
	lea	$5000.w,a1
	move.l	a1,a5
	jsr	resload_LoadFileDecrunch(a2)

	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$2091,d0			; SPS 1770 (budget version)
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok	add.w	#$20,a5				; skip hunk header

; patch
	lea	PLGAME(pc),a0
	bsr.b	.patch


; set default VBI
	lea	AckVBI(pc),a0
	move.l	a0,$6c.w

	lea	$900.w,a7


; and start game
	jmp	(a5)

.patch	move.l	a5,a1
	jmp	resload_Patch(a2)


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)

AckVBI	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rte

AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte

KillSys	move.w	#$7fff,$dff09a		; disable all interrupts
	bsr	WaitRaster
	move.w	#$7ff,$dff096		; disable all DMA
	move.w	#$7fff,$dff09c		; disable all interrupt requests
	lea	AckVBI(pc),a0
	move.l	a0,$6c.w
	rts


LoadHighscores
	movem.l	d0-a6,-(a7)
	move.l	resload(pc),a2
	
	lea	Highname(pc),a0
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nohigh

	lea	Highname(pc),a0
	lea	$1400+$e79e,a1
	jsr	resload_LoadFile(a2)

.nohigh
	movem.l	(a7)+,d0-a6
	rts
	

SaveHighscores
	addq.b	#2,$1400+$eabd		; original code

	movem.l	d0-a6,-(a7)
	lea	Highname(pc),a0
	lea	$1400+$e79e,a1
	move.l	#$e886-$e79e,d0
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)

	movem.l	(a7)+,d0-a6


	rts

Highname
	dc.b	"TotalRecall.highs",0
	CNOP	0,2


PLGAME	PL_START
	PL_SA	$0,$8			; skip Forbid()
	PL_PSA	$c6,LoadFile,$15e
	PL_P	$3ac,DECRUNCH_ATOM
	PL_P	$3a2,.patchmain
	PL_P	$36c,.patch0022
	PL_P	$398,.patch0023
	PL_END

; level 2
.patch0022
	move.w	#$4e75,$425b4		; original code

	movem.l	d0-a6,-(a7)
	lea	PL0022(pc),a0
	lea	$17e4.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	move.l	CPUFLAGS(pc),d0
	lsr.l	#1,d0			; 68000?
	bcc.b	.noblit22		; -> no blitter wait patches
	lea	PL0022_BLIT(pc),a0
	lea	$17e4.w,a1
	jsr	resload_Patch(a2)
.noblit22
	movem.l	(a7)+,d0-a6
	rts

; level 5
.patch0023
	move.w	#$4e75,$45020		; original code

	movem.l	d0-a6,-(a7)
	lea	PL0023(pc),a0
	lea	$17e4.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	move.l	CPUFLAGS(pc),d0
	lsr.l	#1,d0			; 68000?
	bcc.b	.noblit23		; -> no blitter wait patches
	lea	PL0023_BLIT(pc),a0
	lea	$17e4.w,a1
	jsr	resload_Patch(a2)
.noblit23
	movem.l	(a7)+,d0-a6
	rts
	


.patchmain
	move.w	#1,$aeae

	movem.l	d0-a6,-(a7)
	lea	PL0001(pc),a0
	lea	$1400.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	move.l	CPUFLAGS(pc),d0
	lsr.l	#1,d0			; 68000?
	bcc.b	.noblit			; -> no blitter wait patches
	lea	PL0001_BLIT(pc),a0
	lea	$1400.w,a1
	jsr	resload_Patch(a2)
.noblit
	bsr	LoadHighscores

	movem.l	(a7)+,d0-a6
	rts



PL0001_BLIT
	PL_START
	PL_PS	$6a88,wblit1
	PL_PS	$6ad4,wblit2
	PL_PS	$6b00,wblit2
	PL_PS	$6b4e,wblit2
	PL_PS	$6b6a,wblit2
	PL_PS	$6b86,wblit2
	PL_PS	$6ba2,wblit2
	
	PL_PS	$6d0e,wblit1
	PL_PS	$6d60,wblit2
	PL_PS	$6d92,wblit2
	PL_PS	$6ddc,wblit2
	PL_PS	$6dfc,wblit2
	PL_PS	$6e1c,wblit2
	PL_PS	$6e3c,wblit2
	
	PL_PS	$7152,wblit1
	PL_PS	$71a4,wblit2
	PL_PS	$71ee,wblit2
	PL_PS	$720e,wblit2
	PL_PS	$722e,wblit2
	PL_PS	$7250,wblit2

	PL_PS	$3878,wblit1
	PL_END

wblit2	move.w	d7,$58(a6)
	bra.b	WaitBlit

wblit1	lea	$dff000,a6
WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts


wblit3	lea	$dff000,a3
	bra.b	WaitBlit
	

PL0001	PL_START
	PL_P	$138,AckVBI
	PL_PSS	$3948,.ackVBI,2
	PL_P	$1066,FixVolume		; fix byte write to volume register
	PL_P	$1cd6,FixVolume		; fix byte write to volume register
	PL_PSS	$332c,.setkbd,4
	;PL_P	$9b56,SaveHighscores	; doesn't work yet!
	PL_END

.setkbd	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts

.kbdcust

	IFD	DEBUG
	move.b	RawKey(pc),d0
	cmp.b	#$35,d0			; N - skip level
	bne.b	.noN
	move.b	#3,$1400+$eabd
.noN

	cmp.b	#$33,d0			; C - enable in-game cheat
	bne.b	.noC
	move.w	#1,$100e
.noC

	ENDC


	moveq	#0,d0
	move.b	Key(pc),d0
	jmp	$1400+$3430.w


.ackVBI	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rts
	

PL0022_BLIT
	PL_START
	PL_PS	$f7a,wblit3
	PL_PS	$10c6,wblit3
	PL_PS	$4238,wblit3
	PL_PS	$4378,wblit4
	PL_P	$4370,wblit5
	PL_P	$43c6,wblit5
	PL_END

wblit4	bsr	WaitBlit
	ror.w	#4,d0
	move.w	d0,$42(a3)
	rts

wblit5	move.w	#$400,$96(a3)
	bra.w	WaitBlit


PL0022	PL_START
	PL_PSS	$14a4,.setkbd,2
	PL_SA	$19b8,$19c8		; skip stuff in level 2 interrupt code
	PL_R	$19ea			; end level 2 interrupt code
	PL_END
	
.setkbd	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts

.kbdcust

	IFD	DEBUG
	move.b	RawKey(pc),d0
	cmp.b	#$36,d0
	bne.b	.noN
	move.w	#1,$17e4+$326
	ENDC

.noN


	moveq	#0,d0
	move.b	Key(pc),d0
	jmp	$17e4+$19b4.w



PL0023_BLIT
	PL_START
	PL_PS	$f7e,wblit3
	PL_PS	$10ca,wblit3
	PL_PS	$423c,wblit3
	PL_PS	$437c,wblit4
	PL_PS	$4374,wblit4
	PL_P	$43ca,wblit5
	PL_END

PL0023	PL_START
	PL_PSS	$14a8,.setkbd,2
	PL_SA	$19bc,$19cc		; skip stuff in level 2 interrupt code
	PL_R	$19ee			; end level 2 interrupt code
	PL_END
	
.setkbd	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts

.kbdcust
	IFD	DEBUG
	move.b	RawKey(pc),d0
	cmp.b	#$36,d0
	bne.b	.noN
	move.w	#1,$17e4+$332
.noN
	ENDC

	moveq	#0,d0
	move.b	Key(pc),d0
	jmp	$17e4+$19b8.w



FixVolume
	move.w	#0,$dff0c8
	rts

LoadFile
	move.l	$100.w,a1		; destination
	lea	$900+($340-$90),a0	; file name

; files "0008", "0009", "0010" and "0013 are originally loaded
;  to $78000 (or even higher) and are packed, ATOM decruncher
; writes to memory outside the $80000 boundary when decrunching it
; -> we load to different destination!

	cmp.w	#"13",$104.w
	beq.b	.fix
	cmp.w	#"10",$104.w
	beq.b	.fix
	cmp.b	#"9",3(a0)
	beq.b	.fix
	cmp.b	#"8",3(a0)		; file "0008"?
	bne.b	.no0008
.fix	lea	$68000,a1		; fix load address!
.no0008


	move.l	resload(pc),a2
	jmp	resload_LoadFile(a2)

	


WaitRaster
	move.l	d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.b	.wait
.wait2	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	beq.b	.wait2
	move.l	(a7)+,d0
	rts


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
	beq.b	.end

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
.quit	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.exit	pea	(TDREASON_OK).w
	bra.b	.quit

Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine


DECRUNCH_ATOM

; see comment in the "LoadFile" routine!
	lea	$900+($340-$90),a1	; file name
	cmp.w	#"13",$104.w
	beq.b	.fix
	cmp.w	#"10",$104.w
	beq.b	.fix
	cmp.b	#"9",3(a1)
	beq.b	.fix
	cmp.b	#"8",3(a1)
	bne.b	.decrunch
.fix	lea	$68000,a0
.no0008	
	bsr.b	.decrunch
	move.l	$100.w,a0		; copy to correct destination
	lea	$68000,a1
	move.w	#32000/4-1,d7
.copy	move.l	(a1)+,(a0)+
	dbf	d7,.copy
	rts



.decrunch
	movem.l	d0-d7/a0-a6,-(sp)
	cmp.l	#'ATOM',(a0)+
	bne.w	lbC0004EA
	move.l	(a0)+,d0
	move.l	d0,-(sp)
	lea	($10,a0,d0.l),a5
	move.l	a5,a4
	lea	(lbL000578,pc),a3
	moveq	#$19,d0
lbC0003CA
	move.b	-(a4),(a3)+
	dbra	d0,lbC0003CA
	movem.l	a3/a4,-(sp)
	pea	(a5)
	move.l	(a0)+,d0
	lea	(a0,d0.l),a6
	move.b	-(a6),d7
	bra.w	lbC000488

lbC0003E2
	lea	(lbC000520,pc),a4
	moveq	#1,d6
	bsr.b	lbC00044A
	bra.b	lbC000444

lbC0003EC
	moveq	#6,d6
lbC0003EE
	add.b	d7,d7
	beq.b	lbC000414
lbC0003F2
	dbhs	d6,lbC0003EE
	blo.b	lbC0003FE
	moveq	#6,d5
	sub.w	d6,d5
	bra.b	lbC000422

lbC0003FE
	moveq	#3,d6
	bsr.b	lbC00044A
	beq.b	lbC000408
	addq.w	#6,d5
	bra.b	lbC000422

lbC000408
	moveq	#7,d6
	bsr.b	lbC00044A
	beq.b	lbC00041A
	add.w	#$15,d5
	bra.b	lbC000422

lbC000414
	move.b	-(a6),d7
	addx.b	d7,d7
	bra.b	lbC0003F2

lbC00041A
	moveq	#13,d6
	bsr.b	lbC00044A
	add.w	#$114,d5
lbC000422
	move.w	d5,-(sp)
	bne.b	lbC000460
	lea	(lbW00050C,pc),a4
	moveq	#2,d6
	bsr.b	lbC00044A
	cmp.w	#5,d5
	blt.b	lbC000468
	addq.w	#2,sp
	subq.w	#6,d5
	bgt.b	lbC0003E2
	move.l	a5,a4
	blt.b	lbC000440
	addq.w	#4,a4
lbC000440
	moveq	#1,d6
	bsr.b	lbC00044A
lbC000444
	move.b	(a4,d5.w),-(a5)
	bra.b	lbC000488

lbC00044A
	clr.w	d5
lbC00044C
	add.b	d7,d7
	beq.b	lbC00045A
lbC000450
	addx.w	d5,d5
	dbra	d6,lbC00044C
	tst.w	d5
	rts

lbC00045A
	move.b	-(a6),d7
	addx.b	d7,d7
	bra.b	lbC000450

lbC000460
	lea	(lbW0004F6,pc),a4
	moveq	#2,d6
	bsr.b	lbC00044A
lbC000468
	move.w	d5,d4
	move.b	(14,a4,d4.w),d6
	ext.w	d6
	bsr.b	lbC00044A
	add.w	d4,d4
	beq.b	lbC00047A
	add.w	(-2,a4,d4.w),d5
lbC00047A
	lea	(1,a5,d5.w),a4
	move.w	(sp)+,d5
	move.b	-(a4),-(a5)
lbC000482
	move.b	-(a4),-(a5)
	dbra	d5,lbC000482
lbC000488
	moveq	#11,d6
	moveq	#11,d5
lbC00048C
	add.b	d7,d7
	beq.b	lbC0004F0
lbC000490
	dbhs	d6,lbC00048C
	blo.b	lbC00049A
	sub.w	d6,d5
	bra.b	lbC0004B4

lbC00049A
	moveq	#7,d6
	bsr.b	lbC00044A
	beq.b	lbC0004A6
	addq.w	#8,d5
	addq.w	#3,d5
	bra.b	lbC0004B4

lbC0004A6
	moveq	#2,d6
	bsr.b	lbC00044A
	swap	d5
	moveq	#15,d6
	bsr.b	lbC00044A
	addq.l	#8,d5
	addq.l	#3,d5
lbC0004B4
	subq.w	#1,d5
	bmi.b	lbC0004C6
	moveq	#1,d6
	swap	d6
lbC0004BC
	move.b	-(a6),-(a5)
	dbra	d5,lbC0004BC
	sub.l	d6,d5
	bpl.b	lbC0004BC
lbC0004C6
	cmp.l	a6,a0
lbC0004C8
	bne.w	lbC0003EC
	cmp.b	#$80,d7
	bne.b	lbC0004C8
	move.l	(sp)+,a0
	bsr.w	lbC000524
	movem.l	(sp)+,a3/a4
	move.l	(sp)+,d0
	bsr.w	lbC000564
	moveq	#$19,d0
lbC0004E4
	move.b	-(a3),(a4)+
	dbra	d0,lbC0004E4
lbC0004EA
	movem.l	(sp)+,d0-d7/a0-a6
	rts

lbC0004F0
	move.b	-(a6),d7
	addx.b	d7,d7
	bra.b	lbC000490

lbW0004F6
	DC.W	$20
	DC.W	$60
	DC.W	$160
	DC.W	$360
	DC.W	$760
	DC.W	$F60
	DC.W	$1F60
	DC.W	$405
	DC.W	$708
	DC.W	$90A
	DC.W	$B0C
lbW00050C
	DC.W	$20
	DC.W	$60
	DC.W	$E0
	DC.W	$1E0
	DC.W	$3E0
	DC.W	$5E0
	DC.W	$7E0
	DC.W	$405
	DC.W	$607
	DC.W	$808

lbC000520
	bra.b	lbC000542

;fiX Label expected
	DC.W	$1008

lbC000524
	move.w	-(a0),d7
	clr.w	(a0)
lbC000528
	dbra	d7,lbC00052E
	rts

lbC00052E
	move.l	-(a0),d0
	clr.l	(a0)
	lea	(a5,d0.l),a1
	lea	($7D00,a1),a2
lbC00053A
	moveq	#3,d6
lbC00053C
	move.w	(a1)+,d0
	moveq	#3,d5
lbC000540
	add.w	d0,d0
lbC000542
	addx.w	d1,d1
	add.w	d0,d0
	addx.w	d2,d2
	add.w	d0,d0
	addx.w	d3,d3
	add.w	d0,d0
	addx.w	d4,d4
	dbra	d5,lbC000540
	dbra	d6,lbC00053C
	movem.w	d1-d4,(-8,a1)
	cmp.l	a1,a2
	bne.b	lbC00053A
	bra.b	lbC000528

lbC000564
	lsr.l	#4,d0
	lea	(-12,a6),a6
lbC00056A
	move.l	(a5)+,(a6)+
	move.l	(a5)+,(a6)+
	move.l	(a5)+,(a6)+
	move.l	(a5)+,(a6)+
	dbra	d0,lbC00056A
	rts

lbL000578
	DC.L	0
	DC.L	0
	DC.L	0
	DC.L	0
	DC.L	0
	DC.L	0
	DC.L	0

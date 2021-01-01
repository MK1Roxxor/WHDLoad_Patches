***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(  THE FOUR SEASONS/PARASITE WHDLOAD SLAVE   )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            December 2020                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 01-Jan-2021	- patches done yesterday now tested and a few things
;		  corrected (mainly the SMC handling, all level 3 interrupt
;		  routines replaced with own code)

; 31-Dec-2020	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
DEBUG

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
	IFD	DEBUG
	dc.w	.dir-HEADER	; ws_CurrentDir
	ELSE
	dc.w	0		; ws_CurrentDir
	ENDC
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

; v17
;	dc.w	.config-HEADER	; ws_config


;.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Parasite/TheFourSeasons",0
	ENDC

.name	dc.b	"The Four Seasons",0
.copy	dc.b	"1993 Parasite",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (01.01.2021)",0
	CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; install level 2 interrupt
	bsr	SetLev2IRQ


	; load boot
	moveq	#0,d0
	move.l	#2*512,d1
	lea	$100-$10.w,a0

	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)
	move.l	d5,d0
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$911a,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

	; patch boot
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)	


	; set default interrupts
	pea	AckVBI(pc)
	move.l	(a7)+,$6c.w
	pea	AckLev6(pc)
	move.l	(a7)+,$78.w

	; enable needed DMA channels
	move.w	#$83c0,$dff096


	; run demo
	jmp	$2f8(a5)




QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)


KillSys	move.w	#$7fff,$dff09a
	bsr.b	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	rts


WaitRaster
.wait1	btst	#0,$dff005
	beq.b	.wait1
.wait2	btst	#0,$dff005
	bne.b	.wait2
	rts

AckVBI_R
	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rts

AckVBI	bsr.b	AckVBI_R
	rte

AckLev6_R
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rts

AckLev6	bsr.b	AckLev6_R
	rte

WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts

; ---------------------------------------------------------------------------

PLBOOT	PL_START
	PL_P	$10,Load	
	PL_PS	$36a,.PatchReplay
	PL_P	$3be,.PatchPre

	PL_END

.PatchReplay
	lea	PLREPLAY(pc),a0
	pea	$44ba.w
	bra.b	PatchAndRun

.PatchPre
	lea	PLPRE(pc),a0
	pea	$20f30

PatchAndRun
	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)

; d0.w: sector
; d1.l: number of longs to load
; a0.l: destination

Load	mulu.w	#512,d0
	lsl.l	#2,d1			; longs -> bytes
	moveq	#1,d2
	move.l	resload(pc),a1
	jmp	resload_DiskLoad(a1)

; ---------------------------------------------------------------------------

PLPRE	PL_START
	PL_PS	$56,.PatchIntro
	PL_PS	$5c,.PatchMain
	PL_END

.PatchIntro
	lea	PLINTRO(pc),a0
	pea	$21a00
	bra.b	PatchAndRun


.PatchMain
	lea	PLMAIN(pc),a0
	lea	$60000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$60000+$2558		; $2558: skip zero bytes at start of file



; ---------------------------------------------------------------------------

PLINTRO	PL_START
	PL_PSS	$2e,.FixVPOSW,2
	PL_ORW	$78+2,1<<3		; enable level 2 interrupts
	PL_P	$162,.VBI
	PL_END


; Recoded level 3 interrupt routine to easily deal
; with the self-modifying code.

.VBI	movem.l	d0-a6,-(a7)

	btst	#4,$dff01e+1
	beq.b	.noCopInt

	subq.w	#1,$21a00+$1a8
	bne.b	.skip
	jsr	$21a00+$54a
	move.w	#200,$21a00+$1a8
.skip


	move.l	$21a00+$18a+2,a0	; ptr to VBI routine 1 (SMC)
	jsr	(a0)

	move.l	$21a00+$190+2,a0	; ptr to VBI routine 2 (SMC)
	jsr	(a0)

	move.w	#1<<4,$dff09c		; acknowledge copper interrupt
	move.w	#1<<4,$dff09c


.noCopInt

	movem.l	(a7)+,d0-a6
	jmp	$44c0.w			; call replayer VBI



.FixVPOSW
	move.w	$dff004,d0		; VPOSR
	and.w	#$7fff,d0		; clear LOF bit
	move.w	d0,$dff02a		; VPOSW
	rts




; ---------------------------------------------------------------------------

PLREPLAY
	PL_START
	PL_PSS	$1a,AckVBI_R,2
	PL_END


; ---------------------------------------------------------------------------


PLMAIN	PL_START
	PL_ORW	$25b8+2,1<<3		; enable level 2 interrupts
	PL_P	$265e,.VBI
	PL_END


; Recoded level 3 interrupt routine to easily deal
; with the self-modifying code.

.VBI	movem.l	d0-a6,-(a7)

	btst	#4,$dff01e+1
	beq.b	.noCopInt

	move.l	$60000+$2670+2,a0	; VBI routine (SMC)
	jsr	(a0)

	move.w	#1<<4,$dff09c
	move.w	#1<<4,$dff09c
	

.noCopInt
	cmp.w	#$4e73,$65000+$2682
	movem.l	(a7)+,d0-a6

	beq.b	.noReplayer
	jmp	$44c0.w			; call replayer VBI


.noReplayer
	bra.w	AckVBI


; ---------------------------------------------------------------------------




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

	lea	Key(pc),a2
	move.b	$c00(a1),d0
	move.b	d0,(a2)

	not.b	d0
	ror.b	d0
	move.b	d0,RawKey-Key(a2)


	move.l	KbdCust(pc),d1
	beq.b	.noCust
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.noCust


	or.b	#1<<6,$e00(a1)			; set output mode

	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT

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



Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0

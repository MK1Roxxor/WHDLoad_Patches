***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    WICKED HOUSE/ORIGIN WHDLOAD SLAVE       )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                                May 2020                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 18-May-2020	- work started
;		- and finished a while later, DMA wait in replayer fixed (x4),
;		  SMC fixed, interrupt fixed, copperlist problems fixed,
;		  Bplcon0 color bit fix, INTENA settings fixed, blitter
;		  waits added (x4), timing fixed

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem
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
;
; v17
;	dc.w	.config-HEADER	; ws_config


.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Origin/WickedHouse",0
	ENDC

.name	dc.b	"Wicked House",0
.copy	dc.b	"1992 Origin",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (16.05.2020)",0

	CNOP	0,4

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; install level 2 interrupt
	bsr	SetLev2IRQ

	; load demo
	lea	$42500,a0
	move.l	#$98a00,d0
	move.l	#$22000,d1
	moveq	#1,d2
	move.l	a0,a5
	move.l	d1,d5
	jsr	resload_DiskLoad(a2)
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$DE02,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

	; patch
	lea	PLMAIN(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)


	; and run
	add.l	#$4f000-$42500,a5
	jmp	(a5)




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

AckVBI	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte

AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte

WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts

; ---------------------------------------------------------------------------

PLMAIN	PL_START
	PL_S	$cb2a,6


	PL_PSS	$fade,FixDMAWait,2
	PL_PSS	$faf4,FixDMAWait,2
	PL_PSS	$102b6,FixDMAWait,2
	PL_PSS	$102cc,FixDMAWait,2
	PL_SA	$ccc6,$ccd0		; don't modify level 6 interrupt code
	PL_P	$cdaa,AckLev6
	PL_P	$cde0,.Load

	PL_ORW	$10be6+2,1<<9		; set Bplcon0 color bit
	PL_PS	$cb2a,.PatchIntro

	PL_SA	$cca6,$ccae
	PL_PS	$ccb8,.SetDMA
	PL_W	$ccda+2,$e008

	PL_PSS	$edc4,.wblit1,2
	PL_PSS	$d3ea,.wblit2,2
	PL_PS	$ed7e,.wblit3
	PL_PSS	$dc04,.wblit4,2

	PL_PS	$d16a,.CheckQuit

	PL_END


.CheckQuit
	move.b	$bfec01,d0
	move.b	d0,d1
	ror.b	d1
	not.b	d1
	cmp.b	HEADER+ws_keyexit(pc),d1
	beq.w	QUIT
	rts

.wblit1	bsr	WaitBlit
	move.w	#$0100,$dff040
	rts

.wblit2	bsr	WaitBlit
	move.l	d2,$4c(a5)
	move.l	d2,$54(a5)
	rts

.wblit3	bsr	WaitBlit
	move.l	d1,$dff050
	rts

.wblit4	bsr	WaitBlit
	move.l	a1,$54(a5)
	move.l	a0,$50(a5)
	rts


.SetDMA	move.w	#$83f0,$dff096
	rts

.PatchIntro
	lea	PLINTRO(pc),a0
	pea	$20000
	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)


.Load	mulu.w	#512*11,d0
	move.l	(a4),d1
	moveq	#1,d2
	move.l	resload(pc),a2
	jmp	resload_DiskLoad(a2)


PLINTRO	PL_START
	PL_SA	$0,$a			; skip Forbid()
	PL_SA	$38,$40			; don't disable interrupts
	PL_PSA	$60,WaitRaster,$6c

	PL_B	$149,5			; don't show white screen too long
	
	PL_W	$15a+2,3		; fix timing for fade up
	PL_W	$184+2,3		; fix timing for fade down
	PL_END


FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d0
.loop	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait
	dbf	d0,.loop
	movem.l	(a7)+,d0/d1
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

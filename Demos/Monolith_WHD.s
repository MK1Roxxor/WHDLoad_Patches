***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(     MONOLITH/MEGAWATTS WHDLOAD SLAVE       )*)---.---.   *
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

; 17-May-2020	- work started
;		- and finished a few hours later, lots of bugs in the code!
;		- DMA wait in replayer fixed (x2), byte write to volume
;		  register fixed, writes to $dff1da fixed (x2), access
;		  faults fixed (x9), all OS stuff patched (DoIO(),
;		  AddIntServer(), WaitBlit() etc.)

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
;
; v17
;	dc.w	.config-HEADER	; ws_config


.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Megawatts/Monolith",0
	ENDC

.name	dc.b	"Monolith",0
.copy	dc.b	"1991 Megawatts",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (17.05.2020)",0

	CNOP	0,4

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; install level 2 interrupt
	bsr	SetLev2IRQ


	; load boot
	lea	$10000,a0
	move.l	#$400,d0
	move.l	#$15a00,d1
	moveq	#1,d2
	move.l	a0,a5
	move.l	d1,d5
	jsr	resload_DiskLoad(a2)
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$A39D,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

	; build fake exec library
	lea	$2000.w,a6
	move.l	a6,$4.w
	lea	-456(a6),a0		; DoIO
	move.w	#$4ef9,(a0)+
	pea	DoIO(pc)
	move.l	(a7)+,(a0)


	; patch
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)


	; and run
	move.l	a6,a1			; IOStd
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



DoIO	movem.l	d0-a6,-(a7)
	cmp.w	#2,$1c(a1)	; only CMD_READ is supported
	bne.b	.exit

	move.l	$2c(a1),d0
	movem.l	$24(a1),d1/a0
	moveq	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)


.exit	movem.l	(a7)+,d0-a6
	rts


WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts

; ---------------------------------------------------------------------------

PLBOOT	PL_START
	PL_PSS	$1f9e,FixDMAWait,2
	PL_PSS	$1fb6,FixDMAWait,2
	PL_P	$228c,FixAudXVol
	PL_PSA	$1c6e,.SetVBI,$1c80
	PL_PSA	$1c84,.RemVBI,$1c96
	PL_P	$1c9c,.PatchMain
	PL_SA	$18d4,$18da		; skip write to $dff1da


	PL_P	$1a86,.FixPal
	PL_P	$1aa0,.FixPal2

	PL_PS	$19dc,.FixFade
	PL_PS	$1a0a,.FixFade
	PL_PS	$1a3c,.FixFade
	PL_PS	$193e,.FixFade
	PL_PS	$196a,.FixFade
	PL_PS	$199a,.FixFade
	

	PL_END


.FixFade
	lea	$10000+$1842,a3
	move.w	d0,d1
	subq.w	#1,d1
	rts


.FixPal	subq.w	#1,d0
.copy1	move.l	(a0)+,a2
	move.w	(a2),(a1)+
	clr.w	(a2)
	dbf	d0,.copy1
	movem.l	(a7)+,d0/d1/a0-a2
	rts


.FixPal2
	subq.w	#1,d0
.copy2	move.l	(a0)+,d1
	move.l	d1,a2
	move.w	(a1)+,(a2)
	dbf	d0,.copy2
	movem.l	(a7)+,d0/d1/a0-a2
	rts



.PatchMain
	movem.l	d0-a6,-(a7)
	lea	PLMAIN(pc),a0
	lea	$40000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	jmp	$40000


.SetVBI	pea	.VBI(pc)
	bra.b	SetVBI

.VBI	jsr	$10000+$1ca2
	bra.w	AckVBI

.RemVBI	pea	AckVBI(pc)
	;bra.b	SetVBI



SetVBI	move.l	(a7)+,$6c.w
	move.w	#$c028,$dff09a
	rts

; ---------------------------------------------------------------------------


PLMAIN	PL_START
	PL_PSA	$14cde,.SetVBI,$14cec
	PL_PSA	$14cf0,.SetLev2,$14cfe
	PL_SA	$149ba,$149dc		; skip gfxlib stuff and write to $dff1da
	PL_R	$14770			; disable OwnBlitter()
	PL_R	$147a8			; disable DisownBlitter()
	PL_P	$1478c,WaitBlit
	PL_W	$149ea+2,$83c0		; set correct DMA

	PL_W	$1475e+2,32-1		; flx loop counter
	PL_END



.SetLev2
	lea	.KbdCust(pc),a0
	move.l	a0,KbdCust-.KbdCust(a0)
	rts

.KbdCust
	move.b	Key(pc),d0
	jmp	$40000+$14e04

.SetVBI	pea	.VBI(pc)
	bra.b	SetVBI

.VBI	jsr	$40000+$14dd0
	bra.w	AckVBI


FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d0
.loop	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait
	dbf	d0,.loop
	movem.l	(a7)+,d0/d1
	rts


FixAudXVol
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
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

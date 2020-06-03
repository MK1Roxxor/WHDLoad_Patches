***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   STARLIGHT/MYSTIC & TRSI WHDLOAD SLAVE    )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                               June 2020                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 03-Jun-2020	- work started
;		- and finished some hours later, interrupts fixed,
;		  Bplcon0 color bit fixes (x21), blitter waits added (x2)


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Exec/Exec.i
	INCLUDE	lvo/Exec.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem
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
	IFD	DEBUG
	dc.w	.dir-HEADER	; ws_CurrentDir
	ELSE
	dc.w	0		; ws_CurrentDir
	ENDC
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_KeyDebug
	dc.b	QUITKEY		; ws_KeyExit
	dc.l	524288		; ws_ExpMem
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
	dc.b	"SOURCES:WHD_Slaves/Demos/Mystic/Starlight",0
	ENDC

.name	dc.b	"Starlight",0
.copy	dc.b	"1993 Mystic & TRSI",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (03.06.2020)",0
	CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; install level 2 interrupt
	bsr	SetLev2IRQ

	lea	$1000.w,a7


	; load boot
	move.l	#$25800,d0
	move.l	#$4000,d1
	lea	$7b000,a0

	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)
	move.l	d5,d0
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$E69F,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

	; patch
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	pea	AckVBI(pc)
	move.l	(a7)+,$6c.w

	; set correct DMA
	move.w	#$83e0,$dff096


	; set ext. memory
	move.l	HEADER+ws_ExpMem(pc),a0
	add.l	#524288,a0

	sub.l	#232000,a0
	move.l	a0,$7fffa
	sub.l	#131072,a0
	move.l	a0,$7fff6
	sub.l	#65536,a0
	move.l	a0,$7fff2


	; and run
	jmp	$121c(a5)




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

AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte

WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts


FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d0
.loop	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait
	dbf	d0,.loop
	movem.l	(a7)+,d0/d1
	rts


; ---------------------------------------------------------------------------

PLBOOT	PL_START
	PL_P	$134e,AckVBI
	PL_ORW	$1358+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1364+2,1<<9		; set Bplcon0 color bit
	PL_P	$136c,Load

	PL_PS	$12b6,.PatchIntro
	PL_PS	$12f8,.PatchMain
	PL_P	$1332,.PatchEconomy
	PL_END

.PatchIntro
	lea	PLINTRO(pc),a0
	pea	$2000.w
.Patch	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)

.PatchMain
	lea	PLMAIN(pc),a0
	pea	$1d000
	bra.b	.Patch

.PatchEconomy
	lea	PLECONOMY(pc),a0
	pea	$18500
	bra.b	.Patch
	


Load	move.l	(a4),a0			; destination
	moveq	#0,d0
	moveq	#0,d1
	move.b	$10(a4),d0		; track
	move.b	$11(a4),d1		; sector
	mulu.w	#512*11,d0
	mulu.w	#512,d1
	add.l	d1,d0
	move.l	4(a4),d1		; length in bytes
	move.b	DiskNum(pc),d2
	move.l	resload(pc),a1
	jmp	resload_DiskLoad(a1)



DiskNum	dc.b	1
	dc.b	0


; ---------------------------------------------------------------------------

PLINTRO	PL_START
	PL_ORW	$2b2+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$316+2,1<<9		; set Bplcon0 color bit
	PL_P	$1a0a,Load
	PL_ORW	$1294+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$12ec+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$5286+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$52ee+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$550+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$5b8+2,1<<9		; set Bplcon0 color bit
	

	PL_PSS	$51be,.wblit1,2
	PL_PSS	$494,.wblit1,2
	PL_END

.wblit1	bsr	WaitBlit
	move.l	#$ffffffff,$44(a6)
	rts

; ---------------------------------------------------------------------------

PLMAIN	PL_START
	PL_ORW	$5c22+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$5d72+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$5d96+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$5dd2+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$5f22+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$5f46+2,1<<9		; set Bplcon0 color bit
	PL_PSA	$95c,Load,$9ee
	PL_P	$a12,Load
	PL_PSA	$AC2,.ChangeDisk,$b16
	PL_P	$5a3e,AckVBI
	PL_END

.ChangeDisk
	lea	DiskNum(pc),a0
	eor.b	#%11,(a0)		; 1<->2
	rts


; ---------------------------------------------------------------------------

PLECONOMY
	PL_START
	PL_ORW	$3bb6+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$4506+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$45ae+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$4606+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$4666+2,1<<9		; set Bplcon0 color bit
	PL_P	$41b8,AckVBI
	PL_ORW	$36+2,1<<3		; enable level 2 interrupts
	

	PL_END



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

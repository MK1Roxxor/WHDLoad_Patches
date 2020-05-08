***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(     ELEKTRICA/CASCADE WHDLOAD SLAVE        )*)---.---.   *
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

; 08-May-2020	- work started
;		- and finished a while later, DMA wait in replayer fixed (x4),
;		  SMC fixed, out of bounds blit fixed

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
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
	dc.b	"SOURCES:WHD_Slaves/Demos/Cascade/Elektrica",0
	ENDC

.name	dc.b	"Elektrica",0
.copy	dc.b	"1990 Cascade",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (08.05.2020)",0

	CNOP	0,4

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2


	; install level 2 interrupt
	bsr	SetLev2IRQ	


	; load boot
	lea	$2000.w,a0
	moveq	#0,d0
	move.l	#$400,d1
	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$B103,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

	; patch
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	; and run
	jmp	3*4(a5)




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


AckVBI	bsr.b	AckVBI_R
	rte

AckVBI_R
	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rts

FlushCache
	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts


; ---------------------------------------------------------------------------

PLBOOT	PL_START
	PL_P	$50,.FlushCache		; flush cache after copying loader
	PL_P	$56,.Load
	PL_END

.FlushCache
	bsr.b	FlushCache
	jmp	$e000



.Load	lea	$E000+$324-$56,a3
.loop	move.l	(a3)+,a0		; destination
	movem.w	(a3)+,d0/d1

	move.w	d0,d7			
	move.l	a0,a5

	mulu.w	#512*11*2,d0
	mulu.w	#512*11*2,d1
	moveq	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)


	lea	.TAB(pc),a0
.search	cmp.w	(a0)+,d7
	beq.b	.patch
	addq.w	#2,a0
	tst.w	(a0)
	bpl.b	.search
	bra.b	.next

.patch	move.w	(a0)+,d0
	lea	.TAB(pc,d0.w),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)		


.next	tst.l	(a3)
	bpl.b	.loop
	move.l	4(a3),a0
	jmp	(a0)

.TAB	dc.w	30,PLREPLAY-.TAB
	dc.w	44,PLINTRO_PRE-.TAB
	dc.w	01,PLMAIN_PRE-.TAB

	dc.w	-1			; end of table


PLREPLAY
	PL_START
	PL_PSS	$2ce,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$2e4,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$a0e,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$a24,FixDMAWait,2	; fix DMA wait in replayer
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


; ---------------------------------------------------------------------------

PLINTRO_PRE
	PL_START
	PL_P	$188,.PatchIntro
	PL_END

.PatchIntro
	lea	PLINTRO(pc),a0
	pea	$40000
PatchDefjam
	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)

PLINTRO
	PL_START
	PL_SA	$86,$9c			; skip drive access (motor off)
	PL_P	$c0,.SetVBI		; flush cache after copying VBI code
	PL_P	$e0,AckVBI
	PL_END

.SetVBI	move.l	resload(pc),a0
	jsr	resload_FlushCache(a0)

	pea	$7f000
	move.l	(a7)+,$6c.w
	move.w	#$C028,$dff09a
	rts

; ---------------------------------------------------------------------------

PLMAIN_PRE
	PL_START
	PL_P	$188,.PatchMain
	PL_END

.PatchMain
	lea	PLMAIN(pc),a0
	pea	$68000
	bra.b	PatchDefjam

PLMAIN	PL_START
	PL_P	$180,AckVBI
	PL_ORW	$E00+2,1<<3		; enable level 2 interrupts
	PL_SA	$38,$5c			; skip drive access (motor off)
	PL_SA	$CCE,$CD4		; skip wrong blit
	PL_END
	


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

	move.b	$c00(a1),d0
	not.b	d0
	ror.b	d0

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




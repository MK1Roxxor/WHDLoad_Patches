***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*( KRAFTWERK MEGA-MIX/SPACE CAKE WHDLOAD SLAVE )*)---.---.  *
*   `-./                                                            \.-'  *
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
;		- and finished a short while later, DMA wait in replayer
;		  fixed (x4), BPLCON0 color bit fixes (x13), OS stuff
;		  patched, blitter waits added (x2)

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
	dc.b	"SOURCES:WHD_Slaves/Demos/Spacecake/KraftwerkMegaMix",0
	ENDC

.name	dc.b	"Kraftwerk Mega-Mix",0
.copy	dc.b	"1991 Spacecake",0
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


	; load intro
	lea	$18000,a0
	move.l	#$70800,d0
	move.l	#$A400,d1
	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$5799,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

	; decrypt
	move.l	a5,a0
	move.w	#$a400/4-1,d0
.loop	move.l	(a0),d1
	swap	d1
	move.l	d1,(a0)+
	dbf	d0,.loop
	

	; patch
	lea	PLINTRO(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	; run intro
	movem.l	d0-a6,-(a7)
	jsr	(a5)
	movem.l	(a7)+,d0-a6


	; load main
	move.l	#$400,d0
	move.l	#$6dc00,d1
	lea	$10000,a0
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)

	; load remaining part of scrolltext
	move.l	#$6e400,d0
	move.l	#$600,d1
	lea	$7dc00,a0
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)


	; enable level 2 interrupts again
	move.w	#$C008,$dff09a

	; patch and run demo
	lea	PLMAIN(pc),a0
	pea	$10000
	move.l	(a7),a1
	jmp	resload_Patch(a2)
	





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

PLINTRO	PL_START
	PL_PSA	$10,SetCop,$34
	PL_W	$40+2,$83c0		; enable correct DMA
	PL_SA	$96,$a0			; skip Permit()
	PL_ORW	$302+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$41e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$43a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$586+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$5ae+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$5de+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$606+2,1<<9		; set Bplcon0 color bit

	PL_PS	$80,RemCop
	PL_END


SetCop	lea	$dff080,a0
	rts

RemCop	lea	$1000.w,a0
	move.l	a0,$dff080
	bra.w	KillSys



; ---------------------------------------------------------------------------

PLMAIN	PL_START
	PL_PSA	$14,SetCop,$38
	PL_PSS	$8be,FixDMAWait,2
	PL_PSS	$8d4,FixDMAWait,2
	PL_PSS	$ff6,FixDMAWait,2
	PL_PSS	$100c,FixDMAWait,2
	
	PL_ORW	$4b4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$4dc+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$500+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$528+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$5b4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$5e0+2,1<<9		; set Bplcon0 color bit

	PL_PS	$22a,.wblit
	PL_PS	$26c,.wblit
	PL_END

.wblit	lea	$dff000,a5
	tst.b	$02(a5)
.wb	btst	#6,$02(a5)
	bne.b	.wb
	rts



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




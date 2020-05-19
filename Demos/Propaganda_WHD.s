***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(  PROPAGANDA/ZERO DEFECTS WHDLOAD SLAVE     )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              April 2020                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 19-May-2020	- some size optimising

; 18-May-2020	- buggy register restoring fixed

; 27-Apr-2020	- interrupt problem in main part fixed

; 26-Apr-2020	- work started
;		- RawDIC imager coded

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
	dc.w	.dir-HEADER	; ws_CurrentDir
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_KeyDebug
	dc.b	QUITKEY		; ws_KeyExit
	dc.l	4096		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/ZeroDefects/Propaganda/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Propaganda",0
.copy	dc.b	"1991 Zero Defects",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.01 (19.05.2020)",0

FileName
	dc.b	"Propaganda_00",0

	CNOP	0,4

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

; install level 2 interrupt
	bsr	SetLev2IRQ

	lea	AckVBI(pc),a0
	move.l	a0,$6c.w
	lea	AckLev6(pc),a0
	move.l	a0,$78.w

	move.l	HEADER+ws_ExpMem(pc),a0
	add.w	#4096,a0
	move.l	a0,a7
	sub.w	#2048,a0
	move.l	a0,usp

	; load intro
	lea	FileName(pc),a0
	lea	$30000,a1
	move.l	a1,a5
	jsr	resload_LoadFileDecrunch(a2)
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$8DAF,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

	; patch
	lea	PLINTRO(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	; enable DMA
	move.w	#$83c0,$dff096


	; run intro
	movem.l	d0-a6,-(a7)
	add.l	#$37000,a5
	jsr	(a5)
	movem.l	(a7)+,d0-a6
	

	; load main part
	lea	FileName(pc),a0
	addq.b	#1,12(a0)
	lea	$57000,a1
	move.l	a1,a5
	jsr	resload_LoadFileDecrunch(a2)

	; patch
	lea	PLMAIN(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)


	; set default copperlist
	lea	$1000.w,a0
	move.l	a0,$dff080


	; enable DMA
	move.w	#$83c0,$dff096

	; and run
	add.l	#$10000,a5
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

AckLev6_R
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rts	

AckLev6	bsr.b	AckLev6_R
	rte




; ---------------------------------------------------------------------------

PLINTRO	PL_START
	PL_P	$3A7ca,AckLev6
	PL_P	$370ce,AckVBI
	PL_W	$370ca,$4cdf	; movem.l (a7),d0-a7 -> movem.l (a7)+,d0-a7

	; fix CPU dependent delay loops
	PL_PS	$37258,.Delay
	PL_PS	$372b4,.Delay
	PL_PS	$372fe,.Delay

	PL_PS	$375fe,.WaitBlit

	PL_P	$3786e,.CheckBlit	; fix out of bounds blit

	PL_P	$37044,KillSys
	PL_END

.Delay	divu.w	#$34,d7
.loop	move.b	$dff006,d0
.same_line
	cmp.b	$dff006,d0
	beq.b	.same_line
	dbf	d7,.loop
	rts
	
.CheckBlit
	cmp.l	#$80000,a1
	bcc.b	.noblit
	move.w	#(12<<6)|(32/16),$58(a6)
.noblit	rts

.WaitBlit
	lea	$dff000,a6

WaitBlit
	tst.b	$02(a6)
.wblit	btst	#6,$02(a6)
	bne.b	.wblit
	rts

; ---------------------------------------------------------------------------

PLMAIN	PL_START
	PL_P	$1335e,.LoadTune
	PL_P	$1204c,AckVBI
	PL_P	$12062,AckVBI
	PL_P	$12078,AckVBI
	PL_P	$122aa,AckVBI
	PL_P	$13f82,AckLev6

	PL_PS	$100ee,.FlushCache
	PL_PS	$12bf6,.WaitBlit

	PL_ORW	$12118+2,1<<3		; enable level 2 interrupts


	PL_W	$10ca6,$4cdf
	PL_W	$11612,$4cdf
	PL_W	$122a6,$4cdf		; movem.l (a7),xx -> movem.l (a7)+,x
	PL_END

.WaitBlit
	add.w	#16,d0
	add.w	d0,d0
	bra.w	WaitBlit


.FlushCache
	move.w	#$8000,d4
	moveq	#0,d1
	move.l	resload(pc),a0
	jmp	resload_FlushCache(a0)
	
	



.LoadTune
	movem.l	d0-a6,-(a7)
	addq.b	#2,d0
	add.b	#"0",d0
	lea	FileName(pc),a0
	move.b	d0,12(a0)
	lea	$400.w,a1
	move.l	resload(pc),a2
	jsr	resload_LoadFileDecrunch(a2)

	; interrupts are disabled when .LoadTune is called,
	; (INTENA = $4000), enable them again
	move.w	#$c028,$dff09a
	movem.l	(a7)+,d0-a6
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




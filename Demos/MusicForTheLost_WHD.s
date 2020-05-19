***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*( MUSIC FOR THE LOST/ABYSS WHDLOAD SLAVE     )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            February 2019                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 12-Feb-2019	- work started
;		- and finished a while later, interrupts fixed, OS stuff
;		  patched, interrupt and DMA setting fixed, byte write
;		  to Bplcon1 fixed, Bplcon0 color bit fixes (x3), CDANG
;		  bit correctly set (bset #1,$2e(a5) -> move.w #1<<1,$2e(a5)

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
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Abyss/MusicForTheLost",0
	ENDC

.name	dc.b	"Music for the Lost",0
.copy	dc.b	"1993 Abyss",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (12.02.2019)",0

	CNOP	0,4

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

; install level 2 interrupt
	bsr	SetLev2IRQ

; load boot
	lea	$2000.w,a0
	move.l	#$400,d0
	move.l	#$1200,d1
	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)

	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$b2e2,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT

.ok

; patch
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)


	pea	AckVBI(pc)
	move.l	(a7)+,$6c.w

	move.w	#$c028,$dff09a
	move.w	#$83c0,$dff096

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

VBIcust	dc.l	0


PLBOOT	PL_START
	PL_SA	$f6,$fe			; skip write to FMODE
	PL_P	$140,AckVBI
	PL_SA	$4,$3e			; skip drive check
	PL_PSA	$60,.AllocMem,$6c	; emulate AllocMem
	PL_P	$378,Load
	PL_PS	$174,.PatchIntro
	PL_PS	$1a2,.PatchMain
	PL_P	$1cc,.PatchEnd
	PL_END

.PatchIntro
	move.l	a0,a1
	move.l	a0,-(a7)
	lea	PLINTRO(pc),a0
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	move.l	(a7)+,a0
	jsr	(a0)
	jmp	$2000+$9C.W

.PatchMain
	move.l	a0,a1
	move.l	a0,-(a7)
	lea	PLMAIN(pc),a0
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	move.l	(a7)+,a0
	lea	$2000+$1e0.w,a1		; drive status
	jmp	(a0)

.PatchEnd
	move.l	a0,a1
	move.l	a0,-(a7)
	lea	PLEND(pc),a0
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	move.l	(a7)+,a0
	jmp	(a0)


.AllocMem
	moveq	#0,d0			; we don't need any memory to buffer
	rts				; the tunes


Load	movem.l	d0-a6,-(a7)
	mulu.w	#512*11,d0
	mulu.w	#512*11,d1
	move.w	DiskNum(pc),d2
	move.l	resload(pc),a1
	jsr	resload_DiskLoad(a1)
	movem.l	(a7)+,d0-a6
	rts

DiskNum	dc.w	1


PLINTRO	PL_START
	PL_SA	$0,$a			; skip Forbid()
	PL_P	$178,AckVBI
	PL_P	$240,AckVBI
	PL_P	$30a,AckVBI
	PL_ORW	$6e+2,1<<3		; enable level 2 interrupts
	PL_R	$ca			; disable system stuff
	PL_PSS	$3b208,AckLev6_R,2
	PL_PS	$3b264,AckLev6_R
	PL_END

PLMAIN	PL_START
	PL_SA	$0,$a			; skip Forbid()
	PL_P	$5dc,AckVBI
	PL_P	$5fa,AckVBI
	PL_P	$69e,AckVBI
	PL_ORW	$168+2,1<<3		; enable level 2 interrupts
	PL_PSS	$715a,AckLev6_R,2
	PL_PS	$71b6,AckLev6_R
	PL_P	$54aa,.SetDiskNum
	PL_P	$541e,Load
	PL_END

.SetDiskNum
	movem.l	d0-a6,-(a7)
	moveq	#1,d0
	lea	DiskNum(pc),a0
	cmp.l	#$a5901a67,d2
	beq.b	.disk1
	moveq	#2,d0
.disk1	move.w	d0,(a0)
	movem.l	(a7)+,d0-a6
	rts

PLEND	PL_START
	PL_SA	$0,$a			; skip Forbid()
	PL_ORW	$26+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$2907c,AckLev6_R,2
	PL_PS	$290d8,AckLev6_R
	PL_P	$200,AckVBI
	PL_P	$306,AckVBI
	PL_ORW	$242+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$d0+2,1<<3		; enable level 2 interrupts
	PL_SA	$14c,$156		; skip write to FMODE
	PL_PS	$e8,.SetCDANG		; correctly set CDANG bit
	PL_B	$25c,$3b		; move.b d2,$102(a5) -> move.w	
	PL_END

.SetCDANG
	move.w	#1<<1,$2e(a5)
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




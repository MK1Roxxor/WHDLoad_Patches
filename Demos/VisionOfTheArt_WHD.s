***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   VISION OF THE ART/MYSTIC WHDLOAD SLAVE   )*)---.---.   *
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

; 01-May-2020	- work started
;		- and finished about 2 hours later, Bplcon0 color bit
;		  fixes (x4), interrupt fixed, timing fixed

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
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Mystic/VisionOfTheArt",0
	ENDC

.name	dc.b	"Vision of the Art",0
.copy	dc.b	"1994 Mystic",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (01.05.2020)",0

	CNOP	0,4

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; install level 2 interrupt
	bsr	SetLev2IRQ


	; load boot
	lea	$70000,a0
	move.l	#$96000,d0
	move.l	#$2800,d1
	moveq	#1,d2
	move.l	a0,a5
	move.l	d1,d5
	jsr	resload_DiskLoad(a2)
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$0D06,d0
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

AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte


; ---------------------------------------------------------------------------

PLBOOT	PL_START
	PL_P	$326,Load
	PL_P	$1a0,.PatchMain
	PL_END

.PatchMain
	lea	PLMAIN(pc),a0
	pea	$2000.w
	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)


Load	move.l	(a4),a0			; destination
	moveq	#0,d0
	moveq	#0,d1
	move.b	$10(a4),d0		; track
	move.b	$11(a4),d1		; sector
	mulu.w	#512*11,d0
	mulu.w	#512,d1
	add.l	d1,d0
	move.l	4(a4),d1		; length in bytes
	moveq	#1,d2
	move.l	resload(pc),a1
	jmp	resload_DiskLoad(a1)

; ---------------------------------------------------------------------------

PLMAIN	PL_START
	PL_SA	$0,$12			; skip drive access (motor off)
	PL_P	$32e,AckVBI
	PL_P	$30f0,Load
	PL_PS	$46,.PatchIntro
	PL_ORW	$22cc+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$24a8+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3e+2,1<<3		; enable level 2 interrupts

	PL_PS	$788,.PatchBlueLake
	PL_PS	$47a,.PatchMirrorsWhisper
	PL_PS	$53a,.PatchComeToMe
	PL_PS	$3ba,.PatchUnicorn
	PL_PS	$5fc,.PatchPartnership
	PL_PS	$6c8,.PatchVioletOrgasm
	PL_PS	$848,.PatchDustInnocent
	PL_PS	$910,.PatchWingsOfGlory
	PL_PS	$9d8,.PatchWarmLips
	PL_END


.PatchIntro
	lea	PLINTRO(pc),a0
	lea	$32000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$353e0

.PatchBlueLake
	lea	PLBLUELAKE(pc),a0
.PatchPic
	pea	$47000
	move.l	resload(pc),a2
	move.l	(a7),a1

	lsr.w	#2,d0			; adapt delay counter
	move.l	d0,-(a7)
	jsr	resload_Patch(a2)
	move.l	(a7)+,d0
	rts

.PatchMirrorsWhisper
	lea	PLMIRRORSWHISPER(pc),a0
	bra.b	.PatchPic

.PatchComeToMe
	lea	PLCOMETOME(pc),a0
	bra.b	.PatchPic

.PatchUnicorn
	lea	PLUNICORN(pc),a0
	bra.b	.PatchPic

.PatchPartnership
	lea	PLPARTNERSHIP(pc),a0
	bra.b	.PatchPic

.PatchVioletOrgasm
	lea	PLVIOLETORGASM(pc),a0
	bra.b	.PatchPic

.PatchDustInnocent
	lea	PLDUSTINNOCENT(pc),a0
	bra.b	.PatchPic

.PatchWingsOfGlory
	lea	PLWINGSOFGLORY(pc),a0
	bra.b	.PatchPic

.PatchWarmLips
	;bsr	.SavePicCode
	lea	PLWARMLIPS(pc),a0
	bra.b	.PatchPic


	IFD	DEBUG
.SavePicCode
	movem.l	d0-a6,-(a7)
	lea	.name(pc),a0
	lea	$47000,a1
	move.l	#$80000-$47000,d0
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)
	movem.l	(a7)+,d0-a6
	rts
	
.name	dc.b	"warmlips",0
	cnop	0,2
	ENDC

; ---------------------------------------------------------------------------

PLINTRO	PL_START
	PL_ORW	$37be+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$4770+2,1<<9		; set Bplcon0 color bit
	PL_PS	$39e,.flush		; flush cache after code generation
	PL_END




.flush	lea	$dff000,a6
	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,a7
	rts


; ---------------------------------------------------------------------------

PLBLUELAKE
	PL_START
	PL_PSS	$14e,FixTiming,6
	PL_PSS	$1b6,FixTiming,6
	PL_PSS	$1cc,FixTiming,6
	PL_PSS	$1ec,FixTiming,6
	PL_PSS	$202,FixTiming,6
	PL_END


FixTiming
	bra.w	WaitRaster


PLMIRRORSWHISPER
	PL_START
	PL_PSS	$e8,FixTiming,6
	PL_PSS	$100,FixTiming,6
	PL_PSS	$19e,FixTiming,6
	PL_PSS	$1b4,FixTiming,6
	PL_PSS	$1d4,FixTiming,6
	PL_PSS	$1ea,FixTiming,6
	PL_END


PLCOMETOME
	PL_START
	PL_PSS	$14a,FixTiming,6
	PL_PSS	$19a,FixTiming,6
	PL_PSS	$1b0,FixTiming,6
	PL_PSS	$1dc,FixTiming,6
	PL_PSS	$1f2,FixTiming,6
	PL_END


PLUNICORN
	PL_START
	PL_PSS	$146,FixTiming,6
	PL_PSS	$1a6,FixTiming,6
	PL_PSS	$1b6,FixTiming,6
	PL_PSS	$1cc,FixTiming,6
	PL_PSS	$1ec,FixTiming,6
	PL_PSS	$202,FixTiming,6
	
	PL_END


PLPARTNERSHIP
	PL_START
	PL_PSS	$e2,FixTiming,6
	PL_PSS	$fa,FixTiming,6
	PL_PSS	$17e,FixTiming,6
	PL_PSS	$194,FixTiming,6
	PL_PSS	$1c0,FixTiming,6
	PL_PSS	$1d6,FixTiming,6
	PL_END

PLVIOLETORGASM
	PL_START
	PL_PSS	$112,FixTiming,6
	PL_PSS	$12e,FixTiming,6
	PL_PSS	$1b4,FixTiming,6
	PL_PSS	$1ca,FixTiming,6
	PL_PSS	$1fa,FixTiming,6
	PL_PSS	$214,FixTiming,6
	PL_END

PLDUSTINNOCENT
	PL_START
	PL_PSS	$14a,FixTiming,6
	PL_PSS	$15e,FixTiming,6
	PL_PSS	$1b0,FixTiming,6
	PL_PSS	$1c6,FixTiming,6
	PL_PSS	$1e6,FixTiming,6
	PL_PSS	$1fc,FixTiming,6
	PL_END

PLWINGSOFGLORY
	PL_START
	PL_PSS	$180,FixTiming,6
	PL_PSS	$1a8,FixTiming,6
	PL_PSS	$1d4,FixTiming,6
	PL_PSS	$1ea,FixTiming,6
	PL_PSS	$20e,FixTiming,6
	PL_PSS	$228,FixTiming,6
	PL_END

PLWARMLIPS
	PL_START
	PL_PSS	$e0,FixTiming,6
	PL_PSS	$fc,FixTiming,6
	PL_PSS	$19c,FixTiming,6
	PL_PSS	$1b6,FixTiming,6
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




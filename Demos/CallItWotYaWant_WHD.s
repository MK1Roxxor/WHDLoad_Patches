***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*( CALL IT WOT YA WANT/MAGIC WHDLOAD SLAVE    )*)---.---.   *
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

; 16-May-2020	- work started
;		- and finished a while later, RawDIC imager coded,
;		  DMA wait in replayer fixed (x8), Bplcon0 color bit
;		  fixes (x12), keyboard routine fixed, interrupts fixed

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
	dc.b	"SOURCES:WHD_Slaves/Demos/Magic/CallItWotYaWant/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Call It Wot Ya Want",0
.copy	dc.b	"1992 Magic",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (16.05.2020)",0

Name	dc.b	"CIWYW_08C",0

	CNOP	0,4

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; install level 2 interrupt
	bsr	SetLev2IRQ


	; load intro
	lea	Name(pc),a0
	lea	$45000,a1
	move.l	a1,a5
	jsr	resload_LoadFileDecrunch(a2)
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$3ACD,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

	; patch
	lea	PLINTRO(pc),a0
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



; ---------------------------------------------------------------------------

PLINTRO	PL_START
	PL_PSS	$173a,FixDMAWait,2
	PL_PSS	$1750,FixDMAWait,2
	PL_PSS	$1e7a,FixDMAWait,2
	PL_PSS	$1e90,FixDMAWait,2
	PL_P	$1462,AckVBI
	PL_ORW	$10a+2,1<<3		; enable level 2 interrupts
	PL_ORW	$2720+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$274c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$27b4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$283c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2870+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$287c+2,1<<9		; set Bplcon0 color bit
	PL_P	$28aa,Load
	PL_L	$2896+2,$20000		; set destination address for main file
	PL_P	$28a4,.PatchMain
	PL_END
	

.PatchMain
	lea	PLMAIN(pc),a0
	pea	$20000
	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)


Load	;move.l	a0,a1
	bsr.b	.BuildName
	move.l	resload(pc),a2
	jmp	resload_LoadFileDecrunch(a2)


.BuildName
	lea	Name(pc),a0
	moveq	#3-1,d1
.loop	moveq	#$f,d2
	and.b	d0,d2
	cmp.b	#9,d2
	ble.b	.ok
	addq.b	#7,d2
.ok	add.b	#"0",d2
	move.b	d2,6(a0,d1.w)

	lsr.w	#4,d0
	dbf	d1,.loop
	rts

; ---------------------------------------------------------------------------

PLMAIN	PL_START
	PL_P	$b38,.SetKbdCust	
	PL_P	$b30,.AckLev5
	PL_ORW	$40+2,1<<3		; enable level 2 interrupts
	PL_ORW	$464+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$538+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$5fc+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$960+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$ad0+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$b00+2,1<<9		; set Bplcon0 color bit
	PL_P	$b9e,Load
	PL_PSS	$10f2,FixDMAWait,2
	PL_PSS	$1108,FixDMAWait,2
	PL_PSS	$1832,FixDMAWait,2
	PL_PSS	$1848,FixDMAWait,2
	PL_END

.AckLev5
	move.w	#1<<11,$dff09c
	move.w	#1<<11,$dff09c
	rte
	

.SetKbdCust
	lea	.KbdCust(pc),a0
	move.l	a0,KbdCust-.KbdCust(a0)
	rts

.KbdCust
	move.b	d0,$20000+$b9c
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

***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      DRUGSTORE/ABYSS WHDLOAD SLAVE         )*)---.---.   *
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

; 17-Feb-2019	- patch approach changed, all parts are now patched dirctly
;		  after relocating
;		- all parts patched, testing took a long time but patching
;		  the demo was fun as the code is very good!

; 15-Feb-2019	- drive check patch changed, fake exec base created,
;		  demo works from start to finish but there are some minor
;		  problems to fix

; 14-Feb-2019	- some patches

; 13-Feb-2019	- work started

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
	dc.l	524288		; ws_ExpMem
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
	dc.b	"SOURCES:WHD_Slaves/Demos/Abyss/Drugstore",0
	ENDC

.name	dc.b	"Drustore",0
.copy	dc.b	"1995 Abyss",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (17.02.2019)",0

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
	move.l	#$5400,d1
	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)

	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$2b6e,d0
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

	move.l	#$8000,$11e(a5)			; start of free chip memory
	move.l	HEADER+ws_ExpMem(pc),$122(a5)	; start of free fast memory

	lea	$800.w,a6			; ExecBase
	move.l	a6,$4.w

	move.w	#33,$14(a6)			; LIB_VERSION
	clr.b	$129(a6)			; AttnFlags

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
	PL_SA	$56,$da			; skip memory allocations
	PL_P	$108,.PatchMain
	PL_END


.PatchMain
	movem.l	d0-a6,-(a7)
	lea	PLMAIN(pc),a0
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6

	move.l	#"YEAH",$100.w
	jmp	(a1)


PLMAIN	PL_START
	PL_SA	$2a,$cc			; skip OS stuff
	PL_P	$330,AckVBI
	PL_ORW	$158+2,1<<3		; enable level 2 interrupts
	PL_SA	$15e,$164		; skip write to FMODE
	PL_SA	$170,$17c		; skip write to Bplcon3/4
	PL_R	$1992			; disable drive check
	PL_P	$1b8,QUIT
	PL_PS	$39b6,AckLev6_R
	PL_PSS	$3960,AckLev6_R,2
	PL_P	$1868,Load


	PL_PS	$1b26,.StoreStart
	PL_P	$1c5c,.PatchParts

	PL_END


.StoreStart
	move.l	a2,-(a7)
	lea	.Exe(pc),a2
	move.l	a1,(a2)
	move.l	(a7)+,a2
	cmp.l	#$03f3,(a0)+
	rts

.Exe	dc.l	0



.PatchParts
	move.l	.Exe(pc),a1
	lea	.PartNum(pc),a0
	move.w	(a0),d0
	addq.w	#1*2,(a0)
	lea	.TAB(pc),a0
	add.w	(a0,d0.w),a0
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)


	movem.l	(a7)+,d0-a6
	moveq	#0,d0
	rts


.PartNum	dc.w	0




.TAB	dc.w	PL00-.TAB
	dc.w	PL01-.TAB
	dc.w	PL02-.TAB
	dc.w	PL03-.TAB
	dc.w	PL04-.TAB
	dc.w	PL05-.TAB
	dc.w	PL06-.TAB
	dc.w	PL07-.TAB
	dc.w	PL08-.TAB
	dc.w	PL09-.TAB
	dc.w	PL10-.TAB
	dc.w	PL11-.TAB
	dc.w	PL12-.TAB
	dc.w	PL13-.TAB
	dc.w	PL14-.TAB
	dc.w	PL15-.TAB
	dc.w	PL16-.TAB
	dc.w	PL17-.TAB
	dc.w	PL18-.TAB
	dc.w	PL19-.TAB
	dc.w	PL20-.TAB
	dc.w	PL21-.TAB
	dc.w	PL22-.TAB
	dc.w	PL23-.TAB
	dc.w	PL24-.TAB




WaitBlit
	lea	$dff000,a5
	tst.b	$02(a5)
.wblit	btst	#6,02(a5)
	bne.b	.wblit
	rts


Load	movem.l	d0-a6,-(a7)
	mulu.w	#512*11,d0
	mulu.w	#512*11,d1
	sub.b	#"0",d2
	move.l	resload(pc),a1
	jsr	resload_DiskLoad(a1)
	movem.l	(a7)+,d0-a6
	moveq	#0,d3			; no errors
	rts


PL00	PL_START
	PL_PS	$18a6,WaitBlit
	PL_END

PL01	PL_START
	PL_END

PL02	PL_START
	PL_END

PL03	PL_START
	PL_END

PL04	PL_START
	PL_END

PL05	PL_START
	PL_PS	$542,WaitBlit
	PL_END

PL06	PL_START
	PL_END

PL07	PL_START
	PL_END

PL08	PL_START
	PL_END

PL09	PL_START
	PL_PS	$a74,WaitBlit
	PL_END

PL10	PL_START
	PL_END

PL11	PL_START
	PL_END

PL12	PL_START
	PL_END

PL13	PL_START
	PL_END

PL14	PL_START
	PL_END

PL15	PL_START
	PL_END

PL16	PL_START
	PL_ORW	$6e2+4,1<<9		; set Bplcon0 color bit
	PL_END

PL17	PL_START
	PL_PS	$97e,WaitBlit
	PL_END

PL18	PL_START
	PL_END

PL19	PL_START
	PL_END

PL20	PL_START
	PL_END

PL21	PL_START
	PL_END

PL22	PL_START
	PL_PS	$8a6,WaitBlit
	PL_END

PL23	PL_START
	PL_END

PL24	PL_START
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


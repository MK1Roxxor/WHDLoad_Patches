***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       BOHEMIAN/VECTORS WHDLOAD SLAVE       )*)---.---.   *
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

; 09-Jun-2020	- another version of the demo supported
; (V1.01)

; 09-Jun-2020	- demo didn't restart correctly after leaving credits
;		  part, main part patch slightly changed
;		- unused code removed
;		- 68000 quitkey support

; 08-Jun-2020	- patch approach changed, now bootblock is loaded and
;		  patched, this fixes the crash shortly after the demo
;		  started
;		- main part and credits part patched

; 04-Jun-2020	- work started


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
	dc.b	"SOURCES:WHD_Slaves/Demos/Vectors/Bohemian",0
	ENDC

.name	dc.b	"Bohemian",0
.copy	dc.b	"1993 Vectors",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.01 (09.06.2020)",0
	CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; load bootblock
	moveq	#0,d0
	move.l	#1024,d1
	lea	$8000,a0

	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)
	move.l	d5,d0
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$2864,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT

.ok

	; patch
	lea	PLBOOTBLOCK(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	; set ext. memory
	move.l	HEADER+ws_ExpMem(pc),d5

	; and run
	jmp	$58(a5)


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

AckLev6_R
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rts

AckLev6	bsr.b	AckLev6_R
	rte



; ---------------------------------------------------------------------------

PLBOOTBLOCK
	PL_START
	PL_SA	$a0,$be			; skip loader init etc.
	PL_P	$ec,Load
	PL_SA	$88,$a0			; don't copy code to $80a0
	PL_P	$ce,.PatchBoot
	PL_END

.PatchBoot
	; install level 2 interrupt
	bsr	SetLev2IRQ

	lea	$200.w,a0
	move.l	#4*512,d0
	move.l	resload(pc),a2
	jsr	resload_CRC16(a2)
	lea	PLBOOT_V2(pc),a0
	cmp.w	#$68C2,d0
	beq.b	.isV2

	lea	PLBOOT(pc),a0
.isV2	pea	$200.w
	bra.b	PatchAndRun
	



; ---------------------------------------------------------------------------

PLBOOT	PL_START
	PL_SA	$12,$18			; skip write to FMODE
	PL_R	$2d8			; disable drive ready check
	PL_R	$724			; disable track 0 step
	PL_P	$3f0,Load
	PL_R	$792			; disable drive access (motor off)
	PL_PS	$fa,PatchIntroAndMain
	PL_PS	$278,PatchCredits
	PL_PS	$4c,.PatchBase
	PL_END

.PatchBase
	lea	PLBASE(pc),a0
PatchBase
	pea	$7b400
	bra.b	PatchAndRun

PatchIntroAndMain
	lea	PLMAIN(pc),a0
	lea	$1000.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	lea	PLINTRO(pc),a0
	pea	$5b000
	bra.b	PatchAndRun


PatchCredits
	lea	PLCREDITS(pc),a0
	pea	$2e5c6
PatchAndRun
	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)


PLBOOT_V2
	PL_START
	PL_SA	$1c,$26			; skip write to FMODE+BLCON3
	PL_R	$2e4			; disable drive ready check
	PL_R	$730			; disable track 0 step
	PL_P	$3fc,Load
	PL_R	$79e			; disable drive access (motor off)
	PL_PS	$106,PatchIntroAndMain
	PL_PS	$284,PatchCredits
	PL_PS	$58,.PatchBase
	PL_END
	

.PatchBase
	lea	PLBASE_V2(pc),a0
	bra.b	PatchBase


Load	movem.l	d1-a6,-(a7)

	move.w	d1,d5			; save start sector

	move.w	d1,d0
	move.w	d2,d1
	move.l	d3,a0
	mulu.w	#512,d0
	mulu.w	#512,d1
	moveq	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)


	lea	.TAB(pc),a4
.loop	movem.w	(a4)+,d0/d1		; sector/offset to patch list
	cmp.w	d0,d5
	bne.b	.next

	lea	.TAB(pc,d1.w),a0	; a0.l: patch list
	move.l	d3,a1
	jsr	resload_Patch(a2)

.next	tst.w	(a4)
	bpl.b	.loop

	movem.l	(a7)+,d1-a6
	moveq	#0,d0			; no errors
	rts

.TAB	dc.w	$68,PLREPLAY-.TAB
	dc.w	-1
	

PLBASE	PL_START
	PL_PS	$72,AckLev1
	PL_W	$112,$1fe		; FMODE -> NOP
	PL_END

PLBASE_V2
	PL_START
	PL_PS	$72,AckLev1
	PL_W	$12c,$1fe		; FMODE -> NOP
	PL_END
	

AckLev1	move.w	#1<<2,$9c(a6)
	move.w	#1<<2,$9c(a6)
	rts

; Prorunner replay
PLREPLAY
	PL_START
	PL_PSS	$4e,AckVBI_R,2
	PL_PSS	$63e,AckLev6_R,2
	PL_PS	$69a,AckLev6_R
	PL_END



; ---------------------------------------------------------------------------

PLINTRO	PL_START
	PL_PS	$72,AckLev1
	PL_W	$4f4,$1fe		; FMODE -> NOP
	PL_W	$5d8,$1fe		; FMODE -> NOP
	PL_END

; ---------------------------------------------------------------------------

PLMAIN	PL_START
	PL_W	$cb94,$1fe		; FMODE -> NOP
	PL_W	$d0c,$1fe		; FMODE -> NOP
	PL_END
	
; ---------------------------------------------------------------------------

PLCREDITS
	PL_START
	PL_W	$2554,$1fe		; FMODE -> NOP
	PL_PSS	$902,AckLev6_R,2
	PL_PS	$95e,AckLev6_R
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



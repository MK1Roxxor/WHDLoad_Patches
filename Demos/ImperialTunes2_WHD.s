***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(  IMPERIAL TUNES 2/PARASITE WHDLOAD SLAVE   )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            December 2020                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 31-Dec-2020	- work started
;		- and finished a while later, copperlist problem fixed,
;		  mouse reading fixed, timing fixed, memory check fixed,
;		  interrupts fixed


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
;	dc.w	0		; ws_kickname
;	dc.l	0		; ws_kicksize
;	dc.w	0		; ws_kickcrc

; v17
;	dc.w	.config-HEADER	; ws_config


;.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Parasite/ImperialTunes2",0
	ENDC

.name	dc.b	"Imperial Tunes 2",0
.copy	dc.b	"1993 Parasite",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (31.12.2020)",0
	CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; install level 2 interrupt
	bsr	SetLev2IRQ


	; load boot
	move.l	#$76*512,d0
	move.l	#$10*512,d1
	lea	$40000,a0

	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)
	move.l	d5,d0
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$5ff4,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

	; patch boot
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)	


	; set default interrupts
	pea	AckVBI(pc)
	move.l	(a7)+,$6c.w
	pea	AckLev6(pc)
	move.l	(a7)+,$78.w

	; enable needed DMA channels
	move.w	#$83c0,$dff096

	; relocate stack to avoid crash in intro part
	lea	$2000.w,a0
	move.l	a0,USP
	add.w	#1024,a0
	move.l	a0,a7

	; run demo
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

WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts

FlushCache
	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts


; ---------------------------------------------------------------------------

PLBOOT	PL_START
	PL_P	$7a,.GetExtMem
	PL_P	$142,Load
	PL_P	$4ac,.PatchIntro
	PL_END

.GetExtMem
	move.l	HEADER+ws_ExpMem(pc),$140.w
	rts



.PatchIntro
	lea	PLINTRO(pc),a0
	lea	$1a000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$2a800


; d0.w: sector
; d1.w: number of sectors to laod
; a0.l: destination

Load	mulu.w	#512,d0
	mulu.w	#512,d1
	moveq	#1,d2
	move.l	resload(pc),a1
	jmp	resload_DiskLoad(a1)


; ---------------------------------------------------------------------------

PLINTRO	PL_START
	PL_PS	$108b8,AckVBI_R
	PL_ORW	$10892+2,1<<3		; enable level 2 interrupts
	PL_PS	$10a1a,.FlushCache1	; flush cache after copying "Round Vector" code
	PL_PS	$10a36,.FlushCache2	; flush cache after copying vector code
	PL_P	$10a54,Load
	PL_P	$1084c,.PatchMain
	PL_PSS	$110f4,AckLev6_R,2
	PL_PS	$11158,AckLev6_R
	PL_SA	$17ca8,$17cb0		; skip Forbid()
	PL_PSA	$10804,WaitRaster,$1080c
	PL_END

.PatchMain

	; set default copperlist as copper DMA is enabled
	; without a valid copperlist 
	lea	$1000.w,a0
	move.l	a0,$dff080

	lea	PLMAIN(pc),a0
	pea	$55500
	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)


.FlushCache1
	bsr	FlushCache
	jmp	$56800

.FlushCache2
	bsr	FlushCache
	jmp	$60000

; ---------------------------------------------------------------------------

PLMAIN	PL_START
	PL_PSS	$de2,AckLev6_R,2
	PL_PS	$e46,AckLev6_R
	PL_PS	$be,AckVBI_R
	PL_ORW	$6a+2,1<<3		; enable level 2 interrupts
	PL_P	$548,Load

	PL_PSS	$c4,.FixMouse,2
	PL_END


; Only read mouse every other frame as otherwise
; it is impossible to control the menu. This is probably
; related to the hires interlace menu the menu runs in.

.FixMouse
	lea	.delay(pc),a0
	not.b	(a0)
	beq.b	.skip

	jsr	$55500+$228		; read mouse
.skip	jmp	$55500+$368		; fade


.delay	dc.w	0


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

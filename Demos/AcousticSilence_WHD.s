***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(  ACOUSTIC SILENCE/QUADRIGA WHDLOAD SLAVE   )*)---.---.   *
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

; 29-Dec-2020	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem
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
	dc.b	"SOURCES:WHD_Slaves/Demos/Quadriga/AcousticSilence",0
	ENDC

.name	dc.b	"Acoustic Silence",0
.copy	dc.b	"1993 Quadriga",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (29.12.2020)",0
	CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; install level 2 interrupt
	bsr	SetLev2IRQ


	; load intro
	move.l	#1*$1600,d0
	move.l	#2*$1600,d1
	lea	$55000,a0

	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)
	move.l	d5,d0
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$3467,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok
	; decrunch CrunchMania executable
	move.l	a5,a0
	bsr	DecrunchExe


	; patch intro
	lea	PLINTRO(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)	


	; set default interrupts
	pea	AckVBI(pc)
	move.l	(a7)+,$6c.w
	pea	AckLev6(pc)
	move.l	(a7)+,$78.w

	; enable needed DMA channels
	move.w	#$83c0,$dff096


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


FlushCache
	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts


; ---------------------------------------------------------------------------

PLINTRO	PL_START
	PL_P	$86,.PatchMain
	PL_PS	$228,.LoadAndWait
	PL_END

; load main part and display Quadriga logo for at least 2 seconds
.LoadAndWait
	bsr.b	Load
	moveq	#2*10,d0
	move.l	resload(pc),a0
	jmp	resload_Delay(a0)


.PatchMain
	lea	$50000,a0
	bsr	DecrunchExe
	lea	PLMAIN(pc),a0
PatchA5	move.l	a5,-(a7)	
PatchAndRun
	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)



Load	mulu.w	#512*11,d0
	mulu.w	#512*11,d1
	moveq	#1,d2
	move.l	resload(pc),a1
	jmp	resload_DiskLoad(a1)





; ---------------------------------------------------------------------------

PLMAIN	PL_START
	PL_PSS	$83c0,FixDMAWait,2
	PL_PSS	$83d6,FixDMAWait,2
	PL_PSS	$8b10,FixDMAWait,2
	PL_PSS	$8b26,FixDMAWait,2
	PL_P	$92ac,.Load
	PL_P	$fc,.PatchEnd
	PL_ORW	$2e+2,1<<3		; enable level 2 interrupts
	PL_END


.PatchEnd
	lea	$50000,a0
	bsr	DecrunchExe
	lea	PLEND(pc),a0
	bra.w	PatchA5
	

.Load	move.l	a4,a0
	bsr.w	Load
	moveq	#0,d0		; no errors
	rts



; ---------------------------------------------------------------------------

PLEND	PL_START
	PL_PSS	$1c44,FixDMAWait,2
	PL_PSS	$1c5a,FixDMAWait,2
	PL_PSS	$2384,FixDMAWait,2
	PL_PSS	$239a,FixDMAWait,2
	PL_ORW	$2c+2,1<<3		; enable level 2 interrupts
	PL_END

; ---------------------------------------------------------------------------

; Decrunch executable crunched with Crunch Mania's address mode

; a0.l: executable to decrunch
; ----
; a5.l: start of decrunched code

DecrunchExe
	move.l	$28+2(a0),a1		; destination

	; create valid CrunchMania header so data can be
	; decrunched using resload_Decrunch
	add.w	#$148-6,a0		; crunched data starts at offset $148
	
	move.l	#"CrM!",(a0)
	clr.w	4(a0)			; min. security distance (not needed)

	move.l	a1,a5
	move.l	resload(pc),a2
	jmp	resload_Decrunch(a2)


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

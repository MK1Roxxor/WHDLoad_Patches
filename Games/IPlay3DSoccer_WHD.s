***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      I PLAY 3D SOCCER WHDLOAD SLAVE        )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             April 2020                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 12-Apr-2020	- timing fixed

; 05-Apr-2020	- more checksum checks disabled

; 04-Apr-2020	- work started

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
	dc.w	17		; ws_version
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


.config	dc.b	"C1:B:Disable Timing Fix"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/IPlay3DSoccer",0
	ENDC

.name	dc.b	"I Play 3D Soccer",0
.copy	dc.b	"1991 Simulmondo",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.01 (12.04.2020)",0


	CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2


; install level 2 interrupt
	bsr	SetLev2IRQ


; load boot
	move.l	#2*512,d0
	move.l	#$800,d1
	lea	$8000,a0
	move.l	a0,a5
	move.l	d1,d5
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$1B3C,d0		; SPS 2104
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok


; patch
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

	; set default VBI
	pea	AckVBI(pc)
	move.l	(a7)+,$6c.w

	move.l	HEADER+ws_ExpMem(pc),d0
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




PLBOOT	PL_START
	PL_SA	$c,$42			; skip ext. memory check	
	PL_P	$316,Load
	PL_PS	$6e,.Patch1
	PL_P	$1d8,.Patch2
	PL_END


.Patch1	lea	PL1(pc),a0
	pea	$40000
.PatchAndRun
	move.l	(a7),a1
.Patch	move.l	resload(pc),a2
	jmp	resload_Patch(a2)

.Patch2	lea	PLREPLAY(pc),a0
	move.l	$0.w,a1
	add.l	#$28678,a1
	bsr.b	.Patch

	lea	PL2(pc),a0
	pea	$d800
	bra.b	.PatchAndRun


PL1	PL_START
	PL_P	$3b6,.FixVBI
	PL_ORW	$52+2,1<<3		; enable level 2 interrupts
	PL_PSS	$6d0,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$6e8,FixDMAWait,2	; fix DMA wait in replayer
	PL_P	$9b6,FixAudXVol		; fix byte write to volume register
	PL_PSS	$182,.FixDelay4fff,2
	PL_END


.FixDelay4fff
	move.w	#$4fff/($34*5)-1,d0
.loop	bsr	FixDMAWait
	dbf	d0,.loop
	rts

.FixVBI	movem.l	d0-a6,-(a7)
	jsr	$40000+$4c8		; mt_music
	movem.l	(a7)+,d0-a6
	bra.w	AckVBI


PL2	PL_START
	PL_R	$7f6			; disable manual protection

	PL_PSS	$1ef4,.FixDelay7ff,2
	PL_PSS	$1fb0,.FixDelay7ff,2
	PL_P	$1692,.FixDelayffff
	PL_PSS	$206e,.FixDelay4fff,2
	PL_P	$218a,.FixDelayffff_2

	PL_R	$140e			; disable checksum check
	PL_SA	$193e,$1944		; disable checksum check
	PL_R	$1266			; disable checksum check
	PL_B	$7de0,$60
	PL_B	$a22e,60
	PL_B	$a42,$60
	PL_B	$568c,$60
	

	PL_PSS	$6a,SetLev2IRQ,2


	PL_IFC1
	PL_ELSE
	PL_PSS	$38f6,.FixTiming,2
	PL_ENDIF
	
	PL_END


.FixTiming
	;move.w	$dff006,$dff180
	bsr	WaitRaster
	lea	$7868.w,a0
	move.l	$7824.w,a1
	rts


.FixDelay7ff
	move.w	#$7ff/($34*5)-1,d2
.loop	bsr	FixDMAWait
	dbf	d2,.loop
	rts
	
.FixDelayffff
	moveq	#12,d0
.loop1	move.w	#$ffff/($34*5)-1,d1
.loop2	bsr	FixDMAWait
	dbf	d1,.loop2

	btst	#7,$bfe001
	dbeq	d0,.loop1
	rts

.FixDelay4fff
	move.w	#$4fff/($34*5)-1,d0
.loop3	bsr	FixDMAWait
	dbf	d0,.loop3
	rts

.FixDelayffff_2
	move.w	d1,-(a7)
.loop41	move.w	#$ffff/($34*5)-1,d1
.loop4	bsr	FixDMAWait
	dbf	d1,.loop4
	dbf	d0,.loop41
	move.w	(a7)+,d1
	rts


PLREPLAY
	PL_START
	PL_PSS	$298,FixDMAWait,2
	PL_PSS	$2ae,FixDMAWait,2
	PL_P	$570,FixAudXVol
	PL_END


Load	movem.l	d0-a6,-(a7)
	mulu.w	#512,d0
	moveq	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d0-a6
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

FixAudXVol
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
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


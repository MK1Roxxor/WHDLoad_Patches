***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(     LOST SYMPHONY/MYSTIC WHDLOAD SLAVE     )*)---.---.   *
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
;		- and finished a short while later, interrupt fixed,
;		  Bplcon0 color bit fix, DMA settings fixed, ECS/AGA
;		  register access (FMODE, BPLCON3) disabled, ButtonWait
;		  support for loading tune

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
	dc.w	17		; ws_version
	dc.w	FLAGS		; flags
	dc.l	524288*2	; ws_BaseMemSize
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


.config	dc.b	"BW"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Mystic/VisionOfTheArt",0
	ENDC

.name	dc.b	"Lost Symphony",0
.copy	dc.b	"1995 Mystic & Pic Saint Loup",0
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
	lea	$c0000,a0
	move.l	#$c6c00,d0
	move.l	#$9800,d1
	moveq	#1,d2
	move.l	a0,a5
	move.l	d1,d5
	jsr	resload_DiskLoad(a2)
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$2F6B,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

	; patch
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	move.w	#$83c0,$dff096

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

PLBOOT	PL_START
	PL_P	$1376,Load
	PL_P	$60,.PatchMain
	PL_P	$72,AckVBI
	PL_ORW	$7c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$18+2,1<<3		; enable level 2 interrupts

	PL_IFBW
	PL_PSS	$3c,.PlayTune,2		; let tune run if ButtonWait is used
	PL_ENDIF

	PL_END

.PlayTune
	bsr	Load
.LMB	btst	#6,$bfe001
	bne.b	.LMB
	jmp	$c0000+$1346


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
	move.b	DiskNum(pc),d2
	move.l	resload(pc),a1
	jmp	resload_DiskLoad(a1)

DiskNum	dc.b	1
	dc.b	0

; ---------------------------------------------------------------------------

PLMAIN	PL_START
	PL_SA	$1f22,$1f5c		; skip drive access
	PL_PSA	$1f8e,Load,$1fb4
	PL_SA	$1fd0,$2002		; skip drive access
	PL_P	$2002,Load
	PL_ORW	$220ec+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1ff90+2,1<<9		; set Bplcon0 color bit
	PL_P	$2052,.ChangeDisk
	PL_W	$20268+2,$1fe		; Bplcon3 -> NOP
	PL_W	$2023e+2,$1fe		; Bplcon3 -> NOP
	PL_W	$2024a+2,$1fe		; FMODE -> NOP
	PL_W	$20098+2,$1fe		; Bplcon3 -> NOP
	PL_W	$200a4+2,$1fe		; FMODE -> NOP
	
	PL_END

.ChangeDisk
	lea	DiskNum(pc),a0
	eor.b	#%11,(a0)		; 1<->2
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




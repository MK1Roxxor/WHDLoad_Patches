***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    EXTEMPORIZED/DIGITAL WHDLOAD SLAVE      )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                               May 2022                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************


; 22-May-2022	- work started
;		- and finished a while later


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


HEADER	SLAVE_HEADER			; ws_security + ws_ID
	dc.w	17			; ws_version
	dc.w	FLAGS			; flags
	dc.l	$80000			; ws_BaseMemSize
	dc.l	0			; ws_ExecInstall
	dc.w	Patch-HEADER		; ws_GameLoader
	IFD	DEBUG
	dc.w	.dir-HEADER		; ws_CurrentDir
	ELSE
	dc.w	0			; ws_CurrentDir
	ENDC
	dc.w	0			; ws_DontCache
	dc.b	0			; ws_KeyDebug
	dc.b	QUITKEY			; ws_KeyExit
	dc.l	0			; ws_ExpMem
	dc.w	.name-HEADER		; ws_name
	dc.w	.copy-HEADER		; ws_copy
	dc.w	.info-HEADER		; ws_info

; v16
	dc.w	0			; ws_kickname
	dc.l	0			; ws_kicksize
	dc.w	0			; ws_kickcrc

; v17
	dc.w	.config-HEADER		; ws_config


.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Digital/Extemporized",0
	ENDC

.name	dc.b	"Extemporized",0
.copy	dc.b	"1993 Digital",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.1 (22.05.2022)",0

	CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; relocate stack to low memory area
	lea	2000.w,a7
	lea	4096(a7),a0
	move.l	a0,USP


	; load boot code
	move.l	#$200,d0
	move.l	#$4000,d1
	lea	$7c000,a0
	bsr	Disk_Load

	move.l	a0,a5

	; version check
	move.l	a5,a0
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$95A2,d0
	beq.b	.version_ok
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.version_ok


	; patch boot code
	lea	PL_BOOT(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; set default level 3 interrupt (demo enables interrupts
	; before setting up the interrupt vector)
	pea	Acknowledge_All_Level3_Interrupts(pc)
	move.l	(a7)+,$6c.w


	; install level 2 interrupt
	bsr	Init_Level2_Interrupt


	; run the demo
	jmp	(a5)


; ---------------------------------------------------------------------------

PL_BOOT	PL_START
	PL_ORW	$12+2,1<<3		; enable level 2 interrupts
	PL_ORW	$6a+2,1<<3		; enable level 2 interrupts
	PL_P	$1c4,.Load_Data
	PL_P	$656,Acknowledge_Level3_Interrupt
	PL_P	$68e,Acknowledge_Level3_Interrupt
	PL_P	$6b8,Acknowledge_Level3_Interrupt
	PL_P	$6ea,Acknowledge_Level3_Interrupt
	PL_P	$156,.Patch_Main
	PL_W	$628,$1fe		; BPLCON3 -> NOP
	PL_W	$62c,$1fe		; FMODE -> NOP
	PL_W	$630,$1fe		; BPLCON4 -> NOP
	PL_W	$598,$1fe		; FMODE -> NOP
	PL_W	$5a4,$1fe		; BPLCON3 -> NOP
	PL_W	$5ac,$1fe		; BPLCON4 -> NOP
	PL_END

.Patch_Main
	lea	PL_MAIN(pc),a0
	lea	$3fc8c,a1
	bsr	Apply_Patches
	jmp	$4505a

.Load_Data
	move.l	$7c000+$74c,a0
Load_Data
	move.w	d2,d0
	move.w	d3,d1
	mulu.w	#512*11,d0
	mulu.w	#512*11,d1
	bra.w	Disk_Load

; ---------------------------------------------------------------------------

PL_MAIN	PL_START
	PL_PS	$2b80e,Acknowledge_Level6_Interrupt
	PL_ORW	$541a+2,1<<3		; enable level 2 interrupts
	PL_P	$84d2,Acknowledge_Level3_Interrupt
	PL_ORW	$73c2+2,1<<3		; enable level 2 interrupts
	PL_P	$7446,Acknowledge_Level3_Interrupt
	PL_P	$74a0,Acknowledge_Level3_Interrupt
	PL_W	$800c,$1fe		; BPLCON3 -> NOP
	PL_W	$8010,$1fe		; FMODE -> NOP
	PL_W	$80bc,$1fe		; BPLCON3 -> NOP
	PL_W	$80c0,$1fe		; FMODE -> NOP
	PL_P	$824a,.Load_Data
	PL_W	$5746,$1fe		; BPLCON3 -> NOP
	PL_W	$574a,$1fe		; FMODE -> NOP
	PL_W	$574e,$1fe		; BPLCON4 -> NOP
	PL_W	$578a,$1fe		; BPLCON3 -> NOP
	PL_W	$578e,$1fe		; FMODE -> NOP
	PL_W	$5792,$1fe		; BPLCON4 -> NOP
	PL_W	$5f90,$1fe		; BPLCON3 -> NOP
	PL_W	$5f94,$1fe		; FMODE -> NOP
	PL_W	$5f98,$1fe		; BPLCON4 -> NOP
	PL_END

.Load_Data
	move.l	$3fc8c+$84f0,a0
	bra.w	Load_Data
	
; ---------------------------------------------------------------------------


Acknowledge_All_Level3_Interrupts
	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte	


Acknowledge_Level3_Interrupt
	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rte

Acknowledge_Level6_Interrupt
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rts

; ---------------------------------------------------------------------------
; Support/helper routines.


QUIT	pea	(TDREASON_OK).w
EXIT	bsr.b	KillSys
	move.l	resload(pc),a2
	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

KillSys	move.w	#$7fff,$dff09a
	bsr.b	WaitRaster
	move.w	#$7fff,$dff09c
	move.w	#$7ff,$dff096
	rts


WaitRaster
.wait1	btst	#0,$dff005
	beq.b	.wait1
.wait2	btst	#0,$dff005
	bne.b	.wait2
	rts


; ---------------------------------------------------------------------------

; d0.l: offset (bytes)
; d1.l: length (bytes)
; a0.l: destination

Disk_Load
	movem.l	d0-a6,-(a7)
	moveq	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d0-a6
	rts

; ---------------------------------------------------------------------------

Check_Quit_Key
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	rts


; ---------------------------------------------------------------------------

; a0.l: patch list
; a1.l: destination

Apply_Patches
	movem.l	d0-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts

; ---------------------------------------------------------------------------
; Level 2 interrupt used to handle keyboard events.

Init_Level2_Interrupt
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
	moveq	#0,d0
	move.b	$bfec01-$bfe001(a1),d0
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)+
	or.b	#1<<6,$e00(a1)			; set output mode

	bsr.w	Check_Quit_Key

	move.l	(a2)+,d1
	beq.b	.nocustom
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.nocustom
	

.nokeys	moveq	#3-1,d1
.loop	move.b	$6(a0),d0
.wait	cmp.b	$6(a0),d0
	beq.b	.wait
	dbf	d1,.loop


	and.b	#~(1<<6),$e00(a1)		; set input mode
.end	move.w	#1<<3,$9c(a0)
	move.w	#1<<3,$9c(a0)			; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte



Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0				; ptr to custom routine


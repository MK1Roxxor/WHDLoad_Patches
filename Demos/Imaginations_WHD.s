***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(     IMAGINATIONS/DEFIANCE WHDLOAD SLAVE    )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            December 2023                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************


; 30-Dec-2023	- work started
;		- and finished 38 minutes later: OS stuff patched, DMA
;		  wait in replayer fixed (x4), DMA and interrupt settings
;		  fixed, wrong blitter waits fixed (x8), blitter wait added


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Hardware/dmabits.i
	INCLUDE	hardware/intbits.i
	INCLUDE	hardware/custom.i
	IFND	_custom
_custom	= $dff000
	ENDC
	INCLUDE	hardware/cia.i
	IFND	_ciaa
_ciaa	= $bfe001
	ENDC

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
	dc.w	.dir-HEADER		; ws_CurrentDir
	dc.w	0			; ws_DontCache
	dc.b	0			; ws_KeyDebug
	dc.b	QUITKEY			; ws_KeyExit
	dc.l	0			; ws_ExpMem
	dc.w	.name-HEADER		; ws_name
	dc.w	.copy-HEADER		; ws_copy
	dc.w	.info-HEADER		; ws_info
	dc.w	0			; ws_kickname
	dc.l	0			; ws_kicksize
	dc.w	0			; ws_kickcrc
	dc.w	.config-HEADER		; ws_config


.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Defiance/Imaginations/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Imaginations",0
.copy	dc.b	"1994 Defiance",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.00 (30.12.2023)",0

File_Name	dc.b	"Imaginations",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load demo code
	lea	File_Name(pc),a0
	lea	$2000.w,a1
	bsr	Load_File

	move.l	a1,a5

	
	; Version check
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$ee37,d0
	beq.b	.Version_is_Supported

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
.Version_is_Supported


	; Relocate demo code
	move.l	a5,a0
	sub.l	a1,a1			; no tags
	jsr	resload_Relocate(a2)


	; Patch demo code
	lea	PL_MAIN(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches


	; Set default level 3 interrupt
	pea	Acknowledge_Level3_Interrupt(pc)
	move.l	(a7)+,$6c.w

	; Enable required DMA channels
	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_RASTER|DMAF_COPPER|DMAF_BLITTER,_custom+dmacon

	; Enable vertical blank interrupt
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_VERTB,_custom+intena

	; Run demo
	jmp	(a5)


; ---------------------------------------------------------------------------

PL_MAIN	PL_START
	PL_SA	0,$8			; skip Forbid()
	PL_SA	$326,$346		; skip graphics.library stuff
	PL_P	$c36,.Load_Tune

	; fix CPU dependent DMA waits in replayer
	PL_PSS	$2dfee,Fix_DMA_Wait,2
	PL_PSS	$2e004,Fix_DMA_Wait,2
	PL_PSS	$2e72e,Fix_DMA_Wait,2
	PL_PSS	$2e744,Fix_DMA_Wait,2

	PL_SA	$3b2,$3ca		; skip rasterline wait in level 3 interrupt

	; fix wrong blitter waits (btst #6,$dff006 -> btst #6,$dff002)
	PL_L	$525a+4,_custom+dmaconr
	PL_L	$528a+4,_custom+dmaconr
	PL_L	$52ba+4,_custom+dmaconr
	PL_L	$52ea+4,_custom+dmaconr
	PL_L	$531a+4,_custom+dmaconr
	PL_L	$534a+4,_custom+dmaconr
	PL_L	$537a+4,_custom+dmaconr
	PL_L	$53aa+4,_custom+dmaconr

	PL_PSS	$a654,.Wait_Blit_8000_dff072,4
	PL_END

.Wait_Blit_8000_dff072
	bsr	Wait_Blit
	move.w	#$8000,$dff072
	rts


; a4.l: file name (with preceding "df0:")
; a5.l: destination
; d4.l: file size

.Load_Tune
	lea	4(a4),a0
	move.l	a5,a1
	bra.w	Load_File

; ---------------------------------------------------------------------------
; Support/helper routines.


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)


KillSys	move.w	#$7fff,$dff09a
	bsr.b	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	rts


WaitRaster
.wait1	btst	#0,_custom+vposr+1
	beq.b	.wait1
.wait2	btst	#0,_custom+vposr+1
	bne.b	.wait2
	rts


Fix_DMA_Wait
	moveq	#8,d0

; d0.w: number of raster lines to wait
Wait_Raster_Lines
	move.w	d1,-(a7)
.loop	move.b	_custom+vhposr,d1
.still_in_same_raster_line
	cmp.b	_custom+vhposr,d1
	beq.b	.still_in_same_raster_line	
	subq.w	#1,d0
	bne.b	.loop
	move.w	(a7)+,d1
	rts


Wait_Blit
	tst.b	_custom+dmaconr
.blitter_is_busy
	btst	#DMAB_BLITTER,_custom+dmaconr
	bne.b	.blitter_is_busy
	rts

; ---------------------------------------------------------------------------

Acknowledge_Level3_Interrupt
	move.w	#INTF_BLIT|INTF_COPER|INTF_VERTB,_custom+intreq
	move.w	#INTF_BLIT|INTF_COPER|INTF_VERTB,_custom+intreq
	rte

; ---------------------------------------------------------------------------

; a0.l: file name
; a1.l: destination
; -----
; d0.l: file size

Load_File
	movem.l	d1-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_LoadFileDecrunch(a2)
	movem.l	(a7)+,d1-a6
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

; d0.b: rawkey code

Check_Quit_Key
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	rts	

Enable_Keyboard_Interrupt
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,_custom+intena
	rts

; Level 2 interrupt used to handle keyboard events.

Init_Level2_Interrupt
	pea	.int(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode


	move.w	#INTF_PORTS,_custom+intreq	; clear ports interrupt
	bra.w	Enable_Keyboard_Interrupt

.int	movem.l	d0-d1/a0-a2,-(a7)
	lea	_custom,a0
	lea	_ciaa,a1

	btst	#INTB_PORTS,intreqr+1(a0)
	beq.b	.end

	btst	#CIAICRB_SP,ciaicr(a1)
	beq.b	.end

	lea	Key(pc),a2
	moveq	#0,d0
	move.b	ciasdr(a1),d0
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)+
	or.b	#CIACRAF_SPMODE,ciacra(a1)	; set output mode

	bsr.b	Check_Quit_Key

	move.l	(a2)+,d1
	beq.b	.no_keyboard_custom_routine
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.no_keyboard_custom_routine
	
	moveq	#3,d0
	bsr	Wait_Raster_Lines

	and.b	#~CIACRAF_SPMODE,ciacra(a1)	; set input mode
.end	move.w	#INTF_PORTS,intreq(a0)
	move.w	#INTF_PORTS,intreq(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte



Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine

; ---------------------------------------------------------------------------


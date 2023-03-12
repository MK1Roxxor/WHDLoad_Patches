***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   MIND OF TRACES/SHINING 8 WHDLOAD SLAVE   )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             March 2023                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 12-Mar-2023	- shadebob problem fixed (skipped too much code at the
;		  beginning so the screen was not cleared)
;		- SMC fixed
;		- interrupt fixed
;		- patch is finished

; 11-Mar-2023	- work started
;		- code patched, shadebobs do not look correct though


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Hardware/dmabits.i
	INCLUDE	hardware/intbits.i


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


HEADER	SLAVE_HEADER			; ws_security + ws_ID
	dc.w	17			; ws_version
	dc.w	FLAGS			; flags
	dc.l	$80000			; ws_BaseMemSize
	dc.l	0			; ws_ExecInstall
	dc.w	Patch-HEADER		; ws_GameLoader
	dc.w	0			; ws_CurrentDir
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

.name	dc.b	"Mind of Traces",0
.copy	dc.b	"1992 Shining 8",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.00 (12.03.2023)",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; relocate stack to low memory
	lea	$2000.w,a7

	; Load demo code
	move.l	#$aa800,d0
	move.l	#$29400,d1
	pea	$56bf0
	move.l	(a7),a0
	bsr	Disk_Load
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$f4e1,d0
	beq.b	.Version_is_Supported

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.Version_is_Supported

	; Install default level 3 interrupt
	pea	Acknowledge_Level3_Interrupt(pc)
	move.l	(a7)+,$6c.w

	; Enable required DMA channels
	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,$dff096

	; Decrunch demo code, patch it and run the demo
	move.l	(a7)+,a0
	pea	PL_MAIN(pc)
	bra.w	Patch_And_Run_Packed_Part


; ---------------------------------------------------------------------------
; Patch a TetraPack 2.1 executable and run code after decrunching

; a0.l: start of TetraPack 2.1 executable
; (a7): patch list to apply

Patch_And_Run_Packed_Part
	bsr	Decrunch_TetraPack_Executable
	move.l	(a7)+,a0
	move.l	a1,-(a7)
	bra.w	Apply_Patches

; ---------------------------------------------------------------------------

PL_MAIN	PL_START
	PL_SA	$0,$a			; skip Forbid()
	PL_SA	$108,$110		; skip loader initialisation
	PL_P	$960,.Load_Data
	PL_PSS	$1e8,Set_LOF_Bit,2	; fix read from VPOSW
	PL_PSS	$3842,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PSS	$3858,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PSS	$3f82,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PSS	$3f98,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PS	$19c,.Decrunch_Picture
	PL_SA	$4a,$54			; don't modify level 3 interrupt code
	PL_P	$356e,Acknowledge_Level3_Interrupt
	PL_END

.Decrunch_Picture
	lea	$10000+$36288,a0
	bra.w	Decrunch_TetraPack_Executable

.Load_Data
	movem.w	$10000+$111e,d0/d1
	sub.w	d0,d1
	mulu.w	#512*11*2,d0
	mulu.w	#512*11*2,d1
	lea	$10000+$36288,a0
	bra.w	Disk_Load
	

Set_LOF_Bit
	move.w	#1<<15,$dff02a		; VPOSW
	rts



; ---------------------------------------------------------------------------
; Support/helper routines.


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)


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



Fix_DMA_Wait
	moveq	#8,d0

; d0.w: number of raster lines to wait
Wait_Raster_Lines
	move.w	d1,-(a7)
.loop	move.b	$dff006,d1
.still_in_same_raster_line
	cmp.b	$dff006,d1
	beq.b	.still_in_same_raster_line	
	subq.w	#1,d0
	bne.b	.loop
	move.w	(a7)+,d1
	rts


Acknowledge_Level3_Interrupt
	move.w	#INTF_COPER|INTF_VERTB|INTF_BLIT,$dff09c
	move.w	#INTF_COPER|INTF_VERTB|INTF_BLIT,$dff09c
	rte	


Wait_Blit
	tst.b	$dff002
.wait_blit
	btst	#6,$dff002
	bne.b	.wait_blit
	rts

; ---------------------------------------------------------------------------

; d0.l: offset
; d1.l: size
; a0.l: destination

Disk_Load
	movem.l	d0-a6,-(a7)
	moveq	#1,d2			; disk number
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d0-a6
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

	bsr.b	Check_Quit_Key

	move.l	(a2)+,d1
	beq.b	.nocustom
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.nocustom
	
	moveq	#3,d0
	bsr	Wait_Raster_Lines

	and.b	#~(1<<6),$e00(a1)	; set input mode
.end	move.w	#1<<3,$9c(a0)
	move.w	#1<<3,$9c(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte



Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine

; ---------------------------------------------------------------------------
; TetraPack 2.1 decruncher
;
; a0.l: TetraPack 2.1 executable
; ----
; a1.l: start of decrunched data

Decrunch_TetraPack_Executable
	move.l	a0,a4

	lea	$108(a4),a0		; start of crunched data
	add.l	$2c+2(a4),a0		; end of crunched dat
	move.l	$32+2(a4),a1

	moveq	#0,d7
	;lea	$DFF182,a5
	lea	$dff1bc,a5
	move.l	-(a0),a2
	add.l	a1,a2
	move.l	-(a0),d0
lbC00003E
	lsr.l	#1,d0
	bne.b	lbC000044
	bsr.b	lbC000078
lbC000044
	bcs.b	lbC0000B0
	moveq	#8,d1
	moveq	#1,d3
	lsr.l	#1,d0
	bne.b	lbC000050
	bsr.b	lbC000078
lbC000050
	bcs.b	lbC00008E
	moveq	#3,d1
	moveq	#0,d4
lbC000056
	bsr.b	lbC00009E
	move.w	d2,d3
	add.w	d4,d3
lbC00005C
	moveq	#7,d1
lbC00005E
	lsr.l	#1,d0
	bne.b	lbC000064
	bsr.b	lbC000078
lbC000064
	addx.l	d2,d2
	dbf	d1,lbC00005E
	move.b	d2,-(a2)
	dbf	d3,lbC00005C
	bra.b	lbC000098

lbC000072
	moveq	#7,d1
	moveq	#8,d4
	bra.b	lbC000056

lbC000078
	move.l	-(a0),d0
	move.b	d0,d7
	move.w	d7,(a5)
	move.w	#$10,ccr
	roxr.l	#1,d0
	rts

lbC000086
	moveq	#9,d1
	move.w	d2,d3
	add.w	d2,d1
	addq.w	#2,d3
lbC00008E
	bsr.b	lbC00009E
lbC000090
	move.b	-1(a2,d2.w),-(a2)
	dbf	d3,lbC000090
lbC000098
	cmp.l	a2,a1
	blt.b	lbC00003E
	bra.b	lbC0000D6

lbC00009E
	subq.w	#1,d1
	moveq	#0,d2
lbC0000A2
	lsr.l	#1,d0
	bne.b	lbC0000A8
	bsr.b	lbC000078
lbC0000A8
	addx.l	d2,d2
	dbf	d1,lbC0000A2
	rts

lbC0000B0
	moveq	#2,d1
	bsr.b	lbC00009E
	cmp.b	#2,d2
	blt.b	lbC000086
	cmp.b	#3,d2
	beq.b	lbC000072
	moveq	#8,d1
	bsr.b	lbC00009E
	move.w	d2,d3
	addq.w	#4,d3
	;moveq	#10,d1
	moveq	#0,d1
	move.b	$c8+1(a4),d1
	bra.b	lbC00008E


lbC0000D6
	move.b	$d6+1(a4),d7		; RLE byte
	move.l	$d8+2(a4),a0		; RLE destination, start
	move.l	$de+2(a4),a2		; RLE destination, end

lbC0000E4
	move.b	(a1)+,d0
	cmp.b	d7,d0
	bne.b	lbC0000FA
	moveq	#0,d1
	move.b	(a1)+,d1
	beq.b	lbC0000FA
	move.b	(a1)+,d0
	addq.w	#1,d1
lbC0000F4
	move.b	d0,(a0)+
	dbf	d1,lbC0000F4
lbC0000FA
	move.w	d0,(a5)
	move.b	d0,(a0)+
	cmp.l	a2,a1
	blt.b	lbC0000E4


	move.l	$d8+2(a4),a1		; RLE destination, start
	rts

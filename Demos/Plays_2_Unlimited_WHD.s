***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(  SCOOPEX PLAYS 2 UNLIMITED WHDLOAD SLAVE   )*)---.---.   *
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

; 29-May-2022	- level 3 interrupt is now disabled when loading data, this
;		  fixes the "bad stack pointer on entering WHDLoad" problem
;		  that occurs on some systems (issue #5660)

; 26-May-2022	- work started
;		- and finished a while later, Bplcon0 color bit fixes (x9),
;		  DMA wait in replayer fixed (x4), blitter waits added (x3),
;		  access fault in decruncher fixed, NTSC support, 68000
;		  quitkey support


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
	dc.b	"SOURCES:WHD_Slaves/Demos/Scoopex/Plays_2_Unlimited",0
	ENDC

.name	dc.b	"Scoopex Plays 2 Unlimited",0
.copy	dc.b	"1993 Scoopex",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.1A (29.05.2022)",0

	CNOP	0,4


TAGLIST		dc.l	WHDLTAG_MONITOR_GET
MONITOR_ID	dc.l	0
		dc.l	TAG_DONE

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load bootblock
	moveq	#1,d0
	bsr	Set_Disk_Number

	lea	$200.w,a0
	moveq	#0,d0
	move.l	#$400,d1
	bsr	Disk_Load


	move.l	a0,a5

	; Version check
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$8221,d0
	beq.b	.Is_Supported_Version

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.Is_Supported_Version

	; Patch bootblock
	lea	PL_BOOT(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; Run demo
	jmp	3*4(a5)


; ---------------------------------------------------------------------------

PL_BOOT	PL_START
	PL_SA	$24e,$25e		; don't open graphics.library
	PL_PSA	$262,Determine_Video_Mode,$276
	PL_R	$226			; don't patch exception vectors
	PL_B	$3e8,$60		; code is already at correct location
	PL_P	$64,.Load_Data
	PL_PS	$322,.Patch_Title
	PL_PS	$384,.Patch_Intro
	PL_PS	$354,.Patch_Main
	PL_PSS	$1dc,.Fix_Access_Fault,2
	PL_END


; The decruncher accesses memory outside the 512 K boundary when
; decrunching the "Workaholic" tune, this patch fixes this problem.
.Fix_Access_Fault
	clr.w	d0
	cmp.l	#$80000,a0
	bhs.b	.out
	move.b	(a0),d0
	lsl.w	#8,d0

	sf	d0
	addq.w	#1,a0
	cmp.l	#$80000,a0
	bhs.b	.out
	move.b	(a0),d0
	subq.w	#1,a0
.out	rts



.Load_Data
	mulu.w	#512*11,d0
	mulu.w	#512*11,d1
	bsr	Disk_Load
	moveq	#0,d0			; no errors
	rts

.Patch_Title
	move.l	a0,a1
	lea	PL_TITLE(pc),a0
	bra.w	Apply_Patches

.Patch_Intro
	move.l	a0,a1
	lea	PL_INTRO(pc),a0
	bra.w	Apply_Patches
	
.Patch_Main
	move.l	a0,a1
	lea	PL_MAIN(pc),a0
	bra.w	Apply_Patches



Determine_Video_Mode
	move.l	MONITOR_ID(pc),d0
	cmp.l	#NTSC_MONITOR_ID,d0
	beq.b	.is_NTSC
	bset	#1,(a2)
.is_NTSC
	rts


; ---------------------------------------------------------------------------

PL_TITLE
	PL_START
	PL_ORW	$ee+2,1<<3		; enable level 2 interrupts
	PL_ORW	$1a+2,1<<9		; set Bplcon0 color bit
	PL_END


; ---------------------------------------------------------------------------

PL_INTRO
	PL_START
	PL_ORW	$5630+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$4088,.Wait_Blit,2
	PL_PS	$30e,.Wait_Blit_Dff000_A6
	PL_PS	$4038,.Wait_Blit2
	PL_ORW	$1fa+2,1<<3		; enable level 2 interrupts
	PL_END


.Wait_Blit
	bsr	Wait_Blit
	add.l	$8000+$413a,a0
	move.l	a0,$50(a6)
	rts

.Wait_Blit2
	bsr	Wait_Blit
	add.l	#$8000+$5844,d0
	rts

.Wait_Blit_Dff000_A6
	lea	$dff000,a6
	bra.w	Wait_Blit

; ---------------------------------------------------------------------------

PL_MAIN	PL_START
	PL_ORW	$157e+2,1<<9		: set Bplcon0 color bit
	PL_ORW	$1636+2,1<<9		: set Bplcon0 color bit
	PL_ORW	$1682+2,1<<9		: set Bplcon0 color bit
	PL_ORW	$16a2+2,1<<9		: set Bplcon0 color bit
	PL_ORW	$16e2+2,1<<9		: set Bplcon0 color bit
	PL_ORW	$172a+2,1<<9		: set Bplcon0 color bit
	PL_ORW	$174e+2,1<<9		: set Bplcon0 color bit

	; Fix DMA waits in replayer
	PL_PSS	$f20,Fix_DMA_Wait,2
	PL_PSS	$f36,Fix_DMA_Wait,2
	PL_PSS	$135c,Fix_DMA_Wait,2
	PL_PSS	$1372,Fix_DMA_Wait,2

	PL_P	$4fa,.Set_Disk_Number

	PL_PSS	$38,.Set_Keyboard_Custom_Routine,2
	PL_END

.Set_Keyboard_Custom_Routine
	pea	.Store_Key(pc)
	lea	KbdCust(pc),a0
	move.l	(a7)+,(a0)
	rts

.Store_Key
	move.b	RawKey(pc),d0
	btst	#7,d0
	bne.b	.no_key_store
	tst.b	$5f2+$3ec.w
	bne.b	.no_key_store
	move.b	d0,$5f2+$3ec.w
.no_key_store
	rts



.Set_Disk_Number
	moveq	#1,d0
	tst.w	d1
	beq.b	.Set_Disk_1
	moveq	#2,d0
.Set_Disk_1
	bra.w	Set_Disk_Number


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
	move.l	d0,-(a7)
	moveq	#5,d0
	bsr.b	Wait_Raster_Lines
	move.l	(a7)+,d0
	rts

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


; ---------------------------------------------------------------------------

Disk_Load
	movem.l	d0-a6,-(a7)
	move.w	#1<<5,$dff09a
	move.b	Disk_Number(pc),d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	move.w	#1<<15|1<<5,$dff09a
	movem.l	(a7)+,d0-a6
	rts

Set_Disk_Number
	move.l	a0,-(a7)
	lea	Disk_Number(pc),a0
	move.b	d0,(a0)
	move.l	(a7)+,a0
	rts

Disk_Number	dc.b	0
		dc.b	0


; ---------------------------------------------------------------------------

; a0.l: patch list
; a1.l: destination

Apply_Patches
	movem.l	d0-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts


Wait_Blit
	tst.b	$dff002
.blitter_still_busy
	btst	#6,$dff002
	bne.b	.blitter_still_busy
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


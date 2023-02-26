***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   SCOOPEX MELODIES/SCOOPEX WHDLOAD SLAVE   )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            February 2023                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 26-Feb-2023	- StoneCracker decruncher is now relocated to ExpMem,
;		  the code is not copied to a buffer in the slave anymore,
;		  this reduces the slave size
;		- 68000 quitkey support for all parts
;		- disk request text disabled
;		- patch is finished

; 25-Feb-2023	- slideshow part now also work from main menu (disk ID
;		  check had to be disabled and loader patch needed to be
;		  adapted)
;		- blitter wait added
;		- StoneCracker decruncher relocated

; 24-Feb-2023	- slideshow part patched, it can also be run when using
;		  CUSTOM1

; 23-Feb-2023	- loader patch for main part corrected (register d0 was
;		  trashed when setting the disk ID)
;		- copperlist 1 set to start copperlist 2, white screen
;		  problem fixed, first boot picture is now visible as well

; 22-Feb-2023	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	hardware/intbits.i


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
	dc.w	0
	ENDC
	dc.w	0			; ws_DontCache
	dc.b	0			; ws_KeyDebug
	dc.b	QUITKEY			; ws_KeyExit
	dc.l	$80000			; ws_ExpMem
	dc.w	.name-HEADER		; ws_name
	dc.w	.copy-HEADER		; ws_copy
	dc.w	.info-HEADER		; ws_info

; v16
	dc.w	0			; ws_kickname
	dc.l	0			; ws_kicksize
	dc.w	0			; ws_kickcrc

; v17
	dc.w	.config-HEADER		; ws_config


.config	dc.b	"C1:B:Boot Disk 3 (Slideshow)"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Scoopex/ScoopexMelodies",0
	ENDC

.name	dc.b	"Scoopex Melodies",0
.copy	dc.b	"1994 Scoopex",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.2 (26.02.2023)",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	moveq	#1,d0
	bsr	Set_Disk_Number

	; Load boot code
	moveq	#0,d0
	move.l	#$400,d1
	lea	$70000-$28,a0
	bsr	Disk_Load

	move.l	a0,a5

	; Version check
	move.l	a5,a0
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$81cc,d0
	beq.b	.Version_is_Supported

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.Version_is_Supported

	; Patch boot code
	lea	PL_BOOT(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; Create default copperlist 1 that starts copperlist 2
	lea	$1000.w,a0
	move.l	a0,$dff080
	move.l	a0,$dff084
	move.l	#$008a0000,(a0)
	

	; And run the demo
	jmp	$28(a5)
	

; ---------------------------------------------------------------------------

PL_BOOT	PL_START
	PL_PSA	$32,.Set_Extended_Memory,$8a
	PL_SA	$c4,$c8		; skip write to FMODE
	PL_R	$1a0		; disable drive access (drive ready wait)
	PL_R	$1c2		; disable drive access (step to track 0)
	PL_R	$1d4		; disable drive access (step to track)
	PL_PSA	$118,Load_Data,$146
	PL_PS	$14a,.Patch_Title_Load
	PL_IFC1
	PL_P	$32,.Run_Slideshow
	PL_ENDIF
	PL_SA	$e8,$ee		; don't disable CIA interrupts
	PL_END

.Patch_Title_Load
	move.l	HEADER+ws_ExpMem(pc),a0
	lea	$10000+$4f0,a1
	move.w	#($614-$4f0)/2-1,d7
.copy_decruncher_code
	move.w	(a1)+,(a0)+
	dbf	d7,.copy_decruncher_code
	
	lea	$7ff00,a3
	lea	PL_TITLE_LOAD(pc),a0
	lea	$10000,a1
	bra.w	Apply_Patches

.Set_Extended_Memory
	move.l	HEADER+ws_ExpMem(pc),d1
	add.l	#4096,d1	; StoneCracker decruncher is copied to the
				; start of expansion memory
	rts

.Run_Slideshow
	moveq	#3,d0
	bsr	Set_Disk_Number
	
	moveq	#3,d0
	moveq	#$27,d3
	lea	$20000,a6
	bsr.b	Load_Data

Patch_And_Run_Slideshow
	lea	PL_SLIDESHOW(pc),a0
	move.l	a6,a1
	bsr	Apply_Patches
	jmp	(a6)


Load_Data
	mulu.w	#512*11,d0
	move.w	d3,d1
	addq.w	#1,d1
	mulu.w	#512*11,d1
	move.l	a6,a0
	bra.w	Disk_Load


; ---------------------------------------------------------------------------

PL_SLIDESHOW
	PL_START
	PL_PS	$1c6,.Fix_Copperlist
	PL_W	$8c4+2,$01fe		; copper NOP instead of 0
	PL_ORW	$200+2,INTF_PORTS	; enable level 2 interrupts
	PL_END
	

.Fix_Copperlist
	lea	$20000+$1084,a0
	lea	$20000+$10e4,a1
	bsr.b	Fix_Copper

	lea	$dff000,a5
	rts


Fix_Copper
.loop	move.w	#$01fe,(a0)		; set copper NOP
	addq.w	#4,a0
	cmp.l	a0,a1
	bne.b	.loop
	rts

; ---------------------------------------------------------------------------

PL_TITLE_LOAD
	PL_START
	PL_SA	$1c6,$1ce
	PL_R	$286			; disable drive access (step to track)
	PL_PSA	$1dc,Load_Data,$21e
	PL_PS	$f0,.Patch_Title
	PL_P	$4f0,Decrunch_StoneCracker403
	PL_ORW	$16e+2,INTF_PORTS	; enable level 2 interrupts
	PL_R	$3de			; don't disable CIA interrupts
	PL_END

.Patch_Title
	move.l	a1,-(a7)
	lea	PL_TITLE(pc),a0
	move.l	$10000+$126,a1
	bsr	Apply_Patches
	move.l	a1,a0
	move.l	(a7)+,a1
	rts

Decrunch_StoneCracker403
	move.l	HEADER+ws_ExpMem(pc),-(a7)
	rts


; ---------------------------------------------------------------------------

PL_TITLE
	PL_START
	PL_SA	$9cc,$9d4
	PL_SA	$9da,$9de
	PL_PSA	$9e2,Load_Data,$a24
	PL_PSS	$124e,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PSS	$1264,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PSS	$198e,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PSS	$19a4,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PS	$d5e,.Fix_Line_Draw
	PL_PS	$4d4,.Patch_Main_Part
	PL_P	$20b4,Decrunch_StoneCracker403
	PL_ORW	$8b6+2,INTF_PORTS	; enable level 2 interrupts
	PL_END

.Fix_Line_Draw
	move.l	a0,-(a7)
	lea	$38000+$cf6,a0
	move.b	(a0,d4.w),d4
	and.w	#$ff,d4
	move.w	d4,$42(a5)
	move.l	(a7)+,a0
	rts

.Patch_Main_Part
	lea	$5000+$28da,a0
	lea	$5000+$297a,a1
	bsr	Fix_Copper
	lea	$5000+$27ce,a0
	lea	$5000+$280e,a1
	bsr	Fix_Copper

	lea	PL_MAIN(pc),a0
	move.l	$38000+$4e4,a1
	bsr	Apply_Patches
	move.l	a1,a0
	rts

; ---------------------------------------------------------------------------

PL_MAIN	PL_START
	PL_SA	$7de,$7e6
	PL_SA	$7ec,$7f0
	PL_P	$7f4,.Load_Data
	PL_PS	$cc0,.Fix_Line_Draw
	PL_P	$276,.Patch_Slideshow
	PL_R	$1022			; disable disk ID check
	PL_R	$9f2			; don't disable CIA interrupts
	PL_ORW	$2b6+2,INTF_PORTS	; enable level 2 interrupts
	PL_P	$1572,.Wait_Blit
	PL_P	$10b0,Decrunch_StoneCracker403
	PL_SA	$4f8,$520		; skip "Insert Disk" text
	PL_SA	$636,$65e		; skip "Insert Disk" text
	PL_END

.Wait_Blit
	move.w	#$1914,$58(a5)
	bra.w	Wait_Blit

.Patch_Slideshow
	lea	$20000,a6
	bra.w	Patch_And_Run_Slideshow

.Load_Data
	move.l	$5000+$746,a1		; file table pointer
	move.l	d0,d1
	move.l	(a1),d0			; disk number

	cmp.l	#3,$5000+$a10
	bne.b	.Set_Set_Number_From_File_Table

	; Slideshow does not use the file table
	moveq	#3,d0
.Set_Set_Number_From_File_Table
	bsr	Set_Disk_Number
	move.l	d1,d0
	bra.w	Load_Data


.Fix_Line_Draw
	move.l	a0,-(a7)
	lea	$5000+$c52,a0
	move.b	(a0,d4.w),d4
	and.w	#$ff,d4
	move.w	d4,$42(a5)
	move.l	(a7)+,a0
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

Wait_Blit
	tst.b	$dff002
.wait_blit
	btst	#6,$dff002
	bne.b	.wait_blit
	rts
; ---------------------------------------------------------------------------

; d0.b: disk number

Set_Disk_Number
	move.l	a0,-(a7)
	lea	Disk_Number(pc),a0
	move.b	d0,(a0)
	move.l	(a7)+,a0
	rts

; d0.l: offset
; d1.l: size
; a0.l: destination

Disk_Load
	movem.l	d0-a6,-(a7)
	move.b	Disk_Number(pc),d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d0-a6
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


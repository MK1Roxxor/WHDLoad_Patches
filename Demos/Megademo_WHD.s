***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       SARGON MEGADEMO WHDLOAD SLAVE        )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              April 2022                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 16-Apr-2022	- remaining parts patched
;		- graphics problems in loader part fixed (caused by
;		  using the decrunched binaries, fixed by loading the
;		  next part later than in the original demo)
;		- patch is finished

; 15-Apr-2022	- work started
;		- imager coded, loader part and first 2 demo parts patched


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

MAX_PARTS	= 7

	
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

; v16
	dc.w	0			; ws_kickname
	dc.l	0			; ws_kicksize
	dc.w	0			; ws_kickcrc

; v17
	dc.w	.config-HEADER		; ws_config


.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Sargon/Megademo/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Megademo",0
.copy	dc.b	"1989 Sargon",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (16.04.2022)",0

File_Name	dc.b	"Sargon_Megademo_Part_"
File_Number	dc.b	"0",0
	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Relocate stack to low memory
	lea	$2000.w,a0
	move.l	a0,a7
	sub.w	#1024,a0
	move.l	a0,USP

	bsr	Load_Part

	; Enable needed DMA and interrupts
	move.w	#$83c0,$dff096
	bsr	Set_Default_Level3_Interrupt
	move.w	#$c028,$dff09a

	jmp	(a5)


; --------------------------------------------------------------------------

Load_Part
	lea	File_Name(pc),a0
	move.w	Part_Number(pc),d0
	move.w	d0,d1
	add.b	#"0",d1
	move.b	d1,File_Number-File_Name(a0)

	lsl.w	#4,d0
	lea	Part_Table(pc,d0.w),a2
	move.l	(a2)+,a1		; destination address
	bsr	Load_File
	move.l	(a2)+,a5		; jump address
	move.l	(a2)+,d7
	beq.b	.no_checksum_check
	move.l	a1,-(a7)
	move.l	a1,a0
	move.l	resload(pc),a3
	jsr	resload_CRC16(a3)
	move.l	(a7)+,a1
	cmp.w	d0,d7
	bne.b	.wrong_checksum

.no_checksum_check
	move.l	(a2),d0
	lea	Part_Table(pc,d0.w),a0
	bsr	Apply_Patches

	lea	Part_Number(pc),a0
	addq.w	#1,(a0)
	cmp.w	#MAX_PARTS,(a0)
	ble.b	.ok
	move.w	#1,(a0)

.ok	rts



.wrong_checksum
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


			;load	jump	crc	patch list offset
Part_Table	dc.l	$10000,$1e4b0,$f564,PL_LOADER-Part_Table
		dc.l	$40000,$40000,0,PL_PART1-Part_Table
		dc.l	$30000,$30000,0,PL_PART2-Part_Table
		dc.l	$3a000,$3d000,0,PL_PART3-Part_Table
		dc.l	$30000,$30000,0,PL_PART4-Part_Table
		dc.l	$30000,$32000,0,PL_PART5-Part_Table
		dc.l	$25000,$30000,0,PL_PART6-Part_Table
		dc.l	$30000,$30000,0,PL_PART7-Part_Table

Part_Number	dc.w	0


; ---------------------------------------------------------------------------

PL_LOADER
	PL_START
	PL_SA	$e4be,$e50c		; skip OS stuff
	PL_L	$e7ba,$2000		; set Copperlst pointer to $2000.w
	PL_PSS	$f9b6,Fix_DMA_Wait,2
	PL_P	$fb72,Fix_Volume_Register_Write
	PL_ORW	$eb04+2,1<<9		; set Bplcon0 color bit
	PL_SA	$e566,$e570		; don't modify level 6 interrupt code
	PL_P	$e822,Acknowledge_Level6_Interrupt
	PL_R	$e742			; disable "Load Part" routine
	PL_PSS	$e5e4,Set_Default_Level6_Interrupt,4
	PL_PS	$e60c,.Run_Part
	PL_ORW	$e6c4+4,1<<9		; set Bplcon0 color bit
	PL_END


.Run_Part
	; As this patch uses the decrunched binaries, loading and patching
	; the next part must be done here to avoid trashed graphics. 
	bsr	Load_Part

.release_left_mouse_button
	btst	#6,$bfe001
	beq.b	.release_left_mouse_button
	
	jmp	(a5)

Fix_Volume_Register_Write
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts

Set_Default_Level6_Interrupt
	pea	Acknowledge_Level6_Interrupt(pc)
	move.l	(a7)+,$78.w
	rts

Acknowledge_Level6_Interrupt
	tst.b	$bfdd00
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte


; ---------------------------------------------------------------------------

PL_PART1
	PL_START
	PL_ORW	$184+2,1<<9		; set Bplcon0 color bit
	PL_PSA	$8c,Set_Copperlist,$b0
	PL_SA	$b8,$c2			; don't modify level 3 interrupt code
	PL_P	$15e,Acknowledge_Level3_Interrupt
	PL_PSS	$1790,Fix_DMA_Wait,2
	PL_P	$1952,Fix_Volume_Register_Write
	PL_PSS	$d6,Set_Default_Level3_Interrupt,4
	PL_PSA	$e0,Set_Default_Copperlist,$102
	PL_END

Set_Copperlist
	lea	$dff080-$32,a0
	rts

Set_Default_Copperlist
	lea	$1000.w,a0
	move.l	#$01000200,(a0)
	move.l	#$fffffffe,4(a0)
	move.l	a0,$dff080
	rts

Set_Default_Level3_Interrupt
	pea	Acknowledge_Level3_Interrupt(pc)
	move.l	(a7)+,$6c.w
	rts

Acknowledge_Level3_Interrupt
	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte	

; ---------------------------------------------------------------------------

PL_PART2
	PL_START
	PL_SA	$0,$1c			; skip OS stuff
	PL_L	$106,$2000		; set old copperlist pointer to $2000.w
	PL_ORW	$11e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2da+2,1<<9		; set Bplcon0 color bit
	PL_SA	$24,$2e			; don't modify level 3 interrupt code
	PL_P	$67c,Acknowledge_Level3_Interrupt
	PL_PSS	$131a,Fix_DMA_Wait,4
	PL_P	$1230,Fix_Volume_Register_Write
	PL_PS	$1438,Fix_Volume_Register_Write
	PL_PSS	$d4,Set_Default_Level3_Interrupt,4
	PL_PS	$e1c,.Clip_Dot		; don't set dot outside screen
	PL_END

.Clip_Dot
	sub.w	d0,d2
	add.l	d1,a1
	cmp.l	#$80000,a1
	bhi.b	.skip
	bset	d2,(a1)
.skip	rts

; ---------------------------------------------------------------------------

PL_PART3
	PL_START
	PL_SA	$3000,$300a		; skip Forbid()
	PL_SA	$3022,$3042		; skip drive access and graphics stuff
	PL_SA	$307e,$3096		; don't modify level 3 interrupt code
	PL_ORW	$3c9a+2,1<<9		; set Bplcon0 color bit
	PL_P	$3a58,Acknowledge_Level3_Interrupt
	PL_PSA	$30c6,Restore_System,$30f6
	PL_PSS	$558a,Fix_DMA_Wait,4
	PL_P	$5378,Fix_Volume_Register_Write
	PL_PS	$5684,Fix_Volume_Register_Write
	PL_END

Restore_System
	bsr	Set_Default_Level3_Interrupt
	lea	$2000.w,a0
	move.l	a0,$dff080
	rts


; ---------------------------------------------------------------------------

PL_PART4
	PL_START
	PL_SA	$0,$1c			; skip OS stuff
	PL_L	$866,$2000		; set old copperlist pointer to $2000.w
	PL_PSS	$f4a,Fix_DMA_Wait,2
	PL_P	$1106,Fix_Volume_Register_Write
	PL_ORW	$1916+2,1<<9		; set Bplcon0 color bit
	PL_END

; ---------------------------------------------------------------------------

PL_PART5
	PL_START
	PL_SA	$2010,$2018		; skip drive access
	PL_ORW	$2058+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$202a4,Fix_DMA_Wait,2
	PL_P	$20464,Fix_Volume_Register_Write
	PL_P	$2148,Acknowledge_Level3_Interrupt
	PL_ORW	$2092+2,1<<3		; enable level 2 interrupts
	PL_PSA	$20f0,Set_Default_Copperlist,$2110
	PL_SA	$2118,$211c
	PL_W	$364e,$1fe		; HTOTAL -> NOP
	PL_W	$211c+2,$c028
	PL_END

; ---------------------------------------------------------------------------

PL_PART6
	PL_START
	PL_PSS	$d31c,Fix_DMA_Wait,4
	PL_P	$d232,Fix_Volume_Register_Write
	PL_PS	$d416,Fix_Volume_Register_Write
	PL_PSA	$b160,Set_Copperlist,$b184
	PL_SA	$b18c,$b196		; don't modify level 3 interrupt code
	PL_P	$b21c,Acknowledge_Level3_Interrupt
	PL_PSA	$b1aa,Restore_System,$b1d6
	PL_END


; ---------------------------------------------------------------------------

PL_PART7
	PL_START
	PL_ORW	$1ba+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$1070,Fix_DMA_Wait,4
	PL_P	$f66,Fix_Volume_Register_Write
	PL_PS	$116a,Fix_Volume_Register_Write
	PL_SA	$0,$a			; skip Forbid()
	PL_SA	$e,$16			; skip changing audio filter
	PL_PSA	$5c,Set_Copperlist,$76
	PL_SA	$7e,$88			; don't modify level 3 interrupt code
	PL_P	$194,Acknowledge_Level3_Interrupt
	PL_PSA	$9e,Restore_System,$ca
	PL_END



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


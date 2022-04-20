***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   ARCADIA TEAM MEGADEMO WHDLOAD SLAVE      )*)---.---.   *
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

; 20-Apr-2022	- typo in blitter wait for part 5 fixed, scroller is now
;		  displayed
;		- some duplicate blitter wait code adapted/removed

; 19-Apr-2022	- code cleaned up a bit, f.e. using defines from dmabits.i
;		  for the DMA settings
;		- sprite bugs in several parts fixed by using a copperlist
;		  which initialises the sprite pointers and executes the
;		  the copperlist for the current part

; 18-Apr-2022	- a few minor fixes were needed to make the loader and
;		  first demo part work
;		- blitter waits in first part added
;		- part 2 patched
;		- part 3 patched
;		- part 4 patched
;		- part 5 patched
;		- routine Patch_Part_Number added to load, patch and run
;		  a part separately
;		- loader patch handles different ByteKiller binaries now
;		  (needed to decrunch part 6 correctly)
;		- part 6 patched
;		- part 7 patched
;		- all demo parts have been patched

; 17-Apr-2022	- work restarted
;		- loader part and first demo part patched, not tested yet


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Hardware/dmabits.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

RUN_PART_NUMBER	= 0
MAX_PARTS	= 7

DEFAULT_DMA	= DMAF_COPPER|DMAF_BLITTER|DMAF_RASTER

	
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
	dc.b	"SOURCES:WHD_Slaves/Demos/ArcadiaTeam/Megademo/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Megademo",0
.copy	dc.b	"1989 Arcadia Team",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.00 (20.04.2022)",0

File_Name	dc.b	"Arcadia_Megademo_Part_"
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


	IFD	DEBUG
		IFNE	RUN_PART_NUMBER
		moveq	#RUN_PART_NUMBER,d0
		bra.w	Patch_Part_Number
		ENDC
	ENDC

	bsr	Load_Part

	; Enable needed DMA and interrupts
	bsr	Set_Default_DMA
	bsr	Set_Default_Level3_Interrupt
	move.w	#$c028,$dff09a

	jmp	$11000+$2c00


; --------------------------------------------------------------------------
; Load, run and patch a part of the demo. Routine has been made to aid
; development of the patch. It is only enabled if "DEBUG" is set.

; d0.w: part number to patch and run.
	IFD	DEBUG
Patch_Part_Number
	cmp.w	#MAX_PARTS,d0
	ble.b	.Part_Number_is_Valid
	moveq	#MAX_PARTS,d0
.Part_Number_is_Valid	

	lea	Part_Number(pc),a0
	move.w	d0,(a0)

	move.l	d0,-(a7)
	bsr	Load_Part
	move.l	(a7)+,d0

	; fake loader copperlist
	lea	$11000+$333c,a0
	move.l	#$01000200,(a0)+
	move.l	#$fffffffe,(a0)

	lsl.w	#2,d0
	move.l	.Jump_Addresses(pc,d0.w),a0
	jsr	(a0)
	bra.w	QUIT

.Jump_Addresses
	dc.l	$11000			; loader
	dc.l	$7a000			; part 1
	dc.l	$75000			; part 2
	dc.l	$76600			; part 3
	dc.l	$58000			; part 4
	dc.l	$4a000			; part 5
	dc.l	$30000			; part 6
	dc.l	$30000			; part 7

	ENDC

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

	move.w	Part_Number(pc),d0
	beq.b	.no_ByteKiller_Decrunch
	move.l	a1,a0
	bsr	Get_Destination_Address

	bsr	Disable_Decruncher_Code


	movem.l	a1/a2,-(a7)
	bsr	Get_Crunched_Data
	bsr	ByteKiller_Decrunch
	movem.l	(a7)+,a1/a2

.no_ByteKiller_Decrunch

	move.l	(a2),d0
	lea	Part_Table(pc,d0.w),a0
	bsr	Apply_Patches

	lea	Part_Number(pc),a0
	addq.w	#1,(a0)
	rts



.wrong_checksum
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


			;load	jump	crc	patch list offset
Part_Table	dc.l	$11000,0,$D54E,PL_LOADER-Part_Table
		dc.l	$2a000,0,0,PL_PART1-Part_Table
		dc.l	$2a000,0,0,PL_PART2-Part_Table
		dc.l	$2a000,0,0,PL_PART3-Part_Table
		dc.l	$2a000,0,0,PL_PART4-Part_Table
		dc.l	$2a000,0,0,PL_PART5-Part_Table
		dc.l	$2a000,0,0,PL_PART6-Part_Table
		dc.l	$2a000,0,0,PL_PART7-Part_Table

Part_Number	dc.w	0


; ---------------------------------------------------------------------------

PL_LOADER
	PL_START
	PL_SA	$310e,$311c		; skip OS stuff
	PL_P	$3216,Acknowledge_Level3_Interrupt
	PL_SA	$31ca,$31d2		; don't modify level 3 interrupt code
	PL_L	$3312,$2000		; set copperlist pointer to $2000.w
	PL_P	$32ea,.Set_Copperlist_And_DMA
	PL_R	$312c			; don't change lowpass filter state
	PL_SA	$2c04,$2c0e		; don't clear KickTagPtr
	PL_P	$2e54,Load_Part
	PL_R	$2e78			; disable motor off
	PL_SA	$2c52,$2c5a		; don't change lowpass filter state
	PL_SA	$2ca4,$2cac		; don't change lowpass filter state
	PL_SA	$2cf6,$2cfe		; don't change lowpass filter state
	PL_SA	$2d48,$2d50		; don't change lowpass filter state
	PL_SA	$2d9a,$2da2		; don't change lowpass filter state
	PL_SA	$2dec,$2df4		; don't change lowpass filter state
	PL_SA	$2e3e,$2e46		; don't change lowpass filter state
	PL_W	$30a4+2,$07ff		; don't write $ffff to DMACON
	PL_PSS	$4b36,Fix_DMA_Wait,2
	PL_P	$4a44,Fix_Volume_Register_Write
	PL_PS	$4c1e,Fix_Volume_Register_Write
	PL_END

.Set_Copperlist_And_DMA
	bsr.b	Set_Copperlist
	bra.w	Set_Default_DMA

Set_Copperlist
	move.w	#DMAF_COPPER,$dff096
	move.l	a1,$dff080
	rts

Fix_Volume_Register_Write
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts


; ---------------------------------------------------------------------------

PL_PART1
	PL_START
	PL_P	$4ae76,.Delay_512
	PL_SA	$4a0a8,$4a0b6		; skip OS stuff
	PL_PSS	$4aa0e,Fix_DMA_Wait,2
	PL_P	$4a934,Fix_Volume_Register_Write
	PL_PS	$4ab3a,Fix_Volume_Register_Write
	PL_SA	$4a0c8,$4a0d0		; don't change lowpass filter state
	PL_P	$4a332,.Set_Copperlist
	PL_PSA	$4a0f0,.Set_Copperlist,$4a100
	PL_SA	$4a12c,$4a134		; don't change lowpass filter state
	PL_P	$4a138,Restore_System
	PL_P	$4a7e8,Acknowledge_Level3_Interrupt
	PL_PS	$4b1c0,.Wait_Blit
	PL_PS	$4b1e6,.Wait_Blit
	PL_PSS	$4af70,.Wait_Blit2,2
	PL_PSS	$4aece,.Wait_Blit3,2
	PL_END

.Wait_Blit
	add.l	#40*256,d0
	bra.w	Wait_Blit

.Wait_Blit2
	bsr	Wait_Blit
	move.w	#0,$dff064
	rts

.Wait_Blit3
	bsr	Wait_Blit
	move.w	#40-4,$dff064
	rts

.Delay_512
	move.w	#512/$34,d0
	bra.w	Wait_Raster_Lines


.Set_Copperlist
	move.l	$30000+$4a172,a1
	lea	$3000.w,a0
	bsr	Create_Copperlist
	lea	$3000.w,a0
	bsr.w	Set_Copperlist
Set_Default_DMA
	move.w	#DMAF_SETCLR|DMAF_MASTER|DEFAULT_DMA,$dff096
	rts


Restore_System
	bsr	Set_Default_Copperlist
	bsr	Set_Loader_Copperlist
	bsr	Set_Default_Level3_Interrupt
	bra.w	Set_Default_DMA


Set_Default_Copperlist
	lea	$1000.w,a0
	move.l	#$01000200,(a0)
	move.l	#$fffffffe,4(a0)
	move.l	a0,$dff080
	rts

Set_Loader_Copperlist
	move.l	#$11000+$333c,$dff080
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
	PL_SA	$45008,$45016		; skip OS stuff
	PL_SA	$46b64,$46b6c		; don't modify level 3 interrupt code
	PL_P	$46ba2,Acknowledge_Level3_Interrupt
	PL_PSS	$46dc8,Fix_DMA_Wait,2
	PL_P	$46cee,Fix_Volume_Register_Write
	PL_PS	$46ebc,Fix_Volume_Register_Write
	PL_ORW	$46642+2,1<<9		; set Bplcon0 color bit
	PL_P	$4660e,.Set_Copperlist_And_DMA
	PL_SA	$450aa,$450b2		; don't change lowpass filter state
	PL_SA	$45116,$4511e		; don't change lowpass filter state
	PL_P	$45122,Restore_System
	PL_END

.Set_Copperlist_And_DMA
	move.l	$30000+$45460,a1
	bsr.w	Set_Copperlist
	bra.w	Set_Default_DMA

; ---------------------------------------------------------------------------

PL_PART3
	PL_START
	PL_SA	$46600,$4660e		; skip OS stuff
	PL_PSS	$489a4,Fix_DMA_Wait,2
	PL_P	$48b6a,Fix_Volume_Register_Write
	PL_PSS	$48620,.Delay_2F00,2
	PL_PSS	$48376,.Delay_500,2
	PL_P	$470e0,.Delay_3500
	PL_SA	$4662a,$46632		; don't change lowpass filter state
	PL_SA	$467aa,$467b2		; don't change lowpass filter state
	PL_P	$47122,.Set_Copperlist_And_DMA
	PL_ORW	$47492+2,1<<9		; set Bplcon0 color bit
	PL_P	$467b6,Restore_System
	PL_PSS	$48594,.Wait_Blit,4
	PL_AW	$4839e+2,-4		; fix beq to branch to blitter wait 
	PL_PSS	$478da,.Wait_Blit2,2
	PL_PSS	$47920,.Wait_Blit3,4
	PL_END

.Wait_Blit
	bsr	Wait_Blit
	move.l	$30000+$48692,$dff04c
	rts

.Wait_Blit2
	bsr	Wait_Blit
	move.w	#44,$dff062
	rts

.Wait_Blit3
	bsr	Wait_Blit
	move.l	$30000+$47a5e,$dff040
	rts

.Set_Copperlist_And_DMA
	move.l	$30000+$467fe,a1
	lea	$3000.w,a0
	bsr	Create_Copperlist
	lea	$3000.w,a1

	bsr.w	Set_Copperlist
	bra.w	Set_Default_DMA

.Delay_2F00
	move.w	#$2f00/$34,d0
	bra.w	Wait_Raster_Lines

.Delay_500
	move.w	#$500/$34,d0
	bra.w	Wait_Raster_Lines

.Delay_3500
	move.w	#$3500/$34,d0
	bra.w	Wait_Raster_Lines


; ---------------------------------------------------------------------------

PL_PART4
	PL_START
	PL_SA	$28002,$28010		; skip OS stuff
	PL_P	$28b80,.Set_Copperlist_And_DMA
	PL_SA	$2803e,$28046		; don't change lowpass filter state
	PL_SA	$28064,$2806c		; don't change lowpass filter state
	PL_SA	$28c48,$28c50		; don't modify level 3 interrupt code
	PL_P	$28c86,Acknowledge_Level3_Interrupt
	PL_PSS	$28c5a,Set_Default_Level3_Interrupt,2
	PL_PSS	$28eac,Fix_DMA_Wait,2
	PL_P	$28dd2,Fix_Volume_Register_Write
	PL_PS	$28fa0,Fix_Volume_Register_Write
	PL_P	$28070,Restore_System
	PL_END

.Set_Copperlist_And_DMA
	move.l	$30000+$28b1c,a1
	bsr.w	Set_Copperlist
	bra.w	Set_Default_DMA
	

; ---------------------------------------------------------------------------

PL_PART5
	PL_START
	PL_SA	$801a,$8028		; skip OS stuff
	PL_ORW	$8b9e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$8c96+2,1<<9		; set Bplcon0 color bit
	PL_P	$9634,.Set_Copperlist_And_DMA
	PL_PSS	$98ce,Fix_DMA_Wait,2
	PL_P	$9a8a,Fix_Volume_Register_Write
	;PL_W	$80a8+2,$7ff		; correctly disable all DMA channels
	PL_SA	$80a8,$80b0		; don't write $ffff to DMACON
	PL_P	$8126,Restore_System
	PL_PS	$896c,Wait_Blit_Clr_dff064
	PL_PSS	$898a,.Wait_Blit2,4
	PL_PSS	$86fc,.Wait_Blit3,2
	PL_PSS	$8798,.Wait_Blit4,4
	PL_PSS	$87e2,.Wait_Blit5,4
	PL_PSS	$88ea,.Wait_Blit6,2
	PL_PS	$893a,Wait_Blit_d3_dff052
	PL_END

.Set_Copperlist_And_DMA
	move.l	$42000+$8168,a1

	lea	$3000.w,a0
	bsr	Create_Copperlist

	lea	$3000.w,a1
	bsr.w	Set_Copperlist
	move.w	#DMAF_SETCLR|DMAF_MASTER|DEFAULT_DMA|DMAF_SPRITE,$dff096
	rts


.Wait_Blit2
	bsr	Wait_Blit
	move.l	$42000+$8d76,$dff050
	rts

.Wait_Blit3
	bsr	Wait_Blit
	move.w	#32,$dff060
	rts

.Wait_Blit4
	bsr	Wait_Blit
	move.l	$42000+$884a,$dff050
	rts

.Wait_Blit5
	bsr	Wait_Blit
	move.l	#$09f00000,$dff040
	rts

.Wait_Blit6
	bsr	Wait_Blit
	move.w	#6,$dff050
	rts

Wait_Blit_Clr_dff064
	bsr	Wait_Blit
	move.l	#0,$dff064
	rts

Wait_Blit_d3_dff052
	bsr	Wait_Blit
	move.w	d3,$dff052
	rts


; ---------------------------------------------------------------------------

PL_PART6
	PL_START
	PL_W	$103a+2,$07ff		; correctly disable all DMA channels
	PL_SA	$1042,$1050		; skip OS stuff
	PL_P	$26ea,.Set_Copperlist
	PL_PSS	$30ca,Fix_DMA_Wait,2
	PL_P	$328c,Fix_Volume_Register_Write
	PL_SA	$10e8,$10f2		; don't modify level 3 interrupt code
	PL_P	$1112,Acknowledge_Level3_Interrupt
	PL_PSS	$11ce,Set_Default_Level3_Interrupt,4
	PL_P	$11e4,Restore_System
	PL_PS	$10aa,.Set_DMA		; enable DMA after copper buffers have
					; been initialised
	PL_ORW	$10fc+2,1<<3|1<<5	; enable level 2+3 interrupts
	PL_P	$26ca,.Wait_Blit
	PL_PS	$2690,Wait_Blit_Clr_dff064
	PL_PS	$266c,Wait_Blit_d3_dff052
	PL_PSS	$2624,Wait_Blit_7_dff050,2	
	PL_END

.Set_Copperlist
	move.l	$30000+$2244,a1
	bra.w	Set_Copperlist

.Set_DMA
	lea	$30000+$2dea,a3
	bra.w	Set_Default_DMA

.Wait_Blit
	move.l	a3,$30000+$121c
	bra.w	Wait_Blit

Wait_Blit_7_dff050
	bsr	Wait_Blit
	move.w	#7,$dff050
	rts

; ---------------------------------------------------------------------------

PL_PART7
	PL_START
	PL_SA	$e,$1c			; skip OS stuff
	PL_SA	$50,$64			; skip InitBitMap and InitRastPort
	PL_P	$ce6,.Set_Copperlist
	PL_PSS	$210a,Fix_DMA_Wait,2
	PL_P	$22cc,Fix_Volume_Register_Write
	PL_PS	$ca,.Set_DMA
	PL_P	$1a8,Restore_System
	PL_PSS	$14de,Wait_Blit_7_dff050,2
	PL_PS	$1cec,Wait_Blit_Clr_dff064
	PL_PS	$13aa,.Wait_Blit_d0_dff050
	PL_PS	$13f4,.Wait_Blit_d0_dff050
	PL_PS	$1360,.Wait_Blit_d0_dff050
	PL_END

.Set_Copperlist
	move.l	$30000+$b28,a1
	lea	$3000.w,a0
	bsr	Create_Copperlist
	lea	$3000.w,a1
	bra.w	Set_Copperlist

.Set_DMA
	lea	$30000+$794,a3
	bra.w	Set_Default_DMA

.Wait_Blit_d0_dff050
	bsr	Wait_Blit
	move.l	d0,$dff050
	rts

; ---------------------------------------------------------------------------
; Create copperlist which initialises all sprite pointers and executes the
; part copperlist. This will fix the annoyin sprite glitches in several
; parts.

; a0.l: destination for copperlist
; a1.l: copperlist to execute after sprites have been initialised

Create_Copperlist
	moveq	#8*2-1,d0
	move.w	#$120,d1
.loop	move.w	d1,(a0)+
	clr.w	(a0)+
	addq.w	#2,d1
	dbf	d0,.loop


	move.w	#$80,(a0)+
	move.l	a1,d1
	swap	d1
	move.w	d1,(a0)+
	move.w	#$82,(a0)+
	move.w	a1,(a0)+
	move.w	#$8a,(a0)
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


Wait_Blit
	tst.b	$dff002
.wait_blit
	btst	#6,$dff002
	bne.b	.wait_blit
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

; Return the destination address for a ByteKiller binary.
;
; a0.l: ByteKiller crunched binary
; -----
; a1.l: Destination address

Get_Destination_Address
	move.l	2(a0),a1
	rts

; Disable the decruncher code with:
; moveq #0,d0
; rts
;
; a0.l: ByteKiller crunched binary
Disable_Decruncher_Code
	move.l	#$70004e75,(a0)
	rts

; Return start of ByteKiller crunched data.
;
; a0.l: ByteKiller crunched binary
; ----
; a0.l: pointer to ByteKiller crunched data
Get_Crunched_Data
	add.w	6+2(a0),a0
	addq.w	#8,a0
	rts

; Bytekiller decruncher
; resourced and adapted by stingray
;
; a0.l: source
; a1.l: destination

ByteKiller_Decrunch
	bsr.b	.decrunch
	tst.l	d5
	beq.b	.ok

; checksum doesn't match, file corrupt
	pea	ErrText(pc)
	pea	(TDREASON_FAILMSG).w
	bra.w	EXIT

.ok	rts


.decrunch
	move.l	(a0)+,d0		; packed length
	move.l	(a0)+,d1		; unpacked length
	move.l	(a0)+,d5		; checksum
	add.l	d0,a0			; a0: end of packed data
	lea	(a1,d1.l),a2		; a2: end of unpacked data
	move.l	-(a0),d0		; get first long
	eor.l	d0,d5
.loop	lsr.l	#1,d0
	bne.b	.nonew1
	bsr.b	.nextlong
.nonew1	bcs.b	.getcmd

	moveq	#8,d1
	moveq	#1,d3
	lsr.l	#1,d0
	bne.b	.nonew2
	bsr.b	.nextlong
.nonew2	bcs.b	.copyunpacked

; data is packed, unpack and copy
	moveq	#3,d1			; next 3 bits: length of packed data
	clr.w	d4

; d1: number of bits to get from stream
; d4: length
.packed	bsr.b	.getbits
	move.w	d2,d3
	add.w	d4,d3
.copypacked
	moveq	#8-1,d1
.getbyte
	lsr.l	#1,d0
	bne.b	.nonew3
	bsr.b	.nextlong
.nonew3	roxl.l	#1,d2
	dbf	d1,.getbyte

	move.b	d2,-(a2)
	dbf	d3,.copypacked
	bra.b	.next

.ispacked
	moveq	#8,d1
	moveq	#8,d4
	bra.b	.packed

.getcmd	moveq	#2,d1			; next 2 bits: command
	bsr.b	.getbits
	cmp.b	#2,d2			; %10: unpacked data follows
	blt.b	.notpacked
	cmp.b	#3,d2			; %11: packed data follows
	beq.b	.ispacked

; %10
	moveq	#8,d1			; next byte:
	bsr.b	.getbits		; length of unpacked data
	move.w	d2,d3			; length -> d3
	moveq	#12,d1
	bra.b	.copyunpacked

; %00 or %01
.notpacked
	moveq	#9,d1
	add.w	d2,d1
	addq.w	#2,d2
	move.w	d2,d3

.copyunpacked
	bsr.b	.getbits		; get offset (d2)

	subq.w	#1,d2
.copy	move.b	(a2,d2.w),-(a2)
	dbf	d3,.copy

.next	cmp.l	a2,a1
	blt.b	.loop
	rts

.nextlong
	move.l	-(a0),d0
	eor.l	d0,d5
	move.w	#1<<4,ccr
	roxr.l	#1,d0
	rts

; d1.w: number of bits to get
; ----
; d2.l: bit stream

.getbits
	subq.w	#1,d1
	clr.w	d2
.getbit	lsr.l	#1,d0
	bne.b	.nonew
	move.l	-(a0),d0
	eor.l	d0,d5
	move.w	#1<<4,ccr
	roxr.l	#1,d0
.nonew	addx.l	d2,d2
	dbf	d1,.getbit
	rts


ErrText	dc.b	"Decrunching failed, file corrupt!",0



***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   TWILIGHT ZONE/SHINING 8 WHDLOAD SLAVE    )*)---.---.   *
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

; 11-Mar-2023	- graphics problems in "Unlimited Bobs" part finally fixed
;		- patch is finished
;		- unused code removed

; 05-Mar-2023	- illegal plane pointers in boot part disabled
;		- Tetra Pack 2.1 decruncher relocated to fast memory and
;		  adapted to handle all demo executables
;		- code to handle the Tetra Pack 2.1 executables adapted

; 04-Mar-2023	- commercial break part works now (different "load data"
;		  routine was used to load the part)
;		- end part patched

; 03-Mar-2023	- copper plasma part: blitter wait added and interrupts
;		  fixed
;		- unlimited bobs part patched
;		- elastic logo part patched
;		- all other parts (except end part) patched
;		- commercial break part doesn't work yet

; 02-Mar-2023	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Hardware/dmabits.i
	INCLUDE	hardware/intbits.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

LEVEL3_SAVE	= $100	; address to store old level 3 interrupt vector

	
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
	dc.b	"SOURCES:WHD_Slaves/Demos/Shining8/TwilightZone/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Twilight Zone",0
.copy	dc.b	"1992 Shining 8",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.00 (11.03.2023)",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; relocate stack to low memory
	lea	$2000.w,a7

	; Load boot code/intro part
	moveq	#63,d0
	pea	$f000
	move.l	(a7),a0
	bsr.b	Load_Demo_File
	move.l	(a7),a0
	jsr	resload_CRC16(a2)
	cmp.w	#$6590,d0
	beq.b	.Version_is_Supported

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.Version_is_Supported

	; Install default level 3 interrupt
	pea	Acknowledge_Level3_Interrupt(pc)
	move.l	(a7)+,$6c.w

	; Decrunch boot code, patch it and run the demo
	move.l	(a7)+,a0
	pea	PL_BOOT(pc)
	bra.w	Patch_And_Run_Packed_Part


; d0.w: track
; a0.l: destination
; ----
; d0.l: file size

Load_Demo_File
	move.l	a0,-(a7)
	bsr.b	Build_File_Name
	move.l	(a7)+,a1
	bra.w	Load_File


; d0.w: start sector
; ----
; a0.l: file name

Build_File_Name
	lea	File_Name(pc),a0
	lea	FN_SECTOR(a0),a1
	move.w	d0,d3
	moveq	#2,d4

; d3.w: source
; d4.w: number of digits to convert
; a1.l: destination

Convert_Number
.loop	moveq	#$f,d5
	and.b	d3,d5
	cmp.b	#$09,d5
	ble.b	.is_valid_hex_number
	addq.b	#$07,d5
.is_valid_hex_number
	add.b	#"0",d5
	move.b	d5,-1(a1,d4.w)
	ror.w	#4,d3
	subq.w	#1,d4
	bne.b	.loop
	rts
	


	RSRESET
FN_HEADER		rs.b	12	; TwilightZone
FN_SECTOR_SEPARATOR	rs.b	1
FN_SECTOR		rs.b	2

File_Name
	dc.b	"TwilightZone_XX",0
	CNOP	0,2


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

PL_BOOT	PL_START
	PL_PSS	$37a4a,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PSS	$37a60,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PSS	$3818a,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PSS	$381a0,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_L	$3318c+6,LEVEL3_SAVE	; don't modify level 3 interrupt code
	PL_P	$3353c,Acknowledge_Level3_Interrupt	
	PL_PSA	$3343e,.Load_Loader_Part,$33476
	PL_L	$334a8+2,LEVEL3_SAVE
	PL_P	$334b8,.Patch_Loader_Part
	PL_PSS	$333f0,Set_LOF_Bit,2
	;PL_SA	$33212,$33414		; skip animations

	PL_W	$39bfa,$1fe		; disable invalid plane pointers
	PL_W	$39bfe,$1fe		; in copperlist
	PL_END

.Patch_Loader_Part
	pea	PL_LOADER_PART(pc)
	bra.w	Patch_And_Run_Packed_Part

.Load_Loader_Part
	moveq	#$30,d0
	lea	$13400+$4317c,a0
	bra.w	Load_Demo_File

Set_LOF_Bit
	move.w	#1<<15,$dff02a		; VPOSW
	rts

; ---------------------------------------------------------------------------

PL_LOADER_PART
	PL_START
	PL_PSS	$3b214,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PSS	$3b22a,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PSS	$3b954,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PSS	$3b96a,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_L	$33f30+6,LEVEL3_SAVE	; don't modify level 3 interrupt code
	PL_P	$3af40,Acknowledge_Level3_Interrupt	
	PL_R	$36802			; disable loader initialisation
	PL_PS	$36838,.Load_Data
	PL_R	$368b2			; disable drive access (motor on)
	PL_R	$368ca			; disable drive access (motor off)
	PL_L	$35fd2+2,LEVEL3_SAVE
	PL_PS	$35fdc,.Patch_And_Run_Part	; credits
	PL_PS	$3608c,.Patch_And_Run_Part	; copper plasma
	PL_PS	$3613c,.Patch_And_Run_Part	; unlimited bobs
	PL_PS	$361ec,.Patch_And_Run_Part	; elastic logo
	PL_PS	$3629c,.Patch_And_Run_Part	; members
	PL_PS	$3634c,.Patch_And_Run_Part	; transforming dots
	PL_PS	$363fc,.Patch_And_Run_Part	; bob scroller
	PL_PS	$364ac,.Patch_And_Run_Part	; vector ship
	PL_PS	$3655c,.Patch_And_Run_Part	; vector
	PL_P	$36630,.Patch_Commercial_Break_Part
	PL_L	$365dc+2,LEVEL3_SAVE
	;PL_SA	$35f70,$36562			; straight to "Commercial Break" part
	PL_PS	$36876,.Load_Data
	PL_END


.Patch_Commercial_Break_Part
	pea	PL_COMMERCIAL_BREAK_PART(pc)
	bra.w	Patch_And_Run_Packed_Part

.Load_Data
	move.w	$f400+$3c674,d0
	move.l	$f400+$36ab4,a0
	bra.w	Load_Demo_File

.Patch_And_Run_Part
	lea	.Part_Number(pc),a0
	move.w	(a0),d0
	addq.w	#1*2,(a0)
	move.w	.TAB(pc,d0.w),d0
	lea	.TAB(pc,d0.w),a0
	lea	$55900,a1
	bsr	Apply_Patches
	jmp	$55908


.Part_Number	dc.w	0
.TAB		dc.w	PL_CREDITS_PART-.TAB
		dc.w	PL_PLASMA_PART-.TAB
		dc.w	PL_UNLIMITED_BOBS_PART-.TAB
		dc.w	PL_ELASTIC_LOGO_PART-.TAB
		dc.w	PL_MEMBERS_PART-.TAB
		dc.w	PL_TRANSFORMING_DOTS_PART-.TAB
		dc.w	PL_BOB_SCROLLER_PART-.TAB
		dc.w	PL_VECTOR_SHIP_PART-.TAB
		dc.w	PL_VECTOR_PART-.TAB


; ---------------------------------------------------------------------------

PL_CREDITS_PART
	PL_START
	PL_ORW	$8c4+2,1<<8		; fix BLTCON0 settings in line drawing routine
	PL_SA	$24,$38			; don't modify level 3 interrupt code
	PL_P	$934,Acknowledge_Level3_Interrupt
	PL_P	$91e,Acknowledge_Level3_Interrupt
	PL_END


; ---------------------------------------------------------------------------

PL_PLASMA_PART
	PL_START
	PL_W	$1148+2,$7f		; fix Bplcon2 value
	PL_PS	$6e8,Wait_Blit_dff000_a6
	PL_SA	$10,$24			; don't modify level 3 interrupt code
	PL_P	$1f0,Acknowledge_Level3_Interrupt
	PL_P	$1da,Acknowledge_Level3_Interrupt
	
	PL_END
	
Wait_Blit_dff000_a6
	lea	$dff000,a6
	bra.w	Wait_Blit


; ---------------------------------------------------------------------------

MINIMUM_RASTER_LINE	= 80

PL_UNLIMITED_BOBS_PART
	PL_START
	PL_SA	$4a,$5e			; don't modify level 3 interrupt code
	PL_P	$6d4,Acknowledge_Level3_Interrupt
	PL_P	$6be,Acknowledge_Level3_Interrupt
	PL_ORW	$1316+2,1<<8		; fix BLTCON0 settings in line drawing routine
	PL_PSS	$1420,Wait_Blit_ffffffff_44_a6,2
	PL_P	$cbe,.Synchronise_After_Fill
	PL_END


; This fixes the graphics problems, for some reason, the code needs to be
; slowed down on fast machines as otherwise the cube is not filled correctly
; and visible glitches appear. I suspect the double buffering is the real
; reason, but this workaround is good enough for me. Spent way too much time
; on this problem!

.Synchronise_After_Fill
	move.w	d1,$58(a6)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#MINIMUM_RASTER_LINE<<8,d0
	ble.b	.wait
	rts


Wait_Blit_ffffffff_44_a6
	bsr	Wait_Blit
	move.l	#$ffffffff,$44(a6)
	rts


; ---------------------------------------------------------------------------

PL_ELASTIC_LOGO_PART
	PL_START
	PL_SA	$2e,$42			; don't modify level 3 interrupt code
	PL_P	$2ec,Acknowledge_Level3_Interrupt
	PL_P	$2bc,Acknowledge_Level3_Interrupt
	PL_END

; ---------------------------------------------------------------------------

PL_MEMBERS_PART
	PL_START
	PL_SA	$3c,$50			; don't modify level 3 interrupt code
	PL_P	$3e0,Acknowledge_Level3_Interrupt
	PL_P	$40e,Acknowledge_Level3_Interrupt
	PL_L	$119a,$fffffffe
	PL_END

; ---------------------------------------------------------------------------

PL_TRANSFORMING_DOTS_PART
	PL_START
	PL_SA	$10,$24			; don't modify level 3 interrupt code
	PL_P	$a44,Acknowledge_Level3_Interrupt
	PL_P	$a2e,Acknowledge_Level3_Interrupt
	PL_END

; ---------------------------------------------------------------------------

PL_BOB_SCROLLER_PART
	PL_START
	PL_SA	$24,$38			; don't modify level 3 interrupt code
	PL_P	$96a,Acknowledge_Level3_Interrupt
	PL_P	$954,Acknowledge_Level3_Interrupt
	PL_PSS	$522,Wait_Blit_ffff0000_44_a6,2
	PL_END

Wait_Blit_ffff0000_44_a6
	bsr	Wait_Blit
	move.l	#$ffff0000,$44(a6)
	rts

; ---------------------------------------------------------------------------

PL_VECTOR_SHIP_PART
	PL_START
	PL_SA	$6c,$80			; don't modify level 3 interrupt code
	PL_P	$39c,Acknowledge_Level3_Interrupt
	PL_P	$3b2,Acknowledge_Level3_Interrupt
	PL_ORW	$18b4+2,1<<8		; fix BLTCON0 settings in line drawing routine
	PL_PSS	$19c6,Wait_Blit_ffffffff_44_a6,2
	PL_END

; ---------------------------------------------------------------------------

PL_VECTOR_PART
	PL_START
	PL_SA	$10,$24			; don't modify level 3 interrupt code
	PL_P	$1ca,Acknowledge_Level3_Interrupt
	PL_P	$1e0,Acknowledge_Level3_Interrupt
	PL_ORW	$120a+2,1<<8		; fix BLTCON0 settings in line drawing routine
	PL_PSS	$131c,Wait_Blit_ffffffff_44_a6,2
	PL_END

; ---------------------------------------------------------------------------

PL_COMMERCIAL_BREAK_PART
	PL_START
	PL_SA	$2815a,$28164		; don't modify level 3 interrupt code
	PL_L	$28164+6,LEVEL3_SAVE
	PL_L	$28348+2,LEVEL3_SAVE
	PL_P	$285a0,Acknowledge_Level3_Interrupt
	PL_P	$2858e,Acknowledge_Level3_Interrupt
	PL_PSS	$2ce58,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PSS	$2ce6e,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PSS	$2d498,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PSS	$2d5ae,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_R	$2868e			; disable loader initialisation
	PL_PS	$286c2,.Load_Data
	PL_R	$286ce			; disable drive access (motor off)
	PL_PSS	$282b8,Set_LOF_Bit,2
	PL_P	$28358,.Patch_End_Part
	PL_END

.Load_Data
	move.w	$1e000+$2c908,d0
	move.l	$1e000+$28904,a0
	bra.w	Load_Demo_File

.Patch_End_Part
	pea	PL_END_PART(pc)
	bra.w	Patch_And_Run_Packed_Part

; ---------------------------------------------------------------------------

PL_END_PART
	PL_START
	PL_PSS	$694,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PSS	$6aa,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PSS	$dd4,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PSS	$dea,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_SA	$10,$24			; don't modify level 3 interrupt code
	PL_P	$1efa,Acknowledge_Level3_Interrupt
	PL_P	$1ee8,Acknowledge_Level3_Interrupt
	PL_W	$2e+2,INTF_SETCLR|INTF_INTEN|INTF_VERTB|INTF_PORTS
	PL_W	$a4+2,INTF_SETCLR|INTF_INTEN|INTF_VERTB|INTF_PORTS
	PL_P	$144,QUIT		; reset -> quit to DOS
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
	lea	$DFF182,a5
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

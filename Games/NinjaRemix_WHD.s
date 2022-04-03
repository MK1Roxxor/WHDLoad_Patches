***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       NINJA REMIX WHDLOAD SLAVE            )*)---.---.   *
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

; 03-Apr-2022	- save game feature disabled if trainer options are used
;		- help screen to display in-game keys added
;		- DMA wait in replayer fixed
;		- Harakiri key is enabled if unlimited energy option has
;		  been enabled
;		- start at level option added
;		- CD32 joypad support added: BLUE:change weapon,
;		  GREEN: change object, YELLOW: show help screen,
;		  PLAY: toggle pause
;		- patch is finished!

; 02-Apr-2022	- work started
;		- game patched and trained


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
DEBUG

FAST_MEMORY_SIZE	= 524288 

; Trainer options
TRB_LIVES	= 0		; unlimited lives	
TRB_ENERGY	= 1		; unlimited energy
TRB_ALL_OBJECTS	= 2		; all weapons and objects
TRB_KEYS	= 3		; in-game keys

MAX_LEVEL	= 6		; maximum game level

RAWKEY_1	= $01
RAWKEY_2	= $02
RAWKEY_3	= $03
RAWKEY_4	= $04
RAWKEY_5	= $05
RAWKEY_6	= $06
RAWKEY_7	= $07
RAWKEY_8	= $08
RAWKEY_9	= $09
RAWKEY_0	= $0A

RAWKEY_Q	= $10
RAWKEY_W	= $11
RAWKEY_E	= $12
RAWKEY_R	= $13
RAWKEY_T	= $14
RAWKEY_Y	= $15		; English layout
RAWKEY_U	= $16
RAWKEY_I	= $17
RAWKEY_O	= $18
RAWKEY_P	= $19

RAWKEY_A	= $20
RAWKEY_S	= $21
RAWKEY_D	= $22
RAWKEY_F	= $23
RAWKEY_G	= $24
RAWKEY_H	= $25
RAWKEY_J	= $26
RAWKEY_K	= $27
RAWKEY_L	= $28

RAWKEY_Z	= $31		; English layout
RAWKEY_X	= $32
RAWKEY_C	= $33
RAWKEY_V	= $34
RAWKEY_B	= $35
RAWKEY_N	= $36
RAWKEY_M	= $37

RAWKEY_SPACE	= $40
RAWKEY_HELP	= $5f

RAWKEY_B_DELAY_RELEASE	= 7
	
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
	dc.l	FAST_MEMORY_SIZE	; ws_ExpMem
	dc.w	.name-HEADER		; ws_name
	dc.w	.copy-HEADER		; ws_copy
	dc.w	.info-HEADER		; ws_info

; v16
	dc.w	0			; ws_kickname
	dc.l	0			; ws_kicksize
	dc.w	0			; ws_kickcrc

; v17
	dc.w	.config-HEADER		; ws_config


.config	dc.b	"C1:X:Unlimited Lives:",TRB_LIVES+"0",";"
	dc.b	"C1:X:Unlimited Energy:",TRB_ENERGY+"0",";"
	dc.b	"C1:X:All Weapons/Objects:",TRB_ALL_OBJECTS+"0",";"
	dc.b	"C1:X:In-Game Keys (Press Help during Game):",TRB_KEYS+"0",";"
	dc.b	"C2:L:Start at Level:1,2,3,4,5,6;"
	dc.b	"C3:B:Enable CD32 Controls;"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Games/NinjaRemix",0
	ENDC

.name	dc.b	"Ninja Remix",0
.copy	dc.b	"1990 System 3",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.1 (03.04.2022)",0
	CNOP	0,4


TAGLIST		dc.l	WHDLTAG_CUSTOM2_GET
Level_Number	dc.l	0
		dc.l	TAG_DONE

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

	; Detect CD32 controller
	bsr	_detect_controller_types

	; Load boot code
	lea	$400.w,a0
	move.l	#$1600,d0
	move.l	#5*512,d1
	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)

	; Version check
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$993D,d0			; SPS 3020
	beq.b	.version_ok
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
.version_ok


	; Patch boot code
	lea	PL_BOOT_CODE(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; Initialise keyboard interrupt
	bsr	Init_Level2_Interrupt

	; Avoid trashed bitplane pointers
	lea	$70000,a0
	move.l	a0,(a5)

	; Run the game
	jmp	$1c(a5)


; ---------------------------------------------------------------------------
; Boot code patches

SIDE_0_ID	= $505
DISK_SIDE_SIZE	= 80*512*10

PL_BOOT_CODE
	PL_START
	PL_ORW	$160+2,1<<9		; set Bplcon0 color bit
	PL_P	$20c,Acknowledge_Vertical_Blank_Interrupt
	PL_P	$230,Load_Game_File
	PL_ORW	$1ca+2,1<<3		; enable level 2 interrupts
	PL_R	$33a			; disable protection track check
	PL_P	$6e,.Patch_Game
	PL_END

.Patch_Game
	lea	PL_GAME(pc),a0
	lea	$101c.w,a1
	bsr	Apply_Patches
	jmp	(a1)
	


; a6.l: pointer to file parameters
Load_Game_File
	move.w	(a6)+,d0		; track
	mulu.w	#512*10,d0
	move.w	(a6)+,d1		; sector in track
	subq.w	#1,d1
	mulu.w	#512,d1
	add.l	d1,d0
	move.w	(a6)+,d1		; number of sectors to load
	mulu.w	#512,d1
	move.l	(a6)+,a0		; destination
	move.l	(a6)+,d2		; flags
	cmp.w	#SIDE_0_ID,d2
	beq.b	.is_side_0
	add.l	#DISK_SIDE_SIZE,d0
.is_side_0
	move.b	Disk_Number(pc),d2
	move.l	resload(pc),a1
	jmp	resload_DiskLoad(a1)

Disk_Number	dc.b	1
In_Game_Keys	dc.b	0

; ---------------------------------------------------------------------------
; Game patches

MAXIMUM_ENERGY	= 33
SAVE_GAME_SIZE	= 24			; bytes
SAVE_GAME_DATA	= $5fd46

GAME_ADDRESS	= $101c

PL_GAME	PL_START
	PL_P	$961e,Acknowledge_Vertical_Blank_Interrupt
	PL_P	$93e0,Acknowledge_Vertical_Blank_Interrupt
	PL_P	$9642,Acknowledge_Copper_Interrupt
	PL_ORW	$95c4+2,1<<3		; enable level 2 interrupts
	PL_R	$87c4			; disable protection track check
	PL_ORW	$92e4+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$9306,.Initialise_Keyboard,2
	PL_R	$94e0
	PL_P	$86ba,Load_Game_File
	PL_PSA	$a190,.Detect_Extra_Memory,$a1f2
	PL_P	$9c3c,.Set_Disk_Number
	PL_P	$8d3a,.Load_Game
	PL_P	$8bf0,.Save_Game
	PL_PS	$a23e,.Fix_Sample_Player
	

	; Unlimited Lives
	PL_IFC1X	TRB_LIVES
	PL_B	$31e,$4a
	PL_ENDIF

	; Unlimited Energy
	PL_IFC1X	TRB_ENERGY
	PL_B	$31e8,$4a
	PL_P	$94e0,.Check_Harakiri_Key
	PL_ENDIF

	; All Weapons and Objects
	PL_IFC1X	TRB_ALL_OBJECTS
	PL_L	$4c2a,$01010101
	PL_L	$4c2e,$01010101
	PL_L	$4c32,$01010101
	PL_L	$4c36,$01010101
	PL_SA	$d4,$f0
	PL_ENDIF
	
	; In-Game Keys
	PL_IFC1X	TRB_KEYS
	PL_P	$94e0,.Handle_In_Game_Keys
	PL_PS	$1be,.Show_Help_Screen
	PL_ENDIF

	; Disable save game support if trainer options have been used
	PL_IFC1
	PL_S	$3c6,6
	PL_R	$9ecc
	PL_ENDIF

	PL_IFC2
	PL_PSS	$b8,.Set_Level,2
	PL_S	$3c6,6
	PL_R	$9ecc
	PL_ENDIF


	; CD32 joypad support
	PL_IFC3
	PL_PS	$937c,Read_CD32_Pad_In_Vertical_Blank_Interrupt
	PL_ENDIF
	
	PL_END


.Set_Level
	move.l	Level_Number(pc),d0
	addq.w	#1,d0
	cmp.w	#MAX_LEVEL,d0
	ble.b	.Is_Valid_Level_Number
	moveq	#1,d0
.Is_Valid_Level_Number
	move.w	d0,GAME_ADDRESS+$432.w
	rts

.Load_Game
	lea	.Save_Name(pc),a0
	bsr	File_Exists
	tst.l	d0
	beq.b	.No_Save_Game_File_Found
	lea	SAVE_GAME_DATA,a1
	bsr	Load_File
.No_Save_Game_File_Found
	rts

.Save_Game
	lea	.Save_Name(pc),a0
	lea	SAVE_GAME_DATA,a1
	moveq	#SAVE_GAME_SIZE,d0
	bra.w	Save_File	

.Save_Name	dc.b	"NinjaRemix_Save",0
		CNOP	0,2


.Fix_Sample_Player
	pea	Fix_DMA_Wait(pc)
	move.w	#$4ef9,$4d84e+$1b0
	move.l	(a7)+,$4d84e+2+$1b0
	jmp	$4d84e			; original code


.Set_Disk_Number
	moveq	#1,d1
	cmp.w	#1,d0
	ble.b	.ok
	moveq	#2,d1
	cmp.w	#3,d0
	ble.b	.ok
	moveq	#3,d1
	;cmp.w	#6,d0
	;ble.b	.ok

.ok	lea	Disk_Number(pc),a0
	move.b	d1,(a0)
	moveq	#0,d0			; correct disk inserted
	rts


.Detect_Extra_Memory
	move.l	HEADER+ws_ExpMem(pc),a0
	rts

.Initialise_Keyboard
	lea	.Handle_Keyboard(pc),a0
	bra.w	Set_Keyboard_Custom_Routine

.Handle_Keyboard
	move.b	RawKey(pc),d0
	jmp	GAME_ADDRESS+$94ca

; Special case: if unlimited energy option has been enabled,
; the key to kill the player will be active as well.
.Check_Harakiri_Key
	lea	(GAME_ADDRESS).w,a0
	move.b	RawKey(pc),d0
	cmp.b	#RAWKEY_K,d0
	beq.b	.Harakiri
	rts

.Handle_In_Game_Keys
	moveq	#0,d0
	move.b	RawKey(pc),d0
	lea	.Table(pc),a0
.check_all_entries
	movem.w	(a0)+,d1/d2
	cmp.w	d0,d1
	bne.b	.check_next_entry

	lea	(GAME_ADDRESS).w,a0
	move.l	#$01010101,d0
	jmp	.Table(pc,d2.w)

.check_next_entry
	tst.w	(a0)
	bne.b	.check_all_entries
	rts

.Table	dc.w	RAWKEY_L,.Toggle_Unlimited_Lives-.Table
	dc.w	RAWKEY_E,.Toggle_Unlimited_Energy-.Table
	dc.w	RAWKEY_R,.Refresh_Energy-.Table
	dc.w	RAWKEY_W,.Get_All_Weapons-.Table
	dc.w	RAWKEY_O,.Get_All_Objects-.Table
	dc.w	RAWKEY_K,.Harakiri-.Table
	dc.w	RAWKEY_N,.Skip_Level-.Table
	dc.w	RAWKEY_X,.See_End-.Table
	dc.w	RAWKEY_A,.Add_One_Life-.Table
	dc.w	0


.Toggle_Unlimited_Lives
	eor.b	#$19,$31e(a0)	; subq.w #1,lives <-> tst.w lives
	rts

.Toggle_Unlimited_Energy
	eor.b	#$d5,$31e8(a0)	; sub.w d7,energy <-> tst.w energy
	rts

.Refresh_Energy
	move.w	#MAXIMUM_ENERGY,$480(a0)
	rts

.Get_All_Weapons
	add.w	#$4c35,a0
	move.b	d0,(a0)+
	move.l	d0,(a0)
	rts

.Get_All_Objects
	add.w	#$4c2a,a0
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.w	d0,(a0)
	rts

.Harakiri
	move.w	#-1,$480(a0)	; energy
	move.w	#1,$482(a0)	; player died
	move.w	#-1,$484(a0)	; 
	rts

.See_End
	move.w	#6,$432(a0)	; set level number

.Skip_Level
	st	$430(a0)
	rts


.Add_One_Life
	addq.w	#1,$48a(a0)
	rts

.Show_Help_Screen
	move.b	RawKey(pc),d0
	cmp.b	#RAWKEY_HELP,d0
	bne.b	.No_Help_Screen

	jsr	GAME_ADDRESS+$749c	; clear screen
	lea	.Help_Text(pc),a2
	jsr	GAME_ADDRESS+$83f4	; write text

	move.l	$101c+$422.w,a0
	move.l	$101c+$426.w,a1
	jsr	$101c+$8232		; dissolve

	jsr	GAME_ADDRESS+$16e4.w	; swap screens


.wait	move.b	GAME_ADDRESS+$965b,d0	; joystick 2 status
	bne.b	.exit
	move.b	RawKey(pc),d0
	cmp.b	#RAWKEY_HELP,d0
	bne.b	.wait
.exit
	
.wait2	move.b	RawKey(pc),d0
	cmp.b	#RAWKEY_HELP+1<<7,d0
	bne.b	.wait2

.No_Help_Screen
	jmp	GAME_ADDRESS+$80be

.Help_Text
	;	"012345678901234567890123456789"
	dc.b	0,0			; y/x position
	dc.b	"NINJA REMIX - HELP SCREEN",-1
	dc.b	10,0
	dc.b	"-------------------------",-1
	dc.b	20,0
	dc.b	"TOGGLE UNLIMITED LIVES     L",-1
	dc.b	30,0
	dc.b	"TOGGLE UNLIMITED ENERGY    E",-1
	dc.b	40,0
	dc.b	"REFRESH ENERGY             R",-1
	dc.b	50,0
	dc.b	"GET ALL WEAPONS            W",-1
	dc.b	60,0
	dc.b	"GET ALL OBJECTS            O",-1
	dc.b	70,0
	dc.b	"ADD A LIFE                 A",-1
	dc.b	80,0
	dc.b	"HARAKIRI                   K",-1
	dc.b	90,0
	dc.b	"SKIP LEVEL                 N",-1
	dc.b	100,0
	dc.b	"SEE END                    X",-1
	dc.b	120,0
	dc.b	"PRESS HELP OR USE JOYSTICK",-1
	dc.b	130,5
	dc.b	"TO RETURN TO GAME",-2
	CNOP	0,2


; --------------------------------------------------------------------------
; CD32 controls

Read_CD32_Pad_In_Vertical_Blank_Interrupt
	bsr	_joystick
	bsr	Handle_CD32_Buttons
	lea	$dff000,a6			; original code
	rts


Button_Table
	dc.l	JPB_BTN_BLU,RAWKEY_SPACE	; change weapon
	dc.l	JPB_BTN_GRN,RAWKEY_H		; change object
	dc.l	JPB_BTN_PLAY,RAWKEY_P		; toggle pause
	dc.l	JPB_BTN_YEL,RAWKEY_HELP		; show help screen
	dc.l	0


Handle_CD32_Buttons
	lea	Button_Table(pc),a0
	lea	joy1(pc),a1
	lea	Last_Joypad1_State(pc),a2

.Process_Buttons
	move.l	(a1),d0			; current joypad state
	move.l	(a2),d1			; previous joy state
	move.l	d0,(a2)	

	bsr.b	Handle_CD32_Button_Press
	bra.b	Handle_CD32_Button_Release


Last_Joypad1_State	dc.l	0
Release_Delay_Flag	dc.b	0
			dc.b	0

; a0.l: table with buttons to check
; d0.l: current joypad state
; d1.l: previous joypad state

Handle_CD32_Button_Press
	movem.l	d0-a6,-(a7)
.loop	movem.l	(a0)+,d2/d3
	btst	d2,d0
	beq.b	.check_next_button

	bclr	#RAWKEY_B_DELAY_RELEASE,d3
	lea	Release_Delay_Flag(pc),a1
	seq	(a1)

	; button pressed
	movem.l	d0-a6,-(a7)
	move.l	d3,d0

	lea	RawKey(pc),a0
	move.b	d0,(a0)

	jsr	GAME_ADDRESS+$94ca
	
	movem.l	(a7)+,d0-a6

.check_next_button
	tst.l	(a0)
	bne.b	.loop
	movem.l	(a7)+,d0-a6
	rts

; a0.l: table with buttons to check
; d0.l: current joypad state
; d1.l: previous joypad state

Handle_CD32_Button_Release
	movem.l	d0-a6,-(a7)
.loop	movem.l	(a0)+,d2/d3
	btst	d2,d0
	bne.b	.button_is_currently_pressed
	btst	d2,d1
	beq.b	.check_next_button

	lea	Release_Delay_Flag(pc),a1
	tst.b	(a1)
	sf	(a1)
	beq	.check_next_button

	; button released
	movem.l	d0-a6,-(a7)
	move.l	d3,d0
	or.b	#1<<7,d0

	lea	RawKey(pc),a0
	move.b	d0,(a0)

	jsr	GAME_ADDRESS+$94ca


	movem.l	(a7)+,d0-a6

.button_is_currently_pressed

.check_next_button
	tst.l	(a0)
	bne.b	.loop
	movem.l	(a7)+,d0-a6
	rts


; ---------------------------------------------------------------------------

Acknowledge_Vertical_Blank_Interrupt
	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rte

Acknowledge_Copper_Interrupt
	move.w	#1<<4,$dff09c
	move.w	#1<<4,$dff09c
	rte


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
	movem.l	d0/d1,-(a7)
	moveq	#3-1,d0
.loop	move.b	$dff006,d1
.still_same_raster_line
	cmp.b	$dff006,d1
	beq.b	.still_same_raster_line
	dbf	d0,.loop
	movem.l	(a7)+,d0/d1
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

; a0.l: file name
; ----
; d0.l : result (0 = file does not exist)
File_Exists
	movem.l	d1-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	movem.l	(a7)+,d1-a6
	rts	

; a0.l: file name
; a1.l: file data
; d0.l: file size

Save_File
	movem.l	d0-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)
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

; a0.l: pointer to routine to be called once a key has been pressed
Set_Keyboard_Custom_Routine
	move.l	a1,-(a7)
	lea	KbdCust(pc),a1
	move.l	a0,(a1)
	move.l	(a7)+,a1
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
	

.nokeys	moveq	#3-1,d1
.loop	move.b	$dff006-$dff000(a0),d0
.wait	cmp.b	$dff006-$dff000(a0),d0
	beq.b	.wait
	dbf	d1,.loop


	and.b	#~(1<<6),$e00(a1)	; set input mode
.end	move.w	#1<<3,$9c(a0)
	move.w	#1<<3,$9c(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte



Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine

; ---------------------------------------------------------------------------

;==========================================================================
; read current state of joystick & joypad
;
; original code by asman with timing fix by wepl
; "getting joypad keys (cd32)"
; http://eab.abime.net/showthread.php?t=29768
;
; adapted to single read of both joysticks thanks to Girv
;
; added detection of joystick/joypad by JOTD, thanks to EAB thread:
; http://eab.abime.net/showthread.php?p=1175551#post1175551
;
; > d0.l = port number (0,1)
;
; < d0.l = state bits set as follows
;        JPB_JOY_R	= $00
;        JPB_JOY_L 	= $01
;        JPB_JOY_D	= $02
;        JPB_JOY_U	= $03
;        JPB_BTN_PLAY	= $11
;        JPB_BTN_REVERSE	= $12
;        JPB_BTN_FORWARD	= $13
;        JPB_BTN_GRN	= $14
;        JPB_BTN_YEL	= $15
;        JPB_BTN_RED	= $16
;        JPB_BTN_BLU	= $17
; < d1.l = raw joy[01]dat value read from input port
;

	IFND	EXEC_TYPES_I
	INCLUDE	exec/types.i
	ENDC
	INCLUDE	hardware/cia.i
	INCLUDE	hardware/custom.i

	BITDEF	JP,BTN_RIGHT,0
	BITDEF	JP,BTN_LEFT,1
	BITDEF	JP,BTN_DOWN,2
	BITDEF	JP,BTN_UP,3
	BITDEF	JP,BTN_PLAY,$11
	BITDEF	JP,BTN_REVERSE,$12
	BITDEF	JP,BTN_FORWARD,$13
	BITDEF	JP,BTN_GRN,$14
	BITDEF	JP,BTN_YEL,$15
	BITDEF	JP,BTN_RED,$16
	BITDEF	JP,BTN_BLU,$17

POTGO_RESET = $FF00  	; was $FFFF but changed, thanks to robinsonb5@eab

	XDEF	_detect_controller_types
	XDEF	_read_joystick

; optional call to differentiate 2-button joystick from CD32 joypad
; default is "all joypads", but when using 2-button joystick second button,
; the problem is that all bits are set (which explains that pressing 2nd button usually
; triggers pause and/or both shoulder buttons => quit game)
;
; drawback:
; once detected, changing controller type needs game restart
;
; advantage:
; less CPU time consumed while trying to read ghost buttons
;
_detect_controller_types:
	movem.l d0/a0,-(a7)
	moveq	#0,d0
	bsr.b		.detect
	; ignore first read
	bsr	.wvbl
	moveq	#0,d0
	bsr.b		.detect
	
	lea	controller_joypad_0(pc),a0
	move.b	D0,(A0)
	
	bsr.b	.wvbl
	
	moveq	#1,d0
	bsr.b		.detect
	lea	controller_joypad_1(pc),a0
	move.b	D0,(A0)
	movem.l (a7)+,d0/a0
	rts

.wvbl:
	; wait for VBL
	lea	$DFF000,a0
	move.w	#$7FFF,intreq(a0)
.wait
	move.w	intreqr(a0),d0
	btst	#5,d0
	beq.b	.wait
	rts
.detect
	movem.l	d1-d5/a0-a1,-(a7)
	
	tst.l	d0
	bne.b	.port1

	moveq	#CIAB_GAMEPORT0,d3	; red button ( port 0 )
	moveq	#10,d4			; blue button ( port 0 )
	move.w	#$f600,d5		; for potgo port 0
	bra.b	.buttons
.port1
	moveq	#CIAB_GAMEPORT1,d3	; red button ( port 1 )
	moveq	#14,d4			; blue button ( port 1 )
	move.w	#$6f00,d5		; for potgo port 1

.buttons
	lea	$DFF000,a0
	lea	$BFE001,a1
		
	bset	d3,ciaddra(a1)		; set bit to out at ciapra
	bclr	d3,ciapra(a1)		; clr bit to in at ciapra

	move.w	d5,potgo(a0)

	moveq	#0,d0
	moveq	#10-1,d1		; read 9 times instead of 7. Only 2 last reads interest us
	bra.b	.gamecont4

.gamecont3
	tst.b	ciapra(a1)
	tst.b	ciapra(a1)
.gamecont4
	tst.b	ciapra(a1)		; wepl timing fix
	tst.b	ciapra(a1)
	tst.b	ciapra(a1)
	tst.b	ciapra(a1)
	tst.b	ciapra(a1)
	tst.b	ciapra(a1)

	move.w	potinp(a0),d2

	bset	d3,ciapra(a1)
	bclr	d3,ciapra(a1)
	
	btst	d4,d2
	bne.b	.gamecont5

	bset	d1,d0

.gamecont5
	dbf	d1,.gamecont3

	bclr	d3,ciaddra(a1)		; set bit to in at ciapra
	move.w	#POTGO_RESET,potgo(a0)	; changed from ffff to ff00, according to robinsonb5@eab
		
	or.b	#$C0,ciapra(a1)		; reset port direction

		; test only last bits
	and.w	#03,D0
		
	movem.l	(a7)+,d1-d5/a0-a1
	rts

_joystick:

	movem.l	a0,-(a7)		; put input 0 output in joy0
	moveq	#0,d0
	bsr	_read_joystick

	lea	joy0(pc),a0
	move.l	d0,(a0)		

	moveq	#1,d0
	bsr	_read_joystick

	lea	joy1(pc),a0
	move.l	d0,(a0)		
	
	movem.l	(a7)+,a0
	rts	

_read_joystick:
	IFD    IGNORE_JOY_DIRECTIONS        
	movem.l	d1-d7/a0-a1,-(a7)
	ELSE
	movem.l	d2-d7/a0-a1,-(a7)
	ENDC
	
	tst.l	d0
	bne.b	.port1

	moveq	#CIAB_GAMEPORT0,d3		; red button ( port 0 )
	moveq	#10,d4				; blue button ( port 0 )
	move.w	#$f600,d5			; for potgo port 0
	moveq	#joy0dat,d6			; port 0
	move.b	controller_joypad_0(pc),d2
	bra.b	.direction
.port1
	moveq	#CIAB_GAMEPORT1,d3		; red button ( port 1 )
	moveq	#14,d4				; blue button ( port 1 )
	move.w	#$6f00,d5			; for potgo port 1
	moveq	#joy1dat,d6			; port 1
	move.b	controller_joypad_1(pc),d2

.direction
	lea	$DFF000,a0
	lea	$BFE001,a1

	moveq	#0,d7

	IFND    IGNORE_JOY_DIRECTIONS
	move.w	0(a0,d6.w),d0			; get joystick direction
	move.w	d0,d6

	move.w	d0,d1
	lsr.w	#1,d1
	eor.w	d0,d1

	btst	#8,d1				; check joystick up
	sne	d7
	add.w	d7,d7

	btst	#0,d1				; check joystick down
	sne	d7
	add.w	d7,d7

	btst	#9,d0				; check joystick left
	sne	d7
	add.w	d7,d7

	btst	#1,d0				; check joystick right
	sne	d7
	add.w	d7,d7

	swap	d7
	ENDC
    
	;two/three buttons

	btst	d4,potinp(a0)			; check button blue (normal fire2)
	seq	d7
	add.w	d7,d7

	btst	d3,ciapra(a1)			; check button red (normal fire1)
	seq	d7
	add.w	d7,d7

	and.w	#$0300,d7			; calculate right out for
	asr.l	#2,d7				; above two buttons
	swap	d7				; like from lowlevel
	asr.w	#6,d7

	; read buttons from CD32 pad only if CD32 pad detected

	moveq	#0,d0
	tst.b	d2
	beq.b	.read_third_button
		
	bset	d3,ciaddra(a1)			; set bit to out at ciapra
	bclr	d3,ciapra(a1)			; clr bit to in at ciapra

	move.w	d5,potgo(a0)

	moveq	#8-1,d1
	bra.b	.gamecont4

.gamecont3
	tst.b	ciapra(a1)
	tst.b	ciapra(a1)
.gamecont4
	tst.b	ciapra(a1)			; wepl timing fix
	tst.b	ciapra(a1)
	tst.b	ciapra(a1)
	tst.b	ciapra(a1)
	tst.b	ciapra(a1)
	tst.b	ciapra(a1)

	move.w	potinp(a0),d2

	bset	d3,ciapra(a1)
	bclr	d3,ciapra(a1)
	
	btst	d4,d2
	bne.b	.gamecont5

	bset	d1,d0

.gamecont5
	dbf	d1,.gamecont3

	bclr	d3,ciaddra(a1)			; set bit to in at ciapra
.no_further_button_test
	move.w	#POTGO_RESET,potgo(a0)		; changed from ffff, according to robinsonb5@eab


	swap	d0				; d0 = state
	or.l	d7,d0

	IFND    IGNORE_JOY_DIRECTIONS        
	moveq	#0,d1				; d1 = raw joydat
	move.w	d6,d1
	ENDC
    
	or.b	#$C0,ciapra(a1)			; reset port direction

 	IFD    IGNORE_JOY_DIRECTIONS        
	movem.l	(a7)+,d1-d7/a0-a1
	ELSE
	movem.l	(a7)+,d2-d7/a0-a1
	ENDC
	rts

.read_third_button
        subq.l	#2,d4				; shift from DAT*Y to DAT*X
        btst	d4,potinp(a0)			; check third button
        bne.b	.no_further_button_test
        or.l	third_button_maps_to(pc),d7
        bra.b	.no_further_button_test
       
;==========================================================================

;==========================================================================

joy0		dc.l	0		
joy1		dc.l	0
third_button_maps_to:
		dc.l    JPF_BTN_PLAY
controller_joypad_0:
		dc.b	$FF	; set: joystick 0 is a joypad, else joystick
controller_joypad_1:
		dc.b	$FF

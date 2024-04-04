***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       TURBO OUTRUN WHDLOAD SLAVE           )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                               April 2024                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 04-Apr-2024	- minor code clean-up

; 03-Apr-2024	- support for 2 disk version (SPS 1064) added
;		- minor bug in keyboard patch fixed 

; 02-Apr-2024	- high score saving implemented
;		- all trainer options implemented

; 01-Apr-2024	- work started for the US version

; 01-Mar-2015	- high-scores are now encrypted
;		- ButtonWait now also checks the fire button
;		- "cool down turbo" in-game key added
;		- patch finished, more than enough for this crappy game

; 28-Feb-2015	- timing fixed/added in mainloop, game is now playable
;		  on fast machines, fix can be disabled with CUSTOM1
;		- unlimited time trainer now disabled the countdown in
;		  the "select transmission" and "choose tune up parts"
;		  screens too
;		- in-game keys added
;		- "Start at Stage" option added
;		- blitter wait added
;		- access fault fixed
;		- "no overheating" option added
;		- high-score load/save added

; 26-Feb-2015	- game works now (a0 trashed when installing 
;		  keyboard custom routine)
;		- trainers added

; 25-Feb-2015	- work started
;		- title part works


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
	INCLUDE	exec/types.i
	INCLUDE	exec/exec_lib.i
	INCLUDE	exec/io.i

	; Trainer options
	BITDEF	TR,UNLIMITED_TIME,0
	BITDEF	TR,UNLIMITED_CREDITS,1
	BITDEF	TR,NO_OVERHEATING,2
	BITDEF	TR,IN_GAME_KEYS,3

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

RAWKEY_N	= $36
RAWKEY_T	= $14
RAWKEY_O	= $18
RAWKEY_C	= $33
RAWKEY_X	= $32


KEY_RETURN	= 13

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
	dc.w	0			; ws_kickname
	dc.l	0			; ws_kicksize
	dc.w	0			; ws_kickcrc
	dc.w	.config-HEADER		; ws_config


.config	dc.b	"BW;"
	dc.b	"C1:X:Unlimited Time:",TRB_UNLIMITED_TIME+"0",";"
	dc.b	"C1:X:Unlimited Credits:",TRB_UNLIMITED_CREDITS+"0",";"
	dc.b 	"C1:X:No Overheating:",TRB_NO_OVERHEATING+"0",";"
	dc.b	"C1:X:In-Game Keys:",TRB_IN_GAME_KEYS+"0",";"
	dc.b	"C2:L:Start at Stage:Off,1,2,3,4,5,6,7,8,9,10,"
	dc.b	"11,12,13,14,15,16"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Games/TurboOutrun",0
	ENDC

.name	dc.b	"Turbo Outrun",0
.copy	dc.b	"1990 Sega / US Gold",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 2.0 (04.04.2024)",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

; ---------------------------------------------------------------------------

Determine_Version
	lea	.Tab(pc),a4
.Check_All_Entries
	movem.l	(a4)+,d0/d1/a0/a1/a2
	bsr	Disk_Load
	move.l	d1,d0
	bsr	Checksum_Area
	cmp.w	a1,d0
	beq.b	.Supported_Version_Found
	tst.l	(a4)
	bpl.b	.Check_All_Entries

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
	

.Supported_Version_Found
	jmp	.Tab(pc,a2.w)


.Tab	dc.l	0,12000,$50000,$2b90,Patch_US_Version-.Tab
	dc.l	0,512*2,$60000-$34,$f19e,Patch_Two_Disk_Version-.Tab
	dc.l	-1

; ---------------------------------------------------------------------------

Patch_US_Version
	move.l	a0,a5
	add.w	#$20,a5

	; Decrypt boot code, decrypted code is located at $0.w
	move.l	a5,a0
	add.w	#$2312,a0
	movem.l	(a0)+,d0-d2/a1-a4
.decrypt
	move.l	(a1)+,(a2)
	eor.l	d1,(a2)+
	dbf	d0,.decrypt



	; Patch boot code
	lea	PL_BOOT_CODE(pc),a0
	sub.l	a1,a1
	bsr	Apply_Patches

	; Set default level 3 interrupt
	pea	Acknowledge_Level3_Interrupt(pc)
	move.l	(a7)+,$6c.w

	; Run game
	jmp	$118.w


; ---------------------------------------------------------------------------

PL_BOOT_CODE
	PL_START
	PL_R	$460-$52	; disable drive access (loader init)
	PL_P	$4e8-$52,.Load_Game_Binary
	PL_R	$6d4-$52	; disable drive access (motor off)
	PL_P	$3ba-$52,.Patch_Game
	PL_PS	$3a8-$52,.Disable_Planes
	PL_END

.Disable_Planes
	move.w	#1<<9,$dff100
	rts

.Patch_Game
	pea	$400.w
	lea	PL_GAME(pc),a0
	move.l	(a7),a1
	bra.w	Apply_Patches

; a0.l: destination
; d0.l: offset
; d1.l: length
.Load_Game_Binary
	add.l	#2*6000,d0
	bra.w	Disk_Load

; ---------------------------------------------------------------------------

PL_GAME	PL_START
	;PL_R	$66ca		; disable drive access (step to track 20)
	PL_SA	$66e0,$66f6
	PL_P	$6738,.Load_Game_File
	PL_R	$6926		; disable drive access (motor off)
	PL_SA	$51ca,$51d0	; skip move.b #3,$11(a7)
	PL_P	$982e,Acknowledge_Copper_Interrupt
	PL_P	$9840,Acknowledge_Blitter_Interrupt
	PL_PSS	$9684,.Set_Keyboard_Routine,4
	PL_R	$9808
	PL_PS	$96aa,.Load_Highscores
	PL_PSS	$37f2,.Save_Highscores,2


	PL_IFC1X	TRB_UNLIMITED_TIME
	PL_PS	$66ce,.Toggle_Unlimited_Time
	PL_ENDIF

	PL_IFC1X	TRB_UNLIMITED_CREDITS
	PL_B	$32bc,$4a
	PL_ENDIF

	PL_IFC1X	TRB_NO_OVERHEATING
	PL_PS	$66d4,.Toggle_Overheating
	PL_ENDIF

	PL_IFC1X	TRB_IN_GAME_KEYS
	PL_PS	$66da,.Enable_In_Game_Keys
	PL_ENDIF

	PL_IFC2
	PL_PSS	$7dc,.Set_Starting_Stage,2
	PL_ENDIF

	PL_END

.HIGHSCORE_DATA_OFFSET = $17fe0

.Load_Highscores
	move.l	#.HIGHSCORE_DATA_OFFSET,d0
	bra.w	Load_Highscores


.Save_Highscores
	move.l	a0,-(a7)
	jsr	$400+$59c.w
	move.l	(a7)+,a0
	cmp.b	#KEY_RETURN,d0
	bne.b	.exit
	movem.l	d0-a6,-(a7)
	move.l	#.HIGHSCORE_DATA_OFFSET,d0
	bsr	Save_Highscores
	movem.l	(a7)+,d0-a6
.exit	rts

.Toggle_Unlimited_Time
	lea	.Time_Offsets(pc),a0
	bra.w	Toggle_Unlimited_Time

.Time_Offsets
	dc.w	$2b50+2			; "normal" time
	dc.w	$187c			; select transmission type
	dc.w	$1ac8			; "tune up" screen
	dc.w	$cb4			; time bonus


.Toggle_Overheating
	move.w	#$47ba,d0
	bra.w	Toggle_Overheating

.Cool_Down_Turbo
	move.l	#$34a60,d0
	bra.w	Clear_Overheating


.Set_Starting_Stage
	move.l	#$373d6,d0
	bra.w	Set_Starting_Stage


.Enable_In_Game_Keys
	lea	.In_Game_Keys_Enabled(pc),a0
	st	(a0)
	rts



; a0.l: destination
; d0.l: offset
; d1.l: length
.Load_Game_File
	add.l	#(2*6000)+(26*6200),d0
	bra.w	Disk_Load

.Set_Keyboard_Routine
	bsr	Init_Level2_Interrupt

	lea	.Handle_Keys(pc),a2
	move.l	a2,KbdCust-.Handle_Keys(a2)
	rts

.Handle_Keys
	bsr.b	.Handle_In_Game_Keys
	moveq	#0,d0
	move.b	Key(pc),d0
	jmp	$400+$97e0

.Handle_In_Game_Keys
	move.b	.In_Game_Keys_Enabled(pc),d0
	beq.b	.No_In_Game_Keys_Enabled

	lea	.Tab(pc),a0
	bsr	Handle_Keys

.No_In_Game_Keys_Enabled
	rts


.Tab	dc.w	RAWKEY_O,.Toggle_Overheating-.Tab
	dc.w	RAWKEY_T,.Toggle_Unlimited_Time-.Tab
	dc.w	RAWKEY_N,.Skip_Level-.Tab
	dc.w	RAWKEY_C,.Cool_Down_Turbo-.Tab
	dc.w	RAWKEY_X,.Show_End-.Tab
	dc.w	0

.Skip_Level
	st	$400+$37572
	rts

.Show_End
	move.w	#16,$400+$373d6
	bra.b	.Skip_Level
	

.In_Game_Keys_Enabled
	dc.b	0,0


; ---------------------------------------------------------------------------

Patch_Two_Disk_Version
	lea	PL_BOOTBLOCK_SPS1064(pc),a0
	lea	$60000-$34,a1
	bsr	Apply_Patches
	jmp	$60000

; ---------------------------------------------------------------------------

PL_BOOTBLOCK_SPS1064
	PL_START
	PL_P	$13c,.Load_Data
	PL_P	$78,.Patch_Game
	PL_SA	$94,$9a		; don't modify level 2 interrupt vector
	PL_ORW	$c6+2,INTF_PORTS
	PL_P	$132,Acknowledge_VBlank_Interrupt
	PL_END

.Patch_Game
	lea	PL_GAME_SPS1064(pc),a0
	lea	$400.w,a1
	bsr	Apply_Patches
	jmp	(a1)


.Load_Data
	move.l	d7,d0
	move.l	d2,d1
	addq.w	#1,d1
	mulu.w	#512*11,d0
	mulu.w	#512*11,d1
	bra.w	Disk_Load

; ---------------------------------------------------------------------------

PL_GAME_SPS1064
	PL_START
	PL_SA	$51da,$51e0	; skip move.b #3,$11(a7)
	PL_PSA	$6942,.Load_Data,$6986
	PL_SA	$8b2c,$8b38	; skip disk check
	PL_R	$6860		; disable drive access (motor off)
	PL_R	$6840		; disable drive access (motor on)
	PL_R	$68a0		; disable drive access (step to trk0)
	;PL_R	$69a6		; disable disk 2 request
	PL_NOPS	$69a6,12
	PL_R	$69a6+12

	PL_P	$93f0,Acknowledge_Copper_Interrupt
	PL_P	$9402,Acknowledge_Blitter_Interrupt
	PL_PSS	$927a,.Set_Keyboard_Routine,4
	PL_R	$93b4

	PL_PS	$92a0,.Load_Highscores
	PL_PSS	$3802,.Save_Highscores,4

	PL_IFBW
	PL_PSS	$6,.Button_Wait,2
	PL_ENDIF

	PL_IFC1X	TRB_UNLIMITED_TIME
	PL_PS	$69a6,.Toggle_Unlimited_Time
	PL_ENDIF

	PL_IFC1X	TRB_UNLIMITED_CREDITS
	PL_B	$32cc,$4a
	PL_ENDIF

	PL_IFC1X	TRB_NO_OVERHEATING
	PL_PS	$69a6+6,.Toggle_Overheating
	PL_ENDIF

	PL_IFC1X	TRB_IN_GAME_KEYS
	PL_PS	$9264,.Enable_In_Game_Keys
	PL_ENDIF

	PL_IFC2
	PL_PSS	$7ec,.Set_Starting_Stage,2
	PL_ENDIF
	PL_END

.DELAY_TIME 		= 5 
.SECONDS_MULTIPLIER 	= 10

.HIGHSCORE_DATA_OFFSET = $17b9c 


.Button_Wait
	moveq	#.DELAY_TIME*.SECONDS_MULTIPLIER,d0
	move.l	resload(pc),a0
	jsr	resload_Delay(a0)
	move.w	#$7fff,_custom+intena
	rts


.Load_Highscores
	move.l	#.HIGHSCORE_DATA_OFFSET,d0
	bra.w	Load_Highscores


.Save_Highscores
	move.l	a0,-(a7)
	jsr	$400+$5ac.w
	move.l	(a7)+,a0
	cmp.b	#KEY_RETURN,d0
	bne.b	.exit
	movem.l	d0-a6,-(a7)
	move.l	#.HIGHSCORE_DATA_OFFSET,d0
	bsr	Save_Highscores
	movem.l	(a7)+,d0-a6
.exit	rts

.Toggle_Unlimited_Time
	lea	.Time_Offsets(pc),a0
	bra.w	Toggle_Unlimited_Time

.Time_Offsets
	dc.w	$2b60+2			; "normal" time
	dc.w	$188c			; select transmission type
	dc.w	$1ad8			; "tune up" screen
	dc.w	$cc4			; time bonus


.Toggle_Overheating
	move.w	#$47ca,d0
	bra.w	Toggle_Overheating

.Cool_Down_Turbo
	move.l	#$323e4,d0
	bra.w	Clear_Overheating


.Set_Starting_Stage
	move.l	#$34d5a,d0
	bra.w	Set_Starting_Stage


.Enable_In_Game_Keys
	lea	.In_Game_Keys_Enabled(pc),a0
	st	(a0)
	lea	_custom,a0
	rts

.Set_Keyboard_Routine
	bsr	Init_Level2_Interrupt

	lea	.Handle_Keys(pc),a2
	move.l	a2,KbdCust-.Handle_Keys(a2)
	rts

.Handle_Keys
	bsr.b	.Handle_In_Game_Keys
	moveq	#0,d0
	move.b	Key(pc),d0
	jmp	$400+$938c

.Handle_In_Game_Keys
	move.b	.In_Game_Keys_Enabled(pc),d0
	beq.b	.No_In_Game_Keys_Enabled

	lea	.Tab(pc),a0
	bsr	Handle_Keys
.No_In_Game_Keys_Enabled
	rts


.Tab	dc.w	RAWKEY_O,.Toggle_Overheating-.Tab
	dc.w	RAWKEY_T,.Toggle_Unlimited_Time-.Tab
	dc.w	RAWKEY_N,.Skip_Level-.Tab
	dc.w	RAWKEY_C,.Cool_Down_Turbo-.Tab
	dc.w	RAWKEY_X,.Show_End-.Tab
	dc.w	0

.Skip_Level
	st	$400+$34ef6		; set "level complete" flag
	rts

.Show_End
	move.w	#16,$400+$34d5a		; last stage
	bra.b	.Skip_Level
	

.In_Game_Keys_Enabled
	dc.b	0,0

; a2.l: params
.Load_Data
	movem.l	(a2),d0/d1
	add.l	#270336,d0
	move.l	$400+$31db6,a0
	bra.w	Disk_Load


; ---------------------------------------------------------------------------
Acknowledge_Copper_Interrupt
	move.w	#INTF_COPER,_custom+intreq
	move.w	#INTF_COPER,_custom+intreq
	rte

Acknowledge_Blitter_Interrupt
	move.w	#INTF_BLIT,_custom+intreq
	move.w	#INTF_BLIT,_custom+intreq
	rte

Acknowledge_VBlank_Interrupt
	move.w	#INTF_VERTB,_custom+intreq
	move.w	#INTF_VERTB,_custom+intreq
	rte

; ---------------------------------------------------------------------------

HIGHSCORE_SIZE	= 1005

; d0.l: offset to highscore data in binary
Load_Highscores
	move.l	a0,-(a7)
	lea	$400.w,a1
	add.l	d0,a1

	lea	Highscore_Name(pc),a0
	bsr	File_Exists
	tst.l	d0
	beq.b	.No_Highscore_File_Found

	bsr	Load_File
	bsr.b	Decrypt_Memory

.No_Highscore_File_Found
	move.l	(a7)+,a0
	rts


Save_Highscores
	movem.l	d0-a6,-(a7)
	bsr.b	Is_Highscore_Saving_Allowed
	bne.b	.Highscore_Saving_Not_Allowed	
	movem.l	(a7),d0-a6

	lea	$400.w,a1
	add.l	d0,a1

	move.l	#HIGHSCORE_SIZE,d0
	bsr.b	Encrypt_Memory
	lea	Highscore_Name(pc),a0
	bsr	Save_File	
	bsr.b	Decrypt_Memory

.Highscore_Saving_Not_Allowed	
	movem.l	(a7)+,d0-a6
	rts

; d0.l: length of area to encrypt/decrypt
; a1.l: memory area to encrypt/decrypt

Encrypt_Memory
Decrypt_Memory
	movem.l	d0/a1,-(a7)
.loop	eor.b	#$03,(a1)+
	subq.l	#1,d0
	bne.b	.loop
	movem.l	(a7)+,d0/a1
	rts

; -----
; d0.l: result (<> 0: trainer options are enabled, no highscore saving allowed)
Is_Highscore_Saving_Allowed
	lea	.TAGS(pc),a0
	move.l	resload(pc),a1
	jsr	resload_Control(a1)
	move.l	.Trainer_Options(pc),d0
	add.l	.Starting_Level(pc),d0
	rts

.TAGS			dc.l	WHDLTAG_CUSTOM1_GET
.Trainer_Options	dc.l	0
			dc.l	WHDLTAG_CUSTOM2_GET
.Starting_Level		dc.l	0
			dc.l	TAG_DONE

Highscore_Name		dc.b	"TurboOutrun.high",0
			CNOP	0,4


; ---------------------------------------------------------------------------

; d0.l: offset to stage variable in game binary

Set_Starting_Stage
	lea	$400.w,a2
	add.l	d0,a2

	clr.l	-(a7)		; TAG_END
	clr.l	-(a7)		; data for CUSTOM2 tooltype
	pea	WHDLTAG_CUSTOM2_GET
	move.l	a7,a0
	move.l	resload(pc),a1
	jsr	resload_Control(a1)
	move.w	4+2(a7),(a2)	; starting stage
	add.w	#3*4,a7
	rts


; a0.l: table with offsets to time data
Toggle_Unlimited_Time
	lea	$400.w,a1
	move.w	(a0)+,d0	; normal time
	eor.w	#02,(a1,d0.w)
	move.w	(a0)+,d0	; select transmission type
	eor.b	#$19,(a1,d0.w)
	move.w	(a0)+,d0	; "tune up" screen
	eor.b	#$19,(a1,d0.w)
	move.w	(a0),d0		; no time bonus to avoid graphics problems
	eor.b	#$9a,(a1,d0.w)
	rts

; d0.w: offset to "Set Overheat value" in game binary
Toggle_Overheating
	lea	$400.w,a0
	add.w	d0,a0
	eor.w	#$79b9,(a0)	; move.w d0,Var <-> tst.w Var
	rts

; d0.w: offset to "Overheat" value in game binary
Clear_Overheating
	lea	$400.w,a0
	add.l	d0,a0
	clr.w	(a0)	
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
.wait1	btst	#0,_custom+vposr+1
	beq.b	.wait1
.wait2	btst	#0,_custom+vposr+1
	bne.b	.wait2
	rts



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


Flush_Cache
	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts

; ---------------------------------------------------------------------------

Acknowledge_Level3_Interrupt
	move.w	#INTF_BLIT|INTF_COPER|INTF_VERTB,_custom+intreq
	move.w	#INTF_BLIT|INTF_COPER|INTF_VERTB,_custom+intreq
	rte

; ---------------------------------------------------------------------------

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

Disk_Number	dc.b	1
		dc.b	0


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
; a1.l: data to save
; d0.l: size in bytes

Save_File
	movem.l	d0-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)
	movem.l	(a7)+,d0-a6
	rts

; a0.l: file name
; -----
; d0.l: result (0: file does not exist) 

File_Exists
	movem.l	d1-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
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

; a0.l: memory area
; d0.l: size of area to check
; ----
; d0.w: CRC16 value for memory area
Checksum_Area
	movem.l	d1-a6,-(a7)
	move.l	resload(pc),a1
	jsr	resload_CRC16(a1)
	movem.l	(a7)+,d1-a6
	rts


; ---------------------------------------------------------------------------
;
; Check_Quit_Key:
; - checks the defined quitkey and exits WHDLoad if this key
;   is pressed
;
; Set_Keyboard_Custom_Routine:
; - sets pointer to routine that should be called when a key has
;   been pressed
;
; Remove_Keyboard_Custom_Routine:
; - removes the keyboard custom rouine
;
; Enable_Keyboard_Interrupt:
; - enables level 2 (ports) interrupts
;
; Disable_Keyboard_Interrupt:
; - disables level 2 (ports) interrupts, keys will not be processed anymore
;
; Handle_Keys:
; - processes all keys in the table that is supplied in register a0 and
;   calls the routines defined for each key
;   Table has the following format:
;   dc.w RawKey_Code, dc.w Offset_To_Routine (this offset is relative to
;                                             the start of the table)
;
; Example:
; .TAB	dc.w	$36,.Skip-Level-.TAB
;	dc.w	0			; end of table

; d0.b: rawkey code

Check_Quit_Key
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	rts	

Set_Keyboard_Custom_Routine
	move.l	a0,-(a7)
	lea	KbdCust(pc),a0
	move.l	4(a7),(a0)
	move.l	(a7)+,a0
	rts

Remove_Keyboard_Custom_Routine
	move.l	a0,-(a7)
	lea	KbdCust(pc),a0
	clr.l	(a0)
	move.l	(a7)+,a0
	rts

Enable_Keyboard_Interrupt
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,_custom+intena
	rts

Disable_Keyboard_Interrupt
	move.w	#INTF_PORTS,_custom+intena
	rts

; a0.l: table with keys and corresponding routines to call

Handle_Keys
	move.l	a0,a1
	moveq	#0,d0
	move.b	RawKey(pc),d0
.check_all_key_entries
	movem.w	(a0)+,d1/d2
	cmp.w	d0,d1
	beq.b	.key_entry_found
	tst.w	(a0)
	bne.b	.check_all_key_entries
	rts	
	
.key_entry_found
	lea	RawKey(pc),a0
	sf	(a0)
	pea	Flush_Cache(pc)
	jmp	(a1,d2.w)

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

	bsr.w	Check_Quit_Key

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


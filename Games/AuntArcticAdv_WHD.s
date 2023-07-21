***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    AUNT ARCTIC ADVENTURE WHDLOAD SLAVE     )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             October 2017                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 21-Jul-2023	- level skip now works correctly for the very last level
;		  of the game (issue #6207)

; 10-Jul-2023	- CPU dependent delay for title picture (Top Shots) fixed
;		- another CPU dependent delay loop fixed
;		- in-game keys added to the WHDLoad splash screen
;		- level 2 interrupt code cleaned up a bit

; 09-Jul-2023	- patch rewritten to allow easy support for any future
;		  versions
;		- highscore/options file now only contains the relevant
;		  data instead of a full track, it is much smaller than before
;		- copperlist bug fixed
;		- Top Shots version fully supported

; 08-Jul-2023	- support for Top Shots version started

; 30-Oct-2017	- work started
;		- and finished a while later, RawDIC imager coded,
;		  Bplcon0 color bit fixes (x7), protection disabled
;		  (MFM, encrypted loader, track check), DMA wait in
;		  replayer fixed, keyboard routine rewritten, blitter
;		  waits added (x2, 68010+ only), CPU dependent delay
;		  fixed, write to $dff003 fixed, trainer options added
;		  (CUSTOM1), interrupt fixed, copperlist problem fixed,
;		  memory check disabled


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Hardware/dmabits.i
	INCLUDE	hardware/intbits.i
	INCLUDE	exec/types.i


	; Trainer options
	BITDEF	TR,UNLIMITED_LIVES,0
	BITDEF	TR,INVINCIBILITY,1
	BITDEF	TR,IN_GAME_KEYS,2

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

LAST_LEVEL	= 50

RAWKEY_E	= $12
RAWKEY_N	= $36
RAWKEY_B	= $35
RAWKEY_F	= $23
RAWKEY_W	= $11
RAWKEY_S	= $21
RAWKEY_H	= $25
RAWKEY_Y	= $15
RAWKEY_I	= $17
RAWKEY_1	= $01
RAWKEY_2	= $02

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


.config	dc.b	"C1:X:Unlimited Lives:",TRB_UNLIMITED_LIVES+"0",";"
	dc.b	"C1:X:Invincibility:",TRB_INVINCIBILITY+"0",";"
	dc.b	"C1:X:In-Game Keys:",TRB_IN_GAME_KEYS+"0",";"
	dc.b	"C2:B:Disable Blitter Wait Patches"
	dc.b	0

.name	dc.b	"Aunt Arctic Adventure",0
.copy	dc.b	"1988 Mindware",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 2.01 (21.07.2023)",10
	dc.b	10
	dc.b	"In-Game Keys:",10
	dc.b	"1/2: Toggle unlimited Lives Player 1/2",10
	dc.b	"N: Skip Level  I: Toggle Invincibility",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	bsr.b	Determine_Game_Version
	bra.b	Patch_Game

; ---------------------------------------------------------------------------

CRC_V1	= $5b72			; original release, MFM, SPS 1757
CRC_V2	= $7b66			; Top Shots re-release, DOS

Determine_Game_Version
	moveq	#0,d0
	move.l	#512*2,d1
	lea	$2000.w,a0
	bsr	Disk_Load

	move.l	d1,d0
	bsr	Checksum
	lea	.Supported_Versions(pc),a0
.Check_All_Entries
	move.w	(a0)+,d1
	cmp.w	d0,d1
	beq.b	.Supported_Version_Found

	tst.w	(a0)
	bne.b	.Check_All_Entries

	; No supported version found.
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.Supported_Version_Found
	rts

.Supported_Versions
	dc.w	CRC_V1
	dc.w	CRC_V2
	dc.w	0



; ---------------------------------------------------------------------------

; d0.w: Checksum

Patch_Game
	lea	.Patch_Table(pc),a0
.Check_All_Entries
	cmp.w	(a0)+,d0
	beq.b	.Apply_Patches
	addq.w	#2,a0
	bra.b	.Check_All_Entries


.Apply_Patches
	move.w	(a0),d0
	jmp	.Patch_Table(pc,d0.w)


.Patch_Table
	dc.w	CRC_V1,Patch_Original_Game_Version-.Patch_Table
	dc.w	CRC_V2,Patch_TopShots_Game_Version-.Patch_Table


; ---------------------------------------------------------------------------

Patch_Original_Game_Version

	; Load game
	move.l	#($4a-1)*$1770*2,d0
	move.l	#(11+1)*$1770,d1
	lea	$6de90,a0
	bsr	Disk_Load

	move.l	a0,a1
	lea	PL_ORIGINAL_GAME_VERSION(pc),a0
	bsr	Apply_Patches

	; Run game
	jmp	(a1)


PL_ORIGINAL_GAME_VERSION
	PL_START
	PL_SA	$7c9e,$7cae		; skip opening graphics.library
	PL_R	$2280			; disable protection check
	PL_P	$866e,.Loader
	PL_PS	$8624,Load_Highscores_And_Options
	PL_PS	$865e,Save_Highscores_And_Options
	PL_PSS	$82d6,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_R	$73a			; disable memory check
	PL_ORW	$8e0a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$8ffa+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$9032+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$913e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$92ae+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$4dc+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$596+2,1<<9		; set Bplcon0 color bit
	PL_PS	$280a,Fix_Audio_Access	; fix write to $dff003
	PL_PS	$1158,Acknowledge_Level3_Interrupt
	PL_PSS	$7cea,.Set_Keyboard_Routine,4
	PL_R	$106e			; end level 2 interrupt code
	PL_L	$7cae+2,$1000		; set copperlist

	PL_PSS	$2c2,Fix_CPU_Delay_60000,2
	PL_PSS	$388,Fix_CPU_Delay_10000,2

	PL_IFC2
	PL_ELSE
	PL_PSS	$3504,Wait_Blit_09f0_dff040,2
	PL_PSS	$3a84,Wait_Blit_0100_dff040,2
	PL_ENDIF


	PL_IFC1X	TRB_UNLIMITED_LIVES
	PL_W	$2c9c+2,0		; player 1
	PL_W	$2cc0+2,0		; player 2
	PL_ENDIF

	PL_IFC1X	TRB_INVINCIBILITY
	PL_B	$3266,$60
	PL_ENDIF	


	PL_IFC1X	TRB_IN_GAME_KEYS
	PL_PSS	$7cea,.Set_Keyboard_Routine_In_Game_Keys,4
	PL_ENDIF

	PL_END


.Loader	subq.w	#1,d0
	mulu.w	#$1770*2,d0
	addq.w	#1,d1
	mulu.w	#$1770,d1
	bra.w	Disk_Load

.Set_Keyboard_Routine
	pea	.Keyboard_Routine(pc)
	bra.w	Set_Keyboard_Custom_Routine

.Keyboard_Routine
	move.b	Key(pc),$6de90+$b1c0
	jmp	$6de90+$c24		; call level 2 interrupt code

.Set_Keyboard_Routine_In_Game_Keys
	pea	.Keyboard_Routine_In_Game_Keys(pc)
	bra.w	Set_Keyboard_Custom_Routine


.Keyboard_Routine_In_Game_Keys
	bsr.b	.Keyboard_Routine

	lea	.In_Game_Keys(pc),a0
	bra.w	Handle_Keys


.In_Game_Keys
	dc.w	RAWKEY_N,.Skip_Level-.In_Game_Keys
	dc.w	RAWKEY_I,.Toggle_Invincibility-.In_Game_Keys
	dc.w	RAWKEY_1,.Toggle_Unlimited_Lives_Player1-.In_Game_Keys
	dc.w	RAWKEY_2,.Toggle_Unlimited_Lives_Player2-.In_Game_Keys
	dc.w	0

.Skip_Level
	moveq	#1,d0
	cmp.w	#LAST_LEVEL,$6de90+$ac14
	bne.b	.Game_Not_Complete
	move.w	d0,$6de90+$289a		; game complete
	moveq	#0,d0			; do not set level complete

.Game_Not_Complete
	move.w	d0,$6de90+$b19a		; level complete
	rts

.Toggle_Invincibility
	eor.b	#$06,$6de90+$3266
	rts

.Toggle_Unlimited_Lives_Player1
	eor.w	#1,$6de90+$2c9c+2
	rts	

.Toggle_Unlimited_Lives_Player2
	eor.w	#1,$6de90+$2cc0+2
	rts	

; ---------------------------------------------------------------------------

Patch_TopShots_Game_Version
	; Load game
	move.l	#$c4a00,d0
	move.l	#$11a00,d1
	lea	$6de00,a0
	bsr	Disk_Load

	move.l	a0,a1
	lea	PL_TOPSHOTS_GAME_VERSION(pc),a0
	bsr	Apply_Patches

	; Run game
	jmp	(a1)


PL_TOPSHOTS_GAME_VERSION
	PL_START
	PL_SA	$0,$c
	PL_SA	$2e,$40
	PL_R	$7ca			; disable memory check
	PL_SA	$7dd4,$7de4		; skip opening graphics.library
	PL_P	$87a4,.Loader
	PL_PS	$875a,Load_Highscores_And_Options
	PL_PS	$8794,Save_Highscores_And_Options
	PL_PSS	$840c,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_ORW	$8f40+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$9130+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$9168+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$9274+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$93e4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$56c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$626+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$69a2+2,1<<9		; set Bplcon0 color bit
	PL_PS	$289a,Fix_Audio_Access	; fix write to $dff003
	PL_PS	$11e8,Acknowledge_Level3_Interrupt
	PL_PSS	$7e20,.Set_Keyboard_Routine,4
	PL_R	$10fe			; end level 2 interrupt code
	PL_L	$7de4+2,$1000		; set copperlist

	PL_PSA	$6948,Fix_CPU_Delay_200000,$6958
	PL_PSS	$352,Fix_CPU_Delay_60000,2
	PL_PSS	$418,Fix_CPU_Delay_10000,2

	PL_IFC2
	PL_ELSE
	PL_PSS	$3594,Wait_Blit_09f0_dff040,2
	PL_PSS	$3b14,Wait_Blit_0100_dff040,2
	PL_ENDIF

	PL_IFC1X	TRB_UNLIMITED_LIVES
	PL_W	$2d2c+2,0		; player 1
	PL_W	$2d50+2,0		; player 2
	PL_ENDIF

	PL_IFC1X	TRB_INVINCIBILITY
	PL_B	$32f6,$60
	PL_ENDIF	

	PL_IFC1X	TRB_IN_GAME_KEYS
	PL_PSS	$7e20,.Set_Keyboard_Routine_In_Game_Keys,4
	PL_ENDIF
	PL_END

.Loader	cmp.w	#1,d0
	bne.b	.no_special_case
	move.l	#$daa00,d0
	move.l	#$1600,d1
	bra.w	Disk_Load

.no_special_case
	mulu.w	#$1770*2,d0
	sub.l	#$14420,d0
	addq.w	#1,d1
	mulu.w	#$1770,d1
	bra.w	Disk_Load

.Set_Keyboard_Routine
	pea	.Keyboard_Routine(pc)
	bra.w	Set_Keyboard_Custom_Routine

.Keyboard_Routine
	move.b	Key(pc),$6de00+$b2f6
	jmp	$6de00+$cb4		; call level 2 interrupt code

.Set_Keyboard_Routine_In_Game_Keys
	pea	.Keyboard_Routine_In_Game_Keys(pc)
	bra.w	Set_Keyboard_Custom_Routine


.Keyboard_Routine_In_Game_Keys
	bsr.b	.Keyboard_Routine

	lea	.In_Game_Keys(pc),a0
	bra.w	Handle_Keys


.In_Game_Keys
	dc.w	RAWKEY_N,.Skip_Level-.In_Game_Keys
	dc.w	RAWKEY_I,.Toggle_Invincibility-.In_Game_Keys
	dc.w	RAWKEY_1,.Toggle_Unlimited_Lives_Player1-.In_Game_Keys
	dc.w	RAWKEY_2,.Toggle_Unlimited_Lives_Player2-.In_Game_Keys
	dc.w	0

.Skip_Level
	moveq	#1,d0
	cmp.w	#LAST_LEVEL,$6de00+$ad4a
	bne.b	.Game_Not_Complete
	move.w	d0,$6de00+$292a		; game complete
	moveq	#0,d0			; do not set level complete

.Game_Not_Complete
	move.w	d0,$6de00+$b2d0		; level complete
	rts

.Toggle_Invincibility
	eor.b	#$06,$6de00+$32f6
	rts

.Toggle_Unlimited_Lives_Player1
	eor.w	#$01,$6de00+$2d2c+2
	rts

.Toggle_Unlimited_Lives_Player2
	eor.w	#$01,$6de00+$2d50+2
	rts

; ---------------------------------------------------------------------------
; Common code for all supported game versions.

; Fix byte write to $dff003.
Fix_Audio_Access
	movem.l	d0,-(a7)		; movem so flags won't be restored
	move.b	$dff003,d0
	and.b	d1,d0
	movem.l	(a7)+,d0
	rts

; Fix CPU dependent DMA wait in replayer.
Fix_DMA_Wait
	moveq	#8,d0
	bra.w	Wait_Raster_Lines

Wait_Blit_09f0_dff040
	bsr	Wait_Blit
	move.w	#$09f0,$dff040
	rts

Wait_Blit_0100_dff040
	bsr	Wait_Blit
	move.w	#$0100,$dff040
	rts

Acknowledge_Level3_Interrupt
	move.w	d0,$dff09c
	move.w	d0,$dff09c
	rts

Fix_CPU_Delay_10000
	move.w	#10000/$34,d0
	bra.w	Wait_Raster_Lines

Fix_CPU_Delay_60000
	move.w	#60000/$34,d0
	bra.w	Wait_Raster_Lines

Fix_CPU_Delay_200000
	move.w	#200000/$34,d0
	bra.w	Wait_Raster_Lines

; ---------------------------------------------------------------------------

HIGHSCORE_LOCATION	= $1b750
HIGHSCORE_SIZE		= ($2ea+1)*4

Load_Highscores_And_Options
	move.l	a0,-(a7)
	lea	Highscore_Name(pc),a0
	bsr	File_Exists
	tst.l	d0
	beq.b	.No_Highscore_File_Found
	lea	HIGHSCORE_LOCATION,a1
	bsr	Load_File

.No_Highscore_File_Found
	move.l	(a7)+,a0
	rts

; The game saves highscores anb options, for this reason this
; routine must always be called, even if trainer options have been
; used.
Save_Highscores_And_Options
	move.l	a0,a1
	lea	Highscore_Name(pc),a0
	move.l	#HIGHSCORE_SIZE,d0
	bra.w	Save_File


Highscore_Name	dc.b	"AuntArcticAdventure.high",0
		CNOP	0,2

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

Flush_Cache
	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts

; a0.l: data
; d0.l: size
; -----
; d0.l: file size

Checksum
	movem.l	d1-a6,-(a7)
	move.l	resload(pc),a1
	jsr	resload_CRC16(a1)
	movem.l	(a7)+,d1-a6
	rts


; ---------------------------------------------------------------------------

; d0.l: offset
; d1.l: size
; a0.l: destination

Disk_Load
	movem.l	d0-a6,-(a7)
	moveq	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d0-a6
	rts


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
	movem.l	d1-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)
	movem.l	(a7)+,d1-a6
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
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,$dff09a
	rts

Disable_Keyboard_Interrupt
	move.w	#INTF_PORTS,$dff09a
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
	pea	Level2_Interrupt(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode

	move.w	#INTF_PORTS,$dff09c		; clear ports interrupt
	bra.w	Enable_Keyboard_Interrupt

Level2_Interrupt
	movem.l	d0-d1/a0-a2,-(a7)
	lea	$dff000,a0
	lea	$bfe001,a1

	btst	#INTB_PORTS,$1e+1(a0)
	beq.b	.end
	btst	#3,$bfed01-$bfe001(a1)		; keyboard interrupt requested?
	beq.b	.end

	lea	Key(pc),a2
	moveq	#0,d0
	move.b	$bfec01-$bfe001(a1),d0
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)+
	or.b	#1<<6,$bfee01-$bfe001(a1)	; set output mode

	bsr.w	Check_Quit_Key

	move.l	(a2)+,d1
	beq.b	.no_keyboard_custom_routine_set
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.no_keyboard_custom_routine_set
	
	moveq	#3,d0
	bsr	Wait_Raster_Lines

	and.b	#~(1<<6),$bfee01-$bfe001(a1)	; set input mode
.end	move.w	#INTF_PORTS,$9c(a0)
	move.w	#INTF_PORTS,$9c(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte

Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine

; ---------------------------------------------------------------------------


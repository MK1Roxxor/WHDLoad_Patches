***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      EXTERMINATOR WHDLOAD SLAVE            )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            September 2022                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 06-Jul-2ß23	- trainer options added

; 25-Sep-2022	- snoop problem when saving highscore file for the very
;		  first time fixed by using the CBSWITCH tag to set
;		  copperlist 2 location to an address with initialised
;		  copperlist 2 data ($300.w), first time I ever used this
;		  tag
;		- keyboard routine fixed (CPU dependent delay, interrupt
;		  acknowledge)
;		- 68000 quitkey support

; 11-Sep-2022	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	exec/types.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

	; Trainer options
	BITDEF	TR,UNLIMITED_ENERGY,0
	BITDEF	TR,IN_GAME_KEYS,1


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


.config	dc.b	"C1:X:Unlimited Energy:",TRB_UNLIMITED_ENERGY+"0",";"
	dc.b	"C1:X:In-Game Keys:",TRB_IN_GAME_KEYS+"0";"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Games/Exterminator",0
	ENDC

.name	dc.b	"Exterminator",0
.copy	dc.b	"1990 Audiogenic",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.2 (06.07.2023)",10
	dc.b	"In-Game Keys:",10
	dc.b	"N: Skip Level E: Refresh Energy",0

	CNOP	0,4

TAGLIST	dc.l	WHDLTAG_CBSWITCH_SET
	dc.l	0
	dc.l	TAG_DONE

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	pea	Set_Default_Copperlist2(pc)
	move.l	(a7)+,4(a0)
	jsr	resload_Control(a2)

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load boot code
	lea	$20000,a0
	move.l	#2*$1600,d0
	move.l	#$2c00,d1
	bsr	Disk_Load

	move.l	a0,a5

	; Version check
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$0A8E,d0		; SPS 1958
	beq.b	.Version_is_supported
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.Version_is_supported

	; Patch boot code
	lea	PL_BOOT(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	bsr	Initialise_Default_Copperlist2

	; Start the game
	jmp	(a5)


; ---------------------------------------------------------------------------

PL_BOOT	PL_START
	PL_SA	$6,$50		; skip video mode and extended memory check
	PL_SA	$164,$17c	; skip drive access
	PL_P	$1e0,Loader
	PL_P	$1ba,.Patch_Game
	PL_END

.Patch_Game
	lea	PL_GAME(pc),a0
	lea	$40000,a1
	bsr	Apply_Patches
	jmp	(a1)


Loader	mulu.w	#512,d0
	mulu.w	#512,d1
	bra.w	Disk_Load


; ---------------------------------------------------------------------------

Initialise_Default_Copperlist2
	lea	$300.w,a0
	move.l	#$fffffffe,(a0)
	move.l	a0,$dff084
	rts

; Called after returning to the patch after OS switch.
; The jmp (a0) is required by the CBSWITCH tag (see documentation).
; WHDLoad sets the copperlist 2 pointer to the default location ($1000.w) after
; an OS switch, this address is used by game data which leads to invalid
; copperlist 2 data. This happens when saving the highscores for the
; first time (no highscore file exists yet) for example. To avoid this, a 
; default copperlist 2 is initialised at address $300.w and set each time
; WHDLoad returns from the OS.

Set_Default_Copperlist2
	move.l	#$300,$dff084
	jmp	(a0)

; ---------------------------------------------------------------------------

PL_GAME	PL_START
	PL_P	$2f002,.Patch_Game_After_Decrunching
	PL_END

.Patch_Game_After_Decrunching
	lea	PL_GAME_DECRUNCHED(pc),a0
	lea	$400.w,a1
	bsr	Apply_Patches

	movem.l	(a7)+,d0/d1/a0
	jmp	$400.w


; ---------------------------------------------------------------------------

Highscore_Size	= 120			; check offset $877e in game binary
Highscore_Location = $400+$3d472

ROOM_COMPLETED	= $683
MAX_ENERGY	= 100
ENERGY_OFFSET	= $50
PLAYER1_VARS	= $67780
BASE_ADDRESS	= $400
UPDATE_ENERGY	= $3c2fb


RAWKEY_LOCATION	= $638
RAWKEY_N	= $36
RAWKEY_E	= $12


PL_GAME_DECRUNCHED
	PL_START
	PL_PSA	$77e,.Copylock,$10a8
	PL_P	$3986,Loader
	;PL_P	$3a32,Loader
	PL_SA	$10e2,$10fa		; skip drive access
	PL_P	$8758,.Load_Highscores
	PL_IFC1
	; if CUSTOM 1 tooltype (trainer options) has been used,
	; do nothing

	PL_ELSE
	PL_P	$878a,.Save_Highscores
	PL_ENDIF
	PL_PS	$304,.Check_Quit_Key
	PL_PS	$4a0,.Fix_Keyboard_Delay
	PL_P	$4b0,Acknowledge_Level2_Interrupt

	PL_PSS	$1e1e,Wait_Blit_01f00000_dff040,4
	PL_PSS	$1a4c,Wait_Blit_ffff_dff044,2
	PL_PSS	$1d1c,Wait_Blit_09f00000_dff040,4

	PL_IFC1X	TRB_UNLIMITED_ENERGY
	PL_B	$64ea,$4a		; sub.w d0,ENERGY(a5) -> tst.w ENERGY(a5)
	PL_B	$538e,$4a		; subq.w #1,ENERGY(a5) -> tst.
	PL_ENDIF

	PL_IFC1X	TRB_IN_GAME_KEYS
	PL_PSS	$4a6,.Check_In_Game_Keys,2
	PL_ENDIF
	PL_END


.Check_In_Game_Keys
	bclr	#6,$bfee01		; original code

	movem.l	d0-a6,-(a7)
	lea	.In_Game_Keys_Table(pc),a0
	move.b	(RAWKEY_LOCATION).w,RawKey-.In_Game_Keys_Table(a0)
	bsr	Handle_Keys
	movem.l	(a7)+,d0-a6
	rts

.In_Game_Keys_Table
	dc.w	RAWKEY_N,.Skip_Level-.In_Game_Keys_Table
	dc.w	RAWKEY_E,.Refresh_Energy_Player1-.In_Game_Keys_Table
	dc.w	0

.Skip_Level
	move.b	#12,(ROOM_COMPLETED).w
	rts

.Refresh_Energy_Player1
	lea	PLAYER1_VARS,a0
	move.l	$26(a0),a1
	move.w	#MAX_ENERGY,ENERGY_OFFSET(a1)
	st	BASE_ADDRESS+UPDATE_ENERGY
	rts



.Check_Quit_Key
	bsr.b	.Get_Key
	ror.b	d0
	not.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT

.Get_Key
	move.b	$bfec01,d0
	rts

.Fix_Keyboard_Delay
	moveq	#3,d0
	bra.w	Wait_Raster_Lines

.Load_Highscores
	lea	.Highscore_Name(pc),a0
	bsr	File_Exists
	tst.l	d0
	beq.b	.highscore_file_not_present
	lea	Highscore_Location,a1
	bsr	Load_File
.highscore_file_not_present
	rts

.Save_Highscores
	moveq	#Highscore_Size,d1
	move.l	a0,a1
	lea	.Highscore_Name(pc),a0
	bsr	Save_File
	move.l	(a7)+,$1000.w
	rts

.Highscore_Name
	dc.b	"Exterminator.high",0
	CNOP	0,2



.Copylock
	move.l	#$cc0c62c0,d0
	move.l	d0,$60.w
	rts

Wait_Blit_01f00000_dff040
	bsr	Wait_Blit
	move.l	#$01f00000,$dff040
	rts

Wait_Blit_ffff_dff044
	bsr	Wait_Blit
	move.w	#$ffff,$dff044
	rts

Wait_Blit_09f00000_dff040
	bsr	Wait_Blit
	move.l	#$09f00000,$dff040
	rts

Wait_Blit
	tst.b	$dff002
.blitter_is_busy
	btst	#6,$dff002
	bne.b	.blitter_is_busy
	rts

Acknowledge_Level2_Interrupt
	move.w	#1<<3,$dff09c
	move.w	#1<<3,$dff09c
	rte

Acknowledge_Level3_Interrupt
	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
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

Flush_Cache
	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts

; ---------------------------------------------------------------------------

; d0.l: offset (bytes)
; d1.l: length (bytes)
; a0.l: destination

Disk_Load
	movem.l	d0-a6,-(a7)
	moveq	#1,d2
	move.l	resload(pc),a1
	jsr	resload_DiskLoad(a1)
	movem.l	(a7)+,d0-a6
	rts

; a0.l: file name
; ----
; d0.l: result (0: file does not exist)

File_Exists
	movem.l	d1-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)	
	movem.l	(a7)+,d1-a6
	rts
	

; a0.l: file name
; a1.l: destination

Load_File
	movem.l	d0-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)	
	movem.l	(a7)+,d0-a6
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


***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        THE POWER  WHDLOAD SLAVE            )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            November 2022                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 13-Dec-2022	- fixes for the random generator were incorrect and
;		  caused access faults on 68000 (long read from $bfe801),
;		  random generator fixes use a different approach now

; 11-Dec-2022	- highscore loading removed from .Load_Data routine,
;		  highscore loading is now handled separately and works
;		  if no highscores have been saved yet as well
;		- highscore saving is now done separately as well and
;		  disabled if any trainer options are used
;		- support for loading and saving levels added
;		- patch is finished


; 10-Dec-2022	- in-game keys added
;		- highscore load/save added

; 06-Dec-2022	- trainer options added (unlimited time for player 1 and
;		  player 2)

; 04-Dec-2022	- code size optimised a bit
;		- delay in keyboard routine fixed
;		- 68000 quitkey support
;		- DMA wait in sample player fixed

; 29-Nov-2022	- work started
;		- protection removed, access faults fixed, OS stuff
;		  emulated (DoIO), DMA settings fixed, Bplcon0 color bit
;		  fix, wrong Bplcon0 settings fixed


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	exec/io.i
	INCLUDE	hardware/intbits.i
	INCLUDE	hardware/dmabits.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap|WHDLF_NoKbd
QUITKEY		= $59		; F10
;DEBUG


; Trainer options
TRB_UNLIMITED_TIME_PL1	= 0
TRB_UNLIMITED_TIME_PL2	= 1
TRB_IN_GAME_KEYS	= 2


RAWKEY_1		= 1
RAWKEY_2		= 2
RAWKEY_H		= $25
RAWKEY_N		= $36
	
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


.config	dc.b	"BW;"
	dc.b	"C1:X:Unlimited Time Player 1:",TRB_UNLIMITED_TIME_PL1+"0",";"
	dc.b	"C1:X:Unlimited Time Player 2:",TRB_UNLIMITED_TIME_PL2+"0",";"
	dc.b	"C1:X:In-Game Keys:",TRB_IN_GAME_KEYS+"0"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Games/ThePower",0
	ENDC

.name	dc.b	"The Power",0
.copy	dc.b	"1991 Demonware",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.2A (13.12.2022)",10
	dc.b	10
	dc.b	"In-Game Keys:",10
	dc.b	"1/2: Toggle Unlimited Time Player 1/2",10
	dc.b	"N: Skip Level  H: Collect all Hearts",0
	CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load bootblock
	lea	$fc00-$3c,a0
	moveq	#0,d0
	move.l	#$400,d1
	bsr	Disk_Load


	move.l	a0,a5

	; Version check
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$09DE,d0		; SPS 1284
	beq.b	.Is_Supported_Version

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.Is_Supported_Version

	; Patch bootblock
	lea	PL_BOOT(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; Set default level 3 interrupt
	pea	Acknowledge_Level3_Interrupt(pc)
	move.l	(a7)+,$6c.w

	; Enable needed DMA channels
	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_BLITTER|DMAF_RASTER,$dff096

	; Run game
	jmp	$3c(a5)


; ---------------------------------------------------------------------------

PL_BOOT	PL_START
	PL_SA	$68,$ac			; skip opening trackdisk.device
	PL_P	$164,.Load_Data
	PL_P	$1ac,.Disable_Protection
	PL_PS	$14e,.Patch_Game
	PL_ORW	$384+2,1<<9		; set Bplcon0 color bit
	PL_PS	$d0,.Patch_Intro_Picture
	PL_PS	$fe,.Patch_Intro_Picture2
	PL_END

.Patch_Intro_Picture
	lea	PL_PICTURE(pc),a0
	pea	$10000
.Patch_Picture
	move.l	(a7),a1
	bsr	Apply_Patches
	addq.l	#4,(a7)			; jmp = load address+4
	rts

.Patch_Intro_Picture2
	lea	PL_PICTURE(pc),a0
	pea	$40000
	bra.b	.Patch_Picture

.Patch_Game
	lea	PL_GAME(pc),a0
	lea	$10000,a1
	bsr	Apply_Patches
	jmp	$40006			; original code


; d0.l: length in bytes
; d1.l: offset (bytes)
; d2.l: destination

.Load_Data
	move.l	d2,a0
	exg	d0,d1
	bra.w	Disk_Load	


.Disable_Protection
	move.w	#$4552,d0		; return expected key
	rts



; ---------------------------------------------------------------------------

PL_PICTURE
	PL_START
	PL_W	$282+2,$5200		; fix Bplcon0 settings
	PL_IFBW
	PL_PS	$3a,.Picture_Delay
	PL_ENDIF
	PL_END

.Picture_Delay
	moveq	#5*10,d0		; display picture for 5 seconds
	move.l	resload(pc),a0
	jsr	resload_Delay(a0)
	lea	$dff000,a6		; original code
	move.w	#$c000,$9a(a6)
	rts


; ---------------------------------------------------------------------------

PL_GAME	PL_START
	PL_SA	$ee,$104		; skip protection check
	PL_P	$51a8,.Load_Data
	PL_R	$5174			; disable opening trackdisk.device
	PL_P	$516c,QUIT		; reset -> quit to DOS
	PL_PS	$53fe,.Get_Random_D0
	PL_PS	$53e0,.Get_Random_D1
	
	PL_W	$53d4,$2008		; move.l (a0),d0 -> move.l a0,d0
	PL_PSS	$55a6,.Fix_Keyboard_Delay,2
	PL_PS	$55b6,.Check_Quit_Key
	PL_PSS	$546c,Fix_DMA_Wait,2
	PL_IFC1X	TRB_UNLIMITED_TIME_PL1
	PL_B	$3cfc,$60
	PL_ENDIF
	
	PL_IFC1X	TRB_UNLIMITED_TIME_PL2
	PL_B	$3d70,$60
	PL_ENDIF

	PL_IFC1X	TRB_IN_GAME_KEYS
	PL_PS	$55c8,.Handle_In_Game_Keys
	PL_ENDIF

	PL_PSS	$12c,.Load_Highscores,4
	PL_IFC1
	PL_ELSE
	PL_PSS	$824,Save_Highscores,4
	PL_ENDIF

	PL_W	$1f5a,$4e71		; disable game disk check
	PL_PS	$1f5c,.Load_Levels

	PL_W	$1fc6,$4e71		; disable game disk check
	PL_PSS	$1fd4,Save_Levels,4

	PL_END

.Get_Random_D0
	moveq	#0,d0
	move.b	$bfe801,d0
	add.l	$dff004,d0
	rts

.Get_Random_D1
	move.w	$dff004,d0
	add.b	$bfe801,d1
	rts

.Fix_Keyboard_Delay
	moveq	#3,d0
	bra.w	Wait_Raster_Lines

.Check_Quit_Key
	not.b	d1
	move.b	d1,d0
	bsr	Check_Quit_Key
	cmp.b	#$e8,d1			; original code
	rts


; d1.b: raw key code
.Handle_In_Game_Keys
	movem.l	d0-a6,-(a7)
	ext.w	d1
	lea	.TAB(pc),a0
.check_all_keys
	movem.w	(a0)+,d0/d2
	
	cmp.w	d0,d1
	bne.b	.check_next_key
	lea	.last_key(pc),a1
	cmp.b	(a1),d1
	beq.b	.check_next_key
	move.b	d1,(a1)
	jsr	.TAB(pc,d2.w)
	bsr	Flush_Cache
	bra.b	.exit_key_handling

.check_next_key
	tst.w	(a0)
	bne.b	.check_all_keys
	clr.b	2(a0)			; clear .last_key

.exit_key_handling
	movem.l	(a7)+,d0-a6
	lea	$75e5a,a0		; original code
	rts

.TAB	dc.w	RAWKEY_1,.Toggle_Unlimited_Time_Player1-.TAB
	dc.w	RAWKEY_2,.Toggle_Unlimited_Time_Player1-.TAB
	dc.w	RAWKEY_H,.Collect_All_Hearts-.TAB
	dc.w	RAWKEY_N,.Skip_Level-.TAB
	dc.w	0			; end of tab

.last_key
	dc.b	0
	dc.b	0

.Toggle_Unlimited_Time_Player1
	eor.b	#$06,$10000+$3cfc	; bne <-> bra
	rts

.Toggle_Unlimited_Time_Player2
	eor.b	#$06,$10000+$3d70	; bne <-> bra
	rts

.Collect_All_Hearts
	clr.w	$76960
	clr.w	$75fe4
	clr.w	$76036
	rts

.Skip_Level
	st	$75e5a+$66
	st	$75e5a+$67
	st	$75e5a+$21
	rts


; d0.w: command
; d1.l: length in bytes
; d2.l: destination
; d3.l: offset (bytes)

.Load_Data
	cmp.w	#CMD_WRITE,d0
	;beq.b	.Save_Data
	cmp.w	#CMD_READ,d0
	bne.b	.exit
	move.l	d3,d0
	move.l	d2,a0
	bsr	Disk_Load
.exit	moveq	#0,d0			; no errors
	rts

.Save_Data
	cmp.l	#$400,d3
	bne.b	.no_highscore_save
	lea	Highscore_Name(pc),a0
	move.l	d2,a1
	move.l	d1,d0
	bsr	Save_File

.no_highscore_save
	bra.b	.exit
	

.Load_Highscores
	lea	Highscore_Name(pc),a0
	bsr	File_Exists
	tst.l	d0
	beq.b	.no_highscore_file_found
	bsr.b	Load_Highscores
.no_highscore_file_found

	cmp.l	#HIGHSCORE_ID,HIGHSCORE_LOCATION	; original code
	rts

.Load_Levels
	bsr	Load_Levels
	lea	LEVELS_LOCATION,a2			; original code
	rts


; ---------------------------------------------------------------------------

HIGHSCORE_LOCATION	= $5497c
HIGHSCORE_ID		= "MRPH"
HIGHSCORE_SIZE		= 512

Load_Highscores
	lea	Highscore_Name(pc),a0
	lea	HIGHSCORE_LOCATION,a1
	bra.w	Load_File

Save_Highscores
	lea	Highscore_Name(pc),a0
	lea	HIGHSCORE_LOCATION,a1
	move.l	#HIGHSCORE_SIZE,d0
	bra.w	Save_File

Highscore_Name	dc.b	"ThePower.high",0
		CNOP	0,2


; ---------------------------------------------------------------------------

LEVELS_LOCATION		= $6937c
LEVELS_SIZE		= $ca00

Load_Levels
	lea	Levels_Name(pc),a0
	lea	LEVELS_LOCATION,a1
	bra.w	Load_File

Save_Levels
	lea	Levels_Name(pc),a0
	lea	LEVELS_LOCATION,a1
	move.l	#LEVELS_SIZE,d0
	bsr	Save_File
	moveq	#0,d0			; no errors
	rts

Levels_Name	dc.b	"ThePower.levs",0
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

Acknowledge_Level3_Interrupt
	bsr.b	Acknowledge_Level3_Interrupt_Request
	rte

Acknowledge_Level3_Interrupt_Request
	move.w	#INTF_VERTB|INTF_COPER|INTF_BLIT,$dff09c
	move.w	#INTF_VERTB|INTF_COPER|INTF_BLIT,$dff09c
	rts

Acknowledge_Level6_Interrupt
	bsr.b	Acknowledge_Level6_Interrupt_Request
	rte

Acknowledge_Level6_Interrupt_Request
	move.w	#INTF_EXTER,$dff09c
	move.w	#INTF_EXTER,$dff09c
	rts

Flush_Cache
	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts


; ---------------------------------------------------------------------------

Disk_Load
	movem.l	d0-a6,-(a7)
	moveq	#1,d2			; disk number
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
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


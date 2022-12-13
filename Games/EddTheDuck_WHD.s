***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        EDD THE DUCK WHDLOAD SLAVE          )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            December 2022                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 13-Dec-2022	- more in-game keys added

; 12-Dec-2022	- work started
;		- protections removed (Copylock), byte write to
;		  volume register fixed, DMA wait in replayer fixed,
;		  interrupts fixed, keyboard routine fixed, trainer
;		  options added, highscore load/save added, ButtonWait
;		  support for title picture, 68000 quitkey support


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	exec/io.i
	INCLUDE	hardware/intbits.i
	INCLUDE	hardware/dmabits.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG


; Trainer options
TRB_UNLIMITED_LIVES	= 0
TRB_INVINCIBILITY	= 1
TRB_IN_GAME_KEYS	= 2


RAWKEY_1		= 1
RAWKEY_2		= 2
RAWKEY_R		= $13
RAWKEY_I		= $17
RAWKEY_H		= $25
RAWKEY_L		= $28
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
	dc.b	"C1:X:Unlimited Lives:",TRB_UNLIMITED_LIVES+"0",";"
	dc.b	"C1:X:Invincibility:",TRB_INVINCIBILITY+"0",";"
	dc.b	"C1:X:In-Game Keys:",TRB_IN_GAME_KEYS+"0"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Games/EddTheDuck",0
	ENDC

.name	dc.b	"Edd the Duck",0
.copy	dc.b	"1990 Impulze",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.2 (13.12.2022)",10
	dc.b	10
	dc.b	"In-Game Keys:",10
	dc.b	"L: Toggle Unlimited Lives",10
	dc.b	"I: Toggle Invincibility",10
	dc.b	"R: Refresh Lives  N: Skip Level",0
	CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load boot code
	lea	$78000-$4f2,a0
	move.l	#$b6000,d0
	move.l	#$8000,d1
	bsr	Disk_Load


	move.l	a0,a5

	; Version check
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$Ce62,d0		; SPS 0650
	beq.b	.Is_Supported_Version

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.Is_Supported_Version

	; Patch boot code
	lea	PL_BOOTCODE(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; Run game
	lea	$dff000,a6
	jmp	$4f2(a5)


; ---------------------------------------------------------------------------

PL_BOOTCODE
	PL_START
	PL_P	$f2c,Loader
	PL_SA	$560,$e42		; skip Copylock
	PL_L	$ed2,$7277c6ba		; set Copylock key
	PL_P	$e5c,.Patch_Game
	PL_IFBW
	PL_PSS	$558,.Title_Picture_Delay,2
	PL_ENDIF
	PL_END

.Title_Picture_Delay
	jsr	($78000-$4f2)+$f04	; load game code
	moveq	#5*10,d0		; show title picture for 5 seconds
	move.l	resload(pc),a0
	jsr	resload_Delay(a0)
	jmp	($78000-$4f2)+$5d00	; clear palette

.Patch_Game
	lea	PL_GAME(pc),a0
	lea	$6000,a1
	bsr	Apply_Patches
	jmp	$50006


Loader	movem.l	d1-a6,-(a7)
	move.w	d1,d0
	move.w	d2,d1
	mulu.w	#512,d0
	mulu.w	#512,d1
	bsr.w	Disk_Load
	movem.l	(a7)+,d1-a6
	moveq	#0,d0			; no errors
	rts

; ---------------------------------------------------------------------------

PL_GAME	PL_START
	PL_SA	$522c2,$52baa		; skip Copylock
	PL_L	$533e6,$7277c6ba	; set Copylock key
	PL_P	$52bdc,Loader
	PL_PSS	$4d3b0,.Acknowledge_Level3_Interrupt,2
	PL_PSA	$4d37e,.Init_Level2_Interrupt,$4d390
	PL_PSS	$51f68,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_P	$52126,Fix_Volume_Write	; fix byte write to volume register

	PL_PS	$4a506,.Load_Highscores

	PL_IFC1
	; do nothing if trainer options are enabled
	PL_ELSE
	PL_PSS	$4b03a,.Save_Highscores,2
	PL_ENDIF

	PL_IFC1X	TRB_UNLIMITED_LIVES
	PL_W	$4a5c2+2,0
	PL_ENDIF

	PL_IFC1X	TRB_INVINCIBILITY
	PL_B	$4b38c,$60
	PL_ENDIF

	PL_IFC1X	TRB_IN_GAME_KEYS
	PL_PS	$4d61c,.Enable_In_Game_Keys
	PL_ENDIF
	PL_END

.Load_Highscores
	lea	$dff000,a6
	bra.w	Load_Highscores

.Save_Highscores
	jsr	$6000+$51c32
	jsr	$6000+$4b158
	bra.w	Save_Highscores

.Acknowledge_Level3_Interrupt
	and.w	#INTF_COPER|INTF_BLIT|INTF_VERTB,d0	; original code
	move.w	d0,$9c(a0)
	move.w	d0,$9c(a0)
	rts

.Init_Level2_Interrupt
	lea	Handle_Keys(pc),a0
	move.l	a0,KbdCust-Handle_Keys(a0)
	bra.w	Init_Level2_Interrupt

.Enable_In_Game_Keys
	move.l	a0,-(a7)
	lea	Handle_In_Game_Keys(pc),a0
	move.l	a0,KbdCust-Handle_In_Game_Keys(a0)
	move.l	(a7)+,a0
	lea	$dff180,a2			; original code
	rts

Handle_Keys
	move.b	RawKey(pc),d0
	move.b	d0,$6000+$4d4ba
	jmp	$6000+$4d458

Handle_In_Game_Keys
	movem.l	d0-a6,-(a7)
	moveq	#0,d1
	move.b	RawKey(pc),d1
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
	bra.w	Handle_Keys

.TAB	dc.w	RAWKEY_I,.Toggle_Invincibility-.TAB
	dc.w	RAWKEY_N,.Skip_Level-.TAB
	dc.w	RAWKEY_L,.Toggle_Unlimited_Lives-.TAB
	dc.w	RAWKEY_R,.Refresh_Lives-.TAB
	dc.w	0			; end of tab

.last_key
	dc.b	0
	dc.b	0

.Toggle_Invincibility
	eor.b	#$06,$6000+$4b38c	; bne <-> bra
	rts

.Skip_Level
	clr.w	$6000+$4a494		; all stars collected
	rts

.Toggle_Unlimited_Lives
	eor.w	#$01,$6000+$4a5c2+2
	rts

.Refresh_Lives
	move.w	#4,$6000+$4a4f2
	rts

; ---------------------------------------------------------------------------

HIGHSCORE_LOCATION	= $6000+$4bff6
HIGHSCORE_SIZE		= $4c03c-$4bff6

Load_Highscores
	lea	Highscore_Name(pc),a0
	bsr	File_Exists
	tst.l	d0
	beq.b	.no_highscore_file_found
	lea	HIGHSCORE_LOCATION,a1
	bsr	Load_File
.no_highscore_file_found
	rts

Save_Highscores
	lea	Highscore_Name(pc),a0
	lea	HIGHSCORE_LOCATION,a1
	moveq	#HIGHSCORE_SIZE,d0
	bra.w	Save_File

Highscore_Name	dc.b	"EddTheDuck.high",0
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


Fix_Volume_Write
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
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


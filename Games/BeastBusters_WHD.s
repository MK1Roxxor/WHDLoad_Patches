***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      BEAST BUSTERS WHDLOAD SLAVE           )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              April 2023                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 15-Apr-2023	- work started
;		- self-modifying code (level 3 interrupt in replayer) fixed,
;		  keyboard routine fixed, protection removed, DMA wait
;		  in replayer and sample player fixed (x4), trainer options
;		  added, wrong call to exit replayer fixed, high score
;		  load/save added, grenades can be thrown with right mouse
;		  button (player 1) and fire button 2 (player 2)


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Hardware/dmabits.i
	INCLUDE	hardware/intbits.i
	INCLUDE	hardware/custom.i
	INCLUDE	exec/types.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

COPYLOCK_SIZE	= $954
GAME_LOCATION	= $13000-COPYLOCK_SIZE

	; Trainer option bits
	BITDEF	TR,UNLIMITED_ENERGY,0
	BITDEF	TR,UNLIMITED_AMMO,1
	BITDEF	TR,UNLIMITED_GRENADES,2
	BITDEF	TR,UNLIMITED_CREDITS,3
	
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


.config	dc.b	"C1:X:Right Mouse for Grenades (Player 1):0;"
	dc.b	"C1:X:Fire Button 2 for Grenades (Player 2):1;"
	dc.b	"C2:X:Unlimited Energy:",TRB_UNLIMITED_ENERGY+"0",";"
	dc.b	"C2:X:Unlimited Ammo:",TRB_UNLIMITED_AMMO+"0",";"
	dc.b	"C2:X:Unlimited Grenades:",TRB_UNLIMITED_GRENADES+"0",";"
	dc.b	"C2:X:Unlimited Credits:",TRB_UNLIMITED_CREDITS+"0",";"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Games/BeastBusters"
	ENDC
	dc.b	"data",0

.name	dc.b	"Beast Busters",0
.copy	dc.b	"1991 Activision",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.2 (15.04.2023)",10
	dc.b	10
	dc.b	"Grenades can always be thrown with keyboard.",10
	dc.b	"Left shift for Player 1, right shift for Player 2",0

Game_Name
	dc.b	"bbusters",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load game code
	lea	Game_Name(pc),a0
	lea	GAME_LOCATION,a1
	bsr	Load_File

	move.l	a1,a5

	; Version check
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$8F0D,d0			; SPS 1012
	beq.b	.Version_is_Supported

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.Version_is_Supported

	; Relocate game code
	move.l	a5,a0
	sub.l	a1,a1				; no tags
	jsr	resload_Relocate(a2)

	; Patch game code
	lea	PL_GAME(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	bsr	Load_High_Scores

	; And run game
	jmp	COPYLOCK_SIZE(a5)
	

; ---------------------------------------------------------------------------

RAWKEY_LOCATION		= GAME_LOCATION+$158e6
RAWKEY_LEFT_SHIFT	= $60
RAWKEY_RIGHT_SHIFT	= $61


PL_GAME	PL_START
	PL_PSS	$1b8a,.Set_Keyboard_Routine,2
	PL_P	$216e,.Load_File
	PL_P	$1ff6,.Patch_Replayer_Code
	PL_P	$42ba,.Fix_Replay_Call
	PL_PSS	$17798,Fix_DMA_Wait_104,2
	PL_PSS	$17798,Fix_DMA_Wait_50,2
	

	PL_IFC2
	; Do nothing if any trainer options have been used
	PL_ELSE
	PL_PS	$6c60,.Save_High_Scores
	PL_ENDIF

	PL_IFC1X	0
	PL_PS	$1c42,.Read_Right_Mouse_Button
	PL_ENDIF

	PL_IFC1X	1
	PL_PS	$1b64,.Initialise_POTGO
	PL_PS	$1bf6,.Read_Fire_Button2
	PL_ENDIF

	PL_IFC2X	TRB_UNLIMITED_ENERGY
	PL_B	$75fc,$60
	PL_ENDIF

	PL_IFC2X	TRB_UNLIMITED_GRENADES
	PL_B	$65ac,$4a
	PL_ENDIF

	PL_IFC2X	TRB_UNLIMITED_AMMO
	PL_B	$666e,$4a
	PL_ENDIF

	PL_IFC2X	TRB_UNLIMITED_CREDITS
	PL_B	$63dc,$4a
	PL_ENDIF
	PL_END


.Save_High_Scores
	clr.w	GAME_LOCATION+$6c8a
	bra.w	Save_High_Scores


.Right_Mouse_Button_State
	dc.b	0
.Fire_Button2_State
	dc.b	0

.Initialise_POTGO
	lea	$dff000,a5		: original code
	move.w	#$ff00,potgo(a5)
	rts

.Read_Fire_Button2
	move.w	$c(a0),d2		; original code, read JOY1DAT
	moveq	#0,d0

	; Avoid constantly throwing grenades
	lea	.Fire_Button2_State(pc),a1
	tst.b	(a1)
	beq.b	.Fire_Button2_Not_Pressed_Already
	
	btst	#14-8,$16(a0)
	beq.b	.Fire_Button2_Not_Released
	clr.b	RAWKEY_LOCATION
.Fire_Button2_Not_Pressed_Already
	
	btst	#14-8,$16(a0)
	seq	(a1)
	bne.b	.Fire_Button2_Not_Pressed
	move.b	#RAWKEY_RIGHT_SHIFT,RAWKEY_LOCATION

.Fire_Button2_Not_Pressed
.Fire_Button2_Not_Released
	rts


.Read_Right_Mouse_Button
	move.w	$A(a0),d0		; original code, read JOY0DAT
	move.w	d0,d1
	
	; Avoid constantly throwing grenades
	lea	.Right_Mouse_Button_State(pc),a1
	tst.b	(a1)
	beq.b	.Right_Mouse_Button_Not_Pressed_Already
	
	btst	#10-8,$16(a0)
	beq.b	.Right_Mouse_Button_Not_Released
	clr.b	RAWKEY_LOCATION
.Right_Mouse_Button_Not_Pressed_Already
	
	btst	#10-8,$16(a0)
	seq	(a1)
	bne.b	.Right_Mouse_Button_Not_Pressed
	move.b	#RAWKEY_LEFT_SHIFT,RAWKEY_LOCATION

.Right_Mouse_Button_Not_Pressed
.Right_Mouse_Button_Not_Released
	rts



.Set_Keyboard_Routine
	pea	.Handle_Keys(pc)
	bra.w	Set_Keyboard_Custom_Routine

.Handle_Keys
	move.b	RawKey(pc),RAWKEY_LOCATION
	rts


; a0: file data table (destination.l, size.l, file name)

.Load_File
	movem.l	d0-a6,-(a7)
	move.l	(a0)+,a1		; destination
	addq.w	#4,a0			; skip file size
	cmp.b	#":",3(a0)		; "df0:" in front of name?
	bne.b	.No_Absolute_Path
	addq.w	#4,a0			; skip "df0:"
.No_Absolute_Path
	bsr	Load_File
	jmp	GAME_LOCATION+$2bd8


; The original game code calls a wrong address to turn off the
; music replay (replayer+$1c), this patch corrects this problem.
; As the SMC for the level 3 interrupt code has been fixed too, we
; don't have to deal with restoring the level 3 interrupt vector ($6c),
; thus we simply call the "turn off sound channels" routine.
.Fix_Replay_Call
	jmp	$4a1b2+$34

.Patch_Replayer_Code
	lea	PL_REPLAY_CODE(pc),a0
	lea	$4a1b2,a1
	bsr	Apply_Patches
	st	GAME_LOCATION+$1ffe	; original code
	rts

PL_REPLAY_CODE
	PL_START
	PL_SA	$1a,$20			; don't modify level 3 interrupt code
	PL_P	$50,.Acknowledge_Level3_Interrupt
	PL_PSS	$5c2,Fix_DMA_Wait_104,2
	PL_PSS	$5d0,Fix_DMA_Wait_50,2
	PL_END

.Acknowledge_Level3_Interrupt
	move.l	$6c.w,-(a7)
	rts

Fix_DMA_Wait_104
	move.w	#$104/$34,d0
	bra.w	Wait_Raster_Lines
	
Fix_DMA_Wait_50
	move.w	#$50/$34,d0
	bra.w	Wait_Raster_Lines


; ---------------------------------------------------------------------------

HIGH_SCORE_LOCATION	= GAME_LOCATION+$12d0
HIGH_SCORE_SIZE		= $13d8-$12d0

Load_High_Scores
	lea	High_Score_Name(pc),a0
	bsr	File_Exists
	tst.l	d0
	beq.b	.High_Score_File_Not_Found
	lea	HIGH_SCORE_LOCATION,a1
	bsr	Load_File

.High_Score_File_Not_Found
	rts

Save_High_Scores
	movem.l	d0-a6,-(a7)
	lea	High_Score_Name(pc),a0
	lea	HIGH_SCORE_LOCATION,a1
	move.w	#HIGH_SCORE_SIZE,d0
	bsr	Save_File
	movem.l	(a7)+,d0-a6
	rts

High_Score_Name	dc.b	"BeastBusters.high",0
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

Set_Keyboard_Custom_Routine
	move.l	a0,-(a7)
	lea	KbdCust(pc),a0
	move.l	4(a7),(a0)
	move.l	(a7)+,a0
	rts


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


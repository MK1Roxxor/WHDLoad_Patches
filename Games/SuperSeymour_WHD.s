***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(SUPER SEYMOUR SAVES THE PLANET WHDLOAD SLAVE)*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              June 2022                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 17-Jun-2022	- in-game keys added
;		- CPU dependent DMA wait loops in replayer and sample
;		  player fixed
;		- patch is finished!

; 16-Jun-2022	- invulnerability trainer option added

; 15-Jun-2022	- hidden keyboard control enabled for testing/debugging

; 14-Jun-2022	- more trainer options added

; 13-Jun-2022	- highscore saving implemented

; 12-Jun-2022	- work started
;		- blitter waits added (x31), access faults fixed (x2),
;		  read from $dff000 disabled, buggy F10 handling disabled,
;		  trainer options added, 68000 quitkey support, 
;		  interrupts fixed
;		- highscore load added


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Hardware/dmabits.i


FLAGS			= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY			= $59		; F10
;DEBUG
ENABLE_KEYBOARD_CONTROL			; enable keyboard control for game
					; z/x to move left/right,
					; space to activate extra
					; ony works if DEBUG is set

; Trainer options
TRB_UNLIMITED_LIVES	= 0
TRB_UNLIMITED_TIME	= 1
TRB_INVULNERABILITY	= 2
TRB_IN_GAME_KEYS	= 3


BASE_ADDRESS		= $1000
RawKey_Offset		= $63438
Extras_Table_Offset	= $4a2da
Current_Extra_Offset	= $4a2e4
Draw_Extras_Routine	= $4a2f0 
INVULNERABILITY_TIME	= 400

Imploder_ID		= "IMP!"

RAWKEY_HELP		= $5f

	
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


.config	dc.b	"C1:X:Unlimited Lives:",TRB_UNLIMITED_LIVES+"0",";"
	dc.b	"C1:X:Unlimited Time:",TRB_UNLIMITED_TIME+"0",";"
	dc.b	"C1:X:Invulnerability:",TRB_INVULNERABILITY+"0",";"
	dc.b	"C1:X:In-Game-Keys:",TRB_IN_GAME_KEYS+"0",";"
	dc.b	"C2:B:Disable Blitter Waits"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Games/SuperSeymourSavesThePlanet/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Super Seymour Saves the Planet",0
.copy	dc.b	"1992 Codemasters",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.3 (17.06.2022)",10
	dc.b	"In-Game Keys: 1-5 to select extra, Help to complete level",0

Game_Name	dc.b	"sseymour.bin",0
Highscore_Name	dc.b	"Seymour.high",0
	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Load game binary
	lea	Game_Name(pc),a0
	lea	$1000.w,a1
	bsr	Load_File

	; Version check
	move.l	a1,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$BC4D,d0		; SPS 2524
	beq.b	.Version_is_Supported
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.Version_is_Supported

	; Decrunch game code (the imploder ID has been changed so
	; LoadFileDecrunch has not decrunched the file)
	lea	$1000.w,a0
	move.l	a0,a1
	move.l	#Imploder_ID,(a0)
	jsr	resload_Decrunch(a2)

	; Patch game code
	lea	PL_GAME(pc),a0
	lea	$1000.w,a1
	bsr	Apply_Patches

	bsr	Load_Highscores

	; Run game
	lea	$dff000,a6
	jmp	(a1)
	


; ---------------------------------------------------------------------------

PL_GAME	PL_START
	PL_SA	$63130,$6313a		; skip illegal
	PL_SA	$63150,$63162		; don't change exception vectors
	PL_B	$63280,$60		; disable check for F10
	PL_SA	$a6a,$a74		; skip reading from $dff000

	; Fix bug in clipping routine for bob coordinates
	PL_B	$4c8,$d4		; add.l d2,a2 -> add.w d2,a2

	; Fix bug in "play voice" routine
	PL_PS	$5c88a,.Fix_Replayer_Register_Access

	PL_PS	$63468,.Check_Quit_Key
	PL_PSS	$6349c,.Acknowledge_Level2_Interrupt,2
	PL_P	$63382,.Acknowledge_Level3_Interrupt

	; Fix CPU dependent DMA wait loops in replayer and sample player
	PL_PS	$5be7a,.Fix_DMA_Wait
	PL_PSS	$5c8f4,.Fix_DMA_Wait,2

	IFD	DEBUG
	IFD	ENABLE_KEYBOARD_CONTROL
	PL_PSS	$46b08,.Check_Fire_Button,2
	ENDC
	ENDC
	
	PL_IFC1
	; Do nothing if trainer options have been used
	PL_ELSE
	PL_PS	$2d4,.Save_Highscores
	PL_ENDIF
	

	PL_IFC1X	TRB_UNLIMITED_LIVES
	PL_B	$1a2,$4a
	PL_ENDIF

	PL_IFC1X	TRB_UNLIMITED_TIME
	PL_B	$4311a,$4a
	PL_ENDIF

	PL_IFC1X	TRB_INVULNERABILITY
	;PL_R		$34a
	PL_B	$4a088,$60
	PL_ENDIF

	PL_IFC1X	TRB_IN_GAME_KEYS
	PL_PS	$1d2,.Handle_In_Game_Keys
	PL_ENDIF
	

	; Install blitter wait patches if CUSTOM2 has not been used
	PL_IFC2
	PL_ELSE
	PL_PS	$bbe,.Wait_Blit_lsl_4_d1_d1_42
	PL_PS	$c0c,.Wait_Blit_addq_4_a0_add_40_a2
	PL_PS	$c26,.Wait_Blit_addq_4_a0_add_40_a2
	PL_PS	$c40,.Wait_Blit_addq_4_a0_add_40_a2
	PL_PS	$459b0,.Wait_Blit_lsl_4_d1_d1_42
	PL_PS	$459fe,.Wait_Blit_addq_6_a0_add_40_a2
	PL_PS	$45a18,.Wait_Blit_addq_6_a0_add_40_a2
	PL_PS	$45a32,.Wait_Blit_addq_6_a0_add_40_a2
	PL_PS	$29ff8,.Wait_Blit_dff000_a6
	PL_PS	$2a052,.Wait_Blit_dff000_a6
	PL_PS	$d44,.Wait_Blit_moveq_0_d0_d0_42
	PL_PS	$d7c,.Wait_Blit_moveq_0_d0_d0_42
	PL_PS	$dbc,.Wait_Blit_moveq_0_d0_d0_42
	PL_PS	$df4,.Wait_Blit_moveq_0_d0_d0_42
	PL_PS	$2a074,.Wait_Blit_moveq_0_d0_d0_42
	PL_PS	$618,.Wait_Blit_moveq_0_d0_d0_42
	PL_PS	$650,.Wait_Blit_moveq_0_d0_d0_42
	PL_PS	$4da,.Wait_Blit_lsl_4_d1_d1_42
	PL_PS	$528,.Wait_Blit_addq_4_a0_add_40_a2
	PL_PS	$542,.Wait_Blit_addq_4_a0_add_40_a2
	PL_PS	$55c,.Wait_Blit_addq_4_a0_add_40_a2
	PL_PS	$57a,.Wait_Blit_lsl_4_d1_d1_42
	PL_PS	$5c8,.Wait_Blit_addq_2_a0_add_40_a2
	PL_PS	$5e2,.Wait_Blit_addq_2_a0_add_40_a2
	PL_PS	$5fc,.Wait_Blit_addq_2_a0_add_40_a2
	PL_PS	$2a01a,.Wait_Blit_moveq_0_d0_d0_42

	PL_PS	$2a16a,.Wait_Blit_moveq_0_d0_d0_42
	PL_PS	$c9e,.Wait_Blit_lsl_4_d1_d1_42
	PL_PS	$cec,.Wait_Blit_addq_2_a0_add_40_a2
	PL_PS	$d06,.Wait_Blit_addq_2_a0_add_40_a2
	PL_PS	$d20,.Wait_Blit_addq_2_a0_add_40_a2
	PL_ENDIF

	PL_END


.Fix_DMA_Wait
	moveq	#4,d0
	bra.w	Wait_Raster_Lines

.Handle_In_Game_Keys
	moveq	#0,d0
	move.b	BASE_ADDRESS+RawKey_Offset,d0

	; following extras are available:
	; 1: higher jump (L icon)
	; 2: shots (S icon)
	; 3: Invulnerability or swapping joystick directions (? icon)
	; 4: trap ("square" icon)
	; 5: ? (B icon)
	cmp.b	#$01,d0
	blt.b	.no_special
	cmp.b	#$05,d0
	bgt.b	.no_special

	cmp.w	#$05,d0
	bne.b	.No_Special_Case
	moveq	#0,d0
.No_Special_Case


	move.w	d0,BASE_ADDRESS+Current_Extra_Offset
	add.w	d0,d0
	lea	BASE_ADDRESS+Extras_Table_Offset,a0
	move.w	(a0,d0.w),$1346.w

	jsr	BASE_ADDRESS+Draw_Extras_Routine	; draw the extra

	; The "?" extra has two functions: invulnerability
	; or swapping joystick directions. Game checks this
	; based on a random number value in a different routine.
	; Hence the invulnerability time must be set manually.
	cmp.w	#3,BASE_ADDRESS+Current_Extra_Offset
	bne.b	.No_Invulnerability
	move.w	#INVULNERABILITY_TIME,$1348.w
.No_Invulnerability	

	bra.w	.exit

.no_special
	cmp.b	#RAWKEY_HELP,d0
	bne.b	.No_Level_Skip
	move.w	#1,BASE_ADDRESS+$2e0.w
.No_Level_Skip

	
	
.exit	tst.b	$1000+$63545		; original code, check Escape key
	rts


	IFD	DEBUG
	IFD	ENABLE_KEYBOARD_CONTROL
; Enable keyboard control for fire button check in intro
.Check_Fire_Button
	jsr	$1000+$6359c		; get joystick state in d0.b
	eor.b	#1<<7,d0		; toggle fire button bit
	btst	#7,d0
	rts
	ENDC
	ENDC

.Save_Highscores
	jsr	$1000+$47146
	bra.w	Save_Highscores


.Acknowledge_Level2_Interrupt
	move.w	#1<<3,$dff09c
	move.w	#1<<3,$dff09c
	rts

.Acknowledge_Level3_Interrupt
	IFD	DEBUG
	IFD	ENABLE_KEYBOARD_CONTROL
	movem.l	d0-a6,-(a7)
	jsr	$1000+$6338c
	movem.l	(a7)+,d0-a6
	ENDC
	ENDC

	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte	

.Check_Quit_Key
	move.b	d0,BASE_ADDRESS+RawKey_Offset
	bra.w	Check_Quit_Key


.Fix_Replayer_Register_Access
	and.l	#$ffff,d0
	lea	$dff000,a6
	rts


.Wait_Blit_lsl_4_d1_d1_42
	bsr.w	Wait_Blit
	lsl.w	#4,d1
	move.w	d1,$42(a6)
	rts

.Wait_Blit_addq_2_a0_add_40_a2
	bsr.w	Wait_Blit
	addq.w	#2,a0
	add.w	#40,a2
	rts

.Wait_Blit_addq_4_a0_add_40_a2
	bsr.w	Wait_Blit
	addq.w	#4,a0
	add.w	#40,a2
	rts

.Wait_Blit_addq_6_a0_add_40_a2
	bsr.w	Wait_Blit
	addq.w	#6,a0
	add.w	#40,a2
	rts

.Wait_Blit_moveq_0_d0_d0_42
	bsr.w	Wait_Blit
	moveq	#0,d0
	move.w	d0,$42(a6)
	rts

.Wait_Blit_dff000_a6
	lea	$dff000,a6
	bra.w	Wait_Blit

; ---------------------------------------------------------------------------

HIGHSCORE_LOCATION	= $1000+$47068

Load_Highscores
	movem.l	d0-a6,-(a7)
	lea	Highscore_Name(pc),a0
	bsr	File_Exists
	tst.l	d0
	beq.b	.no_highscore_file_found
	lea	Highscore_Name(pc),a0
	lea	HIGHSCORE_LOCATION,a1	
	bsr	Load_File

.no_highscore_file_found
	movem.l	(a7)+,d0-a6
	rts

Save_Highscores
	movem.l	d0-a6,-(a7)
	lea	Highscore_Name(pc),a0
	lea	HIGHSCORE_LOCATION,a1	
	move.l	#$47146-$47068,d0
	bsr	Save_File
	movem.l	(a7)+,d0-a6
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


; d0.b: rawkey code

Check_Quit_Key
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	rts	



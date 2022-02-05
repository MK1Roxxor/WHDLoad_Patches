***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(          HAWKEYE WHDLOAD SLAVE             )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             February 2022                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 05-Feb-2022	- CD32 "Play" button can used to toggle pause
;		- help screen for displaying in-game keys added
;		- in-game keys are now only checked during game, during
;		  intro/high score display etc. they are not checked anymore 
;		- fade to white stuff in bootblock skipped as it doesn't
;		  work correctly and is not interesting enough to debug

; 04-Feb-2022	- CD32 pad support continued, jump with yellow button

; 03-Feb-2022	- ButtonWait support for title picture
;		- blitter wait added
;		- lots of in-game keys added
;		- starting level trainer option added
;		- leaving the "Congratulations" screen is now possible
;		  by pressing fire at any time
;		- ByteKiller decruncher relocated, error check added
;		- high score load/save added
;		- CD32 pad support started, switching weapons with
;		  forward/reverse buttons

; 02-Feb-2022	- a few loader patch fixes (upper side was not set
;		  correctly due to using clr.w instead of clr.l, track
;		  step emulation needed to step to one track less),
;		  game works now
;		- access fault in replayer fixed
;		- first trainer options (unlimited lives, unlimited energy)
;		  added
;		- keyboard interrupt rewritten, 68000 quitkey support
;		- more trainer options added (unlimited ammo, in-game keys)
;		- "Game Over" screen fixed (text wasn't displayed at all)


; 01-Feb-2022	- work started
;		- crashed when pressing fire to start level 1


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

;GAME_OVER_FIX	; if enabled, the game over screen will be fixed for fast
		; machines/emulators

MAX_LEVELS	= 12			; number of game levels

; Trainer options
TRB_LIVES		= 0		; unlimited lives
TRB_ENERGY		= 1		; unlimited energy
TRB_AMMO		= 2		; unlimited ammo
TRB_KEYS		= 3		; in-game keys

RAWKEY_Q		= $10
RAWKEY_W		= $11
RAWKEY_E		= $12
RAWKEY_R		= $13
RAWKEY_T		= $14
RAWKEY_Y		= $15		; English layout
RAWKEY_U		= $16
RAWKEY_I		= $17
RAWKEY_O		= $18
RAWKEY_P		= $19

RAWKEY_A		= $20
RAWKEY_S		= $21
RAWKEY_D		= $22
RAWKEY_F		= $23
RAWKEY_G		= $24
RAWKEY_H		= $25
RAWKEY_J		= $26
RAWKEY_K		= $27
RAWKEY_L		= $28

RAWKEY_Z		= $31		; English layout
RAWKEY_X		= $32
RAWKEY_C		= $33
RAWKEY_V		= $34
RAWKEY_B		= $35
RAWKEY_N		= $36
RAWKEY_M		= $37

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


HEADER	SLAVE_HEADER		; ws_security + ws_ID
	dc.w	17		; ws_version
	dc.w	FLAGS		; flags
	dc.l	524288		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	IFD	DEBUG
	dc.w	.dir-HEADER	; ws_CurrentDir
	ELSE
	dc.w	0
	ENDC
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_KeyDebug
	dc.b	QUITKEY		; ws_KeyExit
	dc.l	0		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"BW;"
	dc.b	"C3:B:Enable CD32 Controls;"
	dc.b	"C1:X:Unlimited Lives:",TRB_LIVES+"0",";"
	dc.b	"C1:X:Unlimited Energy:",TRB_ENERGY+"0",";"
	dc.b	"C1:X:Unlimited Ammo:",TRB_AMMO+"0",";"
	dc.b	"C1:X:In-Game Keys (Press Help during Game):",TRB_KEYS+"0",";"
	dc.b	"C2:L:Start at Level:1,2,3,4,5,6,7,8,9,10,11,12;"

	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Hawkeye",0
	ENDC

.name	dc.b	"Hawkeye",0
.copy	dc.b	"1989 Thalamus",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.1 (05.02.2022)",0

HighScoreName	dc.b	"Hawkeye.high",0

	CNOP	0,4

TAGLIST		dc.l	WHDLTAG_CUSTOM1_GET
TRAINER_OPTIONS	dc.l	0		
		dc.l	WHDLTAG_CUSTOM2_GET
STARTING_LEVEL	dc.l	0		
		dc.l	TAG_DONE

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


	; install level 2 interrupt
	bsr	SetLev2IRQ

	; detect CD32 controller
	bsr	_detect_controller_types


	; load bootblock
	lea	$1000.w,a0
	move.l	#80*$1600,d0
	move.l	#$400,d1
	move.l	a0,a5
	move.l	d1,d5
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)

	; version check
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$97E1,d0		; SPS 1963
	beq.b	.version_ok
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT


.version_ok
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)
	lea	$dff000,a6
	jmp	3*4(a5)




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


AckVBI	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte

AckVBI_R
	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rts

AckCOP	move.w	#1<<4,$dff09c
	move.w	#1<<4,$dff09c
	rte

DisableVBI
	move.w	#1<<4|1<<5|1<<6,$dff09a
	rts

EnableVBI
	move.w	#1<<15|1<<4|1<<5|1<<6,$dff09a
	rts


PLBOOT	PL_START
	PL_P	$22c,AckVBI
	PL_R	$1e8			; disable drive access (motor on)
	PL_P	$1a0,StepToTrack0
	PL_P	$1e0,.StepIn
	PL_P	$e6,LoadTracks
	PL_R	$1f6			; disable drive access (motor off)
	PL_R	$344			; disable protection check
	PL_ORW	$25c+2,1<<9		; set Bplcon0 color bit
	PL_P	$e0,.PatchGame

	PL_SA	$56,$76			; skip "fade to white" VBI stuff
	PL_IFBW
	PL_PS	$ba,.ButtonWait
	PL_ENDIF
	PL_END

.ButtonWait
	moveq	#5*10,d0
	move.l	resload(pc),a0
	jsr	resload_Delay(a0)
	lea	$10000,a0
	rts


.StepIn	lea	Track(pc),a0
	addq.w	#1,(a0)
	rts

.PatchGame
	lea	PLGAME(pc),a0
	pea	$10000
	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)


PLGAME	PL_START
	PL_P	$eaca,StepToTrack0
	PL_P	$eb2c,StepToTrack
	PL_R	$eaea			; disable CPU delay (used by loader)
	PL_R	$eaf8			; disable drive access (motor off)
	PL_R	$e932
	PL_R	$e950
	PL_P	$e89e,LoadTracks
	PL_P	$e96e,.SetSide_Upper
	PL_P	$e978,.SetSide_Lower
	PL_PSS	$13af8,AckVBI_R,2
	PL_PS	$f356,.Check_Fire
	PL_PS	$14a22,.FixReplay
	PL_PSS	$13232,.Init_Keyboard_Interrupt,4
	PL_PS	$d2cc,.WaitBlit1
	PL_P	$ef60,BK_DECRUNCH
	PL_PS	$fd6e,.LoadHighscores
	PL_P	$10420,.SaveHighscores


	; -------------------------------------------------------------------
	; Bplcon0 color bit fixes
	PL_ORW	$fef0+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$ff30+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$fdbc+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$f44c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$f454+2,1<<9		; set Bplcon0 color bit
	PL_P	$f70e,.FixBplcon0
	PL_PS	$fd74,.FixBplcon0_2

	PL_ORW	$10450+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$10458+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1387e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$13886+2,1<<9		; set Bplcon0 color bit
	

	PL_ORW	$10418+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1070a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1074a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$10a02+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$13886+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$14442+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1445e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$144ca+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$144fa+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1454a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$14576+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1458e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$145aa+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$14616+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$147d2+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$14822+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1484e+2,1<<9		; set Bplcon0 color bit
	PL_SA	$46,$4c			; skip byte write to $dff192
	PL_W	$44,$12d8		; move.b (a0),(a1)+ -> move.b (a0)+,(a1)+

	; -------------------------------------------------------------------
	; "Game Over" screen fix
	IFD	GAME_OVER_FIX
	PL_PS	$12db8,.Set_GameOver_Screen
	ENDC

	; -------------------------------------------------------------------
	; Trainer options

	; Unlimited Lives
	PL_IFC1X	TRB_LIVES
	PL_B	$e880,$4a		; subq.w #1,Lives -> tst.w Lives
	PL_ENDIF

	; Unlimited Energy
	PL_IFC1X	TRB_ENERGY
	PL_B	$de84,$4a		; sub.w d1,Energy -> tst.w Energy
	PL_ENDIF

	; Unlimited Ammo
	PL_IFC1X	TRB_AMMO
	PL_B	$e17c,$4a		; subq.b #1,(a0,d2.w) -> tst.w (a0,d2.w)
	PL_ENDIF

	; In-Game Keys
	PL_IFC1X	TRB_KEYS
	PL_PSS	$1323c,.Init_Trainer_Keys,4
	PL_ENDIF

	; Start at Level
	PL_IFC2
	PL_PSS	$13312,.Set_Starting_Level,2
	PL_PS	$1389c,.Set_Starting_Level	; after completing game
	
	PL_ENDIF

	; -------------------------------------------------------------------

	; CD32 controls
	PL_IFC3
	PL_PS	$139dc,.Read_CD32_Pad
	PL_ENDIF
	PL_END


; --------------------------------------------------------------------------
; CD32 controls

.Read_CD32_Pad
	bsr	_joystick


	move.l	joy1(pc),d0
	lea	.last(pc),a0
	cmp.l	(a0),d0
	beq.b	.exit
	move.l	d0,(a0)

	btst	#JPB_BTN_REVERSE,d0
	beq.b	.no_weapon_cycle_left

	move.b	$400+$14942,d1
	subq.b	#1,d1
	bmi.b	.no_weapon_cycle_left
	move.b	d1,$400+$14942
.no_weapon_cycle_left

	btst	#JPB_BTN_FORWARD,d0
	beq.b	.no_weapon_cycle_right

	move.b	$400+$14942,d1
	addq.b	#1,d1
	cmp.b	#4,d1
	bge.b	.no_weapon_cycle_right
	move.b	d1,$400+$14942
.no_weapon_cycle_right


	; yellow button: jump
	btst	#JPB_BTN_YEL,d0
	beq.b	.no_jump
	bset	#0,$400+$14941
.no_jump

	btst	#JPB_BTN_PLAY,d0
	beq.b	.no_pause
	not.b	$400+$13d22		; toggle pause flag
.no_pause


.exit	move.w	$dff01e,d0	
	rts

.last	dc.l	0

; --------------------------------------------------------------------------
; High score load/save

.LoadHighscores
	bsr	DisableVBI
	lea	HighScoreName(pc),a0
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.no_high_score_file

	lea	HighScoreName(pc),a0
	lea	$400+$10638,a1
	jsr	resload_LoadFile(a2)	

.no_high_score_file

	st	$400+$10632			; original code
	bra.w	EnableVBI


.SaveHighscores
	jsr	$400+$10556
	bpl.b	.high_score_achieved

.no_high_score_save	
	rts

.high_score_achieved
	jsr	$400+$10428

	move.l	TRAINER_OPTIONS(pc),d0
	add.l	STARTING_LEVEL(pc),d0
	bne.b	.no_high_score_save

	lea	HighScoreName(pc),a0
	lea	$400+$10638,a1
	move.l	#$10700-$10638,d0
	move.l	resload(pc),a2
	bsr	DisableVBI
	jsr	resload_SaveFile(a2)
	bra.w	EnableVBI

; --------------------------------------------------------------------------

.WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts

.WaitBlit1
	bsr.b	.WaitBlit
	lsl.w	#2,d1
	add.w	d1,d0
	add.w	d0,a0
	rts


; --------------------------------------------------------------------------
; This patch enables leaving the "Congratulations" screen that is shown
; when the game has been completed with fire at any time.
; Originally, this screen is shown for 16 seconds without any possibility
; to leave it.

.Check_Fire
	btst	#7,$bfe001
	bne.b	.no_Fire
	moveq	#1-1,d1				; reset loop counter

.no_Fire
	move.b	$400+$10702,d0			; VBL counter
	rts

; --------------------------------------------------------------------------

.Set_Starting_Level
	move.l	STARTING_LEVEL(pc),d0

	; 0<=starting level<=MAX_LEVELS
	cmp.w	#MAX_LEVELS,d0
	bhi.b	.invalid_level_number

	move.w	d0,$400+$1443c

.invalid_level_number
	rts


; --------------------------------------------------------------------------
	IFD	GAME_OVER_FIX

; The "Game Over" text is not shown as the text is written to
; the currently invisible screen and no screen swapping
; is performed. The fix is easy: instead of writing the text
; to the invisible screen, it is written to the currently displayed
; screen. This problem only occurs on very fast machines/emulators
; (for example WinUAE with cycle-exact chipset disabled) so applying
; it is optional.

.Set_GameOver_Screen
	move.l	$400+$148ae,a1		; write text to show screen
	rts
	ENDC

; --------------------------------------------------------------------------
; Keyboard related patches.

.Init_Keyboard_Interrupt
	bsr	SetLev2IRQ
	pea	.Store_Key(pc)

.Set_Keyboard_Custom_Routine
	lea	KbdCust(pc),a0
	move.l	(a7)+,(a0)
	rts

.Store_Key
	move.b	RawKey(pc),$400+$e3d4
	rts

.Init_Trainer_Keys
	pea	.Check_Trainer_Keys(pc)
	bra.b	.Set_Keyboard_Custom_Routine

.Check_Trainer_Keys
	bsr.b	.Store_Key

	; game VBI active?
	cmp.l	#$400+$139d8,$6c.w
	bne.b	.not_in_game

	move.b	RawKey(pc),d0
	lea	.Tab(pc),a0
.check_keys
	movem.w	(a0)+,d1/d2
	cmp.b	d0,d1
	beq.b	.key_found
	tst.w	(a0)
	bne.b	.check_keys

.not_in_game
	rts

.key_found
	jmp	.Tab(pc,d2.w)


.Tab	dc.w	RAWKEY_N,.SkipLevel-.Tab
	dc.w	RAWKEY_A,.RefreshAmmo-.Tab
	dc.w	RAWKEY_E,.RefreshEnergy-.Tab
	dc.w	RAWKEY_S,.GetAllSecrets-.Tab
	dc.w	RAWKEY_HELP,.ShowHelpScreen-.Tab
	dc.w	0			; end of table

.SkipLevel
	bset	#1,$400+$e89c		; set "level complete" status

	; if the following is not done, the enemies will not be
	; drawn correctly for the first few frames
	bset	#0,$400+$c842
	bset	#5,$400+$14941
	move.w	#936,$400+$13b12
	rts

.RefreshAmmo
	lea	$400+$e30b,a0
	moveq	#4-1,d7
.loop	move.b	#22,(a0)+
	dbf	d7,.loop
	rts

.RefreshEnergy
	move.w	#27,$400+$e0ca
	rts

.GetAllSecrets
	moveq	#4,d0			; all secrets = 4 puzzle pieces
	move.w	d0,$400+$d8e2

	move.w	d0,d2

.draw_secrets
	move.w	d2,d0

	move.w	d0,d1
	lsl.w	#1,d0
	lea	$400+$d8b4,a0		; screen offsets
	lea	$400+$1cd6c,a1		; screen
	add.w	(a0,d0.w),a1
	lsl.w	#3,d1
	lea	$400+$d8b8,a0		; secret graphics
	add.w	d1,a0
	move.b	(a0)+,(a1)
	move.b	(a0)+,1*40(a1)
	move.b	(a0)+,2*40(a1)
	move.b	(a0)+,3*40(a1)
	move.b	(a0)+,4*40(a1)
	move.b	(a0)+,5*40(a1)
	move.b	(a0)+,6*40(a1)

	subq.w	#1,d2
	bne.b	.draw_secrets
	rts


.ShowHelpScreen
	bsr	DisableVBI

	lea	.Text(pc),a0
	bsr	HS_GetScreenHeight
	addq.w	#1,d0
	mulu.w	#640/8,d0
	lea	.height(pc),a1
	move.l	d0,(a1)

	lea	$24000,a1

	; clear screen memory
	move.l	d0,d1
.cls	clr.b	(a1)+
	subq.l	#1,d1
	bne.b	.cls

	lea	$24000,a1
	bsr	ShowHelpScreen

	bsr	EnableVBI
	rts

.height	dc.l	0


.Text	dc.b	"    Hawkeye In-Game Keys",10
	dc.b	10
	dc.b	"A: Refresh Ammo       N: Skip Level",10
	dc.b	"E: Refresh Energy     S: Get all Secrets",10
	dc.b	10
	dc.b	"Press left mouse button or fire to return to game.",10
	dc.b	0
	CNOP	0,2


; --------------------------------------------------------------------------



; Fix writes to wrong audio register locations (e.g. $dffdb0 -> $dff0b0)
; caused by uninitialised index register.
.FixReplay
	moveq	#0,d4			; clear index register
	lea	$dff0a0,a5
	rts


.FixBplcon0
	move.w	#1<<9,$10000+$ff32
	move.w	#1<<9,$10000+$1074c
	rts

.FixBplcon0_2
	move.w	#1<<9,$10000+$ff32
	rts

.SetSide_Upper
	lea	Offset(pc),a0
	clr.l	(a0)
	rts

.SetSide_Lower
	lea	Offset(pc),a0
	move.l	#80*$1600,(a0)
	rts

StepToTrack0
	lea	Track(pc),a0
	clr.w	(a0)
	rts

; d7.w: track to step to -1 (dbf)
StepToTrack
	lea	Track(pc),a0
	move.w	d7,(a0)
	rts

; a0.l: destination
; d0.w: number of tracks to load-1 (dbf)

LoadTracks
	move.w	d0,d1

	move.w	Track(pc),d0
	mulu.w	#512*11,d0
	add.l	Offset(pc),d0
	addq.w	#1,d1

	lea	Track(pc),a1
	add.w	d1,(a1)

	mulu.w	#512*11,d1
	moveq	#1,d2
	move.l	resload(pc),a1


	bsr	DisableVBI
	jsr	resload_DiskLoad(a1)
	bra.w	EnableVBI

Track	dc.w	0
Offset	dc.l	0




***********************************
*** Level 2 IRQ			***
***********************************

SetLev2IRQ
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
	move.b	$c00(a1),d0
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)+
	or.b	#1<<6,$e00(a1)			; set output mode

	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT

	move.l	(a2)+,d1
	beq.b	.nocustom
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.nocustom
	

.nokeys	moveq	#3-1,d1
.loop	move.b	$6(a0),d0
.wait	cmp.b	$6(a0),d0
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

; Bytekiller decruncher
; resourced and adapted by stingray

BK_DECRUNCH
	bsr.b	.decrunch
	tst.l	d5
	beq.b	.ok

; checksum doesn't match, file corrupt
	pea	.ErrTxt(pc)
	pea	(TDREASON_FAILMSG).w
	move.l	resload(pc),a0
	jmp	resload_Abort(a0)


.ok	rts

.ErrTxt	dc.b	"Decrunching failed, file corrupt!",0
	cnop	0,4

.decrunch
	move.l	(a0)+,d0		; crunched length
	move.l	(a0)+,d1		; decrunched length
	move.l	(a0)+,d5		; checksum
	move.l	a1,a2
	add.l	d0,a0			; end of crunched data
	add.l	d1,a2			; end of decrunched data

	move.l	-(a0),d0
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
.nonew3	addx.l	d2,d2
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
;.copy	subq.w	#1,a2
;	move.b	(a2,d2.w),(a2)
;	dbf	d3,.copy

; optimised version of the code above
	subq.w	#1,d2
.copy	move.b	(a2,d2.w),-(a2)
	dbf	d3,.copy

.next	cmp.l	a2,a1
	blt.b	.loop
	rts

.nextlong
	move.l	-(a0),d0
	eor.l	d0,d5
	move.w	#$10,ccr
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
	move.w	#$10,ccr
	roxr.l	#1,d0
.nonew	addx.l	d2,d2
	dbf	d1,.getbit
	rts




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
		
		bset	d3,ciaddra(a1)	;set bit to out at ciapra
		bclr	d3,ciapra(a1)	;clr bit to in at ciapra

		move.w	d5,potgo(a0)

		moveq	#0,d0
		moveq	#10-1,d1	; read 9 times instead of 7. Only 2 last reads interest us
		bra.b	.gamecont4

.gamecont3	tst.b	ciapra(a1)
		tst.b	ciapra(a1)
.gamecont4	tst.b	ciapra(a1)	; wepl timing fix
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

.gamecont5	dbf	d1,.gamecont3

		bclr	d3,ciaddra(a1)		;set bit to in at ciapra
		move.w	#POTGO_RESET,potgo(a0)	;changed from ffff to ff00, according to robinsonb5@eab
		
		or.b	#$C0,ciapra(a1)	;reset port direction

		; test only last bits
		and.w	#03,D0
		
		movem.l	(a7)+,d1-d5/a0-a1
		rts
		
_joystick:

		movem.l	a0,-(a7)	; put input 0 output in joy0
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

		moveq	#CIAB_GAMEPORT0,d3	; red button ( port 0 )
		moveq	#10,d4			; blue button ( port 0 )
		move.w	#$f600,d5		; for potgo port 0
		moveq	#joy0dat,d6		; port 0
		move.b	controller_joypad_0(pc),d2
		bra.b	.direction
.port1
		moveq	#CIAB_GAMEPORT1,d3	; red button ( port 1 )
		moveq	#14,d4			; blue button ( port 1 )
		move.w	#$6f00,d5		; for potgo port 1
		moveq	#joy1dat,d6		; port 1
		move.b	controller_joypad_1(pc),d2

.direction
		lea	$DFF000,a0
		lea	$BFE001,a1

		moveq	#0,d7

    IFND    IGNORE_JOY_DIRECTIONS
		move.w	0(a0,d6.w),d0		;get joystick direction
		move.w	d0,d6

		move.w	d0,d1
		lsr.w	#1,d1
		eor.w	d0,d1

		btst	#8,d1	;check joystick up
		sne	d7
		add.w	d7,d7

		btst	#0,d1	;check joystick down
		sne	d7
		add.w	d7,d7

		btst	#9,d0	;check joystick left
		sne	d7
		add.w	d7,d7

		btst	#1,d0	;check joystick right
		sne	d7
		add.w	d7,d7

		swap	d7
	ENDC
    
	;two/three buttons

		btst	d4,potinp(a0)	;check button blue (normal fire2)
		seq	d7
		add.w	d7,d7

		btst	d3,ciapra(a1)	;check button red (normal fire1)
		seq	d7
		add.w	d7,d7

		and.w	#$0300,d7	;calculate right out for
		asr.l	#2,d7		;above two buttons
		swap	d7		;like from lowlevel
		asr.w	#6,d7

	; read buttons from CD32 pad only if CD32 pad detected

		moveq	#0,d0
		tst.b	d2
		beq.b	.read_third_button
		
		bset	d3,ciaddra(a1)	;set bit to out at ciapra
		bclr	d3,ciapra(a1)	;clr bit to in at ciapra

		move.w	d5,potgo(a0)

		moveq	#8-1,d1
		bra.b	.gamecont4

.gamecont3	tst.b	ciapra(a1)
		tst.b	ciapra(a1)
.gamecont4	tst.b	ciapra(a1)	; wepl timing fix
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

.gamecont5	dbf	d1,.gamecont3

		bclr	d3,ciaddra(a1)		;set bit to in at ciapra
.no_further_button_test
		move.w	#POTGO_RESET,potgo(a0)	;changed from ffff, according to robinsonb5@eab


		swap	d0		; d0 = state
		or.l	d7,d0

    IFND    IGNORE_JOY_DIRECTIONS        
		moveq	#0,d1		; d1 = raw joydat
		move.w	d6,d1
	ENDC
    
		or.b	#$C0,ciapra(a1)	;reset port direction

    IFD    IGNORE_JOY_DIRECTIONS        
		movem.l	(a7)+,d1-d7/a0-a1
    ELSE
		movem.l	(a7)+,d2-d7/a0-a1
    ENDC
		rts
.read_third_button
        subq.l  #2,d4   ; shift from DAT*Y to DAT*X
        btst	d4,potinp(a0)	;check third button
        bne.b   .no_further_button_test
        or.l    third_button_maps_to(pc),d7
        bra.b    .no_further_button_test
       
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


; --------------------------------------------------------------------------

	
; Show help screen to display in-game keys
; Does not use an own copperlist.
; StingRay, 13.02.2021
; Done for the Burning Rubber WHDLoad patch but can be used for
; other purposes too of course.

; a0.l: pointer to text
; a1.l: pointer to free memory (must be in chip) for screen data

ShowHelpScreen
	movem.l	d0-a6,-(a7)

	lea	$dff000,a6

	movem.l	a0/a1,-(a7)

	bsr.w	HS_SaveCurrentState
	bsr.w	HS_KillSys

	movem.l	(a7)+,a0/a1

	; parse text to determine screen height
	bsr	HS_GetScreenHeight
	move.w	d0,d1

	bsr	HS_WriteText	
	add.w	#$2c,d1


	; set display values for a normal hires screen
	move.w	#$2c81,$8e(a6)		; DIWSTRT
	move.w	#$2cc1,$90(a6)		; DIWSTOP
	move.w	#$3c,$92(a6)		; DDFSTRT
	move.w	#$d4,$94(a6)		; DDFSTOP
	move.w	#$9200,$100(a6)		; BPLCON0
	move.w	#$00,$102(a6)		; BPLCON1
	move.w	#$00,$104(a6)		; BPLCON2
	move.w	#$00,$108(a6)		; BPL1MOD
	move.w	#$000,$180(a6)		; COLOR00
	move.w	#$fff,$182(a6)		; COLOR01




.LOOP	bsr.w	HS_WaitVBL
	move.l	a1,$e0(a6)		; set plane pointers

	; enable bitplane DMA only
	move.w	#1<<15|1<<9|1<<8,$96(a6)

.wait	move.l	$dff004,d0
	lsr.l	#8,d0
	cmp.w	d0,d1
	bne.b	.wait

	; disable bitplane DMA
	move.w	#0<<15|1<<9|1<<8,$96(a6)

	lea	$bfe001,a0
	btst	#7,(a0)
	beq.b	.exit
	btst	#6,(a0)
	bne.b	.LOOP


.exit

.release_fire
	btst	#7,(a0)
	beq.b	.release_fire
.release_mouse
	btst	#6,(a0)
	beq.b	.release_mouse
		

	bsr.b	HS_RestoreSys

	movem.l	(a7)+,d0-a6
	rts


HS_SaveCurrentState
	lea	HS_CurrentRegs(pc),a0
	move.w	$02(a6),(a0)+		; DMA
	move.w	$1c(a6),(a0)+		; INTENA
	rts


HS_KillSys
	bsr.b	HS_WaitVBL
	move.w	#$7fff,d0
	move.w	d0,$9c(a6)		; acknowledge all interrupts
	move.w	d0,$9a(a6)
	;lsr.w	#4,d0			; d0.w: $7ff
	move.w	d0,$96(a6)
	rts

HS_RestoreSys
	bsr.b	HS_WaitVBL
	bsr.b	HS_KillSys

	lea	HS_CurrentRegs(pc),a0
	move.w	#1<<15,d0
	move.w	(a0)+,d1		; restore DMA settings
	or.w	d0,d1
	move.w	d1,$96(a6)
	move.w	(a0),d1			; restore INTENA settings
	or.w	#1<<15|1<<14,d1
	move.w	d1,$9a(a6)
	rts


HS_WaitVBL
.wait1	btst	#0,$dff004+1
	beq.b	.wait1
.wait2	btst	#0,$dff004+1
	bne.b	.wait2
	rts



HS_CurrentRegs
	dc.w	0			; DMA
	dc.w	0			; INTENA



; a0.l: text
; ----
; d0.w: screen height

HS_GetScreenHeight
	move.l	a0,-(a7)
	moveq	#0,d0			; y position
.check_chars
	move.b	(a0)+,d1
	beq.b	.end
	cmp.b	#10,d1
	bne.b	.check_chars

	addq.w	#8,d0
	bra.b	.check_chars
.end	move.l	(a7)+,a0
	rts


; a0.l: text
; a1.l: screen

HS_WriteText
	move.l	a1,a3
.newline
	moveq	#0,d0			; x position (bytes)

.write	moveq	#0,d2
	move.b	(a0)+,d2
	beq.b	.done

	cmp.b	#10,d2
	bne.b	.noLF
	add.w	#640/8*8,a3
	bra.b	.newline

.noLF

	sub.b	#" ",d2
	lsl.w	#3,d2
	lea	.Font(pc,d2.w),a2

	move.l	a3,-(a7)
	add.w	d0,a3
	moveq	#8-1,d7
.copy_char
	move.b	(a2)+,(a3)
	add.w	#640/8,a3
	dbf	d7,.copy_char

	move.l	(a7)+,a3

	addq.w	#8/8,d0
	bra.b	.write

.done	rts


.Font	DC.W	$0000,$0000,$0000,$0000,$1818,$1818,$1800,$1800
	DC.W	$6C6C,$6C00,$0000,$0000,$006C,$FE6C,$6CFE,$6C00
	DC.W	$183C,$6630,$0C66,$3C18,$00C6,$CC18,$3066,$C600
	DC.W	$0038,$6C38,$6E6C,$3A00,$3030,$3000,$0000,$0000
	DC.W	$1C30,$3030,$3030,$1C00,$380C,$0C0C,$0C0C,$3800
	DC.W	$007C,$FEFE,$FE7C,$0000,$0000,$1818,$7E18,$1800
	DC.W	$0000,$0000,$0018,$3060,$0000,$0000,$7E00,$0000
	DC.W	$0000,$0000,$0018,$1800,$0006,$0C18,$3060,$C000
	DC.W	$7CC6,$C6E6,$F6F6,$7C00,$0C0C,$0C1C,$3C3C,$3C00
	DC.W	$7C06,$067C,$E0E0,$FE00,$7C06,$061C,$0E0E,$FC00
	DC.W	$C6C6,$C67E,$0E0E,$0E00,$FEC0,$FC0E,$0E0E,$FC00
	DC.W	$7CC0,$FCCE,$CECE,$7C00,$FE06,$0C18,$3838,$3800
	DC.W	$7CC6,$C67C,$E6E6,$7C00,$7CC6,$C67E,$0E0E,$7C00
	DC.W	$0000,$3030,$0030,$3000,$0000,$1818,$0018,$3060
	DC.W	$0C18,$3070,$381C,$0E00,$0000,$FE00,$FE00,$0000
	DC.W	$3018,$0C0E,$1C38,$7000,$7CC6,$061C,$3800,$3800
	DC.W	$C0C0,$C0C0,$C0C0,$C0FF,$7CC6,$C6FE,$E6E6,$E600
	DC.W	$FCC6,$C6FC,$E6E6,$FC00,$7EC0,$C0E0,$F0F0,$7E00
	DC.W	$FCC6,$C6E6,$F6F6,$FC00,$7EC0,$C0FC,$E0E0,$7E00
	DC.W	$7EC0,$C0F8,$E0F0,$F000,$7EC0,$C0EE,$F6F6,$7E00
	DC.W	$C6C6,$C6FE,$E6E6,$E600,$1818,$1838,$7878,$7800
	DC.W	$7E06,$060E,$1E1E,$FC00,$C6CC,$D8F8,$DCDE,$DE00
	DC.W	$C0C0,$C0E0,$F0F0,$FE00,$EEFE,$D6C6,$E6F6,$F600
	DC.W	$FCC6,$C6E6,$F6F6,$F600,$7CC6,$C6E6,$F6F6,$7C00
	DC.W	$FCC6,$C6FC,$E0E0,$E000,$7CC6,$C6CE,$DEDE,$7F00
	DC.W	$FCC6,$C6FC,$CECE,$CE00,$7CC0,$C07C,$0E0E,$FC00
	DC.W	$FE18,$1838,$7878,$7800,$C6C6,$C6E6,$F6F6,$7C00
	DC.W	$CECE,$CECC,$D8F0,$E000,$E6E6,$E6F6,$FEEE,$C600
	DC.W	$C66C,$386C,$EEEE,$EE00,$C6C6,$C67E,$0E0E,$FC00
	DC.W	$FE0C,$1830,$70F0,$FE00,$3C30,$3030,$3030,$3C00
	DC.W	$00C0,$6030,$180C,$0600,$3C0C,$0C0C,$0C0C,$3C00
	DC.W	$0303,$0303,$0303,$03FF,$0000,$0000,$0000,$00FF
	DC.W	$3018,$0C00,$0000,$0000,$007C,$C6C6,$FEE6,$E600
	DC.W	$00FC,$C6FC,$E6E6,$FC00,$007C,$C0E0,$F0F0,$7E00
	DC.W	$00FC,$C6E6,$F6F6,$FC00,$007E,$C0FC,$E0E0,$7E00
	DC.W	$007E,$C0F8,$E0F0,$F000,$007E,$C0EE,$F6F6,$7E00
	DC.W	$00C6,$C6FE,$E6E6,$E600,$0018,$1818,$3878,$7800
	DC.W	$007E,$0606,$0E1E,$FC00,$00C6,$CCF8,$DCDE,$DE00
	DC.W	$00C0,$C0C0,$E0F0,$FE00,$00EE,$FED6,$E6F6,$F600
	DC.W	$00FC,$C6E6,$F6F6,$F600,$007C,$C6C6,$E6F6,$7C00
	DC.W	$00FC,$C6C6,$FCE0,$E000,$007C,$C6C6,$CEDE,$7F00
	DC.W	$00FC,$C6C6,$FCCE,$CE00,$007C,$C07C,$0E0E,$FC00
	DC.W	$00FE,$1818,$3878,$7800,$00C6,$C6C6,$E6F6,$7C00
	DC.W	$00CE,$CECC,$D8F0,$E000,$00E6,$E6F6,$FEEE,$C600
	DC.W	$00C6,$6C38,$6CEE,$EE00,$00C6,$C67E,$0E0E,$FC00
	DC.W	$00FE,$0C18,$3878,$FE00,$1E30,$3070,$3030,$1E00
	DC.W	$0303,$0303,$0303,$0303,$780C,$0C0E,$0C0C,$7800
	DC.W	$C0C0,$C0C0,$C0C0,$C0C0,$FFFF,$FFFF,$FFFF,$FFFF


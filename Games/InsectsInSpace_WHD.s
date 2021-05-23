***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      INSECTS IN SPACE WHDLOAD SLAVE        )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                               May 2021                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 22-May-2021	- bitplane DMA disabled after title picture to avoid
;		  trashed display
;		- level skip finally works correctly, was not as easy
;		  as it seemed first
;		- high score load/save added
;		- second button support added (button 2 can be used to
;		  drop a smart bomb)
;		- patch is finished for now

; 21-May-2021	- more trainer option added

; 20-May-2021	- trainer options added

; 18-May-2021	- work started

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
DEBUG

; trainer bits
TRB_LIVES	= 0		; unlimited lives
TRB_BOMBS	= 1		; unlimited bombs
TRB_BULLETS	= 2		; no enemy bullets
TRB_KEYS	= 3		; in-game keys


; second button handling
IGNORE_JOY_DIRECTIONS		; direction handling is not needed

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
	dc.w	0		; ws_CurrentDir
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


.config	dc.b	"C1:X:Unlimited Lives:",TRB_LIVES+"0",";"
	dc.b	"C1:X:Unlimited Bombs:",TRB_BOMBS+"0",";"
	dc.b	"C1:X:No Enemy Bullets:",TRB_BULLETS+"0",";"
	dc.b	"C1:X:In-Game Keys (Press Help during game):",TRB_KEYS+"0",";"
	dc.b	"C2:B:Second Button Support (Smart Bombs)"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/InsectsInSpace",0
	ENDC

.name	dc.b	"Insects in Space",0
.copy	dc.b	"1991 Hewson",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.2 (22.05.2021)",0
	CNOP	0,4

TAGLIST	dc.l	WHDLTAG_CUSTOM1_GET
CUSTOM1	dc.l	0
	dc.l	TAG_DONE

resload	dc.l	0

	INCLUDE	SOURCES:WHD_Slaves/InsectsInSpace/Helpscreen.i
	INCLUDE	SOURCES:WHD_Slaves/InsectsInSpace/ReadJoyPad.s

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

	bsr	_detect_controller_types

	; install level 2 interrupt
	bsr	SetLev2IRQ

	; load title picture
	moveq	#2-2,d0
	move.l	#12892*4,d1
	move.l	d1,d5
	moveq	#1,d2
	lea	$60000,a0
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)


	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$A37F,d0		; SPS 0829
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

	; show title picture for 5 seconds
	or.w	#1<<9,$118+2(a5)	; set Bplcon0 color bit
	jsr	(a5)
	moveq	#5*10,d0
	jsr	resload_Delay(a2)

	; avoid trashed display when loading game
	lea	$300.w,a0
	move.l	#$01000200,(a0)
	move.l	#$fffffffe,4(a0)
	move.l	a0,$dff080


	; load game
	move.l	#(16-2)*$1600,d0
	move.l	#$1ef00*4,d1
	moveq	#1,d2
	lea	$400.w,a0
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)

	; patch
	lea	PLGAME(pc),a0
	move.l	a5,a1
	add.w	#$1c,a1			; skip Atari ST header

	IFD	DEBUG
	movem.l	a0/a1,-(a7)
	clr.l	-(a7)			; TAG_DONE
	move.l	a1,-(a7)
	pea	WHDLTAG_DBGADR_SET
	move.l	a7,a0
	jsr	resload_Control(a2)
	add.w	#3*4,a7
	movem.l	(a7)+,a0/a1
	ENDC

	jsr	resload_Patch(a2)


	; and start game
	jmp	(a5)




PLGAME	PL_START
	PL_SA	$426,$45e		; don't patch exception vectors
	PL_P	$1116,AckVBI
	PL_PS	$1dec,.CheckQuit
	PL_ORW	$baee+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$bb72+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$bf26+2,1<<9		; set Bplcon0 color bit

	PL_PS	$534,.wblit1
	PL_PS	$6ff2,.wblit2
	PL_PS	$6fda,.wblit3
	PL_PS	$6fc2,.wblit4


	; unlimited lives
	PL_IFC1X	TRB_LIVES
	PL_B	$6844,$4a		; subq.w #1,Lives -> tst.w Lives
	PL_ENDIF

	; unlimited bombs	
	PL_IFC1X	TRB_BOMBS
	PL_B	$89e,$4a		; subq.w #1,Bombs -> tst.w Bombs
	PL_ENDIF

	; no enemy bullets
	PL_IFC1X	TRB_BULLETS
	PL_B	$4284,$60
	PL_W	$47a6,$4e71
	PL_W	$484e,$4e71
	PL_W	$48f8,$4e71
	PL_W	$49a2,$4e71
	PL_ENDIF


	; in-game keys
	PL_IFC1X	TRB_KEYS
	PL_PS	$1dec,.CheckInGameKeys
	PL_ENDIF


	PL_PSS	$f2e,.LoadHighScores,2

	PL_IFC1
	; If trainer options are used, do nothing.
	PL_ELSE

	; Otherwise, save high scores
	PL_P	$550,.SaveHigh
	PL_ENDIF


	PL_IFC2
	PL_P	$10e6,.AckVBIAndReadJoyPad
	PL_ELSE
	PL_P	$10e6,AckVBI
	PL_ENDIF

	PL_END


.AckVBIAndReadJoyPad
	movem.l	d0/a0,-(a7)

	bsr	_read_joysticks_buttons

	move.l	joy1_buttons(pc),d0
	btst	#JPB_BTN_BLU,d0
	beq.b	.no_button_2
	cmp.l	.last_button(pc),d0
	beq.b	.same_as_last

	move.l	d0,-(a7)
	move.b	#$80,d0			; space
	jsr	$400+$1e54+$1c.w	; store key
	move.l	(a7)+,d0


.no_button_2
	lea	.last_button(pc),a0
	move.l	d0,(a0)

.same_as_last
	movem.l	(a7)+,d0/a0
	bra.w	AckVBI

.last_button	dc.l	0


.wblit1	move.w	#$42,$58(a6)
	bra.b	.WaitBlit

.wblit2	bsr.b	.WaitBlit
	move.w	#6,$64(a6)
	rts

.wblit3	bsr.b	.WaitBlit
	move.w	#4,$64(a6)
	rts

.wblit4	bsr.b	.WaitBlit
	move.w	#2,$64(a6)
	rts

.WaitBlit
	tst.b	$02(a6)
.wb	btst	#6,$02(a6)
	bne.b	.wb
	rts

.CheckQuit
	bsr.b	.GetKey
	ror.b	d0
	not.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT


.GetKey	move.b	$bfec01,d0
	rts



.CheckInGameKeys
	bsr.b	.CheckQuit
	ror.b	d0
	not.b	d0

	move.b	$400+$387a6+$1c,d3	; mapped key

	lea	.TAB(pc),a0
.loop	movem.w	(a0)+,d1/d2
	cmp.b	d0,d1
	beq.b	.found
	cmp.b	d3,d1
	beq.b	.found

	tst.w	(a0)
	bne.b	.loop
	bra.b	.GetKey


.found	jsr	.TAB(pc,d2.w)
	bra.b	.GetKey


.TAB	dc.w	"S",.GetShield-.TAB		; S: get shield
	dc.w	"E",.NoBullets-.TAB		; E: no enemy bullets
	dc.w	"1",.GetExtraWeapon1-.TAB	; 1: get extra weapon 1
	dc.w	"2",.GetExtraWeapon2-.TAB	; 2: get extra weapon 2
	dc.w	"N",.SkipLevel-.TAB		; N: skip level, tricky!
	dc.w	"L",.AddLife-.TAB		; L: add one life
	dc.w	"B",.AddBomb-.TAB		; B: add one bomb

	dc.w	$5f,.ShowHelp-.TAB		; Help: show info screen
	dc.w	0				; end of table


.AddBomb
	addq.w	#1,$400+$c2e4+$1c
	rts

.AddLife
	addq.w	#1,$400+$c27c+$1c
	rts

.SkipLevel
	move.l	#"END",$400+$37dbc+$1c
	rts


.GetShield
	;move.w	#2000,$400+$1a5a+$1c		; shield time
	move.w	#32768,$400+$1a5a+$1c		; enable for 32768 VBL's
	move.w	#-1,$400+$1a5c+$1c
	jmp	$400+$1984+$1c.w

.NoBullets
	;move.w	#2000,$400+$1a5e+$1c		; no bullets time
	move.w	#32768,$400+$1a5e+$1c		; enable for 32768 VBL's

	move.w	#-1,$400+$1a60+$1c
	jmp	$400+$195c+$1c.w

.GetExtraWeapon1
	move.w	#-1,$400+$2a90+$1c.w
	rts

.GetExtraWeapon2
	move.w	#-1,$400+$2a92+$1c.w
	rts
	


; Routine displays a screen with the in-game keys.
; It is called if the "HELP" key is pressed during game.
; Stack space is used as Screen memory.

.ShowHelp
	lea	.Text(pc),a0
	bsr	HS_GetScreenHeight
	addq.w	#1,d0
	mulu.w	#640/8,d0
	
	; use stack space as screen memory
	; as SSP is used by the game, the USP can be safely used
	; as screen memory
	move.l	USP,a1
	move.l	a1,a6

	sub.l	d0,a1
	move.l	a1,a2

	; clear screen memory
	move.l	d0,d1
.cls	clr.b	(a1)+
	subq.l	#1,d1
	bne.b	.cls


	move.l	a2,a1

	bsr	ShowHelpScreen
	move.l	a6,USP
	rts



.Text	dc.b	"    Insects in Space In-Game Keys",10
	dc.b	10
	dc.b	"1: Get Weapon 1       2: Get Weapon 2",10
	dc.b	"S: Get Shield         E: No Enemy Bullets",10
	dc.b	"N: Skip Level         B: Add Bomb",10
	dc.b	"L: Add Life",10
	dc.b	10
	dc.b	"Press left mouse button or fire to return to game.",10
	dc.b	0

.HighName	dc.b	"InsectsInSpace.high",0

	CNOP	0,2



.SaveHigh

.game_loop
	jsr	$400+$f14+$1c.w		; run intro
	jsr	$400+$64e+$1c.w		; run game

	; If high score has been achieved, the
	; vertical blank interrupt points to the intro/high score
	; routine.
	cmp.l	#$400+$1052+$1c,$6c.w	; game VBI?
	beq.b	.no_highscore_achieved

	bsr.b	.SaveHighscores

.no_highscore_achieved
	bra.b	.game_loop


.LoadHighScores
	lea	.HighName(pc),a0
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.noHighscoreFile

	lea	.HighName(pc),a0
	lea	$400+$c885+$1c,a1
	jsr	resload_LoadFile(a2)		


.noHighscoreFile
	jsr	$400+$20ea+$1c.w
	jmp	$400+$1908+$1c.w
	


.SaveHighscores
	lea	.HighName(pc),a0
	lea	$400+$c885+$1c,a1
	move.l	#$ce52-$c885,d0
	move.l	resload(pc),a2
	jmp	resload_SaveFile(a2)



; ---------------------------------------------------------------------------



QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)


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

	move.b	$c00(a1),d0
	not.b	d0
	ror.b	d0

	or.b	#1<<6,$e00(a1)			; set output mode

	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT

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


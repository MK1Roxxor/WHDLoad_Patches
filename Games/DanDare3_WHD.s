***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       DAN DARE III WHDLOAD SLAVE           )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             October 2018                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 30-Oct-2018	- high score load/save added
;		- more trainer options added
;		- in-game keys disabled when entering high score name
;		- added help screen which displays the in-game keys, for
;		  that the write routine of the game is used

; 29-Oct-2018	- work started
;		- all OS stuff patched (AllocMem, file loading), lots
;		  of trainer options added, blitter waits added (x2),
;		  timing in shop fixed, DMA wait in replayer fixed,
;		  protection removed, keyboard routine rewritten, interrupt
;		  fixed


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $46		; Del
DEBUG

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
	dc.w	.dir-HEADER	; ws_CurrentDir
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


.config	dc.b	"C1:X:Unlimited Lives:0;"
	dc.b	"C1:X:Unlimited Energy:1;"
	dc.b	"C1:X:Unlimited Ammo:2;"
	dc.b	"C1:X:Unlimited Fuel:3;"
	dc.b	"C1:X:Unlimited Money:4;"
	dc.b	"C1:X:Start with max. Money:5;"
	dc.b	"C1:X:Start with all Extras:6;"
	dc.b	"C1:X:In-Game Keys (Press HELP during game):7;"
	dc.b	"C2:L:Start at Level:1,2,3,4,5"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/DanDare3/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Dan Dare III",0
.copy	dc.b	"1990 Virgin",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.1 (30.10.2018)",0
Name	dc.b	"dan",0
HighName	dc.b	"Dan.high",0
	CNOP	0,2


TAGLIST	dc.l	WHDLTAG_CUSTOM2_GET
LEVEL	dc.l	0
	dc.l	TAG_DONE

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

; install keyboard irq
	bsr	SetLev2IRQ

	pea	StoreKey(pc)
; load game
	lea	Name(pc),a0
	move.l	(a7)+,KbdCust-Name(a0)
	lea	$2000.w,a1
	move.l	a1,a5
	jsr	resload_LoadFileDecrunch(a2)

	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$905e,d0		; SPS 2257
	beq.b	.ok

.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

; relocate
	move.l	a5,a0
	sub.l	a1,a1
	jsr	resload_Relocate(a2)


; patch
	lea	PLGAME(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

; load high scores
	lea	HighName(pc),a0
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.noHigh
	lea	HighName(pc),a0
	lea	$15cb(a5),a1
	jsr	resload_LoadFile(a2)
.noHigh


	move.l	LEVEL(pc),d0
	cmp.w	#5,d0
	bcs.b	.level_ok
	moveq	#4,d0
.level_ok
	move.w	d0,$52a+2(a5)

	pea	AckVBI(pc)
	move.l	(a7)+,$6c.w

; and start
	jmp	(a5)


AckVBI	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte

StoreKey
	move.b	d0,$2000+$ce48
	rts

PLGAME	PL_START
	PL_PSA	$58,.AllocMem,$68
	PL_PSA	$84,.AllocMem,$9a
	PL_SA	$1b4,$212		; don't open dos.library
	PL_P	$9298,.LoadFile
	PL_SA	$23e,$266		; don't load and execute protection code
	PL_PS	$284,.PatchReplayer
	;PL_SA	$1716,$171e		; skip Atari ST code


; unlimited lives
	PL_IFC1X	0
	PL_W	$24d0+2,0
	PL_ENDIF

; unlimited energy
	PL_IFC1X	1
	PL_B	$2784,$4a		; sub.w d0,energy -> tst.w energy
	PL_W	$3b3c+2,0
	PL_ENDIF

; unlimited ammo
	PL_IFC1X	2

; spray ammo
	PL_W	$5aaa,$4a20		; sbcd -(a1),-(a0) -> tst.b -(a0)
; other ammo
	PL_W	$5d9c,$4a20		; sbcd -(a1),-(a0) -> tst.b -(a0)
	PL_ENDIF


; unlimited fuel
	PL_IFC1X	3
	PL_W	$3254,$4a20		; sbcd -(a1),-(a0) -> tst.b -(a0)
	PL_ENDIF

; unlimited money
	PL_IFC1X	4
	PL_SA	$44f6,$44fc
	PL_ENDIF

; start with max. money
	PL_IFC1X	5
	PL_L	$2368+2,$99999
	PL_ENDIF

; start with all extras
	PL_IFC1X	6
	PL_B	$d1d4,$99		; fuel
	PL_B	$d1d6,$99		; bounce bomb
	PL_B	$d1d8,$99		; nuke aliens
	PL_B	$d1db,$99		; spray ammo
	PL_B	$d1dc,$99		; shields
	PL_B	$d1dd,$99		; freeze aliens
	PL_B	$d1de,$99		; homing missile
	PL_ENDIF

; in-game keys
	PL_IFC1X	7
	PL_PSS	$de,.keys,4
	PL_P	$4a6e,.CheckStatus
	PL_PSS	$32cc,.FakeJoy,2	; fake joystick down if needed
	PL_PSS	$120c,.DisableKeys,2	; disable in-game keys when entering name
	PL_PS	$1228,.EnableKeys	; enable in-game keys again after name has been entered
	PL_PS	$498,.ClearEnergy	; -> disable help screen
	PL_ENDIF



	PL_PSS	$36a8,.FixTiming,4	; fix timing in shop

	PL_PS	$786c,.wblit1
	PL_PS	$78ea,.wblit1

	PL_IFC1

	PL_ELSE

	PL_PS	$1222,.SaveHighscores	
	PL_ENDIF

	PL_END


.DisableKeys
	move.l	a0,-(a7)
	lea	.keys_enabled(pc),a0
	sf	(a0)
	move.l	(a7)+,a0

	moveq	#2,d0			; optimised original code
	jmp	(a0)

.EnableKeys
	move.l	a0,-(a7)
	lea	.keys_enabled(pc),a0
	st	(a0)
	move.l	(a7)+,a0
	jmp	$2000+$8c10		; original code, WaitVBL


; clear player energy to disable the help screen
; required to make the "check energy" trick work even if game
; has been aborted with F10
.ClearEnergy
	clr.w	$2000+$ce66
	add.l	#40*200*5,d0		; original code
	rts


.CheckStatus
	move.l	a0,-(a7)
	lea	.Status(pc),a0
	move.w	(a0),d4
	clr.w	(a0)
	move.l	(a7)+,a0
	tst.w	d4			; status set by in-game keys?
	bne.b	.status_set

	and.w	#$fff0,d2		; no, use original code
	lsr.w	#3,d2
	jmp	$2000+$4a74.w

.FakeJoy
	move.w	.Status(pc),-(a7)
	tst.w	(a7)+			; status set by in-game keys?
	bne.b	.fakedown		; yes, fake "joystick down"

	btst	#1,$2000+$ce92		; no, use mormal joystick status

.status_set
.fakedown
	rts
	

	
	


.Status	dc.w	0




.SaveHighscores
	lea	HighName(pc),a0
	lea	$2000+$15cb.w,a1
	move.l	#$16d0-$15cb,d0
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)

	jmp	$2000+$8c10		; original code, WaitVBL
	

.keys	lea	.check_keys(pc),a0
	st	.keys_enabled-.check_keys(a0)
	move.l	a0,KbdCust-.check_keys(a0)
	rts

.check_keys
	bsr	StoreKey
	lea	.TAB(pc),a0
	tst.b	.keys_enabled-.TAB(a0)
	beq.b	.exit
	
.loop	movem.w	(a0)+,d1/d2		; rawkey, offset to routine
	cmp.b	d0,d1
	beq.b	.found

	tst.w	(a0)
	bne.b	.loop
.exit	rts

.keys_enabled	dc.b	0		; in-game keys enabled (0: no)
.help_enabled	dc.b	0		; help screen enabled (0: no)

.found	jmp	.TAB(pc,d2.w)


.TAB	dc.w	$23,.RefreshFuel-.TAB	; F - refresh fuel
	dc.w	$12,.RefreshEnergy-.TAB	; E - refresh energy
	dc.w	$28,.RefreshLives-.TAB	; L - refresh lives
	dc.w	$11,.GetAllWeapons-.TAB	; W - get all weapons/extras
	dc.w	$36,.SkipLevel-.TAB	; N - skip level
	dc.w	$32,.ShowEnd-.TAB	; X - show end
	dc.w	$20,.Freeze-.TAB	; A - freeze enemies
	dc.w	$35,.Nuke-.TAB		; B - nuke enemies
	dc.w	$37,.MaxMoney-.TAB	; M - get max. money
	dc.w	$14,.EnterTerminal-.TAB	; T - enter terminal
	dc.w	$19,.GetFuelPacks-.TAB	; P - get the 50 fuel packs
	dc.w	$5f,.ShowHelp-.TAB	; HELP - show help screen
	dc.w	0			; end of tab

.RefreshFuel
	move.b	#$99,$2000+$d2de
	rts

.RefreshEnergy
	move.w	#192,$2000+$ce66
	rts

.RefreshLives
	move.w	#4,$2000+$ce6e
	rts

.GetAllWeapons
	move.b	#$99,d1
	move.b	d1,$2000+$d1d0		; spray ammo
	move.b	d1,$2000+$d1cc		; rifle
	move.b	d1,$2000+$d1d1		; shield
	move.b	d1,$2000+$d1d2		; freeze aliens
	move.b	d1,$2000+$d1cd		; nuke aliens
	move.b	d1,$2000+$d1cb		; bounce bomb
	move.b	d1,$2000+$d1d3		; homing missile	
	rts

.SkipLevel
	move.w	#$83e0,d0
	bsr	.SetStatus
	jmp	$2000+$2856.w

.Freeze	move.w	#-1,$2000+$ce36		; freeze for 65536 VBL's
	rts

.Nuke	jmp	$2000+$5e86.w

.ShowEnd
	move.w	#1,$2000+$d690
	rts
	
.MaxMoney
	move.l	#$99999,$2000+$d2da
	rts


.EnterTerminal
	move.w	#$9420,d0
.SetStatus
	lea	.Status(pc),a0
	move.w	d0,(a0)
	rts

; get all fuel packs needed to complete the game
.GetFuelPacks
	move.b	#$50,$2000+$d1c9
.nohelp	rts


; display help screen which shows all in-game keys
; to avoid problems the help screen will only be displayed
; if the main game is running. For that we simply check if the player
; energy is >0.
.ShowHelp
	tst.w	$2000+$ce66		; energy
	beq.b	.nohelp			; no energy -> not in game
	tst.w	$2000+$d690		; "game completed" flag
	bne.b	.nohelp

	bsr	WaitRaster

; clear screen
	move.l	$2000+$ce50,a1
	move.w	#40*200*4/4-1,d7
.cls	clr.l	(a1)+
	dbf	d7,.cls

	lea	.HelpText(pc),a0
	move.l	$2000+$ce50,a1
	jsr	$2000+$477c.w		; write

.LOOP	btst	#7,$bfe001
	bne.b	.LOOP

.release
	btst	#7,$bfe001
	beq.b	.release

	bra.w	WaitRaster

.HelpText
	dc.b	0,4	; x/y position
	dc.b	"           IN-GAME KEYS",">"
	dc.b	">"
	dc.b	"F: REFRESH FUEL   E: REFRESH ENERGY",">"
	dc.b	"L: REFRESH LIVES  W: GET ALL EXTRAS",">"
	dc.b	"N: SKIP LEVEL     X: SHOW END",">"
	dc.b	"A: FREEZE ENEMIES B: NUKE ENEMIES",">"
	dc.b	"M: MAXIMUM MONEY  T: ENTER TERMINAL",">"
	dc.b	"P: ALL FUEL PACKS HELP: THIS SCREEN",">"
	dc.b	">"
	dc.b	"   PRESS FIRE TO RETURN TO GAME"
	dc.b	0
	CNOP	0,2

.FixTiming
	moveq	#4-1,d7
.loop2	bsr	WaitRaster
	dbf	d7,.loop2
	move.w	$2000+$cea0,$2000+$380c	; original code
	rts


.wblit1	bsr	WaitBlit
	move.w	d0,$dff040
	rts


.PatchReplayer
	movem.l	d0-a6,-(a7)
	move.l	a0,a1
	lea	PLMUSIC(pc),a0
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6


	add.w	#$1404,a0		; optimised original code
	rts

; d0.l: size
; d1.l: destination
; a0.l: file name

.LoadFile
	move.l	d1,a1
	move.l	resload(pc),a2
	jmp	resload_LoadFileDecrunch(a2)


.AllocMem
	lea	.free(pc),a0
	move.l	(a0),d1
	add.l	d0,(a0)
	move.l	d1,d0
	rts

.free	dc.l	$2000+$10000		; exe size: $dfb8


PLMUSIC	PL_START
	PL_P	$11be,FixDMAWait	; fix DMA wait in replayer
	PL_END

WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts


FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d1	
.loop	move.b	$dff006,d0
.wait	cmp.b	$dff006,d0
	beq.b	.wait
	dbf	d1,.loop
	movem.l	(a7)+,d0/d1
	rts


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
.wait	btst	#0,$dff005
	beq.b	.wait
.wait2	btst	#0,$dff005
	bne.b	.wait2
	rts


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


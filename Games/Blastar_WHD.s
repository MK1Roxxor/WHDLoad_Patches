***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(         BLASTAR WHDLOAD SLAVE              )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             April 2021                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 01-May-2021	- end sequence problem fixed by turning off all DMA before
;		  running the end sequence
;		- default quitkey changed to F9 as F10 is used in the game
;		  to enable the shield
;		- keyboard interrupt and all related code removed as this
;		  approach doesn't work with NOVBRMOVE (and hence not
;		  on 68000 either) due to the WHDLF_NoKbd flag, all parts
;		  adapted to check the quitkey without a level 2 interrupt
;		- Propack decruncher in end sequence relocated
;		- this is the final 3.0 version of the Blastar patch!

; 26-Apr-2021	- tried to fix the end sequence problem (it doesn't work
;		  properly for some reason), no success yet

; 25-Apr-2021	- invulnerability trainer option added
;		- access fault in weapon menu fixed
;		- keyboard interrupt in main menu used now, during game
;		  it is disabled

; 24-Apr-2021	- more in-game keys added (weapon selection, level skip)
;		- yet another access fault detected (weapon menu, selecting
;		  weapon), not yet fixed

; 23-Apr-2021	- code for the option handling improvements optimised a bit

; 22-Apr-2021	- help screen added
;		- option handling improved, when returning to the main
;		  menu after playing a game, the options which have been
;		  set before are restored (difficulty, one/two button joy,
;		  normal/advanced joy). originally, these options are reset
;		  to default values after playing a game.

; 21-Apr-2021	- more in-game keys added

; 20-Apr-2021	- in-game keys added

; 19-Apr-2021	- some tests to perform the graphics bugs fix without
;		  slowing down the game on 68000, not satisfied with the
;		  results yet

; 18-Apr-20021	- blitter waits added
;		- access fault in level 5 (Lavice Island, Stage 2) fixed,
;		  level map data is exactly 64k in size, loaded to $70000
;		  and decrunched to the same area which results in memory
;		  outside the 512k chip memory area being accessed. Fixd
;		  by loading and decrunching the data to $6cd00 (MFM buffer
;		  area) and then copying it to the correct destination.
;		- version bumped to 3.0 as this is completely different
;		  to any of the previous versions of the patch
;		- end sequence patched

; 17-Apr-2021	- delay for the level info screens added
;		- trainer options added

; 16-Apr-2021	- WHDLF_NoKbd flag used now, level 2 interrupt patch for
;		  main game removed
;		- fixed the graphics problems on fast machines, not entirely
;		  happy with the fix approch yet though

; 15-Apr-2021	- work restarted from scratch

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap|WHDLF_NoKbd
QUITKEY		= $58		; F9 (F10 is used in the game)
DEBUG

; Trainer bits
TRB_LIVES	= 0	; unlimited lives
TRB_BOMBS	= 1	; unlimited bombs 
TRB_ENERGY	= 2	; unlimited energy
TRB_MONEY	= 3	; start with max. money
TRB_INVULNERABLE= 4	; invulnerability
TRB_KEYS	= 5	; in-game keys


;TEST_ENDSEQUENCE	; uncomment to run end sequence instead of game

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
	dc.l	524288+65536	; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"C1:B:Skip Intro;"

	dc.b	"C2:X:Unlimited Lives:",TRB_LIVES+"0",";"
	dc.b	"C2:X:Unlimited Bombs:",TRB_BOMBS+"0",";"
	dc.b	"C2:X:Unlimited Energy:",TRB_ENERGY+"0",";"
	dc.b	"C2:X:Invulnerability:",TRB_INVULNERABLE+"0",";"
	dc.b	"C2:X:Start with max. Money:",TRB_MONEY+"0",";"
	dc.b	"C2:X:In-Game Keys (Press HELP during game):",TRB_KEYS+"0",";"

	dc.b	"C3:B:Disable Graphics Fix:"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Blastar",0
	ENDC

.name	dc.b	"Blastar",0
.copy	dc.b	"1993 Core Design",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 3.0 (01.05.2021)",0


	CNOP	0,4


resload	dc.l	0

	INCLUDE	SOURCES:WHD_Slaves/Blastar/Helpscreen.i


Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2


	IFD	TEST_ENDSEQUENCE
	lea	$1000.w,a0
	move.l	#$461*512,d0
	move.l	#$153*512,d1
	moveq	#3,d2
	jsr	resload_DiskLoad(a2)

	lea	$dff000,a6
	bsr	SetCop_End
	lea	$1000.w,a0
	move.l	a0,a1
	bsr	PatchEnd
	bra.w	QUIT
	ENDC


	; install level 2 interrupt
	;bsr	SetLev2IRQ

	; load boot
	move.l	#$2c00,d0
	move.l	#$4e00,d1
	lea	$7a000,a0
	move.l	a0,a5
	move.l	d1,d5
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$D17D,d0		; SPS 2814
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok


; patch
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

	; set ext. memory
	move.l	HEADER+ws_ExpMem(pc),d0
	add.l	#65536,d0
	clr.w	d0
	lea	ExtMem_Aligned(pc),a0
	move.l	d0,(a0)

	move.l	d0,$4baa(a5)


	jmp	(a5)


ExtMem_Aligned	dc.l	0

; ---------------------------------------------------------------------------

PLBOOT	PL_START
	PL_SA	$6,$e			; skip write to FMODE
	PL_R	$4ade			; disable ext. memory detection
	PL_P	$4362,Loader
	PL_P	$4bb0,Decrunch		; relocate Propack decruncher

	PL_PS	$76,.PatchIntro
	PL_PS	$4b8a,.PatchGame
	PL_END

.PatchIntro
	lea	PLINTRO(pc),a0
	lea	$1000.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	move.l	ExtMem_Aligned(pc),d0
	rts

.PatchGame
	lea	PLGAME(pc),a0
	move.l	ExtMem_Aligned(pc),a1
	add.l	#$1c,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)


	;bsr	SetLev2IRQ

	move.l	ExtMem_Aligned(pc),a0

	; fix copperlists
	move.l	a0,a1

	; Chip data is copied to $800.w in the relocation routine.
	; It starts at offset $725c8 in the binary.
	lea	$800+($72f44-$725c8).w,a1
	move.w	#($76918-$72f44)/4-1,d7

.loop	cmp.w	#$0100,(a1)
	bne.b	.noBplcon0
	or.w	#1<<9,2(a1)		; set Bplcon0 color bit

.noBplcon0

	addq.w	#4,a1
	dbf	d7,.loop

	rts


; ---------------------------------------------------------------------------

PLINTRO	PL_START
	PL_P	$f14,AckCOP
	PL_P	$19670,AckLev6
	PL_P	$196b6,AckLev6
	PL_PS	$6ab2,.AckInt
	PL_ORW	$1f0fe+2,1<<9		; set Bplcon0 color bit

	; don't run intro if CUSTOM1 is set
	PL_IFC1
	PL_R	0
	PL_ENDIF
	

	PL_PSS	$efe,.CheckQuit,2	; check quitkey in VBI
	PL_END

.CheckQuit
	bsr	CheckQuit


	btst	#7,$bfe001		; original code
	rts

.AckInt	move.w	d0,$dff09c
	move.w	d0,$dff09c
	rts

; ---------------------------------------------------------------------------

PLGAME	PL_START
	PL_SA	$c,$14			; skip write to FMODE
	PL_PSS	$8a6,AckCOP_R,2
	PL_PSS	$834,AckVBI_R,2
	PL_P	$2d5b6,Loader
	PL_P	$2684e,Decrunch		; relocate Propack decruncher
	PL_PS	$2b698,.Copylock	; disable protection check
	PL_SA	$198,$1a2		; don't modify interrupt vectors

	PL_PS	$84c,.CheckQuitKey	; check quitkey in VBI



	; add delays for the level info/mission objective screens
	; level info is displayed while game loads and decrunches data
	; that means the level info will only be shown for a short time
	; when loading from HD and/or the Amiga is a fast one
	PL_PS	$2b9c4,.WaitBeforeFadeDown
	PL_PS	$2baaa,.WaitBeforeFadeDown
	PL_PS	$2bbd8,.WaitBeforeFadeDown
	PL_PS	$2bdf2,.WaitBeforeFadeDown
	PL_PS	$2bf2c,.WaitBeforeFadeDown
	PL_PS	$2c326,.WaitBeforeFadeDown
	PL_PS	$2c568,.WaitBeforeFadeDown
	PL_PS	$2ca34,.WaitBeforeFadeDown
	PL_PS	$2cb44,.WaitBeforeFadeDown
	PL_PS	$2cd98,.WaitBeforeFadeDown
	PL_PS	$2cfa4,.WaitBeforeFadeDown
	PL_PS	$2d1be,.WaitBeforeFadeDown
	PL_PS	$2d482,.WaitBeforeFadeDown


	; unlimited lives
	PL_IFC2X	TRB_LIVES
	PL_B	$c32a,$4a	; subq.b #1,Lives(a5) -> tst.b Lives(a5)
	PL_ENDIF

	; unlimited bombs
	PL_IFC2X	TRB_BOMBS
	PL_B	$9a4e,$4a	; subq.b #1,Bombs(a5) -> tst.b Bombs(a5)
	PL_B	$9a8c,$4a	; subq.b #1,Bombs(a5) -> tst.b Bombs(a5)
	PL_ENDIF
	
	; unlimited energy
	PL_IFC2X	TRB_ENERGY
	PL_R	$20352
	PL_R	$203e0
	PL_R	$2046a
	PL_R	$205dc
	PL_B	$210fe,$4a	; addq.w #2,Energy(a5) -> tst.w Energy(a5)
	PL_B	$21108,$4a	; addq.w #2,Energy(a5) -> tst.w Energy(a5)
	PL_B	$2134a,$4a	; addq.w #4,Energy(a5) -> tst.w Energy(a5)
	PL_B	$2134e,$4a	; addq.w #2,Energy(a5) -> tst.w Energy(a5)
	PL_B	$21358,$4a	; addq.w #2,Energy(a5) -> tst.w Energy(a5)
	PL_B	$214b2,$4a	; addq.w #2,Energy(a5) -> tst.w Energy(a5)
	PL_B	$214bc,$4a	; addq.w #2,Energy(a5) -> tst.w Energy(a5)
	PL_B	$216e4,$4a	; addq.w #1,Energy(a5) -> tst.w Energy(a5)
	PL_B	$216ee,$4a	; addq.w #1,Energy(a5) -> tst.w Energy(a5)
	PL_ENDIF

	; invulnerability
	PL_IFC2X	TRB_INVULNERABLE
	PL_B	$b558,$60
	PL_B	$1ff5e,$60
	PL_B	$210ea,$60
	PL_B	$2132c,$60
	PL_B	$214a4,$60
	PL_B	$216d4,$60
	PL_ENDIF

	; in-game keys
	PL_IFC2X	TRB_KEYS
	PL_PS	$94f8,.HandleTrainerKeys
	PL_ENDIF


	PL_IFC2X	TRB_MONEY
	PL_PSS	$1022e,.SetMoney,2
	PL_ENDIF

	;PL_L	$95dc,$4e714e71	; enable in-game keys
	;PL_W	$2786a,$4e71	; enable "auto add money in shop" feature
	


	; --------------------------------------------------------

	PL_PSS	$125ae,.wblit1,2
	PL_PSS	$18298,.wblit1,2
	PL_PSS	$187ce,.wblit1,2

	; --------------------------------------------------------
	; Access fault fix for level 5 (Lavice Island, Stage 2)
	
	PL_L	$2bee2+2,$6cd00		; load data to $6cd00 instead of $70000
	PL_PSA	$2bf34,.FixFault,$2bf44	; decrunch and copy to destination

	; Cybernetic Station
	PL_L	$2c51e+2,$6cd00		; load data to $6cd00 instead of $70000
	PL_PSA	$2c570,.FixFault,$2c580	; decrunch and copy to destination


	; --------------------------------------------------------

	PL_PSS	$2d32e,SetCop_End,2
	PL_P	$2d388,PatchEnd


	; --------------------------------------------------------
	; Fix graphics bugs on fast machines

	PL_IFC3
	; don't install graphics fix if CUSTOM3 is set.

	PL_ELSE
	PL_PSA	$888,.Call_VBI_Routines,$89a
	PL_ENDIF


	; --------------------------------------------------------
	; Fix option handling

	PL_PSA	$25d20,.SetOptions,$25d2c
	PL_P	$10676,.SetNormalJoy
	PL_P	$106a0,.SetAdvancedJoy

	PL_P	$106c4,.SetOneButtonJoy
	PL_P	$106ea,.SetTwoButtonJoy

	PL_P	$105d4,.SetNormalDifficulty
	PL_P	$10604,.SetHardDifficulty

	PL_PS	$78c,.WriteCorrectOptions
	

	; --------------------------------------------------------
	; Fix access fault in weapon menu
	
	PL_B	$283ca,$6d	; ble -> blt



	PL_END




; ---------------------------------------------------------------------------
; Fixes/improvements for the option handling.

.SetNormalJoy
	lea	.AdvancedJoy(pc),a1
	clr.w	(a1)
.WriteOption
	move.l	ExtMem_Aligned(pc),a1
	add.l	#$10a44+$1c,a1		; write options text
	jmp	(a1)

.SetAdvancedJoy
	lea	.AdvancedJoy(pc),a1
	move.w	#-1,(a1)
	bra.b	.WriteOption


.SetNormalDifficulty
	lea	.Difficulty(pc),a1
	clr.w	(a1)
	bra.b	.WriteOption

.SetHardDifficulty
	lea	.Difficulty(pc),a1
	move.w	#-1,(a1)
	bra.b	.WriteOption

.SetOneButtonJoy
	lea	.TwoButtonJoy(pc),a1
	clr.w	(a1)
	bra.b	.WriteOption

.SetTwoButtonJoy
	lea	.TwoButtonJoy(pc),a1
	move.w	#-1,(a1)
	bra.b	.WriteOption


.SetOptions
	move.w	.Difficulty(pc),$26a4(a5)
	move.w	.AdvancedJoy(pc),$26a8(a5)
	move.w	.TwoButtonJoy(pc),$26a2(a5)
	rts

.WriteCorrectOptions
	move.l	ExtMem_Aligned(pc),a0
	add.l	#$10942+$1c,a0
	jsr	(a0)			; write menu


	; Menu is always written using the default options.
	; We need to write the currently used options.
	moveq	#3-1,d7
	lea	.Offsets(pc),a1		; offsets to "Write Option" text
	lea	.CurrentOptions(pc),a2
.write_options_loop
	move.l	(a1)+,d0
	move.l	ExtMem_Aligned(pc),a0
	tst.w	(a2)+
	beq.b	.standard_option_set
	movem.l	d0-a6,-(a7)
	jsr	(a0,d0.l)
	movem.l	(a7)+,d0-a6
.standard_option_set
	dbf	d7,.write_options_loop
	rts


.Offsets	dc.l	$105da+$1c	; hard difficulty
		dc.l	$1067c+$1c	; advanced joy
		dc.l	$106ca+$1c	; two button joy

.CurrentOptions
.Difficulty	dc.w	0
.AdvancedJoy	dc.w	0
.TwoButtonJoy	dc.w	0



; ---------------------------------------------------------------------------
; Fixes for the graphics problems on fast machines.


.Call_VBI_Routines
	move.l	ExtMem_Aligned(pc),a0
	move.l	#$1eeae+$1c,d0
	jsr	(a0,d0.l)

	; In the following routine, the screens are swapped and the
	; Bplcon1 values are updated.
	move.l	ExtMem_Aligned(pc),a0
	move.l	#$9ee8+$1c,d0
	jsr	(a0,d0.l)

	; Waiting for a certain raster line fixes the bug.
	; This is merely a workaround than a proper fix but does the job
	; for now.
.wait1	;move.w	d0,$dff180
	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#15<<8,d0
	bne.b	.wait1

	move.l	ExtMem_Aligned(pc),a0
	move.l	#$25266+$1c,d0
	jsr	(a0,d0.l)
	rts



; ---------------------------------------------------------------------------
; Trainer stuff.


.SetMoney
	move.l	#$99999,$3c(a5)
	clr.w	$26ae(a5)
	rts


; ---------------------------------------------------------------------------
; Access fault fixes.

.FixFault
	lea	$6cd00,a0
	move.l	a0,a1
	move.l	resload(pc),a2
	jsr	resload_Decrunch(a2)

	; copy data backwards (as source and destination overlap)
	; to correct destination
	lea	$6cd00,a0
	lea	$70000,a1
	add.l	#65536,a0		; end source area
	add.l	#65536,a1		; end of destination area
	move.w	#65536/4-1,d7
.copy	move.l	-(a0),-(a1)
	dbf	d7,.copy
	rts



; ---------------------------------------------------------------------------
; Blitter waits.

.wblit1	bsr.b	.WaitBlit
	move.l	#$ffff0000,$44(a6)
	rts


.WaitBlit
	tst.b	$02(a6)
.wblit	btst	#6,$02(a6)
	bne.b	.wblit
	rts

; ---------------------------------------------------------------------------
; Keyboard routines.


.HandleTrainerKeys
	moveq	#0,d0
	bsr.b	.GetKey
	
	movem.l	d0-a6,-(a7)
	ror.b	d0
	not.b	d0

	lea	.Tab(pc),a0
.loop	movem.w	(a0)+,d1/d2
	cmp.w	d0,d1
	beq.b	.key_found
	tst.w	(a0)
	bne.b	.loop

	; check weapon keys
	cmp.b	#$01,d0
	blt.b	.noWeaponKey
	cmp.b	#$0A,d0
	bgt.b	.noWeaponKey


	move.l	ExtMem_Aligned(pc),a0
	add.w	#$1c,a0
	lea	$8cc(a0),a1

	move.l	a0,a2
	add.l	#$155a8,a2		; offset to weapon table

	subq.b	#1,d0
	mulu.w	#$1565c-$155a8,d0	; add offset to selected weapon
	add.w	d0,a2
	move.l	a2,(a1)+
	move.l	a2,(a1)
.noWeaponKey


	bra.b	.exit


.key_found
	jsr	.Tab(pc,d2.w)

.exit

	movem.l	(a7)+,d0-a6

.GetKey	move.b	$bfec01,d0
	rts


.Tab	dc.w	$12,.RefreshEnergy-.Tab		; E
	dc.w	$35,.GetMaxBombs-.Tab		; B
	dc.w	$37,.GetMaxMoney-.Tab		; M
	dc.w	$11,.GetMaxWeaponPower-.Tab	; W
	dc.w	$21,.GetMaxSpeed-.Tab		; S
	dc.w	$22,.GetShield-.Tab		; D
	dc.w	$28,.GetMaxLives-.Tab		; L
	dc.w	$25,.GetHomingMissiles-.Tab	; H
	dc.w	$5f,.ShowHelp-.Tab		; Help
	dc.w	$36,.SkipLevel-.Tab		; N
	dc.w	$32,.ShowEnd-.Tab		; X
	dc.w	0				; end of table


.RefreshEnergy
	clr.w	$25ba(a5)
	rts

.GetMaxBombs
	move.b	#9,$30be(a5)
	rts

.GetMaxMoney
	move.l	#$99999,$3c(a5)
	rts

.GetMaxWeaponPower
	move.w	#6,$26ae(a5)
	rts

.GetMaxSpeed
	move.l	ExtMem_Aligned(pc),a0
	move.w	#24,$5af2+$1c(a0)
	rts

.GetShield
	move.w	#50*4,$1dae(a5)			; enable shield for 4 seconds
	rts

.GetMaxLives
	move.b	#9,$30bd(a5)
	rts

.GetHomingMissiles
	move.l	ExtMem_Aligned(pc),a0
	add.l	#$160d0+$1c,a0
	move.w	#-1,(a0)
	rts	

.SkipLevel
	move.l	ExtMem_Aligned(pc),a0
	add.l	#$1c+$25260,a0
	move.w	#112,(a0)

	; Next one is crucial, it stores the current
	; speed in a backup variable. If this isn't done,
	; ship movement will not work properly in next level.
	; Took me (way too) long to find out.
	move.l	ExtMem_Aligned(pc),a0
	move.w	$5af2+$1c(a0),$5af4+$1c(a0)
	rts

.ShowEnd
	move.l	#$3f4,$d04(a5)	
	bra.b	.SkipLevel



; Routine displays a screen with the in-game keys.
; It is called if the "HELP" key is pressed during game.
; Stack space is used as Screen memory.

.ShowHelp
	lea	.Text(pc),a0
	bsr	HS_GetScreenHeight
	addq.w	#1,d0
	mulu.w	#640/8,d0
	
	; use stack space as screen memory
	; as SSP is in fast memory, USP needs to be used
	lea	.OldUSP(pc),a2

	move.l	USP,a1
	move.l	a1,(a2)

	sub.l	d0,a1
	move.l	a1,a2

	; clear screen memory
	move.l	d0,d1
.cls	clr.b	(a1)+
	subq.l	#1,d1
	bne.b	.cls


	move.l	a2,a1
	bsr	ShowHelpScreen

	move.l	.OldUSP(pc),a0
	move.l	a0,USP
	rts

.OldUSP	dc.l	0


.Text	dc.b	"    Blastar In-Game Keys",10
	dc.b	10
	dc.b	"E: Refresh Energy     B: Get Bombs",10
	dc.b	"M: Get Money          W: Maximum Weapon Power",10
	dc.b	"S: Maximum Speed      D: Get Shield",10
	dc.b	"L: Get Lives          H: Get Homing Missiles",10
	dc.b	"N: Skip Level       1-0: Select Weapon",10
	dc.b	10
	dc.b	"Press left mouse button or fire to return to game.",10
	dc.b	0
	CNOP	0,2






; ---------------------------------------------------------------------------
; Delay for the "Mission Objective" screen. Game originally shows these
; while loading and decrunching data from disk, which takes long enough that
; no delay is needed.


.WaitBeforeFadeDown
	movem.l	d0/a0,-(a7)
	moveq	#5*10,d0		; show screen for 5 seconds
	move.l	resload(pc),a0
	jsr	resload_Delay(a0)
	movem.l	(a7)+,d0/a0

	move.w	#-1,$26aa(a5)		; original code, set "fade down" flag
	rts


; ---------------------------------------------------------------------------
; Proctection removal.


; The copylock code is copied to $800.w in the relocation routine.
; In the binary it's stored at offset $725c8.
.Copylock
	move.l	#$5ee0f501,d5		; Copylock key
	move.l	d5,$f4.w
	jmp	$800+($72e9c-$725c8).w
	



; ---------------------------------------------------------------------------

.CheckQuitKey
	lea	$dff000,a6

CheckQuit
	move.b	$bfec01,d0
	ror.b	d0
	not.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	rts


; ---------------------------------------------------------------------------
; End sequence patches.

SetCop_End
	; If DMA is not turned off, the end sequence will not work
	; properly. In the game, the copperlist at $78000 is set at this
	; point, but there is no valid copperlist at this address.
	; However, as turning on copperlist DMA causes the end sequence
	; not to work properly, all DMA will be disabled here so creating
	; a valid copperist at $78000 is not required anymore.
	
	move.w	#$7ff,$dff096
	rts
	
;	lea	$78000,a0
;	move.l	#$01000200,(a0)+
;	move.l	#$01800000,(a0)+
;	move.l	#$ffdffffe,(a0)+
;	move.l	#$2001fffe,(a0)+
;	move.l	#$009c8010,(a0)+
;	move.l	#$fffffffe,(a0)

;	move.l	#$78000,$80(a6)
;	rts

PatchEnd
	bsr	Decrunch
	lea	PLEND(pc),a0
	lea	$1000.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	; copperlist at $78000 will be destroyed
	; in the precalc routine hence we need to set the
	; copperlist pointer to a copperlist from the
	; end sequence
	move.l	#$1000+$9df4,$dff080

	; and run the end sequence
	jmp	$1000.w

PLEND	PL_START
	PL_P	$4184,.FixAccessFault	; fix access fault in NoisePacker replayer

	PL_ORW	$477c+2,1<<9
	PL_ORW	$5188+2,1<<9
	PL_ORW	$526c+2,1<<9
	PL_ORW	$536c+2,1<<9
	PL_ORW	$5400+2,1<<9
	PL_ORW	$9d1c+2,1<<9

	PL_P	$656,.CheckQuitAndAckCOP
	PL_P	$43da,AckLev6
	PL_P	$4430,AckLev6

	PL_PSS	$6a8,FixDMAWait,2	; fix DMA wait in sample player
	PL_PSS	$6ea,FixDMAWait,2	; fix DMA wait in sample player
	PL_PSS	$844,FixDMAWait,2	; fix DMA wait in sample player
	PL_PSS	$886,FixDMAWait,2	; fix DMA wait in sample player


	PL_P	$450c,Decrunch		; relocate Propack decruncher

	PL_PS	$670,.CheckQuit		; enable quit in first part
	PL_PS	$71e,.CheckQuit		; as above
	PL_PS	$aac,.CheckQuit		; enable quit in last part
	PL_END


.CheckQuit
	bsr	CheckQuit
	lea	$dff000,a6
	rts

.CheckQuitAndAckCOP
	move.l	d0,-(a7)
	bsr	CheckQuit
	move.l	(a7)+,d0
	bra.w	AckCOP

.FixAccessFault
	move.l	d1,-(a7)
	move.l	a0,d1
	beq.b	.exit

	cmp.w	-4(a0),d0
	bne.b	.exit
	move.w	-2(a0),(a6)

.exit	move.l	(a7)+,d1
	rts
	


; ---------------------------------------------------------------------------

; d0.w: drive number (0-3)
; d1.w: sector
; d2.w: number of sectors to load
; d3.w: command
; a0.l: destination
; ----
; d0.w: error code (0: no error)

Loader	movem.l	d1-a6,-(a7)

	move.w	d0,d3
	
	move.w	d1,d0
	move.w	d2,d1
	mulu.w	#512,d0
	mulu.w	#512,d1
	move.b	d3,d2
	addq.b	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)

	movem.l	(a7)+,d1-a6
	moveq	#0,d0
	rts

; ---------------------------------------------------------------------------

Decrunch
	movem.l	d0-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_Decrunch(a2)
	movem.l	(a7)+,d0-a6
	rts

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




AckCOP	move.w	#1<<4,$dff09c
	move.w	#1<<4,$dff09c
	rte

AckCOP_R
	move.w	#1<<4,$dff09c
	move.w	#1<<4,$dff09c
	rts

AckVBI	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rte

AckVBI_R
	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rts

AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte

AckLev6_R
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rts



FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d0
.loop	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait
	dbf	d0,.loop
	movem.l	(a7)+,d0/d1
	rts






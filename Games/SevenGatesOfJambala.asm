; V1.2, StingRay, February 2022
; 05.02.2022:	- disassembled V1.1 slave
;		- long write to BPLCON2 fixed
;		- unnecessary blitter wait patch removed
;		- unlimited lives trainer

; 06.02.2022	- Bplcon0 color bit fix in end part
;		- access faults in end part fixed
;		- CPU dependent keyboard delay in end part fixed
;		- interrupts in end part fixed
;		- 68000 quitkey support in end part
;		- Bplcon0 color bit fix in high score screen
;		- CPU dependent keyboard delay in high score screen fixed
;		- interrupts in high score screen fixed
;		- 68000 quitkey support in high score screen
;		- interrupts in title part fixed
;		- 68000 quitkey support in title part
;		- jump with fire 2/ CD32 blue button added (CUSTOM 2)
;		- pause toggle with CD32 play button added (CUSTOM 2)
;		- more trainer options added (start with maximum gold,
;		  unlimited gold, never lose weapons/extras)

; 07.02.2022	- more trainer options added (hammer always available, 
;		  power jump always available)
;		- 68000 quitkey support for main game
;		- support for grandslam intro added (SPS 3052)

; 08.02.2022	- support for Thalion intro added (SPS 3051, SPS 3052)
;		- compilation version (SPS 3051) and original version
;		  (SPS 3052) are now fully supported
;		- one more trainer option (weapon always available)

; 09.02.2022	- in-game keys added
;		- unused and not needed code to save initial high scores
;		  from disk removed

; 10.02.2022	- more in-game keys added

; 11.02.2022	- color combination riddle at end of game is now solved
;		  automatically if "see end" in-game key bas been used
;		- more in-game keys added
;		- key to show help screen changed from H to I as H is
;		  already used to get the hammer
;		- if highscore file does not exist, the initial highscores
;		  are loaded from disk
;		- highscore saving disabled if trainer options are used
;		- the V1.2 update is finished



	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

; Trainer options
TRB_LIVES		= 0		; unlimited lives
TRB_ENERGY		= 1		; unlimited energy
TRB_GOLD		= 2		; unlimited gold
TRB_MAXGOLD		= 3		; start with maximum gold
TRB_KEEPEXTRAS		= 4		; never lose extras
TRB_HAMMER		= 5		; hammer always available
TRB_POWERJUMP		= 6		; power jump always available
TRB_WEAPON		= 7		; weapon always available
TRB_KEYS		= 8		; in-game keys

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


HEADER	SLAVE_HEADER			; ws_Security + ws_ID
	DC.W	17			; ws_Version
	dc.w	FLAGS			; ws_Flags
	DC.L	$80000			; ws_BaseMemSize
	DC.L	0			; ws_ExecInstall
	DC.W	Patch-HEADER		; ws_GameLoader
	DC.W	.dir-HEADER		; ws_CurrentDir
	DC.W	0			; ws_DontCache
	DC.B	0			; ws_keydebug
	dc.b	QUITKEY			; ws_keyexit
	DC.L	0			; ws_ExpMem
	DC.W	.name-HEADER		; ws_name
	DC.W	.copy-HEADER		; ws_copy
	DC.W	.info-HEADER		; ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"C2:B:Enable CD32 Controls;"
	dc.b	"C1:X:Unlimited Lives:",TRB_LIVES+"0",";"
	dc.b	"C1:X:Unlimited Energy:",TRB_ENERGY+"0",";"
	dc.b	"C1:X:Unlimited Gold:",TRB_GOLD+"0",";"
	dc.b	"C1:X:Start with maxium Gold:",TRB_MAXGOLD+"0",";"
	dc.b	"C1:X:Never lose weapons/extras:",TRB_KEEPEXTRAS+"0",";"
	dc.b	"C1:X:Hammer always available:",TRB_HAMMER+"0",";"
	dc.b	"C1:X:Power Jump always available:",TRB_POWERJUMP+"0",";"
	dc.b	"C1:X:Weapon always available:",TRB_WEAPON+"0",";"
	dc.b	"C1:X:In-Game Keys (Press 'I' during Game):",TRB_KEYS+"0",";"
	dc.b	0
	


.dir	DC.B	'data',0
.name
	DC.B	'Seven Gates of Jambala',0
.copy
	DC.B	'1989 Thalion',0
.info	DC.B	'installed & fixed by Mr.Larmer/Bored Seal/StingRay',10
	DC.B	'V1.2 (12-Feb-2022)',0
	CNOP	0,4


Patch	lea	resload(pc),a1
	move.l	a0,(a1)

	bsr	_detect_controller_types

	lea	DiskName(pc),a0
	bsr.w	GetFileSize
	bne.b	.Not_File_Version

	lea	FileName(pc),a0
	bsr.w	GetFileSize
	beq.w	UnsupportedVersion

	lea	FileName(pc),a0
	lea	$A000,a1
	bsr	LoadFile
	move.w	#$4E75,($36,a1)
	jsr	($20,a1)
	move.w	#$4E75,($5EF40)
	jsr	($5EF26)
	move.w	#$4EF9,($FB6E)
	pea	(Loader_FileVersion,pc)
	move.l	(sp)+,($FB70)
	bra.b	PatchGame

.Not_File_Version

	; V1.2
	lea	$2000-$1c.w,a0
	move.l	#$1600,d0
	move.l	#$37*512,d1
	move.l	a0,a5
	move.l	d1,d5
	moveq	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$2596,d0		; SPS 3052
	beq.w	Patch_Original_Version
	cmp.w	#$F620,d0		; SPS 3051
	beq.w	Patch_Compilation_Version
	bra.w	UnsupportedVersion


PatchGame_NoFiles
	move.w	#$4EF9,$1F12.W
	pea	Loader(pc)
	move.l	(sp)+,$1F14.W

PatchGame
	move.w	#$4EF9,$2050.W
	pea	LoadHighscores(pc)
	move.l	(a7)+,$2052.W

	move.w	#$4EF9,($24D2).W
	pea	SaveHighscores(pc)
	move.l	(a7)+,$24D4.W

	move.w	#$4EB9,$81F0
	pea	WaitKey(pc)
	move.l	(a7)+,$81F2

	move.w	#$4EF9,($2AFE).W
	pea	(DECRUNCH,pc)
	move.l	(sp)+,($2B00).W

	move.w	#$4E75,($2836).W	; disable drive access (motor off)

	move.w	#$6002,($87F2)		; skip access fault (movep)


	; V1.2
	lea	PLGAME(pc),a0
	lea	$e4.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	jmp	$100.W

; Grandslam intro and Thalion intro
Patch_Original_Version
	lea	PLGRANDSLAM(pc),a0
PatchAndRun
	lea	$2000-$1c.w,a1
	jsr	resload_Patch(a2)
	jmp	$2000-$1c.w

; Thalion intro only
Patch_Compilation_Version
	lea	PLCOMPILATION(pc),a0
	bra.b	PatchAndRun
	

PLCOMPILATION
	PL_START
	PL_P	$678c,Load
	PL_P	$284e,Patch_Thalion_Intro
	PL_END


PLGRANDSLAM
	PL_START
	PL_ORW	$5c+2,1<<9		; set Bplcon0 color bit
	PL_SA	$272e,$2734		; skip access fault (Atari ST code)
	PL_PS	$f8,.AckVBI
	PL_PS	$162,WaitKey
	PL_PS	$15a,.CheckQuit
	PL_P	$6790,Load

.SAVE_INTRO	= 0

	IFNE	.SAVE_INTRO
	PL_P	$2840,.Save_Thalion_Intro
	ENDC

	PL_P	$2852,Patch_Thalion_Intro

	PL_END

; ---------------------------------------------------------------------------
; Save Thalion intro after decrypting.

	IFNE	.SAVE_INTRO
.Save_Thalion_Intro
	lea	.IntroName(pc),a0
	lea	$15000-$1c,a1
	move.l	#$1c740,d0
	sub.l	a1,d0

	; add cruncher ID at end of crunched data
	move.l	#"JEK!",(a1,d0.l)
	addq.l	#4,d0			; file is 4 bytes longer

	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)
	bra.w	QUIT

.IntroName	dc.b	"ThalionIntro.jek!",0
		CNOP	0,2
	ENDC

; ---------------------------------------------------------------------------




.CheckQuit
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	move.b	d0,($2000-$1c)+$1f8.w
	rts

.AckVBI	move.w	#1<<4|1<<5|1<<6,$9c(a6)
	move.w	#1<<4|1<<5|1<<6,$9c(a6)
	rts

Patch_Thalion_Intro
	lea	PLTHALION_INTRO(pc),a0
	lea	$15000-$1c,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$15000

PLTHALION_INTRO
	PL_START
	PL_PS	$736,WaitKey
	PL_PS	$72e,.CheckQuit
	PL_P	$72d4,Load		; load game binary
	PL_P	$ce,PatchGame_NoFiles
	PL_P	$d2b8,.AdaptSnoop
	PL_PS	$1fc,.FixCopperlist
	PL_END

.FixCopperlist
	lea	$267d0,a0
	move.l	#$fffffffe,(a0)		; terminate copperlist

	lea	$26000,a0		; original code
	rts

.AdaptSnoop
	move.w	(a7)+,$100.w

	move.w	$100.w,$dff096
	jmp	($15000-$1c)+$d2be

.CheckQuit
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	move.b	d0,($15000-$1c)+$6d8
	rts

Load	move.w	(a6)+,d0
	mulu.w	#512*11,d0
	move.w	(a6)+,d1
	subq.w	#1,d1
	mulu.w	#2*512,d1
	add.l	d1,d0
	tst.w	(a6)+
	beq.b	.lower_side
	add.l	#80*512*11,d0
.lower_side
	move.w	(a6)+,d1
	mulu.w	#512,d1
	move.l	(a6)+,a0
	moveq	#1,d2
	move.l	resload(pc),a2
	jmp	resload_DiskLoad(a2)


PLGAME	PL_START
	PL_PSS	$310,.FixBPLCON2_Access,4	; fix long write to Bplcon2
	PL_P	$7f96,AckVBI
	PL_P	$7f86,AckVBI
	PL_P	$80da,AckLev2
	PL_PSS	$810a,.CheckQuit,2

	PL_PS	$c6,.PatchTitle
	PL_PS	$106c,.PatchEnd
	PL_PS	$3a8,.PatchHighscore

	; Unlimited Lives
	PL_IFC1X	TRB_LIVES
	PL_B	$c48,$4a
	PL_ENDIF

	; Unlimited Energy
	PL_IFC1X	TRB_ENERGY
	PL_B	$1d02,$4a
	PL_B	$60fa,$4a
	PL_ENDIF

	; Unlimited Gold
	PL_IFC1X	TRB_GOLD
	PL_B	$137a,$4a
	PL_ENDIF

	; Start with maximum gold
	PL_IFC1X	TRB_MAXGOLD
	PL_PS	$123e,.Set_Max_Gold
	PL_ENDIF

	; Never lose weapons/extras
	PL_IFC1X	TRB_KEEPEXTRAS
	PL_SA	$c3c,$c48
	PL_ENDIF

	; Hammer always available
	PL_IFC1X	TRB_HAMMER
	PL_SA	$c44,$c48		; don't lose hammer after losing life
	PL_B	$120a,$50		; sf -> st
	PL_ENDIF

	; Power Jump always available
	PL_IFC1X	TRB_POWERJUMP
	PL_SA	$c40,$c44		; don't lose power jump after losing life
	PL_B	$120e,$50		; sf -> st
	PL_ENDIF

	; Weapon always available
	PL_IFC1X	TRB_WEAPON
	PL_SA	$c3c,$c40		; don't lose weeapon afer losing life
	PL_P	$127e,.Set_Initial_Weapon
	PL_ENDIF
	

	; In-Game Keyes
	PL_IFC1X		TRB_KEYS
	PL_PS	$80f4,.Check_Trainer_Keys
	PL_ENDIF


	PL_IFC2
	PL_P	$81ea,.Read_CD32_Pad
	PL_ENDIF


	; disable highscore saving if trainer options are used
	PL_IFC1
	PL_R	$23ee
	PL_ENDIF
	PL_END


.Set_Initial_Weapon
	move.w	#5,$1e2(a6)		; set weapon
	st	$d8(a6)			; original code
	rts


.Set_Max_Gold
	move.w	#9999,$1da(a6)
	st	$e4+$864		; original code
	rts


; d0.b: key code
.Check_Trainer_Keys
	not.b	d0
	ror.b	d0
	movem.l	d0-a6,-(a7)

	lea	.LastKey(pc),a0
	cmp.b	(a0),d0
	beq.b	.no_new_key
	move.b	d0,(a0)

	cmp.b	#1,d0
	blt.b	.no_weapon_key
	cmp.b	#6,d0
	bgt.b	.no_weapon_key
	subq.b	#1,d0
	move.b	d0,$1e2+1(a6)
	bra.b	.no_new_key

.no_weapon_key


	bsr.b	.Handle_Trainer_Keys
.no_new_key

	movem.l	(a7)+,d0-a6
	tst.b	d0			; original code
	rts

; d0.b: raw key code
.Handle_Trainer_Keys
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


.Tab	dc.w	RAWKEY_B,.Get_Bubble-.Tab
	dc.w	RAWKEY_H,.Get_Hammer-.Tab
	dc.w	RAWKEY_X,.See_End-.Tab
	dc.w	RAWKEY_E,.Toggle_Unlimited_Energy-.Tab
	dc.w	RAWKEY_G,.Get_Max_Gold-.Tab
	dc.w	RAWKEY_J,.Get_Power_Jump-.Tab
	dc.w	RAWKEY_I,.Show_Help_Screen-.Tab
	dc.w	RAWKEY_L,.Refresh_Lives-.Tab
	dc.w	RAWKEY_P,.Refresh_Energy-.Tab
	dc.w	0			; end of table


.LastKey	dc.b	0
		dc.b	0

.Get_Bubble
	jmp	($100-$1c)+$82e4

.Get_Hammer
	st	$1c7(a6)
	rts

.See_End
	move.w	#2,$fc(a6)			; level complete
	move.w	#-1,$112(a6)			; level status
	lea	See_End_Key_Used(pc),a0
	st	(a0)
	rts	

.Toggle_Unlimited_Energy
	moveq	#$19,d0				; tst.w <-> subq.w
	eor.b	d0,($100-$1c)+$1d02.w
	eor.b	d0,($100-$1c)+$60fa.w
	rts
	
.Get_Max_Gold
	move.w	#9999,$1da(a6)
	rts

.Get_Power_Jump
	st	$1c8(a6)
	rts


.Refresh_Lives
	move.w	#9,$1d8(a6)
	rts

.Refresh_Energy
	move.w	#5,$e8(a6)
	rts

.Show_Help_Screen
	lea	.Text(pc),a0
	bsr	HS_GetScreenHeight
	addq.w	#1,d0
	mulu.w	#640/8,d0
	lea	.height(pc),a1
	move.l	d0,(a1)

	pea	$50bea

	; clear screen memory
	move.l	(a7),a1
	move.l	d0,d1
.cls	clr.b	(a1)+
	subq.l	#1,d1
	bne.b	.cls

	move.l	(a7)+,a1
	bsr	ShowHelpScreen
	rts

.height	dc.l	0


.Text	dc.b	"Seven Gates of Jambala In-Game Keys",10
	dc.b	10
	dc.b	"  A: Get Bubble       G: Maximum Gold",10
	dc.b	"  H: Get Hammer       E: Toggle Unlimited Energy",10
	dc.b	"  J: Get Power Jump   X: See End",10
	dc.b	"  L: Refresh Lives    P: Refresh Energy",10
	dc.b	"1-6: Get Weapon",10
	dc.b	10
	dc.b	10
	dc.b	"Press left mouse button or fire to return to game.",10
	dc.b	0
	CNOP	0,2

; --------------------------------------------------------------------------
; CD32 controls

.Read_CD32_Pad
	move.b	d0,$ee(a6)			; original code, store
						; joystick status
	bsr	_joystick
	move.l	joy1(pc),d0

	lea	.last(pc),a0
	cmp.l	(a0),d0
	beq.b	.exit
	move.l	d0,(a0)

	btst	#JPB_BTN_BLU,d0
	beq.b	.no_jump
	or.b	#1<<0,$ee(a6)
.no_jump

	btst	#JPB_BTN_PLAY,d0
	beq.b	.no_pause_toggle
	not.b	$d6(a6)
.no_pause_toggle

.exit	rts

.last	dc.l	0

; --------------------------------------------------------------------------


.CheckQuit
	bsr	WaitKey
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	rts	


.FixBPLCON2_Access
	move.w	#0,$dff104
	rts

.PatchTitle
	movem.l	d0-a6,-(a7)
	lea	PLTITLE(pc),a0
	lea	$10000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	jmp	$1001c

.PatchEnd
	movem.l	d0-a6,-(a7)
	lea	PLEND(pc),a0
	lea	$10000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	jmp	$1001c
	
.PatchHighscore
	movem.l	d0-a6,-(a7)
	lea	PLHIGHSCORE(pc),a0
	lea	$20000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	jmp	$2001c

PLTITLE	PL_START
	PL_PS	$1a2,WaitKey
	PL_ORW	$7e+2,1<<9		; set Bplcon0 color bit
	PL_P	$f8,AckVBI
	PL_P	$1b2,AckLev2
	PL_PS	$18a,CheckQuit
	PL_END

PLEND	PL_START
	PL_PS	$1d0,WaitKey
	PL_ORW	$ac+2,1<<9		; set Bplcon0 color bit
	PL_P	$126,AckVBI
	PL_P	$1e0,AckLev2
	PL_PS	$1b8,CheckQuit
	PL_W	$1440,$4e71
	PL_SA	$3ffc,$400c		; skip illegal code
	PL_SA	$4018,$4028		; skip illegal code
	PL_SA	$4054,$4064		; skip illegal code
	PL_SA	$40d6,$40e6		; skip illegal code
	PL_IFC1X	TRB_KEYS
	PL_PS	$143a,.CheckEndCheatKey
	PL_ENDIF
	PL_END

.CheckEndCheatKey
	move.b	See_End_Key_Used(pc),d0
	beq.b	.no_end_cheat
	add.l	#$1460-$1440,(a7)

.no_end_cheat
	tst.b	$10000+$4d4		; original code
	rts


CheckQuit
	not.b	d0
	ror.b	d0
	move.b	d0,d1

	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	rts

See_End_Key_Used	dc.b	0
			dc.b	0

PLHIGHSCORE
	PL_START
	PL_PS	$1d2,WaitKey
	PL_ORW	$a6+2,1<<9		; set Bplcon0 color bit
	PL_P	$128,AckVBI
	PL_P	$1e2,AckLev2
	PL_PS	$1ba,CheckQuit
	PL_END


AckVBI	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte

AckLev2	move.w	#1<<3,$dff09c
	move.w	#1<<3,$dff09c
	rte

QUIT	pea	(TDREASON_OK).w
	bra.w	EXIT


WaitKey
	movem.l	d0/d1,-(a7)
	moveq	#3-1,d1
.loop	move.b	$DFF006,d0
.wait	cmp.b	$DFF006,d0
	beq.b	.wait
	dbf	d1,.loop
	movem.l	(a7)+,d0/d1
	rts

Loader	movem.l	d0-d7/a0-a6,-(sp)
	moveq	#0,d0
	move.w	(a1),d0
	mulu	#$1600,d0
	moveq	#0,d1
	move.w	2(a1),d1
	subq.w	#1,d1
	mulu	#$400,d1
	add.l	d1,d0
	tst.w	14(a1)
	beq.b	.side_ok
	add.l	#80*11*512,d0
.side_ok
	move.l	10(a1),d1
	move.l	d1,$1F0A.W		; store file size for decruncher
	bsr	DiskLoad
	movem.l	(sp)+,d0-d7/a0-a6
	moveq	#0,d0
	rts

Loader_FileVersion
	movem.l	d0-d7/a0-a6,-(sp)
	exg	a0,a1
	move.w	(a0),d0
	ext.l	d0
	lea	($FF0C),a2
	moveq	#7,d1
lbC000216
	rol.l	#4,d0
	move.l	d0,d2
	and.l	#15,d2
	cmp.b	#10,d2
	blt.b	lbC000228
	addq.b	#7,d2
lbC000228
	add.b	#'0',d2
	move.b	d2,(a2)+
	dbra	d1,lbC000216
	lea	($FF0C),a0
	bra.b	lbC00023E

LoadFile
	movem.l	d0-d7/a0-a6,-(sp)
lbC00023E
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)
	movem.l	(sp)+,d0-d7/a0-a6
	moveq	#0,d0
	rts

Params	lea	HighscoreName(pc),a0
	lea	$55600,a1
	move.l	resload(pc),a2
	rts


; --------------------------------------------------------------------------
; High score load/save

LoadHighscores
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.b	Params

	; V1.2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	bne.b	.highscore_file_exists

	; load initial highscores from disk
	lea	$55600,a0
	move.l	#79*$1600,d0
	move.l	#512,d1
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)
	bra.b	.exit
	
.highscore_file_exists
	bsr.b	Params
	bsr.b	LoadFile

.exit	movem.l	(sp)+,d0-d7/a0-a6
	moveq	#0,d0
	rts

SaveHighscores
	movem.l	d0-a6,-(a7)
	bsr.b	Params
	move.l	#512,d0
	jsr	resload_SaveFile(a2)
	movem.l	(a7)+,d0-a6
	moveq	#0,d0
	rts



; ---------------------------------------------------------------------------
; Jek! decruncher
; This is actually a ByteKiller decruncher without checksum and an
; interesting optimisation that was, most probably, performed by the
; Thalion coders.

; a0.l: end of crunched data
; a1.l: destination

DECRUNCH
	lea	.TAB(pc),a5
	move.l	-(a0),d5
	lea	(a1,d5.l),a2
	move.l	-(a0),d0
.decrunch
	moveq	#2,d1
	bsr.b	.GetBits
	bset	#1,d2
	beq.b	.HandleCommand
	lsr.l	#1,d0
	bne.b	.no_new
	move.l	-(a0),d0
	roxr.l	#1,d0
.no_new	addx.l	d2,d2

.HandleCommand
	lsl.w	#3,d2
	movem.w	-2*8(a5,d2.w),d1/d3/d4
	pea	(a5,d4.l)
	bra.b	.GetBits

.GetPackedLength
	add.w	d2,d3
.copy_packed
	moveq	#8,d1
	bsr.b	.GetBits
	move.b	d2,-(a2)
	dbf	d3,.copy_packed
	cmp.l	a2,a1
	blt.b	.decrunch
	rts

.GetUnpackedLength
	move.w	d2,d3
	moveq	#12,d1
	bsr.b	.GetBits
.copy_unpacked
	move.b	-1(a2,d2.w),-(a2)
	dbf	d3,.copy_unpacked
	cmp.l	a2,a1
	blt.b	.decrunch
	rts

.GetBits
	subq.w	#1,d1
	clr.w	d2
.loop	lsr.l	#1,d0
	bne.b	.stream_ok
	move.l	-(a0),d0
	roxr.l	#1,d0
.stream_ok
	addx.l	d2,d2
	dbf	d1,.loop
	rts

.TAB	DC.W	3
	DC.W	0
	DC.W	.GetPackedLength-.TAB
	DC.W	0

	DC.W	8
	DC.W	1
	DC.W	.copy_unpacked-.TAB
	DC.W	0

	DC.W	9
	DC.W	2
	DC.W	.copy_unpacked-.TAB
	DC.W	0

	DC.W	10
	DC.W	3
	DC.W	.copy_unpacked-.TAB
	DC.W	0

	DC.W	8
	DC.W	0
	DC.W	.GetUnpackedLength-.TAB
	DC.W	0

	DC.W	8
	DC.W	8
	DC.W	.GetPackedLength-.TAB
	DC.W	0

; ---------------------------------------------------------------------------


DiskLoad
	movem.l	d0/d1/a0-a2,-(sp)
	moveq	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(sp)+,d0/d1/a0-a2
	rts

GetFileSize
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	rts

UnsupportedVersion
	pea	(TDREASON_WRONGVER).W
EXIT	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

resload	DC.L	0

DiskName	dc.b	"Disk.1",0
FileName	dc.b	"Main",0

HighscoreName	dc.b	"HIGHSCORE",0

	CNOP	0,2

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


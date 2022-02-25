***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       ROGUE TROOPER WHDLOAD SLAVE          )*)---.---.   *
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

; 24-Feb-2022	- blitter wait patches can be disabled with CUSTOM2
;		- ByteKiller decruncher in boot code relocated
;		- access fault fix in shop screen changed, instead of
;		  reloading the crunched data, the real cause of the problem
;		  is now fixed (unitialised register when calling the
;		  routine to blit the picture)
;		- in-game keys can be displayed by pressing "HELP" during
;		  game now, adapted the in-game routine that displays the
;		  help text when "F1" is pressed to write the in-game
;		  keys
;		- this version of the patch is now finished!

; 23-Feb-2022	- unused/test code removed
;		- trainer and other patches applied to the shooter part of
;		  version 2 of the game (Christoph Gleisberg) 
;		- protection patch for shooter part in game version 2
;		  corrected (wrong offset)
;		- access fault in shop screen fixed (caused by corrupted
;		  crunched data), instead of decrunching the data from memory,
;		  the data is now always loaded from disk before decrunching
;		- all decrunches relocated (ByteKiller decruncher adapted
;		  to handle both game parts)

; 22-Feb-2022	- lots of trainer options for the first game part
;		  implemented

; 21-Feb-2022	- more trainer options and in-game keys for shooter part
;		  added
;		- blitter wait in shooter part added

; 20-Feb-2022	- lots of trainer options for shooter part implemented
;		- ByteKiller decruncher relocated and optimised, error
;		  check had to be disabled though

; 19-Feb-2022	- more in-game keys (shooter part)
;		- write to $ffff820 (Atari ST color register) in shooter
;		  part disabled
;		- added another patch for "maze game" after completing
;		  the shooter part
;		- game successfully completed!
;		- highscore load/save added


; 18-Feb-2022	- trainer stuff for shooter part

; 17-Feb-2022	- in-game keys for shooter part

; 16-Feb-2022	- patch for game part 2 (shooter) corrected, shooter
;		  part works now

; 15-Feb-2022	- level skip implemented
;		- another protection check disabled

; 14-Feb-2022	- code optimised/clean up a bit
;		- started to add trainer options

; 13-Feb-2022	- one wrong blitter wait patch corrected, game works now
;		- more blitter wait patches added
;		- write to Beamcon0 in menu/intro part disabled
;		- added more calls to patche the menu/intro in the boot code
;		- support for SPS 1414 version added

; 12-Feb-2022	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

; Trainer options
TRB_ENERGY		= 0		; unlimited energy
TRB_AMMO		= 1		; unlimited ammo
TRB_WEAPON		= 2		; weapon always available
TRB_FUEL		= 3		; unlimited fuel (shooter)
TRB_SHIELD		= 4		; unlimited shield (shooter)
TRB_NOLASERHEAT		= 7		; no laser heating (shooting)
TRB_KEYS		= 8		; in-game keys
TRB_TIME		= 9		; unlimited time (level 4)

RAWKEY_1		= $01
RAWKEY_2		= $02
RAWKEY_3		= $03
RAWKEY_4		= $04
RAWKEY_5		= $05
RAWKEY_6		= $06
RAWKEY_7		= $07
RAWKEY_8		= $08
RAWKEY_9		= $09
RAWKEY_0		= $0A

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


.config	dc.b	"C1:X:Unlimited Energy:",TRB_ENERGY+"0",";"
	dc.b	"C1:X:Weapon always available:",TRB_WEAPON+"0",";"
	dc.b	"C1:X:Unlimited Ammo:",TRB_AMMO+"0",";"
	dc.b	"C1:X:Unlimited Time (Level 4):",TRB_TIME+"0",";"
	dc.b	"C1:X:Unlimited Fuel (Shooter):",TRB_FUEL+"0",";"
	dc.b	"C1:X:Unlimited Shield (Shooter):",TRB_SHIELD+"0",";"
	dc.b	"C1:X:No Laser Heating (Shooter):",TRB_NOLASERHEAT+"0",";"
	dc.b	"C1:X:In-Game Keys (Press Help during Game):",TRB_KEYS+"0",";"
	dc.b	"C2:B:Disable Blitter Waits"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Rogue Trooper",0
	ENDC

.name	dc.b	"Rogue Trooper",0
.copy	dc.b	"1990 Krisalis",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.2 (24.02.2022)",0


	CNOP	0,4

TAGLIST		dc.l	WHDLTAG_MONITOR_GET
MONITOR_ID	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
TRAINER_OPTIONS	dc.l	0		
		dc.l	TAG_DONE

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

	; load boot
	lea	$400.w,a0
	move.l	#2*$1600,d0
	move.l	d0,d1
	moveq	#1,d2
	move.l	a0,a5
	move.l	d1,d5
	jsr	resload_DiskLoad(a2)
	move.l	d5,d0
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	lea	PLBOOT(pc),a0
	move.l	#$8000+$847e,d1		; offset to player status
	cmp.w	#$2F59,d0
	beq.b	.version_ok
	lea	PLBOOT_1441(pc),a0
	move.l	#$8000+$84a4,d1		; offset to player status
	cmp.w	#$D159,d0		; SPS 1441
	beq.b	.version_ok
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT


.version_ok
	lea	Player_Status(pc),a1
	move.l	d1,(a1)
	move.l	a5,a1
	jsr	resload_Patch(a2)

	bsr	Load_Highscores

	jmp	(a5)




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

AckCOP	move.w	#1<<4,$dff09c
	move.w	#1<<4,$dff09c
	rte

; ---------------------------------------------------------------------------
; Common patches for all game versions

PLBOOT_COMMON
	PL_START
	PL_P	$1b5e,.Get_Video_Frequency
	PL_P	$1adc,.Create_Memory_Tables
	PL_R	$1b06			; disable FPU detection
	PL_P	$1212,Load
	PL_R	$b94			; disable drive access (motor off)
	PL_P	$13fe,ByteKiller_Decrunch

	PL_PS	$3ba,PatchGame2
	PL_PS	$47a,PatchGame2
	PL_END


.Create_Memory_Tables
	lea	$11c+4.w,a0		; chip memory
	clr.l	(a0)+			; start of memory block
	move.l	#$80000,(a0)		; size
	rts

.Get_Video_Frequency
	moveq	#50,d0
	move.l	MONITOR_ID(pc),d1
	cmp.l	#NTSC_MONITOR_ID,d1
	bne.b	.not_NTSC
	moveq	#60,d0
.not_NTSC
	rts


; ---------------------------------------------------------------------------
; Game version sent by Christoph Gleisberg

PLBOOT	PL_START
	PL_PS	$420,.PatchGame
	PL_PS	$4d6,.PatchGame
	PL_PS	$530,.PatchGame
	PL_PS	$1978,.PatchGame

	PL_NEXT	PLBOOT_COMMON

.PatchGame
	lea	$8000,a6
	movem.l	d0-a6,-(a7)
	lea	PLGAME(pc),a0
	move.l	a6,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts

PatchGame2
	lea	$8000,a6
	movem.l	d0-a6,-(a7)
	lea	PLGAME2(pc),a0
	lea	$4000.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts


PLGAME	PL_START
	PL_PSS	$3fbc,Load,2
	PL_SA	$22ae,$22b6		; skip write to Beamcon0
	
	PL_SA	$27b2,$281e		; skip protection check
	PL_R	$3ea4			; disable drive access (motor off)


	PL_SA	$c498,$c49e		; skip write to $ffff8240 (Atari ST)

	PL_PS	$d4ee,Save_Highscores
	PL_P	$cbd2,BK_DECRUNCH_SHOOTER

	PL_PS	$1de2,WaitBlit_DFF000

	PL_PS	$21ca,Handle_Keys_Shooter
	PL_P	$22e4,Refresh_Energy_And_More

	; No laser heating
	PL_IFC1X	TRB_NOLASERHEAT
	PL_B	$86a4,$4a
	PL_ENDIF

	PL_PS	$c48e,.Fix_Picture_Blit
	PL_END


; This fixes trashing the first byte of the crunched data which then
; leads to an access fault. The routine which blits the picture
; expects register a1 to point to a certain flag, this register is
; not set before calling the blit routine so it points to the beginning
; of the crunched data.
.Fix_Picture_Blit
	lea	$8000+$cb06,a0		; original code
	move.l	$8000+$ba7e,a1		; set parameter for blit flag
	rts



PLGAME2	PL_START
	PL_P	$c62c,.disable_protection_check
	PL_SA	$bc68,$bc6e		; skip write to Beamcon0	

	PL_P	$c57a,BK_DECRUNCH
	
	PL_PSS	$4f78,.Handle_Keys,2

	; install blitter wait patches if CUSTOM2 has not been used
	PL_IFC2
	PL_ELSE
	PL_PS	$4008,.Fix_Blitter_Waits
	PL_ENDIF
	

	; Unlimited Energy
	PL_IFC1X	TRB_ENERGY
	PL_W	$6410+2,0
	PL_W	$6454+2,0
	PL_W	$7d12+2,0
	PL_W	$7d78+2,0
	PL_W	$8202+2,0
	PL_W	$8800+2,0
	PL_W	$9764+2,0
	PL_W	$9fbc+2,0
	PL_W	$a730+2,0
	PL_ENDIF


	; Weapon always available
	PL_IFC1X	TRB_WEAPON
	PL_PSS	$5688,.Set_Weapon,2
	PL_P	$40e0,.Draw_Ammo
	PL_ENDIF

	; Unlimited Time (Level 4)
	PL_IFC1X	TRB_TIME
	PL_W	$c04e,$4e71
	PL_ENDIF


	; Unlimited Ammo
	PL_IFC1X	TRB_AMMO
	PL_B	$7222,$4a
	PL_ENDIF


	PL_IFC1X	TRB_KEYS
	PL_PSS	$c41c,.Write_Help,2

	PL_P	$c250,.Write
	PL_P	$c158,.Clear_Flag	
	

	PL_ENDIF
	PL_END

.disable_protection_check
	moveq	#0,d0
	rts

; d0.b: rawkey code
.Handle_Keys
	bsr	Check_Quit_Key

	move.b	d0,$5d3f.w		; original code
	st	(a0,d0.w)		; =""=

	movem.l	d0-a6,-(a7)
	move.l	TRAINER_OPTIONS(pc),d1
	btst	#TRB_KEYS,d1
	beq.b	.no_ingame_keys

	lea	.KeyTab(pc),a0
	move.l	a0,a1
.loop	movem.w	(a1)+,d1/d2		; rawkey, offset to routine
	cmp.b	d0,d1
	bne.b	.check_next_entry
	jsr	(a0,d2.w)
	bra.b	.exit

.check_next_entry
	tst.w	(a1)
	bne.b	.loop
.exit


.no_ingame_keys
	movem.l	(a7)+,d0-a6
	rts

.KeyTab	dc.w	RAWKEY_N,.Skip_Level-.KeyTab
	dc.w	RAWKEY_W,.Get_Weapon-.KeyTab
	dc.w	RAWKEY_A,.Refresh_Ammo-.KeyTab
	dc.w	RAWKEY_E,.Refresh_Energy-.KeyTab
	dc.w	RAWKEY_K,.Kill_Enemy-.KeyTab

	dc.w	0			; end of table


.Refresh_Ammo
	move.w	#12,$5886.w	; bullets
	move.w	#6,$5888.w	; magazines
	move.l	$587e.w,d1
	and.b	#1<<1|1<<0,d1	; weapon bits
	beq.b	.no_ammo_display
	jsr	$4000+$5306	; update status display (draw magazine/bullets)
.no_ammo_display
	rts

.Refresh_Energy
	move.w	#$fff,$5878.w
	rts

.Skip_Level
	st	$5d3d
	st	$5e59
	rts

.Set_Weapon
	move.l	$587e.w,d1
	or.l	#1<<1,d1
	or.l	(a0,d0.w),d1
	rts

.Draw_Ammo
	bsr	.Refresh_Ammo
	sf	$5e2a.w		; original code
	rts


.Get_Weapon
	or.l	#1<<1,$587e.w	; set weapon bit
	bsr.b	.Refresh_Ammo

	st	$5e22.w		; update status display in next frame
	jmp	$4000+$71e6	; set parameters for weapon to draw

.Kill_Enemy
	jmp	$4000+$b6ec


.Write_Help
	lea	.Flag(pc),a0
	tst.b	(a0)
	bne.b	.write_keys


	lea	$5405.w,a0	; normal help text
	jmp	$4000+$50fc	; write text

.write_keys
	sf	(a0)
	addq.l	#$c42c-$c424,(a7)	; don't write music/sfx status

	lea	.Help_Text(pc),a0
	jmp	$4000+$50fc	; write text


.Write	jsr	$4000+$c13a
	lea	.Flag(pc),a0
	not.b	(a0)
	rts

.Clear_Flag
	lea	.Flag(pc),a0
	sf	(a0)

	st	$5e1d.w
	rts


.Flag	dc.b	0
	dc.b	0


.Help_Text
	dc.b	0		; x position
	dc.b	32		; y position
	dc.b	1		; color
	dc.b	"IN-GAME KEYS:",10,13
	dc.b	"-------------",10,13
	dc.b	10,13
	dc.b	"MAZE/ACTION PART:",10,13
	dc.b	"A: REFRESH AMMO   E: REFRESH ENERGY",10,13
	dc.b	"W: GET WEAPON     K: KILL ENEMY",10,13
	dc.b	"N: SKIP LEVEL",10,13
	dc.b	10,13
	dc.b	"SHOOTER PART:",10,13
	dc.b	"F: REFRESH FUEL   S: REFRESH SHIELD",10,13
	dc.b	"E: REFRESH ENERGY N: SKIP LEVEL",10,13
	dc.b	"R: GET ROCKET     H: COOL DOWN LASER",0
	dc.b	0

	CNOP	0,2



.Fix_Blitter_Waits
	movem.l	d0-a6,-(a7)
	lea	PLGAME2_BLIT(pc),a0
	lea	$4000.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	jmp	$4000+$b9d0	; call original init code



PLGAME2_BLIT
	PL_START
	PL_PSS	$53e6,WaitBlit1,2
	PL_PSS	$5412,WaitBlit1,2
	PL_PSS	$543a,WaitBlit1,2
	PL_PSS	$5466,WaitBlit1,2
	PL_PSS	$548a,WaitBlit1,2
	PL_PSS	$54a6,WaitBlit1,2
	PL_PSS	$54cc,WaitBlit1,2
	PL_PSS	$54ee,WaitBlit1,2
	PL_PS	$5516,WaitBlit2
	PL_PS	$5530,WaitBlit2
	PL_PSS	$5548,WaitBlit1,2
	PL_PS	$5576,WaitBlit3
	PL_PS	$55a6,WaitBlit3
	PL_PSS	$55d0,WaitBlit1,2
	PL_PS	$cc26,WaitBlit4
	PL_PS	$cc32,WaitBlit4
	PL_PS	$cc3e,WaitBlit4
	PL_PS	$cc68,WaitBlit5
	PL_PS	$ae40,WaitBlit6
	PL_PS	$ae66,WaitBlit6
	PL_PS	$7096,WaitBlit7
	PL_PS	$70a4,WaitBlit7
	PL_PS	$70b2,WaitBlit7
	PL_PS	$70c4,WaitBlit8
	PL_PS	$70da,WaitBlit7
	PL_PS	$70ec,WaitBlit7
	PL_PS	$70fe,WaitBlit7
	PL_PS	$6dce,WaitBlit15
	PL_PS	$6dda,WaitBlit15
	PL_PS	$6de6,WaitBlit15
	PL_PSS	$5b5e,WaitBlit10,2
	PL_PS	$5db8,WaitBlit11
	PL_PS	$5a8e,WaitBlit12
	PL_PS	$5a9c,WaitBlit13
	PL_PS	$5ab0,WaitBlit12
	PL_PSS	$5a7c,WaitBlit14,2
	PL_PS	$7804,WaitBlit16
	PL_PS	$7818,WaitBlit16
	PL_PS	$782c,WaitBlit16

	PL_PS	$6f42,WaitBlit15
	PL_PS	$6f4e,WaitBlit15
	PL_PS	$6f5a,WaitBlit15
	PL_PSS	$5f26,WaitBlit17,2
	PL_PSS	$5f44,WaitBlit17,2
	PL_PSS	$5ea4,WaitBlit1,2
	PL_END

WaitBlit1
	bsr	WaitBlit
	move.l	#$ffffffff,$44(a6)
	rts

WaitBlit2
	bsr	WaitBlit
	move.w	#$0900,$40(a6)
	rts

WaitBlit3
	bsr	WaitBlit
	move.w	#$ffff,$44(a6)
	rts

WaitBlit4
	bsr	WaitBlit
	addq.w	#2,a3
	move.l	a3,$50(a6)
	rts

WaitBlit5
	bsr	WaitBlit
	add.w	d1,a4
	move.l	a4,$50(a6)
	rts

WaitBlit6
	bsr	WaitBlit
	move.w	#$420,$58(a6)
	rts

WaitBlit7
	bsr	WaitBlit
	add.w	6(a3),a4
	rts

WaitBlit8
	bsr	WaitBlit
	move.w	#$bfa,$40(a6)
	rts

WaitBlit9
	bsr	WaitBlit
	add.w	d0,a0
	move.l	a0,$54(a6)
	rts

WaitBlit10
	bsr	WaitBlit
	move.l	a5,$54(a6)
	move.w	d7,$58(a6)
	rts

WaitBlit11
	bsr.b	WaitBlit
	move.l	#$4000+$4c20a,d3
	rts

WaitBlit12
	bsr.b	WaitBlit
	addq.w	#2,a3
	move.l	a5,$50(a6)
	rts

WaitBlit13
	bsr.b	WaitBlit
	lea	$106(a3),a3
	rts

WaitBlit14
	bsr.b	WaitBlit
	move.l	a4,$4c(a6)
	move.l	a5,$50(a6)
	rts

WaitBlit15
	bsr.b	WaitBlit
	add.w	d4,a0
	move.l	a0,$54(a6)
	rts

WaitBlit16
	bsr.b	WaitBlit
	add.w	d0,a5
	move.l	a4,$50(a6)
	rts

WaitBlit17
	bsr.b	WaitBlit
	move.l	a1,$50(a6)
	lea	$20(a1),a1
	rts

WaitBlit
	tst.b	$dff002
.wait_blit
	btst	#6,$dff002
	bne.b	.wait_blit
	rts


; ---------------------------------------------------------------------------
; SPS 1441 version

PLBOOT_1441
	PL_START
	PL_PS	$420,.PatchGame		; $384
	PL_PS	$4d6,.PatchGame
	PL_PS	$530,.PatchGame
	PL_PS	$1978,.PatchGame

	PL_NEXT	PLBOOT_COMMON

.PatchGame
	lea	$8000,a6
	movem.l	d0-a6,-(a7)
	lea	PLGAME_1441(pc),a0
	move.l	a6,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts


PLGAME_1441
	PL_START
	PL_PSS	$3fe2,Load,2
	PL_SA	$22ae,$22b6		; skip write to Beamcon0
	
	PL_SA	$27b2,$281e		; skip protection check
	PL_R	$3eae			; disable drive access (motor off)

	PL_SA	$c4be,$c4c4		; skip write to $ffff8240 (Atari ST)

	PL_PS	$d514,Save_Highscores
	PL_P	$cbf8,BK_DECRUNCH_SHOOTER

	PL_PS	$1de2,WaitBlit_DFF000

	PL_PS	$21ca,Handle_Keys_Shooter
	PL_P	$22e4,Refresh_Energy_And_More


	; No laser heating
	PL_IFC1X	TRB_NOLASERHEAT
	PL_B	$86ca,$4a
	PL_ENDIF


	PL_PS	$c4b4,.Fix_Picture_Blit

	PL_END


; See comment in "PLGAME" patch list
.Fix_Picture_Blit
	move.l	$8000+$baa4,a1		; set parameter for blit flag
	lea	$8000+$cb2c,a0		; original code
	rts



Refresh_Energy_And_More
	move.l	TRAINER_OPTIONS(pc),d0
	beq.b	.no_trainer_required
	move.l	Player_Status(pc),a1		; ptr to player status

	btst	#TRB_ENERGY,d0
	beq.b	.no_energy_trainer
	bsr	Refresh_Energy
.no_energy_trainer

	btst	#TRB_SHIELD,d0
	beq.b	.no_shield_trainer
	bsr	Refresh_Shield
.no_shield_trainer

	btst	#TRB_FUEL,d0
	beq.b	.no_fuel_trainer
	bsr	Refresh_Fuel
.no_fuel_trainer


.no_trainer_required
	movem.l	(a7)+,d0-a6
	rte



Handle_Keys_Shooter
	bsr	Check_Quit_Key

	move.b	d0,$8000+$2062			; original code, store rawkey


	movem.l	d0-a6,-(a7)
	lea	.KeyTab(pc),a0
	move.l	Player_Status(pc),a1		; ptr to player status
	move.l	(a1),a1
	bsr	Check_InGame_Keys_Shooter
	movem.l	(a7)+,d0-a6
	rts


.KeyTab	dc.w	RAWKEY_F,Refresh_Fuel-.KeyTab
	dc.w	RAWKEY_E,Refresh_Energy-.KeyTab
	dc.w	RAWKEY_S,Refresh_Shield-.KeyTab
	dc.w	RAWKEY_H,Cool_Down_Laser-.KeyTab
	dc.w	RAWKEY_R,Get_Rockets-.KeyTab

	dc.w	RAWKEY_N,.Skip_Level-.KeyTab
	dc.w	0			; end of table


.Skip_Level
	move.l	$403c.w,a0
	move.w	#32*4,(a0)
	rts




WaitBlit_DFF000
	lea	$dff000,a2
	bra.w	WaitBlit


; ---------------------------------------------------------------------------

; d0.l: destination
; d1.l: length in bytes
; d2.w: starting sector
; d3.l: mfm buffer (unused here)

Load	movem.l	d1-a6,-(a7)
	move.l	d0,a0
	move.w	d2,d0
	mulu.w	#512,d0
	moveq	#1,d2
	move.l	resload(pc),a1
	jsr	resload_DiskLoad(a1)
	movem.l	(a7)+,d1-a6
	moveq	#0,d0			; no errors
	rts

; ---------------------------------------------------------------------------

Load_Highscores
	lea	Highscore_Name(pc),a0
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.no_highscore_file

	lea	Highscore_Name(pc),a0
	lea	$400+$546.w,a1
	jsr	resload_LoadFile(a2)

.no_highscore_file
	rts

Save_Highscores
	move.l	TRAINER_OPTIONS(pc),d0
	bne.b	.no_highscore_save
	
	lea	Highscore_Name(pc),a0
	lea	$200.w,a1
	move.l	#$5e6-$546,d0
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)

.no_highscore_save
	move.w	#$300,$40a2.w	; original code
	rts


Highscore_Name	dc.b	"RogueTrooper.high",0
		CNOP	0,2


; ---------------------------------------------------------------------------

; d0.b: rawkey code

Check_Quit_Key
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	rts	


; d0.b: rawkey code
; a0.l: function table
; a1.l: pointer to player status

Check_InGame_Keys_Shooter
	move.l	TRAINER_OPTIONS(pc),d1
	btst	#TRB_KEYS,d1
	beq.b	.no_ingame_keys	

	movem.l	d0-a6,-(a7)
	move.l	a0,a2
.loop	movem.w	(a2)+,d1/d2		; rawkey, offset to routine
	cmp.b	d0,d1
	bne.b	.check_next_entry

	jsr	(a0,d2.w)
	bra.b	.exit

.check_next_entry
	tst.w	(a2)
	bne.b	.loop

.exit	movem.l	(a7)+,d0-a6

.no_ingame_keys
	rts



Refresh_Fuel
	move.w	#$7fff,$1A(a1)		; refresh fuel
	rts

Refresh_Energy
	move.w	#$7fff,$16(a1)		; refresh energy
	rts

Refresh_Shield
	move.w	#$400,$18(a1)		; refresh shield
	rts

Cool_Down_Laser
	clr.w	$1c(a1)
	rts

Get_Rockets
	bset	#22&7,$10+1(a1)

	move.l	#-1,$10(a1)
	rts


Player_Status	dc.l	0


; ---------------------------------------------------------------------------

; Bytekiller decruncher
; resourced and adapted by stingray

BK_DECRUNCH_SHOOTER
	bra.b	ByteKiller_Decrunch

BK_DECRUNCH
	bsr.b	ByteKiller_Decrunch2
	move.l	d5,d0
	tst.l	d5
	beq.b	.ok

; checksum doesn't match, file corrupt
	pea	.ErrTxt(pc)
	pea	(TDREASON_FAILMSG).w
	move.l	resload(pc),a0
	jmp	resload_Abort(a0)


.ok	move.l	d5,d0
	rts

.ErrTxt	dc.b	"Decrunching failed, file corrupt!",0
	cnop	0,4

ByteKiller_Decrunch
	move.l	(a1)+,d0		; crunched length
	add.l	a1,d0
	move.l	a0,a1
	move.l	d0,a0

ByteKiller_Decrunch2
	move.l	-(a0),a2
	add.l	a1,a2			; end of decrunched data
	move.l	-(a0),d5		; checksum
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


	

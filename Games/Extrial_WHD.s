***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(         EXTRIAL WHDLOAD SLAVE              )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              March 2022                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 10-Mar-2022	- help screen to display in-game keys added
;		- one more in-game key added
;		- random crashes caused by the replayer fixed (uninitialised
;		  level 6 interrupt)
;		- 2 more out of bounds blits in level 1 and level 2 fixed
;		- game fully tested, no faults!

; 09-Mar-2022	- a lot more trainer options added
;		- remaining interrupt fixes done
;		- CUSTOM2 tooltype to disable blitter wait patches added

; 08-Mar-2022	- work started
;		- intro and game patched (Bplcon0 color bit fixes (x15),
;		  interrupts fixed, blitter waits added (x39), out of
;		  bounds blits fixed (x2), trainer options added, keyboard
;		  interrupt added to allow quit on 68000, all ByteKiller
;		  decrunchers relocated)


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

; Trainer options
TRB_LIVES	= 0		; unlimited lives	
TRB_INV		= 1		; invincibility
TRB_AUTOFIRE	= 2		; auto-fire always enabled
TRB_POWERUPS	= 3		; all power ups enabled
TRB_KEYS	= 4		; in-game keys


RAWKEY_1	= $01
RAWKEY_2	= $02
RAWKEY_3	= $03
RAWKEY_4	= $04
RAWKEY_5	= $05
RAWKEY_6	= $06
RAWKEY_7	= $07
RAWKEY_8	= $08
RAWKEY_9	= $09
RAWKEY_0	= $0A

RAWKEY_Q	= $10
RAWKEY_W	= $11
RAWKEY_E	= $12
RAWKEY_R	= $13
RAWKEY_T	= $14
RAWKEY_Y	= $15		; English layout
RAWKEY_U	= $16
RAWKEY_I	= $17
RAWKEY_O	= $18
RAWKEY_P	= $19

RAWKEY_A	= $20
RAWKEY_S	= $21
RAWKEY_D	= $22
RAWKEY_F	= $23
RAWKEY_G	= $24
RAWKEY_H	= $25
RAWKEY_J	= $26
RAWKEY_K	= $27
RAWKEY_L	= $28

RAWKEY_Z	= $31		; English layout
RAWKEY_X	= $32
RAWKEY_C	= $33
RAWKEY_V	= $34
RAWKEY_B	= $35
RAWKEY_N	= $36
RAWKEY_M	= $37

RAWKEY_HELP	= $5f
	
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
	dc.l	524288			; ws_ExpMem
	dc.w	.name-HEADER		; ws_name
	dc.w	.copy-HEADER		; ws_copy
	dc.w	.info-HEADER		; ws_info

; v16
	dc.w	0			; ws_kickname
	dc.l	0			; ws_kicksize
	dc.w	0			; ws_kickcrc

; v17
	dc.w	.config-HEADER		; ws_config


.config	dc.b	"C1:X:Unlimited Lives:",TRB_LIVES+"0",";"
	dc.b	"C1:X:Invincibility:",TRB_INV+"0",";"
	dc.b	"C1:X:Auto/Constant Fire:",TRB_AUTOFIRE+"0",";" 
	dc.b	"C1:X:All Power Ups:",TRB_POWERUPS+"0",";"
	dc.b	"C1:X:In-Game Keys (Press Help during Game):",TRB_KEYS+"0",";"
	dc.b	"C2:B:Disable Blitter Waits;"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Games/Extrial/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Extrial",0
.copy	dc.b	"1995 Computec Verlag",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.1 (10.03.2022)",0


Intro_Name	dc.b	"Intro",0
Game_Name	dc.b	"Extrial",0

	CNOP	0,4


TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
ATTN_FLAGS	dc.l	0
		dc.l	TAG_DONE

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

	; install level 2 interrupt
	bsr	Init_Level2_Interrupt

	; load intro
	lea	Intro_Name(pc),a0
	lea	$1100.w,a1
	move.l	a1,a5
	bsr	Load_File

	; version check
	move.l	a5,a0
	move.l	#$138,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$FD31,d0
	beq.b	.version_ok
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.version_ok

	; initialise default level 6 interrupt to avoid crashes
	; caused by the replayer
	pea	Default_Level6_Interrupt(pc)
	move.l	(a7)+,$78.w

	; relocate intro
	move.l	a5,a0
	sub.l	a1,a1			; no tags
	jsr	resload_Relocate(a2)

	; patch intro
	lea	PLINTRO(pc),a0
	lea	$1100.w,a1
	jsr	resload_Patch(a2)

	; run intro
	jsr	(a5)


	; load crunched game data
	lea	Game_Name(pc),a0
	move.l	HEADER+ws_ExpMem(pc),a1
	lea	$19b6+$20(a1),a3
	move.l	a3,$84.w
	bsr	Load_File

	; decrunch
	move.l	HEADER+ws_ExpMem(pc),a0
	add.w	#$182+$20,a0
	lea	$7d6fc,a1
	move.l	a1,a5
	bsr	BK_DECRUNCH

	; patch game
	lea	PLGAME(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	; relocate stack to end of fast memory
	move.l	HEADER+ws_ExpMem(pc),a7
	add.l	#524288,a7
	lea	-1024(a7),a0
	move.l	a0,USP

	; and run it
	jmp	(a5)


; ---------------------------------------------------------------------------

PLINTRO	PL_START
	PL_ORW	$68a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$71e+2,1<<9		; set Bplcon0 color bit
	PL_PSA	$9c,.Restore_Copperlist,$b4
	PL_P	$1ac,.AckVBI
	PL_W	$6a2,$1fe		; FMODE -> NOP
	PL_W	$5ce,$1fe		; FMODE -> NOP
	PL_PS	$48e,WaitBlit1
	PL_PS	$41a,WaitBlit2
	PL_ORW	$15a+2,1<<3		; enable level 2 interrupts
	PL_END

.Restore_Copperlist
	lea	$1000.w,a0
	move.l	a0,$dff080
	rts

.AckVBI	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte

WaitBlit1
	bsr	WaitBlit
	move.w	d0,$40(a0)
	clr.w	d0
	rts

WaitBlit2
	lea	$dff000,a0
	bra.w	WaitBlit

; ---------------------------------------------------------------------------

PLGAME	PL_START
	PL_ORW	$1904+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$195c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$156+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$f6+2,1<<9		; set Bplcon0 color bit
	PL_W	$1960,$1fe		; FMODE -> NOP
	PL_PS	$33a,WaitBlit1
	PL_PS	$2c2,WaitBlit2
	PL_P	$1c0,BK_DECRUNCH	; relocate ByteKiller decruncher
	PL_PS	$d6,.Patch_Level
	PL_END


.Patch_Level
	moveq	#0,d0
	move.b	$80.w,d0		; level number
	move.w	d0,d1
	mulu.w	#3*4,d0
	lea	$7d6fc+$19c,a0
	move.l	1*4(a0,d0.w),a1		; destination
	add.w	d1,d1
	move.w	.Tab(pc,d1.w),d1
	lea	.Tab(pc,d1.w),a0
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	lea	$7d6fc+$17e2,a6
	rts

.Tab	dc.w	PLLEVEL1-.Tab
	dc.w	PLLEVEL2-.Tab
	dc.w	PLLEVEL3-.Tab

; ---------------------------------------------------------------------------

PLLEVEL1
	PL_START
	PL_S	$3b7d4,6		; skip write to FMODE
	PL_P	$3bb1a,Ack_Level1
	PL_P	$3bb2c,Ack_Level1
	
	PL_P	$3bb78,Ack_Level5
	PL_P	$445fa,Ack_Level6
	PL_ORW	$3e45a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3e46a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3e4da+2,1<<9		; set Bplcon0 color bit

	PL_P	$3e326,.FixBlit
	PL_PS	$3dd02,FixBlit

	PL_IFC2
	PL_ELSE
	PL_PS	$3b96e,WaitBlit2
	PL_PSS	$3b9f8,WaitBlit3,2
	PL_PS	$3b9d2,WaitBlit4
	PL_PS	$3de46,WaitBlit2
	PL_PS	$3df2c,WaitBlit4
	PL_PS	$3deee,WaitBlit5
	PL_PSS	$3e078,WaitBlit6,2
	PL_PSS	$3de90,WaitBlit7,2
	PL_PS	$3e204,WaitBlit8
	PL_PSS	$3e2f8,WaitBlit9,2
	PL_PS	$3e246,WaitBlit8
	PL_PS	$3e286,WaitBlit8
	PL_PSS	$3e130,WaitBlit10,2
	PL_ENDIF

	PL_ORW	$3b950+2,1<<3		; enable level 2 interrupts

	; In-Game Keys
	PL_IFC1X	TRB_KEYS
	PL_PSS	$3bacc,.Check_Keys,2
	PL_ENDIF

	; Unlimited Lives
	PL_IFC1X	TRB_LIVES
	PL_B	$3b848,$4a
	PL_ENDIF

	; auto/constant fire
	PL_IFC1X	TRB_AUTOFIRE
	PL_B	$3c954,$60
	PL_ENDIF


	; All power ups
	PL_IFC1X	TRB_POWERUPS
	PL_PSS	$3b826,.Enable_Power_Ups,2
	PL_ENDIF


	; Invincibility
	PL_IFC1X	TRB_INV
	PL_R	$3c418
	PL_ENDIF
	PL_END



.Enable_Power_Ups
	btst	#0,$38a30+$3e4eb	; level init sequence done?
	beq.b	.not_ready_yet		; if not, do not enable power ups

	bsr.b	.Enable_Shield
	bsr.b	.Enable_Extra_Weapon
	bsr.b	.Enable_Jetpack
	bsr.b	.Enable_Auto_Fire

.not_ready_yet
	btst	#2,$dff01c+1
	rts


.Check_Keys
	lea	.KeyTable(pc),a0
	bsr	Handle_Keys
	jsr	$38a30+$3bc28
	jmp	$38a30+$3bcfc


.KeyTable
	dc.w	RAWKEY_S,.Enable_Shield-.KeyTable
	dc.w	RAWKEY_N,.Skip_Level-.KeyTable
	dc.w	RAWKEY_E,.Enable_Extra_Weapon-.KeyTable
	dc.w	RAWKEY_R,.Rescue_People-.KeyTable
	dc.w	RAWKEY_J,.Enable_Jetpack-.KeyTable
	dc.w	RAWKEY_A,.Enable_Auto_Fire-.KeyTable
	dc.w	RAWKEY_L,Add_Life-.KeyTable
	dc.w	RAWKEY_HELP,Show_Help_Screen-.KeyTable
	dc.w	0


.Enable_Shield
	bset	#0,$38a30+$3e617	; shield
	move.b	#127,$38a30+$430d5	; time
	rts

.Enable_Extra_Weapon
	bset	#0,$38a30+$3e5e5	; extra weapon
	move.b	#127,$38a30+$430d4	; time
	rts

.Enable_Jetpack
	bset	#0,$38a30+$3e649
	clr.w	$38a30+$3cc94
	rts

.Enable_Auto_Fire
	move.w	#8*50,$38a30+$3cae6
	rts

.Rescue_People
	clr.b	$38a30+$3e99e
	rts

.Skip_Level
	move.w	#$13e4+1,$38a30+$3e4f0
	bra.w	Disable_Level1_Interrupt


.FixBlit
	cmp.l	#$80000,d4
	bcc.b	.no_blit
	move.w	#(48<<6)|(16/16),$58(a0)
.no_blit
	rts

WaitBlit3
	bsr	WaitBlit
	move.l	d0,$50(a0)
	move.l	d1,$4c(a0)
	rts

WaitBlit4
	bsr	WaitBlit
	move.w	#$09f0,$40(a0)
	rts

WaitBlit5
	bsr	WaitBlit
	move.w	$2a(a1),$64(a0)
	rts

WaitBlit6
	bsr	WaitBlit
	move.w	d4,$60(a0)
	move.w	d4,$66(a0)
	rts

WaitBlit7
	bsr	WaitBlit
	move.l	#$ffff0000,$44(a0)
	rts

WaitBlit8
	bsr	WaitBlit
	move.w	#$0900,$40(a0)
	rts

WaitBlit9
	bsr	WaitBlit
	move.w	d0,$40(a0)
	clr.w	$42(a0)
	rts

WaitBlit10
	bsr	WaitBlit
	move.w	d3,$64(a0)
	move.w	d3,$62(a0)
	rts

; ---------------------------------------------------------------------------

PLLEVEL2
	PL_START
	PL_P	$3a32e,Ack_Level1
	PL_P	$3a31c,Ack_Level1
	PL_P	$3a34a,Ack_Level4
	PL_P	$3a37a,Ack_Level5
	PL_P	$41f7e,Ack_Level6
	PL_ORW	$3cf86+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3cf96+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3d006+2,1<<9		; set Bplcon0 color bit
	PL_W	$3ce8e,$1fe		; FMODE -> NOP

	PL_PS	$3c82e,FixBlit

	PL_IFC2
	PL_ELSE
	PL_PS	$3a170,WaitBlit2
	PL_PSS	$3a1fa,WaitBlit3,2
	PL_PS	$3a1d4,WaitBlit4
	PL_PS	$3ca54,WaitBlit4
	PL_PS	$3c96e,WaitBlit2
	PL_PSS	$3cba0,WaitBlit6,2
	PL_PS	$3ca16,WaitBlit5
	PL_PSS	$3c9b8,WaitBlit7,2
	PL_PS	$3cd2c,WaitBlit8
	PL_PSS	$3ce20,WaitBlit9,2
	PL_PS	$3cd6e,WaitBlit8
	PL_PS	$3cdae,WaitBlit8
	PL_PSS	$3cc58,WaitBlit10,2
	PL_ENDIF

	PL_ORW	$3a152+2,1<<3		; enable level 2 interrupts

	; In-Game Keys
	PL_IFC1X	TRB_KEYS
	PL_PSS	$3a2ce,.Check_Keys,2
	PL_ENDIF

	; Unlimited Lives
	PL_IFC1X	TRB_LIVES
	PL_B	$3a04a,$4a
	PL_ENDIF

	; auto/constant fire
	PL_IFC1X	TRB_AUTOFIRE
	PL_B	$3b168,$60
	PL_ENDIF


	; All power ups
	PL_IFC1X	TRB_POWERUPS
	PL_PSS	$3a028,.Enable_Power_Ups,2
	PL_ENDIF


	; Invincibility
	PL_IFC1X	TRB_INV
	PL_R	$3ac2e
	PL_ENDIF
	PL_END


.Enable_Power_Ups
	bsr.b	.Enable_Shield
	bsr.b	.Enable_Extra_Weapon
	bsr.b	.Enable_Jetpack
	bsr.b	.Enable_Auto_Fire

.not_ready_yet
	btst	#2,$dff01c+1
	rts

.Check_Keys
	lea	.KeyTable(pc),a0
	bsr	Handle_Keys
	jsr	$39b60+$3a42a
	jmp	$39b60+$3a4fe

.KeyTable
	dc.w	RAWKEY_S,.Enable_Shield-.KeyTable
	dc.w	RAWKEY_N,.Skip_Level-.KeyTable
	dc.w	RAWKEY_E,.Enable_Extra_Weapon-.KeyTable
	dc.w	RAWKEY_R,.Rescue_People-.KeyTable
	dc.w	RAWKEY_J,.Enable_Jetpack-.KeyTable
	dc.w	RAWKEY_A,.Enable_Auto_Fire-.KeyTable
	dc.w	RAWKEY_L,Add_Life-.KeyTable
	dc.w	RAWKEY_HELP,Show_Help_Screen-.KeyTable
	dc.w	0


.Enable_Shield
	bset	#0,$39b60+$3d143	; shield
	move.b	#127,$39b60+$40687	; time
	rts

.Enable_Extra_Weapon
	bset	#0,$39b60+$3d111	; extra weapon
	move.b	#127,$39b60+$40686	; time
	rts

.Enable_Jetpack
	bset	#0,$39b60+$3d175
	clr.w	$39b60+$3b4a8
	rts

.Enable_Auto_Fire
	move.w	#8*50,$39b60+$3b2fa
	rts

.Rescue_People
	clr.b	$39b60+$3d592
	rts

.Skip_Level
	move.w	#$13e4+1,$39b60+$3d01c
	bra.w	Disable_Level1_Interrupt


; ---------------------------------------------------------------------------

PLLEVEL3
	PL_START
	PL_P	$3aae6,Ack_Level1
	PL_P	$3aaf8,Ack_Level1
	PL_P	$3ab14,Ack_Level4
	PL_P	$3ab44,Ack_Level5
	PL_P	$4348e,Ack_Level6
	PL_ORW	$3d73e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3d74e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3d7be+2,1<<9		; set Bplcon0 color bit
	PL_W	$3d646,$1fe		; FMODE -> NOP

	PL_PS	$3cfe6,FixBlit

	PL_IFC2
	PL_ELSE
	PL_PS	$3a93a,WaitBlit2
	PL_PSS	$3a9c4,WaitBlit3,2
	PL_PS	$3a99e,WaitBlit4
	PL_PS	$3d20c,WaitBlit4
	PL_PS	$3d126,WaitBlit2
	PL_PSS	$3d358,WaitBlit6,2
	PL_PS	$3d1ce,WaitBlit5
	PL_PSS	$3d170,WaitBlit7,2
	PL_PS	$3d4e4,WaitBlit8
	PL_PSS	$3d5d8,WaitBlit9,2
	PL_PS	$3d526,WaitBlit8
	PL_PS	$3d566,WaitBlit8
	PL_PSS	$3d410,WaitBlit10,2
	PL_ENDIF

	PL_ORW	$3a91c+2,1<<3		; enable level 2 interrupts

	; In-Game Keys
	PL_IFC1X	TRB_KEYS
	PL_PSS	$3aa98,.Check_Keys,2
	PL_ENDIF

	; Unlimited Lives
	PL_IFC1X	TRB_LIVES
	PL_B	$3a7e4,$4a
	PL_ENDIF

	; auto/constant fire
	PL_IFC1X	TRB_AUTOFIRE
	PL_B	$3b920,$60
	PL_ENDIF


	; All power ups
	PL_IFC1X	TRB_POWERUPS
	PL_PSS	$3a7b6,.Enable_Power_Ups,2
	PL_ENDIF


	; Invincibility
	PL_IFC1X	TRB_INV
	PL_R	$3b3e4
	PL_ENDIF
	PL_END


.Enable_Power_Ups
	bsr.b	.Enable_Shield
	bsr.b	.Enable_Extra_Weapon
	bsr.b	.Enable_Jetpack
	bsr.b	.Enable_Auto_Fire

.not_ready_yet
	btst	#2,$dff01c+1
	rts

.Check_Keys
	lea	.KeyTable(pc),a0
	bsr	Handle_Keys
	jsr	$39b60+$3abf4
	jmp	$39b60+$3acc8

.KeyTable
	dc.w	RAWKEY_S,.Enable_Shield-.KeyTable
	dc.w	RAWKEY_N,.Skip_Level-.KeyTable
	dc.w	RAWKEY_E,.Enable_Extra_Weapon-.KeyTable
	dc.w	RAWKEY_R,.Rescue_People-.KeyTable
	dc.w	RAWKEY_J,.Enable_Jetpack-.KeyTable
	dc.w	RAWKEY_A,.Enable_Auto_Fire-.KeyTable
	dc.w	RAWKEY_L,Add_Life-.KeyTable
	dc.w	RAWKEY_HELP,Show_Help_Screen-.KeyTable
	dc.w	0


.Enable_Shield
	bset	#0,$39b60+$3d8fb	; shield
	move.b	#127,$39b60+$413c7	; time
	rts

.Enable_Extra_Weapon
	bset	#0,$39b60+$3d8c9	; extra weapon
	move.b	#127,$39b60+$413c6	; time
	rts

.Enable_Jetpack
	bset	#0,$39b60+$3d92d
	clr.w	$39b60+$3bc60
	rts

.Enable_Auto_Fire
	move.w	#8*50,$39b60+$3bab2
	rts

.Rescue_People
	clr.b	$39b60+$3dd4a
	rts

.Skip_Level
	move.w	#$1364+1,$39b60+$3d7d4
	bset	#0,$39b60+$3f4b7
	bra.w	Disable_Level1_Interrupt

FixBlit
	cmp.l	#$80000,d2
	bcc.b	.no_blit
	move.w	#(16<<6)|(16/16),$58(a0)
.no_blit
	rts


; ---------------------------------------------------------------------------
; Common in-game key routines for all game levels.

Add_Life
	cmp.b	#9,$82.w
	beq.b	.maximum_lifes_reached
	addq.b	#1,$82.w
.maximum_lifes_reached
	rts

Show_Help_Screen
	lea	.Text(pc),a0
	bsr	HS_GetScreenHeight
	addq.w	#1,d0
	mulu.w	#640/8,d0

	lea	$200.w,a1

	; save screen data
	move.l	USP,a2
	sub.w	d0,a2
	bsr.b	.Copy_Memory

	; clear screen memory
	move.l	d0,d1
.cls	clr.b	(a1)+
	subq.l	#1,d1
	bne.b	.cls

	lea	$200.w,a1
	bsr	ShowHelpScreen

	; restore data
	move.l	USP,a1
	sub.w	d0,a1
	lea	$200.w,a2

.Copy_Memory
	movem.l	d0/a1/a2,-(a7)
.Copy_Memory_Loop
	move.b	(a1)+,(a2)+
	subq.l	#1,d0
	bne.b	.Copy_Memory_Loop
	movem.l	(a7)+,d0/a1/a2
	rts


.Text	dc.b	"    Extrial In-Game Keys",10
	dc.b	10
	dc.b	"E: Get Extra Weapon   N: Skip Level",10
	dc.b	"J: Get Jetpack        S: Get Shield",10
	dc.b	"A: Enable auto fire   R: Rescue People",10
	dc.b	"L: Add Life",10
	dc.b	10
	dc.b	"Press left mouse button or fire to return to game.",10
	dc.b	0
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


WaitBlit
	tst.b	$dff002
.wait_blit
	btst	#6,$dff002
	bne.b	.wait_blit
	rts

; Acknowledge level 1 interrupt
Ack_Level1
	move.w	#1<<2,$dff09c
	move.w	#1<<2,$dff09c
	rte

; Acknowdlege level 4 interrupt
Ack_Level4
	move.w	#1<<7,$dff09c
	move.w	#1<<7,$dff09c
	rte	

; Acknowledge level 5 interrupt
Ack_Level5
	move.w	#1<<11,$dff09c
	move.w	#1<<11,$dff09c
	rte
	
; Default "empty" level 6 interrupt
Default_Level6_Interrupt
	tst.b	$bfdd00

; Acknowledge level 6 interrupt
Ack_Level6
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte

; Disable level 1 interrupt
Disable_Level1_Interrupt
	move.w	#1<<2,$dff09c
	move.w	#1<<2,$dff09a
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
; ----
; d0.l : result (0 = file does not exist)
File_Exists
	movem.l	d1-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	movem.l	(a7)+,d1-a6
	rts	


; ---------------------------------------------------------------------------

; d0.b: rawkey code

Check_Quit_Key
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	rts	

; ---------------------------------------------------------------------------
; Key handling.
;
; a0.l: pointer to key table

Handle_Keys
	moveq	#0,d0
	move.b	RawKey(pc),d0
	lea	.Last_Key(pc),a1
	cmp.b	(a1),d0
	beq.b	.exit
	move.b	d0,(a1)

	move.l	a0,a1
.check_entries
	movem.w	(a1)+,d1/d2			; key, routine to call
	cmp.w	d0,d1
	beq.b	.key_found
	tst.w	(a1)
	bne.b	.check_entries
.exit	rts

.key_found
	jmp	(a0,d2.w)

.Last_Key	dc.b	0
		dc.b	0


; ---------------------------------------------------------------------------
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

	bsr.w	Check_Quit_Key

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

; ---------------------------------------------------------------------------

; Bytekiller decruncher
; resourced and adapted by stingray
;
; a0.l: source
; a1.l: destination

BK_DECRUNCH
	bsr.b	.decrunch
	tst.l	d5
	beq.b	.ok

; checksum doesn't match, file corrupt
	pea	ErrText(pc)
	pea	(TDREASON_FAILMSG).w
	bra.w	EXIT

.ok	rts


.decrunch
	move.l	(a0)+,d0		; crunched length
	move.l	(a0)+,d1		; decrunched length
	move.l	(a0)+,d5		; checksum
	add.l	d0,a0			; end of crunched data
	lea	(a1,d1.l),a2		; end of decrunched data
	move.l	-(a0),d0		; get first long
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

.next

	cmp.l	a2,a1
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


ErrText	dc.b	"Decrunching failed, file corrupt!",0



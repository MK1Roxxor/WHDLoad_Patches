***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(           HOI WHDLOAD SLAVE                )*)---.---.   *
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

; 24-Dec-2022	- endsequence patched
;		- this patch is now finished!

; 23-Dec-2022	- remaining patches for level 5 added
;		- keyboard routine for hiscore part fixed, name can now
;		  be entered
;		- loader patch in hiscore binary extended to support saving
;		  highscores
;		- running game without intro sequence works now too
;		- access faults in replayer code in title screen part
;		  (file: "intro") fixed
;		- trainer options added
;		- blitter wait patches can be disabled with CUSTOM2
;		- if NTSC game mode is selected, an error message will be
;		  displayed if no NTSC monitor driver is available or WHDLoad
;		  was not started with  "NTSC" tooltype

; 22-Dec-2022	- all level binaries patched

; 21-Dec-2022	- most parts patched (lots of work!), game level 1 works
;		- default quitkey set to Del, F10 is used in the game

; 20-Dec-2022	- work restarted from scratch


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	hardware/dmabits.i
	INCLUDE	hardware/intbits.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $46		; Del
;DEBUG

; Trainer options
TRB_UNLIMITED_LIVES	= 0
TRB_INVULNERABILITY	= 1
TRB_IN_GAME_KEYS	= 2

RAWKEY_L		= $28
RAWKEY_I		= $17
RAWKEY_R		= $13
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
	dc.b	"C1:X:Invulnerability:",TRB_INVULNERABILITY+"0",";"
	dc.b	"C1:X:In-Game Keys:",TRB_IN_GAME_KEYS+"0",";"
	dc.b	"C2:B:Disable Blitter Wait Patches"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Games/Hoi/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Hoi",0
.copy	dc.b	"1992 Hollyware",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.00 (24.12.2022)",10
	dc.b	"In-Game Keys:",10
	dc.b	"L: Toggle unlimited Lives I: Toggle Invulnerability",10
	dc.b	"R: Refresh Lives N: Skip Level",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load loader code
	lea	LoaderCodeName(pc),a0
	lea	$10000,a1
	bsr	Load_File

	move.l	a1,a5

	; Version check
	move.l	a1,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$851a,d0		; SPS 0962
	beq.b	.Version_is_Supported

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.Version_is_Supported
	
	lea	PL_LOADERCODE(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; Create copperlist at $420, game uses this address to
	; restore default copperlists
	move.l	#-2,$420.w

	clr.l	-(a7)			; TAG_DONE
	clr.l	-(a7)			; data
	pea	WHDLTAG_CUSTOM1_GET
	move.l	a7,a0
	jsr	resload_Control(a2)
	move.w	6(a7),d0
	add.w	#3*4,a7
	lea	In_Game_Keys_Enabled(pc),a0
	btst	#TRB_IN_GAME_KEYS,d0
	sne	(a0)

.no_in_game_keys
	
	; Start game
	jmp	(a5)


LoaderCodeName		dc.b	"ILOADER",0
In_Game_Keys_Enabled	dc.b	0
		CNOP	0,2


; ---------------------------------------------------------------------------

PL_LOADERCODE
	PL_START
	PL_SA	$0,$10			; skip Supervisor()
	PL_SA	$aa,$e2			; skip installing resident code
	PL_ORW	$22+2,DMAF_MASTER	; enable DMA channels
	PL_PS	$7e,.Set_Keyboard_Interrupt
	PL_SA	$2d4,$354
	PL_SA	$358,$3a0
	PL_P	$3a4,Load_File_a1_a6
	PL_PS	$10a,.Patch_Select
	PL_PS	$296,.Patch_Intro
	PL_P	$184,.Patch_Intro_Anim
	PL_P	$2ce,.Patch_Hiloader
	PL_P	$1fa,.Patch_Hiloader
	PL_END

.Patch_Select
	lea	PL_SELECT(pc),a0
	pea	$50000
	bra.b	Patch_And_Run

.Patch_Intro
	lea	PL_INTRO(pc),a0
	pea	$17000
	bra.b	Patch_And_Run

.Patch_Hiloader
	lea	PL_HILOADER(pc),a0
	pea	$14000
	bra.b	Patch_And_Run

.Patch_Intro_Anim
	lea	PL_INTRO_ANIM(pc),a0
	lea	$324f8,a1
	bsr	Apply_Patches
	jmp	$7e000


.Set_Keyboard_Interrupt
	bsr	Init_Level2_Interrupt
	move.l	a1,$dff080		; original code
	rts

Load_File_a1_a6
	move.l	a1,a0
	move.l	(a6),a1
	bra.w	Load_File

Patch_And_Run
	move.l	(a7)+,a1
	movem.l	d0-d7,-(a7)
	bsr.b	Decrunch_If_Needed
	movem.l	(a7)+,d0-d7
	move.l	a1,-(a7)
	bra.w	Apply_Patches

; ---------------------------------------------------------------------------

; a1.l: binary
; ----
; a1.l: start of decrunched data

Decrunch_If_Needed
	move.l	a0,-(a7)
	cmp.l	#$20182218,$26(a1)	; move.l (a0)+,d0 move.l (a0)+,d1
	bne.b	.Not_ByteKiller_Crunched


	; Determine start of crunched data
	lea	$f4(a1),a0

	; Determine destination address
	move.l	6+2(a1),-(a7)

	; Decrunch
	move.l	(a7),a1
	bsr	BK_DECRUNCH

	; Return address of decrunched data
	move.l	(a7)+,a1

.Not_ByteKiller_Crunched
	move.l	(a7)+,a0
	rts


; ---------------------------------------------------------------------------

PL_SELECT
	PL_START
	PL_ORW	$832+2,1<<9		; set Bplcon0 color bit
	PL_SA	$14e,$156		; skip write to BEAMCON0 (PAL)
	;PL_SA	$15a,$162		; skip write to BEAMCON0 (NTSC)
	PL_PSS	$15a,.Check_NTSC_Monitor,2
	PL_PS	$2a,.Enable_Keyboard_Interrupt
	PL_END

.Enable_Keyboard_Interrupt
	bsr	Enable_Keyboard_Interrupt
	add.l	#$7800,a0		; original code
	rts

.Check_NTSC_Monitor
	clr.l	-(a7)			; TAG_DONE
	clr.l	-(a7)			; data
	pea	WHDLTAG_MONITOR_GET
	move.l	a7,a0
	move.l	resload(pc),a2
	jsr	resload_Control(a2)
	cmp.l	#NTSC_MONITOR_ID,4(a7)
	bne.b	.Error_No_NTSC_Monitor
	add.w	#3*4,a7
	rts

.Error_No_NTSC_Monitor
	pea	(TDREASON_MUSTNTSC).w
	bra.w	EXIT
	


; ---------------------------------------------------------------------------

PL_INTRO
	PL_START
	PL_SA	$82a,$832		; don't modify level 3 interrupt code
	PL_P	$a96,Acknowledge_Level3_Interrupt

	; Access fault fixes for the replayer code.
	; jsr doesn't work for some reason, so jmp needs to be used to call
	; the fix routines.
	PL_P	$1ac2,.Fix_Access_Fault
	PL_P	$1ab4,.Fix_Access_Fault2
	PL_END

.Fix_Access_Fault
	moveq	#0,d6
	cmp.l	#$80000,a3
	bcc.b	.exit
	add.w	d0,d1
	lea	(a3,d5.w),a6
	cmp.l	#$80000,a6
	bcs.b	.ok
	moveq	#0,d5
.ok	move.b	(a3,d5.w),d6
.exit	jmp	$18000+$1ac8

.Fix_Access_Fault2
	moveq	#0,d6
	cmp.l	#$80000,a2
	bcc.b	.exit2
	add.w	d0,d1
	lea	(a2,d4.w),a6
	cmp.l	#$80000,a6
	bcs.b	.ok2
	moveq	#0,d4
.ok2	move.b	(a2,d4.w),d6
.exit2	jmp	$18000+$1aba


; ---------------------------------------------------------------------------

PL_INTRO_ANIM
	PL_START
	PL_SA	$4bb42,$4bb4a		; skip write to lowpass filter
	PL_PSS	$4bdce,Acknowledge_Level3_Interrupt_Request,2
	PL_ORW	$4bb62+2,INTF_PORTS	; enable level 2 interrupts
	PL_ORW	$4c4a4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$4c5b0+2,1<<9		; set Bplcon0 color bit
	PL_P	$4bf9e,BK_DECRUNCH
	PL_PS	$4be38,Wait_Blit_d0_dff054
	PL_END


Wait_Blit_d0_dff054
	bsr	Wait_Blit
	move.l	d0,$dff054
	rts

; ---------------------------------------------------------------------------

PL_HILOADER
	PL_START
	PL_S	$4c,6			; don't load "diskchange" file
	PL_S	$5a,6			; don't run "diskchange" code
	PL_P	$fc,.Load_File
	PL_P	$d6,.Patch_Hiscore
	PL_END


.Patch_Hiscore
	moveq	#0,d0			; clear score
	lea	PL_HISCORE(pc),a0
	pea	$18000
	bra.w	Patch_And_Run

.Load_File
	lea	$14000+$4b6,a0
	move.l	$14000+$4ae,a1
	bra.w	Load_File

; ---------------------------------------------------------------------------

PL_HISCORE
	PL_START
	PL_P	$30c,Acknowledge_Level3_Interrupt
	PL_P	$345c,.Load_File
	PL_PS	$24,.Copy_Replayer_Code_And_Flush_Cache
	PL_ORW	$1a2+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1be+2,1<<9		; set Bplcon0 color bit
	PL_SA	$102b8,$102c0		; don't modify level 3 interrupt code
	PL_P	$10444,Acknowledge_Level3_Interrupt
	PL_P	$2ae,.Patch_Level_Loader
	PL_PSS	$338,.Set_Keyboard_Routine,4
	PL_P	$2fa,.Remove_Keyboard_Routine
	PL_R	$3c6			; return from level 2 interrupt code
	PL_PS	$17ac,.Fix_Blit_Access

	PL_IFC1
	PL_S	$25e,6			; skip highscore saving
	PL_ENDIF

	PL_IFC2
	PL_ELSE
	PL_PS	$732,Wait_Blit_a3_dff050
	PL_PSS	$129e,Wait_Blit_ffffffff_dff044,4
	PL_PSS	$16b8,Wait_Blit_Var_dff054,4
	PL_PS	$1770,Wait_Blit_dff000_a6
	PL_ENDIF
	PL_END

.Fix_Blit_Access
	move.l	(a2,d1.w),d1
	add.w	d0,d1
	and.l	#$ffff,d1
	rts


.Set_Keyboard_Routine
	pea	.Keyboard_Routine(pc)
	bra.w	Set_Keyboard_Custom_Routine

.Remove_Keyboard_Routine
	bsr	Remove_Keyboard_Custom_Routine
	bra.w	Enable_Keyboard_Interrupt


.Keyboard_Routine
	move.b	Key(pc),$21350+$3cc
	move.b	RawKey(pc),d0
	jmp	$21350+$3a8
	


.Patch_Level_Loader
	lea	PL_LEVEL_LOADER(pc),a0
	pea	$f800
	bra.w	Patch_And_Run


; Mugician replayer code will be copied to $400.w
.Copy_Replayer_Code_And_Flush_Cache
	jsr	$21350+$3dc
	bra.w	Flush_Cache

.Load_File
	lea	$21350+$3fd2,a0
	move.l	$21350+$4006,a1
	cmp.w	#1,$21350+$400e
	beq.b	.Save_File
	bra.w	Load_File

.Save_File
	move.l	$21350+$4000,d0		; size
	bra.w	Save_File	
	
	

Wait_Blit_a3_dff050
	bsr	Wait_Blit
	move.l	a3,$dff050
	rts

Wait_Blit_ffffffff_dff044
	bsr	Wait_Blit
	move.l	#$ffffffff,$dff044
	rts

Wait_Blit_Var_dff054
	bsr	Wait_Blit
	move.l	$21350+$1036,$dff054
	rts

Wait_Blit_dff000_a6
	lea	$dff000,a6
	bra.w	Wait_Blit

; ---------------------------------------------------------------------------

PL_LEVEL_LOADER
	PL_START
	PL_SA	$2aa,$32a
	PL_SA	$32e,$376
	PL_P	$37a,Load_File_a1_a6
	PL_PS	$60,.Patch_Level_Pic
	PL_PS	$1ba,.Patch_Level
	PL_PS	$23a,.Patch_Level_Pic
	PL_P	$29e,.Patch_Hiscore
	;PL_L	$1e2,$4e714e71		; always load next level
	PL_SA	$d0,$da			; don't set copperlist at $60000
	PL_P	$1b4,.Patch_Level
	PL_END

.Patch_Hiscore
	lea	PL_HISCORE(pc),a0
	pea	$21350
	bra.w	Patch_And_Run

.Patch_Level_Pic
	lea	$40000+$100,a0
	pea	$60000
	move.l	(a7),a1
	movem.l	(a0),d0/d1
	bsr	BK_DECRUNCH
	lea	PL_LEVEL_PIC(pc),a0
	bra.w	Patch_And_Run

.Patch_Level
	move.w	$108.w,d0		; level number
	subq.w	#1,d0
	add.w	d0,d0
	lea	.TAB(pc),a0
	add.w	(a0,d0.w),a0
	pea	$14000
	bra.w	Patch_And_Run


.TAB	dc.w	PL_LEVEL1-.TAB
	dc.w	PL_LEVEL2-.TAB
	dc.w	PL_LEVEL3-.TAB
	dc.w	PL_LEVEL4-.TAB
	dc.w	PL_LEVEL5-.TAB

; ---------------------------------------------------------------------------

PL_LEVEL_PIC
	PL_START
	PL_ORW	$8f2+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$16,.Enable_Keyboard_Interrupt,2

	PL_IFC2
	PL_ELSE
	PL_PS	$3d8,.Wait_Blit_a1_dff054
	PL_PS	$346,.Wait_Blit_a1_dff054
	PL_PS	$43e,Wait_Blit_a0_dff050
	PL_PS	$27c,.Wait_Blit_a1_dff054
	PL_PS	$2c6,.Wait_Blit_a1_dff054
	PL_ENDIF

	;PL_SA	$156,$15a		; enable built-in cheat
	;PL_W	$162+2,3
	;PL_W	$16a+2,3
	PL_END

.Enable_Keyboard_Interrupt
	move.w	#$7fff,$dff09a		; original code
	bra.w	Enable_Keyboard_Interrupt
	

.Wait_Blit_a1_dff054
	bsr	Wait_Blit
	move.l	a1,$dff054
	rts

Wait_Blit_a0_dff050
	bsr	Wait_Blit
	move.l	a0,$dff050
	rts


; ---------------------------------------------------------------------------

PL_LEVEL1
	PL_START
	PL_PSS	$41a,.Set_Keyboard_Routine,4
	PL_P	$3fc,.Remove_Keyboard_Routine
	PL_P	$721a,.Load_Music
	PL_PS	$77e,Disable_Copper_DMA
	PL_PS	$7a8,.Enable_Copper_DMA	
	PL_PS	$38cc,Fix_Access

	PL_IFC2
	PL_ELSE
	PL_PS	$34be,Wait_Blit_d0_dff040
	PL_PSS	$13a0,Wait_Blit_ffffffff_dff044,4
	PL_PS	$140a,Wait_Blit_Opt_Loop
	PL_PS	$1416,Wait_Blit_Opt_Loop
	PL_PS	$1422,Wait_Blit_Opt_Loop
	PL_PS	$142e,Wait_Blit_Opt_Loop
	PL_PS	$143a,Wait_Blit_Opt_Loop
	PL_PS	$1446,Wait_Blit_Opt_Loop
	PL_PS	$1452,Wait_Blit_Opt_Loop
	PL_PS	$145e,Wait_Blit_Opt_Loop
	PL_PS	$146a,Wait_Blit_Opt_Loop
	PL_PS	$1476,Wait_Blit_Opt_Loop
	PL_PS	$1482,Wait_Blit_Opt_Loop
	PL_PS	$148e,Wait_Blit_Opt_Loop
	PL_PS	$149a,Wait_Blit_Opt_Loop
	PL_PS	$14a6,Wait_Blit_Opt_Loop
	PL_PS	$14b2,Wait_Blit_Opt_Loop
	PL_PS	$14be,Wait_Blit_Opt_Loop
	PL_PS	$14ca,Wait_Blit_Opt_Loop
	PL_PS	$14d6,Wait_Blit_Opt_Loop
	PL_PS	$14e2,Wait_Blit_Opt_Loop
	PL_PS	$14ee,Wait_Blit_Opt_Loop
	PL_PS	$14fa,Wait_Blit_Opt_Loop
	PL_PSS	$3d46,Wait_Blit_09f00000_dff040,4
	PL_PSS	$3d88,Wait_Blit_09f00000_dff040,4
	PL_PS	$4444,Wait_Blit_dff000_a6
	PL_PS	$44b8,Wait_Blit_dff000_a6
	PL_PS	$67ac,Wait_Blit_a2_dff048
	PL_PS	$6804,Wait_Blit_a2_dff048
	PL_ENDIF

	PL_IFC1X	TRB_UNLIMITED_LIVES
	PL_W	$5398+2,0
	PL_ENDIF

	PL_IFC1X	TRB_INVULNERABILITY
	PL_W	$51fe,1
	PL_W	$5238+2,0
	PL_ENDIF
	PL_END


.Enable_Copper_DMA
	move.w	#DMAF_SETCLR|DMAF_COPPER,$dff096
	jmp	$1c000+$24e8

.Load_Music
	lea	$1c000+$76ca,a0
	move.l	$1c000+$76fc,a1
	bra.w	Load_File

.Set_Keyboard_Routine
	pea	.Keyboard_Routine(pc)
	bra.w	Set_Keyboard_Custom_Routine


.Remove_Keyboard_Routine
	bsr	Remove_Keyboard_Custom_Routine
	bra.w	Enable_Keyboard_Interrupt

.Keyboard_Routine
	move.b	Key(pc),$1c000+$482

	lea	.TAB(pc),a0
	bra.w	Handle_In_Game_Keys

.TAB	dc.w	RAWKEY_I,.Toggle_Invulnerability-.TAB
	dc.w	RAWKEY_L,.Toggle_Unlimited_Lives-.TAB
	dc.w	RAWKEY_R,.Refresh_Lives-.TAB
	dc.w	RAWKEY_N,.Skip_Level-.TAB
	dc.w	0

.Toggle_Invulnerability
	eor.w	#1,$1c000+$5238+2
	bne.b	.no_timer_set_needed
	move.w	#1,$1c000+$51fe
.no_timer_set_needed
	rts

.Toggle_Unlimited_Lives
	eor.w	#1,$1c000+$5398+2
	rts

.Refresh_Lives
	move.w	#10,$1c000+$33ba
	rts

.Skip_Level
	move.w	#1,$1c000+$2fec
	rts


Wait_Blit_d0_dff040
	bsr	Wait_Blit
	move.w	d0,$dff040
	rts

Wait_Blit_Opt_Loop
	bsr	Wait_Blit
	move.w	(a2)+,d5
	move.w	(a4,d5.l),(a6)
	rts

Wait_Blit_09f00000_dff040
	bsr	Wait_Blit
	move.l	#$09f00000,$dff040
	rts

Wait_Blit_a2_dff048
	bsr	Wait_Blit
	move.l	a2,$dff048
	rts

; offset can be >$8000, original game code uses 
; lea (a1,d1.w),a2 which leads to negative destination
; address in case the offset is >$8000
Fix_Access
	add.w	d2,d1
	and.l	#$ffff,d1
	lea	(a1,d1.l),a2
	rts

Disable_Copper_DMA
	move.w	#DMAF_COPPER,$dff096
	move.l	#$600,d0		; original code
	rts


; a0.l: table with in-game keys

Handle_In_Game_Keys
	move.b	In_Game_Keys_Enabled(pc),d0
	beq.b	.no_In_Game_Keys
	move.l	a0,a1
	moveq	#0,d0
	move.b	RawKey(pc),d0
.check_all_key_entries
	movem.w	(a0)+,d1/d2
	cmp.w	d0,d1
	beq.b	.key_entry_found
	tst.w	(a0)
	bne.b	.check_all_key_entries
.no_In_Game_Keys
	rts	
	
.key_entry_found
	lea	RawKey(pc),a0
	sf	(a0)
	pea	Flush_Cache(pc)
	jmp	(a1,d2.w)

; ---------------------------------------------------------------------------

PL_LEVEL2
	PL_START
	PL_PSS	$414,.Set_Keyboard_Routine,4
	PL_P	$3f6,.Remove_Keyboard_Routine
	PL_P	$90f4,.Load_Music
	PL_PS	$cee,Disable_Copper_DMA
	PL_PS	$d18,.Enable_Copper_DMA	
	PL_PS	$99a,Fix_Access

	PL_IFC2
	PL_ELSE
	PL_PS	$3fac,Wait_Blit_d0_dff040
	PL_PSS	$1a5e,Wait_Blit_ffffffff_dff044,4
	PL_PS	$1ac8,Wait_Blit_Opt_Loop
	PL_PS	$1ad4,Wait_Blit_Opt_Loop
	PL_PS	$1ae0,Wait_Blit_Opt_Loop
	PL_PS	$1aec,Wait_Blit_Opt_Loop
	PL_PS	$1af8,Wait_Blit_Opt_Loop
	PL_PS	$1b04,Wait_Blit_Opt_Loop
	PL_PS	$1b10,Wait_Blit_Opt_Loop
	PL_PS	$1b1c,Wait_Blit_Opt_Loop
	PL_PS	$1b28,Wait_Blit_Opt_Loop
	PL_PS	$1b34,Wait_Blit_Opt_Loop
	PL_PS	$1b40,Wait_Blit_Opt_Loop
	PL_PS	$1b4c,Wait_Blit_Opt_Loop
	PL_PS	$1b58,Wait_Blit_Opt_Loop
	PL_PS	$1b64,Wait_Blit_Opt_Loop
	PL_PS	$1b70,Wait_Blit_Opt_Loop
	PL_PS	$1b7c,Wait_Blit_Opt_Loop
	PL_PS	$1b88,Wait_Blit_Opt_Loop
	PL_PS	$1b94,Wait_Blit_Opt_Loop
	PL_PS	$1ba0,Wait_Blit_Opt_Loop
	PL_PS	$1bac,Wait_Blit_Opt_Loop
	PL_PS	$1bb8,Wait_Blit_Opt_Loop
	PL_PSS	$3df6,Wait_Blit_09f00000_dff040,4
	PL_PSS	$3e3e,Wait_Blit_09f00000_dff040,4
	PL_PS	$464a,Wait_Blit_dff000_a6
	PL_PS	$46be,Wait_Blit_dff000_a6
	PL_PSS	$3ea2,Wait_Blit_09f00000_dff040,4
	PL_PSS	$3ee0,Wait_Blit_09f00000_dff040,4
	PL_PSS	$3f1e,Wait_Blit_09f00000_dff040,4
	PL_PS	$83d6,Wait_Blit_a2_dff048
	PL_PS	$842e,Wait_Blit_a2_dff048
	PL_ENDIF

	PL_IFC1X	TRB_UNLIMITED_LIVES
	PL_W	$5bfa+2,0
	PL_ENDIF

	PL_IFC1X	TRB_INVULNERABILITY
	PL_W	$5ac2,1
	PL_W	$5afc+2,0
	PL_ENDIF
	PL_END

.Load_Music
	lea	$1c000+$95a4,a0
	move.l	$1c000+$95d6,a1
	bra.w	Load_File


.Set_Keyboard_Routine
	pea	.Keyboard_Routine(pc)
	bra.w	Set_Keyboard_Custom_Routine


.Remove_Keyboard_Routine
	bsr	Remove_Keyboard_Custom_Routine
	bra.w	Enable_Keyboard_Interrupt

.Keyboard_Routine
	move.b	Key(pc),$1c000+$47c

	lea	.TAB(pc),a0
	bra.w	Handle_In_Game_Keys

.TAB	dc.w	RAWKEY_I,.Toggle_Invulnerability-.TAB
	dc.w	RAWKEY_L,.Toggle_Unlimited_Lives-.TAB
	dc.w	RAWKEY_R,.Refresh_Lives-.TAB
	dc.w	RAWKEY_N,.Skip_Level-.TAB
	dc.w	0

.Toggle_Invulnerability
	eor.w	#1,$1c000+$5afc+2
	bne.b	.no_timer_set_needed
	move.w	#1,$1c000+$5ac2
.no_timer_set_needed
	rts

.Toggle_Unlimited_Lives
	eor.w	#1,$1c000+$5bfa+2
	rts

.Refresh_Lives
	move.w	#10,$1c000+$3d0a
	rts

.Skip_Level
	move.w	#1,$1c000+$3216
	rts

.Enable_Copper_DMA
	move.w	#DMAF_SETCLR|DMAF_COPPER,$dff096
	jmp	$1c000+$2b90

; ---------------------------------------------------------------------------

PL_LEVEL3
	PL_START
	PL_PSS	$35e,.Set_Keyboard_Routine,4
	PL_P	$340,.Remove_Keyboard_Routine
	PL_P	$a22c,.Load_Music
	PL_PS	$de4,Disable_Copper_DMA
	PL_PS	$e0e,.Enable_Copper_DMA	
	PL_PS	$9d4,Fix_Access

	PL_IFC2
	PL_ELSE
	PL_PS	$5c48,Wait_Blit_d0_dff040
	PL_PS	$1f3c,Wait_Blit_Opt_Loop
	PL_PS	$1f48,Wait_Blit_Opt_Loop
	PL_PS	$1f54,Wait_Blit_Opt_Loop
	PL_PS	$1f60,Wait_Blit_Opt_Loop
	PL_PS	$1f6c,Wait_Blit_Opt_Loop
	PL_PS	$1f78,Wait_Blit_Opt_Loop
	PL_PS	$1f84,Wait_Blit_Opt_Loop
	PL_PS	$1f90,Wait_Blit_Opt_Loop
	PL_PS	$1f9c,Wait_Blit_Opt_Loop
	PL_PS	$1fa8,Wait_Blit_Opt_Loop
	PL_PS	$1fb4,Wait_Blit_Opt_Loop
	PL_PS	$1fc0,Wait_Blit_Opt_Loop
	PL_PS	$1fcc,Wait_Blit_Opt_Loop
	PL_PS	$1fd8,Wait_Blit_Opt_Loop
	PL_PS	$1fe4,Wait_Blit_Opt_Loop
	PL_PS	$1ff0,Wait_Blit_Opt_Loop
	PL_PS	$1ffc,Wait_Blit_Opt_Loop
	PL_PS	$2008,Wait_Blit_Opt_Loop
	PL_PS	$2014,Wait_Blit_Opt_Loop
	PL_PS	$2020,Wait_Blit_Opt_Loop
	PL_PS	$202c,Wait_Blit_Opt_Loop

	PL_PSS	$5ce2,Wait_Blit_09f00000_dff040,4
	PL_PS	$5d94,Wait_Blit_d0_dff040
	PL_PS	$5e10,Wait_Blit_d0_dff040
	PL_PSS	$1ed2,Wait_Blit_ffffffff_dff044,4
	PL_PSS	$90fa,Wait_Blit_ffffffff_dff044,4
	PL_PSS	$99f4,Wait_Blit_ffffffff_dff044,4

	PL_PSS	$5e60,Wait_Blit_09f0_dff040,2
	PL_PS	$59fc,Wait_Blit_dff000_a6
	PL_PS	$6902,Wait_Blit_dff000_a6
	PL_PS	$6976,Wait_Blit_dff000_a6
	PL_PS	$69ea,Wait_Blit_dff000_a6
	PL_PS	$6ebc,Wait_Blit_a2_dff048
	PL_PS	$6f28,Wait_Blit_a2_dff048
	
	PL_PSS	$4db0,Wait_Blit_09f00000_dff040,4
	PL_PS	$4de4,Wait_Blit_a0_dff050
	PL_PS	$4dfc,Wait_Blit_a0_dff050
	PL_PS	$4e12,Wait_Blit_a0_dff050
	PL_ENDIF

	PL_IFC1X	TRB_UNLIMITED_LIVES
	PL_W	$6b98+2,0
	PL_ENDIF

	PL_IFC1X	TRB_INVULNERABILITY
	PL_W	$6a6e,1
	PL_W	$6aa8+2,0
	PL_ENDIF

	PL_END

.Load_Music
	lea	$1c000+$a6dc,a0
	move.l	$1c000+$a70e,a1
	bra.w	Load_File


.Set_Keyboard_Routine
	pea	.Keyboard_Routine(pc)
	bra.w	Set_Keyboard_Custom_Routine


.Remove_Keyboard_Routine
	bsr	Remove_Keyboard_Custom_Routine
	bra.w	Enable_Keyboard_Interrupt

.Keyboard_Routine
	move.b	Key(pc),$1c000+$3c8

	lea	.TAB(pc),a0
	bra.w	Handle_In_Game_Keys

.TAB	dc.w	RAWKEY_I,.Toggle_Invulnerability-.TAB
	dc.w	RAWKEY_L,.Toggle_Unlimited_Lives-.TAB
	dc.w	RAWKEY_R,.Refresh_Lives-.TAB
	dc.w	RAWKEY_N,.Skip_Level-.TAB
	dc.w	0

.Toggle_Invulnerability
	eor.w	#1,$1c000+$6aa8+2
	bne.b	.no_timer_set_needed
	move.w	#1,$1c000+$6a6e
.no_timer_set_needed
	rts

.Toggle_Unlimited_Lives
	eor.w	#1,$1c000+$6b98+2
	rts

.Refresh_Lives
	move.w	#10,$1c000+$5b20
	rts

.Skip_Level
	move.w	#1,$1c000+$4e28
	rts


.Enable_Copper_DMA
	move.w	#DMAF_SETCLR|DMAF_COPPER,$dff096
	jmp	$1c000+$3dba

Wait_Blit_09f0_dff040
	bsr	Wait_Blit
	move.w	#$09f0,$dff040
	rts

; ---------------------------------------------------------------------------

PL_LEVEL4
	PL_START
	PL_PSS	$490,.Set_Keyboard_Routine,4
	PL_P	$472,.Remove_Keyboard_Routine
	PL_P	$bc9e,.Load_Music
	PL_PS	$fdc,Disable_Copper_DMA
	PL_PS	$1006,.Enable_Copper_DMA	
	PL_PS	$a632,Fix_Access

	PL_IFC2
	PL_ELSE
	PL_PSS	$4e9c,Wait_Blit_09f0_dff040,2
	PL_PSS	$4eee,Wait_Blit_09f0_dff040,2
	PL_PSS	$4f3c,Wait_Blit_09f0_dff040,2
	PL_PSS	$2176,Wait_Blit_ffffffff_dff044,4
	PL_PS	$21e0,Wait_Blit_Opt_Loop
	PL_PS	$21ec,Wait_Blit_Opt_Loop
	PL_PS	$21f8,Wait_Blit_Opt_Loop
	PL_PS	$2204,Wait_Blit_Opt_Loop
	PL_PS	$2210,Wait_Blit_Opt_Loop
	PL_PS	$221c,Wait_Blit_Opt_Loop
	PL_PS	$2228,Wait_Blit_Opt_Loop
	PL_PS	$2234,Wait_Blit_Opt_Loop
	PL_PS	$2240,Wait_Blit_Opt_Loop
	PL_PS	$224c,Wait_Blit_Opt_Loop
	PL_PS	$2258,Wait_Blit_Opt_Loop
	PL_PS	$2264,Wait_Blit_Opt_Loop
	PL_PS	$2270,Wait_Blit_Opt_Loop
	PL_PS	$227c,Wait_Blit_Opt_Loop
	PL_PS	$2288,Wait_Blit_Opt_Loop
	PL_PS	$2294,Wait_Blit_Opt_Loop
	PL_PS	$22a0,Wait_Blit_Opt_Loop
	PL_PS	$22ac,Wait_Blit_Opt_Loop
	PL_PS	$22b8,Wait_Blit_Opt_Loop
	PL_PS	$22c4,Wait_Blit_Opt_Loop
	PL_PS	$22d0,Wait_Blit_Opt_Loop
	PL_PS	$54d2,Wait_Blit_a0_dff050
	PL_PS	$55e6,Wait_Blit_a0_dff050
	PL_PS	$565e,Wait_Blit_a0_dff050
	PL_PS	$588e,Wait_Blit_dff000_a6
	PL_PS	$5902,Wait_Blit_dff000_a6
	PL_PS	$aefa,Wait_Blit_a2_dff048
	PL_PS	$af52,Wait_Blit_a2_dff048
	PL_PS	$afaa,Wait_Blit_d1_dff064
	PL_PSS	$b000,Wait_Blit_0dfc0000_dff040,4
	PL_PS	$b024,Wait_Blit_d0_dff058
	PL_PS	$b048,Wait_Blit_d0_dff058
	PL_PS	$b06c,Wait_Blit_d0_dff058
	PL_PS	$b0be,Wait_Blit_a2_dff048
	PL_ENDIF

	PL_IFC1X	TRB_UNLIMITED_LIVES
	PL_W	$a35a+2,0
	PL_ENDIF

	PL_IFC1X	TRB_INVULNERABILITY
	PL_W	$a1ec,1
	PL_W	$a226+2,0
	PL_ENDIF
	PL_END

.Load_Music
	lea	$1c000+$c14e,a0
	move.l	$1c000+$c180,a1
	bra.w	Load_File

.Set_Keyboard_Routine
	pea	.Keyboard_Routine(pc)
	bra.w	Set_Keyboard_Custom_Routine


.Remove_Keyboard_Routine
	bsr	Remove_Keyboard_Custom_Routine
	bra.w	Enable_Keyboard_Interrupt

.Keyboard_Routine
	move.b	Key(pc),$1c000+$4fa

	lea	.TAB(pc),a0
	bra.w	Handle_In_Game_Keys

.TAB	dc.w	RAWKEY_I,.Toggle_Invulnerability-.TAB
	dc.w	RAWKEY_L,.Toggle_Unlimited_Lives-.TAB
	dc.w	RAWKEY_R,.Refresh_Lives-.TAB
	dc.w	RAWKEY_N,.Skip_Level-.TAB
	dc.w	0

.Toggle_Invulnerability
	eor.w	#1,$1c000+$a226+2
	bne.b	.no_timer_set_needed
	move.w	#1,$1c000+$a1ec
.no_timer_set_needed
	rts

.Toggle_Unlimited_Lives
	eor.w	#1,$1c000+$a35a+2
	rts

.Refresh_Lives
	move.w	#10,$1c000+$4c7a
	rts

.Skip_Level
	move.w	#1,$1c000+$45ea
	rts



.Enable_Copper_DMA
	move.w	#DMAF_SETCLR|DMAF_COPPER,$dff096
	jmp	$1c000+$339c

Wait_Blit_d1_dff064
	bsr	Wait_Blit
	move.w	d1,$dff064
	rts

Wait_Blit_0dfc0000_dff040
	bsr	Wait_Blit
	move.l	#$0dfc0000,$dff040
	rts

Wait_Blit_d0_dff058
	move.w	d0,$dff058
	bra.w	Wait_Blit

; ---------------------------------------------------------------------------

PL_LEVEL5
	PL_START
	PL_PSS	$4fe,.Set_Keyboard_Routine,4
	PL_P	$4e0,.Remove_Keyboard_Routine
	PL_P	$a35a,.Load_Music
	PL_PS	$e40,Disable_Copper_DMA
	PL_PS	$e7a,.Enable_Copper_DMA	
	PL_PS	$a54,Fix_Access
	PL_P	$a8a4,.Patch_Endsequence_Load

	PL_IFC2
	PL_ELSE
	PL_PSS	$467e,Wait_Blit_ffffffff_dff044,4
	PL_PS	$46e8,Wait_Blit_Opt_Loop
	PL_PS	$46f4,Wait_Blit_Opt_Loop
	PL_PS	$4700,Wait_Blit_Opt_Loop
	PL_PS	$470c,Wait_Blit_Opt_Loop
	PL_PS	$4718,Wait_Blit_Opt_Loop
	PL_PS	$4724,Wait_Blit_Opt_Loop
	PL_PS	$4730,Wait_Blit_Opt_Loop
	PL_PS	$473c,Wait_Blit_Opt_Loop
	PL_PS	$4748,Wait_Blit_Opt_Loop
	PL_PS	$4754,Wait_Blit_Opt_Loop
	PL_PS	$4760,Wait_Blit_Opt_Loop
	PL_PS	$476c,Wait_Blit_Opt_Loop
	PL_PS	$4778,Wait_Blit_Opt_Loop
	PL_PS	$4784,Wait_Blit_Opt_Loop
	PL_PS	$4790,Wait_Blit_Opt_Loop
	PL_PS	$479c,Wait_Blit_Opt_Loop
	PL_PS	$47a8,Wait_Blit_Opt_Loop
	PL_PS	$47b4,Wait_Blit_Opt_Loop
	PL_PS	$47c0,Wait_Blit_Opt_Loop
	PL_PS	$47cc,Wait_Blit_Opt_Loop
	PL_PS	$47d8,Wait_Blit_Opt_Loop
	PL_PSS	$f10,.Wait_Blit_b2d0_dff050,4
	PL_PS	$6a62,Wait_Blit_a0_dff050
	PL_PSS	$6aa0,Wait_Blit_ffffffff_dff044,4
	PL_PSS	$6ade,Wait_Blit_ffffffff_dff044,4
	PL_PS	$6b8c,Wait_Blit_a0_dff050
	PL_PS	$6bc0,Wait_Blit_a0_dff050
	PL_PSS	$4568,.Wait_Blit_Var_dff054,4
	PL_ENDIF

	PL_IFC1X	TRB_INVULNERABILITY
	PL_W	$88b6,1
	PL_W	$88b8+2,0
	PL_ENDIF
	PL_END

.Load_Music
	lea	$18000+$a80a,a0
	move.l	$18000+$a83c,a1
	bra.w	Load_File

.Patch_Endsequence_Load
	lea	PL_ENDSEQUENCE_LOAD(pc),a0
	pea	$50000
	bra.w	Patch_And_Run

.Set_Keyboard_Routine
	pea	.Keyboard_Routine(pc)
	bra.w	Set_Keyboard_Custom_Routine


.Remove_Keyboard_Routine
	bsr	Remove_Keyboard_Custom_Routine
	bra.w	Enable_Keyboard_Interrupt

.Keyboard_Routine
	move.b	Key(pc),$18000+$566

	lea	.TAB(pc),a0
	bra.w	Handle_In_Game_Keys

.TAB	dc.w	RAWKEY_I,.Toggle_Invulnerability-.TAB
	dc.w	RAWKEY_R,.Refresh_Lives-.TAB
	dc.w	RAWKEY_N,.Skip_Level-.TAB
	dc.w	0

.Toggle_Invulnerability
	eor.w	#1,$18000+$88b8+2
	bne.b	.no_timer_set_needed
	move.w	#1,$18000+$88b6
.no_timer_set_needed
	rts


.Refresh_Lives
	move.w	#10,$18000+$68fa
	rts

.Skip_Level
	move.w	#1,$18000+$5d2a
	rts



.Enable_Copper_DMA
	move.w	#DMAF_SETCLR|DMAF_COPPER,$dff096
	jmp	$18000+$574e


.Wait_Blit_b2d0_dff050
	bsr	Wait_Blit
	move.l	#$b2d0,$dff050
	rts

.Wait_Blit_Var_dff054
	bsr	Wait_Blit
	move.l	$18000+$c1a,$dff054
	rts

; ---------------------------------------------------------------------------

PL_ENDSEQUENCE_LOAD
	PL_START
	PL_S	$5e,6			; don't load "diskchange" file
	PL_S	$6c,6			; don't run "diskchange" code
	PL_SA	$fa,$17a
	PL_SA	$17e,$1c6
	PL_P	$1ca,Load_File_a1_a6
	PL_P	$f4,.Patch_Endsequence
	PL_P	$22,.Flush_Cache
	PL_PSS	$c4,Wait_Blit_09f00000_dff040,4
	PL_END

.Flush_Cache
	bsr	Flush_Cache
	jmp	$10028

.Patch_Endsequence
	lea	PL_ENDSEQUENCE(pc),a0
	lea	$31b20,a1
	bsr	Apply_Patches
	jmp	$7e000


; ---------------------------------------------------------------------------

PL_ENDSEQUENCE
	PL_START
	PL_ORW	$4d038+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$4d144+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$4d950+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$4cbd8+4,1<<9		; set Bplcon0 color bit
	PL_ORW	$4cc7c+4,1<<9		; set Bplcon0 color bit
	PL_P	$4cd32,BK_DECRUNCH
	PL_PSS	$4ca2c,Acknowledge_Level3_Interrupt_Request,2
	PL_ORW	$4c540+2,INTF_PORTS	; enable level 2 interrupts
	PL_PS	$4caa6,Wait_Blit_d0_dff054
	PL_S	$4da00,6		; don't load "diskchange" file
	PL_S	$4da0e,6		; don't run "diskchange" code
	PL_SA	$4da98,$4db18
	PL_SA	$4db1c,$4db64
	PL_P	$4db68,Load_File_a1_a6
	PL_P	$4da86,.Patch_Hiscore
	PL_END

.Patch_Hiscore
	lea	PL_HISCORE(pc),a0
	pea	$18000
	bra.w	Patch_And_Run


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

Flush_Cache
	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts

; ---------------------------------------------------------------------------

; d0.l: offset
; d1.l: size
; a0.l: destination

Disk_Load
	movem.l	d0-a6,-(a7)
	moveq	#1,d2			; disk number
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d0-a6
	rts


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

Acknowledge_Level3_Interrupt
	bsr.b	Acknowledge_Level3_Interrupt_Request
	rte

Acknowledge_Level3_Interrupt_Request
	move.w	#INTF_VERTB,$dff09c
	move.w	#INTF_VERTB,$dff09c
	rts	

; ---------------------------------------------------------------------------


; d0.b: rawkey code

Check_Quit_Key
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	rts	

Set_Keyboard_Custom_Routine
	move.l	a0,-(a7)
	lea	KbdCust(pc),a0
	move.l	4(a7),(a0)
	move.l	(a7)+,a0
	rts

Remove_Keyboard_Custom_Routine
	move.l	a0,-(a7)
	lea	KbdCust(pc),a0
	clr.l	(a0)
	move.l	(a7)+,a0
	rts


Enable_Keyboard_Interrupt
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,$dff09a
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

	bsr.w	Check_Quit_Key

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

; Bytekiller decruncher
; resourced and adapted by stingray
;
; a0.l: source
; a1.l: destination

BK_DECRUNCH
	bsr.b	.decrunch
	tst.l	d5
	beq.w	.ok

; checksum doesn't match, file corrupt
	pea	ErrText(pc)
	pea	(TDREASON_FAILMSG).w
	bra.w	EXIT

.ok	rts


.decrunch
	move.l	(a0)+,d0		; packed length
	move.l	(a0)+,d1		; unpacked length
	move.l	(a0)+,d5		; checksum
	add.l	d0,a0			; a0: end of packed data
	lea	(a1,d1.l),a2		; a2: end of unpacked data
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


ErrText	dc.b	"Decrunching failed, file corrupt!",0




***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      SECOND SAMURAI WHDLOAD SLAVE          )*)---.---.   *
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

; 03-Apr-2022	- some unused/commented out code removed
;		- 68000 quitkey support fixed (issue #5550)

; 01-Apr-2022	- trainer option for in-game keys used the same bit
;		  as the option for unlimited ammo
;		- unused and test code removed

; 30-Mar-2022	- unused/test code removed
;		- jump button changed from YELLOW to GREEN
;		- yellow button is used to display the help screen
;		- this patch is finished for now

; 29-Mar-2022	- jump with button press (CD32 pad), other approaches
;		  tested

; 28-Mar-2022	- jump with button press (CD32 pad)

; 27-Mar-2022	- CD32 pad support is now finished, after wasting (way too)
;		  many hours trying to implement pause toggling with
;		  the PLAY button I have decided to emulate the original
;		  game behaviour: if pause is enabled, any other button than
;		  PLAY disables the pause mode

; 26-Mar-2022	- CD32 stuff...

; 25-Mar-2022	- CD32 stuff, still not satisfied yet

; 23-Mar-2022	- CD32 pad support continued

; 22-Mar-2022	- easier solution for the 24-bit problems in the sample
;		  player found and used
;		- keyboard handling for in-game keys improved
;		- more im-game keys added
;		- help screen added when in-game keys are enabled (adapted
;		  the games own help screen)
;		- game end sequence patched
;		- CD32 pad support started


; 21-Mar-2022	- highscore load/save added
;		- first in-game keys added
;		- more blitter waits added (large robot in level 7)
;		- one more wrong blit fixed (same large robot in level 7)
;		- disk 3 request patched, not tested yet


; 20-Mar-2022	- game patched (out of bounds blits fixed, blitter waits
;		  added, mouse control in main menu disabled, interrupts
;		  fixed)

; 19-Mar-2022	- work restarted
;		- intro fully patched

; 25-Jan-2016	- one wrong blitter wait corrected
;		- port 1 control in menu can be enabled with CUSTOM1
;		- trainer options added (CUSTOM2)

; 24-Jan-2016	- work started
;		- blitter waits added (68010+ only), 24-bit problems fixed,
;		  mouse/port 1 control in menu disabled, Bplcon0 color bit
;		  fix, writes to Beamcon0 disabled, keyboard routine
;	 	  rewritten, 68000 quitkey support


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	exec/execbase.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

FAST_MEMORY_SIZE	= 524288

; Trainer options
TRB_LIVES		= 0		; unlimited lives
TRB_ENERGY		= 1		; unlimited energy
TRB_INVINCIBILITY	= 2		; 
TRB_WEAPONS		= 3		; unlimited weapons
TRB_KEYS		= 4		; in-game keys

MAX_ENERGY		= 100		; maximum energy
MAX_LIVES		= 9		; maximum number of lives


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
RAWKEY_LEFT_SHIFT	= $60
RAWKEY_RIGHT_SHIFT	= $61

RAWKEY_B_DELAY_RELEASE	= 7

	
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
	dc.l	524288			; ws_BaseMemSize
	dc.l	0			; ws_ExecInstall
	dc.w	Patch-HEADER		; ws_GameLoader
	dc.w	.dir-HEADER		; ws_CurrentDir
	dc.w	0			; ws_DontCache
	dc.b	0			; ws_KeyDebug
	dc.b	QUITKEY			; ws_KeyExit
	dc.l	FAST_MEMORY_SIZE	; ws_ExpMem
	dc.w	.name-HEADER		; ws_name
	dc.w	.copy-HEADER		; ws_copy
	dc.w	.info-HEADER		; ws_info

; v16
	dc.w	0			; ws_kickname
	dc.l	0			; ws_kicksize
	dc.w	0			; ws_kickcrc

; v17
	dc.w	.config-HEADER		; ws_config


.config
	dc.b	"C1:X:Unlimited Lives:",TRB_LIVES+"0",";"
	dc.b	"C1:X:Unlimited Energy:",TRB_ENERGY+"0",";"
	dc.b	"C1:X:Invincibility:",TRB_INVINCIBILITY+"0",";"
	dc.b	"C1:X:Unlimited Weapons:",TRB_WEAPONS+"0",";"
	dc.b	"C1:X:In-Game Keys (Press Help during Game):",TRB_KEYS+"0",";"
	dc.b	"C2:B:Enable Joystick in Port 1 in Menu;"
	dc.b	"C3:B:Disable Blitter Waits;"
	dc.b	"C4:B:Enable CD32 Controls;"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Games/SecondSamurai/"
	ENDC
	dc.b	"data",0


.name	dc.b	"Second Samurai",0
.copy	dc.b	"1993 Vivid Image",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.2A (03.04.2022)",0

Highscore_Name	dc.b	"SecondSamurai.high",0
File_Name	dc.b	"SecondSamuraiX_XX",0

; File name structure
			RSRESET
FN_Prefix		rs.b	13
FN_Disk_Number		rs.b	1
FN_Separator		rs.b	1
FN_File_Number		rs.b	2

	CNOP	0,4

TAGLIST			dc.l	WHDLTAG_CUSTOM1_GET
TRAINER_OPTIONS		dc.l	0		
			dc.l	WHDLTAG_ATTNFLAGS_GET
CPU_FLAGS		dc.l	0
			dc.l	WHDLTAG_CUSTOM3_GET
NO_BLITTER_WAITS	dc.l	0
			dc.l	TAG_DONE

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


	; install level 2 interrupt
	bsr	Init_Level2_Interrupt

	; detect CD32 controller
	bsr	_detect_controller_types


	moveq	#1,d0
	bsr	Set_Disk_Number

	; load boot code
	lea	$500-$be.w,a0
	move.l	a0,a5
	moveq	#12,d0
	bsr	Load_File_Number


	; version check
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$B70D,d0		; SPS 0721
	beq.b	.version_ok
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT
.version_ok

	; patch boot code
	lea	PL_BOOT(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

	; set extended memory
	move.l	HEADER+ws_ExpMem(pc),-4(a5)

	; run game
	jmp	(a5)



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


Wait_Blit
	tst.b	$dff002
.wait_blit
	btst	#6,$dff002
	bne.b	.wait_blit
	rts

; d0.b: raw key code
Check_Quit_Key
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
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

Save_File
	movem.l	d0-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)
	movem.l	(a7)+,d0-a6
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

; Returns if CPU is 68000. Result is returned in
; the z-flag (0: is 68000 CPU).

Is_68000_CPU
	move.l	CPU_FLAGS(pc),d0
	btst	#AFB_68010,d0
	rts

; Returns if blitter wait patches should be installed.
; Result is returned in the the z-flag (0: install patches)
Blitter_Wait_Patches_Disabled
	move.l	NO_BLITTER_WAITS(pc),d0
	rts


Flush_Cache
	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
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
; Game related Support/helper routines.

; a0.l: destination
; d0.w: file number

Load_File_Number
	movem.l	d0-a6,-(a7)
	move.l	a0,a1
	lea	File_Name(pc),a0
	bsr.b	.Convert_File_Number_To_Ascii
	bsr	Load_File
	movem.l	(a7)+,d0-a6
	rts

.Convert_File_Number_To_Ascii
	moveq	#0,d1
	move.b	d0,d1
	divu.w	#10,d1
	add.b	#"0",d1
	move.b	d1,FN_File_Number(a0)
	swap	d1
	add.b	#"0",d1
	move.b	d1,FN_File_Number+1(a0)
	rts

; d0.b: disk number
Set_Disk_Number
	movem.l	d0/a0,-(a7)
	add.b	#"0",d0
	lea	File_Name(pc),a0
	move.b	d0,FN_Disk_Number(a0)
	movem.l	(a7)+,d0/a0
	rts

Acknowledge_Level2_Interrupt
	move.w	#1<<3,$dff09c
	move.w	#1<<3,$dff09c
	rts

Acknowledge_Level3_Interrupt
	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rts

Acknowledge_Level6_Interrupt
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte


Fix_DMA_Wait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d0
.loop	move.b	$dff006,d1
.same_raster_line
	cmp.b	$dff006,d1
	beq.b	.same_raster_line
	dbf	d0,.loop
	movem.l	(a7)+,d0/d1
	rts

; ---------------------------------------------------------------------------
; Game patches.

PL_BOOT	PL_START
	PL_P	$f42,Load_File_Number_Game
	PL_SA	$30,$50			; skip drive access
	PL_P	$17a,Load_Sectors
	PL_PS	$e82,.Load_Highscores
	PL_END

.Load_Highscores
	clr.w	$1506.w			; original code
	bra.w	Load_Highscores

Load_Sectors
	IFD	DEBUG
	cmp.w	#1,d1			; must only be called to load directory
	bne.b	.error
	ENDC
	moveq	#99,d0			; directory
	bsr	Load_File_Number
	moveq	#0,d0			; no errors
	rts

	IFD	DEBUG
.error	illegal
	ENDC

; d7.w: file number
; d6.l: destination
; a0.l: destination
; d1.w: start sector
; d2.w: number of sectors to load
; d3.w: status/control settings (bit 4: file is RLE-packed)
; d4.b: disk number

Load_File_Number_Game
	movem.l	d0-a6,-(a7)
	move.b	d4,d0

	; game uses disk number 4 for disk 3
	cmp.b	#4,d0
	bne.b	.not_disk_3
	moveq	#3,d0
.not_disk_3	
	bsr	Set_Disk_Number

	move.l	d7,d0
	bsr	Load_File_Number

	btst	#4,d3
	beq.b	.file_is_not_packed
	jsr	($500-$be)+$d5e.w	; decrunch RLE
.file_is_not_packed
	movem.l	(a7)+,d0-a6

	; Patch file if necessary
	lea	.Patch_Table(pc),a2
.check_all_entries
	movem.w	(a2)+,d0/d1/d2
	cmp.b	d4,d0
	bne.b	.check_next_entry
	cmp.w	d7,d1
	bne.b	.check_next_entry
	lea	.Patch_Table(pc,d2.w),a1
	exg	a0,a1
	moveq	#0,d0			; no errors
	bra.w	Apply_Patches

.check_next_entry
	tst.w	(a2)
	bpl.b	.check_all_entries
	moveq	#0,d0			; no errors
	rts

; format: disk number, file number, offset to patch list
.Patch_Table
	dc.w	1,00,PL_INTRO-.Patch_Table
	dc.w	1,10,PL_GAME-.Patch_Table
	;dc.w	3,21,PL_EXTRO-.Patch_Table
	dc.w	0				; end of table
	
; --------------------------------------------------------------------------
; Game intro patches.

PL_INTRO
	PL_START
	PL_P	$348dc,Acknowledge_Level6_Interrupt
	PL_P	$348f8,Acknowledge_Level6_Interrupt
	PL_P	$672,Load_File_Number_Internal
	PL_ORW	$45c+2,1<<9			; set Bplcon0 color bit
	PL_SA	$80,$86				; skip write to Beamcon0
	PL_PSA	$38a,.Set_Disk2,$3dc
	PL_PS	$2ff0,Check_Quit_Key_Internal
	PL_END


.Set_Disk2
	moveq	#2,d0
	bra.w	Set_Disk_Number

Check_Quit_Key_Internal
	ror.b	d0
	not.b	d0
	bra.w	Check_Quit_Key

; d0.w: file number multiplied by 8
; a0.l: destination

Load_File_Number_Internal
	lsr.w	#3,d0
	move.w	d0,d7
	bsr.w	Load_File_Number_Game
	moveq	#0,d0
	rts


; --------------------------------------------------------------------------
; Game patches.

PL_GAME	PL_START
	PL_PSS	$0,Install_CPU_Dependent_Patches,2
	PL_PSS	$395a,Acknowledge_Level2_Interrupt,2
	PL_P	$1a3d8,Acknowledge_Level6_Interrupt
	PL_P	$1a3f4,Acknowledge_Level6_Interrupt
	
	PL_L	$1b68a,$4e714e71		; do not clear file number
	PL_P	$1b696,Load_File_Number_Internal

	PL_SA	$12d4,$12dc			; skip write to Beamcon0
	PL_PSS	$3852,.Fix_Keyboard_Delay_And_Check_Quit_Key,2


	; Fix out of bounds blits
	PL_PSS	$2f5c,Wait_Blit_D0_50_A1_54,2
	PL_PSS	$2e24,Wait_Blit_D0_50_A1_54,2

	; Disable mouse reading in options menu
	PL_IFC2
	PL_ELSE
	PL_W	$6b3c,$7e00		; move.w d2,d7 -> moveq #0,d7
	PL_W	$7070,$7e00		; move.w d2,d7 -> moveq #0,d7
	PL_ENDIF


	PL_PS	$3f68,.Clip_Blit_A4
	PL_PSA	$1b34a,.Set_Disk3,$1b63e

	PL_PSS	$1ab60,Fix_DMA_Wait,2
	PL_PSS	$1ab7a,Fix_DMA_Wait,2


	PL_P	$1b3ca,.Load_End_Code

	; -------------------------------------------------------------------
	; Trainer options

	; Unlimited Lives
	PL_IFC1X	TRB_LIVES
	PL_B	$83c6,$4a
	PL_ENDIF

	; Unlimited Energy
	PL_IFC1X	TRB_ENERGY
	PL_B	$8244,$4a
	PL_ENDIF

	; Invulnerability	
	PL_IFC1X	TRB_INVINCIBILITY
	PL_P	$817a,.Set_Invincibility
	PL_ENDIF

	; Unlimited Weapons
	PL_IFC1X	TRB_WEAPONS
	PL_B	$603e,$4a
	PL_ENDIF


	; In-Game Keys
	PL_IFC1X	TRB_KEYS
	;PL_PSS	$3822,.Check_Keys,2
	PL_PS	$ABA,.Check_Keys
	PL_PS	$14e0,.Write_Help_Text
	PL_ENDIF

	; Save Highscores
	PL_IFC1
	; Trainer options have been used, do nothing.
	
	PL_ELSE
	PL_PSS	$74ea,.Save_Highscores,2
	PL_ENDIF



	; -------------------------------------------------------------------
	; CD32 controls
	PL_IFC4
	PL_P	$2d12,Read_CD32_Pad
	PL_PS	$39a6,Enable_Button_Jump
	PL_ENDIF

	PL_END




.Load_End_Code
	move.w	#32767,$8b90
	clr.l	$8b68

	moveq	#0,d1
	move.w	$8B90,d1
	move.w	d1,$1500.W
	move.l	$8B68,d0
	bne.b	.lbC000016
	move.l	d1,d0
.lbC000016
	move.l	d0,$1502.W
	moveq	#21,d0
	lea	$1510.w,a0
	bsr	Load_File_Number

	move.l	a0,a1
	lea	PL_EXTRO(pc),a0
	bsr	Apply_Patches
	jmp	$1510.w


.Set_Disk3
	moveq	#3,d0
	bra.w	Set_Disk_Number
	


.Clip_Blit_A4
	move.l	d1,-(a7)
	move.l	a4,d1
	and.l	#$80000-1,d1
	move.l	d1,a4
	move.l	(a7)+,d1

	and.w	#15,d1
	ror.w	#4,d1
	rts
	



.Save_Highscores
	move.l	$151a.w,a0
	jsr	$166e.w
	beq.b	.no_save
	bsr	Save_Highscores
.no_save
	rts
	

.Fix_Keyboard_Delay_And_Check_Quit_Key
	movem.l	d0/d1,-(a7)
	moveq	#3-1,d0
.loop	move.b	$dff006,d1
.same_raster_line
	cmp.b	$dff006,d1
	beq.b	.same_raster_line
	dbf	d0,.loop

	move.b	$4d12.w,d0
	bsr	Check_Quit_Key

	movem.l	(a7)+,d0/d1
	rts




.Check_Keys
	movem.l	d0-a6,-(a7)
	move.b	$4d12.w,d0
	lea	.Tab(pc),a0
.check_keys
	movem.w	(a0)+,d1/d2
	cmp.b	d0,d1
	beq.b	.key_found
	tst.w	(a0)
	bne.b	.check_keys
	bra.w	.exit

.key_found
	st	$4d12.w
	move.l	$1500+$819c,a6		; player 1 variables
	jsr	.Tab(pc,d2.w)
	bsr	Flush_Cache

.exit	movem.l	(a7)+,d0-a6
	jmp	$1500+$a04c


.Tab	dc.w	RAWKEY_A,.Refresh_Ammo-.Tab
	dc.w	RAWKEY_I,.Toggle_Invincibility-.Tab
	dc.w	RAWKEY_J,.Toggle_Jetpack-.Tab
	dc.w	RAWKEY_L,.Refresh_Lives-.Tab
	dc.w	RAWKEY_E,.Refresh_Energy-.Tab
	dc.w	RAWKEY_W,.Win_Game-.Tab
	dc.w	0			; end of table

.Win_Game
	bsr	.Set_Disk3
	jmp	$1500+$1b36e


.Set_Invincibility
	move.l	(a7),a6
	bsr.b	.Toggle_Invincibility
	movem.l	(a7)+,a0-a6
	rts

.Toggle_Invincibility
	not.b	$b6(a6)
	eor.b	#$19,$1500+$8780
	rts

.Toggle_Jetpack
	not.b	$b8(a6)
	rts

.Refresh_Energy
	move.w	#MAX_ENERGY,$70(a6)
	rts

.Refresh_Lives
	move.b	#MAX_LIVES,$a8(a6)
	rts

.Skip_Level
	rts

.Refresh_Ammo
	move.l	$98(a6),d0
	beq.b	.no_weapon
	move.l	d0,a0
	move.w	#99,2(a0)
	jsr	$252c.w			; update status display
.no_weapon
	rts

.Write_Help_Text
	jsr	$1500+$7834		; write original help text

	lea	.Help_Text(pc),a0
	move.l	$2f26.w,a1		; screen
	add.w	#(44*4)*140+4,a1
	;sub.w	#44*3,a1
	bra.w	HS_WriteText

.Help_Text
	dc.b	"A: Refresh Ammo     W: Win Game",10
	dc.b	"E: Refresh Energy   L: Refresh Lives",10
	dc.b	"I: Toggle Invuln.   J: Get Jetpack",0
	CNOP	0,2

; ---------------------------------------------------------------------------
;
Install_CPU_Dependent_Patches
	movem.l	d0-a6,-(a7)
	bsr	Is_68000_CPU
	beq.b	.no_24_bit_fixes
	bsr	Fix_24_Bit_Problems
.no_24_bit_fixes	

	bsr	Blitter_Wait_Patches_Disabled
	bne.b	.no_blitter_waits
	bsr	Fix_Blitter_Waits
.no_blitter_waits	

	movem.l	(a7)+,d0-a6

	move.l	#$1500+$344,$80.w		; original code
	rts

; ---------------------------------------------------------------------------
; 24-bit fixes.

Fix_24_Bit_Problems
	lea	PL_24_BIT_FIXES(pc),a0
	lea	$1500.w,a1
	bra.w	Apply_Patches


PL_24_BIT_FIXES
	PL_START
	; don't set bit 31 in sample pointers
	PL_SA	$1bdd6,$1bdda

	; always initialise sample
	PL_W	$1bc34,$4e71
	PL_END



; ---------------------------------------------------------------------------
; Blitter wait patches.

Fix_Blitter_Waits
	lea	PL_BLITTER_WAITS(pc),a0
	lea	$1500.w,a1
	bra.w	Apply_Patches


PL_BLITTER_WAITS
	PL_START
	PL_PS	$411c,.wblit1
	PL_PS	$41c4,.wblit2
	PL_PS	$41e6,.wblit2
	PL_PS	$4208,.wblit2

	PL_PS	$429a,.wblit1
	PL_PS	$4330,.wblit2
	PL_PS	$4348,.wblit2
	PL_PS	$4360,.wblit2
	
	PL_PS	$3d6a,.wblit1
	PL_PS	$3df2,.wblit2
	PL_PS	$3e0a,.wblit2
	PL_PS	$3e22,.wblit2

	PL_PS	$3e66,.wblit2
	PL_PS	$3e8a,.wblit2
	PL_PS	$3eae,.wblit2

	PL_PS	$3c40,.wblit1
	PL_PS	$3cc8,.wblit2
	PL_PS	$3cda,.wblit2
	PL_PS	$3cec,.wblit2

	PL_PS	$4734,.wblit1

	PL_PS	$2f0c,.wblit13

;	PL_PS	$2e22,.wblit3
;	PL_PSA	$2e24,.wblit14,$2e30

	PL_PS	$2e62,.wblit4

	PL_PS	$2e84,.wblit5
	PL_PS	$2e9a,.wblit5
	PL_PS	$2eb0,.wblit5

	PL_PS	$2ec8,.wblit6

	PL_PS	$35ea,.wblit7

	PL_PSS	$369c,.wblit8,2
	PL_PSS	$36cc,.wblit9,2
	PL_PS	$371a,.wblit10

	PL_PS	$370c,.wblit11
	PL_PSS	$3b52,.wblit12,2

	PL_PS	$2d96,.wblit13

	PL_PSS	$2e24,Wait_Blit_D0_50_A1_54,2
	PL_PSS	$2f5c,Wait_Blit_D0_50_A1_54,2
	PL_PSS	$34c8,Wait_Blit_D0_50_A1_54,2

	PL_PS	$b04,Wait_Blit_DFF000_A3
	PL_PS	$33d0,.wblit13
	PL_END



.wblit14
	bsr.w	Wait_Blit
	and.l	#$00ffffff,d0
	cmp.l	#$80000,d0
	bhs.b	.noblit
	move.l	d0,$50(a0)
	move.l	a1,$54(a0)
	move.w	d7,$58(a0)
.noblit	rts

.wblit13
	lea	$dff000,a0
	bra.w	Wait_Blit

.wblit12
	bsr.w	Wait_Blit
	move.w	#-1,$dff044
	rts

.wblit11
	bsr.w	Wait_Blit
	move.w	#-2,$62(a5)
	rts
	
.wblit10
	addq.w	#4,d5
	addq.w	#4,a0
	addq.w	#4,a1
	bra.w	Wait_Blit
	

.wblit9	bsr.w	Wait_Blit
	move.w	d6,$40(a5)
	move.l	a0,$50(a5)
	rts

.wblit8	bsr.w	Wait_Blit
	move.w	d7,$40(a5)
	move.l	a0,$50(a5)
	rts

.wblit7	lea	$dff000,a5
	bra.w	Wait_Blit

.wblit6	bsr.w	Wait_Blit
	move.w	#40,$66(a0)
	rts

.wblit5	add.w	#$2c,a1
	bra.w	Wait_Blit

.wblit4	bsr.w	Wait_Blit
	add.l	#$f0,d0
	and.l	#$00ffffff,d0	; fix 24 bit problem
	rts	

.wblit3	bsr.w	Wait_Blit
	add.l	d5,d0
	and.l	#$00ffffff,d0	; fix 24 bit problem
	move.l	d0,$50(a0)
	rts

.wblit2	move.w	d4,$58(a3)
	add.l	d5,a2
	bra.w	Wait_Blit

.wblit1	lea	$dff000,a3
	bra.w	Wait_Blit


Wait_Blit_D0_50_A1_54
	bsr	Wait_Blit
Clip_Blit_D0_50_A1_54
	and.l	#$80000-1,d0
	move.l	d0,$50(a0)
	move.l	a1,$54(a0)
	rts

Wait_Blit_DFF000_A3
	lea	$dff000,a3
	bra.w	Wait_Blit

; ---------------------------------------------------------------------------
; Highscore load/save

Load_Highscores
	movem.l	d0-a6,-(a7)
	lea	Highscore_Name(pc),a0
	bsr	File_Exists
	tst.l	d0
	beq.b	.no_highscore_file
	lea	Highscore_Name(pc),a0
	lea	$400.w,a1
	bsr	Load_File
.no_highscore_file
	movem.l	(a7)+,d0-a6
	rts

Save_Highscores
	movem.l	d0-a6,-(a7)
	lea	Highscore_Name(pc),a0
	lea	$400.w,a1
	moveq	#5*10,d0
	bsr	Save_File
	movem.l	(a7)+,d0-a6
	rts

; --------------------------------------------------------------------------
; CD32 controls

; Read jyoypad in level 3 interrupt.
Read_CD32_Pad
	bsr	_joystick
	bsr	Handle_CD32_Buttons

	; jump with joypad button
	;move.l	joy1(pc),d0
	;btst	#JPB_BTN_YEL,d0
	;beq.b	.no_jump
	;or.w	#1<<2,$1500+$3a0a.w
.no_jump
	movem.l	(a7)+,d0-a6
	rte


Enable_Button_Jump
	move.w	$dff00c,d0
	move.l	joy1(pc),d3
	btst	#JPB_BTN_GRN,d3
	beq.b	.jump_button_not_pressed
	move.w	#1<<8,d0
.jump_button_not_pressed
	rts



; Keys:
; C/V: volume down/up
; left shift: change weapon player 1
; right shift: change weapon player 2
; P: pause
; Escape: return to main menu


Button_Table_Player1
	dc.l	JPB_BTN_BLU,RAWKEY_LEFT_SHIFT
	dc.l	JPB_BTN_PLAY,RAWKEY_P|1<<RAWKEY_B_DELAY_RELEASE
	dc.l	JPB_BTN_REVERSE,RAWKEY_C
	dc.l	JPB_BTN_FORWARD,RAWKEY_V
	dc.l	JPB_BTN_YEL,RAWKEY_HELP
	dc.l	0

Button_Table_Player2
	dc.l	JPB_BTN_BLU,RAWKEY_RIGHT_SHIFT
	dc.l	JPB_BTN_PLAY,RAWKEY_P|1<<RAWKEY_B_DELAY_RELEASE
	dc.l	JPB_BTN_REVERSE,RAWKEY_C
	dc.l	JPB_BTN_FORWARD,RAWKEY_V
	dc.l	JPB_BTN_YEL,RAWKEY_HELP
	dc.l	0

Handle_CD32_Buttons
	lea	Button_Table_Player1(pc),a0
	lea	joy1(pc),a1
	lea	Last_Joypad1_State(pc),a2
	bsr.b	.Process_Buttons
	lea	Button_Table_Player2(pc),a0
	lea	joy0(pc),a1
	lea	Last_Joypad0_State(pc),a2

.Process_Buttons
	move.l	(a1),d0			; current joypad state
	move.l	(a2),d1			; previous joy state
	move.l	d0,(a2)	

	bsr.b	Handle_CD32_Button_Press
	bra.b	Handle_CD32_Button_Release


Last_Joypad0_State	dc.l	0
Last_Joypad1_State	dc.l	0
Release_Delay_Flag	dc.b	0
			dc.b	0


; a0.l: table with buttons to check
; d0.l: current joypad state
; d1.l: previous joypad state

Handle_CD32_Button_Press
	movem.l	d0-a6,-(a7)
.loop	movem.l	(a0)+,d2/d3
	btst	d2,d0
	beq.b	.check_next_button

	bclr	#RAWKEY_B_DELAY_RELEASE,d3
	lea	Release_Delay_Flag(pc),a1
	seq	(a1)

	; button pressed
	movem.l	d0-a6,-(a7)
	move.l	d3,d0
	lea	$1500+$3792.w,a1
	jsr	$1500+$387c.w
	movem.l	(a7)+,d0-a6

.check_next_button
	tst.l	(a0)
	bne.b	.loop
	movem.l	(a7)+,d0-a6
	rts

; a0.l: table with buttons to check
; d0.l: current joypad state
; d1.l: previous joypad state

Handle_CD32_Button_Release
	movem.l	d0-a6,-(a7)
.loop	movem.l	(a0)+,d2/d3
	btst	d2,d0
	bne.b	.button_is_currently_pressed
	btst	d2,d1
	beq.b	.check_next_button

	lea	Release_Delay_Flag(pc),a1
	tst.b	(a1)
	sf	(a1)
	beq	.check_next_button

	; button released
	movem.l	d0-a6,-(a7)
	move.l	d3,d0
	lea	$1500+$3792.w,a1
	jsr	$1500+$389c.w
	movem.l	(a7)+,d0-a6

.button_is_currently_pressed

.check_next_button
	tst.l	(a0)
	bne.b	.loop
	movem.l	(a7)+,d0-a6
	rts


; --------------------------------------------------------------------------
; Game end.

PL_EXTRO
	PL_START
	PL_ORW	$41c+2,1<<9			; set Bplcon0 color bit
	PL_P	$62c,Load_File_Number_Internal
	PL_SA	$ae,$b4				; skip write to Beamcon0
	PL_P	$11594,Acknowledge_Level6_Interrupt
	PL_P	$115b0,Acknowledge_Level6_Interrupt
	PL_PS	$2bae,Check_Quit_Key_Internal
	PL_END



; --------------------------------------------------------------------------
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

	bsr	Check_Quit_Key

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


	and.b	#~(1<<6),$e00(a1)		; set input mode
.end	move.w	#1<<3,$9c(a0)
	move.w	#1<<3,$9c(a0)			; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte



Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0				; ptr to custom routine



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
;
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
	add.w	#44*4*8,a3
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
	add.w	#44*4,a3
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


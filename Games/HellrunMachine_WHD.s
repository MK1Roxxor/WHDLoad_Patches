***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      HELLRUN MACHINE WHDLOAD SLAVE         )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             November 2023                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 29-Nov-2023	- level disk data support for game binary 2 (music)
;		  added
;		- 68000 quitkey support for title part added
;		- copde size optimised a bit
;		- a few more Bplcon0 color bit fixes added
;		- default quitkey changed to Del as F10 is used in the
;		  editor

; 28-Nov-2023	- editor patched to load/save levels
;		- game binary 1 (sound effects only) patched to support
;		  level disk data

; 27-Nov.2023	- second game binary fully patched

; 26-Nov-2023	- V2.0 rewrite started
;		- boot code, game and editor patched, game binary with
;		  music not fully patched yet
;


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Hardware/dmabits.i
	INCLUDE	hardware/intbits.i
	INCLUDE	hardware/custom.i
	IFND	_custom
_custom	= $dff000
	ENDC
	INCLUDE	hardware/cia.i
	IFND	_ciaa
_ciaa	= $bfe001
	ENDC
	INCLUDE	exec/types.i
	INCLUDE	exec/exec_lib.i
	INCLUDE	exec/io.i

	; Trainer options
	BITDEF	TR,UNLIMITED_LIVES,0

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $46		; Del
;DEBUG


; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM


CHIP_MEMORY_END	= $80000

HEADER	SLAVE_HEADER			; ws_security + ws_ID
	dc.w	17			; ws_version
	dc.w	FLAGS			; flags
	dc.l	$80000			; ws_BaseMemSize
	dc.l	0			; ws_ExecInstall
	dc.w	Patch-HEADER		; ws_GameLoader
	dc.w	0			; ws_CurrentDir
	dc.w	0			; ws_DontCache
	dc.b	0			; ws_KeyDebug
	dc.b	QUITKEY			; ws_KeyExit
	dc.l	0			; ws_ExpMem
	dc.w	.name-HEADER		; ws_name
	dc.w	.copy-HEADER		; ws_copy
	dc.w	.info-HEADER		; ws_info
	dc.w	0			; ws_kickname
	dc.l	0			; ws_kicksize
	dc.w	0			; ws_kickcrc
	dc.w	.config-HEADER		; ws_config


.config	dc.b	"C1:B:Disable Blitter Wait Patches;"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Games/HellrunMachine",0
	ENDC

.name	dc.b	"Hellrun Machine",0
.copy	dc.b	"1992 Amiga Fun",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 2.0 (29.11.2023)",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load boot code
	move.l	#512,d0
	move.l	#$1000,d1
	lea	$10000,a0
	bsr	Disk_Load

	move.l	a0,a5
	
	; Version check
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$b3aa,d0
	beq.b	.Version_is_Supported

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
.Version_is_Supported


	; Patch boot code
	lea	PL_BOOT_CODE(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; Set default level 3 interrupt
	pea	Acknowledge_Level3_Interrupt(pc)
	move.l	(a7)+,$6c.w

	; Run game
	jmp	(a5)


; ---------------------------------------------------------------------------

PL_BOOT_CODE
	PL_START
	PL_P	$342,Loader
	PL_PS	$7cc,.Initialise_Decruncher_Registers
	PL_PS	$54,.Patch_Title
	PL_PS	$a6,.Patch_Editor
	PL_PS	$162,.Patch_Game
	PL_PS	$110,.Patch_Game_With_Music
	PL_END


.Patch_Title
	lea	$30000,a1
	pea	$40000
	pea	PL_TITLE_BLIT(pc)
	pea	PL_TITLE(pc)
	bra.b	.Patch_Binary_a1

.Patch_Editor
	pea	$4606c
	pea	PL_EDITOR_BLIT(pc)
	pea	PL_EDITOR(pc)
	bra.b	.Patch_Binary
	
.Patch_Game
	pea	$49000
	pea	PL_GAME_BLIT(pc)
	pea	PL_GAME(pc)
	bra.b	.Patch_Binary


.Patch_Game_With_Music
	pea	$49000
	pea	PL_GAME_WITH_MUSIC_BLIT(pc)
	pea	PL_GAME_WITH_MUSIC(pc)


.Patch_Binary
	lea	$38000,a1
.Patch_Binary_a1
	move.l	(a7)+,a0
	bsr	Apply_Patches

	movem.l	d0/d1/a1,-(a7)
	clr.l	-(a7)		; TAG_DONE
	clr.l	-(a7)		; result
	pea	WHDLTAG_CUSTOM1_GET
	move.l	a7,a0
	move.l	resload(pc),a2
	jsr	resload_Control(a2)
	tst.w	6(a7)
	add.w	#3*4,a7
	movem.l	(a7)+,d0/d1/a1

	move.l	(a7)+,a0
	bne.b	.Blitter_Wait_Patches_Disabled
	bsr	Apply_Patches
.Blitter_Wait_Patches_Disabled
	rts	
	



; Decruncher uses register d2.l without initialising it.
; This causes an access fault during decrunching.
.Initialise_Decruncher_Registers
	moveq	#0,d2
	clr.w	d0
	move.b	-(a0),d0
	lsl.l	#8,d0
	rts


; a0.l: destination
; a1.l:	offset
; d0.l: size in bytes

Loader	move.l	d0,d1
	move.l	a1,d0
	bra.w	Disk_Load


; ---------------------------------------------------------------------------

PL_TITLE
	PL_START
	PL_AB	$10bf8+1,8-3	; increase DMA wait from 3 to 8 raster lines 
	PL_ORW	$10032+2,INTF_PORTS
	PL_W	$1006a+2,$2100	; SR value
	PL_END


PL_TITLE_BLIT
	PL_START
	PL_PS	$10524,Wait_Blit_d1_dff050
	PL_PS	$105d6,Wait_Blit_d1_dff050
	PL_PS	$1067c,Wait_Blit_d0_dff050
	PL_PS	$10750,Wait_Blit_d0_dff040
	PL_PS	$1077a,Wait_Blit_d0_dff040
	PL_PS	$107a4,Wait_Blit_d0_dff040
	PL_PS	$107ce,Wait_Blit_d0_dff040
	PL_PS	$107f8,Wait_Blit_d4_dff040
	PL_PS	$10822,Wait_Blit_d4_dff040
	PL_PS	$1084c,Wait_Blit_d4_dff040
	PL_PS	$10876,Wait_Blit_d4_dff040
	PL_PS	$108a0,Wait_Blit_d4_dff040
	PL_END

Wait_Blit_d1_dff050
	bsr	Wait_Blit
	move.l	d1,$dff050
	rts

Wait_Blit_d0_dff050
	bsr	Wait_Blit
	move.l	d0,$dff050
	rts

Wait_Blit_d0_dff040
	bsr	Wait_Blit
	move.w	d0,$dff040
	rts

Wait_Blit_d4_dff040
	bsr	Wait_Blit
	move.w	d4,$dff040
	rts

; ---------------------------------------------------------------------------

PL_EDITOR_BLIT
	PL_START
	PL_PSS	$e8e6,Wait_Blit_09f0_dff040,2
	PL_PSS	$f0d0,Wait_Blit_09f0_dff040,2
	PL_PSS	$f334,Wait_Blit_09f0_dff040,2
	PL_PSS	$f54c,Wait_Blit_0d0c_dff040,2
	PL_PSS	$f5a8,Wait_Blit_0dfc_dff040,2
	PL_PSS	$fe22,Wait_Blit_09f0_dff040,2
	PL_PSS	$1003e,Wait_Blit_09f0_dff040,2
	PL_PS	$1008e,Wait_Blit_d1_dff050
	PL_PSS	$100d8,Wait_Blit_09f0_dff040,2
	PL_PS	$10128,Wait_Blit_d0_dff050
	PL_PSS	$10198,Wait_Blit_0_dff042,2
	PL_PS	$101c8,Wait_Blit_d0_dff040
	PL_PS	$10204,Wait_Blit_d4_dff040
	PL_PSS	$1029c,Wait_Blit_09f0_dff040,2
	PL_PSS	$10474,Wait_Blit_0d0c_dff040,2
	PL_PSS	$104d0,Wait_Blit_0dfc_dff040,2
	PL_PSS	$105cc,Wait_Blit_0_dff042,2
	PL_PS	$105fc,Wait_Blit_d0_dff040
	PL_PS	$10638,Wait_Blit_d4_dff040
	PL_PSS	$106e4,Wait_Blit_0d0c_dff040,2
	PL_PSS	$10746,Wait_Blit_0dfc_dff040,2
	PL_END

PL_EDITOR
	PL_START
	PL_ORW	$ef3e+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$e9be+2,1<<9	; set Bplcon0 color bit
	PL_P	$10b24,Load_Level_Data
	PL_P	$10b7e,Save_Level_Data
	PL_R	$10bf0		; disable disk formatting
	PL_PSS	$e480,Load_Level_Disk_ID,4	; save level
	PL_PSS	$e684,Load_Level_Disk_ID,4	; load level
	PL_END

Load_Level_Data
	move.l	a1,d1
	sub.l	#$c0000,d1
	move.l	a0,a1
	lea	Level_Disk_Name(pc),a0
	bra.w	Load_File_Offset	

Save_Level_Data
	move.l	a1,d1
	sub.l	#$c0000,d1
	move.l	a0,a1
	lea	Level_Disk_Name(pc),a0
	bra.w	Append_File


; ---------------------------------------------------------------------------

PL_GAME_BLIT
	PL_START
	PL_PSS	$120e0,Wait_Blit_09f0_dff040,2
	PL_PSS	$1214c,Wait_Blit_69f0_dff040,2
	PL_PSS	$1224c,Wait_Blit_09f0_dff040,2
	PL_PSS	$122d4,Wait_Blit_09f0_dff040,2
	PL_PSS	$123fc,Wait_Blit_0d0c_dff040,2
	PL_PSS	$12458,Wait_Blit_0dfc_dff040,2
	PL_PSS	$1251e,Wait_Blit_0d0c_dff040,2
	PL_PSS	$1257a,Wait_Blit_0dfc_dff040,2
	PL_PSS	$1279e,Wait_Blit_09f0_dff040,2
	PL_PS	$127ee,Wait_Blit_d1_dff050
	PL_PSS	$12838,Wait_Blit_09f0_dff040,2
	PL_PS	$12888,Wait_Blit_d0_dff050
	PL_PSS	$128e0,Wait_Blit_09f0_dff040,2
	PL_PS	$1290a,Wait_Blit_d0_dff050
	PL_PSS	$1299a,Wait_Blit_0_dff042,2
	PL_PS	$129ca,Wait_Blit_d0_dff040	
	PL_PS	$12a06,Wait_Blit_d4_dff040
	PL_PSS	$12a82,Wait_Blit_09f0_dff040,2
	PL_PS	$12a9c,Wait_Blit_d0_dff050
	PL_PSS	$11d40,Wait_Blit_09f0_dff040,2
	PL_PS	$11d5a,Wait_Blit_d0_dff050
	PL_PSS	$11e82,Wait_Blit_09f0_dff040,2
	PL_PS	$11e9c,Wait_Blit_d1_dff050
	PL_PSS	$11ce0,Wait_Blit_09f0_dff040,2
	PL_PS	$11cfa,Wait_Blit_d1_dff050
	PL_PSS	$13e1a,Wait_Blit_09f0_dff040,2
	PL_PS	$13e6a,Wait_Blit_d1_dff050
	PL_PSS	$13e98,Wait_Blit_09f0_dff040,2
	PL_PS	$13ee8,Wait_Blit_d3_dff050
	PL_PSS	$13f2c,Wait_Blit_0_dff042,2
	PL_PS	$13f5c,Wait_Blit_d0_dff040
	PL_PS	$13f98,Wait_Blit_d4_dff040
	PL_PSS	$138b6,Wait_Blit_0d0c_dff040,2
	PL_PS	$138e8,Wait_Blit_d1_dff050
	PL_PSS	$13912,Wait_Blit_0dfc_dff040,2
	PL_PS	$13944,Wait_Blit_d4_dff050
	PL_END

Wait_Blit_09f0_dff040
	bsr	Wait_Blit
	move.w	#$09f0,$dff040
	rts

Wait_Blit_69f0_dff040
	bsr	Wait_Blit
	move.w	#$69f0,$dff040
	rts

Wait_Blit_0d0c_dff040
	bsr	Wait_Blit
	move.w	#$0d0c,$dff040
	rts

Wait_Blit_0dfc_dff040
	bsr	Wait_Blit
	move.w	#$0dfc,$dff040
	rts

Wait_Blit_0_dff042
	bsr	Wait_Blit
	move.w	#0,$dff042
	rts

Wait_Blit_d3_dff050
	bsr	Wait_Blit
	move.l	d3,$dff050
	rts

Wait_Blit_d4_dff050
	bsr	Wait_Blit
	move.l	d4,$dff050
	rts


PL_GAME	PL_START
	PL_ORW	$12f5a+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$12f72+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$12f7a+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$12fda+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$1311e+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$1327a+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$132d6+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$1338e+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$13396+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$134f2+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$1354e+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$13606+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$13632+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$111ca+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$11128+2,1<<9	; set Bplcon0 color bit
	

	PL_P	$2e27c,Fix_Access_Fault
	PL_PSS	$2ea10,.Load_Level_Disk_ID,4
	PL_PSS	$2ea66,.Load_Level_Data,4
	PL_END

.Load_Level_Disk_ID
	cmp.b	#1,$38000+$2eb77
	bne.b	Load_Level_Disk_ID
	moveq	#14,d0
	bra.w	Loader	


.Load_Level_Data
	move.l	#1032,d0
	cmp.b	#1,$38000+$2eb77
	bne.w	Load_Level_Data
	bra.w	Loader

; Out of bounds memory access in fireworks routine.
Fix_Access_Fault
	move.l	d0,a6
	cmp.l	#CHIP_MEMORY_END,a6
	bcc.b	.exit
	eor.b	d3,(a6)
.exit	rts




; a0.l: destination
; a1.l: offset in bytes

Load_Level_Disk_ID
	move.l	a0,d7
	lea	Level_Disk_Name(pc),a0
	bsr	File_Exists
	tst.l	d0
	beq.b	.no_level_data_found
	move.l	a1,d1
	sub.l	#$c0000,d1
	move.l	d7,a1
	moveq	#14,d0
	bsr	Load_File_Offset
.no_level_data_found
	rts

Level_Disk_Name
	dc.b	"HellrunMachine_Levels",0
	CNOP	0,2

; ---------------------------------------------------------------------------

PL_GAME_WITH_MUSIC_BLIT
	PL_START
	PL_PSS	$11d90,Wait_Blit_09f0_dff040,2
	PL_PS	$11daa,Wait_Blit_d1_dff050
	PL_PSS	$11df0,Wait_Blit_09f0_dff040,2
	PL_PS	$11e0a,Wait_Blit_d0_dff050
	PL_PSS	$11f32,Wait_Blit_09f0_dff040,2
	PL_PS	$11f4c,Wait_Blit_d1_dff050
	PL_PSS	$12190,Wait_Blit_09f0_dff040,2
	PL_PSS	$121fc,Wait_Blit_69f0_dff040,2
	PL_PSS	$122fc,Wait_Blit_09f0_dff040,2
	PL_PSS	$12384,Wait_Blit_09f0_dff040,2
	PL_PSS	$124ac,Wait_Blit_0d0c_dff040,2
	PL_PSS	$12508,Wait_Blit_0dfc_dff040,2
	PL_PSS	$125ce,Wait_Blit_0d0c_dff040,2
	PL_PSS	$1262a,Wait_Blit_0dfc_dff040,2
	PL_PSS	$1284e,Wait_Blit_09f0_dff040,2
	PL_PS	$1289e,Wait_Blit_d1_dff050
	PL_PSS	$128e8,Wait_Blit_09f0_dff040,2
	PL_PS	$12938,Wait_Blit_d0_dff050
	PL_PSS	$12990,Wait_Blit_09f0_dff040,2
	PL_PS	$129ba,Wait_Blit_d0_dff050
	PL_PSS	$12a4a,Wait_Blit_0_dff042,2
	PL_PS	$12a7a,Wait_Blit_d0_dff040
	PL_PS	$12ab6,Wait_Blit_d4_dff040
	PL_PSS	$12b32,Wait_Blit_09f0_dff040,2
	PL_PS	$12b4c,Wait_Blit_d0_dff050
	PL_PSS	$137c0,Wait_Blit_0d0c_dff040,2
	PL_PS	$137f2,Wait_Blit_d1_dff050
	PL_PSS	$1381c,Wait_Blit_0dfc_dff040,2
	PL_PS	$1384e,Wait_Blit_d4_dff050
	PL_PSS	$13a66,Wait_Blit_09f0_dff040,2
	PL_PS	$13ab6,Wait_Blit_d1_dff050
	PL_PSS	$13ae4,Wait_Blit_09f0_dff040,2
	PL_PS	$13b34,Wait_Blit_d3_dff050
	PL_PSS	$13b78,Wait_Blit_0_dff042,2
	PL_PS	$13ba8,Wait_Blit_d0_dff040
	PL_PS	$13be4,Wait_Blit_d4_dff040
	PL_END


PL_GAME_WITH_MUSIC
	PL_START
	PL_AB	$46ed6+1,8-3	; increase DMA wait from 3 to 8 raster lines 
	PL_ORW	$11146+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$111e8+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$1300c+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$13024+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$1302c+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$1308c+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$131d0+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$1332c+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$13388+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$13440+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$13448+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$135a4+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$13600+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$136b8+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$136e4+2,1<<9	; set Bplcon0 color bit
	
	PL_P	$2e256,Fix_Access_Fault
	PL_PSS	$2e8fc,.Load_Level_Disk_ID,4
	PL_PSS	$2e952,.Load_Level_Data,4
	PL_END


.Load_Level_Disk_ID
	cmp.b	#1,$38000+$2ea63
	bne.w	Load_Level_Disk_ID
	moveq	#14,d0
	bra.w	Loader	


.Load_Level_Data
	move.l	#1032,d0
	cmp.b	#1,$38000+$2ea63
	bne.w	Load_Level_Data
	bra.w	Loader

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
.wait1	btst	#0,_custom+vposr+1
	beq.b	.wait1
.wait2	btst	#0,_custom+vposr+1
	bne.b	.wait2
	rts



; d0.w: number of raster lines to wait
Wait_Raster_Lines
	move.w	d1,-(a7)
.loop	move.b	_custom+vhposr,d1
.still_in_same_raster_line
	cmp.b	_custom+vhposr,d1
	beq.b	.still_in_same_raster_line	
	subq.w	#1,d0
	bne.b	.loop
	move.w	(a7)+,d1
	rts


Wait_Blit
	tst.b	_custom+dmaconr
.blitter_is_busy
	btst	#DMAB_BLITTER,_custom+dmaconr
	bne.b	.blitter_is_busy
	rts


; ---------------------------------------------------------------------------

Acknowledge_Level3_Interrupt
	move.w	#INTF_BLIT|INTF_COPER|INTF_VERTB,_custom+intreq
	move.w	#INTF_BLIT|INTF_COPER|INTF_VERTB,_custom+intreq
	rte

; ---------------------------------------------------------------------------

; d0.l: offset
; d1.l: size
; a0.l: destination

Disk_Load
	movem.l	d0-a6,-(a7)
	moveq	#1,d2
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
; a1.l: destination
; d0.l: size
; d1.l: offset
; -----
; d0.l: file size

Load_File_Offset
	movem.l	d1-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_LoadFileOffset(a2)
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
; a1.l: data to save
; d0.l: size in bytes
; d1.l: offset

Append_File
	movem.l	d1-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_SaveFileOffset(a2)
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


Enable_Keyboard_Interrupt
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,_custom+intena
	rts

Disable_Keyboard_Interrupt
	move.w	#INTF_PORTS,_custom+intena
	rts


; Level 2 interrupt used to handle keyboard events.

Init_Level2_Interrupt
	pea	.int(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode


	move.w	#INTF_PORTS,_custom+intreq	; clear ports interrupt
	bra.w	Enable_Keyboard_Interrupt

.int	movem.l	d0-d1/a0-a2,-(a7)
	lea	_custom,a0
	lea	_ciaa,a1

	btst	#INTB_PORTS,intreqr+1(a0)
	beq.b	.end

	btst	#CIAICRB_SP,ciaicr(a1)
	beq.b	.end

	lea	Key(pc),a2
	moveq	#0,d0
	move.b	ciasdr(a1),d0
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)+
	or.b	#CIACRAF_SPMODE,ciacra(a1)	; set output mode

	bsr.w	Check_Quit_Key

	move.l	(a2)+,d1
	beq.b	.no_keyboard_custom_routine
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.no_keyboard_custom_routine
	
	moveq	#3,d0
	bsr	Wait_Raster_Lines

	and.b	#~CIACRAF_SPMODE,ciacra(a1)	; set input mode
.end	move.w	#INTF_PORTS,intreq(a0)
	move.w	#INTF_PORTS,intreq(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte



Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine

; ---------------------------------------------------------------------------


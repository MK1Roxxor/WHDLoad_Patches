***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   DYLAN DOG: THE MURDERERS WHDLOAD SLAVE   )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            December 2023                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 20-Jan-2024	- complete system crash after quitting the game finally
;		  fixed
;		- credits can be skipped with CUSTOM1
;		- trainer option (in-game keys) added

; 16-Jan-2024	- PowerPacker decruncher relocated

; 04-Dec-2023	- quitkey handling fixed
;		- 68000 quitkey support for game part added

; 03-Dec-2023	- copperlist problem in credits fixed
;		- game patched in intro part too
;		- blitter waits added
;		- stack relocated to low memory

; 02-Dec-2023	-
;
; 01-Dec-2023	- work started
;		- intro and game patched, protection completely skipped


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
	BITDEF	TR,UNLIMITED_CONTINUES,1
	BITDEF	TR,UNLIMITED_ENERGY,2
	BITDEF	TR,UNLIMITED_TIME,3
	BITDEF	TR,IN_GAME_KEYS,4

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

RAWKEY_E	= $12
RAWKEY_A	= $20

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


.config	dc.b	"C1:B:Skip Credits;"
	dc.b	"C2:B:In-Game Keys"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Games/DylanDog",0
	ENDC

.name	dc.b	"Dylan Dog: The Murderers",0
.copy	dc.b	"1992 Simulmondor",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 2.0 (20.01.2024)",-1
	dc.b	"In-Game Keys:",10
	dc.b	"A: Refresh Ammo  E: Refresh Energy",0


	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load boot code
	move.l	#2*512,d0
	move.l	#8000,d1
	moveq	#1,d2
	lea	$7a000,a0
	bsr	Disk_Load

	move.l	a0,a5
	
	; Version check
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$D804,d0
	beq.b	.Version_is_Supported

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
.Version_is_Supported


	; Patch boot code
	lea	PL_BOOT_CODE(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; Disable extended memory
	clr.w	$0.w

	; Set available disk drives
	move.w	#1<<0|1<<1,$2.w

	; Run game
	lea	_custom,a6
	jmp	(a5)




; ---------------------------------------------------------------------------

PL_BOOT_CODE
	PL_START
	PL_PS	$26a,Check_Quit_Key_Game
	PL_P	$f2,Patch_Intro
	PL_P	$112,Patch_Game
	PL_PSA	$6e,WaitRaster,$7e	; fix wrong rasterline wait
	PL_PSA	$98,WaitRaster,$a8	; fix wrong rasterline wait
	PL_PSS	$122,WaitRaster,2	; fix wrong rasterline wait
	PL_P	$2cc,Loader
	PL_W	$0+2,INTF_SETCLR|INTF_INTEN|INTF_PORTS
	PL_P	$5ce,Decrunch_PowerPacker
	PL_END

Patch_Intro
	lea	PL_INTRO(pc),a0
	pea	$6000.w
	move.l	(a7),a1
	bra.w	Apply_Patches

Patch_Game
	lea	PL_GAME(pc),a0
	pea	$14900
	move.l	(a7),a1
	bra.w	Apply_Patches
	

Check_Quit_Key_Game
	move.b	$bfec01,d0
	move.w	d0,-(a7)
	ror.b	d0
	not.b	d0
	bsr	Check_Quit_Key
	move.w	(a7)+,d0
	rts


Loader	move.w	d0,d3
	mulu.w	#512,d0
	bsr	Disk_Load
	movem.l	d0-a6,-(a7)
	bsr.b	.Patch
	movem.l	(a7)+,d0-a6
	rts

.Patch	lea	.Patch_Table(pc),a1
.check_all_entries
	movem.w	(a1)+,d6/d7/a2
	cmp.w	d6,d3
	bne.b	.check_next_entry
	cmp.w	d7,d2
	beq.b	.Apply_Patch

.check_next_entry
	tst.w	(a1)
	bne.b	.check_all_entries
	rts

.Apply_Patch
	move.l	a0,a1
	lea	.Patch_Table(pc,a2.w),a0
	bra.w	Apply_Patches


; Format: offset, disk number, offset to patchlist
.Patch_Table
	dc.w	$c200/512,1,PL_CREDITS-.Patch_Table
	dc.w	$14a00/512,2,PL_ROOM-.Patch_Table
	dc.w	0

; ---------------------------------------------------------------------------

PL_INTRO
	PL_START
	PL_P	$bca,Loader
	PL_PS	$c0,Check_Quit_Key_Game
	PL_PSS	$1c0c,Fix_DMA_Wait,2
	PL_PSS	$1c24,Fix_DMA_Wait,2
	PL_P	$1f0c,Fix_Volume_Write
	PL_PS	$1ce,.Initialise_Bitplane_Size
	PL_P	$962,Patch_Game
	PL_P	$9d0,Decrunch_PowerPacker
	PL_END

.Initialise_Bitplane_Size
	move.l	#40*200,d3
	moveq	#2,d4
	rts

Fix_Volume_Write
	move.w	d0,8(a5)
	rts

; ---------------------------------------------------------------------------

PL_GAME	PL_START
	PL_P	$6596,Loader
	PL_SA	$580,$5ae		; completely skip protection
	PL_PSS	$6c1c,Fix_DMA_Wait,2
	PL_PSS	$6c34,Fix_DMA_Wait,2
	PL_P	$6f1c,Fix_Volume_Write
	PL_PS	$9a,Check_Quit_Key_Game
	PL_IFC2
	PL_PS	$9a,.Handle_In_Game_Keys
	PL_ENDIF
	PL_END

.Handle_In_Game_Keys
	bsr	Check_Quit_Key_Game

	movem.l	d0-a6,-(a7)
	ror.b	d0
	not.b	d0
	lea	RawKey(pc),a0
	move.b	d0,(a0)

	lea	.TAB(pc),a0
	bsr	Handle_Keys
	movem.l	(a7)+,d0-a6
	rts

	
.TAB 	dc.w	RAWKEY_E,.Refresh_Energy-.TAB
	dc.w	RAWKEY_A,.Refresh_Ammo-.TAB
	dc.w	0			; end of table


.Refresh_Energy
	clr.w	$14900+$7f20
	rts

.Refresh_Ammo
	move.w	#7,$14900+$7f22
	rts

; ---------------------------------------------------------------------------

PL_CREDITS
	PL_START
	PL_L	$2d6a,$fffffffe		; terminate copperlist
	PL_PS	$c,.Disable_Interrupts
	PL_PS	$40,.Enable_Interrupts

	PL_IFC1
	PL_W	$0,$4e75
	PL_ENDIF
	PL_END

.Disable_Interrupts
	move.w	#INTF_INTEN,intena(a6)
	move.w	#7,$8e(a4)
	rts

.Enable_Interrupts
	move.w	#INTF_SETCLR|INTF_INTEN,intena(a6)
	move.w	#7,$8e(a4)
	rts


; ---------------------------------------------------------------------------

PL_ROOM	PL_START
	PL_PS	$b06,.Wait_Blit_d4_a1_dff050
	PL_PS	$b68,.Wait_Blit_d4_a1_dff050
	PL_END

.Wait_Blit_d4_a1_dff050
	bsr	Wait_Blit
	movem.l	d4/a1,$dff050
	rts

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



Fix_DMA_Wait
	moveq	#8,d0

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

Flush_Cache
	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts

; ---------------------------------------------------------------------------

; d0.l: offset
; d1.l: size
; d2.b: disk number
; a0.l: destination

Disk_Load
	movem.l	d0-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d0-a6
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
;
; Check_Quit_Key:
; - checks the defined quitkey and exits WHDLoad if this key
;   is pressed
;
; Set_Keyboard_Custom_Routine:
; - sets pointer to routine that should be called when a key has
;   been pressed
;
; Remove_Keyboard_Custom_Routine:
; - removes the keyboard custom rouine
;
; Enable_Keyboard_Interrupt:
; - enables level 2 (ports) interrupts
;
; Disable_Keyboard_Interrupt:
; - disables level 2 (ports) interrupts, keys will not be processed anymore
;
; Handle_Keys:
; - processes all keys in the table that is supplied in register a0 and
;   calls the routines defined for each key
;   Table has the following format:
;   dc.w RawKey_Code, dc.w Offset_To_Routine (this offset is relative to
;                                             the start of the table)
;
; Example:
; .TAB	dc.w	$36,.Skip-Level-.TAB
;	dc.w	0			; end of table

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
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,_custom+intena
	rts

Disable_Keyboard_Interrupt
	move.w	#INTF_PORTS,_custom+intena
	rts

; a0.l: table with keys and corresponding routines to call

Handle_Keys
	move.l	a0,a1
	moveq	#0,d0
	move.b	RawKey(pc),d0
.check_all_key_entries
	movem.w	(a0)+,d1/d2
	cmp.w	d0,d1
	beq.b	.key_entry_found
	tst.w	(a0)
	bne.b	.check_all_key_entries
	rts	
	
.key_entry_found
	lea	RawKey(pc),a0
	sf	(a0)
	pea	Flush_Cache(pc)
	jmp	(a1,d2.w)

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

; d0.l: efficiency
; a0.l: end of crunched data
; a1.l: destination

Decrunch_PowerPacker
	lea	.Efficiency(pc),a5
	move.l	d0,(a5)
	move.l	a1,a2
	move.l	-(a0),d5
	moveq	#0,d1
	move.b	d5,d1
	lsr.l	#8,d5
	add.l	d5,a1
	move.l	-(a0),d5
	lsr.l	d1,d5
	move.b	#$20,d7
	sub.b	d1,d7
.lbC0005EA
	bsr.b	.lbC000656
	tst.b	d1
	bne.b	.lbC000610
	moveq	#0,d2
.lbC0005F2
	moveq	#2,d0
	bsr.b	.lbC000658
	add.w	d1,d2
	cmp.w	#3,d1
	beq.b	.lbC0005F2
.lbC0005FE
	move.w	#8,d0
	bsr.b	.lbC000658
	move.b	d1,-(a1)
	dbra	d2,.lbC0005FE
	cmp.l	a1,a2
	bcs.b	.lbC000610
	rts

.lbC000610
	moveq	#2,d0
	bsr.b	.lbC000658
	moveq	#0,d0
	move.b	(a5,d1.w),d0
	move.l	d0,d4
	move.w	d1,d2
	addq.w	#1,d2
	cmp.w	#4,d2
	bne.b	.lbC000642
	bsr.b	.lbC000656
	move.l	d4,d0
	tst.b	d1
	bne.b	.lbC000630
	moveq	#7,d0
.lbC000630
	bsr.b	.lbC000658
	move.w	d1,d3
.lbC000634
	moveq	#3,d0
	bsr.b	.lbC000658
	add.w	d1,d2
	cmp.w	#7,d1
	beq.b	.lbC000634
	bra.b	.lbC000646

.lbC000642
	bsr.b	.lbC000658
	move.w	d1,d3
.lbC000646
	move.b	(a1,d3.w),d0
	move.b	d0,-(a1)
	dbra	d2,.lbC000646
	cmp.l	a1,a2
	bcs.b	.lbC0005EA
	rts

.lbC000656
	moveq	#1,d0
.lbC000658
	moveq	#0,d1
	subq.w	#1,d0
.lbC00065C
	lsr.l	#1,d5
	roxl.l	#1,d1
	subq.b	#1,d7
	bne.b	.lbC00066A
	move.b	#$20,d7
	move.l	-(a0),d5
.lbC00066A
	dbra	d0,.lbC00065C
	rts

.Efficiency	dc.l	0

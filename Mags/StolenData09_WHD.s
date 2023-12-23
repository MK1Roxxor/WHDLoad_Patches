***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(     STOLEN DATA 9/ANARCHY WHDLOAD SLAVE    )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             December 2023                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************


; 23-Dec-2023	- work started
;		- and finished some hours later: write to read only
;		  custom registers fixed (x7), illegal copperlist entries
;		  fixed, interrupts fixed, blitter waits added (x2), wrong
;		  blitter clear routine disabled (x2), byte write to volume
;		  register fixed (x4), Bplcon0 color bit fixes (x3)


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


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
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


.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Mags/StolenData09",0
	ENDC

.name	dc.b	"Stolen Data 9",0
.copy	dc.b	"1992 Anarchy",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.00 (23.12.2023)",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load bootblock
	moveq	#0,d0
	move.l	#512*2,d1
	lea	$200-$ec.w,a0
	bsr	Disk_Load

	move.l	a0,a5
	
	; Version check
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$5192,d0
	beq.b	.Version_is_Supported

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
.Version_is_Supported


	; Patch bootblock
	lea	PL_BOOTBLOCK(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; Set default level 3 interrupt
	pea	Acknowledge_Level3_Interrupt(pc)
	move.l	(a7)+,$6c.w

	; Run bootblock code
	jmp	3*4(a5)


; ---------------------------------------------------------------------------

PL_BOOTBLOCK
	PL_START
	PL_SA	$e4,$ea		; don't copy code around
	PL_NOPS	$fa,1		; disable blitter wait (DMA is not enabled yet)
	PL_P	$1c2,Loader
	PL_ORW	$3d2+2,1<<9	; set Bplcon0 color bit
	PL_PS	$130,Wait_For_Vertical_Blank_Interrupt
	PL_P	$15a,.Patch_Title
	PL_PS	$146,Patch_Part_Number
	PL_END

.Patch_Title
	trap	#1
	move.w	#$4e75,$4600+$1a8.w	; disable jmp $70000
	bsr	Flush_Cache
	jsr	$4600.w			; decrunch

	lea	PL_TITLE(pc),a0
	pea	$70000
	move.l	(a7),a1
	bra.w	Apply_Patches

; d0.w: length (sectors)
; d1.w: starting sector
; a1.l: destination

Loader	move.l	a1,a0
	exg	d0,d1
	mulu.w	#512,d0
	mulu.w	#512,d1
	bsr	Disk_Load
	rte

Fix_Volume_Write
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	$13(a1),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts

; d0.w: part number
; -----
; a1.l: part code

Patch_Part_Number
	move.w	d0,-(a7)
	trap	#2
	jsr	$4600.w		; decrunch
	move.w	(a7)+,d0
	add.w	d0,d0
	lea	.TAB(pc),a0
	add.w	(a0,d0.w),a0
	lea	$4a00.w,a1
	bra.w	Apply_Patches

.TAB	dc.w	0
	dc.w	PL_MAG-.TAB	; 01
	dc.w	PL_GALLERY-.TAB ; 02
	dc.w	PL_CHARTS-.TAB	; 03
	dc.w	PL_MENU-.TAB

; ---------------------------------------------------------------------------

PL_TITLE
	PL_START
	PL_ORW	$29c+2,1<<9		; set Bplcon0 color bit
	PL_PS	$138,Wait_For_Vertical_Blank_Interrupt
	PL_PS	$154,Wait_For_Vertical_Blank_Interrupt
	PL_PSA	$b2,.Set_Default_Copperlist,$c2
	PL_P	$c2,.Patch_Menu
	PL_END


.Set_Default_Copperlist
	lea	$200-$ec.w,a0
	move.l	#$fffffffe,(a0)
	move.l	a0,cop1lc(a6)
	rts

.Patch_Menu
	lea	PL_MENU(pc),a0
	lea	$4a00.w,a1
	bsr	Apply_Patches
	jmp	2(a1)


Check_If_Vertical_Blank_Interrupt
	btst	#INTB_VERTB,intreqr+1(a6)
	rts

Wait_For_Vertical_Blank_Interrupt
	bsr.b	Check_If_Vertical_Blank_Interrupt
	beq.b	Wait_For_Vertical_Blank_Interrupt
	rts


Check_If_Copper_Interrupt
	btst	#INTB_COPER,intreqr+1(a6)
	rts

Wait_For_Copper_Interrupt
	bsr.b	Check_If_Copper_Interrupt
	beq.b	Wait_For_Copper_Interrupt
	rts

; ---------------------------------------------------------------------------

PL_MENU	PL_START
	PL_P	$1d0,Acknowledge_Level6_Interrupt
	PL_P	$228,Acknowledge_Level6_Interrupt
	PL_P	$a56,Fix_Volume_Write
	PL_PS	$1398,Acknowledge_Vertical_Blank_Interrupt
	PL_ORW	$be4+2,INTF_PORTS
	PL_SA	$c42,$c48		; skip buggy blitter clear
	PL_SA	$c54,$c5a		; as above
	PL_SA	$24ac6,$24ad2		; skip illegal copper instructions
	PL_P	$24ad6,.Flush_Cache	; after copying code to $68000
	PL_PS	$24b0e,Wait_For_Vertical_Blank_Interrupt
	PL_PS	$24af6,Patch_Part_Number
	PL_PS	$24a98,Wait_For_Copper_Interrupt
	PL_PS	$24b4e,Wait_For_Vertical_Blank_Interrupt
	PL_END

.Flush_Cache
	bsr	Flush_Cache
	jmp	$68000

; ---------------------------------------------------------------------------

PL_GALLERY
	PL_START
	PL_PS	$3cc,Wait_For_Copper_Interrupt
	PL_P	$e9e,Fix_Volume_Write
	PL_PS	$7e,Acknowledge_Vertical_Blank_Interrupt
	PL_ORW	$4e+2,INTF_PORTS
	PL_END

; ---------------------------------------------------------------------------

PL_CHARTS
	PL_START
	PL_SA	$1e,$22			; don't write to joy0dat
	PL_P	$5cc,Acknowledge_Level6_Interrupt
	PL_P	$624,Acknowledge_Level6_Interrupt
	PL_PS	$23e,Acknowledge_Vertical_Blank_Interrupt
	PL_ORW	$66+2,INTF_PORTS
	PL_P	$e52,Fix_Volume_Write
	PL_END

; ---------------------------------------------------------------------------

PL_MAG	PL_START
	PL_PS	$72,Check_If_Vertical_Blank_Interrupt
	PL_PS	$a4,Acknowledge_Level3_Interrupt_R
	PL_P	$2778,Acknowledge_Level6_Interrupt
	PL_P	$27d0,Acknowledge_Level6_Interrupt
	PL_PS	$1e54,.Check_Quit_Key
	PL_P	$31c92,.Set_Disk2
	PL_ORW	$325e+2,1<<9		; set Bplcon0 color bit
	PL_PS	$11fe,.Wait_Blit
	PL_PS	$1192,.Wait_Blit2
	PL_P	$2ffe,Fix_Volume_Write
	PL_END

.Wait_Blit
	ror.w	#4,d1
	or.w	#$fca,d1
	bra.w	Wait_Blit

.Wait_Blit2
	bsr	Wait_Blit
	move.w	#0,$42(a6)
	moveq	#-1,d0
	rts


.Check_Quit_Key
	bsr.b	.Get_Key
	ror.b	d0
	not.b	d0
	bsr	Check_Quit_Key
.Get_Key
	move.b	$bfec01,d0
	rts

.Set_Disk2
	moveq	#2,d0
	bra.w	Set_Disk_Number

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

Flush_Cache
	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts

; ---------------------------------------------------------------------------

Acknowledge_Vertical_Blank_Interrupt
	move.w	#INTF_VERTB,intreq(a6)
	move.w	#INTF_VERTB,intreq(a6)
	rts

Acknowledge_Level3_Interrupt_R
	move.w	#INTF_BLIT|INTF_COPER|INTF_VERTB,_custom+intreq
	move.w	#INTF_BLIT|INTF_COPER|INTF_VERTB,_custom+intreq
	rts

Acknowledge_Level3_Interrupt
	move.w	#INTF_BLIT|INTF_COPER|INTF_VERTB,_custom+intreq
	move.w	#INTF_BLIT|INTF_COPER|INTF_VERTB,_custom+intreq
	rte

Acknowledge_Level6_Interrupt
	move.w	#INTF_EXTER,_custom+intreq
	move.w	#INTF_EXTER,_custom+intreq
	rte

; ---------------------------------------------------------------------------

; d0.l: offset
; d1.l: size
; a0.l: destination

Disk_Load
	movem.l	d0-a6,-(a7)
	move.b	Disk_Number(pc),d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d0-a6
	rts

Set_Disk_Number
	move.l	a0,-(a7)
	lea	Disk_Number(pc),a0
	move.b	d0,(a0)
	move.l	(a7)+,a0
	rts

Disk_Number	dc.b	1
		dc.b	0

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

; Level 2 interrupt used to handle keyboard events.

Init_Level2_Interrupt
	pea	.int(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode


	move.w	#INTF_PORTS,_custom+intreq	; clear ports interrupt
	bra.b	Enable_Keyboard_Interrupt

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


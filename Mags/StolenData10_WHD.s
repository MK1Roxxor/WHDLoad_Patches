***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    STOLEN DATA 10/ANARCHY WHDLOAD SLAVE    )*)---.---.   *
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


; 22-Dec-2023	- work started
;		- and finished about 4.5 hours later, all parts patched:
;		  interrupts fixed, byte write to volume register fixed (x3),
;		  blitter waits added (x2), Bplcon0 color bit fixes (x5),
;		  wrong blit disabled, write to INTREQR fixed (x7)



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


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap|WHDLF_NoKbd
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
	dc.b	"SOURCES:WHD_Slaves/Mags/StolenData10",0
	ENDC

.name	dc.b	"Stolen Data 10",0
.copy	dc.b	"1992 Anarchy",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.00 (22.12.2023)",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Load bootblock
	moveq	#0,d0
	move.l	#512*2,d1
	lea	$200-$28.w,a0
	bsr	Disk_Load

	move.l	a0,a5
	
	; Version check
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$efc6,d0
	beq.b	.Version_is_Supported

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
.Version_is_Supported


	; Patch bootblock
	lea	PL_BOOTBLOCK(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; Run bootblock code
	jmp	3*4(a5)


; ---------------------------------------------------------------------------

PL_BOOTBLOCK
	PL_START
	PL_SA	$20,$26		; don't copy code around
	PL_NOPS	$36,1		; disable blitter wait (DMA is not enabled yet)
	PL_P	$112,Loader
	PL_P	$a4,.Wait_VBL
	PL_ORW	$322+2,1<<9	; set Bplcon0 color bit
	PL_P	$82,.Patch_Title
	PL_P	$6e,.Patch_Mag
	PL_END

.Patch_Mag
	jsr	$4400.w
	lea	PL_MAG(pc),a0
	lea	$4800.w,a1
	bsr	Apply_Patches
	jmp	2(a1)

.Patch_Title
	pea	$7c000
	lea	PL_Title(pc),a0
	move.l	(a7),a1
	bra.w	Apply_Patches


; Original code:
; and.w d1,intreqr(a6)
.Wait_VBL
	move.w	intreqr(a6),d0
	and.w	d1,d0
	bne.b	.Wait_VBL
	rts


; d0.w: length (sectors)
; d1.w: starting sector
; d2.w:
; a1.l: destination

Loader	move.l	a1,a0
	exg	d0,d1
	mulu.w	#512,d0
	mulu.w	#512,d1
	bsr	Disk_Load
	rte

; ---------------------------------------------------------------------------
; Stolen Data 10 title picture

PL_Title
	PL_START
	PL_ORW	$2a2+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$312+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$12e+4,1<<9	; set Bplcon0 color bit
	PL_PS	$14c,.Wait_VBL
	PL_PS	$168,.Wait_VBL
	PL_P	$138,.Patch_Menu
	PL_END

.Wait_VBL
	move.w	intreqr(a6),d1
	and.w	d0,d1
	beq.b	.Wait_VBL
	rts

.Patch_Menu
	lea	PL_MENU(pc),a0
	lea	$4800.w,a1
	bsr.w	Apply_Patches

	lea	$200-$28.w,a0
	move.l	#$fffffffe,(a0)
	move.l	a0,$80(a6)

	jmp	$4802.w


; ---------------------------------------------------------------------------

PL_MENU	PL_START
	PL_P	$21c,Acknowledge_Level6_Interrupt
	PL_P	$274,Acknowledge_Level6_Interrupt
	PL_SA	$c92,$c98	; skip blitter start
	PL_PS	$154d8,.Wait_VBL
	PL_PS	$15400,.Wait_for_Copper_Interrupt
	PL_PS	$1549a,.Patch_Parts
	PL_SA	$1542e,$1543a
	PL_PS	$13da,.Check_Quit_Key
	PL_END

.Check_Quit_Key
	lea	$BFEC01,a0
	move.b	(a0),d0
	ror.b	#1,d0
	not.b	d0
	bsr	Check_Quit_Key
	or.b	#1<<6,$200(a0)
	clr.b	(a0)
	and.b	#$BF,$200(a0)

	bra.w	Acknowledge_Level3_Interrupt_R


.Wait_VBL
	btst	#INTB_VERTB,intreqr+1(a6)
	rts

.Patch_Parts
.No_VBL	bsr.b	.Wait_VBL
	beq.b	.No_VBL

	cmp.l	#$4802,a1
	beq.b	.Patch_Mag

	lea	$4800+$1636.w,a5
	move.w	$38(a5),d0
	add.w	d0,d0
	lea	.TAB(pc),a0
	add.w	(a0,d0.w),a0
	lea	$30000,a1
	bsr	Apply_Patches
	jmp	$30002


.TAB	dc.w	0
	dc.w	PL_GALLERY-.TAB
	dc.w	PL_CHARTS-.TAB
	dc.w	PL_JUKEBOX-.TAB



.Patch_Mag
	lea	PL_MAG(pc),a0
	lea	$4800.w,a1
	bsr	Apply_Patches
	jmp	2(a1)

.Wait_for_Copper_Interrupt
	btst	#INTB_COPER,intreqr+1(a6)
	beq.b	.Wait_for_Copper_Interrupt
	rts

; ---------------------------------------------------------------------------

PL_MAG	PL_START
	PL_P	$4b0ce,.Set_Disk2
	PL_PS	$72,.Check_If_Vertical_Blank_Interrupt
	PL_PS	$a4,Acknowledge_Level3_Interrupt
	PL_P	$2906,Acknowledge_Level6_Interrupt
	PL_P	$295e,Acknowledge_Level6_Interrupt
	PL_P	$318c,Fix_Volume_Write
	PL_ORW	$33ec+2,1<<9		; set Bplcon0 color bit
	PL_PS	$1f98,.Check_Quit_Key

	PL_PS	$12ce,.Wait_Blit1
	PL_PS	$1268,.Wait_Blit2
	PL_END

.Check_Quit_Key
	bsr.b	.Get_Key
	ror.b	d0
	not.b	d0
	bsr	Check_Quit_Key
.Get_Key
	move.b	$bfec01,d0
	rts


.Wait_Blit1
	bsr	Wait_Blit
	add.w	d0,a3
	move.l	a3,$50(a6)
	rts

.Wait_Blit2
	bsr	Wait_Blit
	move.w	#0,$42(a6)
	moveq	#-1,d0
	rts


.Check_If_Vertical_Blank_Interrupt
	btst	#INTB_VERTB,intreqr+1(a6)
	rts


.Set_Disk2
	moveq	#2,d0
	bra.w	Set_Disk_Number

Fix_Volume_Write
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	$13(a1),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts


; ---------------------------------------------------------------------------

PL_GALLERY
	PL_START
	PL_PS	$7e,Acknowledge_Level3_Interrupt_R
	PL_PS	$3ee,Check_If_Copper_Interrupt
	PL_P	$786,Acknowledge_Level6_Interrupt
	PL_P	$7de,Acknowledge_Level6_Interrupt
	PL_PS	$dc,Check_Quit_Key_Internal
	PL_P	$100c,Fix_Volume_Write
	PL_END

Check_Quit_Key_Internal
	lea	$bfec01,a0
	move.b	(a0),d0
	ror.b	d0
	not.b	d0
	bra.w	Check_Quit_Key

Check_If_Copper_Interrupt
	btst	#INTB_COPER,intreqr+1(a6)
	rts

; ---------------------------------------------------------------------------

PL_CHARTS
	PL_START
	PL_P	$1092,Fix_Volume_Write
	PL_PS	$35c,Check_Quit_Key_Internal
	PL_PS	$3ec,Acknowledge_Level3_Interrupt_R
	PL_P	$80c,Acknowledge_Level6_Interrupt
	PL_P	$864,Acknowledge_Level6_Interrupt
	PL_END
	

; ---------------------------------------------------------------------------

PL_JUKEBOX
	PL_START
	PL_P	$f82,Fix_Volume_Write
	PL_PS	$21e,Acknowledge_Level3_Interrupt_R
	PL_PS	$1b4,Check_Quit_Key_Internal
	PL_P	$6fc,Acknowledge_Level6_Interrupt
	PL_P	$754,Acknowledge_Level6_Interrupt
	PL_END

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

Acknowledge_Level3_Interrupt_R
	move.w	#INTF_VERTB,intreq(a6)
	move.w	#INTF_VERTB,intreq(a6)
	rts	

Acknowledge_Level3_Interrupt
	move.w	#INTF_BLIT|INTF_COPER|INTF_VERTB,_custom+intreq
	move.w	#INTF_BLIT|INTF_COPER|INTF_VERTB,_custom+intreq
	rts

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


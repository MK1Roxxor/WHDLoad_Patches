***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    MUSIC DISK 3 / VEGA WHDLOAD SLAVE       )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            September 2023                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 03-Sep-2023	- ScrollRaster emulation works correctly now
;		- ByteKiller patching simplified, routine
;		  Patch_ByteKiller_Executable added
;		- CPU dependent delay loops in intro fixed (used for the
;		  sprite animation when the VEGA logo is shown)
;		- DMA wait in replayer fixed (x2)
;		- byte write to volume register fixed
;		- level 2 interrupt in intro enabled (move.w #$2700,sr
;		  skipped)
;		- patch is finished!

; 02-Sep-2023	- work started
;		- all parts patched, ScrollRaster emulation code doesn't
;		  work properly yet though


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Hardware/dmabits.i
	INCLUDE	hardware/intbits.i
	INCLUDE	exec/types.i
	INCLUDE	exec/exec_lib.i
	INCLUDE	exec/io.i
	INCLUDE	graphics/graphics_lib.i
	INCLUDE	graphics/rastport.i
	INCLUDE	hardware/custom.i


RAWKEY_F10	= $59

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= RAWKEY_F10
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

.name	dc.b	"Musicdisk 3",0
.copy	dc.b	"1991 Vega",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.00 (03.09.2023)",0

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
	lea	$1100.w,a0
	bsr	Disk_Load

	move.l	a0,a5
	
	; Version check
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$9432,d0
	beq.b	.Version_is_Supported

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
.Version_is_Supported


	; Install exec library emulation
	lea	(EXEC_LOCATION).w,a0
	move.l	a0,$4.w
	bsr	Create_Exec_Emulation

	; Install graphics emulation
	lea	(GRAPHICS_LOCATION).w,a0
	bsr	Create_Graphics_Emulation

	; Patch bootblock
	lea	PL_BOOTBLOCK(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; Relocate stack to low memory
	lea	$1000.w,a7

	; Run demo
	move.l	$4.w,a6
	lea	1024(a5),a1		; IoStd
	jmp	3*4(a5)


; ---------------------------------------------------------------------------

PL_BOOTBLOCK
	PL_START
	PL_PS	$62,.Patch_Intro_Loader
	PL_END


.Patch_Intro_Loader
	lea	PL_INTRO_LOADER(pc),a0
	pea	$28000
	move.l	(a7),a1
	bra.w	Apply_Patches


; ---------------------------------------------------------------------------

PL_INTRO_LOADER
	PL_START
	PL_ORW	$1ea+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$32+2,1<<9		; set Bplcon0 color bit
	PL_P	$3a,.Patch_Intro
	PL_SA	$40,$5a
	PL_R	$e2	
	PL_END


.Patch_Intro
	lea	$61000,a0
	lea	PL_INTRO(pc),a1
	bra.w	Patch_ByteKiller_Executable
	

; ---------------------------------------------------------------------------

PL_INTRO
	PL_START
	PL_ORW	$30e+2,1<<9		; set Bplcon0 color bit
	PL_P	$250,.Patch_Main_Part
	PL_PSS	$974,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PSS	$98c,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_P	$c5e,Fix_Volume_Write
	PL_S	$16,4			; skip move to SR
	PL_PSA	$62,.Delay_C000,$80
	PL_PSA	$94,.Delay_C000,$ac
	PL_PSA	$c6,.Delay_C000,$de
	PL_PSA	$f8,.Delay_C000,$110
	PL_PSA	$12a,.Delay_C000,$142
	PL_PSA	$15c,.Delay_C000,$174
	PL_PSA	$18e,.Delay_C000,$1a6
	PL_PSA	$1c0,.Delay_C000,$1d8
	PL_PSA	$1ea,.Delay_18000,$202
	PL_END

.Delay_C000
	move.w	#$c000/34,d0
	bra.w	Wait_Raster_Lines

.Delay_18000
	moveq	#5*10,d0		; display VEGA logo for 5 seconds
	move.l	resload(pc),a0
	jmp	resload_Delay(a0)


.Patch_Main_Part
	lea	$30000,a0
	lea	PL_MAIN_PART(pc),a1
	bra.w	Patch_ByteKiller_Executable
	

; ---------------------------------------------------------------------------

PL_MAIN_PART
	PL_START
	PL_ORW	$402+2,1<<9		; set Bplcon0 color bit
	PL_SA	$e8,$f2			; don't modify interrupt code
	PL_P	$226,Acknowledge_Level3_Interrupt
	PL_P	$1ca,QUIT
	PL_W	$fc+2,$c028
	PL_R	$610			; disable drive access
	PL_S	$da,6			; skip mt_init, no module loaded yet

	PL_PSA	$16,.Open_Gfx,$20
	PL_END

.Open_Gfx
	move.l	#GRAPHICS_LOCATION,d0
	rts


; ---------------------------------------------------------------------------
; Exec emulation code

EXEC_LOCATION	= $3000
OPCODE_JMP	= $4ef9


; a0.l: exec location
Create_Exec_Emulation
	lea	.TAB(pc),a1
.loop	movem.w	(a1)+,d0/d1
	lea	(a0,d0.w),a2
	move.w	#OPCODE_JMP,(a2)+
	pea	.TAB(pc,d1.w)
	move.l	(a7)+,(a2)
	tst.w	(a1)
	bne.b	.loop
	rts

.TAB	dc.w	_LVODoIO,DoIO_Emulation-.TAB
	dc.w	_LVOOpenDevice,Do_Nothing-.TAB
	dc.w	_LVOOpenLibrary,Do_Nothing-.TAB
	dc.w	_LVOForbid,Do_Nothing-.TAB
	dc.w	_LVOFindTask,Do_Nothing-.TAB
	dc.w	0			: end of tab


IOSTD_LOCATION	= $4000
DoIO_Emulation
	cmp.w	#CMD_READ,IO_COMMAND(a1)
	bne.b	.unsupported_command

	movem.l	d0-a6,-(a7)
	move.l	IO_DATA(a1),a0
	move.l	IO_OFFSET(a1),d0
	move.l	IO_LENGTH(a1),d1
	bsr	Disk_Load
	movem.l	(a7)+,d0-a6

.unsupported_command
Do_Nothing
	rts


; ---------------------------------------------------------------------------
; Grpahics library emulation code

GRAPHICS_LOCATION	= $2000

; a0.l: graphics location
Create_Graphics_Emulation
	lea	.TAB(pc),a1
.loop	movem.w	(a1)+,d0/d1
	lea	(a0,d0.w),a2
	move.w	#OPCODE_JMP,(a2)+
	pea	.TAB(pc,d1.w)
	move.l	(a7)+,(a2)
	tst.w	(a1)
	bne.b	.loop
	rts

.TAB	dc.w	_LVORectFill,.Gfx_Rect_Fill-.TAB
	dc.w	_LVOInitRastPort,.Gfx_Init_RastPort-.TAB
	dc.w	_LVOInitBitMap,.Gfx_Init_BitMap-.TAB
	dc.w	_LVOSetAPen,.Gfx_Set_A_Pen-.TAB
	dc.w	_LVOScrollRaster,.Gfx_Scroll_Raster-.TAB
	dc.w	0			: end of tab


; a1.l: RastPort

.Gfx_Init_RastPort
	move.l	a1,a0
	;moveq	#rp_SIZEOF-1,d0
	moveq	#78-1,d0			; 1.3 value!
.cls	clr.b	(a0)+
	dbf	d0,.cls

	moveq	#-1,d0
	move.b	d0,rp_Mask(a1)
	move.b	d0,rp_FgPen(a1)
	move.b	d0,rp_AOLPen(a1)
	move.w	d0,rp_LinePtrn(a1)
	move.b	#RP_JAM2,rp_DrawMode(a1)
	rts

; emulates gfx/InitBitMap()
; a0.l: bitmap
; d0.b: depth
; d1.w: width
; d2.w: height

.Gfx_Init_BitMap
	clr.b	bm_Flags(a0)
	clr.w	bm_Pad(a0)
	move.w	d2,bm_Rows(a0)
	move.b	d0,bm_Depth(a0)
	add.w	#15,d1
	asr.w	#4,d1
	add.w	d1,d1
	move.w	d1,bm_BytesPerRow(a0)
	rts

.Gfx_Set_A_Pen
	move.b	d0,rp_FgPen(a1)
	move.b	#15,rp_linpatcnt(a1)
	or.w	#RPF_FRST_DOT,rp_Flags(a1)
	move.b	#$CA,rp_minterms(a1)	; minterm: AB+!AC
	rts

; a1.l: RastPort
; d0.w: dx
; d1.w: dy
; d2.w: xmin
; d3.w: ymin
; d4.w: xmax
; d5.w: ymax

; This is not a generic ScrollRaster emulation, it only works
; for Vega's Music Disk 3.
.Gfx_Scroll_Raster
	bsr	Wait_Blit
	lea	$dff000,a0
	move.l	rp_BitMap(a1),a2
	lea	bm_Planes(a2),a2
	move.l	(a2),a3
	add.w	#40*179-2,a3
	move.l	a3,bltcpt(a0)
	move.l	a3,bltdpt(a0)
	sub.w	#4*40,a3
	move.l	a3,bltbpt(a0)

	moveq	#(320-112)/8,d0

	move.w	d0,bltbmod(a0)
	move.w	d0,bltcmod(a0)
	move.w	d0,bltdmod(a0)
	move.w	#$ffff,bltafwm(a0)
	move.w	#$000f,bltalwm(a0)
	move.w	#$ffff,bltadat(a0)
	move.w	#$07ca,bltcon0(a0)
	move.w	#$0002,bltcon1(a0)
	move.w	#(154<<6)|(112/16),bltsize(a0)
	bra.w	Wait_Blit



.lmasktable:	dc.l	$ffff7fff,$3fff1fff,$0fff07ff,$03ff01ff,$00ff007f
	dc.l	$003f001f,$000f0007,$00030001,0

; a1.l: RastPort
; d0.w: x1
; d1:w: y1
; d2.w: x2
; d3.w: y2

.Gfx_Rect_Fill
	movem.l	d2-d7/a2-a6,-(a7)
	move.l	rp_BitMap(a1),a2

	lea	$dff000,a0
	sub.w	d1,d3				; endy-=starty
	addq.w	#1,d3
	mulu	bm_BytesPerRow(a2),d1		; convert to byte offset
	moveq	#15,d6
	move.w	d0,d4
	and.w	d6,d4
	add.w	d4,d4
	move.w	.lmasktable(pc,d4.w),d4		; d4: fwm
	move.w	d2,d5
	and.w	d6,d5
	add.w	d5,d5
	move.w	.lmasktable+2(pc,d5.w),d5	; d5: lwm
	not.w	d5

	lsr.w	#4,d0
	lsr.w	#4,d2
	sub.w	d0,d2				; d2: # of words blitted
	addq.w	#1,d2
	add.w	d0,d0				; byte offset
	ext.l	d0
	add.l	d0,d1				; and add to memory base in d1

	move.w	d2,d6				; save width for later
	add.w	d2,d2
	sub.w	bm_BytesPerRow(a2),d2
	neg.w	d2				; d2: modulo
	lea	rp_minterms(a1),a5
	lea	bm_Planes(a2),a3
	moveq	#0,d0
	bsr	Wait_Blit
	lsl.w	#6,d3
	add.w	d6,d3				; d3: blit size
	move.w	d4,bltafwm(a0)
	move.w	d5,bltalwm(a0)
	move.w	d2,bltdmod(a0)
	move.w	d2,bltcmod(a0)
	move.w	d0,bltcon1(a0)
	moveq	#-1,d2
	move.l	d2,bltbdat(a0)
	move.b	bm_Depth(a2),d0
	move.b	rp_Mask(a1),d2
	move.w	#$300,d4
	bra.b	.end_lp1

.lp1	move.b	(a5)+,d4
	move.l	(a3)+,a4
	lsr.b	#1,d2
	bcc.s	.end_lp1
	add.l	d1,a4
	bsr	Wait_Blit
	move.w	d4,bltcon0(a0)
	move.l	a4,bltdpt(a0)
	move.l	a4,bltcpt(a0)
	move.w	d3,bltsize(a0)
.end_lp1
	dbf	d0,.lp1
	movem.l	(a7)+,d2-d7/a2-a6
	bra.w	Wait_Blit


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


Fix_Volume_Write
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts

Fix_DMA_Wait
	moveq	#8,d0

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


; ---------------------------------------------------------------------------

Acknowledge_Level3_Interrupt
	move.w	#INTF_BLIT|INTF_VERTB|INTF_COPER,$dff09c
	move.w	#INTF_BLIT|INTF_VERTB|INTF_COPER,$dff09c
	rte	

; ---------------------------------------------------------------------------


Wait_Blit
	tst.b	$dff002
.wait_blit
	btst	#6,$dff002
	bne.b	.wait_blit
	rts

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
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,$dff09a
	rts


; Level 2 interrupt used to handle keyboard events.

Init_Level2_Interrupt
	pea	.int(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode


	move.w	#INTF_PORTS,$dff09c		; clear ports interrupt
	bra.b	Enable_Keyboard_Interrupt

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

	and.b	#~(1<<6),$e00(a1)		; set input mode
.end	move.w	#INTF_PORTS,$9c(a0)
	move.w	#INTF_PORTS,$9c(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte



Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine

; ---------------------------------------------------------------------------
; Patch a ByteKiller crunched executable and run it.

; a0.l: start of executable
; a1.l: patch list


Patch_ByteKiller_Executable
	move.l	a1,-(a7)
	bsr	Decrunch_ByteKiller_Executable
	move.l	(a7)+,a0
	move.l	a1,-(a7)
	bra.w	Apply_Patches


; ---------------------------------------------------------------------------

; a0.l: start of executable
; ----
; a1.l: decrunched data

Decrunch_ByteKiller_Executable
	move.l	$28+2(a0),a1		; destination
	add.w	#$10c,a0		; start of crunched data
	move.l	a1,-(a7)
	bsr.b	ByteKiller_Decrunch
	move.l	(a7)+,a1
	rts


; ---------------------------------------------------------------------------

; Bytekiller decruncher
; resourced and adapted by stingray

ByteKiller_Decrunch
	bsr.b	.decrunch
	tst.l	d5
	beq.b	.ok

; checksum doesn't match, file corrupt
	pea	.ErrTxt(pc)
	pea	(TDREASON_FAILMSG).w
	move.l	resload(pc),a0
	jmp	resload_Abort(a0)


.ok	rts

.ErrTxt	dc.b	"Decrunching failed, file corrupt!",0
	cnop	0,4

.decrunch
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d5
	move.l	a1,a2
	add.l	d0,a0
	add.l	d1,a2
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

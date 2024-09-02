***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*( DIGITAL NOIZE II/THE EVIL FORCES WHDLOAD   )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            September 2024                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 02-Sep-2024	- work started
;		- and finished a while later: all OS stuff patched,
;		  blitter waits added (x3), Bplcon0 color bit fixes (x34),
;		  self-modifying code fixed, interrupts fixed, copperlist
;		  problems fixed, sprite bugs fixed


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Hardware/dmabits.i
	INCLUDE	hardware/intbits.i
	INCLUDE	hardware/custom.i
	IFND	_custom
_custom = $dff000
	ENDC
	INCLUDE	exec/exec_lib.i
	INCLUDE	exec/types.i
	INCLUDE	exec/io.i


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

.name	dc.b	"Digital Noize II",0
.copy	dc.b	"1990 The Evil Forces",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.00 (02.09.2024)",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load bootblock
	moveq	#0,d0
	move.l	#1024,d1
	lea	$1000.w,a0
	bsr	Disk_Load

	move.l	a0,a5
	
	; Version check
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$5153,d0
	beq.b	.Version_is_Supported

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
.Version_is_Supported


	; Install exec library emulation
	lea	(EXEC_LOCATION).w,a0
	move.l	a0,$4.w
	bsr	Create_Exec_Emulation


	; Patch bootblock
	lea	PL_BOOTBLOCK(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	bsr	Set_Default_Level3_Interrupt
	move.l	#-2,$1000.w

	; Run demo
	move.l	$4.w,a6
	lea	IOSTD_LOCATION.w,a1	; StdIo
	jmp	3*4(a5)


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
	dc.w	_LVOForbid,Do_Nothing-.TAB
	dc.w	_LVOPermit,Do_Nothing-.TAB
	dc.w	_LVOFindTask,Do_Nothing-.TAB
	dc.w	_LVOAddPort,Do_Nothing-.TAB
	dc.w	_LVOOpenDevice,Do_Nothing-.TAB
	dc.w	0			: end of tab


IOSTD_LOCATION	= $2000
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

PL_BOOTBLOCK
	PL_START
	PL_PS	$38,.Patch_Crunched_Intro
	PL_PS	$68,.Patch_Crunched_Title_Picture
	PL_PS	$98,.Patch_Crunched_Main_Part
	PL_END

.Patch_Crunched_Intro
	lea	$2a000,a0
	pea	.Patch_Intro(pc)
	move.l	(a7)+,$1a8+2(a0)
	bsr	Flush_Cache
	jmp	$20(a0)

.Patch_Intro
	lea	PL_INTRO(pc),a0
	pea	$3c000
	move.l	(a7),a1
	bra.w	Apply_Patches

.Patch_Crunched_Title_Picture
	lea	$50000,a0
	pea	.Patch_Title_Picture(pc)
	move.l	(a7)+,$11a+2(a0)
	bsr	Flush_Cache
	jmp	$20(a0)

.Patch_Title_Picture
	lea	PL_TITLE_PICTURE(pc),a0
	pea	$7e000
	move.l	(a7),a1
	bra.w	Apply_Patches
	

.Patch_Crunched_Main_Part
	lea	$50000,a0
	pea	.Patch_Main_Part(pc)
	move.l	(a7)+,$1a8+2(a0)
	bsr	Flush_Cache
	jmp	$20(a0)

.Patch_Main_Part
	lea	PL_MAIN_PART(pc),a0
	pea	$10000
	move.l	(a7),a1
	bra.w	Apply_Patches

; ---------------------------------------------------------------------------

PL_INTRO
	PL_START
	PL_ORW	$3e+2,INTF_PORTS	; enable level 2 interrupts
	PL_B	$208c+1,8		; increase DMA wait to 8 raster lines
	PL_SA	$98,$a2			; don't modify interrupt code
	PL_P	$100,Acknowledge_Level3_Interrupts
	PL_PSS	$b6,Set_Default_Level3_Interrupt,4
	PL_ORW	$270a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2712+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$274a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2846+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$287a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$28da+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2976+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$29fe+2,1<<9		; set Bplcon0 color bit
	PL_PS	$6a0,.Wait_Blit_09F0_40
	PL_PS	$2fc,.Wait_Blit_Inc_A0
	PL_PS	$5ea,.Wait_Blit_Mul2_D0
	PL_P	$d8,.Clear_Sprites
	PL_END

.Clear_Sprites
	moveq	#8-1,d7
	lea	$4000.w,a0
	move.l	a0,d6
	move.w	#sprpt,d0
.loop	move.w	d0,(a0)+
	addq	#2,d0
	move.w	d0,(a0)+
	addq.w	#2,d0
	dbf	d7,.loop
	moveq	#-2,d0
	move.l	d0,(a0)

	bsr	WaitRaster
	move.l	d6,$dff080
	rts

.Wait_Blit_09F0_40
	bsr	Wait_Blit
	move.w	#$09f0,$40(a6)
	rts

.Wait_Blit_Inc_A0
	add.w	#16,a0
	bra.w	Wait_Blit

.Wait_Blit_Mul2_D0
	add.l	d0,d0
	add.l	d0,a1
	bra.w	Wait_Blit

; ---------------------------------------------------------------------------

PL_TITLE_PICTURE
	PL_START
	PL_ORW	$60+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$230+2,1<<9		; set Bplcon0 color bit
	PL_END
	

; ---------------------------------------------------------------------------

PL_MAIN_PART
	PL_START
	PL_ORW	$1a+2,INTF_PORTS	; enable level 2 interrupts
	PL_B	$7ea+1,8		; increase DMA wait to 8 raster lines
	PL_SA	$2a,$32			; don't modify interrupt code
	PL_P	$5f8,Acknowledge_Level3_Interrupts
	PL_PSS	$60,Set_Default_Level3_Interrupt,2
	PL_ORW	$2058+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2068+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$20a8+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$20b0+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$20fc+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2110+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$215c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2170+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2178+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2200+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2208+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2268+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2274+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$22c4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2544+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2590+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2598+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$25a0+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$25f0+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2604+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2690+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2698+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$26d4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$26dc+2,1<<9		; set Bplcon0 color bit
	PL_L	$74+2,$1000		; set valid copperlist location
	PL_END


.Enable_Level2_Interrupt
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,$9a(a6)
	bsr	WaitRaster
	move.w	#$87c0,$96(a6)		; original code, enable DMA channels
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

Set_Default_Level3_Interrupt
	pea	Acknowledge_Level3_Interrupts(pc)
	move.l	(a7)+,$6c.w
	rts

Acknowledge_Level3_Interrupts
	move.w	#INTF_COPER|INTF_VERTB|INTF_BLIT,_custom+intreq
	move.w	#INTF_COPER|INTF_VERTB|INTF_BLIT,_custom+intreq
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

Disable_Keyboard_Interrupt
	move.w	#INTF_PORTS,$dff09a
	rts

; Level 2 interrupt used to handle keyboard events.

Init_Level2_Interrupt
	pea	.int(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode


	move.w	#INTF_PORTS,$dff09c		; clear ports interrupt
	bra.w	Enable_Keyboard_Interrupt

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


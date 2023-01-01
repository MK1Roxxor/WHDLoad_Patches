***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       SINK OR SWIM WHDLOAD SLAVE           )*)---.---.   *
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

; 31-Dec-2022	- code optimised a bit
;		- DMA wait fix changed to wait for 8 instead of 5 lines
;		- interrupts fixed
;		- 68000 quitkey support
;		- delay for extended memory and game over picture added
;		- out of bounds blit in intro routine fixed (512k version)
;		- highscore load/save added

; 30-Dec-2022	- work started
;		- Bplcon0 color bit fixes, DMA wait in replayer fixed


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Hardware/dmabits.i
	INCLUDE	hardware/intbits.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

CHIPMEMORY_SIZE	= $80000


	
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
	dc.l	CHIPMEMORY_SIZE		; ws_BaseMemSize
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


.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Games/SinkOrSwim/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Sink or Swim",0
.copy	dc.b	"1993 Zeppelin",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.2 (31.12.2022)",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Set extended memory
	IFGT	CHIPMEMORY_SIZE-$80000
	move.l	#$80000*2,$7fffc
	ENDC

	; Load game
	move.l	#"FRED",d0
	lea	$3e0.w,a1
	bsr	Load_Boot_File

	; Version check
	move.l	a1,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$F4C0,d0		; SPS 1065
	beq.b	.Version_is_Supported
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
.Version_is_Supported


	; Patch game
	lea	PL_GAME(pc),a0
	lea	$400.w,a1
	move.l	a1,a5
	bsr	Apply_Patches

	; Load title picture
	move.l	#"TITL",d0
	lea	$58000,a1
	bsr	Load_Boot_File

	; And display it
	bsr	Display_Title_Picture

	; Run game
	moveq	#0,d2
	jmp	(a5)


; ---------------------------------------------------------------------------

Display_Title_Picture
	move.l	a1,a0
	lea	$dff180,a1
	moveq	#32-1,d7
.set_colors
	move.w	(a0)+,(a1)+
	dbf	d7,.set_colors

	move.l	a0,d0
	lea	Plane_Pointer(pc),a0
	moveq	#5-1,d7
.initialise_planes
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	swap	d0
	add.l	#$28a0,d0
	addq.w	#8,a0
	dbf	d7,.initialise_planes	

	lea	Copperlist(pc),a0
	move.l	d0,a1			; copperlist behind picture data
	move.l	a1,$dff080		; all DMA is off, uninitialised 
					; copperlist can be set
.copy_copperlist
	move.l	(a0)+,(a1)+
	bpl.b	.copy_copperlist

	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_RASTER|DMAF_COPPER,$dff096

Picture_Delay
	move.l	resload(pc),a0
	moveq	#5*10,d0
	jmp	resload_Delay(a0)

Copperlist
	dc.w	$8e,$2c81
	dc.w	$90,$2cc1
	dc.w	$92,$38
	dc.w	$94,$d0
	dc.w	$102,$00
	dc.w	$104,$00
Plane_Pointer
	dc.w	$e0,0,$e2,0
	dc.w	$e4,0,$e6,0
	dc.w	$e8,0,$ea,0
	dc.w	$ec,0,$ee,0
	dc.w	$f0,0,$f2,0
	dc.w	$100,$5200
	dc.l	-2

; ---------------------------------------------------------------------------

PL_GAME	PL_START
	PL_R	$122b4			; disable directory loading
	PL_P	$12306,.Load_Game_File
	PL_R	$12442			; disable drive access (motor on)
	PL_PSS	$1360,.Fix_Delay_2500_d6,2
	PL_PSS	$12dce,.Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_PSS	$12de6,.Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_ORW	$116fe+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$11746+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$d2+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$11738+2,1<<9		; set Bplcon0 color bit
	PL_SA	$15a,$1a4		; skip disk 2 request
	PL_P	$1309c,.Fix_Volume_Write
	PL_ORW	$498+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$f5b4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1172a+2,1<<9		; set Bplcon0 color bit

	PL_P	$42a,Acknowledge_Vertical_Blank_Interrupt
	PL_PSS	$6072,Acknowledge_Vertical_Blank_Interrupt_Request,2

	PL_PS	$5dba,.Check_Quit_Key	
	PL_PS	$100,.Display_Picture	; extra chip memory found
	PL_PS	$ee86,.Display_Picture	; game over picture

	PL_PS	$89ba,.Clear_D2		; fix illegal blit in intro
	PL_P	$f100,.Save_Highscores
	PL_END

.Save_Highscores
	bsr	Save_Highscores
	jmp	$400+$36a.w		; original code

; This fixes the illegal blit in the intro.
.Clear_D2
	moveq	#0,d2
	move.w	d2,$dff066
	rts

.Display_Picture
	jsr	$400+$1165a		; display IFF picture
	bra.w	Picture_Delay	

; d0.b: raw key
.Check_Quit_Key
	clr.b	$bfec01			; original code
	bra.w	Check_Quit_Key

.Fix_Delay_2500_d6
	move.w	d0,-(a7)
	move.w	#2500/$34,d0
	bsr.w	Wait_Raster_Lines
	move.w	(a7)+,d0
	rts

.Fix_DMA_Wait
	moveq	#8,d0
	bra.w	Wait_Raster_Lines

.Fix_Volume_Write
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts


.Load_Game_File
	move.l	$400+$122fe,a1

; ---------------------------------------------------------------------------

; d0.l: file name
; a1.l: pointer to destination address

Load_Boot_File
	lea	File_Name(pc),a0
	move.l	d0,(a0)
	bra.w	Load_File


File_Name	ds.b	4+1		; +1 for null-termination
		CNOP	0,2

; ---------------------------------------------------------------------------

HIGHSCORE_LOCATION	= $400+$1274c
HIGHSCORE_SIZE		= $127b2-$1274c

Load_Highscores
	lea	Highscore_Name(pc),a0
	bsr	File_Exists
	tst.l	d0
	beq.b	.no_highscore_file_found
	lea	HIGHSCORE_LOCATION,a1
	bsr	Load_File

.no_highscore_file_found
	rts

Save_Highscores
	lea	Highscore_Name(pc),a0
	lea	HIGHSCORE_LOCATION,a1
	moveq	#HIGHSCORE_SIZE,d0
	bra.w	Save_File
	

Highscore_Name	dc.b	"SinkOrSwim.high",0
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

Acknowledge_Vertical_Blank_Interrupt
	bsr.b	Acknowledge_Vertical_Blank_Interrupt_Request
	rte

Acknowledge_Vertical_Blank_Interrupt_Request
	move.w	#INTF_VERTB,$dff09c
	move.w	#INTF_VERTB,$dff09c
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

; d0.b: rawkey code

Check_Quit_Key
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
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

	bsr.b	Check_Quit_Key

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


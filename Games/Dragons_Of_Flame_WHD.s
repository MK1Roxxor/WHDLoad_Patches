***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      DRAGONS OF FLAME WHDLOAD SLAVE        )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             December 2022                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 20-Dec-2022	- annoying save game bug fixed, save disk directory is
;		  properly initialised now if needed
;		- all disk requests patched/removed
;		- save disk is created automatically if it doesn't exist
;		- this patch is now finally finished!

; 19-Dec-2022	- DMA wait in sample player fixed (x2)
;		- highscore load/save patched
;		- load/save game support added, game code for save game
;		  creation appears to be buggy
;		- most disk request patched/removed

; 18-Dec-2022	- work restarted
;		- Exec emulation code created, decided to use disk image
;		  instead of files, game works!

; 03-May-2012	- file loader patch fixed, works correctly now

; 02-May-2012	- fixed some patches, game works now (uses disk image)
;		- SMC fixed

; 29-Apr-2012	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	hardware/dmabits.i
	INCLUDE	hardware/intbits.i
	INCLUDE	exec/exec_lib.i
	INCLUDE	exec/io.i
	INCLUDE	exec/interrupts.i

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
	IFD	DEBUG
	dc.w	.dir-HEADER		; ws_CurrentDir
	ELSE
	dc.w	0			; ws_CurrentDir
	ENDC
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
	dc.b	"SOURCES:WHD_Slaves/Games/DragonsOfFlame",0
	ENDC

.name	dc.b	"Dragons of Flame",0
.copy	dc.b	"1989 Strategic Simulations Inc",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.00 (20.12.2022)",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Create save disk if needed
	lea	Save_Disk_Name(pc),a0
	bsr	File_Exists
	tst.l	d0
	bne.b	.Save_Disk_Exists	
	clr.l	$4.w
	bsr	Create_Save_Disk
.Save_Disk_Exists

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	moveq	#1,d0
	bsr	Set_Disk_Number

	; Load bootblock
	moveq	#0,d0
	move.l	#512*2,d1
	lea	$2000.w,a0
	bsr	Disk_Load

	move.l	a0,a5

	; Version check
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$419a,d0			; SPS 0985
	beq.b	.Is_Supported_Version

	; Unsupported version
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.Is_Supported_Version


	; Create Exec emulation code
	lea	(EXEC_LOCATION).w,a0
	move.l	a0,$4.w
	bsr	Create_Exec_Emulation

	; Patch bootblock
	lea	PL_BOOTBLOCK(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; Prepare environment for running boot code
	move.l	$4.w,a6
	lea	(IOSTD_LOCATION).w,a1

	; Run game
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
	dc.w	_LVOAddIntServer,AddIntServer_Emulation-.TAB
	dc.w	_LVOOpenDevice,Do_Nothing-.TAB
	dc.w	_LVOSendIO,Do_Nothing-.TAB	
	dc.w	_LVOAllocSignal,Do_Nothing-.TAB
	dc.w	_LVOFindTask,Do_Nothing-.TAB
	dc.w	_LVOCheckIO,Do_Nothing-.TAB
	dc.w	0			: end of tab


IOSTD_LOCATION	= $4000
DoIO_Emulation
	cmp.w	#CMD_WRITE,IO_COMMAND(a1)
	beq.b	.Save_Data

	cmp.w	#CMD_READ,IO_COMMAND(a1)
	bne.b	.unsupported_command

	movem.l	d0-a6,-(a7)
	move.l	IO_DATA(a1),a0
	move.l	IO_OFFSET(a1),d0
	move.l	IO_LENGTH(a1),d1
	bsr	Disk_Load
	movem.l	(a7)+,d0-a6

.unsupported_command
	rts

.Save_Data
	movem.l	d0-a6,-(a7)
	move.l	IO_LENGTH(a1),d0
	move.l	IO_OFFSET(a1),d1
	move.l	IO_DATA(a1),a1
	lea	Save_Disk_Name(pc),a0
	move.l	resload(pc),a2
	jsr	resload_SaveFileOffset(a2)
	movem.l	(a7)+,d0-a6
	rts

Save_Disk_Name	dc.b	"Disk.2",0
		CNOP	0,2


; d0.w: interrupt number
; a1.l: interrupt

AddIntServer_Emulation
	cmp.w	#INTB_PORTS,d0
	beq.b	.Add_Keyboard_Interrupt
	cmp.w	#INTB_COPER,d0
	bne.b	.Interrupt_Is_Not_Supported

	lea	Copper_Interrupt_Code(pc),a0
	move.l	IS_CODE(a1),(a0)
	move.l	IS_DATA(a1),4(a0)
	pea	Copper_Interrupt(pc)
	move.l	(a7)+,$6c.w
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_COPER,$dff09a

.Interrupt_Is_Not_Supported
	rts

.Add_Keyboard_Interrupt
	move.l	IS_CODE(a1),a1
	add.w	#$34e-$344,a1
	lea	KbdCust(pc),a0
	move.l	a1,(a0)
	rts

Copper_Interrupt
	movem.l	d0-a6,-(a7)
	move.l	Copper_Interrupt_Data(pc),a1
	bsr.b	.Run_Copper_Interrupt_Code
	movem.l	(a7)+,d0-a6
	move.w	#INTF_COPER,$dff09c
	move.w	#INTF_COPER,$dff09c
	rte

.Run_Copper_Interrupt_Code
	move.l	Copper_Interrupt_Code(pc),-(a7)

Do_Nothing
	rts

Copper_Interrupt_Code	dc.l	0
Copper_Interrupt_Data	dc.l	0

; ---------------------------------------------------------------------------

PL_BOOTBLOCK
	PL_START
	PL_SA	$e,$50
	PL_P	$138,.Patch_AEXE
	PL_END

.Patch_AEXE
	movem.l	d0-a6,-(a7)
	lea	PL_AEXE(pc),a0
	move.l	a6,a1
	bsr	Apply_Patches
	movem.l	(a7)+,d0-a6

	move.l	d0,a2
	move.l	d0,a4
	jmp	(a6)


; ---------------------------------------------------------------------------

PL_AEXE	PL_START
	PL_S	$1bc,4			; skip move.l $4.w,(a6) instruction
	PL_S	$36e,4			; skip CPU delay in keyboard interrupt
	PL_PS	$110,.Patch_Game
	PL_PS	$f0c,.Check_Directory
	PL_END

.Patch_Game
	movem.l	d0-a6,-(a7)
	lea	$1c(a0),a1
	lea	PL_GAME(pc),a0

	; Remove "disk in current drive." text
	move.l	a1,a2
	add.l	#$f7ae,a2
	moveq	#$f7c7-$f7ae-1,d0
.clear	move.b	#" ",(a2)+
	dbf	d0,.clear

	bsr	Apply_Patches
	movem.l	(a7)+,d0-a6

	move.l	a0,a5
	add.w	#$1c,a0
	rts


; This fixes the broken save game handling. The game doesn't properly
; initialise the save disk directory, this leads to data written to the
; wrong locations which in turn also kills the disk directory...

.Check_Directory
	lea	(IOSTD_LOCATION).w,a1
	move.l	IO_DATA(a1),a1
	cmp.w	#4,12(a1)		; check if first entry starts
					; at sector 4.
	rts

; ---------------------------------------------------------------------------

PL_GAME	PL_START
	PL_R	$1442			; disable protection check
	PL_PSS	$b3e6,Fix_DMA_Wait,2
	PL_PSS	$b416,Fix_DMA_Wait,2
	PL_P	$176,.Load_Highscores
	PL_P	$190,.Save_Highscores

	;PL_PSA	$4702,.Set_Save_Disk,$471c	; resume game
	;PL_PSA	$4666,.Set_Save_Disk,$4680	; save game
	;PL_PSA	$475a,.Set_Game_Disk,$4774	; game end

	PL_B	$d5a1,0				; Insert a Formatted
	PL_B	$d5b4,0				; Insert save game


	PL_PS	$1a8,.Load_Save_Game
	PL_P	$B532,.Save_Game
	PL_PS	$47f4,.Set_Game_Disk		; after loading save game
	PL_PS	$46e8,.Set_Game_Disk		; after saving save game
	PL_END


.Load_Save_Game
	bsr.b	.Set_Save_Disk
	moveq	#9,d0
	trap	#3
	rts

.Save_Game
	bsr.b	.Set_Save_Disk
	moveq	#17,d0
	trap	#3
	bsr.b	.Set_Game_Disk
	moveq	#0,d0			; no errors
	rts

.Set_Save_Disk
	moveq	#2,d0
	bra.w	Set_Disk_Number

.Set_Game_Disk
	moveq	#1,d0
	bra.w	Set_Disk_Number


; d1.l: file name
; a0.l: destination

.Load_Highscores
	move.l	a0,a1
	move.l	d1,a0
	bsr	File_Exists
	tst.b	d0
	beq.b	.no_highscore_file_found

	bsr	Load_File
	
.no_highscore_file_found
	rts

; a0.l: data
; d1.l: name
; d2.l: size
.Save_Highscores
	move.l	d2,d0
	move.l	a0,a1
	move.l	d1,a0
	bra.w	Save_File


; ---------------------------------------------------------------------------

Create_Save_Disk
	move.l	#524288,d0			; length
	moveq	#0,d1				; offset
	bsr.b	.save
	move.l	#901120-524288,d0		; length
	move.l	#524288,d1			; offset
.save	lea	Save_Disk_Name(pc),a0
	sub.l	a1,a1
	move.l	resload(pc),a2
	jmp	resload_SaveFileOffset(a2)

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


Fix_DMA_Wait
	move.l	d0,-(a7)
	moveq	#5,d0
	bsr.b	Wait_Raster_Lines
	move.l	(a7)+,d0
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

; d0.b: disk number

Set_Disk_Number
	move.l	a0,-(a7)
	lea	Disk_Number(pc),a0
	move.b	d0,(a0)
	move.l	(a7)+,a0
	rts


Disk_Number	dc.b	0
		dc.b	0


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


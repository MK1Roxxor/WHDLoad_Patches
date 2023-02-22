***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(     CRICKET CAPTAIN WHDLOAD SLAVE          )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            February 2023                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 21-Feb-2023	- save game support added
;		- another dongle check removed
;		- save disk request removed
;		- unused code removed
;		- patch is finished

; 19-Feb-2023	- work started
;		- dongle checks removed, OS stuff emulated, access fault
;		  fixed


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Hardware/dmabits.i
	INCLUDE	hardware/intbits.i
	INCLUDE	exec/exec_lib.i
	INCLUDE	exec/io.i
	INCLUDE	graphics/gfxbase.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

GAME_LOCATION	= $4000

	
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


.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Games/CricketCaptain"
	ENDC
	dc.b	"data",0

.name	dc.b	"Cricket Captain",0
.copy	dc.b	"1989 D & H Games",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.00 (22.02.2023)",0

Game_Name
	dc.b	"cap.prg",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load game code
	lea	Game_Name(pc),a0
	lea	(GAME_LOCATION).w,a1
	bsr	Load_File

	move.l	a1,a5

	; Version check
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$c2e5,d0			; SPS 1244
	beq.b	.Version_is_Supported

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.Version_is_Supported

	; Relocate game code
	move.l	a5,a0
	sub.l	a1,a1				; no tags
	jsr	resload_Relocate(a2)

	; Create Exec emulation code
	lea	(EXEC_LOCATION).w,a0
	move.l	a0,$4.w
	bsr	Create_Exec_Emulation

	; Patch game code
	lea	PL_GAME(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; Avoid access fault at offset $7f0, code sets d4.b (at $7d2)
	; and then uses this value to calculate the screen offset using
	; move.w d4,d0
	; mulu.w #40,d0
	; mulu instruction works with full words, so if the upper byte of
	; d4 contains trash, the result of the multiplication will be wrong,
	; this will lead to a wrongly calculated screen offset causing
	; an access fault.
	moveq	#0,d4

	; And run game
	jmp	(a5)
	



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
.Do_Nothing
	rts

.TAB	dc.w	_LVOForbid,.Do_Nothing-.TAB
	dc.w	_LVOPermit,.Do_Nothing-.TAB
	dc.w	0			: end of tab

; ---------------------------------------------------------------------------

PL_GAME	PL_START
	PL_SA	$e,$3c		; skip OS stuff
	PL_P	$600,.Read
	PL_P	$612,.Write
	PL_PS	$10086,.Check_File_Exists
	PL_R	$5ee		; disable Close()
	PL_R	$5dc		; disable Open()
	PL_P	$52,.Set_Keyboard_Routine
	PL_R	$e4

	; Disable dongle checks
	PL_R	$a82
	PL_R	$3ec2
	PL_R	$13cf0

	PL_R	$1340e		; disable save disk request
	PL_END

; d1.l: file name
; d2.l: destination
; d3.l: size
.Read	move.l	d1,a0
	addq.w	#4,a0		; skip "df0:"
	move.l	d2,a1
	bra.w	Load_File

; d1.l: file name
; d2.l: data
; d3.l: size

.Write	move.l	d1,a0
	addq.w	#4,a0		; skip "df0:"
	move.l	d2,a1
	move.l	d3,d0
	bra.w	Save_File

.Check_File_Exists
	move.l	d1,a0
	addq.w	#4,a0		; skip "df0:"
	bra.w	File_Exists


.Set_Keyboard_Routine
	pea	.Keyboard_Routine(pc)
	bra.w	Set_Keyboard_Custom_Routine

.Keyboard_Routine
	moveq	#0,d0
	move.b	RawKey(pc),d0
	moveq	#0,d1		; game uses move.b to set dbf loop counter...
	jmp	(GAME_LOCATION)+$ae.w


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

Set_Keyboard_Custom_Routine
	move.l	a0,-(a7)
	lea	KbdCust(pc),a0
	move.l	4(a7),(a0)
	move.l	(a7)+,a0
	rts


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


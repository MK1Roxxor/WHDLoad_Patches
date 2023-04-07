***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       DEMOLITION WHDLOAD_SLAVE             )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             April 2023                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 07-Apr-2023	- speed problems (main menu, game) fixed
;		- unlimited balls trainer added

; 02-Apr-2023	- work started

	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i


; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM


;============================================================================

CHIPMEMSIZE	= $80000	;size of chip memory
FASTMEMSIZE	= 0		;size of fast memory
NUMDRIVES	= 1		;amount of floppy drives to be configured
WPDRIVES	= %0000		;write protection of floppy drives

;BLACKSCREEN			;set all initial colors to black
;BOOTBLOCK			;enable _bootblock routine
BOOTDOS			;enable _bootdos routine
;BOOTEARLY			;enable _bootearly routine
;CBDOSLOADSEG			;enable _cb_dosLoadSeg routine
;CBDOSREAD			;enable _cb_dosRead routine
;CBKEYBOARD			;enable _cb_keyboard routine
;CACHE				;enable inst/data cache for fast memory with MMU
CACHECHIP			;enable inst cache for chip/fast memory
;CACHECHIPDATA			;enable inst/data cache for chip/fast memory
DEBUG				;add more internal checks
;DISKSONBOOT			;insert disks in floppy drives
DOSASSIGN			;enable _dos_assign routine
FONTHEIGHT	= 8		;enable 80 chars per line
HDINIT				;initialize filesystem handler
HRTMON				;add support for HrtMON
IOCACHE		= 1024		;cache for the filesystem handler (per fh)
;MEMFREE	= $200		;location to store free memory counter
;NEEDFPU			;set requirement for a fpu
POINTERTICKS	= 1		;set mouse speed
SEGTRACKER			;add segment tracker
SETKEYBOARD			;activate host keymap
SETPATCH			;enable patches from SetPatch 1.38
;SNOOPFS			;trace filesystem handler
;STACKSIZE	= 6000		;increase default stack
;TRDCHANGEDISK			;enable _trd_changedisk routine

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	;F10

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

slv_CurrentDir	dc.b	"data",0
slv_name	dc.b	"Demolition",0
slv_copy	dc.b	"1987 Anco",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"Debug (do not release!) "
		ENDC
		
		dc.b	"Version 1.00 (07.04.2023)",0
		dc.b	0

	IFGE slv_Version-17
slv_config	dc.b	"C1:B:Unlimited Balls",0
	ENDC
	EVEN


;============================================================================
; like a program from "startup-sequence" executed, full dos process,
; HDINIT is required, this will never called if booted from a diskimage, only
; works in conjunction with the virtual filesystem of HDINIT
; this routine replaces the loading and executing of the startup-sequence
;

	IFD BOOTDOS

_bootdos	
	move.l	_resload(pc),a2

	; Open dos.library
	lea	_dosname(pc),a1
	move.l	$4.w,a6
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,a6			; a6: dos base

	; Load game
	lea	Loader_Name(pc),a0
	move.l	a0,d1
	jsr	_LVOLoadSeg(a6)
	move.l	d0,d7			; d7: segment
	beq.b	Program_Error

	; Check version
	move.l	d7,d0
	lsl.l	#2,d0
	move.l	d0,a0
	
	add.w	#$6+4,a0
	moveq	#$6c-$6,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$E302,d0		; SPS 2712
	beq.b	.Version_is_Supported
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.Version_is_Supported


	; Patch game
	lea	PL_LOADER(pc),a0
	move.l	d7,a1
	jsr	resload_PatchSeg(a2)

	IFD DEBUG
	;set debug
		clr.l	-(a7)
		move.l	d7,-(a7)
		pea	WHDLTAG_DBGSEG_SET
		move.l	a7,a0
		jsr	(resload_Control,a2)
		add.w	#12,a7
	ENDC


	; Run game
	move.l	d7,d1
	lsl.l	#2,d1
	move.l	d1,a1

	lea	Arguments(pc),a0
	moveq	#Arguments_Length,d0

	jsr	4(a1)

	; Quit back to DOS
QUIT	pea	(TDREASON_OK).w
EXIT	move.l	_resload(pc),a2
	jmp	resload_Abort(a2)


Program_Error
	jsr	_LVOIoErr(a6)
	pea	Loader_Name(pc)
	move.l	d0,-(a7)
	pea	(TDREASON_DOSREAD).w
	jmp	resload_Abort(a2)


PL_LOADER
	PL_START
	PL_P	$A8A,.Fake_Protection_Check
	PL_PS	$92c,.Patch_And_Run_Game
	PL_END

.Fake_Protection_Check
	move.l	#$aa99,d0
	rts

.Patch_And_Run_Game
	movem.l	d0-a6,-(a7)
	lea	PL_GAME(pc),a0
	lea	$4204c,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	jmp	$4204c


PL_GAME	PL_START
	PL_P	$457a,.Fake_Protection_Check
	PL_B	$852,$60
	PL_AW	$5798+2,-1		; correct loop counter
	;PL_PS	$2528,.Fix_Access_Paddle_Speed
	PL_B	$2512,$60
	PL_SA	$594,$858	; skip "manual" protection

	PL_PS	$d96,.Fix_Speed_Main_Menu
	PL_PSS	$244c,.Fix_Speed_In_Game,2

	PL_IFC1
	PL_B	$2fbe,$4a
	PL_ENDIF
	PL_END

;.Fix_Access_Paddle_Speed
;	moveq	#16,d3
;	rts

.Fix_Speed_Main_Menu
	bsr.b	Wait_For_Vertical_Blank
	cmp.l	#$8000,d0
	rts

.Fix_Speed_In_Game
	bsr.b	Wait_For_Vertical_Blank
	move.l	$50c0(a4),d3		; score
	cmp.l	$50c4(a4),d3		; score for getting a new ball
	rts


.Fake_Protection_Check
	move.l	#$8895,d0
	rts

Wait_For_Vertical_Blank
.wait1	btst	#0,$dff005
	beq.b	.wait1
.wait2	btst	#0,$dff005
	bne.b	.wait2
	rts


Arguments	dc.b	"",10
Arguments_Length	= *-Arguments
Loader_Name	dc.b	"c/loader",0
		CNOP 0,4

	ENDC


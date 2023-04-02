***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*( SCARY MUTANT SPACE ALIENS FROM MARS WHDLOAD )*)---.---.  *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             March 2023                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 02-Apr-2023	- code cleaned up, unused and test code removed

; 01-Apr-2023	- "white wire" bug fixed using a different approach, the
;		  white wire object is now always set to appear in room 177

; 13-Mar-2023	- protection check when using terminal disabled
;		- issue with white wires fixed, the object can now be
;		  taken

; 12-Mar-2023	- work started
;		- protection removed, access fault fixed

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

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	;F10

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

slv_CurrentDir	dc.b	"data",0
slv_name	dc.b	"Scary Mutant Space Aliens from Mars",0
slv_copy	dc.b	"1989 ReadySoft Inc.",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"Debug (do not release!) "
		ENDC
		
		dc.b	"Version 1.00 (02.04.2023)",0
		dc.b	0

	IFGE slv_Version-17
slv_config	dc.b	"C1:B:Trainer",0
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

	; Assign game disks
	lea	Disk1_Name(pc),a0
	sub.l	a1,a1
	bsr	_dos_assign
	lea	Disk2_Name(pc),a0
	sub.l	a1,a1
	bsr	_dos_assign

	; Assign save disk
	lea	Save_Disk_Name(pc),a0
	sub.l	a1,a1
	bsr	_dos_assign

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
	
	add.w	#$8ee+4,a0
	moveq	#$912-$8ee,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$6f35,d0		; SPS 1549
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
	PL_PSA	$1ae,.Relocate_And_Patch_Game,$2d2
	PL_S	$2ea,4		; don't free memory
	PL_END


.Relocate_And_Patch_Game
	move.l	a0,-(a7)
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	resload_Relocate(a2)
	lea	PL_GAME(pc),a0
	move.l	(a7)+,a1
	jmp	resload_Patch(a2)


WHITE_WIRE_OBJECT_NUMBER	= $198
PL_GAME	PL_START

	; Fix for the "White Wire" problem
	PL_W	$1ffa2,WHITE_WIRE_OBJECT_NUMBER
	PL_PS	$95fe,.Set_White_Wire_Object_For_Room177
	PL_GA	$1ffa2,.Object_Address

	PL_SA	$8bba,$8c1e	; skip protection (load/save)
	PL_B	$71a4,$60	; disable protection check (terminal)

	PL_GA	$23c1a,.Address
	PL_PS	$1f9c,.Fix_Access_Fault

	PL_P	$66c,QUIT
	PL_END


.Set_White_Wire_Object_For_Room177
	move.l	#$c8,d3			; original code

	move.l	a0,-(a7)
	move.l	.Object_Address(pc),a0
	move.w	#WHITE_WIRE_OBJECT_NUMBER,(a0)
	move.l	(a7)+,a0
	rts
.Object_Address	dc.l	0




.Fix_Access_Fault
	tst.w	d0
	bpl.b	.ok
	moveq	#0,d0
.ok	add.l	.Address(pc),d0
	rts

.Address	dc.l	0




Loader_Name	dc.b	"loader",0
Disk1_Name	dc.b	"SMSADisk1",0
Disk2_Name	dc.b	"SMSADisk2",0
Save_Disk_Name	dc.b	"SMSA Save Disk",0
		CNOP 0,4

	ENDC


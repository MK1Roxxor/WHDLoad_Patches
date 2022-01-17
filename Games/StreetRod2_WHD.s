***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(         STREET ROD 2  WHDLOAD SLAVE        )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             January 2012                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 17-Jan-2022	- access fault fixed (Mantis 5429)

; 31-Jul-2018	- disabled test code removed from source

; 15-Apr-2018	- $bfe201 access fixed (direction for port A)

; 31-Jan-2012	- work started
;		- and finished some minutes later, manual protection
;		  has been completely disabled


	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
;	INCLUDE	lvo/dos.i

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;BOOTBLOCK
BOOTDOS
;BOOTEARLY
;CBDOSLOADSEG
;CBDOSREAD
;CBKEYBOARD
CACHE
;DEBUG
;DISKSONBOOT
DOSASSIGN
FONTHEIGHT     = 8
HDINIT
HRTMON
IOCACHE		= 1024
;MEMFREE	= $200
;NEEDFPU
POINTERTICKS   = 1
;SETPATCH
;STACKSIZE	= 6000
;TRDCHANGEDISK

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $59	; F10

;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================


slv_CurrentDir	IFD	DEBUG
		dc.b	"SOURCES:WHD_Slaves/StreetRod2/data",0
		ELSE
		dc.b	"data",0
		ENDC
slv_name	dc.b	"Street Rod 2",0
slv_copy	dc.b	"1991 California Dreams",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		dc.b	"Version 1.2 (17.01.2022)",0
		CNOP	0,4


	IFD BOOTDOS

_bootdos
	move.l	_resload(pc),a2

	move.l	#WCPUF_Exp_NCS,d0
	move.l	#WCPUF_Exp,d1
	jsr	resload_SetCPU(a2)

; open doslib
	lea	_dosname(pc),a1
	move.l	$4.w,a6
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,a6

; assigns
	lea	diskname(pc),a0
	sub.l	a1,a1
	bsr	_dos_assign

	lea	diskname(pc),a0
	addq.b	#1,7(a0)
	sub.l	a1,a1
	bsr	_dos_assign
	
; load game
	lea	gamename(pc),a0
	move.l	a0,d1
	jsr	_LVOLoadSeg(a6)
	move.l	d0,d7			; d7: segment
	beq.b	.error

; version check
	lsl.l	#2,d0
	addq.l	#4,d0
	move.l	d0,a0
	add.w	#$18,a0
	move.l	#$19c-$18,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$e6a0,d0
	beq.b	.ok
	pea	(TDREASON_WRONGVER).w
	jmp	resload_Abort(a2)
.ok

; patch
	lea	PL_GAME(pc),a0
	move.l	d7,a1
	jsr	resload_PatchSeg(a2)

; and run 
	lsl.l	#2,d7
	addq.l	#4,d7
	move.l	d7,a1
	lea	args(pc),a0
	moveq	#arglen,d0
	jsr	(a1)

	pea	(TDREASON_OK).w
	bra.b	.exit

.error	jsr	_LVOIoErr(a6)
	pea	gamename(pc)
	move.l	d0,-(a7)
	pea	(TDREASON_DOSREAD).w
.exit	jmp	resload_Abort(a2)







PL_GAME	PL_START
	PL_R	$39dd0			; completely disable manual protection
	PL_W	$1322e+2,%00000011	; fix port A direction settings
	PL_END


diskname	dc.b	"sr_disk1",0
gamename	dc.b	"Street_Rod",0
args	dc.b	0
arglen	= *-args

	ENDC


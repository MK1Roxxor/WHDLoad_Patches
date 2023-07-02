***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       WORLD CUP 90 WHDLOAD SLAVE           )*)---.---.   *
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

; 02-Jul-2023	- byte write to volume register fixed (Mantis issue #5283)

; 22-Jan-2012	- work started


	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	;INCLUDE	lvo/dos.i

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

;---------------------------------------------------------------------------*

	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= 0
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;BOOTBLOCK
;BOOTDOS
;BOOTEARLY
CBDOSLOADSEG
;CBDOSREAD
;CBKEYBOARD
CACHE
;DEBUG
DISKSONBOOT
;DOSASSIGN
FONTHEIGHT     = 8
;HDINIT
HRTMON
IOCACHE		= 1024
;MEMFREE	= $200
;NEEDFPU
POINTERTICKS   = 1
SETPATCH
;STACKSIZE	= 6000
;TRDCHANGEDISK

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	; F10

;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================


slv_CurrentDir	IFD	DEBUG
		dc.b	"SOURCES:WHD_Slaves/WorldCup90/",0
		ELSE
		dc.b	0
		ENDC
slv_name	dc.b	"World Cup 90",0
slv_copy	dc.b	"1990 Genias.",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		dc.b	"Version 1.1 (02.07.2023)",0
		CNOP	0,4

;============================================================================
; entry before any diskaccess is performed, no dos.library available

	IFD BOOTEARLY

_bootearly	blitz
		rts

	ENDC

;============================================================================
; bootblock from "Disk.1" has been loaded, no dos.library available

	IFD BOOTBLOCK

; A1 = ioreq ($2c+a5)
; A4 = buffer (1024 bytes)
; A6 = execbase

_bootblock	blitz
		jmp	(12,a4)

	ENDC


;============================================================================
; callback/hook which gets executed after each successful call to dos.LoadSeg
; can also be used instead of _bootdos
; if you use diskimages that is the way to patch the executables

; the following example uses a parameter table to patch different executables
; after they get loaded

	IFD CBDOSLOADSEG

; D0 = BSTR name of the loaded program as BCPL string
; D1 = BPTR segment list of the loaded program as BCPL pointer

_cb_dosLoadSeg
	lsl.l	#2,d0		; convert to bptr
	move.l	d0,a0
	move.b	(a0)+,d0	; length of name
	lea	.name(pc),a1
	bsr.b	.compare
	bne.b	.nope

	lsl.l	#2,d1
	move.l	d1,a5
	lea	$10+4(a5),a0	; +4 -> skip segment ptr
	move.w	#$1ac-$10,d0
	move.l	_resload(pc),a2
	jsr	resload_CRC16(a2)
	cmp.w	#$dd5c,d0
	beq.b	.ok
	pea	(TDREASON_WRONGVER).w
	jmp	resload_Abort(a2)


.ok	lea	PLGAME(pc),a0
	move.l	a5,a1
	move.l	_resload(pc),a2
	jmp	resload_Patch(a2)


.compare
.loop	move.b	(a0)+,d2
	or.b	#1<<5,d2		; convert to lower case
	cmp.b	(a1)+,d2
	bne.b	.nope
	subq.b	#1,d0
	bne.b	.loop
.nope	rts


.name	dc.b	"a",0			; lower case!

PLGAME	PL_START
	PL_PSS	$bce4,FixDMAWait,2	; fix DMA wait in replayer
	PL_P	$bea2,Fix_Volume_Write	; fix byte write to volume register
	PL_END


Fix_Volume_Write
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts

FixDMAWait
	move.l	d1,-(a7)
	moveq	#5-1,d1
.loop	move.b	$dff006,d0
.wait	cmp.b	$dff006,d0
	beq.b	.wait
	dbf	d1,.loop
	move.l	(a7)+,d1
	rts



	ENDC




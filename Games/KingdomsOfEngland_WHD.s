***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    KINGDOMS OF ENGLAND WHDLOAD SLAVE       )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              April 2013                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 30-Aug-2023	- special case code for "boot" file added
;		- disk change code removed, simply using 2 drives now
;		- patch is finished for now

; 29-Aug-2023	- stack problem in "musicplayer" fixed
;		- black screen in "bow" fixed

; 28-Aug-2023	- disk change works correctly now

; 15-Apr-2013	- work started

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i


;============================================================================

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= 0
NUMDRIVES	= 2
WPDRIVES	= %0000

BLACKSCREEN
BOOTBLOCK
;BOOTDOS
;BOOTEARLY
;CBDOSLOADSEG
;CBDOSREAD
;CACHE
DEBUG
DISKSONBOOT
;DOSASSIGN
FONTHEIGHT     = 8
;HDINIT
;HRTMON
IOCACHE		= 1024
;MEMFREE	= $200
;NEEDFPU
POINTERTICKS   = 1
;SETPATCH
STACKSIZE	= 6000
;TRDCHANGEDISK

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulPriv
slv_keyexit	= $59	;F10

;============================================================================

	INCLUDE	SOURCES:whdload/kick13.s

;============================================================================


slv_CurrentDir	dc.b	0
slv_name	dc.b	"Kingdoms of England",0
slv_copy	dc.b	"1989 Incognito Software",0
slv_info	dc.b	"installed and fixed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"DEBUG!!! "
		ENDC
		dc.b	"Version 1.00 (30.08.2023)",0
slv_config	dc.b	0

	CNOP	0,4

;============================================================================
; entry before any diskaccess is performed, no dos.library available

	IFD BOOTEARLY

_bootearly
	rts
	ENDC

;============================================================================
; bootblock from "Disk.1" has been loaded, no dos.library available

	IFD BOOTBLOCK

; A1 = ioreq ($2c+a5)
; A4 = buffer (1024 bytes)
; A6 = execbase

_bootblock
	movem.l	d0-a6,-(a7)
	cmp.l	#"KOE1",4(a4)
	bne.b	.wrongver

	lea	PLBOOTBLOCK(pc),a0
	move.l	a4,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)	
	movem.l	(a7)+,d0-a6
	jmp	12(a4)

.wrongver
	pea	(TDREASON_WRONGVER).w
	jmp	resload_Abort(a2)


PLBOOTBLOCK
	PL_START
	PL_PS	$84,.patchbase
	PL_END

.patchbase
	movem.l	d0-a6,-(a7)
	lea	PLBASE(pc),a0
	move.l	$28(a2),a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	move.l	#$400,d0		; original code
	rts

PLBASE	PL_START
	PL_PS	$7b4,.Patch_Part
	PL_END


; a0.l: name
; a1.: code

.Patch_Part
	move.l	$1a(a4),a0

	movem.l	d0-a6,-(a7)
	lea	.TAB(pc),a2
.check_all_entries
	movem.w	(a2)+,d0/d1
	lea	.TAB(pc,d0.w),a3
	move.l	a0,a4
.compare_name
	move.b	(a3)+,d0
	cmp.b	(a4)+,d0
	bne.b	.check_next_entry
	tst.b	(a3)
	bne.b	.compare_name

	; special case: file "2l" is called with name "boot" too
	cmp.b	#"b",(a0)
	bne.b	.no_boot
	cmp.b	#"o",1(a0)
	bne.b	.no_boot
	cmp.b	#"o",2(a0)
	bne.b	.no_boot
	cmp.b	#"t",3(a0)
	bne.b	.no_boot
	cmp.l	#$bfd100,$24+2(a1)
	bne.b	.Run_Part
.no_boot	

	lea	.TAB(pc,d1),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	bra.b	.Run_Part


.check_next_entry
	tst.w	(a2)
	bne.b	.check_all_entries

.Run_Part
	movem.l	(a7)+,d0-a6
	jmp	(a1)

.TAB	dc.w	.MusicPlayer-.TAB,PL_MUSICPLAYER-.TAB
	dc.w	.boot-.TAB,PL_BOOT-.TAB
	dc.w	.bow-.TAB,PL_BOW-.TAB
	dc.w	.start-.TAB,PL_START_FILE-.TAB
	dc.w	.main-.TAB,PL_MAIN-.TAB
	dc.w	0



.MusicPlayer	dc.b	"musicplayer",0
.bow		dc.b	"bow",0
.boot		dc.b	"boot",0
.start		dc.b	"start",0
.main		dc.b	"main",0
		CNOP	0,2

PL_MUSICPLAYER
	PL_START
	PL_PS	$2be0,Set_Stack
	PL_END

PL_BOW	PL_START
	PL_R	$2c8a		; disable waiting for music player signal
	PL_END
	

PL_BOOT	PL_START
	PL_SA	$0,$ea		; skip protection track check
	PL_END

PL_START_FILE
	PL_START
	PL_END

PL_MAIN	PL_START
	PL_END


Set_Stack
	sub.l	#STACKSIZE,d0
	addq.l	#8,d0
	rts


	ENDC


;============================================================================


***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/�|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(  CONFLICT MIDDLE EAST WHDLOAD SLAVE        )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                               May 2013                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 14-May-2013	- work started


	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	;INCLUDE	lvo/dos.i

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

MC68020	MACRO
	ENDM

;============================================================================

CHIPMEMSIZE	= 524288
FASTMEMSIZE	= 0
NUMDRIVES	= 1
WPDRIVES	= %0001

BLACKSCREEN
;BOOTBLOCK
BOOTDOS
;BOOTEARLY
;CBDOSLOADSEG
;CBDOSREAD
;CACHE
;DEBUG
;DISKSONBOOT
;DOSASSIGN
FONTHEIGHT	= 8
HDINIT
HRTMON
;INITAGA
;INIT_AUDIO
;INIT_GADTOOLS
INIT_LOWLEVEL
;INIT_MATHFFP
IOCACHE		= 1024
;JOYPADEMU
;MEMFREE	= $200
;NEEDFPU
NO68020
POINTERTICKS	= 1
;PROMOTE_DISPLAY
STACKSIZE	= 10000
;TRDCHANGEDISK

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	; F10

;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================


slv_CurrentDir	IFD	DEBUG
		dc.b	"SOURCES:WHD_Slaves/ConflictMiddleEast/data",0
		ELSE
		dc.b	"data",0
		ENDIF

slv_name	dc.b	"Conflict: The Middle East Political Simulator",0
slv_copy	dc.b	"1990 Virgin Mastertronic",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"Debug!!! "
		ENDC
		dc.b	"Version 1.00 (14.05.2013)",0
slv_config	dc.b	0
		CNOP	0,4

	IFD BOOTDOS

_bootdos
	lea	_dosname(pc),a1
	move.l	$4.w,a6
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,a6

	move.l	_resload(pc),a2
	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

	lea	.name(pc),a0
	bsr.b	.do
	bra.w	QUIT


.do	lea	PT_GAME(pc),a1
	bsr.b	.LoadAndPatch
.run	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	movem.l	d7/a6,-(a7)
	lea	.cmd(pc),a0
	moveq	#.cmdlen,d0
	jsr	4(a1)
	movem.l	(a7)+,d7/a6
	move.l	d7,d1
	jmp	_LVOUnLoadSeg(a6)

; a0.l: file name
; a1.l: patch table or 0 if no patching is required
; a6.l: dos base
; ---
; d7: segment

.LoadAndPatch
	move.l	a0,d6
	move.l	a1,a5
	move.l	a1,a4
	move.l	a0,d1
	jsr	_LVOLoadSeg(a6)
	move.l	d0,d7
	beq.b	.error

	move.l	a5,d0
	beq.b	.exit

.loop	movem.w	(a5)+,d0-d4	; checksum, start, end, hunk, patch list
	move.w	d0,d6
	beq.b	.found		; if checksum is 0 we don't care about it
	
; move to correct hunk
	move.l	d7,a0
	bra.b	.enter		; hunk 0 is special case
.gethunk
	move.l	(a0),a0
.enter	add.l	a0,a0
	add.l	a0,a0
	dbf	d3,.gethunk

	lea	4(a0,d1.w),a0
	moveq	#0,d0
	move.w	d2,d0
	sub.w	d1,d0
	move.l	_resload(pc),a2
	jsr	resload_CRC16(a2)
	cmp.w	d0,d6
	beq.b	.found
	tst.w	(a5)
	bne.b	.loop


; unsupported/unknown version
.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT


.found	lea	(a4,d4.w),a0
.patch	move.l	d7,a1
	move.l	_resload(pc),a2
	jsr	resload_PatchSeg(a2)
.exit	rts

.error	jsr	_LVOIoErr(a6)
	move.l	d6,-(a7)
	move.l	d0,-(a7)
	pea	(TDREASON_DOSREAD).w
	bra.b	EXIT


.cmd	dc.b	"",13,0			; fake command line
.cmdlen	= *-.cmd
.name	dc.b	"conflict",0
	CNOP	0,4


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	_resload(pc),a2
	jmp	resload_Abort(a2)


; format: checksum, start, end, hunk, offset to patch list
; start/end offsets are relative to the hunk start!
PT_GAME

; game
	dc.w	$3a96			; checksum
	dc.w	$1fc,$266		; start, end for CRC16
	dc.w	0			; hunk
	dc.w	PLGAME-PT_GAME

	dc.w	0			; end of tab


PLGAME	PL_START
	PL_END



TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
ATTNFLAGS	dc.l	0
		dc.l	TAG_END




	ENDC


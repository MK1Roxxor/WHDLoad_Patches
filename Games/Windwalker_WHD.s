***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       WINDWALKER WHDLOAD SLAVE             )*)---.---.   *
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

; 17-Sep-2024	- offset for stack fix was corrected

; 16-Sep-2024	- access fault fixed (issue #6547)
;		- stack size is now set
;		- unused code/data removed

; 03-May-2013	- work started


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
WPDRIVES	= %0000

;BLACKSCREEN
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
IOCACHE		= 16384
;JOYPADEMU
;MEMFREE	= $200
;NEEDFPU
NO68020
POINTERTICKS	= 1
;PROMOTE_DISPLAY
STACKSIZE	= 6000
;TRDCHANGEDISK

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	; F10

;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================


slv_CurrentDir	IFD	DEBUG
		dc.b	"SOURCES:WHD_Slaves/Windwalker/data",0
		ELSE
		dc.b	"data",0
		ENDIF

slv_name	dc.b	"Windwalker",0
slv_copy	dc.b	"1989 Origin",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"Debug!!! "
		ENDC
		dc.b	"Version 1.02 (17.09.2024)",0
slv_config		dc.b	0
		CNOP	0,4

	IFD BOOTDOS

_bootdos
	lea	_dosname(pc),a1
	move.l	$4.w,a6
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,a6

	lea	.name(pc),a0
	lea	PT_GAME(pc),a1
	bsr.b	.LoadAndPatch
	bsr.b	.run
	bra.w	QUIT

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
; a1.l: patch table
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
	jmp	resload_PatchSeg(a2)

.error	jsr	_LVOIoErr(a6)
	move.l	d6,-(a7)
	move.l	d0,-(a7)
	pea	(TDREASON_DOSREAD).w
	bra.b	EXIT


.cmd	dc.b	"",13,0			; fake command line
.cmdlen	= *-.cmd
.name	dc.b	"wind.ago",0
	CNOP	0,4


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	_resload(pc),a2
	jmp	resload_Abort(a2)


; format: checksum, start, end, hunk, offset to patch list
; start/end offsets are relative to the hunk start!
PT_GAME	dc.w	$519e			; checksum
	dc.w	$6,$a8			; start, end for CRC16
	dc.w	0			; hunk
	dc.w	PLGAME-PT_GAME		; SPS 1391

	dc.w	0			; end of tab

PLGAME	PL_START
	PL_B	$1cc6,$60		; skip manual protection
	PL_PS	$1ed36,.Set_Stack
	PL_PSS	$1eff4,.Fix_Access,2
	PL_END

.Fix_Access
	subq.w	#1,d0
	cmp.l	#$80000,a1
	bcc.b	.exit
.loop	move.b	(a1)+,(a0)+
	dbeq	d0,.loop
.exit	rts	


.Set_Stack
	sub.l	#STACKSIZE,d0
	addq.l	#8,d0
	rts


	ENDC


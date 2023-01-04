***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       BARD'S TALE 2 WHDLOAD SLAVE          )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            December 2013                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 04-Jan-2023	- DMA wait in replayer fixed (issue #5989)

; 29-Dec-2013	- to avoid problems the original Bard's Tale character
;		  data will be copied to its own directory instead of
;		  using the members directory

; 27-Dec-2013	- work started
;		- supports SPS 0046 version


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

BLACKSCREEN
;BOOTBLOCK
BOOTDOS
;BOOTEARLY
;CBDOSLOADSEG
;CBDOSREAD
;CACHE
;DEBUG
;DISKSONBOOT
DOSASSIGN
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
		dc.b	"SOURCES:WHD_Slaves/BardsTale2/"
		ENDC
		dc.b	"data",0

slv_name	dc.b	"Bard's Tale 2: The Destiny Knight",0
slv_copy	dc.b	"1988 Interplay",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"Debug!!! "
		ENDC
		dc.b	"Version 1.01 (04.01.2023)",0
name		dc.b	"bard",0
chardisk_name	dc.b	"destiny knight character disk",0
chardisk_dir	dc.b	"members",0

; for the original bards tale characters
chardiskbt_name	dc.b	"bards tale character disk",0
chardiskbt_dir	dc.b	"membersbt",0

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

; assign character disks
	lea	chardisk_name(pc),a0
	lea	chardisk_dir(pc),a1
	bsr	_dos_assign

; original Bard's Tale character dissk
	lea	chardiskbt_name(pc),a0
	lea	chardiskbt_dir(pc),a1
	bsr	_dos_assign

	lea	name(pc),a0
	lea	$20000,a1
	move.l	a1,a5
	jsr	resload_LoadFile(a2)
	move.l	a5,a0
	jsr	resload_CRC16(a2)
.nodecrypt

	lea	PL0046(pc),a4
	cmp.w	#$a673,d0		; SPS 0046
	beq.b	.ok

; unsupported/unknown version
.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT



.ok	lea	name(pc),a0
	move.l	a0,d6
	move.l	a0,d1
	jsr	_LVOLoadSeg(a6)
	move.l	d0,d7
	beq.b	.error

	move.l	a4,a0
	move.l	d7,a1
	jsr	resload_PatchSeg(a2)
	
	bsr.b	.run
	bra.b	QUIT

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


.error	jsr	_LVOIoErr(a6)
	move.l	d6,-(a7)
	move.l	d0,-(a7)
	pea	(TDREASON_DOSREAD).w
	bra.b	EXIT

.cmd	dc.b	"",13,0			; fake command line
.cmdlen	= *-.cmd
	CNOP	0,4


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	_resload(pc),a2
	jmp	resload_Abort(a2)


; SPS 0046
PL0046	PL_START
	PL_PS	$38b02,Fix_DMA_Wait

	PL_END



Fix_DMA_Wait
	moveq	#5-1,d0

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


TAGLIST	dc.l	WHDLTAG_ATTNFLAGS_GET
	dc.l	0
	dc.l	TAG_END









	ENDC

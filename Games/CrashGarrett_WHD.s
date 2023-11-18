***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       CRASH GARRETT WHDLOAD SLAVE          )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            February 2013                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 18-Nov-2023	- patch is now NTSC compatible

; 24-Feb-2013	- graphics problems fixed by calling _LVOWaitBlit after
;		  _LVOScrollRaster was called
;		- strange "wait for key" after intro disabled, why was
;		  it even implemented in the first place?


; 23-Feb-2013	- work started
;		- CPU dependent timing loops fixed


	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

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
CACHE
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
		dc.b	"SOURCES:WHD_Slaves/CrashGarrett/data",0
		ELSE
		dc.b	"data",0
		ENDIF

slv_name	dc.b	"Crash Garrett",0
slv_copy	dc.b	"1988 ERE Informatique/Infogrames",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"DEBUG!!! "
		ENDC
		dc.b	"Version 1.1 (18.11.2023)",0
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


; load game
.dogame	moveq	#$28,d0
	move.w	#$5a-$28,d1
	lea	.game(pc),a0
	lea	PT_GAME(pc),a1
.go	bsr.b	.LoadAndPatch
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

; d0.w: start offset for version check
; d1.w: length for version check
; a0.l: file name
; a1.l: patch table
; a6.l: dos base
; ---
; d7: segment

.LoadAndPatch
	move.w	d0,d3
	moveq	#0,d4
	move.w	d1,d4

	move.l	a0,d6
	move.l	a1,a5
	move.l	a0,d1
	jsr	_LVOLoadSeg(a6)
	move.l	d0,d7
	beq.b	.error

	move.l	d7,a0
	add.l	a0,a0
	add.l	a0,a0
	lea	4(a0,d3.w),a0
	move.l	d4,d0
	move.l	_resload(pc),a2
	jsr	resload_CRC16(a2)
	move.w	d0,d2

; d0: checksum
	move.l	a5,a0
.find	move.w	(a0)+,d0
	beq.b	.wrongver
	cmp.w	#-1,d0
	bmi.b	.out
	cmp.w	d0,d2
	beq.b	.found
	addq.w	#2,a0
	bra.b	.find

; unsupported/unknown version
.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT


.found	add.w	(a0),a5



	move.l	a5,a0
.patch	move.l	d7,a1
	move.l	_resload(pc),a2
	jsr	resload_PatchSeg(a2)
.out	rts

.error	jsr	_LVOIoErr(a6)
	move.l	d6,-(a7)
	move.l	d0,-(a7)
	pea	(TDREASON_DOSREAD).w
	bra.b	EXIT


.cmd	dc.b	0			; fake command line
.cmdlen	= *-.cmd
.game	dc.b	"crashang",0
	CNOP	0,4


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	_resload(pc),a2
	jmp	resload_Abort(a2)


; format: checksum, offset to patch list
PT_GAME	dc.w	$3636,PLGAME-PT_GAME
	dc.w	0			; end of tab

PLGAME	PL_START
	PL_PS	$41be,.waitTOF		; fix timing in intro
	PL_SA	$41be+6,$41c8
	PL_PSS	$44f0,FixDMAWait,4	; fix DMA wait in replayer
	PL_P	$e1a,.waitTOF2
	PL_PSS	$4e8,.fixdbf,2
	PL_PSS	$1cc8,FixDMAWait,2
	PL_PSS	$1e16,FixDMAWait,2
	PL_PSS	$2346,.fxdbf2,2

	PL_PS	$f66,.scroll		; wait for blitter after scrolling
	PL_PS	$fd4,.scroll		; wait for blitter after scrolling
	PL_PS	$1062,.scroll		; wait for blitter after scrolling
	PL_PS	$10d6,.scroll		; wait for blitter after scrolling

	PL_PS	$2ae0,.fixdelay		; fix delay in sample player
	PL_SA	$40,$44			; don't wait for key after intro

	PL_END

; d5.l: delay value
.fixdelay
	movem.l	d0/d5,-(a7)
	divu.w	#5,d5
.sloop	move.b	$dff006,d0
.swait	cmp.b	$dff006,d0
	beq.b	.swait
	dbf	d5,.sloop


	movem.l	(a7)+,d0/d5
	rts



.scroll	moveq	#0,d1
	jsr	_LVOScrollRaster(a6)
	jmp	_LVOWaitBlit(a6)	


.fxdbf2	bsr	FixDMAWait
	bra.w	FixDMAWait

.fixdbf	move.w	#218,d0
.loop	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait	
	dbf	d0,.loop
	rts


.waitTOF2
.wait1	btst	#0,$dff004+1
	beq.b	.wait1
.wait2	btst	#0,$dff004+1
	bne.b	.wait2
	
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts

.waitTOF
	move.l	$4.w,a6
	move.l	$9c(a6),a6
	jmp	_LVOWaitTOF(a6)


FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d0
.loop	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait
	dbf	d0,.loop
	movem.l	(a7)+,d0/d1
	rts



TAGLIST	dc.l	TAG_END


	ENDC


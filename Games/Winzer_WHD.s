***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(          WINZER WHDLOAD SLAVE              )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                                May 2013                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 15-Mar-2020	- some version had a wrong "fix read from $dff006" fix
;		  (PL_L offset,-2 instead of the correct PL_AL offset,-2)

; 17-Jan-2016	- support for CDTV version added, requested by Ingo Schmitz
;		- all load/save to RAM options removed, saves are always
;		  done to df0:
;		- Lexikon is supported too
;		- all versions: long read from $dff006 fixed

; 21-May-2013	- work started

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
FASTMEMSIZE	= 524288
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN		; removed because of CDTV version
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
IOCACHE		= 8192
;JOYPADEMU
;MEMFREE	= $200
;NEEDFPU
NO68020
POINTERTICKS	= 1
;PROMOTE_DISPLAY
STACKSIZE	= 18000
;TRDCHANGEDISK

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_EmulPriv|WHDLF_Examine
slv_keyexit	= $59	; F10

;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================


slv_CurrentDir	IFD	DEBUG
		dc.b	"SOURCES:WHD_Slaves/Winzer/data_CDTV",0
		ELSE
		dc.b	"data",0
		ENDIF

slv_name	dc.b	"Winzer",0
slv_copy	dc.b	"1991 Starbyte",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"Debug!!! "
		ENDC
		dc.b	"Version 1.02 (15.03.2020)",0
slv_config	dc.b	0
df0		dc.b	"df0",0
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

; assign disk
	lea	df0(pc),a0
	sub.l	a1,a1
	bsr	_dos_assign

	lea	.name(pc),a0
	lea	PT_GAME(pc),a1
	bsr.b	.load
	bra.w	QUIT


.load	bsr.b	.LoadAndPatch
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1


; run "Lexikon" if found (CDTV version)
	movem.l	d0-a6,-(a7)
	bsr	RunLexikon
	movem.l	(a7)+,d0-a6

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


.cmd		dc.b	"DEBUG",13,0		; fake command line
.cmdlen		= *-.cmd
.name		dc.b	"Winzer",0
	CNOP	0,4


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	_resload(pc),a2
	jmp	resload_Abort(a2)


; format: checksum, start, end, hunk, offset to patch list
; start/end offsets are relative to the hunk start!
PT_GAME	dc.w	$2410			; checksum
	dc.w	$6b4,$936		; start, end for CRC16
	dc.w	0			; hunk
	dc.w	PLGAME-PT_GAME		; v1.13, SPS 1759

	dc.w	$db9a			; checksum
	dc.w	$488,$68e		; start, end for CRC16
	dc.w	0			; hunk
	dc.w	PLGAME114-PT_GAME	; v1.14, SPS 1760

	dc.w	$40da			; checksum
	dc.w	$696,$918		; start, end for CRC16
	dc.w	0			; hunk
	dc.w	PLGAME100-PT_GAME	; v1.00

	dc.w	$3447			; checksum
	dc.w	$6b4,$936		; start, end for CRC16
	dc.w	0			; hunk
	dc.w	PLGAME11e-PT_GAME	; v1.1e

	dc.w	$56d9			; checksum
	dc.w	$6c8,$948		; start, end for CRC16
	dc.w	0			; hunk
	dc.w	PLGAMECDTV-PT_GAME	; v1.15 CDTV
	dc.w	0			; end of tab

PLGAME	PL_START
	;PL_W	$466a,$4e71		; disable protection check
	;PL_SA	$458a,$4678		; completely skip protection check
	PL_B	$4574,$60		; completely skip protection check
	PL_SA	$43e2,$43fe		; skip ROM access
	PL_AL	$332ea+2,-2		; fix long read from $dff006
	PL_END


PLGAME114
	PL_START
	;PL_SA	$4234,$4326		; completely skip protection check
	PL_B	$421e,$60		; completely skip protection check
	PL_SA	$408a,$40a6		; skip ROM access
	PL_AL	$32db6+2,-2		; fix long read from $dff006
	PL_END

PLGAME100
	PL_START
	;PL_SA	$4482,$4570		; completely skip protection check
	PL_B	$446c,$60		; completely skip protection check
	PL_SA	$42da,$42f6		; skip ROM access
	PL_AL	$329a6+2,-2		; fix long read from $dff006
	PL_END

PLGAME11e
	PL_START
	;PL_SA	$460a,$46f8		; completely skip protection check
	PL_B	$45f4,$60		; completely skip protection check
	PL_SA	$4462,$447e		; skip ROM access
	PL_AL	$33142+2,-2		; fix long read from $dff006
	PL_END

PLGAMECDTV
	PL_START
	PL_SA	$3cf4,$3d10		; skip ROM access
	PL_AL	$32996+2,-2		; fix long read from $dff006

	PL_W	$2549a,$4e71		; always use df0: to save game
	PL_W	$25626,$4e71		; always use df0: to load game

	PL_S	$3892,4			; disable "load from RAM" option
	PL_AW	$38ae+2,-1		; one option less
	PL_B	$2721,0			; only write "Spiel laden"

	
	PL_S	$15a72,4		; disable "save to RAM" option
	PL_AW	$15a76+2,-1		; 1 option less
	PL_B	$12823,0		; only write "Spiel speichern"
	PL_END


; a6.l: DOSBase
RunLexikon
	lea	.lexikon(pc),a0
	move.l	a0,a5
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nolexikon

	move.l	a5,d1
	jsr	_LVOLoadSeg(a6)
	move.l	d0,d7
	beq.b	.nolexikon

	movem.l	d7/a6,-(a7)
	lsl.l	#2,d7
	move.l	d7,a1
	lea	.cmd(pc),a0
	moveq	#.cmdlen,d0
	jsr	4(a1)
	movem.l	(a7)+,d7/a6
	move.l	d7,d1
	jsr	_LVOUnLoadSeg(a6)
	

.nolexikon
	rts

.lexikon	dc.b	"Lexikon",0
.cmd		dc.b	" ",13,0		; fake command line
.cmdlen		= *-.cmd
		CNOP	0,2


TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
		dc.l	0
		dc.l	TAG_END

	ENDC


***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
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

; 04-Jul-2023	- unused code removed
;		- code clean-up

; 03-Jul-2023	- support for another version added ("Protec" protected)
;		- routine to detect and patch the supported versions
;		  partly rewritten

; 14-May-2013	- work started


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
		dc.b	"SOURCES:WHD_Slaves/ConflictMiddleEast/"
		ENDIF
		dc.b	"data",0

slv_name	dc.b	"Conflict: The Middle East Political Simulator",0
slv_copy	dc.b	"1990 Virgin Mastertronic",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"Debug!!! "
		ENDC
		dc.b	"Version 1.01 (04.07.2023)",0
slv_config	dc.b	0
		CNOP	0,4

	IFD BOOTDOS

_bootdos
	lea	_dosname(pc),a1
	move.l	$4.w,a6
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,a6

	move.l	_resload(pc),a2

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
; a1.l: patch table
; a2.l: resload
; a6.l: dos base
; ---
; d7: segment

.LoadAndPatch
	move.l	a1,d6

	; Load executable
	move.l	a0,d1
	move.l	a0,d2			; save file name for error handling
	jsr	_LVOLoadSeg(a6)
	move.l	d0,d7
	beq.b	.File_Error

	; Detect version and apply patches
	move.l	d6,a1

.parse_all_entries
	move.l	PT_START_OFFSET(a1),d1
	bsr.b	.Get_File_Data_For_CRC16
	move.l	PT_END_OFFSET(a1),d0
	sub.l	PT_START_OFFSET(a1),d0
	move.l	a1,-(a7)
	jsr	resload_CRC16(a2)
	move.l	(a7)+,a1
	cmp.w	PT_CHECKSUM(a1),d0
	beq.b	.Supported_Version_Found
	add.w	#PT_ENTRY_SIZE,a1
	tst.w	(a1)
	bne.b	.parse_all_entries

	; No supported version found
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT

.Supported_Version_Found
	move.l	d6,a0
	add.w	PT_PATCH_LIST(a1),a0
	move.l	d7,a1
	jmp	resload_PatchSeg(a2)


; d7.l: segment
; d1.l: offset
; ----
; a0.l: file data pointer for CRC16

.Get_File_Data_For_CRC16
	move.l	d7,d0
.parse_hunks
	lsl.l	#2,d0
	move.l	d0,a5
	move.l	-4(a5),d2	; hunk length
	subq.l	#2*4,d2		; header consists of 2 longs
	move.l	(a5),d0		; next hunk

	cmp.l	d1,d2
	bge.b	.correct_hunk_found

	sub.l	d2,d1
	bra.b	.parse_hunks


.correct_hunk_found
	lea	4(a5,d1.l),a0
	rts


; d2.l: file name
.File_Error
	jsr	_LVOIoErr(a6)
	move.l	d2,-(a7)
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


; format: checksum, start, end, offset to patch list
PT_GAME

	; V1, unprotected
	dc.w	$2c0f			; checksum
	dc.l	$283d0,$283f5		; start, end for CRC16
	dc.w	PLGAME-PT_GAME		; offset to patch list

	; V2 (Christoph Gleisberg, "Protec" protected)
	dc.w	$2c0f			; checksum
	dc.l	$28698,$286bd		; start, end for CRC16
	dc.w	PLGAME_V2-PT_GAME	; offset to patch list

	dc.w	0			; end of table


		RSRESET
PT_CHECKSUM	rs.w	1
PT_START_OFFSET	rs.l	1
PT_END_OFFSET	rs.l	1
PT_PATCH_LIST	rs.w	1		; relative to start of patch table
PT_ENTRY_SIZE	rs.b	0


PLGAME	PL_START
	PL_END

PLGAME_V2
	PL_START
	PL_R	$25488			; disable proection check
	PL_END



	ENDC


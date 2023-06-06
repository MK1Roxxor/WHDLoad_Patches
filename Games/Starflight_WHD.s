***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        STARFLIGHT WHDLOAD SLAVE            )*)---.---.   *
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

; 06-Jun-2023	- protection properly disabled

; 05-Sep-2018	- DOSASSIGN define removed, not needed

; 29-Apr-2013	- work started


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
STACKSIZE	= 6000
;TRDCHANGEDISK
CBDOSREAD			;enable _cb_dosRead routine

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	; F10

;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================


slv_CurrentDir	IFD	DEBUG
		dc.b	"SOURCES:WHD_Slaves/Starflight/data",0
		ELSE
		dc.b	"data",0
		ENDIF

slv_name	dc.b	"Starflight",0
slv_copy	dc.b	"1989 Electronic Arts",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"Debug!!! "
		ENDC
		dc.b	"Version 1.01 (06.06.2023)",0

slv_config		dc.b	0
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
.name	dc.b	"starflt.ago",0
	CNOP	0,4


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	_resload(pc),a2
	jmp	resload_Abort(a2)


; format: checksum, start, end, hunk, offset to patch list
; start/end offsets are relative to the hunk start!
PT_GAME	dc.w	$bfcd			; checksum
	dc.w	$30,$76			; start, end for CRC16
	dc.w	0			; hunk
	dc.w	PLGAME-PT_GAME		; SPS 855

	dc.w	0			; end of tab


PLGAME	PL_START
	PL_PS	$1764a,.stack
	;PL_R	$1c850			; disable interstel police warning
	PL_END


.stack	sub.l	#STACKSIZE,d0
	addq.l	#8,d0
	rts

TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
		dc.l	0
		dc.l	TAG_END



;---------------
; IN:	D0 = ULONG bytes read
;	D1 = ULONG offset in file
;	A0 = CPTR name of file
;	A1 = APTR memory buffer
; OUT:	-

_cb_dosRead
		move.l	a0,a2
.1		tst.b	(a2)+
		bne.b	.1
		lea	.name(pc),a3
		move.l	a3,a4
.2		tst.b	(a4)+
		bne.b	.2
		sub.l	a4,a2
		add.l	a3,a2		;first char to check
.4		move.b	(a2)+,d2
		cmp.b	#"A",d2
		blo.b	.3
		cmp.b	#"Z",d2
		bhi.b	.3
		add.b	#$20,d2
.3		cmp.b	(a3)+,d2
		bne.b	.no
		tst.b	d2
		bne.b	.4

	;check position
		move.l	d0,d2
		add.l	d1,d2
		lea	.data(pc),a2
		moveq	#0,d3
.next		movem.l	(a2)+,d3-d4
		tst.l	d3
		beq.b	.no
		cmp.l	d1,d3
		blo.b	.next
		cmp.l	d2,d3
		bhs.b	.next
		sub.l	d1,d3
		move.w	d4,(a1,d3.l)
		bra.b	.next

.no		rts

.name		dc.b	"starflt.ago",0	;lower case!
	EVEN
.data		dc.l	$39f4c,$6012
		dc.l	0




	ENDC


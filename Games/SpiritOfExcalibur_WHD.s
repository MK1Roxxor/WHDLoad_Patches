***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   SPIRIT OF EXCALIBUR WHDLOAD SLAVE        )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            September 2018                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 26-Sep-2018	- Allocate/Release patches disabled, fixes access fault
;		  reported in Mantis issue #3965

; 15-Sep-2018	- Examine/ExNext patched to use WHDLoad functions, intro
;		  and game work correclty now from HD
;		- support for SPS 1582/1583 added
;		- POTGO bug fixed (move.w $c00.w,$dff034 ->
;		  move.w #$c00,$dff034)

; 14-Sep-2018	- work started



	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	;INCLUDE	lvo/dos.i


; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM

MC68020	MACRO
	ENDM

;============================================================================

CHIPMEMSIZE	= 524288
FASTMEMSIZE	= 524288
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;BOOTBLOCK
BOOTDOS
;BOOTEARLY
;CBDOSLOADSEG
;CBDOSREAD
CACHE
DEBUG
;DISKSONBOOT
;DOSASSIGN
FONTHEIGHT	= 8
HDINIT
;HRTMON
;INITAGA
;INIT_AUDIO
;INIT_GADTOOLS
;INIT_LOWLEVEL
;INIT_MATHFFP
IOCACHE		= 9300
;JOYPADEMU
;MEMFREE	= $200
;NEEDFPU
;NO68020
POINTERTICKS	= 1
;PROMOTE_DISPLAY
STACKSIZE	= 30000
;TRDCHANGEDISK

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $59	; F10


;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================


slv_CurrentDir	IFD	DEBUG
		dc.b	"SOURCES:WHD_Slaves/SpiritOfExcalibur/"
		ENDC
		dc.b	"data",0

slv_name	dc.b	"Spirit of Excalibur",0
slv_copy	dc.b	"1991 Virgin",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"DEBUG!!! "
		ENDC
		dc.b	"Version 1.01 (26.09.2018)",0
slv_config	dc.b	"C1:B:Skip Intro"
		dc.b	0
		CNOP	0,4

DOSbase	dc.l	0

TAGLIST		dc.l	WHDLTAG_CUSTOM1_GET
SKIPINTRO	dc.l	0
		dc.l	TAG_DONE

	IFD BOOTDOS

_bootdos
	lea	.saveregs(pc),a0
	movem.l	d1-d3/d5-d7/a1-a2/a4-a6,(a0)

	lea	_dosname(pc),a1
	move.l	$4.w,a6
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,a6
	lea	DOSbase(pc),a0
	move.l	d0,(a0)
	move.l	_resload(pc),a2


	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


	move.l	SKIPINTRO(pc),d0
	bne.b	.dogame
	lea	.intro(pc),a0
	bsr.b	.run

; load game
.dogame	lea	.game(pc),a0
	bsr.b	.run

	bra.w	QUIT


.run	lea	PT_GAME(pc),a1
	bsr.w	.LoadAndPatch
	tst.l	d7
	beq.b	.nofile

	move.l	a6,-(a7)
	sub.l	a1,a1
	move.l	$4.w,a6
	jsr	_LVOFindTask(a6)
	move.l	d0,a0
	move.l	d0,a2
	
	move.l	pr_CLI(a0),d0
	lsl.l	#2,d0			; BPTR -> APTR
	move.l	d0,a0
	move.l	d7,cli_Module(a0)
	move.l	(a7)+,a6

	move.l	d7,d1
	moveq	#.arglen,d0
	lea	.args(pc),a0
	movem.l	d7/a6,-(a7)		; save segment/dosbase
	bsr.b	.call
	movem.l	(a7)+,d1/a6

	jsr	_LVOUnLoadSeg(a6)
.nofile	rts	


; d0.l: argument length
; d1.l: segment
; a0.l: argument (command line)
; a6.l: dosbase
.call	lea	.callregs(pc),a1
	movem.l	d2-d7/a2-a6,(a1)
	move.l	(a7)+,11*4(a1)
	move.l	d0,d4
	lsl.l	#2,d1
	move.l	d1,a3
	move.l	a0,a4		; save command line
; create longword aligned copy of args
	lea	.callargs(pc),a1
	move.l	a1,d2
.copy	move.b	(a0)+,(a1)+
	subq.w	#1,d0
	bne.b	.copy


; set args
	jsr	_LVOInput(a6)
	lsl.l	#2,d0		; BPTR -> APTR
	move.l	d0,a0
	lsr.l	#2,d2		; APTR -> BPTR
	move.l	d2,fh_Buf(a0)
	clr.l	fh_Pos(a0)
	move.l	d4,fh_End(a0)
; call
	move.l	d4,d0
	move.l	a4,a0
	movem.l	.saveregs(pc),d1-d3/d5-d7/a1-a2/a4-a6

	jsr	4(a3)

; return
	movem.l	.callregs(pc),d2-d7/a2-a6
	move.l	.callrts(pc),a0
	jmp	(a0)





; a0.l: file name
; a1.l: patch table or 0 if no patching is needed
; a6.l: dos base
; ---
; d7: segment

.LoadAndPatch
	move.l	_resload(pc),a2	

	move.l	a1,a5		; a5: will contain start of entry in patch table
	move.l	a1,a3		; a3: start of patch table

	move.l	a0,d6		; save file name for IoErr
	move.l	a0,d1
	jsr	_LVOLoadSeg(a6)
	move.l	d0,d7		; d7: segment
	beq.b	.out

	move.l	a5,d6
	beq.b	.out
	bsr.b	.CRC16		; check all entries in patch table
	beq.b	.found

; unsupported/unknown version
.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.found	add.l	3*4(a5),a3	; a4: patch list



	move.l	a3,a0
.patch	move.l	d7,a1
	;move.l	_resload(pc),a2
	jsr	resload_PatchSeg(a2)
.out	rts

.error	jsr	_LVOIoErr(a6)
	move.l	d6,-(a7)
	move.l	d0,-(a7)
	pea	(TDREASON_DOSREAD).w
	bra.w	EXIT


; a5.l: patch table
; d7.l: segment
; ----
; zflg: result, if set: entry with matching checksum found
; a5.l: ptr to start of entry in patch table

.CRC16	move.l	d7,d6
	move.l	(a5),d0		; offset
	bmi.b	.notfound

; find start offset in file
.getoffset
	lsl.l	#2,d6
	move.l	d6,a4
	move.l	-4(a4),d1	; hunk length
	subq.l	#2*4,d1		; header consists of 2 longs
	move.l	(a4),d6
	cmp.l	d0,d1
	bge.b	.thishunk
	sub.l	d1,d0
	bra.b	.getoffset

.thishunk
	lea	4(a4,d0.l),a0
	move.l	4(a5),d0	; end offset
	sub.l	(a5),d0		; -start offset = length for CRC16
	jsr	resload_CRC16(a2)
	move.l	2*4(a5),d1
	IFD	DEBUG
	move.w	d0,a0
	ENDC
	cmp.w	d0,d1
	beq.b	.entry_found
	add.w	#4*4,a5		; next entry in tab
	bra.b	.CRC16

.entry_found
.notfound
	rts

.intro	dc.b	"intro",0
.game	dc.b	"excal",0
.args	dc.b	"",10		; must be LF terminated
.arglen	= *-.args
	CNOP	0,4

.saveregs	ds.l	11
.saverts	dc.l	0
.dosbase	dc.l	0
.callregs	ds.l	11
.callrts	dc.l	0
.callargs	ds.b	208


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	_resload(pc),a2
	jmp	resload_Abort(a2)


	CNOP 0,4


; format: start, end, checksum, offset to patch list
PT_GAME	dc.l	$c7d2,$c7df,$b8ad,PLINTRO_2852-PT_GAME
	dc.l	$643c,$645b,$02b1,PLGAME_2852-PT_GAME	; SPS 2852

	dc.l	$dbc0,$dbcd,$b8ad,PLINTRO_1586-PT_GAME
	dc.l	$1eb9a,$1ebb9,$962c,PLGAME_1586-PT_GAME	; SPS 1586/2853

	dc.l	-1					; end of tab


PLINTRO_1586
	PL_START
	PL_PS	$bdc0,SetStack
	PL_PSS	$530a,FixRMB,2

	PL_P	$c914,Examine
	PL_P	$c922,ExNext

; V1.01
	PL_SA	$6f20,$6f44		; skip Allocate/Release patches
	PL_END


PLGAME_1586
	PL_START
	PL_PS	$2a938,SetStack
	PL_B	$2e372,1		; set fCopyProtectPassed
	PL_PSS	$24456,FixRMB,2

	PL_P	$2b48c,Examine
	PL_P	$2b49a,ExNext

; V1.01
	PL_SA	$25e86,$25eaa		; skip Allocate/Release patches
	PL_END


PLINTRO_2852
	PL_START
	PL_PS	$b2f4,SetStack
	PL_PSS	$510a,FixRMB,2

	PL_P	$be48,Examine
	PL_P	$be56,ExNext

; V1.01
	PL_SA	$6b3a,$6b5e		; skip Allocate/Release patches
	PL_END


PLGAME_2852
	PL_START
	PL_PS	$2a86a,SetStack
	PL_B	$2e2a0,1		; set fCopyProtectPassed
	PL_PSS	$24322,FixRMB,2

	PL_P	$2b3be,Examine
	PL_P	$2b3cc,ExNext

; V1.01
	PL_SA	$25d52,$25d76		; skip Allocate/Release patches
	PL_END

FixRMB	move.w	#$c00,$dff034
	rts

ExNext	move.l	d2,a0
	move.l	_resload(pc),a6
	jmp	resload_ExNext(a6)

Examine	lea	.file(pc),a0
	move.l	d2,a1
	move.l	_resload(pc),a6
	jmp	resload_Examine(a6)

.file	dc.b	0,0			; -> current dir





SetStack
	sub.l	#STACKSIZE,d0
	addq.l	#8,d0
	rts

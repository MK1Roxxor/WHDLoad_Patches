***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   BUNDESLIGA MANAGER PRO. WHDLOAD SLAVE    )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             August 2018                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 07-Sep-2018	- support for V2.0 added, thanks to Irek Kloska for the
;		  images
;		- this version seems to be unprotected

; 31-Aug-2018	- support for V1.03 added

; 22-Aug-2018	- access faults fixed

; 21-Aug-2018	- work restarted from scratch, old source seems to be lost



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
DOSASSIGN
FONTHEIGHT	= 8
HDINIT
;HRTMON
;INITAGA
;INIT_AUDIO
;INIT_GADTOOLS
;INIT_LOWLEVEL
;INIT_MATHFFP
IOCACHE		= 4096
;JOYPADEMU
;MEMFREE	= $200
;NEEDFPU
;NO68020
POINTERTICKS	= 1
;PROMOTE_DISPLAY
STACKSIZE	= 10000
;TRDCHANGEDISK

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $59	; F10


;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================


slv_CurrentDir	IFD	DEBUG
		dc.b	"SOURCES:WHD_Slaves/BundesligaManagerPro/"
		ENDC
		dc.b	"data_200",0

slv_name	dc.b	"Bundesliga Manager Professional",0
slv_copy	dc.b	"1991 Software 2000",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"DEBUG!!! "
		ENDC
		dc.b	"Version 1.01 (07.09.2018)",0
slv_config	dc.b	0
		CNOP	0,4

DOSbase	dc.l	0

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

.ok	

; load game
.dogame	lea	.game(pc),a0
	bsr.b	.run
	bra.w	QUIT


.run	lea	PT_GAME(pc),a1
	bsr.w	.LoadAndPatch

	move.l	a6,-(a7)
	sub.l	a1,a1
	move.l	$4.w,a6
	jsr	_LVOFindTask(a6)
	move.l	d0,a0
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
	jmp	_LVOUnLoadSeg(a6)



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
; a1.l: patch table
; a6.l: dos base
; ---
; d7: segment

.LoadAndPatch
	move.l	a1,a5		; a5: will contain start of entry in patch table
	move.l	a1,a3		; a3: start of patch table

	move.l	a0,d6		; save file name for IoErr
	move.l	a0,d1
	jsr	_LVOLoadSeg(a6)
	move.l	d0,d7		; d7: segment

	bsr.b	.CRC16		; check all entries in patch table
	beq.b	.found

; unsupported/unknown version
.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.found	add.l	3*4(a5),a3	; a4: patch list



	move.l	a3,a0
.patch	move.l	d7,a1
	move.l	_resload(pc),a2
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



.game	dc.b	"BM",0
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
PT_GAME	dc.l	$36ba,$3e3a,$51df,PLGAME-PT_GAME	; v1.0
	dc.l	$36be,$3e3e,$51df,PLGAME_103-PT_GAME	; v1.03
	dc.l	$4577,$8126,$f566,PLGAME_200-PT_GAME	: v2.00
	dc.l	-1					; end of tab

PLGAME	PL_START
	;PL_W	$23cd0,$4e71		; disable protection check
	;PL_W	$2c30c,$4e71		; disable protection check
	;PL_W	$3c1e2,$4e71		; disable protection check

	PL_SA	$239c0,$23cd2
	PL_SA	$2c07a,$2c30e
	PL_SA	$3bf9e,$3c1e4


	PL_PS	$3d8ae,SetStack
	PL_PSS	$26f96,.fixacc,2
	PL_PSS	$26fb0,.fixacc2,2
	PL_PSS	$26fd4,.fixacc,2
	PL_END

.fixacc	move.w	-2(a5),d1
.fix	muls.w	#$26,d1
	cmp.l	#$80000,d1
	blo.b	.ok
	moveq	#0,d1
.ok	rts

.fixacc2
	move.w	-$76(a5),d1
	bra.b	.fix

PLGAME_103
	PL_START
	PL_SA	$2415e,$24470
	PL_SA	$2c480,$2c714
	PL_SA	$3c95c,$3cbaa

	PL_PS	$3e2bc,SetStack
	PL_END


PLGAME_200
	PL_START
	
	PL_PS	$3f872,SetStack
	PL_END
	

SetStack
	sub.l	#STACKSIZE,d0
	addq.l	#8,d0
	rts





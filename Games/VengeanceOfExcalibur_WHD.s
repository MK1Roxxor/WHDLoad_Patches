***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   VENGEANCE OF EXCALIBUR WHDLOAD SLAVE     )*)---.---.   *
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

; 26-Sep-2017	- access fault caused by using SMC for the Alloc/Release
;		  patches fixed (issue #3964)

; 20-Sep-2018	- different patch approach for fixing the "files not loaded"
;		  correctly problem used now

; 16-Sep-2018	- support for German and French versions added

; 15-Sep-2018	- work started



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
IOCACHE		= 10500
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
		dc.b	"SOURCES:WHD_Slaves/VengeanceOfExcalibur/"
		ENDC
		dc.b	"data",0

slv_name	dc.b	"Vengeance of Excalibur",0
slv_copy	dc.b	"1992 Virgin",0
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
.game	dc.b	"excalII",0
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
PT_GAME	dc.l	$130f,$1384,$240e,PLINTRO-PT_GAME
	dc.l	$102ca,$102f6,$78f8,PLGAME-PT_GAME	; SPS 2499
	dc.l	$1038e,$10586,$bc85,PLGAME_GER-PT_GAME	; German
	dc.l	$ff5e,$101aa,$305f,PLGAME_FR-PT_GAME	; French
	
	dc.l	-1					; end of tab


PLINTRO
	PL_START
	PL_PS	$ce80,SetStack
	PL_PSS	$54a2,FixRMB,2

	PL_B	$76f2,$60
	PL_SA	$719a,$71e2

	PL_SA	$6f00,$6f24		; skip Alloc/Release patches
	PL_END


PLGAME	PL_START
	PL_PS	$31c70,SetStack
	PL_B	$36778,1		; set fCopyProtectPassed
	PL_PSS	$29f52,FixRMB,2

	;PL_P	$32c1a,.Examine
	;PL_P	$32c28,ExNext
	PL_W	$2ba5c,$4e71		; force HD mode


	PL_SA	$2bc4a,$2bc92
	PL_B	$2c1a2,$60

	PL_SA	$2b9b0,$2b9d4		; skip Alloc/Release patches

	PL_END

.Examine
	move.w	#$0f0,$dff180
	btst	#6,$bfe001
	bne.b	.Examine

	move.l	DOSbase(pc),a6
	jsr	_LVOExamine(a6)
	rts


PLGAME_GER
	PL_START
	PL_PS	$324b4,SetStack
	PL_B	$36fbc,1		; set fCopyProtectPassed
	PL_PSS	$2a796,FixRMB,2
	
	PL_P	$3345e,Examine
	PL_P	$3346c,ExNext
	PL_W	$2c2a0,$4e71		; force HD mode

	PL_SA	$2c1f4,$2c218		; skip Alloc/Release patches
	PL_END


PLGAME_FR
	PL_START
	PL_PS	$3227c,SetStack
	PL_B	$36d68,1		; set fCopyProtectPassed
	PL_PSS	$2a55e,FixRMB,2
	
	PL_P	$33226,Examine
	PL_P	$33234,ExNext
	PL_W	$2c068,$4e71		; force HD mode

	PL_SA	$2bfbc,$2bfe0		; skip Alloc/Release patches
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

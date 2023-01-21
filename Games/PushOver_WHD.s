***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        PUSH OVER WHDLOAD SLAVE             )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              March 2014                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 21-Jan-2023	- DMA wait delay increased to 8 raster line
;		- minor size optimising

; 29-Dec-2022	- sound problems on fast machines fixed

; 05-Sep2016	- 3 CPU dependent delay loops fixed (sample players)

; 11-Apr-2014	- fixed crash on fast machines, caused by SMC in the
;		  VBI setup (Mantis issue #2980)
;		- last level in the game can be played now if unlimited
;		  time option has been enabled

; 24-Mar-2014	- EmulIllegal flag removed

; 23-Mar-2014	- work started
; 		- timing fixed, copylock correctly removed (key stored
;		  at $60.w), trainers added, intro skip option added,
;		  typo in language selection screen fixed
;		- timing in "use token/replay/quit" menu fixed too
;		- ProPack decruncher relocated


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
;DEBUG
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
IOCACHE		= 4096
;JOYPADEMU
;MEMFREE	= $200
;NEEDFPU
;NO68020
POINTERTICKS	= 1
;PROMOTE_DISPLAY
STACKSIZE	= 6000
;TRDCHANGEDISK

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $59	; F10


;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================


slv_CurrentDir	IFD	DEBUG
		dc.b	"SOURCES:WHD_Slaves/PushOver/"
		ENDC
		dc.b	"data",0

slv_name	dc.b	"Push Over",0
slv_copy	dc.b	"1992 Ocean",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"DEBUG!!! "
		ENDC
		dc.b	"Version 1.23 (21.01.2023)",0
slv_config	dc.b	"C1:B:Skip Intro;"
		dc.b	"C2:B:Unlimited Time;"
		dc.b	"C3:B:In-Game Keys;"
		dc.b	"C4:B:Disable Timing Fix"
		dc.b	0
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
	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

.ok

; load game
.dogame	lea	.game(pc),a0
	bsr.b	.run
	bra.w	QUIT


.run	lea	PT_GAME(pc),a1
	bsr.w	.LoadAndPatch
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

	lea	StartAddress(pc),a1
	move.l	a3,(a1)
	addq.l	#4,(a1)

	move.l	(a1),$100.w

	move.l	TIMETRAINER(pc),d1
	beq.b	.notimetrainer
	move.b	#$4a,$2d8c+4(a3)	; addq.b #1,seconds -> tst.b
.notimetrainer

	move.l	SKIPINTRO(pc),d1
	beq.b	.nointroskip
	move.b	#$60,$1d34+4(a3)
.nointroskip

; relocate ProPack decruncher
	lea	4+$7f6(a3),a1
	lea	RNC_Decrunch(pc),a2
	move.w	#($a20-$7f6)/2-1,d7
.copyRNC
	move.w	(a1)+,(a2)+
	dbf	d7,.copyRNC

	lea	4+$7f6(a3),a1
	pea	RNC_Decrunch(pc)
	move.w	#$4ef9,(a1)+
	move.l	(a7)+,(a1)

	move.l	_resload(pc),a1
	jsr	resload_FlushCache(a1)

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

.game	dc.b	"ant",0
.args	dc.b	"  ",10		; must be LF terminated
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
PT_GAME	dc.l	$18f2,$1932,$109b,PLGAME-PT_GAME	; game
	dc.l	-1					; end of tab

PLGAME	PL_START
	PL_PSS	$504,FixDMAWait,2	; fix DMA wait in replayer
	PL_B	$14ad0+1,"E"		; fix "DUETSCH" typo
	PL_B	$14ad0+2,"U"		; as above

	PL_PS	$12bec,.waitraster	; fix timing in language selector
	PL_PSA	$1cd0,.crack,$1cda	; disable copylock

	PL_P	$895c,.store		; store address of level complete flag
	PL_PS	$d0a8,.checklevelskip

	PL_PS	$1247e,.fixtiming	; fix in-game timing
	PL_PS	$12880,.fixtiming2	; fix timing in use token/quit menu

	PL_PSS	$1c50,.flush,2		; flush cache due to SMC in VBI init


; disable unlimited time trainer when picture before last
; level is shown, otherwise game won't continue
	PL_PS	$9fda,.disabletimetrainer	
	PL_P	$a3ec,.enabletimetrainer; and enable it again


	PL_PSS	$504,.FixDMAWait,2
	PL_PSS	$481c,FixDMAWait,2
	PL_PSS	$4854,FixDMAWait,2

	PL_P	$3048,.Fix_DMA_Wait_D1
	PL_PS	$30c0,.Fix_DMA_Wait_D4
	PL_END

.Fix_DMA_Wait_D1
	bsr.w	FixDMAWait
	move.w	d1,$dff096
	rts

.Fix_DMA_Wait_D4
	bsr.w	FixDMAWait
	move.w	d4,$dff096
	bsr.w	FixDMAWait
	rts


.FixDMAWait2
	bsr.w	FixDMAWait
	move.w	d4,$dff096
	rts

.FixDMAWait
	move.w	#200-1,d0
.loop	bsr.w	FixDMAWait
	dbf	d0,.loop
	rts	

.disabletimetrainer
	move.l	StartAddress(pc),a0
	move.l	StartAddress(pc),a0
	move.b	#$52,$2d8c(a0)
	move.l	_resload(pc),a0
	jsr	resload_FlushCache(a0)
	moveq	#0,d0
	move.w	d0,-10(a5)
	rts


.enabletimetrainer
	move.l	StartAddress(pc),a0
	move.l	TIMETRAINER(pc),d2
	beq.b	.off
	move.b	#$4a,$2d8c(a0)		; addq.b #1,seconds -> tst.b
.off	
	movem.l	(a7)+,d2/d3/a2/a3
	unlk	a5
	rts

.flush	move.l	_resload(pc),a0
	jsr	resload_FlushCache(a0)
	move.w	#$8020,$dff09a		; original code
	rts


.fixtiming2
	move.w	#3,-2(a5)
	bra.w	WaitRaster


.fixtiming
	move.l	d0,-(a7)
	move.l	NOTIMINGFIX(pc),d0
	bne.b	.nope
	bsr.w	WaitRaster
	bsr.w	WaitRaster
.nope	move.l	(a7)+,d0

	sub.w	d0,d1
	moveq	#$3d,d0
	cmp.w	d0,d1
	rts



.checklevelskip
	move.l	INGAMEKEYS(pc),d0
	beq.b	.nokeys

	movem.l	d0-a6,-(a7)

	move.b	$bfec01,d0
	ror.b	d0
	not.b	d0
	cmp.b	#$36,d0			; N - level skip
	bne.b	.nolevelskip
	move.l	LevelComplete(pc),a0
	move.w	#1,(a0)
.nolevelskip

	cmp.b	#$14,d0			; T - toggle unlimited time
	bne.b	.notimetoggle
	move.l	StartAddress(pc),a0
	eor.b	#$18,$2d8c(a0)		; addq.b <-> tst.b
.notimetoggle

	cmp.b	#$21,d0			; S - try auto solve
	bne.b	.nosolve
	move.l	AutoSolve(pc),a0
	move.w	#1,(a0)
.nosolve

	cmp.b	#$23,d0			; F - toggle timing fix
	bne.b	.nofixtoggle
	lea	NOTIMINGFIX(pc),a0
	not.l	(a0)
.nofixtoggle

	movem.l	(a7)+,d0-a6

.nokeys



	moveq	#$14,d0
	cmp.b	2(a3),d0
	rts

.store	movem.l	a0/a1,-(a7)
	move.l	StartAddress(pc),a0
	add.l	#$d0b0+2,a0
	lea	LevelComplete(pc),a1
	move.l	(a0),(a1)+

	move.l	StartAddress(pc),a0
	add.l	#$aeb8+2,a0
	move.l	(a0),(a1)

	movem.l	(a7)+,a0/a1
	rts
	

.crack	pea	.copylock(pc)
	move.w	#$4ef9,(a0)
	move.l	(a7)+,2(a0)
	move.l	_resload(pc),a0
	jmp	resload_FlushCache(a0)

.copylock
	move.l	#$42fcdb80,d0
	move.l	d0,$60.w
	rts

.waitraster
	bsr.b	WaitRaster
	cmp.w	#4,-$12(a5)
	rts


StartAddress	dc.l	0
LevelComplete	dc.l	0
AutoSolve	dc.l	0

FixAudXVol
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts

FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#8-1,d1	
.loop	move.b	$dff006,d0
.wait	cmp.b	$dff006,d0
	beq.b	.wait
	dbf	d1,.loop
	movem.l	(a7)+,d0/d1
	rts


WaitRaster
	move.l	d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#16<<8,d0
	bne.b	.wait
.wait2	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#16<<8,d0
	beq.b	.wait2
	move.l	(a7)+,d0
	rts


RNC_Decrunch
	ds.b	$a20-$7f6

TAGLIST		dc.l	WHDLTAG_CUSTOM1_GET
SKIPINTRO	dc.l	0

		dc.l	WHDLTAG_CUSTOM2_GET
TIMETRAINER	dc.l	0

		dc.l	WHDLTAG_CUSTOM3_GET
INGAMEKEYS	dc.l	0

		dc.l	WHDLTAG_CUSTOM4_GET
NOTIMINGFIX	dc.l	0

		dc.l	TAG_END





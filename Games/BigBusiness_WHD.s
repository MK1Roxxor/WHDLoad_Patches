***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       BIG BUSINESS WHDLOAD SLAVE           )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              March 2013                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 06-Apr-2021	- support for another version added (sent by Christoph)

; 23-Dec-2013	- cache flush patch for sales version corrected (wrong
;		  offset)
;		- IOCACHE increased to 4096 bytes, save game size is 4020
;		  bytes

; 10-Mar-2013	- work started
;		- supports 2 versions


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
STACKSIZE	= 20000
;TRDCHANGEDISK

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	; F10


;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================


slv_CurrentDir	IFD	DEBUG
		dc.b	"SOURCES:WHD_Slaves/BigBusiness/data_sales",0
		ELSE
		dc.b	"data",0
		ENDIF

slv_name	dc.b	"Big Business",0
slv_copy	dc.b	"1990 Magic Bytes",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"DEBUG!!! "
		ENDC
		dc.b	"Version 1.01 (06.04.2021)",0

slv_config	dc.b	"C1:L:Game Mode:Normal,Short&Fast,Long,Short&Slow"
		dc.b	0
		CNOP	0,4

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

; CUSTOM! selects game mode
; 0: normal
; 1: short&fast (bbiz 1)
; 2: long	(bbiz n)
; 3: short&slow	(bbiz n1)
	move.l	MODE(pc),d0
	beq.b	.ok
	lea	.args(pc),a0
	move.b	#"1",(a0)
	cmp.b	#1,d0
	beq.b	.ok
	move.b	#"n",(a0)
	cmp.b	#2,d0
	beq.b	.ok
	move.b	#"n",(a0)
	move.b	#"1",1(a0)	; 68000 compatible
	cmp.b	#3,d0
	beq.b	.ok
; unknown/unsupported mode -> default game mode
	move.b	#" ",(a0)
	move.b	#" ",1(a0)

.ok	


	
; load game
.dogame	lea	.game(pc),a0
	lea	PT_GAME(pc),a1
.go	bsr.b	.LoadAndPatch

.run	move.l	d7,d1
	moveq	#.arglen,d0
	lea	.args(pc),a0
	bsr.b	.call
	bra.w	QUIT




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
	move.l	a1,a5
	movem.w	(a1),d0/d1		; start/end offset for CRC16
	sub.w	d0,d1			; length to check
	move.l	d0,d3
	move.l	d1,d4

	move.l	a0,d6
	move.l	a0,d1
	jsr	_LVOLoadSeg(a6)
	move.l	d0,d7
	beq.b	.error

	bsr.b	.CRC16

; d2.w: checksum
	move.l	a5,a0			; a0: current entry in tab
.find	move.w	2*2(a0),d0		; (points to CRC16 value)
	cmp.w	#-1,d0
	beq.b	.out
	tst.w	d0
	beq.b	.wrongver
	cmp.w	d0,d2
	beq.b	.found

	addq.w	#4*2,a0			; next entry in tab
	movem.w	(a0),d3/d4		; new start/end offset for CRC16
	sub.w	d3,d4			; length
	bsr.b	.CRC16			; get new checksum
	bra.b	.find

; unsupported/unknown version
.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.found	add.w	3*2(a0),a5		; a5: patch list



	move.l	a5,a0
.patch	move.l	d7,a1
	move.l	_resload(pc),a2
	jsr	resload_PatchSeg(a2)
.out	rts

.error	jsr	_LVOIoErr(a6)
	move.l	d6,-(a7)
	move.l	d0,-(a7)
	pea	(TDREASON_DOSREAD).w
	bra.w	EXIT

; d3.l: offset
; d4.l: length to check
; d7.l: segment
; ----
; d0.w: CRC16 value
; d2.w: CRC16 value

.CRC16	move.l	a0,-(a7)
	move.l	d7,a0
	add.l	a0,a0
	add.l	a0,a0
	lea	4(a0,d3.l),a0
	move.l	d4,d0
	move.l	_resload(pc),a2
	jsr	resload_CRC16(a2)
	move.w	d0,d2
	move.l	(a7)+,a0
	rts

.game	dc.b	"bbiz",0
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
PT_GAME	dc.w	$12,$42,$12e7,PLGAME-PT_GAME	; probably pre-release version
	dc.w	$2b0,$324,$b2c5,PLGAME2-PT_GAME	; sales version
	dc.w	$280,$2f4,$b2c5,PLGAME3-PT_GAME	; version sent by Christoph
	
	dc.w	0				; end of tab

PLGAME3	PL_START
	PL_P	$2ee3a,acklev4_c0
	PL_PS	$2b7be,flush		; flush cache before executing code
	PL_END
	

PLGAME2	PL_START
	PL_P	$2ee6a,acklev4_c0
	PL_PS	$2b7ee,flush		; flush cache before executing code
	PL_END

.ackVBI	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rte

acklev4_c0
	move.w	#$c0,$dff09c
	move.w	#$c0,$dff09c
	rte

PLGAME	PL_START
	PL_P	$2b19e,.acklev4
	PL_PS	$272fe,flush		; flush cache before executing code
	PL_END



.acklev4
	move.w	#$80,$dff09c
	move.w	#$80,$dff09c
	rte
		

flush	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	jsr	(a1)
	and.b	#$ee,ccr
	rts

TAGLIST	dc.l	WHDLTAG_CUSTOM1_GET
MODE	dc.l	0
	dc.l	TAG_END





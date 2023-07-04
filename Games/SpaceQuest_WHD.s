***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        SPACE QUEST WHDLOAD SLAVE           )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             December 2015                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 21-Dec-2015	- work started
;		- and finished a while later, Herndon HLS executable
;		  decrypted, RawDIC imager coded, Load/Save diretory
;		  requests disabled


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
		dc.b	"SOURCES:WHD_Slaves/SpaceQuest/"
		ENDC
		dc.b	"data",0

slv_name	dc.b	"Space Quest",0
slv_copy	dc.b	"1987 Sierra",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"DEBUG!!! "
		ENDC
		dc.b	"Version 1.2 (21.12.2015)",0
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
	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

; load game
.dogame	lea	.game(pc),a0
	bsr.b	.run
	bra.w	QUIT


.run	lea	PT_GAME(pc),a1
	bsr.w	.LoadAndPatch

	; store loaded segment list in current task
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
	beq.b	.error

	movem.l	d0-a6,-(a7)
	bsr	Decrypt		; decrypt Herndon HLS protected executable
	movem.l	(a7)+,d0-a6

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

.game	dc.b	"Sierra",0
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
PT_GAME	dc.l	$0,$32,$4a83,PLGAME-PT_GAME	; SPS 1484
	dc.l	-1				; end of tab

PLGAME	PL_START
	PL_SA	$0,$4f0			; skip all Herndon HLS stuff
	PL_SA	$12d2,$1306		; skip load/save directory request
	PL_END







TAGLIST		dc.l	TAG_END




; Space Quest decrypter
; stingray, 21-Dec-2015
; early 1 pass Herndon HLS protection

Decrypt	lsl.l	#2,d7
	addq.l	#4,d7
	move.l	d7,a5		; a5: start of executable

	cmp.w	#$4e71,$32(a5)	; BTTR version (decrypted binary)?
	bne.b	.isHLS		
	rts			; don't decrypt!

.isHLS
	;lea	data+$2b8(pc),a5

	lea	2(a5),a0
	lea	$36(a5),a1
	move.w	(a0)+,d0
	eor.w	d0,(a1)+

	moveq	#14-1,d0
.loop1	not.w	(a0)+
	dbf	d0,.loop1

	move.l	a5,a0
	move.w	#"Sp",2(a0)

	move.w	#$23c-1,d1
.loop2	move.w	(a0)+,d0
	eor.w	d0,(a1)+
	dbf	d1,.loop2


	move.l	a5,a0
	moveq	#0,d0			; initial key
	move.w	#$1021,d3		; eor key
	move.w	#$fb,d4			; length
	bsr	.CalcKey

; decrypt the "read protection track" code
	move.w	#$15b,d2
.loop3	move.w	(a0)+,d1
	add.w	d0,d1
	eor.w	d1,(a0)
	dbf	d2,.loop3

	move.l	a5,a0
	moveq	#0,d0			; initial key
	move.w	#$1021,d3		; eor key
	move.w	#$265,d4		; length
	bsr	.CalcKey

; calculate final decryption keys to decrypt hunk data
	move.w	#1000-14,d1		; 1000: max. value
	and.w	#$FF80,d1		; only keep the upper 9 bits
	add.w	d1,d0
	eor.w	d1,d0
	lsr.w	#8,d1
	eor.b	d1,d0

	;move.l	($1A,a5),a2		; a2: hunk entries
	lea	.RELOC(pc),a2
	move.w	d0,d2
.doall	move.w	(a2)+,d0
	move.w	(a2)+,d3
	beq.b	.done
	lea	$4f0(a5),a0
	add.w	d0,a0
	add.w	d0,a0
	move.l	a5,a1
	subq.w	#2,d3
.decrypt
	move.w	(a0)+,d0
	move.b	(a1)+,d1
	eor.w	d2,d0
	eor.b	d1,d0
	eor.w	d0,(a0)
	dbf	d3,.decrypt
	bra.b	.doall

.done
	rts



.CalcKey
	subq.w	#1,d4
.keyouter
	move.w	(a0)+,d1
	moveq	#16-1,d5
.keyinner
	moveq	#0,d2
	lsl.w	#1,d1
	roxr.w	#1,d2
	eor.w	d2,d0
	lsl.w	#1,d0
	bcc.b	.skip
	eor.w	d3,d0
.skip	dbf	d5,.keyinner
	dbf	d4,.keyouter
	rts


.RELOC	DC.W	$0012,$0015,$002C,$000A,$003B,$0018,$006C,$0006
	DC.W	$0074,$0007,$007D,$000E,$0093,$0007,$009C,$0005
	DC.W	$00A3,$0005,$00AA,$0005,$00B7,$001B,$00D7,$0006
	DC.W	$0000,$0000

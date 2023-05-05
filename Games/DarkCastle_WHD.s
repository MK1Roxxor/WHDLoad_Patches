***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       DARK CASTLE WHDLOAD SLAVE            )*)---.---.   *
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

; 31-Jul-2016	- patch requires 512k extra memory now as otherwise game
;		  could quit due to lack of memory
;		- changed timing fix, the slow down can now be chosen with
;		  CUSTOM2, 0: off, 1-4: number of frames to wait

; 25-Mar-2014	- timing fixed
;		- trainers added

; 24-Mar-2014	- work started
;		- decrypter for the game coded, no real work on the patch
;		  yet


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
		dc.b	"SOURCES:WHD_Slaves/DarkCastle/"
		ENDC
		dc.b	"data",0

slv_name	dc.b	"Dark Castle",0
slv_copy	dc.b	"1988 Three-Sixty",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"DEBUG!!! "
		ENDC
		dc.b	"Version 1.01 (31.07.2016)",0
slv_config	dc.b	"C1:X:Unlimited Lives:0;"
		dc.b	"C1:X:Unlimited Rocks:1;"
		dc.b	"C1:X:Unlimited Elixir:2;"
		dc.b	"C1:X:Unlimited Bonus:3;"
		dc.b	"C2:L:Timing Fix:Off,1x,2x,3x,4x"
		dc.b	0
DiskName	dc.b	"DC1",0
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

; assign disks
	lea	DiskName(pc),a0
	sub.l	a1,a1
	bsr	_dos_assign

	lea	DiskName(pc),a0
	addq.b	#1,2(a0)		; DC2:
	sub.l	a1,a1
	bsr	_dos_assign
	


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

; install trainers
	move.w	#$4e75,d2	; rts
	move.l	TRAINEROPTIONS(pc),d1
	lsr.l	#1,d1		; unlimited lives
	bcc.b	.nolivestrainer
	move.w	d2,$14e4+4(a3)
.nolivestrainer

	lsr.l	#1,d1		; unlimited rocks
	bcc.b	.norockstrainer
	move.w	d2,$14b0+4(a3)
.norockstrainer

	lsr.l	#1,d1		; unlimited elixir
	bcc.b	.noelixirtrainer
	move.w	d2,$1516+4(a3)
.noelixirtrainer

	lsr.l	#1,d1		; unlimited bonus
	bcc.b	.nobonustrainer
	move.w	d2,$1478+4(a3)
.nobonustrainer

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


; decrypt HLS executable
	movem.l	d0-a6,-(a7)
	bsr	Decrypt
	movem.l	(a7)+,d0-a6

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

.game	dc.b	"dark castle",0
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
PT_GAME	dc.l	$000,$570,$4824,PLGAME-PT_GAME	; SPS 1459
	dc.l	-1				; end of tab

PLGAME	PL_START
	PL_SA	$0,$570		; jmp to main part
	PL_PS	$12598,.stack
	PL_PS	$c0f2,.fixtiming

;	PL_R	$14b0		; unlimited rocks
;	PL_R	$1478		; unlimited bonus
;	PL_R	$14e4		; unlimited lives
;	PL_R	$1516		; unlimited elixir
	PL_END

.fixtiming
	move.w	$12(a0),d0
	ext.l	d0

	movem.l	d0-a6,-(a7)
	move.l	TIMINGFIX(pc),d7
	beq.b	.skip

	move.l	-$1614(a4),a6	; gfxbase

	
.loop	jsr	-270(a6)	; WaitTOF()
	subq.w	#1,d7
	bne.b	.loop	

.skip
	movem.l	(a7)+,d0-a6
	rts


.stack	sub.l	#STACKSIZE,d0
	addq.l	#8,d0
	rts



; Dark Castle decrypter (1 pass Herndon HLS encryption)
; stingray, 24-mar-2014

; d7.l: segment

Decrypt	lsl.l	#2,d7
	move.l	d7,a4
	addq.l	#4,a4
	lea	$18(a4),a3

	;lea	data+$18(pc),a3
	;lea	data(pc),a4

	move.l	a3,a0
	lea	$4e(a4),a1
	move.w	#$271-1,d1		; -1 because of prefetch trick
	move.w	(a0)+,d0
	eor.w	d0,(a1)+

	moveq	#15-1,d0
.loop1	not.w	(a0)+
	dbf	d0,.loop1

	move.l	a3,a0
	move.w	#"DC",(a0)

.loop2	move.w	(a0)+,d0
	eor.w	d0,(a1)+
	dbf	d1,.loop2


	move.l	a3,a0
	move.w	#$45c3,d3		; $24.w key

	moveq	#-1,d0
	move.w	#$108,d5
	subq.w	#1,d5
.keyloop
	move.w	(a0)+,d1
	moveq	#16-1,d4
.calc	moveq	#0,d2
	lsl.w	#1,d1
	roxr.w	#1,d2
	eor.w	d2,d0
	lsl.w	#1,d0
	bcc.b	.skip
	eor.w	d3,d0
.skip	dbf	d4,.calc
	dbf	d5,.keyloop

	move.w	#$183,d2
.loop3	move.w	(a0)+,d1
	add.w	d0,d1
	eor.w	d1,(a0)
	dbf	d2,.loop3


	move.w	#$69ce,d0
	lea	.Reloc(pc),a2	; a2: relocation table
	move.w	d0,d2
	moveq	#0,d0
.relocate
	move.w	(a2)+,d0
	move.w	(a2)+,d3
	beq.b	.done
	lea	$570(a4),a0	; start of executable
	add.l	d0,a0
	add.l	d0,a0
	move.l	a3,a1

	subq.w	#2,d3
.relocloop
	move.w	(a0)+,d0
	move.b	(a1)+,d1
	eor.w	d2,d0
	eor.b	d1,d0
	eor.w	d0,(a0)
	dbf	d3,.relocloop
	bra.b	.relocate

.done	rts


.Reloc	DC.W	$0003,$01E1,$01E6,$002A,$0212,$004C,$0260,$00D7
	DC.W	$0339,$003F,$037A,$0068,$03E4,$004C,$0432,$005C
	DC.W	$0490,$0007,$0499,$0014,$04B5,$000A,$04C1,$0050
	DC.W	$0513,$00A7,$05BC,$004A,$0608,$0032,$063C,$0047
	DC.W	$0685,$0010,$0697,$0013,$06AC,$0016,$06C8,$009D
	DC.W	$076A,$01C4,$0930,$0008,$093A,$0008,$0944,$0008
	DC.W	$094E,$0008,$0958,$0008,$0962,$000D,$0971,$000E
	DC.W	$0981,$0025,$09A8,$0015,$09C2,$002F,$09F6,$00A6
	DC.W	$0A9E,$0063,$0B03,$0028,$0B2D,$0039,$0B68,$0018
	DC.W	$0B82,$001C,$0BA0,$002B,$0BCD,$0021,$0BF0,$001B
	DC.W	$0C0D,$0530,$1198,$0027,$11C1,$004E,$1211,$0015
	DC.W	$1228,$000A,$1234,$0006,$123C,$0008,$1246,$0008
	DC.W	$1250,$0008,$125A,$000A,$1266,$0008,$1270,$0008
	DC.W	$127A,$0008,$1284,$0008,$128E,$0008,$1298,$0008
	DC.W	$12A2,$0008,$12AF,$0013,$12C7,$0013,$12DF,$0013
	DC.W	$12F7,$0013,$130F,$0013,$1327,$0013,$133F,$0013
	DC.W	$1357,$0013,$136F,$0012,$1386,$0012,$139D,$00B4
	DC.W	$1453,$0012,$1467,$00AF,$1518,$0007,$1521,$000B
	DC.W	$152E,$000D,$153D,$0013,$1552,$0015,$1569,$0010
	DC.W	$157B,$0014,$1591,$0024,$15C4,$0012,$15D8,$0014
	DC.W	$15EE,$001E,$1612,$0005,$1626,$0012,$163A,$0014
	DC.W	$1650,$001E,$1674,$0012,$1688,$0014,$169E,$001C
	DC.W	$16C0,$0029,$16EB,$0020,$170D,$0011,$1720,$0020
	DC.W	$1742,$0011,$1755,$0020,$1777,$0011,$178A,$0020
	DC.W	$17AC,$0022,$17D0,$0021,$17F3,$0018,$180D,$000C
	DC.W	$181B,$0024,$1841,$0019,$185C,$0007,$1865,$001B
	DC.W	$1882,$0008,$188C,$0024,$18B2,$0020,$18D4,$0045
	DC.W	$191B,$0007,$1924,$0011,$1937,$0016,$194F,$0011
	DC.W	$1962,$001C,$1980,$0008,$198A,$0020,$19AC,$0034
	DC.W	$19E2,$000F,$19F3,$0013,$1A08,$0013,$1A1D,$003B
	DC.W	$1A5A,$0027,$1A83,$0024,$1AA9,$0024,$1ACF,$0027
	DC.W	$1AF8,$003E,$1B38,$000D,$1B47,$0013,$0000,$0000


FixAudXVol
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts

FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d1	
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


TAGLIST		dc.l	WHDLTAG_CUSTOM1_GET

; bit 0: unlimited lives on/off
; bit 1: unlimited rocks on/off
; bit 2: unlinited elixir on/off
; bit 3: unlimited bonus on/off
TRAINEROPTIONS	dc.l	0

		dc.l	WHDLTAG_CUSTOM2_GET
TIMINGFIX	dc.l	0			; 0: off

		dc.l	TAG_END





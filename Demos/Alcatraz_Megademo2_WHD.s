***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      MEGADEMO 2/ALCATRAZ WHDLOAD SLAVE     )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             October 2013                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 15-Apr-2020	- patch runs in user mode now to avoid possible freezing
;		  (Mantis issue #4472)

; 14-Apr-2020	- OCS only DDFSTART in part 4 fixed
;		- access fault when restarting scroller in part 4 fixed
;		- ByteKiller decruncher slightly optimised (roxl -> addx)
;		- line vector in part 6 fixed for fast machines

; 13-Apr-2020	- fake exec library and AllocEntry() emulation code written,
;		  AllocEntry patches in Zodiac's parts removed
;		- default copperlist stuff simplified

; 12-Apr-2020	- BPLCON3/4 access removed from slave
;		- blitter waits added in part 2 ("Blitter Shock")
;		- write to HTOTAL in part 3 fixed (buggy fade routine)
;		- line drawer in part 6 fixed, blitter waits added


; 04-Jan-2014	- fixed 2 more byte writes to volume registers (part 1 & 3)
;		- fixed clr.w (a6) problem in part 3

; 06-Oct-2013	- work started

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem
QUITKEY		= $59		; F10
;DEBUG

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM

HEADER	SLAVE_HEADER		; ws_security + ws_ID
	dc.w	17		; ws_version
	dc.w	FLAGS		; flags
	dc.l	524288		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	dc.w	.dir-HEADER	; ws_CurrentDir
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_KeyDebug
	dc.b	QUITKEY		; ws_KeyExit
	dc.l	0		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Alcatraz/Megademo2/"
	ENDC
	dc.b	"data",0
.name	dc.b	"Megademo 2",0
.copy	dc.b	"1988 Alcatraz",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.03 (15.04.2020)",0
	CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	$1000.w,a7
	lea	-1024(a7),a0
	move.l	a0,USP

; install keyboard irq
	bsr	SetLev2IRQ

	move.l	a7,a0
	move.l	#$01000200,(a0)+
	move.l	#$008a0000,(a0)		; start copperlist 2

	
; set default level3+6 interrupts
	lea	AckVBI(pc),a0
	move.l	a0,$6c.w
	lea	AckLev6(pc),a0
	move.l	a0,$78.w
	move.w	#$c028,$dff09a


	; create fake exec library
	lea	$700.w,a0
	move.l	a0,$4.w
	lea	-222(a0),a1		; AllocEntry
	move.w	#$4ef9,(a1)+
	pea	AllocEntry(pc)
	move.l	(a7)+,(a1)


	move.w	#0,sr

; run part 1
	move.w	#$204d,d0
	lea	PLPART1(pc),a0
	bsr.b	.load

; run part 2
	moveq	#0,d0
	lea	PLPART2(pc),a0
	bsr.b	.load

; run part 3
	moveq	#0,d0
	lea	PLPART3(pc),a0
	bsr.b	.load

; run part 4
	moveq	#0,d0
	lea	PLPART4(pc),a0
	bsr.b	.load

; run part 5
	moveq	#0,d0
	lea	PLPART5(pc),a0
	bsr.b	.load

; run part 6
	moveq	#0,d0
	lea	PLPART6(pc),a0
	move.l	#$60000,free-PLPART6(a0)
	bsr.b	.load

	bra.w	QUIT

.load	move.w	#6,$300.w		; set default speed for replayer
	move.l	a0,a1
	lea	$2000.w,a0
	bsr.b	LoadFile
	clr.l	$0.w
	jmp	(a6)


; a0.l: destination
; a1.l: patch list or 0
; d0.w: checksum or 0

LoadFile
.LMB	btst	#6,$bfe001
	beq.b	.LMB
	move.l	a0,a5
	move.l	a1,a4
	move.w	d0,d5

	lea	.NAMES(pc),a0
	add.w	.count(pc),a0

	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)
	move.l	d0,d6			; save file size
	tst.w	d5
	beq.b	.noCRC16
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	d0,d5
	beq.b	.CRC16ok
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.CRC16ok
.noCRC16

	cmp.w	#$2018,$2e(a5)		; move.l (a0)+,d0
	beq.b	.decrunch
	move.l	a5,a0
	sub.l	a1,a1			; no tags
	jsr	resload_Relocate(a2)
	move.l	a5,a6
	lea	$60000,a0
	move.w	#$15000/4-1,d7
.cls	clr.l	(a0)+
	dbf	d7,.cls
	bra.b	.nodecrunch

.decrunch
	movem.l	d0-a4,-(a7)
	move.l	a5,a0
	bsr	BK_DECRUNCH
	move.l	a3,a5
	movem.l	(a7)+,d0-a4


.nodecrunch
	move.l	a4,a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

.nopatch
	lea	.count(pc),a0
	addq.w	#1*4,(a0)
	rts


.count	dc.w	0
.NAMES	dc.b	"M1",0,0	; metalwar 1
	dc.b	"Z1",0,0	; zodiac 1
	dc.b	"M2",0,0	; metalwar 2
	dc.b	"D2",0,0	; darkblitter
	dc.b	"M3",0,0	; metalwar 3
	dc.b	"Z2",0,0	; zodiac 2


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	jmp	resload_Abort(a2)

AckVBI	move.w	#1<<5+1<<4+1<<6,$dff09c
	move.w	#1<<5+1<<4+1<<6,$dff09c
	rte

AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte

KillSys	move.w	#$7fff,$dff09a		; disable all interrupts
	bsr	WaitRaster
	move.w	#$7ff,$dff096		; disable all DMA
	move.w	#$7fff,$dff09c		; disable all interrupt requests
	lea	AckVBI(pc),a0
	move.l	a0,$6c.w
	lea	$1000.w,a0
	move.l	a0,$dff080
	move.l	a0,$dff084
	rts



AllocMem
	lea	free(pc),a1
	move.l	(a1),d1
	add.l	d0,(a1)
	move.l	d1,d0
	rts

AllocEntry
	move.l	a0,-(a7)
	add.w	#14,a0			; skip LN_SIZE
	move.w	d7,-(a7)
	move.w	(a0)+,d7		; # of entries
.loop	movem.l	(a0),d0/d1		; type, size
	move.l	d1,d0
	bsr.b	AllocMem
	move.l	d0,(a0)
	addq.w	#2*4,a0
	subq.w	#1,d7
	bne.b	.loop
	move.w	(a7)+,d7
	move.l	(a7)+,d0
	rts

free	dc.l	$60000


PLPART1	PL_START
	PL_PSS	$648,.checkspeed,2	; fix SMC in replayer (check speed)
	PL_P	$784,FixAudXVol		; fix byte write to volume register
	PL_L	$7b0+2,$300		; fix SMC in replayer (set speed)
	PL_PSS	$85e,FixDMAWait,2	; fix DMA wait in replayer
	PL_P	$14a,AckVBI
	PL_ORW	$f0+2,1<<3		; enable level 2 interrupt
	PL_SA	$0,$4
	PL_P	$100,KillSys
	PL_W	$642,$5279		; addq.w #2 -> addq.w #1
	PL_PS	$952,FixAudXVol
	PL_END

.checkspeed
	move.w	$300.w,d0
	cmp.w	$3a300+$acc,d0
	rts

PLPART2	PL_START
	PL_P	$2da,AckVBI
	PL_ORW	$254+2,1<<3		; enable level 2 interrupt
	PL_P	$264,KillSys
	PL_PSS	$13ca,FixDMAWait,2	; fix DMA wait in replayer

	PL_PS	$2e2,.wblit
	PL_PSS	$70c,.wblit2,2
	PL_PSS	$39e,.wblit3,2
	PL_PS	$4fa,.wblit4
	PL_PS	$512,.wblit4
	PL_PS	$4c8,.wblit5


	PL_END

.wblit5	mulu.w	#42,d1
	add.w	d0,d1
	bra.b	WaitBlit

.wblit4	add.l	#$24c0,d1
	bra.b	WaitBlit

.wblit3	bsr.b	WaitBlit
	move.l	#$ffff0000,$44(a6)
	rts

.wblit2	bsr.b	WaitBlit
	move.l	#$29f00002,$40(a6)
	rts


.wblit	move.l	(a0),a1
	lea	$6e40(a1),a2

WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts



PLPART3	PL_START
	PL_PSS	$2190,.checkspeed,2	; fix SMC in replayer (check speed)
	PL_P	$22cc,FixAudXVol	; fix byte write to volume register
	PL_L	$22f8+2,$300		; fix SMC in replayer (set speed)
	PL_PSS	$23a6,FixDMAWait,2	; fix DMA wait in replayer
	PL_ORW	$2616+2,1<<9		; set Bplcon0 color bit
	PL_P	$16e,AckVBI
	PL_ORW	$d4+2,1<<3		; enable level 2 interrupt
	PL_SA	$0,$4
	PL_P	$ee,KillSys
	PL_W	$be,$80
	PL_PS	$249a,FixAudXVol
	PL_SA	$2fc,$300		; skip clr.w 0(a6)

	PL_AB	$22a+1,-1		; fix fade routine loop counter
	PL_END

.checkspeed
	move.w	$300.w,d0
	cmp.w	$36014+$2614,d0
	rts

PLPART4	PL_START
	PL_PSS	$21a0,.checkspeed,2	; fix SMC in replayer (check speed)
	PL_P	$22dc,FixAudXVol	; fix byte write to volume register
	PL_L	$2308+2,$300		; fix SMC in replayer (set speed)
	PL_PSS	$23b6,FixDMAWait,2	; fix DMA wait in replayer
	PL_SA	$2152,$215a		; don't modify VBI code
	PL_P	$2190,AckVBI
	PL_PSA	$b0,.setcop,$d8
	PL_SA	$e8,$f2			; don't modify VBI code
	PL_P	$318,.AckVBI
	PL_P	$1ce,KillSys
	PL_ORW	$708+2,1<<9		; set Bplcon0 color bit
	PL_SA	$0,$4			; skip crap
	PL_PSA	$f2,.setVBI,$fc
	PL_P	$e0a,.delay3000
	PL_P	$e18,.delay10000

	PL_W	$6e4+2,$30		; fix OCS only DDFSTART
	PL_SA	$2cc,$2d4		; skip add.b #1,TextPtr
	PL_END

.AckVBI	jsr	$272b4+$2196		; mt_music
	bra.w	AckVBI

.delay3000
	moveq	#10-1,d7
.loop	bsr	FixDMAWait
	dbf	d7,.loop
	rts

.delay10000
	moveq	#3-1,d6
.loop2	bsr.b	.delay3000
	dbf	d6,.loop2
	rts

.setVBI	move.l	#$272b4+$200,$6c.w
	move.w	#$c028,$dff09a
	rts

.setcop	lea	$dff080-$32,a0
	move.w	#$83c0,$dff096
	rts

.checkspeed
	move.w	$300.w,d0
	cmp.w	$272b4+$2624,d0
	rts

PLPART5	PL_START
	PL_ORW	$aa4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$a84+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$5fe,.checkspeed,2	; fix SMC in replayer (check speed)
	PL_P	$73a,FixAudXVol		; fix byte write to volume register
	PL_L	$766+2,$300		; fix SMC in replayer (set speed)
	PL_PSS	$814,FixDMAWait,2	; fix DMA wait in replayer
	PL_P	$2c2,AckVBI
	PL_ORW	$244+2,1<<3		; enable level 2 interrupt
	PL_SA	$0,$4
	PL_P	$258,KillSys
	PL_PSA	$a8,.LMB,$b2
	PL_PS	$4c0,.wait
	PL_END

.wait	lea	$65000,a0
	bra.w	WaitRaster

.LMB	btst	#6,$bfe001
	bne.b	.LMB
.release
	btst	#6,$bfe001
	beq.b	.release
	rts

.checkspeed
	move.w	$300.w,d0
	cmp.w	$2df38+$a82,d0
	rts

PLPART6	PL_START
	PL_ORW	$64+2,1<<3		; enable level 2 interrupt
	PL_P	$1ec,KillSys
	PL_PSS	$2a42,FixDMAWait,2	; fix DMA wait in replayer
	PL_P	$900,.AckVBI

	PL_PS	$2190,.wblit1
	PL_PSS	$2148,.FixBltcon1,2
	PL_PSS	$992,.wblit2,2
	PL_PS	$aa0,.wblit3
	PL_PS	$8c6,.wblit4



	; don't run code in VBI
	PL_P	$88c,AckVBI
	PL_PSS	$1e2,.RunEffectCode,4
	PL_R	$8f2

	PL_END


.RunEffectCode
.loop	bsr	WaitRaster


	; swap screens
	lea	$2000+$2ce2,a0
	move.l	(a0),d0
	move.l	4(a0),(a0)
	move.l	d0,4(a0)
	move.l	$2000+$2ce2.w,$dff0ec



	jsr	$2000+$892.w
	btst	#6,$bfe001
	bne.b	.loop
	rts





.AckVBI	bsr	WaitBlit
	bra.w	AckVBI

.FixBltcon1
	move.w	d4,$52(a6)
	and.w	#%1111000001011111,d5
	move.w	d5,$42(a6)
	rts

.wblit1	bsr	WaitBlit
	move.l	#-1,$44(a6)
	move.w	#44,$60(a6)
	rts

.wblit2	bsr	WaitBlit
	move.l	#$01000000,$40(a6)
	rts

.wblit3	and.w	#15,d2
	ror.w	#4,d2
	bra.w	WaitBlit

.wblit4	move.w	#$4014,$58(a6)
	bra.w	WaitBlit



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
.wait1	btst	#0,$dff005
	beq.b	.wait1
.wait2	btst	#0,$dff005
	bne.b	.wait2
	rts


***********************************
*** Level 2 IRQ			***
***********************************

SetLev2IRQ
	pea	.int(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode

	move.w	#1<<3,$dff09c			; clear ports interrupt
	move.w	#1<<15|1<<14|1<<3,$dff09a	; and enable it
	rts

.int	movem.l	d0-d1/a0-a2,-(a7)
	lea	$dff000,a0
	lea	$bfe001,a1


	btst	#3,$1e+1(a0)			; PORTS irq?
	beq.b	.end
	btst	#3,$d00(a1)			; KBD irq?
	beq.b	.end

	moveq	#0,d0
	move.b	$c00(a1),d0
	lea	Key(pc),a2
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)

	move.l	KbdCust(pc),d1
	beq.b	.nocustom
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.nocustom	
	


	or.b	#1<<6,$e00(a1)			; set output mode

	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	.quit
	

.nokeys	moveq	#3-1,d1
.loop	move.b	$6(a0),d0
.wait	cmp.b	$6(a0),d0
	beq.b	.wait
	dbf	d1,.loop


	and.b	#~(1<<6),$e00(a1)	; set input mode
.end	move.w	#1<<3,$9c(a0)
	move.w	#1<<3,$9c(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte

.quit	pea	(TDREASON_OK).w
	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	bra.w	KillSys



Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine



; ByteKiller binary
; a0.l: bytekiller binary
; ----
; a3.l: start of decrunched data

BK_DECRUNCH
	add.w	#9*4,a0			; skip hunk header

.normal	move.l	$4+2(a0),a1		; destination
	move.l	a1,a3
	move.l	$aa+2(a0),a6		; jmp address
	add.w	#$e8,a0			; crunched data

; Bytekiller decruncher
; resourced and adapted by stingray
;
; a0.l: source
; a1.l: destination

;BK_DECRUNCH
	bsr.b	.decrunch
	tst.l	d5
	beq.b	.ok

; checksum doesn't match, file corrupt
	pea	ErrText(pc)
	pea	(TDREASON_FAILMSG).w
	bra.w	EXIT

.ok	rts


.decrunch
	move.l	(a0)+,d0		; packed length
	move.l	(a0)+,d1		; unpacked length
	move.l	(a0)+,d5		; checksum
	add.l	d0,a0			; a0: end of packed data
	lea	(a1,d1.l),a2		; a2: end of unpacked data
	move.l	-(a0),d0		; get first long
	eor.l	d0,d5
.loop	lsr.l	#1,d0
	bne.b	.nonew1
	bsr.b	.nextlong
.nonew1	bcs.b	.getcmd

	moveq	#8,d1
	moveq	#1,d3
	lsr.l	#1,d0
	bne.b	.nonew2
	bsr.b	.nextlong
.nonew2	bcs.b	.copyunpacked

; data is packed, unpack and copy
	moveq	#3,d1			; next 3 bits: length of packed data
	clr.w	d4

; d1: number of bits to get from stream
; d4: length
.packed	bsr.b	.getbits
	move.w	d2,d3
	add.w	d4,d3
.copypacked
	moveq	#8-1,d1
.getbyte
	lsr.l	#1,d0
	bne.b	.nonew3
	bsr.b	.nextlong
.nonew3	addx.l	d2,d2
	dbf	d1,.getbyte

	move.b	d2,-(a2)
	dbf	d3,.copypacked
	bra.b	.next

.ispacked
	moveq	#8,d1
	moveq	#8,d4
	bra.b	.packed

.getcmd	moveq	#2,d1			; next 2 bits: command
	bsr.b	.getbits
	cmp.b	#2,d2			; %10: unpacked data follows
	blt.b	.notpacked
	cmp.b	#3,d2			; %11: packed data follows
	beq.b	.ispacked

; %10
	moveq	#8,d1			; next byte:
	bsr.b	.getbits		; length of unpacked data
	move.w	d2,d3			; length -> d3
	moveq	#12,d1
	bra.b	.copyunpacked

; %00 or %01
.notpacked
	moveq	#9,d1
	add.w	d2,d1
	addq.w	#2,d2
	move.w	d2,d3

.copyunpacked
	bsr.b	.getbits		; get offset (d2)
;.copy	subq.w	#1,a2
;	move.b	(a2,d2.w),(a2)
;	dbf	d3,.copy

; optimised version of the code above
	subq.w	#1,d2
.copy	move.b	(a2,d2.w),-(a2)
	dbf	d3,.copy

.next	cmp.l	a2,a1
	blt.b	.loop
	rts

.nextlong
	move.l	-(a0),d0
	eor.l	d0,d5
	move.w	#$10,ccr
	roxr.l	#1,d0
	rts

; d1.w: number of bits to get
; ----
; d2.l: bit stream

.getbits
	subq.w	#1,d1
	clr.w	d2
.getbit	lsr.l	#1,d0
	bne.b	.nonew
	move.l	-(a0),d0
	eor.l	d0,d5
	move.w	#$10,ccr
	roxr.l	#1,d0
.nonew	addx.l	d2,d2
	dbf	d1,.getbit
	rts


DEC_DESTINATION	dc.l	0
ErrText	dc.b	"Decrunching failed, file corrupt!",0



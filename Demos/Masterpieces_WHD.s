***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    MASTERPIECES/KEFRENS WHDLOAD SLAVE      )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            December 2020                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 28-Dec-2020	- 2 more SMC parts found and fixed
;		- keyboard problems fixed
;		- delay for title picture added (5 seconds)
;		- illegal copperlist entries fixed (DMA enabled too early)
;		- all decrunchers (ByteKiller) slightly optmised, relocated
;		  to fast memory and error check added

; 27-Dec-2020	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Exec/Exec.i
	INCLUDE	lvo/Exec.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem
QUITKEY		= $59		; F10
DEBUG

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
	dc.w	10		; ws_version
	dc.w	FLAGS		; flags
	dc.l	524288		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	IFD	DEBUG
	dc.w	.dir-HEADER	; ws_CurrentDir
	ELSE
	dc.w	0		; ws_CurrentDir
	ENDC
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_KeyDebug
	dc.b	QUITKEY		; ws_KeyExit
	dc.l	0		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
;	dc.w	0		; ws_kickname
;	dc.l	0		; ws_kicksize
;	dc.w	0		; ws_kickcrc

; v17
;	dc.w	.config-HEADER	; ws_config


;.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Kefrens/Masterpieces",0
	ENDC

.name	dc.b	"Masterpieces",0
.copy	dc.b	"1992 Kefrens",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (28.12.2020)",0
	CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; install level 2 interrupt
	bsr	SetLev2IRQ


	; load intro
	move.l	#14*$1600,d0
	move.l	#1*$1600,d1
	lea	$60000,a0

	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)
	move.l	d5,d0
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$E947,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

	lea	PLINTRO(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)


	; set copperlist 1 to start copperlist 2
	lea	$1000.w,a0
	move.w	#$008a,(a0)


	; set default interrupts
	pea	AckVBI(pc)
	move.l	(a7)+,$6c.w
	pea	AckLev6(pc)
	move.l	(a7)+,$78.w


	; run demo
	jmp	(a5)

	



QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)


KillSys	move.w	#$7fff,$dff09a
	bsr.b	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	rts


WaitRaster
.wait1	btst	#0,$dff005
	beq.b	.wait1
.wait2	btst	#0,$dff005
	bne.b	.wait2
	rts

AckVBI_R
	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rts

AckVBI	bsr.b	AckVBI_R
	rte

AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte

WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts

FlushCache
	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts
	


; ---------------------------------------------------------------------------

PLINTRO	PL_START
	PL_P	$ce,Load
	PL_PSS	$c0,AckVBI_R,2
	PL_P	$9a,.PatchMain
	PL_ORW	$54+2,1<<3		; enable level 2 interrupts
	PL_END


.PatchMain
	; show title picture for at least 5 seconds
	move.l	resload(pc),a2
	moveq	#5*10,d0
	jsr	resload_Delay(a2)


	pea	GetKey(pc)
	lea	KbdCust(pc),a0
	move.l	(a7)+,(a0)	

	lea	PLMAIN(pc),a0
	pea	$34000
	move.l	(a7),a1
	;move.l	resload(pc),a2
	jmp	resload_Patch(a2)


Load	mulu.w	#512*11,d0
	mulu.w	#512*11,d1
	moveq	#1,d2
	move.l	resload(pc),a1
	jmp	resload_DiskLoad(a1)


; ---------------------------------------------------------------------------

PLMAIN	PL_START
	PL_P	$1540,Load
	PL_PSS	$212,AckVBI_R,2
	PL_ORW	$60+2,1<<3		; enable level 2 interrupts
	PL_ORW	$d0+2,1<<3		; enable level 2 interrupts
	PL_ORW	$484+2,1<<3		; enable level 2 interrupts
	PL_P	$2858,AckLev6
	PL_SA	$cc,$d0			; don't enable DMA yet
	PL_PS	$e2,.EnableDMA
	PL_ORW	$28c+2,1<<3		; enable level 2 interrupts
	PL_ORW	$4952+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$4a5e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$603e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$614a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$6256+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$6362+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$646e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$657a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$6686+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$6792+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$689e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$69aa+2,1<<9		; set Bplcon0 color bit
	PL_PS	$1e16,.FlushCache
	PL_P	$1f08,.FlushCache2
	PL_PS	$594,.wblit
	PL_P	$e10,.FlushCache3
	PL_P	$1148,.FlushCache4
	PL_R	$2134			; disable keyboard routine in VBI
	PL_PS	$152,.DecrunchPicture
	PL_PS	$2a96,.DecrunchPicture	; scrolltext selector
	PL_END

.wblit	move.w	#$43ac,$58(a6)
	bra.w	WaitBlit

.FlushCache
	lea	$32db8,a4
	bra.w	FlushCache

.FlushCache2
	clr.b	$34000+$6e93
	bra.w	FlushCache

.FlushCache3
	jsr	$34000+$10ba
	bra.w	FlushCache

.FlushCache4
	bsr.b	.FlushCache3
	jmp	$34000+$872


.EnableDMA
	clr.b	$34000+$6e9d
	move.w	d0,$96(a6)
	rts

.DecrunchPicture
	lea	$3ff00+$e8,a0
	lea	$40000,a1
	bra.w	BK_DECRUNCH


GetKey	move.b	RawKey(pc),$34000+$69b2
	rts


; ---------------------------------------------------------------------------

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

	lea	Key(pc),a2
	move.b	$c00(a1),d0
	move.b	d0,(a2)

	not.b	d0
	ror.b	d0
	move.b	d0,RawKey-Key(a2)


	move.l	KbdCust(pc),d1
	beq.b	.noCust
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.noCust


	or.b	#1<<6,$e00(a1)			; set output mode

	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT

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



Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0


; Bytekiller decruncher
; resourced and adapted by stingray

BK_DECRUNCH
	bsr.b	.decrunch
	tst.l	d5
	beq.b	.ok

; checksum doesn't match, file corrupt
	pea	.ErrTxt(pc)
	pea	(TDREASON_FAILMSG).w
	move.l	resload(pc),a0
	jmp	resload_Abort(a0)


.ok	rts

.ErrTxt	dc.b	"Decrunching failed, file corrupt!",0
	cnop	0,4

.decrunch
	move.l	(a0)+,d0		; crunched length
	move.l	(a0)+,d1		; decrunched length
	move.l	(a0)+,d5		; checksum
	move.l	a1,a2
	add.l	d0,a0			; end of crunched data
	add.l	d1,a2			; end of decrunched data

	move.l	-(a0),d0
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



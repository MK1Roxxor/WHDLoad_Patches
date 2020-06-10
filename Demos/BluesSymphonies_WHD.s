***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(  BLUES SYMPHONIES/SKARLA WHDLOAD SLAVE     )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                               June 2020                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 10-Jun-2020	- using my optimised ByteKiller decruncher now
;		- SMC in the vector part fixed, runs with cache now
;		- interrupts in Prorunner replayer fixed

; 09-Jun-2020	- work started
;		- almost everything patched


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Exec/Exec.i
	INCLUDE	lvo/Exec.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_ReqAGA|WHDLF_Req68020
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
	dc.l	524288*4	; ws_BaseMemSize
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
	dc.b	"SOURCES:WHD_Slaves/Demos/Skarla/BluesSymphonies",0
	ENDC

.name	dc.b	"Blues Symphonies",0
.copy	dc.b	"1994 Skarla",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (10.06.2020)",0
	CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; install level 2 interrupt
	bsr	SetLev2IRQ

	; load crunched demo binary
	move.l	#$400,d0
	move.l	#$1b200,d1
	lea	$2a000-$64,a0

	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)
	move.l	d5,d0
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$2BD7,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT

.ok

	; decrunch
	move.l	a5,a0
	lea	$64(a0),a1
	move.l	a1,a5
	bsr	BK_DECRUNCH
	

	; patch
	lea	PLMAIN(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	; set default VBI
	pea	AckVBI(pc)
	move.l	(a7)+,$6c.w

	; and run
	jmp	8(a5)


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

AckLev6_R
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rts

AckLev6	bsr.b	AckLev6_R
	rte


FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d0
.loop	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait
	dbf	d0,.loop
	movem.l	(a7)+,d0/d1
	rts

; ---------------------------------------------------------------------------

PLMAIN	PL_START
	PL_PSA	$8238,.SetDisk1,$8262
	PL_PSA	$8296,.SetDisk2,$82c0
	PL_P	$369c,Load
	PL_P	$1e6,AckVBI
	PL_SA	$77d0,$77e2		; skip drive access and Forbid()
	PL_SA	$16a,$16c		; don't modify VBI code
	PL_L	$1512c,$c0000		; set memory pointer
	PL_L	$15130,$c0000+182000	; set memory pointer 2
	PL_R	$839c			; disable memory allocation
	PL_PSS	$2800,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$2816,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$2f40,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$2f56,FixDMAWait,2	; fix DMA wait in replayer
	PL_SA	$7ce0,$7cea		; skip Forbid()
	PL_ORW	$15140+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$153c0+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$15704+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1573c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$15754+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1576c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$15774+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$15898+2,1<<9		; set Bplcon0 color bit
	PL_L	$14f5a,-2		; terminate copperlist (title picture)
	;PL_PSS	$b316,.FixLine,2
	PL_ORW	$b2e2+2,1<<8		; fix BLTCON0 settings
	PL_PS	$b1dc,.FlushCache
	PL_PSS	$928,AckLev6_R,2
	PL_PS	$984,AckLev6_R
	
	PL_END

; rotation routine uses SMC
.FlushCache
	move.w	d1,$2a000+$b226
	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts


;.FixLine
;	move.w	d4,$48+2(a6)		; BLTC pointer, low
;	swap	d3
;	move.w	d3,$54+2(a6)		; BLTD pointer, low
;	swap	d3
;	move.w	d3,$58(a6)
;	rts


.SetDisk1
	moveq	#1,d0
	bra.b	.SetDisk

.SetDisk2
	moveq	#2,d0
.SetDisk
	lea	DiskNum(pc),a1
	move.b	d0,(a1)
	rts
	

Load	move.w	d6,d0
	move.w	d7,d1
	move.l	a1,a0
	mulu.w	#512*11,d0
	mulu.w	#512*11,d1
	move.b	DiskNum(pc),d2
	move.l	resload(pc),a1
	jmp	resload_DiskLoad(a1)


DiskNum	dc.b	1
	dc.b	0


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

	move.b	$c00(a1),d0
	not.b	d0
	ror.b	d0

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



; Bytekiller decruncher
; resourced and adapted by stingray
;
; a0.l: source
; a1.l: destination

BK_DECRUNCH
	bsr.b	.decrunch
	tst.l	d5
	beq.b	.ok

; checksum doesn't match, file corrupt
	pea	.ErrTxt(pc)
	pea	(TDREASON_FAILMSG).w
	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	
.ok	rts

.ErrTxt	dc.b	"Decrunching failed, file corrupt!",0
	cnop	0,4

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



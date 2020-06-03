***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(     DRUMS & PIPES/TRSI WHDLOAD SLAVE       )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             January 2018                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 23-Jan-2018	- work started
;		- and finished 50 minutes later, Bplcon0 color bit
;		  fixes (x20), interrupts fixed, INTENA and DMA settings
;		  fixed, timing fixed, reset patched to quit back to DOS,
;		  ByteKiller decruncher relocated, CPU dependent delay
;		  fixed, ButtonWait support for title pictures added

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
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
	dc.w	17		; ws_version
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
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"BW"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/TRSI/DrumsAndPipes",0
	ENDC

.name	dc.b	"Drums & Pipes",0
.copy	dc.b	"1991 TRSI",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (23.01.2018)",0
	CNOP	0,2


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

; install keyboard irq
	bsr	SetLev2IRQ

	lea	$2000.w,a7

; load intro
	move.l	#$b7000,d0
	move.l	#$8800,d1
	lea	$40000,a0
	move.l	d1,d5
	move.l	a0,a5
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)

	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$6b7a,d0
	beq.b	.ok

.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

; decrunch
	lea	$10c(a5),a0
	move.l	$28+2(a5),a1
	movem.l	a1/a2,-(a7)
	bsr	BK_DECRUNCH
	movem.l	(a7)+,a1/a2
	move.l	a1,a5

; patch
	lea	PLINTRO(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	pea	AckVBI(pc)
	move.l	(a7)+,$6c.w
	move.w	#$c028,$dff09a

	move.w	#$83c0,$dff096

; and start demo
	jmp	(a5)



AckVBI	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte


PLINTRO	PL_START
	PL_ORW	$426+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$4ce+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$556+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$5fe+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$636+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$642+2,1<<9		; set Bplcon0 color bit
	PL_SA	$a,$2e			; skip opening gfxlib + Forbid()
	PL_SA	$e2,$f6			; skip closing gfxlib + Permit()

	PL_IFBW	
	PL_P	$1b8,.loadmain_wait
	PL_ELSE
	PL_P	$1b8,.loadmain
	PL_ENDIF
	PL_P	$f6,.patchmain

	PL_PSA	$3e,WaitRaster,$48
	PL_PSA	$5c,.delay,$66		; fix CPU dependent delay
	PL_PSA	$6c,WaitRaster,$76
	PL_PSA	$98,WaitRaster,$a2
	PL_PSA	$b6,WaitRaster,$c0
	PL_PSA	$ca,WaitRaster,$d4

	PL_END

.delay	move.w	#$fffff/$34,d0
.loop	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait
	dbf	d0,.loop
	rts


.patchmain
	lea	$50000+$10c,a0
	lea	$25000,a1
	bsr	BK_DECRUNCH

	lea	PLMAIN(pc),a0
	pea	$25000
	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)


.loadmain_wait
	move.l	#60*10,d0
	move.l	resload(pc),a0
	jsr	resload_Delay(a0)
.loadmain
	lea	$50000,a0
	move.l	#$c0800,d0
	move.l	#$f200,d1
	moveq	#1,d2
	move.l	resload(pc),a1
	jmp	resload_DiskLoad(a1)




PLMAIN	PL_START
	PL_ORW	$3c28+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3cd0+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3d0c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3d64+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3e10+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3e48+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3e68+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3ea0+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3f64+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3f98+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$4048+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$4068+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$40a0+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$40a8+2,1<<9		; set Bplcon0 color bit
	PL_SA	$a,$2e			; skip opening gfxlib + Forbid()
	PL_SA	$3a0,$3d8		; skip opening trackdisk device
	PL_PSA	$40a,.load,$446
	PL_P	$bca,AckLev6
	PL_SA	$316,$320		; don't modify VBI code
	PL_P	$33c,AckVBI
	PL_P	$1f6,QUIT		; reset -> quit

	PL_PSA	$10a,WaitRaster,$114
	PL_PSA	$128,WaitRaster,$132
	PL_PSA	$17e,WaitRaster,$188

	PL_IFBW
	PL_PS	$7a,.wait
	PL_ENDIF

	PL_END

.wait	move.l	#60*10,d0
	move.l	resload(pc),a0
	jsr	resload_Delay(a0)

	moveq	#20,d0			; optimised original code
	rts


.load	move.l	$24(a1),d1		; len	
	move.l	$28(a1),a0		; destination
	move.l	$2c(a1),d0		; offset
	moveq	#1,d2
	move.l	resload(pc),a1
	jmp	resload_DiskLoad(a1)


AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte


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
.wait	btst	#0,$dff005
	beq.b	.wait
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
	beq.w	.end

	btst	#3,$d00(a1)			; KBD irq?
	beq.b	.end

	moveq	#0,d0
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


ErrText	dc.b	"Decrunching failed, file corrupt!",0



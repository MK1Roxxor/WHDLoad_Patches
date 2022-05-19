***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      AMAZING TUNES/SAE WHDLOAD SLAVE      )*)---.---.    *
*   `-./                                                          \.-'    *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            January 2012                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 19-May-2022	- interrupt problem fixed (Mantis issue #5629)
;		- delay in keyboard interrupt fixed
;		- ws_keydebug handling removed from keyboard interrupt
;		- unused taglist removed

; 29-Sep-2013	- fixed problems with freezing after loading tune
;		  (reported by Retroplay)
;		- error check added in ByteKiller decruncher

; 03-Jan-2012	- work started
;		- and finished a while later, it's 1:31 A.M. and
;		  I have to get up at 6:30 so off to bed for now

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
DEBUGKEY	= $58		; F9
QUITKEY		= $46		; DEL
;DEBUG

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM


HEADER	SLAVE_HEADER		; ws_security + ws_ID
	dc.w	10		; ws_version
	dc.w	FLAGS		; flags
	dc.l	524288		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	dc.w	.dir-HEADER	; ws_CurrentDir
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_keydebug
	dc.b	QUITKEY		; ws_keyexit
	dc.l	0		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info


.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/ShareAndEnjoy/AmazingTunes/data",0
	ELSE
	dc.b	"data",0
	ENDC
.name	dc.b	"Amazing Tunes",0
.copy	dc.b	"1988 Share and Enjoy",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	dc.b	"Version 1.02 (19.05.2022)",0
	CNOP	0,2


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

; install keyboard irq
	bsr	SetLev2IRQ

; load main
	lea	.name(pc),a0
	lea	$1000.w,a1
	move.l	a1,a5
	jsr	resload_LoadFile(a2)

; version check
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	lea	PLMAIN(pc),a4
	cmp.w	#$ea84,d0
	beq.b	.ok

; unknown version
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT


; decrunch
.ok	lea	$10c(a5),a0
	lea	$2b390,a1
	movem.l	d0-a6,-(a7)
	bsr	BK_DECRUNCH
	movem.l	(a7)+,d0-a6

	lea	Speed(pc),a3
	move.l	a3,$a4+4(a1)

; patch
	move.l	a4,a0
	move.l	a1,a5
	jsr	resload_Patch(a2)

	; initialise level 3 interrupt because demo enables
	; interrupts before level 3 interrupt vector has been set
	pea	Default_Level3_Interrupt(pc)
	move.l	(a7)+,$6c.w

; start
	jmp	(a5)


.name	dc.b	"sae",0
	CNOP	0,2

QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	jmp	resload_Abort(a2)





.setcop	move.l	#$3a000+$1d6,$dff080
	move.w	#1<<15+1<<9+1<<8+1<<7+1<<6,$dff096
	rts


PLMAIN	PL_START
	PL_P	$1632,FixAudXVol	; fix byte write to volume register
	PL_PSS	$17ce,FixDMAWait,2	; fix DMA wait in replayer
	PL_P	$1646,.setspeed
	PL_PSS	$14f6,.checkspeed,2
	PL_PSS	$614,.ackCop,2
	PL_SA	$1a4,$1ae		; don't modify interrupt code
	PL_SA	$18c,$196		; skip Forbid()
	PL_SA	$10,$2e			; skip gfxlib stuff
	PL_SA	$76,$90			; skip gfxlib stuff/cop init
	PL_PS	$90,.setcop
	PL_P	$494,.loadtune
	PL_SA	$16a,$17e		; skip gfxlib stuff/cop init
	PL_PS	$17e,.setcop2
	PL_P	$356,.getkey
	PL_SA	$366,$370		; skip Permit()
	PL_PSS	$386,.setcop3,2
	PL_P	$71a,.ackVBI
	PL_END


.ackVBI	move.w	#1<<5+1<<6,$dff09c
	move.w	#1<<5+1<<6,$dff09c
	rte

.setcop3
	lea	$dff080,a6
	rts

.getkey	move.b	RawKey(pc),d1
	rts

.loadtune
	move.w	#$7fff,$dff096		; disable all DMA to avoid problems
					; during loading (freeze)
	lea	$2b390+$47e,a0		; file name
	lea	$2b390+$28bb0,a1
	move.l	a1,a5
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)
	lea	$e8(a5),a0
	lea	$2b390+$1ab0,a1
	move.w	#1<<4,$dff09a
	bsr.w	BK_DECRUNCH
	move.w	#1<<15+1<<4,$dff09a
	rts


.checkspeed
	move.w	$2b390+$1a58,d0
	cmp.w	Speed(pc),d0
	rts

.setspeed
	move.l	a0,-(a7)
	lea	Speed(pc),a0
	move.w	d0,(a0)
	move.l	(a7)+,a0
	rts




.ackLev6
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte


.setcop	move.l	#$2b390+$cda,$dff080
.setDMA	move.w	#1<<15+1<<9+1<<8+1<<7+1<<6,$dff096
	rts

.setcop2
	move.l	#$2b390+$e26,$dff080
	bra.b	.setDMA




.ackCop	move.w	#1<<4,$dff09c
	move.w	#1<<4,$dff09c
	rts

Speed	dc.w	6

WaitRaster
	move.l	d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.b	.wait
	move.l	(a7)+,d0
	rts



FixDMAWait
	move.b	$dff006,d0
	addq.b	#5,d0
.wait	cmp.b	$dff006,d0
	bne.b	.wait
	rts

FixAudXVol
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts


Default_Level3_Interrupt
	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte

***********************************
*** Level 2 IRQ			***
***********************************

SetLev2IRQ
	pea	Lev2(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode

	move.w	#1<<3,$dff09c			; clear ports interrupt
	move.w	#1<<15|1<<14|1<<3,$dff09a	; and enable it
	rts

Lev2	movem.l	d0-d1/a0-a2,-(a7)
	lea	$dff000,a0
	lea	$bfe001,a1

	btst	#3,$1e+1(a0)			; PORTS irq?
	beq.b	.end
	btst	#3,$d00(a1)			; KBD irq?
	beq.b	.end

	lea	Key(pc),a2
	move.b	$c00(a1),d0
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)

	or.b	#1<<6,$e00(a1)			; set output mode

	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	.exit

.nokeys
	moveq	#3-1,d1
.loop	move.b	$6(a0),d0
.wait	cmp.b	$6(a0),d0
	beq.b	.wait
	dbf	d1,.loop


	and.b	#~(1<<6),$e00(a1)	; set input mode
.end	move.w	#1<<3,$9c(a0)
	move.w	#1<<3,$9c(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte

.debug	pea	(TDREASON_DEBUG).w
.quit	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	bra.b	KillSys
.exit	pea	(TDREASON_OK).w
	bra.b	.quit


KillSys	move.w	#$7fff,$dff09a
	bsr	WaitRaster
	move.w	#$7fff,$dff09c
	move.w	#$07ff,$dff096
	rts

Key	dc.b	0
RawKey	dc.b	0


; Bytekiller decruncher
; resourced and adapted by stingray
;
; a0.l: source
; a1.l: destination
; ----
; a5.l: load address (start of decrunched data)
; a6.l: jmp address

BK_DECRUNCH
	bsr.b	.decrunch
	tst.l	d5
	beq.b	.ok

; checksum doesn't match, file corrupt
	pea	ErrText(pc)
	pea	(TDREASON_FAILMSG).w
	bra.w	EXIT

.ok	move.l	$aa+2(a5),a6
	move.l	$4+2(a5),a5
	rts


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
;	move.l	CUSTOM1(pc),d1
;	beq.b	.noflash
;	move.w	d3,$dff180
.noflash
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


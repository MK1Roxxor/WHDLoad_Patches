***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(     LEGEND OF THE LOST WHDLOAD SLAVE       )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                               May 2013                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 03-Mar-2013	- work started
;		- CPU dependent delays fixed, all OS stuff patched,
;		  trainers added (unlimited lives, select starting level),
;		  intros can be skipped with CUSTOM1, delays after loading
;		  and in init part removed, interrupts fixed, ByteKiller
;		  decruncher relocated to fast memory, CIA access fixed

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
DEBUGKEY	= $58		; F9
QUITKEY		= $59		; F10
;DEBUG

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
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


.config	dc.b	"C1:B:Disable Intros;"
	dc.b	"C2:B:Unlimited Lives;"
	dc.b	"C3:L:Start at Level:1,2,3,4,5,6,7"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/LegendOfTheLost/data",0
	ELSE
	dc.b	"data",0
	ENDC
.name	dc.b	"Legend of the Lost",0
.copy	dc.b	"1990 Impressions",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (03.05.2013)",0

	CNOP	0,2


TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
NOINTROS	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
LIVESTRAINER	dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET
STARTLEVEL	dc.l	0
		dc.l	TAG_END


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


; install keyboard irq
	bsr	SetLev2IRQ

; load game
	lea	.name(pc),a0
	lea	$1000.w,a1
	move.l	a1,a5
	jsr	resload_LoadFile(a2)
	
; version check
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	lea	PLGAME(pc),a3
	cmp.w	#$6019,d0		; SPS 2971
	beq.b	.ok

; unknown version
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok	


; relocate
	move.l	a5,a0
	sub.l	a1,a1
	jsr	resload_Relocate(a2)


; patch
	tst.l	LIVESTRAINER-PLGAME(a3)
	bne.b	.trainer
; unlimited lives no selected -> disable trainer
	clr.w	PLGAME\.TRAINER-PLGAME(a3)
	
.trainer
	move.l	a3,a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

	move.l	NOINTROS(pc),d0
	beq.b	.dointros
	lea	PLSKIPINTROS(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

.dointros


; and start
	move.w	#$83c0,$dff096
	jmp	(a5)


.name	dc.b	"b_legend",0
	CNOP	0,4
QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	jmp	resload_Abort(a2)


; disable intros
PLSKIPINTROS
	PL_START
	PL_R	$d834
	PL_R	$d10a
	PL_R	$4768
	PL_R	$d176
	PL_R	$d3e4
	PL_END

PLGAME	PL_START
	PL_SA	$51e4,$51e8		; skip Exec access
	PL_SA	$51f0,$5204		; skip FindTask() stuff
	PL_P	$5540,.ackVBI
	PL_R	$5020			; disable DOS library opening
	PL_PS	$52e4,.ackLev4
	PL_P	$507e,.loadfile
	PL_R	$5d10			; disable input.device stuff
	PL_P	$5872,.wait2frames	; fix CPU dependent delay
	PL_P	$583c,WaitRaster	; fix CPU dependent delay
	PL_P	$598c,BK_DECRUNCH	; relocate ByteKiller decruncher
	PL_SA	$52cc,$52d0		; remove long delay after file loading
	PL_SA	$18,$1e			; skip long delay in init part
	PL_PSS	$2e,.setlevel,2
	PL_SA	$58e4,$58f2		; skip bfe2ff access
	PL_L	$58f2+2,$bfe001		; $bfe00f -> $bfe001


.TRAINER
	PL_W	$6338+2,0
	PL_W	$6482+2,0
	PL_W	$65d4+2,0
	PL_W	$7852+2,0
	PL_W	$7a46+2,0
	PL_W	$7b90+2,0
	PL_W	$8f28+2,0
	PL_END

.wait2frames
	bsr	WaitRaster
	bra.w	WaitRaster

.setlevel
	move.w	STARTLEVEL+2(pc),$1000+$381c.w
	addq.w	#1,$1000+$381c.w
	rts


	
.loadfile
	movem.l	d0-a6,-(a7)
	move.l	$1000+$51b4.w,a0
	move.l	$1000+$51bc.w,a1
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)
	movem.l	(a7)+,d0-a6
	rts

.ackLev4
	move.w	$dff01e,d0
	move.w	#$780,$dff09c
	rts

.ackVBI	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rte

FixAudXVol
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts

FixDMAWait
	move.l	d0,-(a7)
	move.b	$dff006,d0
	addq.b	#5,d0
.wait	cmp.b	$dff006,d0
	bne.b	.wait
	move.l	(a7)+,d0
	rts

WaitRaster
	move.l	d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.b	.wait
.wait2	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	beq.b	.wait2
	move.l	(a7)+,d0
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
	beq.w	.end

	moveq	#0,d0
	move.b	$c00(a1),d0
	lea	Key(pc),a2
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)

; level skipper disabled because of graphics errors
;	cmp.b	#$36,d0
;	bne.b	.noN
;	move.w	#1,$1000+$381a
;	move.w	#1,$1000+$3818
;.noN

	move.l	KbdCust(pc),d1
	beq.b	.nocustom
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.nocustom	


	or.b	#1<<6,$e00(a1)			; set output mode

	cmp.b	HEADER+ws_keydebug(pc),d0	
	bne.b	.nodebug
	movem.l	(a7)+,d0-d1/a0-a2
	move.w	(a7),6(a7)			; sr
	move.l	2(a7),(a7)			; pc
	clr.w	4(a7)				; ext.l sr
	bra.b	.debug


.nodebug
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	.exit
	

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

.debug	pea	(TDREASON_DEBUG).w
.quit	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.exit	pea	(TDREASON_OK).w
	bra.b	.quit


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine






; Bytekiller decruncher
; resourced and adapted by stingray
;
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
	move.l	-(a0),d5
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
.nonew3	roxl.l	#1,d2
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
.nonew	roxl.l	#1,d2
	dbf	d1,.getbit
	rts






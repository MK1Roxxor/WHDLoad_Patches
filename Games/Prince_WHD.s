***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(          PRINCE WHDLOAD SLAVE              )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            February 2014                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 12-Aug-2019	- a few SMC patches corrected (Mantis #4179)

; 09-Feb-2014	- lots of SMC fixed
;		- load/save support
;		- mouse clipping fixed (access fault)
;		- a lot more 24 bit problems fixed, really ugly code!
;		- stack frame fixes simplified
;		- sample player finally fixed, lots of hours wasted...
;		- buttonwait support added, if enabled sample will be
;		  played until left mouse button is pressed, needed because
;		  in the original game the sampe is playing while loading
;		  data from disk
;		- game disabled CIA interrupts so no quit on 68000 was
;		  possible, fixed

; 08-Feb-2014	- 24 bit problem fixed, main menu is displayed correctly
;		  now
;		- fixed more 24 bit problems, games uses jump tables with
;		  only the low word of the destination address being valid,
;		  upper word is used for data storage...
;		- changed the stack frame fixes but the sample (title) is
;		  still not played correctly

; 05-Feb-2014	- work started


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


.config	dc.b	"BW"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Prince/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Prince",0
.copy	dc.b	"1989 Arc",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.01 (12.08.2019)",0
Name	dc.b	"Prince0",0
SaveName	dc.b	"Prince.save",0
	CNOP	0,2


TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	WHDLTAG_BUTTONWAIT_GET
BUTTONWAIT	dc.l	0
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
	lea	Name(pc),a0
	lea	$400.w,a1
	move.l	a1,a5
	jsr	resload_LoadFile(a2)

	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$42ea,d0		; SPS 1729
	beq.b	.ok

.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

; patch
	lea	PLMAIN(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

; init traps used to fix the stack errors
	lea	Trap0(pc),a0
	move.l	a0,$80.w

	lea	Trap1(pc),a0
	move.l	a0,$84.w

; and start
	lea	$400.w,a7
	jmp	(a5)


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)


KillSys	move.w	#$7fff,$dff09a
	bsr	WaitRaster
	move.w	#$7fff,$dff096
	move.w	#$7fff,$dff09c
	rts

AckVBI	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rte
AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte


; fixes for audio interrupt code that is called with bsr
Trap0	jmp	$400+$16c6.w

Trap1	jmp	$400+$17b0.w



InitAud	move.w	#$80,$9c(a6)
	jmp	$400+$172a.w


LoadSamples
	lea	Name(pc),a0
	move.b	#"2",6(a0)
	lea	$11c00,a1
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)
	lea	Name(pc),a0
	move.b	#"3",6(a0)
	lea	$1ac00,a1
	jsr	resload_LoadFile(a2)

	trap	#0			; init level 4 interrupt

	move.l	BUTTONWAIT(pc),d0
	beq.b	.nowait

.LMB	btst	#6,$bfe001
	bne.b	.LMB	

.release
	btst	#6,$bfe001
	beq.b	.release


.nowait	rts


PLMAIN	PL_START
	PL_SA	$cc6,$cd4		; don't disable CIA interrupts


	PL_PSA	$d22,LoadSamples,$d3a	; load both samples at once!

	;PL_L	$d2a,$4e404e71		; trap 0, nop
	PL_L	$592,$4e414e71		; trap 1, nop
	PL_L	$d36,$4e414e71		; trap 1, nop
	PL_L	$b0c,$4e404e71		; trap 0, nop

	PL_W	$16d8,$3d7c		; move.w #7,$96.w -> move.w #7,$96(a6)
	PL_W	$17d2,$426e		; clr.w $a8.w -> $clr.w $a8(a6)


	PL_P	$1700,InitAud

	PL_SA	$bf4,$c14		; don't change exception vectors
	PL_ORW	$c1c+2,1<<3		; enable level 2 interrupt
	PL_PSS	$db4,.ackVBI,2
	PL_PSS	$101a,.ackVBI,2
	PL_P	$10b2,.load1
;	PL_P	$10d4,.load3
;	PL_P	$10fa,.load2

	PL_PS	$21f0,.fix24bit

	PL_PS	$53d8,.fix1
	PL_PS	$5410,.fix2
	PL_PS	$5430,.fix2
	

; SMC fixes
	PL_PS	$22ba,.fixSMC1
	PL_PS	$2328,.fixSMC2
	PL_PS	$2378,.fixSMC3
	PL_PS	$23f4,.fixSMC4
	PL_PS	$2498,.fixSMC5
	PL_PS	$24e8,.fixSMC6
	PL_PS	$2590,.fixSMC7
	PL_PS	$2624,.fixSMC8
	PL_PS	$269a,.fixSMC9
	PL_PS	$2744,.fixSMC10
	PL_PS	$2810,.fixSMC11
	PL_PS	$2884,.fixSMC12

	PL_PSS	$331a,.fixSMC13,2
	PL_PSS	$332c,.fixSMC14,2
	PL_PSS	$5510,.fixSMC15,2
	PL_PS	$5640,.fixSMC16
	PL_PSS	$56b6,.fixSMC17,2
	PL_PSS	$56c4,.fixSMC18,2
	PL_PSS	$57ce,.fixSMC19,2
	

; load/save game
	PL_P	$1206,.loadgame
	PL_P	$13b8,.savegame

	PL_W	$4a6+2,320-10		; fix mouse x-clipping
	PL_W	$572+2,320-10		; fix mouse x-clipping
	PL_W	$42f4+2,320-10		; fix mouse x-clipping
	PL_W	$450e+2,320-10		; fix mouse x-clipping
	

	PL_PS	$3a30,.fix24bit_2
	PL_PSS	$62a8,.fix24bit_3,2
	PL_PS	$65c6,.fix24bit_4
	PL_PS	$64c4,.fix24bit_5
	PL_PSS	$64e8,.fix24bit_6,2

	PL_END

	


.fix24bit_6
	and.l	#$fffff,d1
	move.l	d1,a1
	moveq	#0,d0
	move.b	5(a1),d0
	rts

.fix24bit_5
	move.l	(a6),d0
	and.l	#$fffff,d0
	st	(a6)
	move.l	d0,a0
	rts	

.fix24bit_4
	add.w	d0,a0
	move.l	0(a0),d0
	and.l	#$fffff,d0
	rts	

.fix24bit_3
	move.l	0(a1),d0
	and.l	#$fffff,d0
	move.l	d0,a3
	moveq	#0,d0
	move.b	5(a3),d0
	rts


.loadgame
	lea	SaveName(pc),a0
	move.l	resload(pc),a2
	movem.l	a0/a1,-(a7)
	jsr	resload_GetFileSize(a2)
	movem.l	(a7)+,a0/a1
	tst.l	d0
	beq.b	.nogame
	jmp	resload_LoadFile(a2)

.nogame	moveq	#-1,d0
	rts

.savegame
	move.l	a0,a1
	lea	SaveName(pc),a0
	move.l	#4*$1400,d0
	move.l	resload(pc),a2
	jmp	resload_SaveFile(a2)



.fixSMC19
	move.b	0(a1),d0
	and.b	#1,d0
	bra.b	.flush

.fixSMC18
	move.b	#$67,$400+$56f6.w
	bra.b	.flush

.fixSMC17
	move.b	#$66,$400+$56f6.w
	bra.b	.flush

.fixSMC16
	move.b	d1,$400+$5658.w
	bra.b	.flush
	

.fixSMC15
	move.l	4(a0),a2
	move.b	0(a2),d0
	bra.b	.flush

.fixSMC14
	move.b	#$66,$400+$333e.w
	bra.b	.flush

.fixSMC13
	move.b	#$67,$400+$333e.w
	bra.b	.flush

.fixSMC12
	move.w	(a4),$400+$28c2.w
	bra.b	.flush

.fixSMC11
	move.w	(a4),$400+$284c.w
	bra.b	.flush

.fixSMC10
	move.w	(a4),$400+$27a2.w
	bra.b	.flush

.fixSMC9
	move.w	(a4),$400+$26d8.w
	bra.b	.flush

.fixSMC8
	move.w	(a4),$400+$2662.w
	bra.b	.flush

.fixSMC7
	move.w	(a4),$400+$25d6.w
	bra.b	.flush
	
.fixSMC6
	move.w	(a4),$400+$251a.w
	bra.b	.flush

.fixSMC5
	move.w	(a4),$400+$24c8.w
	bra.b	.flush
	
.fixSMC4
	move.w	(a4),$400+$2442.w
	bra.b	.flush

.fixSMC3
	move.w	(a4),$400+$23aa.w
	bra.b	.flush

.fixSMC2	
	move.w	(a4),$400+$2358.w
	bra.b	.flush

.fixSMC1
	move.w	(a4),$400+$22f2.w
.flush	move.l	a0,-(a7)
	move.l	resload(pc),a0
	jsr	resload_FlushCache(a0)
	move.l	(a7)+,a0
	rts


.fix1	move.l	4(a1,d0.w),a6
	bra.b	.execute


.fix2	move.l	(a1,d0.w),a6
.execute
	bsr	.FixA6
	jsr	(a6)
	rts


.FixA6	move.l	d1,-(a7)
	move.l	a6,d1
	and.l	#$fffff,d1
	move.l	d1,a6
	move.l	(a7)+,d1
	rts

.fix24bit
	and.w	#512-1,d2
	add.w	d2,a2
	move.l	a2,d2
	;and.l	#$3fffffff,d2
	and.l	#$fffff,d2
	move.l	d2,a2
	rts

.fix24bit_2
	and.w	#512-1,d5
	add.w	d5,a3
	move.l	a3,d5
	and.l	#$fffff,d5
	move.l	d5,a3
	rts

.audint	move.l	a6,-(a7)
	lea	$dff000,a6
	clr.w	$400+$7704.w
	move.w	#$80,$9a(a6)
	move.w	#$80,$0c(a6)
	move.w	#1,$96(a6)
	clr.w	$a8.w
	move.l	(a7)+,a6
	rts

.ackVBI	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rts

;.load2	moveq	#"2",d0
;	bra.b	.load
;
;.load3	moveq	#"3",d0
;	bra.b	.load

.load1	moveq	#"1",d0

.load	lea	Name(pc),a0
	move.b	d0,6(a0)
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)
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


FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d1	
.loop	move.b	$dff006,d0
.wait	cmp.b	$dff006,d0
	beq.b	.wait
	dbf	d1,.loop
	movem.l	(a7)+,d0/d1
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
	bra.w	EXIT

.exit	bra.w	QUIT


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine




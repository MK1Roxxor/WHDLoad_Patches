***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(INTERNATIONAL SPORTS CHALLENGE WHDLOAD SLAVE)*)---.---.   *
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

; 28-Apr-2020	- crash in diving event fixed, caused by useless SMC

; 20-Feb-2014	- keyboard didn't work on 68000 machines at the "enter
;		  name" screen, thanks to retrogamer for reporting

; 03-Feb-2014	- fixed remaining events (cycling, skeeting, show jumping,
;		  shooting)
;		- fixed high score load/save, wrong base address used
;		  ($100 instead of $174) which made the marathon event
;		  crash

; 02-Feb-2014	- work started
;		- game works but only the diving and swimming events have
;		  been patched, others need to have at least the keyboard
;		  interrupt fixed
;		- access fault when starting dive event fixed, byte
;		  write to CopCon in dive event fixed


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap|WHDLF_NoDivZero
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
	dc.l	524288		; ws_ExpMem
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
	dc.b	"SOURCES:WHD_Slaves/IntSportsChallenge/"
	ENDC
	dc.b	"data",0

.name	dc.b	"International Sports Challenge",0
.copy	dc.b	"1992 Empire",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.02 (28.04.2020)",0
Name	dc.b	"boot.prg",0
HiName	dc.b	"high.dat",0
	CNOP	0,2


TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
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
	lea	$100-$20-6.w,a1		; $20: hunk header
	move.l	a1,a5
	jsr	resload_LoadFile(a2)

	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$f944,d0		; SPS 2815
	beq.b	.ok

.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok	add.w	#$20,a5			; skip hunk header, a5: $100.w


; relocate
	lea	$5E(a5),a0
	move.l	a0,d0
	lea	$7A(a5),a1
	move.l	a1,a2
	move.l	a1,d0
	add.l	$60(a5),a1
	move.l	(a1)+,d1
	beq.b	.done
	add.l	d1,a2
	add.l	d0,(a2)
	moveq	#1,d1
	moveq	#0,d2
.loop	move.b	(a1)+,d2
	beq.b	.done
	cmp.w	d1,d2
	bne.b	.rel
	lea	$FE(a2),a2
	bra.b	.loop

.rel	add.l	d2,a2
	add.l	d0,(a2)
	bra.b	.loop

.done
	add.w	#$7a,a5

; patch
	lea	PLGAME(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)


; and start
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

PLSKEET	PL_START
	PL_PSA	$43f4,.setkbd,$43fe	; ; don't install new level 2 interrupt
	PL_PSS	$2f90,FixDMAWait,2	; fix DMA wait in sample player
	PL_PSS	$3024,FixDMAWait,2	; fix DMA wait in sample player
	PL_PSS	$30e2,FixDMAWait,2	; fix DMA wait in sample player
	PL_PSS	$3178,FixDMAWait,2	; fix DMA wait in sample player
	PL_END

.setkbd	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts

.kbdcust
	move.b	Key(pc),d0
	move.l	RelocStart(pc),a0
	jmp	$46e0(a0)



PLCYCLE	PL_START
	PL_PSA	$98da,.setkbd,$98e4	; ; don't install new level 2 interrupt
	PL_PSS	$8490,FixDMAWait,2	; fix DMA wait in sample player
	PL_PSS	$8524,FixDMAWait,2	; fix DMA wait in sample player
	PL_PSS	$85e2,FixDMAWait,2	; fix DMA wait in sample player
	PL_PSS	$8678,FixDMAWait,2	; fix DMA wait in sample player
	PL_END

.setkbd	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts

.kbdcust
	move.b	Key(pc),d0
	move.l	RelocStart(pc),a0
	add.l	#$9bfc,a0
	jmp	(a0)


PLSHOW	PL_START
	PL_PSA	$7b06,.setkbd,$7b10	; don't install new level 2 interrupt
	PL_PSS	$66b0,FixDMAWait,2	; fix DMA wait in sample player
	PL_PSS	$6744,FixDMAWait,2	; fix DMA wait in sample player
	PL_PSS	$6802,FixDMAWait,2	; fix DMA wait in sample player
	PL_PSS	$6898,FixDMAWait,2	; fix DMA wait in sample player
	PL_END

.setkbd	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts

.kbdcust
	move.b	Key(pc),d0
	move.l	RelocStart(pc),a0
	jmp	$7e28(a0)


PLSHOOT	PL_START
	PL_PSA	$771e,.setkbd,$773c	; don't install new level 1&2 interrupt
	PL_PSS	$6b3e,.delay,2		; fix DMA wait in sample player
	PL_PSS	$6b60,.delay,2		; fix DMA wait in sample player
	PL_END

.delay	bsr	FixDMAWait
	bra.w	FixDMAWait

.setkbd	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts

.kbdcust
	move.b	Key(pc),d0
	move.l	RelocStart(pc),a0
	jmp	$79fa(a0)
	
PLSWIM	PL_START
	PL_P	$c56,.ackVBI
	PL_P	$c86,.ackVBI
	PL_P	$c2e,.ackCOP
	PL_P	$c22,.ackBLT
	PL_P	$1641c,AckVBI

	PL_AW	$a+4,1			; $dff004->$dff005
	PL_ORW	$52+2,1<<3		; enable level 2 interrupt

	PL_P	$5e24,FixDMAWait
	PL_P	$5e84,FixDMAWait

	PL_PSA	$16474,.getkey,$1648e
	PL_R	$164a4
	PL_END

.getkey	moveq	#0,d0
	move.b	Key(pc),d0
	rts


.ackCOP	move.w	#1<<4,$9c(a6)
	move.w	#1<<4,$9c(a6)
	rte

.ackVBI	move.w	#1<<5,$9c(a6)
	move.w	#1<<5,$9c(a6)
	rte

.ackBLT	move.w	#1<<6,$9c(a6)
	move.w	#1<<6,$9c(a6)
	rte


PLDIVE	PL_START
	PL_PSS	$5728,.delay,2		; fix DMA wait in sample player
	PL_PSA	$4cf2,.fixcop,$4cfa	; fix byte write to CopCon
	PL_SA	$48ba,$48c4		; don't set new level 2 interrupt
	PL_PS	$48ce,.setkbd
	PL_R	$4b96			; end keyboard interrupt

	; V1.02, fix crash caused by SMC
	PL_PSA	$4eb4,.call,$4ec6
	PL_PSA	$4f10,.call,$4f22
	PL_END

; original code is like this:
; move.l (a4,d1.w),a4
; move.l (a4,d2.w),.jsr+2
; jsr	$fffffffe
;
; we do it properly without SMC and not using any extra registers! :)

.call	move.l	(a4,d1.w),a4
	move.l	(a4,d2.w),-(a7)
	rts


.setkbd	move.l	a0,-(a7)
	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	move.l	(a7)+,a0
	move.w	#$c028,$9a(a5)		; original code
	rts

.kbdcust
	clr.w	$6fffe
	move.l	RelocStart(pc),a0
	lea	$4b7e(a0),a1
	add.l	#$5cac,a0
	move.b	RawKey(pc),d0
	jmp	(a1)
	

.fixcop	move.w	#0,$2e(a5)
	move.l	d0,$80(a5)
	rts

.delay	bsr	FixDMAWait
	bra.w	FixDMAWait


PLGAME	PL_START
	PL_P	$65cc,.ackLev1
	PL_P	$664c,.setkbd		; don't install new level 2 interrupt
;	PL_SA	$6,$6c			; skip ext. mem check
	PL_PSA	$6,.setext,$6c		; set ext. mem
	PL_PSA	$1b2,.loadhighscores,$1d0
	PL_P	$c40,.savehighscores
	PL_P	$9e0a,.loadfile
	PL_PSS	$6132,FixDMAWait,2	; fix DMA wait in replayer
	PL_P	$9c94,Decrunch		; relocate decruncher
	PL_R	$2c3a			; disable disk request
	PL_W	$3540,0			; disable protection check
	PL_P	$2a9e,.flush		; flush cache after relocation

; fix access fault when selecting dive
	PL_PS	$296a,.music_off
	PL_AB	$297a+1,$be-$a6		; skip delay and music fade

	PL_END

.music_off
	jmp	$174+$5f7e.w		; mt_end

.flush	
	move.l	resload(pc),a2

	lea	RelocStart(pc),a1
	move.l	d0,(a1)
	
	move.l	d0,a1
	sub.l	a0,a0
	cmp.w	#$422d,$4cf2(a1)
	bne.b	.nodive
	lea	PLDIVE(pc),a0
.nodive

	cmp.w	#$4e40,(a1)
	bne.b	.noswim
	lea	PLSWIM(pc),a0
.noswim

	cmp.w	#$c8,2(a1)
	bne.b	.noshoot
	lea	PLSHOOT(pc),a0
.noshoot

	cmp.w	#$2b80,2(a1)
	bne.b	.noshow
	lea	PLSHOW(pc),a0
.noshow

	cmp.w	#$2b6e,2(a1)
	bne.b	.nocycle
	lea	PLCYCLE(pc),a0
.nocycle

	cmp.w	#$6a,2(a1)
	bne.b	.noskeet
	lea	PLSKEET(pc),a0
.noskeet

	move.l	a0,d1
	beq.b	.nopatch		; this should never happen
	jsr	resload_Patch(a2)
	bra.b	.out

.nopatch
	jsr	resload_FlushCache(a2)
.out	movem.l	(a7)+,d0-d7/a1-a6
	rts

.setext	move.l	HEADER+ws_ExpMem(pc),a0
	move.l	#$7f000,d0
	rts

.loadhighscores
	move.l	resload(pc),a2
	lea	HiName(pc),a0
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nohigh
	
	lea	HiName(pc),a0
	lea	$174+$11060,a1
	jmp	resload_LoadFile(a2)

.nohigh	rts

.savehighscores
	lea	HiName(pc),a0
	lea	$174+$11060,a1
	move.l	#$11260-$11060,d0
	move.l	resload(pc),a2
	jmp	resload_SaveFile(a2)


.ackLev1
	move.w	d0,$9c(a0)
	move.w	d0,$9c(a0)
	movem.l	(a7)+,d0/a0
	rte


; a0.l: file name
; d0.l: destination
; d1.l: ??? (doesn't seem to be used anyway)

.loadfile
	movem.l	d0-a6,-(a7)
	move.l	d0,a1
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)
	movem.l	(a7)+,d0-a6
	rts


.setkbd	bsr	SetLev2IRQ		; re-install level 2 interrupt
	move.l	a0,-(a7)
	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	move.l	(a7)+,a0
	rts

.kbdcust
	move.b	Key(pc),d0
	jmp	$174+$66e8.w


RelocStart	dc.l	0

; a0.l: source

Decrunch
	movem.l	d0/d1/a0-a2,-(sp)
	move.l	(a0)+,d0		; decrunched size
	move.l	(a0)+,d1		; crunched size
	lea	(a0,d1.l),a1
	lea	(a0,d0.l),a2
	lea	$400(a2),a2
	subq.l	#1,d1
.relocate
	move.b	-(a1),-(a2)
	dbf	d1,.relocate
	sub.l	#$10000,d1
	bpl.b	.relocate

	lea	-8(a0),a1
	move.l	a2,a0
.loop	move.b	(a0)+,d0
	bmi.b	.packed
	and.w	#$FF,d0
.copy	move.b	(a0)+,(a1)+
	dbf	d0,.copy
	bra.b	.loop



.packed	ext.w	d0
	lea	(a1,d0.w),a2
	move.b	(a0)+,d0
	beq.b	.done
	and.w	#$FF,d0
	subq.w	#1,d0
.copy2	move.b	(a2)+,(a1)+
	dbf	d0,.copy2
	bra.b	.loop

.done	movem.l	(sp)+,d0/d1/a0-a2
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
KbdCust	dc.l	0			; ptr to custom routine




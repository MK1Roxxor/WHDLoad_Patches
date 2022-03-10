***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(           CABAL WHDLOAD SLAVE              )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              August 2016                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 30-Aug-2016	- some more trainer options and in-game keys added
;		- high-score saving disabled if any trainers are used

; 29-Aug-2016	- work started
;		- lots of blitter waits added, joypad support added,
;		  Bplcon0 color bit fixes, DMA waits in sample player and
;		  replayer fixed, byte write to volume register fixed, 
;		  interrupts fixed, ByteKiller decruncher relocated and
;		  optimised, write to $dff0f8 disabled, keyboard routine
;		  recoded, 68000 quitkey support
;		- joypad: fire 2: throw grenades, play: toggle pause,
;		  in main menu: fire 1: start single player game, fire 2:
;		  start 2 player game


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


.config	dc.b	"C1:X:Unlimited Lives:0;"
	dc.b	"C1:X:Unlimited Energy:1;"
	dc.b	"C1:X:Unlimited Grenades:2;"
	dc.b	"C1:X:Invulnerability:3;"
	dc.b	"C1:X:In-Game Keys:4;"
	dc.b	"C2:L:Start at Level:1,2,3,4,5,6,7,8,10,11,12,13,14,"
	dc.b	"15,16,17,18,19,20,21,22;"
	dc.b	"C3:B:Enable Joypad support;"
	dc.b	"C4:B:Disable Blitter Wait Patches:"
	dc.b	0


.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Cabal",0
	ENDC

.name	dc.b	"Cabal",0
.copy	dc.b	"1989 Ocean",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.2a (30.08.2016)",0

HighName	dc.b	"Cabal.high",0

	CNOP	0,4


TAGLIST		dc.l	WHDLTAG_CUSTOM1_GET
TRAINEROPTIONS	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
STARTLEVEL	dc.l	0
		dc.l	TAG_DONE

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

; install keyboard irq
	bsr	SetLev2IRQ

; load boot
	moveq	#0,d0
	move.l	#$400,d1
	moveq	#1,d2
	lea	$2000.w,a0
	move.l	a0,a5
	move.l	d1,d5
	jsr	resload_DiskLoad(a2)

	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$41b4,d0		; SPS 638
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
.ok


; patch it
.patch	lea	PLBOOT(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)


; set default DMA
	move.w	#$83c0,$dff096

	lea	$2500.w,a1		; IOStd

; set default VBI
	pea	AckVBI(pc)
	move.l	(a7)+,$6c.w

; and start the game
	jmp	3*4(a5)


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)


KillSys	move.w	#$7fff,$dff09a
	bsr	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	rts




PLBOOT	PL_START
	PL_PSS	$50,.load,4
	PL_PSS	$88,.load,4
	PL_PSS	$e0,.load,4
	PL_PSS	$102,.load,4
	PL_PSS	$124,.load,4
	PL_P	$134,BK_DECRUNCH	; relocate ByteKiller decruncher
	PL_PS	$5e,.patchocean
	PL_PS	$ae,.patchintro
	PL_P	$12e,.patchgame
	PL_END

.patchgame
	lea	HighName(pc),a0
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nohigh
	lea	HighName(pc),a0
	lea	$12000,a1
	jsr	resload_LoadFile(a2)
.nohigh

	move.l	STARTLEVEL(pc),d0
	beq.b	.skip
	addq.w	#1,d0
	move.w	d0,$23000+$2e+2
.skip

	lea	PLGAME(pc),a0
	pea	$23000
	bra.b	.patch2

.patchintro
	lea	PLINTRO(pc),a0
	bra.b	.patch
	
.patchocean
	lea	PLOCEAN(pc),a0
.patch	pea	$35000
.patch2	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)

.load	move.l	a1,-(a7)		; save IOStd
	movem.l	$24(a1),d1/a0
	move.l	$2c(a1),d0
	moveq	#1,d2
	move.l	resload(pc),a1
	jsr	resload_DiskLoad(a1)
	move.l	(a7)+,a1
	rts



PLHIGH	PL_START
	PL_ORW	$da6+2,1<<9		; set Bplcon0 color bit
	PL_PS	$bcc,wblit4
	PL_PSS	$c24,wblit3,2
	PL_PSS	$c50,wblit1,2
	PL_PSS	$cb2,wblit2,2
	PL_P	$af6,AckVBI2
	PL_P	$afc,.savehigh
	PL_END
	
.savehigh
	bsr	RestoreCop

	move.l	TRAINEROPTIONS(pc),d0
	add.l	STARTLEVEL(pc),d0
	bne.b	.nosave

	lea	HighName(pc),a0
	lea	$12000,a1
	move.l	#325,d0
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)
.nosave	rts


PLGAME	PL_START
	PL_ORW	$15a40+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$18094,FixDMAWait,2	; fix DMA wait in replayer
	PL_P	$17ffa,FixAudXVol	; fix byte write to volume register
	PL_PS	$1815a,FixAudXVol	; fix byte write to volume register
	PL_P	$13a06,FixDMAWait	; fix DMA wait in sample player
	PL_P	$17bd4,BK_DECRUNCH	; relocate ByteKiller decruncher
	PL_PSS	$15492,.setkbd,4
	PL_R	$15584			; end level 2 interrupt code
	PL_SA	$15938,$15942		; skip Forbid()

	PL_PSS	$15250,FixDMAWait,2	; fix DMA wait in sample player
	PL_PSS	$15282,FixDMAWait,2	; fix DMA wait in sample player
	PL_PS	$ade,.patchhi

	PL_P	$179ac,.load

	PL_R	$13ab4			; disable Copylock

	PL_IFC1X	0		; unlimited lives
	PL_B	$14c62,$4a
	PL_ENDIF

	PL_IFC1X	1
	PL_B	$14c56,$4a		; unlimited energy
	PL_ENDIF

	PL_IFC1X	2		; unlimited grenades
	PL_B	$163ce,$4a
	PL_ENDIF

	PL_IFC1X	3		; invulnerability
	PL_B	$158c6,$60
	PL_ENDIF


	;PL_B	$14c62,$4a		; unlimited lives
	;PL_R	$158c2			; no collision
	;PL_B	$163ce,$4a		; unlimited grenades

	;PL_W	$2e+2,2

	PL_IFC3
	PL_PS	$155b0,.readjoy
	PL_PSA	$16348,.throwgrenades2,$1635a	; player 2
	PL_B	$1635a,$67			; bne -> beq

	PL_PSA	$16362,.throwgrenades1,$16376	; player 1
	PL_B	$16376,$67			; bne -> beq

	PL_PSS	$f6,.startgame,2
	
	PL_ENDIF


; disable Blitter wait patches if CUSTOM4 is used
	PL_IFC4
	PL_ELSE
	
	PL_PSS	$1ac,.wblit,4
	PL_PSS	$14e0c,.wblit2,2
	PL_PSS	$14e36,.wblit2,2
	PL_PSS	$15172,.wblit,2
	PL_PSS	$151a0,.wblit2,2
	PL_PS	$16a10,.wblit3
	PL_PS	$1392e,.wblit4
	PL_PS	$14d90,.wblit4
	PL_PS	$14dde,.wblit4
	PL_ENDIF


	PL_P	$158a0,.ackCop
	PL_P	$158b0,.ackVBI
	PL_END

.ackCop	move.w	#1<<4,$dff09c
	move.w	#1<<4,$dff09c
	rte

.ackVBI	move.w	#1<<5|1<<6,$dff09c
	move.w	#1<<5|1<<6,$dff09c
	rte

.throwgrenades2
	lea	joy1(pc),a0
	bra.b	.throwgrenades
	
.throwgrenades1
	lea	joy0(pc),a0
	

.throwgrenades
	movem.l	d0/a0,-(a7)
	move.l	(a0),d0
	clr.l	(a0)
	btst	#JPB_BTN_BLU,d0
	movem.l	(a7)+,d0/a0
	rts


.readjoy
	bsr	ReadAllJoys

	move.l	joy0(pc),d0
	or.l	joy1(pc),d0
	btst	#JPB_BTN_PLAY,d0
	beq.b	.nopause
	not.w	$23000+$1558e		; toggle pause flag
.nopause

	jmp	$23000+$17ca2		; original code


; fire 1: start 1 player game
; fire 2: start 2 player game
.startgame
	move.l	joy0(pc),d0
	or.l	joy1(pc),d0
	
	btst	#JPB_BTN_RED,d0
	beq.b	.no1pl
	move.b	#$50,$23000+$1558a

.no1pl	btst	#JPB_BTN_BLU,d0
	beq.b	.no2pl
	move.b	#$51,$23000+$1558a
.no2pl

	cmp.b	#$50,$23000+$1558a
	rts
	


.load	move.w	d1,d0
	move.l	d2,d1
	mulu.w	#512*11*2,d0
	moveq	#1,d2
	move.l	resload(pc),a2
	jmp	resload_DiskLoad(a2)
	

.patchhi
	lea	PLHIGH(pc),a0
	pea	$3c000
	move.l	(a7),a1
	movem.l	d0-d2,-(a7)
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d2
	rts


.setkbd	move.l	a0,-(a7)
	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	move.l	(a7)+,a0
	rts

.kbdcust
	moveq	#0,d0
	move.b	RawKey(pc),d0
	move.b	d0,$23000+$1558a

	move.l	TRAINEROPTIONS(pc),d1
	btst	#4,d1
	beq.b	.nokeys

	cmp.b	#$36,d0			; N - skip level
	bne.b	.noN
	;move.b	#1,$23000+$908
	move.w	#107,$23000+$14f14
	
.noN
	cmp.b	#$24,d0			; G - get machine gun
	bne.b	.noG
	lea	$23000+$1d6cc,a0	; player 1
	jsr	$23000+$cc8		; get machine gun
	lea	$23000+$1d6ee,a0	; player 2
	jsr	$23000+$cc8		; get machine gun
.noG

	cmp.b	#$17,d0			; I - toggle invincibility
	bne.b	.noI
	eor.b	#7,$23000+$158c6	; bne <-> bra
.noI

	cmp.b	#$28,d0			; L - toggle unlimited lives
	bne.b	.noL
	eor.b	#$19,$23000+$14c62
.noL

	cmp.b	#$12,d0			; E - toggle unlimited energy
	bne.b	.noE
	eor.b	#$19,$23000+$14c56
.noE

	cmp.b	#$35,d0			; B - toggle unlimited grenades
	bne.b	.noB
	eor.b	#$19,$23000+$163ce
.noB


.nokeys
	jmp	$23000+$15526


.wblit	bsr	WaitBlit2
	move.l	#-1,$dff044
	rts

.wblit2	bsr	WaitBlit
	move.l	a0,$50(a5)
	move.l	a1,$54(a5)
	rts

.wblit3	asr.w	#7,d0
	add.w	d0,a2
	asl.w	#8,d1
	bra.w	WaitBlit
	
.wblit4	lea	$dff000,a5
	bra.w	WaitBlit


PLINTRO	PL_START
	PL_SA	$121c,$1226		; skip Forbid() and drive access
	PL_ORW	$22+2,1<<3		; enable level 2 interrupt
	PL_PSS	$1938,FixDMAWait,2	; fix DMA wait in replayer
	PL_P	$185e,FixAudXVol	; fix byte write to volume register
	PL_PS	$1a2c,FixAudXVol	; fix byte write to volume register
	PL_ORW	$153c+2,1<<9		; set Bplcon0 color bit
	PL_P	$1216,AckVBI2
	PL_P	$1284,RestoreCop	; don't restore system copperlist

	PL_PSS	$13b4,wblit3,2
	PL_PSS	$13e0,wblit1,2
	PL_PSS	$144c,wblit2,2
	PL_PS	$135c,wblit4
	PL_PS	$400,.wblit5
	PL_END



.wblit5	lea	$68000,a4

WaitBlit2
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts

wblit4	asl.w	#6,d7
	or.w	d5,d7
	move.w	d7,d3
	bra.b	WaitBlit	


PLOCEAN	PL_START
	PL_SA	$646,$658		; skip Forbid() and drive access
	PL_PSS	$9e6,FixDMAWait,2	; fix DMA wait in replayer
	PL_P	$90c,FixAudXVol		; fix byte write to volume register
	PL_PS	$ada,FixAudXVol		; fix byte write to volume register
	PL_ORW	$16+2,1<<3		; enable level 2 interrupt
	PL_P	$638,AckVBI2
	PL_P	$6b6,RestoreCop		; don't restore system copperlist
	PL_SA	$622,$628		; skip write to $dff0f8

	PL_PSS	$440,wblit3,2
	PL_PSS	$46c,wblit1,2
	PL_PSS	$4ce,wblit2,2
	PL_END


wblit3	move.l	a1,$48(a5)
	bra.b	wait

wblit2	move.l	a2,$54(a5)
	bra.b	wait

wblit1	move.l	a1,$4c(a5)
wait	move.w	d3,$58(a5)

WaitBlit
	tst.b	$02(a5)
.wblit	btst	#6,$02(a5)
	bne.b	.wblit
	rts


RestoreCop
	pea	$1000.w
	move.l	(a7)+,$dff080
	rts

AckVBI2	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	movem.l	(a7)+,d0-a6
	rte


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


AckVBI	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte


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



	IFD	DEBUG
	cmp.b	HEADER+ws_keydebug(pc),d0	
	bne.b	.nodebug
	movem.l	(a7)+,d0-d1/a0-a2
	move.w	(a7),6(a7)			; sr
	move.l	2(a7),(a7)			; pc
	clr.w	4(a7)				; ext.l sr
	bra.b	.debug
.nodebug
	ENDC

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

	IFD	DEBUG
.debug	pea	(TDREASON_DEBUG).w
	bra.w	EXIT
	ENDC

.exit	bra.w	QUIT


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine




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
	move.l	-(a0),a2
	add.l	a1,a2
	move.l	-(a0),d5
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


	include	ReadJoypad.s

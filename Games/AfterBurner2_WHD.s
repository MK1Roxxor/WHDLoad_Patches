***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(     AFTER BURNER 2 WHDLOAD SLAVE           )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             January 2016                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 19-Jan-2016	- game could freeze when starting the first level (crunched
;		  data was trashed), fixed
;		- invincibility trainer added

; 17-Jan-2016	- work started
;		- and finished some hours later, 24-bit problems fixed,
;		  trainers added, high-score load/save, ButtonWait support
;		  for title picture, interrupts fixed, memory check fixed,
;		  timing fixed (high-score entering), keyboard routine
;		  recoded, Bplcon0 color bit fix

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
DEBUGKEY	= $58		; F9
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


.config	dc.b	"BW;"
	dc.b	"C1:X:Unlimited Lives:0;"
	dc.b	"C1:X:Unlimited Missiles:1;"
	dc.b	"C1:X:Invincibility:2;"
	dc.b	"C1:X:In-Game Keys:3;"
	dc.b	"C2:L:Start at Stage:1,2,3,4,5,6,7,8,9,10,"
	dc.b	"11,12,13,14,15,16,17,18,19,20,21,22,23"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/AfterBurner89",0
	ENDC

.name	dc.b	"After Burner 2",0
.copy	dc.b	"1989 Sega",0
.info	dc.b	"Installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.4 (19.01.2016)",0
	CNOP	0,2


TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	WHDLTAG_BUTTONWAIT_GET
BUTTONWAIT	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET

; bit 0: unlimited lives on/off
; bit 1: unlimited missiles on/off
; bit 2: invincibility on/off
; bit 3: in-game keys on/off
TRAINEROPTIONS	dc.l	0
	

		dc.l	WHDLTAG_CUSTOM2_GET
STARTLEVEL	dc.l	0
		dc.l	TAG_END
resload	dc.l	0


Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)



; load boot
	lea	$50000,a0
	moveq	#0,d0
	move.l	#$2ee0,d1
	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)

	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$4ca8,d0			; SPS 0947
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT

.ok

; decrypt
	lea	$52(a5),a0
	lsr.l	#2,d5
	sub.l	a1,a1
.loop	eor.l	#$ffbb6611,(a0)
	move.l	(a0)+,(a1)+
	subq.l	#1,d5
	bne.b	.loop	

; patch
	lea	PLBOOT(pc),a0
	sub.l	a1,a1
	jsr	resload_Patch(a2)


; install keyboard irq
	bsr	SetLev2IRQ

; and start game
	jmp	$f4.w



QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)

AckVBI	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
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
	rts



PLBOOT	PL_START
	PL_P	$73a,AckVBI		; disable VBI code
	PL_ORW	$114+2,1<<3		; enable level 2 interrupt
	PL_P	$3f4,.load
	PL_P	$3a4,.flush
	PL_P	$3ee,.patchmain		; flush cache and start game
	PL_PS	$3c4,.fixbplcon0
	PL_END

.fixbplcon0
	move.w	#$0200,$dff100
	rts

.patchmain
	move.l	resload(pc),a2
	jsr	resload_FlushCache(a2)

	lea	PLGAME(pc),a0
	lea	$400.w,a1

; install trainers
	move.l	TRAINEROPTIONS(pc),d0

; unlimited lives
	lsr.l	#1,d0
	bcc.b	.NoLivesTrainer
	moveq	#1,d1
	eor.w	d1,$bf2+2(a1)
	eor.w	d1,$e40+2(a1)
	eor.w	d1,$ee0+2(a1)
.NoLivesTrainer	

; unlimited Missiles
	lsr.l	#1,d0
	bcc.b	.NoMissilesTrainer
	eor.b	#$19,$14d6(a1)	
.NoMissilesTrainer


; invincibility
	lsr.l	#1,d0
	bcc.b	.NoInvTrainer
	eor.b	#6,$16dc(a1)	
.NoInvTrainer


; load high-scores
	bsr	LoadHighscore

	jsr	resload_Patch(a2)
	jmp	$400.w

.flush	move.l	resload(pc),a0
	jsr	resload_FlushCache(a0)
	jmp	$7fa00



.load	move.l	#$2ee0,d0
	move.l	#$ea60,d1
	moveq	#1,d2
	lea	$15000,a0
	move.l	resload(pc),a1
	jsr	resload_DiskLoad(a1)

	move.l	BUTTONWAIT(pc),d0
	beq.b	.nowait
.wait	btst	#6,$bfe001
	beq.b	.nowait
	btst	#7,$bfe001
	bne.b	.wait

.nowait	rts


PLGAME	PL_START
	PL_P	$d70a,.load
	PL_SA	$2206,$2224		; skip ext. mem check
	PL_R	$d8ca			; disable drive init
	PL_R	$d69c			; disable loader init
	PL_R	$d8f8			; disable drive access (motor off)
	PL_PSS	$3764,.fix24bit,2
	PL_PS	$2476,.ackVBI
	PL_PSS	$22c8,.setkbd,4
	PL_PS	$4af4,.savehigh
	PL_PS	$493a,.fixtiming
	PL_AW	$427a+2,$490c-$48fe	; don't convert last score during intro
	PL_P	$2ca0,.setStage
	PL_R	$477a			; disable CheckDisk "cheat"
	PL_SA	$21c6,$21d8		; don't modify zeropage vectors
	PL_END

.fixtiming
	moveq	#0,d0
	move.w	#$50,d1
	bra.w	WaitRaster

.savehigh
	clr.w	$400+$5060.w
	bra.w	SaveHighscore



.setStage
	move.l	STARTLEVEL(pc),d0
	move.w	d0,$cc(a6)
	move.w	d0,$d0(a6)
	
	move.w	#5,$c6(a6)
	rts

.setkbd	move.l	a0,-(a7)
	bsr	SetLev2IRQ
	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	move.l	(a7)+,a0
	rts

.kbdcust
	move.b	RawKey(pc),d0

	move.l	TRAINEROPTIONS(pc),d1
	btst	#3,d1
	beq.b	.nokeys

	cmp.b	#$36,d0			; N - skip level
	bne.b	.noN
	st	$ea(a6)
	jsr	$400+$20a0.w
.noN

	cmp.b	#$28,d0			; L - add life
	bne.b	.noL
	addq.w	#1,$c6(a6)
.noL

	cmp.b	#$13,d0			; R - reload missiles
	bne.b	.noR
	move.w	#100,$ca(a6)
.noR

	cmp.b	#$17,d0			; I - toggle invincibility
	bne.b	.noI
	eor.b	#6,$400+$16dc.w	
.noI	


.nokeys	move.b	d0,$3a(a6)
	bmi.b	.skip
	move.b	d0,$3b(a6)
.skip	rts

.ackVBI	move.w	#1<<5,$9c(a0)
	move.w	#1<<5,$9c(a0)
	rts

.fix24bit
	bclr	#31,d0
	move.l	d0,a0
	move.l	a1,(a0)
	move.w	4(a0),d0
	rts


.load	btst	#6,$dff002		; required as otherwise loaded
	bne.b	.load			; data will be trashed!
	
	add.l	#$12110,d0
	moveq	#1,d2
	move.l	resload(pc),a1
	jmp	resload_DiskLoad(a1)


LoadHighscore
	movem.l	d0-a6,-(a7)
	lea	HighscoreName(pc),a0
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nohigh
	lea	HighscoreName(pc),a0
	lea	$400+$4df8.w,a1
	jsr	resload_LoadFile(a2)
.nohigh
	movem.l	(a7)+,d0-a6
	rts

SaveHighscore
	movem.l	d0-a6,-(a7)
	move.l	TRAINEROPTIONS(pc),d0
	add.l	STARTLEVEL(pc),d0
	bne.b	.nosave
	
	lea	HighscoreName(pc),a0
	lea	$400+$4df8.w,a1
	move.l	#$4f24-$4df8,d0
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)
.nosave	movem.l	(a7)+,d0-a6
	rts


HighscoreName
	dc.b	"AfterBurner2.high",0
	CNOP	0,2

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



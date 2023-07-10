***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    AUNT ARCTIC ADVENTURE WHDLOAD SLAVE     )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             October 2017                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 30-Oct-2017	- work started
;		- and finished a while later, RawDIC imager coded,
;		  Bplcon0 color bit fixes (x7), protectio disabled
;		  (MFM, encrypted loader, track check), DMA wait in
;		  replayer fixed, keyboard routine rewritten, blitter
;		  waits added (x2, 68010+ only), CPU dependent delay
;		  fixed, write to $dff003 fixed, trainer options added
;		  (CUSTOM1), interrupt fixed, copperlist problem fixed,
;		  memory check disabled

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


.config	dc.b	"C1:X:Unlimited Lives:0;"
	dc.b	"C1:X:Invincibility:1;"
	dc.b	"C1:X:In-Game Keys:2"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/AuntArcticAdventure",0
	ENDC

.name	dc.b	"Aunt Arctic Adventure",0
.copy	dc.b	"1988 Mindware",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (30.10.2017)",0
HighName	dc.b	"AuntArcticAdventure.high",0

	CNOP	0,4

TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	TAG_DONE

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

; install keyboard irq
	bsr	SetLev2IRQ

; load game
	moveq	#$4a,d0
	moveq	#11,d1
	lea	$6de90,a0
	move.l	a0,a5
	bsr	Load

	move.l	a5,a0
	move.l	#12*$1770,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$f639,d0		; SPS 1757
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT
.ok

; patch it
	lea	PLGAME(pc),a0
	bsr.b	.patch

	move.l	CPUFLAGS(pc),d0
	lsr.l	#1,d0			; carry: AFB_68010 bit
	bcc.b	.noblit
	lea	PLBLIT(pc),a0
	bsr.b	.patch
.noblit


; set default level 3 interrupt
	lea	AckVBI(pc),a0
	move.l	a0,$6c.w

	moveq	#-2,d0
	move.l	d0,$330c8

	jmp	(a5)
	

.patch	move.l	a5,a1
	jmp	resload_Patch(a2)




QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)


KillSys	move.w	#$7fff,$dff09a
	bsr	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	rts


AckVBI	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rte

PLBLIT	PL_START
	PL_PSS	$3504,.wblit1,2
	PL_PSS	$3a84,.wblit2,2
	PL_END


.wblit1	bsr.b	WaitBlit
	move.w	#$09f0,$dff040
	rts

.wblit2	bsr.b	WaitBlit
	move.w	#$0100,$dff040
	rts

WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts


PLGAME	PL_START
	PL_SA	$7c9e,$7cae		; skip opening graphics.library
	PL_PS	$1158,.ackVBI
	PL_R	$2280			; disable protection check
	PL_P	$866e,Load
	PL_PS	$861e,.loadhigh		; load high scores
	PL_PS	$865e,.savehigh
	PL_PSS	$82d6,FixDMAWait,2	; fix DMA wait in replayer
	PL_R	$73a			; disable memory check
	PL_ORW	$8e0a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$8ffa+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$9032+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$913e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$92ae+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$4dc+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$596+2,1<<9		; set Bplcon0 color bit
	PL_PS	$280a,.fixaudio		; fix write to $dff003

	PL_IFC1X	2
	PL_PSA	$7cea,.setkbd_cheat,$7cf4
	PL_ELSE
	PL_PSA	$7cea,.setkbd,$7cf4
	PL_ENDIF
	PL_R	$106e			; end level 2 interrupt code
	PL_PSS	$388,.delay10k,2	; fix CPU dependent delay


	PL_IFC1X	0
	PL_W	$2c9c+2,0		; unlimited lives, player 1
	PL_W	$2cc0+2,0		; unlimited lives, player 2
	PL_ENDIF

	PL_IFC1X	1
	PL_B	$3266,$60		; invincibility
	PL_ENDIF


	PL_PSA	$6ac2,.fixfire,$6ace	; make sure fire button is released
	PL_END


.delay10k
	move.w	#10000/$34/5,d0
	bra.w	FixDMAWait


.setkbd	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts

.setkbd_cheat
	lea	.kbdcust_cheat(pc),a0
	move.l	a0,KbdCust-.kbdcust_cheat(a0)
	rts

.kbdcust_cheat
	move.b	RawKey(pc),d0
	cmp.b	#$36,d0			; N - skip level
	bne.b	.noN
	move.w	#1,$6de90+$b19a
.noN

	cmp.b	#1,d0			; 1 - toggle unlimited lives, player 1
	bne.b	.NoLivesToggle
	eor.w	#1,$6de90+$2c9c+2
.NoLivesToggle

	cmp.b	#2,d0			; 2 - toggle unlimited lives, player 2
	bne.b	.NoLivesToggle2
	eor.w	#1,$6de90+$2cc0+2
.NoLivesToggle2

	cmp.b	#$17,d0			; I - toggle invincibility
	bne.b	.noInvToggle
	eor.b	#$06,$6de90+$3266
.noInvToggle


.kbdcust
	move.b	Key(pc),$6de90+$b1c0
	jmp	$6de90+$c24		; call level 2 interrupt code


.fixfire
	btst	#7,$bfe001
	bne.b	.fixfire
.release
	btst	#7,$bfe001
	beq.b	.release
	rts


.fixaudio
	movem.l	d0,-(a7)		; movem so flags won't be restored
	move.b	$dff003,d0
	and.b	d1,d0
	movem.l	(a7)+,d0
	rts


.ackVBI	move.w	d0,$dff09c
	move.w	d0,$dff09c
	rts


; high-score/options/progress load/save
.savehigh
	lea	HighName(pc),a0
	lea	$6de90+$a2f4,a1
	move.l	#2*$1770,d0
	move.l	resload(pc),a2
	jmp	resload_SaveFile(a2)

.loadhigh
	lea	HighName(pc),a0
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.fromDisk
	lea	HighName(pc),a0
	lea	$1b750,a1
	jmp	resload_LoadFile(a2)

.fromDisk
	moveq	#1,d0
	moveq	#1,d1
	lea	$1b750,a0



Load	subq.w	#1,d0
	mulu.w	#$1770*2,d0
	addq.w	#1,d1
	mulu.w	#$1770,d1
	moveq	#1,d2
	move.l	resload(pc),a1
	jmp	resload_DiskLoad(a1)
	


WaitRaster
.wait1	btst	#0,$dff005
	beq.b	.wait1
.wait2	btst	#0,$dff005
	bne.b	.wait2
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

.exit	bra.w	QUIT


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine






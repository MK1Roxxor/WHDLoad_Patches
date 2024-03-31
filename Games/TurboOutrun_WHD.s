***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       TURBO OUTRUN WHDLOAD SLAVE           )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             February 2015                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 01-Mar-2015	- high-scores are now encrypted
;		- ButtonWait now also checks the fire button
;		- "cool down turbo" in-game key added
;		- patch finished, more than enough for this crappy game

; 28-Feb-2015	- timing fixed/added in mainloop, game is now playable
;		  on fast machines, fix can be disabled with CUSTOM1
;		- unlimited time trainer now disabled the countdown in
;		  the "select transmission" and "choose tune up parts"
;		  screens too
;		- in-game keys added
;		- "Start at Stage" option added
;		- blitter wait added
;		- access fault fixed
;		- "no overheating" option added
;		- high-score load/save added

; 26-Feb-2015	- game works now (a0 trashed when installing 
;		  keyboard custom routine)
;		- trainers added

; 25-Feb-2015	- work started
;		- title part works

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
	dc.b	"C1:B:Disable timing fix;"
	dc.b	"C2:X:Unlimited Time:0;"
	dc.b	"C2:X:Unlimited Credits:1;"
	dc.b	"C2:X:No Overheating:2;"
	dc.b	"C2:X:In-Game Keys:3;"
	dc.b	"C3:L:Start at Stage:Off,1,2,3,4,5,6,7,8,9,10,"
	dc.b	"11,12,13,14,15,16"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/TurboOutrun",0
	ENDC
.name	dc.b	"Turbo Outrun",0
.copy	dc.b	"1990 US Gold",0
.info	dc.b	"Installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.2 (01.03.2015)",0

HighName	dc.b	"TurboOutrun.high",0
	CNOP	0,2


TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	WHDLTAG_BUTTONWAIT_GET
BUTTONWAIT	dc.l	0

		dc.l	WHDLTAG_CUSTOM1_GET
NOTIMINGFIX	dc.l	0

		dc.l	WHDLTAG_CUSTOM2_GET

; bit 0: unlimited time on/off
; bit 1: unlimited credits on/off
; bit 2: no overheating on/off
; bit 3: in-game keys on/off
;	 T - Toggle unlimited time
;	 N - skip level
; 	 O - toggle overheating
;	 X - show end
;	 C - cool down turbo
TRAINEROPTIONS	dc.l	0

		dc.l	WHDLTAG_CUSTOM3_GET
STAGE		dc.l	0


		dc.l	TAG_END


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
	lea	$60000-$34,a0
	move.l	a0,a5
	move.l	d1,d5
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)

	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$f19e,d0		; SPS 1064
	beq.b	.ok
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

; patch boot
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)


; and start game
	jmp	$34(a5)




QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)

AckVBI	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
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
	PL_SA	$94,$9a			; don't kill level 2 interrupt
	PL_P	$132,AckVBI
	PL_ORW	$c6+2,1<<3		; enable level 2 interrupt
	PL_P	$13c,.loader
	PL_P	$78,.patchgame
	PL_END

.loader	move.l	d7,d0
	move.l	d2,d1
	addq.w	#1,d1
	mulu.w	#512*11,d0
	mulu.w	#512*11,d1
	moveq	#1,d2
	move.l	resload(pc),a1
	jmp	resload_DiskLoad(a1)
	

.patchgame



	lea	PLGAME(pc),a0
	lea	$400.w,a1
	move.l	a1,a5
	

; install trainers
	move.l	TRAINEROPTIONS(pc),d0

; unlimited time
	lsr.l	#1,d0
	bcc.b	.notimetrainer
	bsr	ToggleTime
.notimetrainer

	lsr.l	#1,d0
	bcc.b	.nocreditstrainer
	eor.b	#$19,$32cc(a1)		; subq.b <-> tst.b
.nocreditstrainer

	lsr.l	#1,d0
	bcc.b	.nooverheatingtrainer
	eor.w	#$79b9,$47ca(a1)
.nooverheatingtrainer


	move.l	STAGE(pc),d0
	beq.b	.nostage
	move.w	d0,$4c+2(a1)
	move.w	d0,$7ec+2(a1)
	move.w	d0,$80c+2(a1)
	
.nostage

	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	move.l	NOTIMINGFIX(pc),d0
	bne.b	.skiptiming
	lea	PLTIMING(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)
.skiptiming

; load high scores
	lea	HighName(pc),a0
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nohigh
	lea	HighName(pc),a0
	lea	$400+$17b9c,a1
	jsr	resload_LoadFile(a2)

	lea	$400+$17b9c,a0
	move.w	#$17f89-$17b9c-1,d0
.loop	eor.b	#$03,(a0)+
	dbf	d0,.loop


.nohigh

	move.l	BUTTONWAIT(pc),d0
	beq.b	.nowait
.wait	btst	#6,$bfe001
	beq.b	.nowait
	btst	#7,$bfe001
	beq.b	.nowait
	btst	#2,$dff016
	bne.b	.wait

.nowait	jmp	$400.w



PLTIMING
	PL_START
	PL_PSA	$1bcc,.waitraster,$1bdc
	PL_PSA	$1d66,.waitraster,$1d76
	PL_PSA	$3ba0,.waitraster,$3bb0

	PL_PS	$a5a,.fix		; fix timing in mainloop
	PL_END

.fix	bsr.b	.waitraster
	st	$400+$324bf
	rts

.waitraster
	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.b	.waitraster

.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	beq.b	.wait

	rts
	




PLGAME	PL_START
	PL_PSA	$927a,.setkbd,$9284
	PL_R	$93b4			; so we can call level 2 interrupt code

	PL_P	$93f0,.ackCOP
	PL_P	$952c,AckVBI
	PL_P	$9402,.ackBLT
	PL_SA	$92a6,$932c		; don't kill exceptions+traps

	PL_R	$6860			; disable drive access (motor off)
	PL_R	$6840			; disable drive access (motor on)
	PL_R	$68a0			; disable drive access (step to trk0)
	PL_R	$69a6			; disable disk 2 request

	PL_PSA	$6942,.load,$6986
	PL_SA	$8b2c,$8b38		; skip disk check

	PL_SA	$51da,$51e0		; skip access fault
	PL_P	$3f6,.waitblit
	PL_PSS	$3802,.checkhisave,2
	PL_END

.checkhisave
	move.l	a0,-(a7)
	jsr	$400+$5ac.w		; get key
	move.l	(a7)+,a0

	cmp.b	#13,d0			; return pressed?
	bne.b	.nosave

; no high-score saving if trainers used
	move.l	TRAINEROPTIONS(pc),d1
	add.l	STAGE(pc),d1
	bne.b	.nosave
	

	movem.l	d0-a6,-(a7)

	lea	$400+$17b9c,a0
	move.w	#$17f89-$17b9c-1,d0
.loop	eor.b	#$03,(a0)+
	dbf	d0,.loop

	lea	HighName(pc),a0
	lea	$400+$17b9c,a1
	move.l	#$17f89-$17b9c,d0
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)

	lea	$400+$17b9c,a0
	move.w	#$17f89-$17b9c-1,d0
.loop2	eor.b	#$03,(a0)+
	dbf	d0,.loop2
	movem.l	(a7)+,d0-a6




.nosave
	rts


; this actually shouldn't be necessary as the game
; waits for the blitter interrupt to occur and then clears
; the "blitter busy" flag but WHDLoad throws a snoop fault
; (also mentioned in the WHDLoad docs) 
; so we add a "normal" blitter wait

.waitblit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit

.wait	tst.w	$400+$940c		; check "blitter busy" flag
	bne.b	.wait			; not really needed but doesn't hurt
	rts


; a2.l: params
.load	movem.l	(a2),d0/d1
	moveq	#2,d2
	move.l	$400+$31db6,a0
	move.l	resload(pc),a2
	jmp	resload_DiskLoad(a2)


.ackCOP	move.w	#1<<4,$dff09c
	move.w	#1<<4,$dff09c
	rte

.ackBLT	move.w	#1<<6,$dff09c
	move.w	#1<<6,$dff09c
	rte

.setkbd	move.l	a0,-(a7)
	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	move.l	(a7)+,a0
	rts

.kbdcust
	moveq	#0,d0


	move.l	TRAINEROPTIONS(pc),d1
	btst	#3,d1
	beq.b	.nokeys
	
	lea	RawKey(pc),a0
	move.b	(a0),d0
	clr.b	(a0)

	cmp.b	#$36,d0			; N - skip level
	bne.b	.noN
	st	$400+$34ef6		; set "level complete" flag
.noN

	cmp.b	#$32,d0			; X - show end
	bne.b	.noX
	move.w	#16,$400+$34d5a		; last stage
	st	$400+$34ef6		; set "level complete" flag
.noX

	cmp.b	#$14,d0			; T - toggle unlimited time
	bne.b	.noT
	bsr.b	ToggleTime

.noT
	cmp.b	#$18,d0			; O - toggle overheating
	bne.b	.noO
	eor.w	#$79b9,$400+$47ca
.noO

	cmp.b	#$33,d0			; C - cool down turbo
	bne.b	.noC
	clr.w	$400+$323e4
.noC


.nokeys	move.b	Key(pc),d0
	jmp	$400+$938c		; call original level 2 code


ToggleTime
	lea	$400.w,a1
	eor.w	#2,$2b60+2(a1)
	eor.b	#$19,$188c(a1)		; time in "select transmission" screen
	eor.b	#$19,$1ad8(a1)		; time in "tune up" screen
	eor.b	#$9a,$cc4(a1)		; no time bonus to avoid gfx trash
	rts
	
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




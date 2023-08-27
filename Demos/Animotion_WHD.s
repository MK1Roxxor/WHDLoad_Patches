***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    ANIMOTION/PHENOMENA WHDLOAD SLAVE       )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            September 2013                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 16-AUg-2023	- interrupt vectors (level 3 and level 6) are now
;		  initialised before starting the demo (issue #6223)

; 14-Mar-2016	- illegal out of bounds blit fixed, 7 more blitter waits
;		  added
;		- unused replayer patches removed

; 19-Sep-2013	- work started, patch requested by Frequent/Ephidrena

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	hardware/intbits.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
DEBUGKEY	= $58		; F9
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


.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Phenomena/Animotion",0
	ENDC
.name	dc.b	"Animotion",0
.copy	dc.b	"1990 Phenomena",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.02 (16.08.2023)",10
	dc.b	10
	dc.b	"Greetings to Frequent :)",0
Name	dc.b	"Animotion",0
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

; load demo
	lea	Name(pc),a0
	lea	$1000.w,a1
	move.l	a1,a5
	jsr	resload_LoadFile(a2)
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$31ea,d0
	beq.b	.ok
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
.ok

; decrunch
	lea	$158(a5),a0
	add.l	$154(a5),a0
	lea	$22000,a1
	move.l	a1,a5
	bsr	DECRUNCH

; patch
	move.l	resload(pc),a2
	lea	PLMAIN(pc),a0
	bsr.b	.patch

	move.l	CPUFLAGS(pc),d0
	lsr.l	#1,d0
	bcc.b	.is68k
	lea	PLBLIT(pc),a0
	bsr.b	.patch
.is68k
	move.w	#30,$300.w


	; initialise interrupt vectors
	pea	Acknowledge_Level6_Interrupt(pc)
	move.l	(a7)+,$78.w
	pea	Acknowledge_Level3_Interrupt(pc)
	move.l	(a7)+,$6c.w


; and start
	jmp	(a5)

.patch	move.l	a5,a1
	jmp	resload_Patch(a2)


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	jmp	resload_Abort(a2)

PLBLIT	PL_START
	PL_PSS	$49a2,.wblit1,2		; sine scroll innerloop
	PL_PS	$1000,.wblit2
	PL_PS	$3a2e,.wblit2
	PL_PSS	$397e,.wblit3,2
	PL_PS	$1fd8,.wblit2
	PL_PSS	$2cd8,.wblit3,2
	PL_PS	$f22,.wblit4
	PL_PS	$6db2,.wblit4
	PL_END

.wblit4	lea	$dff000,a0
.wb4	tst.b	$02(a0)
	btst	#6,$02(a0)
	bne.b	.wb4
	rts


.wblit3	tst.b	$dff002
.wb3	btst	#6,$dff002
	bne.b	.wb3
	move.w	#$0100,$dff040
	rts


.wblit2	lea	$dff000,a6
.wb2	tst.b	$02(a6)
	btst	#6,$02(a6)
	bne.b	.wb2
	rts

.wblit1	btst	#6,$2(a0)
	bne.b	.wblit1
	move.l	a4,$48(a0)		; original code
	move.l	d4,$4c(a0)
	rts

PLMAIN	PL_START
	PL_P	$68a8,AckLev6
	PL_ORW	$64+2,1<<3		; enable level 2 interrupt
	PL_P	$12a,.ackVBI
	PL_P	$69ae,DECRUNCH		; relocate decruncher
	PL_PSA	$f6c,.waitraster,$f76	; fix timing
	PL_PSA	$f7a,.waitraster,$f84	; fix timing
	PL_L	$269c+2,$300		; fix SMC in space cut part
	PL_L	$265c,$d2780300		; add.w $300.w,d1
	PL_PSA	$ece,WaitRaster,$ed8
	PL_PSA	$b4a,WaitRaster,$b56
	PL_PSA	$b94,WaitRaster,$b9e
	PL_PSA	$bb6,WaitRaster,$bc0
	
	PL_PS	$1e56,.fixblit		; fix out ouf bound blit in intro
	
	PL_END

.fixblit
	cmp.l	#$80000,a1
	blo.b	.ok
	lea	$60000,a1
.ok

	move.w	$22000+$1f04,d0
	rts

.waitraster
	cmp.b	#255-1,$dff006
	bne.b	.waitraster
.wait	cmp.b	#255-1,$dff006
	beq.b	.wait
	rts

.ackVBI	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	movem.l	(a7)+,d0-a6
	rte
	

AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte

AckVBI	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rte

KillSys	move.w	#$7fff,$dff09a		; disable all interrupts
	bsr	WaitRaster
	move.w	#$7ff,$dff096		; disable all DMA
	move.w	#$7fff,$dff09c		; disable all interrupt requests
	lea	AckVBI(pc),a0
	move.l	a0,$6c.w
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


; a0.l: end of crunched data
; a1.l: destination

DECRUNCH
	move.l	-(a0),a2
	add.l	a1,a2
	tst.l	-(a0)
	move.l	-(a0),d0
lbC00003A
;	move.b	($DFF006),($DFF183)
	moveq	#3,d1
	bsr.w	lbC000132
	tst.w	d2
	beq.b	lbC0000A2
	cmp.w	#7,d2
	bne.b	lbC000078
	lsr.l	#1,d0
	bne.b	lbC00005C
	bsr.w	lbC000128
lbC00005C
	bcc.b	lbC000070
	moveq	#10,d1
	bsr.w	lbC000132
	tst.w	d2
	bne.b	lbC000078
	moveq	#$12,d1
	bsr.w	lbC000132
	bra.b	lbC000078

lbC000070
	moveq	#4,d1
	bsr.w	lbC000132
	addq.w	#7,d2
lbC000078
	subq.w	#1,d2
lbC00007A
	moveq	#7,d1
lbC00007C
	lsr.l	#1,d0
	beq.b	lbC00008E
	roxl.l	#1,d3
	dbf	d1,lbC00007C
	move.b	d3,-(a2)
	dbf	d2,lbC00007A
	bra.b	lbC0000A2

lbC00008E
	move.l	-(a0),d0
	move.w	#$10,ccr
	roxr.l	#1,d0
	roxl.l	#1,d3
	dbf	d1,lbC00007C
	move.b	d3,-(a2)
	dbf	d2,lbC00007A
lbC0000A2
	cmp.l	a2,a1
	bge.b	lbC000122
	moveq	#2,d1
	bsr.w	lbC000132
	moveq	#2,d3
	moveq	#8,d1
	tst.w	d2
	beq.b	lbC000110
	moveq	#4,d3
	cmp.w	#2,d2
	beq.b	lbC0000FA
	moveq	#3,d3
	cmp.w	#1,d2
	beq.b	lbC0000EC
	moveq	#2,d1
	bsr.b	lbC000132
	cmp.w	#3,d2
	beq.b	lbC0000E4
	cmp.w	#2,d2
	beq.b	lbC0000DA
	addq.w	#5,d2
	move.w	d2,d3
	bra.b	lbC0000FA

lbC0000DA
	moveq	#2,d1
	bsr.b	lbC000132
	addq.w	#7,d2
	move.w	d2,d3
	bra.b	lbC0000FA

lbC0000E4
	moveq	#8,d1
	bsr.b	lbC000132
	move.w	d2,d3
	bra.b	lbC0000FA

lbC0000EC
	moveq	#8,d1
	lsr.l	#1,d0
	bne.b	lbC0000F4
	bsr.b	lbC000128
lbC0000F4
	bcs.b	lbC000110
	moveq	#14,d1
	bra.b	lbC000110

lbC0000FA
	moveq	#$10,d1
	lsr.l	#1,d0
	bne.b	lbC000102
	bsr.b	lbC000128
lbC000102
	bcc.b	lbC000110
	moveq	#8,d1
	lsr.l	#1,d0
	bne.b	lbC00010C
	bsr.b	lbC000128
lbC00010C
	bcs.b	lbC000110
	moveq	#12,d1
lbC000110
	bsr.b	lbC000132
	subq.w	#1,d3
lbC000114
	move.b	-1(a2,d2.l),-(a2)
	dbf	d3,lbC000114
	cmp.l	a2,a1
	blt.w	lbC00003A
lbC000122
	rts

lbC000128
	move.l	-(a0),d0
	move.w	#$10,ccr
	roxr.l	#1,d0
	rts

lbC000132
	subq.w	#1,d1
	clr.l	d2
.getbits
	lsr.l	#1,d0
	beq.b	.nextlong
	roxl.l	#1,d2
	dbf	d1,.getbits
	rts

.nextlong
	move.l	-(a0),d0
	move.w	#$10,ccr
	roxr.l	#1,d0
	roxl.l	#1,d2
	dbf	d1,.getbits
	rts

; ---------------------------------------------------------------------------

Acknowledge_Level6_Interrupt
	move.w	#INTF_EXTER,$dff09c
	move.w	#INTF_EXTER,$dff09c
	rte

Acknowledge_Level3_Interrupt
	move.w	#INTF_COPER|INTF_BLIT|INTF_VERTB,$dff09c
	move.w	#INTF_COPER|INTF_BLIT|INTF_VERTB,$dff09c
	rte	


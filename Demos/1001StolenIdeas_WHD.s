***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   1001 STOLEN IDEAS/AIRWALK WHDLOAD SLAVE  )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             October 2013                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 15-Apr-2020	- WHDLF_ReqAGA flag remove
;		- blitter waits added

; 05-Jan-2014	- snoop bug (illegal copperlist entries) fixed, causes
;		  visual bugs though

; 24-Oct-2013	- work started

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


.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Airwalk/1001StolenIdeas",0
	ENDC
.name	dc.b	"1001 Stolen Ideas",0
.copy	dc.b	"1991 Airwalk",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.01 (15.04.2020)",0
Name	dc.b	"1001StolenIdeas",0
	CNOP	0,2




resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2


; install keyboard irq
	bsr	SetLev2IRQ

	lea	$1000.w,a7

; load, relocate and patch demo
	lea	Name(pc),a0
	lea	$1000.w,a1
	move.l	a1,a5
	jsr	resload_LoadFileDecrunch(a2)
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$f59a,d0
	beq.b	.ok
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok	move.l	a5,a0
	sub.l	a1,a1
	jsr	resload_Relocate(a2)

	lea	PLMAIN(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)


; set fake VBI+level 6 interrupt
	lea	AckVBI(pc),a0
	move.l	a0,$6c.w
	lea	AckLev6(pc),a0
	move.l	a0,$78.w

; install fake copperlist
	lea	$100.w,a0
	move.l	a0,a1
	move.l	#$01000200,(a0)+
	move.l	#$008a0000,(a0)+
	move.l	#-2,(a0)
	move.l	a1,$dff080
	
	move.w	#$83c0,$dff096

; fix copperlist (greetings part)
	lea	$1000+$c8ac,a0
	move.w	#($df3c-$c8ac)/2-1,d7
.loop	move.w	#$01fe,(a0)+
	dbf	d7,.loop

; and start
	jmp	(a5)


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)

AckVBI	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rte

KillSys	move.w	#$7fff,$dff09a
	bsr	WaitRaster
	move.w	$dff002,d0		; DMA
	and.w	#1<<6,d0
	beq.b	.noblit
.wb	btst	#6,$dff002
	bne.b	.wb
.noblit	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	lea	AckVBI(pc),a0
	move.l	a0,$6c.w
	rts

PLMAIN	PL_START
	PL_PSA	$4,.setcop,$22
	PL_SA	$36,$40			; skip Forbid()
	PL_PSS	$12470,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$1247e,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSA	$14d2,.setcop,$14e2
	PL_PSA	$5d08,.setcop,$5d18
	PL_PSA	$8616,.setcop,$8626
	PL_PSA	$8f2e,.setcop,$8f3e
	PL_PSA	$c232,.setcop,$c242
	PL_PSA	$c74e,.setcop,$c75e
	PL_PSA	$1162a,.setcop,$1163a
	PL_P	$1174e,QUIT
	PL_ORW	$5e0a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$117c6+2,1<<9		; set Bplcon0 color bit

	PL_PSS	$1774,.wblit,2
	PL_PSS	$17b0,.wblit2,2
	PL_PSS	$e6a6,.wblit3,2
	PL_PSS	$11bca,.wblit4,2
	PL_END

.wblit	bsr.b	WaitBlit
	move.w	#0,$dff064
	rts

.wblit2	bsr.b	WaitBlit
	move.w	#0,$dff066
	rts


.wblit3	bsr.b	WaitBlit
	move.w	#36,$dff066
	rts

.wblit4	bsr.b	WaitBlit
	move.w	#78,$dff066
	rts

.setcop	lea	$dff080,a0
	rts


.ackVBI	move.w	#1<<4,$9c(a6)
	move.w	#1<<4,$9c(a6)
	rts


WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts

AckLev6	tst.b	$bfdd00
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte	


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

.exit	pea	(TDREASON_OK).w
.quit	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine


***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        SPIRILON WHDLOAD SLAVE              )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             April 2020                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 04-Apr-2020	- work started
;		- and finished a while later

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap|WHDLF_ReqAGA
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
	dc.l	524288*4	; ws_BaseMemSize
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


.config	dc.b	"BW"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Spirilon",0
	ENDC

.name	dc.b	"Spirilon",0
.copy	dc.b	"1994 Zephyr Studio",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	dc.b	"Greetings to Lowlife",-1
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (04.04.2020)",0


	CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2


; install level 2 interrupt
	bsr	SetLev2IRQ


; load boot
	move.l	#$82*$1600,d0
	move.l	#$15*$1600,d1
	lea	$100000,a0
	move.l	a0,a5
	move.l	d1,d5
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$A358,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok


; patch
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

	jmp	(a5)




QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)


KillSys	move.w	#$7fff,$dff09a
	bsr.b	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	rts


WaitRaster
.wait1	btst	#0,$dff005
	beq.b	.wait1
.wait2	btst	#0,$dff005
	bne.b	.wait2
	rts




AckVBI	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte

AckVBI_R
	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rts

AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte

AckLev6_R
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rts





PLBOOT	PL_START
	PL_PSS	$1154,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$116a,FixDMAWait,2
	PL_PSS	$1894,FixDMAWait,2
	PL_PSS	$18aa,FixDMAWait,2
	PL_P	$12a,AckVBI
	PL_P	$15c,AckVBI
	PL_P	$18c,AckVBI
	PL_P	$c78,Load
	PL_P	$f0,.PatchMain
	PL_ORW	$294a+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$208e+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$56+2,1<<3		; enable level 2 interrupts

	PL_IFBW
	PL_PS	$c4,.WaitButton
	PL_ENDIF
	PL_END


.WaitButton
	clr.w	$100000+$23a		; original code
	move.l	#(60*5)*10,d0		; 5 minutes should be enough
	move.l	resload(pc),a0
	jmp	resload_Delay(a0)



.PatchMain
	lea	PLMAIN(pc),a0
	pea	$120000
	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)


Load	move.w	d1,d7

	mulu.w	#512*11,d0
	mulu.w	#512*11,d1
	moveq	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)

	; delay a bit so the pictures will be shown
	move.w	d7,d0
	jmp	resload_Delay(a2)


PLMAIN	PL_START
	PL_SA	$46,$52			; skip CACR/VBR stuff

	; fix DMA waits in sample player
	PL_PSS	$64d6,FixDMAWait,2
	PL_PSS	$650c,FixDMAWait,4
	PL_PSS	$6568,FixDMAWait,4	
	PL_PSS	$65a2,FixDMAWait,4	

	PL_P	$4738,AckLev6
	PL_P	$4dc,AckLev6
	PL_P	$504,AckVBI
	PL_ORW	$6822+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$6b92+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$6b9a+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$7436+2,1<<9		; set BPLCON0 color bit
	PL_SA	$58,$5e			; skip write to CLXDAT
	PL_PS	$13c62,AckLev6_R
	PL_P	$158,.AckLev2
	PL_PS	$162,.CheckQuit
	PL_END

.CheckQuit
	move.b	$bfec01,d0
	move.b	d0,d1
	ror.b	d1
	not.b	d1
	cmp.b	HEADER+ws_keyexit(pc),d1
	beq.w	QUIT
	rts


.AckLev2
	move.w	#1<<3,$dff09c
	move.w	#1<<3,$dff09c
	rte	



FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d0
.loop	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait
	dbf	d0,.loop
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

	move.b	$c00(a1),d0
	not.b	d0
	ror.b	d0

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




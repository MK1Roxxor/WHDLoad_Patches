***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(     MINDFIELD/MEGAWATTS WHDLOAD SLAVE      )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            January 2019                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 17-May-2020	- interrupts in main part patched, blitter wait added
;		- credits part patched
;		- hidden part patched

; 21-Jan-2019	- work started

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
DEBUG

;SAVEFILES	; uncomment to save all loaded files

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
	dc.w	10		; ws_version
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
	dc.l	524288		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
;	dc.w	0		; ws_kickname
;	dc.l	0		; ws_kicksize
;	dc.w	0		; ws_kickcrc
;
; v17
;	dc.w	.config-HEADER	; ws_config
;
;
;.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Megawatts/Mindfield",0
	ENDC

.name	dc.b	"Mindfield",0
.copy	dc.b	"1994 Megawatts",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (17.05.2020)",0

	CNOP	0,4

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

; install level 2 interrupt
	bsr	SetLev2IRQ

; load boot
	lea	$30000,a0
	move.l	#$1600,d0
	move.l	d0,d1
	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)

	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$68d0,d0
	beq.b	.ok


	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT

.ok

	lea	$74000,a0
	move.w	#$4ef9,(a0)+
	pea	Load(pc)
	move.l	(a7)+,(a0)

; patch
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

; set ext. memory
	move.l	HEADER+ws_ExpMem(pc),$a58(a5)


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

AckLev6	bsr.b	AckLev6_R
	rte

AckLev6_R
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rts


PLBOOT	PL_START
	PL_R	$98e		; disable ext. mem check
	PL_SA	$16,$24		; skip Forbid() and wrong write to INTENA

	PL_R	$96		; don't load loader

	PL_ORW	$880+2,1<<9	; set Bplcon0 color bit
	PL_SA	$204,$20a	; skip write to BEAMCON0
	
	PL_PS	$56c,.AckVBI
	PL_ORW	$402+2,1<<3	; enable level 2 interrupts

	PL_PS	$3ce,.Patch_2e_01
	PL_PS	$4f4,.PatchMain
	PL_PS	$7a4,.PatchHiddenPart
	

	PL_END


.PatchHiddenPart
	add.l	$7d000,a0

	movem.l	d0-a6,-(a7)
	move.l	a0,a1
	lea	PLHIDDEN_DA(pc),a0
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts
	
	


.PatchMain
	add.l	$7d000,a0

	movem.l	d0-a6,-(a7)
	move.l	a0,a1
	lea	PLMAIN(pc),a0
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts


.Patch_2e_01
	add.l	$7d000,a0

	movem.l	d0-a6,-(a7)
	move.l	a0,a1
	lea	PL2E_01(pc),a0
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts



.AckVBI	move.w	#1<<5,$9c(a6)
	move.w	#1<<5,$9c(a6)
	rts




PL2E_01	PL_START
	PL_PS	$68e,.AckVBI
	PL_PS	$244,AckLev2
	PL_PSS	$cdc,AckLev6,2
	
	PL_END

.AckVBI	move.w	#$4020,$9c(a6)
	move.w	#$4020,$9c(a6)
	rts

AckLev2

	move.b	$bfec01,d0
	ror.b	d0
	not.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT

	move.w	#$4008,$9c(a6)
	move.w	#$4008,$9c(a6)
	rts	


; disk 1, track $10
PLCREDITS
	PL_START
	PL_PS	$b96,AckVBI_R
	PL_ORW	$166+2,1<<3		; enable level 2 interrupts
	
	PL_END


AckVBI_R
	move.w	#$4020,$9c(a6)
	move.w	#$4020,$9c(a6)
	rts	


PLMAIN	PL_START
	PL_PS	$2838,AckVBI_R
	PL_PS	$23ec,AckLev2
	PL_PSS	$5128,AckLev6,2
	PL_PSS	$5178,AckLev6_R,2
	PL_PS	$3f74,.wblit1

	PL_PS	$20e8,.PatchCredits

	PL_END


.PatchCredits
	add.l	$7d000,a0
	movem.l	d0-a6,-(a7)
	move.l	a0,a1
	lea	PLCREDITS(pc),a0
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts



.wblit1	lea	$dff000,a6
	bra.w	WaitBlit



; hidden part, Double Action crunched file

PLHIDDEN_DA
	PL_START
	PL_SA	$12,$2a			; skip drive access
	PL_P	$228,.Patch
	PL_END


.Patch	lea	PLHIDDEN(pc),a0
	move.l	a2,a1
	move.l	resload(pc),a3
	jsr	resload_Patch(a3)
	move.w	#$c000,$9a(a4)
	jmp	(a2)


PLHIDDEN
	PL_START
	PL_PS	$3072,AckVBI_R
	PL_ORW	$96+2,1<<3		; enable level 2 interrupts
	PL_PSS	$36ec,AckLev6_R,2
	PL_PSS	$373c,AckLev6_R,2
	PL_PSS	$3928,AckLev6_R,2
	PL_PS	$3982,AckLev6_R
	PL_END



; d0.w: disk number
; d1.w: track
; d2.w: length
; d3.w: side flag ($1111/$0011)
; d4.l: destination

Load	IFD	SAVEFILES
	move.w	d1,d6
	move.w	d2,d7
	ENDC


	move.w	d0,d5
	move.w	d1,d0
	move.w	d2,d1
	move.w	d5,d2
	move.l	d4,a0
	mulu.w	#512*11*2,d0
	mulu.w	#512*11*2,d1

	lsr.w	#8,d3
	beq.b	.sok
	add.l	#$1600,d0
	sub.l	#$1600,d1
.sok	

	IFD	SAVEFILES
	move.l	d1,-(a7)

	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)

	move.w	d6,d0
	bsr	.BuildName

	move.l	d4,a1
	move.l	(a7)+,d0
	jmp	resload_SaveFile(a2)

	ELSE
	
	move.l	resload(pc),a1
	jmp	resload_DiskLoad(a1)
	ENDC


	IFD	SAVEFILES
.BuildName
	lea	Name(pc),a0

	add.b	#"0",d2
	move.b	d2,2(a0)

	moveq	#3-1,d1
.loop	moveq	#$f,d2
	and.b	d0,d2
	cmp.b	#9,d2
	ble.b	.ok
	addq.b	#7,d2
.ok	add.b	#"0",d2
	move.b	d2,4(a0,d1.w)

	lsr.w	#4,d0
	dbf	d1,.loop
	rts
	
Name	dc.b	"MF0_000",0
	CNOP	0,2
	ENDC


WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
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

	lea	Key(pc),a2
	moveq	#0,d0
	move.b	$c00(a1),d0
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)+
	or.b	#1<<6,$e00(a1)			; set output mode

	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT

	move.l	(a2)+,d1
	beq.b	.nocustom
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.nocustom
	

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

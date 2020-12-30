***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   IMPERIAL TUNES/PARASITE WHDLOAD SLAVE    )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            December 2020                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 30-Dec-2020	- work started
;		- and finished some hours later, all parts (including
;		  hidden part) patched, interrupts fixed, invalid
;		  copperlist entries fixed (x440), out of bounds blits
;		  fixed (x2), blitter waits added (x4), copperlist problem
;		  fixed


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
	dc.l	0		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
;	dc.w	0		; ws_kickname
;	dc.l	0		; ws_kicksize
;	dc.w	0		; ws_kickcrc

; v17
;	dc.w	.config-HEADER	; ws_config


;.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Parasite/ImperialTunes",0
	ENDC

.name	dc.b	"Imperial Tunes",0
.copy	dc.b	"1992 Parasite",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (30.12.2020)",0
	CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; install level 2 interrupt
	bsr	SetLev2IRQ


	; load boot
	move.l	#$9800,d0
	move.l	#$4c00,d1
	lea	$70000,a0

	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)
	move.l	d5,d0
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$5920,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

	; patch boot
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)	


	; set default interrupts
	pea	AckVBI(pc)
	move.l	(a7)+,$6c.w
	pea	AckLev6(pc)
	move.l	(a7)+,$78.w

	; enable needed DMA channels
	move.w	#$83c0,$dff096

	; relocate stack to avoid crash in intro part
	lea	$2000.w,a0
	move.l	a0,USP
	add.w	#1024,a0
	move.l	a0,a7

	; run demo
	jmp	$4500(a5)




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

AckVBI_R
	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rts

AckVBI	bsr.b	AckVBI_R
	rte

AckLev6_R
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rts

AckLev6	bsr.b	AckLev6_R
	rte

WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts


; ---------------------------------------------------------------------------

PLBOOT	PL_START
	PL_PSA	$4598,.load1,$45be
	PL_PSA	$45be,.load2,$460e
	PL_P	$4612,.PatchIntro
	PL_SA	$450a,$4514		; skip Forbid()
	PL_END



.load1	moveq	#$37,d0
	moveq	#$15,d2
	moveq	#$52,d1
	lea	$16000,a0
	bra.b	Load

.load2	moveq	#5,d0
	moveq	#4,d2
	moveq	#$27,d1
	lea	$60000,a0
	bra.b	Load

.PatchIntro

	; show title picture for at least 3 seconds
	moveq	#3*10,d0
	move.l	resload(pc),a0
	jsr	resload_Delay(a0)

	; set default copperlist as copperlist DMA is enabled
	; in the intro without a valid copperlist
	lea	$1000.w,a0
	move.l	a0,$dff080

	; initialise copperlist buffers
	lea	$21000+$196c,a0
	move.w	#($1a48-$196c)/4-1,d7
	bsr.b	FixCop

	lea	$21000+$1a78,a0
	move.w	#($1b54-$1a78)/4-1,d7
	bsr.b	FixCop
	

	lea	PLINTRO(pc),a0
	pea	$21000
PatchAndRun
	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)



; d0.w: track
; d1.w: number of sectors to laod
; d2.w: sector offset in track
; a0.l: destination

Load	mulu.w	#512*11*2,d0
	mulu.w	#512,d2
	add.l	d2,d0
	mulu.w	#512,d1
	moveq	#1,d2
	move.l	resload(pc),a1
	jmp	resload_DiskLoad(a1)


FixCop
.loop	move.w	#$01fe,(a0)+
	addq.w	#2,a0
	dbf	d7,.loop
	rts

; ---------------------------------------------------------------------------

PLINTRO	PL_START
	PL_P	$1588,.load
	PL_R	$151e			; step to track
	PL_R	$1512			; wait
	PL_R	$1608			; load track
	PL_R	$166a			; decode
	PL_R	$179a			; drive motor off
	PL_R	$14fc			; don't change ADKCON

	PL_SA	$13de,$13ee		; skip ADKCON write
	PL_SA	$144a,$145a		; skip ADKCON write

	PL_P	$86,.PatchMain
	PL_P	$14d0,.PatchHiddenPart

	PL_PSS	$2130,AckLev6_R,2
	PL_PS	$219a,AckLev6_R

	PL_ORW	$284+2,1<<3		; enable level 2 interrupts
	
	PL_SA	$140,$14a		; skip Forbid()

	PL_PS	$4b4,.FixBlit		; fix out of bounds blit
	PL_PS	$626,.FixBlit		; as above

	PL_PS	$39c,.WaitBlit1
	PL_PSS	$fb8,.WaitBlit2,2
	PL_END

.WaitBlit1
	lea	$21000+$12000,a0
	bra.w	WaitBlit

.WaitBlit2
	bsr	WaitBlit
	move.l	#$ffffffff,$44(a6)
	rts


.FixBlit
	cmp.l	#$80000,d1
	bcc.b	.noblit
	move.w	#$804,$58(a6)
.noblit
	rts


.load	movem.w	$21000+$1864,d0/d2	; track/sector
	move.w	$21000+$1868,d1		; number of sectors to load
	move.l	$21000+$186e,a0		; destination
	bsr.w	Load

	; delay loading a bit so the "LOADING" vector
	; will be visible
	move.w	$21000+$1868,d0		; number of sectors to load
	lsr.w	#2,d0
	move.l	resload(pc),a0
	jmp	resload_Delay(a0)	


.PatchMain
	lea	PLMAIN(pc),a0
	pea	$5eb00
	bra.w	PatchAndRun

.PatchHiddenPart
	lea	PLHIDDEN(pc),a0
	pea	$46000
	bra.w	PatchAndRun

; ---------------------------------------------------------------------------

PLMAIN	PL_START
	PL_R	$1770			; step to track 0
	PL_P	$16f8,.load
	PL_R	$16ec			; wait
	PL_R	$17f2			; load track
	PL_R	$1858			; decode
	PL_SA	$1654,$1664		; skip ADKCON write
	PL_R	$1968			; drive motor off

	PL_PSS	$3e72,AckLev6_R,2
	PL_PSS	$3edc,AckLev6_R,2
	PL_PSS	$4ff0,AckLev6_R,2
	PL_PS	$505a,AckLev6_R

	PL_PS	$242a,.WaitBlit1
	PL_PSS	$2786,.WaitBlit2,2

	PL_END

.WaitBlit1
	bsr	WaitBlit
	add.w	d1,d3
	move.l	a0,$54(a6)
	rts

.WaitBlit2
	bsr	WaitBlit
	move.l	#$ffffffff,$44(a6)
	rts

.load	movem.w	$5eb00+$3602,d0/d2	; track/sector
	move.w	$5eb00+$3606,d1		; number of sectors to load
	move.l	$5eb00+$360c,a0		; destination
	bsr	Load

	; if credits part data is loaded, a delay is
	; needed after loading, otherwise the credits
	; part is not displayed correctly
	movem.w	$5eb00+$3602,d0/d2	; track/sector
	cmp.w	#12,d0
	bne.b	.nocredits
	cmp.w	#02,d2
	bne.b	.nocredits

	move.w	$5eb00+$3606,d0		; number of sectors to load
	lsr.w	#2,d0
	move.l	resload(pc),a0
	jmp	resload_Delay(a0)

.nocredits
	rts


; ---------------------------------------------------------------------------

PLHIDDEN
	PL_START
	PL_ORW	$1c20+2,1<<3		; enable level 2 interrupts
	PL_PSS	$2512,AckLev6_R,2
	PL_PS	$257c,AckLev6_R
	PL_P	$28,QUIT
	PL_END

; ---------------------------------------------------------------------------




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
	move.b	$c00(a1),d0
	move.b	d0,(a2)

	not.b	d0
	ror.b	d0
	move.b	d0,RawKey-Key(a2)


	move.l	KbdCust(pc),d1
	beq.b	.noCust
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.noCust


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
KbdCust	dc.l	0

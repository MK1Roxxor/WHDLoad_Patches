***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*( S   UN TRACKER 2/ANALOG WHDLOAD SLAVE      )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            February 2019                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 08-Feb-2019	- work started
;		- and finished about 2.5 hours later, all OS stuff patched
;		  (DoIO, AddIntServer etc.), DMA wait in replayer fixed (x4),
;		  byte write to volume register fixed (x2), blitter waits
;		  added (x9), resident code disabled, access faults
;		  fixed (x2), all decrunchers (ByteKiller) relocated and
;		  error check added

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


.config	dc.b	"C1:B:Skip Intro;"
	dc.b	"C2:B:Disable Blitter Waits"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Analog/SunTracker2",0
	ENDC

.name	dc.b	"Sun Tracker 2",0
.copy	dc.b	"1990 Analog, Powerlords, Demons",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (08.02.2019)",0

	CNOP	0,4

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

; install level 2 interrupt
	bsr	SetLev2IRQ

; load boot
	lea	$2000.w,a0
	moveq	#0,d0
	move.l	#$400,d1
	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)

	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$D627,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT

.ok

	lea	$3000.w,a6		; fake exec library
	move.w	#$4ef9,d0
	pea	DoIO(pc)
	move.w	d0,-456(a6)
	move.l	(a7)+,-456+2(a6)

	pea	AddIntServer(pc)
	move.w	d0,-168(a6)
	move.l	(a7)+,-168+2(a6)

	pea	RemIntServer(pc)
	move.w	d0,-174(a6)
	move.l	(a7)+,-174+2(a6)


	move.w	#$4e75,-132(a6)		; Forbid()
	move.w	#$4e75,-138(a6)		; Permit()


; patch
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)


	move.l	a6,$4.w
	move.l	a6,a1			; StdIo
	pea	AckVBI(pc)
	move.l	(a7)+,$6c.w
	
	jmp	3*4(a5)



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



DoIO	cmp.w	#2,$1c(a1)		; only CMD_READ is supported
	bne.b	.exit

	movem.l	$24(a1),d1/a0
	move.l	$2c(a1),d0
	moveq	#1,d2
	move.l	resload(pc),a1
	jmp	resload_DiskLoad(a1)

.exit	rts

RemIntServer
	lea	VBIcust(pc),a0
	clr.l	(a0)
	rts

AddIntServer
	cmp.b	#5,d0			; only INTB_VB is supported
	bne.b	.exit

	lea	VBIcust(pc),a0
	move.l	IS_CODE(a1),(a0)	; store ptr to interrupt code

	pea	.NewVBI(pc)
	move.l	(a7)+,$6c.w

	move.w	#$c020,$dff09a		; enable VBI

.exit	rts


.NewVBI	movem.l	d0-a6,-(a7)
	move.l	VBIcust(pc),d0
	beq.b	.nocust

	move.l	d0,a0
	jsr	(a0)

.nocust	movem.l	(a7)+,d0-a6
AckVBI	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte
	

VBIcust	dc.l	0


PLBOOT	PL_START
	PL_P	$f2,PatchMain
	PL_P	$130,.PatchIntro
	PL_S	$20,8			; skip drive access

	PL_IFC1
	PL_B	$8a,$60			; activate "turbo load" :)
	PL_ENDIF	
	PL_END


.PatchIntro
	movem.l	d0-a6,-(a7)
	lea	PLINTRO(pc),a0
	lea	$64000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	jmp	$64000


PatchMain
	movem.l	d0-a6,-(a7)
	lea	PLMAIN(pc),a0
	lea	$29000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	jmp	$29000

PLMAIN	PL_START
	PL_PSS	$1ae8,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$1b00,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$1e2e,FixAudXVol,2	; fix byte write to volume register
	PL_S	$10,8			; skip drive access
	PL_S	$86,8			; skip drive access
	PL_S	$cc,8			; skip drive access
	PL_S	$4cc,8			; skip drive access
	PL_S	$522,8			; skip drive access
	PL_P	$e80,BK_DECRUNCH	; relocate ByteKiller decruncher
	PL_AW	$4c+4,-1		; fix loop counter

	PL_IFC2
	PL_ELSE
	PL_PSS	$1414,.wblit,2
	PL_PSS	$1438,.wblit,2
	PL_PSS	$145c,.wblit,2
	PL_PSS	$1482,.wblit,2

	PL_PSS	$1370,.wblit2,6

	PL_PS	$2392,.wblit3
	PL_PS	$23de,.wblit4

	PL_PS	$241a,.wblit3
	PL_PS	$2466,.wblit4
	PL_ENDIF

	PL_END

.wblit4	bsr.b	WaitBlit
	move.l	(a4,d7.l),$4c(a6)
	rts

.wblit3	bsr.b	WaitBlit
	move.w	#$0dc0,$40(a6)
	rts


.wblit2	bsr.b	WaitBlit
	clr.l	$64(a6)
	move.l	#$ffff0000,$44(a6)
	rts


.wblit	move.l	d2,$4c(a6)
	move.w	d7,$58(a6)

WaitBlit
	tst.b	$02(a6)
.wblit	btst	#6,$02(a6)
	bne.b	.wblit
	rts
	


PLINTRO	PL_START
	PL_S	$1a0f0,8		; skip drive access
	PL_SA	$1a136,$1a16c		; don't install resident code
	PL_P	$1a342,.PatchIntro2
	PL_P	$1a6d0,BK_DECRUNCH	; relocate ByteKiller decruncher
	PL_END


.PatchIntro2
	movem.l	d0-a6,-(a7)
	lea	PLINTRO2(pc),a0
	lea	$40000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	jmp	$40000


PLINTRO2
	PL_START
	PL_SA	$74,$aa			; don't install resident code
	PL_PSS	$76e,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$786,FixDMAWait,2	; fix DMA wait in replayer
	PL_P	$a58,FixAudXVol		; fix byte write to volume register
	PL_S	$4,8			; skip drive access
	PL_S	$1f4,8			; skip drive access
	PL_P	$3ea,BK_DECRUNCH	; relocated ByteKiller decruncher
	PL_P	$20c,PatchMain
	PL_AW	$68+4,-1		; fix loop counter
	PL_END


FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d0
.loop	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait
	dbf	d0,.loop
	movem.l	(a7)+,d0/d1
	rts

FixAudXVol
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
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



; Bytekiller decruncher
; resourced and adapted by stingray
;
; a0.l: source
; a1.l: destination

BK_DECRUNCH
	bsr.b	.decrunch
	tst.l	d5
	beq.b	.ok

; checksum doesn't match, file corrupt
	pea	.ErrTxt(pc)
	pea	(TDREASON_FAILMSG).w
	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	
.ok	rts

.ErrTxt	dc.b	"Decrunching failed, file corrupt!",0
	cnop	0,4

.decrunch
	move.l	(a0)+,d0		; packed length
	move.l	(a0)+,d1		; unpacked length
	move.l	(a0)+,d5		; checksum
	add.l	d0,a0			; a0: end of packed data
	lea	(a1,d1.l),a2		; a2: end of unpacked data
	move.l	-(a0),d0		; get first long
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

;*---------------------------------------------------------------------------
;  :Program.	escapefromcolditz.asm
;  :Contents.	Slave for "Escape from Colditz"
;  :Author.	Bored Seal, Wepl
;  :Version.	$Id: EscapeFromColditz.asm 1.2 2015/01/24 19:33:31 wepl Exp wepl $
;  :History.	09.02.02 1.0 by Bored Seal
;		24.01.14 quitkey changed from F10 to F8
;		16.07.15 StingRay
;		- byte write to volume register fixed
;		- keyboard handling rewritten
;		- interrupts fixed
;		- tunnel exit bug fixed (thanks to Aperture!)
;		- blitter waits disabled on 68000 machines, CUSTOM1
;		  can be used to force blitter waits on 68000
;		- timing in intro fixed
;		- patch list used
;		- source cleaned up and optimised
;		17.12.22 StingRay
;		- random crashes fixed (issue #4143)
;		- minor size optimising
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9, ASM-Pro 1.16
;  :To Do.	- check BaseMem size (why $86000?), clean up/redo blitter
;		  wait patches
;---------------------------------------------------------------------------*

		INCDIR	SOURCES:Include/
		INCLUDE	whdload.i

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $57		; F8
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



	IFD	BARFLY
	OUTPUT	"wart:es/escapefromcolditz/EscapeFromColditz.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC


HEADER	SLAVE_HEADER		; ws_security + ws_ID
	dc.w	17		; ws_version
	dc.w	FLAGS		; flags
	dc.l	$86000		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	dc.w	.dir-HEADER	; ws_CurrentDir
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


.config	dc.b	"C1:B:Force Blitter Waits on 68000"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/EscapeFromColditz/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Escape from Colditz",0
.copy	dc.b	"1990 Digital Magic Software",0
.info	dc.b	"installed & fixed by Bored Seal with C-Fou! & StingRay",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.3 (17.12.2022)",0

Name	dc.b	"df1:colditz_demo",0
	CNOP	0,2



TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
FORCEBLITWAITS	dc.l	0
		dc.l	TAG_END



Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2


	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


	lea	Name(pc),a0
	lea	$80.w,a1
	move.l	a1,a5
	bsr	LoadFile


	move.l	FORCEBLITWAITS(pc),d0
	bne.b	.doblits
	move.l	CPUFLAGS(pc),d0
	lsr.l	#1,d0
	bcc.w	.noblit

.doblits	move.l	#$4e714eb9,d0

		move.w	d0,$3514.w
		pea	Blit109(pc)
		move.l	(sp)+,$3516.w

		move.w	d0,$420.w
		move.w	d0,$434.w
		pea	Blit1601(pc)
		move.l	(sp),$422.w
		move.l	(sp)+,$436.w



	move.l	a5,a0
		move.w	#$4ef9,d0
		move.w	d0,(a0)+
		pea	BlitFixD3A6(pc)		; $80
		move.l	(sp)+,(a0)+

		move.w	d0,(a0)+		; $86
		pea	BlitFixA0A6(pc)
		move.l	(sp)+,(a0)+

		move.w	d0,(a0)+		; $8c
		pea	BlitFixD2A6(pc)
		move.l	(sp)+,(a0)+

		move.w	d0,(a0)+		; $92
		pea	BlitFixD5A6(pc)
		move.l	(sp)+,(a0)+

		move.w	d0,(a0)+		; $98
		pea	BlitFixD0A6(pc)
		move.l	(sp)+,(a0)+

		move.w	d0,(a0)+		; $9e
		pea	BlitFixD1A6(pc)
		move.l	(sp)+,(a0)+


		move.l	#$4eb80080,d0		; jsr $80.w
		move.l	d0,$7a40.w

		addq.l	#6,d0			; jsr $86.w
		move.l	d0,$3624.w
		move.l	d0,$3640.w
		move.l	d0,$5b2.w

		addq.l	#6,d0			; jsr $8c.w
		move.l	d0,$192.w

		addq.l	#6,d0			; jsr $92.w
		move.l	d0,$758a.w

		addq.l	#6,d0			; jsr $98.w
		move.l	d0,$760a.w
		move.l	d0,$7620.w
		move.l	d0,$604.w

		addq.l	#6,d0			; jsr $9e.w
		move.l	d0,$628.w


.noblit

; stingray, 16-jul-2015
	lea	PLMAIN(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)


	; V1.3, 17.12.2022
	; Game needs to run in user mode, otherwise crashes when
	; certain keys (F5 for example) are pressed can occur
	move.w	#0,sr
	jmp	$1b18(a5)



BlitFixA0A6	move.w	a0,$58(a6)
		bra.b	BlitWait

BlitFixD0A6	move.w	d0,$58(a6)
		bra.b	BlitWait

BlitFixD1A6	move.w	d1,$58(a6)
		bra.b	BlitWait

BlitFixD2A6	move.w	d2,$58(a6)
		bra.b	BlitWait

BlitFixD5A6	move.w	d5,$58(a6)
		bra.b	BlitWait

BlitFixD3A6	move.w	d3,$58(a6)
BlitWait	btst	#6,2(a6)
		bne.b	BlitWait
		rts

Blit109		move.w	#$109,$58(a6)
		bra.b	BlitWait

Blit1601	move.w	#$1601,$58(a6)
		bra.b	BlitWait




LoadFile	movem.l	a0-a2/d0-d1,-(sp)
		;lea	4(a0),a0		;skip DF1: string
	addq.w	#4,a0
		move.l	resload(pc),a2
		jsr	resload_LoadFile(a2)
		move.l	d0,d1
		movem.l	(sp)+,a0-a2/d0-d1
		rts

resload		dc.l	0


PLMAIN	PL_START
	PL_P	$1964,FixAudXVol	; fix byte write to volume register
	PL_PSS	$167e,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$1696,FixDMAWait,2	; fix DMA wait in replayer
	PL_W	$3e9a,$ffec		; fix tunnel exit bug, thanks Aperture!
	PL_PS	$82bc,.ackBlt
	PL_PS	$82c4,.ackCop
	PL_PS	$82d6,.ackVBI

	PL_PS	$c93e,FixDMAWait	; fix DMA wait in sample player
	PL_PS	$c952,FixDMAWait	; fix DMA wait in sample player

	PL_P	$c01e,LoadFile
	PL_R	$bfee			; Loader init/load directory

	PL_SA	$1b26,$1b30		; skip CPU delay	

	PL_PSS	$36e0,.setkbd,4		; install our own level 2 interrupt
	PL_R	$825e			; end level 2 interrupt code

	PL_W	$86d6,$ffff		; fix copperlist end

	PL_PS	$2e9e,.fixtiming	; fix timing in intro
	PL_L	$2e80+2,50*13		; adapt counter value, show each screen
					; for 13 seconds

	PL_END


.fixtiming
	bsr	WaitRaster
	subq.l	#1,$80+$2d9a.w		; original code, optimised a bit :)
	rts


.setkbd	bsr.b	SetLev2IRQ
	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts

.kbdcust
	moveq	#0,d0
	move.b	RawKey(pc),d0
	jmp	$80+$8250		; call original level 2 interrupt code



.ackBlt	move.w	#1<<6,$9c(a0)
	move.w	#1<<6,$9c(a0)
	rts

.ackCop	move.w	#1<<4,$9c(a0)
	move.w	#1<<4,$9c(a0)
	rts

.ackVBI	move.w	#1<<5,$9c(a0)
	move.w	#1<<5,$9c(a0)
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
	beq.w	.end

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
	bra.w	EXIT

.exit	bra.w	QUIT


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)


KillSys	move.w	#$7fff,$dff09a
	bsr	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
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

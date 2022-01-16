***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    HARMAGEDON/INFECT WHDLOAD SLAVE         )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              May 2016                                   *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 16-Jan-2022	- all remaining patches done
;		- filling routine in "72SID" fixed to work on fast machines 

; 15-Jan-2022	- access fault in dot landscape part fixed
;		- copperlist termination fixed
;		- read from $ffffffff fixed
;		- freeze after Harmagedon logo fixed	
;		- lots of Bplcon0 color bit fixes
;		- line drawing routines fixed (Bltcon0/byte write to BltCon1)
;		- invalid copperlist entries in rotation zoomer part fixed

; 24-May-2016	- spaces at end of file names removed, loader patch
;		  adapted
;		- interrupts in ProRunner replayer fixed
;		- adapted effect that is shown while the tables for the
;		  dot vector are precalculated, it's now shown for at least
;		  9 seconds also on very fast machines

; 23-May-2016	- work started

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_ReqAGA
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
	dc.l	524288*4	; ws_BaseMemSize
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
;	dc.w	0		; ws_kickname
;	dc.l	0		; ws_kicksize
;	dc.w	0		; ws_kickcrc
;
; v17
;	dc.w	.config-HEADER	; ws_config


;.config	dc.b	0


.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Infect/Harmagedon/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Harmagedon",0
.copy	dc.b	"1993 Infect",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.01 (16.01.2022)",0
Name	dc.b	"loader",0
	CNOP	0,4

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

; install keyboard irq
	bsr	SetLev2IRQ

; load loader
	lea	Name(pc),a0
	lea	$1c0000,a1
	move.l	a1,a5
	jsr	resload_LoadFileDecrunch(a2)	
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$9e48,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
.ok


; patch it
	lea	PLLOADER(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

; and start the show
	lea	$1000.w,a7

	jmp	(a5)



QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)


KillSys	move.w	#$7fff,$dff09a
	bsr	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	rts



PLLOADER
	PL_START
	PL_PSS	$a12,.ackVBI,2
	PL_ORW	$9b8+2,1<<9		; set Bplcon0 color bit
	PL_P	$ac6,.loadfile
	PL_ORW	$25b0+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$2ba4,.ackLev6,2
	PL_PS	$2c00,.ackLev6
	PL_PS	$44c,.fixpredotvec
	PL_ORW	42+2,1<<3		; enable level 2 interrupt

	PL_PS	$3d6,.PatchDotScape
	PL_SA	$67a,$684		; skip reading from $ffffffff
	PL_L	$2634,-2		; fix copperlist termination
	PL_L	$2638,-2		; as above
	;PL_PS	$a0c,.debug
	;PL_W	$3c4,$4e71
	PL_B	$3c4,$6f		; bne -> ble
	;PL_B	$23e4,$6f
	PL_PS	$41c,.Patch72SID
	PL_PS	$538,.PatchMegaCop
	PL_PS	$54e,.PatchLineTunnel
	PL_PS	$6ce,.PatchDotSun
	PL_PS	$6ee,.PatchManyPlanes
	PL_PS	$744,.PatchRedigVec
	PL_PS	$92e,.PatchDotMattSC
	PL_PS	$9ae,.PatchStars
	PL_END

.debug	addq.w	#1,$1cafec
	move.w	$1cafec,$dff180
	rts

.PatchDotScape
	lea	PLDOTSCAPE(pc),a0
	pea	$142000
.PatchAndRun
	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)

.Patch72SID
	lea	PL72SID(pc),a0
	pea	$191000
	bra.b	.PatchAndRun

.PatchMegaCop
	lea	PLMEGACOP(pc),a0
	pea	$133000

	lea	$133000+$3146,a1	; start of copperlist
.fixcop	cmp.l	#$0000fffe,(a1)
	bne.b	.ok
	move.l	#-2,(a1)
.ok	addq.w	#4,a1
	cmp.l	#-2,(a1)
	bne.b	.fixcop

	bra.b	.PatchAndRun

.PatchLineTunnel
	lea	PLLINETUNNEL(pc),a0
	pea	$f7000
	bra.b	.PatchAndRun

.PatchDotSun
	lea	PLDOTSUN(pc),a0
	pea	$133000
	bra.b	.PatchAndRun

.PatchManyPlanes
	lea	PLMANYPLANES(pc),a0
	pea	$50000
	bra.b	.PatchAndRun

.PatchRedigVec
	lea	PLREDIGVEC(pc),a0
	pea	$192000
	bra.b	.PatchAndRun

.PatchDotMattSC
	lea	PLDOTMATTSC(pc),a0
	pea	$100000
	bra.b	.PatchAndRun

.PatchStars
	lea	PLSTARS(pc),a0
	pea	$150000
	bra.w	.PatchAndRun

.fixpredotvec
	lea	.flag(pc),a0
	st	(a0)			; start counting VBI's
	jsr	$132000			; precalc tables for dot vector

.wait	move.w	Count(pc),d0
	cmp.w	#50*9,d0		; show effect for 9 seconds
	blt.b	.wait

	lea	.flag(pc),a0		; not really required but saves
	sf	(a0)			; a few cycles in the VBI :)
	rts

.loadfile
	move.l	a0,a2
	moveq	#12-1,d7
.findend
	cmp.b	#" ",(a2)+
	beq.b	.end
	dbf	d7,.findend
	bra.b	.skip
.end	clr.b	-1(a2)	
.skip

	move.l	resload(pc),a2
	jmp	resload_LoadFileDecrunch(a2)

.ackVBI	move.w	.flag(pc),d0
	beq.b	.nocount
	lea	Count(pc),a0
	addq.w	#1,(a0)
.nocount

	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rts
.ackLev6
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rts	

.flag	dc.w	0
Count	dc.w	0



; dot landscape after Harmagedon picture
PLDOTSCAPE
	PL_START
	PL_PS	$244,.ClipD2
	PL_ORW	$19de+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1a06+2,1<<9		; set Bplcon0 color bit
	PL_END
	

.ClipD2	moveq	#0,d2
	move.w	a5,d2
	add.w	d5,d2
	lsl.l	#8,d2
	rts

; red/white vector "ball"
PL72SID	PL_START
	PL_ORW	$a11a+2,1<<9
	PL_ORW	$a12a+2,1<<9
	PL_PSS	$4b2,.FixBltCon1,4
	PL_ORW	$490+2,1<<8		; fix BltCon0 value
	PL_P	$550,.FixFill
	PL_END

.FixFill
	tst.b	$02(a5)
.waitblit
	btst	#6,$02(a5)
	bne.b	.waitblit
	jmp	$191000+$55c
		

.FixBltCon1
	and.w	#$ff,d5
	move.w	d5,$42(a5)
	movem.w	d1/d2,$62(a5)
	rts

; Rotation Zoomer
PLMEGACOP
	PL_START
	PL_ORW	$3152+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$31a6+2,1<<9		; set Bplcon0 color bit
	PL_END

PLLINETUNNEL
	PL_START
	PL_ORW	$1aee+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3a2+2,1<<8		; fix BltCon0 value
	PL_W	$3c4,$0245		; and.b #$fd,d5 -> and.w #$fd,d5
	PL_L	$3c8,$3B450042		; move.w d5,$42(a5)
	PL_END
	

; radial dots
PLDOTSUN
	PL_START
	PL_ORW	$386+2,1<<9		; set Bplcon0 color bit
	PL_END
	

; wireframe vector "ball"
PLMANYPLANES
	PL_START
	PL_ORW	$2dc+2,1<<8		; fix BltCon0 value
	PL_W	$2fc,$0245		; and.b #$fd,d5 -> and.w #$fd,d5
	PL_L	$300,$3B450002		; move.w d5,2(a5)
	PL_END
	

; large object composed of vector cubes
PLREDIGVEC
	PL_START
	PL_ORW	$de2+2,1<<8		; fix BltCon0 value
	PL_PSS	$e04,.FixBltCon1,2
	PL_B	$446,$6f		; bne -> ble
	PL_END

.FixBltCon1
	and.w	#$ff,d5
	move.w	d5,$42(a5)
	move.w	d1,$62(a5)
	rts

; dot scroller
PLDOTMATTSC
	PL_START
	PL_ORW	$19f2+2,1<<9		; set Bplcon0 color bit
	PL_END

; 3d starfield, end part
PLSTARS	PL_START
	PL_ORW	$9254+2,1<<9		; set Bplcon0 color bit
	PL_END

AckVBI	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rte


WaitRaster
.wait1	btst	#0,$dff005
	beq.b	.wait1
.wait2	btst	#0,$dff005
	bne.b	.wait2
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
	bra.w	EXIT

.exit	bra.w	QUIT


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine





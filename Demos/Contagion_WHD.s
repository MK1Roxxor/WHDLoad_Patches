***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(     CONTAGION/APPENDIX WHDLOAD SLAVE       )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             October 2019                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 11-Oct-2019	- remaining parts patched
;		- bug in glenz part fixed (buggy loop counter in fade routine
;		  trashed the bitplane pointers)
;		- delay added in loader patch to fix the "Glenz Part is not
;		  shown" problem
;		- read from "FCI Rules!" pointer in replayer disabled
;		- some size optimising
;		- support for hidden part (CUSTOM1) added
;		- looks like the patch is finished...
;		- Bplcon0 color bit fixes (x45), wrong copper instructions
;		  fixed (x2), interrupts fixed, blitter wait added, access
;		  fault fixed, copper problems fixed (x2, glenz part),
;		  BLTCON0 settings fixed (x16, line drawing routine), BLTCON1
;		  settings fixed (line drawing routine)

; 10-Oct-2019	- work started
;		- most disk 1 parts patched (many hours of work!)
;		- bitplane pointers in glenz part are trashed for whatever
;		  reason, part isn't displayed in the demo either...

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
	dc.l	524288*2	; ws_BaseMemSize
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


.config	dc.b	"C1:B:Run Hidden Part"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Appendix/Contagion",0
	ENDC

.name	dc.b	"Contagion",0
.copy	dc.b	"1995 Appendix",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (11.10.2019)",0

	CNOP	0,4

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

; install level 2 interrupt
	bsr	SetLev2IRQ

; load boot
	lea	$2000.w,a0
	move.l	#$400,d0
	move.l	#$5e00,d1
	moveq	#1,d2
	move.l	a0,a5
	move.l	d1,d5
	jsr	resload_DiskLoad(a2)

	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$943c,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT

.ok

; patch
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

; set chip mem size
	move.l	#$100000,$1272(a5)

; and start demo
	jmp	(a5)





QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)


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



PLBOOT	PL_START
	PL_SA	$0,$19c			; skip config/memory check
	PL_SA	$1be,$1d6		; skip writes to ECS/AGA registers
	PL_SA	$1e6,$1ec		; skip write to BEAMCON0
	PL_R	$3276			; disable disk request
	PL_P	$2f2c,Load
	PL_P	$15d4,AckLev6
	PL_SA	$20f2,$20fe		; skip read from "FCI Rules!" pointer
	PL_P	$15e0,AckVBI

	PL_IFC1
	PL_B	$200,$60
	PL_PS	$9b8,PatchHiddenPart
	PL_ENDIF

	PL_PS	$250,PatchIntro		; intro
	PL_PS	$2be,PatchPresents	; starfield/title
	PL_PS	$2e6,PatchCredits	; credits
	PL_PS	$336,PatchSkullPic	; skull picture/vector
	PL_PS	$34c,PatchTitle		; vector explosion/title picture
	PL_PS	$3b6,PatchZoom		; zoom
	PL_PS	$3ec,PatchVector	; plasma vector
	PL_PS	$438,PatchInterference	; interference lines
	PL_PS	$44e,PatchTunnel	; tunnel
	PL_PS	$464,PatchRotZoom	; dolphin picture/rotation zoom
	PL_PS	$48c,PatchFlyingLines	; flying lines
	PL_PS	$4b4,PatchVectorScroll	; vector scroller
	PL_PS	$504,PatchNoAGA		; this is no AGA demo
	PL_PS	$51e,PatchGreetings	; greetings
	PL_PS	$5a0,PatchKeftales	; realtime keftales
	PL_PS	$5a6,PatchPreKeftales	; pre-keftales
	PL_PS	$5c2,PatchLogo		; mapped Appendix logo
	PL_PS	$61c,PatchGlenz		; glenz
	PL_PS	$638,PatchBBS		; BBS advert
	PL_PS	$656,PatchAnim		; animated head, this part is not shown
	PL_PS	$690,PatchInsertDisk2

	PL_PS	$71c,PatchText		; long text
	PL_PS	$834,PatchPic		; "Enterprise" picture
	PL_PS	$85c,PatchTheEnd	; "The End" picture
	PL_PS	$884,PatchEndScroll	; vertical end scroller
	PL_END


PatchHiddenPart
	lea	PLHIDDENPART(pc),a0
	bra.w	Patch55k

PLHIDDENPART
	PL_START
	PL_ORW	$484+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$4e0+2,1<<9		; set BPLCON0 color bit
	PL_PSS	$74,AckVBI_R,2
	PL_END


PatchIntro
	lea	PLINTRO(pc),a0
	bra.w	Patch55k


; part 1: "No AGA"
PLINTRO	PL_START	
	PL_ORW	$292+2,1<<9		; set BPLCON0 color bit
	PL_P	$dc,AckVBI
	PL_P	$ee,AckVBI
	PL_END
	

; part 2: starfield
PatchPresents
	lea	PLPRESENTS(pc),a0
	lea	$90000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$90000	

PLPRESENTS
	PL_START
	PL_ORW	$50a+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$5ae+2,1<<9		; set BPLCON0 color bit
	PL_P	$1fe,AckVBI
	PL_END
	
; part 3: credits
PatchCredits
	lea	PLCREDITS(pc),a0
	bra.w	Patch55k

PLCREDITS
	PL_START
	PL_PS	$10,WaitBlit
	PL_ORW	$248+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$334+2,1<<9		; set BPLCON0 color bit
	PL_P	$90,AckVBI
	PL_END

WaitBlit
	lea	$dff000,a6
	tst.b	02(a6)
.wb	btst	#6,$02(a6)
	bne.b	.wb
	rts


; part 4: perspective/vector
PatchSkullPic
	lea	PLSKULLPIC(pc),a0
	bra.w	Patch80k

PLSKULLPIC
	PL_START
	PL_PS	$48,WaitBlit
	PL_PSS	$ea,AckVBI_R,2
	PL_END


; part 5: vector explosion/title picture
PatchTitle
	lea	PLTITLE(pc),a0
	lea	$55000,a1
	bra.w	Patch55k

PLTITLE
	PL_START
	PL_ORW	$1080+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$10bc+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$11a4+2,1<<9		; set BPLCON0 color bit
	PL_P	$118,AckVBI
	PL_W	$10a4,$1fe		; BPLCON3 -> NOP
	PL_W	$10e0,$1fe		; BPLCON3 -> NOP
	PL_END

; part 6: zoom
PatchZoom
	lea	PLZOOM(pc),a0
	bra.w	Patch80k

PLZOOM	PL_START
	PL_ORW	$b6e+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$156e+2,1<<9		; set BPLCON0 color bit
	PL_P	$50,AckVBI
	PL_END

; part 7: "plasma vector"
PatchVector

; fix BLTCON0 table
	lea	$55000,a1
	lea	$4b54(a1),a2
	move.w	#($4b74-$4b54)/2-1,d7
.loop	or.w	#1<<8,(a2)+		; set SRCD = 1
	dbf	d7,.loop

	lea	PLVECTOR(pc),a0
	bra.w	Patch55k

PLVECTOR
	PL_START
	PL_ORW	$efa+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$372e+2,1<<9		; set BPLCON0 color bit
	PL_PS	$1a,WaitBlit
	PL_P	$66,AckVBI

	PL_PS	$696,.FixBltCon1
	PL_END

.FixBltCon1
	and.w	#$ff,d0
	move.w	d2,d4
	sub.w	d3,d2
	moveq	#6,d5
	rts


; part 8: "interference lines"
PatchInterference
	lea	PLINTERFERENCE(pc),a0
	bra.w	Patch80k

PLINTERFERENCE
	PL_START
	PL_W	$6a8,$1fe		; FMODE -> NOP
	PL_W	$6ac,$1fe		; BPLCON3 -> NOP
	PL_W	$6b0,$1fe		; BPLCON4 -> NOP
	PL_ORW	$6b4+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$74c+2,1<<9		; set BPLCON0 color bit
	PL_PSS	$e6,AckVBI_R,2
	PL_END
		
; part 9: tunnel
PatchTunnel
	lea	PLTUNNEL(pc),a0
	bra.w	Patch55k

PLTUNNEL
	PL_START
	PL_W	$582,$1fe		; FMODE -> NOP
	PL_W	$586,$1fe		; BPLCON3 -> NOP
	PL_W	$58a,$1fe		; DIWHIGH -> NOP
	PL_W	$58e,$1fe		; BPLCON4 -> NOP
	PL_P	$68,AckVBI
	PL_END

; part 10: circle/dolphin picture/rotation zoomer
PatchRotZoom
	lea	PLROTZOOM(pc),a0
	bra.w	Patch80k

PLROTZOOM
	PL_START
	PL_W	$54f4,$1fe		; BPLCON3 -> NOP
	PL_W	$5500,$1fe		; BPLCON4 -> NOP
	PL_W	$5554,$1fe		; BPLCON3 -> NOP
	PL_ORW	$55d4+2,1<<9		; set BPLCON0 color bit
	PL_W	$55e8,$1fe		; BPLCON3 -> NOP
	PL_PSS	$74,AckVBI_R,2

	PL_L	$7ae+2,$01000200	; fix buggy BPLCON0 instruction
	PL_L	$964+2,$01000200	; fix buggy BPLCON0 instruction
	PL_ORW	$8264+2,1<<9		; set BPLCON0 color bit

	PL_W	$25bd4,$1fe		; FMODE -> NOP
	PL_END


; part 11: flying lines
PatchFlyingLines
	lea	PLFLYINGLINES(pc),a0
	bra.w	Patch55k

PLFLYINGLINES
	PL_START
	PL_ORW	$1560+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$16a0+2,1<<9		; set BPLCON0 color bit
	PL_W	$1568,$1fe		; FMODE -> NOP
	PL_W	$156C,$1fe		; BPLCON3 -> NOP
	PL_W	$1570,$1fe		; DIWHIGH -> NOP
	PL_W	$1574,$1fe		; BPLCON4 -> NOP
	PL_P	$dc,AckVBI
	PL_END


; part 12: "Amiga Rules Forever" vector scroll
PatchVectorScroll
	lea	PLVECTORSCROLL(pc),a0
	bra.w	Patch80k

PLVECTORSCROLL
	PL_START
	PL_ORW	$10a0+2,1<<9		; set BPLCON0 color bit
	PL_W	$116c,$1fe		; BPLCON3 -> NOP
	PL_P	$ee,AckVBI
	PL_END


; part 13: "This is no AGA demo"
PatchNoAGA
	lea	PLNOAGA(pc),a0
	bra.w	Patch55k

PLNOAGA	PL_START
	PL_ORW	$1b6+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$222+2,1<<9		; set BPLCON0 color bit
	PL_P	$90,AckVBI
	PL_END

; part 14: greetings
PatchGreetings
	lea	PLGREETINGS(pc),a0
	bra.w	Patch80k

PLGREETINGS
	PL_START
	PL_ORW	$640+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$724+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$72c+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$788+2,1<<9		; set BPLCON0 color bit
	PL_PSS	$a6,AckVBI_R,2
	PL_END


; part 15: realtime keftales
PatchKeftales
	lea	PLKEFTALES(pc),a0
	lea	$60000,a1
	bra.w	PatchRun

PLKEFTALES
	PL_START
	PL_ORW	$a1e+2,1<<9		; set BPLCON0 color bit
	PL_W	$a26,$1fe		; FMODE -> NOP
	PL_W	$a2a,$1fe		; BPLCON3 -> NOP
	PL_W	$a2e,$1fe		; BPLCON4 -> NOP
	PL_P	$f6,AckVBI
	PL_R	$64a			; disable write to BEAMCON0
	PL_END

; part 16: pre-keftales
PatchPreKeftales
	lea	PLPREKEFTALES(pc),a0
	bra.w	Patch55k

PLPREKEFTALES
	PL_START
	PL_ORW	$908+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$958+2,1<<9		; set BPLCON0 color bit
	PL_W	$92c,$1fe		; BPLCON3 -> NOP
	PL_P	$88,AckVBI
	PL_END

; part 17: texture mapped Appendix logo
PatchLogo
	lea	PLLOGO(pc),a0
	bra.w	Patch80k

PLLOGO	PL_START
	PL_ORW	$6d3c+2,1<<9		; set BPLCON0 color bit
	PL_W	$6d40,$1fe		; FMODE -> NOP
	PL_R	$32a			; disable write to BEAMCON0
	PL_PSS	$46,AckVBI_R,2
	PL_END
	

; part 18: glenz vectors
PatchGlenz
	lea	PLGLENZ(pc),a0
	lea	$c9000,a1
	bra.w	PatchRun

PLGLENZ	PL_START
	PL_ORW	$d14+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$dbc+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$e48+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$e5c+2,1<<9		; set BPLCON0 color bit
	PL_P	$4a,AckVBI
	PL_P	$6c,AckVBI

	PL_W	$d20+2,$1c71		; fix DIWSTRT
	PL_W	$dc8+2,$1c71

	PL_B	$c62+1,13		; fix fade routine loop counter
	PL_END



; BBS advert
PatchBBS
	lea	PLBBS(pc),a0
	bra.w	Patch55k

PLBBS	PL_START
	PL_P	$b0,AckVBI
	PL_END
	


; part 19: head anim
PatchAnim
	lea	PLANIM(pc),a0
	lea	$92000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	moveq	#0,d0			; attn flags
	jmp	$92000

PLANIM	PL_START
	PL_ORW	$93a+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$94e+2,1<<9		; set BPLCON0 color bit
	PL_W	$956,$1fe		; FMODE -> NOP
	PL_W	$95a,$1fe		; BPLCON3 -> NOP
	PL_W	$95e,$1fe		; DIWHIGH -> NOP
	PL_W	$962,$1fe		; BPLCON4 -> NOP
	PL_PSS	$12a,AckVBI_R,2
	PL_END


; part 20: "Insert Disk 2"
PatchInsertDisk2
	lea	PLINSERTDISK2(pc),a0
	bra.b	Patch55k

PLINSERTDISK2
	PL_START
	PL_ORW	$2e2+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$396+2,1<<9		; set BPLCON0 color bit
	PL_P	$ac,AckVBI
	PL_END


; part 21: Text
PatchText
	lea	PLTEXT(pc),a0
	lea	$23900,a1
	bra.b	PatchRun

PLTEXT	PL_START
	PL_ORW	$dae+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$e96+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$efa+2,1<<9		; set BPLCON0 color bit
	PL_P	$fa,AckVBI
	PL_END


; Enterprise picture
PatchPic
	lea	PLPIC(pc),a0
	bra.b	Patch55k


PLPIC	PL_START
	PL_P	$7e,AckVBI
	PL_END	
	

; "The End"
PatchTheEnd
	lea	PLTHEEND(pc),a0
	bra.b	Patch80k


PLTHEEND
	PL_START
	PL_ORW	$1e6+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$24e+2,1<<9		; set BPLCON0 color bit
	PL_P	$84,AckVBI
	PL_END	


; end scroll
PatchEndScroll
	lea	PLENDSCROLL(pc),a0

Patch55k
	lea	$55000,a1
PatchRun
	move.l	a1,-(a7)
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)

Patch80k
	lea	$80000,a1
	bra.b	PatchRun


PLENDSCROLL
	PL_START
	PL_ORW	$16a+2,1<<9		; set BPLCON0 color bit
	PL_W	$16e,$1fe		; FMODE -> NOP
	PL_W	$172,$1fe		; BPLCON3 -> NOP
	PL_P	$146,AckVBI
	PL_END
	




; d0.w: start sector
; d1.w: sectors to load
; a0.l: destination

Load	move.w	d1,d7

	mulu.w	#512,d0
	mulu.w	#512,d1
	moveq	#-"0",d2
	add.b	$2000+$34e4+2,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)

	cmp.w	#$33,d7			; no delay if hidden part is
	beq.b	.noDelay		; being loaded

; delay is needed to display the glenz part, black screen otherwise
	move.w	d7,d0
	lsr.w	#1,d0
	jsr	resload_Delay(a2)
.noDelay
	rts


AckVBI_R
	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rts

AckVBI	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rte

AckCOP	move.w	#1<<4,$9c(a6)
	move.w	#1<<4,$9c(a6)
	rte

AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte


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


	lea	Key(pc),a2
	
	btst	#3,$1e+1(a0)			; PORTS irq?
	beq.b	.end

	btst	#3,$d00(a1)			; KBD irq?
	beq.b	.end

	moveq	#0,d0
	move.b	$c00(a1),d0
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)+

	move.l	(a2),d1
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

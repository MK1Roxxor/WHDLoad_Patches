***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       BOOK OF SONGS - WHD SLAVE            )*)---.---.   *
*   `-./                                                           \.-'   *
*			  (c)oded by StingRay				  *
*                         --------------------				  *
*                        July 2007/August 2008                            *
*                                                                         *
***************************************************************************

***************************************************
*** HISTORY					***
***************************************************

; 14-Aug-2023	- patch works on 68000 now (issue #6225)
;		- delay in keyboard interrupt fixed
;		; ws_keydebug handling removed from keyboard interrupt

; 27-Aug-2oo8	- touched again after a long time
;		  (thanks to New Zealand's best...)
;		- keyboard interrupt added so quit is possible on 68000
;		- tst.w $88(a6) -> move.w d0,$88(a6)
;		- tested in snoop mode, no faults


; 24-Jul-2oo7	- code cleaned up, parts of the first loaded
;		  file incorporated into the source for easier
;		  installing (would have required a rip of a 1764
;		  bytes file otherwise which is not easily possible
;		  with standard whdload tools)
;
;		- added date to the version string


; 24-Jul-2oo7	- work started
; v1.00		- loaders patched, empty dbf loops in replayer fixed,
;		  2x bplcon0 fixed, decruncher relocated in fastram,
;		  irq 040/060 fixed



	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i


HEADER	SLAVE_HEADER			; ws_Security + ws_ID
	dc.w	10			; ws_Version
	dc.w	WHDLF_NoError		; ws_flags
	dc.l	524288			; ws_BaseMemSize
	dc.l	0			; ws_ExecInstall
	dc.w	MainPatch-HEADER	; ws_GameLoader
	dc.w	.dir-HEADER		; ws_CurrentDir
	dc.w	0			; ws_DontCache
	dc.b	0			; ws_keydebug
	dc.b	$59			; ws_keyexit = F10
	dc.l	524288			; ws_ExpMem
	dc.w	.name-HEADER		; ws_name
	dc.w	.copy-HEADER		; ws_copy
	dc.w	.info-HEADER		; ws_info



.name	dc.b	"Book of Songs",0
.copy	dc.b	"1992 Complex",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	dc.b	"Version 1.01 (14.08.2023)",0
.dir	;dc.b	"sources:fixes/demos/book_of_songs/"
	dc.b	"files",0
	CNOP	0,2
		

MainPatch
	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2
	bsr	InitMem

	lea	$dff000,a6
	move.w	#$7fff,d0
	move.w	d0,$96(a6)
	move.w	d0,$9a(a6)
	move.w	d0,$9c(a6)
	move.w	d0,$9e(a6)

	lea	p1(pc),a1
	move.l	$118.w,d0
	moveq	#6-1,d1
.loop	move.w	d0,6(a1)
	swap	d0
	move.w	d0,2(a1)
	swap	d0
	add.l	#$2B70,d0
	addq.l	#8,a1
	dbf	d1,.loop

	lea	COPPERLIST(pc),a0
	lea	$300.w,a1
	move.l	a1,a2
	moveq	#COPPERSIZE/4-1,d7
.copy	move.l	(a0)+,(a1)+
	dbf	d7,.copy	


	move.l	a2,$80(a6)
	move.w	d0,$88(a6)

	move.w	#$83D0,$96(a6)
	move.w	#$9500,$9E(a6)
	lea	CopCols+2-COPPERLIST(a2),a0
	move.l	a0,$100.w


	lea	.picname(pc),a0
	move.l	$108.w,a1
	bsr	LOADER
	move.l	$108.w,a4
	move.l	$118.w,a0
	bsr	Decrunch

; fade up loader picture
	move.l	$118.w,a0
	add.l	#$104a0,a0
	move.l	$100.w,a1
	moveq	#32-1,d7
	bsr	Fade

; load/decrunch and relocate main menu
	lea	.menuname(pc),a0
	move.l	$108.w,a1
	bsr	LOADER
	move.l	$108.w,a4
	move.l	$114.w,a0
	bsr.w	Decrunch
	bsr.w	Relocate

; do necessary patches
	lea	$2474(a1),a0
	move.w	#$4ef9,(a0)+
	pea	LOADER(pc)
	move.l	(a7)+,(a0)
	move.w	#$4e75,$2830(a1)	; disable loader init

	move.l	#$4e714e71,$32de(a1)	; remove dbf
	lea	$32ea(a1),a0
	move.w	#$4eb9,(a0)+
	pea	.FixDbf(pc)		; fix empty dbf loop in replayer
	move.l	(a7)+,(a0)

	lea	$415a(a1),a0
	move.l	#$01000200,(a0)		; fix bplcon0

	move.l	#$4e714e71,d0
	move.w	d0,$c94(a1)		; remove disk 1 check/request
	move.w	d0,$d24(a1)		; remove disk 2 check/request
	move.l	d0,$cd6(a1)		; remove "insert disk" text


	move.w	#$C028,$12c+2(a1)	; enable level 2 interrupt

; fix irq
	pea	.IRQ(pc)
	lea	$2ae(a1),a0
	move.w	#$4ef9,(a0)+
	move.l	(a7)+,(a0)
	

; relocate decruncher
	pea	Decrunch(pc)
	lea	$2e76(a1),a0
	move.w	#$4ef9,(a0)+
	move.l	(a7)+,(a0)


	clr.l	$4.w			; disables opening disk.resource

	move.l	resload(pc),a0
	jsr	resload_FlushCache(a0)

; install keyboard interrupt
	bsr	SetLev2IRQ
	jmp	(a1)


.picname	dc.b	"loader.pic",0
.menuname	dc.b	"menu",0
		CNOP	0,2
	


.IRQ	move.w	#$20,$dff09c
	move.w	#$20,$dff09c
	rte


.FixDbf	bsr.b	.wait
	move.w	d0,$dff096
.wait	move.l	d1,-(a7)
	move.b	$dff006,d1
	addq.b	#5,d1
.wait2	cmp.b	$dff006,d1
	bne.b	.wait2
	move.l	(a7)+,d1
	rts

Relocate
	move.l	$14(a0),d0
	add.l	d0,d0
	add.l	d0,d0
	lea	$20(a0),a1
	move.l	4(a1,d0.l),d2
	subq.w	#1,d2
	lea	12(a1,d0.l),a2
	move.l	a1,d1
.loop	move.l	(a2)+,a3
	add.l	d1,(a3,d1.l)
	dbf	d2,.loop
	rts

Fade	moveq	#$10,d6
.floop	bsr.b	.wait		; for some reason, macro won't work
	bsr.b	.wait		; due to asmpro bug...
	bsr.b	.wait
	bsr.b	.wait
	move.l	a0,a2
	move.l	a1,a3
	move.w	d7,d5
.loop	moveq	#15,d2
	moveq	#1,d3
	moveq	#2,d4
.rgb	move.w	(a2),d0
	move.w	(a3),d1
	and.w	d2,d0
	and.w	d2,d1
	cmp.w	d0,d1
	blt.b	.inc
	bgt.b	.dec
.colok	lsl.w	#4,d2
	lsl.w	#4,d3
	dbf	d4,.rgb
	addq.l	#2,a2
	addq.l	#4,a3
	dbf	d5,.loop
	dbf	d6,.floop
	rts

.inc	add.w	d3,(a3)
	bra.b	.colok

.dec	sub.w	d3,(a3)
	bra.b	.colok


.wait	cmp.b	#$fe,$dff006
	bne.b	.wait
.w2	cmp.b	#$ff,$dff006
	bne.b	.w2
	rts

; a4: src
; a0: dst

Decrunch
	lea	(12,a4),a5
	add.l	(8,a4),a5
	move.l	a0,a3
	add.l	(4,a4),a0
	moveq	#$7F,d3
	moveq	#0,d4
	moveq	#3,d5
	moveq	#7,d6
	move.b	(3,a4),d4
	move.l	-(a5),d7
.lbC000184
	lsr.l	#1,d7
	bne.b	.lbC00018C
	move.l	-(a5),d7
	roxr.l	#1,d7
.lbC00018C
	bhs.b	.lbC0001B4
	moveq	#0,d2
.lbC000190
	move.w	d5,d1
	bsr.b	.lbC0001FC
	add.w	d0,d2
	cmp.w	d6,d0
	beq.b	.lbC000190
	subq.w	#1,d2
.lbC00019C
	move.w	d6,d1
.lbC00019E
	lsr.l	#1,d7
	bne.b	.lbC0001A6
	move.l	-(a5),d7
	roxr.l	#1,d7
.lbC0001A6
	roxr.b	#1,d0
	dbra	d1,.lbC00019E
	move.b	d0,-(a0)
	dbra	d2,.lbC00019C
	bra.b	.lbC0001F6

.lbC0001B4
	moveq	#1,d1
	bsr.b	.lbC0001FE
	moveq	#0,d1
	move.l	d0,d2
	move.b	(a4,d0.w),d1
	cmp.w	d5,d0
	bne.b	.lbC0001EA
	lsr.l	#1,d7
	bne.b	.lbC0001CC
	move.l	-(a5),d7
	roxr.l	#1,d7
.lbC0001CC
	blo.b	.lbC0001DE
.lbC0001CE
	move.w	d6,d1
	bsr.b	.lbC0001FC
	add.w	d0,d2
	cmp.w	d3,d0
	beq.b	.lbC0001CE
	add.w	d6,d2
	add.w	d6,d2
	bra.b	.lbC0001E8

.lbC0001DE
	move.w	d5,d1
	bsr.b	.lbC0001FC
	add.w	d0,d2
	cmp.w	d6,d0
	beq.b	.lbC0001DE
.lbC0001E8
	move.w	d4,d1
.lbC0001EA
	addq.w	#1,d2
	bsr.b	.lbC0001FE
.lbC0001EE
	move.b	(a0,d0.w),-(a0)
	dbra	d2,.lbC0001EE
.lbC0001F6
	cmp.l	a0,a3
	blo.b	.lbC000184
	rts

.lbC0001FC
	subq.w	#1,d1
.lbC0001FE
	moveq	#0,d0
.lbC000200
	lsr.l	#1,d7
	bne.b	.lbC000208
	move.l	-(a5),d7
	roxr.l	#1,d7
.lbC000208
	addx.l	d0,d0
	dbra	d1,.lbC000200
	rts


COPPERLIST
	DC.L	$1FFFE
	DC.L	$1000200
	DC.L	$8E2471
	DC.L	$903AD1
	DC.L	$920038
	DC.L	$9400D0
	DC.L	$1080000
	DC.L	$10A0000
	DC.L	$1020000
	DC.L	$1040000
	DC.L	$1006200
CopCols
.COL	SET	$180
	REPT	32
	dc.w	.COL,0
.COL	SET	.COL+2
	ENDR	

p1	dc.w	$E0,0,$E2,0
	dc.w	$E4,0,$E6,0
	dc.w	$E8,0,$EA,0
	dc.w	$EC,0,$EE,0
	dc.w	$F0,0,$F2,0
	dc.w	$F4,0,$F6,0
	dc.l	-2


COPPERSIZE	= *-COPPERLIST


InitMem
	move.l	HEADER+ws_ExpMem(pc),d0
	lea	.fast(pc),a0
	move.l	d0,(a0)

	move.l	#107000,d0
	bsr.b	.AllocChip
	move.l	d0,$114.w
	move.l	#2560,d0
	bsr.b	.AllocChip
	move.l	d0,$120.w
	move.l	#20480,d0
	bsr.b	.AllocChip
	move.l	d0,$110.w
	move.l	#318000,d0
	bsr.b	.AllocChip
	move.l	d0,$104.w
	add.l	#250000,d0
	move.l	d0,$118.w

	lea	.fast(pc),a0
	move.l	#14282,d0
	bsr.b	.alloc
	move.l	d0,$10C.w
	move.l	#250000,d0
	bsr.b	.alloc
	move.l	d0,$108.w
	move.l	#2048,d0
	bsr.b	.alloc
	move.l	d0,$11C.w
	rts

.AllocChip	
	lea	.chip(pc),a0
.alloc	move.l	d0,d1
	move.l	(a0),d0
	add.l	d1,(a0)
	rts

.chip	dc.l	$400			; start address
.fast	dc.l	0



resload	dc.l	0			; address of resident loader





; a0: filename
; a1: destination address

LOADER	movem.l	d0-d6/a0-a6,-(a7)
	moveq	#" ",d1
	move.b	(a0),d0
	or.b	d1,d0
	lsl.l	#8,d0

	move.b	1(a0),d0
	or.b	d1,d0
	lsl.l	#8,d0

	move.b	2(a0),d0
	or.b	d1,d0
	lsl.l	#8,d0

	move.b	3(a0),d0
	or.b	d1,d0
	

	cmp.l	#"file",d0
	bne.b	.skip
	addq.w	#6,a0
.skip	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)
	move.l	d0,d7
	movem.l	(a7)+,d0-d6/a0-a6
	rts


***********************************
** Level 2 IRQ			***
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

.int	movem.l	d0-d1/a0-a1,-(a7)
	lea	$dff000,a0
	lea	$bfe001,a1


	btst	#3,$1e+1(a0)			; PORTS irq?
	beq.b	.end
	btst	#3,$d00(a1)			; KBD irq?
	beq.b	.end

	move.w	#$f00,$dff180
	move.b	$c00(a1),d0
	not.b	d0
	ror.b	d0
	or.b	#1<<6,$e00(a1)			; set output mode


	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	.exit
	

	moveq	#3-1,d1
.loop	move.b	$6(a0),d0
.wait	cmp.b	$6(a0),d0
	beq.b	.wait
	dbf	d1,.loop


	and.b	#~(1<<6),$e00(a1)	; set input mode
.end	move.w	#1<<3,$9c(a0)
	move.w	#1<<3,$9c(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a1
	rte

.quit	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.exit	pea	(TDREASON_OK).w
	bra.b	.quit




	END

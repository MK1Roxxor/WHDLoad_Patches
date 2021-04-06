***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(         BEASTLORD WHDLOAD SLAVE            )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            December 2011                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 05-Apr-2021	- typo in name in splash screen fixed
;		  (Beastloard -> Beastlord), issue #0004151)
;		- WHDLF_ClearMemory flag used now, code to clear memory
;		  removed
;		- unused code removed
;		- debug key handling in keyboard routine removed
;		- bug in keyboard patch fixed (wrong delay loop)
;		- memory requirements changed from 1 MB chip to 512k chip
;		  and 512k other memory
;		- WHDLoad V17+ features used (config)

; 13-Dec-2011	- trainers can now be selected with CUSTOM3 tooltype
;		- added in-game key to show endsequence (x)


; 12-Dec-2011	- trainers added (unlimited health/strength/vitality);
;		  in-game keys (h/s/v -> max. health/strength/vitality)

; 05-Dec-2011	- decruncher relocated
;		- slave creates save disk if none is found
;		- support for load/save implemented 
;		- intro can be disabled with "CUSTOM1=1"
;		- keyboard patch fixed, stored unconverted
;		  rawkey instead of converted one as expected
;		  by the game

; 04-Dec-2011	- work started

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
DEBUGKEY	= $58		; F9
QUITKEY		= $59		; F10
DEBUG

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
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
	dc.l	524288		; ws_ExpMem
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
	dc.b	"C2:B:Disable Save Disk Creation;"
	dc.b	"C3:X:Unlimited Health:0;"
	dc.b	"C3:X:Unlimited Strength:1;"
	dc.b	"C3:X:Unlimited Vitality:2;"
	dc.b	"C3:X:In-Game Keys:3;"
	dc.b	0
	


	IFD	DEBUG
.dir	dc.b	"SOURCES:WHD_Slaves/Beastlord/",0
	ENDC
.name	dc.b	"Beastlord",0
.copy	dc.b	"1993 Grandslam",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	dc.b	"Version 1.02 (05.04.2021)",0
	CNOP	0,2

TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUTYPE		dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
NOINTRO		dc.l	0		; skip intro
		dc.l	WHDLTAG_CUSTOM2_GET
NOSAVEDISK	dc.l	0		; don't create save disk
		dc.l	WHDLTAG_CUSTOM3_GET
TRAINER		dc.l	0		: trainer
		dc.l	TAG_END

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


; install keyboard irq
	bsr	SetLev2IRQ

; load boot
	moveq	#0,d0
	move.l	#$2f678,d1
	move.l	d1,d6
	lea	$100.w,a5
	move.l	a5,a0
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)

; version check
	move.l	a5,a0
	move.l	d6,d0
	jsr	resload_CRC16(a2)
	lea	PLGAME(pc),a0
	cmp.w	#$e31,d0			; SPS 2452
	beq.b	.ok

; unknown version
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT


.ok
	

; patch boot
	move.l	a5,a1
	jsr	resload_Patch(a2)

	move.l	NOSAVEDISK(pc),d0
	bne.b	.nosavedisk
	bsr	CreateSaveDisk		; create save disk if it doesn't exist
.nosavedisk


; start game
	;lea	$80000,a0
	move.l	HEADER+ws_ExpMem(pc),a0


	lea	Flag(pc),a1
	st	(a1)
	move.l	NOINTRO(pc),d0
	beq.b	.dointro
	move.l	#$1c9a8,d0
	move.w	#$4e71,(a5,d0.l)	; skip grandslam intro 
	move.l	#$1c9fc,d0
	move.w	#$4e71,(a5,d0.l)	; skip "real" intro

.dointro
	lea	TRAINER(pc),a1
	move.l	(a1),d0
	beq.b	.notrainer
	lsr.l	#1,d0
	bcc.b	.nohealth
	move.l	#$22fec,d1		; unlimited health
	bsr.b	.disable
.nohealth
	lsr.l	#1,d0
	bcc.b	.nostrength
	move.l	#$22ff8,d1		; unlimited strength
	bsr.b	.disable
.nostrength
	lsr.l	#1,d0
	bcc.b	.novitality
	move.l	#$23004,d1		; unlimited vitality
	bsr.b	.disable
.novitality
	lsr.l	#1,d0
	bcc.b	.nokeys
	st	Keys-TRAINER(a1)	; enable in-game keys
.nokeys	




.notrainer

	jmp	(a5)

	
.disable
	move.w	#$4e75,(a5,d1.l)
	rts

QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	jmp	resload_Abort(a2)


PLGAME	PL_START
	PL_SA	$1e7a0,$1e7b0		; skip level 2 init
	PL_SA	$1e7b4,$1e7fa		; skip level 2 init

	PL_R	$1f540			; disable step to track zero
	PL_R	$1f468			; step
	PL_P	$1f258,.loader
	PL_L	$1f5d2,$70004e75	; disable drive access
	

	PL_P	$1e9f0,DECRUNCH_ATM5
	PL_P	$1eb9a,CopyData

	PL_P	$1f070,.load		; load saved game
	PL_SA	$24450,$24476		; skip check if disk is write protected
	PL_PS	$24480,.clearoffset	; emulate "move to track zero"
	PL_SA	$24486,$2449c		; skip check for save disk
	PL_P	$1f0c4,.save		; save game
	PL_R	$24506			; don't display "insert save disk"
	PL_PSS	$24352,.clearoffset,2	; emulate "move to track zero"



	PL_END

.clearoffset
	lea	.offset(pc),a0
	clr.l	(a0)
	rts



; d0.l: length
; a0.l: destination
.load	movem.l	d1-a6,-(a7)
	move.l	d0,d1

	lea	.offset(pc),a1
	move.l	(a1),d0
	add.l	d1,(a1)
	moveq	#3,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d1-a6
	moveq	#0,d0
	rts

; d0.l: length
; a0.l: data
.save	movem.l	d1-a6,-(a7)
	lea	.offset(pc),a1
	move.l	(a1),d1
	add.l	d0,(a1)
	move.l	a0,a1
	lea	savename(pc),a0
	move.l	resload(pc),a2
	jsr	resload_SaveFileOffset(a2)
	movem.l	(a7)+,d1-a6
	moveq	#0,d0
	rts

.offset	dc.l	0

; a0.l: destination
; a1.l: offset
; d0.l: length

.loader	movem.l	d1-a6,-(a7)
	moveq	#0,d2
	move.l	$100+$97a6,d3		; "BM-1" "BM-2"
	move.b	d3,d2			; ID
	sub.b	#"0",d2
	cmp.b	#1,d2
	bne.b	.nodisk1
	sub.l	#$1858+$258+$1600,a1
.nodisk1
	move.l	d0,d1
	move.l	a1,d0
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d1-a6
	moveq	#0,d0
	rts


***********************************
*** Level 2 IRQ			***
***********************************

SetLev2IRQ
	pea	Lev2(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode

	move.w	#1<<3,$dff09c			; clear ports interrupt
	move.w	#1<<15|1<<14|1<<3,$dff09a	; and enable it
	rts

Lev2	movem.l	d0-d1/a0-a2,-(a7)
	lea	$dff000,a0
	lea	$bfe001,a1

	btst	#3,$1e+1(a0)			; PORTS irq?
	beq.w	.end
	btst	#3,$d00(a1)			; KBD irq?
	beq.w	.end

	move.b	$c00(a1),d0
	not.b	d0
	ror.b	d0
	move.b	Flag(pc),d1
	beq.b	.nostore
	move.b	d0,$100+$9b67


	move.b	Keys(pc),d1
	beq.b	.skip
	moveq	#-1,d1
	cmp.b	#$21,d0				; s - full strength
	bne.b	.nos
	move.l	d1,$100+$9800
.nos	cmp.b	#$25,d0				; h - full health
	bne.b	.noh
	move.l	d1,$100+$9804
.noh	cmp.b	#$34,d0				; v - full vitality
	bne.b	.nov
	move.l	d1,$100+$9808
.nov	cmp.b	#$32,d0				; x - see end
	bne.b	.noend
	st	$100+$99fa
.noend

.skip

.nostore
	or.b	#1<<6,$e00(a1)			; set output mode


	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	.exit
	

.nokeys
	moveq	#3-1,d1
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


Flag	dc.b	0
Keys	dc.b	0			; in-game keys?

	CNOP	0,4

DECRUNCH_ATM5
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	(a0)+,d0
	cmp.l	#'ATM5',d0
	bne.w	lbC01EB7E
	move.l	(a0)+,d0
	move.l	d0,(sp)
	lea	(a1,d0.l),a5
	move.l	(a0)+,d0
	move.l	a0,a6
	add.l	d0,a6
	link	a2,#-$1A
	move.b	-(a6),d7
	bne.w	lbC01EB1E
	move.b	-(a6),d7
	bra.w	lbC01EB1E

lbC01EA1E
	move.w	d3,d5
lbC01EA20
	add.b	d7,d7
lbC01EA22
	dblo	d5,lbC01EA20
	beq.b	lbC01EA44
	bhs.b	lbC01EA30
	sub.w	d3,d5
	neg.w	d5
	bra.b	lbC01EA54

lbC01EA30
	moveq	#3,d6
	bsr.b	lbC01EA98
	beq.b	lbC01EA38
	bra.b	lbC01EA52

lbC01EA38
	moveq	#7,d6
	bsr.b	lbC01EA98
	beq.b	lbC01EA4A
	add.w	#15,d5
	bra.b	lbC01EA52

lbC01EA44
	move.b	-(a6),d7
	addx.b	d7,d7
	bra.b	lbC01EA22

lbC01EA4A
	moveq	#13,d6
	bsr.b	lbC01EA98
	add.w	#$10E,d5
lbC01EA52
	add.w	d3,d5
lbC01EA54
	lea	(lbW01EB84,pc),a4
	move.w	d5,d2
	bne.b	lbC01EAAE
	add.b	d7,d7
	bne.b	lbC01EA64
	move.b	-(a6),d7
	addx.b	d7,d7
lbC01EA64
	blo.b	lbC01EA6A
	moveq	#1,d6
	bra.b	lbC01EAB0

lbC01EA6A
	moveq	#3,d6
	bsr.b	lbC01EA98
	tst.b	(-$1A,a2)
	beq.b	lbC01EA7C
	move.b	(-$10,a2,d5.w),-(a5)
	bra.w	lbC01EB16

lbC01EA7C
	move.b	(a5),d0
	sub.b	(lbB01EA88,pc,d5.w),d0
	move.b	d0,-(a5)
	bra.w	lbC01EB16

lbB01EA88
	DC.B	0
	DC.B	1
	DC.B	2
	DC.B	3
	DC.B	4
	DC.B	5
	DC.B	6
	DC.B	7
	DC.B	$F8
	DC.B	$F9
	DC.B	$FA
	DC.B	$FB
	DC.B	$FC
	DC.B	$FD
	DC.B	$FE
	DC.B	$FF

lbC01EA98
	clr.w	d5
lbC01EA9A
	add.b	d7,d7
	beq.b	lbC01EAA8
lbC01EA9E
	addx.w	d5,d5
	dbra	d6,lbC01EA9A
	tst.w	d5
	rts

lbC01EAA8
	move.b	-(a6),d7
	addx.b	d7,d7
	bra.b	lbC01EA9E

lbC01EAAE
	moveq	#2,d6
lbC01EAB0
	bsr.b	lbC01EA98
	move.w	d5,d4
	move.b	(14,a4,d4.w),d6
	ext.w	d6
	tst.b	(-$19,a2)
	bne.b	lbC01EAC4
	addq.w	#4,d6
	bra.b	lbC01EAF2

lbC01EAC4
	bsr.b	lbC01EA98
	move.w	d5,d1
	lsl.w	#4,d1
	moveq	#2,d6
	bsr.b	lbC01EA98
	cmp.b	#7,d5
	blt.b	lbC01EAEA
	moveq	#0,d6
	bsr.b	lbC01EA98
	beq.b	lbC01EAE4
	moveq	#2,d6
	bsr.b	lbC01EA98
	add.w	d5,d5
	or.w	d1,d5
	bra.b	lbC01EAF4

lbC01EAE4
	or.b	(-$18,a2),d1
	bra.b	lbC01EAEE

lbC01EAEA
	or.b	(-$17,a2,d5.w),d1
lbC01EAEE
	move.w	d1,d5
	bra.b	lbC01EAF4

lbC01EAF2
	bsr.b	lbC01EA98
lbC01EAF4
	add.w	d4,d4
	beq.b	lbC01EAFC
	add.w	(-2,a4,d4.w),d5
lbC01EAFC
	lea	(1,a5,d5.w),a4
	move.b	-(a4),-(a5)
lbC01EB02
	move.b	-(a4),-(a5)
	dbra	d2,lbC01EB02
	bra.b	lbC01EB16

lbC01EB0A
	add.b	d7,d7
	bne.b	lbC01EB12
	move.b	-(a6),d7
	addx.b	d7,d7
lbC01EB12
	blo.b	lbC01EB78
	move.b	-(a6),-(a5)
lbC01EB16
	cmp.l	a5,a3
	bne.b	lbC01EB0A
	cmp.l	a6,a0
	beq.b	lbC01EB7C
lbC01EB1E
	moveq	#0,d6
	bsr.w	lbC01EA98
	beq.b	lbC01EB46
	move.b	-(a6),d0
	lea	(-$18,a2),a1
	move.b	d0,(a1)+
	moveq	#1,d1
	moveq	#6,d2
lbC01EB32
	cmp.b	d0,d1
	bne.b	lbC01EB38
	addq.w	#2,d1
lbC01EB38
	move.b	d1,(a1)+
	addq.w	#2,d1
	dbra	d2,lbC01EB32
	st	(-$19,a2)
	bra.b	lbC01EB4A

lbC01EB46
	sf	(-$19,a2)
lbC01EB4A
	moveq	#0,d6
	bsr.w	lbC01EA98
	beq.b	lbC01EB64
	lea	(-$10,a2),a1
	moveq	#15,d0
lbC01EB58
	move.b	-(a6),(a1)+
	dbra	d0,lbC01EB58
	st	(-$1A,a2)
	bra.b	lbC01EB68

lbC01EB64
	sf	(-$1A,a2)
lbC01EB68
	clr.w	d3
	move.b	-(a6),d3
	move.b	-(a6),d0
	lsl.w	#8,d0
	move.b	-(a6),d0
	move.l	a5,a3
	sub.w	d0,a3
	bra.b	lbC01EB0A

lbC01EB78
	bra.w	lbC01EA1E

lbC01EB7C
	unlk	a2
lbC01EB7E
	movem.l	(sp)+,d0-d7/a0-a6
	rts

lbW01EB84
	DC.W	$20
	DC.W	$60
	DC.W	$160
	DC.W	$360
	DC.W	$760
	DC.W	$F60
	DC.W	$1F60
	DC.W	1
	DC.W	$304
	DC.W	$506
	DC.W	$708

CopyData
	move.l	#$80,d7
	sub.l	d7,d0
	bls.b	lbC01EBE8
lbC01EBA4
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	sub.l	d7,d0
	bhi.b	lbC01EBA4
lbC01EBE8
	add.l	d7,d0
lbC01EBEA
	move.w	(a1)+,(a0)+
	subq.l	#2,d0
	bhi.b	lbC01EBEA
	rts


; a2: resload
; a5: bootstart

CreateSaveDisk
	lea	savename(pc),a0
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	bne.b	.exit			; data disk exists
        clr.l   -(a7)			; TAG_DONE
        clr.l   -(a7)			; data to fill
	move.l  #WHDLTAG_IOERR_GET,-(a7)
	move.l  a7,a0
	jsr     resload_Control(a2)
	move.l	4(a7),d0
	lea	3*4(a7),a7
	beq.b	.exit

; create empty data disk
	move.l	#$30000,d4		; length
	moveq	#0,d7			; offset
	move.l	#901120,d5
.loop	move.l	d4,d0
	move.l	d7,d1
	lea	savename(pc),a0
	lea	$0.w,a1
	jsr	resload_SaveFileOffset(a2)
	
.ok	add.l	#$30000,d7
	cmp.l	#901120-$30000,d7
	ble.b	.ok2
	move.l	#901120,d4
	sub.l	d7,d4
.ok2	sub.l	#$30000,d5
	bpl.b	.loop
.exit	rts

savename	dc.b	"disk.3",0



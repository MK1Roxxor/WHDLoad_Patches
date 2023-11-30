***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       WINGS OF DEATH WHDLOAD SLAVE         )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                          Feb. 2014/Jan. 2016                            *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 15-Jan-2016	- keyboard routines in end and credits parts rewritten
;		- game crashed when end-sequence was supposed to be shown,
;		  caused by disk change problem, disk change slighty changed
;		- game completely tested, no problems!
;		- in-game weapon select (1-5) trainer option changed, selected
;		  weapon now has maximum power and the corresponding sample
;		  is played as well

; 14-Jan-2016	- in-game keys are now disabled when entering name in the
;		  high-score table
;		- credits and end part patched
;		- added "bad extras have no effect", "autofire" and
;		  "max. weapon power" trainer options
;		- "Please insert disk 1" text disabled
;		- in-game Hippel replayer fixed, annoying sound problems
;		  are gone now
;		- Lother Becks decruncher removed for now, might add a
;		  fully working LB decruncher which supports all modes later
;		- added option to skip Thalion intro


; 11-Jan-2016	- illegal writes to bitplane pointers fixed
;		- more interrupt acknowledge fixes
;		- keyboard routines patched (Thalion intro/loading screen)
;		- uninitialised copperlists in Thalion intro fixed
;		- Bplcon0 color bit fix and copperlist bug in title screen
;		  fixed
;		- high-score load/save

; 13-Feb-2014	- corrected some minor bugs, game starts now but level
;		  backgrounds are trashed
;		- some hours later: fixed problem with level backgrounds,
;		  there is one empty entry in the file table (file 7)
;		- SMC fixed
;		- Bplcon0 color bit fix
;		- lots of trainers and in-game keys added, currently
;		  available trainer options:
;		  - unlimited lives/energy/continues
;		  - start at level
;		  - in-game keys: a: auto fire, i: shield, l: add life,
;		    b: smart bomb, h: hunter, d: destroyer, n: skip level,
;		    e: refill energy, s: increase speed, 1-5: select weapon
;		- in-game keys need to be disabled when entering the name
;		  in the high score screen, not yet done


; 12-Feb-2014	- work started
;		- patched boot and main part, nothing tested yet

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
QUITKEY		= $59		; F10
DEBUG

MAXWPNPOWER	= 3		; bit-number for max. weapon power option
AUTOFIRE	= 4		; bit-number for auto fire option
INGAMEKEYS	= 6		; bit-number for in-game keys option

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
	dc.w	.dir-HEADER	; ws_CurrentDir
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_KeyDebug
	dc.b	QUITKEY		; ws_KeyExit
	dc.l	0
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"C1:B:Skip Thalion Intro;"
	dc.b	"C2:X:Unlimited Lives:0;"
	dc.b	"C2:X:Unlimited Energy:1;"
	dc.b	"C2:X:Unlimited Continues:2;"
	dc.b	"C2:X:Maximum Weapon Power:3;"
	dc.b	"C2:X:Auto Fire Always Enabled:4;"
	dc.b	"C2:X:Bad Extras have no Effect:5;"
	dc.b	"C2:X:In-Game Keys:6;"
	dc.b	"C3:L:Start at Stage:1,2,3,4,5,6,7;"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/WingsOfDeath/"
	ENDC
	dc.b	"data",0
.name	dc.b	"Wings of Death",0
.copy	dc.b	"1990 Eclipse",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	dc.b	"Version 1.02 (15.01.2016)",0
Name	dc.b	"WoD_06",0
	CNOP	0,2

TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUTYPE		dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
SKIPINTRO	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
TRAINEROPTS	dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET
STARTLEVEL	dc.l	0
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
	lea	$400.w,a0
	move.l	a0,a5
	moveq	#6,d0
	bsr	LoadFile

; version check
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	lea	PLBOOT(pc),a0
	cmp.w	#$02fc,d0		; SPS 3022
	beq.b	.ok

; unknown version
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT
	

.ok		

	move.l	SKIPINTRO(pc),d0
	beq.b	.dointro
	move.w	#1,$24(a5)
.dointro

; patch boot
	move.l	a5,a1
	jsr	resload_Patch(a2)

; start game
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

AckVBI	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rte

AckCop	move.w	#1<<4,$dff09c
	move.w	#1<<4,$dff09c
	rte

PLBOOT	PL_START
	PL_P	$26c,.loadfile
	PL_P	$248,AckVBI
	PL_ORW	$206+2,1<<3		; enable level 2 interrupt
	PL_P	$110,.patch5		; patch Thalion intro
	PL_P	$6c,.patch0		; patch title screen
	PL_P	$9c,.patch1
	;PL_P	$88e,LB_DECRUNCH	; relocate Lothar Becks decruncher

	;PL_SA	$21c,$23e		; skip illegal writes to $dff0e0-$dff0e8
	PL_PS	$21c,.checkscreen
	PL_ORW	$19c+2,1<<9		; set Bplcon0 color bit

	PL_P	$da,.patch2_or_3
	PL_END

.checkscreen
	lea	$400.w,a0
	cmp.w	#$601a,(a0)
	bne.b	.ok
	move.l	#$60000,(a0)
.ok	move.l	(a0),a0
	rts

.patch1

; install trainers
	lea	$101c.w,a5
	move.l	TRAINEROPTS(pc),d0

; unlimited lives
	lsr.l	#1,d0			; unlimited lives
	bcc.b	.nolivestrainer
	eor.b	#$19,$101c+$7254	; subq <-> tst
.nolivestrainer

; unlimited energy
	lsr.l	#1,d0			; unlimited energy
	bcc.b	.noenergytrainer
	eor.b	#$d9,$1b7e(a5)		; sub.w d1,xx <-> tst.w xx
	eor.b	#$d9,$1c0a(a5)		; sub.w d1,xx <-> tst.w xx
.noenergytrainer

; unlimited continues
	lsr.l	#1,d0
	bcc.b	.noconttrainer		; unlimited continues
	eor.b	#$19,$101c+$885c	; subq <-> tst
.noconttrainer

; maximum weapon power
	lsr.l	#1,d0
	bcc.b	.noweapontrainer
	move.w	#$6002,$5ec6(a5)	; don't reset wehn collecting bad extra
.noweapontrainer


; auto fire
	lsr.l	#1,d0
	bcc.b	.noautofire
	
	;eor.w	#1,$1ad0.w
	move.w	#$6002,$5ebe(a5)	; don't reset when collecting bad extra
.noautofire


; bad extras have no effect
	lsr.l	#1,d0
	bcc.b	.noextrastrainer
	move.w	#$4e75,$101c+$5eb2
.noextrastrainer 


	move.w	STARTLEVEL+2(pc),$101c+$6488.w
	move.l	#$4e714e71,$101c+$8844	; disable "clr stage"

	lea	PL1(pc),a0
	bra.b	.patch

.patch0	lea	PL0(pc),a0
	bra.b	.patch
	
.patch5	lea	PL5(pc),a0		; Thalion intro

; initialise copperlists
	moveq	#-2,d0		
	move.l	d0,$26000
	move.l	d0,$267d0


.patch	lea	$400+$c1c.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$400+$c1c.w


.patch2_or_3
	lea	PL2(pc),a0
	cmp.l	#$4180a,$101c+12.w
	beq.b	.is2
	lea	PL3(pc),a0
.is2	bra.b	.patch


; a6.l: ptr to file table
.loadfile
	lsr.w	#2,d0			; d0: original file number
	move.l	6(a6),a0		; a0: destination
	bra.w	LoadFile

; credits
PL2	PL_START
	PL_PSS	$ad6,.setkbd,2
	PL_R	$cc8			; end level 2 interrupt code
	PL_P	$df2,AckVBI
	PL_P	$e02,AckCop
	PL_P	$c3c,AckVBI
	PL_ORW	$ab4+2,1<<9		; set Bplcon0 color bit
	PL_SA	$11e,$126		; don't write "Please insert disk 1" text
	PL_END

.setkbd	bsr	SetLev2IRQ
	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts


.kbdcust
	move.b	RawKey(pc),d0
	jmp	$101c+$cb4.w



; end
PL3	PL_START
	PL_PSS	$91c,.setkbd,2
	PL_R	$b18
	PL_P	$c4a,AckVBI
	PL_P	$c5a,AckCop
	PL_P	$a8a,AckVBI
	PL_ORW	$8fe+2,1<<9		; set Bplcon0 color bit
	PL_END

.setkbd	bsr	SetLev2IRQ
	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts


.kbdcust
	move.b	RawKey(pc),d0
	jmp	$101c+$b02.w


; Thalion intro
PL5	PL_START
	PL_PSS	$2e,.setkbd,2
	PL_PS	$5c,RemKbd
	PL_END


.setkbd	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts


.kbdcust
	move.b	RawKey(pc),d0
	bpl.b	.ok
	moveq	#0,d0
.ok	move.b	d0,$101c+$660
	rts

RemKbd	lea	KbdCust(pc),a0
	clr.l	(a0)
	rts

; Eclipse/title screen
PL0	PL_START
	PL_ORW	$1f0+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$6,.setkbd,2
	PL_PSS	$32a,.setkbd,2

	PL_R	$37e			; end level 2 interrupt code
	PL_P	$312,AckVBI

	PL_PSS	$468,.checkcop,2
	PL_END

.checkcop
	tst.w	$47c06
	bne.b	.ok
	move.l	#-2,$47c06
.ok	move.l	(a5,d6.w),$dff080
	rts


.setkbd	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts


.kbdcust	
	move.b	RawKey(pc),d0
	jmp	$101c+$368.w



; hippel replayer
PLREPLAY
	PL_START
	PL_PS	$7e,.fixsound
	PL_PS	$74a,.fixsound2
	PL_END

.fixsound
	move.w	$8208,$96(a6)
	bra.w	FixDMAWait

.fixsound2
	move.w	d7,$96(a6)
	bra.w	FixDMAWait
	

; game
PL1	PL_START
	PL_P	$7e4a,.loadfile
	PL_P	$e826,AckVBI
	PL_P	$ea9e,AckVBI
	PL_P	$eaae,AckCop
	PL_P	$ea04,AckCop
	;PL_P	$eabe,LB_DECRUNCH	; relocate Lothar Becks decruncher
	PL_SA	$e9e8,$e9f2		; skip $dff02a write
	PL_SA	$bc,$c2			; skip waiting for key (disk change)
	;PL_W	$8dfe,1			; enable built-in cheat
	PL_P	$761c,.flush1		; flush cache after SMC
	PL_P	$764e,.flush2		; as above
	PL_PSS	$76f6,FixDMAWait,2
	PL_PSA	$7746,FixDMAWait,$7756

	PL_PSS	$e712,.setkbd,2		; don't install new level 2 interrupt
	PL_R	$e920			; end level 2 interrupt code

	PL_ORW	$e6f0+2,1<<9		; set Bplcon0 color bit

	PL_PS	$91bc,.loadhigh
	PL_P	$8306,.savehigh
	PL_PSS	$93f6,.disablekeys,2	; disable in-game keys when entering name

	PL_PSS	$76f6,FixDMAWait,2
	PL_PS	$756a,.patchreplay

	PL_PS	$99c,.maxweapon		; set max. weapon power
	PL_END

.maxweapon
	move.l	TRAINEROPTS(pc),d0
	btst	#MAXWPNPOWER,d0
	beq.b	.noweaponpowertrainer
	move.w	#4,$1ace.w
.noweaponpowertrainer

	btst	#AUTOFIRE,d0
	beq.b	.noautofiretrainer
	
	move.w	#$4e75,$5e98(a5)	; disable autofire toggle
	move.w	#1,$101c+$ab4.w
	rts
	
.noautofiretrainer
	clr.w	$101c+$ab4.w		; original code
	rts

.patchreplay
	jsr	$101c+$7e40		; load replayer
	lea	PLREPLAY(pc),a0		; and patch it
	lea	$19750,a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)


.disablekeys
	move.l	a0,-(a7)
	lea	NoKeysFlag(pc),a0
	st	(a0)
	move.l	(a7)+,a0

	jsr	$161a.w
	jmp	$164e.w


.loadhigh
	lea	.name(pc),a0
	lea	$31620,a1
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nohigh
	lea	.name(pc),a0
	lea	$31620,a1
	jsr	resload_LoadFile(a2)
	moveq	#0,d0
	rts

.nohigh	moveq	#-1,d0
.nosave	rts	

.savehigh

; re-enable in-game keys
	lea	NoKeysFlag(pc),a0
	sf	(a0)

; any trainer options enabled or in-game cheat activated?
; -> no high-score save!
	move.l	TRAINEROPTS(pc),d0
	add.l	STARTLEVEL(pc),d0
	add.w	$101c+$8dfe,d0
	bne.b	.nosave

	lea	.name(pc),a0
	lea	$31620,a1
	move.l	#512,d0			; real size: 180 bytes
	move.l	resload(pc),a2
	jmp	resload_SaveFile(a2)



.name	dc.b	"WOD_14",0
	CNOP	0,2

.setkbd	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	bra.w	SetLev2IRQ

.kbdcust
	moveq	#0,d0
	move.b	RawKey(pc),d0

	move.w	NoKeysFlag(pc),d1
	bne.w	.nokeys
	move.l	TRAINEROPTS(pc),d1
	btst	#INGAMEKEYS,d1
	beq.w	.nokeys

; in-game keys enabled
	cmp.b	#1,d0
	blt.b	.noweapon
	cmp.b	#5,d0
	bgt.b	.noweapon

	subq.b	#1,d0
	jsr	$101c+$5d62.w		; get weapon
	move.w	#4,$101c+$ab2.w		; max. weapon power
.noweapon


	cmp.b	#$28,d0			; L - add life
	bne.b	.noLife
	jsr	$101c+$5ea0		; life

;	jsr	$101c+$5dac.w		; split fire
;	jsr	$101c+$5dd0.w		; circle blast
;	jsr	$101c+$5df8.w		; power beam
;	jsr	$101c+$5e1e.w		; dragon fire
;	jsr	$101c+$5e44.w		; thunderball
;	jsr	$101c+$5e8c.w		; auto fire
;	jsr	$101c+$5eb2.w		; bad extra
;	jsr	$101c+$5ede.w		; shield
;	jsr	$101c+$5ef2.w		; smart bomb
;	jsr	$101c+$5f56.w		; speed
;	jsr	$101c+$5f88.w		; energy
;	jsr	$101c+$5f9c.w		; hunter
;	jsr	$101c+$5fac.w		; destroyer
;	jsr	$101c+$5fbc.w		; 500 points


.noLife

	cmp.b	#$12,d0			; E - refill energy
	bne.b	.noenergy
	jsr	$101c+$5f88
.noenergy

	cmp.b	#$20,d0			; A - enable auto fire
	bne.w	.noautofire
	jsr	$101c+$5e8c.w
.noautofire	

	cmp.b	#$21,d0			; S - add speed
	bne.b	.nospeed
	jsr	$101c+$5f56.w
.nospeed

	cmp.b	#$22,d0			; D - get destroyer
	bne.b	.nodestroyer
	jsr	$101c+$5fac.w
.nodestroyer

	cmp.b	#$25,d0			; H - get hunter
	bne.b	.nohunter
	jsr	$101c+$5f9c.w
.nohunter

	cmp.b	#$17,d0			; I - get shield/invincibility
	bne.b	.noshield
	jsr	$101c+$5ede.w
.noshield	

	cmp.b	#$35,d0			; B - smart bomb
	bne.b	.nobomb
	jsr	$101c+$5ef2.w
.nobomb

	cmp.b	#$36,d0			; N - skip level
	bne.b	.nolevelskip
	move.w	#-1,$101c+$47c.w
.nolevelskip

.nokeys	jmp	$101c+$e90c		; call keyboard interrupt code

.flush2	move.l	#$101c+$767a,$101c+$7676
	bra.b	.flush

.flush1	move.l	#$19754,$101c+$7676

.flush	move.l	a0,-(a7)
	move.l	resload(pc),a0
	jsr	resload_FlushCache(a0)
	move.l	(a7)+,a0
	rts

.loadfile
	lsr.w	#2,d0			; d0: original file number
	move.l	6(a6),a0		; a0: destination


; d0.w: file number
; a0.l: destination

LoadFile
	move.l	#"WDA1",d1		; files 14/15 are used to
	moveq	#0,d2
	cmp.w	#14,d0			; identify the current disk
	beq.b	.storeID
	move.l	#"WDA2",d1
	moveq	#7,d2
	cmp.w	#15,d0
	bne.b	.ok
.storeID
	move.l	d1,(a0)			; $31620

	lea	FileAdd(pc),a0
	move.w	d2,(a0)
	rts

.ok	move.w	FileAdd(pc),d1
	beq.b	.normal
	cmp.w	#7,d0
	blt.b	.nofix
	subq.w	#1,d0			; file 7 is missing
.nofix	add.w	d1,d0	


.normal	move.l	a0,a1
	lea	Name(pc),a0
	movem.l	d0-a6,-(a7)
	bsr.b	.ConvToAscii		; build file name
	movem.l	(a7)+,d0-a6
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)
	rts

; d0:w value

.ConvToAscii
	addq.w	#4,a0			; skip WOD_

	moveq	#2-1,d3
	lea	.TAB(pc),a1
.loop1	moveq	#-"0",d1
.loop2	sub.w	(a1),d0
	dbcs	d1,.loop2
	neg.b	d1
	move.b	d1,(a0)+
.nope	add.w	(a1)+,d0
	dbf	d3,.loop1
	rts

.TAB	dc.w	10
	dc.w	1


FileAdd	dc.w	0

WaitRaster
	move.l	d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.b	.wait
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
.quit	bra.w	EXIT

.exit	pea	(TDREASON_OK).w
	bra.b	.quit


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine

NoKeysFlag	dc.w	0		; $ff: in-game keys disabled




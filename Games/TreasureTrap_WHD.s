***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       TREASURE TRAP WHDLOAD SLAVE          )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              June 2012                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 28-Sep-2024	- alternative joystick controls (CUSTOM5) implemented,
;		  issue #5490
;		- copperlist problems fixed
;		- memory list handling simplified
;		- keyboard debug code (move.w #$f00,$dff180) removed

; 28-Jul-2016	- CD32 joypad support added, BLUE/FIRE 2: pick up/drop,
;		  GREEN: smart fish, YELLOW: map
;		- joypad support can be disabled with CUSTOM4

; 12-Apr-2013	- slave creates save disk (disk.2) if none is found
;		- garbage on screen fixed when intro was skipped, fake
;		  copperlist is now created before starting the game
;		  and DMA enabled (before DMA was enabled after intro
;		  had been loaded and relocated)
;		- since replay uses CIA interrupt old DMA wait fix was
;		  unsafe since it wasn't guaranteed that it's called
;		  in the vertical blank area, now using "safe" approach

; 11-Apr-2013	- uses WHDLoad v17+ features (config) now
;		- intro skip (CUSTOM1) added
;		- trainers added:
;		  unlimited lives, unlimited air, unlimited fish, start
;		  with 999 gold
;		- 68000 quit key support in intro part improved/fixed,
;		  once the music starts playing game installs a new
;		  level 2 interrupt which had to be patched too

; 04-Jun-2012	- work started
;		- RawDIC imager coded which saves all files
;		- converter for the code binaries coded, game has
;		  relocation info so standard AmigaDOS executables
;		  can be created for easy disassembling
;		- game works!


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
DEBUGKEY	= $58		; F9
QUITKEY		= $59		; F10
;DEBUG

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM


HEADER	SLAVE_HEADER		; ws_security + ws_ID
	dc.w	17		; ws_version
	dc.w	FLAGS		; flags
	dc.l	$80000		; ws_BaseMemSize
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
	dc.b	"C2:X:Unlimited Lives:0;"
	dc.b	"C2:X:Unlimited Air:1;"
	dc.b	"C2:X:Unlimited Fish:2;"
	dc.b	"C2:X:Start with 999 pieces of gold:3;"
	dc.b	"C3:B:Disable Save disk creation;"
	dc.b	"C4:B:Disable Joypad Support;"
	dc.b	"C5:B:Enable Alternative Joystick Controls"
	dc.b	0

	IFD	DEBUG
.dir	dc.b	"SOURCES:WHD_Slaves/TreasureTrap",0
	ENDC
.name	dc.b	"Treasure Trap",0
.copy	dc.b	"1989 Emerald Software Ltd.",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.02 (28.09.2024)",0
	CNOP	0,2

	include	ReadJoypad.s

TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
NOINTRO		dc.l	0	
		dc.l	WHDLTAG_CUSTOM2_GET

; bit 0: unlimited lives
; bit 1: unlimited air
; bit 2: unlimited fish
; bit 3: 999 gold pieces
TRAINEROPTS	dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET
NOSAVEDISK	dc.l	0

		dc.l	WHDLTAG_CUSTOM4_GET
NOPAD		dc.l	0

		dc.l	TAG_END


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


; install keyboard irq
	bsr	SetLev2IRQ

; load "bootcode"
	move.l	#$3204,d0
	move.l	#$ffc,d1
	move.l	d1,d5
	lea	$6fa.w,a0
	move.l	a0,a5
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)


; version check
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	lea	PLBOOTCODE(pc),a4
	cmp.w	#$0d11,d0		; SPS 1731
	beq.b	.ok


	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok	



; patch it
	move.l	a4,a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

	move.l	NOINTRO(pc),d0
	bne.b	.nointro
	lea	PLINTRO(pc),a1
	clr.w	(PLINTRO\.skipintro)-PLINTRO(a1)
.nointro	

	bsr	CreateSaveDisk

	; create default copperlist and enable DMA
	lea	$100.w,a0
	move.l	#-2,(a0)
	move.l	a0,$dff080
	move.w	#$83c0,$dff096

	; Avoid illegal copperlist entry when leaving the intro
	lea	$19684,a0
	move.l	#-2,(a0)
	


; and start
	lea	.Memory_Tab(pc),a0
	moveq	#0,d3
	jmp	(a5)


.Memory_Tab
	dc.w	0			; 512k chip block
	dc.w	-1			; end of table


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	jmp	resload_Abort(a2)



PLBOOTCODE
	PL_START
	PL_SA	$c7e,$c8e		; don't patch exception vectors
	PL_R	$58a			; disable serial port code
	PL_R	$104			; drive off
	PL_P	$206,.loadtrack
	PL_R	$1be			; step to track
	PL_PSS	$f18,.patch,2		; patch intro/game after relocating
	PL_END



.loadtrack
	movem.l	d1-a6,-(a7)
	mulu.w	#512*11,d0
	move.l	#512*11-2,d1
	move.l	$6fa+$a.w,a0		; destination
	moveq	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d1-a6
	moveq	#0,d0			; no errors
	rts

.patch	movem.l	d0-a6,-(a7)
	lea	.counter(pc),a1
	cmp.w	#1,(a1)
	bgt.b	.normal

	move.w	(a1),d0
	addq.w	#1,(a1)
	lea	PLPREINTRO(pc),a0
	tst.w	d0
	beq.b	.patchintro
	lea	PLPREGAME(pc),a0
	move.l	TRAINEROPTS(pc),d0
	lsr.l	#1,d0			; unlimited lives selected?
	bcs.b	.lives
	move.b	#$53,(PLTRAINER\.livestr+5)-PLPREGAME(a0)	; no!
.lives	lsr.l	#1,d0			; unlimited air selected?
	bcs.b	.air
	move.b	#$53,(PLTRAINER\.airtr+5)-PLPREGAME(a0)		; no!
.air	lsr.l	#1,d0			; unlimited fish selected?
	bcs.b	.fish
	move.b	#$53,(PLTRAINER\.fishtr+5)-PLPREGAME(a0)	; no!

.fish	

	
.patchintro
	move.l	12(a5),a1		; relocated executable	
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
.normal
	movem.l	(a7)+,d0-a6

	move.l	(a5),d0			; original code
	lsl.l	#2,d0
	move.l	4(a5),a0
	rts



.counter	dc.w	0



PLPREINTRO
	PL_START
	PL_PS	$124-8,.patch
	PL_END

.patch	movem.l	d0-a6,-(a7)
	lea	PLINTRO(pc),a0
	move.l	$7dec,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	move.l	$7dec,a0
	rts


PLINTRO
	PL_START
	PL_R	$5c			; disable drive access
	PL_PSS	$6208,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$6220,FixDMAWait,2	; fix DMA wait in replayer
	PL_P	$64f6,FixAudXVol	; fix byte write to volume register
	PL_SA	$150,$18e		; skip drive check

	PL_P	$7a32,.setkey
	PL_R	$7be0			; so we can call kbd irq code
	PL_P	$113c,.quitkey

	PL_L	$112e+2,$bfed01		; fix CIA icr register access
	PL_L	$115e+4,$bfef01		; fix CIA crb register access

.skipintro
	PL_R	0
	PL_END

.quitkey
	movem.l	d0-a6,-(a7)
	move.b	$bfec01,d0
	not.b	d0
	ror.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT

	lea	$dff000,a0
	lea	$bfe001,a1
	or.b	#1<<6,$e00(a1)		; set output mode

	moveq	#3-1,d1
.loop	move.b	$6(a0),d0
.wait	cmp.b	$6(a0),d0
	beq.b	.wait
	dbf	d1,.loop

	and.b	#~(1<<6),$e00(a1)	; set input mode


	movem.l	(a7)+,d0-a6
	move.w	#1<<3,$dff09c
	move.w	#1<<3,$dff09c
	rte


.setkey	lea	.Keys(pc),a0
	move.l	a0,KbdCust-.Keys(a0)
	bra.w	SetLev2IRQ

.Keys	jsr	$830a+$7bce
	rts



PLPREGAME
	PL_START
	PL_PS	$124-8,.patch
	PL_END

.patch	movem.l	d0-a6,-(a7)
	lea	PLGAME(pc),a0
	move.l	$7dec,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	move.l	$7dec,a0
	rts

PLTRAINER
	PL_START
.livestr
	PL_B	$3410,$4a		; unlimited lives
.airtr	PL_B	$3312,$4a		; unlimited air
.fishtr	PL_B	$2832,$4a		; unlimited fish

	PL_PS	$2094,.gold
	PL_END

.gold	moveq	#0,d0
	move.l	TRAINEROPTS(pc),d1
	btst	#3,d1
	beq.b	.nogold
	move.w	#999,d0
.nogold	move.w	d0,$830a+$1edb2
	rts


PLGAME	PL_START
	PL_SA	$1780,$1bc8		; skip protection check
	PL_SA	$ab00,$af48		; skip protection check
	PL_SA	$122ae,$126f6		; skip protection check
	PL_SA	$146ca,$14b12		; skip protection check
	PL_R	$1dab6			; disable protection check (not used)
	PL_B	$1add0,$60		; disable "boot" check
	PL_R	$5c			; step to track 0
	PL_PSS	$1d73c,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$1d754,FixDMAWait,2	: fix DMA wait in replayer
	PL_P	$1da2a,FixAudXVol	; fix byte write to volume register

	PL_P	$8120,.setkey
	PL_R	$82ce			; so we can call kbd irq code

	PL_R	$1c758			; drive on
	PL_R	$1c780			; drive off
	PL_P	$1c804,.loadtrack
	PL_P	$e8e,.movetotrack

	PL_SA	$1af16,$1af3c		; skip save disk request (hiscore load)

; save high scores
	PL_SA	$1b8cc,$1b8d6		; skip save disk request (hiscore save)
	PL_PS	$1ba1e,.savehi
	PL_SA	$1ba1e+6,$1ba38

; save game
	PL_SA	$17372,$1737e		; skip save disk request
	PL_PS	$174b4,.savedir		; save directory
	PL_SA	$174b4+6,$174d0
	PL_PS	$1766a,.savegame
	PL_SA	$1766a+6,$1768c

	PL_PS	$74ee,.readjoy
	PL_B	$71c8,$24
	PL_GA	$71a2,.tab
	PL_GA	$8157,.keybuf



	; Alternative joystick control
	; Player can move without using diagonal directions
	PL_IFC5
	PL_B	$3ca9,$4c		; up
	PL_B	$3cac,$4f		; left
	PL_B	$3cb0,$4e		; right
	PL_B	$3caa,$4d		; down
	PL_ENDIF

	PL_NEXT	PLTRAINER	

	PL_END

.keybuf	dc.l	0
.tab	dc.l	0

; $71a2: keyboard definition tab
; $1bcfa: keyboard redefinition

.readjoy
	move.l	NOPAD(pc),d0
	bne.b	.nojoy

	moveq	#1,d0
	bsr	ReadJoy
	lea	.joy(pc),a0
	move.l	d0,(a0)
	
	cmp.l	4(a0),d0
	beq.b	.nojoy

	move.l	d0,4(a0)


; fire 2: drop/pick up
	btst	#JPB_BTN_BLU,d0
	beq.b	.nofire2

	move.l	.tab(pc),a0
	moveq	#0,d0
	move.b	$71d7-$71a2(a0),d0	; get defined key for drop/pick up
	bsr.b	.storekey
	bra.b	.done
.nofire2


; green: smart fish
	btst	#JPB_BTN_GRN,d0
	beq.b	.nored

	move.l	.tab(pc),a0
	moveq	#0,d0
	move.b	$71cf-$71a2(a0),d0	; get defined key for smart fish
	bsr.b	.storekey
	bra.b	.done
.nored

; yellow: map
	btst	#JPB_BTN_YEL,d0
	beq.b	.noyellow
	moveq	#$37,d0
	bsr.b	.storekey
.noyellow
.nojoy



.done	move.w	$dff01e,d0		; original code
	rts

.storekey
	move.l	.keybuf(pc),a0
	moveq	#0,d1
	move.b	-1(a0),d1
	addq.b	#1,-1(a0)

	move.b	d0,(a0,d1.w)
	rts

.joy	dc.l	0
.last	dc.l	0
.delay	dc.w	3

.savedir
	move.l	#$1600,d0		; size
	move.l	#5*$1600,d1		; offset
	move.l	-$12(a5),a1		; data
	bra.b	.save

.savegame
	move.l	#$1600,d0		; size
	move.w	-14(a5),d1
	addq.w	#5,d1
	mulu.w	#512*11,d1		; offset
	move.l	-$12(a5),a1		; data
	bra.b	.save


.savehi	move.l	TRAINEROPTS(pc),d0
	bne.b	.nosave
	move.l	-$24(a5),a1		; data
	move.l	#$1600,d0		; size
	move.w	.track(pc),d1		; offset
	mulu.w	#512*11,d1
.save	lea	.name(pc),a0
	move.l	resload(pc),a2
	jsr	resload_SaveFileOffset(a2)
.nosave	moveq	#0,d0
	rts
	


.name	dc.b	"disk.2",0
	CNOP	0,4


.setkey	lea	.Keys(pc),a0
	move.l	a0,KbdCust-.Keys(a0)
	bra.w	SetLev2IRQ

.Keys	jsr	$830a+$82bc
	rts


.movetotrack
	move.l	a0,-(a7)
	lea	.track(pc),a0
	move.w	d0,(a0)
	move.l	(a7)+,a0
	rts

.track	dc.w	0

.loadtrack
	move.w	.track(pc),d0
	mulu.w	#512*11,d0
	move.l	#$1600,d1
	moveq	#2,d2
	move.l	8(a3),a0
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	moveq	#0,d0			; no errors
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

WaitRaster
	move.l	d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.b	.wait
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



	IFD	DEBUG
	cmp.b	HEADER+ws_keydebug(pc),d0	
	bne.b	.nodebug
	movem.l	(a7)+,d0-d1/a0-a2
	move.w	(a7),6(a7)			; sr
	move.l	2(a7),(a7)			; pc
	clr.w	4(a7)				; ext.l sr
	bra.b	.debug
	ENDC

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
.quit	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.exit	pea	(TDREASON_OK).w
	bra.b	.quit


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine


; a2: resload

CreateSaveDisk
	movem.l	d0-a6,-(a7)
	move.l	NOSAVEDISK(pc),d0
	bne.b	.exit

	lea	.name(pc),a0
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
	move.l	#$30000-$1000,d4	; length
	moveq	#0,d7			; offset
	move.l	#901120,d5
.loop	move.l	d4,d0
	move.l	d7,d1
	lea	.name(pc),a0
	lea	$1000.w,a1
	jsr	resload_SaveFileOffset(a2)
	
.ok	add.l	#$30000-$1000,d7
	cmp.l	#901120-$30000,d7
	ble.b	.ok2
	move.l	#901120,d4
	sub.l	d7,d4
.ok2	sub.l	#$30000-$1000,d5
	bpl.b	.loop

.exit	movem.l	(a7)+,d0-a6
	rts

.name	dc.b	"disk.2",0

***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(     ESCAPE FROM THE PLANET OF THE          )*)---.---.   *
*   `-./             ROBOT MONSTERS WHDLOAD SLAVE                  \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             January 2015                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 16-Dec-2022	- fire button 2 support finished

; 15-Dec-2022	- started to add support for fire button 2 to drop
;		  bombs (issue #5614)
;		- minor size optimising

; 01-Jan-2016	- another version support, thanks to Abaddon for sending
;		  it

; 31-Dec-2015	- 53 blitter waits added (skipped on 68000)
;		- high-score load/save added
;		- patch finished

; 30-Dec-2015	- Bplcon2 fix corrected (not really needed but 100%
;		  "emulation" of what coder intended to do)
;		- trainer options properly implemented now, they can
;		  be selected via CUSTOM1 now
;		- more in-game keys added

; 18-Jan-2015	- lots of trainers added and game completed

; 17-Jan-2015	- work started

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_EmulTrap
DEBUGKEY	= $58		; F9
QUITKEY		= $59		; F10
;DEBUG

RAWKEY_LALT	= $64		; left Alt
RAWKEY_RALT	= $65		; right Alt

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


.config	dc.b	"C1:X:Unlimited Lives:0;"
	dc.b	"C1:X:Unlimited Energy:1;"
	dc.b	"C1:X:Unlimited Bombs:2;"
	dc.b	"C1:X:Unlimited Credits:3;"
	dc.b	"C1:X:Start with full Weapon Power:4;"
	dc.b	"C1:X:In-Game Keys:5;"
	dc.b	"C2:B:Enable Fire Button 2 Support (Bombs)"
	dc.b	0

	IFD	DEBUG
.dir	dc.b	"SOURCES:WHD_Slaves/EscapeRobotMonsters",0
	ENDC
.name	dc.b	"Escape from the Planet of the Robot Monsters",0
.copy	dc.b	"1990 Tengen",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.6 (16.12.2022)",0

	CNOP	0,2


TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET

; bit 0: unlimited lives on/off
; bit 1: unlimited energy on/off
; bit 2: unlimited bombs on/off
; bit 3: unlimited credits on/off
; bit 4: full weapon power on/off
; bit 5: in-game keys on/off
TRAINEROPTIONS	dc.l	0

		dc.l	TAG_END


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


; install keyboard irq
	bsr	SetLev2IRQ

; load game
	move.l	#$3ff*512,d0
	move.l	#$5a550,d1
	lea	$d96.w,a0
	move.l	d1,d5
	move.l	a0,a5
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)

; version check
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	lea	PLGAME(pc),a0
	cmp.w	#$49c8,d0		; SPS 477
	beq.b	.ok
	cmp.w	#$4a4f,d0		; SPS 2871
	beq.b	.ok
	lea	PLGAME2(pc),a0
	cmp.w	#$74f9,d0		; version sent by Abaddon
	beq.b	.ok

; unknown version
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

; patch
	move.l	a5,a1
	add.w	#$1c,a1

; install trainers
	move.l	TRAINEROPTIONS(pc),d0

; unlimmited lives
	lsr.l	#1,d0
	bcc.b	.noLivesTrainer
	bsr	ToggleLives
.noLivesTrainer

; unlimited energy
	lsr.l	#1,d0
	bcc.b	.noEnergyTrainer
	bsr	ToggleEnergy
.noEnergyTrainer

; unlimited bombs
	lsr.l	#1,d0
	bcc.b	.noBombsTrainer
	bsr	ToggleBombs
.noBombsTrainer

; unlimited credits
	lsr.l	#1,d0
	bcc.b	.noCreditsTrainer
	bsr	ToggleCredits
.noCreditsTrainer

; full weapon power
	lsr.l	#1,d0
	bcc.b	.noWeaponTrainer
	move.w	#63,$d96+$1c+$4613c+2
.noWeaponTrainer


	jsr	resload_Patch(a2)


; trap 0 -> used to flush cache after relocation
	lea	FlushTrap(pc),a0
	move.l	a0,$80.w

; set used traps
	lea	LOADER(pc),a0
	move.l	a0,$80+(2*4).w		; trap 2, loader

	lea	FAKETRAP(pc),a0
	move.l	a0,$80+(6*4).w		; trap 6, store ptr to free memory
	move.l	a0,$80+(10*4).w		; trap 10, check available drives
	

; load high scores
	bsr	LoadHighscores

; set default VBI
	lea	VBI(pc),a0
	move.l	a0,$6c.w


; and start
	lea	$400.w,a7
	jmp	(a5)


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	jmp	resload_Abort(a2)


VBI	movem.l	d0-a6,-(a7)
	move.l	$204.w,d0
	beq.b	.nocust
	move.l	d0,a0
	jsr	(a0)

.nocust	move.w	#$70,$dff09c
	move.w	#$70,$dff09c

	movem.l	(a7)+,d0-a6
	rte

FlushTrap
	move.l	resload(pc),a2
	jsr	resload_FlushCache(a2)

FAKETRAP
	rte

ToggleLives
	eor.b	#$19,$d96+$1c+$42024
	rts

ToggleEnergy
	eor.b	#$db,$d96+$1c+$424f0
	rts

ToggleBombs
	eor.b	#$19,$d96+$1c+$393c4
	rts

ToggleCredits
	eor.b	#$19,$d96+$1c+$4239e
	rts

PLBLIT	PL_START
	PL_PS	$35f02,.wblit1
	PL_PS	$35f18,.wblit2
	PL_PS	$35f44,.wblit5
	PL_PS	$35f6e,.wblit3
	PL_PS	$35fb6,.wblit4
	PL_PS	$35fd4,.wblit4
	PL_PS	$35ff2,.wblit4
	
	PL_PS	$3a0b2,.wblit1
	PL_PS	$3a0e4,.wblit6
	PL_PS	$3a10e,.wblit6
	PL_PS	$3a138,.wblit6

	PL_PS	$35b06,.wblit1
	PL_PS	$35b48,.wblit7
	PL_PS	$35b74,.wblit8
	PL_PS	$35bb8,.wblit9
	PL_PS	$35bd6,.wblit9
	PL_PS	$35bf4,.wblit9
	
	PL_PS	$35da0,.wblit1
	PL_PS	$35de2,.wblit7
	PL_PS	$35e0e,.wblit8
	PL_PS	$35e60,.wblit9
	PL_PS	$35e7e,.wblit9
	PL_PS	$35e9c,.wblit9

	PL_PS	$35c5c,.wblit1
	PL_PS	$35c9e,.wblit7
	PL_PS	$35cca,.wblit8
	PL_PS	$35d1c,.wblit9
	PL_PS	$35d3a,.wblit9
	PL_PS	$35d58,.wblit9
		
	PL_PS	$38904,.wblit1
	PL_PS	$38946,.wblit7
	PL_PS	$38970,.wblit10
	PL_PSS	$389b4,.wblit11,2
	PL_PSS	$389d0,.wblit11,2
	PL_PSS	$389e8,.wblit11,2

	PL_PS	$38a26,.wblit1
	PL_PS	$38a68,.wblit7
	PL_PS	$38a92,.wblit10
	PL_PSS	$38ae0,.wblit11,2
	PL_PSS	$38afc,.wblit11,2
	PL_PSS	$38b14,.wblit11,2

	PL_PS	$38b52,.wblit1
	PL_PS	$38b94,.wblit7
	PL_PS	$38bc0,.wblit8
	PL_PSS	$38c0e,.wblit11,2
	PL_PSS	$38c2a,.wblit11,2
	PL_PSS	$38c42,.wblit11,2

	PL_PS	$38c7e,.wblit1
	PL_PS	$38cc0,.wblit5
	PL_PS	$38cea,.wblit3
	PL_PSS	$38d2e,.wblit11,2
	PL_PSS	$38d50,.wblit11,2
	PL_PSS	$38d68,.wblit11,2
	PL_END

.wblit11
	bsr.b	.wblit
	move.l	#$d96+$1c+$36208,$50(a6)
	rts

.wblit10
	bsr.b	.wblit
	addq.w	#1,d7
	move.w	#0,$46(a6)
	rts

.wblit9	bsr.b	.wblit
	lea	40*200(a0),a0
	addq.w	#2,a1
	rts

.wblit8	bsr.b	.wblit
	subq.w	#6,a1
	move.w	#0,$46(a6)
	rts

.wblit7	bsr.b	.wblit
	addq.w	#2,a1
	move.l	a1,$50(a6)
	rts

.wblit6	bsr.b	.wblit
	lea	40*200(a1),a1
	addq.w	#4,a2
	rts

.wblit5	bsr.b	.wblit
	addq.w	#4,a1
	move.l	a1,$50(a6)
	rts

.wblit4	bsr.b	.wblit
	lea	40*200(a0),a0
	addq.w	#4,a1
	rts

.wblit3	bsr.b	.wblit
	addq.w	#1,d7
	sub.w	#12,a1
	rts

.wblit2	bsr.b	.wblit
	addq.w	#4,a1
	move.l	a1,$4c(a6)
	rts

.wblit1	lea	$dff000,a6

.wblit	tst.b	$dff002
.wb	btst	#6,$dff002
	bne.b	.wb
	rts

PLGAME2	PL_START
	PL_L	$64,$4e404e71		; trap 0 (flush cache), nop
	PL_PSA	$49196,.copylock,$49ae0
	PL_P	$a0c,SetLev2		; don't install new level 2 interrupt
	PL_W	$f66+2,$7f		; fix illegal bplcon2 value in copperlist
	PL_R	$527e4			; rte -> rts
	PL_R	$527f0			; rte -> rts
	PL_R	$52a2a			; rte -> rts
	PL_R	$52ad6			; rte -> rts
	PL_P	$48658,BK_DECRUNCH	; relocate ByteKiller decruncher
	PL_SA	$92,$aa			; don't kill interrupt vectors


	PL_PS	$70,fixblit		; install blitter waits

	PL_PS	$4277e,SaveHighscores
	PL_IFC2
	PL_PS	$392de,Drop_Bomb_With_Fire2
	PL_ENDIF
	PL_END

.copylock
	move.l	#$37018855,d0
	move.l	d0,$24.w
	rts


Drop_Bomb_With_Fire2
	btst	#14-8,$dff016
	bne.b	.no_fire2
	moveq	#RAWKEY_LALT,d0
	bra.b	.set_key
.no_fire2
	btst	#2,$dff016
	bne.b	.exit
	moveq	#RAWKEY_RALT,d0

.set_key
	move.l	$d96+$1c+$d6e,a0
	jsr	$d96+$1c+$c56.w		; store key

.exit	move.l	a1,a3			; original code
	move.l	$128(a3),a2
	rts




PLGAME	PL_START
	PL_L	$64,$4e404e71		; trap 0 (flush cache), nop
	PL_PSA	$4925e,.copylock,$497ae
	PL_P	$a0c,SetLev2		; don't install new level 2 interrupt
	PL_W	$f66+2,$7f		; fix illegal bplcon2 value in copperlist
	PL_R	$5246e			; rte -> rts
	PL_R	$5247a			; rte -> rts
	PL_R	$526b4			; rte -> rts
	PL_R	$52760			; rte -> rts
	PL_P	$4865c,BK_DECRUNCH	; relocate ByteKiller decruncher
	PL_SA	$92,$aa			; don't kill interrupt vectors


	PL_PS	$70,fixblit		; install blitter waits

	PL_PS	$4277e,SaveHighscores
	PL_IFC2
	PL_PS	$392de,Drop_Bomb_With_Fire2
	PL_ENDIF
	PL_END

.copylock
	move.l	#$a8d398fb,d0
	move.l	d0,$24.w
	rts


; since .wblit11 modifies an instruction which is relocated,
; we install the blitter wait patches after relocation is
; done

fixblit
	move.l	CPUFLAGS(pc),d0
	lsr.l	#1,d0			; 68000
	bcc.b	.noblit			; -> no blitter wait patches
	
	lea	PLBLIT(pc),a0
	lea	$d96+$1c.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

.noblit	lea	$dff000,a0
	rts




SetLev2
	lea	.KbdCust(pc),a0
	move.l	a0,KbdCust-.KbdCust(a0)
	bra.w	SetLev2IRQ

.KbdCust
	move.l	TRAINEROPTIONS(pc),d0
	btst	#5,d0
	beq.b	.nokeys
	
	move.b	RawKey(pc),d0
	cmp.b	#$36,d0			; N - skip level
	bne.b	.noN
	move.w	#5,$d96+$1c+$3d080
	st	$d96+$1c+$469d8		; bonus level
.noN

	cmp.b	#$28,d0			; L - toggle unlimited lives
	bne.b	.noL
	bsr	ToggleLives
.noL

	cmp.b	#$12,d0			; E - toggle unlimited energy
	bne.b	.noE
	bsr	ToggleEnergy
.noE
	cmp.b	#$35,d0			; B - toggle unlimited bombs
	bne.b	.noB
	bsr	ToggleBombs
.noB

	cmp.b	#$24,d0			; G - full gun power
	bne.b	.noG
	move.w	#63,$d96+$1c+$3661c
.noG


.nokeys	move.b	Key(pc),d0
	jmp	($d96+$1c)+$c4a.w


LoadHighscores
	movem.l	d0-a6,-(a7)
	lea	HighName(pc),a0
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nohigh
	lea	HighName(pc),a0
	lea	$d96+$1c+$427ac,a1
	jsr	resload_LoadFile(a2)
	
.nohigh

	movem.l	(a7)+,d0-a6
	rts
	

SaveHighscores
	lea	$d96+$1c+$42790,a1	; adapted original code
	move.b	(a1,d1.w),6(a0,d0.w)

	movem.l	d0-a6,-(a7)
	move.l	TRAINEROPTIONS(pc),d0
	bne.b	.nosave
	

	lea	HighName(pc),a0
	lea	$d96+$1c+$427ac,a1
	move.l	#$4284c-$427ac,d0
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)


.nosave	movem.l	(a7)+,d0-a6
	rts


HighName	dc.b	"EscapeRobotMonsters.high",0
		CNOP	0,2


; d0.l: destination
; d1.l: length (bytes)
; d2.w: offset (blocks)

LOADER	movem.l	d1-a6,-(a7)
	move.l	d0,a0
	move.w	d2,d0
	mulu.w	#512,d0
	moveq	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d1-a6
	moveq	#0,d0			; no errors
	rte

FixAudXVol
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts

FixDMAWait
	move.b	$dff006,d0
	addq.b	#5,d0
.wait	cmp.b	$dff006,d0
	bne.b	.wait
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

; read interrupt control register, register will be cleared
; after reading
	move.b	$bfed01-$bfe001(a1),d1
	btst	#1,d1				; timer B interrupt?
	beq.b	.notimer
	move.l	$204.w,d0			; timer B interrupt routine?
	beq.b	.notimer
	movem.l	d0-a6,-(a7)
	move.l	d0,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
	bra.b	.end
.notimer


	btst	#3,d1				; KBD irq?
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
.quit	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.exit	pea	(TDREASON_OK).w
	bra.b	.quit


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine


; Bytekiller decruncher
; resourced and adapted by stingray
;
; a0.l: source
; a1.l: destination

BK_DECRUNCH
	movem.l	d0-a6,-(a7)
	bsr.b	.decrunch
	tst.l	d5
	beq.b	.ok

; checksum doesn't match, file corrupt
	pea	ErrText(pc)
	pea	(TDREASON_FAILMSG).w
	bra.w	EXIT

.ok	movem.l	(a7)+,d0-a6
	rts


.decrunch
	move.l	-(a0),a2
	add.l	a1,a2
	move.l	-(a0),d5		; checksum
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
	move.w	#1<<4,ccr
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
	move.w	#1<<4,ccr
	roxr.l	#1,d0
.nonew	addx.l	d2,d2
	dbf	d1,.getbit
	rts


ErrText	dc.b	"Decrunching failed, file corrupt!",0







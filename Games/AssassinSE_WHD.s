***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(  ASSASSIN SPECIAL EDITION WHDLOAD SLAVE    )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              June 2019                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 17-Jun-2019	- game patched
;		- ProPack decruncher in intro relocated
;		- patch finished

; 16-Jun-2019	- work started, code adapted from my Assassin patch
;		- intro patched

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem
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


.config	dc.b	"BW;"
	dc.b	"C3:B:Skip Intro;"
	dc.b	"C1:X:Unlimited Lives:0;"
	dc.b	"C1:X:Unlimited Energy:1;"
	dc.b	"C1:X:Unlimited Time:2;"
	dc.b	"C1:X:Unlimited Continues:3;"
	dc.b	"C1:X:All Weapons:4;"
	dc.b	"C1:X:Unlimited Ammo:5;"
	dc.b	"C1:X:In-Game Keys (Press HELP during game):6;"
	dc.b	"C2:L:Start at Level:1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/AssassinSE",0
	ENDC

.name	dc.b	"Assassin Special Edition",0
.copy	dc.b	"1993 Team 17",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 3.0 (17.06.2019)",0

HighName	dc.b	"AssassinSE.highs",0

	CNOP	0,4

TAGLIST		dc.l	WHDLTAG_CUSTOM1_GET
TRAINEROPTIONS	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
STARTLEVEL	dc.l	0
		dc.l	TAG_DONE

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

; install level 2 interrupt
	bsr	SetLev2IRQ
	

; load intro
	lea	$4000.w,a0
	move.l	#$21*512,d0
	move.l	#$1022a,d1
	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$655A,d0		; SPS 0766
	beq.b	.ok
	
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT

.ok


; decrunch
	move.l	a5,a0
	move.l	a5,a1
	jsr	resload_Decrunch(a2)

; patch
	lea	PLINTRO(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

; set ext. mem
	move.l	HEADER+ws_ExpMem(pc),$ffc.w

	jmp	(a5)


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	move.l	resload(pc),-(a7)
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



; d0.w: drive
; d1.w: sector
; d2.l: number of sectors to load
; d3.w: function
; a0.l: destination

Loader	movem.l	d1-a6,-(a7)
	move.w	d0,d3
	move.w	d1,d0
	move.w	d2,d1

	cmp.w	#2,d0
	ble.b	.std
	subq.w	#2,d0
.std
	move.w	d3,d2
	addq.w	#1,d2
	mulu.w	#512,d0
	mulu.w	#512,d1
	move.l	resload(pc),a1
	jsr	resload_DiskLoad(a1)
	movem.l	(a7)+,d1-a6
	moveq	#0,d0			; no errors
	rts



PLINTRO	PL_START
	PL_PSS	$e1c,AckVBI,2

	PL_ORW	$fba+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$10b6+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$117e+2,1<<9		; set Bplcon0 color bit

	PL_SA	$b54,$b5c		; don't install level 2 interrupt

	PL_P	$154,.PatchGame		; patch game after relocating
	PL_P	$1484,Loader		; patch intro loader
	PL_P	$1bfa,Loader
	PL_IFC3
	PL_SA	$12,$c6			; skip intro
	PL_ENDIF

	PL_P	$200e,Decrunch		; relocate ProPack decruncher
	PL_END


.PatchGame
	lea	PLGAME(pc),a0
	move.l	$FFC.w,a1		; ext. mem

; set starting level
	move.l	STARTLEVEL(pc),d0
	cmp.w	#17,d0			; 0-16 only
	bcc.b	.skip
	move.w	d0,$1472+2(a1)
	move.w	d0,$148e+2(a1)

.skip

	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	lea	PLGAME_CHIP(pc),a0
	lea	$1000.w,a1
	jsr	resload_Patch(a2)


; load high scores
	move.l	#$19980,d0		; offset to high scores
	bsr	LoadHighscores

	bsr	SetLev2IRQ

	move.l	$FFC.w,a0		; ext. mem
	jmp	(a0)


; start of chip section: $1000.w
; offset to chip section in executable: $7c884


PLGAME_CHIP
.B	= $7c884

	PL_START
	PL_ORW	$7c9a0+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7ca98+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7cb88+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7cc80+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7ccc8+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7cd88+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7ce0c+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7d498+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7d4f8+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7d5d0+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7d658+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7d748+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7d7d0+2-.B,1<<9	; set Bplcon0 color bit
	PL_END
	

PLGAME	PL_START
	PL_P	$1c356,Loader
	PL_P	$1bbda,Loader

	PL_PS	$169c6,.FixBplcon0
	PL_PS	$169cc,.FixBplcon0_2
	PL_P	$16c30,.FixBplcon0_2

	PL_W	$16a22+2,$62
	PL_W	$16ac6+2,$62
	PL_W	$16ace+2,$62
	PL_W	$16a2a+2,$02


; unlimited lives
	PL_IFC1X	0
	PL_B	$5c6a,$4a
	PL_ENDIF

; unlimited energy
	PL_IFC1X	1
	PL_B	$a7f8,$4a
	PL_B	$d6ba,$4a
	PL_ENDIF

; unlimited time
	PL_IFC1X	2
	PL_B	$5f4a,$60
	PL_ENDIF

; unlimited continues
	PL_IFC1X	3
	PL_B	$1800c,$4a
	PL_ENDIF

; all weapons
	PL_IFC1X	4
	PL_PSA	$14de,.SetWeapons,$14ea
	PL_ENDIF

; unlimited ammo
	PL_IFC1X	5
	PL_B	$8840,$4a
	PL_ENDIF

; in-game keys
	PL_IFC1X	6
	PL_PS	$1662,.checkkeys
	PL_ENDIF


; disable "load high scores" menu entry
	PL_DATA	$179b8,.stop-.start

.start	dc.b	"E X I T",-1
.stop

	PL_B	$179f3,3
	PL_B	$179f4,-1

; disable "save high scores" menu entry
	PL_B	$1825b,-1
	PL_B	$18204,-1

	PL_P	$1c76a,Decrunch		; relocate ProPack decruncher
	PL_P	$196b0,SaveHighscores


	PL_PS	$247c,AckCOP
	PL_PS	$24d4,AckVBI
	PL_P	$2450,AckLev3
	PL_PS	$2510,AckLev6
	PL_PSS	$1cd14,AckLev4,2	

	PL_PSS	$2324,.setkbd,2
	PL_R	$2638

; button wait for level info screen
	PL_IFBW
	PL_PS	$149c,.wait
	PL_ENDIF

	PL_PS	$16778,.FixReplay
	PL_END


.FixReplay
	lea	PLREPLAY(pc),a0
	lea	$323a0,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	move.l	$ffc.w,a0
	clr.b	$26a0(a0)
	rts



.wait	btst	#7,$bfe001
	bne.b	.wait
	move.l	$ffc.w,a0
	add.l	#$1a6fa,a0
	rts


.setkbd	lea	.KbdCust(pc),a0
	move.l	a0,KbdCust-.KbdCust(a0)
	rts

.KbdCust
	moveq	#0,d0
	move.b	RawKey(pc),d0

	move.l	$ffc.w,a0
	jmp	$2624(a0)


.FixBplcon0
	move.b	#$02,$1000+($7cb8a-$7c884).w
	rts

.FixBplcon0_2
	move.b	#$02,$1000+($7ccca-$7c884).w
	rts


.SetWeapons
	move.l	$ffc.w,a0
	add.l	#$87c8,a0
	moveq	#5-1,d1
.set	move.b	#9,(a0)+
	dbf	d1,.set
	move.b	#1,(a0)				; super weapon available
	rts


.checkkeys
	move.l	$ffc.w,a0
	move.b	$268a(a0),d0			; d0.b: mapped key

	lea	.TAB(pc),a1
.loop	movem.w	(a1)+,d1/d2
	cmp.b	d0,d1
	beq.b	.found
	cmp.b	RawKey(pc),d1
	bne.b	.next

.found	movem.l	d0-a6,-(a7)
	jsr	.TAB(pc,d2.w)
	movem.l	(a7)+,d0-a6

.next	tst.w	(a1)
	bne.b	.loop


	add.l	#$993a,a0
	jmp	(a0)


.TAB	dc.w	"n",.SkipLevel-.TAB
	dc.w	"e",.RefreshEnergy-.TAB
	dc.w	"w",.GetWeapons-.TAB
	dc.w	"l",.AddLife-.TAB
	dc.w	"t",.RefreshTime-.TAB
	dc.w	$5f,.ShowKeys-.TAB		; help
	dc.w	0				; end of tab


.SkipLevel
	cmp.w	#16,$18da(a0)			; last level?
	bne.b	.noEnd
	st	$18e0(a0)			: -> game complete
.noEnd

	st	$18dc(a0)			; change level
	clr.w	$18f0(a0)			; count
	st	$18f8(a0)			; level complete
	rts



.RefreshEnergy
	move.w	#31,$6044(a0)
	rts

.GetWeapons
	move.l	#$1a5a6,d0
	jmp	(a0,d0.l)

.AddLife
	jmp	$5c76(a0)


.RefreshTime
	move.w	#$959,$6028(a0)
	jmp	$5e58(a0)



.SCREEN		= $100			; low mem from $100-$1000-16 is unused
.HEIGHT		= 64 			; 8 text lines
.YSTART		= 80

.ShowKeys
	lea	$dff000,a6

	move.w	$1c(a6),-(a7)		; save interrupts
	move.w	$02(a6),-(a7)		; save DMA
	bsr.w	KillSys

	lea	.TXT(pc),a0
	lea	.SCREEN.w,a1
	moveq	#0,d0			; x pos
	moveq	#0,d1			; x pos
.write	moveq	#0,d2
	move.b	(a0)+,d2
	beq.b	.end
	cmp.b	#10,d2
	beq.b	.newLine
	sub.b	#" ",d2
	lsl.w	#3,d2

	move.l	$ffc.w,a2
	add.l	#$1cf1c,a2		; in-game font
	add.w	d2,a2
	
	move.l	a1,a3
	add.w	d0,a3
	add.w	d1,a3
	moveq	#8-1,d7
.copy_char
	move.b	(a2)+,(a3)
	add.w	#40,a3
	dbf	d7,.copy_char

	addq.w	#1,d0
	cmp.w	#40,d0
	blt.b	.ok
.newLine
	moveq	#0,d0
	add.w	#40*9,d1
.ok
	bra.b	.write

.end

	
.WaitFire
	bsr	WaitRaster
	move.w	#($2c+.YSTART)<<8|81,$8e(a6)		; DDFSTRT
	move.w	#($2c+.YSTART+.HEIGHT)<<8|$c1,$90(a6)	; DDFSTOP
	move.w	#$38,$92(a6)				; DIWSTRT
	move.w	#$d0,$94(a6)				; DIWSTOP
	move.w	#$0,$108(a6)				; BPL1MOD
	move.w	#$1200,$100(a6)				; BPLCON0
	move.l	a1,$e0(a6)				; BPL1PTH
	move.w	#0,$102(a6)				; BPLCON1
	move.w	#0,$104(a6)				; BPLCON2

	move.w	#$000,$180(a6)
	move.w	#$fff,$182(a6)

	; enable bitplane DMA only
	move.w	#1<<15|1<<9|1<<8,$96(a6)

	btst	#7,$bfe001
	bne.b	.WaitFire

.exit	bsr	KillSys
	move.w	(a7)+,d0		; DMA
	or.w	#1<<15,d0
	move.w	d0,$96(a6)
	move.w	(a7)+,d0		; INTENA
	or.w	#1<<15,d0
	move.w	d0,$9a(a6)
	rts
	
.TXT	dc.b	"         IN-GAME KEYS",10
	dc.b	10
	dc.b	"N: SKIP LEVEL   E: REFRESH ENERGY",10
	dc.b	"L: ADD LIFE     T: REFRESH TIME",10
	dc.b	"W: GET WEAPONS  H: THIS SCREEN",10
	dc.b	10
	dc.b	"PRESS FIRE TO RETURN TO GAME",0
	CNOP	0,2







AckCOP	move.w	#1<<4,$dff09c
	move.w	#1<<4,$dff09c
	rts

AckVBI	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rts

AckLev3	move.w	d0,$dff09c
	movem.l	(a7)+,d0-a6
	rte

AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rts

AckLev4	move.w	#1<<8,$dff09c
	move.w	#1<<8,$dff09c
	rte


; d0.l: offset to high scores
; high-scores saved with <V1.2 are supported too

LoadHighscores
	add.l	$ffc.w,d0
	move.l	d0,a3


	lea	HighName(pc),a0
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.noHighscores
	move.l	d0,d1

	move.l	#180,d0			; size
	sub.l	d0,d1			; offset
	lea	HighName(pc),a0
	move.l	a3,a1
	jsr	resload_LoadFileOffset(a2)

.noHighscores
	rts


SaveHighscores
	move.l	TRAINEROPTIONS(pc),d0
	add.l	STARTLEVEL(pc),d0
	bne.b	.noSave

	lea	HighName(pc),a0
	move.l	$ffc.w,a1
	add.l	#$19980,a1
	move.l	#180,d0			; size	
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)

.noSave
	movem.l	(a7)+,a0/a1		; original code
	rts


Decrunch
	movem.l	d0-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_Decrunch(a2)
	movem.l	(a7)+,d0-a6
	rts

PLREPLAY
	PL_START
	PL_PSS	$326,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$33c,FixDMAWait,2	; fix DMA wait in replayer
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
	moveq	#0,d0
	move.b	$c00(a1),d0
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)+
	or.b	#1<<6,$e00(a1)			; set output mode

	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT

	move.l	(a2)+,d1
	beq.b	.nocustom
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.nocustom
	

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
KbdCust	dc.l	0			; ptr to custom routine


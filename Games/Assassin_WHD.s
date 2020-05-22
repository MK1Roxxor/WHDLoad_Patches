***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(         ASSASSIN WHDLOAD SLAVE             )*)---.---.   *
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

; 19-Jun-2019	- level 4 interrupt fix was wrong (rte vs. rts) and caused
;		  the game to crash when collecting a bonus

; 16-Jun-2019	- copperlists patched using patchlist now
;		- level 4 interrupt acknowledge fixed

; 15-Jun-2019	- due to a strange problem with the keyboard routine the
;		  in-game key to show the help screen has been changed
;		  from h to HELP, pressing "w" also triggers "h" due to
;		  a bug in the keyboard routine
;		- patch is finished for now

; 14-Jun-2019	- starting level can be set with CUSTOM3
;		- more in-game keys added
;		- help screen to show in-game keys added
;		- DMA wait in replayer fixed

; 13-Jun-2019	- size optimised the code a bit
;		- more trainer options
;		- high score saving disable if any trainer options are
;		  used
;		- "load high score" menu disabling simplified

; 10-Jun-2019	- load/save high scores menu entries disabled
;		- crash caused by keyboard interrupt fixed, 68000 quitkey
;		  works now
;		- more trainer options added
;		- level skipper fixed to work correctly in last level too
;		- ButtonWait support for level info screen
;		- ProPack decruncher relocated to fast memory

; 09-Jun-2019 	- level 6 interrupt fixed
;		- automatic highscore load/save
;		- intro skip

; 08-Jun-2019	- work started
;		- intro and game patched

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
	dc.b	"C2:L:Start at Level:1,2,3,4,5,6"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Assassin",0
	ENDC

.name	dc.b	"Assassin",0
.copy	dc.b	"1992 Team 17",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.2a (19.06.2019)",0

HighName	dc.b	"Assassin.highs",0

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
	move.l	#$1f*512,d0
	move.l	#$12a0f,d1
	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$E595,d0		; SPS 1214
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

; set Copylock key
	move.l	#$E0BB605F,$ff8.w

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
	PL_ORW	$18fa+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$19f6+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1abe+2,1<<9		; set Bplcon0 color bit

	PL_P	$a94,.PatchGame		; patch game after relocating
	PL_P	$1dc4,Loader		; patch intro loader
	PL_SA	$2e,$954		; skip Copylock code

	PL_IFC3
	PL_SA	$958,$a0c		; skip intro
	PL_ENDIF
	PL_END


.PatchGame
	lea	PLGAME(pc),a0
	move.l	$FFC.w,a1		; ext. mem

; set starting level
	move.l	STARTLEVEL(pc),d0
	cmp.w	#6,d0			; 0-5 only
	bcc.b	.skip
	move.w	d0,$1a8+2(a1)
.skip

	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	lea	PLGAME_CHIP(pc),a0
	lea	$1000.w,a1
	jsr	resload_Patch(a2)


; load high scores
	move.l	#$1bbc6,d0		; offset to high scores
	bsr	LoadHighscores

	bsr	SetLev2IRQ

	move.l	$FFC.w,a0		; ext. mem
	jmp	(a0)


; start of chip section: $1000.w
; offset to chip section in executable: $7c618


PLGAME_CHIP
.B	= $7c618

	PL_START
	PL_ORW	$7c734+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7c82c+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7c91c+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7ca14+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7ca5c+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7cb1c+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7cba0+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7d22c+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7d28c+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7d364+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7d3ec+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7d4dc+2-.B,1<<9	; set Bplcon0 color bit
	PL_ORW	$7d564+2-.B,1<<9	; set Bplcon0 color bit
	PL_END
	

PLGAME	PL_START
	PL_PS	$18cd2,.FixBplcon0
	PL_PS	$18cd8,.FixBplcon0
	PL_P	$18f3c,.FixBplcon0
	PL_W	$18d36+2,$02
	PL_W	$18d2e+2,$62		; $60->$62; set Bplcon0 color bit
	PL_W	$18dd2+2,$62		; $60->$62; set Bplcon0 color bit
	PL_W	$18dda+2,$62		; $60->$62; set Bplcon0 color bit

; unlimited lives
	PL_IFC1X	0
	PL_B	$5b1a,$4a
	PL_ENDIF

; unlimited energy
	PL_IFC1X	1
	PL_B	$a5d6,$4a
	PL_B	$d266,$4a
	PL_ENDIF


; unlimited time
	PL_IFC1X	2
	PL_B	$5dfa,$60
	PL_ENDIF

; unlimited continues
	PL_IFC1X	3
	PL_B	$1a264,$4a
	PL_ENDIF

; all weapons
	PL_IFC1X	4
	PL_PSA	$204,.SetWeapons,$210
	PL_ENDIF

; unlimited ammo
	PL_IFC1X	5
	PL_B	$8682,$4a
	PL_ENDIF
	

; in-game kes
	PL_IFC1X	6
	PL_PS	$3b8,.checkkeys
	PL_ENDIF

; disable "load high scores" menu entry
	PL_DATA	$19c86,.stop-.start

.start	dc.b	"E X I T",-1
.stop

	PL_B	$19cc1,3
	PL_B	$19cc2,-1

; disable "save high scores" menu entry
	PL_B	$1a4b3,-1
	PL_B	$1a45c,-1




	PL_P	$1d70e,Loader


	PL_PS	$115c,AckCOP
	PL_PS	$11b4,AckVBI
	PL_P	$1134,AckLev3
	PL_PS	$11f0,AckLev6
	PL_PSS	$1e448,AckLev4,2	


	PL_PSS	$1004,.setkbd,2
	PL_R	$1318

	PL_P	$1b902,SaveHighscores

; button wait for level info screen
	PL_IFBW
	PL_PS	$1c2,.wait
	PL_ENDIF

	PL_P	$1de8a,Decrunch		; relocate ProPack decruncher

	PL_PS	$18a8a,.FixReplay
	PL_END

.FixReplay
	lea	PLREPLAY(pc),a0
	lea	$323a0,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	move.l	$ffc.w,a0
	clr.w	$1380(a0)
	rts



.wait	btst	#7,$bfe001
	bne.b	.wait
	move.l	$ffc.w,a0
	add.l	#$1c8d6,a0
	rts


.setkbd	lea	.KbdCust(pc),a0
	move.l	a0,KbdCust-.KbdCust(a0)
	rts

.KbdCust
	moveq	#0,d0
	move.b	RawKey(pc),d0

	move.l	$ffc.w,a0
	jmp	$1304(a0)

.SetWeapons
	move.l	$ffc.w,a0
	add.l	#$860a,a0
	moveq	#5-1,d1
.set	move.b	#9,(a0)+
	dbf	d1,.set
	move.b	#1,(a0)				; super weapon available
	rts

.checkkeys
	move.l	$ffc.w,a0
	move.b	$136a(a0),d0			; d0.b: mapped key

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



	lea	$2f670,a0			; original code
	rts



.TAB	dc.w	"n",.SkipLevel-.TAB
	dc.w	"e",.RefreshEnergy-.TAB
	dc.w	"w",.GetWeapons-.TAB
	dc.w	"l",.AddLife-.TAB
	dc.w	"t",.RefreshTime-.TAB
	dc.w	$5f,.ShowKeys-.TAB		; help
	dc.w	0				; end of tab


.SkipLevel
	cmp.w	#5,$5ba(a0)			; last level?
	bne.b	.noEnd
	st	$5c0(a0)			: -> game complete
.noEnd

	st	$5bc(a0)			; change level
	clr.w	$5d0(a0)			; count
	;sf	$5c0(a0)			; game over flag
	st	$5d8(a0)			; 
	rts	

.RefreshEnergy
	move.w	#31,$5ef4(a0)
	rts

.GetWeapons
	move.l	#$1c7ca,d0
	jmp	(a0,d0.l)

.AddLife
	jmp	$5b26(a0)


.RefreshTime
	move.w	#$959,$5ed8(a0)
	jmp	$5d08(a0)



.SCREEN		= $100			; low mem from $100-$1000-8 is unused
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
	add.l	#$1e650,a2		; in-game font
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

.FixBplcon0
	move.b	#$02,$1000+($7c91e-$7c618).w
	rts


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
	rts


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
	add.l	#$1bbc6,a1
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


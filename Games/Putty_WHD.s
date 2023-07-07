***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(          PUTTY WHDLOAD SLAVE               )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             January 2014                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 07-Jul-2023	- 68000 quitkey did not work for Silly Putty (issue #6203)
;		- ws_keydebug handling removed from keyboard interrupt

; 07-Dec-2014	- fixed unlimited pliability trainer for A600 version

; 06-Dec-2014	- A600 version now fully supported

; 05-Dec-2014	- got images from Tomead, started to add support for
;		  the A600 version he sent me 

; 13-Jan-2014	- Silly Putty version fully tested, no problems (RawDIC
;		  imager had to be updated a bit)
;		- noticed Codetapper has a "25% finished" version added
;		  to his WIP list on the WHDLoad site so let's see when
;		  he'll finish it, mine is done...

; 12-Jan-2014	- some minor updates concerning high score handling (one
;		  routine for all supported versions) and some other
;		  things

; 11-Jan-2014	- unlimited energy (pliability) trainer added
;		- simplified code (easier handling for all supported
;		  game versions)
;		- in-game keys are now disabled if user has reached a
;		  high score and can enter his name
;		- patched end part (DMA waits in sample player, VBI
;		  acknowledge, blitter wait, decruncher relocated)

; 10-Jan-2014	- support for Silly Putty version added (SPS 1336) 
;		- added some more in-game keys (toggle unlimited lives,
;		  toggle unlimited time) and simplified trainer approach

; 09-Jan-2014	- fixed file loader, no trashed graphics anymore
;		- DMA waits in sample player and replayer fixed
;		- disk change not just skipped but emulated correctly,
;		  this is needed because the copylock won't be called
;		  otherwise making the game crash
;		- trainers added (unlimited lives/time, start at level,
;		  in-game keys)
;		- changed quitkey to Del because F10 is used when cheat
;		  mode is activated
;		- high score load/save added

; 08-Jan-2014	- RawDIC imager works correctly now (lots of work!), no
;		  more missing files but game still doesn't work, just
;		  displays trashed graphics

; 07-Jan-2014	- work started
;		- intro works but once the game is about to start a file
;		  is missing (my RawDIC imager is not working 100% correctly
;		  yet)


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $46		; DEL
DEBUG

BASEADDRESS		= $e8000		; base address Putty
BASEADDRESS_SP		= $e0000		; base address Silly Putty
HISCOREFLAG		= BASEADDRESS+$21de	; flag if high score entry
HISCOREFLAG_A600	= BASEADDRESS+$20e4
HISCOREFLAG_SP		= BASEADDRESS_SP+$2b58


; version info:
; GBH re-release, retail, SPS 197: all the same version, with end sequence
; (animation), copylock on disk 1, track 1 on disk 2 is empty so RawDIC
; imager works with A600 version too
; Putty A600: no end sequence (just a picture), copylock on disk 2, track 1
; on disk 1 is empty so RawDIC imager still works

; Silly Putty A600, SPS 1336: same versions

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


.config	dc.b	"C1:X:Unlimited Lives:0;"
	dc.b	"C1:X:Unlimited Time:1;"
	dc.b	"C1:X:Unlimited Energy (Pliability):2;"
	dc.b	"C1:X:Enable In-Game Keys:3;"
	dc.b	"C2:L:Start at Level:1,2,3,4,5,6,7,8,9,"
	dc.b	"10,11,12,13,14,15,16,17,18,19,20,21,22,23,24;"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Putty/data_A600",0
	ENDC
	dc.b	"data",0

.name	dc.b	"Putty",0
.copy	dc.b	"1992 System 3",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.2A (07.07.2023)",0
Name	dc.b	"SILLYPUTTY04",0
HiName	dc.b	"Putty.high",0
isPutty	dc.b	0			; 0: Silly Putty, $ff: Putty
isA600	dc.b	0			; 0: normal, $ff: A600 version
	CNOP	0,2


TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET

; bit 0: unlimited lives
; bit 1: unlimited time
; bit 2: unlimited energy (pliability)
; bit 3: in-game keys
TRAINEROPTS	dc.l	0		

		dc.l	WHDLTAG_CUSTOM2_GET
STARTLEVEL	dc.l	0
		dc.l	TAG_END

HighscorePtr	dc.l	0		; start address of high score data
HighscoreFlag	dc.l	0		; address of "has high score" flag

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


; install keyboard irq
	bsr	SetLev2IRQ

; check if file "SILLYPUTTY04" exists
	lea	Name(pc),a0
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	bne.b	.isPutty

; SillyPutty04 does not exist -> Silly Putty version
	lea	Name(pc),a0
	subq.b	#4,11(a0)		; SILLYPUTTY00
	lea	BASEADDRESS_SP,a1
	move.l	#BASEADDRESS_SP+$2b5e,HighscorePtr-Name(a0)
	move.l	#HISCOREFLAG_SP,HighscoreFlag-Name(a0)
	lea	PL00(pc),a4
	bra.b	.load

.isPutty
	lea	Name(pc),a0
	st	isPutty-Name(a0)
	lea	BASEADDRESS,a1
	move.l	#BASEADDRESS+$21e4,HighscorePtr-Name(a0)
	move.l	#HISCOREFLAG,HighscoreFlag-Name(a0)
	lea	PL04(pc),a4
.load	move.l	a1,a5
	jsr	resload_LoadFile(a2)
	move.l	d0,d5			; save size (needed later for decrunching)

	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$1ffa,d0		; SPS 197
	beq.b	.ok
	cmp.w	#$f7d0,d0		; SPS 1336
	beq.b	.ok

; A600 version?
	cmp.w	#$cb95,d0
	bne.b	.wrongver

; yes!
	lea	Name(pc),a0
	st	isA600-Name(a0)
	lea	BASEADDRESS,a1
	move.l	#BASEADDRESS+$20ea,HighscorePtr-Name(a0)
	move.l	#HISCOREFLAG_A600,HighscoreFlag-Name(a0)
	lea	PL04_A600(pc),a4
	bra.b	.ok


.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

; decrunch
	move.l	a5,a1
	move.l	d5,d0
	bsr	BK_DECRUNCH

; install trainers
	lea	TrainerOffsets(pc),a0
	tst.b	isA600-TrainerOffsets(a0)
	beq.b	.noA600_1
	add.w	#TrainerOffsets_A600-TrainerOffsets,a0
	bra.b	.go
.noA600_1

	tst.b	isPutty-TrainerOffsets(a0)
	bne.b	.go
	add.w	#TrainerOffsets_SP-TrainerOffsets,a0

.go	move.w	(a0)+,d2		; unlimited lives
	move.l	TRAINEROPTS(pc),d0
	lsr.l	#1,d0
	bcc.b	.nolivestrainer
	eor.w	#2,(a5,d2.w)		; moveq #2,d1 <-> moveq #0,d1
.nolivestrainer

	move.w	(a0)+,d2		; unlimited time
	lsr.l	#1,d0
	bcc.b	.notimetrainer
	eor.w	#1,(a5,d2.w)		; moveq #1,d1 <-> moveq #0,d1
.notimetrainer

	movem.w	(a0)+,d2/d3		; unlimited energy
	lsr.l	#1,d0
	bcc.b	.noenergytrainer
	eor.w	#$dc33,(a5,d2.w)	; $dc33 = sub.w d2,d1 eor nop
	eor.b	#7,(a5,d3.w)		; beq.b <-> bra.b
.noenergytrainer

	
.nokeys	move.w	(a0)+,d2
	move.l	STARTLEVEL(pc),d0
	ble.b	.nolevel
	cmp.w	#24,d0
	ble.b	.levelok
	moveq	#24,d0
.levelok
	move.w	d0,(a5,d2.w)

.nolevel


; patch
	move.l	a4,a0
	move.l	a5,a1
	jsr	resload_Patch(a2)


; load high scores
	lea	HiName(pc),a0
	move.l	a0,a3
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nohigh
	move.l	a3,a0
	move.l	HighscorePtr(pc),a1
	jsr	resload_LoadFile(a2)
.nohigh

	lea	Name(pc),a0
	move.b	#"1",11(a0)		; SILLYPUTTY01
	lea	$2400.w,a1
	lea	PL01(pc),a4
	tst.b	isA600-Name(a0)
	beq.w	.noA600
	lea	PL01_A600(pc),a4
.noA600	tst.b	isPutty-Name(a0)
	bne.b	.loadputty
	lea	$2a10.w,a1		; Silly Putty loads to different
	lea	PL01_SP(pc),a4		; address
.loadputty
	move.l	a1,a6
	jsr	resload_LoadFile(a2)
	move.l	a6,a1
	bsr	BK_DECRUNCH
	move.l	a4,a0
	move.l	a6,a1
	jsr	resload_Patch(a2)

	lea	Name(pc),a0
	addq.b	#1,11(a0)		; SILLYPUTTY02
	lea	$80000,a1
	move.l	a1,a6
	jsr	resload_LoadFile(a2)
	move.l	a6,a1
	bsr	BK_DECRUNCH


	lea	$6c.w,a0
	lea	AckVBI(pc),a1
	move.l	a1,(a0)

	lea	$78.w,a0
	lea	AckLev6(pc),a1
	move.l	a1,(a0)

	jmp	(a5)


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)


KillSys	move.w	#$7fff,$dff09a
	bsr	WaitRaster
	move.w	#$7fff,$dff096
	move.w	#$7fff,$dff09c
	rts

AckVBI	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rte
AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte

TrainerOffsets
	dc.w	$26fc			; unlimited lives
	dc.w	$283e			; unlimited time
	dc.w	$277e,$764e		; unlimited energy
	dc.w	$4a0+2			; start level
	dc.l	$78f8,$9c41		; level skip

; A600 version
TrainerOffsets_A600
	dc.w	$2f68			; unlimited lives
	dc.w	$30d0			; unlimited time
	dc.w	$2fe8,$7c5e		; unlimited energy
	dc.w	$488+2			; start level
	dc.l	$7ee0,$a223		; level skip


; silly putty version
TrainerOffsets_SP
	dc.w	$39c6			; unlimited lives
	dc.w	$3b2a			; unlimited time
	dc.w	$3a42,$7c00		; unlimited energy
	dc.w	$40e+2			; start level
	dc.l	$7e82,$b169		; level skip

; patch list for "SILLYPUTTY04" (main code)
PL04	PL_START
	PL_P	$7702,BK_DECRUNCH	; relocate ByteKiller decruncher
	PL_P	$8bc0,LoadFile

	PL_W	$48,$7000		; moveq #0,d0 -> set only 1 interrupt
	PL_W	$4a+2,$6c		; $64.w -> $6c.w

	PL_W	$432,$7000		; moveq #0,d0 -> set only 1 interrupt
	PL_W	$434+2,$6c		; $64.w -> $6c.w
	;PL_SA	$446,448		; don't patch exception vectors
	PL_W	$2496,$7000		; moveq #0,d0 -> set only 1 interrupt
	PL_W	$2498+2,$6c		; $64.w -> $6c.w
	;PL_SA	$24aa,$24ac		; don't patch exception vectors
	PL_W	$188,$7000		; moveq #0,d0 -> set only 1 interrupt
	PL_W	$18a+2,$6c		; $64.w -> $6c.w
	PL_W	$654,$7000		; moveq #0,d0 -> set only 1 interrupt
	PL_W	$656+2,$6c		; $64.w -> $6c.w
	PL_W	$8b6,$7000		; moveq #0,d0 -> set only 1 interrupt
	PL_W	$8b8+2,$6c		; $64.w -> $6c.w

	PL_PSA	$3b48,getkey,$3b5c
	PL_R	$3bae			; end kbd routine code

	PL_ORW	$78+2,1<<3		; enable level 2 interrupt
	PL_ORW	$1bc+2,1<<3		; enable level 2 interrupt
	PL_ORW	$480+2,1<<3		; enable level 2 interrupt
	PL_ORW	$682+2,1<<3		; enable level 2 interrupt
	PL_ORW	$908+2,1<<3		; enable level 2 interrupt
	PL_ORW	$24b0+2,1<<3		; enable level 2 interrupt

	PL_SA	$8fde,$9100		; skip and fake disk check
	PL_W	$49a+2,$00ff		; set $100.w to $ff	

	PL_ORW	$c9e+2,1<<3		; enable level 2 interrupt
	PL_PSS	$1b60,AckVBI_R,2
	PL_PSS	$8424,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$8440,FixDMAWait,2

	PL_SA	$784,$788		; don't store file length (a3 undefined)

	PL_PS	$1300,SaveHighscores
	PL_PS	$84a,.patchend
	PL_END

.patchend
	move.l	a0,a4
	bsr	LoadFile
	lea	PLEND(pc),a0
	move.l	a4,a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)



; patch list for "SILLYPUTTY04" (main code), A600 version
PL04_A600
	PL_START
	PL_P	$7CEA,BK_DECRUNCH	; relocate ByteKiller decruncher
	PL_P	$91b0,LoadFile

	PL_W	$48,$7000		; moveq #0,d0 -> set only 1 interrupt
	PL_W	$4a+2,$6c		; $64.w -> $6c.w

	PL_W	$41a,$7000		; moveq #0,d0 -> set only 1 interrupt
	PL_W	$41c+2,$6c		; $64.w -> $6c.w
	;PL_SA	$446,448		; don't patch exception vectors
	PL_W	$2d2c,$7000		; moveq #0,d0 -> set only 1 interrupt
	PL_W	$2d2e+2,$6c		; $64.w -> $6c.w
	;PL_SA	$24aa,$24ac		; don't patch exception vectors
	PL_W	$178,$7000		; moveq #0,d0 -> set only 1 interrupt
	PL_W	$17a+2,$6c		; $64.w -> $6c.w
	PL_W	$5f6,$7000		; moveq #0,d0 -> set only 1 interrupt
	PL_W	$5f8+2,$6c		; $64.w -> $6c.w
	PL_W	$7c6,$7000		; moveq #0,d0 -> set only 1 interrupt
	PL_W	$7c8+2,$6c		; $64.w -> $6c.w

	PL_PSA	$419e,getkey,$41b2
	PL_R	$4206			; end kbd routine code

	PL_ORW	$78+2,1<<3		; enable level 2 interrupt
	PL_ORW	$1ac+2,1<<3		; enable level 2 interrupt
	PL_ORW	$468+2,1<<3		; enable level 2 interrupt
	PL_ORW	$624+2,1<<3		; enable level 2 interrupt
	PL_ORW	$818+2,1<<3		; enable level 2 interrupt
	PL_ORW	$2d46+2,1<<3		; enable level 2 interrupt

	PL_SA	$95ce,$96f0		; skip and fake disk check
	PL_W	$482+2,$00ff		; set $100.w to $ff	

	PL_ORW	$bae+2,1<<3		; enable level 2 interrupt
	PL_PSS	$1a66,AckVBI_R,2
	PL_PSS	$8a14,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$8a30,FixDMAWait,2

	PL_SA	$726,$72a		; don't store file length (a3 undefined)

	PL_PS	$1206,SaveHighscores

	PL_P	$2382,copylock
	PL_END



PLEND	PL_START
	PL_PSS	$402,AckVBI_R,2
	PL_ORW	$40+2,1<<3		; enable level 2 interrupt
	PL_P	$2894c,BK_DECRUNCH
	PL_PS	$414,.waitblit
	PL_PSS	$9fc,fixdelay2f0,2
	PL_PSS	$a4a,fixdelay4d0,2
	PL_END

.waitblit
	lea	$dff000,a0
	tst.b	2(a0)
.wb	btst	#6,2(a0)
	bne.b	.wb
	rts

AckVBI_R
	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rts

getkey	move.b	Key(pc),d0
	
	movem.l	d0-d2/a0/a5,-(a7)
	lea	Key(pc),a0
	clr.b	(a0)
	
	move.l	TRAINEROPTS(pc),d1
	and.w	#1<<3,d1
	beq.b	.nokeys

	ror.b	d0
	not.b	d0


	move.l	HighscoreFlag(pc),a0
	tst.w	(a0)			; entering high score?
	bmi.b	.nokeys			; -> do not check in-game keys

	lea	BASEADDRESS,a5		; base address Putty
	lea	TrainerOffsets(pc),a0
	tst.b	isA600-TrainerOffsets(a0)
	beq.b	.noA600
	add.w	#TrainerOffsets_A600-TrainerOffsets,a0
	bra.b	.isputty


.noA600	tst.b	isPutty-TrainerOffsets(a0)
	bne.b	.isputty
	lea	BASEADDRESS_SP,a5	; base address Silly Putty
	add.w	#TrainerOffsets_SP-TrainerOffsets,a0
.isputty

	move.w	(a0)+,d1		; unlimited lives offset
	cmp.b	#$28,d0			; L - toggle unlimited lives
	bne.b	.nolivestoggle
	eor.w	#2,(a5,d1.w)		; moveq	#2,d1 <-> moveq #0,d1
	IFD	DEBUG
	move.w	#$f00,$dff180
	ENDC
.nolivestoggle

	move.w	(a0)+,d1		; unlimited time offset
	cmp.b	#$14,d0			; T - toggle unlimited time
	bne.b	.notimetoggle
	eor.w	#1,(a5,d1.w)		; moveq #1,d1 <-> moveq #0,d1
.notimetoggle

	movem.w	(a0)+,d1/d2		; unlimited energy offsets
	cmp.b	#$12,d0			; E - toggle unlimited energy
	bne.b	.noenergytoggle
	eor.w	#$dc33,(a5,d1.w)	; $dc33 = sub.w d2,d1 eor nop
	eor.b	#7,(a5,d2.w)		; beq.b <-> bra.b
.noenergytoggle

	cmp.b	#$36,d0			; N - skip level
	bne.b	.nolevelskip
	movem.l	2(a0),d1/d2		; 2 = skip start level offset
	move.b	(a5,d1.l),(a5,d2.l)
.nolevelskip


.nokeys	movem.l	(a7)+,d0-d2/a0/a5
	rts

; patch list for "Silly Putty" version
PL00	PL_START
	PL_P	$7c8c,BK_DECRUNCH	; relocate ByteKiller decruncher
	PL_P	$9176,LoadFile

	PL_W	$46,$7000		; moveq #0,d0 -> set only 1 interrupt
	PL_W	$48+2,$6c		; $64.w -> $6c.w
	PL_W	$120,$7000		; moveq #0,d0 -> set only 1 interrupt
	PL_W	$122+2,$6c		; $64.w -> $6c.w
	PL_W	$3a8,$7000		; moveq #0,d0 -> set only 1 interrupt
	PL_W	$3aa+2,$6c		; $64.w -> $6c.w
	PL_W	$524,$7000		; moveq #0,d0 -> set only 1 interrupt
	PL_W	$526+2,$6c		; $64.w -> $6c.w
	PL_W	$6ce,$7000		; moveq #0,d0 -> set only 1 interrupt
	PL_W	$6d0+2,$6c		; $64.w -> $6c.w
	PL_W	$37a0,$7000		; moveq #0,d0 -> set only 1 interrupt
	PL_W	$37a2+2,$6c		; $64.w -> $6c.w

	PL_PSA	$4386,getkey,$439a
	PL_R	$43ee			; end kbd routine code

	PL_ORW	$76+2,1<<3		; enable level 2 interrupt
	PL_ORW	$154+2,1<<3		; enable level 2 interrupt
	PL_ORW	$3ee+2,1<<3		; enable level 2 interrupt
	PL_ORW	$550+2,1<<3		; enable level 2 interrupt
	PL_ORW	$71a+2,1<<3		; enable level 2 interrupt
	PL_ORW	$37ba+2,1<<3		; enable level 2 interrupt

	PL_P	$2df6,copylock
	PL_SA	$958a,$96a8		; skip and fake disk check
	PL_W	$408+2,$00ff		; set $100.w to $ff	

	PL_ORW	$a6c+2,1<<3		; enable level 2 interrupt
	PL_PSS	$18d2,AckVBI_R,2
	PL_PSS	$89da,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$89f6,FixDMAWait,2

	PL_SA	$62e,$632		; don't store file length (a3 undefined)

	PL_PS	$10b6,SaveHighscores

	PL_PS	$3fa,.Enable_CIA_Interrupts
	PL_END


; Game disables CIA interrupts, quitkey does not work on 68000 due
; to this.
.Enable_CIA_Interrupts
	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	lea	$dff000,a0
	rts


SaveHighscores
	move.l	HighscoreFlag(pc),a0	; adapted original code, clear
	clr.w	(a0)			; "has hiscore" flag
	move.l	TRAINEROPTS(pc),d0	; high scores won't be saved if
	add.l	STARTLEVEL(pc),d0	; any trainers are used!
	bne.b	.nosave
	lea	HiName(pc),a0
	move.l	HighscorePtr(pc),a1
	move.l	#$2c12-$2b5e,d0		; Putty: $2298-$21e4
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)
.nosave	rts


; patch list for "SILLYPUTTY01"
PL01	PL_START
	PL_PSS	$144,fixdelay2f0,2	; move.w #$2f0,d7 dbf loop
	PL_PSS	$18e,fixdelayd0,2	; move.w #$d0,d6 dbf loop
	PL_P	$147e0,copylock
	PL_END

; patch list for "SILLYPUTTY01", A600 version
PL01_A600
	PL_START
	PL_PSS	$144,fixdelay2f0,2	; move.w #$2f0,d7 dbf loop
	PL_PSS	$18e,fixdelayd0,2	; move.w #$d0,d6 dbf loop
	PL_END

; Silly Putty version
PL01_SP	PL_START
	PL_PSS	$126,fixdelay2f0,2	; move.w #$2f0,d7 dbf loop
	PL_PSS	$170,fixdelayd0,2	; move.w #$d0,d6 dbf loop
	PL_END


copylock
	clr.l	$8.w
	st	$100.w			; not set: game kills itself!
	move.l	#$17660554,$60.w
	rts

fixdelay4d0
	move.l	d1,-(a7)
	moveq	#5-1,d1
	bsr.b	delay
	move.l	(a7)+,d1
	rts


fixdelay2f0
	move.l	d1,-(a7)
	moveq	#6-1,d1
	bsr.b	delay
	move.l	(a7)+,d1
	rts
	
fixdelayd0
	move.l	d1,-(a7)
	moveq	#3-1,d1
	bsr.b	delay
	move.l	(a7)+,d1
	rts


delay	move.l	d0,-(a7)
.loop	move.b	$dff006,d0	
.wait	cmp.b	$dff006,d0
	beq.b	.wait
	dbf	d1,.loop
	move.l	(a7)+,d0
	rts	

; a0.l: destination
; a1.l: file name
LoadFile
	movem.l	a0-a2,-(a7)
	exg	a0,a1
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)
	movem.l	(a7)+,a0-a2
	add.l	d0,a0
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
.quit	bsr	KillSys
	move.l	resload(pc),-(a7)
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
; a1.l: source+destination
; d0.l: size of crunched data

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
	move.l	a1,a0
	add.l	d0,a0			; a0: end of packed data
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



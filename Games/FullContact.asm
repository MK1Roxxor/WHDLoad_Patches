; V1.5, stingray
; 27.11.2018
; - interrupts fixed
; - Bplcon0 color bit fix
; - long write to Bplcon0 fixed
; - 68000 quitkey support (game only for now)
; - some of the old patch code converted to use patch lists
; - blitwait patch fixed (stack wasn't restored properly)

; 28.11.2018
; - complete game patched, runs without faults now, a few more blitter waits
;    added, more Bplcon0 color bit fixes, CPU dependent delay fixed
; - some of the old 1.4 patches were wrong and not needed at all, these
;   have been removed

; 29.11.2018
; - support for a second version added (disk images provided by UrBi)
; - year in copyright info changed to 1991 :)
; - Escape check fixed, game doesn't try to quit to DOS anymore, instead,
;   the game over screen is shown
; - old V1.4 blitter wait replaced with a better version
; - DMA wait in sample player fixed
; - option to skip the intro added (CUSTOM1)
; - some of the old patch code optimised
; - timing for name entry fixed
; - high score load/save added
; - timing in bonus level 1 and 2 fixed
; - 68000 quitkey support for intro

; 17.03.2019
; - bug with music replaying in intro fixed (wrong interrupt patch)

; 16.06.2019
; - code size optimised a bit
; - archive peprared for releasing on the WHDLoad site (finally!)

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i

DEBUG
FLAGS	= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoKbd|WHDLF_ClearMem

HEADER	SLAVE_HEADER		; ws_Security + ws_ID
	dc.w	17		; ws_Version
	dc.w	FLAGS		; ws_Flags
	dc.l	$80000		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	IFD	DEBUG
	dc.w	.dir-HEADER	; ws_CurrentDir
	ELSE
	dc.w	0		; ws_CurrentDir
	ENDC
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_keydebug
	dc.b	$59		; ws_keyexit
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


.config
	dc.b	"C1:B:Skip Intro"
	dc.b	0



.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/FullContact",0
	ENDC

.name	dc.b	"Full Contact",0
.copy	dc.b	"1991 Team 17",0
.info	dc.b	"installed & fixed by Mr.Larmer & StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"V1.6 (16-Jun-2019)",0

HiName	dc.b	"FullContact.high",0

	CNOP	0,2

Patch	lea	resload(pc),a1
	move.l	a0,(a1)

	move.l	a0,a2

; install keyboard interrupt
	bsr	SetLev2IRQ

	lea	$6FFF4,a0
	move.l	a0,a5
	moveq	#0,d0
	moveq	#$1600/512,d1
	bsr.w	DiskLoad

	move.l	#$1600,d0
	jsr	resload_CRC16(a2)
	lea	PLBOOT(pc),a0
	cmp.w	#$5999,d0		; SPS 2246
	beq.b	.ok	
	lea	PLBOOT_V2(pc),a0
	cmp.w	#$aa40,d0		; V2 (UrBi)
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
	

.ok	move.l	a5,a1
	jsr	resload_Patch(a2)

	jmp	$70032

.AckVBI	bsr.b	AckVBI
	rte

AckVBI	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rts


PLBOOT	PL_START
	PL_ORW	$ee+2,1<<9		; fix DMA settings
	PL_P	$126,Patch1
	PL_P	$10ae,DiskLoad
	PL_END
	


Patch1	lea	PL1(pc),a0
	pea	$400.w
	bra.b	PatchAndRun

PLBOOT_V2
	PL_START
	PL_ORW	$106+2,1<<9		; fix DMA settings
	PL_P	$13e,Patch1
	PL_P	$10dc,DiskLoad

	PL_S	$56,$6e-$56		; skip useless trap 0 code
	PL_END
	


PL1	PL_START

	PL_PS	$54,PatchIntro
	PL_P	$a2,PatchGame
	PL_P	$126,DECRUNCH

; v1.5, stingray
	PL_PSS	$e4,AckVBI,2
	PL_IFC1
	PL_B	$8,$60			; skip intro is CUSTOM1 is used
	PL_ENDIF

	PL_ORW	$1c+2,1<<3		; enable level 2 interrupts
	PL_END

PatchIntro
	lea	PLINTRO(pc),a0
	pea	$1c000
PatchAndRun
	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)




PLINTRO	PL_START
	PL_R	$563ac			; disable protection check
	PL_L	$2f3c,-2		; terminate copperlist

	;PL_P	$20e,.AckVBI
	PL_ORW	$e80+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$76c,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$784,FixDMAWait,2	; as above

	PL_PSS	$134e,FixTiming,4
	PL_END

;.AckVBI	bsr	AckVBI
;	rte


FixAudXVol
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,(8,a5)
	move.l	(a7)+,d0
	rts

PatchGame
	move.w	#$4E75,$6D72E		; disable "Insert Disk" request
	move.w	#$4E75,$6D752		; as above


	move.w	#$4EF9,$6F1EC
	pea	DECRUNCH(pc)
	move.l	(sp)+,$6F1EE


	lea	PLGAME(pc),a0
	lea	$4f390,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	lea	HiName(pc),a0
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.noHigh
	lea	HiName(pc),a0
	lea	$4f390+$17fa0,a1
	jsr	resload_LoadFile(a2)

.noHigh

	jmp	$6402A


PLGAME	PL_START
	PL_P	$1e280,.ChangeDisk


	PL_PSS	$22d62,.AckVBI,2	; fix interrupt and check quitkey
	PL_PSS	$20a18,.fix,4		; fix long write to $dff100

	PL_P	$16636,.patchFiles
	PL_ORW	$22e96+2,1<<9		; set Bplcon0 color bit
	
	;PL_B	$151d0,$60

	PL_W	$14ab6,0		; set "allow quit to dos" flag to 0
	PL_PSS	$1b07e,.wblit,2

	PL_PSS	$20ee8,.delay,4
	PL_PSS	$1e05c,.FixDMAWait,4	; fix DMA wait in sample player

	PL_PS	$17e74,.checkHighScore
	PL_PS	$17e7a,.saveHighScore

	PL_END

.checkHighScore
	movem.l	d0-a6,-(a7)
	lea	$4f390+$17fa0,a0
	move.l	#$17ff4-$17fa0,d0
	move.l	resload(pc),a2
	jsr	resload_CRC16(a2)
	lea	.CRC(pc),a0
	move.w	d0,(a0)
	movem.l	(a7)+,d0-a6
	jmp	$4f390+$17f20

.CRC	dc.w	0

.saveHighScore
	lea	$4f390+$17fa0,a0

	movem.l	d0-a6,-(a7)
	lea	$4f390+$17fa0,a0
	move.l	#$17ff4-$17fa0,d0
	move.l	resload(pc),a2
	jsr	resload_CRC16(a2)
	cmp.w	.CRC(pc),d0
	beq.b	.nosave

	lea	HiName(pc),a0
	lea	$4f390+$17fa0,a1
	move.l	#$17ff4-$17fa0,d0
	jsr	resload_SaveFile(a2)	

.nosave	movem.l	(a7)+,d0-a6
	rts	



.ChangeDisk
	lea	DiskNum(pc),a0
	move.w	d0,(a0)
	rts
	



.delay	move.w	#5000/$34,d7
.loopD	bsr	WaitLine
	dbf	d7,.loopD
	rts

.FixDMAWait
	move.w	#200/$34,d0
.DMADelay
	bsr	WaitLine
	dbf	d0,.DMADelay
	rts


.wblit	move.l	12(a1),a5
	move.l	8(a1),a6
	bra.w	WaitBlit
	


.patchFiles
	tst.l	d3
	beq.b	.notpacked
	jsr	$4f390+$1fe3e		; decrunch

.notpacked


; patch files after decrunching
; d0.w: start block
; a0.l: destination
	movem.l	d0-a6,-(a7)

	lea	.TAB(pc),a1
	move.w	DiskNum(pc),d4
.loop	movem.w	(a1)+,d1-d3
	cmp.w	d0,d1
	bne.b	.next
	cmp.w	d4,d2
	beq.b	.found

.next	tst.w	(a1)
	bpl.b	.loop
	bra.b	.exit


.found	move.l	a0,a1

	lea	.TAB(pc,d3.w),a0
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

.exit	movem.l	(a7)+,d0-a6


	tst.l	d2
	beq.b	.noexe
	jmp	(a0)


; start block, disk number, offset to patch list
.TAB	dc.w	$000,2,PLFIGHTER-.TAB	; fighter 1 intro
	dc.w	$0A4,2,PLFIGHTER-.TAB	; fighter 2 intro
	dc.w	$141,2,PLFIGHTER-.TAB	; fighter 3 intro
	dc.w	$1d0,2,PLFIGHTER-.TAB	; fighter 4 intro
	dc.w	$234,2,PLFIGHTER-.TAB	; fighter 5 intro
	dc.w	$2e5,2,PLFIGHTER-.TAB	; fighter 6 intro
	dc.w	$5f6,1,PLFIGHTER-.TAB	; fighter 7 intro
	;dc.w	$5c4,1,PLFIGHTER-.TAB	; fighter 8 intro
	
	dc.w	$429,2,PLDOJO-.TAB	; dojo
	dc.w	$4a9,2,PLBONUS1-.TAB	; bonus level 1
	dc.w	$514,2,PLBONUS2-.TAB	; bonus level 2
	dc.w	$373,2,PLMENU-.TAB	; main menu
	dc.w	-1			; end of tab


.fix	move.w	#$0200,$dff100
.noexe	rts


.AckVBI	move.b	$4f390+$22dd0,d0

	cmp.b	HEADER+ws_keyexit(pc),d0
	bne.w	AckVBI

QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts


WaitLine
	move.w	d0,-(a7)
	move.b	$dff006,d0
.wait	cmp.b	$dff006,d0
	beq.b	.wait
	move.w	(a7)+,d0
	rts

PLFIGHTER
	PL_START
	PL_PS	$10,.InitCop

	PL_PSS	$19c,.wblit,2
	PL_PSS	$1b6,.wblit,2
	PL_PSS	$1d0,.wblit,2
	PL_PSS	$1ea,.wblit,2
	PL_PSS	$204,.wblit,2
	PL_END

.wblit	bsr	WaitBlitA6

	move.l	a2,$50(a6)
	move.l	a3,$54(a6)
	rts


.InitCop
	move.w	#0,$dff180		; not really needed, original code
	jmp	$28880+$24e		; initialise copper buffers

PLDOJO	PL_START
	PL_ORW	$d10+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$ea0+2,1<<9		; set Bplcon0 color bit
	
	PL_END


PLBONUS1
	PL_START
	PL_PSS	$5e6,wblit1_Bonus,2
	PL_PS	$606,wblit2_Bonus

	PL_PSS	$b02,FixTiming,4
	PL_END

wblit1_Bonus
	bsr.b	WaitBlitA6
	move.l	a0,$50(a6)
	move.l	a1,$54(a6)
	rts

wblit2_Bonus
	lea	$dff000,a6


WaitBlitA6
	tst.b	$02(a6)
.wblit	btst	#6,$02(a6)
	bne.b	.wblit
	rts


PLBONUS2
	PL_START
	PL_PSS	$57e,wblit1_Bonus,2
	PL_PS	$59e,wblit2_Bonus

	PL_PSS	$152,.delay,4
	PL_PSS	$a90,FixTiming,4	; fix timing
	PL_END


.delay	move.w	#5000/$34,d0
.loop	bsr	WaitLine
	dbf	d0,.loop
	rts

FixTiming
.wait	cmp.b	#$ff,$dff006
	bne.b	.wait
.wait2	cmp.b	#$ff,$dff006
	beq.b	.wait2
	rts

PLMENU	PL_START
	PL_PSS	$d3c,.wblit,2
	PL_PSS	$d44,.delay,4		; fix CPU dependent delay in vertical scroller
	PL_PSS	$d1c,.wblit2,4


	PL_PS	$414,.DelayNameEntry	; fix timing for name entry

	PL_END


.DelayNameEntry
	moveq	#50,d2
.delay1	bsr.w	WaitLine
	dbf	d2,.delay1
	
	move.w	$dff00c,d2		; original code, read joy
	rts


.delay	moveq	#6-1,d3
.loop	bsr	WaitLine
	dbf	d3,.loop
	rts

.wblit	move.w	#$0400,$dff096
	bra.b	WaitBlit

.wblit2	bsr.b	WaitBlit
	move.l	#$41d56,$dff054
	rts


WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$DFF002
	bne.b	.wblit
	rts


DiskLoad
	movem.l	d0-a6,-(a7)
	mulu	#512,d0
	mulu	#512,d1
	move.w	DiskNum(pc),d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d0-a6
	moveq	#0,d0			; no errors
	rts

; looks like a modified TetraPak decruncher
DECRUNCH
	move.b	$10(a5),(a2)
	lea	$112(a0),a0
	add.l	(a5),a0
	move.l	8(a5),d0
	sub.l	4(a5),d0
	add.l	d0,a1
	lea	$12(a5),a4
	move.l	4(a5),a2
	add.l	a1,a2
	move.l	-(a0),d0
.loop
	moveq	#3,d1
	bsr.w	.GetBits
	tst.w	d2
	beq.w	.skip_all
	cmp.b	#%111,d2
	bne.b	.normal

	lsr.l	#1,d0
	bne.b	.nonew1
	bsr.w	.NextLong
.nonew1
	bcs.b	.has_bit
	moveq	#2,d1
	bsr.w	.GetBits
	addq.w	#7,d2
	bra.b	.normal

.has_bit
	moveq	#8,d1
	bsr.w	.GetBits
	tst.w	d2
	beq.b	.empty
	add.w	#10,d2
	bra.b	.normal

.empty
	moveq	#12,d1
	bsr.w	.GetBits
	tst.w	d2
	beq.b	.empty2
	add.w	#$109,d2
	bra.b	.normal

.empty2
	moveq	#15,d1
	bsr.w	.GetBits
	add.l	#$110B,d2

.normal	subq.w	#1,d2
	move.w	d2,d3
.loop1	lsr.l	#1,d0
	bne.b	.nonew2
	bsr.b	.NextLong
.nonew2	bcs.b	.has_bit2
	moveq	#8,d5
	moveq	#6,d1
	bra.b	.enter

.has_bit2
	lsr.l	#1,d0
	bne.b	.nonew3
	bsr.b	.NextLong
.nonew3	bcs.b	.has_bit3
	moveq	#0,d5
	moveq	#3,d1
	bra.b	.enter

.has_bit3
	lsr.l	#1,d0
	bne.b	.nonew4
	bsr.b	.NextLong
.nonew4	bcs.b	.has_bit4
	moveq	#$48,d5
	moveq	#6,d1
	bra.b	.enter

.has_bit4
	move.w	#$88,d5
	moveq	#7,d1
.enter	bsr.b	.GetBits
	add.w	d5,d2
	move.b	(a4,d2.w),-(a2)
	dbf	d3,.loop1

.skip_all
	cmp.l	a2,a1
	bge.b	.Pass2

	lsr.l	#1,d0
	bne.b	.nonew5
	bsr.b	.NextLong
.nonew5
	bcc.b	.nobit

	moveq	#2,d1
	bsr.b	.GetBits
	move.w	d4,d1
	moveq	#3,d3
	tst.b	d2
	beq.b	.enter2
	cmp.b	d2,d3
	beq.b	.l3
	cmp.b	#1,d2
	beq.b	.l1
	moveq	#6,d3
	moveq	#3,d1
	bra.b	.l2

.NextLong
	move.l	-(a0),d0
	move.w	#$10,ccr
	roxr.l	#1,d0
	rts

.l1
	moveq	#4,d3
	moveq	#1,d1
.l2
	bsr.b	.GetBits
	add.w	d2,d3
	move.w	d4,d1
	bra.b	.enter2

.GetBits
	subq.w	#1,d1
	moveq	#0,d2
.getbits_loop
	lsr.l	#1,d0
	bne.b	.stream_ok
	bsr.b	.NextLong
.stream_ok
	addx.l	d2,d2
	dbf	d1,.getbits_loop
	rts

.l3
	moveq	#8,d1
	bsr.b	.GetBits
	move.w	d2,d3
	add.w	#14,d3
	moveq	#11,d1
	bra.b	.enter2

.nobit
	lsr.l	#1,d0
	bne.b	.l4
	bsr.b	.NextLong
.l4
	bcs.b	.enter_d3
	moveq	#2,d3
	move.w	d6,d1
	bra.b	.enter2

.enter_d3
	moveq	#1,d3
	move.w	d7,d1
.enter2
	bsr.b	.GetBits
	lea	(a2,d2.w),a3
.copy
	move.b	-(a3),-(a2)
	dbf	d3,.copy
	cmp.l	a2,a1
	blt.w	.loop

.Pass2	move.b	12(a5),d7
	move.l	a6,a0
	move.l	a0,a2
	add.l	8(a5),a2
.loopRLE
	move.b	(a1)+,d0
	cmp.b	d7,d0
	bne.b	.skip
	moveq	#0,d1
	move.b	(a1)+,d1
	beq.b	.skip
	move.b	(a1)+,d0
	addq.w	#1,d1
.store	move.b	d0,(a0)+
	dbf	d1,.store
.skip
	move.b	d0,(a0)+
	cmp.l	a2,a1
	blt.b	.loopRLE
	movem.l	(a7)+,d0-a6
	rts

FixDMAWait
	moveq	#7,d0
.loop	move.w	d0,-(a7)
	move.b	$DFF006,d0
.wait	cmp.b	$DFF006,d0
	beq.b	.wait
	move.w	(a7)+,d0
	dbf	d0,.loop
	rts

DiskNum	dc.w	1
resload	dc.l	0

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
	beq.w	.end

	btst	#3,$d00(a1)			; KBD irq?
	beq.b	.end

	moveq	#0,d0
	move.b	$c00(a1),d0
	not.b	d0
	ror.b	d0
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





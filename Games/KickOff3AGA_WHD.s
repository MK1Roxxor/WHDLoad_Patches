***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        KICK OFF 3 AGA WHDLOAD SLAVE        )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                           March/April 2009                              *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 22-Mar-2020	- one more blitter wait added (half time screen)
;		- all keyboard patches disabled for now
;		- keyboard problems fixed, now using NoKbd flag
;		- I guess that's it, patch is finished after more than
;		  10 years
;		- WHDLoad 17+ used and required now (config)
;		- interrupts fixed and quitkey check added


; 21-Mar-2020	- work restarted after more than 10 years
;		- BPLCON0 color bit fixes
;		- 2 more checksum checks disabled
;		- blitter waits added

; 05-Apr-2009	- access fault in sample replayer fixed
;		- disk change simplified (taken from my
;		  European Challenge slave)
;		- RNC decruncher relocated to fast mem

; 30-Mar-2009	- work started
;		- adapted from my Kick Off 3 ECS slave

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoKbd
DEBUGKEY	= $58		; F9
QUITKEY		= $59		; F10
DEBUG



HEADER	SLAVE_HEADER		; ws_security + ws_ID
	dc.w	17		; ws_version
	dc.w	FLAGS		; flags
	dc.l	524288*4	; ws_BaseMemSize
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


.config	dc.b	"C1:B:Don't create Data Disk"
	dc.b	0
	

	IFD	DEBUG
.dir	dc.b	"SOURCES:WHD_Slaves/KickOff3/",0
	ENDC
.name	dc.b	"Kick Off 3 AGA",0
.copy	dc.b	"1994 Anco",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC

	dc.b	"Version 1.00 (22.03.2020)",0
	CNOP	0,2

TAGLIST		dc.l	WHDLTAG_CUSTOM1_GET
NODATADISK	dc.l	0		; disable creation of data disk

		dc.l	TAG_END

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

; clear memory (so we can create "clean" data disk if needed)
	lea	$1000.w,a0
	lea	$30000,a1
.clear	clr.l	(a0)+
	cmp.l	a0,a1
	bne.b	.clear


; install keyboard irq
;	bsr	SetLev2IRQ

; load boot
	moveq	#0,d0
	move.l	#1024,d1
	moveq	#1,d2
	lea	$75000,a5
	move.l	a5,a0
	jsr	resload_DiskLoad(a2)

; version check
	move.l	a5,a0
	move.l	#1024,d0
	jsr	resload_CRC16(a2)
	lea	PL_BOOTAGA(pc),a0
	cmp.w	#$8fae,d0		; AGA version, SPS 1854
	beq.b	.ok

; unknown version
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT

.ok


; patch it
	move.l	a5,a1
	jsr	resload_Patch(a2)
	
; load main file
	move.l	#$2e00,d0
	move.l	#$4c800,d1
	moveq	#1,d2
	lea	$97e68,a0
	jsr	resload_DiskLoad(a2)


	move.l	NODATADISK(pc),d0
	bne.b	.nodatadisk
	bsr	CreateDataDisk		; create data disk if it doesn't exist
.nodatadisk
	jmp	$74(a5)

QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	jmp	resload_Abort(a2)


*******************************************
*** AGA VERSION 	(SPS 1854)	***
*******************************************

PL_BOOTAGA
	PL_START
	PL_P	$AA,.patch
	PL_END


.patch	movem.l	d0-a6,-(a7)
	lea	PL_GAMEAGA(pc),a0
	lea	$97e68,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	movem.l	.FREE(pc),d0-d7
	jmp	$9beda

.FREE	ds.l	8

PL_GAMEAGA
	PL_START

; disable disk checks
	PL_S	$2588,210
	PL_S	$39e0,210
	PL_S	$4122,210
	PL_S	$56e6,210

; disable checksum checks
	PL_B	$80dc,$60
	PL_B	$952c,$60
	PL_B	$15f8c,$60
	PL_B	$4c66,$60
	PL_B	$81b6,$60
	PL_B	$ac3e,$60
	PL_B	$6e26,$60
	PL_B	$860c,$60
	PL_B	$e2f2,$60
	PL_B	$14448,$60
	PL_L	$8372,$4e714e71
	PL_L	$daa6,$4e714e71
	PL_L	$13f2c,$4e714e71
	
; patch loader
	PL_P	$30,LOADER
	PL_R	$2e4
	PL_R	$2ee

	PL_W	$996,$4e71
	PL_L	$f72,$4e714e71
	PL_W	$fc6,$4e71
	

	PL_P	$92C,.diskchange
	PL_P	$f7e,.diskchange
	PL_PS	$E68,.datadisk


	PL_P	$3e50,DECRUNCH


; work restarted after about 11 years on 21.03.2020,
; thanks to Corona...
	PL_ORW	$392a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$253c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$27b0+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2938+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3708+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$37a2+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$831a+2,1<<9		; set Bplcon0 color bit

	PL_B	$3384,$60		; disable checksum check
	PL_L	$43fa,$4e714e71


	PL_PS	$39da,.wblit1

	PL_PS	$6230,.FixKbd		; fix CPU dependent delay in keyboard
	PL_PS	$626e,CheckQuit	; check quitkey


	PL_PS	$44ee,.AckVBI		; ack. VBI and check quitkey
	PL_PS	$60b2,.AckVBI		; ack. VBI and check quitkey
	PL_END


	




.FixKbd	movem.l	d0/d1,-(a7)
	moveq	#3-1,d0
.delay	move.b	$dff006,d1
.same	cmp.b	$dff006,d1
	beq.b	.same
	dbf	d0,.delay
	movem.l	(a7)+,d0/d1
	rts




.datadisk
	lea	CurrentDisk(pc),a0
	move.w	#3,(a0)
	clr.l	$97e68+$34e		; original code
	rts








; d0.l: disk id
.diskchange
	movem.l	d0-a6,-(a7)

	moveq	#0,d3
	lea	.TAB(pc),a0
.loop	movem.l	(a0)+,d1/d2
	tst.l	d1
	beq.b	.end
	cmp.l	d0,d1
	beq.b	.found
	bra.b	.loop

.found	moveq	#1,d3
.end	tst.l	d3
	beq.b	.exit
	lea	CurrentDisk(pc),a0
	move.w	d2,(a0)

	move.l	d1,$97e68+$34e

.exit	moveq	#0,d0		; set z-flag
	movem.l	(a7)+,d0-a6
	moveq	#0,d0
	rts


.TAB	dc.l	$135215,1
	dc.l	$135216,2
	dc.l	$135314,3
	dc.l	0		; end of tab


.wblit1	move.w	#$4014,$58(a6)
	bra.w	WaitBlitA6



.AckVBI	move.w	#$7070,$dff09c
	move.w	#$7070,$dff09c

CheckQuitKey
	move.b	$bfec01,d0
	ror.b	d0
	not.b	d0
;	bra.b	.CheckQuit

CheckQuit
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	move.l	$97e68+$6246,a0
	rts




LOADER	movem.l	d0-a6,-(a7)

	move.w	d1,d6
	move.l	a0,a6

	tst.w	d1
	bmi.w	.out	
	tst.w	d2
	beq.w	.out

	mulu.w	#512,d1
	mulu.w	#512,d2
	move.l	d1,d0
	move.l	d2,d1
	move.w	CurrentDisk(pc),d2
	move.l	resload(pc),a2

	tst.l	d3
	bne.b	.save
	jsr	resload_DiskLoad(a2)
	bra.b	.nosave

.save	cmp.b	#3,d2
	bne.b	.nosave
	exg.l	d0,d1 
	move.l	a0,a1
	lea	.name(pc),a0
	add.b	#"0",d2
	move.b	d2,.num-.name(a0)
	jsr	resload_SaveFileOffset(a2)


.nosave
.out	cmp.w	#$27c,d6
	bne.b	.nopatch1
	lea	PLGAMECODE(pc),a0	; main game
	move.l	a6,a1			; $19dedc
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)	
.nopatch1


	moveq	#0,d0			; set zero flag
	movem.l	(a7)+,d0-a6
	rts

.name	dc.b	"disk."
.num	dc.b	"1",0,0



PLGAMECODE
	PL_START

; fix access fault in sample player
	PL_PS	$482,.fault


	
	PL_PSS	$2778e,.wblit1,2
	PL_PS	$277c0,.wblit2
	PL_PS	$277e6,.wblit2
	PL_PS	$2780c,.wblit2


	PL_PS	$1826,.wblit3		; half-time screen

	PL_PS	$1944,.AckVBI		; ack. VBI and check quitkey
	PL_END


.AckVBI	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	bra.w	CheckQuitKey



; game tries to access sample tab with negative offset...
.fault	tst.w	d0
	bpl.b	.ok
	moveq	#0,d0			; we use sample 0 in this case
.ok	lsl.w	#2,d0
	move.l	(a0,d0.w),a0
	rts



.wblit1	bsr.b	WaitBlitA6
	mulu.w	#$1000,d2
	move.w	d2,$42(a6)
	rts

.wblit2	add.l	$96394,a3
	bra.b	WaitBlitA6


.wblit3	lea	$dff000,a5
	

WaitBlitA5
	tst.w	$02(a5)
.wb	btst	#6,$02(a5)
	bne.b	.wb
	rts


WaitBlitA6
	tst.w	$02(a6)
.wb	btst	#6,$02(a6)
	bne.b	.wb
	rts

CurrentDisk	dc.w	1


; a2: resload
; a5: bootstart

CreateDataDisk

.createdisk
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
	cmp.l	#901120-$30000-$1000,d7
	ble.b	.ok2
	move.l	#901120,d4
	sub.l	d7,d4
.ok2	sub.l	#$30000-$1000,d5
	bpl.b	.loop
.exit	rts

.name	dc.b	"disk."
.num	dc.b	"3",0

	CNOP	0,4



;***********************************
;*** Level 2 IRQ			***
;***********************************
;
;SetLev2IRQ
;	pea	.int(pc)
;	move.l	(a7)+,$68.w
;
;	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
;	tst.b	$bfed01				; clear all CIA A interrupts
;	and.b	#~(1<<6),$bfee01		; set input mode
;
;	move.w	#1<<3,$dff09c			; clear ports interrupt
;	move.w	#1<<15|1<<14|1<<3,$dff09a	; and enable it
;	rts
;
;.int	movem.l	d0-d1/a0-a2,-(a7)
;	lea	$dff000,a0
;	lea	$bfe001,a1
;
;	btst	#3,$1e+1(a0)			; PORTS irq?
;	beq.w	.end
;	btst	#3,$d00(a1)			; KBD irq?
;	beq.w	.end
;
;
;	; call in-game keyboard routine
;	jsr	$97e68+$61d8
;	
;	move.b	$c00(a1),d0
;	not.b	d0
;	ror.b	d0
;	lea	CurrentKey(pc),a2
;	move.b	d0,(a2)
;
;
;
;
;
;	or.b	#1<<6,$e00(a1)			; set output mode
;
;	cmp.b	HEADER+ws_keyexit(pc),d0
;	beq.b	.exit
;	
;
;	moveq	#3-1,d1
;.loop	move.b	$6(a0),d0
;.wait	cmp.b	$6(a0),d0
;	beq.b	.wait
;	dbf	d1,.loop
;
;
;	and.b	#~(1<<6),$e00(a1)	; set input mode
;.end	move.w	#1<<3,$9c(a0)
;	move.w	#1<<3,$9c(a0)		; twice to avoid a4k hw bug
;	movem.l	(a7)+,d0-d1/a0-a2
;	rte
;
;.exit	pea	(TDREASON_OK).w
;.quit	move.l	resload(pc),-(a7)
;	addq.l	#resload_Abort,(a7)
;	rts
;
;
;
;
;CurrentKey	dc.b	0,0



; a0.l: source
; a1.l: dest
; d0.l: key

DECRUNCH
	movem.l	d0-d7/a0-a6,-(sp)
	lea	(-$180,sp),sp
	move.l	sp,a2
	move.w	d0,d5
	bsr.w	lbC002F8E
	moveq	#0,d1
	cmp.l	#$524E4301,d0
	bne.w	lbC002F26
	bsr.w	lbC002F8E
	move.l	d0,($180,sp)
	lea	(10,a0),a3
	move.l	a1,a5
	lea	(a5,d0.l),a6
	bsr.w	lbC002F8E
	lea	(a3,d0.l),a4
	clr.w	-(sp)
	cmp.l	a4,a5
	bhs.b	lbC002E96
	moveq	#0,d0
	move.b	(-2,a3),d0
	lea	(a6,d0.l),a0
	cmp.l	a4,a0
	bls.b	lbC002E96
	addq.w	#2,sp
	move.l	a4,d0
	btst	#0,d0
	beq.b	lbC002E62
	addq.w	#1,a4
	addq.w	#1,a0
lbC002E62
	move.l	a0,d0
	btst	#0,d0
	beq.b	lbC002E6C
	addq.w	#1,a0
lbC002E6C
	moveq	#0,d0
lbC002E6E
	cmp.l	a0,a6
	beq.b	lbC002E7A
	move.b	-(a0),d1
	move.w	d1,-(sp)
	addq.b	#1,d0
	bra.b	lbC002E6E

lbC002E7A
	move.w	d0,-(sp)
	add.l	d0,a0
	move.w	d5,-(sp)
lbC002E80
	lea	(-$20,a4),a4
	movem.l	(a4),d0-d7
	movem.l	d0-d7,-(a0)
	cmp.l	a3,a4
	bhi.b	lbC002E80
	sub.l	a4,a3
	add.l	a0,a3
	move.w	(sp)+,d5
lbC002E96
	moveq	#0,d7
	move.b	(1,a3),d6
	rol.w	#8,d6
	move.b	(a3),d6
	moveq	#2,d0
	moveq	#2,d1
	bsr.w	lbC002F6A
lbC002EA8
	move.l	a2,a0
	bsr.w	lbC002F9A
	lea	($80,a2),a0
	bsr.w	lbC002F9A
	lea	($100,a2),a0
	bsr.w	lbC002F9A
	moveq	#-1,d0
	moveq	#$10,d1
	bsr.w	lbC002F6A
	move.w	d0,d4
	subq.w	#1,d4
	bra.b	lbC002EE8

lbC002ECC
	lea	($80,a2),a0
	moveq	#0,d0
	bsr.b	lbC002F34
	neg.l	d0
	lea	(-1,a5,d0.l),a1
	lea	($100,a2),a0
	bsr.b	lbC002F34
	move.b	(a1)+,(a5)+
lbC002EE2
	move.b	(a1)+,(a5)+
	dbra	d0,lbC002EE2
lbC002EE8
	move.l	a2,a0
	bsr.b	lbC002F34
	subq.w	#1,d0
	bmi.b	lbC002F10
lbC002EF0
	move.b	(a3)+,(a5)+
	eor.b	d5,(-1,a5)
	dbra	d0,lbC002EF0
	ror.w	#1,d5
	move.b	(1,a3),d0
	rol.w	#8,d0
	move.b	(a3),d0
	lsl.l	d7,d0
	moveq	#1,d1
	lsl.w	d7,d1
	subq.w	#1,d1
	and.l	d1,d6
	or.l	d0,d6
lbC002F10
	dbra	d4,lbC002ECC
	cmp.l	a6,a5
	blo.b	lbC002EA8
	move.w	(sp)+,d0
	beq.b	lbC002F24
lbC002F1C
	move.w	(sp)+,d1
	move.b	d1,(a5)+
	subq.b	#1,d0
	bne.b	lbC002F1C
lbC002F24
	bra.b	lbC002F2A

lbC002F26
	move.l	d1,($180,sp)
lbC002F2A
	lea	($180,sp),sp
	movem.l	(sp)+,d0-d7/a0-a6
	rts

lbC002F34
	move.w	(a0)+,d0
	and.w	d6,d0
	sub.w	(a0)+,d0
	bne.b	lbC002F34
	move.b	($3C,a0),d1
	sub.b	d1,d7
	bge.b	lbC002F46
	bsr.b	lbC002F76
lbC002F46
	lsr.l	d1,d6
	move.b	($3D,a0),d0
	cmp.b	#2,d0
	blt.b	lbC002F68
	subq.b	#1,d0
	move.b	d0,d1
	move.b	d0,d2
	move.w	($3E,a0),d0
	and.w	d6,d0
	sub.b	d1,d7
	bge.b	lbC002F64
	bsr.b	lbC002F76
lbC002F64
	lsr.l	d1,d6
	bset	d2,d0
lbC002F68
	rts

lbC002F6A
	and.w	d6,d0
	sub.b	d1,d7
	bge.b	lbC002F72
	bsr.b	lbC002F76
lbC002F72
	lsr.l	d1,d6
	rts

lbC002F76
	add.b	d1,d7
	lsr.l	d7,d6
	swap	d6
	addq.w	#4,a3
	move.b	-(a3),d6
	rol.w	#8,d6
	move.b	-(a3),d6
	swap	d6
	sub.b	d7,d1
	moveq	#$10,d7
	sub.b	d1,d7
	rts

lbC002F8E
	moveq	#3,d1
lbC002F90
	lsl.l	#8,d0
	move.b	(a0)+,d0
	dbra	d1,lbC002F90
	rts

lbC002F9A
	moveq	#$1F,d0
	moveq	#5,d1
	bsr.b	lbC002F6A
	subq.w	#1,d0
	bmi.b	lbC003020
	move.w	d0,d2
	move.w	d0,d3
	lea	(-$10,sp),sp
	move.l	sp,a1
lbC002FAE
	moveq	#15,d0
	moveq	#4,d1
	bsr.b	lbC002F6A
	move.b	d0,(a1)+
	dbra	d2,lbC002FAE
	moveq	#1,d0
	ror.l	#1,d0
	moveq	#1,d1
	moveq	#0,d2
	movem.l	d5-d7,-(sp)
lbC002FC6
	move.w	d3,d4
	lea	(12,sp),a1
lbC002FCC
	cmp.b	(a1)+,d1
	bne.b	lbC00300A
	moveq	#1,d5
	lsl.w	d1,d5
	subq.w	#1,d5
	move.w	d5,(a0)+
	move.l	d2,d5
	swap	d5
	move.w	d1,d7
	subq.w	#1,d7
lbC002FE0
	roxl.w	#1,d5
	roxr.w	#1,d6
	dbra	d7,lbC002FE0
	moveq	#$10,d5
	sub.b	d1,d5
	lsr.w	d5,d6
	move.w	d6,(a0)+
	move.b	d1,($3C,a0)
	move.b	d3,d5
	sub.b	d4,d5
	move.b	d5,($3D,a0)
	moveq	#1,d6
	subq.b	#1,d5
	lsl.w	d5,d6
	subq.w	#1,d6
	move.w	d6,($3E,a0)
	add.l	d0,d2
lbC00300A
	dbra	d4,lbC002FCC
	lsr.l	#1,d0
	addq.b	#1,d1
	cmp.b	#$11,d1
	bne.b	lbC002FC6
	movem.l	(sp)+,d5-d7
	lea	($10,sp),sp
lbC003020
	rts

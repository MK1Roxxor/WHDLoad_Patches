***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        KICK OFF 3 WHDLOAD SLAVE            )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              March 2009                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 30-Mar-2009	- keyboard fixed
;		- load/save implemented
;		- tested in all snoop modes, all snoop faults fixed
;		- slave for the ECS version is finished

; 29-Mar-2009	- work started
;		- disk protections, checksums checks etc. disabled
;		- game works, no support for loading/saving yet 

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_EmulTrap
DEBUGKEY	= $58		; F9
QUITKEY		= $59		; F10
DEBUG



HEADER	SLAVE_HEADER		; ws_security + ws_ID
	dc.w	10		; ws_version
	dc.w	FLAGS		; flags
	dc.l	524288*2	; ws_BaseMemSize
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

	IFD	DEBUG
.dir	dc.b	"SOURCES:WHD_Slaves/KickOff3/",0
	ENDC
.name	dc.b	"Kick Off 3",0
.copy	dc.b	"1994 Anco",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	dc.b	"Version 1.00 (29.03.2009)",0
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
	bsr	SetLev2IRQ

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
	lea	PL_BOOTECS(pc),a0
	cmp.w	#$1899,d0		; ECS version, SPS 0191
	beq.b	.ok

; unknown version
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT

.ok


; patch it
	move.l	a5,a1
	jsr	resload_Patch(a2)
	
; load crypted main file
	move.l	#$89c00,d0
	move.l	#$16000,d1
	moveq	#1,d2
	lea	$30000,a0
	jsr	resload_DiskLoad(a2)


	move.l	NODATADISK(pc),d0
	bne.b	.nodatadisk
	bsr	CreateDataDisk		; create data disk if it doesn't exist
.nodatadisk
	jmp	$116(a5)

QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	jmp	resload_Abort(a2)


*******************************************
*** ECS VERSION 	(SPS 191)	***
*******************************************

PL_BOOTECS
	PL_START
	PL_L	$154+2,$C1e0e0-$b80000
	PL_P	$192,.patch
	PL_END


.patch	movem.l	d0-a6,-(a7)
	lea	$9e0e0,a0	; start
	lea	$b1250,a1	; end
	lea	.TAB(pc),a4
	move.w	#$96ce,d3
	move.w	#$581a,d4
	lea	PL_GAMEECS(pc),a5
	bsr	DecryptAndPatch
	movem.l	(a7)+,d0-a6
	movem.l	.FREE(pc),d0-d7
	jmp	$9e0e0

.TAB	DC.W	$34BF,$C183,$609E,$6BD4,$B1B2,$5340,$ECF3,$30E1
	DC.W	$7BD7,$5C71,$4F99,$B63A,$9ABC,$7856,$95E3,$6CD5
	DC.W	$598D,$34D6,$DE10,$9339,$CB88,$3A97,$0788,$9C4B
	DC.W	$4A0C,$C54D,$674E,$EA38,$EA6F,$6EDB,$2B92,$AABA

.FREE	ds.l	8

PL_GAMEECS
	PL_START


; patch memory check
	PL_P	$270a,.mem

; disable disk checks
	PL_S	$98,210
	PL_S	$18a6,210
	PL_S	$2308,210
	PL_S	$A6A8,210

; disable checksum checks
	PL_B	$37d2,$60
	PL_B	$512e,$60
	PL_B	$10aec,$60
	PL_B	$4c7e,$60
	PL_B	$608e,$60
	PL_B	$10ff6,$60
	PL_B	$4bb2,$60
	PL_B	$77AA,$60
	PL_B	$12b52,$60
	PL_L	$4e3a,$4e714e71
	PL_L	$A62E,$4e714e71
	PL_L	$AE6A,$4e714e71


; patch loader
	PL_P	$5bc,LOADER
	PL_R	$86E
	PL_R	$878

	PL_W	$f38,$4e71
	PL_L	$14d2,$4e714e71
	PL_W	$1526,$4e71
	PL_W	$1c0e,$4e71
	PL_L	$4d3a,$4e714e71
	PL_W	$4d8e,$4e71
	PL_W	$5238,$4e71

	PL_PS	$13c6,.datadisk



; set level 2 irq
	PL_W	$2b12+2,$c018
	PL_L	$2baa,$4e714e71

	PL_R	$A0CAE-$9E0E0		; avoid lockup in kbd routine
	PL_END




.datadisk
	lea	CurrentDisk(pc),a0
	move.w	#3,(a0)
	clr.l	$9e0e0+$8d8		; original code
	rts


.mem	move.l	#$80000,$9e0e0+$277e
	rts















LOADER	movem.l	d0-a6,-(a7)

	tst.w	d1
	bmi.w	.out	
	tst.w	d2
	beq.w	.out

	cmp.w	#$c020,$fe92+2
	bne.b	.nolev2
	move.w	#$c028,$fe92+2
.nolev2	cmp.l	#$dff1fc,$fdc8+4
	bne.b	.noacc
	move.l	#$dff1fe,$fdc8+4	; $1fc->nop
.noacc
	

	cmp.w	#2,d1
	bne.b	.nodir
	movem.l	d0-a6,-(a7)

	moveq	#1,d1
	cmp.l	#$00135315,d0
	beq.b	.store
	moveq	#2,d1
	cmp.l	#$00135316,d0
	beq.b	.store
	bra.b	.unk
.store	lea	CurrentDisk(pc),a0
	move.w	d1,(a0)
.unk
	movem.l	(a7)+,d0-a6


.nodir


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
.out	moveq	#0,d0
	tst.w	d0
	movem.l	(a7)+,d0-a6
	rts

.name	dc.b	"disk."
.num	dc.b	"1",0,0

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


; d3.w: key1
; d4.w: key2
; a0.l: start
; a1.l: end
; a4.l: tab
; a5.l: PLIST

DecryptAndPatch
	movem.l	d0-a6,-(a7)
.outer	move.l	a4,a3
	moveq	#32-1,d0
.loop	cmp.l	a0,a1
	beq.b	.done
	add.w	a0,d3
	move.w	(a0),d1
	sub.w	d3,d1
	add.w	(a3)+,d1
	move.w	d1,(a0)+
	add.w	d1,d4
	dbf	d0,.loop
	bra.b	.outer

.done	move.l	a5,a0
	lea	$9e0e0,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
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
	beq.w	.end
	btst	#3,$d00(a1)			; KBD irq?
	beq.w	.end


	; call in-game keyboard routine
	jsr	$9e0e0+$2b7e
	
	move.b	$c00(a1),d0
	not.b	d0
	ror.b	d0
	lea	CurrentKey(pc),a2
	move.b	d0,(a2)





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
	

	moveq	#3-1,d1
.loop	move.b	$6(a0),d0
.wait	cmp.b	$6(a0),d0
	bne.b	.wait
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



CurrentKey	dc.b	0,0




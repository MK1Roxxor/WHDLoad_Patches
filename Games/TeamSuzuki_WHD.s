***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        TEAM SUZUKI WHDLOAD SLAVE           )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             March 2020                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 09-Apr-2021	- annoying disk requests removed (tricky!), this in turn
;		  made it possible to remove the "Set Disk" patches, the
;		  directory files are not needed anymore either

; 07-Apr-2021	- timing fixed
;		- directory loading patched, title screen is now shown
;		- load/save support (league) added
;		- 68000 quitkey support
;		- interrupts fixed

; 08-Mar-2020	- work started

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap|WHDLF_NoDivZero
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


.config	dc.b	"C1:B:Disable Timing Fix"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/TeamSuzuki/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Team Suzuki",0
.copy	dc.b	"1991 Gremlin",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.2 (09.04.2021)",0

Name	dc.b	"suzam.ukc",0

	CNOP	0,4

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

; install level 2 interrupt
	bsr	SetLev2IRQ

; load game
	lea	Name(pc),a0
	lea	$400.w,a1
	move.l	a1,a5
	jsr	resload_LoadFile(a2)
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$ADB9,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

; decrunch
	move.l	a5,a0
	move.l	a0,a1
	movem.l	d0-a6,-(a7)
	bsr	Decrunch
	movem.l	(a7)+,d0-a6

; patch
	lea	PLGAME(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

	jmp	(a5)




QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)


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




AckVBI	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte




AckLev2
	move.w	#$4788,$dff09c
	move.w	#$4788,$dff09c
	rte	


PLGAME	PL_START
	PL_R	$11188			; disable loader init
	;PL_R	$1227a			; disable protection check
	PL_R	$1ce			; disable complete protection
	;PL_B	$364,$60		; disable manual check

	PL_P	$121aa,.LoadFile
	PL_R	$1112c			; disable disk change check

	PL_R	$111c4			; disable motor on
	PL_R	$111fa			; disable motor off
	PL_R	$11218			; disable step to track


	PL_SA	$11eaa,$11ed8		; load directory
	PL_SA	$11eee,$11f0e		; save directory
	PL_SA	$40e,$424		; skip game disk check -> load title
	PL_SA	$1c3e,$1c54		; skip game disk check -> load music


	PL_IFC1
	; If custom 1 is enabled, do nothing -> no timing fix.

	PL_ELSE

	PL_PS	$137ee,.FixTiming
	PL_ENDIF


	PL_PSA	$12156,.SaveData,$12162

	
	PL_PS	$4e8,.CheckQuit
	PL_PSS	$548,.AckLev2,2
	PL_PSS	$55e,.AckLev2,2

	PL_P	$588,.AckBLT
	PL_P	$6d4,.AckCOP
	PL_P	$716,.AckLev4_1
	PL_P	$758,.AckLev4_2
	PL_P	$79a,.AckLev4_3
	PL_P	$7d2,.AckLev4_4
	PL_P	$7e6,.AckLev5
	PL_P	$7fa,.AckLev6

	; tricky, disable disk requests
	PL_AL	$3e2f8,$3c6f4-$3c6e2	; change ptr to load league data
	PL_SA	$3c708,$3c73a		; load league, skip disk check
	PL_SA	$3c7ac,$3c6d0		; don't request game disk

	PL_AL	$3e35c,$3c926-$3c846	; change ptr to save league data
	PL_SA	$3c93a,$3c950		; save league, skip disk check
	PL_SA	$3c96a,$3cc7e		; don't request game disk

	PL_END



.AckBLT	move.w	#1<<6,$dff09c
	move.w	#1<<6,$dff09c
	rte

.AckCOP	move.w	#1<<4,$dff09c
	move.w	#1<<4,$dff09c
	rte

.AckLev2
	move.w	#1<<3,$dff09c
	move.w	#1<<3,$dff09c
	rts	

.AckLev4_1
	move.w	#1<<10,$dff09c
	move.w	#1<<10,$dff09c
	rte	

.AckLev4_2
	move.w	#1<<9,$dff09c
	move.w	#1<<9,$dff09c
	rte	

.AckLev4_3
	move.w	#1<<8,$dff09c
	move.w	#1<<8,$dff09c
	rte	

.AckLev4_4
	move.w	#1<<7,$dff09c
	move.w	#1<<7,$dff09c
	rte	

.AckLev5
	move.w	#1<<12,$dff09c
	move.w	#1<<12,$dff09c
	rte	

.AckLev6
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte	

.CheckQuit
	bsr.b	.GetKey
	ror.b	d0
	not.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT

.GetKey	move.b	$bfec01,d0
	rts


; a0.l: data to save
; d7.l: length

.SaveData
	move.l	a0,a1
	move.l	$400+$11e98,a0		; file name
	move.l	d7,d0
	moveq	#0,d7			; all bytes saved
	move.l	resload(pc),a2
	jmp	resload_SaveFile(a2)


.FixTiming
	moveq	#4-1,d7
.delay	bsr	WaitRaster	
	dbf	d7,.delay

	tst.w	$400+$14626		; original code
.file_does_not_exist	
	rts

.LoadFile
	movem.l	a0/a1,-(a7)
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	movem.l	(a7)+,a0/a1
	tst.l	d0
	beq.b	.file_does_not_exist	
	jmp	resload_LoadFileDecrunch(a2)



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



Decrunch
	move.l	#'*FUN',d0
	move.l	#'GUS*',d1
.decrunch1
	cmp.l	(a0)+,d0
	beq.b	.decrunch2
	cmp.l	(a0)+,d0
	bne.b	.decrunch1
.decrunch2
	cmp.l	(a0)+,d1
	bne.b	.decrunch1
	subq.w	#8,a0
	move.l	-(a0),a2
	add.l	a1,a2
	move.l	-(a0),d0
	move.l	-(a0),d4
	move.l	-(a0),d5
	move.l	-(a0),d6
	move.l	-(a0),d7
.decrunch3
	add.l	d0,d0
	bne.b	.decrunch4
	move.l	d4,d0
	move.l	d5,d4
	move.l	d6,d5
	move.l	d7,d6
	move.l	-(a0),d7
	move.w	#$FFFF,ccr
	addx.l	d0,d0
.decrunch4
	blo.w	.decrunch11
	moveq	#3,d1
	moveq	#0,d3
	add.l	d0,d0
	bne.b	.decrunch5
	move.l	d4,d0
	move.l	d5,d4
	move.l	d6,d5
	move.l	d7,d6
	move.l	-(a0),d7
	move.w	#$FFFF,ccr
	addx.l	d0,d0
.decrunch5
	blo.b	.decrunch7
	moveq	#1,d3
	moveq	#8,d1
	bra.w	.decrunch15

.decrunch6
	moveq	#8,d1
	moveq	#8,d3
.decrunch7
	bsr.w	.decrunch18
	add.w	d2,d3
.decrunch8
	moveq	#7,d1
.decrunch9
	add.l	d0,d0
	bne.b	.decrunch10
	move.l	d4,d0
	move.l	d5,d4
	move.l	d6,d5
	move.l	d7,d6
	move.l	-(a0),d7
	move.w	#$FFFF,ccr
	addx.l	d0,d0
.decrunch10
	addx.w	d2,d2
	dbra	d1,.decrunch9
	move.b	d2,-(a2)
	dbra	d3,.decrunch8
	bra.w	.decrunch17

.decrunch11
	moveq	#0,d2
	add.l	d0,d0
	bne.b	.decrunch12
	move.l	d4,d0
	move.l	d5,d4
	move.l	d6,d5
	move.l	d7,d6
	move.l	-(a0),d7
	move.w	#$FFFF,ccr
	addx.l	d0,d0
.decrunch12
	addx.w	d2,d2
	add.l	d0,d0
	bne.b	.decrunch13
	move.l	d4,d0
	move.l	d5,d4
	move.l	d6,d5
	move.l	d7,d6
	move.l	-(a0),d7
	move.w	#$FFFF,ccr
	addx.l	d0,d0
.decrunch13
	addx.w	d2,d2
	cmp.b	#2,d2
	blt.b	.decrunch14
	cmp.b	#3,d2
	beq.b	.decrunch6
	moveq	#8,d1
	bsr.w	.decrunch18
	move.w	d2,d3
	move.w	#12,d1
	bra.w	.decrunch15

.decrunch14
	moveq	#2,d3
	add.w	d2,d3
	move.w	#9,d1
	add.w	d2,d1
.decrunch15
	bsr.w	.decrunch18
	lea	(1,a2,d2.w),a3
.decrunch16
	move.b	-(a3),-(a2)
	dbra	d3,.decrunch16
.decrunch17
	cmp.l	a2,a1
	bne.w	.decrunch3
	rts

.decrunch18
	subq.w	#1,d1
	clr.w	d2
.decrunch19
	add.l	d0,d0
	bne.b	.decrunch20
	move.l	d4,d0
	move.l	d5,d4
	move.l	d6,d5
	move.l	d7,d6
	move.l	-(a0),d7
	move.w	#$FFFF,ccr
	addx.l	d0,d0
.decrunch20
	addx.w	d2,d2
	dbra	d1,.decrunch19
	rts


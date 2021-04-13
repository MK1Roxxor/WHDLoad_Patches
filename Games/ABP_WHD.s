***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   APB - ALL POINTS BULLETIN WHDLOAD SLAVE  )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             April 2021                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 13-Apr-2021	- minor changes (mainly for the TNT collection version)
;		- "No Demerits" trainer added

; 12-Apr-2021	- work started

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap|WHDLF_NoDivZero
QUITKEY		= $59		; F10
;DEBUG

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


.config	dc.b	"C1:B:Disable Brightness Fix;"
	dc.b	"C2:B:No Demerits"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/APB/"
	ENDC
	dc.b	"data",0

.name	dc.b	"APB - All Points Bulletin",0
.copy	dc.b	"1989 Tengen",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.2 (13.04.2021)",0

Name	dc.b	"APB.0184",0

	CNOP	0,4

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a4


	; load game
	lea	Name(pc),a0
	lea	$54c50,a1
	move.l	a1,a5
	jsr	resload_LoadFile(a4)
	move.l	a5,a0
	jsr	resload_CRC16(a4)
	lea	PLGAME(pc),a0
	cmp.w	#$10BA,d0		; SPS 1240, SPS 2870
	beq.b	.ok

	cmp.w	#$ADEB,d0		; SPS 1708 (TNT Compilation)
	bne.b	.unsupported

	; copy crunched data to safe location
	lea	$1a4(a5),a0
	lea	$10000,a1
	moveq	#3*4,d0
	add.l	2*4(a0),d0		; crunched size
.copy	move.b	(a0)+,(a1)+
	subq.l	#1,d0
	bne.b	.copy

	; decrunch
	lea	$10000,a3
	move.l	a3,d0
	move.l	2*4(a3),d1
	lea	3*4(a3),a0		; start of crunched data
	
	bsr	Decrunch

	lea	PLGAME_TNT(pc),a0


	; patch
.ok	move.l	a5,a1
	jsr	resload_Patch(a4)

	jmp	(a5)


.unsupported
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT


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



; ---------------------------------------------------------------------------

PLGAME_TNT
	PL_START
	PL_PSA	$afca,LoadFile,$b082
	PL_NEXT	PLCOMMON


PLGAME	PL_START
	PL_P	$afb2,LoadFile
	PL_NEXT	PLCOMMON


PLCOMMON
	PL_START
	PL_IFC1
	PL_ELSE
	PL_P	$9e30,.SetColors
	PL_ENDIF
	PL_P	$a508,.AckVBI
	PL_P	$a5c4,.AckVBI2
	PL_P	$a69a,.AckVBI2
	PL_P	$a726,.AckVBI
	PL_P	$a7ca,.AckVBI
	PL_P	$a836,.AckVBI
	PL_PS	$a8e6,.CheckQuit

	; no demerits trainer
	PL_IFC2
	PL_S	$4b50,$6
	PL_S	$67b8,$6
	

	PL_ENDIF

	PL_END

.CheckQuit
	bsr.b	.GetKey
	ror.b	d0
	not.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT

.GetKey	clr.w	d0
	move.b	$c00(a0),d0
	rts

.AckVBI	move.w	d1,$9c(a0)
	move.w	d1,$9c(a0)
	movem.l	(a7)+,d0/d1/a0
	rte

.AckVBI2
	move.w	d1,$9c(a0)
	move.w	d1,$9c(a0)
	movem.l	(a7)+,d0/d1/a0/a1
	rte

.SetColors
	movem.l	d0/d1/a0/a1,-(a7)
	moveq	#16-1,d0
	lea	$dff180,a1
.copy	move.w	(a0)+,d1
	add.w	d1,d1			; fix Atari ST brightness
	move.w	d1,(a1)+
	dbf	d0,.copy
	movem.l	(a7)+,d0/d1/a0/a1
	rts


; d1.w: sector
; d2.w: number of sectors to load
; a0.l: destination

LoadFile
	movem.l	d1-a6,-(a7)
	move.l	a0,a1

	bsr.b	BuildName
	move.l	resload(pc),a2
	jsr	resload_LoadFileDecrunch(a2)

	movem.l	(a7)+,d1-a6
	moveq	#0,d0			; no errors
	rts


; d1.w: sector number
; ----
; a0.l: ptr to file name

BuildName
	lea	Name(pc),a0
	moveq	#3-1,d7

.loop	moveq	#15,d0
	and.b	d1,d0

	cmp.b	#9,d0
	ble.b	.ok
	addq.b	#7,d0
.ok	add.b	#"0",d0

	move.b	d0,5(a0,d7.w)

	ror.w	#4,d1

	dbf	d7,.loop
	rts




; ---------------------------------------------------------------------------

Decrunch
	add.l	d1,a0
	move.l	1*4(a3),a1
	move.l	-(a0),a2
	add.l	a1,a2
	move.l	-(a0),d0

.decrunch_loop
	moveq	#3,d1
	bsr.w	.GetBits
	tst.b	d2
	beq.b	.lbC0000F2
	cmp.w	#7,d2
	bne.b	.lbC0000C0
	lsr.l	#1,d0
	bne.b	.lbC0000A2
	bsr.w	.NextLong
.lbC0000A2
	bcc.w	.lbC0000B8

	moveq	#10,d1
	bsr.w	.GetBits
	tst.w	d2
	bne.b	.lbC0000C0
	moveq	#$12,d1
	bsr.w	.GetBits
	bra.b	.lbC0000C0

.lbC0000B8
	moveq	#4,d1
	bsr.w	.GetBits
	addq.w	#7,d2
.lbC0000C0
	subq.w	#1,d2
.lbC0000C2
	moveq	#7,d1
.lbC0000C4
	lsr.l	#1,d0
	beq.w	.lbC0000DE
	roxl.l	#1,d3
	dbra	d1,.lbC0000C4
	move.b	d3,-(a2)

	move.w	d2,$DFF180
	dbf	d2,.lbC0000C2
	bra.b	.lbC0000F2

.lbC0000DE
	move.l	-(a0),d0
	move.w	#1<<4,ccr
	roxr.l	#1,d0
	roxl.l	#1,d3
	dbf	d1,.lbC0000C4
	move.b	d3,-(a2)
	dbf	d2,.lbC0000C2
.lbC0000F2
	cmp.l	a2,a1
	bge.w	.exit

	moveq	#2,d1
	bsr.w	.GetBits
	moveq	#2,d3
	moveq	#8,d1
	tst.w	d2
	beq.b	.lbC000164

	moveq	#4,d3
	cmp.w	#2,d2
	beq.b	.lbC00014E
	moveq	#3,d3
	cmp.w	#1,d2
	beq.b	.lbC000140
	moveq	#2,d1
	bsr.w	.GetBits
	cmp.w	#3,d2
	beq.b	.lbC000138
	cmp.w	#2,d2
	beq.b	.lbC00012E
	addq.w	#5,d2
	move.w	d2,d3
	bra.b	.lbC00014E

.lbC00012E
	moveq	#2,d1
	bsr.b	.GetBits
	addq.w	#7,d2
	move.w	d2,d3
	bra.b	.lbC00014E

.lbC000138
	moveq	#8,d1
	bsr.b	.GetBits
	move.w	d2,d3
	bra.b	.lbC00014E

.lbC000140
	moveq	#8,d1
	lsr.l	#1,d0
	bne.b	.lbC000148
	bsr.b	.NextLong
.lbC000148
	bcs.b	.lbC000164
	moveq	#14,d1
	bra.b	.lbC000164

.lbC00014E
	moveq	#16,d1
	lsr.l	#1,d0
	bne.b	.lbC000156
	bsr.b	.NextLong
.lbC000156
	bcc.b	.lbC000164
	moveq	#8,d1
	lsr.l	#1,d0
	bne.b	.lbC000160
	bsr.b	.NextLong
.lbC000160
	bcs.b	.lbC000164
	moveq	#12,d1

.lbC000164
	bsr.b	.GetBits
	subq.w	#1,d3
.lbC000168
	move.b	-1(a2,d2.l),-(a2)
	dbf	d3,.lbC000168
	bra.w	.decrunch_loop

.exit	rts


.NextLong
	move.l	-(a0),d0
	move.w	#1<<4,ccr
	roxr.l	#1,d0
	rts

.GetBits_NextLong
	move.l	-(a0),d0
	move.w	#1<<4,ccr
	roxr.l	#1,d0
	roxl.l	#1,d2
	dbf	d1,.loop
	rts

.GetBits
	subq.w	#1,d1
	clr.l	d2
.loop	lsr.l	#1,d0
	beq.b	.GetBits_NextLong
	roxl.l	#1,d2
	dbf	d1,.loop
	rts

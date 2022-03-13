; Airball WHDLoad v1.1, 27.10.2017, StingRay
; - bootblock loading removed, main file is now loaded directly
; - version check added
; - blitter waits added (68010+ only)
; - out of bounds blit fixed
; - interrupts fixed
; - 68000 quitkey support
; - default quitkey changed to Del as F10 is used in the game

; V1.2, 12/13.03.2022
; - unlimited lives trainer added
; - unlimited energy trainer added
; - in-game keys added
; - demo can be skipped with space or fire
; - game can be started with space or fire

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i

; Trainer options
TRB_LIVES		= 1		; unlimited lives
TRB_ENERGY		= 2		; unlimited energy
TRB_KEYS		= 3		; in-game keys

	
RAWKEY_1	= $01
RAWKEY_2	= $02
RAWKEY_3	= $03
RAWKEY_4	= $04
RAWKEY_5	= $05
RAWKEY_6	= $06
RAWKEY_7	= $07
RAWKEY_8	= $08
RAWKEY_9	= $09
RAWKEY_0	= $0A

RAWKEY_Q	= $10
RAWKEY_W	= $11
RAWKEY_E	= $12
RAWKEY_R	= $13
RAWKEY_T	= $14
RAWKEY_Y	= $15		; English layout
RAWKEY_U	= $16
RAWKEY_I	= $17
RAWKEY_O	= $18
RAWKEY_P	= $19

RAWKEY_A	= $20
RAWKEY_S	= $21
RAWKEY_D	= $22
RAWKEY_F	= $23
RAWKEY_G	= $24
RAWKEY_H	= $25
RAWKEY_J	= $26
RAWKEY_K	= $27
RAWKEY_L	= $28

RAWKEY_Z	= $31		; English layout
RAWKEY_X	= $32
RAWKEY_C	= $33
RAWKEY_V	= $34
RAWKEY_B	= $35
RAWKEY_N	= $36
RAWKEY_M	= $37

RAWKEY_HELP	= $5f

HEADER	SLAVE_HEADER		; ws_Security+ws_ID
	DC.W	17		; ws_Version
	DC.W	7		; ws_Flags
	DC.L	$80000		; ws_BaseMemSize
	DC.L	0		; ws_ExecInstall
	DC.W	Patch-HEADER	; ws_GameLoader
	DC.W	0		; ws_CurrentDir
	DC.W	0		; ws_DontCache
	DC.B	0		; ws_keydebug
	DC.B	$46		; ws_keyexit
	DC.L	0		; ws_ExpMem
	DC.W	.name-HEADER	; ws_name
	DC.W	.copy-HEADER	; ws_copy
	DC.W	.info-HEADER	; ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"C1:X:Unlimited Lives:",TRB_LIVES+"0",";"
	dc.b	"C1:X:Unlimited Energy:",TRB_ENERGY+"0",";"
	dc.b	"C1:X:In-Game Keys:",TRB_KEYS+"0",";"

.name	dc.b	"Airball",0
.copy	dc.b	"1987-89 Microdeal",0
.info	dc.b	"adapted by Mr.Larmer & StingRay",10
	dc.b	"Version 1.2 (13.03.2022)",-1
	dc.b	"Greetings to Helmut Motzkau",-1
	dc.b	"In-Game Keys:",-1
	dc.b	"U: Toggle Unlimited Lives",10
	dc.b	"E: Toggle Unlimited Energy",0 
	CNOP	0,2

TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	TAG_DONE

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


; load game
	lea	$600.w,a0
	move.l	#$1400,d0
	move.l	#35000,d1
	move.l	a0,a5
	move.l	d1,d5
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$df55,d0
	beq.b	.ok
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

; install blitter wait patches (68010+ only)
	move.l	CPUFLAGS(pc),d0
	lsr.l	#1,d0			; carry: AFB_68010 bit
	bcc.b	.noblit
	lea	PLBLIT(pc),a0
	bsr.b	.patch	
.noblit


	lea	PLGAME(pc),a0
	bsr.b	.patch
	jmp	(a5)


.patch	move.l	a5,a1
	jmp	resload_Patch(a2)


PLBLIT	PL_START
	PL_PS	$1eae,.wblit1
	PL_PS	$1ed6,.wblit1
	PL_PS	$17c8,.wblit1
	PL_PS	$1772,.wblit1
	PL_PS	$3924,.wblit1
	PL_PS	$4b92,.wblit1
	
	PL_END

.wblit1	lea	$dff000,a6
	tst.b	$02(a6)
.wb	btst	#6,$02(a6)
	bne.b	.wb
	rts


PLGAME	PL_START
	PL_P	$5640,Load
	PL_R	$58ae			; disable drive access (motor on)
	PL_R	$588c			; disable drive access (motor off)
	PL_PS	$1814,.fixblit
	PL_P	$20de,.ackVBI
	PL_P	$2168,.ackLev2
	PL_PS	$20fa,.checkquit
	PL_S	$1f24,$1f42-$1f24	; don't patch exception vectors

	; Unlimited Lives
	PL_IFC1X	TRB_LIVES
	PL_B	$34a8,$4a
	PL_ENDIF

	; Unlimited Energy
	PL_IFC1X	TRB_ENERGY
	PL_W	$2d7a,$4e75
	PL_ENDIF

	; In-Game Keys
	PL_IFC1X	TRB_KEYS
	PL_PS	$20fa,.Handle_Keys
	PL_ENDIF

	PL_PS	$136,.Get_Skip_Demo_Text_Pointer
	PL_PS	$188,.Check_Space_Or_Fire
	PL_PS	$1b4,.Check_Space_Or_Fire
	PL_PS	$13e2,.Check_Space_Or_Fire
	PL_END

.Get_Skip_Demo_Text_Pointer
	lea	.Text_Skip_Demo(pc),a0
	rts

.Check_Space_Or_Fire
	btst	#7,$bfe001
	bne.b	.Fire_Not_Pressed
	st	-(a7)
	tst.w	(a7)+
	rts

.Fire_Not_Pressed
	tst.b	$600+$76a8.w		; original code
.exit	rts

.Text_Skip_Demo
	dc.b	1,60
	dc.b	1,1
	dc.b	"PRESS THE SPACEBAR",0
	dc.b	0,80
	dc.b	"OR FIRE TO SKIP DEMO",0,0
	dc.b	0
	CNOP	0,2


.Handle_Keys
	bsr.b	.checkquit

	; d1.b: raw key
	cmp.b	#RAWKEY_E,d1
	beq.b	.Toggle_Unlimited_Energy

	cmp.b	#RAWKEY_U,d1
	beq.b	.Toggle_Unlimited_Lives
	rts



.Toggle_Unlimited_Energy
	eor.w	#$cc,$600+$2d7a		; jsr handle_collisions <-> rts
	rts

.Toggle_Unlimited_Lives
	eor.b	#$19,$600+$34a8		; subq.w <-> tst.w
	rts

.checkquit
	move.b	$bfec01,d0
	move.b	d0,d1
	ror.b	d1
	not.b	d1
	cmp.b	HEADER+ws_keyexit(pc),d1
	bne.b	.noquit
	pea	(TDREASON_OK).w
	bra.w	EXIT
.noquit	rts

.ackLev2
	move.w	#1<<3,$dff09c
	move.w	#1<<3,$dff09c
	rte	

.ackVBI	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte


.fixblit
	or.w	d2,d3
	cmp.l	#$7f8e2,a1
	bcs.b	.ok
	sub.w	#12<<6,d3		; blit 12 lines less
.ok	move.w	d3,$58(a6)
	rts


EXIT	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts


; d0.b: side (0/1)
; d6.w: track
; d5.w: sector in track
; d7.l: length in bytes
; a2.l: destination

Load	movem.l	d0-d7/a0-a2,-(sp)
	mulu	#512*10,d6
	subq.l	#1,d5
	mulu	#512,d5
	add.l	d5,d6
	tst.l	d0
	bne.b	.side1
	add.l	#80*512*10,d6
.side1	move.l	d6,d0
	move.l	d7,d1
	moveq	#1,d2
	move.l	a2,a0
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(sp)+,d0-d7/a0-a2
	rts

resload	dc.l	0


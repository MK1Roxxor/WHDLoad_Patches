; 14.07.2016, V1.01, StingRay
; - uninitialised copperlist problem fixed
; - blitter wait added
; - WHDLoad v17+ features used (config)
; - trainer options added
; - ButtonWait code optimised, uses resload_Delay now
; - interrupt fixed
; - default quitkey changed to F10
; - most of the patch code converted to use patch lists
; - correct spelling of the game name in the splash window :)

; 15.07.2016:
; - more trainer options added

; 16.07.2016:
; - level skip and some more in-game keys added
; - version check added
; - CPU dependent timing fixed (credits/high-scores display)
; - much better and cleaner invincibility trainer
; - all patches done with patchlists now

; 17.07.2016
; - 68000 quitkey only worked when in-game keys were enabled, fixed

; 13.04.2023
; - jump with fire 2 added (CUSTOM3), issue #6042

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	whdload.i

;DEBUG
QUITKEY	= $59			; F10

HEADER	SLAVE_HEADER
	dc.w	17		; ws_version
	dc.w	$47		; ws_flags
	dc.l	$80000		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	IFD	DEBUG
	dc.w	.dir-HEADER
	ELSE
	dc.w	0		; ws_CurrentDir
	ENDC
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_keydebug
	dc.b	QUITKEY		; ws_keyexit
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

.config	dc.b	"BW;"
	dc.b	"C3:B:Jump with Fire 2;"
	dc.b	"C1:X:Unlimited Lives:0;"
	dc.b	"C1:X:Unlimited Time:1;"
	dc.b	"C1:X:Invincibility:2;"
	dc.b	"C1:X:Unlimited Shields:3;"
	dc.b	"C1:X:Unlimited Bombs:4;"
	dc.b	"C1:X:Maximum Shots:5;"
	dc.b	"C1:X:In-Game Keys:6;"
	dc.b	"C2:L:Start at Level:1,2,3,4,5,6,7,8,9,"
	dc.b	"10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25"
	dc.b	0

	

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/HardNHeavy",0
	ENDC

.name		DC.B	"Hard'n'Heavy",0
.copy		DC.B	'1989 Reline',0
.info		DC.B	'V1.03 by Harry & StingRay (13.04.2023)',0
HighName	dc.b	'hnhhigh',0
	CNOP	0,4

TAGLIST		dc.l	WHDLTAG_BUTTONWAIT_GET
BUTTONWAIT	dc.l	0

		dc.l	WHDLTAG_CUSTOM1_GET
TRAINEROPTIONS	dc.l	0

		dc.l	WHDLTAG_CUSTOM2_GET
STARTLEVEL	dc.l	0
		dc.l	TAG_DONE

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	move.l	#1,d0
	move.l	d0,d1
	jsr	resload_SetCACR(a2)

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


; copy WHDLoad's default copperlist at $1000.w to $300.w
	lea	$300.w,a0
	move.l	$1000.w,(a0)
	move.l	a0,$dff080

	lea	$7D000,sp
	move.l	#0,d0
	move.l	#$960,d1
	move.l	d1,d5
	lea	$400.W,a0
	moveq	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)

	lea	$400.w,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$92bb,d0		; SPS 1631
	beq.b	.ok
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok	move.w	#$8040,$DFF096		; enable blitter DMA

	lea	PLBOOT(pc),a0
	lea	$400.w,a1
	jsr	resload_Patch(a2)

	jmp	$400.w

PLBOOT	PL_START
	PL_P	$11e,Loader
	PL_P	$1ac,SaveHighscores
	PL_PS	$b4,DoButtonWait
	PL_W	$ba,$602c
	PL_P	$118,PatchGame
	PL_P	$bc,CheckKey
	PL_END
	

PatchGame
	lea	PLGAME(pc),a0
	lea	$5000.w,a1

; install trainers
	move.l	TRAINEROPTIONS(pc),d0

; unlimited lives
	lsr.l	#1,d0
	bcc.b	.noLivesTrainer
	bsr	ToggleLives
.noLivesTrainer

; unlimited time
	lsr.l	#1,d0
	bcc.b	.noTimeTrainer
	bsr	ToggleTime
.noTimeTrainer

; invincibility
	lsr.l	#1,d0
	bcc.b	.noInvTrainer
	bsr	ToggleInv
.noInvTrainer

; unlimited shields
	lsr.l	#1,d0
	bcc.b	.noShieldTrainer
	eor.b	#$19,$5000+$12c4.w
.noShieldTrainer

; unlimited bombs
	lsr.l	#1,d0
	bcc.b	.noBombTrainer
	eor.b	#$19,$5000+$121e.w
.noBombTrainer

; maximum shots
	lsr.l	#1,d0
	bcc.b	.noShotsTrainer
	move.w	#3,$5000+$2ac+2.w
.noShotsTrainer


	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	jmp	$5000.W


ToggleLives
	eor.b	#1,$5000+$4294+1
	rts
	
ToggleTime
	eor.b	#1,$5000+$1d4a+1
	rts

ToggleInv
	not.b	$5000+$12fc
	not.b	$5000+$6a82
	not.w	$5000+$130e

	eor.b	#$07,$5000+$131c
	rts


PLGAME	PL_START
	PL_R	$1152		; disable checksum calculation
	PL_L	$18,$4e714e71	; disable checksum check

	PL_P	$920,.ackVBI
	PL_PS	$5806,.wblit1

	PL_PSS	$322,.setstage,2+6

	PL_PS	$7e26,.fix	; fix timing (high-score/credits)

	PL_PSS	$8396,Delay,2
	PL_L	$910,$4EB804BC	; jsr $4bc.w -> jsr CheckKey

	PL_IFC3
	PL_PSS	$0,.Initialise_POTGO,2
	PL_PS	$5c02,.Read_Joystick
	PL_ENDIF
	PL_END

.Initialise_POTGO
	move.w	#$7fff,$dff09a	; original code
	move.w	#$ff00,$dff034
	rts

.Read_Joystick
	move.w	$dff00c,d0
	and.w	#~(1<<8),d0	; disable joystick "up" direction
	btst	#14,$dff016
	bne.b	.Fire2_Not_Pressed
	bset	#8,d0
.Fire2_Not_Pressed
	rts


.fix	move.w	d0,-(a7)
	move.b	$dff006,d0
.waitLine
	cmp.b	$dff006,d0
	beq.b	.waitLine
	move.w	(a7)+,d0

	tst.b	$5000+$6ed0	; "fire pressed" flag
	rts


.setstage
	move.l	STARTLEVEL(pc),d0
	move.w	d0,$5000+$67f8

	addq.w	#1,d0	
; convert to BCD
	divu.w	#10,d0
	move.w	d0,d1
	swap	d0
	lsl.w	#4,d1
	or.w	d1,d0

	move.b	d0,$5000+$6eb2
	rts

.ackVBI	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rte

.wblit1	lea	$dff000,a6
WaitBlit
	tst.b	$02(a6)
.wblit	btst	#6,$02(a6)
	bne.b	.wblit
	rts


Delay	move.w	#12500,d0
.loop
	move.w	d0,-(a7)
	move.b	$DFF006,d0
.wait	cmp.b	$DFF006,d0
	beq.b	.wait
	move.w	(a7)+,d0
	dbf	d0,.loop
	rts

DoButtonWait
	move.l	BUTTONWAIT(pc),d0
	beq.b	.nowait
	moveq	#5*10,d0
	move.l	resload(pc),a0
	jsr	resload_Delay(a0)
.nowait	rts

Loader	movem.l	d0-a6,-(a7)
	move.l	d0,d5
	lsl.l	#3,d5
	lea	$A9C.W,a3
	moveq	#0,d3
	move.b	4(a3,d5.w),d3
	cmp.w	#78,d3
	bhs.w	.error
	add.b	d3,d3
	add.b	5(a3,d5.w),d3
	cmp.w	#$9B,d3
	bne.b	.no_highscore

	move.w	#$87,d3
	lea	HighName(pc),a0
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	bne.b	.loadhi

.no_highscore
	subq.w	#1,d3
	mulu	#$1400,d3
	moveq	#0,d4
	move.w	6(a3,d5.w),d4
	add.l	d4,d3
	move.l	d3,d0
	move.l	(a3,d5.w),d1
	move.l	a4,a0
	moveq	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)

	cmp.l	#$23410002,$6D3E8
	bne.b	.no1
	move.l	#$22414ED1,$6D3E8
.no1	cmp.l	#$23400002,$6D5DA
	bne.b	.no2
	move.l	#$22404ED1,$6D5DA
.no2	cmp.l	#$21410002,$6D88E
	bne.b	.no3
	move.l	#$20414ED0,$6D88E
.no3	movem.l	(a7)+,d0-a6
	rts

.loadhi	move.l	a4,a1
	lea	HighName(pc),a0
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)
	movem.l	(a7)+,d0-a6
	rts

.error	illegal

SaveHighscores
	movem.l	d0-a6,-(a7)
	move.l	TRAINEROPTIONS(pc),d0
	add.l	STARTLEVEL(pc),d0
	bne.b	.nosave

	move.l	#$B4,d0
	move.l	a4,a1
	lea	HighName(pc),a0
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)

.nosave	movem.l	(a7)+,d0-a6
	rts



CheckKey
	moveq	#4-1,d0
.loop	move.w	d0,-(a7)
	move.b	$DFF006,d0
.wait	cmp.b	$DFF006,d0
	beq.b	.wait
	move.w	(a7)+,d0
	dbf	d0,.loop

	move.b	$50D0.w,d0
	not.b	d0
	ror.b	#1,d0
	
	move.l	TRAINEROPTIONS(pc),d1
	btst	#6,d1
	beq.b	.out

	cmp.b	#$36,d0		; N - skip level
	bne.b	.noN

	move.w	#2020,$5000+$67a0
	st	$5000+$6eaa
.noN

	cmp.b	#$17,d0		; I - toggle invincibility
	bne.b	.noI
	bsr	ToggleInv
.noI

	cmp.b	#$14,d0		; T - toggle unlimited time
	bne.b	.noT
	bsr	ToggleTime
.noT

	cmp.b	#$28,d0		; L - toggle unlimited lives
	bne.b	.noL
	bsr	ToggleLives
.noL

.out	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	QUIT
	rts

QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),-(a7)
	addq.l	#4,(a7)
	rts

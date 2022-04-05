; V1.2, StingRay

; 05.04.2022	- tried to make climb/dive work with the new approach,
;		  no success yet (and no big deal either)
;		- this update is finished for now

; 04.04.2022	- using my new approach to handle CD32 joypad buttons

; 30.01.2022	- default quitkey changed to Del, F10 is used in the game
;		- WHDLoad v17+ features used (config, splash screen)
;		- CD32 controls can be enabled with CUSTOM2
;		- map screen can be toggled with CD32 "PLAY" button
;		- initiate landing mapped to "PLAY" + "REVERSE
;		- abort landing mapped to "PLAY" + "FORWARD"
;		- this version has been attached to mantis ticket #4833 for
;		  testing, waiting for test results before resuming work
;		  on this update

; 29.01.2022	- dropping bombs with blue button works fine now
;		- weapons and bombs can be switched with yellow/green button
;		- dive/climb with FORWARD/REVERSE button

; 28.01.2022	- more CD32 pad stuff

; 27.01.2022	- other approach for CD32 pad support tried

; 25.01.2022	- CD32 pad support continued, not happy yet

; 24.01.2022	- CD32 pad support continued, blue button: drop bomb

; 23.01.2022	- CD32 pad support started

; 18.01.2022	- source is 100% pc relative now
;		- byte write to volume register fixed
;		- interrupts fixed for 68040/060

		INCDIR	SOURCES:Include/
		INCLUDE	whdload.i

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap|WHDLF_NoDivZero
QUITKEY		= $46		; Del
DEBUG


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

RAWKEY_F1	= $50
RAWKEY_F2	= $51
RAWKEY_F3	= $52
RAWKEY_F4	= $53
RAWKEY_F5	= $54
RAWKEY_F6	= $55
RAWKEY_F7	= $56
RAWKEY_F8	= $57
RAWKEY_F9	= $58
RAWKEY_F10	= $59


RAWKEY_SPACE	= $40
RAWKEY_HELP	= $5f

RAWKEY_B_DELAY_RELEASE	= 7

HEADER
_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoDivZero
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	_dir-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	QUITKEY			;ws_keyexit = F10
_expmem		dc.l	$80000
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"BW;"
	dc.b	"C1:B:Unlimited Lives;"
	dc.b	"C2:B:Enable CD32 controls;"
	dc.b	0


_dir		dc.b	"data",0
_name		dc.b	"Operation Harrier",0
_copy		dc.b	"1990 US Gold",0
_info		dc.b	"installed & fixed by Bored Seal & StingRay",10
		dc.b	"V1.2 (05-Apr-2022)",0
		even

_Start		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later using
		move.l	a0,a2
                lea     (_tags,pc),a0
                jsr     (resload_Control,a2)

	; V1.2
	bsr	_detect_controller_types
	
		lea	filename(pc),a0
		lea	$10000,a1
		move.l	a1,a5
		jsr	(resload_LoadFile,a2)
		move.l	d0,-(sp)

		move.l	a5,a0
                sub.l   a1,a1			;tags
                jsr     (resload_Relocate,a2)

		move.l	(sp)+,d0
		move.l	a5,a0
		jsr     (resload_CRC16,a2)
		cmp.w	#$f0ef,d0
		bne	Unsupported

		suba.l	a0,a0
		move.w	#$4ef9,(a0)+
		pea	Patch(pc)
		move.l	(sp)+,(a0)
		move.l	#$4ef80000,$60(a5)

		jmp	(a5)



Patch		move.w	#$4e75,$1a8c.w		;access fault
		move.w	#$4e75,$bf1e		;manual protection
;		move.w	#$6018,$231e.w		;set for 512kb usage

		move.l	_expmem(pc),$22f0.w	;use fast RAM
		move.w	#$6014,$22f4.w

		move.w	#$4ef9,d0
		move.w	d0,$fe6a
		pea	LoadFile(pc)
		move.l	(sp)+,$fe6c

		move.w	d0,$d17c		;fix 24bit access faults
		pea	Fix1(pc)
		move.l	(sp)+,$d17e

		move.w	d0,$d182
		pea	Fix2(pc)
		move.l	(sp)+,$d184

		move.w	d0,$fdb8
		pea	Decrunch(pc)
		move.l	(sp)+,$fdba

		lea	$12000,a0
		move.w	d0,$100.w
		pea	SnoopFix(pc)
		move.l	(sp)+,$102.w
		move.l	#$4eb80100,d0
		move.l	d0,$e74(a0)
		move.l	d0,$1054(a0)

		pea	ButtonWait(pc)
		move.l	(sp)+,$246a.w

		move.l	#$4e714eb9,d0
		move.l	d0,$d51e
		move.l	d0,$f4c(a0)
		move.l	d0,$14b4(a0)
		move.l	d0,$14cc(a0)
		pea	BeamDelay(pc)
		move.l	(sp),$d522		; $c3a2
		move.l	(sp),$f50(a0)		; $11dd0
		move.l	(sp),$14b8(a0)		; $12338
		move.l	(sp)+,$14d0(a0)		; $12350

		move.l	d0,$c3bc
		pea	SaveHi(pc)
		move.l	(sp)+,$c3c0

		lea	trainer(pc),a0		;unlimited lives
		tst.l	(a0)
		beq	NoTrainer
		move.w	#$6004,$2a6c.w
NoTrainer	bsr	LoadHi



	; V1.2
	lea	PLGAME(pc),a0
	lea	$1200-$80,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

		jmp	4(a6)


PLGAME	PL_START
	PL_P	$1261e,.FixAudXVol
	PL_P	$c29c,.AckVBI
	PL_PS	$bf9c,.AckLev2
	PL_PSS	$c3bc,.FixDMAWait,2


	PL_IFC2
	PL_PS	$c292,.CD32_Controls

	PL_P	$5d7c,.Init_Landing
	PL_PS	$1d28,.Abort_Landing	
	PL_PS	$5e96,.Dive_or_Climb
	PL_ENDIF
	PL_END



; -------------------------------------------------------------------------
; Initiate landing mode with CD32 "PLAY" + "REVERSE" buttons

.Init_Landing
	tst.b	$4c(a0)
	beq.b	.Key_L_Pressed

	move.l	joy1(pc),d1
	btst	#JPB_BTN_PLAY,d1
	beq.b	.no_L_key
	btst	#JPB_BTN_REVERSE,d1
	bne.b	.Key_L_Pressed


.no_L_key
	jmp	$1200-$80+$5d84.w


.Key_L_Pressed
	moveq	#0,d0
	rts


; -------------------------------------------------------------------------
; Abort landing mode with CD32 "PLAY" + "FORWARD" buttons

.Abort_Landing
	tst.b	$1200-$80+$c583
	beq.b	.Key_A_pressed

	move.l	joy1(pc),d1
	btst	#JPB_BTN_PLAY,d1
	beq.b	.no_A_Key
	btst	#JPB_BTN_FORWARD,d1
	seq	d1
	tst.b	d1
	rts

.no_A_Key
	moveq	#1,d1
	

.Key_A_pressed
	rts


; ---------------------------------------------------------------------------

; fire + joystick up: dive	-> CD32 FORWARD button
; fire + joystick down: climb	-> CD32 REVERSE button
.Dive_or_Climb
	move.l	joy1(pc),d1

	btst	#JPB_BTN_REVERSE,d1
	bne.b	.set_climb
	btst	#JPB_BTN_FORWARD,d1
	bne.b	.set_dive

.exit	cmp.w	#4,$2e0.w	; check if fire has been pressed long enough
	rts

.set_dive
	bset	#0,d0		; set joy direction to up
	bra.b	.set

.set_climb
	bset	#1,d0		; set joy direction to down
.set	move.w	#4,$2e0.w
	bra.b	.exit


.FixDMAWait
	move.l	d1,-(a7)
	move.w	#999/$34-1,d0
.loop	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait
	dbf	d0,.loop
	move.l	(a7)+,d1
	rts	

.FixAudXVol
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts

.AckVBI	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rte

.AckLev2
	move.w	#1<<3,$9c(a6)
	move.w	#1<<3,$9c(a6)
	rts	

; Routine is called each vertical blank interrupt
.CD32_Controls
	bsr	_joystick		; read CD32 pad
	bsr	Handle_CD32_Buttons

	jmp	($1200-$80)+$bde0	; call original VBI routine


LoadHi		movem.l	d0-d7/a0-a6,-(sp)
		bsr.b	Params
                jsr     (resload_GetFileSize,a2)
                tst.l   d0
                beq.b 	NoHisc
		bsr.b	Params
		jsr	(resload_LoadFile,a2)
NoHisc		movem.l	(sp)+,d0-d7/a0-a6
		rts

Params		lea	hiscore(pc),a0
		lea	$c7ba,a1
		move.l	(_resload,pc),a2
		rts

SaveHi		jsr	$c5b0
		jsr	$c4d2
		movem.l	d0-d7/a0-a6,-(sp)
		bsr.b	Params
		move.l	#$1be,d0
		jsr	(resload_SaveFile,a2)
		movem.l	(sp)+,d0-d7/a0-a6
		rts

BeamDelay	move.l  d0,-(sp)
		moveq	#5,d0
BM_1		move.w  d0,-(sp)
		move.b	$dff006,d0	; VPOS
BM_2		cmp.b	$dff006,d0
		beq.b	BM_2
		move.w	(sp)+,d0
		dbf	d0,BM_1
End		move.l	(sp)+,d0
		rts

ButtonWait	jsr	$d30c
		movem.l	d0-d7/a0-a6,-(sp)
		lea	button(pc),a0
		tst.l	(a0)
		beq.b	ButtonPressed
		lea	$bfe001,a0
test		btst	#6,(a0)
		beq.b	ButtonPressed
		btst	#7,(a0)
		bne.b	test
ButtonPressed	movem.l	(sp)+,d0-d7/a0-a6
		rts

Fix1		bsr.b	And_A0
		bset	d2,(a0,d1.w)
		rts

Fix2		bsr.b	And_A0
		bclr	d2,(a0,d1.w)
		rts

And_A0		move.l	d0,-(sp)
		move.l	a0,d0
		and.l	#$0000FFFF,d0
		move.l	d0,a0
		move.l	(sp)+,d0
		rts

SnoopFix	ext.w	d0			;write word instead byte
		move.w	d0,8(a5)
		rts

LoadFile	movem.l a0-a2/d1,-(sp)
		move.l	$10450,a0
		move.l	$10454,a1
		move.l	(_resload,pc),a2
		jsr	(resload_LoadFile,a2)
		movem.l	(sp)+,a0-a2/d1
		moveq	#0,d0
		rts

Unsupported	pea	(TDREASON_WRONGVER).w
_end		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

Decrunch	MOVEA.L	D0,A6
		ADDQ.L	#4,A6
		LEA	($200,A6),A5
		LEA	($200,A5),A4
		MOVEQ	#1,D6
		MOVE.W	($1FE,A6),D4
		MOVEQ	#$1F,D7
		MOVEQ	#7,D3
		BRA.B	lab21

lab0		MOVE.W	D4,D5
lab02		LSR.L	#1,D6
		BCC.B	lab11
		BEQ.B	lab1
lab01		MOVE.W	(A5,D5.W),D5
		BMI.B	return
		LSR.L	#1,D6
		BCC.B	lab11
		BEQ.B	lab1
		MOVE.W	(A5,D5.W),D5
		BPL.B	lab02
		RTS

lab1		MOVE.L	(A4)+,D6
		LSR.L	#1,D6
		BSET	D7,D6
		BCS.B	lab01
lab11		MOVE.W	(A6,D5.W),D5
		BMI.B	return
		LSR.L	#1,D6
		BCC.B	lab11
		BEQ.B	lab1
		MOVE.W	(A5,D5.W),D5
		BPL.B	lab02
return		RTS

lab21		MOVEQ	#0,D1
		BSR.B	lab0
		TST.B	D5
		BEQ.B	return
		MOVE.B	D5,D1
		BPL.B	lab3
		BCLR	D3,D1
		SUBQ.B	#1,D1
		BSR.B	lab0
lab22		MOVE.B	D5,(A3)+
		DBRA	D1,lab22
		BRA.B	lab21

lab3		SUBQ.B	#1,D1
lab31		MOVE.W	D4,D5
lab32		LSR.L	#1,D6
		BCC.B	lab41
		BEQ.B	lab4
llab33		MOVE.W	(A5,D5.W),D5
		BMI.B	lab42
		LSR.L	#1,D6
		BCC.B	lab41
		BEQ.B	lab4
		MOVE.W	(A5,D5.W),D5
		BPL.B	lab32
		MOVE.B	D5,(A3)+
		DBRA	D1,lab31
		BRA.B	lab21

lab4		MOVE.L	(A4)+,D6
		LSR.L	#1,D6
		BSET	D7,D6
		BCS.B	llab33
lab41		MOVE.W	(A6,D5.W),D5
		BMI.B	lab42
		LSR.L	#1,D6
		BCC.B	lab41
		BEQ.B	lab4
		MOVE.W	(A5,D5.W),D5
		BPL.B	lab32
lab42		MOVE.B	D5,(A3)+
		DBRA	D1,lab31
		BRA.B	lab21

_resload	dc.l	0
_tags		dc.l	WHDLTAG_BUTTONWAIT_GET
button		dc.l    0
		dc.l	WHDLTAG_CUSTOM1_GET
trainer		dc.l    0,0
filename	dc.b	"loader",0
hiscore		dc.b	"highs",0


	CNOP	0,2


; --------------------------------------------------------------------------
; CD32 controls

Button_Table
	dc.l	JPB_BTN_PLAY,RAWKEY_M		; toggle map
	dc.l	JPB_BTN_GRN,RAWKEY_F1		; switch weapons
	dc.l	JPB_BTN_YEL,RAWKEY_F2		; switch bombs
	dc.l	JPB_BTN_BLU,RAWKEY_SPACE	; drop bomb
	dc.l	0


Handle_CD32_Buttons
	lea	Button_Table(pc),a0
	lea	joy1(pc),a1
	lea	Last_Joypad1_State(pc),a2

.Process_Buttons
	move.l	(a1),d0			; current joypad state
	move.l	(a2),d1			; previous joy state
	move.l	d0,(a2)	

	bsr.b	Handle_CD32_Button_Press
	bra.b	Handle_CD32_Button_Release


Last_Joypad1_State	dc.l	0
Release_Delay_Flag	dc.b	0
			dc.b	0

; d0.l: rawkey
Set_Key	move.l	d0,-(a7)
	lea	($1200-$80)+$c022,a0
	jsr	($1200-$80)+$bfb0
	move.l	(a7)+,d0
	btst	#7,d0
	bne.b	.exit
	jsr	($1200-$80)+$c00e
.exit	rts


; a0.l: table with buttons to check
; d0.l: current joypad state
; d1.l: previous joypad state

Handle_CD32_Button_Press
	movem.l	d0-a6,-(a7)
.loop	movem.l	(a0)+,d2/d3
	btst	d2,d0
	beq.b	.check_next_button

	bclr	#RAWKEY_B_DELAY_RELEASE,d3
	lea	Release_Delay_Flag(pc),a1
	seq	(a1)

	; button pressed
	movem.l	d0-a6,-(a7)
	move.l	d3,d0
	bsr	Set_Key
	movem.l	(a7)+,d0-a6

.check_next_button
	tst.l	(a0)
	bne.b	.loop
	movem.l	(a7)+,d0-a6
	rts

; a0.l: table with buttons to check
; d0.l: current joypad state
; d1.l: previous joypad state

Handle_CD32_Button_Release
	movem.l	d0-a6,-(a7)
.loop	movem.l	(a0)+,d2/d3
	btst	d2,d0
	bne.b	.button_is_currently_pressed
	btst	d2,d1
	beq.b	.check_next_button

	lea	Release_Delay_Flag(pc),a1
	tst.b	(a1)
	sf	(a1)
	beq	.check_next_button

	; button released
	movem.l	d0-a6,-(a7)
	move.l	d3,d0
	or.b	#1<<7,d0
	bsr	Set_Key
	movem.l	(a7)+,d0-a6

.button_is_currently_pressed

.check_next_button
	tst.l	(a0)
	bne.b	.loop
	movem.l	(a7)+,d0-a6
	rts


; ---------------------------------------------------------------------------








; offset: $8fce (weapons/fuel)
; $2a0.b: fuel
; $278.w: 500 LB bombs
; $27a.w: 1000 LB bombs
; $27c.w: heatseekers
; $27e.w: rockets
; $288.w: weapon type (machine gun / rockets / heatseeker)
; $28a.w: bomb type (500 LB / 1000 LB)


;==========================================================================
; read current state of joystick & joypad
;
; original code by asman with timing fix by wepl
; "getting joypad keys (cd32)"
; http://eab.abime.net/showthread.php?t=29768
;
; adapted to single read of both joysticks thanks to Girv
;
; added detection of joystick/joypad by JOTD, thanks to EAB thread:
; http://eab.abime.net/showthread.php?p=1175551#post1175551
;
; > d0.l = port number (0,1)
;
; < d0.l = state bits set as follows
;        JPB_JOY_R	= $00
;        JPB_JOY_L 	= $01
;        JPB_JOY_D	= $02
;        JPB_JOY_U	= $03
;        JPB_BTN_PLAY	= $11
;        JPB_BTN_REVERSE	= $12
;        JPB_BTN_FORWARD	= $13
;        JPB_BTN_GRN	= $14
;        JPB_BTN_YEL	= $15
;        JPB_BTN_RED	= $16
;        JPB_BTN_BLU	= $17
; < d1.l = raw joy[01]dat value read from input port
;

	IFND	EXEC_TYPES_I
	INCLUDE	exec/types.i
	ENDC
	INCLUDE	hardware/cia.i
	INCLUDE	hardware/custom.i

	BITDEF	JP,BTN_RIGHT,0
	BITDEF	JP,BTN_LEFT,1
	BITDEF	JP,BTN_DOWN,2
	BITDEF	JP,BTN_UP,3
	BITDEF	JP,BTN_PLAY,$11
	BITDEF	JP,BTN_REVERSE,$12
	BITDEF	JP,BTN_FORWARD,$13
	BITDEF	JP,BTN_GRN,$14
	BITDEF	JP,BTN_YEL,$15
	BITDEF	JP,BTN_RED,$16
	BITDEF	JP,BTN_BLU,$17

POTGO_RESET = $FF00  	; was $FFFF but changed, thanks to robinsonb5@eab

	XDEF	_detect_controller_types
	XDEF	_read_joystick

; optional call to differentiate 2-button joystick from CD32 joypad
; default is "all joypads", but when using 2-button joystick second button,
; the problem is that all bits are set (which explains that pressing 2nd button usually
; triggers pause and/or both shoulder buttons => quit game)
;
; drawback:
; once detected, changing controller type needs game restart
;
; advantage:
; less CPU time consumed while trying to read ghost buttons
;
_detect_controller_types:
    movem.l d0/a0,-(a7)
	moveq	#0,d0
	bsr.b		.detect
	; ignore first read
	bsr	.wvbl
	moveq	#0,d0
	bsr.b		.detect
	
	lea	controller_joypad_0(pc),a0
	move.b	D0,(A0)
	
	bsr.b	.wvbl
	
	moveq	#1,d0
	bsr.b		.detect
	lea	controller_joypad_1(pc),a0
	move.b	D0,(A0)
    movem.l (a7)+,d0/a0
	rts

.wvbl:
	; wait for VBL
	lea	$DFF000,a0
	move.w	#$7FFF,intreq(a0)
.wait
	move.w	intreqr(a0),d0
	btst	#5,d0
	beq.b	.wait
	rts
.detect
		movem.l	d1-d5/a0-a1,-(a7)
	
		tst.l	d0
		bne.b	.port1

		moveq	#CIAB_GAMEPORT0,d3	; red button ( port 0 )
		moveq	#10,d4			; blue button ( port 0 )
		move.w	#$f600,d5		; for potgo port 0
		bra.b	.buttons
.port1
		moveq	#CIAB_GAMEPORT1,d3	; red button ( port 1 )
		moveq	#14,d4			; blue button ( port 1 )
		move.w	#$6f00,d5		; for potgo port 1

.buttons
		lea	$DFF000,a0
		lea	$BFE001,a1
		
		bset	d3,ciaddra(a1)	;set bit to out at ciapra
		bclr	d3,ciapra(a1)	;clr bit to in at ciapra

		move.w	d5,potgo(a0)

		moveq	#0,d0
		moveq	#10-1,d1	; read 9 times instead of 7. Only 2 last reads interest us
		bra.b	.gamecont4

.gamecont3	tst.b	ciapra(a1)
		tst.b	ciapra(a1)
.gamecont4	tst.b	ciapra(a1)	; wepl timing fix
		tst.b	ciapra(a1)
		tst.b	ciapra(a1)
		tst.b	ciapra(a1)
		tst.b	ciapra(a1)
		tst.b	ciapra(a1)

		move.w	potinp(a0),d2

		bset	d3,ciapra(a1)
		bclr	d3,ciapra(a1)
	
		btst	d4,d2
		bne.b	.gamecont5

		bset	d1,d0

.gamecont5	dbf	d1,.gamecont3

		bclr	d3,ciaddra(a1)		;set bit to in at ciapra
		move.w	#POTGO_RESET,potgo(a0)	;changed from ffff to ff00, according to robinsonb5@eab
		
		or.b	#$C0,ciapra(a1)	;reset port direction

		; test only last bits
		and.w	#03,D0
		
		movem.l	(a7)+,d1-d5/a0-a1
		rts
		
_joystick:

		movem.l	a0,-(a7)	; put input 0 output in joy0
	moveq	#0,d0
	bsr	_read_joystick

		lea	joy0(pc),a0
		move.l	d0,(a0)		

	moveq	#1,d0
	bsr	_read_joystick

		lea	joy1(pc),a0
		move.l	d0,(a0)		
	
		movem.l	(a7)+,a0

	rts	

_read_joystick:
    IFD    IGNORE_JOY_DIRECTIONS        
		movem.l	d1-d7/a0-a1,-(a7)
    ELSE
		movem.l	d2-d7/a0-a1,-(a7)
    ENDC
	
		tst.l	d0
		bne.b	.port1

		moveq	#CIAB_GAMEPORT0,d3	; red button ( port 0 )
		moveq	#10,d4			; blue button ( port 0 )
		move.w	#$f600,d5		; for potgo port 0
		moveq	#joy0dat,d6		; port 0
		move.b	controller_joypad_0(pc),d2
		bra.b	.direction
.port1
		moveq	#CIAB_GAMEPORT1,d3	; red button ( port 1 )
		moveq	#14,d4			; blue button ( port 1 )
		move.w	#$6f00,d5		; for potgo port 1
		moveq	#joy1dat,d6		; port 1
		move.b	controller_joypad_1(pc),d2

.direction
		lea	$DFF000,a0
		lea	$BFE001,a1

		moveq	#0,d7

    IFND    IGNORE_JOY_DIRECTIONS
		move.w	0(a0,d6.w),d0		;get joystick direction
		move.w	d0,d6

		move.w	d0,d1
		lsr.w	#1,d1
		eor.w	d0,d1

		btst	#8,d1	;check joystick up
		sne	d7
		add.w	d7,d7

		btst	#0,d1	;check joystick down
		sne	d7
		add.w	d7,d7

		btst	#9,d0	;check joystick left
		sne	d7
		add.w	d7,d7

		btst	#1,d0	;check joystick right
		sne	d7
		add.w	d7,d7

		swap	d7
	ENDC
    
	;two/three buttons

		btst	d4,potinp(a0)	;check button blue (normal fire2)
		seq	d7
		add.w	d7,d7

		btst	d3,ciapra(a1)	;check button red (normal fire1)
		seq	d7
		add.w	d7,d7

		and.w	#$0300,d7	;calculate right out for
		asr.l	#2,d7		;above two buttons
		swap	d7		;like from lowlevel
		asr.w	#6,d7

	; read buttons from CD32 pad only if CD32 pad detected

		moveq	#0,d0
		tst.b	d2
		beq.b	.read_third_button
		
		bset	d3,ciaddra(a1)	;set bit to out at ciapra
		bclr	d3,ciapra(a1)	;clr bit to in at ciapra

		move.w	d5,potgo(a0)

		moveq	#8-1,d1
		bra.b	.gamecont4

.gamecont3	tst.b	ciapra(a1)
		tst.b	ciapra(a1)
.gamecont4	tst.b	ciapra(a1)	; wepl timing fix
		tst.b	ciapra(a1)
		tst.b	ciapra(a1)
		tst.b	ciapra(a1)
		tst.b	ciapra(a1)
		tst.b	ciapra(a1)

		move.w	potinp(a0),d2

		bset	d3,ciapra(a1)
		bclr	d3,ciapra(a1)
	
		btst	d4,d2
		bne.b	.gamecont5

		bset	d1,d0

.gamecont5	dbf	d1,.gamecont3

		bclr	d3,ciaddra(a1)		;set bit to in at ciapra
.no_further_button_test
		move.w	#POTGO_RESET,potgo(a0)	;changed from ffff, according to robinsonb5@eab


		swap	d0		; d0 = state
		or.l	d7,d0

    IFND    IGNORE_JOY_DIRECTIONS        
		moveq	#0,d1		; d1 = raw joydat
		move.w	d6,d1
	ENDC
    
		or.b	#$C0,ciapra(a1)	;reset port direction

    IFD    IGNORE_JOY_DIRECTIONS        
		movem.l	(a7)+,d1-d7/a0-a1
    ELSE
		movem.l	(a7)+,d2-d7/a0-a1
    ENDC
		rts
.read_third_button
        subq.l  #2,d4   ; shift from DAT*Y to DAT*X
        btst	d4,potinp(a0)	;check third button
        bne.b   .no_further_button_test
        or.l    third_button_maps_to(pc),d7
        bra.b    .no_further_button_test
       
;==========================================================================

;==========================================================================

joy0		dc.l	0		
joy1		dc.l	0
third_button_maps_to:
    dc.l    JPF_BTN_PLAY
controller_joypad_0:
	dc.b	$FF	; set: joystick 0 is a joypad, else joystick
controller_joypad_1:
	dc.b	$FF
	

;*---------------------------------------------------------------------------
;  :Program.	LastNinja3.asm
;  :Contents.	Slave for "Last Ninja 3" from System 3
;  :Author.	Mr.Larmer of Wanted Team, StingRay/[S]carab^Scoopex
;  :History.	20.11.98
;		25.07.2016: - trainer code to enable built-in cheat removed
;		(StingRay)  - version check added
;			    - 68000 compatibility
;			    - code optimised
;			    - WHDLoad v17+ features used
;
;		26.07.2016: - lots of trainer options added
;			    - sound problems fixed (DMA wait)
;			    - keyboard routine fixed, 68000 quitkey support
;			    - ByteKiller decruncher relocated
;			    - interrupts fixed
;			    - intro can be skipped with CUSTOM2
;			    - blitter wait patches disabled on 68000
;			    - game bug fixed (z-pos > 0 - key "r" to reset pos)
;			    - high score load/save added
;			    - delay for System 3 logo added
;
;		27.07.2016: - level skip improved, end sequence is shown now
;			      after skipping level 6
;			    - some more in-game keys added
;			    - much better approach for the options to defeat
;			      resp. kill the enemy with one hit
;			    - joypad support added (can be disabled with
;			      CUSTOM3), fire 2/blue: pick up object, green:
;			      select object
;
;		04.04.2022  - level code can be entered with CD32 joypad
;			      buttons (REVERSE/FORWARD), issue #4600
;			    - latest joypad reading code used

;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Asm-Pro 1.16d
;  :To Do.
;---------------------------------------------------------------------------*

	incdir	SOURCES:include/
	include	whdload.i

;DEBUG

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

RAWKEY_SPACE	= $40
RAWKEY_HELP	= $5f

RAWKEY_B_DELAY_RELEASE	= 7

;======================================================================

HEADER
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$80000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-HEADER	;ws_GameLoader
		IFD	DEBUG
		dc.w	.dir-HEADER	;ws_CurrentDir
		ELSE
		dc.w	0		; ws_CurrentDir
		ENDC
		dc.w	0		;ws_DontCache
		dc.b	0		;ws_keydebug = F9
		dc.b	$59		;ws_keyexit = F10
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

.config	dc.b	"C2:B:Skip Intro;"
	dc.b	"C3:B:Disable Joypad Support;"
	dc.b	"C1:X:Unlimited Lives:0;"
	dc.b	"C1:X:Unlimited Energy:1;"
	dc.b	"C1:X:Start with all Weapons:2;"
	dc.b	"C1:X:Unlimited Shiraken:3;"
	dc.b	"C1:X:One hit to knock down enemies:4;"
	dc.b	"C1:X:Enemies die after one hit:5;"
	dc.b	"C1:X:Start with max. Bushido (Green Dragon):6;"
	dc.b	"C1:X:In-Game Keys:7"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/LastNinja3",0
	ENDC

.name	dc.b	"Last Ninja 3",0
.copy	dc.b	"1991 System 3",0
.info	dc.b	"installed by Mr.Larmer/Wanted Team & StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.1A (04.04.2022)",0

HighName	dc.b	"LastNinja3.high",0
	CNOP	0,4

TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
TRAINEROPTIONS	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
SKIPINTRO	dc.l	0

		dc.l	WHDLTAG_CUSTOM3_GET
NOJOYPAD	dc.l	0

		dc.l	TAG_DONE

	;include	ReadJoypad.s

;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	resload(pc),a1
		move.l	a0,(a1)			;save for later use

	move.l	a0,a2
	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

	; Detect CD32 controller
	bsr	_detect_controller_types

; install keyboard irq
	bsr	SetLev2IRQ


		lea	$40000,A0
		move.l	#$800,D0
		move.l	#$8C00,D1
		moveq	#1,d2
		bsr	LoadDisk

	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$e84e,d0		; SPS 0495
	beq.b	.ok
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT
		
	

.ok		lea	$40000,a0
		pea	mypatch(pc)
		move.l	(A7)+,$A8(A0)

		move.w	#$4EF9,$CE(A0)
		pea	Load(pc)
		move.l	(A7)+,$D0(A0)

		lea	$40A30,A0
		lea	$40(A0),A1
.loop		clr.w	(A0)+			; clear colours in copperlist
		addq.l	#2,A0
		cmp.l	A0,A1
		bne.b	.loop


	lea	AckLev6(pc),a0
	move.l	a0,$78.w


		jmp	$40000


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	jmp	resload_Abort(a2)


mypatch
		move.w	#$4E71,$152.w		; disabled BusError vect etc.
		move.w	#$605E,$CDE.w		; ext mem check

		pea	mypatch1(pc)
		move.l	(A7)+,$4BA8.w

		move.b	#$60,$61CC.w		; skip text with buy ext mem

		move.w	#$4E75,$1AAD0		; drive ?

		move.w	#$4EF9,$1AB08
		pea	ChangeDisk(pc)
		move.l	(A7)+,$1AB0A

		move.w	#$4E75,$1AD3C		; drive ?

		move.w	#$4EF9,$1AD7E
		pea	Load(pc)
		move.l	(A7)+,$1AD80

	move.l	CPUFLAGS(pc),d0
	lsr.l	#1,d0			; 68000?
	bcc.b	.noblit			; -> don't install blitter waits

		move.l	#$4EB800C0,$3966.w	; jsr $c0.w

		move.w	#$4EF9,$C0.w
		pea	WaitBlit2(pc)
		move.l	(A7)+,$C2.w

		move.w	#$4EF9,$C6.w
		pea	WaitBlit3(pc)
		move.l	(A7)+,$C8.w

		move.w	#$4EB9,$86BA
		pea	WaitBlit5(pc)
		move.l	(A7)+,$86BC

		move.w	#$4EF9,$1AD00
		pea	WaitBlit1(pc)
		move.l	(A7)+,$1AD02

		movem.l	D0-D2/A0-A1,-(A7)

		move.l	#$4EB800C6,D0
		lea	Table(pc),A0
		moveq	#((EndTable-Table)/4)-1,D2
.loop		move.l	(A0)+,A1
		move.l	D0,(A1)
		dbf	D2,.loop

		move.w	#$4EB9,D0
		lea	WaitBlit4(pc),A0
		move.l	A0,D1
		lea	Table2(pc),A0
		moveq	#((EndTable2-Table2)/4)-1,D2
.loop2
		move.l	(A0)+,A1
		move.w	D0,(A1)+
		move.l	D1,(A1)
		dbf	D2,.loop2

		movem.l	(A7)+,D0-D2/A0-A1
.noblit


; load high scores
	lea	HighName(pc),a0
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nohighscores
	lea	HighName(pc),a0
	lea	$100+$75c2.w,a1
	jsr	resload_LoadFile(a2)
.nohighscores


; install trainers
	move.l	TRAINEROPTIONS(pc),d0

; unlimited leves
	lsr.l	#1,d0
	bcc.b	.noLivesTrainer
	bsr	ToggleLives
.noLivesTrainer

; unlimited energy
	lsr.l	#1,d0
	bcc.b	.noEnergyTrainer
	bsr	ToggleEnergy
.noEnergyTrainer	

; start with all weapons
	lsr.l	#1,d0
	bcc.b	.noWeaponsTrainer

	pea	.setWeapons(pc)
	move.w	#$4eb9,$100+$215a.w
	move.l	(a7)+,$100+$215a+2.w
.noWeaponsTrainer


; unlimited shiraken
	lsr.l	#1,d0
	bcc.b	.noShirakenTrainer
	eor.w	#1,$100+$108a+2.w
.noShirakenTrainer


; enemies ko after 1 hit
	lsr.l	#1,d0
	bcc.b	.noHitTrainer
	pea	.ko(pc)
	move.w	#$4eb9,$100+$294c.w
	move.l	(a7)+,$100+$294c+2.w
	;move.l	#$4e714e71,$100+$2956.w
.noHitTrainer

; enemies die after 1 hit
	lsr.l	#1,d0
	bcc.b	.noEnemyTrainer
	pea	.die(pc)
	move.w	#$4eb9,$100+$294c.w
	move.l	(a7)+,$100+$294c+2.w

	;move.w	#$4e71,$100+$4378.w
	;move.l	#$4e714e71,$100+$437e.w
.noEnemyTrainer


; start with max. Bushido
	lsr.l	#1,d0
	bcc.b	.noBushidoTrainer
	move.w	#$68,$100+$7b34
	
.noBushidoTrainer

	move.l	SKIPINTRO(pc),d0
	move.w	d0,$100+$6536.w

	lea	PLGAME(pc),a0
	lea	$100.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)


		jmp	$100.w


.ko	move.w	#$ffd2,d1
	rts

.die	bsr.b	.ko
	move.w	#1,$2b73e+$4a+$40
	rts

.setWeapons
.initItems
	move.b	#0,(a1)+
	dbf	d7,.initItems

GetWeapons
	lea	$100+$11e97,a0
	move.b	#5,1(a0)		; shiraken
	move.b	#1,4(a0)		; nunchaku
	move.b	#1,12(a0)		; sword
	move.b	#1,16(a0)		; staff
	rts

AckVBI	move.l	NOJOYPAD(pc),d0
	bne.b	.nopad

	bsr	_joystick
	bsr	Handle_CD32_Buttons
	bsr	Enter_Level_Code

.nopad	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rts



; --------------------------------------------------------------------------
; CD32 controls

RAWKEY_CYCLE	= $4e				; cursor right
RAWKEY_CHAR	= $4c				; cursor up

Button_Table
	dc.l	JPB_BTN_BLU,RAWKEY_P		; pick up object
	dc.l	JPB_BTN_GRN,RAWKEY_SPACE	; change object
	dc.l	JPB_BTN_REVERSE,RAWKEY_CYCLE	; cycle through level code character to change
	dc.l	JPB_BTN_FORWARD,RAWKEY_CHAR	; change level code character
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
.no

	; button pressed
	move.l	d3,d0
	move.w	d0,$100+$8e6a
	movem.l	d0-a6,-(a7)
	jsr	$100+$76b8.w
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
	;bne.b	.button_is_currently_pressed
	btst	d2,d1
	beq.b	.check_next_button

	lea	Release_Delay_Flag(pc),a1
	tst.b	(a1)
	sf	(a1)
	beq	.check_next_button

	; button released
	move.l	d3,d0
	or.b	#1<<7,d0
	move.w	d0,$100+$8e6a
	movem.l	d0-a6,-(a7)
	jsr	$100+$76b8.w
	movem.l	(a7)+,d0-a6


.button_is_currently_pressed

.check_next_button
	tst.l	(a0)
	bne.b	.loop
	movem.l	(a7)+,d0-a6
	rts

; Enter level code with joypad buttons.
Enter_Level_Code
	cmp.w	#RAWKEY_CYCLE,$100+$8e6a
	bne.b	.no_level_code_position_change

	move.w	$100+$75ae.w,d0
	jsr	$100+$73c0.w
.no_level_code_position_change	
	
	cmp.w	#RAWKEY_CHAR,$100+$8e6a
	bne.b	.no_level_code_character
	
	move.b	.Level_Code_Character(pc),d0
	lea	$100+$764e.w,a0		; level code
	move.w	$100+$75ae.w,d1		; index
	move.b	d0,(a0,d1.w)

	move.b	.Level_Code_Character(pc),d0
	addq.b	#1,d0
	cmp.b	#"Z",d0
	ble.b	.Character_OK
	moveq	#"A",d0
.Character_OK
	lea	.Level_Code_Character(pc),a0
	move.b	d0,(a0)
.no_level_code_character
	rts

.Level_Code_Character	dc.b	"A"
			dc.b	0


AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte

PLGAME	PL_START
	PL_PSS	$9d2e,FixDMAWait,2	; fix DMA wait in sample player
	PL_PSS	$9d7c,FixDMAWait,2	; fix DMA wait in sample player
	
	PL_PSS	$72,.setkbd,2
	PL_R	$767c

	PL_PSS	$154,.reset,2		; reset code after using level skipper
	PL_PS	$540,.checkend		; show end if level 6 is skipped

	PL_P	$1b5d8,BK_DECRUNCH	; relocate ByteKiller decruncher
	PL_P	$1bc30,AckLev6
	PL_P	$1bc90,AckLev6
	PL_PSS	$38ee,AckVBI,2
	PL_PSS	$5f68,AckVBI,2
	

	PL_PS	$72c6,.savehigh		; save high scores
	PL_PS	$616c,.delay_logo	; show System 3 logo for at least 3 seconds
	PL_END

.checkend
	lea	Flag(pc),a0		; level skipper used?
	tst.b	(a0)
	bne.b	.showend
	jmp	$100+$980c		; no, call normal code

.showend
	jmp	$100+$6622.w		; yes, show end sequence


.delay_logo
	movem.l	d0/a0,-(a7)
	moveq	#3*10,d0		; show System 3 screen for 3 seconds
	move.l	resload(pc),a0
	jsr	resload_Delay(a0)
	movem.l	(a7)+,d0/a0

	moveq	#2,d0			; optimised original code
	rts


.savehigh
	movem.l	d0-a6,-(a7)

	move.l	TRAINEROPTIONS(pc),d0
	bne.b	.nosave

	lea	HighName(pc),a0
	lea	$100+$75c2.w,a1
	move.l	#$7642-$75c2,d0

; remove crap (cursor) from entered name
	move.w	d0,d1
.fix	cmp.b	#"=",(a1,d1.w)
	beq.b	.rem
	cmp.b	#"<",(a1,d1.w)
	bne.b	.ok
.rem	move.b	#" ",(a1,d1.w)
.ok	subq.w	#1,d1
	bne.b	.fix



	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)

.nosave	movem.l	(a7)+,d0-a6

	clr.b	$100+$75a6.w		; clear "has highscore" flag
	rts


.reset	move.w	#$6400,$100+$150.w
	addq.w	#1,$100+$e6fa
	rts

.setkbd	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts

.kbdcust
	move.b	RawKey(pc),d0

	IFD	DEBUG
	cmp.b	#$22,d0			; D - toggle debug output
	bne.b	.noD
	not.w	$100+$4410.w
.noD
	ENDC

	cmp.b	#$13,d0			; R - reset zpos (fix game bug)
	bne.b	.noR
	clr.w	$2b73e+14
.noR

	tst.b	$100+$75a6.w		; disable keys during highscore entry
	bne.w	.nokeys

; The following check could be optimised using a .b/bmi combination
; as in-game keys are bit 7 in the options. Since there might
; be more options in the future we don't use this though!
	move.l	TRAINEROPTIONS(pc),d1
	btst	#7,d1
	beq.w	.nokeys

	cmp.b	#$36,d0			; N - skip level
	bne.b	.noN
	move.w	#$6002,$100+$150.w	

	lea	Flag(pc),a0
	st	(a0)

.noN

	cmp.b	#$28,d0			; L - toggle unlimited lives
	bne.b	.noL
	bsr	ToggleLives
.noL

	cmp.b	#12,d0			; E - toggle unlimited energy
	bne.b	.noE
	bsr	ToggleEnergy
.noE

	cmp.b	#1,d0			; 1 - add life
	bne.b	.no1
	addq.w	#1,$2b73e+$40
.no1

	cmp.b	#2,d0			; 2 - full energy
	bne.b	.no2
	move.b	#$2e,$2b73e+9
.no2

	cmp.b	#3,d0			; 3 - get all items
	bne.b	.no3
	lea	$100+$11e97,a0
	moveq	#42-1,d7
.get	move.b	#1,(a0)+
	dbf	d7,.get

	bsr	GetWeapons		; -> 5 shiraken stars


.no3


	cmp.b	#$23,d0			; F - freeze enemies
	bne.b	.noF
	not.w	$100+$21ec.w
.noF	

	cmp.b	#$35,d0			; B - full bushido
	bne.b	.noB
	move.w	#$66,$100+$7b34.w
	move.w	#-1,$100+$7b36.w	; refresh display
.noB

	cmp.b	#$11,d0			; W - get all weapons
	bne.b	.noW
	bsr	GetWeapons
.noW


	cmp.b	#$27,d0			; K - kill enemy
	bne.b	.noK
	lea	$2b73e+$4a,a0

	move.w	#$ffd2,d0		; energy
	move.b	d0,9(a0)
	move.w	#1,$40(a0)		; lives


.noK

.nokeys
	jmp	$100+$7666.w


FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d1	
.loop	move.b	$dff006,d0
.wait	cmp.b	$dff006,d0
	beq.b	.wait
	dbf	d1,.loop
	movem.l	(a7)+,d0/d1
	rts

	

ToggleLives
	eor.b	#$19,$100+$3ec.w
	rts

ToggleEnergy
	eor.w	#1,$100+$1bec+2.w
	eor.w	#1,$100+$2b12+2.w
	eor.w	#8,$100+$56b2+2.w
	eor.b	#$d9,$100+$5502.w
	rts

Table
		dc.l	$3EAE,$3ECA,$3EE6,$3F02,$3F1E,$4196,$41B2,$41CE,$41EA
		dc.l	$4206,$76A0,$9536,$958C,$95B2,$95CA,$95E2,$95FA,$9612
		dc.l	$9818,$9834,$9850,$986C,$9886,$98E2,$98FA
EndTable

Table2
		dc.l	$8538,$8556,$8574,$8592,$85B0
EndTable2

;--------------------------------

WaitBlit1
	tst.b	$dff002
.wb	btst	#6,$dff002
	bne.b	.wb
	rts

;--------------------------------

WaitBlit2
		move.w	D1,$58(A0)
		bra.b	WaitBlit1

;--------------------------------

WaitBlit3
		move.w	D6,$58(A6)
		bra.b	WaitBlit1

;--------------------------------

WaitBlit4
		move.w	#$AC3,$58(A6)
		bra.b	WaitBlit1

;--------------------------------

WaitBlit5
		move.w	#$1403,$58(A6)
		bra.b	WaitBlit1

;--------------------------------

mypatch1
		cmp.l	#$487996C1,$2BFB6
		bne.b	.skip
		cmp.l	#$AAFE43FA,$2BFBA
		bne.b	.skip

		move.l	#$96C1AAFE,D0
		move.l	D0,$60.w
		rts
.skip
		jsr	$2BFB6
		rts


ChangeDisk
		move.l	A0,-(A7)
		lea	DiskNr(pc),A0
		moveq	#0,D0
		move.b	$1C(A5),D0
		move.b	D0,(A0)
		addq.b	#1,(A0)
		move.l	(A7)+,A0
		rts

Load
		movem.l	d0-a6,-(A7)

	move.w	d1,d0
	move.w	d2,d1
	mulu.w	#512,d0
	mulu.w	#512,d1
	move.b	DiskNr(pc),d2	
	

		bsr.b	LoadDisk

		movem.l	(A7)+,d0-a6

		moveq	#0,D0
		rts
DiskNr
		dc.b	1
		even

;--------------------------------

resload	dc.l	0		;address of resident loader

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
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
	bra.w	EXIT

.exit	bra.w	QUIT


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine

Flag	dc.b	0			; $ff: level skipper used
	dc.b	0


; Bytekiller decruncher
; resourced and adapted by stingray
;
BK_DECRUNCH
	bsr.b	.decrunch
	tst.l	d5
	beq.b	.ok

; checksum doesn't match, file corrupt
	pea	.ErrTxt(pc)
	pea	(TDREASON_FAILMSG).w
	move.l	resload(pc),a0
	jmp	resload_Abort(a0)


.ok	rts

.ErrTxt	dc.b	"Decrunching failed, file corrupt!",0
	cnop	0,4

.decrunch
	move.l	-(a0),d5
	move.l	-(a0),d0
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
	move.w	#$10,ccr
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
	move.w	#$10,ccr
	roxr.l	#1,d0
.nonew	addx.l	d2,d2
	dbf	d1,.getbit
	rts



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
		
	bset	d3,ciaddra(a1)		; set bit to out at ciapra
	bclr	d3,ciapra(a1)		; clr bit to in at ciapra

	move.w	d5,potgo(a0)

	moveq	#0,d0
	moveq	#10-1,d1		; read 9 times instead of 7. Only 2 last reads interest us
	bra.b	.gamecont4

.gamecont3
	tst.b	ciapra(a1)
	tst.b	ciapra(a1)
.gamecont4
	tst.b	ciapra(a1)		; wepl timing fix
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

.gamecont5
	dbf	d1,.gamecont3

	bclr	d3,ciaddra(a1)		; set bit to in at ciapra
	move.w	#POTGO_RESET,potgo(a0)	; changed from ffff to ff00, according to robinsonb5@eab
		
	or.b	#$C0,ciapra(a1)		; reset port direction

		; test only last bits
	and.w	#03,D0
		
	movem.l	(a7)+,d1-d5/a0-a1
	rts

_joystick:

	movem.l	a0,-(a7)		; put input 0 output in joy0
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

	moveq	#CIAB_GAMEPORT0,d3		; red button ( port 0 )
	moveq	#10,d4				; blue button ( port 0 )
	move.w	#$f600,d5			; for potgo port 0
	moveq	#joy0dat,d6			; port 0
	move.b	controller_joypad_0(pc),d2
	bra.b	.direction
.port1
	moveq	#CIAB_GAMEPORT1,d3		; red button ( port 1 )
	moveq	#14,d4				; blue button ( port 1 )
	move.w	#$6f00,d5			; for potgo port 1
	moveq	#joy1dat,d6			; port 1
	move.b	controller_joypad_1(pc),d2

.direction
	lea	$DFF000,a0
	lea	$BFE001,a1

	moveq	#0,d7

	IFND    IGNORE_JOY_DIRECTIONS
	move.w	0(a0,d6.w),d0			; get joystick direction
	move.w	d0,d6

	move.w	d0,d1
	lsr.w	#1,d1
	eor.w	d0,d1

	btst	#8,d1				; check joystick up
	sne	d7
	add.w	d7,d7

	btst	#0,d1				; check joystick down
	sne	d7
	add.w	d7,d7

	btst	#9,d0				; check joystick left
	sne	d7
	add.w	d7,d7

	btst	#1,d0				; check joystick right
	sne	d7
	add.w	d7,d7

	swap	d7
	ENDC
    
	;two/three buttons

	btst	d4,potinp(a0)			; check button blue (normal fire2)
	seq	d7
	add.w	d7,d7

	btst	d3,ciapra(a1)			; check button red (normal fire1)
	seq	d7
	add.w	d7,d7

	and.w	#$0300,d7			; calculate right out for
	asr.l	#2,d7				; above two buttons
	swap	d7				; like from lowlevel
	asr.w	#6,d7

	; read buttons from CD32 pad only if CD32 pad detected

	moveq	#0,d0
	tst.b	d2
	beq.b	.read_third_button
		
	bset	d3,ciaddra(a1)			; set bit to out at ciapra
	bclr	d3,ciapra(a1)			; clr bit to in at ciapra

	move.w	d5,potgo(a0)

	moveq	#8-1,d1
	bra.b	.gamecont4

.gamecont3
	tst.b	ciapra(a1)
	tst.b	ciapra(a1)
.gamecont4
	tst.b	ciapra(a1)			; wepl timing fix
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

.gamecont5
	dbf	d1,.gamecont3

	bclr	d3,ciaddra(a1)			; set bit to in at ciapra
.no_further_button_test
	move.w	#POTGO_RESET,potgo(a0)		; changed from ffff, according to robinsonb5@eab


	swap	d0				; d0 = state
	or.l	d7,d0

	IFND    IGNORE_JOY_DIRECTIONS        
	moveq	#0,d1				; d1 = raw joydat
	move.w	d6,d1
	ENDC
    
	or.b	#$C0,ciapra(a1)			; reset port direction

 	IFD    IGNORE_JOY_DIRECTIONS        
	movem.l	(a7)+,d1-d7/a0-a1
	ELSE
	movem.l	(a7)+,d2-d7/a0-a1
	ENDC
	rts

.read_third_button
        subq.l	#2,d4				; shift from DAT*Y to DAT*X
        btst	d4,potinp(a0)			; check third button
        bne.b	.no_further_button_test
        or.l	third_button_maps_to(pc),d7
        bra.b	.no_further_button_test
       
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




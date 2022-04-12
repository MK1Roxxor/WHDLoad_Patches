; V1.1, StingRay
; 10-Apr-2022	- slave disassembled
;		- byte write to volume register fixed

; 11-Apr-2022	- keyboard interrupt rewritten
;		- 68000 quitkey support

; 12-Apr-2022	- interrupt fixed
;		- WHDLoad v17+ features (config) used


	INCDIR	SOURCES:Include/
	INCLUDE	WHDLoad.i

FLAGS	= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
QUITKEY	= $59

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM

HEADER
ws	SLAVE_HEADER			; ws_Security + ws_ID
	dc.w	17			; ws_Version
	dc.w	FLAGS			; ws_Flags
	dc.l	$80000			; ws_BaseMemSize
	dc.l	0			; ws_ExecInstall
	dc.w	slv_GameLoader-ws	; ws_GameLoader
	dc.w	0			; ws_CurrentDir
	dc.w	0			; ws_DontCache
	dc.b	0			; ws_keydebug
	dc.b	QUITKEY			; ws_keyexit
	dc.l	0			; ws_ExpMem
	dc.w	slv_name-ws		; ws_name
	dc.w	slv_copy-ws		; ws_copy
	dc.w	slv_info-ws		; ws_info
; v16
	dc.w	0			; ws_kickname
	dc.l	0			; ws_kicksize
	dc.w	0			; ws_kickcrc

; v17
	dc.w	.config-HEADER		; ws_config


.config	dc.b	"C1:B:Unlimited Time"
	dc.b	0

slv_name	DC.B	"Round The Bend",0
slv_copy	DC.B	"1992 Zeppelin",0
slv_info	DC.B	"installed & fixed by Bored Seal & StingRay",10
		DC.B	"V1.1 (12-Apr-2022)",0
		CNOP	0,2

slv_GameLoader
	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	moveq	#$3C,d1
	moveq	#5,d2
	lea	$1BFBC,a0
	bsr	Load
	move.l	a0,a6
	move.l	d2,d0
	mulu	#512,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$8ADE,d0
	bne.w	Unsupported
	lea	($44,a6),a6
	move.w	#$6008,(6,a6)

	lea	Store_Key(pc),a0
	bsr	Set_Keyboard_Custom_Routine

	bsr	Init_Level2_Interrupt


	move.w	#$4EF9,($2FA,a6)
	pea	(Load,pc)
	move.l	(sp)+,($2FC,a6)

	pea	Patch_Game(pc)
	move.l	(a7)+,$218(a6)
	jmp	(a6)


Patch_Game
	move.l	#$534066FC,d0		; subq.w #1,d0 bne.b .loop
	move.l	#$4EB800C0,d2
	bsr.b	Patch_Code
	move.l	#$538066FC,d0		; subq.l #1,d0 bne.b .loop
	bsr.b	Patch_Code
	move.l	#$51C8FFFE,d0		; dbf d0,.loop
	bsr.b	Patch_Code
	move.l	#$6600FFFC,d0		; bne.w .loop
	bsr.b	Patch_Code
	move.l	#$534266FC,d0		; subq.w #1,d2 bne.b .loop
	addq.l	#6,d2
	bsr.b	Patch_Code
	lea	$C0.w,a0
	move.w	#$4EF9,(a0)+
	pea	Fix_Delay(pc)
	move.l	(sp)+,(a0)+
	move.w	#$4EF9,(a0)+
	pea	Fix_Delay_D2(pc)
	move.l	(sp)+,(a0)+

	jmp	$6A026

Patch_Code
	lea	$50164,a0
	lea	$700D2,a1
.loop	move.l	(a0),d1
	cmp.l	d0,d1
	bne.b	.instruction_not_found
	move.l	d2,(a0)
.instruction_not_found
	addq.l	#2,a0
	cmp.l	a1,a0
	ble.b	.loop
	rts




Store_Key
	moveq	#0,d0
	move.b	Key(pc),d0
	move.w	d0,$69000+$7cb2
	rts



Fix_Delay_D2
	movem.l	d0/d1/a0,-(sp)
	move.l	d2,d1
	bra.b	Delay_D1

Fix_Delay
	movem.l	d0/d1/a0,-(sp)
	move.l	d0,d1
Delay_D1
	divu	#34,d1
.loop	move.b	$DFF006,d0
.same_raster_line
	cmp.b	$DFF006,d0
	beq.b	.same_raster_line
	dbf	d1,.loop
	movem.l	(sp)+,d0/d1/a0
	rts

Copylock
	move.l	#$13CA7B50,d0
	move.l	d0,$60.w
	jmp	$69998

Load	movem.l	d0-d3/a0-a2,-(a7)

	move.w	d1,d7
	move.l	a0,a5

	mulu	#512,d1
	mulu	#512,d2
	move.l	d1,d0
	move.l	d2,d1
	moveq	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)

	; V1.1
	lea	.Patch_Table(pc),a0
.search	movem.w	(a0)+,d0/d1
	cmp.w	d0,d7
	bne.b	.no_patch_needed
	lea	.Patch_Table(pc,d1.w),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)
	bra.b	.exit

.no_patch_needed
	tst.w	(a0)
	bne.b	.search


.exit
	movem.l	(a7)+,d0-d3/a0-a2
	moveq	#0,d0
	rts

.Patch_Table
	dc.w	$37a,PL_REPLAY-.Patch_Table
	dc.w	$188,PL_GAME-.Patch_Table
	dc.w	0


PL_REPLAY
	PL_START
	PL_P	$5f2,.Fix_Volume_Register_Byte_Write
	PL_END

.Fix_Volume_Register_Byte_Write
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts


PL_GAME	PL_START
	; V1.0
	PL_P	$7cea,Load
	PL_P	$2c,Copylock
	PL_IFC1
	PL_SA	$701a,$701e
	PL_ENDIF

	; V1.1
	PL_PS	$702c,.Check_Quit_Key
	PL_PSS	$705e,.Acknowledge_Level3_Interrupt,2
	PL_END

.Acknowledge_Level3_Interrupt
	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rts	

.Check_Quit_Key
	move.b	$bfec01,d0
	move.l	d0,-(a7)
	ror.b	d0
	not.b	d0
	bsr	Check_Quit_Key
	move.l	(a7)+,d0
	rts
	



QUIT	pea	(TDREASON_OK).W
	bra.b	EXIT

Unsupported
	pea	(TDREASON_WRONGVER).W
EXIT	move.l	resload(pc),a2
	jmp	resload_Abort(a2)

resload	dc.l	0


; ---------------------------------------------------------------------------


; d0.b: rawkey code

Check_Quit_Key
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	rts	

; a0.l: pointer to routine to be called once a key has been pressed
Set_Keyboard_Custom_Routine
	move.l	a1,-(a7)
	lea	KbdCust(pc),a1
	move.l	a0,(a1)
	move.l	(a7)+,a1
	rts

; Level 2 interrupt used to handle keyboard events.

Init_Level2_Interrupt
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

	lea	Key(pc),a2
	moveq	#0,d0
	move.b	$bfec01-$bfe001(a1),d0
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)+
	or.b	#1<<6,$e00(a1)			; set output mode

	bsr.b	Check_Quit_Key

	move.l	(a2)+,d1
	beq.b	.nocustom
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.nocustom
	

.nokeys	moveq	#3-1,d1
.loop	move.b	$dff006-$dff000(a0),d0
.wait	cmp.b	$dff006-$dff000(a0),d0
	beq.b	.wait
	dbf	d1,.loop


	and.b	#~(1<<6),$e00(a1)	; set input mode
.end	move.w	#1<<3,$9c(a0)
	move.w	#1<<3,$9c(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte



Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine


;-----------------------------------------------------
;  :Program.	nitroslave.asm
;  :Contents.	Slave for "Nitro"
;  :Author.	Harry, StingRay
;  :History.	12.05.97
;               26.08.97
;		25.06.2010
;		24.03.2021 (StingRay):
;		- RawDIC imager, Bored Seal added to credits :), source made
;		  100% pc-relative, resload_Delay() for title picture used,
;		  default high scores are loaded from disk
;  :Requires.	whdload-package :)
;  :Copyright.	Freeware
;  :Language.	68000 Assembler
;  :Translator.	ASM-One 1.25
;  :To Do.
;  :Build from Gods-slave by WEPL
;-------------------------------------------------------

		incdir	"SOURCES:include/"
		include	whdload.i
		include	whdmacros.i

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	15
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_Disk|WHDLF_ClearMem
		dc.l	$80000
		dc.l	0
		dc.w	_Start-_base
		dc.w	0
		dc.w	0
_keydebug	dc.b	0
_keyexit	dc.b	$59
		dc.l	0
		dc.w	_name-_base
		dc.w	_copy-_base
		dc.w	_info-_base
_name		dc.b	"Nitro",0
_copy		dc.b	"1990 Psygnosis",0
_info		dc.b	"installed & fixed by Harry, Bored Seal, StingRay",10
		dc.b	"V1.3 (24-Mar-2021)",0
		even

_Start		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later using

	move.l	a0,a2


	moveq	#0,d0
	move.l	#$1200,d1
	lea	$800-4.w,a0
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)


					
		move.l	#$1200,d0		;check disk version
		lea	$800-4.w,a0
		jsr	(resload_CRC16,a2)

		moveq	#1,d1
		cmp.w	#$3e9f,d0		;v1 = PAL
		beq.b	setver
		moveq	#2,d1
		cmp.w	#$34c8,d0		;v2 = NTSC
		beq.b	setver

Unsupported	pea	(TDREASON_WRONGVER).w
_end		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

setver	move.l	#$100,$dff080
	move.l	#$fffffffe,$100.w

	lea	version(pc),a0
	move.w	d1,(a0)

	cmp.w	#2,d1
	beq.b	ver_2

ver_1	lea	boot_v1(pc),a0
	bra.b	Boot

ver_2	lea	boot_v2(pc),a0
Boot	suba.l	a1,a1
	jsr	(resload_Patch,a2)

	lea	$700.w,a0
	move.l	a0,usp
	jmp	$800.w

boot_v1	PL_START
	PL_B	$85c,$60
	PL_P	$c1c,LOADSTD
	PL_R	$bc6		;remove disk access
	PL_END

boot_v2	PL_START
	PL_B	$85c,$60
	PL_P	$c3c,LOADSTD
	PL_R	$be6		;remove disk access
	PL_END

;A0-ADR
;D0-LEN
;D1-TRACK (OBSOLETE)
;D2-TRACKOFFSET (OBSOLETE)


SAVEHIGH	movem.l	d1-d2/a0-a3,-(sp)
		bsr.b	Params
		jsr	(resload_SaveFile,a2)
		movem.l	(sp)+,d1-d2/a0-a3
		moveq	#0,d0
		rts

Params		move.l	a0,a1			;address
		lea	HIGHNAME(pc),a0		;filename
		move.l	_resload(pc),a2
		rts

LOADHIGH	movem.l	d1-d2/a0-a3,-(sp)
		move.l	a0,a3
		bsr.b	Params
		jsr     (resload_GetFileSize,a2)
		tst.l	d0
		beq.b	.no_highscore_file

		move.l	a3,a0
		bsr.b	Params
		jsr	(resload_LoadFile,a2)
	bra.b	.exit

	; V1.3: load default high scores from disk
.no_highscore_file
	move.l	a3,a0
	move.l	#$1200,d0
	move.l	#320,d1
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)
	


.exit		movem.l	(sp)+,d1-d2/a0-a3
		moveq	#0,d0
		RTS


;A0-DEST
;A1-POINTER AUF AREA:
; (A1)-DISKNAME (LONGWORD)
; 4(A1)-OFFSET
; 8(A1)-LENGTH

LOADSTD	MOVEM.L	D1-A6,-(A7)
	move.l	_resload(pc),a3

	MOVE.L	A1,A6
	MOVE.L	A0,A5
	move.l	4(A6),D0	;offset
	CMP.L	#$63020,D0
	BNE.B	.W1

	; picture delay
	move.l	d0,-(a7)
	moveq	#5*10,d0
	jsr	resload_Delay(a3)
	move.l	(a7)+,d0

.W1	MOVE.L	8(A6),D1	;size
	moveq	#1,d2		;disk
;	lea	(A0),a0		;dest
;	move.l	(_resload,pc),a3
	LEA.L	trap(PC),a2
	MOVE.L	a2,$80.w
	trap	#0
	MOVE.L	4(A6),A0
	CMP.L	#$63020,A0
	BNE.b	CONT
	MOVE.W	version(pc),D0
	CMP.W	#2,D0
	BEQ.b	WV2

	lea	game_v1(pc),a0
	lea	$f000,a1
	jsr	(resload_Patch,a3)
	bra.b	STOP

WV2	
	lea	game_v2(pc),a0
	lea	$f000,a1
	jsr	(resload_Patch,a3)
	move.l	4(A6),A0
CONT	CMP.L	#$95298,A0	;v1
	BNE.S	.CONT2
.V1	MOVE.B	#$20,$4EF4.W
	MOVE.B	#0,$4e7a.w
	MOVE.W	#$4EB9,$53E6.W
	LEA.L	FIXACCESS(PC),A0
	MOVE.L	A0,$53E8.W
	BRA.S	.CONT3

.CONT2	CMP.L	#$952B8,A0	;V2
	BEQ.S	.V1

.CONT3	NOP

STOP	MOVE.B	#$2,$BFE001
	MOVEM.L	(A7)+,D1-A6
	MOVEQ.L	#0,D0
	RTS

trap	add.l	#$1200+320,d0	; V1.3, new disk format
	jsr	resload_DiskLoad(a3)
	rte

game_v1	PL_START
;	PL_W	$1AD14+$F000,$4240
	PL_P	$1384,LOADHIGH	;HIGHSCORE
	PL_P	$13F0,SAVEHIGH
	PL_P	$12F0,LOADSTD	;LOADER
	PL_P	$18634,KEYHP

	PL_R	$1B6D8		;remove ingame protection
	PL_R	$1F4E2
	PL_R	$1A406
	PL_R	$19A1E
	PL_B	$18322,$60	;remove protection check
	PL_B	$18D28,$60
	PL_CB	$1FA09
	PL_CB	$1FA0D

	PL_PS	$18EEA,ADDCORR	;CORRECT ADD
	PL_W	$20EF2,$6002	;SKIP ILLEGAL ACCESS TO $FFFF8240.W
	PL_L	$1E9CA,$DFF006	;REPLACE ILLEGAL ACCESS TO $FF8209.W
	PL_B	$182BD,$84	;CORRECT COPPERLISTPROBLEM

	PL_R	$129a		;remove disk access
	PL_AW	$1834e,$200 	;correct bplcon0 set
	PL_AW	$183c6,$200
	PL_B	$1db3,$a8	;fix $dff008 => $dff0a8

	PL_PS	$19190,BlitFix1	;insert missing blitter waits
	PL_PS	$1dc72,BlitFix2
	PL_PS	$1dcb0,BlitFix2
	PL_W	$1b474,$4e71
	PL_PS	$1b476,BlitFix3
	PL_W	$1b426,$4e71
	PL_PS	$1b428,BlitFix4
	PL_P	$1ecf8,BlitFix5
	PL_PS	$1e2d2,BlitFix6
	PL_P	$1ec64,BlitFix7
	PL_PS	$1d2f2,BlitFix8
	PL_PS	$1b1d8,BlitFix9
	PL_P	$1db4a,BlitWait	;better blit wait
	PL_END

game_v2	PL_START
	PL_P	$1384,LOADHIGH	;HIGHSCORE
	PL_P	$13F0,SAVEHIGH
	PL_P	$12F0,LOADSTD	;LOADER
	PL_P	$1864A,KEYHPV2

	PL_R	$1B6F6		;remove ingame protection
	PL_R	$1F500
	PL_R	$1A41c
	PL_R	$19A34
	PL_B	$18322,$60	;patch protection checks
	PL_B	$18D3E,$60
	PL_CB	$1FA27
	PL_CB	$1FA2B

	PL_PS	$18F00,ADDCORRV2	;CORRECT ADD
	PL_W	$20F10,$6002	;SKIP ILLEGAL ACCESS TO $FFFF8240.W
	PL_L	$1E9E8,$DFF006	;REPLACE ILLEGAL ACCESS TO $FF8209.W
	PL_B	$182BD,$84	;CORRECT COPPERLISTPROBLEM

	PL_R	$129a		;remove disk access
	PL_AW	$1834e,$200 	;correct bplcon0 set
	PL_AW	$183c6,$200
	PL_B	$1db3,$a8		;fix $dff008 => $dff0a8

 	PL_PS	$191a6,BlitFix1	;insert missing blitter waits
	PL_PS	$1dc90,BlitFix2
	PL_PS	$1dcce,BlitFix2
	PL_W	$1b492,$4e71
	PL_PS	$1b494,BlitFix3_v2
	PL_W	$1b444,$4e71
	PL_PS	$1b446,BlitFix4_v2
	PL_P	$1ed16,BlitFix5
	PL_PS	$1e2f0,BlitFix6
	PL_P	$1ec82,BlitFix7
	PL_PS	$1d310,BlitFix8
	PL_PS	$1b1f6,BlitFix9
	PL_P	$1db68,BlitWait	;better blit wait
	PL_END

BlitFix1	move.w	#$7807,$58(a5)
		bra.b	BlitWait

BlitFix2	move.w	d2,$58(a6)
		adda.l	d6,a1
		bra.b	BlitWait

BlitFix3	move.w	$1b4d2,$58(a6)
		bra.b	BlitWait

BlitFix3_v2	move.w	$1b4f0,$58(a6)
		bra.b	BlitWait

BlitFix4	move.w	$1b4d4,$58(a6)
		bra.b	BlitWait

BlitFix4_v2	move.w	$1b4f2,$58(a6)
		bra.b	BlitWait

BlitFix5	move.w	#$245,$dff058
		bra.b	BlitWait

BlitFix6	move.w	d7,$dff058
		bra.b	BlitWait

BlitFix7	move.w	#$244,$dff058
		bra.b	BlitWait

BlitFix9	adda.l	#8,a0
		bra.b	BlitWait

BlitFix8	move.w	d4,$58(a6)
		addq.l	#2,d1
BlitWait	;BLITWAIT


	tst.b	$DFF002
	btst	#6,$DFF002
	beq.b	.exit
.wblit	tst.b	$BFE001
	tst.b	$BFE001
	tst.b	$BFE001
	tst.b	$BFE001
	btst	#6,$DFF002
	bne.b	.wblit
.exit	tst.b	$DFF002
	rts


		rts

INITNAME	DC.B	'INIT',0
		EVEN

HIGHNAME	DC.B	'HIGH',0
		EVEN

version		dc.w	0	;version of game
_resload	dc.l	0	;address of resident loader

;====================================================================
; RAW-Key-Codes:
;	ESC	$45
;	DEL	$46
;	F1..F10	$50..$59
;	HELP	$5f

KEYHP	MOVE.B	$BFED01,D0
	AND.B	#%10001000,D0
	CMP.B	#$88,D0
	BNE	lab_5
	MOVEQ.L	#0,D0
	MOVE.B	$BFEC01,D0
	EOR.B	#$FF,D0
	ROR.B	#1,D0
	BSET	#6,$BFEE01
	MOVE.B	#0,$BFEC01
	MOVEQ.L	#2,D1
.4	MOVE.L	D1,-(A7)
	MOVE.B	$DFF006,D1
.3	CMP.B	$DFF006,D1
	BEQ.S	.3
	MOVE.L	(A7)+,D1
	DBF	D1,.4
	BCLR	#6,$BFEE01
	move.b	_keyexit(pc),d1
	cmp.b	d1,d0
	BEQ	QUIT
	MOVE.B	D0,$1869A
	JMP	$18680

KEYHPV2	MOVE.B	$BFED01,D0
	AND.B	#%10001000,D0
	CMP.B	#$88,D0
	BNE	lab_5
	MOVEQ.L	#0,D0
	MOVE.B	$BFEC01,D0
	EOR.B	#$FF,D0
	ROR.B	#1,D0
	BSET	#6,$BFEE01
	MOVE.B	#0,$BFEC01
	MOVEQ.L	#2,D1
.4	MOVE.L	D1,-(A7)
	MOVE.B	$DFF006,D1
.3	CMP.B	$DFF006,D1
	BEQ.S	.3
	MOVE.L	(A7)+,D1
	DBF	D1,.4
	BCLR	#6,$BFEE01
	move.b	_keyexit(pc),d1
	cmp.b	d1,d0
	BEQ.b	QUIT
	MOVE.B	D0,$186B0
	JMP	$18696

lab_5	MOVE.W	#8,$DFF09C
	MOVEM.L	(A7)+,D0-D2/A0
	RTE

QUIT	pea	(TDREASON_OK).w
	bra	_end

ADDCORR	AND.L	#$FFFF,D1
	ADD.L	#$2030C,D1
	RTS

ADDCORRV2
	AND.L	#$FFFF,D1
	ADD.L	#$2032A,D1
	RTS

FIXACCESS
.2	CMP.L	#$7FFFF,A1
	BLS.S	.1
	SUB.L	A1,A1
.1	MOVE.B	(A0)+,(A1)+
	DBF	D0,.2
	RTS

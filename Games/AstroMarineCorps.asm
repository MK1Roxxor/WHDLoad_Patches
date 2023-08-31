; V1.2, stingray
;
; 14-Feb-2016:
; - moveP instructions used in the text writer emulated
; - much better and simpler approach for the "throw grenadesw with
;   2nd fire button" patch, old one didn't work properly (grenades could
;   not be thrown using keyboard anymore!)
;
; 12-Feb-2016:
; - all blitter wait patches removed, there are none needed...
; - DMA wait fix corrected
;
; 11-Feb-2016:
; - started to convert the old patch code to patchlists
;
; 10-Feb-2016:
; - unlimited bombs trainer added
; - support for 2nd fire button (grenades) added
; - high-score saving disabled if any trainer options are used
;
; 09-Feb-2016:
; - interrupts fixed, 68000 quitkey support, blitter wait patches disabled
;   on 68000, "real" trainer options added, WHDLoad v17+ features used,
;   code optimised


	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i

;DEBUG

HEADER		SLAVE_HEADER			; ws_Security + ws_ID
		dc.w	17
		dc.w	WHDLF_NoError|WHDLF_NoKbd
		dc.l	524288			; ws_BaseMemSize
		dc.l	0			; ws_ExecInstall
		dc.w	Patch-HEADER		; ws_GameLoader
		IFD	DEBUG
		dc.w	.dir-HEADER
		ELSE
		dc.w	0			; ws_CurrentDir
		ENDC
		dc.w	0			; ws_DontCache
		dc.b	0			; ws_keydebug
		dc.b	0			; ws_keyexit
		dc.l	0
		dc.w	.name-HEADER
		dc.w	.copy-HEADER
		dc.w	.info-HEADER

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"C1:X:Unlimited Lives:0;"
	dc.b	"C1:X:Unlimited Energy:1;"
	dc.b	"C1:X:Unlimited Time:2;"
	dc.b	"C1:X:Unlimited Grenades:3"
	dc.b	0



.dir		IFD	DEBUG
		dc.b	"SOURCES:WHD_Slaves/AstroMarineCorps",0
		ENDC
		
.name		dc.b	"Astro Marine Corps",0
.copy		dc.b	"1990 Dinamic",0
.info		dc.b	"installed & fixed by Bored Seal & StingRay",10
		dc.b	"V1.2 (14-Feb-2016)",0
		even

Patch		lea	resload(pc),a1
		move.l	a0,(a1)			;save for later using

		move.l	a0,a2
                lea     TAGLIST(pc),a0
                jsr     resload_Control(a2)

		lea	$34560,a6
		moveq	#2,d0
		move.l	#$4600,d1
		bsr	LoadTracks


; load high-scores
		bsr	LoadHi


	move.w	#$ff00,$dff034		; initialise POTGO

	lea	PLBOOT(pc),a0
	move.l	a6,a1

; install trainers
	move.l	TRAINEROPTIONS(pc),d0

; unlimited lives
	lsr.l	#1,d0
	bcc.b	.NoLivesTrainer
	eor.b	#$19,$146a(a1)		; subq  <-> tst
.NoLivesTrainer

; unlimited energy (tricky, won't be done here!)
	lsr.l	#1,d0
	
.NoEnergyTrainer

; unlimited Time
	lsr.l	#1,d0
	bcc.b	.NoTimeTrainer
	eor.b	#$db,$17ae(a1)		; sub.w d0,xx <-> tst
.NoTimeTrainer

	

	jsr	resload_Patch(a2)
	

	jmp	$34618


PLBOOT	PL_START
	PL_PSS	$2e32,AckVBI,2
	PL_PS	$3948,.checkquit

	PL_PS	$2aec,.energy		; unlimited energy trainer


	PL_P	$6d6,LoadTracks
	PL_P	$5ca,Decrunch	
	PL_P	$2b20,SMFFix		; fix self-modifying code
	PL_P	$10d0,SMFFix2		; fix self-modifying code
	PL_S	$be,4			; no user state
	PL_PSS	$3ee8,FixDMAWait,2	; fix DMA wait in replayer
	PL_W	$3c62,$4e71		; no sound fadeout
	PL_PSS	$19fa,SaveHi,2		; save high-scores
	PL_PS	$54e,InsertDisk
	PL_W	$56c,$4e71		; don't wait for disk change

	PL_P	$bd2,.fixMoveP		; emulate moveP in text writer routine

	PL_PS	$3b46,.checkFire2	; throw grenades with fire 2

	PL_END

.checkFire2
	move.w	$dff00c,d0		; original code

	btst	#6,$dff016		; fire button 2 pressed?
	bne.b	.noFire2
	bset	#0,d2			; set "grenade key" bit

.noFire2
	move.w	#$c000,$dff034
	rts


.fixMoveP
	;move.l	(a0)+,d0
	;movep.l d0,0(a1)

	move.b	(a0)+,0(a1)
	move.b	(a0)+,2(a1)
	move.b	(a0)+,4(a1)
	move.b	(a0)+,6(a1)

	;move.l	(a0)+,d0
	;movep.l d0,8(a1)
	
	move.b	(a0)+,0+8(a1)
	move.b	(a0)+,2+8(a1)
	move.b	(a0)+,4+8(a1)
	move.b	(a0)+,6+8(a1)

	;move.l	(a0)+,d0
	;movep.l d0,16(a1)

	move.b	(a0)+,0+16(a1)
	move.b	(a0)+,2+16(a1)
	move.b	(a0)+,4+16(a1)
	move.b	(a0)+,6+16(a1)

	;move.l	(a0),d0
	;movep.l d0,24(a1)

	move.b	0(a0),0+24(a1)
	move.b	1(a0),2+24(a1)
	move.b	2(a0),4+24(a1)
	move.b	3(a0),6+24(a1)

	add.w	d2,a1
	swap	d2
	rts


	


	


.energy	move.w	(a1),d2
	move.w	2(a1),d0

	movem.l	d1/a0,-(a7)

; unlimited energy trainer enabled?
	move.l	TRAINEROPTIONS(pc),d1
	btst	#1,d1
	beq.b	.noEnergy
	
	lea	(a5,d2.w),a0
	cmp.l	#$15a88,a0		; is it the energy value?
	bne.b	.noEnergy
	moveq	#0,d0

.noEnergy
	movem.l	(a7)+,d1/a0

	tst.w	d0
	rts

.checkquit
	not.b	d0
	and.b	#$7f,d0

	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	QUIT
	rts

QUIT	pea	(TDREASON_OK).w
	move.l	resload(pc),a0
	jmp	resload_Abort(a0)

AckVBI	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rts


PatchExe	move.l	#$70004e75,$3ad82	;protection
	rts


InsertDisk	lea	disknum(pc),a2
		move.b	$34822,d0
		cmp.b	#$1f,d0
		bne.b	.d1
		move.b	#2,(a2)
		bra.b	inserted
.d1		move.b	#1,(a2)
inserted	lea	$34814,a2
		rts

FixDMAWait
	moveq	#5-1,d0
.loop	move.w  d0,-(a7)
	move.b	$dff006,d0
.wait	cmp.b	$dff006,d0
	beq.b	.wait
	move.w	(a7)+,d0
	dbf	d0,.loop
	rts


SMFFix		move.l	(4,a1),-(sp)
		rts

SMFFix2		move.l	(a0,d0.w),d5
		move.l	(sp)+,a0
		move.w	(sp)+,d0
		move.l	d5,-(sp)
		moveq	#0,d5
		rts


LoadTracks	movem.l	d0-d2/a0-a2,-(sp)
		move.l	a6,a0
		mulu.w	#512,d0
		move.b	disknum(pc),d2
		move.l	resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(sp)+,d0-d2/a0-a2
		rts

LoadHi		movem.l	d0-d7/a0-a6,-(sp)
		bsr.b	Params
                jsr     resload_GetFileSize(a2)
                tst.l   d0
                beq.b	NoHisc
		bsr.b	Params
		jsr	resload_LoadFile(a2)
NoHisc		movem.l	(sp)+,d0-d7/a0-a6
		rts

Params		lea	hiscore(pc),a0
		lea	$36034,a1
		move.l	resload(pc),a2
		rts

SaveHi		movem.l	d0-d7/a0-a6,-(sp)

	move.l	TRAINEROPTIONS(pc),d0
	bne.b	.nosave

		bsr.b	Params
		move.l	#172,d0
		jsr	resload_SaveFile(a2)
.nosave

		movem.l	(sp)+,d0-d7/a0-a6
		move.l	$362b0,d0
		cmp.l	$36278,d0
		rts

Decrunch	MOVE.L	A0,-(SP)
		MOVEA.L	A6,A0
		MOVEA.L	A5,A1
		BSR.b	Dec_2
		MOVEA.L	A5,A0
		MOVEA.L	A6,A1
		BSR.W	Dec88
		MOVE.L	D0,D1
		MOVEA.L	(SP)+,A0
		cmp.w	#$58,$3aa12	;exe
		beq.w	PatchExe


	movem.l	d0/a0,-(a7)
	lea	$469ca,a0

	cmp.w	#$5352,(a0)
	bne.b	.nogrenade
	move.l	TRAINEROPTIONS(pc),d0
	btst	#3,d0
	beq.b	.nogrenade
	move.w	#$4e71,(a0)
.nogrenade

	movem.l	(a7)+,d0/a0
	

		RTS

Dec_2		MOVEM.L	D1-D3/A2/A3,-(SP)
		MOVE.L	(A0)+,D0
		ANDI.L	#$7FFFFF,D0
		LEA	(A1,D0.L),A3
		LEA	(A0),A2
		LEA	($12,A0),A0
		MOVE.L	(A0)+,D1
		MOVEQ	#$20,D3
Dec_6		CMPA.L	A3,A1
		BCS.B	Dec_3
		MOVEM.L	(SP)+,D1-D3/A2/A3
		RTS

Dec_3		DBRA	D3,Dec_33
		MOVE.L	(A0)+,D1
		MOVEQ	#$1F,D3
Dec_33		ADD.L	D1,D1
		BCC.B	Dec_4
		DBRA	D3,Dec9
		MOVE.L	(A0)+,D1
		MOVEQ	#$1F,D3
Dec9		ADD.L	D1,D1
		BCC.B	dec_7
		MOVE.B	(A2),(A1)+
		BRA.B	Dec_6

dec_7		CMP.W	#4,D3
		BCS.B	Dec_8
		SUBQ.W	#4,D3
		ROL.L	#4,D1
		MOVEQ	#15,D2
		AND.W	D1,D2
		MOVE.B	(1,A2,D2.W),(A1)+
		BRA.B	Dec_6

Dec_8		MOVEQ	#0,D2
		DBRA	D3,dec33
		MOVE.L	(A0)+,D1
		MOVEQ	#$1F,D3
dec33		ADD.L	D1,D1
		ADDX.W	D2,D2
		DBRA	D3,Dec3_4
		MOVE.L	(A0)+,D1
		MOVEQ	#$1F,D3
Dec3_4		ADD.L	D1,D1
		ADDX.W	D2,D2
		DBRA	D3,Dec3_2
		MOVE.L	(A0)+,D1
		MOVEQ	#$1F,D3
Dec3_2		ADD.L	D1,D1
		ADDX.W	D2,D2
		DBRA	D3,Dec3_1
		MOVE.L	(A0)+,D1
		MOVEQ	#$1F,D3
Dec3_1		ADD.L	D1,D1
		ADDX.W	D2,D2
		MOVE.B	(1,A2,D2.W),(A1)+
		BRA.B	Dec_6

Dec_4		CMP.W	#8,D3
		BCS.B	Dec_5
		SUBQ.W	#8,D3
		ROL.L	#8,D1
		MOVE.B	D1,(A1)+
		BRA.B	Dec_6

Dec_5		DBRA	D3,Dec_55
		MOVE.L	(A0)+,D1
		MOVEQ	#$1F,D3
Dec_55		ADD.L	D1,D1
		ADDX.W	D2,D2
		DBRA	D3,Dec_51
		MOVE.L	(A0)+,D1
		MOVEQ	#$1F,D3
Dec_51		ADD.L	D1,D1
		ADDX.W	D2,D2
		DBRA	D3,Dec5_1
		MOVE.L	(A0)+,D1
		MOVEQ	#$1F,D3
Dec5_1		ADD.L	D1,D1
		ADDX.W	D2,D2
		DBRA	D3,Dec_62
		MOVE.L	(A0)+,D1
		MOVEQ	#$1F,D3
Dec_62		ADD.L	D1,D1
		ADDX.W	D2,D2
		DBRA	D3,Dec_63
		MOVE.L	(A0)+,D1
		MOVEQ	#$1F,D3
Dec_63		ADD.L	D1,D1
		ADDX.W	D2,D2
		DBRA	D3,Dec6_2
		MOVE.L	(A0)+,D1
		MOVEQ	#$1F,D3
Dec6_2		ADD.L	D1,D1
		ADDX.W	D2,D2
		DBRA	D3,Dec_64
		MOVE.L	(A0)+,D1
		MOVEQ	#$1F,D3
Dec_64		ADD.L	D1,D1
		ADDX.W	D2,D2
		DBRA	D3,Dec_61
		MOVE.L	(A0)+,D1
		MOVEQ	#$1F,D3
Dec_61		ADD.L	D1,D1
		ADDX.W	D2,D2
		MOVE.B	D2,(A1)+
		BRA.W	Dec_6

Dec88		MOVEA.L	A1,A2
		MOVE.B	(A0)+,D1
		SUBQ.L	#1,D0
dec45		MOVE.B	(A0)+,D2
		CMP.B	D2,D1
		BEQ.B	DecA
		MOVE.B	D2,(A1)+
		SUBQ.L	#1,D0
		BNE.B	dec45
dec44		SUBA.L	A2,A1
		MOVE.L	A1,D0
		RTS

DecA		CLR.W	D2
		MOVE.B	(A0)+,D2
		BEQ.W	Dec_B
		MOVE.B	(A0)+,D3
		ADDQ.W	#2,D2
dec65		MOVE.B	D3,(A1)+
		DBRA	D2,dec65
		SUBQ.L	#3,D0
		BCS.B	dec44
		BNE.B	dec45
		BRA.B	dec44

Dec_B		MOVE.B	D1,(A1)+
		SUBQ.L	#2,D0
		BCS.B	dec44
		BNE.B	dec45
		BRA.B	dec44

hiscore		dc.b	"Highs",0
resload	dc.l	0

TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET

; bit 0: unlimited lives on/off
; bit 1: unlimited energy on/off
; bit 2: unlimited time on/off
; bit 3: unlimited grenades on/off
TRAINEROPTIONS	dc.l    0
		dc.l	TAG_DONE


disknum		dc.b	1

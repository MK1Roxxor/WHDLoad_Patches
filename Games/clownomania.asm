; v1.3, stingray, 31.08.2016
; - DMA wait fix for replayer and sample players
; - version check for PAL version added
; - VBL based delay replaced with resload_Delay
; - interrupts fixed
; - info for the WHDLoad splash window added

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i

FLAGS		= WHDLF_NoError|WHDLF_ClearMem
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
	dc.w	10		; ws_version
	dc.w	3		; ws_flags
	dc.l	$7C000		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	DC.W	Patch-HEADER	; ws_GameLoader
	IFD	DEBUG
	dc.w	.dir-HEADER	; ws_CurrentDir
	ELSE
	dc.w	0		; ws_CurrentDir
	ENDC
	DC.W	0		; ws_DontCache
	DC.B	0		; ws_keydebug
	dc.b	QUITKEY		; ws_keyexit
	dc.l	0		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

.name	dc.b	"Clown-o-Mania",0
.copy	dc.b	"1989 Starbyte",0
.info	dc.b	"Installed by Graham, Wepl, StingRay",10

	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.3 (31.08.2016)",0


.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/ClownOMania",0
	ENDC

HiName	DC.B	'Clown-O-Mania.save',0,0

	CNOP	0,2
	

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a5

	lea	$DFF000,a6
	move.l	#$3F000,d0
	move.l	#$14C00,d1
	moveq	#1,d2
	lea	($40000),a0
	movem.l	d1/a0,-(sp)
	jsr	resload_DiskLoad(a5)
	movem.l	(sp)+,d0/a0
	jsr	resload_CRC16(a5)
	cmp.w	#$7427,d0		; NTSC version
	seq	$FF.W

; v1.3, stingray
	beq.b	.ok
	
	cmp.w	#$a113,d0		; PAL version
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	jmp	resload_Abort(a5)


.ok	lea	$400.W,a4
	move.l	a4,a0
	move.l	#$1000200,(a0)+
	move.l	#$FFFFFFFE,(a0)
	move.l	a4,$80(a6)

	move.w	#$8380,$96(a6)		; enable copper DMA

	lea	$64.W,a1
	lea	(AckLev1,pc),a0
	move.l	a0,(a1)+
	lea	(AckLev2,pc),a0
	move.l	a0,(a1)+
	lea	(AckVBI,pc),a0
	move.l	a0,(a1)+
	lea	(AckLev4,pc),a0
	move.l	a0,(a1)+
	lea	(AckLev5,pc),a0
	move.l	a0,(a1)+
	lea	(AckLev6,pc),a0
	move.l	a0,(a1)+

	tst.b	$FF.W
	beq.b	.PAL
	move.w	#$6006,($4F600)
	move.w	#$601E,($4F6F4)
	move.w	#$4EB9,($4F6A4)
	pea	WaitVBL(pc)
	move.l	(sp)+,$4F6A6
	jsr	$4F5FC
	bra.b	LoadGame


.PAL	move.w	#$6006,$52A80
	move.w	#$6002,$52B72
	move.w	#$4EB9,$52B24
	pea	WaitVBL(pc)
	move.l	(sp)+,$52B26
	jsr	$52A7C


LoadGame
	move.l	a4,$80(a6)
	bsr	WaitVBL

; load title picture
	moveq	#3,d0
	swap	d0
	move.l	#$F000,d1		; 40*256*6
	moveq	#1,d2
	lea	$10000,a0
	jsr	resload_DiskLoad(a5)

	lea	$410.w,a3
	moveq	#1,d2			; planes start at $10000
	move.l	a3,a1
	moveq	#6-1,d0
	move.w	#$E0,d1
.loop	move.w	d1,(a1)+
	addq.w	#2,d1
	move.w	d2,(a1)+
	swap	d2
	move.w	d1,(a1)+
	addq.w	#2,d1
	move.w	d2,(a1)+
	add.w	#40*256,d2
	swap	d2
	dbf	d0,.loop
	move.l	#$1006200,(a1)+
	move.l	#$FFFFFFFE,(a1)

	lea	Palette(pc),a0
	lea	$180(a6),a1
	moveq	#32/2-1,d0
.setpal	move.l	(a0)+,(a1)+
	dbf	d0,.setpal

	move.l	#$298129C1,$8E(a6)
	move.l	#$3800D0,$92(a6)
	move.l	a3,$80(a6)
	bsr.w	WaitVBL
	move.w	#$8380,$96(a6)

; v1.3, stingray
; VBL based delay  replayed with resload_Delay
	moveq	#6*10,d0
	jsr	resload_Delay(a5)


; load game
	move.w	#$7FFF,$96(a6)
	move.l	#$89800,d0
	move.l	#$42000,d1
	moveq	#1,d2
	lea	$100.W,a0
	jsr	resload_DiskLoad(a5)

	lea	HiName(pc),a0
	jsr	resload_GetFileSize(a5)
	tst.l	d0
	beq.b	.nohigh
	lea	HiName(pc),a0
	lea	$CB0.W,a1
	tst.b	$FF.W
	bne.b	.ok
	addq.l	#8,a1			; PAL
.ok	jsr	resload_LoadFile(a5)

.nohigh	move.w	#$602A,$144.W

	tst.b	$FF.W
	beq.w	.PAL

	move.w	#$4EB9,($E86).W
	pea	SaveHighscore(pc)
	move.l	(sp)+,($E88).W
	move.w	#$4EF9,($6FB4).W
	pea	(Loader,pc)
	move.l	(sp)+,($6FB6).W
	move.w	#$4EB9,($6FA).W
	pea	(GetKey,pc)
	move.l	(sp)+,($6FC).W
	move.w	#$4EB9,($810).W
	pea	(CheckQuit,pc)
	move.l	(sp)+,($812).W
	move.w	#$4EB9,($4FBC).W
	pea	(GetKey,pc)
	move.l	(sp)+,($4FBE).W
	move.w	#$4EB9,($6188).W
	pea	(GetKey,pc)
	move.l	(sp)+,($618A).W
	move.w	#$4EB9,($7070).W
	pea	(CheckQuit,pc)
	move.l	(sp)+,($7072).W
	move.w	#$4EF9,($711C).W
	pea	(AckInt2,pc)
	move.l	(sp)+,($711E).W

; v1.3, stingray
; replace DMA wait routine in replayer and sample player
	pea	FixDMAWait(pc)
	move.w	#$4ef9,$100+$7916.w
	move.l	(a7),$100+$7916+2.w

	move.w	#$4ef9,$100+$6dde.w
	move.l	(a7)+,$100+$6dde+2.w


	bra.w	.go

.PAL	move.w	#$4EB9,($E8E).W
	pea	SaveHighscore(pc)
	move.l	(sp)+,($E90).W
	move.w	#$4EF9,($6FF0).W
	pea	(Loader,pc)
	move.l	(sp)+,($6FF2).W
	move.w	#$4EB9,($700).W
	pea	(GetKey,pc)
	move.l	(sp)+,($702).W
	move.w	#$4EB9,($816).W
	pea	(CheckQuit,pc)
	move.l	(sp)+,($818).W
	move.w	#$4EB9,($4FC4).W
	pea	(GetKey,pc)
	move.l	(sp)+,($4FC6).W
	move.w	#$4EB9,($61C4).W
	pea	(GetKey,pc)
	move.l	(sp)+,($61C6).W
	move.w	#$4EB9,($70AC).W
	pea	(CheckQuit,pc)
	move.l	(sp)+,($70AE).W
	move.w	#$4EF9,($7158).W
	pea	(AckInt2,pc)
	move.l	(sp)+,($715A).W


; v1.3, stingray
; replace DMA wait routine in replayer and sample player
	pea	FixDMAWait(pc)
	move.w	#$4ef9,$100+$7952.w
	move.l	(a7),$100+$7952+2.w

	move.w	#$4ef9,$100+$6e1a.w
	move.l	(a7)+,$100+$6e1a+2.w
	


.go
	jmp	$100.W


FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d1	
.loop	move.b	$dff006,d0
.wait	cmp.b	$dff006,d0
	beq.b	.wait
	dbf	d1,.loop
	movem.l	(a7)+,d0/d1
	rts


AckInt2
	move.w	#8,$DFF09C
	move.w	#8,$DFF09C
	movem.l	(sp)+,d0-d7/a0-a6
	rte

GetKey	move.b	$BFEC01,d5
	bra.b	lbC00031A

CheckQuit
	move.b	$BFEC01,d1
lbC00031A
	move.l	d0,-(sp)
	move.b	($BFEC01),d0
	ror.b	#1,d0
	not.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	.quit
	move.l	(sp)+,d0
	rts

.quit
	pea	(-1).W
	move.l	(resload,pc),-(sp)
	addq.l	#4,(sp)
	rts

Loader	movem.l	d0-d2/a0-a2,-(sp)
	move.l	d1,a2
	move.l	(a2)+,d0
	move.l	(a2)+,d1
	moveq	#1,d2
	move.l	a4,a0
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(sp)+,d0-d2/a0-a2
	rts

SaveHighscore
	move.l	#284,d0
	lea	HiName(pc),a0
	lea	$CB0.W,a1
	tst.b	$FF.W
	bne.b	.ok
	addq.l	#8,a1			; PAL
.ok	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)
	addq.l	#4,(sp)
	rts


WaitVBL
	btst	#0,5(a6)
	beq.b	WaitVBL
.wait	btst	#0,5(a6)
	bne.b	.wait
	rts

AckLev1
	move.w	#7,$DFF09C
	move.w	#7,$DFF09C
	rte

AckLev2
	move.w	#8,$DFF09C
	move.w	#8,$DFF09C
	rte

AckVBI
	move.w	#$70,$DFF09C
	move.w	#$70,$DFF09C
	rte

AckLev4
	move.w	#$780,$DFF09C
	move.w	#$780,$DFF09C
	rte

AckLev5
	move.w	#$1800,$DFF09C
	move.w	#$1800,$DFF09C
	rte

AckLev6
	move.w	#$2000,$DFF09C
	move.w	#$2000,$DFF09C
	rte

Palette
	DC.W	0
	DC.W	$FFF
	DC.W	$FDD
	DC.W	$EBB
	DC.W	$D99
	DC.W	$C77
	DC.W	$B55
	DC.W	$A44
	DC.W	$933
	DC.W	$822
	DC.W	$FF
	DC.W	$DD
	DC.W	$BB
	DC.W	$FF0
	DC.W	$A00
	DC.W	$D00
	DC.W	$F30
	DC.W	$FAF
	DC.W	$F4F
	DC.W	$B0C
	DC.W	$4D
	DC.W	$6F
	DC.W	$9F
	DC.W	$CF
	DC.W	$DDE
	DC.W	$BBC
	DC.W	$99A
	DC.W	$778
	DC.W	$AA
	DC.W	$99
	DC.W	$88
	DC.W	$223

resload	DC.L	0

	END

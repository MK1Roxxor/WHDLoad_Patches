; v1.2, stingray
; 21-Sep-2018: - code optimised and made pc-relative
;	       - started to add support for a different version
;	       - "auto-fix blitter waits" routine coded
;
; 22-Sep-2018  - part 2 ("BON2") patched
;
; 23-Sep-2018  - uses WHDLoad v17+ features now (config)
;	       - blitter wait patches can be disabled with CUSTOM2
;	       - highscore load/save for V2 added
;	       - highscore saving disable if trainer is used
;	       - some more code optimising
;	       - trainer option for V2 added
;	       - 68000 quitkey support for V1
;	       - update finished for now but patch should be redone one day


	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
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

HEADER
_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	_dir-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	0			;ws_ExpMem
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
	dc.b	"C1:B:Enable Trainer;"
	dc.b	"C2:B:Disable Blitter Waits"
	dc.b	0

_dir		IFD	DEBUG
		dc.b	"SOURCES:WHD_Slaves/Hammerfist/"
		ENDC
		dc.b	"data",0
_name		dc.b	"Hammerfist",0
_copy		dc.b	"1990 Vivid Image",0
_info		dc.b	"installed & fixed by Bored Seal & StingRay",10
		dc.b	"V1.2 (23-Sep-2018)",0

		even


PatchV2	lea	PLBOOT(pc),a0
	lea	$4f130,a1
	jsr	resload_Patch(a2)
	jmp	$6e5ba


PLBOOT	PL_START
	PL_P	$1f5b2,AckVBI
	PL_P	$1f580,AckLev2
	PL_PSA	$1f5de,.load,$1f640		; load BOND
	PL_P	$1f656,.run

	PL_END

.load	lea	file2(pc),a0
	lea	$400.w,a1
	bsr	LoadFile
	cmp.w	#$6af4,d0		; BarryB
	beq.b	.ok
	cmp.w	#$7d18,d0		; SPS 1358
	bne.w	Unsupported

.ok	lea	PLBOND(pc),a0
	lea	$400.w,a1

	move.l	a1,a5
	move.l	a5,a6
	add.l	#$c3e4,a6
	bsr.b	FixBlit_FB
	

	bsr	Trainer_LEV1

	move.l	_resload(pc),a2
	jmp	resload_Patch(a2)

.run	bsr	PicWait

	lea	$100.w,a0
	move.l	#-2,(a0)
	move.l	a0,$dff080

	jmp	$404.w


; a5.l: start
; a6.l: end

FixBlit_FB
	move.l	NOBLITWAITS(pc),d0
	bne.b	.exit

.loop	move.w	(a5),d0
	and.w	#~15,d0			; instruction without register
	cmp.w	#$33c0,d0		; move.w x,$dff058
	bne.b	.noblit	
	cmp.l	#$dff058,2(a5)
	bne.b	.noblit

	move.w	(a5),d0
	and.w	#15,d0			; register only
	add.w	d0,d0
	lea	.TAB(pc),a4
	add.w	(a4,d0.w),a4
	move.w	#$4eb9,(a5)+
	move.l	a4,(a5)


.noblit	addq.w	#2,a5

.next	cmp.l	a5,a6
	bcc.b	.loop
.exit	rts

.TAB	dc.w	WaitBlitD0-.TAB
	dc.w	WaitBlitD1-.TAB
	dc.w	WaitBlitD2-.TAB
	dc.w	WaitBlitD3-.TAB
	dc.w	WaitBlitD4-.TAB
	dc.w	WaitBlitD5-.TAB
	dc.w	WaitBlitD6-.TAB
	dc.w	WaitBlitD7-.TAB
	dc.w	WaitBlitA0-.TAB
	dc.w	WaitBlitA1-.TAB
	dc.w	WaitBlitA2-.TAB
	dc.w	WaitBlitA3-.TAB
	dc.w	WaitBlitA4-.TAB
	dc.w	WaitBlitA5-.TAB
	dc.w	WaitBlitA6-.TAB
	dc.w	WaitBlitA7-.TAB
	

WaitBlitD0
	move.w	d0,$dff058
	bra.b	WaitBlit

WaitBlitD1
	move.w	d1,$dff058
	bra.b	WaitBlit

WaitBlitD2
	move.w	d2,$dff058
	bra.b	WaitBlit

WaitBlitD3
	move.w	d3,$dff058
	bra.b	WaitBlit

WaitBlitD4
	move.w	d4,$dff058
	bra.b	WaitBlit

WaitBlitD5
	move.w	d5,$dff058
	bra.b	WaitBlit

WaitBlitD6
	move.w	d6,$dff058
	bra.b	WaitBlit

WaitBlitD7
	move.w	d7,$dff058
	bra.b	WaitBlit

WaitBlitA0
	move.w	a0,$dff058
	bra.b	WaitBlit

WaitBlitA1
	move.w	a1,$dff058
	bra.b	WaitBlit

WaitBlitA2
	move.w	a2,$dff058
	bra.b	WaitBlit

WaitBlitA3
	move.w	a3,$dff058
	bra.b	WaitBlit

WaitBlitA4
	move.w	a4,$dff058
	bra.b	WaitBlit

WaitBlitA5
	move.w	a5,$dff058
	bra.b	WaitBlit

WaitBlitA6
	move.w	a6,$dff058
	bra.b	WaitBlit

WaitBlitA7
	move.w	a7,$dff058
	
WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts


PLBOND	PL_START
	PL_P	$17ae,AckVBI
	PL_PSS	$1636,.InitLev2,2
	PL_R	$1856
	PL_P	$a7e,.patchPart2
	;PL_SA	4,$a6a			; skip to part 2

	PL_PS	$248,.loadhigh
	PL_PSS	$970,.savehigh,2

	;PL_W	$18e6,1


	PL_IFC2
	PL_ELSE
	PL_PSS	$8200,wblit,2
	PL_PSS	$8212,wblit,2
	PL_PSS	$8224,wblit,2
	PL_P	$8230,wblit2
	PL_PSS	$127a,wblit3,2
	PL_PSS	$1288,wblit3,2
	PL_PSS	$1296,wblit3,2
	PL_PS	$129e,wblit4
	PL_PS	$5e04,wblit5
	PL_PS	$5e16,wblit5
	PL_PS	$5e28,wblit5
	PL_PSS	$5e32,wblit6,2
	PL_ENDIF
	PL_END

.loadhigh
	movem.l	d0-a6,-(a7)
	lea	hiscore(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nofile
	lea	hiscore(pc),a0
	lea	$400+$11f99,a1
	jsr	resload_LoadFile(a2)
.nofile

	movem.l	(a7)+,d0-a6
	lea	$dff1a0,a0
	rts

.savehigh
	move.l	trainer(pc),d0
	bne.b	.nosave
	lea	hiscore(pc),a0
	lea	$400+$11f99,a1
	move.l	#$1209a-$11f99,d0
	move.l	_resload(pc),a2
	jsr	resload_SaveFile(a2)
.nosave	move.b	#1,$400+$4ed42
	rts


.patchPart2
	lea	file3(pc),a0		; BON2
	lea	$400.w,a1
	bsr	LoadFile
	cmp.w	#$6d8e,d0
	bne.w	Unsupported
	lea	PLBON2(pc),a0
	lea	$400.w,a1

	move.l	a1,a5
	move.l	a5,a6
	add.l	#$c3e4,a6
	bsr	FixBlit_FB

	bsr	Trainer_LEV2

	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$404.w
	

.InitLev2
	lea	KbdCust(pc),a0
	pea	.StoreKey(pc)
	move.l	(a7)+,(a0)
	bra.w	SetLev2IRQ

.StoreKey
	move.b	Key(pc),d0
	jmp	$400+$183a.w



wblit	bsr	WaitBlit
	lea	40*200(a0),a0
	lea	40*200(a1),a1
	rts

wblit2	move.w	a1,-2(a3)
	move.w	d0,(a3)
	bra.w	WaitBlit

wblit3	bsr	WaitBlit
	lea	40*200(a1),a1
	lea	40*200(a2),a2
	rts

wblit4	move.w	a2,(a4)
	move.w	a1,(a3)
	move.w	d0,(a6)
	bra.w	WaitBlit

wblit5	bsr	WaitBlit
	lea	40*200(a3),a3
	move.l	a2,(a5)
	rts

wblit6	move.w	a3,6(a5)
	move.w	d7,8(a5)
	bra.w	WaitBlit



PLBON2	PL_START
	PL_P	$17a2,AckVBI
	PL_PSS	$162a,.InitLev2,2
	PL_R	$184a

	PL_PS	$240,.loadhigh
	PL_PSS	$968,.savehigh,2


	PL_IFC2
	PL_ELSE
	PL_PSS	$81e0,wblit,2
	PL_PSS	$81f2,wblit,2
	PL_PSS	$8204,wblit,2
	PL_P	$8210,wblit2
	PL_PSS	$126e,wblit3,2
	PL_PSS	$127c,wblit3,2
	PL_PSS	$128a,wblit3,2
	PL_PS	$1292,wblit4
	PL_PS	$5cac,wblit5
	PL_PS	$5cbe,wblit5
	PL_PS	$5cd0,wblit5
	PL_PSS	$5cda,wblit6,2
	PL_ENDIF
	PL_END

.loadhigh
	movem.l	d0-a6,-(a7)
	lea	hiscore(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nofile
	lea	hiscore(pc),a0
	lea	$400+$135dd,a1
	jsr	resload_LoadFile(a2)
.nofile

	movem.l	(a7)+,d0-a6
	lea	$dff1a0,a0
	rts

.savehigh
	move.l	trainer(pc),d0
	bne.b	.nosave
	lea	hiscore(pc),a0
	lea	$400+$11f99,a1
	move.l	#$136de-$135dd,d0
	move.l	_resload(pc),a2
	jsr	resload_SaveFile(a2)
.nosave	move.b	#1,$4f142
	rts


.InitLev2
	lea	KbdCust(pc),a0
	pea	.StoreKey(pc)
	move.l	(a7)+,(a0)
	bra.w	SetLev2IRQ

.StoreKey
	move.b	Key(pc),d0
	jmp	$400+$182e.w



AckLev2	move.w	#1<<3,$dff09c
	move.w	#1<<3,$dff09c
	rte

AckVBI	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte

QUIT	pea	(TDREASON_OK).w
EXIT	move.l	_resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)


KillSys	move.w	#$7fff,$dff09a
	bsr.b	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	rts


WaitRaster
.wait	btst	#0,$dff005
	beq.b	.wait
.wait2	btst	#0,$dff005
	bne.b	.wait2
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
	beq.w	.end

	btst	#3,$d00(a1)			; KBD irq?
	beq.b	.end

	lea	Key(pc),a2
	moveq	#0,d0
	move.b	$c00(a1),d0
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)+
	or.b	#1<<6,$e00(a1)			; set output mode

	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT

	move.l	(a2)+,d1
	beq.b	.nocustom
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.nocustom
	

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



Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine


_Start		lea	(_resload,pc),a1
		move.l	a0,(a1)
		move.l	a0,a2
                lea     (_tags,pc),a0
                jsr     (resload_Control,a2)

		lea	file1(pc),a0		; ABR2
		lea	$4f130,a1
		bsr	LoadFile

	cmp.w	#$7504,d0
	beq.w	PatchV2

		cmp.w	#$15a6,d0
		bne.w	Unsupported



		move.w	#$4ef9,$6e72e
		pea	Patch_LEV1(pc)
		move.l	(sp)+,$6e730
		jmp	$6e5ba

Patch_LEV1	lea	file2(pc),a0		; BOND
		lea	$400.w,a1
		bsr	LoadFile
		cmp.w	#$7d18,d0
		bne.w	Unsupported

		lea	$4f130,a1		;simulate loader routines
		lea	$7c000,a0
		move.w	#$7d0,d0
Restore		move.l	(a0)+,(a1)+
		dbra	d0,Restore
		moveq	#8,d4

		lea	$1a56,a2		;fix problem with overwritten copperlist
		lea	SetCopper(pc),a3
		bsr	PatchNOPJSR

		lea	$1c56,a2		;short delay
		lea	BeamDelay(pc),a3
		bsr	PatchNOPJSR

	move.l	NOBLITWAITS(pc),d0
	bne.w	.skip
		bsr	FixBlit

		lea	BlitFix_1(pc),a3
		lea	$1678,a2
		bsr	PatchJSR
		lea	$1686,a2
		bsr	PatchJSR
		lea	$1694,a2
		bsr	PatchJSR
		lea	BlitFix_11(pc),a3
		lea	$169e,a2
		bsr	PatchJSR

		lea	BlitFix_2(pc),a3
		lea	$85fe,a2
		bsr	PatchJSR
		lea	$8610,a2
		bsr	PatchJSR
		lea	$8622,a2
		bsr	PatchJSR
		lea	BlitFix_22(pc),a3
		lea	$8630,a2
		bsr	PatchJSR

		lea	BlitFix_3(pc),a3
		lea	$6200.w,a2
		bsr	PatchNOPJSR
		lea	$6212.w,a2
		bsr	PatchNOPJSR
		lea	$6224.w,a2
		bsr	PatchNOPJSR
		lea	BlitFix_33(pc),a3
		lea	$6232.w,a2
		bsr	PatchNOPJSR

		lea	$4f496,a2		;insert delays in sound routines
		lea	SndFix1(pc),a3
		bsr	PatchJSR

		lea	$4fb82,a2
		lea	SndFix2(pc),a3
		bsr	PatchJSR
		lea	$4fb8c,a2
		bsr	PatchJSR
.skip

		lea	$d82.w,a2		;highscore operator
		lea	SaveHi_L1(pc),a3
		bsr	PatchNOPJMP

		bsr	LoadHi_L1
		bsr	PicWait

		pea	Patch_LEV2(pc)
		move.l	(sp)+,$e90.w

	bsr.b	Trainer_LEV1

NoTrainer	jmp	$404.w
		;jmp	$e7e			;skip level 1 - for developer purposes

Trainer_LEV1
	move.l	d0,-(a7)
	move.l	trainer(pc),d0
	beq.b	.notrainer

		MOVE.B	#$4A,$6F38.w
		MOVE.B	#$4A,$6F40.w
		MOVE.B	#$4A,$6F70.w
		MOVE.B	#$4A,$6F7C.w
		CLR.W	$955C
		CLR.W	$9570

		move.w	#$4e71,d0
		move.w	d0,$3fba.w
		move.w	d0,$3ff0.w
		move.w	d0,$9ace
.notrainer
	move.l	(a7)+,d0
	rts




Patch_LEV2	lea	file3(pc),a0		; BON2
		lea	$400.w,a1
		bsr	LoadFile
		cmp.w	#$16fd,d0
		bne	Unsupported

		bsr	LoadHi_L2
		bsr	PicWait
		
		lea	$1c4a.w,a2		;short delay
		lea	BeamDelay(pc),a3
		bsr	PatchNOPJSR


	move.l	NOBLITWAITS(pc),d0
	bne.w	.skip
		bsr	FixBlit

		lea	BlitFix_1(pc),a3
		lea	$166c.w,a2
		bsr	PatchJSR
		lea	$167a.w,a2
		bsr	PatchJSR
		lea	$1688.w,a2
		bsr	PatchJSR
		lea	BlitFix_11(pc),a3
		lea	$1692.w,a2
		bsr	PatchJSR

		lea	BlitFix_2(pc),a3
		lea	$85de,a2
		bsr	PatchJSR
		lea	$85f0,a2
		bsr	PatchJSR
		lea	$8602,a2
		bsr	PatchJSR
		lea	BlitFix_22(pc),a3
		lea	$8610,a2
		bsr	PatchJSR

		lea	BlitFix_3(pc),a3
		lea	$60a8.w,a2
		bsr	PatchNOPJSR
		lea	$60ba.w,a2
		bsr	PatchNOPJSR
		lea	$60cc.w,a2
		bsr	PatchNOPJSR
		lea	BlitFix_33(pc),a3
		lea	$60da.w,a2
		bsr	PatchNOPJSR
.skip

		lea	$d7a.w,a2
		lea	SaveHi_L2(pc),a3
		bsr	PatchNOPJMP

	bsr.b	Trainer_LEV2

NoTrainerL2	jmp	$404.w

Trainer_LEV2
	move.l	d0,-(a7)
	move.l	trainer(pc),d0
	beq.b	.notrainer

		MOVE.B	#$4A,$6FAA.w
		MOVE.B	#$4A,$6FB2.w
		MOVE.B	#$4A,$6FE2.w
		MOVE.B	#$4A,$6FEE.w
		CLR.W	$954E
		CLR.W	$9562

		move.w	#$4e71,d0
		move.w	d0,$3FF8
		move.w	d0,$402e
		move.w	d0,$9AC0
.notrainer
	move.l	(a7)+,d0
	rts


SndFix1		bsr.w	BeamDelay
		move.w	d5,$dff096
		bra.w	BeamDelay

SndFix2		move.w	d1,$dff096
		bra.w	BeamDelay

PatchJSR	move.w	#$4eb9,(a2)+
Patch_Sub	move.l	a3,(a2)+
		rts

PatchNOPJSR	move.l	#$4e714eb9,(a2)+
		bra.w	Patch_Sub

PatchNOPJMP	move.l	#$4e714ef9,(a2)+
		bra.w	Patch_Sub

SetCopper	move.l	#$fffffffe,$4.w		;create and start empty copperlist
		move.l	#$4,$dff080
		tst.w	$dff088
		move.w	#$87e0,$dff096
		rts

PicWait		movem.l	d0-d7/a0-a6,-(sp)
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

FixBlit		lea	BlitFixD0(pc),a4
		move.w	#$33c0,d3
		bsr.b	FindBlit

		lea	BlitFixD5(pc),a4
		move.w	#$33c5,d3
		bsr.b	FindBlit

		lea	BlitFixD6(pc),a4
		move.w	#$33c6,d3
		bsr.b	FindBlit

		lea	BlitFixD7(pc),a4
		move.w	#$33c7,d3
		bsr.b	FindBlit
		rts

;a5.l - odkud hledat
;d3.w - kod move.w dx,$dff058
;a4.l - fixla rutina
;d0.w - pocet wordu (implicitni)

FindBlit	lea	$1600.w,a5		;default nastaveni
		move.w	#$5000,d0
FindBL_loop	move.w	(a5),d2
		cmp.w	d3,d2
		bne.b	skip
		cmp.l	#$DFF058,2(a5)
		bne.b	skip
		move.w	#$4eb9,(a5)
		move.l	a4,2(a5)
skip		lea	2(a5),a5
		dbra	d0,FindBL_loop
		rts

BlitFixD7	move.w	d7,$dff058
BlitWait	btst	#6,$dff002
		bne.b	BlitWait
		rts

BlitFixD0	move.w	d0,$dff058
		bra.b	BlitWait

BlitFixD6	move.w	d6,$dff058
		bra.b	BlitWait

BlitFixD5	move.w	d5,$dff058
		bra.b	BlitWait

BlitFix_1	move.w	d0,(a6)
		lea	$1f40(a1),a1
		bra.b	BlitWait

BlitFix_11	move.w	a2,(a4)
		move.w	a1,(a3)
		move.w	d0,(a6)
		bra.b	BlitWait

BlitFix_2	move.w	d0,(a3)
		lea	$1f40(a0),a0
		bra.b	BlitWait

BlitFix_22	move.w	a1,(-2,a3)
		move.w	d0,(a3)
		bra.b	BlitWait

BlitFix_3	move.w	d7,8(a5)
		lea	$1f40(a3),a3
		bra.b	BlitWait

BlitFix_33	move.w	a3,6(a5)
		move.w	d7,8(a5)
		bra.b	BlitWait

BeamDelay
	cmp.b	HEADER+ws_keyexit(pc),d0	; kludge
	beq.w	QUIT

		move.l  d0,-(sp)
		moveq	#2,d0
BM_1		move.w  d0,-(sp)
		move.b	$dff006,d0	; VPOS
BM_2		cmp.b	$dff006,d0
		beq	BM_2
		move.w	(sp)+,d0
		dbf	d0,BM_1
		move.l	(sp)+,d0
		rts

LoadFile	move.l	a1,a5
		move.l	(_resload,pc),a2
		jsr	(resload_LoadFile,a2)

		move.l	a5,a0
		jmp	(resload_CRC16,a2)

LoadHi_L1	movem.l	d0-d7/a0-a6,-(sp)
		bsr.b	Params_L1
		bsr.b	CheckFile
		bsr.b	Params_L1
		bra.b	LoadHi

LoadHi_L2	movem.l	d0-d7/a0-a6,-(sp)
		bsr.b	Params_L2
		bsr.b	CheckFile
		bsr.b	Params_L2
LoadHi		jsr	(resload_LoadFile,a2)
NoHisc		movem.l	(sp)+,d0-d7/a0-a6
		rts

CheckFile	jsr	(resload_GetFileSize,a2)
                tst.l	d0
		bne.b	HiscFound
		lea	4(sp),sp
		bra.b	NoHisc
HiscFound	rts

Params_L2	lea	$139dd,a1
		bra	Params

Params_L1	lea	$12399,a1
Params		lea	hiscore(pc),a0
		move.l	(_resload,pc),a2
		rts

SaveHi_L1	movem.l	d0-d7/a0-a6,-(sp)
	move.l	trainer(pc),d0
	bne.b	.nosave
		bsr.b	Params_L1
		bsr.b	SaveHi
.nosave		movem.l	(sp)+,d0-d7/a0-a6
		jsr	$312a.w
		jmp	$84e.w

SaveHi_L2	movem.l	d0-d7/a0-a6,-(sp)
	move.l	trainer(pc),d0
	bne.b	.nosave
		bsr.b	Params_L2
		bsr.b	SaveHi
.nosave		movem.l	(sp)+,d0-d7/a0-a6
		jsr	$311e.w
		jmp	$846.w

SaveHi		move.l	#$105,d0
		jmp	(resload_SaveFile,a2)

Unsupported	pea	(TDREASON_WRONGVER).w
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

_resload	dc.l	0

_tags		dc.l	WHDLTAG_BUTTONWAIT_GET
button		dc.l    0
		dc.l	WHDLTAG_CUSTOM1_GET
trainer		dc.l    0
		dc.l	WHDLTAG_CUSTOM2_GET
NOBLITWAITS	dc.l	0
		dc.l	TAG_DONE

file1		dc.b	'ABR2',0
file2		dc.b	'BOND',0
file3		dc.b	'BON2',0
hiscore		dc.b	'HISC',0

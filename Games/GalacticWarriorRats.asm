; v1.2, stingray, 01-aug-2016
; - source adapted, 100% pc-relative code without needing opt. assembler
; - wrong audio volume patch fixed
; - WHDLoad v17+ features used
; - keyboard routines fixed
; - 68000 quitkey support

; V1.2a, stingray, 22.03.2021
; - keyboard patch in main game was incorrect, fixed

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i

HEADER
_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
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
	dc.w	.config-_base	; ws_config


.config	dc.b	"BW;"
	dc.b	"C1:B:Enable Trainer"
	dc.b	0	

_name		dc.b	"Galactic Warrior Rats",0
_copy		dc.b	"1992 Summit Software",0
_info		dc.b	"installed & fixed by Bored Seal & StingRay",10
		dc.b	"V1.2a (22-Mar-2021)",0
		even

_Start		lea	(_resload,pc),a1
		move.l	a0,(a1)
		move.l	a0,a2
                lea     (_tags,pc),a0
                jsr     (resload_Control,a2)

		move.l	#$383,d1
		move.l	#$10,d2
		lea	$5000.w,a0
		bsr	LoadRNCTracks

		move.l	a0,a5
		move.l	d2,d0
		mulu.w	#$200,d0
		jsr     (resload_CRC16,a2)
		cmp.w	#$20f4,d0
		bne	Unsupported

		move.w	#$4ef9,$f84(a5)
		pea	LoadRNCTracks(pc)
		move.l	(sp)+,$f86(a5)

		move.w	#$426d,$26e(a5)		;snoopfix

		pea	Patch_Pic(pc)
		move.l	(sp)+,$eac(a5)

		pea	Patch_1(pc)
		move.l	(sp)+,$e3e(a5)

		pea	Patch(pc)
		move.l	(sp)+,$14c(a5)

; stingray, 01.08.2016
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

		jmp	(a5)

Patch_Pic	bsr	PicWait
		jmp	$68200

Patch_1		move.w	#$4ef9,$68234
		pea	LoadRNCTracks(pc)
		move.l	(sp)+,$68236

		jmp	$68200

Patch		move.l	#$47f30000,$70b9a	;access faults, rom access
		move.w	#$6002,$736b0
		move.w	#$4e71,$736bc

		move.l	#$4e714eb9,d0
		move.l	d0,$68c90
		move.l	d0,$68ca8
		pea	BeamDelay(pc)
		move.l	(sp),$68c94
		move.l	(sp)+,$68cac

;snoop mode fixes (v1.1)
		move.w	#$426d,$71936		;clr.b $dff02e=>clr.w
		move.w	#$426d,$7bd7a		;clr.b $dff02e=>clr.w

;		move.w	#$3b6e,$68faa		;.b => .w (aud_vol)

; stingray, 01.08.2016
	move.w	#$4ef9,$68faa
	pea	FixAudXVol(pc)
	move.l	(a7)+,$68faa+2

		move.l	#$fffffffe,$76c78	;set empty copperlist end

		lea	trainer(pc),a0
		tst.l	(a0)
		beq.b	NoTrainer
		move.w	#$6006,$75424		;free shopping
		move.w	#$6002,$7392a		;unlim energy
		move.b	#$60,$7392e
NoTrainer


; stingray, 01.08.2016
	bsr	SetLev2IRQ
	lea	PLGAME(pc),a0
	lea	$6f000,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	lea	PL7bc00(pc),a0
	lea	$7bc00,a1
	jsr	resload_Patch(a2)
	

	jmp	$7bc00


PLBOOT	PL_START
	PL_PSS	$6e,.setkbd,4
	PL_R	$2d2
	PL_END

.setkbd	bsr	SetLev2IRQ
	move.l	a0,-(a7)
	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	move.l	(a7)+,a0
	rts

.kbdcust
	moveq	#0,d0
	move.b	RawKey(pc),d0
	lea	$1b000,a0
	jmp	$7e22c+($2be-$27c)



PL7bc00	PL_START
	PL_PSS	$72,.setkbd,4
	PL_SA	$1e0,$1fa
	PL_R	$200
	PL_PSS	$d30,.setkbd,4
	PL_END

.setkbd	bsr	SetLev2IRQ
	move.l	a0,-(a7)
	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	move.l	(a7)+,a0
	rts

.kbdcust
	moveq	#0,d0
	move.b	RawKey(pc),d0
	lea	$7e900,a0
	jmp	$7bc00+$1c8


PLGAME	PL_START
	PL_PSS	$26,.setkbd,4
	PL_SA	$2de,$2f8
	PL_R	$2fe
	PL_END
	

.setkbd	move.l	a0,-(a7)
	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	move.l	(a7)+,a0
	rts

.kbdcust
	moveq	#0,d0
	move.b	RawKey(pc),d0
	lea	$7dd00,a0
	jmp	$6f000+$2c6




LoadRNCTracks	movem.l a0-a2/d0-d3,-(sp)
		mulu.w	#$200,d1
		mulu.w	#$200,d2
		move.l	d1,d0
		move.l	d2,d1
		moveq	#1,d2
		move.l	(_resload,pc),a2
		jsr	(resload_DiskLoad,a2)
		movem.l (sp)+,a0-a2/d0-d3
		clr.l	d0
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

BeamDelay	moveq	#6,d0
BM_1		move.w  d0,-(sp)
		move.b	$dff006,d0
BM_2		cmp.b	$dff006,d0
		beq	BM_2
		move.w	(sp)+,d0
		dbf	d0,BM_1
		rts


FixAudXVol
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts


Unsupported	pea	(TDREASON_WRONGVER).w
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

_resload	dc.l	0
_tags		dc.l	WHDLTAG_BUTTONWAIT_GET
button		dc.l    0
		dc.l	WHDLTAG_CUSTOM1_GET
trainer		dc.l    0
		dc.l	TAG_DONE


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
.quit	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.exit	pea	(TDREASON_OK).w
	bra.b	.quit


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine

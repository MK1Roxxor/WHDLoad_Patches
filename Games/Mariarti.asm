; 26-Dec-2015, v1.2 (StingRay):
; - blitter wait patches skipped on 68000 machines
; - uses WHDLoad v17+ features (config)
; - 68000 quitkey support

; V1.3, February 2019 (StingRay):
; - all patch code move to patch lists
; - blitter waits done manually
; - NTSC compatible raster wait

; 11.04.2021
; - level 6 interrupt changed to trigger when timer B underflows, the
; game originally uses TOD ALARM which doesn't work for some reason and
; causes the music not to be replayed
; - minor size optimising

	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i


DEBUG

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
		dc.w	17
		dc.w	WHDLF_NoError|WHDLF_EmulTrap		;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		IFD	DEBUG
		dc.w	.dir-_base		;ws_CurrentDir
		ELSE
		dc.w	0			; ws_CurrentDir
		ENDC
		dc.w	0			;ws_DontCache
		dc.b	0			;ws_keydebug
		dc.b	$59			;ws_keyexit = F10
		dc.l	0			;ws_ExpMem
		dc.w	.name-_base		;ws_name
		dc.w	.copy-_base		;ws_copy
		dc.w	.info-_base		;ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-_base	; ws_config

.config	dc.b	"C1:B:Unlimited Lives"
	dc.b	0

.dir		IFD	DEBUG
		dc.b	"SOURCES:WHD_Slaves/MadProfessorMariarti",0
		ENDC
.name		dc.b	"Mad Professor Mariarti",0
.copy		dc.b	"1990 Krisalis",0
.info		dc.b	"installed & fixed by Bored Seal & StingRay",10
		dc.b	"V1.3 (12-Apr-2021)",0
		even

	CNOP	0,4

_Start		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later using
		move.l	a0,a2
                lea     (_tags,pc),a0
                jsr     (resload_Control,a2)

		move.l	#$f2b8,d0
		move.l	d0,a5
		move.l	#$61e00,d1
		move.l	#$370,d2
		bsr	Loader

		move.l	a5,a0
		move.l	d1,d0
		jsr     resload_CRC16(a2)
		cmp.w	#$1527,d0
		bne.w	Unsupported


	bsr	SetLev2IRQ

	lea	PLGAME(pc),a0
	lea	$f2b8,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

		jmp	$11d2(a5)		;skip resetproof stuff

PLGAME	PL_START
	PL_PSS	$168a,.setkbd,4
	PL_R	$28b2			; end level 2 interrupt code
	PL_R	$11dc			; disable memory check
	PL_R	$1260			; disable memory check
	PL_R	$436de			; disable drive check

	PL_IFC1
	PL_B	$4eb0,$4a
	PL_ENDIF	
	

	PL_P	$436f8,Loader
	PL_P	$7cf6,SaveHi


	PL_PS	$2e02,.wblit1
	PL_PSS	$2e60,.wblit2,2
	PL_PS	$2ec8,.wblit1
	PL_PSS	$2f26,.wblit2,2
	PL_PSS	$2f42,.wblit2,2
	PL_PSS	$2f5e,.wblit2,2
	PL_PS	$1860,.wblit1
	PL_PSS	$18b4,.wblit3,2
	PL_PSS	$18c4,.wblit3,2
	PL_PSS	$18d4,.wblit3,2
	PL_PSS	$18e4,.wblit3,2
	PL_PS	$1a64,.wblit1
	PL_PSS	$1ae2,.wblit3,2
	PL_PSS	$1af2,.wblit3,2
	PL_PSS	$1b02,.wblit3,2
	PL_PSS	$1b12,.wblit3,2
	PL_PS	$2d50,.wblit1
	PL_PSS	$2dae,.wblit2,2
	PL_PSS	$2dca,.wblit2,2
	PL_PSS	$2de6,.wblit2,2
	PL_P	$2e02,.wblit1
	PL_PSS	$2e60,.wblit2,2
	PL_PSS	$2e7c,.wblit2,2
	PL_PSS	$2e98,.wblit2,2
	PL_PS	$2ec8,.wblit1
	PL_PSS	$2f26,.wblit2,2
	PL_PSS	$2f42,.wblit2,2
	PL_PSS	$2f5e,.wblit2,2
	PL_PS	$3da6,.wblit1
	PL_PSS	$3df8,.wblit4,2
	PL_PSS	$3e0c,.wblit4,2
	PL_PSS	$3e20,.wblit4,2
	PL_PS	$3e88,.wblit1
	PL_PSS	$3ece,.wblit5,2
	PL_PSS	$3ee2,.wblit5,2
	PL_PSS	$3ef6,.wblit5,2
	PL_PS	$afc6,.wblit6
	PL_PSS	$b052,.wblit7,2
	PL_PSS	$b068,.wblit7,2
	PL_PSS	$b07e,.wblit7,2
	PL_PS	$e8f6,.wblit1
	PL_PSS	$e986,.wblit8,2
	PL_PSS	$e99a,.wblit8,2
	PL_PSS	$e9ae,.wblit8,2
	PL_PS	$e950,.wblit9
	PL_PSS	$98a4,.wblit10,2


	PL_PSA	$43ef0,.FixLev6,$43f1c

	PL_END


; use timer B instead of TOD
.FixLev6
	move.l	#1773447,d0	; PAL
	move.b	d0,$600(a6)
	lsr.w	#8,d0
	move.b	d0,$700(a6)

	move.b	#%10000010,$d00(a6)
	rts

	

.setkbd	lea	.kbdcust(pc),a1
	move.l	a1,KbdCust-.kbdcust(a1)
	rts

.kbdcust
	moveq	#0,d0
	move.b	RawKey(pc),d0
	jmp	$f2b8+$28a0		; call level 2 interrupt code

.wblit1	lea	$dff000,a2
	bra.b	WaitBlit

.wblit2	bsr.b	WaitBlit
	move.l	a1,$50(a2)
	move.l	a3,$4c(a2)
	rts

.wblit3	bsr.b	WaitBlit
	move.l	a1,$50(a2)
	move.l	a3,$54(a2)
	rts

.wblit4	bsr.b	WaitBlit
	move.l	a1,$54(a2)
	move.l	a0,$50(a2)
	rts

.wblit5	bsr.b	WaitBlit
	move.l	a1,$50(a2)
	move.l	a0,$54(a2)
	rts

.wblit6	lea	$dff000,a4
	bra.b	WaitBlit

.wblit7	bsr.b	WaitBlit
	move.l	a2,$48(a4)
	move.l	a3,$54(a4)
	rts

.wblit8	bsr.b	WaitBlit
	move.l	a3,$50(a2)
	move.l	a0,$54(a2)
	rts

.wblit9	bsr.b	WaitBlit
	move.l	a5,a3
	add.l	d5,a3
	add.l	d0,a3
	rts

.wblit10
	bsr.b	WaitBlit
	move.w	#-1,$dff046
	rts

WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts


Loader		movem.l	d0-d7/a0-a6,-(sp)
		movea.l	d0,a0
		move.l	d2,d0
		mulu.w	#$200,d0
		moveq	#1,d2
		move.l	(_resload,pc),a6
		jsr	(resload_DiskLoad,a6)
		movem.l	(sp)+,d0-d7/a0-a6
		moveq	#0,d0
		rts

LoadHi		movem.l	d0-d7/a0-a6,-(sp)
		bsr.b	Params
                jsr     (resload_GetFileSize,a2)
                tst.l   d0
                beq.b	NoHisc
		bsr.b	Params
		jsr	(resload_LoadFile,a2)
NoHisc		movem.l	(sp)+,d0-d7/a0-a6
		rts

Params		lea	hiscore(pc),a0
		lea	$171ce,a1
		move.l	(_resload,pc),a2
		rts

SaveHi		movem.l	d0-d7/a0-a6,-(sp)
		bsr.b	Params
		move.l	#$108,d0
		jsr	(resload_SaveFile,a2)
		movem.l	(sp)+,d0-d7/a0-a6
		jsr	$1085c
		moveq	#1,d0
		rts

Unsupported	pea	(TDREASON_WRONGVER).w
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

_resload	dc.l	0
_tags		dc.l	WHDLTAG_CUSTOM1_GET
trainer		dc.l    0

		dc.l	TAG_DONE

hiscore		dc.b	"Highs",0
		CNOP	0,4

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

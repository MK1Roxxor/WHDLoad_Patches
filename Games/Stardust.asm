;*---------------------------------------------------------------------------
;  :Program.	Stardust.asm
;  :Contents.	Slave for "Stardust" from Bloodhouse
;  :Author.	Mr.Larmer of Wanted Team, Bored Seal, Wepl, StingRay
;  :Id.		$Id: Stardust.asm 1.5 2017/11/13 13:37:52 wepl Exp wepl $
;  :History.	27.03.2000 - first release (Mr Larmer)
; (Bored Seal)  29.11.2000 - asteroids and menu access faults removed
;                          - highscore is saved to file now
;               02.12.2000 - disk access removed
;                          - password feature
;               10.12.2000 - tunnel 1 faults removed
;                          - tunnel 2 faults removed
;                          - tunnel 3 faults removed
;               11.12.2000 - tunnel 4 faults removed
;                          - special missions fixed
;               13.12.2000 - access fault in outro fixed
;                          - quit routine for outro added
;               19.12.2000 - intro - blitter waits added
;                          - boot - cacr+vbr access removed
;                          - skip intro option added (custom1)
;               09.01.2001 - my bug in loader removed (intro sound works now)
;                          - outro quit routine removed - useless
;			   - game - 4x blitter waits added
;		25.06.2006 Wepl
;			termination of taglist for resload_Control fixed to
;			work with WHDLoad v16.6
;			uses 'data' subdir
;		12.11.2017 StingRay
;			   - source is pc-relative now, no optimising
;			     assembler needed anymore
;			   - 68000 quitkey support (in main game only for
;			     the moment)
;			   - WHDLoad v17+ features used (config)
;		13.11.2017 - Bplcon0 color bit fixes
;			   - blitter wait added
;			   - support for fire 2 added
;			   - better 68000 quitkey support
;		26.12.2022 - crash when trying to quit after tunnel sequence
;			     fixed (game trashed the level 2 interrupt code)
;			   - graphics glitch fixed (copperlist 2 now used
;			     instead of copperlist 1 when applying the
;			     Bplcon0 color bit fixes)
;
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

		INCDIR	SOURCES:Include/
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"wart:st/stardust/Stardust.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

base
HEADER		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoKbd
		dc.l	$100000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-base	;ws_GameLoader
		dc.w	_dir-base	;ws_CurrentDir
		dc.w	0		;ws_DontCache
		dc.b	0		;ws_keydebug = none
		dc.b	$59		;ws_keyexit
		dc.l	0		;ws_ExpMem
		dc.w	_name-base	;ws_name
		dc.w	_copy-base	;ws_copy
		dc.w	_info-base	;ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"C1:B:Skip Intro;"
	dc.b	"C2:B:Enable Support for 2nd Fire Button;"
	dc.b	0


	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_dir		dc.b	"code:sources_wrk/whd_slaves/stardust/"
		dc.b	"data",0
_name		dc.b	"Stardust",0
_copy		dc.b	"1993 Bloodhouse",0
_info		dc.b	"installed & fixed by Mr.Larmer/Bored Seal/Wepl/StingRay",10
		dc.b	"V1.6 "
	IFD BARFLY
		INCBIN	"T:date"
	ELSE
		dc.b	"(26.12.2022)"
	ENDC
		dc.b	0





	EVEN

Start		lea	_resload(pc),a1
		move.l	a0,(a1)
		move.l	a0,a2
		lea     (_tags,pc),a0
		jsr     (resload_Control,a2)

		lea	$7000.w,a0
		move.l	a0,-(sp)
		moveq	#0,d0
		move.l	#$1600,d1
		moveq	#1,d2
		jsr	resload_DiskLoad(a2)
		move.l	(sp)+,a0

	move.l	SKIPINTRO(pc),d0
	beq.b	.noskip
	move.b	#$60,$18e(a0)		; skip intro
.noskip

		move.w	#$4eb9,$22a(a0)
		pea	PatchIntro(pc)
		move.l	(sp)+,$22c(a0)

		move.w	#$4ef9,$29C(a0)
		pea	PatchGame(pc)
		move.l	(sp)+,$29E(a0)

		move.w	#$4ef9,$686(a0)
		pea	Load(pc)
		move.l	(sp)+,$688(a0)

		move.w	#$602c,$158(a0)		;disk access
		move.w	#$600c,$d2(a0)		;vbr+cacr operation

		moveq	#0,d1			; attn flag
		move.l	a0,d6			; loader address
		move.l	#$7fc00,d7		; ext mem
		jmp	$C4(a0)

PatchGame	move.l	$782E4,a5
		move.w	#$F080,$4404(a5)	;remove access faults
		move.w	#$F084,$1778(a5)
		move.w	#$F084,$2e74(a5)

		move.w	#$f088,d0
		move.w	d0,$e816c
		move.w	d0,$e824a
		move.w	d0,$e82d2
		move.w	d0,$e835a
		move.w	d0,$e8446
		move.w	d0,$e8522
		move.w	d0,$e85aa
		move.w	d0,$e8632
		move.w	d0,$e86b4
		move.w	d0,$e86ea
		move.w	d0,$e87c6
		move.w	d0,$e88ba
		move.w	d0,$e893c
		move.w	d0,$e8972
		move.w	d0,$e8a4e
		move.w	d0,$e8b42
		move.w	d0,$e8bc4
		move.w	d0,$e8c1e
		move.w	d0,$e8cc0
		move.w	d0,$e8d08
		move.w	d0,$e8d9a
		move.w	d0,$e8dc6

		move.w	#$96,$19a0(a5)

		move.w	#$f09a,d0
		move.w	d0,$1224(a5)
		move.w	d0,$11b0(a5)
		move.w	d0,$11e8(a5)

		move.w	#$4EB9,$340(a5)
		pea	Decrunch(pc)
		move.l	(sp)+,$342(a5)

		move.w	#$4ef9,d0
		move.w	d0,$57C(a5)
		pea	Load(pc)
		move.l	(sp)+,$57E(a5)

		move.w	d0,$ED41A
		pea	LoadSaveHighs(pc)
		move.l	(sp)+,$ED41C

		move.w	d0,$6668(a5)
		move.w	d0,$ec7d0
		pea	GetAdr(pc)
		move.l	(sp),$ec7d2
		move.l	(sp)+,$666a(a5)

		move.w	#$4e75,$4016(a5)	;no cartridge check

		move.l	a5,a0			;80000
		lea	$f0000,a2
		move.w	#$4a2e,d1
		move.w	#$be02,d2
		moveq	#2,d3
		bsr	Replace

		moveq	#$e,d1
		bsr	Replace
		move.w	d3,$6522(a5)

		move.w	#$ac40,d1
		moveq	#$40,d3
		bsr	Repl2cod

		move.w	#$be42,d1
		moveq	#$42,d3
		bsr	Repl2cod

		move.w	#$e648,d1
		moveq	#$48,d3
		bsr	Repl2cod

		move.w	#$d44c,d1
		moveq	#$4c,d3
		bsr	Repl2cod

		move.w	#$c250,d1
		moveq	#$50,d3
		bsr	Repl2cod

		move.w	#$f854,d1
		moveq	#$54,d3
		bsr	Repl2cod
		move.w	d3,$60ae(a5)
		move.w	d3,$68b4(a5)
		move.w	d3,$7b48(a5)

		move.w	#$f458,d1
		moveq	#$58,d3
		bsr	Repl2cod
		move.w	d3,$60b4(a5)
		move.w	d3,$68b8(a5)
		move.w	d3,$87b4c

		move.w	#$ae60,d1
		moveq	#$60,d3
		bsr	Repl2cod

		move.w	#$bc62,d1
		moveq	#$62,d3
		bsr	Repl2cod

		move.w	#$9a64,d1
		moveq	#$64,d3
		bsr	Repl2cod

		move.w	#$b266,d1
		moveq	#$66,d3
		bsr	Repl2cod
		move.w	d3,$87b44
		move.w	d3,$60a8(a5)
		move.w	d3,$68b0(a5)

		move.w	#$f458,d1
		move.w	#$9a64,d2
		move.w	#$ae60,d3
		move.w	#$bc62,d4
		move.w	#$b266,d5
		move.w	#$ac40,d6
		move.w	#$be42,d7
		bsr	Replace2

		move.w	#$2d7c,d1
		move.w	#$ea44,d2
		moveq	#$44,d3
		bsr	Replace3

		move.w	#$c250,d2
		moveq	#$50,d3
		bsr	Replace3

		move.w	#$f854,d2
		moveq	#$54,d3
		bsr	Replace3

		move.w	#$2d79,d1
		move.w	#$e648,d2
		moveq	#$48,d3
		bsr	Replace3

		move.w	#$f854,d2
		moveq	#$54,d3
		bsr	Replace3
		move.w	d3,$e908a

		move.w	#$750,d1
		move.w	#$00df,d2
		move.w	#$f080,d3
		bsr	Replace4

		move.w	#$88c,d1
		move.w	#$00df,d2
		move.w	#$f080,d3
		bsr	Replace4

		move.w	#$6006,$8ac2c		;disk access
		bsr	LoadPass

		move.l	#$4e714eb9,d0
		move.l	d0,$e8224
		pea	PatchTun1(pc)
		move.l	(sp)+,$e8228

		move.l	d0,$e84fc
		pea	PatchTun2(pc)
		move.l	(sp)+,$e8500

		move.l	d0,$e87a0
		pea	PatchTun3(pc)
		move.l	(sp)+,$e87a4

		move.l	d0,$e8a28
		pea	PatchTun4(pc)
		move.l	(sp)+,$e8a2c

		move.w	d0,$e8ca0
		pea	PatchSM(pc)
		move.l	(sp)+,$e8ca2

		move.l	d0,$90bec
		move.l	d0,$88264
		pea	BlitFix3(pc)
		move.l	(sp),$90bf0
		move.l	(sp)+,$88268

		move.l	d0,$83ccc
		move.l	d0,$842cc
		pea	BlitFix4(pc)
		move.l	(sp),$83cd0
		move.l	(sp)+,$842d0

		move.w	#$4ef9,$12e(a5)
		pea	PatchOutro(pc)
		move.l	(sp)+,$130(a5)

;		move.w	#$4ef9,$9e(a5)		;enable outro
;		move.l	#$8011a,$a0(a5)





; v1.5, 12.11.2017, stingray
	lea	PLGAME(pc),a0
	move.l	a5,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

		jmp	(a5)



PLGAME	PL_START
	PL_PS	$442e,.checkquit2		; enable quit during game
	PL_PS	$6c9cc,.checkquit3		; enable quit during main menu

; open weapons menu with fire 2
	PL_IFC2
	PL_PSS	$4f04,.readjoy,2
	PL_PS	$4436,.checkjoy
	PL_PS	$4422,.forcekey
	PL_ENDIF

	PL_ORW	$76d5c+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$76f00+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$76f20+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$770a4+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$77174+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$77188+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$774b0+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$774c4+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$77924+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$77938+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$77a40+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$77ce0+2,1<<9			; set Bplcon0 color bit
	
	PL_ORW	$7ebfc+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$7ecd8+2,1<<9			; set Bplcon0 color bit

	PL_ORW	$f3c+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$fe8+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$1020+2,1<<9			; set Bplcon0 color bit
	PL_ORW	$1050+2,1<<9			; set Bplcon0 color bit

	PL_PSS	$1770,.fixcop,4


	PL_PS	$428a,.wblit

	PL_END

.checkquit3

	; 26.12.2022: Game installs a level 2 interrupt when the tunnel
	; sequence starts. The level 2 interrupt vector is not cleared when
	; the tunnel sequence ends, the code it points to will be trashed
	; though. This leads to crashes when trying to quit with F10.
	cmp.l	#$c24,$68.w
	bne.b	.ok
	bsr	SetLev2IRQ
.ok
	move.w	$dff01c,d0
	or.w	#1<<15|1<<3,d0			; enable level 2 interrupt
	move.w	d0,$dff09a

	bsr.b	.checkquit2

	move.l	$dff004,d0			; original code
	rts


.checkquit2
	move.b 	$bfec01,d0
	ror.b	d0
	not.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	move.b	$bfec01,d0
	rts

.forcekey
	move.b	$bfed01,d0
	move.l	a0,-(a7)
	lea	.fire2(pc),a0
	tst.b	(a0)
	beq.b	.normal
	bset	#3,d0			; force keyboard interrupt
.normal	move.l	(a7)+,a0
		
	rts



.wblit	add.w	d0,a4
	add.w	d0,a5
	move.w	d1,d0
	bra.w	BlitWait

.fixcop	lea	$400.w,a0
	or.w	#1<<9,$4+2(a0)
	or.w	#1<<9,$e0+2(a0)
	move.l	a0,$dff084
	rts

.checkjoy
	ror.b	#1,d0

	move.l	a0,-(a7)
	lea	.fire2(pc),a0
	tst.b	(a0)
	beq.b	.nobutton2

	tst.b	1(a0)
	beq.b	.read
	subq.b	#1,1(a0)		; decrease delay
	bra.b	.nobutton2
	

.read	moveq	#$40,d0			; force key code for space
	sf	(a0)
	addq.b	#5,1(a0)		; reset delay

.nobutton2
	move.l	(a7)+,a0

	cmp.b	#$40,d0			; original code
	rts


.readjoy
	move.w	#1<<4,$dff09c

	btst	#14,$dff016
	bne.b	.noFire2
	move.l	a0,-(a7)
	lea	.fire2(pc),a0
	st	(a0)
	move.l	(a7)+,a0

.noFire2
	move.w	#$cc00,$dff034
	rts

.fire2	dc.b	0
	dc.b	0			; delay



QUIT	pea	(TDREASON_OK).w
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts



PatchSM		movem.l	a0-a4/d0-d5,-(sp)
		move.w	#$96,$8f4.w
		move.w	#$f050,$30b0.w
		move.w	#$f058,$30b6.w

		move.w	#$40,$3094.w
		move.w	#$42,$309a.w
		move.w	#$64,$30a0.w
		move.w	#$66,$30a6.w
		move.w	#$54,$30e2.w

		lea	$178e.w,a1			;access fault fixes
		lea	$5000.w,a2
		moveq	#$e,d1
		move.w	#$802,d2
		moveq	#2,d3
		bsr	Replace

		move.w	#$2d7c,d1
		move.w	#$e44,d2
		moveq	#$44,d3
		bsr	Replace3

		movem.l	(sp)+,a0-a4/d0-d5
		move.w	$e8bf2,d3
		jmp	(a5)

PatchOutro	move.w	#2,$1358.w		;fix access fault
		jmp	$7d4.w

PatchTun4	movem.l	a0-a4/d0-d5,-(sp)
		move.w	#$6006,$1dde.w
		lea	$db0.w,a1		;access fault fixes
		lea	$6460.w,a2

		move.w	#$4a6d,d1
		move.w	#$602,d2
		moveq	#2,d3
		bsr	Replace
		moveq	#$e,d1
		bsr	Replace
		move.w	d3,$3de8
		move.w	d3,$45da

		move.w	#$440,d1
		moveq	#$40,d3
		bsr	Repl2cod

		move.w	#$642,d1
		moveq	#$42,d3
		bsr	Repl2cod

		move.w	#$848,d1
		moveq	#$48,d3
		bsr	Repl2cod

		move.w	#$84c,d1
		moveq	#$4c,d3
		bsr	Repl2cod

		move.w	#$650,d1
		moveq	#$50,d3
		bsr	Repl2cod

		move.w	#$a54,d1
		moveq	#$54,d3
		bsr	Repl2cod
		move.w	d3,$63e4

		move.w	#$e58,d1
		moveq	#$58,d3
		bsr	Repl2cod

		move.w	#$c60,d1
		moveq	#$60,d3
		bsr	Repl2cod

		move.w	#$e66,d1
		moveq	#$66,d3
		bsr	Repl2cod

		move.w	#$e58,d1
		move.w	#$a64,d2
		move.w	#$c60,d3
		move.w	#$c62,d4
		move.w	#$e66,d5
		move.w	#$642,d6
		move.w	#$440,d7
		bsr	Replace2

		move.w	#$2b7c,d1
		move.w	#$444,d2
		moveq	#$44,d3
		bsr	Replace3
		move.w	d3,$5e36
		move.w	d3,$63de
		bra	RunIt

PatchTun3	movem.l	a0-a4/d0-d5,-(sp)
		move.w	#$6006,$181a.w
		lea	$d40.w,a1		;access fault fixes
		lea	$6470.w,a2
		move.w	#$4a6d,d1
		move.w	#$202,d2
		moveq	#2,d3
		bsr	Replace
		moveq	#$e,d1
		bsr	Replace
		move.w	d3,$3d48
		move.w	d3,$460c

		move.w	#$c40,d1
		moveq	#$40,d3
		bsr	Repl2cod

		move.w	#$442,d1
		moveq	#$42,d3
		bsr	Repl2cod

		move.w	#$e48,d1
		moveq	#$48,d3
		bsr	Repl2cod

		move.w	#$64c,d1
		moveq	#$4c,d3
		bsr	Repl2cod

		move.w	#$250,d1
		moveq	#$50,d3
		bsr	Repl2cod

		move.w	#$c54,d1
		moveq	#$54,d3
		bsr	Repl2cod
		move.w	d3,$641e

		move.w	#$a58,d1
		moveq	#$58,d3
		bsr	Repl2cod

		move.w	#$260,d1
		moveq	#$60,d3
		bsr	Repl2cod

		move.w	#$866,d1
		moveq	#$66,d3
		bsr	Repl2cod

		move.w	#$a58,d1
		move.w	#$664,d2
		move.w	#$260,d3
		move.w	#$462,d4
		move.w	#$866,d5
		move.w	#$442,d6
		move.w	#$c40,d7
		bsr	Replace2

		move.w	#$2b7c,d1
		move.w	#$244,d2
		moveq	#$44,d3
		bsr	Replace3
		move.w	d3,$5e70
		move.w	d3,$6418
		bra	RunIt

PatchTun2	movem.l	a0-a4/d0-d5,-(sp)
		move.w	#$6006,$11e4.w		;disk access
		lea	$d30.w,a1		;access fault fixes
		lea	$6390.w,a2
		move.w	#$4a6d,d1
		move.w	#$202,d2
		moveq	#2,d3
		bsr	Replace
		moveq	#$e,d1
		bsr	Replace
		move.w	d3,$3d30
		move.w	d3,$454a

		move.w	#$840,d1
		moveq	#$40,d3
		bsr	Repl2cod

		move.w	#$e42,d1
		moveq	#$42,d3
		bsr	Repl2cod

		move.w	#$648,d1
		moveq	#$48,d3
		bsr	Repl2cod

		move.w	#$44c,d1
		moveq	#$4c,d3
		bsr	Repl2cod

		move.w	#$250,d1
		moveq	#$50,d3
		bsr	Repl2cod

		move.w	#$854,d1
		moveq	#$54,d3
		bsr	Repl2cod
		move.w	d3,$6358

		move.w	#$258,d1
		moveq	#$58,d3
		bsr	Repl2cod

		move.w	#$e60,d1
		moveq	#$60,d3
		bsr	Repl2cod

		move.w	#$866,d1
		moveq	#$66,d3
		bsr	Repl2cod

		move.w	#$258,d1
		move.w	#$a64,d2
		move.w	#$e60,d3
		move.w	#$e62,d4
		move.w	#$866,d5
		move.w	#$e42,d6
		move.w	#$840,d7
		bsr	Replace2

		move.w	#$2b7c,d1
		move.w	#$444,d2
		moveq	#$44,d3
		bsr	Replace3
		move.w	d3,$5dac
		move.w	d3,$6352

		bra	RunIt

PatchTun1	move.w	#$6006,$5832.w		;disk access
		movem.l	a0-a4/d0-d5,-(sp)
		lea	$7d0.w,a1		;access fault fixes
		lea	$bd28,a2
		move.w	#$4a6d,d1
		move.w	#$602,d2
		moveq	#2,d3
		bsr	Replace
		move.w	d3,$35f8.w
		move.w	d3,$3db4.w

		moveq	#$e,d1
		bsr	Replace

		move.w	#$0440,d1
		moveq	#$0040,d3
		bsr	Repl2cod
		move.w	#$0c40,d1
		bsr	Repl2cod

		move.w	#$be42,d1
		moveq	#$42,d3
		bsr	Repl2cod
		move.w	#$0242,d1
		bsr	Repl2cod

		move.w	#$848,d1
		moveq	#$48,d3
		bsr	Repl2cod

		move.w	#$84c,d1
		moveq	#$4c,d3
		bsr	Repl2cod

		move.w	#$650,d1
		moveq	#$50,d3
		bsr	Repl2cod

		move.w	#$654,d1
		moveq	#$54,d3
		bsr	Repl2cod
		move.w	d3,$5cf2

		move.w	#$e58,d1
		moveq	#$58,d3
		bsr	Repl2cod

		move.w	#$c60,d1
		moveq	#$60,d3
		bsr	Repl2cod

		move.w	#$a62,d1
		moveq	#$62,d3
		bsr	Repl2cod

		move.w	#$264,d1
		moveq	#$64,d3
		bsr	Repl2cod

		move.w	#$e66,d1
		moveq	#$66,d3
		bsr	Repl2cod

		move.w	#$e58,d1
		move.w	#$264,d2
		move.w	#$c60,d3
		move.w	#$a62,d4
		move.w	#$e66,d5
		move.w	#$440,d6
		move.w	#$242,d7
		bsr	Replace2

		move.w	#$2b7c,d1
		move.w	#$444,d2
		moveq	#$44,d3
		bsr	Replace3
		move.w	d3,$5426
		move.w	d3,$5cec
RunIt		movem.l	(sp)+,a0-a4/d0-d5
		movea.w	$ed406,a4
		jmp	(a5)

GetAdr		lea	$dff000,a6
		rts

Repl2cod	move.l	a1,a0		;opravuje $xxxxd1d1 => $xxxxd3d3
Hunt0		move.w	(a0),d5
		cmp.w	d1,d5
		bne.b	skip0
		move.w	-2(a0),d5
		cmp.w	#$2b40,d5
		blt.b	skip0
		cmp.w	#$3d50,d5
		bgt.b	skip0
		cmp.w	#$3001,d5
		beq.b	skip0
		cmp.w	#$303a,d5
		beq.b	skip0
		cmp.w	#$3404,d5
		beq.b	skip0
		move.w	d3,(a0)
skip0		lea	2(a0),a0
		cmp.l	a2,a0
		ble.b	Hunt0
		rts

Replace		move.l	a1,a0		;opravuje $D1D1D2D2 -> $D1D1D3D3
.Hunt		move.w	(a0)+,d5
		cmp.w	d1,d5
		bne.b	.skip
		move.w	(a0),d5
		cmp.w	d2,d5
		bne.b	.skip
		move.w	d3,(a0)
.skip		cmp.l	a2,a0
		ble.b	.Hunt
		rts

Replace2	move.l	a1,a0		;opravuje $3bxxXXXX0558
.Hunt1		cmp.w	#$3b7c,(a0)
		beq.b	.ast
		cmp.w	#$3b7a,(a0)
		beq.b	.ast
		cmp.w	#$3d7c,(a0)
		bne.b	.skip1
.ast		move.w	4(a0),d0
		cmp.w	d1,d0
		beq.b	.and4
		cmp.w	d2,d0
		beq.b	.and4
		cmp.w	d3,d0
		beq.b	.and4
		cmp.w	d4,d0
		beq.b	.and4
		cmp.w	d5,d0
		beq.b	.and4
		cmp.w	d6,d0
		beq.b	.and4
		cmp.w	d7,d0
		bne.b	.skip1
.and4		and.w	#$00FF,d0
		move.w	d0,4(a0)
.skip1		lea	2(a0),a0
		cmp.l	a2,a0
		ble.b	.Hunt1
		rts

Replace3	move.l	a1,a0		;D1D1xxxxXXXXD2D2 => D1D1xxxxXXXXD3D3
.Hunt2		move.w	(a0)+,d5
		cmp.w	d1,d5
		bne.b	.skip2
		move.w	4(a0),d5
		cmp.w	d2,d5
		bne.b	.skip2
		move.w	d3,4(a0)
.skip2		cmp.l	a2,a0
		ble.b	.Hunt2
		rts

Replace4	move.l	a1,a0		;$D1D1D2D2xxxx => D1D1D2D2D3D3
.Hunt4		move.w	(a0)+,d5
		cmp.w	d1,d5
		bne.b	.skip4
		move.w	(a0),d5
		cmp.w	d2,d5
		bne.b	.skip4
		move.w	d3,2(a0)
.skip4		cmp.l	a2,a0
		ble.b	.Hunt4
		rts

Decrunch	move.l	a2,-(sp)
		lea	Size(pc),a2
		move.l	a1,(a2)+
		move.l	6(a0),(a2)
		moveq	#12,d1
		subq.l	#4,sp
		lea	(sp),a2
.loop		move.l	4(a2),(a2)+
		dbf	d1,.loop
		move.l	(sp)+,a2
		addq.l	#6,a0
		move.l	(a0)+,d1
		move.l	(a0)+,d2
		pea	Back(pc)
		move.l	(sp)+,$30(sp)
		rts

Back		movem.l	a0-a1,-(sp)
		lea	Size(pc),a1
		move.l	(a1)+,a0
		move.l	(a1),a1
		add.l	a0,a1

.loop		cmp.l	#$48E7E040,(a0)
		bne.b	.next
		cmp.l	#$34197000,4(a0)
		bne.b	.next
		move.w	#$4EF9,(a0)
		pea	Load(pc)
		move.l	(sp)+,2(a0)

.next		cmp.l	#$5C882218,(a0)
		bne.b	.next2
		cmp.w	#$2418,4(a0)
		bne.b	.next2
		move.w	#$4EB9,(a0)
		pea	Decrunch(pc)
		move.l	(sp)+,2(a0)

.next2		addq.l	#2,a0
		cmp.l	a0,a1
		bne.b	.loop
		movem.l	(sp)+,a0-a1
		tst.l	d0
		rts

Size		dc.l	0,0

Load		movem.l	d0/d2-a6,-(sp)
		moveq	#0,d2
		move.w	(a1)+,d2
		addq.b	#1,d2
		move.l	(a1),d0
		lsr.l	#8,d0
		sub.l	#$230,d0
		move.l	2(a1),d1
		and.l	#$FFFFF,d1
		move.l	d1,-(sp)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		move.l	(sp)+,d1
		movem.l	(sp)+,d0/d2-a6
		rts

LoadPass	movem.l	d0-a6,-(sp)
		bsr	Params
		lea	password(pc),a0
		move.l	a0,a5
		jsr     (resload_GetFileSize,a2)
		tst.l	d0
		beq.b	.NoPass
		move.l	a5,a0
		lea	$ece6c,a1
		jsr	(resload_LoadFile,a2)
.NoPass		movem.l	(sp)+,d0-a6
		rts

LoadSaveHighs	movem.l	d0-a6,-(sp)
		tst.w	$ED414
		bne.b	.save

		move.l	a0,a5
		bsr	Params
                jsr     (resload_GetFileSize,a2)
                tst.l   d0
                beq     end
		bsr	Params
		move.l	a5,a1
		jsr	(resload_LoadFile,a2)
		bra	end

.save		moveq	#$4a,d0			;len
		lea	(a0),a1			;address
		bsr	Params
		jsr	(resload_SaveFile,a2)
		lea	password(pc),a0
		lea	$ece6c,a1
		moveq	#12,d0
		jsr	(resload_SaveFile,a2)
end		movem.l	(sp)+,d0-a6
		moveq	#0,d0
		rts

Params		lea	_savename(pc),a0
		move.l	_resload(pc),a2
		rts
PatchIntro	lea	$80000,a4
		move.l	#$4e714eb9,$275a(a4)
		pea	BlitFix(pc)
		move.l	(sp)+,$275e(a4)

		move.w	#$4ef9,$277e(a4)
		pea	BlitFix2(pc)
		move.l	(sp)+,$2780(a4)

	movem.l	d0-a6,-(a7)
	bsr	SetLev2IRQ
	lea	PLINTRO(pc),a0
	move.l	a4,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6


		jmp	(a4)

PLINTRO	PL_START
	PL_ORW	$21e6+2,1<<3		; enable level 2 interrupts
	PL_END


BlitFix		bsr.b	BlitWait
		move.l	$86ef0,$dff054
		rts

BlitFix2	move.w	#$202c,$dff058
BlitWait	btst	#6,$dff002
		bne.b	BlitWait
		rts

BlitFix3	bsr	BlitWait
		move.l	#$ffff0000,$44(a6)
		rts

BlitFix4	bsr.b	BlitWait
		move.w	d1,$42(a6)
		ori.w	#$fca,d1
		rts

_resload	dc.l	0
_tags		dc.l	WHDLTAG_CUSTOM1_GET
SKIPINTRO	dc.l    0
		dc.l	TAG_DONE

_savename	dc.b	'Highs',0
password	dc.b	'Password',0

		CNOP	0,2
	

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

.exit	bra.w	QUIT


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine







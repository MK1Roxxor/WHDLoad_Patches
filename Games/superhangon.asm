;*---------------------------------------------------------------------------
;  :Program.	superhangon.asm
;  :Contents.	Slave for "SuperHangOn"
;  :Author.	Wepl
;  :Version.	$Id: superhangon.asm 1.5 2006/03/08 16:27:35 wepl Exp wepl $
;  :History.	23.06.98 started
;		26.06.98 finished
;		01.07.98 filter disabled
;			 gfx strike at startup fixed
;			 obsolete first highscore saving fixed
;		02.05.99 cb_switch for cop2lc added
;			 support for v10 whdload
;		14.02.06 using expmem for filecache
;			 blitwait routine replaced
;			 some snoop bugs fixed
;		24.02.06 waitvb before race start inserted to fix crash
;			 when joystick control is used
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"wart:su/superhangon/SuperHangOn.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

FIXCOP = 0

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	10			;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	$67000			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD	BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

_name		dc.b	"Super·Hang·On",0
_copy		dc.b	"1986 Sega, 1988 Electric Dreams",0
_info		dc.b	"installed & fixed by Wepl",10
		dc.b	"version 1.5 "
	IFD	BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
	EVEN

;============================================================================
_Start	;	A0 = resident loader
;============================================================================
;
;	Image format:
;	Disk 1		tracks 4-150 even tracks
;			       3-151 odd tracks
;
;============================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later using
		move.l	a0,a2			;A2 = resload

	;get variables
		lea	(_tags),a0
		jsr	(resload_Control,a2)

	;preload game data
		move.l	_expmem,a0
		move.l	a0,$180
		move.l	#74*$1600,d0		;offset
		move.l	d0,d1			;size
		moveq	#1,d2			;disk
		jsr	(resload_DiskLoad,a2)

	;load disk directory
		moveq	#8,d0			;offset
		move.l	#4*8,d1			;size
		moveq	#1,d2			;disk
		lea	$200,a0			;destination
		jsr	(resload_DiskLoad,a2)
		
		LEA	($300),A0
		MOVE.L	#"SLOG",D0
		BSR	_Load

	IFNE FIXCOP
		lea	$167a,a0
		bsr	_fixcop
	ENDC

		lea	_pl_slog,a0
		lea	0,a1
		jsr	(resload_Patch,a2)

		move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(_custom+dmacon)
		JSR	($300)

		LEA	($60000),A0
		MOVE.L	#"MUSC",D0
		BSR	_Load

		move.w	#100,d0
		bsr	_waitbutton

		JSR	($300)
		LEA	($20000),A0
		MOVE.L	#"LDSC",D0
		BSR	_Load

		LEA	($20000).L,A0
		LEA	($50000).L,A1
		MOVE.L	(A0)+,D2		;packed length
		ADD.L	A0,D2
lbC0000E6	MOVEQ	#0,D0
		MOVE.B	(A0)+,D0
		BMI.B	lbC0000F4
lbC0000EC	MOVE.B	(A0)+,(A1)+
		DBRA	D0,lbC0000EC
		BRA.B	lbC000100

lbC0000F4	NEG.B	D0
		BMI.B	lbC000100
		MOVE.B	(A0)+,D1
lbC0000FA	MOVE.B	D1,(A1)+
		DBRA	D0,lbC0000FA
lbC000100	CMP.L	A0,D2
		BHI.B	lbC0000E6

		move.w	#150,d0
		bsr	_waitbutton

		lea	_coplist,a0
		lea	$240,a1
		move.l	a1,a2
.cp		move.l	(a0)+,(a1)+
		bpl	.cp
		MOVE.L	a2,($DFF080)
		BSR.W	_waitvb
		MOVE.W	#$5200,($DFF100).L
		CLR.W	($DFF102).L
		MOVE.W	#$24,($DFF104).L
		MOVE.W	#$30,($DFF092).L
		MOVE.W	#$D8,($DFF094).L
		MOVE.W	#$2471,($DFF08E).L
		MOVE.W	#$46D1,($DFF090).L
		MOVE.W	#$B0,($DFF108).L
		MOVE.W	#$B0,($DFF10A).L
		LEA	(_colors,PC),A0
		LEA	($DFF180).L,A1
		MOVEQ	#15,D0
lbC000164	MOVE.L	(A0)+,(A1)+
		DBRA	D0,lbC000164
		JSR	($60000).L
		LEA	(_colors,PC),A0
		LEA	($DFF180).L,A1
		MOVEQ	#15,D0
lbC000165	MOVE.L	(A0)+,(A1)+
		DBRA	D0,lbC000165

		LEA	($300),A0
		MOVE.L	#"GAME",D0
		BSR.W	_Load

		lea	_pl_game,a0
		lea	$300,a1
		move.l	(_resload),a2
		jsr	(resload_Patch,a2)
		
		pea	0
		pea	_cbs
		pea	WHDLTAG_CBSWITCH_SET
		move.l	a7,a0
		jsr     (resload_Control,a2)

	IFNE FIXCOP
		lea	$5c40+$300,a0
	        bsr	_fixcop
		lea	$62d6+$300,a0
	 	bsr	_fixcop
	ENDC

		bsr	_LoadHighs
		
 		move.w	#$1480,d0
		bsr	_waitbutton

		jmp	$300

_pl_slog	PL_START
		PL_PS	$392,_waitvb
		PL_PS	$544,.bw1
		PL_END

.bw1		bsr	_bw
		move.w	d5,$dff070
		rts

_bw		BLITWAIT
		rts

_pl_game	PL_START
		PL_W	$30,$180		;300 usp
		PL_PS	$50,_SaveHighs
	;	PL_W	$61c,$4e71		;CENTRALISE MOUSE ON PLAY AREA
		PL_W	$b7c,$300		;180 ssp
		PL_W	$b82,$180   		;300 usp
		PL_PS	$11b0,.setcl2
	;	PL_P	$1218,_bw
		PL_R	$53be			;diskaccess
		PL_END

.setcl2		bsr	_waitvb
		move.l	$300+$62cc,$300+$62d0
		addq.l	#2,(a7)
		rts

	IFNE FIXCOP
; fix copper list for snoop
_fixcop
.loop		move.l	(a0),d0
		btst	#16,d0
		bne	.skip
		and.l	#$fffffff,d0
.skip		move.l	d0,(a0)+
		cmp.l	#-2,d0
		bne	.loop
		rts
	ENDC

_cbs		move.l	($65d0),(_custom+cop2lc)
		jmp	(a0)

_coplist	dc.l	$0E00005
		dc.l	$0E20000
		dc.l	$0E40005
		dc.l	$0E6002C
		dc.l	$0E80005
		dc.l	$0EA0058
		dc.l	$0EC0005
		dc.l	$0EE0084
		dc.l	$0F00005
		dc.l	$0F200B0
		dc.l	$FFFFFFFE
_colors		dc.l	$500
		dc.l	$2220333
		dc.l	$4440888
		dc.l	$6660A30
		dc.l	$F800BBB
		dc.l	$6600880
		dc.l	$CB00F55
		dc.l	$F330700
		dc.l	$FF00E00
		dc.l	$A000FFF
		dc.l	$4A00490
		dc.l	$4800330
		dc.l	$ACF08BF
		dc.l	$69F028F
		dc.l	$6F004F
		dc.l	$2F000F

	;load from name
_Load		lea	$200,a1			;disk directory
.search		cmp.l	(a1)+,d0
		bne	.search
		moveq	#0,d0
		move.b	(a1)+,d0		;start cylinder
		subq.l	#2,d0
		mulu	#$1600,d0
		moveq	#0,d1
		move.b	(a1)+,d1		;block offset
		mulu	#$200,d1
		add.l	d1,d0			;=offset
		move.w	(a1),d1			;block amount
		mulu	#$200,d1		;=size
		moveq	#1,d2			;=disk
		move.l	(_resload),a1
		jmp	(resload_DiskLoad,a1)

;--------------------------------

HIGHS	=	$66000

_LoadHighs	lea	_highs,a0
		move.l	(_resload),a4
		jsr	(resload_GetFileSize,a4)
		tst.l	d0
		beq	.end
		lea	_highs,a0
		lea	HIGHS,a1
		add.l	_expmem,a1
		pea	(a1)
		jsr	(resload_LoadFileDecrunch,a4)
		move.l	(a7),a0
		bsr	_crypt
		jsr	(resload_CRC16,a4)
		move.w	d0,$100			;crc
		move.l	(a7)+,a0
		lea	$6490,a2		;course table
		moveq	#3,d2			;4 courses
.c2		move.l	(a2)+,a3
		move.l	(16,a3),a1		;track times start
		move.l	($30,a3),d1		;end of scores
		sub.l	a1,d1			;size
		subq.w	#1,d1
.c1		move.b	(a0)+,(a1)+
		dbf	d1,.c1
		dbf	d2,.c2
.end		rts

_SaveHighs
		bset	#1,$bfe001		;disable filter
		
		move.l	#$10000,d1		;original

		movem.l	d0-d1/a0-a4,-(a7)
		move.l	a7,a4
		lea	HIGHS,a0		;original trackbuffer
		add.l	_expmem,a0
		move.l	a0,a7
		pea	(a0)
		clr.l	-(a7)			;size
		lea	$6490,a2		;course table
		moveq	#3,d2			;4 courses
.c2		move.l	(a2)+,a3
		move.l	(16,a3),a1		;track times start
		move.l	($30,a3),d1		;end of scores
		sub.l	a1,d1			;size
		add.l	d1,(a7)
		subq.w	#1,d1
.c1		move.b	(a1)+,(a0)+
		dbf	d1,.c1
		dbf	d2,.c2
		movem.l	(a7),d0/a0
		move.l	(_resload),a2
		jsr	(resload_CRC16,a2)
		movem.l	(a7)+,d1/a0
		cmp.w	$100,d0
		beq	.end
		move.w	d0,$100
		move.l	d1,d0
		bsr	_crypt
		move.l	a0,a1
		lea	_highs,a0
		jsr	(resload_SaveFile,a2)
.end		move.l	a4,a7
		movem.l	(a7)+,d0-d1/a0-a4
		rts

_crypt		movem.l	d0/a0,-(a7)
		subq.w	#1,d0
.lp		eor.b	d0,(a0)+
		dbf	d0,.lp
		movem.l	(a7)+,d0/a0
		rts

_highs		dc.b	"highs",0

;--------------------------------

_waitbutton	move.l	(_monitor),d1
		cmp.l	#NTSC_MONITOR_ID,d1
		beq	.1
		mulu	#50,d0
		divu	#60,d0
.1		btst	#6,$bfe001
		beq	.2
		btst	#7,$bfe001
		beq	.2
		bsr	_waitvb
		dbf	d0,.1
.2		rts

;--------------------------------

_waitvb		waitvb
		rts

;--------------------------------

	CNOP 0,4
_resload	dc.l	0			;address of resident loader
_tags		dc.l	WHDLTAG_MONITOR_GET
_monitor	dc.l	0
		dc.l	WHDLTAG_DBGADR_SET
		dc.l	$300
		dc.l	0

;============================================================================

	END


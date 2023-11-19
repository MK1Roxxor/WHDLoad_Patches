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
;		11.10.18 (StingRay) DMA waits in sample and music players
;			 fixed
;			 68000 quitkey support (main game only)
;			 source made pc-relative and optimmised so the slave
;			 can be assembled with non-optimising assemblers too
;		12.10.18 high score load/save redone, high score name
;			 changed to "SuperHangOn.high", load/save high scores
;			 menu patched, no more disk accesses!, high scores
;			 are now saved after player entered his name instead
;			 of saving them always when starting the game
;			 68000 quitkey support for intro (SLOG) added, patch
;			 base set to real address ($300.w) instead of 0 and
;			 patchlist adapted accordingly
;			 a while later: high score stuff reverted back to
;			 old version after reading Wepl's notes in the
;			 ReadMe (lap times are saved too)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9, ASM-Pro V1.16d
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	SOURCES:Include/
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
;DEBUG

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	10			;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		IFD	DEBUG
		dc.w	.dir-_base		; ws_CurrentDir
		ELSE
		dc.w	0			;ws_CurrentDir
		ENDC
		dc.w	0			;ws_DontCache
		dc.b	0			;ws_keydebug
		dc.b	$59			;ws_keyexit = F10
		dc.l	$67000			;ws_ExpMem
		dc.w	.name-_base		;ws_name
		dc.w	.copy-_base		;ws_copy
		dc.w	.info-_base		;ws_info

;============================================================================

	IFD	BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

	IFD	DEBUG
.dir	dc.b	"SOURCES:WHD_Slaves/SuperHangOn",0
	ENDC

.name		dc.b	"Super·Hang·On",0
.copy		dc.b	"1986 Sega, 1988 Electric Dreams",0
.info		dc.b	"installed & fixed by Wepl & StingRay",10
		IFD	DEBUG
		dc.b	"DEBUG!!! "
		ENDC
		dc.b	"version 1.6 "
	IFD	BARFLY
		INCBIN	"T:date"
	ELSE
		dc.b	"(12.10.2018)"
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
		lea	(_tags,pc),a0
		jsr	(resload_Control,a2)

	;preload game data
		move.l	_base+ws_ExpMem(pc),a0
		move.l	a0,$180.w
		move.l	#74*$1600,d0		;offset
		move.l	d0,d1			;size
		moveq	#1,d2			;disk
		jsr	(resload_DiskLoad,a2)

	;load disk directory
		moveq	#8,d0			;offset
		moveq	#4*8,d1			;size
		moveq	#1,d2			;disk
		lea	$200.w,a0		;destination
		jsr	(resload_DiskLoad,a2)
		
		LEA	($300.w),A0
		MOVE.L	#"SLOG",D0
		BSR	_Load

	IFNE FIXCOP
		lea	$167a.w,a0
		bsr	_fixcop
	ENDC

		lea	_pl_slog(pc),a0
	lea	$300.w,a1
		jsr	(resload_Patch,a2)

		move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(_custom+dmacon)
		JSR	($300.w)

		LEA	($60000),A0
		MOVE.L	#"MUSC",D0
		BSR	_Load

; v1.6, stingray
	lea	PLMUSC(pc),a0
	lea	$60000,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

		moveq	#100,d0
		bsr	_waitbutton


; load and decrunch the title screen
		lea	$20000,a0
		move.l	#"LDSC",d0		; "load screen"
		bsr	_Load

		lea	$20000,A0
		lea	$50000,A1
		move.l	(A0)+,D2		;packed length
		add.l	A0,D2
.decrunchRLE	moveq	#0,d0
		move.b	(a0)+,d0
		bmi.b	.packed
.copy		move.b	(A0)+,(A1)+
		dbf	D0,.copy
		bra.b	.next

.packed		neg.b	d0			; length of packed data
		bmi.b	.next
		move.b	(a0)+,d1		; get byte
.store		move.b	d1,(a1)+
		dbf	d0,.store
.next		cmp.l	a0,d2
		bhi.b	.decrunchRLE

		move.w	#150,d0
		bsr	_waitbutton

		lea	_coplist(pc),a0
		lea	$240.w,a1
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

		LEA	($300.w),A0
		MOVE.L	#"GAME",D0
		BSR.W	_Load

		lea	_pl_game(pc),a0
		lea	$300.w,a1
		move.l	(_resload,pc),a2
		jsr	(resload_Patch,a2)
		
		pea	0.w
		pea	_cbs(pc)
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

		jmp	$300.w

_pl_slog	PL_START
		PL_PS	$92,_waitvb
		PL_PS	$244,.bw1

; v1.6, stingray
	PL_PS	$59e,.checkquit
	
		PL_END

.checkquit
	movem.l	d0-a6,-(a7)
	move.b	$bfec01,d0
	ror.b	d0
	not.b	d0
	cmp.b	_base+ws_keyexit(pc),d0
	beq.w	QUIT
	movem.l	(a7)+,d0-a6
	tst.w	$300+$8a6.w		; original code
	rts


.bw1		bsr.b	_bw
		move.w	d5,$dff070
		rts

_bw		;BLITWAIT
		tst.b	$dff002
.wb		tst.b	$bfe001
		tst.b	$bfe001
		btst	#6,$dff002
		bne.b	.wb
		tst.b	$dff002
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


; v1.6, stingray
		PL_PSS	$1a6c,FixDMAWait,2
		PL_PSS	$1a80,FixDMAWait,2
		PL_PS	$f8e,.checkquit

		;PL_B	$e9c,$4a20	; unlimited time


		PL_END

.checkquit
	move.w	d0,-(a7)
	ror.b	d0
	not.b	d0
	cmp.b	_base+ws_keyexit(pc),d0
	beq.w	QUIT
	move.w	(a7)+,d0
	clr.b	$bfec01			; original code
	rts

.setcl2		bsr	_waitvb
		move.l	$300+$62cc.w,$300+$62d0.w
		addq.l	#2,(a7)
		rts

	IFNE FIXCOP
; fix copper list for snoop
_fixcop
.loop		move.l	(a0),d0
		btst	#16,d0
		bne.b	.skip
		and.l	#$fffffff,d0
.skip		move.l	d0,(a0)+
		cmp.l	#-2,d0
		bne.b	.loop
		rts
	ENDC

_cbs		move.l	($65d0.w),(_custom+cop2lc)
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
_Load		lea	$200.w,a1		;disk directory
.search		cmp.l	(a1)+,d0
		bne.b	.search
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
		move.l	(_resload,pc),a1
		jmp	(resload_DiskLoad,a1)

;--------------------------------

HIGHS	=	$66000

_LoadHighs	lea	_highs(pc),a0
		move.l	(_resload,pc),a4
		jsr	(resload_GetFileSize,a4)
		tst.l	d0
		beq.b	.end
		lea	_highs(pc),a0
		lea	HIGHS,a1
		add.l	_base+ws_ExpMem(pc),a1
		pea	(a1)
		jsr	(resload_LoadFileDecrunch,a4)
		move.l	(a7),a0
		bsr.w	_crypt
		jsr	(resload_CRC16,a4)
		move.w	d0,$100.w		;crc
		move.l	(a7)+,a0
		lea	$6490.w,a2		;course table
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
		add.l	_base+ws_ExpMem(pc),a0
		move.l	a0,a7
		pea	(a0)
		clr.l	-(a7)			;size
		lea	$6490.w,a2		;course table
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
		move.l	(_resload,pc),a2
		jsr	(resload_CRC16,a2)
		movem.l	(a7)+,d1/a0
		cmp.w	$100.w,d0
		beq.b	.end
		move.w	d0,$100.w
		move.l	d1,d0
		bsr.b	_crypt
		move.l	a0,a1
		lea	_highs(pc),a0
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

_waitbutton	move.l	(_monitor,pc),d1
		cmp.l	#NTSC_MONITOR_ID,d1
		beq.b	.1
		mulu	#50,d0
		divu	#60,d0
.1		btst	#6,$bfe001
		beq.b	.2
		btst	#7,$bfe001
		beq.b	.2
		bsr	_waitvb
		dbf	d0,.1
.2		rts

;--------------------------------

_waitvb		;waitvb
.wait		btst	#0,$dff005
		beq.b	.wait
.wait2		btst	#0,$dff005
		bne.b	.wait2
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

; v1.6, stingray

PLMUSC	PL_START
	PL_PSS	$354,FixDMAWait,2
	PL_PSS	$368,FixDMAWait,2
	PL_END

FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#4-1,d0
.loop	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait
	dbf	d0,.loop
	movem.l	(a7)+,d0/d1
	rts

QUIT	pea	(TDREASON_OK).w
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

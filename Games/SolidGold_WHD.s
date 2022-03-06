***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        SOLID GOLD WHDLOAD SLAVE            )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             January 2014                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 06-Mar-2022	- trainer options adapted for V1.2
;		- Bplcon0 color bit fixes (end part)

; 05-Mar-2022	- started to add support for V1.2 of the game
;		- debug key removed from keyboard interrupt

; 02-Aug-2016	- writes to Beamcon0, Fmode, Bplcon3/4 disabled
;		- color bit fix
;		- added option to jump with fire (CUSTOM3), requested
;		  by modrobert (Mantis #3118)

; 01-Jan-2014	- work started
;		- and finished a short while later


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
DEBUGKEY	= $58		; F9
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
	dc.w	17		; ws_version
	dc.w	FLAGS		; flags
	dc.l	524288		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	IFD	DEBUG
	dc.w	.dir-HEADER	; ws_CurrentDir
	ELSE
	dc.w	0		; ws_CurrentDir
	ENDC
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_KeyDebug
	dc.b	QUITKEY		; ws_KeyExit
	dc.l	524288		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"C1:B:Unlimited Lives;"
	dc.b	"C2:B:Enable In-Game Keys;"
	dc.b	"C3:B:Fire to Jump;"
	dc.b	"BW"
	dc.b	0

	IFD	DEBUG
.dir	dc.b	"SOURCES:WHD_Slaves/SolidGold",0
	ENDC

.name	dc.b	"Solid Gold",0
.copy	dc.b	"2013 Night Owl Design",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.02 (06.03.2022)",0
HiName	dc.b	"SolidGold.high",0
	CNOP	0,2


TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
LIVESTRAINER	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
KEYS		dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET
		dc.l	0

		dc.l	WHDLTAG_BUTTONWAIT_GET
BUTTONWAIT	dc.l	0
		dc.l	TAG_END


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


; install keyboard irq
	bsr	SetLev2IRQ

; load boot (needed for title picture)
	move.l	#$400,d0
	move.l	#$2400,d1
	moveq	#1,d2
	lea	$70000,a0
	move.l	a0,a5
	move.l	d1,d5
	jsr	resload_DiskLoad(a2)
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$8c82,d0		; V1.2
	beq.b	.is_supported_version
	cmp.w	#$fdd4,d0		; V1.0
	bne.b	.wrongver

.is_supported_version
	move.l	a5,a0
	lea	$72400,a1
	bsr	BK_DECRUNCH

	lea	PLTITLE(pc),a0
	lea	$72400,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	lea	$72400+$252,a0
	lea	$dff100,a1
	move.l	(a0)+,(a1)+		; $dff100/$dff102
	move.w	(a0)+,(a1)+		; $dff104
	addq.w	#2,a0
	addq.w	#2,a1			; skip $dff106
	move.l	(a0)+,(a1)+		; $dff108/$dff10a
	

	jsr	$72400+$1d0		; display tite picture


; load game
	move.l	#$2800,d0
	move.l	#$7e4c+12,d1
	lea	$1000.w,a0
	move.l	a0,a5
	move.l	d0,d5
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)

	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	moveq	#0,d1			; game version
	cmp.w	#$d5a6,d0		; V1.0
	beq.b	.ok
	moveq	#1,d1
	cmp.w	#$09c4,d0		; V1.2
	beq.b	.ok

.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok	lea	Game_Version(pc),a0
	move.w	d1,(a0)

; decrunch
	move.l	a5,a0
	move.l	HEADER+ws_ExpMem(pc),a1
	bsr	BK_DECRUNCH

; relocate
	move.l	HEADER+ws_ExpMem(pc),a1	; reloc entries
	lea	$a6*4(a1),a2		; start of code
	move.l	a2,a5

.reloc	move.l	a2,d0
	move.l	(a1)+,d2		; number of reloc entries
	beq.b	.done
.reloop	move.l	(a1)+,d1
	add.l	d0,(a2,d1.l)
	subq.l	#1,d2
	bne.b	.reloop

.done

	move.l	LIVESTRAINER(pc),d0
	beq.b	.nolives
	move.w	#$7000,$25fa(a5)
.nolives

; patch	
	lea	PLGAME(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

; and start
	move.l	BUTTONWAIT(pc),d0
	beq.b	.nowait
.wait	btst	#7,$bfe001
	bne.b	.wait

.nowait	lea	$dff000,a6
	lea	$72400+$2e0,a0		; palette title picture
	jmp	(a5)


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)


KillSys	move.w	#$7fff,$dff09a
	bsr	WaitRaster
	move.w	#$7fff,$dff096
	move.w	#$7fff,$dff09c
	rts

Game_Version	dc.w	0		; 0: V1.0, 1: V1.2

PLTITLE	PL_START
	PL_SA	$238,$23c		; skip _LVOWaitBlit
	PL_R	$24e

	PL_SA	$1dc,$1e2		; skip Beamcon0 write
	PL_ORW	$252,1<<9		; set Bplcon0 color bit
	PL_SA	$1ec,$1f8		; skip reg init+FMODE write
	PL_END



PLGAME	PL_START
	PL_SA	$16,$1e			; skip CPU check ect.
	PL_R	$258			; disable loader init
	PL_P	$4d4,.load
	PL_P	$22,QUIT
	PL_SA	$304,$34e		; skip disk check
	PL_PS	$a58,.keys
	PL_PSA	$1e40,.loadhiscores,$1e4e
	PL_PSA	$63e,.savehiscores,$698
	PL_PS	$2874,.bw

	PL_IFC3
	PL_PS	$2f9a,.checkfire
	PL_ENDIF

	PL_PS	$d8c,.FixCop
	PL_END



.FixCop	move.l	a0,-(a7)
	move.l	4(a1),a0
	bsr.w	Fix_Copperlist
	move.l	(a7)+,a0
	move.l	4(a1),$80(a6)
	rts


.checkfire
	moveq	#0,d0
	movem.l	d0/d1,-(a7)		; movem is required here!
	
	move.w	Game_Version(pc),d1
	beq.b	.is_game_version1
	move.b	-$2545(a4),d0		; up/down
	or.b	-$2546(a4),d0		; +fire
	bra.b	.exit
	

.is_game_version1
	move.b	-$2555(a4),d0		; up/down
	or.b	-$2556(a4),d0		; +fire

.exit	movem.l	(a7)+,d0/d1
	rts

.bw	move.l	BUTTONWAIT(pc),d0
	beq.b	.nowait
	btst	#7,$bfe001
	beq.b	.bw
	
.bw2	btst	#7,$bfe001
	bne.b	.bw2

.nowait	moveq	#0,d0
	move.b	3(a2),d0
	rts

; a0: buffer
.savehiscores
	move.l	LIVESTRAINER(pc),d0	; high scores will not be
	bne.b	.nohi			; saved if any trainers are used
	move.l	KEYS(pc),d0
	bne.b	.nohi

	move.l	a0,a1
	lea	HiName(pc),a0
	move.l	#512,d0
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)

.nohi	moveq	#0,d0
	rts


.loadhiscores
	move.l	resload(pc),a3

	lea	HiName(pc),a0
	jsr	resload_GetFileSize(a3)
	tst.l	d0
	beq.b	.loadfromdisk
	lea	HiName(pc),a0
	move.l	a2,a1
	jmp	resload_LoadFile(a3)

.loadfromdisk
	move.w	#$6d5,d0
	moveq	#1,d1
	move.l	a2,a0
	bra.b	.load


.keys	or.b	#1<<6,$e00(a0)		; original code
	move.b	d0,d1
	ror.b	#1,d1
	not.b	d1
	cmp.b	HEADER+ws_keyexit(pc),d1
	beq.w	QUIT

	movem.l	d2/d3,-(a7)

	move.l	KEYS(pc),d2
	beq.b	.nokeys
	cmp.b	#$36,d1			; N-skip level
	bne.b	.nolevskip

	move.w	Game_Version(pc),d2
	beq.b	.Level_Skip_V1
	sf	-$22c3(a4)
	st	-$1c74(a4)
	bra.b	.Level_Skip_Done

.Level_Skip_V1
	sf	-$22d3(a4)
	st	-$1c84(a4)
.Level_Skip_Done


.nolevskip
	cmp.b	#$28,d1			; L-add 1 life
	bne.b	.nolife
	move.w	Game_Version(pc),d3
	beq.b	.Add_Life_V1
	moveq	#1,d3
	move.b	-$22c5(a4),d2
	cmp.b	#$99,d2
	beq.b	.nolife_V2
	abcd	d3,d2
	move.b	d2,-$22c5(a4)
.nolife_V2
	bra.b	.Add_Life_Done


.Add_Life_V1
	moveq	#1,d3
	move.b	-$22d5(a4),d2
	cmp.b	#$99,d2
	beq.b	.nolife
	abcd	d3,d2
	move.b	d2,-$22d5(a4)
.Add_Life_Done

.nolife



.nokeys	movem.l	(a7)+,d2/d3

	rts	


.load	movem.l	d1-a6,-(a7)
	mulu.w	#512,d0
	mulu.w	#512,d1
	moveq	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	moveq	#0,d0			; no errors
	movem.l	(a7)+,d1-a6
	rts


; This routine fixes several copperlist problems:
; - the BPLCON0 color bit will be set
; - all illegal BPLCON0 bits will be cleared

; a0.l: copperlist

Fix_Copperlist
.loop	cmp.w	#$0100,(a0)
	bne.b	.is_not_Bplcon0

	; clear illegal BPLCON0 bits
	;and.w	#~(1<<0|1<<4|1<<5|1<<6|1<<7),2(a0)

	; set color bit
	or.w	#1<<9,2(a0)

.is_not_Bplcon0

	addq.w	#4,a0
	cmp.l	#$fffffffe,(a0)
	bne.b	.loop
	rts



WaitRaster
	move.l	d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.b	.wait
.wait2	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	beq.b	.wait2
	move.l	(a7)+,d0
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

.quit	bsr	KillSys
	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.exit	pea	(TDREASON_OK).w
	bra.b	.quit


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine



; Bytekiller decruncher
; resourced and adapted by stingray
;
; a0.l: source
; a1.l: destination

BK_DECRUNCH
	bsr.b	.decrunch
	tst.l	d5
	beq.b	.ok

; checksum doesn't match, file corrupt
	pea	ErrText(pc)
	pea	(TDREASON_FAILMSG).w
	bra.w	EXIT

.ok	rts


.decrunch
	move.l	(a0)+,d0		; crunched length
	move.l	(a0)+,d1		; decrunched length
	move.l	(a0)+,d5		; checksum
	add.l	d0,a0			; end of crunched data
	lea	(a1,d1.l),a2		; end of decrunched data
	move.l	-(a0),d0		; get first long
	eor.l	d0,d5
.loop	lsr.l	#1,d0
	bne.b	.nonew1
	bsr.b	.nextlong
.nonew1	bcs.b	.getcmd

	moveq	#8,d1
	moveq	#1,d3
	lsr.l	#1,d0
	bne.b	.nonew2
	bsr.b	.nextlong
.nonew2	bcs.b	.copyunpacked

; data is packed, unpack and copy
	moveq	#3,d1			; next 3 bits: length of packed data
	clr.w	d4

; d1: number of bits to get from stream
; d4: length
.packed	bsr.b	.getbits
	move.w	d2,d3
	add.w	d4,d3
.copypacked
	moveq	#8-1,d1
.getbyte
	lsr.l	#1,d0
	bne.b	.nonew3
	bsr.b	.nextlong
.nonew3	addx.l	d2,d2
	dbf	d1,.getbyte

	move.b	d2,-(a2)
	dbf	d3,.copypacked
	bra.b	.next

.ispacked
	moveq	#8,d1
	moveq	#8,d4
	bra.b	.packed

.getcmd	moveq	#2,d1			; next 2 bits: command
	bsr.b	.getbits
	cmp.b	#2,d2			; %10: unpacked data follows
	blt.b	.notpacked
	cmp.b	#3,d2			; %11: packed data follows
	beq.b	.ispacked

; %10
	moveq	#8,d1			; next byte:
	bsr.b	.getbits		; length of unpacked data
	move.w	d2,d3			; length -> d3
	moveq	#12,d1
	bra.b	.copyunpacked

; %00 or %01
.notpacked
	moveq	#9,d1
	add.w	d2,d1
	addq.w	#2,d2
	move.w	d2,d3

.copyunpacked
	bsr.b	.getbits		; get offset (d2)
;.copy	subq.w	#1,a2
;	move.b	(a2,d2.w),(a2)
;	dbf	d3,.copy

; optimised version of the code above
	subq.w	#1,d2
.copy	move.b	(a2,d2.w),-(a2)
	dbf	d3,.copy

.next
;	move.l	CUSTOM1(pc),d1
;	beq.b	.noflash
;	move.w	a0,$dff186
.noflash

	cmp.l	a2,a1
	blt.b	.loop
	rts

.nextlong
	move.l	-(a0),d0
	eor.l	d0,d5
	move.w	#$10,ccr
	roxr.l	#1,d0
	rts

; d1.w: number of bits to get
; ----
; d2.l: bit stream

.getbits
	subq.w	#1,d1
	clr.w	d2
.getbit	lsr.l	#1,d0
	bne.b	.nonew
	move.l	-(a0),d0
	eor.l	d0,d5
	move.w	#$10,ccr
	roxr.l	#1,d0
.nonew	addx.l	d2,d2
	dbf	d1,.getbit
	rts


DEC_DESTINATION	dc.l	0
ErrText	dc.b	"Decrunching failed, file corrupt!",0



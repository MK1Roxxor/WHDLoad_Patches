***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    MIG-29M SUPER FULCRUM WHDLOAD SLAVE     )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              March 2013                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 05-Jul-2023	- support for another version added (1 disk compilation
;		  version)
;		- CPU dependent DMA waits in all replayers fixed

; 12-Mar-2013	- game mode can be selected with CUSTOM2

; 11-Mar-2013	- work started


	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	;INCLUDE	lvo/dos.i

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

MC68020	MACRO
	ENDM

;============================================================================

CHIPMEMSIZE	= 524288
FASTMEMSIZE	= 524288
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;BOOTBLOCK
BOOTDOS
;BOOTEARLY
;CBDOSLOADSEG
;CBDOSREAD
CACHE
;DEBUG
;DISKSONBOOT
;DOSASSIGN
FONTHEIGHT	= 8
HDINIT
;HRTMON
;INITAGA
;INIT_AUDIO
;INIT_GADTOOLS
;INIT_LOWLEVEL
;INIT_MATHFFP
IOCACHE		= 1024
;JOYPADEMU
;MEMFREE	= $200
;NEEDFPU
;NO68020
POINTERTICKS	= 1
;PROMOTE_DISPLAY
STACKSIZE	= 20000
;TRDCHANGEDISK

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	; F10


;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================


slv_CurrentDir	IFD	DEBUG
		dc.b	"SOURCES:WHD_Slaves/Mig29SuperFulcrum/data",0
		ELSE
		dc.b	"data",0
		ENDIF

slv_name	dc.b	"MiG-29M Super Fulcrum",0
slv_copy	dc.b	"1991 Domark",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"DEBUG!!! "
		ENDC
		dc.b	"Version 1.01 (05.07.2023)",0

slv_config	dc.b	"C1:B:Skip Intro;"
		dc.b	"C2:L:Game Mode:"
		dc.b	"256 lines & 32 colors,"
		dc.b	"256 lines & 16 colors,"
		dc.b	"200 lines & 32 colors,"
		dc.b	"200 lines & 16 colors"
		dc.b	0
		CNOP	0,4

		CNOP	0,4

DOSbase	dc.l	0

	IFD BOOTDOS

_bootdos
	lea	.saveregs(pc),a0
	movem.l	d1-d3/d5-d7/a1-a2/a4-a6,(a0)

	lea	_dosname(pc),a1
	move.l	$4.w,a6
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,a6
	lea	DOSbase(pc),a0
	move.l	d0,(a0)

	move.l	_resload(pc),a2
	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)



	move.l	NOINTRO(pc),d0
	bne.b	.nointro
	lea	.intro(pc),a0
	lea	PT_INTRO(pc),a1
	bsr.b	.go
.nointro

	
; load game
.dogame	lea	.game(pc),a0
	lea	PT_GAME(pc),a1
	addq.w	#1,.GAMEFLAG-PT_GAME(a1)
	bsr.b	.go
	bra.w	QUIT



.do1

.go	bsr.w	.LoadAndPatch

.run	move.l	d7,d1
	moveq	#.arglen,d0
	lea	.args(pc),a0
	bsr.b	.call
	rts


.TAB	dc.w	255<<8|32	; 1
	dc.w	255<<8|16	; 2
	dc.w	199<<8|32	; 3
	dc.w	199<<8|16	; 4


; d0.l: argument length
; d1.l: segment
; a0.l: argument (command line)
; a6.l: dosbase
.call	lea	.callregs(pc),a1
	movem.l	d2-d7/a2-a6,(a1)
	move.l	(a7)+,11*4(a1)
	move.l	d0,d4
	lsl.l	#2,d1
	move.l	d1,a3
	move.l	a0,a4		; save command line
; create longword aligned copy of args
	lea	.callargs(pc),a1
	move.l	a1,d2
.copy	move.b	(a0)+,(a1)+
	subq.w	#1,d0
	bne.b	.copy

; set args
	jsr	_LVOInput(a6)
	lsl.l	#2,d0		; BPTR -> APTR
	move.l	d0,a0
	lsr.l	#2,d2		; APTR -> BPTR
	move.l	d2,fh_Buf(a0)
	clr.l	fh_Pos(a0)
	move.l	d4,fh_End(a0)
; call

; CUSTOM2 selects game mode
	move.w	.GAMEFLAG(pc),d0
	beq.b	.normal
	move.l	MODE(pc),d0
	beq.b	.normal		; default: 200 lines, 16 colors
	cmp.w	#4,d0		; just in case...
	bgt.b	.normal
	add.w	d0,d0
	move.w	.TAB(pc,d0.w),d0
	move.w	d0,d1
	lsr.w	#8,d0
	addq.w	#1,d0		; screen height
	and.w	#32-1,d1	; # of colors

	move.w	Game_Version(pc),d2
	beq.b	.Set_Parameters_For_Game_Version1
	move.w	d1,$1f5e+4+2(a3)
	move.w	d0,$1f66+4+2(a3)
	bra.b	.Run_Game


.Set_Parameters_For_Game_Version1
	move.w	d0,$1f70+4+2(a3)
	move.w	d1,$1f78+4+2(a3)


.Run_Game
	
.normal

	move.l	d4,d0
	move.l	a4,a0
	movem.l	.saveregs(pc),d1-d3/d5-d7/a1-a2/a4-a6

	
	jsr	4(a3)

; return
	movem.l	.callregs(pc),d2-d7/a2-a6
	move.l	.callrts(pc),a0
	jmp	(a0)





; a0.l: file name
; a1.l: patch table
; a6.l: dos base
; ---
; d7: segment

.LoadAndPatch
	move.l	a1,a5
	movem.w	(a1),d0/d1		; start/end offset for CRC16
	sub.w	d0,d1			; length to check
	move.l	d0,d3
	move.l	d1,d4

	move.l	a0,d6
	move.l	a0,d1
	jsr	_LVOLoadSeg(a6)
	move.l	d0,d7
	beq.b	.error

	bsr.b	.CRC16

; d2.w: checksum
	move.l	a5,a0			; a0: current entry in tab
.find	move.w	2*2(a0),d0		; (points to CRC16 value)
	cmp.w	#-1,d0
	beq.b	.out
	tst.w	d0
	beq.b	.wrongver
	cmp.w	d0,d2
	beq.b	.found

	lea	Game_Version(pc),a1
	addq.w	#1,(a1)

	addq.w	#4*2,a0			; next entry in tab
	tst.w	(a0)
	beq.b	.wrongver
	movem.w	(a0),d3/d4		; new start/end offset for CRC16
	sub.w	d3,d4			; length
	bsr.b	.CRC16			; get new checksum
	bra.b	.find

; unsupported/unknown version
.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.found	add.w	3*2(a0),a5		; a5: patch list



	move.l	a5,a0
.patch	move.l	d7,a1
	move.l	_resload(pc),a2
	jsr	resload_PatchSeg(a2)
.out	rts

.error	jsr	_LVOIoErr(a6)
	move.l	d6,-(a7)
	move.l	d0,-(a7)
	pea	(TDREASON_DOSREAD).w
	bra.w	EXIT

; d3.l: offset
; d4.l: length to check
; d7.l: segment
; ----
; d0.w: CRC16 value
; d2.w: CRC16 value

.CRC16	move.l	a0,-(a7)
	move.l	d7,a0
	add.l	a0,a0
	add.l	a0,a0
	lea	4(a0,d3.l),a0
	move.l	d4,d0
	move.l	_resload(pc),a2
	jsr	resload_CRC16(a2)
	move.w	d0,d2
	move.l	(a7)+,a0
	rts

.intro	dc.b	"intro",0
.game	dc.b	"mig",0
.args	dc.b	"  ",10		; must be LF terminated
.arglen	= *-.args
	CNOP	0,4

.GAMEFLAG	dc.w	0	; 0: intro, 1: game
.saveregs	ds.l	11
.saverts	dc.l	0
.dosbase	dc.l	0
.callregs	ds.l	11
.callrts	dc.l	0
.callargs	ds.b	208


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	_resload(pc),a2
	jmp	resload_Abort(a2)


	CNOP 0,4

PT_INTRO
	dc.w	$18,$1e4,$360a,PLINTRO-PT_INTRO
	dc.w	$18,$1e4,$b99f,PLINTRO_V2-PT_INTRO	; V2
	dc.w	0				; end of tab

PLINTRO	PL_START
	PL_PSS	$b712,Fix_DMA_Wait,2
	PL_PSS	$b728,Fix_DMA_Wait,2
	PL_PSS	$be50,Fix_DMA_Wait,2
	PL_PSS	$be66,Fix_DMA_Wait,2
	
	PL_END

PLINTRO_V2
	PL_START
	PL_PSS	$ba8e,Fix_DMA_Wait,2
	PL_PSS	$baa4,Fix_DMA_Wait,2
	PL_PSS	$c1cc,Fix_DMA_Wait,2
	PL_PSS	$c1e2,Fix_DMA_Wait,2
	PL_END


; format: start, end, checksum, offset to patch list
PT_GAME	dc.w	$18,$1e4,$7833,PLGAME-PT_GAME		;
	dc.w	$18,$1e4,$ff21,PLGAME_V2-PT_GAME	; V2
	dc.w	0					; end of tab


PLGAME	PL_START
	PL_W	$1f6e,$4e71		; disable AvailMem() result check
	PL_P	$2d0b8,.crack		: disable Copylock
	PL_SA	$1f80,$1f88		; skip setting low mem flag
	PL_END

; key:
; $9065<<16+$12218893+$260306<<8 | $4859<<16+$12343358

.crack	move.l	#(($9065<<16)+$12218893+($260306<<8))|(($4859<<16)+$12343358),d0
	rts


PLGAME_V2
	PL_START
	PL_SA	$1eb4,$1f5e		; skip height/number of colors input
	PL_SA	$1f6e,$1f82

	PL_R	$232c			; don't open serial.device

	PL_P	$32260,.crack		: disable Copylock
	PL_PSS	$28066,Fix_DMA_Wait,2
	PL_PSS	$2807c,Fix_DMA_Wait,2
	PL_PSS	$287a4,Fix_DMA_Wait,2
	PL_PSS	$287ba,Fix_DMA_Wait,2
	PL_END

.crack	move.l	#$2cc6c50d,d0
	rts

	
Game_Version	dc.w	0
	

TAGLIST	dc.l	WHDLTAG_CUSTOM1_GET
NOINTRO	dc.l	0
	dc.l	WHDLTAG_CUSTOM2_GET
MODE	dc.l	0			: 1: 256 lines, 32 colors
	dc.l	TAG_END			; 2: 256 lines, 16 colors
					; 3: 200 lines, 32 colors
					; 4: 200 lines, 16 colors 



; ---------------------------------------------------------------------------
; Support/helper routines.

Fix_DMA_Wait
	moveq	#8,d0

; d0.w: number of raster lines to wait
Wait_Raster_Lines
	move.w	d1,-(a7)
.loop	move.b	$dff006,d1
.still_in_same_raster_line
	cmp.b	$dff006,d1
	beq.b	.still_in_same_raster_line	
	subq.w	#1,d0
	bne.b	.loop
	move.w	(a7)+,d1
	rts

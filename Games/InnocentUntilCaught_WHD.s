***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    INNOCENT UNTIL CAUGHT WHDLOAD SLAVE     )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             February 2013                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 06-Apr-2021	- support for Italian version added

; 20-Feb-2013	- problem with german umlauts fixed, "ä" and "Ä" are now
;		  displayed correctly

; 19-Feb-2013	- problems with mouse after game has been saved now
;		  finally fixed, before saving the game at least 1 VBL
;		  must occur for whatever reason (probably to switch off
;		  replay)
;		- uses original save routines (but without delay) again
;		  now since the problem with the mouse control has been
;		  fixed
;		- buggy NTSC check is not just skipped any longer, instead
;		  the check has been completely fixed which means that
;		  WHDLoad's "NTSC" option is fully supported now, the game
;		  will also display the correct mode in the "Show config"
;		  screen at the beginning

; 17-Feb-2013	- protection is now completely skipped, no need to enter
;		  any digits at the beginning of the game anymore
;		- support for french version added
;		- uses WHDLoad functions now to save game to avoid
;		  problems (right mouse button w/o function etc.)

; 13-Feb-2013	- fixed flickering status panel, always happened when
;		  opcode $c8 (draw backdrop) was used in a script,
;		  disabling bitplane DMA in the copperlist caused the
;		  problem, fixed with a copper nop instructions
;		- bug in startup (copperlist saving, reading $dff080...)
;		  and buggy NTSC check fixed (checking display mode by
;		  reading bit #8 in AttnFlags? yeah, right...)
;		- delay when saving data disabled

; 12-Feb-2013	- disk-motor check when saving data disabled

; 11-Feb-2013	- touched again after a very long time
;		- code cleaned up and approach to crack the game
;		  simplified a bit
;		- problems caused by hardware banging level 6 interrupt
;		  fixed, music is now replayed in the VBI, level 6
;		  interrupt has been completely disabled

; 05-Jul-2008	- work started
;		- english and german version supported, protection
;		  removed 



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

BLACKSCREEN
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
;STACKSIZE	= 6000
;TRDCHANGEDISK

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	; F10

;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================


slv_CurrentDir	IFD	DEBUG
		dc.b	"SOURCES:WHD_Slaves/Innocent/data_de",0
		ELSE
		dc.b	"data",0
		ENDIF

slv_name	dc.b	"Innocent Until Caught",0
slv_copy	dc.b	"1994 Psygnosis",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"DEBUG!!! "
		ENDC
		dc.b	"Version 1.02 (06.04.2021)",0
		CNOP	0,4

	IFD BOOTDOS

_bootdos
	lea	_dosname(pc),a1
	move.l	$4.w,a6
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,a6

	move.l	_resload(pc),a2
	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


; load game
.dogame	move.l	#$10490,d0
	move.l	#$106c1-$10490,d1
	lea	.game(pc),a0
	lea	PT_GAME(pc),a1
.go	bsr.b	.LoadAndPatch


.run	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1

	movem.l	d7/a6,-(a7)
	jsr	4(a1)
	movem.l	(a7)+,d7/a6
	jsr	_LVOUnLoadSeg(a6)
	bra.w	QUIT


; d0.l: start offset for version check
; d1.l: length for version check
; a0.l: file name
; a1.l: patch table
; a6.l: dos base
; ---
; d7: segment

.LoadAndPatch
	move.l	d0,d3
	move.l	d1,d4

	move.l	a0,d6
	move.l	a1,a5
	move.l	a0,d1
	jsr	_LVOLoadSeg(a6)
	move.l	d0,d7
	beq.b	.error

	move.l	d7,a0
	add.l	a0,a0
	add.l	a0,a0
	lea	4(a0,d3.l),a0
	move.l	d4,d0
	move.l	_resload(pc),a2
	jsr	resload_CRC16(a2)
	move.w	d0,d2

; d0: checksum
	move.l	a5,a0
.find	move.w	(a0)+,d0
	cmp.w	#-1,d0
	beq.b	.out
	tst.w	d0
	beq.b	.wrongver
	cmp.w	d0,d2
	beq.b	.found
	addq.w	#2,a0
	bra.b	.find

; unsupported/unknown version
.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT


.found	add.w	(a0),a5



	move.l	a5,a0
.patch	move.l	d7,a1
	move.l	_resload(pc),a2
	jsr	resload_PatchSeg(a2)
.out	rts

.error	jsr	_LVOIoErr(a6)
	move.l	d6,-(a7)
	move.l	d0,-(a7)
	pea	(TDREASON_DOSREAD).w
	bra.b	EXIT


.game	dc.b	"iuc",0
	CNOP	0,4


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	_resload(pc),a2
	jmp	resload_Abort(a2)


; format: checksum, offset to patch list
PT_GAME	dc.w	$9e93,PLGAME-PT_GAME	; english
	dc.w	$b793,PLGAME_DE-PT_GAME	; german
	dc.w	$1ed0,PLGAME_FR-PT_GAME	; french
	dc.w	$6d13,PLGAME_IT-PT_GAME	; italian
	dc.w	0			; end of tab


AckLev6	moveq	#0,d0
	movem.l	(a7)+,d0-a6
	rts

; this is needed to avoid problems with the mouse control
; after a game has been saved
FixSave	move.b	#0,1(a2)		; original code

	movem.l	d0-a6,-(a7)
	move.l	_resload(pc),a2
	moveq	#10,d0			; wait at least 1 VBL
	jsr	resload_Delay(a2)
	movem.l	(a7)+,d0-a6
	rts

PLCOMMON
	PL_START
	PL_R	$1610			; disable level 6 interrupt
	PL_P	$1c1c,AckLev6
	PL_W	$1be2,$4e71		: disable VBI exit
	PL_R	$20ae			; disable delay after saving
	PL_SA	$1558,$1564		; skip buggy copperlist save
	PL_PSS	$1942,.checkNTSC,2	; fix buggy NTSC check
	PL_PSS	$23d0,.checkNTSC,2	; fix buggy NTSC check (write config)
	PL_W	$1abc,$01fe		; fix flickering status panel
	PL_END


.checkNTSC
	moveq	#0,d1			; default: PAL
	move.l	MON_ID(pc),d0
	cmp.l	#NTSC_MONITOR_ID,d0
	bne.b	.isPAL
	moveq	#1,d1			; NTSC
.isPAL	move.w	d1,d1			; set flags
	rts


PLGAME	PL_START
	PL_PS	$947e,.crack		; crack manual protection
	PL_PS	$fbde,FixSave		; wait 1 VBL before saving the game
	PL_NEXT	PLCOMMON
	PL_END

.crack	move.l	#$16dd4-$10ee4,d1	; data file number
	move.l	#$3348-2,d2		; offset
	bra.w	Crack


PLGAME_IT
	PL_START
	PL_PS	$947e,.crack		; crack manual protection
	PL_PS	$fc76,FixSave		; wait 1 VBL before saving the game
	PL_NEXT	PLCOMMON
	PL_END

.crack	move.l	#$179e0-$112bc,d1	; data file number
	move.l	#$3353-2,d2		; offset
	bra.w	Crack


PLGAME_DE
	PL_START
	PL_PS	$9466,.crack		; crack manual protection
	PL_PS	$fc5e,FixSave		; wait 1 VBL before saving the game
	PL_B	$10836+$5c,5		; fix width for "ä" in size tab 
	PL_B	$10836+$61,5		; fix width for "Ä" in size tab 
	;PL_PSS	$bca4,.debug,2
	PL_NEXT	PLCOMMON
	PL_END

; a0: text
;.debug	cmp.b	#"h",0(a0)
;	bne.b	.no
;	cmp.b	#",",1(a0)
;	bne.b	.no
;
;	move.b	#$a0,-1(a0)
;
;
;.rmb	btst	#2,$dff016
;	bne.b	.rmb
;.no
;	and.w	#$ff,d0
;	cmp.w	#$20,d0
;	rts

.crack	move.l	#$179dc-$112b8,d1	; data file number
	move.l	#$334f-2,d2		; offset
	bra.b	Crack


PLGAME_FR
	PL_START
	PL_PS	$9480,.crack		; crack manual protection
	PL_PS	$fc78,FixSave		; wait 1 VBL before saving the game
	PL_NEXT	PLCOMMON
	PL_END

.crack	move.l	#$17a20-$112fc,d1	; data file number
	move.l	#$335f-2,d2		; offset


; d0.l: size
; d1.l: offset to file number
; d2.l: offset to offset (yay) to skip protection
; d3.l: size
; a0.l: buffer

; this cracks the manual protection in such a way that it will be
; completely skipped!

Crack	move.l	a0,a1
.loop	eor.b	#$6f,(a0)+
	subq.l	#1,d0
	bne.b	.loop

	cmp.b	#18,1(a6,d1.l)		; +1 because variable is word sized
	bne.b	.out

	cmp.b	#$35,(a1,d2.l)		; jmp
	bne.b	.out

	lea	$30be-2(a1),a0		; entry point: $30be
	addq.w	#6,a0			; skip first 2 instructions
	move.b	#$35,(a0)+		; jmp opcode
	move.b	#$09,(a0)+		; $09: offset follows
	move.b	2(a1,d2.l),(a0)+	; offset (little endian)
	move.b	3(a1,d2.l),(a0)		; -> skip protection
.out	rts




TAGLIST	dc.l	WHDLTAG_MONITOR_GET
MON_ID	dc.l	0
	dc.l	TAG_END





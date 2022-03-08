***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(         MEGABALL WHDLOAD SLAVE             )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              April 2014                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 21-Jul-2016	- AGA version: ENV assign wasn't null-terminated so the
;		  game didn't start as there was a "Please insert volume ENV:"
;		  request (invisible due to BLACKSCREEN)

; 12-Apr-2014	- AGA version crashed due to a bug in AsmPro...
;		  fixed by assembling with NO68020 set

; 08-Apr-2014	- work started
;		- trainers added
;		- OCS version supported
;		- support for AGA version added, it requires quite
;		  a few extra files from the original workbench disk
;		  as it uses datatypes library

; extra files needed for AGA version:
; adddatatypes
; iffparse.library
; datatypes.library
; ilbm.datatype
; picture.datatype
; devs:dataytpes/ilbm

	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

AGA	= 1			; set to 1 to create slave for AGA version

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM

MC68020	MACRO
	ENDM

;CBKEYBOARD

;============================================================================

	IFEQ	AGA
CHIPMEMSIZE	= 524288
FASTMEMSIZE	= 524288
	ELSE
CHIPMEMSIZE	= 524288
FASTMEMSIZE	= 524288
	ENDC

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
DOSASSIGN
FONTHEIGHT	= 8
HDINIT
;HRTMON
;INITAGA
;INIT_AUDIO
;INIT_GADTOOLS
;INIT_LOWLEVEL
;INIT_MATHFFP
IOCACHE		= 4096
;JOYPADEMU
;MEMFREE	= $200
;NEEDFPU
NO68020
POINTERTICKS	= 1
;PROMOTE_DISPLAY
STACKSIZE	= 6000
;TRDCHANGEDISK

	IFNE	AGA
INITAGA
	ENDC	

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	; F10


;============================================================================

	IFEQ	AGA
		INCLUDE	Sources:whdload/kick13.s
	ELSE
		INCLUDE	Sources:whdload/kick31.s
	ENDC	

;============================================================================


slv_CurrentDir	IFD	DEBUG
		dc.b	"SOURCES:WHD_Slaves/Megaball/"
		ENDC
		dc.b	"data",0

slv_name	dc.b	"MegaBall"
		IFNE	AGA
		dc.b	" AGA"
		ENDC
		dc.b	0
slv_copy	dc.b	"1995 Ed Mackey",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"DEBUG!!! "
		ENDC
		dc.b	"Version 1.02 (21.07.2016)",0
slv_config	dc.b	"C1:B:Unlimited Lives;"
		dc.b	"C2:B:In-Game Keys"
		dc.b	0
	IFNE	AGA
cmd_adddt	dc.b	"adddatatypes refresh",0
env		dc.b	"ENV",0
	ENDC		

		CNOP	0,4

DOSbase	dc.l	0

	IFD BOOTDOS

_bootdos
	lea	_dosname(pc),a1
	move.l	$4.w,a6
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,a6
	lea	DOSbase(pc),a0
	move.l	d0,(a0)

	move.l	_resload(pc),a2
	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

	IFNE	AGA
	lea	cmd_adddt(pc),a0
	move.l	a0,d1
	moveq	#0,d2
	moveq	#0,d3
	jsr	_LVOExecute(a6)

	lea	env(pc),a0
	sub.l	a1,a1
	bsr	_dos_assign
	ENDC
	

; load game
.dogame	lea	.game(pc),a0

.run	lea	PT_GAME(pc),a1
	bsr.w	.LoadAndPatch

	move.l	d7,d1
	moveq	#.arglen,d0
	lea	.args(pc),a0
	movem.l	d7/a6,-(a7)		; save segment/dosbase
	bsr.b	.call
	movem.l	(a7)+,d1/a6
	jmp	_LVOUnLoadSeg(a6)



; d0.l: argument length
; d1.l: segment
; a0.l: argument (command line)
; a6.l: dosbase
.call	move.l	d1,d7		; save segment

	lsl.l	#2,d1
	add.l	#4,d1
	move.l	d1,a3

; install trainers
	move.w	#$4e71,d2	; nop
	moveq	#0,d3
	move.l	LIVESTR(pc),d1	; unlimited lives
	beq.b	.nolivestr
	eor.b	#$19,$4d62(a3)	; subq -> tst
	eor.b	#$19,$4ddc(a3)	; subq -> tst
.nolivestr

	move.l	INGAMEKEYS(pc),d1
	beq.b	.nokeys
	move.w	#$6008,d2
	move.l	#$34cc,d4
	bsr.b	.set
.nokeys

	tst.w	d3
	beq.b	.notrainer
	moveq	#1,d2
	move.l	#$2d2da,d4
	bsr.b	.set
	move.w	#$6004,$106e(a3)
.notrainer

	jmp	(a3)

.set	move.l	d7,d6

.getoffs
	lsl.l	#2,d6
	move.l	d6,a4
	move.l	-4(a4),d1	; hunk length
	subq.l	#2*4,d1		; header consists of 2 longs
	move.l	(a4),d6
	cmp.l	d4,d1
	bge.b	.hunkfound
	sub.l	d1,d4
	bra.b	.getoffs

.hunkfound
	move.w	d2,4(a4,d4.l)
	addq.w	#1,d3
	rts





; a0.l: file name
; a1.l: patch table
; a6.l: dos base
; ---
; d7: segment

.LoadAndPatch
	move.l	a1,a5		; a5: will contain start of entry in patch table
	move.l	a1,a3		; a3: start of patch table

	move.l	a0,d6		; save file name for IoErr
	move.l	a0,d1
	jsr	_LVOLoadSeg(a6)
	move.l	d0,d7		; d7: segment
	beq.b	.error

	bsr.b	.CRC16		; check all entries in patch table
	beq.b	.found

; unsupported/unknown version
.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.found	add.l	3*4(a5),a3	; a4: patch list

	move.l	a3,a0
.patch	move.l	d7,a1
	move.l	_resload(pc),a2
	jsr	resload_PatchSeg(a2)
.out	rts

.error	jsr	_LVOIoErr(a6)
	move.l	d6,-(a7)
	move.l	d0,-(a7)
	pea	(TDREASON_DOSREAD).w
	bra.w	EXIT


; a5.l: patch table
; d7.l: segment
; ----
; zflg: result, if set: entry with matching checksum found
; a5.l: ptr to start of entry in patch table

.CRC16	move.l	d7,d6
	move.l	(a5),d0		; offset
	bmi.b	.notfound

; find start offset in file
.getoffset
	lsl.l	#2,d6
	move.l	d6,a4
	move.l	-4(a4),d1	; hunk length
	subq.l	#2*4,d1		; header consists of 2 longs
	move.l	(a4),d6
	cmp.l	d0,d1
	bge.b	.thishunk
	sub.l	d1,d0
	bra.b	.getoffset

.thishunk
	lea	4(a4,d0.l),a0
	move.l	4(a5),d0	; end offset
	sub.l	(a5),d0		; -start offset = length for CRC16
	jsr	resload_CRC16(a2)
	move.l	2*4(a5),d1
	IFD	DEBUG
	move.w	d0,a0
	ENDC
	cmp.w	d0,d1
	beq.b	.entry_found
	add.w	#4*4,a5		; next entry in tab
	bra.b	.CRC16

.entry_found
.notfound
	rts

.game	dc.b	"MegaBall",0
.args	dc.b	"  ",10		; must be LF terminated
.arglen	= *-.args
	CNOP	0,4

.dosbase	dc.l	0


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	_resload(pc),a2
	jmp	resload_Abort(a2)


	CNOP 0,4


; format: start, end, checksum, offset to patch list
PT_GAME	dc.l	$d4fe,$d678,$8b56,PLGAME-PT_GAME	; v4.0
	dc.l	-1					; end of tab

PLGAME	PL_START
	PL_PSS	$33d4,.keys,2
	PL_END

.keys	move.b	$19(a5),d0

	move.l	INGAMEKEYS(pc),d1
	beq.b	.nokeys
	cmp.b	#"n",d0		; n - skip level
	bne.b	.noN
	move.b	#$a9,d0
.noN

	cmp.b	#"a",d0		; a - add extra life
	bne.b	.noA
	move.b	#$a5,d0
.noA

	cmp.b	#"e",d0		; e - get extras
	bne.b	.noE
	move.b	#$b6,d0
.noE


.nokeys
	cmp.b	#"Q",d0
	rts



TAGLIST		dc.l	WHDLTAG_CUSTOM1_GET	; custom1: unlimited lives
LIVESTR		dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET	; custom2: in-game keys
INGAMEKEYS	dc.l	0
		dc.l	TAG_END







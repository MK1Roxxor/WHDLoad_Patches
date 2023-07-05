***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      DAY OF THE VIPER WHDLOAD SLAVE        )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                               May 2013                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 05-Jul-2023	- simpler approach for fixing the Rename() problem used:
;		  _LVORename is directly patched in dos.library and WHDLoad
;		  functions are used to implement that functionality, this
;		  is done in 3 steps:
;		  1. memory for files is allocated at the beginning
;		  2. file to be renamed is loaded into memory allocated in 1.
;		  3. file loaded to memory in 2. is saved with the new name
;		- clicking "quit" icon works too now

; 07-Mar-2020	- patched Rename() in load/save routines, not fully done yet
;		- game crashes when clicking on quit icon, needs to be checked

; 07-May-2013	- work started


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
FASTMEMSIZE	= 0
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
HRTMON
;INITAGA
;INIT_AUDIO
;INIT_GADTOOLS
INIT_LOWLEVEL
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

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $59	; F10

;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================


slv_CurrentDir	IFD	DEBUG
		dc.b	"SOURCES:WHD_Slaves/DayOfTheViper/data",0
		ELSE
		dc.b	"data",0
		ENDIF

slv_name	dc.b	"Day of the Viper",0
slv_copy	dc.b	"1989 Accolade",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"Debug!!! "
		ENDC
		dc.b	"Version 1.01 (05.07.2023)",0
slv_config	dc.b	"C1:B:Skip Intro;"
		dc.b	"C2:B:Unlimited Energy;"
		dc.b	0
		CNOP	0,4

	IFD BOOTDOS

_bootdos

MAX_MAZE_SIZE	= 4096	; 4k should be fine, max. maze size is 2081 bytes


	; Allocate memory for renaming files
	move.l	#MAX_MAZE_SIZE,d0
	moveq	#MEMF_PUBLIC,d1
	move.l	$4.w,a6
	jsr	_LVOAllocMem(a6)
	lea	Temp_Memory(pc),a0
	move.l	d0,(a0)
	beq.w	QUIT

	lea	_dosname(pc),a1
	move.l	$4.w,a6
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,a6


	; Patch _LVORename in dos.library
	lea	_LVORename(a6),a1
	move.w	#$4ef9,(a1)
	pea	RenamePatch(pc)
	move.l	(a7)+,2(a1)




	move.l	_resload(pc),a2
	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

.runagain
	lea	.ix2(pc),a0
	tst.l	ENERGYTRAINER-.ix2(a0)
	bne.b	.trainerenabled
	clr.w	PLGAME\.PLTR-.ix2(a0)		; PLCMD_END


.trainerenabled

	tst.l	NOINTRO-.ix2(a0)
	bne.b	.skip
	lea	PT_IX2(pc),a1
	bsr.b	.do2			; $56180AC2

.skip	lea	.vx2(pc),a0
	bsr.b	.do

	sub.l	a1,a1
	lea	.wx2(pc),a0		; good end
	cmp.w	#10,d6
	beq.b	.go
	lea	.ex2(pc),a0		; bad end
.go	bsr.b	.do2
	tst.w	d6
	bne.b	.runagain
	bra.w	QUIT


.do	lea	PT_GAME(pc),a1
.do2	bsr.b	.LoadAndPatch
.run	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	movem.l	d7/a6,-(a7)
	lea	.cmd(pc),a0
	moveq	#.cmdlen,d0
	jsr	4(a1)

	move.l	d0,d6
	movem.l	(a7)+,d7/a6
	move.l	d7,d1
	jmp	_LVOUnLoadSeg(a6)

; a0.l: file name
; a1.l: patch table or 0 if no patching is required
; a6.l: dos base
; ---
; d7: segment

.LoadAndPatch
	move.l	a0,d6
	move.l	a1,a5
	move.l	a1,a4
	move.l	a0,d1
	jsr	_LVOLoadSeg(a6)
	move.l	d0,d7
	beq.b	.error

	move.l	a5,d0
	beq.b	.exit

.loop	movem.w	(a5)+,d0-d4	; checksum, start, end, hunk, patch list
	move.w	d0,d6
	beq.b	.found		; if checksum is 0 we don't care about it
	
; move to correct hunk
	move.l	d7,a0
	bra.b	.enter		; hunk 0 is special case
.gethunk
	move.l	(a0),a0
.enter	add.l	a0,a0
	add.l	a0,a0
	dbf	d3,.gethunk

	lea	4(a0,d1.w),a0
	moveq	#0,d0
	move.w	d2,d0
	sub.w	d1,d0
	move.l	_resload(pc),a2
	jsr	resload_CRC16(a2)
	cmp.w	d0,d6
	beq.b	.found
	tst.w	(a5)
	bne.b	.loop


; unsupported/unknown version
.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT


.found	lea	(a4,d4.w),a0
.patch	move.l	d7,a1
	move.l	_resload(pc),a2
	jsr	resload_PatchSeg(a2)
.exit	rts

.error	jsr	_LVOIoErr(a6)
	move.l	d6,-(a7)
	move.l	d0,-(a7)
	pea	(TDREASON_DOSREAD).w
	bra.b	EXIT


.cmd	dc.b	"",13,0			; fake command line
.cmdlen	= *-.cmd
.ix2	dc.b	"ix2",0
.vx2	dc.b	"vx2",0
.ex2	dc.b	"ex2",0
.wx2	dc.b	"wx2",0
	CNOP	0,4


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	_resload(pc),a2
	jmp	resload_Abort(a2)


; format: checksum, start, end, hunk, offset to patch list
; start/end offsets are relative to the hunk start!
PT_GAME

; game
	dc.w	$ef9c			; checksum
	dc.w	$7198-$7198,$71c8-$7198	; start, end for CRC16
	dc.w	4			; hunk
	dc.w	PLGAME-PT_GAME		; SPS 454

	dc.w	0			; end of tab


PT_IX2	dc.w	$7a1f			; checksum
	dc.w	$356-$234,$392-$234	; start, end for CRC16
	dc.w	3			; hunk
	dc.w	PLIX2-PT_IX2		; SPS 454

	dc.w	0			; end of tab

PLIX2	PL_START
	PL_B	$d42,$60		; disable protection check
	PL_END
	

PLGAME	PL_START
	PL_B	$73de,$60		; disable protection check
.PLTR	PL_B	$10562,$60		; unlimited energy
	PL_END



; ----------------------------------------------------------------------
; This is the _LVORename patch that is called whenever _LVORename() in
; dos.library is called. File to be rename is loaded into temp. memory
; and then saved with a new name.

; d1; old name
; d2: new name

RenamePatch
	movem.l	d1-a6,-(a7)
	move.l	d1,a0
	move.l	Temp_Memory(pc),a1
	move.l	_resload(pc),a2
	jsr	resload_LoadFile(a2)	; returns with file size in d0.l

	move.l	d2,a0
	move.l	Temp_Memory(pc),a1
	jsr	resload_SaveFile(a2)	
	movem.l	(a7)+,d1-a6
	moveq	#0,d0			; no errors
	rts


Temp_Memory	dc.l	0

; ----------------------------------------------------------------------



TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
		dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
NOINTRO		dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
ENERGYTRAINER	dc.l	0
		dc.l	TAG_END

	ENDC


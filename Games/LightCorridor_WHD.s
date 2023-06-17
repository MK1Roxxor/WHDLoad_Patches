***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       DEMOLITION WHDLOAD_SLAVE             )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             April 2023                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 17-Jun-2023	- SMC that caused graphics errors in main menu fixed
;		- game works with full caches now

; 14-Jun-2023	- file loading patch simplified
;		- crash fixed (code determined the file size of file
;		  "music.dum" from the custom directory table stored at
;		  offset $400 in the disk image, took way too long to
;		  figure out...)
;		- file saving implemented


; 11-Jun-2023	- work started

	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i


; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM


;============================================================================

CHIPMEMSIZE	= $80000	;size of chip memory
FASTMEMSIZE	= 256*1024	;size of fast memory
NUMDRIVES	= 1		;amount of floppy drives to be configured
WPDRIVES	= %0000		;write protection of floppy drives

;BLACKSCREEN			;set all initial colors to black
;BOOTBLOCK			;enable _bootblock routine
BOOTDOS			;enable _bootdos routine
;BOOTEARLY			;enable _bootearly routine
;CBDOSLOADSEG			;enable _cb_dosLoadSeg routine
;CBDOSREAD			;enable _cb_dosRead routine
;CBKEYBOARD			;enable _cb_keyboard routine
;CACHE				;enable inst/data cache for fast memory with MMU
CACHECHIP			;enable inst cache for chip/fast memory
;CACHECHIPDATA			;enable inst/data cache for chip/fast memory
;DEBUG				;add more internal checks
;DISKSONBOOT			;insert disks in floppy drives
;DOSASSIGN			;enable _dos_assign routine
FONTHEIGHT	= 8		;enable 80 chars per line
HDINIT				;initialize filesystem handler
HRTMON				;add support for HrtMON
IOCACHE		= 1024		;cache for the filesystem handler (per fh)
;MEMFREE	= $200		;location to store free memory counter
;NEEDFPU			;set requirement for a fpu
POINTERTICKS	= 1		;set mouse speed
SEGTRACKER			;add segment tracker
SETKEYBOARD			;activate host keymap
SETPATCH			;enable patches from SetPatch 1.38
;SNOOPFS			;trace filesystem handler
;STACKSIZE	= 6000		;increase default stack
;TRDCHANGEDISK			;enable _trd_changedisk routine

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	;F10

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

slv_CurrentDir	dc.b	"data",0
slv_name	dc.b	"The Light Corridor",0
slv_copy	dc.b	"1990 Infogrames",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"Debug (do not release!) "
		ENDC
		
		dc.b	"Version 2.00 (17.06.2023)",0
		dc.b	0

	IFGE slv_Version-17
slv_config
	dc.b	0
	ENDC
	EVEN


;============================================================================
; like a program from "startup-sequence" executed, full dos process,
; HDINIT is required, this will never called if booted from a diskimage, only
; works in conjunction with the virtual filesystem of HDINIT
; this routine replaces the loading and executing of the startup-sequence
;

	IFD BOOTDOS

_bootdos	
	move.l	_resload(pc),a2

	; Open dos.library
	lea	_dosname(pc),a1
	move.l	$4.w,a6
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,a6			; a6: dos base

	; Load game
	lea	Game_Name(pc),a0
	move.l	a0,d1
	jsr	_LVOLoadSeg(a6)
	move.l	d0,d7			; d7: segment
	beq.b	Program_Error

	; Check version
	move.l	d7,d0
	lsl.l	#2,d0
	move.l	d0,a0
	
	add.w	#$6+4,a0
	move.l	#$90-$6,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$0A3B,d0		; SPS 0526
	beq.b	.Version_is_Supported
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.Version_is_Supported


	; Patch game
	lea	PL_GAME(pc),a0
	move.l	d7,a1
	jsr	resload_PatchSeg(a2)

	IFD DEBUG
	;set debug
		clr.l	-(a7)
		move.l	d7,-(a7)
		pea	WHDLTAG_DBGSEG_SET
		move.l	a7,a0
		jsr	(resload_Control,a2)
		add.w	#12,a7
	ENDC


	; disable cache
	;move.l	#WCPUF_Exp_NCS,d0
	;move.l	#WCPUF_Exp,d1
	;jsr	resload_SetCPU(a2)


	; Run game
	move.l	d7,d1
	lsl.l	#2,d1
	move.l	d1,a1

	lea	Arguments(pc),a0
	moveq	#Arguments_Length,d0

	jsr	4(a1)

	; Quit back to DOS
QUIT	pea	(TDREASON_OK).w
EXIT	move.l	_resload(pc),a2
	jmp	resload_Abort(a2)


Program_Error
	jsr	_LVOIoErr(a6)
	pea	Game_Name(pc)
	move.l	d0,-(a7)
	pea	(TDREASON_DOSREAD).w
	jmp	resload_Abort(a2)


PL_GAME	PL_START
	PL_P	$a95a,.Open_File
	PL_P	$a768,.Load_File_Data
	PL_P	$a864,.Save_File_Data
	PL_P	$a666,.Get_File_Length
	PL_P	$aa1e,.Close_File
	PL_SA	$2c4e,$2c60			; skip protection checks

	PL_PS	$a11c,.Flush_Cache
	PL_P	$a188,.Flush_Cache2
	PL_PS	$9d08,.Flush_Cache3
	PL_PS	$A112,.Flush_Cache2
	PL_PS	$9aac,.Flush_Cache4
	PL_PS	$91d8,.Flush_Cache5
	PL_P	$9204,.Flush_Cache6

	PL_PS	$a0a6,.Flush_Cache7
	PL_PS	$9fb8,.Flush_Cache8
	PL_PS	$9aac,.Flush_Cache9
	PL_PS	$9b70,.Flush_Cache10
	PL_PS	$9be0,.Flush_Cache11
	PL_PS	$9c6c,.Flush_Cache12
	PL_PS	$a498,.Flush_Cache13		; main menu
	PL_PS	$a130,.Flush_Cache14

	PL_END

.Flush_Cache
	move.w	d1,d2
	add.w	d2,d2
	add.w	d2,d2
	bra.w	Flush_Cache

.Flush_Cache2
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	bra.w	Flush_Cache	

.Flush_Cache3
	move.l	d7,d6
	not.l	d4
	not.l	d6
	bra.w	Flush_Cache

.Flush_Cache4
	move.w	d0,a3
	swap	d0
	move.w	d0,d4
	bra.w	Flush_Cache

.Flush_Cache5
	move.w	(a2)+,d0
	add.w	(a2)+,d1
	add.w	(a2)+,d2
	bra.w	Flush_Cache

.Flush_Cache6
	bsr	Flush_Cache
	movem.l	(a7)+,d4-d7/a2-a5
	rts

.Flush_Cache7
	and.w	d2,d0
	move.w	d0,d1
	not.w	d1
	bra.w	Flush_Cache

.Flush_Cache8
	lea	$dff000,a1
	bra.w	Flush_Cache

.Flush_Cache9
	move.w	d0,a3
	swap	d0
	move.w	d0,d4
	bra.w	Flush_Cache

.Flush_Cache10
	move.l	(a1,d5.w),d5
	sub.w	d0,d4
	bra.w	Flush_Cache

.Flush_Cache11
	and.w	(a1,d4.w),d5
	move.w	d5,d4
	bra.w	Flush_Cache

.Flush_Cache12
	move.l	d5,d4
	move.w	d7,d6
	not.l	d4
	bra.w	Flush_Cache

.Flush_Cache13
	and.w	$20(a2,d2.w),d1
	move.w	d1,d0
	bra.w	Flush_Cache

.Flush_Cache14
	and.w	d1,d2
	sub.w	d2,d1
	moveq	#40,d2
	bra.w	Flush_Cache


.Get_File_Length
	move.l	4(a7),a0
	move.l	_resload(pc),a1
	jmp	resload_GetFileSize(a1)

.Open_File
	move.l	0*4+4(a7),a0
	lea	.File_Name(pc),a1
	move.l	a0,(a1)

	moveq	#1,d0
	cmp.l	#MODE_NEWFILE,1*4+4(a7)
	beq.b	.exit
	bsr.w	File_Exists
.exit	rts

.Load_File_Data
	move.l	.File_Name(pc),a0
	move.l	1*4+4(a7),a1			; destination
	move.l	2*4+4(a7),d0			; size
	lea	.File_Offset(pc),a2
	move.l	(a2),d1
	add.l	d0,(a2)
	move.l	_resload(pc),a2
	jmp	resload_LoadFileOffset(a2)

.Save_File_Data
	move.l	.File_Name(pc),a0
	move.l	1*4+4(a7),a1
	move.l	2*4+4(a7),d0
	lea	.File_Offset(pc),a2
	move.l	(a2),d1
	add.l	d0,(a2)
	move.l	_resload(pc),a2
	jmp	resload_SaveFileOffset(a2)

.Close_File
	lea	.File_Name(pc),a0
	clr.l	(a0)
	clr.l	.File_Offset-.File_Name(a0)
	rts

.File_Name	dc.l	0
.File_Offset	dc.l	0

Arguments		dc.b	"",10
Arguments_Length	= *-Arguments
Game_Name		dc.b	"cor.am2",0
			CNOP 0,4

	ENDC


; ---------------------------------------------------------------------------
; Support/helper routines.

WaitRaster
.wait1	btst	#0,$dff005
	beq.b	.wait1
.wait2	btst	#0,$dff005
	bne.b	.wait2
	rts



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


Wait_Blit
	tst.b	$dff002
.wait_blit
	btst	#6,$dff002
	bne.b	.wait_blit
	rts

Flush_Cache
	move.l	_resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts

; ---------------------------------------------------------------------------

; a0.l: file name
; a1.l: destination
; -----
; d0.l: file size

Load_File
	movem.l	d1-a6,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_LoadFileDecrunch(a2)
	movem.l	(a7)+,d1-a6
	rts

; a0.l: file name
; a1.l: data to save
; d0.l: size in bytes

Save_File
	movem.l	d1-a6,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_SaveFile(a2)
	movem.l	(a7)+,d1-a6
	rts

; a0.l: file name
; -----
; d0.l: result (0: file does not exist) 

File_Exists
	movem.l	d1-a6,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	movem.l	(a7)+,d1-a6
	rts

; ---------------------------------------------------------------------------

; a0.l: patch list
; a1.l: destination

Apply_Patches
	movem.l	d0-a6,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts


; V1.2, StingRay
; 23.11.2023: 	- started to add support for another version (issue #5911),
;		  file "Campaign" on disk 2 is broken though
;		- DMA wait in replayer and byte write to volume register
;		  fixed (game intro)
; 24.11.2023	- Retroplay supplied a working disk image, file "Campaign"
;		  patched
; 25.11.2023	- Map editor patched

	INCDIR	SOURcES:Include/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DEBUG
;DISKSONBOOT
DOSASSIGN
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH

;============================================================================

KICKSIZE	= $40000			;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	15			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulPriv|WHDLF_Examine|WHDLF_EmulTrap	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================
_data		dc.b	"data",0
intro		dc.b	"intro",0
master		dc.b	"master",0
_disk1		dc.b	3,"df0",0
_args		dc.b	10
_args_end

_name		dc.b	"Campaign",0
_copy		dc.b	"1992 Empire",0
_info		dc.b	"installed & fixed by Bored Seal & StingRay",10
		dc.b	"V1.2 (25-Nov-2023)",0
		even

; ---------------------------------------------------------------------------
; V1.2 additions, StingRay


PL_INTRO_V2
	PL_START
	PL_S	$2f9e,$2fb2-$2f9e	; skip disk change check

	; fix CPU dependent DMA wait in replayer
	PL_PSS	$4b4c,Fix_DMA_Wait,2
	PL_PSS	$4b62,Fix_DMA_Wait,2

	; fix byte write to volume register
	PL_P	$4dfe,Fix_Volume_Write
	PL_END

PL_MASTER_V2
	PL_START
	PL_R	$19b4			; disable game disk request
	PL_GA	$434,.File_Name

	PL_P	$1b14,.Patch_Executable
	PL_END

.Patch_Executable
.relocate
	move.l	(a1)+,d3
	add.l	d2,(a2,d3.l)
	subq.l	#1,d1
	bne.b	.relocate

	movem.l	d0-a6,-(a7)

	lea	.TAB(pc),a2
.check_all_entries
	movem.w	(a2)+,d0/d1
	lea	.TAB(pc,d0.w),a3
	move.l	.File_Name(pc),a1
	move.l	(a1),a1
.check_file_name
	move.b	(a3)+,d0
	beq.b	.file_found
	move.b	(a1)+,d2
	or.b	#1<<5,d2
	cmp.b	d0,d2
	beq.b	.check_file_name

.check_next_entry
	tst.w	(a2)
	bne.b	.check_all_entries

	; no patches required, just flush the cache
	moveq	#PL_NOTHING-.TAB,d1

.file_found	
	lea	$20(a0),a1
	lea	.TAB(pc,d1.w),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts

.TAB	dc.w	.Campaign-.TAB,PL_CAMPAIGN_V2-.TAB
	dc.w	.Mapedit-.TAB,PL_MAPEDIT_V2-.TAB
	dc.w	0

.Campaign	dc.b	"campaign",0
.Mapedit	dc.b	"mapedit",0
		CNOP	0,2	


.File_Name	dc.l	0


PL_CAMPAIGN_V2
	PL_START
	PL_W	$1748,$605a	; disable manual protection
	PL_W	$1ae2,$605a	; disable manual protection
	PL_S	$1834,4		; skip disk space check
	PL_END

PL_MAPEDIT_V2
	PL_START
	PL_W	$1850,$605a	; disable manual protection
	PL_W	$1bea,$605a	; disable manual protection
	PL_S	$193c,4		; skip disk space check
	PL_END

PL_NOTHING
	PL_START
	PL_END


Fix_DMA_Wait
	moveq	#8,d0
	bra.w	Wait_Raster_Lines


Fix_Volume_Write
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts


; d0.w: number of raster lines to wait
Wait_Raster_Lines
	move.w	d1,-(a7)
.loop	move.b	_custom+vhposr,d1
.still_in_same_raster_line
	cmp.b	_custom+vhposr,d1
	beq.b	.still_in_same_raster_line	
	subq.w	#1,d0
	bne.b	.loop
	move.w	(a7)+,d1
	rts


; a0.l: pointer to patch list
; d7.l: segment

Apply_Patches
	movem.l	d0-a6,-(a7)
	move.l	d7,a1
	move.l	_resload(pc),a2
	jsr	resload_PatchSeg(a2)
	movem.l	(a7)+,d0-a6
	rts

; a0.l: memory
; d0.l: size to check
; ----
; d0.w: checksum
Checksum
	movem.l	d1-a6,-(a7)
	move.l	_resload(pc),a1
	jsr	resload_CRC16(a1)
	movem.l	(a7)+,d1-a6
	rts	


; End of V1.2 additions, StingRay
; ---------------------------------------------------------------------------


_start
	;initialize kickstart and environment
		bra	_boot

_bootdos	move.l	(_resload,pc),a2	;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	$4.w,a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		lea	(_disk1,pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	intro(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
	



		movem.l	d0/a6,-(sp)
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		addq.l	#4,a1

	lea	$b56(a1),a0
	move.l	#$15e6-$b56,d0
	move.l	a1,-(a7)
	jsr	resload_CRC16(a2)
	move.l	(a7)+,a1
	lea	PL_INTRO_V2(pc),a0
	cmp.w	#$4ef3,d0			; V2, Christoph Gleisberg
	beq.w	.Supported_Version_Found
	bra.w	.check_V1

.Supported_Version_Found
	move.l	a1,-(a7)
	move.l	d7,a1
	jsr	resload_PatchSeg(a2)
	move.l	(a7)+,a1
	bra.w	.Run_Intro



.check_V1
		cmp.l	#$4eaeff9a,$33e0(a1)
		bne.w	Unsupported
		move.l	#$60000068,$3482(a1)	;skip disk change stuff

.Run_Intro
		bsr	_flushcache
		jsr	(a1)
		movem.l	(sp)+,d1/a6
		jsr	-156(a6)		;unload intro

;load/patch master
		lea	master(pc),a0
		move.l	a0,d1
		jsr	-150(a6)

		move.l	d0,d7			;D7 = segment
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		addq.l	#4,a1


	lea	$548(a1),a0
	move.l	#$608-$548,d0
	bsr	Checksum
	cmp.w	#$db8a,d0
	bne.b	.Check_Other_Versions


	lea	PL_MASTER_V2(pc),a0
	bsr	Apply_Patches
	jmp	(a1)


.Check_Other_Versions
		cmp.l	#$4ea80020,$1ac0(a1)
		beq.b	game_v1
		cmp.l	#$4ea80020,$1a8c(a1)
		bne.b	Unsupported

game_v2		move.l	#$4eb80100,$1a8c(a1)
		move.w	#$6012,$19ec(a1)	;skip dskready
		bra.b	game_all

game_v1		move.l	#$4eb80100,$1ac0(a1)
game_all	move.w	#$4ef9,$100.w
		pea	PatchGame(pc)
		move.l	(sp)+,$102.w

		bsr	_flushcache
		jsr	(a1)

		pea	(TDREASON_OK).w
		move.l	_resload(pc),a2
		jmp	(resload_Abort,a2)

PatchGame	lea	$20(a0),a0
		cmp.l	#$b03c000d,$173e(a0)	;file Campaign
		bne.b	testmap
		
		move.w	#$605a,$173c(a0)	;crack manual protection
		move.w	#$605a,$1ad6(a0)
		move.w	#$6002,$1828(a0)	;don't check free disk space

testmap		cmp.l	#$b03c000d,$1846(a0)	;file MapEdit
		bne.b	.skip

		move.w	#$605a,$1844(a0)	;crack manual protection
		move.w	#$605a,$1bde(a0)
		move.w	#$6002,$1930(a0)	;don't check free disk space

.skip		bsr	_flushcache
		jmp	(a0)

Unsupported	pea	(TDREASON_WRONGVER).w
		move.l	_resload(pc),a2
		jmp	(resload_Abort,a2)

		INCLUDE	SOURCES:WHDLoad/kick13.s
		END

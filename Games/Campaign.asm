	INCDIR	Include:
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
_copy		dc.b	"1993 Empire",0
_info		dc.b	"installed & fixed by Bored Seal",10
		dc.b	"V1.1 (02-Aug-2008)",0
		even

_start
	;initialize kickstart and environment
		bra	_boot

_bootdos	move.l	(_resload),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		lea	(_disk1),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	intro,a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment

		movem.l	d0/a6,-(sp)
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		add.l	#4,a1
		cmp.l	#$4eaeff9a,$33e0(a1)
		bne	Unsupported

		move.l	#$60000068,$3482(a1)	;skip disk change stuff
		bsr	_flushcache
		jsr	(a1)
		movem.l	(sp)+,d1/a6
		jsr	-156(a6)		;unload intro

;load/patch master
		lea	master,a0
		move.l	a0,d1
		jsr	-150(a6)

		move.l	d0,d7			;D7 = segment
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		add.l	#4,a1

		cmp.l	#$4ea80020,$1ac0(a1)
		beq	game_v1
		cmp.l	#$4ea80020,$1a8c(a1)
		bne	Unsupported

game_v2		move.l	#$4eb80100,$1a8c(a1)
		move.w	#$6012,$19ec(a1)	;skip dskready
		bra	game_all

game_v1		move.l	#$4eb80100,$1ac0(a1)
game_all	move.w	#$4ef9,$100
		pea	PatchGame
		move.l	(sp)+,$102

		bsr	_flushcache
		jsr	(a1)

		pea	TDREASON_OK
		move.l	_resload,a2
		jmp	(resload_Abort,a2)

PatchGame	lea	$20(a0),a0
		cmp.l	#$b03c000d,$173e(a0)	;file Campaign
		bne	testmap
		
		move.w	#$605a,$173c(a0)	;crack manual protection
		move.w	#$605a,$1ad6(a0)
		move.w	#$6002,$1828(a0)	;don't check free disk space

testmap		cmp.l	#$b03c000d,$1846(a0)	;file MapEdit
		bne	skip

		move.w	#$605a,$1844(a0)	;crack manual protection
		move.w	#$605a,$1bde(a0)
		move.w	#$6002,$1930(a0)	;don't check free disk space

skip		bsr	_flushcache
		jmp	(a0)

Unsupported	pea	TDREASON_WRONGVER
		move.l	_resload,a2
		jmp	(resload_Abort,a2)

		INCLUDE	kick13.s
		END

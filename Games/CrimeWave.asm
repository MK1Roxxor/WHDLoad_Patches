	INCDIR	"Include:"
	INCLUDE	whdload.i

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	10			;ws_Version
		dc.w	WHDLF_NoError		;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	_dir-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
		dc.l	0
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

_dir		dc.b	"data",0
_name		dc.b	"Crime Wave",0
_copy		dc.b	"1990 US Gold",0
_info		dc.b	"installed & fixed by Bored Seal",10
		dc.b	"V1.1 (07-Jul-2006)",0
		even

_Start		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later using

		move.l	a0,a2
                lea     (_tags,pc),a0
                jsr     (resload_Control,a2)

		lea	filename,a0
		lea	$10e4,a1
		move.l	a1,-(sp)
		jsr	(resload_LoadFile,a2)

		move.l	(sp)+,a0
		jsr	(resload_CRC16,a2)
		cmp.w	#$7d36,d0
		bne	Unsupported

		move.w	#$4e71,d0		;crack it
		move.w	d0,$f79c
		move.w	d0,$f7a0

		move.w	#$4e75,$175ba		;remove disk access
		move.w	#$4e75,$17802
		move.w	#$6012,$20dc

		move.w	#$6002,$b1b2		;remove access fault

		move.w	#$4ef9,$15b32
		pea	LoadFile
		move.l	(sp)+,$15b34

		lea	$15cec,a0		;fix filenames
		lea	$16b94,a1		;replace '\' by '/'
Replace		move.b	(a0)+,d0
		cmp.b	#$5c,d0
		bne	NoLomitko
		move.b	#$2f,-(a0)
NoLomitko	cmp.l	a0,a1
		bne	Replace

		lea	trainer,a1
		tst.l	(a1)
		beq	NoTrainer

		move.l	#$4e714e71,$3b40	;unlimited lives
		move.w	#$4a79,d0
		move.w	d0,$39d0		;unlimited ammo1
		move.w	d0,$38d4		;unlimited rocked
NoTrainer	jmp	$1100

LoadFile	movem.l d1/a0-a2,-(sp)
		move.l	a0,-(sp)
		lea	$15cea,a0		;search for name
		subq	#1,d0
		bmi	FileFound
SearchName	cmpi.b	#0,(a0)+
		bne	SearchName
		dbra	d0,SearchName
FileFound	move.w	(a0)+,d0		;move disk drive name
		move.l	(sp)+,a1		;restore bugger
Load		move.l	(_resload,pc),a2
		jsr	(resload_LoadFile,a2)
		movem.l	(sp)+,d1/a0-a2
		rts

Unsupported	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

_resload	dc.l	0
_tags		dc.l	WHDLTAG_CUSTOM1_GET
trainer		dc.l    0,0
filename	dc.b	"boot.prg",0
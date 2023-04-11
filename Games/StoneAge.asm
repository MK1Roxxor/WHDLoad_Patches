;*---------------------------------------------------------------------------
;  :Program.	StoneAge.asm
;  :Contents.	Slave for "Stone Age" from Eclipse
;  :Author.	Mr.Larmer of Wanted Team, Bored Seal
;  :History.	06.10.1999
;               29.01.2001 (done by Bored Seal)
;                          - load/save highscore support added
;                          - some snoopAGA bugs fixed
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

		INCDIR	Include:
		INCLUDE	whdload.i

base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$100000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0		;ws_keydebug = none
_keyexit	dc.b	$5D		;ws_keyexit = '*'
		dc.l	0		;ws_ExpMem
		dc.w	_name-base	;ws_name
		dc.w	_copy-base	;ws_copy
		dc.w	_info-base	;ws_info

_name		dc.b	'Stone Age',0
_copy		dc.b	'1992 Eclipse',0
_info		dc.b	'Installed and fixed by Mr.Larmer',10
		dc.b	'Version 1.1 (29-Jan-2001)',-1
		dc.b	'Greetings to Larry Nall',0
		CNOP 0,2

Start		lea	_resload(pc),a1
		move.l	a0,(a1)

		lea	$55730,A0
		move.l	#$1400,D0
		move.l	D0,D1
		moveq	#1,d2
		bsr.w	_LoadDisk

		move.l	a0,-(a7)
		move.l	#$1400,D0
		move.l	_resload(pc),a2
		jsr	resload_CRC16(a2)
		move.l	(a7)+,a0

		cmp.w	#$93D6,D0
		bne.w	.not_support

		move.w	#$4E71,8(a0)		; skip original return address

		pea	Patch(pc)
		jmp	(A0)
.not_support
		subq.l	#8,a7
		pea	TDREASON_WRONGVER.w
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

Patch		lea	$5836A,a0		; load protection track
		move.l	#$2800,d0
		move.l	#$200,d1
		moveq	#1,d2
		bsr.w	_LoadDisk

		lea	$5BB6A,a0
		move.l	#$94*$1400,d0
		move.l	#$B*$1400,d1
		moveq	#1,d2
		bsr.w	_LoadDisk

		moveq	#$7D,d0
		move.l	#'MMUD',d1
		moveq	#2,d6
		eor.b	d0,d1
		lea	$574A4,a0
		lea	$5816A,a1
		add.l	d6,a0
decode		eor.l	d1,(a0)
		move.l	(a0)+,d1
		cmp.l	a1,a0
		blt.b	decode

		move.w	#$225F,$574CE		; move.l (a7),a1 -> move.l (a7)+,a1
		move.w	#$604E,$5767C		; skip set cache and vbr
		move.b	#$60,$576CC		; go

		move.l	#$600003CA,$57B6E	; skip read protection track used to decode crunched file
		move.w	#$4E71,$58162		; subq.l #1,a7 -> nop

		pea	Patch2(pc)
		move.l	#$80000,-(a7)		; ext. mem

		jmp	$574A6

Patch2		move.l	#$70FF607A,$803DC	; skip set cache and vbr

		move.w	#$4EF9,$8C756
		pea	Loader
		move.l	(a7)+,$8C758

		move.w	#$4e71,$8061e		;snoop bux
		move.w	#$4e71,$806c0
		move.w	#$4e71,$872f2

		move.w	#$4ef9,$8da28
		pea	LoadHi
		move.l	(sp)+,$8da2a

		move.w	#$4ef9,$8d7fa
		pea	SaveHi
		move.l	(sp)+,$8d7fc

		jmp	$80000

LoadHi		movem.l	d1-d7/a0-a6,-(sp)
		bsr	Params
                jsr     (resload_GetFileSize,a2)
                tst.l   d0
                beq     NoHisc
		bsr	Params
		jsr	(resload_LoadFile,a2)
NoHisc		movem.l	(sp)+,d1-d7/a0-a6
		moveq	#-1,d0
		rts

Params		lea	hiscore,a0
		lea	$8b7b1,a1
		move.l	(_resload,pc),a2
		rts

SaveHi		movem.l	d0-d7/a0-a6,-(sp)
		bsr	Params
		move.l	#$129,d0
		jsr	(resload_SaveFile,a2)
		movem.l	(sp)+,d0-d7/a0-a6
		rts

Loader		movem.l	d0-a6,-(a7)
		btst	#0,d1
		bne.b	skip
		tst.l	d1
		beq.b	skip
		moveq	#1,d2
		bsr.b	_LoadDisk
skip		movem.l	(a7)+,d0-a6
		rts

_LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

_resload	dc.l	0
hiscore		dc.b	"StoneAge.High",0
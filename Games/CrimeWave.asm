; V1.2, StingRay
; 10-Apr-2022	- manual protection completely skipped
;		- keyboard routine fixed
;		- 68000 quitkey support
;		- file loader patch rewritten, it is 68000 compatible now

	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i

GAME_ADDRESS		= $1100-$1c
FILE_TABLE_OFFSET	= $14c06


_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
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
; v16
	dc.w	0			; ws_kickname
	dc.l	0			; ws_kicksize
	dc.w	0			; ws_kickcrc

; v17
	dc.w	.config-_base		; ws_config


.config
	dc.b	"C1:B:Enable Trainer"
	dc.b	0


_dir		dc.b	"data",0
_name		dc.b	"Crime Wave",0
_copy		dc.b	"1990 US Gold",0
_info		dc.b	"installed & fixed by Bored Seal & StingRay",10
		dc.b	"V1.2 (10-Apr-2022)",0
		even

_Start		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later using

		move.l	a0,a2
                lea     (_tags,pc),a0
                jsr     (resload_Control,a2)

		lea	filename(pc),a0
		lea	$10e4.w,a1
		move.l	a1,-(sp)
		jsr	(resload_LoadFile,a2)

		move.l	(sp)+,a0
		jsr	(resload_CRC16,a2)
		cmp.w	#$7d36,d0
		bne.w	Unsupported


		move.w	#$4e75,$175ba		;remove disk access
		move.w	#$4e75,$17802
		move.w	#$6012,$20dc

		move.w	#$6002,$b1b2		;remove access fault

		lea	trainer(pc),a1
		tst.l	(a1)
		beq.b	NoTrainer

		move.l	#$4e714e71,$3b40	;unlimited lives
		move.w	#$4a79,d0
		move.w	d0,$39d0		;unlimited ammo1
		move.w	d0,$38d4		;unlimited rocked
NoTrainer


	; V1.2
	lea	PL_GAME(pc),a0
	lea	(GAME_ADDRESS).w,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

		jmp	$1100.w

PL_GAME	PL_START
	PL_R	$e608			; disable protection check
	PL_PS	$16a44,.Fix_Keyboard_Delay
	PL_PS	$16a32,.Check_Quit_Key
	PL_P	$14a4e,Load_File
	PL_END

.Fix_Keyboard_Delay
	movem.l	d0/d1,-(a7)
	moveq	#3-1,d0
.loop	move.b	$dff006,d1
.same_raster_line
	cmp.b	$dff006,d1
	beq.b	.same_raster_line
	dbf	d0,.loop
	movem.l	(a7)+,d0/d1
	rts


.Check_Quit_Key
	move.b	$bfec01,d0
	move.l	d0,-(a7)
	ror.b	d0
	not.b	d0
	bsr.b	Check_Quit_Key
	move.l	(a7)+,d0
	rts


; d0.w: file number
; a0.l: destination

Load_File
	movem.l	d1-a6,-(a7)
	lea	GAME_ADDRESS+FILE_TABLE_OFFSET,a1
	
.find_file_entry
	tst.w	d0
	beq.b	.file_entry_found
.find_file_name_end
	tst.b	(a1)+
	bne.b	.find_file_name_end
	subq.w	#1,d0
	bra.b	.find_file_entry


.file_entry_found
	addq.w	#2,a1		; skip disk number

	move.l	a1,a2
.filter_file_name
	cmp.b	#"\",(a2)
	bne.b	.file_name_character_is_valid
	move.b	#"/",(a2)

.file_name_character_is_valid
	addq.w	#1,a2
	tst.b	(a2)
	bne.b	.filter_file_name

	exg	a0,a1
	move.l	_resload(pc),a2
	jsr	resload_LoadFileDecrunch(a2)
	movem.l	(a7)+,d1-a6
	rts


; d0.b: raw key code
Check_Quit_Key
	cmp.b	_base+ws_keyexit(pc),d0
	beq.b	QUIT
	rts

QUIT	pea	(TDREASON_OK).w
	bra.w	_end



Unsupported	pea	(TDREASON_WRONGVER).w
_end		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

_resload	dc.l	0
_tags		dc.l	WHDLTAG_CUSTOM1_GET
trainer		dc.l    0,0
filename	dc.b	"boot.prg",0

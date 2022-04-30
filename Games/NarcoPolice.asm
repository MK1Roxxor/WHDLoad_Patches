; V1.2, StingRay
;
; 28.04.2022: - made source 100 pc-relative
;
; 30.04.2022: - 68000 quitkey support
;             - default quitkey changed to Del as F10 is used in the
;               game (player can be controlled with F6-F10)
;             - WHDLoad v17+ features used
;             - ButtonWait code redone using WHDLoad functions (resload_Delay)

	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i

HEADER
_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoKbd
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$46			;ws_keyexit = Del
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

		; v16
		dc.w	0			; ws_kickname
		dc.l	0			; ws_kicksize
		dc.w	0			; ws_kickcrc

		; v17
		dc.w	.config-HEADER		; ws_config


.config	dc.b	"BW"
	dc.b	0

_name		dc.b	"Narco Police",0
_copy		dc.b	"1990 Dinamic",0
_info		dc.b	"installed & fixed by Bored Seal & StingRay",10
		dc.b	"V1.2 (30-Apr-2022)",0
		even

resload	dc.l	0

_Start		lea	(resload,pc),a1
		move.l	a0,(a1)
		move.l	a0,a2

		lea	$800.w,a6
		moveq	#2,d0
		move.l	#$1000,d1
		bsr	LoadTracks

		move.w	#$4ef9,$bc2.w
		pea	LoadTracks(pc)
		move.l	(sp)+,$bc4.w

		move.l	#$4e714eb9,$13b0.w
		pea	BeamDelay(pc)
		move.l	(sp)+,$13b4.w

		pea	PatchIntro(pc)
		move.l	(sp)+,$8c6.w

		pea	PatchGame(pc)
		move.l	(sp)+,$8fc.w

		jmp	$866.w

PatchIntro
	lea	PL_INTRO(pc),a0
	lea	$2a000,a1
	bsr	Apply_Patches

		jmp	$2a006


PL_INTRO
	PL_START
	PL_PSS	$52,.Check_Quit_Key,2
	PL_END


.Check_Quit_Key
	tst.b	$BFED01
	bpl.b	.exit

	Lea	.Key_Flag(pc),a0

	bchg	#0,(a0)
	beq.b	.Get_New_Key
	clr.b	$BFEE01
	bra.b	.exit

.Get_New_Key
	move.b	$BFEC01,d0
	ror.b	d0
	not.b	d0
	bsr	Check_Quit_Key

	move.b	#$51,$BFEE01
	clr.b	$BFEC01
	
.exit

	btst	#6,$bfe001
	rts

.Key_Flag	dc.b	0,0



PatchGame	move.w	#$601c,$3556c		;fix keyboard bug
		move.w	#$600e,$2aa76		;big delay


	lea	PL_GAME(pc),a0
	lea	$2a000,a1
	bsr	Apply_Patches

		jmp	$2a006

PL_GAME	PL_START
	PL_PS	$b526,.Check_Quit_Key
	PL_IFBW
	PL_PS	$a28,.Button_Wait
	PL_ENDIF
	PL_END

.Check_Quit_Key
	move.b	$bfec01,d0
	move.l	d0,-(a7)
	ror.b	d0
	not.b	d0
	bsr	Check_Quit_Key
	move.l	(a7)+,d0
	rts

.Button_Wait
	moveq	#5*10,d0
	move.l	resload(pc),a0
	jsr	resload_Delay(a0)
	lea	$6fd24,a0
	rts




LoadTracks	movem.l	d0-d2/a0-a2,-(sp)
		move.l	a6,a0
		mulu.w	#$200,d0
		moveq	#1,d2
		move.l	(resload,pc),a2
		jsr	(resload_DiskLoad,a2)
		move.w	#$8210,$dff096
		movem.l	(sp)+,d0-d2/a0-a2
		rts

BeamDelay	moveq	#9,d0
		bra.b	Wait_Raster_Lines





; ---------------------------------------------------------------------------

; a0.l: patch list
; a1.l: destination

Apply_Patches
	movem.l	d0-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts


; ---------------------------------------------------------------------------


; d0.b: rawkey code

Check_Quit_Key
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	rts	


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)


KillSys	move.w	#$7fff,$dff09a
	bsr.b	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
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

WaitRaster
.wait1	btst	#0,$dff005
	beq.b	.wait1
.wait2	btst	#0,$dff005
	bne.b	.wait2
	rts

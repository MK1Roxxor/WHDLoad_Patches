		INCDIR	SOURCES:Include/
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

HEADER
_base		SLAVE_HEADER
		dc.w	17
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoKbd
		dc.l	$80000
		dc.l	0
		dc.w	_Start-_base
		dc.l	_dir-_base
_keydebug	dc.b	0
_keyexit	dc.b	$59
		dc.l	0
		dc.w	_name-_base
		dc.w	_copy-_base
		dc.w	_info-_base

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"C1:B:Enable In-Game Cheat;"
	dc.b	"C2:B:Second Button Support (Weapon Selection)"
	dc.b	0


_dir		dc.b	"data",0
_name		dc.b	"Atomic RoboKid",0
_copy		dc.b	"1990 Activision",0
_info		dc.b	"installed & fixed by Abaddon/Bored Seal/StingRay",10
		dc.b	"V1.5 (23-May-2021)",0
		even

	INCLUDE	SOURCES:WHD_Slaves/AtomicRobokid/ReadJoypad.s
	

_Start		lea	(_resload,PC),a1
		move.l	a0,(a1)


	bsr	_detect_controller_types

		lea	$2000.w,a0
		moveq	#0,d0
		moveq	#$16,d1
		move.l	#$265,d2
		bsr	LoadRNCTracks

		bsr	LoadHi			;load highscore file if present

		movem.l	a0-a6/d0-d7,-(sp)
		lea	_patchgame(pc),a0
		suba.l	a1,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)
		jmp	$2000.w

_patchgame	PL_START
		PL_P	$5536,LoadRNCTracks	;loader
		PL_L	$d8e6,$3C89612C		;remove RNC copylock
		PL_R	$d8ea

	;insert blitter waits (through BLITWAIT macro in whdmacros.i)
		PL_P	$3c6e,Blit_D0
		PL_PS	$3bd8,BlitAdr1
		PL_PS	$3ae0,BlitAdr2
		PL_PS	$3940,Blit_1001
		PL_PS	$3b2e,Blit_402
		PL_PS	$3b52,Blit_402
		PL_PS	$425e,BlitFix2
		PL_PS	$38f0,BlitFix3
		PL_PS	$3932,BlitFix4
		PL_PS	$398a,BlitFix4
		PL_PS	$41cc,BlitFix5
		PL_PS	$3ac4,BlitFix6
		PL_PS	$3bbc,BlitFix7
		PL_P	$780A,Blit_C715
		PL_P	$6BE6,Blit_3f15
		PL_P	$b0,Blit_D0
		PL_L	$59FE,$4EB800B0
		PL_L	$3C38,$4EB800B0

	;patch dbxx loops in ActivisionPro music player
		PL_L	$e852,$4e714e71
		PL_PS	$e856,BeamDelay
		PL_PS	$e864,BeamDelay2
		PL_L	$eeb0,$4e714e71
		PL_PS	$eeb4,BeamDelay
		PL_PS	$eee0,BeamDelay2

	;insert highscore save routine
		;PL_P	$72a4,SaveHi


	PL_IFC1
	PL_W	$2000+$828,1
	PL_ELSE
		PL_P	$72a4,SaveHi

	PL_ENDIF

	PL_IFC2
	PL_PSS	$2000+$d18,.ReadJoyPad,2
	PL_ENDIF


	PL_PS	$2000+$e9a,.CheckQuitKey


		PL_END


.QUIT	pea	(TDREASON_OK).w
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.CheckQuitKey
	bsr.b	.GetKey
	not.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	.QUIT

	
.GetKey	move.b	$c00(a1),d0
	ror.b	d0
	rts


.ReadJoyPad
	movem.l	d0/a0,-(a7)

	bsr	_read_joysticks_buttons

	move.l	joy1_buttons(pc),d0
	btst	#JPB_BTN_BLU,d0
	beq.b	.no_button_2
	cmp.l	.last_button(pc),d0
	beq.b	.same_as_last

	move.b	#$3f,$26a4.w		; store key code for "space"


.no_button_2
	lea	.last_button(pc),a0
	move.l	d0,(a0)

.same_as_last
	movem.l	(a7)+,d0/a0
	addq.w	#1,$26b6.w
	tst.w	$26b2.w
	rts

.last_button	dc.l	0




BeamDelay	moveq	#5,d0
		bra.b	BM_1

BeamDelay2	moveq	#2,d0
BM_1		move.w  d0,-(sp)
		move.b	$dff006,d0
BM_2		cmp.b	$dff006,d0
		beq.b	BM_2
		move.w	(sp)+,d0
		dbf	d0,BM_1
End		rts


Blit_402	move.w	#$402,$58(a0)
		bra.b	BlitWait

Blit_1001	move.w	#$1001,$dff058
		bra.b	BlitWait

Blit_C715	move.w	#$c715,$dff058
		bra.b	BlitWait

Blit_3f15	move.w	#$3f15,$dff058
		bra.b	BlitWait

Blit_D0		move.w	d0,$dff058
		bra.b	BlitWait

BlitAdr1	move.w	$3bb6,$dff058
		bra.b	BlitWait

BlitFix2	adda.l	#$2a,a2
		bra.b	BlitWait

BlitFix3	bsr.b	BlitWait
		adda.w	d6,a4
		move.l	a6,$54(a0)
		rts

BlitFix4	bsr.b	BlitWait
		add.w	d2,d2
		adda.w	(a2,d2.w),a4
		rts

BlitFix5	lea	$dff000,a0
		bra.b	BlitWait

BlitFix6	adda.l	#$2a,a6
		BRA.b	BlitWait

BlitFix7	adda.l	#$2a,a1
		BRA.b	BlitWait

BlitAdr2	move.w	$3abe,$58(a0)
		bra.w	BlitWait

BlitWait	;BLITWAIT

		tst.b	(_custom+dmaconr)
		btst	#DMAB_BLTDONE-8,(_custom+dmaconr)
		beq.b	.done
.wait		tst.b	(_ciaa)		;this avoids blitter slow down
		tst.b	(_ciaa)		;this avoids blitter slow down
		tst.b	(_ciaa)		;this avoids blitter slow down
		tst.b	(_ciaa)		;this avoids blitter slow down
		btst	#DMAB_BLTDONE-8,(_custom+dmaconr)
		bne.b	.wait
.done		tst.b	(_custom+dmaconr)
		rts

LoadRNCTracks	MOVEM.L	D1-D7/A0-A6,-(SP)
		MOVE.L	D0,D3
		MOVE.W	D1,D0
		MULU.W	#$200,D0
		MOVEQ	#0,D1
		MOVE.W	D2,D1
		MULU.W	#$200,D1
		MOVE.L	D3,D2
		ADDQ.L	#1,D2
		MOVEA.L	(_resload,PC),A2
		JSR	resload_DiskLoad(A2)
		MOVEM.L	(SP)+,D1-D7/A0-A6
		MOVEQ	#0,D0
		RTS

;score points table is at $713a, names on $6f16

LoadHi		movem.l	d0-d7/a0-a6,-(sp)
		bsr.b	Params
                jsr     (resload_GetFileSize,a2)
                tst.l   d0
                beq.b 	NoHisc
		bsr	Params
		jsr	(resload_LoadFile,a2)
NoHisc		movem.l	(sp)+,d0-d7/a0-a6
		rts

Params		lea	hiscore(pc),a0
		lea	$6f16.w,a1
		move.l	(_resload,pc),a2
		rts

SaveHi		cmpi.b	#$fd,$27cd.w
		bne.b	save_return

		movem.l	d0-d7/a0-a6,-(sp)
		bsr.b	Params
		move.l	#$248,d0
		jsr	(resload_SaveFile,a2)
		movem.l	(sp)+,d0-d7/a0-a6
		rts
		
save_return	jmp	$72ae.w

_resload	dc.l	0
hiscore		dc.b	"AtomicRobokid.High",0

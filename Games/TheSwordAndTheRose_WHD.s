; V1.3, 31.08.2023, StingRay
; - original version (SPS 3434) is now supported, previous versions of
;   the patch only supported a cracked version
; - 68000 quitkey support
; - WHDLoad v17+ features used

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	whdload.i

FLAGS	= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem


ws	SLAVE_HEADER		; ws_Security + ws_ID
	DC.W	17		; ws_Version
	DC.W	FLAGS		; ws_Flags
	DC.L	$80000		; ws_BaseMemSize
	DC.L	0		; ws_ExecInstall
	DC.W	Patch-ws	; ws_GameLoader
	DC.W	0		; ws_CurrentDir
	DC.W	0		; ws_DontCache
	DC.B	0		; ws_keydebug
	DC.B	$59		; ws_keyexit
	DC.L	0		; ws_ExpMem
	DC.W	slv_name-ws	; ws_name
	DC.W	slv_copy-ws	; ws_copy
	DC.W	slv_info-ws	; ws_info

	
; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-ws	; ws_config


.config	dc.b	"C1:B:Unlimited Lives;"
	dc.b	0

slv_name	DC.B	"The Sword and the Rose",0
slv_copy	DC.B	"1991 Code Masters",0
slv_info	DC.B	"installed & fixed by Bored Seal & StingRay",10
		DC.B	"V1.3 (31-Aug-2023)",0
		CNOP	0,2

Patch
	lea	resload(pc),a1
	move.l	a0,(a1)

	move.l	a0,a2

	lea	Game_Name(pc),a0
	lea	$B000-$8c8,a1
	move.l	a1,d7
	move.l	a1,a5
	add.w	#$8c8,a5
	jsr	resload_LoadFileDecrunch(a2)
	move.l	d7,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$e289,d0		; SPS 2434
	beq.b	.Version_is_Supported

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.Version_is_Supported
	; decrypt game
	move.l	#$B2191957,d0
	moveq	#0,d1
	move.l	#$FFFFFF00,d2
	move.l	#$C17D0000,d3
	move.l	#$00F06570,d4
	moveq	#$00000040,d5

	move.l	a5,a6
	move.l	#$5000,d6
.decrypt
	rol.l	d0,d1
	add.l	d1,d2
	ror.l	d2,d3
	add.l	d3,d4
	ror.l	d4,d5
	add.l	d5,d0
	add.l	d0,(a6)+
	subq.l	#4,d6
	bne.b	.decrypt


	move.l	#$4E714EB9,d0
	move.l	d0,$1409E
	move.l	d0,$140BA
	move.l	d0,$140D6
	move.l	d0,$140F2
	pea	Wait_Blit_0401_dff058(pc)
	move.l	(sp),$140A2
	move.l	(sp),$140BE
	move.l	(sp),$140DA
	move.l	(sp)+,$140F6
	move.w	d0,$1416E
	move.w	d0,$14188
	move.w	d0,$141A2
	move.w	d0,$141BC
	move.w	d0,$141D4
	move.w	d0,$141EE
	move.w	d0,$14208
	move.w	d0,$14222
	pea	Wait_Blit_d0_dff058(pc)
	move.l	(sp),$14170
	move.l	(sp),$1418A
	move.l	(sp),$141A4
	move.l	(sp),$141BE
	move.l	(sp),$141D6
	move.l	(sp),$141F0
	move.l	(sp),$1420A
	move.l	(sp)+,$14224


	lea	PL_GAME(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

	jmp	(a5)

PL_GAME	PL_START
	PL_R	$6382			; disable advertisement pictures
	PL_PS	$e4cc,Fix_DMA_Wait


	; V1.3, StingRay
	PL_PS	$d108,.Check_Quit_Key

	PL_IFC1
	PL_B	$4a12,$4a
	PL_ENDIF
	PL_END

.Check_Quit_Key
	bsr.b	.Get_Key
	ror.b	d0
	not.b	d0
	cmp.b	ws+ws_keyexit(pc),d0
	beq.b	QUIT

.Get_Key
	move.b	$bfec01,d0
	rts




Fix_DMA_Wait
	moveq	#8-1,d0
.loop	move.w	d0,-(sp)
	move.b	$DFF006,d0
.same_raster_line
	cmp.b	$DFF006,d0
	beq.b	.same_raster_line
	move.w	(sp)+,d0
	dbf	d0,.loop
	rts

Wait_Blit_0401_dff058
	move.w	#$401,$DFF058
Wait_Blit
	btst	#6,$DFF002
	bne.b	Wait_Blit
	rts

Wait_Blit_d0_dff058
	move.w	d0,$DFF058
	bra.b	Wait_Blit

QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

resload		dc.l	0
Game_Name	dc.b	"sword",0



	END

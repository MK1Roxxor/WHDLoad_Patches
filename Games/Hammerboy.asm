; V1.2, StingRay
; - 50% brightness bug fixed
; - timing fixed
; - unlimited lives trainer added
; - patch now uses files instead of a disk image
; - decruncher relocated to fast memory

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Hardware/dmabits.i
	INCLUDE	hardware/intbits.i
	INCLUDE	hardware/custom.i
	IFND	_custom
_custom	= $dff000
	ENDC
	INCLUDE	hardware/cia.i
	IFND	_ciaa
_ciaa	= $bfe001
	ENDC
	INCLUDE	exec/types.i
	INCLUDE	exec/exec_lib.i
	INCLUDE	exec/io.i


ws	SLAVE_HEADER			; ws_Security + ws_ID
	DC.W	17			; ws_Version
	DC.W	WHDLF_NoError|WHDLF_EmulTrap	;ws_Flags
	DC.L	$80000			; ws_BaseMemSize
	DC.L	0			; ws_ExecInstall
	DC.W	slv_GameLoader-ws	; ws_GameLoader
	DC.W	slv_GameDir-ws		; ws_CurrentDir
	DC.W	0			; ws_DontCache
	DC.B	0			; ws_keydebug
	DC.B	0			; ws_keyexit
	DC.L	0			; ws_ExpMem
	DC.W	slv_name-ws		; ws_name
	DC.W	slv_copy-ws		; ws_copy
	DC.W	slv_info-ws		; ws_info
	dc.w	0			; ws_kickname
	dc.l	0			; ws_kicksize
	dc.w	0			; ws_kickcrc
	dc.w	slv_config-ws		; ws_config
	

slv_name	DC.B	"Hammer Boy",0
slv_copy	DC.B	"1990 Dinamic",0
slv_info	DC.B	"installed & fixed by Bored Seal & StingRay",10
		DC.B	"V1.3 (27-Sep-2024)",0
slv_GameDir	dc.b	"data",0

slv_config	dc.b	"C1:B:Unlimited Lives"
		dc.b	0
		CNOP	0,2

slv_GameLoader
	lea	resload(pc),a1
	move.l	a0,(a1)

	lea	File_Name(pc),a0
	lea	$290c0,a1
	bsr	Load_File


	move.w	#$6006,$3B0F8	; $12038, $bfe0ff

	move.l	#$4E714EB9,d0
	move.l	d0,($294F6)	; $436, delay
	move.l	d0,($367E0)	; $d720, delay
	move.l	d0,($3B6E6)	; $12626, $bfe0ff

	pea	Fix_DMA_Wait(pc)
	move.l	(sp)+,$294FA
	pea	Delay_118(pc)
	move.l	(sp)+,$367E4
	pea	Delay_21(pc)
	move.l	(sp)+,$3B6EA

	move.w	#$4EB9,$3B32E
	pea	Check_Level_Skip(pc)
	move.l	(sp)+,$3B330

	pea	Install_Highscore_Handling_Patch(pc)
	move.l	(sp)+,$3BD6C

	; V1.2, StingRay
	lea	PL_GAME(pc),a0
	lea	$290c0,a1
	bsr	Apply_Patches

	jmp	$29166


PL_GAME	PL_START
	PL_PS	$1245a,Fix_Brightness
	PL_ORW	$12138+2,1<<9	; set Bplcon0 color bit

	PL_P	$12e46,Load_Game_File
	PL_R	$12d56		; disable loading of file table
	PL_B	$12dd2,$60	; skip file size check
	PL_P	$12e2e,Decrunch
	PL_P	$12cf8,Patch_Stage1_Code
	PL_P	$12d14,Patch_Stage2_Code
	PL_P	$12d30,Patch_Stage3_Code
	PL_P	$12d4c,Patch_Stage4_Code
	PL_PS	$1248c,Check_Quit_Key
	PL_END

Check_Quit_Key
	move.b	$bfec01,d0
	move.b	d0,d1
	ror.b	d1
	not.b	d1
	cmp.b	ws+ws_keyexit(pc),d1
	beq.w	QUIT
	rts


Patch_Stage1_Code
	lea	PL_STAGE1_CODE(pc),a0
Patch_Stage_Code
	lea	$290c0,a1
	bsr	Apply_Patches
	jmp	$3d008

Patch_Stage2_Code
	lea	PL_STAGE2_CODE(pc),a0
	bra.b	Patch_Stage_Code

Patch_Stage3_Code
	lea	PL_STAGE3_CODE(pc),a0
	bra.b	Patch_Stage_Code

Patch_Stage4_Code
	lea	PL_STAGE4_CODE(pc),a0
	bra.b	Patch_Stage_Code

PL_STAGE1_CODE
	PL_START
	PL_PS	$14012,Fix_Timing
	PL_PSS	$140e2,Delay_200000,4
	PL_PSS	$14140,Delay_200000,4
	PL_PSS	$14168,Delay_80000,4
	PL_PSS	$14192,Delay_38000,4

	PL_IFC1
	PL_B	$1555e,$4a
	PL_ENDIF

	PL_END

PL_STAGE2_CODE
	PL_START
	PL_PS	$1401a,Fix_Timing
	PL_PSS	$140ec,Delay_200000,4
	PL_PSS	$14156,Delay_40000,4
	PL_PSS	$14182,Delay_50000,4
	PL_PSS	$141b0,Delay_40000,4
	PL_PSS	$141dc,Delay_50000,4
	PL_PSS	$14208,Delay_50000,4
	PL_PSS	$1423e,Delay_170000,4
	

	PL_IFC1
	PL_B	$1596a,$4a
	PL_ENDIF

	PL_END

PL_STAGE3_CODE
	PL_START
	PL_PS	$1405e,Fix_Timing
	PL_PSS	$1413a,Delay_200000,4

	PL_IFC1
	PL_B	$15706,$4a
	PL_ENDIF

	PL_END

PL_STAGE4_CODE
	PL_START
	PL_PS	$14016,Fix_Timing
	PL_PSS	$140ea,Delay_200000,4

	PL_IFC1
	PL_B	$15b22,$4a
	PL_ENDIF

	PL_END

Fix_Timing
	bsr	WaitRaster
	jmp	$290c0+$668

Delay_200000
	move.l	#200000/$34,d0
	bra.w	Delay	

Delay_40000
	move.l	#40000/$34,d0
	bra.w	Delay	

Delay_50000
	move.l	#50000/$34,d0
	bra.w	Delay	

Delay_170000
	move.l	#170000/$34,d0
	bra.w	Delay	

Delay_80000
	move.l	#80000/$34,d0
	bra.w	Delay	

Delay_38000
	move.l	#38000/$34,d0
	bra.w	Delay	


; d2.w: file number
; a6.l: destination

Load_Game_File
	move.w	d2,d0
	lea	File_Name(pc),a0
	bsr.b	.Build_Name
	move.l	a6,a1
	bra.w	Load_File

.Build_Name
	movem.l	d0/d1/a0,-(a7)
	moveq	#2-1,d3		; max. 2 digits
	lea	.TAB(pc),a1
.loop	moveq	#-"0",d1
.loop2	sub.w	(a1),d0
	dbcs	d1,.loop2
	neg.b	d1
	move.b	d1,(a0)+
.nope	add.w	(a1)+,d0
	dbf	d3,.loop
	movem.l	(a7)+,d0/d1/a0
	rts

.TAB	dc.w	10
	dc.w	1


Fix_Brightness
.Set_Colors
	move.w	(a0)+,d1
	add.w	d1,d1
	move.w	d1,(a1)+
	dbf	d0,.Set_Colors
	rts

Decrunch
	move.l	a0,-(sp)
	move.l	a6,a0
	move.l	a5,a1
	bsr.b	lbC013248
	move.l	a5,a0
	move.l	a6,a1
	bsr.w	lbC013348
	move.l	d0,d1
	move.l	(sp)+,a0
	rts

lbC013248
	movem.l	d1-d3/a2/a3,-(sp)
	move.l	(a0)+,d0
	and.l	#$7FFFFF,d0
	lea	(a1,d0.l),a3
	lea	(a0),a2
	lea	($12,a0),a0
	move.l	(a0)+,d1
	moveq	#$20,d3
lbC013262
	cmp.l	a3,a1
	blo.b	lbC01326C
	movem.l	(sp)+,d1-d3/a2/a3
	rts

lbC01326C
	dbra	d3,lbC013274
	move.l	(a0)+,d1
	moveq	#$1F,d3
lbC013274
	add.l	d1,d1
	bhs.b	lbC0132D4
	dbra	d3,lbC013280
	move.l	(a0)+,d1
	moveq	#$1F,d3
lbC013280
	add.l	d1,d1
	bhs.b	lbC013288
	move.b	(a2),(a1)+
	bra.b	lbC013262

lbC013288
	cmp.w	#4,d3
	blo.b	lbC01329C
	subq.w	#4,d3
	rol.l	#4,d1
	moveq	#15,d2
	and.w	d1,d2
	move.b	(1,a2,d2.w),(a1)+
	bra.b	lbC013262

lbC01329C
	moveq	#0,d2
	dbra	d3,lbC0132A6
	move.l	(a0)+,d1
	moveq	#$1F,d3
lbC0132A6
	add.l	d1,d1
	addx.w	d2,d2
	dbra	d3,lbC0132B2
	move.l	(a0)+,d1
	moveq	#$1F,d3
lbC0132B2
	add.l	d1,d1
	addx.w	d2,d2
	dbra	d3,lbC0132BE
	move.l	(a0)+,d1
	moveq	#$1F,d3
lbC0132BE
	add.l	d1,d1
	addx.w	d2,d2
	dbra	d3,lbC0132CA
	move.l	(a0)+,d1
	moveq	#$1F,d3
lbC0132CA
	add.l	d1,d1
	addx.w	d2,d2
	move.b	(1,a2,d2.w),(a1)+
	bra.b	lbC013262

lbC0132D4
	cmp.w	#8,d3
	blo.b	lbC0132E2
	subq.w	#8,d3
	rol.l	#8,d1
	move.b	d1,(a1)+
	bra.b	lbC013262

lbC0132E2
	dbra	d3,lbC0132EA
	move.l	(a0)+,d1
	moveq	#$1F,d3
lbC0132EA
	add.l	d1,d1
	addx.w	d2,d2
	dbra	d3,lbC0132F6
	move.l	(a0)+,d1
	moveq	#$1F,d3
lbC0132F6
	add.l	d1,d1
	addx.w	d2,d2
	dbra	d3,lbC013302
	move.l	(a0)+,d1
	moveq	#$1F,d3
lbC013302
	add.l	d1,d1
	addx.w	d2,d2
	dbra	d3,lbC01330E
	move.l	(a0)+,d1
	moveq	#$1F,d3
lbC01330E
	add.l	d1,d1
	addx.w	d2,d2
	dbra	d3,lbC01331A
	move.l	(a0)+,d1
	moveq	#$1F,d3
lbC01331A
	add.l	d1,d1
	addx.w	d2,d2
	dbra	d3,lbC013326
	move.l	(a0)+,d1
	moveq	#$1F,d3
lbC013326
	add.l	d1,d1
	addx.w	d2,d2
	dbra	d3,lbC013332
	move.l	(a0)+,d1
	moveq	#$1F,d3
lbC013332
	add.l	d1,d1
	addx.w	d2,d2
	dbra	d3,lbC01333E
	move.l	(a0)+,d1
	moveq	#$1F,d3
lbC01333E
	add.l	d1,d1
	addx.w	d2,d2
	move.b	d2,(a1)+
	bra.w	lbC013262

lbC013348
	move.l	a1,a2
	move.b	(a0)+,d1
	subq.l	#1,d0
lbC01334E
	move.b	(a0)+,d2
	cmp.b	d2,d1
	beq.b	lbC013360
	move.b	d2,(a1)+
	subq.l	#1,d0
	bne.b	lbC01334E
lbC01335A
	sub.l	a2,a1
	move.l	a1,d0
	rts

lbC013360
	clr.w	d2
	move.b	(a0)+,d2
	beq.w	lbC01337A
	move.b	(a0)+,d3
	addq.w	#2,d2
lbC01336C
	move.b	d3,(a1)+
	dbra	d2,lbC01336C
	subq.l	#3,d0
	blo.b	lbC01335A
	bne.b	lbC01334E
	bra.b	lbC01335A

lbC01337A
	move.b	d1,(a1)+
	subq.l	#2,d0
	blo.b	lbC01335A
	bne.b	lbC01334E
	bra.b	lbC01335A




Install_Highscore_Handling_Patch
	move.w	#$4EF9,($3D83C)
	pea	(Save_Highscores,pc)
	move.l	(sp)+,($3D83E)
	bsr.b	Load_Highscores
	jmp	$3D000

Load_Highscores
	movem.l	d0-a6,-(a7)
	bsr.b	Initialise_Highscore_Handling
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.No_highscores_found
	bsr.b	Initialise_Highscore_Handling
	jsr	resload_LoadFile(a2)
.No_highscores_found
	movem.l	(a7)+,d0-a6
	rts

Initialise_Highscore_Handling
	lea	Highscore_Name(pc),a0
	lea	$3D512,a1
	move.l	resload(pc),a2
	rts

Save_Highscores
	jsr	$3B3C8
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.b	Initialise_Highscore_Handling
	move.l	#244,d0
	jsr	resload_SaveFile(a2)
	movem.l	(sp)+,d0-d7/a0-a6
	rts

Check_Level_Skip
	btst	#6,$BFE001
	bne.b	.noLMB
	clr.w	$36804
.noLMB
	move.w	$DFF00C,d0
	rts

Delay_21
	move.l	d0,d1
	moveq	#20,d0
	bsr.b	Delay
	move.l	d1,d0
	rts

Delay_118
	move.w	#117,d0
	bra.b	Delay

Fix_DMA_Wait
	moveq	#14,d0
Delay
	move.w	d0,-(sp)
	move.b	$DFF006,d0
.same_raster_line
	cmp.b	$DFF006,d0
	beq.b	.same_raster_line
	move.w	(sp)+,d0
	dbf	d0,Delay
	rts

Disk_Load
	movem.l	d0-d2/a0-a2,-(sp)
	move.l	a6,a0
	mulu	#512,d0
	moveq	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(sp)+,d0-d2/a0-a2
	rts

resload	dc.l	0
Highscore_Name
	dc.b	"Hammerboy.High",0

File_Name
	dc.b	"HA",0
	CNOP	0,2


; ---------------------------------------------------------------------------
; Support/helper routines.


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)


KillSys	move.w	#$7fff,$dff09a
	bsr.b	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	rts


WaitRaster
.wait1	btst	#0,_custom+vposr+1
	beq.b	.wait1
.wait2	btst	#0,_custom+vposr+1
	bne.b	.wait2
	rts


; ---------------------------------------------------------------------------

; a0.l: file name
; a1.l: destination
; -----
; d0.l: file size

Load_File
	movem.l	d1-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_LoadFileDecrunch(a2)
	movem.l	(a7)+,d1-a6
	rts

; ---------------------------------------------------------------------------

; a0.l: patch list
; a1.l: destination

Apply_Patches
	movem.l	d0-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts

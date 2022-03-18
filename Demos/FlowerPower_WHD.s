***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    FLOWER POWER/ANARCHY WHDLOAD SLAVE      )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              March 2022                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 18-Mar-2022	- instruction cache disabled as many parts use lots of
;		  self-modifying code
;		- 68000 quitkey support
;		- that's enought for this patch for now!

; 17-Mar-2022	- all other parts patched

; 16-Mar-2022	- enhanced loader patch, uncrunched parts are now patched
;		  directly after loading
;		- vector parts (after title picture) patched

; 15-Mar-2022	- RawDIC imager coded, patch is now file based
;		- first parts patched

; 14-Mar-2022	- work started
;		- demo patched to load from HD, not fixes yet


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	dos/doshunks.i
	INCLUDE	exec/execbase.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
DEBUG

FAST_MEMORY_SIZE	= 524288

	
; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM


HEADER	SLAVE_HEADER			; ws_security + ws_ID
	dc.w	17			; ws_version
	dc.w	FLAGS			; flags
	dc.l	$80000			; ws_BaseMemSize
	dc.l	0			; ws_ExecInstall
	dc.w	Patch-HEADER		; ws_GameLoader
	dc.w	.dir-HEADER		; ws_CurrentDir
	dc.w	0			; ws_DontCache
	dc.b	0			; ws_KeyDebug
	dc.b	QUITKEY			; ws_KeyExit
	dc.l	FAST_MEMORY_SIZE	; ws_ExpMem
	dc.w	.name-HEADER		; ws_name
	dc.w	.copy-HEADER		; ws_copy
	dc.w	.info-HEADER		; ws_info

; v16
	dc.w	0			; ws_kickname
	dc.l	0			; ws_kicksize
	dc.w	0			; ws_kickcrc

; v17
	dc.w	.config-HEADER		; ws_config


.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Anarchy/FlowerPower/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Flower Power",0
.copy	dc.b	"1992 Anarchy",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.1 (18.03.2022)",0

File_Name	dc.b	"FlowerPower_"
File_Number	dc.b	"00",0
	CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; load boot code
	lea	$70000,a0
	bsr	Load_Next_File

	move.l	a0,a5

	; version check
	move.l	a5,a0
	move.l	#512*11,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$49EE,d0
	beq.b	.version_ok
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.version_ok

	; decrunch boot code
	lea	$3e(a5),a0
	move.l	HEADER+ws_ExpMem(pc),a1
	move.l	a1,a5
	bsr	Decrunch_Defjam32

	; patch boot code
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)


	; set extended memory locations
	move.l	HEADER+ws_ExpMem(pc),a0
	move.l	a0,$7ff10
	add.l	#FAST_MEMORY_SIZE,a0
	move.l	a0,$7ff14


	; relocate stack to end of extended memory
	move.l	a0,a7
	sub.w	#2048,a0
	move.l	a0,USP


	; enable DMA channels
	move.w	#$83c0,$dff096

	; install level 2 interrupt
	bsr	Init_Level2_Interrupt

	; disable instruction cache as demo uses a lot of
	; self-modifying code
	bsr	Disable_Instruction_Cache

	; run the demo
	moveq	#0,d0				; extended memory available
	jmp	(a5)


; ---------------------------------------------------------------------------

PLBOOT	PL_START
	PL_P	$c06,.Acknowledge_Level3_Interrupt
	PL_P	$c90,.Load
	PL_ORW	$73e+4,1<<9			; set Bplcon0 color bit
	PL_PS	$81e,.Delay
	PL_ORW	$70a+2,1<<3			; enable level 2 interrupts
	PL_W	$786+2,$2000			; sr value
	PL_P	$c6e,Flush_Cache_After_Relocation

	PL_PS	$810,.Patch_Part1
	;PL_PS	$91a,.Patch_Part4



;	PL_W	$918,$4e71			; disable long vector world
;	PL_L	$920,$4e714e71			; disable sprite balls
;	PL_W	$95e,$4e71			; disable title picture + zoom
;	PL_W	$a00,$4e71			; disable vector parts
;	PL_L	$a0a,$4e714e71			; disable RGB vectors + dragonball

	PL_PSS	$aac,.Run_The_End,4
	PL_PS	$af8,.Patch_Final_Part

	; don't patch interrupt and exception vectors
	PL_SA	$77a,$782

	PL_PSS	$a00,.Enable_Keyboard,2
	PL_END

; Enable keyboard in the vector parts to enable
; quit on 68000.

.Enable_Keyboard
.run_vector_parts
	move.w	#$2000,sr
	bsr	Init_Level2_Interrupt
	jsr	(a0)
	addq.w	#1,d0
	dbf	d1,.run_vector_parts
	rts	


.Patch_Final_Part
	movem.l	d0-a6,-(a7)
	lea	PL_FINAL(pc),a0
	lea	$2f000,a1
	bsr	Apply_Patches
	movem.l	(a7)+,d0-a6
	jmp	$2f000


; Code was copied from fast memory to $70000, flush cache and run part
.Run_The_End
	movem.l	d0-a6,-(a7)
	bsr	Flush_Cache
	jsr	(a2)
	movem.l	(a7)+,d0-a6
	rts



.Delay	movem.l	d0-a6,-(a7)
	moveq	#6*10,d0
	move.l	resload(pc),a2
	jsr	resload_Delay(a2)
	movem.l	(a7)+,d0-a6
	move.l	$7FF10,d0
	rts



; a0.l: destination
; d0.w: track
; d1.w: length (tracks)
; d2.w: command offset (2*4: load data)

.Load	subq.w	#2*4,d2
	bne.b	.not_load_command

	movem.l	d0-a6,-(a7)
	bsr	Load_Next_File

	; patch parts that are not crunched
	lea	.Patch_Table(pc),a2
	move.l	a0,a1
.find_parts_to_patch
	movem.w	(a2)+,d2/d3
	cmp.w	d0,d2
	bne.b	.check_next_entry
	lea	.Patch_Table(pc,d3.w),a0
	cmp.l	#HUNK_HEADER,(a1)
	bne.b	.no_executable

	add.w	#$20,a1				; skip hunk header

.is_defjam_packed
.no_executable
	bsr	Apply_Patches

.check_next_entry
	tst.w	(a2)
	bpl.b	.find_parts_to_patch
	movem.l	(a7)+,d0-a6

.not_load_command
	rts

.Patch_Table
	dc.w	95,PL_VECTOR-.Patch_Table	; 102 light faces and more
	dc.w	117,PL_GREETINGS_INIT-.Patch_Table
	dc.w	105,PL_RGB_VECTORS_DRAGONBALL-.Patch_Table
	dc.w	119,PL_10-.Patch_Table
	dc.w	145,PL_THE_END-.Patch_Table	; "The End" vector logo
	dc.w	147,PL_VECTOR_WORLD-.Patch_Table
	dc.w	50,PL_PART3-.Patch_Table
	dc.w	15,PL_REPLAY_MAIN-.Patch_Table
	dc.w	-1				; end of table



.Acknowledge_Level3_Interrupt
	move.w	d0,(a0)
	movem.l	(a7)+,d0/a0
	rte

.Patch_Part1
	movem.l	d0-a6,-(a7)
	bsr	Get_Defjam32_Destination
	bsr	Decrunch_Defjam32
	lea	PLPART1(pc),a0
	bsr	Apply_Patches
	movem.l	(a7)+,d0-a6
	bsr	Get_Defjam32_Jump
	sub.w	#8*4,a0
	rts


.Patch_Part4
	sf	$7ff05
	movem.l	d0-a6,-(a7)
	bsr	Get_Defjam32_Destination
	bsr	Decrunch_Defjam32
	lea	PLPART4(pc),a0
	bsr	Apply_Patches
	movem.l	(a7)+,d0-a6
	bsr	Get_Defjam32_Jump
	sub.w	#8*4,a0
	rts

Flush_Cache_After_Relocation
	bsr.b	Flush_Cache
	movem.l	(a7)+,d0-d2/a0/a1
	rts

Flush_Cache
	move.l	resload(pc),a1
	jmp	resload_FlushCache(a1)


; ---------------------------------------------------------------------------

PL_REPLAY_MAIN
	PL_START
	PL_PSS	$9e,Acknowledge_Level6_Interrupt,2
	PL_PS	$516,Acknowledge_Level6_Interrupt
	PL_END
	

; ---------------------------------------------------------------------------

PLPART1	PL_START
	PL_ORW	$7e+2,1<<3			; enable level 2 interrupts
	PL_PSS	$1fc,Acknowledge_Level3_Interrupt,2
	PL_PSS	$15c,Acknowledge_Level3_Interrupt,2
	PL_PSS	$382,Acknowledge_Level3_Interrupt,2
	PL_PSS	$326,Acknowledge_Level3_Interrupt,2
	PL_PSS	$184,Acknowledge_Level3_Interrupt,2
	PL_PSS	$1c4,Acknowledge_Level3_Interrupt,2
	PL_PSS	$a0,Acknowledge_Level3_Interrupt,2
	PL_PS	$48c,.fix_line_draw
	PL_END

.fix_line_draw
	move.l	a0,-(a7)
	lea	$40000+$4d0,a0
	move.b	(a0,d4.w),d4
	move.w	d4,$42(a5)
	move.l	(a7)+,a0
	rts


Acknowledge_Level3_Interrupt
	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rts

Acknowledge_Level6_Interrupt
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rts

; ---------------------------------------------------------------------------
; Vector world

PL_VECTOR_WORLD
	PL_START
	PL_PSS	$25c,Acknowledge_Blitter_Interrupt,2
	PL_PSS	$356,Acknowledge_Level3_Interrupt,2
	PL_ORW	$f0+2,1<<3			; enable level 2 interrupts
	PL_W	$8c5c,$1fe
	PL_PSS	$27aa,.fix_line_draw,2
	PL_PS	$14,.Fix_Copperlist
	PL_END


.Fix_Copperlist
	lea	$dff000,a5
	lea	$50000+$8614,a0
	lea	$50000+$8c54,a1

; a0.l: start of area to nop
; a1.l: end of area

.Set_Copper_Nop
.loop	move.w	#$01fe,(a0)
	addq.w	#4,a0
	cmp.l	a0,a1
	bhi.b	.loop
	rts


.fix_line_draw
	moveq	#0,d0
	move.b	(a6)+,d0
	addq.w	#1,a6
	move.w	d0,$42(a5)
	rts


Acknowledge_Blitter_Interrupt
	move.w	#1<<6,$dff09c
	move.w	#1<<6,$dff09c
	rts	

; ---------------------------------------------------------------------------
; balls + zooming planet

PL_PART3
	PL_START
	PL_PSS	$1068,Acknowledge_Level3_Interrupt,2
	PL_PSS	$10aa,Acknowledge_Level3_Interrupt,2
	PL_ORW	$fc4+2,1<<3			; enable level 2 interrupts
	PL_END

; ---------------------------------------------------------------------------

PLPART4	PL_START
	PL_R	0
	PL_END

; ---------------------------------------------------------------------------
; This part contains 5 embedded executables (4 vector parts, 1 dot scroller)
; Parts are: 102 lightfaces, 230 vectorlines, 62 glenzfaces, dot scroller,
; cubes

PL_VECTOR
	PL_START
	PL_P	$7a,Flush_Cache_After_Relocation
	PL_PS	$b06,.fix_line_draw
	PL_ORW	$2e6a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$5900+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$5920+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$59e0+2,1<<9		; set Bplcon0 color bit
	PL_PS	$338c,.Fix_Line_Draw_BltCon1
	PL_ORW	$867c+2,1<<9		; set Bplcon0 color bit
	PL_L	$86c8,-2		; terminate copperlist
	PL_PS	$933e,.WaitBlit

	PL_PS	$6284,.Fix_Line_Draw_BltCon1_3
	PL_PS	$6344,.Fix_Line_Draw_BltCon1_3
	PL_PS	$63cc,.Fix_Line_Draw_BltCon1_3
	PL_PS	$6452,.Fix_Line_Draw_BltCon1_3
	PL_PS	$64d0,.Fix_Line_Draw_BltCon1_3

	; correct Bltcon0 table
.OFFSET	SET 0
	REPT	16
	PL_ORW	$6508+.OFFSET,1<<8
.OFFSET	SET .OFFSET+2
	ENDR

	

	; scroller
	PL_PS	$9734,.Fix_Line_Draw_BltCon1_Scroller

	; cubes
	PL_PS	$bf54,Fix_Line_Draw_BltCon1_A2_D4
	PL_PS	$bf84,Fix_Line_Draw_BltCon1_A2_D4
	PL_PS	$c0fc,Fix_Line_Draw_BltCon1_A2_D4
	PL_PS	$c12c,Fix_Line_Draw_BltCon1_A2_D4
	PL_PS	$aab0,.WaitBlit2
	PL_PS	$aae6,.WaitBlit2
	PL_PS	$ab1c,.WaitBlit2
	PL_PS	$ab52,.WaitBlit2
	PL_PS	$ab88,.WaitBlit2
	PL_PS	$abbe,.WaitBlit2
	PL_PS	$abf4,.WaitBlit2
	PL_PS	$ac2a,.WaitBlit2
	PL_ORW	$d0a0+2,1<<9		; set Bplcon0 color bit

	PL_W	$220+2,$1fff&~(1<<3)	; enable level 2 interrupts
	PL_W	$3020+2,$1fff&~(1<<3)	; enable level 2 interrupts
	PL_W	$5e20+2,$1fff&~(1<<3)	; enable level 2 interrupts
	PL_W	$9020+2,$1fff&~(1<<3)	; enable level 2 interrupts
	PL_W	$a820+2,$1fff&~(1<<3)	; enable level 2 interrupts
	
	PL_END

.WaitBlit
	move.w	#1<<5,$96(a5)
	bra.w	WaitBlit

.WaitBlit2
	bsr	WaitBlit
	move.w	d1,(a6)
	move.w	d0,(a4)
	move.w	a2,(a5)
	rts

.Fix_Line_Draw_BltCon1
	move.l	a0,-(a7)
	move.l	HEADER+ws_ExpMem(pc),a0
	add.l	#$8000+$33d6,a0
	move.b	(a0,d4.w),d0
	move.w	d0,$42(a5)
	move.l	(a7)+,a0
	rts

.Fix_Line_Draw_BltCon1_3
	move.w	d4,-(a7)
	move.b	(a3,d4.w),d4
	move.w	d4,$42(a5)
	move.w	(a7)+,d4
	rts

.Fix_Line_Draw_BltCon1_Scroller
	movem.l	d4/a0,-(a7)
	move.l	HEADER+ws_ExpMem(pc),a0
	add.l	#$8000+$9778,a0
	move.b	(a0,d4.w),d4
	move.w	d4,$42(a5)
	movem.l	(a7)+,d4/a0
	rts
	

.fix_line_draw
	move.w	8(a3,d0.w),d0			; Bltcon0 value
	or.w	#1<<8,d0
	swap	d0
	rts

Fix_Line_Draw_BltCon1_A2_D4
	move.w	d4,-(a7)
	move.b	(a2,d4.w),d4
	move.w	d4,$42(a5)
	move.w	(a7)+,d4
	rts

; ---------------------------------------------------------------------------
; RGB Vectors and dragonball intro/main/extro

PL_RGB_VECTORS_DRAGONBALL
	PL_START
	PL_PSS	$6c5e,Acknowledge_Level3_Interrupt,2
	PL_PSS	$6c6e,Acknowledge_Level3_Interrupt,2
	PL_PS	$d4ba,.Flush_Cache
	PL_PS	$6bd4,.Patch_Dragonball_Intro	
	PL_PS	$da2c,.Fix_Line_Draw_BltCon1
	PL_PS	$db32,.Fix_Line_Draw_BltCon1

	; dragonball extro
	PL_PS	$fbe6,.Fix_Line_Draw_BltCon1

	; fix Bltcon0 table2
.OFFSET	SET $da54
	REPT	16
	PL_ORW	.OFFSET,1<<8
.OFFSET	SET .OFFSET+2	
	ENDR	

.OFFSET	SET $db5a
	REPT	16
	PL_ORW	.OFFSET,1<<8
.OFFSET	SET .OFFSET+2	
	ENDR	

	; dragonball extro
.OFFSET	SET $fc0e
	REPT	16
	PL_ORW	.OFFSET,1<<8
.OFFSET	SET .OFFSET+2	
	ENDR	

	PL_ORW	$6a6a+2,1<<3			; enable level 2 interrupts
	PL_W	$6aa4+2,$2000			; sr value
	PL_END


.Fix_Line_Draw_BltCon1
	movem.l	d4/a0,-(a7)
	move.l	HEADER+ws_ExpMem(pc),a0
	add.l	#$15c00+$da74+$20,a0
	move.b	(a0,d4.w),d4
	move.w	d4,$42(a5)
	movem.l	(a7)+,d4/a0
	rts


; Flush cache after copying code to $30000
.Flush_Cache
	bsr	Flush_Cache
	move.w	#$2000,sr
	bsr	Init_Level2_Interrupt
	jmp	$30000

.Patch_Dragonball_Intro
	move.w	#0,$180(a5)			; original code
	lea	PL_DRAGONBALL_INTRO(pc),a0
	lea	$40000,a1
	bra.w	Apply_Patches


PL_DRAGONBALL_INTRO
	PL_START
	PL_PS	$f7a,.Fix_Line_Draw_BltCon1
	PL_PS	$87c,.WaitBlit1

	; fix Bltcon0 table
.OFFSET	SET $fa4
	REPT	16
	PL_ORW	.OFFSET,1<<8
.OFFSET	SET .OFFSET+2	
	ENDR	

	PL_END

.Fix_Line_Draw_BltCon1
	move.l	a0,-(a7)
	lea	$40000+$fc4,a0
	move.b	(a0,d4.w),d4
	move.w	d4,$42(a5)
	move.l	(a7)+,a0
	rts

.WaitBlit1
	bsr	WaitBlit
	cmp.l	#$9f00000,d6
	rts

; ---------------------------------------------------------------------------

PL_GREETINGS_INIT
	PL_START
	PL_P	$188,.Patch_Greetings_Part
	PL_END

.Patch_Greetings_Part
	movem.l	d0-a6,-(a7)
	lea	PL_GREETINGS(pc),a0
	lea	$40000,a1
	bsr	Apply_Patches
	movem.l	(a7)+,d0-a6
	jmp	$40000


PL_GREETINGS
	PL_START
	PL_PS	$11f6,Fix_Line_Draw_BltCon1_A2_D4
	PL_PS	$127e,Fix_Line_Draw_BltCon1_A2_D4
	PL_PS	$1306,Fix_Line_Draw_BltCon1_A2_D4
	PL_W	$16+2,$2000			; sr value	
	PL_END


; ---------------------------------------------------------------------------

PL_10	PL_START

	PL_PSS	$18ea,Acknowledge_Level3_Interrupt,2

.OFFSET	SET $2d2c
	REPT	16
	PL_ORW	.OFFSET,1<<8
.OFFSET SET .OFFSET+2
	ENDR

	PL_END


; ---------------------------------------------------------------------------
; Z-rotating and zooming "The End" vector logo

PL_THE_END
	PL_START
	PL_PS	$10a6,.Fix_Line_Draw_BltCon1
	PL_P	$f5a,.Adapt_Snoop


	; fix Bltcon0 table
.OFFSET	SET $10ca
	REPT	16
	PL_ORW	.OFFSET,1<<8
.OFFSET SET .OFFSET+2
	ENDR

	PL_W	$a52+2,$2000			; sr value
	PL_END

.Adapt_Snoop
	move.l	(a7)+,d0
	move.l	d0,$54(a5)
	jmp	$70000+$f60

.Fix_Line_Draw_BltCon1
	movem.l	d4/a0,-(a7)
	lea	$70000+$10ea,a0
	move.b	(a0,d4.w),d4
	move.w	d4,$42(a5)
	movem.l	(a7)+,d4/a0
	rts

; ---------------------------------------------------------------------------
; Final part.

PL_FINAL
	PL_START
	PL_ORW	$39c28+2,1<<3			; enable level 2 interrupts
	PL_W	$39c2e+2,$2000			; sr value
	PL_END

; ---------------------------------------------------------------------------
; Support/helper routines.


QUIT	pea	(TDREASON_OK).w
EXIT	bsr.b	KillSys
	move.l	resload(pc),a2
	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

KillSys	move.w	#$7fff,$dff09a
	bsr.b	WaitRaster
	move.w	#$7fff,$dff09c
	move.w	#$7ff,$dff096
	rts


WaitRaster
.wait1	btst	#0,$dff005
	beq.b	.wait1
.wait2	btst	#0,$dff005
	bne.b	.wait2
	rts


WaitBlit
	tst.b	$dff002
.wait_blit
	btst	#6,$dff002
	bne.b	.wait_blit
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

; a0.l: file name
; ----
; d0.l : result (0 = file does not exist)
File_Exists
	movem.l	d1-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	movem.l	(a7)+,d1-a6
	rts	


; ---------------------------------------------------------------------------

Check_Quit_Key
	move.l	d0,-(a7)
	move.w	#1<<15|1<<3,$dff09a		; enable level 2 interrupts
	move.b	$bfec01,d0
	ror.b	d0
	not.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	move.w	#1<<3,$dff09a			; disable level 2 interrupts
	move.l	(a7)+,d0
	rts


; ---------------------------------------------------------------------------

Disable_Instruction_Cache
	movem.l	d0-a6,-(a7)
	move.l	#WCPUF_Exp_NCS,d0
	move.l	#WCPUF_Exp,d1
	jsr	resload_SetCPU(a2)
	movem.l	(a7)+,d0-a6
	rts


; ---------------------------------------------------------------------------

; a0.l: destination

Load_Next_File
	movem.l	d0-a6,-(a7)
	move.l	a0,a1
	lea	File_Name(pc),a0
	bsr	Load_File
	bsr.b	.Update_File_Name
	movem.l	(a7)+,d0-a6
	rts

.Update_File_Name
	lea	File_Number(pc),a0
	cmp.b	#"9",1(a0)
	bne.b	.ok
	move.b	#"0"-1,1(a0)
	addq.b	#1,(a0)
.ok	addq.b	#1,1(a0)
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

; ---------------------------------------------------------------------------
; Level 2 interrupt used to handle keyboard events.

Init_Level2_Interrupt
	pea	.int(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode

	move.w	#1<<3,$dff09c			; clear ports interrupt
	move.w	#1<<15|1<<14|1<<3,$dff09a	; and enable it
	rts

.int	movem.l	d0-d1/a0-a2,-(a7)
	lea	$dff000,a0
	lea	$bfe001,a1

	btst	#3,$1e+1(a0)			; PORTS irq?
	beq.b	.end

	btst	#3,$d00(a1)			; KBD irq?
	beq.b	.end

	lea	Key(pc),a2
	moveq	#0,d0
	move.b	$bfec01-$bfe001(a1),d0
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)+
	or.b	#1<<6,$e00(a1)			; set output mode

	bsr.w	Check_Quit_Key

	move.l	(a2)+,d1
	beq.b	.nocustom
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.nocustom
	

.nokeys	moveq	#3-1,d1
.loop	move.b	$6(a0),d0
.wait	cmp.b	$6(a0),d0
	beq.b	.wait
	dbf	d1,.loop


	and.b	#~(1<<6),$e00(a1)		; set input mode
.end	move.w	#1<<3,$9c(a0)
	move.w	#1<<3,$9c(a0)			; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte



Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0				; ptr to custom routine

; ---------------------------------------------------------------------------

; Defjam Packer 3.2 decruncher

; a0.l: crunched executable
; ----
; a1.l: destination

Get_Defjam32_Destination
	move.l	$17e+2(a0),a1
	rts

; a0.l: crunched executable
; ----
; a0.l: jump address

Get_Defjam32_Jump
	move.l	$1a8+2(a0),a0
	rts


; a0.l: crunched executable
; a1.l: destination

Decrunch_Defjam32
	movem.l	d0-a6,-(a7)

	lea	Defjam_Variables(pc),a5

	move.l	a0,a3

		move.l	$186(a3),d0
		sub.l	$180(a3),d0
	move.l	d0,Defjam_Decrunched_Length-Defjam_Variables(a5)


	move.l	$1aa(a3),Defjam_Jump_Address-Defjam_Variables(a5)
	move.l	$180(a3),Defjam_Decrunch_Address-Defjam_Variables(a5)
	move.l	a1,Defjam_Destination_Address-Defjam_Variables(a5)

		lea	$2b0(a3),a0
		add.l	$34(a3),a0	;decr data end

		add.l	$4c(a3),a1
		sub.l	$180(a3),a1

		lea	$1b0(a3),a4
		move.b	$17d(a3),d7		

		lea	-10(a7),a7
		move.l	a7,a6
		clr.l	(a6)
		clr.l	4(a6)
		clr.w	8(a6)
		move.b	$ff(a3),1(a6)
		move.b	$12d(a3),3(a6)
		move.b	$14d(a3),5(a6)
		move.b	$15b(a3),7(a6)
		move.b	$161(a3),9(a6)
		bsr	D_DefJam
		lea	10(a7),a7

		moveq	#1,d0
	movem.l	(a7)+,d0-a6
	rts

* a0: source end
* a1: target begin
* d5-d7/a4/a6: parameters

D_DefJam	moveq	#-1,d6
		move.l	-(a0),a2
		add.l	a1,a2
		move.l	-(a0),d0
.Decr1		moveq	#3,d1
		bsr	.Decr20
		tst.w	d2
		beq.b	.Decr15
		cmp.b	#7,d2
		bne.b	.Decr6
		bsr	.Decr17
		bcs.b	.Decr3
		moveq	#2,d1
		bsr	.Decr20
		addq.w	#7,d2
		bra.b	.Decr6

.Decr3		moveq	#8,d1
		bsr	.Decr20
		tst.w	d2
		beq.b	.Decr4
		add.w	#10,d2
		bra.b	.Decr6

.Decr4		moveq	#12,d1
		bsr	.Decr20
		tst.w	d2
		beq.b	.Decr5
		add.w	#$109,d2
		bra.b	.Decr6

.Decr5		moveq	#15,d1
		bsr.b	.Decr20
		add.l	#$110B,d2
.Decr6		subq.w	#1,d2
		move.w	d2,d3
.Decr7		bsr.b	.Decr17
		bcs.b	.Decr9
		moveq	#8,d5
		moveq	#6,d1
		bra.b	.Decr14

.Decr9		bsr.b	.Decr17
		bcs.b	.Decr11
		moveq	#0,d5
		moveq	#3,d1
		bra.b	.Decr14

.Decr11		bsr.b	.Decr17
		bcs.b	.Decr13
		moveq	#$48,d5
		moveq	#6,d1
		bra.b	.Decr14

.Decr13		move.w	#$88,d5
		moveq	#7,d1
.Decr14		bsr.b	.Decr20
		add.w	d5,d2
		move.b	(a4,d2.w),-(a2)
		cmp.l	a1,a2
		dbeq	d3,.Decr7
		cmp.w	d6,d3
		bne.b	.Decr29

.Decr15		bsr.b	.Decr17
		bcc.b	.Decr24
		moveq	#2,d1
		bsr.b	.Decr20
		move.w	(a6),d1			;<--
		moveq	#3,d3
		tst.b	d2
		beq.b	.Decr27
		cmp.b	d2,d3
		beq.b	.Decr23
		cmp.b	#1,d2
		beq.b	.Decr18
		moveq	#6,d3
		moveq	#3,d1
		bra.b	.Decr19

.Decr17		lsr.l	#1,d0
		bne.b	.Decr16
		move.l	-(a0),d0
		move.w	#$10,ccr
		roxr.l	#1,d0
.Decr16		rts

.Decr18		moveq	#4,d3
		moveq	#1,d1
.Decr19		bsr.b	.Decr20
		add.w	d2,d3
		move.w	2(a6),d1			;<--
		bra.b	.Decr27

.Decr20		subq.w	#1,d1
		moveq	#0,d2
.Decr21		bsr.b	.Decr17
		addx.l	d2,d2
		dbf	d1,.Decr21
		rts

.Decr23		moveq	#8,d1
		bsr.b	.Decr20
		move.w	d2,d3
		add.w	#14,d3
		move.w	4(a6),d1			;<--
		bra.b	.Decr27

.Decr24		bsr.b	.Decr17
		bcs.b	.Decr26
		moveq	#2,d3
		move.w	6(a6),d1			;<--
		bra.b	.Decr27

.Decr26		moveq	#1,d3
		move.w	8(a6),d1			;<--
.Decr27		bsr.b	.Decr20
.Decr28		move.b	-1(a2,d2.w),-(a2)
		cmp.l	a1,a2
		dbeq	d3,.Decr28
		cmp.w	d6,d3
		beq.w	.Decr1

.Decr29		move.l	Defjam_Destination_Address(pc),a0
		move.l	a0,a2
		add.l	Defjam_Decrunched_Length(pc),a2
.Decr30		move.b	(a1)+,d0
		cmp.b	d7,d0		;<--
		bne.s	.Decr32
		moveq	#0,d1
		move.b	(a1)+,d1
		beq.b	.Decr32
		move.b	(a1)+,d0
		addq.w	#1,d1
.Decr31		move.b	d0,(a0)+
		cmp.l	a2,a0
		dbeq	d1,.Decr31
		cmp.w	d6,d1
		bne.b	.Exit
.Decr32		move.b	d0,(a0)+
		cmp.l	a2,a0
		bne.b	.Decr30
.Exit		rts



Defjam_Variables
Defjam_Destination_Address	dc.l	0
Defjam_Decrunch_Address		dc.l	0
Defjam_Jump_Address		dc.l	0
Defjam_Decrunched_Length	dc.l	0

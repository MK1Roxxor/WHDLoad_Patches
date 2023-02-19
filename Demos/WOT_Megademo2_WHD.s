***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*( MEGADEMO 2/WINGS OF TOMORROW WHDLOAD SLAVE )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            February 2023                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 19-Feb-2023	- text writer emulated (_LVOText)
;		- sprite bugs fixed

; 05-Feb-2023	- work started
;		- all parts execpt part 7 (which is defective) patched


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Hardware/dmabits.i
	INCLUDE	hardware/intbits.i
	INCLUDE	exec/exec_lib.i
	INCLUDE	exec/io.i
	INCLUDE	graphics/gfxbase.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG



	
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
	IFD	DEBUG
	dc.w	.dir-HEADER		; ws_CurrentDir
	ELSE
	dc.w	0
	ENDC
	dc.w	0			; ws_DontCache
	dc.b	0			; ws_KeyDebug
	dc.b	QUITKEY			; ws_KeyExit
	dc.l	0			; ws_ExpMem
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
	dc.b	"SOURCES:WHD_Slaves/Demos/WingsOfTomorrow/Megademo2",0
	ENDC

.name	dc.b	"Megademo 2",0
.copy	dc.b	"1989 Wings of Tomorrow",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.00 (19.02.2023)",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load boot code
	moveq	#0,d0
	move.l	#$2c00,d1
	lea	$10000,a0
	bsr	Disk_Load

	move.l	a0,a5

	; Version check
	move.l	a5,a0
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$644c,d0
	beq.b	.Version_is_Supported

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.Version_is_Supported

	; Create Exec emulation code
	lea	(EXEC_LOCATION).w,a0
	move.l	a0,$4.w
	bsr	Create_Exec_Emulation

	; Patch boot code
	lea	PL_BOOT(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; Switch to user mode. Some parts modify the
	; status register (sr) and would need to be patched manually
	; if this is not done.
	move.w	#0,sr


	lea	Font(pc),a0
	move.w	#Font_Size/4-1,d7
.decrypt
	eor.l	#"STR!",(a0)+
	dbf	d7,.decrypt


	; And run demo
	lea	(IOSTD_LOCATION).w,a1
	jmp	$4c(a5)
	



; ---------------------------------------------------------------------------
; Exec emulation code

EXEC_LOCATION	= $3000
OPCODE_JMP	= $4ef9


; a0.l: exec location
Create_Exec_Emulation
	lea	.TAB(pc),a1
.loop	movem.w	(a1)+,d0/d1
	lea	(a0,d0.w),a2
	move.w	#OPCODE_JMP,(a2)+
	pea	.TAB(pc,d1.w)
	move.l	(a7)+,(a2)
	tst.w	(a1)
	bne.b	.loop
	rts

.TAB	dc.w	_LVODoIO,DoIO_Emulation-.TAB
	dc.w	_LVOOpenDevice,Do_Nothing-.TAB
	dc.w	_LVOSendIO,Do_Nothing-.TAB	
	dc.w	_LVOAllocSignal,Do_Nothing-.TAB
	dc.w	_LVOFindTask,Do_Nothing-.TAB
	dc.w	_LVOCheckIO,Do_Nothing-.TAB
	dc.w	_LVOOldOpenLibrary,OpenLibrary_Emulation-.TAB
	dc.w	_LVOForbid,Do_Nothing-.TAB
	dc.w	_LVOPermit,Do_Nothing-.TAB
	dc.w	0			: end of tab


IOSTD_LOCATION	= $4000
DoIO_Emulation
	cmp.w	#CMD_READ,IO_COMMAND(a1)
	bne.b	.unsupported_command

	movem.l	d0-a6,-(a7)
	move.l	IO_DATA(a1),a0
	move.l	IO_OFFSET(a1),d0
	move.l	IO_LENGTH(a1),d1
	bsr	Disk_Load
	movem.l	(a7)+,d0-a6

.unsupported_command
Do_Nothing
	rts


OpenLibrary_Emulation
	move.l	#$dff080-gb_LOFlist,d0
	rts

; ---------------------------------------------------------------------------

BOOT_LOCATION		= $10000
TEXT_SCREEN_LOCATION	= $1c000
TEXT_SCREEN2_LOCATION	= $1e000
TEXT_LOCATION		= BOOT_LOCATION+$602
TEXT_X_POSITION		= BOOT_LOCATION+$62a
TEXT_Y_POSITION		= BOOT_LOCATION+$62e

PL_BOOT	PL_START
	PL_R	$636			; disable screen init
	PL_P	$574,.Write_Texts	
	PL_PS	$90a,.Patch_Demo_Part
	PL_P	$d8,.Skip_Part7
	PL_PSS	$8f8,.Disable_Sprites,2
	PL_END

.Disable_Sprites
	bsr	WaitRaster
	move.w	#DMAF_SPRITE|DMAF_AUD0|DMAF_AUD1|DMAF_AUD2|DMAF_AUD3,$dff096
	bra.w	Disable_Sprites


.Skip_Part7
	cmp.w	#6,$10000+$a12
	bne.b	.Not_Part6
	addq.w	#1,$10000+$a12
.Not_Part6
	rts

; This looks a bit different to the original demo screen but I like
; my version more as I think it looks better.

.Write_Texts
	moveq	#2-1,d6
	lea	TEXT_SCREEN_LOCATION,a4

.Write	move.l	a4,a1
	addq.w	#3,a1

	lea	TEXT_LOCATION,a0
	move.l	TEXT_X_POSITION,d0
	lsr.w	#3,d0
	move.l	TEXT_Y_POSITION,d1
.test	mulu.w	#320/8,d1
	add.l	d1,a1
	add.w	d0,a1
.write_all_chars
	moveq	#0,d0
	move.b	(a0)+,d0
	beq.b	.text_done
	moveq	#0,d1
	moveq	#Number_of_Font_Characters-1,d2
	lea	Font_Order_Table(pc),a2
.find_offset
	cmp.b	(a2)+,d0
	beq.b	.character_offset_found
	addq.w	#1,d1
	dbf	d2,.find_offset

	; character not found, convert to space
	moveq	#0,d1


.character_offset_found
	lea	Font(pc),a2
	add.w	d1,a2
	move.l	a1,a3
	moveq	#Font_Height-1,d7
.copy_character
	move.b	(a2),(a3)
	add.w	#Font_Width,a2
	add.w	#40,a3
	dbf	d7,.copy_character
	addq.w	#1,a1
	bra.b	.write_all_chars

.text_done

	lea	TEXT_SCREEN2_LOCATION,a4
	;subq.w	#1,a4
	sub.w	#40*3,a4
	dbf	d6,.Write

	rts


.Patch_Demo_Part
	move.l	$10000+$a0e,a0		; load address
	move.l	4+2(a0),a1		; destination address
	move.l	$aa+2(a0),a2		; jmp address
	add.w	#$e8,a0			; start of ByteKiller crunched data
	movem.l	a1/a2,-(a7)
	bsr	ByteKiller_Decrunch
	movem.l	(a7)+,a1/a2
	move.w	$10000+$a12,d0		; part number
	add.w	d0,d0
	lea	.TAB(pc),a0
	add.w	(a0,d0.w),a0		; a0: offset to patch list
	bsr	Apply_Patches
	move.l	a2,a0
	rts

.TAB	dc.w	0
	dc.w	PL_PART1-.TAB		; intro
	dc.w	PL_PART2-.TAB		; budget demo
	dc.w	PL_PART3-.TAB		; sailin' demo
	dc.w	PL_PART4-.TAB		; hiphop demo
	dc.w	PL_PART5-.TAB		; church demo
	dc.w	PL_PART6-.TAB		; 3d
	dc.w	PL_PART7-.TAB		; gremlin demo
	dc.w	PL_PART8-.TAB		; end part

; ---------------------------------------------------------------------------
; Part 1: "The Intro"

PL_PART1
	PL_START
	PL_SA	$78,$7e			; don't get old copperlist from graphics.lib
	PL_L	$16e6,$10000+$804	; old copperlist = loader part copperlist
	PL_P	$84c,Acknowledge_Level3_Interrupt
	PL_PSS	$b0a,Fix_DMA_Wait,4	; fix DMA wait in replayer
	PL_ORW	$eb0+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$f4c+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$1da,Set_Default_Level3_Interrupt,4
	PL_END

Set_Default_Level3_Interrupt
	pea	Acknowledge_Level3_Interrupt(pc)
	move.l	(a7)+,$6c.w
	rts


; ---------------------------------------------------------------------------
; Part 2: "A budget demo?"

PL_PART2
	PL_START
	PL_SA	$148,$14e		; don't get old copperlist from graphics.lib
	PL_L	$2dac,$10000+$804	; old copperlist = loader part copperlist
	PL_P	$23e,Acknowledge_Level3_Interrupt
	PL_ORW	$19a2+2,1<<9		; set Bplcon0 color bit
	PL_AW	$4c+2,-1		; fix loop counter (otherwise Bplcon 0
					; value at offset $1d66 will be cleared
	PL_ORW	$1d66+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1d82+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$3b84,Fix_DMA_Wait,4	; fix DMA wait in replayer
	PL_L	$fb0+2,$10000
	PL_P	$3d74,Fix_Volume_Write	; fix byte write to volume register
	PL_PS	$11c0,.Fix_Check
	PL_W	$1ae+2,$07ff
	PL_W	$1e6+2,$07ff
	PL_END

.Fix_Check
	cmp.b	#$ff,d3			; demo uses cmp.b $ff,d3
	rts


Fix_Volume_Write
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts


; ---------------------------------------------------------------------------
; Part 3: "The Sailin' demo"

PL_PART3
	PL_START
	PL_PSA	$4a,Get_Graphics_Base,$5c
	PL_L	$34e,$10000+$804	; old copperlist = loader part copperlist
	PL_P	$f8,Acknowledge_Level3_Interrupt
	PL_PSA	$8e,Get_Graphics_Base,$98
	PL_P	$e0,.Patch_Part2
	;PL_SA	0,$a			; skip trap #0
	;PL_SA	$d6,$da			; skip move.w #0,sr
	PL_END


.Patch_Part2
	lea	$3553c+$3abd0,a0	; start of ByteKiller crunched data
	pea	$3553c+$19f0		; destination address
	move.l	(a7),a1
	bsr	ByteKiller_Decrunch
	lea	PL_PART3_02(pc),a0
	move.l	(a7),a1
	bra.w	Apply_Patches


Get_Graphics_Base
	lea	$dff080-gb_LOFlist,a6
	rts

PL_PART3_02
	PL_START
	PL_L	$e38a,$10000+$804	; old copperlist = loader part copperlist
	PL_PSS	$69a,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_P	$856,Fix_Volume_Write	; fix byte write to volume register
	PL_PSA	$9a,Get_Graphics_Base,$ac
	PL_ORW	$e1e2+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$e382+2,1<<9		; set Bplcon0 color bit
	PL_P	$132,Acknowledge_Level3_Interrupt
	PL_PSA	$de,Get_Graphics_Base,$e8
	PL_END


; ---------------------------------------------------------------------------
; Part 4: "The HIPHOP demo"

PL_PART4
	PL_START
	PL_PSS	$42ee,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_P	$44aa,Fix_Volume_Write	; fix byte write to volume register
	PL_L	$3912,$10000+$804	; old copperlist = loader part copperlist
	PL_SA	$174,$17a		; don't get old copperlist from graphics.lib
	PL_P	$264,Acknowledge_Level3_Interrupt
	PL_ORW	$2796+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$27da+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2e32+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2e76+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2eba+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3606+2,1<<9		; set Bplcon0 color bit
	PL_END


; ---------------------------------------------------------------------------
; Part 5: "The Church demo"

PL_PART5
	PL_START
	;PL_SA	0,$a			; skip trap #0
	;PL_SA	$19e,$1ae		; skip move.w #0,sr
	PL_P	$e36,Acknowledge_Level3_Interrupt
	PL_PSA	$178,Set_Default_Level3_Interrupt,$182
	PL_SA	$136,$13c		; don't get old copperlist from graphics.lib
	PL_L	$1d5a,$10000+$804	; old copperlist = loader part copperlist
	PL_PSS	$1156,Fix_DMA_Wait,4	; fix DMA wait in replayer
	PL_P	$1348,Fix_Volume_Write	; fix byte write to volume register
	PL_ORW	$18e0+2,1<<9		; set Bplcon0 color bit
	PL_END

; ---------------------------------------------------------------------------
; Part 6: "W.O.T goes 3D"

PL_PART6
	PL_START
	PL_ORW	$3ee0+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3fa4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$4058+2,1<<9		; set Bplcon0 color bit
	PL_P	$1fc,Acknowledge_Level3_Interrupt
	PL_ORW	$14c+2,INTF_PORTS
	PL_PSS	$3b94,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_P	$3d50,Fix_Volume_Write	; fix byte write to volume register
	PL_SA	$104,$10a		; don't get old copperlist from graphics.lib
	PL_L	$436,$10000+$804	; old copperlist = loader part copperlist
	PL_W	$3f60,$1fe		; HTOTAL -> NOP
	PL_W	$3f64,$1fe		; HTOTAL -> NOP
	PL_W	$3f68,$1fe		; HTOTAL -> NOP
	PL_W	$3f6c,$1fe		; HTOTAL -> NOP
	PL_W	$3f70,$1fe		; HTOTAL -> NOP
	PL_W	$3f74,$1fe		; HTOTAL -> NOP
	PL_W	$3f78,$1fe		; HTOTAL -> NOP
	PL_W	$3f7c,$1fe		; HTOTAL -> NOP
	PL_W	$3f80,$1fe		; HTOTAL -> NOP
	PL_W	$3f84,$1fe		; HTOTAL -> NOP
	PL_W	$3f88,$1fe		; HTOTAL -> NOP
	PL_W	$3f8c,$1fe		; HTOTAL -> NOP
	PL_W	$3f90,$1fe		; HTOTAL -> NOP
	PL_W	$3f94,$1fe		; HTOTAL -> NOP
	PL_W	$3f98,$1fe		; HTOTAL -> NOP
	PL_W	$3f9c,$1fe		; HTOTAL -> NOP
	PL_END

; ---------------------------------------------------------------------------
; Part 7: "A Gremlin demo"

PL_PART7
	PL_START
	PL_R	0			; part is defective
	PL_END

; ---------------------------------------------------------------------------
; Part 8: "The end part"

PL_PART8
	PL_START
	PL_PSS	$29b8,Fix_DMA_Wait,2	; fix DMA wait in replayer
	PL_P	$2b74,Fix_Volume_Write	; fix byte write to volume register
	PL_ORW	$1756+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1832+2,1<<9		; set Bplcon0 color bit
	PL_SA	$58,$60			; don't get old copperlist from graphics.lib
	PL_L	$2102,$10000+$804	; old copperlist = loader part copperlist
	PL_P	$11a,Acknowledge_Level3_Interrupt
	PL_ORW	$78+2,INTF_PORTS
	PL_PS	$2a,.DMA
	PL_PS	$9e,.Disable_Sprites
	PL_END

.DMA	move.w	#$7fff,$96(a5)
	move.w	#DMAF_MASTER|DMAF_SETCLR|DMAF_BLITTER,$96(a5)
	rts

.Disable_Sprites
	lea	$dff000,a5	; original code
	
Disable_Sprites
	lea	$dff140,a0	; spr0pos
	moveq	#8-1,d7
	moveq	#0,d0
.disable_sprites
	move.l	d0,(a0)		; position and control
	addq.w	#8,a0
	dbf	d7,.disable_sprites	
	rts


; ---------------------------------------------------------------------------
; Support/helper routines.


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)


KillSys	move.w	#$7fff,$dff09a
	bsr.b	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	rts


WaitRaster
.wait1	btst	#0,$dff005
	beq.b	.wait1
.wait2	btst	#0,$dff005
	bne.b	.wait2
	rts

Fix_DMA_Wait
	moveq	#8,d0

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

Acknowledge_Level3_Interrupt
	move.w	#INTF_VERTB|INTF_BLIT|INTF_COPER,$dff09c
	move.w	#INTF_VERTB|INTF_BLIT|INTF_COPER,$dff09c
	rte

; ---------------------------------------------------------------------------

; d0.l: offset
; d1.l: size
; a0.l: destination

Disk_Load
	movem.l	d0-a6,-(a7)
	moveq	#1,d2			; disk number
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d0-a6
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

; d0.b: rawkey code

Check_Quit_Key
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	rts	


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

	bsr.b	Check_Quit_Key

	move.l	(a2)+,d1
	beq.b	.nocustom
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.nocustom
	
	moveq	#3,d0
	bsr	Wait_Raster_Lines

	and.b	#~(1<<6),$e00(a1)	; set input mode
.end	move.w	#1<<3,$9c(a0)
	move.w	#1<<3,$9c(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte



Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine

; ---------------------------------------------------------------------------

; Bytekiller decruncher
; resourced and adapted by stingray

ByteKiller_Decrunch
	bsr.b	.decrunch
	tst.l	d5
	beq.b	.ok

; checksum doesn't match, file corrupt
	pea	.ErrTxt(pc)
	pea	(TDREASON_FAILMSG).w
	move.l	resload(pc),a0
	jmp	resload_Abort(a0)


.ok	rts

.ErrTxt	dc.b	"Decrunching failed, file corrupt!",0
	cnop	0,4

.decrunch
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d5
	move.l	a1,a2
	add.l	d0,a0
	add.l	d1,a2
	move.l	-(a0),d0
	eor.l	d0,d5
.loop	lsr.l	#1,d0
	bne.b	.nonew1
	bsr.b	.nextlong
.nonew1	bcs.b	.getcmd

	moveq	#8,d1
	moveq	#1,d3
	lsr.l	#1,d0
	bne.b	.nonew2
	bsr.b	.nextlong
.nonew2	bcs.b	.copyunpacked

; data is packed, unpack and copy
	moveq	#3,d1			; next 3 bits: length of packed data
	clr.w	d4

; d1: number of bits to get from stream
; d4: length
.packed	bsr.b	.getbits
	move.w	d2,d3
	add.w	d4,d3
.copypacked
	moveq	#8-1,d1
.getbyte
	lsr.l	#1,d0
	bne.b	.nonew3
	bsr.b	.nextlong
.nonew3	addx.l	d2,d2
	dbf	d1,.getbyte

	move.b	d2,-(a2)
	dbf	d3,.copypacked
	bra.b	.next

.ispacked
	moveq	#8,d1
	moveq	#8,d4
	bra.b	.packed

.getcmd	moveq	#2,d1			; next 2 bits: command
	bsr.b	.getbits
	cmp.b	#2,d2			; %10: unpacked data follows
	blt.b	.notpacked
	cmp.b	#3,d2			; %11: packed data follows
	beq.b	.ispacked

; %10
	moveq	#8,d1			; next byte:
	bsr.b	.getbits		; length of unpacked data
	move.w	d2,d3			; length -> d3
	moveq	#12,d1
	bra.b	.copyunpacked

; %00 or %01
.notpacked
	moveq	#9,d1
	add.w	d2,d1
	addq.w	#2,d2
	move.w	d2,d3

.copyunpacked
	bsr.b	.getbits		; get offset (d2)
	subq.w	#1,d2
.copy	move.b	(a2,d2.w),-(a2)
	dbf	d3,.copy

.next	cmp.l	a2,a1
	blt.b	.loop
	rts

.nextlong
	move.l	-(a0),d0
	eor.l	d0,d5
	move.w	#$10,ccr
	roxr.l	#1,d0
	rts

; d1.w: number of bits to get
; ----
; d2.l: bit stream

.getbits
	subq.w	#1,d1
	clr.w	d2
.getbit	lsr.l	#1,d0
	bne.b	.nonew
	move.l	-(a0),d0
	eor.l	d0,d5
	move.w	#$10,ccr
	roxr.l	#1,d0
.nonew	addx.l	d2,d2
	dbf	d1,.getbit
	rts

; ---------------------------------------------------------------------------

Font	DC.L	$534C3E4D,$4B546A39,$5F645221,$53545222
	DC.L	$6F4C6E1D,$4F2A4E5F,$6F685221,$5F54621D
	DC.L	$2F4CAE1D,$ABAAAC1D,$352A5CC7,$A3D69419
	DC.L	$AF6CAE1D,$2D3291E7,$9097AC1D,$93684221
	DC.L	$4B54B221,$5D544E21,$B34C54C1,$6B545221
	DC.L	$53545221,$5B545221,$5354522F,$4B2420ED
	DC.L	$2D4C5E3D,$11974A1D,$352A6221,$6D542C5F
	DC.L	$6F4CA2D1,$4B542C21,$53642221,$73749239
	DC.L	$63584A50,$90684D1D,$334C6247,$63584A47
	DC.L	$AB25622D,$4B259121,$6E645E39,$3552A25D
	DC.L	$63584A50,$60685221,$63584A47,$63584A47
	DC.L	$3325622D,$4B253421,$53645E39,$3558A247
	DC.L	$53683E4D,$6D923E39,$4B4C3439,$53545227
	DC.L	$356C3447,$6F346247,$35324A39,$4B544A47
	DC.L	$95683447,$3F323447,$354C5447,$3392B44D
	DC.L	$35383447,$093291E7,$35979411,$33586A21
	DC.L	$4B543221,$55546421,$33545241,$4B545221
	DC.L	$53545221,$4B545221,$53545239,$4B4CCE12
	DC.L	$35546C17,$6F324A61,$53D51A12,$5554D321
	DC.L	$354C4A39,$6354A621,$5324DAED,$30377121
	DC.L	$5B4476AF,$4B326E47,$43741A21,$5B447621
	DC.L	$3FDA5A31,$77DA6E42,$355C4205,$535C3247
	DC.L	$5B4476AF,$53325221,$5B447621,$5B447621
	DC.L	$AFDA5A31,$77DA5239,$525C4205,$53443221
	DC.L	$536852DF,$33983A11,$63586E39,$5354522D
	DC.L	$3D4C5427,$3F283227,$35324A39,$632A5E27
	DC.L	$8D6834E1,$353432E1,$354C544D,$33BAA4E7
	DC.L	$35923451,$4B3234E7,$6F32DE11,$63583E21
	DC.L	$5F683E1D,$6568621A,$3F6C5447,$4B322E1D
	DC.L	$8F69BE1F,$6D323442,$30322C39,$4B4C52ED
	DC.L	$354C3E11,$35684A1D,$53C9DA47,$532AEB21
	DC.L	$6F2A6211,$5392A639,$5364DA47,$75723439
	DC.L	$6F686E1D,$6F686EE1,$ADAAACDF,$2D2A2C5F
	DC.L	$35926E1D,$6F683417,$9C323447,$35972C47
	DC.L	$6F686E1D,$6F682C1D,$6F686E1D,$6B6C6A19
	DC.L	$4B286E1D,$6F686E21,$6D323447,$35322E47
	DC.L	$534C524D,$6F4C2421,$6358AD5F,$532A5239
	DC.L	$2D4C4E3D,$9F522E2D,$6F6A5221,$3354542D
	DC.L	$8D322EE1,$352C2AEF,$2D4C5459,$33AA8CE7
	DC.L	$2F922E19,$4B3234F7,$4B684A11,$4B589421
	DC.L	$53522447,$3D322A47,$254C544D,$4B233447
	DC.L	$35322441,$4B32344A,$65321E51,$4B5A5212
	DC.L	$354C3E59,$6F4C5247,$53E5AAED,$532AEB21
	DC.L	$534C3239,$53922639,$53642212,$7F787E11
	DC.L	$35323447,$35323DE1,$33343241,$4B4C4A39
	DC.L	$A5B23447,$3532913D,$88323447,$3532314D
	DC.L	$55525427,$55524947,$35323447,$4B4C4A39
	DC.L	$2F323447,$3532345F,$34323447,$35323447
	DC.L	$534C52DF,$55648E21,$63586E39,$53545211
	DC.L	$254C6227,$AD523439,$35525221,$63545E39
	DC.L	$8D2A34E1,$353432E7,$354C344D,$31829CE7
	DC.L	$33923E2F,$4B326EDF,$6F4C6011,$5F585221
	DC.L	$534A3441,$352A6247,$354C5459,$4B3F3447
	DC.L	$3532341D,$4B32344A,$4F324A39,$4B4C52ED
	DC.L	$35686C11,$11684A1D,$53E55247,$5354E321
	DC.L	$534CAAD1,$53924621,$53645247,$4A4F8B41
	DC.L	$2D2A2C5F,$2D2A2E47,$2B2C2A59,$4B4C4A39
	DC.L	$358291E2,$90979117,$A0323447,$35683147
	DC.L	$4D4A4C3F,$4D4A2D41,$2D2A2C5F,$4B4C4A39
	DC.L	$95323447,$35323421,$38323447,$35323447
	DC.L	$5354524D,$2F329E21,$4B4C3439,$4B544A41
	DC.L	$354C3447,$5F323439,$35584A39,$4B2A4A21
	DC.L	$93973447,$3F323247,$354C3447,$3592944D
	DC.L	$33383447,$4B326ECF,$354C3411,$55585221
	DC.L	$53323447,$3534621D,$354C544D,$4B373447
	DC.L	$2F6A3227,$49326E17,$65686039,$4B4C5212
	DC.L	$35685E11,$534C4A23,$53C9AE12,$5354FB21
	DC.L	$53545221,$53BA4621,$5354AAED,$60656147
	DC.L	$909791E2,$90979E1D,$33343241,$4B4C4A39
	DC.L	$3F9A3447,$35323442,$35323447,$354C2C47
	DC.L	$35323447,$35328A47,$33343241,$4B4C4A39
	DC.L	$95323447,$35323439,$20323447,$35682E1D
	DC.L	$534C524D,$4B922421,$5F645221,$4B544AE1
	DC.L	$6F2A2C1D,$4D686E39,$6F6C4A39,$5F546239
	DC.L	$2B97AE1D,$ABAAA21F,$352A6EC7,$AD929419
	DC.L	$A368B11D,$6F6A4AE7,$9068AC1D,$50685221
	DC.L	$536F6E1D,$68682AE7,$B56834C7,$6F37341D
	DC.L	$3352A25D,$5F6F4A17,$304C2C2F,$4B2452ED
	DC.L	$2D4C525F,$53684A1D,$53D55221,$5354D321
	DC.L	$532A5221,$53AE4621,$4B545221,$3436351D
	DC.L	$909791E2,$90979D29,$ADAAACDF,$2D2A2C5F
	DC.L	$AB926E1D,$6F686E21,$EF6A6C1F,$6D68324D
	DC.L	$686F691A,$686F251D,$6F686E1D,$6F686E1D
	DC.L	$2F326E1D,$6F686E21,$6D6F691A,$684C3239
	DC.L	$53545221,$53545221,$53545221,$63545221
	DC.L	$53545221,$53545221,$53545211,$53545221
	DC.L	$53545221,$53545221,$53545221,$53545221
	DC.L	$53525221,$53545221,$53545221,$535452DF
	DC.L	$53545221,$5354525D,$53546E21,$53545221
	DC.L	$A3535221,$53545221,$53245221,$53545212
	DC.L	$53545221,$53545221,$532A5221,$53542C21
	DC.L	$53545221,$53945221,$63545221,$52535321
	DC.L	$53545221,$53545211,$53545221,$53545221
	DC.L	$53545221,$53545221,$53545221,$5354A241
	DC.L	$53545221,$53545231,$53545221,$53545221
	DC.L	$53545221,$53545221,$13545221,$5324A251
	DC.L	$53545229,$535C5229,$53445229,$534C5229
	DC.L	$53745229,$537C5229,$53645229,$536C5229
	DC.L	$53145229,$531C5229,$53045229,$530C5229
	DC.L	$53345229,$533C5229,$53245229,$532C5229
Font_Size	= *-Font

Font_Width	= 192
Font_Height	= 8

Font_Order_Table
	dc.b	' !"#$%&''()*+,-./0123456789:;<=>?@'
	dc.b	"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	dc.b	"[\]^_`"
	dc.b	"abcdefghijklmnopqrstuvwxyz{|}~"
Number_of_Font_Characters = *-Font_Order_Table
	CNOP	0,4


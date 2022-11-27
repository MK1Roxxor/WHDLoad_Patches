***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    BRAINSTORM MEGADEMO WHDLOAD SLAVE       )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            November 2022                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 27-Nov-2022	- ByteKiller decruncher in loader part relocated and
;		  optimised, parts are decrunched much faster now

; 26-Nov-2022	- more Bplcon0 color bit fixes in part 5 added
;		- real cause for the snoop problems in the line drawing
;		  routine found (blitter registers are written to in the
;		  vertical blank interrupt), problem fixed without completely
;		  replacing the line drawing code
;		- all parts tested, no problems encountered

; 24-Nov-2022	- interrupt fixes for part 5 corrected
;		- line drawing in part 5 replaced
;		- 68000 quitkey support for parts 6,7, 8 and 9 added

; 21-Nov-2022	- interrupts in part 5 (sphere scroller) fixed

; 20-Nov-2022	- CPU dependent delays in part 3 ("Trembling Balls") fixed
;		- 68000 quitkey support for all parts of part 3 enabled

; 15-Nov-2022	- SMC in level 3 interrupt code in intro fixed
;		- level 6 interrupt vector initialised before starting
;		  the demo, intro part enables level 3 and level 6 interrupts
;		  but only initialises the level 3 interrupt vector
;		- 68000/NOVBRMOVE quitkey support for loader part works now
;		- 68000/NOVBRMOVE quitkey support for part 1 works now
;		- 68000/NOVBRMOVE quitkey support for part 2 added

; 13-Nov-2022	- parts can be run separately now, code to patch the
;		  parts adapted to determine the part number from the
;		  file table pointer
;		- intro can be disabled, also done to speed up development
;		- part3 fully patched, problem with wrong offset in
;		  patch list fixed
;		- all remaining parts patched
;		- minor problem in loader decrypter fixed, decrypter
;		  did not decrypt all data due to wrong loop counter
;		  handling, this caused graphics bugs, the module was not
;		  replayed properly either
;		- "Insert Disk 2" part is disabled by default, it can be
;		  enabled with CUSTOM1

; 12-Nov-2022	- work started, patch was requested by Keito
;		- loader part deprotected (trace vector decoder)
;		- intro, loader and first 3 demo parts patched


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	exec/io.i
	INCLUDE	hardware/intbits.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
DEBUG

PART_TO_RUN	= 0
DISABLE_INTRO	= 0


	
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
	dc.w	0			; ws_CurrentDir
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


.config	dc.b	"C1:B:Enable ""Insert Disk 2"" Part"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Brainstorm/Megademo",0
	ENDC

.name	dc.b	"Megademo",0
.copy	dc.b	"1990 Brainstorm",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (27.11.2022)",0

	CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load bootblock
	moveq	#1,d0
	bsr	Set_Disk_Number

	lea	$200.w,a0
	moveq	#0,d0
	move.l	#$400,d1
	bsr	Disk_Load


	move.l	a0,a5

	; Version check
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$4172,d0
	beq.b	.Is_Supported_Version

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.Is_Supported_Version

	; Patch bootblock
	lea	PL_BOOT(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; Set default level 3 interrupt
	pea	Acknowledge_Level3_Interrupt(pc)
	move.l	(a7)+,$6c.w

	; Set default level 6 interrupt
	pea	Acknowledge_Level6_Interrupt(pc)
	move.l	(a7)+,$78.w

	; Run demo
	jmp	$3a(a5)


; ---------------------------------------------------------------------------

PL_BOOT	PL_START
	PL_PSS	$58,.Load_DoIO,4	; load "loading" copperlist+graphics
	PL_PSS	$9a,.Load_DoIO,4	; load intro part
	PL_PSS	$c2,.Load_DoIO,4	; load loader part
	PL_PSS	$de,.Load_DoIO,4	; turn off drive motor
	PL_PSS	$62,.Fix_Copperlist,2
	PL_ORW	$ee+2,1<<9		; set Bplcon0 color bit
	PL_SA	$74,$7c			; skip byte write to copjmp1
	PL_PS	$e8,.Patch_Intro_Part
	PL_P	$108,.Patch_Loader_Part
	PL_END

.Load_DoIO
	cmp.w	#CMD_READ,IO_COMMAND(a1)
	bne.b	.exit
	move.l	IO_OFFSET(a1),d0
	move.l	IO_LENGTH(a1),d1
	move.l	IO_DATA(a1),a0
	bsr	Disk_Load
.exit	rts


.Patch_Intro_Part
	lea	$1fd00+$c6,a0
	pea	$20000
	move.l	(a7),a1
	bsr	ByteKiller_Decrunch	
	lea	PL_INTRO(pc),a0
	move.l	(a7),a1
	bra.w	Apply_Patches

.Patch_Loader_Part
	lea	$10500+$c6,a0
	lea	$20000,a1
	bsr	ByteKiller_Decrunch	

	bsr	Decrypt_Loader

	lea	PL_LOADER(pc),a0
	pea	$50000
	move.l	(a7),a1
	bra.w	Apply_Patches

.Fix_Copperlist
	or.w	#1<<9,$10048+2
	move.w	#$83d0,$dff096
	rts

; ---------------------------------------------------------------------------

PL_INTRO
	PL_START
	IFNE	DISABLE_INTRO
	PL_R	0
	ENDC
	PL_PSS	$5e0,Fix_DMA_Wait,2
	PL_P	$7de,Fix_Volume_Write
	PL_P	$6c,.Acknowledge_Level3_Interrupt
	PL_END

.Acknowledge_Level3_Interrupt
	movem.l	(a7)+,d0-a6
	bra.w	Acknowledge_Level3_Interrupt


; ---------------------------------------------------------------------------

FILE_TABLE_POINTER	= ($c0-$30)+$1b2
FILE_TABLE		= ($c0-$30)+$1b6

PL_LOADER
	PL_START
	PL_P	$2a,.Flush_Cache
	PL_SA	$30,$44			; don't modify exception vectors
	PL_ORW	$5090+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$54de,Fix_DMA_Wait,2
	PL_P	$56a2,Fix_Volume_Write
	PL_PSS	$7c,Initialise_Keyboard,2
	PL_P	$42c,.Load_Part
	PL_PS	$3d14,Wait_Blit_a0_dff050

	PL_PSS	$140,.Patch_Demo_Part,2
	PL_P	$23c,ByteKiller_Decrunch


	IFD	DEBUG
	IFNE	PART_TO_RUN
	PL_PS	$94,.Set_File_Table
	ENDC
	ENDC


	PL_IFC1
	PL_ELSE
	PL_PS	$a4,.Disable_Insert_Disk2_Part
	PL_ENDIF

	PL_END


; Loader code will be copied to $c0.w, cache needs to be
; flushed after code has been copied.
.Flush_Cache
	bsr	Flush_Cache
	jmp	$c0.w


.Load_Part
	move.w	(a5),d0
	move.w	(a4),d1
	addq.w	#1,d1
	mulu.w	#512*11,d0
	mulu.w	#512*11,d1
	move.l	(a3),a0
	bra.w	Disk_Load


	IFD	DEBUG
.Set_File_Table
	lea	($c0-$30)+$1b6.w,a1
	add.w	#(PART_TO_RUN-1)*FE_SIZEOF,a1
	move.l	a1,(a0)

	IFGT	PART_TO_RUN-4
	moveq	#2,d0
	bsr	Set_Disk_Number
	ENDC
	rts
	ENDC

.Disable_Insert_Disk2_Part
	lea	(FILE_TABLE_POINTER).w,a0
	move.l	(a0),a1

	cmp.w	#60,FE_TRACK(a1)
	bne.b	.not_insert_disk2_part
	add.w	#FE_SIZEOF,a1
	moveq	#2,d0
	bsr	Set_Disk_Number

.not_insert_disk2_part
	rts
	


.Patch_Demo_Part
	move.w	#$7fff,$dff09c		; original code

	; determine part number
	move.l	(FILE_TABLE_POINTER).w,a0
	sub.w	#FE_SIZEOF,a0
	lea	(FILE_TABLE),a1
	sub.w	a1,a0
	move.l	a0,d0
	divu.w	#FE_SIZEOF,d0

	lea	.Parts_Table(pc),a0
	add.w	d0,d0
	move.w	.Parts_Table(pc,d0.w),d0
	lea	.Parts_Table(pc,d0.w),a0
	move.l	($c0-$30)+$148+2,a1
	bsr	Apply_Patches
	rts

.Parts_Table
	dc.w	PL_PART1-.Parts_Table
	dc.w	PL_PART2-.Parts_Table
	dc.w	PL_PART3-.Parts_Table
	dc.w	PL_PART4-.Parts_Table
	dc.w	PL_PART5-.Parts_Table
	dc.w	PL_PART6-.Parts_Table
	dc.w	PL_PART7-.Parts_Table
	dc.w	PL_PART8-.Parts_Table
	dc.w	PL_PART9-.Parts_Table
	

Initialise_Keyboard
	bset	#1,$bfe001	; original code
	bra.w	Init_Level2_Interrupt

FILE_ENTRY		RSRESET
FE_LOAD_ADDRESS		rs.l	1
FE_DECRUNCH_ADDRESS	rs.l	1
FE_TRACK		rs.w	1
FE_NUMBER_OF_TRACKS	rs.w	1
FE_SIZEOF		rs.b	0


; Brainstorm Megademo, Loader part decrypter
; Part was protected with a TVD.
; StingRay, 12.11.2022

Decrypt_Loader
	lea	$20000+$24+$68,a0	; encrypted data
	lea	$50000,a1		; destination
	move.w	#$1e300/2-1,d7
	moveq	#8,d2
.loop	subq.b	#1,d2
	tst.w	d2
	bne.b	.normal
	bsr.b	Decrypt_Variant3
	bra.b	.skip
.normal	bsr.b	Decrypt_Variant1
.skip	bsr.b	Decrypt_Variant2

	tst.w	d2
	bne.b	.skip2
	moveq	#7,d2
.skip2	dbf	d7,.loop
	rts


Decrypt_Variant1
	move.b	(a0)+,d0
	bchg	d2,d0
	ror.b	d0
	not.b	d0
	move.b	d0,(a1)+
	rts	

Decrypt_Variant2
	move.b	(a0)+,d0
	tst.b	d2
	bne.b	.skip
	ror.b	#$03,d0
.skip	rol.b	d2,d0
	eor.b	#$43,d0
	move.b	d0,(a1)+
	rts	

Decrypt_Variant3
	move.b	(a0)+,d0
	rol.b	#$03,d0
	bchg	d2,d0
	ror.b	#1,d0
	not.b	d0
	move.b	d0,(a1)+
	rts


; ---------------------------------------------------------------------------
; bobs part

PL_PART1
	PL_START
	PL_W	$14e+2,$1fe		; Bplcon3 -> NOP
	PL_W	$282+2,$1fe		; Bplcon3 -> NOP
	PL_AW	$1cc+2,-1		; fix loop counter
	PL_PSS	$2fe32,Fix_DMA_Wait,2
	PL_P	$2fffc,Fix_Volume_Write
	PL_PSS	$354,Initialise_Keyboard,2
	PL_END
	



; ---------------------------------------------------------------------------
; "Power Street" part

PL_PART2
	PL_START
	PL_PSS	$1244,Fix_DMA_Wait,2
	PL_PS	$141e,Fix_Volume_Write
	PL_PSS	$4a,Fix_Raster_Wait,2
	PL_PSS	$2c,.Initialise_Keyboard,2
	PL_END

.Initialise_Keyboard
	move.w	#$83f0,$dff096
	bra.w	Init_Level2_Interrupt

Fix_Raster_Wait
	btst	#0,$dff004+1
	rts


; ---------------------------------------------------------------------------
; "Trembling Balls" part

PL_PART3
	PL_START
	PL_SA	$40d2,$40d8		; skip byte write to copjmp1
	PL_SA	$9020,$9026		; skip byte write to copjmp1
	PL_P	$11656,Acknowledge_Level3_Interrupt
	PL_PSS	$11840,Fix_DMA_Wait,2
	PL_P	$11a0a,Fix_Volume_Write
	PL_ORW	$960e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$9646+2,1<<9		; set Bplcon0 color bit
	PL_PS	$90d6,Wait_Blit_a0_dff050
	PL_P	$60,.Delay960
	PL_PSS	$84,.Fix_Fade_Delay,2
	PL_PSS	$9a,.Fix_Fade_Delay2,2
	PL_P	$4120,.Delay16384
	PL_PSS	$4154,.Fix_Fade_Delay3,2
	PL_PS	$24,Init_Level2_Interrupt
	PL_END

.Delay960
	move.w	#960/20,d0
	bra.w	Wait_Raster_Lines

.Fix_Fade_Delay
	add.w	#$111,(a0)
.Fix_Fade_Delay_Common
	move.l	d0,-(a7)
	moveq	#0,d0
	move.w	d1,d0
	divu.w	#$34,d0
	bsr	Wait_Raster_Lines
	move.l	(a7)+,d0
	rts

.Fix_Fade_Delay2
	sub.w	#$111,(a1)
	bra.b	.Fix_Fade_Delay_Common

.Fix_Fade_Delay3
	add.w	#$111,d1
	move.l	d0,-(a7)
	moveq	#0,d0
	move.w	d2,d0
	divu.w	#$34,d0
	bsr	Wait_Raster_Lines
	move.l	(a7)+,d0
	rts

.Delay16384
	move.w	#16384/$34,d0
	bra.w	Wait_Raster_Lines
	

; ---------------------------------------------------------------------------
; "Disk change" part

PL_PART4
	PL_START
	PL_PSS	$77c,Fix_DMA_Wait,2
	PL_P	$94e,Fix_Volume_Write
	PL_PSS	$42,Fix_Raster_Wait,2
	PL_P	$200,.Set_Disk2
	PL_B	$82,$60
	PL_PSS	$96,Fix_Raster_Wait,2
	PL_END

.Set_Disk2
	moveq	#2,d0
	bra.w	Set_Disk_Number
	
; ---------------------------------------------------------------------------
; "Sphere Scroller" part

PL_PART5
	PL_START
	PL_ORW	$217e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$21ba+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$21ce+2,1<<9		; set Bplcon0 color bit
	PL_W	$21b2,$ffdf		; fix wrong PAL wait
	PL_PS	$3ed2,.Wait_Blit
	PL_PSS	$a71e,Acknowledge_Level6_Interrupt_Request,2
	PL_PSS	$2268,Acknowledge_Level3_Interrupt_Request,2
	PL_ORW	$3dbe+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3dc4+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$2ee2,.draw_line,6	
	PL_ORW	$208+2,INTF_PORTS	; enable level 2 interrupts
	PL_END


; The level 3 interrupt can cause problems as the blitter registers
; are changed, this can lead to problems in the line drawing routine.
; To fix this, the vertical blank interrupt is disabled before drawing
; a line.
.draw_line
	movem.w	$20000+$2e14,d2/d3
	move.w	#INTF_VERTB,$dff09a
	jsr	$20000+$383e
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_VERTB,$dff09a
	rts	


.Wait_Blit
	moveq	#7,d0
	lea	-40*256(a1),a3
	bra.w	Wait_Blit


; ---------------------------------------------------------------------------
; "Morphing Line Vectors" part

PL_PART6
	PL_START
	PL_PSS	$2c6,Fix_DMA_Wait,2
	PL_P	$490,Fix_Volume_Write
	PL_P	$2e,Acknowledge_Level3_Interrupt
	PL_ORW	$16+2,INTF_PORTS
	PL_END

; ---------------------------------------------------------------------------
; "Whirlwind" part

PL_PART7
	PL_START
	PL_P	$13c,Acknowledge_Level3_Interrupt
	PL_ORW	$6e+2,INTF_PORTS
	PL_END

; ---------------------------------------------------------------------------

PL_PART8
	PL_START
	PL_PSS	$1c974,Fix_DMA_Wait,2
	PL_P	$1cb3e,Fix_Volume_Write
	PL_W	$b8+2,$1fe		; Bplcon3 -> NOP
	PL_PSS	$19b4,.Wait_Blit,2
	PL_PSS	$24ce,.Wait_Blit,2
	PL_PSS	$7c,.Enable_Level2_Interrupt,2
	PL_END

.Enable_Level2_Interrupt
	move.w	#$7fff,$dff09a
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,$dff09a
	rts

.Wait_Blit
	bsr	Wait_Blit
	move.w	#$09f0,$dff040
	rts

; ---------------------------------------------------------------------------
; "Hall of Heroes" part


PL_PART9
	PL_START
	PL_PSS	$59ce,Fix_DMA_Wait,2
	PL_P	$5b98,Fix_Volume_Write
	PL_PSS	$88,Init_Level2_Interrupt,2
	PL_END

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
	move.l	d0,-(a7)
	moveq	#5,d0
	bsr.b	Wait_Raster_Lines
	move.l	(a7)+,d0
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

Fix_Volume_Write
	move.l	d0,-(a7)
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts

Acknowledge_Level3_Interrupt
	bsr.b	Acknowledge_Level3_Interrupt_Request
	rte

Acknowledge_Level3_Interrupt_Request
	move.w	#INTF_VERTB|INTF_COPER|INTF_BLIT,$dff09c
	move.w	#INTF_VERTB|INTF_COPER|INTF_BLIT,$dff09c
	rts

Acknowledge_Level6_Interrupt
	bsr.b	Acknowledge_Level6_Interrupt_Request
	rte

Acknowledge_Level6_Interrupt_Request
	move.w	#INTF_EXTER,$dff09c
	move.w	#INTF_EXTER,$dff09c
	rts

Flush_Cache
	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts


; ---------------------------------------------------------------------------

Disk_Load
	movem.l	d0-a6,-(a7)
	move.w	#1<<5,$dff09a
	move.b	Disk_Number(pc),d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	move.w	#1<<15|1<<5,$dff09a
	movem.l	(a7)+,d0-a6
	rts

Set_Disk_Number
	move.l	a0,-(a7)
	lea	Disk_Number(pc),a0
	move.b	d0,(a0)
	move.l	(a7)+,a0
	rts

Disk_Number	dc.b	0
		dc.b	0


; ---------------------------------------------------------------------------

; a0.l: patch list
; a1.l: destination

Apply_Patches
	movem.l	d0-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts


Wait_Blit_a0_dff050
	bsr.b	Wait_Blit
	move.l	a0,$dff050
	rts

Wait_Blit
	tst.b	$dff002
.blitter_still_busy
	btst	#6,$dff002
	bne.b	.blitter_still_busy
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
;
; a0.l: source
; a1.l: destination

ByteKiller_Decrunch
	bsr.b	.decrunch
	tst.l	d5
	beq.b	.ok

; checksum doesn't match, file corrupt
	pea	ErrText(pc)
	pea	(TDREASON_FAILMSG).w
	bra.w	EXIT

.ok	rts


.decrunch
	move.l	(a0)+,d0		; packed length
	move.l	(a0)+,d1		; unpacked length
	move.l	(a0)+,d5		; checksum
	add.l	d0,a0			; a0: end of packed data
	lea	(a1,d1.l),a2		; a2: end of unpacked data
	move.l	-(a0),d0		; get first long
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
	move.w	#1<<4,ccr
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
	move.w	#1<<4,ccr
	roxr.l	#1,d0
.nonew	addx.l	d2,d2
	dbf	d1,.getbit
	rts


ErrText	dc.b	"Decrunching failed, file corrupt!",0



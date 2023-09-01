***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*( CRAYON SHINCHAN/MELON DEZIGN WHDLOAD SLAVE )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            September 2023                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************


; 01-Sep-2023	- work started
;		- and finished about 2.5 hours later, interrupt problems
;		  fixed, all AGA register acccesses disabled, out of
;		  bounds blit fixed, delay for title picture added,
;		  Bplcon0 color bit fixes (x7), OS stuff patched


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Hardware/dmabits.i
	INCLUDE	hardware/intbits.i
	INCLUDE	exec/types.i
	INCLUDE	exec/exec_lib.i
	INCLUDE	exec/io.i
	INCLUDE	devices/trackdisk.i


RAWKEY_F10	= $59

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= RAWKEY_F10
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
	dc.w	0			; ws_CurrentDir
	dc.w	0			; ws_DontCache
	dc.b	0			; ws_KeyDebug
	dc.b	QUITKEY			; ws_KeyExit
	dc.l	0			; ws_ExpMem
	dc.w	.name-HEADER		; ws_name
	dc.w	.copy-HEADER		; ws_copy
	dc.w	.info-HEADER		; ws_info
	dc.w	0			; ws_kickname
	dc.l	0			; ws_kicksize
	dc.w	0			; ws_kickcrc
	dc.w	.config-HEADER		; ws_config


.config	dc.b	"C1:B:Enable Hidden Part"
	dc.b	0

.name	dc.b	"Crayon Shinchan",0
.copy	dc.b	"1993 Melon Dezign",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.2 (01.09.2023)",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load bootblock
	lea	$2000.w,a0
	moveq	#0,d0
	move.l	#512*2,d1
	bsr	Disk_Load

	move.l	a0,a5
	
	; Version check
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$cf0a,d0		; V2.0
	beq.b	.Version_is_Supported

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
.Version_is_Supported


	; Install exec library emulation
	lea	(EXEC_LOCATION).w,a0
	move.l	a0,$4.w
	bsr	Create_Exec_Emulation


	; Patch bootblock
	lea	PL_BOOTBLOCK(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches


	; relocate stack to low memory
	lea	$1000.w,a7

	; Set default level 3 interrupt vector
	pea	Acknowledge_Level3_Interrupt(pc)
	move.l	(a7)+,$6c.w

	; Run demo
	lea	$1000.w,a6	; copperlist
	lea	$2000.w,a1	; StdIo
	jmp	3*4(a5)


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
	bsr.b	Patch_Part
	movem.l	(a7)+,d0-a6

.unsupported_command
Do_Nothing
	rts

Patch_Part
	lea	.Patch_Table(pc),a0
	move.l	IO_OFFSET(a1),d0
.Check_All_Table_Entries
	cmp.l	(a0)+,d0
	beq.b	.Part_To_Patch_Found

	addq.w	#4,a0
	tst.l	(a0)
	bne.b	.Check_All_Table_Entries
	rts

.Part_To_Patch_Found
	move.l	(a0),d0
	lea	.Patch_Table(pc,d0.w),a0
	move.l	IO_DATA(a1),a1
	bra.w	Apply_Patches
	


.Patch_Table
	dc.l	$b1600,PL_TITLE_PICTURE-.Patch_Table
	dc.l	$a7c00,PL_HIDDEN_PART-.Patch_Table
	dc.l	$200,PL_DEMO-.Patch_Table
	dc.l	0

; ---------------------------------------------------------------------------

PL_BOOTBLOCK
	PL_START
	PL_SA	$c,$18			; skip graphics base access
	PL_ORW	$18+4,1<<9		; set Bplcon0 color bit

	PL_IFC1
	PL_W	$aa,$4e71
	PL_ENDIF
	PL_END



; ---------------------------------------------------------------------------

PL_HIDDEN_PART
	PL_START
	PL_P	$1370,Acknowledge_Level3_Interrupt
	PL_W	$13b4,$1fe		; disable BPLCON3 access
	PL_W	$13c0,$1fe		; disable FMODE access
	PL_W	$13c4,$1fe		; disable DIWHIGH access
	PL_ORW	$1484+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$8a+2,INTF_PORTS	; enable level 2 interrupts
	PL_END

; ---------------------------------------------------------------------------

PL_DEMO	PL_START
	PL_ORW	$50+2,INTF_PORTS	; enable level 2 interrupts	
	PL_W	$73e,$1fe		; disable BPLCON3 access
	PL_W	$742,$1fe		; disable FMODE access
	PL_P	$784,Acknowledge_Level3_Interrupt
	PL_P	$192,.Load_Data
	PL_PS	$68,.Display_Title_Picture
	PL_END

.Display_Title_Picture
	jsr	$70000
	moveq	#3*10,d0
	move.l	resload(pc),a0
	jmp	resload_Delay(a0)

.Load_Data
	move.w	d2,d0
	move.w	d3,d1
	mulu.w	#512*11,d0
	mulu.w	#512*11,d1
	move.l	$7b000+$7a2,a0
	bsr.w	Disk_Load

	move.l	a0,a1
	lea	.Patch_Table(pc),a0
.Check_All_Table_Entries
	cmp.w	(a0)+,d2
	beq.b	.Part_To_Patch_Found
	addq.w	#2,a0
	tst.w	(a0)
	bne.b	.Check_All_Table_Entries
	rts

.Part_To_Patch_Found
	move.w	(a0),d0
	lea	.Patch_Table(pc,d0.w),a0
	bra.w	Apply_Patches

.Patch_Table
	dc.w	$38,PL_PART1-.Patch_Table
	dc.w	$28,PL_PART2-.Patch_Table
	dc.w	$48,PL_PART3-.Patch_Table
	dc.w	0


; ---------------------------------------------------------------------------

PL_PART1
	PL_START
	PL_P	$568,Acknowledge_Level3_Interrupt
	PL_W	$1642,$1fe		; disable BPLCON3 access
	PL_W	$164e,$1fe		; disable FMODE access
	PL_PS	$436,.Fix_Blit
	PL_END

.Fix_Blit
	moveq	#0,d5
	move.w	$34000+$1614,d5
	rts


; ---------------------------------------------------------------------------

PL_PART2
	PL_START
	PL_SA	$0,$14			; skip AGA check
	PL_P	$572,Acknowledge_Level3_Interrupt
	PL_ORW	$6ae+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$73a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$7ce+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$7f2+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$88a+2,1<<9		; set Bplcon0 color bit
	PL_W	$6ba,$1fe		; disable BPLCON3 access
	PL_W	$6c6,$1fe		; disable FMODE access
	PL_W	$776,$1fe		; disable BPLCON3 access
	PL_W	$77a,$1fe		; disable DIWHIGH access
	PL_W	$77e,$1fe		; disable FMODE access
	PL_W	$7fe,$1fe		; disable FMODE access
	PL_W	$802,$1fe		; disable BPLCON3 access
	PL_W	$806,$1fe		; disable DIWHIGH access
	PL_W	$80a,$1fe		; disable FMODE access
	PL_END

; ---------------------------------------------------------------------------

PL_PART3
	PL_START
	PL_W	$12b0,$1fe		; disable BPLCON3 access
	PL_W	$12b4,$1fe		; disable FMODE access
	PL_W	$12f8,$1fe		; disable BPLCON3 access
	PL_W	$12fc,$1fe		; disable FMODE access
	PL_PSS	$1282,.Acknowledge_Level3_Interrupt,2
	PL_ORW	$72+2,INTF_PORTS	; enable level 2 interrupts
	PL_END

.Acknowledge_Level3_Interrupt
	move.w	#INTF_BLIT|INTF_VERTB|INTF_COPER,$dff09c
	move.w	#INTF_BLIT|INTF_VERTB|INTF_COPER,$dff09c
	rts

; ---------------------------------------------------------------------------

PL_TITLE_PICTURE
	PL_START
	PL_W	$6c,$1fe		; disable BPLCON3 access
	PL_W	$70,$1fe		; disable FMODE access
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


; ---------------------------------------------------------------------------

Acknowledge_Level3_Interrupt
	move.w	#INTF_BLIT|INTF_VERTB|INTF_COPER,$dff09c
	move.w	#INTF_BLIT|INTF_VERTB|INTF_COPER,$dff09c
	rte	


; ---------------------------------------------------------------------------

; d0.l: offset
; d1.l: size
; a0.l: destination

Disk_Load
	movem.l	d0-a6,-(a7)
	moveq	#1,d2
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

Enable_Keyboard_Interrupt
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,$dff09a
	rts


; Level 2 interrupt used to handle keyboard events.

Init_Level2_Interrupt
	pea	.int(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode


	move.w	#INTF_PORTS,$dff09c		; clear ports interrupt
	bra.w	Enable_Keyboard_Interrupt

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
	
	moveq	#3,d0
	bsr	Wait_Raster_Lines

	and.b	#~(1<<6),$e00(a1)		; set input mode
.end	move.w	#INTF_PORTS,$9c(a0)
	move.w	#INTF_PORTS,$9c(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte



Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine

; ---------------------------------------------------------------------------


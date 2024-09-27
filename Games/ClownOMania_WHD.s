***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       CLOWN-O-MANIA WHDLOAD SLAVE          )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             September 2024                              *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 26-Sep-2024	- cache flush added before executing the main code
;		- final version of the V2.0 update of the patch

; 25-Sep-2024	- NTSC version supported

; 24-Sep-2024	- Starbyte intro patched, game patched too 

; 23-Sep-2024	- work started, patch completely rewritten


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
	dc.l	$80000*2			; ws_BaseMemSize
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


.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Games/ClownOMania",0
	ENDC

.name	dc.b	"Clown-o-Mania",0
.copy	dc.b	"1989 Starbyte",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 2.0 (26.09.2024)",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)

; ---------------------------------------------------------------------------
; Determine version.	

	lea	.Tab(pc),a5
.Check_All_Entries
	movem.l	(a5)+,d0/d1/a0-a2
	bsr	Disk_Load
	move.l	d1,d0
	bsr	Checksum_Area
	cmp.w	a1,d0
	beq.b	.Supported_Version_Found

	tst.l	(a5)
	bpl.b	.Check_All_Entries

	; No supported version found, display error message and quit
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.Supported_Version_Found

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	jmp	.Tab(pc,a2.w)


.Tab	dc.l	0,512*11,$70000,$C6BB,Patch_Game_PAL-.Tab
	dc.l	0,512*11,$70000,$6FCB,Patch_Game_NTSC-.Tab
	dc.l	-1

; ---------------------------------------------------------------------------

Patch_Game_NTSC
	

Patch_Game_PAL
	bsr	Install_Exec_Emulation

	lea	$70000,a0
	move.l	a0,a4


	lea	PL_BOOT(pc),a0
	move.l	a4,a1
	bsr	Apply_Patches

	move.l	$4.w,a6
	lea	(IOSTD_LOCATION).w,a1	
	jmp	3*4(a4)




; ---------------------------------------------------------------------------

PL_BOOT	PL_START
	PL_SA	$14,$40		; skip video mode check and loading track 0
	PL_P	$c8,.Wait_TOF
	PL_PSS	$3d8,.Flush_Cache,2
	PL_END


; Game code has been copied from $10000 to $100.w, cache needs to be
; flushed before executing the code at $100.w
.Flush_Cache
	bsr	Flush_Cache
	pea	$100.w
	move.l	(a7)+,$80.w
	rts

.Wait_TOF
	bsr	WaitRaster
	jmp	$70000+$2dc

; ---------------------------------------------------------------------------

PL_STARBYTE_INTRO
	PL_START
	PL_ORW	$12aa0+2,1<<INTB_PORTS	; enable level 2 interrupts
	PL_P	$14974,Acknowledge_All_Level3_Interrupts
	PL_SA	$12a90,$12a98		; don't modify level 3 interrupt code
	PL_PSA	$12b56,Restore_Interrupts,$12b66
	PL_END

; Intro code sets INTENA to $e02c, which is incorrect
Restore_Interrupts
	pea	Acknowledge_All_Level3_Interrupts(pc)
	move.l	(a7)+,$6c.w
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,$dff09a
	rts


PL_STARBYTE_INTRO_NTSC
	PL_START
	PL_ORW	$f620+2,1<<INTB_PORTS	; enable level 2 interrupts
	PL_P	$10f02,Acknowledge_All_Level3_Interrupts
	PL_SA	$f610,$f618		; don't modify level 3 interrupt code
	PL_PSA	$f6d8,Restore_Interrupts,$f6e8
	PL_SA	$f6f8,$f714		; skip OS stuff (set system copperlist)
	PL_END


; ---------------------------------------------------------------------------

PL_GAME	PL_START
	PL_P	$753a,Load_Highscores
	PL_P	$74e2,Save_Highscores
	PL_P	$7058,.Load
	PL_PSS	$7012,Fix_Keyboard_Delay,2
	PL_P	$7952,Fix_DMA_Wait
	PL_P	$6e1a,Fix_DMA_Wait
	PL_P	$71d6,Acknowledge_Level2_Interrupt
	PL_END

.Load	lea	$100+$73da.w,a1
Load_Game_Data
	move.l	$76(a1),d0
	move.l	$7e(a1),d1
	move.l	$7a(a1),a0
	bsr	Disk_Load
	clr.l	$7e(a1)
	movem.l	(a7)+,d0-a6
	bra.w	Acknowledge_Level2_Interrupt

Fix_Keyboard_Delay
	moveq	#3,d0
	bsr	Wait_Raster_Lines
	move.b	$bfec01,d0
	ror.b	d0
	not.b	d0
	bra.w	Check_Quit_Key



PL_GAME_NTSC
	PL_START
	PL_P	$74fe,Load_Highscores
	PL_P	$74a6,Save_Highscores
	PL_P	$701c,.Load
	PL_PSS	$6fd6,Fix_Keyboard_Delay,2
	PL_P	$7916,Fix_DMA_Wait
	PL_P	$6dde,Fix_DMA_Wait
	PL_END

.Load	lea	$100+$739e.w,a1
	bra.b	Load_Game_Data


; ---------------------------------------------------------------------------

; a0.l: highscore data

Load_Highscores
	move.l	a0,a1
	lea	Highscore_Name(pc),a0
	bsr	File_Exists
	beq.b	.No_Highscores_Found
	bsr	Load_File
.No_Highscores_Found
	rts

; a0.l: highscore data

Save_Highscores
	move.l	a0,a1
	move.l	#HIGHSCORE_SIZE,d0
	lea	Highscore_Name(pc),a0
	bra.w	Save_File


HIGHSCORE_SIZE	= 284

Highscore_Name
	dc.b	"ClownOMania.high",0
	CNOP	0,2	

; ---------------------------------------------------------------------------
; Exec emulation code

EXEC_LOCATION	= $3000
OPCODE_JMP	= $4ef9

Install_Exec_Emulation
	lea	(EXEC_LOCATION).w,a0
	move.l	a0,$4.w

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
	dc.w	_LVOForbid,Do_Nothing-.TAB
	dc.w	_LVOPermit,Do_Nothing-.TAB
	dc.w	_LVOOldOpenLibrary,Do_Nothing-.TAB
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
	move.l	IO_DATA(a1),a0
	move.l	IO_LENGTH(a1),d0
	bsr	Checksum_Area

	lea	.Patch_Table(pc),a0
	move.l	IO_OFFSET(a1),d1
.Check_All_Table_Entries
	movem.l	(a0)+,d2/d3/d4
	
	cmp.l	d1,d2
	bne.b	.Check_Next_Entry
	cmp.l	d0,d3
	beq.b	.Part_To_Patch_Found

.Check_Next_Entry
	tst.l	(a0)
	bne.b	.Check_All_Table_Entries
	rts

.Part_To_Patch_Found
	lea	.Patch_Table(pc,d4.w),a0
	move.l	IO_DATA(a1),a1
	bra.w	Apply_Patches



; offset, checksum, patch table
.Patch_Table
	dc.l	$3f000,$A113,PL_STARBYTE_INTRO-.Patch_Table
	dc.l	$3f000,$7427,PL_STARBYTE_INTRO_NTSC-.Patch_Table
	dc.l	$89800,$3B75,PL_GAME-.Patch_Table
	dc.l	$89800,$5913,PL_GAME_NTSC-.Patch_Table
	dc.l	0


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
.wait1	btst	#0,_custom+vposr+1
	beq.b	.wait1
.wait2	btst	#0,_custom+vposr+1
	bne.b	.wait2
	rts


DMA_WAIT_DELAY	= 8

Fix_DMA_Wait
	moveq	#DMA_WAIT_DELAY,d0

; d0.w: number of raster lines to wait
Wait_Raster_Lines
	move.w	d1,-(a7)
.loop	move.b	_custom+vhposr,d1
.still_in_same_raster_line
	cmp.b	_custom+vhposr,d1
	beq.b	.still_in_same_raster_line	
	subq.w	#1,d0
	bne.b	.loop
	move.w	(a7)+,d1
	rts


Flush_Cache
	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts

; ---------------------------------------------------------------------------

Enable_Level2_Interrupt
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,_custom+intena
	rts

Acknowledge_Level2_Interrupt
	move.w	#INTF_PORTS,_custom+intreq
	move.w	#INTF_PORTS,_custom+intreq
	rte	

Acknowledge_All_Level3_Interrupts
	move.w	#INTF_BLIT|INTF_COPER|INTF_VERTB,_custom+intreq
	move.w	#INTF_BLIT|INTF_COPER|INTF_VERTB,_custom+intreq
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
; a1.l: data to save
; d0.l: size in bytes

Save_File
	movem.l	d1-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)
	movem.l	(a7)+,d1-a6
	rts

; a0.l: file name
; -----
; d0.l: result (0: file does not exist) 

File_Exists
	movem.l	d1-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	movem.l	(a7)+,d1-a6
	rts

; ---------------------------------------------------------------------------

; a0.l: pointer to start of memory area
; d0.l: size of memory area
; ----
; d0.w: CRC16 value
 
Checksum_Area
	movem.l	d1-a6,-(a7)
	move.l	resload(pc),a1
	jsr	resload_CRC16(a1)
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


	move.w	#INTF_PORTS,_custom+intreq	; clear ports interrupt
	bra.w	Enable_Level2_Interrupt

.int	movem.l	d0-d1/a0-a2,-(a7)
	lea	_custom,a0
	lea	_ciaa,a1

	btst	#INTB_PORTS,intreqr+1(a0)
	beq.b	.end

	btst	#CIAICRB_SP,ciaicr(a1)
	beq.b	.end

	lea	Key(pc),a2
	moveq	#0,d0
	move.b	ciasdr(a1),d0
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)+
	or.b	#CIACRAF_SPMODE,ciacra(a1)	; set output mode

	bsr.b	Check_Quit_Key

	move.l	(a2)+,d1
	beq.b	.no_keyboard_custom_routine
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.no_keyboard_custom_routine
	
	moveq	#3,d0
	bsr	Wait_Raster_Lines

	and.b	#~CIACRAF_SPMODE,ciacra(a1)	; set input mode
.end	move.w	#INTF_PORTS,intreq(a0)
	move.w	#INTF_PORTS,intreq(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte



Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine

; ---------------------------------------------------------------------------


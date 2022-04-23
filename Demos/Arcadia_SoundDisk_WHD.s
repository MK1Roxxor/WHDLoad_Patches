***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   ARCADIA TEAM SOUND DISK WHDLOAD SLAVE    )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              April 2022                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 23-Apr-2022	- OCS only DDFSTRT in scroller area fixed
;		- boot copperlist set after intro exits
;		- unused code removed

; 22-Apr-2022	- intro and main part patched

; 21-Apr-2022	- work started
;		- boot part patched, exec library emulation code created


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Hardware/dmabits.i
	INCLUDE	exec/exec_lib.i
	INCLUDE	exec/io.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

STACK_LOCATION	= $2000
IOSTD_LOCATION	= $2000
EXEC_LOCATION	= $5000
DEFAULT_DMA	= DMAF_COPPER|DMAF_BLITTER|DMAF_RASTER

	
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


.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/ArcadiaTeam/SoundDisk",0
	ENDC

.name	dc.b	"Sound Disk",0
.copy	dc.b	"1989 Arcadia Team",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.00 (23.04.2022)",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Relocate stack to low memory
	lea	(STACK_LOCATION).w,a0
	move.l	a0,a7
	sub.w	#1024,a0
	move.l	a0,USP


	; Load boot code
	lea	$1fa00,a0
	move.l	#$23c00,d0
	move.l	#$5800,d1
	moveq	#1,d2
	move.l	a0,a5
	move.l	d1,d5
	jsr	resload_DiskLoad(a2)

	; Version check
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$F18B,d0
	beq.b	.Version_is_supported
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
.Version_is_supported

	; Create partial exec library emulation
	lea	(EXEC_LOCATION).w,a6
	bsr	Create_Exec_Library

	; Patch boot code
	lea	PL_BOOT(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)


	bsr	Set_Default_Level3_Interrupt


	; Set IOStd pointer for trackdisk.device usage
	lea	(IOSTD_LOCATION).w,a0
	move.l	a0,$0.w

	; Run boot code
	jmp	(a5)
	

; ---------------------------------------------------------------------------
; Create exec library emulation.
;
; a6.l: pointer to end of free space for exec library

Create_Exec_Library
	movem.l	d0-a6,-(a7)
	move.l	a6,$4.w
	lea	Exec_Routines(pc),a2

.parse_all_entries
	movem.w	(a2)+,d0/d1
	lea	(a6,d0.w),a0
	lea	.Do_Nothing(pc),a1
	tst.w	d1
	beq.b	.Routine_not_needed
	lea	Exec_Routines(pc,d1.w),a1
	
.Routine_not_needed	
	move.w	#$4ef9,(a0)+
	move.l	a1,(a0)+

	tst.w	(a2)
	bne.b	.parse_all_entries
	movem.l	(a7)+,d0-a6

.Do_Nothing
	rts

Exec_Routines
	dc.w	_LVOForbid,0
	dc.w	_LVODoIO,DoIO_Emulation-Exec_Routines
	dc.w	_LVOOpenLibrary,OpenLibrary_Emulation-Exec_Routines
	dc.w	0

DoIO_Emulation
	movem.l	d0-a6,-(a7)
	cmp.w	#CMD_READ,IO_COMMAND(a1)
	bne.b	.exit
	move.l	IO_OFFSET(a1),d0
	move.l	IO_LENGTH(a1),d1
	move.l	IO_DATA(a1),a0
	moveq	#1,d2
	move.l	resload(pc),a1
	jsr	resload_DiskLoad(a1)
.exit	movem.l	(a7)+,d0-a6
	rts

OpenLibrary_Emulation
	moveq	#0,d0		; return error (library not opened)
	rts


; ---------------------------------------------------------------------------

PL_BOOT
	PL_START
	PL_SA	$30,$44		; skip InitBitMap and InitRastPort
	PL_P	$282,.Set_Copperlist
	PL_R	$2c0		; disable resident code
	PL_P	$6c,Set_Default_Copperlist
	PL_P	$16c,.Decrunch_And_Patch_Main
	PL_PS	$3c4,.Patch_Intro
	PL_END

.Patch_Intro
	lea	PL_INTRO(pc),a0
	lea	$30000,a1
	bsr	Apply_Patches
	jsr	$4b000
	bra.b	.Set_Copperlist

; a0.l: ByteKiller crunched data
; a1.l: destination

.Decrunch_And_Patch_Main
	move.l	a1,-(a7)
	bsr	ByteKiller_Decrunch
	lea	PL_MAIN(pc),a0
	move.l	(a7)+,a1
	bsr	Apply_Patches
	jmp	$7a000


.Set_Copperlist
	move.l	$1fa00+$a0,a1

.Set_Copperlist_And_DMA
	bsr.b	Set_Copperlist
	bra.w	Set_Default_DMA

Set_Copperlist
	move.w	#DMAF_COPPER,$dff096
	move.l	a1,$dff080
	rts

Fix_Volume_Register_Write
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts


; ---------------------------------------------------------------------------

PL_INTRO
	PL_START
	PL_P	$1b31e,.Set_Copperlist
	PL_P	$1b0b4,Set_Default_Copperlist
	PL_PSS	$1b17c,.Wait_Blit,4
	PL_END

.Wait_Blit
	bsr	Wait_Blit
	move.l	$30000+$1b1b2,$dff050
	rts

.Set_Copperlist
	move.l	$30000+$1b0e2,a1
	bsr	Set_Copperlist
	bra.w	Set_Default_DMA

; ---------------------------------------------------------------------------

PL_MAIN	PL_START
	PL_P	$4acaa,.Set_Copperlist
	PL_PSS	$4b19c,Fix_DMA_Wait,2
	PL_P	$4b374,Fix_Volume_Register_Write
	PL_SA	$4a0aa,$4a0b4		; don't modify level 3 interrupt code
	PL_SA	$4aa04,$4aa0e		; don't modify level 3 interrupt code
	PL_P	$4b5b4,Acknowledge_Level3_Interrupt
	PL_ORW	$4a0be+2,1<<3|1<<5	; enable level 2 + 3 interrupts
	PL_ORW	$4aa18+2,1<<3|1<<5	; enable level 2 + 3 interrupts
	PL_P	$4aace,ByteKiller_Decrunch
	PL_P	$4a142,Set_Default_Copperlist
	PL_PSS	$4a61c,.Fix_Access_Fault,2
	PL_PS	$4a116,.Wait_Blit
	PL_PS	$4b688,.Wait_Blit_Clr_Dff064
	PL_PSS	$4b6a4,.Wait_Blit2,4
	PL_PSS	$4b608,.Wait_Blit_7_Dff050,2
	PL_PS	$4b656,.Wait_Blit_D3_Dff052
	PL_PSS	$4a73c,.Wait_Blit3,4

	PL_AW	$4adbe+2,-2		; fix OCS only DDFSTRT
	PL_END

.Fix_Access_Fault
	cmp.l	#$80000,a0
	bcc.b	.invalid_memory_location
	move.b	(a0),d3
	move.w	$30000+$4a380,d4
	
.invalid_memory_location
	rts

.Wait_Blit
	bsr	Wait_Blit
	tst.b	$30000+$4a17a
	rts

.Wait_Blit2
	bsr	Wait_Blit
	move.l	$30000+$4b6e8,$dff050
	rts

.Wait_Blit3
	bsr	Wait_Blit
	move.l	$30000+$4a6ac,$dff054
	rts

.Wait_Blit_Clr_Dff064
	bsr	Wait_Blit
	move.l	#0,$dff064
	rts

.Wait_Blit_7_Dff050
	bsr	Wait_Blit
	move.w	#$07,$dff050
	rts

.Wait_Blit_D3_Dff052
	bsr	Wait_Blit
	move.w	d3,$dff052
	rts

.Set_Copperlist
	move.l	$30000+$4a2ec,a1
	bsr	Set_Copperlist

Set_Default_DMA
	move.w	#DMAF_SETCLR|DMAF_MASTER|DEFAULT_DMA,$dff096
	rts


Set_Default_Copperlist
	lea	$1000.w,a0
	move.l	#$01000200,(a0)
	move.l	#$fffffffe,4(a0)
	move.l	a0,$dff080
	rts


Set_Default_Level3_Interrupt
	pea	Acknowledge_Level3_Interrupt(pc)
	move.l	(a7)+,$6c.w
	rts

Acknowledge_Level3_Interrupt
	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte	


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


Wait_Blit
	tst.b	$dff002
.wait_blit
	btst	#6,$dff002
	bne.b	.wait_blit
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



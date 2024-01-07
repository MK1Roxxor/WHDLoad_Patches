***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(     MUSIC DISK II/ELITE INC. WHDLOAD SLAVE )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             January 2024                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 07-Jan-2024	- PowerPackeer decruncher relocated to fast memory
;		- Checksum checks for song files added as there are
;		  broken images of this music disk

; 06-Jan-2024	- work started


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
	dc.b	"SOURCES:WHD_Slaves/Demos/EliteInc",0
	ENDC

.name	dc.b	"Music Disk II",0
.copy	dc.b	"1990 Elite Inc.",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.00 (07.01.2024)",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load main code
	move.l	#$400,d0
	move.l	#$f200,d1
	lea	$4800.w,a0
	bsr	Disk_Load

	move.l	a0,a5
	
	; Version check
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$4ce1,d0
	beq.b	.Version_is_Supported

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
.Version_is_Supported


	; Patch main code
	lea	PL_MAIN(pc),a0
	move.l	a5,a1
	sub.w	#$3c2,a1
	bsr	Apply_Patches

	; Run demo
	lea	_custom,a6
	jmp	(a5)


; ---------------------------------------------------------------------------

SECTOR_SIZE		= 512
SECTORS_PER_TRACK	= 11
TRACK_SIZE		= SECTOR_SIZE*SECTORS_PER_TRACK

PL_MAIN	PL_START
	PL_R	$7ee			; disable resident code
	PL_R	$ad2			; disable drive access (motor off)
	PL_P	$a6a,.Step_To_Track
	PL_P	$966,.Loader
	PL_PS	$7d8,.Acknowledge_Vertical_Blank_Interrupt
	PL_ORW	$5a8+2,INTF_PORTS	; enable level 2 interrupts
	PL_ORW	$9db2+2,1<<9		; set Bplcon0 color bit
	PL_P	$b70,Decrunch_PowerPacker
	PL_END

.Step_To_Track
	move.w	d0,d2
	rts

.Loader	move.w	d0,d1
	move.w	d2,d0
	mulu.w	#TRACK_SIZE,d0
	mulu.w	#TRACK_SIZE,d1
	bsr	Disk_Load

	movem.l	d0-a6,-(a7)
	move.l	d1,d0
	move.l	resload(pc),a1
	jsr	resload_CRC16(a1)

	move.w	($4800-$3c2)+$141e.w,d1	; song numer
	lsr.w	#4,d1
	add.w	d1,d1
	cmp.w	.Checksums(pc,d1.w),d0
	beq.b	.File_is_OK

	pea	.Error_Text(pc)
	pea	(TDREASON_FAILMSG).w
	bra.w	EXIT

.File_is_OK
	movem.l	(a7)+,d0-a6
	rts

.Error_Text
	dc.b	"File is corrupt!",0
	cnop	0,4
	
.Checksums
	dc.w	$9043
	dc.w	$C24D
	dc.w	$59ED
	dc.w	$C5C9
	dc.w	$F265
	dc.w	$9FAB
	dc.w	$0F68
	dc.w	$781D
	dc.w	$6476
	dc.w	$400E


.Acknowledge_Vertical_Blank_Interrupt
	move.w	#INTF_VERTB,intreq(a6)
	move.w	#INTF_VERTB,intreq(a6)
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
.wait1	btst	#0,_custom+vposr+1
	beq.b	.wait1
.wait2	btst	#0,_custom+vposr+1
	bne.b	.wait2
	rts



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
;
; d0.b: rawkey code

Check_Quit_Key
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	rts	


Enable_Keyboard_Interrupt
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,_custom+intena
	rts



; Level 2 interrupt used to handle keyboard events.

Init_Level2_Interrupt
	pea	.int(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode


	move.w	#INTF_PORTS,_custom+intreq	; clear ports interrupt
	bra.w	Enable_Keyboard_Interrupt

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

; d0.l: size of crunched data
; a0.l: start of crunched data (directly after PP20 header)

Decrunch_PowerPacker
	move.l	a0,a5
	lea	$200(a0),a1
	move.l	a1,a2
	add.l	d0,a0
	move.l	-(a0),d5
	moveq	#0,d1
	move.b	d5,d1
	lsr.l	#8,d5
	add.l	d5,a1
	move.l	-(a0),d5
	lsr.l	d1,d5
	move.b	#$20,d7
	sub.b	d1,d7
lbC000B8E
	bsr.b	lbC000BF8
	tst.b	d1
	bne.b	lbC000BB4
	moveq	#0,d2
lbC000B96
	moveq	#2,d0
	bsr.b	lbC000BFA
	add.w	d1,d2
	cmp.w	#3,d1
	beq.b	lbC000B96
lbC000BA2
	move.w	#8,d0
	bsr.b	lbC000BFA
	move.b	d1,-(a1)
	dbf	d2,lbC000BA2
	cmp.l	a1,a2
	bcs.b	lbC000BB4
	rts

lbC000BB4
	moveq	#2,d0
	bsr.b	lbC000BFA
	moveq	#0,d0
	move.b	(a5,d1.w),d0
	move.l	d0,d4
	move.w	d1,d2
	addq.w	#1,d2
	cmp.w	#4,d2
	bne.b	lbC000BE6
	bsr.b	lbC000BF8
	move.l	d4,d0
	tst.b	d1
	bne.b	lbC000BD4
	moveq	#7,d0
lbC000BD4
	bsr.b	lbC000BFA
	move.w	d1,d3
lbC000BD8
	moveq	#3,d0
	bsr.b	lbC000BFA
	add.w	d1,d2
	cmp.w	#7,d1
	beq.b	lbC000BD8
	bra.b	lbC000BEA

lbC000BE6
	bsr.b	lbC000BFA
	move.w	d1,d3
lbC000BEA
	move.b	(a1,d3.w),-(a1)
	dbf	d2,lbC000BEA
	cmp.l	a1,a2
	bcs.b	lbC000B8E
	rts

lbC000BF8
	moveq	#1,d0
lbC000BFA
	moveq	#0,d1
	subq.w	#1,d0
lbC000BFE
	lsr.l	#1,d5
	addx.l	d1,d1
	subq.b	#1,d7
	bne.b	lbC000C0C
	move.b	#$20,d7
	move.l	-(a0),d5
lbC000C0C
	dbf	d0,lbC000BFE
	rts


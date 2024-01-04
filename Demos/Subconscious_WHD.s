***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(  SUBCONSCIOUS/DIMENSION X WHDLOAD SLAVE    )*)---.---.   *
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

; 04-Jan-2024	- main part and end part patched
;		- delay for title part added
;		- intro can be skipped with CUSTOM1

; 03-Jan-2024	- work started
;		- title and intro part patched


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
	dc.l	$80000			; ws_BaseMemSize
	dc.l	0			; ws_ExecInstall
	dc.w	Patch-HEADER		; ws_GameLoader
	dc.w	.dir-HEADER		; ws_CurrentDir
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


.config	dc.b	"C1:B:Skip Intro"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Subconscious/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Subconscious",0
.copy	dc.b	"1991 Dimension X",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.00 (04.01.2024)",0

File_Name
	dc.b	"3",0,0

	CNOP	0,4



resload	dc.l	0


TITLE_LOCATION	= $78000
INTRO_LOCATION	= $20000
MAIN_LOCATION	= $20000
END_LOCATION	= $7a000

SECONDS		= 10
TITLE_DELAY	= 6*SECONDS

OPCODE_NOP	= $4e71

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load Title binary
	lea	File_Name(pc),a0
	lea	TITLE_LOCATION,a1
	bsr	Load_File

	move.l	a1,a5

	; Version check
	move.l	a1,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$056c,d0
	beq.b	.Version_is_Supported

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
.Version_is_Supported



	; Run title code
	jsr	(a5)
	moveq	#TITLE_DELAY,d0
	move.l	resload(pc),a0
	jsr	resload_Delay(a0)

	; Set default level 3 interrupt
	pea	Acknowledge_Level3_Interrupt(pc)
	move.l	(a7)+,$6c.w
	

	clr.l	-(a7)		; TAG_DONE
	clr.l	-(a7)		; data
	pea	WHDLTAG_CUSTOM1_GET
	move.l	a7,a0
	move.l	resload(pc),a1
	jsr	resload_Control(a1)
	tst.l	1*4(a7)
	add.w	#3*4,a7
	bne.b	.Skip_Intro

	; Load intro code
	lea	File_Name(pc),a0
	move.b	#"1",(a0)
	lea	INTRO_LOCATION,a1
	bsr	Load_File

	; Patch intro code
	lea	PL_INTRO(pc),a0
	bsr	Apply_Patches

	; Run intro code
	jsr	(a1)

.Skip_Intro

	; Load main part
	lea	File_Name(pc),a0
	move.b	#"2",(a0)
	lea	MAIN_LOCATION,a1
	bsr	Load_File

	; Patch main part
	lea	PL_MAIN(pc),a0
	bsr	Apply_Patches

	lea	$1000.w,a0
	move.l	a0,_custom+cop1lc

	; Run main part
	jsr	(a1)


	; Load end part
	lea	File_Name(pc),a0
	move.b	#"R",(a0)
	move.b	#"I",1(a0)
	lea	END_LOCATION,a1
	bsr	Load_File

	; Decrunch
	move.w	#OPCODE_NOP,$72(a1)	; disable pea (a1)
	bsr	Flush_Cache
	jsr	$66(a1)

	; Patch end part
	lea	PL_END_PART(pc),a0
	lea	$40000,a1
	bsr	Apply_Patches

	; Run end part
	jmp	(a1)



; ---------------------------------------------------------------------------

PL_INTRO
	PL_START
	PL_SA	$226,$23c		; skip OS stuff
	PL_SA	$27a,$282		; don't disable CIA interrupts
	PL_SA	$26e,$282		; don't write to read only registers
	PL_W	$189a,$1fe		: Bplcon3 -> NOP
	PL_W	$19b6,$1fe		: Bplcon3 -> NOP
	PL_ORW	$28e+2,DMAF_SPRITE	; enable sprite DMA

	; fix CPU dependent DMA waits in replayer
	PL_PSS	$224c,Fix_DMA_Wait,2
	PL_PSS	$2262,Fix_DMA_Wait,2
	PL_PSS	$298a,Fix_DMA_Wait,2
	PL_PSS	$29a0,Fix_DMA_Wait,2
	
	PL_SA	$12,$1a			; don't modify level 3 interrupt code
	PL_P	$2ae,Acknowledge_Level3_Interrupt
	PL_SA	$212,$218		; don't restore modified interrupt code
	PL_SA	$43c,$446		; don't restore system copperlist
	PL_SA	$468,$480		; skip OS stuff

	PL_P	$28a,.Enable_Level3_Interrupt
	PL_END

.Enable_Level3_Interrupt
	move.w	#$87c0,dmacon(a6)
	move.w	#$c028,intena(a6)
	rts



; ---------------------------------------------------------------------------

PL_MAIN	PL_START
	PL_SA	$74,$94			; skip OS stuff
	PL_P	$16be4,Load_File

	; fix CPU dependent DMA waits in replayer
	PL_PSS	$6be8,Fix_DMA_Wait,2
	PL_PSS	$6bfe,Fix_DMA_Wait,2
	PL_PSS	$7328,Fix_DMA_Wait,2
	PL_PSS	$733e,Fix_DMA_Wait,2

	PL_SA	$138,$140		; don't modify level 3 interrupt code
	PL_P	$33c,Acknowledge_Level3_Interrupt
	PL_SA	$2a2,$2aa		; don't restore modified interrupt code
	PL_SA	$2ca,$2d4		; don't restore system copperlist
	PL_SA	$2f6,$310		; skip OS stuff
	PL_END


; ---------------------------------------------------------------------------

PL_END_PART
	PL_START
	;PL_SA	$7c,$90			; skip OS stuff
	;PL_SA	$9a,$a2			; don't write to read only registers
	PL_R	$7c

	; fix CPU dependent DMA waits in replayer
	PL_PSS	$214e,Fix_DMA_Wait,2
	PL_PSS	$2164,Fix_DMA_Wait,2
	PL_PSS	$288c,Fix_DMA_Wait,2
	PL_PSS	$28a2,Fix_DMA_Wait,2

	PL_SA	$6,$e			; don't modify level 3 interrupt code
	PL_P	$76,Acknowledge_Level3_Interrupt
	PL_ORW	$1c4+2,INTF_PORTS	; enable level 2 interrupts
	
	PL_END


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


Fix_DMA_Wait
	moveq	#8,d0

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

Acknowledge_Level3_Interrupt
	move.w	#INTF_BLIT|INTF_COPER|INTF_VERTB,_custom+intreq
	move.w	#INTF_BLIT|INTF_COPER|INTF_VERTB,_custom+intreq
	rte

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


; ---------------------------------------------------------------------------

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


***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*( ALL WEE NEED IS MUSIC 5/CPS WHDLOAD SLAVE  )*)---.---.   *
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

; 22-Feb-2023	- work started
;		- and finished about 90 minutes later, interrupts
;		  fixed, blitter waits added (x5), Bplcon0 color bit
;		  fixes (x5), DMA wait in replayer fixed (x2), all
;		  Power Packer decrunchers relocated, CopyMemQuick
;		  trashing disabled, delay for second title picture
;		  added


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	hardware/intbits.i


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
	dc.b	"SOURCES:WHD_Slaves/Demos/CyborgPowerSystems/AllWeNeedIsMusic5",0
	ENDC

.name	dc.b	"All we need is Music 5",0
.copy	dc.b	"1990 Cyborg Power Systems",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.00 (22.02.2023)",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load boot code
	moveq	#0,d0
	move.l	#$400+$600,d1
	lea	$78000-$19c,a0
	bsr	Disk_Load

	move.l	a0,a5

	; Version check
	move.l	a5,a0
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$71c5,d0
	beq.b	.Version_is_Supported

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.Version_is_Supported

	; Patch boot code
	lea	PL_BOOT(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; And run the demo
	jmp	$19c(a5)
	

; ---------------------------------------------------------------------------

PL_BOOT	PL_START
	PL_R	$528		; disable drive access (motor on)
	PL_R	$54a		: disable drive access (motor off)
	PL_P	$290,Fake_Loader_Init
	PL_R	$2f6		; disable drive access (drive ready wait)
	PL_P	$344,Load_Tracks
	PL_P	$274,.Patch_Title_Part
	PL_END


.Patch_Title_Part
	pea	$40000
	move.l	(a7),a1
	lea	PL_TITLE(pc),a0
	bra.w	Apply_Patches


; ---------------------------------------------------------------------------

PL_TITLE
	PL_START
	PL_R	$540		; disable drive access (motor on)
	PL_R	$562		; disable drive access (motor off)
	PL_SA	$27e,$2a0	; don't clear CopyMemQuick
	PL_P	$2f6,Fake_Loader_Init
	PL_P	$35c,Load_Tracks
	PL_P	$2f0,.Patch_Main_Part
	PL_ORW	$8c8+2,1<<9	; set Bplcon0 color bit
	PL_P	$46,PowerPacker_Decrunch
	PL_PS	$2e6,.Title_Picture_Delay
	PL_END


.Title_Picture_Delay
	moveq	#5*10,d0
	move.l	resload(pc),a0
	jsr	resload_Delay(a0)
	lea	$40000+$7c4,a0
	rts

.Patch_Main_Part
	pea	$c0.w
	move.l	(a7),a1
	lea	PL_MAIN(pc),a0
	bra.w	Apply_Patches


; ---------------------------------------------------------------------------

PL_MAIN	PL_START
	PL_PSS	$10e2,Fix_DMA_Wait,2
	PL_PSS	$10fa,Fix_DMA_Wait,2
	PL_PSS	$214,.Acknowledge_Other_Level3_Interrupts,2
	PL_PSS	$26c,.Acknowledge_Level3_Interrupt,2
	PL_ORW	$2e+2,INTF_PORTS	; enable level 2 interrupts
	PL_R	$dc8		; disable drive access (motor on)
	PL_R	$dea		: disable drive access (motor off)
	PL_P	$b66,Fake_Loader_Init
	PL_P	$bcc,Load_Tracks
	PL_ORW	$5aaa+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$5b4e+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$5bf2+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$5c0e+2,1<<9	; set Bplcon0 color bit
	PL_P	$d2,PowerPacker_Decrunch

	PL_PS	$50a,.Wait_Blit_d3_dff050
	PL_PS	$9f4,.Wait_Blit_d1_dff054
	PL_PS	$b0c,.Wait_Blit_a0_dff050
	PL_PSS	$3d8,.Wait_Blit_09f0000_dff040,4
	PL_PSS	$3f6,.Wait_Blit_09f0002_dff040,4
	PL_END


.Wait_Blit_d3_dff050
	bsr	Wait_Blit
	move.l	d3,$dff050
	rts

.Wait_Blit_a0_dff050
	bsr	Wait_Blit
	move.l	a0,$dff050
	rts

.Wait_Blit_d1_dff054
	bsr	Wait_Blit
	move.l	d1,$dff054
	rts

.Wait_Blit_09f0000_dff040
	bsr	Wait_Blit
	move.l	#$09f00000,$dff040
	rts

.Wait_Blit_09f0002_dff040
	bsr	Wait_Blit
	move.l	#$09f00002,$dff040
	rts



.Acknowledge_Other_Level3_Interrupts
	move.w	#INTF_COPER|INTF_BLIT,$dff09c
	move.w	#INTF_COPER|INTF_BLIT,$dff09c
	rts	

.Acknowledge_Level3_Interrupt
	move.w	#INTF_VERTB,$dff09c
	move.w	#INTF_VERTB,$dff09c
	rts	


Fake_Loader_Init
	moveq	#1,d0		; return success
	rts

; a1.l: destination
; a2.l: pointer to track table
Load_Tracks
	move.w	(a2)+,d0

.find_end_track
	tst.w	(a2)+
	bpl.b	.find_end_track
	move.w	-2*2(a2),d1
	addq.w	#1,d1
	sub.w	d0,d1
	mulu.w	#512*11,d0
	mulu.w	#512*11,d1
	move.l	a1,a0
	bra.w	Disk_Load



Fix_Volume_Write
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
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

Wait_Blit
	tst.b	$dff002
.wait_blit
	btst	#6,$dff002
	bne.b	.wait_blit
	rts
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

PowerPacker_Decrunch
	lea	(lbL0000E8,pc),a5
	move.l	d0,(a5)
	move.l	a1,a2
	move.l	-(a0),d5
	moveq	#0,d1
	move.b	d5,d1
	lsr.l	#8,d5
	add.l	d5,a1
	move.l	-(a0),d5
	lsr.l	d1,d5
	move.b	#$20,d7
	sub.b	d1,d7
lbC000062
	bsr.b	lbC0000CE
	tst.b	d1
	bne.b	lbC000088
	moveq	#0,d2
lbC00006A
	moveq	#2,d0
	bsr.b	lbC0000D0
	add.w	d1,d2
	cmp.w	#3,d1
	beq.b	lbC00006A
lbC000076
	move.w	#8,d0
	bsr.b	lbC0000D0
	move.b	d1,-(a1)
	dbf	d2,lbC000076
	cmp.l	a1,a2
	bcs.b	lbC000088
	rts

lbC000088
	moveq	#2,d0
	bsr.b	lbC0000D0
	moveq	#0,d0
	move.b	(a5,d1.w),d0
	move.l	d0,d4
	move.w	d1,d2
	addq.w	#1,d2
	cmp.w	#4,d2
	bne.b	lbC0000BA
	bsr.b	lbC0000CE
	move.l	d4,d0
	tst.b	d1
	bne.b	lbC0000A8
	moveq	#7,d0
lbC0000A8
	bsr.b	lbC0000D0
	move.w	d1,d3
lbC0000AC
	moveq	#3,d0
	bsr.b	lbC0000D0
	add.w	d1,d2
	cmp.w	#7,d1
	beq.b	lbC0000AC
	bra.b	lbC0000BE

lbC0000BA
	bsr.b	lbC0000D0
	move.w	d1,d3
lbC0000BE
	move.b	(a1,d3.w),d0
	move.b	d0,-(a1)
	dbf	d2,lbC0000BE
	cmp.l	a1,a2
	bcs.b	lbC000062
	rts

lbC0000CE
	moveq	#1,d0
lbC0000D0
	moveq	#0,d1
	subq.w	#1,d0
lbC0000D4
	lsr.l	#1,d5
	roxl.l	#1,d1
	subq.b	#1,d7
	bne.b	lbC0000E2
	move.b	#$20,d7
	move.l	-(a0),d5
lbC0000E2
	dbf	d0,lbC0000D4
	rts

lbL0000E8
	DC.L	$90A0B0B


***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(          CARNAGE WHDLOAD SLAVE             )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              May 2022                                   *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************


; 29-May-2022	- work started
;		- and finished a while later, all OS stuff patched,
;		  DMA wait in replayer fixed (x4), CIA interrupt recoded,
;		  keyboard routine fixed, access faults fixed (x3),
;		  blitter waits added (x2), resident code removed, interrupt
;		  fixed


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
DEBUG

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
	dc.b	"SOURCES:WHD_Slaves/Games/Carnage",0
	ENDC

.name	dc.b	"Carnage",0
.copy	dc.b	"1992 Zeppelin Games",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 2.0 (29.05.2022)",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load intro code
	move.l	#$20000,a0
	move.l	#$400,d0
	move.l	#$2cc00,d1
	bsr	Disk_Load
	
	move.l	a0,a5

	; Version check
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$D825,d0
	beq.b	.Version_is_supported
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.Version_is_supported

	; Patch intro code
	lea	PL_INTRO(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; Start the game
	jmp	(a5)


; ---------------------------------------------------------------------------

PL_INTRO
	PL_START
	PL_SA	$0,$28			; skip OS stuff
	PL_P	$e2b8,.Install_Replayer_Level6_Interrupt
	PL_P	$e39a,.Remove_Replayer_Level6_Interrupt
	PL_SA	$e3d4,$e3dc		; skip CIA resource check in mt_SetTempo
	PL_PSS	$e74a,Fix_DMA_Wait,2
	PL_PSS	$e760,Fix_DMA_Wait,2
	PL_PSS	$ee94,Fix_DMA_Wait,2
	PL_PSS	$eeaa,Fix_DMA_Wait,2
	PL_SA	$a2,$a8			; don't disable all interrupts

	PL_P	$26a,.Load_Game
	PL_END

.Load_Game
	move.l	#$16000,a0
	move.l	#$2d000,d0
	move.l	#$1f400,d1
	bsr	Disk_Load

	move.l	a0,a1
	lea	PL_GAME(pc),a0
	bsr	Apply_Patches
	jmp	(a1)


.Install_Replayer_Level6_Interrupt
	lea	$dff000,a6
	lea	$bfd000,a0

	move.w	#$2000,d0
	move.w	d0,$9a(a6)
	move.w	d0,$9c(a6)
	
	move.b	#$7f,$d00(a0)
	move.b	#$10,$e00(a0)
	move.b	#$10,$f00(a0)
	move.b	#$82,$d00(a0)

	move.l	#1773447,d0 		; PAL
	move.l	d0,$20000+$e42e

	divu.w	#125,d0
	move.b	d0,$400(a0)
	lsr.w	#8,d0
	move.b	d0,$500(a0)
	

	pea	.Level6_Interrupt(pc)
	move.l	(a7)+,$78.w

	move.b	#$83,$d00(a0)
	move.b	#$11,$e00(a0)
	move	#$e000,$9a(a6)
	rts	


.Level6_Interrupt
	movem.l	d0-a6,-(a7)

	tst.b	$bfdd00
	jsr	$20000+$e508

	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c

	movem.l	(a7)+,d0-a6
	rte
	

.Remove_Replayer_Level6_Interrupt
	move.w	#1<<13,$dff09a
	pea	Acknowledge_Level6_Interrupt(pc)
	move.l	(a7)+,$78.w
	rts

Fix_DMA_Wait
	moveq	#5,d0
	bra.w	Wait_Raster_Lines

; ---------------------------------------------------------------------------

PL_GAME	PL_START
	PL_SA	$0,$8			; skip Forbid()
	PL_PSS	$7a,.Initialise_Keyboard,2
	PL_P	$4a6,Acknowledge_Level3_Interrupt
	PL_P	$416,.Load_Data
	PL_PS	$fde,.Fix_Memory_Access
	PL_PS	$fea,.Fix_Memory_Access2
	PL_PS	$ff6,.Fix_Memory_Access3
	PL_PS	$1f3e,.Wait_Blit
	PL_PS	$130a,.Wait_Blit2
	PL_END

.Fix_Memory_Access
	add.w	#40*256,a0
	clr.w	d4
	cmp.l	#$80000,a0
	bhs.b	.clip
	move.w	(a0),d4
	sub.w	#40*256,a0
	and.w	d0,d4
.clip	rts

	
.Fix_Memory_Access2
	add.w	#40*256*2,a0
	clr.w	d4
	cmp.l	#$80000,a0
	bhs.b	.clip2
	move.w	(a0),d4
	sub.w	#40*256*2,a0
	and.w	d0,d4
.clip2	rts

.Fix_Memory_Access3
	add.w	#40*256*3,a0
	clr.w	d4
	cmp.l	#$80000,a0
	bhs.b	.clip3
	move.w	(a0),d4
	sub.w	#40*256*3,a0
	and.w	d0,d4
.clip3	rts

.Load_Data
	move.l	$7faf8,a0
	move.l	$7faf4,d0
	move.l	$7fafc,d1
	bra.w	Disk_Load
	

.Wait_Blit
	bsr	Wait_Blit
	addq.w	#1,$16000+$2064
	rts

.Wait_Blit2
	move.w	d0,d2
	lsl.w	#6,d0
	lsl.w	#6,d0
	bra.w	Wait_Blit
	

.Initialise_Keyboard
	lea	.Keyboard_Custom_Routine(pc),a0
	move.l	a0,KbdCust-.Keyboard_Custom_Routine(a0)
	rts

.Keyboard_Custom_Routine
	move.b	Key(pc),$16000+$748
	jmp	$16000+$74a



Acknowledge_Level3_Interrupt
	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte

Acknowledge_Level6_Interrupt
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
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


Wait_Blit
	tst.b	$dff002
.blitter_still_busy
	btst	#6,$dff002
	bne.b	.blitter_still_busy
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

; d0.l: offset (bytes)
; d1.l: length (bytes)
; a0.l: destination

Disk_Load
	movem.l	d0-a6,-(a7)
	moveq	#1,d2
	move.l	resload(pc),a1
	jsr	resload_DiskLoad(a1)
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


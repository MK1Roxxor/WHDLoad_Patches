***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      SHARKEY'S MOLL WHDLOAD SLAVE          )*)---.---.   *
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
;		- and finished a while later, protection removed, trainer
;		  options added, CPU dependent delay loops fixed, keyboard
;		  interrupt added and code adapted to use it


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $46		; Del
;DEBUG

; Trainer options
TRB_UNLIMITED_AMMO	= 0
TRB_UNLIMITED_LIVES	= 1
TRB_UNLIMITED_ENERGY	= 2
TRB_UNLIMITED_MOLOTOV	= 3

	
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


.config	dc.b	"BW;"
	dc.b	"C1:X:Unlimited Ammo:",TRB_UNLIMITED_AMMO+"0",";"
	dc.b	"C1:X:Unlimited Molotov Cocktails:",TRB_UNLIMITED_MOLOTOV+"0",";"
	dc.b	"C1:X:Unlimited Lives:",TRB_UNLIMITED_LIVES+"0",";"
	dc.b	"C1:X:Unlimited Energy:",TRB_UNLIMITED_ENERGY+"0",";"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Games/SharkeysMoll",0
	ENDC

.name	dc.b	"Sharkey's Moll",0
.copy	dc.b	"1991 Zeppelin Games",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.3 (29.05.2022)",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load boot code
	lea	$66000-$4a,a0
	move.l	#$6c200,d0
	move.l	#$e00,d1
	bsr	Disk_Load

	move.l	a0,a5

	; Version check
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$644E,d0		; SPS 2133
	beq.b	.Version_is_supported
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.Version_is_supported

	; Patch boot code
	lea	PL_BOOT(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; Start the game
	jmp	(a5)


; ---------------------------------------------------------------------------

PL_BOOT	PL_START
	PL_SA	$0,$4a			; skip copying code to $66000
	PL_SA	$50,$5e			; skip delay
	PL_P	$476,.Load_Data
	PL_PS	$382,.Patch_Game

	; Button wait for title picture
	PL_IFBW
	PL_PS	$318,.Show_Title_Picture
	PL_ENDIF
	PL_END

.Load_Data
	move.w	d1,d0
	move.w	d2,d1
	mulu.w	#512,d0
	mulu.w	#512,d1
	bsr	Disk_Load
	moveq	#0,d0			; no errors
	rts


.Patch_Game
	lea	PL_GAME(pc),a0
	lea	$5f800,a1
	bsr	Apply_Patches
	move.l	a1,a0
	rts


.Show_Title_Picture
	moveq	#5*10,d0		; show picture for 5 seconds
	move.l	resload(pc),a2
	jsr	resload_Delay(a2)
	lea	$dff000,a6
	rts


; ---------------------------------------------------------------------------

PL_GAME	PL_START
	PL_R	$53e6			; disable Copylock
	PL_PS	$25c0,.Get_Key
	PL_PS	$25fe,.Get_Key
	PL_PS	$2638,.Get_Key
	PL_PSS	$39ee,Acknowledge_Level3_Interrupt,2
	PL_PSS	$5c0,.Delay_D0,2
	PL_PSS	$5d2,.Delay_D0,2
	PL_PSS	$210,.Delay_D0,2
	PL_PSS	$29c,.Delay_D0,2
	PL_PSS	$54a,.Delay_D0,2
	PL_PSS	$184a,.Delay_D0,2
	PL_PSS	$1b92,.Delay_D0,2
	PL_PSS	$1bb0,.Delay_D0,2
	PL_PSS	$1c1c,.Delay_D0,2


	PL_IFC1X	TRB_UNLIMITED_AMMO
	PL_W	$374c,$4e71
	PL_ENDIF

	PL_IFC1X	TRB_UNLIMITED_LIVES
	PL_W	$374c,$4e71
	PL_ENDIF

	PL_IFC1X	TRB_UNLIMITED_ENERGY
	PL_W	$2ea4+2,0
	PL_W	$2eba+2,0
	PL_W	$2ed0+2,0
	PL_W	$2ee6+2,0
	PL_W	$308e+2,0
	PL_W	$3096,$6004
	PL_W	$30a6+2,0
	PL_W	$30ae,$6004
	PL_W	$30be+2,0
	PL_W	$30c6,$6004
	PL_W	$31f2+2,0
	PL_W	$3204+2,0
	PL_W	$3216+2,0
	PL_W	$3350+2,0
	PL_W	$3362+2,0
	PL_W	$3374+2,0
	PL_W	$3f76+2,0
	PL_W	$40e8+2,0
	PL_W	$4c20+2,0
	PL_W	$4c34+2,0
	PL_ENDIF

	PL_IFC1X	TRB_UNLIMITED_MOLOTOV
	PL_B	$3692,$4a
	PL_ENDIF

	PL_END

.Get_Key
	move.b	Key(pc),d0
	rts

.Delay_D0
	divu.w	#34,d0
	bra.w	Wait_Raster_Lines


Acknowledge_Level3_Interrupt
	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
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


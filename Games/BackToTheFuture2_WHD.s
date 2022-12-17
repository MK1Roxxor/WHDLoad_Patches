***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   BACK TO THE FUTURE 2 WHDLOAD SLAVE       )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            December 2022                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 17-Dec-2022	- restarted from scratch
;		- decruncher relocated to fast memory
;		- highscore load/save added
;		- unlimited energy option implemented in a simpler way
;		- trainer options for level 3 implemented (special case)

; 15-Mar-2015	- work started
;		- interrupts fixed, protection disabled, timing fixed,
;		  $bfe0xx access fixed, blitter waits added, trainers added
;		- to do: fix black screen problem in level 2
;			 fix flickering status panel


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG


; Trainer options
TRB_UNLIMITED_LIVES	= 0
TRB_UNLIMITED_ENERGY	= 1
TRB_UNLIMITED_TIME	= 2
TRB_IN_GAME_KEYS	= 3
	
RAWKEY_X		= $32
RAWKEY_N		= $36
RAWKEY_E		= $12
RAWKEY_T		= $14


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


.config	dc.b	"C1:X:Unlimited Lives:",TRB_UNLIMITED_LIVES+"0",";"
	dc.b	"C1:X:Unlimited Energy:",TRB_UNLIMITED_ENERGY+"0",";"
	dc.b	"C1:X:Unlimited Time:",TRB_UNLIMITED_TIME+"0",";"
	dc.b	"C1:X:In-Game Keys:",TRB_IN_GAME_KEYS+"0",";"
	dc.b	"C2:B:Disable Blitter Wait Patches;"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Games/BackToTheFuture2",0
	ENDC

.name	dc.b	"Back to the Future 2",0
.copy	dc.b	"1990 Image Works",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.3 (17.12.2022)",10
	dc.b	10
	dc.b	"In-Game Keys:",10
	dc.b	"T: Toggle Unlimited Time E: Refresh Energy",10
	dc.b	"N: Skip Level X: Show End",0
	

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load game code
	lea	$13000,a0
	move.l	#$4f6*512,d0
	move.l	#$1e0*512,d1
	bsr	Disk_Load

	; Version check
	move.l	a0,a5
	move.l	d1,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$a1a2,d0			; SPS 0005
	beq.b	.Is_Supported_Version

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.Is_Supported_Version

	; Patch game code
	lea	PL_GAME(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; Apply blitter wait patches
	clr.l	-(a7)				; TAG_DONE
	clr.l	-(a7)				; CUSTOM2 data
	pea	WHDLTAG_CUSTOM2_GET
	move.l	a7,a0
	jsr	resload_Control(a2)
	tst.w	6(a7)
	add.w	#3*4,a7
	bne.b	.no_blitter_wait_patches
	lea	PL_GAME_BLIT(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches
.no_blitter_wait_patches

	bsr	Load_Highscores

	; Start game
	jmp	(a5)


; ---------------------------------------------------------------------------

PL_GAME	PL_START
	PL_IFC1X	TRB_IN_GAME_KEYS
	PL_PSS	$3d8a,.Initialise_Keyboard_In_Game_Keys,2
	PL_W	$68de,$4e71
	PL_W	$68e0+2,RAWKEY_N
	PL_ELSE
	PL_PSS	$3d8a,.Initialise_Keyboard,2
	PL_ENDIF
	PL_P	$1156,.Load_Data
	PL_SA	$515a,$5a40			; skip Copylock
	PL_L	$5a4c,$4e714e71
	PL_P	$6ae4,Decrunch
	PL_L	$3f14+2,$bfe001			; $bfe0ff -> $bfe001
	PL_P	$f23e,Fix_DMA_Wait		; fix DMA wait in replayer

	PL_IFC1
	; Do nothing if trainer options have been used.
	PL_ELSE
	PL_P	$e44,.Save_Highscores
	PL_ENDIF

	PL_IFC1X	TRB_UNLIMITED_LIVES
	PL_B	$62ae,$4a
	PL_B	$baec,$4a
	PL_ENDIF

	PL_IFC1X	TRB_UNLIMITED_ENERGY
	PL_W	$74fc,$4e71

	; Level 3
	PL_W	$c9da+2,0
	PL_W	$cbb4+2,0
	PL_W	$d084+2,0
	PL_W	$d0fc+2,0
	PL_B	$d33a,$4a
	PL_ENDIF

	PL_IFC1X	TRB_UNLIMITED_TIME
	PL_W	$2e0,$4e71
	PL_ENDIF

	PL_END


.Save_Highscores
	tst.w	d1
	beq.b	.no_highscore_achieved
	jsr	$13000+$e4a		; enter name
	bsr	Save_Highscores

.no_highscore_achieved
	rts


; d1.w: starting sector
; d2.w: number of sectors to load
; a0.l: destination

.Load_Data
	move.w	d1,d0
	move.w	d2,d1
	mulu.w	#512,d0
	mulu.w	#512,d1
	bra.w	Disk_Load

.Initialise_Keyboard
	lea	.Handle_Keys(pc),a0
	move.l	a0,KbdCust-.Handle_Keys(a0)
	rts

.Initialise_Keyboard_In_Game_Keys
	lea	.Handle_In_Game_Keys(pc),a0
	move.l	a0,KbdCust-.Handle_In_Game_Keys(a0)
	rts
	

.Handle_Keys
	move.b	RawKey(pc),$13000+$407e
	rts

.Handle_In_Game_Keys
	bsr.b	.Handle_Keys

	move.b	RawKey(pc),d1
	ext.w	d1
	lea	.TAB(pc),a0
.check_all_keys
	movem.w	(a0)+,d0/d2
	
	cmp.w	d0,d1
	bne.b	.check_next_key
	lea	.last_key(pc),a1
	cmp.b	(a1),d1
	beq.b	.check_next_key
	move.b	d1,(a1)
	jsr	.TAB(pc,d2.w)
	bsr	Flush_Cache
	bra.b	.exit_key_handling

.check_next_key
	tst.w	(a0)
	bne.b	.check_all_keys
	clr.b	2(a0)			; clear .last_key

.exit_key_handling
	rts

.TAB	dc.w	RAWKEY_X,.Show_End-.TAB
	dc.w	RAWKEY_E,.Refresh_Energy-.TAB
	dc.w	RAWKEY_T,.Toggle_Unlimited_Time-.TAB
	dc.w	0			; end of tab


.last_key
	dc.b	0
	dc.b	0


.Show_End
	move.w	#5-1,$13000+$5efa
	move.w	#2,$13000+$5f02
	rts

.Refresh_Energy
	move.b	#95,$13000+$20002+$36
	move.b	#95,$13000+$a034		; level 3
	rts

.Toggle_Unlimited_Time
	eor.w	#$cf70,$13000+$2e0
	rts


PL_GAME_BLIT
	PL_START
	PL_PS	$44c6,.Wait_Blit_Dff000_A5
	PL_PSS	$450e,.Wait_Blit_a1_54_a1_48,2
	PL_PS	$4530,.Wait_Blit_Dff000_A5
	PL_PSS	$456a,.Wait_Blit_a1_54_a1_48,2
	PL_PS	$4eca,.Wait_Blit_Dff000_A5
	PL_PS	$3c90,.Wait_Blit_Dff000_A5
	PL_PS	$4584,.Wait_Blit_Dff000_A5
	PL_PSS	$45cc,.Wait_Blit_a1_54_a1_48,2
	PL_PS	$45ee,.Wait_Blit_Dff000_A5
	PL_PSS	$4628,.Wait_Blit_a1_54_a1_48,2
	PL_PS	$4642,.Wait_Blit_Dff000_A5
	PL_PSS	$468a,.Wait_Blit_a1_54_a1_48,2
	PL_PS	$46ac,.Wait_Blit_Dff000_A5
	PL_PSS	$46e6,.Wait_Blit_a1_54_a1_48,2
	PL_PS	$4700,.Wait_Blit_Dff000_A5
	PL_PSS	$474a,.Wait_Blit_a1_54_a1_48,2
	PL_PS	$476c,.Wait_Blit_Dff000_A5
	PL_PSS	$47a8,.Wait_Blit_a1_54_a1_48,2
	PL_PS	$20da0,.Wait_Blit_Dff000_A5
	PL_PSS	$20dfe,.Wait_Blit_a0_54_a0_48,2
	PL_PS	$3c90,.Wait_Blit_Dff000_A5
	PL_END
	

.Wait_Blit_Dff000_A5
	lea	$dff000,a5
	bra.w	Wait_Blit

.Wait_Blit_a1_54_a1_48
	bsr	Wait_Blit
	move.l	a1,$54(a5)
	move.l	a1,$48(a5)
	rts

.Wait_Blit_a0_54_a0_48
	bsr	Wait_Blit
	move.l	a0,$54(a5)
	move.l	a0,$48(a5)
	rts

; ---------------------------------------------------------------------------

HIGHSCORE_LOCATION	= $13000+$f70
HIGHSCORE_SIZE		= $ff6-$f70

Load_Highscores
	lea	Highscore_Name(pc),a0
	bsr	File_Exists
	tst.l	d0
	beq.b	.no_highscore_file_found
	lea	HIGHSCORE_LOCATION,a1
	bsr	Load_File

.no_highscore_file_found
	rts

Save_Highscores
	lea	Highscore_Name(pc),a0
	lea	HIGHSCORE_LOCATION,a1
	move.l	#HIGHSCORE_SIZE,d0
	bra.w	Save_File


Highscore_Name	dc.b	"BackToTheFuture2.high",0
		CNOP	0,2

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


Flush_Cache
	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
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

Decrunch
	movem.l	d1-d4/a0-a4,-(sp)
	move.l	a0,a3
	add.w	2(a3),a0
	tst.l	(a3)+
	addq.w	#4,a0
	move.l	(a0)+,d1
	move.l	(a0)+,d0
	move.l	d0,-(sp)
	lea	(a0,d0.l),a2
	add.l	#$100,a2
	add.l	d1,a0
	move.b	-(a0),d1
	moveq	#0,d2
	moveq	#7,d3
lbC006B0A
	move.l	a3,a4
lbC006B0C
	add.b	d1,d1
	bcc.b	lbC006B12
	addq.w	#2,a4
lbC006B12
	dbf	d3,lbC006B1A
	moveq	#7,d3
	move.b	-(a0),d1
lbC006B1A
	move.w	(a4),d4
	bmi.b	lbC006B22
	add.w	d4,a4
	bra.b	lbC006B0C

lbC006B22
	tst.b	d2
	bmi.b	lbC006B30
	cmp.w	#$F100,d4
	bne.b	lbC006B36
	subq.b	#1,d2
	bra.b	lbC006B0A

lbC006B30
	add.b	d4,d2
	sub.l	d2,d0
	move.b	(a2),d4
lbC006B36
	move.b	d4,-(a2)
	dbf	d2,lbC006B36
	addq.w	#1,d2
	subq.l	#1,d0
	bne.b	lbC006B0A
	lea	(-4,a3),a0
	move.l	(sp)+,d0
	move.l	a0,a1
	add.l	(a0),a0
	add.l	#$10C,a0
	move.l	a0,d2
	sub.l	a1,d2
	move.l	d0,d1
lbC006B58
	move.b	(a0)+,(a1)+
	subq.l	#1,d1
	bne.b	lbC006B58
lbC006B5E
	clr.b	(a1)+
	subq.l	#1,d2
	bne.b	lbC006B5E
	movem.l	(sp)+,d1-d4/a0-a4
	rts


***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        SKI OR DIE WHDLOAD SLAVE            )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             December 2022                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 29-Dec-2022	- unused code removed

; 28-Dec-2022	- work started
;		- protection completely skipped, highscore saving supported, 
;		  68000 quitkey support, CPU dependent delay loop in
;		  keyboard routine fixed


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Hardware/dmabits.i
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
	dc.w	.dir-HEADER		; ws_CurrentDir
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
	dc.b	"SOURCES:WHD_Slaves/Games/SkiOrDie/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Ski or Die",0
.copy	dc.b	"1991 Electronic Arts",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.1 (29.12.2022)",0

File_Name	dc.b	"Ski_Or_Die_39",0

; file name structure
FN		RSRESET
FN_NAME		rs.b	11
FN_NUMBER	rs.b	2

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Load game code
	lea	File_Name(pc),a0
	lea	$3100.w,a1
	bsr	Load_File

	move.l	a1,a5

	; Version check
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$938e,d0		; SPS 1258
	beq.b 	.Version_is_Supported

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.Version_is_Supported

	; Patch game
	lea	PL_GAME(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	; Run game
	jmp	(a5)



; ---------------------------------------------------------------------------

PL_GAME	PL_START
	PL_PS	$2b9c,.Load_Game_File
	PL_PS	$2bde,.Save_Game_File
	PL_PSS	$13ef0,.Fix_Keyboard_Delay,2
	PL_PS	$13ed2,.Check_Quit_Key
	PL_R	$5dc			; disable protection check
	PL_B	$1421c,$01		; set protection flag
	PL_B	$1421d,$01		; set protection flag 2
	PL_R	$e4d8			; disable drive init
	PL_END

.Check_Quit_Key
	bsr.b	.Get_Key
	ror.b	d0
	not.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT

.Get_Key
	move.b	$bfec01,d0
	rts	

.Fix_Keyboard_Delay
	moveq	#3,d0
	bra.w	Wait_Raster_Lines

; a2.w: file_number
; a3.l: destination

.Load_Game_File
	bsr.b	.Build_File_Name
	move.l	a3,a1	
	bsr	Load_File
	moveq	#0,d0
	rts

; a2.w: file_number
; a3.l: data to save

.Save_Game_File
	bsr.b	.Build_File_Name
	move.l	a3,a1
	move.l	#512,d0
	bra.w	Save_File		


; a2.w: file number
; ----
; a0.l: file name

.Build_File_Name
	moveq	#0,d0
	move.w	a2,d0
	lea	File_Name(pc),a0
	divu.w	#10,d0
	add.b	#"0",d0
	move.b	d0,FN_NUMBER(a0)
	swap	d0
	add.b	#"0",d0
	move.b	d0,FN_NUMBER+1(a0)
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

; ---------------------------------------------------------------------------

; a0.l: patch list
; a1.l: destination

Apply_Patches
	movem.l	d0-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts



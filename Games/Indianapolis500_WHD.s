***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      INDIANAPOLIS 500 WHDLOAD SLAVE        )*)---.---.   *
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

; 30-Apr-2022	- byte sized flag was passed as word sized flag when starting
;		  game, this caused the replay to work as intended
;		- all helper routines that are not used have been removed
;		- cache is enabled prior to starting the game


; 28-Apr-2022	- some unused defines and Includes removed

; 27-Apr-2022	- 68000 quitkey support and level 2 interrupt acknowledge
;		  fixes for intro part
;		- keyboard interrupt code removed from slave

; 26-Apr-2022	- level 2 interrupt acknowledge fixed for 040/060
;		- 68000 quitkey support

; 24-Apr-2022	- work started
;		- protection completely removed
;		- saves done to separate files


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $46		; Del
;DEBUG

FAST_MEMORY_SIZE	= 524288

	
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
	dc.l	FAST_MEMORY_SIZE	; ws_ExpMem
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
	dc.b	"SOURCES:WHD_Slaves/Games/Indianapolis500",0
	ENDC

.name	dc.b	"Indianapolis 500",0
.copy	dc.b	"1990 Papyrus Design Group",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 3.0 (30.04.2022)",0

	CNOP	0,4



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Load intro code
	sub.l	a0,a0
	move.l	a0,d0
	move.l	#19*$1600,d1
	moveq	#1,d2
	move.l	a0,a5
	move.l	d1,d5
	jsr	resload_DiskLoad(a2)

	; Version check
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$B46E,d0			; SPS 686
	beq.b	.Version_is_supported
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
.Version_is_supported

	; Patch intro code
	lea	PL_INTRO(pc),a0
	add.l	#$a040,a5
	move.l	a5,a1
	bsr	Apply_Patches

	; Set current track
	moveq	#19,d0
	move.b	d0,$0.w

	; Set memory pointers
	move.l	#$80000,d7		; chip memory size
	move.l	HEADER+ws_ExpMem(pc),d6	; start of extended memory

	; Run game
	bsr	Enable_Cache
	jmp	(a5)
	

; ---------------------------------------------------------------------------

PL_INTRO
	PL_START
	PL_SA	$14,$1a			; don't change ext. memory pointer
	PL_P	$107e,.Load_Track
	PL_R	$11b0			; disable drive access (motor off)
	PL_PS	$266,.Patch_Game
	PL_PS	$b90,.Check_Quit_Key
	PL_PSS	$be2,Acknowledge_Level2_Interrupt,2
	PL_PSS	$bf6,Acknowledge_Level2_Interrupt,2
	PL_PSS	$c6a,Acknowledge_Level2_Interrupt,2
	PL_END

.Check_Quit_Key
	move.b	$bfec01,d0
	move.l	d0,-(a7)
	ror.b	d0
	not.b	d0
	bsr	Check_Quit_Key
	move.l	(a7)+,d0
	rts



.Patch_Game
	move.l	a0,a1
	lea	PL_GAME(pc),a0

	IFD	DEBUG
	movem.l	d0-a6,-(a7)
	clr.l	-(a7)
	move.l	a1,-(a7)
	pea	WHDLTAG_DBGADR_SET
	move.l	a7,a0
	move.l	resload(pc),a2
	jsr	resload_Control(a2)
	add.w	#3*4,a7
	movem.l	(a7)+,d0-a6
	ENDC
	

	bsr	Apply_Patches
	move.l	a1,a0
	move.b	$a040+$b3e,d3
	rts


.Load_Track
	move.w	$a040+$b40,d0
	mulu.w	#512,d0
	move.l	#512*11,d1
	bra.w	Disk_Load


; ---------------------------------------------------------------------------

PL_GAME	PL_START
	PL_SA	$2d52a,$2d542

	PL_P	$2d478,.load
	PL_P	$2d4b8,.save
	PL_SA	$2b528,$2b5c2		; skip manual protection

	PL_PSS	$9bb4,Acknowledge_Level2_Interrupt,2
	PL_PSS	$9bcc,Acknowledge_Level2_Interrupt,2
	PL_PSS	$9c48,Acknowledge_Level2_Interrupt,2

	PL_PS	$9b7e,.Check_Quit_Key
	PL_END

.load	movem.l	d0-a6,-(a7)
	move.l	a0,a5

	bsr.b	.Get_File_Name
	move.l	a2,d2
	beq.b	.File_Not_Found
	move.l	a2,a0
	bsr	File_Exists
	beq.b	.File_Not_Found

	move.l	a5,a1
	bsr	Load_File
	bra.b	.done


.File_Not_Found
	move.l	a5,a0
	mulu.w	#512,d0
	mulu.w	#512,d1
	bsr	Disk_Load

.done	movem.l	(a7)+,d0-a6
	and.b	#$fe,ccr
	rts



.save	movem.l	d0-a6,-(a7)
	bsr.b	.Get_File_Name
	move.l	a2,d2
	beq.b	.do_nothing

	move.l	a0,a1
	move.l	a2,a0
	mulu.w	#512,d1
	move.l	d1,d0
	bsr	Save_File

.do_nothing
	moveq	#0,d0
	movem.l	(a7)+,d0-a6
	and.b	#$fe,ccr
	rts
	


; d0.w: sector
; ----
; a2.l: file name (0 if file name could not be determined)

.Get_File_Name
	lea	.Tab(pc),a3
.check_all_entries
	movem.w	(a3)+,d2/d3
	cmp.w	d2,d0
	beq.b	.name_found
	
	tst.w	(a3)
	bne.b	.check_all_entries
	sub.l	a2,a2
	rts

.name_found
	lea	.Tab(pc,d3.w),a2
	rts


.Tab	dc.w	$494,.Settings_Name-.Tab
	dc.w	$65c,.Replay_Name-.Tab
	dc.w	0


.Settings_Name	dc.b	"Settings",0
.Replay_Name	dc.b	"Instant_Replay",0
		CNOP	0,2


.Check_Quit_Key
	eor.b	#$fe,d0
	ror.l	#1,d0
	bra.w	Check_Quit_Key

Acknowledge_Level2_Interrupt
	move.w	#1<<3,$dff09c
	move.w	#1<<3,$dff09c
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


; a0.l: destination
; d0.l: offset
; d1.l: length
Disk_Load
	movem.l	d0-a6,-(a7)
	moveq	#1,d2
	move.l	resload(pc),a1
	jsr	resload_DiskLoad(a1)
	movem.l	(a7)+,d0-a6
	rts

Load_File
	movem.l	d0-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_LoadFileDecrunch(a2)
	movem.l	(a7)+,d0-a6
	rts

Save_File
	movem.l	d0-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)
	movem.l	(a7)+,d0-a6
	rts

; a0.l: file name
; -----
; zflg: result (0: file does not exist)

File_Exists
	movem.l	d0-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
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



; ---------------------------------------------------------------------------

Enable_Cache
	movem.l	d0-a6,-(a7)
	move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	move.l	resload(pc),a2
	jsr	resload_SetCPU(a2)
	movem.l	(a7)+,d0-a6
	rts

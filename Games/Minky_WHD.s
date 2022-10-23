***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(          MINKY WHDLOAD SLAVE               )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            October 2022                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 23-Oct-2022	- "Toggle invincibility" in-game key works correctly now,
;		  one should remember to flush the cache when modifying
;		  code :)
;		- highscore saving disabled if trainer options are used
;		- code for generating copperlist fixed to not used
;		  ECS copper register (BPLCON3)

; 18-Oct-2022	- more trainer options added (unlimited ammo, start with
;		  max. ammo)
;		- selecting quit in game menu quits patch now

; 17-Oct-2022	- highscore saving approach changed, highscore saving
;		  works now
;		- highscore loading added

; 16-Oct-2022	- another access fault fixed (similar to the problem in
;		  the tile blitting routine)
;		- highscore saving added, doesn't work correctly yet

; 15-Oct-2022	- work started
;		- OS stuff patched/emulated (AllocMem, file loading),
;		  wrong BPLCON0 settings fixed, out of bounds blits fixed,
;		  BPLCON0 color bit fixes, invalid copperlist entries fixed


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	exec/memory.i
	INCLUDE	exec/exec_lib.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
DEBUG

OPCODE_JMP	= $4ef9

; Trainer options
TRB_UNLIMITED_LIVES	= 0
TRB_UNLIMITED_AMMO	= 1
TRB_START_WITH_MAX_AMMO	= 2		; start with 99 ammo
TRB_INVINCIBILITY	= 3
TRB_EXIT_ALWAYS_OPEN	= 4
TRB_IN_GAME_KEYS	= 5

MAX_AMMO		= 99
MAX_LIVES		= 9

RAWKEY_I		= $17
RAWKEY_O		= $18
RAWKEY_A		= $20
RAWKEY_L		= $28
RAWKEY_HELP		= $5f
	
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
	dc.l	$80000			; ws_ExpMem
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
	dc.b	"C1:X:Unlimited Ammo:",TRB_UNLIMITED_AMMO+"0",";"
	dc.b	"C1:X:Start with max. Ammo:",TRB_START_WITH_MAX_AMMO+"0",";"
	dc.b	"C1:X:Invincibility:",TRB_INVINCIBILITY+"0",";"
	dc.b	"C1:X:Exit always Open:",TRB_EXIT_ALWAYS_OPEN+"0",";"
	dc.b	"C1:X:In-Game Keys:",TRB_IN_GAME_KEYS+"0",";"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Games/Minky/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Minky",0
.copy	dc.b	"2022 Matze1887 Retro Games",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG (do NOT release!) "
	ENDC
	dc.b	"Version 1.00 (23.10.2022)",-1
	dc.b	"In-Game Keys:",10
	dc.b	"-------------",10
	dc.b	"L: Refresh Lives A: Refresh Ammo",10
	dc.b	"I: Toggle Invincibility O: Open Exit",10
	dc.b	"HELP: Skip Level",0

Game_Name
	dc.b	"Minky.exe",0
	CNOP	0,4

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt

	; Load game
	lea	Game_Name(pc),a0
	move.l	HEADER+ws_ExpMem(pc),a1
	bsr	Load_File

	move.l	a1,a5

	; Version check
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$5495,d0		; V1.01
	beq.b	.Version_is_supported
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.Version_is_supported

	; Relocate game code
	move.l	a5,a0
	clr.l	-(a7)			; TAG_DONE
	move.l	Free_Chip_Memory_Location(pc),-(a7)
	pea	WHDLTAG_CHIPPTR
	pea	8.w			; alignment: 8 bytes
	pea	WHDLTAG_ALIGN
	move.l	a7,a1
	jsr	resload_Relocate(a2)

	lea	Free_Fast_Memory_Location(pc),a0
	move.l	a5,(a0)
	add.l	d0,(a0)
	lea	Free_Chip_Memory_Location(pc),a0
	move.l	12(a7),d0
	add.l	d0,(a0)

	add.w	#5*4,a7

	; Patch AllocMem() in exec library
	move.l	Free_Chip_Memory_Location(pc),a6
	move.l	a6,$4.w
	lea	_LVOAllocMem(a6),a6
	move.w	#OPCODE_JMP,(a6)+
	pea	Alloc_Memory_Patch(pc)
	move.l	(a7)+,(a6)


	; Patch game code
	lea	PL_GAME(pc),a0
	move.l	a5,a1
	bsr	Apply_Patches

	lea	PL_GAME_CHIPDATA(pc),a0
	lea	$2000.w,a1
	bsr	Apply_Patches

	; Fix uninitialised copperlist buffers
	lea	$2000+$22814-$13278,a0
	lea	$2000+$26494-$13278,a1
.initialise_copper
	move.w	#$01fe,(a0)
	addq.w	#4,a0
	cmp.l	a0,a1
	bne.b	.initialise_copper

	lea	Highscore_Name(pc),a0
	bsr	File_Exists
	tst.l	.d0
	beq.b	.no_highscore_file_found
	bsr	Load_Highscores
.no_highscore_file_found
	
	; Start the game
	sub.l	a0,a0
	lea	$dff000,a6
	jmp	$76(a5)


; ---------------------------------------------------------------------------

EMPTY_TILE_LOCATION	= $70000	; empty 16/8*64 space for blitting

PL_GAME	PL_START
	PL_SA	$616a,$6178		; skip opening dos.library
	PL_SA	$617c,$618e		; skip Open()
	PL_PSA	$6196,.Load_File,$61a6
	PL_SA	$61ea,$623c
	PL_SA	$2928,$2930
	PL_SA	$293a,$293e
	PL_SA	$61ac,$61b2
	PL_P	$8e,QUIT
	PL_W	$1af2+2,1<<9		; fix wrong BPLCON0 setting
	PL_W	$1bae+2,1<<9		; fix wrong BPLCON0 setting
	PL_W	$1d22+2,1<<9		; fix wrong BPLCON0 setting
	PL_PS	$6ea6,.Fix_Blit
	PL_PS	$5380,.Fix_Access_Fault
	PL_W	$39c+2,$1fe		; BPLCON3 -> NOP
	PL_W	$3b6+2,$1fe		; BPLCON3 -> NOP
	PL_W	$3bc+2,$1fe		; BPLCON3 -> NOP
	PL_W	$3c2+2,$1fe		; BPLCON3 -> NOP
	PL_W	$3c8+2,$1fe		; BPLCON3 -> NOP
	PL_W	$3ce+2,$1fe		; BPLCON3 -> NOP
	PL_W	$3d4+2,$1fe		; BPLCON3 -> NOP
	PL_W	$3da+2,$1fe		; BPLCON3 -> NOP
	PL_W	$3e0+2,$1fe		; BPLCON3 -> NOP
	PL_W	$3e6+2,$1fe		; BPLCON3 -> NOP
	PL_W	$3ec+2,$1fe		; BPLCON3 -> NOP
	PL_W	$3f2+2,$1fe		; BPLCON3 -> NOP

	PL_IFC1
	PL_ELSE
	PL_PSS	$432c,.Save_Highscores,2
	PL_ENDIF
	PL_P	$51c,QUIT

	PL_IFC1X	TRB_UNLIMITED_LIVES
	PL_B	$1a32,$4a
	PL_ENDIF

	PL_IFC1X	TRB_UNLIMITED_AMMO
	PL_B	$37bc,$4a
	PL_ENDIF

	PL_IFC1X	TRB_START_WITH_MAX_AMMO
	PL_PS	$2f2,.Set_Max_Ammo
	PL_ENDIF

	PL_IFC1X	TRB_INVINCIBILITY
	PL_W	$3184,$4e71
	PL_B	$3186,$4a
	PL_ENDIF

	PL_IFC1X	TRB_EXIT_ALWAYS_OPEN
	PL_P	$652c,.Set_Exit_Open
	PL_ENDIF

	PL_IFC1X	TRB_IN_GAME_KEYS
	PL_PSS	$4f4,.Check_In_Game_Keys,2
	PL_ENDIF
	PL_END

.Set_Exit_Open
	move.l	a0,-(a7)
	move.l	HEADER+ws_ExpMem(pc),a0
	st	$54a(a0)
	move.l	(a7)+,a0
	rts

.Set_Max_Ammo
	move.l	HEADER+ws_ExpMem(pc),a0
	move.b	#MAX_AMMO,$547(a0)
	rts

.Check_In_Game_Keys
	movem.l	d0-a6,-(a7)
	lea	.In_Game_Keys_Table(pc),a0
	move.b	RawKey(pc),d0
.check_key_table
	movem.w	(a0)+,d1/d2
	cmp.b	d0,d1
	beq.b	.key_found
	tst.w	(a0)
	bne.b	.check_key_table
	bra.b	.exit

.key_found
	move.l	HEADER+ws_ExpMem(pc),a0
	jsr	.In_Game_Keys_Table(pc,d2.w)
	lea	RawKey(pc),a0
	clr.b	(a0)

	move.l	resload(pc),a0
	jsr	resload_FlushCache(a0)

.exit	movem.l	(a7)+,d0-a6

	cmp.b	#$75,$bfec01
	rts

.In_Game_Keys_Table
	dc.w	RAWKEY_HELP,.Skip_Level-.In_Game_Keys_Table
	dc.w	RAWKEY_L,.Refresh_Lives-.In_Game_Keys_Table
	dc.w	RAWKEY_A,.Refresh_Ammo-.In_Game_Keys_Table
	dc.w	RAWKEY_O,.Open_Exit-.In_Game_Keys_Table
	dc.w	RAWKEY_I,.Toggle_Invincibility-.In_Game_Keys_Table
	dc.w	0

.Skip_Level
	st	$576(a0)
	st	$577(a0)
	rts

.Refresh_Lives
	move.b	#MAX_LIVES,$58c(a0)
	st	$536(a0)		; update lives status
	rts

.Refresh_Ammo
	bsr	.Set_Max_Ammo
	st	$538(a0)		; update ammo status
	rts

.Open_Exit
	bra.w	.Set_Exit_Open

.Toggle_Invincibility
	not.b	$53c(a0)		; toggle invincibility flag
	eor.b	#$19,$3186(a0)		; subq.b<->tst.b invincibility time
	rts



.Fix_Blit
	lsl.w	#2,d2
	bpl.b	.ok1
	lea	EMPTY_TILE_LOCATION,a0
	rts
.ok1	move.l	(a0,d2.w),a0
	rts


.Fix_Access_Fault
	lsl.w	#2,d2
	move.w	(a1,d2.w),d1
	cmp.w	#$608c,d1
	beq.b	.illegal_access
	tst.l	(a1,d2.w)
	
.illegal_access
	rts


; d1.l: file name
; d2.l: destination
; d3.l: size

.Load_File
	move.l	d1,a0
	move.l	d2,a1
	bra.w	Load_File


.Save_Highscores
	bsr	Save_Highscores
	btst	#7,$bfe001
	rts
		


; ---------------------------------------------------------------------------

PL_GAME_CHIPDATA
.OFF	= $13278			; offset to chip section in binary

	PL_START
	PL_W	$226f8-.OFF,$1fe	; BPLCON3 -> NOP
	PL_W	$226fc-.OFF,$1fe	; FMODE -> NOP
	PL_ORW	$227ea-.OFF,1<<9	; set BPLCON0 color bit
	PL_W	$2652c-.OFF,$1fe	; BPLCON3 -> NOP
	PL_W	$26530-.OFF,$1fe	; FMODE -> NOP
	PL_W	$26658-.OFF,$1fe	; BPLCON3 -> NOP
	PL_W	$2665c-.OFF,$1fe	; FMODE -> NOP
	PL_W	$26718-.OFF,$1fe	; BPLCON3 -> NOP
	PL_W	$2671c-.OFF,$1fe	; FMODE -> NOP
	PL_W	$268a0-.OFF,$1fe	; BPLCON3 -> NOP
	PL_W	$268a4-.OFF,$1fe	; FMODE -> NOP
	
	PL_END

; ---------------------------------------------------------------------------

Load_Highscores
	movem.l	d0-a6,-(a7)
	lea	Highscore_Name(pc),a0
	move.l	HEADER+ws_ExpMem(pc),a1
	add.w	#$4ba2,a1
	bsr	Load_File
	movem.l	(a7)+,d0-a6
	rts

Save_Highscores
	movem.l	d0-a6,-(a7)
	lea	Highscore_Name(pc),a0
	move.l	HEADER+ws_ExpMem(pc),a1
	add.w	#$4ba2,a1
	move.l	#$4c2e-$4ba2,d0
	bsr	Save_File
	movem.l	(a7)+,d0-a6
	rts

Highscore_Name
	dc.b	"Minky.high",0
	CNOP	0,2

; ---------------------------------------------------------------------------

; d0.l: size to allocate
; d1.l: type of memory
Alloc_Memory_Patch
	lea	Free_Fast_Memory_Location(pc),a0
	btst	#MEMB_CHIP,d1
	beq.b	.No_Chip_Memory_To_Allocate
	lea	Free_Chip_Memory_Location(pc),a0
.No_Chip_Memory_To_Allocate
	move.l	d0,d1
	move.l	(a0),d0
	add.l	d1,(a0)
	rts

Free_Chip_Memory_Location	dc.l	$2000
Free_Fast_Memory_Location	dc.l	0

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

; a0.l: file name
; ----
; d0.l: result (0: file does not exist)

File_Exists
	movem.l	d1-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)	
	movem.l	(a7)+,d1-a6
	rts
	

; a0.l: file name
; a1.l: destination
; ----
; d0.l: length

Load_File
	movem.l	d1-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)	
	movem.l	(a7)+,d1-a6
	rts

; a0.l: file name
; a1.l: file data
; d0.l: file size

Save_File
	movem.l	d0-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)
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


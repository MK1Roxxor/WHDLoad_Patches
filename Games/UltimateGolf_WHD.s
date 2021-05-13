***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       ULTIMATE GOLF WHDLOAD SLAVE          )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              May 2021                                   *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 13-May-2021	- wrong offset for interrupt acknowledge patch fixed

; 13-May-2021	- fungus decruncher properly relocated
;		- color flashing in decruncher disabled
;		- CPU dependent delay in main game fixed
;		- required WHDLoad version set to V10 as no V17 features
;		  are used
;		- access fault when using "Load Save Game" fixed (happened
;		  if no game had been saved)
;		- interrupts disabled to avoid crash when loading game
;		  (see the comment for "DisableInterrupts" for more info)
;		- patch is finished!

; 10-May-2021	- load/save game works fine now
;		- graphics bugs in text writer fixed (SMC)
;		- CPU dependent delay in text fading routine fixed
;		- 68000 quitkey support for title screen added

; 08-May-2021	- changed load/save approach, directory data is now saved
;		- load/save game patches need to be adapted, not yet
;		  fully finished

; 06-May-2021	- game patched, saving game works, loading a saved game
;		  does not work yet

; 05-May-2021	- work started

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap|WHDLF_NoDivZero
QUITKEY		= $58		; F9
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


HEADER	SLAVE_HEADER		; ws_security + ws_ID
	dc.w	10		; ws_version
	dc.w	FLAGS		; flags
	dc.l	524288		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	dc.w	.dir-HEADER	; ws_CurrentDir
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_KeyDebug
	dc.b	QUITKEY		; ws_KeyExit
	dc.l	0		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
;	dc.w	0		; ws_kickname
;	dc.l	0		; ws_kicksize
;	dc.w	0		; ws_kickcrc
;
; v17
;	dc.w	.config-HEADER	; ws_config
;
;
;.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/UltimateGolf/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Ultimate Golf",0
.copy	dc.b	"1990 Gremlin",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.3a (13.05.2021)",0

FileName	dc.b	"UltimateGolf_"
FileNum		dc.b	"07",0
		CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; enable instruction cache
	move.l	#CACRF_EnableI,d0
	move.l	d0,d1
	jsr	resload_SetCACR(a2)

	; load boot
	lea	FileName(pc),a0
	lea	$78000,a1
	move.l	a1,a5
	jsr	resload_LoadFileDecrunch(a2)

	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$D887,d0		; SPS 2129
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

	; patch it
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

	; and start the game
	jmp	(a5)


; ---------------------------------------------------------------------------

PLBOOT	PL_START
	PL_SA	$798,$7c0		; skip protection track check
	PL_P	$6da,.LoadFileNumber
	PL_PS	$e7c,AckInt
	PL_R	$f0a			; disable manual protection
	PL_R	$4bc			; disable drive access (motor off)
	PL_P	$8b4,.PatchGame		; decrunch, patch and run game
	PL_PS	$7e8,.PatchReplay


	PL_PS	$c84,.flush		; fix SMC in text writer
	PL_PSS	$be8,.delay,2		; fix CPU dependent delay in fade routine

	PL_PS	$155a,CheckQuitKey

	PL_SA	$a14,$a1a		; disable color flashing in decruncher
	PL_SA	$b02,$b08		; as above

	PL_PS	$878,.DisableInterrupts
	PL_END


; the main game file trashes the replay code during loading so
; all interrupts need to be disabled

.DisableInterrupts
	move.w	#$2700,sr
	rts


.delay	move.w	#14540/34-1,d7
	move.w	d0,-(a7)
.loop	move.b	$dff006,d0
.same_line
	cmp.b	$dff006,d0
	beq.b	.same_line
	dbf	d7,.loop
	move.w	(a7)+,d0
	rts

	

.flush	sub.l	a5,a6
	move.l	a6,d0
	move.w	d0,(a5)
	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts

.AckVBI	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte


.PatchGame
	; Set stack to safe location (game code uses almost the complete
	; 512k memory ($400-$80000)).
	; Decruncher is originally copied to $200.w, decruncher code
	; starts at offset $a00 in the binary and stack location
	; is at offset $b96 in the binary.
	lea	$200+($b96-$a00).w,a7
	bsr	FungusDecrunch

	lea	PLGAME(pc),a0
	lea	$400.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$400.w


.PatchReplay
	movem.l	d0-a6,-(a7)
	lea	PLREPLAY(pc),a0
	lea	$20000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	jmp	$20000



.LoadFileNumber
	moveq	#0,d1

; a0.l: pointer to file table data for this file
; d0.w: file number multiplied by 16 (size of one file entry in file table)
; d1.b: number adder

LoadFileNumber
	move.l	0*4(a0),a1		; destination

	lsr.w	#4,d0			; restore original file number
	add.b	d1,d0

	cmp.w	#11,d0			; course disk
	beq.b	.exit


	moveq	#0,d2
	move.w	d0,d2
	divu.w	#10,d2
	add.b	#"0",d2
	lea	FileNum(pc),a0
	move.b	d2,(a0)+
	swap	d2
	add.b	#"0",d2
	move.b	d2,(a0)+


	move.l	resload(pc),a2
	lea	FileName(pc),a0

	cmp.w	#8,d0			; data base
	bne.b	.normal_load
	movem.l	a0/a1,-(a7)
	jsr	resload_GetFileSize(a2)
	movem.l	(a7)+,a0/a1
	tst.l	d0
	beq.b	.exit
	


.normal_load
	jsr	resload_LoadFileDecrunch(a2)

.exit	rts

	
AckInt	move.w	d0,$dff09c
	move.w	d0,$dff09c
	rts

; ---------------------------------------------------------------------------

PLREPLAY
	PL_START
	PL_SA	$29a,$2a0		; skip move.w sr,-(a7) or.w #$700,sr
	PL_R	$356			; rte -> rts
	PL_END



; ---------------------------------------------------------------------------


PLGAME	PL_START
	PL_SA	$47568,$47570		; skip bset #1,$bfd200 (CIA B, DDRA)
	PL_R	$509a2			; disable drive access (motor on)
	PL_R	$50926			; disable drive access (step to track 0)
	PL_R	$50972			; disable drive access (motor off)
	PL_R	$5085c			; disable drive access (step to track)
	PL_P	$50330,.SetDiskID
	PL_P	$50b9e,.LoadFileNumber
	PL_P	$3b422,QUIT
	PL_PS	$4766c,AckInt
	PL_PSS	$4779e,.AckCOP,2
	PL_PS	$4780e,CheckQuitKey


	; --------------------------------------------------------------
	; As there are no course disks available for this game,
	; all options regarding course disks will be removed/adapted.

	PL_S	$396a8,2		; skip writing course disk option
	PL_DATA	$39726+2,.stop-.strt	; adapt the menu text
.strt	dc.b	"OR 2",0
.stop	CNOP	0,2

	PL_SA	$396ba,$396be		; skip check for key 3
	PL_B	$396be,$6c		; bgt -> bge

	; --------------------------------------------------------------
	; Load/save data base

	PL_SA	$3ee70,$3eeb0		; skip requesting database disk

	PL_SA	$3eff4,$3f01c		; skip disk request/format stuff
	PL_SA	$3f026,$3f04a		; skip waiting for key press
	PL_PS	$3f09c,.SaveDataBase
	PL_SA	$3f0ac,$3f0d4		; skip saving disk ID


	; --------------------------------------------------------------
	; Load/save game

	; load game
	PL_SA	$50fda,$51024		; skip requesting save disk
	PL_PS	$5115c,.LoadGameFile
	PL_PS	$5119c,.LoadGameFile
	

	; save game
	PL_SA	$50c2e,$50cae		: skip requesting save disk
	PL_SA	$50124,$50144		; skip searching for starting track
	PL_PS	$50168,.SaveFile	; step to track -> file saving
	PL_S	$50172,6		; skip real file saving routine
	PL_B	$50194,$60		; file has been saved completely
	PL_PS	$501e0,.SaveDirectory	; update directory file



	PL_PS	$3cba0,.Delay		; fix CPU dependent delay


	PL_PS	$3ebbe,.CheckDiskErrorFlag
	PL_END


; if "Load saved game" is used and there is no saved game yet,
; the error routine will point to an illegal text -> we fake
; it to point to the "directory error" text

.CheckDiskErrorFlag
	move.w	$400+$503b2,d0
	bne.b	.ok

	moveq	#3+1,d0			; directory error

.ok	rts


.Delay	bsr.w	.WaitOneLine
	
.WaitOneLine
	move.b	$dff006,d0
.same_line
	cmp.b	$dff006,d0
	beq.b	.same_line
	rts	


; d0.w: ID (0: game disk, 1: course disk, 2: database disk, 3: save disk)

.SetDiskID
	lea	.CurrentDisk(pc),a0
	move.w	d0,(a0)
	rts

.CurrentDisk	dc.w	0


.LoadDirectory
	movem.l	d0-a6,-(a7)
	lea	.DirectoryNames(pc),a0
	move.w	.CurrentDisk(pc),d0
	mulu.w	#8+1,d0			; 8 chars filename, 1 char for termination
	add.w	d0,a0
	lea	$400+$671f4,a1
	move.l	resload(pc),a2
	movem.l	a0/a1,-(a7)
	jsr	resload_GetFileSize(a2)
	movem.l	(a7)+,a0/a1
	tst.l	d0
	bne.b	.directory_exists

	; create directory file
	lea	$400+$671f4,a1
	move.l	a1,a2
	move.w	#2408-1,d7
.cls	clr.b	(a2)+
	dbf	d7,.cls

	st	$67ab6-$671f4(a1)
	st	$67b55-$671f4(a1)
	move.l	#2408,d0		; size
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)
	bra.b	.exit

.directory_exists
	jsr	resload_LoadFileDecrunch(a2)
.exit	movem.l	(a7)+,d0-a6
	rts



.DirectoryNames
	dc.b	"MAIN.DIR",0		; game disk
	dc.b	"COUR.DIR",0		; course disk
	dc.b	"DATA.DIR",0		; database disk
	dc.b	"SAVE.DIR",0		; save disk
	CNOP	0,2
	


.SaveFile
	movem.l	d0-a6,-(a7)
	move.l	d6,d0
	move.l	a5,a1
	addq.w	#4,a0
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)
	movem.l	(a7)+,d0-a6
	rts


; a0.l: directory data

.SaveDirectory
	movem.l	d0-a6,-(a7)
	move.l	a0,a1
	lea	.DirectoryNames(pc),a0
	move.w	.CurrentDisk(pc),d0
	mulu.w	#8+1,d0			; 8 chars filename, 1 char for termination
	add.w	d0,a0
	move.l	#2408,d0
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)
	movem.l	(a7)+,d0-a6
	rts


.LoadFileNumber
	cmp.w	#2*16,d0		; file number 2: directory
	beq.w	.LoadDirectory	

	moveq	#8,d1
	bra.w	LoadFileNumber



; a0.l: data
; d0.w: track number

.SaveDataBase
	moveq	#8,d0			; file number 8 = data base
	move.l	a0,a1

	moveq	#0,d2
	move.w	d0,d2
	divu.w	#10,d2
	add.b	#"0",d2
	lea	FileNum(pc),a0
	move.b	d2,(a0)+
	swap	d2
	add.b	#"0",d2
	move.b	d2,(a0)+

	lea	FileName(pc),a0
	move.l	#1004,d0
.save	move.l	resload(pc),a2
	jmp	resload_SaveFile(a2)

; a5.l: data 
; a6.l: file name
; d6.l: size


; directory format:
; dc.w number of files
; file entry
; ...
; 
;
; file entry format:
; 00: 4+4 bytes for file name (e.g. TEST.CRS)
; 08: file size (4 bytes)
; 12: track 

.LoadGameFile
	move.l	a6,a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jmp	resload_LoadFileDecrunch(a2)


; a5.l: data 
; a6.l: file name
; d6.l: size
; 
.SaveGameFile
	move.l	a6,a0
	move.l	a5,a1
	move.l	d6,d0
	bra.b	.save


.AckCOP	move.w	#1<<4,$dff09c
	move.w	#1<<4,$dff09c
	rts

CheckQuitKey
	bsr.b	.GetKey
	ror.b	#1,d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT


.GetKey	move.b	$c00(a0),d0
	not.b	d0
	rts


; ---------------------------------------------------------------------------


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


; ---------------------------------------------------------------------------


; a0.l: source
; a1.l: destination

FungusDecrunch
	move.l	#'*FUN',d0
	move.l	#'GUS*',d1

	; find end of binary by searching for the *FUNGUS* ID
.find_end

;	move.w	a0,($DFF180)

	cmp.l	(a0)+,d0
	beq.b	.found
	cmp.l	(a0)+,d0
	bne.b	.find_end
.found	cmp.l	(a0)+,d1
	bne.b	.find_end



	subq.w	#2*4,a0			; point to the "real" crunched data
	move.l	-(a0),a2		; a2.l: decrunched size
	add.l	a1,a2			; a2.l: end of decrunched data
	move.l	-(a0),d0
	move.l	-(a0),d4
	move.l	-(a0),d5
	move.l	-(a0),d6
	move.l	-(a0),d7
lbC000A36
	add.l	d0,d0
	bne.b	lbC000A4A
	move.l	d4,d0
	move.l	d5,d4
	move.l	d6,d5
	move.l	d7,d6
	move.l	-(a0),d7
	move.w	#$FFFF,ccr
	addx.l	d0,d0
lbC000A4A
	blo.w	lbC000AA0
	moveq	#3,d1
	moveq	#0,d3
	add.l	d0,d0
	bne.b	lbC000A66
	move.l	d4,d0
	move.l	d5,d4
	move.l	d6,d5
	move.l	d7,d6
	move.l	-(a0),d7
	move.w	#$FFFF,ccr
	addx.l	d0,d0
lbC000A66
	blo.b	lbC000A74
	moveq	#1,d3
	moveq	#8,d1
	bra.w	lbC000AF4

lbC000A70
	moveq	#8,d1
	moveq	#8,d3
lbC000A74
	bsr.w	lbC000B14
	add.w	d2,d3
lbC000A7A
	moveq	#7,d1
lbC000A7C
	add.l	d0,d0
	bne.b	lbC000A90
	move.l	d4,d0
	move.l	d5,d4
	move.l	d6,d5
	move.l	d7,d6
	move.l	-(a0),d7
	move.w	#$FFFF,ccr
	addx.l	d0,d0
lbC000A90
	addx.w	d2,d2
	dbra	d1,lbC000A7C
	move.b	d2,-(a2)
	dbra	d3,lbC000A7A
	bra.w	lbC000B02

lbC000AA0
	moveq	#0,d2
	add.l	d0,d0
	bne.b	lbC000AB6
	move.l	d4,d0
	move.l	d5,d4
	move.l	d6,d5
	move.l	d7,d6
	move.l	-(a0),d7
	move.w	#$FFFF,ccr
	addx.l	d0,d0
lbC000AB6
	addx.w	d2,d2
	add.l	d0,d0
	bne.b	lbC000ACC
	move.l	d4,d0
	move.l	d5,d4
	move.l	d6,d5
	move.l	d7,d6
	move.l	-(a0),d7
	move.w	#$FFFF,ccr
	addx.l	d0,d0
lbC000ACC
	addx.w	d2,d2
	cmp.b	#2,d2
	blt.b	lbC000AEA
	cmp.b	#3,d2
	beq.b	lbC000A70
	moveq	#8,d1
	bsr.w	lbC000B14
	move.w	d2,d3
	move.w	#12,d1
	bra.w	lbC000AF4

lbC000AEA
	moveq	#2,d3
	add.w	d2,d3
	move.w	#9,d1
	add.w	d2,d1
lbC000AF4
	bsr.w	lbC000B14
	lea	(1,a2,d2.w),a3
lbC000AFC
	move.b	-(a3),-(a2)
	dbra	d3,lbC000AFC
lbC000B02
	;move.w	a2,($DFF180)
	cmp.l	a2,a1
	bne.w	lbC000A36
	rts

	;jmp	($400)



lbC000B14
	subq.w	#1,d1
	clr.w	d2
lbC000B18
	add.l	d0,d0
	bne.b	lbC000B2C
	move.l	d4,d0
	move.l	d5,d4
	move.l	d6,d5
	move.l	d7,d6
	move.l	-(a0),d7
	move.w	#$FFFF,ccr
	addx.l	d0,d0
lbC000B2C
	addx.w	d2,d2
	dbra	d1,lbC000B18
	rts


***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       WORLD CUP USA '94 WHDLOAD SLAVE      )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             February 2022                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 27-Feb-2022	- adapted memory allocation, game works with 512k chip and
;		  512k other memory now
;		- "Insert Disk" text disabled
;		- blitter waits can be disabled with CUSTOM1
;		- patch is finished!

; 26-Feb-2022	- load/save support
;		- sprite DMA enabled
;		- keyboard routine fixed (level 2 interrupt used now)

; 25-Feb-2022	- work started
;		- OS stuff patched/emulated (AllocMem, file loading)
;		- blitter waits added
;		- 24-bit problems fixed
;		- BPLCON0 settings fixed
;		- DMA wait in replayer fixed
;		- access fault fixed (wrong write to DMACON)


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

CHIP_MEMORY_START	= $1100
CHIP_MEMORY_SIZE	= 524288
FAST_MEMORY_SIZE	= 524288


RAWKEY_1		= $01
RAWKEY_2		= $02
RAWKEY_3		= $03
RAWKEY_4		= $04
RAWKEY_5		= $05
RAWKEY_6		= $06
RAWKEY_7		= $07
RAWKEY_8		= $08
RAWKEY_9		= $09
RAWKEY_0		= $0A

RAWKEY_Q		= $10
RAWKEY_W		= $11
RAWKEY_E		= $12
RAWKEY_R		= $13
RAWKEY_T		= $14
RAWKEY_Y		= $15		; English layout
RAWKEY_U		= $16
RAWKEY_I		= $17
RAWKEY_O		= $18
RAWKEY_P		= $19

RAWKEY_A		= $20
RAWKEY_S		= $21
RAWKEY_D		= $22
RAWKEY_F		= $23
RAWKEY_G		= $24
RAWKEY_H		= $25
RAWKEY_J		= $26
RAWKEY_K		= $27
RAWKEY_L		= $28

RAWKEY_Z		= $31		; English layout
RAWKEY_X		= $32
RAWKEY_C		= $33
RAWKEY_V		= $34
RAWKEY_B		= $35
RAWKEY_N		= $36
RAWKEY_M		= $37

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
	dc.l	CHIP_MEMORY_SIZE	; ws_BaseMemSize
	dc.l	0			; ws_ExecInstall
	dc.w	Patch-HEADER		; ws_GameLoader
	dc.w	.dir-HEADER		; ws_CurrentDir
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


.config	dc.b	"C1:B:Disable Blitter Waits"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/WorldCupUSA94/"
	ENDC
	dc.b	"data",0

.name	dc.b	"World Cup USA '94",0
.copy	dc.b	"1994 U.S. Gold",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (27.02.2022)",0

Game_Name	dc.b	"football",0

	CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; load game executable
	lea	Game_Name(pc),a0
	move.l	HEADER+ws_ExpMem(pc),a1
	bsr	Load_File
	move.l	a1,a5

	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$186f,d0			; SPS 0163
	beq.b	.version_ok
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.version_ok

	; relocate game executable
	move.l	a5,a0
	clr.l	-(a7)				; TAG_DONE
	move.l	Chip_Memory(pc),-(a7)		; free chip memory
	pea	WHDLTAG_CHIPPTR
	pea	8.w				; alignment
	pea	WHDLTAG_ALIGN
	move.l	a7,a1
	jsr	resload_Relocate(a2)
	lea	Fast_Memory(pc),a0
	move.l	a5,(a0)
	add.l	d0,(a0)
	move.l	3*4(a7),d0
	add.l	d0,Chip_Memory-Fast_Memory(a0)
	add.w	#5*4,a7

	lea	PLGAME(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

	lea	PLGAME_CHIP(pc),a0
	lea	(CHIP_MEMORY_START).w,a1
	jsr	resload_Patch(a2)


	; set default level 3 interrupt
	pea	AckVBI(pc)
	move.l	(a7)+,$6c.w

	; enable required DMA channels
	move.w	#$83e0,$dff096

	lea	KbdCust(pc),a0
	move.l	a5,a1
	add.w	#$520,a1
	move.l	a1,(a0)
	bsr	Init_Level2_Interrupt
	

	jmp	(a5)


; ---------------------------------------------------------------------------

PLGAME_CHIP
.CHIP_SECTION_START = $38df8

	PL_START
	PL_W	($39640-.CHIP_SECTION_START)+2,$4200
	PL_END

PLGAME	PL_START
	PL_S	$8e4,2			; don't modify VBI code
	PL_P	$638,AckVBI
	PL_SA	$18,$66			; skip OS stuff
	PL_SA	$96,$a8			; skip OS stuff
	PL_SA	$b4,$c0			; don't access gb_copinit
	PL_P	$1fc,.Load_File
	PL_R	$19a			; disable DisownBlitter()
	PL_SA	$1a8,$1ba		; skip Forbid() and OwnBlitter()
	PL_PSS	$432,.Alloc_Chip,2
	PL_PSS	$470,.Alloc_Chip,2
	PL_PSS	$4c0,.Alloc_Fast,2
	PL_SA	$e2,$e8			; skip wrong write to DMACON
	PL_PSS	$28bc,Fix_DMA_Wait,2
	PL_PSS	$28e8,Fix_DMA_Wait,2
	PL_PS	$582,.Get_Key
	PL_P	$39e,.Load_Data
	PL_P	$34a,.Save_Data
	PL_R	$68e8			; disable "Insert Disk" text

	; disable blitter waits if CUSTOM1 has been used
	PL_IFC1
	PL_PS	$a8,.Fix_Blits_NoWait
	
	PL_ELSE
	PL_PS	$a8,.Fix_Blits	
	PL_PS	$44c0,.WaitBlit1
	PL_PS	$89dc,.WaitBlit1
	PL_PS	$10320,.WaitBlit2
	PL_PS	$b9a4,.WaitBlit2
	PL_PS	$ba42,.WaitBlit3
	PL_PS	$48b6,.WaitBlit2
	PL_PS	$4956,.WaitBlit2
	PL_PS	$b97e,.WaitBlit3
	PL_PS	$b878,.WaitBlit2
	PL_PS	$10040,.WaitBlit2
	PL_PS	$100c2,.WaitBlit2
	PL_PS	$10148,.WaitBlit2
	PL_PS	$10268,.WaitBlit2
	PL_PS	$10320,.WaitBlit2
	PL_PS	$2fda,.WaitBlit2
	PL_PS	$2e7e,.WaitBlit2
	PL_PS	$2d3c,.WaitBlit2
	PL_PS	$421c,.WaitBlit2
	PL_PSS	$2fba,.WaitBlit4,2

	PL_PS	$13a02,.WaitBlit2

	PL_PS	$fdde,.WaitBlit2
	PL_PS	$fea8,.WaitBlit2
	PL_PS	$36248,.WaitBlit2
	PL_PSS	$363fe,.WaitBlit6,2
	PL_PS	$3642c,.WaitBlit7
	PL_PS	$36448,.WaitBlit7
	PL_PS	$36464,.WaitBlit7
	PL_PS	$ba82,.WaitBlit2
	PL_ENDIF


	PL_END


.Get_Key
	move.b	Key(pc),d7
	rts

; d0.w: track number
; a0.l: destination

.Load_Data
	bsr.b	.Build_File_Name
	move.l	a0,a1
	lea	.Data_File_Name(pc),a0
	bsr	File_Exists
	tst.l	d0
	beq.b	.no_file
	bsr	Load_File
.no_file
	rts


; d0.w: track number
; a1.l: data to save

.Save_Data
	bsr.b	.Build_File_Name
	lea	.Data_File_Name(pc),a0
	move.l	#$fd0,d0
	move.l	resload(pc),a2
	jmp	resload_SaveFile(a2)

.Build_File_Name
	movem.l	d0/a0/a1,-(a7)
	lea	.Data_File_Num(pc),a0
	moveq	#4-1,d1
.build_name_loop
	moveq	#$f,d2
	and.b	d0,d2

	cmp.b	#9,d2
	ble.b	.ok
	addq.b	#7,d2
.ok
	add.b	#"0",d2
	move.b	d2,(a0,d1.w)

	ror.l	#4,d0
	dbf	d1,.build_name_loop
	movem.l	(a7)+,d0/a0/a1
	rts



.Data_File_Name	dc.b	"WorldCupSave_"
.Data_File_Num	dc.b	"0000",0


.Fix_Blits
	movem.l	d0-a6,-(a7)
	move.l	HEADER+ws_ExpMem(pc),a0
	add.l	#$13a4c,a0
	move.l	a0,a1
	add.l	#$19a68,a1

.loop	cmp.w	#$d842,(a0)		; add.w d2,d4
	bne.b	.next
	cmp.l	#$d3f44000,2(a0)	; add.l (a4,d4.w),a1
	bne.b	.next

	move.w	#$4eb9,(a0)+
	pea	.WaitBlit5(pc)
	move.l	(a7)+,(a0)	


.next	addq.w	#2,a0
	cmp.l	a1,a0
	ble.b	.loop
	movem.l	(a7)+,d0-a6

	lea	$dff000,a0
	rts

.Fix_Blits_NoWait
	movem.l	d0-a6,-(a7)
	move.l	HEADER+ws_ExpMem(pc),a0
	add.l	#$13a4c,a0
	move.l	a0,a1
	add.l	#$19a68,a1

.loop2	cmp.w	#$d842,(a0)		; add.w d2,d4
	bne.b	.next2
	cmp.l	#$d3f44000,2(a0)	; add.l (a4,d4.w),a1
	bne.b	.next2

	move.w	#$4eb9,(a0)+
	pea	.Fix24Bit(pc)
	move.l	(a7)+,(a0)	


.next2	addq.w	#2,a0
	cmp.l	a1,a0
	ble.b	.loop2
	movem.l	(a7)+,d0-a6

	lea	$dff000,a0
	rts

.Fix24Bit
	add.w	d2,d4
	add.l	(a4,d4.l),a1

	move.l	d0,-(a7)
	move.l	a1,d0
	and.l	#$fffff,d0
	move.l	d0,a1
	move.l	(a7)+,d0
	rts



.WaitBlit1
	bsr	WaitBlit
	move.w	#$ffff,$44(a6)
	rts

.WaitBlit2
	lea	$dff000,a6
	bra.w	WaitBlit

.WaitBlit3
	bsr	WaitBlit
	add.l	d2,d4
	move.w	d5,$40(a6)
	rts

.WaitBlit4
	bsr	WaitBlit
	move.w	d5,$40(a6)
	move.w	d6,$42(a6)
	rts

.WaitBlit5
	add.w	d2,d4
	add.l	(a4,d4.l),a1

	move.l	d0,-(a7)
	move.l	a1,d0
	and.l	#$fffff,d0
	move.l	d0,a1
	move.l	(a7)+,d0

	bra.w	WaitBlit


.WaitBlit6
	bsr	WaitBlit
	move.w	d0,$60(a6)
	move.w	d0,$66(a6)
	rts

.WaitBlit7
	add.l	#$2a,a2
	bra.w	WaitBlit


; d0.l: size to allocate
; ----
; d0.l: ptr to allocated chip memory (or 0 if memory could not be allocated)

.Alloc_Chip
	movem.l	d1-a6,-(a7)
	lea	Chip_Memory(pc),a0
	move.l	(a0),d1
	move.l	d1,d2
	add.l	d0,d2
	cmp.l	#CHIP_MEMORY_SIZE,d2
	ble.b	.allocation_ok
.allocation_failed
	moveq	#0,d1			; allocation failed
	bra.b	.exit

.allocation_ok
	move.l	d2,(a0)
.exit	move.l	d1,d0
	movem.l	(a7)+,d1-a6
	rts


; d0.l: size to allocate
; ----
; d0.l: ptr to allocated chip memory (or 0 if memory could not be allocated)

.Alloc_Fast
	movem.l	d1-a6,-(a7)
	lea	Fast_Memory(pc),a0
	move.l	(a0),d1
	move.l	d1,d2
	add.l	d0,d2

	move.l	d2,d3
	sub.l	HEADER+ws_ExpMem(pc),d3
	cmp.l	#FAST_MEMORY_SIZE,d3
	ble.b	.allocation_ok
	bra.b	.allocation_failed



; d0.l: file name
; d1.l: destination
; d2.l: file size
; d3.w: flag (does not seem to be used)

.Load_File
	move.l	d0,a0
	move.l	d1,a1
	bra.w	Load_File


Chip_Memory	dc.l	CHIP_MEMORY_START	; start of free chip memory
Fast_Memory	dc.l	0			; start of free fast memory

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


AckVBI	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte

AckCOP	move.w	#1<<4,$dff09c
	move.w	#1<<4,$dff09c
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

; a0.l: file name
; ----
; d0.l : result (0 = file does not exist)
File_Exists
	movem.l	d1-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	movem.l	(a7)+,d1-a6
	rts	


; ---------------------------------------------------------------------------


; d0.b: rawkey code

Check_Quit_Key
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	rts	

; ---------------------------------------------------------------------------


WaitBlit
	tst.b	$dff002
.wait_blit
	btst	#6,$dff002
	bne.b	.wait_blit
	rts

; ---------------------------------------------------------------------------

Fix_DMA_Wait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d0
.loop	move.b	$dff006,d1
.same_raster_line
	cmp.b	$dff006,d1
	beq.b	.same_raster_line
	dbf	d0,.loop
	movem.l	(a7)+,d0/d1
	rts

; ---------------------------------------------------------------------------
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

	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT

	move.l	(a2)+,d1
	beq.b	.nocustom
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.nocustom
	

.nokeys	moveq	#3-1,d1
.loop	move.b	$6(a0),d0
.wait	cmp.b	$6(a0),d0
	beq.b	.wait
	dbf	d1,.loop


	and.b	#~(1<<6),$e00(a1)	; set input mode
.end	move.w	#1<<3,$9c(a0)
	move.w	#1<<3,$9c(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte



Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine

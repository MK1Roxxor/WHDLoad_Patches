***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/�|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    HELIOPOLIS/EMT DESIGN WHDLOAD SLAVE     )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                               July 2020                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 29-Dec-2020	- disk change works properly now
;		- copperlist 2 ($dff084) handling in bootblock added so
;		  pictures are displayed
;		- unused/unneeded code removed

; 28-Dec-2020	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Exec/Exec.i
	INCLUDE	lvo/Exec.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem
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


HEADER	SLAVE_HEADER		; ws_security + ws_ID
	dc.w	10		; ws_version
	dc.w	FLAGS		; flags
	dc.l	524288		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	IFD	DEBUG
	dc.w	.dir-HEADER	; ws_CurrentDir
	ELSE
	dc.w	0		; ws_CurrentDir
	ENDC
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

; v17
;	dc.w	.config-HEADER	; ws_config


;.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Mirage/ToxicWaste",0
	ENDC

.name	dc.b	"Toxic Waste",0
.copy	dc.b	"1991 Mirage",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (29.12.2020)",0
	CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; install level 2 interrupt
	bsr	SetLev2IRQ


	; load boot
	moveq	#0,d0
	move.l	#512*2,d1
	lea	$2000.w,a0

	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)
	move.l	d5,d0
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$B730,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok


	; create exec.library emulation
	lea	$2000.w,a6
	move.l	a6,$4.w
	bsr	CreateExecLib

	; patch boot
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)	


	; set default interrupts
	pea	AckVBI(pc)
	move.l	(a7)+,$6c.w
	pea	AckLev6(pc)
	move.l	(a7)+,$78.w

	; set copperlist 1 to start copperlist 2
	move.w	#$008a,$1000.w

	; enable needed DMA channels
	move.w	#$83c0,$dff096


	; run demo
	lea	$1000.w,a1		; StdIO
	jmp	3*4(a5)




QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)


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

AckVBI_R
	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rts

AckVBI	bsr.b	AckVBI_R
	rte

AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte

WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts


FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d0
.loop	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait
	dbf	d0,.loop
	movem.l	(a7)+,d0/d1
	rts


FlushCache
	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts


; ---------------------------------------------------------------------------

; Routine creates exec.library emulation code. Routines to emulate
; are specified in a table (.TAB) which has the following format:
; dc.w offset to library routine (relative to .TAB)
; dc.w new routine or 0 to disable the original library routine
; ....
; dc.w 0 to end the table
; 
; a6.l: ExecBase

CreateExecLib
	lea	.TAB(pc),a0
.loop	movem.w	(a0)+,d0/d1
	move.w	#$4ef9,d2		; jmp
	tst.w	d1
	bne.b	.setRoutine
	move.w	#$4e75,d2		; rts

.setRoutine
	lea	(a6,d0.w),a1
	move.w	d2,(a1)+
	pea	.TAB(pc,d1.w)
	move.l	(a7)+,(a1)

	tst.w	(a0)
	bne.b	.loop


	; flush cache
	bra.b	FlushCache



.TAB	dc.w	_LVODoIO,DoIO-.TAB
	dc.w	_LVOForbid,0

	dc.w	0			; end of tab
	

DoIO	movem.l	d0-a6,-(a7)
	cmp.w	#CMD_READ,IO_COMMAND(a1)
	bne.b	.exit

	move.l	IO_OFFSET(a1),d0
	move.l	IO_LENGTH(a1),d1
	move.l	IO_DATA(a1),a0
	move.b	DiskNum(pc),d2		; disk number
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)


.exit	movem.l	(a7)+,d0-a6
	rts


DiskNum	dc.b	1
	dc.b	0

; ---------------------------------------------------------------------------

PLBOOT	PL_START
	PL_P	$18a,.PatchIntro
	PL_ORW	$19a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1ce+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1de+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$20e+2,1<<9		; set Bplcon0 color bit
	PL_END


.PatchIntro
	lea	PLINTRO(pc),a0
	pea	$10000
PatchAndRun
	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)




; ---------------------------------------------------------------------------

PLINTRO	PL_START
	PL_ORW	$352+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$562+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$5b2+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$642+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$696+2,1<<9		; set Bplcon0 color bit
	PL_P	$2ba,AckVBI
	PL_ORW	$1e+2,1<<3		; enable level 2 interrupts
	PL_ORW	$3e+2,1<<9		; set Bplcon0 color bit
	PL_P	$de,.PatchMain
	PL_PS	$58,.SetVPOS
	PL_ORW	$3f2+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$402+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$44a+2,1<<9		; set Bplcon0 color bit
	PL_END

.SetVPOS
	move.w	$dff004,d0		; VPOSR
	or.w	#1<<15,d0		; set LOF bit
	move.w	d0,$dff02a		; VPOSW
	rts

.PatchMain
	move.w	#$4e75,$1f000+$11a	; disable jmp $20000
	bsr	FlushCache
	jsr	$1f020			; decrunch

	lea	PLMAIN(pc),a0
	pea	$20000
	bra.w	PatchAndRun
	


; ---------------------------------------------------------------------------

PLMAIN	PL_START
	PL_PSS	$10fa,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$1110,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$183a,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$1850,FixDMAWait,2	; fix DMA wait in replayer
	PL_SA	$47a,,$4c6		; skip drive access
	PL_ORW	$2984+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$29c0+2,1<<9		; set Bplcon0 color bit
	PL_PS	$634,.SetDisk
	PL_END


.SetDisk
	moveq	#2,d0
	cmp.b	#2,$20000+$e15
	bgt.b	.use_disk2
	moveq	#1,d0
.use_disk2

	lea	DiskNum(pc),a0
	move.b	d0,(a0)
	rts



; ---------------------------------------------------------------------------

***********************************
*** Level 2 IRQ			***
***********************************

SetLev2IRQ
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
	move.b	$c00(a1),d0
	move.b	d0,(a2)

	not.b	d0
	ror.b	d0
	move.b	d0,RawKey-Key(a2)


	move.l	KbdCust(pc),d1
	beq.b	.noCust
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.noCust


	or.b	#1<<6,$e00(a1)			; set output mode

	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT

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
KbdCust	dc.l	0

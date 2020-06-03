***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    LOST TRACK/ILLUSION WHDLOAD SLAVE       )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                               June 2020                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 03-Jun-2020	- work started
;		- and finished about 2 hours later, OS stuff patched,
;		  memory check fixed, INTENA and DMA settings fixed,
;		  interrupts fixed, SMC fixed, illegal BPLCON2
;		  settings fixed (x6), Bplcon0 color bit fixes (x17),
;		  line drawing routine fixed, DMA wait in replayer
;		  fixed (x12), byte write to $dff1f0 fixed (x18),
;		  copperlist bug fixed, support for hidden part added


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Exec/Exec.i
	INCLUDE	lvo/Exec.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem
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


HEADER	SLAVE_HEADER		; ws_security + ws_ID
	dc.w	17		; ws_version
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
	dc.l	524288		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"C1:B:Run Hidden Part"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Illusion/LostTrack",0
	ENDC

.name	dc.b	"Lost Track",0
.copy	dc.b	"1993 Illusion",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (03.06.2020)",0
	CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; install level 2 interrupt
	bsr	SetLev2IRQ

	lea	$1000.w,a7


	; load demo
	move.l	#$11800,d0
	move.l	#$4600,d1
	lea	$15000,a0

	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)
	move.l	d5,d0
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$CDE6,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

	; create fake Exec
	lea	$2000.w,a6
	move.l	a6,$4.w

	bsr	BuildExec


	; patch
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	pea	AckVBI(pc)
	move.l	(a7)+,$6c.w

	; set correct INTENA and DMA
	move.w	#$c028,$dff09a
	move.w	#$83e0,$dff096

	; and run
	jmp	(a5)




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



; ---------------------------------------------------------------------------
; Exec emulation, routine creates a fake exec library. Routines to emulate
; or disable are taken from table ".TAB". Format of the table is as follows:
;
; dc.w library offset
; dc.w offset to new routine or 0 (0: just disable routine)
; ...
; dc.w 0 to terminate table
;
; After calling this routine it is required to flush the cache so it's best
; to call it before resload_Patch (as that one does a cache flush).


BuildExec
	move.l	$4.w,a6
	lea	.TAB(pc),a0
.loop	movem.w	(a0)+,d0/d1

	lea	(a6,d0.w),a1
	tst.w	d1
	bne.b	.SetNewRoutine
	move.w	#$4e75,(a1)		; disable
	bra.b	.next


.SetNewRoutine
	move.w	#$4ef9,(a1)+
	lea	.TAB(pc,d1.w),a2
	move.l	a2,(a1)


.next	tst.w	(a0)
	bne.b	.loop
	rts

.TAB	dc.w	_LVODoIO,DoIO-.TAB

	dc.w	_LVOOpenDevice,0
	dc.w	_LVOCloseDevice,0
	dc.w	_LVOFindTask,0
	dc.w	_LVOAddPort,0
	dc.w	_LVORemPort,0

	dc.w	0			; end of table


DoIO	movem.l	d0-a6,-(a7)
	cmp.w	#CMD_READ,IO_COMMAND(a1); only CMD_READ is supported
	bne.b	.exit
	move.l	IO_OFFSET(a1),d0	; offset
	move.l	IO_LENGTH(a1),d1	; length
	move.l	IO_DATA(a1),a0
	move.b	DiskNum(pc),d2
	move.l	resload(pc),a1
	jsr	resload_DiskLoad(a1)
.exit	movem.l	(a7)+,d0-a6
	rts

DiskNum	dc.b	1
	dc.b	0

; ---------------------------------------------------------------------------

PLBOOT	PL_START

	; enable hidden part if CUSTOM1 is used
	PL_IFC1
	PL_B	$a,$60
	PL_ENDIF

	PL_P	$94,.SetExtMem
	PL_ORW	$470+4,1<<9		; set Bplcon0 color bit
	PL_ORW	$5a2+4,1<<9		; set Bplcon0 color bit
	PL_PS	$38,.PatchIntro
	PL_PS	$46,.PatchMain

	PL_W	$502+4,$24		; fix Bplcon2 value
	PL_PS	$582,FixBplcon0

	PL_W	$3e,$4e71		; disable jsr (a0)

	PL_P	$56,.PatchHiddenPart
	PL_END

.SetExtMem
	move.l	HEADER+ws_ExpMem(pc),$15000+$fc
	rts


.PatchIntro
	move.l	HEADER+ws_ExpMem(pc),a0
	bsr.b	.Decrunch

	lea	PLINTRO(pc),a0
.Patch	pea	$20000
.Run	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)


.PatchMain
	add.l	#$22000,a0
	bsr.b	.Decrunch

	lea	PLMAIN(pc),a0
	bra.b	.Patch


.Decrunch
	move.w	#$4e75,$104(a0)		; disable jmp $20000
	move.w	#$6004,$62(a0)		; skip move.b d3,$dff1f0
	
	bsr.b	.flush
	jmp	(a0)			; decrunch


.flush	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts

.PatchHiddenPart
	lea	PLHIDDEN(pc),a0
	pea	$30000
	bra.b	.Run


FixBplcon0
	;lsl.w	#8,d0
	;lsl.w	#4,d0
	ror.w	#4,d0			; optimised original code :)
	or.w	#1<<9,d0		; set Bplcon0 color bit
	move.w	d0,(a1)+
	rts


; ---------------------------------------------------------------------------

PLINTRO	PL_START
	PL_PSS	$956,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$96c,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$10b2,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$10c8,FixDMAWait,2	; fix DMA wait in replayer

	PL_P	$61a,AckVBI
	PL_SA	$600,$608		; don't modify VBI code

	PL_ORW	$47c+4,1<<9		; set Bplcon0 color bit
	PL_ORW	$5a8+4,1<<9		; set Bplcon0 color bit
	PL_ORW	$5bc+4,1<<9		; set Bplcon0 color bit
	
	PL_W	$508+4,$24		; fix Bplcon2 value
	PL_PS	$588,FixBplcon0

	PL_L	$5ce+2,$6f00		; set correct copperlist address
	PL_END
	

; ---------------------------------------------------------------------------

PLMAIN	PL_START
	PL_PSS	$24d2,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$24e8,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$2c28,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$2c3e,FixDMAWait,2	; fix DMA wait in replayer

	PL_P	$428,.SetExtMem

	PL_P	$afa,AckVBI
	PL_SA	$a66,$a6e		; don't modify VBI code
	PL_P	$af4,AckLev6
	PL_SA	$aa6,$aae		; don't modify level 6 interrupt code
	

	PL_ORW	$716+4,1<<9		; set Bplcon0 color bit
	PL_ORW	$868+4,1<<9		; set Bplcon0 color bit
	PL_ORW	$93e+4,1<<9		; set Bplcon0 color bit
	PL_ORW	$a34+4,1<<9		; set Bplcon0 color bit

	PL_P	$1d32,.SetDiskNum
	
	PL_W	$7cc+4,$24		; fix Bplcon2 value
	PL_W	$8b2+4,$24		; fix Bplcon2 value
	PL_W	$982+4,$24		; fix Bplcon2 value
	PL_PS	$84c,FixBplcon0
	PL_PS	$92c,FixBplcon0
	PL_PS	$a0a,FixBplcon0

	PL_PS	$20ce,.FixDecruncher
	PL_END
	
.SetExtMem
	move.l	HEADER+ws_ExpMem(pc),$20000+$490
	rts

.SetDiskNum
	move.l	$20000+$2116,d0
	lea	DiskNum(pc),a0
	move.b	d0,(a0)
	rts

.FixDecruncher
	move.l	HEADER+ws_ExpMem(pc),a0
	move.w	#$6004,$62(a0)		; skip move.b d3,$dff1f0
	rts	


; ---------------------------------------------------------------------------

PLHIDDEN
	PL_START
	PL_PSS	$102e,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$1044,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$1778,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$178e,FixDMAWait,2	; fix DMA wait in replayer

	PL_P	$cb2,AckVBI
	PL_SA	$c72,$c7a		; don't modify VBI code

	PL_W	$26a+4,$24		; fix Bplcon2 value
	PL_ORW	$1de+4,1<<9		; set Bplcon0 color bit
	PL_ORW	$34c+4,1<<9		; set Bplcon0 color bit
	PL_PS	$33a,FixBplcon0

	PL_P	$90,QUIT

	PL_PS	$3da,.FixLine
	PL_END


.FixLine
	moveq	#40,d4
	moveq	#0,d7			; initialise BLTCON1 register
	rts


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

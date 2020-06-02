***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   AURAL ILLUSIONS/GENOCIDE WHDLOAD SLAVE   )*)---.---.   *
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

; 02-Jun-2020	- work started
;		- and finished some hours later, all OS stuff patched/emulated
;		  (DoIO, AddIntServer, CopyMem etc.), long write to
;		  BLTDMOD fixed (x2), access fault fixed, Bplcon0 color bit
;		  fix, DMA settings fixed, timing fixed, support for
;		  hidden part added


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Exec/Exec.i
	INCLUDE	lvo/Exec.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem
QUITKEY		= $46		; Del
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


.config	dc.b	"C1:B:Run Bonus Track"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Genocide/AuralIllusions",0
	ENDC

.name	dc.b	"Aural Illusions",0
.copy	dc.b	"1992 Genocide",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (02.06.2020)",0
	CNOP	0,4

TAGLIST	dc.l	WHDLTAG_CUSTOM1_GET
BONUS	dc.l	0
	dc.l	TAG_DONE


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; install level 2 interrupt
	bsr	SetLev2IRQ

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

	; load demo
	move.l	#$400,d0
	move.l	#$9200,d1
	lea	$60000,a0
	lea	PLINTRO(pc),a3

	move.l	BONUS(pc),d2
	beq.b	.noBonusTrack
	move.l	#$1f400,d0
	move.l	#$1fc00,d1
	lea	$50000,a0
	lea	PLBONUS(pc),a3
.noBonusTrack


	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)
	move.l	d5,d0
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$21FC,d0
	beq.b	.ok
	cmp.w	#$99A1,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

	; create fake Exec
	lea	$2000.w,a6
	move.l	a6,$4.w

	bsr	BuildExec


	; patch
	move.l	a3,a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	pea	AckVBI(pc)
	move.l	(a7)+,$6c.w


	lea	$1004.w,a1		; StdIo
	move.l	a1,$108.w

	move.l	HEADER+ws_ExpMem(pc),$100.w

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

WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
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
	dc.w	_LVOAddIntServer,AddIntServer-.TAB
	dc.w	_LVORemIntServer,RemIntServer-.TAB
	dc.w	_LVOOpenLibrary,OpenLibrary-.TAB
	dc.w	_LVOCopyMem,CopyMem-.TAB

	dc.w	_LVOCloseLibrary,0
	dc.w	_LVOOpenDevice,0
	dc.w	_LVOCloseDevice,0
	dc.w	_LVOFindTask,0
	dc.w	_LVOAddPort,0
	dc.w	_LVORemPort,0
	dc.w	_LVOForbid,0

	dc.w	0			; end of table


DoIO	movem.l	d0-a6,-(a7)
	cmp.w	#CMD_READ,IO_COMMAND(a1); only CMD_READ is supported
	bne.b	.exit
	move.l	IO_OFFSET(a1),d0	; offset
	move.l	IO_LENGTH(a1),d1	; length
	move.l	IO_DATA(a1),a0
	moveq	#1,d2
	move.l	resload(pc),a1
	jsr	resload_DiskLoad(a1)
.exit	movem.l	(a7)+,d0-a6
	rts

AddIntServer
	cmp.w	#5,d0			; only VBI is supported
	bne.b	.exit

	lea	.VBIcust(pc),a0
	move.l	IS_CODE(a1),(a0)

	; set new VBI
	pea	.VBI(pc)
	move.l	(a7)+,$6c.w

	; and enable it
	move.w	#$c020,$dff09a

.exit	rts


.VBI	movem.l	d0-a6,-(a7)

	move.l	.VBIcust(pc),d0
	beq.b	.noVBIcust

	move.l	d0,a0
	jsr	(a0)

.noVBIcust

	movem.l	(a7)+,d0-a6
	bra.w	AckVBI



.VBIcust	dc.l	0


RemIntServer
	cmp.w	#5,d0			; only VBI is supported
	bne.b	.exit

	pea	AckVBI(pc)
	move.l	(a7)+,$6c.w
	move.w	#$20,$dff09a

.exit	rts


OpenLibrary
	lea	$2000.w,a0		; GfxBase
	move.l	a0,d0
	move.l	#$1000,$26(a0)		; gb_copinit = default copperlist
	rts



; a0.l: source
; a1.l: dest
; d0.l: size

CopyMem	tst.l	d0
	beq.b	.exit

.copy	move.b	(a0)+,(a1)+
	subq.l	#1,d0
	bne.b	.copy

.exit	rts


; ---------------------------------------------------------------------------

PLINTRO	PL_START
	PL_PS	$c,.PatchIntro
	PL_END
	

.PatchIntro
	lea	PLINTRO_DEC(pc),a0
	pea	$20000

PatchAndRun
	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)


PLINTRO_DEC
	PL_START
	PL_PS	$110,.PatchPreDemo
	PL_PSA	$96,WaitRaster,$a0
	PL_PSA	$ce,WaitRaster,$d8
	PL_END

.PatchPreDemo
	lea	PLPREDEMO(pc),a0
	pea	$50000
	bra.b	PatchAndRun



; ---------------------------------------------------------------------------

PLPREDEMO
	PL_START
	PL_PS	$120,.PatchDemo
	PL_ORW	$8c64+2,1<<9		; set Bplcon0 color bit
	PL_END
	

.PatchDemo
	lea	PLDEMO(pc),a0
	pea	$1a000
	bra.b	PatchAndRun


; ---------------------------------------------------------------------------


PLDEMO	PL_START
	PL_L	$4c,$4e714e71		; disable OpenDevice() result check
	PL_PSS	$3956,.FixBlit,2	; fix long write to BLTDMOD
	PL_PSS	$3a26,.FixBlit,2	; fix long write to BLTDMOD
	PL_R	$4c0			; disable Action Replay killer
	PL_AL	$4e6+2,-$1000		; fix length for CopyMem
	PL_END

.FixBlit
	move.w	#0,$66(a5)
	rts

; ---------------------------------------------------------------------------

PLBONUS	PL_START
	PL_PSA	$0,.DisableDMA,32
	PL_P	$188+32,.Patch
	PL_END


.DisableDMA
	move.w	#$7ff,$dff096
	rts

.Patch	move.w	#$83c0,$dff096
	lea	PLBONUS_DEC(pc),a0
	pea	$20000
	bra.w	PatchAndRun

PLBONUS_DEC
	PL_START
	PL_END


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

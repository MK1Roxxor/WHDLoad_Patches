***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*( KREST MASS LEFTOVERS/ANARCHY WHDLOAD SLAVE )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             October 2014                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 01-Jun-2020	- ws_keydebug handling removed from keyboard interrupt
;		- some unused code removed

; 05-Oct-2014	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
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


;.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Anarchy/KrestMassLeftovers/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Krest Mass Leftovers",0
.copy	dc.b	"1992 Anarchy",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.1 (01.06.2020)",0
Name	dc.b	"loader",0
	CNOP	0,2


TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	TAG_END

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

; install keyboard irq
	bsr	SetLev2IRQ

	lea	$1000.w,a7

; load main
	lea	Name(pc),a0
	lea	$10000,a1
	move.l	a1,a5
	jsr	resload_LoadFileDecrunch(a2)

	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$2ca4,d0
	beq.b	.ok

.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

; patch
	lea	PLLOADER(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)


; set default VBI+level 6 interrupt
	lea	AckVBI(pc),a0
	move.l	a0,$6c.w
	lea	AckLev6(pc),a0
	move.l	a0,$78.w

; set default DMA
	move.w	#$83c0,$dff096

; and start demo
	jmp	(a5)




QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)


KillSys	move.w	#$7fff,$dff09a
	bsr	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	rts

AckVBI	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rte

AckLev6	tst.b	$bfdd00
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte


PLLOADER
	PL_START
	PL_R	$39b4		; disable directory loading/loader init
	PL_P	$3676,.loadfile
	PL_P	$33d8,AckLev6
	PL_P	$342e,AckLev6
	PL_SA	$de,$e4		; don't disable interrupts
	PL_PS	$5a6,.patchtrail
	PL_PS	$5f8,.patchdglenz
	PL_PS	$694,.patchjelly
	PL_R	$36f0
	PL_END



.loadfile
	move.w	#150-1,d7
.loop	bsr	WaitRaster
	jsr	$10000+$36ce
	dbf	d7,.loop

	exg	a0,a1
	move.l	resload(pc),a2
	jmp	resload_LoadFileDecrunch(a2)

.patchjelly
	lea	PLJELLY(pc),a0
	bra.b	.patch2k

.patchdglenz
	lea	PLDGLENZ(pc),a0
.patch2k
	pea	$20000
	bra.b	.patch

.patchtrail
	lea	PLTRAIL(pc),a0
	pea	$24000

.patch	move.l	(a7),a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)


PLTRAIL	PL_START
	PL_PS	$1314,.fixline	; fix byte write to $dff043
	PL_PS	$13bc,.fixline2	; fix byte write to $dff043
	PL_PS	$13ee,.fixline2	; fix byte write to $dff043
	PL_END

.fixline
	move.l	a5,-(a7)
	lea	$24000+$132e,a5
	move.b	(a5,d6.w),d6	; d6 fully cleared before!
	move.w	d6,$42(a6)
	move.l	(a7)+,a5
	rts

.fixline2
	move.l	a5,-(a7)
	lea	$24000+$1408,a5
	move.b	(a5,d6.w),d6	; d6 fully cleared before!
	move.w	d6,$42(a6)
	move.l	(a7)+,a5
	rts

PLDGLENZ
	PL_START
	PL_PS	$cc2,.fixline	; fix byte write to $dff043
	
	PL_END

.fixline
	move.l	a5,-(a7)
	lea	$20000+$cdc,a5
	move.b	(a5,d6.w),d6	; d6 fully cleared before!
	move.w	d6,$42(a6)
	move.l	(a7)+,a5
	rts

PLJELLY	PL_START
	PL_PS	$e18,.fixline	; fix byte write to $dff043
	PL_PS	$ec0,.fixline2	; fix byte write to $dff043
	PL_PSS	$398,.wblit1,2
	PL_END

.wblit1	tst.b	$02(a6)
.wb	btst	#6,$02(a6)
	bne.b	.wb
	move.l	$20000+$d82,$54(a6)
	rts

.fixline
	move.l	a5,-(a7)
	lea	$20000+$e32,a5
	move.b	(a5,d6.w),d6	; d6 fully cleared before!
	move.w	d6,$42(a6)
	move.l	(a7)+,a5
	rts

.fixline2
	move.l	a5,-(a7)
	lea	$20000+$eda,a5
	move.b	(a5,d6.w),d6	; d6 fully cleared before!
	move.w	d6,$42(a6)
	move.l	(a7)+,a5
	rts


WaitRaster
	move.l	d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.b	.wait
.wait2	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	beq.b	.wait2
	move.l	(a7)+,d0
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
	beq.w	.end

	btst	#3,$d00(a1)			; KBD irq?
	beq.b	.end

	moveq	#0,d0
	move.b	$c00(a1),d0
	lea	Key(pc),a2
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)

	move.l	KbdCust(pc),d1
	beq.b	.nocustom
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.nocustom	
	


	or.b	#1<<6,$e00(a1)			; set output mode


.nodebug
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
KbdCust	dc.l	0			; ptr to custom routine





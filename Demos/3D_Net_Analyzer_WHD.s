***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    3D NET ANALYZER/DOC WHDLOAD SLAVE      )*)---.---.    *
*   `-./                                                          \.-'    *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              July 2013                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 17-Aug-2023	- level 3 interrupt vector is now initialised before
;		  starting the demo (issue #6222)
;		- ws_keydebug handling removed from keyboard interrupt

; 18-Aug-2015	- some unused/not needed code removed
;		- directory name wasn't null-terminated in non DEBUG mode

; 17-Aug-2015	- keyboard handling improved
;		- offset for loader patch corrected
;		- "safe" DMA wait fix added
;		- quitkey changed to escape since F10/Del etc. are
;		  used in the demo
;		- SMC fixes removed as there's too much SMC in the demo,
; 		  instruction cache is now disabled

; 25-Jul-2013	- rainy day here in Serams so I continued work on the patch
;		- started to fix all self-modifying code
;

; 19-Jul-2013	- work started

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	hardware/intbits.i
	

FLAGS		= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
DEBUGKEY	= $58		; F9
QUITKEY		= $45		; Escape
;DEBUG

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM


HEADER	SLAVE_HEADER		; ws_security + ws_ID
	dc.w	10		; ws_version
	dc.w	FLAGS		; flags
	dc.l	524288		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	dc.w	.dir-HEADER	; ws_CurrentDir
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_keydebug
	dc.b	QUITKEY		; ws_keyexit
	dc.l	0		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info


	IFD	DEBUG
.dir	dc.b	"SOURCES:WHD_Slaves/Demos/DOC/3DNetAnalyzer/"
	ENDC
.dir	dc.b	"data",0
.name	dc.b	"3D-Net Analyzer",0
.copy	dc.b	"1989 Doctor Mabuse Orgasm Crackings",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"Debug!!! "
	ENDC
	dc.b	"Version 1.01 (17.08.2023)",0
FileName	dc.b	"6",0
	CNOP	0,2


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2


; install keyboard irq
	bsr	SetLev2IRQ

; load main
	lea	$18000,a1
	bsr	LoadFile
	
; version check
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$2f6e,d0
	beq.b	.ok

; unknown version
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT
	

; decrunch and patch main part
.ok	move.l	a5,a0
	add.l	#$8d42,a0		; end of crunched data
	lea	$24000,a1		; destination
	move.l	a1,a5
	bsr	BK_DECRUNCH
	lea	PLMAIN(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

; set default DMA
	move.w	#$83c0,$dff096

; disable cache
	moveq	#0,d0			; new status: I+D cache off
.on	move.l	d0,d1			; status to change
	jsr	resload_SetCACR(a2)


	; Initialise level 3 interrupt vector
	pea	Acknowledge_Level3_Interrupt(pc)
	move.l	(a7)+,$6c.w
	

; and start
	jmp	(a5)

; a1: destination
LoadFile
	lea	FileName(pc),a0
	move.l	a1,a5
	move.l	resload(pc),a2
	jmp	resload_LoadFile(a2)



QUIT	pea	(TDREASON_OK).w
EXIT	bsr.b	KillSys
	move.l	resload(pc),a2
	jmp	resload_Abort(a2)

KillSys	move.w	#$7fff,$dff09a
	bsr	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	rts

PLMAIN	PL_START
	PL_R	$59152			; disable "step to track 0"
	PL_W	$2044,0			; song 1 -> song 0
	PL_PS	$ba,.loadsong		; load song 1
	PL_ORW	$d0+2,1<<3		; enable level 2 interrupt
	PL_PSS	$13ea,FixDMAWait,2	; fix DMA wait in replayer
	PL_PS	$15b8,FixAudXVol	; fix byte write to volume register
	PL_PS	$18e,.loadsong
	PL_SA	$18e+6,$1a8
	PL_ORW	$1b2+2,1<<3		; enable level 2 interrupt
	PL_P	$fac,.getkey
	PL_ORW	$c8+2,1<<9		; set DMA enable bit
	PL_END



.getkey	lea	RawKey(pc),a0
	move.b	(a0),d0
	clr.b	(a0)
	rts


.loadsong
	move.w	$24000+$2044,d0		; song number
	add.b	#"0",d0
	lea	FileName(pc),a0
	move.b	d0,(a0)
	lea	$24000+$1c000,a1
	bra.w	LoadFile


FixAudXVol
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts

FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d1	
.loop	move.b	$dff006,d0
.wait	cmp.b	$dff006,d0
	beq.b	.wait
	dbf	d1,.loop
	movem.l	(a7)+,d0/d1
	rts

WaitRaster
.loop	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.b	.loop
	rts


***********************************
*** Level 2 IRQ			***
***********************************

SetLev2IRQ
	pea	Lev2(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode

	move.w	#1<<3,$dff09c			; clear ports interrupt
	move.w	#1<<15|1<<14|1<<3,$dff09a	; and enable it
	rts

Lev2	movem.l	d0-d1/a0-a2,-(a7)
	lea	$dff000,a0
	lea	$bfe001,a1

	btst	#3,$1e+1(a0)			; PORTS irq?
	beq.b	.end
	btst	#3,$d00(a1)			; KBD irq?
	beq.b	.end

	lea	Key(pc),a2
	move.b	$c00(a1),d0
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)

	or.b	#1<<6,$e00(a1)			; set output mode


	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	.exit
	

.nokeys
	moveq	#3-1,d1
.loop	move.b	$6(a0),d0
.wait	cmp.b	$6(a0),d0
	beq.b	.wait
	dbf	d1,.loop


	and.b	#~(1<<6),$e00(a1)	; set input mode
.end	move.w	#1<<3,$9c(a0)
	move.w	#1<<3,$9c(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte

.exit	pea	(TDREASON_OK).w
.quit	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts


Key	dc.b	0
RawKey	dc.b	0



; Bytekiller decruncher
; resourced and adapted by stingray
;
BK_DECRUNCH
	bsr.b	.decrunch
	tst.l	d5
	beq.b	.ok

; checksum doesn't match, file corrupt
	pea	.ErrTxt(pc)
	pea	(TDREASON_FAILMSG).w
	move.l	resload(pc),a0
	jmp	resload_Abort(a0)


.ok	rts

.ErrTxt	dc.b	"Decrunching failed, file corrupt!",0
	cnop	0,4

.decrunch
	move.l	-(a0),a2
	add.l	a1,a2
	move.l	-(a0),d5		; checksum
	move.l	-(a0),d0		; get first long
	eor.l	d0,d5
.loop	lsr.l	#1,d0
	bne.b	.nonew1
	bsr.b	.nextlong
.nonew1	bcs.b	.getcmd

	moveq	#8,d1
	moveq	#1,d3
	lsr.l	#1,d0
	bne.b	.nonew2
	bsr.b	.nextlong
.nonew2	bcs.b	.copyunpacked

; data is packed, unpack and copy
	moveq	#3,d1			; next 3 bits: length of packed data
	clr.w	d4

; d1: number of bits to get from stream
; d4: length
.packed	bsr.b	.getbits
	move.w	d2,d3
	add.w	d4,d3
.copypacked
	moveq	#8-1,d1
.getbyte
	lsr.l	#1,d0
	bne.b	.nonew3
	bsr.b	.nextlong
.nonew3	roxl.l	#1,d2
	dbf	d1,.getbyte

	move.b	d2,-(a2)
	dbf	d3,.copypacked
	bra.b	.next

.ispacked
	moveq	#8,d1
	moveq	#8,d4
	bra.b	.packed

.getcmd	moveq	#2,d1			; next 2 bits: command
	bsr.b	.getbits
	cmp.b	#2,d2			; %10: unpacked data follows
	blt.b	.notpacked
	cmp.b	#3,d2			; %11: packed data follows
	beq.b	.ispacked

; %10
	moveq	#8,d1			; next byte:
	bsr.b	.getbits		; length of unpacked data
	move.w	d2,d3			; length -> d3
	moveq	#12,d1
	bra.b	.copyunpacked

; %00 or %01
.notpacked
	moveq	#9,d1
	add.w	d2,d1
	addq.w	#2,d2
	move.w	d2,d3

.copyunpacked
	bsr.b	.getbits		; get offset (d2)
;.copy	subq.w	#1,a2
;	move.b	(a2,d2.w),(a2)
;	dbf	d3,.copy

; optimised version of the code above
	subq.w	#1,d2
.copy	move.b	(a2,d2.w),-(a2)
	dbf	d3,.copy

.next	cmp.l	a2,a1
	blt.b	.loop
	rts

.nextlong
	move.l	-(a0),d0
	eor.l	d0,d5
	move.w	#$10,ccr
	roxr.l	#1,d0
	rts

; d1.w: number of bits to get
; ----
; d2.l: bit stream

.getbits
	subq.w	#1,d1
	clr.w	d2
.getbit	lsr.l	#1,d0
	bne.b	.nonew
	move.l	-(a0),d0
	eor.l	d0,d5
	move.w	#$10,ccr
	roxr.l	#1,d0
.nonew	roxl.l	#1,d2
	dbf	d1,.getbit
	rts


; ---------------------------------------------------------------------------

Acknowledge_Level3_Interrupt
	move.w	#INTF_COPER|INTF_BLIT|INTF_VERTB,$dff09c
	move.w	#INTF_COPER|INTF_BLIT|INTF_VERTB,$dff09c
	rte	

***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(  LOTHAR MATTHÄUS SUPER SOCCER WHDLOAD SLAVE )*)---.---.  *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              April 2020                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 02-Apr-2020	- 68000 quitkey support for match added

; 01-Apr-2020	- work started, adapted from my Manchester United: The Double
;		  slave

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
DEBUGKEY	= $58		; F9
QUITKEY		= $59		; F10
DEBUG

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
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
	dc.l	524288*2		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"C1:B:Disable Data Disk Creation"
	dc.b	0


	IFD	DEBUG
.dir	dc.b	"SOURCES:WHD_Slaves/LotharSuperSoccer/",0
	ENDC
.name	dc.b	"Lothar Matthäus Super Soccer",0
.copy	dc.b	"1994 Krisalis",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	dc.b	"Version 1.00 (02.04.2020)",0
	CNOP	0,2

TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUTYPE		dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
NODATADISK	dc.l	0		; don't create data disk

		dc.l	TAG_END

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


; install keyboard irq
	bsr	SetLev2IRQ

; load boot
	moveq	#0,d0
	move.l	#1024,d1
	lea	$70000,a5
	move.l	a5,a0
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)

; version check
	move.l	a5,a0
	move.l	#1024,d0
	jsr	resload_CRC16(a2)
	lea	PLBOOT_1728(pc),a4
	cmp.w	#$1c24,d0		; SPS 1728
	beq.b	.is1728

; unknown version
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
	


; load first file
.is1728	lea	$75000+$100,a0
	move.l	#$400,d0
	move.l	#$c00,d1
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)


; patch boot
	move.l	a4,a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

; patch first file
	lea	PLFIRST_1728(pc),a0
	lea	$75000+$100,a1
	jsr	resload_Patch(a2)


	move.l	NODATADISK(pc),d0
	bne.b	.nodatadisk
	bsr	CreateDataDisk		; create data disk if it doesn't exist
.nodatadisk

; start game
	move.l	#$75000,d0

	jmp	$2a(a5)

	

QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	jmp	resload_Abort(a2)


; first: $a7400
PLBOOT_1728
	PL_START
	PL_SA	$30,$72			; skip trackdisk stuff
	PL_R	$26a			; GetCPU
	PL_P	$1bc,.mem
	PL_R	$202			; sort memlist by priority
	PL_END

.mem	moveq	#0,d1			; start of chip
	move.l	#$80000,d2		; size
	move.l	d1,$10(a5)
	move.l	d2,$14(a5)
	move.l	HEADER+ws_ExpMem(pc),$20(a5)
	move.l	#$80000*2,$24(a5)
	rts

PLFIRST_1728
	PL_START
	PL_R	$722			; loader init
	PL_P	$778,.load
	PL_R	$7fc			; drive check/init
	PL_P	$f8,.patchgame
	PL_END

.patchgame
	jsr	$78000+$2a6
	move.l	d0,a5
	lea	PLGAME_1728(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	(a5)



.load	move.l	d0,a0
	move.l	d2,d0
	mulu.w	#512,d0
	moveq	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	moveq	#0,d0			; no errors
	rts


PLGAME_1728
	PL_START
	PL_L	$c4,$70004e75		; cpu check
	PL_P	$1206,Loader

	PL_L	$116e,$b6834e71		; cmp.l d3,d3 -> correct disk in drive
	PL_P	$128c,SaveData

	PL_R	$1338			; drive stuff


	PL_R	$1814			; drive stuff


	PL_W	$2366,$4e71		; disk in drive

	;PL_R	$14da			; drive stuff
	PL_R	$16a8			; drive stuff
	PL_R	$19ae			; get available drives

	PL_R	$1628			; drive stuff

	PL_PS	$23cc,Loader		; load dir
	PL_SA	$23cc+6,$2412

	PL_SA	$1148,$1160		; skip "disk in df0:" check


	PL_R	$189f6			; disable chipset check

	PL_P	$18980,memend

	PL_PS	$1be,keys

	PL_P	$3266,DECRUNCH

	PL_P	$32c,AckLev6
	PL_R	$187c4			; disable video mode check
	PL_R	$189f6			; disable chipset check
	PL_R	$17a98			; disable write to Bplcon4


	PL_P	$372,.snoop		; make snoop work on 68060

	PL_SA	$1776,$179a		; skip drive access
	PL_END

.snoop	move.w	(a7)+,d0
	move.w	d0,$dff09c
	move.w	d0,$dff09c
	trap	#0
	movem.l	(a7)+,d0-a6
	rte	

PLMATCH_1728
	PL_START
	PL_PS	$7eee,.CheckQuit
	PL_END


.CheckQuit
	moveq	#0,d0
	move.b	$c00(a1),d0
	move.w	d0,-(a7)
	ror.b	d0
	not.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	move.w	(a7)+,d0
	rts



AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte


keys	move.b	$c00(a1),d0
	not.b	d0
	move.b	d0,d1
	ror.b	#1,d1
	cmp.b	HEADER+ws_keyexit(pc),d1	
	beq.w	QUIT
	rts

memend	move.l	#$100000/2,d1
	rts


; MU3P: program disk
; MU3A: data disk
; MU3S: save disk

Loader	move.l	d0,a0
	move.l	d2,d0
	mulu.w	#512,d0
	moveq	#1,d2
	cmp.l	#"MU3P",d3		; program disk
	beq.b	.diskok
	moveq	#2,d2
	cmp.l	#"MU3A",d3		; data disk
	beq.b	.diskok
	moveq	#3,d2
	cmp.l	#"MU3S",d3		; save disk
	bne.b	.error			; unknown disk

.diskok	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	moveq	#0,d0			; no errors
	rts
.error	moveq	#-1,d0
	rts

.disk	dc.b	1,0




SaveData
	cmp.w	#18,d1
	bne.b	.nokludge
	move.w	#512,d1			; save complete directory
.nokludge
	move.l	d0,a1			; buffer
	move.l	d1,d0			; size
	move.w	d2,d1
	mulu.w	#512,d1			; offset
	lea	.name(pc),a0
	move.l	resload(pc),a2
	jsr	resload_SaveFileOffset(a2)
	moveq	#0,d0
	rts

.name	dc.b	"disk.3",0
	CNOP	0,4


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
	beq.w	.end

	move.b	$c00(a1),d0
	not.b	d0
	ror.b	d0

	or.b	#1<<6,$e00(a1)			; set output mode


.nodebug
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



; a2: resload
; a5: bootstart

CreateDataDisk
	lea	.name(pc),a0
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	bne.b	.exit			; data disk exists
        clr.l   -(a7)			; TAG_DONE
        clr.l   -(a7)			; data to fill
	move.l  #WHDLTAG_IOERR_GET,-(a7)
	move.l  a7,a0
	jsr     resload_Control(a2)
	move.l	4(a7),d0
	lea	3*4(a7),a7
	beq.b	.exit

; create empty data disk
	move.l	#$30000-$1000,d4	; length
	moveq	#0,d7			; offset
	move.l	#901120,d5
.loop	move.l	d4,d0
	move.l	d7,d1
	lea	.name(pc),a0
	lea	$1000.w,a1
	jsr	resload_SaveFileOffset(a2)

.ok	add.l	#$30000-$1000,d7
	cmp.l	#901120-$30000,d7
	ble.b	.ok2
	move.l	#901120,d4
	sub.l	d7,d4
.ok2	sub.l	#$30000-$1000,d5
	bpl.b	.loop
.exit	rts

.name	dc.b	"disk."
.num	dc.b	"3",0


	CNOP	0,4
; a1: source
; a0: dest

DECRUNCH
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.b	BK_DECRUNCH
	movem.l	(sp)+,d0-d7/a0-a6


	cmp.l	#$21c90068,$10e(a0)	; move.l a1,$68.w
	bne.b	.noMatch

	movem.l	d0-a6,-(a7)
	move.l	a0,a1
	lea	PLMATCH_1728(pc),a0
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6


.noMatch
	rts


; Bytekiller decruncher
; resourced and adapted by stingray
;
; a0.l: source
; a1.l: destination

BK_DECRUNCH
	movem.l	d0-a6,-(a7)
	bsr.b	.decrunch
	tst.l	d5
	beq.b	.ok

; checksum doesn't match, file corrupt
	pea	ErrText(pc)
	pea	(TDREASON_FAILMSG).w
	bra.w	EXIT

.ok	movem.l	(a7)+,d0-a6
	rts


.decrunch
	move.l	(a1)+,d0
	add.l	a1,d0
	move.l	a0,a1
	move.l	d0,a0
	move.l	-(a0),a2
	add.l	a1,a2
	move.l	-(a0),d5
	move.l	-(a0),d0
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
.nonew3	addx.l	d2,d2
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
	move.w	#1<<4,ccr
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
	move.w	#1<<4,ccr
	roxr.l	#1,d0
.nonew	addx.l	d2,d2
	dbf	d1,.getbit
	rts


ErrText	dc.b	"Decrunching failed, file corrupt!",0



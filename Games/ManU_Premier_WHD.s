***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*( Manchester United Premier League Champions  )*)---.---.  *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            September 2009                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 26-Feb-2022	- version check changed, see routine
;	 	  "determine_game_version" for information
;		- delay in keyboard interrupt fixed
;		- debug key removed from keyboard interrupt

; 24-Feb-2022	- support for v1.0 of the game added (issue #5505)

; 02-Jan-2016	- source can be assembled case-sensitive now
;		- writes to Beamcon0 and Bplcon4 disabled
;		- Bplcon0 color bit fixes
;		- uses WHDLoad v17+ features now (config)
;		- ByteKiller decruncher replaced with my new version which
;		  has error checking
;		- uses WHDLF_ClearMem flag now, code to clear memory
;		  removed
;		- made patch work with 512k chip and 512k fast now, 1MB
;		  chip not needed anymore
;		- Level 6 interrupt acknowledge fixed

; 25-Jan-2010	- support for 94/95 data disk (CUSTOM2=1)

; 18-Jan-2010	- looked at it again, found reason for the crashes
;		  (stupid memory check), game works

; 01-Sep-2009	- work started, adapted from my John Barnes slave

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
DEBUGKEY	= $58		; F9
QUITKEY		= $59		; F10
;DEBUG

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

.config	dc.b	"C1:B:Disable Data Disk Creation;"
	dc.b	"C2:B:Boot from Data Disk;"
	dc.b	0

	IFD	DEBUG
.dir	dc.b	"SOURCES:WHD_Slaves/ManU_PremierLeague/",0
	ENDC
.name	dc.b	"Manchester United Premier League Champions",0
.copy	dc.b	"1994 Krisalis",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	dc.b	"Version 1.03 (26.02.2022)",0
	CNOP	0,2

TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUTYPE		dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
NODATADISK	dc.l	0		; skip intro
		dc.l	WHDLTAG_CUSTOM2_GET
BOOTDATA	dc.l	0		; boot from data disk

		dc.l	TAG_END

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

	lea	BOOTDATA(pc),a0
	tst.l	(a0)
	beq.b	.nodata
	move.l	#2,(a0)
.nodata	


; install keyboard irq
	bsr	SetLev2IRQ

; load boot
	moveq	#0,d0
	move.l	#1024,d1
	lea	$70000,a5
	move.l	a5,a0
	moveq	#1,d2
	add.l	BOOTDATA(pc),d2
	jsr	resload_DiskLoad(a2)

; version check
	move.l	a5,a0
	move.l	#1024,d0
	jsr	resload_CRC16(a2)
	lea	PLBOOT_1790(pc),a4
	cmp.w	#$1c24,d0		; SPS 1790
	beq.b	.isok
	cmp.w	#$8d18,d0		; data disk (SPS 1789)
	beq.b	.isok

; unknown version
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT
	

; load first file
.isok	lea	$75000+$100,a0
	move.l	#$400,d0
	move.l	#$c00,d1
	moveq	#1,d2
	add.l	BOOTDATA(pc),d2
	jsr	resload_DiskLoad(a2)


; patch boot
	move.l	a4,a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

; patch first file
	lea	PLFIRST_1790(pc),a0
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




PLBOOT_1790
	PL_START
	PL_SA	$30,$72			; skip trackdisk stuff
	PL_R	$26a			; GetCPU
	PL_P	$1bc,.mem
	PL_R	$202			; sort memlists by priority
	PL_END

.mem	moveq	#0,d1			; start of chip
	move.l	#$80000,d2		; size
	move.l	d1,$10(a5)
	move.l	d2,$14(a5)
	move.l	HEADER+ws_ExpMem(pc),d1	; start of fast
	move.l	d1,$20(a5)
	move.l	d2,$24(a5)
	rts

PLFIRST_1790
	PL_START
	PL_R	$7fc			; drive check/init
	PL_R	$722			; loader init
	PL_P	$74e,.load
	PL_P	$f8,.patchgame

	PL_END

.patchgame
	jsr	$78000+$2a6
	move.l	d0,a5
	move.l	resload(pc),a2

	bsr.b	Determine_Game_Version

	move.l	BOOTDATA(pc),d0
	beq.b	.isgame
	lea	PLDATA_1789(pc),a0
.isgame	move.l	a5,a1
	jsr	resload_Patch(a2)
	jmp	(a5)



.load	movem.l	d0-a6,-(a7)
	move.l	d0,a0
	move.l	d2,d0
	mulu.w	#512,d0
	moveq	#1,d2
	add.l	BOOTDATA(pc),d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	moveq	#0,d0			; no errors
	movem.l	(a7)+,d0-a6
	rts


; ---------------------------------------------------------------------------
; Determine game version, this is done by performing a CRC16 over the
; ByteKiller decruncher code. The decruncher code is 100% pc-relative so
; it will always return the same checksum value. This is important as the
; version check is done after the game code has been relocated.
;
; To add support for a different version, locate the ByteKiller decruncher
; in the game code and add the start and end offset as well as the
; offset to the patchlist to the table.


; a0.l: relocated game code
; a2.l: resload
; a5.l: relocated game code
; ----
; a0.l: patchlist

Determine_Game_Version
	lea	.TAB(pc),a3
.loop	movem.w	(a3)+,d2/d3/d4	
	moveq	#0,d0
	move.w	d3,d0
	sub.w	d2,d0
	move.l	a5,a0
	add.w	d2,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$ABCE,d0
	beq.b	.supported_version_found

	tst.w	(a3)
	bne.b	.loop

	; unsupported version, display error message and quit
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


	; supported version, return patchlist to use
.supported_version_found
	lea	.TAB(pc,d4.w),a0
	rts

.TAB	dc.w	$33e4,$349e,PLGAME_1790-.TAB	; V1.2, SPS 1790
	dc.w	$33da,$3494,PLGAME_V10-.TAB	; V1.0
	dc.w	0				; end of table


; ---------------------------------------------------------------------------

PLDATA_1789
	PL_START
	PL_L	$c4,$70004e75		; cpu check
	PL_P	$14fe,loader
	PL_L	$1466,$b6834e71		; cmp.l d3,d3 -> correct disk in drive
	PL_P	$1584,savedata
	PL_R	$1630			; disk access/drive ready etc
	PL_W	$265e,$4e71		; disable "disk in drive" check
	PL_R	$1b0c			; disk ready check
	PL_R	$1ca6			; disable "Get available drives"
	PL_R	$19a0			; drive stuff
	PL_R	$1920			; drive stuff

	PL_PS	$26c4,loader		; load dir
	PL_SA	$26c4+6,$270a

	PL_SA	$1440,$1458		; skip "disk in df0:" check


	PL_R	$17798			; disable chipset check

	PL_P	$17720,memend

	PL_PS	$4b2,keys

	PL_P	$347a,DECRUNCH

	PL_SA	$1a76,$1a92		; drive access

	PL_P	$668,snoop		; (a7)+,$dffxxx unsupported

	PL_R	$175d8			; disable video mode check
	PL_R	$1683a			; disable write to Bplcon4

	PL_P	$622,AckLev6
	PL_END


AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte


PLGAME_COMMON
	PL_START
	PL_L	$c4,$70004e75		; cpu check
	PL_P	$130a,loader
	PL_L	$156a,$b6834e71		; cmp.l d3,d3 -> correct disk in drive
	PL_P	$13aa,savedata
	PL_R	$18c8			; disk access/drive ready etc
	PL_W	$2652,$4e71		; disable "disk in drive" check
	PL_R	$1a80			; disk ready check
	PL_R	$1c84			; disable "Get available drives"
	PL_R	$18a8			; drive stuff
	PL_R	$1828			; drive stuff

	PL_PS	$26b8,loader		; load dir
	PL_SA	$26b8+6,$26fe

	PL_SA	$135a,$1372		; skip "disk in df0:" check

	PL_PS	$4b2,keys
	PL_SA	$19ce,$19ea		; drive access

	PL_P	$6c4,snoop		; (a7)+,$dffxxx unsupported
	PL_P	$894,setcop		; fix Bplcon0 color bit problems
	PL_END
	

PLGAME_V10
	PL_START
	PL_R	$1757e			; disable chipset check
	PL_P	$17506,memend
	PL_P	$33da,DECRUNCH
	PL_R	$173be			; disable video mode check

	PL_NEXT	PLGAME_COMMON


PLGAME_1790
	PL_START
	PL_R	$1764a			; disable chipset check
	PL_P	$175d2,memend
	PL_P	$33e4,DECRUNCH
	PL_R	$1748a			; disable video mode check

	PL_NEXT	PLGAME_COMMON


setcop	move.l	a0,-(a7)

.loop	cmp.l	#$fffffffe,(a0)
	beq.b	.end

	cmp.w	#$100,(a0)
	bne.b	.noBplcon0
	or.w	#1<<9,2(a0)
.noBplcon0

	addq.w	#4,a0
	bra.b	.loop


.end	move.l	(a7)+,a0
	move.l	a0,$dff080
	rts


snoop	move.w	(a7)+,d0
	move.w	d0,$dff09c
	trap	#0
	movem.l	(a7)+,d0-a6
	rte


memend	move.l	#$100000/2,d1
	rts

keys	moveq	#0,d0
	move.b	$c00(a1),d0
	move.b	d0,d1
	ror.b	#1,d1
	not.b	d1
	cmp.b	HEADER+ws_keyexit(pc),d1
	beq.w	QUIT
	rts



loader	movem.l	d0-a6,-(a7)
	move.l	d0,a0
	move.l	d2,d0
	mulu.w	#512,d0
	moveq	#1,d2
	cmp.l	#"MU3P",d3
	beq.b	.ok
	moveq	#2,d2
	move.l	BOOTDATA(pc),d4
	beq.b	.nodata
	moveq	#3,d2
.nodata
	cmp.l	#"MU3A",d3
	beq.b	.ok
	moveq	#4,d2
	cmp.l	#"MU3S",d3
	beq.b	.ok
	moveq	#-1,d0
	bra.b	.exit
.ok	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	moveq	#0,d0			; no errors
.exit	movem.l	(a7)+,d0-a6
	rts



savedata
	cmp.w	#$12,d1
	bne.b	.nokludge
	move.w	#$200,d1		; save complete directory
.nokludge

	move.l	d0,a1			; buffer
	move.l	d1,d0			; size
	move.w	d2,d1
	mulu.w	#512,d1			; offset
	lea	.name(pc),a0
	cmp.l	#"MU3S",d3
	beq.b	.disk3
	cmp.l	#"MU3S",d5
	beq.b	.disk3
	moveq	#-1,d0
	rts
.disk3	move.l	resload(pc),a2
	jsr	resload_SaveFileOffset(a2)
	moveq	#0,d0
	rts

.name	dc.b	"disk.4",0
	CNOP	0,4


WaitRaster
	move.l	d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.b	.wait
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
	beq.b	.end
	btst	#3,$d00(a1)			; KBD irq?
	beq.b	.end

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

.debug	pea	(TDREASON_DEBUG).w
.quit	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.exit	pea	(TDREASON_OK).w
	bra.b	.quit


Return	dc.b	0,0


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
.num	dc.b	"4",0

	CNOP	0,4

; a1: source
; a0: dest

DECRUNCH
	movem.l	d0-d7/a0-a6,-(sp)
	bsr	BK_DECRUNCH
	movem.l	(sp)+,d0-d7/a0-a6

	move.l	a0,-(a7)
	cmp.l	#$7d1c21c9,$77352+2
	bne.b	.nomatch
	lea	$7f0b8,a0
	move.w	#$4eb9,(a0)+
	pea	.keys(pc)
	move.l	(a7)+,(a0)
.nomatch	
	cmp.l	#$7d1c21c9,$77822+2	; french
	bne.b	.nomatch2
	lea	$7f588,a0
	move.w	#$4eb9,(a0)+
	pea	.keys(pc)
	move.l	(a7)+,(a0)
.nomatch2
	cmp.l	#$7d1c21c9,$7750a+2	; german
	bne.b	.nomatch3
	lea	$7f270,a0
	move.w	#$4eb9,(a0)+
	pea	.keys(pc)
	move.l	(a7)+,(a0)
.nomatch3
	cmp.l	#$7d1c21c9,$778e6+2	; italian
	bne.b	.nomatch4
	lea	$7f64c,a0
	move.w	#$4eb9,(a0)+
	pea	.keys(pc)
	move.l	(a7)+,(a0)
.nomatch4



	move.l	(a7)+,a0

	rts

.keys	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	move.b	d0,$fd4.w
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



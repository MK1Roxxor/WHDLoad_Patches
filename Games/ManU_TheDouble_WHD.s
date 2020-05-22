***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(     Manchester United: The Double           )*)---.---.  *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                          Sept 2009/Jan 2010                             *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 02-Jan-2016	- source can be assembled case sensitive now
;		- almost 6 years since I coded this patch... time to
;		  finally release it!
;		- uses WHDLoad v17+ features now (config)
;		- ByteKiller decruncher replaced with my new version which
;		  has error checking
;		- writes to Beamcon0 and Bplcon4 disabled
;		- level 6 interrupt acknowledge fixed
;		- changed memory requirements to 512k chip and 1MB fast
;		- uses WHDLF_ClearMemory flag now, code to clear memory
;		  removed

; 26-Jan-2010	- changed memory requirements to 1MB Chip and 512k
;		  other mem, with 1MB an "out of memory" occurs
;		  when a match is started of selling/buying players,
;		  reported by Gordon 


; 20-Jan-2010	- french language support removed since the french
;		  translation is not really good according to lolafg
;		- support for database disk added, CUSTOM2=1 to boot
;		  from data disk to edit the database, thanks to Gordon
;		  for the information how to edit the database

; 18-Jan-2010	- game works, load/save left to do
;		- 68000 quit key
;		- some hours later: load/save works, "Format disk"
;		  option patched too 
;		- french language can be enabled with CUSTOM2=1
;		- decruncher relocated


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


.config	dc.b	"C1:B:Disable Data Disk Creation;"
	dc.b	"C2:B:Boot from Data Disk;"
	
	dc.b	0


	IFD	DEBUG
.dir	dc.b	"SOURCES:WHD_Slaves/ManU_TheDouble/",0
	ENDC
.name	dc.b	"Manchester United: The Double",0
.copy	dc.b	"1995 Krisalis",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	dc.b	"Version 1.00 (02.01.2016)",0
	CNOP	0,2

TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUTYPE		dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
NODATADISK	dc.l	0		; don't create data disk
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
	move.l	#1,(a0)
.nodata	


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
	lea	PLBOOT_1851(pc),a4
	cmp.w	#$ed61,d0
	beq.b	.is1851			; SPS 1851

; unknown version
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT
	


; load first file
.is1851	lea	$75000+$100,a0
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
	lea	PLFIRST_1851(pc),a0
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
PLBOOT_1851
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

PLFIRST_1851
	PL_START
	PL_R	$722			; loader init
	PL_P	$778,.load
	PL_R	$7fc			; drive check/init
	PL_P	$f8,.patchgame
	PL_END

.patchgame
	jsr	$78000+$2a6
	move.l	d0,a5
	lea	PLGAME_1790(pc),a0
	move.l	BOOTDATA(pc),d0
	beq.b	.isgame
	lea	PLDATA_1790(pc),a0
.isgame	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	(a5)



.load	move.l	d0,a0
	move.l	d2,d0
	mulu.w	#512,d0
	moveq	#1,d2
	add.l	BOOTDATA(pc),d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	moveq	#0,d0			; no errors
	rts

PLDATA_1790
	PL_START
	PL_L	$be,$70004e75		; cpu check
	PL_P	$12d6,Loader
	PL_L	$123e,$b6834e71		; cmp.l d3,d3 -> correct disk in drive
	PL_P	$135c,SaveData

	PL_R	$142a			; drive stuff
	PL_R	$1906			; drive stuff
	PL_W	$2458,$4e71		; disk in drive
	PL_R	$1400			; drive stuff
	PL_R	$179a			; drive stuff
	PL_R	$1aa0			; get available drives

	PL_R	$171a			; drive stuff

	PL_PS	$24c0,Loader		; load dir
	PL_SA	$24c0+6,$2506

	PL_SA	$1218,$1230		; skip "disk in df0:" check


	PL_R	$9bea			; disable chipset check

	PL_P	$9b72,memend

	PL_PS	$3be,keys

;	PL_P	$342c,DECRUNCH

	PL_R	$99b8			; disable video mode check
	PL_R	$8c78			; disable write to Bplcon4
	PL_P	$51c,AckLev6
	PL_END


PLGAME_1790
	PL_START
	PL_L	$d2,$70004e75		; cpu check
	PL_P	$13b0,Loader
	PL_L	$1318,$b6834e71		; cmp.l d3,d3 -> correct disk in drive
	PL_P	$1436,SaveData

	PL_R	$1504			; drive stuff
	PL_R	$19e0			; drive stuff
	PL_W	$2532,$4e71		; disk in drive
	PL_R	$14da			; drive stuff
	PL_R	$1874			; drive stuff
	PL_R	$1b7a			; get available drives

	PL_R	$17f4			; drive stuff

	PL_PS	$259a,Loader		; load dir
	PL_SA	$259a+6,$25e0

	PL_SA	$12f2,$130a		; skip "disk in df0:" check


	PL_R	$1c36a			; disable chipset check

	PL_P	$1c2f2,memend

	PL_PS	$482,keys

	PL_P	$342c,DECRUNCH

	PL_P	$5f0,AckLev6
	PL_R	$1c138			; disable video mode check
	PL_R	$1c36a			; disable chipset check
	PL_R	$1b3f2			; disable write to Bplcon4
	PL_END


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



; DBL3: save disk
; DBL4: saved database disk

Loader	move.l	d0,a0
	move.l	d2,d0
	mulu.w	#512,d0
	moveq	#1,d2
	cmp.l	#"DBL1",d3
	beq.b	.diskok
	moveq	#2,d2
	cmp.l	#"DBL2",d3
	beq.b	.diskok
	moveq	#3,d2
	cmp.l	#"DBL3",d3
	beq.b	.diskok
	moveq	#4,d2
	cmp.l	#"DBL4",d3
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
	cmp.l	#"DBL3",d3
	beq.b	.disk3
	lea	.name2(pc),a0
	
.disk3	move.l	resload(pc),a2
	jsr	resload_SaveFileOffset(a2)
	moveq	#0,d0
	rts

.name	dc.b	"disk.3",0
.name2	dc.b	"disk.4",0
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
	beq.w	.end
	btst	#3,$d00(a1)			; KBD irq?
	beq.w	.end

	move.b	$c00(a1),d0
	not.b	d0
	ror.b	d0

	or.b	#1<<6,$e00(a1)			; set output mode



	cmp.b	HEADER+ws_keydebug(pc),d0	
	bne.b	.nodebug
	movem.l	(a7)+,d0-d1/a0-a2
	move.w	(a7),6(a7)			; sr
	move.l	2(a7),(a7)			; pc
	clr.w	4(a7)				; ext.l sr
	bra.b	.debug


.nodebug
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	.exit
	

.nokeys
	moveq	#3-1,d1
.loop	move.b	$6(a0),d0
.wait	cmp.b	$6(a0),d0
	bne.b	.wait
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
	bsr.b	.createdisk		; create disk.3 (save disk)
	lea	.name(pc),a0
	addq.b	#1,.num-.name(a0)	; create disk.4 (database)

.createdisk
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

	move.l	a0,-(a7)
	cmp.l	#$7df621c9,$7c88c+2
	bne.b	.nomatch
	lea	$846cc,a0
	move.w	#$4eb9,(a0)+
	pea	.keys(pc)
	move.l	(a7)+,(a0)
.nomatch	
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



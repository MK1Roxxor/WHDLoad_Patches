***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    MEGADEMO 3/ALCATRAZ WHDLOAD SLAVE       )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              August 2013                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 14-Apr-2020	- more Bplcon0 color bit fixes (part 4)
;		- OCS only DDFSTRT fixed (part 4)
;		- blitter wait added (end part)

; 05-Jan-2014	- default copperlist set to avoid snoop errors
;		- copperlist termination fixed in part 2, 5 and 6
;		- 3 more byte writes to volume register fixed
;		- byte write fix in part 6 fixed, replayer uses
;		  move.b 3(a1),8(a6) instead of the usual 3(a6),8(a5)
;		- write to $dff000 [clr.w 0(a6)] in part 7 fixed
;		- all interrupts/DMA are disabled at the end of each part
;		  to avoid graphics trash and other problems

; 04-Aug-2013	- converted to use real files
;		- all decrunchers (ByteKiller) relocated to fast memory
;		- timing in part 5 ("illusions demo") fixed

; 26-Oct-2011	- fifth part patched
;		- sixth part patched
;		- and finally, the last part has been patched too
;		- not yet tested on a real Amiga (all done at work
;		  as usual :D)

; 25-Oct-2011	- second part patched
;		- third part patched
;		- fourth part patched (lots of buggy blitter waits)

; 24-Oct-2011	- work started
;		- first part patched, not fully working yet

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

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
	dc.w	.dir-HEADER	; ws_CurrentDir
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_KeyDebug
	dc.b	QUITKEY		; ws_KeyExit
	dc.l	0		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Alcatraz/Megademo3/"
	ENDC
	dc.b	"data",0
.name	dc.b	"Megademo 3",0
.copy	dc.b	"1989 Alcatraz",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.02 (14.04.2020)",0
Name	dc.b	"0",0
	CNOP	0,2



resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2


; install keyboard irq
	bsr	SetLev2IRQ

; set fake VBI
	lea	AckVBI(pc),a0
	move.l	a0,$6c.w

; set default copperlist
	lea	$100.w,a0
	move.l	a0,a1
	move.l	#$01000200,(a1)+
	move.l	#-2,(a1)+
	move.l	a0,$dff080


; load and patch current part
.loop	lea	Speed(pc),a0
	move.w	#6,(a0)		; reset speed for replayer

	lea	$1f000,a0
	bsr	LoadFile

; run current part
.release
	btst	#6,$bfe001
	beq.b	.release
	jsr	(a5)

	bra.b	.loop




QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	jmp	resload_Abort(a2)


AckVBI	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rte

KillSys	move.w	#$7fff,$dff09a
	bsr	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	lea	AckVBI(pc),a0
	move.l	a0,$6c.w
	lea	$100.w,a0
	move.l	a0,$dff080
	rts


; a0: load address
LoadFile
	move.l	a0,a5
	lea	Name(pc),a4
	move.l	a4,a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)

	moveq	#0,d4
	move.b	(a4),d4
	addq.b	#1,(a4)
	cmp.b	#"6",(a4)
	ble.b	.ok
	subq.b	#7,(a4)
.ok	sub.b	#"0",d4
	lsl.w	#2,d4
	movem.w	.TAB(pc,d4.w),d4/d5	; crc/offset to patch list
	tst.w	d4
	beq.b	.CRCok
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	d0,d4
	beq.b	.CRCok
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.CRCok	movem.l	d0-a3,-(a7)
	bsr	DECRUNCH		; -> a4: load address, a5: jmp address
	movem.l	(a7)+,d0-a3

	tst.w	d5
	beq.b	.nopatch
	lea	.TAB(pc),a0
	add.w	d5,a0
	move.l	a4,a1
	jsr	resload_Patch(a2)
.nopatch
	rts


.TAB	dc.w	$5cdd,PLPART1-.TAB	; part 1
	dc.w	0,PLPART2-.TAB		; part 2
	dc.w	0,PLPART3-.TAB		; part 3
	dc.w	0,PLPART4-.TAB		; part 4
	dc.w	0,PLPART5-.TAB		; part 5
	dc.w	0,PLPART6-.TAB		; part 6
	dc.w	0,PLPART7-.TAB		; part 7

	
PLPART1	PL_START
	PL_ORW	$84+2,1<<3		; enable level 2 interrupt
	PL_P	$16a,AckVBI
	PL_ORW	$76c+2,1<<9		; set Bplcon0 color bit
	PL_P	$406,FixAudXVol		; fix byte write to volume register
	PL_PSS	$4e0,FixDMAWait,2	; fix DMA wait in replayer
	PL_P	$432,SetSpeed		; set speed
	PL_PSS	$2ca,.checkspeed,2
	PL_AW	$62+8,-4		; $dff084->$dff080
	PL_PSA	$9a,KillSys,$ce
	PL_END

.checkspeed
	move.w	Speed(pc),d0
	cmp.w	$23834+$74e,d0
	rts
; ghost
PLPART2	PL_START
	PL_AW	$32010+6,-4		; $084(a6)->$080(a6)
	PL_ORW	$32968+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$32b48+2,1<<9		; set bplcon0 colorbit

	PL_P	$1fe,FixAudXVol
	PL_PSS	$2d8,FixDMAWait,2
	PL_PSS	$c2,.checkspeed,2
	PL_P	$22a,SetSpeed
	PL_PS	$3200a,.killsys
	PL_PSS	$32038,WaitRaster,2	; fix timing
	PL_L	$32b70,-2		; terminate copperlist
	PL_PS	$3cc,FixAudXVol
	PL_PSA	$3206e,KillSys,$3207a
	PL_END


.killsys
	move.w	#$7fff,d0
	move.w	d0,$9a(a6)
	move.w	d0,$9c(a6)
	move.w	d0,$96(a6)
	bsr	WaitRaster
	lea	$100.w,a0
	move.l	a0,$dff080

	move.w	#$c008,$9a(a6)		; enable level 2 irq
	move.w	#1<<15+1<<9+1<<8+1<<7+1<<6,$96(a6)	; copper, blitter, bpl
	rts

.checkspeed
	move.w	Speed(pc),d0
	cmp.w	$40000+$546,d0
	rts

; mickey
PLPART3	PL_START
	PL_AW	$142+8,-4		; $dff084->$dff080
	PL_P	$1e6,AckVBI
	PL_PS	$408,.wblit
	PL_SA	$12a,$142		; skip blitter reg init (no DMA yet)
	PL_PSS	$164,.initblit,2
	PL_ORW	$6ee+2,1<<9		; set bplcon0 colorbit

	PL_R	$21ee			; disable irq init in replay
	PL_SA	$21f8,$2200		; skip irq restore in mt_end
	PL_P	$2370,FixAudXVol
	PL_PSS	$244a,FixDMAWait,2
	PL_PSS	$2234,.checkspeed,2
	PL_P	$239c,SetSpeed
	PL_PSA	$178,KillSys,$1b2
	PL_END

.checkspeed
	move.w	Speed(pc),d0
	cmp.w	$41904+$26b8,d0
	rts

.initblit
	bsr.b	.wblit			; trashing of d0 doesn't matter here!
	move.w	#0,$dff062
	move.w	#0,$dff066
	move.w	#$5cc,$dff040
	move.w	#$c028,$dff09a		; enable level2+level3 irq

	move.w	#0,$dff102		; forgotten in copperlist!
	move.w	#0,$dff104
	rts

.wblit	btst	#6,$dff002
.wtblit	btst	#6,$dff002
	bne.b	.wtblit
	move.w	$41904+$5d0,d0		; original code
	rts
	

	

; "claude in space"
PLPART4	PL_START
	PL_AW	$1fa+6,-4		; $084(a6)->$080(a6)
	PL_ORW	$216+2,1<<3		; enable level 2 irq

	PL_B	$388+1,$f6		; fix blitter wait
	PL_B	$3c8+1,$f6		; fix blitter wait
	PL_B	$3e8+1,$f6		; fix blitter wait
	PL_B	$408+1,$f6		; fix blitter wait
	PL_B	$474+1,$f6		; fix blitter wait
	PL_B	$484+1,$f6		; fix blitter wait
	PL_B	$4a4+1,$f6		; fix blitter wait
	PL_B	$4c4+1,$f6		; fix blitter wait
	PL_B	$13d2+1,$f6		; fix blitter wait
	PL_B	$1402+1,$f6		; fix blitter wait
	PL_B	$143a+1,$f6		; fix blitter wait
	PL_B	$145c+1,$f6		; fix blitter wait
	PL_B	$1474+1,$f6		; fix blitter wait
	PL_B	$2446+1,$f6		; fix blitter wait
	PL_B	$2472+1,$f6		; fix blitter wait
	PL_B	$248a+1,$f6		; fix blitter wait


	PL_P	$2408,.delay

	PL_P	$506,AckVBI

	PL_P	$3550,FixAudXVol
	PL_PSS	$362a,FixDMAWait,2
	PL_PSS	$3414,.speed,2
	PL_P	$357c,SetSpeed

	PL_ORW	$38e6+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$4182+2,1<<9		; set bplcon0 colorbit
	PL_W	$3ebe,$102		; $100 -> $102
	PL_PSA	$2ee,KillSys,$31e

	PL_ORW	$3ebe+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$9066+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$944a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$94b2+2,1<<9		; set Bplcon0 color bit
	PL_W	$38c6+2,$30		; fix OCS only DDFSTRT
	PL_END

.speed	move.w	Speed(pc),d0
	cmp.w	$1fb14+$3898,d0
	rts

.delay	move.w	#1500/34,d1
.loop	move.b	$dff006,d0
.wait	cmp.b	$dff006,d0
	beq.b	.wait
	dbf	d1,.loop
	rts

; illusions demo
PLPART5	PL_START
	PL_PS	$3e8de,.killsys
	PL_W	$3e8e4+6,$80		; $084(a2)->$080(a2)
	PL_ORW	$3ee18+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$40788+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$407b0+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$4080c+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$408a0+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$40a80+2,1<<9		; set bplcon0 colorbit

	PL_P	$c624,FixAudXVol
	PL_PSS	$c6fe,FixDMAWait,2
	PL_PSS	$c4e8,.speed,2
	PL_P	$c650,SetSpeed
	PL_PSS	$3e8f8,WaitRaster,4	; fix timing
	PL_PS	$c7f2,FixAudXVol
	PL_L	$40a94,-2		; terminate copperlist
	PL_PSA	$3ea08,KillSys,$3ea1a
	PL_END

.speed	move.w	Speed(pc),d0
	cmp.w	$35000+$c96c,d0
	rts

.killsys
	move.w	#$7fff,d0
	move.w	d0,$9a(a2)
	move.w	d0,$9c(a2)
	move.w	d0,$96(a2)
	move.w	#0,$104(a2)
	bsr	WaitRaster
	lea	$100.w,a0
	move.l	a0,$dff080
	move.w	#$c008,$9a(a2)		; enable level 2 irq
	move.w	#1<<15+1<<9+1<<8+1<<7+1<<6,$96(a2)	; copper, blitter, bpl
	rts

	
PLPART6	PL_START
	PL_ORW	$42d4+2,1<<9		; set bplcon0 colorbit
	;PL_AW	$72+6,-4		; $084(a6)->$080(a6)
	PL_ORW	$8e+2,1<<3		; enable level 2 irq

	PL_P	$118,AckVBI

	PL_P	$3808,.FixAudXVol
	PL_PSS	$38d4,FixDMAWait,2
	;PL_I	$3834,SetSpeed

	PL_R	$4308
	;PL_L	$55a4,-2		; fix copperlist termination
	PL_PSS	$72,.fixcop,2
	PL_PS	$39a0,.FixAudXVol
	PL_PSA	$a2,KillSys,$c6
	PL_END


.fixcop	move.l	#-2,$31bb2
	move.l	#$2c60c+$4566,$80(a6)
	rts

.FixAudXVol
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a1),d0
	move.w	d0,8(a6)
	move.l	(a7)+,d0
	rts
	



PLPART7	PL_START
	PL_SA	$0,$100			; skip crap
	PL_AW	$206+6,-4		; $084(a6)->$080(a6)
	PL_ORW	$222+2,1<<3		; enable level 2 irq
	PL_ORW	$308+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$2efa+2,1<<9		; set bplcon0 colorbit

	PL_P	$380,AckVBI

	PL_P	$22ee,FixAudXVol
	PL_PSS	$23c8,FixDMAWait,2
	PL_PSS	$21b2,.speed,2
	PL_P	$231a,SetSpeed
	PL_PS	$24bc,FixAudXVol
	PL_SA	$926,$92a		; skip clr.w 0(a6)
	PL_PSA	$238,KillSys,$25c

	PL_PS	$916,.wblit
	PL_END

.wblit	tst.b	$02(a6)
.wb	btst	#6,$02(a6)
	bne.b	.wb
	move.w	#$0100,$40(a6)
	rts

.speed	move.w	Speed(pc),d0
	cmp.w	$2b6b8+$2636,d0
	rts



SetSpeed
	move.l	a0,-(a7)
	lea	Speed(pc),a0
	move.w	d0,(a0)
	move.l	(a7)+,a0
	rts

Speed	dc.w	6

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
	move.l	d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#16<<8,d0
	bne.b	.wait
.wait2	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#16<<8,d0
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
	beq.b	.end
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



	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	.quit
	

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

.quit	pea	(TDREASON_OK).w
	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine

; a5.l: crunched executable
; ----
; a4.l: load address
; a5.l: jmp address

DECRUNCH
	lea	$e8+$24(a5),a0		; crunched data
	move.l	$4+2+$24(a5),a1		; load address
	move.l	a1,a4			; save load address
	move.l	$aa+2+$24(a5),a5	; jmp address


; Bytekiller decruncher
; resourced and adapted by stingray

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
	move.l	(a0)+,d0		; crunched length
	move.l	(a0)+,d1		; decrunched length
	move.l	(a0)+,d5		; checksum
	move.l	a1,a2
	add.l	d0,a0			; end of crunched data
	add.l	d1,a2			; end of decrunched data

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
.nonew	addx.l	d2,d2
	dbf	d1,.getbit
	rts



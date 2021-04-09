***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      UNIVERSAL WARRIOR WHDLOAD SLAVE       )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             November 2017                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 08-Apr-2021	- load/save support for save games added (pressing "L" in
;		  the "Start the level" screen show the load/save game screen)
;		- one more blitter wait added
;		- delay when loading level added so the level name can be
;		  seen
;		- option to disable blitter wait patches (CUSTOM1) added

; 01-Nov-2017	- work started

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


.config	dc.b	"C1:B:Disable Blitter Wait Patches"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/UniversalWarrior",0
	ENDC

.name	dc.b	"Universal Warrior",0
.copy	dc.b	"1993 Zeppelin",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.02 (08.04.2021)",0

	CNOP	0,4

TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	TAG_DONE

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

; install keyboard irq
	bsr	SetLev2IRQ


; load intro
	lea	$50000,a0
	moveq	#0,d0
	move.l	#$8ef4,d1
	move.l	d1,d5
	move.l	a0,a5
	moveq	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$c477,d0		; SPS 0597
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT
.ok


; decrunch intro
	lea	$e8(a5),a0		; start of crunched data
	move.l	$4+2(a5),a1		; destination
	bsr	BK_DECRUNCH


; patch intro
	lea	PLINTRO(pc),a0
	lea	$6b000,a1
	move.l	a1,a5
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

; and start the game
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

WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts

PLINTRO	PL_START
	PL_PSS	$b80a,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$b822,FixDMAWait,2	; fix DMA wait in replayer
	PL_P	$bae2,FixAudXVol	; fix byte write to volume register
	PL_ORW	$17a+2,1<<3		; enable level 2 interrupt
	PL_P	$7640,.load
	PL_W	$6a+2,$800-1		; correct loop counter, fix access fault
	PL_P	$637c,.ackCOP
	PL_P	$635c,PatchShop

	PL_IFC1
	PL_ELSE
	PL_PS	$628a,.wblit
	PL_PSS	$69c8,.wblit2,2
	PL_PS	$132,.wblit
	PL_ENDIF
	PL_END

.wblit	bsr	WaitBlit
	move.w	#0,$40(a6)
	rts

.wblit2	bsr	WaitBlit
	move.l	d1,$54(a6)
	move.l	d1,$48(a6)
	rts



.ackCOP	move.w	#1<<4,$9c(a6)
	move.w	#1<<4,$9c(a6)
	rte

.load	move.w	$6b000+$7948,d0
	move.w	$6b000+$794c,d1
	move.l	$6b000+$7944,a0

Load	addq.w	#1,d0
	and.w	#$fe,d0
	subq.w	#2,d0
	cmp.w	#34,d0
	blo.b	.ok
	subq.w	#2,d0
.ok	mulu.w	#$1800,d0
	mulu.w	#$1800,d1
	moveq	#1,d2
	move.l	resload(pc),a1
	jmp	resload_DiskLoad(a1)

PatchShop
	lea	$80000,a7

	lea	$440e8,a0
	lea	$200-32.w,a1
	bsr	BK_DECRUNCH

	lea	PLSHOP(pc),a0
	lea	$200.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	jmp	$200.w


PLSHOP	PL_START
	PL_PS	$2ce,.ackCOP
	PL_PSS	$78,.setkbd,4

	PL_IFC1
	PL_ELSE
	PL_PS	$42,.wblit
	PL_PSS	$20f6,.wblit2,2
	PL_PSS	$2330,.wblit2,2
	PL_PSS	$23cc,.wblit2,2
	PL_PSS	$246e,.wblit2,2
	PL_ENDIF

	PL_SA	$436ea,$4376e		; skip memory check
	PL_P	$438a4,.load
	PL_P	$4388a,.LoadPatchGame
	PL_P	$43826,PatchShop
	PL_PSS	$518,.wblit3,2

	PL_P	$af9e,.LoadSave
	PL_SA	$a896,$a8be		; skip save disk request
	PL_SA	$a9b6,$a9d4		; skip game disk request
	PL_SA	$aa5a,$aaa6		; skip save disk request
	PL_SA	$abf8,$ac16		; skip game disk request

	; fix graphics bug when game has been completed (wrong blitter
	; routine called
	PL_W	$1aaa+2,$23c2-$1aaa-2	; fix bsr to call correct routine
	PL_END


.LoadSave
	movem.l	d0-a6,-(a7)
	move.w	$200+$b368,d0		; track (2/4/6 only)
	move.w	$200+$b36c,d1		; length
	move.l	$200+$b364,a5		; destination/memory to save
	lea	$200+$b360,a3		; error flag
	clr.w	(a3)			; default: no errors

	move.l	resload(pc),a2

	lsr.w	#1,d0			; 2/4/6 -> 1/2/3
	add.b	#"0",d0
	lea	.Name(pc),a4
	move.b	d0,.Num-.Name(a4)


	tst.w	$200+$b36e		; load or save?
	beq.b	.LoadGame

	; save game
	mulu.w	#$1800,d1
	move.l	d1,d0

	move.l	a4,a0
	move.l	a5,a1
	move.l	#2*$1800,d0
	jsr	resload_SaveFile(a2)
	bra.b	.exit

.LoadGame
	move.l	a4,a0
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.noGameFile
	
	move.l	a4,a0
	move.l	a5,a1
	jsr	resload_LoadFile(a2)
	bra.b	.exit

.noGameFile
	addq.w	#1,(a3)			; set error flag


.exit
	movem.l	(a7)+,d0-a6
	rts


.Name	dc.b	"UniversalWarrior_Save"
.Num	dc.b	"0",0
	CNOP	0,2
	

.LoadPatchGame
	lea	$80000,a7
	move.l	#$40000,a0
	moveq	#$23,d0
	moveq	#$18,d1
	bsr	Load

	lea	$40000,a0
	move.l	$4+2(a0),a1
	add.w	#$e8,a0
	bsr	BK_DECRUNCH

	lea	PLGAME(pc),a0
	lea	$48000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$48000


.load	movem.l	d0-a6,-(a7)

	move.w	$7e3e4,d0
	move.w	$7e3e0,d1
	move.l	$7e3e6,a0
	bsr	Load

	clr.w	$7E3EC			; clear error flag
	movem.l	(a7)+,d0-a6
	rts


.wblit	bsr	WaitBlit
	move.w	#0,$42(a6)
	rts

.wblit2	bsr	WaitBlit
	move.l	#-1,$44(a6)
	rts


.wblit3	bsr	WaitBlit
	move.l	d1,$54(a6)
	move.l	d1,$48(a6)
	rts

.setkbd	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts

.kbdcust
	move.b	RawKey(pc),d0
	move.b	d0,$200+$2ea.w
	rts


.ackCOP	move.w	#1<<4,$9c(a6)
	move.w	#1<<4,$9c(a6)
	rts

PLGAME	PL_START
	PL_P	$ca12,.load
	PL_R	$1fe			; disable loader error check
	PL_PSS	$2943e,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$29456,FixDMAWait,2	; fix DMA wait in replayer
	PL_P	$29716,FixAudXVol	; fix byte write to volume register
	PL_PS	$6a,.wblit
	PL_PSS	$ac,.setkbd,4
	PL_PS	$848,.ackCOP

	PL_IFC1
	PL_ELSE
	PL_PS	$4a6c,.wblit2
	PL_PS	$4b6e,.wblit2
	PL_PS	$4ac4,.wblit3
	PL_PS	$4a34,.wblit3
	PL_PS	$4a2e,.wblit4
	PL_PS	$239a,.wblit4
	PL_PSS	$4aa6,.wblit5,2
	PL_PS	$4c70,.wblit6
	PL_PS	$1e46,.wblit4
	PL_PSS	$4a80,.wblit5,2
	PL_PS	$4be6,.wblit6
	PL_PS	$254e,.wblit4
	PL_PSS	$4a4e,.wblit5,2

	PL_PS	$4b48,.wblit6
	PL_ENDIF
	PL_END

.ackCOP	move.w	#1<<4,$9c(a6)
	move.w	#1<<4,$9c(a6)
	rts

.wblit	bsr	WaitBlit
	move.w	#0,$42(a6)
	rts

.wblit2	bsr	WaitBlit
	move.w	#44,$66(a6)
	rts

.wblit3	bsr	WaitBlit
	move.w	#42,$66(a6)
	rts

.wblit4	bsr	WaitBlit
	move.w	#0,$64(a6)
	rts

.wblit5	bsr	WaitBlit
	move.l	#$36610,$50(a6)
	rts

.wblit6	ror.w	#4,d2
	or.w	#$dfc,d2
	bra.w	WaitBlit

.setkbd	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts

.kbdcust
	move.b	Key(pc),d0
	move.b	d0,$48000+$9446

	ror.b	d0
	not.b	d0
	cmp.b	#$36,d0
	bne.b	.no
	jsr	$48000+$ae70
.no
	rts


.load	movem.l	d0-a6,-(a7)

	move.w	$48000+$cd1a,d0
	move.w	$48000+$cd1e,d1
	move.l	$48000+$cd16,a0
	bsr.w	Load

	; show level name for 3 seconds
	moveq	#3*10,d0
	move.l	resload(pc),a0
	jsr	resload_Delay(a0)

	movem.l	(a7)+,d0-a6
	rts



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
.wait1	btst	#0,$dff005
	beq.b	.wait1
.wait2	btst	#0,$dff005
	bne.b	.wait2
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
	beq.b	.exit
	

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

.exit	bra.w	QUIT


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine





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
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d5
	move.l	a1,a2
	add.l	d0,a0
	add.l	d1,a2
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



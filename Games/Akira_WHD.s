***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        AKIRA CD32 WHDLOAD SLAVE            )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            September 2018                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 13-Dec-2022	- original version supported, images sent by Christoph
;		  Gleisberg

; 18-Sep-2018	- "IT STINKS" level works correctly now, memory patches
;		  adapted
;		- out of bounds blits fixed
;		- Sewers.exe patched
;		- title patched
;		- started to add support for the OCS version
;		- CD32 version base code now loaded to $800.w (instead
;		  of $2000.w) for easier patching of the OCS version,
;		  chip memory start set to $10000 (instead of $5000.w) for
;		  the same reason
;		- some hours later: OCS version fully supported
;		- copperlist fixes simplified

; 17-Sep-2018	- work started


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
	dc.l	524288*2	; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
;	dc.w	0		; ws_kickname
;	dc.l	0		; ws_kicksize
;	dc.w	0		; ws_kickcrc

; v17
;	dc.w	.config-HEADER	; ws_config


;.config
;	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Akira/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Akira",0
.copy	dc.b	"1994 ICE",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.3 (13.12.2022)",0
Name	dc.b	"Akira",0
	CNOP	0,2


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

; install keyboard irq
	bsr	SetLev2IRQ


; load base code
	lea	Name(pc),a0
	lea	$800.w,a1
	move.l	a1,a5
	jsr	resload_LoadFile(a2)

	move.l	a5,a0
	move.l	#4096,d0			; only use 4k for CRC
	lea	PLBASE(pc),a3
	jsr	resload_CRC16(a2)
	cmp.w	#$43fa,d0			; CD32 version
	beq.b	.ok

	lea	PLBASE_OCS(pc),a3
	cmp.w	#$c2a3,d0			; OCS version, Hoodlum crack
	beq.b	.ok
	cmp.w	#$2a81,d0			; OCS version, original
	beq.b	.ok

.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT

.ok

; relocate
	move.l	a5,a0
	sub.l	a1,a1
	jsr	resload_Relocate(a2)


; patch
	move.l	a3,a0
	move.l	a5,a1
	jsr	resload_Patch(a2)



; and start
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
.wait	btst	#0,$dff005
	beq.b	.wait
.wait2	btst	#0,$dff005
	bne.b	.wait2
	rts


PLPICTURE
	PL_START
	PL_P	$264,AckCop
	PL_END

PLPICTUREC
	PL_START
.B	= $27d4
	PL_ORW	$28a8-.B+2,1<<9		; set Bplcon0 color bit
	PL_W	$28f0-.B,$1fe		; FMODE -> NOP
	PL_END


PLBASE_OCS
	PL_START
	PL_SA	0,$5a			; skip system stuff
	PL_R	$d10			; disable cache/VBR stuff
	PL_PSA	$332,.getExtMem,$346
	PL_SA	$86,$c0			; skip relocation
	PL_P	$e14,.AckLev1
	PL_P	$e74,.AckLev2
	PL_P	$e7e,.AckVBI
	PL_P	$e88,.AckLev4
	PL_P	$e92,.AckLev5
	PL_P	$e9c,.AckLev6

; restore cracked version (jsr $100.w) to original state
	PL_L	$29c,$227a130e		; move.l ChipMem(pc),a1

	PL_P	$10d6,.LoadFile
	PL_P	$43e,.flush		; flush cache after relocating

	PL_W	$2466,$1fe		; disable BPLCON3
	PL_W	$2472,$1fe		; disable BPLCON4
	PL_W	$2476,$1fe		; disable FMODE

	;PL_L	$1740,100

	PL_PS	$e2e,.checkquit	
	PL_P	$31c,QUIT
	PL_END

.checkquit
	move.b	$bfec01,d0

	move.b	d0,d1
	ror.b	d1
	not.b	d1
	cmp.b	HEADER+ws_keyexit(pc),d1
	beq.w	QUIT
	rts



.flush	lea	.TAB(pc),a0
	move.l	a0,a1
.loop	move.l	.FileName(pc),a2

;.w	move.w	#$0f0,$dff180
;	btst	#2,$dff016
;	bne.b	.w

	move.w	(a0),d0			; offset to file name
	lea	(a1,d0.w),a3
.compare
	move.b	(a2)+,d0
	cmp.b	#"A",d0
	blt.b	.ok
	cmp.b	#"Z",d0
	bhi.b	.ok
	or.b	#1<<5,d0
.ok

	move.b	(a3)+,d1
	cmp.b	d0,d1
	bne.b	.next

	tst.b	(a2)
	bne.b	.compare

; file found, patch
;.s	move.w	#$f00,$dff180
;	btst	#2,$dff016
;	bne.b	.s


	movem.w	2(a0),d0/d5		; offset to patch lists
	lea	(a1,d0.w),a0		; public
	lea	(a1,d5.w),a4		; chip
	move.l	$800+$15b0.w,a1		; public memory
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	move.l	a4,a0
	move.l	$800+$15ac.w,a1		; chip memory
	jsr	resload_Patch(a2)

	bra.b	.out



.next	addq.w	#3*2,a0
	tst.w	(a0)
	bpl.b	.loop


.out	move.l	resload(pc),a0
	jsr	resload_FlushCache(a0)
	movem.l	(a7)+,d0-a6
	rts


.TAB	dc.w	.Title-.TAB,PLTITLE-.TAB,PLTITLEC-.TAB
	dc.w	.Picture1-.TAB,PLPICTURE-.TAB,PLPICTUREC-.TAB
	dc.w	.Picture2-.TAB,PLPICTURE-.TAB,PLPICTUREC-.TAB
	dc.w	.Picture3-.TAB,PLPICTURE-.TAB,PLPICTUREC-.TAB
	dc.w	.Road-.TAB,PLROAD-.TAB,PLROADC-.TAB
	dc.w	.Platform-.TAB,PLPLATFORMOCS-.TAB,PLPLATFORMOCS-.TAB
	dc.w	.Sewer-.TAB,PLSEWER-.TAB,PLSEWERC-.TAB
	dc.w	-1				; end of tab


.Title		dc.b	"title.exe",0
.Picture1	dc.b	"picture1.exe",0
.Picture2	dc.b	"picture2.exe",0
.Picture3	dc.b	"picture3.exe",0
.Road		dc.b	"road.exe",0
.Platform	dc.b	"platform.exe",0
.Sewer		dc.b	"sewer.exe",0

	CNOP	0,2


; d0.l: file size
; a0.l: file name
; a1.l: destination
; a2.l: ptr to "file is packed" flag
; a3.l: end of file name

.LoadFile
	movem.l	d0-a6,-(a7)

	lea	.FileName(pc),a4
	move.l	a0,(a4)

	move.l	a1,a5
	move.l	resload(pc),a2

	

; *.Ani files are unpacked, all other files are packed
	cmp.b	#"i",-(a3)
	bne.b	.packed
	cmp.b	#"n",-(a3)
	bne.b	.packed
	cmp.b	#"A",-(a3)
	beq.b	.unpacked


.packed	subq.w	#4,a1			; adapt destination address

.unpacked
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)
	movem.l	(a7)+,d0-a6

	tst.b	(a1)
	seq	(a2)			; set flag to $ff if 1st byte is 0
	rts


.FileName	dc.l	0


.getExtMem
	move.l	HEADER+ws_ExpMem(pc),d0
	add.l	#524288,d0
	rts

.AckLev1
	move.w	#1<<0|1<<1|1<<2,$dff09c
	move.w	#1<<0|1<<1|1<<2,$dff09c
	rte	

.AckLev2
	move.w	#1<<3,$dff09c
	move.w	#1<<3,$dff09c
	rte

.AckVBI	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte

.AckLev4
	move.w	#$780,$dff09c
	move.w	#$780,$dff09c
	rte	

.AckLev5
	move.w	#$1800,$dff09c
	move.w	#$1800,$dff09c
	rte	

.AckLev6
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte	


PLTITLE	PL_START
	PL_P	$c76,AckCop
	PL_PS	$eae,AckLev4

	PL_PSS	$2286,.fixblit,2	; fix long write to bltdmod
	PL_PSS	$22c6,.fixblit,2

	PL_R	$2660			; disable manual protection


; debug
;	PL_SA	$2c,$34			; don't set part
; set part:
; 0: title
; 1: menu
; 2: high scores
; 3: end
;	PL_W	$4c30,0
	
	
	PL_END

.fixblit
	move.w	#0,$dff066
	rts

PLTITLEC
	PL_START
.B	= $73880
	PL_ORW	$73ce4-.B+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$73e0c-.B+2,1<<9	; set Bplcon0 color bit
	PL_END


PLANIM1	PL_START

	PL_P	$2b4,AckCop

	PL_END

PLANIM1C
.B	= $c4cbc
	PL_START
	PL_ORW	$c4d90-.B+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$c4eb8-.B+2,1<<9	; set Bplcon0 color bit
	PL_END
	

PLROAD	PL_START
	PL_ORW	$f8+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$16a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$158+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$18c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$194+2,1<<9		; set Bplcon0 color bit
	PL_P	$3950,AckCop
	PL_PS	$3d4e,AckLev4

;	PL_W	$258,$4e71		: enable level skip
	PL_END
	
PLROADC	PL_START
.B	= $215c0
	PL_ORW	$215d8-.B+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$21998-.B+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$21a58-.B+2,1<<9	; set Bplcon0 color bit

	PL_L	$215e8-.B,-2
	PL_END


PLPLATFORM
	PL_START
	PL_PS	$b12a,FixCop
	PL_PSS	$c0f6,AckVBI,2
	PL_PS	$d48a,AckLev4
	PL_PSS	$29d4,checkblit,2
	PL_PSS	$2b44,checkblit,2
	PL_END


PLPLATFORMOCS
	PL_START
	PL_PS	$b11e,FixCop
	PL_PSS	$bfe2,AckVBI,2
	PL_PS	$d376,AckLev4
	PL_PSS	$29ca,checkblit,2
	PL_PSS	$2b3a,checkblit,2
	PL_END

checkblit
	cmp.l	#$80000,a2
	bcc.b	.noblit

	move.l	a3,$54(a6)
	move.w	d3,$58(a6)
.noblit	rts


FixCop	move.l	d0,a0
	or.w	#1<<9,$30+2(a0)
	move.l	d0,$dff080
	rts

AckVBI	move.w	#1<<4|1<<5,$dff09c
	move.w	#1<<4|1<<5,$dff09c
	rts

PLPLATFORMCOCS
PLPLATFORMC
	PL_START
	PL_END

PLSEWER	PL_START
	PL_P	$41ac,AckCop
	PL_PS	$44a6,AckLev4
	PL_ORW	$106+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$166+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$17e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1a0+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1a8+2,1<<9		; set Bplcon0 color bit
	
;	PL_W	$286,$4e71		: enable level skip
	PL_END

PLSEWERC
	PL_START
.B	= $180b0
	PL_ORW	$180c0-.B+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$182c8-.B+2,1<<9	; set Bplcon0 color bit
	PL_ORW	$18388-.B+2,1<<9	; set Bplcon0 color bit
	
	PL_L	$180d8-.B,-2
	PL_END


AckCop	move.w	#1<<4,$dff09c
	move.w	#1<<4,$dff09c
	rte

AckLev4	move.w	d0,$dff09c
	move.w	d0,$dff09c
	rts


PLBASE	PL_START
	PL_SA	$0,$60
	PL_R	$ea4			; disable cache/VBR stuff

	PL_PSA	$9b0,LoadHigh,$9d6
	PL_R	$9fe			; disable nonvolatile stuff
	PL_SA	$a04,$a0a		; skip nonvolatile stuff if CRC is wrong
	PL_SA	$a26,$a2e		; don't load from nonvolatile


	PL_SA	$a56,$a68		; skip nonvolatile stuff
	PL_P	$a84,SaveHigh


	PL_S	$408,2			; skip addq.w #6,a1
	PL_S	$f1e,2			; skip addq.w #6,a1

;	PL_L	$1496,100		; for highscore save testing


	PL_P	$44c,.flush		; flush cache after relocating

	PL_SA	$41a,$430
	PL_PSA	$438,.read,$444
	

	PL_SA	$f24,$f3a		; skip Open()
	PL_PSA	$f48,.load,$f54

	PL_SA	$64,$aa
	PL_PSA	$b0,.AllocMem,$c0
	PL_PSA	$cc,.AllocMem,$dc
	PL_P	$37e,QUIT
	PL_SA	$e2,$f4			; don't store system copperlist

	PL_SA	$cc4,$cce		; skip DOS delay
	PL_SA	$d4c,$d56
	PL_SA	$c38,$c42
	

	PL_P	$3aa,QUIT
	PL_END

.load	lea	$800+$126b.w,a0	; file name
	move.l	d2,a1
	move.l	resload(pc),a2
	jmp	resload_LoadFile(a2)


	
.read	lea	$800+$126b.w,a0
	move.l	d2,a1
	move.l	resload(pc),a2
	jmp	resload_LoadFile(a2)


.AllocMem
	move.l	HEADER+ws_ExpMem(pc),d0
	tst.l	d1
	beq.b	.done
	
; chip
	pea	$10000
	move.l	(a7)+,d0

.done	rts


.flush	lea	.TAB(pc),a0
	move.l	a0,a1
.loop	;move.l	.FileName(pc),a2
	lea	$800+$126b.w,a2	; file name

;.w	move.w	#$0f0,$dff180
;	btst	#2,$dff016
;	bne.b	.w

	move.w	(a0),d0			; offset to file name
	lea	(a1,d0.w),a3
.compare
	move.b	(a2)+,d0
	cmp.b	#"A",d0
	blt.b	.ok
	cmp.b	#"Z",d0
	bhi.b	.ok
	or.b	#1<<5,d0
.ok

	move.b	(a3)+,d1
	cmp.b	d0,d1
	bne.b	.next

	tst.b	(a2)
	bne.b	.compare

; file found, patch
;.s	move.w	#$f00,$dff180
;	btst	#2,$dff016
;	bne.b	.s


	movem.w	2(a0),d0/d5		; offset to patch lists
	lea	(a1,d0.w),a0		; public
	lea	(a1,d5.w),a4		; chip
	move.l	$800+$11f2.w,a1		; public memory
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	move.l	a4,a0
	move.l	$800+$11ee.w,a1		; chip memory
	jsr	resload_Patch(a2)

	bra.b	.out



.next	addq.w	#3*2,a0
	tst.w	(a0)
	bpl.b	.loop


.out	move.l	resload(pc),a0
	jsr	resload_FlushCache(a0)
	movem.l	(a7)+,d0-a6
	rts


.TAB	dc.w	.Title-.TAB,PLTITLE-.TAB,PLTITLEC-.TAB
	dc.w	.Anim1-.TAB,PLANIM1-.TAB,PLANIM1C-.TAB
	dc.w	.Anim2-.TAB,PLANIM1-.TAB,PLANIM1C-.TAB
	dc.w	.Anim3-.TAB,PLANIM1-.TAB,PLANIM1C-.TAB
	dc.w	.Road-.TAB,PLROAD-.TAB,PLROADC-.TAB
	dc.w	.Platform-.TAB,PLPLATFORM-.TAB,PLPLATFORMC-.TAB
	dc.w	.Sewer-.TAB,PLSEWER-.TAB,PLSEWERC-.TAB
	dc.w	-1				; end of tab


.Title		dc.b	"title.exe",0
.Anim1		dc.b	"anim1.exe",0
.Anim2		dc.b	"anim2.exe",0
.Anim3		dc.b	"anim3.exe",0
.Road		dc.b	"road.exe",0
.Platform	dc.b	"platform.exe",0
.Sewer		dc.b	"sewer.exe",0

	CNOP	0,2



LoadHigh
	lea	HighName(pc),a0
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nohigh

	lea	HighName(pc),a0
	lea	$800+$1378.w,a1
	jsr	resload_LoadFile(a2)	
	move.l	#$800+$1378,d0
	
.nohigh	rts


SaveHigh
	lea	HighName(pc),a0
	move.l	a2,a1
	move.l	#71*2,d0
	move.l	resload(pc),a2
	jmp	resload_SaveFile(a2)

	

HighName
	dc.b	"Akira.high",0
	CNOP	0,2


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
	not.b	d0
	ror.b	d0
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





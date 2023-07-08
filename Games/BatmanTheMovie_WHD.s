***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      BATMAN THE MOVIE WHDLOAD SLAVE        )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             January 2015                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 19-Jul-2016	- support for 1 disk version finished
;		- bug in ascii conversion (move.b $2e,(a0)+) in level 2
;		  fixed, no buggy balloons text displayed anymore
;		- high-score load/save added
;		- timing for game over and "game won" screens fixed, they
;		  are now shown for for 5 seconds
;		- patch is finished for now!

; 18-Jul-2016	- 2 disk version fully patched, blitter waits added,
;		  access faults fixed, BLTADAT values fixed etc.
;		- the file loader code I wrote last years was almost 100%
;		  correct and only needed 2 minor fixes :)
;		- trainer options added
;		- WHDLoad v17+ features used
;		- started to add support for the 1 disk version
;		- TO DO: in the driving level there is buggy and wrong
;		  texts for balloons displayed, probably a bug in the
;		  game code somehwere

; 14-Jan-2015	- work started
;		- code for the file loader emulation written but not tested
;		  yet


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $46		; Del
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


.config	dc.b	"C1:X:Unlimited Lives:0;"
	dc.b	"C1:X:Unlimited Energy:1;"
	dc.b	"C1:X:Unlimited Time:2;"
	dc.b	"C1:X:In-Game Keys:3"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/BatmanTheMovie/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Batman the Movie",0
.copy	dc.b	"1889 Ocean",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.5 (19.06.2016)",0
Name	dc.b	"batman",0
	CNOP	0,2


TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET

; bit 0: unlimited lives on/off
; bit 1: unlimited energy on/off
; bit 2: unlimited time on/off
; bit 3: in-game keys on/off
TRAINEROPTIONS	dc.l	0
		dc.l	TAG_END

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


; install keyboard interrupt
	bsr	SetLev2IRQ

	lea	$300.w,a0
	move.l	$1000.w,(a0)
	move.l	a0,$dff080

; load boot
	lea	Name(pc),a0
	lea	$800.w,a1
	move.l	a1,a5
	jsr	resload_LoadFileDecrunch(a2)
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	lea	PLBOOT(pc),a0
	lea	DecrunchRout_2Disk(pc),a1
	lea	$1c000+$974,a3			; high-score location
	cmp.w	#$cd73,d0			; SPS 0006, 2 disks
	beq.b	.ok
	lea	PLBOOT_1DISK(pc),a0
	lea	DecrunchRout_1Disk(pc),a1
	lea	$7ff00,a3			: high-score location
	cmp.w	#$b309,d0			; SPS 0019
	beq.b	.ok
	cmp.w	#$aacd,d0			; SPS 1730
	beq.b	.ok

.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok	lea	DecrunchRout(pc),a4
	move.l	a1,(a4)+
	move.l	a3,(a4)				; high-score location


; patch
	move.l	a5,a1
	jsr	resload_Patch(a2)

; set default DMA
	move.w	#$83c0,$dff096


; and start
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

AckVBI_R
	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rts

AckBLT_R
	move.w	#1<<6,$dff09c
	move.w	#1<<6,$dff09c
	rts

AckCOP_R
	move.w	#1<<4,$dff09c
	move.w	#1<<4,$dff09c
	rts

AckVB_R	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rts
	
AckLev4_R
	move.w	d0,$dff09c
	move.w	d0,$dff09c
	rts
	
AckLev5_R
	move.w	#1<<12,$dff09c
	move.w	#1<<12,$dff09c
	rts	

AckLev5_2_R
	move.w	#1<<11,$dff09c
	move.w	#1<<11,$dff09c
	rts	


AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte
AckLev6_R
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rts

AckLev6_2_R
	move.w	#1<<14,$dff09c
	move.w	#1<<14,$dff09c
	rts


AckLev2_R
	move.w	#1<<3,$dff09c
	move.w	#1<<3,$dff09c
	rts	

AckLev1_R
	move.w	#1,$dff09c
	move.w	#1,$dff09c
	rts

AckLev1_2_R
	move.w	#2,$dff09c
	move.w	#2,$dff09c
	rts

AckLev1_3_R
	move.w	#4,$dff09c
	move.w	#4,$dff09c
	rts
		

ToggleLives
	eor.b	#$19,$7fb20		; subq <-> tst
	rts

ToggleEnergy
	eor.b	#$9b,$7fa76		; add.w <-> tst
	;eor.w	#1,$7fae6+2
	;eor.w	#1,$7fa92+2
	rts

ToggleTime
	eor.w	#1,$7fca8+2		; sub.w #1 <-> sub.w #0
	rts

FixDelay
	move.l	a0,-(a7)
	moveq	#5*10,d0
	move.l	resload(pc),a0
	jsr	resload_Delay(a0)
	move.l	(a7)+,a0
	rts

PLTITLE_1DISK
	PL_START
	PL_SA	$1258,$1260		; skip byte write to $dff08e
	PL_W	$1266+2,$5200		; set Bplcon0 color bit
	PL_PS	$12a8,.wblit1
	PL_ORW	$3e+2,1<<9		; set Bplcon0 color bit
	PL_P	$30e,WaitRaster		; fix timing
	PL_ORW	$13f8+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$2e4,AckVBI_R,2

	PL_P	$2b6,.checkquit

	PL_PSS	$78c,.savehigh,2

	PL_PSS	$149e,FixDelay,2	; show game over screen for 5 seconds
	PL_PSS	$1434,FixDelay,2	; show "game won" screen for 5 seconds
	PL_END

	

.wblit1	move.w	#0,$dff10a
	bra.w	WaitBlit

.checkquit
	move.b	$800+$303.w,d0
	ror.b	d0
	not.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT

	movem.l	(a7)+,d0-a6
	rte

.savehigh
	move.b	#$60,$1c000+$7b6	; original code
SaveHigh
	movem.l	d0-a6,-(a7)
	move.l	TRAINEROPTIONS(pc),d0
	bne.b	.nosave
	btst	#7,$7c875
	bne.b	.nosave
	
	lea	HiName(pc),a0
	move.l	HighscoreLoc(pc),a1
	move.l	#$c0,d0
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)


.nosave	movem.l	(a7)+,d0-a6
	rts

LoadHigh
	movem.l	d0-a6,-(a7)
	lea	HiName(pc),a0
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nohigh
	lea	HiName(pc),a0
	move.l	HighscoreLoc(pc),a1
	jsr	resload_LoadFile(a2)

.nohigh	movem.l	(a7)+,d0-a6
	rts


HiName	dc.b	"Batman.hi",0
	CNOP	0,2

PLTITLE	PL_START
	PL_SA	$12e4,$12ec		; skip byte write to $dff08e
	PL_ORW	$12f2+2,1<<9		; set Bplcon0 color bit
	PL_PS	$1334,.wblit1
	PL_ORW	$38+2,1<<9		; set Bplcon0 color bit
	PL_P	$2f8,WaitRaster		; fix timing
	PL_ORW	$1484+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$2d0,AckVBI_R,2

	PL_P	$2a2,.checkquit

	PL_PSS	$758,.savehigh,2

	
	PL_PSS	$152a,FixDelay,2	; show game over screen for 5 seconds
	PL_PSS	$14c0,FixDelay,2	; show "game won" screen for 5 seconds
	PL_END

.checkquit
	move.b	$800+$2ed.w,d0
	ror.b	d0
	not.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT

	movem.l	(a7)+,d0-a6
	rte

.savehigh
	move.b	#$60,$1c000+$782	; original code
	bra.w	SaveHigh

.wblit1	move.w	#0,$dff10a
WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts	

; level 1
PLCODE1_1DISK
	PL_START
	PL_W	$2680+2,$8000		; fix BLTADAT
	
	PL_NEXT	PLCODE1_COMMON
	PL_END


; level 1
PLCODE1	PL_START
	PL_W	$2664+2,$8000		; fix BLTADAT
	
	PL_NEXT	PLCODE1_COMMON
	PL_END

PLCODE1_COMMON
	PL_START
	PL_PSS	$20,wblit1,2
	PL_SA	$102,$122		; skip drive access
	PL_SA	$12a,$132		; skip write to $bfeb01
	PL_SA	$142,$148		; skip write to $bfdb00
;	PL_W	$2664+2,$8000		; fix BLTADAT
	PL_PSS	$306,AckLev2_R,2
	PL_PSS	$332,AckBLT_R,2
	PL_PSS	$34e,AckCOP_R,2
	PL_PSS	$342,AckVB_R,2
	PL_PS	$366,AckLev4_R
	PL_PSS	$38a,AckLev5_R,2
	PL_PSS	$37e,AckLev5_2_R,2
	PL_PSS	$3b0,AckLev6_R,2
	PL_PSS	$3bc,AckLev6_R,2
	PL_PSS	$3c8,AckLev6_2_R,2

	PL_PS	$3e4,.checkquit
	
	PL_END

.checkquit
	move.b	$bfec01,d1
	move.b	d1,d2
	ror.b	#1,d2
	not.b	d2


	movem.l	d0/a0,-(a7)
	move.w	d2,d0
	lea	.skiplevel(pc),a0
	bsr.b	CheckInGameKeys
	movem.l	(a7)+,d0/a0
	rts

.skiplevel
	move.w	#$4e71,$3000+$c4c.w
	move.b	#$60,$3000+$c56.w
	rts


; d0.b: raw key
; a0.l: ptr to code for level skip

CheckInGameKeys
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT

	move.l	d1,-(a7)
	move.l	TRAINEROPTIONS(pc),d1
	btst	#3,d1
	beq.b	.nokeys

	cmp.b	#$12,d0			; E - toggle unlimited energy
	bne.b	.noE
	bsr	ToggleEnergy
.noE	

	cmp.b	#$14,d0			; T - toggle unlimited time
	bne.b	.noT
	bsr	ToggleTime
.noT

	cmp.b	#$28,d0			; L - toggle unlimited lives
	bne.b	.noL
	bsr	ToggleLives
.noL

	cmp.b	#$36,d0			; N - skip level
	bne.b	.noN
	jsr	(a0)
.noN

.nokeys	
	move.l	(a7)+,d1
	rts
	

wblit1	bsr	WaitBlit
	move.w	#$4000,$dff024		; original code
	rts

; level 2
PLCODE_1DISK
	PL_START
	PL_PSS	$34,wblit1,2
	PL_SA	$122,$142		; skip drive access
	PL_SA	$14a,$152		; skip write to $bfeb01
	PL_SA	$162,$168		; skip write to $bfdb00
	PL_PS	$400a,cwblit1
	PL_PS	$42da,cwblit2
	PL_PS	$420,.checkquit

	PL_PSS	$310,AckLev1_R,2
	PL_PSS	$31c,AckLev1_2_R,2
	PL_PSS	$328,AckLev1_3_R,2
	PL_PSS	$342,AckLev2_R,2
	PL_PSS	$34e,AckLev2_R,2
	PL_PSS	$36e,AckBLT_R,2
	PL_PSS	$37e,AckVB_R,2
	PL_PSS	$38a,AckCOP_R,2
	PL_PS	$3a2,AckLev4_R
	PL_PSS	$3c6,AckLev5_R,2
	PL_PSS	$3ba,AckLev5_2_R,2
	PL_PSS	$3ec,AckLev6_R,2
	PL_PSS	$3f8,AckLev6_R,2
	PL_PSS	$404,AckLev6_2_R,2
	PL_END

.checkquit
	move.b	$bfec01,d1
	
	move.b	d1,d2
	ror.b	#1,d2
	not.b	d2

	movem.l	d0/a0,-(a7)
	move.w	d2,d0
	lea	.skiplevel(pc),a0
	bsr.w	CheckInGameKeys
	movem.l	(a7)+,d0/a0
	rts

.skiplevel
	clr.w	$3000+$6002		; distance (level 2)
	clr.w	$3000+$6004		; number of balloons (level 4)
	rts

; level 2
PLCODE	PL_START
	PL_PSS	$3e,wblit1,2
	PL_SA	$12c,$14c		; skip drive access
	PL_SA	$154,$15c		; skip write to $bfeb01
	PL_SA	$16c,$172		; skip write to $bfdb00
	PL_PS	$3eec,cwblit1
	PL_PS	$41bc,cwblit2
	PL_PS	$42a,.checkquit

	PL_PSS	$31a,AckLev1_R,2
	PL_PSS	$326,AckLev1_2_R,2
	PL_PSS	$332,AckLev1_3_R,2
	PL_PSS	$34c,AckLev2_R,2
	PL_PSS	$358,AckLev2_R,2
	PL_PSS	$378,AckBLT_R,2
	PL_PSS	$388,AckVB_R,2
	PL_PSS	$394,AckCOP_R,2
	PL_PS	$3ac,AckLev4_R
	PL_PSS	$3d0,AckLev5_R,2
	PL_PSS	$3c4,AckLev5_2_R,2
	PL_PSS	$3f6,AckLev6_R,2
	PL_PSS	$402,AckLev6_R,2
	PL_PSS	$40e,AckLev6_2_R,2
	
	PL_END

.checkquit
	move.b	$bfec01,d1
	

	move.b	d1,d2
	ror.b	#1,d2
	not.b	d2

	movem.l	d0/a0,-(a7)
	move.w	d2,d0
	lea	.skiplevel(pc),a0
	bsr.w	CheckInGameKeys
	movem.l	(a7)+,d0/a0
	rts

.skiplevel
	clr.w	$3000+$5d22		; distance (level 2)
	clr.w	$3000+$5d24		; number of balloons (level 4)
	rts



cwblit1	bsr	WaitBlit
	move.l	a0,$dff054
	rts

cwblit2	bsr	WaitBlit
	move.w	d0,$dff040
	rts

; level 3
PLBATCAVE_1DISK
	PL_START
	PL_P	$1f4,WaitRaster
	PL_S	$4,6			; skip write to $dff002
	PL_W	$392+2,$4200		; fix Bplcon0 value
	PL_PSS	$39a,bwblit1,2
	PL_PS	$ed4,bwblit2

	PL_PSS	$18e,AckLev2_R,2
	PL_PS	$164,.checkquit
	PL_END

.checkquit
	move.l	d0,-(a7)
	move.b	$bfec01,d0
	ror.b	d0
	not.b	d0
	lea	.skiplevel(pc),a0
	bsr	CheckInGameKeys
	move.l	(a7)+,d0

	jmp	$d000+$228

.skiplevel
	move.w	#$4e71,$d000+$2e6
	move.w	#$4c,$d000+$1ec
	rts


; level 3
PLBATCAVE
	PL_START
	PL_P	$1ee,WaitRaster
	PL_S	$50,6			; skip write to $dff002
	PL_W	$38c+2,$4200		; fix Bplcon0 value
	PL_PSS	$394,bwblit1,2
	PL_PS	$ec8,bwblit2

	PL_PSS	$18a,AckLev2_R,2
	PL_PS	$160,.checkquit
	PL_END


.checkquit
	move.l	d0,-(a7)
	move.b	$bfec01,d0
	ror.b	d0
	not.b	d0
	lea	.skiplevel(pc),a0
	bsr	CheckInGameKeys
	move.l	(a7)+,d0

	jmp	$d000+$222

.skiplevel
	move.w	#$4e71,$d000+$2e0
	move.w	#$4c,$d000+$1e6
	rts

bwblit1	move.w	#$40,$dff104		; original code
	bra.w	WaitBlit

bwblit2	bsr	WaitBlit
	move.w	d1,$dff040
	rts

; level 5
PLCODE5_1DISK
	PL_START
	PL_W	$26CA+2,$8000		; fix BLTADAT
	PL_NEXT	PLCODE5_COMMON
	PL_END

; level 5
PLCODE5	PL_START
	PL_W	$26a4+2,$8000		; fix BLTADAT
	PL_NEXT	PLCODE5_COMMON
	PL_END
	
PLCODE5_COMMON
	PL_START
	PL_PSS	$20,wblit1,2
	PL_SA	$102,$122		; skip drive access
	PL_SA	$12a,$132		; skip write to $bfeb01
	PL_SA	$142,$148		; skip write to $bfdb00
	;PL_W	$26a4+2,$8000		; fix BLTADAT

	PL_PSS	$2c8,AckLev1_R,2
	PL_PSS	$2d4,AckLev1_2_R,2
	PL_PSS	$2e0,AckLev1_3_R,2
	PL_PSS	$2fa,AckLev2_R,2
	PL_PSS	$306,AckLev2_R,2
	PL_PSS	$326,AckBLT_R,2
	PL_PSS	$342,AckCOP_R,2
	PL_PSS	$336,AckVB_R,2
	PL_PS	$35a,AckLev4_R
	PL_PSS	$372,AckLev5_2_R,2
	PL_PSS	$37e,AckLev5_R,2
	PL_PSS	$3a4,AckLev6_R,2
	PL_PSS	$3b0,AckLev6_R,2
	PL_PSS	$3bc,AckLev6_2_R,2

	PL_PS	$3d8,.checkquit
	PL_END

.checkquit
	move.b	$bfec01,d1

	move.b	d1,d2
	ror.b	#1,d2
	not.b	d2

	movem.l	d0/a0,-(a7)
	move.b	d2,d0
	lea	.skiplevel(pc),a0
	bsr	CheckInGameKeys
	movem.l	(a7)+,d0/a0
	rts

.skiplevel
	move.w	#$4e71,$3000+$c36.w
	move.b	#$60,$3000+$c40.w
	rts

WaitBlitA6
	tst.b	$02(a6)
.wblit	btst	#6,$02(a6)
	bne.b	.wblit
	rts

PLBOOT_1DISK
	PL_START
	PL_R	$138c			; disable drive check
	PL_SA	$1876,$1886		; skip drive access
	PL_P	$522,LoadFile

	PL_P	$156,.patchtitle	; title
	PL_P	$190,.patchtitle_2	; end
	PL_P	$20c,.patchcode1	; level 1
	PL_P	$2bc,.patchcode		; level 2
	PL_P	$36c,.patchbatcave	; level 3
	PL_P	$3d4,.patchcode_2	; level 4 (same code as level 2)
	PL_P	$496,.patchcode5	; level 5
	
	PL_PS	$17ae,wblit1_A6
	PL_END

; level 5
.patchcode5
	move.w	#$2000,sr
	lea	PLCODE5_1DISK(pc),a0
	bra.w	.dopatch	

; level 4
.patchcode_2
	lea	PLCODE_1DISK(pc),a0
	move.w	#$2000,sr
	lea	$3000.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$3002.w

.patchbatcave
	lea	PLBATCAVE_1DISK(pc),a0
	lea	$d000,a1
	move.w	#$2000,sr
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$d000	

.patchcode
	lea	PLCODE_1DISK(pc),a0
	move.b	#$2e,$2e.w		; fix bug in asc. conversion
.dopatch
	lea	$3000.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$3000.w

.patchcode1
	lea	PLCODE1_1DISK(pc),a0
	lea	$3000.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	st	$22.w			; must not be 0 (bug in game code)
	jmp	$3000.w


.patchtitle
	bsr	LoadHigh

; install trainers
	move.l	TRAINEROPTIONS(pc),d0
	lsr.l	#1,d0
	bcc.b	.noLivesTrainer
	bsr	ToggleLives
.noLivesTrainer

	lsr.l	#1,d0
	bcc.b	.noEnergyTrainer
	bsr	ToggleEnergy
.noEnergyTrainer

	lsr.l	#1,d0
	bcc.b	.noTimeTrainer
	bsr	ToggleTime
.noTimeTrainer	


	lea	PLTITLE_1DISK(pc),a0
	lea	$1c000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$1c000


.patchtitle_2
	lea	PLTITLE_1DISK(pc),a0
	lea	$1c000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$1c004


wblit1_A6
	bsr.w	WaitBlitA6
	move.w	#$4000,$24(a6)		; original code
	rts

PLBOOT	PL_START
	PL_R	$134a			; disable drive check
	PL_SA	$1834,$1844		; skip drive access
	PL_P	$4fc,LoadFile

	PL_P	$142,.patchtitle	; title
	PL_P	$17c,.patchtitle_2	; end
	PL_P	$1f8,.patchcode1	; level 1
	PL_P	$2a8,.patchcode		; level 2
	PL_P	$358,.patchbatcave	; level 3
	PL_P	$3c0,.patchcode_2	; level 4 (same code as level 2)
	PL_P	$470,.patchcode5	; level 5
	PL_PS	$176c,wblit1_A6
	PL_END

; level 5
.patchcode5
	move.w	#$2000,sr
	lea	PLCODE5(pc),a0
	bra.w	.dopatch	

; level 4
.patchcode_2
	lea	PLCODE(pc),a0
	move.w	#$2000,sr
	lea	$3000.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$3002.w


.patchbatcave
	lea	PLBATCAVE(pc),a0
	lea	$d000,a1
	move.w	#$2000,sr
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$d000	

.patchcode
	lea	PLCODE(pc),a0
	move.b	#$2e,$2e.w		; fix bug in asc. conversion
.dopatch
	lea	$3000.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$3000.w
		
.patchcode1
	lea	PLCODE1(pc),a0
	lea	$3000.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	st	$22.w			; must not be 0 (bug in game code)

	
	jmp	$3000.w


.patchtitle
	bsr	LoadHigh

; install trainers
	move.l	TRAINEROPTIONS(pc),d0
	lsr.l	#1,d0
	bcc.b	.noLivesTrainer
	bsr	ToggleLives
.noLivesTrainer

	lsr.l	#1,d0
	bcc.b	.noEnergyTrainer
	bsr	ToggleEnergy
.noEnergyTrainer

	lsr.l	#1,d0
	bcc.b	.noTimeTrainer
	bsr	ToggleTime
.noTimeTrainer	


	lea	PLTITLE(pc),a0
	lea	$1c000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$1c000

.patchtitle_2
	lea	PLTITLE(pc),a0
	lea	$1c000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$1c004



; a0.l: pointer to file table
; format is as follows:
; dc.w offset to disk name
; dc.w offset to file name
; dc.l destination (final)
; dc.l file size (will be set by loading routine)
; dc.l start of loaded data/destination (will be set by loading routine)
;
; this is repeated for every file until the offset to filename = 0 (end of TAB)

LoadFile
	movem.l	d0-a6,-(a7)
	addq.w	#2,a0			; skip offset to disk name
	move.l	a0,a5			; save ptr to file table
.loop	tst.w	(a5)
	beq.b	.done
	move.w	(a5),d0			; offset to file name
	lea	(a5,d0.w),a0

	lea	.name(pc),a1
	lea	11(a1),a2		; a2: end of file name
	moveq	#11-1,d7
.copy	move.b	(a0)+,(a1)+
	dbf	d7,.copy
; remove spaces at end of file name
	moveq	#11-1,d7
.search	cmp.b	#" ",-(a2)
	dbne	d7,.search

.ok	sf	1(a2)			; null terminate
	
	lea	.name(pc),a0
	move.l	a0,a3			; save file name
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	btst	#0,d0
	beq.b	.no_odd_size
	addq.l	#1,d0
.no_odd_size	
	move.l	d0,6(a5)		; store in tab
	lea	$7c7fc,a6
	sub.l	d0,a6
	move.l	a6,10(a5)

	move.l	a3,a0			; file name
	move.l	a6,a1			; destination
	jsr	resload_LoadFile(a2)

	move.l	6(a5),d0		; size
	move.l	a6,a0

	move.l	DecrunchRout(pc),a2
	jsr	(a2)
	

	add.w	#14,a5			; next file entry
	bra.b	.loop


.done	movem.l	(a7)+,d0-a6
	rts


.name	ds.b	12			; max. 11 chars + null-termination
	

DecrunchRout_2Disk
	move.l	2(a5),$cf0.w		; final destination :)
	jmp	$800+$ee0.w		; decrunch

DecrunchRout_1Disk
	move.l	2(a5),$d16.w		; final destination :)
	jmp	$800+$f22.w		; decrunch

; do not change order of the next 2 longs!
DecrunchRout	dc.l	0
HighscoreLoc	dc.l	0


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

.debug	pea	(TDREASON_DEBUG).w
	bra.w	EXIT

.exit	bra.w	QUIT


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine



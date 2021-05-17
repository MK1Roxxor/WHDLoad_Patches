; V2.00, StingRay, 16.05.2021
; - DMA wait in replayer fixed
; - high score loading changed, default highscore is not needed anymore,
;   RNC ProPacked file removed from slave
; - high score saving fixed to use proper long for the size, worked by
;   coincidence with move.w
; - 2 seconds delay after saving high scores removed, this is WHDLoad's job!
; - blitter waits corrected
; - debug code in loader patch removed
; - WHDLoad version/revision check removed
; - data directory removed
; - blitter wait patches are not needed for the intro, call to install
;   the blitter wait patches removed
; - patch for intro code redone
; - 68000 quitkey support
; - high score file renamed to RaceDrivin.high
; - extended memory check in game disabled
; - CUSTOM1 changed, if used, intro is shown, otherwise the game is run
; - both parts (intro and game) are loaded to the real destination now and
;   relocation is skipped
; - WHDLoad v17+ features used (config)
; - various optimisations and other changes

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i


FLAGS	= WHDLF_EmulTrap|WHDLF_NoDivZero|WHDLF_ClearMem


HEADER
ws	SLAVE_HEADER			;ws_Security+ws_ID
	DC.W	17			;ws_Version
	DC.W	FLAGS			;ws_Flags
	DC.L	$80000			;ws_BaseMemSize
	DC.L	0			;ws_ExecInstall
	DC.W	slv_GameLoader-ws	;ws_GameLoader
	DC.W	0			;ws_CurrentDir
	DC.W	0			;ws_DontCache
	DC.B	0			;ws_keydebug
	DC.B	$59			;ws_keyexit
	DC.L	0			;ws_ExpMem
	DC.W	slv_name-ws		;ws_name
	DC.W	slv_copy-ws		;ws_copy
	DC.W	slv_info-ws		;ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	
	dc.b	"C1:B:Run Intro"
	dc.b	0

	CNOP	0,2

slv_GameLoader
	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

	move.l	CUSTOM1(pc),d0
	beq.b	PatchGame

	lea	DiskNum(pc),a0
	subq.b	#1,(a0)
	bra.w	PatchIntro
	


PatchGame
	lea	$1000.w,a0
	move.l	a0,a5

	move.l	#$2C00,d0
	move.l	#$25800,d1
	moveq	#2,d2
	move.l	d1,-(sp)
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	move.l	(sp)+,d0
	move.l	a5,a1
	bsr.b	FixBlit

	lea	PLGAME(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	move.l	#(WCPUF_Base_NCS|WCPUF_Exp_NCS|WCPUF_Slave_NCS|WCPUF_IC|WCPUF_DC|WCPUF_NWA|WCPUF_SB|WCPUF_BC|WCPUF_SS|WCPUF_FPU),d0
	move.l	d0,d1
	or.l	#(WCPUF_Base_WT|WCPUF_Exp_WT|WCPUF_Slave_CB),d0
	or.l	#(WCPUF_Base_CB|WCPUF_Exp_CB|WCPUF_Slave_CB),d1
	move.l	resload(pc),a2
	jsr	resload_SetCPU(a2)

	; V2.01: Initialise keyboard and some other stuff
	jsr	$189e(a5)

	jmp	$62(a5)			; $62: skip relocation


FixBlit
	movem.l	d0-a6,-(a7)


.loop	; move.w #$ffff,$44(a5)
	cmp.l	#$3B7CFFFF,(a1)
	bne.b	.noblit1
	cmp.w	#$44,(4,a1)
	bne.b	.noblit1
	lea	WaitBlit1(pc),a0
	bra.b	.patch
.noblit1

	; move.l -$a(a4),$50(a5)
	cmp.l	#$2B6CFFF6,(a1)
	bne.b	.noblit2
	cmp.w	#$50,(4,a1)
	bne.b	.noblit2
	lea	WaitBlit2(pc),a0
	bra.b	.patch
.noblit2

	; move.l -$12(a4),$54(a5)
	cmp.l	#$2B6CFFEE,(a1)
	bne.b	.next
	cmp.w	#$54,(4,a1)
	bne.b	.next
	lea	WaitBlit3(pc),a0

.patch	move.w	#$4EB9,(a1)
	move.l	a0,(2,a1)

.next	addq.l	#2,a1
	subq.l	#2,d0
	bpl.b	.loop

	movem.l	(a7)+,d0-a6
	rts



; ---------------------------------------------------------------------------
; V2.00, StingRay

PatchIntro
	lea	$200.w,a0
	move.l	a0,a5
	move.l	#$3C00,d0
	move.l	#$2000,d1
	moveq	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)

	lea	PLINTRO_BASECODE(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

	move.l	ATTNFLAGS(pc),d0
	btst	#AFB_68010,d0
	beq.b	.is_68000

	; fix trap handler
	lea	PLTRAP(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)
.is_68000

	jmp	$4a(a5)		; $4a: skip relocation


PLTRAP	PL_START

	PL_P	$1d2,.AdaptStackFrame
	PL_P	$21c,.ExitTrap
	
	PL_END

.AdaptStackFrame
	lea	200+$1578.w,a0
	movem.l	d1-d7/a1-a6,(a0)

	; convert the 4 word stack frame used on 68010+
	; to the 68000 stack frame format
	lea	-18(a7),a7
	clr.w	(a7)
	clr.l	2(a7)
	move.l	($1A,sp),(6,sp)
	move.l	($1E,sp),(10,sp)
	move.l	($22,sp),(14,sp)

	jmp	$3DA.W

.ExitTrap
	lea	18(a7),a7
	movem.l	(a0),d1-d7/a1-a6
	rte




PLINTRO_BASECODE
	PL_START
	PL_P	$afa,LOADER
	PL_PS	$fe,.PatchIntroCode
	PL_END


.PatchIntroCode
	lea	PLINTRO_MAINCODE(pc),a0
	move.l	$200+$15c4.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	move.l	$200+$15c4.w,a0
	rts	

PLINTRO_MAINCODE
	PL_START
	PL_PS	$1fe,.AckVBI
	PL_PS	$29a,.CheckQuitKey
	PL_R	$2caa			; disable ext. memory check
	PL_S	$3ce,6			; skip or.w #1,$34(a0)
	PL_PSS	$980,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$996,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$10ba,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$10d0,FixDMAWait,2	; fix DMA wait in replayer
	PL_END

.AckVBI	move.w	d0,$dff09c
	move.w	d0,$dff09c
	rts

.CheckQuitKey
	bsr.b	.GetKey
	ror.b	d0
	not.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT


.GetKey	clr.w	d0
	move.b	$c00(a0),d0
	rts


; ---------------------------------------------------------------------------



PLGAME	PL_START
	PL_P	$b6a,CopyLock


	PL_P	$206a,SaveHighscores
	PL_P	$262,LOADER


	; V2.00, StingRay
	PL_PSS	$6ee4,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$6efa,FixDMAWait,2
	PL_PSS	$761e,FixDMAWait,2
	PL_PSS	$7634,FixDMAWait,2

	PL_PSS	$ac,.LoadHighscores,2


	PL_PS	$1f54,.wblit1
	PL_PS	$1f8c,.wblit2
	PL_PS	$1fc4,.wblit2

	PL_PS	$683c,.CheckQuitKey

	PL_R	$b8			; disable ext. memory check
	PL_END

.CheckQuitKey
	not.b	d0
	ror.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	rts


.wblit1	bsr	WaitBlit
	move.w	#0,$74(a5)
	rts

.wblit2	bsr	WaitBlit
	move.w	#$ffff,$74(a5)
	rts


.LoadHighscores
	lea	HighscoreName(pc),a0
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.no_highscore_file

	lea	HighscoreName(pc),a0
	lea	$2BE4(a6),a1
	jsr	resload_LoadFile(a2)
	lea	$2BE4(a6),a0
	bsr.w	DecryptHighscores
.no_highscore_file	

	jsr	$1000+$2770.w
	jmp	$1000+$6384.w


FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d0
.loop	move.b	$dff006,d1
.same_line
	cmp.b	$dff006,d1
	beq.b	.same_line
	dbf	d0,.loop	
	movem.l	(a7)+,d0/d1
	rts



CopyLock
	move.l	#$3D742CF1,($60).W
	move.l	#$BA808BE6,($29762)
	move.l	#$28F2,($14).W
	rts



SaveHighscores
	movem.l	d0-d7/a0-a6,-(sp)
	lea	$2BE4(a6),a0
	move.l	a0,-(sp)
	bsr.w	DecryptHighscores
	;move.w	#720,d0			; bug!
	move.l	#720,d0
	lea	(HighscoreName,pc),a0
	move.l	(sp),a1
	move.l	(resload,pc),a2
	jsr	(resload_SaveFile,a2)
	move.l	(sp)+,a0
	bsr.b	DecryptHighscores


	movem.l	(sp)+,d0-d7/a0-a6

	moveq	#0,d0
	jmp	$7BE4.W

DecryptHighscores
	movem.l	d0/d1/a0,-(a7)
	move.w	#720-1,d0
	move.l	#$87F4A717,d1
.loop	eor.b	d1,(a0)+
	eor.w	d0,d1
	ror.l	d0,d1
	dbf	d0,.loop
	movem.l	(a7)+,d0/d1/a0
	rts



WaitBlit1
	bsr.b	WaitBlit
	move.w	#$FFFF,($44,a5)
	rts

WaitBlit2
	bsr.b	WaitBlit
	move.l	(-10,a4),($50,a5)
	rts

WaitBlit3
	bsr.b	WaitBlit
	move.l	(-$12,a4),($54,a5)
	rts

WaitBlit
	tst.b	2(a5)
.wblit	tst.b	$BFE001
	tst.b	$BFE001
	btst	#6,2(a5)
	bne.b	.wblit
	tst.b	2(a5)
	rts

; d1.w: starting sector
; d2.w: number of sectors to load
; d3.w: command
; a0.l: destination

LOADER	tst.w	d2
	beq.b	.exit

	movem.l	d1-a6,-(a7)
	move.w	d1,d0
	mulu.w	#512,d0
	move.w	d2,d1
	mulu.w	#512,d1
	move.b	DiskNum(pc),d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d1-a6

.exit	moveq	#0,d0
	rts


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	(resload,pc),-(sp)
	addq.l	#4,(sp)
	rts

resload
	DC.L	0

TAGLIST		DC.L	WHDLTAG_ATTNFLAGS_GET
ATTNFLAGS	DC.L	0

		DC.L	WHDLTAG_CUSTOM1_GET
CUSTOM1		DC.L	0
		DC.L	TAG_DONE


slv_name	DC.B	"Race Drivin'",0
slv_copy	DC.B	'1991 Tengen / Domark / Atari',0
slv_info	dc.b	"installed by Girv & StingRay/[S]carab^Scoopex",10
		dc.b	"Version 2.01 (17.05.2021)",0

HighscoreName	dc.b	'RaceDrivin.high',0
DiskNum		dc.b	2

	END

***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   UNJUST SENTENCE/APPENDIX WHDLOAD SLAVE   )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             October 2019                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 14-Oct-2019	- added delays were responsible for the access fault
;		  in the last part (module wasn't loaded correctly as
;		  d0 (start sector) was trashed)
;		- ATTNFLAGS weren't read correctly, fixed. CPU/FPU/MMU
;		  are now displayed correctly
;		- patch is finished: BPLCON0 color bit fixes (x72),
;		  interrupts fixed, double buffering/screen switching bugs
;		  fixed (x4), access fault fixed (write to $dff000), SMC
;		  fixed, BLTCON settings fixed (x16, line drawing routine),
;		  BLTCON1 settings fixed( line drawing routine), 
;		  BLTADAT settings fixed (x4)
;		  

; 13-Oct-2019	- part 2 glitch fixed (double buffering recoded)
;		- a while later: glitch in part 6 fixed as well, also
;		  a double buffering problem
;		- same double buffering bug in 2 other vector parts fixed
;		- delays in both picture parts and loader added

; 12-Oct-2019	- remaining parts patched
;		- memory required changed to 512k chip/512k fast
;		- config check patched to show the correct info (memory,
;		  display etc.)
;		- support for hidden part added
;		- part 2 (presents) and part6 (vector ball) still have
;		  glitches

; 11-Oct-2019	- work started
;		- first 9 parts patched

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


.config	dc.b	"C1:B:Run Hidden Part"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Appendix/UnjustSentence",0
	ENDC

.name	dc.b	"Unjust Sentence",0
.copy	dc.b	"1994 Appendix",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (14.10.2019)",0

	CNOP	0,4

TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
ATTNFLAGS	dc.l	0
		dc.l	WHDLTAG_CHIPREVBITS_GET
CHIPREV		dc.l	0
		dc.l	TAG_DONE

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


; install level 2 interrupt
	bsr	SetLev2IRQ

; load boot
	lea	$7a000,a0
	move.l	#$600,d0
	move.l	#$3000,d1
	moveq	#1,d2
	move.l	a0,a5
	move.l	d1,d5
	jsr	resload_DiskLoad(a2)

	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$8edd,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok	

; patch
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

; fake memory list
	lea	$570(a5),a0
	clr.l	(a0)+			; memory start: $0.w
	move.l	#$80000,(a0)+		; memory end: $100000
	move.w	#"C",(a0)+		; memory typ: chip

	move.l	HEADER+ws_ExpMem(pc),d0
	move.l	d0,(a0)+
	add.l	#$80000,d0
	move.l	d0,(a0)+
	move.w	#"E",(a0)+
	move.l	#-1,(a0)


; set ext. memory
	move.l	HEADER+ws_ExpMem(pc),d0
	add.l	#$10000,d0
	move.l	d0,$102.w
	add.l	#$40000,d0
	move.l	d0,$106.w
	add.l	#$10000,d0
	move.l	d0,$110.w


	move.l	#$80000,$472(a5)	; chip memory size
	move.l	#$80000,$47a(a5)	; fast memory size
	move.l	#$100000,$47e(a5)	; total memory size

; and start demo
	jmp	(a5)





QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)


KillSys	move.w	#$7fff,$dff09a
	bsr.b	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	rts


WaitRaster
.wait1	btst	#0,$dff005
	beq.b	.wait1
.wait2	btst	#0,$dff005
	bne.b	.wait2
	rts



PLBOOT	PL_START
	PL_SA	$0,$3c			; skip CPU check
	PL_P	$27d8,Load
	PL_SA	$c8,$18a		; skip memory check
	PL_PSS	$13c2,AckVBI_R,2
	PL_PSS	$13e2,AckVBI_R,2
	PL_SA	$aa,$b2			; skip writes to ECS registers
	PL_SA	$c2,$c8			; skip write to BEAMCON0
	PL_PS	$8f0,.GetCPU
	PL_SA	$9f2,$a42		; skip drive checks
	PL_SA	$a42,$ac0		; skip memory check
	PL_PS	$cb2,.GetChipRev

	PL_PS	$114e,PatchTitle	; Appendix
	PL_PS	$116a,PatchPart2	; Presents
	PL_PS	$1180,PatchPart3	; Credits
	PL_PS	$11ac,PatchPart4	; Title
	PL_PS	$11d2,PatchPart5	; Tunnel
	PL_PS	$11f8,PatchPart6	; Vector "Ball"
	PL_PS	$121e,PatchPart7	; Cycle Pictures
	PL_PS	$1254,PatchPart8	; Picture
	PL_PS	$126a,PatchPart9	; line vector
	PL_PS	$1286,PatchPart10	; Greetings
	PL_PS	$12ac,PatchPart11	; "Fire" vector
	PL_PS	$12c2,PatchPart12	; rotating picture 
	PL_PS	$12d8,PatchPart13	; line vector 2
	PL_PS	$12ee,PatchPart14	; dots
	PL_P	$138a,PatchPart15	; End scroller

; enable and run hidden part
	PL_IFC1
	PL_SA	$1aa,$1bc
	PL_ENDIF

	PL_END

	
.GetCPU	move.l	ATTNFLAGS(pc),d0
	rts

.GetChipRev
	moveq	#-1,d0			; default: OCS denise

	move.l	CHIPREV(pc),d1
	lsr.b	#1,d1
	bcc.b	.exit
	move.b	#%11111100,d0		; ECS

	lsr.b	#1,d1
	lsr.b	#1,d1
	bcc.b	.exit
	move.b	#%11111000,d0		; AGA
.exit	rts



; $184
PatchTitle
	lea	PLTITLE(pc),a0
	bra.w	Patch36k

PLTITLE	PL_START
	
	PL_END

; $228
PatchPart2
	lea	PLPART2(pc),a0
	bra.w	Patch36k

PLPART2	PL_START
	PL_ORW	$1854+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$1898+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$1900+2,1<<9		; set BPLCON0 color bit


	PL_PS	$82,.SwapScreens
	PL_SA	$a8,$b6
	PL_END


.SwapScreens
	lea	$36000+$188a,a0		; plane pointer in copperlist

SwapScreens
	move.l	d1,(a2)+
	move.l	d0,(a2)

	move.w	d1,6-2(a0)
	swap	d1
	move.w	d1,(a0)

	move.w	#$8400,$96(a6)		; original code
	rts	


; $242
PatchPart3
	lea	PLPART3(pc),a0
	bra.w	Patch36k

PLPART3	PL_START
	PL_ORW	$c82+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$cfa+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$d6a+2,1<<9		; set BPLCON0 color bit
	PL_PSA	$1c4,.wblit,$1cc
	PL_END

.wblit	move.l	d7,(a4)
	movem.l	d0-d6,4(a4)

	tst.b	$dff002
.wb	btst	#6,$dff002
	bne.b	.wb
	rts

; $262	
PatchPart4
	lea	PLPART4(pc),a0
	bra.w	Patch36k

PLPART4	PL_START
	PL_ORW	$16ac+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$16f0+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$17c8+2,1<<9		; set BPLCON0 color bit
	PL_P	$9c,.fix		; fix buggy write to DMACON

	PL_PS	$ba,.SwapScreens
	PL_SA	$e0,$ee
	PL_END

.SwapScreens
	lea	$36000+$16e2,a0
	bra.w	SwapScreens

.fix	move.w	#$5a0,$96(a6)
	move.w	#0,$180(a6)
	rts

; $294
PatchPart5
	lea	PLPART5(pc),a0
	bra.w	Patch36k

PLPART5	PL_START
	PL_PS	$1b4,.flush
	PL_ORW	$77a+2,1<<9		; set BPLCON0 color bit
	PL_W	$238+4,$8000		; set BLTADAT for line drawing
	PL_END

.flush	lea	$c00.w,a4
	moveq	#$2f,d7
Flush	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts


; $2a8
PatchPart6
; fix BLTCON0 table
	lea	$36000+$1ca6,a1
	move.w	#($1cc6-$1ca6)/2-1,d7
.loop	or.w	#1<<8,(a1)+		; set SRCD = 1
	dbf	d7,.loop


	lea	PLPART6(pc),a0
	bra.w	Patch36k

PLPART6	PL_START
	PL_ORW	$1134+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$11e4+2,1<<9		; set BPLCON0 color bit
	PL_PS	$2a0,.flush
	PL_PS	$cd4,.FixBltCon1

	PL_PS	$174,.SwapScreens
	PL_SA	$1a2,$1cc
	PL_END


.SwapScreens
	addq.l	#6,d0
	addq.l	#6,d2
	addq.l	#6,d4
	addq.l	#6,d6

	lea	$36000+$1194+2,a0	; plane pointers in copperlist
	move.w	d0,4(a0)
	swap	d0
	move.w	d0,(a0)
	addq.w	#8,a0
	move.w	d2,4(a0)
	swap	d2
	move.w	d2,(a0)
	addq.w	#8,a0
	move.w	d4,4(a0)
	swap	d4
	move.w	d4,(a0)
	addq.w	#8,a0
	move.w	d6,4(a0)
	swap	d6
	move.w	d6,(a0)


	move.w	#$8400,$96(a6)		; original code
	rts


.flush	move.w	#$0400,$96(a6)
	bra.w	Flush	

.FixBltCon1
	and.w	#$ff,d0
	move.w	d2,d4
	sub.w	d3,d2
	add.w	d3,d3
	rts



; $2b2
PatchPart7
	lea	PLPART7(pc),a0
	bra.w	Patch36k

PLPART7	PL_START
	PL_ORW	$4aa+2,1<<9		; set BPLCON0 color bit
	PL_END

; $2b7
PatchPart8
	lea	PLPART8(pc),a0
	bra.w	Patch36k

PLPART8	PL_START
	PL_PS	$ac,.delay
	PL_END

.delay	trap	#1

	moveq	#3*10,d0
	move.l	resload(pc),a0
	jsr	resload_Delay(a0)

	jmp	$36000+$290		; fade down


; $383
PatchPart9
	lea	PLPART9(pc),a0
	bra.w	Patch36k

PLPART9	PL_START
	PL_ORW	$ce6+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$384+2,1<<9		; set BPLCON0 color bit
	PL_W	$1f4+4,$8000		; set BLTADAT for line drawing
	PL_ORW	$2bb4+2,1<<9		; set BPLCON0 color bit
	PL_PS	$16f6,.SwapScreens
	PL_SA	$171c,$172a
	PL_END

.SwapScreens
	lea	$36000+$2be6,a0		; plane pointer in copperlist
	bra.w	SwapScreens

; $38a
PatchPart10
	lea	PLPART10(pc),a0
	bra.w	Patch36k

PLPART10
	PL_START
	PL_ORW	$d36+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$d7a+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$dbe+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$e02+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$e46+2,1<<9		; set BPLCON0 color bit
	PL_END


; $3aa
PatchPart11
	lea	PLPART11(pc),a0
	bra.w	Patch36k

PLPART11
	PL_START
	PL_ORW	$5aa+2,1<<9		; set BPLCON0 color bit
	PL_W	$1e8+4,$8000		; set BLTADAT for line drawing
	PL_END


; $2e9
PatchPart12
	lea	PLPART12(pc),a0
	bra.w	Patch36k

PLPART12
	PL_START
	PL_ORW	$11a+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$1aa+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$1b6+2,1<<9		; set BPLCON0 color bit

	PL_ORW	$1e2+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$206+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$22a+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$24e+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$272+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$296+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$2ba+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$2de+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$302+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$326+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$34a+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$36e+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$392+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$3b6+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$3da+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$3fe+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$422+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$446+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$46a+4,1<<9		; set BPLCON0 color bit

	PL_ORW	$566+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$58a+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$5ae+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$5d2+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$5f6+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$61a+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$63e+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$662+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$686+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$6aa+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$6ce+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$6f2+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$716+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$73a+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$75e+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$782+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$7a6+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$7ca+4,1<<9		; set BPLCON0 color bit
	PL_ORW	$7ee+4,1<<9		; set BPLCON0 color bit

	PL_PS	$102,.delay
	PL_END

.delay	move.l	d0,-(a7)
	moveq	#3*10,d0
	move.l	resload(pc),a0
	jsr	resload_Delay(a0)
	move.l	(a7)+,d0

	move.l	$102.w,a0
	rts

; $3b3
PatchPart13
	lea	PLPART13(pc),a0
	bra.b	Patch36k

PLPART13
	PL_START
	PL_ORW	$dec+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$ee0+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$f78+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$f80+2,1<<9		; set BPLCON0 color bit
	PL_ORW	$fe4+2,1<<9		; set BPLCON0 color bit
	PL_PS	$1de,.flush
	PL_W	$974+4,$8000		; set BLTADAT for line drawing
	PL_END

.flush	move.w	(a1,d5.w),$4a(a4)
	bra.w	Flush

; $3c7
PatchPart14
	lea	PLPART14(pc),a0
	bra.b	Patch36k

PLPART14
	PL_START
	PL_ORW	$500+2,1<<9		; set BPLCON0 color bit
	PL_END
	

; $49c
PatchPart15
	lea	PLPART15(pc),a0
	bra.b	Patch36k

PLPART15
	PL_START
	PL_ORW	$fa+2,1<<9		; set BPLCON0 color bit
	PL_W	$fe,$1fe		; FMODE -> NOP
	PL_W	$102,$1fe		; BPLCON3 -> NOP
	PL_ORW	$212+2,1<<9		; set BPLCON0 color bit
	PL_END


Patch36k
	lea	$36000,a1
	move.l	a1,-(a7)
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)


; d0.w: start sector
; d1.w: sectors to load
; a0.l: destination

Load	move.w	d1,d7

	mulu.w	#512,d0
	mulu.w	#512,d1
	moveq	#1,d2
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)

	move.w	d7,d0
	lsr.w	#2,d0
	jsr	resload_Delay(a2)
	rte


AckVBI_R
	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
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


	lea	Key(pc),a2
	
	btst	#3,$1e+1(a0)			; PORTS irq?
	beq.b	.end

	btst	#3,$d00(a1)			; KBD irq?
	beq.b	.end

	moveq	#0,d0
	move.b	$c00(a1),d0
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)+

	move.l	(a2),d1
	beq.b	.noCust
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.noCust

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



Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0

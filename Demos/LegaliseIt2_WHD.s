***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   LEGALISE IT 2/ANARCHY WHDLOAD SLAVE      )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            January 2019                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 21-Jan-2019	- work started
;		- and finished a while later, byte writes to BLTCON1
;		  fixed (x3), DMA wait in replayer fixed (x12), byte
;		  write to volume register fixed, interrupts fixed,
;		  CPU dependent delays in sample player fixed (x2), 
;		  Bplcon0 color bit fixes (x2), decrunchers relocated
;		  to fast memory, line drawing routines fixed (x3),
;		  intro can be skipped with CUSTOM1, hidden parts can
;		  be enabled with CUSTOM2/3

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $46		; F10
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


.config	dc.b	"C1:B:Skip Intro;"
	dc.b	"C2:B:Run Hidden Part 1;"
	dc.b	"C3:B:Run Hidden Part 2"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/Anarchy/LegaliseIt2/"
	ENDC
	dc.b	"data",0

.name	dc.b	"Legalise It 2",0
.copy	dc.b	"1992 Anarchy",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.2 (21.01.2019)",0

Name	dc.b	"LegalizeIt2",0
	CNOP	0,4

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

; install level 2 interrupt
	bsr	SetLev2IRQ

; load demo
	lea	Name(pc),a0
	lea	$70000,a1
	move.l	a1,a5
	jsr	resload_LoadFile(a2)

	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$4279,d0
	beq.b	.ok


	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT

.ok
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

; set ext. memory
	move.l	HEADER+ws_ExpMem(pc),$132(a5)

	jmp	$a(a5)



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
.wait1	btst	#0,$dff005
	beq.b	.wait1
.wait2	btst	#0,$dff005
	bne.b	.wait2
	rts

AckCOP	move.w	#1<<4,$dff09c
	move.w	#1<<4,$dff09c
	rte

AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte


PLBOOT	PL_START
	PL_ORW	$17c+2,1<<3		; enable level 2 interrupts
	PL_P	$196,AckCOP
	PL_R	$73a			; disable directory loading
	PL_P	$48a,LoadFile
	PL_PS	$8c,.patchIntro
	PL_P	$e6,.patchMain	

	PL_IFC2
	PL_PS	$10,.RunHiddenPart1
	PL_ENDIF

	PL_IFC3
	PL_PS	$10,.RunHiddenPart2
	PL_ENDIF
	
	PL_P	$1a0,Decrunch
	PL_END

.RunHiddenPart1
	lea	.Hidden(pc),a1
	lea	PLHIDDEN1(pc),a4
.patchHidden
	move.l	HEADER+ws_ExpMem(pc),a0
	move.l	a0,a5
	bsr	LoadFile
	
	move.w	#$4e75,$1a8(a5)		; disable jmp $20000
	move.l	a4,-(a7)
	jsr	$20(a5)			; decrunch
	move.l	(a7)+,a0
	lea	$20000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$20000

.RunHiddenPart2
	lea	.Hidden(pc),a1
	addq.b	#1,6(a1)
	lea	PLHIDDEN2(pc),a4
	bra.b	.patchHidden
	

.Hidden	dc.b	"Hidden1",0



.patchIntro
	lea	PLINTRO(pc),a0
	pea	$8000
.patch	move.l	(a7),a1
	move.l	d0,-(a7)
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	move.l	(a7)+,d0
	rts

.patchMain
	lea	PLMAIN(pc),a0
	pea	$4000.w

; fix BLTCON0 table
	move.l	(a7),a5
	lea	$2fee(a5),a1
	move.w	#($3eee-$2fee)/2-1,d7
.fix	or.w	#1<<8,(a1)+
	dbf	d7,.fix
	


	bra.b	.patch


LoadFile
	exg	a0,a1
	move.l	resload(pc),a2
	jmp	resload_LoadFile(a2)

Decrunch
	move.l	resload(pc),-(a7)
	add.l	#resload_Decrunch,(a7)
	rts


PLINTRO	PL_START
	PL_PSS	$b60,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$b76,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$12be,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$12d4,FixDMAWait,2	; fix DMA wait in replayer

	PL_PSS	$53e,.delay,2		; fix delay in sample player
	PL_PSS	$580,.delay,2		; fix delay in sample player

	PL_P	$62,AckCOP
	PL_ORW	$40+2,1<<3		; enable level 2 interrupts

	PL_IFC1
	PL_R	0
	PL_ENDIF
	
	PL_END

.delay	move.w	#500/$34,d7
.loop	move.b	$dff006,d0
.wait	cmp.b	$dff006,d0
	beq.b	.wait
	dbf	d7,.loop	
	rts

PLMAIN	PL_START
	PL_R	$6016			; disable directory loading
	PL_P	$5d66,LoadFile
	PL_PSS	$4bf6,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$4c0c,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$5354,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$536a,FixDMAWait,2	; fix DMA wait in replayer
	
	PL_PS	$3f36,.FixLine
	PL_PS	$177e,.FixLine2

	PL_ORW	$6628+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$6768+2,1<<9		; set Bplcon0 color bit

	PL_PS	$6154,.checkQuit	

	PL_P	$5a7c,Decrunch
	PL_P	$c88,.DiskCheck		; disk 1
	PL_P	$d0c,.DiskCheck		; disk 2
	PL_END

.DiskCheck
	moveq	#0,d6			; correct disk in drive
	rts

.checkQuit
	move.b	$4000+$14866,d0
	ror.b	d0
	not.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT
	bra.w	FixDMAWait

	

.FixLine
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	6(a1),d0
	move.w	d0,$42(a6)
	move.l	(a7)+,d0
	rts

.FixLine2
	move.l	a0,-(a7)
	lea	$4000+$179c,a0
	move.b	(a0,d5.w),d5
	move.w	d5,$42(a6)
	move.l	(a7)+,a0
	rts


PLHIDDEN1
	PL_START
	PL_PSS	$52c,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$542,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$c8a,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$ca0,FixDMAWait,2	; fix DMA wait in replayer
	PL_P	$10a,AckCOP
	PL_ORW	$f0+2,1<<3		; enable level 2 interrupts
	
	PL_END

PLHIDDEN2
	PL_START
	PL_SA	$a,$22			; skip OS stuff
	PL_SA	$7c,$94			; don't patch exception vectors
	PL_P	$acfc,AckLev6
	PL_P	$ad54,AckLev6
	PL_P	$f6,QUIT
	PL_PS	$106e,.FixLine
	PL_PS	$22,.FixTab
	PL_P	$b582,.FixAudXVol	; fix byte write to volume register
	PL_ORW	$ab9c+2,1<<3		; enable level 2 interrupts
	PL_END

.FixAudXVol
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	$13(a1),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts


.FixTab
	lea	$20000+$1094,a0
	move.w	#($10b4-$1094)/2-1,d7
.loop	or.w	#1<<8,(a0)+
	dbf	d7,.loop
	lea	$dff000,a6		; original code
	rts

.FixLine
	move.l	a0,-(a7)
	lea	$20000+$108c,a0
	move.b	(a0,d5.w),d5
	move.w	d5,$42(a6)
	move.l	(a7)+,a0
	rts



FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d0
.loop	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait
	dbf	d0,.loop
	movem.l	(a7)+,d0/d1
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

	lea	Key(pc),a2
	moveq	#0,d0
	move.b	$c00(a1),d0
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)+
	or.b	#1<<6,$e00(a1)			; set output mode

	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT

	move.l	(a2)+,d1
	beq.b	.nocustom
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.nocustom
	

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
KbdCust	dc.l	0			; ptr to custom routine

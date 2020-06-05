***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(  DON'T YOU WANT ME/PROJECT A WHDLOAD SLAVE )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                               June 2020                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 05-Jun-2020	- work started
;		- and finished about 2 hours later, Bplcon0 color bit
;		  fixes (x9), DDFSTRT fixed (x6), access fault fixed,
;		  OS-friendly CIA interrupt in replay routine recoded,
;		  DMA wait in replayer fixed (x4), timing fixed, OS stuff
;		  patched


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	INCLUDE	Exec/Exec.i
	INCLUDE	lvo/Exec.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem
QUITKEY		= $59		; F10
;DEBUG

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
;	dc.w	0		; ws_kickname
;	dc.l	0		; ws_kicksize
;	dc.w	0		; ws_kickcrc

; v17
;	dc.w	.config-HEADER	; ws_config


;.config	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Demos/ProjectA/DontYouWantMe",0
	ENDC

.name	dc.b	"Felix - Don't You Want Me",0
.copy	dc.b	"1993 Project A",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (05.06.2020)",0
	CNOP	0,4


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	; install level 2 interrupt
	bsr	SetLev2IRQ


	; load boot
	move.l	#$64000,d0
	move.l	#$1c00,d1
	lea	$40000,a0

	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)
	move.l	d5,d0
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	cmp.w	#$0AAE,d0
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok


	; decrunch
	move.w	#$4e75,$1a8(a5)		; disable jmp $5d000
	jsr	resload_FlushCache(a2)
	jsr	(a5)


	; patch
	lea	PLBOOT(pc),a0
	lea	$50000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	jmp	$5d000




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

FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d0
.loop	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait
	dbf	d0,.loop
	movem.l	(a7)+,d0/d1
	rts


; ---------------------------------------------------------------------------

PLBOOT	PL_START
	PL_SA	$d016,$d03c		; skip OS stuff
	PL_ORW	$d560+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$d5a8+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$d5e8+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$d604+2,1<<9		; set Bplcon0 color bit
	PL_PSA	$d2dc,.LoadMain,$d318
	PL_P	$d354,.PatchMain
	PL_P	$d2d6,.RunMain
	PL_P	$d004,.FixTiming

	PL_W	$d558+2,$2c81		; fix DDFSTRT
	PL_W	$d5a0+2,$2c81		; fix DDFSTRT
	PL_W	$d5e0+2,$7f81		; fix DDFSTRT

	; fix timing
	PL_W	$d05c+2,50
	PL_W	$d06e+2,2		; Project A logo fade up
	PL_W	$d0c8+2,50*4		; display logo
	PL_W	$d0d2+2,3		; fade down

	PL_W	$d13c+2,4		; fade up text
	PL_W	$d15a+2,50*2		; display text
	PL_W	$d164+2,3		; fade down


	PL_W	$d1b2+2,2		; fade up title picture
	PL_W	$d1e8+2,50*4		; display title picture
	PL_W	$d1f2+2,2		; fade down title picture

	PL_W	$d24e+2,50
	PL_W	$d2bc+2,2

	PL_END

.FixTiming
.wait	cmp.b	#$f8,$dff006
	bne.b	.wait
.same_line
	cmp.b	#$f8,$dff006
	beq.b	.same_line
	add.w	#1,d1
	cmp.w	d0,d1
	bne.b	.wait
	rts	
	


.LoadMain
	move.l	#$400,d0
	move.l	#$63000,d1
	lea	$10000,a0
	moveq	#1,d2
	move.l	resload(pc),a1
	jmp	resload_DiskLoad(a1)


.PatchMain
	lea	PLMAIN(pc),a0
	lea	$10000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$70000


.RunMain
	move.l	resload(pc),a0
	jsr	resload_FlushCache(a0)
	jmp	$f000
	

; ---------------------------------------------------------------------------

PLMAIN	PL_START
	PL_SA	$6001c,$60042		; skip OS stuff
	PL_ORW	$60042+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$608e4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$6094c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$60984+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$600c4+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$60f06,FixDMAWait,2	; fix DMA wait in replayer
	PL_PSS	$60f1c,FixDMAWait,2
	PL_PSS	$61650,FixDMAWait,2
	PL_PSS	$61666,FixDMAWait,2
	PL_P	$609c4,SetCIAInt
	PL_PSA	$60bb6,.FixSampleInit,$60bd6
	PL_W	$608dc+2,$2c81		; fix DDFSTRT
	PL_W	$6092c+2,$7081		; fix DDFSTRT
	PL_W	$60964+2,$7f81		; fix DDFSTRT
	PL_END
	
.FixSampleInit
	moveq	#30,d0
.loop	cmp.l	#$80000,a2
	bhs.b	.skip

	clr.l	(a2)
.skip	move.l	a2,(a1)
	moveq	#0,d1
	move.w	42(a0),d1
	asl.l	#1,d1
	add.l	d1,a2
	add.l	#30,a0

	sub.l	#$62000,(a1)+
	dbf	d0,.loop
	rts
	

SetCIAInt
	lea	$dff000,a6
	lea	$bfd000,a0

	move.w	#$2000,d0
	move.w	d0,$9a(a6)
	move.w	d0,$9c(a6)
	

	move.b	#$7f,$d00(a0)
	move.b	#$10,$e00(a0)
	move.b	#$10,$f00(a0)
	move.b	#$82,$d00(a0)


	move.l	#1773447,d0 		; PAL
	move.l	d0,$10000+$60b3a
	divu.w	#125,d0
	move.b	d0,$400(a0)
	lsr.w	#8,d0
	move.b	d0,$500(a0)
	

	pea	NewLev6(pc)
	move.l	(a7)+,$78.w

	move.b	#$83,$d00(a0)
	move.b	#$11,$e00(a0)
	move	#$e000,$9a(a6)
	rts	

NewLev6	movem.l	d0-a6,-(a7)

	tst.b	$bfdd00
	jsr	$10000+$60c1e		; mt_music
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c

	movem.l	(a7)+,d0-a6
	rte



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
	move.b	$c00(a1),d0
	move.b	d0,(a2)

	not.b	d0
	ror.b	d0
	move.b	d0,RawKey-Key(a2)


	move.l	KbdCust(pc),d1
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

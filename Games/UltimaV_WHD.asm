; V1.3, stingray, 12.04.2018
; - RawDIC imager coded
; - source optimised
; - default directory changed to "data"
; - interrupts fixed
; - 68000 quitkey support
; - default quitkey changed to F10
; - Bplcon0 color bit fixes
; - illegal copperlist entries fixed
; - move.w #$C010,$dff09a disabled in slave

; V1.4, 16.05.2023
; - DMA wait in replayer fixed (issue #6167)

DEBUG

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i

HEADER	SLAVE_HEADER		; ws_Security + ws_ID
	dc.w	10		; ws_Version>
	DC.W	6		; ws_Flags>
	DC.L	$80000		; ws_BaseMemSize
	DC.L	0		; ws_ExecInstall
	DC.W	Patch-HEADER	; ws_GameLoader
	DC.W	.dir-HEADER	; ws_CurrentDir
	DC.W	0		; ws_DontCache
	DC.B	0		; ws_keydebug
	DC.B	$59		; ws_keyexit = F10
	DC.L	0		; ws_ExpMem
	DC.W	.name-HEADER	; ws_name
	DC.W	.copy-HEADER	; ws_copy
	DC.W	.info-HEADER	; ws_info
	

	;DC.B	'$VER: Ultima V HD by Dark Angel V1.2 [25/06/98]',0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Ultima5/"
	ENDC
	DC.B	'data',0



.name	dc.b	'Ultima V',0
.copy	dc.b	'1989 Origin',0
.info	dc.b	'Installed by Dark Angel & StingRay/[S]carab^Scoopex',10
	IFD	DEBUG
	dc.b	"Debug!!! "
	ENDC
	dc.b	'Version 1.4 (16.05.2023)',0
Name	DC.B	'loader',0
	CNOP	0,4



Patch	lea	resload(pc),a1
	move.l	a0,(a1)

	moveq	#1,d0
	move.l	d0,d1
	jsr	resload_SetCACR(a0)


	lea	Name(pc),a0
	lea	$60000,a1
	move.l	resload(pc),a6
	jsr	resload_LoadFile(a6)


	move.w	#$4EF9,$60278
	pea	LoadFile(pc)
	move.l	(sp)+,$6027A

	move.w	#$4EF9,$60160
	pea	.PatchMain(pc)
	move.l	(sp)+,$60162

; v1.3, stingray
	lea	PLLOADER(pc),a0
	lea	$60000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)



	move.w	#$87E0,$DFF096
	;move.w	#$C010,$DFF09A		; why?
	jmp	$60000

.PatchMain
	move.w	#$4E75,d0
	move.w	d0,($1C3E).W
	move.w	d0,($1C5E).W
	move.w	d0,($1C24).W
	move.w	d0,($1E78).W
	move.w	d0,($227A).W
	move.w	d0,($2282).W

	move.l	#$4E714E71,d0
	move.l	d0,($45966)
	move.l	d0,($4589C)

	move.w	#$4EF9,($458C0)
	pea	Clear(pc)
	move.l	(sp)+,($458C2)

	move.w	#$4EF9,($457F6)
	pea	Clear2(pc)
	move.l	(sp)+,($457F8)

	move.w	#$4EB9,($44B7E)
	pea	DoAngel(pc)
	move.l	(sp)+,($44B80)

	move.w	#$4EF9,($13BE).W
	pea	Keyboard(pc)
	move.l	(sp)+,($13C0).W

	move.w	#$4EF9,$1AE8.W
	pea	GetFileSize(pc)
	move.l	(sp)+,$1AEA.W

	move.w	#$4EF9,($1BA6).W
	pea	(LoadSomething,pc)
	move.l	(sp)+,($1BA8).W

	move.w	#$4EF9,$1B5E.W
	pea	SaveFile(pc)
	move.l	(sp)+,$1B60.W

; v1.3, stingray
	lea	PLMAIN(pc),a0
	lea	$800.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	jmp	$800.W


PLLOADER
	PL_START
	PL_ORW	$f2+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$21e,AckVBI,2
	PL_END
	
PLMAIN	PL_START
	PL_ORW	$22+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$b6a,AckVBI,2
	PL_W	$2214+0*4,$1fe		; fix illegal copperlist entries
	PL_W	$2214+1*4,$1fe
	PL_W	$2214+2*4,$1fe
	PL_W	$2214+3*4,$1fe
	
	PL_PSS	$456,Fix_DMA_Wait,2
	PL_PSS	$46e,Fix_DMA_Wait,2
	PL_END

AckVBI	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rts


Keyboard
	movem.l	d0/d1/a0/a1,-(sp)
	lea	($BFE001),a1
	btst	#3,($D00,a1)
	beq.w	.exit
	move.b	($C00,a1),d0
	clr.b	($C00,a1)
	lea	Key(pc),a0
	move.b	d0,(a0)
	or.b	#$40,($E00,a1)

	moveq	#3-1,d1
.delay	move.b	$DFF006,d0
.wait	cmp.b	$DFF006,d0
	beq.b	.wait
	dbf	d1,.delay


; stingray, v1.3
	move.b	Key(pc),d0
	ror.b	d0
	not.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT


	and.b	#$BF,($E00,a1)
	clr.b	($11E2).W
	moveq	#0,d0
	move.w	$B924,d0
	cmp.w	#1,d0
	beq.b	.storekey
	move.b	Key(pc),d0
	move.b	d0,$11E2.W
	btst	#0,d0
	bne.b	.skip
	clr.w	$1196.W
	clr.w	$26CC.W
.skip	cmp.b	#$3C,d0
	blo.b	.exit
	cmp.b	#$40,d0
	bhs.b	.exit
	and.w	#1,d0
	move.w	d0,$13BC.w
	bra.b	.exit

.storekey
	lea	($1378).W,a0
	move.w	($13B8).W,d1
	move.b	Key(pc),d0
	move.b	d0,(a0,d1.w)
	btst	#0,d0
	bne.b	.nocls
	clr.w	($26CC).W
.nocls
	add.w	#1,d1
	and.w	#$1F,d1
	move.w	d1,($13B8).W
	bra.b	.skip

.exit
	move.w	#8,$DFF09C

	move.w	#1<<3,$dff09c
	movem.l	(sp)+,d0/d1/a0/a1
	rte

Key	DC.B	0
	DC.B	0

QUIT	pea	(TDREASON_OK).w
	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

DoAngel	move.l	-4(a6),d0
	bne.b	.exit

	moveq	#5,d0
	move.l	d0,(-4,a6)
	move.b	#'A',(a0)
	move.b	#'n',(1,a0)
	move.b	#'g',(2,a0)
	move.b	#'e',(3,a0)
	move.b	#'l',(4,a0)
.exit
	add.l	d0,a0
	clr.b	(a0)
	rts

Clear
	clr.l	(-4,a6)
	jmp	$45926

Clear2
	clr.l	(-4,a6)
	jmp	($4585C)

GetFileSize
	movem.l	d0-d7/a0-a7,-(sp)
	lea	$7448.w,a0
	move.l	resload(pc),a6
	jsr	resload_GetFileSize(a6)
	move.l	d0,$7444.w
	movem.l	(sp)+,d0-d7/a0-a7
	jmp	$1B1E.W

LoadSomething
	tst.w	($1A4C).W
	bmi.b	.loadpart
	bsr.b	LoadFile
	jmp	($1C06).W

.loadpart
	movem.l	d0-d7/a0-a7,-(sp)
	move.l	d0,d2
	add.l	d1,d2
	cmp.l	($7444).W,d2
	ble.b	.ok
	move.l	($7444).W,d0
	sub.l	d1,d0
.ok
	exg	a0,a1
	move.l	(resload,pc),a6
	jsr	resload_LoadFileOffset(a6)
	movem.l	(sp)+,d0-d7/a0-a7
	jmp	$1C06.W

LoadFile
	movem.l	d0-d7/a0-a7,-(sp)
	exg	a0,a1
	move.l	resload(pc),a6
	jsr	resload_LoadFile(a6)
	movem.l	(sp)+,d0-d7/a0-a7
	rts

SaveFile
	movem.l	d0-d7/a0-a7,-(sp)
	exg	a0,a1
	move.l	resload(pc),a6
	jsr	resload_SaveFile(a6)
	movem.l	(sp)+,d0-d7/a0-a7
	jmp	$1B8C.W

Fix_DMA_Wait
	moveq	#8,d0

; d0.w: number of raster lines to wait
Wait_Raster_Lines
	move.w	d1,-(a7)
.loop	move.b	$dff006,d1
.still_in_same_raster_line
	cmp.b	$dff006,d1
	beq.b	.still_in_same_raster_line	
	subq.w	#1,d0
	bne.b	.loop
	move.w	(a7)+,d1
	rts


resload	dc.l	0


	END

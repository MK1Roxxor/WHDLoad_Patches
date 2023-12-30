;---------------T

****************************************************************
; Use the new asm-pro's WX command, or any other assembler that
; handles combined code+bss sections to get a small executable.

; v1.0 by a/b
; - patched: track loader, cache flush, exp. memory, interrupt
;            killer (quit key)
; - fixed: starfield cube left border didn't show up in winuae,
;          display window expanded by 1 pixel
; - fixed: 040+ cache flush workarounds for SMC in sine dots
;          plotter to avoid performance degradation on PiStorm
; - doesn't require 0.5MB exp. memory (disk fully preloaded)

; StingRay
; - line drawing fixed (illegal BLTCON1 settings)
; - 68000 quitkey support
; - parts can be patched separately (see PL_BOOT patch list)

; Thanks to:
; - Stingray for publishing his sources
; - Tom-cat for PiStorm testing and support

****************************************************************
; Disk layout

; trk/len	contents	patched?
;   0/2	loader+intro	Y
;   2/1	music1.1
;   3/1	music1.2
;   4/3	music1.3
;   7/15	music1.4
;  22/8	logo
;  30/13	picture
;  43/10	music1.5
;  53/31	music2
;  84/4	credits
;  88/2	glenz
;  90/4	scrollers
;  94/2	72 glenz
;  96/3	multi-cube
;  99/1	3d dots
; 100/2	glenz+light
; 102/2	cube+balls
; 104/2	glenz cubes
; 106/2	sine dots	Y
; 108/3	rubik
; 111/1	96 light
; 112/1	starfield	Y
; 113/2	shade bobs
; 115/3	logo
; 118/2	end part	Y
; 120

****************************************************************

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i

	INCLUDE	Hardware/dmabits.i
	INCLUDE	hardware/intbits.i
	INCLUDE	hardware/custom.i
	IFND	_custom
_custom	= $dff000
	ENDC
	INCLUDE	hardware/cia.i
	IFND	_ciaa
_ciaa	= $bfe001
	ENDC

TRK_SIZE	EQU	11*512
XMEM_SIZE	EQU	40*1024			; for SMC code (sine dots)

****************************************************************

Header	SLAVE_HEADER			; ws_Security, ws_ID
	DC.W	10			; ws_Version
	DC.W	WHDLF_NoError|WHDLF_ClearMem ; ws_Flags
	DC.L	512*1024		; ws_BaseMemSize
	DC.L	0			; ws_ExecInstall
	DC.W	Patch-Header		; ws_GameLoader
	DC.W	0			; ws_CurrentDir
	DC.W	0			; ws_DontCache
	DC.B	0			; ws_keydebug
	DC.B	$59			; ws_keyexit (F10)
	DC.L	XMEM_SIZE		; ws_ExpMem
	DC.W	.Name-Header		; ws_name
	DC.W	.Copy-Header		; ws_copy
	DC.W	.Info-Header		; ws_info

.Name	DC.B	"Made in Croatia",0
.Copy	DC.B	"1993 Binary (v1.1 1998)",0
.Info	DC.B	"Patched by Amigo/Binary, v1.0 (20.8.2023)",10
	dc.b	"Additional patches by StingRay (30.12.2023)",10
	DC.B	"Make sure to use the AGA/020+",10
	DC.B	"fixed version from 1998.",0
	EVEN

Tags	DC.L	WHDLTAG_ATTNFLAGS_GET
.CPU	DC.L	0
	DC.L	TAG_END

****************************************************************
; Private data

WhdBase	DS.L	1			; keep in this order (postinc)
TrackPtr	DS.L	1

****************************************************************

Patch
	move.l	a0,a5			; a5 = whdload base
	lea	(WhdBase,pc),a2
	move.l	a5,(a2)+

	lea	(Tags,pc),a0
	jsr	(resload_Control,a5)

; Load the entire disk image.
	moveq	#0,d0			; offset
	move.l	#Disk\.End-Disk,d1	; size
	moveq	#1,d2			; diskno
	lea	(Disk,pc),a0		; dest
	move.l	a0,a4			; a4 = disk image
	jsr	(resload_DiskLoad,a5)
	tst.l	d0
	beq.w	LoadFailed

; Check demo version.
	cmp.l	#'1998',($032e,a4)	; bootblock text
	bne.w	WrongVersion

; Patch cache invalidator.
	lea	($23a0,a4),a1		; don't need cpu version
	move.w	(Proto\.Nop,pc),(a1)+
	move.w	(Proto\.Nop,pc),(a1)+

	lea	($23fa,a4),a1
	move.w	(Proto\.Jmp,pc),(a1)+
	lea	(resload_FlushCache,a5),a0
	move.l	a0,(a1)+

; Patch track loader.
	lea	($2420,a4),a1
	move.w	(Proto\.Jmp,pc),(a1)+
	lea	(Loader,pc),a0
	move.l	a0,(a1)+

; Patch starfield cube (left sprite border isn't showing in winuae).
	move.l	a4,a1
	add.l	#112*TRK_SIZE+$0c80,a1
	move.w	#$369f,(a1)		; originally $36a0

; Patch music switching (sine dots).
	move.l	a4,a1
	add.l	#106*TRK_SIZE+$072c,a1
	move.w	(Proto\.Lea3,pc),(a1)+	; cached music2
	move.l	a4,a0
	add.l	#53*TRK_SIZE,a0
	move.l	a0,(a1)+
	moveq	#3+3+2+1+2-1,d0
.PatchSample	move.w	(Proto\.Nop,pc),(a1)+	; don't need sample backup
	dbf	d0,.PatchSample

	
	move.l	a4,a1
	add.l	#106*TRK_SIZE,a1
	move.w	#$4e75,$172(a1)
	pea	PL_SINEDOTS\.Wait_Blit(pc)
	move.w	#$4eb9,$1fc(a1)
	move.l	(a7)+,$1fc+2(a1)
	move.w	#$4e71,$1fc+6(a1)



; Move generated+SMC code (sliding rts) to ext. memory to prevent
; periodic drops to 25fps on PiStorm due to frequent cache flushing.
	move.l	a4,a1
	add.l	#106*TRK_SIZE+$0196,a1
	move.w	(Proto\.Lea5,pc),(a1)+
	move.l	(Header+ws_ExpMem,pc),(a1)+

	move.l	a4,a1
	add.l	#106*TRK_SIZE+$023e,a1
	move.w	(Proto\.Lea2,pc),(a1)+
	move.l	(Header+ws_ExpMem,pc),(a1)+

; Replace per frame full flush with two line flushes to avoid
; severe performance degradation on PiStorm. Full flush is still
; needed each time the code has been fully regenerated.
	move.l	(Tags\.CPU,pc),d0
	btst	#AFB_68040,d0
	beq.b	.No040

	move.l	a4,a1
	add.l	#106*TRK_SIZE+$01f0,a1
	move.w	(Proto\.Jsr,pc),(a1)+	; full flush
	lea	(FullFlush,pc),a0
	move.l	a0,(a1)+
	move.w	(Proto\.Nop,pc),(a1)+

	move.l	a4,a1
	add.l	#106*TRK_SIZE+$0252,a1
	lea	(LineFlush\.Flush,pc),a0 ; line flush (set rts)
	move.l	(a0),(a1)+

	move.l	a4,a1
	add.l	#106*TRK_SIZE+$026c,a1
	move.w	(Proto\.Jsr,pc),(a1)+	; line flush (restore)
	lea	(LineFlush,pc),a0
	move.l	a0,(a1)+
.No040

; Patch misc stuff in the end part.
	move.l	a4,a1
	add.l	#118*TRK_SIZE+$0bc6,a1
	move.w	(Proto\.Lea0,pc),(a1)+	; logo
	move.l	a4,a0
	add.l	#115*TRK_SIZE,a0
	move.l	a0,(a1)+
	move.w	(Proto\.Lea2,pc),(a1)+	; bang sample
	move.l	a4,a0
	add.l	#7*TRK_SIZE+$623a,a0
	move.l	a0,(a1)+

	move.l	a4,a1
	add.l	#118*TRK_SIZE+$0c44,a1	; don't need disk motor off
	moveq	#4+1+4+1+4+1+4-1,d0
.PatchMotor	move.w	(Proto\.Nop,pc),(a1)+
	dbf	d0,.PatchMotor

	move.l	a4,a1
	add.l	#118*TRK_SIZE+$0ba6,a1	; interrupt killer
	move.w	(Proto\.Jsr,pc),(a1)+
	lea	(DisableInts,pc),a0
	move.l	a0,(a1)+
	move.w	(Proto\.Nop,pc),(a1)+

; Load tracks 0-1 (bootblock, initial sequence), it's easier to
; entirely bypass the initialization than to patch several things.
	lea	($30000-1024),a1
	move.l	a1,a3			; a3 = bootblock
	move.w	#2*TRK_SIZE/4-1,d0
.CopyTrk01	move.l	(a4)+,(a1)+
	dbf	d0,.CopyTrk01

; Patch bootblock code.
	lea	(Proto\.Int3,pc),a0
	lea	($0120,a3),a1
	move.l	(a0)+,(a1)+
	move.w	(a0)+,(a1)+
	move.w	(Proto\.Jmp,pc),(a1)+
	lea	(1024,a3),a0
	move.l	a0,(a1)+

	movem.l	d0-a6,-(a7)
	lea	PL_BOOT(pc),a0
	lea	$30000,a1
	move.l	WhdBase(pc),a2
	jsr	resload_Patch(a2)

	; Initialise level 2 interrupt for 68000 quitkey support
	bsr	Init_Level2_Interrupt
	movem.l	(a7)+,d0-a6


	

; All done, ready to roll.
	move.l	a4,(a2)			; TrackPtr
	st	(0).w			; init exp. memory

	lea	($bfd100),a5		; needed for LED/filter
	lea	($dff000),a6
	move.w	#$0010,($09c,a6)
	move.w	#$83d0,($096,a6)
	jmp	($00aa,a3)		; into bootblock


;PATCH_PARTS	
PL_BOOT	PL_START
	PL_PS	$670,.Fix_Line_Draw
	IFD	PATCH_PARTS
	PL_PS	$23bc-1024,.Patch_Parts
	ENDC
	PL_END

.Fix_Line_Draw	add.w	d3,d3
	move.w	(a3,d3.w),d3
	and.w	#%01011111,d0		; only keep valid BLTCON1 bits
	rts

	IFD	PATCH_PARTS
.Patch_Parts	bsr	Loader

	movem.l	d0-a6,-(a7)
	lea	.Part_Number(pc),a0
	move.w	(a0),d0
	addq.w	#1*2,(a0)
	move.w	.TAB(pc,d0.w),d0
	jsr	.TAB(pc,d0.w)
	movem.l	(a7)+,d0-a6

	jmp	(a1)

.Part_Number	dc.w	0

.TAB	dc.w	Patch_Credits-.TAB
	dc.w	Patch_Glenz-.TAB
	dc.w	Patch_Scrollers-.TAB
	dc.w	Patch_72_Glenz-.TAB
	dc.w	Patch_Multi_Cube-.TAB
	dc.w	Patch_3d_Dots-.TAB
	dc.w	Patch_Glenz_Light-.TAB
	dc.w	Patch_Cube_Balls-.TAB
	dc.w	Patch_Glenz_Cubes-.TAB
	dc.w	Patch_Sine_Dots-.TAB
	dc.w	Patch_Rubik-.TAB
	dc.w	Patch_96_Light-.TAB
	dc.w	Patch_Starfield-.TAB
	dc.w	Patch_Shade_Bobs-.TAB
	dc.w	Patch_End_Part-.TAB

Patch_Credits	rts

Patch_Glenz	rts

Patch_Scrollers	rts

Patch_72_Glenz	rts

Patch_Multi_Cube
	rts

Patch_3d_Dots	rts

Patch_Glenz_Light
	rts

Patch_Cube_Balls
	rts

Patch_Glenz_Cubes
	rts

Patch_Sine_Dots	rts

Patch_Rubik	rts

Patch_96_Light	rts

Patch_Starfield	rts

Patch_Shade_Bobs
	rts

Patch_End_Part	rts

	ENDC


PL_SINEDOTS	PL_START
	PL_R	$172			; disable write to FMODE
	PL_PS	$1f0,.Wait_Blit
	PL_END

.Wait_Blit	;move.w	#500,(a4)
	;clr.l	-4(a4)
.Wait_TOF	cmp.b	#255,6(a6)
	bne.b	.Wait_TOF

Wait_Blit	tst.b	$dff002
.blitter_is_still_busy
	btst	#6,$dff002
	bne.b	.blitter_is_still_busy
	rts
	


****************************************************************
; Error handling

LoadFailed	pea	(1).w			; diskno
	move.l	d1,-(a7)		; errcode
	pea	(TDREASON_DISKLOAD).w
	jmp	resload_Abort(a5)

WrongVersion	pea	(TDREASON_WRONGVER).w
	jmp	resload_Abort(a5)

****************************************************************
; Misc. injected code

Proto
.Int3	move.w	#$c010,($09a,a6)
.Jmp	jmp	(0)
.Jsr	jsr	(0)
.Nop	nop
.Lea0	lea	(0),a0
.Lea2	lea	(0),a2
.Lea3	lea	(0),a3
.Lea5	lea	(0),a5

****************************************************************
; Load directly from cached disk image.

; d0 = num_trk-1, a0 = addr (neg. if exp. memory), a1 = preserve!
Loader	addq.w	#1,d0			; unadjust for dbf
	mulu.w	#TRK_SIZE,d0		; to bytes
	lea	(TrackPtr,pc),a4
	move.l	(a4),a2
	lea	(a2,d0.l),a3
	move.l	a0,d0
	bmi.b	.ExpMem
.CopyTrks	move.l	(a2)+,(a0)+
	cmp.l	a3,a2
	blo.b	.CopyTrks
.ExpMem	move.l	a3,(a4)
	rts

;****************************************************************
; Keep one empty interrupt to trigger whdload's keyboard checks.

DisableInts	move.w	#$6000,($dff09a)	; int6 ext off (music)
	lea	(.Int3VBL,pc),a0
	move.l	a0,($6c).w
	move.w	#$c000,($dff09a)
	rts

.Int3VBL	move.w	#$0020,($dff09c)	; paranoia mode on
	nop
	move.w	#$0020,($dff09c)
	nop
	rte

****************************************************************

FullFlush	move.l	(WhdBase,pc),a0
	jsr	(resload_FlushCache,a0)

;	move.w	#50*Time,(a4)		; original instr.
	move.w	#50*10,(a4)
;	clr.l	(CurrPos-Ctr,a4)
	clr.l	(-4,a4)
	rts

LineFlush
.Flush	cpushl	dc,(a2)			; 68040+
	cinvl	ic,(a2)

;	tst.w	(Test)			; original instr.
	tst.w	($306bc)
	rts

****************************************************************

QUIT	pea	(TDREASON_OK).w
EXIT	move.l	WhdBase(pc),-(a7)
	addq.l	#resload_Abort,(a7)


KillSys	move.w	#$7fff,$dff09a
	bsr.b	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	rts


WaitRaster
.wait1	btst	#0,_custom+vposr+1
	beq.b	.wait1
.wait2	btst	#0,_custom+vposr+1
	bne.b	.wait2
	rts

; d0.w: number of raster lines to wait
Wait_Raster_Lines
	move.w	d1,-(a7)
.loop	move.b	_custom+vhposr,d1
.still_in_same_raster_line
	cmp.b	_custom+vhposr,d1
	beq.b	.still_in_same_raster_line	
	subq.w	#1,d0
	bne.b	.loop
	move.w	(a7)+,d1
	rts

; d0.b: rawkey code

Check_Quit_Key	cmp.b	Header+ws_keyexit(pc),d0
	beq.w	QUIT
	rts	

; Level 2 interrupt used to handle keyboard events.

Init_Level2_Interrupt
	pea	.int(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode


	move.w	#INTF_PORTS,_custom+intreq	; clear ports interrupt
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,_custom+intena
	rts

.int	movem.l	d0-d1/a0-a2,-(a7)
	lea	_custom,a0
	lea	_ciaa,a1

	btst	#INTB_PORTS,intreqr+1(a0)
	beq.b	.end

	btst	#CIAICRB_SP,ciaicr(a1)
	beq.b	.end

	lea	Key(pc),a2
	moveq	#0,d0
	move.b	ciasdr(a1),d0
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)+
	or.b	#CIACRAF_SPMODE,ciacra(a1)	; set output mode

	bsr.w	Check_Quit_Key

	move.l	(a2)+,d1
	beq.b	.no_keyboard_custom_routine
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.no_keyboard_custom_routine
	
	moveq	#3,d0
	bsr	Wait_Raster_Lines

	and.b	#~CIACRAF_SPMODE,ciacra(a1)	; set input mode
.end	move.w	#INTF_PORTS,intreq(a0)
	move.w	#INTF_PORTS,intreq(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte



Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine

****************************************************************

Disk	DS.B	880*1024
.End

****************************************************************

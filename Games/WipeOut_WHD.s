***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(          WIPE OUT WHDLOAD SLAVE            )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              March 2009                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 18-Apr-2020	- boundary checks added as apparently the 24-bit fix
;		  caused writes above the $80000 area

; 17-Apr-2020	- another 24-bit problem fixed (Mantis issue #4503)

; 29-Mar-2020	- league disk creation fixed
;		- CPU dependent delay loops fixed
;		- tried (once again) to disable the disk requests, no
;		  success and I'm fed up with this game so they'll stay for now
;		- 68000 quitkey support
;		- ButtonWait support for title picture
;		- out of bounds blit fixed
;		- code cleaned up a bit, patch finished for now!


; 28-Mar-2020	- instruction cache disables as there's way too much SMC
;		- save/format support
;		- league disk file (disk.2) will be created if it doesn't exist

; 26-Mar-2020	- league disk support (required fixing the imager)

; 25-Mar-2020	- blitter waits added
;		- 24-bit problems fixed
;		- SMC fixed

; 22-Mar-2009	- disk image created
;		- game works until intro anim, hangs then

; 21-Mar-2009	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
DEBUGKEY	= $58		; F9
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


.config	dc.b	"C1:B:Don't create League Disk;"
	dc.b	"BW"

	IFD	DEBUG
.dir	dc.b	"SOURCES:WHD_Slaves/WipeOut/",0
	ENDC
.name	dc.b	"Wipe Out",0
.copy	dc.b	"1990 Gonzo Games",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	dc.b	"Version 1.01 (18.04.2020)",0
	CNOP	0,2

TAGLIST		dc.l	WHDLTAG_CUSTOM1_GET
NODATADISK	dc.l	0		; disable creation of data disk
		dc.l	WHDLTAG_BUTTONWAIT_GET
BUTTONWAIT	dc.l	0

		dc.l	TAG_END

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

	; create empty league disk file
	move.l	NODATADISK(pc),d0
	bne.b	.skip

	; check if league disk exists
	lea	LeagueDiskName(pc),a0
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	bne.b	.skip

	lea	LeagueDiskName(pc),a0
	lea	$1200.w,a1
	move.l	#(141*$1600)/2,d0
	jsr	resload_SaveFile(a2)

	lea	LeagueDiskName(pc),a0
	lea	$1200.w,a1
	move.l	#(141*$1600)/2,d0
	move.l	d0,d1
	jsr	resload_SaveFileOffset(a2)
.skip

; load bootloader
	move.l	#$5800,d0
	move.l	#$7e00,d1
	moveq	#1,d2
	lea	$1560.w,a5
	move.l	a5,a0
	jsr	resload_DiskLoad(a2)

; version check
	move.l	a5,a0
	move.l	#$7e00,d0
	jsr	resload_CRC16(a2)
	lea	PL_BOOT(pc),a0
	cmp.w	#$1005,d0		; SPS 0161
	beq.b	.ok

; unknown version
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT

.ok


; patch it
	move.l	a5,a1
	jsr	resload_Patch(a2)


	; disable instruction cache as games uses way too much SMC
	moveq	#0,d0
	moveq	#CACRF_EnableI,d1
	jsr	resload_SetCACR(a2)


	


	jmp	(a5)

QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	jmp	resload_Abort(a2)



PL_BOOT	PL_START
	PL_P	$7C4,Loader
	PL_P	$6da,.patch
	PL_END


.patch	movem.l	d0-a6,-(a7)
	lea	PL_40000(pc),a0
	lea	$40000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	jmp	$40000


PL_40000
	PL_START
	PL_P	$804,Loader
	PL_P	$6da,.patch
	PL_PS	$a6c,CheckQuit
	PL_END


.patch	movem.l	d0-a6,-(a7)

	move.l	BUTTONWAIT(pc),d0
	beq.b	.nowait

	move.l	#50*100,d0
	move.l	resload(pc),a0
	jsr	resload_Delay(a0)
.nowait


	lea	PL_800(pc),a0
	lea	$800.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	jmp	$800.w


CheckQuit
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.w	QUIT

	move.b	d0,d1
	and.b	#7,d1
	rts


PL_800
	PL_START
	PL_PS	$2c48,.check		; fix 24-bit problems

	PL_PSS	$a466,.wblit1,2
	PL_PSS	$a1ca,.wblit1,2
	PL_PSS	$a1f8,.wblit1,2

	PL_PS	$ba08,.flush

	PL_PS	$ba20,.Fix24Bit_2


	PL_P	$829e,.LoadBytes
	PL_P	$8192,.SaveBytes


	; fix CPU dependent delay loops
	PL_PSS	$88ca,.FixDelay,2
	PL_PSS	$620a,.FixDelay2,4
	PL_PSS	$6230,.FixDelay3,4


	; set correct disk
	PL_PS	$7884,.PatchDiskIDCheck


	; enable quit on 68000 machines
	PL_PS	$3746,CheckQuit

	; fix out of bounds blit
	PL_PSS	$a476,.FixBlit,2


	; fix mask
	PL_L	$2ade+2,$fffff

	PL_PSA	$2b2e,.fix,$2b3e
	PL_END

.nowrite5
	lea	(a1,d1.l),a2
	illegal

.fix	move.l	a3,-(a7)

.loop1	or.w	(a2),d6
	;cmp.l	#$80000,(a1,d1.l)
	;bhs.b	.nowrite5

	lea	(a1,d1.l),a3
	cmp.l	#$80000,a3
	bhs.b	.nowrite


	move.w	(a2),(a1,d1.l)

.nowrite
	addq.w	#2,a2
	add.l	d3,d1
	dbf	d0,.loop1

	;cmp.l	#$80000,(a1,d1.l)
	;bhs.b	.nowrite2

	lea	(a1,d1.l),a3
	cmp.l	#$80000,a3
	bhs.b	.nowrite2

	move.w	d6,(a1,d1.l)
.nowrite2

	move.l	(a7)+,a3
	rts	



.FixBlit
	move.l	a0,$54(a1)
	cmp.l	#$80000,a3
	bhs.b	.noBlit
	move.w	d4,$58(a1)
.noBlit
	rts



.PatchDiskIDCheck
	move.l	d0,-(a7)
	move.l	4+4(a7),d0		; from where was this routine called?

	lea	.TAB(pc),a0
.search	cmp.l	(a0),d0
	beq.b	.set
	addq.w	#2*4,a0
	tst.l	(a0)
	bne.b	.search

.set	move.l	4(a0),d0
	lea	DiskNum(pc),a0
	move.b	d0,(a0)

	lea	$800+$15494,a0		; original code
	move.l	(a7)+,d0
	rts


.TAB	dc.l	$800+$4548,2
	dc.l	$800+$47f0,2
	dc.l	$800+$73b2,2
	dc.l	$800+$75a0,2
	dc.l	0,1


.FixDelay3
	move.l	#$4000,d0
	bra.b	.FixDelay

.FixDelay2
	move.l	#$8000,d0

.FixDelay
	move.w	d1,-(a7)
	divu.w	#$34,d0
.loop	move.b	$dff006,d1
.wait	cmp.b	$dff006,d1
	beq.b	.wait	
	dbf	d0,.loop
	move.w	(a7)+,d1
	rts



; d0.l: offset (bytes)
; d1.l: size (bytes)
; a0.l: destination

.LoadBytes
	bra.w	Loader

.SaveBytes
	exg	d0,d1			; d0.l: size, d1.l: offset
	move.l	a0,a1
	lea	LeagueDiskName(pc),a0
	move.l	resload(pc),a2
	jmp	resload_SaveFileOffset(a2)





.Fix24Bit_2
	move.l	d1,-(a7)
	move.l	a4,d1
	and.l	#$00ffffff,d1
	move.l	d1,a4
	move.l	(a7)+,d1

	move.l	a3,a5
	move.w	#4,d1
	rts


.flush	moveq	#0,d4
	and.w	#$ff,d2
	move.l	resload(pc),-(a7)
	add.l	#resload_FlushCache,(a7)
	rts


.wblit1	bsr	WaitBlit
	move.w	d7,$44(a1)
	move.w	d6,$46(a1)
	rts


.check	add.l	$800+$16f60,a1

	move.l	d0,-(a7)
	move.l	a1,d0
	and.l	#$00ffffff,d0
	move.l	d0,a1
	move.l	(a7)+,d0
	rts


; d0.l: offset
; d1.l: length
; a0.l: address

Loader	movem.l	d0-a6,-(a7)
	move.b	DiskNum(pc),d2
	move.l	resload(pc),a1
	jsr	resload_DiskLoad(a1)
	movem.l	(a7)+,d0-a6
	rts

DiskNum	dc.b	1
	dc.b	0


WaitBlit
	tst.w	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts


LeagueDiskName	dc.b	"Disk.2",0

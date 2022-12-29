***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       THE BARD'S TALE WHDLOAD SLAVE        )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            December 2013                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 29-Dec-2022	- DMA wait in replayer fixed (issue #5960)

; 26-Dec-2013	- work started
;		- supports SPS 0010 and SPS 1978 versions


	INCDIR	SOURCES:Include/
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	;INCLUDE	lvo/dos.i

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

MC68020	MACRO
	ENDM

;============================================================================

CHIPMEMSIZE	= 524288
FASTMEMSIZE	= 0
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;BOOTBLOCK
BOOTDOS
;BOOTEARLY
;CBDOSLOADSEG
;CBDOSREAD
;CACHE
;DEBUG
;DISKSONBOOT
DOSASSIGN
FONTHEIGHT	= 8
HDINIT
HRTMON
;INITAGA
;INIT_AUDIO
;INIT_GADTOOLS
INIT_LOWLEVEL
;INIT_MATHFFP
IOCACHE		= 1024
;JOYPADEMU
;MEMFREE	= $200
;NEEDFPU
NO68020
POINTERTICKS	= 1
;PROMOTE_DISPLAY
STACKSIZE	= 6000
;TRDCHANGEDISK

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	; F10

;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================


slv_CurrentDir	IFD	DEBUG
		dc.b	"SOURCES:WHD_Slaves/BardsTale/"
		ENDC
		dc.b	"data",0

slv_name	dc.b	"The Bard's Tale: Tales of the Unknown",0
slv_copy	dc.b	"1986 Interplay",0
slv_info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
		IFD	DEBUG
		dc.b	"Debug!!! "
		ENDC
		dc.b	"Version 1.2 (29.12.2022)",0
name		dc.b	"bardstale.dat",0
chardisk_name	dc.b	"bards tale character disk",0
chardisk_dir	dc.b	"members",0

slv_config	dc.b	0
		CNOP	0,4

	IFD BOOTDOS

_bootdos
	lea	_dosname(pc),a1
	move.l	$4.w,a6
	jsr	_LVOOldOpenLibrary(a6)
	move.l	d0,a6

	move.l	_resload(pc),a2
	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

; assign character disk
	lea	chardisk_name(pc),a0
	lea	chardisk_dir(pc),a1
	bsr	_dos_assign

	lea	name(pc),a0
	lea	$20000,a1
	move.l	a1,a5
	jsr	resload_LoadFile(a2)
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	move.l	#$214f8,d6		; length
	cmp.w	#$d938,d0		; SPS 1978, encrypted
	beq.b	.decrypt
	move.l	#$2231c,d6		; length
	cmp.w	#$7d8a,d0		; SPS 0010, encrypted
	bne.b	.nodecrypt	
	lea	.len(pc),a0
	move.l	#222348,(a0)

; decrypt executable and save it
.decrypt
	move.w	d6,-(a7)		; save checksum
	move.l	a5,a0			; encrypted data
	move.l	d6,d0			; length
	movem.l	a2/a6,-(a7)
	bsr	EA_Decrypt
	movem.l	(a7)+,a2/a6
	lea	name(pc),a0
	lea	$20000,a1
	move.l	.len(pc),d0
	jsr	resload_SaveFile(a2)
	move.w	(a7)+,d6		: checksum
	
	move.w	#$e313,d0		; fake checksum for decrypted file
	cmp.w	#$d938,d6		; SPS 1978
	beq.b	.is1978
	move.w	#$44b2,d0		; SPS 0010
.is1978
	

.nodecrypt

	lea	PL1978(pc),a4
	cmp.w	#$e313,d0		; SPS 1978, decrypted
	beq.b	.ok
	lea	PL0010(pc),a4
	cmp.w	#$44b2,d0		; SPS 0010, decrypted
	beq.b	.ok
	cmp.w	#$a4f8,d0
	beq.b	.ok

; unsupported/unknown version
.wrongver
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT



.ok	lea	name(pc),a0
	move.l	a0,d6
	move.l	a0,d1
	jsr	_LVOLoadSeg(a6)
	move.l	d0,d7
	beq.b	.error

	move.l	a4,a0
	move.l	d7,a1
	jsr	resload_PatchSeg(a2)
	
	bsr.b	.run
	bra.b	QUIT

.run	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	movem.l	d7/a6,-(a7)
	lea	.cmd(pc),a0
	moveq	#.cmdlen,d0
	jsr	4(a1)
	movem.l	(a7)+,d7/a6
	move.l	d7,d1
	jmp	_LVOUnLoadSeg(a6)


.error	jsr	_LVOIoErr(a6)
	move.l	d6,-(a7)
	move.l	d0,-(a7)
	pea	(TDREASON_DOSREAD).w
	bra.b	EXIT

.len	dc.l	219456			; SPS 1978

.cmd	dc.b	"",13,0			; fake command line
.cmdlen	= *-.cmd
	CNOP	0,4


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	_resload(pc),a2
	jmp	resload_Abort(a2)


; SPS 1978
PL1978	PL_START
	PL_PS	$1dac2,Fix_DMA_Wait
	PL_END

; SPS 0010
PL0010	PL_START
	PL_PS	$1db52,Fix_DMA_Wait
	PL_END



Fix_DMA_Wait
	moveq	#5-1,d0

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



TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
		dc.l	0
		dc.l	TAG_END








; Electronic Arts decrypter
; deprotects EA's early (1985-87) Amiga games
;
; generic version which handles binary data and executables
; full asm version derived from the ugly disassembled C code
; (key calculation routine anyway, rest has been coded from
; scratch using good old "guess work" approach)
;
; StingRay, 26/27-Jun-2012

; a0.l: data to decrypt
; d0.l: length
; -----
; a0.l: start of decrypted data
; a1.l: end of decrypted data

EA_Decrypt
	move.l	a0,a5
	move.l	d0,d5
	
	lea	KeyBuf(pc),a0
	move.l	a0,a1
	move.l	a1,Key-KeyBuf(a0)
	add.w	#$6c,a1
	move.l	a1,Key6c-KeyBuf(a0)
	lea	$dc(a0),a1
	move.l	a1,KeyDC-KeyBuf(a0)

	move.l	#$56317753,(a0)
	moveq	#1,d6
	moveq	#55-2,d7
.loop	move.l	(a0)+,d0		; previous key
	move.l	d0,d1
	asl.l	#5,d1
	sub.l	d0,d1
	add.l	d6,d1
	addq.l	#1,d6
	move.l	d1,(a0)
	dbf	d7,.loop

	lea	TAB(pc),a0
	lea	KeyBuf(pc),a1
	moveq	#TABSIZE-1,d7
.loop2	move.l	(a0)+,d0
	eor.l	d0,(a1)+
	dbf	d7,.loop2

	lea	KeyBuf+$28(pc),a0
	move.l	#$fc,d0
	moveq	#17-10-1,d7
.loop3	eor.l	d0,(a0)+
	dbf	d7,.loop3

	lea	KeyBuf+$28(pc),a0
	moveq	#15-10-1,d7
.loop4	eor.l	d0,(a0)+
	dbf	d7,.loop4

	lea	KeyBuf+$80(pc),a0
	moveq	#$30-$20-1,d7
.loop5	eor.l	d0,(a0)+
	dbf	d7,.loop5

	lea	KeyBuf+$78(pc),a0
	eor.l	d0,(a0)+
	asr.l	#4,d0
	eor.l	d0,(a0)

	move.l	a5,a0
	lea	(a0,d5.l),a1
	cmp.l	#$03f3,(a0)
	beq.w	DecryptHunks

; binary 
	move.l	a5,a4
	lsr.l	#2,d5
.decrypt
	bsr	GetNewKey
	eor.l	d0,(a5)+
	subq.l	#1,d5
	bne.b	.decrypt

	move.l	a4,a0
	move.l	a5,a1
	


.noexe	rts

Key	dc.l	0
Key6c	dc.l	0
KeyDC	dc.l	0

GetNewKey
	lea	Key(pc),a3
	move.l	(a3),a0
	
	;move.l	Key(pc),a0
	move.l	Key6c(pc),a1
	move.l	KeyDC(pc),d1
	move.l	(a1),d0
	add.l	d0,(a0)+
	cmp.l	d1,a0
	bne.b	.noreset
	sub.w	#55*4,a0
.noreset
	addq.l	#8,a1
	cmp.l	d1,a1
	blo.b	.ok
	sub.w	#55*4,a1
.ok	move.l	a0,(a3)			; Key
	move.l	a1,Key6c-Key(a3)
	move.l	(a0),d0
	rts


; a0.l: start of crypted executable
; a1.l: end of crypted executable

DecryptHunks
	move.l	a0,a5
	move.l	a1,a6

.loop	move.l	(a5)+,d0
	cmp.w	#999,d0
	blt.b	.next
	cmp.w	#1017,d0
	bgt.b	.next
	sub.w	#999,d0
	add.w	d0,d0
	lea	.TAB(pc),a0
	add.w	(a0,d0.w),a0
	jsr	(a0)
	bmi.b	.out
.next	cmp.l	a5,a6
	bcc.b	.loop
		
.out	rts

.TAB	dc.w	HUNK_UNIT-.TAB		;  999/$3e7
	dc.w	HUNK_NAME-.TAB		; 1000/$3e8
	dc.w	HUNK_CODE-.TAB		; 1001/$3e9
	dc.w	HUNK_DATA-.TAB		; 1002/$3ea
	dc.w	HUNK_BSS-.TAB		; 1003/$3eb
	dc.w	HUNK_RELOC32-.TAB	; 1004/$3ec
	dc.w	HUNK_RELOC16-.TAB	; 1005/$3ed
	dc.w	HUNK_RELOC08-.TAB	; 1006/$3ee
	dc.w	HUNK_EXT-.TAB		; 1007
	dc.w	HUNK_SYMBOL-.TAB	; 1008
	dc.w	HUNK_DEBUG-.TAB		; 1009
	dc.w	HUNK_END-.TAB		; 1010
	dc.w	HUNK_HEADER-.TAB	; 1011
	dc.w	0
	dc.w	HUNK_OVERLAY-.TAB	; 1013
	dc.w	HUNK_BREAK-.TAB		; 1014
	dc.w	HUNK_DREL32-.TAB	; 1015
	dc.w	HUNK_DREL16-.TAB	; 1016
	dc.w	HUNK_DREL08-.TAB	; 1017
	
HUNK_BSS
	bsr	GetNewKey
	eor.l	d0,(a5)+
	moveq	#0,d0
	rts

HUNK_CODE
HUNK_DATA
	bsr	GetNewKey
	eor.l	d0,(a5)
	move.l	(a5)+,d7
	bra.b	DO_HUNK

HUNK_RELOC32
.reloc	bsr	GetNewKey
	eor.l	d0,(a5)

	move.l	(a5)+,d7
	beq.b	.done
	bsr	GetNewKey
	eor.l	d0,(a5)+
.loop	bsr	GetNewKey
	eor.l	d0,(a5)+
	subq.l	#1,d7
	bne.b	.loop
	bra.b	.reloc
.done	rts

HUNK_SYMBOL
.loop	bsr	GetNewKey
	eor.l	d0,(a5)
	move.l	(a5)+,d7
	beq.b	.out
	lsl.l	#2,d7
	add.l	d7,a5
	bsr	GetNewKey
	eor.l	d0,(a5)+
	bra.b	.loop
.out	rts


HUNK_BREAK
HUNK_END
	moveq	#0,d0
	rts


HUNK_HEADER
	lea	.flag(pc),a0	; only process hunk header once
	moveq	#-1,d0		; since overlaid executables can
	tst.w	(a0)		; have more than 1 hunk header
	bne.b	.err
	addq.w	#1,(a0)

	bsr	GetNewKey
	eor.l	d0,(a5)+	; no name
	bsr	GetNewKey
	eor.l	d0,(a5)+	; size
	bsr	GetNewKey
	eor.l	d0,(a5)+	; first hunk
	bsr	GetNewKey
	eor.l	d0,(a5)		; last hunk
	move.l	(a5)+,d7
	addq.l	#1,d7
	bsr.b	DO_HUNK
.err	rts

.flag	dc.w	0


HUNK_OVERLAY
	bsr	GetNewKey
	eor.l	d0,(a5)
	move.l	(a5)+,d7
	addq.l	#1,d7
	lsl.l	#2,d7
	add.l	d7,a5	
	rts


HUNK_UNIT
HUNK_NAME
HUNK_RELOC16
HUNK_RELOC08
HUNK_EXT
HUNK_DEBUG
HUNK_DREL32
HUNK_DREL16
HUNK_DREL08
	moveq	#-1,d0
	rts


DO_HUNK	move.l	a5,a4
	move.l	d7,d0
	lsl.l	#2,d0
	add.l	d0,a4
	moveq	#-1,d1
	tst.l	d7
	beq.b	.error
	cmp.l	a4,a6
	bcs.b	.error


.loop	bsr	GetNewKey
	eor.l	d0,(a5)+
	subq.l	#1,d7
	bne.b	.loop
.error	rts


KeyBuf	ds.l	55
TAB	DC.L	$928087A1,$C6FCC522,$03A7FC4B,$30D73FA6
	DC.L	$7913CA21,$26D6092C,$0A36CFB6,$C0623F5E
	DC.L	$702D25ED,$4860033F,$8CAC21D1,$2EC69D1B
	DC.L	$9321E008,$4AB0843D,$7EB20EAE,$6582C492
	DC.L	$2CE3BB22,$ACE0770A,$A45DCADE,$EDBE2596
TABSIZE	= (*-TAB)/4



	ENDC

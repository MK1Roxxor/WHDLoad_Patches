***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(         WINGS OF DEATH MAGER SLAVE         )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            February 2014                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 11-Feb-2014	- sector handling completely rewritten, imager works fine
;		  now!
;		- file saving added

; 10-Feb-2014	- work started
;		- works but needs a lot of retries to read the correct
;		  sectors (checksum errors)


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i




	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Wings of Death imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(11.02.2014)",0
	CNOP	0,4


.disk1	dc.l	.disk2		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_DOUBLEINC	; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	MakeCRCTab	; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

.disk2	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_DOUBLEINC	; Disk flags
	dc.l	.tracks2	; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read


.tracks	TLENTRY 002,158,512*10,SYNC_STD,DecodeTrack
	TLENTRY 003,159,512*10,SYNC_STD,DecodeTrack
	TLEND


.tracks2
	TLENTRY 000,158,512*10,SYNC_STD,DecodeTrack
	TLENTRY 001,159,512*10,SYNC_STD,DecodeTrack
	TLEND


SaveFiles
	move.l	#79*$1400,d5
	move.l	#$1400,d6
	lea	FileTab(pc),a4
	cmp.w	#1,d0
	beq.b	.disk1
	move.l	#80*$1400,d5
	moveq	#0,d6
	lea	FileTab2(pc),a4

.disk1

.loop	move.w	(a4)+,d0		; track
	mulu.w	#10,d0			; # of sectors per track
	add.w	(a4)+,d0
	subq.w	#1,d0
	mulu.w	#512,d0
	move.w	(a4)+,d1		; length (number of sectors)
	mulu.w	#512,d1
	move.w	(a4)+,d2		; side: $505 side0, $404: side 1
	lsr.w	#1,d2
	bcs.b	.side0
	add.l	d5,d0

.side0	sub.l	d6,d0
	lea	.name(pc),a0
	bsr.b	.createname
	jsr	rawdic_SaveDiskFile(a5)

	addq.w	#1,.filenum
	tst.w	(a4)
	bpl.b	.loop

	moveq	#IERR_OK,d0
	rts


; a0.l: file name WOD1_xx/WOD2_xx
; d7.w: file number
.createname
	movem.l	d0-a6,-(a7)
	move.w	.filenum(pc),d0
	bsr.b	.ConvToAscii
	movem.l	(a7)+,d0-a6
	rts
; d0:w value

.ConvToAscii
	addq.w	#4,a0			; skip WOD_

	moveq	#2-1,d3
	lea	.TAB(pc),a1
.loop1	moveq	#-"0",d1
.loop2	sub.w	(a1),d0
	dbcs	d1,.loop2
	neg.b	d1
	move.b	d1,(a0)+
.nope	add.w	(a1)+,d0
	dbf	d3,.loop1
	rts

.TAB	dc.w	10
	dc.w	1

.filenum	dc.w	0

.name	dc.b	"WOD_00",0
	CNOP	0,2


; dc.w track,sector,number of sectors, side

FileTab	DC.W	2	; track
	DC.W	8	; sector
	DC.W	$5E	; number of sectors
	DC.W	$505	; side

	DC.W	12
	DC.W	2
	DC.W	$6F
	DC.W	$505

	DC.W	1
	DC.W	1
	DC.W	$196
	DC.W	$404

	DC.W	$17
	DC.W	3
	DC.W	$E6
	DC.W	$505

	DC.W	1	; 04: neochrome pic
	DC.W	7
	DC.W	11
	DC.W	$505

	DC.W	$2E
	DC.W	3
	DC.W	$3D
	DC.W	$505

	dc.w	1	; boot
	dc.w	2
	dc.w	5
	dc.w	$505

	dc.w	-1	; end of file table


FileTab2
File0
	DC.W	0
	DC.W	3
	DC.W	$60
	DC.W	$505
File1
	DC.W	9
	DC.W	9
	DC.W	$6D
	DC.W	$505
File2
	DC.W	$14
	DC.W	8
	DC.W	$63
	DC.W	$505
File3
	DC.W	$1E
	DC.W	7
	DC.W	$6C
	DC.W	$505
File4
	DC.W	$29
	DC.W	5
	DC.W	$69
	DC.W	$505
File5
	DC.W	$33
	DC.W	10
	DC.W	$72
	DC.W	$505
File6
	DC.W	$3F
	DC.W	4
	DC.W	$72
	DC.W	$505
File8
	DC.W	0
	DC.W	2
	DC.W	1
	DC.W	$505
File9
	DC.W	$4A
	DC.W	8
	DC.W	$1B
	DC.W	$505
File10
	DC.W	$4D
	DC.W	5
	DC.W	$17
	DC.W	$505
File11
	DC.W	1
	DC.W	5
	DC.W	$4E
	DC.W	$404
File12
	DC.W	$13
	DC.W	5
	DC.W	$57
	DC.W	$404
File13
	DC.W	9
	DC.W	3
	DC.W	$66
	DC.W	$404

	dc.w	-1	

; d0.w: track number
; a0.l: ptr to mfm buffer
; a1.l: ptr to destination buffer

DecodeTrack
	lsr.w	#1,d0
	move.w	d0,CurrentTrack
	move.l	a1,LD_Dest
	lea	$3300(a0),a1

	moveq	#10-1,d5		
.loop	bsr.b	DecodeSector
	tst.w	d0
	bne.b	.out
	dbf	d5,.loop
	moveq	#IERR_OK,d0
.out	rts



; a0.l: start of mfm buffer
; a1.l: end of mfm buffer (start+$3300 bytes)

; header format:
; 0: ID.b ($FE: sector header)
; 1: TRACK.b
; 2: 0/unused
; 3: SECTOR.b (1-10)
; 4: index to length table .b (0-3, 128/256/512/1024 bytes per sector)
; 5: checksum.w

; data format:
; 0: ID.b ($FB: data block)
; 1: 512 bytes sector data followed by checksum (1 word)
 


DecodeSector
.find_header
	bsr	GetSync
	tst.w	d0
	bmi.w	.err_sector

	moveq	#11,d1
	bsr	ShiftMFM		; also initialises d6/d7

; decode header
	lea	LD_SectorHeader(pc),a4
	moveq	#7,d1
	bsr	DecodeBytes

	subq.w	#7,a4			; back to start of sector heaser
	cmp.b	#$fe,(a4)		; sector header?
	bne.b	.find_header

	or.b	d6,d7
	bne.b	.err_checksum

	move.w	CurrentTrack(pc),d0
	cmp.b	1(a4),d0
	bne.b	.err_sector

	moveq	#0,d0
	move.b	3(a4),d0		; sector
	subq.b	#1,d0
	cmp.b	#9,d0			; 0-9 only
	bgt.b	.err_sector

	mulu.w	#512,d0
	add.l	LD_Dest(pc),d0
	move.l	d0,a6			; destination


; find start of data block
	bsr	GetSync
	tst.w	d0
	bmi.b	.err_sector

	move.w	#512+7,d1		; data block size + header size
	bsr	ShiftMFM


	lea	DataHeader(pc),a4
	moveq	#1,d1
	bsr	DecodeBytes
	cmp.b	#$FB,-1(a4)		; data block?
	bne.b	.err_sector

	move.w	#512,d1
	move.l	a6,a4
	bsr	DecodeBytes

	lea	DataChecksum(pc),a4
	moveq	#2,d1
	bsr.b	DecodeBytes
	or.b	d6,d7
	bne.b	.err_checksum

	moveq	#IERR_OK,d0
	rts


.err_sector
	moveq	#IERR_NOSECTOR,d0
	rts

.err_checksum
	moveq	#IERR_CHECKSUM,d0
	rts


; a0.l: mfm buffer
; a1.l: end of mfm buffer

GetSync	move.w	#$4489,d1
.loop	move.l	(a0),d0
	moveq	#0,d7
.bitloop
	cmp.w	d1,d0
	beq.b	.sync_found
	lsr.l	#1,d0
	addq.w	#1,d7
	cmp.w	#16,d7
	bne.b	.bitloop
	addq.l	#4,a0
	cmp.l	a1,a0
	blt.b	.loop
	moveq	#-1,d0
	rts

.sync_found
	moveq	#16,d0
	sub.w	d7,d0
	cmp.w	#16,d0
	bne.b	.noword
	addq.l	#2,a0
	moveq	#0,d0
.noword	rts



; d0.w: number of words to shift
; d1.w: offset
; a0.l: mfm buffer

ShiftMFM
	subq.w	#1,d0
	bmi.b	.next
	move.l	a0,a2
	add.w	d1,a2
	add.w	d1,a2
	subq.w	#2,d1
.oloop	move.l	a2,a3
	move.w	d1,d2
	asl.w	-(a3)
.iloop	roxl.w	-(a3)
	dbf	d2,.iloop
	dbf	d0,.oloop
.next

	move.w	#$4489,d0
.getlast
	cmp.w	(a0)+,d0
	beq.b	.getlast
	subq.w	#2,a0
	move.b	#$CD,d6		; eor value 1
	move.b	#$B4,d7		; eor value 2
	rts


; d1.w: number of bytes to decode
; a0.l: mfm data
; a4.l: destination

DecodeBytes
	subq.w	#1,d1
	lea	SectorTab(pc),a2
	lea	CRC16TAB,a3
	move.l	a3,d4
	moveq	#127,d3
	moveq	#0,d0
.loop	moveq	#0,d2
	move.b	(a0)+,d0
	and.w	d3,d0
	move.b	(a2,d0.w),d2
	move.b	(a0)+,d0
	and.w	d3,d0
	lsl.b	#4,d2
	or.b	(a2,d0.w),d2
	move.b	d2,(a4)+
	move.l	d4,a3
	eor.b	d6,d2
	add.w	d2,a3
	move.b	(a3),d6
	eor.b	d7,d6
	move.b	$100(a3),d7
	dbf	d1,.loop
	rts


CurrentTrack	dc.w	0
LD_Dest		dc.l	0


LD_SectorHeader	ds.b	7
DataHeader	ds.b	1
DataChecksum	ds.w	1

SectorTab
	DC.B	$00,$01,$00,$01,$02,$03,$02,$03
	DC.B	$00,$01,$00,$01,$02,$03,$02,$03

	DC.B	$04,$05,$04,$05,$06,$07,$06,$07
	DC.B	$04,$05,$04,$05,$06,$07,$06,$07

	DC.B	$00,$01,$00,$01,$02,$03,$02,$03
	DC.B	$00,$01,$00,$01,$02,$03,$02,$03

	DC.B	$04,$05,$04,$05,$06,$07,$06,$07
	DC.B	$04,$05,$04,$05,$06,$07,$06,$07

	DC.B	$08,$09,$08,$09,$0A,$0B,$0A,$0B
	DC.B	$08,$09,$08,$09,$0A,$0B,$0A,$0B

	DC.B	$0C,$0D,$0C,$0D,$0E,$0F,$0E,$0F
	DC.B	$0C,$0D,$0C,$0D,$0E,$0F,$0E,$0F

	DC.B	$08,$09,$08,$09,$0A,$0B,$0A,$0B
	DC.B	$08,$09,$08,$09,$0A,$0B,$0A,$0B

	DC.B	$0C,$0D,$0C,$0D,$0E,$0F,$0E,$0F
	DC.B	$0C,$0D,$0C,$0D,$0E,$0F,$0E,$0F


MakeCRCTab
	lea	CRC16TAB,a0
	moveq	#0,d7		; current byte
.loop	moveq	#0,d6
	move.b	d7,d6
	lsl.w	#8,d6
	moveq	#8-1,d0		; for each bit
.inner	add.w	d6,d6
	bcc.b	.skip
	eor.w	#$1021,d6
.skip	dbf	d0,.inner

	move.b	d6,256(a0)
	lsr.w	#8,d6
	move.b	d6,(a0)+
	addq.b	#1,d7
	bne.b	.loop
	rts

	SECTION	TAB,BSS

CRC16TAB	ds.b	512


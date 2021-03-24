***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(           NITRO IMAGER SLAVE               )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             March 2021                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 24-Mar-2021	- final version of the imager

; 23-Mar-2021	- work started

; The disk format is quite interesting, track 0 is a hybrid DOS and custom
; track, on the custom part the track length data for each track and info
; which mask to use for this track is stored. On track 2 the high scores
; are saved, from track 3-146 the main data follows.


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Nitro imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(24.03.2021)",0
	CNOP	0,4


.disk1	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_NORESTRICTIONS		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveDisk	; Called after a disk has been read


.tracks	TLENTRY	000,000,$1600,SYNC_STD,DMFM_STD
	TLENTRY	000,000,$14e,$428a,DecodeDiskData
	TLENTRY	002,002,$189c,$4429,DecodeHighscoreTrack
	TLENTRY	003,146,$2000,$4429,DecodeTrack
	TLEND


; ---------------------------------------------------------------------------

; Create and save disk image. Due to the varying track lengths this
; custom routine is needed to create the final disk image.

; d0.w: disk number
; a0.l: disk structure
; a1.l: disk image data
; a5.l: RawDIC base
 

SaveDisk
	lea	rawdic_SaveDiskFile(a5),a3

	moveq	#0,d6		; offset

	; store boot code and high scores at the beginning of
	; the disk image
	move.w	#$400,d6
	move.l	#$1600-$400,d1
	bsr.b	.Save	

	lea	rawdic_AppendDiskFile(a5),a3

	move.w	#$14e+$1600,d6
	move.l	#320,d1
	bsr.b	.Save


	; create main image data
	move.w	#$14e+$1600+$189c,d6
	moveq	#3,d7		; track number
.loop	moveq	#0,d1
	move.w	d7,d1
	add.w	d1,d1
	lea	TrackLenTab(pc),a2
	move.w	(a2,d1.w),d1
	and.w	#$fff,d1
	lsl.w	#2,d1
	bsr.b	.Save


	add.l	#$2000,d6

	addq.w	#1,d7
	cmp.w	#147,d7
	bne.b	.loop

	moveq	#IERR_OK,d0
	rts


; d6.l: offset
; d1.l: length
; a3.l: rawDIC routine

.Save	lea	.DiskName(pc),a0
	move.l	d6,d0
	jmp	(a3)


.DiskName	dc.b	"Disk.1",0
		CNOP	0,2

; ---------------------------------------------------------------------------

DecodeDiskData
	move.l	a1,a3

	move.w	#$14e/2-1,d1
.loop	move.l	(a0)+,d2
	and.l	#$55555555,d2
	move.l	d2,d3
	swap	d3
	add.w	d3,d3
	or.w	d3,d2
	move.w	d2,(a1)+
	dbf	d1,.loop

	lea	2(a3),a1
	move.w	#$14C,d6
	bsr.w	CalcChecksum
	moveq	#IERR_CHECKSUM,d0
	cmp.w	(a3),d2
	bne.b	.error

	; create track length table
	lea	2+2*4(a3),a0		; 2+2*4: checksum, diskname+data
	lea	TrackLenTab(pc),a1
	move.w	#160-1,d7
.loop2	move.w	(a0)+,(a1)+
	dbf	d7,.loop2


	moveq	#IERR_OK,d0
.error	rts

TrackLenTab	ds.w	160

; ---------------------------------------------------------------------------

; d0.w: track number
; a0.l: MFM data
; a1.l: destination

DecodeTrack
	exg	a0,a1			; a0: destination, a1: MFM

	; decode checksum
	move.l	(a1)+,d5
	and.l	#$55555555,d5
	move.w	d5,d1
	swap	d5
	add.w	d5,d5
	or.w	d1,d5


	; get track length and mask value
	move.w	d0,d7
	add.w	d7,d7
	lea	TrackLenTab(pc),a2
	move.w	(a2,d7.w),d7

	move.w	d7,d2
	and.w	#$fff,d7

	move.l	#$AAAAAAAA,d1
	btst	#12,d2
	beq.b	.mask_ok
	move.l	#$55555555,d1
.mask_ok	


	; decode track data
	movem.l	d5/d7,-(sp)
	bsr.b	.Decode
	movem.l	(sp)+,d5/d7
	move.w	d6,d2
	swap	d6
	eor.w	d6,d2
	and.w	#$FFF0,d2

	moveq	#0,d0

	move.w	d7,d0
	cmp.w	d2,d5
	bne.b	.error
	moveq	#IERR_OK,d0
	rts	

.error	moveq	#IERR_CHECKSUM,d0
	rts


.Decode	moveq	#$1F,d2
	moveq	#$1F,d4
	moveq	#0,d3
	moveq	#0,d6
	subq.w	#1,d7
	moveq	#$1F,d5
	move.l	(a1)+,d0
	btst	d4,d0
	beq.b	.lbC000EC2
.lbC000E9A
	add.l	d3,d3
	addq.w	#1,d3
	dbf	d5,.lbC000EB0
	eor.l	d1,d3
	add.l	d3,d6
	move.l	d3,(a0)+
	dbf	d7,.lbC000EAE
	bra.b	.lbC000F10

.lbC000EAE
	moveq	#$1F,d5
.lbC000EB0
	subq.w	#2,d4
	bpl.b	.lbC000EBE
	and.w	d2,d4
	move.l	(a1)+,d0
.lbC000EBE
	btst	d4,d0
	bne.b	.lbC000E9A
.lbC000EC2
	add.l	d3,d3
	dbra	d5,.lbC000ED6
	eor.l	d1,d3
	add.l	d3,d6
	move.l	d3,(a0)+
	dbra	d7,.lbC000ED4
	bra.b	.lbC000F10

.lbC000ED4
	moveq	#$1F,d5
.lbC000ED6
	dbf	d4,.lbC000EE4

	moveq	#$1F,d4
	move.l	(a1)+,d0
.lbC000EE4
	btst	d4,d0
	bne.b	.lbC000E9A
	add.l	d3,d3
	dbra	d5,.lbC000EFC
	eor.l	d1,d3
	add.l	d3,d6
	move.l	d3,(a0)+
	dbf	d7,.lbC000EFA
	bra.b	.lbC000F10

.lbC000EFA
	moveq	#$1F,d5
.lbC000EFC
	subq.w	#3,d4
	bpl.b	.lbC000F0A
	and.w	d2,d4
	move.l	(a1)+,d0
.lbC000F0A
	btst	d4,d0
	bne.b	.lbC000E9A
	beq.b	.lbC000EC2
.lbC000F10
	rts


; ---------------------------------------------------------------------------

; d0.w: track number
; a0.l: ptr to mfm buffer
; a1.l: ptr to destination buffer

DecodeHighscoreTrack
	move.l	a1,a3

	move.l	a1,a2
	move.l	a0,a1

	move.l	#$55555555,d2
	moveq	#1,d3
	move.w	#$189c/4-1,d7
.loop	move.l	(a1)+,d4
	move.l	(a1)+,d1
	and.l	d2,d4
	and.l	d2,d1
	add.l	d4,d4
	or.l	d1,d4
	move.l	d4,(a2)+
	dbf	d7,.loop

	move.l	a3,a1
	move.w	(a1)+,d3
	move.w	#$189A,d6
	bsr.b	CalcChecksum

	moveq	#IERR_CHECKSUM,d0
	cmp.w	d2,d3
	bne.b	.checksum_error
	moveq	#IERR_OK,d0
.checksum_error
	rts


; a1.l: data to check
; d6.w: length (adapted for "dbf")
; ----
; d2.w: checksum

CalcChecksum
	movem.l	d1/d6/a1,-(sp)
	lsr.w	#1,d6
	moveq	#-1,d2
	add.w	d2,d2
	bra.b	.enter

.loop	move.w	(a1)+,d1
	addx.w	d1,d2
.enter	dbf	d6,.loop
	movem.l	(sp)+,d1/d6/a1
	rts


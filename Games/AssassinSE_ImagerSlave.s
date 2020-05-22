***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   ASSASSIN SPECIAL EDITION IMAGER SLAVE    )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                               June 2019                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 17-Jun-2019	- work started
;		- and finished a short while later


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Assassin Special Edition imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(17.06.2019)",0
	CNOP	0,4



.disk1	dc.l	.disk2		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_DISKIMAGE	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	0		; Called after a disk has been read

.disk2	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_DISKIMAGE	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	0		; Called after a disk has been read

.tracks	TLENTRY	000,001,$1600,SYNC_STD,DMFM_STD
	TLENTRY	002,159,$1800,$1448,.DecodePDOS
	TLEND



.DecodePDOS
	move.l	a0,a5
	move.l	#$55555555,d6

	moveq	#12-1,d7		; sectors per track
.loop	cmp.w	#$4891,(a5)+
	bne.b	.error

; decode header
	movem.l	(a5)+,d0/d1
	and.l	d6,d0
	and.l	d6,d1
	add.l	d0,d0
	or.l	d1,d0

	moveq	#0,d1			; key
	bset	#31,d1
	eor.l	d1,d0
	move.l	d0,d3			; checksum
	swap	d0
	lsr.w	#8,d0

	move.l	a5,a0
	bsr.b	CalcChecksum
	cmp.w	d0,d3
	bne.b	.error

	bsr.b	DecodeSector

; calculate offset to next sector in MFM buffer
	add.w	#$40a-10,a5
	move.w	(a5)+,d0
	moveq	#0,d1
	moveq	#8-1,d2
.loop2	;roxl.w	#2,d0
	;roxl.b	#1,d1

	add.w	d0,d0
	addx.w	d0,d0
	
	addx.b	d1,d1
	dbf	d2,.loop2
	add.w	d1,d1
	add.w	d1,a5
	
	dbf	d7,.loop
	moveq	#IERR_OK,d0
	rts

.error	moveq	#IERR_CHECKSUM,d0
	rts


CalcChecksum
	movem.l	d1/d2/a0,-(a7)
	moveq	#0,d0
	move.w	#512*2/4-1,d1
.loop	move.l	(a0)+,d2
	eor.l	d2,d0
	dbf	d1,.loop

	and.l	d6,d0
	move.l	d0,d1
	swap	d1
	add.w	d1,d1
	or.w	d1,d0
	movem.l	(a7)+,d1/d2/a0
	rts



DecodeSector
	moveq	#512/4-1,d0
	lea	512(a0),a3
	moveq	#0,d4			; key
.loop	move.l	(a0)+,d1
	move.l	(a3)+,d2
	and.l	d6,d1
	and.l	d6,d2
	add.l	d1,d1
	or.l	d2,d1
	eor.l	d1,d4
	move.l	d4,(a1)+
	move.l	d1,d4
	dbf	d0,.loop
	rts


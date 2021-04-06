***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(         BEASTLORD IMAGER SLAVE             )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            December 2011                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 04-Dec-2011	- work started
;		- and finished after a few minutes, not very hard to
;		  do imager


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Beastlord imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(04.12.2011)",0
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
	dc.l	.tracks2	; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_DISKIMAGE	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	0		; Called after a disk has been read

.tracks	;TLENTRY	000,000,512*11,SYNC_STD,DMFM_STD
	TLENTRY 002,131,$1858,$4489,.decode1
	TLEND

.tracks2
	TLENTRY 000,107,$1858,$4489,.decode2
	TLEND

.decode2
	move.l	#"BM-2",d6
	bra.b	DecodeTrack

.decode1
	move.l	#"BM-1",d6

; d0.w: track number
; d6.l: disk ID
; a0.l: ptr to mfm buffer
; a1.l: ptr to destination buffer
DecodeTrack
	move.l	#$55555555,d5
	
	bsr.b	.GetLong
	cmp.l	d6,d0
	bne.b	.error
	bsr	.GetLong
	move.l	d0,d4			; checksum
	moveq	#0,d3
	move.w	#$1858/4-1,d7
.loop	bsr.b	.GetLong
	move.l	d0,(a1)+
	eor.l	d0,d3
	dbf	d7,.loop
	moveq	#IERR_CHECKSUM,d0
	cmp.l	d3,d4
	bne.b	.exit			; checksum error
	moveq	#IERR_OK,d0
.exit	rts

.error	moveq	#IERR_NOSECTOR,d0
	rts


.GetLong
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	and.l	d5,d0
	and.l	d5,d1
	add.l	d0,d0
	or.l	d1,d0
	rts

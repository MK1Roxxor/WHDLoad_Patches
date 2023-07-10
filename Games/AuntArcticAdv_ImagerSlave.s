***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    AUNT ARCTIC ADVENTURE IMAGER SLAVE      )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            October 2017                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 10-Jul-2023	- support for TopShots version added

; 30-Oct-2017	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1_TopShots	; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Aunt Arctic Adventure imager V1.1",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(10.07.2023)",0
	CNOP	0,4



.disk1	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_DISKIMAGE	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	0		; Called after a disk has been read

.disk1_TopShots
	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks_TopShots; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_DISKIMAGE	; List of files to be saved
	dc.l	.CRC		; Table of certain tracks with CRC values
	dc.l	.disk1		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	0		; Called after a disk has been read


.CRC	CRCENTRY	000,$241B
	CRCEND

.tracks	TLENTRY	002,003,$1770,$a425,DecodeTrack
	TLENTRY	004,013,$1770,$a425,DMFM_NULL
	TLENTRY	014,073,$1770,$a425,DecodeTrack
	TLENTRY	074,079,$1770,$a425,DMFM_NULL
	TLENTRY	080,117,$1770,$a425,DecodeTrack
	TLENTRY	118,119,$1770,$a425,DMFM_NULL
	TLENTRY	120,159,$1770,$a425,DecodeTrack
	TLEND

.tracks_TopShots
	TLENTRY	000,159,$1600,SYNC_STD,DMFM_STD
	TLEND


; d0.w: track number
; a0.l: ptr to mfm buffer
; a1.l: ptr to destination buffer

DecodeTrack
	exg	a0,a1

	moveq	#64,d0
.find	cmp.w	#$5554,(a1)+
	dbeq	d0,.find
	
	cmp.w	#$5554,(a1)+
	bne.b	.error
	cmp.l	#$aaa4a929,(a1)
	bne.b	.error
	cmp.l	#$544a4a4a,4(a1)
	bne.b	.error

	move.l	#$AAAAAAAA,d2
	move.l	#$55555555,d3
	moveq	#1,d4

; decode track length
	move.l	8(a1),d0
	move.l	12(a1),d1
	asl.l	d4,d0
	and.l	d2,d0
	and.l	d3,d1
	or.l	d1,d0
	cmp.l	#$1770,d0
	bne.b	.error

; decode track data
	move.l	a1,a2
	lea	$18(a1),a1
	move.l	d6,a4
	move.w	#$1770,d6
	move.w	d6,d5
	lsr.w	#2,d6
	subq.w	#1,d6
	moveq	#0,d7		; checksum
.loop	move.l	(a1,d5.w),d1
	move.l	(a1)+,d0
	asl.l	d4,d0
	and.l	d2,d0
	and.l	d3,d1
	or.l	d1,d0
	eor.l	d0,d7
	move.l	d0,(a0)+
	dbf	d6,.loop

; decode track checksum
	lea	$10(a2),a2
	move.l	(a2)+,d0
	move.l	(a2),d1
	asl.l	d4,d0
	and.l	d2,d0
	and.l	d3,d1
	or.l	d0,d1
	move.l	a4,d6
	cmp.l	d1,d7
	bne.b	.checksum
	
	moveq	#IERR_OK,d0
	rts

.error	moveq	#IERR_NOSECTOR,d0
	rts

.checksum
	moveq	#IERR_CHECKSUM,d0
	rts

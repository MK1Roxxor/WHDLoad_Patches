***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(     EUROPEAN CHAMPIONSHIP IMAGER SLAV      )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            November 2011                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 13-Apr-2023	- support for another version added

; 03-Feb-2014	- updated to support the 1 disk "Sports Masters"
;		  compilation version

; 28-Nov-2011	- work started
;		- and finished without even coding a single line
;		  since I just used my Robozone imager that I coded
;		  back in May 2010, European Championship uses the
;		  same disk format :)
;		- ok, coded a file saver now :)


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i




	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"European Championship imager V1.2",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(13.04.2023)",0
	CNOP	0,4


.disk1	dc.l	.disk2		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	.crc		; Table of certain tracks with CRC values
	dc.l	.disk1_alt	; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

.disk1_alt
	dc.l	.disk2		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	.crc_alt	; Table of certain tracks with CRC values
	dc.l	.disk2		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read


.disk2	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks2	; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	.disk2file	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	0		; Called after a disk has been read

.tracks	TLENTRY	000,000,512*11,SYNC_STD,DMFM_STD
	TLENTRY 001,159,512*12,SYNC_STD,DecodeTrack
	TLEND

.crc	CRCENTRY 0,$846d
	CRCEND

.crc_alt
	CRCENTRY 0,$60d3
	CRCEND

; disk 2 is DOS (track1: copylock)
.tracks2
	TLENTRY	000,000,512*11,SYNC_STD,DMFM_STD
	TLENTRY	001,001,512*11,SYNC_STD,DMFM_NULL
	TLENTRY 002,159,512*11,SYNC_STD,DMFM_STD
	TLEND

.disk2file
	FLENTRY	.name,0,901120
	FLEND

.name	dc.b	"disk.2",0
	CNOP	0,2


; d0.w: track number
; a0.l: ptr to mfm buffer
; a1.l: ptr to destination buffer

DecodeTrack
	moveq	#12-1,d1
.decode	addq.w	#4,a0
	moveq	#512/4-1,d3
	move.l	#$55555555,d4
	moveq	#0,d5
.loop	move.l	(a0)+,d6
	move.l	(a0)+,d7
	and.l	d4,d6
	and.l	d4,d7
	add.l	d6,d6
	or.l	d7,d6
	move.l	d6,(a1)+
	eor.w	d6,d5
	dbf	d3,.loop
	movem.w	(a0),d6/d7
	and.w	d4,d6
	and.w	d4,d7
	add.w	d6,d6
	or.w	d7,d6
	eor.w	d6,d5
	bne.b	.error

	dbf	d1,.decode
	moveq	#IERR_OK,d0
	rts

.error	moveq	#IERR_CHECKSUM,d0
	rts


SaveFiles
	moveq	#1,d0
	jsr	rawdic_ReadTrack(a5)	; read directory
	lea	DIR,a3
	moveq	#512/4-1,d7
.copy	move.l	(a1)+,(a3)+
	dbf	d7,.copy
	
; format:
; dc.b track, dc.b sector, dc.w # of sectors to load-1
; dc.l length in bytes 
	lea	DIR,a4
	moveq	#15-1,d7
	moveq	#0,d6
.loop	moveq	#0,d0
	moveq	#0,d1
	move.b	(a4)+,d0
	subq.b	#1,d0			; image starts at track 1
	mulu.w	#512*12,d0
	add.l	#512*11,d0		; skip bootblock
	move.b	(a4)+,d1
	mulu.w	#512,d1
	add.l	d1,d0			; offset
	addq.w	#2,a4
	move.l	(a4)+,d1		; length
	lea	.name(pc),a0
	move.b	.TAB(pc,d6.w),(a0)
	jsr	rawdic_SaveDiskFile(a5)
	addq.w	#1,d6
	dbf	d7,.loop
	rts

.TAB	dc.b	"0123456789ABCDEF"

.name	dc.b	"0",0

	SECTION	BSS,BSS
DIR	ds.b	512


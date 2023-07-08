***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      BATMAN THE MOVIE IMAGER SLAVE         )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            January 2015                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 18-Jul-2016	- fixed length bug, MSB of size was cleared due to
;		  null-termination of file name which caused files
;		  larger than 64k to be saved incorrectly (too short)
;		- version bumped to 1.1

; 17-Jul-2016	- support for one disk versions (SPS 0019/SPS 1730) added

; 13-Jan-2015	- work started
;		- saves all files and removes spaces at the end of
;		  the file name so unpacking on Windows machines works


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Batman the Movie imager V1.1",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(18.07.2016)",0
	CNOP	0,4

.disk1	dc.l	.disk2		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES
	dc.l	.CRC		; Table of certain tracks with CRC values
	dc.l	.disk1_SPS0019	; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

.disk2	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

; SPS 0019
.disk1_SPS0019
	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES
	dc.l	.CRC2		; Table of certain tracks with CRC values
	dc.l	.disk1_SPS1730	; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

; SPS 1730
.disk1_SPS1730
	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks2	; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES
	dc.l	.CRC3		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

.tracks	TLENTRY 000,000,$1600,SYNC_STD,DMFM_STD
	TLENTRY 001,001,$1600,SYNC_STD,DMFM_NULL
	TLENTRY 002,159,$1600,SYNC_STD,DMFM_STD
	TLEND

.tracks2
	TLENTRY 000,159,$1600,SYNC_STD,DMFM_STD
	TLEND

.CRC	CRCENTRY 0,$bae6
	CRCEND

; SPS 0019, one disk, copylock track
.CRC2	CRCENTRY 2,$f28a
	CRCEND

; SPS 1730, one disk, no copylock track
.CRC3	CRCENTRY 2,$9096
	CRCEND

SaveFiles
	moveq	#0,d0
	jsr	rawdic_ReadTrack(a5)
	add.w	#$400+16,a1

.loop	tst.b	(a1)
	beq.b	.done

	move.l	a1,a0			; name

	move.l	10(a0),d1		; size
	and.l	#$ffffff,d1
	move.w	14(a0),d0		; start offset
	mulu.w	#512,d0


; remove spaces at end of file name
	moveq	#11-1,d7
	lea	11(a0),a2
.search	cmp.b	#" ",-(a2)
	dbne	d7,.search

.ok	sf	1(a2)			; null terminate


	jsr	rawdic_SaveDiskFile(a5)


	add.w	#4*4,a1			; next entry
	bra.b	.loop

.done	moveq	#IERR_OK,d0
	rts
	



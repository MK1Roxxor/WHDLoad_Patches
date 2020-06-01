***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*( KREST MASS LEFTOVERS/ANARCHY IMAGER SLAVE  )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             October 2014                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 05-Oct-2014	- work started
;		- and finished, saves all files


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Krest Mass Leftovers imager V1.1",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(05.10.2014)",0
	CNOP	0,4

.disk1	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

.tracks	TLENTRY 000,159,$1600,SYNC_STD,DMFM_STD
	TLEND



SaveFiles
	moveq	#0,d0
	jsr	rawdic_ReadTrack(a5)
	lea	$420(a1),a4	; start of file table
	lea	$4c2(a1),a6	; start of file names

.loop	move.l	a6,a0
	movem.w	(a4)+,d0/d1
	mulu.w	#512*11,d0
	mulu.w	#512*11,d1
	jsr	rawdic_SaveDiskFile(a5)

	add.w	#20,a6		; next file name
	tst.b	(a6)
	bne.b	.loop

	moveq	#IERR_OK,d0
	rts


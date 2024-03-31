***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        TURBO OUTRUN IMAGER SLAVE           )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             February 2015                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 25-Feb-2014	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Turbo Outrun imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(25.02.2015)",0
	CNOP	0,4

.disk1	dc.l	.disk2		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_DOUBLEINC|DFLG_RAWREADONLY		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_DISKIMAGE
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	0		; Called after a disk has been read


.disk2	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_DOUBLEINC|DFLG_RAWREADONLY		; Disk flags
	dc.l	.tracks2	; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_DISKIMAGE
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	0		; Called after a disk has been read

.tracks	TLENTRY 000,000,$1600,SYNC_STD,DMFM_STD

	TLENTRY 002,016,$1600,$4891,DMFM_STD
	TLENTRY 018,018,$1600,$4891,DMFM_NULL
	TLENTRY 020,094,$1600,$4891,DMFM_STD
	TLEND

.tracks2
	TLENTRY 000,158,$1600,$4891,DMFM_STD
	TLENTRY 001,101,$1600,$4891,DMFM_STD
	TLEND

***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(          HAWKEYE IMAGER SLAVE              )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             January 2022                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 05-Feb-2022	- source cleaned up a bit

; 01-Feb-2022	- slight change in track list

; 31-Jan-2022	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


FLAGS	= DFLG_RAWREADONLY|DFLG_DOUBLEINC|DFLG_SWAPSIDES

	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Hawkeye imager V1.1",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(05.02.2022)",0
	CNOP	0,4

.disk1	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	FLAGS		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	0
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	0		; Called after a disk has been read


.tracks	TLENTRY 000,070,$1600,SYNC_STD,DMFM_STD
	TLENTRY 072,080,$1600,SYNC_STD,DMFM_NULL
	TLENTRY 082,158,$1600,SYNC_STD,DMFM_STD
	TLENTRY 001,153,$1600,SYNC_STD,DMFM_STD
	TLEND





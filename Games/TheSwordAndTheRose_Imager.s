***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(  THE SWORD AND THE ROSE IMAGER SLAVE       )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              August 2023                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 31-Aug-2023	- work started

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i




	SLAVE_HEADER
	dc.b	5		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"The Sword and the Rose imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(31.08.2023)",0
	CNOP	0,4


.disk1	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read


.tracks	TLENTRY	000,000,512*11,SYNC_STD,DMFM_STD
	TLENTRY	001,001,512*11,SYNC_STD,DMFM_NULL
	TLENTRY	002,089,512*11,SYNC_STD,DMFM_STD
	TLEND
	



; d0.w: disk number
; a1.l: disk image data

SaveFiles
	lea	File_Name(pc),a0
	add.l	#$96*512,a1
	move.l	#$336*512,d0
	jsr	rawdic_SaveFile(a5)	
	moveq	#IERR_OK,d0
	rts

File_Name	dc.b	"Sword",0




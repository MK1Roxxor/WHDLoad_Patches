***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       Light Corridor  IMAGER SLAVE         )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              June 2023                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 17-Jun-2023	- title corrected

; 11-Jun-2023	- check for end of file table was incorrect, not all
;		  files were saved

; 07-Jun-2023	- work started

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i




	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"The Light Corridor imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(17.06.2023)",0
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
	dc.l	Save_Files	; Called after a disk has been read

.tracks	TLENTRY	000,001,512*11,SYNC_STD,DMFM_STD
	TLENTRY	002,003,512*11,SYNC_STD,DMFM_NULL
	TLENTRY	004,159,512*11,SYNC_STD,DMFM_STD
	TLEND
	

Save_Files
	moveq	#0,d0
	jsr	rawdic_ReadTrack(a5)
	lea	$400(a1),a4

	moveq	#$400/FE_SIZEOF-1,d7
.save_all_files
	move.l	a4,a0
	tst.b	(a0)
	beq.b	.not_a_valid_file
	move.l	FE_OFFSET(a4),d0
	move.l	FE_LENGTH(a4),d1
	jsr	rawdic_SaveDiskFile(a5)

.not_a_valid_file
	add.w	#FE_SIZEOF,a4
	dbf	d7,.save_all_files

	moveq	#IERR_OK,d0
	rts

	RSRESET
FE_NAME		rs.b	12
FE_OFFSET	rs.l	1
FE_LENGTH	rs.l	1
FE_SIZEOF	rs.b	0

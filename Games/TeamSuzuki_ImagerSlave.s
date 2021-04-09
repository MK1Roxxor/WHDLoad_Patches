***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        TEAM SUZUKI IMAGER SLAVE            )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              March 2020                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 09-Apr-2021	- and removed the directory saving as the adapted patch
;		  code works without it :)
;		- the code for saving the directory has not been removed
;		  though, it can be enabled with the "SAVE_DIRECTORY"
;		  define

; 07-Apr-2021	- updated to save directory data as it's needed for
;		  the patch

; 07-Mar-2020	- work started, adapted from my Celica GT imager


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Team Suzuki imager V1.1",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(09.04.2021)",0
	CNOP	0,4

.disk1	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_SWAPSIDES	; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

.tracks	TLENTRY 002,98,$1800,SYNC_STD,DecodeTrack
	TLEND


DecodeTrack
	move.w	#$1800/2-1,d7
	move.w	#$5555,d2
	move.w	#0,d3			; checksum for this track
	exg	a0,a1
.find_start
	move.w	(a1)+,d0
	cmp.w	#$5555,d0
	bne.b	.find_start

.decode	move.w	(a1)+,d0
	move.w	(a1)+,d1
	and.w	d2,d0
	and.w	d2,d1
	add.w	d1,d1
	or.w	d1,d0
	add.w	d0,d3
	move.w	d0,(a0)+
	dbf	d7,.decode

	move.w	(a1)+,d0
	move.w	(a1)+,d1
	and.w	d2,d0
	and.w	d2,d1
	add.w	d1,d1
	add.w	d0,d1			; d1: checksum (wanted)

	cmp.w	d3,d1
	bne.b	.bad_crc
	moveq	#IERR_OK,d0
	rts

.bad_crc
	moveq	#IERR_CHECKSUM,d0
	rts


SaveFiles
	moveq	#2,d0			; read directory
	jsr	rawdic_ReadTrack(a5)
	move.l	a1,a4			; save ptr to directory

	IFD	SAVE_DIRECTORY	
	; save directory file
	lea	.DirectoryName(pc),a0
	move.l	#$900,d0
	jsr	rawdic_SaveFile(a5)
	ENDC

.save	move.l	a4,a0


	move.b	$1f(a4),d0
	ext.w	d0
	move.l	$1a(a4),d1


	subq.w	#2,d0
	mulu.w	#$1800,d0

	move.l	a0,a2
.find_end
	cmp.b	#" ",(a2)+
	bne.b	.find_end
	clr.b	-1(a2)			; null-terminate file name

	jsr	rawdic_SaveDiskFile(a5)

	add.w	#8*4,a4			; next entry
	tst.l	(a4)
	bne.b	.save


	moveq	#IERR_OK,d0
	rts


	IFD	SAVE_DIRECTORY	
.DirectoryName	dc.b	"Game.dir",0
	ENDC

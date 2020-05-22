***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(     WIPE OUT LEAGUE DISK IMAGER SLAVE      )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                         March 2009/2011/2020                            *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 29-Mar-2020	- final version of the imager, saves file as "Disk.2"

; 05-Mar-2011	- changed handling of the unused/dos tracks
;		  fixes the "game hangs in intro anim" bug

; 21-Mar-2009	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i




	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Wipe Out League disk imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(29.03.2020)",0
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
	dc.l	SaveDisk	; Called after a disk has been read


; disk format:
; 000-140: gonzo dos, sync $4489, $1600 bytes

; checksum is at the end of the track

.tracks	TLENTRY	000,140,512*11,SYNC_STD,DecodeTrack
	TLEND



; d0.w: track number
; a0.l: ptr to mfm buffer
; a1.l: ptr to destination buffer

DecodeTrack
	move.l	a1,a3
	addq.w	#4,a0
	lea	$1610(a0),a2	
	move.l	#$55555555,d6
	move.w	#$1608/4-1,d7
.loop	move.l	(a0)+,d0
	move.l	(a2)+,d1
	and.l	d6,d0
	and.l	d6,d1
	add.l	d0,d0
	or.l	d1,d0
	move.l	d0,(a1)+
	dbf	d7,.loop

	moveq	#0,d0
	moveq	#0,d1
	move.w	#$1602/2-1,d7
.loop2	move.w	(a3)+,d0
	add.l	d0,d1
	dbf	d7,.loop2
	sub.l	(a3),d1
	bne.b	.err
.ok	moveq	#IERR_OK,d0
	rts

.err	moveq	#IERR_CHECKSUM,d0
	rts



SaveDisk
	lea	.Name(pc),a0
	moveq	#0,d0
	move.l	#141*$1600,d1
	jsr	rawdic_SaveDiskFile(a5)
	moveq	#IERR_OK,d0
	rts

.Name	dc.b	"Disk.2",0

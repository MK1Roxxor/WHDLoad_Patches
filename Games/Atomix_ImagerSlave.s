***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(          ATOMIX IMAGER SLAVE               )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              August 2018                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 13-Aug-2018	- work started
;		- and finished a short while later


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Atomix imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(13.08.2018)",0
	CNOP	0,4



.disk1	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_NORESTRICTIONS		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_DISKIMAGE	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	0		; Called after a disk has been read

.tracks	TLENTRY	001,001,$1600,SYNC_STD,DMFM_STD
	TLENTRY	001,001,$189c-$1600,SYNC_STD,DMFM_NULL
	TLENTRY	002,123,$189c,SYNC_STD,DecodeTrack
	TLEND



; d0.w: track number
; a0.l: ptr to mfm buffer
; a1.l: ptr to destination buffer

DecodeTrack
	cmp.l	#$aaaaaaaa,(a0)
	beq.b	.ok
	cmp.l	#$2aaaaaaa,(a0)
	bne.b	.error

.ok	addq.w	#4,a0

	move.w	#$189c/4-1,d7
.loop	move.l	(a0)+,d0
	move.l	(a0)+,d1
	add.l	d0,d0
	and.l	#$aaaaaaaa,d0
	and.l	#$55555555,d1
	or.l	d0,d1
	move.l	d1,(a1)+
	dbf	d7,.loop	

	moveq	#IERR_OK,d0
	rts


.error	move	#IERR_CHECKSUM,d0
	rts




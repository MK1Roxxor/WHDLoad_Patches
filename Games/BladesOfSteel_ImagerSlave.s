***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       BLADES OF STEEL IMAGER SLAVE         )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              April 2013                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 14-Apr-2013	- work started, adapted from my Double Dribble imager


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Blades of Steel imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(14.04.2013)",0
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
	lea	.DIR(pc),a0
	move.l	a0,a4
	add.w	#$400,a1
	move.w	#$400/4-1,d7
.copy	move.l	(a1)+,(a0)+
	dbf	d7,.copy

.loop	move.l	(a4)+,d0	; name
	beq.b	.done
	lea	.name(pc),a0
	move.l	d0,(a0)
	moveq	#0,d0
	moveq	#0,d1
	move.b	(a4)+,d0	; track
	move.b	(a4)+,d1	; sector
	mulu.w	#512*11,d0
	mulu.w	#512,d1
	add.l	d1,d0		; d0: offset
	move.l	(a4)+,d1	; size
	jsr	rawdic_SaveDiskFile(a5)
	bra.b	.loop

.done	move.l	#2*$1600+12,d0
	move.l	#$13884,d1
	lea	.name(pc),a0
	move.l	#"CODE",(a0)
	jsr	rawdic_SaveDiskFile(a5)


	moveq	#IERR_OK,d0
	rts

.name	dc.l	0
	dc.b	0
.DIR	ds.b	$400

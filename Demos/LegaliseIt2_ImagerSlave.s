***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    LEGALISE IT 2/ANARCHY IMAGER SLAVE      )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             January 2019                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 21-Jan-2019	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Legalise It 2 imager V1.1",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(21.01.2019)",0
	CNOP	0,4

.disk1	dc.l	.disk2		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
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



.tracks	TLENTRY	000,159,$1600,SYNC_STD,DMFM_STD
	TLEND


SaveFiles
	lea	rawdic_SaveDiskFile(a5),a6
	subq.w	#1,d0
	bne.b	.noSpecial
	move.l	#$c0800,d0
	move.l	#$2000,d1
	lea	.main(pc),a0
	jsr	(a6)

	move.l	#$ce400,d0
	move.l	#$c088,d1
	lea	.hidden1(pc),a0
	jsr	(a6)
	
	move.l	#$b5800,d0
	move.l	#$84e8,d1
	lea	.hidden2(pc),a0
	jsr	(a6)
.noSpecial

	moveq	#0,d0
	jsr	rawdic_ReadTrack(a5)
	lea	$400+$20(a1),a4	; start of file data
	lea	$4c2(a1),a3	; start of file names

.loop	movem.w	(a4)+,d0/d1
	mulu.w	#512*11,d0
	mulu.w	#512*11,d1
	move.l	a3,a0
	jsr	(a6)

	add.w	#5*4,a3

	tst.w	(a4)
	bpl.b	.loop

	moveq	#IERR_OK,d0
	rts
	
.hidden1	dc.b	"Hidden1",0
.hidden2	dc.b	"Hidden2",0
.main		dc.b	"LegalizeIt2",0

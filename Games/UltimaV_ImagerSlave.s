***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(         ULTIMA V IMAGER SLAVE              )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              April 2018                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 12-Apr-2018	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	5		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Ultima V imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(12.04.2018)",0
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

.tracks	TLENTRY 001,159,$1600,$8915,Decode
	TLEND


Decode	moveq	#1-1,d7		; decode checksum
	bsr.b	.Decode
	subq.w	#1*4,a1		; back to start of destination
	move.l	(a1),d5		; checksum (wanted)

	move.w	#$1600/4-1,d7
	bsr.b	.Decode

	moveq	#IERR_CHECKSUM,d0
	cmp.l	d5,d6
	bne.b	.error
	moveq	#IERR_OK,d0

.error	rts


; a0.l: MFM
; a1.l: destination
; d7.w: number of longs to decode -1 (dbf)
; -----
; d6.l: checksum

.Decode	moveq	#0,d6		; checksum
.loop	move.l	(a0)+,d0
	move.l	(a0)+,d1
	and.l	#$55555555,d0
	and.l	#$55555555,d1
	add.l	d0,d0
	or.l	d1,d0
	move.l	d0,(a1)+
	add.l	d0,d6
	dbf	d7,.loop
	rts




; track 1, sector 1: directory
; 32 bytes per eentry
; 4 longs (16 bytes) for file name
; 1 long (file size)
; 1 word (track)
; 1 word (sector in track OR number of bytes-1 in last sector)
 

; a1.l: ptr to disk image
; a5.l: RawDIC base

SaveFiles
	move.l	a1,a4			; a4: disk image
	lea	512(a1),a3		; a3: directory

.loop	move.l	a3,a2			; current directory entry
	lea	.name(pc),a0
.copyname
	move.b	(a2)+,(a0)+
	bne.b	.copyname

	lea	rawdic_SaveFile(a5),a6	; first run: create file
	movem.w	4*4+4(a3),d0/d1		; track/sector in track
.storefile
	subq.w	#1,d0			; disk image starts at track 1
	mulu.w	#512*11,d0
	mulu.w	#512,d1
	add.l	d1,d0
	lea	(a4,d0.l),a1		; a1: start of file
	move.w	(a1)+,d0		; next track
	move.w	(a1)+,d1		; sector in track/remaining bytes (last sector)


	movem.w	d0/d1,-(a7)

	move.w	#512-4,d2		; sector size
	tst.w	d0			; last sector in file?
	bpl.b	.full
	move.w	d1,d2			; yes, store remaining bytes
	addq.w	#1,d2			; because of dbf in original loader
.full	lea	.name(pc),a0
	move.l	d2,d0			; size
	jsr	(a6)			; SaveFile or AppendFile

	lea	rawdic_AppendFile(a5),a6; all following runs: append file

	movem.w	(a7)+,d0/d1

	tst.w	d0
	bpl.b	.storefile

	add.w	#32,a3			; next entry in directory
	tst.b	(a3)
	bne.b	.loop

	moveq	#IERR_OK,d0
	rts



.name	ds.b	20+1
	CNOP	0,2




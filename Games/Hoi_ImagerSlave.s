***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(             HOI IMAGER SLAVE               )*)---.---.   *
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

; 24-Dec-2022	- disabled saving of disk images

; 22-Aug-2018	- file saving added

; 21-Aug-2018	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	5		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Hoi imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(24.12.2022)",0
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

.tracks	TLENTRY 001,159,$1810,$2291,Decode
	TLEND


; a1.l: ptr to disk image
; a5.l: RawDIC base

SaveFiles
	move.l	a1,a6

	move.l	a1,a4
	add.l	#(78-1)*$1810+256,a4	; start of file entries

.save_all
	moveq	#rawdic_SaveFile,d7
	lea	32(a4),a3
	moveq	#0,d0
	move.b	(a3),d0			; track
.loop	tst.b	d0
	beq.b	.no
	subq.b	#1,d0
.no	mulu.w	#$1810,d0

	move.l	a4,a0			; file name
	lea	(a6,d0.l),a1
	move.l	(a1)+,d6

	swap	d6
	moveq	#0,d0
	move.b	d6,d0
	cmp.b	#-1,d6
	bne.b	.normal

	move.w	12(a3),d0	
	bra.b	.go


.normal
	move.l	#$1810-4,d0

.go	jsr	(a5,d7.l)
	moveq	#rawdic_AppendFile,d7



	moveq	#0,d0
	move.b	d6,d0
	cmp.b	#-1,d6
	bne.b	.loop


.end	add.w	#64,a4			; next file entry
	tst.b	(a4)
	bne.b	.save_all

	moveq	#IERR_OK,d0
	rts


Decode	move.l	#$55555555,d6
	move.w	#$1810/4-1,d7
.loop	move.l	(a0)+,d0
	move.l	$1810-4(a0),d1
	and.l	d6,d0
	and.l	d6,d1

	add.l	d0,d0
	or.l	d1,d0

	move.l	d0,(a1)+

	dbf	d7,.loop

	moveq	#IERR_OK,d0
	rts


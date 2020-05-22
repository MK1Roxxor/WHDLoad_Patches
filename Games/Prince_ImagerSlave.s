***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(          PRINCE IMAGER SLAVE               )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            February 2014                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 05-Feb-2014	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i




	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Prince imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(05.02.2014)",0
	CNOP	0,4


.disk1	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_DOUBLEINC	; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

.tracks	TLENTRY 001*2,014*2,512*10,SYNC_STD,.decode1400
	TLENTRY	015*2,059*2,512*12,SYNC_STD,.decode1800

; side 2 
	TLENTRY	4*2+1,70*2+1,512*12,SYNC_STD,.decode1800
	TLEND


.decode1800
	move.w	#$1800,d5
	bra.b	DecodeTrack

.decode1400
	move.w	#$1400,d5


; d0.w: track number
; d5.w: track length
; a0.l: ptr to mfm buffer
; a1.l: ptr to destination buffer

DecodeTrack
	move.w	d0,d7

	move.l	#$55555555,d6
	movem.l	(a0)+,d0/d1
	and.l	d6,d0
	and.l	d6,d1
	add.l	d0,d0
	or.l	d1,d0
	add.w	d0,d0
	cmp.b	d0,d7
	;bne.b	.sector_error

	move.w	d5,d7
	lsr.w	#2,d7
.loop	move.l	(a0,d5.w),d1
	move.l	(a0)+,d0
	and.l	d6,d0
	and.l	d6,d1
	add.l	d0,d0
	or.l	d1,d0
	move.l	d0,(a1)+	
	subq.w	#1,d7
	bne.b	.loop

	moveq	#IERR_OK,d0
	rts


.sector_error
	moveq	#IERR_NOSECTOR,d0
	rts


SaveFiles
	lea	.TAB(pc),a4
	lea	.num(pc),a3
.loop	movem.l	(a4)+,d0/d1	; offset, length
	lea	.name(pc),a0
	jsr	rawdic_SaveDiskFile(a5)
	addq.b	#1,(a3)
	tst.l	(a4)
	bpl.b	.loop
	moveq	#IERR_OK,d0
	rts

.name	dc.b	"Prince"
.num	dc.b	"0",0
	CNOP	0,2

.TAB	dc.l	1-1,(14-1+1)*$1400		; 1-14
	dc.l	14*$1400,(59-15+1)*$1800	; 14-59


; side 2
	dc.l	348160+0,(9-4+1)*$1800		; 4-9
	dc.l	348160+((10-4)*$1800),(70-10+1)*$1800		; 10-70
	

	dc.l	-1

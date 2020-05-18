***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    CALL IT WOT YA WANT/MAGIC IMAGER SLAVE  )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                               May 2020                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 16-May-2020	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Call It What Ya Want imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(16.05.2020)",0
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

.tracks	TLENTRY	000,159,$1600,SYNC_STD,DMFM_STD
	TLEND



; d0.w: disk number
; a5.l: rawdic

SaveFiles
	lea	FileTab(pc),a4

.save	move.w	(a4),d0		; sector
	bsr.b	.BuildName	; create file name from start sector

	movem.w	(a4)+,d0/d1
	mulu.w	#512*11,d0
	mulu.w	#512*11,d1
	jsr	rawdic_SaveDiskFile(a5)

	tst.w	(a4)
	bpl.b	.save

	moveq	#IERR_OK,d0
	rts

.BuildName
	lea	Name(pc),a0
	moveq	#3-1,d1
.loop	move.b	d0,d2
	and.b	#$f,d2
	cmp.b	#9,d2
	ble.b	.ok
	addq.b	#7,d2
.ok	add.b	#"0",d2
	move.b	d2,6(a0,d1.w)

	lsr.w	#4,d0
	dbf	d1,.loop
	rts
	rts



FileTab	dc.w	01,38		; tune 1
	dc.w	39,25		; tune 2
	dc.w	64,27		; tune 3
	dc.w	91,26		; tune 4
	dc.w	117,14		; tune 5
	dc.w	140,8		; intro
	dc.w	154,6		; main
	dc.w	-1		; end of table
	



Name	dc.b	"CIWYW_"
	dc.b	"000",0
	

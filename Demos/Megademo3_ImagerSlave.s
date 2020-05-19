***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    ALCATRAZ MEGADEMO 3 IMAGER SLAVE   )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             August 2013                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 04-Aug-2013	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Alcatraz Megademo 3 imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(04.08.2013)",0
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
	lea	FILETAB(pc),a4
	moveq	#0,d2
.save	move.l	(a4)+,d0	; start
	bmi.b	.done
	move.l	(a4)+,d1	; length
	lea	.name(pc),a0
	move.b	d2,(a0)
	add.b	#"0",(a0)
	jsr	rawdic_SaveDiskFile(a5)
	addq.w	#1,d2
	bra.b	.save

.done	moveq	#IERR_OK,d0
	rts
	

.name	dc.b	"0",0

	CNOP	0,4

; format:
; dc.l start offset
; dc.l length in bytes

FILETAB	DC.L	$2A800,$28000
	DC.L	$52800,$11800
	DC.L	$64000,$C800
	DC.L	$70800,$23000
	DC.L	$93800,$16800
	DC.L	$AA000,$C800
	DC.L	$B6800,$11800
	dc.l	-1

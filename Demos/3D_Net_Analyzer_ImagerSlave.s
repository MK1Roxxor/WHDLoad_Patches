***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(     3D-NET ANALYZER DEMO IMAGER SLAVE      )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              July 2013                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 19-Jul-2013	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"3D-Net Analyzer demo imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(19.07.2013)",0
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
.save	move.l	(a4)+,d0	; offset
	bmi.b	.done
	lea	.name(pc),a0
	move.b	.TAB(pc,d2.w),(a0)
	move.l	(a4)+,d1	; length
	jsr	rawdic_SaveDiskFile(a5)
	addq.w	#1,d2
	bra.b	.save

.done	moveq	#IERR_OK,d0
	rts
	

.TAB	dc.b	"0123456789ABCDEF",0
.name	dc.b	"0",0

	CNOP	0,4

; format:
; dc.l start 
; dc.l length 

FILETAB
	DC.l	10*$1600*2
	DC.l	12*$1600*2

	DC.l	$16*$1600*2
	DC.l	11*$1600*2

	DC.l	$21*$1600*2
	DC.l	$15*$1600*2

	DC.l	$36*$1600*2
	DC.l	9*$1600*2

	DC.l	$3F*$1600*2
	DC.l	10*$1600*2

	DC.l	$49*$1600*2
	DC.l	6*$1600*2

	dc.l	$10800
	dc.l	$b000
	



	dc.l	-1

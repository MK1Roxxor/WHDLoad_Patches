***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       AFTER BURNER 2 IMAGER SLAVE          )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             January 2016                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 17-Jan-2016	- "After Burner 89" is actually After Burner 2, renamed
;		- special case for track 2/3 handled
;		- tracklength for the other tracks corrected
;		- checksum check was always skipped, fixed

; 16-Jan-2016	- work started
;		- and finished some minutes later, just adapted my
;		  Space Harrier 2 imager that I made back in 2010 and
;		  added checksum checks


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"After Burner 2 imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(17.01.2016)",0
	CNOP	0,4


.disk1	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_SWAPSIDES	; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_DISKIMAGE	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	0		; Called after a disk has been read


.tracks	;TLENTRY	000,000,512*11,SYNC_STD,DMFM_STD
	
	TLENTRY 002,003,6000,$A245,.decode1
	TLENTRY 004,145,6200,$A245,.decode2
	TLEND


.decode1
	move.w	#6000/4-1,d7
	bra.b	DecodeTrack

.decode2
	move.w	#6200/4-1,d7

; d0.w: track number
; a0.l: ptr to mfm buffer
; a1.l: ptr to destination buffer
DecodeTrack
	move.l	#$55555555,d3
	move.w	d0,d5

	cmp.w	#4,d0		; tracks 2-3: no checksum
	blt.b	.skip

	move.l	a0,a4

; calculate checksum
	move.w	#$c1d,d1
	moveq	#0,d0
.calc	sub.l	(a4)+,d0
	dbf	d1,.calc

	move.l	(a4)+,d1
	move.l	(a4)+,d2
	and.l	d3,d1
	and.l	d3,d2
	add.l	d1,d1
	or.l	d1,d2
	cmp.l	d0,d2
	bne.b	.checksumerror


.skip
	addq.w	#8,a0

	cmp.w	#4,d5
	bge.b	.no

	addq.w	#8,a0			; skip checksum
.no

	move.l	#$55555555,d3
	;move.w	#6000/4-1,d7	
.loop	move.l	(a0)+,d0
	move.l	(a0)+,d1
	and.l	d3,d0
	and.l	d3,d1
	add.l	d0,d0
	or.l	d1,d0
	move.l	d0,(a1)+
	dbf	d7,.loop

	moveq	#IERR_OK,d0
.ok	rts


.checksumerror
	moveq	#IERR_CHECKSUM,d0
	rts

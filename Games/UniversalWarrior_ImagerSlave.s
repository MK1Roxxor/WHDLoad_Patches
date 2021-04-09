***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      UNIVERSAL WARRIOR IMAGER SLAVE        )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            November 2017                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 07-Apr-2021	- size optimised (whopping 4 bytes saved) just for fun

; 02-Nov-2017	- and finally finished, all annoying side-swapping stuff
;		  is now handled

; 01-Nov-2017	- work started


TLSWAP	MACRO

.start	SET	\1

	REPT	(\2-\1)/2
	TLENTRY	.start+1,.start+1,$1800,$3489,DecodeTrack
	TLENTRY	.start,.start,$1800,$3489,DecodeTrack

.start	SET	.start+2

	ENDR

; if number of tracks is odd (i.e. not even) we need to read
; one more track
	IFNE (\2-\1)&1<<0
	TLENTRY	.start+1,.start+1,$1800,$3489,DecodeTrack
	ENDC	

	ENDM
	

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Universal Warrior imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(07.04.2021)",0
	CNOP	0,4



.disk1	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_NORESTRICTIONS	; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_DISKIMAGE	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	0		; Called after a disk has been read

; 002-008: sides swapped
; 009-034: sides not swapped
;     035: empty
; 036-061: sides swapped
; 062-159: sides not swapped

.tracks	TLSWAP	002,008
	TLENTRY	009,034,$1800,$3489,DecodeTrack
	TLSWAP	036,061
	TLENTRY	062,160,$1800,$3489,DecodeTrack
	TLEND



; d0.w: track number
; a0.l: ptr to mfm buffer
; d6.w: number of bytes to decode-1
; a1.l: ptr to destination buffer

DecodeTrack
	move.l	#$55555555,d6
	bsr.b	.decode
	move.l	d2,d4		; checksum

	moveq	#0,d3
	move.w	#$1800/4-1,d7
.loop	bsr.b	.decode
	move.l	d2,(a1)+
	add.l	d2,d3
	dbf	d7,.loop

	moveq	#IERR_CHECKSUM,d0
	cmp.l	d3,d4
	bne.b	.ChecksumError

	moveq	#IERR_OK,d0
.ChecksumError
	rts

.decode	move.l	(a0)+,d2
	move.l	(a0)+,d1
	and.l	d6,d2
	add.l	d2,d2
	and.l	d6,d1
	or.l	d1,d2
	rts


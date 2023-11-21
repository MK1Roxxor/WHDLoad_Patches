***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(         HAMMERFIST IMAGER SLAVE            )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            September 2018                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 23-Sep-2018	- removed disk image saving, FL_NOFILES used now

; 22-Sep-2018	- finished, file saving added

; 21-Sep-2018	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Hammerfist imager V1.1",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(23.09.2018)",0
	CNOP	0,4

.disk1	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_DOUBLEINC	; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read


.tracks	TLENTRY 002,020*2,$1A08,SYNC_STD,.DecodeARB2
	TLENTRY	030*2,78*2,$1a18,SYNC_STD,.DecodeBOND
	TLENTRY	001,48*2,$1a2c,SYNC_STD,.DecodeBOND2
	TLEND



.DecodeBOND2
	move.l	#"BOND",d7
	move.w	#$1a2c/4-1,d6
	bra.b	DecodeTrack


.DecodeBOND
	move.l	#"BOND",d7
	move.w	#$1a18/4-1,d6
	bra.b	DecodeTrack

.DecodeARB2
	move.l	#"ARB2",d7
	move.w	#$1a08/4-1,d6


; d0.w: track
; d6.w: length/4-1
; d7.l: ID
; a0.l: MFM buffer
; a1.l: destination
; a5.l: rawdic

DecodeTrack
	bsr.b	.decode
	cmp.l	d7,d0
	bne.b	.error	

	move.w	d6,d5
.loop	bsr.b	.decode
	move.l	d0,(a1)+
	dbf	d5,.loop
	
	moveq	#IERR_OK,d0

.exit	move.l	d7,d0
	rts

.error	moveq	#IERR_CHECKSUM,d0
	rts

.decode	move.l	(a0)+,d0
	move.l	(a0)+,d1
	add.l	d0,d0
	and.l	#$aaaaaaaa,d0
	and.l	#$55555555,d1
	or.l	d1,d0
	rts

SaveFiles
	lea	FILETAB(pc),a4
	moveq	#0,d7			; offset
.loop	move.l	a4,a0			; file name
	move.l	d7,d0
	move.l	4(a4),d1		; length
	add.l	d1,d7
	jsr	rawdic_SaveDiskFile(a5)

	addq.w	#2*4,a4
	tst.l	(a4)
	bne.b	.loop

	moveq	#IERR_OK,d0
	rts


; format: file name, length
; the file name saving is somewhat tricky, the upper
; byte of the length if used to null-terminate the name :)
;
; the first file should actually be called "ARB2" instead of ABR2
; but to save people from reinstalling I have kept Bored Seal's typo :)

FILETAB	dc.l	"ABR2",20*$1a08
	dc.l	"BOND",327320
	dc.l	"BON2",321600
	dc.l	0


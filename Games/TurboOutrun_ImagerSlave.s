***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       TURBO OUTRUN IMAGER SLAVE            )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             March 2024                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 02-Apr-2024	- disk image size optimised, unformatted tracks are not
;		  saved anymore
;		- support for the 2 disk version (SPS 1064) added

; 01-Apr-2024	- imager for 1-disk US version is finished 

; 31-Mar-2024	- work started, adapted from my Afterburner imager


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Turbo Outrun imager V1.1",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(02.04.2024)",0
	CNOP	0,4


.disk1	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_SWAPSIDES	; Disk flags
	dc.l	.Tracks_US_Version		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	.CRC		; Table of certain tracks with CRC values
	dc.l	Two_Disk_Version	; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	.Save_Image	; Called after a disk has been read


.CRC	CRCENTRY	001,$2084
	CRCEND


.Tracks_US_Version
	TLENTRY	001,001,512*11,SYNC_STD,DMFM_STD
	
	; boot code (encrypted)
	TLENTRY 002,003,6000,$A245,.decode1

	; main game data
	TLENTRY 004,029,6200,$4854,.decode2

	; unformatted
	;TLENTRY 030,039,6200,$0000,DMFM_NULL

	; level data
	TLENTRY 040,0158,6200,$A245,.decode2

	TLEND

.Save_Image
	move.l	#512*11,d0	; skip track 0 (only used to determine version)
	move.l	#(3-2+1)*6000+(29-4+1)*6200+(158-40+1)*6200,d1
	bra.w	Save_Disk_Image


.decode1
	move.w	#6000/4-1,d7
	bra.b	DecodeTrack

.decode2
	move.w	#6200/4-1,d7

; d0.w: track number
; d7.w: track size (long words, adapted for dbf)
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


; ---------------------------------------------------------------------------


Two_Disk_Version
	dc.l	.disk2		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_DOUBLEINC|DFLG_RAWREADONLY		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	.Save_Disk1_Data; Called after a disk has been read


.disk2	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_DOUBLEINC|DFLG_RAWREADONLY		; Disk flags
	dc.l	.tracks2	; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	.Save_Disk2_Data; Called after a disk has been read

.tracks	TLENTRY 000,000,$1600,SYNC_STD,DMFM_STD

	TLENTRY 002,016,$1600,$4891,DMFM_STD
	TLENTRY 018,018,$1600,$4891,DMFM_NULL
	TLENTRY 020,094,$1600,$4891,DMFM_STD
	TLEND

.tracks2
	TLENTRY 000,158,$1600,$4891,DMFM_STD
	TLENTRY 001,101,$1600,$4891,DMFM_STD
	TLEND


.Save_Disk1_Data
	moveq	#0,d0
	move.l	#270336,d1
	bra.b	Save_Disk_Image

.Save_Disk2_Data
	moveq	#0,d0
	move.l	#737792,d1
	bra.b	Append_Disk_Image



Save_Disk_Image
	lea	Disk_Image_Name(pc),a0
	jmp	rawdic_SaveDiskFile(a5)

Append_Disk_Image
	lea	Disk_Image_Name(pc),a0
	jmp	rawdic_AppendDiskFile(a5)


Disk_Image_Name
	dc.b	"Disk.1",0


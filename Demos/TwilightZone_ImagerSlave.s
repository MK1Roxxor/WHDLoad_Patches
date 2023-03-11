***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   TWILIGHT ZONE/SHINING 8 IMAGER SLAVE     )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             March 2023                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 04-Mar-2023	- end part added to file table

; 02-Nar-2023	- work started, adapted from my Hero Quest imager

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i




	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Twilight Zone imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(04.03.2023)",0
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

.tracks	TLENTRY	000,159,512*11,SYNC_STD,DMFM_STD
	TLEND
	

; d0.w: disk number

SaveFiles
	lea	File_Table(pc),a4
.savefiles
	movem.w	(a4)+,d0/d1	; start/length
	bsr.b	Build_File_Name
	mulu.w	#512*11*2,d0
	mulu.w	#512*11*2,d1
	jsr	rawdic_SaveDiskFile(a5)
	tst.w	(a4)
	bpl.b	.savefiles

.noboot
	moveq	#IERR_OK,d0
	rts



File_Table

	; start track, end track
TRACK	MACRO
	dc.w	\1,(\2-\1)
	ENDM

	dc.w	63,16		: boot, TetrackPack 2.1
	TRACK	$30,$3f		; loader part, TetraPack 2.1
	TRACK	1,5		; credits
	TRACK	5,9		; plasma
	TRACK	9,11		; unlimited bobs
	TRACK	11,14		; elastic logo
	TRACK	14,19		; members
	TRACK	19,20		; transformer dots
	TRACK	20,22		; bobs
	TRACK	22,24		; vector ship
	TRACK	24,30		; vector part
	TRACK	36,48		; commercial break (Techno Mania3, TetraPack 2.1)
	TRACK	30,36		; end part
	dc.w	-1		; end of file table

; d0.w: start sector
; ----
; a0.l: file name

Build_File_Name
	lea	File_Name(pc),a0
	lea	FN_SECTOR(a0),a1
	move.w	d0,d3
	moveq	#2,d4

; d3.w: source
; d4.w: number of digits to convert
; a1.l: destination

Convert_Number
.loop	moveq	#$f,d5
	and.b	d3,d5
	cmp.b	#$09,d5
	ble.b	.is_valid_hex_number
	addq.b	#$07,d5
.is_valid_hex_number
	add.b	#"0",d5
	move.b	d5,-1(a1,d4.w)
	ror.w	#4,d3
	subq.w	#1,d4
	bne.b	.loop
	rts
	


	RSRESET
FN_HEADER		rs.b	12	; TwilightZone
FN_SECTOR_SEPARATOR	rs.b	1
FN_SECTOR		rs.b	2

File_Name
	dc.b	"TwilightZone_XX",0



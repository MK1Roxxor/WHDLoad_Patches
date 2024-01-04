***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(   SUBCONSCIOUS/DIMENSION X IMAGER SLAVE    )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             January 2024                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 04-Jan-2024	- bootblock doesn't need to be saved anymore

; 03-Jan-2024	- saves all files

; 02-Jan-2024	- work started

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i




	SLAVE_HEADER
	dc.b	5		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Subconscious imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(04.01.2024)",0
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
	dc.l	Save_Files	; Called after a disk has been read

.tracks	TLENTRY	000,159,512*11,SYNC_STD,DMFM_STD
	TLEND


SECTOR_SIZE	= 512
SECTOR_DATA_SIZE= 488

; d0.w: disk number
; a1.l: disk image
; a5.l: rawdic base

Save_Files
	move.l	a1,a6

	lea	File_Names(pc),a2

	; load rootblock
.loop	move.w	#880,d0
	bsr	Load_Sector
	move.l	a2,a1
	bsr	Save_File_Data

	tst.b	(a2)
	bpl.b	.loop

	moveq	#IERR_OK,d0
	rts



; d0.w: sector number
; a6.l: disk image data
; ----
; a0.l: sector data

Load_Sector
	mulu.w	#SECTOR_SIZE,d0
	lea	(a6,d0.l),a0
	rts


; a0.l: rootblock
; a1.l: file name
; a6.l: disk image
; ----
; a2.l: next file name

Save_File_Data
	move.l	a1,d1

	move.l	a1,a2
.get_file_name_end
	tst.b	(a2)+
	bne.b	.get_file_name_end

	move.l	a2,d7
	
	sub.l	a1,a2
	subq.w	#1,a2
	move.l	a2,d2
	moveq	#0,d3
	move.l	d2,d4
	move.l	d4,d6
	move.l	a1,a3
.calculate_hash_for_file_name
	mulu	#13,d2
	move.b	(a1)+,d3
	add.w	d3,d2
	and.w	#$7FF,d2
	subq.w	#1,d4
	bne.b	.calculate_hash_for_file_name
	divu	#72,d2
	swap	d2
	addq.w	#6,d2
	lsl.w	#2,d2
	move.l	(a0,d2.w),d0
.parse_hash_table
	bsr	Load_Sector
	lea	$1B0(a0),a1
	cmp.b	(a1)+,d6
	bne.b	.get_next
	move.l	a3,a2
	move.w	d6,d0
.compare_file_name
	cmpm.b	(a1)+,(a2)+
	bne.b	.get_next
	subq.w	#1,d0
	bne.b	.compare_file_name

.save_file_sectors
	move.l	$10(a0),d0
	beq.b	.all_file_sectors_loaded
	bsr	Load_Sector
	lea	$18(a0),a1

	move.l	a0,-(a7)
	move.l	d1,a0
	move.l	#SECTOR_DATA_SIZE,d0
	jsr	rawdic_AppendFile(a5)
	move.l	(a7)+,a0

	bra.b	.save_file_sectors

.get_next
	move.l	$1F0(a0),d0
	bne.b	.parse_hash_table

.all_file_sectors_loaded

	move.l	d7,a2
	rts

File_Names
	dc.b	"1",0		; intro
	dc.b	"2",0		; main
	dc.b	"3",0		; "no externals"
	dc.b	"RI",0		; reset part
	DC.B	'BLINDEYEPAK',0
	DC.B	'SNOOZEPAK',0
	DC.B	'MRMOISTPAK',0
	DC.B	'FADEPAK',0
	DC.B	'OVERLOADPAK',0
	DC.B	'MODTOUCHPAK',0
	DC.B	'DELETIONPAK',0
	DC.B	'HOISEPAK',0
	DC.B	'TSRPAK',0

	dc.b	-1


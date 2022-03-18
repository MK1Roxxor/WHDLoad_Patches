***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    FLOWER POWER/ANARCHY IMAGER SLAVE       )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              March 2022                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 16-Mar-2022	- offset for file FlowerPower_09 (font data for vector parts)
;		  corrected

; 15-Mar-2022	- file saving

; 14-Mar-2022	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Flower Power imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(16.03.2022)",0
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
	dc.l	Save_Files	; Called after a disk has been read


.tracks	TLENTRY 000,159,$1600,SYNC_STD,DMFM_STD
	TLEND


Save_Files
	lea	.File_Table(pc),a4
.save_all_files
	movem.w	(a4)+,d2/d3
	mulu.w	#512*11,d2
	mulu.w	#512*11,d3

.save_file_data
	move.l	d2,d0
	addq.l	#4,d0		; skip "HEXE" ID
	move.l	#$1600-4,d1
	lea	.File_Name(pc),a0
	jsr	rawdic_AppendDiskFile(a5)
	add.l	#$1600,d2
	sub.l	#$1600,d3
	bne.b	.save_file_data

	lea	.File_Number(pc),a0
	cmp.b	#"9",1(a0)
	bne.b	.ok
	move.b	#"0"-1,1(a0)
	addq.b	#1,(a0)
.ok	addq.b	#1,1(a0)

	tst.w	(a4)
	bne.b	.save_all_files
	moveq	#IERR_OK,d0
	rts


.File_Name	dc.b	"FlowerPower_"
.File_Number	dc.b	"00",0
		CNOP	0,2

.File_Table
	dc.w	1,1		; 00:
	dc.w	2,10		; 01:
	dc.w	48,2		: 02: intro vector
	dc.w	12,3		; 03:
	dc.w	15,33		; 04: replayer code + tune
	dc.w	147,11		; 05: vector world
	dc.w	50,2		; 06:
	dc.w	62,26		; 07: animation: planet->vector ball
	dc.w	52,10		; 08:
	dc.w	88,7		; 09: font data for vector parts
	dc.w	119,3		; 10: cubes + address text
	dc.w	117,2		; 11: greetings
	dc.w	105,12		; 12: RGB vectors and dragonball
	dc.w	95,10
	dc.w	122,11
	dc.w	133,12
	dc.w	145,2
	dc.w	0		; end of file table
	

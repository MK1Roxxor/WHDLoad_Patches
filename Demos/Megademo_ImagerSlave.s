***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       SARGON MEGADEMO IMAGER SLAVE         )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             April 2022                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 15-Apr-2022	- work started
;		- and finished a few minutes later


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Sargon Megademo imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(15.04.2022)",0
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
	lea	File_Table(pc),a4
.save_all_files
	move.l	(a4)+,d1
	move.l	(a4)+,d0
	lea	File_Name(pc),a0
	jsr	rawdic_SaveDiskFile(a5)
	
	lea	File_Number(pc),a0
	addq.b	#1,(a0)

	tst.l	(a4)
	bne.b	.save_all_files
	rts

File_Name
	dc.b	"Sargon_Megademo_Part_"
File_Number
	dc.b	"0",0


File_Table
	dc.l	$c600
	dc.l	$400

	DC.L	$B400		; length
	DC.L	$C600		; offset

	DC.L	$12E00
	DC.L	$17A00

	DC.L	$20800
	DC.L	$2A800

	DC.L	$1C600
	DC.L	$4B000

	DC.L	$F800
	DC.L	$77600

	DC.L	$23600
	DC.L	$86E00

	DC.L	$10000
	DC.L	$67600

	dc.l	0		; end of file table

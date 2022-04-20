***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    ARCADIA TEAM MEGADEMO IMAGER SLAVE      )*)---.---.   *
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

; 20-Apr-2022	- files are saved with their real file size now, more than
;		  100 KB saved (923.658 vs. 782.394 bytes), file sizes are
; 		  easy to determine as they are stored in the ByteKiller
;		  header

; 17-Apr-2022	- work started
;		- and finished a few minutes later


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Arcadia Team Megademo imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(20.04.2022)",0
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
	move.l	(a4)+,d0
	move.l	(a4)+,d1
	lea	File_Name(pc),a0
	jsr	rawdic_SaveDiskFile(a5)
	
	lea	File_Number(pc),a0
	addq.b	#1,(a0)

	tst.l	(a4)
	bne.b	.save_all_files
	moveq	#IERR_OK,d0
	rts

File_Name
	dc.b	"Arcadia_Megademo_Part_"
File_Number
	dc.b	"0",0
	CNOP	0,2
	
File_Table
.Decruncher_Size	= $ce
.Decruncher_Size2	= $de
.Header_Size		= 3*4	; crunched length, decrunched length, checksum

	dc.l	$4fc00,$18c00	; offset, length
	dc.l	$2c00,$1dd40+.Decruncher_Size+.Header_Size
	dc.l	$23c00,$11134+.Decruncher_Size+.Header_Size
	dc.l	$37000,$137d0+.Decruncher_Size+.Header_Size
	dc.l	$6e000,$2653c+.Decruncher_Size+.Header_Size
	dc.l	$97400,$12f74+.Decruncher_Size+.Header_Size
	dc.l	$aa800,$11284+.Decruncher_Size2+.Header_Size
	dc.l	$bdc00,$190bc+.Decruncher_Size+.Header_Size
	dc.l	0		; end of file table

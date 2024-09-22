***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(         HAMMER BOY IMAGER SLAVE            )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            September 2024                               *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 22-Sep-2024	- minor changes, imager is finished

; 21-Sep-2024	- code cleaned up a bit

; 20-Sep-2024	- Risky Woods imager adapted to save "Hammer Boy" files 


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Hammer Boy imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(22.09.2024)",0
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


.tracks	TLENTRY 000,115,$1600,SYNC_STD,DMFM_STD
	TLEND

SECTOR_SIZE	= 512

SaveFiles
	moveq	#0,d0
	jsr	rawdic_ReadTrack(a5)
	lea	$200(a1),a4	; a4: directory

	moveq	#0,d7		; file number
.save	move.w	d7,d0
	lea	.name(pc),a0
	bsr.b	.Build_File_Name

	move.w	(a4)+,d0	; sector number
	moveq	#0,d1
	move.w	(a4)+,d1	; file size in words
	beq.b	.nextfile
	add.l	d1,d1		; convert file size to bytes
	mulu.w	#SECTOR_SIZE,d0
	jsr	rawdic_SaveDiskFile(a5)

.nextfile
	addq.w	#1,d7
	cmp.w	#"HA",(a4)
	bne.b	.save

	; save main code
	lea	.name(pc),a0
	move.b	#"H",(a0)
	move.b	#"A",1(a0)
	move.l	#$400,d0
	move.l	#$13400,d1
	jsr	rawdic_SaveDiskFile(a5)


.done	moveq	#IERR_OK,d0
	rts

.Build_File_Name
	movem.l	d0/d1/a0,-(a7)
	moveq	#2-1,d3		; max. 2 digits
	lea	.TAB(pc),a1
.loop	moveq	#-"0",d1
.loop2	sub.w	(a1),d0
	dbcs	d1,.loop2
	neg.b	d1
	move.b	d1,(a0)+
.nope	add.w	(a1)+,d0
	dbf	d3,.loop
	movem.l	(a7)+,d0/d1/a0
	rts

.TAB	dc.w	10
	dc.w	1

.name	dc.b	"00",0



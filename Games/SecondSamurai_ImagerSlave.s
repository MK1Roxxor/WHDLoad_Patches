***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(      SECOND SAMURAI IMAGER SLAVE           )*)---.---.   *
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

; 25-Jan-2016	- now also saves directories and the boot file
;		- dummy files on disk 1 are not saved anymore
;		- tested with AGA version too, no problems

; 24-Jan-2016	- work started
;		- and finished, saves all files


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Second Samurai imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(25.01.2016)",0
	CNOP	0,4

.disk1	dc.l	.disk2		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

.disk2	dc.l	.disk3		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

.disk3	dc.l	0		; Pointer to next disk structure
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
	move.w	d0,d5
	
	lea	.disk(pc),a0
	add.b	#"0",d0
	move.b	d0,(a0)

	cmp.b	#3,d5
	bne.b	.notdisk3
	addq.w	#1,d5		; game uses disk 4 as disk 3
.notdisk3


; load directory
	moveq	#0,d0
	jsr	rawdic_ReadTrack(a5)
	lea	512(a1),a4	; directory

; decrypt
	move.l	a4,a0
	move.w	#48*4-1,d7
	move.l	#$5ea693bd,d1
.decrypt
	eor.b	d1,(a0)+
	rol.l	#5,d1
	dbf	d7,.decrypt



	moveq	#48-1,d6
	moveq	#0,d7		; file number
.save	move.w	d7,d0
	bsr.b	.convName	; create file name

	move.w	(a4)+,d0	; offset (sector)
	move.w	(a4)+,d1	; length (sectors)
	move.l	(a4)+,d1	; disk number+length in bytes

	move.l	d1,d2
	rol.l	#8,d2		; d2.b: disk number
	cmp.b	d2,d5		; correct disk?
	bne.b	.skip
	
	and.l	#$00ffffff,d1	; length bytes only
	cmp.l	#10,d1		; don't save "dummy" files on disk 1
	ble.b	.skip
	mulu.w	#512,d0
	bsr.b	.saveFile

.skip	addq.w	#1,d7
	dbf	d6,.save

	cmp.w	#1,d5
	bne.b	.noboot
	moveq	#12,d0
	bsr	.convName
	move.l	#$400,d0
	move.l	#$1200,d1
	bsr.b	.saveFile
.noboot

; save directory for each disk
	moveq	#99,d0
	bsr	.convName
	move.l	#512,d0
	move.l	d0,d1
	bsr.b	.saveFile

	moveq	#IERR_OK,d0
	rts

.saveFile
	lea	.name(pc),a0
	jmp	rawdic_SaveDiskFile(a5)
	
	


.convName
	movem.l	d0/d1/a0,-(a7)
	lea	.num(pc),a0
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

.name	dc.b	"SecondSamurai"
.disk	dc.b	"x_"
.num	dc.b	"00",0


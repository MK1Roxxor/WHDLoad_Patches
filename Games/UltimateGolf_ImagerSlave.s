***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        ULTIMATE GOLF IMAGER SLAVE       )*)---.---.      *
*   `-./                                                        \.-'      *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                               May 2021                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 13-May-2021	- final version of the imager, code cleaned up a bit

; 05-May-2021	- saves data correctly now (original decoder uses the
;		  MFM buffer as destination hence disk image data was
;		  empty)
;		- file saving added

; 04-May-2021	- work started
;		- reads all tracks correctly but saved disk image is empty


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Ultimate Golf imager V1.1",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(13.05.2021)",0
	CNOP	0,4



.disk1	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_SWAPSIDES	; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read


.tracks	TLENTRY	002,131,$1770,SYNC_STD,DecodeTrack
	TLEND


SaveFiles
	bsr	.SaveBootFiles
	
	; save game files
	lea	FileTab(pc),a2		; file table
	moveq	#(FileTabEnd-FileTab)/16-1,d7	; number of files to save
.loop2	bsr.b	.SaveFileData

	addq.w	#1,d6
	add.w	#4*4,a2		; next file
	dbf	d7,.loop2

	moveq	#IERR_OK,d0
	rts



.SaveBootFiles
	moveq	#2,d0
	jsr	rawdic_ReadTrack(a5)

	lea	$98e(a1),a2		; file table
	moveq	#0,d6			; file number
	moveq	#($9fe-$98e)/16-1,d7	; number of files to save
.loop	bsr.b	.SaveFileData

	addq.w	#1,d6
	add.w	#4*4,a2		; next file
	dbf	d7,.loop


	; save boot data
	lea	.BootEntry(pc),a2
	bsr	.SaveFileData
	addq.w	#1,d6
	rts


; a2.l: file entry
; d6.w: file number

.SaveFileData
	move.l	1*4(a2),d0		; track
	subq.w	#2,d0
	mulu.w	#$1770,d0
	move.l	3*4(a2),d1		; length
	beq.b	.skip

	; build file number part of file name
	move.l	d6,d5
	divu.w	#10,d5
	lea	.Num(pc),a0
	add.b	#"0",d5
	move.b	d5,(a0)+
	swap	d5
	add.b	#"0",d5
	move.b	d5,(a0)+

	lea	.Name(pc),a0
	jsr	rawdic_SaveDiskFile(a5)

.skip	rts


.Name	dc.b	"UltimateGolf_"
.Num	dc.b	"00",0
	CNOP	0,2



.BootEntry
	dc.l	0
	dc.l	0+2
	dc.l	0
	dc.l	$1770

FileTab
	DC.L	$3F756
	DC.L	2
	DC.L	0
	DC.L	0	;$3EC, directory file, no need to save

	DC.L	0
	DC.L	0
	DC.L	0
	DC.L	0

	DC.L	$675F4
	DC.L	0
	DC.L	0
	DC.L	0	;$968

	DC.L	$50816
	DC.L	$9F
	DC.L	0
	DC.L	0	;10, disk ID file, no need to save

	DC.L	$51778	; file number 4: course 1
	DC.L	$6E
	DC.L	0
	DC.L	$642A

	DC.L	$51778	; file number 5: course 2
	DC.L	$75
	DC.L	0
	DC.L	$642A
FileTabEnd


; a0.l: mfm buffer
; a1.l: destination
; d0.w: track number

DecodeTrack
	exg	a0,a1
	move.l	a1,a6		; a1 = a6 = MFM


	move.l	a0,a3

	move.w	d0,d7		; save track number

	; decode track number
	move.w	4-2(a6),d0
	bsr	DecodeByte
	cmp.w	d0,d7
	bne.b	.sector_error

	moveq	#3-1,d5

	; decode part number (0-2)
.loop	move.w	6-2(a6),d0
	bsr	DecodeByte
	cmp.w	#2,d0
	bgt.b	.sector_error
	move.w	d0,d7

	;lea	6-2(a6),a0

	; prepare destination 
	move.l	a3,a0
	mulu.w	#$1770/3,d0
	add.w	d0,a0
	move.l	a0,a2
	

	; decode checksum
	move.w	$fa8-2(a6),d0
	bsr.b	DecodeByte
	move.w	d0,d4
	lsl.w	#8,d4
	move.w	$faa-2(a6),d0
	bsr.b	DecodeByte
	or.w	d0,d4
	

	; calculate checksum over loaded data
	lea	8-2(a6),a0
	move.w	#$1770/3/2-1,d0
	bsr.b	CalcChecksum
	cmp.w	d1,d4
	bne.b	.checksum_error

	; decode data for current part of track
	move.w	#$1770/3-1,d0	
	move.l	a2,a0
	lea	8-2(a6),a1
	bsr.b	DecodeBytes

	;lea	$fc8-2(a6),a6

	jsr	rawdic_NextSync(a5)
	dbf	d5,.loop


	moveq	#IERR_OK,d0
	rts

.sector_error
	moveq	#IERR_NOSECTOR,d0
	rts

.checksum_error
	moveq	#IERR_CHECKSUM,d0
	rts



DecodeBytes
.decode	moveq	#0,d1
	moveq	#8-1,d2
	move.w	(a1)+,d3
.loop	lsl.w	#1,d3
	lsl.l	#1,d3
	dbf	d2,.loop
	swap	d3
	move.b	d3,(a0)+
	dbf	d0,.decode
	rts

DecodeByte
	moveq	#8-1,d2
.loop	lsl.w	#1,d0
	lsl.l	#1,d0
	dbf	d2,.loop
	swap	d0
	and.w	#$FF,d0
	rts


CalcChecksum
	move.w	d2,-(a7)
	moveq	#0,d1
	move.w	d1,d2
.loop	move.w	(a0)+,d2
	eor.w	d2,d1
	move.w	(a0)+,d2
	eor.w	d2,d1
	dbf	d0,.loop
	move.w	(a7)+,d2
	rts



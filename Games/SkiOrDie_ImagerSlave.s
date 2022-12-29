***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        SKI OR DIE IMAGER SLAVE             )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            December 2022                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 29-Dec-2022	- code cleaned up a bit, using file name structure now

; 28-Dec-2022	- work started


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i




	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Ski or Die imager V1.1",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(29.12.2022)",0
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

.tracks	TLENTRY	000,079,512*11,SYNC_STD,DMFM_STD
	TLENTRY	082,159,512*11,SYNC_STD,DMFM_STD
	TLEND


; a5.l: rawdic base

Save_Files
	lea	File_Table(pc),a4
	moveq	#0,d7		; file number
.save_all_files
	lea	File_Name(pc),a0
	bsr	Build_File_Name
	movem.w	(a4)+,d0/d1
	mulu.w	#512,d0
	mulu.w	#512,d1
	jsr	rawdic_SaveDiskFile(a5)

	addq.w	#1,d7
	tst.w	(a4)
	bne.b	.save_all_files
	moveq	#IERR_OK,d0
	rts


; a0.l: file name
; d7.l: file number

Build_File_Name
	move.l	d7,d0
	divu.w	#10,d0
	add.b	#"0",d0
	move.b	d0,FN_NUMBER(a0)
	swap	d0
	add.b	#"0",d0
	move.b	d0,FN_NUMBER+1(a0)
	rts

File_Name	dc.b	"Ski_or_Die_00",0
		CNOP	0,2

; file name structure
FN		RSRESET
FN_NAME		rs.b	11
FN_NUMBER	rs.b	2

File_Table
	dc.w	$0002,$0001
	dc.w	$0003,$0016
	dc.w	$0019,$002E
	dc.w	$0047,$0004
	dc.w	$004B,$0010
	dc.w	$005B,$0017
	dc.w	$0072,$000F
	dc.w	$0081,$003F
	dc.w	$00C0,$0026
	dc.w	$00E6,$0001
	dc.w	$00E7,$0018
	dc.w	$00FF,$0010
	dc.w	$010F,$0008
	dc.w	$0117,$0008
	dc.w	$011F,$004F
	dc.w	$016E,$0034
	dc.w	$01A2,$0005
	dc.w	$01A7,$000D
	dc.w	$01B4,$0043
	dc.w	$01F7,$0028
	dc.w	$021F,$0023
	dc.w	$0242,$0010
	dc.w	$0252,$0016
	dc.w	$0268,$0034
	dc.w	$029C,$0034
	dc.w	$02D0,$001E
	dc.w	$02EE,$0001
	dc.w	$02EF,$0016
	dc.w	$0305,$002D
	dc.w	$0332,$0072
	dc.w	$03C0,$004A
	dc.w	$040D,$0045
	dc.w	$0452,$0034
	dc.w	$0486,$0016
	dc.w	$049C,$0009
	dc.w	$04A5,$000B
	dc.w	$04B0,$001D
	dc.w	$04CD,$00AD
	dc.w	$057A,$001D

	; game binary, -$2c00 takes into account that the imager
	; skips the directory track
	dc.w	($b5a00-$2c00)/512,$1c800/512
	dc.w	0			; end of file table


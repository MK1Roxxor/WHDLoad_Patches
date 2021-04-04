***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       ARMOUR GEDDON IMAGER SLAVE           )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             March 2021                                  *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 04-Apr-2021	- all disk images created correctly and compatible
; Easter Sunday	  with Dark Angel's old imager
;		- data for the variable track length data is saved using
;		  yet another new approch, no buffers used anymore
;		- data for game over animation (disk 2, track 159) is
;		  saved as Disk.7

; 03-Apr-2021	- disk image saving simplified, using my new approach
;		  developed for the Nitro imager

; 28-Mar-2021	- disk image creation simplified, track lengths for all
;		  tracks are stored in a table which is used for creating
;		  the disk image

; 25-Mar-2021	- remaining decoder for disk 1 done
;		- disk 2/3 decoders done

; 24-Mar-2021	- work started, adapted from my Nitro imager


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Armour Geddon imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(04.04.2021)",0
	CNOP	0,4


.disk1	dc.l	.disk2		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_NORESTRICTIONS		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveAll_Disk1	; Called after a disk has been read

.disk2	dc.l	.disk3		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_NORESTRICTIONS		; Disk flags
	dc.l	.tracks2	; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveAll_Disk2	; Called after a disk has been read

.disk3	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	DFLG_NORESTRICTIONS		; Disk flags
	dc.l	.tracks3	; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveAll_Disk3	; Called after a disk has been read


.tracks	TLENTRY	000,000,$1600,SYNC_STD,DMFM_STD
	TLENTRY	000,000,$136,$428a,DecodeDiskData

	; fixed track length
	TLENTRY	002,053,$1800,$4429,DecodeTrack_1800	; disk.2

	; fixed track length
	TLENTRY	054,110,$1898,$4429,DecodeTrack_1898	; disk.1

	; variable track length
	TLENTRY	001,001,$2000,$4429,DecodeTrack
	TLENTRY	111,148,$2000,$4429,DecodeTrack		; disk.3
	TLEND

.tracks2
	TLENTRY	000,000,$136,$428a,DecodeDiskData

	; fixed track length
	TLENTRY	004,020,$1800,$4489,DecodeTrack_1800_2	; disk.5

	; variable track length
	TLENTRY	54,151,$2000,$4429,DecodeTrack		; disk.4

	; fixed track length
	TLENTRY	159,159,$1800,$4489,DecodeTrack_1800_2
	TLEND

.tracks3
	; fixed track length
	TLENTRY	000,114,$1800,$4489,DecodeTrack_1800_2	; disk.6
	TLEND


; ---------------------------------------------------------------------------
;
; Process all data from game disk 1 and create the disk files.

; d0.w: disk number
; a0.l: disk structure
; a1.l: disk image data
; a5.l: RawDIC base

SaveAll_Disk1

	; save boot track
	lea	BootTrackName(pc),a0
	moveq	#0,d0
	move.l	#$1600,d1
	jsr	rawdic_SaveDiskFile(a5)

	bsr	SaveDisk1Data_To_Disk2	; OK!
	bsr	SaveDisk1Data_To_Disk1	; OK!
	bsr	SaveDisk1Data_To_Disk3	; OK!
	
	moveq	#IERR_OK,d0
	rts


SaveDisk1Data_To_Disk2
	moveq	#2,d0
	bsr	SetDiskName

	move.l	#310+$1600,d0
	move.l	#((53-2)+1)*$1800,d1
	bsr	SaveDiskFile
	rts


SaveDiskFile
	move.l	d1,d6
	add.l	d0,d6
	lea	DiskName(pc),a0
	jsr	rawdic_SaveDiskFile(a5)

	move.l	d6,d0
	rts

SaveDisk1Data_To_Disk1
	moveq	#1,d0
	bsr	SetDiskName

	move.l	d6,d0
	move.l	#((110-54)+1)*$1898,d1
	bra.w	SaveDiskFile


SaveDisk1Data_To_Disk3
	moveq	#3,d0
	bsr	SetDiskName

	; save track length data
	move.l	#0+$1600,d0
	move.l	#310,d1
	bsr	SaveDiskFile

	moveq	#1,d6
	bsr.b	AppendTrackData

	moveq	#111,d6
.save_loop
	bsr.b	AppendTrackData
	
	addq.w	#1,d6
	cmp.w	#148,d6
	ble.b	.save_loop
	rts


; d6.w: track number

AppendTrackData
	move.w	d6,d0
	jsr	rawdic_ReadTrack(a5)
	lea	DiskName(pc),a0

	moveq	#0,d0
	move.w	d6,d0
	add.w	d0,d0
	lea	TrackLenTab,a2
	move.w	(a2,d0.w),d0
	lsl.w	#2,d0
	jmp	rawdic_AppendFile(a5)
	


; ---------------------------------------------------------------------------
;
; Process all data from game disk 2 and create the disk files.

SaveAll_Disk2
	bsr	SaveDisk2Data_To_Disk4
	bsr	SaveDisk2Data_To_Disk5
	bsr	SaveDisk2Data_To_Disk7
	moveq	#IERR_OK,d0
	rts


SaveDisk2Data_To_Disk4
	moveq	#4,d0
	bsr	SetDiskName

	; save track length data
	moveq	#0,d0
	move.l	#310,d1
	bsr	SaveDiskFile

	moveq	#54,d6
.save_loop
	move.w	d6,d0
	bsr	AppendTrackData
	addq.w	#1,d6
	cmp.w	#151,d6
	ble.b	.save_loop

	
SaveDisk2Data_To_Disk5
	moveq	#5,d0
	bsr	SetDiskName

	move.l	#310,d0
	move.l	#(20-4+1)*$1800,d1
	bra.w	SaveDiskFile

SaveDisk2Data_To_Disk7
	moveq	#7,d0
	bsr	SetDiskName

	move.w	#159,d0
	jsr	rawdic_ReadTrack(a5)

	lea	DiskName(pc),a0
	move.l	#$1800,d0
	jsr	rawdic_SaveFile(a5)
	rts



; ---------------------------------------------------------------------------
;
; Process all data from game disk 1 and create the disk files.

SaveAll_Disk3
	moveq	#6,d0
	bsr	SetDiskName

	moveq	#0,d0
	move.l	#(114-000)*$1800,d1
	lea	DiskName(pc),a0
	jsr	rawdic_SaveDiskFile(a5)

	moveq	#IERR_OK,d0
	rts

; ---------------------------------------------------------------------------


SetDiskName
	add.b	#"0",d0
	lea	DiskName(pc),a0
	move.b	d0,5(a0)
	rts


DiskName	dc.b	"Disk.1",0
BootTrackName	dc.b	"BootTrack",0
		CNOP	0,2
	


; ---------------------------------------------------------------------------

DecodeDiskData
	addq.w	#2,a0

	move.l	a1,a3

	move.w	#310/2-1,d1
	move.w	d1,d6
.loop	move.l	(a0)+,d2
	and.l	#$55555555,d2
	move.l	d2,d3
	swap	d3
	add.w	d3,d3
	or.w	d3,d2
	move.w	d2,(a1)+
	dbf	d1,.loop

	lea	2(a3),a1
	;move.w	#$9a,d6
	bsr.w	CalcChecksum
	moveq	#IERR_CHECKSUM,d0
	cmp.w	(a3),d2
	bne.b	.error



	; create track length table
	lea	2+2*4(a3),a0		; 2+2*4: checksum, diskname+data
	lea	TrackLenTab,a1
	moveq	#80-1,d7
.loop2	moveq	#0,d0
	move.b	(a0)+,d0
	lsl.w	#4,d0
	moveq	#0,d1
	move.b	d0,d1
	lsl.w	#4,d1
	move.b	(a0)+,d0
	move.b	(a0)+,d1
	move.w	d0,(a1)+
	move.w	d1,(a1)+
	dbf	d7,.loop2


	addq.w	#4,a0			; skip disk length

	moveq	#4,d7
.lbC000C70
	moveq	#32-1,d6
	move.l	(a0)+,d0
.lbC000C74
	moveq	#0,d1
	add.l	d0,d0
	addx.w	d1,d1
	move.b	d1,(a1)+
	dbf	d6,.lbC000C74
	dbf	d7,.lbC000C70

	moveq	#IERR_OK,d0
.error	rts


; ---------------------------------------------------------------------------

; d0.w: track number
; a0.l: MFM data
; a1.l: destination

DecodeTrack
	addq.w	#2,a0

	exg	a0,a1			; a0: destination, a1: MFM

	; decode checksum
	move.l	(a1)+,d5
	and.l	#$55555555,d5
	move.w	d5,d1
	swap	d5
	add.w	d5,d5
	or.w	d1,d5


	; get track length and mask value
	move.w	d0,d7
	add.w	d7,d7
	lea	TrackLenTab,a2
	move.w	(a2,d7.w),d7
	beq.b	.sector_error

	move.l	#$AAAAAAAA,d1
	lea	MaskTab,a2
	tst.b	(a2,d0.w)
	beq.b	.mask_ok
	move.l	#$55555555,d1
.mask_ok



	; decode track data
	movem.l	d5/d7,-(sp)
	bsr.b	.Decode
	movem.l	(sp)+,d5/d7
	move.w	d6,d2
	swap	d6
	eor.w	d6,d2
	and.w	#$FFFA,d2

	moveq	#0,d0

	move.w	d7,d0
	cmp.w	d2,d5
	bne.b	.error


	moveq	#IERR_OK,d0
	rts	

.error	moveq	#IERR_CHECKSUM,d0
	rts

.sector_error
	moveq	#IERR_NOSECTOR,d0
	rts


.Decode	moveq	#$1F,d2
	moveq	#$1F,d4
	moveq	#0,d3
	moveq	#0,d6
	subq.w	#1,d7
	moveq	#$1F,d5
	move.l	(a1)+,d0
	btst	d4,d0
	beq.b	.lbC000EC2
.lbC000E9A
	add.l	d3,d3
	addq.w	#1,d3
	dbf	d5,.lbC000EB0
	eor.l	d1,d3
	add.l	d3,d6
	move.l	d3,(a0)+
	dbf	d7,.lbC000EAE
	bra.b	.lbC000F10

.lbC000EAE
	moveq	#$1F,d5
.lbC000EB0
	subq.w	#2,d4
	bpl.b	.lbC000EBE
	and.w	d2,d4
	move.l	(a1)+,d0
.lbC000EBE
	btst	d4,d0
	bne.b	.lbC000E9A
.lbC000EC2
	add.l	d3,d3
	dbra	d5,.lbC000ED6
	eor.l	d1,d3
	add.l	d3,d6
	move.l	d3,(a0)+
	dbra	d7,.lbC000ED4
	bra.b	.lbC000F10

.lbC000ED4
	moveq	#$1F,d5
.lbC000ED6
	dbf	d4,.lbC000EE4

	moveq	#$1F,d4
	move.l	(a1)+,d0
.lbC000EE4
	btst	d4,d0
	bne.b	.lbC000E9A
	add.l	d3,d3
	dbra	d5,.lbC000EFC
	eor.l	d1,d3
	add.l	d3,d6
	move.l	d3,(a0)+
	dbf	d7,.lbC000EFA
	bra.b	.lbC000F10

.lbC000EFA
	moveq	#$1F,d5
.lbC000EFC
	subq.w	#3,d4
	bpl.b	.lbC000F0A
	and.w	d2,d4
	move.l	(a1)+,d0
.lbC000F0A
	btst	d4,d0
	bne.b	.lbC000E9A
	beq.b	.lbC000EC2
.lbC000F10
	rts


; ---------------------------------------------------------------------------

; d0.w: track number
; a0.l: ptr to mfm buffer
; a1.l: ptr to destination buffer

DecodeTrack_1898
	addq.w	#2,a0

	move.l	a1,a2

	move.w	#$5555,d3
	bsr.b	.DecodeWord
	move.w	d0,d2

	move.w	#$1898/2-1,d7
.loop	bsr.b	.DecodeWord
	move.w	d0,(a1)+
	dbf	d7,.loop

	moveq	#0,d0
	move.w	#$1898/2-1,d7
.checksum
	move.w	(a2)+,d1
	addx.w	d1,d0
	dbf	d7,.checksum
	and.w	#$FFFA,d0
	cmp.w	d0,d2
	bne.b	.checksum_error
	moveq	#IERR_OK,d0
	rts

.checksum_error
	moveq	#IERR_CHECKSUM,d0
	rts

.DecodeWord
	move.w	(a0)+,d0
	move.w	(a0)+,d1
	and.w	d3,d0
	and.w	d3,d1
	add.w	d0,d0
	or.w	d1,d0
	rts


; ---------------------------------------------------------------------------

; d0.w: track number
; a0.l: ptr to mfm buffer
; a1.l: ptr to destination buffer

DecodeTrack_1800
	move.w	d0,d7
	move.l	a1,a2

	move.l	#$55555555,d5

	; decode track number
	bsr.b	.DecodeLong
	cmp.b	d0,d7
	bne.b	.sector_error


	; decode checksum
	bsr.b	.DecodeLong
	move.l	d0,d7

	; calculate checksum over loaded data
	move.l	a0,-(a7)
	move.l	(a0)+,d0
	move.w	#$1800/2-2,d1
.loop	move.l	(a0)+,d2
	eor.l	d2,d0
	dbf	d1,.loop
	and.l	d5,d0
	move.l	(a7)+,a0
	cmp.l	d0,d7
	bne.b	.checksum_error

	; decode track data
	lea	$1800(a0),a1
	move.w	#$1800/4-1,d7
.loop2	move.l	(a0)+,d0
	move.l	(a1)+,d1
	and.l	d5,d0
	and.l	d5,d1
	add.l	d0,d0
	or.l	d1,d0
	move.l	d0,(a2)+
	dbf	d7,.loop2

	moveq	#IERR_OK,d0
	rts

.DecodeLong
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	and.l	d5,d0
	and.l	d5,d1
	add.l	d0,d0
	or.l	d1,d0
	rts


.checksum_error
	moveq	#IERR_CHECKSUM,d0
	rts

.sector_error
	moveq	#IERR_NOSECTOR,d0
	rts


; a1.l: data to check
; d6.w: length (adapted for "dbf")
; ----
; d2.w: checksum

CalcChecksum
	movem.l	d1/d6/a1,-(sp)
	;lsr.w	#1,d6
	moveq	#-1,d2
	add.w	d2,d2
	bra.b	.enter

.loop	move.w	(a1)+,d1
	addx.w	d1,d2
.enter	dbf	d6,.loop

	and.w	#$fffa,d2
	
	movem.l	(sp)+,d1/d6/a1
	rts




; ---------------------------------------------------------------------------

; d0.w: track number
; a0.l: ptr to mfm buffer
; a1.l: ptr to destination buffer

DecodeTrack_1800_2
	move.w	#$5555,d3

	cmp.w	(a0)+,d3
	bne.b	.error

	; decode signature
	moveq	#4-1,d7
.decode_sig
	bsr.b	.DecodeByte
	move.b	d0,d2
	rol.l	#8,d2
	dbf	d7,.decode_sig
	ror.l	#8,d2
	cmp.l	#"KEEP",d2
	bne.b	.error


	addq.w	#2,a0			; skip disk ID
	move.w	#$1800-1,d7
.loop	bsr.b	.DecodeByte
	move.b	d0,(a1)+
	dbf	d7,.loop


	moveq	#IERR_OK,d0
	rts

.error	moveq	#IERR_NOSECTOR,d0
	rts

.DecodeByte
	move.b	(a0)+,d0
	move.b	(a0)+,d1
	and.w	d3,d0
	and.w	d3,d1
	add.w	d0,d0
	or.w	d1,d0
	rts


	SECTION	BSS,BSS

TrackLenTab	ds.w	160
MaskTab		ds.b	160

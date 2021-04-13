***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(            PB IMAGER SLAVE                 )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              April 2021                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 13-Apr-2021	- support for the TNT compilation version (DOS files) added

; 12-Apr-2021	- work started
;		- and finished a few minutes later, saves all files, names
;		  are built in the same way as the TNT compilation uses them


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	5		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"APB - All Points Bulletin imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(13.04.2021)",0
	CNOP	0,4

.disk1	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES
	dc.l	.CRC_NDOS		; Table of certain tracks with CRC values
	dc.l	.disk1_DOS	; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles_NDOS	; Called after a disk has been read

.disk1_DOS
	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES
	dc.l	.CRC_DOS	; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	SetRoutines	; Called before a disk is read
	dc.l	SaveFiles_DOS	; Called after a disk has been read
	

.CRC_NDOS
	CRCENTRY 3,$d4f5	; SPS 1240, SPS 2870
	CRCEND

.CRC_DOS
	CRCENTRY 3,$9564	; SPS 1708
	CRCEND
	

.tracks	TLENTRY 000,000,512*11,SYNC_STD,DMFM_STD
	TLENTRY 001,001,512*11,SYNC_STD,DMFM_NULL
	TLENTRY 002,159,512*11,SYNC_STD,DMFM_STD
	TLEND


SaveFiles_NDOS
	lea	FileTab(pc),a4
.loop	movem.l	(a4),d0/d1
	bsr.b	BuildName
	movem.l	(a4)+,d0/d1
	mulu.w	#512,d0
	jsr	rawdic_SaveDiskFile(a5)
	tst.l	(a4)
	bne.b	.loop

	bsr.b	SaveDummyFile

	moveq	#IERR_OK,d0
	rts

SaveDummyFile
	lea	.DummyName(pc),a0
	move.l	a0,a1			; data (dummy as we save a 0-byte file)
	moveq	#0,d0			; length
	jmp	rawdic_SaveFile(a5)

.DummyName
	dc.b	"Dummy",0
	CNOP	0,2


; d0.w: sector number
; ----
; a0.l: ptr to file name

BuildName
	lea	.FileName(pc),a0
	moveq	#3-1,d7

.loop	moveq	#15,d1
	and.b	d0,d1

	cmp.b	#9,d1
	ble.b	.ok
	addq.b	#7,d1
.ok	add.b	#"0",d1

	move.b	d1,5(a0,d7.w)

	ror.w	#4,d0

	dbf	d7,.loop
	rts

.FileName	dc.b	"APB.0000",0
	CNOP	0,2

; offset (sectors), size (bytes)

FileTab	DC.L	$32E
	DC.L	$7D04

	DC.L	$45D
	DC.L	$1C400

	DC.L	$319
	DC.L	$2808


	DC.L	$304
	DC.L	$2808

	DC.L	$2EF
	DC.L	$2808

	DC.L	$378
	DC.L	$1404

	DC.L	$2D3
	DC.L	$37F0

	DC.L	$3D7
	DC.L	$10B20

	DC.L	$383
	DC.L	$A67A

	DC.L	$610
	DC.L	$19D34

	DC.L	$53F
	DC.L	$1A008


	; main
	dc.l	$184
	dc.l	$14c*512

	dc.l	0		; end of table




; ---------------------------------------------------------------------------


SetRoutines
	move.l	#SaveSectors,File_SaveSector
	rts
	

; a0.l: file name
; a1.l: data
; d0.l: size

SaveSectors
	lea	rawdic_SaveFile(a5),a2
	lea	FileOffset(pc),a3
	tst.l	(a3)
	beq.b	.new_file
	lea	rawdic_AppendFile(a5),a2
.new_file
	add.l	d0,(a3)
	jmp	(a2)


FileOffset	dc.l	0



; d0.w: disk number
; a0.l: pointer to current disk structure
; a1.l: disk image buffer
; a5.l: RawDIC base

SaveFiles_DOS
	move.l	a1,DiskPtr


	; load rootblock
	move.w	#880,d0
	bsr	LoadSector

	bsr	CheckRootblock
	tst.l	d0
	beq.b	.error

	; rootblock is OK, process files

	; get hash table pointer
	lea	rbl_ht(a0),a2

	moveq	#512/4-56-1,d7	; max. # of entries in hash table
.loop	move.l	(a2)+,d0	; sector
	beq.b	.no_file

.sector_loop
	bsr	LoadSector	; a0: pointer to sector data
	move.l	a0,-(a7)	; save sector data

	bsr	Process_FileName
	tst.l	d0
	beq.b	.invalid_file_name

	; file name is OK, process all sectors
	move.l	(a7),a0
	bsr	Process_File_Sectors


.invalid_file_name



	; process all sector with same hash value
	move.l	(a7)+,a0
	move.l	rbl_next_hash(a0),d0
	bne.b	.sector_loop

.no_file
	dbf	d7,.loop

	; save dummy file so the install script can check if all
	; files have been saved successfully
	bsr	SaveDummyFile



	moveq	#IERR_OK,d0
	rts


.error	moveq	#IERR_CHECKSUM,d0
	rts

.DummyName	dc.b	"Dummy",0
		CNOP	0,2

; ---------------------------------------------------------------------------

; a0.l: pointer to sector data
; ----
; d0.l: result (0: error)

Process_FileName
	lea	512-80(a0),a0	; sector name (first byte: length of name)
	move.b	(a0)+,d0	; length of file name

	; check if file name length is OK

	; must be at least 1 character...
	tst.b	d0
	ble.b	.invalid_file_name

	; ...and not exceed 30 characters
	cmp.b	#30,d0
	bgt.b	.invalid_file_name


	; only copy APB.#? files and file "1" (APB executable)
	cmp.b	#"1",(a0)
	beq.b	.ok
	cmp.l	#"APB.",(a0)
	bne.b	.invalid_file_name
.ok

	; copy file name
	bsr.b	Copy_FileName

	moveq	#1,d0
	rts

.invalid_file_name
	moveq	#0,d0
	rts

; ---------------------------------------------------------------------------
; Copy file name to buffer.
; If the "FileName_Prefix" pointer is not 0 the routine it points to
; will be called. This can be used to add a prefix (for example
; the disk number) before the real file name.

; a0.l: pointer to file name
; d0.b: file name length


Copy_FileName
	lea	FileName(pc),a1

	move.l	FileName_Prefix(pc),d1
	beq.b	.noPrefixRoutine

	movem.l	d0-d7/a0/a2-a6,-(a7)
	move.l	d1,a2
	move.l	a1,a0
	jsr	(a2)
	move.l	a0,a1
	movem.l	(a7)+,d0-d7/a0/a2-a6
.noPrefixRoutine

.copy	move.b	(a0)+,(a1)+
	subq.b	#1,d0
	bne.b	.copy

	; null-terminate file name
	clr.b	(a1)
	rts


FileName_Prefix	dc.l	0

FileName
	ds.b	30+1	; +1: null-termination
	CNOP	0,2	

; ---------------------------------------------------------------------------
; Process all file sectors.

; a0.l: pointer to sector data

Process_File_Sectors

	clr.l	FileOffset

.save	move.l	rbl_firstdata(a0),d0
	beq.b	.done	

	cmp.w	#160*11,d0
	bge.b	.error
	bsr.b	LoadSector

	lea	6*4(a0),a1	; data
	move.l	3*4(a0),d0	; data size

	move.l	File_SaveSector(pc),d1
	beq.b	.no_save_routine
	movem.l	d0-a6,-(a7)
	lea	FileName(pc),a0
	move.l	d1,a2
	jsr	(a2)
	movem.l	(a7)+,d0-a6
.no_save_routine

	bra.b	.save

.error

.done	rts

File_SaveSector	dc.l	0




; ---------------------------------------------------------------------------
; Check if rootblock is valid. 
;
; The bitmap flag and checksum are checked. Also checked is if secondary
; type is ST_ROOT.

; a0.l: pointer to rooblock
; ----
; d0.l: result (0: rootblock is invalid)

CheckRootblock
	moveq	#0,d0		; default: rootblock is invalid

	move.l	a0,a1

	; calculate checksum
	move.l	rbl_checksum(a1),-(a7)
	clr.l	rbl_checksum(a1)
	moveq	#0,d0
	moveq	#512/4-1,d1
.loop	add.l	(a1)+,d0	
	dbf	d1,.loop
	neg.l	d0
	cmp.l	(a7)+,d0
	bne.b	.error

	; check secondary type
	cmp.l	#1,512-4(a0)	; secondary type = ST_ROOT?
	bne.b	.error

	; check if bitmap is valid
	cmp.l	#-1,rbl_bm_flag(a0)
	bne.b	.error

	moveq	#1,d0		; all checks passed, rootblock is OK.

.error	rts

; ---------------------------------------------------------------------------

; d0.w: sector number
; ----
; a0.l: pointer to sector data

LoadSector
	mulu.w	#512,d0
	move.l	d0,a0
	add.l	DiskPtr(pc),a0
	rts


DiskPtr	dc.l	0


; root block format
		RSRESET
rbl_type	rs.l	1		; primary type, 2=T_HEADER
rbl_headerkey	rs.l	1		; unused
rbl_highseq	rs.l	1		; unused
rbl_htsize	rs.l	1		; hash table size (BLOCKSIZE/4)-56
rbl_firstdata	rs.l	1		; unused
rbl_checksum	rs.l	1		; checksum
rbl_ht		rs.l	(512/4)-56	; hash table
rbl_bm_flag	rs.l	1		; bitmap flag, -1 = valid
rbl_bm_pages	rs.l	25		; bitmap blocks pointers
rbl_bm_ext	rs.l	1		; first bitmap extension block (harddisk only)
rbl_r_day	rs.l	1		; last root alteration date, days since 1.1.1978
rbl_r_min	rs.l	1		; minutes past midnight
rbl_r_ticks	rs.l	1		; ticks (1/50 sec) past last minute
rbl_name_len	rs.b	1		; volume name length
rbl_diskname	rs.b	30		; volume name
rbl_unused	rs.b	1		; unused, set to 0
rbl_unused2	rs.l	2		; unused, set to 0
rbl_v_days	rs.l	1		; last disk alt. date, days since 1.1.78
rbl_v_mins	rs.l	1		; minutes past midnight
rbl_v_ticks	rs.l	1		; ticks (1/50 sec) past last minute
rbl_c_days	rs.l	1		; filesystem creation date
rbl_c_mins	rs.l	1		; 
rbl_c_ticks	rs.l	1		;
rbl_next_hash	rs.l	1		; unused (value = 0)
rbl_parent_dir	rs.l	1		; unused (value = 0)
rbl_extentsion	rs.l	1		; FFS: first dircache block, 0 otherwise
rbl_sec_type	rs.l	1		; block secondary type = ST_ROOT (value 1)


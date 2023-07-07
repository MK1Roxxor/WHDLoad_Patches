***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(           PUTTY IMAGER SLAVE               )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            January 2014                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 07-Dec-2014	- once all files have been saved a dummy file is saved,
;		  this is for simple error checking in the install script
;		  (last file is the same for all supported versions)

; 06-Dec-2014	- support for A600 version added (COFFEBAR.BLK is on
;		  disk 3)

; 12-Jan-2014	- added "DPT" and "BAD" extensions that Silly Putty uses
;		- added support for Silly Putty's hidden files

; 08-Jan-2014	- saves hidden files too (except for "COFFEBAR.BLK" on 
;		  disk 2) but is very slow because files are saved
;		  several times
;		- some hours later: saves all files correctly now, file
;		  saving completely redone, new approach is as follows:
;		  all file names are stored in a buffer, all duplicate
;		  names will be removed, then all known extensions are
;		  added (needed because of the hidden files!) and the
;		  files are saved, much faster than the previous version!
;		- finally this is finished, was quite interesting to do
;		  and not too easy!

; 07-Jan-2014	- saves all files now without any need for file names,
;		  everything is done automatically (reading hash table
;		  from root block and saving all files)
;		- uses a big buffer (needs to hold the largest file), I
;		  may change this later (using rawDic_AppendFile caused
;		  problems when I tried it yesterday but that might've been
;		  a bug in my code)
;		- I may extend it later to save all files 
;		  (i.e. directories too etc.) from a normal DOS disk so
;		  it can be used to save files from disks which don't have
;		  the correct protection bits set (old Sierra and Electronic
;		  Arts games for example)

; 06-Jan-2014	- can save files if file name is specified (calculates
;		  hash and saves the file), not really a
;		  good solution though since there are lots of files and
;		  also different versions of the game with different
;		  files but good enough as a test how to save files directly
;		  from disk, never did that before
;		- also tried to make it save all files automatically but
;		  doesn't work correctly yet

; 05-Jan-2014	- work started

BUFSIZE	= 320000		; largest file: 318544


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Putty imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(07.12.2014)",0
	CNOP	0,4


.disk1	dc.l	.disk2		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks		; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

.disk2	dc.l	.disk3		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks2	; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

.disk3	dc.l	0		; Pointer to next disk structure
	dc.w	1		; Disk structure version
	dc.w	0		; Disk flags
	dc.l	.tracks2	; List of tracks which contain data
	dc.l	0		; UNUSED, ALWAYS SET TO 0!
	dc.l	FL_NOFILES	; List of files to be saved
	dc.l	0		; Table of certain tracks with CRC values
	dc.l	0		; Alternative disk structure, if CRC failed
	dc.l	0		; Called before a disk is read
	dc.l	SaveFiles	; Called after a disk has been read

.tracks	TLENTRY	000,000,512*11,SYNC_STD,DMFM_STD
	TLENTRY	001,001,512*11,SYNC_STD,DMFM_NULL
	TLENTRY	002,159,512*11,SYNC_STD,DMFM_STD
	TLEND

.tracks2
	TLENTRY	000,159,512*11,SYNC_STD,DMFM_STD
	TLEND



; d0.w: disk number
; a5.l: rawdic base
SaveFiles
	move.w	d0,d5		; save disk number

	move.w	#880,d0
	bsr	LoadBlock	; load rootblock
	lea	.root(pc),a0
	bsr	CopyBlock

	bsr	CheckRootBlock	; checksum ok?, bitmap valid?
	bne.w	.RootBlockInvalid

	lea	.root(pc),a3
	lea	rbl_ht(a3),a2	; hash table
	lea	Files,a4	; file names
	moveq	#0,d6		; files counter
.do_all	move.l	(a2)+,d0	; first block
	bmi.b	.exit		; bitmap flag reached -> end of hash table!
	beq.b	.do_all


	bsr.w	LoadBlock	; a3: block
	lea	$1b0(a3),a0	; sector name (1. byte: length of name)
	move.b	(a0)+,d0	; length of file name
	move.b	d0,d1
	lea	.name(pc),a1
	moveq	#4,d3		; 4 characters less
.copyname1
	cmp.b	#".",(a0)	; for 8.3 file names do not copy extension
	beq.b	.done
	move.b	(a0)+,(a1)+
	subq.b	#1,d0
	bne.b	.copyname1	
	moveq	#0,d3		; full file name length

.done	sf	(a1)+		; null-terminate


; store file names without duplicates
	lea	Files,a1
	move.w	d6,d7	
.check	lea	.name(pc),a0
	move.b	d1,d0
	sub.b	d3,d0
.cmp	move.b	(a1)+,d2
	beq.b	.notsame
	cmp.b	(a0)+,d2
	bne.b	.notsame
	subq.b	#1,d0
	bne.b	.cmp
	bra.b	.nostore


.notsame

.getnext
	tst.b	(a1)+
	bne.b	.getnext
	
	dbf	d7,.check

	addq.w	#1,d6		; new file
	lea	.name(pc),a0
	bsr.w	.copyname

.nostore
	bra.b	.do_all


; now save all files
; d5.w: disk number
; d6.w: number of files
; a3.l: root block
; a4.l: end of file name table

.exit	lea	Files,a2
	move.w	d6,d7
.enlarge_filetable
	tst.b	8(a2)		; 8+3 name?
	bne.b	.normal

	lea	.ext_FRM(pc),a0
	moveq	#.NUMEXT,d4
	add.w	d4,d6		; add files
.extloop
	move.l	a0,-(a7)
	move.l	a2,a0		; yes, add extensions
	bsr	.copyname
	subq.w	#1,a4
	move.l	(a7)+,a0
	bsr	.copyname
	subq.w	#1,d4
	bne.b	.extloop

.normal

.next_file
	tst.b	(a2)+
	bne.b	.next_file
	subq.w	#1,d7
	bne.b	.enlarge_filetable

	cmp.w	#2,d5
	bne.b	.nospecial
	lea	.special(pc),a0
	bsr.w	.copyname
	addq.w	#1,d6		; 1 new file
.nospecial

	cmp.w	#3,d5
	bne.b	.nospecial2
	lea	.special(pc),a0	; COFFEBAR.BLK a600 version
	bsr.w	.copyname
	lea	.special2(pc),a0
	bsr	.copyname
	lea	.special3(pc),a0
	bsr	.copyname
	addq.w	#3,d6		; 3 new files
.nospecial2

	lea	Files,a4
.saveloop
.no	move.l	a4,a0
	moveq	#-1,d0		; hash
.getlen	addq.l	#1,d0
	tst.b	(a0)+
	bne.b	.getlen

	cmp.w	#8,d0
	beq.w	.nofile

; calc hash
	move.l	a4,a0
	moveq	#0,d1
	move.w	d0,d7
	subq.w	#1,d7
.hashloop
	mulu.w	#13,d0
	move.b	(a0)+,d1
	add.w	d1,d0
	and.w	#$7ff,d0
	dbf	d7,.hashloop
	divu.w	#(512/4)-56,d0
	swap	d0
	addq.w	#6,d0
	lsl.w	#2,d0

	lea	.root(pc),a3
	move.l	(a3,d0.w),d0	; first block
	beq.b	.nofile
	cmp.w	#160*11,d0
	bge.w	.error

.loop	bsr.w	LoadBlock	; a3: block

; compare filename
	lea	$1b0(a3),a0	; sector name (1. byte: length of name)
	move.b	(a0)+,d0
	move.b	d0,d1
	move.l	a4,a1
.compare_name
	cmpm.b	(a0)+,(a1)+
	bne.b	.check_next
	subq.b	#1,d0
	bne.b	.compare_name

	lea	BUF,a6
.load	move.l	4*4(a3),d0	; next block
	beq.b	.file_done
	cmp.w	#160*11,d0
	bge.b	.error
	bsr	LoadBlock
	lea	6*4(a3),a0	; data
	move.l	3*4(a3),d0	; data size
.copy	move.b	(a0)+,(a6)+
	subq.w	#1,d0
	bne.b	.copy
	bra.b	.load

.check_next
	move.l	$1f0(a3),d0
	beq.b	.nofile
	cmp.w	#160*11,d0
	blt.b	.loop

.file_done
	move.l	a4,a0		; file name
	lea	BUF,a1		; data
	move.l	a6,d0
	sub.l	a1,d0		; file size
	jsr	rawdic_SaveFile(a5)		


.nofile

.getnextfile
	tst.b	(a4)+
	bne.b	.getnextfile

	subq.w	#1,d6
	bne.w	.saveloop


	lea	Files,a0
.cls	clr.b	(a0)+
	subq.w	#1,d7
	bne.b	.cls	


; since the supported versions all have different
; files on each disk we save a dummy file so the
; install script can check if everything was saved OK
; (last saved file is the same for all versions)

	cmp.w	#3,d5
	bne.b	.nodummy
	lea	.dummy(pc),a0
	move.l	a0,a1
	moveq	#.dummylen-1,d0
	jsr	rawdic_SaveFile(a5)

.nodummy
	moveq	#IERR_OK,d0
	rts

.dummy	dc.b	"dummy",0
.dummylen	= *-.dummy


.copyname
	move.b	(a0)+,(a4)+
	bne.b	.copyname
	rts

.error
.RootBlockInvalid
	moveq	#IERR_NOSECTOR,d0
	rts

.root	ds.b	512
.name	ds.b	32

.special	dc.b	"COFFEBAR.BLK",0
.special2	dc.b	"TOYT1TO3.BAD",0
.special3	dc.b	"TOYT1TO3.SCR",0
.ext_FRM	dc.b	".FRM",0
.ext_SPR	dc.b	".SPR",0
.ext_DRV	dc.b	".DRV",0
.ext_SFX	dc.b	".SFX",0
.ext_D1M	dc.b	".D1M",0
.ext_BLK	dc.b	".BLK",0
.ext_SEQ	dc.b	".SEQ",0
.ext_SCR	dc.b	".SCR",0
.ext_PRG	dc.b	".PRG",0
.ext_BAD	dc.b	".BAD",0
.ext_DPT	dc.b	".DPT",0
		CNOP	0,2
.NUMEXT	= (*-.ext_FRM)/5



CopyBlock
	movem.l	d7/a0/a3,-(a7)
	moveq	#512/4-1,d7
.loop	move.l	(a3)+,(a0)+
	dbf	d7,.loop
	movem.l	(a7)+,d7/a0/a3
	rts


; a3.l: root block
; ----
; zflg: if set, rootblock is OK!


; checks checksum and bitmap flag in root block

CheckRootBlock
	move.l	rbl_checksum(a3),-(a7)
	clr.l	rbl_checksum(a3)
	moveq	#0,d0
	move.l	a3,a0
	moveq	#512/4-1,d1
.loop	add.l	(a0)+,d0	
	dbf	d1,.loop
	neg.l	d0
	cmp.l	(a7)+,d0
	bne.b	.error
	cmp.l	#-1,rbl_bm_flag(a3)
.error	rts


; d0.w: block
; ----
; a1.l: data
; a3.l: data

LoadBlock
	move.w	d0,d1
	mulu.w	#512,d1		; offset
	divu.w	#$1600,d1	; track
	move.w	d1,d0
	swap	d1		; offset
	move.w	d1,-(a7)
	jsr	rawdic_ReadTrack(a5)
	add.w	(a7)+,a1
	move.l	a1,a3
	rts



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


; file header block format
		RSRESET
fhbl_type	rs.l	1		; primary type, 2=T_HEADER
fhbl_headerkey	rs.l	1		; header key (points to the block itself)
fhbl_blockcount	rs.l	1		; number of entries used in this block list
fhbl_unused	rs.l	1
fhbl_firstdata	rs.l	1		; ptr to first data block
fhbl_checksum	rs.l	1		; block checksum
fhbl_blocks	rs.l	128-56		; list of data block pointers
fhbl_unused2	rs.l	1		; 0
fhbl_unused3	rs.l	1		; 0
fhbl_protect	rs.l	1		; shell and protection flags
fhbl_bytesize	rs.l	1		; total file size in bytes
fhbl_comment	rs.l	(46-24)+1	; comment as BCPL string (max. 79 chars)
fhbl_days	rs.l	1
fhbl_mins	rs.l	1
fhbl_ticks	rs.l	1
fhbl_filename	rs.l	(20-13)+1	; file name as BPCL string (max. 30 chars)
fhbl_unused4	rs.l	1
fhbl_unused5	rs.l	1
fhbl_linkchain	rs.l	1		; ptr to first hard link
fhbl_unused6	rs.l	(9-5)+1		; 
fhbl_hashchain	rs.l	1		; next entry in this hash chain
fhbl_parent	rs.l	1		; parent directory
fhbl_extension	rs.l	1		; ptr to first extension block
fhbl_sec_type	rs.l	1		; secondary type = ST.FILE (-3)

; user directory block format
		RSRESET
udbl_type	rs.l	1		; primary type
udbl_headerkey	rs.l	1		; header key (points to block itself)
ubbl_unused1	rs.l	1
ubbl_unused2	rs.l	1
ubbl_unused3	rs.l	1
udbl_checksum	rs.l	1		; block checksum
ubbl_ht		rs.l	128-56		; hash table
udbl_unused4	rs.l	1
udbl_unused5	rs.l	1
udbl_protect	rs.l	1		; shell and protection flags
udbl_unused6	rs.l	1
udbl_comment	rs.l	(46-24)+1	; comment as BCPL string (max. 79 chars)
udbl_days	rs.l	1
udbl_mins	rs.l	1
udbl_ticks	rs.l	1
udbl_name	rs.l	(20-13)+1	; directory name as BCPL string (max. 30 chars)
udbl_unused7	rs.l	1
udbl_unused8	rs.l	1
udbl_linkchain	rs.l	1		; ptr to first hard link
udbl_unused9	rs.l	(9-5)+1		; 
udbl_hashchain	rs.l	1		; next entry in this hash chain
udbl_parent	rs.l	1		; parent directory
udbl_unused10	rs.l	1
udbl_sec_type	rs.l	1		; secondary type = ST_USERDIR (2)


; extension block format
		RSRESET
exbl_type	rs.l	1		; prinary type T_LIST (16)
exbl_headerkey	rs.l	1		; header key (points to the block itself)
exbl_blockcount	rs.l	1		; number of entries used in this block list
exbl_unused1	rs.l	1
exbl_unused2	rs.l	1
exbl_checksum	rs.l	1		; block checksum
exbl_datablocks	rs.l	128-56		; list of data block pointers
exbl_info	rs.l	(50-5)+1	; unused
exbl_unused3	rs.l	1
exbl_parent	rs.l	1		; ptr to the associated file header
exbl_extension	rs.l	1		; ptr to next extension block
exbl_sec_type	rs.l	1		; secondary type = ST_FILE (-3)


; data block format
		RSRESET
dbl_type	rs.l	1		; primary type T_DATA (8)
dbl_headerkey	rs.l	1		; header key (points to file header)
dbl_seqnum	rs.l	1		; sequence number of the data block
dbl_datasize	rs.l	1		; number of data bytes in this block
dbl_nextdata	rs.l	1		; ptr to next data block
dbl_checksum	rs.l	1		; block checksum
dbl_data	rs.l	128-6

	SECTION	BUF,BSS

Files	ds.b	100*30			; max. 100 files per disk
BUF	ds.b	BUFSIZE

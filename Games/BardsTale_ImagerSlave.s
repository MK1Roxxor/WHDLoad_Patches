***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        BARD'S TALE IMAGER SLAVE            )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            December 2015                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************


; 06-Dec-2015	- work started, adapted from my generic Amiga DOS imager



	INCDIR	SOURCES:INCLUDE/
	INCLUDE	RawDIC.i


	SLAVE_HEADER
	dc.b	1		; Slave version
	dc.b	0		; Slave flags
	dc.l	.disk1		; Pointer to the first disk structure
	dc.l	.text		; Pointer to the text displayed in the imager window


	dc.b	"$VER: "
.text	dc.b	"Bard's Tale imager V1.0",10
	dc.b	"by StingRay/[S]carab^Scoopex "
	dc.b	"(06.12.2015)",0
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
	dc.l	SaveFiles	; Called after a disk has been read


.tracks	TLENTRY	000,159,512*11,SYNC_STD,DMFM_STD
	TLEND



;; d0.w: disk number
;; a5.l: rawdic base
;SaveSpecial
;	move.w	d0,d7		; save disk number
;	
;	lea	.TAB(pc),a4
;	move.l	a4,a3
;
;.loop	movem.w	(a4)+,d0-d3	; disk/start/length/name
;	tst.w	d0
;	beq.b	.done
;
;	cmp.w	d0,d7		; correct disk?
;	bne.b	.next
;
;	mulu.w	#512,d1
;	mulu.w	#512,d2
;	move.l	d1,d0
;	move.l	d2,d1
;	lea	(a3,d3.w),a0	; file name
;	jsr	rawdic_SaveDiskFile(a5)
;
;.next	bra.b	.loop
;
;.done	rts
;
;
;.TAB	dc.w	1			; disk number
;	dc.w	0,$5800/512		; start/length
;	dc.w	.boot-.TAB		; file name
;
;	dc.w	0			; end of table
;
;
;.boot		dc.b	"boot",0

DOSName	dc.b	"dos.library",0
		CNOP	0,2


; d0.w: disk number
; a5.l: rawdic base
SaveFiles
	move.w	d0,d7		; save disk number
	
	lea	DOSName(pc),a1
	move.l	$4.w,a6
	moveq	#0,d0		; any version will do
	jsr	-552(a6)	; OpenLibrary()
	move.l	d0,a6
	tst.l	d0
	beq.w	.noDOS


; load rootblock
	move.w	#880,d0
	bsr	LoadBlock
	lea	ROOTBLOCK,a0
	bsr	CopyBlock

; check it
	bsr	CheckRootBlock	; checksum ok?, bitmap valid?
	bne.w	.RootBlockInvalid

	lea	ROOTBLOCK,a2
	lea	6*4(a2),a2	; hash table


	moveq	#512/4-56-1,d6	; max. # of entries in hash table

.do_all	move.l	(a2)+,d0	; first block
	beq.b	.noentry

.load_loop
	bsr	LoadBlock	; a3: block
	move.l	rbl_next_hash(a3),d5

; copy file name
	lea	512-80(a3),a0	; sector name (1. byte: length of name)
	move.b	(a0)+,d0	; length of file name
	lea	FILENAME,a1
.copyname
	move.b	(a0)+,(a1)+
	subq.b	#1,d0
	bne.b	.copyname	
	sf	(a1)		; null-terminate

	lea	FILENAME,a0	; check if file/directory may need to be
	bsr	CheckName	; excluded from saving
	tst.l	d0
	beq.b	.next

.nonext	cmp.l	#2,512-4(a3)	; secondary type = ST_USERDIR?
	bne.b	.noDir

	movem.l	d0-a6,-(a7)	; yes, save all files in the directory
	bsr.b	SaveDirFiles	; including all sub-directories
	movem.l	(a7)+,d0-a6
	bra.b	.next

.noDir	bsr	SaveBlocks
	tst.l	d0
	bne.b	.error

.next	move.l	d5,d0		; more entries with the same hash value?
	bne.b	.load_loop


.noentry
	dbf	d6,.do_all



.exit	;move.w	d7,d0		; d0: disk number
	;bsr	SaveSpecial	; save "hidden" files stored on disk


; all files have been saved successfully, create a 0-byte
; dummy file so install procedure can check if all files have been
; saved without any errors
	lea	.dummy(pc),a0
	add.b	#"0",d7		; convert disk number to ascii
	move.b	d7,4(a0)
	move.l	a0,a1
	moveq	#0,d0
	jsr	rawdic_SaveFile(a5)



; close DOS library
	move.l	a6,a1		; a1: DOSBase
	move.l	$4.w,a6
	jsr	-414(a6)	; CloseLibrary()

	moveq	#IERR_OK,d0
	rts

.error
.RootBlockInvalid
	moveq	#IERR_NOSECTOR,d0
	rts

.noDOS	lea	.errtxt_DOS(pc),a0
	sub.l	a1,a1
	jmp	rawdic_Print(a5)

.errtxt_DOS	dc.b	"Error opening dos.library!",0
.dummy		dc.b	"Disk0Dummy",0
		CNOP	0,2





	

; a0.l: directory name (null-terminated)
; a3.l: block (ST_USERDIR)
; a6.l: DOS Base

SaveDirFiles
	sub.w	#VAR_SIZEOF,a7	; make room on stack for variables/buffers

; create directory
	move.l	a0,d1
	jsr	-120(a6)	; CreateDir()
.lockok	move.l	d0,DIRLOCK(a7)
	beq.b	.direrror

	move.l	d0,d1
	jsr	-126(a6)	; CurrentDir()
	move.l	d0,DIRLOCK_OLD(a7)


	move.l	a7,a0
	bsr	CopyBlock	; copy directory block

	lea	6*4(a7),a2	; hash table
	moveq	#512/4-56-1,d6	; max. # of entries in hash table
.do_all	move.l	(a2)+,d0	; first block
	beq.b	.next

.load_loop
	bsr	LoadBlock	; a3: block

	lea	512-80(a3),a0	; sector name (1. byte: length of name)
	move.b	(a0)+,d0	; length of file name
	lea	SECNAME(a7),a1
.copyname
	move.b	(a0)+,(a1)+
	subq.b	#1,d0
	bne.b	.copyname	
	sf	(a1)		; null-terminate

	cmp.l	#2,512-4(a3)	; secondary type = ST_USERDIR?
	bne.b	.noDir

	movem.l	d0-a6,-(a7)	; yes, we have a sub-directory!
	lea	SECNAME+15*4(a7),a0
	bsr	SaveDirFiles	; save all files in the sub-directory
	movem.l	(a7)+,d0-a6
	bra.b	.next


.noDir	lea	SECNAME(a7),a0
	bsr	CheckName
	tst.l	d0
	beq.b	.next

	lea	SECNAME(a7),a0
	bsr	SaveBlocks
	tst.l	d0
	bne.b	.error


.next	dbf	d6,.do_all



.out	move.l	DIRLOCK_OLD(a7),d1
	beq.b	.noolddir
	jsr	-126(a6)	; CurrentDir()
.noolddir

	move.l	DIRLOCK(a7),d1
	beq.b	.nonewdir
	jsr	-90(a6)		; Unlock()
.nonewdir
	


.direrror
	add.w	#VAR_SIZEOF,a7
.nosave	rts
	


.error	moveq	#IERR_NOSECTOR,d0
	bra.b	.out


		RSRESET
SECBUF		rs.b	512	; sector buffer
SECNAME		rs.b	30+2	; sector name
DIRLOCK		rs.l	1
DIRLOCK_OLD	rs.l	1
VAR_SIZEOF	rs.b	0



*******************************************
*** EXCLUDE FILES FROM SAVING		***
*******************************************

; checks if a file should be excluded from saving
; this is useful for dummy or protection files which
; often have read errors and are not needed for a game
; to work (protection has to be removed anyway!)


; a0.l: file name
; ----
; d0.l: result, 0: file should be excluded

CheckName
	movem.l	d1-a6,-(a7)
	lea	.TAB(pc),a4
	move.l	a4,a3
	moveq	#1,d0			; default: name is valid
.loop	move.w	(a3)+,d1
	beq.b	.done

	move.l	a0,a2
	lea	(a4,d1.w),a1
.compare
	move.b	(a2)+,d1
	move.b	(a1)+,d2
	beq.b	.same_name

; convert to uppper case
	cmp.b	#"a",d1
	bcs.b	.n1
	cmp.b	#"z",d1
	bhi.b	.n1
	and.b	#~(1<<5),d1
.n1			

; as above
	cmp.b	#"a",d2
	bcs.b	.n2
	cmp.b	#"z",d2
	bhi.b	.n2
	and.b	#~(1<<5),d2
.n2

	cmp.b	d2,d1			
	bne.b	.loop			; names differ, check next entry
	bra.b	.compare

.same_name
	moveq	#0,d0			; file should be excluded!

.done	movem.l	(a7)+,d1-a6
	rts

.TAB	dc.w	.exclude1-.TAB
	dc.w	.exclude2-.TAB
	dc.w	0

.exclude1	dc.b	"sigfile",0	; Bard's Tale protection file
.exclude2	dc.b	"        ",0	; HLS protection file
		CNOP	0,2


*******************************************************************************
*									      *
*			     HELPER ROUTINES				      *
*						      			      *
*******************************************************************************

*******************************************
*** SAVE ALL BLOCKS FOR A FILE		***
*******************************************

; a0.l: file name
; a3.l: block data

SaveBlocks
	move.l	a0,a4		; save file name

.save_file
	move.l	4*4(a3),d0	; next block
	beq.b	.done
	cmp.w	#160*11,d0
	bge.b	.error
	bsr.b	LoadBlock

	move.l	a4,a0
	lea	6*4(a3),a1	; data
	move.l	3*4(a3),d0	; data size
	jsr	rawdic_AppendFile(a5)

	bra.b	.save_file

.done
	
.error	rts


*******************************************
*** LOAD A BLOCK			***
*******************************************

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




*******************************************
*** COPY BLOCK TO BUFFER		***
*******************************************

; copies a block to the destination buffer

; a3.l: block data
; a0.l: destination

CopyBlock
	movem.l	d7/a0/a3,-(a7)
	moveq	#512/4-1,d7
.loop	move.l	(a3)+,(a0)+
	dbf	d7,.loop
	movem.l	(a7)+,d7/a0/a3
	rts


*******************************************
*** CHECK ROOTBLOCK			***
*******************************************

; checks the bitmap flag and checksum for the
; given rootblock, also checks if secondary type
; is ST_ROOT

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
	cmp.l	#1,512-4(a3)		; secondary type = ST_ROOT?
	bne.b	.error
	cmp.l	#-1,rbl_bm_flag(a3)
.error	rts










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



	SECTION	BSS,BSS

ROOTBLOCK	ds.b	512
FILENAME	ds.b	30+2		; +2: null-termination+padding

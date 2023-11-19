;*---------------------------------------------------------------------------
;  :Program.	superhangon.islave.asm
;  :Contents.	Imager for SuperHangOn
;  :Author.	Wepl
;  :Version.	$Id: superhangon.islave.asm 1.1 2006/03/08 16:27:16 wepl Exp wepl $
;  :History.	02.03.06 converted from imager and adpated for 2nd version
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*
;
;	Disk format:
;	Disk 1:		0	standard
;			1	zzkja highscores
;			2	zzkjb loader
;				$1000 bytes sync=4489
;				44894489 2aaa <$1008 odd bits> <$1008 even bits>
;		v1	3-151	$1600 bytes sync=4489
;				44894489 2aaaaaaa aaaaaaaa aaaaaaaa aaaaaaaa
;				44894489 2aaa <$1608 odd bits> <$1608 even bits>
;					xxxxxxxx cylinder number
;					$1600 byte data
;					xxxxxxxx checksum
;		v2	3-151	$1600 bytes sync=4489
;				44894489 2aaaaaaa ..unformatted (7-9 byte).. aaaaaaaa
;				44894489 2aaa <$1608 odd bits> <$1608 even bits>
;					xxxxxxxx cylinder number
;					$1600 byte data
;					xxxxxxxx checksum
;				...
;
;			152-159	unused
;
;	the sync must be not more than $160 bytes after the index signal!!!
;
;	Image format:
;	Disk 1		tracks 4-150 even tracks
;			       3-151 odd tracks
;
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	RawDic.i

	IFD BARFLY
	OUTPUT	"Develop:Installs/SuperHangOn Install/SuperHangOn.ISlave"
	BOPT	O+			;enable optimizing
	BOPT	OG+			;enable optimizing
	BOPT	ODd-			;disable mul optimizing
	BOPT	ODe-			;disable mul optimizing
	ENDC

;============================================================================

	SECTION a,CODE

		SLAVE_HEADER
		dc.b	1		; Slave version
		dc.b	0		; Slave flags
		dc.l	_disk1v1	; Pointer to the first disk structure
		dc.l	_text		; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
_text		dc.b	"Super·Hang·On Imager",10
		dc.b	"Done by Wepl, Version 1.1 "
	DOSCMD	"WDate >T:date"
	INCBIN	"T:date"
		dc.b	".",0
	EVEN

;============================================================================

_disk1v1	dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_DOUBLEINC	; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	.fl		; List of files to be saved
		dc.l	.crc		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

.tl		TLENTRY	0,0,$1600,SYNC_STD,DMFM_STD
	;	TLENTRY 2,2,$800,$4489,_decode_a
		TLENTRY 4,150,$1600,$4489,_decode_c
		TLENTRY 3,149,$1600,$4489,_decode_c
		TLEND

.fl		FLENTRY	FL_DISKIMAGE,$1600,$1600*148
		FLEND

.crc		CRCENTRY 0,$5db6
		CRCEND

	;d0=tracknum a0=mfm a1=buffer a5=rawdic
_decode_c	move.l	d0,d3
		lsr.l	#1,d3			;D3 = cylnum
		scs	d6			;D6 = head
		move.l	#$55555555,d5		;D5 = 55555555

		cmp.w	#$2aaa,(a0)+
		bne	.nosync
		cmp.l	#$aaaaaaaa,(a0)+
		bne	.v2
		cmp.l	#$aaaaaaaa,(a0)+
		bne	.v2
		cmp.l	#$aaaaaaaa,(a0)+
		bne	.v2
		cmp.l	#$aaaa4489,(a0)+
		bne	.v2
		cmp.l	#$44892aaa,(a0)+
		bne	.v2

.decode		lea	($1608,a0),a2

		move.l	(a0)+,d4
		move.l	(a2)+,d2
		and.l	d5,d4
		and.l	d5,d2
		add.l	d2,d2
		or.l	d2,d4
		cmp.l	d3,d4
		bne	.error
		
		move.w	#$1600/4-1,d7

.loop		move.l	(a0)+,d1
		move.l	(a2)+,d2
		and.l	d5,d1
		and.l	d5,d2
		add.l	d2,d2
		or.l	d2,d1
		move.l	d1,(a1)+
		add.l	d1,d4
		dbf	d7,.loop

		move.l	(a0)+,d1
		move.l	(a2)+,d2
		and.l	d5,d1
		and.l	d5,d2
		add.l	d2,d2
		or.l	d2,d1
		cmp.l	d1,d4
		bne	.error
		
		moveq	#IERR_OK,d0
		rts

.error		moveq	#IERR_CHECKSUM,d0
		rts

.nosync		moveq	#IERR_NOSYNC,d0
		rts

.v2		jsr	(rawdic_NextSync,a5)
		cmp.l	#IERR_OK,d0
		bne	.nosync

		cmp.w	#$2aaa,(a0)+
		bne	.nosync

		tst.b	d6		;only one side in encoded
		bne	.decode

		move.l	#$12345678,d6

		lea	($1608,a0),a2

		move.l	(a0)+,d4
		move.l	(a2)+,d2
		and.l	d5,d4
		and.l	d5,d2
		add.l	d2,d2
		or.l	d2,d4
		cmp.l	d3,d4
		bne	.error

		move.w	#$1600/4-1,d7

.loop2		move.l	(a0)+,d1
		move.l	(a2)+,d2
		and.l	d5,d1
		and.l	d5,d2
		add.l	d2,d2
		or.l	d2,d1
		eor.l	d6,d1
		move.l	d1,d6
		move.l	d1,(a1)+
		add.l	d1,d4
		dbf	d7,.loop2

		move.l	(a0)+,d1
		move.l	(a2)+,d2
		and.l	d5,d1
		and.l	d5,d2
		add.l	d2,d2
		or.l	d2,d1
		eor.l	d6,d1
		cmp.l	d1,d4
		bne	.error

		moveq	#IERR_OK,d0
		rts

;============================================================================

	END

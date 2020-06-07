		incdir	Include:
		include	RawDIC.i

		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
Text:		dc.b	"Escape From Colditz imager",10
		dc.b	"V1.0 by Bored Seal (10-Jan-2002)",0
		cnop	0,4

DSK_1:		dc.l	0
		dc.w	1		; disk structure version
		dc.w	DFLG_NORESTRICTIONS
		dc.l	TL_1		; list of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_NOFILES
		dc.l	0		; table of certain tracks with CRC values
		dc.l	0		; alternative disk structure, if CRC failed
		dc.l	0
		dc.l	Extract

TL_1:		TLENTRY	0,0,$1600,$4489,DMFM_STD
		TLENTRY	1,1,$17c0+$1c0,$4489,DMFM_NULL
		TLENTRY	2,148,$17c0,$4489,Decoder
		TLEND

Extract		moveq	#4,d0
		jsr	rawdic_ReadTrack(a5)	; read track containing directory

		move.l	a1,a2			;save pointer

fileloop	move.l	a2,a1
		lea	2(a1),a1		;skip 2 bytes

		moveq	#0,d0
		move.b	(a1)+,d0		;offset
		mulu.w	#$17c0,d0

		moveq	#0,d1
		move.b	(a1)+,d1		;lenght in tracks = useless

		moveq	#0,d2
		move.w	(a1)+,d2		;real start of file
		add.l	d2,d0			;now, real offset is done

		move.l	(a1)+,d1		;real file size
		tst.l	d1			;is there a file ?
		beq	EndOfDisk

		lea	4(a1),a1		;skip 'DF1:' string
		move.l	a1,a0			;filename

		cmp.l	#'TEXT',$10(a1)		;wrong filename?
		bne	skip
		lea	fixedname,a0
skip		jsr	rawdic_SaveDiskFile(a5)

		lea	$20(a2),a2		;next file
		bra	fileloop

EndOfDisk	moveq	#IERR_OK,d0
		rts


Decoder		move.l	a0,a2
		move.l	a1,a5
		move.l	#$55555555,d5

		MOVE.W	#$4489,D1
		CMP.W	(A2)+,D1
		BEQ.B	SyncFound
		SUBQ.W	#2,A2
SyncFound	CMP.W	(A2)+,D1
		BEQ.B	SkipSync
		SUBQ.W	#2,A2
SkipSync	LEA	(0,A2),A0
		BSR.B	CalcLong		;calc track number
		LEA	(8,A2),A0
		BSR.B	CalcLong		;calc checksum
		MOVE.L	D0,D7
		LEA	($10,A2),A0
		BSR.B	Checksum
		AND.L	D5,D0
		CMP.L	D0,D7
		BNE.B	Error
		LEA	($10,A2),A1
		LEA	($17C0,A1),A3
		MOVE.W	#$5EF,D2
dec_loop	MOVE.L	(A1)+,D0
		MOVE.L	(A3)+,D1
		AND.L	D5,D0
		AND.L	D5,D1
		ADD.L	D0,D0
		OR.L	D1,D0
		MOVE.L	D0,(A5)+
		DBRA	D2,dec_loop
		MOVEQ	#0,D0
		RTS

CalcLong	MOVE.L	(A0)+,D0
		MOVE.L	(A0)+,D1
		AND.L	D5,D0
		AND.L	D5,D1
		ADD.L	D0,D0
		OR.L	D1,D0
		RTS

Checksum	MOVE.W	#$BDF,D2
		CLR.L	D0
chk_loop	MOVE.L	(A0)+,D1
		EOR.L	D1,D0
		DBRA	D2,chk_loop
		AND.L	D5,D0
		RTS

Error		moveq	#-1,d0
		rts

fixedname	dc.b	"PIC.B(GAME-OVER)TEXT",0
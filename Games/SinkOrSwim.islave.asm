; 30.12.2022, StingRay
; - imager saves all files

		incdir	SOURCES:Include/
		include	RawDIC.i

		SLAVE_HEADER
		dc.b	1	; Slave version
		dc.b	0
		dc.l	DSK_1	; Pointer to the first disk structure
		dc.l	Text	; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
Text:		dc.b	"Sink or Swim imager V1.1",10
		dc.b	"by Bored Seal & StingRay (30.12.2022)",0
		cnop	0,4

DSK_1:		dc.l	DSK_2
		dc.w	1
		dc.w	DFLG_DOUBLEINC|DFLG_NORESTRICTIONS
		dc.l	TL_1			;tracklist for disk1
		dc.l	0
		dc.l	FL_NOFILES
		dc.l	0
		dc.l	0
		dc.l	0
		dc.l	Save_Files

DSK_2:		dc.l	0
		dc.w	1
		dc.w	DFLG_DOUBLEINC|DFLG_NORESTRICTIONS
		dc.l	TL_2			;tracklist for disk2
		dc.l	0
		dc.l	FL_NOFILES
		dc.l	0
		dc.l	0
		dc.l	0
		dc.l	Save_Files

TL_1:		;TLENTRY	0,0,$1600,$4489,DMFM_STD
		;TLENTRY	0,0,$200,SYNC_INDEX,DMFM_NULL
		TLENTRY	3,159,$1800,$8914,Decoder
		TLENTRY	2,52,$1800,$8914,Decoder
		TLEND

TL_2:		;TLENTRY	0,0,$1800,SYNC_INDEX,DMFM_NULL
		TLENTRY	3,159,$1800,$8914,Decoder
		TLENTRY	2,142,$1800,$8914,Decoder
		TLEND

Decoder		lea	8(a0),a0
		exg.l	a0,a1
		MOVE.W	#$5ff,D0
DC_loop		MOVE.L	(A1)+,D1
		ANDI.L	#$55555555,D1
		LSL.L	#1,D1
		ANDI.L	#$55555555,(A1)
		OR.L	(A1)+,D1
		MOVE.L	D1,(A0)+
		DBRA	D0,DC_loop
		moveq	#0,d0
		rts

Save_Files
	moveq	#3,d0
	jsr	rawdic_ReadTrack(a5)
	move.l	a1,a4
.save_all_files
	lea	File_Name(pc),a0
	move.l	(a4)+,(a0)
	move.l	(a4)+,d1			; length
	move.w	(a4)+,d2			; side
	move.w	(a4)+,d0			; track
	subq.w	#1,d0
	tst.w	d2
	beq.b	.side_ok
	add.w	#79,d0
.side_ok
	mulu.w	#$1800,d0
	jsr	rawdic_SaveDiskFile(a5)

	addq.w	#4,a4
	tst.l	(a4)
	bne.b	.save_all_files
	moveq	#IERR_OK,d0
	rts


File_Name	ds.b	4+1			; +1 for null termination

		


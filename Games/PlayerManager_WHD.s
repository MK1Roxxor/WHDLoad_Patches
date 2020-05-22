***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        PLAYER MANAGER WHDLOAD SLAVE        )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              March 2009                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 12-Mar-2020	- found the reason for the "substitute player" problem
;		  shortly after I wrote the history  text yesterday, it
;		  was caused by missing game code modifications which were
;		  done after decrypting, apparently either some sort of
;		  additional protection or this version had debug stuff
;		  left
;		- code cleaned up

; 11-Mar-2020	- tried to fix the annoying "substitute player" problem
;		  in the German V2 version, no success...
;		- copperlist problem fixed in a way that no binary patches
;		  are needed
;		- data disks weren't created when the German V2 version was
;		  detected due to the different code to handle that version
;		  of the game, code to create the data disks moved to the
;		  beginning of the patch
;		- memory clearing removed, WHDLF_ClearMem used now


; 10-Mar-2020	- support for another German version added (sent by
;		  Christoph Gleisberg)

; 25-Aug-2014	- support for another french version (sent by lolafg) added

; 31-Jan-2012	- source can be assembled case sensitive
;		- size optimised the code a bit, d4 is not needed
;		  for the decrypter
;		- support for french version finally finished
;		  (started it back in January 2010), thanks to Xavier
;		  Bodénand for the disk image

; 23-Mar-2009	- work started
;		- patch worked at first try, how boring :)


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
DEBUGKEY	= $58		; F9
QUITKEY		= $46		; DEL
DEBUG

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM


HEADER	SLAVE_HEADER		; ws_security + ws_ID
	dc.w	10		; ws_version
	dc.w	FLAGS		; flags
	dc.l	524288		; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	IFD	DEBUG
	dc.w	.dir-HEADER	; ws_CurrentDir
	ELSE
	dc.w	0		; ws_CurrentDir
	ENDC
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_KeyDebug
	dc.b	QUITKEY		; ws_KeyExit
	dc.l	0		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info


	IFD	DEBUG
.dir	dc.b	"SOURCES:WHD_Slaves/PlayerManager/",0
	ENDC
.name	dc.b	"Player Manager",0
.copy	dc.b	"1990 Anco",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	dc.b	"Version 1.03 (12.03.2020)",0
	CNOP	0,2

TAGLIST		dc.l	WHDLTAG_CUSTOM1_GET
NODATADISK	dc.l	0		; disable creation of data disk

		dc.l	TAG_END

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)



	move.l	NODATADISK(pc),d0
	bne.b	.nodatadisk
	bsr	CreateDataDisk		; create data disk if it doesn't exist
.nodatadisk



	; fix copperlist problems
	moveq	#-2,d0
	move.l	d0,$0.w


; load boot
	moveq	#0,d0
	move.l	#1024,d1
	moveq	#1,d2
	lea	$75000,a5
	move.l	a5,a0
	jsr	resload_DiskLoad(a2)

; version check
	move.l	a5,a0
	move.l	#1024,d0
	jsr	resload_CRC16(a2)
	lea	PL_BOOT(pc),a0
	cmp.w	#$4419,d0		; SPS 0171
	beq.b	.ok
	lea	PL_MOD(pc),a0
	cmp.w	#$ADB7,d0		; modified version
	beq.b	.ok
	lea	PL_BOOTITA(pc),a0
	cmp.w	#$1ae3,d0		; italian version, SPS 2572
	beq.b	.ok
	lea	PL_BOOTGER(pc),a0
	cmp.w	#$8ac6,d0		; german version, SPS 2772
	beq.b	.ok
	lea	PL_BOOTFR(pc),a0	; french version
	cmp.w	#$fac7,d0
	beq.b	.ok

	cmp.w	#$93f5,d0		; german version V2
	beq.w	PatchGermanV2		; (different to the other bootblocks)



; unknown version
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT

.ok


; patch it
	move.l	a5,a1
	jsr	resload_Patch(a2)
	
; load crypted main file
	move.l	#$1600,d0
	move.l	#$22400,d1
	moveq	#1,d2
	lea	$30000,a0
	jsr	resload_DiskLoad(a2)


	jmp	$76(a5)




QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	jmp	resload_Abort(a2)


*******************************************
*** GERMAN VERSION, V2			***
*******************************************

; This must either be a late or very early version of the game
; (I suspect the former). The bootblock is different to all
; other version, the Cobra X-ROM encryption uses a table with
; 64 keys instead of 32 and there are also "hidden" modifications
; done to the game code after decryption has been finished.


PatchGermanV2
	move.l	#$1600,d0
	move.l	#$1cc00,d1
	moveq	#1,d2
	lea	$5f00.w,a0
	move.l	a0,a5
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)


	move.w	#$a995,d3
	lea	$7092.w,a0
	lea	$22922,a1
	move.l	a5,a2
.outer	lea	.TAB(pc),a3
	moveq	#64-1,d0
.loop	cmp.l	a0,a1
	beq.b	.end
	add.w	a2,d3
	move.w	(a0)+,d1
	sub.w	d3,d1
	sub.w	(a3)+,d1

	move.w	d1,(a2)+

	dbf	d0,.loop
	bra.b	.outer
.end

	lea	PL_GAMEGERV2(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)


	lea	$80000,a7
	lea	-$400(a7),a0
	jmp	(a5)




.TAB	DC.W	$E8EB,$57AB,$5C21,$2DD7,$9C88,$FAA6,$C8C8,$4E8A
	DC.W	$085F,$FFD3,$17FE,$05EC,$E183,$1371,$B2CC,$5ED1
	DC.W	$8D79,$35BE,$5E9C,$9414,$C9E6,$223F,$CAC3,$51AE
	DC.W	$1790,$610E,$ABA8,$A2B7,$14C4,$881E,$21F4,$3089

	DC.W	$FA44,$68A5,$0F64,$CE34,$D9D8,$8165,$1B41,$F724
	DC.W	$C11C,$CDFC,$6D02,$F925,$21F6,$3E92,$A8BE,$B9DC
	DC.W	$FE40,$3D70,$3583,$4760,$0779,$54AA,$4C3C,$152E
	DC.W	$46B0,$7912,$30A5,$3A1F,$C6F3,$86AE,$6250,$6CF0




PL_GAMEGERV2
	PL_START

; disable disk checks
	PL_SA	$2a0,$42e
	PL_SA	$5be,$74c
	PL_SA	$238c,$251a
	PL_SA	$274a,$28d8

; disable checksum checks
	PL_B	$2b08,$60
	PL_B	$72da,$60
	PL_B	$110e8,$60
	PL_L	$49e2,$4e714e71
	PL_L	$7eb2,$4e714e71
	PL_B	$485a,$60
	PL_B	$c280,$60
	PL_B	$35b2,$60
	PL_B	$7082,$60
	PL_B	$f246,$60
	PL_L	$5b7e,$4e714e71
	PL_L	$8120,$4e714e71

; patch loader/disk change
	PL_P	$119b6,LOADER
	PL_W	$12054,$4e71
	PL_W	$12088,$4e71
	PL_W	$120bc,$4e71
	PL_W	$1211a,$4e71

	PL_PSS	$8598,.changedisk,2

; $150: data disk
; $151: formatted disk
; $160: program disk


; disable "insert disk" requesters
	PL_S	$542,6
	PL_S	$55c,6
	PL_S	$822,6
	PL_S	$f8a,6
	PL_S	$25f0,6
	PL_S	$29ae,6
	PL_S	$1110e,6

	PL_S	$a7e,6
	PL_S	$aba,6
	PL_S	$af6,6
	PL_S	$43f2,6
	PL_S	$442e,6
	PL_S	$5e78,6
	PL_S	$5eb4,6
	PL_S	$7f8a,6
	PL_S	$7fc6,6

	PL_S	$590,6
	PL_S	$235e,6
	PL_S	$271c,6
	

	PL_PSS	$13064,AckVBI,2	

; enable quit on 68000 machines
	PL_PS	$13220,.key


; fix invalid copperlist entry
;	PL_PS	$E196,.cop
;	PL_PS	$e2e8,.cop2



; original patches (code at end of binary, offset $1dbb4)
	PL_R	$1028a
	PL_R	$cfe
	PL_R	$cf10
	PL_R	$973a
	PL_R	$f5fe
	PL_END

; decruncher: $8486


.changedisk
	lea	-$1c6c(a4),a2
	bra.w	DiskChange

.key	move.b	$5f00+$1b84c,d1
	bra.w	Keys


;.cop	move.l	#$5f00+$176e4,$dff084
;	move.w	#$8380,$dff096
;	rts

;.cop2	move.l	#$5f00+$176c0,$dff084
;	move.w	#$8380,$dff096
;	rts


AckVBI	move.w	#1<<5,$dff09c
	move.w	#1<<5,$dff09c
	rts


*******************************************
*** ENGLISH VERSION 	(SPS 171)	***
*******************************************

PL_BOOT	PL_START
	PL_P	$E2,.patch
	PL_END


.patch	movem.l	d0-a6,-(a7)
	lea	$5f00.w,a0	; start
	lea	$22258,a1	; end
	lea	.TAB(pc),a4
	move.w	#$38c6,d3
	lea	PL_GAME(pc),a5
	bsr	DecryptAndPatch
	movem.l	(a7)+,d0-a6
	jmp	$5f00.w

.TAB	DC.W	$970D,$2D06,$D1D6,$9CF9,$1D9F,$F533,$B256,$2F3E
	DC.W	$583C,$446E,$52C0,$790B,$AB2A,$D2D6,$CD46,$907E
	DC.W	$27CC,$5761,$8733,$DC9C,$CC34,$B5D8,$8CB9,$4185
	DC.W	$3519,$1E4F,$F4CB,$8F48,$F4CA,$65B6,$84A4,$A607


PL_GAME	PL_START

; disable disk checks
	PL_S	$2d0,$3a6-$2d0
	PL_S	$644,$71a-$644
	PL_S	$23be,$2494-$23be
	PL_S	$277c,$2852-$277c
	

; disable checksum checks
	PL_B	$35d4,$60
	PL_B	$72a2,$60
	PL_B	$f1f8,$60
	PL_L	$690e,$4e714e71
	PL_B	$4a02,$60
	PL_B	$7e66,$60
	PL_B	$489c,$60
	PL_B	$7046,$60
	PL_B	$110c0,$60
	PL_L	$2b3a,$4e714e71
	PL_L	$80e6,$4e714e71
	PL_L	$C272,$4e714e71
	

; patch loader/disk change
	PL_P	$11962,LOADER
	PL_W	$12000,$4e71
	PL_W	$12034,$4e71
	PL_W	$12068,$4e71
	PL_W	$120c6,$4e71

	PL_PS	$858a,.changedisk
	PL_W	$858a+6,$4e71
	

; disable "insert disk" requesters
	PL_S	$588,6			; "insert data disk"
	PL_S	$5a2,6			; "insert data disk"
	PL_S	$8a8,6			; "insert data disk"
	PL_S	$2622,6			; "insert data disk"
	PL_S	$29e0,6			; "insert data disk"
	
	PL_S	$b00,6			; "insert formatted disk"
	PL_S	$b3c,6			; "insert formatted disk"
	PL_S	$b78,6			; "insert formatted disk"
	PL_S	$4424,6			; "insert formatted disk"
	PL_S	$4460,6			; "insert formatted disk"
	PL_S	$5e2c,6			; "insert formatted disk"
	PL_S	$5e68,6			; "insert formatted disk"
	PL_S	$7f50,6			; "insert formatted disk"
	PL_S	$7f8c,6			; "insert formatted disk"

	PL_S	$5e4,6			; "insert program disk"
	PL_S	$616,6			; "insert program disk"
	PL_S	$2390,6			; "insert program disk"
	PL_S	$274e,6			; "insert program disk"


; fix invalid copperlist entry
	PL_PS	$E188,.cop

; enable quit on 68000 machines
	PL_PS	$131d0,.key
	PL_END



.changedisk
	lea	$5f00+$1a2dc,a2
	bra.w	DiskChange

.cop	move.l	#$5f00+$173e8,$dff084
	move.w	#$8380,$dff096
	rts


.key	move.b	$5f00+$1c314,d1
	bra.w	Keys


*******************************************
*** ITALIAN VERSION 	(SPS 2572)	***
*******************************************

PL_BOOTITA
	PL_START
	PL_P	$E2,.patch
	PL_END


.patch	movem.l	d0-a6,-(a7)
	lea	$5f00.w,a0	; start
	lea	$2260a,a1	; end
	lea	.TAB(pc),a4
	move.w	#$38c6,d3
	lea	PL_GAME(pc),a5	; same offsets as SPS 0171
	bsr	DecryptAndPatch

	lea	PL_GAMEITA(pc),a0
	lea	$5f00.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	movem.l	(a7)+,d0-a6
	jmp	$5f00.w

.TAB	DC.W	$970D,$2D06,$D1D6,$9CF9,$1D9F,$F533,$B256,$2F3E
	DC.W	$583C,$446E,$52C0,$790B,$AB2A,$D2D6,$CD46,$907E
	DC.W	$27CC,$5761,$8733,$DC9C,$CC34,$B5D8,$8CB9,$4185
	DC.W	$3519,$1E4F,$F4CB,$8F48,$F4CA,$65B6,$84A4,$A607


PL_GAMEITA
	PL_START


	PL_PS	$858a,.changedisk
	PL_W	$858a+6,$4e71

; fix invalid copperlist entry
	PL_PS	$E188,.cop

; enable quit on 68000 machines
	PL_PS	$131d0,.key
	PL_END



.changedisk
	lea	$5f00+$1a68e,a2
	bra.w	DiskChange

.cop	move.l	#$5f00+$1779a,$dff084
	move.w	#$8380,$dff096
	rts


.key	move.b	$225c6,d1
	bra.w	Keys



*******************************************
*** GERMAN VERSION 	(SPS 2772)	***
*******************************************

PL_BOOTGER
	PL_START
	PL_P	$E2,.patch
	PL_END


.patch	movem.l	d0-a6,-(a7)
	lea	$5f00.w,a0	; start
	lea	$2250e,a1	; end
	lea	.TAB(pc),a4
	move.w	#$38c6,d3
	lea	PL_GAME(pc),a5	; same offsets as SPS 0171
	bsr	DecryptAndPatch

	lea	PL_GAMEGER(pc),a0
	lea	$5f00.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	movem.l	(a7)+,d0-a6
	jmp	$5f00.w

.TAB	DC.W	$970D,$2D06,$D1D6,$9CF9,$1D9F,$F533,$B256,$2F3E
	DC.W	$583C,$446E,$52C0,$790B,$AB2A,$D2D6,$CD46,$907E
	DC.W	$27CC,$5761,$8733,$DC9C,$CC34,$B5D8,$8CB9,$4185
	DC.W	$3519,$1E4F,$F4CB,$8F48,$F4CA,$65B6,$84A4,$A607


PL_GAMEGER
	PL_START


	PL_PS	$858a,.changedisk
	PL_W	$858a+6,$4e71

; fix invalid copperlist entry
	PL_PS	$E188,.cop

; enable quit on 68000 machines
	PL_PS	$131d0,.key
	PL_END



.changedisk
	lea	$5f00+$1a592,a2
	bra.w	DiskChange

.cop	move.l	#$5f00+$1769e,$dff084
	move.w	#$8380,$dff096
	rts


.key	move.b	$5f00+$1c5ca,d1
	bra.w	Keys



*******************************************
*** MODIFIED ENGLISH VERSION 		***
*******************************************

PL_MOD	PL_START
	PL_P	$E2,.patch
	PL_END


.patch	movem.l	d0-a6,-(a7)
	lea	PL_GAMEMOD(pc),a0
	lea	$5f00.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	jmp	$5f00.w


PL_GAMEMOD
	PL_START

; patch loader/disk change
	PL_P	$11962+$54,LOADER
	PL_W	$12054,$4e71
	PL_W	$12088,$4e71
	PL_W	$120bc,$4e71
	PL_W	$1211a,$4e71

	PL_PS	$8598,.changedisk
	PL_W	$8598+6,$4e71
	

; disable "insert disk" requesters
	PL_S	$542,6			; "insert data disk"
	PL_S	$55c,6			; "insert data disk"
	PL_S	$822,6			; "insert data disk"
	PL_S	$f8a,6			; "insert data disk"
	PL_S	$25f0,6			; "insert data disk"
	PL_S	$1110e,6		; "insert data disk"

	
	PL_S	$a7e,6			; "insert formatted disk"
	PL_S	$aba,6			; "insert formatted disk"
	PL_S	$af6,6			; "insert formatted disk"
	PL_S	$43f2,6			; "insert formatted disk"
	PL_S	$442e,6			; "insert formatted disk"
	PL_S	$5e78,6			; "insert formatted disk"
	PL_S	$5eb4,6			; "insert formatted disk"
	PL_S	$7f8a,6			; "insert formatted disk"
	PL_S	$7fc6,6			; "insert formatted disk"

	PL_S	$590,6			; "insert program disk"
	PL_S	$235e,6			; "insert program disk"
	PL_S	$271c,6			; "insert program disk"


; fix invalid copperlist entry
	PL_PS	$E188,.cop

; enable quit on 68000 machines
	PL_PS	$13220,.key
	PL_END



.changedisk
	lea	$5f00+$1955c,a2
	bra.w	DiskChange

.cop	move.l	#$5f00+$173e8,$dff084
	move.w	#$8380,$dff096
	rts


.key	move.b	$5f00+$1b594,d1
	bra.w	Keys



*******************************************
*** FRENCH VERSION			***
*******************************************

PL_BOOTFR
	PL_START
	PL_P	$E2,.patch
	PL_END


.patch	movem.l	d0-a6,-(a7)

; since there are different french versions we have
; to check the CRC of the main file
	lea	$5f00,a0
	move.l	#256,d0
	move.l	resload(pc),a2
	jsr	resload_CRC16(a2)
	cmp.w	#$5490,d0
	beq.w	french_v2

	lea	$5f00.w,a0	; start
	lea	$22544,a1	; end
	lea	.TAB(pc),a4
	move.w	#$f4ca,d3
	lea	PL_GAMEFR(pc),a5

; french version uses different decrypter
.outer	move.l	a4,a3
	moveq	#32-1,d0
.loop	cmp.l	a0,a1
	beq.b	.done
	add.w	a0,d3
	move.w	(a0),d1
	eor.w	d3,d1
	add.w	(a3)+,d1
	move.w	d1,(a0)+
	dbf	d0,.loop
	bra.b	.outer

.done	move.l	a5,a0
	lea	$5f00.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	jmp	$5f00.w

.TAB	DC.W	$D6B2,$DB99,$8B12,$985A,$970D,$2D06,$D1D6,$9CF9
	DC.W	$1D9F,$F533,$B256,$2F3E,$583C,$446E,$52C0,$790B
	DC.W	$AB2A,$D2D6,$CD46,$907E,$27CC,$5761,$8733,$DC9C
	DC.W	$CC34,$B5D8,$8CB9,$4185,$3519,$1E4F,$F4CB,$8F48


PL_GAMEFR
	PL_START

; disable disk checks
	PL_S	$2d0,$3a2-$2d0
	PL_S	$644,$716-$644
	PL_S	$23be,$2490-$23be
	PL_S	$277c,$284e-$277c

; disable checksum checks
	PL_B	$35d2,$60
	PL_B	$72a0,$60
	PL_B	$f1f8,$60
	PL_L	$690e,$4e714e71
	PL_B	$4a02,$60
	PL_B	$7e66,$60
	PL_B	$488e,$60
	PL_B	$7046,$60
	PL_L	$110b0,$4e714e71
	PL_B	$2b4a,$60
	PL_B	$80e8,$60
	PL_B	$C282,$60

; patch loader/disk change
	PL_P	$11962,LOADER
	PL_W	$12000,$4e71
	PL_W	$12034,$4e71
	PL_W	$12068,$4e71
	PL_W	$120c6,$4e71

	PL_PS	$858a,.changedisk
	PL_W	$858a+6,$4e71
	
; disable "insert disk" requesters
	PL_S	$588,6			; "insert data disk"
	PL_S	$5a2,6			; "insert data disk"
	PL_S	$8a8,6			; "insert data disk"
	PL_S	$2622,6			; "insert data disk"
	PL_S	$29e0,6			; "insert data disk"
	
	PL_S	$b00,6			; "insert formatted disk"
	PL_S	$b3c,6			; "insert formatted disk"
	PL_S	$b78,6			; "insert formatted disk"
	PL_S	$4424,6			; "insert formatted disk"
	PL_S	$4460,6			; "insert formatted disk"
	PL_S	$5e2c,6			; "insert formatted disk"
	PL_S	$5e68,6			; "insert formatted disk"
	PL_S	$7f50,6			; "insert formatted disk"
	PL_S	$7f8c,6			; "insert formatted disk"

	PL_S	$5e4,6			; "insert program disk"
	PL_S	$616,6			; "insert program disk"
	PL_S	$2390,6			; "insert program disk"
	PL_S	$274e,6			; "insert program disk"


; fix invalid copperlist entry
	PL_PS	$E188,.cop

; enable quit on 68000 machines
	PL_PS	$131d0,.key
	PL_END

.changedisk
	lea	$5f00+$1a5c8,a2
	bra.w	DiskChange

.cop	move.l	#$5f00+$176d2,$dff084
	move.w	#$8380,$dff096
	rts


.key	move.b	$22502-2,d1		; -2 because of .l
	bra.w	Keys


*******************************************
*** FRENCH VERSION V2			***
*******************************************

; french version 2 uses "standard" decrypter
french_v2
	lea	$5f00.w,a0	; start
	lea	$22544,a1	; end
	lea	.TAB(pc),a4
	move.w	#$38c6,d3
	lea	PL_GAMEFR2(pc),a5
	bsr	DecryptAndPatch
	movem.l	(a7)+,d0-a6
	jmp	$5f00.w


.TAB	DC.W	$970D,$2D06,$D1D6,$9CF9,$1D9F,$F533,$B256,$2F3E
	DC.W	$583C,$446E,$52C0,$790B,$AB2A,$D2D6,$CD46,$907E
	DC.W	$27CC,$5761,$8733,$DC9C,$CC34,$B5D8,$8CB9,$4185
	DC.W	$3519,$1E4F,$F4CB,$8F48,$F4CA,$65B6,$84A4,$A607

PL_GAMEFR2
	PL_START

; disable disk checks
	PL_S	$2d0,$3a6-$2d0
	PL_S	$644,$71a-$644
	PL_S	$23be,$2494-$23be
	PL_S	$277c,$2852-$277c

; disable checksum checks
	PL_B	$35d4,$60
	PL_B	$72a2,$60
	PL_B	$f1f8,$60
	PL_L	$690e,$4e714e71
	PL_B	$4a02,$60
	PL_B	$7e66,$60
	PL_W	$4890,$4e71
	PL_B	$7046,$60
	PL_W	$110b4,$4e71
	PL_L	$2b3a,$4e714e71
	PL_L	$80e6,$4e714e71
	PL_L	$C272,$4e714e71

; patch loader/disk change
	PL_P	$11962,LOADER
	PL_W	$12000,$4e71
	PL_W	$12034,$4e71
	PL_W	$12068,$4e71
	PL_W	$120c6,$4e71

	PL_PS	$858a,.changedisk	; !! check
	PL_W	$858a+6,$4e71		; !! check

; disable "insert disk" requesters
	PL_S	$588,6			; "insert data disk"
	PL_S	$5a2,6			; "insert data disk"
	PL_S	$8a8,6			; "insert data disk"
	PL_S	$2622,6			; "insert data disk"
	PL_S	$29e0,6			; "insert data disk"
	
	PL_S	$b00,6			; "insert formatted disk"
	PL_S	$b3c,6			; "insert formatted disk"
	PL_S	$b78,6			; "insert formatted disk"
	PL_S	$4424,6			; "insert formatted disk"
	PL_S	$4460,6			; "insert formatted disk"
	PL_S	$5e2c,6			; "insert formatted disk"
	PL_S	$5e68,6			; "insert formatted disk"
	PL_S	$7f50,6			; "insert formatted disk" !!check
	PL_S	$7f8c,6			; "insert formatted disk" !!check

	PL_S	$5e4,6			; "insert program disk"
	PL_S	$616,6			; "insert program disk"
	PL_S	$2390,6			; "insert program disk"
	PL_S	$274e,6			; "insert program disk"


; fix invalid copperlist entry
	PL_PS	$E188,.cop

; enable quit on 68000 machines
	PL_PS	$131d0,.key
	PL_END

.changedisk
	lea	$5f00+$1a5c8,a2
	bra.w	DiskChange

.cop	move.l	#$5f00+$176d2,$dff084
	move.w	#$8380,$dff096
	rts

; !!check
.key	move.b	$22500,d1
	;bra.w	Keys


Keys	ror.b	d1
	not.b	d1
	cmp.b	HEADER+ws_keyexit(pc),d1
	beq.b	.quit


	moveq	#3-1,d1
.loop	move.b	$dff006,d2
.wait	cmp.b	$dff006,d2
	bne.b	.wait
	dbf	d1,.loop
	rts

.quit	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.b	.quit

	; disable irq's/dma
	move.w	#$7fff,d0
	move.w	d0,$dff09c
	move.w	d0,$dff09a
	move.w	d0,$dff096

	pea	(TDREASON_OK).w
	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts



DiskChange
	movem.l	d1-a6,-(a7)
	lea	CurrentDisk(pc),a0
	move.w	(a0),d1
	moveq	#-1,d3			; flag

	lea	.tab(pc),a1
.search	move.w	(a1)+,d2
	beq.b	.end
	cmp.w	d0,d2
	bne.b	.search
	moveq	#0,d3			; new disk

.end	tst.w	d3
	bmi.b	.nonew
	move.w	(a1),(a0)

.nonew	move.w	(a2,d0.w),d0
	movem.l	(a7)+,d1-a6
	rts


.tab	dc.w	336*2,2			; "Please insert your data disk in drive A"
	dc.w	337*2,2			; "Please insert a formatted disk in drive A"
	dc.w	352*2,1			; "Please insert program disk in drive A"

	dc.w	128*2,8			; "save tactics"
	dc.w	129*2,8			; "load tactics"
	dc.w	0



Colors	add.w	#$180,a0
	move.w	$16(a7),(a0,d0.w)
	movem.l	(a7)+,d0/d1/a0/a1
	rts


LOADER	movem.l	d1-a6,-(a7)
	mulu.w	#512,d1
	mulu.w	#512,d2
	move.l	d1,d0
	move.l	d2,d1
	move.w	CurrentDisk(pc),d2
	move.l	resload(pc),a2

	tst.l	d3
	bmi.b	.save
	jsr	resload_DiskLoad(a2)
	bra.b	.nosave

.save	cmp.b	#1,d2
	beq.b	.nosave

	exg.l	d0,d1 
	move.l	a0,a1
	lea	.name(pc),a0
	add.b	#"0",d2
	move.b	d2,.num-.name(a0)
	jsr	resload_SaveFileOffset(a2)


.nosave
.out	movem.l	(a7)+,d1-a6
	moveq	#0,d0
	rts

.name	dc.b	"disk."
.num	dc.b	"1",0,0

CurrentDisk	dc.w	1


; a2: resload
; a5: bootstart

CreateDataDisk
	bsr.b	.createdisk		; create disk.2 (data)
	lea	.name(pc),a0
	move.b	#"8",.num-.name(a0)	; create disk.8 (tactics)

.createdisk
	lea	.name(pc),a0
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	bne.b	.exit			; data disk exists
        clr.l   -(a7)			; TAG_DONE
        clr.l   -(a7)			; data to fill
	move.l  #WHDLTAG_IOERR_GET,-(a7)
	move.l  a7,a0
	jsr     resload_Control(a2)
	move.l	4(a7),d0
	lea	3*4(a7),a7
	beq.b	.exit

; create empty data disk
	move.l	#$30000-$1000,d4	; length
	moveq	#0,d7			; offset
	move.l	#901120,d5
.loop	move.l	d4,d0
	move.l	d7,d1
	lea	.name(pc),a0
	lea	$0.w,a1
	jsr	resload_SaveFileOffset(a2)
	
.ok	add.l	#$30000-$1000,d7
	cmp.l	#901120-$30000-$1000,d7
	ble.b	.ok2
	move.l	#901120,d4
	sub.l	d7,d4
.ok2	sub.l	#$30000-$1000,d5
	bpl.b	.loop
.exit	rts

.name	dc.b	"disk."
.num	dc.b	"2",0

	CNOP	0,4


; d3.w: key1
; a0.l: start
; a1.l: end
; a4.l: tab
; a5.l: PLIST

DecryptAndPatch
	movem.l	d0-a6,-(a7)
.outer	move.l	a4,a3
	moveq	#32-1,d0
.loop	cmp.l	a0,a1
	beq.b	.done
	sub.w	a0,d3
	move.w	(a0),d1
	sub.w	d3,d1
	add.w	(a3)+,d1
	move.w	d1,(a0)+
	dbf	d0,.loop
	bra.b	.outer

.done	move.l	a5,a0
	lea	$5f00.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts


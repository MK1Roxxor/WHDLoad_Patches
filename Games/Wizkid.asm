; V1.3, Codetapper, 01.08.2020
; - Added ability to show the happy birthday intro
; - Fixed empty DBF loops in the ProTracker replayer

; V1.2, stingray, 07.11.2018
; - RawDIC imager
; - Bplcon0 color bit fixes
; - disk accesses removed
; - default quitkey changed to F10

; 08.11.2018
; - high score load/save added
; - trainer options added
; - all old V1.0/V1.1 patches converted to patch lists
; - IFF loading/decrunching optimised, whole routine should be
;   recoded
; - version check added

	INCDIR	INCLUDE:
	INCLUDE	WHDLoad.i
	INCLUDE	WHDMacros.i

		IFD BARFLY
		OUTPUT	"Wizkid.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

FLAGS		= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
QUITKEY		= $59		; F10
;DEBUG

; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM


HEADER	SLAVE_HEADER		; ws_Security + ws_ID
	DC.W	17		; ws_Version
	dc.w	FLAGS		; ws_Flags
	DC.L	$100000		; ws_BaseMemSize
	DC.L	0		; ws_ExecInstall
	DC.W	Patch-HEADER	; ws_GameLoader
	DC.W	.dir-HEADER	; ws_CurrentDir
	DC.W	0		; ws_DontCache
	DC.B	0		; ws_keydebug
	dc.b	QUITKEY		; ws_keyexit
	DC.L	$10000		; ws_ExpMem
	DC.W	.name-HEADER	; ws_name
	DC.W	.copy-HEADER	; ws_copy
	DC.W	.info-HEADER	; ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config
	

.config	dc.b	"C1:X:Unlimited Lives:0;"
	dc.b	"C1:X:Unlimited Energy:1;"
	dc.b	"C1:X:Unlimited Money:2;"
	dc.b	"C1:X:In-Game Keys (press HELP during game):3;"
	dc.b	"C1:X:Happy birthday intro:4;"
	dc.b	0

.name	DC.B	'--<> W i Z K i D <>--',0
.copy	DC.B	'1992 Sensible Software / Ocean',0
.info	DC.B	'------------------------------',10
	DC.B	'Installed & Fixed by',$A
	DC.B	"Galahad of Scoopex & StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	DC.B	"v1.3 (01.08.2020)",10
	DC.B	"------------------------------",0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/Wizkid/"
	ENDC
	dc.b	"data",0

FileName	dc.b	"wizkiddemo80",0
HighName	dc.b	"Wizkid.high",0

	CNOP	0,2

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	FileName(pc),a0
	lea	$80000,a1
	move.l	a1,a5
	jsr	resload_LoadFile(a2)
	move.l	a5,a0
	jsr	resload_CRC16(a2)	
	cmp.w	#$dde3,d0
	beq.w	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

.ok

; stingray, v1.2
	lea	PLMAIN(pc),a0
	move.l	a5,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	jmp	(a5)



PLMAIN	PL_START

; V1.0/1.1 patches, Galahad
	PL_PS	$881c,.CheckQuit
	PL_P	$121a8,.LoadFile
	PL_PS	$c2,LoadIFF
	PL_W	$c2+6,$6036
	PL_R	$6360			; disable raster wait
	PL_W	$11156,$4e71		; as above
	PL_SA	$2f10,$2f18		; skip div0
	PL_L	$11b32,$70004A40	; moveq #0,d0 tst.w d0
	PL_R	$11b32+4
	PL_L	$120d0,$70004A40	; moveq #0,d0 tst.w d0
	PL_R	$120d0+4

	PL_PS	$8714,Copylock
	PL_W	$8714+6,$6002
	PL_L	$34d0,$203A0010
	PL_W	$34d4,$6022	


; V1.2 patches, StingRay
	PL_ORW	$11134+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3c82+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3cb2+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3d62+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3d86+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3d8e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$3e1e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$40f8+2,1<<9		; set Bplcon0 color bit

	PL_R	$12a2c			; disable drive access (motor off)
	PL_R	$128fc			; disable drive access
	PL_R	$12922			; disable drive access
	PL_R	$1297a			; disable drive access (motor on)

	PL_R	$15fe			; loader stuff
	

	PL_IFC1
	PL_R	$11a2e
	PL_ELSE
	PL_P	$11a2e,.SaveHighscores
	PL_ENDIF
	PL_P	$11a50,.LoadHighscores

; unlimited lives
	PL_IFC1X	0
	PL_B	$9d7e,$4a
	PL_ENDIF

; unlimited energy
	PL_IFC1X	1
	PL_B	$9d08,$4a
	PL_ENDIF

; unlimited money
	PL_IFC1X	2
	;PL_B	$643e,$4a
	PL_W	$ad3e,$4a81
	PL_ENDIF

; in-game keys
	PL_IFC1X	3
	PL_PS	$881c,.CheckKeys
	PL_ENDIF

; V1.3 patches, Codetapper

	PL_PSS	$20bcc,_MusicDelay,2		;Empty DBF loop (300)
	PL_PSS	$20be4,_MusicDelay,2		;Empty DBF loop (300)

; happy birthday intro (Codetapper)
	PL_IFC1X	4
	PL_B	$322C,$60
	PL_ENDIF

	PL_END

.LoadHighscores
	lea	HighName(pc),a0
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nohigh
	lea	HighName(pc),a0
	lea	$80000+$56e6,a1
	jsr	resload_LoadFile(a2)
.nohigh	rts


.SaveHighscores
	lea	HighName(pc),a0
	lea	$80000+$56e6,a1
	move.l	#$57e2-$56e6,d0
	move.l	resload(pc),a2
	jmp	resload_SaveFile(a2)


.CheckKeys
	bsr	.CheckQuit

	movem.l	d0-a6,-(a7)
	ror.b	#1,d0
	not.b	d0

	lea	.TAB(pc),a0
.loop	movem.w	(a0)+,d1/d2
	cmp.b	d0,d1
	beq.b	.found
	tst.w	(a0)
	bne.b	.loop

.exit	movem.l	(a7)+,d0-a6
	rts

.found	jsr	.TAB(pc,d2.w)
	bra.b	.exit

.TAB	dc.w	$36,.SkipRound-.TAB		; N: skip round
	dc.w	$28,.RefreshLives-.TAB		; L: refresh lives
	dc.w	$12,.RefreshEnergy-.TAB		; E: refresh energy
	dc.w	$37,.RefreshMoney-.TAB		; M: max. money
	dc.w	$5f,.ShowHelp-.TAB		; HELP: show help screen
	dc.w	0

.SkipRound
	cmp.w	#9,$80000+$733e		; problems when used after level 9
	beq.b	.noskip
	move.w	#1,$80000+$734e
.noskip
	rts

.RefreshLives
	move.w	#2,$80000+$9cca
	rts

.RefreshEnergy
	move.w	#5,$80000+$9cce
	rts

.RefreshMoney
	move.l	#9999,$80000+$d756
	rts



SCREEN		= $60000
HEIGHT		= 64 			; 8 text lines
YSTART		= 80

.ShowHelp
	lea	SCREEN,a0		; screen
	move.l	HEADER+ws_ExpMem(pc),a1
	move.w	#(40*HEIGHT)/4-1,d7
.copy	move.l	(a0),d0
	clr.l	(a0)+
	move.l	d0,(a1)+
	dbf	d7,.copy

	bsr	WaitRaster

	lea	$dff000,a6
	move.w	#$4000,$9a(a6)		; disable interrupts

	move.w	$02(a6),d0
	or.w	#1<<15,d0
	move.w	d0,-(a7)		; save current DMA settings

	move.w	#$7ff,$96(a6)		; disable all DMA

; write help text
	lea	.TXT(pc),a0
	lea	SCREEN,a1
	moveq	#0,d1			; x pos
	moveq	#0,d2			; y pos
.next	sub.l	a4,a4			; special chars
	moveq	#0,d0
	move.b	(a0)+,d0
	beq.w	.done
	cmp.b	#10,d0
	bne.b	.noNew
	moveq	#0,d1
	add.w	#40*8,d2
	bra.b	.next

.noNew	lea	.COLON(pc),a2
	cmp.b	#":",d0
	beq.b	.go
	lea	.MINUS(pc),a2
	cmp.b	#"-",d0
	beq.b	.go

	sub.w	#" ",d0
	lsl.w	#3,d0
.write	lea	font,a2		; font
	add.w	d0,a2
.go	lea	(a1,d1.w),a3		; screen
	add.w	d2,a3
	moveq	#8-1,d7
.copyChar
	move.b	(a2)+,(a3)
	add.w	#40,a3
	dbf	d7,.copyChar
	addq.w	#1,d1			; next x pos	
	bra.w	.next

.done
	move.w	#1<<15+1<<9+1<<8,$96(a6); enable bitplane DMA only


.Fire	bsr	WaitRaster

	move.w	#($2c+YSTART)<<8|81,$8e(a6)
	move.w	#($2c+YSTART+HEIGHT)<<8|$c1,$90(a6)
	move.w	#$38,$92(a6)
	move.w	#$d0,$94(a6)
	move.l	#SCREEN,$e0(a6)
	move.w	#$1200,$100(a6)
	move.w	#0,$108(a6)
	move.w	#0,$10a(a6)
	move.w	#0,$102(a6)
	move.w	#0,$104(a6)
	move.w	#0,$180(a6)
	move.w	#$fff,$182(a6)


	btst	#7,$bfe001
	bne.b	.Fire

	move.w	#1<<8,$96(a6)		; disable bitplane DMA

.release
	btst	#7,$bfe001
	beq.b	.release

	move.l	HEADER+ws_ExpMem(pc),a0
	lea	SCREEN,a1		; screen
	move.w	#(40*HEIGHT)/4-1,d7
.restore
	move.l	(a0)+,(a1)+
	dbf	d7,.restore

	move.w	#$c000,$9a(a6)
	move.w	(a7)+,d0			; restore DMA settings
	move.w	d0,$96(a6)
	rts

font	= $80000+$8db8

; chars not available in font, "drawn" by me :)
.MINUS	dc.b	%00000000
	dc.b	%00000000
	dc.b	%00000000
	dc.b	%01111110
	dc.b	%00000000
	dc.b	%00000000
	dc.b	%00000000
	dc.b	%00000000

.COLON	dc.b	%00000000
	dc.b	%00011000
	dc.b	%00011000
	dc.b	%00000000
	dc.b	%00011000
	dc.b	%00011000
	dc.b	%00000000
	dc.b	%00000000


.TXT	dc.b	"              IN-GAME KEYS",10
	dc.b	10
	dc.b	"L: REFRESH LIVES        M: REFRESH MONEY",10
	dc.b	"E: REFRESH ENERGY       N: SKIP ROUND",10
	dc.b	"          HELP: THIS SCREEN",10
	dc.b	10
	dc.b	"     PRESS FIRE TO RETURN TO GAME",0

	CNOP	0,2



.LoadFile
	movem.l	d0-a6,-(a7)

	move.l	a0,a2
	lea	.TEMP(pc),a3
	move.l	a3,a4
	moveq	#4-1,d0
.copy_name
	move.b	(a2)+,(a3)+
	dbf	d0,.copy_name

	bsr	LoadFile

	cmp.l	#"astc",(a4)
	bne.b	.nospecial

	lea	LoadIFF(pc),a0
	move.w	#$4EF9,($80,a1)
	move.l	a0,($82,a1)

	lea	.LoadFile(pc),a0
	move.w	#$4EF9,($4E,a1)
	move.l	a0,($50,a1)
	move.w	#$600C,($16C0,a1)

.nospecial
	movem.l	(a7)+,d0-a6

	move.l	FileLength(pc),d1
	moveq	#0,d0
	rts

.TEMP	DC.L	0
	DC.W	0


.CheckQuit
	move.b	$BFEC01,d0
	ror.b	#1,d0
	not.b	d0
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	.QUIT

	move.b	$BFEC01,d0
	rts



.QUIT	pea	(TDREASON_OK).W
EXIT	move.l	resload(pc),a0
	jmp	resload_Abort(a0)



; a0.l: file name
; a1.l: destination
; a2.l: palette buffer

LoadIFF	movem.l	d0-d7/a0-a6,-(sp)
	lea	PicDest(pc),a3
	move.l	a1,(a3)+

	movem.l	a0-a2,-(a7)
	move.l	HEADER+ws_ExpMem(pc),a1
	bsr	LoadFile
	movem.l	(a7)+,a0-a2

	bsr.b	DecrunchIFF

	movem.l	(sp)+,d0-d7/a0-a6
	rts

PicDest	dc.l	0
lbL0002CA
	DC.L	0



DecrunchIFF
	movem.l	d0-d7/a0-a6,-(sp)

	move.l	HEADER+ws_ExpMem(pc),a0
	lea	BUF1(pc),a6
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3
	moveq	#32/4-1,d4
	move.l	a6,-(sp)
.clear	move.l	d0,(a6)+
	dbf	d4,.clear

	move.l	(sp)+,a6

	cmp.l	#"FORM",(a0)
	bne.w	lbC0003E6
	addq.l	#8,a0
	cmp.l	#'ILBM',(a0)+
	bne.w	lbC0003E6

.find_header
	cmp.l	#"BMHD",(a0)
	beq.b	lbC00031C
	addq.l	#2,a0
	bra.b	.find_header

lbC00031C
	move.w	8(a0),d0
	lsr.w	#3,d0
	move.w	(10,a0),d1
	move.b	($10,a0),d2
	move.b	($12,a0),d3
	move.l	d0,($14,a6)
	move.l	d1,($18,a6)
	move.l	d2,($10,a6)
lbC00033A

	cmp.l	#"CMAP",(a0)
	beq.b	lbC000346
	addq.l	#2,a0
	bra.b	lbC00033A

lbC000346
	bsr.w	lbC0003EC
lbC00034A
	cmp.l	#"BODY",(a0)
	beq.b	lbC000356
	addq.l	#2,a0
	bra.b	lbC00034A

lbC000356
	addq.l	#8,a0
	tst.l	d3
	beq.w	lbC0003E6
	move.l	($14,a6),d0
	move.l	($18,a6),d1
	subq.l	#1,d1
	mulu	d0,d1
	move.l	d1,d3
	move.l	a1,a4
lbC00036E
	move.l	($14,a6),d0
	move.l	(0,a6),d1
	cmp.l	d0,d1
	bne.b	lbC0003B2
	clr.l	(0,a6)
	addq.l	#1,(4,a6)
	add.l	d3,a1
	move.l	($10,a6),d0
	move.l	(4,a6),d1
	cmp.l	d0,d1
	bne.b	lbC0003B2
	clr.l	(4,a6)
	move.l	($14,a6),d0
	add.l	d0,(8,a6)
	addq.l	#1,(12,a6)
	move.l	($18,a6),d0
	move.l	(12,a6),d1
	cmp.l	d0,d1
	beq.b	lbC0003E6
	move.l	a4,a1
	add.l	(8,a6),a1
lbC0003B2
	moveq	#0,d0
	move.b	(a0),d0
	bpl.b	lbC0003BA
	bmi.b	lbC0003CE
lbC0003BA
	addq.l	#1,a0
	moveq	#0,d1
	move.b	d0,d1
	addq.b	#1,d1
lbC0003C2
	move.b	(a0)+,(a1)+
	dbra	d0,lbC0003C2
	add.l	d1,(0,a6)
	bra.b	lbC00036E

lbC0003CE
	addq.l	#1,a0
	neg.b	d0
	moveq	#0,d2
	move.b	d0,d2
	addq.b	#1,d2
	move.b	(a0)+,d1
lbC0003DA
	move.b	d1,(a1)+
	dbra	d0,lbC0003DA
	add.l	d2,(0,a6)
	bra.b	lbC00036E

lbC0003E6
	movem.l	(sp)+,d0-d7/a0-a6
	rts

lbC0003EC
	movem.l	d0-d7/a0-a6,-(sp)
	addq.l	#4,a0
	move.l	(a0)+,d0
	lea	(lbL0002CA,pc),a1
	move.l	d0,(a1)
	divs	#3,d0
	subq.l	#1,d0
	move.l	a2,a1
.loop
	clr.w	(a1)

	move.b	(a0)+,d1
	lsr.b	#4,d1
	ext.w	d1
	lsl.w	#8,d1
	add.w	d1,(a1)

	move.b	(a0)+,d1
	lsr.b	#4,d1
	ext.w	d1
	lsl.w	#4,d1
	add.w	d1,(a1)

	move.b	(a0)+,d1
	lsr.b	#4,d1
	ext.w	d1
	add.w	d1,(a1)+

	dbf	d0,.loop
	movem.l	(sp)+,d0-d7/a0-a6
	rts

BUF1	ds.b	112

PALETTE	ds.b	32*3

FileLength	DC.L	0
resload		DC.L	0

LoadFile
	movem.l	d0/d1/a0-a2,-(sp)
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)
	lea	FileLength(pc),a0
	move.l	d0,(a0)
	movem.l	(sp)+,d0/d1/a0-a2
	rts



WaitRaster
.wait	btst	#0,$dff005
	beq.b	.wait

.wait2	btst	#0,$dff005
	bne.b	.wait2
	rts
	

Copylock
	movem.l	d0-d7/a0-a7,-(sp)
	move.l	sp,a6
	move.l	#$3D742CF1,(a6)
	move.l	(a6),$60.W
	lea	8(a6),a0
	lea	$24(a6),a1
	moveq	#2,d2
	move.l	#$25B2BD1,d0
	move.l	d0,d3
	lsl.l	#2,d0
.loop	move.l	(a0)+,d1
	sub.l	d0,d1
	move.l	d1,(a1)+
	add.l	d0,d0
	addq.b	#1,d2
	cmp.b	#8,d2
	bne.b	.loop
	move.l	d3,(a1)+
	movem.l	(sp)+,d0-d7/a0
	rts

_MusicDelay	movem.l	d0-d1,-(sp)
		moveq	#8-1,d1
.int2w1		move.b	(_custom+vhposr),d0
.int2w2		cmp.b	(_custom+vhposr),d0	;one line is 63.5 µs
		beq	.int2w2
		dbf	d1,.int2w1
		movem.l	(sp)+,d0-d1
		rts

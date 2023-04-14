***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(    EUROPEAN CHAMPIONSHIP WHDLOAD SLAVE     )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                            November 2011                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 14-Apr-2023	- support for another version added

; 03-Feb-2014	- support for "Sports Masters" compilation version added,
;		  thanks to Chris4981 for sending his original

; 27-Jan-2014	- tested game save, works fine
;		- cheated my way through this crappy game, everything
;		  works fine
;		- fixed config to properly show the language selection
;		  cycle gadget
;		- ext. mem back to chip as intro crashes otherwise
;		- high score load/save added, no idea why I even bothered...
;		- save disk is created automatically if it doesn't exist

; 26-Jan-2014	- had a look at the patch again after more than 2 years,
;		  time sure does fly
;		- made the game work, reason for the crash was missing
;		  ext. mem init, once that was fixed the game worked
;		  flawlessly
;		- changed memory required, now using fast mem for ext.
;		  memory, since game aligns the memory the patch needs
;		  512+64k ext. mem but that's better than 1Mb chip
;		- Fire-Pack decruncher used in intro relocated to fast
;		  memory
;		- added option to select language, language can be
;		  set with CUSTOM2, if used the language selection screen
;		  is skipped
;		- interrupts fixed
;		- made game run after intro has been played! (original game
;		  just resets the machine)
;		- added support for save disk, tested with settings and
;		  goals, didn't test game save yet

; 28-11-2011	- work started
;		- intro works
;		- game patched too but crashes

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

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

HEADER	SLAVE_HEADER		; ws_security + ws_ID
	dc.w	17		; ws_version
	dc.w	FLAGS		; flags
	dc.l	524288*2	; ws_BaseMemSize
	dc.l	0		; ws_ExecInstall
	dc.w	Patch-HEADER	; ws_GameLoader
	dc.w	.dir-HEADER	; ws_CurrentDir
	dc.w	0		; ws_DontCache
	dc.b	0		; ws_KeyDebug
	dc.b	QUITKEY		; ws_KeyExit
	dc.l	0		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"C1:B:Skip Intro;"
	dc.b	"C2:L:Select Language:Off,English,French,Italian,Spanish,German,Swedish;"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/EuropeanChampionship/"
	ENDC
	dc.b	"data",0
.name	dc.b	"European Championship 1992",0
.copy	dc.b	"1992 Elite",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	dc.b	"Version 1.02 (14.04.2023)",0

TAB	dc.b	"0123456789ABCDEF"
NAME	dc.b	"0",0

SaveDiskName	dc.b	"disk.3",0
HighName	dc.b	"EuropeanChampionship.high",0
	CNOP	0,2

DiskNum		dc.w	2
TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUTYPE		dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
BOOTDISK2	dc.l	0		; boot from disk 2 (skip intro)
		dc.l	WHDLTAG_CUSTOM2_GET
LANGUAGE	dc.l	0
		dc.l	TAG_END

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

; create save disk if it doesn't exist
	bsr	CreateSaveDisk


; install keyboard irq
	bsr	SetLev2IRQ

; check if intro files exist (support for 1 disk "Sports Masters"
; compilation version)
	lea	NAME(pc),a0
	jsr	resload_GetFileSize(a2)
	tst.l	d0			; if no intro files exist ->
	beq.w	Disk2			; boot from disk 2

	move.l	BOOTDISK2(pc),d0
	bne.w	Disk2

; load file 0
	moveq	#0,d0
	lea	$1000.w,a0
	move.l	a0,a5
	bsr	LoadFile

; version check
	move.l	a5,a0
	jsr	resload_CRC16(a2)
	lea	PL0(pc),a0
	cmp.w	#$be47,d0		; SPS 478
	beq.b	.ok
	move.l	#$80000,$fc.w		; set ext. memory
	lea	PL0_V2(pc),a0
	cmp.w	#$28D1,d0		; V2
	beq.b	.ok

; unknown version
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT
	

.ok
	

; patch boot
	move.l	a5,a1
	jsr	resload_Patch(a2)

; start game
	;move.l	HEADER+ws_ExpMem(pc),d0
	;add.l	#65536,d0		; game aligns the memory ptr

	jmp	(a5)


	
QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)

KillSys	move.w	#$7fff,$dff09a
	bsr	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	rts
	

; common for both supported versions
PLGAME_COMMON
	PL_START
	PL_SA	$6b02,$6b18		; don't patch exception vectors

	PL_R	$470			; rts in kbd irq

	PL_L	$4d2e,$70004e75		; drive/disk status
	PL_P	$4dde,Loader
	PL_R	$1698			; drive access

	PL_PSA	$6c8a,.setlang,$6c94	; set language if CUSTOM2 is used

	PL_PSS	$3a8,.delay,2		; fix CPU dependent delay

	PL_SA	$1898,$18b4		; disable save disk request
	PL_SA	$163c,$1658		; disable save disk request
	PL_SA	$22c6,$22de		; disable save disk request
	PL_PS	$1752,.gamedisk		; set game disk
	PL_PS	$17a4,.savedisk		; set save disk
	PL_PS	$17f6,.savedisk		; set save disk
	PL_PS	$184a,.savedisk		; set save disk

	PL_P	$7568,.savehigh		; save high scores
	PL_END

.setlang
	move.l	LANGUAGE(pc),d0
	beq.b	.nolang
	cmp.w	#1,d0
	blt.b	.nolang
	cmp.w	#6,d0
	bgt.b	.nolang
	subq.w	#2,d0
	move.b	d0,$420+$24a.w
	rts


.nolang	jsr	$420+$208.w		; language selection screen
	move.w	$420+$16ed4,d0
	rts


.savehigh
.copy	move.b	(a0)+,(a1)+		; original code, copy high score name
	bpl.b	.copy

	lea	HighName(pc),a0
	lea	$420+$29d4.w,a1
	move.l	resload(pc),a2
	move.l	#$2ba8-$29d4,d0
	jmp	resload_SaveFile(a2)


.gamedisk
	lea	DiskNum(pc),a0
	move.w	#2,(a0)
.set	lea	$2c996,a0		; original code
	rts

.savedisk
	lea	DiskNum(pc),a0
	move.w	#3,(a0)
	bra.b	.set

.delay	moveq	#11-1,d0		; wait 11*5 raster lines
.wait	bsr	FixDMAWait
	dbf	d0,.wait
	rts

	

; "Sports Masters" Compilation
PL_GAMECOMP
	PL_START
	PL_SA	$6b02,$6b18		; don't patch exception vectors

	PL_SA	$8416,$8420		; don't set level 2 irq
	PL_SA	$8460,$846a		; don't set level 2 irq

	PL_P	$16582,copylock

	PL_P	$85d2,ackLev6
	PL_P	$8588,ackVBI
	PL_PSS	$961c,ackLev4,2

	PL_ORW	$8448+2,1<<14
	PL_PS	$849a,enable_interrupts

	PL_NEXT	PLGAME_COMMON
	PL_END
	

enable_interrupts
	move.w	#$2000,sr		; enable interrupts
	jmp	$420+$2a6.w


ackVBI	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rte

ackLev6
	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte

ackLev4
	move.w	#$80,$dff09c
	move.w	#$80,$dff09c
	rts

copylock
	move.l	#$da8dbfdb,d0
	move.l	d0,$60.w
	rts




PL_GAME	PL_START
	PL_SA	$6b02,$6b18		; don't patch exception vectors

	PL_SA	$83ee,$83f8		; don't set level 2 irq
	PL_SA	$8438,$8442		; don't set level 2 irq

	PL_P	$1655a,copylock

	PL_P	$85aa,ackLev6
	PL_P	$8560,ackVBI
	PL_PSS	$95f4,ackLev4,2

	PL_ORW	$8420+2,1<<14
	PL_PS	$8472,enable_interrupts

	PL_NEXT	PLGAME_COMMON
	PL_END


PL0_V2
	PL_START
	PL_ORW	$4cc+2,1<<3		; enable level 2 irq	
	PL_P	$b98,LoadFile
	PL_P	$cf14,Loader		; Rob Northen loader
	PL_SA	$6c,$110		; skip "insert disk" picture
	PL_P	$114,Disk2		; boot from disk 2 instead of rebooting
	PL_PSS	$d894,ackLev4_Intro,2
	PL_P	$57c,fire_decrunch	; relocate Fire-Pack decruncher
	PL_END


PL0	PL_START
	PL_ORW	$4c8+2,1<<3		; enable level 2 irq	
	PL_P	$b94,LoadFile
	PL_P	$cf10,Loader		; Rob Northen loader
	PL_SA	$a8,$14c		; skip "insert disk" picture
	PL_P	150,Disk2		; boot from disk 2 instead of rebooting
	PL_PSS	$d890,ackLev4_Intro,2
	PL_P	$578,fire_decrunch	; relocate Fire-Pack decruncher
	PL_SA	$0,$22			; skip alloc/avail mem
	PL_END

ackLev4_Intro
	move.w	#$80,$dff09c
	move.w	#$80,$dff09c
	rts

Disk2	bsr	KillSys
	;lea	$7f730-$3300,a7	
	lea	$7f840,a7

	move.w	#$383,d1
	move.w	#$43d-$383,d2
	addq.w	#1,d2
	lea	$400.w,a0
	lea	20(a0),a5		; 20 -> skip hunk header
	bsr.w	Loader

	
	move.w	d2,d0
	mulu.w	#512,d0
	move.l	resload(pc),a2
	jsr	resload_CRC16(a2)

	lea	PL_GAME(pc),a0
	cmp.w	#$0953,d0		; SPS 478
	beq.b	.ok
	lea	PL_GAMECOMP(pc),a0
	cmp.w	#$019b,d0		; Sports Masters compilation
	beq.b	.ok
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.ok	lea	$420.w,a1
	jsr	resload_Patch(a2)


; load high scores (why did I even bother?)
	lea	HighName(pc),a0
	st	GameFlag-HighName(a0)
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nohigh
	lea	HighName(pc),a0
	lea	$420+$29d4.w,a1
	jsr	resload_LoadFile(a2)
.nohigh

	move.w	#$123,$324.w
	clr.l	$4.w
	jmp	(a5)




Loader	cmp.w	#$8001,d3
	beq.b	.save

.nosave	movem.l	d0-a6,-(a7)
	move.w	d1,d0
	move.w	d2,d1
	mulu.w	#512,d0
	mulu.w	#512,d1
	move.w	DiskNum(pc),d2		; disk 2/3
	move.l	resload(pc),a2
	jsr	resload_DiskLoad(a2)
	movem.l	(a7)+,d0-a6
.exit	moveq	#0,d0			; no errors
	rts


.save	movem.l	d0-a6,-(a7)
	move.l	a0,a1
	
	move.w	d1,d0
	move.w	d2,d1
	mulu.w	#512,d0
	mulu.w	#512,d1
	exg	d0,d1
	lea	SaveDiskName(pc),a0
	move.l	resload(pc),a2
	jsr	resload_SaveFileOffset(a2)
	movem.l	(a7)+,d0-a6
	moveq	#0,d0			; no errors
	rts


; d0.w: file number
; a0.l: destination

LoadFile
	tst.w	d0
	bmi.b	.out			; init loader
	movem.l	d2-d7/a2-a6,-(a7)
	move.l	a0,a1
	lea	NAME(pc),a0
	move.b	TAB-NAME(a0,d0.w),(a0)
	move.l	resload(pc),a2
	jsr	resload_LoadFile(a2)
	movem.l	(a7)+,d2-d7/a2-a6
.out	rts

WaitRaster
	move.l	d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.b	.wait
	move.l	(a7)+,d0
	rts

FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d1	
.loop	move.b	$dff006,d0
.wait	cmp.b	$dff006,d0
	beq.b	.wait
	dbf	d1,.loop
	movem.l	(a7)+,d0/d1
	rts

***********************************
*** Level 2 IRQ			***
***********************************

SetLev2IRQ
	pea	Lev2(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode

	move.w	#1<<3,$dff09c			; clear ports interrupt
	move.w	#1<<15|1<<14|1<<3,$dff09a	; and enable it
	rts

Lev2	movem.l	d0-d1/a0-a2,-(a7)
	lea	$dff000,a0
	lea	$bfe001,a1


	btst	#3,$1e+1(a0)			; PORTS irq?
	beq.w	.end
	btst	#3,$d00(a1)			; KBD irq?
	beq.w	.end

	moveq	#0,d0
	move.b	$c00(a1),d0

	move.b	GameFlag(pc),d1
	beq.b	.nogame
	movem.l	d0-a6,-(a7)
	jsr	$420+$42c.w			; call in-game routine
	movem.l	(a7)+,d0-a6

.nogame	not.b	d0
	ror.b	d0

	or.b	#1<<6,$e00(a1)			; set output mode



	cmp.b	HEADER+ws_keydebug(pc),d0	
	bne.b	.nodebug
	movem.l	(a7)+,d0-d1/a0-a2
	move.w	(a7),6(a7)			; sr
	move.l	2(a7),(a7)			; pc
	clr.w	4(a7)				; ext.l sr
	bra.b	.debug


.nodebug
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	.exit
	

.nokeys
	moveq	#3-1,d1
.loop	move.b	$6(a0),d0
.wait	cmp.b	$6(a0),d0
	bne.b	.wait
	dbf	d1,.loop


	and.b	#~(1<<6),$e00(a1)	; set input mode
.end	move.w	#1<<3,$9c(a0)
	move.w	#1<<3,$9c(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte

.debug	pea	(TDREASON_DEBUG).w
.quit	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.exit	pea	(TDREASON_OK).w
	bra.b	.quit



GameFlag	dc.b	0
		dc.b	0


; Unpackroutine von FIRE-PACK
; Eingabe: a0 = Adresse gepackter Daten
; Uses 120 byte-buffer stored on the stack

fire_decrunch
	link	a3,#-120
	movem.l	d0-a6,-(sp)
	move.l	a0,a6		; Arbeitsregister
	move.l	a0,a4		; a4 = Anfang der Originaldaten
	bsr.s	.getinfo	; Kenn-Langwort holen
	cmp.l	#'FIRE',d0	; Kennung gefunden?
	bne.s	.not_packed	; nein: nicht gepackt
	bsr.s	.getinfo	; Kenn-Langwort holen
	move.l	a3,a2
	moveq	#119,d1		; 120 Bytes vor gepackten Daten
.save	move.b	-(a6),-(a2)	; in sicheren Bereich sichern
	dbf	d1,.save
	move.l	a6,a2		; Anfang der gepackten Daten
	lea.l	-8(a6,d0.l),a5	; a5 = Ende der gepackten Daten
.move	move.b	(a0)+,(a6)+
	subq.l	#1,d0
	bne.s	.move
	move.l	a2,a0
	bsr.s	.getinfo	; Laenge holen
	move.l	d0,(sp)		; Originallaenge: spaeter nach d0
	move.l	a4,a6		; a6 = Ende der Originaldaten
	add.l	d0,a6

	move.b	-(a5),d7	; erstes Informationslangwort
	lea	.tabellen(pc),a2; a2 = Zeiger auf Datenbereich
	moveq	#1,d6
	swap	d6		; d6 = $10000
	moveq	#0,d5		; d5 = 0 (oberes Wort: immer 0!)

.normal_bytes
	bsr.s	.get_1_bit
	bcc.s	.test_if_end	; Bit %0: keine Daten
	moveq	#0,d1		; falls zu .copy_direkt
	bsr.s	.get_1_bit
	bcc.s	.copy_direkt	 ; Bitfolge: %10: 1 Byte direkt kop.
;	lea.l	.direkt_tab+16-.tabellen(a2),a0 ; ...siehe naechste Zeile
	move.l	a2,a0
	moveq	#3,d3
.nextgb	move.l	-(a0),d0	; d0.w Bytes lesen
	bsr.s	.get_d0_bits
	swap	d0
	cmp.w	d0,d1		; alle gelesenen Bits gesetzt?
	dbne	d3,.nextgb	; ja: dann weiter Bits lesen
.no_more
	 add.l	16(a0),d1 	; Anzahl der zu bertragenen Bytes
.copy_direkt
	move.b	-(a5),-(a6)	; Daten direkt kopieren
	;move.w	#$070,$ff8240	; green
	dbf	d1,.copy_direkt	; noch ein Byte
.test_if_end:
	cmp.l	a4,a6		; Fertig?
	bgt.s	.strings	; Weiter wenn Ende nicht erreicht
	moveq	#119,d0		; um ueberschriebenen Bereich
.rest	move.b	-(a3),-(a4)	; wieder herzustellen
	dbf	d0,.rest
.not_packed:
	movem.l	(sp)+,d0-a6
	unlk	a3
	rts

;************************** Unterroutinen: wegen Optimierung nicht am Schluß
.getinfo:
	moveq	#3,d1
.glw:	rol.l	#8,d0
	move.b	(a0)+,d0
	dbf	d1,.glw
	rts


.get_1_bit:
	add.b	d7,d7		; hole ein Bit
	beq.s	.no_bit_found
	rts
.no_bit_found:
	move.b	-(a5),d7
	addx.b	d7,d7
	rts

.get_d0_bits:
	moveq	#0,d1		; ergebnisfeld vorbereiten
.hole_bit_loop:
	add.b	d7,d7		; hole ein Bit
	beq.s	.not_found	; quellfeld leer
.on_d0:	addx.w	d1,d1		; und uebernimm es
	dbf	d0,.hole_bit_loop; bis alle Bits geholt wurden
	rts

.not_found:
	move.b	-(a5),d7	; hole sonst ein weiters longword
	addx.b	d7,d7		; hole ein Bit
	bra.s	.on_d0

;************************************ Ende der Unterroutinen


.strings:
	moveq	#1,d0		; 2 Bits lesen
	bsr.s	.get_d0_bits
	subq.w	#1,d1
	bmi.s	.gleich_morestring	; %00
	beq.s	.length_2 	; %01
	subq.w	#1,d1
	beq.s	.length_3 	; %10
	bsr.s	.get_1_bit
	bcc.s	.bitset		; %110
	bsr.s	.get_1_bit
	bcc.s	.length_4 	; %1110
	bra.s	.length_5 	; %1111

.get_short_offset:
	moveq	#1,d0
	bsr.s	.get_d0_bits	; d1:  0,  1,  2,  3
	subq.w	#1,d1
	bpl.s	.contoffs
	moveq	#0,d0		; Sonderfall
	rts

.get_long_offset:
	moveq	#1,d0		; 2 Bits lesen
	bsr.s	.get_d0_bits	; d1:  0,  1,  2,  3
.contoffs add.w	d1,d1		; d1:  0,  2,  4,  6
	add.w	d1,d1		; d1:  0,  4,  8, 12
	movem.w	.offset_table-.tabellen(a2,d1),d0/d5
	bsr.s	.get_d0_bits	; 4, 8, 12 oder 16 Bits lesen
	add.l	d5,d1
	rts


.gleich_morestring: 		; %00
	moveq	#1,d0		; 2 Bits lesen
	bsr.s	.get_d0_bits	; d1:  0,  1,  2,  3
	subq.w	#1,d1
	bmi.s	.gleich_string	; %0000

	add.w	d1,d1		; d1:	 0,  2,  4
	add.w	d1,d1		; d1:	 0,  4,  8
	movem.w	.more_table-.tabellen(a2,d1),d0/d2
	bsr.s	.get_d0_bits
	add.w	d1,d2		; d2 = Stringlaenge
	bsr.s	.get_long_offset
	move.w	d2,d0		; d0 = Stringlaenge
	bra.s	.copy_longstring

.bitset:	moveq	#2,d0		; %110
	bsr.s	.get_d0_bits
	moveq	#0,d0
	bset	d1,d0
	bra.s	.put_d0

.length_2:
	moveq	#7,d0		; %01
	bsr.s	.get_d0_bits
	moveq	#2-2,d0
	bra.s	.copy_string

.length_3:
	bsr.s	.get_short_offset	; %10
	tst.w	d0
	beq	.put_d0		; 0 ablegen
	moveq	#3-2,d0
	bra.s	.copy_string

.length_4:
	bsr.s	.get_short_offset	; %1110
	tst.w	d0
	beq.s	.vorgaenger_kopieren
	moveq	#4-2,d0
	bra.s	.copy_string

.length_5:
	bsr.s	.get_short_offset	; %1111
	tst.w	d0
	beq.s	.put_ff
	moveq	#5-2,d0
	bra.s	.copy_string


.put_ff	moveq	#-1,d0
	bra.s	.put_d0

.vorgaenger_kopieren:
	move.b	(a6),d0
;	bra.s	.put_d0

.put_d0	move.b	d0,-(a6)
	bra.s	.backmain


.gleich_string:
	bsr.s	.get_long_offset; Anzahl gleicher Bytes lesen
	beq.s	.backmain 	; 0: zurueck
	move.b	(a6),d0
.copy_gl: move.b	d0,-(a6)
	dbf	d1,.copy_gl
	sub.l	d6,d1
	bmi.s	.backmain
	bra.s	.copy_gl

.copy_longstring:
	subq.w	#2,d0		; Stringlaenge - 2 (wegen dbf)
.copy_string:			; d1 = Offset, d0 = Anzahl Bytes -2
	lea.l	2(a6,d1.l),a0	; Hier stehen die Originaldaten
	add.w	d0,a0		; dazu die Stringl„nge-2
	move.b	-(a0),-(a6)	; ein Byte auf jeden Fall kopieren
.dep_b:	move.b	-(a0),-(a6)	; mehr Bytes kopieren
	dbf	d0,.dep_b 	; und noch ein Mal
	;move.w	#$777,$ff8240	; white
.backmain bra	.normal_bytes	; Jetzt kommen wieder normale Bytes


.direkt_tab:
	dc.l	$03ff0009,$00070002,$00030001,$00030001 ; Anzahl 1-Bits
.tabellen:dc.l	    15-1,      8-1,      5-1,      2-1	; Anz. Bytes

.offset_table:
	dc.w	 3,	      0
	dc.w	 7,	   16+0
	dc.w	11,      256+16+0
	dc.w	15, 4096+256+16+0
.more_table:
	dc.w	3,       5
	dc.w	5,    16+5
	dc.w	7, 64+16+5

ende_fire_decrunch_3:
;*************************************************** Ende der Unpackroutine


CreateSaveDisk
	lea	SaveDiskName(pc),a0
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

; create empty save disk
	move.l	#$30000-$1000,d4	; length
	moveq	#0,d7			; offset
	move.l	#901120,d5
.loop	move.l	d4,d0
	move.l	d7,d1
	lea	SaveDiskName(pc),a0
	lea	$1000.w,a1
	jsr	resload_SaveFileOffset(a2)
	
.ok	add.l	#$30000-$1000,d7
	cmp.l	#901120-$30000,d7
	ble.b	.ok2
	move.l	#901120,d4
	sub.l	d7,d4
.ok2	sub.l	#$30000-$1000,d5
	bpl.b	.loop
.exit	rts


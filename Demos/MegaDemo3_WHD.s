***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*( NORTH STAR/FLT 'MEGADEMO 3'  WHDLOAD SLAVE )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                             October 2011                                *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
** History			***
***********************************

; 08-May-2020	- Black Shadow's part (part 17) didn't run correctly on
;		  some machines (reported by Paul Mitchell), changed the
;		  way it waits for the raster beam which fixed the problem

; 06-May-2020	- system font (modified) added for the bootblock intro
;		- simple randomizer for the starfield coded (no data from
;		  ROM necessary)
;		- patch finished!


; 05-May-2020	- size optimised the TimeDecruncher calls a bit
;		- separate offset table for decrunchers removed and added
;		  directly in main table
;		- support for disk 2 bootblock intro added (ScrollRaster(),
;		  Move() and Text() already emulated, font and starfield
;		  left to adapt)

; 17-Oct-2018	- checking of ws_keydebug in keyboard interrupt removed

; 06-Jun-2016	- part 10: problem with uninitialised copperlist buffers
;		           fixed
;			   one more byte write to volume register fixed
;			   OCS only DDFSTOP in scroller area fixed -> no
;			   more "modulo" bugs!
;		- part 5:  OCS only DDFSTOP in both parts fixed, no more
;			   bitplane trash/modulo bugs!
;		- part 11: problem with uninitialised copperlist buffers
;			   fixed
;			   one more byte write to volume register fixed
;			   OCS only DDFSTOP fixed, no more "modulo" bugs!
;			   one more Bplcon0 color bit fix
;		- part 12: ROM access ($f82000) fixed
;			   OCS only DDFSTRT fixed, no more garbage in the
;			   scroller area
;		- part 14: 2 blitter waits added
;		- part 15: 2 Bplcon0 color bit fixes added
;			   default copperlist ($1000) restored upon exit
;			   default VBI set upon exit
;		- part 16: long read from $dff006 fixed
;			   3 blitter waits added 
;			   one more byte write to volume register fixed
;		- part 17: ROM access ($f82000) fixed
;		- part 18: blitter wait added
;			   OCS only DDFSTOP fixed
;			   default copperlist ($1000) restored upon exit
;		- part 6:  one blitter wait added to fix the scroller
;			   glitch on fast machines
;		- part 13: one more byte write to volume register fixed
;		- part 3:  DMA wait and byte write to volume register fixed
;		- part 7:  one more byte write to volume register fixed
;
;		- And that's it! After many, many hours of work all parts
;		  are finally patched and fixed!
;
;		- bug in keyboard interrupt (delay) fixed
;		- ByteKiller decruncher optimised and error check added
;		- Time decruncher optimised
;		- some debug code removed
;		- size optimised DMA wait fix replaced with "safe" version

; 05-Jun-2016	- source can be assembled case sensitive now

; 02-Jun-2016	- part 2: out of bound blits fixed (uninitialised
;		          register so crap was left in the high word of d0)
;		- part 4: unitialised copperlist fixed (system restore)
;		- part 5: $ABBA plane pointers fixed, illegal Bplcon 2
;		          value fixed, wrong A-modulo register access
;		          fixed ($dff6064 -> $dff064) 
;		- part 6: access fault fixed (move.b (a1,d1.l),d2 ->
;			  move.b (a1,d1.w),d2)
;		          ROM access ($f82000) fixed
;			  OCS only DDFSTRT causing bitplane trash in the
;			  scroller area fixed
;		- part 7: Bplcon0 color bit fix
;		- part 8: Bplcon0 color bit fixes corrected (a0)+ -> (a2)+
;		          one more byte write to volume register fixed
;		          unitialised copperlist fixed (system restore)

; 01-Jun-2016	- almost 5 years later...
;		- ROM access ($faa000) in loader part fixed
;		- part 1: one more byte write to volume register fixed
;		- part 2: long read from $dff006 fixed

; 10-Nov-2011	- part 15 patched
;		- part 16 patched
;		- part 17 patched
;		- part 18 patched
;		- disk change corrected, demo displays correct logo
;		  when loading from 2nd disk now


; 09-Nov-2011	- fixed speed issues in part 7
;		- part 8 patched
;		- part 9 patched
;		- part 10 patched
;		- part 11 patched
;		- part 12 patched
;		- part 13 patched, smc to do
;		- part 14 patched, not finished

; 08-Nov-2011	- patched part 6
;		- patched part 7

; 07-Nov-2011	- continued to patch part 5

; 03-Nov-2011	- part 4 (stars are forever) patched

; 02-Nov-2011	- bugs fixed
;		- part 1 patched
;		- part 2 patched

; 01-Nov-2011

; 31-Oct-2011	- work started

	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
DEBUGKEY	= $58		; F9
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

; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"C1:B:Run Disk 2 Boot Intro"
	dc.b	0
	

	IFD	DEBUG
.dir	dc.b	"SOURCES:WHD_Slaves/Demos/Northstar/MegaDemo3/",0
	ENDC
.name	dc.b	"Megademo 3",0
.copy	dc.b	"1989 North Star & Fairlight",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	dc.b	"Version 1.01 (08.05.2020)",0
	CNOP	0,2

TAGLIST		dc.l	WHDLTAG_CUSTOM1_GET
RUNBOOTINTRO	dc.l	0
		dc.l	TAG_DONE


resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

; install keyboard irq
	bsr	SetLev2IRQ

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)
	move.l	RUNBOOTINTRO(pc),d0
	bne.b	RunDisk2BootIntro




; load boot
	move.l	#$400,d0
	move.l	#$2800,d1
	move.l	d1,d7
	moveq	#1,d2
	lea	$c000,a5
	move.l	a5,a0
	jsr	resload_DiskLoad(a2)

; version check
	move.l	a5,a0
	move.l	d7,d0
	jsr	resload_CRC16(a2)
	lea	PL_BOOT(pc),a0
	cmp.w	#$4026,d0
	beq.b	.ok

; unknown version
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT

.ok	move.l	a5,a1
	jsr	resload_Patch(a2)
	move.w	#$aaa,$dff180
	jmp	$1a(a5)

QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	jmp	resload_Abort(a2)




RunDisk2BootIntro
	moveq	#0,d0
	move.l	#$400,d1
	moveq	#2,d2
	lea	$77000-$42,a0
	move.l	a0,a5
	move.l	d1,d5
	jsr	resload_DiskLoad(a2)
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$A618,d0
	beq.b	.ok
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT
		

.ok	lea	PLBOOTINTRO(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

	lea	$2af(a5),a4		; scroll text
	jmp	$42(a5)



PLBOOTINTRO
	PL_START
	;PL_L	$7e+2,$77000		; $fca000 -> start of bootblock code
	;PL_SA	$9c,$a2			; skip buggy code
	PL_SA	$118,$170		; skip graphics.library stuff
	PL_PSS	$1fe,.ScrollRaster,4
	PL_P	$212,.WriteChar
	PL_ORW	$34a+2,1<<9		; set Bplcon0 color bit
	PL_SA	$110,$118		; skip write to INTENA
	;PL_W	$22c+2,$180

	PL_PSA	$90,.SetCoords,$b0

	PL_END

; simple randomizing which is good enough for the starfield
.SetCoords
	bsr.b	.rnd
	move.b	d0,100(a2)

	bsr.b	.rnd
	move.b	d0,80(a2)

	bsr.b	.rnd
	move.b	d0,60(a2)

	bsr.b	.rnd
	move.b	d0,40(a2)

	bsr.b	.rnd
	move.b	d0,20(a2)

	bsr.b	.rnd
	move.b	d0,(a2)+

.rnd	ror.l	d0,d0
	addq.l	#5,d0
	rts



.ScrollRaster
	lea	$dff000,a6
	bsr	WaitBlit
	lea	$50000,a0
	add.w	#100*42,a0
	add.w	#20*42+40,a0		; end of area
	move.l	a0,$50(a6)		; BLTAPTR
	move.l	a0,$54(a6)		; BLTDPTR	
	move.w	#0,$64(a6)		; BLTAMOD
	move.w	#0,$66(a6)		; BLTDMOD
	move.l	#$29f00002,$40(a6)	; BLTCON0+1
	move.l	#$fffffff0,$44(a6)
	move.w	#(20<<6)|(336/16),$58(a6)
	rts


; a0.l: char
; d0.w: x position
; d1.w: y position
.WriteChar
	moveq	#0,d2
	move.b	(a0),d2
	sub.b	#" ",d2
	lea	.Font(pc),a2
	add.w	d2,a2

	lea	$50000+40+(42*101),a3

	moveq	#8-1,d7
.copy_char
	move.b	(a2),(a3)
	add.w	#472/8,a2
	add.w	#42,a3
	dbf	d7,.copy_char
	rts

.Font	DC.L	$00186C6C,$18003818,$0C300000,$00000003
	DC.L	$3C183C3C,$1C7E1C7E,$3C3C0000,$0C00303C
	DC.L	$7C18FC3C,$F8FEFE3C,$667E0EE6,$F082C638
	DC.L	$FC38FC3C,$7E66C3C6,$C3C3FE00,$3C6C6C3E
	DC.L	$C66C1818,$18661800,$00000666,$3866663C
	DC.L	$60306666,$66181818,$001866C6,$3C66666C
	DC.L	$66666666,$18066660,$C6E66C66,$6C66665A
	DC.L	$66C3C666,$C3C6003C,$00FE60CC,$6830300C
	DC.L	$3C180000,$000C6E18,$06066C7C,$60066666
	DC.L	$1818307E,$0C06DE3C,$66C06660,$60C06618
	DC.L	$066C60EE,$F6C666C6,$66701866,$66C63C66
	DC.L	$8C001800,$6C3C1876,$00300CFF,$7E007E00
	DC.L	$187E181C,$1CCC067C,$0C3C3E00,$00600006
	DC.L	$0CDE667C,$C0667878,$CE7E1806,$7860FEDE
	DC.L	$C67CC67C,$38186666,$D6183C18,$001800FE
	DC.L	$0630DC00,$300C3C18,$00000030,$76183006
	DC.L	$FE066618,$66060000,$30000C18,$DE7E66C0
	DC.L	$666060C6,$6618666C,$62D6CEC6,$60C66C0E
	DC.L	$18663CFE,$3C183200,$00006C7C,$66CC0018
	DC.L	$18661818,$00186066,$1866660C,$66661866
	DC.L	$0C181818,$7E1800C0,$C366666C,$66606666
	DC.L	$18666666,$C6C66C60,$6C666618,$663CEE66
	DC.L	$18660018,$006C18C6,$76000C30,$00001800
	DC.L	$18C03C7E,$7E3C1E3C,$3C183C38,$18180C00
	DC.L	$301878C3,$FC3CF8FE,$F03E667E,$3CE6FEC6
	DC.L	$C638F03C,$E33C3C3E,$18C6C33C,$FE000000
	DC.L	$00000000,$00000000,$00300000,$00000000
	DC.L	$00000000,$00000000,$30000000,$00000000
	DC.L	$00000000,$00000000,$00000000,$00000600
	DC.L	$00000000,$00000000




PL_BOOT	PL_START
	PL_R	$108e			; disable reset part
	PL_P	$1008,.loadgfx
	PL_R	$fde			; trackdisk, motor off
	PL_PSS	$1124,.loadparts,$114a-($1124+6)
	PL_PS	$b8,.runpart		; disk 1
	PL_PS	$232,.runpart		; disk 2
	PL_PSS	$da,.ChangeDisk,$1aa-($da+6)
	PL_P	$250,QUIT		; reset -> quit

	PL_ORW	$c50+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$134e+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$13e6+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$1402+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$1412+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$147a+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$148e+2,1<<9		; set bplcon0 colorbit

	PL_L	$288+2,$c000		; $faa000 -> $c000
	PL_END


; a3: start of part
.runpart
	lea	.TAB(pc),a0
	move.l	.offs(pc),d0
	clr.l	.offs-.TAB(a0)

.search	cmp.l	(a0)+,d0
	beq.b	.found
	addq.w	#2*2,a0
	bra.b	.search

.found	move.w	2(a0),d0		; offset to Decruncher
	move.l	a0,-(a7)
	jsr	2(a0,d0.w)		; call decruncher
	move.l	(a7)+,a0

	add.w	(a0),a0			; offset to patch list
	move.l	decaddr(pc),a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	move.l	jmpaddr(pc),a3

	jsr	(a3)
.skip	lea	$c00+$1100,a0		; original code
	rts

; offset.l, offset to patch list.w, decruncher type.w (see .DECTAB)

.TAB	dc.l	$DC00			; intro
	dc.w	PL_PART1-*
	dc.w	DECRUNCH0-*		; decruncher

	dc.l	$26800			; scrolly by exolon
	dc.w	PL_PART2-*
	dc.w	DECRUNCH1-*		; decruncher
	
	dc.l	$3C800			; blue demo by kaktus
	dc.w	PL_PART3-*
	dc.w	DECRUNCH0-*		; decruncher

	dc.l	$58000			; "stars are forever"
	dc.w	PL_PART4-*
	dc.w	DECRUNCH0-*		; decruncher

	dc.l	$68800			; scrolly by kaktus
	dc.w	PL_PART5-*
	dc.w	DECRUNCH0-*		; decruncher
	
	dc.l	$7BC00			; intro by black shadow
	dc.w	PL_PART6-*
	dc.w	DECRUNCH2-*

	dc.l	$91C00			; bobby demo by mahoney&kaktus
	dc.w	PL_PART7-*
	dc.w	DECRUNCH3-*		; decruncher

	dc.l	$AA800			; atom demo #4/ego demo
	dc.w	PL_PART8-*
	dc.w	DECRUNCH0-*		; decruncher

	dc.l	$CE400			; flummy intro by mahoney&kaktus
	dc.w	PL_PART9-*
	dc.w	DECRUNCH4-*		; decruncher


; disk 2
	dc.l	$B000			; flummy intro 2 mahoney&kaktus
	dc.w	PL_PART10-*
	dc.w	DECRUNCH4-*		; decruncher

	dc.l	$21000			; flummy mahoney&kaktus
	dc.w	PL_PART11-*
	dc.w	DECRUNCH4-*		; decruncher

	dc.l	$31800			; vector demo by black shadow
	dc.w	PL_PART12-*
	dc.w	DECRUNCH5-*
	
	dc.l	$4A400			; scrolly2 by mahoney&kaktus
	dc.w	PL_PART13-*
	dc.w	DECRUNCH4-*		; decruncher

	dc.l	$63000			; scrolly2 part2 by mahoney&kaktus
	dc.w	PL_PART14-*
	dc.w	DECRUNCH4-*		; decruncher

	dc.l	$79000			; progress by celebrandil
	dc.w	PL_PART15-*
	dc.w	DECRUNCH6-*		; decruncher

	dc.l	$94800			; vector demo by exolon
	dc.w	PL_PART16-*
	dc.w	DECRUNCH1-*		; decruncher

	dc.l	$A5000			; demo by black shadow
	dc.w	PL_PART17-*
	dc.w	DECRUNCH7-*		; decruncher

	DC.L	$C0800			; raytracing by celebrandil
	dc.w	PL_PART18-*	
	dc.w	DECRUNCH0-*		; decruncher

.offs	dc.l	0


.loadparts
	move.l	a0,-(a7)
	move.l	d6,d0
	lea	.offs(pc),a0
	tst.l	(a0)
	bne.b	.nope
	move.l	d6,(a0)
.nope	move.l	#$2c00,d1
	move.l	d5,a0
	bsr.b	.doload
	move.l	(a7)+,a0
	rts



.loadgfx
; demo loads this in 3 parts, we load it in one go
	move.l	#$2c00,d0
	move.l	#$2c00*3,d1
	lea	$10000,a0
.doload	moveq	#0,d2
	move.w	.Disk(pc),d2
	move.l	resload(pc),a1
	jmp	resload_DiskLoad(a1)
	
;	move.l	#$2c00,d0
;	move.l	d0,d1
;	lea	$10000,a0
;	bsr.b	.load
;	move.w	#$666,$dff180
;	move.l	#$5800,d0
;	move.l	#$2c00,d1
;	lea	$12c00,a0
;	bsr.b	.load
;	move.w	#$444,$dff180
;	move.l	#$8400,d0
;	move.l	#$2c00,d1
;	lea	$15800,a0
;	bsr.b	.load
;	move.w	#$222,$dff180
;	rts
;
;.load	move.l	resload(pc),a1
;	jmp	resload_DiskLoad(a1)


.ChangeDisk
	lea	.Disk(pc),a1
	addq.w	#1,(a1)
	rts

.Disk	dc.w	1


decaddr	dc.l	0
jmpaddr	dc.l	0

; a3: load address
DECRUNCH0

; get start of crunched data and destination address
	lea	jmpaddr(pc),a1
	move.l	6(a3),(a1)
	move.l	$16+2(a3),decaddr-jmpaddr(a1)		; decrunch to

	move.l	$a+2(a3),a0
	move.l	$10+2(a3),a1
	add.l	(a1),a0			; a0: end of decrunched data

CallTimeDecruncher
	move.l	decaddr(pc),a1



; a0: end of crunched data
; a1: destination
timedecruncher
	move.l	-(a0),a2
	add.l	a1,a2
	tst.l	-(a0)
	move.l	-(a0),d0
.loop	;move.b	($DFF006),($DFF181)

	moveq	#3,d1
	bsr.w	.getbits
	tst.w	d2
	beq.b	.next
	cmp.w	#7,d2
	bne.b	.enter
	lsr.l	#1,d0
	bne.b	.hasbit
	bsr.w	.nextbit
.hasbit	bcc.b	.lbC00005A
	moveq	#10,d1
	bsr.w	.getbits
	tst.w	d2
	bne.b	.enter
	moveq	#18,d1
	bsr.w	.getbits
	bra.b	.enter

.lbC00005A
	moveq	#4,d1
	bsr.w	.getbits
	addq.w	#7,d2

.enter	subq.w	#1,d2
.lbC000064
	moveq	#7,d1
.lbC000066
	lsr.l	#1,d0
	beq.b	.lbC000078
	addx.l	d3,d3
	dbf	d1,.lbC000066
	move.b	d3,-(a2)
	dbf	d2,.lbC000064
	bra.b	.next

.lbC000078
	move.l	-(a0),d0
	move.w	#$10,ccr
	roxr.l	#1,d0
	addx.l	d3,d3
	dbf	d1,.lbC000066
	move.b	d3,-(a2)
	dbf	d2,.lbC000064

.next	cmp.l	a2,a1
	bge.b	.exit

	moveq	#2,d1
	bsr.w	.getbits
	moveq	#2,d3
	moveq	#8,d1
	tst.w	d2
	beq.b	.lbC0000FA
	moveq	#4,d3
	cmp.w	#2,d2
	beq.b	.lbC0000E4
	moveq	#3,d3
	cmp.w	#1,d2
	beq.b	.lbC0000D6
	moveq	#2,d1
	bsr.b	.getbits
	cmp.w	#3,d2
	beq.b	.lbC0000CE
	cmp.w	#2,d2
	beq.b	.lbC0000C4
	addq.w	#5,d2
	move.w	d2,d3
	bra.b	.lbC0000E4

.lbC0000C4
	moveq	#2,d1
	bsr.b	.getbits
	addq.w	#7,d2
	move.w	d2,d3
	bra.b	.lbC0000E4

.lbC0000CE
	moveq	#8,d1
	bsr.b	.getbits
	move.w	d2,d3
	bra.b	.lbC0000E4

.lbC0000D6
	moveq	#8,d1
	lsr.l	#1,d0
	bne.b	.lbC0000DE
	bsr.b	.nextbit
.lbC0000DE
	bcs.b	.lbC0000FA
	moveq	#14,d1
	bra.b	.lbC0000FA

.lbC0000E4
	moveq	#16,d1
	lsr.l	#1,d0
	bne.b	.lbC0000EC
	bsr.b	.nextbit
.lbC0000EC
	bcc.b	.lbC0000FA

	moveq	#8,d1
	lsr.l	#1,d0
	bne.b	.lbC0000F6
	bsr.b	.nextbit
.lbC0000F6
	bcs.b	.lbC0000FA

	moveq	#12,d1
.lbC0000FA
	bsr.b	.getbits
	subq.w	#1,d3
.lbC0000FE
	move.b	-1(a2,d2.l),-(a2)
	dbf	d3,.lbC0000FE
	cmp.l	a2,a1
	blt.w	.loop
.exit	rts

.nextbit
	move.l	-(a0),d0
	move.w	#$10,ccr
	roxr.l	#1,d0
	rts

.getbits
	subq.w	#1,d1
	moveq	#0,d2
.bitsloop
	lsr.l	#1,d0
	beq.b	.nextlong
	addx.l	d2,d2
	dbf	d1,.bitsloop
	rts

.nextlong
	move.l	-(a0),d0
	move.w	#$10,ccr
	roxr.l	#1,d0
	addx.l	d2,d2
	dbf	d1,.bitsloop
	rts


; a3: start of crunched data
DECRUNCH1
	lea	$f0(a3),a0
	lea	$45000,a1
DECRUNCH11
	move.l	a1,a4
DECRUNCH12
	lea	decaddr(pc),a2
	move.l	a1,(a2)+
	move.l	a4,(a2)
	bra.w	ByteKillerDecrunch






; a3: start of crunched data
DECRUNCH2
	lea	decaddr(pc),a0
	move.l	$3c+2(a3),(a0)+		; decrunch to
	move.l	$12+2(a3),(a0)		; jmp


	jsr	$18(a3)
	
	move.l	$30+2(a3),a0
	move.l	$36+2(a3),a1
	add.l	(a1),a0			; a0: end of decrunched data

	bra.w	CallTimeDecruncher

; a3: start of crunched data
DECRUNCH3
	lea	$10c(a3),a0
	lea	$3c000,a1
	bra.b	DECRUNCH11

; a3: start of crunched data
DECRUNCH4
	lea	$e8(a3),a0
	move.l	$4+2(a3),a1		; decrunch to
	move.l	$aa+2(a3),a4		; jmp
	bra.b	DECRUNCH12

; a3: start of crunched data
DECRUNCH5
	move.w	#$4000,$dff09a
	;move.w	#$8240,$dff096		; enable blitter dma

	lea	decaddr(pc),a0
	move.l	$11e+2(a3),(a0)+	; decrunch to
	move.l	$11e+2(a3),(a0)		; jmp


	move.l	$112+2(a3),a0
	move.l	$118+2(a3),a1
	add.l	(a1),a0			; a0: end of decrunched data

	bra.w	CallTimeDecruncher

; a3: start of crunched data
DECRUNCH6
	lea	decaddr(pc),a0
	move.l	$28+2(a3),(a0)		; decrunch to
	move.l	(a0)+,(a0)		; jmp
	
	move.l	$1c+2(a3),a0
	move.l	$22+2(a3),a1
	add.l	(a1),a0			; a0: end of decrunched data

	bra.w	CallTimeDecruncher
	
; a3: start of crunched data
DECRUNCH7
	lea	decaddr(pc),a0
	move.l	$8+2(a3),(a0)		; decrunch to
	move.l	(a0)+,(a0)		; jmp
	
	lea	$134(a3),a0
	add.l	$130(a3),a0

	bra.w	CallTimeDecruncher


; intro
PL_PART1
	PL_START
	PL_P	$2f962,FixAudXVol
	PL_PSS	$2fa3c,FixDMAWait,2
	PL_PSS	$2f824,.speed,2
	PL_P	$2f98e,SetSpeed

	PL_ORW	$2f1b0+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$2f51c+2,1<<9		; set bplcon0 colorbit

	PL_W	$2f20e,$0839		; bchg #6,$bfe001 -> btst #6,$bfe001
	PL_SA	$2f222,$2f244		; skip gfxlib stuff

	PL_PS	$2f1e0,.setlev2

	PL_PS	$2f5aa,.waitblit

	PL_PS	$2fb32,FixAudXVol
	PL_END

.waitblit
	lea	$dff000,a0		; original code
	btst	#6,$2(a0)
.wblit	btst	#6,$2(a0)
	bne.b	.wblit
	rts
	
.setlev2
	move.w	#$c008,$9a(a0)		; enable level 2 irq
	move.w	#$87c0,$96(a0)		; original code
	rts

.speed	move.w	Speed(pc),d0
	cmp.w	$40000+$2fcae,d0
	rts

; scroller by exolon
PL_PART2
	PL_START
	PL_P	$37ec,FixAudXVol
	PL_PSS	$38c6,FixDMAWait,2
	PL_PSS	$36b0,.speed,2
	PL_P	$3818,SetSpeed

	PL_PSS	$3a,.waitraster,2
	PL_SA	$8c,$ae			; skip gfxlib stuff

	PL_P	$32c,.setDMA

	PL_B	$5336,$33		; move.l $dff006 -> move.w

	PL_PS	$1b74,.clip		; fix out of bounds blit in scroller
	PL_END

.clip	add.w	#25,d2
	and.l	#$ffff,d2
	move.l	d2,d0
	rts


.setDMA	move.w	#$83c0,$dff096
	move.w	#$c008,$dff09a		; enable level 2 irq
	rts

.waitraster
	move.l	$4(a5),d0
	and.l	#$1ff00,d0
	cmp.l	#$f8<<8,d0
	bne.b	.waitraster
	rts

.speed	move.w	Speed(pc),d0
	cmp.w	$45000+$3c1e,d0
	rts

; blue demo
PL_PART3
	PL_START
	PL_SA	$274,$27e		; skip copperlist restore
	PL_SA	$14090,$1409a		; skip copperlist restore
	PL_PSS	$14548,FixDMAWait,4	; fix DMA wait in replayer
	PL_P	$14738,FixAudXVol	; fix byte write to volume register
	PL_END

; "stars are forever" demo
PL_PART4
	PL_START
	PL_P	$1756e,.getkey
	PL_R	$174fe			; disable gfxlib stuff

	PL_P	$19344,FixAudXVol
	PL_PSS	$19432,FixDMAWait,2
	PL_PSS	$19208,.speed,2
	PL_P	$19370,SetSpeed

	PL_ORW	$17428+2,1<<9		; set bplcon0 colorbit
	PL_PS	$1745e,.setlev2
	PL_ORW	$17f92+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$18024+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$18042+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$1810e+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$1820c+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$183a8+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$18454+2,1<<9		; set bplcon0 colorbit

	PL_W	$174d4,$0839		; bchg #6,$bfe001 -> btst #6,$bfe001

	PL_PS	$174e4,.setCop		; set default copper before restoring DMA
	PL_END

.setCop	move.l	#$1000,$dff080
	rts



.setlev2
	move.w	#$c008,$9a(a0)		; enable level 2 irq
	move.w	#$83f0,$96(a0)		; original code
	rts

.speed	move.w	Speed(pc),d0
	cmp.w	$56000+$196b2,d0
	rts

.getkey	move.b	Key(pc),d0
	rts

; "scrolly" by kaktus
; plane ptrs set to: $ABBA :)
PL_PART5
	PL_START
	PL_PSS	$1acda,FixDMAWait,4
	PL_P	$1aeca,FixAudXVol
	PL_PSS	$1aa78,.speed,4
	PL_P	$1aee2,.setspeed

	PL_SA	$2210,$221a		; skip copperlist restore
	PL_SA	$261b2,$261bc		; skip copperlist restore

	
	PL_ORW	$2276+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$26208+2,1<<9		; set bplcon0 colorbit
	
	PL_W	$25272+2,$4000		; disable all interrupts
	PL_W	$261c4+2,$c000

	PL_PSS	$252a0,.setDMA,2
	PL_W	$26204+2,$f0-16		; fix OCS only DDFSTOP, part 1
	PL_W	$2272+2,$f0-16		; fix OCS only DDFSTOP, part 2

	PL_W	$44+2,$4000		; disable all interrupts
	PL_W	$222a+2,$c000
	

	PL_W	$261da,0		; clear $ABBA plane pointers
	PL_W	$261de,0
	PL_W	$261e2,0
	PL_W	$261e6,0
	PL_W	$261ea,0
	PL_W	$261ee,0

	PL_W	$2238,0
	PL_W	$223c,0
	PL_W	$2240,0
	PL_W	$2244,0
	PL_W	$2248,0
	PL_W	$224c,0

	PL_W	$2282+2,$40		; fix illegal Bplcon2 value

	PL_L	$76a+4,$dff064		; $dff6064 -> $dff064
	PL_END

.setDMA	move.w	#$81c1+1<<9,$dff096
	move.w	#0,$dff102
	move.w	#0,$dff104
	rts
	

	
.speed	moveq	#0,d0
	move.w	Speed(pc),d0
	cmp.l	$40000+$1af7e,d0
	rts

.setspeed
	and.w	#$f,d0
	bra.w	SetSpeed

; intro by black shadow
PL_PART6
	PL_START
	PL_P	$1c3a,FixAudXVol
	PL_PSS	$1d3c,FixDMAWait,2
	PL_PSS	$1afe,.speed,2
	PL_P	$1c66,SetSpeed

;	PL_PS	$1246,.rnd		; kickrom access for rnd
	PL_P	$f74,.waitblit		; fix buggy waitblit
	PL_PSS	$ac,.LMB,2		; fix buggy LMB check
	PL_R	$104c			; disable gfx lib access
	PL_P	$103a,.setDMA

	PL_ORW	$12b6+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$14ee+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$150e+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$1556+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$1822+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$1916+2,1<<9		; set bplcon0 colorbit

	PL_B	$2080+2,$10		; move.b (a1,d1.l),d2 -> (a1.d1.w)
	PL_L	$1246+2,$38000		; $f82000 -> $38000

	PL_W	$182a+2,$19		; fix OCS only DDFSTRT

	PL_P	$f1c,.wblit2		; fix glitch on fast machines
	PL_END

.wblit2	move.w	#$782,$dff058
	bra.w	WaitBlit

.setDMA	move.w	#$8100,$dff096
	move.w	#$4000,$dff09a
	move.w	#$c008,$dff09a		; enable level2 irq
	rts

.LMB	btst	#6,$bfe001		; was and.b #$40,$bfe001
	rts

.waitblit
	btst	#6,$dff002		; was: and.w #$4000,$dff002
.wblit	btst	#6,$dff002		; $dff002 is read only!
	bne.b	.wblit	
	rts

.speed	move.w	Speed(pc),d0
	cmp.w	$38000+$1fbe,d0
	rts


; bobby demo by mahoney&kaktus
PL_PART7
	PL_START
	PL_SA	$bc,$c6			; skip buggy copperlist restore

	PL_P	$271e2,FixAudXVol
	PL_PSS	$272bc,FixDMAWait,2
	PL_PSS	$270a6,.speed,2
	PL_P	$2720e,SetSpeed

	PL_PS	$1702,.waitblit
	PL_PS	$36,.setlev2

	PL_ORW	$1bc4+2,1<<9		; set Bplcon0 color bit
	PL_PS	$273b0,FixAudXVol	; fix byte write to volume register
	PL_END

.setlev2
	move.b	#2,$bfe001		; original code
	move.w	#$c008,$dff09a		; enable level 2 irq
	rts

.speed	move.w	Speed(pc),d0
	cmp.w	$3c000+$2752a,d0
	rts

.waitblit
	lea	$3c000+$178c,a6		; original code
	btst	#6,$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts

; atom demo #4/ego demo
PL_PART8
	PL_START
	
	PL_ORW	$375f4+2,1<<9		; set bplcon0 colorbit
	PL_P	$37678,.bplcon0
	PL_ORW	$3777c+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$379a6+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$37b12+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$37b86+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$35e90+2,1<<9		; set bplcon0 colorbit
	PL_P	$35eea,.bplcon0

	PL_P	$35bac,.getkey

	PL_P	$380f2,FixAudXVol
	PL_PS	$38310,FixAudXVol
	PL_PSS	$38214,FixDMAWait,2
	PL_PSS	$37fb4,.speed,2
	PL_P	$3811e,SetSpeed

	PL_SA	$35200,$35222		; skip gfx lib access

	PL_PSS	$35166,.waitraster,2
	PL_PSS	$351d2,.waitraster2,2

	PL_W	$351ea,$0839		; bchg #6,$bfe001 -> btst #6,$bfe001
	
	PL_SA	$3519e,$351a2
	PL_PS	$3514a,.setirq
	PL_PS	$35222,.remirq

	PL_PS	$351fa,.setCop		; set default copperlist before restoring DMA
	PL_END

.setCop	move.l	#$1000,$dff080
	rts

.speed	move.w	Speed(pc),d0
	cmp.w	$46000+$38492,d0
	rts

.remirq	lea	$dff000,a0
	move.w	#$7fff,d0
	move.w	d0,$9a(a0)
	move.w	d0,$96(a0)
	move.l	.oldlev3(pc),$6c.w
	rts

.setirq	lea	.lev3(pc),a1
	move.l	$6c.w,.oldlev3-.lev3(a1)
	move.l	a1,$6c.w
	move.w	#$87c0,$96(a0)
	move.w	#$c028,$9a(a0)
	rts

.lev3	movem.l	d0-a6,-(a7)
	jsr	$46000+$37faa	; mt_music
	move.w	#$20,$dff09c
	move.w	#$20,$dff09c
	movem.l	(a7)+,d0-a6
	rte	

.oldlev3	dc.l	0

.waitraster
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#250<<8,d0
	bne.b	.wait
	rts

.waitraster2
.wait2	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#250<<8,d0
	ble.b	.wait2
	rts

.bplcon0
	move.w	#$100,(a2)+
	move.w	#$0200,(a2)+
	rts

.getkey	move.b	Key(pc),d0
	rts

; flummy intro by mahoney&kaktus
PL_PART9
	PL_START
	PL_P	$127fc,FixAudXVol
	PL_PSS	$12640,FixDMAWait,2
	PL_PSS	$12498,.speed,4
	PL_P	$12838,.setspeed

	PL_ORW	$1157a+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$115d6+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$115de+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$115f2+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$115fa+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$11606+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$11632+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$11642+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$1164e+2,1<<9		; set bplcon0 colorbit

	PL_PSS	$14e,.setlev2,2

	PL_P	$1156c,.wait30
	;PL_SA	$1a0,$1aa		; skip buggy copperlist restore

	PL_PSS	$1a0,SetCop,4
	PL_END

.wait30	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#$30<<8,d0
	bne.b	.wait30
	rts

.setlev2
	move.w	#$4000,$dff09a
	move.w	#$c008,$dff09a
	rts
	

.speed	moveq	#0,d0
	move.w	Speed(pc),d0
	cmp.l	$48000+$128b0,d0
	rts

.setspeed
	and.w	#$f,d0
	bra.w	SetSpeed


SetCop	move.l	#$1000,$dff080
	rts

; flummy intro2 by mahoney&kaktus
PL_PART10
	PL_START

	PL_P	$1e48,FixAudXVol
	PL_PSS	$1f22,FixDMAWait,2
	PL_PSS	$1d0c,.speed,2
	PL_P	$1e74,SetSpeed

	PL_PSS	$24,.setlev2,2
	PL_SA	$4bc,$4d6		; skip gfxlib access

	PL_ORW	$1628+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$1674+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$16b4+2,1<<9		; set bplcon0 colorbit

	PL_SA	$a,$14			; don't set copperlist yet
	PL_PS	$11e,.setCop
	PL_W	$1c+2,$07ff		; don't enable DMA yet

	PL_PS	$2016,FixAudXVol	; fix byte write to volume register

	PL_W	$16b0+2,$f0-16		; fix OCS only ddfstop
	PL_END

.setCop	move.l	#$43000+$15f8,$dff080
	move.w	#$83c0,$dff096
	jmp	$43000+$1c6c		; mt_init


.speed	move.w	Speed(pc),d0
	cmp.w	$43000+$2190,d0
	rts


.setlev2
	move.w	#$4000,$dff09a		; original code
	move.w	#$c008,$dff09a		; enable level 2 irq
	rts

; flummy by mahoney&kaktus
PL_PART11
	PL_START
	PL_P	$452,FixAudXVol
	PL_PSS	$52c,FixDMAWait,2
	PL_PSS	$316,.speed,2
	PL_P	$47e,SetSpeed

	PL_SA	$92c,$946		; skip gfxlib access
	PL_PSS	$86,.setlev2,2

	PL_ORW	$19ea+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$2102+2,1<<9		; set bplcon0 colorbit

	PL_SA	$6c,$76			; don't set copperlist yet
	PL_W	$7e+2,$07ff		; don't enable DMA yet
	PL_PS	$124,.setCop
	PL_ORW	$20e2+2,1<<9		; set Bplcon0 color bit
	PL_PS	$620,FixAudXVol		; fix byte write to volume register
	PL_W	$19e6+2,$f0-16		; fix OCS only DDFSTOP	

	PL_END

.setCop	move.l	#$43000+$19be,$dff080
	move.w	#$83c0,$dff096
	jmp	$43000+$276		; mt_init



.setlev2
	move.w	#$4000,$dff09a		; original code
	move.w	#$c008,$dff09a		; enable level 2 irq
	rts

.speed	move.w	Speed(pc),d0
	cmp.w	$43000+$79a,d0
	rts

; vector demo by black shadow
PL_PART12
	PL_START
	PL_P	$4424,FixAudXVol
	PL_PSS	$4268,FixDMAWait,2
	PL_PSS	$40c2,.speed,4
	PL_P	$4460,.setspeed

	PL_SA	$20,$44			; skip exec/gfxlib access

	PL_P	$b4e,.waitblit		; fix buggy waitblit

	PL_SA	$bc,$c6			; skip exec access

	PL_ORW	$f6+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$176+2,1<<9		; set bplcon0 colorbit

	PL_PSS	$23a,.wtblit,2

	PL_PSS	$d6,.setlev2,2

	PL_L	$a10+2,$34000+$16a	; $f82000 -> $3416a (copperlist)
	PL_W	$1da+2,$19		; fix OCS only DDFSTRT
	PL_END

.setlev2
	move.w	#$c008,$dff09a		; enable level2 irq
	move.w	#$8020,$dff096		; original code
	rts

.wtblit	bsr.b	.waitblit
	move.w	#-1,$dff044		; original code
	rts

.waitblit
	btst	#6,$dff002		; was: and.w #$4000,$dff002
.wblit	btst	#6,$dff002		; $dff002 is read only!
	bne.b	.wblit	
	rts

.setspeed
	and.w	#$f,d0
	bra.w	SetSpeed
	
.speed	moveq	#0,d0
	move.w	Speed(pc),d0
	cmp.l	$34000+$44d8,d0
	rts


; scrolly2 by mahoney&kaktus
PL_PART13
	PL_START

	PL_P	$2c5a2,FixAudXVol
	PL_PSS	$2c67c,FixDMAWait,2
	PL_PSS	$2c466,.speed,2
	PL_P	$2c5ce,SetSpeed

	PL_ORW	$29e1e+2,1<<9		; set bplcon0 colorbit

	PL_SA	$297bc,$297c6		; skip buggy copperlist restore

	PL_PSS	$2972e,.setlev2,2

	PL_PS	$2c788,FixAudXVol	; fix byte write to volume register

; SMC: $299ee
	PL_END

.setlev2
	move.w	#$4000,$dff09a
	move.w	#$c008,$dff09a		; enable level 2 irq
	rts

.speed	move.w	Speed(pc),d0
	cmp.w	$4da00+$2c902,d0
	rts

; scrolly2 part2 by mahoney&kaktus
PL_PART14
	PL_START
	PL_P	$4bd6,FixAudXVol
	PL_PSS	$4cb0,FixDMAWait,2
	PL_PSS	$4a9a,.speed,2
	PL_P	$4c02,SetSpeed

	PL_PSS	$1540,.setlev2,2
	PL_SA	$1618,$1622		; skip buggy copperlist restore


	PL_ORW	$3df2+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$3e62+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$49de+2,1<<9		; set bplcon0 colorbit

	PL_PSS	$39b2,.wblit,2
	PL_PSS	$39f4,.wblit,2
	
	;PL_PSS	$1588,.waitraster,6
	PL_PSS	$184a,.wblit2,2
	PL_PSS	$39aa,.wblit3,2
	PL_PSS	$39ec,.wblit4,2
	PL_END

.wblit2	move.w	#$49e,$dff058
	bra.w	WaitBlit

.wblit3	move.w	#$6001,$dff058
	bra.w	WaitBlit

.wblit4	move.w	#$4801,$dff058
	bra.w	WaitBlit
	

.waitraster
	bsr	WaitRaster
	rts

.wblit	move.w	#$8400,$dff096
	bra.w	WaitBlit

.setlev2
	move.w	#$4000,$dff09a
	move.w	#$c008,$dff09a		; enable level 2 irq
	rts

.speed	move.w	Speed(pc),d0
	cmp.w	$4b000+$4f1e,d0
	rts

; progress by celebrandil
PL_PART15
	PL_START
	PL_SA	$0,$26			; skip exec/gfx access
	PL_PSS	$c90,FixDMAWait,4
	PL_P	$384,AckVBI
	PL_R	$37e

;	PL_PSS	$10e,.wlinec0,2
;	PL_PSS	$142,.wlinec0,2
;	PL_PSS	$164,.wlinec0,2
;	PL_PSS	$142,.wlinec0,2
;	PL_PSS	$1fc,.wlinec0,2
;
;	PL_PSS	$296,.wlineaa,2

	PL_PSS	$64,.setlev2,2
	
	PL_SA	$e4,$ee			; skip exec access

	PL_SA	$6c,$76

	PL_R	$a5e
	PL_SA	$a9a,$aac


	PL_W	$22ee+2,0
	PL_W	$22f2+2,0
	
	PL_W	$1f12+2,0
	PL_W	$1f16+2,0


	PL_PSS	$1da,.setlev3,4

	PL_ORW	$1f86+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2046+2,1<<9		; set Bplcon0 color bit
	PL_L	$10a,$1000		; OldCop -> $1000	
	PL_PSS	$ba,.remVBI,4
	PL_END

.remVBI	lea	AckVBI(pc),a0
	move.l	a0,$6c.w
	rts

.setlev3
	lea	.lev3(pc),a0
	move.l	a0,$6c.w
	move.w	#$c020,$dff09a
	rts

.lev3	movem.l	d0-a6,-(a7)
	jsr	$35000+$348
	movem.l	(a7)+,d0-a6
	bra.w	AckVBI

.wlinec0
.wline	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#192<<8,d0
	;bne.b	.wline
	rts

.wlineaa
	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#$aa<<8,d0
	;bne.b	.wlineaa
	rts

.setlev2
	move.w	#$8180,$dff096		; original code
	move.w	#$c008,$dff09a		; enable level 2 irq
	rts

; vector demo by exolon
PL_PART16
	PL_START
	PL_P	$38b6,FixAudXVol
	PL_P	$38e2,SetSpeed
	PL_PSS	$377a,.speed,2
	PL_PSS	$3992,FixDMAWait,2

	PL_SA	$74,$96			; skip gfxlib access
	PL_PSS	$1c,.setlev2,2

	PL_B	$efa,$33		; move.l $dff006 -> move.w
	PL_PSS	$f0a,.wblit,2
	PL_PS	$2c52,.wblit2
	PL_PS	$2c5a,.wblit3
	PL_PS	$3ac8,FixAudXVol	; fix byte write to volume register
	PL_END

.wblit	bsr	WaitBlit
	move.w	#$ffff,$dff044
	rts

.wblit2	bsr	WaitBlit
	move.w	#$0100,$40(a5)
	rts

.wblit3	bsr	WaitBlit
	move.w	#$09f0,$40(a5)
	rts

.setlev2
	move.w	#$4000,$dff09a		; original code
	move.w	#$c008,$dff09a		; enable level 2 irq
	rts
	

.speed	move.w	Speed(pc),d0
	cmp.w	$45000+$3c42,d0
	rts


; demo by black shadow
PL_PART17
	PL_START

;	PL_PS	$194,.rnd		; $f82000
	PL_P	$5e6,.waitblit		; fix buggy waitblit
	PL_PSS	$2e2,.setlev2,2

	PL_PSS	$f2e8,FixDMAWait,4
	PL_SA	$2f8,$318		; skip gfxlib access


	PL_ORW	$d32+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$dfa+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$e56+2,1<<9		; set bplcon0 colorbit

	PL_L	$194+2,$30000+$d86	; $f82000 -> $30d86 (copperlist)

	PL_PSA	$60,.WaitRaster,$6e


	PL_END


.WaitRaster
.s	btst	#0,$dff005
	beq.b	.s
.s2	btst	#0,$dff005
	bne.b	.s2
	rts
	


.setlev2
	move.w	#$4000,$dff09a		; original code
	move.w	#$c008,$dff09a		; enable level 2 irq
	rts


.waitblit
	btst	#6,$dff002		; was: and.w #$4000,$dff002
.wblit	btst	#6,$dff002		; $dff002 is read only!
	bne.b	.wblit	
	rts


; end part (raytracing) by celebrandil
PL_PART18
	PL_START
	PL_SA	$4,$2a			; skip exec/gfxlib access
	PL_PSS	$1cae,FixDMAWait,4
	PL_SA	$b6,$c0			; skip exec/gfxlib access

	PL_PSS	$34,.setlev2,2

	PL_ORW	$272+2,1<<9		; set bplcon0 colorbit
	PL_ORW	$27e+2,1<<9		; set bplcon0 colorbit

	PL_PSS	$54,.waitline80,6

	PL_PS	$ee,.wblit
	PL_W	$27a+2,$f0-16		; fix OCS only DDFSTOP
	PL_L	$e4,$1000		; OldCop -> $1000
	PL_END

.wblit	lea	$78000,a1
	bra.w	WaitBlit

.setlev2
	move.w	#$4000,$dff09a		; original code
	move.w	#$c008,$dff09a		; enable level 2 irq
	rts

.waitline80
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#80<<8,d0
	bne.b	.wait
	rts


WaitBlit
	tst.b	$dff002
.wblit	btst	#6,$dff002
	bne.b	.wblit
	rts

WaitRaster
	move.l	d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.b	.wait
	move.l	(a7)+,d0
	rts

WaitRasterEnd
	move.l	d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	beq.b	.wait
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

FixAudXVol
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	3(a6),d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts

SetSpeed
	move.l	d0,-(a7)
	lea	Speed(pc),a0
	move.w	d0,(a0)
	move.l	(a7)+,a0
	rts

Speed	dc.w	6

AckVBI	move.w	#1<<4|1<<5|1<<6,$dff09c
	move.w	#1<<4|1<<5|1<<6,$dff09c
	rte


***********************************
** Level 2 IRQ			***
***********************************

SetLev2IRQ
	pea	.int(pc)
	move.l	(a7)+,$68.w

	move.b	#1<<7|1<<3,$bfed01		; enable keyboard interrupts
	tst.b	$bfed01				; clear all CIA A interrupts
	and.b	#~(1<<6),$bfee01		; set input mode

	move.w	#1<<3,$dff09c			; clear ports interrupt
	move.w	#1<<15|1<<14|1<<3,$dff09a	; and enable it
	rts

.int	movem.l	d0-d1/a0-a2,-(a7)
	lea	$dff000,a0
	lea	$bfe001,a1

	lea	Key(pc),a2
	clr.b	(a2)

	btst	#3,$1e+1(a0)			; PORTS irq?
	beq.b	.end
	btst	#3,$d00(a1)			; KBD irq?
	beq.b	.end

	move.b	$c00(a1),d0
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)
	or.b	#1<<6,$e00(a1)			; set output mode

.nodebug
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	.exit
	

	moveq	#3-1,d1
.loop	move.b	$6(a0),d0
.wait	cmp.b	$6(a0),d0
	beq.b	.wait
	dbf	d1,.loop


	and.b	#~(1<<6),$e00(a1)	; set input mode
.end	move.w	#1<<3,$9c(a0)
	move.w	#1<<3,$9c(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte

.exit	pea	(TDREASON_OK).w
.quit	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

KeyFlag	dc.b	0
Key	dc.b	0


***********************************
** Bytekiller 2.0 Decruncher	***
***********************************

; a0: start of crunched data
; a1: destination
; normal bytekiller 2.0 decruncher

ByteKillerDecrunch


; Bytekiller decruncher
; resourced and adapted by stingray
;
BK_DECRUNCH
	bsr.b	.decrunch
	tst.l	d5
	beq.b	.ok

; checksum doesn't match, file corrupt
	pea	.ErrTxt(pc)
	pea	(TDREASON_FAILMSG).w
	bra.w	EXIT

.ok	rts

.ErrTxt	dc.b	"Decrunching failed, file corrupt!",0
	cnop	0,4

.decrunch
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	move.l	(a0)+,d5
	move.l	a1,a2
	add.l	d0,a0
	add.l	d1,a2
	move.l	-(a0),d0
	eor.l	d0,d5
.loop	lsr.l	#1,d0
	bne.b	.nonew1
	bsr.b	.nextlong
.nonew1	bcs.b	.getcmd

	moveq	#8,d1
	moveq	#1,d3
	lsr.l	#1,d0
	bne.b	.nonew2
	bsr.b	.nextlong
.nonew2	bcs.b	.copyunpacked

; data is packed, unpack and copy
	moveq	#3,d1			; next 3 bits: length of packed data
	clr.w	d4

; d1: number of bits to get from stream
; d4: length
.packed	bsr.b	.getbits
	move.w	d2,d3
	add.w	d4,d3
.copypacked
	moveq	#8-1,d1
.getbyte
	lsr.l	#1,d0
	bne.b	.nonew3
	bsr.b	.nextlong
.nonew3	roxl.l	#1,d2
	dbf	d1,.getbyte

	move.b	d2,-(a2)
	dbf	d3,.copypacked
	bra.b	.next

.ispacked
	moveq	#8,d1
	moveq	#8,d4
	bra.b	.packed

.getcmd	moveq	#2,d1			; next 2 bits: command
	bsr.b	.getbits
	cmp.b	#2,d2			; %10: unpacked data follows
	blt.b	.notpacked
	cmp.b	#3,d2			; %11: packed data follows
	beq.b	.ispacked

; %10
	moveq	#8,d1			; next byte:
	bsr.b	.getbits		; length of unpacked data
	move.w	d2,d3			; length -> d3
	moveq	#12,d1
	bra.b	.copyunpacked

; %00 or %01
.notpacked
	moveq	#9,d1
	add.w	d2,d1
	addq.w	#2,d2
	move.w	d2,d3

.copyunpacked
	bsr.b	.getbits		; get offset (d2)
;.copy	subq.w	#1,a2
;	move.b	(a2,d2.w),(a2)
;	dbf	d3,.copy

; optimised version of the code above
	subq.w	#1,d2
.copy	move.b	(a2,d2.w),-(a2)
	dbf	d3,.copy

.next	cmp.l	a2,a1
	blt.b	.loop
	rts

.nextlong
	move.l	-(a0),d0
	eor.l	d0,d5
	move.w	#$10,ccr
	roxr.l	#1,d0
	rts

; d1.w: number of bits to get
; ----
; d2.l: bit stream

.getbits
	subq.w	#1,d1
	clr.w	d2
.getbit	lsr.l	#1,d0
	bne.b	.nonew
	move.l	-(a0),d0
	eor.l	d0,d5
	move.w	#$10,ccr
	roxr.l	#1,d0
.nonew	addx.l	d2,d2
	dbf	d1,.getbit
	rts





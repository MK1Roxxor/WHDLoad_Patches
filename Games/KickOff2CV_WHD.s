***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(        KICK OFF 2 WHDLOAD SLAVE            )*)---.---.   *
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

; 17-Mar-2020	- decrypter didn't handle V1.6e version, fixed
;		- PL_NEXT approach added yesterday caused bugs, reverted
;		  back to "normal" patch lists and added optional second
;		  patch list support in decrypter

; 16-Mar-2020	- new generic decrypter for all versions
;		- accidentally left-in debug code in WaitRaster routine
;		  removed
;		- WHDLoad v17+ features really enabled now (ws_version
;		  was still set to 10)

; 01-May-2018	- generic COBRA X-ROM decrypter used now, works for all
;		  versions and no decryption tables needed anymore, also
;		  much easier to support new versions should there still
;		  be unsupported versions left
;		- WHDLoad v17+ features used (config)
;		- NTSC compatible VBL wait in quit routine

; 04-Apr-2013	- keyboard delay fixed (bne vs beq)
;		- buggy "movep" raster wait fixed 

; 30-Jan-2012	- support for 1.6g  version added, thanks to
;		  Irek for the disk image
;		- bug in generic competition version support
;		  fixed, introduced when I added the KOCV ID check
;		- size optimised the code a bit, d4 is not needed
;		  for the decrypter

; 04-Dec-2011	- check for KOCV ID, all future competition versions
;		  should now be supported automagically, greetings
;		  to Steve Camber

; 03-Dec-2011	- source can be assembled case sensitive now
;		- support for Competition versions 1.05, 1.06
;		  and 1.07 added

; 27-Mar-2010	- support for Competition version 1.04 added
;		- simplified the patch for the Competition version,
;		  code searches for the cache stuff and skips it,
;		  should now support any future version automagically
;		  as long as the bootblock is not changed

; 09-Jan-2010	- Player Manager teams can now be loaded

; 30-Dec-2009	- fixed support for Competition version 1.03
;		  the cache stuff was incorrectly patched
;		  (wrong offset used)

; 28-Dec-2009	- support for Competition version 1.03 added

; 17-May-2009	- support for v1.6f added, thanks to Xavier Bodénand
;		  for the disk image
;		- quit key fixed for SPS2573/2574, wrong offsets
;		  for the rawkey used, thanks to lolafg for reporting

; 18-Mar-2009	- finally found and fixed the f*cking "Game hangs
;		  after foul" problem that was reported by lolafg,
;		  apparently the game didn't like cleared memory
;		  in the $0-$1000.w area, adapted the CreateDataDisk
;		  routine accordingly

; 16-Mar-2009	- support for french WC'90 version added (dlfrsilver)
;		- irq's/dma are now disabled after quit key has been
;		  been pressed, this fixes the problem with the
;		  game freezing after quit key has been pressed,
;		  reported by lolafg
;		- separate tactics disks supported, must be named disk.8
;		- fixed bug in checksum patches for 1.6e version
;		  ($34e6 vs. $34ea, crash when loading tactics)

; 14-Mar-2009	- minor problem with the quitkey fixed, uses
;		  ws_KeyExit instead of QUITKEY constant now

; 11-Mar-2009	- support for SPS 0853 fixed, didn't work due to wrong
;		  PLIST (uses almost same offsets as 2573, not 0689) 
;		  thanks to AxelFoley and lolafg for reporting

; 10-Mar-2009	- support for 1.6e (SPS2191) added, only version
;		  that needs extended memory

; 09-Mar-2009	- started to add support for other versions, added
;		  support for SPS 0689 (German ver.+WC90)
;		- version check adapted, bootblock is used for checking
;		  version now
;		- support for SPS 0853 added (same offsets as SPS 0689)
;		- support for SPS 2573 added (ital. vers. +WC90)
;		- support for SPS 0168 added (almost same offsets as SPS 2573)
;		- support for SPS 1270 added (almost same offsets as SPS 0689)
;		- support for SPS 0760 added (same as compet. version)
;		- support for SPS 1245 added (almost same offsets as SPS 0760)
;		- support for SPS 2574 added (almost same offsets as SPS 0760)
;		- support for SPS 2507 added (almost same offsets as SPS 0760)


; 08-Mar-2009	- disabled the "insert disk" requesters
;		- support for 68000 quitkey added
;		- some unused code removed
;		- if no data disk is found it is created before
;		  starting the game, can be disabled with CUSTOM1
;		  tooltype

; 07-Mar-2009	- fixed little problem with saving replays,
;		  thanks to lolafg on EAB for reporting

; 05-Mar-2009	- added support for data disks (load/save),
;		  loading/saving teams and replays seems to work
;		  fine
;		

; 02-Mar-2009	- work started
;		- "forgotten" checksum check removed, loader patched,
;		  access fault fixed, invalid copperlist entry 
;		  fixed etc.
;		- patch worked at first try, scary or what? :D


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_EmulTrap
DEBUGKEY	= $58		; F9
QUITKEY		= $46		; DEL
DEBUG



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
	dc.b	0		; ws_keydebug
	dc.b	QUITKEY		; ws_keyexit
	dc.l	524288		; ws_ExpMem
	dc.w	.name-HEADER	; ws_name
	dc.w	.copy-HEADER	; ws_copy
	dc.w	.info-HEADER	; ws_info
; v16
	dc.w	0		; ws_kickname
	dc.l	0		; ws_kicksize
	dc.w	0		; ws_kickcrc

; v17
	dc.w	.config-HEADER	; ws_config


.config	dc.b	"C1:B:Don't create Data Disk"
	dc.b	0

	IFD	DEBUG
.dir	dc.b	"SOURCES:WHD_Slaves/KickOff2_CV/",0
	ENDC
.name	dc.b	"Kick Off 2",0
.copy	dc.b	"1990 Anco",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	dc.b	"Version 1.09a (17.03.2020)",0
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


; clear memory (so we can create "clean" data disk if needed)
	lea	$1000.w,a0
	lea	$30000,a1
.clear	clr.l	(a0)+
	cmp.l	a0,a1
	bne.b	.clear


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
	cmp.w	#$0164,d0		; Kick Off 2 Competition Version
	beq.w	.ok
	lea	PL_BOOT103(pc),a0
	cmp.w	#$8f10,d0		; Competition version 1.03/1.04
	beq.w	.ok
	cmp.w	#$446,d0		; Competition version 1.05/1.06
	beq.w	.ok
	cmp.w	#$f350,d0		; Competition version 1.07
	beq.w	.ok
	lea	PL_BOOTGER1(pc),a0
	cmp.w	#$0E6D,d0		; ger. ver. + WC90
	beq.w	.ok
	lea	PL_BOOTGER2(pc),a0
	cmp.w	#$F70B,d0		; ger. ver.2 + WC90
	beq.w	.ok
	lea	PL_BOOTITA(pc),a0
	cmp.w	#$76CB,d0		; ital. ver. + WC90
	beq.w	.ok
	lea	PL_BOOTENG(pc),a0
	cmp.w	#$518e,d0		; eng. ver. + WC90
	beq.b	.ok
	lea	PL_BOOTENG2(pc),a0
	cmp.w	#$5492,d0		; eng. ver2. + WC90
	beq.b	.ok
	lea	PL_BOOT14E(pc),a0
	cmp.w	#$5b5e,d0		; v 1.4e
	beq.b	.ok
	lea	PL_BOOT14G(pc),a0
	cmp.w	#$5ca7,d0		; v 1.4g
	beq.b	.ok
	lea	PL_BOOT14I(pc),a0
	cmp.w	#$3e7d,d0		; v 1.4i
	beq.b	.ok
	lea	PL_BOOT14S(pc),a0
	cmp.w	#$932b,d0		; v 1.4s
	beq.b	.ok
	lea	PL_BOOT16E(pc),a0
	cmp.w	#$CE6f,d0		; v 1.6e
	beq.b	.ok
	lea	PL_BOOT16G(pc),a0
	cmp.w	#$c225,d0		; v 1.6g Irek
	beq.b	.ok
	lea	PL_BOOTFR(pc),a0	; french version + WC90
	cmp.w	#$F214,d0
	beq.b	.ok
	lea	PL_BOOT14F(pc),a0	; v 1.6f
	cmp.w	#$33c0,d0
	beq.b	.ok

; no known version, check if it's a Competition version
	lea	PL_BOOTKOCV(pc),a0
	lea	$400-8(a5),a1
	cmp.l	#"KOCV",(a1)+
	bne.b	.unknown
	move.l	(a1),CacheOffset-PL_BOOTKOCV(a0)
	bra.b	.ok

; unknown version
.unknown
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT

.ok


; patch it
	;lea	PL_BOOT(pc),a0
	move.l	a5,a1
	lea	CodeStart(pc),a3
	move.l	$e2+2(a1),(a3)
	jsr	resload_Patch(a2)
	
; load crypted main file
	move.l	#$1600,d0
	;move.l	#$1c200,d1
	move.l	#$22400,d1
	moveq	#1,d2
	lea	$30000,a0
	jsr	resload_DiskLoad(a2)


	move.l	NODATADISK(pc),d0
	bne.b	.nodatadisk
	bsr	CreateDataDisk		; create data disk if it doesn't exist
.nodatadisk


	jmp	$76(a5)

QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	jmp	resload_Abort(a2)


CacheOffset	dc.l	0	; offset to cache disable routine (KOCV)
CodeStart	dc.l	0	; start address of code

*******************************************
** COMPETITION VERSION			***
*******************************************

PL_BOOT	PL_START
	PL_P	$102,.patch
	PL_END


.patch	move.l	a0,-(a7)
	lea	PL_GAME(pc),a0
	lea	$5300.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	move.l	(a7)+,a0
	jmp	$5300.w


PL_GAME	PL_START
	PL_S	$19650,$1967E-$19650	; skip cache stuff
	PL_NEXT	PL_GAMECV



*******************************************
** COMPETITION VERSION	1.03/1.04	***
*******************************************

PL_BOOT103
	PL_START
	PL_P	$102,.patch
	PL_END


.patch	move.l	a0,-(a7)

; search for move.l $4.w,a0 to find the cache stuff 
	lea	$5300+$19000,a0
.search	cmp.w	#$2078,(a0)+
	bne.b	.search
	cmp.w	#4,(a0)
	bne.b	.search

	subq.w	#2,a0
	move.w	#$60<<8+38-2,(a0)

	lea	PL_GAMECV(pc),a0
	lea	$5300.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	move.l	(a7)+,a0
	jmp	$5300.w


*******************************************
** COMPETITION VERSION	(generic)	***
*******************************************

PL_BOOTKOCV
	PL_START
	PL_P	$102,.patch
	PL_END

.patch	move.l	a0,-(a7)
	move.l	CacheOffset(pc),d0
	lea	PL_GAMECV(pc),a0
	lea	$5300.w,a1
	move.w	#$4e75,(a1,d0.l)	; disable Cache disable routine
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	move.l	(a7)+,a0
	jmp	$5300.w


PL_GAMECV
	PL_START
	PL_P	$f0fa,LOADER

; disable checksum checks
	PL_B	$89a2,$60

	PL_R	$FE34			; Forbid
	PL_R	$FE46			; Permit
	PL_P	$FE8C,Colors		; fix access fault


	PL_PS	$B498,.cop		; fix invalid copperlist entry


; patch disk change
	PL_W	$F788,$4e71
	PL_W	$F7BC,$4e71
	PL_W	$F7F0,$4e71
	;PL_B	$f7f0,$60
	PL_W	$F84e,$4e71


	;PL_PS	$F966,.changedisk

	PL_PS	$3D66,.changedisk
	PL_W	$3D66+6,$4e71

; disable "insert disk" requesters
	PL_S	$10A2,6			; "insert data disc"
	PL_S	$168A,6			; "insert data disc"
	PL_S	$26ea,6			; "insert data disc"
	PL_S	$29b4,6			; "insert data disc"
	PL_S	$35c4,6			; "insert data disc"
	PL_S	$3e48,6			; "insert data disc"
	PL_S	$3f2c,6			; "insert data disc"
	PL_S	$3fcc,6			; "insert data disc"
	PL_S	$428c,6			; "insert data disc"
	PL_S	$432a,6			; "insert data disc"
	PL_S	$43d6,6			; "insert data disc"

	PL_S	$95e0,6			; "insert program disc"
	PL_S	$AE74,6			; "insert program disc"

	PL_S	$4a1c,$4a30-$4a1c	; "insert action replay data disc"
	PL_S	$4a5c,$4A70-$4a5c	; "insert action replay data disc"
	


; enable quit on 68000 machines
	PL_PS	$109d6,.key

	PL_END


.changedisk
	lea	$5300+$157e0,a2
	bra.w	DiskChange

.cop	move.l	#$5300+$13976,$dff084
	move.w	#$8380,$dff096
	rts


.key	move.b	$5300+$18c6a,d1
	bra.w	Keys






*******************************************
** GERMAN VERSION + WC'90 (SPS 0689)	***
*******************************************

PL_BOOTGER1
	PL_START
	PL_P	$E2,.patch
	PL_END

.patch
	lea	PL_GER1(pc),a1
	sub.l	a2,a2			; no common patch list
	bra.w	DecryptAndPatch



PL_GER1	PL_START

; disable disk checks
	PL_S	$1DA,210
	PL_S	$BC20,210	
	PL_S	$A392,210

; disable checksum checks
	PL_B	$426e,$60
	PL_B	$f4a6,$60
	PL_L	$ea7c,$4e714e71
	PL_B	$5844,$60
	PL_B	$9742,$60
	PL_L	$459a,$4e714e71


; patch disk change
	PL_W	$10528,$4e71
	PL_W	$1055C,$4e71
	PL_W	$10590,$4e71
	PL_W	$105EE,$4e71
	
	PL_PS	$4B06,.changedisk
	PL_W	$4B06+6,$4e71


; disable "insert disk" requesters
	PL_S	$10CA,6			; "insert data disc"
	PL_S	$16B2,6			; "insert data disc"
	PL_S	$24A2,6			; "insert data disc"
	PL_S	$348a,6			; "insert data disc"
	PL_S	$3754,6			; "insert data disc"
	PL_S	$4364,6			; "insert data disc"
	PL_S	$4Be8,6			; "insert data disc"
	PL_S	$4CCC,6			; "insert data disc"
	PL_S	$4D6C,6			; "insert data disc"
	PL_S	$502C,6			; "insert data disc"
	PL_S	$50CA,6			; "insert data disc"
	PL_S	$5176,6			; "insert data disc"

	PL_S	$A380,6			; "insert program disc"
	PL_S	$BC14,6			; "insert program disc"

	PL_S	$57BC,$57D0-$57BC	; "insert action replay data disc"
	PL_S	$57FC,$5810-$57FC	; "insert action replay data disc"



	PL_P	$FE9A,LOADER

; enable quit on 68000 machines
	PL_PS	$11776,.key

	PL_R	$10BD4			; Forbid()
	PL_R	$10BE6			; Permit
	PL_P	$10C2C,Colors		; fix access fault

	PL_PS	$C238,.cop		; fix invalid copperlist entry
	PL_END


.changedisk
	lea	$5300+$173F6,a2
	bra.w	DiskChange

.cop	move.l	#$5300+$14BBE,$dff084
	move.w	#$8380,$dff096
	rts

.key	move.b	$5300+$1a880,d1
	bra.w	Keys




*******************************************
** GERMAN VERSION2 + WC'90 (SPS 0853)	***
*******************************************

PL_BOOTGER2
	PL_START
	PL_P	$E2,.patch
	PL_END

.patch	lea	PL_GER2(pc),a1
	lea	PL_ITA(pc),a2	; same offsets as SPS 2573

	bra.w	DecryptAndPatch


PL_GER2	PL_START

; enable quit on 68000 machines
	PL_PS	$1164A,.key

	PL_PS	$4AA4,.changedisk
	PL_W	$4AA4+6,$4e71

	PL_PS	$C11C,.cop		; fix invalid copperlist entry
	PL_END



.cop	move.l	#$5300+$14a90,$dff084
	move.w	#$8380,$dff096
	rts

.changedisk
	lea	$5300+$172c8,a2
	bra.w	DiskChange

.key	move.b	$5300+$1a6fe,d1
	bra.w	Keys



*******************************************
** ITALIAN VERSION + WC'90 (SPS 2573)	***
*******************************************

PL_BOOTITA
	PL_START
	PL_P	$E2,.patch
	PL_END

.patch	lea	PL_ITA(pc),a1
	sub.l	a2,a2
	bra.w	DecryptAndPatch



PL_ITA	PL_START

; disable disk checks
	PL_S	$1DA,210
	PL_S	$A272,210	
	PL_S	$BB04,210

; disable checksum checks
	PL_B	$420c,$60
	PL_B	$f38a,$60
	PL_L	$e960,$4e714e71
	PL_B	$5762,$60
	PL_B	$9622,$60
	PL_L	$4538,$4e714e71


; patch disk change
	PL_W	$1040c,$4e71
	PL_W	$10440,$4e71
	PL_W	$10474,$4e71
	PL_W	$104d2,$4e71
	
	PL_PS	$4AA4,.changedisk
	PL_W	$4AA4+6,$4e71


; disable "insert disk" requesters
	PL_S	$10CA,6			; "insert data disc"
	PL_S	$16B2,6			; "insert data disc"
	PL_S	$24A6,6			; "insert data disc"
	PL_S	$3434,6			; "insert data disc"
	PL_S	$36fe,6			; "insert data disc"
	PL_S	$4302,6			; "insert data disc"
	PL_S	$4B82,6			; "insert data disc"
	PL_S	$4C66,6			; "insert data disc"
	PL_S	$4D06,6			; "insert data disc"
	PL_S	$4f62,6			; "insert data disc"
	PL_S	$4ff8,6			; "insert data disc"
	PL_S	$50A4,6			; "insert data disc"

	PL_S	$A260,6			; "insert program disc"
	PL_S	$BAf8,6			; "insert program disc"

	PL_S	$56DA,$56EE-$56DA	; "insert action replay data disc"
	PL_S	$571a,$572e-$571a	; "insert action replay data disc"



	PL_P	$FD7E,LOADER

; enable quit on 68000 machines
	PL_PS	$1164a,.key

	PL_R	$10AB8			; Forbid()
	PL_R	$10ACA			; Permit
	PL_P	$10B10,Colors		; fix access fault

	PL_PS	$C11C,.cop		; fix invalid copperlist entry
	PL_END


.changedisk
	lea	$5300+$1730e,a2
	bra.w	DiskChange

.cop	move.l	#$5300+$14728,$dff084
	move.w	#$8380,$dff096
	rts

.key	move.b	$1fa44,d1		; absolute!
	bra.w	Keys


*******************************************
** ENGLISH VERSION + WC'90 (SPS 0168)	***
*******************************************

PL_BOOTENG
	PL_START
	PL_P	$E2,.patch
	PL_END

.patch	lea	PL_ENG(pc),a1
	lea	PL_ITA(pc),a2	; same offsets as ita. version (SPS 2573)
	bra.w	DecryptAndPatch


PL_ENG	PL_START

; enable quit on 68000 machines
	PL_PS	$1164a,.key
	
	PL_PS	$4AA4,.changedisk
	PL_W	$4AA4+6,$4e71
	PL_END


.changedisk
	lea	$5300+$16f60,a2
	bra.w	DiskChange

.key	move.b	$5300+$1a396,d1
	bra.w	Keys


*******************************************
** ENGLISH VERSION + WC'90 (SPS 1270)	***
*******************************************

PL_BOOTENG2
	PL_START
	PL_P	$E2,.patch
	PL_END

.patch	lea	PL_ENG2(pc),a1
	lea	PL_GER1(pc),a2	; same offsets as ger version (SPS 0689)
	bra.w	DecryptAndPatch

PL_ENG2	PL_START

; enable quit on 68000 machines
	PL_PS	$11776,.key

	PL_PS	$4B06,.changedisk
	PL_W	$4B06+6,$4e71

	PL_PS	$C238,.cop	; fix invalid copperlist entry
	PL_END




.cop	move.l	#$5300+$14866,$dff084
	move.w	#$8380,$dff096
	rts

.changedisk
	lea	$5300+$1709e,a2
	bra.w	DiskChange

.key	move.b	$5300+$1a528,d1
	bra.w	Keys



*******************************************
** V1.4E 		(SPS 0760)	***
*******************************************

PL_BOOT14E
	PL_START
	PL_P	$E2,.patch
	PL_END

.patch	lea	PL_14E(pc),a1
	sub.l	a2,a2
	bra.w	DecryptAndPatch



PL_14E	PL_START


; disable disk checks
	PL_S	$1DA,210
	PL_S	$95f2,210	
	PL_S	$AE80,210

; disable checksum checks
	PL_B	$34ce,$60
	PL_B	$e706,$60
	PL_L	$dcdc,$4e714e71
	PL_B	$4AA4,$60
	PL_B	$89a2,$60
	PL_L	$37fa,$4e714e71



	PL_P	$f0fa,LOADER

	PL_R	$FE34			; Forbid
	PL_R	$FE46			; Permit
	PL_P	$FE8C,Colors		; fix access fault


	PL_PS	$B498,.cop		; fix invalid copperlist entry


; patch disk change
	PL_W	$F788,$4e71
	PL_W	$F7BC,$4e71
	PL_W	$F7F0,$4e71
	PL_W	$F84e,$4e71



	PL_PS	$3D66,.changedisk
	PL_W	$3D66+6,$4e71

; disable "insert disk" requesters
	PL_S	$10A2,6			; "insert data disc"
	PL_S	$168A,6			; "insert data disc"
	PL_S	$26ea,6			; "insert data disc"
	PL_S	$29b4,6			; "insert data disc"
	PL_S	$35c4,6			; "insert data disc"
	PL_S	$3e48,6			; "insert data disc"
	PL_S	$3f2c,6			; "insert data disc"
	PL_S	$3fcc,6			; "insert data disc"
	PL_S	$428c,6			; "insert data disc"
	PL_S	$432a,6			; "insert data disc"
	PL_S	$43d6,6			; "insert data disc"

	PL_S	$95e0,6			; "insert program disc"
	PL_S	$AE74,6			; "insert program disc"

	PL_S	$4a1c,$4a30-$4a1c	; "insert action replay data disc"
	PL_S	$4a5c,$4A70-$4a5c	; "insert action replay data disc"
	


; enable quit on 68000 machines
	PL_PS	$109d6,.key

	PL_END


.changedisk
	lea	$5300+$157e0,a2
	bra.w	DiskChange

.cop	move.l	#$5300+$13976,$dff084
	move.w	#$8380,$dff096
	rts


.key	move.b	$5300+$18c6a,d1
	bra.w	Keys


*******************************************
** V1.4G 		(SPS 1245)	***
*******************************************

PL_BOOT14G
	PL_START
	PL_P	$E2,.patch
	PL_END

.patch	lea	PL_14G(pc),a1
	lea	PL_14E(pc),a2		; same offsets as 1.4e
	bra.w	DecryptAndPatch


PL_14G	PL_START

	PL_PS	$B498,.cop		; fix invalid copperlist entry

	PL_PS	$3D66,.changedisk
	PL_W	$3D66+6,$4e71

; enable quit on 68000 machines
	PL_PS	$109d6,.key

	PL_END




.changedisk
	lea	$5300+$15b38,a2
	bra.w	DiskChange

.cop	move.l	#$5300+$13cce,$dff084
	move.w	#$8380,$dff096
	rts


.key	move.b	$5300+$18fc2,d1
	bra.w	Keys


*******************************************
** V1.4I 		(SPS 2574)	***
*******************************************

PL_BOOT14I
	PL_START
	PL_P	$E2,.patch
	PL_END

.patch	lea	PL_14I(pc),a1
	lea	PL_14E(pc),a2		; same offsets as 1.4e
	bra.w	DecryptAndPatch



PL_14I	PL_START

	PL_PS	$B498,.cop		; fix invalid copperlist entry

	PL_PS	$3D66,.changedisk
	PL_W	$3D66+6,$4e71

; enable quit on 68000 machines
	PL_PS	$109d6,.key

	PL_END
	


.changedisk
	lea	$5300+$15b8c,a2
	bra.w	DiskChange

.cop	move.l	#$5300+$13d22,$dff084
	move.w	#$8380,$dff096
	rts


.key	move.b	$1e316,d1		; absolute!
	bra.w	Keys


*******************************************
** V1.4S 		(SPS 2507)	***
*******************************************

PL_BOOT14S
	PL_START
	PL_P	$E2,.patch
	PL_END

.patch	lea	PL_14S(pc),a1
	lea	PL_14E(pc),a2		; same offsets as 1.4e
	bra.w	DecryptAndPatch


PL_14S	PL_START

	PL_PS	$B498,.cop		; fix invalid copperlist entry

	PL_PS	$3D66,.changedisk
	PL_W	$3D66+6,$4e71

; enable quit on 68000 machines
	PL_PS	$109d6,.key


	PL_END

.changedisk
	lea	$5300+$15b58,a2
	bra.w	DiskChange

.cop	move.l	#$5300+$13cee,$dff084
	move.w	#$8380,$dff096
	rts


.key	move.b	$5300+$18fe2,d1
	bra.w	Keys


*******************************************
** V1.6E 		(SPS 2191)	***
*******************************************

PL_BOOT16E
	PL_START
	PL_P	$E2,.patch
	PL_END

.patch	lea	PL_16E(pc),a1
	sub.l	a2,a2
	bra.w	DecryptAndPatch



PL_16E	PL_START

; disable disk checks
	PL_S	$1E4,210
	PL_S	$B82C,210	

; disable checksum checks
	PL_B	$4ad8,$60
	PL_L	$e7fe,$4e714e71
	PL_B	$3818,$60
	PL_B	$8DE0,$60
	PL_B	$F236,$60
	PL_L	$34ea,$4e714e71


	PL_P	$fc1c,LOADER

	PL_R	$10a12			; Forbid
	PL_R	$10a24			; Permit
	PL_P	$10a6a,Colors		; fix access fault


	PL_PS	$Bf14,.cop		; fix invalid copperlist entry


; patch disk change
	PL_W	$102f8,$4e71
	PL_W	$1032c,$4e71
	PL_W	$10360,$4e71
	PL_W	$103be,$4e71



	PL_PS	$3D88,.changedisk
	PL_W	$3D88+6,$4e71

; disable "insert disk" requesters
	PL_S	$10b4,6			; "insert data disc"
	PL_S	$16a0,6			; "insert data disc"
	PL_S	$2700,6			; "insert data disc"
	PL_S	$29ce,6			; "insert data disc"
	PL_S	$35e2,6			; "insert data disc"
	PL_S	$3e6e,6			; "insert data disc"
	PL_S	$3f52,6			; "insert data disc"
	PL_S	$3ff2,6			; "insert data disc"
	PL_S	$42b2,6			; "insert data disc"
	PL_S	$4350,6			; "insert data disc"
	PL_S	$43fc,6			; "insert data disc"

	PL_S	$9db0,6			; "insert program disc"
	PL_S	$B820,6			; "insert program disc"

	PL_S	$4a4e,$4a62-$4a4e	; "insert action replay data disc"
	PL_S	$4a8e,$4AA2-$4a8e	; "insert action replay data disc"
	


; enable quit on 68000 machines
	PL_PS	$11604,.key

; patch lousy extension memory check
	PL_P	$9FE6,.extmem
	PL_END

.extmem	;move.l	#$80000,d0
	move.l	HEADER+ws_ExpMem(pc),d0
	move.l	d0,d7
	add.l	#$80000,d7
	btst	#1,d0
	rts

.changedisk
	lea	$5300+$1656a,a2
	bra.w	DiskChange

.cop	move.l	#$5300+$146ee,$dff084
	move.w	#$8380,$dff096
	rts


.key	move.b	$5300+$19a12,d1
	bra.w	Keys


*******************************************
** V1.6G 				***
*******************************************

PL_BOOT16G
	PL_START
	PL_P	$E2,.patch
	PL_END

.patch	lea	PL_16G(pc),a1
	lea	PL_16E(pc),a2		; same offsets as 1.6e
	bra.w	DecryptAndPatch



PL_16G	PL_START
	PL_PS	$Bf14,.cop		; fix invalid copperlist entry
	PL_PS	$3D88,.changedisk
	PL_W	$3D88+6,$4e71

; enable quit on 68000 machines
	PL_PS	$11604,.key

	PL_END



.changedisk
	lea	$5300+$168c2,a2
	bra.w	DiskChange

.cop	move.l	#$5300+$14a46,$dff084
	move.w	#$8380,$dff096
	rts


.key	move.b	$1f06c-2,d1		; -2 because of .l
	bra.w	Keys


*******************************************
** FRENCH VERSION + WC'90		***
*******************************************

PL_BOOTFR
	PL_START
	PL_P	$E2,.patch
	PL_END

.patch	lea	PL_FR(pc),a1
	lea	PL_GER1(pc),a2		; same offsets as german version
	bra.w	DecryptAndPatch

PL_FR	PL_START

	PL_PS	$4B06,.changedisk
	PL_W	$4B06+6,$4e71

; enable quit on 68000 machines
	PL_PS	$11776,.key

	PL_PS	$C238,.cop		; fix invalid copperlist entry

	PL_END


.changedisk
	lea	$5300+$172e4,a2
	bra.w	DiskChange

.cop	move.l	#$5300+$14AAC,$dff084
	move.w	#$8380,$dff096
	rts

.key	move.b	$5300+$1a76e,d1
	bra.w	Keys



*******************************************
** V1.4F				***
*******************************************

PL_BOOT14F
	PL_START
	PL_P	$E2,.patch
	PL_END

.patch	lea	PL_14F(pc),a1
	lea	PL_14E(pc),a2		; same offsets as english version
	bra.w	DecryptAndPatch



PL_14F	PL_START

	PL_PS	$3d66,.changedisk
	PL_W	$3d66+6,$4e71

; enable quit on 68000 machines
	PL_PS	$109d6,.key

	PL_PS	$b498,.cop		; fix invalid copperlist entry

	PL_END



.changedisk
	lea	$5300+$15a26,a2
	bra.w	DiskChange

.cop	move.l	#$5300+$13bbc,$dff084
	move.w	#$8380,$dff096
	rts

.key	move.b	$1e1b0,d1		; absolute!
	bra.w	Keys




Keys	ror.b	d1
	not.b	d1
	cmp.b	HEADER+ws_keyexit(pc),d1
	beq.b	.quit

; make sure we don't save replays to the tactics disk
	cmp.b	#$50,d1
	bne.b	.noreplay
	move.l	a0,-(a7)
	lea	CurrentDisk(pc),a0
	move.w	#9,(a0)
	move.l	(a7)+,a0
.noreplay

	moveq	#3-1,d1
.loop	move.b	$dff006,d2
.wait	cmp.b	$dff006,d2
	beq.b	.wait
	dbf	d1,.loop
	rts

.quit
.wait1	btst	#0,$dff005
	beq.b	.wait1
.wait2	btst	#0,$dff005
	bne.b	.wait2


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
	move.l	a0,-(a7)
	lea	CurrentDisk(pc),a0
	cmp.w	#190*2,d0		; "insert data disc"
	bne.b	.nodatadisk
	move.w	#9,(a0)
.nodatadisk
	cmp.w	#189*2,d0		; "insert program disc"
	bne.b	.noprogramdisk
	move.w	#1,(a0)
.noprogramdisk
	cmp.w	#187*2,d0		; "insert action replay data disc"
	bne.b	.noactionreplays
	move.w	#9,(a0)
.noactionreplays


	cmp.w	#149*2,d0		; "load tactics"
	bne.b	.notactics
	move.w	#8,(a0)
.notactics

	cmp.w	#166*2,d0
	bne.b	.noPMteam
	move.w	#9,(a0)
.noPMteam


	move.l	(a7)+,a0

	;lea	$5300+$157e0,a2
	move.w	(a2,d0.w),d0
	rts






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
	bsr.b	.createdisk		; create disk.8 (tactics)
	lea	.name(pc),a0
	addq.b	#1,.num-.name(a0)	; create disk.9 (replays,cups,leagues)
	
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

.name	dc.b	"disk."
.num	dc.b	"8",0

	CNOP	0,4



; a0.l: pointer to end of memory (must NOT be trashed!)
; a1.l: patch list (main)
; a2.l: patch list (common, MUST be called first) or 0

DecryptAndPatch
	move.l	a0,-(a7)

	movem.l	a1/a2,-(a7)
	lea	$5300.w,a0
	move.l	#$22400,d0		; size of largest known binary
	bsr.b	Decrypt
	movem.l	(a7)+,a4/a5


	lea	$5300.w,a1
	bsr.b	FixMoveP

	move.l	a5,d0
	beq.b	.noPatchlist2
	move.l	a5,a0
	bsr.b	.patch
.noPatchlist2	
	move.l	a4,a0
	bsr.b	.patch


	move.l	(a7)+,a0
	jmp	$5300.w

.patch	lea	$5300.w,a1
	move.l	resload(pc),a2
	jmp	resload_Patch(a2)


; search for buggy movep code which is used to wait for the raster beam
; (all versions) and fix it

FixMoveP
	move.l	a1,a2
	move.l	a2,a3
	add.l	#140288,a3	; largest binary: 140288 bytes
.fix	move.w	(a2)+,d0
	cmp.w	#$0509,d0	; movep x(a1),d2?
	bne.b	.nomovep
	cmp.w	#$0004,(a2)	; movep.w 4(a1),d2?
	bne.b	.nomovep

; movep.w 4(a0),d0 instruction found
	pea	.WaitRaster(pc)
	move.w	#$4eb9,-2(a2)	; jsr
	move.l	(a7)+,(a2)+	; jsr .WaitRaster
	move.w	#$4e71,(a2)

.nomovep
	cmp.l	a2,a3
	bcc.b	.fix	
	rts


.WaitRaster
	move.l	$4(a1),d2
	and.l	#$1ff00,d2
	lsr.l	#8,d2
	rts




; Generic Cobra X-ROM decrypter
; stingray, 15.03.2020
; 
; Derived from my Kick Off 2 decrypter


; a0.l: start of data
; d0.l: length

Decrypt	lea	(a0,d0.l),a1


	; find sub.l a0,a0 instruction
.loop	cmp.w	#$91c8,(a0)
	bne.b	.next

	; next instruction MUST be lea xxx(pc),a1
	cmp.w	#$43fa,2(a0)
	bne.b	.next

	move.w	4(a0),d0
	lea	4(a0,d0.w),a0

	; a0.l: start of decryption code
	move.l	a1,-(a7)
	bsr	Decrypt_CobraXROM
	move.l	(a7)+,a1

	; first pass decryption is now done
	; a0.l: end of decryption code 

	; now find start of the final decryption code

	; find jmp $xxxx instruction


.loop2	cmp.w	#$4ef9,(a0)
	bne.b	.next2

	addq.w	#6,a0		; skip jmp $xxxx

	; a0.l: start of final decryption code
	move.l	a0,a5

	; find cmp.l a0,a1 instruction

.loop3	cmp.w	#$b3c8,(a0)
	bne.b	.next3
	move.w	2+2(a0),d0		; get offset to end of decryption code
	move.w	#$4e75,4(a0,d0.w)	; and terminate it

	; the final decryption can be executed now with jsr/jmp (a5)
	jsr	(a5)
	rts


.next3	addq.w	#2,a0
	cmp.l	a0,a1
	bne.b	.loop3
	rts

.next2	addq.w	#2,a0
	cmp.l	a0,a1
	bne.b	.loop2
	rts


.next	addq.w	#2,a0
	cmp.l	a0,a1
	bne.b	.loop
	rts



; a0.l: start of decryption code

Decrypt_CobraXROM
	move.l	a0,a4			; runs at $0.w in the orginal game

.loop	lea	TAB(pc),a3
.search	movem.w	(a3)+,d0/d1/d2/d3
	move.w	d0,d4
	and.w	d1,d4
	move.w	(a0,d2.w),d5
	and.w	d1,d5
	cmp.w	d4,d5
	beq.b	.found

	tst.w	(a3)
	bne.b	.search
	rts


.found	move.l	a4,-(a7)
	jsr	TAB(pc,d3.w)
	move.l	(a7)+,a4
	bra.w	.loop


	

	


; format: opcode, mask, position
TAB	dc.w	$b0b8,$f0ff,6,DecEorShort-TAB	; eor.l	dx,$xxx.w
	dc.w	$b0b8,$f0ff,4,DecEorShort-TAB

	; Kick Off2, 1.6e
	dc.w	$0301,$ffff,0,Skip2-TAB		; btst d1,d1
	dc.w	$0b03,$ffff,0,Skip2-TAB
	dc.w	$0901,$ffff,0,Skip2-TAB
	dc.w	$0305,$ffff,0,Skip2-TAB
	dc.w	$0506,$ffff,0,Skip2-TAB
	dc.w	$0304,$ffff,0,Skip2-TAB
	dc.w	$0703,$ffff,0,Skip2-TAB
	dc.w	$0d07,$ffff,0,Skip2-TAB
	dc.w	$0505,$ffff,0,Skip2-TAB
	dc.w	$0103,$ffff,0,Skip2-TAB
	dc.w	$0b01,$ffff,0,Skip2-TAB

	dc.w	$0907,$ffff,0,Skip2-TAB
	dc.w	$2e07,$ffff,0,Skip2-TAB
	dc.w	$2201,$ffff,0,Skip2-TAB
	dc.w	$c349,$ffff,0,Skip2-TAB
	dc.w	$c140,$ffff,0,Skip2-TAB


	dc.w	$1038,$f0ff,0,Skip4-TAB		; move.b $xxx.w,dx
	;dc.w	$3039,$f0ff,0,Skip6-TAB		; move.w $xxx,dx
	dc.w	$9179,$f0ff,6,DecSub-TAB	; sub.w dx,$xxx
	dc.w	$264b,$ffff,0,Skip2-TAB		; move.l a3,a3
	dc.w	$5350,$ffff,4,Skip8-TAB		; subq.w #1,(a0)
	dc.w	$b079,$f0ff,6,DecEor-TAB	; eor.w dx,$xxx
	dc.w	$d0b8,$f0ff,4,DecAddShort-TAB	; add.l dx,$xxx.w
	dc.w	$0105,$ffff,0,Skip2-TAB		; btst d0,d5
	dc.w	$0b06,$ffff,0,Skip2-TAB
	dc.w	$2c06,$ffff,0,Skip2-TAB
	dc.w	$90b8,$f0ff,4,DecSubShort-TAB	; sub.l dx,$xxx.w
	dc.w	$0700,$ffff,0,Skip2-TAB
	dc.w	$2000,$ffff,0,Skip2-TAB
	dc.w	$0303,$ffff,0,Skip2-TAB
	dc.w	$b841,$ffff,0,Skip2-TAB
	dc.w	$0104,$ffff,0,Skip2-TAB
	dc.w	$0705,$ffff,0,Skip2-TAB
	;dc.w	$4a01,$ffff,0,Skip2-TAB
	dc.w	$ba43,$ffff,0,Skip2-TAB
	dc.w	$4cd6,$ffff,8,DecMovem-TAB	; movem.l (a6),d0-d5/a0-a1
	dc.w	$4698,$fff0,8,DecNot-TAB	; not.l (ax)+
	dc.w	$4a05,$ffff,0,Skip2-TAB
	dc.w	$d179,$f0ff,6,DecAdd-TAB	; add.w dx,$xxx
	dc.w	$3000,$ffff,0,Skip2-TAB
	dc.w	$49f8,$ffff,0,Skip4-TAB
	dc.w	$202c,$ffff,0,Skip4-TAB
	dc.w	$294c,$ffff,0,Skip4-TAB
	dc.w	$2940,$ffff,0,Skip4-TAB
	dc.w	$4a07,$ffff,0,Skip2-TAB
	dc.w	$5f81,$ffff,14,DecSubqRol-TAB
	dc.w	$d090,$f0ff,14,DecAddKey-TAB	; add.l dx,(a0)
	dc.w	$4a00,$fff0,0,Skip2-TAB		; tst.b dx
	dc.w	$3402,$ffff,0,Skip2-TAB		; move.w d2,d2
	dc.w	$2804,$ffff,0,Skip2-TAB		; move.l d4,d4
	dc.w	$4e71,$ffff,0,Skip2-TAB
	dc.w	$0102,$ffff,0,Skip2-TAB
	dc.w	$1402,$ffff,0,Skip2-TAB		; move.b d2,d2
	dc.w	$b441,$ffff,0,Skip2-TAB		; cmp.w d1,d2
	dc.w	$1201,$ffff,0,Skip2-TAB		; move.b d1,d1
	dc.w	$1000,$ffff,0,Skip2-TAB		; move.b d0,d0
	dc.w	$4a40,$fff0,0,Skip2-TAB		; tst.w dx
	dc.w	$4a80,$fff0,0,Skip2-TAB		; tst.l dx
	dc.w	$c94c,$ffff,0,Skip2-TAB		; exg d4,a4
	dc.w	$b042,$ffff,0,Skip2-TAB		; cmp.w d2,d0
	dc.w	$0106,$ffff,0,Skip2-TAB		; btst d0,d6
	dc.w	$cd46,$ffff,0,Skip2-TAB		; exg d6,d6
	dc.w	$be44,$ffff,0,Skip2-TAB		; cmp.w d4,d7
	dc.w	$ba47,$ffff,0,Skip2-TAB		; cmp.w d7,d5
	dc.w	$0107,$ffff,0,Skip2-TAB		; btst d0,d7
	dc.w	$b243,$ffff,0,Skip2-TAB		; cmp.w d3,d1
	dc.w	$b244,$ffff,0,Skip2-TAB		; cmp.w d4,d1
	dc.w	$c743,$ffff,0,Skip2-TAB		; exg d3,d3
	dc.w	$b644,$ffff,0,Skip2-TAB		; cmp.w d4,d3
	dc.w	$0b00,$ffff,0,Skip2-TAB		; btst d5,d0
	dc.w	$4e70,$ffff,12,Skip14-TAB	; reset
	dc.w	$b645,$ffff,0,Skip2-TAB		; cmp.w d5,d3
	dc.w	$0503,$ffff,0,Skip2-TAB		; btst d2,d3
	dc.w	$3e07,$ffff,0,Skip2-TAB		; move.w d7,d7
	dc.w	$2603,$ffff,0,Skip2-TAB		; move.l d3,d3
	dc.w	$cd4e,$ffff,0,Skip2-TAB		; exg a6,a6
	dc.w	$1a05,$ffff,0,Skip2-TAB		; move.b d5,d5
	dc.w	0


; d2.w: position of eor.w opcode (default: 4)
; a0.l: decryption code
; a4.l: start of decryption code ($0.w)

DecEorShort
	cmp.w	#4,d2
	blt.b	.ok
	subq.w	#4,d2
	add.w	d2,a0			; a0: real start of decryption routine
.ok	move.w	0*4+2(a0),d0		; offset to encrypted data 
	move.w	1*4+2(a0),d1		; offset to destination
	move.w	2*4+2(a0),d2
	move.w	3*4+2(a0),d3
	move.w	4*4+2(a0),d4

	lea	(a4,d0.w),a0
	lea	(a4,d1.w),a1
	lea	(a4,d2.w),a2
	lea	(a4,d3.w),a3
	add.w	d4,a4

	move.l	a1,-(a7)
.loop	move.l	(a0)+,d5
	eor.l	d5,(a1)+

	addq.w	#4,(a2)
	addq.w	#4,(a3)
	subq.w	#1,(a4)
	bne.b	.loop
	move.l	(a7)+,a0
	rts

; d2.w: position of sub.w opcode (default: 6)
; a0.l: decryption code
; a4.l: start of decryption code ($0.w)

DecSub	cmp.w	#6,d2
	blt.b	.ok
	subq.w	#6,d2
	add.w	d2,a0			; a0: real start of decryption routine
.ok	move.l	0*6+2(a0),d0		; offset to encrypted data 
	move.l	1*6+2(a0),d1		; offset to destination
	move.l	2*6+2(a0),d2
	move.l	3*6+2(a0),d3
	move.l	4*6+2(a0),d4

	lea	(a4,d0.w),a0
	lea	(a4,d1.w),a1
	lea	(a4,d2.w),a2
	lea	(a4,d3.w),a3
	add.w	d4,a4

	move.l	a1,-(a7)
.loop	move.w	(a0),d5
	sub.w	d5,(a1)
	addq.w	#4,a0
	addq.w	#4,a1

	addq.l	#4,(a2)
	addq.l	#4,(a3)
	subq.w	#1,(a4)
	bne.b	.loop
	move.l	(a7)+,a0
	rts

; d2.w: position of add.w opcode (default: 6)
; a0.l: decryption code
; a4.l: start of decryption code ($0.w)

DecAdd	cmp.w	#6,d2
	blt.b	.ok
	subq.w	#6,d2
	add.w	d2,a0			; a0: real start of decryption routine
.ok	move.l	0*6+2(a0),d0		; offset to encrypted data 
	move.l	1*6+2(a0),d1		; offset to destination
	move.l	2*6+2(a0),d2
	move.l	3*6+2(a0),d3
	move.l	4*6+2(a0),d4

	lea	(a4,d0.w),a0
	lea	(a4,d1.w),a1
	lea	(a4,d2.w),a2
	lea	(a4,d3.w),a3
	add.w	d4,a4

	move.l	a1,-(a7)
.loop	move.w	(a0),d5
	add.w	d5,(a1)
	addq.w	#4,a0
	addq.w	#4,a1

	addq.l	#4,(a2)
	addq.l	#4,(a3)
	subq.w	#1,(a4)
	bne.b	.loop
	move.l	(a7)+,a0
	rts

; d2.w: position of eor.w opcode (default: 6)
; a0.l: decryption code
; a4.l: start of decryption code ($0.w)

DecEor	cmp.w	#6,d2
	blt.b	.ok
	subq.w	#6,d2
	add.w	d2,a0			; a0: real start of decryption routine
.ok	move.l	0*6+2(a0),d0		; offset to encrypted data 
	move.l	1*6+2(a0),d1		; offset to destination
	move.l	2*6+2(a0),d2
	move.l	3*6+2(a0),d3
	move.l	4*6+2(a0),d4

	lea	(a4,d0.w),a0
	lea	(a4,d1.w),a1
	lea	(a4,d2.w),a2
	lea	(a4,d3.w),a3
	add.w	d4,a4

	move.l	a1,-(a7)
.loop	move.w	(a0),d5
	eor.w	d5,(a1)
	addq.w	#4,a0
	addq.w	#4,a1

	addq.l	#4,(a2)
	addq.l	#4,(a3)
	subq.w	#1,(a4)
	bne.b	.loop
	move.l	(a7)+,a0
	rts

	
; d2.w: position of add.l opcode (default: 4)
; a0.l: decryption code
; a4.l: start of decryption code ($0.w)

DecAddShort
	cmp.w	#4,d2
	blt.b	.ok
	subq.w	#4,d2
	add.w	d2,a0			; a0: real start of decryption routine
.ok	move.w	0*4+2(a0),d0		; offset to encrypted data 
	move.w	1*4+2(a0),d1		; offset to destination
	move.w	2*4+2(a0),d2
	move.w	3*4+2(a0),d3
	move.w	4*4+2(a0),d4

	lea	(a4,d0.w),a0
	lea	(a4,d1.w),a1
	lea	(a4,d2.w),a2
	lea	(a4,d3.w),a3
	add.w	d4,a4

	move.l	a1,-(a7)
.loop	move.l	(a0)+,d5
	add.l	d5,(a1)+

	addq.w	#4,(a2)
	addq.w	#4,(a3)
	subq.w	#1,(a4)
	bne.b	.loop
	move.l	(a7)+,a0
	rts

; d2.w: position of sub.l opcode (default: 4)
; a0.l: decryption code
; a4.l: start of decryption code ($0.w)

DecSubShort
	cmp.w	#4,d2
	blt.b	.ok
	subq.w	#4,d2
	add.w	d2,a0			; a0: real start of decryption routine
.ok	move.w	0*4+2(a0),d0		; offset to encrypted data 
	move.w	1*4+2(a0),d1		; offset to destination
	move.w	2*4+2(a0),d2
	move.w	3*4+2(a0),d3
	move.w	4*4+2(a0),d4

	lea	(a4,d0.w),a0
	lea	(a4,d1.w),a1
	lea	(a4,d2.w),a2
	lea	(a4,d3.w),a3
	add.w	d4,a4

	move.l	a1,-(a7)
.loop	move.l	(a0)+,d5
	sub.l	d5,(a1)+

	addq.w	#4,(a2)
	addq.w	#4,(a3)
	subq.w	#1,(a4)
	bne.b	.loop
	move.l	(a7)+,a0
	rts


DecSubqRol
	move.w	8+2(a0),d0
	lea	26(a0),a1
	move.l	a1,-(a7)

.loop	move.l	(a0)+,d1
	subq.l	#7,d1
	swap	d1
	rol.l	#1,d1
	add.l	d1,(a1)+
	dbf	d0,.loop

	move.l	(a7)+,a0
	rts


DecMovem
	move.w	2(a0),d7
	lea	32(a0),a6
	move.l	a6,-(a7)
.loop	movem.l	(a6),d0-d5/a0/a1
	exg	d0,d4
	exg	d1,d2
	exg	d3,d5
	exg	a1,a0
	movem.l	d0-d5/a0/a1,(a6)
	lea	$20(a6),a6
	dbf	d7,.loop
	move.l	(a7)+,a0
	rts


DecNot	move.w	2(a0),d7
	add.w	#14,a0
	move.l	a0,-(a7)
.loop	not.l	(a0)+
	dbf	d7,.loop
	move.l	(a7)+,a0
	rts	


DecAddKey
	move.w	2(a0),d0
	move.l	4+2(a0),d1
	add.w	#22,a0
	move.l	a0,-(a7)
.loop	add.l	d1,(a0)
	addq.w	#8,a0
	dbf	d0,.loop
	move.l	(a7)+,a0
	rts


Skip2	addq.w	#2,a0
	rts

Skip4	addq.w	#4,a0
	rts

Skip6	addq.w	#6,a0
	rts

Skip8	addq.w	#8,a0
	rts

Skip14	add.w	#14,a0
	rts


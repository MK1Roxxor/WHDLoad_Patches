***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*( KICK OFF 2-THE FINAL WHISTLE WHDLOAD SLAVE )*)---.---.   *
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

; 29-Nov-2022	- delay loop keyboard routine fixed
;		- WHDLoad v17+ features used (config)

; 28-Nov-2022	- source can be assembled case-sensitive now
;		- support for 1.9f version added

; 10-Jan-2010	- fixed loading of Player Manager teams (didn't
;		  work due to wrong check in diskchange patch)

; 26-Jul-2009	- fixed problem with loading different pitches
;		  reported by Alkis21

; 19-Mar-2009	- support for diffent v1.9e version added, disk
;		  image sent by Tom Meades

; 15-Mar-2009	- teams are handled differently now, data disk
;		  for teams needs to be named disk.8, this should
;		  hopefully fix the problems with loading teams that
;		  were reported by lolafg today, now waiting for
;		  him to test this new version :)
 
; 14-Mar-2009	- minor problem with the quitkey fixed, uses
;		  ws_KeyExit instead of QUITKEY constant now

; 13-Mar-2009	- loading/saving of teams/goals ect.
;		- automatic creation of data disk
;		- disk requesters disabled
;		- support for 1.9e and 2.1e added

; 01-Mar-2009	- tested on my A4k, access fault fixed,
; 		  invalid copperlist entry fixed, cache stuff
;		  skipped
;		- tested with all snoop modes, no faults

; 28-Feb-2009	- work started
;		- checksums removed, disk protections removed,
;		  lousy memory check patched etc.
;		- patch worked at first try, scary or what? :D



	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_EmulTrap
DEBUGKEY	= $58		; F9
QUITKEY		= $46		; DEL
;DEBUG



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


.config	dc.b	"C1:B:Disable Data Disk Creation"
	dc.b	0

	IFD	DEBUG
.dir	dc.b	"SOURCES:WHD_Slaves/FinalWhistle/",0
	ENDC
.name	dc.b	"Kick Off 2 - The Final Whistle",0
.copy	dc.b	"1991 Anco",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	dc.b	"Version 1.04 (29.11.2022)",0
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
	lea	$0.w,a0
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
	lea	PL_BOOTCV(pc),a0
	cmp.w	#$A071,d0		; competition version
	beq.b	.ok
	lea	PL_BOOT21E(pc),a0
	cmp.w	#$E24C,d0		; v2.1e (SPS 166)
	beq.b	.ok
	lea	PL_BOOT19E(pc),a0
	cmp.w	#$49BD,d0		; v1.9e (SPS 759)
	beq.b	.ok
	lea	PL_BOOTNEW(pc),a0
	cmp.w	#$9CCD,d0		; v1.9e (tom meades)
	beq.b	.ok
	lea	PL_BOOT19F(pc),a0	; v1.9f
	cmp.w	#$38f5,d0
	beq.b	.ok
; unknown version
	pea	(TDREASON_WRONGVER).w
	bra.b	EXIT

.ok


	; patch it
	move.l	a5,a1
	jsr	resload_Patch(a2)
	
	; load encrypted main file
	move.l	#$1600,d0
	move.l	#$1d600,d1
	moveq	#1,d2
	lea	$30000,a0
	jsr	resload_DiskLoad(a2)


	; skip cache stuff in competition version
	lea	$30000+$1c498,a0
	move.w	#$602a,(a0)


	move.l	NODATADISK(pc),d0
	bne.b	.nodatadisk
	bsr	CreateDataDisk		; create data disk if it doesn't exist
.nodatadisk
	jmp	$76(a5)

QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	jmp	resload_Abort(a2)




*******************************************
*** COMPETITION VERSION			***
*******************************************

PL_BOOTCV
	PL_START
	PL_P	$208,.patch
	PL_END


.patch	move.l	a0,-(a7)
	lea	PL_GAMECV(pc),a0
	lea	$5300.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	move.l	(a7)+,a0
	jmp	$5300.w


PL_GAMECV
	PL_START
	PL_S	$11c3c,$11cc0-$11c3c	; skip ext. mem check
	PL_PS	$11cc0,ExtMem
	PL_PS	$11cd0,ExtMem2
	PL_P	$115e6,LOADER

; disable disk checks
	PL_S	$1f6,$2c8-$1f6
	PL_S	$416,$4e8-$416
	PL_S	$53c4,$5496-$53c4
	PL_S	$55e4,$56b6-$55e4
	PL_S	$B1A6,$B278-$B1a6
	PL_S	$CC90,$CD62-$CC90
	PL_S	$12022,$120f4-$12022

	PL_R	$41cc			; disable check for Kick Off 2 disk

; disable checksum checks
	PL_B	$3e70,$60
	PL_B	$3B6e,$60
	PL_B	$5216,$60
	PL_L	$7ff0,$4e714e71
	PL_B	$9f7a,$60
	PL_B	$E6A2,$60
	PL_L	$FC60,$4e714e71
	PL_L	$FFD6,$4e714e71
	PL_B	$10ba8,$60


	PL_W	$11d28,$4e71		; remove disk change check
	PL_W	$11d5c,$4e71
	PL_W	$11dba,$4e71
	PL_W	$122c2,$4e71

; disable "insert disk" requesters
	PL_S	$4228,6			; "insert data disc"
	PL_S	$4278,6			; "insert data disc"
	PL_S	$42B4,6			; "insert data disc"
	PL_S	$42EA,6			; "insert data disc"

	PL_S	$518e,20		; "insert action replay data disc"
	PL_S	$51ce,20		; "insert action replay data disc"



	PL_R	$1278c			; Forbid
	PL_R	$1279e			; Permit
	PL_P	$127e4,Colors		; fix access fault

	PL_PS	$D44A,.cop		; fix invalid copperlist entry

	PL_PS	$45d8,.changedisk
	PL_W	$45d8+6,$4e71

; enable quit on 68000 machines
	PL_PS	$13396,.key


	PL_END

.cop	move.l	#$5300+$15932,$dff084
	move.w	#$8380,$dff096
	rts

.key	move.b	$5300+$1b52e,d1
	bra.w	Keys

.changedisk
	lea	$5300+$1803a,a2
	bra.w	DiskChange




*******************************************
*** V1.9e		(SPS 759)	***
*******************************************

PL_BOOT19E
	PL_START
	PL_P	$E2,.patch
	PL_END


.patch	movem.l	d0-a6,-(a7)
	lea	$5300.w,a0	; start
	lea	$20882,a1	; end
	lea	.TAB(pc),a4
	move.w	#$4f99,d3
	move.w	#$7d10,d4
	lea	PL_GAME19E(pc),a5
	bsr	DecryptAndPatch
	movem.l	(a7)+,d0-a6
	jmp	$5300.w

.TAB	DC.W	$365F,$C0D3,$110E,$07A8,$5F4B,$33E4,$8598,$82C9
	DC.W	$CFA9,$DB3A,$5608,$4013,$02E2,$AFB4,$171E,$0634
	DC.W	$528F,$D2AB,$4079,$4624,$66CB,$B3D8,$34BF,$C183
	DC.W	$609E,$6BD4,$B1B2,$5340,$ECF3,$30E1,$7BD7,$5C71


PL_GAME19E
	PL_START
	PL_S	$11c1c,$11cc0-$11c3c	; skip ext. mem check
	PL_PS	$11ca0,ExtMem
	PL_PS	$11cb0,ExtMem2
	PL_P	$115c6,LOADER

; disable disk checks
	PL_S	$1f6,210
	PL_S	$416,210
	PL_S	$53c2,210
	PL_S	$55e2,210
	PL_S	$B18a,210
	PL_S	$CC74,210
	PL_S	$12002,210

	PL_R	$41ca			; disable check for Kick Off 2 disk

; disable checksum checks
	PL_B	$3B6c,$60
	PL_B	$e686,$60
	PL_L	$ffb6,$4e714e71
	PL_B	$5214,$60
	PL_B	$10b88,$60
	PL_B	$3E6E,$60
	PL_B	$9f5e,$60
	PL_L	$7fdc,$4e714e71
	PL_L	$FC40,$4e714e71
	

	PL_W	$11d08,$4e71		; remove disk change check
	PL_W	$11d3c,$4e71
	PL_W	$11d9a,$4e71
	PL_W	$122a2,$4e71

; disable "insert disk" requesters
	PL_S	$4226,6			; "insert data disc"
	PL_S	$4276,6			; "insert data disc"
	PL_S	$42B2,6			; "insert data disc"
	PL_S	$42E8,6			; "insert data disc"

	PL_S	$518c,20		; "insert action replay data disc"
	PL_S	$51c8,20		; "insert action replay data disc"



	PL_R	$1276c			; Forbid
	PL_R	$1277e			; Permit
	PL_P	$127c4,Colors		; fix access fault

	PL_PS	$D42e,.cop		; fix invalid copperlist entry

	PL_PS	$45d6,.changedisk
	PL_W	$45d6+6,$4e71

; enable quit on 68000 machines
	PL_PS	$13376,.key


	PL_END

.cop	move.l	#$5300+$15912,$dff084
	move.w	#$8380,$dff096
	rts

.key	move.b	$5300+$1b50e,d1
	bra.w	Keys

.changedisk
	lea	$5300+$1801a,a2
	bra.w	DiskChange



*******************************************
*** V1.9f				***
*******************************************

PL_BOOT19F
	PL_START
	PL_P	$E2,.patch
	PL_END

.patch	movem.l	d0-a6,-(a7)
	lea	$5300.w,a0	; start
	lea	$20A4E,a1	; end
	lea	.TAB(pc),a4
	move.w	#$4f99,d3
	move.w	#$5b59,d4
	lea	PL_GAME19F(pc),a5
	bsr	DecryptAndPatch
	movem.l	(a7)+,d0-a6
	jmp	$5300.w

.TAB	DC.W	$365F,$C0D3,$110E,$07A8,$5F4B,$33E4,$8598,$82C9
	DC.W	$CFA9,$DB3A,$5608,$4013,$02E2,$AFB4,$171E,$0634
	DC.W	$528F,$D2AB,$4079,$4624,$66CB,$B3D8,$34BF,$C183
	DC.W	$609E,$6BD4,$B1B2,$5340,$ECF3,$30E1,$7BD7,$5C71

PL_GAME19F
	PL_START
	PL_S	$11c3c,$11cc0-$11c3c	; skip ext. mem check
	PL_PS	$11cc0,ExtMem
	PL_PS	$11cd0,ExtMem2
	PL_P	$115e6,LOADER

; disable disk checks
	PL_S	$1f6,210
	PL_S	$416,210
	PL_S	$53c4,210
	PL_S	$55e4,210
	PL_S	$B1a6,210
	PL_S	$CC90,210
	PL_S	$12022,210

	PL_R	$41cc			; disable check for Kick Off 2 disk

; disable checksum checks
	PL_B	$3B6e,$60
	PL_B	$e6a2,$60
	PL_L	$ffd6,$4e714e71
	PL_B	$5216,$60
	PL_B	$10ba8,$60
	PL_B	$3E70,$60
	PL_B	$9f7a,$60
	PL_L	$7ff0,$4e714e71
	PL_L	$FC60,$4e714e71
	

	PL_W	$11d28,$4e71		; remove disk change check
	PL_W	$11d5c,$4e71
	PL_W	$11dba,$4e71
	PL_W	$122c2,$4e71

; disable "insert disk" requesters
	PL_S	$4228,6			; "insert data disc"
	PL_S	$4278,6			; "insert data disc"
	PL_S	$42B4,6			; "insert data disc"
	PL_S	$42Ea,6			; "insert data disc"

	PL_S	$518e,20		; "insert action replay data disc"
	PL_S	$51ce,20		; "insert action replay data disc"



	PL_R	$1278c			; Forbid
	PL_R	$1279e			; Permit
	PL_P	$127e4,Colors		; fix access fault

	PL_PS	$D44a,.cop		; fix invalid copperlist entry

	PL_PS	$45d8,.changedisk
	PL_W	$45d8+6,$4e71

; enable quit on 68000 machines
	PL_PS	$13396,.key
	PL_END

.cop	move.l	#$5300+$15af6,$dff084
	move.w	#$8380,$dff096
	rts

.key	move.b	$5300+$1b6fa,d1
	bra.w	Keys

.changedisk
	lea	$5300+$18206,a2
	bra.w	DiskChange


*******************************************
*** V2.1e		(SPS 166)	***
*******************************************

PL_BOOT21E
	PL_START
	PL_P	$E2,.patch
	PL_END


.patch	movem.l	d0-a6,-(a7)
	lea	$5300.w,a0	; start
	lea	$20882,a1	; end
	lea	.TAB(pc),a4
	move.w	#$4f99,d3
	move.w	#$2332,d4
	lea	PL_GAMECV(pc),a5	; same as competition version
	bsr	DecryptAndPatch
	movem.l	(a7)+,d0-a6
	jmp	$5300.w

.TAB	DC.W	$365F,$C0D3,$110E,$07A8,$5F4B,$33E4,$8598,$82C9
	DC.W	$CFA9,$DB3A,$5608,$4013,$02E2,$AFB4,$171E,$0634
	DC.W	$528F,$D2AB,$4079,$4624,$66CB,$B3D8,$34BF,$C183
	DC.W	$609E,$6BD4,$B1B2,$5340,$ECF3,$30E1,$7BD7,$5C71







*******************************************
*** TOM MEADES				***
*******************************************

PL_BOOTNEW
	PL_START
	PL_P	$E2,.patch
	PL_END


.patch	movem.l	d0-a6,-(a7)
	lea	$5300.w,a0	; start
	lea	$2087a,a1	; end
	lea	.TAB(pc),a4
	move.w	#$4f99,d3
	move.w	#$172e,d4
	lea	PL_GAMENEW(pc),a5
	bsr	DecryptAndPatch
	movem.l	(a7)+,d0-a6
	jmp	$5300.w

.TAB	DC.W	$365F,$C0D3,$110E,$07A8,$5F4B,$33E4,$8598,$82C9
	DC.W	$CFA9,$DB3A,$5608,$4013,$02E2,$AFB4,$171E,$0634
	DC.W	$528F,$D2AB,$4079,$4624,$66CB,$B3D8,$34BF,$C183
	DC.W	$609E,$6BD4,$B1B2,$5340,$ECF3,$30E1,$7BD7,$5C71


PL_GAMENEW
	PL_START
	PL_S	$11c34,$11cc0-$11c3c	; skip ext. mem check
	PL_PS	$11cb8,ExtMem
	PL_PS	$11cc8,ExtMem2
	PL_P	$115de,LOADER

; disable disk checks
	PL_S	$1f6,210
	PL_S	$416,210
	PL_S	$53c4,210
	PL_S	$55e4,210
	PL_S	$B19E,210
	PL_S	$CC88,210
	PL_S	$1201a,210

	PL_R	$41cc			; disable check for Kick Off 2 disk

; disable checksum checks
	PL_B	$3B6e,$60
	PL_B	$e69a,$60
	PL_L	$ffce,$4e714e71
	PL_B	$5216,$60
	PL_B	$10ba0,$60
	PL_B	$3E70,$60
	PL_B	$9f72,$60
	PL_L	$7ff0,$4e714e71
	PL_L	$FC58,$4e714e71
	

	PL_W	$11d20,$4e71		; remove disk change check
	PL_W	$11d54,$4e71
	PL_W	$11db2,$4e71
	PL_W	$122ba,$4e71

; disable "insert disk" requesters
	PL_S	$4228,6			; "insert data disc"
	PL_S	$4278,6			; "insert data disc"
	PL_S	$42B4,6			; "insert data disc"
	PL_S	$42EA,6			; "insert data disc"

	PL_S	$518e,20		; "insert action replay data disc"
	PL_S	$51ce,20		; "insert action replay data disc"



	PL_R	$12784			; Forbid
	PL_R	$12796			; Permit
	PL_P	$127dc,Colors		; fix access fault

	PL_PS	$D442,.cop		; fix invalid copperlist entry

	PL_PS	$45d8,.changedisk
	PL_W	$45d8+6,$4e71

; enable quit on 68000 machines
	PL_PS	$1338e,.key


	PL_END

.cop	move.l	#$5300+$1592a,$dff084
	move.w	#$8380,$dff096
	rts

.key	move.b	$5300+$1b526,d1
	bra.w	Keys

.changedisk
	lea	$5300+$18032,a2
	bra.w	DiskChange



ExtMem	move.l	HEADER+ws_ExpMem(pc),d0
	rts

ExtMem2	bsr.b	ExtMem
	add.l	#524288,d0
	move.l	d0,(a0)+
	rts

Keys	;move.b	$5300+$18c6a,d1
	ror.b	d1
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

.quit	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.b	.quit

	move.w	#$7fff,$dff09c
	move.w	#$7fff,$dff09a
	move.w	#$7fff,$dff096	
	
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
	cmp.w	#157*2,d0		; "load league"
	bne.b	.noleague
	move.w	#9,(a0)
.noleague
	cmp.w	#164*2,d0		; "load cup"
	bne.b	.nocup
	move.w	#9,(a0)
.nocup	cmp.w	#166*2,d0		" "load player manager team"
	bne.b	.noplayermanagerteam
	move.w	#9,(a0)
.noplayermanagerteam
	cmp.w	#180*2,d0		; "load match replays"
	bne.b	.nomatchreplays
	move.w	#9,(a0)
.nomatchreplays
	cmp.w	#181*2,d0		" "load golden replays"
	bne.b	.nogoldenreplays
	move.w	#9,(a0)
.nogoldenreplays
	cmp.w	#225*2,d0		; "load world cup"
	bne.b	.noworldcup
	move.w	#9,(a0)
.noworldcup		

	cmp.w	#168*2,d0		; "store"
	bne.b	.nostore
	move.w	#9,(a0)
.nostore	


	cmp.w	#265*2,d0		; "load pitch"
	bne.b	.nopitch
	move.w	#1,(a0)
.nopitch
	
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
	move.l	#$30000,d4		; length
	moveq	#0,d7			; offset
	move.l	#901120,d5
.loop	move.l	d4,d0
	move.l	d7,d1
	lea	.name(pc),a0
	lea	$0.w,a1
	jsr	resload_SaveFileOffset(a2)
	
.ok	add.l	#$30000,d7
	cmp.l	#901120-$30000,d7
	ble.b	.ok2
	move.l	#901120,d4
	sub.l	d7,d4
.ok2	sub.l	#$30000,d5
	bpl.b	.loop
.exit	rts

.name	dc.b	"disk."
.num	dc.b	"8",0

	CNOP	0,4


; d3.w: key1
; d4.w: key2
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
	add.w	d3,d1
	add.w	(a3)+,d1
	move.w	d1,(a0)+
	add.w	d1,d4
	dbf	d0,.loop
	bra.b	.outer

.done	move.l	a5,a0
	lea	$5300.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	rts



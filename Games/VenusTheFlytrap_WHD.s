***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(     VENUS THE FLYTRAP WHDLOAD SLAVE        )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              March 2015                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 13-Dec-2022	- game didn't work on 68000 machines if "Force Blitter Wait
;		  Patches" wasn't used (issue #5628)
;		- Jump with fire 2 option (CUSTOM4) added (issue #5832)

; 05-Mar-2015	- Chart Attack version (SPS 1985) is now fully supported
;		  again
;		- checked all available trainer releases of this game
;		  and NONE got the "unlimited lives" option right, they all
;		  bug out after the end sequence! :)
;		- keys for level/world skip disabled during bonus level
;		- key to refill ammo ('A') added
;		- added option to skip intro again (CUSTOM3), if enabled
;		  credits and intro will be skipped
;		- I guess that's it for now, this patch is now finally
;		  finished!

; 04-Mar-2015	- lots of SMC and CPU dependent delay loops fixed
;		- one more interrupt acknowledge fix
;		- key to toggle unlimited energy ('E') added
;		- key to enable flying ability ('F') added
;		- above keys were added to aid playtesting, 'E' so I didn't
;		  have to play the whole bloody bonus levels and
;		  'F' for easy playing
;		- finally found a good fix for the access faults, that
;		  was a lot of work! tested the complete game, no faults!
;		- key to show secret rooms ('S') added
;		- key to show end ('X') added
;		- timing in end part fixed
;		- high-score load/save added, enter "ACIEEEEED" for a 
;		  surprise :)
;		- end-sequence didn't work properly when "unlimited lives"
;		  option was turned on, game relied on the fact that
;		  a life would be subtracted in certain situations, adapted
;		  the code for that!
;		- CPU dependent delays in credits part (gremlin logo) and
;		  intro fixed
;		- table with ddfstrt/stop etc. values in intro found, this
;		  contained buggy values just like all copperlists, coded
;		  a routine to fix all table entries
;		- except for a few sound problems the 2 disk NDOS version
;		  is now fully patched after a LOT of work, hooray! 
;		- started to add support for the "Chart Attack" version
;		  (SPS 1985) again :)

; 03-Mar-2015	- game patched, copperlist fixes applied and blitter
;		  waits added
;		- option to skip the credits/intro removed, intro can
;		  be skipped by pressing Escape
;		- some more interrupt acknowledge fixes
;		- lots of hours wasted trying to fix all access faults,
;		  the first 3 worlds seem to work now but I'm not satisfied
;		  with the fixes
;		- on the good side of things I finally found the real
;		  reason for the access fault in the bonus level and
;		  fixed it properly now (move.b instead of move.l was used
;		  to initialise the "tab adder", quite a lame bug...)
;		- unlimited energy option fixed

; 02-Mar-2015	- work restarted again...
;		- old code got way too complex so restarting from
;		  scratch, intro (2 disk version) patched

; 16-Jan-2014	- default copperlist set (copper DMA enabled before
;		  any copperlist was set)
;		- writes to $dff010, $bfe201 and $dff00a disabled
;		- offset for Bplcon0 color bit fix corrected ($582 vs. $584)
;		- access fault in bonus level fixed but there are more

; 21-Jun-2013	- Chart attack re-release version now works too
;		- lots of trainers added

; 20-Jun-2013	- bug in file loading routine fixed, after the first
;		  character of the file name was compared a wrong
;		  branch was taken
;		- file loader handles uncrunched files correctly now
;		- game now finally works again :)
;		- credits screen and intro can be skipped now (CUSTOM1)
;		- started to add support for the Chart Attack re-release
;		  version (IPF 1985)

; 19-Jun-2013	- code to automatically fix blitter waits added

; 18-Jun-2013	- all code parts patched, nothing tested yet though
;		- interrupts fixed in boot code (SMC, acknowledge etc.)

; 17-Jun-2013	- work restarted again
;		- file loader coded which handles all patching automagically
;		- FUNGUS decruncher optimised (it's an optimised version
;		  of the bytekiller decruncher)


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i
	

FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
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


.config	dc.b	"C1:X:Unlimited Lives:0;"
	dc.b	"C1:X:Unlimited Energy:1;"
	dc.b	"C1:X:Unlimited Ammo:2;"
	dc.b	"C1:X:Unlimited Credits:3;"
	dc.b	"C1:X:Unlimited Time:4;"
	dc.b	"C1:X:Start with all Weapons:5;"
	dc.b	"C1:X:Enable In-Game Keys:6;"
	dc.b	"C2:B:Force Blitter Wait patches on 68000;"
	dc.b	"C3:B:Skip Intro;"
	dc.b	"C4:B:Jump with Fire 2 (Disables Joystick Up)"
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/VenusTheFlytrap/"
	ENDC
	dc.b	"data",0
.name	dc.b	"Venus The Flytrap",0
.copy	dc.b	"1990 Gremlin",0
.info	dc.b	"Installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.3 (13.12.2022)",0

BootName	dc.b	"boot",0
MusName		dc.b	"intro.mus",0
CreditsName	dc.b	"credits.wrk",0
IntroName	dc.b	"intro.wrk",0
VenusName	dc.b	"venus.wrk",0
HighName	dc.b	"Venus.high",0

	CNOP	0,2


TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
CPUFLAGS	dc.l	0


		dc.l	WHDLTAG_CUSTOM1_GET

; bit 0: unlimited lives 	on/off
; bit 1: unlimited energy	on/off
; bit 2: unlimited ammo 	on/off
; bit 3: unlimited credits 	on/off
; bit 4: unlimited time 	on/off
; bit 5: start with all weapons on/off
; bit 6: in-game keys		on/off

TRAINEROPTIONS	dc.l	0


		dc.l	WHDLTAG_CUSTOM2_GET
FORCEBLITWAITS	dc.l	0

		dc.l	WHDLTAG_CUSTOM3_GET
SKIPINTRO	dc.l	0
		dc.l	TAG_END


resload	dc.l	0

OPT_KEYS	= 6	; bit used for in-game keys


Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)


; install keyboard irq
	bsr	SetLev2IRQ

; load boot
	lea	BootName(pc),a0
	lea	$400-($280+$20).w,a1	; $280: start of packed data

	move.l	a1,a5
	jsr	resload_LoadFileDecrunch(a2)
	move.l	d0,d5			; save size

	move.l	a5,a0
	jsr	resload_CRC16(a2)

	cmp.w	#$49f1,d0		; 2 disk version, no intro, DOS/NDOS
	bne.b	.notnointro

; 2 disk version, no intro (Chart Attack compilation)
; decrunch game binary
	lea	$400.w,a0
	move.l	a0,a5
	bsr	DECRUNCH2
	lea	PatchVenus(pc),a5
	bra.b	.go

.notnointro
	cmp.w	#$0573,d0		; 2 disk version with intro, NDOS
	beq.b	.ok

	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT

; 2 disk version with intro (original release)
.ok

	move.l	SKIPINTRO(pc),d0
	beq.b	.dointro

; skip intro -> load and decrunch game binary
	lea	VenusName(pc),a0
	lea	$400.w,a1
	jsr	resload_LoadFileDecrunch(a2)
	lea	$400.w,a0
	move.l	a0,a1
	bsr	DECRUNCH_FUNGUS
	lea	PatchVenus(pc),a5
	bra.b	.go
.dointro


; copy binary to real destination
	move.l	a5,a0			; source
	lea	$70000,a1		; destination
	move.l	a1,a5
.copy	move.b	(a0)+,(a1)+
	subq.l	#1,d5
	bne.b	.copy

; patch boot
	lea	PLBOOT(pc),a0
	move.l	a5,a1
	jsr	resload_Patch(a2)

; set default copperlist
.go	lea	$300.w,a0
	move.l	#-2,(a0)
	move.l	a0,$dff080
	move.l	a0,$dff084

; and start game
	jmp	(a5)




QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	bsr.b	KillSys
	jmp	resload_Abort(a2)

AckVBI	move.w	#1<<4+1<<5+1<<6,$dff09c
	move.w	#1<<4+1<<5+1<<6,$dff09c
	rte

AckLev6	move.w	#1<<13,$dff09c
	move.w	#1<<13,$dff09c
	rte

KillSys	move.w	#$7fff,$dff09a		; disable all interrupts
	bsr	WaitRaster
	move.w	#$7ff,$dff096		; disable all DMA
	move.w	#$7fff,$dff09c		; disable all interrupt requests
	lea	AckVBI(pc),a0
	move.l	a0,$6c.w
	rts


; boot (game code actually but crunched), 2-disk version without intro

PLBOOT_NOINTRO
	PL_START
	PL_END


; boot, 2-disk version

PLBOOT	PL_START
	PL_ORW	$524+2,1<<3		; enable level 2 interrupt
	PL_ORW	$584+2,1<<9		; set Bplcon0 color bit
	PL_P	$4dc,AckVBI
	PL_PSA	$3a,.setVBI,$44		; flush cache before installing VBI
	PL_P	$97e,.setkbd
	PL_SA	$72,$8a			; skip Action Replay check
	PL_SA	$92,$a2			; skip protection stuff
	PL_R	$aac			; disable loader init
	PL_R	$b0e			; disable drive access (motor on)
	PL_R	$b3a			; disable drive access (motor off)
	PL_PSA	$be,.loadmus,$d2	; load "intro.mus"
	PL_P	$862,DECRUNCH_FUNGUS	; relocate Fungus decruncher
	PL_PS	$100,.initreplay	; flush cache before initialising replayer
	PL_PSA	$11a,.loadcredits,$12e	; load "credits.wrk"
	PL_PSA	$142,.patchcredits,$14e	; patch and run credits
	PL_PSA	$15a,.loadintro,$172	; load "intro.wrk"
	PL_PS	$1ee,.patchintro	; patch and run intro
	PL_PSA	$218,.loadvenus,$230	; load "venus.wrk"
	PL_P	$292,PatchVenus		; patch and run game
	PL_END

.setkbd	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts

.kbdcust
	move.b	RawKey(pc),$7fffe
	rts




.loadvenus
	move.l	a0,a1
	lea	VenusName(pc),a0
	move.l	resload(pc),a2
	jmp	resload_LoadFileDecrunch(a2)

.patchintro
	lea	PLINTRO(pc),a0
	lea	$8000,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	move.l	FORCEBLITWAITS(pc),d0
	bne.b	.doblit
	move.l	CPUFLAGS(pc),d0
	lsr.l	#1,d0
	bcc.b	.noblit
.doblit	lea	PLINTRO_BLIT(pc),a0
	lea	$8000,a1
	jsr	resload_Patch(a2)

.noblit

	jmp	$8002

.loadintro
	move.l	a0,a1
	lea	IntroName(pc),a0
	move.l	resload(pc),a2
	jmp	resload_LoadFileDecrunch(a2)
	

.patchcredits
	lea	PLCREDITS(pc),a0
	lea	$400.w,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	jmp	$400.w

.loadcredits
	move.l	a0,a1
	lea	CreditsName(pc),a0
	move.l	resload(pc),a2
	jmp	resload_LoadFileDecrunch(a2)
	

.initreplay
	move.l	resload(pc),a0
	jsr	resload_FlushCache(a0)
	jmp	$56660

.loadmus
	move.l	a0,a1
	lea	MusName(pc),a0
	move.l	resload(pc),a2
	jmp	resload_LoadFileDecrunch(a2)
	

.setVBI	move.l	resload(pc),a0
	jsr	resload_FlushCache(a0)
	move.l	#$6f000,$6c.w
	rts


; same code for the 2 supported versions hence
; no local label here!

PatchVenus

; install trainers
	moveq	#$19,d1
	lea	$400.w,a0
	move.l	TRAINEROPTIONS(pc),d0

; unlimited lives
	lsr.l	#1,d0
	bcc.b	.nolivestrainer
	eor.b	d1,$492(a0)
.nolivestrainer

; unlimited energy
	lsr.l	#1,d0
	bcc.b	.noenergytrainer
	move.b	#$60,$4484(a0)
.noenergytrainer

; unlimited ammo
	lsr.l	#1,d0
	bcc.b	.noammotrainer
	eor.b	d1,$400+$bbae
.noammotrainer


; unlimited credits
	lsr.l	#1,d0
	bcc.b	.nocreditstrainer
	eor.b	d1,$718(a0)
	eor.b	d1,$c6(a0)
	eor.b	d1,$d6(a0)
.nocreditstrainer

; unlimited time
	lsr.l	#1,d0
	bcc.b	.notimetrainer
	eor.b	d1,$400+$bbb0
.notimetrainer

; start with all weapons
	lsr.l	#1,d0
	bcc.b	.noweapontrainer
	eor.b	d1,$400+$bbaf
.noweapontrainer

	move.l	resload(pc),a2

	move.l	FORCEBLITWAITS(pc),d0
	bne.b	.doblitsgame
	move.l	CPUFLAGS(pc),d0
	lsr.l	#1,d0
	bcc.b	.noblitsgame
.doblitsgame
	lea	PLGAME_BLIT(pc),a0
	lea	$400.w,a1
	jsr	resload_Patch(a2)
.noblitsgame


; load high-scores
	lea	HighName(pc),a0
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nohigh
	lea	HighName(pc),a0
	lea	$400+$1156.w,a1
	jsr	resload_LoadFile(a2)
.nohigh

	lea	PLGAME(pc),a0
	lea	$400.w,a1
	jsr	resload_Patch(a2)
	jmp	$402.w

PLCREDITS
	PL_START
	PL_P	$164,AckVBI
	PL_ORW	$352+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$42a+2,1<<9		; set Bplcon0 color bit
	PL_PSS	$8e,.delayd0d1,2
	PL_PSS	$108,.delayd0d1,2
	PL_END


; 	move.w #count,d1
; .loop dbf d0,.loop
; 	dbf d1,.loop

.delayd0d1
.loop	move.w	#65535/34,d0
	bsr.b	.delay
	dbf	d1,.loop
	rts


; d0.w: # of raster lines to wait
.delay	move.l	d1,-(a7)
.delayloop
	move.b	$dff006,d1
.sameline
	cmp.b	$dff006,d1
	beq.b	.sameline	
	dbf	d0,.delayloop
	move.l	(a7)+,d1
	rts



PLINTRO	PL_START
	PL_ORW	$1fb4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1fc0+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1ffc+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2004+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$20f8+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2100+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2140+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2148+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$223c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$229c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$22dc+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$22e4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2324+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$232c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$241c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2424+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2460+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2468+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$255c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2564+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$25a4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$25ac+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$269c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$26a4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$26e4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$26ec+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2728+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2730+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2824+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2884+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$28c4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$28cc+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2908+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2910+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2990+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$29d8+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2a98+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2aa0+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$2b68+2,1<<9		; set Bplcon0 color bit

; DiwStrt fixes
	PL_W	$1ff4+2,$4881
	PL_W	$20a4+2,$2c81
	PL_W	$2134+2,$4881
	PL_W	$21e8+2,$2c81
	PL_W	$22d0+2,$4881
	PL_W	$2318+2,$4881
	PL_W	$23c8+2,$2c81
	PL_W	$2458+2,$4881
	PL_W	$2508+2,$2c81
	PL_W	$2598+2,$4881
	PL_W	$2648+2,$2c81
	PL_W	$26d8+2,$4881
	PL_W	$2720+2,$4881
	PL_W	$27d0+2,$2c81
	PL_W	$28b8+2,$4881
	PL_W	$2900+2,$a581
	PL_W	$2984+2,$4881
	PL_W	$2a8c+2,$4281
	PL_W	$2b5c+2,$2c81
	
	
; DDFstrt fixes
	PL_W	$1fec+2,$38
	PL_W	$209c+2,$5c
	PL_W	$212c+2,$38
	PL_W	$21e0+2,$7c
	PL_W	$22c8+2,$38
	PL_W	$2310+2,$38
	PL_W	$23c0+2,$60
	PL_W	$2450+2,$38
	PL_W	$2500+2,$5c
	PL_W	$2590+2,$38
	PL_W	$2640+2,$60
	PL_W	$26d0+2,$38
	PL_W	$2718+2,$38
	PL_W	$27c8+2,$5c
	PL_W	$28b0+2,$38
	PL_W	$28f8+2,$4f
	PL_W	$297c+2,$38
	PL_W	$2a84+2,$38
	PL_W	$2b54+2,$38


; DDFstop fixes
	PL_W	$1ff0+2,$d0
	PL_W	$20a0+2,$a4
	PL_W	$2130+2,$d0
	PL_W	$21e4+2,$c4
	PL_W	$22cc+2,$d0
	PL_W	$2314+2,$d0
	PL_W	$23c4+2,$a4
	PL_W	$2454+2,$d0
	PL_W	$2504+2,$a4
	PL_W	$2594+2,$d0
	PL_W	$2644+2,$a4
	PL_W	$26d4+2,$d0
	PL_W	$271c+2,$d0
	PL_W	$27cc+2,$a4
	PL_W	$28b4+2,$d0
	PL_W	$28fc+2,$d0
	PL_W	$2980+2,$d0
	PL_W	$2a88+2,$d0
	PL_W	$2b58+2,$d0


	PL_P	$ed2,AckVBI
	PL_P	$eea,DECRUNCH_FUNGUS	; relocate Fungus decruncher

	PL_PSA	$ee,.delay40000,$fc
	PL_PSA	$170,.delay40000,$17e
	PL_PSA	$232,.delay40000,$240
	PL_PSA	$300,.delay40000,$30e
	PL_PSA	$37a,.delay40000,$388
	PL_PSA	$4a0,.delay10000,$4ae
	PL_PSS	$71e,.delayd0d1,2
	PL_PSS	$7e8,.delayd0d1,2

; fix table with DDFSTRT/DDFSTOP/DIWSTRT/DIWSTOP/BPLCON1 values
	PL_PS	$e,.fixtab
	PL_END


.fixtab
	lea	$8000+$4c2c,a0		; start of tab
	move.w	#($4daa-$4c2c)/12-1,d7	; 6 words per entry
.tabloop	

	movem.w	(a0),d0-d3
	and.w	#$ff,d0			; fix ddfstrt
	and.w	#$ff,d1			; fix ddfstop
	move.b	#$81,d2			; fix diwstrt	

	movem.w	d0-d3,(a0)
	add.w	#6*2,a0			; next entry

	dbf	d7,.tabloop

	lea	$7204e,a0		; original code
	rts

.delay10000
	move.l	#10000/34,d0
	bra.b	.delay

.delay40000
	move.l	#40000/34,d0

; d0.w: # of raster lines to wait
.delay	move.l	d1,-(a7)
.delayloop
	move.b	$dff006,d1
.sameline
	cmp.b	$dff006,d1
	beq.b	.sameline	
	dbf	d0,.delayloop
	move.l	(a7)+,d1
	rts

; 	move.w #count,d1
; .loop dbf d0,.loop
; 	dbf d1,.loop

.delayd0d1
	exg	d0,d1
.loop	move.w	#65535/34,d0
	bsr.b	.delay
	dbf	d1,.loop
	rts
	

PLINTRO_BLIT
	PL_START
	PL_PSS	$c7c,.wblit1,2
	PL_PS	$185e,.wblit2
	PL_PSS	$1906,.wblit3,2
	PL_PSS	$1962,.wblit4,2
	PL_PSS	$1b06,.wblit5,2
	PL_END


.wblit1	move.w	#$100a,$dff058
.wblit	tst.b	$dff002
.wb1	btst	#6,$dff002
	bne.b	.wb1
	rts

.wblit2	move.w	d6,$dff058
	bra.w	.wblit

.wblit3	move.w	#$442,$dff058
	bra.w	.wblit

.wblit4	move.w	#$1ca,$dff058
	bra.w	.wblit

.wblit5	move.w	#$341,$dff058
	bra.w	.wblit


PLGAME	PL_START
	PL_ORW	$eb58+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$eb70+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$ec0c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$ec20+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$ecb0+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$f138+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$f1f4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$10abc+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$10b34+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$10be8+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$10c14+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$10c64+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$10d0c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$10db4+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$10dbc+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$10e20+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$10e6c+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$10f20+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$10f78+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$10fdc+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$11010+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$11070+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$11082+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1111a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$11196+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$11216+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1121e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$11276+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1127e+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$142f2+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1430a+2,1<<9		; set Bplcon0 color bit
	PL_ORW	$1435e+2,1<<9		; set Bplcon0 color bit
	

; DiwStrt fixes
	PL_W	$10a34+2,$4581
	PL_W	$10b60+2,$5581
	PL_W	$10c40+2,$7481
	PL_W	$10c84+2,$9081
	PL_W	$10d2c+2,$3781
	PL_W	$10dd8+2,$4581
	PL_W	$10e98+2,$3581
	PL_W	$10fa4+2,$6081
	PL_W	$1102c+2,$4581
	PL_W	$110a6+2,$7481
	PL_W	$1115a+2,$5c81
	PL_W	$111b6+2,$7081
	PL_W	$1123a+2,$5c81

; DDFstrt fixes
	PL_W	$eb1c+2,$38
	PL_W	$ec74+2,$38
	PL_W	$f1cc+2,$38
	PL_W	$10a2c+2,$38
	PL_W	$10b58+2,$38
	PL_W	$10c38+2,$38
	PL_W	$10c7c+2,$65
	PL_W	$10d24+2,$65
	PL_W	$10dd0+2,$38
	PL_W	$10e90+2,$38
	PL_W	$10f9c+2,$68
	PL_W	$11024+2,$38
	PL_W	$1109e+2,$38
	PL_W	$11152+2,$38
	PL_W	$111ae+2,$7c
	PL_W	$11232+2,$38
	PL_W	$142b6+2,$38
	PL_W	$1431e+2,$38
	

; DDFstop fixes
	PL_W	$eb20+2,$d0
	PL_W	$ebd8+2,$d8
	PL_W	$ec78+2,$d0
	PL_W	$f1d0+2,$d0
	PL_W	$10a30+2,$d0
	PL_W	$10b5c+2,$d0
	PL_W	$10c3c+2,$d0
	PL_W	$10c80+2,$a0
	PL_W	$10d28+2,$a0
	PL_W	$10dd4+2,$d0
	PL_W	$10e94+2,$d0
	PL_W	$10fa0+2,$a0
	PL_W	$11028+2,$d0
	PL_W	$110a2+2,$d0
	PL_W	$11156+2,$d0
	PL_W	$111b2+2,$90
	PL_W	$11236+2,$d0
	PL_W	$142ba+2,$d0
	PL_W	$14322+2,$d0
	
	
	PL_P	$1e06,.setkbd		; don't install new level 2 interrupt
	PL_P	$370c,AckVBI
	PL_ORW	$38+2,1<<3		; enable level 2 interrupt
	PL_SA	$40,$48			; skip write to ADKCONR
	PL_SA	$7b7c,$7b84		; skip write to $bfe201
	PL_SA	$100,$106		; skip write to $dff00a
	PL_SA	$52,$6a			; skip Action Replay check

	PL_R	$1f2e			; disable loader init
	PL_R	$1f90			; disable motor on
	PL_R	$1fbc			; disable motor off
	PL_P	$1cea,DECRUNCH_FUNGUS	; relocate Fungus decruncher
	PL_SA	$132,$14a		; disable level 7/cartridge check
	PL_R	$6432			; disable disk 2 request
	PL_SA	$2ad4,$2ae6		; disable loader init/protection check
	PL_P	$23c4,.load


	PL_PSS	$768,WaitRaster,4	; stage complete, set copperlist
	PL_P	$30f0,AckVBI
	PL_P	$2f90,AckVBI

	;PL_PSS	$85a,WaitRaster,4
	;PL_PSS	$898,.delay5000,4
	PL_PSS	$b18,WaitRaster,4
	PL_PSS	$b34,.delay5000,4
	;PL_PSS	$b70,WaitRaster,4
	PL_PSS	$12e60,WaitRaster,4	; 20000
	PL_PSS	$12cec,WaitRaster,2	; $ffff, bonus level
	PL_PSS	$1e2,.delayd0d1,2
	PL_PSS	$22a,.delayd0d1,2
	PL_PSS	$23e,.delayd0d1,2
	PL_PSS	$278,.delayd0d1,2
	PL_PSS	$28a,.delayd0d1,2
	PL_PSS	$2f2,.delayd0d1,2
	PL_PSA	$52e,.delay50000,$53a
	PL_PSA	$570,.delay50000,$57c	
	PL_PSA	$474,.delay8192,$480
	PL_PSA	$36c,.delay22000,$378	; $22000
	PL_PSA	$7ae,.delay30000,$7b8
	PL_PSA	$c7e,.delay8192,$c88
	PL_P	$1b0a,.delay18000	; $18000
	PL_PSS	$768,.delay20000_dbf,4
	PL_PSS	$85a,.delay60000_dbf,4
	PL_PSS	$898,.delay5000_dbf,4
	PL_PSS	$b70,.delay40000_dbf,4

****************************************************

; access fault fixes, that was a hell of a lot of
; work!

; fix tab init bug (move.b instead of move.l) which causes
; the access fault in the bonus level...
	PL_PSS	$1318c,.fixtabinit,2


; fix access faults in the "draw objects" routines
	PL_PS	$c43a,.acctest
	PL_PS	$c4c2,.acctest
	PL_PS	$c4ee,.acctest


****************************************************



; Self-modifying code fixes
	PL_PSS	$66c,.fixSMC,2
	PL_PSS	$1978,.flush,2
	PL_PS	$1cca,.fixSMC2
	PL_PS	$1c36,.fixSMC3
	PL_PS	$2d74,.fixSMC4
	PL_PS	$2d9c,.fixSMC5
	PL_PS	$12d4c,.fixSMC6


	PL_PSS	$2e5a,.savehigh,2


; make sure end sequence works correctly with "unlimited lives"
; option turned on
	PL_PS	$2a6,.check_end


	PL_IFC4
	PL_PS	$7b7c,.Jump_With_Fire2
	PL_ENDIF
	PL_END


.Jump_With_Fire2
	btst	#14-8,$dff016
	seq.b	$400+$7d47
	
	move.b	#1,$bfe201		; original code
	rts


.check_end
	clr.b	$400+$8abb		; clear lives, original code
	move.l	TRAINEROPTIONS(pc),d0	; if unlimited lives trainer
	lsr.l	#1,d0			; is enabled we have a special
	bcc.b	.normal			; case!
	st.b	$400+$8abb
.normal	rts


.savehigh
	move.l	TRAINEROPTIONS(pc),d0
	bne.b	.nohigh
	lea	HighName(pc),a0
	lea	$400+$1156.w,a1
	move.l	#$14a4-$1156,d0
	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)
.nohigh	move.b	#1,$400+$8aae
	rts


.acctest
	cmp.l	#$80000,d0
	bcs.b	.ok
	moveq	#0,d0
.ok	move.l	$400+$9d22,d3		; tab ptr
	rts


.fixtabinit
	move.l	#4,$400+$bc0e
	rts


.fixSMC6
	bsr.b	.flush
	tst.b	$400+$9e18
	rts

.fixSMC5
	bsr.b	.flush
	clr.w	$400+$11080
	rts

.fixSMC4
	bsr.b	.flush
	jmp	$400+$29c00

.fixSMC3
	bsr.b	.flush
	jmp	$400+$28700

.fixSMC2
	bsr.b	.flush
	lea	$75000,a0		; optimised original code
	rts

.fixSMC	move.b	#9,$400+$32c5
.flush	move.l	a0,-(a7)
	move.l	resload(pc),a0
	jsr	resload_FlushCache(a0)
	move.l	(a7)+,a0
	rts


; 	moveq	#0,d0
; .loop	addq.l	#1,d0
;	cmp.l	#50000,d0
;	bmi.b	.loop

.delay50000
	move.w	#50000/34,d0
	bra.b	.delay	

; same code as above except for different "timer" value
.delay8192
	move.w	#8192/34,d0
	bra.b	.delay

.delay22000
	move.w	#$22000/34,d0
	bra.b	.delay

.delay30000
	move.w	#30000/34,d0
	bra.b	.delay

.delay18000
	move.w	#$18000/34,d0
	bra.b	.delay

.delay5000_dbf
	move.w	#5000/34,d0
	bra.b	.delay

.delay20000_dbf
	move.w	#20000/34,d0
	bra.b	.delay

.delay40000_dbf
	move.w	#40000/34,d0
	bra.b	.delay

.delay60000_dbf
	move.w	#60000/34,d0
	bra.b	.delay


; 	move.w #count,d1
; .loop dbf d0,.loop
; 	dbf d1,.loop

.delayd0d1
.loop	move.w	#65535/34,d0
	bsr.b	.delay
	dbf	d1,.loop
	rts


.delay5000
	move.w	#5000/$34,d0


; d0.w: # of raster lines to wait
.delay	move.l	d1,-(a7)
.delayloop
	move.b	$dff006,d1
.sameline
	cmp.b	$dff006,d1
	beq.b	.sameline	
	dbf	d0,.delayloop
	move.l	(a7)+,d1
	rts









.load	move.l	resload(pc),a2
	jmp	resload_LoadFile(a2)

.setkbd	lea	.kbdcust(pc),a0
	move.l	a0,KbdCust-.kbdcust(a0)
	rts

.kbdcust
	lea	RawKey(pc),a0
	move.b	(a0),d0
	clr.b	(a0)
	;move.b	RawKey(pc),d0
	move.b	d0,$400+$1e54.w

	move.l	TRAINEROPTIONS(pc),d1
	and.w	#1<<OPT_KEYS,d1
	beq.w	.noingamekeys

	cmp.b	#$36,d0			; N - skip current level
	bne.b	.noN
	tst.b	$400+$b70a		; bonus level enabled?
	bne.b	.noN			; -> no level skip!
	move.w	#480,$400+$acdc
.noN
	cmp.b	#$11,d0			; W - skip current world
	bne.b	.noW
	tst.b	$400+$b70a		; bonus level enabled?
	bne.b	.noW			; -> no world skip!
	move.l	#5-1,$400+$8ac0		; last level in current world
	move.w	#480,$400+$acdc		; skip current level
.noW

	cmp.b	#$12,d0			; E - toggle unlimited energy
	bne.b	.noE
	eor.b	#$06,$400+$4484
.noE

	cmp.b	#$23,d0			; F - toggle flying ability
	bne.b	.noF
	not.w	$400+$ad4a
.noF

	cmp.b	#$21,d0			; S - show secret rooms
	bne.b	.noS
	st	$400+$c25d
	
.noS

	cmp.b	#$32,d0			; X - show end
	bne.b	.noX
	move.l	#9,$400+$8abc		; level number
	move.l	#5-1,$400+$8ac0		; last level in current world
	move.w	#480,$400+$acdc		; skip current level
.noX

	cmp.b	#$20,d0			; A - refill ammo
	bne.b	.noA
	move.l	#$09090900,$400+$b75c
.noA

.noingamekeys
	rts



PLGAME_BLIT
	PL_START
	PL_PSS	$5456,.wblit1,2		; 202
	PL_P	$54aa,.wblit1		; 202
	PL_PSS	$5558,.wblit1,2		; 202
	PL_PSS	$562c,.wblit2,4		; b30c
	PL_P	$56b4,.wblit2		; b30c
	PL_PSS	$58a2,.wblit3,2		; 402
	PL_P	$58f4,.wblit3		; 402
	PL_PSS	$59a2,.wblit3,2		; 402
	PL_PSS	$5b16,.wblit2,4		; b30c
	PL_PSS	$5b5a,.wblit2,4		; b30c
	PL_PSS	$5da4,.wblit2,4		; b30c
	PL_P	$5dfa,.wblit2		; b30c
	PL_PSS	$5e56,.wblit2,4		; b30c
	PL_PSS	$5f5e,.wblit2,4		; b30c
	PL_PSS	$616a,.wblit2,4		; b30c
	PL_PSS	$61e6,.wblit2,4		; b30c
	PL_PSS	$697c,.wblit4,2		; 401
	PL_PSS	$844c,.wblit4,2		; 401
	PL_PSS	$13928,.wblit2,4	; b30c
	PL_PSS	$13a94,.wblit2,4	; b30c
	PL_PSS	$13bf4,.wblit3,2	; 402
	PL_PSS	$13d4a,.wblit3,2	; 402
	PL_PSS	$13e74,.wblit1,2	; 202
	PL_PSS	$13f80,.wblit1,2	; 202
	PL_END

.wblit1	move.w	#$202,$dff058
.wblit	tst.b	$dff002
.wb	btst	#6,$dff002
	bne.b	.wb
	rts

.wblit2	move.w	$400+$b30c,$dff058
	bra.w	.wblit

.wblit3	move.w	#$402,$dff058
	bra.w	.wblit

.wblit4	move.w	#$401,$dff058
	bra.w	.wblit

FixDMAWait
	movem.l	d0/d1,-(a7)
	moveq	#5-1,d1	
.loop	move.b	$dff006,d0
.wait	cmp.b	$dff006,d0
	beq.b	.wait
	dbf	d1,.loop
	movem.l	(a7)+,d0/d1
	rts

WaitRaster
	move.l	d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.b	.wait
.wait2	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	beq.b	.wait2
	move.l	(a7)+,d0
	rts

***********************************
*** Level 2 IRQ			***
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


	btst	#3,$1e+1(a0)			; PORTS irq?
	beq.b	.end
	btst	#3,$d00(a1)			; KBD irq?
	beq.b	.end

	moveq	#0,d0
	move.b	$c00(a1),d0
	lea	Key(pc),a2
	move.b	d0,(a2)+
	not.b	d0
	ror.b	d0
	move.b	d0,(a2)

	move.l	KbdCust(pc),d1
	beq.b	.nocustom
	movem.l	d0-a6,-(a7)
	move.l	d1,a0
	jsr	(a0)
	movem.l	(a7)+,d0-a6
.nocustom	
	


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
	

.nokeys	moveq	#3-1,d1
.loop	move.b	$6(a0),d0
.wait	cmp.b	$6(a0),d0
	beq.b	.wait
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


Key	dc.b	0
RawKey	dc.b	0
KbdCust	dc.l	0			; ptr to custom routine



***********************************
** FUNGUS DECRUNCHER		***
***********************************

; this is an optimised version of the ByteKiller decruncher
; disassembled, adapted and optimised by stingray

FNG_NEXTLONG	MACRO
		add.l	d0,d0
		bne.b	*+18
		move.l	d4,d0
		move.l	d5,d4
		move.l	d6,d5
		move.l	d7,d6
		move.l	-(a0),d7
		move.w	#$FFFF,ccr
		addx.l	d0,d0
		ENDM	


DECRUNCH_FUNGUS
	move.l	#"*FUN",d0
	move.l	#"GUS*",d1
.getend	cmp.l	(a0)+,d0
	beq.b	.ok1
	cmp.l	(a0)+,d0
	bne.b	.getend
.ok1	cmp.l	(a0)+,d1
	bne.b	.getend

	subq.w	#8,a0
	move.l	-(a0),a2	; decrunched length
	add.l	a1,a2		; a2: end of decrunched data
	move.l	-(a0),d0	; get first long
	move.l	-(a0),d4	; plus the 4 following longs
	move.l	-(a0),d5
	move.l	-(a0),d6
	move.l	-(a0),d7

.loop	FNG_NEXTLONG
	bcs.b	.getcmd

	moveq	#3,d1		; next 3 bits: length of packed data
	moveq	#0,d3
	FNG_NEXTLONG
	bcs.b	.enter
	moveq	#1,d3
	moveq	#8,d1
	bra.w	.copyunpacked

.copypacked
	moveq	#8,d1
	moveq	#8,d3
.enter	bsr.w	.getbits
	add.w	d2,d3
.packedloop
	moveq	#8-1,d1
.getbyte
	FNG_NEXTLONG
	addx.w	d2,d2
	dbf	d1,.getbyte
	move.b	d2,-(a2)
	dbf	d3,.packedloop
	bra.b	.next

.getcmd	moveq	#0,d2
	FNG_NEXTLONG
	addx.w	d2,d2
	FNG_NEXTLONG
	addx.w	d2,d2
	cmp.b	#2,d2		; %10: unpacked data follows
	blt.b	.notpacked
	cmp.b	#3,d2		; %11: packed data follows
	beq.b	.copypacked

; %10
	moveq	#8,d1		; next byte
	bsr.b	.getbits
	move.w	d2,d3
	moveq	#12,d1
	bra.b	.copyunpacked

.notpacked
	moveq	#2,d3
	add.w	d2,d3
	moveq	#9,d1
	add.w	d2,d1
.copyunpacked
	bsr.b	.getbits
	lea	1(a2,d2.w),a3
.copy	move.b	-(a3),-(a2)
	dbf	d3,.copy

.next	cmp.l	a2,a1
	blt.w	.loop
	rts

; d0.l: stream
; d1.w: number of bits to get from stream 
; -----
; d2.w: new bits

.getbits
	subq.w	#1,d1
	clr.w	d2
.bitloop
	FNG_NEXTLONG
	addx.w	d2,d2
	dbf	d1,.bitloop
	rts


; decruncher for Venus The Flytrap, IPF 1985 version
; looks like Pack-Ice decruncher with changed ID
; disassembled and adapted (with parts of the original decruncher
; source by Axe/Delight) by stingray

DECRUNCH2
	movem.l	d0-d7/a0-a6,-(sp)
	cmp.l	#$63158666,(a0)+
	bne.b	.not_packed

	move.l	(a0)+,d0
	lea	-8(a0,d0.l),a5
	move.l	(a0)+,(sp)
	lea	$6C(a0),a4
	move.l	a4,a6
	add.l	(sp),a6
	move.l	a6,a3
	move.l	a6,a1
	lea	savebuf+120(pc),a2
	moveq	#120-1,d0
.copy	move.b	-(a1),-(a2)
	dbf	d0,.copy
	bsr.b	.getlong
	bsr.b	.ice_normal_bytes
	move.l	(sp),d0

	lea	-120(a4),a1
.copy2	move.b	(a4)+,(a1)+
	dbf	d0,.copy2

	sub.l	#$10000,d0
	bpl.b	.copy2

	moveq	#120-1,d0
	lea	savebuf+120(pc),a2
.copy3	move.b	-(a2),-(a3)
	dbf	d0,.copy3

.not_packed
	movem.l	(sp)+,d0-d7/a0-a6
	rts

.ice_normal_bytes
	bsr.b	.get_1_bit
	bcc.b	.test_if_end
	moveq	#0,d1
	bsr.b	.get_1_bit
	bcc.b	.copy_direkt		; Bitfolge: %10: 1 Byte direkt kop.
	lea	direkt_tab+20(pc),a1
	moveq	#4,d3
.nextgb	move.l	-(a1),d0		; d0.w Bytes lesen
	bsr.b	.get_d0_bits
	swap	d0
	cmp.w	d0,d1
	dbne	d3,.nextgb
	add.l	20(a1),d1		; Anzahl der zu uebertragenen Bytes
.copy_direkt
	move.b	-(a5),-(a6)
	dbf	d1,.copy_direkt
.test_if_end
	cmp.l	a4,a6
	bgt.b	.ice_strings
	rts

.getlong
	moveq	#3,d0
.glw	move.b	-(a5),d7
	ror.l	#8,d7
	dbf	d0,.glw
	rts

; get_d0_bits: Siehe weiter unten
.not_found
	move.w	a5,d7
	btst	#0,d7
	bne.b	.not_even
	move.l	-(a5),d7		; hole sonst ein weiteres longword
	addx.l	d7,d7
	bra.b	.on_d0

.not_even
	move.l	-5(a5),d7
	lsl.l	#8,d7
	move.b	-(a5),d7
	subq.l	#3,a5
	add.l	d7,d7
	bset	#0,d7
	bra.b	.on_d0

.get_1_bit
	add.l	d7,d7			; hole ein bit
	beq.b	.not_found2		; quellfeld leer
	rts

.not_found2
	move.w	a5,d7
	btst	#0,d7
	bne.b	.not_even2
	move.l	-(a5),d7		; hole sonst ein weiters longword
	addx.l	d7,d7			; hole ein bit
	rts

.not_even2
	move.l	-5(a5),d7
	lsl.l	#8,d7
	move.b	-(a5),d7
	subq.l	#3,a5
	add.l	d7,d7
	bset	#0,d7
	rts

.get_d0_bits
	moveq	#0,d1			; ergebnisfeld vorbereiten
.get_bit_loop
	add.l	d7,d7			; hole ein bit
	beq.b	.not_found		; quellfeld leer
.on_d0	addx.w	d1,d1			; und uebernimm es
	dbra	d0,.get_bit_loop	; bis alle bits geholt wurden
	rts

.ice_strings
	lea	length_tab(pc),a1	; a1 = Zeiger auf Tabelle
	moveq	#3,d2			; d2 = Zeiger in Tabelle
.get_length_bit
	bsr.b	.get_1_bit
	dbcc	d2,.get_length_bit

	moveq	#0,d4
	moveq	#0,d1
	move.b	1(a1,d2.w),d0		; d2: zw. -1 und 3; d3+1: Bits lesen
	ext.w	d0			; als Wort behandeln
	bmi.b	.no_ueber		; kein Ueberschuss noetig 
	bsr.b	.get_d0_bits
.no_ueber
	move.b	6(a1,d2.w),d4		; Standard-Laenge zu Ueberschuss add.
	add.w	d1,d4			; d4 = String-Laenge-2
	beq.b	.get_offs2		; Laenge = 2: Spezielle Offset-Routine

	lea	more_offset(pc),a1
	moveq	#1,d2
.get_offs
	bsr.b	.get_1_bit
	dbcc	d2,.get_offs
	moveq	#0,d1
	move.b	1(a1,d2.w),d0
	ext.w	d0
	bsr.b	.get_d0_bits
	add.w	d2,d2
	add.w	6(a1,d2.w),d1
	bra.b	.depack_bytes

.get_offs2
	moveq	#0,d1			; Ueberschuss-Offset auf 0 setzen
	moveq	#5,d0			; standard: 6 Bits holen
	moveq	#0,d2			; Standard-Offset auf 0
	bsr.b	.get_1_bit
	bcc.b	.less40			; Bit = %0
	moveq	#8,d0			; quenty fourty: 9 Bits holen
	moveq	#$40,d2			; Standard-Offset: $40
.less40	bsr.b	.get_d0_bits
	add.w	d2,d1			; Standard-Offset + Ueber-Offset

.depack_bytes				; d1 = Offset, d4 = Anzahl Bytes
	lea	2(a6,d4.w),a1		; Hier stehen die Originaldaten
	add.w	d1,a1			; Dazu der Offset
	move.b	-(a1),-(a6)		; ein Byte auf jeden Fall kopieren
.depack_loop
	move.b	-(a1),-(a6)		; mehr Bytes kopieren
	dbf	d4,.depack_loop
	bra.w	.ice_normal_bytes	; Jetzt kommen wieder normale Bytes


direkt_tab
	DC.L	$7FFF000E,$00FF0007,$00070002,$00030001
	DC.L	$00030001,$0000010D

	dc.l	15-1,8-1,5-1,2-1


length_tab
	dc.b 9,1,0,-1,-1
	dc.b 8,4,2,1,0


more_offset
	DC.W	$B04
	DC.W	$700
	DC.W	$120
	DC.W	0
	DC.W	$20


savebuf	ds.b	120

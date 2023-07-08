;*---------------------------------------------------------------------------
; Program:	StuntCarRacer.s
; Contents:	Slave for "Stunt Car Racer" from Geoff Crammond/Microstyle
; Author:	Codetapper of Action, StingRay
; History:	14.01.97 - v1.0
; 		         - Only Quartex crack supported
;		         - Full load from HD
;		         - Loads and saves driver information to a separate file (which can be
;		           unpacked back onto a disk using DiskWiz or a similar utility)
;		         - Save game for all 4 divisions and super division 4 included! Just select
;		           load from the main menu to play!
;		         - Quit option (default key is '*' on keypad)
;		12.12.99 - v1.1
;			 - Now supports Galahad's AGA fixed disk image
;		         - Trainer added (F1 to toggle infinite boost, Help to win the race)
;		         - Turbo mode included (toggle with F2)
;		         - ButtonWait tooltype added for loading picture
;		         - 24 bit access faults fixed (x2)
; 		16.02.02 - v1.2
;		         - Now supports the original (thanks to Galahad/Fairlight and Harry!)
;		         - Loads and saves fastest lap and track times
;		         - Loading a non existant save game no longer quits the game
;		         - Turbo mode code completely rewritten
;		         - When turbo mode is enabled, the word TURBO will appear in the top left
;		           corner of the screen to show that it is active
;		         - Tooltype CUSTOM1=1 added to automatically start with infinite boost
;		         - Tooltype CUSTOM2=1 added to automatically start with turbo mode enabled
;		         - Instructions included
;		         - Trainer keys changed to F6/F7 since game uses F1 to redefine keys while
;		           it is paused
;		         - Audio filter disabled for clearer sound
;		         - Beautiful RomIcon, NewIcon and GlowIcon (all created by Frank!) and 2 
;		           Exoticons (taken from http://exotica.fix.no)
;		         - Existing save game renamed from "highs" to "StuntCarRacer.save"
;		         - Slave heavily optimised
;		         - Quit key changed to F10
;		20.12.04 - v1.3
;		         - Supports the TNT version made by AmiGer/CARE
;		         - Fire button will bypass name entry sequence
;		         - Slave optimised (due to one of the decryption keys being wrong)
;		         - Turbo text will no longer corrupt any pictures in the top left corner
;		         - Icon modifications
;		08.07.23 - v1.4 (StingRay)
;                        - Keyboard problems fixed (issue #3512)
;                        - Slave code optimised and made pc-relative
;                        - Source can be assembled with ASM-One/Pro (routine
;                          _ToggleBoost had to be modified)
;                        - WHDLoad v17+ features used (config) 
; Requires:	WHDLoad 10+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly 2.9, Asm-Pro 1.16d
; Info:		$7a61a = Fastest lap times
;		$7a71a = Fastest track times
;		At $5c8ca, game copies the blank time information into the
;		fastest laps from $5cf30. Track times are saved everytime a
;		race is complete so it is best to cache writes for speed
;		and to reduce the number of O/S swaps.
;
;		Galahad reckoned the d7 decryption key for the game is 
;		$59fe104b which is incorrect! Harry did it correctly!
;---------------------------------------------------------------------------*

		INCDIR	SOURCES:Include/
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"StuntCarRacer.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_EmulTrap|WHDLF_NoError	;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	$1000			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	.config-_base		;ws_config


.config		dc.b	"C1:B:Infinite Boost;"
		dc.b	"C2:B:Turbo Mode;"
		dc.b	"BW"
		dc.b	0

;============================================================================

_name		dc.b	"Stunt Car Racer",0
_copy		dc.b	"1989 Geoff Crammond/Microstyle",0
_info		dc.b	"Installed by Codetapper/Action! & StingRay",10
		dc.b	"Version 1.4 "
		IFD	BARFLY
		IFND	.passchk
		DOSCMD	"WDate >T:date"
.passchk
		ENDC
		INCBIN	"T:date"
		ELSE
		dc.b	"(08.07.2023)"
		ENDC
		dc.b	-1,"Keys:   F6 - Toggle infinite boost   "
		dc.b	10,"        F7 - Toggle turbo mode on/off"
		dc.b	10,"      Help - Win race                "
		dc.b	-1,"Thanks to Harry, Carlo Pirri, AmiGer/CARE,"
		dc.b	10,"Galahad and Frank for the great icons!"
		dc.b	0
_PlayerName	dc.b	"Player      ",0
_TNTName	dc.b	"SCR-TNT",0
_TimesName	dc.b	"StuntCarRacer.times",0
_SaveName	dc.b	"StuntCarRacer.save",0
_TurboFlag	dc.b	0
		EVEN

;======================================================================
_Start						;A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;Save for later use

_restart	move.l	_expmem(pc),a0		;Stack to fast memory
		add.w	#$1000,a0
		move.l	a0,sp

		lea	_Tags(pc),a0		;Check parameters
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)

		lea	_SaveName(pc),a0	;Store save filesize
		jsr	resload_GetFileSize(a2)
		lea	_SaveFileSize(pc),a0
		move.l	d0,(a0)

		bset	#1,$bfe001		;Disable filter

		lea	_TNTName(pc),a0
		bsr	_GetFileSize
		bne	_TNTVersion

_DiskVersion	move.l	#$2c00,d0		;Load initial file
		move.l	#$9800,d1
		moveq	#1,d2
		lea	$59e8.w,a0
		move.l	a0,a5
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)

		cmp.l	#$6000007a,(a5)		;Check for the original
		bne.b	_CrackedIntro

		move.l	#$22b6,d0		;Length of encrypted data
		move.l	#$d6d17a1e,d5		;Decrypt intro
		move.l	#$54da0d34,d6
		move.l	#$54da0d1e,d7
		lea	$c98(a5),a0
		bsr	_Decrypt

		lea	$c9c(a5),a0		;Relocate intro
		move.l	a5,a1
		move.l	#$22b6-1,d0
_RelocateIntro	move.l	(a0)+,(a1)+
		dbf	d0,_RelocateIntro

_CrackedIntro	lea	_PL_Intro(pc),a0	;Patch intro
		move.l	a5,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		jmp	(a5)

;======================================================================

_PL_Intro	PL_START
		PL_L	$5a,$4e714e71		;Small delay before the title pic
		PL_W	$86,$0			;Black screen rather than red
		PL_PS	$124,_PatchMain		;Patch before main game
		PL_P	$570,_Loader		;Rob Northen loader
		PL_PSS	$f8,.Enable_Level2_Interrupts,2
		PL_END

.Enable_Level2_Interrupts
		bsr	Init_Level2_Interrupt
		move.w	#$2100,sr
		rts

;======================================================================

_PatchMain	cmp.l	#$6000007a,$e700	;Check for the original
		bne	_CrackedMain

		move.l	#$18ef8,d0		;Length of encrypted data
		move.l	#$c905b365,d5		;Decrypt key 1
		move.l	#$a0cff27b,d6		;Decrypt key 2
		move.l	#$59f3a592,d7		;Decrypt key 3 (from Harry)
		lea	$e700+$c98,a0
		move.l	a0,a2
		bsr	_Decrypt

		lea	$e700+$c9c,a0		;Relocate main game
		lea	$e700,a1
		move.l	#$18ef8,d0
_RelocateMain	move.l	(a0)+,(a1)+
		subq.l	#1,d0
		bne.s	_RelocateMain

		move.w	#($c9c>>2)-1,d0
		moveq	#0,d1
_ClearLoop	move.l	d1,(a1)+
		dbf	d0,_ClearLoop

_CrackedMain	bsr	_PicDelay

_GameCommon	movem.l	d0-d1/a0-a2,-(sp)

		move.l	_Custom1(pc),d0		;Check for initial infinite
		;tst.l	d0			;energy cheat
		beq.b	_CheckStartTurb
		bsr	_RefreshBoost

_CheckStartTurb	move.l	_Custom2(pc),d0		;Check for initial turbo
		;tst.l	d0			;mode
		beq.b	_PatchGame
		bsr	_ToggleTurbo

_PatchGame	lea	_PL_Game(pc),a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)

		move.l	_expmem(pc),d0
		add.l	#$1000,d0
		move.l	d0,$e73e		;Stack to fast memory
		move.l	d0,$5cf42		;Stack to fast memory

		movem.l	(sp)+,d0-d1/a0-a2
		jmp	$e700			;Start the fun!

_PL_Game	PL_START
		PL_S	$e70e,$26-$e		;Skip checksum
		PL_PS	$f036,_Keybd		;Detect quit key: ror.b #1,d0 and eori.b #$ff,d0
;		PL_W	$1ba42,$0		;Some palette thing?!
		PL_R	$59846			;Don't ask for floppy!
		PL_PS	$5b6bc,_SkipPlayerName	;Allow fire to skip name entry
		PL_L	$5b6c2,$4e714e71
		PL_PS	$5c960,_Copylock	;Crack in game copylock!
		PL_S	$5c966,$efa-$966
		PL_PS	$5dac0,_CheckTurboMode	;Alter delay and write TURBO
		PL_L	$5dac6,$4e714e71	;into the screen if turbo is
		PL_PS	$64516,_CheckTurboMode	;on, otherwise clear it
		PL_L	$6451c,$4e714e71
		PL_P	$5f2f8,_SaveTimes	;move.b ($1c947).l,(2,a1,d1.w)
		PL_L	$62d1c,$7a61a		;Change load location from $7a21a to $7a61a for fastest laps/track times
		PL_P	$62e86,_Loader		;Rob Northen loader
		PL_PS	$69fea,_24Bit_SwpMv_D0	;swap d0, move.w #$ffff,d0
		PL_PS	$6a06e,_24Bit_Add_2_A0	;adda.l #2,a0
		PL_END

;======================================================================

_Copylock	move.l	#$9cedcd02,d0		;Rob Northen copylock
		move.l	d0,($24).w
		rts

;======================================================================

_WinRace	move.b	#4,($1bb20).l		;Cheating bastard! :)
		rts

;======================================================================

_RefreshBoost	cmp.b	#0,$1ca20
		bne.b	_ToggleBoost
		move.b	#$80,($1ca20).l		;Lame trainer
_ToggleBoost	eor.l	#$65000008~$4e714e71,$60836
		rts

;======================================================================

_ToggleTurbo	move.l	a0,-(sp)
		lea	_TurboFlag(pc),a0
		not.b	(a0)
		move.l	(sp)+,a0
		rts

;======================================================================

_CheckTurboMode	movem.l	d0/a0-a1,-(sp)		;Check for turbo mode which

		move.b	_TurboFlag(pc),d0	;is at $5dac0 and $64516
		;tst.b	d0
		beq.b	_NormalMode

		lea	$6a594,a1
		bsr.b	_WriteTurboBMap
		lea	$72294,a1
		bsr.b	_WriteTurboBMap
		movem.l	(sp)+,d0/a0-a1

.BlitWait	btst	#6,$dff002		;At least wait for the blitter!
		bne.b	.BlitWait
		move.b	#0,$616d8		;Set the delay as ready
		rts

_NormalMode	lea	$6a594,a1
		bsr.b	_ClearTurboBMap
		lea	$72294,a1
		bsr.b	_ClearTurboBMap
		movem.l	(sp)+,d0/a0-a1

.Wait		tst.b	($616d8).l		;$4a39000616d8
		bne.b	.Wait			;$6600fff8
		rts

;======================================================================

_WriteTurboBMap	lea	_TurboText(pc),a0	;Paste TURBO writing into
		move.l	(a0)+,d0		;the bitmap
		cmp.l	#$fff3f3f,4(a1)		;Only paste during game when
		bne.b	_Rts			;the car frame is showing
		or.l	d0,(a1)
		move.l	(a0)+,d0
		or.l	d0,40(a1)
		move.l	(a0)+,d0
		or.l	d0,80(a1)
		move.l	(a0)+,d0
		or.l	d0,120(a1)
		move.l	(a0)+,d0
		or.l	d0,160(a1)
_Rts		rts

_ClearTurboBMap	cmp.l	#$fff3f3f,4(a1)
		bne.b	_Rts
		and.l	#$ff,(a1)		;Clear TURBO writing from
		and.l	#$ff,40(a1)		;the bitmap
		and.l	#$ff,80(a1)
		and.l	#$ff,120(a1)
		and.l	#$ff,160(a1)
		rts

;======================================================================

_24Bit_SwpMv_D0	swap	d0			;Stolen code
		move.w	#$FFFF,d0
		bra.b	_24Bit_Fix_A0

_24Bit_Add_2_A0	bsr.b	_24Bit_Fix_A0
		addq.l	#2,a0			;Stolen code
		rts

_24Bit_Fix_A0	move.l	d0,-(sp)		;Fix 24 bit A0 bug
		move.l	a0,d0
		and.l	#$ffffff,d0
		movea.l	d0,a0
		move.l	(sp)+,d0
		rts

;======================================================================

_SkipPlayerName	cmpi.b	#' ',(1,a0,d0.w)
		bne.b	.NotBlankName
		movem.l	d0/d1/a0/a1,-(sp)
		movea.l	a0,a1
		lea	_PlayerName(pc),a0
		moveq	#11,d1
.CopyPlayerName	move.b	(a0)+,(1,a1,d0.w)
		addq.l	#1,d0
		dbra	d1,.CopyPlayerName
		movem.l	(sp)+,d0/d1/a0/a1
.NotBlankName	rts

;======================================================================

_Keybd		ror.b	#1,d0			;Stolen 6 bytes
		eor.b	#$ff,d0
		cmp.b	_keyexit(pc),d0
		beq.w	_exit
		cmp.b	#$55,d0			;F6 = Refresh boost
		beq.w	_RefreshBoost
		cmp.b	#$56,d0			;F7 = Switch turbo on/off
		beq.w	_ToggleTurbo
		cmp.b	#$5f,d0			;Help = Win the race!
		beq.w	_WinRace
		rts

;======================================================================

_SaveTimes	move.b	($1c947).l,(2,a1,d1.w)	;Stolen code

		movem.l	d0-d1/a0-a2,-(sp)

		lea	_TimesName(pc),a0	;a0 = Name
		lea	$7a61a,a1		;a1 = Address
		move.l	#$200,d0		;d0 = Size
		move.l	_resload(pc),a2
		jsr	resload_SaveFile(a2)

		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_Loader		movem.l	d1-d4/a0-a3,-(sp)

                move.l  _resload(pc),a2		;a0 = Address
		mulu	#$200,d1		;d1 = Offset
		mulu	#$200,d2		;d2 = Length
		cmp.l	#$dc00,d1		;Initial game load
		beq.b	_DiskLoad
		cmp.l	#$a00,d1		;When game starts, it loads this
		beq.b	_TimesLoad

		move.l	d2,d0			;d0 = Length
		move.l	a0,a1			;a1 = Source
		lea	_SaveName(pc),a0	;a0 = Name
		lea	_SaveFileSize(pc),a3	;a3 = Save game file size
		move.l	d1,d4
		add.l	d0,d4			;d4 = Minimum file size required
		cmp.w	#1,d3			;0 = read, 1 = write
		beq.b	_Save

		move.l	(a3),d3			;Check that the load operation
		cmp.l	d4,d3			;will work
		blt.b	_DiskOpDone

		jsr	resload_LoadFileOffset(a2)
		bra.b	_DiskOpDone

_Save		jsr	resload_SaveFileOffset(a2)

		cmp.l	(a3),d4
		blt.b	_DiskOpDone
		move.l	d4,(a3)			;Save new file length
		bra.b	_DiskOpDone

_DiskLoad	move.l	d1,d0			;d0 = offset (bytes)
		move.l	d2,d1			;d1 = length (bytes)
		moveq	#1,d2			;d2 = disk
		jsr	resload_DiskLoad(a2)	;a0 = destination

_DiskOpDone	movem.l	(sp)+,d1-d4/a0-a3
		moveq	#0,d0
		rts

_TimesLoad	move.l	a0,a1			;a1 = Source
		lea	_TimesName(pc),a0

		movem.l	d0-d1/a0-a1,-(sp)
		jsr	resload_GetFileSize(a2)
		move.l	d0,d3
		movem.l	(sp)+,d0-d1/a0-a1
		
		cmp.l	#$200,d3
		bne.b	_DiskOpDone

		jsr	resload_LoadFile(a2)
		bra.b	_DiskOpDone

;======================================================================

_Decrypt	movem.l	d0/d5-d7/a0,-(sp)	;Rob Northen Decryption (3 Key)
.DecryptLoop	lsl.l	#1,d7
		btst	d5,d7
		beq.s	.Skip1
		btst	d6,d7
		beq.s	.Skip3
		bra.s	.Skip2
.Skip1		btst	d6,d7
		beq.s	.Skip2
.Skip3		addq.l	#1,d7			;Modify key for correct btst otherwise fuckup!
.Skip2		add.l	d7,(a0)			;Modify key to encrypted data = correct data
		add.l	(a0)+,d7		;Modify key with next encrypted longword
		subq.l	#1,d0			;Subtract from counter until null
		bne.s	.DecryptLoop
		movem.l	(sp)+,d0/d5-d7/a0
		rts

;======================================================================

_PicDelay	movem.l	d0-d1/a0-a2,-(sp)	;Show title pic until the
		move.l	_ButtonWait(pc),d0	;user hits a button if
		;tst.l	d0			;the buttonwait tooltype
		beq.b	_ButtonWaitDone		;was set
		lea	$bfe001,a0
_WaitButton	btst	#6,(a0)
		beq.s	_ButtonWaitDone
		btst	#7,(a0)
		bne.s	_WaitButton
_ButtonWaitDone	movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_TurboText	dc.l	$F4B9C600		;This 32x5 bitmap says TURBO
		dc.l	$14A52900
		dc.l	$14B9C900
		dc.l	$14A52900
		dc.l	$1325C600

;======================================================================

_TNTVersion	lea	$1000.w,a1
		move.l	a1,a5
		move.l	_resload(pc),a2
		jsr	resload_LoadFileDecrunch(a2)

		cmp.l	#$e700,$28e(a5)		;Check for right version
		bne.w	_DiskVersion

		move.l	a5,a0
		sub.l	a1,a1
		jsr	resload_Relocate(a2)	;Relocate AmigaDOS file

		lea	_PL_TNTIntro(pc),a0	;Patch the game
		move.l	a5,a1
		jsr	resload_Patch(a2)

		jmp	(a5)			;Start the action!

_PL_TNTIntro	PL_START
		PL_P	$38,_CopyTNTPatch	;Copies patch to $7e000
		PL_R	$5a			;Find task, WB message
		PL_S	$c0,$cc-$c0		;Don't alter bplcon3, fmode
		PL_R	$11c			;Disk access
		PL_L	$14a,$4e714e71		;Stack is too small = Snoop faults
		PL_P	$264,_TNTSpecific	;jmp $e700
		PL_END

_TNTSpecific	move.l	#$00020113,$2b986	;Correct colours on preview from reds->blues
		bra.w	_GameCommon		;(starts at $2b974 - called at $5d228)

;======================================================================

_CopyTNTPatch	move.l	_expmem(pc),a1		;Copy the patches to
		movea.l	a1,a2			;fast memory
		move.w	#$9c0>>2,d7
.CopyTNTLoop	move.l	(a0)+,(a1)+
		dbra	d7,.CopyTNTLoop
		bsr.b	_FlushCache
		jmp	(a2)

;======================================================================

_GetFileSize	movem.l	d1/a0-a2,-(sp)
		move.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)
		movem.l	(sp)+,d1/a0-a2
		tst.l	d0
		rts

_FlushCache	movem.l	d0-d1/a0-a2,-(sp)
		move.l	_resload(pc),a2
		jsr	resload_FlushCache(a2)
		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================
_resload	dc.l	0			;Resident loader
_Tags		dc.l	WHDLTAG_BUTTONWAIT_GET
_ButtonWait	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
_Custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_Custom2	dc.l	0
		dc.l	TAG_DONE
_SaveFileSize	dc.l	0
;======================================================================

_exit		pea	(TDREASON_OK).w
		bra.b	_end
_debug		pea	(TDREASON_DEBUG).w
_end		move.l	(_resload,pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts
;======================================================================

Init_Level2_Interrupt
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
	move.b	$bfec01-$bfe001(a1),d0
	not.b	d0
	ror.b	d0
	or.b	#1<<6,$e00(a1)			; set output mode

	bsr.b	Check_Quit_Key
	
	moveq	#3,d0
	bsr.b	Wait_Raster_Lines

	and.b	#~(1<<6),$e00(a1)	; set input mode
.end	move.w	#1<<3,$9c(a0)
	move.w	#1<<3,$9c(a0)		; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-d1/a0-a2
	rte


Check_Quit_Key
	cmp.b	_base+ws_keyexit(pc),d0
	beq.w	_exit
	rts	


; d0.w: number of raster lines to wait
Wait_Raster_Lines
	move.w	d1,-(a7)
.loop	move.b	$dff006,d1
.still_in_same_raster_line
	cmp.b	$dff006,d1
	beq.b	.still_in_same_raster_line	
	subq.w	#1,d0
	bne.b	.loop
	move.w	(a7)+,d1
	rts

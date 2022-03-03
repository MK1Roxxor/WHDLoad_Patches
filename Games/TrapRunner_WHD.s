***************************************************************************
*             /                                                           *
*       _____.__ _                                         .___.          *
*      /    /_____________.  _________.__________.________ |   |________  *
*  ___/____      /    ____|_/         |         /|        \|   ._      /  *
*  \     \/      \    \     \    /    |    :___/¯|    \    \   |/     /   *
*   \_____________\___/_____/___/_____|____|     |____|\_____________/    *
*     -========================/===========|______\================-      *
*                                                                         *
*   .---.----(*(       TRAP RUNNER WHDLOAD SLAVE            )*)---.---.   *
*   `-./                                                           \.-'   *
*                                                                         *
*                         (c)oded by StingRay                             *
*                         --------------------                            *
*                              March 2022                                 *
*                                                                         *
*                                                                         *
***************************************************************************

***********************************
*** History			***
***********************************

; 03-Mar-2022	- work started
;		- and finished a few hours later, all OS stuff patched,
;		  copperlist problems fixed, a few trainer options added


	INCDIR	SOURCES:INCLUDE/
	INCLUDE	WHDLoad.i


FLAGS		= WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap
QUITKEY		= $59		; F10
;DEBUG

; Trainer options
TRB_LIVES	= 0		; unlimited lives	
TRB_INV		= 1		; invincibility
TRB_KEYS	= 2		; in-game keys


RAWKEY_1	= $01
RAWKEY_2	= $02
RAWKEY_3	= $03
RAWKEY_4	= $04
RAWKEY_5	= $05
RAWKEY_6	= $06
RAWKEY_7	= $07
RAWKEY_8	= $08
RAWKEY_9	= $09
RAWKEY_0	= $0A

RAWKEY_Q	= $10
RAWKEY_W	= $11
RAWKEY_E	= $12
RAWKEY_R	= $13
RAWKEY_T	= $14
RAWKEY_Y	= $15		; English layout
RAWKEY_U	= $16
RAWKEY_I	= $17
RAWKEY_O	= $18
RAWKEY_P	= $19

RAWKEY_A	= $20
RAWKEY_S	= $21
RAWKEY_D	= $22
RAWKEY_F	= $23
RAWKEY_G	= $24
RAWKEY_H	= $25
RAWKEY_J	= $26
RAWKEY_K	= $27
RAWKEY_L	= $28

RAWKEY_Z	= $31		; English layout
RAWKEY_X	= $32
RAWKEY_C	= $33
RAWKEY_V	= $34
RAWKEY_B	= $35
RAWKEY_N	= $36
RAWKEY_M	= $37

RAWKEY_HELP	= $5f
	
; absolute skip
PL_SA	MACRO
	PL_S	\1,\2-(\1)
	ENDM

; jsr+absolute skip
PL_PSA	MACRO
	PL_PS	\1,\2		; could use PSS here but it fills memory
	PL_S	\1+6,\3-(\1+6)	; with NOPS so we use standard skip
	ENDM


HEADER	SLAVE_HEADER			; ws_security + ws_ID
	dc.w	17			; ws_version
	dc.w	FLAGS			; flags
	dc.l	$80000			; ws_BaseMemSize
	dc.l	0			; ws_ExecInstall
	dc.w	Patch-HEADER		; ws_GameLoader
	IFD	DEBUG
	dc.w	.dir-HEADER		; ws_CurrentDir
	ELSE
	dc.w	0			; ws_CurrentDir
	ENDC
	dc.w	0			; ws_DontCache
	dc.b	0			; ws_KeyDebug
	dc.b	QUITKEY			; ws_KeyExit
	dc.l	524288			; ws_ExpMem
	dc.w	.name-HEADER		; ws_name
	dc.w	.copy-HEADER		; ws_copy
	dc.w	.info-HEADER		; ws_info

; v16
	dc.w	0			; ws_kickname
	dc.l	0			; ws_kicksize
	dc.w	0			; ws_kickcrc

; v17
	dc.w	.config-HEADER		; ws_config


.config	dc.b	"C1:X:Unlimited Lives:",TRB_LIVES+"0",";"
	dc.b	"C1:X:Invincibility:",TRB_INV+"0",";"
	dc.b	"C1:X:In-Game Keys:",TRB_KEYS+"0",""
	dc.b	0

.dir	IFD	DEBUG
	dc.b	"SOURCES:WHD_Slaves/TrapRunner",0
	ENDC

.name	dc.b	"Trap Runner",0
.copy	dc.b	"2019 Retroguru",0
.info	dc.b	"installed by StingRay/[S]carab^Scoopex",10
	IFD	DEBUG
	dc.b	"DEBUG!!! "
	ENDC
	dc.b	"Version 1.00 (03.03.2022)",10
	dc.b	10
	dc.b	"In-Game Keys:",10
	dc.b	"E: Skip Level P: Get Potion",10
	dc.b	"I: Toggle Invincibility R: Red Hero",10
	dc.b	"W: White Hero",0

	CNOP	0,4


TAGLIST		dc.l	WHDLTAG_ATTNFLAGS_GET
ATTN_FLAGS	dc.l	0
		dc.l	TAG_DONE

resload	dc.l	0

Patch	lea	resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2

	lea	TAGLIST(pc),a0
	jsr	resload_Control(a2)

	; load bootblock
	lea	$1100.w,a0
	moveq	#0,d0
	move.l	#$400,d1
	moveq	#1,d2
	move.l	d1,d5
	move.l	a0,a5
	jsr	resload_DiskLoad(a2)

	; version check
	move.l	a5,a0
	move.l	d5,d0
	jsr	resload_CRC16(a2)
	cmp.w	#$9AEC,d0			; V1.2
	beq.b	.version_ok
	pea	(TDREASON_WRONGVER).w
	bra.w	EXIT


.version_ok

	; load crunched loader
	lea	$2000.w,a0
	move.l	#$4200,d0
	move.l	#$2200,d1
	moveq	#1,d2
	jsr	resload_DiskLoad(a2)

	; decrunch loader
	lea	$2000+4.w,a0
	lea	$65100,a1
	jsr	$9e(a5)				; decrunch

	; patch loader
	lea	PLLOADER(pc),a0
	lea	$65100,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)

	; set decrunched game size
	move.l	#$15a4c,d7 	

	; run the game
	jmp	$65100


; ---------------------------------------------------------------------------

PLLOADER
	PL_START
	PL_R	$1018				; disable loader init
	PL_P	$12ac,Load_Sectors
	PL_P	$810,FlushCache
	PL_PS	$776,.Get_Attn_Flags
	PL_B	$790,$60			; skip reading VBR
	PL_R	$79a
	PL_L	$5b0,$4ead0000			; jsr _LVOSuperVisor(a6) -> jsr 0(a5)
	PL_PSA	$59e,.Get_Video_Mode,$5a8
	PL_P	$5b4,.Set_Memory
	PL_SA	$664,$66a			; skip write to BEAMCON0
	PL_ORW	$690,1<<9			; set BPLCON0 color bit
	PL_B	$672+1,3-1			; don't access ECS/AGA registers
	PL_SA	$67c,$680			; skip write to FMODE
	PL_SA	$10b8,$1108
	PL_R	$680				; disable stack relocation
	PL_R	$108a				; disable drive access (motor off)

	PL_PS	$d8,Patch_Game
	PL_END



.Get_Attn_Flags
	move.l	ATTN_FLAGS(pc),d1
	moveq	#0,d2
	rts

.Get_Video_Mode
	moveq	#1,d0				; PAL
	rts

.Set_Memory
	move.l	HEADER+ws_ExpMem(pc),d1
	move.l	d1,-$7fc2(a4)
	move.l	d1,-$7fbe(a4)
	add.l	#262144,d1
	move.l	d1,-$7fca(a4)
	rts


Load_Sectors
	movem.l	d1-a6,-(a7)
	mulu.w	#512,d0
	mulu.w	#512,d1
	moveq	#1,d2
	move.l	resload(pc),a1
	jsr	resload_DiskLoad(a1)
	movem.l	(a7)+,d1-a6
	moveq	#0,d0				; no errors
	rts


FlushCache
	move.l	resload(pc),a1
	jsr	resload_FlushCache(a1)
	rte

; ---------------------------------------------------------------------------

Patch_Game
	movem.l	d0-a6,-(a7)
	lea	PLGAME(pc),a0
	move.l	HEADER+ws_ExpMem(pc),a1
	add.l	#262144,a1
	move.l	resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6

.wait	tst.b	-$7b3b(a4)
	beq.b	.wait
	rts


PLGAME	PL_START
	PL_W	$6ba+2,$0200			; fix BPLCON0 settings
	PL_R	$66a8				; disable loader init
	PL_R	$671a				; disable drive access (motor off)
	PL_SA	$6748,$6798
	PL_P	$693c,Load_Sectors
	PL_PSS	$8b2,.Fix_Copperlist,2
	PL_P	$8ee,.Fix_Copperlist2
	;PL_R	$a02				; disable write to BPLCON3
	;PL_R	$a0a				; disable write to BPLCON3
	PL_PS	$470c,.Check_Quit_Key

	PL_PS	$4caa,.Load_Settings
	PL_PS	$6ee8,.Save_Settings
	PL_PS	$6dcc,.Load_Hiscores

	; Adapt code to allow snoop on 68060
	; (ssp)+,<ea> is incompatible with Snoop/S on 68060
	PL_P	$622a,.Adapt_Snoop

	PL_IFC1
	; Trainer options used -> disable hiscore saving
	PL_S	$6f3a,6
	PL_ELSE
	PL_PS	$6f3a,.Save_Hiscores
	PL_ENDIF

	; Unlimited Lives
	PL_IFC1X	TRB_LIVES
	PL_B	$20de,$60
	PL_ENDIF

	; Invincibility
	PL_IFC1X	TRB_INV
	PL_B	$33a0,$60
	PL_ENDIF

	; In-Game Keys
	PL_IFC1X	TRB_KEYS
	PL_W	$1ff2,$4e71
	PL_P	$3392,.Toggle_Invincibility
	PL_ENDIF

	PL_END


.Toggle_Invincibility
	move.l	a0,-(a7)
	move.l	HEADER+ws_ExpMem(pc),a0
	add.l	#262144+$33a0,a0
	eor.b	#$06,(a0)		; bne <-> bra
	move.l	resload(pc),a0
	jsr	resload_FlushCache(a0)
	move.l	(a7)+,a0
	rts



.Adapt_Snoop
.loop	move.w	(a7)+,d1
	move.w	d1,(a0)+
	dbf	d0,.loop

	; back to calling routine
	move.l	HEADER+ws_ExpMem(pc),-(a7)
	add.l	#262144+$6230,(a7)
	rts


.Check_Quit_Key
	move.w	d0,-(a7)
	ror.b	d0
	not.b	d0
	bsr	Check_Quit_Key

	IFD	DEBUG
	cmp.b	#$36,d0
	bne.b	.no_level_skip
	move.w	#2*2,-$6076(a4)
.no_level_skip
	ENDC

	move.w	(a7)+,d0

	or.b	#1,$f00(a0)
	rts


.Load_Settings
	movem.l	a0/a2,-(a7)
	move.l	a0,a2

	lea	.Settings_Name(pc),a0
	bsr	File_Exists
	tst.l	d0
	beq.b	.no_settings_file
	lea	.Settings_Name(pc),a0
	move.l	a2,a1
	bsr	Load_File	

.no_settings_file
	movem.l	(a7)+,a0/a2
	cmp.l	#"OPTS",(a0)
	rts

; a0.l: game settings
.Save_Settings
	movem.l	d0-a6,-(a7)
	move.l	a0,a1
	lea	.Settings_Name(pc),a0
	move.l	#128,d0
.save	move.l	resload(pc),a2
	jsr	resload_SaveFile(a2)
	movem.l	(a7)+,d0-a6
	rts

.Load_Hiscores
	lea	.Hiscore_Name(pc),a0
	bsr	File_Exists
	tst.l	d0
	beq.b	.load_hiscores_from_disk
	lea	.Hiscore_Name(pc),a0
	move.l	a2,a1
	bra.w	Load_File	

.load_hiscores_from_disk
	move.l	a2,a0
	bra.w	Load_Sectors

; a1.l: end of hiscores
.Save_Hiscores
	movem.l	d0-a6,-(a7)
	move.l	#512,d0
	sub.l	d0,a1
	lea	.Hiscore_Name(pc),a0
	bra.b	.save


.Settings_Name	dc.b	"TrapRunner.opt",0
.Hiscore_Name	dc.b	"TrapRunner.high",0
		CNOP	0,2


.Fix_Copperlist2
	move.l	a0,-(a7)
	move.l	4(a0),a0
	bsr.b	Fix_Copperlist
	move.l	(a7)+,a0

	move.l	4(a0),$80(a6)
	rts

.Fix_Copperlist
	move.l	4(a1),a0
	move.l	a0,-$6536(a4)

	move.l	a0,-(a7)
	bsr.b	Fix_Copperlist
	move.l	(a7)+,a0
	rts


; This routine fixes several copperlist problems:
; - the BPLCON0 color bit will be set
; - all illegal BPLCON0 bits will be cleared

; a0.l: copperlist

Fix_Copperlist
.loop	cmp.w	#$0100,(a0)
	bne.b	.is_not_Bplcon0

	; clear illegal BPLCON0 bits
	and.w	#~(1<<0|1<<4|1<<5|1<<6|1<<7),2(a0)

	; set color bit
	or.w	#1<<9,2(a0)

.is_not_Bplcon0

	addq.w	#4,a0
	cmp.l	#$fffffffe,(a0)
	bne.b	.loop
	rts

; ---------------------------------------------------------------------------
; Support/helper routines.


QUIT	pea	(TDREASON_OK).w
EXIT	move.l	resload(pc),a2
	move.l	resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)


KillSys	move.w	#$7fff,$dff09a
	bsr.b	WaitRaster
	move.w	#$7ff,$dff096
	move.w	#$7fff,$dff09c
	rts


WaitRaster
.wait1	btst	#0,$dff005
	beq.b	.wait1
.wait2	btst	#0,$dff005
	bne.b	.wait2
	rts



; ---------------------------------------------------------------------------

; a0.l: file name
; a1.l: destination
; -----
; d0.l: file size

Load_File
	movem.l	d1-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_LoadFileDecrunch(a2)
	movem.l	(a7)+,d1-a6
	rts

; a0.l: file name
; ----
; d0.l : result (0 = file does not exist)
File_Exists
	movem.l	d1-a6,-(a7)
	move.l	resload(pc),a2
	jsr	resload_GetFileSize(a2)
	movem.l	(a7)+,d1-a6
	rts	


; ---------------------------------------------------------------------------


; d0.b: rawkey code

Check_Quit_Key
	cmp.b	HEADER+ws_keyexit(pc),d0
	beq.b	QUIT
	rts	


; Diagnostic only: enter Practice (1) or Race (2) through the native menu, then hold
; the native accelerator key. With DRIVING_REPLAY=N (Race only), release it after N
; CIA ticks and post Esc (raw key $45), whose handler requests the menu (game:5fde), then
; choose Instant Replay there. The key goes through the race's own dispatcher at the
; end of SOFT (game:03aa8): while a request is pending the CIA handler stops the ticks
; (game:09bea), so raising it from this interrupt could leave the original main loop
; waiting for a tick forever. This file is absent from normal builds.
driving_test_magic dc.b 'I5DR'
driving_test_ticks dc.l 0
driving_test_ready dc.w 0

driving_test_start
 movem.l d0-a6,-(sp)
 move.l motion_game(pc),a0
 adda.l #$2a59c,a0
 jsr (a0)
 lea driving_test_ready(pc),a0
 move.w #1,(a0)
 move.l motion_game(pc),a0
 adda.l #$7e4,a0
 jsr (a0)
 movem.l (sp)+,d0-a6
 rts

driving_test_menu
 move.l a0,-(sp)
 move.l motion_game(pc),a0
 adda.l #$28000,a0
 IFEQ DRIVING_TEST-2
 cmp.w #8,$3b0e(a0)        ; Main menu vs race-length submenu
 bne.s .race_length
 IFD DRIVING_REPLAY
 move.l d0,-(sp)
 move.l driving_test_ticks(pc),d0
 cmp.l #DRIVING_REPLAY,d0
 movem.l (sp)+,d0          ; keeps the flags
 bcs.s .race
 move.w #1,$3b0c(a0)       ; Instant Replay, after the race
 bra.s .selected
.race
 ENDC
 move.w #4,$3b0c(a0)       ; Race
 bra.s .selected
.race_length clr.w $3b0c(a0) ; first race-length choice (10 laps)
.selected
 ELSE
 move.w #2,$3b0c(a0)       ; native Main menu: Practice
 ENDC
 move.l (sp)+,a0
 rts

driving_test_input
 move.l a0,-(sp)
 lea driving_test_ready(pc),a0
 tst.w (a0)
 beq.s .native
 lea driving_test_ticks(pc),a0
 addq.l #1,(a0)
 IFD DRIVING_REPLAY
 cmp.l #DRIVING_REPLAY,(a0)
 bcs.s .accelerate
 bne.s .native
 move.l motion_game(pc),a0
 adda.l #$10000,a0
 bclr #0,-$61e4(a0)        ; release the accelerator
 bset #7,-$61dd(a0)        ; Esc event, game:9e23
 bset #0,-$610c(a0)        ; key event pending, game:9ef4
 bra.s .native
.accelerate
 ENDC
 move.l motion_game(pc),a0
 adda.l #$10000,a0
 bset #0,-$61e4(a0)        ; held keypad/up accelerator, game:9e1c
.native move.l motion_game(pc),a0
 adda.l #$10000,a0
 addq.w #1,-$64d8(a0)      ; original game:9b28 counter and CCR
 move.l (sp)+,a0
 rts

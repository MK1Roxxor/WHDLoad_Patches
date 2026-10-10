; CPU equivalent of the game's line blits (game:0b92c-0bad4). The native code
; draws each line as four line-mode blits, one per plane: minterm $CA, A = one
; dot, B = the plane's colour word, C = D = the bitmap, waiting after each.
; Entry from the native octant selection: d0 = major delta, d1 = minor delta,
; d2 = BLTCON1 octant code. The pen and start word come from the native moveto
; (game:e84a, BLTCON0 shift at game:e830). The native tail at game:0bad8
; then moves the pen as before.

line_cpu
 IFD VERIFY
 bra.w verify_line
 ELSE
 bsr.s line_draw
 bne.s line_native
 move.l motion_game(pc),-(sp)
 add.l #$bad8,(sp)
 rts
 ENDC

; Colour words other than 0/$FFFF would need B rotation: keep the blits.
line_native
 asl.w #2,d1                ; replaced native instructions
 add.w d0,d0
 move.w d1,$dff062
 move.l motion_game(pc),-(sp)
 add.l #$b936,(sp)
 rts

; Z set: drawn. Z clear: colour words need the native path. All registers kept.
line_draw
 movem.l d0-d7/a0-a4,-(sp)
 move.l motion_game(pc),a1
 adda.l #$10000,a1
 lea -$17dc(a1),a0          ; game:e824, colour words for planes 0-3
 moveq #0,d3
 moveq #0,d4
.colour move.w (a0)+,d5
 beq.s .next
 cmp.w #$ffff,d5
 bne.w .native
 bset d4,d3
.next addq.w #1,d4
 cmp.w #4,d4
 bne.s .colour
 add.w d3,d3
 lea line_plot_table(pc),a2
 adda.w (a2,d3.w),a2
 ; The native register arithmetic, including its stored copies.
 asl.w #2,d1                ; 4dy
 add.w d0,d0                ; 2dx
 move.w d1,d4               ; BLTBMOD
 sub.w d0,d1
 bpl.s .sign
 ori.w #$40,d2              ; SIGN
.sign ext.l d1
 move.l d1,-$17be(a1)       ; game:e842, BLTAPT
 move.w d1,d7               ; accumulator
 sub.w d0,d1                ; BLTAMOD
 move.w d2,-$17ce(a1)       ; game:e832, BLTCON1
 move.w d0,d6
 asl.w #5,d6
 addi.w #66,d6
 move.w d6,-$17ae(a1)       ; game:e852, BLTSIZE
 lsr.w #6,d6                ; height; 0 means 1024
 subq.w #1,d6
 and.w #1023,d6
 move.l -$17b6(a1),a0       ; game:e84a, first word
 IFD VERIFY
 add.l verify_shift(pc),a0
 ENDC
 move.w -$17d0(a1),d0       ; game:e830, BLTCON0 shift
 rol.w #4,d0
 and.w #15,d0
 move.w #$8000,d3
 lsr.w d0,d3
 moveq #0,d5
 movea.w #40,a3             ; BLTCMOD: one row down
 btst #4,d2                 ; SUD: the conditional step is in y
 beq.s .ymajor
 btst #3,d2                 ; SUL
 beq.s .xdown
 movea.w #-40,a3
.xdown btst #2,d2           ; AUL
 bne.s .xleft
; x-major: x steps every dot, y when the sign is clear. Dots in one word
; and row are written together.
.xright or.w d3,d5
 tst.w d7
 bmi.s .xr_b
 add.w d1,d7
 jsr (a2)
 adda.w a3,a0
 bra.s .xr_x
.xr_b add.w d4,d7
.xr_x lsr.w #1,d3
 bne.s .xr_n
 jsr (a2)
 addq.l #2,a0
 move.w #$8000,d3
.xr_n dbf d6,.xright
 bra.s .flush
.xleft or.w d3,d5
 tst.w d7
 bmi.s .xl_b
 add.w d1,d7
 jsr (a2)
 adda.w a3,a0
 bra.s .xl_x
.xl_b add.w d4,d7
.xl_x add.w d3,d3
 bne.s .xl_n
 jsr (a2)
 subq.l #2,a0
 moveq #1,d3
.xl_n dbf d6,.xleft
 bra.s .flush
; y-major: y steps every dot, x when the sign is clear.
.ymajor btst #2,d2          ; AUL
 beq.s .ydown
 movea.w #-40,a3
.ydown btst #3,d2           ; SUL
 bne.s .yleft
.yright or.w d3,d5
 jsr (a2)
 tst.w d7
 bmi.s .yr_b
 add.w d1,d7
 lsr.w #1,d3
 bne.s .yr_y
 addq.l #2,a0
 move.w #$8000,d3
 bra.s .yr_y
.yr_b add.w d4,d7
.yr_y adda.w a3,a0
 dbf d6,.yright
 bra.s .registers
.yleft or.w d3,d5
 jsr (a2)
 tst.w d7
 bmi.s .yl_b
 add.w d1,d7
 add.w d3,d3
 bne.s .yl_y
 subq.l #2,a0
 moveq #1,d3
 bra.s .yl_y
.yl_b add.w d4,d7
.yl_y adda.w a3,a0
 dbf d6,.yleft
 bra.s .registers
.flush jsr (a2)
; Leave the static blitter registers as the last native line blit did.
.registers lea $dff000,a0
 move.w -$17d0(a1),$40(a0)  ; BLTCON0
 move.w d2,$42(a0)          ; BLTCON1
 move.w #40,$60(a0)         ; BLTCMOD
 move.w d4,$62(a0)          ; BLTBMOD
 move.w d1,$64(a0)          ; BLTAMOD
 move.w #40,$66(a0)         ; BLTDMOD
 move.w -$17d6(a1),$72(a0)  ; BLTBDAT, plane 3 colour
 move.w #$8000,$74(a0)      ; BLTADAT
 movem.l (sp)+,d0-d7/a0-a4
 cmp.w d0,d0                ; Z: drawn
 rts
.native movem.l (sp)+,d0-d7/a0-a4 ; keeps Z clear from the colour test
 rts

; d5 = dots in the word at a0, written to the four planes; d5 is cleared.
line_plot MACRO
line_plot_\1
 move.w d5,d0
 beq.s .r\@
 not.w d0
 IFNE (\1)&1
 or.w d5,(a0)
 ELSE
 and.w d0,(a0)
 ENDC
 IFNE (\1)&2
 or.w d5,8000(a0)
 ELSE
 and.w d0,8000(a0)
 ENDC
 IFNE (\1)&4
 or.w d5,16000(a0)
 ELSE
 and.w d0,16000(a0)
 ENDC
 IFNE (\1)&8
 or.w d5,24000(a0)
 ELSE
 and.w d0,24000(a0)
 ENDC
 moveq #0,d5
.r\@ rts
 ENDM

line_plot_table
 dc.w line_plot_0-line_plot_table,line_plot_1-line_plot_table,line_plot_2-line_plot_table,line_plot_3-line_plot_table
 dc.w line_plot_4-line_plot_table,line_plot_5-line_plot_table,line_plot_6-line_plot_table,line_plot_7-line_plot_table
 dc.w line_plot_8-line_plot_table,line_plot_9-line_plot_table,line_plot_10-line_plot_table,line_plot_11-line_plot_table
 dc.w line_plot_12-line_plot_table,line_plot_13-line_plot_table,line_plot_14-line_plot_table,line_plot_15-line_plot_table

 line_plot 0
 line_plot 1
 line_plot 2
 line_plot 3
 line_plot 4
 line_plot 5
 line_plot 6
 line_plot 7
 line_plot 8
 line_plot 9
 line_plot 10
 line_plot 11
 line_plot 12
 line_plot 13
 line_plot 14
 line_plot 15

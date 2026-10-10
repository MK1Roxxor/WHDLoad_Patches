; CPU equivalents of the game's one-row four-plane blits.
; The existing polygon setup, edge tables, colours and span order stay intact.
span_kind dc.w 0             ; 0 colour, 1 C texture, 2 dither
span_fwm dc.w 0
span_lwm dc.w 0
span_pattern dc.w 0
span_count dc.w 0
span_dest dc.l 0
span_source dc.l 0
span_bdat dc.w 0
span_cdat dc.w 0
span_high dc.w 0,0,0
span_native_a2 dc.l 0
span_row_count dc.w 0
span_colour_function dc.l 0
span_binary dc.w 0
span_previous_edges dc.w 0,0
span_high_flip dc.w 0

span_solid
 lea span_kind(pc),a0
 clr.w (a0)
 bra.s span_start
span_texture
 lea span_kind(pc),a0
 move.w #1,(a0)
 bra.s span_start
span_dither
 lea span_kind(pc),a0
 move.w #2,(a0)
span_start
 movem.l d0-d1/d3,-(sp)
 lea span_high(pc),a0
 move.w (sp),(a0)+
 move.w 4(sp),(a0)+
 move.w 8(sp),(a0)
 movem.l (sp)+,d0-d1/d3
 move.w span_kind(pc),d4
 cmp.w #2,d4
 beq.s .pattern_ready
 lea span_pattern(pc),a0
 move.w #$ffff,(a0)
.pattern_ready move.l #$dff000,a0
 ; Complete any earlier blit before touching the bitmap.
.wait btst #6,2(a0)
 btst #6,2(a0)
 bne.s .wait
 moveq #6,d4
 IFD VERIFY
 bsr verify_polygon
 ELSE
 bsr span_rows
 ENDC
 ; Remove the internal hook's return; the original tail restores a2-a6.
 addq.l #4,sp
 move.l motion_game(pc),a5
 move.w span_kind(pc),d4
 cmp.w #1,d4
 beq.s .texture_tail
 cmp.w #2,d4
 beq.s .dither_tail
 adda.l #$bc3c,a5
 bra.s .tail
.texture_tail adda.l #$bd58,a5
 bra.s .tail
.dither_tail adda.l #$bea0,a5
.tail moveq #6,d4
 lea 2(a0),a6
 jmp (a5)

span_rows
 lea span_native_a2(pc),a0
 move.l a2,(a0)+
 move.w d6,(a0)
 movea.l a1,a6
 move.w span_kind(pc),d0
 tst.w d0
 bne.s .selected
 bsr span_select_colour
 bra.w span_colour_rows
.selected move.l d5,d2
 move.w d6,d7
.row
 move.w -2(a6),d0
 move.w 506(a6),d1
 cmp.w d1,d0
 blt.s .sorted
 exg d0,d1
 ; Preserve the original full-register sort after the prepared first row.
 cmp.w span_row_count(pc),d7
 beq.s .sorted
 bsr span_swap_high
.sorted add.w d0,d0
 add.w d1,d1
 move.w (a3,d0.w),d4
 move.w (a4,d1.w),d5
 lea span_fwm(pc),a0
 move.w d4,(a0)+
 move.w d5,(a0)
 moveq #0,d4
 move.w (a5,d0.w),d4
 move.w (a5,d1.w),d1
 sub.w d4,d1
 lsr.w #1,d1
 addq.w #1,d1
 lea span_count(pc),a0
 move.w d1,(a0)+
 move.l d2,d0
 add.l d4,d0
 IFD VERIFY
 add.l verify_shift(pc),d0
 ENDC
 move.l d0,(a0)
 movea.l d0,a0
 move.w span_kind(pc),d0
 cmp.w #1,d0
 beq.w .texture_row
 bra.w .dither_row
.texture_row
 moveq #0,d1
 move.b d2,d1
 move.l motion_game(pc),a1
 adda.l #$10000,a1
 add.w $2380(a1),d1
 add.w d4,d1
 add.l $237a(a1),d1
 lea span_source(pc),a1
 move.l d1,(a1)
 movea.l d1,a1
 move.w span_count(pc),d0
 cmp.w #3,d0
 bcc.s .texture_gpu
 bsr span_texture_narrow
 bra.s .texture_done
.texture_gpu bsr span_texture_batch
.texture_done lea span_high(pc),a1
 move.w span_source(pc),(a1)
 bra.s .next
.dither_row
 move.l motion_game(pc),a1
 adda.l #$10000,a1
 move.w -$17cc(a1),d0
 lea span_pattern(pc),a1
 move.w d0,(a1)
 and.w d0,d5
 bsr span_dither_plane
 bsr span_dither_plane
 bsr span_dither_plane
 bsr span_dither_plane
 subq.w #8,a2
 move.l motion_game(pc),a1
 adda.l #$10000,a1
 move.w $4836(a1),d0
 eor.w d0,-$17cc(a1)
.next
 add.l #40,d2
 addq.l #2,a6
 dbf d7,.row
 move.w span_kind(pc),d0
 cmp.w #1,d0
 bne.s .a2_ready
 move.l span_native_a2(pc),a2
 moveq #0,d0
 move.w span_row_count(pc),d0
 addq.w #1,d0
 lsl.l #3,d0
 suba.l d0,a2
.a2_ready move.l d2,d5
 move.l span_dest(pc),d2
 IFD VERIFY
 sub.l verify_shift(pc),d2
 ENDC
 move.w span_count(pc),d3
 add.w #64,d3
span_finish
 swap d3
 move.w span_high+4(pc),d3
 swap d3
 move.w span_high(pc),d0
 swap d0
 move.w span_kind(pc),d4
 cmp.w #1,d4
 bne.s .normal_high
 move.l span_source(pc),d0
.normal_high move.w span_high+2(pc),d1
 swap d1
 move.w -2(a6),d0
 move.w 506(a6),d1
 cmp.w d1,d0
 blt.s .end_sorted
 exg d0,d1
.end_sorted add.w d0,d0
 add.w d1,d1
 movea.l a6,a1
 move.l #$dff000,a0
 lea 2(a0),a6
 moveq #6,d4
 move.w #-1,d6
 move.w #7998,d7
.finish_wait btst #6,2(a0)
 btst #6,2(a0)
 bne.s .finish_wait
 bsr span_hardware
 rts

; One function call per plane, no per-word calls for the common variants.

span_colour_plane
 move.w (a2)+,d3
 move.w span_count(pc),d6
 move.w span_fwm(pc),d4
 cmp.w #1,d6
 bne.s .first
 and.w d5,d4
 bra.s .last_word
.first cmp.w #$ffff,d4
 bne.s .masked_first
 move.w d3,(a0)+
 bra.s .interior_setup
.masked_first move.w (a0),d0
 move.w d3,d1
 eor.w d0,d1
 and.w d4,d1
 eor.w d1,d0
 move.w d0,(a0)+
.interior_setup subq.w #2,d6
 beq.s .last
 ; Repeat the colour in both halves for longword stores to chip RAM.
 move.w d3,d0
 swap d3
 move.w d0,d3
 btst #0,d6
 beq.s .longs
 move.w d3,(a0)+
 subq.w #1,d6
 beq.s .last
.longs lsr.w #1,d6
 subq.w #1,d6
.interior move.l d3,(a0)+
 dbf d6,.interior
.last move.w d5,d4
.last_word move.w (a0),d0
 lea span_bdat(pc),a1
 move.w d0,(a1)+
 move.w d3,(a1)
 cmp.w #$ffff,d4
 bne.s .masked_last
 move.w d3,(a0)+
 bra.s .advance
.masked_last move.w d3,d1
 eor.w d0,d1
 and.w d4,d1
 eor.w d1,d0
 move.w d0,(a0)+
.advance move.w span_count(pc),d0
 add.w d0,d0
 suba.w d0,a0
 adda.w #8000,a0
 rts


; Four texture planes are four rows with the native C/B/D plane modulos.
; A masks are reapplied on every row; CON1 has no shift or fill carry.
span_texture_batch
 tst.w d7
 bne.s .post_ready
 move.w span_count(pc),d0
 add.w d0,d0
 subq.w #2,d0
 movea.l a0,a2
 adda.w #24000,a2
 move.w (a2,d0.w),d3
 lea span_bdat(pc),a2
 move.w d3,(a2)
 movea.l a1,a2
 adda.w #3240,a2
 move.w (a2,d0.w),d3
 lea span_cdat(pc),a2
 move.w d3,(a2)
; The modulos are computed before the wait, so the blit starts sooner.
.post_ready move.w span_count(pc),d0
 add.w d0,d0
 move.w #8000,d1
 sub.w d0,d1                ; B and D modulo
 neg.w d0
 add.w #1080,d0             ; C modulo
 move.l #$dff000,a2
.wait btst #6,2(a2)
 btst #6,2(a2)
 bne.s .wait
 move.w d1,$62(a2)
 move.w d1,$66(a2)
 move.w d0,$60(a2)
 move.w span_fwm(pc),$44(a2)
 move.w span_lwm(pc),$46(a2)
 move.l a1,$48(a2)
 move.l a0,$4c(a2)
 move.l a0,$54(a2)
 move.w span_count(pc),d1
 add.w #256,d1
 move.w d1,$58(a2)
 move.w span_count(pc),d0   ; native exit value
 add.w d0,d0
 rts

; One/two-word textures blend all four planes with one width dispatch.
; Original source and bitmap pointers are private; a0/a1 stay at row start.
texture_edge MACRO
 move.w \1(a0),d0
 move.w \2(a1),d1
 eor.w d0,d1
 and.w d4,d1
 eor.w d1,d0
 move.w d0,\1(a0)
 ENDM

span_texture_narrow
 move.w span_fwm(pc),d4
 move.w span_count(pc),d6
 cmp.w #1,d6
 bne.s .two
 and.w d5,d4
 bra.s .last
.two
 texture_edge 0,0
 texture_edge 8000,1080
 texture_edge 16000,2160
 texture_edge 24000,3240
 addq.w #2,a0
 addq.w #2,a1
 move.w d5,d4
.last
 ; Hardware latches retain the old B word and native C word.
 move.w 24000(a0),d0
 move.w 3240(a1),d1
 lea span_bdat(pc),a2
 move.w d0,(a2)+
 move.w d1,(a2)
 texture_edge 0,0
 texture_edge 8000,1080
 texture_edge 16000,2160
 texture_edge 24000,3240
 rts

span_texture_plane
 move.w span_count(pc),d6
 move.w span_fwm(pc),d4
 cmp.w #1,d6
 bne.s .first
 and.w d5,d4
 bra.s .last_word
.first
 move.w (a0),d0
 move.w (a1)+,d1
 eor.w d0,d1
 and.w d4,d1
 eor.w d1,d0
 move.w d0,(a0)+
 subq.w #2,d6
 beq.s .last
 subq.w #1,d6
.interior move.w (a1)+,(a0)+
 dbf d6,.interior
.last move.w d5,d4
.last_word move.w (a0),d0
 move.w (a1)+,d1
 move.w d1,d3
 movem.l a1,-(sp)
 lea span_bdat(pc),a1
 move.w d0,(a1)+
 move.w d3,(a1)
 movem.l (sp)+,a1
 eor.w d0,d1
 and.w d4,d1
 eor.w d1,d0
 move.w d0,(a0)+
 move.w span_count(pc),d0
 add.w d0,d0
 suba.w d0,a0
 adda.w #8000,a0
 suba.w d0,a1
 adda.w #1080,a1
 rts

span_dither_plane
 move.w (a2)+,d3
 move.w span_count(pc),d6
 move.w span_fwm(pc),d4
 and.w span_pattern(pc),d4
 cmp.w #1,d6
 bne.s .first
 and.w d5,d4
 bra.s .last_word
.first
 move.w (a0),d0
 move.w d3,d1
 eor.w d0,d1
 and.w d4,d1
 eor.w d1,d0
 move.w d0,(a0)+
 subq.w #2,d6
 beq.s .last
 subq.w #1,d6
 move.w span_pattern(pc),d4
.interior move.w (a0),d0
 move.w d3,d1
 eor.w d0,d1
 and.w d4,d1
 eor.w d1,d0
 move.w d0,(a0)+
 dbf d6,.interior
.last move.w d5,d4
.last_word move.w (a0),d0
 lea span_bdat(pc),a1
 move.w d0,(a1)+
 move.w d3,(a1)
 move.w d3,d1
 eor.w d0,d1
 and.w d4,d1
 eor.w d1,d0
 move.w d0,(a0)+
 move.w span_count(pc),d0
 add.w d0,d0
 suba.w d0,a0
 adda.w #8000,a0
 rts

span_hardware
 move.w sr,-(sp)
 movem.l d0-d7/a0-a6,-(sp)
 sub.w #65,d3
 add.w d3,d3
 ; Mirror the final row's hardware state, without starting a DMA blit.
 ; a0 remains CUSTOM. The final B/D pointers include the plane modulo.
 move.w #7998,d7
 sub.w d3,d7
 move.w d7,$62(a0)
 move.w d7,$66(a0)
 move.l span_dest(pc),d4
 add.l #32000,d4
 move.l d4,$4c(a0)
 move.l d4,$54(a0)
 move.w span_bdat(pc),$72(a0)
 move.w span_cdat(pc),$70(a0)
 move.w span_pattern(pc),$74(a0)
 move.w span_kind(pc),d4
 cmp.w #1,d4
 bne.s .hardware_done
 move.w #1078,d7
 sub.w d3,d7
 move.w d7,$60(a0)
 move.l span_source(pc),d4
 add.l #4320,d4
 move.l d4,$48(a0)
.hardware_done
 movem.l (sp)+,d0-d7/a0-a6
 move.w (sp)+,ccr
 rts


; Solid colours keep width and masks in registers and return the next
; bitmap row in a0. Identical sorted edge pairs reuse that setup.
span_colour_rows
 move.l d5,d2
 move.w d6,d7
 lea span_high_flip(pc),a1
 clr.w (a1)
 ; The prepared first row has already sorted the original full registers.
 move.w -2(a6),d0
 move.w 506(a6),d1
 cmp.w d1,d0
 blt.s .setup
 exg d0,d1
 bra.s .setup
.row move.w -2(a6),d0
 move.w 506(a6),d1
 cmp.w d1,d0
 blt.s .sorted
 exg d0,d1
 lea span_high_flip(pc),a1
 not.w (a1)
.sorted cmp.w span_previous_edges(pc),d0
 bne.s .setup
 cmp.w span_previous_edges+2(pc),d1
 beq.s .draw
.setup lea span_previous_edges(pc),a1
 move.w d0,(a1)+
 move.w d1,(a1)
 add.w d0,d0
 add.w d1,d1
 move.w (a3,d0.w),d3
 move.w (a4,d1.w),d5
 moveq #0,d4
 move.w (a5,d0.w),d4
 move.w (a5,d1.w),d6
 sub.w d4,d6
 lsr.w #1,d6
 addq.w #1,d6
 move.l d2,d0
 add.l d4,d0
 IFD VERIFY
 add.l verify_shift(pc),d0
 ENDC
 movea.l d0,a0
 move.w d3,d4
.draw bsr span_colour_constant
 add.l #40,d2
 addq.w #2,a6
 move.w a1,d6
 dbf d7,.row
 ; Apply full-register EXG parity once, before the native final edge load.
 move.w span_high_flip(pc),d0
 beq.s .high_ready
 bsr span_swap_high
.high_ready move.l d2,d5
 move.l a0,d2
 sub.l #40,d2
 lea span_dest(pc),a0
 move.l d2,(a0)
 IFD VERIFY
 sub.l verify_shift(pc),d2
 ENDC
 move.w d6,d3
 add.w #64,d3
 bra.w span_finish

span_swap_high
 move.l d0,-(sp)
 lea span_high(pc),a1
 move.w (a1),d0
 move.w 2(a1),d3
 move.w d3,(a1)
 move.w d0,2(a1)
 move.l (sp)+,d0
 rts

 include "Indianapolis500_Colour.s"

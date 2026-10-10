; VERIFY-only pixel twins. No reference game instructions are embedded:
; the three original hook ranges are captured before resload_Patch.
VERIFY_SHADOW = $80010
verify_magic dc.b 'I5PV'
verify_frames dc.l 0
verify_polygons dc.l 0
verify_failures dc.l 0
verify_guard_failures dc.l 0
verify_first_difference dc.l 0
verify_fixture_active dc.w 0
verify_fixture dc.w 0
verify_control_offset dc.w verify_custom3-verify_magic
verify_request dc.w 0
verify_original ds.b 24
verify_patched ds.b 8
verify_outputs ds.b 60
verify_end_sr dc.w 0
verify_shift dc.l 0
verify_bitmap dc.l 0
verify_hook dc.l 0
verify_function dc.l 0
verify_clear_original ds.b 8
verify_clear_patched ds.b 8
verify_planes_original ds.b 8      ; game:0c240
verify_planes_patched ds.b 8
verify_register_magic dc.b 'I5RG'
verify_register_failures dc.l 0
verify_cpu_outputs ds.b 40
verify_cpu_sr dc.w 0
verify_phase ds.b 12
verify_failure_phase ds.b 12
verify_failure_input ds.b 60
verify_failure_kind dc.w 0
verify_tags
 dc.l WHDLTAG_CUSTOM3_GET
verify_custom3 dc.l 0
 dc.l 0

verify_init
 movem.l d0-a6,-(sp)
 move.l motion_game(pc),a0
 adda.l #$10000,a0
 lea verify_original(pc),a1
 move.l -$444c(a0),(a1)+
 move.l -$4448(a0),(a1)+
 move.l -$4344(a0),(a1)+
 move.l -$4340(a0),(a1)+
 move.l -$41fc(a0),(a1)+
 move.l -$41f8(a0),(a1)+
 move.l motion_game(pc),a0
 adda.l #$c29a,a0
 lea verify_clear_original(pc),a1
 move.l (a0)+,(a1)+
 move.l (a0),(a1)
 move.l motion_game(pc),a0
 adda.l #$c240,a0
 lea verify_planes_original(pc),a1
 move.l (a0)+,(a1)+
 move.l (a0),(a1)
 move.l motion_game(pc),a0
 adda.l #$b92c,a0
 lea verify_line_original(pc),a1
 move.l (a0)+,(a1)+
 move.l (a0),(a1)
 lea verify_tags(pc),a0
 move.l resload(pc),a2
 jsr resload_Control(a2)
 move.l verify_custom3(pc),d0
 cmp.l #6,d0
 bhi.s .no_fixture
 tst.l d0
 beq.s .no_fixture
 subq.w #1,d0
 mulu.w #150,d0
 add.w #50,d0
 lea verify_fixture(pc),a0
 move.w d0,(a0)
.no_fixture move.l #$5a5ac3c3,$80000
 move.l #$5a5ac3c3,$87d10
 movem.l (sp)+,d0-a6
 rts

verify_entry
 move.w sr,-(sp)
 movem.l d0-a6,-(sp)
 move.l verify_custom3(pc),d0
 beq.s .done
 cmp.l #6,d0
 bhi.s .done
 move.l motion_game(pc),a0
 adda.l #$24000,a0
 move.w verify_fixture(pc),d0
 lea verify_request(pc),a1
 tst.w (a1)
 beq.s .wait_target
 clr.w (a1)
 bra.s .activate
.wait_target cmp.w $28d0(a0),d0
 bne.s .done
.activate
 lea verify_fixture_active(pc),a1
 move.w #1,(a1)
 subq.w #1,d0
 move.w d0,$28d0(a0)
.done movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 move.w #4,$dff09c          ; original INTREQ acknowledge
 rts

verify_frame
 move.w sr,-(sp)
 movem.l a0-a1,-(sp)
 lea verify_frames(pc),a1
 move.l verify_custom3(pc),a0
 cmpa.w #0,a0
 beq.s .count
 move.w verify_fixture_active(pc),a0
 cmpa.w #0,a0
 beq.s .done
.count addq.l #1,(a1)
.done movem.l (sp)+,a0-a1
 move.w (sp)+,ccr
 movem.l a0,-(sp)
 move.l motion_game(pc),a0
 adda.l #$10000,a0
 bset #0,$2396(a0)          ; original frame-end request
 movem.l (sp)+,a0
 rts

verify_flush
 movem.l d0-a6,-(sp)
 move.l resload(pc),a2
 jsr resload_FlushCache(a2)
 movem.l (sp)+,d0-a6
 rts

verify_polygon
 move.w sr,-(sp)
 ori.w #$0700,sr           ; same inputs for CPU and reference, including clouds
 movem.l d0-a6,-(sp)
 move.l motion_game(pc),a0
 adda.l #$10000,a0
 move.l -$17f4(a0),a1
 lea verify_bitmap(pc),a2
 move.l a1,(a2)
 move.l #VERIFY_SHADOW,d0
 sub.l a1,d0
 lea verify_shift(pc),a2
 move.l d0,(a2)
 move.l #VERIFY_SHADOW,a2
 move.w #7999,d0
.copy move.l (a1)+,(a2)+
 dbf d0,.copy
 move.w span_kind(pc),d0
 move.w d0,d1
 lsl.w #3,d1
 lea verify_original(pc),a2
 adda.w d1,a2
 ; Capture the selected patch bytes before temporarily restoring them.
 move.l motion_game(pc),a0
 move.w #$bbb4,d1
 move.w #$bb42,d2
 tst.w d0
 beq.s .selected
 move.w #$bcbc,d1
 move.w #$bc50,d2
 cmp.w #1,d0
 beq.s .selected
 move.w #$be04,d1
 move.w #$bd6c,d2
.selected and.l #$ffff,d1
 and.l #$ffff,d2
 lea verify_hook(pc),a1
 move.l a0,d0
 add.l d1,d0
 move.l d0,(a1)+
 move.l a0,d0
 add.l d2,d0
 move.l d0,(a1)
 move.l motion_game(pc),a0
 adda.l #$10000,a0
 lea verify_phase(pc),a1
 move.w -$17cc(a0),(a1)+
 move.w $4836(a0),(a1)+
 move.w -$17e0(a0),(a1)+
 move.w -$17de(a0),(a1)+
 movem.l (sp),d0-a6
 bsr span_rows             ; shipping path, with shadow destination only
 lea verify_cpu_outputs(pc),a6
 movem.l d0-d7/a0-a1,(a6)
 lea verify_cpu_sr(pc),a6
 move.w sr,(a6)
 move.l motion_game(pc),a0
 adda.l #$10000,a0
 lea verify_phase+8(pc),a1
 move.w -$17cc(a0),(a1)+
 move.w $4836(a0),(a1)
 move.l verify_hook(pc),a0
 lea verify_patched(pc),a1
 move.l (a0),(a1)+
 move.l 4(a0),(a1)
 move.w span_kind(pc),d0
 lsl.w #3,d0
 lea verify_original(pc),a1
 adda.w d0,a1
 move.l (a1)+,(a0)+
 move.l (a1),(a0)
 bsr verify_flush
 ; Restore the prepared dither phase: callers can enter at bd76 with
 ; a custom pattern, so rerunning the whole function's prefix is wrong.
 move.l motion_game(pc),a0
 adda.l #$10000,a0
 move.w verify_phase(pc),-$17cc(a0)
 move.w verify_phase+2(pc),$4836(a0)
 movem.l (sp),d0-a6
 pea .reference_done(pc)
 movem.l a2-a6,-(sp)       ; native loop epilogue consumes this inner save
 move.l verify_hook(pc),-(sp)
 movem.l 28(sp),d0-a6
 rts                      ; enter the restored native loop, with all inputs
.reference_done
 lea verify_outputs(pc),a6
 movem.l d0-a5,(a6)        ; a6 is replaced below with its prepared native value
 ; The outer original epilogue will restore caller a2-a6, so prepared a6
 ; is only needed as DMACONR for its final wait.
 move.l #$dff002,56(a6)
 lea verify_end_sr(pc),a0
 move.w sr,(a0)
 ; Only d0-d7/a0-a1 survive the outer native epilogue. Compare these,
 ; plus X (the tail normalises N/Z/V/C), against the prepared-loop twin.
 lea verify_cpu_outputs(pc),a0
 lea verify_outputs(pc),a1
 moveq #9,d0
 moveq #0,d1
.registers cmpm.l (a0)+,(a1)+
 beq.s .register_equal
 addq.l #1,d1
.register_equal dbf d0,.registers
 move.w verify_cpu_sr(pc),d0
 move.w verify_end_sr(pc),d2
 eor.w d2,d0
 and.w #$10,d0
 or.w d0,d1
 beq.s .register_ok
 lea verify_register_failures(pc),a0
 addq.l #1,(a0)
.register_ok move.l verify_hook(pc),a0
 lea verify_patched(pc),a1
 move.l (a1)+,(a0)+
 move.l (a1),(a0)
 bsr verify_flush
verify_compare
 move.l verify_bitmap(pc),a0
 move.l #VERIFY_SHADOW,a1
 move.w #7999,d0
 moveq #0,d1
.compare cmpm.l (a0)+,(a1)+
 beq.s .equal
 addq.l #1,d1
 lea verify_first_difference(pc),a2
 tst.l (a2)
 bne.s .equal
 move.l a0,(a2)
 lea verify_failure_input(pc),a2
 lea (sp),a3
 moveq #14,d2
.failure_input move.l (a3)+,(a2)+
 dbf d2,.failure_input
 move.w span_kind(pc),(a2)
 lea verify_phase(pc),a2
 lea verify_failure_phase(pc),a3
 move.l (a2)+,(a3)+
 move.l (a2)+,(a3)+
 move.l (a2),(a3)
.equal dbf d0,.compare
 lea verify_polygons(pc),a0
 addq.l #1,(a0)+
 tst.l d1
 beq.s .guards
 addq.l #1,(a0)
.guards cmp.l #$5a5ac3c3,$80000
 bne.s .guard_fail
 cmp.l #$5a5ac3c3,$87d10
 beq.s .restore
.guard_fail lea verify_guard_failures(pc),a0
 addq.l #1,(a0)
.restore lea 60(sp),sp
 move.w (sp)+,d0
 and.w #$ff00,d0
 move.w verify_end_sr(pc),d1
 and.w #$00ff,d1
 or.w d1,d0
 move.w d0,sr
 lea verify_outputs(pc),a6
 movem.l (a6),d0-a6
 rts

; The clear twin runs the shipping early return into the shadow, then the
; original final wait into the real bitmap. Both finish before comparison.
verify_clear
 move.w sr,-(sp)
 ori.w #$0700,sr
 movem.l d0-a6,-(sp)
 move.l motion_game(pc),a0
 adda.l #$10000,a0
 move.l -$17f4(a0),a1
 lea verify_bitmap(pc),a2
 move.l a1,(a2)
 move.l #VERIFY_SHADOW,a2
 move.w #7999,d0
.copy move.l (a1)+,(a2)+
 dbf d0,.copy
 move.l #VERIFY_SHADOW,-$17f4(a0)
 movem.l (sp),d0-a6
 move.l motion_game(pc),a6
 adda.l #$c0ba,a6
 jsr (a6)
 bsr .wait
 move.l motion_game(pc),a0
 adda.l #$10000,a0
 move.l verify_bitmap(pc),-$17f4(a0)
 move.l motion_game(pc),a0
 adda.l #$c29a,a0
 lea verify_clear_patched(pc),a1
 move.l (a0),(a1)+
 move.l 4(a0),(a1)
 lea verify_clear_original(pc),a1
 move.l (a1)+,(a0)+
 move.l (a1),(a0)
 move.l motion_game(pc),a0
 adda.l #$c240,a0
 lea verify_planes_patched(pc),a1
 move.l (a0),(a1)+
 move.l 4(a0),(a1)
 lea verify_planes_original(pc),a1
 move.l (a1)+,(a0)+
 move.l (a1),(a0)
 bsr verify_flush
 movem.l (sp),d0-a6
 move.l motion_game(pc),a6
 adda.l #$c0ba,a6
 jsr (a6)
 lea verify_outputs(pc),a6
 movem.l d0-a5,(a6)
 lea verify_end_sr(pc),a0
 move.w sr,(a0)
 move.l 56(sp),56(a6)
 move.l motion_game(pc),a0
 adda.l #$c29a,a0
 lea verify_clear_patched(pc),a1
 move.l (a1)+,(a0)+
 move.l (a1),(a0)
 move.l motion_game(pc),a0
 adda.l #$c240,a0
 lea verify_planes_patched(pc),a1
 move.l (a1)+,(a0)+
 move.l (a1),(a0)
 bsr verify_flush
 lea span_kind(pc),a0
 move.w #3,(a0)
 bra.w verify_compare
.wait move.l #$dff002,a0
.loop btst #6,(a0)
 btst #6,(a0)
 bne.s .loop
 rts

; The line twin runs the shipping CPU line into the shadow, then the restored
; native blits into the real bitmap. The native tail (pen update, saved d2,
; rts) returns to verify_line_done, which compares and re-patches.
verify_line_original ds.b 8
verify_line_patched ds.b 8
verify_line_return dc.l 0
verify_line_sr dc.w 0
verify_line_vars ds.b 8          ; CPU game:e842.l, e832.w, e852.w
verify_lines dc.l 0

verify_line
 move.w sr,-(sp)
 ori.w #$0700,sr
 movem.l d0-a6,-(sp)
 move.l motion_game(pc),a0
 adda.l #$10000,a0
 move.l -$17f4(a0),a1
 lea verify_bitmap(pc),a2
 move.l a1,(a2)
 move.l #VERIFY_SHADOW,d0
 sub.l a1,d0
 lea verify_shift(pc),a2
 move.l d0,(a2)
 move.l #VERIFY_SHADOW,a2
 move.w #7999,d0
.copy move.l (a1)+,(a2)+
 dbf d0,.copy
 movem.l (sp),d0-a6
 bsr line_draw
 bne.s .native_only
 move.l motion_game(pc),a0
 adda.l #$10000,a0
 lea verify_line_vars(pc),a1
 move.l -$17be(a0),(a1)+
 move.w -$17ce(a0),(a1)+
 move.w -$17ae(a0),(a1)
 move.l motion_game(pc),a0
 adda.l #$b92c,a0
 lea verify_line_patched(pc),a1
 move.l (a0),(a1)+
 move.l 4(a0),(a1)
 lea verify_line_original(pc),a1
 move.l (a1)+,(a0)+
 move.l (a1),(a0)
 bsr verify_flush
 ; Stack: registers, sr, native saved d2, caller.
 lea verify_line_return(pc),a0
 move.l 66(sp),(a0)
 lea verify_line_done(pc),a0
 move.l a0,66(sp)
 lea verify_line_sr(pc),a0
 move.w 60(sp),(a0)
 movem.l (sp)+,d0-a6
 addq.l #2,sp               ; interrupts stay off through the native blits
 move.l motion_game(pc),-(sp)
 add.l #$b92c,(sp)
 rts
.native_only movem.l (sp)+,d0-a6
 move.w (sp)+,sr
 bra.w line_native

verify_line_done
 move.l verify_line_return(pc),-(sp)
 move.w sr,-(sp)
 movem.l d0-a6,-(sp)
 move.l motion_game(pc),a0
 adda.l #$b92c,a0
 lea verify_line_patched(pc),a1
 move.l (a1)+,(a0)+
 move.l (a1),(a0)
 bsr verify_flush
 moveq #0,d1
 move.l motion_game(pc),a0
 adda.l #$10000,a0
 lea verify_line_vars(pc),a1
 move.l -$17be(a0),d0
 cmp.l (a1)+,d0
 beq.s .apt
 addq.l #1,d1
.apt move.w -$17ce(a0),d0
 cmp.w (a1)+,d0
 beq.s .con1
 addq.l #1,d1
.con1 move.w -$17ae(a0),d0
 cmp.w (a1),d0
 beq.s .size
 addq.l #1,d1
.size tst.l d1
 beq.s .vars_ok
 lea verify_register_failures(pc),a0
 addq.l #1,(a0)
.vars_ok move.l verify_bitmap(pc),a0
 move.l #VERIFY_SHADOW,a1
 move.w #7999,d0
 moveq #0,d1
.compare cmpm.l (a0)+,(a1)+
 beq.s .equal
 addq.l #1,d1
 lea verify_first_difference(pc),a2
 tst.l (a2)
 bne.s .equal
 move.l a0,(a2)
.equal dbf d0,.compare
 lea verify_lines(pc),a0
 addq.l #1,(a0)
 lea verify_polygons(pc),a0
 addq.l #1,(a0)+
 tst.l d1
 beq.s .guards
 addq.l #1,(a0)
.guards cmp.l #$5a5ac3c3,$80000
 bne.s .guard_fail
 cmp.l #$5a5ac3c3,$87d10
 beq.s .restore
.guard_fail lea verify_guard_failures(pc),a0
 addq.l #1,(a0)
.restore move.w 60(sp),d0       ; native final condition codes
 and.w #$00ff,d0
 move.w verify_line_sr(pc),d1
 and.w #$ff00,d1
 or.w d1,d0
 move.w d0,60(sp)
 movem.l (sp)+,d0-a6
 move.w (sp)+,sr
 rts

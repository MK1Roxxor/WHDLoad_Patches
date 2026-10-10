; Overlap only the final clear with CPU work. Every subsequent drawing entry
; waits before its first blitter register write or bitmap access.
clear_return
 addq.l #4,sp              ; discard patch JSR, return from original clear
 ori.b #4,ccr              ; completed BTST sets Z; preserve native N/V/C/X
 rts

; Planes 0 and 1 of the view (rows 24-147) become all ones, as the native
; $01FF blits at game:0c25e/0c28c do, with 32-bit CPU stores instead of
; 16-bit blitter writes. Nothing waits: the running plane 3 copy does not
; touch these planes. Returns through the native tail at game:0c29a.
clear_planes01
 movem.l d1-d7/a0-a5,-(sp)
 move.l motion_game(pc),a0
 adda.l #$10000,a0
 move.l -$17f4(a0),a0        ; game:e80c, bitmap
 lea 960+4960(a0),a0        ; end of plane 0's view rows
 moveq #-1,d1
 move.l d1,d2
 move.l d1,d3
 move.l d1,d4
 move.l d1,d5
 move.l d1,d6
 move.l d1,d7
 move.l d1,a1
 move.l d1,a2
 move.l d1,a3
 move.l d1,a4
 move.l d1,a5
 bsr.s .plane
 lea 8000+4960(a0),a0       ; end of plane 1's view rows
 bsr.s .plane
 lea 8000(a0),a0
 move.l a0,d0               ; native d0 after the fills: plane 1 start
 movem.l (sp)+,d1-d7/a0-a5
 move.l motion_game(pc),-(sp)
 add.l #$c29a,(sp)
 rts
.plane moveq #102,d0         ; 103 x 48 + 16 = 4960 bytes
.fill movem.l d1-d7/a1-a5,-(a0)
 dbf d0,.fill
 move.l d1,-(a0)
 move.l d1,-(a0)
 move.l d1,-(a0)
 move.l d1,-(a0)
 rts

clear_solid_barrier
 bsr clear_hardware_wait
 move.w #$05ac,$40(a0)    ; original first blitter register write
 rts

clear_texture_barrier
 bsr clear_hardware_wait
 move.w #$07ac,$40(a0)
 rts

clear_hardware_wait
 movem.l a1,-(sp)
 lea $dff002,a1
.wait btst #6,(a1)
 btst #6,(a1)
 bne.s .wait
 movem.l (sp)+,a1
 rts

clear_line_barrier
 movem.l a0,-(sp)
 lea $dff002,a0
.wait btst #6,(a0)
 btst #6,(a0)
 bne.s .wait
 movem.l (sp)+,a0
 ; Insert the original saved d2 below this hook's return address.
 move.l (sp),-(sp)
 move.l d2,4(sp)
 movem.l a0,-(sp)
 move.l motion_game(pc),a0
 adda.l #$10000,a0
 move.w d0,-$17e4(a0)      ; original game:e81c store
 movem.l (sp)+,a0
 rts

clear_frame_barrier
 movem.l a0,-(sp)
 lea $dff002,a0
.wait btst #6,(a0)
 btst #6,(a0)
 bne.s .wait
 IFD TIMING
 bsr timing_end
 ENDC
 move.l motion_game(pc),a0
 adda.l #$24000,a0
 btst #0,$28d8(a0)        ; original display-mode test before swap request/HUD
 movem.l (sp)+,a0
 rts

 IFD TIMING
; Diagnostic elapsed time, from the same CIA clock used for interpolation.
; This code is absent from the shipping and pixel-twin builds.
timing_magic dc.b 'I5TM'
timing_count dc.l 0
timing_samples ds.l 64
timing_directors ds.w 64
timing_clock dc.l 0
timing_phase dc.w 0

timing_end
 move.w sr,-(sp)
 movem.l d0-d3/a0-a1,-(sp)
 move.l timing_count(pc),d3
 cmp.l #64,d3
 bcc.s .done
 tst.l d3
 bne.s .record
 move.l motion_game(pc),a0
 adda.l #$24000,a0
 cmp.w #200,$28d0(a0)
 bne.s .done
.record bsr motion_now
 sub.l timing_clock(pc),d0
 mulu.w #11883,d0
 moveq #0,d2
 move.w timing_phase(pc),d2
 sub.l d1,d2
 add.l d2,d0
 lsl.w #2,d3
 lea timing_samples(pc),a0
 move.l d0,(a0,d3.w)
 lsr.w #1,d3
 move.l motion_game(pc),a0
 adda.l #$24000,a0
 move.w $28d0(a0),d1
 lea timing_directors(pc),a0
 move.w d1,(a0,d3.w)
 lea timing_count(pc),a0
 addq.l #1,(a0)
.done movem.l (sp)+,d0-d3/a0-a1
 move.w (sp)+,ccr
 rts
 ENDC

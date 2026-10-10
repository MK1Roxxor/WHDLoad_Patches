; Diagnostic only: CIA time stamps through each SOFT, read by a host debugger tool.
; Slots: 0 entry (game:007ee), 1 player forces (game:00bf8, driving only), 2 camera
; publication (game:03138), 3/4 around the field update call (game:03144 demo,
; game:035c8 driving), 5 common exit (game:03af0). Needs the motion CIA clock.
; This file is absent from normal builds.
ST_SAMPLES = 256
ST_SIZE = 44                 ; 6 x (clock.l, timer.w), mode, style, 9b2e, pad, event.w, pad
soft_timing_magic dc.b 'I5ST'
 dc.w soft_timing_done-soft_timing_magic
soft_timing_count dc.l 0     ; completed SOFTs; sample n is at n mod ST_SAMPLES
soft_timing_ptr dc.l 0
soft_timing_active dc.w 0
soft_timing_samples ds.b ST_SAMPLES*ST_SIZE

PL_SOFT_TIMING PL_START
	PL_PSS $7ee,soft_timing_entry,2
	PL_PS $bf8,soft_timing_forces
	PL_PSS $3138,soft_timing_publish,2
	PL_PS $3144,soft_timing_field
	PL_PS $35c8,soft_timing_field
 PL_END

; d3 = slot*6. Clobbers d0-d2/a0.
soft_timing_stamp
 move.w soft_timing_active(pc),d0
 beq.s .done
 bsr motion_now
 move.l soft_timing_ptr(pc),a0
 add.w d3,a0
 move.l d0,(a0)+
 move.w d1,(a0)
.done rts

soft_timing_entry
 move.w #4,$dff09c          ; displaced SOFT acknowledge
 movem.l d0-d3/a0-a1,-(sp)
 move.l soft_timing_count(pc),d0
 and.l #ST_SAMPLES-1,d0
 mulu.w #ST_SIZE,d0
 lea soft_timing_samples(pc),a0
 add.l d0,a0
 lea soft_timing_ptr(pc),a1
 move.l a0,(a1)
 moveq #ST_SIZE/2-1,d0
.clear move.w #-1,(a0)+     ; a missing stamp reads as clock $ffffffff
 dbf d0,.clear
 lea soft_timing_active(pc),a1
 move.w #1,(a1)
 moveq #0,d3
 bsr soft_timing_stamp
 movem.l (sp)+,d0-d3/a0-a1
 rts

soft_timing_forces
 movem.l d0-d3/a0,-(sp)
 moveq #1*6,d3
 bsr soft_timing_stamp
 movem.l (sp)+,d0-d3/a0
 move.l a0,-(sp)
 move.l motion_game(pc),a0
 adda.l #$10000,a0
 move.w -$6780(a0),d0       ; displaced move.w game:9880,d0
 move.l (sp)+,a0
 rts

soft_timing_publish
 movem.l d0-d3/a0,-(sp)
 moveq #2*6,d3
 bsr soft_timing_stamp
 movem.l (sp)+,d0-d3/a0
 move.l a0,-(sp)
 move.l motion_game(pc),a0
 adda.l #$24000,a0
 cmp.b #1,$28da(a0)         ; displaced cmpi.b #1,game:268da; flags for the bne
 movea.l (sp)+,a0
 rts

; Replaces jsr game:20d26; the field update gets and returns the caller's registers.
soft_timing_field
 movem.l d0-d3/a0,-(sp)
 moveq #3*6,d3
 bsr soft_timing_stamp
 movem.l (sp)+,d0-d3/a0
 pea .back(pc)
 move.l motion_game(pc),-(sp)
 add.l #$20d26,(sp)
 rts
.back movem.l d0-d3/a0,-(sp)
 moveq #4*6,d3
 bsr soft_timing_stamp
 movem.l (sp)+,d0-d3/a0
 rts

; Called first by motion_record (game:03af0); registers are free there.
soft_timing_exit
 move.w soft_timing_active(pc),d0
 beq.s soft_timing_done
 moveq #5*6,d3
 bsr soft_timing_stamp
 move.l soft_timing_ptr(pc),a0
 move.l motion_game(pc),a1
 move.w $7d4(a1),40(a0)     ; race event
 adda.l #$10000,a1
 move.b -$64d2(a1),38(a0)   ; game:9b2e
 adda.l #$14000,a1
 move.b $28da(a1),36(a0)    ; mode
 move.b $28d7(a1),37(a0)    ; view style
 lea soft_timing_active(pc),a1
 clr.w (a1)
 lea soft_timing_count(pc),a1
 addq.l #1,(a1)
soft_timing_done
 rts                        ; the host tool waits here

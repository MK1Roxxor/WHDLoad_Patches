; Display motion between simulation ticks only. All game addresses are hunk-0 offsets.
; SOFT owns the published state. The frame hook edits its private copies only.
; Driving (cockpit snapshots): the camera and the player's car extrapolate from the
; latest tick, so the display does not lag the controls, and opponents move by their
; own per-tick rates. Demo and replays (external snapshots) interpolate.
MOTION_SIZE = 226
MOTION_CARS = 28
motion_magic dc.b 'I5MO'
motion_game dc.l 0
motion_clock dc.l 0
motion_stamp dc.l 0
motion_timer dc.w 0
motion_valid dc.w 0
motion_alpha dc.w 0
motion_track dc.w 0
motion_prev ds.b MOTION_SIZE
motion_cur ds.b MOTION_SIZE
motion_next ds.b 33*6      ; cockpit: each car's pose at the next tick, from its rates
motion_follow ds.b 33      ; cockpit: 1 if the car reached the pose predicted a tick ago
motion_predict dc.b 0      ; 1: cur is a cockpit snapshot with predictions (extrapolate)

; Replaces the main loop's wait for a simulation tick (game:00152 move.w game:9832,d0;
; beq.s game:00152), so frames are drawn between ticks. The replay transition wipe
; (view style 2) advances one step per pass (game:00176..001d4) and draws nothing that
; waits for the display, so it keeps the original pace of one step per CIA tick.
motion_wait
 move.l a0,-(sp)
 move.l motion_game(pc),a0
 adda.l #$24000,a0
 cmp.b #2,$28d7(a0)
 suba.l #$24000-$9832,a0     ; game:9832; flags still from the style test
 bne.s .go
.wait tst.w (a0)
 beq.s .wait
.go move.w (a0),d0
 move.l (sp)+,a0
 rts

motion_cia
 move.l a0,-(sp)
 lea motion_clock(pc),a0
 addq.l #1,(a0)
 move.l motion_game(pc),a0
 adda.l #$10000,a0
 addq.w #1,$2388(a0)       ; original instruction, including CCR
 move.l (sp)+,a0
 rts

; d0 = monotonic CIA interrupt count, d1 = down-counter phase.
; CIA interrupts remain enabled; retry if a tick or high-byte rollover intervenes.
motion_now
 move.l motion_clock(pc),d0
 moveq #0,d1
 move.b $bfe701,d1
 lsl.w #8,d1
 move.b $bfe601,d1
 move.w d1,d2
 lsr.w #8,d2
 cmp.b $bfe701,d2
 bne.s motion_now
 cmp.l motion_clock(pc),d0
 bne.s motion_now
 rts

motion_record
 ; Original SOFT prologue saved d0-a6. This replaces its common epilogue.
 IFD SOFT_TIMING
 bsr soft_timing_exit
 ENDC
 move.l motion_game(pc),a6
 adda.l #$24000,a6
 lea motion_cur(pc),a0
 lea motion_prev(pc),a1
 moveq #MOTION_SIZE/2-1,d0
.copy move.w (a0)+,(a1)+
 dbf d0,.copy
 ; Cockpit frames publish their camera at game:9834; external/demo frames
 ; publish at game:26664. Match the native branch at game:160..172.
 moveq #0,d3
 lea $2664(a6),a0
 btst #0,$28da(a6)
 bne.s .source_ready
 move.l motion_game(pc),a2
 adda.l #$10000,a2
 btst #1,-$64d2(a2)
 bne.s .source_ready
 lea -$67cc(a2),a0
 moveq #1,d3
.source_ready
 lea motion_cur(pc),a1
 moveq #8,d0
.view move.w (a0)+,(a1)+
 dbf d0,.view
 move.w $28d2(a6),d1
 tst.b d3
 beq.s .track_ready
 move.w -$18a2(a6),d1    ; cockpit distances are relative to player car +6
.track_ready move.w d1,(a1)+
 move.b $2789(a6),(a1)+
 move.b $28da(a6),(a1)+
 move.l $2698(a6),(a1)+
 move.b $28d7(a6),(a1)+
 move.b d3,(a1)+         ; 0 external camera, 1 cockpit
 lea -$18a8+6(a6),a0
 moveq #32,d0
.cars move.l (a0),(a1)+
 move.w 4(a0),(a1)+
 lea 86(a0),a0
 dbf d0,.cars
 tst.b d3
 bne.s .predict
 bsr motion_record_nodes
.predict lea motion_predict(pc),a0
 move.b d3,(a0)
 beq.s .stamp
 bsr motion_predict_cars
.stamp bsr motion_now
 lea motion_stamp(pc),a0
 move.l d0,(a0)+
 move.w d1,(a0)
 lea motion_valid(pc),a0
 cmp.w #2,(a0)
 bcc.s .done
 addq.w #1,(a0)
.done movem.l (sp)+,d0-a6
 rte

; External views draw the cars from a ring of 22-byte nodes (game:280d4 walks it
; from the viewer node game:26698 through +0): +12 car record, +16/+18/+20 pose.
; Replays move only the nodes, and in the demo the nodes trail the records by a
; tick, so take each car's pose from its node. a6 = game+$24000. Clobbers d0-d2/a0-a2.
motion_record_nodes
 move.l $2698(a6),d0
 beq.s .done
 movea.l d0,a0
 movea.l a0,a2
 moveq #32,d2               ; a ring holds at most the 33 cars
.node move.l 12(a2),d0
 sub.l a6,d0
 add.l #$18a8,d0            ; offset from car record 0 (game:22758)
 cmp.l #33*86,d0
 bcc.s .next
 divu.w #86,d0
 move.l d0,d1
 swap d1
 tst.w d1                   ; require an exact car-record pointer
 bne.s .next
 mulu.w #6,d0
 lea motion_cur+MOTION_CARS(pc),a1
 adda.w d0,a1
 move.w 16(a2),(a1)+
 move.l 18(a2),(a1)
.next move.l (a2),d0
 beq.s .done
 movea.l d0,a2
 cmpa.l a0,a2
 dbeq d2,.node
.done rts

; Cockpit only. The field loop (game:020d38..020d7a) moves each car by the rates in its
; record, and the controllers change them only after that, so at a SOFT exit an
; opponent's next pose is known. Mark the cars that reached last tick's prediction;
; the others (contacts, cars the field loop does not move) are extrapolated.
; a6 = game+$24000. Clobbers d0-d2/a0-a3.
motion_predict_cars
 lea -$18a8+86(a6),a0      ; record 1; the player's record 0 is extrapolated
 lea motion_cur+MOTION_CARS+6(pc),a1
 lea motion_next+6(pc),a2
 lea motion_follow+1(pc),a3
 moveq #31,d0
.car moveq #0,d2
 move.l (a1)+,d1
 cmp.l (a2),d1
 bne.s .missed
 move.w (a1),d1
 cmp.w 4(a2),d1
 bne.s .missed
 moveq #1,d2
.missed move.b d2,(a3)+
 addq.l #2,a1
 ; Track: 24-bit +6/+7 with fraction +5, minus the 8.8 speed +12; +39600 on a borrow.
 moveq #0,d1
 move.w 6(a0),d1
 lsl.l #8,d1
 move.b 5(a0),d1
 moveq #0,d2
 move.w 12(a0),d2
 sub.l d2,d1
 bcc.s .track
 add.l #39600*256,d1
.track lsr.l #8,d1
 move.w d1,(a2)+
 move.w 8(a0),d1           ; lateral + rate + acceleration
 add.w 14(a0),d1
 add.w 84(a0),d1
 move.w d1,(a2)+
 move.w 10(a0),d1          ; heading + rate
 add.w 16(a0),d1
 move.w d1,(a2)+
 lea 86(a0),a0
 dbf d0,.car
 rts

; Signed word difference (shortest 16-bit angular arc), Q14 interpolation.
; d0 = previous, d1 = current, d7 = alpha. Result d0; clobbers d1.
motion_lerp
 sub.w d0,d1
 muls.w d7,d1
 asr.l #7,d1
 asr.l #7,d1
 add.w d1,d0
 rts

; Track coordinates are unsigned 0..39599. Difference must be 32-bit.
; d0 previous, d1 current. Result wraps around 39600. Clobbers d1,d2.
motion_lap
 and.l #$ffff,d0
 and.l #$ffff,d1
 sub.l d0,d1
 cmp.l #19800,d1
 blt.s .lower
 sub.l #39600,d1
.lower cmp.l #-19800,d1
 bge.s .delta
 add.l #39600,d1
.delta move.l d1,d2
 ; A teleport is displayed immediately rather than swept round the track.
 bpl.s .positive
 neg.l d2
.positive cmp.l #1000,d2
 ble.s .blend
 add.l d1,d0
 bra.s .wrap
.blend muls.w d7,d1
 asr.l #7,d1
 asr.l #7,d1
 add.l d1,d0
.wrap tst.l d0
 bpl.s .upper
 add.l #39600,d0
.upper cmp.l #39600,d0
 blt.s .done
 sub.l #39600,d0
.done rts

motion_rewrite
 bsr motion_frame
 movem.l a0,-(sp)
 move.l motion_game(pc),a0
 adda.l #$24000,a0
 btst #3,$2786(a0)        ; displaced BTST game:26786 (not game:26392)
 move.l (sp)+,a0
 rts

motion_cockpit
 bsr motion_frame
 movem.l a0,-(sp)
 move.l motion_game(pc),a0
 clr.b $7d7(a0)           ; displaced CLR at game:270, including CCR
 move.l (sp)+,a0
 rts

motion_frame
 move.w sr,-(sp)
 movem.l d0-a6,-(sp)
 IFD TIMING
 bsr motion_now
 lea timing_clock(pc),a0
 move.l d0,(a0)+
 move.w d1,(a0)
 ENDC
 move.l motion_game(pc),a6
 adda.l #$24000,a6
 move.w motion_valid(pc),d0
 cmp.w #2,d0
 bcs.w .done
 cmp.b #2,$28d7(a6)       ; transition wipe: the CIA handler (game:9bf4) skips
                          ; SOFT and the motion clock
 beq.w .done
 lea motion_prev(pc),a4
 lea motion_cur(pc),a5
 ; Do not apply an old external snapshot to a freshly selected cockpit.
 moveq #0,d0
 btst #0,$28da(a6)
 bne.s .check_source
 move.l motion_game(pc),a0
 adda.l #$10000,a0
 btst #1,-$64d2(a0)
 bne.s .check_source
 moveq #1,d0
.check_source cmp.b 27(a5),d0
 bne.w .done
 move.w #16384,d7
 cmp.b 27(a4),d0
 bne.s .phase_ready
 ; Snap at director/style/viewer/mode cuts. Follow-camera coordinates move.
 move.l 20(a4),d0
 cmp.l 20(a5),d0
 bne.s .phase_ready
 move.w 24(a4),d0
 cmp.w 24(a5),d0
 bne.s .phase_ready
 bsr motion_now
 sub.l motion_stamp(pc),d0
 cmp.l #4,d0
 bhi.s .phase_ready        ; SOFT stopped (pause, menus): show the latest tick
 mulu.w #11883,d0
 moveq #0,d2
 move.w motion_timer(pc),d2
 sub.l d1,d2
 add.l d2,d0
 bmi.s .phase_zero
 cmp.l #47532,d0
 bcc.s .phase_late
 lsl.l #7,d0
 lsl.l #7,d0
 divu.w #47532,d0
 move.w d0,d7
 bra.s .phase_mode
.phase_zero moveq #0,d7
 ; Cockpit: extrapolate from the current tick instead of interpolating from
 ; the previous one. Alpha 1..2 in Q14 (at most 32767 for MULS) removes the
 ; one-tick presentation delay; cuts still show the current tick. Opponents
 ; moving by their rates use alpha - 1 from their current to their next pose.
.phase_mode move.b motion_predict(pc),d2
 beq.s .phase_ready
 add.w #16384,d7
 bra.s .phase_ready
.phase_late move.b motion_predict(pc),d2
 beq.s .phase_ready
 move.w #32767,d7
.phase_ready
 ; Camera track coordinate is word 6, not zoom. Snap only at a teleport.
 moveq #0,d0
 moveq #0,d1
 move.w 12(a5),d0
 move.w 12(a4),d1
 sub.l d1,d0
 cmp.l #19800,d0
 blt.s .track_lower
 sub.l #39600,d0
.track_lower cmp.l #-19800,d0
 bge.s .track_delta
 add.l #39600,d0
.track_delta tst.l d0
 bpl.s .track_positive
 neg.l d0
.track_positive cmp.l #1000,d0
 bhi.s .snap
 ; A large XYZ jump is a cut; ordinary following motion is interpolated.
 moveq #2,d6
 movea.l a4,a0
 movea.l a5,a1
.check_xyz move.w (a1)+,d1
 sub.w (a0)+,d1
 bpl.s .xyz_positive
 neg.w d1
.xyz_positive cmp.w #1000,d1
 bhi.s .snap
 dbf d6,.check_xyz
 bra.s .camera
.snap move.w #16384,d7
.camera lea motion_alpha(pc),a0
 move.w d7,(a0)
 move.l motion_game(pc),a2
 lea $7a8(a2),a2
 movea.l a4,a0
 movea.l a5,a1
 moveq #5,d6
.camera_word move.w (a0)+,d0
 move.w (a1)+,d1
 bsr motion_lerp
 move.w d0,(a2)+
 dbf d6,.camera_word
 moveq #0,d0
 moveq #0,d1
 move.w (a0)+,d0
 move.w (a1)+,d1
 bsr motion_lap
 move.w d0,(a2)+
 ; Camera lateral coordinate and track tangent use ordinary/angle lerp.
 moveq #1,d6
.camera_track_word move.w (a0)+,d0
 move.w (a1)+,d1
 bsr motion_lerp
 move.w d0,(a2)+
 dbf d6,.camera_track_word
 moveq #0,d0
 moveq #0,d1
 move.w 18(a4),d0
 move.w 18(a5),d1
 bsr motion_lap
 lea motion_track(pc),a0
 move.w d0,(a0)
 lea -$d92(a6),a3
 move.w (a3)+,d6           ; DBF count, not a number of records
 bmi.w .done
 cmp.w #32,d6
 bhi.w .done
 move.w d7,d5              ; alpha for every car; d7 is per car below
.car move.l 2(a3),d0
 move.l a6,d1
 sub.l #$18a8,d1
 sub.l d1,d0
 cmp.l #33*86,d0
 bcc.w .next
 divu.w #86,d0
 move.l d0,d1
 swap d1
 tst.w d1                  ; require an exact car-record pointer
 bne.w .next
 moveq #0,d2
 move.w d0,d2              ; record index
 mulu.w #6,d0
 lea MOTION_CARS(a4),a0
 lea MOTION_CARS(a5),a1
 adda.l d0,a0
 adda.l d0,a1
 moveq #0,d3
 move.w 18(a5),d3
 moveq #0,d4
 move.w (a1),d4
 sub.l d4,d3
 cmp.l #19800,d3
 blt.s .bias_lower
 sub.l #39600,d3
.bias_lower cmp.l #-19800,d3
 bge.s .bias_done
 add.l #39600,d3
.bias_done move.w (a3),d4
 sub.w d3,d4               ; preserve each native distance bias
 move.w d5,d7
 move.b motion_predict(pc),d0
 beq.s .pose
 tst.w d2
 beq.s .pose               ; the player's record moves with the camera
 lea motion_follow(pc),a2
 tst.b 0(a2,d2.w)
 beq.s .pose
 movea.l a1,a0             ; current pose to the pose its rates give next tick
 lea motion_next(pc),a1
 mulu.w #6,d2
 adda.l d2,a1
 sub.w #16384,d7
.pose moveq #0,d0
 moveq #0,d1
 move.w (a0)+,d0
 move.w (a1)+,d1
 bsr motion_lap
 move.w d0,6(a3)
 moveq #0,d1
 move.w motion_track(pc),d1
 sub.l d0,d1
 cmp.l #19800,d1
 blt.s .distance_lower
 sub.l #39600,d1
.distance_lower cmp.l #-19800,d1
 bge.s .distance_done
 add.l #39600,d1
.distance_done add.w d4,d1
 move.w d1,(a3)
 move.w (a0)+,d0
 move.w (a1)+,d1
 bsr motion_lerp
 move.w d0,8(a3)
 move.w (a0),d0
 move.w (a1),d1
 bsr motion_lerp
 move.w d0,10(a3)
.next lea 12(a3),a3
 dbf d6,.car
.done movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 rts

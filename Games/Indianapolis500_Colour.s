; Binary palettes select an unrolled four-plane fill once per polygon.
; Arbitrary colour words retain the general CPU path.
span_select_colour
 lea span_binary(pc),a1
 move.w #1,(a1)
 moveq #0,d0
 moveq #3,d1
 movea.l a2,a0
.plane move.w (a0)+,d3
 beq.s .next
 cmp.w #$ffff,d3
 bne.s .generic
 bset d1,d0
.next dbf d1,.plane
 add.w d0,d0
 lea span_colour_table(pc),a1
 move.w (a1,d0.w),d0
 adda.w d0,a1
 bra.s .store
.generic lea span_binary(pc),a1
 clr.w (a1)
 lea span_colour_generic(pc),a1
.store lea span_colour_function(pc),a0
 move.l a1,(a0)
 rts

span_colour_constant
 tst.w d7
 bne.s .no_post
 move.w d6,d0
 add.w d0,d0
 subq.w #2,d0
 movea.l a0,a1
 adda.w #24000,a1
 move.w (a1,d0.w),d3
 lea span_bdat(pc),a1
 move.w d3,(a1)
 move.w 6(a2),2(a1)
.no_post move.w d4,d3
 not.w d3
 moveq #0,d0
 moveq #-1,d1
 move.l span_colour_function(pc),a1
 jmp (a1)

span_colour_generic
 lea span_count(pc),a1
 move.w d6,(a1)
 lea span_fwm(pc),a1
 move.w d4,(a1)
 bsr span_colour_plane
 bsr span_colour_plane
 bsr span_colour_plane
 bsr span_colour_plane
 suba.w #31960,a0
 subq.w #8,a2
 movea.w span_count(pc),a1
 rts

span_colour_table
 dc.w span_fill_0-span_colour_table,span_fill_1-span_colour_table,span_fill_2-span_colour_table,span_fill_3-span_colour_table,span_fill_4-span_colour_table,span_fill_5-span_colour_table,span_fill_6-span_colour_table,span_fill_7-span_colour_table,span_fill_8-span_colour_table,span_fill_9-span_colour_table,span_fill_10-span_colour_table,span_fill_11-span_colour_table,span_fill_12-span_colour_table,span_fill_13-span_colour_table,span_fill_14-span_colour_table,span_fill_15-span_colour_table

; One instruction template expands all 16 exact binary palettes.
colour_case MACRO
\1
 movea.w d6,a1
 cmp.w #1,d6
 beq.s .single
 IFNE (\2)&8
 or.w d4,(a0)
 ELSE
 and.w d3,(a0)
 ENDC
 IFNE (\2)&4
 or.w d4,8000(a0)
 ELSE
 and.w d3,8000(a0)
 ENDC
 IFNE (\2)&2
 or.w d4,16000(a0)
 ELSE
 and.w d3,16000(a0)
 ENDC
 IFNE (\2)&1
 or.w d4,24000(a0)
 ELSE
 and.w d3,24000(a0)
 ENDC
 addq.w #2,a0
 subq.w #2,d6
 beq.s .last
 btst #0,d6
 beq.s .longs
 IFNE (\2)&8
 move.w d1,(a0)
 ELSE
 move.w d0,(a0)
 ENDC
 IFNE (\2)&4
 move.w d1,8000(a0)
 ELSE
 move.w d0,8000(a0)
 ENDC
 IFNE (\2)&2
 move.w d1,16000(a0)
 ELSE
 move.w d0,16000(a0)
 ENDC
 IFNE (\2)&1
 move.w d1,24000(a0)
 ELSE
 move.w d0,24000(a0)
 ENDC
 addq.w #2,a0
 subq.w #1,d6
 beq.s .last
.longs lsr.w #1,d6
 subq.w #1,d6
.interior
 IFNE (\2)&8
 move.l d1,(a0)
 ELSE
 move.l d0,(a0)
 ENDC
 IFNE (\2)&4
 move.l d1,8000(a0)
 ELSE
 move.l d0,8000(a0)
 ENDC
 IFNE (\2)&2
 move.l d1,16000(a0)
 ELSE
 move.l d0,16000(a0)
 ENDC
 IFNE (\2)&1
 move.l d1,24000(a0)
 ELSE
 move.l d0,24000(a0)
 ENDC
 addq.w #4,a0
 dbf d6,.interior
.last move.w d5,d3
 not.w d3
 IFNE (\2)&8
 or.w d5,(a0)
 ELSE
 and.w d3,(a0)
 ENDC
 IFNE (\2)&4
 or.w d5,8000(a0)
 ELSE
 and.w d3,8000(a0)
 ENDC
 IFNE (\2)&2
 or.w d5,16000(a0)
 ELSE
 and.w d3,16000(a0)
 ENDC
 IFNE (\2)&1
 or.w d5,24000(a0)
 ELSE
 and.w d3,24000(a0)
 ENDC
 move.w a1,d6
 subq.w #1,d6
 add.w d6,d6
 suba.w d6,a0
 adda.w #40,a0
 rts
.single and.w d5,d4
 move.w d4,d3
 not.w d3
 IFNE (\2)&8
 or.w d4,(a0)
 ELSE
 and.w d3,(a0)
 ENDC
 IFNE (\2)&4
 or.w d4,8000(a0)
 ELSE
 and.w d3,8000(a0)
 ENDC
 IFNE (\2)&2
 or.w d4,16000(a0)
 ELSE
 and.w d3,16000(a0)
 ENDC
 IFNE (\2)&1
 or.w d4,24000(a0)
 ELSE
 and.w d3,24000(a0)
 ENDC
 adda.w #40,a0
 rts

 ENDM

 colour_case span_fill_0,0
 colour_case span_fill_1,1
 colour_case span_fill_2,2
 colour_case span_fill_3,3
 colour_case span_fill_4,4
 colour_case span_fill_5,5
 colour_case span_fill_6,6
 colour_case span_fill_7,7
 colour_case span_fill_8,8
 colour_case span_fill_9,9
 colour_case span_fill_10,10
 colour_case span_fill_11,11
 colour_case span_fill_12,12
 colour_case span_fill_13,13
 colour_case span_fill_14,14
 colour_case span_fill_15,15

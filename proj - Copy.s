.include "nios_macros.s"
.equ DISP, 0x08000000
.equ AUDIO, 0x10003040
.equ TIMER, 0x10002000
.equ HEX, 0x10000020
.equ KB, 0x10000100
.equ PUSHBT, 0x10000050
.equ BACKGROUND, 0x0
.equ REFRESH, 1
.equ NUM_SAMPLE_READ_PER_INTRPT, 90
.equ VU_WINDOW_SIZE, 1024
.equ VU_COLOR, 0b100111110110101
.equ VU_SCALE,6710887
.equ COL_TOP_L, 36
.equ COL_BOT_L, 88
.equ COL_TOP_R, 151
.equ COL_BOT_R, 203
.equ SCOPE_SAMPLE_INTERVAL, 1
.equ SCOPE_AXIS_LEFT, 62
.equ SCOPE_AXIS_RIGHT, 177
.equ SCOPE_HOR_SCALE, 41297762
.equ SCOPE_COLOR, 0b100111110110101
.equ SCOPE_AXIS_COLOR, 0b1010100000100000

.section .exceptions, "ax"
.align 2

ihandler:
	# save ea, et, clt1, and any other used registers!!
	subi	sp, sp, 72
	stw		ea, 0(sp)
	stw		et, 4(sp)
	rdctl	et, ctl1
	stw		et, 8(sp)
	stw		r2, 12(sp)
	stw		r3, 16(sp)
	stw		r4, 20(sp)
	stw		r5, 24(sp)
	stw		r6, 28(sp)
	stw		r7, 32(sp)
	stw		r8, 36(sp)
	stw		r9, 40(sp)
	stw		r10, 44(sp)
	stw		r11, 48(sp)
	stw		r12, 52(sp)
	stw		r13, 56(sp)
	stw		r14, 60(sp)
	stw		r15, 64(sp)
	stw		ra, 68(sp)
	
	rdctl	r8, ctl4
	
	andi	r9, r8, 1
	bne		r9, r0, ihandler_timer
	srli	r9, r8, 6
	andi	r9, r9, 1
	bne		r9, r0, ihandler_audio
	srli	r9, r8, 7
	andi	r9, r9, 1
	bne		r9, r0, ihandler_kb
	srli	r9, r8, 1
	andi	r9, r9, 1
	bne		r9, r0, ihandler_pushbt
	br		epilog
	
	
ihandler_audio:
	movi	r7, NUM_SAMPLE_READ_PER_INTRPT
read_codec:
	beq		r7, r0, stop_reading
	
	movia	r10, AUDIO
# read and send data
	ldwio	r8, 8(r10)	# left data
	ldwio	r9, 12(r10)	# right data
	stwio	r8, 8(r10)	# left data
	stwio	r9, 12(r10)	# right data
	subi	r7, r7, 1
	
# update peak left
	mov		r11, r8
	bge		r11, r0, dont_negate_L
	nor		r11, r11, r0		
	addi	r11, r11, 1
dont_negate_L:
	# r11 = abs(r8)
	ldw		r10, peak_calculating_L(r0)
	ble		r11, r10, dont_update_L
	stw		r11, peak_calculating_L(r0)
dont_update_L:
# update peak right
	mov		r11, r9
	bge		r11, r0, dont_negate_R
	nor		r11, r11, r0		
	addi	r11, r11, 1
dont_negate_R:
	# r11 = abs(r9)
	ldw		r10, peak_calculating_R(r0)
	ble		r11, r10, dont_update_R
	stw		r11, peak_calculating_R(r0)
dont_update_R:
	
	# increment_counter:
	ldw		r10, sample_counter_for_VU(r0)	
	addi	r10, r10, 1
	movia	r11, VU_WINDOW_SIZE
	bge		r10, r11, new_window
	stw		r10, sample_counter_for_VU(r0)
	br		update_peak_end
new_window:
	stw		r0, sample_counter_for_VU(r0)
	ldw		r10, peak_calculating_L(r0)
	movia	r11, VU_SCALE
	div		r10, r10, r11
	stw		r10, peak_prev_L(r0)
	ldw		r10, peak_calculating_R(r0)
	movia	r11, VU_SCALE
	div		r10, r10, r11
	stw		r10, peak_prev_R(r0)
	stw		r0, peak_calculating_L(r0)
	stw		r0, peak_calculating_R(r0)
	#
	#
update_peak_end:
	
# increment sample counter
	ldw		r11, sample_counter(r0)
	addi	r11, r11, 1
	movi	r10, SCOPE_SAMPLE_INTERVAL	# show one sample in every SCOPE_SAMPLE_INTERVAL samples
	bge		r11, r10, store_displacement	# store 
	stw		r11, sample_counter(r0)			# don't store. just read another sample
	br		read_codec		
store_displacement:
	stw		r0, sample_counter(r0)		# reset counter
	ldw		r15, offset_counter(r0)
	movia	r10, SCOPE_HOR_SCALE
	div		r8, r8, r10
	movi	r10, SCOPE_AXIS_LEFT
	sub		r8, r10, r8
	addi	r10, r15, displacement_left
	stw		r8, 0(r10)
	movia	r10, SCOPE_HOR_SCALE
	div		r9, r9, r10
	movi	r10, SCOPE_AXIS_RIGHT
	sub		r9, r10, r9
	addi	r10, r15, displacement_right
	stw		r9, 0(r10)
	addi	r15, r15, 4
	movi	r8, 1280
	blt		r15, r8, dont_reset_offset
# reset offset counter
	mov		r15, r0
dont_reset_offset:
	stw		r15, offset_counter(r0)
	
	
	br		read_codec
stop_reading:
	br		epilog

	

ihandler_timer:

	# check mode
	ldw		r8, mode(r0)
	beq		r8, r0, oscilloscope_start

	
VU_start:
	# backup
	ldw		r8, peak_prev_L(r0)
	stw		r8, peak_prev_L_backup(r0)
	ldw		r8, peak_prev_R(r0)
	stw		r8, peak_prev_R_backup(r0)
	# ack
	movia	r8, TIMER
	stwio	r0, 0(r8)
	movi	r8, 1
	wrctl	ctl0, r8
	
	mov		r9, r0	# y
draw_loop:
	mov		r8, r0  # x
	movi	r10, 240
	bge		r9, r10, draw_loop_exit
draw_row_loop:
	movi	r10, 320
	bge		r8, r10, draw_row_loop_exit
	# determine if this pixel should be colored or not here
	# and draw the pixel
	# r8 = x, r9 = y
	
	######
/*********************
#The C code here is TOO slow!

	subi	sp, sp, 8
	stw		r8, 0(sp)
	stw		r9, 4(sp)
	
	mov		r4, r8
	mov		r5, r9
	ldw		r6, peak_prev_L_backup(r0)
	ldw		r7, peak_prev_R_backup(r0)
	call	is_VU_background_n
	
	ldw		r8, 0(sp)
	ldw		r9, 4(sp)
	addi	sp, sp, 8
	
	# r2 now = color
	slli	r10, r8, 1
	slli	r11, r9, 10
	add		r10, r10, r11
	movia	r11, DISP
	add		r10, r10, r11
	sthio	r2, 0(r10)
	######
********************/

	cmpgei	r10, r9, COL_TOP_L
	cmplei	r11, r9, COL_BOT_L
	and		r10, r10, r11
	ldw		r11, peak_prev_L_backup(r0)
	cmplt	r11, r8, r11
	and		r13, r10, r11
	cmpgei	r10, r9, COL_TOP_R
	cmplei	r11, r9, COL_BOT_R
	and		r10, r10, r11
	ldw		r11, peak_prev_R_backup(r0)
	cmplt	r11, r8, r11
	and		r10, r10, r11
	or		r10, r13, r10
	movia	r11, BACKGROUND
	beq		r10, r0, is_back
	movia	r11, VU_COLOR
is_back:
	slli	r10, r8, 1
	slli	r12, r9, 10
	add		r10, r10, r12
	movia	r12, DISP
	add		r10, r10, r12
	sthio	r11, 0(r10)

	
	addi	r8, r8, 1
	br		draw_row_loop
draw_row_loop_exit:
	addi	r9, r9, 1
	br		draw_loop
draw_loop_exit:


VU_end:
	br	oscilloscope_end
	
	
	
	
oscilloscope_start:
	
	# backup displacement
	mov		r8, r0
BACKUP_DISPLACEMENT_LOOP:
	movi	r9, 1280
	bge		r8, r9, BACKUP_DISPLACEMENT_LOOP_END
	ldw		r9, displacement_left(r8)
	stw		r9, displacement_left_backup(r8)
	ldw		r9, displacement_right(r8)
	stw		r9, displacement_right_backup(r8)
	addi	r8, r8, 4
	br		BACKUP_DISPLACEMENT_LOOP
BACKUP_DISPLACEMENT_LOOP_END:
	# backup offset
	ldw		r9, offset_counter(r0)
	stw		r9, offset_counter_backup(r0)

	# ack
	movia	r8, TIMER
	stwio	r0, 0(r8)
	movi	r8, 1
	wrctl	ctl0, r8
	
	# redraw_waveform
	mov		r9, r0		# x = r9, counter
redraw_wave_loop:                                              
# find offset of y
	ldw		r15, offset_counter_backup(r0)
	slli	r10, r9, 2
	add		r10, r10, r15
	movi	r11, 1280
	blt		r10, r11, dont_minus_1280
	subi	r10, r10, 1280
dont_minus_1280:
	# r10 = offset

	# left channel
	addi	r11, r10, displacement_left_backup
	ldw		r11, 0(r11)		# r11 = y_L
	slli	r11, r11, 10
	slli	r12, r9, 1
	add		r11, r11, r12
	movia	r12, DISP
	add		r8, r11, r12	# r8 = pixel_addr_L
	
	# right channel
	addi	r11, r10, displacement_right_backup
	ldw		r11, 0(r11)		# r11 = y_R
	slli	r11, r11, 10
	slli	r12, r9, 1
	add		r11, r11, r12
	movia	r12, DISP
	add		r10, r11, r12	# r10 = pixel_addr_R
	
	r9 = x
	r8 = addr_L
	r10 = addr_R
# clear column
	mov		r13, r0		# 1024y = r13 = 0
clear_column_loop:
	slli	r11, r9, 1
	add		r11, r11, r13
	movia	r12, DISP
	add		r11, r11, r12

	# r11 is destination pixel
	srli	r6, r11, 10
	andi	r6, r6, 0xFF	# r6 = destination y value
	
	# is sample height?****
	cmpeq	r5, r11, r8
	cmpeq	r4, r11, r10
	or		r5, r4, r5
	#***********************
/*	
	###### between sample height and center axis?#######
	cmpgt	r5, r11, r8
	cmpgti	r7, r6, SCOPE_AXIS_LEFT
	xor		r5, r5, r7
	cmpgt	r4, r11, r10
	cmpgti	r7, r6, SCOPE_AXIS_RIGHT
	xor		r4, r4, r7
	or		r5, r4, r5
	##############################################
*/	
	########### is center axis?  ###########
	cmpeqi	r3, r6, SCOPE_AXIS_LEFT
	cmpeqi	r4, r6, SCOPE_AXIS_RIGHT
	or		r3, r3, r4
	##############################################
	

	bne		r5, r0, is_sample
	bne		r3, r0, is_center
is_background:
	movui	r12, BACKGROUND
	br		end_case
is_sample:
	movui	r12, SCOPE_COLOR
	br		end_case
is_center:
	movui	r12, SCOPE_AXIS_COLOR
end_case:
	sthio	r12, 0(r11)
	
	
	addi	r13, r13, 1024
	movia	r11, 245100
	blt		r13, r11, clear_column_loop   
	
	addi	r9, r9, 1
	# stop when r9 == 320
	movi	r10, 320
	blt		r9, r10, redraw_wave_loop
oscilloscope_end:


	movia	r8, TIMER
	movui	r9, 0b0101
	stwio	r9, 4(r8)
	br		epilog
	
	
	
ihandler_kb:
	# ack
	movia	r8, KB
	ldwio	r8, 0(r8)
	ldw		r9, mode(r0)
	movi	r10, 1
	movia	r8, HEX
	movi	r11, 0b0000110  #1
	stwio	r11, 0(r8)
	beq		r9, r0, change_to_mode1
	mov		r10, r0
	movia	r8, HEX
	movi	r11, 0b0111111  #0
	stwio	r11, 0(r8)
change_to_mode1:
	stw		r10, mode(r0)
	# now r10 == current_mode
	br		epilog
	
	
ihandler_pushbt:
	ldw		r9, mode(r0)
	movi	r10, 1
	movia	r8, HEX
	movi	r11, 0b0000110  #1
	stwio	r11, 0(r8)
	beq		r9, r0, change_to_mode1_push
	mov		r10, r0
	movia	r8, HEX
	movi	r11, 0b0111111  #0
	stwio	r11, 0(r8)
change_to_mode1_push:
	stw		r10, mode(r0)
	
	# ack
	movia	r8, PUSHBT
	stw		r0, 12(r8)
	
	
epilog:
	# restore ea, et, clt1, any other stuff!
	#
	ldw		ea, 0(sp)
	ldw		et, 8(sp)
	wrctl	ctl1, et
	ldw		et, 4(sp)
	ldw		r2, 12(sp)
	ldw		r3, 16(sp)
	ldw		r4, 20(sp)
	ldw		r5, 24(sp)
	ldw		r6, 28(sp)
	ldw		r7, 32(sp)
	ldw		r8, 36(sp)
	ldw		r9, 40(sp)
	ldw		r10, 44(sp)
	ldw		r11, 48(sp)
	ldw		r12, 52(sp)
	ldw		r13, 56(sp)
	ldw		r14, 60(sp)
	ldw		r15, 64(sp)
	ldw		ra, 68(sp)
	addi	sp, sp, 72
	
	subi	ea, ea, 4
	eret


.section .data
.align 2

displacement_left:
.skip 1280		# 320 pixels * 4 = 1280

displacement_right:
.skip 1280		# 320 pixels * 4 = 1280

displacement_left_backup:
.skip 1280		# 320 pixels * 4 = 1280

displacement_right_backup:
.skip 1280		# 320 pixels * 4 = 1280

sample_counter:
.word 0

offset_counter:
.word 0

offset_counter_backup:
.word 0

mode:
.word 0

peak_calculating_L:
.word 0

peak_prev_L:
.word 0

peak_prev_L_backup:
.word 0

peak_calculating_R:
.word 0

peak_prev_R:
.word 0

peak_prev_R_backup:
.word 0

sample_counter_for_VU:
.word 0



.section .text
.global main

clear_screen:
	movia	r8, DISP
	movui	r11, BACKGROUND
clear_screen_loop:
	sthio	r11, 0(r8)
	addi	r8, r8, 2	# next pixel in the line
	srli	r9, r8, 1
	andi	r9, r9, 0x1FF
	movi	r10, 320
	blt		r9, r10, clear_screen_loop	# a line complete?
# a line complete, clear next line
	srli	r8, r8, 10
	addi	r8, r8, 1
	andi	r9, r8, 0xFF
	slli	r8, r8, 10
	movi	r10, 240
	blt		r9, r10, clear_screen_loop
	ret


main:
	call	clear_screen
	
	movia	r8, HEX
	movi	r11, 0b0111111
	stwio	r11, 0(r8)
	
# clear audio FIFOs
	movi	r8, 0b1100
	movia	r9, AUDIO
	stwio	r8, 0(r9)
	movi	r8, 0b0001
	stwio	r8, 0(r9)
	
# setup timer with interrupt
	movia	r8, TIMER
	movui	r9, 0b1000
	stwio	r9, 4(r8)
	stwio	r0, 0(r8)
	movui	r9, %lo(REFRESH)
	stwio	r9, 8(r8)
	movui	r9, %hi(REFRESH)
	stwio	r9, 12(r8)
	movui	r9, 0b0101
	stwio	r9, 4(r8)

# setup keyboard interrupt
	movia	r8, KB
	movi	r9, 1
	stwio	r9, 4(r8)
	
# setup pushbutton interrupt
	movia	r8, PUSHBT
	movi	r9, 0b1110
	stwio	r9, 8(r8)
	
	mov		r15, r0
scope_starts:
# initialize the waveform
	addi	r8, r15, displacement_left
	movi	r9, SCOPE_AXIS_LEFT
	stw		r9, 0(r8)
	addi	r8, r15, displacement_right
	movi	r9, SCOPE_AXIS_RIGHT
	stw		r9, 0(r8)
	addi	r15, r15, 4
	movi	r8, 1280
	bne		r8, r15, scope_starts
	
	
# config CPU interrupt
	movi	r8, 0b11000011
	wrctl	ctl3, r8
	movi	r8, 1
	wrctl	ctl0, r8

wait:
	br		wait
	


	
	







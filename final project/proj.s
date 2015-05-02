.include "nios_macros.s"
.equ DISP, 0x08000000
.equ AUDIO, 0x10003040
.equ TIMER, 0x10002000
.equ BACKGROUND, 0xFFFF
.equ REFRESH, 1
.equ NUM_SAMPLE_READ_PER_INTRPT, 1
.equ SCOPE_SAMPLE_INTERVAL, 1
.equ SCOPE_AXIS_LEFT, 62
.equ SCOPE_AXIS_RIGHT, 177
.equ SCOPE_HOR_SCALE, 41297762
.equ SCOPE_COLOR, 0x0000

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
	# which chuncks to store?
	addi	r10, r15, displacement_left_0
	ldw		r6, cycle(r0)
	beq		r6, r0, cycle_0_left
	addi	r10, r15, displacement_left_1
cycle_0_left:
	# chunck decided!
	stw		r8, 0(r10)
	movia	r10, SCOPE_HOR_SCALE
	div		r9, r9, r10
	movi	r10, SCOPE_AXIS_RIGHT
	sub		r9, r10, r9
	# which chuncks to store?
	addi	r10, r15, displacement_right_0
	ldw		r6, cycle(r0)
	beq		r6, r0, cycle_0_right
	addi	r10, r15, displacement_right_1
cycle_0_right:
	# chunck decided!
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
	# ack
	movia	r8, TIMER
	stwio	r0, 0(r8)
	
	movi	r8, 1
	wrctl	ctl0, r8
	
# time to switch cycle
	ldw		r8, cycle(r0)
	stw		r0, cycle(r0)
	bne		r8, r0, to_cycle0
	movi	r8, 1
	stw		r8, cycle(r0)
to_cycle0:

	# redraw_waveform
	mov		r9, r0		# x = r9, counter
redraw_wave_loop:                                              
# find offset of y
	ldw		r15, offset_counter(r0)
	muli	r10, r9, 4
	add		r10, r10, r15
	movi	r11, 1280
	blt		r10, r11, dont_minus_1280
	subi	r10, r10, 1280
dont_minus_1280:
	# r10 = offset

	# left channel
	# which chuncks to store?
	addi	r11, r10, displacement_left_1
	ldw		r7, cycle(r0)
	beq		r7, r0, cycle_0_disp
	addi	r11, r10, displacement_left_0
cycle_0_disp:

	# chunck decided!
	ldw		r11, 0(r11)		# r11 = y_L
	muli	r11, r11, 1024
	slli	r12, r9, 1
	add		r11, r11, r12
	movia	r12, DISP
	add		r8, r11, r12	# r8 = pixel_addr_L
	
	# right channel
	# which chuncks to store?
	addi	r11, r10, displacement_right_1
	ldw		r7, cycle(r0)
	bne		r7, r0, cycle_1_disp_right
	addi	r11, r10, displacement_right_0
cycle_1_disp_right:	
	ldw		r11, 0(r11)		# r11 = y_R
	muli	r11, r11, 1024
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
	cmpge	r5, r11, r8
	cmpgei	r7, r6, SCOPE_AXIS_LEFT
	xor		r5, r5, r7
	cmpge	r4, r11, r10
	cmpgei	r7, r6, SCOPE_AXIS_RIGHT
	xor		r4, r4, r7
	or		r5, r4, r5
	
	movui	r12, BACKGROUND
	beq		r0, r5, IS_BGND
	movui	r12, SCOPE_COLOR
IS_BGND:
	sthio	r12, 0(r11)
	addi	r13, r13, 1024
	movia	r11, 245100
	blt		r13, r11, clear_column_loop   
	
	addi	r9, r9, 1
	# stop when r9 == 320
	movi	r10, 320
	blt		r9, r10, redraw_wave_loop
	movia	r8, TIMER
	movui	r9, 0b0101
	stwio	r9, 4(r8)

	
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

displacement_left_0:
.space 1280		# 320 pixels * 4 = 1280

displacement_right_0:
.space 1280		# 320 pixels * 4 = 1280

displacement_left_1:
.space 1280		# 320 pixels * 4 = 1280

displacement_right_1:
.space 1280		# 320 pixels * 4 = 1280

sample_counter:
.word 0

offset_counter:
.word 0

cycle:
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

	
	mov		r15, r0
scope_starts:
/*
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
*/
	
# config CPU interrupt
	movi	r8, 0b1000001
	wrctl	ctl3, r8
	movi	r8, 1
	wrctl	ctl0, r8

wait:
	br		wait
	
/*
# initialize some important registers
	mov		r14, r0		# count sample intervals
	mov		r15, r0		# count pixel array index

poll_codec:
	movia	r10, AUDIO
poll_right:
	ldwio	r8, 4(r10)
	andi	r9, r8, 0xFF
	beq		r9, r0, poll_right
poll_left:
	ldwio	r8, 4(r10)
	srli	r9, r8, 8
	andi	r9, r9, 0xFF
	beq		r9, r0, poll_left
# poll both success, read data
	ldwio	r8, 8(r10)	# left data
	ldwio	r9, 12(r10)	# right data
	stwio	r8, 8(r10)	# left data
	stwio	r9, 12(r10)	# right data
	addi	r14, r14, 1		# increment counter
# show a new sample on screen or not?
	movi	r10, SCOPE_SAMPLE_INTERVAL	# show one sample in every SCOPE_SAMPLE_INTERVAL samples
	
	beq		r14, r10, store_displacement	# store 
	br		poll_codec		# don't store. just read another sample
store_displacement:
	mov		r14, r0
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
	blt		r15, r8, dont_reset_r15
# reset r15
	mov		r15, r0
dont_reset_r15:
# refresh screen or not?
	movia	r8, TIMER
	ldwio	r9, 0(r8)
	andi	r9, r9, 0b1
	beq		r0, r9, poll_codec
	#br		poll_codec
	
	stwio	r0, 0(r8)

# redraw_waveform
	mov		r9, r0		# x = r9, counter
	
redraw_wave_loop:                                              
# find offset of y
	muli	r10, r9, 4
	add		r10, r10, r15
	movi	r11, 1280
	blt		r10, r11, dont_minus_1280
	subi	r10, r10, 1280
dont_minus_1280:
	# r10 = offset
	
	
	# left channel
	addi	r11, r10, displacement_left		
	ldw		r11, 0(r11)		# r11 = y_L
	muli	r11, r11, 1024
	slli	r12, r9, 1
	add		r11, r11, r12
	movia	r12, DISP
	add		r8, r11, r12	# r8 = pixel_addr_L
	
	# right channel
	addi	r11, r10, displacement_right		
	ldw		r11, 0(r11)		# r11 = y_R
	muli	r11, r11, 1024
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
	cmpge	r5, r11, r8
	cmpgei	r7, r6, SCOPE_AXIS_LEFT
	xor		r5, r5, r7
	cmpge	r4, r11, r10
	cmpgei	r7, r6, SCOPE_AXIS_RIGHT
	xor		r4, r4, r7
	or		r5, r4, r5
	
	movui	r12, BACKGROUND
	beq		r0, r5, IS_BGND
	movui	r12, SCOPE_COLOR
IS_BGND:
	sthio	r12, 0(r11)
	addi	r13, r13, 1024
	movia	r11, 245100
	blt		r13, r11, clear_column_loop   
	
	addi	r9, r9, 1
	# stop when r9 == 320
	movi	r10, 320
	blt		r9, r10, redraw_wave_loop
	mov		r14, r0		# reset r14
	br		poll_codec
	
*/	

	
	







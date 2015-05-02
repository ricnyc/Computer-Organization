.include "nios_macros.s"

.equ	UART_TERM, 0x10001000
.equ	UART_CAR, 0x10001020
.equ	TIMER, 	0x10002000
.equ	LEFT_ANG, -64
.equ	RIGHT_ANG, 64
.equ	HLEFT_ANG, -127		
.equ	HRIGHT_ANG, 127
.equ	STRAIGHT_SPD_MAX, 48
.equ	STRAIGHT_SPD_MIN, 47
.equ	LEFT_SPD_MAX, 41
.equ	LEFT_SPD_MIN, 41
.equ	RIGHT_SPD_MAX, 41
.equ	RIGHT_SPD_MIN, 41
.equ	HLEFT_SPD_MAX, 41
.equ	HLEFT_SPD_MIN, 41
.equ	HRIGHT_SPD_MAX, 41
.equ	HRIGHT_SPD_MIN, 41
.equ	DISP_SPD, 0
.equ	DISP_SENSORS, 1

.section .data
disp:
	.byte 0
speed:
	.byte 0
sensors:
	.byte 0

	
.align 2
.section .text
.global main
		
read_sensor_spd:
	# prolog
	subi	sp, sp, 12
	stw		r16, 0(sp)
	stw		r17, 4(sp)
	stw		ra, 8(sp)
	# send req
	movi	r16, 2
	movia	r17, UART_CAR
	movia	r4, UART_CAR
	call	poll_write
	stwio	r16, 0(r17)
poll_type_0:
	movia	r4, UART_CAR
	call	read_pak
	bne		r2, r0, poll_type_0
	movia	r4, UART_CAR
	call	read_pak
	mov		r3, r2		# r3 = sensor
	movia	r4, UART_CAR
	call	read_pak	# r2 = speed	
	# epilog
	ldw		r16, 0(sp)
	ldw		r17, 4(sp)
	ldw		ra, 8(sp)
	addi	sp, sp, 12
	ret		# r2=speed  r3=sensor

	
	
change_accel:	# accel = r4
	subi	sp, sp, 16
	stw		r16, 0(sp)
	stw		r17, 4(sp)
	stw		r18, 8(sp)
	stw		ra, 12(sp)
	movi	r16, 4
	movia	r17, UART_CAR
	mov		r18, r4
	movia	r4, UART_CAR
	call	poll_write
	stwio	r16, 0(r17)
	movia	r4, UART_CAR
	call	poll_write
	stwio	r18, 0(r17)
	ldw		r16, 0(sp)
	ldw		r17, 4(sp)
	ldw		r18, 8(sp)
	ldw		ra, 12(sp)
	addi	sp, sp, 16
	ret
	
	
	
change_angle:	# angle = r4
	subi	sp, sp, 16
	stw		r16, 0(sp)
	stw		r17, 4(sp)
	stw		r18, 8(sp)
	stw		ra, 12(sp)
	movi	r16, 5
	movia	r17, UART_CAR
	mov		r18, r4
	movia	r4, UART_CAR
	call	poll_write
	stwio	r16, 0(r17)
	movia	r4, UART_CAR
	call	poll_write
	stwio	r18, 0(r17)
	ldw		r16, 0(sp)
	ldw		r17, 4(sp)
	ldw		r18, 8(sp)
	ldw		ra, 12(sp)
	addi	sp, sp, 16
	ret

	
	
poll_write:	# poll a UART for writing
			# r4 = UART addr
	subi	sp, sp, 4
	stw		r16, 0(sp)
poll_write_loop:
	ldwio	r16, 4(r4)
	srli	r16, r16, 16
	beq		r16, r0, poll_write_loop
	ldw		r16, 0(sp)
	addi	sp, sp, 4
	ret
	
write_pak:	# r4=byte r5=UART_addr
	subi	sp, sp, 12
	stw		r16, 0(sp)
	stw		r17, 4(sp)
	stw		ra, 8(sp)
	mov		r16, r4
	mov		r17, r5
	mov		r4, r5
	call	poll_write
	stwio	r16, 0(r17)
	ldw		r16, 0(sp)
	ldw		r17, 4(sp)
	ldw		ra, 8(sp)
	addi	sp, sp, 12
	ret
	
read_pak:	# read a packet from a UART
			# r4 = UART addr
	subi	sp, sp, 4
	stw		r16, 0(sp)
read_pak_loop:
	ldwio	r2, 0(r4)
	srli	r16, r2, 15
	andi	r16, r16, 0b1
	beq		r16, r0, read_pak_loop
	andi	r2, r2, 0xFF
	ldw		r16, 0(sp)
	addi	sp, sp, 4
	ret		# r2 = packet read
	
	
	
pause:	# setup timer without intterupt and continuing
		# r4 = # of clock cycles
	# prolog
	subi	sp, sp, 8
	stw		r16, 0(sp)
	stw		r17, 4(sp)
	# reset timer
	movia	r16, TIMER
	movi	r17, 0b1000
	stwio	r17, 4(r16)
	stwio	r0, 0(r16)
	# set period and start
	andi	r17, r4, 0xFFFF
	stwio	r17, 8(r16)
	srli	r17, r4, 16
	stwio	r17, 12(r16)
	movi	r17, 0b0100
	stwio	r17, 4(r16)
poll_timeout:
	ldwio	r17, 0(r16)
	andi	r17, r17, 0b1
	beq		r17, r0, poll_timeout
	# epilog
	ldw		r16, 0(sp)
	ldw		r17, 4(sp)
	addi	sp, sp, 8
	ret
	
	
	
timer_interrupt:	# setup timer and enable interrupt and continuing
					# r4 = # of clock cycles
	# prolog
	subi	sp, sp, 8
	stw		r16, 0(sp)
	stw		r17, 4(sp)
	# reset timer
	movia	r16, TIMER
	movi	r17, 0b1000
	stwio	r17, 4(r16)
	stwio	r0, 0(r16)
	# set period and start
	andi	r17, r4, 0xFFFF
	stwio	r17, 8(r16)
	srli	r17, r4, 16
	stwio	r17, 12(r16)
	movi	r17, 0b0111
	stwio	r17, 4(r16)
	# epilog
	ldw		r16, 0(sp)
	ldw		r17, 4(sp)
	addi	sp, sp, 8
	ret
	
	
	
set_spd:	# only compare with current spd
			# and set accel according to the result at this moment
			# so must call repeatedly
			# r4=max r5=min r6=current
	subi	sp, sp, 4
	stw		ra, 0(sp)
	bge		r6, r4, slower
	ble		r6, r5, faster
faster:
	movi	r4, 127
	call	change_accel
	br		return
slower:
	movi	r4, -128
	call	change_accel
	br		return
return:
	ldw		ra, 0(sp)
	addi	sp, sp, 4
	ret
	
	
main:
	
check_sensor_spd:
	call	read_sensor_spd
	mov		r18, r2				# r18 = spd
	andi	r16, r3, 0b11111	# r16 = sensors
	movi	r17, 0b11111
	beq		r16, r17, straight
	movi	r17, 0b01111
	beq		r16, r17, right
	movi	r17, 0b00111
	beq		r16, r17, hard_right
	movi	r17, 0b11110
	beq		r16, r17, left
	movi	r17, 0b11100
	beq		r16, r17, hard_left
	br		check_sensor_spd
straight:
	mov		r4, r0
	call	change_angle
	mov		r6, r18
	movi	r4, STRAIGHT_SPD_MAX
	movi	r5, STRAIGHT_SPD_MIN
	call	set_spd
	br		check_sensor_spd
left:
	movi	r4, LEFT_ANG
	call	change_angle
	mov		r6, r18
	movi	r4, LEFT_SPD_MAX
	movi	r5, LEFT_SPD_MIN
	call	set_spd
	br		check_sensor_spd
hard_left:
	movi	r4, HLEFT_ANG
	call	change_angle	
	mov		r6, r18
	movi	r4, HLEFT_SPD_MAX
	movi	r5, HLEFT_SPD_MIN
	call	set_spd
	br		check_sensor_spd
right:
	movi	r4, RIGHT_ANG
	call	change_angle
	mov		r6, r18
	movi	r4, RIGHT_SPD_MAX
	movi	r5, RIGHT_SPD_MIN
	call	set_spd
	br		check_sensor_spd
hard_right:
	movi	r4, HRIGHT_ANG
	call	change_angle
	mov		r6, r18
	movi	r4, HRIGHT_SPD_MAX
	movi	r5, HRIGHT_SPD_MIN
	call	set_spd
	br		check_sensor_spd


	
	
	
	
	
	
	
	
	
	
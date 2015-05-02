.section .text
.global main
.equ	JP1, 0x10000060
.equ	TIMER, 0x10002000

main:
	movia	r9, JP1
	# set direction registers
	movia	r8, 0x07F557FF
	stwio	r8, 4(r9)		

	# disable all sensors and motors
	ldwio	r8, 0(r9)
	orhi	r8, r8, 0x0005
	ori		r8, r8, 0x57FF
	stwio	r8, 0(r9)
	
	# set up timer
	# stop the timer, set continue bits
	movia	r9, TIMER
	movia	r8, 0b1010
	stwio	r8, 4(r9)
	
	# set the period
	addi	r8, r0, %lo(3000)
	stwio	r8, 8(r9)
	addi	r8, r0, %hi(3000)
	stwio	r8, 8(r9)
	
	# start the timer
	movia	r8, 0b0110
	stwio	r8, 4(r9)
	

	
	
check_sensors:	
	# drop the timer flag
	ldwio	r8, 0(r9)
	andhi	r8, r8, 0xFFFF
	andi	r8, r8, 0xFFFE
	stwio	r8, 0(r9)
	
	movia	r9, JP1
	
enable_sensor0:
	ldwio	r8, 0(r9)
	andhi	r8, r8, 0xFFFF
	andi	r8, r8, 0xFBFF
	stwio	r8, 0(r9)
	
poll_sensor0:
	ldwio	r8, 0(r9)
	srli	r8, r8, 11
	andhi	r8, r8, 0x0
	andi	r8, r8, 0x1
	bne		r8, r0, poll_sensor0

read_sensor0:
	ldwio	r8, 0(r9)
	srli	r8, r8, 27
	andhi	r15, r8, 0x0
	andi	r15, r8, 0xF	# r15 stores the value for sensor 0
	
disable_sensor_0:
	ldwio	r8, 0(r9)
	orhi	r8, r8, 0x0000
	ori		r8, r8, 0x0400
	stwio	r8, 0(r9)
	
enable_sensor1:
	ldwio	r8, 0(r9)
	andhi	r8, r8, 0xFFFF
	andi	r8, r8, 0xEFFF
	stwio	r8, 0(r9)
	
poll_sensor1:
	ldwio	r8, 0(r9)
	srli	r8, r8, 13
	andhi	r8, r8, 0x0
	andi	r8, r8, 0x1
	bne		r8, r0, poll_sensor1

read_sensor1:
	ldwio	r8, 0(r9)
	srli	r8, r8, 27
	andhi	r14, r8, 0x0
	andi	r14, r8, 0xF	# r14 stores the value for sensor 1
	
disable_sensor_1:
	ldwio	r8, 0(r9)
	orhi	r8, r8, 0x0000
	ori		r8, r8, 0x1000
	stwio	r8, 0(r9)
	
compare_sensor_values:
	addi	r15, r15, 0		# probably need to do some trimming here
	bgt		r15, r14, to_left			
	blt		r15, r14, to_right
	br		stop_motor

to_left:
	ldwio	r8, 0(r9)
	andhi	r8, r8, 0xFFFF
	andi	r8, r8, 0xFFFC
	stwio	r8, 0(r9)
	br		wait_before_stop

to_right:
	ldwio	r8, 0(r9)
	andhi	r8, r8, 0xFFFF
	andi	r8, r8, 0xFFFE
	stwio	r8, 0(r9)
	
wait_before_stop:
	movia	r9, TIMER
	
	ldwio	r8,	0(r9)
	andhi	r8, r8, 0x0
	andi	r8, r8, 0x1
	beq		r8, r0, wait_before_stop
	
	# drop flag
	ldwio	r8, 0(r9)
	andhi	r8, r8, 0xFFFF
	andi	r8, r8, 0xFFFE
	stwio	r8, 0(r9)
	
	movia	r9, JP1
	
stop_motor:
	ldwio	r8, 0(r9)
	orhi	r8, r8, 0x0000
	ori		r8, r8, 0x0003
	stwio	r8, 0(r9)
	br		wait_after_stop
	
wait_after_stop:
	movia	r9, TIMER
	
	ldwio	r8,	0(r9)
	andhi	r8, r8, 0x0
	andi	r8, r8, 0x1
	beq		r8, r0, wait_after_stop
	
	br		check_sensors









	
.section .text
.global main
.equ	JP1, 0x10000060
.equ	TIMER, 0x10002000
.include "nios_macros.s"

main:
	movia	r9, JP1
	movia	r11, TIMER
	# set direction registers
	movia	r8, 0x07F557FF
	stwio	r8, 4(r9)

	# disable all sensors and motors
	ldwio	r8, 0(r9)
	subi	r8, r0, 1
	stwio	r8, 0(r9)


check_sensors:	
#enable_sensor5 
	movia	r8, 0xFFFBFFFC
	ldwio	r10, 0(r9)
	andi	r10, r10, 0b11
	add		r8, r8, r10
	stwio	r8, 0(r9)
	
poll_sensor5:
	ldwio	r8, 0(r9) 
	srli	r8, r8, 19
	andi	r8, r8, 0x1
	bne		r8, r0, poll_sensor5

#read_sensor5
	ldwio	r8, 0(r9)
	srli	r8, r8, 27
	andi	r15, r8, 0xF	# r15 stores the value for sensor 5
	
#enable_sensor4, disable_sensor5
	movia	r8, 0xFFFEFFFC
	ldwio	r10, 0(r9)
	andi	r10, r10, 0b11
	add		r8, r8, r10
	stwio	r8, 0(r9)
	
poll_sensor4:
	ldwio	r8, 0(r9)
	srli	r8, r8, 17
	andi	r8, r8, 0x1
	bne		r8, r0, poll_sensor4

#read_sensor4
	ldwio	r8, 0(r9)
	srli	r8, r8, 27
	andi	r14, r8, 0xF	# r14 stores the value for sensor 4
	
#disable_sensor_4
	subi	r8, r0, 4
	ldwio	r10, 0(r9)
	andi	r10, r10, 0b11
	add		r8, r8, r10
	stwio	r8, 0(r9)
	
#compare_sensor_values
	addi	r14, r14, 0		# probably need to do some trimming here
	bgt		r15, r14, to_right			
	blt		r15, r14, to_left
	br		stop_motor

to_left:
	subi	r8, r0, -4
	stwio	r8, 0(r9)
	br		check_sensors

to_right:
	subi	r8, r0, -2
	stwio	r8, 0(r9)
	br		check_sensors

	
stop_motor:
	subi	r8, r8, 1
	stwio	r8, 0(r9)
	br		check_sensors
	








	
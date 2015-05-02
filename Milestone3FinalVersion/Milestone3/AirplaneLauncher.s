/* Airplane Launcher */
/* Currently can be launched with the modified machine structure - Milestone */
/* Milestone 3*/

.equ ADDR_GREENLEDS, 0x10000010 /* GREEN LED */
.equ ADDR_REDLEDS, 0x10000000 /* Red LED */
.equ ADDR_JP1, 0x10000060   /*Address GPIO JP1*/
.equ TIMER, 0x10002000
.equ PS2, 0X10000100 /*PS2 Controller*/


#.equ period, 0x0EE6B280 /*5seconds*/
.equ period, 0x02FAF080 /*1second*/
.equ JTAG_UART_2, 0x10001000


.global main
main:


movia sp, 0x7ffff0  
  movia  r8, ADDR_JP1
  
  movia  r9, 0x07f557ff        /* set direction for motors to all output */
  stwio  r9, 4(r8)
  movia  r9, 0xffffffff
  stwio r9, 0(r8)
  
  
  
  movia r16, TIMER
  movui r17, %lo(period)
  stwio r17, 8(r16)
  
  movui r17, %hi(period)
  stwio r17, 12(r16)
  stwio r0, 0(r16) #reset timer
  movi r17, 0b111
  stwio r17, 4(r16)
  
  
  #setup the interrupt
  
   movi r17, 0x181 #enable the IRQ 0 and 8 and 7 for timer and JTAG_UART_2
   wrctl ctl3, r17
	
   movi r17, 0b1 # the CPU enable
   wrctl ctl0, r17
	
	
   movia r10, JTAG_UART_2
   stwio r17, 4(r10) #enable JTAG_UART_2 interrupt
   
   movia r10, PS2
   stwio r17, 4(r10) #enable PS2 interrupt
   
  

  
  movia r11, 0xfffffbff #sensor 0, 111111111111 11111 11110 11111 11111
  movia r12, 0xffffefff #sensor 1, 111111111111 11111 11011 11111 11111  
  movia r14, 0xffffbfff #sensor 2, 111111111111 11111 01111 11111 11111
  movia r19, 0xffffbfff #sensor 22
  movia r22, 0xfffeffff
  
  
  
 
start1:

sensor_3:
   stwio r22, 0(r8)
   ldwio  r4, 0(r8)           /* checking for valid data sensor 0*/
   srli   r4, r4, 17           /* bit 11 equals valid bit for sensor 0*/           
   andi   r4, r4, 0x1
   bne    r0, r4, sensor_3     /* checking if low indicated polling data at sensor 0 is valid*/
   
good3:
   ldwio  r21, 0(r8)         /* read sensor0 value (into r10) */
   srli   r21, r21, 27       /* shift to the right by 27 bits so that 4-bit sensor value is in lower 4 bits */
   andi   r21, r21, 0x0f
  
sensor_0:
   stwio r11, 0(r8)
   ldwio  r4, 0(r8)           /* checking for valid data sensor 0*/
   srli   r4, r4, 11           /* bit 11 equals valid bit for sensor 0*/           
   andi   r4, r4, 0x1
   bne    r0, r4, sensor_0     /* checking if low indicated polling data at sensor 0 is valid*/
   
good0:
   ldwio  r10, 0(r8)         /* read sensor0 value (into r10) */
   srli   r10, r10, 27       /* shift to the right by 27 bits so that 4-bit sensor value is in lower 4 bits */
   andi   r10, r10, 0x0f
 

 
sensor_1:
   stwio r12, 0(r8)

   ldwio  r5, 0(r8)           /* checking for valid data sensor 1*/
   srli   r5, r5, 13           /* bit 13 equals valid bit for sensor 1*/           
   andi   r5, r5, 0x1
   bne    r0, r5, sensor_1     /* checking if low indicated polling data at sensor 1 is valid*/
   
good1:
   ldwio  r13, 0(r8)         /* read sensor1 value (into r10) */
   srli   r13, r13, 27       /* shift to the right by 27 bits so that 4-bit sensor value is in lower 4 bits */
   andi   r13, r13, 0x0f 
 

compare:
	beq r10, r0, right
	beq r13, r0, left
	#beq r21, r0, VGA
    br start1

right:
  movia  r9, 0xffffffcf #enable the motor 2 
  stwio	 r9, 0(r8)
  
  call motor 
  br start1
  
left:
  movia  r9, 0xffffffef #enable the motor 2
  stwio	 r9, 0(r8)
  

  
  call motor 
  br start1	
  
VGA:
  beq r21, r0, printinfo
  
printinfo:  
  /*Print to terminal*/
  mov r4, r21  
  call printStatus
  movia r21,ADDR_GREENLEDS
  movi  r22,0b11111111
  stwio r22,0(r21)        /* Write to LEDs */
  
  /*Print to screen */
  #movi r4, 10
  #movi r5, 10
  #movi r6, 10
  call PrintScreen
  call lcd

light:
	/*Light all Green LEDS*/
  movia r21,ADDR_GREENLEDS
  movi  r22,0b11111111
  stwio r22,0(r21)        /* Write to LEDs */
  
motor:
  subi sp, sp, 4
  stw r16, 0(sp)
  
  movia r16,10000000 /* set starting point for delay counter */
  DELAY:
  subi r16,r16,1       /* subtract 1 from delay */
  bne r16,r0, DELAY   /* continue subtracting if delay has not elapsed */
 
  ldw r16, 0(sp)
  addi sp, sp, 4
 
ret 


time:
   subi sp, sp, 4
   stw ra, 0(sp)
   call time_period
   ldw ra, 0(sp)
   addi sp, sp, 4
   br  sensor_0


time_period:

  subi sp, sp, 12
  stw r16, 8(sp)
  stw r17, 4(sp)
  stw r18, 0(sp)
  
  /*movia r16, timer
  movui r17, %lo(period)
  stwio r17, 8(r16)
  
  movui r17, %hi(period)
  stwio r17, 12(r16)
  stwio r0, 0(r16)#reset timer
  movi r17, 0b111
  stwio r17, 4(r16)*/

  
  mov  r20, r0
  
   ldw r18, 0(sp)
   ldw r17, 4(sp)
   ldw r16, 8(sp)

   addi sp, sp, 12
ret


fly:
  
  movia  r9, 0xfffffffa #enable the motor 0 and motor 1,  111111111111 11111 11111 11111 11010
  stwio	 r9, 0(r8)
  movia r16,50000000/* set starting point for delay counter */
  
  
  subi sp, sp, 48
  stw r4, 0(sp)
  stw r5, 4(sp)
  stw r6, 8(sp)
  stw r7, 12(sp)
  stw r8, 16(sp)
  stw r9, 20(sp)
  stw r10, 24(sp)
  stw r11, 28(sp)
  stw r12, 32(sp)
  stw r13, 36(sp)
  stw r14, 40(sp)
  stw r15, 44(sp)
  call printStatus
  ldw r4, 0(sp)
  ldw r5, 4(sp)
  ldw r6, 8(sp)
  ldw r7, 12(sp)
  ldw r8, 16(sp)
  ldw r9, 20(sp)
  ldw r10, 24(sp)
  ldw r11, 28(sp)
  ldw r12, 32(sp)
  ldw r13, 36(sp)
  ldw r14, 40(sp)
  ldw r15, 44(sp)
  addi sp, sp, 48
  
  subi sp, sp, 48
  stw r4, 0(sp)
  stw r5, 4(sp)
  stw r6, 8(sp)
  stw r7, 12(sp)
  stw r8, 16(sp)
  stw r9, 20(sp)
  stw r10, 24(sp)
  stw r11, 28(sp)
  stw r12, 32(sp)
  stw r13, 36(sp)
  stw r14, 40(sp)
  stw r15, 44(sp)
  call PrintScreen
  ldw r4, 0(sp)
  ldw r5, 4(sp)
  ldw r6, 8(sp)
  ldw r7, 12(sp)
  ldw r8, 16(sp)
  ldw r9, 20(sp)
  ldw r10, 24(sp)
  ldw r11, 28(sp)
  ldw r12, 32(sp)
  ldw r13, 36(sp)
  ldw r14, 40(sp)
  ldw r15, 44(sp)
  addi sp, sp, 48
  
  subi sp, sp, 48
  stw r4, 0(sp)
  stw r5, 4(sp)
  stw r6, 8(sp)
  stw r7, 12(sp)
  stw r8, 16(sp)
  stw r9, 20(sp)
  stw r10, 24(sp)
  stw r11, 28(sp)
  stw r12, 32(sp)
  stw r13, 36(sp)
  stw r14, 40(sp)
  stw r15, 44(sp)
  call lcd
  ldw r4, 0(sp)
  ldw r5, 4(sp)
  ldw r6, 8(sp)
  ldw r7, 12(sp)
  ldw r8, 16(sp)
  ldw r9, 20(sp)
  ldw r10, 24(sp)
  ldw r11, 28(sp)
  ldw r12, 32(sp)
  ldw r13, 36(sp)
  ldw r14, 40(sp)
  ldw r15, 44(sp)
  addi sp, sp, 48
 
  DELAY3:
  subi r16,r16,1       /* subtract 1 from delay */
  bne r16,r0, DELAY3   /* continue subtracting if delay has not elapsed */

  loop_forever:
  br loop_forever
  
  
  
    .section .exceptions, "ax"
 IHANDLER:
	subi sp, sp, 32 #save ea, et, ctl1
	stw et, 0(sp)
	rdctl et, ctl1
	stw et, 4(sp)
	stw ea, 8(sp)
	stw r16, 12(sp)
	stw r17, 16(sp)
	stw r18, 20(sp)
	stw r19, 24(sp)
	stw r20, 28(sp)
	
	
	#check the ipending bits for IRQ7
	rdctl et, ctl4
	andi et, et, 0x80
	bne et, r0, HANDLE_PS2
	
	#check the ipending bits for IRQ8
	rdctl et, ctl4
	andi et, et, 0x100
	bne et, r0, HANDLE_JTAG_UART
		
	#check if interrupt is caused by the timer
	rdctl et, ctl4
	andi et, et, 0x1
	bne et, r0, HANDLE_TIMER 
  
	br EXIT_IHANDLER
	
HANDLE_TIMER: 

  
sensor_22:
   stwio r19, 0(r8)
   ldwio  r4, 0(r8)           /* checking for valid data sensor 0*/
   srli   r4, r4, 15           /* bit 11 equals valid bit for sensor 0*/           
   andi   r4, r4, 0x1
   bne    r0, r4, sensor_22     /* checking if low indicated polling data at sensor 0 is valid*/
   
good22:
	  

   movia et, TIMER
   stwio r0, 0(et)

   ldwio  r18, 0(r8)         /* read sensor0 value (into r10) */
   srli   r18, r18, 27       /* shift to the right by 27 bits so that 4-bit sensor value is in lower 4 bits */
   andi   r18, r18, 0x0f
   beq 	  r18, r0, fly
   

   
   br EXIT_IHANDLER
    


HANDLE_JTAG_UART: 


	
	READ_POLL_8:
  	movia r20, JTAG_UART_2 
  	ldwio et, 0(r20) 
  	andi  r20, et, 0x8000 
  	beq   r20, r0, READ_POLL_8
  	andi et, et, 0xFF #mask first 8 bit
	

	
  	movi r16, 'd'
  	beq et, r16, left1
  	movi r16, 'a'
  	beq et, r16, right1


	right1:
	movia  r17, 0xffffffcf #enable the motor 2 
	stwio	 r17, 0(r8)

	call motor 
 	br EXIT_IHANDLER
  
	left1:
	movia  r17, 0xffffffef #enable the motor 2
	stwio r17, 0(r8)
	
	call motor
  	br EXIT_IHANDLER
	
HANDLE_PS2:
  	movia r20, PS2 
  	ldwio et, 0(r20) 
  	andi et, et, 0xFF #mask first 8 bit
	

	
  	movi r16, 0x1C
  	beq et, r16, left2
  	movi r16, 0x23
  	beq et, r16, right2
    br EXIT_IHANDLER

	right2:
	movia  r17, 0xffffffcf #enable the motor 2 
	stwio  r17, 0(r8)
	call motor 
	
	
	
	     
 	br EXIT_IHANDLER
  
  
	left2:
	movia  r17, 0xffffffef #enable the motor 2
	stwio r17, 0(r8)
	call motor
	

	
	
  	br EXIT_IHANDLER
	
	
	
  EXIT_IHANDLER:
	
	ldw et, 4(sp)
	wrctl ctl1, et
	ldw et, 0(sp)
	ldw ea, 8(sp)
	
	ldw r16, 12(sp)
	ldw r17, 16(sp)
	ldw r18, 20(sp)
	ldw r19, 24(sp)
	ldw r20, 28(sp)
	addi sp, sp, 32
	subi ea, ea, 4
	
	eret
  
  
  
/****************** User's Instructions ********************/
.section .data

.align 2
START:
.word 0
.word INSTR1
INSTR1:
.word 1
.word 77
.word INSTR3
INSTR2:
.word 0
.word FIN
INSTR3:
.word 2
.word 15
.word FIN
FIN:
.word 3



/********************* Program Codes **********************/

/*********** Register Use *************
 * r8 pointer to memory
 * r0 stores 0
 * r9 stores 1
 * r10 stores 2
 * r11 stores 3
 * r12 accumulator
 * r13 current operand or instruction
***************************************/

.section .text
.global main

main:
	movia	r12, 0x0			/* clear accumulator */
	movia	r9, 0x1				/* load constants */
	movia	r10, 0x2
	movia	r11, 0x3
	movia	r8, START			/* load the address of the first instruction */

SELECT:
	ldw		r13, 0(r8)			/* load the first instruction */
	beq		r13, r0, CLEAR		/* branch to corresponding block */
	beq		r13, r9, ADD		
	beq		r13, r10, SUB
	beq		r13, r11, EXIT
	br		ERROR

CLEAR:
	movia	r12, 0x0
	br FIND_NEXT

ADD:
	addi	r8, r8, 0x4
	ldw		r13, 0(r8)
	add		r12, r12, r13
	br FIND_NEXT
	
SUB:
	addi	r8, r8, 0x4
	ldw		r13, 0(r8)
	sub		r12, r12, r13
	br FIND_NEXT

/* load next instruction to r8 */	
FIND_NEXT:
	addi	r8, r8, 0x4			/* load the address of the address of the next instruction */
	ldw		r8, 0(r8)			/* load the address of the next instruction */
	br		SELECT

ERROR:
	movia	r12, 0xFFFFFFFF

/* infinite loop that retains the value in accumulator */
EXIT:
	add		r12, r12, r0
	br		EXIT





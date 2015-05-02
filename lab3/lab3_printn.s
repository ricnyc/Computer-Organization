.global printn
printn:
	addi	sp, sp, -20
	stw		ra, 0(sp)
	stw		r4, 4(sp)
	stw		r5, 8(sp)
	stw		r6, 12(sp)
	stw		r7, 16(sp)
	add		r16, r0, r4
	addi	r17, sp, 8

compare:	
	ldb		r8, 0(r16)
	movia	r9, 'd'
	beq		r8, r9, dec
	movia	r9, 'o'
	beq		r8, r9, oct
	movia	r9, 'h'
	beq		r8, r9, hex
	br		stop_it
	
dec:
	ldw		r4, 0(r17)
	call	printDec
	addi	r16, r16, 1
	addi	r17, r17, 4
	br		compare
	
oct:
	ldw		r4, 0(r17)
	call	printOct
	addi	r16, r16, 1
	addi	r17, r17, 4
	br		compare

hex:
	ldw		r4, 0(r17)
	call	printHex
	addi	r16, r16, 1
	addi	r17, r17, 4
	br		compare
	
stop_it:
	ldw		ra, 0(sp)
	addi	sp, sp, 20
	ret
	

	
	
	
	
	
	
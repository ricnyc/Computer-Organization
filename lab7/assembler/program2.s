; this is a sample program that demonstrates
; all possible instructions

; Create constant 3A = 1D*2
		ori		$1d
		shiftl	k1,1

		add		k2,k1
		add		k3,k2
		add		k0,k2
		sub		k1,k2
		ori		$15
lbl1		nand		k0,k1
		shiftl	k0,1
		shiftr	k3,2
		store		k1,(k2)
		load		k0,(k2)
		bz		lbl2
		bnz		lbl1

lbl2		org		15


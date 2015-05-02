 db %00011010 ;jal 1: k1 = PC + 1 = 1, PC = PC + 1 + IMM = 2, you can see this as a function call to foo
 add k1,k1 ;k1 = 2, we are skipping this instruction here to execute foo, we'll come back 
foo sub k3,k3 ;k3 = 0, subroutine foo, first save k1 (return address) into k3
 add k3,k1 ;k3 = 1
 sub k1,k1 ;k1 = 0
 ori 14 ;k1 = 14
 store k3,(k1) ; Mem[14] = 1, test if store still works
 sub k2,k2 ;k2 = 0, test if nand still works
 nand k2,k2 ;k2 = 255
 db %10011110 ;ldind k2,(k1), k2 = Mem[Mem[14]] = Mem[1] = 01010100
 sub k1,k1 ;k1 = 0
 add k1,k3 ;k1 = 1, restore k1
 db %01000001 ;foo jr k1, return to addr 1
 db %10101010 ;not used
 db %11111111 ;this is where we write to, and where ldind takes the first read from

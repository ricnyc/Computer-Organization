 sub k1,k1 ;k1=0
 ori 3 ;k1 =3
 db %10011110 ;ldind k2,((k1)), k2 = Mem[Mem[k1]] = Mem[Mem[3]] = Mem[4] = 0x0f
 db %00000100 ;read first by ldind above
 db %00001111 ;read second by ldind above

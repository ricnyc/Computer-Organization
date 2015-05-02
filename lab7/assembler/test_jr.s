 sub k1,k1 ;k1 = 0
 ori 4 ;k1 = 4
 db %01000001 ;jr k1: PC = k1 = 4
 sub k1,k1 ;this one will be skipped
 add k1,k1 ;k1=8

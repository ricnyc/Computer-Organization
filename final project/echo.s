.equ ADDR_AUDIODACFIFO, 0x10003040
.section .text
.global main
main:
  movia r2,ADDR_AUDIODACFIFO
  ldwio r3,4(r2)      /* Read fifospace register */
  andi  r3,r3,0xff    /* Extract # of samples in Input Right Channel FIFO */
  beq   r3,r0,main  /* If no samples in FIFO, go back to start */
  ldwio r3,8(r2)
  stwio r3,8(r2)      /* Echo to left channel */
  ldwio r3,12(r2)
  stwio r3,12(r2)     /* Echo to right channel */
  br main
 
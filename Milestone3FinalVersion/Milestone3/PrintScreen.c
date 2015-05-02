/* set a single pixel on the screen at x,y
 * x in [0,319], y in [0,239], and colour in [0,65535]
 */
void write_pixel(int x, int y, short colour) {
  volatile short *vga_addr=(volatile short*)(0x08000000 + (y<<10) + (x<<1));
  *vga_addr=colour;
}

/* use write_pixel to set entire screen to black (does not clear the character buffer) */
void clear_screen() {
  int x, y;
  for (x = 0; x < 320; x++) {
    for (y = 0; y < 240; y++) {
	  write_pixel(x,y,0);
	}
  }
}

/* write a single character to the character buffer at x,y
 * x in [0,79], y in [0,59]
 */
void write_char(int x, int y, char c) {
  // VGA character buffer
  volatile char * character_buffer = (char *) (0x09000000 + (y<<7) + x);
  *character_buffer = c;
}

int PrintScreen () {

   clear_screen();
   int x;
/*
   for (x=0;x<320;x++)
   {
      // Draw a straight line in red across the screen centre
      write_pixel(x, 59, 0xf800);
      // Draw a "diagonal" line in green
      if (x<240)
         write_pixel(x, x, 0x07e0);
   }
*/
   // Write Hello, world!
   char* hw = "Airplane has been launched!";
   x = 10;
   while (*hw) {
     write_char(x, 25, *hw);
	 x++;
	 x++;
	 hw++;
   }
   return 0;
}

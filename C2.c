

unsigned get_uptime(unsigned seconds_elapsed);
unsigned hex_decoder(unsigned digit);


unsigned get_uptime(unsigned seconds_elapsed) {
	unsigned hex3, hex2, hex1, hex0;
	unsigned minutes_elapsed;
	minutes_elapsed = seconds_elapsed / 60;
	seconds_elapsed = seconds_elapsed % 60;
	hex3 = minutes_elapsed / 10;
	hex2 = minutes_elapsed % 10;
	hex1 = seconds_elapsed / 10;
	hex0 = seconds_elapsed % 10;
	hex3 = hex_decoder(hex3);
	hex2 = hex_decoder(hex2);
	hex1 = hex_decoder(hex1);
	hex0 = hex_decoder(hex0);
	return (hex0 + hex1 * 256u + hex2 * 65536u + hex3 * 16777216u);

}

unsigned hex_decoder(unsigned digit) {
	unsigned hex;
	switch(digit) {
		case 0:
			hex = 0x3F;
			break;
		case 1:
			hex = 0x6;
			break;
		case 2:
			hex = 0x5B;
			break;
		case 3:
			hex = 0x4F;
			break;
		case 4:
			hex = 0x66;
			break;
		case 5:
			hex = 0x6D;
			break;
		case 6:
			hex = 0x7D;
			break;
		case 7:
			hex = 0x7;
			break;
		case 8:
			hex = 0x7F;
			break;
		case 9:
			hex = 0x6F;
			break;
		default:
			hex = 0x0;
			break;
	}
	return hex;
}


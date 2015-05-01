#define COL_TOP_L 36
#define COL_BOT_L 88
#define COL_TOP_R 151
#define COL_BOT_R 203
#define VU_SCALE 6710887
#define BACKGROUND -1
#define VU_COLOR 0

int is_VU_background_n(int x, int y, int peak_prev_L, int peak_prev_R) {
	if ((y >= COL_TOP_L && y <= COL_BOT_L && x < peak_prev_L) || (y >= COL_TOP_R && y <= COL_BOT_R && x < peak_prev_R))
		return VU_COLOR;
	return BACKGROUND;
}

#define GAME_NAME "GOALRILLA"
#define GAME_VERSION 			0.06
#define SCR_W 					640
#define SCR_H 					480
#define SECTIONS 				80
#define TERRAIN_WIDTH 			SCR_W
#define SECTION_W 				TERRAIN_WIDTH \ SECTIONS
#define SCR_TOP_MARGIN 			100
#define SCR_BOTTOM_MARGIN 		SCR_H - 100
'colors
#define C_BLACK 	&h000000
#define C_WHITE 	&hFFFFFF
#define C_GRAY 		&h7F7F7F
#define C_RED 		&hFF0000
#define C_BLUE 		&h0000FF
#define C_GREEN 	&h00FF00
#define C_YELLOW 	&hFFFF00
#define C_CYAN 		&h00FFFF
#define C_LILIAC 	&h7F00FF
#define C_ORANGE 	&hFF7F00
#define C_PURPLE 	&h7F007F
#define C_DARK_RED 	&h7F0000
#define C_DARK_GREEN &h007F00
#define C_DARK_BLUE &h00007F

const BMP_TILE_W as integer = 32
const BMP_TILE_H as integer = 32
const BMP_TILE_COLS as integer = SCR_W \ BMP_TILE_W
const BMP_TILE_ROWS	as integer = SCR_H \ BMP_TILE_H
const BMP_TILE_TOT as integer = BMP_TILE_COLS * BMP_TILE_ROWS

const PI as single = 3.14159f

const GRAVITY_ACCEL as single 	= 9.80665f
const GRAVITY 		as single 	= 0.980665f
'friction of the air
const AIR_FRICTION 	as single = 0.995
'maximum speed the ball can reach so it doesn't become a ball flame
const BALL_MAX_SPEED as single = 25.0f 
'minimum speed of the ball
const BALL_MIN_SPEED as Single 	= 0.01f
'player moving speed
const PL_MOVING_SPEED as integer = 5




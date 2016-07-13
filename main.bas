' Compiling instructions: fbc -w all -exx "%f"
' use 1.04 freebasic compiler

#include "fbgfx.bi"

Using FB
Randomize Timer()

'__MACROS_______________________________________________________________
'calculate angle between two points
#macro _abtp (x1,y1,x2,y2)
    -Atan2(y2-y1,x2-x1)
#endmacro

#include "enums.bi"
#include "types.bas"
#include "define_and_consts.bas"
#include "subs.bas"

		
'initialize Types
Dim Ball 							as ball_proto
Dim Ball_Record(0 to 24) 			as ball_proto
dim ball_record_slot				as integer
dim ball_sprite(0 to 4) 			as Uinteger ptr
dim big_numbers (0 to 9) 			as Uinteger ptr
dim clouds(0 to 20) 				as generic_item_proto
dim Debug_mode 						as boolean = false
Dim pl(0 to 19)	 					as player_proto
dim pl_sel 							as integer = 0
dim pl_sprite_0(0 to 31) 			as Uinteger ptr
dim pl_sprite_1(0 to 31)			as Uinteger ptr
Dim User_Mouse 						as mouse
dim particles(0 to 9) 				as ball_proto
Dim turn 							as integer = 0
dim terrain_sprite (0 to 15) 		as Uinteger ptr
dim status_sprite(0 to 2) 			as Uinteger ptr
dim turn_timing						as single
Dim Terrain_line(0 to SECTIONS-1) 	as Terrain
dim game_section 					as proto_game_section
dim camera							as camera_proto
dim c as integer

DIM SHARED Workpage 				AS INTEGER

'init some vars
camera.x = 0
camera.x_offset = 0
camera.y = 0 
camera.speed = 0
camera.obj = player
game_section = splashscreen
ball_record_slot = 0
ball.is_active = false

for c = 0 to Ubound(clouds)
	clouds(c).x = rnd * TERRAIN_WIDTH
	clouds(c).y = -(rnd * 300)
	clouds(c).w = rnd * 20
next c

screenres SCR_W, SCR_H, 24
'hides the mouse
SetMouse 320, 240, 0

load_bmp (ball_sprite(), 80, 16, 5, 1,"img\ball_sprites.bmp")
load_bmp (pl_sprite_0(), 84, 200, 4, 8,"img\pl_sprites_0.bmp")
load_bmp (pl_sprite_1(), 84, 200, 4, 8,"img\pl_sprites_1.bmp")
load_bmp (status_sprite(), 78, 32, 3, 1,"img\status_sprite.bmp")
load_bmp (terrain_sprite(), 128, 128, 4, 4,"img\terrain.bmp")
load_bmp (big_numbers(), 280, 32, 10, 1,"img\numbers.bmp")

dim e As EVENT
DO
	If (ScreenEvent(@e)) Then
		Select Case e.type
			Case EVENT_KEY_RELEASE
				If (e.scancode = SC_D) Then
					Debug_mode = not Debug_mode
				End If
		End Select
	End If
	
	if MULTIKEY (SC_Escape) then exit do

	screenlock ' Lock the screen
	screenset workpage, workpage xor 1 ' Swap work pages.
	cls
	
	select case game_section
		case splashscreen
			if Multikey(SC_ENTER) then game_section = terrain_generation
			draw string (20,20), GAME_NAME + " " + str(GAME_VERSION)
			draw string (20,40), "Use mouse wheel to change selected player", C_GRAY
			draw string (20,50), "Right click to move player", C_GRAY
			draw string (20,60), "Left click to kick ball", C_GRAY
			draw string (20,SCR_H - 50 + 50 * cos(Timer * 2)), "Press Enter to start", C_RED
		case terrain_generation
			' INITIALIZE GROUND PROFILE
			init_ground(Terrain_line())
			'init pl positions
			init_pl_positions(pl(), Terrain_line())
			turn_timing = Timer
			game_section = game
		case game
			'check if a team has win____________________________________
			if count_alive(pl(), 0) = 0 or count_alive(pl(), 1) = 0 then
				game_section = splashscreen
			end if
			'change turn every ten seconds______________________________
			update_turn_change (@turn_timing, @turn, pl(), @pl_sel)
			'update camera position
			update_camera (	camera, ball, pl(), pl_sel)
			'draws the profile of the terrain
			draw_background(Terrain_line(), camera)
			'update particles position
			update_players (pl(), camera, Terrain_line())
			'if active update particles position
			update_particles(particles())
			
			if point(Ball.x - camera.x_offset, Ball.y - camera.y_offset) <> C_BLUE then
				if Ball.is_active then
					check_ball_collisions(Ball, Terrain_line(), pl())
					'initialize the position of the particles
					init_particles(Ball.x, Ball.y, particles())
					Ball.is_active = false	
				end if
			else
				update_ball (@Ball)
				record_ball_position(Ball_Record(),Ball, @ball_record_slot)
			end if
			
			'get user input
			get_mouse (Ball, User_Mouse, @pl_sel, pl(), @turn, @turn_timing, Ball_Record(), camera)
			'draw the trajectory of the ball____________________________
			if Ball.is_active then
				draw_trajectory(Ball_Record(), ball_record_slot, camera)
			end if
			'draw the preview of the launch of the ball
			if Ball.is_active = false and pl(pl_sel).is_alive then
				draw_trajectory_preview(pl(), pl_sel, User_Mouse, camera)
			end if
			'draws mouse direction
			draw_arrow	(pl(pl_sel).x - camera.x_offset, pl(pl_sel).y - camera.y_offset, _
						_abtp ((pl(pl_sel).x - camera.x_offset), _
						(pl(pl_sel).y- camera.y_offset), _
						User_Mouse.x , User_Mouse.y ), 50, C_RED)
			'draw particles if the bal hit the terrain		
			draw_particles(particles(), camera)
			'draw players
			draw_players(ball, pl(), pl_sel, pl_sprite_0(), pl_sprite_1(), camera)
			'draws the ball
			draw_ball(Ball, Ball_sprite(), camera)
			
			'draw clouds
			draw_clouds(clouds(), camera)
			'draw players icons on bottom of the screen and also turn timing
			draw_player_stats (pl(), pl_sel, turn, status_sprite(), turn_timing)
		
			'draw mouse
			draw_mouse_pointer(User_Mouse)

			'draw debug info by pressing run-time D Key
			if (Debug_mode) then
				draw_debug (Ball, pl(), pl_sel, User_Mouse, Terrain_line(), @turn, turn_timing, camera)
			end if
	
	end select
		
	workpage xor = 1 ' Swap work pages.
	screensync
	screenunlock
	sleep 20,1
LOOP

for c = 0 to Ubound(pl_sprite_0)
	ImageDestroy pl_sprite_0(c)
	ImageDestroy pl_sprite_1(c)
next c

for c = 0 to Ubound(Ball_sprite)
	ImageDestroy Ball_sprite(c)
next c

for c = 0 to Ubound(status_sprite)
	ImageDestroy status_sprite(c)
next c

for c = 0 to Ubound(terrain_sprite)
	ImageDestroy terrain_sprite(c)
next c


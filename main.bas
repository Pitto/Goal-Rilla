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
Dim Terrain_line(0 to SECTIONS-1) 	as Terrain
Dim Ball 							as ball_proto
dim particles(0 to 9) 				as ball_proto
dim clouds(0 to 20) 					as generic_item_proto
Dim Ball_Record(0 to 24) 			as ball_proto
dim ball_record_slot				as integer
Dim pl(0 to 19)	 					as player_proto
Dim User_Mouse 						as mouse
dim pl_sel 							as integer = 0
Dim turn 							as integer = 0
dim Debug_mode 						as boolean = false
dim ball_sprite(0 to 4) 			as Uinteger ptr
dim pl_sprite_0(0 to 31) 			as Uinteger ptr
dim pl_sprite_1(0 to 31)			as Uinteger ptr
dim status_sprite(0 to 2) 			as Uinteger ptr
dim terrain_sprite (0 to 15) 		as Uinteger ptr
dim big_numbers (0 to 9) 			as Uinteger ptr
dim turn_timing						as single
dim game_section 					as proto_game_section
dim camera							as camera_proto
dim c as integer

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


DIM SHARED Workpage 				AS INTEGER


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
				If (e.scancode = SC_Escape) Then
					Exit do
				End If
				If (e.scancode = SC_D) Then
					Debug_mode = not Debug_mode
				End If
		End Select
	End If

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
			if Timer - turn_timing > MAX_TURN_TIMING_SECS then
				turn = 1 - turn
				turn_timing = Timer
				'find first alive player from other team
				for c = turn to Ubound(pl) step 2
					if pl(c).is_alive then
						pl_sel = c
						exit for
					end if
				next c
			end if


	if ball.is_active then
		camera.speed = d_b_t_p(camera.x, camera.y, ball.x, ball.y) / 25
		camera.x += cos(_abtp(camera.x, camera.y, ball.x, ball.y))*camera.speed 
		camera.y += -sin(_abtp(camera.x, camera.y, ball.x, ball.y))*camera.speed 
    else
		camera.speed = d_b_t_p(camera.x, camera.y, pl(pl_sel).x, pl(pl_sel).y) / 25
		camera.x += cos(_abtp(camera.x, camera.y, pl(pl_sel).x, pl(pl_sel).y))*camera.speed 
		camera.y += -sin(_abtp(camera.x, camera.y, pl(pl_sel).x, pl(pl_sel).y))*camera.speed 
    end if
    
        'padding & border limit check
    if (camera.x < 0 + SCR_W\2) then
        camera.x = 0 + SCR_W\2
    end if
    if (camera.x > TERRAIN_WIDTH - SCR_W\2) then
        camera.x = TERRAIN_WIDTH - SCR_W\2
    end if
    
    if (camera.y < -SCR_H\2 + 150) then
        camera.y = -SCR_H\2 + 150
    end if
    if (camera.y > SCR_H\2) then
        camera.y = SCR_H\2
    end if
    
    camera.x_offset = camera.x - SCR_W\2
    camera.y_offset = camera.y - SCR_H\2

			draw_background(Terrain_line(), camera)

			dim t as integer
			t = get_nrst_node(ball.x, ball.y, Terrain_line())
			
			update_players (pl(), camera, Terrain_line())
			'update particles position
			update_particles(particles())
			
			if point(Ball.x - camera.x_offset, Ball.y - camera.y_offset) <> C_BLUE then
				if Ball.is_active then
					'modify the ground profile when the ball impacts
					Terrain_line(t).y += 16
					if t < Ubound(Terrain_line) and t > 0 then
						terrain_line(t-1).y +=8
						terrain_line(t+1).y +=8
					end if
					'initialize the position of the particles
					init_particles(Ball.x, Ball.y, particles())
					'check collision of the ball with each player
					for c = 0 to Ubound(pl)
						'skip the players without power
						if pl(c).is_alive = false then continue for
						if (d_b_t_p(Ball.x, Ball.y,pl(c).x, pl(c).y) < 30) then
							'the player hitted lose some power
							pl(c).power -= int(60 - d_b_t_p(Ball.x, Ball.y,pl(c).x, pl(c).y))
							if pl(c).power < 1 then pl(c).is_alive = false
							pl(c).speed = rnd*5 + 5
							pl(c).rds = PI/2 + rnd(PI/4) - PI/8
							pl(c).y +=10
						end if
					next c
					Ball.is_active = false
					
				end if
			else
				update_ball (@Ball)
				'record ball position___________________________________
				Ball_Record(ball_record_slot).x = ball.x
				Ball_Record(ball_record_slot).y = ball.y
				ball_record_slot +=1
				if ball_record_slot > Ubound (Ball_Record) then 
					ball_record_slot = 0
				end if			
				'_______________________________________________________
				
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
			for c = 0 to Ubound(clouds)
				circle (clouds(c).x - camera.x_offset, _
						clouds(c).y - camera.y_offset),  clouds(c).w, c_WHITE,,,0.5,F
				circle (clouds(c).x - (c mod 3) * 3 - camera.x_offset, _
						clouds(c).y - (c mod 3) * 5 - camera.y_offset),  clouds(c).w*2, c_WHITE,,,0.3,F
			next c
			
			'___________________________________________________________
			draw_player_stats (pl(), pl_sel, turn, status_sprite())
			
			'highlight turn___________________________________________
			
			if turn then
				line (SCR_W\2 - 16, 20)-(SCR_W\2 + 16, 42), C_RED, BF
			else
				line (SCR_W\2 - 16, 20)-(SCR_W\2 + 16, 42), C_YELLOW,BF
			end if
			draw string (SCR_W\2 - 8, 10), str(MAX_TURN_TIMING_SECS - int(Timer - turn_timing))
			'________________________
			
			'draw mouse
			
			line (User_Mouse.x - 5, User_Mouse.y)- (User_Mouse.x +5, User_Mouse.y)
			line (User_Mouse.x, User_Mouse.y +5)- (User_Mouse.x, User_Mouse.y - 5)
			
			
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


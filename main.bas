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

#include "types.bas"
#include "define_and_consts.bas"
#include "subs.bas"
#include "enums.bi"
		
'initialize Types
Dim Terrain_line(0 to SECTIONS-1) 	as Terrain
Dim Ball 							as ball_proto
dim particles(0 to 9) 				as ball_proto
Dim Ball_Record(0 to 20) 			as ball_proto
Dim pl(0 to 9) 						as player_proto
Dim User_Mouse 						as mouse
dim pl_sel 							as integer = 0
Dim turn 							as integer = 0
dim Debug_mode 						as boolean = false
dim ball_sprite(0 to 4) 			as Uinteger ptr
dim pl_sprite_0(0 to 31) 			as Uinteger ptr
dim pl_sprite_1(0 to 31)			as Uinteger ptr
dim status_sprite(0 to 2) 			as Uinteger ptr
dim terrain_sprite (0 to 15) 		as Uinteger ptr
dim game_section 					as proto_game_section
game_section = splashscreen
DIM SHARED Workpage 				AS INTEGER

dim c as integer
screenres SCR_W, SCR_H, 24

load_bmp (ball_sprite(), 80, 16, 5, 1,"img\ball_sprites.bmp")
load_bmp (pl_sprite_0(), 84, 200, 4, 8,"img\pl_sprites_0.bmp")
load_bmp (pl_sprite_1(), 84, 200, 4, 8,"img\pl_sprites_1.bmp")
load_bmp (status_sprite(), 78, 32, 3, 1,"img\status_sprite.bmp")
load_bmp (terrain_sprite(), 128, 128, 4, 4,"img\terrain.bmp")

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
			draw string (20,30), "Press Enter to start"
		case terrain_generation
			' INITIALIZE GROUND PROFILE
			init_ground(Terrain_line())
			'init pl positions
			init_pl_positions(pl(), Terrain_line())
			game_section = game
		case game
			draw_background(Terrain_line())
			
			'for c = 0 to BMP_TILE_TOT - 1
	
				'draw string ((c mod BMP_TILE_COLS) * BMP_TILE_W, _
				'			(c \ BMP_TILE_COLS) * BMP_TILE_H + 10), _
				'			str(get_terrain_tile (c, 5))
							
				'draw string ((c mod BMP_TILE_COLS) * BMP_TILE_W, _
				'			(c \ BMP_TILE_COLS) * BMP_TILE_H), _
				'			str (c)
							
				'put ((c mod BMP_TILE_COLS) * BMP_TILE_W, _
				'			(c \ BMP_TILE_COLS) * BMP_TILE_H), terrain_sprite(get_terrain_tile (c, 5)), trans
							
			
				'line (		(c mod BMP_TILE_COLS) * BMP_TILE_W, _
				'			(c \ BMP_TILE_COLS) * BMP_TILE_H)- _
				'			((c mod BMP_TILE_COLS) * BMP_TILE_W + BMP_TILE_W, _
				'			(c \ BMP_TILE_COLS) * BMP_TILE_H + BMP_TILE_H ), C_BLACK, B
			'next c
			
			
			
			
			dim t as integer
			t = get_nrst_node(@Ball, Terrain_line())
			
			update_players (pl())
			'update particles position
			update_particles(particles())
			
			if point(Ball.x, Ball.y) <> C_BLUE and Ball.y > 1 then
				if Ball.is_active then
					'modify the ground profile
					Terrain_line(t).y += 16
				
					init_particles(Ball.x, Ball.y, particles())
					'check collision of the ball with each player
					for c = 0 to Ubound(pl)
						'skip the players without power
						if pl(c).is_alive = false then continue for
						if (d_b_t_p(Ball.x, Ball.y,pl(c).x, pl(c).y) < 30) then
							'the player hitted lose some power
							pl(c).power -= int(60 - d_b_t_p(Ball.x, Ball.y,pl(c).x, pl(c).y))
							if pl(c).power < 1 then pl(c).is_alive = false
							pl(c).speed = rnd*5 + 12
							pl(c).rds = PI/2 + rnd(PI/4) - PI/8
							pl(c).y +=10
						end if
					next c
					Ball.is_active = false
				end if
			else
				update_ball (@Ball)
			end if
			
			'get user input
			get_mouse (Ball, User_Mouse, @pl_sel, pl(), @turn)
			
			
			
			draw_particles(particles())
			'draw players
			draw_players(ball, pl(), pl_sel, pl_sprite_0(), pl_sprite_1())
			draw_ball(Ball, Ball_sprite())
			draw_player_stats (pl(), pl_sel, turn, status_sprite())
			

			
			'draw debug info by pressing run-time D Key
			if (Debug_mode) then
				draw_debug (Ball, pl(), pl_sel, User_Mouse, Terrain_line(), @turn)
				

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

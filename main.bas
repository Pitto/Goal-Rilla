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
		
'initialize Types
Dim Terrain_line(0 to SECTIONS-1) as Terrain
Dim Ball as ball_proto
Dim Ball_Record(0 to 20) as ball_proto

Dim pl(0 to 9) as player_proto
Dim User_Mouse as mouse
dim pl_sel as integer = 0
Dim turn as integer = 0

DIM SHARED Workpage AS INTEGER 

dim c as integer

' INITIALIZE GROUND PROFILE
init_ground(Terrain_line())

'init pl positions
init_pl_positions(pl(), Terrain_line())

screenres SCR_W, SCR_H, 24
dim e As EVENT
DO
	If (ScreenEvent(@e)) Then
		Select Case e.type
			Case EVENT_KEY_RELEASE
				If (e.scancode = SC_Escape) Then
					Exit do
				End If
		End Select
	End If

	screenlock ' Lock the screen
	screenset workpage, workpage xor 1 ' Swap work pages.
	cls
	
	draw_background(Terrain_line())
	
	dim t as integer
	t = get_nrst_node(@Ball, Terrain_line())
	
	update_players (pl())
	
	if point(Ball.x, Ball.y) <> C_BLUE and Ball.y > 1 then
		if Ball.is_active then
			'modify the ground profile
			Terrain_line(t).x -= cos(Ball.rds) * (Ball.speed + GRAVITY_ACCEL) * 0.7
			Terrain_line(t).y -= -sin(Ball.rds) * (Ball.speed + GRAVITY_ACCEL) * 0.5
			Terrain_line(t+1).x -= cos(Ball.rds) * (Ball.speed + GRAVITY_ACCEL) * 0.2
			Terrain_line(t+1).y -= -sin(Ball.rds) * (Ball.speed + GRAVITY_ACCEL) * 0.2
			Terrain_line(t-1).x -= cos(Ball.rds) * (Ball.speed + GRAVITY_ACCEL) * 0.2
			Terrain_line(t-1).y -= -sin(Ball.rds) * (Ball.speed + GRAVITY_ACCEL) * 0.2
			'check collision of the ball with each player
			for c = 0 to Ubound(pl)
				'skip the players without power
				if pl(c).is_alive = false then continue for
				if (d_b_t_p(Ball.x, Ball.y,pl(c).x, pl(c).y) < 30) then
					'the player hitted lose some power
					pl(c).power -= int(30 - d_b_t_p(Ball.x, Ball.y,pl(c).x, pl(c).y))
					if pl(c).power < 1 then pl(c).is_alive = false
					pl(c).speed = rnd*4 + 4
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
	
	'draw players
	draw_players(pl(), pl_sel)
	draw_ball(Ball)
	draw_player_stats (pl(), pl_sel, turn)
	draw_debug (Ball, pl(), pl_sel, User_Mouse, Terrain_line(), @turn)
	
	workpage xor = 1 ' Swap work pages.
	screensync
	screenunlock
	sleep 20,1
LOOP

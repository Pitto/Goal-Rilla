declare function d_b_t_p (x1 as single, y1 as single, x2 as single, y2 as single) as single
'gives values in the range -1...1
declare function get_diff_angle(alfa as single, beta as single) as single

'__________________________________________________________________
declare sub draw_arrow(x as single, y as single, rds as single, a_l as single, cl as Uinteger)
'initialize the ground profile
declare sub init_terrain_line(	x as single, y as single, rds as single, _
								a_l as single, coords as Terrain ptr)
								
declare sub update_ball (coords as ball_proto ptr)
declare sub init_pl_positions(pl() as player_proto, terrain_line() as terrain)
declare sub draw_background(Terrain_line() as Terrain, camera as camera_proto)
declare sub draw_players(	ball as ball_proto, pl() as player_proto, _
							pl_sel as integer, sprite_t0() as Uinteger ptr, _
							sprite_t1() as Uinteger ptr, camera as camera_proto)
declare sub draw_ball(Ball as ball_proto, ball_sprite() as Uinteger ptr, camera as camera_proto)
declare sub draw_trajectory_preview(pl() as player_proto, pl_sel as integer, User_Mouse as mouse,  camera as camera_proto)
'draws a bar scale
declare sub draw_horz_scale	   (x as integer, y as integer, _
								w as integer, h as integer, _
								v as integer, mv as integer, _
								s_color as Uinteger)
declare sub get_mouse (	Ball as ball_proto, User_Mouse as mouse, _
						pl_sel as integer ptr, pl() as player_proto, _
						turn as integer ptr, turn_timing as single ptr, _
						Ball_Record() as ball_proto, camera as camera_proto)
'prints on screen useful info for debug
declare sub draw_debug (Ball as ball_proto, pl() as player_proto, pl_sel as integer, _
				User_Mouse as mouse, Terrain_line() as Terrain, _
				turn as integer ptr, turn_timing as single, _
				camera as camera_proto)
				
declare sub draw_player_stats (pl() as player_proto, pl_sel as integer, turn as integer, status_sprite() as Uinteger ptr, turn_timing as single)

declare sub load_bmp ( bmp() as Uinteger ptr, w as integer, h as integer, _
					   cols as integer, rows as integer, Byref bmp_path as string)

declare function count_alive(pl() as player_proto, n_team as integer) as integer
declare function start_frame (rds as single) as integer

declare sub reset_ball_recording(Ball_Record() as ball_proto, x as single, y as single)

declare sub	update_turn_change (	turn_timing as single ptr, turn as integer ptr, _
							pl() as player_proto, pl_sel as integer ptr)

function get_diff_angle(alfa as single, beta as single) as single
    if alfa <> beta  then
        return _abtp(0,0,cos(alfa-beta),-sin(alfa-beta))
	else
		return 0
	end if
end function

function d_b_t_p (x1 as single, y1 as single, x2 as single, y2 as single) as single
    return Sqr(((x1-x2)*(x1-x2))+((y1-y2)*(y1-y2)))
end function

sub init_terrain_line(	x as single, y as single, rds as single, _
				a_l as single, coords as Terrain ptr)
	coords->x = x + a_l * cos(rds)
	coords->y = y + a_l * -sin(rds)
end sub

sub update_ball (coords as ball_proto ptr)
	coords->old_x = coords->x
	coords->old_y = coords->y
	coords->x += coords->speed * cos(coords->rds)
	coords->y += coords->speed * -sin(coords->rds) + GRAVITY_ACCEL
	coords->speed *= GRAVITY
end sub

sub draw_arrow(x as single, y as single, rds as single, a_l as single, cl as Uinteger)
    line (x, y)-(x + a_l * cos(rds), y + a_l *  -sin(rds)),cl
    line (x + a_l * cos(rds), y + a_l *  -sin(rds))-(x + (a_l-10) * cos(rds-0.5), y + (a_l-10) *  -sin(rds-0.5)),cl
    line (x + a_l * cos(rds), y + a_l *  -sin(rds))-(x + (a_l-10) * cos(rds+0.5), y + (a_l-10) *  -sin(rds+0.5)),cl
end sub

function get_nrst_node(x as single, y as single, tc() as Terrain) as Integer
    dim max_dist as integer = 1000
    dim as Integer c, id
    for c = 2 to Ubound(tc)-2
        if d_b_t_p(x, y,tc(c).x,tc(c).y) < max_dist then
			max_dist = d_b_t_p(x, y,tc(c).x,tc(c).y)
			id = c
		end if
    next c
    return id
end function

sub update_players(pl() as player_proto, camera as camera_proto, terrain_line() as Terrain)
	dim c as integer
	for c = 0 to Ubound(pl)
		pl(c).old_x = pl(c).x
		pl(c).old_y = pl(c).y
		
		if pl(c).y < terrain_line(get_nrst_node(pl(c).x, pl(c).y, terrain_line())).y then
			pl(c).y += 3
		else
			pl(c).y =  terrain_line(get_nrst_node(pl(c).x, pl(c).y, terrain_line())).y
		end if
		
		'if point(pl(c).x - pl(c).w\2 - camera.x_offset, pl(c).y + pl(c).h + 3 - camera.y_offset) = C_BLUE then	
			'pl(c).y +=2
			'pl(c).speed *= GRAVITY
		'end if
		if pl(c).speed > 1 then
			pl(c).x += pl(c).speed*cos(pl(c).rds)
			pl(c).y += pl(c).speed*-sin(pl(c).rds)
			pl(c).speed *= GRAVITY
			'bound check
			if pl(c).x + pl(c).w > TERRAIN_WIDTH then
				pl(c).x = TERRAIN_WIDTH - pl(c).w - 10
				pl(c).rds = pl(c).rds + PI_HALF
			end if
			if pl(c).x < 0 then
				pl(c).x = 10
				pl(c).rds = pl(c).rds + PI_HALF
			end if
		else
			pl(c).speed = 0
		end if
	next c
end sub

sub init_pl_positions(pl() as player_proto, Terrain_line() as Terrain)
	dim c as integer
	dim p as integer
	for c = 0 to Ubound(pl)
		p = rnd * int(Ubound(Terrain_line)-2)+1
		pl(c).x = Terrain_line(p).x
		pl(c).y = Terrain_line(p).y - pl(c).h - 50
		pl(c).team = c MOD 2
		pl(c).w = 8
		pl(c).h = 12 
		pl(c).power = 99
		pl(c).is_alive = true
		pl(c).has_moved = false
	next c
end sub

sub init_ground (Terrain_line() as Terrain)
	dim c as integer
	dim as single angle, length, sct_length
	
	sct_length = SECTION_W
		
	Terrain_line(0).x = -5
	Terrain_line(0).y = SCR_H \2

	for c = 0 to Ubound(Terrain_line)
		'if c mod 20 = 0 then
		angle = rnd *(PI*0.8)-PI*0.4
		
		length = sct_length / cos(angle)
		
		'top and bottom screen margin check, dont'allow the profile to
		'go outside the specified area
		if Terrain_line(c).y + sct_length * -sin(angle) < SCR_TOP_MARGIN then
			angle = -angle
		end if
		if Terrain_line(c).y + sct_length * -sin(angle) > SCR_BOTTOM_MARGIN then
			angle = -angle
		end if
		
		if c < Ubound(Terrain_line) - 1 then
			init_terrain_line(	Terrain_line(c).x, Terrain_line(c).y, _
								angle, length, @Terrain_line(c+1))
		else
			Terrain_line(SECTIONS-1).x = TERRAIN_WIDTH
			Terrain_line(SECTIONS-1).y = SCR_TOP_MARGIN
		end if
	next c
end sub

sub draw_background(Terrain_line() as Terrain, camera as camera_proto)
	dim c as integer
	dim temp_color as Uinteger
	line(0,0)-(SCR_W, SCR_H),C_DARK_GREEN,BF
	
	
	
	'draw the ground line
	for c = 0 to Ubound(Terrain_line)
		if c < Ubound(Terrain_line) - 1 then
			if _abtp(Terrain_line(c).x, Terrain_line(c).y, Terrain_line(c+1).x, Terrain_line(c+1).y) < 0 then
				temp_color = rgb(0,160,0)
			else
				temp_color = rgb (0,120,0)
			end if
			line (Terrain_line(c).x - camera.x_offset, Terrain_line(c).y - camera.y_offset)-(Terrain_line(c +1).x - camera.x_offset, Terrain_line(c+1).y - camera.y_offset), C_BLUE
			line (Terrain_line(c).x - camera.x_offset, Terrain_line(c).y - camera.y_offset +20)-(Terrain_line(c +1).x - camera.x_offset, Terrain_line(c+1).y - camera.y_offset + 20), C_BLUE
			line (Terrain_line(c).x - camera.x_offset, Terrain_line(c).y - camera.y_offset +20)-(Terrain_line(c).x - camera.x_offset, Terrain_line(c).y - camera.y_offset), C_BLUE
			paint (Terrain_line(c).x - camera.x_offset -2, Terrain_line(c).y - camera.y_offset +10), temp_color, C_BLUE
		else
			line (Terrain_line(c-1).x - camera.x_offset, Terrain_line(c-1).y - camera.y_offset)-(Terrain_line(c).x - camera.x_offset, Terrain_line(c).y - camera.y_offset), C_BLUE
			line (Terrain_line(c-1).x - camera.x_offset, Terrain_line(c-1).y - camera.y_offset +20)-(Terrain_line(c).x - camera.x_offset, Terrain_line(c).y - camera.y_offset +20 ), C_BLUE
			
		end if
	next c
	' fill the sky
	paint (SCR_W \ 2, 2), C_BLUE, C_BLUE
	
end sub

sub draw_players(ball as ball_proto, pl() as player_proto, pl_sel as integer, sprite_t0() as Uinteger ptr, sprite_t1() as Uinteger ptr, camera as camera_proto)
	dim c as integer
	dim sprite as integer
	for c = 0 to Ubound(pl)
		if pl(c).is_alive = false then continue for
		'draws a line around the selected player
		if c = pl_sel then
	
			draw_horz_scale	   (pl(c).x - pl(c).w\2 - 2 - camera.x_offset, pl(c).y + pl(c).h + 10 - camera.y_offset, _
								20, 5, pl(c).power, 100, C_GRAY)
			
		end if
		
		sprite = start_frame (_abtp (ball.x, ball.y, pl(c).x,pl(c).y ))
		if pl(c).team = 0 then
			if pl(c).speed then
				sprite = start_frame (_abtp (pl(c).x,pl(c).y, pl(c).old_x,pl(c).old_y )) + 1
			end if
			
			put (pl(c).x - camera.x_offset - 10, pl(c).y - camera.y_offset - 5), sprite_t0(sprite), trans
		else
			if pl(c).speed then
				sprite = start_frame (_abtp (pl(c).x,pl(c).y, pl(c).old_x,pl(c).old_y )) + 1
			end if
	
			put (pl(c).x - camera.x_offset - 10, pl(c).y - camera.y_offset - 5), sprite_t1(sprite), trans
		end if
		
	next c
end sub

sub draw_ball(Ball as ball_proto, ball_sprite() as Uinteger ptr, camera as camera_proto)
	if Ball.is_active then
		put (Ball.x - 8 - camera.x_offset, Ball.y - 8 - camera.y_offset), ball_sprite(int((timer * 10) mod Ubound(ball_sprite))), trans
	end if
end sub


sub update_particles(particles() as ball_proto)
	dim c as integer
	for c = 0 to ubound(particles)
		'check screen bounds
		if 	particles(c).x > 0 and particles(c).x < TERRAIN_WIDTH _
			and particles(c).y > 0 and particles(c).y < SCR_H then
			particles(c).x += particles(c).speed * cos(particles(c).rds) 
			particles(c).y += particles(c).speed * -sin(particles(c).rds) + GRAVITY_ACCEL
			particles(c).speed *= GRAVITY
		end if
	next c
end sub

sub draw_particles(particles() as ball_proto, camera as camera_proto)
	dim c as integer
	for c = 0 to ubound(particles)
		if c mod 2 then
			Circle (particles(c).x - camera.x_offset, particles(c).y - camera.y_offset), particles(c).w, C_YELLOW,,,,F
		else
			Circle (particles(c).x - camera.x_offset, particles(c).y - camera.y_offset), particles(c).w, C_ORANGE,,,,F
		end if
	next c
end sub

sub init_particles(x as integer, y as integer, particles() as ball_proto)
	dim c as integer
	for c = 0 to ubound(particles)
		particles(c).x = x
		particles(c).y = y
		particles(c).speed = rnd*6 + 10
		particles(c).w = int (rnd*3) + 1
		particles(c).rds = PI/2 + rnd(PI/4) - PI/8
	next c
end sub

sub draw_trajectory_preview(pl() as player_proto, pl_sel as integer, User_Mouse as mouse, camera as camera_proto)
	dim as single temp_x, temp_y, temp_rds, temp_speed
	dim c as integer 
	temp_rds = _abtp((pl(pl_sel).x - camera.x_offset), (pl(pl_sel).y - camera.y_offset), _
				User_Mouse.x , User_Mouse.y)

	temp_speed = d_b_t_p(pl(pl_sel).x - camera.x_offset, pl(pl_sel).y - camera.y_offset, _
				User_Mouse.x, User_Mouse.y)/5
	if temp_speed > BALL_MAX_SPEED then temp_speed = BALL_MAX_SPEED		
	temp_x = pl(pl_sel).x - camera.x_offset
	temp_y = pl(pl_sel).y - camera.y_offset
	'draw coords of the ball
	for c = 0 to 10
		if (int(Timer)) mod 10 = c then
			circle (temp_x, temp_y), 4
		end if
		if c mod 2 then
			pset (temp_x, temp_y)
		else
			circle (temp_x, temp_y), 2
		end if
		temp_x += temp_speed * cos(temp_rds) 
		temp_y += temp_speed * -sin(temp_rds) + GRAVITY_ACCEL
		temp_speed *= GRAVITY
	next c
end sub

sub draw_horz_scale	   (		x as integer, y as integer, _
								w as integer, h as integer, _
								v as integer, mv as integer, _
								s_color as Uinteger)
	dim bar_w as integer 'bar width
	dim bar_c as Uinteger ' bar color
	bar_w = int (w * v / mv)
	bar_c = int (100 * v / mv)
	line (x-1, y-1)-(x+w + 2, y +h + 2), s_color, B
	line (x + 1,y + 1)-(x + bar_w, y + h), rgb(255 - int(bar_c*2.5),int(bar_c*2.5), 0), BF							
end sub

sub get_mouse (	Ball as ball_proto, User_Mouse as mouse, pl_sel as integer ptr, _
				pl() as player_proto, turn as integer ptr, turn_timing as single ptr, _
				Ball_Record() as ball_proto, camera as camera_proto)
	dim c as integer
	dim is_found as boolean = false

	
	'pl selected updated by user
	User_Mouse.res = 	GetMouse( 	User_Mouse.x, User_Mouse.y, _
									User_Mouse.wheel, User_Mouse.buttons,_
									User_Mouse.clip)
	'check if the mouse isnt' outside the window 
	if  User_Mouse.clip <> -1 then
		User_Mouse.diff_wheel = User_Mouse.old_wheel - User_Mouse.wheel
		if User_Mouse.diff_wheel > 1 then User_Mouse.diff_wheel = 1
		if User_Mouse.diff_wheel < -1 then User_Mouse.diff_wheel = -1
		User_Mouse.old_wheel = User_Mouse.wheel
	end if
	'select alive player
	c = *pl_sel

	'check if user has moved the mouse's wheel
	if User_Mouse.diff_wheel then
		while is_found = false
			c += 2 * User_Mouse.diff_wheel
			if c > Ubound(pl) then
				c = 0 + *turn
			end if
			if c < 0 then
				c = Ubound(pl) - 1 + *turn
			end if
			if pl(c).is_alive then
				*pl_sel = c
				is_found = true
			end if
		wend
	end if
	
	if Ball.is_active = false and pl(*pl_sel).is_alive then
	
		'move the player
		if CBool(User_Mouse.buttons = 2) and pl(*pl_sel).has_moved = false then
			pl(*pl_sel).speed = PL_MOVING_SPEED
			pl(*pl_sel).y -= 20
			pl(*pl_sel).rds = abs(_abtp(		(pl(*pl_sel).x - camera.x_offset), _
									(pl(*pl_sel).x - camera.x_offset), _
									User_Mouse.x, User_Mouse.y))
			pl(*pl_sel).has_moved = true
		end if
		'launch the ball
		if User_Mouse.buttons = 1 then
			Ball.rds = 	_abtp(		(pl(*pl_sel).x - camera.x_offset), _
									(pl(*pl_sel).y - camera.y_offset), _
									User_Mouse.x, User_Mouse.y)
									
			Ball.speed = d_b_t_p(	(pl(*pl_sel).x - camera.x_offset), _
									(pl(*pl_sel).y - camera.y_offset), _
									User_Mouse.x, User_Mouse.y) / 5
			'dont' allow the ball to go to fast					
			if Ball.speed > BALL_MAX_SPEED then Ball.speed = BALL_MAX_SPEED
			Ball.is_active = true
			Ball.x = pl(*pl_sel).x
			Ball.y = pl(*pl_sel).y - 5
			'after kicking the ball change the team turn
			'find first opponent player alive
			*turn = 1-*turn
			'reset has_moved status - allows all players to move again
			for c = 0 to Ubound(pl)
				pl(c).has_moved = false
			next c
			
			'reset the recording of the ball to the position of player
			reset_ball_recording(Ball_Record(), pl(*pl_sel).x, pl(*pl_sel).y)
			
			'find first alive player from other team
			for c = *turn to Ubound(pl) step 2
				if pl(c).is_alive then
					*pl_sel = c
					exit for
				end if
			next c
			'reset timing
			*turn_timing = Timer
			
			
		end if
	end if
end sub

sub draw_debug (Ball as ball_proto, pl() as player_proto, pl_sel as integer, _
				User_Mouse as mouse, Terrain_line() as Terrain, _
				turn as integer ptr, turn_timing as single, _
				camera as camera_proto)
	dim t as integer
	t = get_nrst_node(Ball.x, ball.y, Terrain_line())
	
	circle (Terrain_line(t).x - camera.x_offset, Terrain_line(t).y - camera.y_offset), 4, C_ORANGE,,,,F
	circle (Terrain_line(t+1).x, Terrain_line(t+1).y ), 3, C_ORANGE,,,,F
	circle (Terrain_line(t-1).x, Terrain_line(t-1).y ), 3, C_ORANGE,,,,F

	draw_arrow(		Ball.x - camera.x_offset, Ball.y - camera.y_offset,_
					_abtp(Ball.old_x, Ball.old_y, Ball.x, Ball.y), _
					Ball.speed * 4, C_CYAN)
	
	draw string (20,20), str(hex(point(Ball.x, Ball.y)))
	draw string (20,30), "Ball.x  " + str(int(Ball.x))
	draw string (20,40), "Ball.y  " + str(int(Ball.y))
	draw string (20,50), "Nrstnd  " + str(get_nrst_node(ball.x, ball.y, Terrain_line()))
	draw string (20,60), "turn    " + str(*Turn)
	draw string (20,70), "Alive#0 " + str(count_alive(pl(), 0))
	draw string (20,80), "Alive#1 " + str(count_alive(pl(), 1))
	draw string (20,90), "SCT_W   " + str(SECTION_W)
	draw string (20,100),"Mouse x          " + str(User_Mouse.x)
	draw string (20,110),"Mouse y          " + str(User_Mouse.y)
	draw string (20,120),"Mouse.wheel      " + str(User_Mouse.wheel)
	draw string (20,130),"Mouse.buttons    " + str(User_Mouse.buttons)
	draw string (20,140),"Mouse.clip       " + str(User_Mouse.clip)
	draw string (20,150),"Mouse.diff_wheel " + str(User_Mouse.diff_wheel)
	draw string (20,160),"Mouse.old_wheel  " + str(User_Mouse.old_wheel)
	draw string (20,180),"turn timing  " + str(int(Timer - turn_timing))
	
	'player selected proprietes
	draw string (pl(pl_sel).x - camera.x_offset, pl(pl_sel).y - camera.y_offset + 20), " PWR " + str(pl(pl_sel).power)
	draw string (pl(pl_sel).x - camera.x_offset, pl(pl_sel).y - camera.y_offset + 30), "   X " + str(int(pl(pl_sel).x - camera.x_offset))
	draw string (pl(pl_sel).x - camera.x_offset, pl(pl_sel).y - camera.y_offset + 40), "   Y " + str(int(pl(pl_sel).y - camera.y_offset))
	draw string (pl(pl_sel).x - camera.x_offset, pl(pl_sel).y - camera.y_offset + 50), "  ID " + str(pl_sel)
	draw string (pl(pl_sel).x - camera.x_offset, pl(pl_sel).y - camera.y_offset + 60), "TEAM " + str(pl(pl_sel).team)
	
	line (0,SCR_TOP_MARGIN)-(SCR_W, SCR_TOP_MARGIN), C_GRAY
	line (0,SCR_BOTTOM_MARGIN)-(SCR_W, SCR_BOTTOM_MARGIN), C_GRAY
end sub

sub draw_player_stats (pl() as player_proto, pl_sel as integer, turn as integer, status_sprite() as Uinteger ptr, turn_timing as single)
	dim as integer c, x, y, w, h, p, m, mb
	w = 26 'width
	h = 32 'heigth
	p = 1 'padding
	m = 1 'margin left/right
	mb = 40 'margin bottom
	
	for c = 0 to Ubound(pl)
		if pl(c).team = 0 then
			x = m+(w*c\2)+(p*c)
			y = SCR_H - mb
			'highlight selected player
			
			if c = pl_sel then
				y -= 10 
				line(x-2,y+2)-(x+w+2, y+h+2), C_WHITE,BF
			end if
			'line(x,y)-(x+w, y-h), C_RED,BF
			if pl(c).is_alive then
				put (x, y), status_sprite(1),trans
			else
				put (x, y), status_sprite(2),trans
			end if
			draw_horz_scale (x, y + h, w, 5, pl(c).power, 100, C_WHITE)
		else
			x = SCR_W - m -(w*c\2)-(p*c) - w\2
			y = SCR_H - mb
			'highlight selected player
			if c = pl_sel then
				y -= 10 
				line(x-2,y+2)-(x+w+2, y+h+2), C_WHITE,BF
			end if
			if pl(c).is_alive then
				put (x, y), status_sprite(0),trans
			else
				put (x, y), status_sprite(2),trans
			end if
			draw_horz_scale (x, y + h, w, 5, pl(c).power, 100, C_WHITE)
		end if
	next c
	'draw the timer and the color of the selected team
	if turn then
		line (SCR_W\2 - 16, 20)-(SCR_W\2 + 16, 42), C_RED, BF
	else
		line (SCR_W\2 - 16, 20)-(SCR_W\2 + 16, 42), C_YELLOW,BF
	end if
	draw string (SCR_W\2 - 8, 10), str(MAX_TURN_TIMING_SECS - int(Timer - turn_timing))

end sub

function count_alive(pl() as player_proto, n_team as integer) as integer
	dim c as integer
	dim alive_players as integer = 0
	for c = 0 to Ubound(pl)
		if pl(c).team = n_team then
			if pl(c).is_alive then alive_players +=1
		end if
	next c
	return alive_players
end function

sub load_bmp ( 	bmp() as Uinteger ptr, w as integer, h as integer, _
				cols as integer, rows as integer, Byref bmp_path as string)
				
	dim as integer c, tiles, tile_w, tile_h, y, x
	tiles = cols * rows
	tile_w = w\cols
	tile_h = h\rows
	y = 0
	x = 0
	
	BLOAD bmp_path, 0
	
	for c = 0 to Ubound(bmp)
		if c > 0 and c mod cols = 0 then
			y+= tile_h 
			x = 0 
		end if
		bmp(c) = IMAGECREATE (tile_w, tile_h)
		GET (x, y)-(x + tile_w - 1, y + tile_h - 1), bmp(c)
		x += tile_w

	next c

end sub


function start_frame (rds as single) as integer
    
    dim degree as integer
    'convert radiants to 360° degree
    degree = (180-int(rds*180/PI))
    select case degree
		case 0 to 22
			return 0
		case 23 to 67
			return 28'tr
		case 68 to 112
			return 24
		case 113 to 157
			return 20
		case 158 to 202
			return 16
		case 203 to 247
			return 12'bL
		case 248 to 292
			return 8
		case 292 to 337
			return 4
		case 337 to 360
			return 0
		case else
			return 0
    end select
end function

function get_terrain_tile (tile as integer, margin as integer) as integer

dim as integer c, p, masked, tile_x, tile_y

dim tile_model(0 to 15) as integer = {	&b0000, &b1000, &b1100, &b1110, _
										&b1111, &b0111, &b0011, &b0001, _
										&b0101, &b1010, &b1101, &b1011, _
										&b0110, &b1001, &b0010, &b0100}

tile_x = (tile mod BMP_TILE_COLS) * BMP_TILE_W
tile_y = (tile \ BMP_TILE_COLS) * BMP_TILE_H

masked = &b0000

if point(tile_x + margin, tile_y + margin) <> C_BLUE then masked = masked or &b1000
if point(tile_x + BMP_TILE_W - margin, tile_y + margin) <> C_BLUE then masked = masked or &b0100
if point(tile_x + margin, tile_y + BMP_TILE_H - margin) <> C_BLUE then masked = masked or &b0010
if point(tile_x + BMP_TILE_W - margin, tile_y + BMP_TILE_H - margin) <> C_BLUE then masked = masked or &b0001

for c = 0 to Ubound (tile_model)
	if tile_model(c) = masked then exit for
next c

return c

end function

sub reset_ball_recording(Ball_Record() as ball_proto, x as single, y as single)
	'reset ball record position 
	dim c as integer
	for c = 0 to Ubound(Ball_Record)
		Ball_Record(c).x = x
		Ball_Record(c).y = y
	next c
end sub

sub draw_trajectory(Ball_Record() as ball_proto, ball_record_slot as integer, camera as camera_proto)
	dim temp_slot1 as integer = ball_record_slot - 1
	dim temp_slot2 as integer = temp_slot1 - 1
	dim c as integer = 0
	dim a as integer = 0
	dim points(0 to 3) as ball_proto
	dim as single rds = 0
	dim as single picker_x, picker_y
	dim as integer color_pick = 0  
	for c = 0 to Ubound(Ball_Record) - 1
		'check that the slot doesnt' goes outside array bounds
		if temp_slot2 < 0 then temp_slot2 = Ubound(Ball_Record)
		if temp_slot1 < 0 then temp_slot1 = Ubound(Ball_Record)
		if temp_slot1 > Ubound(Ball_Record) then
			temp_slot1 = 0
			temp_slot2 = Ubound(Ball_Record)
		end if
		if temp_slot2 > Ubound(Ball_Record) then
			temp_slot2 = 0
		end if
		'------------------------------------------------------
		
		rds = _abtp(	Ball_Record(temp_slot1).x, _
						Ball_Record(temp_slot1).y, _
						Ball_Record(temp_slot2).x, _
						Ball_Record(temp_slot2).y)
						
		points(0).x = Ball_Record(temp_slot1).x + (7-(c+5)\5) * cos(rds + PI_HALF) 
		points(0).y = Ball_Record(temp_slot1).y + (7-(c+5)\5)  * -sin(rds + PI_HALF)
		points(1).x = Ball_Record(temp_slot1).x + (7-(c+5)\5)  * cos(rds - PI_HALF)
		points(1).y = Ball_Record(temp_slot1).y + (7-(c+5)\5)  * -sin(rds - PI_HALF)
		points(2).x = Ball_Record(temp_slot2).x + (7-(c+5)\5)  * cos(rds + PI_HALF)
		points(2).y = Ball_Record(temp_slot2).y + (7-(c+5)\5)  * -sin(rds + PI_HALF)
		points(3).x = Ball_Record(temp_slot2).x + (7-(c+5)\5)  * cos(rds - PI_HALF)
		points(3).y = Ball_Record(temp_slot2).y + (7-(c+5)\5)  * -sin(rds - PI_HALF)
		
		picker_x = points(0).x + d_b_t_p(points(0).x, points(0).y, points(3).x, points(3).y) / 2 * _
					cos(_abtp(points(0).x, points(0).y, points(3).x, points(3).y)) 
		picker_y = points(0).y + d_b_t_p(points(0).x, points(0).y, points(3).x, points(3).y) / 2 * _
					-sin(_abtp(points(0).x, points(0).y, points(3).x, points(3).y)) 
		
		color_pick = rgb(255 - c*10,255 - c*10,255)
		'draws a circle on top of trajectory
		if c = 0 then
			circle	(	Ball_Record(temp_slot1).x - camera.x_offset, _
						Ball_Record(temp_slot1).y - camera.y_offset),  5, c_WHITE,,,,F
		end if
		
		line (points(0).x - camera.x_offset, points(0).y - camera.y_offset) - (points(1).x - camera.x_offset, points(1).y - camera.y_offset), color_pick
		line (points(1).x - camera.x_offset, points(1).y - camera.y_offset) - (points(3).x - camera.x_offset, points(3).y - camera.y_offset), color_pick
		line (points(3).x - camera.x_offset, points(3).y - camera.y_offset) - (points(2).x - camera.x_offset, points(2).y - camera.y_offset), color_pick
		line (points(2).x - camera.x_offset, points(2).y - camera.y_offset) - (points(0).x - camera.x_offset, points(0).y - camera.y_offset), color_pick
		if (d_b_t_p (Ball_Record(temp_slot1).x - camera.x_offset, Ball_Record(temp_slot1).y - camera.y_offset, _
					Ball_Record(temp_slot2).x - camera.x_offset, Ball_Record(temp_slot2).y - camera.y_offset )) _
					> 3 then
			paint (picker_x - camera.x_offset, picker_y - camera.y_offset), color_pick, color_pick
		end if
		
		temp_slot1 -=1
		temp_slot2 -=1
	next c
end sub

sub draw_clouds(clouds() as generic_item_proto, cloud_sprite() as Uinteger ptr, camera as camera_proto)
	dim as integer	c, d
	for c = 0 to Ubound(clouds)
		if c < ubound(cloud_sprite) then
			d = c
		else
			d = c mod ubound(cloud_sprite)
		end if
		put (clouds(c).x - camera.x_offset, _
				clouds(c).y - camera.y_offset),  cloud_sprite(d), trans

				
	next c
end sub

sub check_ball_collisions	(Ball as ball_proto, Terrain_line() as terrain, _
							pl() as player_proto)
							
	dim as integer t, c
	t = get_nrst_node(ball.x, ball.y, Terrain_line())
	'modify the ground profile when the ball impacts
	Terrain_line(t).y += 16
	if t < Ubound(Terrain_line) and t > 0 then
		terrain_line(t-1).y +=8
		terrain_line(t+1).y +=8
	end if

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

end sub

sub  record_ball_position	(ball_record() as ball_proto, ball as ball_proto,_
							ball_record_slot as uinteger ptr)
	Ball_Record(*ball_record_slot).x = ball.x
	Ball_Record(*ball_record_slot).y = ball.y
	*ball_record_slot +=1
	if *ball_record_slot > Ubound (Ball_Record) then 
		*ball_record_slot = 0
	end if		
end sub

sub update_camera (		camera as camera_proto, ball as ball_proto, _
						pl() as player_proto, pl_sel as integer)
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


end sub

sub	update_turn_change (	turn_timing as single ptr, turn as integer ptr, _
							pl() as player_proto, pl_sel as integer ptr)
	dim c as integer
	if Timer - *turn_timing > MAX_TURN_TIMING_SECS then
	*turn = 1 - *turn
	*turn_timing = Timer
	'find first alive player from other team
	for c = *turn to Ubound(pl) step 2
		if pl(c).is_alive then
			*pl_sel = c
			exit for
		end if
	next c
	end if

end sub

sub draw_mouse_pointer (User_Mouse as mouse)
	line (User_Mouse.x - 5, User_Mouse.y)- (User_Mouse.x +5, User_Mouse.y)
	line (User_Mouse.x, User_Mouse.y +5)- (User_Mouse.x, User_Mouse.y - 5)
end sub






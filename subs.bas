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
declare sub draw_background(Terrain_line() as Terrain)
declare sub draw_players(ball as ball_proto, pl() as player_proto, pl_sel as integer, sprite_t0() as Uinteger ptr, sprite_t1() as Uinteger ptr)
declare sub draw_ball(Ball as ball_proto, ball_sprite() as Uinteger ptr)
declare sub draw_trajectory(pl() as player_proto, pl_sel as integer, User_Mouse as mouse)
'draws a bar scale
declare sub draw_horz_scale	   (x as integer, y as integer, _
								w as integer, h as integer, _
								v as integer, mv as integer, _
								s_color as Uinteger)
declare sub get_mouse (Ball as ball_proto, User_Mouse as mouse, pl_sel as integer ptr, pl() as player_proto, turn as integer ptr)
'prints on screen useful info for debug
declare sub draw_debug (Ball as ball_proto, pl() as player_proto, pl_sel as integer, _
				User_Mouse as mouse, Terrain_line() as Terrain, turn as integer ptr)
				
declare sub draw_player_stats (pl() as player_proto, pl_sel as integer, turn as integer)

declare sub load_bmp ( bmp() as Uinteger ptr, w as integer, h as integer, _
					   cols as integer, rows as integer, Byref bmp_path as string)

declare function count_alive(pl() as player_proto, n_team as integer) as integer
declare function start_frame (rds as single) as integer

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

function get_nrst_node(bc as ball_proto ptr, tc() as Terrain) as Integer
    dim max_dist as integer = 1000
    dim as Integer c, id
    for c = 2 to Ubound(tc)-2
        if d_b_t_p(bc->x, bc->y,tc(c).x,tc(c).y) < max_dist then
			max_dist = d_b_t_p(bc->x, bc->y,tc(c).x,tc(c).y)
			id = c
		end if
    next c
    return id
end function

sub update_players(pl() as player_proto)
	dim c as integer
	for c = 0 to Ubound(pl)
		pl(c).old_x = pl(c).x
		pl(c).old_y = pl(c).y
		if point(pl(c).x - pl(c).w\2, pl(c).y + pl(c).h + 3) = C_BLUE then
			pl(c).y +=5
			pl(c).speed *=0.9
		end if
		if pl(c).speed > 1 then
			pl(c).x += pl(c).speed*cos(pl(c).rds)
			pl(c).y += pl(c).speed*-sin(pl(c).rds)
			pl(c).speed *= GRAVITY
			'bound check
			if pl(c).x + pl(c).w > SCR_W then
				pl(c).x = SCR_W - pl(c).w - 10
				pl(c).rds = -pl(c).rds
			end if
			if pl(c).x < 0 then
				pl(c).x = 10
				pl(c).rds = -pl(c).rds
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
			Terrain_line(SECTIONS-1).x = SCR_W
			Terrain_line(SECTIONS-1).y = SCR_TOP_MARGIN
		end if
	next c
end sub

sub draw_background(Terrain_line() as Terrain)
	dim c as integer
	'draw the ground line
	for c = 0 to Ubound(Terrain_line)
		if c < Ubound(Terrain_line) - 1 then
			line (Terrain_line(c).x, Terrain_line(c).y)-(Terrain_line(c +1).x, Terrain_line(c+1).y), &hFF0000
		else
			line (Terrain_line(c-1).x, Terrain_line(c-1).y)-(Terrain_line(c).x, Terrain_line(c).y), &hFF0000
		end if
	next c
	' fill the background
	paint (SCR_W \ 2, 2), C_BLUE, &hFF0000
end sub

sub draw_players(ball as ball_proto, pl() as player_proto, pl_sel as integer, sprite_t0() as Uinteger ptr, sprite_t1() as Uinteger ptr)
	dim c as integer
	dim sprite as integer
	for c = 0 to Ubound(pl)
		if pl(c).is_alive = false then continue for
		'draws a line around the selected player
		if c = pl_sel then
	
			draw_horz_scale	   (pl(c).x - pl(c).w\2 - 2, pl(c).y + pl(c).h + 10, _
								20, 5, pl(c).power, 100, C_GRAY)
			
		end if
		
		sprite = start_frame (_abtp (ball.x, ball.y, pl(c).x,pl(c).y ))
		if pl(c).team = 0 then
			if pl(c).speed then
				sprite = start_frame (_abtp (pl(c).x,pl(c).y, pl(c).old_x,pl(c).old_y )) + 1
			end if
			
			put (pl(c).x - 10, pl(c).y - 5), sprite_t0(sprite), trans
		else
			if pl(c).speed then
				sprite = start_frame (_abtp (pl(c).x,pl(c).y, pl(c).old_x,pl(c).old_y )) + 1
			end if
	
			put (pl(c).x - 10, pl(c).y - 5), sprite_t1(sprite), trans
		end if
		
	next c
end sub

sub draw_ball(Ball as ball_proto, ball_sprite() as Uinteger ptr)
	if Ball.is_active then
		put (Ball.x - 8, Ball.y - 8), ball_sprite(int((timer * 10) mod Ubound(ball_sprite))), trans
	end if
end sub


sub update_particles(particles() as ball_proto)
	dim c as integer
	for c = 0 to ubound(particles)
		'check screen bounds
		if 	particles(c).x > 0 and particles(c).x < SCR_W _
			and particles(c).y > 0 and particles(c).y < SCR_H then
			particles(c).x += particles(c).speed * cos(particles(c).rds)
			particles(c).y += particles(c).speed * -sin(particles(c).rds) + GRAVITY_ACCEL
			particles(c).speed *= GRAVITY
		end if
	next c
end sub

sub draw_particles(particles() as ball_proto)
	dim c as integer
	for c = 0 to ubound(particles)
		Circle (particles(c).x, particles(c).y), particles(c).w, C_YELLOW,,,,F
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

sub draw_trajectory(pl() as player_proto, pl_sel as integer, User_Mouse as mouse)
	dim as single temp_x, temp_y, temp_rds, temp_speed
	dim c as integer 
	temp_rds = _abtp(pl(pl_sel).x, pl(pl_sel).y, _
				User_Mouse.x, User_Mouse.y)
				
	temp_speed = d_b_t_p(pl(pl_sel).x, pl(pl_sel).y, _
				User_Mouse.x, User_Mouse.y)/5
	if temp_speed > BALL_MAX_SPEED then temp_speed = BALL_MAX_SPEED		
	temp_x = pl(pl_sel).x
	temp_y = pl(pl_sel).y
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

sub get_mouse (Ball as ball_proto, User_Mouse as mouse, pl_sel as integer ptr, pl() as player_proto, turn as integer ptr)
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
		draw_trajectory(pl(), *pl_sel, User_Mouse)
		'launch the ball
		if User_Mouse.buttons = 1 then
			Ball.rds = 	_abtp(		pl(*pl_sel).x, pl(*pl_sel).y, _
									User_Mouse.x, User_Mouse.y)
			
			Ball.speed = d_b_t_p(	pl(*pl_sel).x, pl(*pl_sel).y, _
									User_Mouse.x, User_Mouse.y) / 5
									
			if Ball.speed > BALL_MAX_SPEED then Ball.speed = BALL_MAX_SPEED
			Ball.is_active = true
			Ball.x = pl(*pl_sel).x
			Ball.y = pl(*pl_sel).y - 5
			'after kicking the ball change the team turn
			'find first opponent player alive
			*turn = 1-*turn
			for c = *turn to Ubound(pl) step 2
				if pl(c).is_alive then
					*pl_sel = c
					exit for
				end if
			next c
		end if
	end if
end sub

sub draw_debug (Ball as ball_proto, pl() as player_proto, pl_sel as integer, _
				User_Mouse as mouse, Terrain_line() as Terrain, turn as integer ptr)
	dim t as integer
	t = get_nrst_node(@Ball, Terrain_line())
	
	circle (Terrain_line(t).x, Terrain_line(t).y ), 4, C_ORANGE,,,,F
	circle (Terrain_line(t+1).x, Terrain_line(t+1).y ), 3, C_ORANGE,,,,F
	circle (Terrain_line(t-1).x, Terrain_line(t-1).y ), 3, C_ORANGE,,,,F

	draw_arrow(Ball.x, Ball.y, _abtp(Ball.old_x, Ball.old_y, Ball.x, Ball.y), Ball.speed * 4, C_CYAN)
	
	draw string (20,20), str(hex(point(Ball.x, Ball.y)))
	draw string (20,30), "Ball.x  " + str(int(Ball.x))
	draw string (20,40), "Ball.y  " + str(int(Ball.y))
	draw string (20,50), "Nrstnd  " + str(get_nrst_node(@Ball, Terrain_line()))
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
	
	'player selected proprietes
	draw string (pl(pl_sel).x, pl(pl_sel).y + 20), " PWR " + str(pl(pl_sel).power)
	draw string (pl(pl_sel).x, pl(pl_sel).y + 30), "   X " + str(int(pl(pl_sel).x))
	draw string (pl(pl_sel).x, pl(pl_sel).y + 40), "   Y " + str(int(pl(pl_sel).y))
	draw string (pl(pl_sel).x, pl(pl_sel).y + 50), "  ID " + str(pl_sel)
	draw string (pl(pl_sel).x, pl(pl_sel).y + 60), "TEAM " + str(pl(pl_sel).team)
	
	line (0,SCR_TOP_MARGIN)-(SCR_W, SCR_TOP_MARGIN), C_GRAY
	line (0,SCR_BOTTOM_MARGIN)-(SCR_W, SCR_BOTTOM_MARGIN), C_GRAY
end sub

sub draw_player_stats (pl() as player_proto, pl_sel as integer, turn as integer)
	dim as integer c, x, y, w, h, p, m, mb
	w = 20 'width
	h = 30 'heigth
	p = 2 'padding
	m = 10 'margin left/right
	mb = 40 'margin bottom
	
	for c = 0 to Ubound(pl)
		if pl(c).is_alive then
			if pl(c).team = 0 then
				x = m+(w*c)+(p*c)
				y = SCR_H - mb
				'highlight selected player
				if c = pl_sel then line(x-2,y+2)-(x+w+2, y-h-2), C_WHITE,B
				line(x,y)-(x+w, y-h), C_RED,BF
				draw_horz_scale (x, y + h, w, 5, pl(c).power, 100, C_WHITE)
			else
				x = SCR_W - m -(w*c)-(p*c)
				y = SCR_H - mb
				'highlight selected player
				if c = pl_sel then line(x-2,y+2)-(x+w+2, y-h-2), C_WHITE,B
				line(x,y)-(x+w, y-h), C_YELLOW,BF
				draw_horz_scale (x, y + h, w, 5, pl(c).power, 100, C_WHITE)
			end if
		end if
	next c

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




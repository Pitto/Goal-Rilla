declare function d_b_t_p (x1 as single, y1 as single, x2 as single, y2 as single) as single
'gives values in the range -1...1
declare function get_diff_angle(alfa as single, beta as single) as single

'__________________________________________________________________
declare sub draw_arrow(x as single, y as single, rds as single, a_l as single, cl as Uinteger)
'initialize the ground profile
declare sub init_terrain_line(	x as single, y as single, rds as single, _
								a_l as single, coords as Terrain ptr)
								
declare sub update_ball (coords as ball_proto ptr)
declare sub init_pl_positions(pl() as player_proto)
declare sub draw_background(Terrain_line() as Terrain)
declare sub draw_players(pl() as player_proto, pl_sel as integer)
declare sub draw_ball(Ball as ball_proto)
declare sub draw_trajectory(pl() as player_proto, pl_sel as integer, User_Mouse as mouse)
declare sub draw_horz_scale	   (x as integer, y as integer, _
								w as integer, h as integer, _
								v as integer, mv as integer, _
								s_color as Uinteger)
declare sub get_mouse (Ball as ball_proto, User_Mouse as mouse, pl_sel as integer ptr, pl() as player_proto)
declare sub draw_debug (Ball as ball_proto, pl() as player_proto, pl_sel as integer, _
				User_Mouse as mouse, Terrain_line() as Terrain)

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
		if point(pl(c).x - pl(c).w\2, pl(c).y + pl(c).h + 3) = C_BLUE then
			pl(c).y +=5
		end if
		if pl(c).speed > 1 then
			pl(c).x += pl(c).speed*cos(pl(c).rds)
			pl(c).y += pl(c).speed*-sin(pl(c).rds)
			pl(c).speed *= GRAVITY
		else
			pl(c).speed = 0
		end if
	next c
end sub

sub init_pl_positions(pl() as player_proto)
	dim c as integer
	for c = 0 to Ubound(pl)
		pl(c).x = rnd * (SCR_W - 20) + 10
		pl(c).y = 0
		pl(c).team = c MOD 2
		pl(c).w = 8
		pl(c).h = 12 
		pl(c).power = int(rnd*90)+10
		pl(c).is_alive = true
	next c
end sub

sub init_ground (Terrain_line() as Terrain)
	dim c as integer
	Terrain_line(0).x = -5
	Terrain_line(0).y = SCR_H -100

	for c = 0 to Ubound(Terrain_line) 
		if c < Ubound(Terrain_line) - 1 then
		init_terrain_line(	Terrain_line(c).x, Terrain_line(c).y, rnd *(PI*0.33)-PI/8, _
							SECTION_W, @Terrain_line(c+1))
		else
			Terrain_line(SECTIONS-1).x = SCR_W
			Terrain_line(SECTIONS-1).y = SCR_H \2
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

sub draw_players(pl() as player_proto, pl_sel as integer)
	dim c as integer
	for c = 0 to Ubound(pl)
		'draws a line around the selected player
		if c = pl_sel then
			line(pl(c).x - 2, pl(c).y -2 )-(pl(c).x + pl(c).w + 2, pl(c).y + pl(c).h + 2), &hFFFFFF, BF
			draw_horz_scale	   (pl(c).x - pl(c).w\2, pl(c).y + pl(c).h + 10, _
								20, 5, pl(c).power, 100, C_GRAY)
			
		end if
		if c mod 2 then
			line(pl(c).x, pl(c).y)-(pl(c).x + pl(c).w, pl(c).y + pl(c).h), C_RED, BF
		else
			line(pl(c).x, pl(c).y)-(pl(c).x + pl(c).w, pl(c).y + pl(c).h), C_YELLOW, BF
		end if
	next c
end sub

sub draw_ball(Ball as ball_proto)
	Circle (Ball.x, Ball.y), 5, C_RED,,,,F
	Circle (Ball.x, Ball.y), 3, C_DARK_RED,,,,F
end sub

sub draw_trajectory(pl() as player_proto, pl_sel as integer, User_Mouse as mouse)
	dim as single temp_x, temp_y, temp_rds, temp_speed
	dim c as integer 
	temp_rds = _abtp(pl(pl_sel).x, pl(pl_sel).y, _
				User_Mouse.x, User_Mouse.y)
	temp_speed = d_b_t_p(pl(pl_sel).x, pl(pl_sel).y, _
				User_Mouse.x, User_Mouse.y)/5			
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

sub get_mouse (Ball as ball_proto, User_Mouse as mouse, pl_sel as integer ptr, pl() as player_proto)
	'pl selected updated by user
	User_Mouse.res = 	GetMouse( 	User_Mouse.x, User_Mouse.y, _
									User_Mouse.wheel, User_Mouse.buttons,_
									User_Mouse.clip)
	User_Mouse.diff_wheel = User_Mouse.old_wheel - User_Mouse.wheel
	User_Mouse.old_wheel = User_Mouse.wheel
	*pl_sel = *pl_sel + User_Mouse.diff_wheel
	if *pl_sel < 0 then *pl_sel = 0
	if *pl_sel > Ubound(pl) then *pl_sel = Ubound(pl)

	if Ball.is_active = false then
		draw_trajectory(pl(), *pl_sel, User_Mouse)
		'launch the ball
		if User_Mouse.buttons = 1 then
			Ball.rds = 	_abtp(		pl(*pl_sel).x, pl(*pl_sel).y, _
									User_Mouse.x, User_Mouse.y)
			Ball.speed = d_b_t_p(	pl(*pl_sel).x, pl(*pl_sel).y, _
									User_Mouse.x, User_Mouse.y) / 5
			Ball.is_active = true
			Ball.x = pl(*pl_sel).x
			Ball.y = pl(*pl_sel).y - 5
		end if
	end if
end sub

sub draw_debug (Ball as ball_proto, pl() as player_proto, pl_sel as integer, _
				User_Mouse as mouse, Terrain_line() as Terrain)
	dim t as integer
	t = get_nrst_node(@Ball, Terrain_line())
	
	circle (Terrain_line(t).x, Terrain_line(t).y ), 4, C_ORANGE,,,,F
	circle (Terrain_line(t+1).x, Terrain_line(t+1).y ), 3, C_ORANGE,,,,F
	circle (Terrain_line(t-1).x, Terrain_line(t-1).y ), 3, C_ORANGE,,,,F

	draw_arrow(Ball.x, Ball.y, _abtp(Ball.old_x, Ball.old_y, Ball.x, Ball.y), Ball.speed * 4, C_CYAN)
	
	draw string (20,20), str(hex(point(Ball.x, Ball.y)))
	draw string (20,40), "Ball.x " + str(int(Ball.x))
	draw string (20,60), "Ball.y " + str(int(Ball.y))
	draw string (20,80), str(get_nrst_node(@Ball, Terrain_line()))
	
	'player selected proprietes
	draw string (pl(pl_sel).x, pl(pl_sel).y + 20), "PWR " + str(pl(pl_sel).power)
	draw string (pl(pl_sel).x, pl(pl_sel).y + 30), "X   " + str(int(pl(pl_sel).x))
	draw string (pl(pl_sel).x, pl(pl_sel).y + 40), "Y   " + str(int(pl(pl_sel).y))
	draw string (pl(pl_sel).x, pl(pl_sel).y + 50), "ID  " + str(pl_sel)
end sub




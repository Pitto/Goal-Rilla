type Terrain
	x as single
	y as single
end type

type generic_item_proto
	x as single
	y as single
	w as single
end type

type ball_proto
	x 		as single
	y 		as single
	old_x 	as single
	old_y 	as single
	r		as single 'radius
	rds 	as single 'angle in radiants
	speed 	as single
	is_active as boolean
	w as single
end type

type camera_proto
	x as single
	x_offset as single
	y as single
	y_offset as single
	obj as obj_to_follow
	rds as single
	speed as single
end type

type player_proto
	x as single
	y as single
	old_x 	as single
	old_y 	as single
	w as single
	h as single
	rds as single
	speed as single
	power as single
	team as integer
	is_alive as boolean
	has_moved as boolean
end type

Type mouse
    As Integer res, x, y, wheel, clip, old_wheel, diff_wheel
    Union
        buttons 		As Integer
        Type
            Left:1 		As Integer
            Right:1 	As Integer
            middle:1 	As Integer
        End Type
    End Union
End Type

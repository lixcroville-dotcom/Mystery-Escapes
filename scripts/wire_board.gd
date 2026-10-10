extends Control
# Mobile/desktop drag-and-drop terminal board. Complete wires in the indicated order.
signal wire_dropped(color_index: int)
signal drag_rejected
var connected: Array = []
var dragging: int = -1
var drag_point := Vector2.ZERO
var palette := [Color("#eebd75"),Color("#6ed0e4"),Color("#ed8798"),Color("#79d6a5")]
var text_color := Color("#f0e1c9")
const LEFT_X = 74.0
const RIGHT_X = 500.0
const FIRST_Y = 54.0
const STEP_Y = 78.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(false)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(4,4,570,355), Color("#0a1724eb"),true)
	draw_rect(Rect2(4,4,570,355), Color("#aa8b59"),false,2.0)
	for i in range(4):
		var start=Vector2(LEFT_X,FIRST_Y+i*STEP_Y)
		var stop=Vector2(RIGHT_X,FIRST_Y+i*STEP_Y)
		draw_circle(start,26.0,Color("#202d3c"))
		draw_circle(start,16.0,palette[i])
		draw_circle(stop,25.0,Color("#2c3b48"))
		draw_arc(stop,17.0,0.0,TAU,32,Color("#b6a17e"),3.0)
		draw_string(get_theme_default_font(),Vector2(LEFT_X-11.0,FIRST_Y+i*STEP_Y+8.0),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#101c2a"))
		draw_string(get_theme_default_font(),Vector2(RIGHT_X-9.0,FIRST_Y+i*STEP_Y+8.0),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,18,text_color)
	for i in range(connected.size()):
		var idx=int(connected[i])
		var a=Vector2(LEFT_X,FIRST_Y+idx*STEP_Y)
		var b=Vector2(RIGHT_X,FIRST_Y+i*STEP_Y)
		var c=palette[idx]
		draw_line(a,b,Color(c.r,c.g,c.b,0.25),15.0,true)
		draw_line(a,b,c,6.0,true)
	if dragging >= 0:
		var origin=Vector2(LEFT_X,FIRST_Y+dragging*STEP_Y)
		draw_line(origin,drag_point,palette[dragging],7.0,true)

func _find_origin(p: Vector2) -> int:
	for i in range(4):
		if p.distance_to(Vector2(LEFT_X,FIRST_Y+i*STEP_Y)) <= 48.0:
			return i
	return -1

func _press_at(p: Vector2) -> void:
	dragging = _find_origin(p)
	drag_point = p
	queue_redraw()

func _release_at(p: Vector2) -> void:
	if dragging<0:
		return
	var selected=dragging
	dragging=-1
	var destination=Vector2(RIGHT_X,FIRST_Y+connected.size()*STEP_Y)
	if p.distance_to(destination)<65.0 and connected.size()<4:
		wire_dropped.emit(selected)
	else:
		drag_rejected.emit()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: _press_at(event.position)
		else: _release_at(event.position)
		accept_event()
	elif event is InputEventMouseMotion and dragging>=0:
		drag_point=event.position
		queue_redraw()
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed: _press_at(event.position)
		else: _release_at(event.position)
		accept_event()
	elif event is InputEventScreenDrag and dragging>=0:
		drag_point=event.position
		queue_redraw()
		accept_event()

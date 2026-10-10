extends Control
# Tap an item, or drag it to the central combining station.
signal item_chosen(index: int)
var items: Array = []
var selected: Array = []
var dragging: int = -1
var drag_pos := Vector2.ZERO
const TARGET = Vector2(294.0,192.0)

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	queue_redraw()

func item_pos(i: int) -> Vector2:
	return Vector2(32.0+float(i%2)*276.0, 22.0+float(int(i/2))*110.0)

func _draw() -> void:
	draw_rect(Rect2(0,0,588,382),Color("#10202ddf"),true)
	draw_rect(Rect2(0,0,588,382),Color("#b79a6c"),false,2.0)
	for i in range(mini(items.size(),4)):
		var p=item_pos(i)
		var rect=Rect2(p.x,p.y,248,82)
		var picked=selected.has(i)
		draw_rect(rect,Color("#385243") if picked else Color("#263e50"),true)
		draw_rect(rect,Color("#b5d69e") if picked else Color("#c1a36e"),false,2.0)
		draw_string(get_theme_default_font(),p+Vector2(14,47),str(items[i]),HORIZONTAL_ALIGNMENT_CENTER,222,22,Color("#f4e4c6"))
	# Combination plate below the pieces
	var station=Rect2(106,261,380,95)
	draw_rect(station,Color("#0d151f"),true)
	draw_rect(station,Color("#cfae70"),false,2.5)
	draw_string(get_theme_default_font(),Vector2(141,313),"COMBINER  /  COMBINE",HORIZONTAL_ALIGNMENT_CENTER,307,22,Color("#f1d296"))
	if dragging>=0:
		draw_circle(drag_pos,21,Color("#eec17aa3"))
		draw_circle(drag_pos,12,Color("#ffffff"))

func _origin(p: Vector2) -> int:
	for i in range(mini(items.size(),4)):
		if Rect2(item_pos(i),Vector2(248,82)).has_point(p):
			return i
	return -1

func _press(p: Vector2) -> void:
	dragging=_origin(p)
	drag_pos=p
	queue_redraw()

func _release(p: Vector2) -> void:
	if dragging<0:return
	var i=dragging
	dragging=-1
	if Rect2(106,261,380,95).has_point(p) or Rect2(item_pos(i),Vector2(248,82)).has_point(p):
		item_chosen.emit(i)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:_press(event.position)
		else:_release(event.position)
		accept_event()
	elif event is InputEventMouseMotion and dragging>=0:
		drag_pos=event.position
		queue_redraw()
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:_press(event.position)
		else:_release(event.position)
		accept_event()
	elif event is InputEventScreenDrag and dragging>=0:
		drag_pos=event.position
		queue_redraw()
		accept_event()

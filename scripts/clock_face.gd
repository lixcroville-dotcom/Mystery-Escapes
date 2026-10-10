extends Control
## Standalone analogue clock UI. Tap the left half to move the hour hand,
## right half to move the minute hand. Swipe vertically to change direction.
signal change_clock(hours: bool, step: int)
var hour: int = 0
var minute: int = 0
var first_touch: Vector2 = Vector2.ZERO
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()
func _draw() -> void:
	var c := size * 0.5
	var r: float = minf(size.x, size.y) * 0.46
	draw_circle(c, r + 6.0, Color("#ab824b"))
	draw_circle(c, r, Color("#111f2b"))
	draw_arc(c, r - 8.0, 0.0, TAU, 96, Color("#e4ba76"), 3.0, true)
	for n in range(60):
		var a: float = float(n) * TAU / 60.0 - PI / 2.0
		var ext: float = 15.0 if n % 5 == 0 else 7.0
		var thickness: float = 3.0 if n % 5 == 0 else 1.0
		draw_line(c + Vector2(cos(a),sin(a)) * (r-10.0-ext), c + Vector2(cos(a),sin(a)) * (r-10.0), Color("#efd39a"), thickness, true)
	var ha: float = (float(hour % 12) + float(minute) / 60.0) * TAU / 12.0 - PI / 2.0
	var ma: float = float(minute) * TAU / 60.0 - PI / 2.0
	draw_line(c, c + Vector2(cos(ha),sin(ha)) * (r * 0.52), Color("#f5dba5"), 8.0, true)
	draw_line(c, c + Vector2(cos(ma),sin(ma)) * (r * 0.79), Color("#c5e4f4"), 5.0, true)
	draw_circle(c, 7.0, Color("#e3aa5d"))
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			first_touch = event.position
		else:
			var diff: float = event.position.y-first_touch.y
			change_clock.emit(first_touch.x < size.x * 0.5, -1 if diff < -12.0 else 1)
		accept_event()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		change_clock.emit(event.position.x < size.x * 0.5, 1)
		accept_event()

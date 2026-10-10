extends Control
# Lightweight, non-interactive, deterministic motes for the illustrated backdrops.
# Turned off by the reduced-motion accessibility preference.
var motes: Array = []
var elapsed: float = 0.0
var tint := Color(0.95,0.77,0.45,0.15)
var frame_time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var random = RandomNumberGenerator.new()
	random.seed = 98210
	for i in range(29):
		motes.append({"x":random.randf_range(10.0,710.0),"y":random.randf_range(10.0,1270.0),"r":random.randf_range(1.0,3.5),"speed":random.randf_range(2.0,10.0),"phase":random.randf_range(0.0,6.28)})

func _process(delta: float) -> void:
	elapsed += delta
	frame_time += delta
	if frame_time > 0.055:
		frame_time = 0.0
		queue_redraw()

func _draw() -> void:
	for m in motes:
		var xx: float = float(m["x"]) + sin(elapsed*0.35+float(m["phase"])) * 10.0
		var yy: float = fposmod(float(m["y"])-elapsed*float(m["speed"]), 1280.0)
		var alpha: float = 0.35+0.55*absf(sin(elapsed*0.6+float(m["phase"])))
		draw_circle(Vector2(xx,yy),float(m["r"]),Color(tint.r,tint.g,tint.b,tint.a*alpha))

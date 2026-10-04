extends Control
var tracks: Array[Dictionary] = []
var selected := ""

func _draw() -> void:
	draw_style_box(_background(), Rect2(Vector2.ZERO, size))
	var center := size * 0.5
	for radius in [32.0, 60.0, 82.0]:
		draw_arc(center, radius, 0, TAU, 64, Color("31584d"), 1, true)
	draw_line(Vector2(10, center.y), Vector2(size.x - 10, center.y), Color("31584d"))
	draw_line(Vector2(center.x, 10), Vector2(center.x, size.y - 10), Color("31584d"))
	draw_line(center + Vector2(-45, 0), center + Vector2(45, 0), Color("83a393"), 2)
	for flight in tracks:
		var point := center + Vector2(flight.pos.x, flight.pos.z) * 0.85
		var color := Color("ffd269") if flight.id == selected else Color("68e2df")
		draw_circle(point, 3.5, color)
		draw_string(ThemeDB.fallback_font, point + Vector2(5, -5), flight.id, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
	draw_string(ThemeDB.fallback_font, Vector2(10, 17), "TRAFFIC OVERVIEW", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("68e2df"))

func _background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0b211edd")
	style.set_corner_radius_all(10)
	return style

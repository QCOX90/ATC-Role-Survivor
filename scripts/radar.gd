extends Control
var tracks: Array[Dictionary] = []
var selected := ""

func _draw() -> void:
	draw_style_box(_background(), Rect2(Vector2.ZERO, size))
	var center := size * 0.5
	var extent := 100.0
	for flight in tracks:
		extent = maxf(extent, maxf(absf(flight.pos.x), absf(flight.pos.z)) + 15)
	var map_scale := 78.0 / extent
	for radius in [32.0, 60.0, 82.0]:
		draw_arc(center, radius, 0, TAU, 64, Color("31584d"), 1, true)
	draw_line(Vector2(10, center.y), Vector2(size.x - 10, center.y), Color("31584d"))
	draw_line(Vector2(center.x, 10), Vector2(center.x, size.y - 10), Color("31584d"))
	draw_line(center + Vector2(-48, 0) * map_scale, center + Vector2(48, 0) * map_scale, Color("83a393"), 2)
	for flight in tracks:
		var point := center + Vector2(flight.pos.x, flight.pos.z) * map_scale
		var color := Color("ffd269") if flight.id == selected else Color("68e2df")
		draw_circle(point, 3.5, color)
		draw_string(ThemeDB.fallback_font, point + Vector2(5, -5), flight.id, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
	draw_string(ThemeDB.fallback_font, Vector2(10, 17), "TRAFFIC OVERVIEW", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("68e2df"))
	draw_string(ThemeDB.fallback_font, Vector2(10, size.y - 8), "Range %.1f NM" % (extent * 40.0 / 1852.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("68e2df"))

func _background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0b211edd")
	style.set_corner_radius_all(10)
	return style
